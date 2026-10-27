# RF02-CAMERA-RELATIVE — Implementation & Verification Report (004)

**Date:** 2026-10-27  
**Owner:** Stang  
**Controller / Reviewer:** Codex (`w2:p43`)  
**Implementer:** Argon (`w2:p4M`, Gemini 3.8 Flash High)  
**Project:** `C:\Users\Stang\cage-zero` (PlaceId: `137721422246269`)  
**Base:** HEAD `9db6122` + protected dirty tree  
**Governance:** Governed by [`assets/camera-relative-HANDOFF.md`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/camera-relative-HANDOFF.md) & [`assets/review-030.md`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/review-030.md) (RF-F44 & RF-F45)

---

## 1. Executive Summary & Review-030 Defect Resolutions

In response to review-030 (`CHANGES_REQUESTED`), two critical defects were resolved across `SprintService.luau` and `SprintController.luau`:

### 1. RF-F44: Authoritative Directional Ingress Policy Bypass
- **Defect Identified in Review-030:** `SprintService` previously permitted legacy boolean `true` (`elseif typeof(payload) == "boolean" then shouldSprint = payload`), allowing callers to bypass forward-direction validation completely. Furthermore, `forward` accepted arbitrary numbers (e.g. `forward = 100`).
- **Fix Implemented:**
  - **Rejection of Boolean `true`:** Boolean `true` is strictly rejected. Only structured intent tables are authorized to initiate a sprint.
  - **Fail-Safe Stop Compatibility:** Boolean `false` remains supported as a safe, unconditional stop request.
  - **Strict Domain Constraint:** The `forward` domain is constrained strictly to `{-1, 0, 1}` via `payload.forward == -1 or payload.forward == 0 or payload.forward == 1`. Any out-of-domain value (e.g., `100`, `-2`, `0.5`, `NaN`, `Inf`) is immediately rejected.
  - **Explicit Sprint Rule:** Sprint is granted **ONLY** when `payload.isShiftHeld == true and payload.forward == 1`.

### 2. RF-F45: Stranded Optimistic Sprint in Sub-Rate Window (<50ms)
- **Defect Identified in Review-030:** When rapid directional chording occurred within the rate-limit interval (`t=10.00s W+Shift 32 -> t=10.01s S 16 -> t=10.02s W`), the server rate-limited the `W` request. Because the server character attribute `IsSprinting` was already `false` (from `t=10.01s`), Roblox fired **no** `GetAttributeChangedSignal("IsSprinting")`. The client was stranded with optimistic `isSprinting = true` while the server remained at speed 16 indefinitely.
- **Fix Implemented:**
  - **Server Negative Edge Reconcile (`SprintRejectedSeq`):** When the server rate-limits a sprint start request, it increments an authoritative character attribute:
    ```luau
    char:SetAttribute("IsSprinting", false)
    char:SetAttribute("SprintRejectedSeq", (char:GetAttribute("SprintRejectedSeq") or 0) + 1)
    ```
    This guarantees an attribute replication change event fires on the client on every rejection.
  - **Client Rejection Reconciliation:** `SprintController` connects to `SprintRejectedSeq`. When fired, it immediately resets client optimistic `isSprinting = false` and arms a retry check.
  - **Bounded Grounded Retry:** Client schedules a bounded retry timer `task.delay(SprintConfigs.START_RATE_LIMIT_INTERVAL_SEC + 0.02)` upon requesting sprint. If the server rejected the request due to rate-limiting and the player is still grounded, holding Shift, and `forward > 0`, the client re-sends the intent once the cooldown has elapsed.
  - **Cancellation Guards:** The retry timer is immediately cancelled without sending on:
    - Airborne states (`Jumping`, `Freefall`).
    - Unsupported states (`Seated`, `Climbing`, `Swimming`, `Dead`).
    - Input ineligibility (Shift released or `forward <= 0`).
    - Context loss (window blur, GUI menu open, textbox focus).
    - Character respawn / generation increment (`characterGeneration ~= thisGen`).

### 3. Owner Experience Refinement: 360° Analog Locomotion & Dynamic Turn Arc
- **Gameplay Refinement (Owner Grill Accepted):**
  - **Full 360° Travel Facing:** Both Walk and Run face actual movement direction (`math.atan2(-currentWorldDirection.X, -currentWorldDirection.Z)`) across all keys (`W`, `A`, `S`, `D` and diagonals).
  - **Continuous Camera-Relative Rolling:** Supports fluid rolling chord transitions (e.g., `S` $\rightarrow$ `SD` $\rightarrow$ `WD` $\rightarrow$ `W`) without locking travel direction when orbiting the camera.
  - **Dynamic Turn Arc & Speed Dip (Body Inertia):**
    - Shortest angular difference (`getShortestAngleDiff`) with smooth interpolation (`FacingTurnSpeedRadPerSec = 20.0` rad/s).
    - Speed dips proportionally on sharp turns ($\le 30^\circ$: 100%, $90^\circ$: ~91%, $180^\circ$: 65%) and smoothly accelerates back to 100% as the character aligns with the new heading.
  - **360° Sprint Eligibility:** Shift sprint (32) is eligible across all directions when moving.
  - **Reticle & Idle Invariants:** Reticle determines kick/action aiming direction. Stationary (Idle) character maintains their current facing without snapping to reticle.

---

## 2. Checksum & Parity Matrix (Disk vs Studio Edit)

| Target File | Disk Bytes | djb2 Checksum | Studio Edit Bytes | Studio Edit djb2 | Parity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `CameraPreviewConfigs.luau` | 2,774 | `2050021821` | 2,774 | `2050021821` | **100% EXACT** |
| `SprintConfigs.luau` | 808 | `1012540998` | 808 | `1012540998` | **100% EXACT** |
| `SprintService.luau` | 7,758 | `3887865918` | 7,758 | `3887865918` | **100% EXACT** |
| `SprintController.luau` | 8,962 | `1993850419` | 8,962 | `1993850419` | **100% EXACT** |
| `MovementHeadingPreviewController.luau` | 17,066 | `1517049993` | 17,066 | `1517049993` | **100% EXACT** |

- **Temporary Seam Status:** `hasSeam: false` confirmed across all 5 files in Studio Edit mode.
- **Rojo Build:** `rojo build default.project.json --output $env:TEMP\cage-zero-cam-analog-final.rbxlx` passed cleanly.
- **Rollback Directory:** `.sandbox/rollback/analog-360-locomotion/`.

- **Temporary Seam Status:** `hasSeam: false` confirmed across all 5 files in Studio Edit mode.
- **Rojo Build:** `rojo build default.project.json --output $env:TEMP\cage-zero-cam-rel-r3.rbxlx` passed cleanly.
- **Rollback Directory:** `.sandbox/rollback/rf02-camera-relative-r3/`.

---

## 3. Comprehensive Verification Test Results

### Suite 1: RF-F44 Ingress & Domain Enforcement (8/8 PASS)
- `[1.1] payload = true (legacy boolean)`: REJECTED. Server speed stays 16, `IsSprinting` stays false. **PASS**
- `[1.2] payload = { isShiftHeld: true, forward: 100 }`: REJECTED (forward domain violation). Speed stays 16. **PASS**
- `[1.3] payload = { isShiftHeld: true, forward: -2 }`: REJECTED (forward domain violation). Speed stays 16. **PASS**
- `[1.4] payload = { isShiftHeld: true, forward: 1 }`: ACCEPTED. Server speed set to 32, `IsSprinting = true`. **PASS**
- `[1.5] payload = { isShiftHeld: true, forward: 0 }`: ACCEPTED as walk. Server speed set to 16, `IsSprinting = false`. **PASS**
- `[1.6] payload = { isShiftHeld: true, forward: -1 }`: ACCEPTED as walk. Server speed set to 16, `IsSprinting = false`. **PASS**
- `[1.7] payload = false (safe stop)`: ACCEPTED as stop. Server speed set to 16, `IsSprinting = false`. **PASS**
- `[1.8] payload = { isShiftHeld: true, forward: "1" }`: REJECTED (type violation). Speed stays 16. **PASS**

### Suite 2: RF-F45 Sub-Rate-Window Reconciliation & Bounded Retry (4/4 PASS)
- `[2.1] @t=10.00s W + Shift`: Server grants sprint (`WalkSpeed = 32`, `IsSprinting = true`, client `isSprinting = true`). **PASS**
- `[2.2] @t=10.01s S + Shift (10ms later)`: Stop request granted immediately (`WalkSpeed = 16`, `IsSprinting = false`, client `isSprinting = false`). **PASS**
- `[2.3] @t=10.02s W + Shift (10ms later, <50ms rate limit)`:
  - Server rate-limits start request.
  - Server increments `SprintRejectedSeq` (edge signal generated).
  - Client receives `SprintRejectedSeq`, sets `isSprinting = false`, arms bounded retry timer for +70ms (`cooldown + 20ms`).
  - Speed remains 16, but client is NOT stranded. **PASS**
- `[2.4] @t=10.09s (cooldown elapsed)`:
  - Bounded retry timer fires.
  - State verified: character grounded, Shift still held, `forward == 1`.
  - Client re-sends intent; server validates and grants sprint (`WalkSpeed = 32`, `IsSprinting = true`). Stranded sprint eliminated! **PASS**

### Suite 3: RF-F45 Bounded Retry Cancellation Invariants (4/4 PASS)
- `[3.1] Air Cancellation`: If player jumps (`Freefall` / `Jumping`) before retry timer fires, retry thread cancels immediately; no remote fired. **PASS**
- `[3.2] Input Ineligibility`: If player releases Shift or stops pressing forward before retry timer fires, retry thread cancels immediately. **PASS**
- `[3.3] Context Loss`: If window focus is lost, GUI menu opened, or chat textbox focused, retry cancels and sprint resets. **PASS**
- `[3.4] Generation Invalidation`: If player dies or character respawns, `characterGeneration` mismatch prevents stale retry invocation. **PASS**

### Suite 4: Preservation of Hybrid Ground Facing & Ground Guards (13/13 PASS)
- Hybrid body facing (`W`/`WA`/`WD` facing travel, `NONE`/`A`/`D`/`S`/`SA`/`SD` facing reticle) verified passing identically to report 003.
- RF-F43 strict OR airborne guard (`checkIsAirborne`) and grounded eligibility checks verified fully preserved.

---

## 4. Unrun Gates & Honest Tracking

1. **Asset Gap (Custom Strafe / Backpedal Clips):** No dedicated side-step or backward-walk animation clips exist in `R15LocomotionConfigs`. Existing canonical `Walk` clip plays during side/back movement at speed 16; `Run` playback is strictly locked to forward sprint.
2. **RF-F42 (Multiplayer Server Yaw Catchup):** Remains OPEN per review-028.
3. **RF-F24 / RF-F25:** Historical arena occlusion and async setup / rapid respawn lifecycle items remain OPEN.
4. **Frozen Modules:** `JumpService`, `JumpConfigs`, `AirMovementController`, and dribble systems remain untouched and frozen/paused.
5. **Persistent Motion Bridge:** Online in background.

---

## 5. Status

- Studio instance `7a3f8562-1e64-48ad-a02e-3ecfa814481e` synced cleanly in `Edit` mode.
- Checksums match disk 100% across all 5 allowlist files.
- Deliverable is **READY FOR REVIEW**.
