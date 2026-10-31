--!strict
local Actions = require(script.Parent.FootballActionConfigs)
local Shot = Actions.Shot
return table.freeze({
	ClipName = "RF02_StrikeFowardJogMixamo_R15_v02",
	ChargeClipName = "RF02_StrikeFowardJog_Charge_R15_v02",
	MovingChargeClipName = "RF02_StrikeFowardJog_ChargeMoving_R15_v02",
	ChargeHoldAt = 0.20,
	ChargeFadeSec = 0.12,
	AnimationId = "", -- Studio registers the authored sequence; publishing is a separate Owner step.
	PlaybackRate = Shot.Rate,
	SourceEnd = Shot.EndSource,
	Duration = (Shot.EndSource-Shot.HoldAt)/Shot.Rate,
	ContactAt = (Shot.ContactSource-Shot.HoldAt)/Shot.Rate,
	ContactEnd = (Shot.ContactEndSource-Shot.HoldAt)/Shot.Rate,
	BlendOutAt = (Shot.EndSource-Shot.HoldAt)/Shot.Rate-0.08,
	MaxChargeSec = 1.2,
	ChargeTimeoutSec = 5,
	CooldownSec = 0.7,
	MinSpeed = 54,
	MaxSpeed = 128,
	CurveAcceleration = 24,
	CurveDurationSec = 0.8,
	RecaptureDelaySec = 0.6,
	ContactTolerance = 0.15,
	FootHalfSize = Vector3.new(0.418089032, 0.436725199, 0.621226967),
	BallSetupTrackGain = 9.5,
	BallSetupMaxRelativeSpeed = 28.0,
	BallSetupOffset = Vector3.new(0.7, 0, -1.7),
})

--[========[
Previous implementation retained at Owner request.
--!strict
return table.freeze({
	ClipName = "RF02_Shot_R15_v01",
	ChargeClipName = "RF02_ShotChargeBackswing_R15_v02",
	MovingChargeClipName = "RF02_ShotChargeBackswingMoving_R15_v02",
	ChargeHoldAt = 0.22,
	ChargeFadeSec = 0.12,
	AnimationId = "", -- Studio registers the authored sequence; publishing is a separate Owner step.
	PlaybackRate = 1.25,
	SourceEnd = 0.7,
	Duration = 0.56,
	ContactAt = 0.24,
	ContactEnd = 0.29336,
	BlendOutAt = 0.48,
	MaxChargeSec = 1.2,
	ChargeTimeoutSec = 5,
	CooldownSec = 0.7,
	MinSpeed = 54,
	MaxSpeed = 128,
	CurveAcceleration = 24,
	CurveDurationSec = 0.8,
	RecaptureDelaySec = 0.6,
	ContactTolerance = 0.15,
	FootHalfSize = Vector3.new(0.418089032, 0.436725199, 0.621226967),
	BallSetupTrackGain = 9.5,
	BallSetupMaxRelativeSpeed = 28.0,
	BallSetupOffset = Vector3.new(1.3, 0, -2.05),
})

]========]
