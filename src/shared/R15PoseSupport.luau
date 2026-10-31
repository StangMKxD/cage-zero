--!strict
-- Canonical normalized R15 authoring geometry; does not move live characters.
type JointSample = {p: Vector3?, r: Vector3}
type PoseMap = {[string]: JointSample}
local Support = {}
local G_SUPPORT_CHAINS = {
	Left = {
		hip0 = Vector3.new(-0.50000006, -0.387453228, 0.0999825597),
		hip1 = Vector3.new(-0.0755341053, 0.592273593, 0.0578525662),
		knee0 = Vector3.new(-0.0262608826, -0.761328697, -0.0509277508),
		knee1 = Vector3.new(-0.00505596399, 0.489029348, -0.15365231),
		ankle0 = Vector3.new(-0.00246268511, -0.467684567, 0.0713348314),
		ankle1 = Vector3.new(0.00442031026, 0.0454355441, 0.255645543),
	},
	Right = {
		hip0 = Vector3.new(0.49999994, -0.387453228, 0.0999634415),
		hip1 = Vector3.new(0.0755339861, 0.592273414, 0.0578332059),
		knee0 = Vector3.new(0.0265339613, -0.761112213, -0.0509468839),
		knee1 = Vector3.new(0.00532895327, 0.489245981, -0.153671652),
		ankle0 = Vector3.new(0.00232899189, -0.467684567, 0.0713181272),
		ankle1 = Vector3.new(-0.00455403328, 0.0454352126, 0.255628645),
	},
}

function Support.Ground(pose: PoseMap): PoseMap
	local function transform(sample: JointSample): CFrame
		return CFrame.new(sample.p or Vector3.zero)
			* CFrame.Angles(math.rad(sample.r.X), math.rad(sample.r.Y), math.rad(sample.r.Z))
	end
	local torso = CFrame.new(0, 4.183 - 1.44150245, 0) * transform(pose.LowerTorso)
		* CFrame.new(0, 0.437955648, -0.0999825597)
	local bottoms: { number } = {}
	for _, side in ipairs({ "Left", "Right" }) do
		local chain = G_SUPPORT_CHAINS[side]
		local upper = torso * CFrame.new(chain.hip0) * transform(pose[side .. "UpperLeg"]) * CFrame.new(-chain.hip1)
		local lower = upper * CFrame.new(chain.knee0) * transform(pose[side .. "LowerLeg"]) * CFrame.new(-chain.knee1)
		local foot = lower * CFrame.new(chain.ankle0) * transform(pose[side .. "Foot"]) * CFrame.new(-chain.ankle1)
		local halfHeight = math.abs(foot.XVector.Y) * 0.836178064 / 2
			+ math.abs(foot.YVector.Y) * 0.873450398 / 2
			+ math.abs(foot.ZVector.Y) * 1.242453933 / 2
		table.insert(bottoms, foot.Y - halfHeight)
	end
	local delta = bottoms[1] - bottoms[2]
	local supportBottom = 0.5 * (bottoms[1] + bottoms[2] - math.sqrt(delta * delta + 0.01 * 0.01))
	pose.LowerTorso.p = (pose.LowerTorso.p or Vector3.zero) + Vector3.new(0, 0.015 - supportBottom, 0)
	return pose
end



function Support.FootFrame(root: CFrame, pose: PoseMap, side: string): CFrame
 local function transform(s: JointSample): CFrame
  return CFrame.new(s.p or Vector3.zero)*CFrame.Angles(math.rad(s.r.X),math.rad(s.r.Y),math.rad(s.r.Z))
 end
 local chain=G_SUPPORT_CHAINS[side]
 local torso=root*CFrame.new(0,-1.44150245,0)*transform(pose.LowerTorso)*CFrame.new(0,0.437955648,-0.0999825597)
 local upper=torso*CFrame.new(chain.hip0)*transform(pose[side..'UpperLeg'])*CFrame.new(-chain.hip1)
 local lower=upper*CFrame.new(chain.knee0)*transform(pose[side..'LowerLeg'])*CFrame.new(-chain.knee1)
 return lower*CFrame.new(chain.ankle0)*transform(pose[side..'Foot'])*CFrame.new(-chain.ankle1)
end
return table.freeze(Support)
