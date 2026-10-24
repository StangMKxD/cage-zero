--!strict
-- src/shared/configs/SkillMoveConfigs.luau
-- Authoritative catalog and configuration for Module 03: Skill Moves & Defense
-- Governed by Spec 02 & docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/HANDOFF.md

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local Constants = require(Shared:WaitForChild("Constants"))

local SkillCatalog: { [Types.SkillMoveId]: Types.SkillMoveDefinition } = table.freeze({
	HeavyKnockOn = table.freeze({
		id = "HeavyKnockOn" :: Types.SkillMoveId,
		displayName = "Heavy Knock-On",
		starRating = 1,
		staminaCost = 0.15,
		cooldownSec = 0.0,
		commonRecoverySec = 0.0,
		totalDurationSec = 0.36,
		contactTimeSec = 0.12,
		ballImpulseMagnitude = 45.0,
		ballImpulseVertical = 1.0,
		playerVelocityBurst = 22.0,
		burstDurationSec = 0.18,
		retreatSpeed = 0,
		directionPolicy = "Forward",
		neutralSide = 1,
		contactStages = table.freeze({ { time = 0.12, lateral = 0, forward = 1, vertical = 0 } }),
		description = "Knocks the ball far into open space ahead while player takes a brief short step forward without chasing all the way to the ball.",
	}),

	OpenUpFakeShot = table.freeze({
		id = "OpenUpFakeShot" :: Types.SkillMoveId,
		displayName = "Open Up Fake Shot",
		starRating = 1,
		staminaCost = 0.16,
		cooldownSec = 0.0,
		commonRecoverySec = 0.0,
		totalDurationSec = 0.38,
		contactTimeSec = 0.16,
		ballImpulseMagnitude = 22.0,
		ballImpulseVertical = 0.8,
		playerVelocityBurst = 20.0,
		burstDurationSec = 0.22,
		retreatSpeed = 0,
		directionPolicy = "LateralCut",
		neutralSide = 1,
		contactStages = table.freeze({
			{ time = 0.16, lateral = 0.70, forward = 0.70, vertical = 0 },
		}),
		description = "Readable strike windup feint checking into open hips, cushioning the ball diagonally forward with a short following step.",
	}),

	BodyFeint = table.freeze({
		id = "BodyFeint" :: Types.SkillMoveId,
		displayName = "Body Feint",
		starRating = 2,
		staminaCost = 0.18,
		cooldownSec = 0.0,
		commonRecoverySec = 0.0,
		totalDurationSec = 0.36,
		contactTimeSec = 0.18,
		ballImpulseMagnitude = 22.0,
		ballImpulseVertical = 0.5,
		playerVelocityBurst = 20.0,
		burstDurationSec = 0.22,
		retreatSpeed = 0,
		directionPolicy = "LateralCut",
		neutralSide = 1,
		contactStages = table.freeze({
			{ time = 0.18, lateral = 0.85, forward = 0.35, vertical = 0 },
		}),
		description = "Drops shoulder sharply in the false direction while ball stays near feet, then shifts weight and cuts into opposite exit with a short step.",
	}),

	HeelChop = table.freeze({
		id = "HeelChop" :: Types.SkillMoveId,
		displayName = "Heel Chop",
		starRating = 3,
		staminaCost = 0.22,
		cooldownSec = 0.0,
		commonRecoverySec = 0.0,
		totalDurationSec = 0.36,
		contactTimeSec = 0.14,
		ballImpulseMagnitude = 26.0,
		ballImpulseVertical = 0.4,
		playerVelocityBurst = 0.0,
		burstDurationSec = 0.0,
		retreatSpeed = 0,
		directionPolicy = "LateralCut",
		neutralSide = 1,
		contactStages = table.freeze({
			{ time = 0.14, lateral = 1.0, forward = 0.10, vertical = 0 },
		}),
		description = "Grounded cross-foot cut without jumping: contacting foot hooks behind support leg to chop ball laterally beside the body while player maintains balance.",
	}),

	LaneChange = table.freeze({
		id = "LaneChange" :: Types.SkillMoveId,
		displayName = "Lane Change",
		starRating = 4,
		staminaCost = 0.26,
		cooldownSec = 0.0,
		commonRecoverySec = 0.0,
		totalDurationSec = 0.34,
		contactTimeSec = 0.12,
		ballImpulseMagnitude = 26.0,
		ballImpulseVertical = 0.8,
		playerVelocityBurst = 22.0,
		burstDurationSec = 0.22,
		retreatSpeed = 0,
		directionPolicy = "LateralCut",
		neutralSide = 1,
		contactStages = table.freeze({
			{ time = 0.12, lateral = 0.85, forward = 0.30, vertical = 0 },
		}),
		description = "Rapid double-touch glide across the defender's tackle radius into an adjacent open running lane.",
	}),

	SombreroFlick = table.freeze({
		id = "SombreroFlick" :: Types.SkillMoveId,
		displayName = "Sombrero Flick",
		starRating = 4,
		staminaCost = 0.28,
		cooldownSec = 0.0,
		commonRecoverySec = 0.0,
		totalDurationSec = 0.55,
		contactTimeSec = 0.15,
		ballImpulseMagnitude = 14.0,
		ballImpulseVertical = 38.0,
		playerVelocityBurst = 18.0,
		burstDurationSec = 0.30,
		retreatSpeed = 0,
		directionPolicy = "LiftForward",
		neutralSide = 1,
		contactStages = table.freeze({ { time = 0.15, lateral = 0, forward = 1, vertical = 1 } }),
		description = "Flicks ball in an airborne parabolic arc over defender's head while moving forward to collect.",
	}),

	Elastico = table.freeze({
		id = "Elastico" :: Types.SkillMoveId,
		displayName = "Elastico",
		starRating = 5,
		staminaCost = 0.32,
		cooldownSec = 0.0,
		commonRecoverySec = 0.0,
		totalDurationSec = 0.44,
		contactTimeSec = 0.12,
		ballImpulseMagnitude = 26.0,
		ballImpulseVertical = 0.8,
		playerVelocityBurst = 22.0,
		burstDurationSec = 0.22,
		retreatSpeed = 0,
		directionPolicy = "LateralCut",
		neutralSide = 1,
		contactStages = table.freeze({
			{ time = 0.12, lateral = 0.50, forward = 0.10, vertical = 0 },
			{ time = 0.24, lateral = -0.90, forward = 0.40, vertical = 0 },
		}),
		description = "Continuous two-touch flip-flap using the same foot: outside touch draws defender, followed immediately by an inside instep snap across with a short exit step.",
	}),
})

local DefenseCatalog: { [Types.TackleActionType]: Types.TackleDefinition } = table.freeze({
	Poke = table.freeze({
		action = "Poke" :: Types.TackleActionType,
		displayName = "Quick Poke",
		reachStuds = Constants.POKE_TACKLE_REACH or 4.5,
		staminaCost = Constants.POKE_TACKLE_STAMINA_COST or 0.10,
		cooldownSec = Constants.POKE_TACKLE_COOLDOWN_SEC or 1.0,
		windupSec = 0.08,
		activeDurationSec = Constants.POKE_TACKLE_DURATION_SEC or 0.28,
		recoverySec = Constants.POKE_TACKLE_RECOVERY_SEC or 0.20,
		whiffRecoverySec = 0.25,
		slowMultiplier = nil,
		slowDurationSec = nil,
	}),

	CagePress = table.freeze({
		action = "CagePress" :: Types.TackleActionType,
		displayName = "Cage Press",
		reachStuds = Constants.CAGE_PRESS_REACH,
		staminaCost = Constants.CAGE_PRESS_STAMINA_COST,
		cooldownSec = Constants.CAGE_PRESS_COOLDOWN_SEC,
		windupSec = 0.04,
		activeDurationSec = Constants.CAGE_PRESS_DURATION_SEC,
		recoverySec = Constants.CAGE_PRESS_MISS_RECOVERY_SEC,
		whiffRecoverySec = Constants.CAGE_PRESS_MISS_RECOVERY_SEC,
		slowMultiplier = Constants.CAGE_PRESS_OPEN_FIELD_SLOW_MULTIPLIER,
		slowDurationSec = Constants.CAGE_PRESS_OPEN_FIELD_SLOW_SEC,
	}),

	Slide = table.freeze({
		action = "Slide" :: Types.TackleActionType,
		displayName = "Slide Tackle",
		reachStuds = Constants.SLIDE_TACKLE_REACH or 8.5,
		staminaCost = Constants.SLIDE_STAMINA_COST or 0.25,
		cooldownSec = Constants.SLIDE_COOLDOWN_SEC or 1.05,
		windupSec = 0.05,
		activeDurationSec = Constants.SLIDE_DURATION_SEC or 0.44,
		recoverySec = Constants.SLIDE_RECOVERY_SEC or 0.35,
		whiffRecoverySec = Constants.WHIFF_RECOVERY_SEC or 0.35,
		slowMultiplier = nil,
		slowDurationSec = nil,
	}),
})

local DEFAULT_STARTER_LOADOUT: Types.PlayerSkillLoadout = table.freeze({
	slot1 = "HeavyKnockOn",
	slot2 = "BodyFeint",
	slot3 = "SombreroFlick",
})

local SkillMoveConfigs = {
	Catalog = SkillCatalog,
	DefenseCatalog = DefenseCatalog,
	DEFAULT_LOADOUT = DEFAULT_STARTER_LOADOUT,
	MAX_SLOTS = 3,
	STARTER_CEILING_STARS = 5,
}

-- Resolve A/D movement in the player's character frame. Neutral input follows
-- each move's authored side; lifting/forward policies never become lateral.
function SkillMoveConfigs.ResolveCharacterRelativeDirection(
	skillDef: Types.SkillMoveDefinition,
	requestedDirection: Vector3,
	moveDirection: Vector3,
	rootCFrame: CFrame
): (Vector3, number)
	local forward = Vector3.new(rootCFrame.LookVector.X, 0, rootCFrame.LookVector.Z)
	forward = if forward.Magnitude > 0.05 then forward.Unit else Vector3.new(0, 0, -1)
	local right = Vector3.new(-forward.Z, 0, forward.X)
	local intent = Vector3.new(moveDirection.X, 0, moveDirection.Z)
	if intent.Magnitude < 0.05 then intent = Vector3.new(requestedDirection.X, 0, requestedDirection.Z) end
	local side = skillDef.neutralSide
	if intent.Magnitude >= 0.05 then
		local lateral = intent.Unit:Dot(right)
		if math.abs(lateral) >= 0.15 then side = if lateral < 0 then -1 else 1 end
	end
	return forward, side
end

function SkillMoveConfigs.GetSkill(skillId: string): Types.SkillMoveDefinition?
	return SkillCatalog[skillId :: Types.SkillMoveId]
end

function SkillMoveConfigs.GetDefenseAction(action: string): Types.TackleDefinition?
	return DefenseCatalog[action :: Types.TackleActionType]
end

function SkillMoveConfigs.ValidateLoadout(loadout: Types.PlayerSkillLoadout, playerStars: number?): (boolean, string?)
	local stars = playerStars or SkillMoveConfigs.STARTER_CEILING_STARS
	local s1 = SkillCatalog[loadout.slot1]
	local s2 = SkillCatalog[loadout.slot2]
	local s3 = SkillCatalog[loadout.slot3]

	if not s1 or not s2 or not s3 then
		return false, "InvalidSkillId"
	end
	if s1.starRating > stars or s2.starRating > stars or s3.starRating > stars then
		return false, "ExceedsStarCeiling"
	end
	-- Check for duplicate skills across slots
	if loadout.slot1 == loadout.slot2 or loadout.slot1 == loadout.slot3 or loadout.slot2 == loadout.slot3 then
		return false, "DuplicateEquippedSkill"
	end
	return true, nil
end

return table.freeze(SkillMoveConfigs)
