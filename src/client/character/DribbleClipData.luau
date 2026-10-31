--!strict
-- src/client/character/DribbleClipData.luau
-- Immutable Authored R15 Dribble and G-Mode Close-Control Animation Data
-- Governed by RF02-DRIBBLE-ANIMATION-INTEGRATION Contract (2026-10-27).
-- Provides deterministic KeyframeSequence construction with 15 R15 joints and KeyframeMarkers.

local WalkDribbleReference = require(script.Parent:WaitForChild("WalkDribbleReferenceData"))

export type MarkerEntry = {
	t: number,
	name: string,
	value: string,
}

export type JointSample = {
	p: Vector3?,
	r: Vector3,
}

export type PoseMap = { [string]: JointSample }

export type ClipDefinition = {
	name: string,
	duration: number,
	keyCount: number,
	loop: boolean,
	priority: Enum.AnimationPriority,
	markers: { MarkerEntry },
	frameTimes: { number }?,
	poseAt: (u: number) -> PoseMap,
}

local R15_TREE = {
	name = "HumanoidRootPart",
	children = {
		{
			name = "LowerTorso",
			children = {
				{
					name = "UpperTorso",
					children = {
						{ name = "Head", children = {} },
						{ name = "LeftUpperArm", children = { { name = "LeftLowerArm", children = { { name = "LeftHand", children = {} } } } } },
						{ name = "RightUpperArm", children = { { name = "RightLowerArm", children = { { name = "RightHand", children = {} } } } } },
					},
				},
				{ name = "LeftUpperLeg", children = { { name = "LeftLowerLeg", children = { { name = "LeftFoot", children = {} } } } } },
				{ name = "RightUpperLeg", children = { { name = "RightLowerLeg", children = { { name = "RightFoot", children = {} } } } } },
			},
		},
	},
}

local function sin2p(u: number, phaseDeg: number?): number
	return math.sin(2 * math.pi * u + math.rad(phaseDeg or 0))
end

local function cos2p(u: number, phaseDeg: number?): number
	return math.cos(2 * math.pi * u + math.rad(phaseDeg or 0))
end

-- Quintic C2-continuous bell curve for loop touches
local function pulse(u: number, u0: number, um: number, u1: number): number
	if u <= u0 or u >= u1 then
		return 0
	end
	local s = if u <= um then (u - u0) / (um - u0) else (u1 - u) / (u1 - um)
	return s * s * s * (s * (s * 6 - 15) + 10)
end

-- Septic C3-continuous bell curve (zero 1st, 2nd, and 3rd derivative at endpoints and peak) for ultra-smooth cut motion
local function pulseQ(u: number, u0: number, um: number, u1: number): number
	if u <= u0 or u >= u1 then
		return 0
	end
	local s = if u <= um then (u - u0) / (um - u0) else (u1 - u) / (u1 - um)
	local s2 = s * s
	local s4 = s2 * s2
	return s4 * (35 - 84 * s + 70 * s2 - 20 * s2 * s)
end

local function runDribblePose(u: number): PoseMap
	local uLoop = if u >= 1 then 0 else u
	local touchL = pulse(uLoop, 0.05, 0.1875, 0.33)
	local touchR = pulse(uLoop, 0.55, 0.6875, 0.83)

	local pelY = -0.055 + 0.038 * cos2p(2 * uLoop, -35) - 0.075 * (touchL + touchR)
	local pelX = -0.018 * sin2p(uLoop, 0)
	local pelZ = -0.06 - 0.26 * (touchL + touchR)

	local pelPitch = -11.5 + 3.5 * (touchL + touchR)
	local pelYaw = -11.0 * cos2p(uLoop, 0)
	local pelRoll = 2.2 * sin2p(uLoop, 0)

	local chestPitch = -13.0 - 4.5 * (touchL + touchR)
	local chestYaw = 14.0 * cos2p(uLoop, 0)
	local chestRoll = -1.8 * sin2p(uLoop, 0)

	local headPitch = 20.5 + 3.5 * (touchL + touchR)
	local headYaw = -3.0 * cos2p(uLoop, 0)
	local headRoll = -0.4 * sin2p(uLoop, 0)

	local lArmPitch = -48 * cos2p(uLoop, -10) + 12 * touchR
	local rArmPitch = 48 * cos2p(uLoop, -10) + 12 * touchL
	local lElbow = 72 + 16 * sin2p(uLoop, 10)
	local rElbow = 72 - 16 * sin2p(uLoop, 10)

	local lHipPitch = 46 * cos2p(uLoop, -22) + 26 * touchL
	local lHipYaw = -3.5 * cos2p(uLoop, 0) - 4.0 * touchL
	local lHipRoll = -2.0 - 2.0 * touchL
	local lKneePitch = -18 - 48 * (0.5 - 0.5 * cos2p(uLoop, -65)) + 22 * touchL
	local lFootPitch = 12 * cos2p(uLoop, 15) - 26 * touchL
	local lFootYaw = -6.0 * touchL

	local uR = (uLoop + 0.5) % 1
	local rHipPitch = 46 * cos2p(uR, -22) + 26 * touchR
	local rHipYaw = 3.5 * cos2p(uR, 0) + 4.0 * touchR
	local rHipRoll = 2.0 + 2.0 * touchR
	local rKneePitch = -18 - 48 * (0.5 - 0.5 * cos2p(uR, -65)) + 22 * touchR
	local rFootPitch = 12 * cos2p(uR, 15) - 26 * touchR
	local rFootYaw = 6.0 * touchR

	return {
		LowerTorso = { p = Vector3.new(pelX, pelY, pelZ), r = Vector3.new(pelPitch, pelYaw, pelRoll) },
		UpperTorso = { r = Vector3.new(chestPitch, chestYaw, chestRoll) },
		Head = { r = Vector3.new(headPitch, headYaw, headRoll) },
		LeftUpperArm = { r = Vector3.new(lArmPitch, 7.5 * cos2p(uLoop, 0), -14.0) },
		LeftLowerArm = { r = Vector3.new(lElbow, 0, 0) },
		LeftHand = { r = Vector3.new(-5 * cos2p(uLoop, 0), 0, -6) },
		RightUpperArm = { r = Vector3.new(rArmPitch, 7.5 * cos2p(uLoop, 0), 14.0) },
		RightLowerArm = { r = Vector3.new(rElbow, 0, 0) },
		RightHand = { r = Vector3.new(5 * cos2p(uLoop, 0), 0, 6) },
		LeftUpperLeg = { r = Vector3.new(lHipPitch, lHipYaw, lHipRoll) },
		LeftLowerLeg = { r = Vector3.new(lKneePitch, 0, 0) },
		LeftFoot = { r = Vector3.new(lFootPitch, lFootYaw, 1.2) },
		RightUpperLeg = { r = Vector3.new(rHipPitch, rHipYaw, rHipRoll) },
		RightLowerLeg = { r = Vector3.new(rKneePitch, 0, 0) },
		RightFoot = { r = Vector3.new(rFootPitch, rFootYaw, -1.2) },
	}
end

-- Exact R15 support-leg kinematic vertical drop so the planted foot never floats off the turf during knee bend/abduction
local STAND_LEG_HEIGHT = 1.05 * math.cos(math.rad(6)) + 1.05 * math.cos(math.rad(-14))
local function groundedPelvisY(supHipPitchDeg: number, supKneePitchDeg: number, supHipRollDeg: number, extraDrop: number): number
	local hp = math.rad(supHipPitchDeg)
	local kp = math.rad(supKneePitchDeg)
	local hr = math.rad(supHipRollDeg)
	local curH = (1.05 * math.cos(hp) + 1.05 * math.cos(hp + kp)) * math.cos(hr)
	local drop = math.max(0, STAND_LEG_HEIGHT - curH)
	return -(0.055 + drop * 1.15 + extraDrop)
end

-- Authoring support frame measured from the normalized ROBLOX Boy Height30 rig.
-- This is evaluated while baking clips, not in the per-frame movement controller.
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

local function gGroundPose(pose: PoseMap): PoseMap
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

local function gWalkingFeet(pose: PoseMap, phase: number, forward: number, lateral: number): PoseMap
	if forward == 0 and lateral == 0 then
		return pose
	end
	local function transform(sample: JointSample): CFrame
		return CFrame.new(sample.p or Vector3.zero)
			* CFrame.Angles(math.rad(sample.r.X), math.rad(sample.r.Y), math.rad(sample.r.Z))
	end
	local function sample(frame: CFrame): JointSample
		local x, y, z = frame:ToEulerAnglesXYZ()
		return { r = Vector3.new(math.deg(x), math.deg(y), math.deg(z)) }
	end
	local function align(from: Vector3, to: Vector3): CFrame
		local axis = from.Unit:Cross(to.Unit)
		local dot = math.clamp(from.Unit:Dot(to.Unit), -1, 1)
		if axis.Magnitude < 1e-6 then
			return if dot >= 0 then CFrame.identity else CFrame.Angles(math.pi, 0, 0)
		end
		return CFrame.fromAxisAngle(axis.Unit, math.acos(dot))
	end
	local torso = CFrame.new(0, 4.183 - 1.44150245, 0) * transform(pose.LowerTorso)
		* CFrame.new(0, 0.437955648, -0.0999825597)
	for index, side in ipairs({ "Left", "Right" }) do
		local chain = G_SUPPORT_CHAINS[side]
		local q = (phase + (index - 1) * 0.5) % 1
		local halfStep = if lateral ~= 0 then 0.35 else 0.55
		local offset: number
		local lift = 0
		-- 60% planted, 40% low swing; the two feet never swing simultaneously.
		if q <= 0.6 then
			offset = halfStep * (1 - 2 * q / 0.6)
		else
			local t = (q - 0.6) / 0.4
			local t2, t3 = t * t, t * t * t
			local tangent = -2 * halfStep * 0.4 / 0.6
			offset = -(2 * t3 - 3 * t2 + 1) * halfStep
				+ (t3 - 2 * t2 + t) * tangent
				+ (-2 * t3 + 3 * t2) * halfStep
				+ (t3 - t2) * tangent
			lift = 0.18 * math.sin(math.pi * t) ^ 2
		end
		local sign = if side == "Left" then -1 else 1
		local footRotation = CFrame.Angles(0, math.rad(sign * 5), 0)
		local foot = CFrame.new(sign * 0.78 + lateral * offset, 0.873450398 / 2 + 0.02 + lift, -0.05 - forward * offset)
			* footRotation
		local hip = torso:PointToWorldSpace(chain.hip0)
		local ankle = foot:PointToWorldSpace(chain.ankle1)
		local upperVector, lowerVector = chain.knee0 - chain.hip1, chain.ankle0 - chain.knee1
		local upperLength, lowerLength = upperVector.Magnitude, lowerVector.Magnitude
		local reach = ankle - hip
		local distance = math.clamp(reach.Magnitude, math.abs(upperLength - lowerLength) + 0.001, upperLength + lowerLength - 0.001)
		local direction = reach.Unit
		local pole = Vector3.new(0, 0, -1)
		local bend = (pole - direction * pole:Dot(direction)).Unit
		local along = (upperLength * upperLength + distance * distance - lowerLength * lowerLength) / (2 * distance)
		local knee = hip + direction * along + bend * math.sqrt(math.max(0, upperLength * upperLength - along * along))
		local upper = CFrame.new(hip) * align(upperVector, knee - hip) * CFrame.new(-chain.hip1)
		local lower = CFrame.new(knee) * align(lowerVector, ankle - knee) * CFrame.new(-chain.knee1)
		pose[side .. "UpperLeg"] = sample(CFrame.new(-chain.hip0) * torso:Inverse() * upper * CFrame.new(chain.hip1))
		pose[side .. "LowerLeg"] = sample(CFrame.new(-chain.knee0) * upper:Inverse() * lower * CFrame.new(chain.knee1))
		pose[side .. "Foot"] = sample(CFrame.new(-chain.ankle0) * lower:Inverse() * foot * CFrame.new(chain.ankle1))
	end
	return pose
end

-- Owner-provided 3s walking loop, with source joint rotations/timestamps and level gaze.
-- Root X/Z travel stays with the game controller; baked support height fits the rig.
local function walkDribblePose(u: number): PoseMap
	local frames = WalkDribbleReference.Frames
	local time = math.clamp(u, 0, 1) * 3
	local index = math.clamp(math.floor(time * 30) + 1, 1, #frames - 1)
	while index > 1 and frames[index].time > time do
		index -= 1
	end
	while index < #frames - 1 and frames[index + 1].time < time do
		index += 1
	end
	local first, second = frames[index], frames[index + 1]
	local alpha = math.clamp((time - first.time) / (second.time - first.time), 0, 1)
	local pose: PoseMap = {}
	for joint, name in ipairs(WalkDribbleReference.Parts) do
		local rotation = first.rotations[joint]:Lerp(second.rotations[joint], alpha)
		local x, y, z = rotation:ToEulerAnglesXYZ()
		pose[name] = { r = Vector3.new(math.deg(x), math.deg(y), math.deg(z)) }
	end
	pose.LowerTorso.p = Vector3.new(0, first.travel.Y + (second.travel.Y - first.travel.Y) * alpha, 0)
	-- Keep the accepted body lean, but compensate at the neck so the gaze stays level.
	-- Preserve the reference's horizontal look direction and head roll.
	local function rotation(r: Vector3): CFrame
		return CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))
	end
	local body = rotation(pose.LowerTorso.r) * rotation(pose.UpperTorso.r)
	local head = body * rotation(pose.Head.r)
	local forward = Vector3.new(head.LookVector.X, 0, head.LookVector.Z)
	if forward.Magnitude > 0.001 then
		local roll = math.atan2(head.RightVector.Y, head.UpVector.Y)
		local level = CFrame.lookAt(Vector3.zero, forward.Unit) * CFrame.Angles(0, 0, roll)
		local x, y, z = (body:Inverse() * level):ToEulerAnglesXYZ()
		pose.Head.r = Vector3.new(math.deg(x), math.deg(y), math.deg(z))
	end
	return gGroundPose(pose)
end

-- Goal-facing duel stance: a wider, crouched base with bent arms and low lateral steps.
-- Sinusoidal weight transfer and knee flexion keep velocity continuous at loop seams.
local function gModeGroundStepPose(u: number, forward: number, lateral: number): PoseMap
	local phase = if u >= 1 then 0 else u
	local stride = sin2p(phase, 0)
	local cycle = cos2p(phase, 0)
	local liftL = 0.5 - 0.5 * cycle
	local liftR = 0.5 + 0.5 * cycle
	local moving = math.max(math.abs(forward), math.abs(lateral))
	local side = math.abs(lateral)
	local sway = (0.008 + 0.035 * moving + 0.025 * side) * stride
	local sideRoll = lateral * 6.5 * stride
	local hipSwing = 16 * forward * stride + 6 * side * cycle
	local shuffle = 5 * side
	local hipL = 22 + hipSwing
	local hipR = 22 - hipSwing
	local kneeL = -44 - 12 * moving * liftL
	local kneeR = -44 - 12 * moving * liftR
	local rollL = -9 + sideRoll
	local rollR = 9 + sideRoll
	-- Smooth maximum follows the longer support leg without a hard support switch.
	local supportYLeft = groundedPelvisY(hipL - 7, kneeL, rollL, 0)
	local supportYRight = groundedPelvisY(hipR - 7, kneeR, rollR, 0)
	local heightDelta = supportYLeft - supportYRight
	local pelvisY = 0.5 * (supportYLeft + supportYRight + math.sqrt(heightDelta * heightDelta + 0.015 * 0.015))

	local pose = gGroundPose({
		LowerTorso = {
			p = Vector3.new(sway, pelvisY, -0.035),
			r = Vector3.new(-7, -1.5 * moving * stride, -1.5 * moving * stride),
		},
		UpperTorso = { r = Vector3.new(-9, 3 * moving * stride, 1.5 * moving * stride) },
		Head = { r = Vector3.new(16, -1.5 * moving * stride, 0) },
		LeftUpperArm = { r = Vector3.new(14 - 10 * moving * stride, -7, -30 - 3 * moving * cycle) },
		LeftLowerArm = { r = Vector3.new(58 + 5 * moving * stride, -5, -3) },
		LeftHand = { r = Vector3.new(-5, 0, -7) },
		RightUpperArm = { r = Vector3.new(14 + 10 * moving * stride, 7, 30 + 3 * moving * cycle) },
		RightLowerArm = { r = Vector3.new(58 - 5 * moving * stride, 5, 3) },
		RightHand = { r = Vector3.new(-5, 0, 7) },
		LeftUpperLeg = { r = Vector3.new(hipL, -shuffle, rollL) },
		LeftLowerLeg = { r = Vector3.new(kneeL, 0, 0) },
		LeftFoot = { r = Vector3.new(29 - 6 * moving * liftL, -2 * side, 4 - sideRoll * 0.5) },
		RightUpperLeg = { r = Vector3.new(hipR, shuffle, rollR) },
		RightLowerLeg = { r = Vector3.new(kneeR, 0, 0) },
		RightFoot = { r = Vector3.new(29 - 6 * moving * liftR, 2 * side, -4 - sideRoll * 0.5) },
	})
	return gWalkingFeet(pose, phase, forward, lateral)
end

local function gModeSlowLoopPose(u: number): PoseMap
	return gModeGroundStepPose(u, 0, 0)
end

local function gModeForwardStepPose(u: number): PoseMap
	return gModeGroundStepPose(u, 1, 0)
end

local function gModeBackwardStepPose(u: number): PoseMap
	return gModeGroundStepPose(u, -1, 0)
end

local function gModeLeftStepPose(u: number): PoseMap
	return gModeGroundStepPose(u, 0, -1)
end

local function gModeRightStepPose(u: number): PoseMap
	return gModeGroundStepPose(u, 0, 1)
end

local ShotConfig = require(game:GetService("ReplicatedStorage").Shared.configs.ShotConfigs)
local ShotModel = require(game:GetService("ReplicatedStorage").Shared.ShotModel)
local ShotReference = require(game:GetService("ReplicatedStorage").Shared.ShotReferenceData)
local shotFrameTimes = {}
for _,t in ShotReference.Times do if t<=ShotConfig.SourceEnd then table.insert(shotFrameTimes,t/ShotConfig.PlaybackRate) end end
local Definitions: { [string]: ClipDefinition } = {
 RF02_Shot_R15_v01 = {
  name = ShotConfig.ClipName, duration = ShotConfig.Duration, keyCount = #shotFrameTimes,
  frameTimes = shotFrameTimes, loop = false, priority = Enum.AnimationPriority.Action2,
  markers = {
   {t=0, name="ShotStart", value="Right"},
   {t=ShotConfig.ContactAt, name="BallStrike", value="Right"},
   {t=ShotConfig.ContactEnd, name="ContactEnd", value="Right"},
   {t=ShotConfig.BlendOutAt, name="BlendOut", value=""},
   {t=ShotConfig.Duration, name="ClipEnd", value=""},
  },
  poseAt = function(u) return ShotModel.PoseAt(u*ShotConfig.Duration*ShotConfig.PlaybackRate) end,
 },
	RF02_WalkDribble_R15_v01 = {
		name = "RF02_WalkDribble_R15_v01",
		duration = 3.0,
		keyCount = 91,
		frameTimes = WalkDribbleReference.Times,
		loop = true,
		priority = Enum.AnimationPriority.Movement,
		markers = {
			{ t = 0.0, name = "LeftSupportEntry", value = "left_cycle_start" },
			{ t = 0.4, name = "TouchL", value = "npcmotion_left_contact" },
			{ t = 1.0, name = "TouchR", value = "npcmotion_right_contact" },
			{ t = 1.7333, name = "TouchL", value = "npcmotion_left_contact" },
			{ t = 2.3667, name = "TouchR", value = "npcmotion_right_contact" },
			{ t = 3.0, name = "WalkDribbleLoop", value = "loop_seam" },
		},
		poseAt = walkDribblePose,
	},
	RF02_RunDribble_R15_v01 = {
		name = "RF02_RunDribble_R15_v01",
		duration = 0.72,
		keyCount = 145,
		loop = true,
		priority = Enum.AnimationPriority.Movement,
		markers = {
			{ t = 0.0, name = "LeftDriveEntry", value = "left_stance_entry" },
			{ t = 0.135, name = "TouchL", value = "left_foot_sprint_tap" },
			{ t = 0.36, name = "RightDriveEntry", value = "right_stance_entry" },
			{ t = 0.495, name = "TouchR", value = "right_foot_sprint_tap" },
			{ t = 0.72, name = "RunDribbleLoop", value = "loop_seam" },
		},
		poseAt = runDribblePose,
	},
	RF02_GMode_SlowControlLoop_R15_v01 = {
		name = "RF02_GMode_SlowControlLoop_R15_v01",
		duration = 1.12,
		keyCount = 225,
		loop = true,
		priority = Enum.AnimationPriority.Movement,
		markers = {
			{ t = 0.0, name = "GStanceEntry", value = "goal_facing_close_control_start" },
			{ t = 0.245, name = "TouchL", value = "g_mode_sole_roll_left" },
			{ t = 0.56, name = "GMidStance", value = "goal_facing_mid_cycle" },
			{ t = 0.805, name = "TouchR", value = "g_mode_sole_roll_right" },
			{ t = 1.12, name = "GControlLoop", value = "loop_seam" },
		},
		poseAt = gModeSlowLoopPose,
	},
	RF02_GMode_SoleRollForward_W_R15_v01 = {
		name = "RF02_GMode_SoleRollForward_W_R15_v01",
		duration = 0.64,
		keyCount = 129,
		loop = true,
		priority = Enum.AnimationPriority.Movement,
		markers = {
			{ t = 0.0, name = "GForwardEntry", value = "goal_facing_forward_start" },
			{ t = 0.28, name = "TouchR", value = "g_mode_sole_roll_fwd_right" },
			{ t = 0.32, name = "GMidForward", value = "goal_facing_forward_mid" },
			{ t = 0.64, name = "GForwardLoop", value = "loop_seam" },
		},
		poseAt = gModeForwardStepPose,
	},
	RF02_GMode_SoleRollBackward_S_R15_v01 = {
		name = "RF02_GMode_SoleRollBackward_S_R15_v01",
		duration = 0.64,
		keyCount = 129,
		loop = true,
		priority = Enum.AnimationPriority.Movement,
		markers = {
			{ t = 0.0, name = "GBackwardEntry", value = "goal_facing_backward_start" },
			{ t = 0.26, name = "TouchR", value = "g_mode_sole_drag_back_right" },
			{ t = 0.32, name = "GMidBackward", value = "goal_facing_backward_mid" },
			{ t = 0.64, name = "GBackwardLoop", value = "loop_seam" },
		},
		poseAt = gModeBackwardStepPose,
	},
	RF02_GMode_SoleRollLeft_A_R15_v01 = {
		name = "RF02_GMode_SoleRollLeft_A_R15_v01",
		duration = 0.96,
		keyCount = 193,
		loop = true,
		priority = Enum.AnimationPriority.Movement,
		markers = {
			{ t = 0.0, name = "GLeftEntry", value = "goal_facing_lateral_left_start" },
			{ t = 0.22, name = "TouchR", value = "g_mode_sole_roll_lateral_right_touch_drag_left" },
			{ t = 0.48, name = "GMidLeft", value = "goal_facing_lateral_left_mid" },
			{ t = 0.70, name = "TouchL", value = "g_mode_inside_guide_left" },
			{ t = 0.96, name = "GLeftLoop", value = "loop_seam" },
		},
		poseAt = gModeLeftStepPose,
	},
	RF02_GMode_SoleRollRight_D_R15_v01 = {
		name = "RF02_GMode_SoleRollRight_D_R15_v01",
		duration = 0.96,
		keyCount = 193,
		loop = true,
		priority = Enum.AnimationPriority.Movement,
		markers = {
			{ t = 0.0, name = "GRightEntry", value = "goal_facing_lateral_right_start" },
			{ t = 0.22, name = "TouchL", value = "g_mode_sole_roll_lateral_left_touch_drag_right" },
			{ t = 0.48, name = "GMidRight", value = "goal_facing_lateral_right_mid" },
			{ t = 0.70, name = "TouchR", value = "g_mode_inside_guide_right" },
			{ t = 0.96, name = "GRightLoop", value = "loop_seam" },
		},
		poseAt = gModeRightStepPose,
	},
}

local DribbleClipData = {
	Definitions = Definitions,
}

function DribbleClipData.BuildKeyframeSequence(clipName: string): KeyframeSequence?
	local def = Definitions[clipName]
	if not def then
		return nil
	end

	local sequence = Instance.new("KeyframeSequence")
	sequence.Name = def.name
	sequence.Loop = def.loop
	sequence.Priority = def.priority

	local function buildPose(node: any, poseMap: PoseMap): Pose
		local pose = Instance.new("Pose")
		pose.Name = node.name
		local sample = poseMap[node.name]
		pose.Weight = if sample then 1 else 0
		pose.EasingStyle = Enum.PoseEasingStyle.Cubic
		pose.EasingDirection = Enum.PoseEasingDirection.InOut
		if sample then
			local baseCf = if sample.p then CFrame.new(sample.p) else CFrame.identity
			pose.CFrame = baseCf * CFrame.Angles(math.rad(sample.r.X), math.rad(sample.r.Y), math.rad(sample.r.Z))
		else
			pose.CFrame = CFrame.identity
		end
		for _, child in ipairs(node.children) do
			pose:AddSubPose(buildPose(child, poseMap))
		end
		return pose
	end

	local frames: { Keyframe } = {}
	for i = 0, def.keyCount - 1 do
		local u = i / (def.keyCount - 1)
		local timeSec = if def.frameTimes then def.frameTimes[i + 1] else math.round(u * def.duration * 1000) / 1000
		local poseMap = def.poseAt(if def.frameTimes then timeSec / def.duration else u)
		local frame = Instance.new("Keyframe")
		frame.Time = timeSec
		frame:AddPose(buildPose(R15_TREE, poseMap))
		table.insert(frames, frame)
	end

	for _, m in ipairs(def.markers) do
		local bestFrame: Keyframe = frames[1]
		local bestDist = math.huge
		for _, frame in ipairs(frames) do
			local dist = math.abs(frame.Time - m.t)
			if dist < bestDist then
				bestDist = dist
				bestFrame = frame
			end
		end
		local marker = Instance.new("KeyframeMarker")
		marker.Name = m.name
		marker.Value = m.value
		bestFrame:AddMarker(marker)
	end

	for _, frame in ipairs(frames) do
		sequence:AddKeyframe(frame)
	end

	return sequence
end

return table.freeze(DribbleClipData)

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

-- Immutable Authored R15 Dribble, Directional Cut, and G-Mode Close-Control Animation Data

-- Previous section --
local CutTimeline = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("DribbleCutTimeline"))
local SprintCutReference = require(script.Parent:WaitForChild("SprintCutReferenceData"))

-- Previous section --
	legsOnly: boolean?,
	poseAt: (u: number, gaitPhase: number?) -> PoseMap,

-- Previous section --
local function mirrorCutPose(pose: PoseMap): PoseMap
	local mirrored: PoseMap = {}
	for name, joint in pairs(pose) do
		local other = if name:sub(1, 4) == "Left" then "Right" .. name:sub(5)
			elseif name:sub(1, 5) == "Right" then "Left" .. name:sub(6) else name
		local p = joint.p
		mirrored[other] = {
			p = if p then Vector3.new(-p.X, p.Y, p.Z) else nil,
			r = Vector3.new(joint.r.X, -joint.r.Y, -joint.r.Z),
		}
	end
	return mirrored
end

-- A small directional tap layered over the same running stride; no torso/arm sway.
local function makeRunningCutPose(dirSign: number, turnDegrees: number)
 return function(u: number, gaitPhase: number?): PoseMap
  local phase=((gaitPhase or 0)+u*CutTimeline.Duration/0.72)%1
  local pose=runDribblePose(phase)
  local t=u*CutTimeline.Duration
  local tap=pulse(t,0,CutTimeline.StrikeAt,0.3)
  local exit=pulse(u,0.13,0.4,1)
  local gain=if turnDegrees>90 then 1.2 else 1
  local function add(name: string,x: number,y: number,z: number)
   pose[name].r+=Vector3.new(x,y,z)
  end
  local tapSide=if dirSign>0 then "Left" else "Right"
  local supportSide=if dirSign>0 then "Right" else "Left"
  add(tapSide.."UpperLeg",5*tap,-dirSign*(8*tap+3*exit)*gain,-dirSign*2*tap)
  add(tapSide.."LowerLeg",-7*tap,0,0)
  add(tapSide.."Foot",-3*tap,-dirSign*6*tap*gain,0)
  add(supportSide.."UpperLeg",0,-dirSign*3*exit*gain,dirSign*exit)
  return pose
 end
end


-- Previous section --
local cutFrameTimes = {}
for _, t in SprintCutReference.Times do table.insert(cutFrameTimes, t * CutTimeline.TimeScale) end

-- Previous section --
	RF02_CutDiagFrontLeft_AW_R15_v01 = {
		name = "RF02_CutDiagFrontLeft_AW_R15_v01",
		duration = CutTimeline.Duration,
		keyCount = 61,
		frameTimes = cutFrameTimes,
		legsOnly = true,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0, name = "CutStart", value = "sprint_cut_entry" },
			{ t = CutTimeline.TrapAt, name = "BallTrap", value = "L" },
			{ t = CutTimeline.StrikeAt, name = "TouchL", value = "Strike" },
			{ t = CutTimeline.ReleaseAt, name = "ControlRelease", value = "L" },
			{ t = CutTimeline.BlendOutAt, name = "BlendOut", value = "run_recovery" },
			{ t = CutTimeline.Duration, name = "ClipEnd", value = "complete" },
		},
		poseAt = makeRunningCutPose(1, 45),
	},	RF02_CutDiagFrontRight_WD_R15_v01 = {
		name = "RF02_CutDiagFrontRight_WD_R15_v01",
		duration = CutTimeline.Duration,
		keyCount = 61,
		frameTimes = cutFrameTimes,
		legsOnly = true,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0, name = "CutStart", value = "sprint_cut_entry" },
			{ t = CutTimeline.TrapAt, name = "BallTrap", value = "R" },
			{ t = CutTimeline.StrikeAt, name = "TouchR", value = "Strike" },
			{ t = CutTimeline.ReleaseAt, name = "ControlRelease", value = "R" },
			{ t = CutTimeline.BlendOutAt, name = "BlendOut", value = "run_recovery" },
			{ t = CutTimeline.Duration, name = "ClipEnd", value = "complete" },
		},
		poseAt = makeRunningCutPose(-1, 45),
	},	RF02_CutDiagBackLeft_AS_R15_v01 = {
		name = "RF02_CutDiagBackLeft_AS_R15_v01",
		duration = CutTimeline.Duration,
		keyCount = 61,
		frameTimes = cutFrameTimes,
		legsOnly = true,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0, name = "CutStart", value = "sprint_cut_entry" },
			{ t = CutTimeline.TrapAt, name = "BallTrap", value = "L" },
			{ t = CutTimeline.StrikeAt, name = "TouchL", value = "Strike" },
			{ t = CutTimeline.ReleaseAt, name = "ControlRelease", value = "L" },
			{ t = CutTimeline.BlendOutAt, name = "BlendOut", value = "run_recovery" },
			{ t = CutTimeline.Duration, name = "ClipEnd", value = "complete" },
		},
		poseAt = makeRunningCutPose(1, 135),
	},	RF02_CutDiagBackRight_SD_R15_v01 = {
		name = "RF02_CutDiagBackRight_SD_R15_v01",
		duration = CutTimeline.Duration,
		keyCount = 61,
		frameTimes = cutFrameTimes,
		legsOnly = true,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0, name = "CutStart", value = "sprint_cut_entry" },
			{ t = CutTimeline.TrapAt, name = "BallTrap", value = "R" },
			{ t = CutTimeline.StrikeAt, name = "TouchR", value = "Strike" },
			{ t = CutTimeline.ReleaseAt, name = "ControlRelease", value = "R" },
			{ t = CutTimeline.BlendOutAt, name = "BlendOut", value = "run_recovery" },
			{ t = CutTimeline.Duration, name = "ClipEnd", value = "complete" },
		},
		poseAt = makeRunningCutPose(-1, 135),
	},	RF02_CutReverse_WS_R15_v01 = {
		name = "RF02_CutReverse_WS_R15_v01",
		duration = CutTimeline.Duration,
		keyCount = 61,
		frameTimes = cutFrameTimes,
		legsOnly = true,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0, name = "CutStart", value = "sprint_cut_entry" },
			{ t = CutTimeline.TrapAt, name = "BallTrap", value = "L" },
			{ t = CutTimeline.StrikeAt, name = "TouchL", value = "Strike" },
			{ t = CutTimeline.ReleaseAt, name = "ControlRelease", value = "L" },
			{ t = CutTimeline.BlendOutAt, name = "BlendOut", value = "run_recovery" },
			{ t = CutTimeline.Duration, name = "ClipEnd", value = "complete" },
		},
		poseAt = makeRunningCutPose(1, 180),
	},	RF02_GMode_SlowControlLoop_R15_v01 = {

-- Previous section --
	RF02_GMode_SoleDragBack_WS_R15_v01 = {
		name = "RF02_GMode_SoleDragBack_WS_R15_v01",
		duration = 0.74,
		keyCount = 149,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0.10, name = "SoleTrapEntry", value = "g_mode_sole_reach" },
			{ t = 0.20, name = "TouchR", value = "g_mode_sole_lock_drag_right" },
			{ t = 0.48, name = "TouchL", value = "g_mode_cushion_settle_left" },
			{ t = 0.62, name = "ControlRelease", value = "cut_exit_ready" },
			{ t = 0.74, name = "ClipEnd", value = "one_shot_complete" },
		},
		poseAt = gModeBackwardStepPose,
	},

-- Previous section --
function DribbleClipData.BuildKeyframeSequence(clipName: string, gaitPhase: number?): KeyframeSequence?

-- Previous section --
		pose.Weight = if sample and (not def.legsOnly or node.name:find("Leg") or node.name:find("Foot")) then 1 else 0

-- Previous section --
		local poseMap = def.poseAt(if def.frameTimes then timeSec / def.duration else u, gaitPhase)
]====]
