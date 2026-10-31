--!strict
-- Public contract checks; execute the returned function with DribbleCutTimeline.
return function(Timeline: any)
	local checks = 0
	local function check(value: boolean, message: string)
		checks += 1
		assert(value, message)
	end
	check(Timeline.Duration == 0.7 and Timeline.SourceDuration == 2, "Compress the source into the approved 0.7s commitment")
	check(Timeline.Get("unknown") == nil, "Unknown cut rejected")
	check(Timeline.HasSprintContext(true, nil, 1), "Server-confirmed sprint")
	check(not Timeline.HasSprintContext(false, nil, 1), "No fabricated sprint history")
	check(Timeline.HasSprintContext(false, 1, 1.1), "Brief key-transition gap allowed")
	check(not Timeline.HasSprintContext(false, 1, 1.121), "Sprint grace expires")
	check(not Timeline.HasSprintContext(false, 1, 0.9), "Future sprint timestamp rejected")
	for _, cut in ipairs({ "FrontLeft", "FrontRight", "BackLeft", "BackRight", "ReverseLeft", "ReverseRight" }) do
		local p = Timeline.Get(cut)
		check(p ~= nil, "Known cut profile")
		for _, phase in ipairs({ "Trap", "Strike", "Release" }) do
			local time = if phase == "Trap" then Timeline.TrapAt elseif phase == "Strike" then Timeline.StrikeAt else Timeline.ReleaseAt
			local foot = if phase == "Trap" then p.TrapFoot else p.StrikeFoot
			check(Timeline.ValidateMarker(p, phase, foot, time), "Authored marker accepted")
			check(not Timeline.ValidateMarker(p, phase, if foot == "L" then "R" else "L", time), "Wrong foot rejected")
			check(not Timeline.ValidateMarker(p, phase, foot, time - Timeline.EarlyTolerance - 0.001), "Premature marker rejected")
			check(not Timeline.ValidateMarker(p, phase, foot, time + Timeline.LateTolerance + 0.001), "Stale marker rejected")
			check(not Timeline.ValidateMarker(p, phase, foot, 0 / 0), "NaN rejected")
			check(not Timeline.ValidateMarker(p, phase, foot, math.huge), "Infinity rejected")
		end
	end
	local previous = 0
	for i = 0, 120 do
		local time = i / 60
		local alpha = Timeline.DirectionAlpha(time)
		local speed = Timeline.SpeedFactor(time)
		check(alpha >= previous and alpha <= 1, "Direction progresses monotonically")
		check(speed >= 0.45 and speed <= 1, "Cut slowdown bounded")
		previous = alpha
	end
	check(Timeline.DirectionAlpha(Timeline.StrikeAt-0.001) == 0, "No timed turn before strike")
	check(Timeline.SpeedFactor((Timeline.TrapAt+Timeline.StrikeAt)/2) == 0.45, "Plant has a real speed dip")
	check(Timeline.SpeedFactor(Timeline.ReleaseAt) == 1, "Speed restored at release")
	return { checks = checks, status = "PASS" }
end

