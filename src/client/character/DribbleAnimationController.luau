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
	GoalForward = nil,
	GoalBackward = nil,
	GoalLeft = nil,
	GoalRight = nil,
}
local currentSources: DribbleAnimationHelper.LoopRegistrationSources = {
	WalkDribble = "NONE",
	RunDribble = "NONE",
	GModeLoop = "NONE",
	GoalForward = "NONE",
	GoalBackward = "NONE",
	GoalLeft = "NONE",
	GoalRight = "NONE",
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

	local function stopAllGoalLoops(fadeSec: number)
		local goalKeys: { DribbleAnimationHelper.DribbleLoopKey } = {
			"GoalForward",
			"GoalBackward",
			"GoalLeft",
			"GoalRight",
			"GModeLoop",
		}
		for _, key in ipairs(goalKeys) do
			local tr = currentTracks[key]
			if tr and tr.IsPlaying then
				pcall(function()
					tr:Stop(fadeSec)
				end)
			end
		end
	end

	-- One-shot directional/reverse cut takes priority and locks movement until completion.
	-- Keep underlying RunDribble (or GModeLoop in goal mode) playing under Action-priority cuts
	-- and keep base locomotion muted so there is zero 1-frame snap to R15AnimationController!
	if DribbleCutController.IsLocked(char) then
		muteBaseLocomotionWeights()
		local goalMode = (char:GetAttribute("GoalDribbleActive") == true)
		if goalMode then
			if currentTracks.WalkDribble and currentTracks.WalkDribble.IsPlaying then
				currentTracks.WalkDribble:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
			end
			if currentTracks.RunDribble and currentTracks.RunDribble.IsPlaying then
				currentTracks.RunDribble:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
			end
			local keepKey: DribbleAnimationHelper.DribbleLoopKey = if currentTracks.GoalBackward then "GoalBackward" else "GModeLoop"
			local goalKeys: { DribbleAnimationHelper.DribbleLoopKey } = {
				"GoalForward",
				"GoalBackward",
				"GoalLeft",
				"GoalRight",
				"GModeLoop",
			}
			for _, key in ipairs(goalKeys) do
				if key ~= keepKey then
					local tr = currentTracks[key]
					if tr and tr.IsPlaying then
						pcall(function()
							tr:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
						end)
					end
				end
			end
			local gTrack = currentTracks[keepKey]
			if gTrack then
				if not gTrack.IsPlaying then
					gTrack:Play(DribbleActionConfigs.LOOP_FADE_SEC)
				end
				gTrack:AdjustSpeed(1.0)
			end
			activeLoopKey = keepKey
		else
			if currentTracks.WalkDribble and currentTracks.WalkDribble.IsPlaying then
				currentTracks.WalkDribble:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
			end
			stopAllGoalLoops(DribbleActionConfigs.LOOP_FADE_SEC)
			local runTrack = currentTracks.RunDribble
			if runTrack then
				if not runTrack.IsPlaying then
					runTrack:Play(DribbleActionConfigs.LOOP_FADE_SEC)
				end
				runTrack:AdjustSpeed(1.0)
			end
			activeLoopKey = "RunDribble"
		end
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

	local goalMode = (char:GetAttribute("GoalDribbleActive") == true)
	if not isMoving and not goalMode then
		stopAllDribbleLoops(DribbleActionConfigs.LOOP_FADE_SEC)
		char:SetAttribute("ActiveDribbleClip", "")
		return
	end

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

		local targetGoalKey: DribbleAnimationHelper.DribbleLoopKey = "GoalForward"
		local localMove = Vector3.zero
		if rootPart and hum.MoveDirection.Magnitude > 0.05 then
			localMove = rootPart.CFrame:VectorToObjectSpace(hum.MoveDirection)
		elseif rootPart and horizVel > 0.5 then
			localMove = rootPart.CFrame:VectorToObjectSpace(rootPart.AssemblyLinearVelocity)
		end

		local isW = false
		local isS = false
		local isA = false
		local isD = false
		pcall(function()
			local uis = game:GetService("UserInputService")
			isW = uis:IsKeyDown(Enum.KeyCode.W) or uis:IsKeyDown(Enum.KeyCode.Up)
			isS = uis:IsKeyDown(Enum.KeyCode.S) or uis:IsKeyDown(Enum.KeyCode.Down)
			isA = uis:IsKeyDown(Enum.KeyCode.A) or uis:IsKeyDown(Enum.KeyCode.Left)
			isD = uis:IsKeyDown(Enum.KeyCode.D) or uis:IsKeyDown(Enum.KeyCode.Right)
		end)

		if isA and not isD then
			-- Moving Left (A, AW, AS) in Goal Mode routes to GoalLeft (Right-Foot Opposite Sole Roll)
			targetGoalKey = "GoalLeft"
		elseif isD and not isA then
			-- Moving Right (D, WD, SD) in Goal Mode routes to GoalRight (Left-Foot Opposite Sole Roll)
			targetGoalKey = "GoalRight"
		elseif isS and not isW then
			-- Moving Backward (S) in Goal Mode routes to GoalBackward (Sole Drag Pullback)
			targetGoalKey = "GoalBackward"
		elseif isW and not isS then
			-- Moving Forward (W) in Goal Mode routes to GoalForward
			targetGoalKey = "GoalForward"
		elseif localMove.Magnitude > 0.05 then
			local angle = math.atan2(localMove.X, -localMove.Z)
			local deadzone = math.pi * 0.18 -- ~32.4 deg sector around straight forward/backward
			if math.abs(angle) <= deadzone then
				targetGoalKey = "GoalForward"
			elseif math.abs(angle) >= (math.pi - deadzone) then
				targetGoalKey = "GoalBackward"
			elseif angle < 0 then
				-- Left hemisphere: all diagonal front-left, pure left, and back-left
				targetGoalKey = "GoalLeft"
			else
				-- Right hemisphere: all diagonal front-right, pure right, and back-right
				targetGoalKey = "GoalRight"
			end
		else
			targetGoalKey = "GModeLoop"
		end

		local allGoalKeys: { DribbleAnimationHelper.DribbleLoopKey } = {
			"GoalForward",
			"GoalBackward",
			"GoalLeft",
			"GoalRight",
			"GModeLoop",
		}

		local playedAny = false
		local previousGoalTrack = if table.find(allGoalKeys, activeLoopKey)
			then (currentTracks :: { [string]: AnimationTrack? })[activeLoopKey]
			else nil
		local gaitPhase = if previousGoalTrack and previousGoalTrack.IsPlaying and previousGoalTrack.Length > 0
			then (previousGoalTrack.TimePosition / previousGoalTrack.Length) % 1
			else nil
		for _, gKey in ipairs(allGoalKeys) do
			local tr = currentTracks[gKey]
			if gKey == targetGoalKey then
				if tr then
					if not tr.IsPlaying then
						tr:Play(DribbleActionConfigs.LOOP_FADE_SEC)
						if gaitPhase and tr.Length > 0 then
							tr.TimePosition = gaitPhase * tr.Length
						end
					end
					local refSpeed = if horizVel > 1.0 then horizVel else DribbleActionConfigs.GOAL_BASE_SPEED
					tr:AdjustSpeed(math.clamp(refSpeed / DribbleActionConfigs.GOAL_BASE_SPEED, 0.75, 1.25))
					tr:AdjustWeight(1.0, DribbleActionConfigs.LOOP_FADE_SEC)
					activeLoopKey = targetGoalKey
					local clipSpec = (DribbleActionConfigs.Clips :: { [string]: DribbleActionConfigs.DribbleClipSpec })[targetGoalKey]
					if clipSpec then
						char:SetAttribute("ActiveDribbleClip", clipSpec.ClipName)
					end
					playedAny = true
				end
			else
				if tr and tr.IsPlaying then
					tr:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
				end
			end
		end

		if not playedAny and currentTracks.GModeLoop then
			local fallbackTrack = currentTracks.GModeLoop
			if not fallbackTrack.IsPlaying then
				fallbackTrack:Play(DribbleActionConfigs.LOOP_FADE_SEC)
			end
			fallbackTrack:AdjustSpeed(1.0)
			activeLoopKey = "GModeLoop"
			char:SetAttribute("ActiveDribbleClip", DribbleActionConfigs.Clips.GModeLoop.ClipName)
		end
	elseif isSprinting then
		if currentTracks.WalkDribble and currentTracks.WalkDribble.IsPlaying then
			currentTracks.WalkDribble:Stop(DribbleActionConfigs.LOOP_FADE_SEC)
		end
		stopAllGoalLoops(DribbleActionConfigs.LOOP_FADE_SEC)
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
		stopAllGoalLoops(DribbleActionConfigs.LOOP_FADE_SEC)
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
		GoalForward = nil,
		GoalBackward = nil,
		GoalLeft = nil,
		GoalRight = nil,
	}
	currentSources = {
		WalkDribble = "NONE",
		RunDribble = "NONE",
		GModeLoop = "NONE",
		GoalForward = "NONE",
		GoalBackward = "NONE",
		GoalLeft = "NONE",
		GoalRight = "NONE",
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
	if not localPlayer then
		return
	end

	if not character:IsDescendantOf(game) or localPlayer.Character ~= character then
		local deadline = os.clock() + 3.0
		while (not character:IsDescendantOf(game) or localPlayer.Character ~= character) and os.clock() < deadline do
			task.wait()
		end
		if not character:IsDescendantOf(game) or localPlayer.Character ~= character then
			return
		end
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
	attachLoopMarkers(thisGen, character, "GoalForward", tracks.GoalForward)
	attachLoopMarkers(thisGen, character, "GoalBackward", tracks.GoalBackward)
	attachLoopMarkers(thisGen, character, "GoalLeft", tracks.GoalLeft)
	attachLoopMarkers(thisGen, character, "GoalRight", tracks.GoalRight)

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
		local lp = Players.LocalPlayer
		if lp and lp.Character and (not currentAnimator or not currentCharacter) then
			task.spawn(function()
				onCharacterAdded(lp.Character :: Model)
			end)
		end
		return
	end
	isInitialized = true

	local localPlayer = Players.LocalPlayer
	assert(localPlayer ~= nil, "[DribbleAnimationController] LocalPlayer required for initialization")

	table.insert(globalConnections, localPlayer.CharacterAdded:Connect(onCharacterAdded))
	table.insert(globalConnections, localPlayer.CharacterRemoving:Connect(onCharacterRemoving))

	task.spawn(function()
		local deadline = os.clock() + 10.0
		while not localPlayer.Character and os.clock() < deadline do
			task.wait()
		end
		if localPlayer.Character then
			onCharacterAdded(localPlayer.Character)
		end
	end)
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

function DribbleAnimationController.GetGoalForwardTrack(): AnimationTrack?
	return currentTracks.GoalForward
end

function DribbleAnimationController.GetGoalBackwardTrack(): AnimationTrack?
	return currentTracks.GoalBackward
end

function DribbleAnimationController.GetGoalLeftTrack(): AnimationTrack?
	return currentTracks.GoalLeft
end

function DribbleAnimationController.GetGoalRightTrack(): AnimationTrack?
	return currentTracks.GoalRight
end

function DribbleAnimationController.GetActiveLoopKey(): string
	return activeLoopKey
end

function DribbleAnimationController.GetRegistrationSources(): DribbleAnimationHelper.LoopRegistrationSources
	return {
		WalkDribble = currentSources.WalkDribble,
		RunDribble = currentSources.RunDribble,
		GModeLoop = currentSources.GModeLoop,
		GoalForward = currentSources.GoalForward,
		GoalBackward = currentSources.GoalBackward,
		GoalLeft = currentSources.GoalLeft,
		GoalRight = currentSources.GoalRight,
	}
end

return table.freeze(DribbleAnimationController)
