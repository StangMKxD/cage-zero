--!strict
-- Dedicated balanced backswing. The shot reference supplies arm shape and key timing;
-- release/contact animation and server foot-contact model remain separate.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.configs.ShotConfigs)
local Reference = require(Shared.ShotReferenceData)
local ShotModel = require(Shared.ShotModel)
local Support = require(Shared.R15PoseSupport)
local Charge = {}
type Sample = {p: Vector3?, r: Vector3}
type PoseMap = {[string]: Sample}
local parents = {0,1,2,2,4,5,2,7,8,1,10,11,1,13,14}

function Charge.PoseAt(time: number): PoseMap
	local pose = ShotModel.PoseAt(0.08)
	local u = math.clamp(time / Config.ChargeHoldAt, 0, 1)
	local a = u*u*u*(10 + u*(-15 + 6*u))
	pose.LowerTorso = {p = Vector3.zero, r = Vector3.new(-2,-3,0)}
	pose.UpperTorso = {r = Vector3.new(-3-a, 5+3*a, 0)}
	pose.Head = {r = Vector3.new(5+a,-2-3*a,0)}
	pose.LeftUpperLeg = {r = Vector3.new(7,0,-3)}
	pose.LeftLowerLeg = {r = Vector3.new(-12,0,0)}
	pose.LeftFoot = {r = Vector3.new(7,0,0)}
	pose.RightUpperLeg = {r = Vector3.new(4-26*a,5*a,3*a)}
	pose.RightLowerLeg = {r = Vector3.new(-8-74*a,0,0)}
	pose.RightFoot = {r = Vector3.new(4+20*a,0,0)}
	for _, side in {"Left", "Right"} do
		local arm = pose[side.."UpperArm"].r
		local elbow = pose[side.."LowerArm"].r
		pose[side.."UpperArm"] = {r = Vector3.new(math.clamp(arm.X,-15,18),
			math.clamp(arm.Y,-12,12), if side=="Left" then -22 else 24)}
		pose[side.."LowerArm"] = {r = Vector3.new(math.clamp(elbow.X,35,55),
			math.clamp(elbow.Y,-8,8),math.clamp(elbow.Z,-6,6))}
		pose[side.."Hand"] = {r = Vector3.zero}
	end
	return Support.Ground(pose)
end

function Charge.Build(moving: boolean): KeyframeSequence
	local sequence = Instance.new("KeyframeSequence")
	sequence.Name = if moving then Config.MovingChargeClipName else Config.ChargeClipName
	sequence.Priority = Enum.AnimationPriority.Action2
	sequence.Loop = false
	local times = {}
	for _, sourceTime in Reference.Times do
		local t = sourceTime / Config.PlaybackRate
		if t < Config.ChargeHoldAt then table.insert(times,t) end
	end
	table.insert(times,Config.ChargeHoldAt)
	table.insert(times,0.6) -- Hold before the clip end; do not freeze an arbitrary shot frame.
	for _, t in times do
		local frame = Instance.new("Keyframe");frame.Time=t
		local root = Instance.new("Pose");root.Name="HumanoidRootPart";root.Weight=0;root.Parent=frame
		local pose = Charge.PoseAt(t)
		local built: {Pose} = {}
		for i, name in Reference.Parts do
			local sample = pose[name]
			local p = Instance.new("Pose");p.Name=name
			p.CFrame = CFrame.new(sample.p or Vector3.zero)
				* CFrame.Angles(math.rad(sample.r.X),math.rad(sample.r.Y),math.rad(sample.r.Z))
			p.Weight = if moving and (name=="LowerTorso" or name:find("Left.*Leg") or name=="LeftFoot") then 0
				elseif moving and (name:find("Right.*Leg") or name=="RightFoot") then 0.8 else 1
			p.EasingStyle=Enum.PoseEasingStyle.Cubic;p.EasingDirection=Enum.PoseEasingDirection.InOut
			p.Parent=if parents[i]==0 then root else built[parents[i]]
			built[i]=p
		end
		frame.Parent=sequence
	end
	return sequence
end

return table.freeze(Charge)
