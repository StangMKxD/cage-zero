--!strict
-- Analytic volume test against the authoritative custom ball solver position.
-- Debug parts never decide contact and no client contact/quality values are trusted.
local Config=require(script.Parent.configs.KickHitboxConfigs)
local Rules={}
export type Contact={point: Vector3, localPoint: Vector3, quality: number, powerScale: number, deflectionDegrees: number}
local function finite(v: Vector3): boolean
	return v.X==v.X and v.Y==v.Y and v.Z==v.Z
		and math.abs(v.X)<math.huge and math.abs(v.Y)<math.huge and math.abs(v.Z)<math.huge
end
function Rules.Heading(root: CFrame, aim: Vector3?): CFrame
	local look=if aim and finite(aim) then aim else root.LookVector
	local flat=Vector3.new(look.X,0,look.Z)
	if flat.Magnitude<0.001 then flat=Vector3.new(0,0,-1) end
	return CFrame.lookAt(root.Position,root.Position+flat.Unit)
end
function Rules.Frame(root: CFrame, aim: Vector3?): CFrame
	return Rules.Heading(root,aim)*CFrame.new(Config.Center)
end
function Rules.Evaluate(root: CFrame, ball: Vector3, aim: Vector3?): Contact?
	if not finite(ball) then return nil end
	local heading=Rules.Heading(root,aim)
	local localPoint=heading:PointToObjectSpace(ball)
	if localPoint.Z>-Config.MinimumForward then return nil end
	local offset=localPoint-Config.Center;local half=Config.Size/2
	if math.abs(offset.X)>half.X+1e-5 or math.abs(offset.Y)>half.Y+1e-5 or math.abs(offset.Z)>half.Z+1e-5 then return nil end
	local lateral=math.abs(offset.X)/half.X
	local depth=math.abs(offset.Z)/half.Z
	local angle=math.deg(math.atan2(math.abs(offset.X),-localPoint.Z))
	local errorScore=math.clamp(0.65*math.max(lateral,depth)+0.35*angle/Config.AngleReferenceDegrees,0,1)
	-- CFrame roundoff must not turn an exactly centered strike into a mishit.
	if errorScore<1e-5 then errorScore=0 end
	local quality=1-errorScore
	return {point=ball,localPoint=localPoint,quality=quality,
		powerScale=1-(1-Config.MinimumPowerScale)*errorScore,
		deflectionDegrees=math.sign(offset.X)*Config.MaxDeflectionDegrees*errorScore}
end
function Rules.ApplyMishit(velocity: Vector3, contact: Contact): Vector3
	return CFrame.Angles(0,-math.rad(contact.deflectionDegrees),0):VectorToWorldSpace(velocity)*contact.powerScale
end
return table.freeze(Rules)
