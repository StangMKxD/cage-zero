--!strict
-- Only an Owner-approved, successfully loaded one-shot clip can lock movement.
-- Governed by RF02-DRIBBLE-ANIMATION-INTEGRATION Contract (2026-10-27).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("configs"):WaitForChild("DribbleActionConfigs"))
local CharacterFolder = script.Parent.Parent:WaitForChild("character")
local DribbleAnimationHelper = require(CharacterFolder:WaitForChild("DribbleAnimationHelper"))

local Controller = {}
local track: AnimationTrack? = nil
local activeConnections: { RBXScriptConnection } = {}
local lockedCharacter: Model? = nil
local activeCutName: string? = nil
local activeClipName: string? = nil
local activeCutDirection: Vector3? = nil
local activeEntryDirection: Vector3? = nil
local cutTouchReached: boolean = false
local deadline = 0.0

local function disconnectAll()
	for _, conn in ipairs(activeConnections) do
		conn:Disconnect()
	end
	table.clear(activeConnections)
end

function Controller.Cancel()
	disconnectAll()
	local old = track
	track = nil
	activeCutName = nil
	activeClipName = nil
	activeCutDirection = nil
	activeEntryDirection = nil
	cutTouchReached = false
	if lockedCharacter then
		lockedCharacter:SetAttribute("DribbleCutActive", false)
		lockedCharacter:SetAttribute("DribbleCutName", "")
		lockedCharacter:SetAttribute("DribbleCutClipName", "")
		lockedCharacter:SetAttribute("DribbleCutControlReleaseReached", false)
	end
	lockedCharacter = nil
	deadline = 0
	if old then
		pcall(function()
			local fade = Config.CUT_FADE_SEC or 0.15
			old:Stop(fade)
			task.delay(fade + 0.05, function()
				pcall(function()
					old:Destroy()
				end)
			end)
		end)
	end
end

function Controller.TryStart(character: Model, name: string, exitDirection: Vector3?, entryDirection: Vector3?): boolean
	if track then
		return false
	end
	if not character or character:GetAttribute("IsBallCarrier") ~= true then
		return false
	end

	local approved = (Config.ApprovedCutAnimations :: { [string]: string })[name]
	if not approved or #approved == 0 then
		return false
	end

	local hum = character:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not hum or hum.Health <= 0 or not animator or hum.FloorMaterial == Enum.Material.Air then
		return false
	end

	local newTrack, resolvedClipName = DribbleAnimationHelper.LoadCutTrack(animator, name)
	if not newTrack or not resolvedClipName then
		warn("[DribbleCut] Approved clip failed to load: " .. name)
		return false
	end

	if newTrack.Length <= 0 or newTrack.Length > Config.CUT_MAX_DURATION then
		newTrack:Destroy()
		warn("[DribbleCut] Clip is not ready or exceeds bounded lock duration: " .. name)
		return false
	end

	track = newTrack
	lockedCharacter = character
	activeCutName = name
	activeClipName = resolvedClipName
	cutTouchReached = false
	if exitDirection and exitDirection.Magnitude > 0.001 then
		activeCutDirection = exitDirection.Unit
	else
		activeCutDirection = nil
	end
	if entryDirection and entryDirection.Magnitude > 0.001 then
		activeEntryDirection = entryDirection.Unit
	else
		activeEntryDirection = activeCutDirection
	end
	deadline = os.clock() + math.min(Config.CUT_MAX_DURATION, newTrack.Length + 0.15)
	newTrack.Looped = false
	newTrack.Priority = Enum.AnimationPriority.Action

	character:SetAttribute("DribbleCutActive", true)
	character:SetAttribute("DribbleCutName", name)
	character:SetAttribute("DribbleCutClipName", resolvedClipName)
	character:SetAttribute("DribbleCutControlReleaseReached", false)

	table.insert(
		activeConnections,
		newTrack:GetMarkerReachedSignal("TouchL"):Connect(function()
			if track == newTrack and lockedCharacter == character then
				cutTouchReached = true
				DribbleAnimationHelper.NotifyTouchMarker(character, "L", resolvedClipName, true)
			end
		end)
	)

	table.insert(
		activeConnections,
		newTrack:GetMarkerReachedSignal("TouchR"):Connect(function()
			if track == newTrack and lockedCharacter == character then
				cutTouchReached = true
				DribbleAnimationHelper.NotifyTouchMarker(character, "R", resolvedClipName, true)
			end
		end)
	)

	table.insert(
		activeConnections,
		newTrack:GetMarkerReachedSignal("ControlRelease"):Connect(function()
			if track == newTrack and lockedCharacter == character then
				character:SetAttribute("DribbleCutControlReleaseReached", true)
				local fadeOut = Config.CUT_FADE_OUT_SEC or 0.18
				pcall(function()
					newTrack:AdjustWeight(0.001, fadeOut)
				end)
			end
		end)
	)

	table.insert(
		activeConnections,
		newTrack.Ended:Connect(function()
			if track == newTrack then
				Controller.Cancel()
			end
		end)
	)

	table.insert(
		activeConnections,
		newTrack.Stopped:Connect(function()
			if track == newTrack then
				Controller.Cancel()
			end
		end)
	)

	newTrack:Play(Config.CUT_FADE_SEC)
	if exitDirection then
		DribbleAnimationHelper.NotifyCutIntent(character, name, exitDirection)
	end
	return true
end

function Controller.IsLocked(character: Model): boolean
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if
		lockedCharacter ~= character
		or not hum
		or hum.Health <= 0
		or hum.FloorMaterial == Enum.Material.Air
		or character:GetAttribute("IsBallCarrier") ~= true
		or os.clock() >= deadline
		or (track ~= nil and not track.IsPlaying)
	then
		Controller.Cancel()
	end
	return track ~= nil
end

function Controller.IsControlReleased(character: Model?): boolean
	if not track or lockedCharacter ~= character then
		return true
	end
	if character and character:GetAttribute("DribbleCutControlReleaseReached") == true then
		return true
	end
	return false
end

function Controller.GetActiveTrack(): AnimationTrack?
	return track
end

function Controller.GetActiveCutName(): string?
	return activeCutName
end

function Controller.GetActiveClipName(): string?
	return activeClipName
end

function Controller.GetActiveCutDirection(): Vector3?
	if not track or not activeCutDirection then
		return activeCutDirection
	end
	if cutTouchReached then
		return activeCutDirection
	end
	local entry = activeEntryDirection or activeCutDirection
	-- For 180-degree reverse cuts (W->S), keep moving/facing along entry until the foot traps the ball (TouchR),
	-- then flip cleanly to the opposite direction so the body doesn't swing sideways right!
	if activeCutName == "ReverseLeft" or activeCutName == "ReverseRight" or activeCutName == "GoalReverse" then
		return entry
	end
	local strikePhase = Config.CUT_BALL_STRIKE_PHASE or 0.36
	local u = if track.Length > 0.01 then math.clamp(track.TimePosition / track.Length, 0, 1) else 1.0
	local alpha = math.clamp(u / math.max(0.05, strikePhase), 0, 1)
	local s = alpha * alpha * (3 - 2 * alpha)
	local blended = entry * (1 - s) + activeCutDirection * s
	if blended.Magnitude > 0.001 then
		return blended.Unit
	end
	return activeCutDirection
end

return Controller
