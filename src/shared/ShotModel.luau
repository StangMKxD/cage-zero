--!strict
local Animation=require(script.Parent.FootballAnimation)
local Rules=require(script.Parent.FootballActionRules)
local Model={}
function Model.FootFrame(root: CFrame, time: number, side: string, kind: string?): CFrame
 return Animation.FootFrame(root,kind or "Shot",time,side)
end
return table.freeze(Model)

--[========[
Previous implementation retained at Owner request.
--!strict
-- The reference's horizontal travel belongs to locomotion; retain every joint rotation.
local Reference = require(script.Parent.ShotReferenceData)
type JointSample = {p: Vector3?, r: Vector3}
type JointSample = {p: Vector3?, r: Vector3}
type JointSample = {p: Vector3?, r: Vector3}
type PoseMap = {[string]: JointSample}
local Model = {}
local Support = require(script.Parent.R15PoseSupport)
function Model.PoseAt(time: number): PoseMap
 local frames = Reference.Frames
 local i = math.clamp(math.floor(time * 30) + 1, 1, #frames - 1)
 while i > 1 and frames[i].time > time do i -= 1 end
 while i < #frames - 1 and frames[i+1].time < time do i += 1 end
 local a,b = frames[i],frames[i+1]
 local alpha = math.clamp((time-a.time)/(b.time-a.time),0,1)
 local pose: PoseMap = {}
 for j,name in Reference.Parts do
  local rotation = a.rotations[j]:Lerp(b.rotations[j],alpha)
  local x,y,z = rotation:ToEulerAnglesXYZ()
  pose[name] = {r=Vector3.new(math.deg(x),math.deg(y),math.deg(z))}
 end
 pose.LowerTorso.p = Vector3.new(0,a.travel.Y+(b.travel.Y-a.travel.Y)*alpha,0)
 return Support.Ground(pose)
end
-- Server uses authored FK, never client-replicated animated limb positions.
function Model.FootFrame(root: CFrame, time: number, side: string): CFrame
 return Support.FootFrame(root,Model.PoseAt(time),side)
end
return table.freeze(Model)

]========]
