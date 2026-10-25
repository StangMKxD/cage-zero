# Legacy Animation Removal Manifest — Phase 1 Exact Inventory

- **Date:** 2026-10-25
- **Baseline Git HEAD:** `9fbce58eb90ed6b7e6a39b00a5744455ee639811` (Camera-off commit)
- **Studio Target:** `Cage-Zero` (`PlaceId = 137721422246269`), Studio ID `ab5aa575-5e53-41b6-b1ab-e2c8bc7c29c0`, Mode: `Edit`
- **Owner Scope:** Authorized removal of obsolete Cage-Zero R6 / legacy Plan 02–03 animation runtime, raw clip/recipe libraries, and stray Studio instances.
- **Phase 1 Rule:** **STRICTLY READ-ONLY**. No deletions, source mutations, or Studio modifications until Controller Codex locks the explicit allowlist.

---

## 1. Candidate Summary Counts

| Classification | Count (Primary Targets) | Scope Breakdown |
|---|---|---|
| **REMOVE** | **12 targets** | 6 Repository files (`src/` and `docs/`) + 6 Studio DataModel instances (including 1 Model with 9 child `Animation` instances) |
| **UNCERTAIN** | **2 asset groups** | 1 Design document (`skill-animation-rework-20261024.md`) + 1 Design pack folder (`argon-r6-pack` spec & 23 PNGs) |
| **KEEP (PROTECTED)** | **5 categories** | Active R15 Boy+30% Preview Rig (28 R15 Animations), `CageZeroStandardR6Rig`, Argon's `idle-r15/` recipes, `.sandbox/rollback/`, and historical fix/review docs |

---

## 2. Category: REMOVE Candidates

The following 12 targets are obsolete R6 animation controllers, configs, raw transform data, clip libraries, or stray Studio instances from Plans 00–03. All have zero active callers in current runtime code.

### A. Repository Source & Data Files (6 files)

| Item | Exact Repo Path | Class / Type | Size (Bytes) | SHA256 Hash | Provenance | Active Consumers / Reference Status | Recommended Action |
|---|---|---|---|---|---|---|---|
| **R-01** | `src/client/character/R6AnimationController.luau` | ModuleScript (Luau) | 22,421 | `616B1D4A6D3A2A4F833AE3A2193547A6ED5B982C8C0246E2222AE61E3AE927FA` | Legacy Plan 00/01 R6 locomotion & action animation controller | **ZERO active consumers**. Only 2 inert comments in `src/client/init.client.luau` (lines 4, 42). Not loaded or required anywhere. | **REMOVE** |
| **R-02** | `src/shared/configs/RigAnimationConfigs.luau` | ModuleScript (Luau) | 9,733 | `A54D0A81B59535730137224AAE0DA26CDD2CE9E719BB70F2AEE3FCF9EF70DF99` | Legacy Plan 00 R6 animation track IDs and state definitions | **ZERO active consumers**. Required only by `R6AnimationController.luau` (R-01). Not loaded by any other module. | **REMOVE** |
| **R-03** | `docs/plan/phase-01-gameplay-demo/02-player-actions/assets/designs/argon-r6-pack/R6FootballPoseData.luau` | ModuleScript (Luau) | 125,311 | `2F53441CFF05DDC150FF3F1496787823735254BD3604B4B4EFCCDFD0FA0D2DFA` | Legacy Plan 02 Argon R6 Motor6D transform data (A01-A18) | **ZERO runtime consumers**. Consumed only by `R6FootballPosePlayer.luau` (R-04). Not used in `src/` or `tests/`. | **REMOVE** |
| **R-04** | `docs/plan/phase-01-gameplay-demo/02-player-actions/assets/designs/argon-r6-pack/R6FootballPosePlayer.luau` | ModuleScript (Luau) | 23,223 | `15D58D328617AEAF00013703930A8E2C09B7DE0E08E742F6850172AAC206E91D` | Legacy Plan 02 Argon R6 Motor6D custom pose player | **ZERO runtime consumers**. Not loaded anywhere in `src/` or `tests/`. | **REMOVE** |
| **R-05** | `docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/animation-library.json` | JSON Data | 90,709 | `B6895B569A9D7CE59966FFAEC3E8A4426B8170ADF838EF51F0CEA7DF8FA94676` | Legacy Plan 03 Motion Tools R6 animation clip library & recipes | **ZERO runtime consumers**. Replaced by new R15 motion workflow. | **REMOVE** |
| **R-06** | `docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/animation-library.delta-agycage.json` | JSON Data | 6,714 | `8D8ECCD19966104799E383B206B2042D76E4B4F7E9CB91467107B956A08E700A` | Legacy Plan 03 Motion Tools R6 delta library | **ZERO runtime consumers**. Replaced by new R15 motion workflow. | **REMOVE** |

### B. Studio DataModel Targets (6 targets in `PlaceId = 137721422246269`)

| Item | Exact Studio Path | Class | Size / Content | Provenance | Active Consumers / Reference Status | Recommended Action |
|---|---|---|---|---|---|---|
| **S-01** | `StarterPlayer.StarterPlayerScripts.Client.character.R6AnimationController` | ModuleScript | 22,421 bytes | Studio synced copy of `src/client/character/R6AnimationController.luau` | Inert in Studio runtime; zero active callers. | **REMOVE** |
| **S-02** | `ReplicatedStorage.Shared.configs.RigAnimationConfigs` | ModuleScript | 9,733 bytes | Studio synced copy of `src/shared/configs/RigAnimationConfigs.luau` | Inert in Studio runtime; zero active callers. | **REMOVE** |
| **S-03** | `ReplicatedStorage.PlayerActionPoseConfigs` | ModuleScript | 163,665 bytes | Stray instance in `ReplicatedStorage` root from Plan 02 R6 procedural pose configs | Already deleted from Git repository during Cleanup A; remains as orphan in Studio. Zero active callers. | **REMOVE** |
| **S-04** | `ReplicatedStorage.Tier1_PlayerActions` | ModuleScript | 101,151 bytes | Stray instance in `ReplicatedStorage` root from Plan 02 E2E test suite | Stray orphan in Studio root. Zero active callers. | **REMOVE** |
| **S-05** | `ReplicatedStorage.TestRunner` | ModuleScript | 10,213 bytes | Stray instance in `ReplicatedStorage` root from Plan 02 master test runner | Stray orphan in Studio root. Zero active callers. | **REMOVE** |
| **S-06** | `ServerStorage.MotionToolsRigs.R6_Rig` | Model | Contains `Animate` LocalScript + 9 `Animation` instances | Legacy Plan 03 Motion Tools R6 preview rig target | Replaced by active R15 preview rig in `Workspace.PreviewRigs`. Contains 9 default R6 Animation instances (listed below). Zero active gameplay consumers. | **REMOVE** (Model + all 9 child Animations) |

#### Exact Animation Instances inside `ServerStorage.MotionToolsRigs.R6_Rig` (Child Objects of S-06):
1. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.idle.Animation1` — AssetId: `http://www.roblox.com/asset/?id=180435571`
2. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.idle.Animation2` — AssetId: `http://www.roblox.com/asset/?id=180435792`
3. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.walk.WalkAnim` — AssetId: `http://www.roblox.com/asset/?id=180426354`
4. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.run.RunAnim` — AssetId: `http://www.roblox.com/asset/?id=180426354`
5. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.jump.JumpAnim` — AssetId: `http://www.roblox.com/asset/?id=125750702`
6. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.climb.ClimbAnim` — AssetId: `http://www.roblox.com/asset/?id=180436334`
7. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.toolnone.ToolNoneAnim` — AssetId: `http://www.roblox.com/asset/?id=182393478`
8. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.fall.FallAnim` — AssetId: `http://www.roblox.com/asset/?id=180436148`
9. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.sit.SitAnim` — AssetId: `http://www.roblox.com/asset/?id=178130996`

*(Note: DataModel search confirmed **0** `KeyframeSequence`, `Keyframe`, or `Pose` instances exist in the entire DataModel).*

---

## 3. Category: UNCERTAIN Candidates

The following 2 candidate groups are non-runtime design documents and visual references. Per handoff instructions: *"Preserve historical review/fix/decision docs... If a genuine unknown remains, keep it UNCERTAIN rather than guessing."*

| Item | Path | Class / Type | Size | SHA256 Hash | Provenance & Description | Question / Reason for UNCERTAIN |
|---|---|---|---|---|---|---|
| **U-01** | `docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/designs/skill-animation-rework-20261024.md` | Markdown Document | 8,715 bytes | `E401A5967D20F58F1DF9F69876BB14F297094BF42D397EDDA173055DF9D03629` | Plan 03 design rework document evaluating R6 skill animations | Contains historical design reasoning. Does Owner/Codex wish to delete it as part of old animation purge, or keep it under historical decision doc preservation? |
| **U-02** | `docs/plan/phase-01-gameplay-demo/02-player-actions/assets/designs/argon-r6-pack/` (documentation and PNG references) | Markdown, Text, and 23 PNG files | Total ~11.8 MB (`animation-spec.md` 340 KB, 23 PNGs ~300-550 KB each) | Diverse | Legacy Plan 02 visual design reference pack for football actions A01-A18 | While raw Luau files (R-03, R-04) are flagged for REMOVE, should the design spec and reference PNGs be preserved as visual reference for future R15 animations, or deleted completely? |

---

## 4. Category: KEEP (Explicitly Protected) Items

The following items are active systems, active preview assets, or critical historical/recovery baselines and **MUST NOT** be modified or deleted.

| Category | Path / Studio Location | Class | Content / Details | Protection Reason |
|---|---|---|---|---|
| **K-01** | `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30` | Model (in Studio Workspace) | Active R15 Boy+30% preview rig calibrated to 6.708 studs height. Contains `Animate` script with 28 default R15 `Animation` instances. | **ACTIVE R15 PREVIEW RIG**. Owned by Owner/Argon for new Motion preview. |
| **K-02** | `ServerStorage.CageZeroStandardR6Rig` | Model (in Studio ServerStorage) | Baseline R6 template rig containing standard parts and Humanoid/Animator. Has **no** child Animation instances. | **BASELINE TEMPLATE RIG**. Protected per handoff rule: *"Do not classify ordinary rig models or every Animator as old animation trash."* |
| **K-03** | `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/idle-r15/` | Directory in repo | Contains Argon's new R15 motion assets: `PreviewRig_R15_Boy_Height30.backup.json` (5,465 B), `RF02_Idle_Ready_R15_v01.audit.json` (194,919 B), `RF02_Idle_Ready_R15_v01.recipe.json` (11,624 B). | **NEW R15 IDLE ASSETS**. Owned by Argon (`w2:p48`). Protected from all cleanup actions. |
| **K-04** | `.sandbox/` and `.sandbox/rollback/` | Directory in repo | Contains baseline rollback files, sandbox prototypes, and recovery archives. | **RECOVERY & ROLLBACK ARCHIVE**. Protected by explicit project governance. |
| **K-05** | Historical Docs & Git History | `docs/**/fix-*.md`, `review-*.md`, `HANDOFF.md`, etc. | All formal handoffs, verification records, and commit history. | **AUDIT TRAIL**. Preserved for provenance and compliance. |

---

## 5. Active Runtime Callers & Consumer Audit

An exhaustive codebase search across `src/` and `tests/` confirmed:
1. `R6AnimationController`:
   - `src/client/init.client.luau:4`: `-- R6AnimationController preserved as inert reference; R6 controller does not compete.` (comment only)
   - `src/client/init.client.luau:42`: `-- R6AnimationController preserved as inert reference; does not run concurrently.` (comment only)
   - **No executable requires, imports, or calls exist in any script.**
2. `RigAnimationConfigs`:
   - Consumed only by `R6AnimationController.luau: local RigAnimationConfigs = require(SharedConfigs:WaitForChild("RigAnimationConfigs"))`.
   - **No other consumer in `src/` or `tests/`.**
3. `PlayerActionPoseConfigs`, `Tier1_PlayerActions`, `TestRunner`:
   - **Zero references** in `src/` or `tests/`.
4. `animation-library.json`, `animation-library.delta-agycage.json`, `R6FootballPoseData.luau`:
   - **Zero references** in `src/` or `tests/`.

---

## 6. Execution Pre-flight & Safety Guards

When Codex issues the formal execution allowlist:
1. **Reversibility:** Source files are tracked under Git commit `9fbce58eb90ed6b7e6a39b00a5744455ee639811`. Studio instances can be exported or backed up prior to deletion if needed.
2. **Argon Coordination:** Studio deletions (S-01 through S-06) will only take place when Argon has concluded the current preview session, Studio is confirmed in `Edit` mode, and explicit dispatch is granted.
3. **No Wildcard Deletions:** Deletions will target strictly the approved paths. No parent directories containing mixed content (e.g., `ServerStorage`, `Workspace.PreviewRigs`) will be deleted.
