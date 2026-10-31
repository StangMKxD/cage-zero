--!strict
-- Owner removed the special reverse action; ordinary90deg slowdown stays.
return function(Rules,Config)
	local count=0
	local function check(ok,name) assert(ok,name);count+=1 end
	for _,v in {0/0,math.huge,-math.huge,2,"1",false} do check(not Rules.IsAxis(v),"invalid axis") end
	for _,a in {{1,0},{-1,0},{0,1},{0,-1}} do check(Rules.BaseSpeed(a[1],a[2])==32,"cardinal32") end
	for _,a in {{1,1},{1,-1},{-1,1},{-1,-1}} do check(Rules.BaseSpeed(a[1],a[2])==28.8,"diagonal28.8") end
	local s=Rules.New();Rules.SetDirection(s,1,0,0);Rules.Advance(s,1,0.016)
	Rules.SetDirection(s,0,1,1.01);check(s.speed==28.8,"90deg slowdown retained")
	check(Rules.Advance(s,1.01+Config.TURN_HOLD_SEC-0.01,0.016)==28.8,"ordinary slowdown duration")
	local recovered=Rules.Advance(s,1.01+Config.TURN_HOLD_SEC+0.01,0.016)
	check(recovered>28.8 and recovered<32,"smooth recovery")
	for _,pair in {{{1,0},{-1,0}},{{-1,0},{1,0}},{{0,1},{0,-1}},{{0,-1},{0,1}}} do
		local st=Rules.New();Rules.SetDirection(st,pair[1][1],pair[1][2],0);Rules.Advance(st,1,0.016)
		Rules.SetDirection(st,pair[2][1],pair[2][2],1.02)
		check(st.speed==32,"opposite direction no reverse speed")
		check(st.penaltyUntil==0,"opposite direction no hold")
		check(Rules.Advance(st,1.03,0.016)==32,"reverse no delayed slowdown")
	end
	for _,a in {{-1,-1},{-1,1}} do
		local st=Rules.New();Rules.SetDirection(st,1,0,0);Rules.Advance(st,1,0.016);Rules.SetDirection(st,a[1],a[2],1.01)
		check(st.speed==28.8,"back diagonal uses normal diagonal speed")
	end
	check(Rules.ObserveFacing==nil,"no mouse reverse trigger")
	return count
end

--[============[
Previous reverse-speed assertions superseded by Owner removal.
--!strict
return function(Rules, Config)
	local count = 0
	local function check(ok, message) assert(ok, message); count += 1 end
	local function near(a, b) return math.abs(a - b) < 0.0001 end
	for _, value in {0/0, math.huge, -math.huge, 2, "1", false} do
		check(not Rules.IsAxis(value), "invalid axis")
	end
	for _, axis in {{1,0},{-1,0},{0,1},{0,-1}} do
		check(Rules.BaseSpeed(axis[1],axis[2]) == 32, "every cardinal reaches32")
	end
	for _, axis in {{1,1},{1,-1},{-1,1},{-1,-1}} do
		check(Rules.BaseSpeed(axis[1],axis[2]) == 28.8, "every diagonal stays28.8")
	end
	local state = Rules.New()
	Rules.SetDirection(state,1,0,0)
	check(near(Rules.Advance(state,10,0.016),32), "long held W remains32")
	Rules.SetDirection(state,0,1,10.01)
	check(near(state.speed,28.8), "W then D slows despite no simultaneous keys")
	check(near(Rules.Advance(state,10.01+Config.TURN_HOLD_SEC-0.01,0.016),28.8), "90deg penalty holds through configured duration")
	check(Rules.Advance(state,10.01+Config.TURN_HOLD_SEC+0.01,0.016)>28.8 and state.speed<32, "recovery is gradual")
	for i=1,30 do Rules.Advance(state,10.01+Config.TURN_HOLD_SEC+0.01+i/60,1/60) end
	check(near(state.speed,32), "single D recovers32")
	for _, axis in {{-1,0},{-1,1},{-1,-1}} do
		local s=Rules.New();Rules.SetDirection(s,1,0,0);Rules.Advance(s,1,0.016)
		Rules.SetDirection(s,axis[1],axis[2],1.08)
		check(near(s.speed,25.92), "W to S/SD/SA severe reduction")
		check(near(Rules.Advance(s,1.08+Config.TURN_HOLD_SEC-0.01,0.016),25.92), "reverse holds through configured duration")
		for i=1,40 do Rules.Advance(s,1.08+Config.TURN_HOLD_SEC+0.01+i/60,1/60) end
		check(near(s.speed,Rules.BaseSpeed(axis[1],axis[2])), "recover to held key group")
	end
	local s=Rules.New();Rules.SetDirection(s,1,0,0);Rules.Advance(s,2,0.016)
	Rules.SetDirection(s,-1,0,2.05);local untilTime=s.penaltyUntil
	Rules.SetDirection(s,-1,0,2.1)
	check(s.penaltyUntil==untilTime, "retry same direction does not extend penalty")
	Rules.SetDirection(s,-1,1,2.15)
	check(near(s.speed,25.92), "intermediate diagonal cannot erase reverse penalty")
	Rules.SetDirection(s,0,1,3)
	check(near(s.speed,32), "fresh movement after pause has no stale penalty")
	local staged=Rules.New();Rules.SetDirection(staged,1,0,0)
	Rules.SetDirection(staged,1,1,0.03);Rules.SetDirection(staged,0,1,0.06)
	Rules.SetDirection(staged,-1,1,0.09)
	check(near(staged.speed,25.92), "W to SD through brief intermediate chords is still135deg")
	local deadline=staged.penaltyUntil;Rules.SetDirection(staged,-1,1,0.1)
	check(staged.penaltyUntil==deadline, "same-key retry cannot renew origin-based penalty")
	check(Config.TURN_HOLD_SEC==0.7, "Owner hold duration")
	return count
end

]============]
