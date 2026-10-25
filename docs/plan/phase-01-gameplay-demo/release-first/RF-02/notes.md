# RF-02: Core Football & R15 Foundation — Notes

- **Date:** 2026-10-25
- **Status:** Planning / Documentation Synchronized
- **Related Docs:**
  - [Release-First Track Plan](../plan.md)
  - [Owner R15 Restart Directive](../assets/owner-r15-restart.md)
  - [Legacy Plan 02 Cancelled Notes](../../02-player-actions/notes.md)

---

## Active Follow-Up Task — RF02-LEGACY-ANIM-CLEANUP (Legacy Animation Removal)

- **Execution Contract:** [`legacy-animation-removal-HANDOFF.md`](../assets/legacy-animation-removal-HANDOFF.md) & [`review-021.md`](../assets/review-021.md)
- **Status:** **READY_FOR_REVIEW (Implementer claim; pending independent Codex review & local commit)**
- **Report:** [`legacy-animation-removal-report-001.md`](../assets/legacy-animation-removal-report-001.md)
- **Manifest:** [`legacy-animation-removal-manifest.md`](../assets/legacy-animation-removal-manifest.md)
- **Scope & Engine Delivery:**
  - Full recoverable before-state backup stored at `C:/Users/Stang/cage-zero-cleanup-backups/legacy-anim-cleanup-20261025-2115/` ([`BACKUP_METADATA.json`](file:///C:/Users/Stang/cage-zero-cleanup-backups/legacy-anim-cleanup-20261025-2115/BACKUP_METADATA.json)).
  - Exact 6 repo files deleted (R01–R06: `R6AnimationController.luau`, `RigAnimationConfigs.luau`, `R6FootballPoseData.luau`, `R6FootballPosePlayer.luau`, `animation-library.json`, `animation-library.delta-agycage.json`). *(Note: Removed raw assets remain retrievable from Git ref `9fbce58eb90ed6b7e6a39b00a5744455ee639811`).*
  - Exact 4 Studio targets deleted in `Cage-Zero` (`PlaceId = 137721422246269`): `R6AnimationController`, `RigAnimationConfigs`, `PlayerActionPoseConfigs`, and `ServerStorage.MotionToolsRigs.R6_Rig.Animate` (including 9 child Animation instances).
  - Preserved boundaries: `R6_Rig` Model body/Humanoid/Animator, orphan test modules (`Tier1_PlayerActions`, `TestRunner`), `CageZeroStandardR6Rig`, active R15 preview rig (`Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30`), and Argon's new R15 motion assets (`release-first/assets/animations/idle-r15/`) strictly intact.
  - Zero modifications to protected `src/` runtime scripts. Studio confirmed in `Edit` mode. No Git staging, committing, or pushing by Flash.

---

## Active Follow-Up Task — RF02-CAMERA-OFF (Temporary Normal Camera)

- **Execution Contract:** [`camera-normal-temporary-HANDOFF.md`](../assets/camera-normal-temporary-HANDOFF.md)
- **Status:** **SOURCE_FROZEN_AWAITING_REVIEW_AND_LOCAL_COMMIT (Implementer claim; pending independent Codex review & local commit)**
- **Report:** [`camera-normal-temporary-report-001.md`](../assets/camera-normal-temporary-report-001.md)
- **Scope & Engine Delivery:**
  - Owner Q3 Decision: Disabled legacy custom `CameraShiftLockController` initialization in `src/client/init.client.luau` and `src/client/controllers/InputController.luau`.
  - Legacy `CameraShiftLockController.luau` preserved as an inert reference.
  - Studio Edit readback parity verified (100% byte & SHA256 match).
  - Play smoke test verified: `CameraType = Enum.CameraType.Custom`, `CameraSubject = Humanoid`, `MouseBehavior = Default` (normal free cursor), `shiftLockActive = false`.
  - Height (~6.708 studs), ROBLOX Boy package, and ball (radius 1.125 / diameter 2.25) intact. 0 Lua errors.
  - Advanced center-reticle / free-look camera design safely queued for post-Idle in [`advanced-camera-owner-draft.md`](../assets/advanced-camera-owner-draft.md).
  - **SOURCE FROZEN:** No Git stage, commit, or push by Flash.

---

## Active Owner Milestone — RF02-R15-BASE (Player Avatar R15, ROBLOX Boy +30% Height, & Smaller Ball)

- **Execution Contract:** [`r15-player-and-ball-HANDOFF.md`](../assets/r15-player-and-ball-HANDOFF.md) & [`review-018.md`](../assets/review-018.md)
- **Status:** **SOURCE_FROZEN_AWAITING_REVIEW_AND_LOCAL_COMMIT (Implementer claim; pending independent Codex review & local commit)**
- **Reports:**
  - Lifecycle Fix Report: [`r15-lifecycle-fix-001.md`](../assets/r15-lifecycle-fix-001.md) (Review 018 fixes: RF-F21, RF-F22, RF-F23 & Edge cases 1-3)
  - Height +30% Report: [`roblox-boy-height-report-001.md`](../assets/roblox-boy-height-report-001.md) (**OWNER VISUAL ACCEPTANCE RECORDED: Height ~6.708 studs locked**)
  - ROBLOX Boy Baseline Report: [`roblox-boy-report-001.md`](../assets/roblox-boy-report-001.md)
  - Initial R15 & Ball Report: [`r15-player-and-ball-report-001.md`](../assets/r15-player-and-ball-report-001.md)
- **Scope & Engine Delivery:**
  - Review 018 Lifecycle Fixes:
    - RF-F21: Server connections kept active until replacement validated; `activeRequestGeneration[userId]` checked after every yield; cache committed only on valid model.
    - RF-F22: Client `IsR15Ready()` strictly enforces alive Humanoid, valid Animator descendant, matching `LocalPlayer.Character`, and Workspace descendant; captures local character before `task.spawn`.
    - RF-F23: Bounded backoff retry (`MAX_ACQUISITION_RETRIES = 3`, `RETRY_BASE_DELAY_SEC = 2.0`) for both description and model acquisition; explicit non-gameplay state entered upon exhaustion.
    - Edge Case 1: Separated in-flight `activeRequestGeneration[userId]` from `committedCharacterGeneration[userId]`, guaranteeing that old character's respawn listener never becomes inert on failed replacement attempts.
    - Edge Case 2: Dead character check on model creation failure (`isExistingAlive`), ensuring dead old characters during respawn do not shortcircuit bounded retry.
    - Edge Case 3: `onCharacterAdded` checks `localPlayer.Character == character` before incrementing `characterGeneration` or invalidating state, preventing stale background tasks from corrupting newer characters.
  - Standard Height Steering (+30%): Locked at `HeightScale = 1.391` delivering physical body height of `6.708 studs` (~`6.71 studs`, +30.05% growth from `5.158` baseline) while keeping `HeadScale = 1.0`. Width (`3.459`) and Depth (`1.366`) preserved.
  - Derived Grounding & Clearance: `CANONICAL_HIP_HEIGHT = 2.792 studs`, `SPAWN_HEIGHT_OFFSET = 4.45 studs`. Measured live turf contact: `gapToFloor = -0.017 studs`. Zero floating, zero ground clipping.
  - ROBLOX Boy Body Baseline (Bundle 109): Torso `376532000`, LeftArm `376530220`, RightArm `376531012`, LeftLeg `376531300`, RightLeg `376531703`. Stang's appearance preserved with `Traditional Chinese Hat`, Shirt `6169665524`, Pants `6457926684`, and body colors.
  - Dimension equality proven: Stang vs User 1 difference is exactly 0.000000 studs across all 15 limb, torso, and root parts.
  - Respawn lifecycle verified: 2.0s delay, respawns as R15 Boy with 1 Animator, 100 Health. Stale R6 spawner is inert.
  - Ball preview: diameter 2.25 studs (radius 1.125), resting at `Y = 1.125`, forces/speeds unchanged.
  - Studio parity: 100% byte/SHA256 match for `R15AvatarConfigs.luau`, `R15AvatarService.luau`, and `R15AnimationController.luau`.
  - Preview Rig constructed: `game.Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30` (Anchored, `HipHeight = 2.792`, `HeightScale = 1.391`, at position `(0, 4.183, 45)`).
  - Studio released to `Edit` mode.
  - **SOURCE FROZEN:** Implementer source edits are frozen. Codex will independently review and commit verified foundation before any Idle work commences.
  - **STOP GATE:** Awaiting Codex independent review and local commit. Idle authoring by Argon (`w2:p48`) must wait for Codex `COMMIT_DONE`.

---

## Completed Milestone — RF02-CLEANUP-A (Option A Implementation)

- **Execution Contract:** [`cleanup-option-a-HANDOFF.md`](../assets/cleanup-option-a-HANDOFF.md) & [`cleanup-studio-sync-HANDOFF.md`](../assets/cleanup-studio-sync-HANDOFF.md)
- **Status:** **STUDIO_SYNC_AND_FOUNDATION_READY / READY_FOR_OWNER_IDLE_PLANNING (Implementer claim; pending independent Codex review)**
- **Reports:**
  - Implementation Report: [`cleanup-option-a-report-001.md`](../assets/cleanup-option-a-report-001.md)
  - Review 014 Fix Report: [`cleanup-option-a-fix-001.md`](../assets/cleanup-option-a-fix-001.md) (Review 015 Verified)
  - Studio Sync & Readiness Report: [`cleanup-studio-sync-report-001.md`](../assets/cleanup-studio-sync-report-001.md)
  - Studio Sync Fix Report 001: [`cleanup-studio-sync-fix-001.md`](../assets/cleanup-studio-sync-fix-001.md) (Review 016 Fixes: RF-F19, RF-F20)
- **Scope & Engine Verification Delivery:**
  - 10 dedicated legacy files deleted in repo; 3 legacy ModuleScripts deleted in Studio DataModel (`R6ActionPoseController`, `SkillMoveService`, `PlayerActionPoseConfigs`).
  - 3 residual legacy RemoteEvents deleted in Studio DataModel (`SkillMoveRequest`, `SkillMoveReplicate`, `TackleActionRequest`); exactly 12 canonical remotes verified in Edit and fresh Play mode.
  - 7 modified runtime scripts synchronized to Studio with 100% byte/SHA256 parity.
  - 12 protected foundational files verified intact in Studio.
  - Studio Pre-mutation backup preserved at `studio-backup-20261025-1915/` (including `remotes-residual-backup.json`).
  - Bounded local Play mode verified: Custom R6 spawn, native jumping, autonomous free ball (`Workspace.CageMatchBall`), wall collision & rebound reflection at East wall (`X = 81`), 0 Lua runtime errors (1 pre-existing asset warning). Returned to Edit mode cleanly.
  - **STOP GATE:** Awaiting independent Codex review and Owner direction starting from Idle pose first before any R15 or new gameplay authoring.

---

## 1. Context & Evolution

- แผนเดิม Plan 02 มุ่งเน้นการปรับปรุงบนโครงกระดูก R6 ตามคำสั่งก่อนหน้า ทว่าข้อจำกัดของ R6 ในด้านข้อต่อและมุมมองท่วงท่าทำให้ไม่สามารถผ่านเกณฑ์ Owner Visual Review ได้อย่างสมบูรณ์
- เมื่อวันที่ 2026-10-25 Owner มีคำสั่ง Direct Override ให้ยกเลิก Plan 02 และ Plan 03 เดิมทั้งหมด แล้วเริ่มต้นใหม่บน **Custom Blocky R15**
- RF-02 ถูกกำหนดให้เป็นแผนแรกของ Release-First Track เพื่อวางรากฐานทางเทคนิคใหม่ทั้งหมดให้ถูกต้องตั้งแต่ก้าวแรก

---

## 2. Legacy Code Reuse Evaluation

| Component / File ใน Repo จริง | ความเข้ากันได้กับ R15 | แนวทางการจัดการ |
|---|---|---|
| `src/client/controllers/InputController.luau` | ปานกลาง (Medium) | นำ Logic การจับปุ่มและการคำนวณเวกเตอร์กล้องมาปรับใช้ต่อ โดยถอด R6 Action mappings และ pose requires ออก |
| `src/server/services/BallService.luau` | ปานกลาง (Medium) | โครงสร้าง Server Authority และ Heartbeat loop เดิมนำมาต่อยอดได้ แต่ต้องถอด R6 pose hooks ออก และเชื่อม Raycast / Hitbox ให้ตรงกับ R15 Attachment *(หมายเหตุ: `BallService` ณ จุด checkpoint `617f523` มีโค้ด possession/shoot/pass/laserGuidedPass เดิมอยู่ ไม่ใช่ baseline ฟิสิกส์บริสุทธิ์)* |
| `src/client/controllers/CameraShiftLockController.luau` | สูง (High) | การปรับทิศทางตัวละครตามกล้อง (Yaw alignment) นำมาใช้ต่อได้ทันที |
| `src/shared/AirLeanSolver.luau` & `JumpModel.luau` | สูง (High) | สูตรคณิตศาสตร์การเอียงตัวและ State Jump FSM สามารถนำมาประยุกต์ใช้กับ R15 ได้ |
| Segmented Charge Gauge ใน Repo UI | สูง (High) | โครงสร้าง UI เกจชาร์จพลังนำมาต่อยอดได้ |
| R6 Animation Keyframe Sequences (`PlayerActionPoseConfigs.luau`) | ต่ำมาก (Incompatible) | **ไม่สามารถนำมาใช้โดยตรงได้** เนื่องจากโครงสร้างกระดูกและ Motor6D แตกต่างกัน ต้องสร้างใหม่บน R15 หรือใช้เฉพาะเป็น Choreography timing reference |
| *External Prototype: FootballSandbox* | ข้อมูลอ้างอิงภายนอก | โค้ดใน `C:/Users/Stang/FootballSandbox` (`FootballClient.client.luau`, `FootballServer.server.luau`, `ShiftLockDribble.luau`) เป็นเพียง sandbox ต้นแบบภายนอก repo ซึ่งยังไม่ผ่านการ verify ไม่นับเป็นไฟล์ใน codebase |

---

## 3. Unresolved Risks & Mitigations

1. **R15 Ball Dribble Clamping:**
   - *Risk:* การเลี้ยงบอลด้วย R15 อาจเกิดการสะดุดของลูกบอลหาก Hitbox ของเท้าทั้งสองข้างชนกับบอลสลับไปมาอย่างรวดเร็ว
   - *Mitigation:* ใช้ `BallDribbleAttachment` บริเวณกึ่งกลางด้านหน้าของ HumanoidRootPart ร่วมกับการคำนวณ Physical Sweep เพื่อให้ลูกบอลเคลื่อนที่สม่ำเสมอโดยไม่สูญเสียคุณสมบัติทางฟิสิกส์
2. **First-time Whiff Animation Feel:**
   - *Risk:* จังหวะเตะวืดอาจทำให้การควบคุมดูหน่วงหากช่วง Recovery นานเกินไป
   - *Mitigation:* กำหนดค่า Whiff Penalty ใน `BalanceConfig` ให้เป็นตัวแปรที่จูนได้ง่าย (เริ่มต้นที่ 0.25 - 0.35 วินาที)
3. **DataStore Session Concurrency:**
   - *Risk:* การบันทึก PlayerProfile ในระดับรากฐานอาจชนกันหากมีหลายเซิร์ฟเวอร์เปิดพร้อมกัน
   - *Mitigation:* ใช้ Session Locking ผ่าน DataStore UpdateAsync พร้อม version increment
4. **Per-Move Cooldown Alignment (Owner U2):**
   - *Clarification:* ไม่มีระบบ Cooldown รายท่า (No per-move cooldowns) ในระบบเกมเพลย์; การจำกัดการกระทำขึ้นอยู่กับ Stamina pool, Recovery delay, และข้อจำกัดทางกายภาพเท่านั้น

---

## 4. Legacy Plan 02/03 Provisional Removal Inventory (READ-ONLY Discovery)

> [!IMPORTANT]
> **สถานะเอกสารการสำรวจอย่างเป็นทางการ (Gate 1 Deliverable):**  
> รายละเอียดแผนที่การพึ่งพา (Dependency Closure), การระบุ Hunks ระดับบรรทัด, ลำดับการถอดเพื่อป้องกัน Dead Reference, และข้อจำกัดด้านสิ่งแวดล้อม ได้รับการจัดทำอย่างสมบูรณ์ในเอกสารหลัก **[Removal Manifest](../assets/removal-manifest.md)**, **[Discovery Spot Audit (Argon)](../assets/discovery-spot-audit.md)**, **[Discovery Report 001](../assets/discovery-report-001.md)**, **[Discovery Report 002](../assets/discovery-report-002.md)**, **[Discovery Report 003](../assets/discovery-report-003.md)**, **[Discovery Report 004](../assets/discovery-report-004.md)**, **[Discovery Report 005](../assets/discovery-report-005.md)**, และ **[Discovery Report 006 (Gate 1 Review 012 Focused Corrections)](../assets/discovery-report-006.md)** (หมายเหตุ: ข้อความและสถานะทั้งหมดเป็น implementer claim จนกว่า independent review จะรับรอง)](../assets/discovery-spot-audit.md)**, **[Discovery Report 001](../assets/discovery-report-001.md)**, **[Discovery Report 002](../assets/discovery-report-002.md)**, **[Discovery Report 003](../assets/discovery-report-003.md)**, **[Discovery Report 004](../assets/discovery-report-004.md)**, และ **[Discovery Report 005 (Gate 1 Review 011 Exact Boundaries)](../assets/discovery-report-005.md)** (หมายเหตุ: ข้อความและสถานะทั้งหมดเป็น implementer claim จนกว่า independent review จะรับรอง)](../assets/discovery-spot-audit.md)**, **[Discovery Report 001](../assets/discovery-report-001.md)**, **[Discovery Report 002](../assets/discovery-report-002.md)**, **[Discovery Report 003](../assets/discovery-report-003.md)**, และ **[Discovery Report 004 (Gate 1 Review 010 Targeted Closure)](../assets/discovery-report-004.md)** (หมายเหตุ: ข้อความและสถานะทั้งหมดเป็น implementer claim จนกว่า independent review จะรับรอง)](../assets/discovery-spot-audit.md)**, **[Discovery Report 001](../assets/discovery-report-001.md)**, **[Discovery Report 002](../assets/discovery-report-002.md)**, และ **[Discovery Report 003 (Gate 1 Review 009 & Spot Audit Integration)](../assets/discovery-report-003.md)** (หมายเหตุ: ข้อความและสถานะทั้งหมดเป็น implementer claim จนกว่า independent review จะรับรอง)**  
> **สถานะการปฏิบัติการ:** READ-ONLY DISCOVERY ONLY — **หยุดการทำงานก่อนแตะต้องโค้ดจริง (STOP BEFORE CODE DELETION / SOURCE EDITS / NEW GAMEPLAY)** จนกว่า Codex และ Owner จะอนุมัติขอบเขตการทำความสะอาด  
> **ข้อเท็จจริงเรื่อง Checkpoint `617f523`:** คอมมิต `617f523` เป็นเพียง Comparison Checkpoint ไม่ใช่ baseline ฟิสิกส์บริสุทธิ์ (`BallService.luau` ณ จุดนั้นมีโค้ด possession/shoot/pass, shooting-zone, และ `laserGuidedPassActive` อยู่เดิมแล้ว; ส่วน `CagePhysicsService.luau` มี hunk ปรับปรุง `FLOOR_SMASH_RESTITUTION` และ lighting ภายหลัง) ดังนั้นการทำความสะอาดจึง **ห้ามใช้วิธี Restore/Reset ไฟล์ทั้งไฟล์กลับสู่ `617f523`** แต่ต้องระบุ hunk ที่ต้องการถอดอย่างละเอียด
> **การแยกแยะ First Tracked vs Behavioral Origin:** บันทึกแยกชัดเจนระหว่างคอมมิตแรกที่ Git บันทึกไฟล์ (`git log --diff-filter=A`) กับบริบทการเริ่มมีพฤติกรรม (Behavioral Introduction) โดยคอมมิต Bulk Checkpoint (เช่น `25a67d5`) ไม่ใช่หลักฐานว่าโค้ดเพิ่งถูกเขียนขึ้น ณ จุดนั้น

รายการเปลี่ยนแปลง 34 ไฟล์ใน `src` และ `tests` อิงตาม `git diff --name-status 617f523 HEAD -- src tests`:

| # | Path / File | Status in Range | Proposed Action | First Tracked Commit | Commits in 617f523..HEAD | Behavioral Introduction Context | Consumers & Dependencies |
|---|---|---|---|---|---|---|---|
| 1 | `src/client/character/R6ActionPoseController.luau` | Added | **REMOVE** | `4d1ba7a` | `4d1ba7a`, `25a67d5` | ตัวควบคุม Pose R6 เฉพาะท่าเคลื่อนไหว/เลี้ยง/สไลด์ของ Plan 02 | `InputController.luau`, `R6AnimationController.luau` |
| 2 | `src/client/character/R6AnimationController.luau` | Modified | **HUNK REMOVE** | `6502666` (Pre-checkpoint) | `4d1ba7a`, `5c33d5f`, `b579530`, `25a67d5` | ตัวคุม Locomotion เดิม; ถูกแทรก Hunk ต่อเชื่อมกับ R6 Action Pose | Character Rig Bootstrap |
| 3 | `src/client/controllers/CameraShiftLockController.luau` | Added | **REPLACE** | `4d1ba7a` | `4d1ba7a`, `b579530` | ระบบกล้อง Shift Lock หมุนตัวตาม Yaw ใน Plan 02; ปรับปรุงต่อใน `b579530` (เก็บตรรกะไว้ประยุกต์กับ R15) | `init.client.luau`, `InputController.luau` |
| 4 | `src/client/controllers/DuelUIController.luau` | Modified | **UNCERTAIN** | `ec0c94c` (Baseline) | `25a67d5` | UI ดวลเดิม; มี Hunk ถูกแตะใน Bulk Checkpoint `25a67d5` | `DuelChoiceModal.luau`, Duel Event Flow |
| 5 | `src/client/controllers/InputController.luau` | Modified | **HUNK REMOVE** | `ec0c94c` (Baseline) | `4d1ba7a`, `5c33d5f`, `b579530`, `25a67d5` | Controller ควบคุมอินพุตเดิม; ถูกเพิ่ม Keybinds/Actions ของ 02/03 จำนวนมาก ต้องถอดเฉพาะ Hunk คืน baseline | Client Core Controls |
| 6 | `src/client/controllers/InputController.luau.bak_fc27` | Added | **REMOVE** | `25a67d5` | `25a67d5` | ไฟล์สำรองที่บันทึกไว้ใน Bulk Checkpoint `25a67d5` | ไม่มี Consumer |
| 7 | `src/client/controllers/TrainingHUD.luau` | Added | **UNCERTAIN** | `4d1ba7a` | `4d1ba7a`, `b579530`, `25a67d5` | HUD แสดงข้อมูล Debug ใน Plan 02 เริ่มที่ `4d1ba7a` | `init.client.luau` |
| 8 | `src/client/init.client.luau` | Modified | **HUNK REMOVE** | `ec0c94c` (Baseline) | `4d1ba7a` | Client Bootstrap เดิม; เพิ่ม require/init ของ `CameraShiftLock` และ `TrainingHUD` ที่ `4d1ba7a` | Client Startup Entry |
| 9 | `src/client/ui/screens/DuelChoiceModal.luau` | Modified | **UNCERTAIN** | `ec0c94c` (Baseline) | `25a67d5` | Modal หน้าต่างดวลเดิม; มี Hunk ปรับปรุงใน `25a67d5` | `DuelUIController.luau` |
| 10 | `src/server/init.server.luau` | Modified | **HUNK REMOVE** | `ec0c94c` (Baseline) | `25a67d5` | Server Bootstrap เดิม; เพิ่ม require/init ของ `SkillMoveService` ใน `25a67d5` | Server Startup Entry |
| 11 | `src/server/services/BallService.luau` | Modified | **HUNK REMOVE** | `ec0c94c` (Baseline) | `4d1ba7a`, `5c33d5f`, `b579530`, `25a67d5` | เซอร์วิสหลักของบอล; เดิมมี possession/pass/shoot อยู่แล้ว; In-range เพิ่ม pose hooks, state jump, air volley, skill hooks ต้องถอดเฉพาะ Hunk | Core Ball Physics & Cage Interactions |
| 12 | `src/server/services/BallService.luau.bak_fc27` | Added | **REMOVE** | `25a67d5` | `25a67d5` | ไฟล์สำรองที่บันทึกไว้ใน Bulk Checkpoint `25a67d5` | ไม่มี Consumer |
| 13 | `src/server/services/CagePhysicsService.luau` | Modified | **KEEP (Evaluate Hunks)** | `ec0c94c` (Baseline) | `4d1ba7a`, `25a67d5` | เรขาคณิตสนาม A/B/C เป็น Plan 01 foundation; ตรวจสอบ Hunk `FLOOR_SMASH_RESTITUTION` และแสงสว่าง | Stadium Geometry & Ball Collision |
| 14 | `src/server/services/DuelEngineService.luau` | Modified | **UNCERTAIN** | `ec0c94c` (Baseline) | `25a67d5` | เซอร์วิสดวลเดิม; มี Hunk ปรับปรุงใน `25a67d5` | `BallService.luau`, Duel System |
| 15 | `src/server/services/SkillMoveService.luau` | Added | **REMOVE** | `25a67d5` | `25a67d5` | เซอร์วิสสกิลดวล 03 เดิม; บันทึกครั้งแรกใน Bulk Checkpoint `25a67d5` ผูกกับแอนิเมชัน R6 | `init.server.luau`, `BallService.luau` |
| 16 | `src/shared/AirLeanSolver.luau` | Added | **REPLACE** | `b579530` | `b579530`, `25a67d5` | สูตรคณิตศาสตร์ Air Lean ใน Plan 02 เริ่มที่ `b579530` (เก็บตรรกะไว้ใช้กับ R15) | `BallService.luau`, `InputController.luau` |
| 17 | `src/shared/Constants.luau` | Modified | **HUNK REMOVE** | `ec0c94c` (Baseline) | `4d1ba7a`, `5c33d5f`, `b579530`, `25a67d5` | ค่าคงที่กลางเดิม; ถูกเพิ่ม Action/Jump/Skill constants ใน 02/03 | Global Shared Constants |
| 18 | `src/shared/JumpModel.luau` | Added | **REPLACE** | `5c33d5f` | `5c33d5f` | แบบจำลอง State Jump FSM ใน Plan 02 เริ่มที่ `5c33d5f` (เก็บตรรกะไว้ใช้กับ R15) | `BallService.luau`, `InputController.luau` |
| 19 | `src/shared/Network.luau` | Modified | **HUNK REMOVE** | `ec0c94c` (Baseline) | `4d1ba7a`, `5c33d5f`, `b579530`, `25a67d5` | นิยาม Remotes เดิม; ถูกเพิ่ม remotes ของ 02/03 | Client/Server Remotes |
| 20 | `src/shared/Types.luau` | Modified | **HUNK REMOVE** | `ec0c94c` (Baseline) | `4d1ba7a`, `5c33d5f`, `b579530`, `25a67d5` | Type Contracts เดิม; ถูกเพิ่ม types ของ 02/03 | Global Types |
| 21 | `src/shared/configs/AirLeanConfigs.luau` | Added | **UNCERTAIN / REPLACE** | `b579530` | `b579530`, `25a67d5` | ค่าปรับจูน Air Lean เริ่มที่ `b579530` (ย้ายเฉพาะค่าที่จำเป็นเข้า `BalanceConfig`) | `AirLeanSolver.luau`, `BallService.luau` |
| 22 | `src/shared/configs/JumpConfigs.luau` | Added | **UNCERTAIN / REPLACE** | `5c33d5f` | `5c33d5f` | ค่าปรับจูน Jump เริ่มที่ `5c33d5f` (ย้ายเฉพาะค่าที่จำเป็นเข้า `BalanceConfig`) | `JumpModel.luau`, `BallService.luau` |
| 23 | `src/shared/configs/PlayerActionPoseConfigs.luau` | Added | **REMOVE** | `4d1ba7a` | `4d1ba7a`, `5c33d5f`, `b579530`, `25a67d5` | ตาราง Keyframe C0/C1 R6 (3,927 บรรทัด) เริ่มที่ `4d1ba7a` ไม่สามารถใช้กับ R15 ได้ | `R6ActionPoseController.luau` |
| 24 | `src/shared/configs/RigAnimationConfigs.luau` | Modified | **HUNK REMOVE** | `6502666` (Pre-checkpoint) | `4d1ba7a`, `25a67d5` | Config แอนิเมชันเดิม; ถูกเพิ่ม R6 Action Pose Clip IDs ใน `4d1ba7a` คืนสู่ Plan 00 clips | `R6AnimationController.luau` |
| 25 | `src/shared/configs/SkillMoveConfigs.luau` | Added | **UNCERTAIN / REPLACE** | `25a67d5` | `25a67d5` | พารามิเตอร์สกิลดวล 03 เดิม; บันทึกครั้งแรกใน Bulk Checkpoint `25a67d5` (คัดเฉพาะ 3 ท่าเข้า `BalanceConfig`) | `SkillMoveService.luau` |
| 26 | `tests/e2e/BundledTestRunner.luau` | Modified | **HUNK REMOVE** | `617f523` (Checkpoint) | `4d1ba7a` | Runner รวมเดิมที่จุด checkpoint; เพิ่ม require ของ Plan 02 tests ใน `4d1ba7a` | E2E Bundled Testing |
| 27 | `tests/e2e/TestHarness.luau` | Modified | **HUNK REMOVE** | `617f523` (Checkpoint) | `4d1ba7a` | Test Harness เดิม; เพิ่ม Mock Helpers ของ 02 ใน `4d1ba7a` | Test Mocking |
| 28 | `tests/e2e/TestRunner.luau` | Modified | **HUNK REMOVE** | `617f523` (Checkpoint) | `4d1ba7a`, `5c33d5f`, `b579530`, `25a67d5` | Test Runner เดิม; เพิ่มการสั่งรัน 5 ไฟล์ทดสอบ R6 ในช่วง 02/03 | E2E Test Execution |
| 29 | `tests/e2e/Tier1_AirLeanPhysics.luau` | Added | **REMOVE** | `b579530` | `b579530`, `25a67d5` | ชุดทดสอบ R6 Air Lean เริ่มที่ `b579530` | `TestRunner.luau` |
| 30 | `tests/e2e/Tier1_BallPopPhysics.luau` | Added | **REMOVE** | `5c33d5f` | `5c33d5f` | ชุดทดสอบ R6 Ball Pop เริ่มที่ `5c33d5f` | `TestRunner.luau` |
| 31 | `tests/e2e/Tier1_PlayerActions.luau` | Added | **REMOVE** | `4d1ba7a` | `4d1ba7a`, `5c33d5f`, `b579530`, `25a67d5` | ชุดทดสอบ R6 Actions (2,187 บรรทัด) เริ่มที่ `4d1ba7a` | `TestRunner.luau` |
| 32 | `tests/e2e/Tier1_SkillMovesAndDefense.luau` | Added | **REMOVE** | `25a67d5` | `25a67d5` | ชุดทดสอบ R6 Skills & Defense (622 บรรทัด) บันทึกใน Bulk Checkpoint `25a67d5` | `TestRunner.luau` |
| 33 | `tests/e2e/Tier1_StateJumpPhysics.luau` | Added | **REMOVE** | `5c33d5f` | `5c33d5f`, `25a67d5` | ชุดทดสอบ R6 State Jump เริ่มที่ `5c33d5f` | `TestRunner.luau` |
| 34 | `tests/e2e/run_all.ps1` | Modified | **HUNK REMOVE** | `617f523` (Checkpoint) | `b579530` | สคริปต์ PowerShell รันการทดสอบเดิม; เพิ่มการสั่งรัน Plan 02 tests ใน `b579530` | CLI Test Execution |

*(หมายเหตุสำคัญ: ไฟล์ `tests/e2e/Tier1_FeatureCoverage.luau` มีอยู่ก่อน Plan 02 เป็นชุดทดสอบรากฐานของ Plan 00/01 **ต้องคงรักษาไว้ (KEEP)** ห้ามใช้คำสั่งลบแบบ Wildcard `Tier1_*.luau` เด็ดขาด)*

---

### นโยบายโมเดลและขั้นตอนการปฏิบัติการ
- **รอบปัจจุบัน:** จัดเตรียมเอกสารและ Provisional Inventory เท่านั้น (Documentation Only) ยังไม่อนุมัติการถอดโค้ดจริง
- **ผู้รับผิดชอบการถอดโค้ดจริง (ลำดับถัดไป):** `agyanimation` ใช้โมเดล **3.8 Flash** เป็นค่าเริ่มต้นเมื่อยืนยัน pane identity แล้ว
- **การใช้โมเดล Argon:** อนุญาตเฉพาะจุดที่มี dependency ซับซ้อนและโมเดล Flash ชี้หลักฐานปัญหาชัดเจนเท่านั้น
- **การรายงาน:** ไม่มี monitoring; ส่ง push callback อัตโนมัติเมื่อ READY_FOR_REVIEW / BLOCKED / ต้องการ Owner decision ไปยัง Controller (w2:p43) พร้อม Enter ตาม Latest Owner Reporting Override

---

## 5. Player Avatar R15 Normalization Seams & Unresolved Details (Owner Target Delta 2026-10-25)

> [!IMPORTANT]
> **Owner Directive:** ปรับเปลี่ยน Target Rig จาก Game-owned Custom Blocky R15 เป็น **Player Avatar R15 (Normalized to Same Body Dimensions)** โดยผู้เล่นใช้ Avatar ส่วนตัวแต่ถูกปรับมิติร่างกายให้เท่ากันทั้งหมด; บันทึก Seams ทางเทคนิคและประเด็นที่ยังรอการทดสอบจริง ห้ามคาดเดาผลการทดสอบ

### 5.1 Technical Seams Analysis

1. **Scale Numbers vs Physical Dimensions & API Targets Seam ([RF-F07]):**
   - **การแยกแยะ API Properties vs Child NumberValues อย่างเด็ดขาด:**
     - ใน Roblox R15 คุณสมบัติสเกลของ [`HumanoidDescription`](https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription) ได้แก่ `HeightScale`, `WidthScale`, `DepthScale`, `HeadScale`, `ProportionScale`, และ `BodyTypeScale` (ไม่มีคำนำหน้า `Body` ยกเว้น `BodyTypeScale`)
     - ส่วนอินสแตนซ์สเกลที่มีคำนำหน้า `Body` ได้แก่ `BodyHeightScale`, `BodyWidthScale`, `BodyDepthScale`, `BodyProportionScale`, `BodyTypeScale` (รวมถึง `HeadScale`) เป็นอินสแตนซ์ประเภท `NumberValue` ที่เป็น **ลูก (Children) ของ [`Humanoid`](https://create.roblox.com/docs/reference/engine/classes/Humanoid)** โดยตรง ไม่ใช่พร็อพเพอร์ตี้ของ `HumanoidDescription`
     - ผู้พัฒนาระบบ (Worker) ต้องไม่พยายามกำหนดค่า `HumanoidDescription.BodyHeightScale` เพราะจะเกิด runtime error จากการเข้าถึง property ที่ไม่มีอยู่จริง
   - **ข้อจำกัดเชิงมิติกายภาพ (Physical Dimensions):** แม้จะกำหนดสเกลตัวเลขของ `HumanoidDescription` (เช่น `HeightScale = 1.0`, `WidthScale = 1.0`, `DepthScale = 1.0`, `HeadScale = 1.0`) หรือค่าใน `NumberValue` ให้เท่ากันทุกตัวละคร **ก็ไม่ได้รับประกันว่าขนาดมิติทางกายภาพจริง (Physical Bounding Box / Extents) จะเท่ากัน** เมื่อผู้เล่นสวมใส่ Arbitrary Body Packages หลากหลาย (เช่น Man, Woman, Boy, Rthro, Anime rigs, และ Layered Clothing)
   - โมเดล Rthro หรือ Stylized packages มีความยาวแขนขาและ Bounding Box ที่ต่างจาก Classic Blocky แม้ตัวเลขสเกลจะเป็น 1.0 เท่ากัน จึงจำเป็นต้องมีกระบวนการ Normalization ทางกายภาพเสริม

2. **Normalization & Permitted Body Packages Seam (Unresolved Visual Package Details):**
   - จำเป็นต้องมี Normalization Pipeline ที่ปรับขนาด Physical Bounding Box และ Hitbox ของผู้เล่นทุกคนให้เท่ากันอย่างแท้จริง
   - **ประเด็นที่ยังต้องทดสอบจริงใน Studio (Unresolved):** รูปแบบการรองรับ Body Packages (อนุญาตทุกแพ็กเกจแล้ว Clamp สเกล, หรือจำกัดเฉพาะแพ็กเกจ R15 มาตรฐาน, หรือใช้ Invisible Standard Hitbox ครอบตัว Avatar) ต้องผ่านการทดสอบ Visual & Physics Parity ใน Studio ในขั้นตอนถัดไป ไม่คาดเดาผลลัพธ์ล่วงหน้า

3. **Ball Contact & Uniform Collision Geometry Seam:**
   - การเตะ, การสัมผัสบอล (Dribble/Trap), การแย่งบอล (Poke), และ Slide Tackle ต้องใช้เรขาคณิตการชน (Collision Geometry) ที่มีขนาด ตำแหน่ง และระยะการสัมผัสเท่าเทียมกันทุกผู้เล่น
   - ต้องป้องกันไม่ให้ผู้เล่นที่เลือก Avatar ขนาดเล็กหรือผอมบางได้เปรียบทาง Hitbox หรือเกิดความเหลื่อมล้ำในการสัมผัสบอล

4. **Joint Attachments & Motor6D Seam:**
   - จุดต่อสำคัญสำหรับการเล่นบอล เช่น `BallDribbleAttachment`, `LeftFootSocket`, `RightFootSocket`, `HeadContactAttachment` ต้องมีตำแหน่งสัมพัทธ์ที่ได้มาตรฐานและสม่ำเสมอ
   - ต้องตรวจสอบตำแหน่ง Offset บน Motor6D เมื่อสวมใส่ชิ้นส่วนร่างกายแพ็กเกจต่าง ๆ เพื่อไม่ให้จุดสัมผัสบอลคลาดเคลื่อน

5. **Animation Retargeting & Visual Consistency Seam:**
   - แอนิเมชัน Locomotion, Dribble, Shoot, Pass, Slide ที่เล่นบนโครงสร้างกระดูก R15 อาจเกิดอาการเท้าจมพื้น (Foot clipping) หรือเท้าลอย (Foot floating) เมื่อใช้กับแพ็กเกจที่มีความยาวแขนขาต่างกัน
   - ต้องวางแผน Retargeting Calibration บน R15 ใน Roblox Studio

6. **Respawn, Appearance Readiness & Normalization Lifecycle Seam ([RF-F08]):**
   - **Readiness Check + Event Dual-Path:** เพื่อป้องกันปัญหาการพลาดอีเวนต์กรณีที่รูปลักษณ์ของ Avatar โหลดเสร็จสิ้นแล้วก่อนการ Subscribe (Already-loaded character) ระบบต้องใช้กลไกตรวจสอบคู่ขนาน:
     1. ตรวจสอบสถานะความพร้อมปัจจุบันผ่าน [`Player:HasAppearanceLoaded()`](https://create.roblox.com/docs/reference/engine/classes/Player#HasAppearanceLoaded) ทันทีที่เชื่อมต่อตัวละคร
     2. รับฟังอีเวนต์ [`Player.CharacterAppearanceLoaded`](https://create.roblox.com/docs/reference/engine/classes/Player#CharacterAppearanceLoaded) สำหรับกรณีที่รูปลักษณ์ยังโหลดไม่เสร็จ
   - **Current-Character Generation Tracking:** ระบบต้องสร้าง Generation Token / Spawn ID กำกับทุกครั้งที่ตัวละครเกิด เพื่อตรวจสอบว่า callback ที่ทำงานแบบ asynchronous เป็นของตัวละครปัจจุบันหรือไม่ หากตัวละครตายหรือถูกแทนที่ (Character replaced / respawned) ระหว่างที่กำลังโหลด ให้ทิ้ง (discard) callback ที่ล้าสมัยทันที
   - **Cleanup on Respawn & Disconnect:** เชื่อมต่อ `CharacterRemoving` และ `PlayerRemoving` เพื่อยกเลิก connection ทำลาย token และลบ collision box หรือ attachments ชั่วคราว ป้องกัน memory leak และการตกค้างของวัตถุ
   - **Idempotent Normalization Pipeline:** ฟังก์ชันการ Normalize ต้องมีความเป็น Idempotent (การเรียกซ้ำบนตัวละครเดิมต้องไม่ทำให้เกิดการเพิ่ม Attachment ซ้ำซ้อน หรือสเกลซ้อนทับกัน)
   - **Preserve Player Visual Identity While Pending:** ในระหว่างที่กระบวนการ Normalization กำลังทำงาน รูปลักษณ์และเสื้อผ้าส่วนตัวของผู้เล่นจะยังคงถูกแสดงผลตามปกติ ไม่ถูกรีเซ็ตหรือลบทิ้ง
   - **Bounded Fallback & Critical Safety Invariant:**
     - มี Bounded Timeout กำหนดระยะเวลาการรอโหลดที่ชัดเจน
     - **กฎความปลอดภัยเด็ดขาด (Strict Invariant):** หากเกิดกรณี Timeout หรือความล้มเหลวในการโหลดรูปลักษณ์/Normalize **ระบบต้องไม่ปล่อยให้ตัวละครที่ไม่ผ่านการ Normalize เข้าสู่เกมเพลย์โดยเด็ดขาด (Never silently grant gameplay to an unnormalized character on timeout)**
     - ผู้เล่นที่ติดสถานะ Timeout จะต้องถูกคงไว้ในสถานะ Non-gameplay (เช่น Spectator / Loading State หรือใช้ Fallback Neutral Rig มาตรฐานแทนชั่วคราว) จนกว่าการตรวจสอบ Hitbox/Geometry ที่ได้มาตรฐานจะผ่านการรับรอง
   - *(หมายเหตุ: กลไกข้างต้นเป็นข้อเสนอแนะเชิงโครงสร้างสัญญาความปลอดภัย ยังไม่มีการอ้างอิงผลการทดสอบจริงใน Studio ในรอบเอกสารนี้)*

7. **Accessory & Clothing Occlusion / Collision Seam:**
   - หมวก, ปีก, เครื่องประดับหลัง, และ Layered Clothing ของผู้เล่นอาจขัดขวางฟิสิกส์ของลูกบอล
   - ต้องบังคับปิดฟิสิกส์ของเครื่องประดับทุกชิ้นอย่างเคร่งครัด: `Accessory.Handle.CanCollide = false`, `CanTouch = false`, `CanQuery = false`
   - ต้องประเมินแนวทางแก้ไขกรณีเครื่องประดับขนาดใหญ่บดบังมุมมองกล้องหรือมุมมองการเล่น

8. **Team Readability Seam:**
   - เนื่องจากผู้เล่นใช้อวาตารของตนเอง ทำให้สีสันและเสื้อผ้ามีความหลากหลาย ไม่สามารถแยกทีม 2v2 ด้วยเสื้อผ้าของผู้เล่นได้โดยตรง
   - ต้องออกแบบ Seam สำหรับแสดงผลสังกัดทีม เช่น Over-head Team Marker / Nameplate ที่ชัดเจน หรือ Virtual Team Jersey / Pinnies Vest Overlay

9. **Character Stats & Cards Decoupling:**
   - สถิติตัวละครทั้ง 13 ค่า และ Character Cards (เช่น Messi, Haaland) **ไม่เปลี่ยนแปลงขนาดทางกายภาพหรือมิติร่างกายของผู้เล่น**
   - ผู้เล่นทุกคนในสนามมีขนาดร่างกายเท่ากันเสมอเพื่อความยุติธรรมในเกมเพลย์ฟุตบอล (ค่า Scale ตัวละครในอดีต เช่น Messi 0.92, Haaland 1.08 เป็นเพียงเอกสารอ้างอิงเชิงทฤษฎีในอดีต ไม่นำมาใช้สเกลโมเดลจริง)

---

## 6. Assisted Aerial Control & Trajectory Guidance (Owner Design Delta 2026-10-25)

> [!IMPORTANT]
> **Owner Decisions Integration:** สรุป 4 ข้อยุติการออกแบบระบบช่วยรับบอลกลางอากาศและเส้นวิถีลูกบอลตาม [aerial-control-owner-decisions.md](../assets/aerial-control-owner-decisions.md) เพื่อผสานเข้ากับโครงสร้าง RF-02

### 6.1 พฤติกรรมที่ได้รับการรับรอง (Accepted Behaviors)

1. **Contact-gated Aerial Reception with Relative Speed Limit (Q1 Recommended):**
   - **ข้อยกเว้นต่อกฎ Blanket No-Auto-Catch:** อนุญาตให้รับบอลกลางอากาศได้แบบมีเงื่อนไข โดยผู้เล่นที่กระโดด (Jump) หรือพุ่งจากกำแพง (Wall Launch) จะสามารถเข้าครอบครองบอลกลางอากาศและเริ่มง้างยิงได้ก็ต่อเมื่อ **เกิดการสัมผัสจริงกับ Hitbox ลูกบอล** และ **ความเร็วสัมพัทธ์ในการเข้าหาบอล (Player-Ball Relative Approach Speed) อยู่ในขอบเขตที่กำหนด** โดยสูตรการประมาณการความเร็วสัมพัทธ์ที่แน่นอน (เช่น ค่าขนาดความเร็ว 3D Magnitude $|v_{player} - v_{ball}|$ เทียบกับ Radial Closing Component ในแนวการเข้าหา) เป็น **PROPOSED implementation choice / technical contract pending** ที่ยังไม่ถือเป็นมติตัดสินตายตัวจาก Owner
   - **การสะท้อนเมื่อความเร็วเกินเกณฑ์:** หากความเร็วสัมพัทธ์สูงเกินเกณฑ์กำหนด ลูกบอลจะกระดอนสะท้อนออกเป็น Loose Ball / Deflection ไม่เกิดการครอบครอง
   - **ไม่ใช่เงื่อนไขความเร็วขั้นต่ำ:** เงื่อนไขนี้ไม่ใช่การบังคับให้ผู้เล่นต้อง Sprint ด้วยความเร็วขั้นต่ำเพื่อปลดล็อก
   - **การตรวจสอบฝั่งเซิร์ฟเวอร์:** Server เป็นผู้ตรวจสอบการสัมผัสและความเร็วสัมพัทธ์อย่างเข้มงวด **ห้ามมิให้มีการวาร์ปหรือเทเลพอร์ตบอลเข้าตัวจากระยะไกลโดยเด็ดขาด**

2. **Brief Aerial Aiming Hold (Q2 B):**
   - **การลอยค้างเล็งชั่วครู่:** เมื่อรับบอลกลางอากาศสำเร็จ ผู้เล่นจะเข้าสู่ช่วงเวลาลอยค้างสั้น ๆ ที่มีขอบเขตจำกัด (Finite & Bounded Hold Duration) สำหรับการเล็ง 3D และง้างยิง (Windup) ก่อนจะกลับสู่แรงโน้มถ่วงและร่วงลงพื้นตามปกติ ทั้งนี้ การระงับแรงโน้มถ่วงชั่วคราว (Suspending gravity) เป็นเพียงหนึ่งในกลไกที่เป็นไปได้ (Proposed mechanism) ซึ่งอาจไม่เพียงพอต่อการหยุดความเร็วในแนวดิ่ง (Vertical Velocity) ที่มีอยู่เดิม; กลไกทางฟิสิกส์ที่แท้จริง (เช่น การ Dampen ความเร็วแนวดิ่ง หรือการใช้ LinearVelocity/VectorForce) รวมถึงการคืนแรงส่งและโมเมนตัม (Momentum Restoration) มีสถานะเป็น **PROPOSED technical contract pending**
   - **การแทนที่กติกาเดิม:** กติกานี้แทนที่ข้อกำหนดเดิมที่บังคับให้ตัวละครต้องร่วงลงตามปกติเสมอ (Supersedes always-fall-normally เฉพาะ action นี้)
   - **การคงสภาพการแย่งบอลและความโปร่งใส:** ลูกบอลต้องมองเห็นได้ชัดเจนและมี Hitbox ที่คู่แข่งสามารถกระโดดบล็อก แย่ง หรือสกัดได้ตลอดเวลา
   - **ไม่มีสิทธิ์อมตะและไม่มีคูลดาวน์:** ไม่มี I-frame, ไม่มีผลชนะทางอัตโนมัติ, ห้ามมีระบบบินต่อเนื่องไม่จำกัด (No infinite flight) และห้ามเชื่อมต่อการลอยค้างซ้ำซ้อน (No stall chaining) โดยยังคงไม่มี per-move gameplay cooldown

3. **Live Trajectory Guide + Landing Marker & Prerelease Aim Preview (Q3 Recommended B):**
   - **การมองเห็นสำหรับทุกคน (All Players):** ผู้เล่นทุกคนในสนามสามารถมองเห็นเส้นวิถีโค้งพยากรณ์ของลูกบอลลอยฟ้า (Predicted Curved Trajectory) และจุดตกกระทบพื้น (Landing Marker) รวมถึงการคำนวณการชิ่งสะท้อนผนังและเพดาน Stadium A ล่วงหน้า
   - **การคำนวณใหม่แบบเรียลไทม์:** เส้นทางและจุดตกจะถูกคำนวณใหม่ทันทีเมื่อสถานะลูกบอลเปลี่ยน หรือเมื่อเกิดการสัมผัส/สกัด/ชนสิ่งกีดขวาง
   - **Prerelease Aim Preview:** ผู้เล่นที่กำลังง้างยิง (Windup / Charge) ไม่ว่าจะอยู่บนพื้นหรือกลางอากาศ จะมองเห็นเส้นวิถีเล็งและจุดตกจำลองเฉพาะบนหน้าจอของตนเองในระหว่างการชาร์จ (General shooter-only preview ไม่จำกัดเฉพาะคนยิงกลางอากาศ ขณะที่ Aerial Hold เป็นแอ็กชันเฉพาะกลางอากาศ)
   - **ข้อจำกัดเชิงเทคนิค:** เส้นวิถีและจุดตกเป็นเพียงไกด์นำสายตา (Visual Guidance) ไม่ใช่แรงบังคับฟิสิกส์ และไม่รับประกันผลลัพธ์ในอนาคต

4. **Goalkeeper Skill through Physical Contact (Q4 Recommended A):**
   - ผู้รักษาประตูต้องเคลื่อนที่เข้าสู่ตำแหน่ง จังหวะ และมี **Physical Contact สัมผัสกับลูกบอลจริงในระยะที่ถูกต้อง** จึงจะเซฟประตูได้
   - การพุ่งตัวถูกทิศทางเพียงอย่างเดียวไม่การันตีว่าจะเซฟบอลได้ (No correct-direction guaranteed save)
   - ไม่ถือเป็นข้อผูกมัดว่าทุกลูกยิงต้องเซฟได้จากทุกตำแหน่ง และ **ไม่มีการเพิ่ม Goalkeeper AI เข้ามาเป็นข้อกำหนดของ Alpha Launch** (โกล AI ยังคงเลื่อนไป Phase 2 ตามเดิม)

### 6.2 Finite State Machine, Required Invariants & Proposed Policies
- **ลำดับสถานะกลางอากาศ (Airborne State Progression):**
  `FreeAirborne` $\rightarrow$ (Contact Hitbox + Relative Speed $\le$ Limit) $\rightarrow$ `AerialHoldAiming` (จับเวลาถอยหลัง Finite Bounded Hold) $\rightarrow$ `AirborneShotReleased` หรือ `AerialHoldExpired` $\rightarrow$ `DescentFalling` $\rightarrow$ `LandingRecovery`
- **ข้อกำหนดไม่แปรเปลี่ยนที่บังคับใช้ (Required Invariants):**
  - **Finite & Bounded Duration:** การลอยค้างต้องมีกรอบเวลาจำกัดที่สิ้นสุดแน่นอนเสมอ ห้ามลอยค้างไม่จำกัด (No infinite flight) และห้ามเชื่อมต่อการลอยค้างซ้ำซ้อน (No stall chaining)
  - **Contestable Ball & No I-Frame:** ลูกบอลต้องมองเห็นได้ชัดเจนและมี Hitbox ทางกายภาพที่คู่แข่งสามารถแย่ง/สกัดได้ตลอดเวลา ไม่มีสถานะอมตะ (No I-frame)
  - **Cleanup Contract:** เมื่อตัวละครตาย (Death), เกิดใหม่ (Respawn), ลงสู่พื้น (Landing), หรือหลุดจากการเชื่อมต่อ (Disconnect) ระบบต้องยกเลิกและล้างสถานะกลางอากาศทันที และปล่อยลูกบอลเป็นอิสระ ห้ามเกิดกรณีตัวละครลอยค้างกลางอากาศค้างเติ่งจากความล่าช้าของเน็ตเวิร์ก
- **นโยบายการเปลี่ยนผ่านที่รอข้อสรุป (PROPOSED Policies — Technical Design / Owner Choice Pending):**
  - **การชนกำแพงระหว่าง Hold (Wall Collision):** ข้อเสนอให้ยกเลิกสถานะ Hold ทันทีเมื่อชนกำแพง ถือเป็น **PROPOSED policy / technical design pending** เพื่อรอทดสอบความรู้สึกลื่นไหลในการเล่นจริง (Feel)
  - **การปะทะกับคู่แข่งระหว่าง Hold (Opponent Contact & Tackling):** บอลที่แย่งได้ (Contestable) หมายถึงการเข้าสกัดที่ผ่านการตรวจสอบสำเร็จ (Validated successful tackle) เท่านั้นที่จะแย่งการครองบอลได้ ส่วนการสัมผัสเพียงผิวเผินหรือเฉียดกัน (Incidental contact) ไม่ทำให้บอลหลุดมือหรือเสียการครองบอลโดยอัตโนมัติ นโยบายการปะทะระหว่าง Hold จึงเป็น **PROPOSED transition policy / Owner choice pending** ไม่ใช่กติกาตายตัวที่รับรองแล้ว

### 6.3 ค่าพารามิเตอร์ที่รอการทดสอบปรับจูน (Tuning & Technical Contract Pending)
- ค่าขอบเขตความเร็วสัมพัทธ์ (Relative Speed Limit), ระยะเวลาลอยค้าง (Hold Duration Sec), แรงส่งเมื่อยิง (Release Momentum), กรอบเวลาป้องกันการรับซ้ำ (Re-entry Protection Window) และขอบเขตระยะพยากรณ์วิถีบอล (Predictive Horizon) มีสถานะเป็น **PENDING Empirical Tuning** ในขั้นตอนพัฒนา ไม่กำหนดตัวเลขลอย ๆ ขึ้นมาเองโดยไม่มีการทดสอบจริงใน Studio
- แยกบทบาท Server/Client ชัดเจน: การคำนวณ Visual Trajectory บน Client ไม่มีสิทธิ์มอบการครองบอลหรือตัดสินผลการเซฟประตู
