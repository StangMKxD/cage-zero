-- Retired by Owner: retained as comments, no runtime implementation.
--[====[
--!strict
-- Only an Owner-approved, successfully loaded one-shot clip can lock movement.
-- Governed by RF02-DRIBBLE-ANIMATION-INTEGRATION Contract (2026-10-27).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("configs"):WaitForChild("DribbleActionConfigs"))
local CutTimeline = require(Shared:WaitForChild("DribbleCutTimeline"))
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
local activeCutId: number? = nil
local legOffsets: {{joint: Instance, attachment: Attachment?, base: CFrame, yaw: number, roll: number}} = {}

local function disconnectAll()
	for _, conn in ipairs(activeConnections) do
		conn:Disconnect()
	end
	table.clear(activeConnections)
end

function Controller.Cancel(force: boolean?)
	local hum = lockedCharacter and lockedCharacter:FindFirstChildOfClass("Humanoid")
	if not force and track and activeCutName and CutTimeline.Get(activeCutName) and track.IsPlaying
		and track.TimePosition < CutTimeline.Duration - 0.002 and hum and hum.Health > 0
		and hum.FloorMaterial ~= Enum.Material.Air and lockedCharacter:GetAttribute("IsBallCarrier") == true then return end
	disconnectAll()
	for _,offset in legOffsets do
		if offset.attachment and offset.attachment.Parent then offset.attachment.CFrame=offset.base
		elseif offset.joint.Parent and offset.joint:IsA("Motor6D") then offset.joint.C0=offset.base end
	end
	table.clear(legOffsets)
	if lockedCharacter and activeCutId then
		DribbleAnimationHelper.NotifyCutCancel(lockedCharacter, activeCutId)
	end
	activeCutId = nil
	local wasSprintCut = activeCutName ~= nil and CutTimeline.Get(activeCutName) ~= nil
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
		lockedCharacter:SetAttribute("DribbleCutBallPhase", "")
		lockedCharacter:SetAttribute("DribbleCutVisualOwner", false)
	end
	lockedCharacter = nil
	deadline = 0
	if old then
		pcall(function()
			local fade = if wasSprintCut then Config.SPRINT_CUT_FADE_SEC else Config.CUT_FADE_SEC
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
	if character:GetAttribute("ShotActive") == true or character:GetAttribute("ShotCharging") == true then return false end
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
	local profile = CutTimeline.Get(name)
 if profile then
  local side=if profile.StrikeFoot=="L" then "Left" else "Right"
  local sign=if side=="Left" then 1 else -1
  for _,joint in character:GetDescendants() do
   if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
    local part=joint.Part1
    if part and (part.Name==side.."UpperLeg" or part.Name==side.."Foot") then
     local attachment=if joint:IsA("AnimationConstraint") then joint.Attachment0 else nil
     table.insert(legOffsets,{joint=joint,attachment=attachment,base=if attachment then attachment.CFrame else joint.C0,
      yaw=-sign*(if part.Name:find("Foot") then 6 else 8),roll=if part.Name:find("Foot") then 0 else -sign*2})
    end
   end
  end
  table.insert(activeConnections,RunService.PreSimulation:Connect(function()
   if track~=newTrack then return end
   local t=newTrack.TimePosition
   local a=if t<=CutTimeline.StrikeAt then t/CutTimeline.StrikeAt else (0.3-t)/(0.3-CutTimeline.StrikeAt)
   a=math.clamp(a,0,1);a=a*a*(3-2*a)
   for _,offset in legOffsets do
    local cf=offset.base*CFrame.Angles(0,math.rad(offset.yaw*a),math.rad(offset.roll*a))
    if offset.attachment and offset.attachment.Parent then offset.attachment.CFrame=cf
    elseif offset.joint.Parent and offset.joint:IsA("Motor6D") then offset.joint.C0=cf end
   end
  end))
 end
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
	deadline = os.clock() + math.min(Config.CUT_MAX_DURATION, newTrack.Length + 0.03)
	newTrack.Looped = false
	newTrack.Priority = Enum.AnimationPriority.Action

	character:SetAttribute("DribbleCutActive", true)
	character:SetAttribute("DribbleCutName", name)
	character:SetAttribute("DribbleCutClipName", resolvedClipName)
	character:SetAttribute("DribbleCutControlReleaseReached", false)
	character:SetAttribute("DribbleCutBallPhase", "Approach")
	character:SetAttribute("DribbleCutVisualOwner", profile ~= nil)

	if profile then
		table.insert(activeConnections, newTrack:GetMarkerReachedSignal("BallTrap"):Connect(function(foot: string)
			if track == newTrack and lockedCharacter == character then
				character:SetAttribute("DribbleCutBallPhase", "Trapped")
				DribbleAnimationHelper.NotifyTouchMarker(character, foot, resolvedClipName, true, activeCutId, "Trap")
			end
		end))
	end

	table.insert(
		activeConnections,
		newTrack:GetMarkerReachedSignal("TouchL"):Connect(function()
			if track == newTrack and lockedCharacter == character then
				cutTouchReached = true
				character:SetAttribute("DribbleCutBallPhase", "Struck")
				DribbleAnimationHelper.NotifyTouchMarker(character, "L", resolvedClipName, true, activeCutId, if profile then "Strike" else nil)
			end
		end)
	)

	table.insert(
		activeConnections,
		newTrack:GetMarkerReachedSignal("TouchR"):Connect(function()
			if track == newTrack and lockedCharacter == character then
				cutTouchReached = true
				character:SetAttribute("DribbleCutBallPhase", "Struck")
				DribbleAnimationHelper.NotifyTouchMarker(character, "R", resolvedClipName, true, activeCutId, if profile then "Strike" else nil)
			end
		end)
	)

	table.insert(
		activeConnections,
		newTrack:GetMarkerReachedSignal("ControlRelease"):Connect(function()
			if track == newTrack and lockedCharacter == character then
				character:SetAttribute("DribbleCutControlReleaseReached", true)
				character:SetAttribute("DribbleCutBallPhase", "Released")
				if profile then
					DribbleAnimationHelper.NotifyTouchMarker(character, profile.StrikeFoot, resolvedClipName, true, activeCutId, "Release")
					return
				end
				local fadeOut = Config.CUT_FADE_OUT_SEC or 0.18
				pcall(function()
					newTrack:AdjustWeight(0.001, fadeOut)
				end)
			end
		end)
	)
	if profile then
		table.insert(activeConnections, newTrack:GetMarkerReachedSignal("BlendOut"):Connect(function()
			if track == newTrack then
				character:SetAttribute("DribbleCutVisualOwner", false)
				newTrack:AdjustWeight(0.001, Config.SPRINT_CUT_FADE_OUT_SEC)
			end
		end))
	end

	table.insert(
		activeConnections,
		newTrack.Ended:Connect(function()
			if track == newTrack then
				Controller.Cancel(true)
			end
		end)
	)

	table.insert(
		activeConnections,
		newTrack.Stopped:Connect(function()
			if track == newTrack then
				Controller.Cancel(true)
			end
		end)
	)

	if exitDirection then
		activeCutId = DribbleAnimationHelper.NotifyCutIntent(character, name, exitDirection)
		if not activeCutId then Controller.Cancel() return false end
	end
	newTrack:Play(if profile then 0.08 else Config.CUT_FADE_SEC, if profile then 0.001 else 1)
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
	if activeCutName and CutTimeline.Get(activeCutName) then return false end
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
	if activeCutName and CutTimeline.Get(activeCutName) then
		local entry = activeEntryDirection or activeCutDirection
		if not cutTouchReached then return entry end
		local angle = math.atan2(entry:Cross(activeCutDirection).Y, math.clamp(entry:Dot(activeCutDirection), -1, 1))
		return CFrame.Angles(0, angle * CutTimeline.DirectionAlpha(track.TimePosition), 0):VectorToWorldSpace(entry).Unit
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

function Controller.GetMovementSpeedFactor(): number
	if track and activeCutName and CutTimeline.Get(activeCutName) then
		return CutTimeline.SpeedFactor(track.TimePosition)
	end
	return 1
end

return Controller

]====]
