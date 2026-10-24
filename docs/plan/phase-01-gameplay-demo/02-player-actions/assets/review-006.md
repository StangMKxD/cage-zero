# Review 006 — fix-007 regression: missing HUD and unusable shoot input

- Date: 2026-10-23 Asia/Bangkok; Reviewer Codex / stang-luna.
- **Verdict: CHANGES_REQUESTED — client startup blocker.** Plan02 remains OPEN. No approval/closure of older findings.
- Actual ref: `b579530d9ad7f4ded3cfa2af754698d97e44578f` on codex/plan02-animation-rework + unrelated dirty docs/CagePhysicsService; application files inspected match current committed disk baseline. Do not attribute unrelated dirty changes to this regression.
- Target discovered fresh: Cage-Zero Place137721422246269, Studio `b3c0bfce-4cdb-41f8-93e5-0de561cd407f`, Play / Client.
- Method: read console, inspect runtime ModuleScript source lines315–355, actual PlayerGui and bootstrap line65; read disk source/test helpers. No application source edits, no require/re-init of failing module, no test suite run, restart, sync, commit or push by Codex.

## F-31 — P0 / OPEN: duplicate charge tail makes InputController fail parsing

**Disk/runtime coordinates:** InputController.luau:342–347; client init:65–72.
RequestStartCharge already ends at344 after the correct SetCharging(true,visualChargeAct,...). Lines345–347 repeat setLocalWalkSpeed/SetCharging using chargeAction/chargeCurveStyle/chargeFoot outside the function plus an unmatchedend.
Actual console: `Players.StangMKxD.PlayerScripts.Client.controllers.InputController:347: Expected <eof>, got 'end'`; then `Requested module experienced an error while loading`, bootstrapClient:65.
Client bootstrap requires InputController at65 before initializing TrainingHUD below it. Runtime PlayerGui contains only Freecam, no Module02_TrainingHUD. This establishes the startup interruption and explains both missing HUD and unbound input; it does not prove all later gameplay would pass after syntax repair.
**Fix:** remove the entire stale duplicate block345–347 while retaining the correct visualChargeAct block342–344. Removing only the extraend leaves top-level invalid calls/undefinedlocals and is insufficient. Verify surrounding scopes/localarguments. Do not skip Input.Init, swallow the require error, or create a fakeHUD to hide startup failure.

## F-32 — P1 / OPEN: AirLean fixture assigns undefined RUN_SPEED

**Coordinate:** tests/e2e/Tier1_AirLeanPhysics.luau:91.
`hum.WalkSpeed = Constants.RUN_SPEED` references a constant not present in current Constants. Console includes `value of type nil cannot be converted to a number` from createMockAirPlayer:91 in multiple cases.
**Fix:** use the real approved movement constant appropriate to the fixture (WALK_SPEED for ordinary walking fixture), and verify fixture creation/teardown. Do not add a fabricated RUN_SPEED alias or weaken assertions to mask errors.

## F-17 / F-18 remain OPEN — evidence did not cover Client bootstrap

Console also contains a printed PLAYER ACTIONS PASSED/64 summary and earlier repeated test/helper errors. The cumulative console lacks a reliable fresh-run boundary for all these messages; do not claim the summary proves those errors were fixed or the current Client starts.
fix007 math/Edit tests are not a substitute for a fresh default-client boot, HUD presence, input binding and real input→server→ball validation. AGY must rerun with exact source/cache parity and separate current-run errors from historical console noise.
Unrelated animation asset warnings and legacy runner wait are recorded but not diagnosed as the cause of the confirmed syntax blocker; investigate only if they continue blocking after focused repair.

## Evidence / lock

- Runtime InputController bytes44374, Adler32 944017144; this is a non-cryptographic diagnostic fingerprint, not SHA parity.
- Runtime source315–355 and disk source311–354 show the same duplicated tail. bootstrap runtime line65=`local InputController = require(InputCtrlModule)`.
- PlayerGui observation: only ScreenGui Freecam (Enabled=true), no Module02_TrainingHUD.
- Disk InputController SHA256 `ca3dfc3399324433228a0eeaf280a0402a14151262bd09026f997e9aa85366d5`.
- Disk clientinit SHA256 `4731c0449a26ad48f1ae3385c3103643f61d64653c0f2b50799539bbc0c86c93`.
- Disk TestRunner SHA256 `bed64c0721161a176fcfc5135993198ac0e0c23a3846c4d7a8eccd8f009eee36`.

## Corrective assignment

Use existing HANDOFF02§13, normal focused prompt. Repair F31/F32 and prove fresh native Client boot+Module02_TrainingHUD+actualnewbindings. Preserve §12 input/lean/side/action contracts and fix006 movingjump/off-ball fixes. Next report assets/fix-008.md; keep fix007 unchanged.
No feature expansion, no Plan03 integration or GK during this startup repair. Existing scoped Git authorization applies to AGY Lead only; no force/merge/deploy/approve/close.

