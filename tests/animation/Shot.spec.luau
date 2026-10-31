--!strict
return function(Rules, Model, Reference, ClipData, Config)
	local count = 0
	local function check(value, message)
		assert(value, message)
		count += 1
	end
	for _, value in {0/0, math.huge, -math.huge, "1", false} do
		check(not Rules.IsFinite(value), "nonfinite scalar")
		check(not Rules.IsActionId(value), "invalid nonce")
	end
	for _, value in {0, -1, 1.5, 2147483648} do check(not Rules.IsActionId(value), "nonce boundary") end
	check(Rules.IsActionId(1) and Rules.IsActionId(2147483647), "nonce range")
	for _, value in {Vector3.zero, Vector3.new(0/0,0,1), Vector3.new(0,math.huge,0),
		Vector3.new(100,0,0), Vector3.yAxis, -Vector3.yAxis} do check(Rules.Aim(value)==nil,"invalid aim") end
	local aim = Rules.Aim(Vector3.new(0,0.3,-1))
	check(aim and math.abs(aim.Magnitude-1)<1e-6,"normalize aim")
	check(math.abs(Rules.Velocity(aim,-1).Magnitude-Config.MinSpeed)<1e-4,"minimum charge")
	check(math.abs(Rules.Velocity(aim,100).Magnitude-Config.MaxSpeed)<1e-4,"charge cap")
	check(Rules.Touches(CFrame.identity,Vector3.zero,1.125),"inside foot")
	check(not Rules.Touches(CFrame.identity,Vector3.new(0,0,9),1.125),"outside foot")
	check(#Reference.Frames==61,"all source frames")
	for _, frame in Reference.Frames do
		local pose = Model.PoseAt(frame.time)
		for i, name in Reference.Parts do
			local r=pose[name].r
			local actual=CFrame.Angles(math.rad(r.X),math.rad(r.Y),math.rad(r.Z))
			local delta=frame.rotations[i]:ToObjectSpace(actual)
			local _,angle=delta:ToAxisAngle()
			check(math.abs(angle)<0.001,"source rotation changed: "..name)
		end
	end
	local seq=ClipData.BuildKeyframeSequence(Config.ClipName)
	check(seq and #seq:GetKeyframes()==22 and not seq.Loop,"one-shot clip")
	check(seq.Priority==Enum.AnimationPriority.Action2,"shot priority")
	local markers={}
	for _, key in seq:GetKeyframes() do
		for _, marker in key:GetMarkers() do markers[marker.Name]=key.Time end
	end
	check(math.abs(markers.BallStrike-Config.ContactAt)<1e-6
		and math.abs(markers.ContactEnd-Config.ContactEnd)<1e-6,"contact markers")
	seq:Destroy()
	local root=CFrame.new(0,4.183,0)
	local foot=Model.FootFrame(root,Config.ContactAt*Config.PlaybackRate,"Right")
	check(Rules.Touches(foot,Vector3.new(1.3,1.125,-2.05),1.125),"authored contact setup")
	check(not Rules.Touches(foot,Vector3.new(-4,1.125,-2.05),1.125),"real whiff")
	return count
end
