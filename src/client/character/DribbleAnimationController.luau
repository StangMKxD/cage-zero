--!strict
-- src/client/character/DribbleAnimationController.luau
-- Additive Carrier Dribble & G-Mode Close-Control Animation Controller for R15 Characters
-- Governed by RF02-DRIBBLE-ANIMATION-INTEGRATION Contract (2026-10-27).
-- Preserves R15AnimationController non-carrier locomotion and airborne Jump/Land/4-lean/yaw-lock untouched.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10) :: Folder?
assert(Shared ~= nil, "[DribbleAnimationController] Shared folder missing in ReplicatedStorage")
local configs = Shared:WaitForChild("configs", 10) :: Folder?
assert(configs ~= nil, "[DribbleAnimationController] configs folder missing in Shared")

local LocomotionConfigs = require(configs:WaitForChild("R15LocomotionConfigs"))
local DribbleActionConfigs = require(configs:WaitForChild("DribbleActionConfigs"))
local R15AnimationController = require(script.Parent:WaitForChild("R15AnimationController"))
local DribbleAnimationHelper = require(script.Parent:WaitForChild("DribbleAnimationHelper"))
local ControllersFolder = script.Parent.Parent:WaitForChild("controllers")
local DribbleCutController = require(ControllersFolder:WaitForChild("DribbleCutController"))

local isInitialized = false
local currentCharacter: Model? = nil
local currentHumanoid: Humanoid? = nil
local currentAnimator: Animator? = nil
local characterGeneration: number = 0
local currentRunningSpeed: number = 0
local baseWeightsMuted: boolean = false
local activeLoopKey: string = "NONE"

local currentTracks: DribbleAnimationHelper.LoopTrackCache = {
	WalkDribble = nil,
	RunDribble = nil,
	GModeLoop = nil,
}
local currentSources: DribbleAnimationHelper.LoopRegistrationSources = {
	WalkDribble = "NONE",
	RunDribble = "NONE",
	GModeLoop = "NONE",
}
local currentAnimInstances: { Animation } = {}
local activeConnections: { RBXScriptConnection } = {}
local globalConnections: { RBXScriptConnection } = {}

local DribbleAnimationController = {}

local function restoreBaseLocomotionWeights()
	if not baseWeightsMuted then
		return
	end
	baseWeightsMuted = false
	local walkTrack = R15AnimationController.GetWalkTrack()
	if walkTrack then
		pcall(function()
			walkTrack:AdjustWeight(1.0, DribbleActionConfigs.LOOP_FADE_SEC)
		end)
	end
	local runTrack = R15AnimationController.GetRunTrack()
	if runTrack then
		pcall(function()
			runTrack:AdjustWeight(1.0, DribbleActionConfigs.LOOP_FADE_SEC)
		end)
	end
end

local function muteBaseLocomotionWeights()
	baseWeightsMuted = true
	local walkTrack = R15AnimationController.GetWalkTrack()
	if walkTrack and walkTrack.IsPlaying then
		pcall(function()
			walkTrack:AdjustWeight(0.0001, 0.06)
		end)
	end
	local runTrack = R15AnimationController.GetRunTrack()
	if runTrack and runTrack.IsPlaying then
		pcall(function()
			runTrack:AdjustWeight(0.0001, 0.06)
		end)
	end
end

local function stopAllDribbleLoops(fadeSec: number?)
	local fade = fadeSec or DribbleActionConfigs.LOOP_FADE_SEC
	for _, track in pairs(currentTracks) do
		if track and track.IsPlaying then
			pcall(function()
				track:Stop(fade)
			end)
		end
	end
	activeLoopKey = "NONE"
	restoreBaseLocomotionWeights()
end

local function isGroundedState(hum: Humanoid): boolean
	if hum.FloorMaterial == Enum.Material.Air then
		return false
	end
	local state = hum:GetState()
	if
		state == Enum.HumanoidStateType.Jumping
		or state == Enum.HumanoidStateType.Freefall
		or state == Enum.HumanoidStateType.Climbing
		or state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Seated
		or state == Enum.HumanoidStateType.Dead
		or state == Enum.HumanoidStateType.Physics
		or state == Enum.HumanoidStateType.PlatformStanding
	then
		return false
	end
	return true
end

local function updateDribblePlayback(thisGen: number)
	if characterGeneration ~= thisGen then
		return
	end
	local char = currentCharacter
	local hum = currentHumanoid
	if not char or not hum or not char.Parent or hum.Health <= 0 then
		stopAllDribbleLoops(0.05)
		return
	end

	local isCarrier = (char:GetAttribute("IsBallCarrier") == true)
	local grounded = isGroundedState(hum)

	if not isCarrier or not grounded then
		if not grounded or not isCarrier then
			DribbleCutController.Cancel()
		end
		stopAllDribbleLoops(0.10)
		char:SetAttribute("ActiveDribbleClip", "")
		return
	end

	-- One-shot directional/reverse cut takes priority and locks movement until completion
	if DribbleCutController.IsLocked(char) then
		stopAllDribbleLoops(DribbleActionConfigs.CUT_FADE_SEC)
		char:SetAttribute("ActiveDribbleClip", DribbleCutController.GetActiveClipName() or "")
		return
	end

	local rootPart = hum.RootPart
	local horizVel = if rootPart
		then Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z).Magnitude
		else 0
	local isMoving = (hum.MoveDirection.Magnitude > LocomotionConfigs.Playback.MoveDirectionThreshold)
		or (currentRunningSpeed > LocomotionConfigs.Playback.SpeedStationaryThreshold)
		or (horizVel > 1.0)

	if not isMoving then
		stopAllDribbleLoops(DribbleActionConfigs.LOOP_FADE_SEC)
		char:SetAttribute("ActiveDribbleClip", "")
		return
	end

	local goalMode = (char:GetAttribute("GoalDribbleActive") == true)
	local isSprinting = (char:GetAttribute("IsSprinting") == true)
		or (not goalMode and hum.WalkSpeed >= LocomotionConfigs.Playback.SprintSpeedThreshold)

	muteBaseLocomotionWeights()

	if goalMode then
		if currentTracks.WalkDribble and currentTracks.WalkDribble.IsPlaying then
			currentTracks.WalkDribble:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
		end
		if currentTracks.RunDribble and currentTracks.RunDribble.IsPlaying then
			currentTracks.RunDribble:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
		end
		local gTrack = currentTracks.GModeLoop
		if gTrack then
			if not gTrack.IsPlaying then
				gTrack:Play(DribbleActionConfigs.LOOP_FADE_SEC)
			end
			local refSpeed = if horizVel > 1.0 then horizVel else DribbleActionConfigs.GOAL_BASE_SPEED
			gTrack:AdjustSpeed(math.clamp(refSpeed / DribbleActionConfigs.GOAL_BASE_SPEED, 0.75, 1.25))
			activeLoopKey = "GModeLoop"
			char:SetAttribute("ActiveDribbleClip", DribbleActionConfigs.Clips.GModeLoop.ClipName)
		end
	elseif isSprinting then
		if currentTracks.WalkDribble and currentTracks.WalkDribble.IsPlaying then
			currentTracks.WalkDribble:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
		end
		if currentTracks.GModeLoop and currentTracks.GModeLoop.IsPlaying then
			currentTracks.GModeLoop:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
		end
		local runTrack = currentTracks.RunDribble
		if runTrack then
			if not runTrack.IsPlaying then
				runTrack:Play(DribbleActionConfigs.LOOP_FADE_SEC)
			end
			local refSpeed = if horizVel > 2.0 then horizVel else hum.WalkSpeed
			runTrack:AdjustSpeed(math.clamp(refSpeed / DribbleActionConfigs.RUN_BASE_SPEED, 0.75, 1.25))
			activeLoopKey = "RunDribble"
			char:SetAttribute("ActiveDribbleClip", DribbleActionConfigs.Clips.RunDribble.ClipName)
		end
	else
		if currentTracks.RunDribble and currentTracks.RunDribble.IsPlaying then
			currentTracks.RunDribble:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
		end
		if currentTracks.GModeLoop and currentTracks.GModeLoop.IsPlaying then
			currentTracks.GModeLoop:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
		end
		local walkTrack = currentTracks.WalkDribble
		if walkTrack then
			if not walkTrack.IsPlaying then
				walkTrack:Play(DribbleActionConfigs.LOOP_FADE_SEC)
			end
			local refSpeed = if horizVel > 1.5 then horizVel else hum.WalkSpeed
			walkTrack:AdjustSpeed(math.clamp(refSpeed / DribbleActionConfigs.WALK_BASE_SPEED, 0.70, 1.30))
			activeLoopKey = "WalkDribble"
			char:SetAttribute("ActiveDribbleClip", DribbleActionConfigs.Clips.WalkDribble.ClipName)
		end
	end
end

local function cleanupCharacterConnections()
	for _, conn in ipairs(activeConnections) do
		conn:Disconnect()
	end
	table.clear(activeConnections)
end

local function invalidateCharacterState()
	cleanupCharacterConnections()
	DribbleCutController.Cancel()
	stopAllDribbleLoops(0)
	DribbleAnimationHelper.CleanupLoopTracks(currentTracks, currentAnimInstances)
	currentTracks = {
		WalkDribble = nil,
		RunDribble = nil,
		GModeLoop = nil,
	}
	currentSources = {
		WalkDribble = "NONE",
		RunDribble = "NONE",
		GModeLoop = "NONE",
	}
	currentCharacter = nil
	currentHumanoid = nil
	currentAnimator = nil
	currentRunningSpeed = 0
	activeLoopKey = "NONE"
end

local function attachLoopMarkers(thisGen: number, character: Model, key: DribbleAnimationHelper.DribbleLoopKey, track: AnimationTrack?)
	if not track then
		return
	end
	local spec = (DribbleActionConfigs.Clips :: { [string]: DribbleActionConfigs.DribbleClipSpec })[key]
	if not spec then
		return
	end

	table.insert(
		activeConnections,
		track:GetMarkerReachedSignal("TouchL"):Connect(function()
			if characterGeneration == thisGen and currentCharacter == character and track.IsPlaying then
				DribbleAnimationHelper.NotifyTouchMarker(character, "L", spec.ClipName, false)
			end
		end)
	)

	table.insert(
		activeConnections,
		track:GetMarkerReachedSignal("TouchR"):Connect(function()
			if characterGeneration == thisGen and currentCharacter == character and track.IsPlaying then
				DribbleAnimationHelper.NotifyTouchMarker(character, "R", spec.ClipName, false)
			end
		end)
	)
end

local function onCharacterAdded(character: Model)
	local localPlayer = Players.LocalPlayer
	if not localPlayer or localPlayer.Character ~= character or not character:IsDescendantOf(game) then
		return
	end

	characterGeneration += 1
	local thisGen = characterGeneration

	invalidateCharacterState()
	currentCharacter = character

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if
		characterGeneration ~= thisGen
		or localPlayer.Character ~= character
		or not character:IsDescendantOf(game)
		or not humanoid
		or not humanoid:IsDescendantOf(character)
	then
		return
	end

	local animator = humanoid:WaitForChild("Animator", 10) :: Animator?
	if
		characterGeneration ~= thisGen
		or localPlayer.Character ~= character
		or not character:IsDescendantOf(game)
		or not humanoid:IsDescendantOf(character)
		or not animator
		or not animator:IsDescendantOf(humanoid)
	then
		return
	end

	currentHumanoid = humanoid
	currentAnimator = animator

	local tracks, sources, animInstances = DribbleAnimationHelper.LoadLoopTracks(animator)
	if characterGeneration ~= thisGen or localPlayer.Character ~= character or not character:IsDescendantOf(game) then
		DribbleAnimationHelper.CleanupLoopTracks(tracks, animInstances)
		return
	end

	currentTracks = tracks
	currentSources = sources
	currentAnimInstances = animInstances

	-- Warm up one-shot cut clips asynchronously so TryStart sees track.Length > 0 immediately
	task.spawn(function()
		if characterGeneration == thisGen and currentAnimator == animator then
			DribbleAnimationHelper.WarmupCutTracks(animator)
		end
	end)

	attachLoopMarkers(thisGen, character, "WalkDribble", tracks.WalkDribble)
	attachLoopMarkers(thisGen, character, "RunDribble", tracks.RunDribble)
	attachLoopMarkers(thisGen, character, "GModeLoop", tracks.GModeLoop)

	table.insert(
		activeConnections,
		humanoid.Died:Connect(function()
			if characterGeneration == thisGen then
				invalidateCharacterState()
			end
		end)
	)

	local function observe()
		if characterGeneration == thisGen then
			updateDribblePlayback(thisGen)
		end
	end

	table.insert(activeConnections, humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(observe))
	table.insert(activeConnections, humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(observe))
	table.insert(
		activeConnections,
		humanoid.Running:Connect(function(speed: number)
			if characterGeneration == thisGen then
				currentRunningSpeed = speed
				updateDribblePlayback(thisGen)
			end
		end)
	)
	table.insert(
		activeConnections,
		humanoid.StateChanged:Connect(function()
			if characterGeneration == thisGen then
				updateDribblePlayback(thisGen)
			end
		end)
	)
	table.insert(activeConnections, character:GetAttributeChangedSignal("IsBallCarrier"):Connect(observe))
	table.insert(activeConnections, character:GetAttributeChangedSignal("GoalDribbleActive"):Connect(observe))
	table.insert(activeConnections, character:GetAttributeChangedSignal("IsSprinting"):Connect(observe))
	table.insert(activeConnections, character:GetAttributeChangedSignal("DribbleCutActive"):Connect(observe))
	table.insert(
		activeConnections,
		RunService.Heartbeat:Connect(function()
			if characterGeneration == thisGen then
				updateDribblePlayback(thisGen)
			end
		end)
	)

	updateDribblePlayback(thisGen)
end

local function onCharacterRemoving(character: Model)
	if character == currentCharacter then
		invalidateCharacterState()
	end
end

function DribbleAnimationController.Init(_timeoutBudget: number?)
	if isInitialized then
		return
	end
	isInitialized = true

	local localPlayer = Players.LocalPlayer
	assert(localPlayer ~= nil, "[DribbleAnimationController] LocalPlayer required for initialization")

	table.insert(globalConnections, localPlayer.CharacterAdded:Connect(onCharacterAdded))
	table.insert(globalConnections, localPlayer.CharacterRemoving:Connect(onCharacterRemoving))

	local existingChar = localPlayer.Character
	if existingChar and existingChar:IsDescendantOf(game) then
		task.spawn(function()
			onCharacterAdded(existingChar)
		end)
	end
end

function DribbleAnimationController.Cleanup()
	invalidateCharacterState()
	for _, conn in ipairs(globalConnections) do
		conn:Disconnect()
	end
	table.clear(globalConnections)
	isInitialized = false
end

function DribbleAnimationController.IsReady(): boolean
	local localPlayer = Players.LocalPlayer
	if not localPlayer or not currentCharacter or not currentHumanoid or not currentAnimator then
		return false
	end
	return currentCharacter == localPlayer.Character
		and currentCharacter:IsDescendantOf(game)
		and currentHumanoid.Health > 0
end

function DribbleAnimationController.GetWalkDribbleTrack(): AnimationTrack?
	return currentTracks.WalkDribble
end

function DribbleAnimationController.GetRunDribbleTrack(): AnimationTrack?
	return currentTracks.RunDribble
end

function DribbleAnimationController.GetGModeLoopTrack(): AnimationTrack?
	return currentTracks.GModeLoop
end

function DribbleAnimationController.GetActiveLoopKey(): string
	return activeLoopKey
end

function DribbleAnimationController.GetRegistrationSources(): DribbleAnimationHelper.LoopRegistrationSources
	return {
		WalkDribble = currentSources.WalkDribble,
		RunDribble = currentSources.RunDribble,
		GModeLoop = currentSources.GModeLoop,
	}
end

return table.freeze(DribbleAnimationController)
