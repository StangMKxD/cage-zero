# RF02 Dribble Animation Integration — Report 002 (Sprint-Only Moving Cuts, Guaranteed Ball Retention & Zero-Clipping R15 Poses)

- **Date:** 2026-10-28
- **Role:** `implementer (GAME ANIMATION-INTEGRATION IMPLEMENTER)` (`w2:p52`)
- **Task:** `RF02-DRIBBLE-ANIMATION-INTEGRATION` — Owner Grill Round 2 Refinement (`1`, `2A`, `3A`, `4`)
- **Target Studio:** `Cage-Zero (placeId: 137721422246269)` (`studio_id: c25f10b5-3780-4cee-8d21-0d25ef9eb62c`, synced, verified on `PreviewRig_R15_Boy_Height30.AnimSaves` & `Play` mode, returned to `Edit`)

---

## 1. Summary of Owner Grill Round 2 Decisions & Fixes

1. **Ball Never Drops Contact While Dribbling (`1` — ครองบอลอยู่ตลอด ยกเว้นโดนแย่ง/กระโดด/เตะ):**
   - In [`BallService.luau`](file:///C:/Users/Stang/cage-zero/src/server/services/BallService.luau), expanded `carrierInContact` distance gate for an active grounded possessor to `DribbleConfigs.LOOSE_BALL_DISTANCE` (`7.5` studs) and set `CUT_BALL_LEAD_SPRINT = 0.85` (`FRONT_DISTANCE_SPRINT 3.10 + 0.85 = 3.95` studs, strictly inside the `4.5` stud receive window).
   - The visual forward touch during a sprint cut now stays within `3.95` studs and never drops possession unless an opponent steals, the carrier jumps (Self-Lob), or shoots/passes.
2. **Live Travel Direction & Sprint-Only Cuts (`2A` — บอลเกาะตามทิศวิ่งจริงทุกเฟรม + ล็อกบอลเฉพาะตอนวิ่ง Sprint เท่านั้น):**
   - In [`BallService.luau`](file:///C:/Users/Stang/cage-zero/src/server/services/BallService.luau), removed the stale `leadDir = cutIntent.direction` override while moving so `leadDir` always follows the carrier's live `MoveDirection` on every frame (including when moving in `G` mode).
   - In [`MovementHeadingPreviewController.luau`](file:///C:/Users/Stang/cage-zero/src/client/controllers/MovementHeadingPreviewController.luau), gated dribble cut triggers (`DribbleCutController.TryStart`) so they **only trigger while sprinting (`sprintingNow and not activeGoal`)**. Normal walking and `G` close-control mode no longer trigger cut locks, and releasing sprint or pressing `G` cancels any active cut cleanly.
3. **Zero Leg-Cross Clipping via Forward-Kinematics Verification on `PreviewRig_R15_Boy_Height30` (`3A` + `4`):**
   - Verified on `PreviewRig_R15_Boy_Height30` that in R15 `Motor6D` coordinates, `LeftUpperLeg` abducts outward with `HipRoll < 0` and `RightUpperLeg` abducts outward with `HipRoll > 0`.
   - Fixed `makeDiagFrontPose` and `makeDiagBackPose` in [`DribbleClipData.luau`](file:///C:/Users/Stang/cage-zero/src/client/character/DribbleClipData.luau) so both legs always abduct outward (`minKneeLat(R-L) >= +0.89` studs, `minFootLat(R-L) >= +0.89` studs across all 9 clips; zero negative/crossed frames).
   - Rebuilt all 9 `KeyframeSequence`s in `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves`.

---

## 2. Rig Forward-Kinematics Clearance Matrix (`PreviewRig_R15_Boy_Height30`)

| Clip Name | Keyframes | Duration | Min Hip Dist | Min Knee Dist | Min Foot Dist | Min Knee Lateral `(R.x - L.x)` | Min Foot Lateral `(R.x - L.x)` |
| --- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `RF02_WalkDribble_R15_v01` | 33 | 1.04s | 0.87 | 0.97 | 1.02 | +0.95 | +0.98 |
| `RF02_RunDribble_R15_v01` | 33 | 0.72s | 0.88 | 1.02 | 1.12 | +0.97 | +0.98 |
| `RF02_GMode_SlowControlLoop_R15_v01` | 33 | 1.12s | 0.95 | 1.19 | 1.29 | +1.16 | +1.24 |
| `RF02_CutDiagFrontLeft_AW_R15_v01` | 69 | 0.68s | 0.85 | 0.89 | 0.91 | +0.89 | +0.91 |
| `RF02_CutDiagFrontRight_WD_R15_v01` | 69 | 0.68s | 0.85 | 0.89 | 0.91 | +0.89 | +0.91 |
| `RF02_CutDiagBackLeft_AS_R15_v01` | 77 | 0.76s | 0.85 | 0.89 | 0.89 | +0.89 | +0.89 |
| `RF02_CutDiagBackRight_SD_R15_v01` | 77 | 0.76s | 0.85 | 0.89 | 0.89 | +0.89 | +0.89 |
| `RF02_CutReverse_WS_R15_v01` | 83 | 0.82s | 0.85 | 0.89 | 0.89 | +0.89 | +0.89 |
| `RF02_GMode_SoleDragBack_WS_R15_v01` | 75 | 0.74s | 1.01 | 1.36 | 1.50 | +1.36 | +1.49 |
