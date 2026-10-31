--!strict
local Config=require(script.Parent.configs.FootballActionConfigs)
local Hitbox=require(script.Parent.KickHitbox)
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
function Rules.MaxChargeSec(kind: string): number
	return Config[kind].MaxChargeSec
end
function Rules.Velocity(kind: string, aim: Vector3, charge: number, curve: number?): Vector3
	local c=Config[kind];local power=math.clamp(charge/c.MaxChargeSec,0,1)
	local speed=c.MinSpeed+(c.MaxSpeed-c.MinSpeed)*power
	if kind=="Shot" and curve and curve~=0 then speed*=Config.CurveSpeedScale end
	-- Preserve the complete aim vector: downward passes bounce via the normal floor solver.
	return aim*speed
end
function Rules.CurveVelocity(velocity: Vector3, direction: number, dt: number): Vector3
	local radians=-direction*math.rad(Config.CurveAngularSpeedDegrees)*math.clamp(dt,0,0.1)
	return CFrame.Angles(0,radians,0):VectorToWorldSpace(velocity)
end
function Rules.Contact(root: CFrame, ball: Vector3, isCarrier: boolean, maxCarrierDistance: number)
	if not isCarrier then return Hitbox.Evaluate(root,ball) end
	-- Possession uses the normal server distance safeguard, never the free-ball volume.
	local distance=(root.Position-ball).Magnitude
	if distance~=distance or distance>maxCarrierDistance then return nil end
	return {point=ball,localPoint=root:PointToObjectSpace(ball),quality=1,powerScale=1,deflectionDegrees=0}
end
return table.freeze(Rules)
