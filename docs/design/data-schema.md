# Data Schema & Domain Models — Target และ Baseline Reference

Decision Accepted / Delivery Planned ตาม Q22 และ DOCS-20261024; ไม่แก้โค้ดใน `src/` (`Types.luau`, `CardConfigs.luau`, `Network.luau` ของแผน 00) ในรอบเอกสารนี้ แผน 02/03/Phase2 ต้อง freeze field types/validation/migration ใน HANDOFF ก่อนลงมือ implementation

---

## 1. Target Domain Concepts — Phase 1 & Phase 2

### 1.1 Outfield Base Stats Schema (13 ค่าสเตตัสเป้าหมาย)

```luau
export type OutfieldStatModifiers = {
    speedMultiplier: number,           -- #1  Speed (0.90..1.15)
    jumpMultiplier: number,            -- #2  Jump (0.90..1.15)
    shotPowerMultiplier: number,       -- #3  Shot Power (0.90..1.15)
    curveMultiplier: number,           -- #4  Curve (0.90..1.15)
    slidingMultiplier: number,         -- #5  Sliding (0.90..1.15)
    strengthMultiplier: number,        -- #6  Strength (0.90..1.15)
    dribblingMultiplier: number,       -- #7  Dribbling (0.90..1.15, inverse offset math)
    staminaMultiplier: number,         -- #9  Stamina (0.90..1.15)
    passVelocityMultiplier: number,    -- #16 Pass Velocity (0.90..1.15)
    accelerationDashMultiplier: number,-- #27 Acceleration / Dash (0.90..1.15)
    pokeReachMultiplier: number,       -- #30 Poke Reach (0.90..1.15)
    recoveryReflexMultiplier: number,  -- #32 Recovery / Reflex (0.90..1.15, inverse duration math)
    blockMultiplier: number,           -- Block (0.90..1.15)
}

-- 4 ค่า Goalkeeper Stats ถูกเลื่อนไปออกแบบหลัง Phase 1 / 04:
-- diveReachMultiplier, handlingMultiplier, reflexDiveRecoveryMultiplier, boxDistributionMultiplier
```

### 1.2 Character Traits Enum (16 รายการ)

```luau
export type TraitId =
    -- สายยิง/ชิ่ง (4)
    | "WhippedFinesse"
    | "TrivelaMaster"
    | "KnuckleEmperor"
    | "WallBreaker"
    -- สายเทคนิค/เคลื่อนที่ (7 — #11 ถูกตัดออกถาวร)
    | "SecondWind"
    | "VelvetTouch"
    | "OneTouchSpecialist"
    | "AcrobatSkyStriker"
    | "QuickFootwork"
    | "LightningPoke"
    | "ElasticRecovery"
    -- สายกองหลัง/เกมรับ (5)
    | "IronWallBlock"
    | "BulldozerImpact"
    | "CleanSweeper"
    | "ShadowChaser"
    | "CageGuardian"
```

### 1.3 Character Archetypes Enum (5 สาย)

```luau
export type ArchetypeId =
    | "SpeedsterStriker" -- Ney (0.98), 4★
    | "CagePlaymaker"    -- Leon (0.92), 5★
    | "PowerTarget"      -- Ronan (1.03), 3★
    | "IronStopper"      -- Vandik (1.08), 2★
    | "SweeperDestroyer" -- Ronan (1.03), 3★
```

### 1.4 Target Player Card Model (`PlayerCardConfig` Target)

```luau
export type PlayerCardConfig = {
    cardId: string,
    displayName: string,
    archetypeId: ArchetypeId,
    tier: "B" | "A" | "S",
    heightScale: number,                -- 0.92, 0.98, 1.03, 1.08 ตาม R6 profile
    widthScale: number,
    skillMoveStarsCeiling: number,      -- 2★ ถึง 5★ ตาม Archetype
    statModifiers: OutfieldStatModifiers, -- ครบ 13 ค่าในช่วง 0.90..1.15
    innateTraitIds: { TraitId },         -- รายการ Trait ติดตัวละคร (จำนวนผันแปร: 0, 1, 2, ... รายการ; อาจว่างเปล่าได้ {})
    celebrationAnimId: string,
}
```

### 1.5 Target Battle Threads & Mutations Model (Cosmetic Only)

```luau
export type BattleThreadInstance = {
    threadUid: string,
    threadConfigId: string,
    rarity: "Common" | "Rare" | "Epic" | "Legendary",
    -- หมายเหตุ Target: ไม่มีฟิลด์ maxTraitSlots และไม่มี equippedTraitIds ใน Target Design
    mutation: MutationData?,
}

export type MutationData = {
    mutationType: "GoldenAura" | "VoidGlitch" | "BloodMoonFlame",
    vfxId: string,
    cashMultiplier: number,             -- 1.5 ถึง 5.0 (เฉพาะเงินรางวัลหลังแข่ง)
    expMultiplier: number,              -- 1.5 ถึง 3.0 (เฉพาะ EXP หลังแข่ง)
    tradeValueBonus: number,
    -- หมายเหตุ: ห้ามมีฟิลด์บวกค่าสเตตัสในสนามเด็ดขาด
}
```

### 1.6 Target Player Profile Data

```luau
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
    -- หมายเหตุ Target: ไม่มี ownedTraits (หิน Trait) ใน Target Design
}
```

---

## 2. Baseline Schema Reference — ข้อมูลประวัติศาสตร์เดิม (Labelled History)

> โครงสร้างด้านล่างบันทึก source ก่อน Q22 และ DOCS-20261024 โดยเฉพาะ `signatureChoiceId`, `winCutsceneAnimIds`, สล็อต Trait บนชุด, และหิน Trait Stone ถูก supersede ใน Target Design แล้ว คงไว้เพื่อเป็นประวัติศาสตร์อ้างอิงเท่านั้น

### 2.1 โครงสร้างเดิม: ข้อมูลผู้เล่น (`PlayerProfileData` Historical)
- `userId: number` — รหัสผู้เล่น Roblox
- `cash: number` — เงินในเกม (`Cash`)
- `level: number` — เลเวลผู้เล่น
- `exp: number` — ค่าประสบการณ์สะสม (`EXP`)
- `pityCounter: number` — ตัวนับการันตีกาชา (`0–100`)
- `equippedCardId: string` — รหัสการ์ดนักเตะที่สวมใส่ปัจจุบัน
- `equippedThreadUid: string?` — รหัสชุด `Battle Threads` ที่สวมใส่ปัจจุบัน
- `equippedCelebrationId: string` — รหัสท่าดีใจหลังยิงประตู
- `ownedCards: {string}` — รายการการ์ดนักเตะที่ครอบครอง
- `ownedThreads: {BattleThreadInstance}` — รายการชุด `Battle Threads` ที่ครอบครอง
- `ownedTraits: {TraitStoneInstance}` — *(HISTORICAL: รายการหิน Trait ในกระเป๋า — ถูกถอดออกจาก Target)*

### 2.2 โครงสร้างเดิม: ข้อมูลการ์ดนักเตะ (`PlayerCardConfig` Historical)
- `cardId: string`
- `displayName: string`
- `tier: "B" | "A" | "S"`
- `heightScale: number` (`0.92`, `0.98`, `1.03`, `1.08`)
- `widthScale: number`
- `statModifiers`: `{ speedMultiplier: number, shotMultiplier: number, passMultiplier: number, tackleMultiplier: number }` *(HISTORICAL: สเตตัสชุดเล็ก 4 ค่า — ถูกแทนที่ด้วย 13 Outfield Stats ใน Target)*
- `signatureChoiceId: string` *(HISTORICAL: ถูกยกเลิกตาม Q22)*
- `signatureCooldownSec: number` *(HISTORICAL: ถูกยกเลิกตาม Q22)*
- `winCutsceneAnimIds: {string}` *(HISTORICAL: ถูกยกเลิกตาม Q22)*
- `celebrationAnimId: string`

### 2.3 โครงสร้างเดิม: ข้อมูลชุด `Battle Threads` (`BattleThreadInstance` Historical)
- `threadUid: string`
- `threadConfigId: string`
- `rarity: "Common" | "Rare" | "Epic" | "Legendary"`
- `maxTraitSlots: number` (`1` หรือ `2` ช่อง) *(HISTORICAL: ถูกถอดออกจาก Target)*
- `equippedTraitIds: {string}` *(HISTORICAL: ถูกถอดออกจาก Target)*
- `mutation: MutationData?`

### 2.4 โครงสร้างเดิม: ข้อมูลธุรกรรมตลาดเทรด (`TradeSessionData` Historical)
- `tradeId: string`
- `initiatorUserId: number`
- `partnerUserId: number`
- `initiatorOfferUids: {string}`
- `partnerOfferUids: {string}`
- `initiatorLocked: boolean`
- `partnerLocked: boolean`
- `lockTimestamp: number?`
- `initiatorConfirmed: boolean`
- `partnerConfirmed: boolean`
- `status: "Active" | "Locked" | "Completed" | "Cancelled"`


## 3. Plan 00 Foundation Architecture Extension Schema (DOCS-ARCH-20261024 - A-03 & A-04 Harmonized)

> รายละเอียดความสัมพันธ์และการออกแบบเชิงลึกอยู่ใน [Upgrade & Limit Break Design](../plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/upgrade-limit-break.md) และ [Monetization & Identity Design](../plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/monetization-identity-celebration.md)

### 3.1 Persistent Card Record vs Runtime Derived Profile (A-04 Canonical Schema)

```luau
-- 1. ข้อมูลแม่แบบถาวร (Immutable Definition Catalog)
export type CharacterDefinition = {
    characterId: string,              -- รหัสตัวละคร เช่น "ronan_base", "leon_base"
    displayName: string,
    tier: "B" | "A" | "S",
    archetypeId: ArchetypeId,
    heightScale: number,              -- 0.92, 0.98, 1.03, 1.08 (alias: baseHeightScale)
    widthScale: number,               -- (alias: baseWidthScale)
    baseSkillMoveStarsCeiling: number,-- 2★ ถึง 5★ (Ronan 3★, Ney 4★, Leon 5★, Vandik 2★)
    baseStats: { [OutfieldStatId]: number }, -- 13 ค่าสเตตัสพื้นฐาน (0.90..1.15) (alias: baseStatModifiers)
    innateTraitIds: { TraitId },      -- รายการ Trait ติดตัวละครพื้นฐาน (0, 1, 2, ... รายการ)
    signatureIdentityKitId: string,
    defaultCelebrationId: string,
}

-- 2. ข้อมูลการถือครองการ์ดที่บันทึกลงฐานข้อมูล (Persistent Owned Card Instance)
-- หมายเหตุ A-04: บันทึกเฉพาะ Persistent Source State เท่านั้น ไม่บันทึกค่าที่คำนวณสดได้ (No Stored Derived State)
export type OwnedCardInstance = {
    cardUid: string,                  -- UUID เฉพาะตัวของการ์ดใบนี้ (ห้ามใช้ซ้ำ)
    characterId: string,              -- รหัสตัวละครอ้างอิง CharacterDefinition
    ownerUserId: number,              -- รหัสผู้เล่นเจ้าของการ์ด
    upgradeLevel: number,             -- ระดับ Limit Break: 0 ถึง 5
    
    -- การจัดสรรแต้มสเตตัสอิสระ (+2: 2 แต้ม, +3: 3 แต้ม รวมสูงสุด 5 แต้ม)
    allocatedCustomStats: {
        [OutfieldStatId]: number,     -- แต่ละแต้ม +0.01; รวมไม่เกิน 5 แต้ม (Base + Custom <= 1.15)
    },
    
    -- การตื่นรู้ Trait และสล็อตเสริม (U1, U9, U10, U13)
    awakenedTraitId: TraitId?,        -- 1 Trait ที่เลือกเบิกเนตรเป็น Tier II ที่ +3 (หรือ nil หากยังไม่มี Trait)
    bankedAwakeningRight: boolean,    -- true หากตอนถึง +3 ตัวละครมี 0 Trait และเก็บสิทธิ์ไว้เบิกเนตรภายหลัง
    extraTraitId: TraitId?,           -- 1 Trait สล็อตเสริมที่ปลดล็อกที่ +5 (เลือกจากทั้งเกม ห้ามซ้ำ innate)
    
    acquiredTimestamp: number,        -- เวลาที่ได้รับไอเทม
    isLocked: boolean,                -- ล็อกป้องกันการเผลอย่อย (PROPOSED ELIGIBILITY)
    provenance: ItemProvenance,       -- ประวัติที่มาของไอเทม
}

-- 3. ข้อมูลโปรไฟล์สถิติตอน Spawn ที่แคชในหน่วยความจำ Server (Static Derived Card Profile)
-- หมายเหตุ A-04: คำนวณแบบ Pure Function ตอนสปอว์น มี Cache Invalidation Contract เมื่ออัปเกรด/รีสเปก
-- ห้ามนำเอฟเฟกต์ Trait เชิงเงื่อนไขในสนาม (เช่น ระยะไล่บอล, โซนป้องกัน) มาแคชค้างไว้ในโครงสร้างนี้
export type StaticCardProfile = {
    effectiveBaseStats: { [OutfieldStatId]: number }, -- Base + Custom Points (capped 1.15)
    effectiveSkillCeiling: number,                -- Base Ceiling + (Level >= 5 and 1 or 0) capped at 5★
    staminaProfile: StaminaDiscountProfile,       -- ส่วนลดเฉพาะ 5 กลุ่มแอ็กชันตามคำสั่ง Owner U3
    resolvedTraits: { ResolvedTraitEffect },      -- Trait ที่มีผลจริงในสนาม
}

-- ส่วนลด Stamina เฉพาะ 5 กลุ่มแอ็กชันตาม U3 (ไม่รวมยิง, กระโดด, ดูดบอลแรก; ท่า 0 cost คงเดิม)
export type StaminaDiscountProfile = {
    skillMovesMultiplier: number,                 -- 1.00 (Lv 0..3), 0.88 (Lv 4), 0.80 (Lv 5)
    sprintDashMultiplier: number,                 -- 1.00 (Lv 0..3), 0.88 (Lv 4), 0.80 (Lv 5)
    slideTackleMultiplier: number,                -- 1.00 (Lv 0..4), 0.80 (Lv 5)
    quickPokeMultiplier: number,                  -- 1.00 (Lv 0..4), 0.80 (Lv 5)
    bodyCheckMultiplier: number,                  -- 1.00 (Lv 0..4), 0.80 (Lv 5)
}

export type ResolvedTraitEffect = {
    traitId: TraitId,
    tier: "TierI" | "TierII",
    isAwakened: boolean,
}
```

### 3.2 Celebration & Visual Identity Schema (A-03 & A-04 Compliance)

```luau
export type CelebrationCategory = "GoalCelebration" | "BallAction" | "Movement"

-- สเปกท่าดีใจ (แยก Duration รวม ออกจาก Duration และ Trigger Offset ของ Impact Frame ชัดเจน)
export type CelebrationDefinition = {
    celebrationId: string,
    displayName: string,
    category: CelebrationCategory,
    rarity: "Common" | "Rare" | "Epic" | "Legendary",
    
    cutsceneDurationSec: number,        -- 3.0 ถึง 4.0 วินาทีสำหรับ GoalCelebration
    impactFrameDurationSec: number,     -- 0.15 วินาทีถ้วน (ระยะเวลาที่เฟรมภาพคอนทราสต์อนิเมะคงอยู่)
    impactFrameTriggerOffsetSec: number,-- วินาทีที่ตัดเข้า Impact Frame นับจากเริ่มคัตซีน
    
    animationClipId: string,
    cameraTrackAnimationId: string?,
    vfxId: string?,
    sfxId: string?,
    signatureCharacterId: string?,      -- สำหรับ Signature Sync Bonus (Cosmetic Only)
}

-- ประวัติที่มาของไอเทมและการกำกับดูแลตาม Roblox Policy (A-03 Compliance)
export type ItemProvenance = {
    sourceType: "FreeGacha" | "PaidGacha" | "StarterPack" | "MatchReward" | "DirectRobux",
    acquiredTimestamp: number,
    -- หมายเหตุ A-03: isTradeable ระบุเฉพาะคุณสมบัติสถิติของไอเทม (เช่น ไอเทมผูกมัดบัญชี)
    -- ห้ามใช้ทดแทนการตรวจเช็กสิทธิ์จริงจาก PolicyService:GetPolicyInfoForPlayerAsync ของผู้เล่นทั้ง 2 ฝ่าย ณ เวลาทำธุรกรรม
    isTradeable: boolean,
    transactionReceiptId: string?,
}
```

### 3.3 Player Profile Extension Schema

```luau
export type PlayerProfileDataExtension = {
    hasPurchasedStarterPack: boolean,   -- จำกัด 1 ครั้งต่อบัญชี (U7)
    
    -- เศษการ์ดสำหรับ Limit Break (หมายเหตุ: อัตราแลกเปลี่ยน Shard ต่อนักเตะซ้ำเป็น PENDING GRILL)
    cardShards: { [characterId: string]: number },
    
    ownedCelebrationIds: { string },    -- Canonical field name (alias: ownedCelebrations)
    equippedBallActionFxId: string?,
    equippedMovementFxId: string?,
    equippedGoalCelebrationId: string?,
    
    activeLoadoutPresetIndex: number,   -- ค่าตั้งต้นมาตรฐาน (การขยายสล็อตเป็น PROPOSED PENDING GRILL)
    provenanceAuditLogs: { ItemProvenance },
}
```
