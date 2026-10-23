--!strict
--[[
    JumpConfigs.luau
    Authoritative configuration for state-based momentum jump and soft apex timing.
    Governed by: docs/plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md §15
]]

export type JumpConfigType = {
    VERTICAL_LAUNCH_SPEED: number,
    GRAVITY: number,
    EXPECTED_APEX_HEIGHT: number,
    EXPECTED_APEX_TIME: number,
    LANDING_LAG_SEC: number,
    APEX_QUALITY_MIN: number,
    APEX_QUALITY_MAX: number,
    APEX_TIME_WINDOW_SEC: number,
    AIR_OFFENSIVE_BUDGET_PER_FLIGHT: number,
    RECENT_GROUND_TOLERANCE_SEC: number,
    BALL_POP_REPOSSESS_COOLDOWN_SEC: number,
    BALL_POP_MIN_MOVE_THRESHOLD: number,
}

local JumpConfigs: JumpConfigType = {
    -- Vertical launch speed: 78.0 studs/s gives ~15.5 studs apex under 196.2 gravity
    VERTICAL_LAUNCH_SPEED = 78.0,
    GRAVITY = 196.2,
    EXPECTED_APEX_HEIGHT = 15.5,
    EXPECTED_APEX_TIME = 0.398, -- 78.0 / 196.2

    -- Landing recovery / jump debounce (not walking stun)
    LANDING_LAG_SEC = 0.08,

    -- Soft apex quality multiplier [0.90, 1.00]
    APEX_QUALITY_MIN = 0.90,
    APEX_QUALITY_MAX = 1.00,
    APEX_TIME_WINDOW_SEC = 0.12,

    -- Offensive actions budget: 1 valid release (Direct/Volley/Pass) per flight
    AIR_OFFENSIVE_BUDGET_PER_FLIGHT = 1,

    -- Bounded recent-ground validation for client prediction reconciliation
    RECENT_GROUND_TOLERANCE_SEC = 0.12,

    -- Owner Delta § 16: Grounded possessor BallPop parameters
    BALL_POP_REPOSSESS_COOLDOWN_SEC = 0.35,
    BALL_POP_MIN_MOVE_THRESHOLD = 0.08,
}

return table.freeze(JumpConfigs)
