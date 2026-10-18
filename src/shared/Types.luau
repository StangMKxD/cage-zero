--!strict
-- src/shared/Types.luau
-- Domain types and network payload schemas for Cage Zero (Module 00)

export type PlayerPosition = "Forward" | "Midfielder" | "Defender"
export type DuelRole = "Attacker" | "Defender"
export type CardTier = "B" | "A" | "S"
export type BallActionType = "Pass" | "Shoot" | "Sprint"
export type FreeKickTimingZone = "Green" | "Yellow" | "Red"
export type MatchEventType = "PillarLockdown" | "BlackoutVoid" | "FavelaAlley"
export type MatchEventState = "Warning" | "Active" | "Ended"
export type InventoryCategory = "Card" | "Thread" | "Trait" | "Celebration"
export type SummonCount = number -- 1 | 10
export type TradeActionType = "AddItem" | "LockOffer" | "ConfirmTrade" | "Cancel"
export type UIMode = "MAIN_MENU" | "LOBBY_MODE" | "MATCH_MODE"
export type MutationType = "GoldenAura" | "VoidGlitch" | "BloodMoonFlame"

export type RigScaleConfig = {
	heightScale: number,
	widthScale: number,
	headScale: number,
	depthScale: number,
	proportionScale: number,
}

export type StatModifiers = {
	speedMultiplier: number,
	shotMultiplier: number,
	passMultiplier: number,
	tackleMultiplier: number,
}

export type PlayerCardConfig = {
	cardId: string,
	displayName: string,
	archetypeName: string,
	tier: CardTier,
	defaultPosition: PlayerPosition,
	rigScale: RigScaleConfig,
	statModifiers: StatModifiers,
	signatureChoiceId: string,
	signatureCooldownSec: number,
	winCutsceneAnimIds: { string },
	celebrationAnimId: string,
}

-- Zero Pay-to-Win Rule: MutationData contains ONLY VFX, trade value, and post-match Cash/EXP multipliers.
export type MutationData = {
	mutationType: MutationType,
	vfxId: string,
	cashMultiplier: number,
	expMultiplier: number,
	tradeValueBonus: number,
}

-- No Boots/Cleats Rule: Equipment is strictly limited to Battle Threads with 1-2 Trait Slots.
export type BattleThreadInstance = {
	threadUid: string,
	threadConfigId: string,
	maxTraitSlots: number,
	equippedTraitIds: { string },
	mutation: MutationData?,
}

export type ObtainedItem = {
	itemUid: string,
	category: InventoryCategory,
	configId: string,
	tierOrRarity: string,
}

export type PlayerProfileData = {
	userId: number,
	cash: number,
	level: number,
	exp: number,
	pityCounter: number,
	equippedCardId: string,
	equippedThreadUid: string?,
	equippedCelebrationId: string,
	ownedCards: { string },
	ownedThreads: { BattleThreadInstance },
	ownedTraits: { string },
}

local Types = {}
return table.freeze(Types)
