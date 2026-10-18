--!strict
-- src/shared/configs/ThreadConfigs.luau
-- Module 06: Battle Threads Equipment & Zero Pay-to-Win Mutated Gear Configurations
-- Rule 3: No Boots/Cleats System. Rule 4: Mutations grant ONLY VFX, trade value, and Cash/EXP multipliers.

local Constants = require(script.Parent.Parent.Constants)
local Types = require(script.Parent.Parent.Types)

export type BattleThreadConfig = {
	threadConfigId: string,
	displayName: string,
	rarity: Types.ThreadRarity,
	maxTraitSlots: number,
	baseTradeValue: number,
}

local Threads: { [string]: BattleThreadConfig } = table.freeze({
	StreetHoodie_Common = table.freeze({
		threadConfigId = "StreetHoodie_Common",
		displayName = "Street Cage Hoodie",
		rarity = "Common" :: Types.ThreadRarity,
		maxTraitSlots = 1,
		baseTradeValue = 250,
	}),
	CyberJacket_Rare = table.freeze({
		threadConfigId = "CyberJacket_Rare",
		displayName = "Neon Pulse Jacket",
		rarity = "Rare" :: Types.ThreadRarity,
		maxTraitSlots = 1,
		baseTradeValue = 750,
	}),
	PhantomCloak_Epic = table.freeze({
		threadConfigId = "PhantomCloak_Epic",
		displayName = "Phantom Street Cloak",
		rarity = "Epic" :: Types.ThreadRarity,
		maxTraitSlots = 2,
		baseTradeValue = 2200,
	}),
	CageEmperorArmor_Legendary = table.freeze({
		threadConfigId = "CageEmperorArmor_Legendary",
		displayName = "Cage Emperor Battle Thread",
		rarity = "Legendary" :: Types.ThreadRarity,
		maxTraitSlots = 2,
		baseTradeValue = 6000,
	}),
})

-- Rule 4: Zero combat stat fields exist in MutationPresets
local MutationPresets: { [Types.MutationType]: Types.MutationData } = table.freeze({
	GoldenAura = table.freeze({
		mutationType = "GoldenAura" :: Types.MutationType,
		vfxId = "VFX_GoldenAuraFootsteps",
		cashMultiplier = 2.0,
		expMultiplier = 1.5,
		tradeValueBonus = 3500,
	}),
	VoidGlitch = table.freeze({
		mutationType = "VoidGlitch" :: Types.MutationType,
		vfxId = "VFX_VoidGlitchTrail",
		cashMultiplier = 3.5,
		expMultiplier = 2.2,
		tradeValueBonus = 8000,
	}),
	BloodMoonFlame = table.freeze({
		mutationType = "BloodMoonFlame" :: Types.MutationType,
		vfxId = "VFX_BloodMoonFlameAura",
		cashMultiplier = 5.0,
		expMultiplier = 3.0,
		tradeValueBonus = 15000,
	}),
})

local ThreadConfigs = {
	Threads = Threads,
	MutationPresets = MutationPresets,
}

function ThreadConfigs.GetThreadConfig(threadConfigId: string): BattleThreadConfig?
	return Threads[threadConfigId]
end

function ThreadConfigs.ValidateZeroPayToWinMutations(): boolean
	if Constants.ALLOW_BOOTS_OR_CLEATS_SYSTEM or Constants.ALLOW_MUTATION_COMBAT_STATS then
		return false
	end
	for _, mut in pairs(MutationPresets) do
		local raw = mut :: any
		if raw.speedMultiplier ~= nil or raw.shotMultiplier ~= nil or raw.passMultiplier ~= nil or raw.duelBonus ~= nil then
			return false
		end
		if mut.cashMultiplier < Constants.MUTATION_CASH_MULTIPLIER_MIN
			or mut.cashMultiplier > Constants.MUTATION_CASH_MULTIPLIER_MAX
		then
			return false
		end
		if mut.expMultiplier < Constants.MUTATION_EXP_MULTIPLIER_MIN
			or mut.expMultiplier > Constants.MUTATION_EXP_MULTIPLIER_MAX
		then
			return false
		end
	end
	return true
end

return table.freeze(ThreadConfigs)
