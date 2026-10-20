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
			track:Stop(fade)
		end
	end

	targetTrack:Play(fade, targetProfile.weight, speed)
	currentState = newState
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

		if speed > 0.5 then
			local targetState = if (speed > 18 and activeTracks["run"] ~= nil) then "run" else "walk"
			playState(targetState)
			local track = activeTracks[targetState]
			if track and track.IsPlaying then
				local profile = configs.GetProfile(targetState)
				local baseSpeed = if profile then profile.speed else 1.0
				local speedRatio = math.clamp(speed / 16.0, 0.5, 2.0)
				track:AdjustSpeed(baseSpeed * speedRatio)
			end
		else
			playState("idle")
		end
	end

	local runningConn = humanoid.Running:Connect(function(speed: number)
		evaluateLocomotion(speed)
	end)
	table.insert(activeConnections, runningConn)

	local jumpingConn = humanoid.Jumping:Connect(function(isActive: boolean)
		if isActive then
			playState("jump", 0.05)
		end
	end)
	table.insert(activeConnections, jumpingConn)

	local freefallConn = humanoid.FreeFalling:Connect(function(isActive: boolean)
		if isActive then
			playState("fall", 0.15)
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
			playState("fall", 0.15)
		elseif newState == Enum.HumanoidStateType.Jumping then
			playState("jump", 0.05)
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

return table.freeze(R6AnimationController)
