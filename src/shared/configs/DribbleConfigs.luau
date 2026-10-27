--!strict
-- src/shared/configs/DribbleConfigs.luau
-- Authoritative Configuration for Ground Dribble & Receive Mechanics (RF02-DRIBBLE-RECEIVE)
-- Governed by RF02-DRIBBLE-RECEIVE Contract (Owner Checklist 7, 2026-10-26 & Review026)

export type DribbleConfig = {
	-- Mode Toggles
	FREE_BALL_ONLY_MODE: boolean,

	-- Receive Gate Parameters
	MAX_RECEIVE_DISTANCE: number,
	MAX_RECEIVE_VERTICAL_GAP: number,
	MAX_RECEIVE_RELATIVE_SPEED: number,
	GROUNDED_MAX_BALL_Y: number,
	PLAYER_GROUNDED_REQUIRED: boolean,

	-- Dribble Touch Rhythm & Cadence
	TOUCH_COOLDOWN_NORMAL: number,
	TOUCH_COOLDOWN_SPRINT: number,

	-- Touch Impulses & Kinematics
	DRIBBLE_TOUCH_FORWARD_OFFSET: number,
	DRIBBLE_TOUCH_SPEED_WALK: number,
	DRIBBLE_TOUCH_SPEED_SPRINT: number,
	DRIBBLE_TOUCH_VERTICAL_IMPULSE: number,
	MAX_BALL_DRIBBLE_SPEED: number,

	-- Loose Ball & Dispossession Parameters
	LOOSE_BALL_DISTANCE: number,
	STEAL_INTERCEPT_DISTANCE: number,
	STEAL_CONTEST_COOLDOWN_SEC: number,
	STEAL_REENTRY_DISTANCE: number,
	PLAYER_FEET_OFFSET: number,
	MAX_RECEIVE_CUSHION_SPEED: number,
	MIN_RECEIVE_CUSHION_SPEED: number,
	MIN_STEAL_CUSHION_SPEED: number,
	MOVE_DIRECTION_THRESHOLD: number,
	MIN_PLAYER_MOVE_SPEED: number,
	TARGET_DIRECTION_THRESHOLD: number,
	CUSHION_DAMPING_RATE: number,
	CUSHION_DAMPING_FACTOR: number,

	-- Simulation Guardrails
	MAX_DT_SIMULATION: number,
	MAX_TELEPORT_DISPLACEMENT: number,
}

local DribbleConfigs: DribbleConfig = {
	-- When true, dribble/receive is completely bypassed and ball behaves purely as autonomous free ball
	FREE_BALL_ONLY_MODE = false,

	-- Reception Gate: Proximity & Relative Speed
	-- Ball must be within 4.5 studs horizontal reach of player root
	MAX_RECEIVE_DISTANCE = 4.5,
	-- Ball and feet vertical separation cannot exceed 2.2 studs
	MAX_RECEIVE_VERTICAL_GAP = 2.2,
	-- If ball relative speed to player exceeds 38 studs/s, it deflects/passes by and cannot be trapped
	MAX_RECEIVE_RELATIVE_SPEED = 38.0,
	-- Ball must be near ground (cannot receive airborne balls above 2.8 studs from ground in ground dribble)
	GROUNDED_MAX_BALL_Y = 2.8,
	-- Player must be grounded (not jumping or in freefall)
	PLAYER_GROUNDED_REQUIRED = true,

	-- Cadence between foot touches: walk touch rhythm vs sprint touch rhythm (seconds)
	TOUCH_COOLDOWN_NORMAL = 0.40,
	TOUCH_COOLDOWN_SPRINT = 0.28,

	-- Forward placement offset ahead of player's RootPart where ball is pushed
	DRIBBLE_TOUCH_FORWARD_OFFSET = 2.8,
	-- Velocity impulse imparted on ball during normal walk dribble (studs/s)
	DRIBBLE_TOUCH_SPEED_WALK = 18.5,
	-- Velocity impulse imparted on ball during sprint dribble (studs/s)
	DRIBBLE_TOUCH_SPEED_SPRINT = 33.0,
	-- Vertical micro-lift (kept minimal for pure ground roll)
	DRIBBLE_TOUCH_VERTICAL_IMPULSE = 0.0,
	-- Hard speed ceiling on ball dribble impulses to prevent physics explosions
	MAX_BALL_DRIBBLE_SPEED = 40.0,

	-- Distance beyond which carrier loses possession and ball becomes Free (studs)
	LOOSE_BALL_DISTANCE = 7.5,
	-- Distance where opponent can intercept / steal possession (studs)
	STEAL_INTERCEPT_DISTANCE = 3.8,
	-- Steal contest cooldown: prevents tick-by-tick ping-pong possession churn between overlapping players (seconds)
	STEAL_CONTEST_COOLDOWN_SEC = 0.40,
	-- Opponents must separate beyond this distance before the same pair can contest again.
	STEAL_REENTRY_DISTANCE = 5.0,
	-- Approximate root-to-foot vertical offset used by the contact window for the normalized R15 rig.
	PLAYER_FEET_OFFSET = 2.8,
	MAX_RECEIVE_CUSHION_SPEED = 32.0,
	MIN_RECEIVE_CUSHION_SPEED = 8.0,
	MIN_STEAL_CUSHION_SPEED = 10.0,
	MOVE_DIRECTION_THRESHOLD = 0.05,
	MIN_PLAYER_MOVE_SPEED = 1.5,
	TARGET_DIRECTION_THRESHOLD = 0.1,
	-- Damping rate per second applied when player idles within contact zone to cushion the ball (dt-independent)
	CUSHION_DAMPING_RATE = 3.5,
	-- Legacy cushion damping factor retained for backward compatibility with existing tests
	CUSHION_DAMPING_FACTOR = 0.65,

	-- Simulation safety bounds
	MAX_DT_SIMULATION = 0.10,
	MAX_TELEPORT_DISPLACEMENT = 20.0,
}

return table.freeze(DribbleConfigs)
