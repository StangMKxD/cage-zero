--!strict
-- Owner-approved G hold / R15 dribble animation runtime bindings.
-- Governed by RF02-DRIBBLE-ANIMATION-INTEGRATION Contract (2026-10-27).

local RunService = game:GetService("RunService")

export type DribbleClipSpec = {
	ClipName: string,
	ExpectedKeyframeCount: number,
	ExpectedDuration: number,
	DurationTolerance: number,
	ExpectedLoop: boolean,
	ExpectedPriority: Enum.AnimationPriority,
	ExpectedDrivenJoints: number,
	ExpectedMarkerCount: number,
	ControlReleaseTime: number?,
}

local DribbleActionConfigs = {}

DribbleActionConfigs.GOAL_SPEED = 8.0
DribbleActionConfigs.GOAL_BALL_DISTANCE = 1.95
DribbleActionConfigs.GOAL_CARRIER_SEPARATION = 1.85
DribbleActionConfigs.GOAL_INTENT_TIMEOUT = 0.5
DribbleActionConfigs.INTENT_INTERVAL = 0.1
DribbleActionConfigs.STUDIO_FALLBACK_ENABLED = true
DribbleActionConfigs.PREVIEW_RIG_PATH = "Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30"
DribbleActionConfigs.ANIMSAVES_CONTAINER = "AnimSaves"
DribbleActionConfigs.LOOP_FADE_SEC = 0.18
DribbleActionConfigs.WALK_BASE_SPEED = 16.0
DribbleActionConfigs.RUN_BASE_SPEED = 32.0
DribbleActionConfigs.GOAL_BASE_SPEED = 8.0

-- Marker-driven forward touch coordination (bounded, server-validated)
DribbleActionConfigs.TOUCH_INTENT_COOLDOWN_SEC = 0.08
DribbleActionConfigs.TOUCH_PULSE_DURATION_SEC = 0.24
DribbleActionConfigs.TOUCH_PULSE_BOOST_WALK = 0.38
DribbleActionConfigs.TOUCH_PULSE_BOOST_RUN = 0.62
DribbleActionConfigs.TOUCH_PULSE_BOOST_GOAL = 0.18
-- Orbit / radial speed multiplier when an animation foot-touch marker strikes the ball
DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_WALK = 1.65
DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_RUN = 2.05
DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_GOAL = 1.35
DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_WALK = 4.5
DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_RUN = 8.5
DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_GOAL = 1.2

-- Published asset IDs remain nil until officially published; Studio uses validated local KeyframeSequences.
DribbleActionConfigs.PublishedIds = table.freeze({
	WalkDribble = nil :: string?,
	RunDribble = nil :: string?,
	GModeLoop = nil :: string?,
	GoalForward = nil :: string?,
	GoalBackward = nil :: string?,
	GoalLeft = nil :: string?,
	GoalRight = nil :: string?,
})

DribbleActionConfigs.Clips = table.freeze({
	WalkDribble = table.freeze({
		ClipName = "RF02_JogForwardMixamo_R15_v02",
		ExpectedKeyframeCount = 26,
		ExpectedDuration = 0.833,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 2,
	}) :: DribbleClipSpec,

	RunDribble = table.freeze({
		ClipName = "RF02_FastRunMixamo_R15_v02",
		ExpectedKeyframeCount = 17,
		ExpectedDuration = 0.533,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 2,
	}) :: DribbleClipSpec,

	GModeLoop = table.freeze({
		ClipName = "RF02_GMode_SlowControlLoop_R15_v01",
		ExpectedKeyframeCount = 225,
		ExpectedDuration = 1.12,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 5,
	}) :: DribbleClipSpec,

	GoalForward = table.freeze({
		ClipName = "RF02_GMode_SoleRollForward_W_R15_v01",
		ExpectedKeyframeCount = 129,
		ExpectedDuration = 0.64,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 4,
	}) :: DribbleClipSpec,

	GoalBackward = table.freeze({
		ClipName = "RF02_GMode_SoleRollBackward_S_R15_v01",
		ExpectedKeyframeCount = 129,
		ExpectedDuration = 0.64,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 4,
	}) :: DribbleClipSpec,

	GoalLeft = table.freeze({
		ClipName = "RF02_GMode_SoleRollLeft_A_R15_v01",
		ExpectedKeyframeCount = 193,
		ExpectedDuration = 0.96,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 5,
	}) :: DribbleClipSpec,

	GoalRight = table.freeze({
		ClipName = "RF02_GMode_SoleRollRight_D_R15_v01",
		ExpectedKeyframeCount = 193,
		ExpectedDuration = 0.96,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 5,
	}) :: DribbleClipSpec,
})

local recognizedClipNames: { [string]: boolean } = {
	RF02_JogForwardMixamo_R15_v02 = true,
	RF02_FastRunMixamo_R15_v02 = true,
	RF02_GMode_SlowControlLoop_R15_v01 = true,
	RF02_GMode_SoleRollForward_W_R15_v01 = true,
	RF02_GMode_SoleRollBackward_S_R15_v01 = true,
	RF02_GMode_SoleRollLeft_A_R15_v01 = true,
	RF02_GMode_SoleRollRight_D_R15_v01 = true,
}

function DribbleActionConfigs.IsRecognizedClipName(clipName: string): boolean
	return recognizedClipNames[clipName] == true
end

function DribbleActionConfigs.IsGoalModeClipName(clipName: string): boolean
	return clipName == "RF02_GMode_SlowControlLoop_R15_v01"
		or clipName == "RF02_GMode_SoleRollForward_W_R15_v01"
		or clipName == "RF02_GMode_SoleRollBackward_S_R15_v01"
		or clipName == "RF02_GMode_SoleRollLeft_A_R15_v01"
		or clipName == "RF02_GMode_SoleRollRight_D_R15_v01"
end

function DribbleActionConfigs.IsStudioFallbackAllowed(): boolean
	return DribbleActionConfigs.STUDIO_FALLBACK_ENABLED and RunService:IsStudio()
end

return table.freeze(DribbleActionConfigs)


--[========[
Previous implementation retained at Owner request.
--!strict
-- Owner-approved G hold / R15 dribble animation runtime bindings.
-- Governed by RF02-DRIBBLE-ANIMATION-INTEGRATION Contract (2026-10-27).

local RunService = game:GetService("RunService")

export type DribbleClipSpec = {
	ClipName: string,
	ExpectedKeyframeCount: number,
	ExpectedDuration: number,
	DurationTolerance: number,
	ExpectedLoop: boolean,
	ExpectedPriority: Enum.AnimationPriority,
	ExpectedDrivenJoints: number,
	ExpectedMarkerCount: number,
	ControlReleaseTime: number?,
}

local DribbleActionConfigs = {}

DribbleActionConfigs.GOAL_SPEED = 8.0
DribbleActionConfigs.GOAL_BALL_DISTANCE = 1.95
DribbleActionConfigs.GOAL_CARRIER_SEPARATION = 1.85
DribbleActionConfigs.GOAL_INTENT_TIMEOUT = 0.5
DribbleActionConfigs.INTENT_INTERVAL = 0.1
DribbleActionConfigs.STUDIO_FALLBACK_ENABLED = true
DribbleActionConfigs.PREVIEW_RIG_PATH = "Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30"
DribbleActionConfigs.ANIMSAVES_CONTAINER = "AnimSaves"
DribbleActionConfigs.LOOP_FADE_SEC = 0.18
DribbleActionConfigs.WALK_BASE_SPEED = 16.0
DribbleActionConfigs.RUN_BASE_SPEED = 32.0
DribbleActionConfigs.GOAL_BASE_SPEED = 8.0

-- Marker-driven forward touch coordination (bounded, server-validated)
DribbleActionConfigs.TOUCH_INTENT_COOLDOWN_SEC = 0.08
DribbleActionConfigs.TOUCH_PULSE_DURATION_SEC = 0.24
DribbleActionConfigs.TOUCH_PULSE_BOOST_WALK = 0.38
DribbleActionConfigs.TOUCH_PULSE_BOOST_RUN = 0.62
DribbleActionConfigs.TOUCH_PULSE_BOOST_GOAL = 0.18
-- Orbit / radial speed multiplier when an animation foot-touch marker strikes the ball
DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_WALK = 1.65
DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_RUN = 2.05
DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_GOAL = 1.35
DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_WALK = 4.5
DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_RUN = 8.5
DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_GOAL = 1.2

-- Published asset IDs remain nil until officially published; Studio uses validated local KeyframeSequences.
DribbleActionConfigs.PublishedIds = table.freeze({
	WalkDribble = nil :: string?,
	RunDribble = nil :: string?,
	GModeLoop = nil :: string?,
	GoalForward = nil :: string?,
	GoalBackward = nil :: string?,
	GoalLeft = nil :: string?,
	GoalRight = nil :: string?,
})

DribbleActionConfigs.Clips = table.freeze({
	WalkDribble = table.freeze({
		ClipName = "RF02_WalkDribble_R15_v01",
		ExpectedKeyframeCount = 91,
		ExpectedDuration = 3.0,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 6,
	}) :: DribbleClipSpec,

	RunDribble = table.freeze({
		ClipName = "RF02_RunDribble_R15_v01",
		ExpectedKeyframeCount = 145,
		ExpectedDuration = 0.72,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 5,
	}) :: DribbleClipSpec,

	GModeLoop = table.freeze({
		ClipName = "RF02_GMode_SlowControlLoop_R15_v01",
		ExpectedKeyframeCount = 225,
		ExpectedDuration = 1.12,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 5,
	}) :: DribbleClipSpec,

	GoalForward = table.freeze({
		ClipName = "RF02_GMode_SoleRollForward_W_R15_v01",
		ExpectedKeyframeCount = 129,
		ExpectedDuration = 0.64,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 4,
	}) :: DribbleClipSpec,

	GoalBackward = table.freeze({
		ClipName = "RF02_GMode_SoleRollBackward_S_R15_v01",
		ExpectedKeyframeCount = 129,
		ExpectedDuration = 0.64,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 4,
	}) :: DribbleClipSpec,

	GoalLeft = table.freeze({
		ClipName = "RF02_GMode_SoleRollLeft_A_R15_v01",
		ExpectedKeyframeCount = 193,
		ExpectedDuration = 0.96,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 5,
	}) :: DribbleClipSpec,

	GoalRight = table.freeze({
		ClipName = "RF02_GMode_SoleRollRight_D_R15_v01",
		ExpectedKeyframeCount = 193,
		ExpectedDuration = 0.96,
		DurationTolerance = 0.05,
		ExpectedLoop = true,
		ExpectedPriority = Enum.AnimationPriority.Movement,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 5,
	}) :: DribbleClipSpec,
})

local recognizedClipNames: { [string]: boolean } = {
	RF02_WalkDribble_R15_v01 = true,
	RF02_RunDribble_R15_v01 = true,
	RF02_GMode_SlowControlLoop_R15_v01 = true,
	RF02_GMode_SoleRollForward_W_R15_v01 = true,
	RF02_GMode_SoleRollBackward_S_R15_v01 = true,
	RF02_GMode_SoleRollLeft_A_R15_v01 = true,
	RF02_GMode_SoleRollRight_D_R15_v01 = true,
}

function DribbleActionConfigs.IsRecognizedClipName(clipName: string): boolean
	return recognizedClipNames[clipName] == true
end

function DribbleActionConfigs.IsGoalModeClipName(clipName: string): boolean
	return clipName == "RF02_GMode_SlowControlLoop_R15_v01"
		or clipName == "RF02_GMode_SoleRollForward_W_R15_v01"
		or clipName == "RF02_GMode_SoleRollBackward_S_R15_v01"
		or clipName == "RF02_GMode_SoleRollLeft_A_R15_v01"
		or clipName == "RF02_GMode_SoleRollRight_D_R15_v01"
end

function DribbleActionConfigs.IsStudioFallbackAllowed(): boolean
	return DribbleActionConfigs.STUDIO_FALLBACK_ENABLED and RunService:IsStudio()
end

return table.freeze(DribbleActionConfigs)

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

-- Owner-approved G hold / discrete ball-lock cuts / R15 dribble animation runtime bindings.

-- Previous section --
DribbleActionConfigs.CUT_REVERSE_ANGLE_DEG = 120
DribbleActionConfigs.CUT_MOUSE_STEER_DIAG_FRONT_DEG = 34
DribbleActionConfigs.CUT_MOUSE_STEER_DIAG_BACK_DEG = 88
DribbleActionConfigs.CUT_MAX_DURATION = 2.2
DribbleActionConfigs.CUT_FADE_SEC = 0.15
DribbleActionConfigs.SPRINT_CUT_FADE_SEC = 0.05
DribbleActionConfigs.CUT_FADE_OUT_SEC = 0.18
DribbleActionConfigs.SPRINT_CUT_FADE_OUT_SEC = 0.07
DribbleActionConfigs.CUT_COOLDOWN_SEC = 0.20
DribbleActionConfigs.REVERSE_INPUT_GRACE_SEC = 0.25

-- Base factors; marker-driven sprint cuts additionally apply DribbleCutTimeline.SpeedFactor.
DribbleActionConfigs.CUT_MOVE_SPEED_FACTOR = 1.0
DribbleActionConfigs.CUT_MOVE_SPEED_FACTOR_REVERSE = 1.0
DribbleActionConfigs.CUT_SPEED_RECOVERY_PER_SEC = 8.0
-- Server-side: ball stays on the pre-cut line during wind-up, then slides linearly along the diagonal line once the boot strikes it (TouchL/TouchR).
DribbleActionConfigs.CUT_BALL_INTENT_GRACE_SEC = 0.08
-- Legacy fallback for the unchanged GoalReverse clip; new sprint cuts require marker intent.
DribbleActionConfigs.CUT_BALL_STRIKE_PHASE = 0.36
DribbleActionConfigs.CUT_BALL_LEAD_WALK = 0.0
DribbleActionConfigs.CUT_BALL_LEAD_SPRINT = 0.90
DribbleActionConfigs.CUT_BALL_LEAD_GOAL = 0.0
DribbleActionConfigs.CUT_LINEAR_TRACK_GAIN = 9.5
DribbleActionConfigs.CUT_LINEAR_MAX_REL_SPEED = 28.0


-- Previous section --
DribbleActionConfigs.TOUCH_PULSE_BOOST_CUT = 0.35

-- Previous section --
DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_CUT = 1.50

-- Previous section --
DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_CUT = 4.0

-- Previous section --
	FrontLeft = nil :: string?,
	FrontRight = nil :: string?,
	BackLeft = nil :: string?,
	BackRight = nil :: string?,
	ReverseLeft = nil :: string?,
	ReverseRight = nil :: string?,
	GoalReverse = nil :: string?,

-- Previous section --
DribbleActionConfigs.ApprovedCutAnimations = table.freeze({
	FrontLeft = "RF02_CutDiagFrontLeft_AW_R15_v01",
	FrontRight = "RF02_CutDiagFrontRight_WD_R15_v01",
	BackLeft = "RF02_CutDiagBackLeft_AS_R15_v01",
	BackRight = "RF02_CutDiagBackRight_SD_R15_v01",
	ReverseLeft = "RF02_CutReverse_WS_R15_v01",
	ReverseRight = "RF02_CutReverse_WS_R15_v01",
	GoalReverse = "RF02_GMode_SoleDragBack_WS_R15_v01",
})


-- Previous section --
	FrontLeft = table.freeze({
		ClipName = "RF02_CutDiagFrontLeft_AW_R15_v01",
		ExpectedKeyframeCount = 61,
		ExpectedDuration = 0.7,
		DurationTolerance = 0.05,
		ExpectedLoop = false,
		ExpectedPriority = Enum.AnimationPriority.Action,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 6,
		ControlReleaseTime = 0.665,
	}) :: DribbleClipSpec,

	FrontRight = table.freeze({
		ClipName = "RF02_CutDiagFrontRight_WD_R15_v01",
		ExpectedKeyframeCount = 61,
		ExpectedDuration = 0.7,
		DurationTolerance = 0.05,
		ExpectedLoop = false,
		ExpectedPriority = Enum.AnimationPriority.Action,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 6,
		ControlReleaseTime = 0.665,
	}) :: DribbleClipSpec,

	BackLeft = table.freeze({
		ClipName = "RF02_CutDiagBackLeft_AS_R15_v01",
		ExpectedKeyframeCount = 61,
		ExpectedDuration = 0.7,
		DurationTolerance = 0.05,
		ExpectedLoop = false,
		ExpectedPriority = Enum.AnimationPriority.Action,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 6,
		ControlReleaseTime = 0.665,
	}) :: DribbleClipSpec,

	BackRight = table.freeze({
		ClipName = "RF02_CutDiagBackRight_SD_R15_v01",
		ExpectedKeyframeCount = 61,
		ExpectedDuration = 0.7,
		DurationTolerance = 0.05,
		ExpectedLoop = false,
		ExpectedPriority = Enum.AnimationPriority.Action,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 6,
		ControlReleaseTime = 0.665,
	}) :: DribbleClipSpec,

	ReverseLeft = table.freeze({
		ClipName = "RF02_CutReverse_WS_R15_v01",
		ExpectedKeyframeCount = 61,
		ExpectedDuration = 0.7,
		DurationTolerance = 0.05,
		ExpectedLoop = false,
		ExpectedPriority = Enum.AnimationPriority.Action,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 6,
		ControlReleaseTime = 0.665,
	}) :: DribbleClipSpec,

	ReverseRight = table.freeze({
		ClipName = "RF02_CutReverse_WS_R15_v01",
		ExpectedKeyframeCount = 61,
		ExpectedDuration = 0.7,
		DurationTolerance = 0.05,
		ExpectedLoop = false,
		ExpectedPriority = Enum.AnimationPriority.Action,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 6,
		ControlReleaseTime = 0.665,
	}) :: DribbleClipSpec,

	GoalReverse = table.freeze({
		ClipName = "RF02_GMode_SoleDragBack_WS_R15_v01",
		ExpectedKeyframeCount = 149,
		ExpectedDuration = 0.74,
		DurationTolerance = 0.05,
		ExpectedLoop = false,
		ExpectedPriority = Enum.AnimationPriority.Action,
		ExpectedDrivenJoints = 15,
		ExpectedMarkerCount = 5,
		ControlReleaseTime = 0.62,
	}) :: DribbleClipSpec,


-- Previous section --
	RF02_CutDiagFrontLeft_AW_R15_v01 = true,
	RF02_CutDiagFrontRight_WD_R15_v01 = true,
	RF02_CutDiagBackLeft_AS_R15_v01 = true,
	RF02_CutDiagBackRight_SD_R15_v01 = true,
	RF02_CutReverse_WS_R15_v01 = true,

-- Previous section --
	RF02_GMode_SoleDragBack_WS_R15_v01 = true,

-- Previous section --
		or clipName == "RF02_GMode_SoleDragBack_WS_R15_v01"
]====]

]========]
