--!strict
-- src/shared/configs/TraitConfigs.luau
-- Module 06: Cooldown-Gated Guaranteed Traits (Soul Stones)
-- Rule 5: Every 100% guaranteed Trait MUST have a mandatory Server-side Cooldown (never permanent passive).

export type TraitDefinition = {
	traitId: string,
	displayName: string,
	description: string,
	cooldownSec: number,
	isPermanentPassive: boolean,
	triggerContext: "OnPass" | "OnShootInZone" | "OnDefensiveDuel",
}

local Traits: { [string]: TraitDefinition } = table.freeze({
	LaserGuidedPass = table.freeze({
		traitId = "LaserGuidedPass",
		displayName = "Laser Guided Pass",
		description = "Next pass curves around opponents to reach a teammate 100%.",
		cooldownSec = 35,
		isPermanentPassive = false,
		triggerContext = "OnPass" :: "OnPass",
	}),
	MiracleFinish = table.freeze({
		traitId = "MiracleFinish",
		displayName = "Miracle Finish",
		description = "Next shot inside Shooting Zone hits top corner 100% if not blocked in duel.",
		cooldownSec = 60,
		isPermanentPassive = false,
		triggerContext = "OnShootInZone" :: "OnShootInZone",
	}),
	IronLockdown = table.freeze({
		traitId = "IronLockdown",
		displayName = "Iron Lockdown",
		description = "Next defensive 1v1 duel wins and steals possession 100%.",
		cooldownSec = 45,
		isPermanentPassive = false,
		triggerContext = "OnDefensiveDuel" :: "OnDefensiveDuel",
	}),
})

local TraitConfigs = {
	Traits = Traits,
}

function TraitConfigs.GetTraitConfig(traitId: string): TraitDefinition?
	return Traits[traitId]
end

function TraitConfigs.ValidateAllTraitsHaveCooldown(): boolean
	for _, trait in pairs(Traits) do
		if trait.isPermanentPassive or trait.cooldownSec <= 0 then
			return false
		end
	end
	return true
end

return table.freeze(TraitConfigs)
