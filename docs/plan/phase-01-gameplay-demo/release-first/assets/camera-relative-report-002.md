# RF02-CAMERA-RELATIVE — Implementation & Verification Report (002)

**Date:** 2026-10-27  
**Owner:** Stang  
**Controller / Reviewer:** Codex (`w2:p43`)  
**Implementer:** Argon (`w2:p4M`, Gemini 3.8 Flash High)  
**Project:** `C:\Users\Stang\cage-zero`  
**Base:** HEAD `9db6122` + protected dirty tree  
**Governance:** Governed by [`assets/camera-relative-HANDOFF.md`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/camera-relative-HANDOFF.md) & [`assets/review-029.md`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/review-029.md) (RF-F43 Resolution)

---

## 1. Resolution of RF-F43 (Airborne Disagreement & Unsupported States)

Review-029 identified that `checkIsAirborne()` returned `false` immediately if `AirMovementController.IsAirborne()` returned `false`, even when native `Humanoid:GetState()` was `Freefall` or `Jumping`. This allowed `updateGroundedFacing` to write character yaw mid-air during transition/replication gaps. Additionally, non-ground states (`Seated`, `Climbing`, `Swimming`, `Physics`, `Ragdoll`) were treated as grounded, forcing camera reticle yaw where it should hand off. Furthermore, `jumpBufferUntil = 0` inside `isAirborne` was eating legitimate landing-edge buffered jumps.

### Implementation Fix in [`MovementHeadingPreviewController.luau`](file:///C:/Users/Stang/cage-zero/src/client/controllers/MovementHeadingPreviewController.luau)
1. **OR Airborne Logic (`checkIsAirborne`):**
   ```luau
   local function checkIsAirborne(): boolean
       local nativeAirborne = false
       if currentHumanoid and currentHumanoid.Parent then
           local state = currentHumanoid:GetState()
           nativeAirborne = (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall)
       end
       local airCtrl = getAirMovementController()
       local ctrlAirborne = (airCtrl ~= nil and airCtrl.IsAirborne ~= nil and airCtrl.IsAirborne() == true)
       return nativeAirborne or ctrlAirborne
   end
   ```
   If either native Humanoid is in `Jumping`/`Freefall` OR `AirMovementController` indicates airborne, the state is strictly treated as airborne.
2. **Explicit Ground Eligibility (`isEligibleGrounded`):**
   - Strictly rejects `Jumping` and `Freefall`.
   - Strictly rejects `airCtrl.IsAirborne() == true`.
   - Strictly rejects unsupported/specialized states: `Seated`, `Climbing`, `Swimming`, `Physics`, `Ragdoll`, `Dead`.
   - Rejects `FloorMaterial == Air` (unless in the instant `Landed` transition state).
3. **Dedicated Unsupported State Hand-off:**
   When in an unsupported state, `onMovementStep` hands off cleanly:
   - Does NOT call `updateGroundedFacing`.
   - Restores `AutoRotate = true` so native vehicle, seat, ladder, swimming, and ragdoll rotation functions without interference.
   - Publishes `Vector3.zero` lean input so residual air lean does not persist.
4. **Preserved Landing-Edge Jump Buffer:**
   - Removed unconditional `jumpBufferUntil = 0` inside `isAirborne`.
   - Jump buffer is now cleared only when `state == Enum.HumanoidStateType.Jumping` (liftoff achieved) or when the time window naturally elapses. Pre-landing jump presses within `JUMP_BUFFER_WINDOW_SEC` now reliably trigger jump upon touching down.

---

## 2. File Checksums & Parity Matrix

### Scoped Files
- [`src/client/controllers/MovementHeadingPreviewController.luau`](file:///C:/Users/Stang/cage-zero/src/client/controllers/MovementHeadingPreviewController.luau)
- [`src/shared/configs/CameraPreviewConfigs.luau`](file:///C:/Users/Stang/cage-zero/src/shared/configs/CameraPreviewConfigs.luau)

| File | Disk Bytes | djb2 Checksum | SHA-256 |
| :--- | :--- | :--- | :--- |
| `src/shared/configs/CameraPreviewConfigs.luau` | 2,166 | `1316643812` | `0aa9169250b98966110b5e4b9aba1848062b4cfd3c97f0be36c011758be3312e` |
| `src/client/controllers/MovementHeadingPreviewController.luau` | 14,795 | `2379847643` | `50a5c813f94800c84b825db3e067a3773c8be3948ed6dbe719db2500782b59e6` |

- **Rollback Backup:** Saved to `.sandbox/rollback/rf02-camera-relative-r1/`.
- **Rojo Build:** `rojo build default.project.json --output $env:TEMP\cage-zero-cam-rel-r1.rbxlx` passed cleanly.

---

## 3. Deterministic Verification Matrix (12/12 PASS)

| Test Case | Conditions (`airCtrl`, `HumanoidState`, `FloorMaterial`) | Expected Branch | Ground Yaw Written? | Result |
| :--- | :--- | :--- | :--- | :--- |
| **1. RF-F43 Core (Air Disagreement)** | `airCtrl = false`, `Freefall`, `Floor = Air` | `airborne` | **No** (Blocked) | **PASS** |
| **2. RF-F43 Core (Takeoff Disagreement)** | `airCtrl = false`, `Jumping`, `Floor = Plastic` | `airborne` | **No** (Blocked) | **PASS** |
| **3. Normal Air** | `airCtrl = true`, `Freefall`, `Floor = Air` | `airborne` | **No** (Blocked) | **PASS** |
| **4. Controller Latch Lag** | `airCtrl = true`, `Running`, `Floor = Plastic` | `airborne` | **No** (Blocked) | **PASS** |
| **5. Unsupported: Seated** | `airCtrl = false`, `Seated`, `Floor = Plastic` | `unsupported` | **No** (AutoRotate=true) | **PASS** |
| **6. Unsupported: Climbing** | `airCtrl = false`, `Climbing`, `Floor = Air` | `unsupported` | **No** (AutoRotate=true) | **PASS** |
| **7. Unsupported: Swimming** | `airCtrl = false`, `Swimming`, `Floor = Water` | `unsupported` | **No** (AutoRotate=true) | **PASS** |
| **8. Unsupported: Physics/Ragdoll** | `airCtrl = false`, `Physics`, `Floor = Plastic` | `unsupported` | **No** (AutoRotate=true) | **PASS** |
| **9. Unsupported: Dead** | `airCtrl = false`, `Dead`, `Health = 0` | `unsupported` | **No** (AutoRotate=true) | **PASS** |
| **10. Edge: Cliff Walk-off** | `airCtrl = false`, `Running`, `Floor = Air` | `unsupported` | **No** (Blocked) | **PASS** |
| **11. Supported Ground: Running** | `airCtrl = false`, `Running`, `Floor = Plastic` | `grounded` | **Yes** (Faces Reticle) | **PASS** |
| **12. Supported Ground: Landed** | `airCtrl = false`, `Landed`, `Floor = Plastic` | `grounded` | **Yes** (Faces Reticle) | **PASS** |

---

## 4. Studio Environment & Standing Constraints

1. **Studio Connection Status:** Currently offline (`studios: []`). Per strict standing guardrail rule (*"no reopening closedStudio or force-stopping Owner test on own"*), Studio was NOT relaunched by the agent. Source files are verified on disk and ready for instant sync upon Owner launch.
2. **Open Findings (Honest Tracking):**
   - **RF-F42:** Server-side yaw catchup gap remains OPEN (out of camera client scope).
   - **RF-F24 / RF-F25:** Historical arena occlusion and async setup / rapid respawn lifecycle items remain OPEN.
3. **Protected State:**
   - Persistent Motion bridge remains ONLINE.
   - Dribble / front-control work remains PAUSED.
   - No Git commits, pushes, or branch changes.
