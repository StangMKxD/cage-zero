--!strict
return function(Timing, Data, Reference)
	local checks=0
	local function check(v,message) assert(v,message);checks+=1 end
	check(#Reference.Frames==91,"complete source")
	local last=-math.huge
	for vy=72,-72,-1 do
		local time=Timing.Sample(vy,72,false)
		check(time>=last and time<=Timing.DescentHold,"monotonic flight without touchdown")
		last=time
	end
	local apex,phase=Timing.Sample(0,72,false)
	check(apex==Timing.Apex and phase=="Apex","actual apex pose")
	for vy=-6,6 do check(Timing.Sample(vy,72,false)==Timing.Apex,"hold reference apex") end
	check(Timing.Sample(-100,72,true)==Timing.DescentHold,"ledge fall skips launch")
	for _,frame in Reference.Frames do
		for _,grounded in {false,true} do
			local pose=Data.PoseAt(frame.time,grounded)
			for i,name in Reference.Parts do
				local r=pose[name].r
				local _,angle=frame.rotations[i]:ToObjectSpace(CFrame.Angles(math.rad(r.X),math.rad(r.Y),math.rad(r.Z))):ToAxisAngle()
				if name:find("UpperArm") then
					check(math.abs(r.X)<=8.001 and math.abs(r.Y)<=10.001 and math.abs(r.Z)<=12.001,"low shoulder: "..name)
				elseif name:find("LowerArm") then
					check(r.X>=24.999 and r.X<=40.001 and math.abs(r.Y)<=8.001 and math.abs(r.Z)<=8.001,"waist elbow: "..name)
				else check(math.abs(angle)<0.001,"source rotation: "..name) end
			end
		end
	end
	for _,key in {"Jump","Land"} do
		local seq=Data.Build(key)
		check(seq and not seq.Loop and seq.Priority==Enum.AnimationPriority.Action,"one-shot "..key)
		local frames=seq:GetKeyframes()
		check(#frames==46,"split key count")
		table.sort(frames,function(a,b)return a.Time<b.Time end)
		check(math.abs(frames[1].Time)<1e-6 and math.abs(frames[#frames].Time-1.5)<1e-6,"split duration")
		seq:Destroy()
	end
	check(Data.Build("Run")==nil,"unrelated clip untouched")
	return checks
end
