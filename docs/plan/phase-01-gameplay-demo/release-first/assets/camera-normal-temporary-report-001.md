# RF02-CAMERA-OFF — Temporary Normal Camera Report 001

**Date:** 2026-10-25 · **Author:** `agyanimation` (3.8 Flash, pane `w2:p49`) · **Controller/Reviewer:** Codex (`w2:p43`) · **Owner:** Stang  
**Status:** **SOURCE_FROZEN / READY_FOR_CODEX_REVIEW_AND_LOCAL_COMMIT**  
**Baseline HEAD:** `5ccb53d69568144c4b43458e84d06029d7937557` (Foundation local commit; working tree: 2 files modified in `src/`)  
**Contract Reference:** [`camera-normal-temporary-HANDOFF.md`](camera-normal-temporary-HANDOFF.md) & [`advanced-camera-owner-draft.md`](advanced-camera-owner-draft.md)  
**Studio Target:** `Cage-Zero` (PlaceId: `137721422246269`, Studio Instance ID: `ab5aa575-5e53-41b6-b1ab-e2c8bc7c29c0`, DataModel: `Edit`)  
**Pre-Mutation Backup Directory:** `C:/Users/Stang/cage-zero-cleanup-backups/camera-normal-backup-20261025-2040/`

---

## 1. Executive Summary & Verification Verdict

Per the Owner's directive (*"OWNER Q3 explicit: disable OLD ShiftLock now, normal camera TEMPORARILY; advanced camera AFTER Idle"*), implementer `agyanimation` disabled the automatic initialization and input wiring of the legacy custom `CameraShiftLockController`, restoring default/native Roblox third-person camera controls.

### Key Milestones Achieved:
1. **Narrow 2-File Scope Strictly Followed:**
   - [`src/client/init.client.luau`](file:///C:/Users/Stang/cage-zero/src/client/init.client.luau): Removed `CameraShiftLockController` require and `Init()` call from step 4.
   - [`src/client/controllers/InputController.luau`](file:///C:/Users/Stang/cage-zero/src/client/controllers/InputController.luau): Removed `require("CameraShiftLockController")` and `CameraShiftLockController.Init()` call.
   - Legacy file `src/client/controllers/CameraShiftLockController.luau` is kept completely **inert** (not deleted, not rewritten).
   - Zero new camera controllers, RenderStepped loops, keybindings, cursor locking, reticles, or game settings added. Advanced camera designs remain safely drafted in `advanced-camera-owner-draft.md` for post-Idle implementation.
2. **100% Readback Parity in Studio Edit Mode:**
   - Both modified files synchronized to `Cage-Zero` Edit DataModel and verified byte-for-byte and SHA256 identical.
3. **Engine Smoke Verification (Native Normal Camera Active):**
   - In local Play mode, `Workspace.CurrentCamera.CameraType` is `Enum.CameraType.Custom` with `CameraSubject = Workspace.StangMKxD.Humanoid` and `FieldOfView = 70`.
   - `UserInputService.MouseBehavior` is `Enum.MouseBehavior.Default` (free cursor, not locked to center).
   - Old shift-lock controller is completely inactive (`shiftLockActive = false`). Native mouse orbiting / RMB camera rotation operates via Roblox default `PlayerModule`.
4. **Foundation Invariants Preserved:**
   - Locked R15 height: `6.708 studs` (HeightScale `1.391`, HeadScale `1.0`, Width `3.459`, Depth `1.366`, `HipHeight = 2.792`).
   - ROBLOX Boy package, `Traditional Chinese Hat`, and personal clothing intact.
   - Ball: `Workspace.CageMatchBall` radius `1.125 studs` (diameter `2.25 studs`), resting at `(0, 1.125, 0)`.
   - Console: **0 Lua runtime errors** (only 1 historical asset warning).
5. **Studio Released to Edit Mode:**
   - Preview rig verified intact at `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30`.
   - Studio restored to `Edit` mode.

**Verdict:** **`READY_FOR_CODEX_REVIEW_AND_LOCAL_COMMIT / STUDIO_RELEASED_FOR_ARGON_PREVIEW`**.

---

## 2. Pre-Mutation Backup & Source Hashes

### Pre-Mutation Backup:
- Directory: `C:/Users/Stang/cage-zero-cleanup-backups/camera-normal-backup-20261025-2040/`
- `init.client.luau`: SHA256 `db8ce436235f820c8435554883a743c236c7de363b7506ec4eeeeab489cf03dd`
- `InputController.luau`: SHA256 `a3c2cadf011dbe8106131511c258ce82b832dad9d0748337b38a301e01cba449`

### Synchronized Files & Studio Edit Readback Parity:
| File Relative Path | Disk Bytes | Studio Bytes | Disk / Studio SHA256 Hash | Parity Status |
| :--- | :---: | :---: | :---: | :---: |
| `src/client/init.client.luau` | 3,372 | 3,372 | `89aa42be02f031ccc4d02d8de53f67b892f819b79b235a518ac1e80eced2723c` | **EXACT MATCH (100%)** |
| `src/client/controllers/InputController.luau` | 1,530 | 1,530 | `efa9d9e90546124969347798a5f203bbca2a808c27ca964871e7639f522a17ea` | **EXACT MATCH (100%)** |

---

## 3. Engine Smoke Observations (Play Mode)

- **Camera Type:** `Enum.CameraType.Custom` (default Roblox native third-person camera)
- **Camera Subject:** `Workspace.StangMKxD.Humanoid`
- **Field of View:** `70`
- **Mouse Behavior:** `Enum.MouseBehavior.Default` (cursor moves freely across window; no forced center lock)
- **ShiftLock Controller State:** `IsActive() = false` (inert, uninitialized)
- **Player Character:** `StangMKxD` (R15, ROBLOX Boy limbs, `HipHeight = 2.792`, `gapToFloor = -0.017 studs`)
- **Ball Invariants:** `CageMatchBall` radius `1.125`, diameter `2.25`, resting at `(0, 1.125, 0)`
- **Console Log:** **0 Lua runtime errors** (only 1 historical asset warning `rbxassetid://203785492`)
- **Visual & Feel Note:** Engine properties confirm default Roblox camera initialization. Player input capture behavior requiring subjective human feel remains explicitly pending Owner in-game visual acceptance.

---

## 4. Scope Boundaries & Commit Gate

1. **SOURCE_FROZEN:** All source edits in `src/` are frozen. Flash will **not** stage, commit, or push.
2. **Local Commit Gate:** Codex will independently review this bounded 2-file camera-normal diff and perform the local foundation commit under Owner standing authorization.
3. **Argon Preview Release:** Studio is in `Edit` mode with `PreviewRig_R15_Boy_Height30` ready at `(0, 4.183, 45)`. Argon will wait for Codex's official preview release.
