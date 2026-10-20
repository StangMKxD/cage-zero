--!strict
-- src/shared/Constants.luau
-- Authoritative constants and architectural guardrails for Cage Zero (Module 00)

local Constants = {
	-- Strict Anti-Drift & Anti-Hallucination Guardrails (Section 1)
	ALLOW_PLAYER_AVATAR_MODELS = false,
	ALLOW_BOOTS_OR_CLEATS_SYSTEM = false,
	ALLOW_MUTATION_COMBAT_STATS = false,

	-- Single Standard Custom R6 Rig Defaults (Module 00)
	CUSTOM_RIG_MODEL_NAME = "CageZeroStandardR6Rig",
	RIG_PROFILE = "R6",
	RIG_SCHEMA_VERSION = 1,
	IS_STANDARD_CUSTOM_RIG = true,
	USES_PLAYER_AVATAR = false,
	DEFAULT_HIP_HEIGHT = 0.0,
	ANIME_FACE_DECAL_ID = "rbxassetid://144075659",
	DEFAULT_CARD_ID = "Ronan_TierB",
	MIN_HEIGHT_SCALE = 0.85,
	MAX_HEIGHT_SCALE = 1.15,
	DEFAULT_HEIGHT_SCALE = 1.00,
	DEFAULT_WIDTH_SCALE = 1.00,
	DEFAULT_HEAD_SCALE = 1.00,
	DEFAULT_DEPTH_SCALE = 1.00,
	DEFAULT_PROPORTION_SCALE = 0.00,

	-- Explicit Floor & Spawn Anchors (Module 00 Seam to 01)
	PRIMARY_FLOOR_PATH = "Workspace.BootstrapTestFloor",
	PRIMARY_SPAWN_PATH = "Workspace.BootstrapSpawnLocation",
	FALLBACK_FLOOR_PATH = "Workspace.Baseplate",
	BOOTSTRAP_FLOOR_SIZE = Vector3.new(160, 2, 240),
	BOOTSTRAP_FLOOR_POSITION = Vector3.new(0, -1, 0),
	BOOTSTRAP_SPAWN_POSITION = Vector3.new(0, 5, 0),

	-- Archetype Height Scales (Section 4.4 Easter Egg Proportions)
	ARCHETYPE_HEIGHT_SCALES = table.freeze({
		Leon = 0.92,
		Ney = 0.98,
		Ronan = 1.03,
		Vandik = 1.08,
	}),

	-- Tier Constraints (Section 1 Rule 8 & Section 4.4)
	MAX_CARD_STAT_DIFFERENCE_RATIO = 0.15,
	MAX_WIN_CUTSCENES_BY_TIER = table.freeze({
		B = 1,
		A = 2,
		S = 3,
	}),

	-- Hex-Cage Arena & Physics Parameters (Section 4.1 & 4.2)
	BUMPER_RESTITUTION = 1.25,
	GOAL_BACK_ZONE_STUDS = 14,
	ELEVATING_RAMP_ANGLE_DEG = 25,
	MATCH_EVENT_INTERVAL_SEC = 90,
	MATCH_EVENT_DURATION_SEC = 40,
	PILLAR_WARNING_LEAD_SEC = 1.5,

	-- Duel & Parry Parameters (Section 1 Rules 6-7 & Section 4.3)
	CHOICE_DUEL_TRIGGER_DISTANCE_STUDS = 6.0,
	CHOICE_DUEL_DEFAULT_WINDOW_SEC = 0.80,
	CHOICE_DUEL_MISTAKE_WINDOW_SEC = 0.45,
	PARRY_INTERCEPT_RADIUS_STUDS = 5.0,
	PARRY_WINDOW_DURATION_SEC = 0.35,
	PARRY_MISS_RECOVERY_SEC = 0.50,
	STAMINA_EXHAUSTED_THRESHOLD = 0.15,

	-- Economy, Gacha & Trading Parameters (Section 4.6 & 4.7)
	GACHA_PITY_LIMIT = 100,
	MUTATION_CASH_MULTIPLIER_MIN = 1.5,
	MUTATION_CASH_MULTIPLIER_MAX = 5.0,
	MUTATION_EXP_MULTIPLIER_MIN = 1.5,
	MUTATION_EXP_MULTIPLIER_MAX = 3.0,
	TRADE_CONFIRM_COUNTDOWN_SEC = 3.0,
	MAX_BOOTH_SLOTS = 6,
}

return table.freeze(Constants)
