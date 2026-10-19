# Architecture & Network Contract — Cage Zero

> Current scope: ผู้ใช้เลือก [Phase 1](../plan/phase-01-gameplay-demo/plan.md) แล้ว; [Phase 2](../plan/phase-02-full-match-and-progression/plan.md) รอ Phase 1 เสร็จครบก่อน ยังเป็นการจัดแผน ไม่มีสิทธิ์ implementation จากคำสั่งนี้; [roadmap](../plan/roadmap.md)

## 0. Source baseline และ Studio MCP
- Source baseline ใน Git คือ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182` มีไฟล์หลายโมดูลอยู่แล้ว การมีโค้ดหรือสถานะ APPROVED เดิมยังไม่ใช่หลักฐานว่าแผนรอบปัจจุบันผ่านการอนุมัติ
- Prototype ที่ผู้ใช้ทดลองใน Studio คือ `FootballSandbox` ใน `sandboxcage-zero` (place `112091950831355`) ใช้ซอร์สคนละชุดกับ `src/`; ต้องเทียบ behavior ก่อนนำมาใช้ ไม่เพิ่มทุกพฤติกรรมของ prototype ลง PRD โดยอัตโนมัติ
- เก็บ sandbox เป็น local reference ใน root `.sandbox/` และ ignore ด้วย `/.sandbox/`; snapshot แรกมี 7 สคริปต์พร้อม manifest ที่ `.sandbox/reference/football-sandbox/` ส่วน `.sandbox/football-sandbox/` เป็น ref ที่มีการแก้ต่อจากภายนอกรอบนี้
- เมื่ออนุมัติลงมือแล้ว ใช้ Studio MCP โดยตรงและเก็บ source หลักใน repo ตรวจ source/path/hash ก่อนเขียน Studio ทุกครั้ง; ไม่ใช้ Rojo เป็นขั้นตอนหลัก
- แยกแพ็กเกจ/fixture ทดลองจาก gameplay ของผู้ใช้ และไม่หยุด Play หรือเขียนทับ source ที่มีการแก้ค้างโดยอัตโนมัติ
- โค้ด/เทสต์ที่ Codex ทำเกินขอบเขตรอบก่อนถูกเก็บที่ `.sandbox/plan1/implementation-attempt/` แล้วคืน source หลักกลับ baseline; ผล 24/24 เป็นหลักฐานของงานทดลองนั้น ไม่ใช่การตรวจรับ Plan 1
- แพ็กเกจ `ServerStorage.CageZeroDevelopment` ที่สร้างไว้เป็น ModuleScripts ทดลองที่ยังไม่เชื่อมกับ gameplay; ไม่ถือเป็น source หลักหรือ release ที่ผ่านอนุมัติ

## 1. โครงสร้าง Client-Server (100% Server-Authoritative)
- **Server (`src/server/services/`):** คำนวณและตรวจสอบผลแพ้-ชนะในการดวล (`DuelEngineService`), ระยะยิง (`Shooting Zone`), หน้าต่างเวลา `Parry` (`ParryService`), คูลดาวน์ของ `Trait` และ `Signature Choice`, ฟิสิกส์การชิ่งลูกบอล (`CagePhysicsService`, `BallService`), อีเวนต์สนาม (`EventManagerService`), การสร้าง `Single Custom R15 Rig` (`RigAndCardService`), การสุ่มกาชา และการเทรดของ (`TraitAndThreadService`, `TradeMarketService`)
- **Client (`src/client/controllers/` & `src/client/ui/`):** รับอินพุตผู้เล่น ส่งคำขอผ่าน `RemoteEvent`/`RemoteFunction` แสดงผลมุมกล้องคัตซีน (`CameraCutsceneController`), เอฟเฟกต์สนาม (`EventVFXController`) และควบคุมหน้าจอผ่าน `UIManager.luau`
- **Shared (`src/shared/`):** เก็บ `Types.luau`, `Constants.luau`, `Network.luau` และตารางคอนฟิกใน `src/shared/configs/`

## 2. สัญญา Network ใน baseline (`src/shared/Network.luau`)
ตารางนี้เป็น contract เดิมที่ยังอยู่ใน source ไม่ใช่ contract ใหม่ที่ผ่านการออกแบบครบหลัง grill โดยเฉพาะ timed Parry ที่ผู้ใช้เปลี่ยนเป็นกระโดดบล็อก; แผนที่เลือกลงมือต้องตรวจ/แก้ contract ให้ตรง decisions ก่อน ห้าม reuse endpoint เดิมผิดความหมายหรือเพิ่มเองโดยไม่ระบุในแผน:

| ชื่อ RemoteEvent / Function | ชนิด (Type) | ทิศทาง | พารามิเตอร์ที่ส่ง (Payload) | โมดูลที่ใช้งาน |
| :--- | :--- | :--- | :--- | :--- |
| `BallActionRequest` | `RemoteEvent` | Client -> Server | `(actionType: "Pass" \| "Shoot" \| "Sprint", aimVector: Vector3)` | Module 02 |
| `ParryWindowTrigger` | `RemoteEvent` | Server -> Client | `(ballId: string, windowDuration: number)` | Module 02, 07 |
| `ParryAttemptRequest` | `RemoteEvent` | Client -> Server | `(clientTimestamp: number)` | Module 02 |
| `DuelStartEvent` | `RemoteEvent` | Server -> Client | `(duelId: string, role: "Attacker" \| "Defender", availableChoices: {string}, lockedChoices: {string}, timeLimit: number)` | Module 03, 07 |
| `DuelChoiceSubmit` | `RemoteEvent` | Client -> Server | `(duelId: string, selectedChoiceId: string)` | Module 03, 07 |
| `DuelResultEvent` | `RemoteEvent` | Server -> Client | `(duelId: string, winnerUserId: number, cutsceneAnimId: string, appliedBuff: string?)` | Module 03, 04, 07 |
| `FreeKickStartEvent` | `RemoteEvent` | Server -> Client | `(spotPosition: Vector3, timeLimit: number)` | Module 04, 07 |
| `FreeKickSubmit` | `RemoteEvent` | Client -> Server | `(aimDir: Vector3, spinOffset: Vector2, powerPercent: number, timingZone: "Green" \| "Yellow" \| "Red")` | Module 04, 07 |
| `MatchEventBroadcast` | `RemoteEvent` | Server -> Client | `(eventType: "PillarLockdown" \| "BlackoutVoid" \| "FavelaAlley", state: "Warning" \| "Active" \| "Ended", payload: any)` | Module 05, 07 |
| `InventoryEquipRequest` | `RemoteEvent` | Client -> Server | `(category: "Card" \| "Thread" \| "Trait" \| "Celebration", itemId: string, slotIndex: number?)` | Module 06, 07 |
| `SummonRequest` | `RemoteFunction` | Client -> Server | `(bannerId: string, count: 1 \| 10)` -> คืนค่า `{ObtainedItems}` | Module 06, 07 |
| `TradeActionRequest` | `RemoteEvent` | Client -> Server | `(tradeId: string, action: "AddItem" \| "LockOffer" \| "ConfirmTrade" \| "Cancel", itemUid: string?)` | Module 06, 07 |


## 3. Architecture ที่เตรียมสำหรับ Plan 1
- **ขอบเขต:** รูปสนามกรง 6 เหลี่ยม, พื้น/เพดาน, bumper, rebound markers, ทางลาด และพื้นที่หลังประตู ตาม spec เดิม
- **เจ้าของ geometry และ collision:** `CagePhysicsService` สร้างสนามและคำนวณ collision จากข้อมูลพื้นผิวชุดเดียวกัน รวมตำแหน่ง, ขนาด, normal, ความหนา และรัศมีบอล ป้องกันสนามที่เห็นไม่ตรงกับจุดชิ่ง
- **สัญญาปัจจุบันที่จะรักษา:** `BuildHexCageArena(parent?)`, `ComputeReboundVelocity(velocity, normal, restitution)`, `StepBallCageCollision(position, velocity, dt) -> (position, velocity, surfaceTag?)`, `ApplyRampImpulse(velocity, isOnRamp)` และการตรวจ ramp/goal zones ไม่เพิ่ม network endpoint ใน Plan 1
- **ผู้เรียกในอนาคต:** BallService เป็นเจ้าของ state/การครองบอลและเรียก collision helper; match scheduler, การให้คะแนนและ UI เป็นความรับผิดชอบของแผนถัดไป ไม่เริ่มแก้จากการเตรียม architecture นี้
- **ข้อมูลตั้งต้นที่เสนอ:** คง outer extents X±80/Z±120, พื้น Y=0/เพดาน Y=32, บอลรัศมี 1.25 ตาม baseline; สร้าง hexagon ที่ผนังต่อกันจริง รายละเอียด vertices/CFrame ต้องตรวจเป็น design ก่อน implementation
- **ข้อกำหนดผลิตภัณฑ์เดิม:** bumper restitution 1.25, ramp 25 องศา, back zone 14 Studs และเพดานชิ่ง ไม่เปลี่ยน PRD/spec เพื่อให้ตรงกับโค้ดเก่า
- **แนวทาง collision ที่เสนอ:** ใช้ swept collision/time of impact กับรัศมีบอลและเวลาที่เหลือ; ระบุข้อจำกัดที่ขอบ/มุมและกรณีหลาย contact ชัดเจน ไม่อ้าง Zero Clipping จากการ clamp ตำแหน่งหรือผ่าน build เพียงอย่างเดียว
- **ทางลาด:** ใช้ CFrame/Size เดียวกับชิ้นสนามตรวจ footprint และช่วงความสูง บอลนอกปลาย/ด้านข้าง/ใต้ ramp ต้องไม่ได้แรงยก
- **การตรวจรับ:** ทดสอบกับ geometry ที่สร้างจริง ทุกผนัง/เพดาน/bumper, high speed, corners/grazing, ramp bounds และการวิ่งอ้อมหลังประตู; แยก automated tests ออกจาก visual UAT

## 4. ลำดับและขอบเขตตาม phase
- ใช้โฟลเดอร์แผนจริงใน [Phase 1](../plan/phase-01-gameplay-demo/plan.md) และ [Phase 2](../plan/phase-02-full-match-and-progression/plan.md) ไม่ใช้ชุดรหัส feature แยก
- Phase 1 แผน 00/01 เป็นฐาน Rig/สนาม/physics, 02 player actions, 03 duel, 04 โกล, 05 ลูกนิ่ง, 06 ซ้อม/หุ่น, 07 อีเวนต์, 08 gameplay UI และ 09 UAT
- Phase 2 แผน 00/01 แมตช์/ตัดสินเสมอ, 02 transactions, 03 สุ่มตัวละครและ stats ชุดเล็ก, 04 collection/เศรษฐกิจ, 05 เอฟเฟค, 06 ตลาด, 07 meta UI และ 08 full integration/UAT; transactions เป็นฐานก่อนรายการ Cash/ไอเทม
- โกล/ลูกนิ่ง/อีเวนต์ใน Phase 1 ใช้ controller ฉากฝึกเท่าที่จำเป็น ไม่ดึง full match clock/result/รางวัลของ Phase 2 มาทำก่อน
- การ์ดกาชา/collection/meta UI ที่เคยอยู่แผนคร่อม phase แยกเป็นแผนเฉพาะแล้ว เอฟเฟคสองชุดไม่มีสเตตัสและขายผ่านแผงเท่านั้น สกิลยิง/ส่งที่ตัดไม่กลับมาจาก base stats นักเตะ
- รูปแบบกติกาและ delta จาก spec เดิมดู [accepted decisions](../plan/phase-01-gameplay-demo/01-cage-physics/notes.md); sync ส่วนที่ทำก่อน implementation ไม่ลบฟีเจอร์ที่เลื่อนไป phase ถัดไป
- Phase 2 เริ่มได้เมื่อ Phase 1 เสร็จครบและผ่าน gate เท่านั้น รายงานเก่าไม่ใช้ข้าม gate
