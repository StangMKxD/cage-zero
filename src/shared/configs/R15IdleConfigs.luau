--!strict
-- src/shared/configs/R15IdleConfigs.luau
-- Configuration for R15 Idle Animation Runtime
-- Governed by RF02-IDLE-RUNTIME Contract (Round 1)

local RunService = game:GetService("RunService")

export type StudioClipSpec = {
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

export type PlaybackSettings = {
	FadeTime: number,
	Speed: number,
	Priority: Enum.AnimationPriority,
	Looped: boolean,
	MovementSpeedThreshold: number,
	MoveDirectionThreshold: number,
}

export type R15IdleConfig = {
	-- Production Published Asset ID.
	-- MUST remain nil / empty until explicitly published to Roblox cloud asset store.
	-- Invented IDs / UUIDs are strictly prohibited.
	PUBLISHED_ANIMATION_ID: string?,

	STUDIO_FALLBACK_ENABLED: boolean,
	Playback: PlaybackSettings,
	StudioClip: StudioClipSpec,
	IsStudioFallbackAllowed: () -> boolean,
}

local R15IdleConfigs = {}

-- Explicit production asset ID: empty/nil until asset is published.
-- Native animation will be used if published ID is absent.
R15IdleConfigs.PUBLISHED_ANIMATION_ID = nil :: string?

R15IdleConfigs.STUDIO_FALLBACK_ENABLED = true

R15IdleConfigs.Playback = table.freeze({
	FadeTime = 0.25,
	Speed = 1.0,
	Priority = Enum.AnimationPriority.Idle,
	Looped = true,
	MovementSpeedThreshold = 0.1,
	MoveDirectionThreshold = 0.01,
}) :: PlaybackSettings

R15IdleConfigs.StudioClip = table.freeze({
	RigPath = "Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30",
	AnimSavesName = "AnimSaves",
	ClipName = "RF02_Idle_Ready_R15_v01",
	ExpectedKeyframeCount = 9,
	ExpectedDuration = 4.8,
	DurationTolerance = 0.05,
	ExpectedLoop = true,
	ExpectedPriority = Enum.AnimationPriority.Idle,
	ExpectedDrivenJoints = 15,
}) :: StudioClipSpec

function R15IdleConfigs.IsStudioFallbackAllowed(): boolean
	return R15IdleConfigs.STUDIO_FALLBACK_ENABLED and RunService:IsStudio()
end

return table.freeze(R15IdleConfigs)
