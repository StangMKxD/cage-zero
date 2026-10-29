--!strict
-- src/client/character/DribbleAnimationHelper.luau
-- KeyframeSequence validator, Studio fallback registrar, and marker intent helper for R15 Dribble/Cut/G clips.
-- Governed by RF02-DRIBBLE-ANIMATION-INTEGRATION Contract (2026-10-27).

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10) :: Folder?
assert(Shared ~= nil, "[DribbleAnimationHelper] Shared folder missing in ReplicatedStorage")
local configs = Shared:WaitForChild("configs", 10) :: Folder?
assert(configs ~= nil, "[DribbleAnimationHelper] configs folder missing in Shared")
local DribbleActionConfigs = require(configs:WaitForChild("DribbleActionConfigs"))
local DribbleClipData = require(script.Parent:WaitForChild("DribbleClipData"))

export type DribbleLoopKey =
	| "WalkDribble"
	| "RunDribble"
	| "GModeLoop"
	| "GoalForward"
	| "GoalBackward"
	| "GoalLeft"
	| "GoalRight"
export type DribbleCutKey = "FrontLeft" | "FrontRight" | "BackLeft" | "BackRight" | "ReverseLeft" | "ReverseRight" | "GoalReverse"
export type DribbleClipKey = DribbleLoopKey | DribbleCutKey

export type LoopTrackCache = {
	WalkDribble: AnimationTrack?,
	RunDribble: AnimationTrack?,
	GModeLoop: AnimationTrack?,
	GoalForward: AnimationTrack?,
	GoalBackward: AnimationTrack?,
	GoalLeft: AnimationTrack?,
	GoalRight: AnimationTrack?,
}

export type LoopRegistrationSources = {
	WalkDribble: string,
	RunDribble: string,
	GModeLoop: string,
	GoalForward: string,
	GoalBackward: string,
	GoalLeft: string,
	GoalRight: string,
}

local cachedStudioTempIds: { [string]: string } = {}
local warnedProductionMissing: { [string]: boolean } = {}
local lastTouchSentTime: number = 0
local ballActionRemoteRef: RemoteEvent? = nil

local DribbleAnimationHelper = {}

local function getBallActionRemote(): RemoteEvent?
	if ballActionRemoteRef and ballActionRemoteRef.Parent then
		return ballActionRemoteRef
	end
	local remotesFolder = ReplicatedStorage:FindFirstChild("CageZeroRemotes")
	if remotesFolder then
		local r = remotesFolder:FindFirstChild("BallActionRequest")
		if r and r:IsA("RemoteEvent") then
			ballActionRemoteRef = r
		end
	end
	return ballActionRemoteRef
end

function DribbleAnimationHelper.ValidateClip(clip: Instance, spec: DribbleActionConfigs.DribbleClipSpec): (boolean, string?)
	if not clip:IsA("KeyframeSequence") then
		return false, "Clip is not a KeyframeSequence"
	end
	if clip.Name ~= spec.ClipName then
		return false, "Clip name mismatch: expected " .. spec.ClipName .. ", got " .. clip.Name
	end
	if clip.Loop ~= spec.ExpectedLoop then
		return false, "Clip Loop mismatch: expected " .. tostring(spec.ExpectedLoop) .. ", got " .. tostring(clip.Loop)
	end
	if clip.Priority ~= spec.ExpectedPriority then
		return false, "Clip Priority mismatch: expected " .. spec.ExpectedPriority.Name .. ", got " .. clip.Priority.Name
	end

	local keyframes = clip:GetKeyframes()
	if #keyframes ~= spec.ExpectedKeyframeCount then
		return false, string.format("Keyframe count mismatch: expected %d, got %d", spec.ExpectedKeyframeCount, #keyframes)
	end

	local minTime = math.huge
	local maxTime = -math.huge
	local markerCount = 0
	local hasTouchMarker = false
	for _, kf in ipairs(keyframes) do
		if kf.Time < minTime then
			minTime = kf.Time
		end
		if kf.Time > maxTime then
			maxTime = kf.Time
		end
		if kf:IsA("Keyframe") then
			local markers = kf:GetMarkers()
			markerCount += #markers
			for _, m in ipairs(markers) do
				if m.Name == "TouchL" or m.Name == "TouchR" then
					hasTouchMarker = true
				end
			end
		end
	end

	local duration = maxTime - minTime
	if math.abs(duration - spec.ExpectedDuration) > spec.DurationTolerance then
		return false, string.format("Duration mismatch: expected %.2f, got %.2f", spec.ExpectedDuration, duration)
	end

	local firstKf = keyframes[1]
	local drivenJoints = 0
	for _, desc in ipairs(firstKf:GetDescendants()) do
		if desc:IsA("Pose") and desc.Name ~= "HumanoidRootPart" then
			drivenJoints += 1
		end
	end
	if drivenJoints ~= spec.ExpectedDrivenJoints then
		return false, string.format("Driven joints mismatch: expected %d, got %d", spec.ExpectedDrivenJoints, drivenJoints)
	end

	if markerCount < 1 or not hasTouchMarker then
		return false, "Missing required TouchL/TouchR KeyframeMarkers"
	end

	return true, nil
end

function DribbleAnimationHelper.ResolveAnimation(key: string): (Animation?, string)
	local specs = DribbleActionConfigs.Clips :: { [string]: DribbleActionConfigs.DribbleClipSpec }
	local spec = specs[key]
	if not spec then
		return nil, "UNKNOWN_KEY"
	end

	local publishedMap = DribbleActionConfigs.PublishedIds :: { [string]: string? }
	local approvedCutMap = DribbleActionConfigs.ApprovedCutAnimations :: { [string]: string? }
	local publishedId = publishedMap[key]
	local cutBinding = approvedCutMap[key]
	if not publishedId and cutBinding and string.match(cutBinding, "^rbxassetid://%d+$") then
		publishedId = cutBinding
	end

	if publishedId and string.match(publishedId, "^rbxassetid://%d+$") then
		local anim = Instance.new("Animation")
		anim.Name = "R15_Dribble_" .. key .. "_Published"
		anim.AnimationId = publishedId
		return anim, "PUBLISHED"
	end

	if not DribbleActionConfigs.IsStudioFallbackAllowed() then
		if not warnedProductionMissing[key] then
			warn("[DribbleAnimationHelper] Published AnimationId for " .. key .. " is missing in production.")
			warnedProductionMissing[key] = true
		end
		return nil, "PRODUCTION_MISSING"
	end

	local clipName = spec.ClipName
	if cachedStudioTempIds[clipName] then
		local anim = Instance.new("Animation")
		anim.Name = "R15_Dribble_" .. key .. "_StudioFallback"
		anim.AnimationId = cachedStudioTempIds[clipName]
		return anim, "STUDIO_FALLBACK"
	end

	local previewRigs = workspace:FindFirstChild("PreviewRigs")
	local previewRig = previewRigs and previewRigs:FindFirstChild("PreviewRig_R15_Boy_Height30")
	local animSaves = previewRig and previewRig:FindFirstChild("AnimSaves")
	local clip: Instance? = animSaves and animSaves:FindFirstChild(clipName)
	local sourceTag = "STUDIO_FALLBACK"
	local builtTemporary = false

	if not clip then
		clip = DribbleClipData.BuildKeyframeSequence(clipName)
		sourceTag = "STUDIO_IMMUTABLE_DATA"
		builtTemporary = true
	end

	if not clip then
		warn("[DribbleAnimationHelper] Clip not found for " .. key .. " (" .. clipName .. ")")
		return nil, "CLIP_NOT_FOUND"
	end

	local isValid, err = DribbleAnimationHelper.ValidateClip(clip, spec)
	if not isValid then
		if builtTemporary then
			clip:Destroy()
		end
		warn("[DribbleAnimationHelper] Clip validation failed for " .. key .. ": " .. tostring(err))
		return nil, "CLIP_VALIDATION_FAILED"
	end

	local ok, tempId = pcall(function()
		return KeyframeSequenceProvider:RegisterKeyframeSequence(clip :: KeyframeSequence)
	end)
	if builtTemporary then
		clip:Destroy()
	end

	if not ok or not tempId or typeof(tempId) ~= "string" or #tempId == 0 then
		warn("[DribbleAnimationHelper] Failed to register KeyframeSequence for " .. key)
		return nil, "REGISTRATION_FAILED"
	end

	cachedStudioTempIds[clipName] = tempId
	local anim = Instance.new("Animation")
	anim.Name = "R15_Dribble_" .. key .. "_" .. sourceTag
	anim.AnimationId = tempId
	return anim, sourceTag
end

function DribbleAnimationHelper.WarmupCutTracks(animator: Animator)
	local cutKeys: { DribbleCutKey } = {
		"FrontLeft",
		"FrontRight",
		"BackLeft",
		"BackRight",
		"ReverseLeft",
		"ReverseRight",
		"GoalReverse",
	}
	local warmupTracks: { AnimationTrack } = {}
	local warmupAnims: { Animation } = {}

	for _, key in ipairs(cutKeys) do
		local binding = (DribbleActionConfigs.ApprovedCutAnimations :: { [string]: string? })[key]
		if binding and #binding > 0 then
			local anim = DribbleAnimationHelper.ResolveAnimation(key)
			if anim then
				table.insert(warmupAnims, anim)
				local ok, tr = pcall(function()
					return animator:LoadAnimation(anim)
				end)
				if ok and tr then
					table.insert(warmupTracks, tr)
				end
			end
		end
	end

	local deadline = os.clock() + 0.25
	while os.clock() < deadline do
		local allReady = true
		for _, tr in ipairs(warmupTracks) do
			if tr.Length <= 0 then
				allReady = false
				break
			end
		end
		if allReady then
			break
		end
		task.wait(0.02)
	end

	for _, tr in ipairs(warmupTracks) do
		pcall(function()
			tr:Stop(0)
			tr:Destroy()
		end)
	end
	for _, anim in ipairs(warmupAnims) do
		pcall(function()
			anim:Destroy()
		end)
	end
end

function DribbleAnimationHelper.LoadLoopTracks(animator: Animator): (LoopTrackCache, LoopRegistrationSources, { Animation })
	local tracks: LoopTrackCache = {
		WalkDribble = nil,
		RunDribble = nil,
		GModeLoop = nil,
		GoalForward = nil,
		GoalBackward = nil,
		GoalLeft = nil,
		GoalRight = nil,
	}
	local sources: LoopRegistrationSources = {
		WalkDribble = "NONE",
		RunDribble = "NONE",
		GModeLoop = "NONE",
		GoalForward = "NONE",
		GoalBackward = "NONE",
		GoalLeft = "NONE",
		GoalRight = "NONE",
	}
	local animInstances: { Animation } = {}

	local keys: { DribbleLoopKey } = {
		"WalkDribble",
		"RunDribble",
		"GModeLoop",
		"GoalForward",
		"GoalBackward",
		"GoalLeft",
		"GoalRight",
	}
	for _, key in ipairs(keys) do
		local anim, src = DribbleAnimationHelper.ResolveAnimation(key)
		sources[key] = src
		if anim then
			table.insert(animInstances, anim)
			local spec = (DribbleActionConfigs.Clips :: { [string]: DribbleActionConfigs.DribbleClipSpec })[key]
			local ok, track = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			if ok and track then
				track.Priority = spec.ExpectedPriority
				track.Looped = spec.ExpectedLoop
				tracks[key] = track
			else
				sources[key] = "LOAD_FAILED"
			end
		end
	end

	return tracks, sources, animInstances
end

function DribbleAnimationHelper.LoadCutTrack(animator: Animator, name: string): (AnimationTrack?, string?)
	local approved = (DribbleActionConfigs.ApprovedCutAnimations :: { [string]: string? })[name]
	if not approved or #approved == 0 then
		return nil, nil
	end

	local spec = (DribbleActionConfigs.Clips :: { [string]: DribbleActionConfigs.DribbleClipSpec })[name]
	if not spec then
		return nil, nil
	end

	local anim: Animation? = nil
	if string.match(approved, "^rbxassetid://%d+$") then
		anim = Instance.new("Animation")
		anim.Name = "R15_Cut_" .. name
		anim.AnimationId = approved
	elseif approved == spec.ClipName then
		anim = DribbleAnimationHelper.ResolveAnimation(name)
	else
		return nil, nil
	end

	if not anim then
		return nil, nil
	end

	local ok, loaded = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	anim:Destroy()
	if not ok or not loaded then
		return nil, nil
	end

	return loaded :: AnimationTrack, spec.ClipName
end

function DribbleAnimationHelper.CleanupLoopTracks(tracks: LoopTrackCache, animInstances: { Animation })
	for _, track in pairs(tracks) do
		if track then
			pcall(function()
				track:Stop(0)
				track:Destroy()
			end)
		end
	end
	for _, anim in ipairs(animInstances) do
		pcall(function()
			anim:Destroy()
		end)
	end
	table.clear(animInstances)
end

function DribbleAnimationHelper.NotifyTouchMarker(character: Model, foot: string, clipName: string, isCut: boolean)
	if not character or not character.Parent or character:GetAttribute("IsBallCarrier") ~= true then
		return
	end
	if foot ~= "L" and foot ~= "R" then
		return
	end
	local now = os.clock()
	local prevCount = character:GetAttribute("DribbleTouchCount")
	local nextCount = (if typeof(prevCount) == "number" then prevCount else 0) + 1
	character:SetAttribute("LastDribbleTouchFoot", foot)
	character:SetAttribute("LastDribbleTouchTime", now)
	character:SetAttribute("LastDribbleTouchClip", clipName)
	character:SetAttribute("DribbleTouchCount", nextCount)

	if now - lastTouchSentTime < DribbleActionConfigs.TOUCH_INTENT_COOLDOWN_SEC then
		return
	end
	lastTouchSentTime = now

	local remote = getBallActionRemote()
	if remote then
		pcall(function()
			remote:FireServer({
				action = "DribbleTouch",
				foot = foot,
				clip = clipName,
				isCut = isCut,
				character = character,
			})
		end)
	end
end

function DribbleAnimationHelper.NotifyCutIntent(character: Model, cutKey: string, exitDirection: Vector3)
	if not character or not character.Parent or character:GetAttribute("IsBallCarrier") ~= true then
		return
	end
	local horizontal = Vector3.new(exitDirection.X, 0, exitDirection.Z)
	if horizontal.Magnitude < 0.5 or horizontal.Magnitude ~= horizontal.Magnitude then
		return
	end
	local remote = getBallActionRemote()
	if remote then
		pcall(function()
			remote:FireServer({
				action = "DribbleCut",
				cut = cutKey,
				direction = horizontal.Unit,
				character = character,
			})
		end)
	end
end

return table.freeze(DribbleAnimationHelper)
