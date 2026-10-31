-- Retired by Owner: retained as comments, no runtime implementation.
--[====[
--!strict
-- Shared authored times for sprint-cut.md (61 source frames / 2 seconds).
-- Marker callbacks advance gameplay; these times validate/order intent, never fabricate a strike.
local Timeline = {}
Timeline.SourceDuration = 2.0
Timeline.Duration = 0.7
Timeline.TimeScale = Timeline.Duration / Timeline.SourceDuration
Timeline.TrapAt = 0.1333 * Timeline.TimeScale
Timeline.StrikeAt = 0.2667 * Timeline.TimeScale
Timeline.ReleaseAt = 1.9 * Timeline.TimeScale
Timeline.BlendOutAt = 1.8 * Timeline.TimeScale
Timeline.TrapDistance = 2.55
Timeline.PushLead = 0.45
Timeline.EarlyTolerance = 0.025
Timeline.LateTolerance = 0.18
Timeline.SprintGraceSec = 0.12

export type Profile = { TrapFoot: string, StrikeFoot: string }
local left = table.freeze({ TrapFoot = "L", StrikeFoot = "L" })
local right = table.freeze({ TrapFoot = "R", StrikeFoot = "R" })
local profiles: { [string]: Profile } = {
	FrontLeft = left, FrontRight = right, BackLeft = left, BackRight = right,
	-- Existing reversal bindings share one left-pivot clip.
	ReverseLeft = left, ReverseRight = left,
}

function Timeline.Get(cut: string): Profile?
	return profiles[cut]
end

function Timeline.HasSprintContext(active: boolean, lastSprintAt: number?, now: number): boolean
	return active or (lastSprintAt ~= nil and now >= lastSprintAt and now - lastSprintAt <= Timeline.SprintGraceSec)
end

function Timeline.ValidateMarker(profile: Profile, phase: any, foot: any, elapsed: number): boolean
	if elapsed ~= elapsed or math.abs(elapsed) == math.huge then return false end
	local time: number
	local expectedFoot: string
	if phase == "Trap" then
		time, expectedFoot = Timeline.TrapAt, profile.TrapFoot
	elseif phase == "Strike" then
		time, expectedFoot = Timeline.StrikeAt, profile.StrikeFoot
	elseif phase == "Release" then
		time, expectedFoot = Timeline.ReleaseAt, profile.StrikeFoot
	else
		return false
	end
	return foot == expectedFoot and elapsed >= time - Timeline.EarlyTolerance and elapsed <= time + Timeline.LateTolerance
end

function Timeline.DirectionAlpha(time: number): number
	local t = math.clamp((time - Timeline.StrikeAt) / (Timeline.ReleaseAt - Timeline.StrikeAt), 0, 1)
	return t * t * (3 - 2 * t)
end

function Timeline.SpeedFactor(time: number): number
	if time < Timeline.TrapAt then
		local t = math.clamp(time / Timeline.TrapAt, 0, 1)
		return 1 - 0.55 * t * t * (3 - 2 * t)
	elseif time < Timeline.StrikeAt then
		return 0.45
	end
	return 0.45 + 0.55 * Timeline.DirectionAlpha(time)
end

return table.freeze(Timeline)

]====]
