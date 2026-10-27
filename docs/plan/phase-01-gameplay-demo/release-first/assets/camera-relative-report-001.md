# RF02-CAMERA-RELATIVE — Implementation & Verification Report (001)

**Date:** 2026-10-27  
**Owner:** Stang  
**Controller / Reviewer:** Codex (`w2:p43`)  
**Implementer:** Argon (`w2:p4M`, Gemini 3.8 Flash High)  
**Project:** `C:\Users\Stang\cage-zero` (PlaceId: `137721422246269`)  
**Base:** HEAD `9db6122` + protected dirty tree  
**Governance:** Governed strictly by [`docs/plan/phase-01-gameplay-demo/release-first/assets/camera-relative-HANDOFF.md`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/camera-relative-HANDOFF.md)

---

## 1. Executive Summary

`RF02-CAMERA-RELATIVE` replaces the previous world-heading latch semantics with continuous camera-relative movement and ShiftLock-style grounded reticle facing as confirmed by Owner:
1. **Grounded Reticle Facing:** Grounded character body yaw aligns with the camera reticle aim at all times (`AutoRotate = false` while grounded, orientation driven at `RenderPriority.Input.Value + 5` with 0.001 rad deadband; root translation and linear physics velocity are strictly preserved).
2. **Continuous Camera-Relative WASD:** Movement direction is recomputed continuously against current camera yaw every frame, even when holding the same chord.
3. **Manual Countersteering:** Opposing keys cancel (`W+S = 0`, `A+D = 0`), diagonal inputs normalize to unit magnitude (1.0). Player manually countersteers (e.g. `W+A` at camera-right 45°, `A` at camera-right 90°) to preserve world heading.
4. **Airborne Boundary & Yaw Lock:** When jumping (`isAirborne == true`), `AirMovementController` retains exclusive ownership of root yaw (liftoff yaw is strictly frozen throughout flight); 4-way lean operates relative to liftoff yaw, and flight momentum is untouched. Grounded reticle facing seamlessly resumes upon landing.
5. **No Jump or Dribble Regressions:** Prior jump files remain frozen (technical gap RF-F42 from review-028 remains open and not claimed closed). Dribble/front-control work remains paused.

---

## 2. File Artifacts & Parity Checks

### Scoped File Allowlist
- [`src/shared/configs/CameraPreviewConfigs.luau`](file:///C:/Users/Stang/cage-zero/src/shared/configs/CameraPreviewConfigs.luau)
- [`src/client/controllers/MovementHeadingPreviewController.luau`](file:///C:/Users/Stang/cage-zero/src/client/controllers/MovementHeadingPreviewController.luau)

### Checksums & Parity Matrix
| Target File | Disk Bytes | Disk SHA-256 | Disk djb2 | Studio Edit Bytes | Studio Edit djb2 | Match |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `CameraPreviewConfigs.luau` | 2166 | `0aa9169250b98966110b5e4b9aba1848062b4cfd3c97f0be36c011758be3312e` | 1316643812 | 2166 | 1316643812 | **100% EXACT** |
| `MovementHeadingPreviewController.luau` | 13195 | `87813b9788841fc9938c9c5f51dbff9333bcc814ee86acd63b45196351db8ef4` | 666746675 | 13195 | 666746675 | **100% EXACT** |

- **Temporary Seam Status:** `hasSeam: false` confirmed in Studio Edit mode. All test harnesses removed.
- **Rojo Build:** `rojo build default.project.json --output $env:TEMP\cage-zero-cam-rel-final.rbxlx` passed with zero errors.

---

## 3. Actual Verified Test Results

All tests were executed in live Studio Play mode (`PlaceId: 137721422246269`, Studio instance `83fe57bf-2773-403f-ab21-654558ed4aa9`).

### Suite 1: Continuous Camera-Relative W Movement & Ground Body Facing
- **Condition:** Holding `W` continuously while sweeping camera yaw `0° -> 45° -> 90°`.
- **Results:**
  - `yaw = 0°`: `chord = "W"`, `dir = (0, 0, -1)`, `dirDotExpected = 1.0`, `yawErr = 0.0 rad`.
  - `yaw = 45°`: `chord = "W"`, `dir = (-0.7071, 0, -0.7071)`, `dirDotExpected = 1.0`, `yawErr = 3.77e-8 rad`.
  - `yaw = 90°`: `chord = "W"`, `dir = (-1.0, 0, 0)`, `dirDotExpected = 1.0`, `yawErr = 1.63e-7 rad`.
- **Verdict:** **PASS**. No stale world latch; body continuously tracks reticle facing.

### Suite 2: Strafe (A/D), Back (S), Opposing Cancellation, & Manual Countersteer
- **Strafe Left (A):** `dir = (-1, 0, 0)`, `dirDot = 1.0`, `hrpYaw = 0.0 rad` (`bodyFacesCamera: true`).
- **Strafe Right (D):** `dir = (1, 0, 0)`, `dirDot = 1.0`, `hrpYaw = 0.0 rad` (`bodyFacesCamera: true`).
- **Backward (S):** `dir = (0, 0, 1)`, `dirDot = 1.0`, `hrpYaw = 0.0 rad` (`bodyFacesCamera: true`).
- **Opposing W + S Cancellation:** `chord = "NONE"`, `dirMagnitude = 0.0` (`cancelled: true`).
- **Opposing A + D Cancellation:** `chord = "NONE"`, `dirMagnitude = 0.0` (`cancelled: true`).
- **Diagonal Normalization (W + D):** `chord = "WD"`, `dirMagnitude = 1.0` (`isUnitSpeed: true`).
- **Countersteer at Cam-Right 45° (W + A):** `camYaw = -45°`, `chord = "WA"`, `dir = (0, 0, -1)`, `dotOriginalForward = 1.0` (`isAligned: true`).
- **Countersteer at Cam-Right 90° (A alone):** `camYaw = -90°`, `chord = "A"`, `dir = (0, 0, -1)`, `dotOriginalForward = 1.0` (`isAligned: true`).
- **Verdict:** **PASS**. Clean ShiftLock movement and countersteering behavior verified.

### Suite 3: Standing Camera Rotation & Planar Speed Independence
- **Condition:** Standing still (`NONE` chord) while sweeping camera yaw across `0°`, `60°`, `120°`, `180°`, `-90°`.
- **Results:**
  - `0°`: `yawError = 0.0 rad` (`followsAim: true`).
  - `60°`: `yawError = 2.91e-8 rad` (`followsAim: true`).
  - `120°`: `yawError = 5.83e-8 rad` (`followsAim: true`).
  - `180°`: `yawError = 1.51e-7 rad` (`followsAim: true`).
  - `-90°`: `yawError = 4.37e-8 rad` (`followsAim: true`).
- **Planar Speed Check:** Pitch/zoom adjustments yield `dir.Y = 0.0`, `planarSpeed = 1.0` (`isPurelyPlanar: true`).
- **Verdict:** **PASS**.

### Suite 4: Airborne Boundary, Yaw Lock & Landing Recovery
- **Condition:** Moving forward with `W` held -> Jump (`Space`) -> Sweep camera yaw to `90°` and switch chord to `S` while airborne -> Land on ground.
- **Results:**
  - `liftoffDetected: true`, `liftoffYaw = 0.0 rad`.
  - While airborne (4 continuous samples):
    - `sample 1`: `yawDrift = 0.0 rad`, `yawLocked = true`, `isAirborne = true`.
    - `sample 2`: `yawDrift = 0.0 rad`, `yawLocked = true`, `isAirborne = true`.
    - `sample 3`: `yawDrift = 0.0 rad`, `yawLocked = true`, `isAirborne = true`.
    - `sample 4`: `yawDrift = 0.0 rad`, `yawLocked = true`, `isAirborne = true`.
  - Upon landing:
    - `landYaw = 1.570796 rad` (matches `90°` camera aim).
    - `resumedFacing: true`.
- **Verdict:** **PASS**. Liftoff yaw lock is completely intact. Air turning prevented. Landing seamlessly re-engages camera facing without stutter or jerk.

### Suite 5: Lifecycle, Clean Re-Init & Safety Focus Handling
- **Cleanup Behavior:** `Cleanup()` resets state, unbinds render step, restores `AutoRotate = true` (`isActive = false`, `autoRotateRestored = true`).
- **Re-Init Behavior:** `Init()` cleanly rebinds, suspends native controls, sets `AutoRotate = false` (`isActive = true`, `autoRotateSetFalse = true`).
- **Cycle Stability:** 2 full Cleanup -> Init cycles passed cleanly without duplicate bindings or dangling handlers.
- **Focus Safety:** `GuiService.MenuOpened`, `UserInputService.WindowFocusReleased`, `UserInputService.TextBoxFocused` safely reset held keys and movement directions.
- **Verdict:** **PASS**.

---

## 4. Unrun Gates & Known Risks (Honest NOTRUN)

1. **Multiplayer Server Yaw Catchup (RF-F42):** Remains open per Controller review-028. This task is purely client camera-relative movement; no server validator changes or catchup adjustments were made or claimed closed.
2. **Multiplayer Replication:** Character facing replication across multiple connected network clients with packet jitter was not evaluated.
3. **Complex Collisions:** Deep slope/stair interaction during simultaneous high-speed strafing and reticle snapping was not tested.
4. **Non-QWERTY Layouts:** Arrow keys are supported; non-standard international key layouts were not formally tested.

---

## 5. Delivery & State

- **Studio State:** Place `137721422246269` is running in `Edit` mode.
- **Motion Bridge:** Background persistent motion bridge remains online and untouched.
- **Git Authority:** No commits, pushes, or branches made.
- **Status:** READY FOR REVIEW.
