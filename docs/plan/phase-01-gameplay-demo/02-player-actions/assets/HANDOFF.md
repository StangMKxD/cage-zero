# HANDOFF CONTRACT — 02-player-actions (บอล การเคลื่อนที่ และปุ่มตามทีม)

- **Date:** 2026-10-21 (Asia/Bangkok)
- **Active Plan:** `02-player-actions`
- **State:** `READY_FOR_AGY / SANDBOX_ADAPTATION_AUTHORIZED`
- **Owner:** คุณ Stang
- **Controller / Reviewer:** Codex
- **Implementer:** AGY Teamwork-preview
- **Current Baseline:** Git HEAD `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + uncommitted working tree ตาม AGY fix-001
- **Prerequisites & Upstream States:**
  - `00-bootstrap-and-rig`: `OPEN / PAUSED_BY_OWNER` (ยังไม่ปิดแผน 00 ตามคำสั่ง Owner)
  - `01-cage-physics`: `OPEN / PENDING_TECHNICAL_REVIEW` (แก้ไข F-05 เสร็จสมบูรณ์แล้วใน [fix-005.md](../../01-cage-physics/assets/fix-005.md); Owner สั่งพักรอ technical check ภายหลัง โดยยังไม่ปิดแผน)
- **Design Authority:** [Spec 02 — ฟุตบอลต่อเนื่อง](../../../../specs/spec-02-duel-and-parry.md) (มติ Q22 ลบระบบ Choice/Parry และเปลี่ยนเป็น Continuous Football 100%)

---

## 1. ลำดับการอ่านเอกสาร (Required Reading Order)

1. [docs/READ.md](../../../../READ.md) — สถานะภาพรวมและกติกาโปรเจกต์
2. [agent.md](../../../../../agent.md) — แผนปัจจุบันและขอบเขตกฎความปลอดภัย
3. [docs/specs/spec-02-duel-and-parry.md](../../../../specs/spec-02-duel-and-parry.md) — สเปกฟุตบอลต่อเนื่องและระบบปุ่มตามทีม
4. [plan.md](../plan.md) — ขอบเขตและสัญญาของแผน 02
5. [tasks.md](../tasks.md) — รายการงานและเกณฑ์การตรวจรับ
6. [notes.md](../notes.md) — บันทึกการตัดสินใจและคำสั่ง Owner ล่าสุด

---

## 2. ขอบเขตการทำงาน (Workstream Breakdown)

### Workstream 1: `BallService` (Server-Authoritative Single Writer)
- **ไฟล์เป้าหมาย:** `src/server/services/BallService.luau`
- **หน้าที่หลัก:**
  1. ควบคุม Instance ลูกบอลจริง (`Workspace.CageMatchBall`, Sphere radius 1.25 studs ตาม `Constants.BALL_RADIUS`)
  2. จัดการสถานะลูกบอล:
     - `Possessed`: ผู้เล่นคนใดครองบอลอยู่ (ยึดตำแหน่งให้อยู่ด้านหน้าเท้าตามทิศทางการเลี้ยง)
     - `Free / InFlight`: บอลลอยหรือกลิ้งอิสระ คำนวณฟิสิกส์ร่วมกับ `CagePhysicsService.StepBallCageCollision`
  3. บันทึกและอัปเดต `LastPossessingTeam` ("North" หรือ "South")
  4. ตัดโค้ดระบบเก่าที่ไม่ใช้แล้วออก: `1v1v1`, `ParryService` hooks, `ChoiceEngine` hooks, และ `miracleFinish`

### Workstream 2: ระบบปุ่มตามบริบททีม (Team-Context Action Buttons)
- **Owner delta 2026-10-21:** รอบนี้port Slide ก่อน ส่วนPoke/Shoulderอยู่03ภายหลัง ไม่เปิดสามท่าพร้อมกัน
- **สเปก:** ตาม Spec 02 §2
  - **ทีมเราครองบอล หรือบอลอิสระหลังทีมเราครองล่าสุด:** ปุ่มหลัก = ยิง (Shoot), ปุ่มรอง = ส่ง (Pass), ปุ่มที่สาม = ยิงโค้ง (Curve Shoot)
  - **ทีมคู่แข่งครองบอลล่าสุด:** ปุ่มป้องกัน (เตรียมเชื่อมกับแผน 03: Slide / Poke / Shoulder)
- **กติกาสำคัญ:**
  - ทั้งทีมยังคงสถานะโหมดบุกแม้จะยิงหรือส่งบอลออกไปแล้ว (บอลอิสระ)
  - โหมดปุ่มจะสลับข้างต่อเมื่อคู่แข่งเข้าครองบอลสำเร็จ (Confirmed Possession) เท่านั้น การที่บอลเด้งชนตัวหรือชิ่งกำแพงไม่ทำให้ปุ่มสลับ
  - ไม่แปลง input กลางคัน (Input ที่กดค้างระหว่างจังหวะเปลี่ยนโหมดต้องถูก cancel อย่างปลอดภัย)

### Workstream 3: การเคลื่อนที่, Stamina และ Directional Jump
- **ไฟล์เป้าหมาย:** `src/client/character/R6AnimationController.luau`, `src/client/controllers/InputController.luau`, `src/server/services/BallService.luau`
- **หน้าที่หลัก:**
  1. การเคลื่อนที่พื้นฐาน: เดิน (Walk speed 16), วิ่งเร็ว (Sprint speed 24), แดช (Dash burst impulse)
  2. **Directional Jump:** ล็อกเวกเตอร์ความเร็วแนวราบตอนเริ่มกระโดด **ห้ามเปลี่ยนทิศทางกลางอากาศ**
  3. **Stamina Pool:** ค่า 0.0 – 1.0 จัดการบน Server:
     - Sprint และ Dash ใช้ Stamina ตามอัตราที่กำหนด
     - เมื่อ Stamina หมด (Exhausted): วิ่ง Sprint หรือ Dash ไม่ได้, เลี้ยงบอลแตะห่างขึ้น แต่ยังเดิน ยิง ส่ง และยืนตัดบอลได้ตามปกติ (ไม่สุ่มเสียบอล)

### Workstream 4: ระบบการยิง ส่ง และการเล่นจังหวะแรก (First-Time Play)
- **Shoot & Curve:**
  - ยิงตรง: บอลพุ่งตรงด้วยความเร็วตามระดับการชาร์จ
  - ยิงโค้ง (Curve Shoot): ปุ่มแยกเฉพาะ คำนวณส่วนโค้งฟิสิกส์บน Server ตามทิศทางการเล็ง
- **Pass (Owner supersession 2026-10-21):** ส่งแบบเดียวเล็ง3D/ปรับแรงจากSandbox ไม่มีLobPass/ปุ่มส่งโด่งแยก; migrationตาม§6
- **First-Time Play (Header / Volley / First-Time Shot):**
  - ผู้เล่นสามารถยิงหรือส่งบอลได้ทันทีเมื่อบอลลอยหรือกลิ้งเข้ามาในรัศมีสัมผัส โดยไม่ต้องจับครองบอลก่อน
  - ตรวจสอบ Hitbox จริง ไม่มีการันตีเข้าประตูอัตโนมัติ

---

## 3. กฎความปลอดภัยและการปกป้อง (Protection & Non-Goals)

1. **ห้ามแตะต้องหรือแก้ไข:**
   - โค้ดสนาม `CagePhysicsService.luau` และโมเดล `Workspace.HexCageArena` (งานแผน 01)
   - สัญญาตัวละคร R6 จากแผน 00 (`ServerStorage.CageZeroStandardR6Rig`, `RigAndCardService.luau`)
   - Reference Sandbox (`112091950831355`) และ `.gitignore`
2. **ไม่เปิดฟีเจอร์นอกขอบเขต Phase 1:**
   - ห้ามนำระบบสุ่ม/กาชา, UI ซื้อขาย, หรือระบบ Match Loop 5 นาทีจาก Phase 2 มาทำแทรก
   - ห้ามคืนระบบ Parry แบบจับเวลาหรือ Choice duel cutscene ที่ตัดออกไปแล้ว
3. **Git Policy:**
   - ห้ามทำ git commit, push, merge, deploy หรือลบ branch โดยไม่ได้รับคำสั่งเป็นลายลักษณ์อักษรจาก Owner
   - ส่งมอบเป็น Working Tree พร้อมรายงานสถานะ

---

## 4. เกณฑ์การตรวจสอบและส่งมอบ (Verification Gates)

1. **V-01 (Ball Lifecycle & Possession):** บอลเกิดที่จุดกึ่งกลางสนาม เข้าครอบครองเมื่อแตะตัว เลี้ยงบอลตามตัวละคร และหลุดเมื่อถูกสั่งยิง/ส่ง
2. **V-02 (Team Context Toggle):** ปุ่มสลับระหว่างทีมบุกและทีมรับอย่างถูกต้อง และคงสถานะโหมดบุกไว้ระหว่างบอลลอยอิสระ
3. **V-03 (Directional Jump & Stamina):** กระโดดไม่สามารถเลี้ยวกลางอากาศได้, Stamina ลดลงเมื่อ Sprint/Dash และรีเจนเมื่อหยุดพัก
4. **V-04 (First-Time Play):** สามารถโหม่ง (Header) หรือยิงวอลเลย์ (Volley) บอลกลางอากาศได้ตามวิถีจริง
5. **V-05 (Studio Parity):** ไฟล์ Source Scripts ตรงกับ DataModel ใน Studio Place4 ครบ 100%

---

## 5. ตารางอนุญาตการแก้ไขสัญญาและไฟล์ (Locked Contract Allowlist — F-18)

| File Path | Scope & Boundary | Allowed Modifications |
| --- | --- | --- |
| `src/shared/Constants.luau` | Shared parameters | เพิ่ม `BALL_SPAWN_POSITION`, `HIGH_JUMP_POWER`, `HIGH_JUMP_HEIGHT`, `DASH_SPEED_BURST`, `GROUND_ROLLING_FRICTION`, `BALL_REST_THRESHOLD_SPEED` |
| `src/shared/Types.luau` | Type contracts | เพิ่ม `isCharging: boolean?`, `chargePower: number?` ใน `PlayerMovementSnapshot` |
| `src/server/services/BallService.luau` | Single Authoritative Ball Writer | จัดการ Continuous Contact, Swept Collision, First-Time Intents, Rate Limiting, Authoritative Charge (`StartCharge`/`CancelCharge`), Takeoff/Landing Lifecycle, Player/Character Lifecycle (`CharacterAdded`, `Humanoid.Died`, Team Transfer) |
| `src/client/controllers/InputController.luau` | Client input & movement | ปรับแต่ง Instant Dash Burst Impulse, Smooth Directional Jump Lock & Orientation Lock, Authoritative Charging (`StartCharge`/`CancelCharge`), Quick Ball Reset (`X` key) |
| `src/client/controllers/TrainingHUD.luau` | Minimal Live Training Fixture HUD | แสดง Context (Attacking/Defending), Live Stamina bar, Ball status, Controls guide (T-05 / F-19) |
| `src/client/init.client.luau` | Client bootstrap | Chained `TrainingHUD.Init()` alongside `InputController.Init()` |
| `tests/e2e/TestHarness.luau` | Test Framework | เพิ่ม Strict NaN/Non-finite guards ใน `toBeCloseTo`, `toBeGreaterThan`, `toBeGreaterThanOrEqual`, `toBeLessThan`, `toBeLessThanOrEqual`, `toBeVector3CloseTo`, `toBeWithinBounds` (F-17) |
| `tests/e2e/Tier1_PlayerActions.luau` | Module 02 E2E Suite | 34 Test Cases (TC-P02-01..34) พร้อม `SafeTest` protected wrapper และ auto-teardown `cleanupAllMockPlayers()` ครอบคลุม F-10..F-17 |
| `tests/e2e/TestRunner.luau` | Master Test Runner | เพิ่ม `RunPlayerActions()` runner method |

## 6. Controller-locked delta — ต่อจาก AGY fix-001 / Selective Sandbox Port (2026-10-21)

**Authority:** Ownerยืนยันดึง sprint/dash/kick/pass/ยิงโค้ง+เกจ เว้นท่าโยก ตัดส่งโด่งแยก และ “ดึงระบบslideมา แต่จะทำpoke shoulderทีหลัง” พร้อมสั่งปรับเพิ่มจากรายงานAGYที่แนบ
**สถานะ:** READY_FOR_AGY / SCOPE_LOCKED ไม่ใช่dispatch/technical approval; §6แทนscope/contract/allowlistเดิมใน§1–5เฉพาะที่ขัดกัน โดยเฉพาะLobPass/Slide/UI
**Git:** ไม่อนุญาตcommit/push/merge/deploy/ปิดแผนในงานนี้ คำสั่งcommit01ก่อนหน้าจบที่617f523แล้ว 00/01ยังเปิดและพักตามเดิม

### 6.1 Baseline และสิ่งที่ต้องรักษา

ใช้main617f523+workingtreeของfix-001 ไม่ย้อนsourceรอบแรก Codexตรวจlocalhashจากรายงานใหม่ของOwnerตรง8/8ด้านล่างเท่านั้น **ยังไม่reviewรับรอง34/34,141/141,LivePlayหรือF-10..19**
รักษาonGround/rollingfriction, cameraQ/F Dash+Knock-onเดิม, Humanoid.StateChangedjump, servercharge, finite/lifecycleguardsและTrainingHUD ไม่ลบทิ้งหรือเพิ่มระบบซ้อน
ค่าดิสก์จริงWalk16/Sprint24/Dash46/CD1.2/cost0.20/Shoot60–130เป็นbaselineจูน; HIGH_JUMP_POWER65ไม่ใช่horizontalvelocity65 Ballradius1.25ไม่ใช้1.1ของSandbox เกณฑ์Headerเดิม3.2เป็นstudsไม่ใช่เมตร
คงค่าปัจจุบันเมื่อไม่จำเป็นต้องเปลี่ยน หากจูนให้รายงานold/new/reason/ผลruntimeในfix-002 ไม่อ้างเป็นสมดุลfinal

| Baseline file | SHA-256 |
| --- | --- |
| `src/shared/Constants.luau` | `fca27b1c081933c82e24c566a0ef601ae1e009f50c9427dc916d8a9aaf971bc1` |
| `src/shared/Types.luau` | `9634266a399c0aeb13149fc49eea2b99078c4be51b91fa69820ddba52af9478a` |
| `src/server/services/BallService.luau` | `168a74645576921061e0fa4a7e84ec106c4e4521f58bc3f947aef11847b9435a` |
| `src/client/controllers/InputController.luau` | `48c56f81c33fda17efc82a45a616060095b2672d49f443aef9d83e79c7243373` |
| `src/client/controllers/TrainingHUD.luau` | `11e480d63dda656f220ef417248dfb99faac9242a28b41063e31471decd59371` |
| `src/client/init.client.luau` | `3cae961240d44d596d1b7c9f2472ae95a68d6004b43f1e1fe47323305eabaeac` |
| `tests/e2e/Tier1_PlayerActions.luau` | `685afbe5475443dd32202ed8b81849f161e91c0eb8f122ec28422f58918bd205` |
| `tests/e2e/TestHarness.luau` | `0715455c938e5585364973078c5590469495f03f666bc1096ae49d4ab5bc960b` |

**Dirty protection:** .gitignore,agent,READ,notes01ที่encodingเสีย,เอกสาร02/review-001/fix-001,source02รวมTrainingHUD/R6/config/client+serverbootstrap,TestHarness/TestRunner/Bundled/PlayerActions ห้ามrevert/overwriteงานค้าง; before-stateใหม่ต้องแยกจากrollback/preเดิม

### 6.2 ต้นทางและส่วนที่ให้ดึง (read-only)

Primary: `.sandbox/prototype3/` ตามรายงานAGY; immutablecompare: `.sandbox/reference/football-sandbox/manifest.json` snapshot2026-10-19 Place112091950831355 (ตรวจlocal7/7ตรงmanifest)
Studioที่เชื่อมตอนตรวจมีเฉพาะCage-Zero Place137721422246269 ไม่มีliveSandboxparity ห้ามใช้StudioIDเก่าเป็นสิทธิ์เขียน หากเปลี่ยนไปใช้live sourceต้องreadbackhashและบันทึกเวอร์ชันก่อน ไม่แก้ต้นทาง

| Prototype3 path | SHA-256 / selected pointers |
| --- | --- |
| client/FootballClient.client.luau | `9b71d800b1a906af4fcc603a82022eea82e6f9d598ba87098f5afa083c730dab`; aim79,requestKick204,charge276/310/350,Sprint470,Dash479,Slide/end544/handle676,gauge1074,jump1629 |
| server/FootballServer.server.luau | `30af80c5feec60e3389b772571b64ba706b21cadd1f5f0b684df5f1d5fb01c92`; kick634,SlideTackle957,physics1328เฉพาะgroundrest/selectedcontacts ไม่ยกloop |
| shared/SandboxConfig.luau | `1833b4ed870bd4c9de1eedf9d412e8b720799ff502076e03a72ba57ffe32d23a`; movement/kick/charge/Slide subset,ResolveCurveShot344 |
| shared/FootballVFX.luau | `904d1da24ede68650136c526573bd763908a740f83eea40a7574ad2e7b6ec739`; เฉพาะhelperจำเป็นที่selectedactionsเรียก |
| shared/FootballVFXConfig.luau | `43fada3edcfa799d09a44aaccf8d20f5bf631eee9d7b8a6dc8e8f3e22d495401`; เฉพาะconfigของhelperข้างต้น ไม่เปิดpack/ownership |

ไม่ยกArenaBuilder/DummyController/score/goalreset/Match/Debugmenus/Feint/Cut/Skill5ท่า/3slots/Poke/Shoulderหรือremotefolderทั้งชุด
AdaptposeR15ไปยังR6jointsเดิม ไม่เปลี่ยนrigschema/scale/DefaultCard ไม่อ้าง12tracksจากชื่อ/profile; คืนTransform/AutoRotate/HipHeight/WalkSpeed/constraintsทุกexit
Knock-on Dashที่fix-001มีอยู่แล้วให้รวมเพียงครั้งเดียว ไม่ติดตั้งHeavyKnockOnskill03แฝงด้วยDash

### 6.3 Locked behavior / intent / snapshot

- BallServiceเป็นsingle writerของball/possession/team/resource ใช้CagePhysicsService solver/catalogเดิม ห้ามsecondHeartbeat/ballinstance/physicsloopหรือcopyclampสนาม±48.5/±78.5จากSandbox
- Canonical kickactions `DirectShoot|CurveShoot|Pass`; Passหนึ่งปุ่มเล็ง3D/ปรับแรงเล่นต่ำ/สูง/ชิ่งจากกลไกnormalpass ไม่บังคับY=0เพราะชื่อGroundPassเดิมและไม่ทำLobPassชื่อใหม่
- รับlegacyGroundPassเป็นaliasเข้าทางPassเดียวระหว่างย้ายผู้เรียก02; LobPassต้องrejectไม่mutationและถอนจากactiveTypes/config/UI/input/positive tests รวมปุ่มT
- คงremote `BallActionRequest`/12Definitions/gettersเดิม ไม่เพิ่มKickRequest/MovementRequest/FeedbackRequestของSandboxหรือใช้Duel/Parryremoteผิดความหมาย
- Tableintent: `action=Sprint|Dash|DirectionalJump|StartCharge|CancelCharge|DirectShoot|CurveShoot|Pass|Slide|ResetBall`; fieldsตามaction `aimDirection:Vector3?,isSprinting:boolean?,charge:number?` (chargeเป็นpresentationhint ไม่ใช่serverpower)
- ทุกintentมี `intentId:string(1..64),characterGeneration:integer,contextVersion:integer`; serverเป็นเจ้าของgeneration/version StartChargeเพิ่ม `chargeAction=DirectShoot|CurveShoot|Pass|Slide` แล้วrelease/cancelใช้intentเดิม ห้ามreleaseเป็นอีกaction
- Idempotencyตรวจตาม `(characterGeneration,contextVersion,intentId,phase)` โดยphase=start/release/cancel; startและreleaseของintentเดียวกันต้องผ่านได้ครั้งละหนึ่งphase อนุญาตtransitionstart→releaseหรือstart→cancelเพียงทางเดียว หลังterminalแล้วrejectทุกphaseซ้ำ Instantactionsประมวลผลครั้งเดียวต่อintent ไม่ใช้intentIdอย่างเดียวปฏิเสธreleaseหลังเห็นstart
- เมื่อcontext/death/respawn/resetเปลี่ยน serverยกเลิกpendingchargeก่อนเพิ่มversion/generation คำขอเก่าจึงrejectโดยไม่ทิ้งchargeค้าง ไม่เติมcurrentmetadataให้legacyrequestเพื่อข้ามstaleguard
- ย้ายclient/tests02พร้อมกัน; stringcompatibilityเดิมต้องผ่านvalidationเดียว ไม่เป็นทางข้ามfinite/alive/generation/context/rate/cost/CD/reach LegacyLobPassไม่คงไว้
- Serverคำนวณchargeจากเวลาตนเองและresolveaction/cost/CD/contact ไม่รับballvelocity/ผลชนะจากClient; cancel/release/StopSprintต้องไม่ถูกรate limitทำให้ค้าง
- ฝ่ายบุกใช้ยิง/ส่ง/โค้งรวมfirst-timeเมื่อballถึงจริง ไม่เอาSandbox “ไม่มีบอลส่วนตัว=Slide” มาใช้; contextตอนเริ่มintentล็อกไว้ ถ้าเปลี่ยนระหว่างholdให้cancel ไม่แปลงท่า
- Slideเป็นdefensiveintentแยกจากExecuteKickฝ่ายบุก ต้องgrounded/alive/ฝ่ายรับ/cost/CD/recovery/generationผ่าน ล็อกทิศเมื่อเริ่ม contact/hitwindowจริงผ่านownerบอล ไม่มอบpossessionหรือstunคู่แข่งอัตโนมัติ พลาดรอลุก ไม่มีI-frame ไม่เปิดฟาวล์05
- Snapshot/attributesเดิมเพิ่มเฉพาะ `isSliding,slideCooldownRemaining,recoveryRemaining,characterGeneration,contextVersion,chargeAction,lastResolvedAction,actionSequence`; คงisCharging/chargePowerและfieldsเดิม
- BallServicereplicatecharacterattributes `PlayerActionGeneration,ActionContextVersion,IsSliding,SlideCooldownRemaining,RecoveryRemaining,ChargeAction,ChargePower,LastResolvedAction,ActionSequence`; clientอ่านแสดงผล/กันstaletimer ไม่สร้างchargeauthorityจากUIและไม่เขียนattrserverเอง
- Failurefeedbackใช้attributesเพิ่ม `LastActionIntentId,LastActionStatus,LastActionReason` โดยstatus=Accepted/Rejected/Cancelled; reason=InvalidPayload/StaleIntent/WrongContext/NotAlive/OutOfReach/InsufficientStamina/Cooldown/Recovery/RateLimited/RemovedAction ไม่มีball/resource mutationเมื่อreject ClearUI/predictionเฉพาะintentและgenerationที่ตรงกัน; ไม่เพิ่มremoteใหม่ Authใช้Playerที่OnServerEventส่งมา ไม่เชื่อUserId/ทีมจากpayload Versioningอยู่generation/contextของsession ไม่ใช่HTTPหรือDBschema

### 6.4 Keymap / charge UI

| Control | รอบนี้ |
| --- | --- |
| Shiftสองข้าง / Q,F / Space | Sprint / Dash / DirectionalJump ตามfix-001 ไม่ย้อนQกลับเป็นPass |
| E / LMB | Attacking=DirectShoot hold/release; Defending=Slideintentตามcontextตอนเริ่ม |
| C,G / MMB | Attacking=Passแบบเดียวเล็ง3D/charge; ฝ่ายรับยังไม่เปิดPoke |
| R,V / RMB | Attacking=CurveShootปุ่มแยก; ฝ่ายรับยังไม่เปิดShoulder |
| T | ไม่ผูก/ไม่แสดงLobPass |
| X | QuickResetเฉพาะtraining/sessionที่อนุญาต ไม่เปิดresetmatchอนาคต |

AdaptKickChargeGaugeBg/segments/สี/labelจากprototype3ลงTrainingHUDrootเดิม คงContext/Stamina/ballstatus/guideของfix-001 ไม่ซ้อนScreenGui/แถบชาร์จ ไม่ดึงDummy/Skillmenus
แสดงhold/tap/เต็ม/ปล่อย/cancel/ชนิดactionจริง ใช้serverresolvedchargeกับผลยิง predictionได้แต่ต้องreconcileหลังreject/context/death/respawn/focuslost/reset
ขนาด/ตำแหน่งไม่บังบอลหรือcontrols กดUIไม่ยิงซ้ำ หนึ่งintentออกท่าได้ครั้งเดียว keyboard/mouseและtouchถ้านำปุ่มtouchมาด้วย

### 6.5 Exact target allowlist (แทน§5เฉพาะรอบport)

| Target | แก้เฉพาะ |
| --- | --- |
| src/server/services/BallService.luau:326/478/519/578/620/672/940 | integratekick/movement/Slide/resource/charge/intent/lifecycleตาม§6.3 รักษาfix-001 ไม่มีsecondballloop |
| src/client/controllers/InputController.luau:36/82/93/113/170/221 | selectedinputs/charge/Slide/aim/generation/keymap |
| src/client/controllers/TrainingHUD.luau:13 | segmentedgauge/guide/feedbackในrootเดิม |
| src/client/character/R6AnimationController.luau; src/shared/configs/RigAnimationConfigs.luau | selectedactionpose/provenance/cleanup คง00locomotion/ready/generation/rigschema |
| src/shared/Constants.luau; src/shared/Types.luau | เฉพาะModule02config/Pass/Slide/intent/snapshotตาม§6.3 ถอนLob; ไม่เปลี่ยนCage01/defaultcard |
| src/client/init.client.luau | hookHUD/actionvisualsที่จำเป็นในbootstrapเดิม ไม่เปิดUIManagerเต็ม |
| src/client/controllers/PlayerActionVFX.luau (สร้างได้ถ้าจำเป็น) | extracthelperเล็กของselectedactionsที่ถูกเรียกจริง ไม่copyeffectpackทั้งชุด |
| tests/e2e/Tier1_PlayerActions.luau | freshbehavior/protocol/singlePass/removedLob/gauge/Slide/lifecycletests ไม่ลดassertionsให้ผ่าน |
| tests/e2e/TestHarness.luau; TestRunner.luau | finite/teardown/runnerที่จำเป็น คงtests01 |
| tests/e2e/BundledTestRunner.luau | regenerateเฉพาะเมื่อcanonicalharnessเปลี่ยน ไม่แก้expectedresults01 |
| เอกสารT-99 | plan/tasks/notes/HANDOFF02,PRD/Spec02/TDD/architecture/glossary,READ/agent/phaseplan,seam03/UI08 ไม่แก้review-001/fix-001ย้อนหลัง |

Read-only: Network.luau,RigAndCardService,CardConfigs,rigtemplate,CagePhysicsService/HexCageArena/Baseplate,.gitignore,sourcemap,Sandboxทุกชุดและrollback/pre; serverbootstrap01ไม่อยู่allowlist
เกินallowlistให้แจ้งexactdependency/deltaก่อน ไม่อ้างfindingเป็นสิทธิ์ขยายscope

### 6.6 Verification และส่งมอบ

- V-01 preflightgit/dirty/sourceprototypehash/Place4ใหม่ก่อนsync เก็บbefore-state/rollbackตามartifactcontractเดิม ไม่ทับpre/ไม่เขียนReferencePlace
- V-02 groundrest/clearance/rollingจริงโดยไม่ดูดลูกกำลังขึ้น/ramp; DashQ/Fเคลื่อนได้Knock-onครั้งเดียว; Jumpไม่stutter/ไม่ทับverticalphysics
- V-03 input→remote→server→ball→HUDจริง: shoot/curve/Passหลายมุม/แรง/first-time; T/LobPassnegativeไม่mutation ไม่ใช้แค่mockเรียกว่าLivePlay
- V-04 segmentedgaugehold/release/tap/เต็ม/cancelตรงservercharge/context; exhausted/death/focuslost/reset/respawnแล้วspeed/pose/HUDไม่ค้าง ไม่ยิงซ้ำ
- V-05 Slidehit/miss/near-miss/no-ball/air/cost/CD/recovery/stalecontextจริง ไม่มีauto-possession/stun/I-frame คืนforces/constraints/poseครบ
- V-06 รักษาcontacts/deflect/highball/teamcontext/NaN/Inf/verticalaim/rate/lifecycleตามTDDและF-10..19; ไม่เปิดLobกลับเพราะtestเก่า
- V-07 affected01regression+sourceStudioParityตามไฟล์ที่เปลี่ยน; R6action/gaugevisualอ่านได้ ถ้าหลักฐานไม่พอระบุINCOMPLETE ไม่บังคับภาพ/วิดีโอ
- ทุกgateหลังport **NOT RUN**; 34/34/160assertionsและ141/141/445assertionsพร้อมLivePlayในfix-001เป็นhistoricalก่อนport ไม่ใช่freshpass/ZeroRegression
- ส่ง `assets/fix-002.md` ฉบับเดียว: retainedfix-001,sourcefunction/hash→targetmapping,old/newค่าจูน,currentgit/source/test/payloadhash,exactStudioID/Place/mode,ผลstatic/Edit/Live/visual/NOTRUNตามจริง
- คงF-10..F-19stable claimsCLOSEDในfix-001ไม่ใช่Codexsign-off ส่งREADY_FOR_REVIEWให้ตรวจcurrentref ไม่มีสิทธิ์approve/close/commitเอง

## 7. Owner-locked R6 animation / Shift Lock adaptation — 2026-10-21

**Authorityล่าสุด:** Ownerแจ้ง “เอฟเฟคอะไรไม่มีเลย animationก็มั่ว ... อนิเมชั่นยังไม่ผ่าน”, ยืนยันShift LockแบบSandbox และ “ในsandboxทำไว้ดีแล้วค่าต่างๆ เดี๋ยวเอามาปรับเพิ่มต่อในplanนี้”
รอบนี้ **REWORK / OWNER_VISUAL_REJECTED** ต่อจากfix-002และreview-002; §7แทน§6ที่ให้ยึดค่าปัจจุบันเมื่อไม่จำเป็นต้องเปลี่ยน ใช้Sandboxเป็นฐานความรู้สึก/ค่า/จังหวะแล้วค่อยจูนใน02 ไม่สร้างท่าใหม่จากชื่อclip
ผล40/40Edit/243assertionsเป็นAGYreported ไม่ใช่รับรองpose/LivePlayหรือปิดF-ID; source/testlockปัจจุบันอยู่review-002 00/01ยังเปิดและพัก ไม่commit/push/merge/deploy

### 7.1 ขอบเขตและต้นทาง

Mandatory: proceduralR6poseของselectedSprint/Dash/ยิงตรง/Pass/ยิงโค้ง/Slide + Shift Lock + แก้behaviorที่review-002ชี้
ต้นทางprimaryยังprototype3ตามhash§6; sourceเพิ่มเติม `shared/ShiftLockDribble.luau` hash `8b83d62ac128023ab68c0c3304c8214467a04025c2ab5934ebfdaefb8b066154` อ่านเฉพาะCalculate8Direction/CalculateProceduralJointsและmathที่จำเป็น **ไม่เอาCreateClientBallController/AlignPosition/ballwriterอีกชุด**
Liveหน้าต่างtestsandbox90251255542737ไม่ใช่Reference112091950831355โดยอัตโนมัติ; readsourceที่Reviewerลองคืนข้อความว่าง จึงยังใช้localhashที่ล็อก ไม่สลับเวอร์ชันเงียบๆ หากOwnerชี้เวอร์ชันใหม่ค่อยread/hash/บันทึกmapping
ห้ามดึงFeint/Cut/Skill5ท่า/3slots/Poke/Shoulder/score/Dummytools/cutscene/first-time-missstunจากSandbox; retaingroundrest/contacts/servercharge/lifecycleguardsของfix-001/002ที่ตรวจถูกแล้ว
เอฟเฟกต์เต็มของ07/08/Phase2คงdeferred/รอแผนเจ้าของตามOwner ไม่บังคับชุดVFX/เสียง/กล้องสั่นเพื่อผ่าน02 หากใช้selectedactionhelperเล็กตาม§6ต้องcleanupและไม่ขยายเป็นpack/ownership

### 7.2 ค่าตั้งต้นจากSandbox (ไม่ใช่finalbalance)

| Selected parameter | Prototype3 seed / การแปลงที่จำเป็น |
| --- | --- |
| Walk / Sprint / Dash | 20 / 32 / 58 studs/s; Dash0.22s/CD1.8s |
| Stamina | ต้นทางmax100→เกมmax1: Dash35→0.35, Sprint9/s→0.09/s, regen22/s→0.22/s, recoverydelay0.35s; Slidecostที่ไม่มีค่าตรงในsourceให้คงค่าจูนเดิมและระบุว่าไม่ใช่ค่าต้นทาง |
| Jump | JumpPower72 / configuredJumpHeight15.5ตามต้นทาง ไม่แปลเป็นhorizontalvelocityหรือทับverticalกลางair; ใช้actualhumanoidmodeของrig |
| Charge | maxTime0.85s, min0.50/max1.00, tap threshold/power curveตามprototype3; serverเป็นauthority |
| Pass / shot / curve | ใช้KICK_PRESETSและselectedkicksolverต้นทาง: Passbase68, Straight125, unifiedCurve95; Finesse82/Trivela84เป็นunderlyingstyleของCurveปุ่มเดียว พร้อมsourcebias/spin/gravityที่เกี่ยวข้อง ไม่คงslider50–85/60–130เพียงเพราะfix-002ทำไว้ |
| Slide | speed52, duration0.44, CD1.05, reach8.5 และcharge scalingตามต้นทาง; slidehitresponseจากcoreSlideTacklebranchให้ระบุmappingชัด (branchใช้SLIDE_KICK_SPEED94 ขณะที่KICK_PRESETS.SlideKick118เป็นอีกเส้นทาง ห้ามสลับโดยไม่บอก) |
| Camera | AUTO_SHIFTLOCK_DEFAULTtrue, shoulder(1.75,0.45,0), smoothingalpha0.18ที่60fpsตามต้นทาง |

ไม่copyradius1.1/สนาม100x160/สเกลR15หรือมุมคานจากprototype: targetBallradius1.25/geometry01/rigschema00คงเดิม
นำselectedphysicsbehaviorเข้ากับsinglewriter/solverเดิม พร้อมunit mapping/caps ไม่เปิดloopแยก old→source→adaptedค่าจริง/เหตุผลอยู่fix-003 ให้Ownerจูนต่อใน02ได้โดยไม่อ้างสมดุลผ่านแล้ว

### 7.3 แบบแอนิเมชัน — adaptposeที่ทำไว้แล้ว ไม่เปลี่ยนชื่อjumpclipเป็นaction

ยึด `FootballClient.applyClientProceduralAnimations` ของprototype3 (selectedbranches) และShiftLockDribblemathเป็นแบบท่าร่าง ฟังก์ชัน/branch→targetprofileต้องมีmappingในfix-003 ไม่ใช้จำนวนtracksหรือassetIDเป็นacceptance

| State | ท่าร่าง/จังหวะจากSandboxที่ต้องเห็นบนR6 |
| --- | --- |
| Walk/Sprint/8-waystrafe | ใช้ทิศobject-space/stridephase/speedalphaของต้นทาง ขาสลับตามเดินหน้า/ถอย/ข้าง แขนสวนก้าว ลำตัวเอนตามความเร็ว ไม่เล่นwalkloopเร็วขึ้นอย่างเดียว |
| Dash | entry→burst→returnตามdashdurationที่ใช้จริง ท่าพุ่งตัวเอน/แขนสมดุล/ขานำอ่านออก แยกจากกระโดด ใช้directionที่serverยอมรับ ไม่เพิ่มKnock-onซ้ำ |
| ChargeDirectShoot | ใช้sourcepullAlphaง้างขา/ถ่ายน้ำหนัก/แขนสมดุลเป็นholdposeตามservercharge เคลื่อนที่ระหว่างholdได้ตามresolvedspeed |
| DirectShoot release | เท้าตั้งรับน้ำหนัก เท้ายิงเหวี่ยงผ่านบอลและfollow-throughตามsourcekickwindow (sourceสูตรใช้0.28s) จังหวะcontactสัมพันธ์กับserverballrelease ไม่เพิ่มphysicalwindupdelayเองเพื่อให้ภาพดูตรง |
| Pass | เปิดสะโพก/หน้าเท้าด้านในและfollow-throughสั้นตามsourcePassbranch เห็นต่างจากPowerShoot; กดชุดเดียวเล็ง3D/ชาร์จ ไม่มีLobแยก |
| CurveShoot | ใช้ResolveCurveShot/charge-side/follow-throughของFinesseหรือTrivelaตามต้นทาง เท้า/สะโพก/ไหล่ชี้ด้านที่ออกลูกจริง ไม่สุ่มหรือเล่นkickทั่วไปซ้ำ |
| Slide | ลำตัวลด/เอนหลัง ขานำเหยียด ขาหลังเก็บ แขนช่วยสมดุลจากsourceSlidebranch คงท่าตลอดactivewindow; hit→exitตามผลserver, miss→recover/get-upตามsource ไม่ใช้jump125750702แทนslide |
| Jump/Fall | คงtakeoff/lockedtravel/landingจริงและnativeverticalphysics; ไม่ดึงscissorVolley/first-time-misspenaltyของPhase2มาขยายรอบนี้ |

**R15→R6projection:** targetมีTorso/สองแขน/สองขาและ6Motor6Dเดิม ไม่เพิ่มknee/ankle/elbow/waist:
- Root+Waistposeของsourceแปลงเป็นRootJoint/Torsooverlay; Hip/Knee/Anklechainแปลงเป็นทิศขาR6เส้นเดียวที่อ่านท่าตรงกัน; Shoulder/Elbow/Wristแปลงเป็นแขนR6เส้นเดียว Neckใช้Headเดิม
- อ่านbaseC0/baseC1และscaleจริง ไม่copyEulerของR15ลงR6โดยตรง/สะสมทับC0 ให้เปรียบเทียบworldpose/stancefoot/clearanceกับต้นทาง รักษาเท้ารับน้ำหนักไม่จมพื้น
- มีposewriterเดียวในR6controller lifecycle; overlayกับbaseAnimatorหลังanimationevaluationอย่างกำหนดลำดับได้ ไม่ให้server/client/สองRenderSteppedแข่งเขียนjoint
- Priority: death/resetcleanup > confirmedSlide > resolvedreleasefollow-through > heldcharge > Dash > Jump/Fall > locomotion; suppressเฉพาะjointที่actionใช้แล้วblendกลับ ไม่มีposeเก่าค้าง
- ไม่anchorHumanoidRootPart/เปลี่ยนrigschema/แก้RigAndCardService ไม่ใช้memorytower/weldrigแทนplayerR6
- poseเริ่ม/จบจากserverresolvedaction/sequence+predictionที่reconcileได้ ผูกcharacterGeneration+intent token ไม่ปล่อยtrackที่serverrejectเล่นต่อ หากFinesse/Trivela/เท้าต้องส่งผลเพิ่ม ให้เพิ่มเฉพาะsnapshot/attrs `resolvedKickFoot` Left/Right และ `resolvedCurveStyle` Finesse/Trivela/empty โดยserverownerเดิม ไม่เพิ่มremoteใหม่

### 7.4 Shift Lock จากSandbox / centralorientation

- ใช้setShiftLockState/toggleShiftLock/MenuOpened/MenuClosedและcursor/shoulderoffsetในprototype3client:822–867,1064,1698–1720,2286–2328
- เปิดเป็นdefault กดLหรือLeftAlt/RightAltสลับ; Shiftสองข้างยังSprint ไม่ทำให้ShiftLocktoggleซ้อน nativecameraปกติยังzoom/orbitได้ ไม่เปิดCutsceneController
- ON: MouseBehaviorLockCenter, cursorกลางจอ, Humanoid.AutoRotatefalse และcamerashoulderoffset(1.75,0.45,0); yawตามกล้องแนวราบสำหรับgroundednormalmovementเท่านั้น
- OFF/menu/focuslost/TextBox/death/characterremove: ปล่อยcursorและrestorecamera/autorotateเดิมตามstate เมื่อกลับเข้าเกมใช้togglepreferenceเดิมและcurrentgeneration ไม่บังคับแย่งเมาส์จากเมนู
- priorityrotation: Slideล็อกslideDir; Jumpล็อกcommitteddirectionจนactualLanded; นอกสองท่านั้นจึงyawตามกล้องเมื่อShiftLockON; ไม่มีInputControllerหรือdelayedcallbackมาsetAutoRotatetrueแทรก
- camera/rotationwriterเดียว updateตามdtไม่สะสมCamera.CFrameoffset frameก่อนหน้า smoothingรักษาfeelalpha0.18@60fpsพร้อมพฤติกรรมสอดคล้อง30/60/120fps ไม่เพิ่มcamerashakeเพื่อแทนShiftLock
- ปุ่ม/indicatorL/Altเล็กในTrainingHUDเดิม ไม่ดึงDummytool rowหรือfullsettings08มา

### 7.5 Allowlist เพิ่มจาก§6 / ส่งแก้และรับงาน

สร้างได้เฉพาะเมื่อใช้จริง: `src/client/controllers/CameraShiftLockController.luau` (camera+rotationowner), `src/client/character/R6ActionPoseController.luau` (poseevaluatorที่R6AnimationControllerdelegatesครั้งเดียว), `src/shared/configs/PlayerActionPoseConfigs.luau` (selectedsourceprovenance/profileconfig)
ไฟล์เดิมตาม§6แก้integrationได้: InputController/R6AnimationController/TrainingHUD/clientinit/Constants/Types/BallService/selectedtests ไม่เพิ่มsecondballwriterหรือแก้Network/RigAndCardService/CardConfigs/CagePhysicsService/serverbootstrap01
ข้อแก้review-002F-13..18/F-20..24อยู่รอบนี้ ใช้servermovementresolver/statepriorityเดียว แยกgroundrestจากvalidupwardrebound ห้ามแก้reportก่อนหน้าให้กลายเป็นPASS; fix-003ฉบับเดียวพร้อมsource/test/prototype/currentrefhashและผลจริง
รับงานเมื่อrealR6แสดงselectedposesแยกได้+ShiftLockตามต้นทาง กล้องกับSlide/Jumpไม่สู้กัน cancel/reject/death/respawn/focus/menu/30–120fpsคืนstateครบ พร้อมstate/joint/camera evidenceตามsessionที่ตรวจจริง
ไม่บังคับscreenshot/video Ownerตรวจความรู้สึก/ภาพอีกครั้งได้ตามปกติ ระบุvisualINCOMPLETEถ้ายังดูจริงไม่ได้ ห้ามใช้TC40schema/assetIDหรือEdit40/40แทนvisualผ่าน
freshcontract/behavior/LivePlay/affected01regressionตาม§6ยังต้องทำ แยกNOTRUNตามจริง ไม่ใช้ผลfix-002รับรองsourcefix-003 ไม่มีcommit/push/merge/deploy/ปิดแผนจากสัญญานี้

## 8. Owner delta — Argon R6 Football Animation Pack / 2026-10-22

**Authority:** userส่งZIPให้Codexวิเคราะห์และขอpromptปรับเพิ่มใน02พร้อมแบ่งงานAGY; ในchatเลือกภาษาท่าใหม่แบบฟุตบอลสมจริงเน้นความเร็ว/ชิงจังหวะ และยืนยันค้างท่าง้างไม่สับขา. อนุญาตadapt visual02ตามสัญญานี้ ไม่ใช่รับรองภาพ/โค้ดZIPหรือปิดแผน.
**State:** READY_FOR_AGY_REWORK / DESIGN_REFERENCE_ONLY. ผลตรวจ [review-003](review-003.md): F-25..F-30 OPEN; findingsเดิมไม่ถูกปิด. GateEdit/Live/visualหลังเปลี่ยนทั้งหมดNOT RUN.
**Baseline:** main `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + dirtysource lockในreview003. ตรวจhashปัจจุบันใหม่ก่อนแก้ หากต่างให้reconcileกับงานเดิม ไม่reset/revert/ทับuserwork.
**Commit policy:** AGYไม่มีสิทธิ์สร้างlocalcommitเพื่อSHAtracking ใช้HEAD+workingtree/filehash ส่งreview ไม่มีcommit/push/merge/deploy/approve/close.

### 8.1 ต้นทางและลำดับอำนาจ

ZIP `C:\Users\Stang\Downloads\Roblox_R6_Football_Animation_Pack-20261022T055539Z-1-001.zip`; SHA256 `c82ef41b057e2a1a0675fd9b2771670a428f3f5720254cee13a8676177b46d49`.
ตรวจhashแล้วextractแบบกันpathtraversalเป็นreferenceimmutableใน `assets/designs/argon-r6-pack/` ภายในแผน02 โดยOrchestratorเจ้าของไฟล์นี้คนเดียว; ถ้ามีของเดิมห้ามoverwriteเงียบๆ. ไม่require/runincomingLuauบนcharacterเกมก่อนreview/adapt; ไม่คัดPlayerเข้าsrcทั้งชุด.
§8แทนเฉพาะข้อ§7.3ที่บังคับรูปลักษณ์poseจากSandboxเมื่อขัดกับvisualใหม่ที่userเลือก. gameplayvalues/keymap/charge/contact/ShiftLock/camera/rig/ballownershipยังตามcontractเดิมและsourceจริง ไม่เปลี่ยนตามpreviewtiming.
ลำดับauthority: Ownerchatdeltaนี้→contract02→resolvedruntimeaction/state→adaptedposeprofiles→ภาพ/ตัวเลขproposedในZIP. metadataReferenceY/worldcontact/OBBไม่ใช่คำสั่งย้ายHRPหรือผลเทสต์.

### 8.2 Visual mapping ที่อยู่ในรอบนี้

| ID | Target visual / integration |
| --- | --- |
| A01–A03 | Idle/Walk/Sprint ผ่านR6controllerเดิม; rig00/schema/scale/gettersคงเดิม จูนcadenceกับspeedจริง |
| A04–A05 | Dash entry/burst/returnตามactualduration และ8waygroundstrafeทิศobjectspace ไม่เปิดSkillMove |
| A06–A07 | actualtakeoff/up/apex/down→actualLanded→cushion→currentlocomotion ไม่timerflight/worldYfallback |
| A08–A09 | Header/Blockตามcontactจริง ไม่สร้างปุ่ม/auto-win/blockผลใหม่ |
| A10–A11 | Volley/Bicyclevisualตามairborne/resolvedactionที่มีอยู่ พร้อมลงพื้นจริง; ไม่เพิ่มstandinglaunch/jumpimpulse/ballisticsจากREADME |
| A12–A13 | directwindup/heldpose→resolvedreleasefollowthrough; HOLDค้างท่าง้างไม่walkcycle ไม่anchorHRP/เปลี่ยนmovementrules |
| A14–A15 | curvehold→Finesse/TrivelaตามResolvedCurveStyle/ResolvedKickFoot; mirrorเท้าที่ใช้จริง ไม่สุ่มvariant |
| A16 | Passชุดเดียว3D แปรภาพตามaim/power; ground/lobในZIPเป็นvisualvariant ไม่คืนLobPassaction/key/remote |
| A17–A18 | Slidevisualตามserveractivewindow→hit/missrecoverystateจริง ไม่ใช้.55/.44ในZIPแทนmechanics/CD/costเดิม |

แก้F-25/26ด้วยnativeevaluationของfinalposeระหว่างkeyframe/transition/smoothing/variants/scaleบนactualground ไม่แก้riggeometry/ballradius/physicsหรือยกrootเพื่อซ่อนclipping. สูตร/data/runtimeต้องตรงภาพหรือบันทึกwhyadapt.
F-27: stop/cancel/rejectเป็นterminalมีintent+generationtoken ไม่มีautonextปลุกท่ากลับมา; cleanupคืนjoint/trackownershipของcharacterเดิมเท่านั้น.
F-28/29: phaseผูกactualstate/serveroutcome จังหวะสัมผัสภาพสัมพันธ์releaseจริงโดยไม่หน่วงบอลใหม่ ใช้snapshot/attributesที่มี; ถ้าขาดcontractจริงให้รายงานexactdeltaเฉพาะdependencyนั้น.
Pose/jointwriterเดียวใต้R6controllerเดิม ไม่เพิ่มRenderStepped/PreSimulationอีกชุดแข่งกับC0/Transform/Animator; เลือกฐานrestจริงที่ไม่ปนposeค้างจากwriterเก่า. suppressเฉพาะtracks/jointsที่ท่านั้นครอบครองและคืนได้.
foot-slip/cadenceF-30ต้องวัดที่Walk20/Sprint32ตามactualconfig ไม่เปลี่ยนspeedให้เข้าภาพ.

### 8.3 Team AGY / disjoint ownership

Orchestratorทำpreflight/assetlockและตกลงdata+evaluator+stateinterfacesก่อนparallel; ใช้จำนวนworkersตามcapacityแต่คงownershipตามตาราง. Codexยังเป็นIndependentReviewer ไม่ให้AGYปิดF-IDแทน.

| Role | File ownership / responsibility |
| --- | --- |
| Lead Orchestrator | plan/tasks/notes/HANDOFF02, assets/designs/argon-r6-pack/, fix-004, finaldocsync; clientinitเฉพาะถ้าintegrationจำเป็น. คนเดียวsyncStudio/beforestate/rollbackและเขียนเอกสารกลาง |
| Explorer / Challenger | read-onlyZIPและcallgraph ตรวจF-25..30/scopecounterexamples ไม่เขียนsource/board ไม่เปลี่ยนapprovedspec |
| Worker Pose Data | `src/shared/configs/PlayerActionPoseConfigs.luau` เท่านั้น: adaptA01–18/variants/provenance/keyframes/support/clearance; ไม่สร้างwriter |
| Worker Pose Runtime | `src/client/character/R6ActionPoseController.luau` เท่านั้น: evaluator/blend/hold/cancel/lifecycle/statepriority จัดjointwriterเดียว |
| Worker Animator Integration | `src/client/character/R6AnimationController.luau`, `src/shared/configs/RigAnimationConfigs.luau`: trackownership/delegation/cleanup คงpublicAPIของ00 |
| Worker Input Adapter | `src/client/controllers/InputController.luau` เท่านั้น: visualintent/outcome/sequence/actualairborne/landingadapter เชื่อมAPIที่ตกลง ไม่แก้ballmechanics/remotecontract |
| Test Engineer | `tests/e2e/Tier1_PlayerActions.luau` เท่านั้น: behavioral/pose/lifecyclechecksผ่านpublicinterfaces รันทดสอบในช่วงStudioที่Leadจัดให้ ไม่มีparallelscene/sourcewrites |

data/runtime/animator/inputต้องตกลงAPIก่อนให้workersแก้คนละไฟล์; integrationตามdependencyไม่บังคับparallelทุกขั้น. ห้ามแบ่งกลุ่มท่าให้หลายคนเขียนPlayerActionPoseConfigsไฟล์เดียวกัน. ให้workersคืนผลสั้นแก่Lead ไม่สร้างreportซ้ำหรือgitcommit.

### 8.4 Allowlist / exclusions / doc integrity

sourceแก้เฉพาะ5ไฟล์visual/inputในตาราง; testsแก้Tier1_PlayerActions; clientinitLeadแก้เฉพาะจำเป็นตามallowlistเดิม. ไม่เพิ่มR6FootballPosePlayer/R6FootballPoseDataอีกระบบในsrc.
Server BallService/Constants/Types/Network/CameraShiftLockController/TrainingHUD/rig00/physics01/Sandbox/reference/rollbackpre/.gitignore/sourcemapread-onlyในdeltaนี้; ไม่ใช้ข้ออนุญาตเก่า§6เป็นสิทธิ์แก้gameplayโดยไม่เกี่ยวกับงานภาพนี้.
ไม่มีPoke/Shoulder/SkillMoves/GK/FullUI/VFXpacks/camera redesign/shot-pass-whiffpenaltyเพิ่ม. baselineมีshotwhiffในdirtycode/notesที่ขัดplan/spec ให้รายงานความขัดแย้งเป็นexistingissue ไม่เพิ่มscopeหรือลบuserworkเงียบๆ.
Leadsyncplan/tasks/notes02ให้สะท้อนvisualsourceล่าสุดและลิงก์§8/review003; PRD/Spec02/TDD/architecture/READ/agent/phaseplanแก้เฉพาะข้อความpointer/acceptance02ที่จำเป็นจริงตามallowlistT99เดิม บันทึกbefore→after/เหตุผล/Ownerauthorityในfix004 ไม่เปลี่ยนscopeแผนอื่นหรือdraftเป็นapproved/closed/pass.
รายงานเก่าreview001/002,fix001/002/003คงhistorical; รอบนี้ส่งfix004ใหม่ฉบับเดียว ใช้F-IDเดิมต่อเนื่อง.

### 8.5 Verification / return

- Preflight: gitstatus/HEAD/sourcehash/ZIPhash,ยืนยันStudioID/PlaceId137721422246269/modeสดและbeforestate/rollbackก่อนsync; คงReference112091950831355read-only ไม่ใช้StudioIDเก่าเป็นข้อเท็จจริงปัจจุบัน.
- Testentrypoints/commandsให้AGYตรวจจากrunner/StudioMCPปัจจุบันก่อนรัน ไม่อ้างTEST_READYหรือผล45/45เดิมเป็นผลใหม่. Focusedbehaviorgateก่อนแล้วaffected01regressionตาม§6โดยไม่แก้kernel01.
- V-A pose/nativegeometry: ทั้ง18profiles/variants,8ทิศ+oppositedirections+stop,Passaim/power,hold→release/cancel,Slidehit/miss,finalblendedOBB/support/foot-slipที่scaleเกมใช้จริง. คำนวณในengine ไม่อ่านobbMinYmetadataมาassertกับตัวเอง.
- V-B lifecycle: Start/Play/Stopfade/Stop0/Cancel/reject/auto-next/characterdestroy/death/respawn/reset/focus/menu; ไม่มีstaleintentcallback เปลี่ยนstateแล้วไม่คืนท่าค้างหรือแย่งjointจากownerใหม่.
- V-C realinput→serverresolvedaction/foot/style→pose/ballcontact,holdค้างขาไม่สับ/ปล่อยไม่ซ้ำ,actualjump/landingไม่เปลี่ยนverticalphysics/SlideJumpcameraไม่สู้กัน; ตรวจ30/60/120fpsเท่าที่ทำได้รวมobservervisualหากใช้client-onlyTransform.
- V-D sourceStudioParity/currentgeneration+freshaffected01contact/groundrest/teamcontext; ไม่ถือว่าunit/EditgeometryแทนLivePlay.
- ส่งfix004พร้อมAxx→sourcefunction/hash→targetprofile/state/retimingmapping,ค่าที่adaptพร้อมเหตุผล,exactcommands/resultsและStatic/Edit/Live/Visual/NotRunแยกชัด,currentHEAD+changedfilehashes,remainingF-IDและscopeexceptions. ไม่ต้องscreenshot/video; visualINCOMPLETEเมื่อยังตรวจจริงไม่ได้.
- ส่งREADY_FOR_REVIEW ไม่มีสิทธิ์commit/push/merge/deploy/ปิดแผน/ปิดfinding. งาน00/01ยังเปิดและพักตามเดิม. (ข้ออนุญาต Git ล่าสุดดู §9)

## 9. Owner Boost supplement — sync / reference fidelity / commit-push (2026-10-22)

**คำสั่งล่าสุด:** Owner แจ้ง Animation ยังไม่เหมือนภาพ ขอใช้ AGY Boost แก้ sync ปรับท่าให้ดีขึ้น และ commit/push โค้ดปัจจุบัน. คงสถานะ OWNER_VISUAL_REJECTED / REWORK ตาม [review-004](review-004.md); ยังไม่มี full implementation sign-off.
§9 เสริม §8 และแทนคำห้าม commit/push เดิมเฉพาะ AGY Lead สำหรับงาน Plan02 รอบนี้. ไม่อนุญาต merge/deploy/force-push/approve/close. Codex ไม่ลงมือแก้ source รัน application tests หรือ Git mutation ในรอบนี้.

### 9.1 Git checkpoints และฐานงาน
- เริ่มจาก HEAD/status/hashes ปัจจุบัน ไม่ใช้รายงานเก่าแทน. HEAD ที่ตรวจคือ617f523พร้อม dirty working tree หลัง fix004; main ahead1 origin/main เป็นข้อมูล local tracking ที่ยังไม่ได้ fetch.
- Lead สร้างหรือใช้ branch `codex/plan02-animation-rework` จากฐานปัจจุบัน โดยรักษา working tree. หากมี branch อยู่แล้วต้องตรวจว่าเป็นงานเดียวกัน ไม่ reset/delete/ทับ branch ของงานอื่น และไม่ force-push.
- เก็บ WIP checkpoint ของ source Plan02 ปัจจุบันและ dependency hunks ที่จำเป็นก่อนแก้ต่อ แล้ว push ไป origin บน branch งาน. เนื้อหาฐาน Plan02 ที่มีอยู่สามารถรวมใน checkpoint ได้แม้ §8 ห้ามแก้เนื้อหาใหม่ในไฟล์นั้น; การบันทึก WIP ไม่ใช่การอนุมัติฟีเจอร์.
- ตรวจ staged diff แยกตามงาน ปกป้องไฟล์ค้างที่ไม่เกี่ยวข้อง รวม .gitignore/notes01; ไม่รวม secrets, temporary logs, rollback/reference snapshots. ห้าม `git add .` หรือ `git add -A`.
- หลัง rework ให้ commit/push ผลที่ตรวจใหม่แล้ว. หากยังไม่ครบ อนุญาต push checkpoint เฉพาะที่ระบุ WIP และเปิดเผยข้อค้าง ห้ามรายงานว่าเสร็จ. ส่ง commit SHA, remote branch/status และรายการที่ยัง unstaged.
- คำสั่ง Owner นี้เป็นสิทธิ์ commit/push โดยไม่ต้องถามย้ำ; Git push ไม่ใช่การ publish Roblox experience หรือ merge เข้า main.

### 9.2 ตรวจ sync ก่อนจูนท่า
Lead ตรวจ StudioID/Place137721422246269/mode สด และ canonical paths จาก default.project.json. เทียบ hash ดิสก์→Studio Edit Source ของ config/controller/bootstrap/input และ modules ที่ require จริง พร้อมตรวจ duplicate instances/scripts/mappings.
จากนั้นเปิด Play ใหม่หรือ respawn แบบควบคุม ตรวจ running client/character/generation/module identity/source version. ห้ามใช้ require cache เก่า หรือถือว่าแก้ StarterPlayerScripts แล้ว PlayerScripts ที่เกิดไปแล้วจะเปลี่ยนตาม.
มีผู้ sync Studio คนเดียว เก็บ before-state/backup ก่อนแก้; Reference Sandbox112091950831355 คง read-only. ถ้าพบปัญหา sync ให้ระบุจุดที่ผิดจริง ไม่สรุปว่า sync เป็นสาเหตุเดียวล่วงหน้า.

### 9.3 ความตรงภาพและคุณภาพ Animation
- แก้ active paths ที่ review004 ชี้: locomotion ยังใช้ native walk กับ torso lean, A06 ค้างที่เฟส .50 และ Slide เป็นท่าคงที่เพื่อ TC40. ต้อง trace A01–A18 จาก state จริง→profile/phase/variant→final C0/Transform→world pose; มี data ใน config อย่างเดียวไม่พอ.
- ทำ defining poses ให้ตรงภาพก่อน แล้วจูน spacing/weight/anticipation/contact/follow-through/settle/transitions ภายในข้อจำกัด R6. คง6ข้อต่อและ rig scale ไม่เพิ่มเข่า/ศอกหรือใช้ VFX/กล้องแทนการแก้ท่า.
- เทียบแต่ละ Axx ที่ phase/view/scale เดียวกัน บันทึกแนวตัว ขารับน้ำหนัก world positions ของแขนขา ความคลาดเคลื่อน และเหตุผลที่ต้อง adapt. ไม่ถือจำนวน profiles/tests หรือ provenance label เป็นเกณฑ์ภาพผ่าน.
- ตรวจ final pose หลัง Animator+pose+smoothing+clearance. การแก้ clearance ต้องไม่ทำให้สไลด์ลอย ขารับน้ำหนักหลุด หรือจังหวะสัมผัสบอลเสีย; ตรวจพื้นจริงและ support ไม่ใช่เพียง minY>=0.
- HOLD ค้างง้างไม่สับขา; release/cancel ตอบสนอง; gait phase ต่อเนื่อง; strafe8ทิศอ่านออก; Dash ต่างจาก Jump; Header ต่างจาก Block; Volley/Bicycle มี flight และลงพื้นครบ; Pass ต่างจาก Shoot; Curve ตาม Server foot/style; Slide มี entry/active/exit/recovery จริง.
- คง mechanics, release timing, cost/CD, ballistics และ Shift Lock. การเพิ่มความสวยเป็น visual เท่านั้น. ใช้ native clips เฉพาะที่ mapping ชัดและไม่แข่งเขียน joints; ไม่ตรึงค่าท่าเพียงเพื่อให้ assertion เก่าผ่าน.
- ใช้ training fixture/test controls เดิมสำหรับตรวจ phase ไม่สร้าง Full UI ใหม่. ไม่บังคับ screenshot/video. ถ้ายังดู viewport ไม่ได้ ให้ visual INCOMPLETE และรอ Owner ตรวจภาพจริง โดยทำงานส่วนที่พิสูจน์ได้ต่อและไม่แต่งผล.

### 9.4 ทีมและการส่งกลับ
คงเจ้าของไฟล์แยกตาม§8: Lead+Sync/Git, Pose Data, Pose Runtime, Animator, Input Adapter, Test Engineer และ Challenger แบบ read-only. ตกลง interfaces ก่อนเริ่มงานที่พึ่งกัน ห้ามชนไฟล์หรือแก้ Studio ขนานกัน; Lead เขียนเอกสารและทำ Git คนเดียว.
ทดสอบ counterexamples ใหม่, input/pose/reject/cancel/lifecycle และ fresh affected regression. Test Engineer ตรวจ world pose ที่เกิดจริง ไม่ตรวจ metadata เทียบตัวเอง. Challenger ตรวจ active runtime path และความตรงภาพก่อนส่ง.
Lead ปรับ plan/tasks/notes/pointers ให้ตรง§9 โดยไม่เพิ่ม scope PRD/spec/plan อื่นหรือแก้ผล historical. fix004 มีอยู่แล้ว ให้ส่ง `assets/fix-005.md` ฉบับเดียว พร้อม source→Edit→Live parity, current hashes, สถานะและความตรงภาพรายAxx, intentional deltas, commands/results ใหม่, commit/push SHAs และข้อค้าง.
F-21/F-28 และ findings อื่นยังเปิดจน Codex re-review; visual pass ต้องอาศัยหลักฐานจริงและการตัดสินของ Owner.

## 10. Owner priority — prototype3 gameplay adaptation: jump + off-ball kick (2026-10-22)

**Owner authority ล่าสุด:** ขอการกระโดดเหมือน Sandbox และอนุญาตส่งงานตรงเข้า pane ที่กำหนด; เพิ่มอาการ “เตะบอลไม่ได้ตอนไม่ได้ครองบอล” และยืนยันใช้ gameplay ของ prototype3 ล่าสุดเป็นต้นแบบเพื่ออัปเกรดของเดิม ไม่สร้างระบบใหม่. งานนี้มีลำดับก่อน polish ท่าอื่นใน§8–9.
**Baseline ที่อ่านจริง:** `codex/plan02-animation-rework` HEAD `e38e2f489fca522dbf0d12ea73894f2332e0118d` + dirty working tree; fix005 มีแล้ว ให้ส่ง fix006 ใหม่. ไม่มี Codex runtime sign-off. ตรวจ HEAD/hash ใหม่ก่อนเริ่มเพราะ AGY pane ทำงานอยู่.
**Dispatch:** ตรวจ tab/agent IDs ก่อนส่งทุกครั้ง. ตอนตรวจ alias `agycagezero` เป็น AGY `w2:p3X`; Codex แชทนี้ `w2:p43`. `w2:p42` คือ AgyBridge อีก tab ไม่ใช้ ID เก่าหรือ alias ที่เดา. Owner อนุญาตสั่ง AGY และรับรายงานกลับผ่าน herdr ตาม pane ที่ตรวจสด.

### 10.1 Source of truth / ขอบเขต
ใช้ `.sandbox/prototype3/` เป็น gameplay reference แบบ read-only: client FootballClient.client.luau, server FootballServer.server.luau, shared SandboxConfig.luau. ถ้า “ล่าสุด” ใน Studio ต่างจากดิสก์ให้ read/hash และบันทึก source version ก่อนเทียบ ห้ามเขียน Sandbox หรือสลับเวอร์ชันเงียบๆ.
Local source SHA256: client `9b71d800b1a906af4fcc603a82022eea82e6f9d598ba87098f5afa083c730dab`; server `30af80c5feec60e3389b772571b64ba706b21cadd1f5f0b684df5f1d5fb01c92`; config `1833b4ed870bd4c9de1eedf9d412e8b720799ff502076e03a72ba57ffe32d23a`.
ยึด behavior/function ของต้นทางแล้ว adapt เข้ากับ R6/BallService/Network/intent lifecycle เดิม. ไม่เขียนฟุตบอลระบบใหม่ ไม่ยก remote tree/second ball controller/arena/GK/Skill Moves/ฟาวล์/whiff stun จาก Sandbox เข้ามาทั้งชุด.
คำสั่งนี้ขยาย §8 allowlist เฉพาะ jump/off-ball gameplay seam: InputController, BallService, Constants และ adapter ที่เกี่ยวข้องใน R6ActionPoseController/R6AnimationController/PlayerActionPoseConfigs; CameraShiftLockControllerแก้เฉพาะ ownership ของ jump facing หากจำเป็นจริง; Tier1_PlayerActions tests และเอกสาร02.
ไม่แก้ CagePhysicsService/rig schema/Network definitions/สนาม/Workspace gravity เพื่อชดเชยอาการ แม้ปัจจุบันมี dirty changes ให้เก็บฐานและแยก attribution ไว้ ห้ามทับหรือเคลมว่าเป็นงานรอบนี้. public API/remote schema ที่ต้องขยายจริงให้รายงาน exact dependency ก่อน เฉพาะส่วนนั้น.
คง team context แยกจาก personal possession ตาม Spec02: ฝ่ายบุกเล่น first-time ได้โดยไม่ต้องจับครองก่อน; บอลต้องอยู่ใน valid reach/contact. ไม่แก้โดยบังคับ possession หรือให้ยิงโดนบอลได้ทุกระยะ. ถ้าพบข้อขัดกันจริงระหว่าง source gameplay กับข้อกำหนดทีม ให้แสดง case ชัดเจน ไม่ลบกติกาทีมเงียบๆ.
สำหรับ jump feel/pose ให้ behavior ของ prototype3 มีลำดับเหนือ Argon jump preview เมื่อขัดกัน; แปลง R15 chain เป็น world direction ของแขนขา R6 ทั้งชิ้น ไม่เพิ่ม knee/elbow. visual ของ action อื่นคงงานเดิม.

### 10.2 สิ่งที่ตรวจจาก source / ยังไม่ใช่ root cause ที่พิสูจน์ runtime
- Sandbox client:1629–1696 commit เพียงทิศ/facing; ตั้ง UseJumpPower=true, JumpPower72, JumpHeight15.5 แล้วให้ Humanoid กระโดด. ไม่เขียน vertical velocity ใน commit.
- Current InputController:687–699 ChangeState(Jumping) และ set AssemblyLinearVelocity.Y>=72 พร้อมบังคับ XZ เป็นWalk/Sprint แม้ยืนเฉย; BallService:1026–1031เขียน jump velocity ซ้ำและใช้Walk20เสมอ แล้วStepPhysics:1224–1229บังคับXZต่อเฟรม. จึงต่างจากต้นทางทั้ง launch ownership/idle/sprint และอาจมีการเติมแรงซ้ำหลัง latency.
- Current input ใช้ InputBegan/JumpRequest/StateChanged ร่วมกัน มี release guard. ต้องตรวจจริงหนึ่งpress→หนึ่งtakeoff ไม่ถอด guard แล้วคืน bunny-hop เพื่อให้ “เหมือนต้นทาง”.
- Sandbox server:832–836 แยก horizDist<=AERIAL_VOLLEY_REACH9.5 และ vertDist<=8.5 โดยไม่ต้องเป็น dribbler; MAX_KICK_DISTANCE9เป็นอีกค่าที่ใช้บาง branch ห้ามสลับผิด.
- Current BallService:582–602ใช้ระยะ3D HRP→ball<=BALL_TOUCH_RADIUS4.5 สำหรับ first-time; นอกระยะคืน Accepted/เล่นท่าเฉยๆ โดยไม่ออกบอล และมี WrongContext gate ก่อนหน้า. ตัวเลขและ branch นี้อาจอธิบายบาง case แต่ยังต้อง reproduce.
- Current StartCharge/release/remote metadata/terminal intent/context version ยังเป็นจุดที่ต้อง trace. อย่าเห็น pose Accepted แล้วสรุปว่ามีบอลถูกเตะจริง.
- Ball gravity ใน SandboxConfig ไม่ใช่ Workspace.Gravity ของ character. UseJumpPower=true ทำให้ JumpHeight15.5ไม่ใช่ตัวควบคุม arc อีกชุด; วัด actual gravity/arc ของทั้งสองก่อนจูน.

### 10.3 งาน AGY / hypothesis-driven comparison
เริ่มจาก reproduction บน current running client ไม่แก้หลายสาเหตุพร้อมกัน:
1. P0 Off-ball: ทีมโหมดบุก + HasBall=false + ลูกFree/ลูกวิ่งเข้ามา/ลูกชิ่ง/ลูกลอย ในระยะต้นทาง; กด Shoot/Curve/Pass ตาม inputจริงและ trace action→start/release→server reason→contact→ball velocity. แยก context/team กับ personal possession และแยก far-ball whiff ที่ไม่ควรออกบอล.
2. P1 Jump: เทียบ stationary/walk/sprint และ Space tap/hold-release, ShiftLock ON/OFF, พื้นยกระดับ/ตกขอบ/หลังDash. จับ takeoff count,initialVY/VXZ, apex height/time,totalairtime,landingevent/facing และสถานะ writer ที่แก้ velocity.
3. จัดอันดับสมมติฐาน: first-time reach geometry/actual contact window; stale charge/context/intent; dual jump impulse; walk-onlyXZ overwrite; current pose/facing/cached module. แต่ละข้อมี predictionและcounterexample; เปลี่ยนทีละตัวแปรเพื่อยืนยันสาเหตุก่อนfix.
4. Adapt source functions ที่เลือกลง seam เดิม: native vertical jump ownerเดียว, server validate/reconcileโดยไม่ให้secondupwardkick, horizontal lockตามcontractเดิมโดยไม่ผลักผู้ยืนนิ่งเป็นWalk20หรือทำSprintตกเป็นWalk. หากต้องมี bounded prediction correction ให้แสดงเหตุผลและผลวัด ไม่เติมVYทุกครั้งที่event/remoteมาถึง.
5. Off-ball kickต้องส่งผลกับบอลจริงเมื่อ valid contact ไม่ต้องรับ possession ก่อน; ล็อกหนึ่งintentเตะครั้งเดียว, รักษาPass/Curve intent และ cancel lifecycle. อย่าลบ finite/generation/context/rate validationเพื่อให้ยิงผ่าน. ตัดสินระยะ/ความสูง/ช่วงcontactโดย mapเงื่อนไขprototype3มาที่R6/ballradius1.25พร้อมอธิบายold→source→adapted.
6. ไม่แก้ด้วยเพิ่มJumpPowerเรื่อยๆ, forced root lift, anchor, globalgravity หรือ Animation speed อย่างเดียว. ไม่อ้าง clonedrig/mock/settingattributes แทน realinput→server→physics.

### 10.4 ทีม / gates / return
Lead คง single sync/Git/doc writer; แบ่ง Input+native jump, BallService first-time+validation, R6 pose/rotation adapter, Test Engineer และ read-only Challenger แบบไม่ชนไฟล์. ตกลง movement/intent interfacesก่อนparallel. คง API ของ module เดิม.
ก่อน sync ตรวจ disk→Studio Edit source hashes และ fresh running client/require/character generation. ใช้ Place137721422246269 ที่ยืนยัน session ใหม่ ไม่แตะ reference. สนาม/rig/context fixture ต้องเทียบกันได้.
ทดสอบ positive off-ball reach/contact รวม incoming/rebound/aerial; negative outside reach/wrongcontext/staleintent/replay/NaN/cancel; ball velocityต้องเปลี่ยนจากcontactจริงไม่ใช่แค่pose/flag. Jump single press/hold/release/idle/walk/sprint/directionlock/death/respawn/platform ต้องผ่านจริง.
ส่ง `assets/fix-006.md` ฉบับเดียว: reproductionและrootcauseที่พิสูจน์, sourcehash+function→targetmapping,ผลเทียบSandbox/current/fixed,retainedfixes,exactcommands/resultsแยกStatic/Edit/Live/Visual/NOTRUN,currentSHA+filehashes,scope deltaและข้อค้าง. ไม่แก้ fix005ย้อนหลัง/ไม่ปิดfindingเอง.
Git authorization§9ยังใช้ได้สำหรับ scopedcheckpoint/final commit+push บนbranchงาน ไม่merge/deploy/force/approve/close และไม่รวมdirtyนอกงาน. ตอบรับและรายงานกลับCodexpaneที่ตรวจสดตามคำสั่งOwner.
Dispatch receipt: 2026-10-22 ตรวจ herdr tab list/agent list สดแล้วส่ง `herdr agent prompt` ไป alias agycagezero (`w2:p3X`), reply Codex `w2:p43`; CLI exit0/type agent_prompted. เป็นหลักฐานส่งคำสั่งสำเร็จ ไม่ใช่ AGY acknowledgment หรือผลแก้/ทดสอบผ่าน.

## 11. Resume after Owner pause — 2026-10-23

Owner “ทำต่อ … ตรวจ pane ปัจจุบัน อนุญาตให้ใช้ pane ชื่อ agycagezero” ยกเลิกการพักรวมวันที่22 เฉพาะงานที่ยังอนุญาต; ไม่ได้เปิด Plan04 กลับ. ตรวจpaneสดพบAGY agycagezero=w2:p3X/idle, Codex=w2:p43; ต้องตรวจซ้ำก่อนส่ง ไม่ยึดterminal_idจากsessionเก่า.
ลำดับงาน: (1)แก้jumpเมื่อเดิน/วิ่ง+temporaryHeadervisualตามOwner (2)ส่งfix006เพื่อCodexreviewโดยPlan02ยังOPEN (3)เริ่มPlan03ตามHANDOFFของ03; คงPlan04PAUSED_BY_OWNER. ใช้normal focused promptสำหรับjumpเพราะinput/physics/stateต้องตรวจตามลำดับ ไม่จำเป็นเปิดagentsขนานในsharedfiles; Plan03เลือก/teamworkได้ตามownershipในสัญญานั้น.

### 11.1 หลักฐานที่ต้องใช้ ไม่ทำซ้ำงานอ่านทั้งหมด
อ่าน [review-005](review-005.md) และ evidenceJSON. Caseเดิน+SpaceจริงมีVY70.5975→-4.0875ที่t.05052s,rootขึ้นเพียง2.449stud,Landed.31623s และclientflightidle/replicatedIsAirbornetrue. ยังไม่มีrootcauseproof; Sprint/standing/Sandboxต้องเก็บใหม่. ห้ามใช้invalidtimedprobeหรือsampleCount0เป็นPASS.
ก่อนrunค้นหาStudio/Place/modeใหม่และตรวจdisk→Edit→freshclient/source/generation. CodexหยุดPlayและล้างprobesแล้ว ช่วงexclusive diagnosticของCodexสิ้นสุด AGYกลับมาควบคุมStudioได้ตามscopeเดิม. ไม่ต้องรอCodexprobeที่ไม่มีอยู่แล้ว.
Base HEAD e38e2f489fca522dbf0d12ea73894f2332e0118d+dirty; resume hashes Input712a6879e0462c6dde4005d1d7198f8d731bb8e04abd537df3ba3a1c0fa51e30, Ball1b072749fc9ac756380b76770adf4811b29260dbeefe44851d7b44d79ae6c089, ActionPose18c40acf2e0db2b7e9c24036213ff8e53da36b787d491d13326c750db4456994, Animationf6f156d121f132b92fc4c0b090ab704ae3f98cc7df9cef247840f5d48c5b27c7. ตรวจใหม่ก่อนแก้และปกป้องdirtyทุกไฟล์

### 11.2 งานแก้ที่อนุญาต
- Native input Walk+Space, Sprint+Space, standingcontrol,hold/release,ShiftLockON/OFFบนพื้นราบที่ตั้งfixtureเทียบกันได้; เก็บactualevents/position/VY/VXZ/clientflight/serverairborne/forcewritersและcollidersรอบจังหวะผิด. ติดprobeจากactualSpace/Jumpingไม่เริ่มdeadlineตอนMCPrequest
- ทำdifferentialกับprototype3ตาม§10 และพิสูจน์writer/state/contactที่ตัดVYก่อนfix ไม่แก้แบบสุ่มเพิ่มJumpPower/resetCFrame/lockroot/เปลี่ยนgravity/คืนbunnyhop
- Input/Server/Camera/poseต้องไม่สู้กันเรื่องjump;รักษาauthority/generation/intent/finitevalidationและบอลอิสระfirst-timeที่ได้จากรอบก่อน. Testผ่านactualinput ไม่เรียกmockexecutorแล้วอ้างLiveinput
- TemporaryHeader: airborne CurveShoot/BicycleKickแสดงHeaderposeง่ายแทนflip ผ่านvisualmappingเดียวทั้งpredictionและresolvedreconciliation. ไม่ส่งHeaderแทนBicycleในnetwork/ไม่เปลี่ยนballistics/charge/actionintent. ปิดacrobaticflipและbreakfallrecoveryเฉพาะfallbackนี้เพื่อไม่ลุกกลางอากาศ; landingปกติตามactualLanded
- Scopeไฟล์ตาม§10; ไม่แก้CagePhysicsService/rig00/สนาม/Networkschemaหรือปรับโครงสร้างsyncใหม่รอบนี้. Ownerเลื่อนการปรับวิธีsyncไปครั้งหน้าแล้ว; ใช้วิธีที่มีและแจ้งปัญหาจริง ไม่เปิดงานinfrastructureแทรก

### 11.3 ส่งกลับและGit
Ownerอนุญาตresumeผ่านpaneนี้รวมการตอบกลับCodexpaneที่ตรวจสด. ส่งackสั้นเมื่อเริ่มแล้วทำต่อ ไม่ถามย้ำสิทธิ์เก่า ไม่ปิดPlan02/03/04หรือfinding.
ส่งassets/fix-006.mdฉบับเดียวพร้อมrepro/rootcause/freshchecksและvisualfallback,old/newsourcehash/runtimeparity,ข้อค้างรวม03ที่ยังไม่เริ่ม. GitอนุญาตเฉพาะPlan02ตาม§9แบบscopedcheckpoint/commit/pushไม่merge/deploy/force; ห้ามรวมงานPlan03ไว้ในcommitสิทธิ์Plan02. Plan03ยังไม่มีสิทธิ์Gitcommit/pushใหม่จากการอนุมัติimplementationเพียงอย่างเดียว.




