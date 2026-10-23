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
    Pitch tilts forward (+X in Motor6D Part0), Roll tilts laterally (Z axis).
]=]
function AirLeanSolver.ComputeLeanCFrame(leanForward: number, leanRight: number): CFrame
    local pitchRad, rollRad = AirLeanSolver.ComputeLeanAngles(leanForward, leanRight)
    -- Rotation: Pitch forward tilts around local X axis; Roll right tilts around local Z axis
    return CFrame.Angles(pitchRad, 0, -rollRad)
end

--[=[
    Calculates deterministic launch velocity and angular spin deflection for airborne shots.
    Takes the locked takeoff horizontal azimuth F0, camera elevation angle, base shot velocities,
    and accepted lean snapshot.
]=]
function AirLeanSolver.ComputeAirShotTrajectory(
    baseAzimuthF0: Vector3,
    cameraElevationAngle: number,
    basePower: number,
    baseVerticalPower: number,
    leanForward: number?,
    leanRight: number?,
    actionType: string?
): (Vector3, Vector3)
    local f, r = AirLeanSolver.ClampLeanInput(leanForward, leanRight)

    -- Normalize horizontal F0 (ensure valid unit vector)
    local flatF0 = Vector3.new(baseAzimuthF0.X, 0, baseAzimuthF0.Z)
    local F0 = if flatF0.Magnitude > 0.001 then flatF0.Unit else Vector3.new(0, 0, -1)
    local R0 = F0:Cross(UP_VECTOR).Unit

    -- Elevation bounded between -35 deg and +45 deg
    local cleanElevation = math.clamp(cameraElevationAngle, math.rad(-35.0), math.rad(45.0))

    -- Neutral lean fast-path: exact base trajectory without extra modification
    if math.abs(f) < 0.001 and math.abs(r) < 0.001 then
        local baseDir = (F0 * math.cos(cleanElevation) + UP_VECTOR * math.sin(cleanElevation)).Unit
        local baseVelocity = baseDir * basePower + UP_VECTOR * baseVerticalPower
        return baseVelocity, Vector3.zero
    end

    -- 1. Pitch modifies launch elevation angle
    local elevationOffset = math.rad(f * AirLeanConfigs.MAX_ELEVATION_DEFLECTION_DEG)
    local effectiveElevation = math.clamp(cleanElevation + elevationOffset, math.rad(-45.0), math.rad(55.0))

    -- 2. Base directed launch vector from effective elevation
    local baseDir = (F0 * math.cos(effectiveElevation) + UP_VECTOR * math.sin(effectiveElevation)).Unit
    local baseVelocity = baseDir * basePower + UP_VECTOR * baseVerticalPower

    -- 3. Roll imparts lateral tangential impulse along R0 (Right vector)
    local lateralMag = math.clamp(
        r * basePower * AirLeanConfigs.LATERAL_IMPULSE_RATIO,
        -AirLeanConfigs.MAX_LATERAL_DEFLECTION_STUDS,
        AirLeanConfigs.MAX_LATERAL_DEFLECTION_STUDS
    )
    local lateralImpulse = R0 * lateralMag

    local rawVelocity = baseVelocity + lateralImpulse

    -- 4. Energy Conservation Cap (prevents exploit power boosting)
    local maxSpeed = math.max(baseVelocity.Magnitude, basePower) * AirLeanConfigs.ENERGY_BOOST_CAP
    local finalVelocity = if rawVelocity.Magnitude > maxSpeed
        then rawVelocity.Unit * maxSpeed
        else rawVelocity

    -- 5. Physical Spin Deflection
    -- Rolling right induces clockwise curve (negative yaw spin); rolling left induces counter-clockwise curve
    local yawSpin = -r * AirLeanConfigs.SPIN_DEFLECTION_RAD_S
    -- Pitching forward induces topspin (curves downward); pitching back induces backspin (floats)
    local pitchSpin = f * (AirLeanConfigs.SPIN_DEFLECTION_RAD_S * 0.6)
    local finalSpin = Vector3.new(0, yawSpin, 0) + R0 * pitchSpin

    return finalVelocity, finalSpin
end

return table.freeze(AirLeanSolver)
