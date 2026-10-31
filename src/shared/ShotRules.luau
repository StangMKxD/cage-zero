--!strict
local Config = require(script.Parent.configs.ShotConfigs)
local Rules = {}

function Rules.IsFinite(n: any): boolean
	return typeof(n) == "number" and n == n and math.abs(n) < math.huge
end

function Rules.IsActionId(id: any): boolean
	return Rules.IsFinite(id) and id >= 1 and id <= 2147483647 and id % 1 == 0
end

function Rules.Aim(value: any): Vector3?
	if typeof(value) ~= "Vector3" or not Rules.IsFinite(value.X)
		or not Rules.IsFinite(value.Y) or not Rules.IsFinite(value.Z) then return nil end
	local magnitude = value.Magnitude
	if magnitude < 0.5 or magnitude > 1.5 then return nil end
	local unit = value / magnitude
	-- Ground kick permits low shots and deliberate loft; no backward vertical singularity.
	if unit.Y < -0.95 or unit.Y > 0.8 then return nil end
	return unit
end

function Rules.Velocity(aim: Vector3, charge: number): Vector3
	local power = math.clamp(charge / Config.MaxChargeSec, 0, 1)
	return aim * (Config.MinSpeed + (Config.MaxSpeed - Config.MinSpeed) * power)
end

function Rules.Touches(foot: CFrame, ball: Vector3, radius: number): boolean
	local p = foot:PointToObjectSpace(ball)
	local half = Config.FootHalfSize
	local gap = Vector3.new(math.max(0, math.abs(p.X) - half.X),
		math.max(0, math.abs(p.Y) - half.Y), math.max(0, math.abs(p.Z) - half.Z))
	return gap.Magnitude <= radius + Config.ContactTolerance
end

return table.freeze(Rules)
