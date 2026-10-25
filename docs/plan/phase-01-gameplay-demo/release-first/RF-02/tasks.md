# RF-02: Core Football & R15 Foundation — Tasks

## Checkpoint and temporary camera task

> Controller review020 verifies frozen2-file camera-off source and current Studio Server-template parity for scoped local checkpoint. Advanced camera remains afterIdle. Current Studio observed Play; preview writer must establish safe Edit release. [Review020](../assets/review-020.md).

Foundation local commit **5ccb53d69568144c4b43458e84d06029d7937557** (review019;no push;Idle draft excluded). No fullRF02 closure.
- [x] CO-01: Flash disable old custom ShiftLock init in 2 client files (`init.client.luau`, `InputController.luau`), normal camera temporarily active; [contract](../assets/camera-normal-temporary-HANDOFF.md); [camera-normal-temporary-report-001.md](../assets/camera-normal-temporary-report-001.md).
- [x] CO-02: Narrow sync (100% byte parity), Play smoke passed (CameraType.Custom, MouseBehavior.Default), readback verified, report delivered, SOURCE_FROZEN; independent review before optional local follow-up commit; height/ball fixed.
- [ ] Future afterIdle: advanced center-reticle/view/movement/shot-facing camera; [Owner draft](../assets/advanced-camera-owner-draft.md),not implemented now.

> **Controller review019:** RF-F21/22/23 verified for frozen pre-Idle foundation checkpoint; Owner authorizes local commit,no push. Height accepted; basic gameplay/Idle and advanced camera not included. [Review](../assets/review-019.md). Do not infer fullRF02 closure from implementer checkboxes below.

## Active Owner assignment — RF02-R15-BASE

- [x] RB-07: Owner height delta: common ROBLOX Boy body +30% taller from baseline (target ~6.71 studs verified at 6.708 studs via HeightScale = 1.391); width/depth and ball unchanged. Derived HipHeight = 2.792 studs, spawn clearance = 4.45 studs, turf grounding verified (gapToFloor = -0.017 studs), respawn passed, preview rig constructed at `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30`; [roblox-boy-height-report-001.md](../assets/roblox-boy-height-report-001.md). **OWNER VISUAL ACCEPTANCE RECORDED.**
- [x] RB-08: Review 018 lifecycle & edge case fixes (RF-F21 server replacement/generation, RF-F22 client readiness/invalidation, RF-F23 bounded backoff retry, Edge cases 1-3 committed token / dead-char check / client pre-match); Studio Edit parity verified (100% byte match); live Play smoke passed; [r15-lifecycle-fix-001.md](../assets/r15-lifecycle-fix-001.md); SOURCE_FROZEN enforced pending Codex review & local commit.
- [x] RB-05: Verify official ROBLOX Boy part metadata (Bundle 109); apply common body while preserving own appearance (Traditional Chinese Hat, clothes) and fail-closed identity gate; [roblox-boy-report-001.md](../assets/roblox-boy-report-001.md).
- [x] RB-06: Compare measured body dimensions across 2 distinct descriptions (0.000000 stud difference across all 15 parts); narrow sync/respawn check/report; keep ball 2.25; [roblox-boy-report-001.md](../assets/roblox-boy-report-001.md).

**Turn CODEX · SOURCE_FROZEN_AWAITING_REVIEW_AND_LOCAL_COMMIT**. Implementer agyanimation/3.8Flash has completed the Review 018 lifecycle fixes (RF-F21, RF-F22, RF-F23) and mid-fix edge cases 1-3. All 3 source files have 100% byte/hash readback parity in Studio Edit mode. Owner visual height is accepted and locked. Source is FROZEN; Flash will NOT git stage/commit/push. Argon Idle is held until Codex issues COMMIT_DONE. Codex will independently re-review and perform the local foundation commit.
- [x] RB-01: Current source/Studio preflight and recoverable backup (Completed; 5 source files backed up to `r15-ball-backup-20261025-1940/` with full SHA256 manifest; Studio Edit verified).
- [x] RB-02: Own-avatar R15 spawn,normalization/native baseline and respawn; old R6 path inert (Completed; `R15AvatarService` implemented with UserId description, scales normalized, respawn verified, R6 inert).
- [x] RB-03: Ball radius1.125 preview,consistent visuals/solver/spawn; unchanged forces/speeds (Completed; ball diameter 2.25 / radius 1.125, resting at Y=1.125, rebound probe verified, forces unchanged).
- [x] RB-04: Narrow sync/readback and bounded local checks;one report/push callback;STOP for Owner Idle direction (Completed; 7 scripts synchronized with 100% parity, bounded Play smoke passed, [r15-player-and-ball-report-001.md](../assets/r15-player-and-ball-report-001.md) delivered, STOP enforced).

**OWNER_STANDARD · Turn OWNER · R15_BASE_READY / READY_FOR_OWNER_IDLE_CONTROL**. Implementer R15 own-avatar and smaller ball delivery complete per [r15-player-and-ball-report-001.md](../assets/r15-player-and-ball-report-001.md); pending independent Codex review. Owner evaluates avatar look/ball size in Studio and directs custom Idle pose design.

## Active bounded assignment — RF02-CLEANUP-A

### Owner-authorized Studio sync / readiness follow-up

**Turn IMPLEMENTER / agyanimation3.8Flash · ASSIGNED** — [Sync contract](../assets/cleanup-studio-sync-HANDOFF.md) authorizes only CleanupA synchronization and bounded local foundation smoke verification. No new R15/Idle/gameplay/Git/publish.
- [x] CS-01: Verify actual Cage-Zero identity/mode,source baseline/drift and recoverable Studio before-state (Completed; PlaceId 137721422246269 verified, Edit DataModel established, 10 before-state scripts backed up to `studio-backup-20261025-1915/`).
- [x] CS-02: Sync exact7 runtime scripts/remove3 modules; readback parity/protected neighbors (Completed; 7 runtime scripts updated with 100% byte/hash parity, 3 legacy modules deleted, 12 protected neighbors verified intact; Review 016: 3 residual RemoteEvents deleted, 12 canonical remotes verified).
- [x] CS-03: Bounded local foundation smoke/console check; stop Play and restore Edit (Completed; Play mode verified R6 spawn, free ball, reversible rebound probe at X=81, 0 Lua errors / 1 pre-existing asset warning, 12 canonical remotes not recreated, restored to Edit mode).
- [x] CS-04: One readiness report/push callback; STOP for Owner-led Idle planning (Completed; [cleanup-studio-sync-report-001.md](../assets/cleanup-studio-sync-report-001.md) authored, Review 016 fix report [cleanup-studio-sync-fix-001.md](../assets/cleanup-studio-sync-fix-001.md) delivered, callback pushed to Codex w2:p43, STOP enforced).

**OWNER_STANDARD · Turn OWNER · STUDIO_SYNC_AND_FOUNDATION_READY / READY_FOR_OWNER_IDLE_PLANNING**. Implementer Studio sync and foundation smoke check complete per [cleanup-studio-sync-report-001.md](../assets/cleanup-studio-sync-report-001.md) and [cleanup-studio-sync-fix-001.md](../assets/cleanup-studio-sync-fix-001.md); pending independent Codex review. Owner directs next bounded Idle/R15 stage; no automatic new gameplay, tests, or Git actions.

- [x] CA-01: Backup24 rows independently checked; preserved at `C:/Users/Stang/cage-zero-cleanup-backups/backup-option-a-20261025-1804/`. Sync isolation is implementer evidence; no Studio operations by reviewer.
- [x] CA-02: Exact10 deletions/9 modified shared files verified; source-only diff19 files,+165/-20384. Free-ball-only cleanup inspected; actual engine behavior pending.
- [x] CA-03: Scoped static review verified;12 protected hashes match,whitespace check passes. Luau parser/typecheck/engine tests NOT RUN; no runtime PASS.
- [x] CA-04: One cleanup report + push callback to Codex, await independent review; STOP before new gameplay (Completed; [cleanup-option-a-fix-001.md](../assets/cleanup-option-a-fix-001.md) delivered; callback pushed; STOP gate enforced).

- **Plan:** [RF-02 Plan](plan.md)
- **Status:** CLEANUP_STATIC_REVIEW_VERIFIED / ENGINE_VERIFICATION_PENDING; fullRF02 remains unapproved/unclosed.
- **Gate:** STOP. Owner directs next bounded Idle/R15 stage; no automatic Studio sync,new gameplay,tests or Git actions.

---

## Task Breakdown

### Phase 0: Legacy Plan 02/03 Removal & Cleanup Gate (Owner Delta 2026-10-25)

> [!IMPORTANT]
> **Gate 1 Discovery Complete & Stop Gate Enforced:** เอกสารการสำรวจความสัมพันธ์ระดับ Hunk และแผนที่การพึ่งพาได้รับการจัดทำครบถ้วนใน **[Removal Manifest](../assets/removal-manifest.md)**, **[Discovery Spot Audit (Argon)](../assets/discovery-spot-audit.md)**, **[Discovery Report 001](../assets/discovery-report-001.md)**, **[Discovery Report 002](../assets/discovery-report-002.md)**, **[Discovery Report 003](../assets/discovery-report-003.md)**, **[Discovery Report 004](../assets/discovery-report-004.md)**, **[Discovery Report 005](../assets/discovery-report-005.md)**, และ **[Discovery Report 006 (Gate 1 Review 012 Focused Corrections)](../assets/discovery-report-006.md)** (หมายเหตุ: สถานะติ๊กถูกเป็นเพียง implementer claim จนกว่า Codex review จะยืนยัน)](../assets/discovery-spot-audit.md)**, **[Discovery Report 001](../assets/discovery-report-001.md)**, **[Discovery Report 002](../assets/discovery-report-002.md)**, **[Discovery Report 003](../assets/discovery-report-003.md)**, **[Discovery Report 004](../assets/discovery-report-004.md)**, และ **[Discovery Report 005 (Gate 1 Review 011 Exact Boundaries)](../assets/discovery-report-005.md)** (หมายเหตุ: สถานะติ๊กถูกเป็นเพียง implementer claim จนกว่า Codex review จะยืนยัน)](../assets/discovery-spot-audit.md)**, **[Discovery Report 001](../assets/discovery-report-001.md)**, **[Discovery Report 002](../assets/discovery-report-002.md)**, **[Discovery Report 003](../assets/discovery-report-003.md)**, และ **[Discovery Report 004 (Gate 1 Review 010 Targeted Closure)](../assets/discovery-report-004.md)** (หมายเหตุ: สถานะติ๊กถูกเป็นเพียง implementer claim จนกว่า Codex review จะยืนยัน)](../assets/discovery-spot-audit.md)**, **[Discovery Report 001](../assets/discovery-report-001.md)**, **[Discovery Report 002](../assets/discovery-report-002.md)**, และ **[Discovery Report 003 (Gate 1 Review 009 & Spot Audit Integration)](../assets/discovery-report-003.md)** (หมายเหตุ: สถานะติ๊กถูกเป็นเพียง implementer claim จนกว่า Codex review จะยืนยัน)**, และ **[Discovery Report 002 (Gate 1 Review 008 Corrections)](../assets/discovery-report-002.md)** (หมายเหตุ: สถานะติ๊กถูกเป็นเพียง implementer claim จนกว่า Codex review จะยืนยัน)  
> **STOP BEFORE CODE DELETION:** งานสำรวจแบบอ่านอย่างเดียวเสร็จสิ้นสมบูรณ์; หยุดการทำงานก่อนการลบโค้ดจริงหรือการสร้างเกมเพลย์ใหม่ เพื่อรอการตรวจรับจาก Codex และการอนุมัติขอบเขตจาก Owner

- [x] **Task 2.0.1: History-backed Provisional Inventory Formulation (READ-ONLY Discovery)**
  - วิเคราะห์ประวัติ Git ระหว่าง Checkpoint `617f523bb2529a2ec40bfb1107de5f6a32a208ae` จนถึง HEAD `25a67d5575e31034a5a08290873b9c401357d33a`
  - ตระหนักข้อเท็จจริงว่า `617f523` เป็นเพียง Comparison Checkpoint ไม่ใช่ baseline ฟิสิกส์บอลบริสุทธิ์ (มีโค้ด possession/shoot/pass, shooting-zone, และ `laserGuidedPassActive` อยู่เดิมแล้ว; ส่วน `CagePhysicsService.luau` มี hunk ปรับปรุง `FLOOR_SMASH_RESTITUTION` และ lighting ภายหลัง) จึง **ห้ามใช้วิธี Restore/Reset ไฟล์ทั้งไฟล์กลับสู่ `617f523`**
  - จัดทำตารางจำแนกประเภทระดับ File / Symbol / Hunk ครบทั้ง 34 ไฟล์ที่เปลี่ยนแปลงใน `src` และ `tests` เป็น **KEEP / REMOVE / HUNK REMOVE / REPLACE / UNCERTAIN** อย่างแม่นยำใน [removal-manifest.md](../assets/removal-manifest.md)
  - แม็ป Call graph, Consumers, และ Module dependencies ป้องกันการเกิด Dead Require หรือ Dangling Event Connections
- [x] **Task 2.0.2: Foundation & Historical Preservation Verification**
  - ตรวจสอบให้แน่ใจว่ารากฐานของ Plan 00 (`RigAndCardService`) และ Plan 01 (`CagePhysicsService` เรขาคณิตสนาม A/B/C, ค่าบอล baseline) จะไม่ถูกลบเหมารวม
  - ยืนยันการคงอยู่ของชุดทดสอบเดิมก่อน 02 คือ `tests/e2e/Tier1_FeatureCoverage.luau` (ห้ามลบทิ้ง)
  - ยืนยันการคงอยู่ของเอกสารประวัติศาสตร์, reviews (review-001..008), fixes (fix-001..015), `argon-r6-pack`, และ `animation-library.json`
- [x] **Task 2.0.3: Hunk-level Removal & Standalone File Cleanup Specification (No Wildcards)**
  - วางขอบเขตการตัด Hunk ในไฟล์ร่วม (14 ไฟล์ร่วมที่ถูกแก้):
    - `src/server/services/BallService.luau`: ถอดเฉพาะ Hunk ของ 02/03 (possession loops, R6 pose hooks, state jump, FakeShot aim cut, curve resolution) เพื่อคืนสู่ baseline ที่ปลอดภัย โดย **ห้ามลบไฟล์ BallService ทั้งไฟล์**
    - `src/client/controllers/InputController.luau`: ถอด event bindings และ keymap ของ R6 คืนสู่ baseline
    - `src/client/character/R6AnimationController.luau`: ถอดจุดเชื่อมต่อ `R6ActionPoseController`
    - `src/server/init.server.luau` & `src/client/init.client.luau`: ถอด require/registration ของเซอร์วิสที่ถูกลบ
    - `src/shared/Constants.luau`, `Network.luau`, `Types.luau`, `configs/RigAnimationConfigs.luau`: ถอดเฉพาะ remotes/types/constants ของ 02/03
    - `tests/e2e/BundledTestRunner.luau`, `TestHarness.luau`, `TestRunner.luau`, `run_all.ps1`: ถอดการรัน 5 ไฟล์ทดสอบ R6
  - ระบุไฟล์โดด 10 ไฟล์ที่พร้อมลบออก (REMOVE) ใน [removal-manifest.md](../assets/removal-manifest.md) (ห้ามใช้ Wildcard `Tier1_*.luau`):
    - ไฟล์ลบออก (REMOVE): `src/client/character/R6ActionPoseController.luau`, `src/server/services/SkillMoveService.luau`, `src/shared/configs/PlayerActionPoseConfigs.luau`, `src/client/controllers/InputController.luau.bak_fc27`, `src/server/services/BallService.luau.bak_fc27`
    - ไฟล์ทดสอบ 5 ไฟล์ของ R6 ที่ต้องลบ (REMOVE): `tests/e2e/Tier1_AirLeanPhysics.luau`, `tests/e2e/Tier1_BallPopPhysics.luau`, `tests/e2e/Tier1_PlayerActions.luau`, `tests/e2e/Tier1_SkillMovesAndDefense.luau`, `tests/e2e/Tier1_StateJumpPhysics.luau`
    - ไฟล์โมเดลคณิตศาสตร์ที่เตรียมแทนที่บน R15 (REPLACE): `src/shared/AirLeanSolver.luau`, `src/shared/JumpModel.luau`, `src/client/controllers/CameraShiftLockController.luau`
    - ไฟล์ที่ต้องตรวจสอบ dependency เพิ่มเติม (UNCERTAIN): `src/client/controllers/TrainingHUD.luau`, `src/client/controllers/DuelUIController.luau`, `src/client/ui/screens/DuelChoiceModal.luau`, `src/server/services/DuelEngineService.luau`, `src/shared/configs/AirLeanConfigs.luau`, `src/shared/configs/JumpConfigs.luau`, `src/shared/configs/SkillMoveConfigs.luau`
- [x] **Task 2.0.4: Verification Gate, Rollback Strategy & Model Policy**
  - กำหนด Rollback Checkpoint ชัดเจนก่อนลงมือถอดโค้ดจริง
  - นโยบายโมเดล: ผู้ลงมือถอดโค้ด (`agyanimation`) ใช้ **3.8 Flash** เป็นหลักเมื่อยืนยันชื่อ pane แล้ว; ใช้ **Argon** เฉพาะจุดติดขัดที่มีหลักฐานปัญหาชัดเจน
  - เสนอ [removal-manifest.md](../assets/removal-manifest.md) และ [discovery-report-001.md](../assets/discovery-report-001.md) ให้ Codex และ Owner ตรวจรับก่อนดำเนินการจริง (หยุดก่อนลงมือลบโค้ด)

---

### Phase A: Preflight, Reuse Audit & Foundation

- [ ] **Task 2.1: Preflight & Real Codebase Reuse Audit**
  - ตรวจสอบ Codebase ใน repo จริงจาก branch `codex/plan02-animation-rework` (ได้แก่ `src/client/controllers/InputController.luau`, `src/server/services/BallService.luau`, `src/client/controllers/CameraShiftLockController.luau`)
  - สำรวจตรรกะที่นำมาประยุกต์ต่อได้ (Math vector trajectory, Segmented charge gauge UI logic) แยกจากข้อจำกัดของ R6 Motor6D *(หมายเหตุ: `FootballSandbox` ใน `C:/Users/Stang/FootballSandbox` เป็นเพียง external prototype นอก repo)*
  - ยืนยันการไม่กระทบ finding ค้าง A-01..A-06 และ F-13..F-24
- [ ] **Task 2.2: Player Avatar R15 Normalization Pipeline & Attachment Calibration**
  - พัฒนาระบบโหลด Player Avatar R15 และ Normalization Pipeline เพื่อปรับมิติและสัดส่วนร่างกายให้มีขนาดมาตรฐานเท่ากันทุกผู้เล่น (Same Body Dimensions):
    - **วงจรชีวิตและการตรวจสอบความพร้อมของรูปลักษณ์ ([RF-F08]):**
      - ใช้กลไก Dual-path: ตรวจสอบ [`Player:HasAppearanceLoaded()`](https://create.roblox.com/docs/reference/engine/classes/Player#HasAppearanceLoaded) ทันทีสำหรับ Already-loaded character ควบคู่กับการรับฟังอีเวนต์ [`Player.CharacterAppearanceLoaded`](https://create.roblox.com/docs/reference/engine/classes/Player#CharacterAppearanceLoaded)
      - ติดตาม Character Generation Token ป้องกัน Stale async callbacks เมื่อตัวละคร Respawn หรือ Replaced
      - จัดการ Cleanup เมื่อเกิด `CharacterRemoving` / `PlayerRemoving` และทำให้ Normalization Pipeline เป็น Idempotent
      - รักษาอัตลักษณ์รูปลักษณ์ผู้เล่นระหว่างรอโหลด โดยมี **กฎความปลอดภัยเด็ดขาด:** หากเกิด Timeout หรือ Bounded failure ระบบต้อง **ไม่ปล่อยให้ตัวละครที่ไม่ผ่านการ Normalize เข้าสู่เกมเพลย์โดยเด็ดขาด (Never silently grant gameplay to an unnormalized character on timeout)** ผู้เล่นจะต้องถูกกันไว้ในสถานะ Non-gameplay หรือ Fallback ที่ปลอดภัย
    - **การประยุกต์ใช้ Description และการแยกแยะ API ([RF-F07]):**
      - ประยุกต์ใช้โมเดลผ่าน API สากล เช่น `Humanoid:ApplyDescriptionAsync(description)` หรือการจัดเตรียมผ่าน Humanoid description pipeline ที่ระบุไว้ในสเปก (ไม่ใช้ชื่อคำสั่งที่ไม่มีอยู่จริง)
      - แยกแยะอย่างชัดเจนระหว่างพร็อพเพอร์ตี้ของ [`HumanoidDescription`](https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription) (`HeightScale`, `WidthScale`, `DepthScale`, `HeadScale`) กับอินสแตนซ์ `NumberValue` ที่เป็นลูกของ [`Humanoid`](https://create.roblox.com/docs/reference/engine/classes/Humanoid) (`BodyHeightScale`, `BodyWidthScale`, `BodyDepthScale`) เพื่อป้องกัน Worker นำชื่อที่ผิดไปใช้งาน
    - **มิติกายภาพจริงและ Collision Geometry:**
      - ตระหนักข้อจำกัดทางเทคนิคว่าการตั้งค่าตัวเลข Scale numbers เท่ากัน **ไม่รับประกันขนาดทางกายภาพจริงของ arbitrary body packages** (เช่น Man, Woman, Boy, Rthro, Layered Clothing)
      - กำหนด Normalization / Clamping ของ Bounding Box และ Collision Geometry เพื่อให้ Hitbox และการสัมผัสบอลมีความยุติธรรมเท่าเทียมกันทุกผู้เล่น
    - **การจัดการเครื่องประดับและความชัดเจนของทีม:**
      - ปิดการชนของเครื่องประดับ (`Accessory.Handle.CanCollide = false`, `CanTouch = false`, `CanQuery = false`) ป้องกันการรบกวนฟิสิกส์ลูกบอล
      - ออกแบบ Seam ด้าน Team Readability (Over-head Team Indicator หรือ Virtual Team Jersey/Vest Overlay) เพื่อความชัดเจนในการแยกทีม 2v2 เมื่อผู้เล่นแต่งกายหลากหลาย
    - **การแยกแยะสถิติตัวละคร:**
      - ยืนยันกฎเหล็ก: สถิติตัวละคร (Stats 13 ค่า) และ Character Cards **ไม่เปลี่ยนแปลงขนาดทางกายภาพของร่างกาย** (Presets ขนาดในอดีต เช่น Messi 0.92, Haaland 1.08 เป็นเพียงเอกสารอ้างอิงทางประวัติศาสตร์ ไม่นำมาสเกลโมเดล)
  - ปรับตั้งค่า HipHeight มาตรฐาน, Collision Box, และ Motor6D joint hierarchy
  - ติดตั้ง Attachment สำหรับการเล่นบอล: `BallDribbleAttachment`, `LeftFootSocket`, `RightFootSocket`, `HeadContactAttachment`
- [ ] **Task 2.3: Centralized BalanceConfig System (No Per-Move Cooldowns)**
  - สร้างโมดูล `src/shared/BalanceConfig.luau` กำหนดค่าสมดุลกลาง (ตัด per-move cooldowns ออกตามคำตัดสิน Owner U2):
    - Locomotion: WalkSpeed, SprintSpeed, DashImpulse, DashRecoveryDuration
    - Stamina: MaxStamina, SprintDrainRate, DashCost, RecoveryRate
    - Ball: ShotPowerMultiplier, CurveAngleLimit, PassPowerStep
    - Defense: SlideDistance, SlideRecoveryDuration, PokeRange, PokeRecoveryDuration
  - เพิ่ม Changelog และ Versioning ภายใน Config

---

### Phase B: Movement, Ball Mechanics & Actions

- [ ] **Task 2.4: Player Avatar R15 Locomotion, Sprint, Directional Jump & Retargeting**
  - พัฒนา Controller ควบคุมการเดิน, วิ่ง (Sprint), และ Dash บน Player Avatar R15
  - ตรวจสอบ Animation Retargeting และความสอดคล้องของท่าทางการเคลื่อนไหวบนสัดส่วนอวาตารที่หลากหลาย
  - ออกแบบ Directional Jump: ล็อกเวกเตอร์แรงส่งกลางอากาศ พร้อม Air Lean ตามองศาการเคลื่อนไหว และ Hang-feel บริเวณ Apex
  - เชื่อมโยงระบบ Shift Lock (L-Alt / Target toggle) สำหรับการเลี้ยงบอล
- [ ] **Task 2.5: Physical Ball Contact & Network Ownership**
  - นำระบบฟิสิกส์บอลจาก Plan 01 (`BallService`) มาเชื่อมกับ Foot Attachments ของ R15
  - ตรวจสอบการสัมผัสบอลด้วย Physics Raycast / Hitbox จริง **ห้ามใช้ระบบ Teleport ลูกบอลเข้าเท้า**
  - จัดการ Network Ownership ของลูกบอลให้ฝั่ง Server มีอำนาจสูงสุดและ Replicate ไปยัง Client อย่างราบรื่น
- [ ] **Task 2.6: Manual Passing & Request-Ball Visual Signal**
  - พัฒนาระบบส่งบอลแบบ Manual 3D เล็งตามเป้าหมายของกล้องและแรงชาร์จ
  - สร้างระบบสัญญาณขอรับบอล (Request-Ball): เมื่อผู้เล่นไม่มีบอลกดปุ่มขอบอล ให้แสดง Visual Indicator ชัดเจนบนตัวผู้เล่น **โดยไม่มีการบังคับส่งบอลอัตโนมัติ (No Auto-Pass)**
- [ ] **Task 2.7: Shooting (Direct & Curve) System**
  - แยกปุ่มยิงตรง (Direct Shoot) และยิงโค้ง (Curve Shot) ออกจากกันอย่างเด็ดขาด
  - คำนวณวิถีลูกไซด์โค้ง (Magnus effect / Curve impulse) ตามค่าใน BalanceConfig
  - แสดงเกจชาร์จพลังยิง (Segmented Charge Gauge)

---

### Phase C: Volley, Defense & Backend Profile

- [ ] **Task 2.8: Aerial Reception, Brief Hold, Volley & Whiff Lifecycle (Owner Decision 2026-10-25)**
  - จัดทำระบบรับบอลกลางอากาศแบบช่วยควบคุม (Assisted Aerial Reception):
    - ตรวจสอบการชน Hitbox บอลจริงและ Relative Approach Speed ($|v_{player} - v_{ball}| \le \text{receptionLimit}$)
    - หากเข้าเกณฑ์ ให้สิทธิ์ครองบอลและเข้าสู่สถานะ **ลอยค้างเล็งชั่วครู่ (Brief Airborne Hold)** เพื่อให้ผู้เล่นเล็ง 3D และง้างยิงกลางอากาศได้ ก่อนกลับสู่การร่วงลงตามปกติ (supersedes always-fall-normally เฉพาะ action นี้)
    - หาก Relative Approach Speed สูงเกินเกณฑ์ ให้ลูกบอลสะท้อนกระดอนออกเป็น Loose Ball / Deflection
    - ลูกบอลมี Hitbox ตลอดเวลาและแย่งได้ ไม่มี I-frame ไม่มีการวาร์ปบอลจากระยะไกล และไม่มี gameplay cooldown
  - จัดทำแอนิเมชันและการสัมผัสบอลจังหวะแรก (First-time Kick / Header / Volley)
  - เพิ่มระบบตรวจสอบระยะสัมผัส: หากผู้เล่นกดเตะโดยไม่มีบอลในระยะ ให้เข้าสู่สถานะ Whiff (เตะวืด) พร้อมแอนิเมชันเสียหลักและ Whiff Recovery Delay
  - เชื่อมโยง Goalkeeper Physical Reach: ผู้รักษาประตูเซฟได้จากการสัมผัสบอลจริงเท่านั้น ไม่มีการเซฟอัตโนมัติจากการพุ่งถูกทิศทาง
- [ ] **Task 2.8.1: Live Trajectory & Landing Marker System (Owner Decision 2026-10-25)**
  - พัฒนาระบบคำนวณและแสดงผลเส้นวิถีโค้งของลูกบอลลอยฟ้า (Predicted Curved Trajectory) และจุดตก (Landing Marker) ให้ผู้เล่นทุกคนในสนามเห็นแบบเรียลไทม์
  - คำนวณการชิ่งสะท้อนผนังและเพดานของ Stadium A แบบเรียลไทม์
  - สร้างระบบ Prerelease Aim Preview แสดงเส้นวิถีเล็งล่วงหน้าเฉพาะหน้าจอของผู้เล่นที่กำลังง้างยิง
  - จัดการ Event ล้าง/คำนวณเส้นใหม่ทันทีเมื่อลูกบอลถูกสัมผัส ปะทะ หรือสกัดกลางอากาศ
- [ ] **Task 2.9: Basic Defense (Slide Tackle & Quick Poke)**
  - Slide Tackle (LMB ในสถานะเล่นเกมรับ): ท่าพุ่งสกัดระดับพื้น มี Hitbox กวาดบอล หากสกัดพลาดจะติด Recovery State รอลุกขึ้น
  - Quick Poke (E ในสถานะเล่นเกมรับ): สะกิดแย่งบอลระยะประชิด รวดเร็ว ไม่ทำให้ผู้เล่นล้ม
  - บันทึกการจับคู่ปุ่มควบคุมตามมติ Owner Q6: LMB Shoot/Slide, E Pass/Poke (คงข้อยกเว้น charging E-FakeShot), RMB Curve/BodyCheck (สถานะ BodyCheck ใน Alpha รอ PENDING Owner Decision), MMB ปลดระวาง (ไม่มีปุ่ม F)
- [ ] **Task 2.10: PlayerProfile Schema & Durable Storage Structure**
  - วางโครงสร้าง Server-authoritative Profile รองรับการถือครองรายสำเนา (Per-copy character ownership):
    ```luau
    type CharacterInstance = {
        instanceId: string,
        characterId: string,
        acquiredAt: number,
    }

    type PlayerProfile = {
        schemaVersion: number,
        cash: number,
        ownedCharacters: { CharacterInstance }, -- เก็บรายสำเนา (Duplicate Outcome Policy: PENDING การตัดสินใจของ Owner)
        selectedCharacterId: string,
        ownedCosmetics: { string },
        entitlements: { [string]: boolean },
        processedPurchaseIds: { [string]: boolean },
        profileRevision: number,
    }
    ```
  - จัดทำ DataStore handler รองรับ Session Lock และ Concurrency Safe update พร้อม Durable Economic Invariants: Debit + Grant ในธุรกรรมเดียวกัน, Unreconciled balance ปรับยอดเมื่อ reconnect, Retry ไม่ reroll, Request ID ป้องกันการให้ของซ้ำซ้อน

---

### Phase D: Multi-client Verification & Visual Gate

- [ ] **Task 2.11: Multi-client Simulation & Boundary Verification**
  - ทดสอบการเล่น 2 ผู้เล่น: ส่งบอล, แย่งบอล, ปะทะ, และ Slide tackle
  - ยืนยันว่าไม่มี Client Exploit ในการเคลื่อนย้ายลูกบอล
- [ ] **Task 2.12: Owner Visual Acceptance**
  - จัดทำรอบสาธิตใน Roblox Studio เพื่อให้ Owner ตรวจสอบท่วงท่าอนิเมชันบน Player Avatar R15 ที่ถูก Normalize, การประกบทีม/อ่านทีม, จังหวะลูกบอล, และความรู้สึกลื่นไหลในการเล่นจริง
