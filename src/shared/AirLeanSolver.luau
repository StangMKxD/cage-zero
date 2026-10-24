--!strict
--[[
    AirLeanSolver.luau
    Pure deterministic solver for airborne body lean kinematics and ball launch deflection.
    Governed by: docs/plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md §12.5–12.6

    Principles:
    1. Pure functional logic — zero side effects, no instance writes, no frame loops.
    2. Shared identically by Client prediction and Server authoritative resolution.
    3. F0 locked horizontal facing committed at takeoff; R0 = F0 x Up.
    4. Neutral lean (0, 0) produces exact standard base trajectory with zero extra offset.
    5. Deterministic deflection along R0 and pitch elevation with bounded energy cap.
]]

local AirLeanConfigs = require(script.Parent.configs.AirLeanConfigs)

local AirLeanSolver = {}

local UP_VECTOR = Vector3.new(0, 1, 0)

--[=[
    Clamps and sanitizes normalized lean inputs to the unit circle/box [-1.0, 1.0].
]=]
function AirLeanSolver.ClampLeanInput(forward: number?, right: number?): (number, number)
    local f = forward or 0.0
    local r = right or 0.0

    -- Sanitize non-finite values (NaN / Inf)
    if f ~= f or math.abs(f) == math.huge then
        f = 0.0
    end
    if r ~= r or math.abs(r) == math.huge then
        r = 0.0
    end

    f = math.clamp(f, -1.0, 1.0)
    r = math.clamp(r, -1.0, 1.0)

    -- Diagonal magnitude normalization so corner inputs (e.g. W+D) do not exceed 1.0
    local magSq = f * f + r * r
    if magSq > 1.0 then
        local mag = math.sqrt(magSq)
        f /= mag
        r /= mag
    end

    return f, r
end

--[=[
    Applies slew rate limiting to smoothly transition from current lean to target lean.
]=]
function AirLeanSolver.SlewLean(
    currentFwd: number,
    currentRight: number,
    targetFwd: number,
    targetRight: number,
    dt: number
): (number, number)
    local maxDelta = (AirLeanConfigs.MAX_SLEW_DEG_PER_SEC / AirLeanConfigs.MAX_PITCH_DEG) * math.max(dt, 0.0)

    local deltaFwd = targetFwd - currentFwd
    local stepFwd = math.clamp(deltaFwd, -maxDelta, maxDelta)
    local nextFwd = math.clamp(currentFwd + stepFwd, -1.0, 1.0)

    local deltaRight = targetRight - currentRight
    local stepRight = math.clamp(deltaRight, -maxDelta, maxDelta)
    local nextRight = math.clamp(currentRight + stepRight, -1.0, 1.0)

    return nextFwd, nextRight
end

--[=[
    Computes angular tilt in radians for pitch (X axis) and roll (Z axis).
]=]
function AirLeanSolver.ComputeLeanAngles(leanForward: number, leanRight: number): (number, number)
    local f, r = AirLeanSolver.ClampLeanInput(leanForward, leanRight)
    local pitchRad = math.rad(f * AirLeanConfigs.MAX_PITCH_DEG)
    local rollRad = math.rad(r * AirLeanConfigs.MAX_ROLL_DEG)
    return pitchRad, rollRad
end

--[=[
    Computes pure orientation tilt CFrame in RootJoint local space.
    W (+forward) tilts Torso.Up forward (Part0 -X pitch); Roll tilts laterally (Z axis).
    Governed by: docs/plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md §14.1–14.2
]=]
function AirLeanSolver.ComputeLeanCFrame(leanForward: number, leanRight: number): CFrame
    local pitchRad, rollRad = AirLeanSolver.ComputeLeanAngles(leanForward, leanRight)
    -- In R6 RootJoint C0, negating pitch tilts Torso.Up forward into -Z (W forward, S backward)
    return CFrame.Angles(-pitchRad, 0, -rollRad)
end

--[=[
    Calculates deterministic launch velocity and angular spin deflection for airborne shots.
    Uses validated 3D aim direction from reticle/camera as the base trajectory (Owner Delta §14.3),
    applying a small bounded deterministic perturbation in the aim-local frame (extra cone <= 5 deg).
]=]
function AirLeanSolver.ComputeAirShotTrajectory(
    baseAimOrF0: Vector3,
    speedOrElev: number,
    biasOrPower: number,
    leanFwdOrVertPower: any,
    leanRgtOrFwd: any,
    actionOrRgt: any,
    legacyAction: any
): (Vector3, Vector3)
    local baseAimDirection: Vector3
    local kickSpeed: number
    local upwardBias: number
    local leanForward: number?
    local leanRight: number?
    local actionType: string?

    -- Support both new 6-arg aim-relative signature and legacy 7-arg (F0, elev, power, vertPower, ...) signature
    if typeof(leanFwdOrVertPower) == "number" and typeof(leanRgtOrFwd) == "number" and (legacyAction ~= nil or typeof(actionOrRgt) == "number") then
        local elev = speedOrElev
        local power = biasOrPower
        local vertPower = leanFwdOrVertPower :: number
        local flatF0 = Vector3.new(baseAimOrF0.X, 0, baseAimOrF0.Z)
        local F0 = if flatF0.Magnitude > 0.001 then flatF0.Unit else Vector3.new(0, 0, -1)
        baseAimDirection = (F0 * math.cos(elev) + UP_VECTOR * math.sin(elev)).Unit
        kickSpeed = power
        upwardBias = if power > 0.001 then vertPower / power else 0.0
        leanForward = leanRgtOrFwd :: number?
        leanRight = actionOrRgt :: number?
        actionType = legacyAction :: string?
    else
        baseAimDirection = baseAimOrF0
        kickSpeed = speedOrElev
        upwardBias = biasOrPower
        leanForward = leanFwdOrVertPower :: number?
        leanRight = leanRgtOrFwd :: number?
        actionType = actionOrRgt :: string?
    end

    -- 1. Base launch vector from validated aimDirection3D (Owner Delta §14.3)
    local rawAim = if baseAimDirection and baseAimDirection.Magnitude > 0.001 then baseAimDirection.Unit else Vector3.new(0, 0, -1)
    local launchY = math.clamp(rawAim.Y + upwardBias, -0.75, 0.85)
    local horizScale = math.sqrt(math.max(0.01, 1.0 - launchY * launchY))
    local horizAim = Vector3.new(rawAim.X, 0, rawAim.Z)
    local flatAim = if horizAim.Magnitude > 0.001 then horizAim.Unit else Vector3.new(0, 0, -1)
    local baseLaunchDir = (flatAim * horizScale + UP_VECTOR * launchY).Unit
    local baseVelocity = baseLaunchDir * kickSpeed

    -- 2. Neutral lean fast-path: exact base trajectory without extra modification
    local f, r = AirLeanSolver.ClampLeanInput(leanForward, leanRight)
    if math.abs(f) < 0.001 and math.abs(r) < 0.001 then
        return baseVelocity, Vector3.zero
    end

    -- 3. Construct orthonormal AIM-local coordinate frame (AimForward, AimRight, AimUp)
    local AimForward = baseLaunchDir
    local refUp = UP_VECTOR
    if math.abs(AimForward:Dot(refUp)) > 0.98 then
        refUp = Vector3.new(0, 0, -1)
    end
    local AimRight = AimForward:Cross(refUp).Unit
    local AimUp = AimRight:Cross(AimForward).Unit

    -- 4. Bounded deflection cone: strictly capped at MAX_DEFLECTION_CONE_DEG (5.0 deg)
    local maxConeDeg = AirLeanConfigs.MAX_DEFLECTION_CONE_DEG or 5.0
    local yawAngle = math.rad(r * maxConeDeg)
    local pitchAngle = math.rad(-f * maxConeDeg)
    local deflectedDir = (AimForward + AimRight * math.tan(yawAngle) + AimUp * math.tan(pitchAngle)).Unit
    local finalVelocity = deflectedDir * kickSpeed

    -- 5. Bounded physical curve force (studs/s²) for subtle Magnus drift
    local maxExtraCurve = AirLeanConfigs.MAX_EXTRA_CURVE_FORCE or 6.0
    local extraCurveForce = AimRight * (-r * maxExtraCurve)

    return finalVelocity, extraCurveForce
end

-- Applies accepted lean through the actual strike-frame orientation. The neutral
-- contact frame is subtracted so legacy aim/launch values remain unchanged at 0 lean.
function AirLeanSolver.ComputeContactShotTrajectory(
	baseAimDirection: Vector3,
	kickSpeed: number,
	upwardBias: number,
	leanForward: number,
	leanRight: number,
	actionType: string,
	contactFrame: CFrame,
	neutralContactFrame: CFrame
): (Vector3, Vector3)
	local leanFwd, leanRgt = AirLeanSolver.ClampLeanInput(leanForward, leanRight)
	local baseVelocity, curveForce = AirLeanSolver.ComputeAirShotTrajectory(
		baseAimDirection,
		kickSpeed,
		upwardBias,
		0.0,
		leanRgt,
		actionType
	)
	local profile = AirLeanConfigs.CONTACT_LEAN_PROFILES[actionType]
	if not profile or math.abs(leanFwd) < 1e-4 then
		return baseVelocity, curveForce
	end

	local flatAim = Vector3.new(baseAimDirection.X, 0, baseAimDirection.Z)
	if flatAim.Magnitude < 1e-3 then
		local look = neutralContactFrame.LookVector
		flatAim = Vector3.new(look.X, 0, look.Z)
	end
	if flatAim.Magnitude < 1e-3 then
		flatAim = Vector3.new(0, 0, -1)
	end
	flatAim = flatAim.Unit

	-- A torso leaning backward has its up axis displaced opposite the strike aim.
	-- Comparing against the same action's neutral contact frame removes its fixed pose bias.
	local contactUpDelta = contactFrame.UpVector - neutralContactFrame.UpVector
	local maxInputPitch = math.sin(math.rad(AirLeanConfigs.MAX_PITCH_DEG))
	local postureWeight = if maxInputPitch > 1e-4
		then math.clamp(contactUpDelta:Dot(-flatAim) / maxInputPitch, -1.0, 1.0)
		else 0.0
	local elevationDeltaDeg = if postureWeight >= 0
		then postureWeight * profile.maxBackwardLoftDeg
		else postureWeight * profile.maxForwardLoweringDeg
	if math.abs(elevationDeltaDeg) < 1e-4 then
		return baseVelocity, curveForce
	end

	local speed = baseVelocity.Magnitude
	local horizontal = Vector3.new(baseVelocity.X, 0, baseVelocity.Z)
	if horizontal.Magnitude < 1e-3 then
		horizontal = flatAim
	else
		horizontal = horizontal.Unit
	end
	local baseElevation = math.atan2(baseVelocity.Y, math.max(1e-4, Vector3.new(baseVelocity.X, 0, baseVelocity.Z).Magnitude))
	local requestedDelta = math.rad(elevationDeltaDeg)
	if requestedDelta > 0 then
		requestedDelta = math.min(requestedDelta, math.rad(profile.maxLaunchElevationDeg) - baseElevation)
	else
		requestedDelta = math.max(requestedDelta, -math.pi * 0.5 - baseElevation)
	end
	local finalElevation = baseElevation + requestedDelta
	local finalDirection = (horizontal * math.cos(finalElevation) + UP_VECTOR * math.sin(finalElevation)).Unit
	return finalDirection * speed, curveForce
end

return table.freeze(AirLeanSolver)
