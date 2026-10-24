# HANDOFF CONTRACT — 02-player-actions (บอล การเคลื่อนที่ และปุ่มตามทีม)

## 24. LATEST Owner visual rejection — base locomotion / runtime FakeShot (2026-10-24)

Owner reports FakeShot ball still stationary, then reports walking/idle/running/jumping still look normal. Review008 F36–38 governs correction of current fix014/fix003;116 Edit tests do not override real input/visual failure. New narrow allowance: inspect/fix runtime animation wiring in `src/client/character/R6AnimationController.luau`, `src/shared/configs/RigAnimationConfigs.luau`, and `src/client/init.client.luau` ONLY as necessary for prepared custom base locomotion and lifecycle/priority integration. Existing PlayerActionPoseConfigs/R6ActionPoseController/InputController and focused relevant tests remain in scope. Do not redesign Module00 rig/default-card/stats, physics, unrelated bootstrap or gameplay; add proposed files only if a concrete missing seam requires scope resolution.

Use actual prepared Idle/Walk/Run-Sprint/Jump-Fall-Landing poses/clips and source mapping, not fabricated public asset IDs or personal avatar packs. Preserve generation/reset/death cleanup, controller readiness, charge/action precedence and one track/pose writer. Existing default R6 fallback is not accepted as the custom animation result. Clearly show custom state changes on real player in Cage-Zero; keep visual acceptance with Owner. No upload/publish/new Studio or global settings/extra worker/Git authority. Same primary assignment, new correction report fix015 for F36–38; push report per Plan03§O, no polling.

## 23. LATEST Owner delta — aimed lateral FakeShot ball touch (2026-10-24)

Owner: “เวลากด fakeshot แล้ว ให้บอลโยกไปเลย ... แตะไปซ้ายหรือขวาตามทิศที่เป้าเล็ง ไม่เอา fakeshot อยู่กับที่ แบบล็อคบอลหนี”. This explicitly changes the EXISTING grounded core E-triggered FakeShot; it is not permission to merge/replace it with the separate OpenUpFakeShot1★ loadout skill.

- Trigger remains grounded attacking Direct/Curve charge + E. Atomically terminalize the held shot intent; consume E press/release and stale LMB/RMB release, no accidental Shoot/Pass/recharge or repeated touch. Preserve recovery, generation/context, flight budget and no-bypass gates.
- A successful FakeShot on an actually controlled/reachable ball must cause a **visible real lateral ball touch/cut** toward the left/right side selected by the current validated AIM at FakeShot activation. No stationary cancel-only result or cosmetic foot animation presented as ball movement. Do not substitute Humanoid.MoveDirection/A-D-only or world-X sign for the aimed side. Capture one shared character-relative side/exit descriptor for local prediction, Server ball/contact and replicated pose; revalidate the existing aim payload on Server, no client-authorized teleport/force/outcome.
- Use existing authoritative BallService dribble/contact/impulse ownership and bounded movement paths. Preserve physical contest/tackling throughout; no weld/anchor/invulnerability/automatic successful dodge, unowned-ball capture or global ball-physics/shot-pass scaling. Nonpossessor/out-of-range/airborne/rejected attempts cannot move or gain the ball. Body/foot pose should clearly agree with the actual ball-contact direction.
- Inspect the actual active call chain before editing: current InputController.RequestFakeShot sends aimDirection but predicts exit from movement; inspected BallService contained TWO ExecuteFakeShot definitions (approx2035/2083) based on movement and ordinary stationary dribble. Preserve partial work, resolve duplicate active definitions carefully and pass the validated aim through the real handler; do not edit an overridden/dead function and claim it changed gameplay.
- Direction/neutral policy must be deterministic and documented using existing shared directional conventions; test left/right with character rotated, camera aim differing from movement/opposite A-D, changes just before E, near-neutral aim, stale/replayed E/mouse release, reset/death/context/recovery, ball ownership/range/air rejection. Do not invent Owner-approved tuning numbers; choose traceable tunable draft values from existing contact/action conventions, measure displacement/contact and leave visual tuning for Owner.
- Acceptance includes actual input→validated Server intent→ball displacement/contact, current source parity and matching visible R6 pose. Static/fixture/clip playback alone does not prove the ball cut. Maintain legacy core FakeShot cancellation/recovery assertions and add behavioral coverage rather than weakening tests. Main writer agycage w2:p48 implements/tests; Codex reviews current ref. Keep Motion connection priority Plan03§M, then this delta as first gameplay correction. Same §L file allowlist; no Git/publish/closure/Phase2 authority.

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

## 12. Owner delta — single bindings / curve side / airborne shot + lean (2026-10-23)

**Authority:** Ownerบอกพอใช้ได้แต่ยังไม่ปิด Plan02 ขอหนึ่งปุ่มต่อaction, Finesseเมื่อเดินซ้าย/กดA และTrivelaเมื่อเดินขวา/กดD, แก้ท่าง้างขาปนกับท่ากลางอากาศ และเพิ่มเอนตัวที่ส่งผลต่อบอลโดยคงyaw lock. คำตอบล่าสุดยืนยัน **กลางอากาศ LMBยิงปกติ / RMBวอลเล่ย์** และ **ฐานยิง=ทิศหน้าที่ล็อกตอนขึ้น+มุมเล็งสูงต่ำ+ผลleanต่อวิถี/สปิน**.
ข้อยืนยันนี้แทน temporaryHeader/Bicycle fallback ของ§11 ไม่ใช่ให้ทำHeaderต่อ. GroundRMBยังCurveShoot. Plan02คงOPEN/OWNER_TUNING_REQUESTED; Plan03ยังได้รับอนุมัติรอสัญญาและฐานร่วมที่นิ่ง; Plan04ยังPAUSED_BY_OWNER.
ใช้ stang-solar-system สำหรับขอบเขตที่Ownerยืนยัน, stang-mercury Designสำหรับpayload validation และ stang-comet handoff; Codexไม่เขียนแอปหรืออ้างทดสอบผ่านแทนAGY. งานนี้เลือก/teamworkเพราะแยกinput,sharedphysics,visual/curve และtestsคนละไฟล์ได้ โดยLeadรวมsharedserver/schemaคนเดียว. ถ้าruntimeไม่รองรับใช้promptธรรมดาและรายงาน ไม่ต้องบังคับโหมด.

### 12.1 Baseline / retained fixes / source of truth
Actual HEADตอนสั่งงาน `2d3f1e63f3f9ff47cc20991ff1c13753d8a45fca` บนcodex/plan02-animation-rework + dirty docsและCagePhysicsServiceนอกงาน. fix006มีอยู่แล้วและเป็นImplementer-reported ไม่ใช่Codexsign-off. เก็บmovingjump/nativeimpulse/off-ball fixesจากฐานนี้; ห้ามย้อนกลับe38e2f4หรือแทรกการแก้CagePhysicsService.
Resume hashes: Input a6ef9b4f23e6c16971086bbf7e3a143d39cd3c56d4a081a9701240563cb008be; PoseConfigs dfbcd078dd7456f48ed62979d279c85855062d4494a6bd4bf67399cc6203c75b; Ball c6cecc4d67511bff0d847015b4df4a759e4996bae80dc2bd7f3f43f5c86a3c4e; Types8341ba0ae2a34785ee33838e5a4483b3fe417f71ea3915926f7f301734593747. ตรวจใหม่และเก็บbefore-stateก่อนแก้
เลือก behavior ของprototype3ที่ยังตรงscopeเป็นฐานอัปเกรด; ข้อยืนยัน§12 supersede เฉพาะส่วนที่เปลี่ยน ไม่ยกSandbox/physics/remote treeมาใหม่ทั้งชุด

### 12.2 หนึ่ง physical binding ต่อactionบนkeyboard/mouse
| Action/context | เหลือปุ่มเดียว |
| --- | --- |
| Shoot บนพื้นหรือกลางอากาศ | LMB — DirectShoot |
| Secondary บนพื้น | RMB — CurveShoot |
| Secondary กลางอากาศ | RMB — Volley |
| Pass | MMB |
| Dash | Q |
| Sprint | LeftShift |
| Jump | Space |
| Shift Lock toggle | LeftAlt |
| Training reset / controls help | X / H ตามactionเดิมอย่างละหนึ่งปุ่ม |
| Movementบนพื้น / Air body lean | WASD แยกตามground/air context |

ถอดaliases E/R/V/C/G/F/RightShift/L/RightAlt ของactionเหล่านี้จากInputBegan/InputEnded,HUD/guideและtestsให้ตรงกัน ไม่ให้callbackอีกชุดยังรับปุ่มเก่า. ไม่ให้keydownใหม่แต่keyupเก่าปลดchargeผิดaction. NativeJumpRequestเป็นplatformeventไม่ใช่physicalaliasและยังต้องidempotentกับSpace/onepress guard.
contextทีมเดิมยังใช้ LMB=Slideเมื่อDefending; Poke/Shoulder/Skill slotsเป็นPlan03ยังไม่เปิดในรอบนี้. ไม่ยึดXเป็นSkill2ตามSandboxจนชนTrainingReset.
การกดค้างต้องlatchintent/button/context/action familyและหนึ่งreleaseหรือcancelเท่านั้น. ถ้าholdข้ามground/airให้Leadล็อกlegalconversionและtestsใน§12ก่อนแก้ ไม่ทำให้client/serverคนละactionหรือคืนBicycleconversionเก่า; ไม่เปลี่ยนShootเป็นSlideกลางintentเมื่อteamcontextสลับ

### 12.3 Finesse / Trivela — styleตามside intent ไม่ใช่มุมaimหรือฝั่งบอล
- GroundA/left input หรือ lateral movementซ้าย → Finesse; D/right → Trivela ทั้งสองเท้า. A+Dพร้อมกันเป็นneutral; ไม่มีsideใช้neutral Finesseเดิม
- inputsideต้องระบุจากgesture A/Dโดยตรงก่อน และfallbackmovementที่projectในreference frameที่ตกลง ไม่ใช้worldXหรือfoot-dependentstyleinversion. ปุ่มAตอนชนผนังยังเป็นleftintentได้แม้ความเร็ว0
- Shared ResolveCurveShotเพิ่มnormalizedsideintentเป็นinput โดยคงfoot/contact geometryอีกเรื่องหนึ่ง. ballSideใช้เลือกเท้าและmirror/spinตามเท้าได้ แต่ไม่เปลี่ยนFinesseเป็นTrivelaกลับไปเมื่อบอลอยู่อีกฝั่ง
- Serverคำนวณstyle/footจากvalidatedintent+ball state ไม่รับclientส่งstyle/speed/spinสำเร็จรูป. ClientpreviewและServerreleaseต้องเรียกsharedruleเดียวกัน; reconcileไม่กระตุกกลับอีกstyle
- ตรวจA/Dกับballซ้าย/ขวา, ShiftLockON/OFF,wallblockedmovement,neutral/ทั้งสองปุ่มและaimหมุนข้ามซ้ายขวา; aimเปลี่ยนอย่างเดียวไม่ override sideที่Ownerกำหนด

### 12.4 Shot/animation mapping ที่Ownerเปลี่ยนล่าสุด
- AirLMBเป็นDirectShootปกติ ไม่แปลงเป็นVolleyเพียงเพราะIsAirborne; AirRMBเป็นVolley ไม่แปลงเป็นCurve/Bicycle/Header
- เลือกairborneprepareตั้งแต่เริ่มกด/charge ไม่เล่นgroundcurvewindupหรือง้างขาแบบoldheaderก่อน แล้วค่อยเปลี่ยนท่าตอนrelease. DirectShootมีท่าเตะของDirectShootได้ตามaction ไม่บังคับเป็นโหม่ง
- Remove temporaryHeader/Bicycle fallbackทั้งprediction,heldcharge,resolvedaction callbacks,profiledelegationและrecovery. ไม่ลบHeaderที่เป็นgenuinecontactpathอื่น แต่ห้ามใช้Header fallbackแทนmanualshotsสองปุ่มนี้
- Serverresolverต้องตรงกับinputfamily ไม่แอบconvertmanualDirectShootเป็นVolley/Headerจากairflagหรือheightheuristicอย่างเดียว. Contactvalidationยังอยู่ ห้ามทำให้เตะโดนทุกลูก/ทุกระยะ
- กันdoubletrack/posewriter,ไม่เรียกacrobaticbreakfallเมื่อไม่มีflip,รักษาจังหวะcontactและfixed moving-jump. คงหนึ่งchargeintentและone-shotrelease/cancel. Recordก่อน/หลังจากbegin→hold→release→landedครบ ไม่เช็กเฉพาะPlayActionตอนท้าย

### 12.5 Air lean — เพิ่มbehaviorที่OwnerอนุญาตในPlan02
- ขณะairborne: A/Dเอนซ้าย/ขวา (roll), W/Sเอนหน้า/หลัง (pitch), diagonalsผสมได้. เป็นbodyleanเท่านั้น ไม่หมุนyaw/ไม่เปลี่ยนทิศเดินทางของcharacterที่ล็อกไว้; ไม่ใช้HRP.CFrame/PivotToทำlean ไม่เติมVY/เปลี่ยนgravityหรือผลักตัวเพื่อให้ดูเอน
- ตั้งframe F0=unit horizontal facingที่ระบบเดิมcommitตอนtakeoff; R0=F0 cross WorldUp. ไม่ใช้camera yawล่าสุด/WorldXแทนF0/R0. Stationary jumpก็ต้องมีF0ที่validโดยไม่บังคับพุ่งWalk20
- normalizedleanRight+1หมายถึงD/เอนไปทางR0; normalizedleanForward+1หมายถึงW/เอนไปทางF0. อธิบายmatrixorder/เครื่องหมายของpitch-rollในPart0spaceให้ชัดก่อนmappingMotor6D R6. ไม่มีknee/elbow/waistใหม่
- จำกัดมุมและslew rateผ่านconfig; initialtuningเสนอpitch/rollแต่ละแกนไม่เกิน20deg และอัตราเปลี่ยนไม่เกิน120deg/s โดยเป็นค่าจูนไม่ใช่finalbalance. รวมdiagonalต้องไม่ทำให้เอียงแรงขึ้นโดยไม่ตั้งใจ; returntoneutralนุ่มและล้างเมื่อlanded/death/reset/respawn/focuslost/rejected
- Poseใช้singlewriterเดิม compositingกับshot/volleyตามjointmaskที่ตกลง ไม่ให้lean blendรีเซ็ตท่ายิงหรือclearanceทำให้rootเด้ง. Observervisualตรวจหากมีหลายclient ไม่ถือว่าMotor6D.Transformจากclientreplicateโดยอัตโนมัติ

### 12.6 Shot physics / contract — server authoritative และdeterministic
- Airbaseaim=Normalize(F0*cos(elevation)+WorldUp*sin(elevation)); elevationมาจากaimสูงต่ำที่finiteและboundedตามprofileเดิม. Cameraหมุนyawขณะairไม่ทำให้characterหรือbaseazimuthหมุนตาม
- ให้bodylean/contactframeเปลี่ยนlaunch/spinอย่างมีเหตุผลทางฟิสิกส์ ไม่สุ่มspread ไม่ดึงลูกกลับเป้าหลังใช้lean. Neutralleanต้องไม่มีextraoffsetจากlean; บอลต้องไม่ตรงreticleทุกท่าโดยไม่สนใจbody
- คำนวณจากbasevelocity/spinของaction,orientationและcontactleverarmในframeเดียวกัน; rollรอบlocalforwardอย่างเดียวจะไม่เปลี่ยนLookVector จึงห้ามอ้างว่าLookVectorหมุนอย่างเดียวพิสูจน์lateraldeviation. ใช้contact/tangential impulseและ/หรือrotatedspin axisที่อธิบายผลได้
- ถ้าใช้Magnus ให้ระบุหน่วยและลำดับcrossproduct(spin cross velocity),coefficient/caps/energybounds. หมุนท่าต้องไม่ให้unboundedpowerboostและไม่บวกgravity/Magnusซ้ำกับsolverเดิม
- Scope physicsเฉพาะairborne shot releaseและspin/force integrationของBallServiceเดิม; groundtrajectory/charge/cost/CD/ballradius/cagecollisionkernelคงเดิมเว้นdeltaที่Ownerกำหนดตรงๆ. ไม่ใช้leanเป็นair steeringของcharacter
- Snapshotleanที่ServerยอมรับขณะreleaseผูกintentId/generation/context/actionsequence; delayedfeedbackไม่ใช้leanของcharacterใหม่หรือframeใหม่มาทับลูกที่ปล่อยแล้ว
- ใช้existingBallActionRequestเป็นtransport เพิ่มได้เฉพาะaction SetAirLean และpayload normalizedairLeanRight/airLeanForward,curveSideIntent รวมTypes/validatedstate/snapshotจำเป็น. ไม่เพิ่มRemoteDefinitionใหม่/ไม่reuseDuel/Parry/Match remotesผิดความหมาย
- Leanpacketมีmetadataเหมือนเดิม, finite/type/range[-1,1], actualairborne/lifecyclevalidation,maxrate/maxslewและstale/replayguard. Update/keepaliveแบบbounded ไม่ส่งทุกRenderSteppedหรือใช้ratebucketเดียวจนกินสิทธิ์Shoot/Jump; ระบุtimeoutกับkeepaliveให้สอดคล้องกัน
- SetAirLeanไม่เริ่ม/ยกเลิกcharge ไม่เขียนLastResolvedAction/LastActionStatus/shotsequenceรัวจนfeedback shotสูญหาย. Clientส่งdesiredinputเท่านั้น ห้ามส่งfinalvelocity/spin/validatedstyleให้Serverเชื่อ
- RefactorcommonlegacyKickActionType/ChargeActionTypeเฉพาะDirect/Curve/Volleyและlegalconversionที่จำเป็น คงmetadata validationและ12Networkdefinitions/gettersของ00. Leadเขียนfield schema/actiontransitionใน§12ก่อนworkersintegration; missingdataต้องมีเหตุผลและclearrejectionไม่fallbackเพิ่มสิทธิ์

### 12.7 Disjoint team / allowlist / documentation
| Owner | Files |
| --- | --- |
| Lead | BallService.luau, Types.luau, Constants.luau; bootstrapเฉพาะจำเป็น,primarydocsและStudio/Gitคนเดียว |
| Input worker | InputController.luau, CameraShiftLockController.luau, TrainingHUD.luau: binding/intent/lean input/guide |
| Visual + Curve worker | PlayerActionPoseConfigs.luau, R6ActionPoseController.luau, R6AnimationController.luau: side resolver/airprepare/Volley/noHeaderfallback/leancomposite |
| Physics worker | new src/shared/configs/AirLeanConfigs.luau และ src/shared/AirLeanSolver.luau: pure deterministicmath/config ไม่เขียนบอล/ไม่มีframe loop |
| Test Engineer | tests/e2e/Tier1_PlayerActions.luau และ new tests/e2e/Tier1_AirLeanPhysics.luau; runnerregistrationให้Leadทำ |
| Challenger | read-onlycontract/counterexamples/nativefinalpose/packetabuse ไม่เขียนsharedfiles |

ตกลงpureSolverAPI/unitsและvisualSetAirLeanAPIก่อนparallel;client/serverใช้solver/configเดียว ไม่copyสูตรสองชุด. ไม่มีsecondballwriter/physicsloopหรือframewriterใหม่.
Plan/tasks/notes02และSpec02/PRD/TDD/architecture/glossaryแก้เฉพาะOwnerdeltaนี้พร้อมpointerแหล่งเดียว; ไม่ขยาย03/GK/FullUI/อีเวนต์. ความสามารถเอนที่มีผลต่อบอลเป็นscopeใหม่ที่Ownerสั่ง ไม่เขียนย้อนหลังว่าอยู่ในprototype3หรือผ่านแล้ว.
CagePhysicsService/rigschema/RigAndCardService/CardConfigs/Sandbox/rollback/.gitignoreยังread-only. ปกป้องdirtyนอกงาน

### 12.8 Acceptance / return
- ปุ่มเก่าที่ถอดไม่มีผลทั้งเริ่ม/ปล่อย,ปุ่มใหม่หนึ่งpress→หนึ่งintent;HUDตรงbindings;focus/menu/cancelไม่ค้าง
- GroundA→Finesse,D→Trivelaทุกballside/foot,preview=serverและno aim-only inversion; neutralและdiagonalมีผลแน่นอน
- GroundLMB/RMB=Direct/Curve; AirLMB/RMB=Direct/Volleyทั้งbegin/hold/release/resolved ไม่มีheader/bicycleหรือgroundwindupปน. Verifycontext/holdcrossing/conversions/metadatareplay
- AirWASDเปลี่ยนเฉพาะpitch/roll,YawF0และjumptrajectoryยังล็อก; walking/sprintjumpต้องไม่กลับไปVYdrop/stutter. Landed/death/focus/respawnคืนneutral
- Resetfixtureเทียบneutral/left/right/front/back/diagonals,หลายaimpitch/chargeและmouseyaw. วัดinitialvelocity/spinและtrajectoryจริง ไม่อ่านexpectedจากสูตรเดียวมาassertกับตัวเอง; no automaticreticlecorrection/no RNG/no energyexploit
- negativepayloadNaN/Inf/เกินrange/stalegeneration/context/replay/ส่งถี่/leanขณะground/releasewithfuturestateไม่mutationหรือไม่ข้ามvalidation. บันทึกratecapsและnormalshotไม่starve
- Source→Edit→freshClientparityและrealinputtests/affected02regressionก่อนส่ง; ไม่อ้างfix006เป็นผลของsourceใหม่. Static/Edit/Live/Visual/NOTRUNแยกจริง
- ส่งassets/fix-007.mdฉบับเดียวพร้อมbefore→after/mapping/approveddeltas/mathunits/trace/currentSHA+hashes/testcommands/resultsและข้อค้าง. ไม่แก้fix006ย้อนหลัง ไม่closePlan02หรือfindingเอง. Gitสิทธิ์Plan02§9ยังใช้แบบscopedcommit/pushไม่force/merge/deployและไม่รวมงาน03/04

## 13. Urgent correction — HUD missing / all shooting input dead (2026-10-23)

Ownerแจ้งUIหายและยิงไม่ได้หลังfix007. Codexตรวจcurrentb579530d9ad7f4ded3cfa2af754698d97e44578f+dirtyและPlayClientจริง พบstartupsyntaxblockerตาม[review-006](review-006.md). Plan02ยังOPEN; ไม่มีสิทธิ์ข้ามข้อผิดพลาดเพราะEdittestsแสดงPASS.
**Priority:** แก้คืนClient startupก่อนfeature/polishอื่นทั้งหมด. ใช้normal focused prompt เพราะเป็นparse/fixture regressionในเส้นทางเดียว ไม่จำเป็นใช้/boostหรือ/teamwork.

### 13.1 Exact correction / scope
- InputController:345–347เป็นduplicate stale charge tailนอกRequestStartCharge ซึ่งจบที่344แล้ว; removeบล็อกซ้ำทั้ง3บรรทัด ไม่ใช่ลบendอย่างเดียว. คงcorrectvisualChargeActที่342–344 และ§12bindings/side/airDirectVolley/lean
- Tier1_AirLeanPhysics:91ใช้Constants.RUN_SPEEDที่ไม่มีอยู่ แก้fixtureให้ใช้constantจริงตามความหมายและคงassertions/cleanup. ไม่สร้างRUN_SPEEDaliasเพื่อให้testsผ่าน
- Clientinit:65 requireInputล้มจึงไม่ถึงTrainingHUD.Initข้างล่าง. ห้ามแก้ด้วยskiprequire,pcallกลืนerrorหรือHUDplaceholder. ถ้าพบbootstrapbudget/dependencyissueหลังparseผ่าน ให้รายงานเหตุจริงและแก้เฉพาะจำเป็น
- Allowlist: InputController, Tier1_AirLeanPhysics, focused regression coverageในTier1_PlayerActions/TestRunnerเท่าที่จำเป็น และเอกสาร02. Clientinitแก้ได้เฉพาะพิสูจน์ว่ามีbootstrapissueเพิ่มเติม;ไม่แก้physics/BallService/Types/controls semanticsเพื่อแก้syntax
- Leadคนเดียวทำsource+sync+testสำหรับfocusedrepair; read-onlyinternalreviewได้ ไม่เขียนชน. ปกป้องdirtyCagePhysicsService/.gitignore/notes01และdocsนอกงาน

### 13.2 Verification ต้องทำจาก fresh default startup
1. Reproduce native parse errorตามreview006และตรวจทุกLuauที่fix007เปลี่ยนว่าparse/loadในcontextที่ถูกต้อง ไม่ใช้delimitercountแทนparser
2. Synccanonicalsourceและdependencyที่เปลี่ยนไปEdit;ตรวจsourceparity,ก่อนPlayเก็บbeforestateแล้วrestartPlayใหม่เพื่อไม่reusePlayerScripts/failedrequirecache. ตรวจStudioID/Place/modeใหม่ไม่ใช้sessionIDเก่า
3. ให้defaultbootstrapเริ่มเอง ไม่เรียกInput.Init/TrainingHUD.Initด้วยมือเพื่อทำให้ดูผ่าน;ยืนยันไม่มีrequire/parseexception, PlayerGui.Module02_TrainingHUD.Enabled=true และcontrolscontainerจริง
4. RealLMBstart/release→charge/serverintent→ballเปลี่ยนvelocity/contactจริงในvalidfixture, RMBgroundA/Dstyle, RMBairVolley, MMBPass,Space/Q/LeftShift/LeftAltตาม§12 และnegativekeysaliasesไม่มีผล. ขั้นต่ำต้องพิสูจน์HUD/input/ballจริงก่อนอ้างผ่าน
5. RerunAirLeanfixturesหลังF32fixและPlayerActionsที่เกี่ยวข้อง;แยกfreshconsoleboundaryไม่เอาerrorเก่าหรือ64PASSเดิมมาสรุปsourceใหม่. ค่าtotal/failed/exceptionต้องตรงrunจริง;ไม่ลดassertionsหรือซ่อนerror
6. แยกSyntax/Unit/Edit/Live/Visual/NOTRUN. ถ้ามีassetwarningหรือlegacyrunnerhangให้แยกว่าblockingหรือout-of-scope ไม่ใช้warningกลบสาเหตุparseที่พิสูจน์แล้ว

### 13.3 Return
ส่งassets/fix-008.mdฉบับเดียว ผูกF31/F32และF17/F18เดิม พร้อมcurrentSHA/filehash/Studiofreshparity/defaultstartup/HUD+actualinputevidence/commands/resultsและข้อค้าง;ไม่แก้fix007ย้อนหลังหรือปิดfinding/Plan02เอง.
GitอนุญาตเฉพาะAGYLeadตาม§9 scopedcommit/pushไม่force/merge/deploy;currentbaselineb579530และreferenceSandbox/rig/physicsยังprotected. หลังส่งผลให้Codexตรวจcurrentrefใหม่ก่อนถือว่างานผ่าน.

## 14. Owner tuning — smooth lean / correct W-S / aim-relative shot / crisp visuals (2026-10-23)

**Owner latest:** UIเริ่มใช้ได้แต่leanไม่smooth, Wเอนหลัง/Sเอนหน้าสลับกัน; หลังA/D/Sลูกไปซ้าย/ขวา/หลังเป็นทิศใหม่มากเกิน จึงเปลี่ยนเป็น “อิงตามเป้าที่เราเล็ง แต่ไม่ตรงเป้า” และขอลดความฟุ้งของตัวละคร/เส้นสนาม/บอล.
คำสั่งนี้ **แทนฐานairshotที่ผูกlockedF0ใน§12.6**: ballaimใช้validatedcamera/reticle3Dเป็นฐาน ส่วนcharacterfacing/yawและjumptrajectoryยังล็อกเดิม. ห้ามแก้ด้วยunlockตัวละครหรือให้leanเปลี่ยนmovement.
คง§12singlebindings/groundA=Finesse,D=Trivela,groundLMBDirect/RMBCurve,airLMBDirect/RMBVolley;ไม่คืนHeader/Bicyclefallback. Plan02ยังOPEN,03ยังรอฐานร่วม/สัญญา,04ยังพัก.
AGYกำลังทำstartuphotfix§13: ให้จบoperationที่กำลังรันและเก็บF31/F32fixก่อน แล้วรวมtuningนี้ในfix008ถ้ายังไม่ส่งreport. หากfix008ถูกส่ง/commitแล้ว ให้รอบนี้ใช้fix009และบอกเลขจริง ไม่แก้รายงานhistoricalย้อนหลัง. ไม่ทำreportซ้ำของรอบเดียว

### 14.1 Source observations / bug IDs
- **F-33 P1 OPEN:** AirLeanSolver.ComputeLeanAnglesให้W(+forward)เป็น+pitch แล้วComputeLeanCFrameใช้+pitchในPart0X;ทำให้Torso.UpเอียงไปหลังตามR6frame ขัดทิศW/Sที่Ownerต้องการ. แก้rotation convention ไม่ใช่สลับชื่อinputฝั่งเดียวจนserver/visualคนละความหมาย
- **F-34 P2 OPEN:** Inputส่งcleanF/cleanRดิบเข้าSetAirLeanทุกRenderStepped; ActionPoseController:666–668คูณleanCFหลังbaseposeLerp. จึงข้ามsmoothingของbasepose. ServerSlewอย่างเดียวไม่ทำให้clientpreviewsmooth
- CurrentBallService:758–770ใช้st.jumpFacingF0เป็นbaseazimuthและใช้aimเฉพาะelevation. นี่ตรงกับข้อเลือกOwnerก่อนหน้า แต่ถูกsupersedeใน§14แล้ว ไม่ใช่ให้แก้แค่อัตราsideimpulseโดยยังฐานF0เดิม
- LiveClientที่ตรวจ: Lighting.Bloom enabled intensity1/size24/threshold2 และ Lighting.GrittyBloom enabled intensity.55/size28/threshold.8; Atmosphere density.38/haze2.5/glare.1. DOFdisabled. CharacterPlastic/reflectance0, fieldlineConcrete, ballCageMatchBallNeon. เป็นactualread-onlyinspection ไม่ใช่ผลว่าภาพหลังแก้ผ่านแล้ว

### 14.2 Correct and smooth lean
1. semanticinputเหมือนกันทุกชั้น: W=leanForward+1/S=-1,D=leanRight+1/A=-1. WทำTorso.Upเอียงไปhorizontalfacingที่ล็อก; Sตรงข้าม; A/Dไม่กลับข้าง. แปลงsignedpitch/rollจากPart0/rigจริง อย่าassertแค่มุมที่คืนจากhelperเทียบตัวเอง
2. มีcurrentaccepted/predictedleanแยกจากtarget. ใส่dt-basedsmooth/slewก่อนComputeLeanCFrame/finalcomposite ไม่คูณrawtarget±1หลังsmoothing. easingไม่ผูกfps/minAlphaคงที่;ใช้หลัก1-exp(-lambda*dt)หรือboundedcontinuousfilterที่พิสูจน์ได้ ไม่ซ้อนfilterจนinputหน่วงหลายชั้น
3. W→S/A→D/diagonals/keyup/landing/shotreleaseต้องไม่snap. Leanค้างต่อได้เมื่อปุ่มยังค้าง;releaseให้snapshotสำหรับบอล ไม่resetbodyleanเป็น0ทันทีเพียงเพราะยิงแล้วเด้งกลับ1จากpacketถัดไป. ล้าง/returnneutralตามkeyup/landed/death/focus/respawnด้วยlifecycleที่ถูกต้อง
4. Composeกับshot/volleyในsinglejointwriterเดิม และตรวจclearanceบนfinalposeที่รวมlean. ห้ามclearanceoverrideทำให้rootเด้ง/สไลด์ลอย. คงjumpimpulse/characterroot/headinglockแก้แล้วจากfix006และfreshbootจาก§13

### 14.3 Aim-relative bounded ball deflection
1. ใช้existingvalidatedaimDirection3D/currentreticleaimเป็นฐานคำนวณnormalactionlaunch; ไม่discardaimyawหรือแทนด้วยjumpMoveDirection/F0/WASD. F0มีหน้าที่characterfacing lockและreferencefallbackเท่านั้น ไม่ใช่basevelocityของลูก
2. Neutralleanใช้basevelocity/spinของactionจากaim3Dเดิมแบบไม่มีleanoffsetเพิ่ม. รวมbias/chargeตามprofileครั้งเดียว ไม่reconstructมุมจากF0แล้วบวกvelocity/biasซ้ำ
3. Leanเป็นsmall deterministicperturbationในaim-localframe: Right/Upสร้างจากbaseaimและverticalreferenceพร้อมstablefallbackเมื่อaimใกล้vertical. อย่าใช้worldcardinalX/ZหรือrawA/D/Svectorเป็นทิศlaunchใหม่. Preserveการเล็งซ้าย/ขวา/หลังจริงที่ผู้เล่นเลือก แต่leanต้องไม่ทำลูกไปด้านอื่นโดยไม่มีaimรองรับ
4. ตั้งต้นจูนด้วยtotalextraangularconeไม่เกิน5degเทียบnormalizedBASELAUNCHVELOCITY (รวมbaseactionbiasแล้ว),diagonalไม่ทำเกินcap. ปรับtuningภายในแนว“เบี่ยงนิดเดียว”หลังวัดและบันทึกก่อน/หลัง;ไม่เพิ่มpowerหรือทำลูกหัน90/180degเพราะlean
5. สปิน/extraMagnusต้องจำกัดจนtrajectoryช่วงแรกยังสัมพันธ์เป้า ไม่launchใกล้เป้าแล้วforceดึงออกข้างแรง. แยกหน่วยangularvelocity(rad/s)กับforce/acceleration(studs/s²);ห้ามบวกspinVecตรงเข้าค่าforceโดยไม่แปลงที่อธิบายได้. ถ้ายังไม่ใช้spinกับsolverจริงอย่าอ้างว่าphysicalspinverified
6. ไม่RNGspray/autoaimmagnet/แก้ตำแหน่งบอลให้เข้าเป้า. keeponeBallServicewriter/physicsintegration,finite/rate/metadata/intent/generationvalidation และenergybounds. ไม่แก้Workspacegravity/cagecollisionkernel/ballradius
7. Testsต้องตั้งcameraaimกับfacing/moveintentต่างกันอย่างน้อย90และ180deg. เปลี่ยนA/D/S/leanแล้วbaseยังตามเป้า ไม่ตามหน้าหรือjumpvector. Neutralและ±leanเทียบsamefixture;dot(baseLaunch,finalLaunch)>0และextraangleไม่เกินcone,ระยะเบี่ยงที่5/10/20studรายงานจริง ไม่ใช้สมมติฐานว่าaim=facingในทุกtest
8. Updateเอกสาร/testsที่บังคับF0ให้เป็นshotbaseใน§12ตามOwnerdeltaนี้;characterYawlocktestsยังอยู่ ห้ามลบข้อนี้เพื่อทำให้ลูกตามเป้า

### 14.4 Remove fuzz / halo while retaining colors and geometry
1. ลด/ปิดgameplayBloomทั้งLighting.BloomและGrittyBloomไม่ให้ซ้อนกัน;ลดAtmosphereHaze/Glareและdensityส่วนที่ทำให้ใกล้สนามหม่นฟุ้ง. เริ่มจากnoBloom/noHazeในการเทียบ แล้วจูนความสว่างให้ยังเห็นสนาม/สีทีมชัด ไม่ใช่แก้โดยทำทั้งฉากมืด
2. ไม่เปิดBlur/DOFเพิ่ม. ตรวจeffectใต้Cameraด้วย อย่าลบposteffectsทั้งหมดสุ่มๆหรือปรับสีผิว/สีทีมเพื่อชดเชยhalo. KeepClockTime/sky/coloridentityถ้าไม่จำเป็นต้องเปลี่ยน
3. บอลเปลี่ยนNeonเป็นnon-emissive Plastic/SmoothPlasticได้เพื่อขอบคม โดยคงRGB/ขนาด/radius/collision/mass/ballmechanics. เส้นสนาม/ตัวละครที่เป็นConcrete/Plasticอยู่แล้วไม่จำเป็นเปลี่ยนวัสดุ/สี
4. ตรวจsourceที่สร้างeffectsให้คงผลหลังfreshPlay;ไม่แก้เฉพาะClientcurrentLightingแล้วreportว่าถาวร. Scopepresentation-only: BallService.EnsureBallInstance materialและCagePhysicsService.setupGrittyLighting parameters/effectenable เท่าที่จำเป็น
5. **ข้อยกเว้นprotectedfileแบบแคบ:** Ownerอนุญาตแก้visualsettingsดังกล่าวแม้อยู่ในdirtyCagePhysicsService. ห้ามเปลี่ยนgeometry/solver/colliders/goal/ramp/positionหรือstageไฟล์dirtyทั้งก้อน. เก็บbefore/aftervisualhunksและparentdirtyhash. ถ้าstagingvisualdeltaต้องลากunreviewedlegacydirtyเข้ามา ให้ส่งworkingtree+แจ้งdependencyก่อนcommit ไม่commitหรือpushscopeที่ยังไม่ได้อนุมัติ
6. ไม่สร้างgraphics-settingssystem/UIใหม่,ไม่เปิดงานsyncinfrastructureที่Ownerเลื่อนไว้. Visualverificationถ้าดูviewportไม่ได้ให้INCOMPLETE ไม่บังคับscreenshot/video

### 14.5 Work allocation / scope / evidence
ใช้normalcontinuationของfocusedhotfixรอบปัจจุบันเพราะsharedSolver/Input/pose/BallServiceต้องปรับconventionพร้อมกันตามลำดับ;ไม่บังคับ/boostหรือ/teamwork. แยกpresentationworkerได้เฉพาะมีdisjointownershipจริง โดยLeadยังownBallService/Studio/Gitรวมจุดชน ห้ามหลายworkerแก้Input/solverพร้อมกัน.
Allowlistเพิ่มเติมจาก§13เพื่อทำ§14: AirLeanSolver,AirLeanConfigs,InputController,R6ActionPoseController,BallService,Typesเฉพาะจำเป็น,Tier1_AirLeanPhysics/Tier1_PlayerActionsและเอกสาร02;CameraShiftLockเฉพาะรักษาheading/ไม่ปลดlock. Visualexceptionตาม14.4เท่านั้น
ตรวจsyntax/defaultClientbootstrap/HUD/newbindingsก่อน และหลังแก้ต้องretestW/Sworldtilt,rawtargetstep/smoothing30/60/120fpsเท่าที่ทำได้,aim≠facingcaseและboundedrealballtrajectory,UI/input,walking/sprintjump/off-ballไม่regress,source→Edit→freshClientparity.
ส่งreportรอบที่ยังเปิดตาม14ต้นเรื่องฉบับเดียว ผูกF31/F32/F33/F34และfindingเก่าที่เกี่ยวข้อง,currentSHA/hashes/actualcommands/results/fieldreadingsbeforeafter/visualINCOMPLETEถ้ายังไม่ดูจริง. Plan02ไม่close/approve,03ยังรอ,04พัก. Gitสิทธิ์เดิมมีผลเฉพาะscopedPlan02และไม่ข้ามdirtyvisualstaginggateนี้.

## 15. Owner adaptation — state-based momentum jump / soft apex timing (2026-10-23)

**Owner intent:** ใช้แนวคิดจาก Volleyball Legends/Haikyuu Legends มาปรับระบบกระโดดเกมเรา: ground/actioncheck, momentum/facinglock, tilt, jumpheight/config และairactiontiming. คำตอบยืนยันรอบนี้คือ **กดออกบอลได้ตลอดช่วงลอยแต่ใกล้apexได้ผลดีที่สุด** และ **ยังเล็งmouse3Dได้ ล็อกเฉพาะcharacterfacing+momentum**. ไม่ล็อกกล้องจริงเพิ่มและไม่คืนshotbase=F0ของ§12; aim-relativeball+smallleanของ§14ยังมีผล
Plan02ยังOPEN;03ยังรอฐานร่วม/สัญญา;04ยังPAUSED. ให้จบstartup/smooth/aim/crispvisual baseline§13–14ที่กำลังรันอย่างปลอดภัยก่อนสลับcorejump ไม่ทับงานที่ยังไม่checkpointหรือเอาผลเก่ามารับรองcoreใหม่.

### 15.1 Evidence and adaptation boundaries
- ข้อมูลผู้ใช้เป็นgameplayreference ไม่ใช่sourcecodeของVolleyball Legends. ยังไม่มีหลักฐานfirst-partyที่ยืนยันว่าตัวเกมใช้VectorForce/AssemblyLinearVelocityหรือไม่ใช้Humanoid.Jumpภายในจริง ห้ามเขียนimplementationclaimนั้นเป็นCONFIRMED
- Community pagesแยกRedirection Jumpเป็นabilityที่เปลี่ยนทิศกลางอากาศได้ และKazanaSuperJumpมีmeterเฉพาะstyle; ไม่ใช้เป็นเหตุให้เพิ่มredirection/SnakeJump/class/gacha/meterในcoreเกมเราโดยไม่สั่งเพิ่ม
- Engine references: [BasePart/ApplyImpulseและAssemblyLinearVelocity](https://create.roblox.com/docs/reference/engine/classes/BasePart), [Humanoid/JumpPower/ownership](https://create.roblox.com/docs/reference/engine/classes/Humanoid), [Network ownership](https://create.roblox.com/docs/physics/network-ownership). Community gameplay only: [Redirection description](https://volleyball-legends-official.fandom.com/wiki/Positions_%26_Playstyles), [Kazana meter](https://volleyball-legends.fandom.com/wiki/Kazana)
- AGYตรวจprimaryAPIและsourceของเราให้ชัดก่อนเปลี่ยนphysics;บันทึกข้อเท็จจริง/ข้อเสนอ/ไม่ทราบพร้อมlinksใน§15นี้หรือreportรอบเดียว ไม่สร้างresearchsummaryซ้ำ. ออกแบบระบบของCageZeroตามinvariantsต่อไปนี้ ไม่ต้องพิสูจน์ว่าcloneinternalsเกมอื่นได้

### 15.2 Functional contract — adapt existing Input/BallService seam
- FSM: Grounded → Takeoff → Rising → Apex → Falling → Landed/LandingLag → Grounded; Disabled/Cancelledต่อdeath/characterchange. Grounded/landingต้องcontactจริง มีascending/descent/hasLeftGroundguardไม่ใช่worldYหรือRunningeventอย่างเดียว
- ก่อนjump: alive,actualgroundหรือboundedserverhistoryของvalidpredictedtakeoff,ไม่อยู่Slide/recovery/stunถ้ามีจริง/landinglag,ไม่มีactiveflight,ผ่านonepress-releaseguard. ห้ามเพิ่มSnakeJump/slidecancel/GKdiveเทคนิคใหม่
- Captureครั้งเดียวต่อflight: servervalidatedcharacterGeneration/intent/flightId,initialhorizontalvelocity/direction,committedfacingYaw,takeoffY/time,configuredverticalspeed,actualgravity. ยืนนิ่งได้XZ0,Walk/Sprintใช้ความเร็วที่รับจริง ไม่บังคับทุกคนเป็นWalk20และไม่ทำstationaryพุ่งเอง
- NativeHumanoidยังใช้เป็นrig/floor/movement state แต่ **การออกแรงกระโดดต้องมีเส้นทางเดียวที่กำหนดเอง** ไม่ให้nativeJumpกับclient/servermanualkickซ้อนกัน. InputBegan/JumpRequest/StateChangedต้องผ่านgatewayเดียว/idempotent ไม่แต่ละeventlaunchใหม่
- แนวทางตั้งต้นคือinstantaneouslaunchครั้งเดียว (เช่นApplyImpulse mass*(targetVelocity-currentVelocity) ตามnetworkowner) แล้วให้gravityทำงานปกติ. เลือกหนึ่งวิธีที่พิสูจน์ได้;ไม่ใช้ทั้งforce+velocity/nativejumpเพื่อแรงเดียวกัน ไม่เติมVYซ้ำกลางair ไม่anchor/teleportเพื่อทำarc
- Clientpredictionเพื่อความตอบสนองได้ แต่servervalidation/reconciliationต้องผูกflightId/intentและไม่ยิงแรงซ้ำหลังpacketdelay. ถ้าpredictionทำให้serverเห็นairแล้ว ให้ตรวจboundedrecent-ground historyอย่างจำกัด ไม่ปฏิเสธvalidjumpทันทีหรือยกเลิกgroundcheckทั้งหมด
- Horizontalmomentum/facinglockตามเดิมจนcontactlandingจริง. ระงับairmovementintentของdefaultcontrolsด้วยวิธีที่ไม่ทำให้Humanoid/forcesแข่งกัน;ไม่ให้A/D/Sเปลี่ยนflightXZ. ระบุsingleownerของlaunch/lock/yaw/reconcileและทดสอบnetworkownershipจริง ไม่ให้server/clientเขียนvelocityสวนกันทุกframe
- Cameraยังorbit/เล็ง3Dได้ ไม่มีCamera.CFramelockใหม่. CharacterHRPyawคงcommittedyaw; TorsoPitch/Rollสำหรับtiltไม่ใช้rootyaw/เปลี่ยนphysicsflight
- Baseheight/speedใช้approvedconfigของตัวทดสอบปัจจุบันและactualgravity. ไม่มีStyles/JumpMeterระบบใช้งานจริงในPhase1 ให้multipliers=1และบันทึกว่าเป็นค่าฐาน ไม่เพิ่มCardConfigs/gacha/progressionหรือแปลJumpHeightกับJumpPowerเป็นสองแรงซ้อน
- LandingLagเป็นconfigสั้นสำหรับre-jumpเท่านั้น ไม่ล็อกWalk/groundshoot/Passให้กลายเป็นstun;ค่าตั้งต้นเสนอ.08sจูนได้. heldSpaceต้องปล่อยก่อนflightใหม่ ไม่มีbunnyhop/airjump/queuedjumpที่เพิ่มเอง

### 15.3 Airborne offensive action budget / apex quality
- หนึ่งmanualoffensive releaseที่validต่อflight: DirectShoot(LMB),Volley(RMB)หรือPassใช้budgetร่วมกัน. StartCharge/cancel/lean/cameraไม่consume;invalidmetadata/stale/rejectedก่อนacceptไม่consume. validattemptที่วืดconsumeหนึ่งครั้งแต่ไม่เพิ่มwhiffstunใหม่
- BudgetownedServer+flightId+characterGeneration,consumeatomicallyก่อนapplycontact/ballimpulse,duplicate/replay/newintentหลังใช้แล้วไม่ออกซ้ำ. resetเฉพาะnewvalidflight/actualresetตามlifecycle ไม่resetจากclientflightflagสลับ/animationจบ
- กดได้ตลอดRising/Apex/Fallingเมื่อphysicalcontact/ballactionเงื่อนไขครบ **ไม่hardrejectเพราะอยู่นอกapexwindow**. Landinglagไม่ทำให้ลูกยิงกลางairกลายเป็นgroundattackโดยพลการ
- Serverคำนวณsoftqualityจากactualheightเหนือtakeoffและverticalphase/expectedapex ไม่ใช้clientส่งpower/heightเอง. ออกแบบcontinuouscurveไม่spike/stepที่vy=0,แรงหรือความสามารถกดลูกลงใกล้apexดีกว่าช่วงอื่นอย่างbounded
- Initialbalanceใช้configที่ประกาศว่าproposed: เช่นpowerfactor.9..1.0โดยapex=1คงเพดานpowerเดิม;ถ้าปรับมุมกดลงให้ทำเมื่อaimลงอยู่แล้วและอยู่ภายในsmall-extra-deflectionbudgetของ§14. ไม่หันลูกไปหาfloorเองเมื่อผู้เล่นเล็งขึ้น/แนวนอน
- actualjumpVY/gravityเปลี่ยนจากenvironmentต้องไม่ทำให้qualityหาร0/NaN. วัดapexและcontactจริง,ceiling/raisedfloor/edgefallไม่สร้างflightbudgetใหม่เอง. บอลยังsingleBallServicewriterและhitboxจริง ไม่มีfreeze/I-frame/auto-score

### 15.4 Scope and staged execution
- แก้เฉพาะjump/input/serverstate/rotation/animationadapterของ02: InputController,BallService,Constants,Types,CameraShiftLockController,R6ActionPoseController/R6AnimationControllerเท่าที่จำเป็น,sharedpureJumpModel.luau/newconfigs.JumpConfigs.luauถ้าจำเป็นจริง และfocusedtests. ไม่สร้างreplacementfootballcontroller/secondballloop
- คง12Networkdefinitions/getters;existingBallActionRequestเพิ่มtypedjump/flightmetadataและrejectreasonเท่าที่จำเป็นด้วยfinite/range/generation/context/rate/replayvalidation. แยกjump/leanratesไม่ให้ยิงstarve;เอกสารfield/phasecontractให้Leadfreezeก่อนcode
- ไม่แก้rigschema/RigAndCardService/CardConfigs/CagePhysicsServicekernel/สนาม/Workspacegravity/Sandbox หรือเปิดPlan03skills/GK4/สไตล์/JumpMeter/SnakeJump. presentation-onlyexception§14ยังจำกัดแค่นั้น
- ใช้/boostได้รอบนี้เพราะต้องพิสูจน์physics/networkownershiphand-offและstate reconciliationจากbugVYdropจริง ไม่ใช่แค่เปลี่ยนตัวเลข. เริ่มคนเดียวทำjumpcore/ownershipและทดสอบก่อน;แยกreadonlyresearchหรือpuremodel/testsได้เมื่อไฟล์ไม่ชนและinterfacesfreezeแล้ว ไม่เปิดหลายagentแก้Input/BallServiceพร้อมกัน. หากruntimeไม่รองรับใช้normalpromptและแจ้ง
- StageA: ปิดเฉพาะoperationของstartup/aim/smooth/visualที่เปิดอยู่แล้วให้baselineใช้งานได้และเก็บsourcehash/ผล. StageB: customjump FSM+singlelaunch/momentum/softquality/actionbudget. StageC: freshactualinput/latency/regression+sync. ไม่มีstageใดอนุญาตปิดPlan02หรือถือว่าplanอื่นผ่าน
- Reportรอบstartup/tuningที่ยังเปิดคงฉบับเดียว;หลังมีcheckpointแล้วcustomjumpให้ใช้fixreportเลขถัดไปที่ยังไม่มี (ห้ามทับ008ถ้าส่งแล้ว). บันทึกselectedmode/actualruntime/sourcehash/currentHEADและold→newbehaviorในreport ไม่สร้างsummaryคู่กัน
- Gitสิทธิ์เดิมใช้เฉพาะscopedPlan02checkpoint/commit/pushพร้อมhonestWIPไม่force/merge/deploy/approve/close;dirtyCagePhysicsServiceและdocsนอกงานต้องไม่ถูกรวมทั้งก้อน

### 15.5 Verification / acceptance gates
- Nativeparser/defaultboot/HUD/inputต้องยังทำงาน;realSpaceonepressได้หนึ่งflightและหนึ่งlaunch,heldSpaceไม่repeat;Walk/Sprint/stationary/diagonal/edge/raisedfloor/death/respawn/focus/reject/packetdelayครบ
- TraceactualVY/height/XZ/state/facing/networkowner/flightId;ไม่มีearlyVYcutเช่นreview005,secondimpulse/positioncorrectionspikeหรือfacingfight. XZ lockและyawlockทำงานขณะmouseaimเปลี่ยน
- Wleanforward/Sback,Aleft/Drightsmooth,diagonalsbounded,groundmovementคืนหลังlandและcameraไม่ถูกล็อก. Aim≠facing90/180degยังยิงตามaim3D+smalllean ไม่คืนF0shotbase
- Rising/apex/fallingยิงได้จริงทั้งหมดเมื่อvalidcontact;วัดcontinuousqualityโดยapexดีที่สุดแบบbounded. validfirstairreleaseconsumeหนึ่งbudget,secondreleaseคนละintentถูกปฏิเสธ,invalid/cancelไม่consume,landing/newflightresetถูกต้องและไม่มีdoubleballimpulse
- ต้องรักษาgroundLMBDirect/RMBCurve,A=Finesse/D=TrivelaและairLMBDirect/RMBVolley,off-ballfirst-time,Pass,Slide,cost/CD/metadata/leanvalidation,lookcrisp/HUDตาม§12–14. ไม่มีwhiffstun/classes/meterของเกมอ้างอิงแอบเข้ามา
- Snapshotbefore/syncEdit/freshPlayclientเทียบsource/hashจริง;NativeLivePlayไม่ใช้mockหรือsettingflagsแทน. Static/Unit/Edit/Live/Visual/NOTRUNแยกตามหลักฐาน. MissingvisualระบุINCOMPLETE;CodexอิสระตรวจcurrentrefและOwnerreviewก่อนปิดfinding

## 16. Owner change — grounded possessor Space pops ball, next press jumps (2026-10-23)

**Owner latest:** บอลตามช้าตอนกระโดดขณะครองบอล แต่physicsบอลโอเคแล้ว ให้เปลี่ยนเฉพาะกรณีผู้ครองอยู่บนพื้น: Spaceครั้งแรกงัดบอลขึ้นตามmovementWASD ตัวอยู่พื้น แล้วค่อยกระโดดตามเล่นบอลอีกจังหวะ. เป็นbasicBallPopของ02 ไม่ใช่Sombrero skillของ03และไม่ใช่การเปิด03/04.
สิ่งนี้แทน§15เฉพาะSpaceขณะpersonalpossession+grounded; nonpossessorSpaceยังcustomjumpตาม§15. คงballphysics/aim-relativelean/singlebindings/crispvisual/groundFinesseTrivelaเดิม. Plan02ยังOPEN;03ยังรอ;04พัก.

### 16.1 Resolve one Space action BEFORE character launch
- Grounded+ServerpossessorUserId=ผู้กด → BallPop เท่านั้น: ไม่ApplyImpulseตัวละคร ไม่Humanoid.Jump/ChangeStateJumping ไม่สร้างTakeoff/flightId ไม่setairborne/facinglock/landinglag ไม่consumeairreleasebudget
- Grounded+ไม่ได้ครองเอง → DirectionalJumpตามcoreใหม่เดิม. ทีมเดียวกันถือบอลไม่ใช่personalpossession;ยังJumpปกติ
- หลังBallPopปล่อยballpossessionจริงเป็นFree/InFlight รักษาlastPossessingTeam/teamAttacking;ผู้เล่นเดินหรือวิ่งตามได้ทันที. ปล่อยSpaceแล้วกดใหม่เมื่อไม่มีballpossession → Jumpตาม§15. ไม่autojump/queuedlaunchจากSpaceที่กดค้าง
- Gateนี้ต้องอยู่ก่อนInputController.commitJumpDirection/CalculateLaunchImpulse และก่อนServerExecuteDirectionalJumpสร้างflight. InputBegan/JumpRequest/StateChangedผ่านgatewayเดียว;หนึ่งSpaceintentห้ามเกิดทั้งpopและplayerjump
- Clientใช้authoritativereplicatedownershipsnapshotสำหรับbranchแต่Serverเป็นผู้ตัดสินactualowner/ground/state/intent. จัดการstaleHasBall/ownershiprace/predictionให้ไม่เกิดpop+jumpพร้อมกันหรือreapplylaunch;rejectต้องคืนpendingstateโดยไม่teleport/ตัดVYเพื่อซ่อนrace. Leadระบุวิธีreconcileที่ใช้ก่อนcode
- Airborne/dead/Slide/recovery/ballไม่ใช่ของตนไม่ใช่BallPopที่valid ห้ามดึงballคู่แข่ง/งัดทุกระยะหรือforcecharacterลงพื้น. รักษาnativeSpace suppression/press-release/idempotencyของcorejumpที่กำลังทำ

### 16.2 BallPop release / direction / height — launch change only
- BallServiceเดิมเป็นsingleballwriter. Atomicallyreleasepersonalpossessionและตั้งinitialballvelocityครั้งเดียว พร้อมlastKicker/time/feedbackตามschemaเดิม;ไม่สร้างballcontroller/ballfollowingloopใหม่
- Directionใช้actualhorizontalmovementintentWASD (Humanoid.MoveDirectionหรือvalidatednormalizedsnapshotในreferenceเดียวกับmovement) รวมdiagonalnormalized. ยืนนิ่งให้popเกือบตรงขึ้นจากตำแหน่งballเดิม ไม่บังคับforwardWalk20หรือaimทิศอื่นเอง
- Ballhorizontalvelocityใช้acceptedgroundmovement/Walk/Sprintตามmovementที่จับตอนSpaceและcapsของexistingmovement;ไม่ให้diagonalเพิ่มspeedsqrt2. Playerไม่ถูกดันหรือเล่นjumpimpulseตามball
- “เด้งเหมือนระยะกระโดด” ให้ใช้riseของcustomjumpปัจจุบันเป็นreference relativeheightเหนือballrelease ไม่ใช้rootWorldYเป็นค่าความสูง. ตัวอย่างสูตรlaunch-only: H=JumpV0²/(2*gCharacterActual), ballVy=sqrt(2*gBallEffectiveExisting*H) เมื่อgravityที่ใช้คงที่;กรณีsolverมีdrag/forceอื่นให้solveจากexistingintegratorและวัดapexจริงโดยไม่แก้solver
- ใช้actualconfig/Workspacegravityของcharacterและballgravityเดิมคนละค่า ห้ามเอาJumpV0ใส่ballตรงๆจนเด้งสูงผิดหรือเปลี่ยนballgravityให้เท่าตัว. H/launchเป็นค่าinitialtuningที่ต้องเทียบjumpปัจจุบันและจังหวะตามได้ ไม่เพิ่มstat/meter/buff
- ห้ามเปลี่ยนballgravity/drag/restitution/Magnus/collision/ballradius/networkownership/renderinterpolation/groundrestหรือshot/Pass/Volleysolverที่Ownerบอกโอเค. ไม่fakeparent/weld/teleportballตามตัวละครหรือguaranteedcatch
- Reuseexistingrelease/reacquireguard(lastKicker+lastKickTimeเป็นต้น)เฉพาะจำเป็นเพื่อไม่auto-repossessทันทีที่popเริ่มใกล้เท้า;ห้ามปิดcollisionหรือห้ามคนอื่นแย่งบอล. ไม่เพิ่มI-frame/auto-stun/auto-possession
- BallPopไม่ใช่DirectShoot/Pass/Volley/Bicycleจึงไม่ใช้shotcharge/softapex/airbudgetหรือส่งท่าเหล่านั้นปลอมเพื่ออาศัยsolver. groundtoe-liftvisualสั้นได้โดยR6rigเดิมและbodygrounded ไม่มีwholebodyjump
- ถือchargeอยู่ตอนpopให้รักษาintentlifecycleเดิมและระบุinteractionชัด;ไม่ปล่อยshotซ้ำ/ไม่ล้างchargedintentด้วยfeedbackของBallPopคนละidเอง. ไม่มีnewwhiffpenaltyหรือlandinglagจากpop

### 16.3 Narrow protocol and scope
ใช้existingBallActionRequest: เพิ่มtypedactionBallPop (หรือserverresolvedSpacefamilyที่Leadพิสูจน์ว่าจำเป็น), startphase, validatedmoveintent/meta;รักษา12RemoteDefinitions/getters. Servervalidatepersonalowner/realground/lifecycle/cost-CDเดิมถ้ามี/finite/range/idempotencyก่อนmutate. ไม่ให้clientกำหนดballVY/position/finalpowerหรือclaimownershipเอง
Allowlist: InputController,BallService,Types,JumpModel/JumpConfigsหรือConstantsเฉพาะderivedpoplaunch/configจริง,existingR6poseadapter/HUDguideเฉพาะfeedbackใหม่ และfocusedtests+docs02. ไม่แก้Camera/yaw/aimphysics/CagePhysicsService/rig/schema/สนาม/Sandbox/ballkernelหรือเปิดSkill03/GK.
โหมดnormalfocusedcontinuationเพราะเป็นcontextbranchเล็กในjump/ballseamเดียว;ไม่จำเป็นเปิด/boostหรือteamใหม่ให้ชนงานcustomjumpที่กำลังทำ. Finishatomiccurrenteditก่อน และคงแกน§15ส่วนที่ยังเกี่ยวข้อง ไม่ย้อนกลับsourceเก่า
Baselineที่ตรวจ HEADa7178da844d2aa56cefe4c38d665f2af5f9e7391+in-progresscustomjumpdirty;freezeactualHEAD/hashesล่าสุดก่อนแก้. อย่าเคลมว่าdirtyCagePhysicsServiceเป็นผลงานรอบนี้หรือstageทั้งก้อน

### 16.4 Test / report / return
1. Ownball+ground+W/A/S/D/diagonal/stationary/Walk/Sprint→Spaceหนึ่งครั้ง: ballมีupwardlaunchตามmovement,ownerเป็นnil,stateFree/InFlight,teamcontextไม่สลับ,characterไม่Takeoff/ไม่launchและยังmovegroundได้
2. HoldSpaceหลายframeไม่popซ้ำ/ไม่jumpอัตโนมัติ;Spacekeyupแล้วpressใหม่→normalcustomjumpครั้งเดียวตามmomentum/face+mouseaim/tiltเดิม และตามไปเล่นballfirst-timeได้โดยไม่ต้องpossessใหม่ก่อน
3. Teammate/enemyownsball,ballfree,ownershipchanged/staleclientflag,airborne,invalid/replay/rate/generation/context/NaNต้องไม่stealball/ไม่ทำสองactionจากpressเดียวและไม่ทำclientค้าง
4. Measureballrise/apextime/horizontaldistanceและplayergroundheightเทียบreferencejump;ตรวจno immediate self-relatch,defenderยังcontactได้,chargeinteractionและreset/deathcleanup. ไม่ใช้setflags/mockอย่างเดียวแทนrealkeyboard→server→ball
5. Regression: nonownerstanding/walk/sprintjump,oneflight/oneairrelease,softapex,UI/singlebindings,A-Finesse/D-Trivela,airLMBDirect/RMBVolley,aim3D+smalllean,W/Ssmoothและcrispvisualต้องคง. เทียบballintegratorconfig/behaviorก่อนหลังยกเว้นinitialPoplaunch
6. หากรอบcustomjump§15ยังไม่ส่ง ให้รวมpossessionSpacebranchในfixreportรอบนั้นฉบับเดียว;ถ้าส่งแล้วใช้เลขถัดไปที่ยังไม่มี ไม่แก้historicalรายงานย้อนหลัง. ส่งsource→Edit→freshClientparity/currentSHA/hashes/repro/results/ค่าจูน/ข้อค้าง ไม่closePlan02เอง
GitauthorizationเดิมเฉพาะscopedPlan02checkpoint/commit/pushไม่force/merge/deploy/approve และไม่รวมdirtyนอกงาน. กลับมารายงานCodexpaneที่ตรวจสดตามOwnerอนุญาต.

## 17. Focused aim transport correction — S/backtilt still fires locked direction (2026-10-23)

Ownerบอกส่วนอื่นพอได้ เหลือairtiltshot directionโดยเฉพาะS/backtiltที่เรียกว่าจักรยานอากาศ ยิงทิศเดียวไม่ตามเป้า. **โฟกัสแก้aimต้นทางก่อน ไม่รื้อjump/BallPop/ballphysicsที่Ownerพอใช้แล้ว**. คำนี้ไม่ใช่อนุญาตrestoreBicycle/Headerfallback;คงLMBDirect/RMBairVolleyตามข้อยืนยันเดิม.
ActualreviewedHEAD `5c33d5f060a9f613d6841767637bf917f9a69614` + unrelateddirty;AGYส่งfix009แล้ว. [review007](review-007.md)พบF35P1OPEN: InputController.getAimDirection:128–132ใช้jumpCommitDirXZแทนcameraaimyawตอนair ทำให้payloadผิดแม้Server/solverใช้aim-relativeถูกแล้ว.

### 17.1 Narrow scope and invariants
- ใช้normalfocusedprompt เพราะแก้branchเล็กของclientaimpathกับtestที่ตรงseam ไม่บังคับboost/teamworkหรือเปิดagentsชนInputไฟล์เดียวกัน
- InputgetAimDirectionต้องคืนcurrentfullvalidatedcamera/reticle3D aimทั้งground/air;คงfallbackเมื่อไม่มีcamera. ห้ามreconstructด้วยF0/jumpCommitDir/HRPLookเพียงเพราะairborne และห้ามเอาสัญญาณWASDleanมาแทนbaseaim
- auditRequestKick/predicted/release/serverresolvedให้ได้aimเดียวกันจริง. Character yaw/facing/momentumlockยังคงเดิม;ballaimแยกจากorientation. ไม่แก้CameraControllerให้หมุนตัวตามaimเพื่อซ่อนbug
- คงSbacktilt/Wforward และsmooth/boundedcone/profilebiasของ§14, BallPop§16, oneairaction/softapex§15,UI/onebinding/groundA-Finesse-DTrivelaและcrispvisual. ไม่เพิ่มforce/power/spin/แก้gravityหรือtrajectorysolverที่Ownerบอกโอเค
- Allowlist: InputControllerและfocusedtest/temporarydiagnosticที่จำเป็น;AirLeanPhysics/PlayerActions testcasesต้องเรียกclientaim acquisition/releasepipelineจริง. R6/Server/Solver/Cameraแตะได้เฉพาะพิสูจน์ว่ามีlockedaimoverrideอีกจุดและรายงานexactchange ไม่ใช้สิทธิ์กว้างจากรอบก่อนรีแฟกเตอร์
- ปกป้องdirtyCagePhysicsService/.gitignore/notes01/docsนอกงาน;ไม่แก้sourceSandbox/rig/Networkdefinitions

### 17.2 Tests that expose THIS bug
1. Freshsourcehash/parityและfreshPlay/requirecache;defaultboot/HUD/inputต้องผ่าน. StudioID/Place/modeค้นหาใหม่ไม่ใช้oldsessionโดยเดา
2. LockbodyYawF0คงที่+leanSคงที่+sameballfixture/charge;เปลี่ยนcameraaimyaw0,+60,-60,180แล้วกดactualLMB/RMBตามinputจริง. บันทึกcamera/reticleaim→payloadaim→serveracceptedaim→actualinitialballvelocityและbodyYawอย่างมีtimestamp/flightId
3. balllaunchต้องเปลี่ยนตามaimyaw ไม่ค้างjumpCommitDir;เล็งหลังได้เมื่อaimหลังจริงแต่leanไม่บังคับลูกหลังเอง. Extra leanเทียบbaseprofilelaunchไม่เกิน5degและไม่auto-correctกลับreticle
4. ทดสอบneutral/A/D/W/Sและnearverticalbasis,ทั้งDirect/Volley,ballpop→keyup→jump→shoot,invalid/replay/airbudgetไม่regress. ห้ามตั้งaim=facingทุกcase หรือข้ามgetAimDirectionแล้วเรียกExecuteKickตรงๆอ้างว่าแก้แล้ว
5. แยกStatic/Unit/Edit/Live/Visual/NOTRUN;ถ้ายังไม่มีactualcamera→payloadtraceอย่าใช้solverunit/116PASSเก่าเป็นsignoff. ไม่บังคับscreenshot/video

### 18. Owner delta — right-foot dominant Plan02 — 2026-10-23

- Owner authorizes a focused correction: this Plan02 character is right-foot dominant. A / left movement selects Finesse with the inside of the RIGHT foot; D / right movement selects Trivela with the outside of the RIGHT foot. Preserve neutral/A+D default Finesse. Movement side is relative to the character, not world X or aim direction; reconcile existing keyboard and movement-intent paths without adding bindings.
- Baseline observed: `7cdca7fff61b1f6a92c15821c0162e4cec24c5ca` plus existing protected dirty files. `src/shared/configs/PlayerActionPoseConfigs.luau:771` ResolveCurveShot still chooses foot from ballSide at line809. Replace that active Plan02 selection; ball left/center/right must not change dominant foot, style, or mirror the right-foot pose. Keep ballSide only as useful contact metadata. Preserve existing right-foot spin profiles rather than compensating by changing global ball physics.
- AGY owns implementation and verification. Allowed focused paths: shared curve resolver, InputController preview/intent, BallService resolved foot/style, R6ActionPoseController charge/release composition, relevant existing tests and Plan02 documentation. Do not redesign rig/CardConfigs/classes or remove future Left-foot type support. Protect unrelated dirty files; preserve §17 full camera aim, air yaw/momentum lock, lean smoothing, BallPop, single bindings and good ball physics.
- Acceptance: A/left→Finesse+Right; D/right→Trivela+Right; neutral→Finesse+Right. Verify ball on all three sides and varied camera/character yaw, including movement-intent paths, charge hold and release. Client preview, server ResolvedCurveStyle/ResolvedKickFoot and actual right-leg animation agree. Ground curve selection must not replace airborne RMB Volley. Run focused checks plus actual input/runtime evidence; separate unverified visual behavior from static/unit results.
- Normal prompt is sufficient: sequential correction in the same resolver/input seam, no parallel agents required. fix-010 is already delivered; use `assets/fix-011.md` for this delta, record actual SHA/source parity, commands/results and outstanding evidence. Reuse this HANDOFF. Existing scoped AGY Plan02 Git authorization remains; no merge/deploy/force or closure. Plan02 stays OPEN; Plan03 pending handoff and Plan04 paused.

### 19. Owner correction — actual movement and curve result

Owner confirms Finesse/Trivela ANIMATION accepted visually; do not reauthor or swap these poses. Owner reports shot selection/curve A-D reversed and not following actual movement. Inspect InputController.getCurveSideIntent (raw A/D currently overrides actual MoveDirection), curve resolver, BallService rightVec/curveForce and real trajectory. Keep right-foot contract: actual left lateral movement -> Finesse inside right foot, actual right -> Trivela outside right foot. Use the same character-relative movement basis for preview and accepted shot; input-only fallback for no movement must not override contradictory actual movement. Preserve neutral behavior and camera aim, do not use world X. Do not blindly swap pose names or invert both style and spin. Prove initial aim and signed curvature from actual movement/release/server launch for A/D, diagonals and rotated character/camera. Preserve established ball physics kernel and other Plan02/03 controls. Deliver focused fix-012 with source ref and measured evidence; Plan02 stays OPEN. Owner requests monitoring only: no ACK, pane replies, greetings or status messages sent to Codex; Codex reads pane/files itself.

### 22. LATEST Owner delta — LIVE curve selection during charge (2026-10-24)

Owner explicitly removes the initial A/D choice lock. This supersedes §20, fix012's initial-style latch requirement, §21.1 references preserving that latch, and Plan03§D/G historical latch references ONLY for curve side/style selection. Right-foot dominance/accepted poses/charge strength/timing/one-binding/FakeShot and other gameplay scope remain.

- Ground RMB Curve charge continuously follows CURRENT character-relative movement using the shared resolver: left/A Finesse RIGHT inside foot, right/D Trivela RIGHT outside foot; stationary/neutral keeps documented existing default. Apply actual movement with existing valid keyboard fallback, not world X/ball side/camera yaw. No requirement to choose A/D before pressing RMB and no key release/new charge required to change style while holding.
- Client windup/held-pose style updates smoothly as movement side changes, without replaying full windup, resetting charge power/start time/intent, duplicating event handlers or foot slips. Preserve accepted authored Finesse/Trivela clips, blend their correct charge poses. Only take final style/side snapshot at the actual release/contact for this shot; movement after shot does not retroactively alter flight.
- Server validates/resolves current accepted movement/release side with the same shared selector and applies matching style/spin/foot. Stale start-charge side must NOT override release side. Client payload does not grant arbitrary style/foot/power. Charge remains Server authoritative and FakeShot/cancel/death/reset/context/generation/replay cleanup still works.
- Test D→RMB down→A→RMB up => Finesse, inverse =>Trivela, switch several times while holding, press RMB first then choose A/D, neutral/A+D, diagonal/rotated character/camera and unchanged charge/foot. Verify actual hold preview→request→accepted Server style→initial spin/trajectory; no sign-only label swap. Air RMB Volley unchanged; no new bindings or unrelated retune.
- Implement narrowly in ongoing assignment through codexluna; record in current implementation report, no new duplicate handoff/report or approval/closure. Owner authorized this change while the rest of §21/Plan03§G continues. No ACK/messages back to controller.

### 20. HISTORICAL Owner clarification — initial-press lock SUPERSEDED by §22

Latest Owner instruction supersedes §19 only on sampling time: select curve style from direction at the FIRST accepted RMB charge press, then freeze for that charge intent. D/right at start = Trivela RIGHT foot; switching to A during hold/release must NOT become Finesse. A/left at start = Finesse RIGHT foot; switching D must NOT become Trivela. Neutral uses existing Finesse default. Preserve §19 actual movement/basis correction when choosing initial side; do not resample it on release. Snapshot side/style/foot in client charge state and Server charge intent, use same snapshot for hold preview/release/accepted launch; Server must not trust a changed release style over accepted start. Snapshot only curve selection, not freely adjustable aim/charge strength. Clear snapshot on cancel/reject/reset/context invalidation/death/new intent so no stale selection leaks. Test D→RMB down→A→RMB up, inverse, neutral, repeated charges/cancels; verify pose and actual spin/trajectory agree. Ground curve only; air RMB Volley unchanged. Integrate into current fix-012 rather than duplicate reports; preserve accepted animations and physics. NO ACK or messages back to Codex; monitoring only.

## 21. Owner playtest delta — E Pass / Fake Shot / S loft / attack miss recovery

Owner authorizes these revisions in chat 2026-10-23 and requires animation tools from Obsidian. Baseline HEAD `c7542258b93b613e0260e43035761cbce87928cd` + dirty Plan02/03 delivery; record fresh source hashes. AGY implements, Codex independently reviews. Coordinate sequentially with Plan03 HANDOFF §B because Input/BallService/R6/Studio are shared. Normal prompt; no compulsory boost/teamwork or parallel agents. NO ACK/messages back; controller monitors pane/files. Working-tree delivery only for this mixed round, no commit/push/merge/deploy/closure. Plan02/03 remain OPEN, Plan04 paused.

### 21.1 E Pass and Fake Shot

- Move Pass from MMB to E ONLY, hold/release for existing charge. Audit E consumers before wiring; no aliases. MMB remains defending Cage Press ONLY; remove attacking Pass behavior and update HUD/tests. Defending E has no new tackle mapping.
- Ground attacking LMB Direct or RMB Curve charge + E PRESS immediately triggers Fake Shot, NOT Pass. Consume E press AND release; original mouse release later must not shoot, pass or restart charge. Server atomically cancels/terminalizes original shot intent, validates FakeShot and rejects stale release/replay. New shot requires fresh press after recovery. Aim remains adjustable; preserve fix012 initial curve selection latch.
- Fake Shot animation initial duration0.25–0.35s: partial swing/hip feint into sole stop/protective touch and natural directional exit. Inspect/reuse suitable older clip if available or tool-author it as §B requires. Ball stays at ordinary controllable dribble distance only if actually possessed, never teleport/unowned capture/weld/anchor/I-frame. Opponents can tackle throughout. Not a sixth loadout Skill Move or automatic successful dodge.
- Nonpossessor may cancel/cosmetically feint but cannot lock/gain ball. Clear snapshots/restore movement on rejection/cancel/context change/death/reset. Air E does not trigger the new grounded Fake Shot or convert the existing shot unexpectedly; preserve flight budget.

### 21.2 Backward S lean — latest physiological correction (Plan03 HANDOFF§G.1)

- Owner clarified and authorized full implementation: S backward lean should make the ball naturally a little loftier according to body/strike posture, NOT switch to a fixed high lob. Previous fixed vH32/vY40 / forced F0 azimuth / estimated rise12.31-range39.38 are SUPERSEDED, not targets. No new X air or Bicycle/backward mapping. Existing valid Direct/Volley/Header contacts only, no extra binding/contact fallback.
- Preserve current free3D aim azimuth, body yaw/momentum lock, neutral launch and global physics. Shared config-driven Server/prediction computation couples accepted smoothed lean/contact orientation to a continuous bounded elevation change, action-profile-specific coupling and existing energy limits. Small tilt should make a small change; no raw S-key velocity switch, forced reversal, discontinuity or independent per-action hardcoded formulas. Read Plan03§G.1 exact acceptance and measure actual launch/lean continuity/apex.

### 21.3 Slower receivable Pass

- Current pass base68 * (0.55+charge), charge0.50–1.00 => unbuffed71.4–105.4studs/s; current Direct base125 =>131.25–193.75 before other modifiers. Do not assume charge directly multiplies base.
- New neutral unbuffed GROUND Pass launch target24–40studs/s tap→full, keep Direct profile. Use explicit pass-specific mapping/config to reach measured speed; preserve one 3D Pass action, no separate lob binding or aim magnet. Ideal20stud travel0.50–0.83s before rolling drag. Audit actual receivable/interception thresholds, not only Poke's42 threshold. Buffs/high balls still use valid contact/contest rules.

### 21.4 Attacking whiff recovery / anti-spam

- Owner adds recovery on ground and air shot MISS: interpret as no valid ball contact/out-of-reach whiff, not delayed judgement of whether a launched shot scored. Initial ground0.35s, air0.50s authoritative recovery with readable R6 overswing/off-balance and movement slowdown. No new successful-shot penalty.
- During recovery Server blocks repeated shot/Skill/Dash/tackle/FakeShot bypass chains; client/HUD uses same deadline. Normal movement/aim remains with slowdown; valid grounded Pass can follow existing gates but cannot clear deadline or bypass shot lock. Preserve one valid air release per flight. Duplicate/rejected malformed inputs cannot repeatedly charge stamina or indefinitely extend recovery.
- Landing/key release/cancel/context swap cannot reset recovery. Use generation-safe cleanup for death/reset; no stale callbacks. Test air whiff→land→shot, ground no-ball/out-of-reach, alternating LMB/RMB/E/Space, repeated intent/replay and FakeShot stale release. Clearly distinguish contact miss from invalid payload rejection.

### 21.5 Scope and return

Allowlist: InputController, TrainingHUD, BallService, SkillMoveService shared recovery gates, PlayerActionPoseConfigs/R6ActionPoseController, Constants, semantic Types/Network if needed, AirLeanSolver/AirLeanConfigs for this S exception, existing focused tests and narrow current Plan02/03 docs. Preserve accepted Finesse/Trivela clips/fix012, rig/default cards, good ball integrator and protected dirty CagePhysicsService/.gitignore/notes01/unrelated docs. No global physics/geometry changes.

Use mandatory Obsidian animation authoring workflow in Plan03§B for FakeShot/recovery/rejected Skill poses. Verify actual input→Server intent→ball, fresh source-to-Studio parity/boot/HUD and two-player contest; distinguish unit/Edit/Live/visual/NOT RUN. Editable clips/exports/tool provenance required; numeric audits alone cannot prove visuals. No mandatory screenshots/video. Return one `assets/fix-013.md` with current ref/hashes, commands/results, measured pass/loft/recovery, linking Plan03fix002 rather than duplicate evidence. No ACK or pane reply.

### 17.3 Return and monitoring
ส่งassets/fix-010.mdฉบับเดียว ผูกF35พร้อมrootcause/sourcebeforeafter/currentSHA/hashes/realpipelineevidence/commands-resultsและข้อค้าง. เก็บfix009/review007historical ไม่ปิดfinding/Plan02เอง;03ยังรอ/04พัก.
Ownerอนุญาตmonitorผ่านpaneagycagezero ให้ตอบรับสั้นและรายงานกลับCodexpaneที่ตรวจสดเมื่อcomplete/blocked. Monitoringcompletion≠reviewpass. Gitสิทธิ์scopedPlan02เดิมไม่force/merge/deploy/approve/closeและไม่รวมdirtyนอกงาน.




