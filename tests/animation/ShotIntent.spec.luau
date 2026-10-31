--!strict
-- Run against an uninitialized cloned BallService and a grounded live character.
-- The fixture restores its diagnostic attributes and never initializes a second ball writer.
return function(Service, character: Model)
	local saved = character:GetAttributes()
	local actor = {UserId = -9029, Character = character}
	local count = 0
	local function check(value, name)
		assert(value, name)
		count += 1
	end
	local function send(phase, id, aim, curve)
		return Service.HandleShotIntent(actor, {phase=phase,id=id,aim=aim,curve=curve})
	end
	local ok, failure = pcall(function()
		check(not send("Begin",1),"noncarrier")
		Service.SetPossessor(actor.UserId)
		check(not send("Release",1,Vector3.new(0,0,-1),0),"release without begin")
		for _, id in {0,-1,1.5,math.huge,0/0,"1"} do check(not send("Begin",id),"bad id") end
		check(send("Begin",1),"accepted begin")
		check(not send("Begin",2),"overlapping begin")
		check(not send("Release",2,Vector3.new(0,0,-1),0),"wrong id")
		check(not send("Release",1,Vector3.new(0/0,0,-1),0),"nan aim")
		check(not send("Release",1,Vector3.new(0,0,-1),10),"forged spin")
		check(not send("Release",1,Vector3.new(0,0,-10),0),"forged magnitude")
		check(not send("Cancel",2),"foreign cancel")
		check(send("Release",1,Vector3.new(0,0,-1),0),"accepted release")
		check(not send("Release",1,Vector3.new(0,0,-1),0),"release replay")
		check(not Service.SetDribbleTouchIntent(actor,{}),"no hidden dribble touch")
		check(not Service.SetDribbleCutIntent(actor,{}),"no overlapping cut")
		check(send("Cancel",1),"matching cancel")
		check(not send("Begin",1),"nonce replay")
		check(not send("Begin",2),"cooldown")
	end)
	for key in character:GetAttributes() do
		if key:sub(1,10)=="ServerShot" then character:SetAttribute(key,saved[key]) end
	end
	if not ok then error(failure) end
	return count
end
