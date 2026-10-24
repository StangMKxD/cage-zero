--!strict
--[[
    AirLeanConfigs.luau
    Authoritative configuration for airborne body lean and trajectory deflection.
    Governed by: docs/plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md §12.5–12.6, §14.3
]]

export type AirLeanConfigType = {
    MAX_PITCH_DEG: number,
    MAX_ROLL_DEG: number,
    MAX_SLEW_DEG_PER_SEC: number,
    RATE_LIMIT_HZ: number,
    MIN_UPDATE_INTERVAL: number,
    MAX_DEFLECTION_CONE_DEG: number,
    MAX_EXTRA_CURVE_FORCE: number,
    ENERGY_BOOST_CAP: number,
	CONTACT_LEAN_PROFILES: { [string]: {
		maxBackwardLoftDeg: number,
		maxForwardLoweringDeg: number,
		maxLaunchElevationDeg: number,
	} },
}

local AirLeanConfigs: AirLeanConfigType = {
    -- Maximum angular tilt of character torso
    MAX_PITCH_DEG = 20.0,
    MAX_ROLL_DEG = 20.0,
    MAX_SLEW_DEG_PER_SEC = 120.0,

    -- Network protocol & rate validation
    RATE_LIMIT_HZ = 20,
    MIN_UPDATE_INTERVAL = 0.045, -- 1.0 / 22 to tolerate jitter

    -- Trajectory deflection parameters (Owner Delta §14.3: max extra cone <= 5 deg)
    MAX_DEFLECTION_CONE_DEG = 5.0,
    MAX_EXTRA_CURVE_FORCE = 6.0,  -- Bounded physical spin drift acceleration (studs/s²)
    ENERGY_BOOST_CAP = 1.0,       -- Strict energy conservation (final speed == kickSpeed)

	-- Modest shot-posture coupling. These caps adjust elevation while preserving
	-- horizontal aim and launch speed; body pose determines the signed weight.
	CONTACT_LEAN_PROFILES = table.freeze({
		DirectShoot = table.freeze({ maxBackwardLoftDeg = 3.0, maxForwardLoweringDeg = 1.2, maxLaunchElevationDeg = 60.0 }),
		Volley = table.freeze({ maxBackwardLoftDeg = 3.5, maxForwardLoweringDeg = 1.5, maxLaunchElevationDeg = 62.0 }),
		Header = table.freeze({ maxBackwardLoftDeg = 2.0, maxForwardLoweringDeg = 0.8, maxLaunchElevationDeg = 58.0 }),
	}),
}

return table.freeze(AirLeanConfigs)
