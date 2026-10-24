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

-- Module 02: 02-player-actions (Continuous Football, Possession, Actions & Movement)
export type TeamSide = "North" | "South"
export type TeamActionContext = "Attacking" | "Defending"

export type KickActionType =
	| "DirectShoot"
	| "CurveShoot"
	| "Pass"
	| "GroundPass"
	| "Header"
	| "Volley"
	| "QuickPoke"
	| "SkillMove"
	| "BicycleKick"
	| "AcrobaticFinishing"
	| "BallPop"

export type ChargeActionType = "DirectShoot" | "CurveShoot" | "Pass" | "Slide"

export type CurveSideIntent = "Left" | "Right" | "Neutral"

export type ActionIntentName =
	| "Sprint"
	| "Dash"
	| "DirectionalJump"
	| "StartCharge"
	| "CancelCharge"
	| "FakeShot"
	| "DirectShoot"
	| "CurveShoot"
	| "Pass"
	| "GroundPass"
	| "Slide"
	| "ResetBall"
	| "Volley"
	| "BicycleKick"
	| "SetAirLean"
	| "BallPop"

export type FlightState =
	| "Grounded"
	| "Takeoff"
	| "Rising"
	| "Apex"
	| "Falling"
	| "Landed"
	| "LandingLag"

export type ActionStatus = "Accepted" | "Rejected" | "Cancelled"

export type ActionRejectReason =
	| "InvalidPayload"
	| "StaleIntent"
	| "WrongContext"
	| "NotAlive"
	| "OutOfReach"
	| "InsufficientStamina"
	| "Cooldown"
	| "Recovery"
	| "RateLimited"
	| "RemovedAction"
	| "ExceededBudget"
	| "LandingLag"
	| "NotPossessor"
	| "PossessingBall"

export type ActionIntentPayload = {
	action: ActionIntentName,
	intentId: string?,
	flightId: string?,
	characterGeneration: number?,
	contextVersion: number?,
	phase: ("start" | "release" | "cancel" | "feint")?,
	chargeAction: ChargeActionType?,
	aimDirection: Vector3?,
	isSprinting: boolean?,
	charge: number?,
	curveSideIntent: CurveSideIntent?,
	airLeanForward: number?,
	airLeanRight: number?,
}

export type BallPossessionState =
	| "Free"
	| "Possessed"
	| "InFlight"

export type BallSnapshot = {
	ballId: string,
	position: Vector3,
	velocity: Vector3,
	state: BallPossessionState,
	possessorUserId: number?,
	lastPossessingTeam: TeamSide?,
	lastKickerUserId: number?,
	curveImpulse: Vector3?,
	inFlightAction: KickActionType?,
}

export type PlayerMovementSnapshot = {
	userId: number,
	teamSide: TeamSide,
	stamina: number,
	isSprinting: boolean,
	isDashing: boolean,
	dashCooldownRemaining: number,
	isAirborne: boolean,
	jumpLockedVelocity: Vector3?,
	actionContext: TeamActionContext,
	isCharging: boolean?,
	chargePower: number?,
	isSliding: boolean?,
	slideCooldownRemaining: number?,
	recoveryRemaining: number?,
	whiffRecoveryRemaining: number?,
	fakeShotRecoveryRemaining: number?,
	whiffRecoveryAction: string?,
	characterGeneration: number?,
	contextVersion: number?,
	chargeAction: ChargeActionType?,
	chargeCurveSide: CurveSideIntent?,
	chargeCurveStyle: ("Finesse" | "Trivela")?,
	chargeKickFoot: ("Left" | "Right")?,
	lastResolvedAction: string?,
	actionSequence: number?,
	resolvedKickFoot: ("Left" | "Right")?,
	resolvedCurveStyle: ("Finesse" | "Trivela")?,
	airLeanForward: number?,
	airLeanRight: number?,
	airLeanTimestamp: number?,
	jumpFacingF0: Vector3?,
	flightState: FlightState?,
	flightId: string?,
	airOffensiveBudget: number?,
	landingLagRemaining: number?,
	activeSkillMove: SkillMoveId?,
	activeTackle: TackleActionType?,
	commonSkillRecoveryRemaining: number?,
}

-- Plan 03: Skill Moves & Defense Domain Types
export type SkillMoveId =
	| "HeavyKnockOn"
	| "OpenUpFakeShot"
	| "BodyFeint"
	| "HeelChop"
	| "LaneChange"
	| "SombreroFlick"
	| "Elastico"
	| "DragBackTurn"
	| "LaCroqueta"

export type SkillSlotIndex = number -- Validated runtime slot index: 1, 2, or 3

export type SkillMoveDefinition = {
	id: SkillMoveId,
	displayName: string,
	starRating: number,
	staminaCost: number,
	cooldownSec: number,
	commonRecoverySec: number,
	totalDurationSec: number,
	contactTimeSec: number,
	ballImpulseMagnitude: number,
	ballImpulseVertical: number,
	playerVelocityBurst: number,
	burstDurationSec: number,
	retreatSpeed: number,
	description: string,
	directionPolicy: "Forward" | "LateralCut" | "LiftForward",
	neutralSide: number,
	contactStages: { { time: number, lateral: number, forward: number, vertical: number } },
}

export type TackleActionType = "Slide" | "Poke" | "CagePress"

export type TackleDefinition = {
	action: TackleActionType,
	displayName: string,
	reachStuds: number,
	staminaCost: number,
	cooldownSec: number,
	windupSec: number,
	activeDurationSec: number,
	recoverySec: number,
	whiffRecoverySec: number,
	slowMultiplier: number?,
	slowDurationSec: number?,
}

export type PlayerSkillLoadout = {
	slot1: SkillMoveId,
	slot2: SkillMoveId,
	slot3: SkillMoveId,
}

local Types = {}
return table.freeze(Types)
