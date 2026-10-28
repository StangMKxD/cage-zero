--!strict
-- src/client/character/DribbleClipData.luau
-- Immutable Authored R15 Dribble, Directional Cut, and G-Mode Close-Control Animation Data
-- Governed by RF02-DRIBBLE-ANIMATION-INTEGRATION Contract (2026-10-27).
-- Provides deterministic KeyframeSequence construction with 15 R15 joints and KeyframeMarkers.

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

local function walkDribblePose(u: number): PoseMap
	local uLoop = if u >= 1 then 0 else u
	local touchL = pulse(uLoop, 0.06, 0.1875, 0.34)
	local touchR = pulse(uLoop, 0.56, 0.6875, 0.84)

	local pelY = -0.065 + 0.022 * cos2p(2 * uLoop, -25) - 0.055 * (touchL + touchR)
	local pelX = -0.015 * sin2p(uLoop, 0)
	local pelZ = -0.18 * (touchL + touchR) - 0.02

	local pelPitch = -5.5 - 1.2 * cos2p(2 * uLoop, 0)
	local pelYaw = -4.5 * cos2p(uLoop, 0)
	local pelRoll = 1.6 * sin2p(uLoop, 0)

	local chestPitch = -5.0 - 3.5 * (touchL + touchR)
	local chestYaw = 6.2 * cos2p(uLoop, 0)
	local chestRoll = -1.4 * sin2p(uLoop, 0)

	local headPitch = 8.5 + 3.5 * (touchL + touchR)
	local headYaw = -1.7 * cos2p(uLoop, 0)
	local headRoll = -0.2 * sin2p(uLoop, 0)

	local lArmPitch = -22 * cos2p(uLoop, 0) + 10 * touchR
	local rArmPitch = 22 * cos2p(uLoop, 0) + 10 * touchL
	local lElbow = 28 + 10 * sin2p(uLoop, 15)
	local rElbow = 28 - 10 * sin2p(uLoop, 15)

	local lHipPitch = 25 * cos2p(uLoop, -18) + 28 * touchL
	local lHipYaw = -5.5 * touchL + 1.5 * sin2p(uLoop, 0)
	local lHipRoll = -1.8 - 2.2 * touchL
	local lKneePitch = -12 - 18 * (0.5 - 0.5 * cos2p(uLoop, -55)) - 14 * pulse(uLoop, 0.52, 0.78, 0.98) + 14 * touchL
	local lFootPitch = 7 * cos2p(uLoop, 10) - 22 * touchL
	local lFootYaw = -12 * touchL
	local lFootRoll = 1.0 + 3.5 * touchL

	local uR = (uLoop + 0.5) % 1
	local rHipPitch = 25 * cos2p(uR, -18) + 28 * touchR
	local rHipYaw = 5.5 * touchR - 1.5 * sin2p(uLoop, 0)
	local rHipRoll = 1.8 + 2.2 * touchR
	local rKneePitch = -12 - 18 * (0.5 - 0.5 * cos2p(uR, -55)) - 14 * pulse(uR, 0.52, 0.78, 0.98) + 14 * touchR
	local rFootPitch = 7 * cos2p(uR, 10) - 22 * touchR
	local rFootYaw = 12 * touchR
	local rFootRoll = -1.0 - 3.5 * touchR

	return {
		LowerTorso = { p = Vector3.new(pelX, pelY, pelZ), r = Vector3.new(pelPitch, pelYaw, pelRoll) },
		UpperTorso = { r = Vector3.new(chestPitch, chestYaw, chestRoll) },
		Head = { r = Vector3.new(headPitch, headYaw, headRoll) },
		LeftUpperArm = { r = Vector3.new(lArmPitch, 3.0 * cos2p(uLoop, 0), -12.5) },
		LeftLowerArm = { r = Vector3.new(lElbow, 0, 0) },
		LeftHand = { r = Vector3.new(-3 * cos2p(uLoop, 0), 0, -5) },
		RightUpperArm = { r = Vector3.new(rArmPitch, 3.0 * cos2p(uLoop, 0), 12.5) },
		RightLowerArm = { r = Vector3.new(rElbow, 0, 0) },
		RightHand = { r = Vector3.new(3 * cos2p(uLoop, 0), 0, 5) },
		LeftUpperLeg = { r = Vector3.new(lHipPitch, lHipYaw, lHipRoll) },
		LeftLowerLeg = { r = Vector3.new(lKneePitch, 0, 0) },
		LeftFoot = { r = Vector3.new(lFootPitch, lFootYaw, lFootRoll) },
		RightUpperLeg = { r = Vector3.new(rHipPitch, rHipYaw, rHipRoll) },
		RightLowerLeg = { r = Vector3.new(rKneePitch, 0, 0) },
		RightFoot = { r = Vector3.new(rFootPitch, rFootYaw, rFootRoll) },
	}
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

local function makeDiagFrontPose(dirSign: number)
	-- Inside-of-foot / opposite-foot cut:
	-- Cutting Left (AW, dirSign=+1) plants Left foot outside and sweeps Right foot across to push ball left!
	-- Cutting Right (WD, dirSign=-1) plants Right foot outside and sweeps Left foot across to push ball right!
	local useRightAsCut = dirSign > 0
	return function(u: number): PoseMap
		local plant = pulseQ(u, 0.0, 0.21, 0.64)
		local touch = pulseQ(u, 0.06, 0.412, 0.88)
		local drive = pulseQ(u, 0.30, 0.72, 1.00)

		-- Outward-abducted stance so legs NEVER cross midline:
		-- Left leg HipRoll <= 0 (always abducted left), Right leg HipRoll >= 0 (always abducted right).
		local plantHipPitch = 36 * plant + 16 * touch - 14 * drive
		local plantHipYaw = dirSign * (10 * plant + 8 * touch)
		local plantHipRoll = dirSign * (-14 * plant - 10 * touch - 4 * drive)
		local plantKneePitch = -18 - 44 * plant - 30 * touch - 8 * drive
		local plantFootPitch = 22 * plant + 14 * touch - 14 * drive

		-- Reaching leg lunges far forward (+68 deg hip, nearly extended knee -8 deg at touch peak) so the boot physically strikes the ball at Z ~ -2.56 studs!
		local cutHipPitch = -12 * plant + 68 * touch + 34 * drive
		local cutHipYaw = dirSign * (12 * touch + 16 * drive)
		local cutHipRoll = dirSign * (8 * plant + 12 * touch + 14 * drive)
		local cutKneePitch = -18 - 14 * plant + 10 * touch - 14 * drive
		local cutFootPitch = 10 * plant - 22 * touch + 8 * drive
		local cutFootYaw = dirSign * (20 * touch + 14 * drive)
		local cutFootRoll = dirSign * (12 * touch)

		local pelY = groundedPelvisY(plantHipPitch, plantKneePitch, plantHipRoll, 0.08 * plant + 0.06 * touch)
		local pelX = dirSign * (0.38 * plant - 0.42 * touch - 0.52 * drive)
		-- In R15 LowerTorso local space, -Z is forward! Lunging pelZ to -0.52 at touch brings the boot right onto the ball!
		local pelZ = -0.06 + 0.18 * plant - 0.48 * touch - 0.30 * drive

		local pelPitch = -11.5 - 8.5 * plant - 2.0 * touch - 6.0 * drive
		local pelYaw = dirSign * (-16 * plant + 22 * touch + 28 * drive)
		local pelRoll = dirSign * (12.0 * plant - 10.0 * touch - 12.0 * drive)

		local chestPitch = -13.0 - 9.0 * plant - 9.0 * touch - 4.0 * drive
		local chestYaw = dirSign * (-14 * plant + 28 * touch + 18 * drive)
		local chestRoll = dirSign * (-9.0 * plant + 11.0 * touch + 9.0 * drive)

		local headPitch = 20.5 + 8.0 * plant + 7.5 * touch + 3.0 * drive
		local headYaw = dirSign * (18 * touch + 12 * drive)
		local headRoll = dirSign * (5.0 * plant - 6.0 * touch)

		return {
			LowerTorso = { p = Vector3.new(pelX, pelY, pelZ), r = Vector3.new(pelPitch, pelYaw, pelRoll) },
			UpperTorso = { r = Vector3.new(chestPitch, chestYaw, chestRoll) },
			Head = { r = Vector3.new(headPitch, headYaw, headRoll) },
			LeftUpperArm = {
				r = Vector3.new(
					if useRightAsCut then -34 * plant + 56 * touch - 28 * drive else 38 * plant - 58 * touch + 32 * drive,
					14 * dirSign * touch - 10 * dirSign * plant,
					-14 - 28 * plant - 22 * touch - 12 * drive
				),
			},
			LeftLowerArm = { r = Vector3.new(72 + 18 * plant + 12 * touch + 6 * drive, 10 * plant, 0) },
			LeftHand = { r = Vector3.new(-10 * touch, 0, -6 - 12 * plant) },
			RightUpperArm = {
				r = Vector3.new(
					if useRightAsCut then 38 * plant - 58 * touch + 32 * drive else -34 * plant + 56 * touch - 28 * drive,
					14 * dirSign * touch - 10 * dirSign * plant,
					14 + 28 * plant + 22 * touch + 12 * drive
				),
			},
			RightLowerArm = { r = Vector3.new(72 + 18 * plant + 12 * touch + 6 * drive, -10 * plant, 0) },
			RightHand = { r = Vector3.new(-10 * touch, 0, 6 + 12 * plant) },
			LeftUpperLeg = { r = if useRightAsCut then Vector3.new(plantHipPitch, plantHipYaw, plantHipRoll) else Vector3.new(cutHipPitch, cutHipYaw, cutHipRoll) },
			LeftLowerLeg = { r = Vector3.new(if useRightAsCut then plantKneePitch else cutKneePitch, 0, 0) },
			LeftFoot = { r = if useRightAsCut then Vector3.new(plantFootPitch, -plantHipYaw * 0.5, -plantHipRoll * 0.5) else Vector3.new(cutFootPitch, cutFootYaw, cutFootRoll) },
			RightUpperLeg = { r = if useRightAsCut then Vector3.new(cutHipPitch, cutHipYaw, cutHipRoll) else Vector3.new(plantHipPitch, plantHipYaw, plantHipRoll) },
			RightLowerLeg = { r = Vector3.new(if useRightAsCut then cutKneePitch else plantKneePitch, 0, 0) },
			RightFoot = { r = if useRightAsCut then Vector3.new(cutFootPitch, cutFootYaw, cutFootRoll) else Vector3.new(plantFootPitch, -plantHipYaw * 0.5, -plantHipRoll * 0.5) },
		}
	end
end

local function makeDiagBackPose(dirSign: number)
	-- Inside-pull / opposite-foot drag-back:
	-- BackLeft (AS, dirSign=+1) plants Left support leg and uses Right foot to drag & pull ball toward back-left!
	-- BackRight (SD, dirSign=-1) plants Right support leg and uses Left foot to drag & pull ball toward back-right!
	local useRightAsDrag = dirSign > 0
	return function(u: number): PoseMap
		local reach = pulseQ(u, 0.0, 0.289, 0.72)
		local redirect = pulseQ(u, 0.20, 0.579, 1.00)

		-- Outward-abducted stance so legs NEVER cross midline:
		-- Left leg HipRoll <= 0 (abducted left), Right leg HipRoll >= 0 (abducted right).
		local supHipPitch = 30 * reach + 56 * redirect
		local supHipYaw = dirSign * (10 * reach + 14 * redirect)
		local supHipRoll = dirSign * (-14 * reach - 14 * redirect)
		local supKneePitch = -18 - 46 * reach - 14 * redirect
		local supFootPitch = 22 * reach - 20 * redirect
		local supFootYaw = dirSign * (18 * redirect)

		-- At reach peak (u=0.29), drag leg reaches far forward (+68 deg hip, -6 deg knee) onto the ball, then sweeps back
		local dragHipPitch = 68 * reach - 26 * redirect
		local dragHipYaw = dirSign * (-14 * reach - 24 * redirect)
		local dragHipRoll = dirSign * (14 * reach + 22 * redirect)
		local dragKneePitch = -18 + 12 * reach - 42 * redirect
		local dragFootPitch = -24 * reach + 16 * redirect
		local dragFootYaw = dirSign * (-18 * reach - 14 * redirect)

		local pelY = groundedPelvisY(supHipPitch, supKneePitch, supHipRoll, 0.08 * reach + 0.06 * redirect)
		local pelX = dirSign * (0.36 * reach - 0.54 * redirect)
		-- Forward lunge (-Z) on reach so the boot contacts the ball at Z ~ -2.5 studs, then pulls back
		local pelZ = -0.06 - 0.40 * reach - 0.26 * redirect

		local pelPitch = -11.5 - 3.5 * reach - 3.5 * redirect
		local pelYaw = dirSign * (18 * reach + 46 * redirect)
		local pelRoll = dirSign * (11.5 * reach - 13.0 * redirect)

		local chestPitch = -13.0 - 10.0 * reach - 6.5 * redirect
		local chestYaw = dirSign * (18 * reach + 36 * redirect)
		local chestRoll = dirSign * (-9.0 * reach + 11.0 * redirect)

		local headPitch = 20.5 + 8.5 * reach + 5.5 * redirect
		local headYaw = dirSign * (18 * reach + 24 * redirect)
		local headRoll = dirSign * (4.5 * reach - 5.5 * redirect)

		return {
			LowerTorso = { p = Vector3.new(pelX, pelY, pelZ), r = Vector3.new(pelPitch, pelYaw, pelRoll) },
			UpperTorso = { r = Vector3.new(chestPitch, chestYaw, chestRoll) },
			Head = { r = Vector3.new(headPitch, headYaw, headRoll) },
			LeftUpperArm = {
				r = Vector3.new(
					if useRightAsDrag then 48 * reach - 42 * redirect else -54 * reach + 38 * redirect,
					12 * dirSign * reach - 16 * dirSign * redirect,
					-14 - 26 * reach - 20 * redirect
				),
			},
			LeftLowerArm = { r = Vector3.new(72 + 16 * reach + 12 * redirect, 10 * reach, 0) },
			LeftHand = { r = Vector3.new(-8 * reach, 0, -6 - 6 * reach) },
			RightUpperArm = {
				r = Vector3.new(
					if useRightAsDrag then -54 * reach + 38 * redirect else 48 * reach - 42 * redirect,
					12 * dirSign * reach - 16 * dirSign * redirect,
					14 + 26 * reach + 20 * redirect
				),
			},
			RightLowerArm = { r = Vector3.new(72 + 16 * reach + 12 * redirect, -10 * reach, 0) },
			RightHand = { r = Vector3.new(-8 * reach, 0, 6 + 6 * reach) },
			LeftUpperLeg = { r = if useRightAsDrag then Vector3.new(supHipPitch, supHipYaw, supHipRoll) else Vector3.new(dragHipPitch, dragHipYaw, dragHipRoll) },
			LeftLowerLeg = { r = Vector3.new(if useRightAsDrag then supKneePitch else dragKneePitch, 0, 0) },
			LeftFoot = { r = if useRightAsDrag then Vector3.new(supFootPitch, supFootYaw, 6) else Vector3.new(dragFootPitch, dragFootYaw, 8) },
			RightUpperLeg = { r = if useRightAsDrag then Vector3.new(dragHipPitch, dragHipYaw, dragHipRoll) else Vector3.new(supHipPitch, supHipYaw, supHipRoll) },
			RightLowerLeg = { r = Vector3.new(if useRightAsDrag then dragKneePitch else supKneePitch, 0, 0) },
			RightFoot = { r = if useRightAsDrag then Vector3.new(dragFootPitch, dragFootYaw, -8) else Vector3.new(supFootPitch, supFootYaw, -6) },
		}
	end
end

local function reverseCutWSPose(u: number): PoseMap
	-- Phase 1 (lock): Right foot reaches far forward (-Z) onto top of the ball to trap & stop it.
	-- Phase 2 (pull): Right foot drags the ball straight back through the legs (+Z) while the body pivots toward the new direction.
	local lock = pulseQ(u, 0.0, 0.28, 0.68)
	local pull = pulseQ(u, 0.20, 0.634, 1.00)

	-- Left support leg plants deep into the turf and drives into the new direction
	local lHipPitch = 36 * lock + 56 * pull
	local lHipYaw = -6 * lock - 12 * pull
	local lHipRoll = -16.0 * lock - 14.0 * pull
	local lKneePitch = -18 - 50 * lock - 20 * pull
	local lFootPitch = 24 * lock - 18 * pull
	local lFootYaw = -12 * pull

	-- Right leg reaches far forward (+72 deg hip, nearly straight knee) to trap the ball at TouchR (u=0.29),
	-- then drags straight back (-46 deg hip) through the stride line to push the ball toward the new direction!
	local rHipPitch = 72 * lock - 46 * pull
	local rHipYaw = 6 * lock - 14 * pull
	local rHipRoll = 14.0 * lock + 18.0 * pull
	local rKneePitch = -18 + 14 * lock - 34 * pull
	local rFootPitch = -26 * lock + 24 * pull
	local rFootYaw = 8 * lock - 10 * pull

	local pelY = groundedPelvisY(lHipPitch, lKneePitch, lHipRoll, 0.09 * lock + 0.07 * pull)
	local pelX = -0.32 * lock + 0.36 * pull
	-- Pelvis lunges forward (-0.48) on trap so Right boot lands squarely on the ball, then drives straight through (-0.36)
	local pelZ = -0.06 - 0.44 * lock - 0.32 * pull

	local pelPitch = -11.5 - 5.0 * lock - 5.0 * pull
	local pelYaw = -14 * lock - 34 * pull
	local pelRoll = 10.5 * lock - 11.0 * pull

	local chestPitch = -13.0 - 11.0 * lock - 7.5 * pull
	local chestYaw = -12 * lock - 28 * pull
	local chestRoll = -8.5 * lock + 9.5 * pull

	local headPitch = 20.5 + 9.5 * lock + 6.5 * pull
	local headYaw = -12 * lock - 22 * pull
	local headRoll = 4.0 * lock - 5.0 * pull

	return {
		LowerTorso = { p = Vector3.new(pelX, pelY, pelZ), r = Vector3.new(pelPitch, pelYaw, pelRoll) },
		UpperTorso = { r = Vector3.new(chestPitch, chestYaw, chestRoll) },
		Head = { r = Vector3.new(headPitch, headYaw, headRoll) },
		LeftUpperArm = { r = Vector3.new(58 * lock - 48 * pull, -14 * lock + 18 * pull, -14 - 30 * lock - 18 * pull) },
		LeftLowerArm = { r = Vector3.new(72 + 18 * lock + 12 * pull, 12 * lock, 0) },
		LeftHand = { r = Vector3.new(-10 * lock, 0, -6 - 6 * lock) },
		RightUpperArm = { r = Vector3.new(-60 * lock + 50 * pull, -14 * lock + 18 * pull, 14 + 30 * lock + 18 * pull) },
		RightLowerArm = { r = Vector3.new(72 + 18 * lock + 12 * pull, -12 * lock, 0) },
		RightHand = { r = Vector3.new(-10 * lock, 0, 6 + 6 * lock) },
		LeftUpperLeg = { r = Vector3.new(lHipPitch, lHipYaw, lHipRoll) },
		LeftLowerLeg = { r = Vector3.new(lKneePitch, 0, 0) },
		LeftFoot = { r = Vector3.new(lFootPitch, lFootYaw, 6.5) },
		RightUpperLeg = { r = Vector3.new(rHipPitch, rHipYaw, rHipRoll) },
		RightLowerLeg = { r = Vector3.new(rKneePitch, 0, 0) },
		RightFoot = { r = Vector3.new(rFootPitch, rFootYaw, -6.5) },
	}
end

local function gModeSlowLoopPose(u: number): PoseMap
	local uLoop = if u >= 1 then 0 else u
	local touchL = pulse(uLoop, 0.06, 0.21875, 0.42)
	local touchR = pulse(uLoop, 0.56, 0.71875, 0.92)

	local pelY = -0.105 + 0.018 * cos2p(2 * uLoop, -20) - 0.045 * (touchL + touchR)
	local pelX = -0.022 * sin2p(uLoop, 0)
	local pelZ = -0.04 - 0.22 * (touchL + touchR)

	local pelPitch = -7.5 + 2.0 * (touchL + touchR)
	local pelYaw = -2.5 * cos2p(uLoop, 0)
	local pelRoll = 1.8 * sin2p(uLoop, 0)

	local chestPitch = -6.5 - 4.0 * (touchL + touchR)
	local chestYaw = 2.5 * cos2p(uLoop, 0)
	local chestRoll = -1.5 * sin2p(uLoop, 0)
	local headPitch = 11.5 + 3.5 * (touchL + touchR)

	local lArmPitch = -14 * cos2p(uLoop, 0) + 8 * touchR
	local rArmPitch = 14 * cos2p(uLoop, 0) + 8 * touchL

	local lHipPitch = 22 + 8 * cos2p(uLoop, -15) + 28 * touchL
	local lHipYaw = -8 * touchL
	local lHipRoll = -4.5 - 4.0 * touchL
	local lKneePitch = -26 - 12 * (0.5 - 0.5 * cos2p(uLoop, -45)) + 20 * touchL
	local lFootPitch = 10 - 24 * touchL
	local lFootYaw = -12 * touchL

	local uR = (uLoop + 0.5) % 1
	local rHipPitch = 22 + 8 * cos2p(uR, -15) + 28 * touchR
	local rHipYaw = 8 * touchR
	local rHipRoll = 4.5 + 4.0 * touchR
	local rKneePitch = -26 - 12 * (0.5 - 0.5 * cos2p(uR, -45)) + 20 * touchR
	local rFootPitch = 10 - 24 * touchR
	local rFootYaw = 12 * touchR

	return {
		LowerTorso = { p = Vector3.new(pelX, pelY, pelZ), r = Vector3.new(pelPitch, pelYaw, pelRoll) },
		UpperTorso = { r = Vector3.new(chestPitch, chestYaw, chestRoll) },
		Head = { r = Vector3.new(headPitch, 0, 0) },
		LeftUpperArm = { r = Vector3.new(lArmPitch, 0, -16) },
		LeftLowerArm = { r = Vector3.new(42, 0, 0) },
		LeftHand = { r = Vector3.new(0, 0, -6) },
		RightUpperArm = { r = Vector3.new(rArmPitch, 0, 16) },
		RightLowerArm = { r = Vector3.new(42, 0, 0) },
		RightHand = { r = Vector3.new(0, 0, 6) },
		LeftUpperLeg = { r = Vector3.new(lHipPitch, lHipYaw, lHipRoll) },
		LeftLowerLeg = { r = Vector3.new(lKneePitch, 0, 0) },
		LeftFoot = { r = Vector3.new(lFootPitch, lFootYaw, 3) },
		RightUpperLeg = { r = Vector3.new(rHipPitch, rHipYaw, rHipRoll) },
		RightLowerLeg = { r = Vector3.new(rKneePitch, 0, 0) },
		RightFoot = { r = Vector3.new(rFootPitch, rFootYaw, -3) },
	}
end

local function gModeSoleDragBackPose(u: number): PoseMap
	local trap = pulseQ(u, 0.0, 0.270, 0.62)
	local pull = pulseQ(u, 0.25, 0.649, 0.96)

	-- Left support knee bends deeply into grounded crouch; Right foot reaches onto ball top and drags it back
	local lHipPitch = 24 + 22 * trap + 44 * pull
	local lHipRoll = -6.0 - 8.0 * trap - 6.0 * pull
	local lKneePitch = -28 - 32 * trap - 14 * pull
	local lFootPitch = 18 + 10 * trap - 22 * pull

	local rHipPitch = 20 + 48 * trap - 26 * pull
	local rKneePitch = -26 + 14 * trap - 42 * pull
	local rFootPitch = 8 - 28 * trap + 16 * pull

	local pelY = groundedPelvisY(lHipPitch, lKneePitch, lHipRoll, 0.08 * trap + 0.06 * pull)
	local pelX = -0.24 * trap + 0.20 * pull
	local pelZ = -0.04 - 0.38 * trap - 0.26 * pull

	local pelPitch = -7.5 - 7.0 * trap - 5.0 * pull
	local pelYaw = -10.0 * trap + 6.5 * pull
	local pelRoll = 8.5 * trap - 7.0 * pull

	local chestPitch = -6.5 - 14.5 * trap - 9.0 * pull
	local chestYaw = 10.0 * trap - 6.5 * pull
	local chestRoll = -6.5 * trap + 5.5 * pull
	local headPitch = 11.5 + 16.5 * trap + 10.0 * pull

	return {
		LowerTorso = { p = Vector3.new(pelX, pelY, pelZ), r = Vector3.new(pelPitch, pelYaw, pelRoll) },
		UpperTorso = { r = Vector3.new(chestPitch, chestYaw, chestRoll) },
		Head = { r = Vector3.new(headPitch, 0, -3.5 * trap) },
		LeftUpperArm = { r = Vector3.new(44 * trap - 32 * pull, -10 * trap, -16 - 22 * trap - 10 * pull) },
		LeftLowerArm = { r = Vector3.new(42 + 40 * trap + 28 * pull, 10 * trap, 0) },
		LeftHand = { r = Vector3.new(-8 * trap, 0, -6 - 4 * trap) },
		RightUpperArm = { r = Vector3.new(-48 * trap + 34 * pull, 10 * trap, 16 + 22 * trap + 10 * pull) },
		RightLowerArm = { r = Vector3.new(42 + 40 * trap + 28 * pull, -10 * trap, 0) },
		RightHand = { r = Vector3.new(-8 * trap, 0, 6 + 4 * trap) },
		LeftUpperLeg = { r = Vector3.new(lHipPitch, -12 * pull, lHipRoll) },
		LeftLowerLeg = { r = Vector3.new(lKneePitch, 0, 0) },
		LeftFoot = { r = Vector3.new(lFootPitch, -14 * pull, 5.5) },
		RightUpperLeg = { r = Vector3.new(rHipPitch, 14 * trap - 8 * pull, 9.5 + 6 * trap) },
		RightLowerLeg = { r = Vector3.new(rKneePitch, 0, 0) },
		RightFoot = { r = Vector3.new(rFootPitch, 16 * trap, -5.5) },
	}
end

local Definitions: { [string]: ClipDefinition } = {
	RF02_WalkDribble_R15_v01 = {
		name = "RF02_WalkDribble_R15_v01",
		duration = 1.04,
		keyCount = 209,
		loop = true,
		priority = Enum.AnimationPriority.Movement,
		markers = {
			{ t = 0.0, name = "LeftSupportEntry", value = "left_cycle_start" },
			{ t = 0.195, name = "TouchL", value = "left_foot_ball_touch" },
			{ t = 0.52, name = "MidCycleTransition", value = "right_half_entry" },
			{ t = 0.715, name = "TouchR", value = "right_foot_ball_touch" },
			{ t = 1.04, name = "WalkDribbleLoop", value = "loop_seam" },
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
	RF02_CutDiagFrontLeft_AW_R15_v01 = {
		name = "RF02_CutDiagFrontLeft_AW_R15_v01",
		duration = 0.68,
		keyCount = 137,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0.12, name = "PlantBrake", value = "AW_brake_plant" },
			{ t = 0.28, name = "TouchR", value = "AW_diagonal_cut_touch_right" },
			{ t = 0.56, name = "ControlRelease", value = "cut_exit_ready" },
			{ t = 0.68, name = "ClipEnd", value = "one_shot_complete" },
		},
		poseAt = makeDiagFrontPose(1),
	},
	RF02_CutDiagFrontRight_WD_R15_v01 = {
		name = "RF02_CutDiagFrontRight_WD_R15_v01",
		duration = 0.68,
		keyCount = 137,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0.12, name = "PlantBrake", value = "WD_brake_plant" },
			{ t = 0.28, name = "TouchL", value = "WD_diagonal_cut_touch_left" },
			{ t = 0.56, name = "ControlRelease", value = "cut_exit_ready" },
			{ t = 0.68, name = "ClipEnd", value = "one_shot_complete" },
		},
		poseAt = makeDiagFrontPose(-1),
	},
	RF02_CutDiagBackLeft_AS_R15_v01 = {
		name = "RF02_CutDiagBackLeft_AS_R15_v01",
		duration = 0.76,
		keyCount = 153,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0.12, name = "PlantBrake", value = "AS_brake_entry" },
			{ t = 0.22, name = "TouchR", value = "AS_sole_lock_drag_right" },
			{ t = 0.44, name = "TouchL", value = "AS_exit_redirect_left" },
			{ t = 0.64, name = "ControlRelease", value = "cut_exit_ready" },
			{ t = 0.76, name = "ClipEnd", value = "one_shot_complete" },
		},
		poseAt = makeDiagBackPose(1),
	},
	RF02_CutDiagBackRight_SD_R15_v01 = {
		name = "RF02_CutDiagBackRight_SD_R15_v01",
		duration = 0.76,
		keyCount = 153,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0.12, name = "PlantBrake", value = "SD_brake_entry" },
			{ t = 0.22, name = "TouchL", value = "SD_sole_lock_drag_left" },
			{ t = 0.44, name = "TouchR", value = "SD_exit_redirect_right" },
			{ t = 0.64, name = "ControlRelease", value = "cut_exit_ready" },
			{ t = 0.76, name = "ClipEnd", value = "one_shot_complete" },
		},
		poseAt = makeDiagBackPose(-1),
	},
	RF02_CutReverse_WS_R15_v01 = {
		name = "RF02_CutReverse_WS_R15_v01",
		duration = 0.82,
		keyCount = 165,
		loop = false,
		priority = Enum.AnimationPriority.Action,
		markers = {
			{ t = 0.12, name = "HardBrake", value = "WS_reversal_brake" },
			{ t = 0.24, name = "TouchR", value = "sole_lock_pullback_right" },
			{ t = 0.52, name = "TouchL", value = "reverse_control_tap_left" },
			{ t = 0.68, name = "ControlRelease", value = "cut_exit_ready" },
			{ t = 0.82, name = "ClipEnd", value = "one_shot_complete" },
		},
		poseAt = reverseCutWSPose,
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
		poseAt = gModeSoleDragBackPose,
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
		local timeSec = math.round(u * def.duration * 1000) / 1000
		local poseMap = def.poseAt(u)
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
