--!strict
-- Initial visual tuning for continuous steering; no animation completion gate.
return table.freeze({
	ResponseSec = 0.045,
	FacingRateRadPerSec = 20,
	LeanResponse = 22,
	MaxRollDeg = 9,
	MaxPitchDeg = 3,
	FullLeanAngleDeg = 45,
	FullLeanRateRadPerSec = 8,
})
