--!strict
-- src/shared/configs/SprintConfigs.luau
-- Authoritative Configuration for R15 Sprint Mechanics & Run Animation Integration
-- Governed by RF02-IDLE-RUNTIME Contract (Latest Owner Override 2026-10-26)

export type SprintConfig = {
	NORMAL_WALK_SPEED: number,
	SPRINT_SPEED: number,
	START_RATE_LIMIT_INTERVAL_SEC: number,
	SPRINT_KEY_CODES: { Enum.KeyCode },
}

local SprintConfigs = {}

SprintConfigs.NORMAL_WALK_SPEED = 16.0
SprintConfigs.SPRINT_SPEED = 32.0
SprintConfigs.START_RATE_LIMIT_INTERVAL_SEC = 0.05

-- Owner Override: hold LeftShift / RightShift to sprint.
-- Dual-key tracking: releasing one Shift while other remains held preserves sprinting.
SprintConfigs.SPRINT_KEY_CODES = table.freeze({
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.RightShift,
})

return table.freeze(SprintConfigs)
