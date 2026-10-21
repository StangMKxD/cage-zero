--!strict
-- src/shared/Types.luau
-- Domain types and network payload schemas for Cage Zero (Module 00 - run-02 Fixed)

export type PlayerPosition = "Forward" | "Midfielder" | "Defender"
export type DuelRole = "Attacker" | "Defender"
export type CardTier = "B" | "A" | "S"
export type ThreadRarity = "Common" | "Rare" | "Epic" | "Legendary"
export type BallActionType = "Pass" | "Shoot" | "Sprint"
export type FreeKickTimingZone = "Green" | "Yellow" | "Red"
export type MatchEventType = "PillarLockdown" | "BlackoutVoid" | "FavelaAlley"
export type MatchEventState = "Warning" | "Active" | "Ended"
export type InventoryCategory = "Card" | "Thread" | "Trait" | "Celebration"
export type SummonCount = number
export type TradeActionType = "AddItem" | "LockOffer" | "ConfirmTrade" | "Cancel"
export type TradeStatus = "Active" | "Locked" | "Completed" | "Cancelled"
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
	rarity: ThreadRarity,
	maxTraitSlots: number,
	equippedTraitIds: { string },
	mutation: MutationData?,
}

export type TraitStoneInstance = {
	traitUid: string,
	traitId: string,
	acquiredAt: number,
}

export type ObtainedItem = {
	itemUid: string,
	category: InventoryCategory,
	configId: string,
	tierOrRarity: string,
}

export type TradeSessionData = {
	tradeId: string,
	initiatorUserId: number,
	partnerUserId: number,
	initiatorOfferUids: { string },
	partnerOfferUids: { string },
	initiatorLocked: boolean,
	partnerLocked: boolean,
	lockTimestamp: number?,
	initiatorConfirmed: boolean,
	partnerConfirmed: boolean,
	status: TradeStatus,
}

export type BoothListingData = {
	listingId: string,
	sellerUserId: number,
	itemUid: string,
	category: InventoryCategory,
	priceCash: number,
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
	ownedTraits: { TraitStoneInstance },
}

-- Module 01: 01-cage-physics (3D Cage Variants A/B/C & Rebound Physics)
export type CageVariantId = "A" | "B" | "C"

export type CageVariantAlias =
	| "HexClassicVariantA"
	| "HexChamferVariantB"
	| "HexStreetVariantC"
	| "HexClassicA"
	| "HexChamferB"
	| "HexStreetC"
	| "HexClassic"
	| "HexChamfer"
	| "HexStreet"
	| "VariantA"
	| "VariantB"
	| "VariantC"
	| "Variant_A"
	| "Variant_B"
	| "Variant_C"
	| "Classic"
	| "Chamfer"
	| "Street"
	| "Bevel"
	| "a"
	| "b"
	| "c"

export type CageVariantInput = CageVariantId | CageVariantAlias | string

export type ArenaSurfaceKind =
	"Floor"
	| "Wall"
	| "CornerWall"
	| "Ceiling"
	| "RoofBevel"
	| "GoalFrame"
	| "GoalPost"
	| "GoalCrossbar"
	| "GoalTransom"
	| "GoalPocket"
	| "Transom"
	| "PinballBumper"
	| "ElevatingRamp"
	| "CeilingMarker"
	| "SpawnLocation"

export type ReboundFeatureFlags = {
	enableBumpers: boolean,
	enableTransom: boolean,
	enableRamps: boolean,
	includeCornerOverlayInA: boolean?,
}

export type ArenaSurfaceDef = {
	surfaceId: string,
	kind: ArenaSurfaceKind,
	size: Vector3,
	cframe: CFrame,
	normal: Vector3,
	restitution: number,
	color: Color3,
	material: Enum.Material,
	transparency: number,
	canCollide: boolean,
	canQuery: boolean,
	isGuideOnly: boolean,
	requiresBumperFlag: boolean?,
	requiresTransomFlag: boolean?,
	requiresRampFlag: boolean?,
	goalSide: ("North" | "South")?,
}

export type ArenaGeometryProfile = {
	variantId: CageVariantId,
	displayName: string,
	wallCount: number,
	hasChamferedCorners: boolean,
	hasBeveledRoof: boolean,
	halfWidthX: number,
	halfLengthZ: number,
	ceilingHeightY: number,
	eaveHeightY: number,
	chamferCutStuds: number,
	roofBevelStuds: number,
	ballRadius: number,
	goalFrontAbsZ: number,
	backGoalAlleyStuds: number,
	footprintPolygonXZ: { Vector2 },
	surfaces: { ArenaSurfaceDef },
}

export type ReboundStepResult = {
	position: Vector3,
	velocity: Vector3,
	hitSurfaceTag: string?,
	hitCount: number,
	hitSurfaces: { string },
	substepsUsed: number,
	budgetExhausted: boolean,
	speedBeforeHit: number,
	speedPreCap: number,
	speedAfterHit: number,
	appliedRampLift: boolean,
}

local Types = {}
return table.freeze(Types)
