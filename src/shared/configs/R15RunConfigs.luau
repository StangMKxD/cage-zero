--!strict
-- src/shared/configs/R15RunConfigs.luau
-- Configuration for R15 Run Animation Runtime
-- Governed by RF02-IDLE-RUNTIME Contract (Owner Scope Delta 2026-10-26)

local RunService = game:GetService("RunService")

export type StudioRunClipSpec = {
	RigPath: string,
	AnimSavesName: string,
	ClipName: string,
	ExpectedKeyframeCount: number,
	ExpectedDuration: number,
	DurationTolerance: number,
	ExpectedLoop: boolean,
	ExpectedPriority: Enum.AnimationPriority,
	ExpectedDrivenJoints: number,
}

export type RunPlaybackSettings = {
	FadeTime: number,
	Speed: number,
	Priority: Enum.AnimationPriority,
	Looped: boolean,
}

local R15RunConfigs = {}

-- Explicit production asset ID: empty/nil until asset is published.
-- Native walk/run animation will be used if published ID is absent.
R15RunConfigs.PUBLISHED_ANIMATION_ID = nil :: string?

R15RunConfigs.STUDIO_FALLBACK_ENABLED = true

R15RunConfigs.Playback = table.freeze({
	FadeTime = 0.20,
	Speed = 1.0,
	Priority = Enum.AnimationPriority.Movement,
	Looped = true,
}) :: RunPlaybackSettings

R15RunConfigs.StudioClip = table.freeze({
	RigPath = "Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30",
	AnimSavesName = "AnimSaves",
	ClipName = "RF02_Run_Ready_R15_v01",
	ExpectedKeyframeCount = 33,
	ExpectedDuration = 0.76,
	DurationTolerance = 0.05,
	ExpectedLoop = true,
	ExpectedPriority = Enum.AnimationPriority.Movement,
	ExpectedDrivenJoints = 15,
}) :: StudioRunClipSpec

function R15RunConfigs.IsStudioFallbackAllowed(): boolean
	return R15RunConfigs.STUDIO_FALLBACK_ENABLED and RunService:IsStudio()
end

return table.freeze(R15RunConfigs)
