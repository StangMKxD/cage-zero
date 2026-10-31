--!strict
-- Source times are taken from the Owner-selected clips: backswing -> forward foot strike.
return table.freeze({
	Shot = table.freeze({Key="Shot", HoldAt=0.30, ContactSource=0.433, ContactEndSource=0.48,
		EndSource=1.30, Rate=1.4, MinSpeed=60, MaxSpeed=142, MaxChargeSec=1.2}),
	Pass = table.freeze({Key="Pass", HoldAt=0.367, ContactSource=0.50, ContactEndSource=0.55,
		EndSource=1.60, Rate=1.4, MinSpeed=46, MaxSpeed=90, MaxChargeSec=0.55, GroundFriction=0.45}),
	CurveSpeedScale=0.78,
	CurveAngularSpeedDegrees=50,
	ChargeEntrySec=0.20,
	-- Removed by Owner: ReleaseWaitSec=1, reverse-turn/mouse-trigger action.
})
