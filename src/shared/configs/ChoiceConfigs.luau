--!strict
-- src/shared/configs/ChoiceConfigs.luau
-- Module 03: Position-Based 1v1 Duel Choices (Forward, Midfielder, Defender) & Resolution Matrix

local Types = require(script.Parent.Parent.Types)

export type ChoiceDefinition = {
	choiceId: string,
	displayName: string,
	role: Types.DuelRole,
	requiresShootingZone: boolean,
	isSignature: boolean,
	cooldownSec: number,
}

local BaseChoicesByPosition: { [Types.PlayerPosition]: { string } } = table.freeze({
	Forward = table.freeze({ "SpeedBurst", "TechNutmeg", "QuickPass", "SnapShot" }),
	Midfielder = table.freeze({ "ThroughPass", "WallBouncePass", "LobPass", "BodyFeint", "SnapShot" }),
	Defender = table.freeze({ "HardTackle", "JockeyIntercept", "ShotBlock" }),
})

local ChoiceCatalog: { [string]: ChoiceDefinition } = table.freeze({
	-- Forward / Midfielder Standard Choices
	SpeedBurst = {
		choiceId = "SpeedBurst",
		displayName = "Speed Burst",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = false,
		cooldownSec = 0,
	},
	TechNutmeg = {
		choiceId = "TechNutmeg",
		displayName = "Tech Nutmeg",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = false,
		cooldownSec = 0,
	},
	QuickPass = {
		choiceId = "QuickPass",
		displayName = "Quick Pass",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = false,
		cooldownSec = 0,
	},
	ThroughPass = {
		choiceId = "ThroughPass",
		displayName = "Through Pass",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = false,
		cooldownSec = 0,
	},
	WallBouncePass = {
		choiceId = "WallBouncePass",
		displayName = "Wall Bounce Pass",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = false,
		cooldownSec = 0,
	},
	LobPass = {
		choiceId = "LobPass",
		displayName = "Lob Pass",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = false,
		cooldownSec = 0,
	},
	BodyFeint = {
		choiceId = "BodyFeint",
		displayName = "Body Feint",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = false,
		cooldownSec = 0,
	},
	SnapShot = {
		choiceId = "SnapShot",
		displayName = "Snap Shot",
		role = "Attacker",
		requiresShootingZone = true,
		isSignature = false,
		cooldownSec = 0,
	},

	-- Defender Standard Choices (ShotBlock is exclusive to 1v1 Choice Duel)
	HardTackle = {
		choiceId = "HardTackle",
		displayName = "Hard Tackle",
		role = "Defender",
		requiresShootingZone = false,
		isSignature = false,
		cooldownSec = 0,
	},
	JockeyIntercept = {
		choiceId = "JockeyIntercept",
		displayName = "Jockey / Intercept",
		role = "Defender",
		requiresShootingZone = false,
		isSignature = false,
		cooldownSec = 0,
	},
	ShotBlock = {
		choiceId = "ShotBlock",
		displayName = "Shot Block",
		role = "Defender",
		requiresShootingZone = false,
		isSignature = false,
		cooldownSec = 0,
	},

	-- Signature Card Choices (All have mandatory Server Cooldowns)
	StepoverDrive = {
		choiceId = "StepoverDrive",
		displayName = "Stepover Drive",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = true,
		cooldownSec = 35,
	},
	ChopBlitz = {
		choiceId = "ChopBlitz",
		displayName = "Chop Blitz",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = true,
		cooldownSec = 42,
	},
	PhantomLaPulga = {
		choiceId = "PhantomLaPulga",
		displayName = "Phantom La Pulga",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = true,
		cooldownSec = 45,
	},
	KnuckleEmperor = {
		choiceId = "KnuckleEmperor",
		displayName = "Knuckle Emperor",
		role = "Attacker",
		requiresShootingZone = true,
		isSignature = true,
		cooldownSec = 50,
	},
	SambaIllusion = {
		choiceId = "SambaIllusion",
		displayName = "Samba Illusion",
		role = "Attacker",
		requiresShootingZone = false,
		isSignature = true,
		cooldownSec = 40,
	},
	ColossusWall = {
		choiceId = "ColossusWall",
		displayName = "Colossus Wall",
		role = "Defender",
		requiresShootingZone = false,
		isSignature = true,
		cooldownSec = 45,
	},
})

local ChoiceConfigs = {
	BaseChoicesByPosition = BaseChoicesByPosition,
	ChoiceCatalog = ChoiceCatalog,
}

function ChoiceConfigs.GetAvailableChoicesForRole(
	role: Types.DuelRole,
	position: Types.PlayerPosition,
	signatureChoiceId: string?
): { string }
	local list: { string } = {}
	if role == "Defender" then
		for _, c in ipairs(BaseChoicesByPosition.Defender) do
			table.insert(list, c)
		end
		if signatureChoiceId and ChoiceCatalog[signatureChoiceId] and ChoiceCatalog[signatureChoiceId].role == "Defender" then
			table.insert(list, signatureChoiceId)
		end
		return list
	end

	local posKey: Types.PlayerPosition = if position == "Midfielder" then "Midfielder" else "Forward"
	for _, c in ipairs(BaseChoicesByPosition[posKey]) do
		table.insert(list, c)
	end
	if signatureChoiceId and ChoiceCatalog[signatureChoiceId] and ChoiceCatalog[signatureChoiceId].role == "Attacker" then
		table.insert(list, signatureChoiceId)
	end
	return list
end

function ChoiceConfigs.ResolveChoiceOutcome(
	attackerChoice: string,
	defenderChoice: string,
	attackerHasMistake: boolean,
	_defenderHasMistake: boolean,
	isInShootingZone: boolean
): (Types.DuelRole, string?)
	-- Prevent out-of-zone shooting exploits
	if (attackerChoice == "SnapShot" or attackerChoice == "KnuckleEmperor") and not isInShootingZone then
		return "Defender", nil
	end

	-- Signature Choice resolution
	if defenderChoice == "ColossusWall" and attackerChoice ~= "KnuckleEmperor" then
		return "Defender", "ColossusWall_Lockdown"
	end
	if attackerChoice == "PhantomLaPulga" then
		return "Attacker", "ZoneFocus_+35%"
	end
	if attackerChoice == "KnuckleEmperor" and isInShootingZone then
		-- Pierces ShotBlock 100%
		return "Attacker", "KnuckleEmperor_Pierce"
	end
	if attackerChoice == "SambaIllusion" then
		return "Attacker", "SambaStun_1.0s"
	end
	if attackerChoice == "StepoverDrive" or attackerChoice == "ChopBlitz" then
		if defenderChoice ~= "ColossusWall" then
			return "Attacker", "SignatureBurst"
		end
	end

	-- Standard Resolution Matrix (Section 4.3)
	if attackerChoice == "SpeedBurst" then
		if defenderChoice == "HardTackle" then
			return "Defender", nil
		end
		return "Attacker", nil
	elseif attackerChoice == "TechNutmeg" or attackerChoice == "BodyFeint" then
		if defenderChoice == "JockeyIntercept" then
			return "Defender", nil
		end
		return "Attacker", nil
	elseif
		attackerChoice == "QuickPass"
		or attackerChoice == "ThroughPass"
		or attackerChoice == "WallBouncePass"
		or attackerChoice == "LobPass"
	then
		if defenderChoice == "JockeyIntercept" then
			return "Defender", nil
		end
		return "Attacker", nil
	elseif attackerChoice == "SnapShot" then
		if defenderChoice == "ShotBlock" then
			return "Defender", nil
		end
		return "Attacker", nil
	end

	-- Tie / Default fallback: On-ball Mistake immediately loses ties
	if attackerHasMistake then
		return "Defender", nil
	end
	return "Attacker", nil
end

return table.freeze(ChoiceConfigs)
