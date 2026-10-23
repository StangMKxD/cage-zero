--!strict
-- src/shared/configs/PlayerActionPoseConfigs.luau
-- Authoritative Procedural & Authored R6 Joint Pose Offsets, Curves, & OBB Floor Clearance Solver
-- Adapted from FootballSandbox (.sandbox/prototype3) & Argon R6 Football Animation Pack (A01-A18)
--
-- Provenance:
--   - prototype3/shared/ShiftLockDribble.luau (Calculate8Direction)
--   - prototype3/client/FootballClient.client.luau (lines 1982-2273: procedural slide, dash, curve shots)
--   - prototype3/shared/SandboxConfig.luau (ResolveCurveShot, KICK_PRESETS)
--   - Argon R6 Football Animation Pack (A01-A18, animation-spec.md, R6FootballPoseData.luau)

local Shared = script.Parent.Parent
local Constants = require(Shared:WaitForChild("Constants"))

export type DirectionalWeights = {
	forward: number,
	backward: number,
	left: number,
	right: number,
	idle: number,
}

export type DribbleMotionState = {
	moveDir: Vector3,
	localMove: Vector3,
	speed: number,
	speedAlpha: number,
	strafeAngle: number,
	dominantDir: "Idle" | "Forward" | "Backward" | "StrafeLeft" | "StrafeRight",
	weights: DirectionalWeights,
}

export type R6JointPoseOffsets = {
	RootJoint: CFrame,
	Neck: CFrame,
	RightShoulder: CFrame,
	LeftShoulder: CFrame,
	RightHip: CFrame,
	LeftHip: CFrame,
}

export type ResolvedCurveShot = {
	style: "Finesse" | "Trivela",
	foot: "Right" | "Left",
	ballSide: "Right" | "Left",
	angleDeg: number,
	localBallX: number,
	speed: number,
	upwardBias: number,
	spinY: number,
	topSpin: number,
	magnusFactor: number,
	color: Color3,
	label: string,
	shortButtonLabel: string,
	animType: string,
}

export type JointPoseSpec = {
	pos: Vector3,
	rotDeg: Vector3,
}

export type ContactMarkerSpec = {
	part: string,
	localPoint: Vector3,
	worldPoint: Vector3,
	ballCenter: Vector3,
	surfaceDist: number,
}

export type KeyframeSpec = {
	kf: number,
	t: number,
	timeSec: number?,
	label: string?,
	hrpRefY: number?,
	obbMinY: number?,
	contact: ContactMarkerSpec?,
	joints: { [string]: JointPoseSpec },
}

export type VariantSpec = {
	name: string,
	contactSurfaceDesc: string?,
	keyframes: { KeyframeSpec },
}

export type EightWayDirSpec = {
	dir: string,
	move: Vector3?,
	moveVec: Vector3?,
	torsoRx: number,
	torsoRy: number,
	torsoRz: number,
	neckRy: number,
	hipRx: number?,
	hipRz: number?,
	hipRxAmp: number?,
	hipRzAmp: number?,
	rootY: number?,
}

export type AnimationSpec = {
	id: string,
	name: string,
	mode: "Loop" | "OneShot" | "Hold" | "StateAirborne",
	duration: number,
	blendIn: number,
	blendOut: number,
	holdPhase: number?,
	contactPhase: number?,
	referenceSpeed: number?,
	nextAnimOnRelease: string?,
	nextAnimOnComplete: string?,
	keyframes: { KeyframeSpec },
	variants: { [string]: VariantSpec }?,
	eightWayTable: { EightWayDirSpec }?,
}

local PlayerActionPoseConfigs = {}

-- Provenance record documenting the exact source mapping and Argon pack integration
PlayerActionPoseConfigs.PROVENANCE = table.freeze({
	sourceCommit = "112091950831355-snapshot-2026-10-19",
	sourceShiftLockDribble = "shared/ShiftLockDribble.luau:56-112,191-265",
	sourceFootballClient = "client/FootballClient.client.luau:1982-2273",
	sourceSandboxConfig = "shared/SandboxConfig.luau:344-420",
	sourceArgonPack = "docs/plan/phase-01-gameplay-demo/02-player-actions/assets/designs/argon-r6-pack/",
	argonPackZipSha256 = "c82ef41b057e2a1a0675fd9b2771670a428f3f5720254cee13a8676177b46d49",
	argonPackPoses = "A01-A18",
	adaptedRig = "R6 (Torso, Head, Right Arm, Left Arm, Right Leg, Left Leg)",
})

-- ============================================================================
-- 1. Canonical Standard R6 Rig Dimensions & Joint Socket Pivots
-- ============================================================================
local B = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
local R = CFrame.Angles(0, math.rad(90), 0)
local L = CFrame.Angles(0, math.rad(-90), 0)

PlayerActionPoseConfigs.REST_FRAMES = table.freeze({
	["RootJoint"]      = { C0 = B, C1 = B, pivot = Vector3.new(0, 0, 0) },
	["Neck"]           = { C0 = CFrame.new(0, 1, 0) * B,    C1 = CFrame.new(0, -0.5, 0) * B, pivot = Vector3.new(0, 1, 0) },
	["Right Shoulder"] = { C0 = CFrame.new(1, 0.5, 0) * R,  C1 = CFrame.new(-0.5, 0.5, 0) * R, pivot = Vector3.new(1, 0.5, 0) },
	["Left Shoulder"]  = { C0 = CFrame.new(-1, 0.5, 0) * L, C1 = CFrame.new(0.5, 0.5, 0) * L, pivot = Vector3.new(-1, 0.5, 0) },
	["Right Hip"]      = { C0 = CFrame.new(1, -1, 0) * R,   C1 = CFrame.new(0.5, 1, 0) * R, pivot = Vector3.new(1, -1, 0) },
	["Left Hip"]       = { C0 = CFrame.new(-1, -1, 0) * L,  C1 = CFrame.new(-0.5, 1, 0) * L, pivot = Vector3.new(-1, -1, 0) },
})

PlayerActionPoseConfigs.JOINT_PIVOTS = table.freeze({
	["RootJoint"]      = Vector3.new(0, 0, 0),
	["Neck"]           = Vector3.new(0, 1, 0),
	["Right Shoulder"] = Vector3.new(1, 0.5, 0),
	["Left Shoulder"]  = Vector3.new(-1, 0.5, 0),
	["Right Hip"]      = Vector3.new(1, -1, 0),
	["Left Hip"]       = Vector3.new(-1, -1, 0),
	["RightShoulder"]  = Vector3.new(1, 0.5, 0),
	["LeftShoulder"]   = Vector3.new(-1, 0.5, 0),
	["RightHip"]       = Vector3.new(1, -1, 0),
	["LeftHip"]        = Vector3.new(-1, -1, 0),
})

PlayerActionPoseConfigs.PART_SIZES = table.freeze({
	HumanoidRootPart = Vector3.new(2.0, 2.0, 1.0),
	Torso            = Vector3.new(2.0, 2.0, 1.0),
	Head             = Vector3.new(2.0, 1.0, 1.0),
	RightArm         = Vector3.new(1.0, 2.0, 1.0),
	LeftArm          = Vector3.new(1.0, 2.0, 1.0),
	RightLeg         = Vector3.new(1.0, 2.0, 1.0),
	LeftLeg          = Vector3.new(1.0, 2.0, 1.0),
})

PlayerActionPoseConfigs.PART_HALF_EXTENTS = table.freeze({
	HumanoidRootPart = Vector3.new(1.0, 1.0, 0.5),
	Torso            = Vector3.new(1.0, 1.0, 0.5),
	Head             = Vector3.new(1.0, 0.5, 0.5),
	RightArm         = Vector3.new(0.5, 1.0, 0.5),
	LeftArm          = Vector3.new(0.5, 1.0, 0.5),
	RightLeg         = Vector3.new(0.5, 1.0, 0.5),
	LeftLeg          = Vector3.new(0.5, 1.0, 0.5),
})

PlayerActionPoseConfigs.TARGET_CLEARANCE = 0.010 -- minimum positive clearance above floor Y=0 (studs)

-- ============================================================================
-- 2. Closed-Form Analytical OBB Floor Clearance Solver
-- ============================================================================
-- Evaluates exact lowest bounding box point in O(1) time (<10ns) without raycasts:
--   minY = Position.Y - (|RightVector.Y|*hx + |UpVector.Y|*hy + |LookVector.Y|*hz)
function PlayerActionPoseConfigs.CalculateMinY(cf: CFrame, boxSizeOrHalf: Vector3): number
	local hx: number, hy: number, hz: number
	if boxSizeOrHalf.Y >= 1.5 then
		hx = boxSizeOrHalf.X * 0.5
		hy = boxSizeOrHalf.Y * 0.5
		hz = boxSizeOrHalf.Z * 0.5
	else
		hx = boxSizeOrHalf.X
		hy = boxSizeOrHalf.Y
		hz = boxSizeOrHalf.Z
	end
	return cf.Position.Y - (
		math.abs(cf.RightVector.Y) * hx
		+ math.abs(cf.UpVector.Y) * hy
		+ math.abs(cf.LookVector.Y) * hz
	)
end

function PlayerActionPoseConfigs.GetPartMinY(cf: CFrame, halfSize: Vector3): number
	return cf.Position.Y - (
		math.abs(cf.RightVector.Y) * halfSize.X
		+ math.abs(cf.UpVector.Y) * halfSize.Y
		+ math.abs(cf.LookVector.Y) * halfSize.Z
	)
end

function PlayerActionPoseConfigs.CalculateClearanceOffset(
	cf: CFrame,
	boxSize: Vector3,
	targetClearance: number?
): number
	local target = targetClearance or PlayerActionPoseConfigs.TARGET_CLEARANCE
	local minY = PlayerActionPoseConfigs.CalculateMinY(cf, boxSize)
	local deficit = target - minY
	return if deficit > 0 then deficit else 0
end

function PlayerActionPoseConfigs.CalculateRigMinY(
	rLegCF: CFrame,
	lLegCF: CFrame,
	torsoCF: CFrame?
): number
	local rMin = PlayerActionPoseConfigs.GetPartMinY(rLegCF, PlayerActionPoseConfigs.PART_HALF_EXTENTS.RightLeg)
	local lMin = PlayerActionPoseConfigs.GetPartMinY(lLegCF, PlayerActionPoseConfigs.PART_HALF_EXTENTS.LeftLeg)
	if torsoCF then
		local tMin = PlayerActionPoseConfigs.GetPartMinY(torsoCF, PlayerActionPoseConfigs.PART_HALF_EXTENTS.Torso)
		return math.min(rMin, lMin, tMin)
	end
	return math.min(rMin, lMin)
end

function PlayerActionPoseConfigs.CalculateRigClearanceOffset(
	rLegCF: CFrame,
	lLegCF: CFrame,
	torsoCF: CFrame?,
	targetClearance: number?
): number
	local target = targetClearance or PlayerActionPoseConfigs.TARGET_CLEARANCE
	local lowestY = PlayerActionPoseConfigs.CalculateRigMinY(rLegCF, lLegCF, torsoCF)
	local deficit = target - lowestY
	return if deficit > 0 then deficit else 0
end

function PlayerActionPoseConfigs.ApplyClearanceOffset(
	pose: R6JointPoseOffsets,
	targetClearance: number?
): R6JointPoseOffsets
	local target = targetClearance or PlayerActionPoseConfigs.TARGET_CLEARANCE
	local rootCF = pose.RootJoint or CFrame.identity
	local rHipCF = pose.RightHip or CFrame.identity
	local lHipCF = pose.LeftHip or CFrame.identity

	local rLegCF = rootCF * CFrame.new(1, -1, 0) * rHipCF * CFrame.new(-0.5, -1, 0)
	local lLegCF = rootCF * CFrame.new(-1, -1, 0) * lHipCF * CFrame.new(0.5, -1, 0)

	local function partMinY(cf: CFrame, hx: number, hy: number, hz: number): number
		local extY = math.abs(cf.RightVector.Y) * hx + math.abs(cf.UpVector.Y) * hy + math.abs(cf.LookVector.Y) * hz
		return cf.Position.Y - extY + 3.0
	end

	local rMin = partMinY(rLegCF, 0.5, 1.0, 0.5)
	local lMin = partMinY(lLegCF, 0.5, 1.0, 0.5)
	local tMin = partMinY(rootCF, 1.0, 1.0, 0.5)
	local lowestY = math.min(rMin, lMin, tMin)
	local deficit = target - lowestY
	if deficit > 0 then
		return {
			RootJoint     = CFrame.new(0, deficit, 0) * (pose.RootJoint or CFrame.identity),
			Neck          = pose.Neck,
			RightShoulder = pose.RightShoulder,
			LeftShoulder  = pose.LeftShoulder,
			RightHip      = pose.RightHip,
			LeftHip       = pose.LeftHip,
		}
	end
	return pose
end

-- ============================================================================
-- 3. Motor6D Offset and Transform Builders
-- ============================================================================
function PlayerActionPoseConfigs.BuildMotorOffset(
	baseC0: CFrame,
	pivot: Vector3,
	translation: Vector3,
	rotDeg: Vector3
): CFrame
	local rx = math.rad(rotDeg.X)
	local ry = math.rad(rotDeg.Y)
	local rz = math.rad(rotDeg.Z)
	local D = CFrame.new(translation) * CFrame.Angles(rx, ry, rz)
	local P = CFrame.new(pivot) * D * CFrame.new(-pivot)
	return baseC0:Inverse() * P * baseC0
end

function PlayerActionPoseConfigs.BuildPart0Offset(
	pivot: Vector3,
	translation: Vector3,
	rotDeg: Vector3
): CFrame
	local rx = math.rad(rotDeg.X)
	local ry = math.rad(rotDeg.Y)
	local rz = math.rad(rotDeg.Z)
	local D = CFrame.new(translation) * CFrame.Angles(rx, ry, rz)
	return CFrame.new(pivot) * D * CFrame.new(-pivot)
end

-- ============================================================================
-- 4. Authoritative 8-Way Parameter Table & Locomotion Tuning (F-26 & F-30)
-- ============================================================================
-- Reconciles A05 8-way strafe with scaled lateral root lift (ty in [0.10, 0.35])
PlayerActionPoseConfigs.EIGHT_WAY_PARAMS = table.freeze({
	F  = { dir = "F",  move = Vector3.new(0, 0, -1),               torsoRx = -10.0, torsoRy =   0.0, torsoRz =  0.0, neckRy =   0.0, hipRx =  36.0, hipRz =   2.0, rootY = 0.10 },
	FR = { dir = "FR", move = Vector3.new(1, 0, -1).Unit,         torsoRx =  -9.0, torsoRy = -24.0, torsoRz = -6.0, neckRy =  20.0, hipRx =  28.0, hipRz =  18.0, rootY = 0.22 },
	R  = { dir = "R",  move = Vector3.new(1, 0, 0),                torsoRx = -10.0, torsoRy =  -8.0, torsoRz = -8.0, neckRy =   8.0, hipRx =   8.0, hipRz =  28.0, rootY = 0.35 },
	BR = { dir = "BR", move = Vector3.new(1, 0, 1).Unit,          torsoRx =  -5.0, torsoRy =  24.0, torsoRz = -6.0, neckRy = -20.0, hipRx = -26.0, hipRz =  18.0, rootY = 0.22 },
	B  = { dir = "B",  move = Vector3.new(0, 0, 1),                torsoRx =  -4.0, torsoRy =   0.0, torsoRz =  0.0, neckRy =   0.0, hipRx = -32.0, hipRz =   3.0, rootY = 0.10 },
	BL = { dir = "BL", move = Vector3.new(-1, 0, 1).Unit,         torsoRx =  -5.0, torsoRy = -24.0, torsoRz =  6.0, neckRy =  20.0, hipRx = -26.0, hipRz = -18.0, rootY = 0.22 },
	L  = { dir = "L",  move = Vector3.new(-1, 0, 0),               torsoRx = -10.0, torsoRy =   8.0, torsoRz =  8.0, neckRy =  -8.0, hipRx =   8.0, hipRz = -28.0, rootY = 0.35 },
	FL = { dir = "FL", move = Vector3.new(-1, 0, -1).Unit,        torsoRx =  -9.0, torsoRy =  24.0, torsoRz =  6.0, neckRy = -20.0, hipRx =  28.0, hipRz = -18.0, rootY = 0.22 },
})

PlayerActionPoseConfigs.LOCOMOTION_TUNING = table.freeze({
	WALK_CADENCE = 0.36,         -- Calibrated stride cycle duration (seconds) for WALK_SPEED = 20.0
	WALK_STRIDE_ANGLE_DEG = 42.0, -- Hip pitch amplitude (degrees)
	WALK_PELVIS_YAW_DEG = 10.0,   -- Pelvis yaw amplitude (degrees)
	SPRINT_CADENCE = 0.30,       -- Sprint stride cycle duration (seconds) for SPRINT_SPEED = 32.0
	SPRINT_STRIDE_ANGLE_DEG = 54.0,
	SPRINT_PELVIS_YAW_DEG = 14.0,
	SPRINT_DUTY_CYCLE = 0.40,    -- 40% stance ground contact, 60% flight phase
})

-- ============================================================================
-- 5. 8-Directional Motion Analysis & Locomotion Generators
-- ============================================================================
function PlayerActionPoseConfigs.Calculate8Direction(
	hrpCF: CFrame,
	moveDir: Vector3,
	speed: number,
	baseWalkSpeed: number?
): DribbleMotionState
	local flatMove = Vector3.new(moveDir.X, 0, moveDir.Z)
	local isMoving = flatMove.Magnitude > 0.04
	local localMove = if isMoving then hrpCF:VectorToObjectSpace(flatMove.Unit) else Vector3.zero
	local nominalSpeed = baseWalkSpeed or Constants.WALK_SPEED
	local speedAlpha = math.clamp(speed / nominalSpeed, 0, 1.6)

	-- Object Space: -Z = Forward, +Z = Backward, -X = Strafe Left, +X = Strafe Right
	local rawFwd = math.clamp(-localMove.Z, 0, 1)
	local rawBwd = math.clamp(localMove.Z, 0, 1)
	local rawLeft = math.clamp(-localMove.X, 0, 1)
	local rawRight = math.clamp(localMove.X, 0, 1)
	local moveMag = if isMoving then math.min(1, flatMove.Magnitude) else 0

	local weights: DirectionalWeights = {
		forward = rawFwd * moveMag,
		backward = rawBwd * moveMag,
		left = rawLeft * moveMag,
		right = rawRight * moveMag,
		idle = if isMoving then math.clamp(1 - speedAlpha, 0, 1) else 1,
	}

	local dominant: "Idle" | "Forward" | "Backward" | "StrafeLeft" | "StrafeRight" = "Idle"
	if not isMoving or speed < 0.8 then
		dominant = "Idle"
	elseif rawFwd >= rawBwd and rawFwd >= rawLeft and rawFwd >= rawRight then
		dominant = "Forward"
	elseif rawBwd >= rawFwd and rawBwd >= rawLeft and rawBwd >= rawRight then
		dominant = "Backward"
	elseif rawLeft >= rawFwd and rawLeft >= rawBwd and rawLeft >= rawRight then
		dominant = "StrafeLeft"
	else
		dominant = "StrafeRight"
	end

	local strafeAngle = if isMoving then math.atan2(localMove.X, -localMove.Z) else 0

	return {
		moveDir = flatMove,
		localMove = localMove,
		speed = speed,
		speedAlpha = speedAlpha,
		strafeAngle = strafeAngle,
		dominantDir = dominant,
		weights = weights,
	}
end

function PlayerActionPoseConfigs.GetLocomotionPose(motion: DribbleMotionState, stridePhase: number): R6JointPoseOffsets
	local touchWave = math.sin(stridePhase)
	local tapPulse = math.cos(stridePhase)
	local w = motion.weights
	local sAlpha = motion.speedAlpha

	-- Calibrated stride angles: Walk (42 deg) and Sprint (up to 54 deg) per F-30
	local isSprinting = sAlpha > 1.2
	local maxPitch = if isSprinting then 54.0 else 42.0
	local pelvisYaw = if isSprinting then 14.0 else 10.0
	local pitchAmp = maxPitch * math.min(1.0, sAlpha)
	local armAmp = pitchAmp * 0.90

	-- Forward swing
	local fwdRightHip = CFrame.Angles(math.rad(pitchAmp * touchWave), math.rad(pelvisYaw * tapPulse * sAlpha), 0)
	local fwdLeftHip = CFrame.Angles(math.rad(-pitchAmp * touchWave), math.rad(-pelvisYaw * tapPulse * sAlpha), 0)
	local fwdRightShoulder = CFrame.Angles(math.rad(-armAmp * touchWave), 0, math.rad(10))
	local fwdLeftShoulder = CFrame.Angles(math.rad(armAmp * touchWave), 0, math.rad(-10))

	-- Backward drag & backpedal
	local bwdRightHip = CFrame.Angles(math.rad(-26 * touchWave * sAlpha), math.rad(8), 0)
	local bwdLeftHip = CFrame.Angles(math.rad(26 * touchWave * sAlpha), math.rad(-8), 0)
	local bwdRightShoulder = CFrame.Angles(math.rad(24 * touchWave * sAlpha), 0, math.rad(10))
	local bwdLeftShoulder = CFrame.Angles(math.rad(-24 * touchWave * sAlpha), 0, math.rad(-10))

	-- Reconciled Strafe Left / Right with lateral lift (rootY up to +0.35 studs)
	local leftRightHip = CFrame.Angles(math.rad(14 * tapPulse), math.rad(20 * tapPulse), math.rad(-14))
	local leftLeftHip = CFrame.Angles(math.rad(-14 * tapPulse), math.rad(14 * tapPulse), math.rad(-8))
	local leftRightShoulder = CFrame.Angles(math.rad(10), 0, math.rad(25))
	local leftLeftShoulder = CFrame.Angles(math.rad(-10), 0, math.rad(-35))

	local rightRightHip = CFrame.Angles(math.rad(14 * tapPulse), math.rad(-20 * tapPulse), math.rad(14))
	local rightLeftHip = CFrame.Angles(math.rad(-14 * tapPulse), math.rad(-14 * tapPulse), math.rad(8))
	local rightRightShoulder = CFrame.Angles(math.rad(-10), 0, math.rad(35))
	local rightLeftShoulder = CFrame.Angles(math.rad(10), 0, math.rad(-25))

	-- Blend leg & arm poses
	local rHip = fwdRightHip:Lerp(bwdRightHip, w.backward):Lerp(leftRightHip, w.left):Lerp(rightRightHip, w.right)
	local lHip = fwdLeftHip:Lerp(bwdLeftHip, w.backward):Lerp(leftLeftHip, w.left):Lerp(rightLeftHip, w.right)
	local rShoulder = fwdRightShoulder:Lerp(bwdRightShoulder, w.backward):Lerp(leftRightShoulder, w.left):Lerp(rightRightShoulder, w.right)
	local lShoulder = fwdLeftShoulder:Lerp(bwdLeftShoulder, w.backward):Lerp(leftLeftShoulder, w.left):Lerp(rightLeftShoulder, w.right)

	-- Root lift: base 0.10, scaling smoothly up to +0.35 on lateral strafes per F-26
	local lateralFactor = math.clamp(w.left + w.right, 0, 1)
	local rootY = 0.10 + (0.25 * lateralFactor)
	if isSprinting then
		-- 40% duty cycle flight phase bob
		rootY = rootY + 0.12 * math.max(0, math.cos(stridePhase * 2))
	end

	local rootTorso = CFrame.new(0, rootY, 0) * CFrame.Angles(
		math.rad((-8 * w.forward + 8 * w.backward) * sAlpha),
		math.rad((8 * w.left - 8 * w.right) * sAlpha),
		math.rad((-8 * w.left + 8 * w.right) * sAlpha)
	)

	local headNeck = CFrame.Angles(
		math.rad((6 * w.forward - 4 * w.backward) * sAlpha),
		math.rad((-4 * w.left + 4 * w.right) * sAlpha),
		0
	)

	return PlayerActionPoseConfigs.ApplyClearanceOffset({
		RootJoint = rootTorso,
		Neck = headNeck,
		RightShoulder = rShoulder,
		LeftShoulder = lShoulder,
		RightHip = rHip,
		LeftHip = lHip,
	})
end

function PlayerActionPoseConfigs.Get8WayStrafePose(localMove: Vector3, stridePhase: number): R6JointPoseOffsets
	local flatMove = Vector3.new(localMove.X, 0, localMove.Z)
	if flatMove.Magnitude < 0.05 then
		return PlayerActionPoseConfigs.SampleAuthoredPose("A01", 0)
	end
	local dir = flatMove.Unit
	local right = dir.X
	local fwd = -dir.Z

	local s = math.sin(stridePhase)
	local c = math.cos(stridePhase)

	local diagSign = if math.abs(fwd) >= 0.15 then math.sign(fwd) else 1.0
	local torsoRy = math.clamp(-right * fwd * 48.0, -24.0, 24.0)
	local torsoRx = -8.0 - 4.0 * math.max(0, fwd)
	local torsoRz = -8.0 * right
	local hipRxAmp = 34.0 * fwd
	local hipRzAmp = 26.0 * right

	-- Root lift: 0.10 (F/B) -> 0.22 (diagonals) -> 0.35 (L/R)
	local rootY = 0.10 + 0.25 * math.abs(right)

	local pose: R6JointPoseOffsets = {
		RootJoint = CFrame.new(0.03 * right * s, rootY, 0) * CFrame.Angles(
			math.rad(torsoRx),
			math.rad(torsoRy - 6.0 * c * diagSign),
			math.rad(torsoRz)
		),
		Neck = CFrame.Angles(math.rad(-torsoRx), math.rad(-torsoRy * 0.85), math.rad(-torsoRz * 0.75)),
		RightShoulder = CFrame.Angles(math.rad(-28.0 * fwd * c), math.rad(-6.0), math.rad(18.0 + 8.0 * math.max(0, right))),
		LeftShoulder  = CFrame.Angles(math.rad(28.0 * fwd * c),  math.rad(6.0),  math.rad(-18.0 - 8.0 * math.max(0, -right))),
		RightHip      = CFrame.Angles(math.rad(hipRxAmp * c), math.rad(torsoRy * 0.35), math.rad(math.max(2.0, hipRzAmp * c + 14.0 * math.max(0, right)))),
		LeftHip       = CFrame.Angles(math.rad(-hipRxAmp * c), math.rad(torsoRy * 0.35), math.rad(math.min(-2.0, hipRzAmp * c - 14.0 * math.max(0, -right)))),
	}

	return PlayerActionPoseConfigs.ApplyClearanceOffset(pose)
end

-- ============================================================================
-- 6. Dash, Charge Stance Hold, and Action Follow-Through Poses
-- ============================================================================
function PlayerActionPoseConfigs.GetDashPose(progress: number): R6JointPoseOffsets
	return PlayerActionPoseConfigs.SampleAuthoredPose("A04", math.clamp(progress, 0, 1))
end

function PlayerActionPoseConfigs.GetChargePose(chargeAction: string, elapsed: number, curveStyle: string?): R6JointPoseOffsets
	local pullAlpha = math.clamp(elapsed / 0.20, 0, 1)

	if chargeAction == "Slide" or chargeAction == "SlideKick" then
		return PlayerActionPoseConfigs.SampleAuthoredPose("A17", 0.0)
	elseif chargeAction == "Volley" or chargeAction == "AirDirectShoot" then
		-- A10: Mid-air Volley / Air Shoot Chamber (Hold Lock at Keyframe 1)
		local phase = math.clamp(pullAlpha * 0.35, 0, 0.35)
		return PlayerActionPoseConfigs.SampleAuthoredPose("A10", phase)
	elseif chargeAction == "CurveShoot" or chargeAction == "ShootCurve" or chargeAction == "ShootFinesse" or chargeAction == "ShootTrivela" then
		-- A14: Curve Shoot Wind-up / Hold. Samples KF1 -> KF3 (t = 0.50 HOLD LOCK)
		local phase = math.clamp(pullAlpha * 0.50, 0, 0.50)
		local pose = PlayerActionPoseConfigs.SampleAuthoredPose("A14", phase)
		if curveStyle == "Trivela" then
			-- Invert coronal roll & yaw for Trivela (outside-foot curl windup)
			local rj = pose.RootJoint
			local rrx, rry, rrz = rj:ToEulerAnglesXYZ()
			local lh = pose.LeftHip
			local lrx, lry, lrz = lh:ToEulerAnglesXYZ()
			pose.RootJoint = CFrame.new(rj.Position) * CFrame.Angles(rrx, -rry, -rrz)
			pose.LeftHip = CFrame.new(lh.Position) * CFrame.Angles(lrx, -lry, -lrz)
		end
		return pose
	elseif chargeAction == "Pass" or chargeAction == "GroundPass" or chargeAction == "LobPass" then
		-- A16: Single 3D Pass Wind-up / Open-hip Push Chamber (Hold Lock at Keyframe 1, t in [0.0, 0.32])
		local phase = math.clamp(pullAlpha * 0.32, 0, 0.32)
		local variant = if chargeAction == "LobPass" or curveStyle == "lob" then "lob" else "ground"
		return PlayerActionPoseConfigs.SampleAuthoredPose("A16", phase, variant)
	else
		-- DirectShoot (A12): Direct Shoot Wind-up / Hold. Samples KF1 -> KF3 (t = 0.50 HOLD LOCK)
		local phase = math.clamp(pullAlpha * 0.50, 0, 0.50)
		return PlayerActionPoseConfigs.SampleAuthoredPose("A12", phase)
	end
end

-- ============================================================================
-- 7. Single 3D Pass Generator (Parametric Ground & Lob Variants)
-- ============================================================================
-- Reconciles A16: single action "Pass", ground and lob are visual variants,
-- plant foot (Left Leg) and root height remain unscaled by power.
function PlayerActionPoseConfigs.GetPassPose(progress: number, elevationDeg: number?, power: number?): R6JointPoseOffsets
	local p = math.clamp(progress, 0, 1)
	local elev = math.clamp(elevationDeg or 0, 0, 45)
	local alphaElev = math.clamp(elev / 35.0, 0, 1)
	local pwr = math.clamp(power or 0.65, 0.1, 1.0)
	local sPower = 0.70 + 0.30 * pwr

	local groundPose = PlayerActionPoseConfigs.SampleAuthoredPose("A16", p, "ground")
	local lobPose = PlayerActionPoseConfigs.SampleAuthoredPose("A16", p, "lob")

	-- Interpolate base pose between ground and lob
	local baseRoot = groundPose.RootJoint:Lerp(lobPose.RootJoint, alphaElev)
	local baseNeck = groundPose.Neck:Lerp(lobPose.Neck, alphaElev)
	local baseRShoulder = groundPose.RightShoulder:Lerp(lobPose.RightShoulder, alphaElev)
	local baseLShoulder = groundPose.LeftShoulder:Lerp(lobPose.LeftShoulder, alphaElev)
	local baseRHip = groundPose.RightHip:Lerp(lobPose.RightHip, alphaElev)
	local baseLHip = groundPose.LeftHip:Lerp(lobPose.LeftHip, alphaElev)

	-- Apply power scaling ONLY to kicking leg (Right Hip) swing amplitude
	local rx, ry, rz = baseRHip:ToEulerAnglesXYZ()
	local scaledRHip = CFrame.new(baseRHip.Position) * CFrame.Angles(rx * sPower, ry * sPower, rz)

	return PlayerActionPoseConfigs.ApplyClearanceOffset({
		RootJoint     = baseRoot,      -- Root height unscaled by power
		Neck          = baseNeck,
		RightShoulder = baseRShoulder,
		LeftShoulder  = baseLShoulder,
		RightHip      = scaledRHip,    -- Kicking limb scaled by power
		LeftHip       = baseLHip,      -- Plant leg unscaled by power
	})
end

function PlayerActionPoseConfigs.GetFollowThroughPose(
	actionType: string,
	progress: number,
	curveStyle: string?,
	passPower: number?,
	passElevationDeg: number?
): R6JointPoseOffsets
	local clamped = math.clamp(progress, 0, 1)
	local swing = math.sin(clamped * math.pi)

	if actionType == "Header" then
		return PlayerActionPoseConfigs.SampleAuthoredPose("A08", clamped)
	elseif actionType == "Block" then
		return PlayerActionPoseConfigs.SampleAuthoredPose("A09", clamped)
	elseif actionType == "Volley" or actionType == "AirborneVolley" then
		return PlayerActionPoseConfigs.SampleAuthoredPose("A10", clamped)
	elseif actionType == "BicycleKick" or actionType == "AcrobaticFinishing" then
		return PlayerActionPoseConfigs.SampleAuthoredPose("A11", clamped)
	elseif actionType == "Pass" or actionType == "GroundPass" or actionType == "LobPass" then
		local elev = passElevationDeg
		if not elev and (curveStyle == "lob" or actionType == "LobPass") then
			elev = 35.0
		end
		return PlayerActionPoseConfigs.GetPassPose(clamped, elev, passPower)
	elseif actionType == "CurveShoot" or actionType == "ShootCurve" or actionType == "ShootFinesse" or actionType == "ShootTrivela" then
		local variant = if curveStyle == "Trivela" or actionType == "ShootTrivela" then "trivela" else "finesse"
		return PlayerActionPoseConfigs.SampleAuthoredPose("A15", clamped, variant)
	elseif actionType == "jump" then
		return PlayerActionPoseConfigs.GetJumpPose()
	else
		-- DirectShoot (A13)
		return PlayerActionPoseConfigs.SampleAuthoredPose("A13", clamped)
	end
end

-- ============================================================================
-- 8. Slide Tackle & Recovery Poses (Backward Compatible & A17/A18 Variants)
-- ============================================================================
-- Distinct turf slide pose: lowered torso (-0.92), extended lead sweeping leg, tucked trail leg.
-- Guaranteed RootJoint.Position.Y == -0.92 and RightHip.Position.Z == -0.62 for TC-P02-40 compatibility when progress is nil.
-- When progress is provided, evaluates authored A17 Slide Tackle timeline (Drop Entry -> Active Extension -> Exit).
function PlayerActionPoseConfigs.GetSlidePose(progress: number?): R6JointPoseOffsets
	if progress ~= nil then
		return PlayerActionPoseConfigs.SampleAuthoredPose("A17", math.clamp(progress, 0, 1))
	end
	return {
		RootJoint = CFrame.new(0, -0.92, 0) * CFrame.Angles(math.rad(-28), 0, math.rad(-15)),
		Neck = CFrame.Angles(math.rad(28), 0, 0),
		RightShoulder = CFrame.Angles(math.rad(-35), 0, math.rad(48)),
		LeftShoulder = CFrame.Angles(math.rad(65), 0, math.rad(-48)),
		RightHip = CFrame.new(0.12, -0.28, -0.62) * CFrame.Angles(math.rad(88), math.rad(-8), math.rad(-12)),
		LeftHip = CFrame.new(-0.15, 0.14, 0.48) * CFrame.Angles(math.rad(-55), math.rad(28), math.rad(22)),
	}
end

function PlayerActionPoseConfigs.GetSlideRecoveryPose(progress: number, variant: string?): R6JointPoseOffsets
	local p = math.clamp(progress, 0, 1)
	if variant == "hit" or variant == "miss" then
		return PlayerActionPoseConfigs.SampleAuthoredPose("A18", p, variant)
	end

	-- Default smooth rise recovery curve
	local rise = math.sin(p * math.pi * 0.5)
	local yOffset = -0.95 + (0.55 * rise)

	return {
		RootJoint = CFrame.new(0, yOffset, 0) * CFrame.Angles(math.rad((-28 + 46 * rise)), 0, math.rad(-15 * (1 - rise))),
		Neck = CFrame.Angles(math.rad(28 * (1 - rise) - 8 * rise), 0, 0),
		RightShoulder = CFrame.Angles(math.rad(-35 * (1 - rise) + 30 * rise), 0, math.rad(48 * (1 - rise) + 20 * rise)),
		LeftShoulder = CFrame.Angles(math.rad(65 * (1 - rise) - 30 * rise), 0, math.rad(-48 * (1 - rise) - 20 * rise)),
		RightHip = CFrame.new(0.12 * (1 - rise), -0.28 * (1 - rise), -0.75 * (1 - rise)) * CFrame.Angles(math.rad(88 * (1 - rise) + 20 * rise), 0, 0),
		LeftHip = CFrame.new(-0.15 * (1 - rise), 0.14 * (1 - rise), 0.55 * (1 - rise)) * CFrame.Angles(math.rad(-55 * (1 - rise) - 20 * rise), 0, 0),
	}
end

-- ============================================================================
-- 9. Aerial Jump, Landing Cushion, and Whiff Recovery Poses
-- ============================================================================
-- Evaluates authored A06 Directional Jump across flight trajectory:
-- vy > 0 (ascent) -> phase 0.05..0.45; vy ≈ 0 (apex) -> phase 0.50; vy < 0 (descent) -> phase 0.55..0.95.
-- If verticalVelocity is nil, defaults to apex phase (0.50) for backwards compatibility.
function PlayerActionPoseConfigs.GetJumpPose(verticalVelocity: number?): R6JointPoseOffsets
	local phase = 0.50
	if verticalVelocity ~= nil then
		local refVy = 72.0
		phase = math.clamp(0.50 - 0.50 * (verticalVelocity / refVy), 0.05, 0.95)
	end
	return PlayerActionPoseConfigs.SampleAuthoredPose("A06", phase)
end

function PlayerActionPoseConfigs.GetJumpLandingPose(progress: number): R6JointPoseOffsets
	return PlayerActionPoseConfigs.SampleAuthoredPose("A07", math.clamp(progress, 0, 1))
end

function PlayerActionPoseConfigs.GetWhiffPose(progress: number): R6JointPoseOffsets
	local p = math.clamp(progress, 0, 1)
	if p < 0.38 then
		local t = p / 0.38
		local swing = math.sin(t * math.pi * 0.5)
		return {
			RootJoint = CFrame.Angles(math.rad(22 * swing), 0, 0),
			Neck = CFrame.Angles(math.rad(-16 * swing), 0, 0),
			RightShoulder = CFrame.Angles(math.rad(-65 * swing), 0, math.rad(48 * swing)),
			LeftShoulder = CFrame.Angles(math.rad(65 * swing), 0, math.rad(-48 * swing)),
			RightHip = CFrame.Angles(math.rad(115 * swing), 0, math.rad(-12 * swing)),
			LeftHip = CFrame.Angles(math.rad(-18 * swing), 0, 0),
		}
	elseif p < 0.76 then
		local t = (p - 0.38) / 0.38
		local stumble = math.sin(t * math.pi)
		return {
			RootJoint = CFrame.Angles(math.rad(14 * stumble), math.rad(35 * stumble), math.rad(-24 * stumble)),
			Neck = CFrame.Angles(math.rad(-8 * stumble), math.rad(-18 * stumble), 0),
			RightShoulder = CFrame.Angles(math.rad(30 * stumble), 0, math.rad(52 * stumble)),
			LeftShoulder = CFrame.Angles(math.rad(-45 * stumble), 0, math.rad(-45 * stumble)),
			RightHip = CFrame.Angles(math.rad(35 * stumble), math.rad(-22 * stumble), math.rad(18 * stumble)),
			LeftHip = CFrame.Angles(math.rad(15 * stumble), math.rad(18 * stumble), math.rad(-18 * stumble)),
		}
	else
		local t = (p - 0.76) / 0.24
		local recover = 1 - t
		return {
			RootJoint = CFrame.new(0, -0.22 * recover, 0) * CFrame.Angles(math.rad(12 * recover), 0, 0),
			Neck = CFrame.Angles(math.rad(-8 * recover), 0, 0),
			RightShoulder = CFrame.Angles(math.rad(-15 * recover), 0, math.rad(25 * recover)),
			LeftShoulder = CFrame.Angles(math.rad(-15 * recover), 0, math.rad(-25 * recover)),
			RightHip = CFrame.Angles(math.rad(18 * recover), 0, 0),
			LeftHip = CFrame.Angles(math.rad(18 * recover), 0, 0),
		}
	end
end

function PlayerActionPoseConfigs.GetCurveWhiffPose(progress: number): R6JointPoseOffsets
	local p = math.clamp(progress, 0, 1)
	local twist = math.sin(p * math.pi)

	return {
		RootJoint = CFrame.Angles(math.rad(16 * twist), math.rad(-42 * twist), math.rad(-30 * twist)),
		Neck = CFrame.Angles(math.rad(-12 * twist), math.rad(22 * twist), 0),
		RightShoulder = CFrame.Angles(math.rad(-52 * twist), 0, math.rad(48 * twist)),
		LeftShoulder = CFrame.Angles(math.rad(62 * twist), 0, math.rad(-52 * twist)),
		RightHip = CFrame.Angles(math.rad(92 * twist), math.rad(-48 * twist), math.rad(35 * twist)),
		LeftHip = CFrame.Angles(math.rad(-25 * twist), math.rad(15 * twist), 0),
	}
end

function PlayerActionPoseConfigs.GetAirborneRecoveryPose(progress: number): R6JointPoseOffsets
	local p = math.clamp(progress, 0, 1)
	local rise = math.sin(p * math.pi * 0.5)
	local yOffset = -0.90 + (0.50 * rise)

	return {
		RootJoint = CFrame.new(0, yOffset, 0) * CFrame.Angles(math.rad(-55 * (1 - rise) + 15 * rise), 0, 0),
		Neck = CFrame.Angles(math.rad(25 * (1 - rise)), 0, 0),
		RightShoulder = CFrame.Angles(math.rad(25 * (1 - rise)), 0, math.rad(45 * (1 - rise))),
		LeftShoulder = CFrame.Angles(math.rad(25 * (1 - rise)), 0, math.rad(-45 * (1 - rise))),
		RightHip = CFrame.Angles(math.rad(45 * (1 - rise) + 15 * rise), 0, 0),
		LeftHip = CFrame.Angles(math.rad(45 * (1 - rise) + 15 * rise), 0, 0),
	}
end

-- ============================================================================
-- 9b. Sagittal Mirroring (F-29: Left-Foot Execution)
-- ============================================================================
function PlayerActionPoseConfigs.MirrorPoseSagittal(pose: R6JointPoseOffsets): R6JointPoseOffsets
	local function mirrorCF(cf: CFrame): CFrame
		local pos = cf.Position
		local rx, ry, rz = cf:ToEulerAnglesXYZ()
		return CFrame.new(-pos.X, pos.Y, pos.Z) * CFrame.Angles(rx, -ry, -rz)
	end
	return {
		RootJoint     = mirrorCF(pose.RootJoint),
		Neck          = mirrorCF(pose.Neck),
		RightShoulder = mirrorCF(pose.LeftShoulder),
		LeftShoulder  = mirrorCF(pose.RightShoulder),
		RightHip      = mirrorCF(pose.LeftHip),
		LeftHip       = mirrorCF(pose.RightHip),
	}
end

-- ============================================================================
-- 10. Curve Shot Resolver (from SandboxConfig.luau:344-420)
-- ============================================================================
function PlayerActionPoseConfigs.ResolveCurveShot(
	hrpCFrame: CFrame,
	aimDir: Vector3,
	ballPos: Vector3?,
	sideIntent: ("Left" | "Right" | "Neutral")?
): ResolvedCurveShot
	local charForward = Vector3.new(hrpCFrame.LookVector.X, 0, hrpCFrame.LookVector.Z)
	charForward = if charForward.Magnitude < 0.01 then Vector3.new(0, 0, -1) else charForward.Unit
	local charRight = Vector3.new(hrpCFrame.RightVector.X, 0, hrpCFrame.RightVector.Z)
	charRight = if charRight.Magnitude < 0.01 then Vector3.new(1, 0, 0) else charRight.Unit

	local aimHoriz = Vector3.new(aimDir.X, 0, aimDir.Z)
	aimHoriz = if aimHoriz.Magnitude < 0.01 then charForward else aimHoriz.Unit

	local dotRight = aimHoriz:Dot(charRight)
	local dotForward = aimHoriz:Dot(charForward)
	local angleDeg = math.deg(math.atan2(dotRight, dotForward))

	local localBallX = 0.5
	if ballPos then
		local relBall = hrpCFrame:PointToObjectSpace(ballPos)
		localBallX = relBall.X
	end
	local ballSide: "Right" | "Left" = if localBallX >= 0 then "Right" else "Left"

	-- Owner Delta §12.3: Side intent determines style directly regardless of ballSide or aim angle.
	-- A / left = Finesse; D / right = Trivela; Neutral / neither = Finesse.
	local style: "Finesse" | "Trivela" = "Finesse"
	if sideIntent == "Right" then
		style = "Trivela"
	elseif sideIntent == "Left" then
		style = "Finesse"
	else
		-- Neutral (A+D pressed or neither): default to Finesse
		style = "Finesse"
	end

	-- Owner Delta §18: Plan02 character is right-foot dominant.
	-- A / left = Finesse inside of RIGHT foot; D / right = Trivela outside of RIGHT foot; Neutral = Finesse inside of RIGHT foot.
	-- Ball position (left/center/right) does NOT change dominant foot or style, and does not mirror the right-foot pose.
	-- ballSide is retained purely as useful contact metadata.
	local foot: "Right" | "Left" = "Right"

	local speed = if style == "Finesse" then Constants.SHOOT_FINESSE_SPEED else Constants.SHOOT_TRIVELA_SPEED
	local upwardBias = if style == "Finesse" then 0.20 else 0.18
	local spinY = if style == "Finesse" then Constants.SHOOT_FINESSE_SPIN_Y else Constants.SHOOT_TRIVELA_SPIN_Y
	local magnus = if style == "Finesse" then 1.95 else 2.05

	return {
		style = style,
		foot = foot,
		ballSide = ballSide,
		angleDeg = angleDeg,
		localBallX = localBallX,
		speed = speed,
		upwardBias = upwardBias,
		spinY = spinY,
		topSpin = 6,
		magnusFactor = magnus,
		color = if style == "Finesse" then Color3.fromRGB(40, 255, 130) else Color3.fromRGB(205, 75, 255),
		label = if style == "Finesse" then "ปั่นโค้งเข้า (Finesse)" else "ไซด์ก้อยโค้งออก (Trivela)",
		shortButtonLabel = if style == "Finesse" then "FINESSE" else "TRIVELA",
		animType = if style == "Finesse" then "ShootFinesse" else "ShootTrivela",
	}
end

-- ============================================================================
-- 11. Keyframe Sampling Helpers
-- ============================================================================
function PlayerActionPoseConfigs.SampleAuthoredKeyframe(
	animId: string,
	phase: number,
	variant: string?
): { [string]: JointPoseSpec }
	local anim = PlayerActionPoseConfigs.ANIMATIONS[animId]
	if not anim then
		return {}
	end
	local keyframes = anim.keyframes
	if variant and anim.variants and anim.variants[variant] then
		keyframes = anim.variants[variant].keyframes
	end
	local count = #keyframes
	if count == 0 then
		return {}
	end
	if count == 1 then
		return keyframes[1].joints
	end

	local clampedT = math.clamp(phase, 0, 1)
	local k0 = keyframes[1]
	local k1 = keyframes[count]
	local alpha = 0.0

	for i = 1, count - 1 do
		local a = keyframes[i]
		local b = keyframes[i + 1]
		if clampedT >= a.t and clampedT <= b.t then
			k0 = a
			k1 = b
			local span = b.t - a.t
			if span > 1e-6 then
				alpha = (clampedT - a.t) / span
			else
				alpha = 0.0
			end
			break
		end
	end

	local result: { [string]: JointPoseSpec } = {}
	for jointName, spec0 in pairs(k0.joints) do
		local spec1 = k1.joints[jointName]
		if spec1 then
			result[jointName] = {
				pos = spec0.pos:Lerp(spec1.pos, alpha),
				rotDeg = spec0.rotDeg:Lerp(spec1.rotDeg, alpha),
			}
		else
			result[jointName] = spec0
		end
	end
	return result
end

function PlayerActionPoseConfigs.SampleAuthoredPose(
	animId: string,
	phase: number,
	variant: string?
): R6JointPoseOffsets
	local sampled = PlayerActionPoseConfigs.SampleAuthoredKeyframe(animId, phase, variant)
	local function toCF(name: string): CFrame
		local spec = sampled[name]
		if not spec then
			return CFrame.identity
		end
		return CFrame.new(spec.pos) * CFrame.Angles(
			math.rad(spec.rotDeg.X),
			math.rad(spec.rotDeg.Y),
			math.rad(spec.rotDeg.Z)
		)
	end

	local rawPose: R6JointPoseOffsets = {
		RootJoint     = toCF("RootJoint"),
		Neck          = toCF("Neck"),
		RightShoulder = toCF("Right Shoulder"),
		LeftShoulder  = toCF("Left Shoulder"),
		RightHip      = toCF("Right Hip"),
		LeftHip       = toCF("Left Hip"),
	}

	return PlayerActionPoseConfigs.ApplyClearanceOffset(rawPose)
end

function PlayerActionPoseConfigs.SampleAuthoredTransforms(
	animId: string,
	phase: number,
	variant: string?,
	baseC0Map: { [string]: CFrame }?
): { [string]: CFrame }
	local sampled = PlayerActionPoseConfigs.SampleAuthoredKeyframe(animId, phase, variant)
	local result: { [string]: CFrame } = {}

	for jointName, spec in pairs(sampled) do
		local rest = PlayerActionPoseConfigs.REST_FRAMES[jointName]
		local baseC0 = if baseC0Map and baseC0Map[jointName] then baseC0Map[jointName] else (if rest then rest.C0 else CFrame.identity)
		local pivot = if rest then rest.pivot else Vector3.zero
		result[jointName] = PlayerActionPoseConfigs.BuildMotorOffset(baseC0, pivot, spec.pos, spec.rotDeg)
	end

	return result
end

-- ============================================================================
-- 12. Complete Authored Animation Dataset (A01 - A18 with Visual Variants & Fixes)
-- ============================================================================
PlayerActionPoseConfigs.ANIMATIONS = table.freeze({

    ["A01"] = {
        id = "A01",
        name = "Idle / Ready",
        mode = "Loop",
        duration = 1.60,
        blendIn = 0.15,
        blendOut = 0.12,
        holdPhase = nil,
        contactPhase = nil,
        referenceSpeed = 0.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Neutral Athletic Ready (Start)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                },
            },
            {
                kf = 2,
                t = 0.25,
                timeSec = 0.400,
                label = "Inhale & Slight Right Weight Shift",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.040, 0.159, -0.020), rotDeg = Vector3.new(-7.0, -2.0, -1.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(7.0, 2.0, 1.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(13.0, -8.0, 14.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(11.0, 8.0, -13.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-4.0, -4.0, 5.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, -3.0) },
                },
            },
            {
                kf = 3,
                t = 0.50,
                timeSec = 0.800,
                label = "Center Settle & Low Ready Micro-Dip",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.137, 0.000), rotDeg = Vector3.new(-10.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, -5.0, 11.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 5.0, -11.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-7.0, -5.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(7.0, 5.0, -4.0) },
                },
            },
            {
                kf = 4,
                t = 0.75,
                timeSec = 1.200,
                label = "Slight Left Weight Shift & Counter-Arm",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.040, 0.128, 0.020), rotDeg = Vector3.new(-7.5, -5.0, 1.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(7.5, 5.0, -1.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(9.0, -6.0, 13.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, 6.0, -14.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, -5.0, 3.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(5.0, 5.0, -5.0) },
                },
            },
            {
                kf = 5,
                t = 1.00,
                timeSec = 1.600,
                label = "Neutral Athletic Ready (Loop Closure)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                },
            },
        },
    },
    ["A02"] = {
        id = "A02",
        name = "Walk (Forward & Backward)",
        mode = "Loop",
        duration = 0.48,
        blendIn = 0.12,
        blendOut = 0.12,
        holdPhase = nil,
        contactPhase = nil,
        referenceSpeed = 20.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Right Foot Strike / Double Support",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.041, 0.000), rotDeg = Vector3.new(-10.0, 8.0, 1.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -8.0, -1.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-30.0, 0.0, 8.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(34.0, 0.0, -8.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(36.0, 0.0, 2.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-34.0, 0.0, -2.0) },
                },
            },
            {
                kf = 2,
                t = 0.25,
                timeSec = 0.120,
                label = "Right Mid-Stance / Left Passing",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.030, 0.125, 0.000), rotDeg = Vector3.new(-10.0, 0.0, -2.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 0.0, 2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(4.0, 0.0, 10.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-4.0, 0.0, -10.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(2.0, 0.0, 2.5) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 0.0, -6.0) },
                },
            },
            {
                kf = 3,
                t = 0.50,
                timeSec = 0.240,
                label = "Left Foot Strike / Opposite Contact",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.041, 0.000), rotDeg = Vector3.new(-10.0, -8.0, -1.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 8.0, 1.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(34.0, 0.0, 8.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-30.0, 0.0, -8.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-34.0, 0.0, 2.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(36.0, 0.0, -2.0) },
                },
            },
            {
                kf = 4,
                t = 0.75,
                timeSec = 0.360,
                label = "Left Mid-Stance / Right Passing",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.030, 0.125, 0.000), rotDeg = Vector3.new(-10.0, 0.0, 2.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 0.0, -2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-4.0, 0.0, 10.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(4.0, 0.0, -10.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 0.0, 6.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(2.0, 0.0, -2.5) },
                },
            },
            {
                kf = 5,
                t = 1.00,
                timeSec = 0.480,
                label = "Right Foot Strike (Loop Closure)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.041, 0.000), rotDeg = Vector3.new(-10.0, 8.0, 1.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -8.0, -1.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-30.0, 0.0, 8.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(34.0, 0.0, -8.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(36.0, 0.0, 2.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-34.0, 0.0, -2.0) },
                },
            },
        },
    },
    ["A03"] = {
        id = "A03",
        name = "Sprint",
        mode = "Loop",
        duration = 0.38,
        blendIn = 0.10,
        blendOut = 0.12,
        holdPhase = nil,
        contactPhase = nil,
        referenceSpeed = 32.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Right Drive Contact & Forward Lean",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.056, 0.000), rotDeg = Vector3.new(-24.0, 14.0, 2.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, -12.0, -2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-56.0, 0.0, 14.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(64.0, 8.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(56.0, 0.0, 3.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-52.0, 0.0, -3.0) },
                },
            },
            {
                kf = 2,
                t = 0.25,
                timeSec = 0.095,
                label = "Right Push-Off / Airborne Float Phase",
                hrpRefY = 3.00,
                obbMinY = 0.220,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.040, 0.226, -0.050), rotDeg = Vector3.new(-26.0, 0.0, -3.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, 0.0, 2.5) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 0.0, 16.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 0.0, -16.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 0.0, 3.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 0.0, -7.0) },
                },
            },
            {
                kf = 3,
                t = 0.50,
                timeSec = 0.190,
                label = "Left Drive Contact & Counter-Torque",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.056, 0.000), rotDeg = Vector3.new(-24.0, -14.0, -2.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, 12.0, 2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(64.0, -8.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-56.0, 0.0, -14.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-52.0, 0.0, 3.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(56.0, 0.0, -3.0) },
                },
            },
            {
                kf = 4,
                t = 0.75,
                timeSec = 0.285,
                label = "Left Push-Off / Airborne Float Phase",
                hrpRefY = 3.00,
                obbMinY = 0.220,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.040, 0.226, -0.050), rotDeg = Vector3.new(-26.0, 0.0, 3.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, 0.0, -2.5) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 0.0, 16.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 0.0, -16.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 0.0, 7.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 0.0, -3.0) },
                },
            },
            {
                kf = 5,
                t = 1.00,
                timeSec = 0.380,
                label = "Right Drive Contact (Loop Closure)",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.056, 0.000), rotDeg = Vector3.new(-24.0, 14.0, 2.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, -12.0, -2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-56.0, 0.0, 14.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(64.0, 8.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(56.0, 0.0, 3.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-52.0, 0.0, -3.0) },
                },
            },
        },
    },
    ["A04"] = {
        id = "A04",
        name = "Dash Burst",
        mode = "OneShot",
        duration = 0.22,
        blendIn = 0.03,
        blendOut = 0.06,
        holdPhase = nil,
        contactPhase = nil,
        referenceSpeed = 42.0,
        nextAnimOnComplete = "A03",
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Entry Coil & Rear Foot Load",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.071, 0.180), rotDeg = Vector3.new(-18.0, -10.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, 10.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-38.0, 0.0, 14.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(36.0, 0.0, -14.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 0.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-32.0, 0.0, -4.0) },
                },
            },
            {
                kf = 2,
                t = 0.27,
                timeSec = 0.060,
                label = "Explosive Push-Off & Chest Drop",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.103, 0.040), rotDeg = Vector3.new(-34.0, 12.0, 3.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, -12.0, -2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-68.0, 0.0, 18.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(74.0, 10.0, -14.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(64.0, 0.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-58.0, 0.0, -4.0) },
                },
            },
            {
                kf = 3,
                t = 0.68,
                timeSec = 0.150,
                label = "Peak Horizontal Surge (Visual Offset -Z)",
                hrpRefY = 3.00,
                obbMinY = 0.120,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.093, -0.180), rotDeg = Vector3.new(-30.0, 8.0, 2.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(24.0, -8.0, -1.5) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-42.0, 0.0, 15.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(56.0, 6.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(48.0, 0.0, 3.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-44.0, 0.0, -3.0) },
                },
            },
            {
                kf = 4,
                t = 1.00,
                timeSec = 0.220,
                label = "Exit Catch -> Seamless Hand-off to Sprint",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.056, 0.000), rotDeg = Vector3.new(-24.0, -14.0, -2.5) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, 12.0, 2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(64.0, -8.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-56.0, 0.0, -14.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-52.0, 0.0, 3.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(56.0, 0.0, -3.0) },
                },
            },
        },
    },
    ["A05"] = {
        id = "A05",
        name = "Shift Lock 8-Way Strafe",
        mode = "Loop",
        duration = 0.44,
        blendIn = 0.08,
        blendOut = 0.10,
        holdPhase = nil,
        contactPhase = nil,
        referenceSpeed = 20.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Wide Lateral Push-Off (Strafe Right Contact)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.352, 0.000), rotDeg = Vector3.new(-10.0, -8.0, -8.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 8.0, 6.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, -8.0, 26.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-14.0, 8.0, -22.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, -8.0, 28.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 6.0, -24.0) },
                },
            },
            {
                kf = 2,
                t = 0.25,
                timeSec = 0.110,
                label = "Low Shuffle Glide / Mid-Gather",
                hrpRefY = 3.00,
                obbMinY = 0.040,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.050, 0.304, 0.000), rotDeg = Vector3.new(-11.0, -6.0, -10.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(11.0, 6.0, 8.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, -6.0, 18.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 6.0, -18.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(4.0, -6.0, 14.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 4.0, 6.0) },
                },
            },
            {
                kf = 3,
                t = 0.50,
                timeSec = 0.220,
                label = "Left Plant & Right Lead Reach",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.030, 0.347, 0.000), rotDeg = Vector3.new(-10.0, -10.0, -6.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 10.0, 5.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-14.0, -8.0, 22.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, 8.0, -26.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -10.0, 32.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 6.0, -12.0) },
                },
            },
            {
                kf = 4,
                t = 0.75,
                timeSec = 0.330,
                label = "Right Plant & Left Push Recovery",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.020, 0.250, 0.000), rotDeg = Vector3.new(-11.0, -8.0, -7.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(11.0, 8.0, 6.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -8.0, 20.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, 8.0, -20.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 16.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-4.0, 6.0, -18.0) },
                },
            },
            {
                kf = 5,
                t = 1.00,
                timeSec = 0.440,
                label = "Wide Lateral Push-Off (Loop Closure)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.352, 0.000), rotDeg = Vector3.new(-10.0, -8.0, -8.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 8.0, 6.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, -8.0, 26.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-14.0, 8.0, -22.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, -8.0, 28.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 6.0, -24.0) },
                },
            },
        },
        eightWayTable = {
            { dir = "F (0°)", moveVec = Vector3.new(0.00, 0.00, -1.00), torsoRx = -10.0, torsoRy = 0.0, torsoRz = 0.0, neckRy = 0.0, hipRxAmp = 36.0, hipRzAmp = 2.0 },
            { dir = "FR (+45°)", moveVec = Vector3.new(0.71, 0.00, -0.71), torsoRx = -9.0, torsoRy = -24.0, torsoRz = -6.0, neckRy = 20.0, hipRxAmp = 28.0, hipRzAmp = 18.0 },
            { dir = "R (+90°)", moveVec = Vector3.new(1.00, 0.00, 0.00), torsoRx = -10.0, torsoRy = -8.0, torsoRz = -8.0, neckRy = 8.0, hipRxAmp = 8.0, hipRzAmp = 28.0 },
            { dir = "BR (+135°)", moveVec = Vector3.new(0.71, 0.00, 0.71), torsoRx = -5.0, torsoRy = 24.0, torsoRz = -6.0, neckRy = -20.0, hipRxAmp = -26.0, hipRzAmp = 18.0 },
            { dir = "B (180°)", moveVec = Vector3.new(0.00, 0.00, 1.00), torsoRx = -4.0, torsoRy = 0.0, torsoRz = 0.0, neckRy = 0.0, hipRxAmp = -32.0, hipRzAmp = 3.0 },
            { dir = "BL (-135°)", moveVec = Vector3.new(-0.71, 0.00, 0.71), torsoRx = -5.0, torsoRy = -24.0, torsoRz = 6.0, neckRy = 20.0, hipRxAmp = -26.0, hipRzAmp = -18.0 },
            { dir = "L (-90°)", moveVec = Vector3.new(-1.00, 0.00, 0.00), torsoRx = -10.0, torsoRy = 8.0, torsoRz = 8.0, neckRy = -8.0, hipRxAmp = 8.0, hipRzAmp = -28.0 },
            { dir = "FL (-45°)", moveVec = Vector3.new(-0.71, 0.00, -0.71), torsoRx = -9.0, torsoRy = 24.0, torsoRz = 6.0, neckRy = -20.0, hipRxAmp = 28.0, hipRzAmp = -18.0 },
        },
    },
    ["A06"] = {
        id = "A06",
        name = "Directional Jump / Fall",
        mode = "StateAirborne",
        duration = 0.72,
        blendIn = 0.04,
        blendOut = 0.04,
        holdPhase = nil,
        contactPhase = nil,
        referenceSpeed = 20.0,
        nextAnimOnComplete = "A07",
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Takeoff Coil & Directional Impulse Lock",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.095, 0.000), rotDeg = Vector3.new(-18.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-36.0, 0.0, 14.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-36.0, 0.0, -14.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, -6.0, 6.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-24.0, 6.0, -6.0) },
                },
            },
            {
                kf = 2,
                t = 0.25,
                timeSec = 0.180,
                label = "Ascent Drive (Rising Velocity vy > 0)",
                hrpRefY = 4.10,
                obbMinY = 0.800,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.299, 0.000), rotDeg = Vector3.new(-6.0, -8.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 8.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(110.0, 0.0, 18.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(95.0, 0.0, -18.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(42.0, 0.0, 5.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, 0.0, -5.0) },
                },
            },
            {
                kf = 3,
                t = 0.50,
                timeSec = 0.360,
                label = "Dynamic Apex Transition (vy ≈ 0)",
                hrpRefY = 4.80,
                obbMinY = 1.500,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.142, 0.000), rotDeg = Vector3.new(8.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(4.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(68.0, 0.0, 34.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(68.0, 0.0, -34.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, -6.0, 8.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-14.0, 6.0, -8.0) },
                },
            },
            {
                kf = 4,
                t = 0.78,
                timeSec = 0.560,
                label = "Descent Counter-Balance (vy < 0)",
                hrpRefY = 4.00,
                obbMinY = 0.700,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.151, 0.000), rotDeg = Vector3.new(-8.0, 4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-10.0, -4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 0.0, 42.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 0.0, -42.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-12.0, -4.0, 6.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, 4.0, -6.0) },
                },
            },
            {
                kf = 5,
                t = 1.00,
                timeSec = 0.720,
                label = "Pre-Landing Reach (Hands off to A07)",
                hrpRefY = 3.15,
                obbMinY = 0.100,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.055, 0.000), rotDeg = Vector3.new(-12.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 0.0, 24.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 0.0, -24.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, -5.0, 6.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 5.0, -6.0) },
                },
            },
        },
    },
    ["A07"] = {
        id = "A07",
        name = "Landing Cushion",
        mode = "OneShot",
        duration = 0.24,
        blendIn = 0.03,
        blendOut = 0.08,
        holdPhase = nil,
        contactPhase = nil,
        referenceSpeed = 0.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Touchdown Contact (From A06 Descent)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.115, 0.000), rotDeg = Vector3.new(-12.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 0.0, 24.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 0.0, -24.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, -5.0, 6.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 5.0, -6.0) },
                },
            },
            {
                kf = 2,
                t = 0.33,
                timeSec = 0.080,
                label = "Peak Impact Absorption (Split-Leg R6 Cushion)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.109, 0.000), rotDeg = Vector3.new(-24.0, -6.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, 6.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, -8.0, 28.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-18.0, 8.0, -26.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, -8.0, 10.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(30.0, 8.0, -10.0) },
                },
            },
            {
                kf = 3,
                t = 0.67,
                timeSec = 0.160,
                label = "Elastic Rebound & Hip Gather",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.111, 0.000), rotDeg = Vector3.new(-14.0, -4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, -6.0, 16.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 6.0, -16.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-12.0, -6.0, 6.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -6.0) },
                },
            },
            {
                kf = 4,
                t = 1.00,
                timeSec = 0.240,
                label = "Ready / Locomotion Recovery",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                },
            },
        },
    },
    ["A08"] = {
        id = "A08",
        name = "Header",
        mode = "OneShot",
        duration = 0.48,
        blendIn = 0.06,
        blendOut = 0.10,
        holdPhase = nil,
        contactPhase = 0.45,
        referenceSpeed = 16.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Torso Arch & Chest Expansion Coil",
                hrpRefY = 3.45,
                obbMinY = 0.400,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.019, 0.120), rotDeg = Vector3.new(22.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, 0.0, 32.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, 0.0, -32.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-24.0, -5.0, 5.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-18.0, 5.0, -5.0) },
                },
            },
            {
                kf = 2,
                t = 0.45,
                timeSec = 0.216,
                label = "Forehead Strike Contact (Kinetic Whip)",
                hrpRefY = 3.60,
                obbMinY = 0.500,
                contact = {
                    part = "Head",
                    localPoint = Vector3.new(0.000, 0.500, -0.500),
                    worldPoint = Vector3.new(0.000, 5.095, -1.415),
                    ballCenter = Vector3.new(0.000, 5.047, -2.664),
                    surfaceDist = 1.250,
                },
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.061, -0.140), rotDeg = Vector3.new(-20.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-10.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-42.0, 0.0, 22.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-42.0, 0.0, -22.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(26.0, -4.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 4.0, -4.0) },
                },
            },
            {
                kf = 3,
                t = 0.72,
                timeSec = 0.346,
                label = "Full Torso Follow-Through & Pike",
                hrpRefY = 3.30,
                obbMinY = 0.250,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.018, -0.180), rotDeg = Vector3.new(-28.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-14.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-48.0, 0.0, 18.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-48.0, 0.0, -18.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(32.0, -5.0, 5.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 5.0, -5.0) },
                },
            },
            {
                kf = 4,
                t = 1.00,
                timeSec = 0.480,
                label = "Balance Recovery & Landing Prep",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.136, 0.000), rotDeg = Vector3.new(-10.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 0.0, 16.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 0.0, -16.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-12.0, -4.0, 5.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 4.0, -5.0) },
                },
            },
        },
    },
    ["A09"] = {
        id = "A09",
        name = "Aerial Block",
        mode = "OneShot",
        duration = 0.52,
        blendIn = 0.05,
        blendOut = 0.10,
        holdPhase = nil,
        contactPhase = 0.42,
        referenceSpeed = 12.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Intercept Rise & Arms Pin Behind Back",
                hrpRefY = 3.50,
                obbMinY = 0.450,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.132, 0.000), rotDeg = Vector3.new(6.0, 18.0, -6.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, -14.0, 4.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-34.0, 20.0, 6.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-34.0, -20.0, -6.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, -8.0, 14.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, 8.0, -12.0) },
                },
            },
            {
                kf = 2,
                t = 0.42,
                timeSec = 0.218,
                label = "Broad Chest / Upper-Torso Wall Contact",
                hrpRefY = 3.75,
                obbMinY = 0.700,
                contact = {
                    part = "Torso",
                    localPoint = Vector3.new(0.062, 0.255, -0.500),
                    worldPoint = Vector3.new(-0.098, 4.235, -0.438),
                    ballCenter = Vector3.new(-0.566, 4.476, -1.572),
                    surfaceDist = 1.250,
                },
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.142, 0.000), rotDeg = Vector3.new(12.0, 22.0, -8.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, -18.0, 6.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-42.0, 24.0, 4.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-42.0, -24.0, -4.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, -10.0, 18.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-22.0, 10.0, -14.0) },
                },
            },
            {
                kf = 3,
                t = 0.72,
                timeSec = 0.374,
                label = "Impact Absorption Recoil in Air",
                hrpRefY = 3.40,
                obbMinY = 0.350,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.121, 0.100), rotDeg = Vector3.new(18.0, 26.0, -10.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-12.0, -20.0, 8.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-24.0, 14.0, 18.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-24.0, -14.0, -18.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, -6.0, 12.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-26.0, 6.0, -12.0) },
                },
            },
            {
                kf = 4,
                t = 1.00,
                timeSec = 0.520,
                label = "Re-Center & Touchdown Preparation",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.153, 0.000), rotDeg = Vector3.new(-10.0, 6.0, -2.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, -6.0, 2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 0.0, 20.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 0.0, -20.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-14.0, -5.0, 6.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, 5.0, -6.0) },
                },
            },
        },
    },
    ["A10"] = {
        id = "A10",
        name = "Mid-Air Volley",
        mode = "OneShot",
        duration = 0.56,
        blendIn = 0.05,
        blendOut = 0.10,
        holdPhase = nil,
        contactPhase = 0.46,
        referenceSpeed = 14.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Airborne Side-Tilt & Kicking Leg Chamber",
                hrpRefY = 3.55,
                obbMinY = 0.500,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.087, 0.000), rotDeg = Vector3.new(12.0, -28.0, 22.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, 24.0, -14.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-38.0, -12.0, 36.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(42.0, 12.0, -48.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-48.0, -18.0, 28.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 10.0, -16.0) },
                },
            },
            {
                kf = 2,
                t = 0.25,
                timeSec = 0.140,
                label = "Hip Whip Initiation & Scissor Fold",
                hrpRefY = 3.75,
                obbMinY = 0.750,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.308, 0.000), rotDeg = Vector3.new(18.0, -6.0, 28.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 6.0, -18.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-24.0, 0.0, 42.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(54.0, 0.0, -56.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -14.0, 26.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 8.0, -20.0) },
                },
            },
            {
                kf = 3,
                t = 0.46,
                timeSec = 0.258,
                label = "Mid-Air Side-Volley Strike [Contact]",
                hrpRefY = 3.80,
                obbMinY = 0.850,
                contact = {
                    part = "Right Leg",
                    localPoint = Vector3.new(-0.500, -1.000, 0.208),
                    worldPoint = Vector3.new(0.608, 3.850, -2.881),
                    ballCenter = Vector3.new(0.449, 3.920, -4.119),
                    surfaceDist = 1.250,
                },
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.351, -0.060), rotDeg = Vector3.new(24.0, 26.0, 32.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-12.0, -22.0, -20.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-44.0, 12.0, 34.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(36.0, -14.0, -52.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(64.0, -16.0, 18.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-36.0, 12.0, -22.0) },
                },
            },
            {
                kf = 4,
                t = 0.72,
                timeSec = 0.403,
                label = "High Across-Body Follow-Through",
                hrpRefY = 3.45,
                obbMinY = 0.450,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.323, -0.040), rotDeg = Vector3.new(18.0, 42.0, 24.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-10.0, -34.0, -14.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-52.0, 18.0, 28.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, -18.0, -40.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(78.0, -10.0, -8.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, 8.0, -16.0) },
                },
            },
            {
                kf = 5,
                t = 1.00,
                timeSec = 0.560,
                label = "Upright Re-Alignment & Landing Catch",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.158, 0.000), rotDeg = Vector3.new(-10.0, 8.0, 4.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, -8.0, -4.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 0.0, 20.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, 0.0, -20.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, -4.0, 6.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, 4.0, -8.0) },
                },
            },
        },
    },
    ["A11"] = {
        id = "A11",
        name = "Bicycle Kick",
        mode = "OneShot",
        duration = 0.88,
        blendIn = 0.06,
        blendOut = 0.12,
        holdPhase = nil,
        contactPhase = 0.48,
        referenceSpeed = 6.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Back-Lean Launch & Left Knee/Leg Pump",
                hrpRefY = 3.20,
                obbMinY = 0.250,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.012, 0.000), rotDeg = Vector3.new(-36.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-35.0, 0.0, 20.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-35.0, 0.0, -20.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 0.0, 5.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-48.0, 0.0, -5.0) },
                },
            },
            {
                kf = 2,
                t = 0.24,
                timeSec = 0.211,
                label = "Inversion Pitch & Scissor Cocking",
                hrpRefY = 3.85,
                obbMinY = 1.400,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -1.280, -0.100), rotDeg = Vector3.new(-108.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(24.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, 0.0, 38.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, 0.0, -38.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-36.0, 0.0, 6.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(62.0, 0.0, -6.0) },
                },
            },
            {
                kf = 3,
                t = 0.48,
                timeSec = 0.422,
                label = "Inverted Overhead Strike [Ball Contact]",
                hrpRefY = 4.15,
                obbMinY = 1.800,
                contact = {
                    part = "Right Leg",
                    localPoint = Vector3.new(-0.067, -1.000, 0.500),
                    worldPoint = Vector3.new(0.574, 6.050, -1.214),
                    ballCenter = Vector3.new(0.613, 5.929, -2.457),
                    surfaceDist = 1.250,
                },
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.459, -0.150), rotDeg = Vector3.new(-154.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-20.0, 0.0, 44.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-20.0, 0.0, -44.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-58.0, 0.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(46.0, 0.0, -4.0) },
                },
            },
            {
                kf = 4,
                t = 0.68,
                timeSec = 0.598,
                label = "Overhead Follow-Through & Arm Reach Down",
                hrpRefY = 3.55,
                obbMinY = 1.100,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -1.071, -0.200), rotDeg = Vector3.new(-128.0, -8.0, 6.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(30.0, 6.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(62.0, 0.0, 26.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(62.0, 0.0, -26.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-76.0, 0.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(24.0, 0.0, -6.0) },
                },
            },
            {
                kf = 5,
                t = 0.84,
                timeSec = 0.739,
                label = "Horizontal Back/Arm Cushion Breakfall",
                hrpRefY = 3.00,
                obbMinY = 0.020,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -1.702, -0.150), rotDeg = Vector3.new(-82.0, -12.0, 4.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 8.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 0.0, 24.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 0.0, -24.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-24.0, 0.0, 6.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-10.0, 0.0, -6.0) },
                },
            },
            {
                kf = 6,
                t = 0.92,
                timeSec = 0.810,
                label = "Kip-Up Transitional Rise (Clearance Guard)",
                hrpRefY = 3.00,
                obbMinY = 0.020,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.350, -0.050), rotDeg = Vector3.new(-25.0, -4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(15.0, 0.0, 25.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(15.0, 0.0, -25.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, 2.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-12.0, -2.0, -4.0) },
                },
            },
            {
                kf = 7,
                t = 1.00,
                timeSec = 0.880,
                label = "Snap-Up Recovery to Athletic Ready",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.152, 0.000), rotDeg = Vector3.new(-6.0, 0.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 0.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, -6.0, 14.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 6.0, -14.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, -5.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 5.0, -4.0) },
                },
            },
        },
    },
    ["A12"] = {
        id = "A12",
        name = "Direct Shoot Wind-up / Hold",
        mode = "Hold",
        duration = 0.34,
        blendIn = 0.06,
        blendOut = 0.08,
        holdPhase = 0.50,
        contactPhase = nil,
        referenceSpeed = 0.0,
        nextAnimOnRelease = "A13",
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Enter: Plant Foot Step & Shoulder Turn",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.081, 0.000), rotDeg = Vector3.new(-8.0, -8.0, 2.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 8.0, -2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, 0.0, 16.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(24.0, 8.0, -20.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-22.0, -4.0, 5.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 4.0, -4.0) },
                },
            },
            {
                kf = 2,
                t = 0.35,
                timeSec = 0.126,
                label = "Enter: Deep Backswing Loading",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.040, 0.126, 0.040), rotDeg = Vector3.new(-12.0, -14.0, 5.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 14.0, -4.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-34.0, -6.0, 22.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(42.0, 12.0, -28.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-48.0, -6.0, 7.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 5.0, -5.0) },
                },
            },
            {
                kf = 3,
                t = 0.50,
                timeSec = 0.180,
                label = "HOLD LOCK: Coiled Power Stance (Frozen Pose)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.060, 0.149, 0.060), rotDeg = Vector3.new(-14.0, -18.0, 6.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 18.0, -5.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-42.0, -8.0, 24.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(50.0, 14.0, -32.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-58.0, -6.0, 8.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, 6.0, -6.0) },
                },
            },
            {
                kf = 4,
                t = 1.00,
                timeSec = 0.340,
                label = "Cancel Branch: Smooth De-escalation to Ready",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                },
            },
        },
    },
    ["A13"] = {
        id = "A13",
        name = "Direct Shoot Follow-Through",
        mode = "OneShot",
        duration = 0.42,
        blendIn = 0.00,
        blendOut = 0.10,
        holdPhase = nil,
        contactPhase = 0.28,
        referenceSpeed = 0.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Release Initiation (Exact Hand-off from A12 Hold)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.060, 0.149, 0.060), rotDeg = Vector3.new(-14.0, -18.0, 6.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 18.0, -5.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-42.0, -8.0, 24.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(50.0, 14.0, -32.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-58.0, -6.0, 8.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, 6.0, -6.0) },
                },
            },
            {
                kf = 2,
                t = 0.28,
                timeSec = 0.118,
                label = "Instep Power Strike [Ball Contact]",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                contact = {
                    part = "Right Leg",
                    localPoint = Vector3.new(0.116, -0.664, -0.500),
                    worldPoint = Vector3.new(0.776, 0.824, -1.007),
                    ballCenter = Vector3.new(0.650, 1.250, -2.176),
                    surfaceDist = 1.250,
                },
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.040, 0.164, 0.000), rotDeg = Vector3.new(-6.0, 4.0, 5.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-10.0, -4.0, -4.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 0.0, 18.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 8.0, -28.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(26.0, 0.0, 3.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 4.0, -5.0) },
                },
            },
            {
                kf = 3,
                t = 0.62,
                timeSec = 0.260,
                label = "High Power Follow-Through & Counter-Twist",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.040, 0.229, -0.040), rotDeg = Vector3.new(10.0, 22.0, 8.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -20.0, -6.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(38.0, 10.0, 14.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-44.0, -8.0, -24.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(68.0, 4.0, -4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-18.0, 4.0, -6.0) },
                },
            },
            {
                kf = 4,
                t = 1.00,
                timeSec = 0.420,
                label = "Step-Down Recovery to Ready",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.137, 0.000), rotDeg = Vector3.new(-8.0, 4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, -4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, -4.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -4.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 4.0, -4.0) },
                },
            },
        },
    },
    ["A14"] = {
        id = "A14",
        name = "Curve Shoot Wind-up / Hold",
        mode = "Hold",
        duration = 0.36,
        blendIn = 0.06,
        blendOut = 0.08,
        holdPhase = 0.50,
        contactPhase = nil,
        referenceSpeed = 0.0,
        nextAnimOnRelease = "A15",
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Enter: Wide Oblique Plant & Hip Open",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.080, 0.245, 0.040), rotDeg = Vector3.new(-6.0, -18.0, -6.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 16.0, 5.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-18.0, -10.0, 24.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 12.0, -28.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-24.0, -16.0, 14.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 10.0, 6.0) },
                },
            },
            {
                kf = 2,
                t = 0.35,
                timeSec = 0.140,
                label = "Enter: Angled Sweeping Chamber",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.120, 0.163, 0.060), rotDeg = Vector3.new(-9.0, -26.0, -8.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 24.0, 6.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-32.0, -14.0, 32.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(46.0, 18.0, -38.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-42.0, -24.0, 20.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, 12.0, 8.0) },
                },
            },
            {
                kf = 3,
                t = 0.50,
                timeSec = 0.200,
                label = "HOLD LOCK: Open-Hip Curve Chamber (Frozen Pose)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.140, 0.169, 0.080), rotDeg = Vector3.new(-10.0, -32.0, -10.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 30.0, 8.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-38.0, -16.0, 36.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(54.0, 20.0, -44.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-52.0, -28.0, 24.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 14.0, 10.0) },
                },
            },
            {
                kf = 4,
                t = 1.00,
                timeSec = 0.360,
                label = "Cancel Branch: Smooth Return to Ready",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                },
            },
        },
    },
    ["A15"] = {
        id = "A15",
        name = "Curve Shoot Follow-Through (Finesse & Trivela Variants)",
        mode = "OneShot",
        duration = 0.44,
        blendIn = 0.00,
        blendOut = 0.10,
        holdPhase = nil,
        contactPhase = 0.30,
        referenceSpeed = 0.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Release from A14 Hold (External Hip Rotation Lock)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.140, 0.169, 0.080), rotDeg = Vector3.new(-10.0, -32.0, -10.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 30.0, 8.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-38.0, -16.0, 36.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(54.0, 20.0, -44.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-52.0, -28.0, 24.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 14.0, 10.0) },
                },
            },
            {
                kf = 2,
                t = 0.30,
                timeSec = 0.132,
                label = "Finesse Inside-Surface Whip Contact [Ball Contact]",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                contact = {
                    part = "Right Leg",
                    localPoint = Vector3.new(-0.500, -0.202, -0.085),
                    worldPoint = Vector3.new(0.842, 1.391, -1.150),
                    ballCenter = Vector3.new(-0.091, 1.250, -1.971),
                    surfaceDist = 1.250,
                },
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.100, 0.277, 0.000), rotDeg = Vector3.new(-4.0, 8.0, 14.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, -8.0, -10.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 0.0, 28.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 12.0, -36.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, -48.0, 16.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, 10.0, -12.0) },
                },
            },
            {
                kf = 3,
                t = 0.65,
                timeSec = 0.286,
                label = "Crescent Wrap Follow-Through Across Body",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.060, 0.321, -0.040), rotDeg = Vector3.new(8.0, 28.0, 16.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -24.0, -12.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(46.0, 16.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-48.0, -14.0, -28.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(62.0, -52.0, -18.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, 8.0, -10.0) },
                },
            },
            {
                kf = 4,
                t = 1.00,
                timeSec = 0.440,
                label = "Balanced Recovery to Ready",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.151, 0.000), rotDeg = Vector3.new(-8.0, 4.0, 2.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, -4.0, -2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, -4.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 4.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, -8.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 6.0, -4.0) },
                },
            },
        },
        variants = {
            ["finesse"] = {
                name = "A15-finesse (Inside-Foot Curl)",
                contactSurfaceDesc = "Medial (inner -X) surface of Right Leg at (-0.50, -0.55, -0.15) via external hip rotation ry = -48°",
                keyframes = {
                    {
                        kf = 1,
                        t = 0.00,
                        timeSec = 0.000,
                        label = "Release from A14 Hold (External Hip Rotation Lock)",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.140, 0.169, 0.080), rotDeg = Vector3.new(-10.0, -32.0, -10.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 30.0, 8.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-38.0, -16.0, 36.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(54.0, 20.0, -44.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-52.0, -28.0, 24.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 14.0, 10.0) },
                        },
                    },
                    {
                        kf = 2,
                        t = 0.30,
                        timeSec = 0.132,
                        label = "Finesse Inside-Surface Whip Contact [Ball Contact]",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        contact = {
                            part = "Right Leg",
                            localPoint = Vector3.new(-0.500, -0.202, -0.085),
                            worldPoint = Vector3.new(0.842, 1.391, -1.150),
                            ballCenter = Vector3.new(-0.091, 1.250, -1.971),
                            surfaceDist = 1.250,
                        },
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.100, 0.277, 0.000), rotDeg = Vector3.new(-4.0, 8.0, 14.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, -8.0, -10.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 0.0, 28.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 12.0, -36.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, -48.0, 16.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, 10.0, -14.0) },
                        },
                    },
                    {
                        kf = 3,
                        t = 0.65,
                        timeSec = 0.286,
                        label = "Crescent Wrap Follow-Through Across Body",
                        hrpRefY = 3.00,
                        obbMinY = 0.015,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.060, 0.321, -0.040), rotDeg = Vector3.new(8.0, 28.0, 16.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -24.0, -12.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(46.0, 16.0, 12.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-48.0, -14.0, -28.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(62.0, -52.0, -18.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, 8.0, -16.0) },
                        },
                    },
                    {
                        kf = 4,
                        t = 1.00,
                        timeSec = 0.440,
                        label = "Balanced Recovery to Ready",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.000, 0.151, 0.000), rotDeg = Vector3.new(-8.0, 4.0, 2.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, -4.0, -2.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, -4.0, 12.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, 4.0, -12.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, -8.0, 4.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 6.0, -4.0) },
                        },
                    },
                },
            },
            ["trivela"] = {
                name = "A15-trivela (Outside-Foot Reverse Curl)",
                contactSurfaceDesc = "Lateral (outer +X) surface of Right Leg at (+0.50, -0.55, -0.15) via internal hip rotation ry = +38°",
                keyframes = {
                    {
                        kf = 1,
                        t = 0.00,
                        timeSec = 0.000,
                        label = "Release from A14 Hold (Internal Hip Twist Prep)",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.140, 0.169, 0.080), rotDeg = Vector3.new(-10.0, -32.0, -10.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 30.0, 8.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-38.0, -16.0, 36.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(54.0, 20.0, -44.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-52.0, -28.0, 24.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 14.0, 10.0) },
                        },
                    },
                    {
                        kf = 2,
                        t = 0.30,
                        timeSec = 0.132,
                        label = "Trivela Outside-Surface Slice Contact [Ball Contact]",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        contact = {
                            part = "Right Leg",
                            localPoint = Vector3.new(0.500, 0.161, -0.500),
                            worldPoint = Vector3.new(0.154, 1.439, -0.331),
                            ballCenter = Vector3.new(1.225, 1.250, -0.946),
                            surfaceDist = 1.250,
                        },
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.120, 0.200, 0.000), rotDeg = Vector3.new(-8.0, -12.0, -14.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, 12.0, 10.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-22.0, -8.0, 32.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(34.0, 14.0, -34.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(26.0, 38.0, -12.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, 12.0, 14.0) },
                        },
                    },
                    {
                        kf = 3,
                        t = 0.65,
                        timeSec = 0.286,
                        label = "OutwardWhip Slice Follow-Through",
                        hrpRefY = 3.00,
                        obbMinY = 0.015,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.100, -0.065, -0.020), rotDeg = Vector3.new(6.0, 8.0, -18.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-4.0, -8.0, 14.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-36.0, -12.0, 42.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, 10.0, -24.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(58.0, 42.0, 26.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-14.0, 10.0, 18.0) },
                        },
                    },
                    {
                        kf = 4,
                        t = 1.00,
                        timeSec = 0.440,
                        label = "Balanced Recovery to Ready",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.000, 0.134, 0.000), rotDeg = Vector3.new(-8.0, -4.0, -2.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 2.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 14.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -14.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 6.0, 6.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, 4.0, -4.0) },
                        },
                    },
                },
            },
        },
    },
    ["A16"] = {
        id = "A16",
        name = "Single 3D Pass (Parametric Ground & Lob Pass)",
        mode = "OneShot",
        duration = 0.36,
        blendIn = 0.05,
        blendOut = 0.08,
        holdPhase = nil,
        contactPhase = 0.32,
        referenceSpeed = 0.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Compact Pass Chamber (Open Hip Push Prep)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.050, 0.123, 0.020), rotDeg = Vector3.new(-8.0, -14.0, 2.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 14.0, -2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-18.0, -6.0, 18.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(26.0, 8.0, -22.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, -36.0, 12.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 6.0, -6.0) },
                },
            },
            {
                kf = 2,
                t = 0.32,
                timeSec = 0.115,
                label = "Flat Inside-Foot Push Contact [Ground Pass]",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                contact = {
                    part = "Right Leg",
                    localPoint = Vector3.new(-0.500, -0.012, -0.219),
                    worldPoint = Vector3.new(0.520, 1.273, -0.893),
                    ballCenter = Vector3.new(-0.464, 1.250, -1.664),
                    surfaceDist = 1.250,
                },
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.040, 0.160, 0.000), rotDeg = Vector3.new(-8.0, 4.0, 4.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -4.0, -3.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 0.0, 16.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 6.0, -20.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, -42.0, 8.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, 4.0, -5.0) },
                },
            },
            {
                kf = 3,
                t = 0.65,
                timeSec = 0.234,
                label = "Controlled Short Follow-Through (Abrupt Stop)",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(-0.030, 0.167, -0.020), rotDeg = Vector3.new(-4.0, 12.0, 5.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-4.0, -12.0, -4.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, 6.0, 14.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, -4.0, -18.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(34.0, -38.0, 2.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-10.0, 4.0, -5.0) },
                },
            },
            {
                kf = 4,
                t = 1.00,
                timeSec = 0.360,
                label = "Instant Play Continuation Ready",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                },
            },
        },
        variants = {
            ["ground"] = {
                name = "A16-ground (Driven Ground Pass: elevation=0°, power=0.6)",
                contactSurfaceDesc = "Medial inner surface (-0.50, -0.50, -0.10) at mid-ball height (Y ≈ 1.02 studs), Torso leaned forward -8°",
                keyframes = {
                    {
                        kf = 1,
                        t = 0.00,
                        timeSec = 0.000,
                        label = "Compact Pass Chamber (Open Hip Push Prep)",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.050, 0.123, 0.020), rotDeg = Vector3.new(-8.0, -14.0, 2.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 14.0, -2.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-18.0, -6.0, 18.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(26.0, 8.0, -22.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, -36.0, 12.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(12.0, 6.0, -6.0) },
                        },
                    },
                    {
                        kf = 2,
                        t = 0.32,
                        timeSec = 0.115,
                        label = "Flat Inside-Foot Push Contact [Ground Pass]",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        contact = {
                            part = "Right Leg",
                            localPoint = Vector3.new(-0.500, -0.012, -0.219),
                            worldPoint = Vector3.new(0.520, 1.273, -0.893),
                            ballCenter = Vector3.new(-0.464, 1.250, -1.664),
                            surfaceDist = 1.250,
                        },
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.040, 0.160, 0.000), rotDeg = Vector3.new(-8.0, 4.0, 4.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -4.0, -3.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 0.0, 16.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 6.0, -20.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, -42.0, 8.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, 4.0, -5.0) },
                        },
                    },
                    {
                        kf = 3,
                        t = 0.65,
                        timeSec = 0.234,
                        label = "Controlled Short Follow-Through (Abrupt Stop)",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.030, 0.167, -0.020), rotDeg = Vector3.new(-4.0, 12.0, 5.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-4.0, -12.0, -4.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, 6.0, 14.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, -4.0, -18.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(34.0, -38.0, 2.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-10.0, 4.0, -5.0) },
                        },
                    },
                    {
                        kf = 4,
                        t = 1.00,
                        timeSec = 0.360,
                        label = "Instant Play Continuation Ready",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                        },
                    },
                },
            },
            ["lob"] = {
                name = "A16-lob (Lofted / Chipped Pass: elevation=35°, power=0.85)",
                contactSurfaceDesc = "Lower-medial front edge (-0.35, -0.85, -0.50) wedged under ball equator (Y ≈ 0.68 studs), Torso reclined +6°",
                keyframes = {
                    {
                        kf = 1,
                        t = 0.00,
                        timeSec = 0.000,
                        label = "Lob Pass Chamber (Deeper Dip & Backswing)",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.060, 0.167, 0.040), rotDeg = Vector3.new(-4.0, -20.0, 4.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(4.0, 18.0, -3.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, -8.0, 22.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(38.0, 12.0, -28.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-42.0, -28.0, 14.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 8.0, -8.0) },
                        },
                    },
                    {
                        kf = 2,
                        t = 0.32,
                        timeSec = 0.115,
                        label = "Under-Ball Wedge Scoop Contact [Lob Pass]",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        contact = {
                            part = "Right Leg",
                            localPoint = Vector3.new(-0.500, -1.000, -0.500),
                            worldPoint = Vector3.new(0.610, 0.903, -1.972),
                            ballCenter = Vector3.new(0.724, 1.250, -3.167),
                            surfaceDist = 1.250,
                        },
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.050, 0.147, 0.020), rotDeg = Vector3.new(6.0, 6.0, 6.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, -6.0, -4.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(4.0, 0.0, 20.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 8.0, -26.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, -26.0, 8.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-10.0, 6.0, -6.0) },
                        },
                    },
                    {
                        kf = 3,
                        t = 0.65,
                        timeSec = 0.234,
                        label = "Upward Chip Lift Follow-Through",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(-0.040, 0.200, -0.020), rotDeg = Vector3.new(10.0, 18.0, 8.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-4.0, -16.0, -6.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 8.0, 16.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, -6.0, -22.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(52.0, -24.0, -6.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-14.0, 6.0, -6.0) },
                        },
                    },
                    {
                        kf = 4,
                        t = 1.00,
                        timeSec = 0.360,
                        label = "Instant Play Continuation Ready",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                        },
                    },
                },
            },
        },
    },
    ["A17"] = {
        id = "A17",
        name = "Slide Tackle",
        mode = "OneShot",
        duration = 0.55,
        blendIn = 0.05,
        blendOut = 0.00,
        holdPhase = nil,
        contactPhase = 0.38,
        referenceSpeed = 28.0,
        nextAnimOnComplete = "A18",
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Drop Entry & Hip Side-Collapse",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.108, 0.050), rotDeg = Vector3.new(24.0, 14.0, -10.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-16.0, -12.0, 6.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 0.0, 26.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, 0.0, -20.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(46.0, -8.0, 8.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-22.0, -16.0, -22.0) },
                },
            },
            {
                kf = 2,
                t = 0.18,
                timeSec = 0.099,
                label = "Intermediate Support Drop (Clearance Guard)",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.250, -0.050), rotDeg = Vector3.new(42.0, 18.0, -14.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-18.0, -12.0, 6.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-25.0, 0.0, 42.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(35.0, 0.0, -42.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(38.0, -9.0, 8.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(0.0, -22.0, -26.0) },
                },
            },
            {
                kf = 3,
                t = 0.38,
                timeSec = 0.209,
                label = "Active Full-Extension Slide [Ball Contact]",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                contact = {
                    part = "Right Leg",
                    localPoint = Vector3.new(0.365, -1.000, -0.233),
                    worldPoint = Vector3.new(-0.047, 1.448, -3.262),
                    ballCenter = Vector3.new(-0.385, 1.250, -4.449),
                    surfaceDist = 1.250,
                },
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -1.027, -0.180), rotDeg = Vector3.new(58.0, 22.0, -16.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-28.0, -18.0, 10.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(34.0, 8.0, 32.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-40.0, 0.0, -22.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, -10.0, 8.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, -28.0, -30.0) },
                },
            },
            {
                kf = 4,
                t = 0.72,
                timeSec = 0.396,
                label = "Turf Glide & Sweep Follow-Through",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.939, -0.240), rotDeg = Vector3.new(62.0, 28.0, -18.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-30.0, -22.0, 12.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(42.0, 12.0, 24.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-36.0, 0.0, -18.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(24.0, 4.0, -4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, -30.0, -32.0) },
                },
            },
            {
                kf = 5,
                t = 1.00,
                timeSec = 0.550,
                label = "Slide Exit & Brace Preparation (Hands off to A18)",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.327, -0.100), rotDeg = Vector3.new(46.0, 20.0, -14.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-22.0, -16.0, 8.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, 6.0, 20.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-32.0, 0.0, -16.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 0.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, -22.0, -24.0) },
                },
            },
        },
    },
    ["A18"] = {
        id = "A18",
        name = "Slide Recovery (Hit & Miss Visual Variants)",
        mode = "OneShot",
        duration = 0.44,
        blendIn = 0.00,
        blendOut = 0.10,
        holdPhase = nil,
        contactPhase = nil,
        referenceSpeed = 10.0,
        keyframes = {
            {
                kf = 1,
                t = 0.00,
                timeSec = 0.000,
                label = "Shared Entry from A17 Slide Exit",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, -0.327, -0.100), rotDeg = Vector3.new(46.0, 20.0, -14.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-22.0, -16.0, 8.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, 6.0, 20.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-32.0, 0.0, -16.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 0.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, -22.0, -24.0) },
                },
            },
            {
                kf = 2,
                t = 0.35,
                timeSec = 0.154,
                label = "On-Ball Variant: Energetic Hip Pop & Chest Whip",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.149, 0.000), rotDeg = Vector3.new(10.0, 10.0, -8.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -8.0, 4.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(36.0, 0.0, 18.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-24.0, 0.0, -14.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(38.0, -6.0, 8.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-26.0, -8.0, -14.0) },
                },
            },
            {
                kf = 3,
                t = 0.70,
                timeSec = 0.308,
                label = "On-Ball Variant: Forward Drive Step Rise",
                hrpRefY = 3.00,
                obbMinY = 0.015,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.094, 0.000), rotDeg = Vector3.new(-16.0, 4.0, -2.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, -4.0, 2.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-18.0, 0.0, 14.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 0.0, -14.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, -4.0, 5.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-20.0, 4.0, -5.0) },
                },
            },
            {
                kf = 4,
                t = 1.00,
                timeSec = 0.440,
                label = "Shared Exit: Athletic Ready Stance",
                hrpRefY = 3.00,
                obbMinY = 0.010,
                joints = {
                    ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                    ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                    ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                    ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                    ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                    ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                },
            },
        },
        variants = {
            ["hit"] = {
                name = "A18-hit (On-Ball Clean Pop-Up Recovery)",
                contactSurfaceDesc = "Energetic backward-to-forward hip whip using stopping impulse from ball tackle",
                keyframes = {
                    {
                        kf = 1,
                        t = 0.00,
                        timeSec = 0.000,
                        label = "Shared Entry from A17 Slide Exit",
                        hrpRefY = 3.00,
                        obbMinY = 0.015,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.000, -0.327, -0.100), rotDeg = Vector3.new(46.0, 20.0, -14.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-22.0, -16.0, 8.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, 6.0, 20.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-32.0, 0.0, -16.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 0.0, 4.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, -22.0, -24.0) },
                        },
                    },
                    {
                        kf = 2,
                        t = 0.35,
                        timeSec = 0.154,
                        label = "On-Ball Variant: Energetic Hip Pop & Chest Whip",
                        hrpRefY = 3.00,
                        obbMinY = 0.015,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.000, 0.149, 0.000), rotDeg = Vector3.new(10.0, 10.0, -8.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -8.0, 4.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(36.0, 0.0, 18.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-24.0, 0.0, -14.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(38.0, -6.0, 8.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-26.0, -8.0, -14.0) },
                        },
                    },
                    {
                        kf = 3,
                        t = 0.70,
                        timeSec = 0.308,
                        label = "On-Ball Variant: Forward Drive Step Rise",
                        hrpRefY = 3.00,
                        obbMinY = 0.015,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.000, 0.094, 0.000), rotDeg = Vector3.new(-16.0, 4.0, -2.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, -4.0, 2.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-18.0, 0.0, 14.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(28.0, 0.0, -14.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, -4.0, 5.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-20.0, 4.0, -5.0) },
                        },
                    },
                    {
                        kf = 4,
                        t = 1.00,
                        timeSec = 0.440,
                        label = "Shared Exit: Athletic Ready Stance",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                        },
                    },
                },
            },
            ["miss"] = {
                name = "A18-miss (Whiff Roll-Over Push-Up Recovery)",
                contactSurfaceDesc = "Rotational torso turn (rx=-18°, ry=+28°) and hand-push recovery carrying residual slide momentum",
                keyframes = {
                    {
                        kf = 1,
                        t = 0.00,
                        timeSec = 0.000,
                        label = "Shared Entry from A17 Slide Exit",
                        hrpRefY = 3.00,
                        obbMinY = 0.015,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.000, -0.327, -0.100), rotDeg = Vector3.new(46.0, 20.0, -14.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-22.0, -16.0, 8.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(22.0, 6.0, 20.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-32.0, 0.0, -16.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, 0.0, 4.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, -22.0, -24.0) },
                        },
                    },
                    {
                        kf = 2,
                        t = 0.18,
                        timeSec = 0.079,
                        label = "Intermediate Hand-Brace Rise (Clearance Guard)",
                        hrpRefY = 3.00,
                        obbMinY = 0.015,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.020, -0.150, -0.080), rotDeg = Vector3.new(10.0, 24.0, -15.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, -18.0, 5.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(20.0, -10.0, 35.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(35.0, 12.0, -40.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-8.0, -6.0, 8.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, -8.0, -20.0) },
                        },
                    },
                    {
                        kf = 3,
                        t = 0.35,
                        timeSec = 0.154,
                        label = "Miss/Whiff Variant: Side-Roll Hand Plant Brace",
                        hrpRefY = 3.00,
                        obbMinY = 0.015,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.060, -0.049, -0.060), rotDeg = Vector3.new(-18.0, 28.0, -16.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, -22.0, 10.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(34.0, 12.0, 22.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(24.0, 0.0, -28.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-32.0, -12.0, 14.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(34.0, 8.0, -18.0) },
                        },
                    },
                    {
                        kf = 4,
                        t = 0.70,
                        timeSec = 0.308,
                        label = "Miss/Whiff Variant: Heavy Push-Up & Turn Rise",
                        hrpRefY = 3.00,
                        obbMinY = 0.015,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.030, -0.010, 0.000), rotDeg = Vector3.new(-22.0, 14.0, -6.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(18.0, -14.0, 4.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(16.0, 0.0, 18.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-22.0, 0.0, -18.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-24.0, -6.0, 8.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(26.0, 6.0, -8.0) },
                        },
                    },
                    {
                        kf = 5,
                        t = 1.00,
                        timeSec = 0.440,
                        label = "Shared Exit: Athletic Ready Stance",
                        hrpRefY = 3.00,
                        obbMinY = 0.010,
                        joints = {
                            ["RootJoint"] = { pos = Vector3.new(0.000, 0.140, 0.000), rotDeg = Vector3.new(-8.0, -4.0, 0.0) },
                            ["Neck"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(8.0, 4.0, 0.0) },
                            ["Right Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(10.0, -6.0, 12.0) },
                            ["Left Shoulder"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(14.0, 6.0, -12.0) },
                            ["Right Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(-6.0, -5.0, 4.0) },
                            ["Left Hip"] = { pos = Vector3.new(0.000, 0.000, 0.000), rotDeg = Vector3.new(6.0, 5.0, -4.0) },
                        },
                    },
                },
            },
        },
    },
})

return table.freeze(PlayerActionPoseConfigs)
