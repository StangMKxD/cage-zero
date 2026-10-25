# Gate 1 Discovery — Bounded Argon Spot Audit (`w2:p48`)

- **Date / Authority:** 2026-10-25 · `agycageim/4Argon` (`w2:p48`) per Owner bounded read-only directive & `review-009.md`.
- **Baseline HEAD:** `25a67d5575e31034a5a08290873b9c401357d33a` (seed diff base `617f523..HEAD`).
- **Scope:** Exact read-only verification of `src/server/init.server.luau`, `src/client/init.client.luau`, `src/shared/Network.luau`, `src/shared/Types.luau` (+ direct consumer headers in `InputController.luau` / `R6AnimationController.luau`), compared against `removal-manifest.md` (§3.2, §3.3, §3.5, §4.2, §6, §8) and `review-009.md` (`RF-F11`–`RF-F15`).

## 1. Audited Source Fingerprints & Exact Line Metrics (`RF-F11`, `RF-F14`)

| File Path | Bytes | `Get-Content` Lines | `Split-Lines` (w/ EOF `\n`) | Non-Empty Lines | SHA256 Hash |
| :--- | :---: | :---: | :---: | :---: | :--- |
| `src/server/init.server.luau` | 1,525 | 32 | 33 | 24 | `17d24b2f5199fda3f3a8bbf2cc6c469c2f7252428f48d4fc3456dcdf07926b2b` |
| `src/client/init.client.luau` | 3,641 | 75 | 76 | 61 | `4731c0449a26ad48f1ae3385c3103643f61d64653c0f2b50799539bbc0c86c93` |
| `src/shared/Network.luau` | 9,931 | 296 | 297 | 270 | `217668ce752348d046bf0f7963a3a72ff7133ff5ad57fafb9aea7d4a7abf96a5` |
| `src/shared/Types.luau` | 9,799 | 419 | 420 | 381 | `64b9e53831833c3d90f5563beeffa2171ee9abb3ea9662878c8d6216f17a0c59` |

## 2. File-by-File Evidence vs. Incorrect Manifest Claims

### 2.1 `src/server/init.server.luau` (32 `Get-Content` lines)
- **Exact Numbered Evidence:**
  - `L9–L10`: `local Shared = ReplicatedStorage:WaitForChild("Shared")` / `local Network = require(Shared:WaitForChild("Network"))`
  - `L12–L16`: Requires `Services:WaitForChild("CagePhysicsService")` (`L13`), `RigAndCardService` (`L14`), `BallService` (`L15`), `SkillMoveService` (`L16`).
  - `L19–L32`: Calls `Network.Init(10.0)` (`L19`), `CagePhysicsService.Init()` (`L22`), `CagePhysicsService.RetireBootstrapFixtures(Workspace)` (`L23`), `RigAndCardService.Init()` (`L26`), `BallService.Init()` (`L29`), `SkillMoveService.Init()` (`L32`).
- **Incorrect Manifest Claims (§2.4, §3.3.A, §4.2):**
  1. Claims `52 Physical Lines / 44 Non-Empty Lines` in §2.4 & §3.3.A (actual: `32` lines / `24` non-empty; §8 row 10 had `33 / 24`).
  2. Claims preserved requires/inits for `DuelEngineService`, `MatchService`, `FreeKickService`, `ParryService`, and `EventManagerService`. **None of these 5 services appear in `init.server.luau`.**
  3. §4.2 treats `FreeKickService`, `ParryService`, `MatchService`, and `EventManagerService` as active runtime callers of `BallService`/`CagePhysicsService`, when none are bootstrapped by `init.server.luau`.

### 2.2 `src/client/init.client.luau` (75 `Get-Content` lines)
- **Exact Numbered Evidence:**
  - `L18–L26`: Requires `Shared:WaitForChild("Network", remaining)` (`L18–L21`) and calls `Network.Init(remaining)` (`L26`).
  - `L31–L44`: Waits for `script:WaitForChild("character", remaining)` (`L31`) and `CharacterFolder:WaitForChild("R6AnimationController", remaining)` (`L36`), requires it (`L39`), calls `R6AnimationController.Init(remaining)` (`L44`).
  - `L46–L50`: `local ActionPoseModule = CharacterFolder:FindFirstChild("R6ActionPoseController")` -> `require(ActionPoseModule)` (`L48`) -> `R6ActionPoseController.Init()` (`L49`).
  - `L55–L74`: Checks `script:FindFirstChild("controllers")` (`L55`) and conditionally requires + calls `.Init()` on:
    - `CameraShiftLockController` (`L57–L61`)
    - `InputController` (`L63–L67`)
    - `TrainingHUD` (`L69–L73`)
- **Incorrect Manifest Claims (§2.4, §3.3.B):**
  1. Claims `86 Physical Lines / 70 Non-Empty Lines` in §2.4 & §3.3.B (actual: `75` lines / `61` non-empty; §8 row 8 had `76 / 61`).
  2. Claims `Lines 45–50` and `Lines 68–75` require/init `AirLeanController`, `SkillMoveController`, and `JumpVfxController`, and preserve `DuelUIController.Init()`. **None of `AirLeanController`, `SkillMoveController`, `JumpVfxController`, or `DuelUIController` exist in `init.client.luau`.**

### 2.3 `src/shared/Network.luau` (296 `Get-Content` lines)
- **Exact Numbered Evidence:**
  - `L20–L36`: `local RemoteNames = table.freeze({ ... })` defines 15 keys: `BallActionRequest` (`L21`), `ParryWindowTrigger` (`L22`), `ParryAttemptRequest` (`L23`), `DuelStartEvent` (`L24`), `DuelChoiceSubmit` (`L25`), `DuelResultEvent` (`L26`), `SkillMoveRequest` (`L27`), `SkillMoveReplicate` (`L28`), `TackleActionRequest` (`L29`), `FreeKickStartEvent` (`L30`), `FreeKickSubmit` (`L31`), `MatchEventBroadcast` (`L32`), `InventoryEquipRequest` (`L33`), `SummonRequest` (`L34`), `TradeActionRequest` (`L35`).
  - `L38–L129`: `local Definitions: { [string]: RemoteDefinition } = table.freeze({ ... })` defines matching metadata blocks:
    - `BallActionRequest`: `L39–L44` (`RemoteEvent`, `ClientToServer`, `moduleScope = "Module 02"`)
    - `SkillMoveRequest`: `L75–L80` (`RemoteEvent`, `ClientToServer`, `moduleScope = "Module 03"`)
    - `SkillMoveReplicate`: `L81–L86` (`RemoteEvent`, `ServerToClient`, `moduleScope = "Module 03"`)
    - `TackleActionRequest`: `L87–L92` (`RemoteEvent`, `ClientToServer`, `moduleScope = "Module 03"`)
- **Incorrect Manifest Claims (§3.5.A):**
  1. Claims `Line 38: RemoteNames.SkillMoveRequest = ...`, `Line 39: RemoteNames.SkillMoveReplicate = ...`, `Line 41: RemoteNames.TackleActionRequest = ...`.
  2. Actual code uses table keys at `L27–L29` inside `RemoteNames` AND frozen `Definitions` entries at `L75–L92` (which `Network.Init` iterates at `L171` & `L202`). Both `RemoteNames` (`L27–L29`) and `Definitions` (`L75–L92`) must be pruned together.

### 2.4 `src/shared/Types.luau` (419 `Get-Content` lines)
- **Exact Numbered Evidence (Module 02 `L222–L360` & Plan 03 `L362–L416`):**
  - Module 02 exports: `TeamSide` (`L223`), `TeamActionContext` (`L224`), `KickActionType` (`L226–L237`), `ChargeActionType` (`L239`), `CurveSideIntent` (`L241`), `ActionIntentName` (`L243–L259`), `FlightState` (`L261–L268`), `ActionStatus` (`L270`), `ActionRejectReason` (`L272–L286`), `ActionIntentPayload` (`L288–L302`), `BallPossessionState` (`L304–L307`), `BallSnapshot` (`L309–L319`), `PlayerMovementSnapshot` (`L321–L360`).
  - Plan 03 exports: `SkillMoveId` (`L363–L372`), `SkillSlotIndex` (`L374`), `SkillMoveDefinition` (`L376–L394`), `TackleActionType` (`L396`), `TackleDefinition` (`L398–L410`), `PlayerSkillLoadout` (`L412–L416`).
- **Incorrect Manifest Claims (§3.5.B):**
  1. Lists non-existent symbols `Types.AirLeanState`, `Types.JumpFSMState`, `Types.SkillLoadout` (actual: `PlayerSkillLoadout` at `L412–L416`), and `Types.TackleExecutionState` (actual: `TackleActionType` at `L396`, `TackleDefinition` at `L398–L410`).
  2. Claims `BallSnapshot` and `PlayerMovementSnapshot` can be preserved as-is while deleting `KickActionType`, `ChargeActionType`, `CurveSideIntent`, `FlightState`, `SkillMoveId`, and `TackleActionType`. In fact, `BallSnapshot` references `inFlightAction: KickActionType?` (`L318`), and `PlayerMovementSnapshot` references `TeamActionContext` (`L330`), `ChargeActionType?` (`L341`), `CurveSideIntent?` (`L342`), `FlightState?` (`L353`), `SkillMoveId?` (`L357`), and `TackleActionType?` (`L358`).

### 2.5 Direct Consumer Header & Stage Ordering Audit (`RF-F15`)
- **Direct Reference Evidence:**
  - `src/client/controllers/InputController.luau` (`L17–L28`) executes top-level `WaitForChild` + `require` for `AirLeanSolver` (`L17`), `JumpModel` (`L18`), `PlayerActionPoseConfigs` (`L20`), `JumpConfigs` (`L21`), `SkillMoveConfigs` (`L22`), `R6AnimationController` (`L25`), `R6ActionPoseController` (`L26`), `CameraShiftLockController` (`L27`), and `TrainingHUD` (`L28`).
  - `src/client/character/R6AnimationController.luau` (`L41–L56`) lazily resolves `script.Parent:FindFirstChild("R6ActionPoseController")` (`L48`) and calls `pcall(require, mod)` (`L50`).
- **Incorrect Manifest Claims (§3.2.A, §6):**
  1. §3.2.A claims `InputController.luau` `Lines 1–69` are foundation elements to `PRESERVE (KEEP)`, ignoring that `L17–L28` requires legacy modules scheduled for deletion.
  2. §6 Stage 3 deletes `R6ActionPoseController.luau` BEFORE Stage 4 removes its requires in `InputController.luau` (`L26`), `init.client.luau` (`L46–L50`), and `R6AnimationController.luau` (`L48–L50`), violating consumer-before-provider order.

## 3. Mandatory Correction Directions for Flash (`w2:p49`)
1. **Fix `removal-manifest.md` §2.4 & §3.3:** Replace fabricated `init.server.luau` (`52/44`) and `init.client.luau` (`86/70`) metrics and module lists with the exact line counts (`32/24` and `75/61` via `Get-Content`, or standardized `Split-Lines` matching §8) and exact line numbers from §2.1–§2.2 above.
2. **Fix `removal-manifest.md` §3.5:** Replace `Network.luau` remote locations with `RemoteNames` (`L27–L29`) + `Definitions` (`L75–L92`). In `Types.luau`, remove non-existent type names (`AirLeanState`, `JumpFSMState`, `SkillLoadout`, `TackleExecutionState`), use exact symbols (`L222–L416`), and specify pruning of coupled legacy fields inside `BallSnapshot` (`L318`) and `PlayerMovementSnapshot` (`L330–L359`).
3. **Fix `removal-manifest.md` §4.2 & §5 (`RF-F12`, `RF-F13`):** Mark `FreeKickService`, `ParryService`, `MatchService`, `DuelEngineService`, and `EventManagerService` as **unbootstrapped in `init.server.luau`**, separating active bootstrapped runtime closure (`Network`, `CagePhysicsService`, `RigAndCardService`, `BallService`, `SkillMoveService`) from dormant/uninitialized files.
4. **Fix `removal-manifest.md` §3.2.A & §6 (`RF-F15`):** Excise `InputController.luau` `L17–L28` legacy requires in Stage 4 BEFORE deleting `R6ActionPoseController.luau` and shared configs/solvers (swap Stage 3 provider deletion after Stage 4 consumer decoupling, or define one atomic non-sync edit barrier).
