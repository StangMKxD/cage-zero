--!strict
return table.freeze({
	-- Ball-center eligibility volume in the player's horizontal local frame (studs).
	-- Owner tuning: compact reach centered on the dominant right foot.
	Center = Vector3.new(0.75,-2.7,-2.5),
	Size = Vector3.new(3.4,2.8,3.4),
	PreferredFoot = "Right",
	MinimumForward = 0.2,
	MinimumPowerScale = 0.45,
	MaxDeflectionDegrees = 18,
	AngleReferenceDegrees = 65,
	DebugVisible = true,
})
