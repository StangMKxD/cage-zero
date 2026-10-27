# Review029 — Camera-relative/grounded reticle facing
2026-10-27 · Codex Controller · **CHANGES_REQUESTED** (RF-F43); Owner currentcamera acceptance pending.
Task RF02-CAMERA-RELATIVE; compare2allowed source files against .sandbox/rollback/rf02-camera-relative-pre. Existing jump/server/ball work not reapproved. No code edits/Play/input/scene writes by this review.

## RF-F43 — Medium: grounded facing can run during actual airborne/unsupported state
MovementHeadingPreviewController.checkIsAirborne returns AirMovementController.IsAirborne() immediately when module exists; false prevents consulting actual HumanoidState. onMovementStep uses else as grounded without checking FloorMaterial or supported ground states. updateGroundedFacing can therefore rewrite character yaw while native state is Jumping/Freefall but AirMovement false (initialization/replication/transition mismatch), violating explicit grounded-only/airlock guard. It also treats Seated/Climbing/Swimming/Physics as grounded when AirMovement resets, imposing upright yaw where it does not own orientation.
Independent deterministic check executed EXACT helper extracted from currentdisk with dependency stub AirMovement=false + HumanoidState=Freefall: controllerSaysAirborne=false, wouldEnterGroundFacing=true. No full live transition repro claimed, but wrong branch is proven.
Required: actual Jumping/Freefall OR aircontrollertrue prevents grounded writes; ground facing/movement only with alive/current character+root and explicit eligible ground/floor condition; unsupported state hands off without forcing camera yaw. Preserve landing-edge jump buffer and current movementmath. Add disagreement-state/unsupported-state tests and live takeoff/landing regression, no changes to JumpService/AirMovement files. Avoid clearing legitimate bufferedjump on every transient flag mismatch.

## Verified current scope
- DiskSHA CameraPreviewConfigs0aa9169250b98966110b5e4b9aba1848062b4cfd3c97f0be36c011758be3312e; MovementHeading87813b9788841fc9938c9c5f51dbff9333bcc814ee86acd63b45196351db8ef4 match report.
- Independent Studio Editread exact source equality both files (2166/13195bytes), noDIAG_SEAM_BEGIN; place137721422246269. No testseam left in these sources.
- Executed EXACT extracted computeLocalInputVector/computeWorldDirection with controlled keybooleans in Studio Edit:8/8 W0,W90,WA45countersteer,A90countersteer,S0,WSzero,ADzero,WDunit passed. This is mathunit evidence, NOT live actualkeypress or wholemovement E2E.
- Source recomputes camera yaw eachstep evenheldsamechord; new groundedfacing usesdeadband andpreserves linearvelocity; diagonal normalization/opposedkeys correct. Existing input+5/jumpbuffer/sprint/Alt not intentionally changed.
- Full reportSuite1..5 live results are IMPLEMENTER evidence; Controller did not independently rerun live flows. No exact reproducible harness included with report. Suite5 covers2Cleanup/Init cycles, not delayedyield/rapidrespawn cancellation. Prior RF-F25asyncsetup/suspendNativeControls risks remain open as preexisting; don't claim fullyclosed lifecycle.
- git diff --check targeted PASS (LF/CRLFwarnings only). Build report saysPASS, not independently rerun byController in this review.
- RF-F42 servercatchup gap remainsOPEN/out ofcamera source scope. Networkreplication/complexslopes/unusualkeylayouts NOTRUN perreport. No current Owner visualacceptance.

## Return
Fix RF-F43 in samepane/task exactallowlist, preserve existingvectorbehavior and acceptedjumpfeel. Backup/narrowsync/EXACTreadback and testseamcleanup beforeOwner retest. Reportupdated camera-relative-report-002.md preserving001. No sourceGit/publish or dribbleresume. Existing camera arenaocclusion RF-F24/preexisting lifecycleRF-F25 not silentlyclosed.