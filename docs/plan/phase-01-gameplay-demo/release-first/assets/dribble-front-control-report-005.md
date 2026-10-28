# RF02-DRIBBLE-RECEIVE — Implementation Report 005
**Task ID:** `RF02-DRIBBLE-RECEIVE` (360 MoveDirection Lead / Forward Micro-Touch / Jump Self-Lob)  
**Governance:** `OWNER_STANDARD`  
**Implementer:** `argon` (`w2:p4M`)  
**Controller Route:** `codex` (`w2:p43`)  
**Date:** 2026-10-27  
**Status:** `READY_FOR_REVIEW_DISK_ONLY` (NOT_SYNCED to Studio; awaiting Owner sync directive)  
**Contract Baseline:** Base `b374102` + protected Sprint RF46/48 hashes (`139D29F8...`, `F8CDD3AC...`) + Authoritative Owner Grill Confirmed (ใช่) in `assets/dribble-front-control-HANDOFF.md`.

---

## 1. Prior One-Shot Sync Verification (Report 004)
Prior sync operation authorized by Owner was executed atomically before beginning new disk edits:
- Studio Place: `137721422246269` ("Cage-Zero")
- Studio State: `Edit` mode verified.
- Backup created: `.sandbox/rollback/pre-sync-report004/`
- Parity readback: 100% exact character/byte match across all 4 files:
  - `DribbleConfigs`: len 5060, match: true
  - `DribbleGeometryHelper`: len 9870, sha256: `21b6c1ef89c8bcd8e1f801c9fa7ce87f0e757d7a846e5a222860199101eae30a`
  - `MovementHeadingPreviewController`: len 18851, sha256: `535a4ad8420b5b325b5c25dca2a4601e58573e85dbeff534083f51b0fbbbab1c`
  - `BallService`: len 29771, sha256: `cad1d74e926887fd26460d9302e12a225170fdb8abc60d7b89434b2cb6a0296a`
- Callback delivered: `SYNC_COMPLETE` submitted to `w2:p43` with Enter.
- Rollback backup for new delta created: `.sandbox/rollback/pre-delta-report005/`.

---

## 2. Primary Scoped File Edits (Disk Only)

### 2.1 `src/shared/configs/DribbleConfigs.luau`
- Added forward micro-touch configurations:
  - `MICRO_TOUCH_ENABLED = true`
  - `MICRO_TOUCH_AMPLITUDE_WALK = 0.25` (studs)
  - `MICRO_TOUCH_AMPLITUDE_SPRINT = 0.40` (studs)
  - `MICRO_TOUCH_CADENCE_WALK = 2.5` (Hz)
  - `MICRO_TOUCH_CADENCE_SPRINT = 4.0` (Hz)
- Updated turn speed dip threshold:
  - `DRIBBLE_TURN_DIP_THRESHOLD_DEG = 120.0` (turns $\le 120^\circ$ have zero dip; turns $> 120^\circ$ scale to min 0.60 walk / 0.45 sprint, recovery rate 3.0 /s).
- Added Jump Self-Lob (Scoop) configurations:
  - `SELF_LOB_ENABLED = true`
  - `SELF_LOB_UPWARD_SPEED = 24.0` (studs/s, gives peak height ~4.4 studs above floor under -65 g)
  - `SELF_LOB_MIN_HORIZONTAL_SPEED = 8.0` (studs/s)
  - `SELF_LOB_MOMENTUM_FACTOR = 1.05`
  - `SELF_LOB_MAX_HORIZONTAL_SPEED = 36.0` (studs/s)
  - `SELF_LOB_MIN_TAKEOFF_VY = 15.0` (matches `LEDGE_FALL_MAX_INITIAL_VY`)
  - `SELF_LOB_RECAPTURE_COOLDOWN_SEC = 0.60` (brief former-owner recapture guard)

### 2.2 `src/shared/DribbleGeometryHelper.luau`
- `FeasibleFrontTarget(rootPos, leadDir, isSprinting, radialOffset)`:
  - Accepts arbitrary 360 horizontal `leadDir` (`MoveDirection` when moving, body `LookVector` when idle) and optional radial micro-touch offset.
  - Guarantees $d \ge \text{CARRIER\_SEPARATION\_DISTANCE}$ (2.425 studs).
  - Searches feasible flank angles along clearance ring inside cage bounds when approaching walls/corners.
- `ComputeMicroTouchOffset(speed, isSprinting, timeSec)`:
  - Purely forward along the travel direction ($D_{lead}$), with mathematically zero lateral sway.
  - Returns 0.0 at rest (speed $\le 1.5$ studs/s).
- `ComputeSelfLobVelocity(launchDir, carrierHorizVel, isMoving)`:
  - Computes initial 3D velocity for self-lob ($V_y = 24.0$ studs/s upward, horizontal momentum clamped to safe envelope).
- `ComputeTurnSpeedFactor`:
  - Evaluates turn angle against threshold $120^\circ$. Returns 1.0 for turns $\le 120^\circ$.
- `ResolveBodyCage`:
  - Preserved continuous swept circle-circle quadratic solver and feasible flank cage boundary clamp.

### 2.3 `src/server/services/BallService.luau`
- **360 Lead Tracking**:
  - Valid current carrier uses horizontal `carrierCand.humanoid.MoveDirection.Unit` as lead direction when moving ($> 0.05$ studs/s).
  - Smoothly settles to `carrierCand.rootPart.CFrame.LookVector` front when idle.
- **Forward Micro-Touches**:
  - Evaluates `ComputeMicroTouchOffset(cSpeed, isSprinting, now)` and adds purely to radial distance.
- **Real Ball Rolling**:
  - Distance-to-radius angle integration along horizontal travel axis: $\theta = \Delta s / R_{ball}$. Zero travel stops spin at rest.
- **Jump Self-Lob (Scoop)**:
  - Implemented `BallService.TriggerSelfLob(player, hrp, humanoid)`.
  - Discharges ONCE per upward jump (`lobDischargedThisJump[uid] = true`).
  - Moving uses verified horizontal velocity snapshot; stationary uses horizontal camera look (or root facing fallback).
  - Atomically clears server possession: `ballState.state = "Free"`, `ballState.possessorUserId = nil`, `IsBallCarrier = false`.
  - Observer hooked in `humanoid.StateChanged` (`newState == Jumping` or coalesced rising `Freefall` with $V_y > 15.0$).
  - Guarded against failed press ($V_y \le 15.0$) and ledge fall ($V_y \le 0$).
  - Former owner recapture cooldown guard: former owner cannot reacquire during `SELF_LOB_RECAPTURE_COOLDOWN_SEC` (0.60s); opponents can receive immediately if in gate.
- **Camera Intent Listener**:
  - Connected `BallActionRequest` RemoteEvent from `CageZeroRemotes`. Validates finite, non-NaN, non-Inf, normalized horizontal vectors; enforces carrier-only context and rate limit ($\le 20$ msgs/s).

### 2.4 `src/client/controllers/MovementHeadingPreviewController.luau`
- Hooked `BallActionRequest` RemoteEvent to report camera look intent at 10 Hz when `isCarrier` is true.
- `updateGroundedFacing` applies `ComputeTurnSpeedFactor` with new $120^\circ$ threshold.
- Non-carrier movement, jump buffer, air lean, and camera 360 controls completely preserved.

---

## 3. Verification & Evidence

### 3.1 Test Suite Results (`.sandbox/test_rf02_front_control_report005.js`)
All 13/13 offline tests executed and PASSED:
- **Suite 1: Moving Lead vs Idle Lead & Separation Guarantee**
  - `[PASS]` Moving lead follows MoveDirection across 360° independently of body facing.
  - `[PASS]` Idle lead smoothly settles to body LookVector front.
- **Suite 2: Forward Micro-Touches (Purely Radial, Zero Lateral Sway)**
  - `[PASS]` Stationary player has exactly zero micro-touch offset (no spin / no pulse at rest).
  - `[PASS]` Moving player micro-touches are strictly positive (forward-only) and bounded by amplitude.
  - `[PASS]` Micro-touch perturbation has ZERO lateral sway across all angles.
- **Suite 3: Sharp Turns & Configurable Dribble Speed Dip**
  - `[PASS]` Turns <= 120° produce no speed dip (factor = 1.0).
  - `[PASS]` Turns > 120° smoothly dip to configured minimums at 180°.
- **Suite 4: Joint Swept Body + Cage Clearance**
  - `[PASS]` Ball is safely separated from body across high-speed approach and initial overlap.
  - `[PASS]` Wall proximity: carrier near boundary slides along feasible flank inside cage.
- **Suite 5: Jump Self-Lob (Scoop) Lifecycle & Recapture Guard**
  - `[PASS]` ComputeSelfLobVelocity produces exact upward velocity and momentum-scaled horizontal.
  - `[PASS]` Self-Lob Simulation Model: upward jump scoops once, clears possession atomically, enforces recapture cooldown.
  - `[PASS]` Jump rejection cases: ledge fall (Vy <= 0) and failed press do not trigger scoop.
  - `[PASS]` Camera Intent Network Payload Validator rejects NaN, Inf, non-vectors, and zero vectors.

### 3.2 Rojo Packaging
```powershell
rojo build default.project.json --output $env:TEMP\cage-zero-r5.rbxlx
# Built project to cage-zero-r5.rbxlx (Exit code 0)
```

### 3.3 Protected Sprint Hashes
- `src/client/controllers/SprintController.luau`: `139D29F86597E3587A558A115A25D6F92D1CEDF731D717ECF398D8E37344924E` (MATCH)
- `src/server/services/SprintService.luau`: `F8CDD3ACF8FD7BCE8E18C878F4104BCBF31ABF63738C026314A7B3EA0B949294` (MATCH)

---

## 4. Tuning Guide (`DribbleConfigs.luau`)
| Parameter | Default | Purpose / Impact |
|---|---|---|
| `FRONT_DISTANCE_WALK` | `2.9` | Base controlled lead distance while walking (studs) |
| `FRONT_DISTANCE_SPRINT` | `3.3` | Base controlled lead distance while sprinting (studs) |
| `MICRO_TOUCH_ENABLED` | `true` | Enables/disables forward micro-touches |
| `MICRO_TOUCH_AMPLITUDE_WALK` | `0.25` | Forward touch push amplitude during walk (studs) |
| `MICRO_TOUCH_AMPLITUDE_SPRINT` | `0.40` | Forward touch push amplitude during sprint (studs) |
| `MICRO_TOUCH_CADENCE_WALK` | `2.5` | Foot tap cadence during walk (Hz) |
| `MICRO_TOUCH_CADENCE_SPRINT` | `4.0` | Foot tap cadence during sprint (Hz) |
| `DRIBBLE_TURN_DIP_THRESHOLD_DEG` | `120.0` | Angle below which turns have zero speed reduction |
| `DRIBBLE_TURN_MIN_FACTOR_WALK` | `0.60` | Minimum speed factor during 180° walk reversal |
| `DRIBBLE_TURN_MIN_FACTOR_SPRINT` | `0.45` | Minimum speed factor during 180° sprint reversal |
| `DRIBBLE_TURN_RECOVERY_RATE` | `3.0` | Turn speed recovery rate back to 1.0 (1/s) |
| `SELF_LOB_ENABLED` | `true` | Enables/disables Jump Self-Lob scoop |
| `SELF_LOB_UPWARD_SPEED` | `24.0` | Upward scoop launch velocity (studs/s) |
| `SELF_LOB_MIN_HORIZONTAL_SPEED` | `8.0` | Stationary scoop forward pop speed (studs/s) |
| `SELF_LOB_MOMENTUM_FACTOR` | `1.05` | Moving scoop horizontal momentum multiplier |
| `SELF_LOB_MIN_TAKEOFF_VY` | `15.0` | Minimum upward takeoff Vy required to trigger scoop |
| `SELF_LOB_RECAPTURE_COOLDOWN_SEC` | `0.60` | Former owner recapture guard window (seconds) |

---

## 5. Technical Limitations & Status
- **NOT_SYNCED**: This report and implementation are strictly `DISK ONLY` per Owner instruction. Studio place `137721422246269` currently contains the verified `report004` code; new `report005` delta will NOT be synced until Owner explicitly issues a sync directive.
- **NOTRUN**: Live multiplayer replication, visual animation feel, and Studio playtest remain NOTRUN offline; models verified via deterministic test runner.
- **Goal-Facing Feature**: Firmly queued for *after* dribbling acceptance; no input/camera/jump keys touched for it.
