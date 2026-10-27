# RF02-CAMERA-RELATIVE — Implementation & Verification Report (003)

**Date:** 2026-10-27  
**Owner:** Stang  
**Controller / Reviewer:** Codex (`w2:p43`)  
**Implementer:** Argon (`w2:p4M`, Gemini 3.8 Flash High)  
**Project:** `C:\Users\Stang\cage-zero` (PlaceId: `137721422246269`)  
**Base:** HEAD `9db6122` + protected dirty tree  
**Governance:** Governed by [`assets/camera-relative-HANDOFF.md`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/camera-relative-HANDOFF.md) (Final Owner Grill Delta) & [`assets/review-029.md`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/review-029.md)

---

## 1. Executive Summary & Implemented Specifications

Following the completion of the Owner Grill session, the camera-relative movement and facing system was updated to implement the newly confirmed **Hybrid Ground Facing** and **Directional Sprint Eligibility** model:

1. **Hybrid Ground Body Facing (`MovementHeadingPreviewController.luau`):**
   - **Forward Travel (`W`, `W+A`, `W+D`, resolved `forward > 0`):** Character body yaw faces the **actual camera-relative travel direction**. The character runs forward into their direction of travel with normal forward running poses, completely eliminating awkward sideways sprint angles when countersteering diagonally!
   - **Stationary & Camera-Facing Movements (`NONE`, `A`, `D`, `S`, `S+A`, `S+D`, resolved `forward <= 0`):** Character body yaw continuously faces the **camera reticle aim** (ShiftLock style).
   - **Opposing Key Cancellation:** Keys resolve algebraically first:
     - `W + S = 0` (forward component cancels). `W + S + A` behaves as pure `A` (faces reticle, sidewalk at 16, sprint disabled).
     - `A + D = 0` (lateral component cancels). `W + A + D` behaves as pure `W` (faces travel forward).
   - **Diagonal Normalization:** All diagonal inputs are normalized to unit vector length (1.0), preventing faster diagonal movement.

2. **Authoritative Directional Sprint & Speed Control (`SprintController`, `SprintService`, `SprintConfigs`):**
   - **Sprint Speed (32) Eligibility:** Permitted **ONLY when resolved forward > 0 AND Shift is held**.
   - **Sidewalk & Backpedal Speed (16):** `A`, `D` (sidewalk) and all `S`, `S+A`, `S+D` (backpedal) are capped at **WalkSpeed 16 EVEN WHEN SHIFT IS HELD**.
   - **Seamless Rapid Directional Switching:**
     - Holding Shift while switching `W -> A/S -> W` immediately revokes sprint (WalkSpeed 16) when moving side/back, but preserves the physical Shift key held state in memory.
     - Returning to `W` immediately resumes sprint (WalkSpeed 32) without releasing and re-pressing Shift!
   - **Rate-Limit Lock Prevention:** `SprintConfigs.START_RATE_LIMIT_INTERVAL_SEC` set to `0.05s` (50ms). Stopping sprint is never rate-limited. Rapid human direction changes (100–150ms) switch speeds cleanly without rate-limit lock.
   - **Server Authority & Security:**
     - Server determines authoritative speed (16 vs 32) based on validated directional intent `{ isShiftHeld: boolean, forward: number }`.
     - Client never specifies speed numbers or velocities.
     - Malformed payloads (nil, strings, numbers, NaN, Inf, injected tables) are strictly rejected.

3. **Preservation of RF-F43 Ground & Airborne Guards:**
   - Strict OR airborne detection (`checkIsAirborne`): native `Jumping`/`Freefall` OR `AirMovementController.IsAirborne()`.
   - Explicit grounded eligibility (`isEligibleGrounded`): rejects air, rejects unsupported states (`Seated`, `Climbing`, `Swimming`, `Physics`, `Ragdoll`, `Dead`), and requires non-air floor material.
   - Unsupported states cleanly restore `AutoRotate = true` and hand off orientation.
   - Landing-edge jump buffer is preserved (not wiped in air; only cleared on liftoff `state == Jumping`).

4. **Asset Gap Inspection (Animation):**
   - Inspected `src/shared/configs/R15LocomotionConfigs.luau`: canonical clips are `Idle`, `Walk`, `Run`, `Jump`, `Land`.
   - **Asset Gap Finding:** No custom authored strafe (left/right) or backpedal animation clips exist in the repository. Existing canonical `Walk` (`RF02_Walk_Ready_R15_v01`) plays during side/back movement at speed 16. `Run` playback is strictly forbidden during side/back movement and only plays during eligible forward sprint (where body faces travel).

---

## 2. Checksum & Parity Matrix (Disk vs Studio Edit)

| Target File | Disk Bytes | djb2 Checksum | SHA-256 | Studio Edit Bytes | Studio Edit djb2 | Parity |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `CameraPreviewConfigs.luau` | 2,166 | `1316643812` | `0aa9169250b98966110b5e4b9aba1848062b4cfd3c97f0be36c011758be3312e` | 2,166 | `1316643812` | **100% EXACT** |
| `SprintConfigs.luau` | 808 | `1012540998` | `041cbdc2ea046d229a9e60571926676c61618bc853b6d5bd3d771ed9ab360a42` | 808 | `1012540998` | **100% EXACT** |
| `SprintService.luau` | 7,352 | `1514490889` | `a5fdca6d3604e876e761f833b4fd64d3af561520b090bfeb215e5b4eae435c75` | 7,352 | `1514490889` | **100% EXACT** |
| `SprintController.luau` | 7,037 | `2359396867` | `f7dc64ccd723c97a1111d14b5a9f678910799c26f6da29d7cb957dd7e2d6ce48` | 7,037 | `2359396867` | **100% EXACT** |
| `MovementHeadingPreviewController.luau` | 16,165 | `3150028356` | `390bc1aaf3e0d4f45b168dcf3f83973430c9387d6c0ad0eff1bdc8c84ed36670` | 16,165 | `3150028356` | **100% EXACT** |

- **Temporary Seam Status:** `hasSeam: false` confirmed in Studio Edit mode.
- **Rojo Build:** `rojo build default.project.json --output $env:TEMP\cage-zero-cam-rel-r2-final.rbxlx` passed cleanly.
- **Rollback Directory:** `.sandbox/rollback/rf02-camera-relative-r2/`.

---

## 3. Comprehensive Verification Test Results

### Suite A: Hybrid Ground Facing Matrix (13/13 PASS)
- `[A.1] W alone (camYaw=0)`: `chord = "W"`, `targetYaw = 0°` (faces travel). **PASS**
- `[A.2] W+A diagonal (camYaw=0)`: `chord = "WA"`, `targetYaw = +45°` (faces travel). **PASS**
- `[A.3] W+D diagonal (camYaw=0)`: `chord = "WD"`, `targetYaw = -45°` (faces travel). **PASS**
- `[A.4] Countersteer W+A at camYaw=-45° (cam right)`: `chord = "WA"`, `targetYaw = 0°` (faces North travel). **PASS**
- `[A.5] Countersteer W+D at camYaw=45° (cam left)`: `chord = "WD"`, `targetYaw = 0°` (faces North travel). **PASS**
- `[A.6] NONE (Idle, camYaw=30°)`: `chord = "NONE"`, `targetYaw = 30°` (faces reticle). **PASS**
- `[A.7] A alone (Strafe left, camYaw=30°)`: `chord = "A"`, `targetYaw = 30°` (faces reticle). **PASS**
- `[A.8] D alone (Strafe right, camYaw=30°)`: `chord = "D"`, `targetYaw = 30°` (faces reticle). **PASS**
- `[A.9] S alone (Backpedal, camYaw=30°)`: `chord = "S"`, `targetYaw = 30°` (faces reticle). **PASS**
- `[A.10] S+A diagonal back (camYaw=30°)`: `chord = "SA"`, `targetYaw = 30°` (faces reticle). **PASS**
- `[A.11] S+D diagonal back (camYaw=30°)`: `chord = "SD"`, `targetYaw = 30°` (faces reticle). **PASS**
- `[A.12] W+S+A opposing cancellation (camYaw=30°)`: `chord = "A"`, `targetYaw = 30°` (faces reticle). **PASS**
- `[A.13] A+D opposing cancellation with W (camYaw=30°)`: `chord = "W"`, `targetYaw = 30°` (faces travel). **PASS**

### Suite B: Directional Sprint Eligibility & Authoritative Server Speeds (10/10 PASS)
- `[B.1] W + Shift`: `WalkSpeed = 32`, `IsSprinting = true`. **PASS**
- `[B.2] W+A + Shift`: `WalkSpeed = 32`, `IsSprinting = true`. **PASS**
- `[B.3] W+D + Shift`: `WalkSpeed = 32`, `IsSprinting = true`. **PASS**
- `[B.4] A + Shift`: `WalkSpeed = 16`, `IsSprinting = false`. **PASS**
- `[B.5] D + Shift`: `WalkSpeed = 16`, `IsSprinting = false`. **PASS**
- `[B.6] S + Shift`: `WalkSpeed = 16`, `IsSprinting = false`. **PASS**
- `[B.7] S+A + Shift`: `WalkSpeed = 16`, `IsSprinting = false`. **PASS**
- `[B.8] S+D + Shift`: `WalkSpeed = 16`, `IsSprinting = false`. **PASS**
- `[B.9] W+S+A + Shift`: `WalkSpeed = 16`, `IsSprinting = false`. **PASS**
- `[B.10] W alone (Shift released)`: `WalkSpeed = 16`, `IsSprinting = false`. **PASS**

### Suite C: Rapid Shift-Held Transition Simulation (6/6 PASS)
- `@t=0.10s Press W with Shift`: `WalkSpeed = 32`. **PASS**
- `@t=0.16s Switch to A (Shift held)`: `WalkSpeed = 16` (immediately revoked). **PASS**
- `@t=0.22s Switch back to W (Shift held)`: `WalkSpeed = 32` (resumed without re-press). **PASS**
- `@t=0.28s Switch to S (Shift held)`: `WalkSpeed = 16` (immediately revoked). **PASS**
- `@t=0.34s Switch back to W (Shift held)`: `WalkSpeed = 32` (resumed without re-press). **PASS**
- `@t=0.40s Release Shift (W still held)`: `WalkSpeed = 16` (immediately revoked). **PASS**

### Suite D: Malformed Payload Security Validation (7/7 PASS)
- `nil` payload: REJECTED safely. **PASS**
- `string` payload: REJECTED safely. **PASS**
- `arbitrary numeric speed injection (9999)`: REJECTED safely. **PASS**
- `table with injected arbitrary speed`: Server overrides to configured 32. **PASS**
- `table with NaN forward`: REJECTED safely. **PASS**
- `table with Infinite forward`: REJECTED safely. **PASS**
- `table with non-boolean isShiftHeld`: REJECTED safely. **PASS**

### Suite E: Ground Eligibility & Airborne Guard (RF-F43) (12/12 PASS)
- All 12 state combinations (airborne disagreement, cliff walk-off, unsupported states, supported ground) verified passing identically to report 002.

---

## 4. Unrun Gates & Honest Tracking

1. **Asset Gap (Custom Strafe / Backpedal Clips):** No dedicated side-step or backward-walk animation clips exist in `R15LocomotionConfigs`. Existing `Walk` clip plays at speed 16; `Run` is strictly locked to forward sprint.
2. **RF-F42 (Multiplayer Server Yaw Catchup):** Remains OPEN per review-028.
3. **RF-F24 / RF-F25:** Historical arena occlusion and async setup / rapid respawn lifecycle items remain OPEN.
4. **Frozen Modules:** `JumpService`, `JumpConfigs`, `AirMovementController`, and dribble systems remain untouched and frozen/paused.
5. **Persistent Motion Bridge:** Online in background.

---

## 5. Status

- Studio instance `7a3f8562-1e64-48ad-a02e-3ecfa814481e` synced cleanly in `Edit` mode.
- Deliverable is **READY FOR REVIEW**.
