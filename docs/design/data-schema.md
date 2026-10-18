# Data Schema & Domain Models (`src/shared/Types.luau`)

## 1. โครงสร้างข้อมูลผู้เล่น (`PlayerProfileData`)
- `userId: number` — รหัสผู้เล่น Roblox
- `cash: number` — เงินในเกม (`Cash`)
- `level: number` — เลเวลผู้เล่น
- `exp: number` — ค่าประสบการณ์สะสม (`EXP`)
- `pityCounter: number` — ตัวนับการันตีกาชา (`0–100`)
- `equippedCardId: string` — รหัสการ์ดนักเตะที่สวมใส่ปัจจุบัน
- `equippedThreadUid: string?` — รหัสชุด `Battle Threads` ที่สวมใส่ปัจจุบัน (ไม่มีช่องรองเท้าสตั๊ด)
- `equippedCelebrationId: string` — รหัสท่าดีใจหลังยิงประตู
- `ownedCards: {string}` — รายการการ์ดนักเตะที่ครอบครอง
- `ownedThreads: {BattleThreadInstance}` — รายการชุด `Battle Threads` ที่ครอบครอง
- `ownedTraits: {TraitStoneInstance}` — รายการหิน `Trait` ในกระเป๋า

## 2. โครงสร้างข้อมูลการ์ดนักเตะ (`PlayerCardConfig`)
- `cardId: string`
- `displayName: string`
- `tier: "B" | "A" | "S"`
- `heightScale: number` (เช่น `0.92`, `0.98`, `1.03`, `1.08`)
- `widthScale: number`
- `statModifiers`: `{ speedMultiplier: number, shotMultiplier: number, passMultiplier: number, tackleMultiplier: number }` (ห้ามฉีกห่างจากการ์ดเริ่มต้นเกิน `15%` หรือ `1.00–1.15`)
- `signatureChoiceId: string`
- `signatureCooldownSec: number`
- `winCutsceneAnimIds: {string}` (จำกัดจำนวนตาม Tier: `B = 1`, `A = 2`, `S = 3`)
- `celebrationAnimId: string`

## 3. โครงสร้างข้อมูลชุด `Battle Threads` และ `Mutated Gear` (`BattleThreadInstance`)
- `threadUid: string` — รหัสเฉพาะของไอเทมแต่ละชิ้น (ป้องกันการปั๊มของ)
- `threadConfigId: string`
- `rarity: "Common" | "Rare" | "Epic" | "Legendary"`
- `maxTraitSlots: number` (`1` หรือ `2` ช่อง)
- `equippedTraitIds: {string}`
- `mutation: MutationData?`
  - `mutationType: "GoldenAura" | "VoidGlitch" | "BloodMoonFlame"`
  - `vfxId: string`
  - `cashMultiplier: number` (`1.5` ถึง `5.0`)
  - `expMultiplier: number` (`1.5` ถึง `3.0`)
  - `tradeValueBonus: number`
  - *(หมายเหตุ: ห้ามมีฟิลด์บวกค่าสเตตัสในสนามเด็ดขาด)*

## 4. โครงสร้างข้อมูลธุรกรรมตลาดเทรด (`TradeSessionData`)
- `tradeId: string`
- `initiatorUserId: number`
- `partnerUserId: number`
- `initiatorOfferUids: {string}`
- `partnerOfferUids: {string}`
- `initiatorLocked: boolean`
- `partnerLocked: boolean`
- `lockTimestamp: number?` (ต้องล็อกครบทั้ง 2 ฝั่งและรอนับถอยหลัง `3 วินาที` ก่อนกดยืนยันขั้นสุดท้าย)
- `initiatorConfirmed: boolean`
- `partnerConfirmed: boolean`
- `status: "Active" | "Locked" | "Completed" | "Cancelled"`
