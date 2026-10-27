--!strict
-- src/shared/configs/R15LocomotionConfigs.luau
-- Authoritative Consolidated Configuration for R15 Locomotion Animation Runtime
-- Covers canonical Idle, Walk, Run, Jump, and Land clips.
-- Governed by RF02-IDLE-RUNTIME Contract (Latest Owner Scope Lock 2026-10-26).

local RunService = game:GetService("RunService")

export type ClipSpec = {
	ClipName: string,
	ExpectedKeyframeCount: number,
	ExpectedDuration: number,
	DurationTolerance: number,
	ExpectedLoop: boolean,
	ExpectedPriority: Enum.AnimationPriority,
	ExpectedDrivenJoints: number,
}

export type JumpLandmarkSpec = {
	DipStart: number,
	DipEnd: number,
	PushOff: number,
	Rise: number,
	Apex: number,
	DescentHold: number,
	Touchdown: number,
}

local R15LocomotionConfigs = {}

R15LocomotionConfigs.STUDIO_FALLBACK_ENABLED = true
R15LocomotionConfigs.PREVIEW_RIG_PATH = "Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30"
R15LocomotionConfigs.ANIMSAVES_CONTAINER = "AnimSaves"

-- Published Animation IDs: MUST remain nil until officially published to Roblox asset store.
-- Native animations serve as fallback in production.
R15LocomotionConfigs.PublishedIds = {
	Idle = nil :: string?,
	Walk = nil :: string?,
	Run = nil :: string?,
	Jump = nil :: string?,
	Land = nil :: string?,
}

R15LocomotionConfigs.Clips = table.freeze({
	Idle = table.freeze({
		ClipName = "RF02_Idle_Ready_R15_v01",
		ExpectedKeyframeCount = 9,
		ExpectedDuration = 4.80,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Idle,
		ExpectedDrivenJoints = 15,
	}) :: ClipSpec,

	Walk = table.freeze({
		ClipName = "RF02_Walk_Ready_R15_v01",
		ExpectedKeyframeCount = 33,
		ExpectedDuration = 1.12,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
	}) :: ClipSpec,

	Run = table.freeze({
		ClipName = "RF02_Run_Ready_R15_v01",
		ExpectedKeyframeCount = 33,
		ExpectedDuration = 0.76,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
	}) :: ClipSpec,

	Jump = table.freeze({
		ClipName = "RF02_Jump_Ready_R15_v01",
		ExpectedKeyframeCount = 49,
		ExpectedDuration = 1.80,
		DurationTolerance = 0.05,
		ExpectedLoop = false,
		ExpectedPriority = Enum.AnimationPriority.Action,
		ExpectedDrivenJoints = 15,
	}) :: ClipSpec,

	Land = table.freeze({
		ClipName = "RF02_Land_Ready_R15_v01",
		ExpectedKeyframeCount = 29,
		ExpectedDuration = 0.84,
		DurationTolerance = 0.05,
		ExpectedLoop = false,
		ExpectedPriority = Enum.AnimationPriority.Action,
		ExpectedDrivenJoints = 15,
	}) :: ClipSpec,
})

-- Landmark phases of the authored 1.8s jump sequence
R15LocomotionConfigs.JumpLandmarks = table.freeze({
	DipStart = 0.18,
	DipEnd = 0.36,
	PushOff = 0.56,
	Rise = 0.85,
	Apex = 1.08,
	DescentHold = 1.38,
	Touchdown = 1.56,
}) :: JumpLandmarkSpec

R15LocomotionConfigs.Playback = table.freeze({
	IdleFadeTime = 0.25,
	WalkFadeTime = 0.20,
	RunFadeTime = 0.20,
	JumpFadeTime = 0.10,
	LandFadeTime = 0.15,

	MoveDirectionThreshold = 0.01,
	SpeedStationaryThreshold = 0.5,
	SprintSpeedThreshold = 24.0,
})

function R15LocomotionConfigs.IsStudioFallbackAllowed(): boolean
	return R15LocomotionConfigs.STUDIO_FALLBACK_ENABLED and RunService:IsStudio()
end

return table.freeze(R15LocomotionConfigs)
