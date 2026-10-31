--!strict
-- Pure direction rules, shared by server validation and local input; no side effects.
local Rules = {}

function Rules.IsFiniteVector(v: any): boolean
	return typeof(v) == "Vector3"
		and v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < math.huge and math.abs(v.Y) < math.huge and math.abs(v.Z) < math.huge
end

function Rules.AttackGoal(teamSide: string, halfLength: number, backZone: number): Vector3?
	if teamSide ~= "North" and teamSide ~= "South" then return nil end
	-- TeamSide is its own goal, not the goal it attacks.
	return Vector3.new(0, 0, (if teamSide == "North" then 1 else -1) * (halfLength - backZone))
end

function Rules.HorizontalDirection(v: Vector3): Vector3
	if not Rules.IsFiniteVector(v) then return Vector3.zero end
	local h = Vector3.new(v.X, 0, v.Z)
	return if h.Magnitude > 1e-4 then h.Unit else Vector3.zero
end

function Rules.GoalMovement(localInput: Vector3, goalDirection: Vector3): Vector3
	local forward = Rules.HorizontalDirection(goalDirection)
	if forward.Magnitude == 0 or localInput.Magnitude == 0 then return Vector3.zero end
	local right = forward:Cross(Vector3.yAxis)
	return Rules.HorizontalDirection(right * localInput.X - forward * localInput.Z)
end

return table.freeze(Rules)

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

function Rules.CutForTransition(previousChord: string, chord: string, previousInput: Vector3, input: Vector3, reverseAngle: number): string?
	if chord == previousChord or previousInput.Magnitude < 0.001 or input.Magnitude < 0.001 then return nil end
	local prev = Rules.HorizontalDirection(previousInput)
	local nextDir = Rules.HorizontalDirection(input)
	local angle = math.deg(math.acos(math.clamp(prev:Dot(nextDir), -1, 1)))
	if angle >= reverseAngle then
		return if prev:Cross(nextDir).Y < 0 then "ReverseRight" else "ReverseLeft"
	end
	if #chord == 2 then
		if input.Z < 0 then return if input.X < 0 then "FrontLeft" else "FrontRight" end
		return if input.X < 0 then "BackLeft" else "BackRight"
	end
	return nil
end

]====]
