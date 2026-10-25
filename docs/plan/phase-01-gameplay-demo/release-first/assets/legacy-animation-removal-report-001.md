# Legacy Animation Removal Report — `legacy-animation-removal-report-001`

- **Date:** 2026-10-25
- **Status:** `READY_FOR_REVIEW` (Implementer claim; pending independent Codex review & local commit)
- **Task ID:** `RF02-LEGACY-ANIM-CLEANUP`
- **Implementer:** `agyanimation/3.8Flash` (`w2:p49`)
- **Parent Ref (Baseline Git HEAD):** `9fbce58eb90ed6b7e6a39b00a5744455ee639811` (Camera-off commit)
- **Studio Target:** `Cage-Zero` (`PlaceId = 137721422246269`), Studio ID `ab5aa575-5e53-41b6-b1ab-e2c8bc7c29c0`, Mode: `Edit`
- **Governing Contract:** [`review-021.md`](review-021.md) & [`legacy-animation-removal-HANDOFF.md`](legacy-animation-removal-HANDOFF.md)
- **Release Coordination Evidence:** Received explicit Argon (`w2:p48`) `STUDIO_RELEASED` notification confirming:
  - Owner approved `RF02_Idle_Ready_R15_v01` R15 Idle preview.
  - Studio Cage-Zero (`PlaceId 137721422246269`, `Edit` mode) released for Review 021 legacy R6 cleanup.
  - Motion Tools is **NOT** actively loading or depending on `03-dribble-duel/assets/animation-library.json` or `delta-agycage.json`.
  - New R15 Idle assets (`release-first/assets/animations/idle-r15/` and `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30`) are 100% independent and protected.

---

## 1. Recoverable Before-State Backup

Prior to any file or scene deletion, complete full-fidelity copies and serialized metadata were captured at:
- **Backup Directory:** `C:\Users\Stang\cage-zero-cleanup-backups\legacy-anim-cleanup-20261025-2115\`
- **Backup Metadata File:** [`BACKUP_METADATA.json`](file:///C:/Users/Stang/cage-zero-cleanup-backups/legacy-anim-cleanup-20261025-2115/BACKUP_METADATA.json)
- **Contents:**
  - 6 raw repo files with SHA256 pre-hashes matching the locked allowlist.
  - 3 raw Studio ModuleScript sources (`R6AnimationController`, `RigAnimationConfigs`, `PlayerActionPoseConfigs`).
  - Full hierarchical JSON subtree dump of `ServerStorage.MotionToolsRigs.R6_Rig.Animate` including LocalScript source, all 9 child `Animation` IDs, `StringValue` containers, `NumberValue` weights, and `BindableFunction`.

*(Historical Note: Any removed raw files are also permanently retrievable from Git commit `9fbce58eb90ed6b7e6a39b00a5744455ee639811`).*

---

## 2. Deletion Allowlist Execution (Exact 10 Targets)

### A. Repository Files Deleted (Exact 6 Files)

All pre-hashes verified against the manifest and [`review-021.md`](review-021.md) before removal:

| Item | Relative Repo Path | Pre-Deletion SHA256 Hash | Size (Bytes) | Execution Status |
|---|---|---|---|---|
| **R-01** | `src/client/character/R6AnimationController.luau` | `616B1D4A6D3A2A4F833AE3A2193547A6ED5B982C8C0246E2222AE61E3AE927FA` | 22,421 | **DELETED** |
| **R-02** | `src/shared/configs/RigAnimationConfigs.luau` | `A54D0A81B59535730137224AAE0DA26CDD2CE9E719BB70F2AEE3FCF9EF70DF99` | 9,733 | **DELETED** |
| **R-03** | `docs/plan/phase-01-gameplay-demo/02-player-actions/assets/designs/argon-r6-pack/R6FootballPoseData.luau` | `2F53441CFF05DDC150FF3F1496787823735254BD3604B4B4EFCCDFD0FA0D2DFA` | 125,311 | **DELETED** |
| **R-04** | `docs/plan/phase-01-gameplay-demo/02-player-actions/assets/designs/argon-r6-pack/R6FootballPosePlayer.luau` | `15D58D328617AEAF00013703930A8E2C09B7DE0E08E742F6850172AAC206E91D` | 23,223 | **DELETED** |
| **R-05** | `docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/animation-library.json` | `B6895B569A9D7CE59966FFAEC3E8A4426B8170ADF838EF51F0CEA7DF8FA94676` | 90,709 | **DELETED** |
| **R-06** | `docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/animation-library.delta-agycage.json` | `8D8ECCD19966104799E383B206B2042D76E4B4F7E9CB91467107B956A08E700A` | 6,714 | **DELETED** |

*Parent directories verified: no wildcard or recursive deletions occurred. `src/client/character/R15AnimationController.luau`, `src/shared/configs/R15AvatarConfigs.luau`, `argon-r6-pack/animation-spec.md` + 23 PNGs, and `03-dribble-duel/assets/designs/skill-animation-rework-20261024.md` remain intact.*

### B. Studio DataModel Targets Deleted (Exact 4 Targets in `PlaceId = 137721422246269`)

Executed in `Edit` mode via Luau execution:

| Item | Exact Studio DataModel Path | Class | Content Destroyed | Execution Status |
|---|---|---|---|---|
| **S-01** | `StarterPlayer.StarterPlayerScripts.Client.character.R6AnimationController` | ModuleScript | Synced legacy R6 controller script (22,421 B) | **DESTROYED** |
| **S-02** | `ReplicatedStorage.Shared.configs.RigAnimationConfigs` | ModuleScript | Synced legacy R6 configs script (9,733 B) | **DESTROYED** |
| **S-03** | `ReplicatedStorage.PlayerActionPoseConfigs` | ModuleScript | Orphan Plan 02 procedural pose config script (163,665 B) | **DESTROYED** |
| **S-04** | `ServerStorage.MotionToolsRigs.R6_Rig.Animate` | LocalScript | Legacy R6 Animate script (15,630 B) + 9 child `Animation` instances | **DESTROYED** |

#### Old R6 Child Animations Destroyed under S-04:
1. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.idle.Animation1` (`180435571`)
2. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.idle.Animation2` (`180435792`)
3. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.walk.WalkAnim` (`180426354`)
4. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.run.RunAnim` (`180426354`)
5. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.jump.JumpAnim` (`125750702`)
6. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.climb.ClimbAnim` (`180436334`)
7. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.toolnone.ToolNoneAnim` (`182393478`)
8. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.fall.FallAnim` (`180436148`)
9. `ServerStorage.MotionToolsRigs.R6_Rig.Animate.sit.SitAnim` (`178130996`)

*(Preservation Confirmation: The parent model `ServerStorage.MotionToolsRigs.R6_Rig`, its character limbs, `Humanoid`, and `Animator` were **NOT** deleted and remain intact).*

---

## 3. Post-Deletion Verification & Evidence

Read-only verification query executed in Studio Edit mode confirmed:

| Verification Item | Target Condition | Observed Result | Pass / Fail |
|---|---|---|:---:|
| `StarterPlayer...R6AnimationController` | Absent | `nil` | **PASS** |
| `ReplicatedStorage...RigAnimationConfigs` | Absent | `nil` | **PASS** |
| `ReplicatedStorage.PlayerActionPoseConfigs` | Absent | `nil` | **PASS** |
| `ServerStorage...R6_Rig.Animate` subtree | Absent | `nil` | **PASS** |
| `ServerStorage.MotionToolsRigs.R6_Rig` Model | Preserved | Exists with Humanoid + Animator | **PASS** |
| `ReplicatedStorage.Tier1_PlayerActions` | Preserved (Excluded orphan) | Exists untouched | **PASS** |
| `ReplicatedStorage.TestRunner` | Preserved (Excluded orphan) | Exists untouched | **PASS** |
| `ServerStorage.CageZeroStandardR6Rig` | Preserved (Baseline template rig) | Exists untouched | **PASS** |
| `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30` | Preserved (Active R15 Preview Rig) | Exists untouched | **PASS** |
| Studio Total Animation Count | Only active R15 animations | Exactly 29 (28 R15 Animations under PreviewRig + 1 `AnimSaves` KeyframeSequence) | **PASS** |

---

## 4. Protected Source Hash Baseline (Commit `9fbce58` Unchanged)

All core runtime scripts in `src/` were verified completely untouched with zero diff:

| File Path | SHA256 Hash | Status |
|---|---|---|
| `src/server/services/R15AvatarService.luau` | `F0B8D6288FF9316D912F76192377BF37D333232D5B534DE1C552EE46C8066B8B` | **UNTOUCHED** |
| `src/shared/configs/R15AvatarConfigs.luau` | `65E8E6EDE9BE7561F52598CA96CAF10AA5A2F1BCD0E3D23531894EAB7212FF72` | **UNTOUCHED** |
| `src/client/character/R15AnimationController.luau` | `97B36FACEE668863E68702D95B2D2A2687DCDD4981E9A7C1918AED23086DD5C5` | **UNTOUCHED** |
| `src/client/init.client.luau` | `89AA42BE02F031CCC4D02D8DE53F67B892F819B79B235A518AC1E80ECED2723C` | **UNTOUCHED** |
| `src/client/controllers/InputController.luau` | `EFA9D9E90546124969347798A5F203BBCA2A808C27CA964871E7639F522A17EA` | **UNTOUCHED** |

---

## 5. Scope Boundaries & Governance

- **No Git Staging or Committing:** Per project rules, Flash did NOT run `git add`, `git commit`, or `git push`. Local commit is reserved for Controller Codex upon independent review pass.
- **Studio Mode:** Studio was confirmed in `Edit` mode before and after execution; no Play mode was initiated or interrupted.
- **Argon Isolation:** Argon's new R15 Idle draft assets and preview rig were strictly protected.
