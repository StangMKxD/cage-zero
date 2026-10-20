# Notes — 00-bootstrap-and-rig

## Owner pause — 2026-10-20

Ownerตอบ “พักรอบ 00 ก่อน” หลังได้รับreview010 สถานะPAUSED_BY_OWNER หยุดcorrection/runtimeverification/dispatchจนกว่าจะสั่งresume เก็บsource/dirtyfiles/bundles/reviewsทั้งหมดตามเดิม F18/F19ยังOPENและไม่ถือว่าผ่านgate ไม่มีcommit/pushผลงาน00จากการพักนี้

## Current independent verdict — review010 / 2026-10-20

ตรวจfix009/manifestSHA256ตรงผู้ใช้และliveStudio43e07a67...Editอ่าน9/9hashตรงrepo ตรวจhashrepo/pre/post45รายการผ่าน typed19attributesไม่เป็นnullแล้ว แต่F18ยังOPENเพราะRound3rollback4sourcepathsไม่มีไฟล์และWorldPivotที่อ่านสด4.5ต่างจากpost5 (GetPivot=5) F19REOPENEDเพราะV03sizesคูณheightทุกแกนขัดCardConfigsที่แยกwidth/depth และAPI/fields/errorในprobesบางตัวไม่มีในsourceที่lock; Network.Initdurationไม่ใช่overallbootstrap ข้อมูลPASSในsubmission/historyด้านล่างยังไม่ใช่independentacceptance ดู[review010](assets/review-010.md)สำหรับexpected/source/probeที่ต้องแก้ รอOwnerวินิจฉัย3-Strikeก่อนRound5 คงrun01ACCEPTED_GAP ไม่แก้source/CardConfigsเพื่อทำรายงานเก่าให้ผ่าน

## Current decisions — 2026-10-20
- ผู้ใช้ให้ Codex ปรับแผน/architecture และตอบ “ใช้ R6 ตลอด Phase 1 (แนะนำ)” design scope ตกลงแล้ว; ต่อมา Stang สั่ง “เริ่มเลย” อนุมัติ AGY implementation/verification เฉพาะ00 ส่วน Git/แผนอื่นยังไม่อนุมัติ
- ใช้ Custom R6 ของเกมและ standard locomotion clips คงหน้าอนิเมะ/No Boots และ presets 0.92/0.98/1.03/1.08; ผู้เล่นเริ่ม Ronan_TierB ไม่เพิ่ม UI/กาชา
- Server เป็นเจ้าของ template/scale/spawn/respawn; client R6AnimationController เล่น clips ผ่าน server-created Animator ทุกแผนใช้ PrimaryPart=HumanoidRootPart ไม่อ้าง R15 limbs
- R6 ground height = Left Leg.Size.Y + HRP.Size.Y/2 + HipHeight (relative offset); ไม่คัดสูตร R15 2.0*scale
- คง Network getters/12 Definitions; Init ใหม่ใช้ deadline รวม 10s; ไม่เปิด deferred inventory/gacha handlers ใน 00 สลับ preset จาก server fixture
- 00 ใช้พื้นทดสอบขั้นต่ำ; 01 เปลี่ยน explicit floor เป็น Workspace.HexCageArena.CageFloor ก่อน rig Init โดยไม่เปลี่ยน lifecycle API
- [Plan](plan.md)/[tasks](tasks.md)/[HANDOFF](assets/HANDOFF.md) เป็นสัญญา R6 ปัจจุบัน ไม่ส่งข้อเสนอ R15 599 บรรทัดวนแก้อีก

## Source/review delta
| เดิม | Target รอบนี้ | ข้อจำกัด |
| --- | --- | --- |
| R15: 16 parts/15 joints | R6: 7 BaseParts รวม HRP / 6 Motor6Ds | source ยังไม่แก้ ต้องตรวจ topology/clip จริงตอน implement |
| BuildStandardCustomR15Rig | BuildStandardCustomRig | ผู้เรียกอยู่ภายใน service เดิม; consumers GetEquippedCardConfig ฯลฯ คงเดิม |
| animation proposal เก่า | client R6AnimationController + shared RigAnimationConfigs | เพิ่ม source 2 ไฟล์ ไม่เพิ่ม remote/UI framework |
| sandbox prototype | read-only reference | source 7/7 ตรง local current ณ snapshot review-003 ไม่ใช่ runtime pass |
| review-001..006 ของ R15 | คงหลัก bootstrap/rollback/scope เปลี่ยน skeleton-specific gates | asset/runtime/visual R6 ยัง NOT VERIFIED |

> **Historical baseline notes:** ข้อมูลด้านล่างเป็นประวัติเดิมก่อนย้าย/แยก phase และก่อนคำสั่ง R6 ล่าสุด ผลตรวจ/สถานะเก่าไม่ใช่การรับรองแผนใหม่

# Technical Notes — MODULE 00: `00-bootstrap-and-rig`

- **2026-10-18 (Acceptance & Bootstrap):** เริ่มดำเนินการ `MODULE 00: 00-bootstrap-and-rig` ตาม `startprojects.md`
- **Git Setup:** ตั้งค่า Repository ที่ `C:\Users\Stang\cage-zero` เชื่อมต่อ `origin` ไปยัง `https://github.com/StangMKxD/cage-zero.git` บนกิ่ง `main` เรียบร้อยแล้ว
- **Task 00.1 (`[x]`):** สร้าง `agent.md` ที่ Root และโครงสร้างเอกสารทั้งหมดใน `docs/context/`, `docs/prd/`, `docs/specs/`, `docs/design/`, `docs/tdd/`, และ `docs/plan/` (ครบทั้ง 9 Modules `00` ถึง `08`)
- **Task 00.2 (`[x]`):** สร้าง `default.project.json` สำหรับ Rojo 7.7.1 และโครงสร้างไฟล์ใน `src/client`, `src/server`, `src/shared` ครบ 100% ตามแผนผังส่วนที่ 2 (ไฟล์ของ Module `01`–`08` เป็นโมดูลตั้งต้น `--!strict` ที่ไม่มีลอจิกเกินขอบเขต)
- **Task 00.3 (`[x]`):** เขียน `src/shared/Types.luau`, `src/shared/Constants.luau`, และ `src/shared/Network.luau` กำหนด RemoteEvents/RemoteFunctions ครบทั้ง 12 รายการตามตารางส่วนที่ 4.8
- **Task 00.4 (`[x]`):** เขียน `src/server/services/RigAndCardService.luau` และ `src/shared/configs/CardConfigs.luau` ปิด `Players.CharacterAutoLoads = false`, บังคับสร้าง `Single Custom R15 Rig` มาตรฐานเดียวพร้อมล็อกใบหน้าสไตล์อนิเมะ (`AnimeFaceLocked = true`), และปรับขนาดชิ้นส่วนรวมถึงออฟเซ็ต `Motor6D` (`C0`/`C1`) ตาม `HeightScale` / `WidthScale` ของการ์ดนักเตะ (`Leon = 0.92`, `Ney = 0.98`, `Ronan = 1.03`, `Vandik = 1.08`) โดยกระดูกไม่เพี้ยน
- **Verification:** ทดสอบคอมไพล์โปรเจกต์ด้วย `rojo sourcemap` และ `rojo build default.project.json` ผ่านสมบูรณ์ (`0 errors`)


## Implementation authorization — 2026-10-20
Stang สั่ง “เริ่มเลย” หลังได้รับ plan/HANDOFF R6 จึงเปิด P-03 เฉพาะ00 ให้ AGY ทำ source/Studio/verification ตามขอบเขตเดิม Codex เป็น Controller/Reviewer ไม่มีการอนุมัติ local commit/push/merge/deploy หรือเรียก agents เพิ่มโดยอัตโนมัติ ขณะบันทึกยังไม่ dispatch เข้า AGY และ source ยังไม่มี diff

## AGY Implementation Execution Record — 2026-10-20
- **Implementer:** AGY Teamwork-preview
- **Session ID:** `e86ac30e-006d-4338-9a90-5f5e3b002028`
- **Run ID:** `run-phase00-agy-impl-01`
- **Status:** `CHANGES_REQUESTED` — Codex review-007 ตรวจแล้ว; F-13–F-19 OPEN / correction Round2
- **Scope executed:**
  - S1: `src/shared/Constants.luau` (R6 profile, floor/spawn constants), `src/shared/Network.luau` (Network.Init with 10s budget and 12-remote validation), `src/server/init.server.luau` (decoupled to only Network & RigAndCardService), `src/server/services/RigAndCardService.luau` (R6 builder, 7 parts, 6 joints, drift-free C0/C1 scaling, GetStandingHeight, BootstrapTestFloor resolution, filtered raycast, generation race guard, out-of-bounds detection).
  - S2: `src/shared/configs/RigAnimationConfigs.luau` (official native R6 clip profiles & provenance), `src/client/character/R6AnimationController.luau` (ModuleScript lifecycle, Animator wait, cross-fading, cleanup), `src/client/init.client.luau` (bootstrapper decoupled to only Network & R6AnimationController).
  - S3: `rojo sourcemap` and `rojo build default.project.json` passed with 0 errors. Rollback pre/post snapshots stored in `.sandbox/rollback/run-phase00-agy-impl-01/`. Gates V-01..V-07 recorded.
- **Constraints preserved:** No local commits, no push, no merge, no deploy. No Phase 01/07/Phase 2 changes. Pre-existing dirty files preserved.

## Independent review 007 — 2026-10-20

Codexยืนยัน source9/9ในPlace1 Editตรงrepo และ template7parts/6joints; พบ F-13–F-19 ตาม [review-007](assets/review-007.md) ยังไม่ sign-off00 ข้อความ sourceยังไม่แก้/ไม่มีsessionในบันทึกก่อนหน้าเป็น historical handoff baseline ไม่ใช่สถานะปัจจุบัน Runtime/buildด้านบนเป็นผลที่ AGYรายงาน ยังต้องreconcile measured results/ข้อจำกัดตามF-19; visual/multi-client NOT VERIFIED ใช้ HANDOFFเดิมส่งแก้หนึ่งไฟล์ fix-007.md

## Correction Round 2 Execution Record (F-13 – F-19) — 2026-10-20
- **Implementer:** AGY Teamwork-preview
- **Session ID:** `e86ac30e-006d-4338-9a90-5f5e3b002028`
- **Run ID:** `run-phase00-agy-impl-01`
- **Correction Round:** Round 2
- **Status:** `READY_FOR_REVIEW` — Submitted for Codex independent review in [fix-007.md](assets/fix-007.md)
- **Corrections implemented & verified:**
  - **F-13:** Disconnected `InventoryEquipRequest.OnServerEvent` listener from `RigAndCardService.Init()`. Public `EquipCardForPlayer` API preserved for server preset fixtures.
  - **F-14:** Reordered `Network.Init(remaining)` before `require(R6AnimationController)` in `init.client.luau`. Passed explicit `remaining` budget to all child waits. Removed all top-level unbounded `WaitForChild` calls from `R6AnimationController.luau`, resolving configs with bounded timeout.
  - **F-15:** Added `validateFloorPart()` checking `IsA("BasePart")`, `Anchored == true`, `CanCollide == true`, `CanQuery == true`, and minimum support dimensions. `GetPrimaryFloor()` throws explicit errors on invalid primary without silent fallback. `calculateSpawnCFrame()` computes OBB bounding extents for oriented/elevated floors, verifies surface normal (`Normal.Y >= 0.70`), validates margins on actual hit position, and aggregates candidate rejection logs.
  - **F-16:** Added `SetupToken` with `cancelled` flag and per-generation tracking in `R6AnimationController.luau`. `cleanupCurrentCharacter()` increments generation and invalidates active token upon `CharacterRemoving`, died, or ancestry change. `isSetupValid()` guards all yields.
  - **F-17:** Added `REQUIRED_STATES` (`idle`, `walk`, `jump`, `fall`) validation in `R6AnimationController.luau`. Replaced invalid `track.IsLoaded` with safe `isTrackAssetLoaded` (`Length > 0`). If `animator:LoadAnimation` fails or required asset fails loading, setup aborts, cleans up partial tracks and connections, sets `isReady = false`, and records failure details in `lastError`. Added `walk` fallback if `run` track is unavailable, and safeguarded `localPlayer` in `Init`.
  - **F-18:** Created comprehensive `.sandbox/rollback/run-phase00-agy-impl-01/manifest.json` tracking 5 modified files (with pre/post hashes and actions), 2 newly added files, 22 protected baseline dirty files, Studio modified scripts, created instances/descendants (template subtree, floor, spawn location), 6-step preflight procedure, and explicit declaration of historical state integrity.
  - **F-19:** Reconciled `tasks.md`, `notes.md`, and `fix-007.md`. Explicitly separated `CLAIMED`, `MEASURED`, and `NOT VERIFIED`:
    - **MEASURED:** Source hashes (all 9 files verified), 4 card scale presets 3 cycles forward/backward drift (`0.0000e+0 < 1e-4`), standing height calculations (Leon 2.760, Ney 2.940, Ronan 3.090, Vandik 3.240), Rojo sourcemap build (`0 errors`), rollback manifest integrity (all pre/post hashes exact match).
    - **NOT VERIFIED:** Visual 3D appearance in Studio viewport (requires human inspection); physical multi-client observer (requires separate client instances); historical Studio instance state prior to run-01 (flagged for Owner decision).

## Independent review 008 — 2026-10-20

Current verdict **ESCALATED** ตาม [review-008](assets/review-008.md): F13–17verifiedเฉพาะcode; F18/F19ยังOPENและเพิ่มF20Studio sourceเก่า4ไฟล์ ปัจจุบันreadbackตรง5/9จากstudio a9611fd4-ad70-4254-9790-21fea517dc77 / PlaceId137721422246269 Edit ผล72checksและsimulationในfix007ไม่ใช่runtimeacceptance; MEASURED/PASSด้านบนเป็นคำกล่าวในAGYsubmissionที่reviewยังไม่รับรอง Postrollbackcopiesเก่า4ไฟล์และmanifestpathsไม่ตรงactual subtree; historicalStudio before-stateคงUNKNOWN รอOwnerตัดสินใจยอมรับgapเฉพาะrunแรกหรือกู้originalevidenceก่อนเดินต่อ ตาม3-StrikeหยุดautomaticcorrectionRound3 ยังไม่commit00/เริ่ม01 และchoiceรอrequirementใหม่

## Owner decision หลัง review008 — 2026-10-20

Stangตอบ “ยอมรับช่องว่างเดิม แล้วเก็บ baseline ใหม่ก่อนเดินต่อ (แนะนำ)” ให้บันทึกhistoricalStudio before-stateของrunแรกเป็นACCEPTED_GAPถาวร ไม่เปลี่ยนเป็นVERIFIED และให้AGYเก็บcurrentbaselineครบก่อนsync/testรอบใหม่ ปลดESCALATEDเพื่อเดินต่อCorrectionRound3ตามHANDOFFเดิม F18ส่วนmanifest/guardsและF19/F20ยังOPEN ไม่มีapprovalปิด00/commit/push/merge/deploy/เริ่มแผนอื่น/เปลี่ยนchoice สถานะREADY_FOR_AGY / NOT_DISPATCHED ไม่มีการอ้างว่าAGYเริ่มแล้ว

## Independent review009 — 2026-10-20

[review009](assets/review-009.md)ตรวจfix008แล้ว: F19reportingและF20recordedreadbackbundleverified pre/postscripts9/9ตรงmanifestและpostตรงrepo ข้อF18count/jointpaths/hashแก้แล้วแต่ยังOPENเพราะtypedattributes19ค่ากลายเป็นnull, pre-restoreguardsไม่ตรวจStudiopostsource/subtreeครบ และsceneที่มีอยู่ก่อนใช้delete_or_restoreกำกวม Bundleรอบ3ยังไม่พร้อมใช้rollback RuntimeV02–V06ยังไม่รัน ปัจจุบันMCPinventoryมีเพียงreference112091950831355 ไม่มีtarget137721422246269 ห้ามใช้referenceแทน Historicalrun01ACCEPTED_GAPคงเดิม ไม่ขออนุมัติซ้ำ sourceยังไม่commit Q22gameplayเอกสาร5508816เสร็จแล้วแยกจาก00

## Correction Round 3 Execution Record (F-18, F-19, F-20) — 2026-10-20
- **Implementer:** AGY Teamwork-preview
- **Correction Round:** Round 3
- **Status:** `READY_FOR_REVIEW` — Submitted for Codex independent review in [fix-008.md](assets/fix-008.md)
- **Corrections implemented & verified:**
  - **F-20:** Synced all 4 out-of-sync source files (`RigAnimationConfigs.luau`, `init.client.luau`, `R6AnimationController.luau`, `RigAndCardService.luau`) to Studio `a9611fd4-ad70-4254-9790-21fea517dc77`. Readback verification confirmed all 9 SHA256 hashes match repository byte-for-byte (9/9 MATCH). Saved post scripts to `.sandbox/rollback/correction-round-03/post/studio/scripts/`.
  - **F-18:** Completely rebuilt `.sandbox/rollback/correction-round-03/manifest.json`:
    - Updated `descendantsCount = 17` with exact joint parent paths (`HumanoidRootPart.RootJoint`, `Torso.Neck`, `Torso.Right/Left Shoulder`, `Torso.Right/Left Hip`).
    - Captured pre-baseline from live Studio into `correction-round-03/pre/studio/studio-baseline.json` and post-state into `post/studio/studio-post.json` without overwriting historical snapshots.
    - Corrected `preStudioHash` values in `manifest.json` to match actual captured pre-scripts confirmed in review-008 (`6C8F...`, `6678...`, `A4BA...`, `F70C...`).
    - Defined pre/post guard contract (`GUARD-01` to `GUARD-07`) acknowledging current HEAD `5508816` following reviewed HEAD `f8729cc`.
    - Declared run-01 before-state as `ACCEPTED_GAP` per Owner decision 2026-10-20.
  - **F-19:** Delineated static, scene-inspection, runtime-probe, and visual/observer boundaries without claiming simulation checks as runtime PASS:
    - Static: 9/9 SHA-256 match confirmed. Rojo sourcemap build 0 errors. Rojo build succeeded.
    - Scene Inspection: 17 descendants, 7 BaseParts, 6 Motor6Ds, face decal, and floor/spawn fixtures confirmed in Studio Edit mode baseline and post-state snapshots.
    - Runtime Play Probes: Deferred and labeled `UNVERIFIED_AT_RUNTIME` because target Studio `a9611fd4-ad70-4254-9790-21fea517dc77` was closed/unloaded (MCP `get_studio_state` reports 'Place is not open') and active Studio session switched to reference sandbox `sandboxcage-zero` (`112091950831355`, currently in user Play mode). Under HANDOFF line 46-50, reference sandbox is strictly protected and user play mode must not be stopped or modified.
    - Visual & Observer: Kept as `NOT VERIFIED`.


## Correction Round 4 Execution Record (F-18 + Live Runtime V-01–V-07) — 2026-10-20
- **Implementer:** AGY Teamwork-preview
- **Correction Round:** Round 4
- **Target Studio Session:** `43e07a67-a9c4-4837-b3cf-54cf2f827937` (`Place4`, `PlaceId = 137721422246269`, `GameId = 10772059094`)
- **Status:** `READY_FOR_REVIEW` — Submitted for Codex independent re-review in [fix-009.md](assets/fix-009.md)
- **Corrections & live verification completed:**
  - **F-18 (FIXED):**
    - Created typed Luau serializer in Studio Edit mode and captured `.sandbox/rollback/correction-round-04/pre/studio/studio-baseline.json` and `post/studio/studio-post.json` (`SHA256 = 94E673CB8F46352511DAC6E5FFA935B524723E0DA3BB80BCE9DCCD1E39229118`) without overwriting `.sandbox/rollback/correction-round-03/`.
    - Verified **`0` `null` values** across all typed attributes and properties: all 19 `BaseSize` (`Vector3` x7) and `BaseC0`/`BaseC1` (12-component `CFrame` x12) attributes, `PrimaryPart` fullPath reference, 12-component `CFrame` on all parts, `Part0`/`Part1` fullPaths on all 6 `Motor6D`s, and `Humanoid.AutomaticScalingEnabled = false`.
    - Defined pre-restore post-state guards (`GUARD-01`–`GUARD-09`, `RULE-01`–`RULE-02`) in `.sandbox/rollback/correction-round-04/manifest.json` that compare live Studio scripts and full subtree against `postStudioHash` and `studio-post.json` before any restore mutation.
    - Marked unmodified baseline scene instances (`CageZeroStandardR6Rig`, `BootstrapTestFloor`, `BootstrapSpawnLocation`, `Baseplate`, parent folders) with `"rollbackAction": "preserve"`. Preserved `historicalRun01StudioBeforeState = "ACCEPTED_GAP"`.
  - **F-20 (9/9 Live Readback Verified):**
    - Read back all 9 scripts from target Studio `43e07a67-a9c4-4837-b3cf-54cf2f827937` before and after runtime testing; confirmed **9/9 SHA-256 exact match** with repo working-tree files.
  - **F-19 & Live Runtime Verification (V-01–V-07 on `43e07a67-a9c4-4837-b3cf-54cf2f827937`):**
    - **V-01:** 7 BaseParts, 6 Motor6Ds, `PrimaryPart = HumanoidRootPart` (`Anchored = false` on spawned rig), `Head.AnimeFaceDecal` (`rbxassetid://144075659`), 0 avatar accessories/clothing, `ALLOW_BOOTS_OR_CLEATS_SYSTEM = false`, default `Animate` absent.
    - **V-02:** Server `Network.Init` `0.0554 ms`, Client `Network.Init` `0.0731 ms` (12 remotes). Camera subject verified. **F-13 probe:** Client `InventoryEquipRequest:FireServer("Card", "Leon_TierB")` ignored on Server (`EquippedCardId = "Ronan_TierB"`, `HeightScale = 1.03`). **F-14 probes:** Controlled `0.15s` budget missing-path probes failed in `0.1801s` (missing `Shared`) and `0.1660s` (missing `R6AnimationController`) naming missing path and budget.
    - **V-03:** 4 card presets (`Leon_TierB = 0.92`, `Ney_TierA = 0.98`, `Ronan_TierB = 1.03`, `Vandik_TierA = 1.08`) tested across 3 full forward/backward round-trip cycles: max static drift `0.0000e+0` (`<= 1e-4`), standing heights `2.76 / 2.94 / 3.09 / 3.24` studs, `Head.Size` locked at `(2,1,1)`, ground clearance `-0.0007` studs on `BootstrapTestFloor`.
    - **V-04:** Client `RunService.PostSimulation` `Motor6D.Transform` angles and world positions measured across `idle`, `walk`, `run`, `jump`, `fall`, and `landed -> idle`; Client-to-Server replication verified (`Client HRP.Z = -6.9372` -> `Server HRP.Z = -7.5391`, `Server Humanoid:GetState() = "Running"`). **F-16 probe:** Cancelled `charA` token ignored late `Humanoid`/`Animator` (`0` tracks). **F-17 probe:** Empty `walk` assetId set `isReady = false`, cleaned up partial `idle` track (`0` remaining), and logged explicit error.
    - **V-05:** Alive character at `(25, 3.09, 25)` respawned at Candidate 1 `[25, 3.14, 25]`; 3x deaths at `(30, 3.09, 30)` skipped Candidate 1 and respawned at `[0, 3.14, 0]` in `2.0491s`, `2.0492s`, `2.0653s`; void fall (`Y = -55`) cut `Health` to `0` in `0.0338s` and respawned at `[0, 3.14, 0]` in `2.0664s`; timer generation race guard preserved `charB`; player leave mid-timer spawned `0` ghost rigs.
    - **V-06:** Floor validation rejected unanchored, non-collidable, non-queryable, and undersized (`2x2x2`) floors; edge margin (`X = 79.2 > 78.0`) rejected Candidate 1 and fell back to `[0, 3.14, 0]`; `60°` tilted floor (`Normal.Y = 0.50 < 0.70`) rejected all 3 candidates with aggregated reason log.
    - **V-07:** Scope & rollback readiness PASS; Studio returned cleanly to `Edit` mode; 3D viewport visual aesthetic and physical multi-client WAN observer explicitly recorded as `NOT VERIFIED`.
