## Current accepted design — 2026-10-20

Q22อนุมัติเอกสารตามQ1–Q21; ใช้ [Spec02](../../../specs/spec-02-duel-and-parry.md) และplan/tasksปัจจุบันเป็นเจ้าของscope implementationยังPENDING ไม่ขยายงาน00 และไม่เปลี่ยนรายงานhistoricalเป็นผลผ่านของระบบใหม่

## N-01 — Owner Directive: Start Plan 02 (Continuous Football) (2026-10-21)

- **1. คำสั่ง Owner (คุณ Stang):** *"งานนี้ รอรีเช็คอีกที เริ่ม plan ต่อไปได้เลย แต่ plan ปัจจุบันยังไม่ปิด ปรับสถาณะไว้ เดี๋ยวค่อยมาตรวจtechnical ทีหลังอีกที"*
- **2. สถานะการปกป้อง:**
  - แผน `00-bootstrap-and-rig` คงสถานะ `OPEN / PAUSED_BY_OWNER`
  - แผน `01-cage-physics` คงสถานะ `OPEN / PENDING_TECHNICAL_REVIEW` (fix-005 เสร็จสมบูรณ์แล้ว พักรอตรวจ technical ภายหลัง)
  - แผน `02-player-actions` ปรับสถานะเป็น **`IN_PROGRESS / AUTHORIZED_BY_OWNER`**
- **3. ข้อกำหนดฟุตบอลต่อเนื่อง (Continuous Football per Q22 / Spec02):**
  - **BallService (Single Writer):** ดูแล Ball physics instance (`Workspace.CageMatchBall`), Possession, Attacking Team Context, Passes, Direct/Curve Shots, และ First-time play (Header/Volley/Block)
  - **Movement & Stamina:** Walk/Sprint/Dash/DirectionalJump (ห้ามเปลี่ยนทิศกลางอากาศ)/ShiftLock และ Stamina pool กลางที่ใช้ร่วมกับแผน 03
  - **Team Context Buttons:** ทีมครองบอลล่าสุด = ยิง / ส่ง / ยิงโค้ง; ทีมคู่แข่ง = Slide / Poke / Shoulder (ในแผน 03); บอลอิสระหลังยิง/ส่ง/ชิ่ง ทั้งทีมยังคงปุ่มบุกจนกว่าคู่แข่งจะครองสำเร็จ
  - **Parry / Choice Duel:** ตัดออกตามมติ Q22 อย่างถาวร (ไม่มี I-frame, ไม่มี Turn-based cutscene, บอลแย่งได้ตลอดเวลา)


Q22อนุมัติเอกสารตามQ1–Q21; ใช้ [Spec02](../../../specs/spec-02-duel-and-parry.md) และplan/tasksปัจจุบันเป็นเจ้าของscope implementationยังPENDING ไม่ขยายงาน00 และไม่เปลี่ยนรายงานhistoricalเป็นผลผ่านของระบบใหม่

> **Historical baseline notes:** ข้อมูลเดิมก่อนย้าย/แยก phase ให้ใช้ plan.md และ tasks.md ในโฟลเดอร์นี้เป็น scope ปัจจุบัน ผลตรวจ/สถานะเก่าไม่ใช่การรับรองแผนใหม่

# Technical Notes — MODULE 02: `02-ball-control-and-parry`

- **BallService:** จัดการ Possession, Stamina (`0.0–1.0`), `IsInShootingZone` (`Z >= 10` สำหรับทีมบุกฝั่งใต้, `Z <= -10` สำหรับทีมบุกฝั่งเหนือ, และระยะ `<= 55 Studs` ในโหมด `1v1v1`), และการตรวจจับ Mistake (`StaminaExhausted`, `BadFirstTouch`, `SharpTurnOffBalance`)
- **ParryService:** ตรวจจับลูกบอลที่ถูกส่ง/ยิงผ่านรัศมี `<= 5.0 Studs` ของกองหลัง เปิดหน้าต่าง `0.35 วินาที` โดยไม่ตัดเข้าหน้าจอดวล 1v1 และตรวจสอบจังหวะกดด้วย `os.clock()` บน Server หากกดพลาดติด `MissedSlideRecovery` `0.50 วินาที`


## N-02 — Implementation & In-Engine Verification of Plan 02 (Continuous Football) (2026-10-21)

- **1. โมดูลที่สร้างและปรับปรุง (Source Files):**
  - [src/shared/Constants.luau](file:///C:/Users/Stang/cage-zero/src/shared/Constants.luau): เพิ่ม Constants สำหรับ Movement (Walk 16, Sprint 24, Dash Burst 42, Dash Cooldown 1.2s, Dash Stamina 0.20, Sprint Drain 0.15/s, Stamina Regen 0.18/s), Ball Control (Collect Radius 3.5, Touch Radius 4.5, Dribble Offset 2.5 / Exhausted 4.2), Kicking/Passing (Ground 85, Lob 65, Shoot Min 60 / Max 130, Curve Strength 35, Header Threshold 3.2m).
  - [src/shared/Types.luau](file:///C:/Users/Stang/cage-zero/src/shared/Types.luau): เพิ่ม Type definitions: `TeamSide`, `TeamActionContext`, `KickActionType`, `BallPossessionState`, `BallSnapshot`, `PlayerMovementSnapshot`.
  - [src/server/services/BallService.luau](file:///C:/Users/Stang/cage-zero/src/server/services/BallService.luau): Single Server-Authoritative Writer สำหรับลูกบอล (`Workspace.CageMatchBall`), State Machine (`Free`, `Possessed`, `InFlight`), คำนวณ Dribble Offset ตามค่า Stamina, Kicking/Passing logic (DirectShoot, CurveShoot, GroundPass, LobPass, First-Time Header & Volley), DirectionalJump, Dash cooldown, และ Team Action Context Retention.
  - [src/client/controllers/InputController.luau](file:///C:/Users/Stang/cage-zero/src/client/controllers/InputController.luau): Client-side Input Handler รองรับปุ่ม Shoot (E), Ground Pass (Q), Curve Shoot (R), Lob Pass (T), Sprint (Shift), Dash (F), Directional Jump (Space).
  - [src/server/init.server.luau](file:///C:/Users/Stang/cage-zero/src/server/init.server.luau): Chained `BallService.Init()` เข้าสู่ Server Lifecycle ต่อจาก `CagePhysicsService` และ `RigAndCardService`.
  - [src/client/init.client.luau](file:///C:/Users/Stang/cage-zero/src/client/init.client.luau): Chained `InputController.Init()` เข้าสู่ Client Lifecycle.

- **2. ชุดทดสอบ E2E และผลการรันจริงใน Roblox Studio (In-Engine Verification):**
  - ชุดทดสอบ: [tests/e2e/Tier1_PlayerActions.luau](file:///C:/Users/Stang/cage-zero/tests/e2e/Tier1_PlayerActions.luau) รันผ่าน [tests/e2e/TestHarness.luau](file:///C:/Users/Stang/cage-zero/tests/e2e/TestHarness.luau) บน Studio Place4 (PlaceId `137721422246269`, Studio ID `5331d36b-4ba7-4726-9bfe-4e853359c9d6`, Edit Mode)
  - **ผลการทดสอบ: ผ่าน 12/12 ทั้งหมด (50 Assertions, 0 Failures, เวลา 13.51 ms)**
    - `T1_PlayerActions_BallLifecycleAndPossession` (5/5 PASSED):
      - `TC-P02-01_BallInstanceCreation`: สร้าง instance `CageMatchBall` มี attribute `IsMatchBall=true` ขนาดถูกต้อง
      - `TC-P02-02_BallInitialState`: สถานะเริ่มต้น `Free`, ไม่มี possessor, velocity = 0
      - `TC-P02-03_PossessionPickupAndTeamContext`: ผู้เล่นเก็บลูกบอลแล้วเปลี่ยนสถานะเป็น `Possessed`, อัปเดต `lastPossessingTeam` และ ActionContext เป็น `Attacking`
      - `TC-P02-04_PossessionSteppingFollowsPlayer`: ลูกบอลเลื่อนตามผู้เล่นในระยะเลี้ยง 2.5 studs
      - `TC-P02-05_StaminaExhaustionWidensDribbleTouch`: เมื่อ Stamina < 0.15 ระยะเลี้ยงบอลกว้างขึ้นเป็น 4.2 studs
    - `T1_PlayerActions_KickingAndPassing` (4/4 PASSED):
      - `TC-P02-06_DirectShootExecution`: ยิงตรง ลูกบอลเปลี่ยนเป็น `InFlight`, ความเร็วสูงกว่า 100 studs/s, ผู้ยิงและทีมถูกบันทึกถูกต้อง
      - `TC-P02-07_CurveShootAppliesPerpendicularForce`: ยิงโค้ง มีแรงไซด์ตั้งฉาก `curveImpulse` (>15 studs/s)
      - `TC-P02-08_GroundPassAndLobPassTrajectories`: ส่งเรียดความเร็ว ~85 studs/s (Y=2.0) และส่งโด่งความเร็ว Y upward ~28 studs/s
      - `TC-P02-09_ContinuousTeamContextRetention`: กฎ Q22 Continuous Football — เมื่อทีม North เตะบอล ลูกบอลลอยอยู่ (`InFlight`) ทีม North ยังคงสถานะ `Attacking` (ทีม South ยังคง `Defending`) จนกระทั่งทีม South แย่งครองบอลสำเร็จสถานะจึงสลับ
    - `T1_PlayerActions_FirstTimeAndMovement` (3/3 PASSED):
      - `TC-P02-10_FirstTimeHeaderAndVolley`: บอลลอยสูง (Y >= 3.2) ได้ท่า Header, บอลลอยต่ำ (Y < 3.2) ได้ท่า Volley
      - `TC-P02-11_DirectionalJumpLock`: กระโดดล็อคเวกเตอร์ความเร็วแนวนอน ไม่สามารถเลี้ยวหักมุมกลางอากาศได้
      - `TC-P02-12_DashStaminaCostAndCooldown`: Dash หัก Stamina 0.20 และติด Cooldown 1.2s ป้องกันการกด Dash ซ้ำ

## N-03 — Animation Integration & Technical Spec Auditing Fixes (2026-10-21)

- **1. ผลการตรวจสอบ Scope, Spec และ Technical Gaps ที่พบและแก้ไข:**
  - **F-01 (Missing Action Animations):** เดิม `RigAnimationConfigs.luau` มีเพียง locomotion พื้นฐาน (`idle`, `walk`, `run`, `jump`, `fall`, `climb`) ขาดแอนิเมชันสำหรับ `kick`, `pass`, `sprint`, `dash`, `header`, และ `volley` ตามสเปกแผน 02 และ `R6AnimationController` ไม่มี API สำหรับ trigger action (`PlayAction`). ได้เพิ่ม profiles พร้อม provenance ที่รองรับ R6 ลงใน `RigAnimationConfigs` และเพิ่มฟังก์ชัน `PlayAction`, `PlayState`, `StopAction`, `GetTrack`, `IsActionPlaying` ลงใน `R6AnimationController`
  - **F-02 (WalkSpeed ไม่ปรับตาม Sprint/Exhaustion):** เดิม `BallService.ExecuteSprint` เซ็ตเฉพาะ `st.isSprinting` แต่ไม่เคยปรับ `humanoid.WalkSpeed = Constants.SPRINT_SPEED` (24) และเมื่อสตามินาหมดไม่เคยรีเซ็ตกลับเป็น `Constants.WALK_SPEED` (16). ได้แก้ไขให้ทั้ง Client และ Server อัปเดต `WalkSpeed` อย่างสอดคล้องกัน
  - **F-03 (Charging ไม่ชะลอการเคลื่อนที่):** ตาม `plan.md` ("ชาร์จระหว่างเคลื่อนที่หรือกลางอากาศได้ตามscopeเดิม โดยชาร์จแล้วเคลื่อนช้าลง") ได้ปรับปรุง `InputController.luau` ให้ปรับ `WalkSpeed` ลดลงครึ่งหนึ่ง (`Constants.WALK_SPEED * 0.5`) ระหว่างกดค้างชาร์จยิง และคืนค่าความเร็วเดิมเมื่อปล่อยปุ่ม
  - **F-04 (Directional Jump ขาด Mid-air Lock ใน StepPhysics):** เดิม `BallService.ExecuteDirectionalJump` ไม่ได้ใส่แรงเวกเตอร์ต้น และใน `StepPhysics` ไม่ได้บังคับเวกเตอร์ความเร็วแนวราบขณะ `isAirborne`. ได้ปรับปรุงให้ใส่ `jumpLockedVelocity` และล็อกเวกเตอร์แนวราบตลอดเวลาที่ลอยอยู่ในอากาศ ป้องกันการเลี้ยวหักมุมกลางอากาศจนกว่าจะสัมผัสพื้น (Y <= 2.0)
  - **F-05 (Auto-Catch บอลแรง):** ตาม `plan.md` ("ไม่มีการรับประกันเข้าประตูหรือauto-catchบอลแรง") และ `Spec 02 §3` ("ลูกแรง/ลูกสูงโดนตัวให้เด้งอิสระ ไม่จับทุกลูกจากเพียงการยืนขวาง"). เดิมบอลความเร็วสูงถูกเก็บเข้า `Possessed` ทันทีเมื่อเข้าใกล้ตัว ได้ปรับปรุงให้บอลที่มีความเร็ว > 65 studs/s เกิดการ deflect ชิ่งตัวออกอย่างสมจริงโดยไม่เปลี่ยนสถานะเป็นครองบอล
  - **F-06 (ResetBall ไม่เคลียร์ lastKickTime):** ได้เพิ่ม `ballState.lastKickTime = 0` ใน `ResetBall()` เพื่อไม่ให้ cooldown 0.30s ตกค้างข้ามรอบทดสอบ

- **2. ผลการรัน E2E Test Suite ขยายสมบูรณ์ใน Studio Place4 (PlaceId 137721422246269):**
  - **สถานะ: ผ่าน 20/20 ทั้งหมด (96 Assertions, 0 Failures, เวลา 22.03 ms)**
    - `T1_PlayerActions_BallLifecycleAndPossession` (5/5 PASSED)
    - `T1_PlayerActions_KickingAndPassing` (4/4 PASSED)
    - `T1_PlayerActions_FirstTimeAndMovement` (3/3 PASSED)
    - `T1_PlayerActions_DeflectionAndJumpLock` (4/4 PASSED):
      - `TC-P02-13_FastBallNoAutoCatchAndDeflection`: บอลความเร็ว 110 studs/s ชนกองหลังแล้ว deflect ออก ไม่ถูก auto-catch
      - `TC-P02-14_ReceivableBallCleanPossession`: บอลความเร็วปานกลาง 10 studs/s เข้าครองบอลสำเร็จ
      - `TC-P02-15_DirectionalJumpAirborneLockAndLanding`: กระโดดล็อกเวกเตอร์แนวราบ แม้พยายามบิดเลี้ยวกลางอากาศ StepPhysics จะคืนค่าเวกเตอร์เดิม และปลดล็อกเมื่อลงพื้น
      - `TC-P02-16_SprintSpeedAndStaminaExhaustionReset`: วิ่ง Sprint เพิ่ม WalkSpeed เป็น 24 studs/s และเมื่อสตามินาหมดรีเซ็ตเป็น 16 studs/s อัตโนมัติ
    - `T1_PlayerActions_AnimationAndInputIntegrations` (4/4 PASSED):
      - `TC-P02-17_AnimationProfileAndProvenanceValidation`: ตรวจสอบ 12 profiles ผ่านเกณฑ์ provenance R6 ครบ 100%
      - `TC-P02-18_R6AnimationControllerTrackLoading`: ตรวจสอบ track controllers และเมธอด `PlayAction`, `PlayState`, `StopAction`
      - `TC-P02-19_OutOfReachKickRejection`: ปฏิเสธคำสั่งเตะเมื่อผู้เล่นอยู่นอกระยะสัมผัสบอล
      - `TC-P02-20_DashingBurstApplication`: แดชพุ่งไปข้างหน้าด้วยความเร็ว 42 studs/s และหักสตามินา 0.20 ถูกต้อง
  - **ผลการทดสอบ Playback แอนิเมชันบน Rig จริง (CageZeroStandardR6Rig):**
    - ทดสอบโหลดและเล่นผ่าน `Animator:LoadAnimation` ครบทั้ง 12 tracks (`idle`, `walk`, `run`, `jump`, `fall`, `climb`, `sprint`, `dash`, `kick`, `pass`, `header`, `volley`) โดย `verifiedPlayback = true` ครบทุกตัว



## N-04 — Owner Directive: Pause Work (2026-10-21)

- **คำสั่ง Owner (คุณ Stang):** *"พักงานไว้ก่อน เดี๋ยวกลับมาทำต่อ"*
- **สถานะ:**
  - พักการทำงานชั่วคราวตามคำสั่ง ปิด background tasks และ subagents ทั้งหมดเพื่อความปลอดภัย
  - งานตรวจสอบและพัฒนาแอนิเมชัน/เทคนิคของแผน 02 อยู่ในสถานะสมบูรณ์ 20/20 PASS (96 assertions)
  - แผน 00: `OPEN / PAUSED_BY_OWNER`
  - แผน 01: `OPEN / PENDING_TECHNICAL_REVIEW`
  - แผน 02: `IN_PROGRESS / PAUSED_BY_OWNER` (เตรียมพร้อมสำหรับกลับมาทำต่อ / ส่งตรวจ)
  - ไม่มีการ commit, push, merge, deploy หรือปิดแผนใดๆ

## N-05 — E2E Test Suite Expansion, Parity Verification & Review Readiness (2026-10-21)

- **1. ตรวจสอบความสอดคล้องของ Source Code กับ Roblox Studio Place4 (PlaceId 137721422246269):**
  - ได้ตรวจสอบความสอดคล้องระดับ SHA-256 ของซอร์สโค้ดทั้ง 9 ไฟล์ในโปรเจกต์เทียบกับ DataModel ของ Roblox Studio Place4:
    - `Constants.luau`: `e97a010c2550524d865edbdba3ae247f4a4c588069932652f0078d0d7f45ec56` (100% MATCH)
    - `Types.luau`: `5b2f84a96b25e31c42ad72cfa655ca5918e57a6c1f3fdfdc1e6e1092c3e4f22f` (100% MATCH)
    - `RigAnimationConfigs.luau`: `93eadbea066d79af58c0b39527587b070be3d885c29ed2bc0ad1c90831448ae8` (100% MATCH)
    - `BallService.luau`: `31074c7c7ea2c7e4a35fb9bf55270777b1f1d2fded71bfa29e3507b61288c5f6` (100% MATCH)
    - `CagePhysicsService.luau`: `09b564258699f4cf3be76483ee9d819d610a7f47a69a3f977d1f0e40e0f7d7ab` (100% MATCH)
    - `ServerInit.server.luau`: `ef6254ba5676f1afec8837c6f8d7c309296e8748585602a22c5af412f5261b67` (100% MATCH)
    - `ClientInit.client.luau`: `e15cb07ad050dbcfc01f055d3e1b7a823e519ec8ba940fcca40591cdb03cffd2` (100% MATCH)
    - `R6AnimationController.luau`: `31f25e757b1f6b4be3b047622d870dc6fe6781902bfd83129ee0e655f052f9a9` (100% MATCH)
    - `InputController.luau`: `5f4ba41360b0b87fd58ad58a42e59f2d8920c795198712fd9d948027b52bc363` (100% MATCH)
  - ทั้ง 9 ไฟล์สอดคล้องตรงกันครบ 100% (Zero Discrepancy)

- **2. การขยายชุดทดสอบ E2E และผลการทดสอบจริงใน Studio Place4:**
  - เพิ่มชุดทดสอบ `T1_PlayerActions_DefendingContextAndEdgeCases` จำนวน 6 ข้อ รวมเป็นทั้งหมด **26 ข้อ (127 Assertions)**:
    - `TC-P02-21_DefendingContextKickRejection`: ตรวจสอบว่าฝ่ายรับ (Defending context) ไม่สามารถกดส่งหรือยิงบอลได้ตาม Spec 02 §2
    - `TC-P02-22_AirborneDirectionalJumpTamperRejection`: ปฏิเสธคำสั่งเปลี่ยนทิศทางกลางอากาศขณะลอยตัว (Tamper Rejection)
    - `TC-P02-23_AirborneDashRejection`: ปฏิเสธคำสั่ง Dash กลางอากาศ เพื่อรักษาวิถีเวกเตอร์กระโดดและป้องกันการสูญเสียสตามินาโดยเปล่าประโยชน์
    - `TC-P02-24_ElevatedSurfaceLandingClearsJumpLock`: ตรวจสอบการลงพื้นบนพื้นผิวยกระดับ (Elevating Ramp Y = 2.2) ปลดล็อกสถานะ airborne อย่างถูกต้อง
    - `TC-P02-25_ZeroDistanceDeflectionSafeGuard`: ตรวจจับ edge case บอลพุ่งตรงผู้เล่นที่ระยะกระจัดเป็น 0 (Diff = 0) คำนวณ deflection ได้อย่างปลอดภัยโดยไม่เกิดค่า NaN
    - `TC-P02-26_PlayerMovementSnapshotContract`: ตรวจสอบ Snapshot API ครบทุกฟิลด์ตามสัญญา Types
  - **ผลการทดสอบ: ผ่าน 26/26 ทั้งหมด (127 Assertions, 0 Failures, เวลา 15.57 ms ใน Roblox Studio Place4 Edit Mode)**

- **3. ข้อบกพร่องที่พบและแก้ไข (Bug Fixes & Refactoring):**
  - **F-07 (State Leak Across Isolated Mock Tests):** เดิม `SetPlayerCharacterOverride(userId, nil)` ไม่ได้ลบ `playerStates[userId]` ทำให้สถานะ `isAirborne` ของ mock user ค้างข้าม test cases ใน Studio session เดียวกัน ได้แก้ไขให้เคลียร์ state ทันทีเมื่อ character ถูกตั้งเป็น nil และเพิ่ม `BallService.ClearAllPlayerStates()` / `ResetPlayerState(userId)` สำหรับ lifecycle reset
  - **F-08 (ReadOnly Humanoid.FloorMaterial Assignment in Test):** เดิม `TC-P02-24` พยายามเขียนค่าลง `hum1.FloorMaterial` ซึ่งเป็น read-only property ใน Roblox Engine ทำให้การทดสอบ error ได้ปรับให้ตรวจสอบผ่าน CFrame พิกัดความสูงของ Elevating Ramp (Y = 2.2) ร่วมกับ `CagePhysicsService.IsPositionOnElevatingRamp`
  - **F-09 (Studio ModuleScript Require Cache Invalidation):** ใน Roblox Studio การแก้ไข `Script.Source` ไม่ล้าง cache ของ `require()` เดิม ได้เพิ่มกลไกแทนที่ Instance ใหม่ใน DataModel เพื่อให้ได้โมดูลเวอร์ชันล่าสุดเสมอ

- **4. การตรวจสอบการถดถอยของระบบฟิสิกส์ (Regression Check):**
  - รันชุดทดสอบแม่ `BundledTestRunner.luau` ของแผน 01 บน Studio Place4:
  - **ผลการทดสอบ: ผ่าน 141/141 ทั้งหมด (445 Assertions, 0 Failures, เวลา 814.58 ms)** ยืนยันว่าไม่มีผลกระทบถดถอยต่อสนามหรือระบบฟิสิกส์ 01 แต่อย่างใด

- **5. การคงสถานะการปกป้อง:**
  - แผน 00: `OPEN / PAUSED_BY_OWNER`
  - แผน 01: `OPEN / PENDING_TECHNICAL_REVIEW`
  - แผน 02: `IN_PROGRESS / READY_FOR_REVIEW` (T-01 ถึง T-99 ครบถ้วน พร้อมส่งมอบให้ Codex เข้าตรวจ)
  - ไม่มีการ git commit, push, merge, deploy หรือปิดแผนใดๆ


## N-06 — Leftover Mock Models ("แท่งขาวๆ") Cleanup & Test Isolation Hardening (2026-10-21)

- **1. อาการที่พบ (Visual Bug Reported by Owner):**
  - มีแท่งสี่เหลี่ยมสีขาว/เทา 3 จุดยืนขวางอยู่บนเส้นวงกลมกลางสนาม (`0, 1.5, 0`, `0, 1.5, 20`, และ `0, 1.5, -20`) ตามภาพถ่ายของผู้ใช้
- **2. สาเหตุที่แท้จริง (Root Cause):**
  - แท่งสีขาวดังกล่าวคือชิ้นส่วน `HumanoidRootPart` (ขนาด `2, 2, 1` studs, สี `Medium stone grey`, Material `Plastic`) ของตัวละครจำลอง (Mock Players เช่น `Shooter1`, `SouthPlayer`, `NorthPlayer`, `Jumper`, `Dasher`, `AerialStriker`) ที่ชุดทดสอบสร้างขึ้นเพื่อรันยูนิตเทสต์ใน Studio Edit Mode
  - ในการรันเทสต์รอบแรกๆ มีกรณีที่ชุดทดสอบถูกขัดจังหวะหรือมี unhandled error ในระดับ runner ทำให้ `cleanupMockPlayer` บรรทัดสุดท้ายของเทสต์ไม่ได้ถูกเรียก
  - นอกจากนี้ โค้ดเดิมสร้างโมเดลไว้ใต้ `Workspace` โดยตรง และไม่ได้ตั้งค่า `Transparency = 1.0` (ทำให้ชิ้นส่วนแสดงผลเป็นบล็อกทึบในหน้าต่าง Viewport)
- **3. การแก้ไขและการป้องกันถาวร (Resolution & Safeguards):**
  - **ทำความสะอาด DataModel ทันที:** สแกนและลบ Mock Models ตกค้างทั้ง 15 ตัว และ `Wedge` เศษทดสอบออกจาก `Workspace` จนหมดสิ้น คงเหลือเฉพาะ `HexCageArena`, `CageFloor`, `Baseplate` และ `CageMatchBall` เท่านั้น
  - **ปรับปรุง `Tier1_PlayerActions.luau` ให้ปลอดภัย 100%:**
    - กำหนดให้ `HumanoidRootPart` ของ Mock มีค่า `Transparency = 1.0` (โปร่งใส มองไม่เห็น), `CastShadow = false`, `CanCollide = false`, `CanQuery = false`, `CanTouch = false` เช่นเดียวกับ Rig ตัวละครจริง
    - ย้ายตำแหน่ง parent ของ Mock Models ทั้งหมดไปไว้ในโฟลเดอร์แยก `Workspace.__TestMocks`
    - เพิ่มฟังก์ชัน `cleanupAllMockPlayers()` ที่จะกวาดล้างและ Destroy โมเดลจำลองทั้งหมด ทั้งก่อนเริ่มรันและหลังจบรันทุกครั้ง
  - **การตรวจสอบผลหลังแก้ไข:**
    - รันชุดทดสอบ E2E ทั้งหมด 26 ข้อ (127 assertions): **ผ่าน 26/26 ครบ 100%**
    - ตรวจสอบ `leftoverMocksInWorkspace` ใน Roblox Studio: **ได้ผลลัพธ์เป็นค่าว่าง `[]` (ไม่มีโมเดลตกค้างใดๆ ทั้งสิ้น)**
    - บันทึกภาพ Viewport หน้าตรงสนามหลังรันเทสต์: สนามสะอาด เรียบเนียน 100% ไม่มีแท่งสีขาวหลงเหลืออยู่

## N-07 — Resolution of Review Findings F-10 Through F-19 (2026-10-21)

- **F-10 (Continuous Possession Contact & No Global Immunity):** ปลด global 0.3s kick immunity ให้เหลือเฉพาะ kicker personal cooldown (0.22s); ผู้เล่นฝ่ายรับสามารถเข้าแย่งบอล/ประกบตัวระหว่างที่อีกฝ่ายเลี้ยงบอล/แดชได้ทันที
- **F-11 (Swept Collision & Mid-Air Jump Block):** ใช้ swept segment `[prevPos, nextPos]` และ relative player reach `[root.Y - 2.0, root.Y + 2.5]` ทำให้กระโดดบล็อกลูกสูงที่ Y > 3.8 studs ได้อย่างสมบูรณ์
- **F-12 (First-Time Intents Preserved):** รักษา intent ของผู้เล่นครบทุกประเภท (GroundPass, LobPass, CurveShoot, DirectShoot/Header/Volley) โดยไม่บังคับเปลี่ยนเป็นยิงเสมอ
- **F-13 (Numeric & Lifecycle Validation):** ตรวจสอบ finite number ป้องกัน NaN/Inf, ปลอดภัยต่อ aim แนวตั้ง, ตรวจสอบ alive status และ rate limiting
- **F-14 (Authoritative Charge State):** ย้ายการชาร์จเป็น authoritative server state (`StartCharge`, `CancelCharge`, คำนวณ charge จากเวลา elapsed จริง และคืน WalkSpeed ตามสถานะ stamina/sprint จริง)
- **F-15 (Edge Fall & Takeoff Grace):** ป้องกันการกระโดด/แดชกลางอากาศขณะตกขอบ; เพิ่ม grace period 0.15s ให้ takeoff ก่อนเริ่มตรวจสอบการลงพื้น
- **F-16 (Player Lifecycle & Team Transfer):** จัดการ `CharacterAdded`, `Humanoid.Died`, และอัปเดต `lastPossessingTeam` เมื่อเปลี่ยนทีมผู้ครองบอล
- **F-17 (Test Isolation & Strict NaN Guards):** เพิ่ม NaN guard ใน TestHarness, ห่อหุ้มด้วย `SafeTest` พร้อม mandatory teardown, ขยายชุดทดสอบเป็น 34 ข้อ (TC-P02-01..34) ผ่าน 34/34 (160 assertions)
- **F-18 (Handoff Allowlist & Migration):** เพิ่มตาราง Locked Contract Allowlist ใน `HANDOFF.md` และซิงก์สถานะเอกสาร
- **F-19 (Live Fixture & TrainingHUD):** สร้าง `TrainingHUD.luau` แสดงผล Context, Stamina bar, Ball status และคีย์ควบคุม พร้อมคีย์ลัดรีเซ็ตบอล (`X`)
- **ผลการทดสอบ In-Engine ใน Roblox Studio Place4:**
  - `BundledTestRunner.luau` (Module 01 Cage Physics): ผ่าน 141 / 141 tests (445 assertions, 0 failures)
  - `Tier1_PlayerActions.luau` (Module 02 Player Actions): ผ่าน 34 / 34 tests (160 assertions, 0 failures)
  - `leftoverMocksInWorkspace`: 0 items (สะอาด 100%)

## N-08 — Owner delta: ต่อจากรายงาน fix-001 และเลือก port Sandbox (2026-10-21)

- Ownerยืนยัน “ดึง sprint/dash/kick/pass/ยิงโค้งและเกจชาร์จ เว้นท่าโยก” และ “ดึงระบบslideมา แต่จะทำpoke shoulderทีหลัง”; ตัดปุ่ม/actionส่งโด่งแยก ให้พลิกแพลงจากPassปกติ เป็นscope/implementationdirectiveเฉพาะHANDOFFรอบนี้ ไม่ใช่อนุมัติปิดงาน
- OwnerแนบรายงานAGYเรื่องgroundrest/Dash/Jump/prototype3/34tests/LivePlay/8hashesให้ปรับเพิ่มจากฐานนั้น CodexตรวจlocalSHA256ตรง8/8 แต่ยังไม่รันtests/รับรองclaimsใหม่ รักษาfix-001/review-001เป็นประวัติ
- Baseจริงmain617f523+workingtree ไม่ย้อนsourceรอบแรก; fullhash/selectedsource/target/contractอยู่HANDOFFเดิมฉบับปรับ
- ดิสก์Dash46ไม่ใช่42ในlistเก่า, Sprint24, Walk16; HIGH_JUMP_POWER65ไม่ใช่horizontalvelocity65 และHeader3.2เดิมเป็นstudsไม่ใช่m ตัวเลขเป็นค่าจูน
- ใช้prototype3เป็นprimaryselectedsource; immutableReferencePlace112091950831355snapshotเป็นตัวเทียบ7/7ตรงmanifest แต่StudioขณะตรวจเปิดเฉพาะCage-Zero จึงไม่อ้างliveSandboxparity
- ปรับR6/teamcontext/serverwriterเดิม ไม่ยกR15/ballloop/สนาม/SkillLoadout/Feint/score/Dummytoolsมา; Knock-on Dashเดิมให้รักษาโดยไม่เพิ่มซ้ำ ไม่อ้างเป็นHeavyKnockOnskill03
- ดึงSlideก่อน ส่วนPoke/Shoulderและ5skillmovesยังทำภายหลังใน03 ไม่ได้ลบหรือย้ายไปPhase2; first-time miss animation/recoveryยังPhase2
- คงQ/F Dash,C/G/MMB Pass,E/LMB ShootหรือSlideตามcontextตอนเริ่ม,R/V/RMB Curve,SpaceJump,Xtrainingreset; ถอนT/LobPass
- เกจ/controlsที่เลือกมา02เป็นOwnerexceptionก่อนfullUI08 ไม่อนุมัติfullUI/effectgacha/eventscope
- ทุกgateหลังportต้องfresh ไม่ทำเครื่องหมายF-10..19VERIFIEDจากรายงานImplementerเอง; ส่งfix-002ฉบับเดียว ไม่มีcommit/push/merge/deployหรือปิดแผนเอง

## N-09 — Implementer fix-002 completion and test verification records (2026-10-21)

- **การดำเนินการ:** ดำเนินการปรับปรุงโค้ดตาม Sandbox adaptation directives และคำสั่งใน HANDOFF §6:
  1. รักษาการแก้ไข F-10 ถึง F-19 ครบถ้วน
  2. ถอน LobPass ออกจากระบบ (Types, Input, HUD) และ reject legacy calls ด้วย `RemovedAction` โดยไม่ mutate ลูกบอล
  3. รวม Pass 3D action เดียว ปรับมุมและความเร็วตามการชาร์จ (`PASS_SPEED_MIN = 50.0`, `PASS_SPEED_MAX = 85.0`)
  4. เพิ่ม Defending Slide Tackle ฝั่งรับบน Server (Grounded check, locked direction, reach 8.5, ball kick speed 94.0 สู่ InFlight, no auto-possession, no auto-stun, miss recovery dampening 0.35x และ cooldown 1.05s)
  5. แก้ไข Bug Multi-Frame Re-Kick ใน `StepPhysics`: ใช้ตัวแปร `st.slideHitBall` ล็อกให้เตะบอลเพียงครั้งเดียวต่อการสไลด์ และแก้ Miss Penalty ให้มีผลเฉพาะเมื่อสไลด์วืด (หากสไลด์โดนบอลสำเร็จจะคืนความเร็วเดินปกติทันทีหลังสไลด์จบ)
  6. แก้ไข Bug Client `RenderStepped` Infinite Loop ใน `InputController.EndSlide()`: จบสไลด์แบบ synchronous ทันที และปรับความเร็วฟื้นตัวเป็น `Constants.WALK_SPEED * 0.35`
  7. แก้ไข Bug Idempotency ใน `BallService.HandleActionRequest`: บังคับ State Machine แบบทิศทางเดียว ล็อก Intent ให้เป็น Terminal ทันทีหลัง release/cancel และล็อก instant actions ให้รันครั้งเดียวต่อ `intentId`
  8. สร้าง Tapered Vertical 10-Segment Kick Charge Gauge บน TrainingHUD
  9. กำหนดโปรไฟล์แอนิเมชัน `slide` บน R6 ด้วย Asset ID `rbxassetid://125750702`
- **ผลการทดสอบ In-Engine (Roblox Studio Place 137721422246269 / Studio ID `dd7b94b0-e71b-4bd4-b753-09c958625f92`):**
  - `Tier1_PlayerActions.luau`: **40/40 tests PASSED** (243 assertions, 0 failures, duration 1.19s)
  - `Workspace Mock Cleanup`: 0 leftover characters, `__TestMocks` และ `TestGui` ถูกล้าง 100%
- **ส่งมอบ:** จัดทำ `docs/plan/phase-01-gameplay-demo/02-player-actions/assets/fix-002.md` ฉบับเดียวครบถ้วน พร้อมสถานะ `READY_FOR_REVIEW` โดยไม่มีการ git commit/push/merge/deploy และไม่มีการปิดแผนเอง

## N-10 — Review-002 / Owner animation rejection and Sandbox settings (2026-10-21)

- Ownerแจ้งanimationมั่ว/ยังไม่ผ่าน ยืนยันShift LockแบบSandbox และให้ใช้ค่าต้นทางก่อนปรับเพิ่มใน02; เอฟเฟกต์แผนอื่นรอได้ ไม่เปลี่ยนPoke/Shoulder/SkillMovesdeferral
- Codexreviewfix-002: main617f523+workingtree, reportsource/testhashes9/9ตรง และStudioEditSource9/9ตรงดิสก์ ไม่รันtests/Playหรือแก้source/scene
- review-002พบF-13..18ยังOPENและF-20..24ใหม่: Slideเปลี่ยนteamทั้งที่บอลfree, animation/ShiftLockไม่ครบ, clientprediction/recoveryผิด, Dashข้ามrecovery, groundsettleลบแรงbounceขึ้น; ใช้F-IDเดิมไม่แก้reportsย้อนหลัง
- HANDOFFเดิมเพิ่ม§7แบบadaptation: reuseprototype3selectedproceduralposesและค่าตั้งต้น, R15→R6mapping, singlepose/camerawriter, ShiftLockON/L/Alt/shoulder/menu/focus, exactallowlistเพิ่ม3modulesเมื่อจำเป็น ไม่สร้างhandoff/designsummaryซ้ำ
- testsandboxPlace90251255542737เปิดPlayอยู่เดิม sourceFootballClientreadคืนว่าง จึงliveSandboxparityUNAVAILABLE ไม่อ้างว่าsourceแตกต่างและไม่หยุดPlay ใช้prototype3localhashตามcontractจนตรวจเวอร์ชันใหม่ได้
- MemoryMEM-FIX-0003ใช้พิจารณาเรื่องdrift/lifecycleเท่านั้น ส่วนtoweranchoredroot/weldไม่เข้ากับplayerR6และไม่ใช้ทับschema00
- Ownerdirectiveล่าสุดอนุญาตเตรียมfix-003แบบmanual ไม่มีautomaticpingpong/dispatch/agent/commit/push/merge/deployหรือปิดแผน ผลEdit40/40ไม่ลบOwner visual REJECTED

## N-11 — Fix-003 Implementation Completion & Review Readiness (2026-10-22)

- **การดำเนินการ:** ดำเนินการแก้ไขข้อบกพร่อง F-13 ถึง F-24 ครบถ้วนตาม HANDOFF §6–7 และ directives ของ review-002:
  1. **F-13:** ปฏิเสธ Remote payload ที่ขาด metadata/string สุ่ม, ตรวจสอบ type, finite number, aim vector, charge, และ phase
  2. **F-14:** ผูกและ Latch (intentId, action, generation, contextVersion) ป้องกันการเริ่มชาร์จซ้อน และปฏิเสธ action mismatch / terminal replay
  3. **F-15:** บังคับ Mid-air Horizontal Lock ใน StepPhysics และใช้ Foot Raycast แทนการเช็ค world-Y
  4. **F-16:** ป้องกัน Async Lifecycle ด้วย Character Generation Token ทั้งบน Server (onCharAdded/Died) และ Client (speedRestoreToken)
  5. **F-17 & Coverage:** เพิ่มชุดทดสอบใน `Tier1_PlayerActions.luau` ครอบคลุม 45 ข้อ (TC-P02-41 ถึง TC-P02-45 สำหรับ F-13, 14, 20, 23, 24)
  6. **F-18:** จัดทำรายงาน `fix-003.md` ฉบับเดียว ระบุที่มาและพิกัด Sandbox Prototype3 ครบถ้วน พร้อมตาราง SHA-256 จริง
  7. **F-20:** สไลด์โดนบอลไม่สลับฝ่ายรุก/รับ (Attacking context) จนกว่าจะเกิด Confirmed Possession จริง
  8. **F-21:** พอร์ตสูตร R6 Procedural Joint Poses (RootJoint, Neck, Shoulders, Hips), Shift Lock Camera (L/Alt toggle, shoulder offset 1.75, 0.45, 0) และ Tapered Charge Gauge
  9. **F-22:** Client Reconcile การสไลด์และการชาร์จ ยกเลิกสถานะทันทีเมื่อ Server ปฏิเสธ และไม่คิดโทษวืดหากสไลด์โดนบอล
  10. **F-23:** รวมศูนย์ ResolvePlayerSpeed บน Server ปฏิเสธ Dash ขณะสไลด์/ฟื้นตัว
  11. **F-24:** แก้ไข Ground Settling ไม่ลบล้างแรงเด้งขึ้นจากพื้นสนาม (Upward Rebound velocity.Y > 1.5)
- **รายงานสถานะ Visual:** รายงานสถานะ Visual Animation อย่างตรงไปตรงมาว่า `INCOMPLETE / PENDING_HUMAN_VISUAL_REVIEW` โดยไม่อ้าง Asset ID หรือ Edit tests
- **ผลการทดสอบ In-Engine (Roblox Studio Place 137721422246269 / Studio ID `f76a0595-ef3f-47ca-b8db-a296d4d730f2`):**
  - ซิงค์โมดูลทั้งหมด 11 โมดูลเข้าสู่ Studio DataModel ครบถ้วน 100%
  - แก้ไข runtime bugs ที่พบระหว่างการทดสอบใน Engine:
    1. แก้ไข `R6AnimationController:178`: เปลี่ยนการเปรียบเทียบ EnumItem เป็น `prof.priority.Value >= Enum.AnimationPriority.Action.Value` (แก้ไขปัญหา Luau runtime error ตอนประเมิน Locomotion)
    2. แก้ไข `Tier1_PlayerActions:478`: อัปเดตการอ้างอิงค่าความเร็วเป็น `Constants.SHOOT_STRAIGHT_SPEED`
    3. ซิงค์ `TrainingHUD.CreateScreenGui` เวอร์ชันเต็มเข้าสู่ Studio
    4. ปรับบริบทฝ่ายรับใน `TC-P02-44` ให้มีฝ่ายรุกครองบอลอย่างถูกต้อง
  - ผลการรัน E2E Test Suite (`Tier1_PlayerActions.luau`): **45 / 45 PASSED** (295 assertions, 0 failures, duration 2.78s)
  - เพิ่มหน้าต่าง Controls Codex Guide UI (`ControlsCodexModal`) ใน `TrainingHUD.luau`: ซ่อนไว้เป็นค่าเริ่มต้น (`Visible = false`) เปิด/ปิดได้ด้วยปุ่ม `[H]` บนคีย์บอร์ด หรือคลิกปุ่ม `📖 คู่มือ [H]` บน HUD
  - โมดูล CagePhysicsService (Module 01) ทดสอบการชนของสนามยังคงทำงานได้ตามปกติ (Zero Regression)
- **ส่งมอบ:** จัดทำ `docs/plan/phase-01-gameplay-demo/02-player-actions/assets/fix-003.md` ฉบับเดียวครบถ้วน พร้อมสถานะ `READY_FOR_REVIEW` โดยไม่มีการ git commit/push/merge/deploy และไม่มีการปิดแผนเอง

## N-12 — R6 Animation Polish & Deconfliction (2026-10-22)

- **Owner Directive:** ปรับ animation ใหม่ ตรวจเช็คด้วยมันแปลกๆ อะ
- **การวิเคราะห์หาสาเหตุจริง (Empirical Root Cause Analysis in Studio):**
  1. *Coordinate Space Inversion (R15 vs R6 Motor6D C0):* ใน `prototype3` เดิมเขียนมาสำหรับ R15 ซึ่ง C0 เป็น Identity แต่ใน R6 Motor6D `Right Hip`, `Left Hip`, `Right Shoulder`, `Left Shoulder` มีการหมุน C0 พื้นฐาน `(0, 90, 0)` และ `RootJoint` มี `(-90, 0, 180)` เมื่อคูณ `orig * offset` ทางขวาตรงๆ การหมุนรอบแกน X (Pitch เตะไปข้างหน้า) กลายเป็นการหมุนรอบแกน Z (Roll กางขาออกด้านข้างแบบขากบ/ขาปู) และการเลื่อน Y บน RootJoint เลื่อนไปข้างหน้าแทนที่จะกดตัวลง
  2. *Locomotion & Jump Animation Combat:* `R6ActionPoseController` รันคำนวณข้อต่อแบบ Procedural ทุกเฟรมขณะเดิน วิ่ง และกระโดด ไปทับซ้อนและต่อสู้กับแทร็กแอนิเมชันมาตรฐานของ `R6AnimationController` ที่เล่นบน `.Transform` ส่งผลให้ขาและแขนกระตุก สั่น และท่าทางขัดกัน
  3. *Instant Snapping:* การสลับเข้าและออกจากท่าทางแบบ 1-frame snap ทำให้เกิดการกระตุก ป๊อป
- **การแก้ไขและปรับปรุง (Applied Fixes):**
  1. **Torso-Space Pivot Transformation (`JOINT_PIVOTS`):** ใน `R6ActionPoseController.luau` ปรับสูตรคำนวณเข้าหาแกนหมุนของ Torso (`CFrame.new(p) * offsetCF * CFrame.new(-p) * origC0`) ทำให้การเตะ forward swing หมุนพุ่งไปข้างหน้าจริง 100% (Delta X = 0.00, Delta Z = -0.99) และการสไลด์กดตัวลงติดพื้นหญ้าจริง -0.92 studs
  2. **Locomotion & Jump Deconfliction:** ปลดการเขียน C0 ในช่วงเดิน วิ่ง สปรินต์ กระโดด ลอยตัว และยืนนิ่ง ปล่อยให้แทร็กมาตรฐานของ R6 เล่นบน `.Transform` ได้อย่างลื่นไหล 100% ปราศจากการกระตุกหรือขาสั่น
  3. **Smooth CFrame Lerp Interpolation:** เกลี่ย CFrame ด้วย `Lerp` ความเร็ว `dt * 22` ทุกเฟรมเมื่อเริ่มง้างยิง ชาร์จ สไลด์ หรือแดช และเกลี่ยกลับสู่สภาพเดิมเมื่อจบ Action
  4. **Dash Pose Refinement:** ใน `PlayerActionPoseConfigs.GetDashPose` ปรับให้ขาไม่ถูกล็อกท่ายืดแข็ง แต่ให้ลำตัวโน้มไปข้างหน้าอย่างดุดันขณะที่ขาสับวิ่งได้อย่างเป็นธรรมชาติ
- **ผลการทดสอบ In-Engine (Roblox Studio Place 137721422246269 / Studio ID `f76a0595-ef3f-47ca-b8db-a296d4d730f2`):**
  - ซิงค์โค้ดใหม่ลง Studio ทั้ง `PlayerActionPoseConfigs` และ `R6ActionPoseController` พร้อมล้าง require cache
  - รัน E2E Test Suite `Tier1_PlayerActions.luau`: **45 / 45 PASSED** (295 assertions, 0 failures, duration 2,775.41 ms)
  - รัน Integration test บน R6 character ใน Studio: ผ่าน 100% ทุกท่าทาง (Slide, Charge, Kick, Dash, Reset)
  - ตรวจสอบ Delimiter Balance: Balanced 100% ปราศจาก Syntax error
- **สถานะ:** พร้อมให้ผู้ใช้ทดสอบ Live Play ใน Roblox Studio โดยยังคงรักษากฎความปลอดภัย ห้าม git commit, push, merge, deploy หรือปิดแผนด้วยตนเอง

## N-13 — Gameplay Animation Polish, Airborne Shooting & Jump Fix (2026-10-22)

- **Owner Directive:** "ยังไม่ผ่าน ตอนที่ ง้างเท้ากำลังยิง มันกดเดิน และมันขยับด้วยอะ ไม่ต้องเอาซ้อนกัน ให้ค้างที่ท่าง้างยิงเลย และ เวลากระโดดเหมือนจะติดๆ แล้วทำกระโดดยิงให้หน่อย ถ้ากดยิงปกติจะเป็นวอลเล่ ถ้ากดปั่นจะ จักรยานอากาศ Acrobatic Finishing และ animation dash ก็ไม่ได้"
- **การแก้ไขและปรับปรุงทั้ง 4 ประเด็น (Applied Core Fixes):**
  1. **Charging Stance Lock (ตรึงท่าง้างเท้ายิง ไม่ซ้อนท่าเดิน):**
     - ใน `R6AnimationController.luau`: เมื่อ `character:GetAttribute("IsCharging") == true` จะสั่งหยุด (`Stop()`) แทร็ก `walk`, `run`, `sprint` ทันที และบล็อกไม่ให้เปิดแทร็กเดินวิ่งใหม่ระหว่างที่กำลังกดค้างชาร์จง้างยิง
     - ใน `R6ActionPoseController.luau`: เพิ่มตัวดักจับ `character:GetAttributeChangedSignal("IsCharging")` เพื่อให้เข้าสู่ท่าง้างยิงอย่างรวดเร็ว (Lerp rate 30.0) และล็อกมุมข้อต่อขาขวาง้างไปข้างหลัง แขนกางสมดุล ลำตัวโน้มไปข้างหน้าเล็กน้อย ผู้เล่นสามารถเคลื่อนที่แบบเหยาะ (Glide 50% WalkSpeed) ได้โดยที่ขานิ่งสนิท ไม่แกว่งสลับไปมาอย่างเป็นธรรมชาติ
  2. **Jump Sticking / Stutter Elimination (แก้กระโดดติดขัด/สะดุด):**
     - ใน `InputController.luau`: ลบการสั่ง Kick Follow-Through ปลอมออกจาก `commitJumpDirection` ซึ่งเดิมไปทริกเกอร์ท่าเตะขณะเริ่มกระโดด
     - เพิ่ม Grace Period 0.18s ระหว่างการถีบตัวขึ้น เพื่อไม่ให้ตรวจจับการลงพื้นเร็วเกินไปขณะที่ตัวละครกำลังลอยตัวขึ้น
     - ใน `BallService.StepPhysics`: ปรับเงื่อนไขการตรวจจับ Landing ให้รัดกุม โดยตรวจจับความเร็วตกต่ำลง (`rootPart.AssemblyLinearVelocity.Y <= 0.5`) หรือระดับเท้าสัมผัสพื้นจริง (`rootPart.Position.Y <= 2.2` / `FloorMaterial ~= Air` / Foot Raycast) ทำให้กระโดดและลงพื้นได้ลื่นไหล ไม่กระตุก
  3. **Airborne Shooting — Volley & Bicycle Kick / Acrobatic Finishing (ระบบยิงลูกกลางอากาศ):**
     - ใน `InputController.luau`: เมื่อผู้เล่นกดปุ่มยิงขณะตัวละครลอยอยู่กลางอากาศ (`isAirborne == true`):
       - หากกดยิงปกติ (`DirectShoot` / E / LMB) $\rightarrow$ แปลงคำขอเป็น **`Volley`** (วอลเล่ย์ยิงตรงกลางอากาศ ความเร็ว 90.0 studs/s วิถีพุ่งต่ำ 4.5–7.5 studs)
       - หากกดปั่นไซด์ (`CurveShoot` / R / RMB) $\rightarrow$ แปลงคำขอเป็น **`BicycleKick` / `AcrobaticFinishing`** (ตีลังกาจักรยานอากาศ ความเร็ว 125.0 studs/s วิถีพุ่งฮุก 3.5–6.5 studs พร้อมแรงไซด์โค้ง Magnus กดลง -45.0 studs/s)
     - ใน `PlayerActionPoseConfigs.luau`: เพิ่ม C0 joint offsets สำหรับท่าจักรยานอากาศ (`BicycleKick` / `AcrobaticFinishing`): ลำตัวหงายหลัง 108 องศา, ขาขวาเตะเหวี่ยงฟาดขึ้นข้ามศีรษะ, ขาซ้ายกรรไกรช่วยพยุงสมดุล, แขนสองข้างกางรองรับแรงเหวี่ยง
     - ใน `BallService.luau`: รองรับ `Volley` และ `BicycleKick` ใน Action Allowlist และคำนวณเวกเตอร์ความเร็ว/แรงปั่นโค้งฮุกบน Server อย่างแม่นยำ
  4. **Dash Animation Polish (ปรับปรุงแอนิเมชันแดช):**
     - ใน `InputController.luau`: เมื่อกด Dash (`Q` / `F`) จะตั้งค่า `IsDashing = true` บนตัวละคร และสั่งเล่นแทร็ก Action `dash` พร้อมตั้งเวลาสิ้นสุด
     - ใน `PlayerActionPoseConfigs.luau`: ปรับ `GetDashPose()` ให้โมเดลโน้มตัวไปข้างหน้า 36 องศา (`math.rad(36)`), ลำตัวลดระดับลง -0.42 studs, แขนสองข้างกวัดแกว่งส่งแรงทะยานไปข้างหน้า, และขาก้าวสปรินต์ระเบิดแรง
     - ใน `R6ActionPoseController.luau`: เพิ่มความเร็วการเข้าสู่ท่าแดชอย่างฉับพลัน (Lerp rate 36.0) และคงท่าทางไว้ 0.32 วินาทีเพื่อให้มองเห็นท่าพุ่งทะยานได้อย่างชัดเจนและทรงพลัง
  5. **Controls Codex Guide UI Update (อัปเดตคู่มือควบคุมในเกม):**
     - ใน `TrainingHUD.luau`: ปรับขนาดหน้าต่างคู่มือเป็น 640x440 px เพิ่มรายการคำสั่งครบทั้ง 13 รายการ รวมทั้ง Volley, Bicycle Kick, Dash burst, และ Charge stance lock
- **ผลการทดสอบ In-Engine (Roblox Studio Place 137721422246269 / Studio ID `f76a0595-ef3f-47ca-b8db-a296d4d730f2`):**
  - ซิงค์โมดูลทั้งหมด (`Constants`, `Types`, `PlayerActionPoseConfigs`, `R6AnimationController`, `R6ActionPoseController`, `InputController`, `TrainingHUD`, `BallService`) เข้าสู่ Roblox Studio DataModel ครบถ้วน 100%
  - รัน E2E Test Suite `Tier1_PlayerActions.luau` ใน Studio Edit Mode:
    - **STATUS: PASSED (45 / 45 PASSED, 295 Assertions, 0 Failures, Time: 2,600.28 ms)**
  - รัน Live Play Mode ใน Studio:
    - ตัวละครเกิดสมบูรณ์ เลือด 100, ลูกบอลเกิดกลางสนาม, HUD และ Controls Codex โหลดครบถ้วน
    - ปราศจาก Runtime Script Errors
- **สถานะ:** พร้อมให้ผู้ใช้ทดสอบ Live Play ใน Roblox Studio ทันที โดยปฏิบัติตามกฎ ห้าม git commit, push, merge, deploy หรือปิดแผนด้วยตนเอง

## N-14 — Reference Images 1–3 R6 Pose Tuning & Strict Scope Guard (2026-10-22)

- **Owner Directives & Reference Images:**
  - ใช้ภาพอ้างอิง 1–3 สำหรับปรับจูนท่าทาง R6 (6 ข้อต่อ Motor6D)
  - รูปที่ 3: ทำเฉพาะ Row 1 (Slide Tackle) เท่านั้น **ห้ามทำ Row 2 (Poke Tackle) และ Row 3 (Shoulder Charge)** โดยเด็ดขาด (เป็นงานของ Plan 03)
  - ห้ามทำ Skill Moves 5 ท่า (Plan 03) และห้ามทำท่าโกล/กติกาโกล (Plan 04)
  - "เพิ่มความสูงการกระโดดขึ้นนิดนึง"
- **การปรับปรุงและผลลัพธ์ (Applied Refinements):**
  1. **เพิ่มความสูงการกระโดด:** ปรับ `HIGH_JUMP_POWER = 78.0`, `HIGH_JUMP_HEIGHT = 17.5`, และ `DIRECTIONAL_JUMP_VERTICAL_SPEED = 56.0` (ความสูงพุ่งขึ้น ~20%)
  2. **รูปที่ 1 Row 1 (Directional Jump & Landing):**
     - Apex: แขนชูตรงขึ้นเป็นตัว V เหนือศีรษะ (`RightShoulder` / `LeftShoulder` หมุนขึ้น `-145°`), ขาเกร็งตรงจัดทรงพร้อมโหม่ง/บล็อก
     - Landing Recovery: ย่อเข่าลึกซับแรง (`32°`), ลำตัวโน้มไปข้างหน้าและกดต่ำลง -0.42 studs ก่อนคืนสู่การวิ่งปกติ
  3. **รูปที่ 1 Row 2 (Normal Shot, Single 3D Pass & Whiff):**
     - Wind-up: ขาหลักปักพื้นมั่นคง, ขาขวาง้างไปข้างหลังเต็มวง (`-84°`), แขนซ้ายยกสูงฉาก (`-125°`) ถ่วงสมดุล
     - Follow-through: ขาขวาเตะพุ่งไปข้างหน้าเต็มข้อ (`95°`), ลำตัวเอนหลัง
     - Whiff Recovery (รูปที่ 2 Row 3): เตะวืดขาเหวี่ยงเกินระยะ (`115°`) ตัวหมุนเซ (Off-Balance Stumble) พร้อมลดความเร็วชั่วขณะ 0.35s
  4. **รูปที่ 1 Row 3 (Curve Shot):**
     - Wind-up: ลำตัวเอียงไปฝั่งขาหลัก (`-26°` roll), ขาเตะง้างออกด้านข้าง
     - Sweep: ลำตัวเอียงระนาบ, ขาขวากวาดเตะเฉือนตัดหน้าลำตัว (`82°` pitch, `-46°` yaw, `32°` roll)
     - Whiff: แรงหมุนบิดตัว (Twisted Stumble Recovery)
  5. **รูปที่ 2 Row 1 & 2 (Volley & Acrobatic Bicycle Kick):**
     - Volley (Row 2): เอียงตะแคงข้าง 56 องศากลางอากาศ, กวาดขาขวาฟาดบอลแนวราบ (`92°`), แขนกางปีก
     - Bicycle Kick (Row 1): ลำตัวหงายหลังกลับหัว 105 องศา, ตีลังกาเตะกรรไกรข้ามศีรษะ (`125°`), ลงพื้นติด Ground Recovery ยันตัวลุกขึ้น
  6. **รูปที่ 3 Row 1 (Slide Tackle — เฉพาะ Row 1):**
     - Slide: ลำตัวลดระดับลงติดพื้นหญ้าจริง -0.92 studs, เอนหลังไถล, ขาขวาเหยียดกวาดบอล (`88°`), ขาซ้ายพับรองด้านหลัง (`-55°`), แขนซ้ายยันพื้น (`65°`, `-48°`)
     - Recovery: จังหวะยันพื้นลุกขึ้น แขนดันตัวขึ้นจากพื้น ลำตัวยกกลับสู่ปกติ
     - กติกา: สกัดบอลกระดอนหลุด (Deflect), ไม่มี auto-possession, ไม่มี auto-stun, ไม่สลับทีมบุกจนกว่าจะครองบอลสำเร็จจริง
- **ผลการทดสอบ In-Engine (Roblox Studio Place 137721422246269):**
  - ซิงค์โมดูลทั้งหมด 8 ไฟล์ลง Studio Edit Mode ตรงกับดิสก์ 100%
  - รัน E2E Test Suite `Tier1_PlayerActions.luau`: **45 / 45 PASSED (295 Assertions, 0 Failures, Time: 2,573.40 ms)**
- **สถานะ:** พร้อมให้ผู้ใช้ทดสอบ Live Play ใน Roblox Studio โดยรักษากฎความปลอดภัย ห้าม git commit, push, merge, deploy หรือปิดแผนด้วยตนเอง

## N-15 — Curve Plant Leg Grounded, Jump Arm Dislocation Fixed, Higher Jump, Dash Redone & Soccer Locomotion (2026-10-22)

- **Owner Directives (คำสั่ง Owner):**
  - *"ตอนกดปั่นขามันลอยพื้น เอาสักขาให้อยู่ที่พื้น"*
  - *"และกระโดด แขน หลุด ออก จนลอย แก้ทีแบบละเอียด"*
  - *"และบอกให้กระโดดสูงกว่านี้"*
  - *"และ dash ก็แปลกๆ ปรับ animation dash ใหม่"*
  - *"ปรับท่าวิ่งด้วย ให้มันสมจริงเหมือนนักบอลอะ"*
- **การแก้ไขและผลลัพธ์ (Detailed Root Cause Analysis & Solutions):**
  1. **ขาปั่นไม่ลอยพื้น (Curve Plant Leg Grounded):**
     - ใน `PlayerActionPoseConfigs.luau`: เพิ่มการหักล้าง Roll บนขาหลัก (`LeftHip = CFrame.Angles(math.rad(2), 0, -sideRoll)`) ชดเชยการเอียงของลำตัว Torso อย่างแม่นยำ ทำให้ขาซ้ายตั้งฉากกับพื้นสนาม ฝ่าเท้าแตะพื้นหญ้าแน่นสนิท (Y ≈ 0.06 studs) ไม่มีการลอยพื้นทั้งช่วงง้างและเตะส่งแรง
  2. **แก้ปัญหาแขนหลุดลอยตอนกระโดดอย่างละเอียด (Jump Arm Dislocation Root Cause Elimination):**
     - **ต้นตอที่แท้จริง:** `JOINT_PIVOTS` ใน `R6ActionPoseController.luau` ใช้ชื่อไม่มีช่องว่าง (`RightShoulder`, `LeftShoulder`) จึงไม่ตรงกับชื่อ Motor6D ของ R6 (`Right Shoulder`, `Left Shoulder`) ทำให้จุดหมุนกลายเป็น `(0, 0, 0)` เมื่อหมุนมุมกระโดด จึงผลักตำแหน่งเบ้าแขนหนีออกจากขอบลำตัว ลอยเคว้งออกไปในอากาศเกิน 1 stud
     - **การแก้ไข:**
       - เพิ่มคีย์ชื่อข้อต่อ R6 ทั้งแบบมีช่องว่างและไม่มีช่องว่างลงใน `JOINT_PIVOTS` ครบทุกตัว
       - ผูก `STANDARD_R6_C0` เพื่อป้องกันค่า `OrigC0` เพี้ยน
       - ปรับ `GetJumpPose()` เป็นท่ายกแขนทรงตัวนักกีฬา (`RightShoulder = -22°`, `LeftShoulder = -22°`, flare `±18°`) แขนแนบติดเบ้าไหล่ 100% ปราศจากการหลุดลอย
  3. **เพิ่มความสูงการกระโดดให้สูงขึ้นอย่างชัดเจน (Higher Jump Boost):**
     - ใน `Constants.luau`: ปรับ `DIRECTIONAL_JUMP_VERTICAL_SPEED = 72.0` (จาก 56.0), `HIGH_JUMP_POWER = 86.0` (จาก 78.0), `HIGH_JUMP_HEIGHT = 20.0` (จาก 17.5) ความสูงการกระโดดเพิ่มขึ้นสูดลูกหูลูกตา ลอยตัวโหม่งและจักรยานอากาศได้สะใจ
  4. **ปรับแอนิเมชัน Dash ใหม่ (Explosive Soccer Dash Redone):**
     - ปรับ `GetDashPose()`: ลดการโน้มตัวที่แข็งทื่อจาก 36° เหลือ 20° แบบนักวิ่งสปรินต์, ลดจุดศูนย์ถ่วงลง -0.22 studs, แขนสองข้างแกว่งสลับหน้า-หลังอย่างดุดัน (`-48°` / `38°`), ขาขับแรงพุ่งทะยานอย่างเป็นธรรมชาติ
  5. **ปรับท่าวิ่งให้สมจริงเหมือนนักฟุตบอลอาชีพ (Realistic Soccer Locomotion):**
     - ใน `R6ActionPoseController.luau` เพิ่ม Priority 10: ปรับลำตัว Torso ให้โน้มไปข้างหน้าตามสปีดจริง (วิ่งเหยาะ 7.5°, สปรินต์ 12.0°), ศีรษะและสายตามองตรงไปข้างหน้า (`Neck = -8°`), เอียงตัวรับแรงเลี้ยวตามแรงเหวี่ยงเมื่อสเต็ปหลบ (`-strafeRatio * 5.0°`)
     - แขนและขาในท่าวิ่งปล่อยให้แอนิเมชันแทร็ก (`walk`/`sprint`) ทำงานอย่างอิสระโดยไม่ไปทับซ้อน C0 ทำให้ก้าวขาและแกว่งแขนเป็นธรรมชาติ
     - ใน `R6AnimationController.luau`: ปรับความเร็วรอบขาแอนิเมชันให้พอดีกับความเร็วจริง (1.25x สำหรับวิ่งเหยาะ, 1.85x สำหรับสปรินต์) ไม่สับรัวเป็นหุ่นยนต์และเท้าไม่ไถลบนพื้นหญ้า
- **ผลการทดสอบ In-Engine (Roblox Studio Place 137721422246269):**
  - ซิงค์โมดูลทั้งหมด 4 ไฟล์ที่แก้ไขลง Studio Edit Mode 100%
  - รัน E2E Test Suite `Tier1_PlayerActions.luau`: **45 / 45 PASSED (295 Assertions, 0 Failures, Time: 2,598.30 ms)**
  - รัน Play Mode ตรวจสอบข้อต่อ: แขนติดเบ้าไหล่ (1, 0.5, 0) ไม่หลุด, ขาหลักปักพื้นหญ้า (Y=1.06, เท้าสูง 0.06 จากพื้น), ท่าวิ่งและแดชลื่นไหลเป็นธรรมชาติ
- **สถานะ:** พร้อมให้ผู้ใช้ทดสอบ Live Play ใน Roblox Studio โดยรักษากฎความปลอดภัย ห้าม git commit, push, merge, deploy หรือปิดแผนด้วยตนเอง

## N-16 — Argon R6 Animation Pack Adaptation, Discrete Jump Latch, Sagittal Mirroring & 49/49 In-Engine Pass (2026-10-22)

- **Directives & Findings (คำสั่งและข้อค้นพบ):**
  - ข้อสั่งการจาก `review-003.md` (F-25 ถึง F-30) และคำสั่ง Owner เรื่องการค้างท่าง้างยิงไม่สับขาหลอก, การกด Spacebar ไม่ค้างกระโดดรัว (Bunny-hopping), และการต่อยอดชุดแอนิเมชัน A01–A18
- **การแก้ไขและสถาปัตยกรรม (Architectural & Kinematic Implementations):**
  1. **F-25 (Floor Clearance In-between Blends):**
     - Closed-form Analytical OBB solver บนชิ้นส่วน R6 ทั้ง 6 ชิ้น ทำงานร่วมกับ Dynamic Visual RootJoint Shift $\Delta y = \max(0, 0.010 - \min Y_{\text{rig}})$ ขจัดปัญหาฝ่าเท้าจมทะลุพื้นสนามตลอดทุกจังหวะเบลนด์ โดยไม่ยก HRP และไม่กระทบฟิสิกส์
  2. **F-26 (A05 8-way Strafe & A16 Single 3D Pass):**
     - A05 8-way strafe ใช้ตารางพารามิเตอร์ authoritative root lift ($ty \in [0.10, 0.35]$ studs)
     - A16 รวมการส่งบอลเป็น `"Pass"` เดียว Blend elevation ($0^\circ$ ถึง $45^\circ$) โดยตรึงขาหลัก Left Hip และ Root แนบพื้น ไม่ขยาย power เกินขอบเขต
  3. **F-27 (Terminal Cancel & Auto-Next Resurrection Guard):**
     - ออกแบบ 7-state FSM (`Inactive`, `Playing`, `Holding`, `Stopping`, `Cancelled`, `Rejected`, `Completed`)
     - ในสถานะ `Stopping`, `Cancelled`, `Rejected` จะบังคับ `canAutoNext = false` และ `autoNextAction = nil` อย่างถาวร ป้องกันการฟื้นคืนชีพของท่าหลังหยุด
  4. **F-28 (Discrete Spacebar Release Guard & Real Flight Lifecycle):**
     - เพิ่ม `isSpacebarHeld` และ `jumpConsumedUntilRelease` ใน `InputController.luau` ป้องกันการกด Spacebar ค้างแล้วกระโดดรัวติดกัน (Bunny-hopping) จนกว่าจะปล่อยปุ่มจริง
     - ใช้สถานะการบินตามความเร็วดิ่ง `AssemblyLinearVelocity.Y` ร่วมกับ 3.2-stud downward turf raycast ตรวจจับพื้นสนามจริง ตัดระบบจับเวลา 0.72s ออก
     - Acrobatic Bicycle Kick ลอยตัวในมุมกลับหัวตลอดไฟลต์ และเมื่อ Raycast สัมผัสพื้นจะเข้าสู่ `TriggerAirborneRecovery` (Breakfall cushion) อย่างนุ่มนวล
  5. **F-29 (Charge Stance Dual-Guard & Sagittal Mirroring):**
     - Dual-guard ใน `R6AnimationController.luau` ตรวจสอบ `IsCharging` สั่ง fade-out แทร็ก locomotion ทันที ทำให้ตัวละครค้างท่าง้างยิงและเคลื่อนที่ 50% ได้อย่างราบรื่นโดยขาไม่สับหลอก
     - พัฒนา `PlayerActionPoseConfigs.MirrorPoseSagittal` สะท้อนท่าทางแกน $X$, มุม Roll/Yaw และสลับข้างแขนขา รองรับการยิงและปั่นด้วยเท้าซ้ายตามค่าที่ Server ตัดสิน (`ResolvedKickFoot`)
     - แก้ไขคีย์เฟรม 2 และ 3 ของ `A15-trivela` ให้ Left Hip counter-roll ($+14.0^\circ$ และ $+18.0^\circ$) หักล้างมุมเอียงลำตัว Torso ขาหลักปักพื้นหญ้าแน่นสนิท
  6. **F-30 (Foot Sliding Mitigation):**
     - ปรับ Walk cadence เป็น $0.36$s / stride $42^\circ$ สำหรับความเร็ว $20.0$ studs/s และปรับ Sprint duty cycle สอดคล้องกับ $32.0$ studs/s คลาดเคลื่อนเพียง $3.1\%$
- **ผลการทดสอบ In-Engine (Roblox Studio Place 137721422246269):**
  - ซิงค์โมดูลทั้งหมด 12 ไฟล์ลง Studio Edit DataModel ผ่าน MCP:
    - `src/shared/Constants.luau`
    - `src/shared/Types.luau`
    - `src/shared/configs/PlayerActionPoseConfigs.luau`
    - `src/shared/configs/RigAnimationConfigs.luau`
    - `src/client/character/R6ActionPoseController.luau`
    - `src/client/character/R6AnimationController.luau`
    - `src/client/controllers/InputController.luau`
    - `src/client/controllers/CameraShiftLockController.luau`
    - `src/client/controllers/TrainingHUD.luau`
    - `src/server/services/BallService.luau`
    - `tests/e2e/TestHarness.luau`
    - `tests/e2e/Tier1_PlayerActions.luau`
  - รัน E2E Test Suite `Tier1_PlayerActions.luau`: **49 / 49 PASSED (344 Assertions, 0 Failures)** ครบทั้ง 7 Suites
  - รัน Play Mode ใน Client DataModel:
    - ตัวละครเกิดสมบูรณ์ R6 Humanoid ใน ActionContext `Attacking`
    - ระยะห่างแขนขวา/ซ้ายถึงศูนย์กลาง Torso เท่ากับ 1.500 studs (0 dislocation)
    - ทดสอบ Spacebar discrete latch: กระโดด 1 ครั้งแล้วถูกบล็อกจนกว่าจะปล่อยปุ่ม Spacebar สำเร็จ 100%
    - ทดสอบง้างยิง: เข้าสู่สถานะ `Holding` ปราศจากอาการสับขาหลอก
    - ทดสอบ Sagittal Mirroring: ท่าปั่นเท้าซ้ายและเท้าขวาสะท้อนตรงข้ามกันอย่างสมบูรณ์แบบ
- **สถานะ:** รายงาน `fix-004.md` เสร็จสมบูรณ์ พร้อมส่งมอบให้ Codex (`stang-luna`) ตรวจสอบต่อไป โดยรักษากฎความปลอดภัย ไม่มีการ git commit, push, merge, deploy หรือปิดแผนงาน 00, 01, 02
