--!strict
-- src/client/character/R15AnimationController.luau
-- Client R15 Animation & Character Lifecycle Controller
-- Tracks native R15 Animator and Humanoid lifecycle with strict generation and invalidation gates (RF-F22).
-- Orchestrates full canonical locomotion suite: Idle, Walk, Run, Jump, and Land.
-- Governed by RF02-IDLE-RUNTIME Contract (Round 1 & Owner Scope Lock 2026-10-26).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10) :: Folder?
assert(Shared ~= nil, "[R15AnimationController] Shared folder missing in ReplicatedStorage")
local configs = Shared:WaitForChild("configs", 10) :: Folder?
assert(configs ~= nil, "[R15AnimationController] configs folder missing in Shared")
local LocomotionConfigsModule = configs:WaitForChild("R15LocomotionConfigs", 10) :: ModuleScript?
assert(LocomotionConfigsModule ~= nil, "[R15AnimationController] R15LocomotionConfigs missing")
local LocomotionConfigs = require(LocomotionConfigsModule)

local JumpConfigsModule = configs:WaitForChild("JumpConfigs", 10) :: ModuleScript?
local JumpConfigs = if JumpConfigsModule then require(JumpConfigsModule) else { JUMP_POWER = 72, EXPECTED_APEX_HEIGHT = 13.2 }

local JumpTiming = require(Shared:WaitForChild("JumpAnimationTiming"))
local LocomotionHelper = require(script.Parent:WaitForChild("R15LocomotionHelper"))

local isInitialized = false
local currentCharacter: Model? = nil
local currentHumanoid: Humanoid? = nil
local currentAnimator: Animator? = nil

local currentTracks: LocomotionHelper.TrackCache = {
	Idle = nil,
	Walk = nil,
	Run = nil,
	Jump = nil,
	Land = nil,
}
local currentRegistrationSources: LocomotionHelper.RegistrationSources = {
	Idle = "NONE",
	Walk = "NONE",
	Run = "NONE",
	Jump = "NONE",
	Land = "NONE",
}
local currentAnimInstances: { Animation } = {}

local characterGeneration: number = 0
local activeConnections: { RBXScriptConnection } = {}
local currentRunningSpeed: number = 0
local wasAirborne: boolean = false
local passiveFall = false
local jumpSourceTime = JumpTiming.PushOff
local landingStartedAt = 0

local R15AnimationController = {}

local function cleanupConnections()
	for _, conn in ipairs(activeConnections) do
		conn:Disconnect()
	end
	table.clear(activeConnections)
end

local function cleanupAllTracks()
	LocomotionHelper.CleanupTracks(currentTracks, currentAnimInstances)
	currentTracks = {
		Idle = nil,
		Walk = nil,
		Run = nil,
		Jump = nil,
		Land = nil,
	}
	currentRegistrationSources = {
		Idle = "NONE",
		Walk = "NONE",
		Run = "NONE",
		Jump = "NONE",
		Land = "NONE",
	}
	wasAirborne = false
	currentRunningSpeed = 0
end

local function invalidateCharacterState()
	cleanupConnections()
	cleanupAllTracks()
	currentCharacter = nil
	currentHumanoid = nil
	currentAnimator = nil
end

local function onCharacterRemoving(character: Model)
	if character == currentCharacter then
		invalidateCharacterState()
	end
end

local function isAirborneState(state: Enum.HumanoidStateType): boolean
	return state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
end

local function isDisablingState(state: Enum.HumanoidStateType): boolean
	return state == Enum.HumanoidStateType.Climbing
		or state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Seated
		or state == Enum.HumanoidStateType.Dead
		or state == Enum.HumanoidStateType.Physics
		or state == Enum.HumanoidStateType.PlatformStanding
end

local function updateLocomotionPlayback(thisGen: number)
	if characterGeneration ~= thisGen or not currentHumanoid or currentHumanoid.Health <= 0 then
		return
	end

	local state = currentHumanoid:GetState()

	-- 1. Disabling states: Climbing, swimming, seated, dead, ragdoll/physics
	if isDisablingState(state) then
		wasAirborne = false
		for _, track in pairs(currentTracks) do
			if track and track.IsPlaying then
				track:Stop(LocomotionConfigs.Playback.IdleFadeTime)
			end
		end
		return
	end

	-- Flight pose is sampled from actual vertical velocity; Freefall includes the rising arc.
 if isAirborneState(state) or (wasAirborne and currentHumanoid.FloorMaterial == Enum.Material.Air) then
  local entering = not wasAirborne
  wasAirborne = true
  for _, key in {"Idle","Walk","Run","Land"} do
   local tr = currentTracks[key]
   if tr and tr.IsPlaying then tr:Stop(if key == "Land" then 0.02 else 0.08) end
  end
  local jump = currentTracks.Jump
  if entering then
   local root = currentHumanoid.RootPart
   passiveFall = state == Enum.HumanoidStateType.Freefall and (not root or root.AssemblyLinearVelocity.Y <= JumpConfigs.LEDGE_FALL_MAX_INITIAL_VY)
   jumpSourceTime = if passiveFall then JumpTiming.DescentHold else JumpTiming.PushOff
  end
  if jump and not jump.IsPlaying then
   jump:Play(LocomotionConfigs.Playback.JumpFadeTime,1,0)
   jump.TimePosition = jumpSourceTime
  end
  return
 end

	-- 3. Grounded states: Running or Landed
	if wasAirborne then
		-- Just made ground contact after being airborne!
		wasAirborne = false
		landingStartedAt = os.clock()
		if currentCharacter then currentCharacter:SetAttribute("JumpAnimationPhase","Land") end

		-- Stop jump flight pose immediately
		if currentTracks.Jump and currentTracks.Jump.IsPlaying then
			currentTracks.Jump:Stop(0.05)
		end

		-- Play separate authored Land recovery track once (Action priority)
		if currentTracks.Land and not currentTracks.Land.IsPlaying then
			currentTracks.Land:Play(LocomotionConfigs.Playback.LandFadeTime)
		end
	end

	-- Base Ground Locomotion Selection (Idle / Walk / Run)
	local rootPart = currentHumanoid.RootPart
	local horizVel = if rootPart then Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z).Magnitude else 0
	local isMoving = (currentHumanoid.MoveDirection.Magnitude > LocomotionConfigs.Playback.MoveDirectionThreshold)
		or (currentRunningSpeed > LocomotionConfigs.Playback.SpeedStationaryThreshold)
		or (horizVel > 1.0)

	if not isMoving then
		-- Grounded & Stationary: Play Idle, Stop Walk and Run
		if currentTracks.Walk and currentTracks.Walk.IsPlaying then
			currentTracks.Walk:Stop(LocomotionConfigs.Playback.WalkFadeTime)
		end
		if currentTracks.Run and currentTracks.Run.IsPlaying then
			currentTracks.Run:Stop(LocomotionConfigs.Playback.RunFadeTime)
		end
		if currentTracks.Idle and not currentTracks.Idle.IsPlaying then
			currentTracks.Idle:Play(LocomotionConfigs.Playback.IdleFadeTime)
		end
	else
		-- Grounded & Moving: Stop Idle and interrupt Land recovery overlay
		if currentTracks.Idle and currentTracks.Idle.IsPlaying then
			currentTracks.Idle:Stop(LocomotionConfigs.Playback.IdleFadeTime)
		end
		if currentTracks.Land and currentTracks.Land.IsPlaying and os.clock()-landingStartedAt >= JumpTiming.LandingMoveBlendAfter then
			currentTracks.Land:Stop(LocomotionConfigs.Playback.LandFadeTime)
		end

		local isSprinting = false
		local char = currentCharacter
		if char and char:GetAttribute("IsSprinting") == true then
			isSprinting = true
		elseif currentHumanoid.WalkSpeed >= LocomotionConfigs.Playback.SprintSpeedThreshold then
			isSprinting = true
		end

		if isSprinting then
			-- Moving at Sprint speed: Play Run, Stop Walk
			if currentTracks.Walk and currentTracks.Walk.IsPlaying then
				currentTracks.Walk:Stop(LocomotionConfigs.Playback.WalkFadeTime)
			end
			if currentTracks.Run and not currentTracks.Run.IsPlaying then
				currentTracks.Run:Play(LocomotionConfigs.Playback.RunFadeTime)
			end
		else
			-- Moving at normal Walk speed: Play Walk, Stop Run
			if currentTracks.Run and currentTracks.Run.IsPlaying then
				currentTracks.Run:Stop(LocomotionConfigs.Playback.RunFadeTime)
			end
			if currentTracks.Walk and not currentTracks.Walk.IsPlaying then
				currentTracks.Walk:Play(LocomotionConfigs.Playback.WalkFadeTime)
			end
		end
	end
end

local function onCharacterAdded(character: Model)
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	-- Edge Case (3): Reject mismatched or non-current character BEFORE generation increment or invalidation!
	if localPlayer.Character ~= character or not character:IsDescendantOf(game) then
		return
	end

	characterGeneration += 1
	local thisGen = characterGeneration

	-- Invalidate previous character state immediately upon new character arriving
	invalidateCharacterState()
	currentCharacter = character

	-- Yield to find Humanoid within bounded timeout
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?

	-- Post-yield generation and hierarchy verification (RF-F22)
	if characterGeneration ~= thisGen
		or localPlayer.Character ~= character
		or not character:IsDescendantOf(game)
		or not humanoid
		or not humanoid:IsDescendantOf(character) then
		return
	end

	-- Yield to find Animator within bounded timeout
	local animator = humanoid:WaitForChild("Animator", 10) :: Animator?

	-- Post-yield generation and hierarchy verification (RF-F22)
	if characterGeneration ~= thisGen
		or localPlayer.Character ~= character
		or not character:IsDescendantOf(game)
		or not humanoid:IsDescendantOf(character)
		or not animator
		or not animator:IsDescendantOf(humanoid) then
		return
	end

	-- Successfully validated both Humanoid and Animator for this active generation
	currentHumanoid = humanoid
	currentAnimator = animator

	-- Configure native locomotion responsiveness with higher jump configuration
	humanoid.UseJumpPower = true
	humanoid.JumpPower = JumpConfigs.JUMP_POWER
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

	-- Load all five canonical locomotion animation tracks via helper
	local tracks, sources, animInstances = LocomotionHelper.LoadTracks(animator)

	-- Post-LoadTracks generation verification (RF-F22 hardening)
	if characterGeneration ~= thisGen
		or localPlayer.Character ~= character
		or not character:IsDescendantOf(game) then
		LocomotionHelper.CleanupTracks(tracks, animInstances)
		return
	end

	currentTracks = tracks
	currentRegistrationSources = sources
	currentAnimInstances = animInstances

	-- Invalidate on Humanoid death (RF-F22)
	local diedConn = humanoid.Died:Connect(function()
		if characterGeneration == thisGen then
			cleanupAllTracks()
			currentAnimator = nil
			currentHumanoid = nil
		end
	end)
	table.insert(activeConnections, diedConn)

	-- Event-driven locomotion and state observers (No render-loop polling)
	-- Established BEFORE initial evaluation to ensure no state transition is dropped
	local moveDirConn = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if characterGeneration == thisGen then
			updateLocomotionPlayback(thisGen)
		end
	end)
	table.insert(activeConnections, moveDirConn)

	local speedConn = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if characterGeneration == thisGen then
			updateLocomotionPlayback(thisGen)
		end
	end)
	table.insert(activeConnections, speedConn)

	local runningConn = humanoid.Running:Connect(function(speed: number)
		if characterGeneration == thisGen then
			currentRunningSpeed = speed
			updateLocomotionPlayback(thisGen)
		end
	end)
	table.insert(activeConnections, runningConn)

	local stateConn = humanoid.StateChanged:Connect(function(_oldState, _newState)
		if characterGeneration == thisGen then
			updateLocomotionPlayback(thisGen)
		end
	end)
	table.insert(activeConnections, stateConn)
	-- Landed/Running may arrive transiently before actual support is reported.
	local floorConn = humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		if characterGeneration == thisGen then updateLocomotionPlayback(thisGen) end
	end)
	table.insert(activeConnections, floorConn)

	local sprintAttrConn = character:GetAttributeChangedSignal("IsSprinting"):Connect(function()
		if characterGeneration == thisGen then
			updateLocomotionPlayback(thisGen)
		end
	end)
	table.insert(activeConnections, sprintAttrConn)


 -- Apply track timing before Animator evaluates joints (official PreAnimation guidance).
 local animationConn = RunService.PreAnimation:Connect(function()
  if characterGeneration ~= thisGen or not currentHumanoid or currentHumanoid.Health <= 0 then return end
  local root = currentHumanoid.RootPart
  local jump = currentTracks.Jump
  if wasAirborne and root and jump and jump.IsPlaying then
   local time,phase = JumpTiming.Sample(root.AssemblyLinearVelocity.Y,JumpConfigs.JUMP_POWER,passiveFall)
   jumpSourceTime = math.max(jumpSourceTime,time)
   jump:AdjustSpeed(0)
   jump.TimePosition = math.min(jumpSourceTime,JumpTiming.DescentHold)
   character:SetAttribute("JumpAnimationSourceTime",jumpSourceTime)
   character:SetAttribute("JumpAnimationPhase",phase)
  elseif currentTracks.Land and currentTracks.Land.IsPlaying and root
   and os.clock()-landingStartedAt >= JumpTiming.LandingMoveBlendAfter
   and (currentHumanoid.MoveDirection.Magnitude > 0.01 or Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude > 1) then
   currentTracks.Land:Stop(LocomotionConfigs.Playback.LandFadeTime)
  end
 end)
 table.insert(activeConnections,animationConn)

	-- Initial locomotion evaluation after all observers are active
	updateLocomotionPlayback(thisGen)
end

function R15AnimationController.Init(_timeoutBudget: number?)
	if isInitialized then
		return
	end
	isInitialized = true

	local localPlayer = Players.LocalPlayer
	assert(localPlayer ~= nil, "[R15AnimationController] LocalPlayer required for initialization")

	localPlayer.CharacterAdded:Connect(onCharacterAdded)
	localPlayer.CharacterRemoving:Connect(onCharacterRemoving)

	task.spawn(function()
		local deadline = os.clock() + 10.0
		while (not localPlayer.Character or not localPlayer.Character:IsDescendantOf(game)) and os.clock() < deadline do
			task.wait()
		end
		if localPlayer.Character and localPlayer.Character:IsDescendantOf(game) then
			onCharacterAdded(localPlayer.Character)
		end
	end)
end

function R15AnimationController.GetAnimator(): Animator?
	if R15AnimationController.IsR15Ready() then
		return currentAnimator
	end
	return nil
end

function R15AnimationController.GetHumanoid(): Humanoid?
	if R15AnimationController.IsR15Ready() then
		return currentHumanoid
	end
	return nil
end

function R15AnimationController.GetCharacter(): Model?
	if R15AnimationController.IsR15Ready() then
		return currentCharacter
	end
	return nil
end

function R15AnimationController.GetGeneration(): number
	return characterGeneration
end

-- Idle APIs
function R15AnimationController.GetIdleTrack(): AnimationTrack?
	if R15AnimationController.IsR15Ready() then
		return currentTracks.Idle
	end
	return nil
end

function R15AnimationController.IsIdlePlaying(): boolean
	if currentTracks.Idle then
		return currentTracks.Idle.IsPlaying
	end
	return false
end

function R15AnimationController.GetIdleRegistrationSource(): string
	return currentRegistrationSources.Idle
end

-- Walk APIs
function R15AnimationController.GetWalkTrack(): AnimationTrack?
	if R15AnimationController.IsR15Ready() then
		return currentTracks.Walk
	end
	return nil
end

function R15AnimationController.IsWalkPlaying(): boolean
	if currentTracks.Walk then
		return currentTracks.Walk.IsPlaying
	end
	return false
end

function R15AnimationController.GetWalkRegistrationSource(): string
	return currentRegistrationSources.Walk
end

-- Run APIs
function R15AnimationController.GetRunTrack(): AnimationTrack?
	if R15AnimationController.IsR15Ready() then
		return currentTracks.Run
	end
	return nil
end

function R15AnimationController.IsRunPlaying(): boolean
	if currentTracks.Run then
		return currentTracks.Run.IsPlaying
	end
	return false
end

function R15AnimationController.GetRunRegistrationSource(): string
	return currentRegistrationSources.Run
end

-- Jump APIs
function R15AnimationController.GetJumpTrack(): AnimationTrack?
	if R15AnimationController.IsR15Ready() then
		return currentTracks.Jump
	end
	return nil
end

function R15AnimationController.IsJumpPlaying(): boolean
	if currentTracks.Jump then
		return currentTracks.Jump.IsPlaying
	end
	return false
end

function R15AnimationController.GetJumpRegistrationSource(): string
	return currentRegistrationSources.Jump
end

-- Land APIs
function R15AnimationController.GetLandTrack(): AnimationTrack?
	if R15AnimationController.IsR15Ready() then
		return currentTracks.Land
	end
	return nil
end

function R15AnimationController.IsLandPlaying(): boolean
	if currentTracks.Land then
		return currentTracks.Land.IsPlaying
	end
	return false
end

function R15AnimationController.GetLandRegistrationSource(): string
	return currentRegistrationSources.Land
end

function R15AnimationController.WasAirborne(): boolean
	return wasAirborne
end

function R15AnimationController.IsR15Ready(): boolean
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return false
	end

	local char = currentCharacter
	local hum = currentHumanoid
	local anim = currentAnimator

	if not char or not hum or not anim then
		return false
	end

	-- Strict validity checks (RF-F22):
	-- 1. Character matches LocalPlayer.Character and is descendant of game/Workspace
	-- 2. Humanoid is descendant of Character, is alive (Health > 0), and is RigType R15
	-- 3. Animator is descendant of Humanoid
	if char ~= localPlayer.Character or not char:IsDescendantOf(game) then
		return false
	end

	if not hum:IsDescendantOf(char) or hum.RigType ~= Enum.HumanoidRigType.R15 or hum.Health <= 0 then
		return false
	end

	if not anim:IsDescendantOf(hum) then
		return false
	end

	return true
end

return table.freeze(R15AnimationController)
