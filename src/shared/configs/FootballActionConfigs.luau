--!strict
-- Source times are taken from the Owner-selected clips: backswing -> forward foot strike.
return table.freeze({
	Shot = table.freeze({Key="Shot", HoldAt=0.30, ContactSource=0.433, ContactEndSource=0.48,
		EndSource=1.30, Rate=1.4, MinSpeed=54, MaxSpeed=128}),
	Pass = table.freeze({Key="Pass", HoldAt=0.367, ContactSource=0.50, ContactEndSource=0.55,
		EndSource=1.60, Rate=1.4, MinSpeed=30, MaxSpeed=76}),
	ChargeEntrySec=0.20,
	ReleaseWaitSec=1.0,
	TurnAngleDeg=179.9,
	MouseTurnAngleDeg=110,
	MouseTurnWindowSec=0.25,
	TurnDurationSec=0.70,
})
