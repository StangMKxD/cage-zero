--!strict
--[[
    JumpModel.luau
    Pure deterministic model for state-based momentum jump FSM and soft apex quality.
    Governed by: docs/plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md §15
]]

local JumpConfigs = require(script.Parent.configs.JumpConfigs)
local Types = require(script.Parent.Types)

local JumpModel = {}

--[=[
    Calculates expected apex height and time given initial vertical speed and gravity.
]=]
function JumpModel.CalculateExpectedApex(v0: number?, g: number?): (number, number)
    local initialV = v0 or JumpConfigs.VERTICAL_LAUNCH_SPEED
    local grav = g or JumpConfigs.GRAVITY
    if grav <= 0.001 then
        return 15.5, 0.4
    end
    local tApex = initialV / grav
    local hApex = (initialV * initialV) / (2.0 * grav)
    return hApex, tApex
end

--[=[
    Calculates continuous, bounded soft quality multiplier [0.90, 1.00].
    Rewards near-apex timing without hard-gating any phase.
]=]
function JumpModel.CalculateSoftQuality(
    timeSinceTakeoff: number,
    currentVY: number,
    v0: number?,
    g: number?
): number
    local _, tApex = JumpModel.CalculateExpectedApex(v0, g)
    if tApex <= 0.001 then
        return 1.0
    end

    local dtApex = math.abs(timeSinceTakeoff - tApex)
    local proximity = math.clamp(1.0 - (dtApex / tApex), 0.0, 1.0)
    local quality = JumpConfigs.APEX_QUALITY_MIN + proximity * (JumpConfigs.APEX_QUALITY_MAX - JumpConfigs.APEX_QUALITY_MIN)
    return math.clamp(quality, JumpConfigs.APEX_QUALITY_MIN, JumpConfigs.APEX_QUALITY_MAX)
end

--[=[
    Determines flight FSM state based on vertical velocity, time elapsed, and ground contact.
]=]
function JumpModel.ResolveFlightState(
    vy: number,
    timeSinceTakeoff: number,
    hasLeftGround: boolean,
    isGrounded: boolean
): Types.FlightState
    if isGrounded and (timeSinceTakeoff > 0.15 or hasLeftGround) then
        return "Landed"
    end
    if timeSinceTakeoff < 0.04 then
        return "Takeoff"
    end
    if vy > 2.5 then
        return "Rising"
    elseif math.abs(vy) <= 2.5 then
        return "Apex"
    else
        return "Falling"
    end
end

--[=[
    Calculates the instantaneous impulse needed to achieve target launch velocity.
]=]
function JumpModel.CalculateLaunchImpulse(
    currentVelocity: Vector3,
    targetHorizontalVelocity: Vector3,
    verticalSpeed: number?,
    totalMass: number
): Vector3
    local vyTarget = verticalSpeed or JumpConfigs.VERTICAL_LAUNCH_SPEED
    local targetVel = Vector3.new(targetHorizontalVelocity.X, vyTarget, targetHorizontalVelocity.Z)
    local deltaVel = targetVel - currentVelocity
    return deltaVel * totalMass
end

--[=[
    Calculates initial 3D launch velocity for BallPop from grounded possessor (Owner Delta § 16.2).
    Height reference: current character jump apex height H = v0^2 / (2 * gChar) under ball gravity gBall.
    ballVy = sqrt(2 * gBall * H). Idle pop is nearly straight up from existing ball position.
]=]
function JumpModel.CalculateBallPopLaunchVelocity(
    moveDirection: Vector3?,
    isSprinting: boolean?,
    ballGravity: number?,
    charGravity: number?,
    charJumpV0: number?,
    walkSpeed: number?,
    sprintSpeed: number?
): Vector3
    local gChar = charGravity or JumpConfigs.GRAVITY
    local v0Char = charJumpV0 or JumpConfigs.VERTICAL_LAUNCH_SPEED
    local hApex = (v0Char * v0Char) / (2.0 * math.max(0.01, gChar))

    local gBall = math.abs(ballGravity or -65.0)
    local ballVy = math.sqrt(2.0 * gBall * hApex)

    local rawDir = moveDirection or Vector3.zero
    local flatDir = Vector3.new(rawDir.X, 0, rawDir.Z)
    if flatDir.Magnitude < (JumpConfigs.BALL_POP_MIN_MOVE_THRESHOLD or 0.08) then
        return Vector3.new(0, ballVy, 0)
    end

    local dirUnit = flatDir.Unit
    local ws = walkSpeed or 20.0
    local ss = sprintSpeed or 24.0
    local speed = if isSprinting then ss else ws

    return Vector3.new(dirUnit.X * speed, ballVy, dirUnit.Z * speed)
end

return table.freeze(JumpModel)
