--!strict
--[[
    JumpConfigs.luau
    Authoritative configuration for state-based momentum jump, soft apex timing, and four-way air lean.
    Governed by: docs/plan/phase-01-gameplay-demo/release-first/assets/dribble-receive-HANDOFF.md (Owner Additive Scope & Review026)
]]

export type JumpConfigType = {
    -- High Momentum Jump Parameters
    JUMP_POWER: number,
    VERTICAL_LAUNCH_SPEED: number,
    GRAVITY: number,
    EXPECTED_APEX_HEIGHT: number,
    EXPECTED_APEX_TIME: number,
    LANDING_LAG_SEC: number,
    JUMP_BUFFER_WINDOW_SEC: number,
    LEDGE_FALL_MAX_INITIAL_VY: number,

    -- Horizontal Momentum
    HORIZONTAL_MOMENTUM_RATIO: number,
    MAX_AIR_HORIZONTAL_SPEED: number,

    -- Soft Apex Kinematics
    APEX_SOFT_ZONE_VY_MIN: number,
    APEX_SOFT_ZONE_VY_MAX: number,
    APEX_GRAVITY_DAMPING: number,
    APEX_SOFT_MAX_DURATION: number,
    APEX_QUALITY_MIN: number,
    APEX_QUALITY_MAX: number,
    APEX_TIME_WINDOW_SEC: number,

    -- Four-Way Air Lean Overlay
    LEAN_MAX_PITCH_DEG: number,
    LEAN_MAX_ROLL_DEG: number,
    LEAN_LERP_SPEED: number,
    LEAN_RETURN_SPEED: number,

    -- Server Flight Envelope & Yaw Validation
    SERVER_YAW_TOLERANCE_DEG: number,
    TAKEOFF_YAW_SETTLE_WINDOW_SEC: number,
    TAKEOFF_VELOCITY_BLEND_SEC: number,
    TAKEOFF_YAW_CATCHUP_MAX_SEC: number,
    CLIENT_YAW_LOCK_DEADBAND_RAD: number,
    SERVER_VERTICAL_SPEED_TOLERANCE: number,
    SERVER_VERTICAL_POSITION_TOLERANCE: number,
    SERVER_FLIGHT_CLOCK_SKEW_SEC: number,
    SERVER_POSITION_TOLERANCE: number,
    SERVER_MAX_FLIGHT_DURATION_SEC: number,

    -- Air Actions & BallPop
    AIR_OFFENSIVE_BUDGET_PER_FLIGHT: number,
    RECENT_GROUND_TOLERANCE_SEC: number,
    BALL_POP_REPOSSESS_COOLDOWN_SEC: number,
    BALL_POP_MIN_MOVE_THRESHOLD: number,
}

local JumpConfigs: JumpConfigType = {
    -- High Momentum Jump: Provisional JumpPower = 72 giving ~13.2 studs base apex (~15.5 studs with soft apex) under 196.2 gravity
    JUMP_POWER = 72.0,
    VERTICAL_LAUNCH_SPEED = 72.0,
    GRAVITY = 196.2,
    EXPECTED_APEX_HEIGHT = 13.2,
    EXPECTED_APEX_TIME = 0.367, -- 72.0 / 196.2

    -- Bounded jump input buffer for tap/landing-edge responsiveness without duplicate jumps
    JUMP_BUFFER_WINDOW_SEC = 0.14,
    -- Initial upward velocity threshold distinguishing coalesced Freefall jump liftoff from passive ledge fall
    LEDGE_FALL_MAX_INITIAL_VY = 15.0,

    -- Horizontal Momentum: 100% of takeoff horizontal speed preserved in takeoff movement heading
    HORIZONTAL_MOMENTUM_RATIO = 1.0,
    MAX_AIR_HORIZONTAL_SPEED = 32.0,

    -- Soft Apex: Gradual vertical deceleration approaching apex (smooth hang time)
    APEX_SOFT_ZONE_VY_MIN = -6.0,
    APEX_SOFT_ZONE_VY_MAX = 14.0,
    APEX_GRAVITY_DAMPING = 0.55, -- 55% gravity reduction during near-apex window (~88 studs/s² effective gravity)
    APEX_SOFT_MAX_DURATION = 0.16,

    -- Landing recovery / jump debounce (not walking stun)
    LANDING_LAG_SEC = 0.08,

    -- Soft apex quality multiplier [0.90, 1.00]
    APEX_QUALITY_MIN = 0.90,
    APEX_QUALITY_MAX = 1.00,
    APEX_TIME_WINDOW_SEC = 0.12,

    -- Four-Way Air Lean: Visual pitch/roll tilt overlay based on flight movement input
    LEAN_MAX_PITCH_DEG = 15.0,
    LEAN_MAX_ROLL_DEG = 15.0,
    LEAN_LERP_SPEED = 14.0,
    LEAN_RETURN_SPEED = 18.0,

    -- Server Flight Envelope & Yaw Validation
    SERVER_YAW_TOLERANCE_DEG = 15.0,
    TAKEOFF_YAW_SETTLE_WINDOW_SEC = 0.10,
    -- Bounded-acceleration hand-off from actual ground velocity to the takeoff vector (no boost: speed never exceeds takeoffSpeed)
    TAKEOFF_VELOCITY_BLEND_SEC = 0.10,
    -- Replicated root yaw/position reach the server ~0.1-0.25s after the owning client liftoff; while the replicated yaw is still
    -- turning (ground turn in progress at liftoff) the server keeps adopting it, bounded by this absolute cap
    TAKEOFF_YAW_CATCHUP_MAX_SEC = 0.50,
    CLIENT_YAW_LOCK_DEADBAND_RAD = 0.015,
    SERVER_VERTICAL_SPEED_TOLERANCE = 12.0,
    SERVER_VERTICAL_POSITION_TOLERANCE = 4.0,
    -- Descent-only clock/replication skew: server liftoff timestamp and replicated root position are not
    -- time-aligned with the owning client; measured ~0.07-0.13s. Rising checks stay strict (see JumpService).
    SERVER_FLIGHT_CLOCK_SKEW_SEC = 0.15,
    -- Bounded slack for replication cadence and character collision correction.
    SERVER_POSITION_TOLERANCE = 2.0,
    SERVER_MAX_FLIGHT_DURATION_SEC = 2.5,

    -- Offensive actions budget: 1 valid release (Direct/Volley/Pass) per flight
    AIR_OFFENSIVE_BUDGET_PER_FLIGHT = 1,

    -- Bounded recent-ground validation for client prediction reconciliation
    RECENT_GROUND_TOLERANCE_SEC = 0.12,

    -- Owner Delta § 16: Grounded possessor BallPop parameters
    BALL_POP_REPOSSESS_COOLDOWN_SEC = 0.35,
    BALL_POP_MIN_MOVE_THRESHOLD = 0.08,
}

return table.freeze(JumpConfigs)
