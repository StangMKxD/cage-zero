# RF02-CAMERA-RELATIVE — Implementation & Verification Report (006)

**Date:** 2026-10-27  
**Owner:** Stang  
**Controller / Reviewer:** Codex (`w2:p43`)  
**Implementer:** Argon (`w2:p4M`, Gemini 3.8 Flash High)  
**Project:** `C:\Users\Stang\cage-zero` (PlaceId: `137721422246269`)  
**Base:** Commit `b374102` (`feat(rf02): camera-relative 360 analog locomotion and dynamic turn arc`)  
**Governance:** Governed by [`assets/camera-relative-HANDOFF.md`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/camera-relative-HANDOFF.md), Owner Q1–Q4 Grill Decisions, and [`assets/review-032.md`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/review-032.md) (RF-F48)

---

## 1. Executive Summary & Defect Resolutions

This report documents the resolution of **RF-F48** (duplicated landing start leaving WalkSpeed 32 after Shift release) identified in `review-032`, following independent verification of the 5 prior suites and the reviewer's reproducer harness `.sandbox/review/rf46-stop-after-landing.js`.

### RF-F48: Duplicated Landing Start Leaving WalkSpeed 32 after Shift Release
- **Root Cause Identified in Review-032:**
  1. **Duplicate Landing Requests:** When landing from a jump, Roblox Humanoid state transitions rapidly: `Freefall -> Landed` followed within ~10ms by `Landed -> Running`. `SprintController:setupCharacter` previously invoked `syncSprintIntent(true)` on both `Landed` and `Running`.
  2. **Rate-Limit Rejection on Second Request:** The first request was granted (`WalkSpeed = 32`, `IsSprinting = true`). The second request at +10ms arrived within the 50ms rate-limit cooldown window (`START_RATE_LIMIT_INTERVAL_SEC = 0.05`). `SprintService` cleared `IsSprinting = false` and incremented `SprintRejectedSeq`, but left `humanoid.WalkSpeed = 32`.
  3. **Client Optimistic Clearing & Stranded Stop:** The client negative edge cleared `isSprinting = false` and scheduled a retry timer (+70ms). When the player released Shift before the retry timer elapsed, `syncSprintIntent` and `resetSprintState` checked `if isSprinting then`. Because `isSprinting` was already false, no stop packet was sent. The retry timer was cancelled, stranding the server at `WalkSpeed = 32` indefinitely.

- **Fix Implemented:**
  1. **Eliminate Duplicate Resume on Ordinary Ground Transition:**
     - In [`SprintController.luau`](file:///C:/Users/Stang/cage-zero/src/client/controllers/SprintController.luau), the `humanoid.StateChanged` observer checks `wasAirborne = (oldState == Jumping or oldState == Freefall)`.
     - Only an actual transition from airborne to ground initiates `syncSprintIntent(true)`.
     - Ordinary ground-to-ground transitions (`Landed -> Running`) do not force-resend sprint if already sprinting, completely eliminating duplicate requests on landing.
  2. **Decouple Stop Packet from Optimistic Client State:**
     - Added `serverSprintRequested: boolean` in [`SprintController.luau`](file:///C:/Users/Stang/cage-zero/src/client/controllers/SprintController.luau).
     - Whenever sprint eligibility ends (`not isEligible`) or sprint is reset via focus loss, death, or window blur (`resetSprintState`), the controller checks:
       `if isSprinting or serverSprintRequested or serverFlag then`
     - If a start intent was ever sent or the server has sprint active, an authoritative stop packet (`{ isShiftHeld = false, isMoving = false, forward = 0 }`) is guaranteed to be delivered, clearing `serverSprintRequested = false`. Stop delivery never depends solely on optimistic `isSprinting`.
  3. **Reconcile Effective Speed and Sprint Flag on Rejection:**
     - In [`SprintService.luau`](file:///C:/Users/Stang/cage-zero/src/server/services/SprintService.luau), whenever a start request is rejected (due to invalid locomotion state or rate-limit cooldown), the service explicitly resets:
       ```luau
       humanoid.WalkSpeed = SprintConfigs.NORMAL_WALK_SPEED
       character:SetAttribute("IsSprinting", false)
       character:SetAttribute("SprintRejectedSeq", (character:GetAttribute("SprintRejectedSeq") or 0) + 1)
       ```
     - Server `WalkSpeed` and `IsSprinting` attribute are guaranteed to remain 100% consistent across all rejection and grant paths.

---

## 2. Checksum & File Metrics (Disk Working Tree)

| Target File | Disk Bytes | djb2 Checksum | Working Status |
| :--- | :--- | :--- | :--- |
| `src/server/services/SprintService.luau` | 8,104 | `27921103` | Modified (RF-F48 speed/flag consistency on rejection) |
| `src/client/controllers/SprintController.luau` | 10,270 | `1272493400` | Modified (RF-F48 wasAirborne gate & decoupled stop) |
| `src/client/controllers/MovementHeadingPreviewController.luau` | 17,066 | `3438070945` | Unmodified since `b374102` |
| `src/shared/configs/CameraPreviewConfigs.luau` | 2,774 | `3093956625` | Unmodified since `b374102` |
| `src/shared/configs/SprintConfigs.luau` | 808 | `4285292666` | Unmodified since `b374102` |

- **Rojo Packaging:** `rojo build default.project.json --output $env:TEMP\cage-zero-r5.rbxlx` passed cleanly without warnings or errors.
- **Git Checkpoint Integrity:** Commit `b374102` remains the baseline checkpoint; changes remain strictly uncommitted in the working tree per review instructions (no git commit/amend/push/publish).
- **Studio Connection Status:** **OFFLINE** (Place closed / disconnected). Live Studio readback is marked **NOTRUN (Studio Offline)** honestly; Studio was not reopened.

---

## 3. Comprehensive Verification Test Results (Node.js Deterministic Port)

> [!NOTE]
> The test results below are executed via an isolated Node.js deterministic port harness (`.sandbox/test_rf_f46_comprehensive.js`) replicating exact client/server functions, clocks, and Roblox signal mocks with realistic attribute edge semantics (`prev !== val`). This is deterministic model evidence, not live Luau/Studio runtime execution.

### Suite Summary (8/8 Suites Passed)
- **Suite 1: RF-F46 Exact Mid-Air Re-engagement Repro:**
  - Initial ground sprint: `WalkSpeed = 32`, `isSprinting = true`.
  - Jump liftoff into `Freefall`: `WalkSpeed = 16`, `isSprinting = false`.
  - Mid-air neutral intent (`SetMovementIntent(false)`) -> no packets sent.
  - Mid-air re-engagement (`SetMovementIntent(true)`) -> inhibited by `isLocomotionEligible()`, optimistic `isSprinting` stays `false`, held intent preserved in memory.
  - Touchdown (`Landed`): seamless recovery to `WalkSpeed = 32`, `isSprinting = true`. **PASS**.
- **Suite 2: Server State Rejection Gate (Airborne Ingress):**
  - Direct airborne sprint request rejected by server; sets `WalkSpeed = 16`, `IsSprinting = false`, increments `SprintRejectedSeq`. **PASS**.
- **Suite 3: 360° Locomotion Sprint Speeds:**
  - `W`, `A`, `S`, `D`, and moving tables all grant `WalkSpeed = 32` when Shift is held.
  - Stationary + Shift: `WalkSpeed = 16`. Moving without Shift: `WalkSpeed = 16`. **PASS**.
- **Suite 4: RF-F44 Ingress & Domain Security:**
  - Legacy `true` without direction: rejected (16).
  - Out-of-domain forward `100` / `-2`: rejected (16).
  - Safe stop boolean `false`: accepted (16). **PASS**.
- **Suite 5: RF-F45 Rate-Limit Rejection & Bounded Retry:**
  - Start -> immediate stop (10ms) -> immediate restart (10ms) (< 50ms cooldown) triggers rate rejection.
  - `SprintRejectedSeq` increments, speed remains 16.
  - Bounded retry timer (+70ms) fires and safely restores `WalkSpeed = 32`. **PASS**.
- **Suite 6: RF-F48 Landed -> Running 10ms & Shift Release (Review-032 Exact Case):**
  - `Freefall` with held Shift + moving -> `Landed`: grants `WalkSpeed = 32`, client `true`, server `true`.
  - Transition to `Running` at +10ms: `wasAirborne` is false and already sprinting -> does NOT send duplicate start request. Speed remains 32, no rate rejection.
  - Release Shift before 70ms retry window: client sends authoritative stop -> server immediately resets `WalkSpeed = 16`, `IsSprinting = false`. **PASS**.
- **Suite 7: Focus Loss & Context Loss Sprint Release:**
  - Active sprint at 32 -> trigger `resetSprintState` (simulating `WindowFocusReleased`, `MenuOpened`, `TextBoxFocused`).
  - Immediately delivers stop request: `WalkSpeed = 16`, client `false`, server `false`.
  - Clock advance proves no lingering retry tasks re-enable sprint. **PASS**.
- **Suite 8: Release During Negative-Ack Rate-Limit Cooldown:**
  - Rate-limited restart puts character at 16 with negative ack received.
  - Releasing Shift during the 70ms retry cooldown cancels the timer and delivers authoritative stop.
  - Advancing clock past retry window proves `WalkSpeed` remains 16 and flag remains false. **PASS**.

---

## 4. Reviewer Harness Execution (`.sandbox/review/rf46-stop-after-landing.js`)

Executed reviewer independent reproducer directly via Node.js:
```json
{
  "testKind": "Independent extension of implementer JS port; not live Luau/Roblox",
  "landedSpeed": 32,
  "beforeRelease": {
    "speed": 32,
    "client": true,
    "serverFlag": true
  },
  "afterShiftRelease": {
    "speed": 16,
    "client": false,
    "serverFlag": false
  },
  "expectedStopSpeed": 16,
  "passed": true
}
```
**Verdict:** `passed: true`.
