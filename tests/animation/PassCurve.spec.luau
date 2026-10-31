--!strict
return function(Rules,ShotRules,Config)
	local count=0
	local function check(ok,label) assert(ok,label);count+=1 end
	local forward=Vector3.new(0,0,-1)
	check(Rules.MaxChargeSec("Pass")==0.55 and Rules.MaxChargeSec("Shot")==1.2,"pass charge faster only")
	check(Rules.Velocity("Pass",forward,0).Magnitude>32,"pass tap faster than sprint")
	check(math.abs(Rules.Velocity("Pass",forward,0.55).Magnitude-Config.Pass.MaxSpeed)<1e-4,"pass full charge")
	check(Rules.Velocity("Shot",forward,0.55).Magnitude<Config.Shot.MaxSpeed,"shot not prematurely full")
	local up=Vector3.new(0,0.6,-0.8)
	local down=Vector3.new(0,-0.6,-0.8)
	check(Rules.Velocity("Pass",up,0.55).Y>0,"lofted pass")
	check(Rules.Velocity("Pass",down,0.55).Y<0,"downward pass reaches floor")
	check(Rules.Velocity("Pass",up,0.55).Unit:Dot(up)>0.99999,"up aim preserved")
	check(Rules.Velocity("Pass",down,0.55).Unit:Dot(down)>0.99999,"down aim preserved")
	check(ShotRules.Aim(Vector3.new(0,0.9,-math.sqrt(0.19)))~=nil,"high aim accepted")
	local straight=Rules.Velocity("Shot",forward,1.2,0)
	local curve=Rules.Velocity("Shot",forward,1.2,-1)
	check(straight.Magnitude==142,"stronger straight")
	check(curve.Magnitude<straight.Magnitude,"curve slower than straight")
	check(math.abs(curve.Magnitude/straight.Magnitude-0.78)<1e-5,"curve speed scale")
	for _,direction in {-1,1} do
		local v=Vector3.new(0,12,-100);local original=v
		for i=1,10 do v=Rules.CurveVelocity(v,direction,0.05) end
		check(v.X*direction>30 and v.X*direction<50,"moderate mirrored curve")
		check(math.abs(v.Y-12)<1e-4,"curve preserves loft")
		check(math.abs(v.Magnitude-original.Magnitude)<0.001,"curve rotates without power gain")
	end
	return count
end
