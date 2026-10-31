--!strict
-- src/shared/configs/SprintConfigs.luau
-- Authoritative Configuration for R15 Sprint Mechanics & Run Animation Integration
-- Governed by RF02-IDLE-RUNTIME Contract (Latest Owner Override 2026-10-26)

export type SprintConfig = {
	NORMAL_WALK_SPEED: number,
	SPRINT_SPEED: number,
	DIAGONAL_SPEED: number,
	REVERSE_SPEED: number,
	TURN_HOLD_SEC: number,
	TURN_MEMORY_SEC: number,
	RECOVERY_PER_SEC: number,
	START_RATE_LIMIT_INTERVAL_SEC: number,
	SPRINT_KEY_CODES: { Enum.KeyCode },
}

local SprintConfigs = {}

SprintConfigs.NORMAL_WALK_SPEED = 16.0
SprintConfigs.SPRINT_SPEED = 32.0
SprintConfigs.DIAGONAL_SPEED = 28.8
SprintConfigs.REVERSE_SPEED = 25.92
-- SprintConfigs.TURN_HOLD_SEC = 0.3 -- Previous Owner tuning.
SprintConfigs.TURN_HOLD_SEC = 0.7
SprintConfigs.TURN_MEMORY_SEC = 0.3 -- Remember a brief key-up gap before the next direction.
SprintConfigs.RECOVERY_PER_SEC = 32.0 -- Smooth return after the Owner-selected hold.
SprintConfigs.START_RATE_LIMIT_INTERVAL_SEC = 0.05

-- Owner Override: hold LeftShift / RightShift to sprint.
-- Dual-key tracking: releasing one Shift while other remains held preserves sprinting.
SprintConfigs.SPRINT_KEY_CODES = table.freeze({
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.RightShift,
})

return table.freeze(SprintConfigs)

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

SprintConfigs.SPRINT_SPEED = 32.0
]====]

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

	OTHER_DIRECTION_SPEED: number,

-- Previous section --
SprintConfigs.SPRINT_SPEED = 28.8
SprintConfigs.OTHER_DIRECTION_SPEED = 25.92 -- Initial Owner-review tuning for side/back movement.
]====]
