--!strict
--[[
    AirLeanConfigs.luau
    Authoritative configuration for airborne body lean and trajectory deflection.
    Governed by: docs/plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md §12.5–12.6
]]

export type AirLeanConfigType = {
    MAX_PITCH_DEG: number,
    MAX_ROLL_DEG: number,
    MAX_SLEW_DEG_PER_SEC: number,
    RATE_LIMIT_HZ: number,
    MIN_UPDATE_INTERVAL: number,
    MAX_ELEVATION_DEFLECTION_DEG: number,
    LATERAL_IMPULSE_RATIO: number,
    MAX_LATERAL_DEFLECTION_STUDS: number,
    SPIN_DEFLECTION_RAD_S: number,
    ENERGY_BOOST_CAP: number,
}

local AirLeanConfigs: AirLeanConfigType = {
    -- Maximum angular tilt of character torso
    MAX_PITCH_DEG = 20.0,
    MAX_ROLL_DEG = 20.0,
    MAX_SLEW_DEG_PER_SEC = 120.0,

    -- Network protocol & rate validation
    RATE_LIMIT_HZ = 20,
    MIN_UPDATE_INTERVAL = 0.045, -- 1.0 / 22 to tolerate jitter

    -- Trajectory deflection parameters
    MAX_ELEVATION_DEFLECTION_DEG = 12.0, -- Pitch deflection modifies launch angle
    LATERAL_IMPULSE_RATIO = 0.22,        -- Fraction of horizontal speed added tangentially along R0
    MAX_LATERAL_DEFLECTION_STUDS = 18.0, -- Maximum lateral velocity impulse (studs/s)
    SPIN_DEFLECTION_RAD_S = 18.0,        -- Additional spin induced around vertical / lateral axes
    ENERGY_BOOST_CAP = 1.05,             -- Maximum velocity magnitude factor (conserves energy)
}

return table.freeze(AirLeanConfigs)
