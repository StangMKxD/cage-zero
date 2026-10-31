--!strict
-- Source landmarks from jump.md; independent of character movement/physics ownership.
local Timing = {
	PushOff = 0.9,
	Apex = 1.2667,
	DescentHold = 1.4667,
	LandingStart = 1.5,
	LandingEnd = 3,
	LandingMoveBlendAfter = 0.18,
}

function Timing.Sample(verticalSpeed: number, launchSpeed: number, passiveFall: boolean): (number, string)
	if passiveFall then return Timing.DescentHold, "Fall" end
	if math.abs(verticalSpeed)<=6 then return Timing.Apex, "Apex" end
	if verticalSpeed > 0 then
		local progress = 1-math.clamp(verticalSpeed/math.max(1,launchSpeed),0,1)
		return Timing.PushOff+(Timing.Apex-Timing.PushOff)*progress,
			if verticalSpeed <= 6 then "Apex" else "Rise"
	end
	local progress = math.clamp(-verticalSpeed/45,0,1)
	return Timing.Apex+(Timing.DescentHold-Timing.Apex)*progress,
		if verticalSpeed >= -6 then "Apex" else "Descent"
end

return table.freeze(Timing)
