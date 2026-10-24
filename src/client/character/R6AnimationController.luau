--!strict
-- src/client/character/R6AnimationController.luau
-- Module 00: Client-side R6 Locomotion Animation Lifecycle & Track Controller
-- [FIX-F14] Decouple top-level unbounded waits; resolve configs lazily / via Init budget.
-- [FIX-F16] Per-setup cancellation token & generation invalidation in cleanup; post-yield guards.
-- [FIX-F17] Required clip failure fails ready status, cleans up partial resources, records error.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

export type LoadedTrackMap = { [string]: AnimationTrack }

type SetupToken = {
	generation: number,
	character: Model,
	cancelled: boolean,
}

local REQUIRED_STATES = table.freeze({ "idle", "walk", "jump", "fall" })

local R6AnimationController = {}

local currentGeneration = 0
local activeToken: SetupToken? = nil
local activeTracks: LoadedTrackMap = {}
local activeConnections: { RBXScriptConnection } = {}
local currentCharacter: Model? = nil
local currentHumanoid: Humanoid? = nil
local currentAnimator: Animator? = nil
local currentState: string = "idle"
local isReady = false
local lastError: string? = nil
local currentEvaluateLocomotion: ((speed: number) -> ())? = nil

-- Lazy action pose controller resolution & charging dual-guard
local actionPoseController: any = nil

local function getActionPoseController(): any?
	if actionPoseController ~= nil then
		return actionPoseController
	end

	local parent = script.Parent
	if parent then
		local mod = parent:FindFirstChild("R6ActionPoseController")
		if mod and mod:IsA("ModuleScript") then
			local ok, res = pcall(require, mod)
			if ok and res then
				actionPoseController = res
				return actionPoseController
			end
		end
	end

	local starterPlayer = game:GetService("StarterPlayer")
	local spScripts = starterPlayer:FindFirstChild("StarterPlayerScripts")
	if spScripts then
		local client = spScripts:FindFirstChild("Client")
		if client then
			local charFolder = client:FindFirstChild("character")
			if charFolder then
				local mod = charFolder:FindFirstChild("R6ActionPoseController")
				if mod and mod:IsA("ModuleScript") then
					local ok, res = pcall(require, mod)
					if ok and res then
						actionPoseController = res
						return actionPoseController
					end
				end
			end
		end
	end

	return nil
end

local function isCharacterCharging(char: Model?): boolean
	if not char then
		return false
	end
	if char:GetAttribute("IsCharging") == true then
		return true
	end
	local apc = getActionPoseController()
	if apc and type(apc.IsCharging) == "function" then
		local ok, result = pcall(apc.IsCharging)
		if ok and result == true then
			return true
		end
	end
	return false
end

local function isProceduralCustomPoseActive(char: Model?): boolean
	if not char then
		return false
	end
	if char:GetAttribute("IsCustomPoseActive") == true
		or char:GetAttribute("IsCustomLocomotionActive") == true
		or char:GetAttribute("IsSliding") == true
		or char:GetAttribute("IsDashing") == true
	then
		return true
	end
	local apc = getActionPoseController()
	if apc and type(apc.IsCustomPoseActive) == "function" then
		local ok, result = pcall(apc.IsCustomPoseActive)
		if ok and result == true then
			return true
		end
	end
	return false
end

-- Lazy / budget-bounded config resolution (F-14)
local resolvedConfigs: any = nil

local function getRigAnimationConfigs(timeoutSec: number?): any
	if resolvedConfigs ~= nil then
		return resolvedConfigs
	end

	local timeout = timeoutSec or 5.0
	local startTime = os.clock()

	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if not shared then
		shared = ReplicatedStorage:WaitForChild("Shared", timeout)
	end
	if not shared then
		error("[R6AnimationController] Timed out waiting for Shared in ReplicatedStorage")
	end

	local remaining = timeout - (os.clock() - startTime)
	if remaining <= 0 then
		error("[R6AnimationController] Timeout exhausted waiting for configs in Shared")
	end

	local configs = shared:FindFirstChild("configs")
	if not configs then
		configs = shared:WaitForChild("configs", remaining)
	end
	if not configs then
		error("[R6AnimationController] Timed out waiting for configs in Shared")
	end

	remaining = timeout - (os.clock() - startTime)
	if remaining <= 0 then
		error("[R6AnimationController] Timeout exhausted waiting for RigAnimationConfigs in configs")
	end

	local animConfigInst = configs:FindFirstChild("RigAnimationConfigs")
	if not animConfigInst then
		animConfigInst = configs:WaitForChild("RigAnimationConfigs", remaining)
	end
	if not animConfigInst or not animConfigInst:IsA("ModuleScript") then
		error("[R6AnimationController] Timed out waiting for RigAnimationConfigs ModuleScript")
	end

	resolvedConfigs = require(animConfigInst)
	return resolvedConfigs
end

local function cleanupTracks(tracks: LoadedTrackMap)
	for _, track in pairs(tracks) do
		pcall(function()
			track:Stop(0)
			track:Destroy()
		end)
	end
	table.clear(tracks)
end

local function cleanupConnections(conns: { RBXScriptConnection })
	for _, conn in ipairs(conns) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	table.clear(conns)
end

-- Safely verify if AnimationTrack keyframe data has loaded (Roblox AnimationTrack has no IsLoaded property; completion indicated by Length > 0)
local function isTrackAssetLoaded(track: AnimationTrack): boolean
	local ok, length = pcall(function()
		return track.Length
	end)
	return ok and typeof(length) == "number" and length > 0
end

-- [FIX-F16] Invalidate generation and cancel activeToken on cleanup
local function cleanupCurrentCharacter(targetGen: number?)
	if targetGen ~= nil and targetGen ~= currentGeneration then
		return
	end

	currentGeneration += 1
	if activeToken then
		activeToken.cancelled = true
		activeToken = nil
	end

	isReady = false
	currentState = "none"

	cleanupConnections(activeConnections)
	cleanupTracks(activeTracks)

	currentCharacter = nil
	currentHumanoid = nil
	currentAnimator = nil
	currentEvaluateLocomotion = nil
end

local function isSetupValid(token: SetupToken): boolean
	if token.cancelled then
		return false
	end
	if token.generation ~= currentGeneration then
		return false
	end
	if token.character ~= currentCharacter then
		return false
	end
	local lp = localPlayer or Players.LocalPlayer
	if lp and token.character ~= lp.Character then
		return false
	end
	if not token.character:IsDescendantOf(Workspace) then
		return false
	end
	return true
end

local function playState(newState: string, customFade: number?, customSpeed: number?)
	if not isReady then
		return
	end
	if isCharacterCharging(currentCharacter) and (newState == "walk" or newState == "sprint" or newState == "run" or newState == "idle") then
		return
	end
	if currentState == newState and activeTracks[newState] and activeTracks[newState].IsPlaying then
		return
	end

	local configs = getRigAnimationConfigs()
	local targetProfile = configs.GetProfile(newState)
	local targetTrack = activeTracks[newState]
	if not targetTrack or not targetProfile then
		return
	end

	local fade = customFade or targetProfile.fadeTime
	local speed = customSpeed or targetProfile.speed

	-- Fade out other non-action tracks if transitioning between movement/idle
	for stateName, track in pairs(activeTracks) do
		if stateName ~= newState and track.IsPlaying then
			local prof = configs.GetProfile(stateName)
			local isAction = prof and (prof.priority.Value >= Enum.AnimationPriority.Action.Value) and (stateName ~= "jump")
			if not isAction then
				track:Stop(fade)
			end
		end
	end

	targetTrack:Play(fade, targetProfile.weight, speed)
	currentState = newState
end

local function playAction(actionName: string, customFade: number?, customSpeed: number?): AnimationTrack?
	if not isReady then
		return nil
	end
	local track = activeTracks[actionName]
	if not track then
		return nil
	end

	local configs = getRigAnimationConfigs()
	local profile = configs.GetProfile(actionName)
	local fade = customFade or (if profile then profile.fadeTime else 0.05)
	local speed = customSpeed or (if profile then profile.speed else 1.0)
	local weight = if profile then profile.weight else 1.0

	track:Play(fade, weight, speed)
	return track
end

local function setupCharacter(character: Model)
	-- Clean up previous character and invalidate previous generation
	cleanupCurrentCharacter()

	currentGeneration += 1
	local thisGen = currentGeneration
	local token: SetupToken = {
		generation = thisGen,
		character = character,
		cancelled = false,
	}
	activeToken = token
	currentCharacter = character

	-- 1. Ensure character is in Workspace (bounded by 5s)
	local startWait = os.clock()
	while not character:IsDescendantOf(Workspace) do
		if os.clock() - startWait > 5.0 then
			warn("[R6AnimationController] Character not parented to Workspace within 5s")
			cleanupCurrentCharacter(thisGen)
			return
		end
		task.wait()
		if not isSetupValid(token) then
			return
		end
	end

	-- 2. Wait for Humanoid with timeout (5s)
	local humanoid = character:WaitForChild("Humanoid", 5.0) :: Humanoid?
	if not isSetupValid(token) then
		return
	end
	if not humanoid or not humanoid:IsA("Humanoid") then
		warn("[R6AnimationController] Humanoid not found in character within 5s")
		cleanupCurrentCharacter(thisGen)
		return
	end

	-- Verify R6 RigType
	if humanoid.RigType ~= Enum.HumanoidRigType.R6 then
		warn("[R6AnimationController] Non-R6 Humanoid detected, R6AnimationController stands down")
		cleanupCurrentCharacter(thisGen)
		return
	end

	-- 3. Wait for Server-Created Animator with timeout (5s)
	local animator = humanoid:WaitForChild("Animator", 5.0) :: Animator?
	if not isSetupValid(token) then
		return
	end
	if not animator or not animator:IsA("Animator") then
		warn("[R6AnimationController] Server-created Animator not found within 5s")
		cleanupCurrentCharacter(thisGen)
		return
	end

	currentHumanoid = humanoid
	currentAnimator = animator

	local newTracks: LoadedTrackMap = {}
	local newConnections: { RBXScriptConnection } = {}

	-- 4. Disable and remove any conflicting default Animate script
	local defaultAnimate = character:FindFirstChild("Animate")
	if defaultAnimate and (defaultAnimate:IsA("LuaSourceContainer") or defaultAnimate:IsA("BaseScript")) then
		(defaultAnimate :: any).Disabled = true
		defaultAnimate:Destroy()
	end

	local childAddedConn = character.ChildAdded:Connect(function(child)
		if child.Name == "Animate" and (child:IsA("LuaSourceContainer") or child:IsA("BaseScript")) then
			(child :: any).Disabled = true
			child:Destroy()
		end
	end)
	table.insert(newConnections, childAddedConn)

	-- 5. Load standard R6 animation tracks from RigAnimationConfigs (F-17)
	local configs = getRigAnimationConfigs()
	local allProfiles = configs.GetAllProfiles()

	local loadFailed = false
	local failureReason: string? = nil

	-- Step 5a: Load required clips first
	for _, reqState in ipairs(REQUIRED_STATES) do
		local profile = allProfiles[reqState]
		if not profile then
			loadFailed = true
			failureReason = string.format("Missing required animation profile for state '%s'", reqState)
			break
		end

		local anim = Instance.new("Animation")
		anim.Name = "R6_" .. reqState
		anim.AnimationId = profile.assetId

		local ok, trackOrErr = pcall(function()
			return animator:LoadAnimation(anim)
		end)

		if not ok or not trackOrErr then
			loadFailed = true
			failureReason = string.format("Failed animator:LoadAnimation for required state '%s' (%s): %s", reqState, profile.assetId, tostring(trackOrErr))
			break
		end

		local track = trackOrErr :: AnimationTrack
		track.Priority = profile.priority
		track.Looped = profile.looped
		newTracks[reqState] = track
	end

	-- Also load optional / secondary profiles (run, climb) if present
	if not loadFailed then
		for stateName, profile in pairs(allProfiles) do
			if newTracks[stateName] == nil then
				local anim = Instance.new("Animation")
				anim.Name = "R6_" .. stateName
				anim.AnimationId = profile.assetId
				local ok, track = pcall(function()
					return animator:LoadAnimation(anim)
				end)
				if ok and track then
					track.Priority = profile.priority
					track.Looped = profile.looped
					newTracks[stateName] = track
				end
			end
		end
	end

	-- Check setup validity after track creation
	if not isSetupValid(token) then
		cleanupTracks(newTracks)
		cleanupConnections(newConnections)
		return
	end

	-- Step 5b: Asset loaded verification for required tracks (verified via Length > 0)
	if not loadFailed then
		for _, reqState in ipairs(REQUIRED_STATES) do
			local track = newTracks[reqState]
			local profile = allProfiles[reqState]

			if not isTrackAssetLoaded(track) then
				local waitStart = os.clock()
				while not isTrackAssetLoaded(track) and (os.clock() - waitStart) < 3.0 do
					task.wait()
					if not isSetupValid(token) then
						cleanupTracks(newTracks)
						cleanupConnections(newConnections)
						return
					end
				end
			end

			if not isTrackAssetLoaded(track) then
				loadFailed = true
				local currLen = 0
				pcall(function()
					currLen = track.Length
				end)
				failureReason = string.format("Required animation asset failed to load for state '%s' (%s): Length=%.3f (expected > 0)", reqState, profile.assetId, currLen)
				break
			end
		end
	end

	-- Step 5c: Handle clip failure (clean up partial resources, do NOT mark ready)
	if loadFailed then
		cleanupTracks(newTracks)
		cleanupConnections(newConnections)
		isReady = false
		lastError = failureReason
		warn(string.format("[R6AnimationController] Setup failed: %s", tostring(failureReason)))
		return
	end

	-- Check setup validity before publishing
	if not isSetupValid(token) then
		cleanupTracks(newTracks)
		cleanupConnections(newConnections)
		return
	end

	-- Step 5d: Publish active tracks & connections
	activeTracks = newTracks
	for _, conn in ipairs(newConnections) do
		table.insert(activeConnections, conn)
	end

	-- 6. Connect locomotion states via Humanoid events & StateChanged
	local function evaluateLocomotion(speed: number)
		if not isReady or not isSetupValid(token) then
			return
		end
		if humanoid.FloorMaterial == Enum.Material.Air then
			return
		end

		-- Do not layer walk/run/sprint/idle over charging kick stance or active authored procedural poses!
		if isCharacterCharging(character) or isProceduralCustomPoseActive(character) then
			if activeTracks["walk"] and activeTracks["walk"].IsPlaying then
				activeTracks["walk"]:Stop(0.08)
			end
			if activeTracks["sprint"] and activeTracks["sprint"].IsPlaying then
				activeTracks["sprint"]:Stop(0.08)
			end
			if activeTracks["run"] and activeTracks["run"].IsPlaying then
				activeTracks["run"]:Stop(0.08)
			end
			if activeTracks["idle"] and activeTracks["idle"].IsPlaying then
				activeTracks["idle"]:Stop(0.08)
			end
			return
		end

		if speed > 0.5 then
			local targetState = "walk"
			if speed > 22 and activeTracks["sprint"] ~= nil then
				targetState = "sprint"
			elseif speed > 16 and activeTracks["run"] ~= nil then
				targetState = "run"
			end
			playState(targetState)
			local track = activeTracks[targetState]
			if track and track.IsPlaying then
				local naturalSpeed = math.clamp(speed / 16.0, 0.85, 1.35)
				track:AdjustSpeed(naturalSpeed)
			end
		else
			playState("idle")
		end
	end

	currentEvaluateLocomotion = evaluateLocomotion

	local runningConn = humanoid.Running:Connect(function(speed: number)
		evaluateLocomotion(speed)
	end)
	table.insert(activeConnections, runningConn)

	local jumpingConn = humanoid.Jumping:Connect(function(isActive: boolean)
		if isActive then
			if not isProceduralCustomPoseActive(character) then
				playState("jump", 0.05)
			end
		end
	end)
	table.insert(activeConnections, jumpingConn)

	local freefallConn = humanoid.FreeFalling:Connect(function(isActive: boolean)
		if isActive then
			if not isProceduralCustomPoseActive(character) then
				playState("fall", 0.15)
			end
		else
			evaluateLocomotion(humanoid.MoveDirection.Magnitude > 0 and humanoid.WalkSpeed or 0)
		end
	end)
	table.insert(activeConnections, freefallConn)

	local climbingConn = humanoid.Climbing:Connect(function(speed: number)
		if math.abs(speed) > 0.1 then
			playState("climb")
		else
			if activeTracks["climb"] then
				activeTracks["climb"]:AdjustSpeed(0)
			end
		end
	end)
	table.insert(activeConnections, climbingConn)

	local stateChangedConn = humanoid.StateChanged:Connect(function(_oldState, newState)
		if not isReady or not isSetupValid(token) then
			return
		end
		if newState == Enum.HumanoidStateType.Landed then
			evaluateLocomotion(humanoid.MoveDirection.Magnitude > 0 and humanoid.WalkSpeed or 0)
		elseif newState == Enum.HumanoidStateType.Freefall then
			if not isProceduralCustomPoseActive(character) then
				playState("fall", 0.15)
			end
		elseif newState == Enum.HumanoidStateType.Jumping then
			if not isProceduralCustomPoseActive(character) then
				playState("jump", 0.05)
			end
		elseif newState == Enum.HumanoidStateType.Climbing then
			playState("climb")
		elseif newState == Enum.HumanoidStateType.Running then
			evaluateLocomotion(humanoid.MoveDirection.Magnitude > 0 and humanoid.WalkSpeed or 0)
		elseif newState == Enum.HumanoidStateType.Dead then
			cleanupCurrentCharacter(thisGen)
		end
	end)
	table.insert(activeConnections, stateChangedConn)

	local diedConn = humanoid.Died:Connect(function()
		cleanupCurrentCharacter(thisGen)
	end)
	table.insert(activeConnections, diedConn)

	local chargingConn = character:GetAttributeChangedSignal("IsCharging"):Connect(function()
		if not isReady or not isSetupValid(token) then
			return
		end
		local isChg = isCharacterCharging(character)
		if isChg then
			if activeTracks["walk"] and activeTracks["walk"].IsPlaying then
				activeTracks["walk"]:Stop(0.08)
			end
			if activeTracks["sprint"] and activeTracks["sprint"].IsPlaying then
				activeTracks["sprint"]:Stop(0.08)
			end
			if activeTracks["run"] and activeTracks["run"].IsPlaying then
				activeTracks["run"]:Stop(0.08)
			end
			if activeTracks["idle"] and activeTracks["idle"].IsPlaying then
				activeTracks["idle"]:Stop(0.08)
			end
		else
			evaluateLocomotion(humanoid.MoveDirection.Magnitude > 0 and humanoid.WalkSpeed or 0)
		end
	end)
	table.insert(activeConnections, chargingConn)

	local customPoseConn = character:GetAttributeChangedSignal("IsCustomPoseActive"):Connect(function()
		if not isReady or not isSetupValid(token) then
			return
		end
		if isProceduralCustomPoseActive(character) then
			if activeTracks["walk"] and activeTracks["walk"].IsPlaying then
				activeTracks["walk"]:Stop(0.08)
			end
			if activeTracks["sprint"] and activeTracks["sprint"].IsPlaying then
				activeTracks["sprint"]:Stop(0.08)
			end
			if activeTracks["run"] and activeTracks["run"].IsPlaying then
				activeTracks["run"]:Stop(0.08)
			end
			if activeTracks["idle"] and activeTracks["idle"].IsPlaying then
				activeTracks["idle"]:Stop(0.08)
			end
			if activeTracks["jump"] and activeTracks["jump"].IsPlaying then
				activeTracks["jump"]:Stop(0.08)
			end
			if activeTracks["fall"] and activeTracks["fall"].IsPlaying then
				activeTracks["fall"]:Stop(0.08)
			end
		else
			evaluateLocomotion(humanoid.MoveDirection.Magnitude > 0 and humanoid.WalkSpeed or 0)
		end
	end)
	table.insert(activeConnections, customPoseConn)

	local ancestryConn = character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			cleanupCurrentCharacter(thisGen)
		end
	end)
	table.insert(activeConnections, ancestryConn)

	-- Publish ready status
	isReady = true
	lastError = nil

	-- Start with initial idle state
	playState("idle")
end

function R6AnimationController.Init(timeoutSec: number?)
	-- Pre-resolve configs within budget
	local ok, err = pcall(function()
		getRigAnimationConfigs(timeoutSec)
	end)
	if not ok then
		error(string.format("[R6AnimationController.Init] Failed to resolve RigAnimationConfigs within budget: %s", tostring(err)))
	end

	if not localPlayer then
		localPlayer = Players.LocalPlayer
	end
	if not localPlayer then
		error("[R6AnimationController.Init] Players.LocalPlayer is nil on client")
	end

	if localPlayer.Character and localPlayer.Character:IsDescendantOf(Workspace) then
		task.spawn(setupCharacter, localPlayer.Character)
	end

	localPlayer.CharacterAdded:Connect(function(newChar)
		setupCharacter(newChar)
	end)

	localPlayer.CharacterRemoving:Connect(function(removingChar: Model)
		if removingChar == currentCharacter or currentCharacter == nil then
			cleanupCurrentCharacter()
		end
	end)
end

function R6AnimationController.GetCurrentState(): string
	return currentState
end

function R6AnimationController.GetActiveTracks(): LoadedTrackMap
	return activeTracks
end

function R6AnimationController.GetGeneration(): number
	return currentGeneration
end

function R6AnimationController.IsReady(): boolean
	return isReady
end

function R6AnimationController.GetLastError(): string?
	return lastError
end

function R6AnimationController.GetRequiredStates(): { string }
	return REQUIRED_STATES
end

function R6AnimationController.PlayAction(actionName: string, customFade: number?, customSpeed: number?): AnimationTrack?
	local mapped = actionName
	if actionName == "DirectShoot" or actionName == "CurveShoot" then
		mapped = "kick"
	elseif actionName == "Pass" or actionName == "GroundPass" then
		mapped = "pass"
	elseif actionName == "Slide" or actionName == "SlideTackle" then
		mapped = "slide"
	elseif actionName == "Header" then
		mapped = "header"
	elseif actionName == "Volley" then
		mapped = "volley"
	elseif actionName == "Dash" then
		mapped = "dash"
	elseif actionName == "Sprint" then
		mapped = "sprint"
	end

	if mapped == "pass" then
		-- Pass is an authentic low inside-foot push driven authoritatively by R6ActionPoseController (A16).
		-- Stop any high-kick animation track so it does not distort the inside-foot pass.
		if activeTracks["kick"] and activeTracks["kick"].IsPlaying then
			activeTracks["kick"]:Stop(0.05)
		end
		return nil
	end

	return playAction(mapped, customFade, customSpeed)
end

function R6AnimationController.PlayState(stateName: string, customFade: number?, customSpeed: number?)
	playState(stateName, customFade, customSpeed)
end

function R6AnimationController.StopAction(actionName: string, customFade: number?)
	local track = activeTracks[actionName]
	if track and track.IsPlaying then
		track:Stop(customFade or 0.1)
	end
end

function R6AnimationController.GetTrack(stateName: string): AnimationTrack?
	return activeTracks[stateName]
end

function R6AnimationController.IsActionPlaying(actionName: string): boolean
	local track = activeTracks[actionName]
	return track ~= nil and track.IsPlaying
end

function R6AnimationController.RestoreLocomotion()
	if not isReady or not currentCharacter or not currentHumanoid then
		return
	end
	if isCharacterCharging(currentCharacter) then
		return
	end
	if currentEvaluateLocomotion then
		local speed = if currentHumanoid.MoveDirection.Magnitude > 0 then currentHumanoid.WalkSpeed else 0
		currentEvaluateLocomotion(speed)
	else
		playState(if currentHumanoid.MoveDirection.Magnitude > 0 then "walk" else "idle", 0.15)
	end
end

function R6AnimationController.IsCharging(): boolean
	return isCharacterCharging(currentCharacter)
end

function R6AnimationController.SetChargingSuppressed(suppressed: boolean)
	if not isReady or not currentCharacter or not currentHumanoid then
		return
	end
	if suppressed then
		if activeTracks["walk"] and activeTracks["walk"].IsPlaying then activeTracks["walk"]:Stop(0.08) end
		if activeTracks["sprint"] and activeTracks["sprint"].IsPlaying then activeTracks["sprint"]:Stop(0.08) end
		if activeTracks["run"] and activeTracks["run"].IsPlaying then activeTracks["run"]:Stop(0.08) end
		if activeTracks["idle"] and activeTracks["idle"].IsPlaying then activeTracks["idle"]:Stop(0.08) end
	else
		R6AnimationController.RestoreLocomotion()
	end
end

function R6AnimationController.GetActiveLocomotionState(): string
	if currentCharacter then
		local locState = currentCharacter:GetAttribute("ActiveLocomotionState") :: string?
		if locState and #locState > 0 then
			return locState
		end
	end
	return currentState
end

return table.freeze(R6AnimationController)
