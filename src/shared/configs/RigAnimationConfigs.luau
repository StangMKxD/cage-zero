--!strict
-- src/shared/configs/RigAnimationConfigs.luau
-- Module 00: Single Standard Custom R6 Locomotion Animation Configs & Provenance
-- [FIX-F19] Enrich animation provenance with verifiable Roblox assetdelivery URLs and documentation references.

export type AnimationProvenance = {
	source: string,
	assetId: string,
	verifiedCompatibility: string,
	description: string,
	referenceUrl: string,
	catalogAssetUrl: string,
}

export type AnimationStateProfile = {
	stateName: string,
	assetId: string,
	priority: Enum.AnimationPriority,
	looped: boolean,
	speed: number,
	fadeTime: number,
	weight: number,
	provenance: AnimationProvenance,
}

local RigAnimationConfigs = {}

local PROFILES: { [string]: AnimationStateProfile } = table.freeze({
	idle = table.freeze({
		stateName = "idle",
		assetId = "rbxassetid://180435571",
		priority = Enum.AnimationPriority.Idle,
		looped = true,
		speed = 1.0,
		fadeTime = 0.2,
		weight = 1.0,
		provenance = table.freeze({
			source = "Roblox Native Standard R6 Animate Baseline",
			assetId = "180435571",
			verifiedCompatibility = "R6",
			description = "Standard Roblox R6 default idle animation",
			referenceUrl = "https://create.roblox.com/docs/avatar/characters/animation#default-animations",
			catalogAssetUrl = "https://assetdelivery.roblox.com/v1/asset/?id=180435571",
		}),
	}),
	walk = table.freeze({
		stateName = "walk",
		assetId = "rbxassetid://180426354",
		priority = Enum.AnimationPriority.Movement,
		looped = true,
		speed = 1.0,
		fadeTime = 0.2,
		weight = 1.0,
		provenance = table.freeze({
			source = "Roblox Native Standard R6 Animate Baseline",
			assetId = "180426354",
			verifiedCompatibility = "R6",
			description = "Standard Roblox R6 default walk locomotion",
			referenceUrl = "https://create.roblox.com/docs/avatar/characters/animation#default-animations",
			catalogAssetUrl = "https://assetdelivery.roblox.com/v1/asset/?id=180426354",
		}),
	}),
	run = table.freeze({
		stateName = "run",
		assetId = "rbxassetid://180426354",
		priority = Enum.AnimationPriority.Movement,
		looped = true,
		speed = 1.25,
		fadeTime = 0.2,
		weight = 1.0,
		provenance = table.freeze({
			source = "Roblox Native Standard R6 Animate Baseline (Speed-scaled walk)",
			assetId = "180426354",
			verifiedCompatibility = "R6",
			description = "Standard Roblox R6 walk clip adjusted for sprint/run speed",
			referenceUrl = "https://create.roblox.com/docs/avatar/characters/animation#default-animations",
			catalogAssetUrl = "https://assetdelivery.roblox.com/v1/asset/?id=180426354",
		}),
	}),
	jump = table.freeze({
		stateName = "jump",
		assetId = "rbxassetid://125750702",
		priority = Enum.AnimationPriority.Action,
		looped = false,
		speed = 1.0,
		fadeTime = 0.1,
		weight = 1.0,
		provenance = table.freeze({
			source = "Roblox Native Standard R6 Animate Baseline",
			assetId = "125750702",
			verifiedCompatibility = "R6",
			description = "Standard Roblox R6 default jump pose",
			referenceUrl = "https://create.roblox.com/docs/avatar/characters/animation#default-animations",
			catalogAssetUrl = "https://assetdelivery.roblox.com/v1/asset/?id=125750702",
		}),
	}),
	fall = table.freeze({
		stateName = "fall",
		assetId = "rbxassetid://180436148",
		priority = Enum.AnimationPriority.Movement,
		looped = true,
		speed = 1.0,
		fadeTime = 0.2,
		weight = 1.0,
		provenance = table.freeze({
			source = "Roblox Native Standard R6 Animate Baseline",
			assetId = "180436148",
			verifiedCompatibility = "R6",
			description = "Standard Roblox R6 default freefall loop",
			referenceUrl = "https://create.roblox.com/docs/avatar/characters/animation#default-animations",
			catalogAssetUrl = "https://assetdelivery.roblox.com/v1/asset/?id=180436148",
		}),
	}),
	climb = table.freeze({
		stateName = "climb",
		assetId = "rbxassetid://180436334",
		priority = Enum.AnimationPriority.Movement,
		looped = true,
		speed = 1.0,
		fadeTime = 0.2,
		weight = 1.0,
		provenance = table.freeze({
			source = "Roblox Native Standard R6 Animate Baseline",
			assetId = "180436334",
			verifiedCompatibility = "R6",
			description = "Standard Roblox R6 default climb ladder loop",
			referenceUrl = "https://create.roblox.com/docs/avatar/characters/animation#default-animations",
			catalogAssetUrl = "https://assetdelivery.roblox.com/v1/asset/?id=180436334",
		}),
	}),
})

function RigAnimationConfigs.GetProfile(stateName: string): AnimationStateProfile?
	return PROFILES[stateName]
end

function RigAnimationConfigs.GetAllProfiles(): { [string]: AnimationStateProfile }
	return PROFILES
end

function RigAnimationConfigs.ValidateProvenance(stateName: string): boolean
	local profile = PROFILES[stateName]
	if not profile then
		return false
	end
	return profile.provenance.verifiedCompatibility == "R6"
		and string.match(profile.assetId, "^rbxassetid://%d+$") ~= nil
		and string.match(profile.provenance.catalogAssetUrl, "^https://assetdelivery%.roblox%.com/v1/asset/%?id=%d+$") ~= nil
end

return table.freeze(RigAnimationConfigs)
