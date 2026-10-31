--!strict
-- Shared sampling keeps server contact geometry and authored client poses on the same clip.
local Reference = require(script.Parent.FootballClipReferenceData)
local Support = require(script.Parent.R15PoseSupport)
local Animation = {}
local Parts = {"LowerTorso","UpperTorso","Head","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}
local Parents = {0,1,2,2,4,5,2,7,8,1,10,11,1,13,14}

local function frame(key)
	local p,r = key[3] or {0,0,0},key[2]
	return CFrame.new(p[1],p[2],p[3])*CFrame.Angles(math.rad(r[1]),math.rad(r[2]),math.rad(r[3]))
end

function Animation.Sample(key: string, time: number): {[string]: CFrame}
	local pose = {}
	for _, track in Reference[key].recipe.tracks do
		local keys = track.keys
		local i = 1
		while i<#keys-1 and keys[i+1][1]<time do i+=1 end
		local a,b=keys[i],keys[math.min(i+1,#keys)]
		local alpha=if b[1]>a[1] then math.clamp((time-a[1])/(b[1]-a[1]),0,1) else 0
		-- CubicV2 / InOut is the selected assets' segment easing.
		alpha=if alpha<0.5 then 4*alpha^3 else 1-(-2*alpha+2)^3/2
		pose[track.joint]=frame(a):Lerp(frame(b),alpha)
	end
	return pose
end

function Animation.FootFrame(root: CFrame, key: string, time: number, side: string): CFrame
	local pose={}
	for name,cf in Animation.Sample(key,time) do
		local x,y,z=cf:ToEulerAnglesXYZ()
		pose[name]={p=cf.Position,r=Vector3.new(math.deg(x),math.deg(y),math.deg(z))}
	end
	return Support.FootFrame(root,pose,side)
end

function Animation.Build(key: string, options: any?): KeyframeSequence
	local recipe=Reference[key].recipe
	local opt=options or {}
	local first,last=opt.start or 0,opt.finish or recipe.duration
	local speed=opt.rate or 1
	local sequence=Instance.new("KeyframeSequence")
	sequence.Name=opt.name or recipe.name
	sequence.Loop=if opt.loop~=nil then opt.loop else recipe.loop
	sequence.Priority=opt.priority or Enum.AnimationPriority.Movement
	local times={first,last}
	for _,track in recipe.tracks do
		for _,sample in track.keys do if sample[1]>first and sample[1]<last then table.insert(times,sample[1]) end end
	end
	table.sort(times)
	local previous=-math.huge
	for _,time in times do
		if math.abs(time-previous)<1e-5 then continue end
		previous=time
		local kf=Instance.new("Keyframe");kf.Time=(time-first)/speed
		local root=Instance.new("Pose");root.Name="HumanoidRootPart";root.Parent=kf
		local transforms=Animation.Sample(key,time);local poses={}
		for i,name in Parts do
			local p=Instance.new("Pose");p.Name=name;p.CFrame=transforms[name] or CFrame.identity
			p.EasingStyle=Enum.PoseEasingStyle.CubicV2;p.EasingDirection=Enum.PoseEasingDirection.InOut
			if opt.movingCharge then p.Weight=if name=="LowerTorso" or name:sub(1,4)=="Left" and name:find("Leg") or name=="LeftFoot" then 0 else 0.8 end
			p.Parent=if Parents[i]==0 then root else poses[Parents[i]];poses[i]=p
		end
		for _,m in opt.markers or {} do
			if math.abs(kf.Time-m.time)<0.018 then local marker=Instance.new("KeyframeMarker");marker.Name=m.name;marker.Parent=kf end
		end
		kf.Parent=sequence
	end
	return sequence
end

return table.freeze(Animation)
