--!strict
-- src/shared/DribbleGeometryHelper.luau
-- Continuous front-foot control + joint body/cage clearance + jump self-lob
-- Governed by RF02-DRIBBLE-RECEIVE (2026-10-27 Authoritative Grill Final).
-- Pure functions over Vector3; the ONLY authority is the server BallService caller.
-- Assumptions (not measured rig bounds): carrier = upright cylinder radius CARRIER_BODY_RADIUS, ball = sphere BALL_COLLISION_RADIUS.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local DribbleConfigs = require(Shared:WaitForChild("configs"):WaitForChild("DribbleConfigs"))

local DribbleGeometryHelper = {}

local EPS = 1e-4

local function horiz(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function safeUnit(v: Vector3, fallback: Vector3): Vector3
	local m = v.Magnitude
	if m > EPS and m == m then
		return v / m
	end
	return fallback
end

local function clampMag(v: Vector3, maxMag: number): Vector3
	local m = v.Magnitude
	if m > maxMag and m > EPS then
		return v * (maxMag / m)
	end
	return v
end

-- Ball-center limits inside the cage box (cage physics itself is untouched).
local function cageLimits(): (number, number)
	local r = DribbleConfigs.BALL_COLLISION_RADIUS
	return Constants.ARENA_HALF_WIDTH_X - r, Constants.ARENA_HALF_LENGTH_Z - r
end

local function insideCage(x: number, z: number): boolean
	local mx, mz = cageLimits()
	return math.abs(x) <= mx + 1e-6 and math.abs(z) <= mz + 1e-6
end

function DribbleGeometryHelper.GetCarrierSeparationDistance(): number
	return DribbleConfigs.CARRIER_BODY_RADIUS + DribbleConfigs.BALL_COLLISION_RADIUS + DribbleConfigs.MIN_BODY_SEPARATION_MARGIN
end

-- Shared feet origin: feet = RootPart.Y - PLAYER_FEET_OFFSET
function DribbleGeometryHelper.GetFeetY(rootY: number): number
	return rootY - DribbleConfigs.PLAYER_FEET_OFFSET
end

-- Turn slow-down factor for DRIBBLING carriers: 1 at/below threshold (120 deg), MIN at 180 degrees.
function DribbleGeometryHelper.ComputeTurnSpeedFactor(angleRad: number, isSprinting: boolean): number
	local thresh = math.rad(DribbleConfigs.DRIBBLE_TURN_DIP_THRESHOLD_DEG)
	local a = math.abs(angleRad)
	if a ~= a or a <= thresh then
		return 1.0
	end
	local minF = if isSprinting then DribbleConfigs.DRIBBLE_TURN_MIN_FACTOR_SPRINT else DribbleConfigs.DRIBBLE_TURN_MIN_FACTOR_WALK
	local norm = math.clamp((a - thresh) / (math.pi - thresh), 0, 1)
	return 1.0 - (1.0 - minF) * (norm ^ DribbleConfigs.DRIBBLE_TURN_EXPONENT)
end

-- Forward micro-touch radial pulse: purely forward along travel direction, zero lateral sway, 0 at rest.
function DribbleGeometryHelper.ComputeMicroTouchOffset(speed: number, isSprinting: boolean, timeSec: number): number
	if not DribbleConfigs.MICRO_TOUCH_ENABLED or speed <= DribbleConfigs.MIN_PLAYER_MOVE_SPEED then
		return 0.0
	end
	local amp = if isSprinting then DribbleConfigs.MICRO_TOUCH_AMPLITUDE_SPRINT else DribbleConfigs.MICRO_TOUCH_AMPLITUDE_WALK
	local cad = if isSprinting then DribbleConfigs.MICRO_TOUCH_CADENCE_SPRINT else DribbleConfigs.MICRO_TOUCH_CADENCE_WALK
	local phase = (timeSec * cad * 2 * math.pi) % (2 * math.pi)
	-- Forward-only positive pulse in [0, 1]
	local pulse = 0.5 * (1 - math.cos(phase))
	return amp * pulse
end

-- Desired controlled ball position: along leadDir (MoveDirection when moving, body front when idle);
-- slides to nearest feasible flank when the target is outside the cage; returns (target, flankAngleDeg, infeasible).
function DribbleGeometryHelper.FeasibleFrontTarget(
	rootPos: Vector3,
	leadDir: Vector3,
	isSprinting: boolean,
	radialOffset: number?
): (Vector3, number, boolean)
	local f = safeUnit(horiz(leadDir), Vector3.new(0, 0, -1))
	local baseD = if isSprinting then DribbleConfigs.FRONT_DISTANCE_SPRINT else DribbleConfigs.FRONT_DISTANCE_WALK
	local sep = DribbleGeometryHelper.GetCarrierSeparationDistance()
	local d = math.max(baseD + (radialOffset or 0), sep)
	local base = math.atan2(f.Z, f.X)
	local steps = DribbleConfigs.FLANK_ANGLE_STEPS
	local stepRad = 2 * math.pi / steps
	for _, radius in ipairs({ d, sep }) do
		for k = 0, steps // 2 do
			for _, sgn in ipairs({ 1, -1 }) do
				if k == 0 and sgn == -1 then
					continue
				end
				local ang = base + sgn * k * stepRad
				local x = rootPos.X + math.cos(ang) * radius
				local z = rootPos.Z + math.sin(ang) * radius
				if insideCage(x, z) then
					return Vector3.new(x, rootPos.Y, z), math.deg(k * stepRad), false
				end
			end
		end
	end
	local mx, mz = cageLimits()
	local clamped = Vector3.new(math.clamp(rootPos.X + f.X * d, -mx, mx), rootPos.Y, math.clamp(rootPos.Z + f.Z * d, -mz, mz))
	return clamped, 180, true
end

local function wrapAngle(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

-- Polar front tracking: the ball ORBITS the carrier (bounded angular speed, bounded radial speed, radius never below the
-- clearance ring) toward the target, carried with the carrier velocity so it genuinely travels. Because the relative
-- motion is an arc around the body, the ball never crosses the torso while swinging between back/side/front.
-- Returns the absolute ball velocity for this step (displacement = velocity * dt before friction/cage).
function DribbleGeometryHelper.ComputeFrontVelocity(rootPos: Vector3, carrierVel: Vector3, ballPos: Vector3, target: Vector3, dt: number): Vector3
	local sep = DribbleGeometryHelper.GetCarrierSeparationDistance()
	local rel = horiz(ballPos - rootPos)
	local tRel = horiz(target - rootPos)
	local rt = math.max(tRel.Magnitude, sep)
	local thetaT = if tRel.Magnitude > EPS then math.atan2(tRel.Z, tRel.X) else 0
	local r = rel.Magnitude
	local thetaB = if r > 0.05 then math.atan2(rel.Z, rel.X) else thetaT
	if r <= 0.05 then
		r = sep
		rel = Vector3.new(math.cos(thetaB) * r, 0, math.sin(thetaB) * r)
	end
	local step = math.clamp(dt, 0.001, 0.1)

	local dTheta = wrapAngle(thetaT - thetaB)
	local maxAng = DribbleConfigs.FRONT_MAX_ANGULAR_SPEED * step
	local stepTheta = math.clamp(dTheta * DribbleConfigs.FRONT_ANGULAR_GAIN * step, -maxAng, maxAng)
	if math.abs(stepTheta) > math.abs(dTheta) then
		stepTheta = dTheta
	end

	local dR = rt - r
	local maxRad = DribbleConfigs.FRONT_RADIAL_MAX_SPEED * step
	local stepR = math.clamp(dR * DribbleConfigs.FRONT_RADIAL_GAIN * step, -maxRad, maxRad)
	if math.abs(stepR) > math.abs(dR) then
		stepR = dR
	end

	local newR = math.max(r + stepR, sep)
	local newTheta = thetaB + stepTheta
	local relNew = Vector3.new(math.cos(newTheta) * newR, 0, math.sin(newTheta) * newR)
	local relVel = clampMag((relNew - rel) / step, DribbleConfigs.FRONT_MAX_REL_SPEED)
	return clampMag(horiz(carrierVel) + relVel, DribbleConfigs.MAX_BALL_DRIBBLE_SPEED)
end

-- Compute initial 3D velocity for Jump Self-Lob (Scoop).
-- Moving uses verified horizontal momentum; stationary uses horizontal launchDir (from camera look).
function DribbleGeometryHelper.ComputeSelfLobVelocity(
	launchDir: Vector3,
	carrierHorizVel: Vector3,
	isMoving: boolean
): Vector3
	local f = safeUnit(horiz(launchDir), Vector3.new(0, 0, -1))
	local vH: number
	if isMoving then
		local curSpeed = horiz(carrierHorizVel).Magnitude
		vH = math.clamp(
			curSpeed * DribbleConfigs.SELF_LOB_MOMENTUM_FACTOR,
			DribbleConfigs.SELF_LOB_MIN_HORIZONTAL_SPEED,
			DribbleConfigs.SELF_LOB_MAX_HORIZONTAL_SPEED
		)
	else
		vH = DribbleConfigs.SELF_LOB_MIN_HORIZONTAL_SPEED
	end
	return Vector3.new(f.X * vH, DribbleConfigs.SELF_LOB_UPWARD_SPEED, f.Z * vH)
end

local function reflectInward(n: Vector3, vRel: Vector3): Vector3
	local vn = vRel.X * n.X + vRel.Z * n.Z
	if vn < 0 then
		return vRel - n * ((1 + DribbleConfigs.BODY_CONTACT_RESTITUTION) * vn)
	end
	return vRel
end

-- Joint swept body + cage resolution for one step. Returns (pos, vel, adjusted, infeasible).
-- 1) vertical-disjoint balls untouched; 2) exact first time-of-impact vs body circle; 3) cage feasibility with
-- feasible-flank ring search (never pushes through walls, never teleports beyond one ring correction).
function DribbleGeometryHelper.ResolveBodyCage(
	p0: Vector3,
	p1: Vector3,
	b0: Vector3,
	b1: Vector3,
	vb: Vector3,
	vp: Vector3,
	dt: number,
	facing: Vector3
): (Vector3, Vector3, boolean, boolean)
	local dT = DribbleGeometryHelper.GetCarrierSeparationDistance()
	local ballR = DribbleConfigs.BALL_COLLISION_RADIUS
	local feet = DribbleGeometryHelper.GetFeetY(p1.Y)
	if math.max(feet, b1.Y - ballR) > math.min(feet + DribbleConfigs.BODY_HEIGHT, b1.Y + ballR) then
		return b1, vb, false, false
	end

	local fU = safeUnit(horiz(facing), Vector3.new(0, 0, -1))
	local s0 = Vector3.new(b0.X - p0.X, 0, b0.Z - p0.Z)
	local s1 = Vector3.new(b1.X - p1.X, 0, b1.Z - p1.Z)
	local ds = s1 - s0
	local a = ds.X * ds.X + ds.Z * ds.Z
	local b = 2 * (s0.X * ds.X + s0.Z * ds.Z)
	local c = (s0.X * s0.X + s0.Z * s0.Z) - dT * dT

	local adjusted = false
	local s1c = s1
	local vbc = vb
	local vpH = horiz(vp)

	if c <= 0 then
		adjusted = true
		local d0 = s0.Magnitude
		local n = safeUnit(s0, fU)
		local sC = n * (d0 + math.min(dT - d0, DribbleConfigs.MAX_OVERLAP_SEPARATION_STEP))
		local vr = reflectInward(n, Vector3.new(vb.X - vp.X, 0, vb.Z - vp.Z))
		local o = vr.X * n.X + vr.Z * n.Z
		if o < DribbleConfigs.OVERLAP_RECOVERY_PUSH_SPEED then
			vr = vr + n * (DribbleConfigs.OVERLAP_RECOVERY_PUSH_SPEED - math.max(0, o))
		end
		s1c = sC + vr * dt
		local l = s1c.Magnitude
		if l < dT then
			s1c = if l > EPS then s1c * (dT / l) else n * dT
		end
		vbc = Vector3.new(vpH.X + vr.X, vb.Y, vpH.Z + vr.Z)
	elseif b < 0 and a > 1e-8 then
		local disc = b * b - 4 * a * c
		if disc >= 0 then
			local t = (-b - math.sqrt(disc)) / (2 * a)
			if t >= 0 and t <= 1 then
				adjusted = true
				local sC = s0 + ds * t
				local n = safeUnit(sC, fU)
				local vr = reflectInward(n, if dt > EPS then ds / dt else Vector3.zero)
				s1c = sC + vr * ((1 - t) * dt)
				local l = s1c.Magnitude
				if l < dT then
					s1c = if l > EPS then s1c * (dT / l) else n * dT
				end
				vbc = Vector3.new(vpH.X + vr.X, vb.Y, vpH.Z + vr.Z)
			end
		end
	end

	local cx, cz = p1.X + s1c.X, p1.Z + s1c.Z
	local infeasible = false
	if not insideCage(cx, cz) then
		adjusted = true
		local mx, mz = cageLimits()
		local clx, clz = math.clamp(cx, -mx, mx), math.clamp(cz, -mz, mz)
		local vx, vz = vbc.X, vbc.Z
		if clx ~= cx and ((clx > 0 and vx > 0) or (clx < 0 and vx < 0)) then
			vx = 0
		end
		if clz ~= cz and ((clz > 0 and vz > 0) or (clz < 0 and vz < 0)) then
			vz = 0
		end
		vbc = Vector3.new(vx, vbc.Y, vz)
		local dx, dz = clx - p1.X, clz - p1.Z
		if math.sqrt(dx * dx + dz * dz) >= dT - 1e-6 then
			cx, cz = clx, clz
		else
			-- Body and wall conflict: choose the feasible ring point nearest to the clamped ball
			local best, bestD = nil, math.huge
			local steps = DribbleConfigs.FLANK_ANGLE_STEPS
			for i = 0, steps - 1 do
				local ang = i * 2 * math.pi / steps
				local qx, qz = p1.X + math.cos(ang) * dT, p1.Z + math.sin(ang) * dT
				if insideCage(qx, qz) then
					local dd = (qx - clx) ^ 2 + (qz - clz) ^ 2
					if dd < bestD then
						bestD = dd
						best = Vector3.new(qx, 0, qz)
					end
				end
			end
			if best then
				cx, cz = best.X, best.Z
				local n = safeUnit(Vector3.new(cx - p1.X, 0, cz - p1.Z), fU)
				local vr = reflectInward(n, Vector3.new(vbc.X - vp.X, 0, vbc.Z - vp.Z))
				vbc = Vector3.new(vpH.X + vr.X, vbc.Y, vpH.Z + vr.Z)
			else
				cx, cz = clx, clz
				infeasible = true
			end
		end
	end

	return Vector3.new(cx, b1.Y, cz), vbc, adjusted, infeasible
end

return DribbleGeometryHelper
