--!strict
-- Two non-looped clips from the Owner reference: flight and actual touchdown/recovery.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Timing = require(Shared.JumpAnimationTiming)
local Support = require(Shared.R15PoseSupport)
local Reference = require(script.Parent.JumpReferenceData)
local PARENTS = {0,1,2,2,4,5,2,7,8,1,10,11,1,13,14}
local Data = {}

function Data.PoseAt(time: number, grounded: boolean)
	local frames = Reference.Frames
	local i = math.clamp(math.floor(time*30)+1,1,#frames-1)
	while i>1 and frames[i].time>time do i-=1 end
	while i<#frames-1 and frames[i+1].time<time do i+=1 end
	local a,b = frames[i],frames[i+1]
	local alpha = math.clamp((time-a.time)/(b.time-a.time),0,1)
	local pose = {}
	for j,name in Reference.Parts do
		local x,y,z = a.rotations[j]:Lerp(b.rotations[j],alpha):ToEulerAnglesXYZ()
		-- Owner refinement: hands stay near the waist rather than reaching overhead.
		if name=="LeftUpperArm" or name=="RightUpperArm" then
			x=math.clamp(x,-math.rad(8),math.rad(8))
			y=math.clamp(y,-math.rad(10),math.rad(10))
			z=if name=="LeftUpperArm" then -math.rad(12) else math.rad(12)
		elseif name=="LeftLowerArm" or name=="RightLowerArm" then
			x=math.clamp(x,math.rad(25),math.rad(40))
			y=math.clamp(y,-math.rad(8),math.rad(8))
			z=math.clamp(z,-math.rad(8),math.rad(8))
		end
		pose[name] = {r=Vector3.new(math.deg(x),math.deg(y),math.deg(z))}
	end
	-- Real Humanoid flight owns root height/travel; landing support only changes the pose.
	pose.LowerTorso.p = Vector3.zero
	return if grounded then Support.Ground(pose) else pose
end

function Data.Build(key: string): KeyframeSequence?
	if key~="Jump" and key~="Land" then return nil end
	local landing = key=="Land"
	local start = if landing then Timing.LandingStart else 0
	local finish = if landing then Timing.LandingEnd else Timing.LandingStart
	local seq = Instance.new("KeyframeSequence")
	seq.Name = if landing then "RF02_Land_Ready_R15_v01" else "RF02_Jump_Ready_R15_v01"
	seq.Priority = Enum.AnimationPriority.Action
	seq.Loop = false
	for _,sample in Reference.Frames do
		if sample.time<start or sample.time>finish then continue end
		local kf = Instance.new("Keyframe")
		kf.Time = sample.time-start
		local root = Instance.new("Pose")
		root.Name = "HumanoidRootPart"
		root.Weight = 0
		root.Parent = kf
		local pose = Data.PoseAt(sample.time,landing)
		local nodes = {}
		for i,name in Reference.Parts do
			local p = Instance.new("Pose")
			p.Name = name
			p.Weight = 1
			p.EasingStyle = Enum.PoseEasingStyle.Linear
			local s = pose[name]
			p.CFrame = CFrame.new(s.p or Vector3.zero)*CFrame.Angles(math.rad(s.r.X),math.rad(s.r.Y),math.rad(s.r.Z))
			p.Parent = if PARENTS[i]==0 then root else nodes[PARENTS[i]]
			nodes[i] = p
		end
		local markerName = if landing and sample.time==start then "Touchdown"
			elseif not landing and sample.time==Timing.Apex then "Apex" else nil
		if markerName then
			local marker = Instance.new("KeyframeMarker")
			marker.Name = markerName
			marker.Parent = kf
		end
		kf.Parent = seq
	end
	return seq
end

return table.freeze(Data)
