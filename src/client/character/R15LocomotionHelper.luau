--!strict
-- src/client/character/R15LocomotionHelper.luau
-- Locomotion & Animation Track Orchestrator for R15 Characters
-- Manages five canonical clips: Idle, Walk, Run, Jump, and Land.
-- Governed by RF02-IDLE-RUNTIME Contract (Latest Owner Scope Lock 2026-10-26).

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10) :: Folder?
assert(Shared ~= nil, "[R15LocomotionHelper] Shared folder missing in ReplicatedStorage")
local configs = Shared:WaitForChild("configs", 10) :: Folder?
assert(configs ~= nil, "[R15LocomotionHelper] configs folder missing in Shared")
local LocomotionConfigsModule = configs:WaitForChild("R15LocomotionConfigs", 10) :: ModuleScript?
assert(LocomotionConfigsModule ~= nil, "[R15LocomotionHelper] R15LocomotionConfigs missing")
local LocomotionConfigs = require(LocomotionConfigsModule)

type ClipNameKey = "Idle" | "Walk" | "Run" | "Jump" | "Land"

export type TrackCache = {
	Idle: AnimationTrack?,
	Walk: AnimationTrack?,
	Run: AnimationTrack?,
	Jump: AnimationTrack?,
	Land: AnimationTrack?,
}

export type RegistrationSources = {
	Idle: string,
	Walk: string,
	Run: string,
	Jump: string,
	Land: string,
}

local cachedStudioTempIds: { [ClipNameKey]: string } = {}
local warnedProductionMissing: { [ClipNameKey]: boolean } = {}

local R15LocomotionHelper = {}

local function validateClip(clip: Instance, spec: any): (boolean, string?)
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
	for _, kf in ipairs(keyframes) do
		if kf.Time < minTime then
			minTime = kf.Time
		end
		if kf.Time > maxTime then
			maxTime = kf.Time
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

	return true, nil
end

local function resolveAnimation(key: ClipNameKey): (Animation?, string)
	local publishedId = LocomotionConfigs.PublishedIds[key]
	if publishedId and #publishedId > 0 then
		local anim = Instance.new("Animation")
		anim.Name = "R15_" .. key .. "_Published"
		anim.AnimationId = publishedId
		return anim, "PUBLISHED"
	end

	if not LocomotionConfigs.IsStudioFallbackAllowed() then
		if not warnedProductionMissing[key] then
			warn("[R15LocomotionHelper] Published AnimationId for " .. key .. " is missing. Falling back to native animation in production.")
			warnedProductionMissing[key] = true
		end
		return nil, "PRODUCTION_NATIVE_FALLBACK"
	end

	if cachedStudioTempIds[key] then
		local anim = Instance.new("Animation")
		anim.Name = "R15_" .. key .. "_StudioFallback"
		anim.AnimationId = cachedStudioTempIds[key]
		return anim, "STUDIO_FALLBACK"
	end

	local previewRigs = workspace:FindFirstChild("PreviewRigs")
	local previewRig = previewRigs and previewRigs:FindFirstChild("PreviewRig_R15_Boy_Height30")
	local animSaves = previewRig and previewRig:FindFirstChild("AnimSaves")
	local spec = LocomotionConfigs.Clips[key]
	local clip = animSaves and animSaves:FindFirstChild(spec.ClipName)

	if not clip then
		warn("[R15LocomotionHelper] Studio fallback clip not found for " .. key .. " (" .. spec.ClipName .. ")")
		return nil, "CLIP_NOT_FOUND"
	end

	local isValid, err = validateClip(clip, spec)
	if not isValid then
		warn("[R15LocomotionHelper] Clip validation failed for " .. key .. ":", err)
		return nil, "CLIP_VALIDATION_FAILED"
	end

	local ok, tempId = pcall(function()
		return KeyframeSequenceProvider:RegisterKeyframeSequence(clip :: KeyframeSequence)
	end)

	if not ok or not tempId or typeof(tempId) ~= "string" or #tempId == 0 then
		warn("[R15LocomotionHelper] Failed to register Studio KeyframeSequence for " .. key .. ":", tempId)
		return nil, "REGISTRATION_FAILED"
	end

	cachedStudioTempIds[key] = tempId
	local anim = Instance.new("Animation")
	anim.Name = "R15_" .. key .. "_StudioFallback"
	anim.AnimationId = tempId
	return anim, "STUDIO_FALLBACK"
end

function R15LocomotionHelper.LoadTracks(animator: Animator): (TrackCache, RegistrationSources, { Animation })
	local tracks: TrackCache = {
		Idle = nil,
		Walk = nil,
		Run = nil,
		Jump = nil,
		Land = nil,
	}
	local sources: RegistrationSources = {
		Idle = "NONE",
		Walk = "NONE",
		Run = "NONE",
		Jump = "NONE",
		Land = "NONE",
	}
	local animInstances: { Animation } = {}

	local keys: { ClipNameKey } = { "Idle", "Walk", "Run", "Jump", "Land" }
	for _, key in ipairs(keys) do
		local anim, src = resolveAnimation(key)
		sources[key] = src
		if anim then
			table.insert(animInstances, anim)
			local spec = LocomotionConfigs.Clips[key]
			local ok, track = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			if ok and track then
				track.Priority = spec.ExpectedPriority
				track.Looped = spec.ExpectedLoop
				tracks[key] = track
			else
				warn("[R15LocomotionHelper] Failed to load " .. key .. " track onto Animator:", track)
				sources[key] = "LOAD_FAILED"
			end
		end
	end

	return tracks, sources, animInstances
end

function R15LocomotionHelper.CleanupTracks(tracks: TrackCache, animInstances: { Animation })
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

return table.freeze(R15LocomotionHelper)
