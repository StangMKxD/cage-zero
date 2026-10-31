--!strict
return function(Shared)
	local A=require(Shared.FootballAnimation)
	local R=require(Shared.FootballActionRules)
	local C=require(Shared.configs.FootballActionConfigs)
	local Sprint=require(Shared.SprintSpeedRules)
	local Reference=require(Shared.FootballClipReferenceData)
	local count=0
	local function check(ok,label) assert(ok,label);count+=1 end
	check(R.Kind("Pass")=="Pass" and R.Kind("Other")==nil,"action whitelist")
	for _,kind in {"Shot","Pass"} do
		check(R.ContactAt(kind)>0 and R.ContactEnd(kind)>R.ContactAt(kind) and R.Duration(kind)>R.ContactEnd(kind),"ordered contact window")
		check(math.abs(R.SourceTime(kind,R.ContactAt(kind))-C[kind].ContactSource)<1e-6,"same server/client source clock")
		local seq=A.Build(kind,{start=C[kind].HoldAt,rate=C[kind].Rate,loop=false,priority=Enum.AnimationPriority.Action2})
		local frames=seq:GetKeyframes()
		check(not seq.Loop and math.abs(frames[#frames].Time-R.Duration(kind))<1e-5,"release range")
		seq:Destroy()
	end
	local passAim=Vector3.new(0,0.7,-0.7).Unit
	check(R.Velocity("Pass",passAim,100).Unit:Dot(passAim)>0.99999,"pass follows full aim")
	check(R.Velocity("Pass",Vector3.new(0,0,-1),100).Magnitude<R.Velocity("Shot",Vector3.new(0,0,-1),100).Magnitude,"pass power distinct")
	for _,key in {"Shot","Pass","Turn","WalkDribble","Run"} do
		local data=Reference[key]
		for _,track in data.recipe.tracks do
			for _,sample in track.keys do
				local expected=CFrame.Angles(math.rad(sample[2][1]),math.rad(sample[2][2]),math.rad(sample[2][3]))
				local actual=A.Sample(key,sample[1])[track.joint]
				local _,angle=expected.Rotation:ToObjectSpace(actual.Rotation):ToAxisAngle()
				check(math.abs(angle)<0.001,"selected asset rotations preserved")
			end
		end
	end
	local s=Sprint.New();Sprint.SetDirection(s,1,0,0);Sprint.SetDirection(s,0,1,0.05)
	check(s.penaltyUntil>0.05,"ordinary90 degree slowdown retained")
	Sprint.SetDirection(s,0,-1,0.1);check(s.speed==32 and s.penaltyUntil==0,"opposite direction has no special penalty")
	local w=Sprint.New();Sprint.SetDirection(w,1,0,0);Sprint.SetDirection(w,-1,0,0.05)
	check(w.speed==32 and w.penaltyUntil==0,"W/S reverse action removed")
	check(Sprint.ObserveFacing==nil,"mouse reverse trigger removed")
	local root=CFrame.new(0,4.2,0)
	local behind=root:PointToWorldSpace(Vector3.new(0,-3,2))
	check(R.Contact(root,behind,false,8)==nil,"free ball behind player rejected")
	local owned=R.Contact(root,behind,true,8)
	check(owned and owned.quality==1 and owned.powerScale==1 and owned.deflectionDegrees==0,"carrier ignores hitbox/mishit")
	check(R.Contact(root,root.Position+Vector3.new(0,0,50),true,8)==nil,"carrier still bounded")
	return count
end
