--!strict
-- src/shared/configs/DribbleConfigs.luau
-- Authoritative Configuration for Ground Dribble & Receive Mechanics (RF02-DRIBBLE-RECEIVE)
-- Revised 2026-10-27 (Owner AUTHORITATIVE GRILL CONFIRMED):
-- 1. Moving ground lead follows MoveDirection; idle smoothly settles to body LookVector front.
-- 2. Bounded speed-related FORWARD radial micro-touches (zero lateral sway). Real-ball rolling.
-- 3. Sharp turns > 120 deg get configurable speed dip; no old touch-phase wait / no automatic loss.
-- 4. Successful upward jump while carrier triggers ONE self-lob scoop and clears possession atomically.
--    Former owner has brief recapture cooldown guard before standard ground receive applies.

export type DribbleConfig = {
	FREE_BALL_ONLY_MODE: boolean,

	-- Receive / steal gate (retained, honest eligibility)
	MAX_RECEIVE_DISTANCE: number,
	MAX_RECEIVE_VERTICAL_GAP: number,
	MAX_RECEIVE_RELATIVE_SPEED: number,
	GROUNDED_MAX_BALL_Y: number,
	PLAYER_GROUNDED_REQUIRED: boolean,

	-- Continuous front control (valid current carrier only)
	FRONT_DISTANCE_WALK: number,
	FRONT_DISTANCE_SPRINT: number,
	FRONT_RADIAL_GAIN: number,
	FRONT_RADIAL_MAX_SPEED: number,
	FRONT_ANGULAR_GAIN: number,
	FRONT_MAX_ANGULAR_SPEED: number,
	FRONT_MAX_REL_SPEED: number,
	MAX_BALL_DRIBBLE_SPEED: number,
	VISUAL_SNAPSHOT_MAX_AGE: number,

	-- Forward micro-touches (purely radial along lead direction, zero lateral sway)
	MICRO_TOUCH_ENABLED: boolean,
	MICRO_TOUCH_AMPLITUDE_WALK: number,
	MICRO_TOUCH_AMPLITUDE_SPRINT: number,
	MICRO_TOUCH_CADENCE_WALK: number,
	MICRO_TOUCH_CADENCE_SPRINT: number,

	-- Dribbling turn slow-down (carrier only, applied by client heading controller)
	DRIBBLE_TURN_RATE_RAD_PER_SEC: number,
	DRIBBLE_TURN_DIP_THRESHOLD_DEG: number,
	DRIBBLE_TURN_MIN_FACTOR_WALK: number,
	DRIBBLE_TURN_MIN_FACTOR_SPRINT: number,
	DRIBBLE_TURN_EXPONENT: number,
	DRIBBLE_TURN_RECOVERY_RATE: number,

	-- Jump Self-Lob (Scoop)
	SELF_LOB_ENABLED: boolean,
	SELF_LOB_UPWARD_SPEED: number,
	SELF_LOB_MIN_HORIZONTAL_SPEED: number,
	SELF_LOB_MOMENTUM_FACTOR: number,
	SELF_LOB_MAX_HORIZONTAL_SPEED: number,
	SELF_LOB_MIN_TAKEOFF_VY: number,
	SELF_LOB_RECAPTURE_COOLDOWN_SEC: number,

	-- Joint body + cage clearance
	CARRIER_BODY_RADIUS: number,
	BALL_COLLISION_RADIUS: number,
	MIN_BODY_SEPARATION_MARGIN: number,
	CARRIER_SEPARATION_DISTANCE: number,
	BODY_HEIGHT: number,
	BODY_CONTACT_RESTITUTION: number,
	MAX_OVERLAP_SEPARATION_STEP: number,
	OVERLAP_RECOVERY_PUSH_SPEED: number,
	FLANK_ANGLE_STEPS: number,
	BLOCKED_FLANK_ANGLE_DEG: number,
	BLOCKED_SPEED_FACTOR: number,
	INFEASIBLE_SPEED_FACTOR: number,

	-- Loose ball & dispossession
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
	FREE_BALL_ONLY_MODE = false,

	-- Reception gate
	MAX_RECEIVE_DISTANCE = 4.5,
	MAX_RECEIVE_VERTICAL_GAP = 2.2,
	MAX_RECEIVE_RELATIVE_SPEED = 38.0,
	GROUNDED_MAX_BALL_Y = 2.8,
	PLAYER_GROUNDED_REQUIRED = true,

	-- Desired ball center distance ahead of RootPart along LEAD DIRECTION (must exceed CARRIER_SEPARATION_DISTANCE)
	FRONT_DISTANCE_WALK = 2.75,
	FRONT_DISTANCE_SPRINT = 3.1,
	-- Polar front tracking around the carrier: radial pull toward front radius and
	-- bounded angular swing toward lead direction.
	FRONT_RADIAL_GAIN = 14.0,
	FRONT_RADIAL_MAX_SPEED = 30.0,
	FRONT_ANGULAR_GAIN = 25.0,
	FRONT_MAX_ANGULAR_SPEED = 14.0,
	-- Cap on ball speed RELATIVE to carrier (studs/s)
	FRONT_MAX_REL_SPEED = 48.0,
	-- Hard ball speed ceiling
	MAX_BALL_DRIBBLE_SPEED = 72.0,
	-- Discard prediction when authoritative ground control snapshots stop arriving.
	VISUAL_SNAPSHOT_MAX_AGE = 0.25,

	-- Forward micro-touches (purely radial, zero lateral sway)
	MICRO_TOUCH_ENABLED = true,
	MICRO_TOUCH_AMPLITUDE_WALK = 0.25,
	MICRO_TOUCH_AMPLITUDE_SPRINT = 0.40,
	MICRO_TOUCH_CADENCE_WALK = 2.5,
	MICRO_TOUCH_CADENCE_SPRINT = 4.0,

	-- CARRIER-ONLY body yaw rate while dribbling (rad/s). Non-carrier keeps accepted CameraPreviewConfigs rate (20).
	DRIBBLE_TURN_RATE_RAD_PER_SEC = 10.0,
	-- Dribbling turn values: turns > 120 deg get configurable short speed reduction; smooth recovery (3/s)
	DRIBBLE_TURN_DIP_THRESHOLD_DEG = 120.0,
	DRIBBLE_TURN_MIN_FACTOR_WALK = 0.60,
	DRIBBLE_TURN_MIN_FACTOR_SPRINT = 0.45,
	DRIBBLE_TURN_EXPONENT = 1.3,
	DRIBBLE_TURN_RECOVERY_RATE = 3.0,

	-- Jump Self-Lob (Scoop)
	SELF_LOB_ENABLED = true,
	SELF_LOB_UPWARD_SPEED = 24.0,
	SELF_LOB_MIN_HORIZONTAL_SPEED = 8.0,
	SELF_LOB_MOMENTUM_FACTOR = 1.05,
	SELF_LOB_MAX_HORIZONTAL_SPEED = 36.0,
	SELF_LOB_MIN_TAKEOFF_VY = 15.0,
	SELF_LOB_RECAPTURE_COOLDOWN_SEC = 0.60,

	-- Normalized rig assumptions (not measured per-part bounds)
	CARRIER_BODY_RADIUS = 1.25,
	BALL_COLLISION_RADIUS = 1.125,
	MIN_BODY_SEPARATION_MARGIN = 0.05,
	CARRIER_SEPARATION_DISTANCE = 2.425,
	-- Body vertical span: [feet, feet + BODY_HEIGHT], feet = RootPart.Y - PLAYER_FEET_OFFSET (shared origin)
	BODY_HEIGHT = 5.5,
	BODY_CONTACT_RESTITUTION = 0.15,
	MAX_OVERLAP_SEPARATION_STEP = 2.50,
	OVERLAP_RECOVERY_PUSH_SPEED = 8.0,
	-- Candidate angles on the clearance ring when searching a feasible flank
	FLANK_ANGLE_STEPS = 72,
	-- Front target deviating more than this from lead direction means front is obstructed: carrier is slowed
	BLOCKED_FLANK_ANGLE_DEG = 60.0,
	BLOCKED_SPEED_FACTOR = 0.5,
	-- No feasible ball position at all (carrier outside cage box etc.)
	INFEASIBLE_SPEED_FACTOR = 0.2,

	LOOSE_BALL_DISTANCE = 7.5,
	STEAL_INTERCEPT_DISTANCE = 3.8,
	STEAL_CONTEST_COOLDOWN_SEC = 0.40,
	STEAL_REENTRY_DISTANCE = 5.0,
	-- Root-to-foot vertical offset: single shared feet origin for receive, steal, front control and body span
	PLAYER_FEET_OFFSET = 2.8,
	MAX_RECEIVE_CUSHION_SPEED = 32.0,
	MIN_RECEIVE_CUSHION_SPEED = 8.0,
	MIN_STEAL_CUSHION_SPEED = 10.0,
	MOVE_DIRECTION_THRESHOLD = 0.05,
	MIN_PLAYER_MOVE_SPEED = 1.5,
	TARGET_DIRECTION_THRESHOLD = 0.1,
	CUSHION_DAMPING_RATE = 3.5,
	CUSHION_DAMPING_FACTOR = 0.65,

	MAX_DT_SIMULATION = 0.10,
	MAX_TELEPORT_DISPLACEMENT = 20.0,
}

return table.freeze(DribbleConfigs)
