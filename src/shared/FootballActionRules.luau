--!strict
local Config=require(script.Parent.configs.FootballActionConfigs)
local Rules={}
function Rules.Kind(value: any): string?
	return if value=="Shot" or value=="Pass" then value else nil
end
function Rules.Duration(kind: string): number
	local c=Config[kind];return (c.EndSource-c.HoldAt)/c.Rate
end
function Rules.ContactAt(kind: string): number
	local c=Config[kind];return (c.ContactSource-c.HoldAt)/c.Rate
end
function Rules.ContactEnd(kind: string): number
	local c=Config[kind];return (c.ContactEndSource-c.HoldAt)/c.Rate
end
function Rules.SourceTime(kind: string, elapsed: number): number
	local c=Config[kind];return math.min(c.EndSource,c.HoldAt+math.max(0,elapsed)*c.Rate)
end
function Rules.Velocity(kind: string, aim: Vector3, charge: number): Vector3
	local c=Config[kind];local power=math.clamp(charge/1.2,0,1)
	if kind=="Pass" then
		local horizontal=Vector3.new(aim.X,0,aim.Z)
		if horizontal.Magnitude<0.01 then return Vector3.zero end
		return horizontal.Unit*(c.MinSpeed+(c.MaxSpeed-c.MinSpeed)*power)+Vector3.new(0,2,0)
	end
	return aim*(c.MinSpeed+(c.MaxSpeed-c.MinSpeed)*power)
end
return table.freeze(Rules)
