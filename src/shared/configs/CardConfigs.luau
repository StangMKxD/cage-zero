--!strict
-- src/shared/configs/CardConfigs.luau
-- Module 04: Multi-Tier Player Cards, Custom R15 Scales, Cooldown-Gated Signature Choices & Tier-Capped Win Cutscenes

local Constants = require(script.Parent.Parent.Constants)
local Types = require(script.Parent.Parent.Types)

export type PlayerCardConfig = Types.PlayerCardConfig

local Cards: { [string]: PlayerCardConfig } = {
	Ronan_TierB = {
		cardId = "Ronan_TierB",
		displayName = "Young Ronan",
		archetypeName = "Ronan",
		tier = "B",
		defaultPosition = "Forward",
		rigScale = {
			heightScale = Constants.ARCHETYPE_HEIGHT_SCALES.Ronan, -- 1.03
			widthScale = 1.00,
			headScale = 1.00,
			depthScale = 1.00,
			proportionScale = 0.00,
		},
		statModifiers = {
			speedMultiplier = 1.00,
			shotMultiplier = 1.00,
			passMultiplier = 1.00,
			tackleMultiplier = 1.00,
		},
		signatureChoiceId = "StepoverDrive",
		signatureCooldownSec = 35,
		winCutsceneAnimIds = { "SlowMoNutmeg" }, -- Tier B = 1
		celebrationAnimId = "DeepBreathStance",
	},
	Ronan_TierA = {
		cardId = "Ronan_TierA",
		displayName = "Wing Ronan",
		archetypeName = "Ronan",
		tier = "A",
		defaultPosition = "Forward",
		rigScale = {
			heightScale = Constants.ARCHETYPE_HEIGHT_SCALES.Ronan, -- 1.03
			widthScale = 1.01,
			headScale = 1.00,
			depthScale = 1.00,
			proportionScale = 0.00,
		},
		statModifiers = {
			speedMultiplier = 1.06,
			shotMultiplier = 1.07,
			passMultiplier = 1.03,
			tackleMultiplier = 1.00,
		},
		signatureChoiceId = "ChopBlitz",
		signatureCooldownSec = 42,
		winCutsceneAnimIds = { "SlowMoNutmeg", "ElasticoFlash" }, -- Tier A = 2
		celebrationAnimId = "DeepBreathStance",
	},
	Ronan_TierS = {
		cardId = "Ronan_TierS",
		displayName = "Prime Striker Ronan",
		archetypeName = "Ronan",
		tier = "S",
		defaultPosition = "Forward",
		rigScale = {
			heightScale = Constants.ARCHETYPE_HEIGHT_SCALES.Ronan, -- 1.03
			widthScale = 1.02,
			headScale = 1.00,
			depthScale = 1.01,
			proportionScale = 0.00,
		},
		statModifiers = {
			speedMultiplier = 1.12,
			shotMultiplier = 1.15,
			passMultiplier = 1.05,
			tackleMultiplier = 1.02,
		},
		signatureChoiceId = "KnuckleEmperor",
		signatureCooldownSec = 50,
		winCutsceneAnimIds = { "SlowMoNutmeg", "RainbowFlick", "HeelChop" }, -- Tier S = 3
		celebrationAnimId = "DeepBreathStance",
	},
	Leon_TierB = {
		cardId = "Leon_TierB",
		displayName = "Academy Leon",
		archetypeName = "Leon",
		tier = "B",
		defaultPosition = "Forward",
		rigScale = {
			heightScale = Constants.ARCHETYPE_HEIGHT_SCALES.Leon, -- 0.92
			widthScale = 0.95,
			headScale = 1.00,
			depthScale = 0.95,
			proportionScale = 0.00,
		},
		statModifiers = {
			speedMultiplier = 1.02,
			shotMultiplier = 1.00,
			passMultiplier = 1.03,
			tackleMultiplier = 1.00,
		},
		signatureChoiceId = "StepoverDrive",
		signatureCooldownSec = 35,
		winCutsceneAnimIds = { "SlowMoNutmeg" },
		celebrationAnimId = "PointToSky",
	},
	Leon_TierA = {
		cardId = "Leon_TierA",
		displayName = "Playmaker Leon",
		archetypeName = "Leon",
		tier = "A",
		defaultPosition = "Midfielder",
		rigScale = {
			heightScale = Constants.ARCHETYPE_HEIGHT_SCALES.Leon, -- 0.92
			widthScale = 0.96,
			headScale = 1.00,
			depthScale = 0.96,
			proportionScale = 0.00,
		},
		statModifiers = {
			speedMultiplier = 1.08,
			shotMultiplier = 1.06,
			passMultiplier = 1.09,
			tackleMultiplier = 1.00,
		},
		signatureChoiceId = "ChopBlitz",
		signatureCooldownSec = 42,
		winCutsceneAnimIds = { "SlowMoNutmeg", "ElasticoFlash" },
		celebrationAnimId = "PointToSky",
	},
	Leon_TierS = {
		cardId = "Leon_TierS",
		displayName = "Phantom Leon",
		archetypeName = "Leon",
		tier = "S",
		defaultPosition = "Forward",
		rigScale = {
			heightScale = Constants.ARCHETYPE_HEIGHT_SCALES.Leon, -- 0.92
			widthScale = 0.96,
			headScale = 1.00,
			depthScale = 0.96,
			proportionScale = 0.00,
		},
		statModifiers = {
			speedMultiplier = 1.14,
			shotMultiplier = 1.12,
			passMultiplier = 1.15,
			tackleMultiplier = 1.00,
		},
		signatureChoiceId = "PhantomLaPulga",
		signatureCooldownSec = 45,
		winCutsceneAnimIds = { "SlowMoNutmeg", "RainbowFlick", "HeelChop" },
		celebrationAnimId = "PointToSky",
	},
	Ney_TierA = {
		cardId = "Ney_TierA",
		displayName = "Street Ney",
		archetypeName = "Ney",
		tier = "A",
		defaultPosition = "Midfielder",
		rigScale = {
			heightScale = Constants.ARCHETYPE_HEIGHT_SCALES.Ney, -- 0.98
			widthScale = 0.97,
			headScale = 1.00,
			depthScale = 0.97,
			proportionScale = 0.00,
		},
		statModifiers = {
			speedMultiplier = 1.07,
			shotMultiplier = 1.05,
			passMultiplier = 1.08,
			tackleMultiplier = 1.00,
		},
		signatureChoiceId = "ChopBlitz",
		signatureCooldownSec = 42,
		winCutsceneAnimIds = { "SlowMoNutmeg", "ElasticoFlash" },
		celebrationAnimId = "SambaDance",
	},
	Ney_TierS = {
		cardId = "Ney_TierS",
		displayName = "Samba Ney",
		archetypeName = "Ney",
		tier = "S",
		defaultPosition = "Midfielder",
		rigScale = {
			heightScale = Constants.ARCHETYPE_HEIGHT_SCALES.Ney, -- 0.98
			widthScale = 0.97,
			headScale = 1.00,
			depthScale = 0.97,
			proportionScale = 0.00,
		},
		statModifiers = {
			speedMultiplier = 1.13,
			shotMultiplier = 1.10,
			passMultiplier = 1.14,
			tackleMultiplier = 1.00,
		},
		signatureChoiceId = "SambaIllusion",
		signatureCooldownSec = 40,
		winCutsceneAnimIds = { "SlowMoNutmeg", "RainbowFlick", "HeelChop" },
		celebrationAnimId = "SambaDance",
	},
	Vandik_TierA = {
		cardId = "Vandik_TierA",
		displayName = "Sentinel Vandik",
		archetypeName = "Vandik",
		tier = "A",
		defaultPosition = "Defender",
		rigScale = {
			heightScale = Constants.ARCHETYPE_HEIGHT_SCALES.Vandik, -- 1.08
			widthScale = 1.05,
			headScale = 1.00,
			depthScale = 1.04,
			proportionScale = 0.00,
		},
		statModifiers = {
			speedMultiplier = 1.04,
			shotMultiplier = 1.02,
			passMultiplier = 1.05,
			tackleMultiplier = 1.09,
		},
		signatureChoiceId = "ColossusWall",
		signatureCooldownSec = 45,
		winCutsceneAnimIds = { "SlowMoNutmeg", "ElasticoFlash" },
		celebrationAnimId = "ArmsCrossedAura",
	},
	Vandik_TierS = {
		cardId = "Vandik_TierS",
		displayName = "Colossus Vandik",
		archetypeName = "Vandik",
		tier = "S",
		defaultPosition = "Defender",
		rigScale = {
			heightScale = Constants.ARCHETYPE_HEIGHT_SCALES.Vandik, -- 1.08
			widthScale = 1.06,
			headScale = 1.00,
			depthScale = 1.05,
			proportionScale = 0.00,
		},
		statModifiers = {
			speedMultiplier = 1.08,
			shotMultiplier = 1.04,
			passMultiplier = 1.08,
			tackleMultiplier = 1.15,
		},
		signatureChoiceId = "ColossusWall",
		signatureCooldownSec = 45,
		winCutsceneAnimIds = { "SlowMoNutmeg", "RainbowFlick", "HeelChop" },
		celebrationAnimId = "ArmsCrossedAura",
	},
}

local CardConfigs = {
	Cards = table.freeze(Cards),
}

function CardConfigs.GetCardConfig(cardId: string?): PlayerCardConfig
	if cardId and Cards[cardId] then
		return Cards[cardId]
	end
	return Cards[Constants.DEFAULT_CARD_ID]
end

function CardConfigs.ValidateCardInvariants(card: PlayerCardConfig): boolean
	local maxAnims = Constants.MAX_WIN_CUTSCENES_BY_TIER[card.tier] or 1
	if #card.winCutsceneAnimIds > maxAnims or #card.winCutsceneAnimIds > 3 then
		return false
	end
	if card.signatureCooldownSec <= 0 then
		return false
	end
	local maxMult = 1.0 + Constants.MAX_CARD_STAT_DIFFERENCE_RATIO + 1e-4
	local m = card.statModifiers
	if m.speedMultiplier > maxMult or m.shotMultiplier > maxMult or m.passMultiplier > maxMult or m.tackleMultiplier > maxMult then
		return false
	end
	return true
end

return table.freeze(CardConfigs)
