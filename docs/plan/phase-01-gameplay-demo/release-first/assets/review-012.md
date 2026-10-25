# Gate1 Discovery — Review012

2026-10-25 · Codex · **CHANGES_REQUESTED — final retained-solver evidence and possession boundary**.
Ref HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + docs; discovery005 SHA256 `2813e5d14855dcf678c74282123c5efd0f7d029df20eafafe5fcc6eda7d5f451`.
All65 reported source/doc hashes match. Focused checker49 markdown/185 links SUCCESS. Prior verified metrics/order/types-name corrections retained. No application tests/Studio/source/Git mutation.

## RF-F11/RF-F12 — OPEN, precise remaining evidence

Manifest§3.2 claims retained2724–2775 calls ComputeReboundVelocity, EnforcePolytopeContainment and CheckGoalScored (2768–2774). Actual statements in this range are:

-2725 `CagePhysicsService.IsPositionOnElevatingRamp(ballState.position)`
-2728–2731 existing `ballState.curveImpulse` integration/decay
-2740–2742 `inFlightAction == "Pass"` selects PASS_GRAVITY_ACCELERATION_Y
-2748 `CagePhysicsService.StepBallCageCollision(prevPos,currentVel,dt)`
-2763–2765 `inFlightAction == "Pass"` selects PASS_GROUND_ROLLING_FRICTION
-2769–2774 ball-rest check and clearing inFlightAction; no goal-scoring call here

Therefore zero-inFlightAction/legacy-provider-dependency assertion is false. Correct exact helper names/locations. Trace actual helpers and constants, classify Pass-specific branches and curveImpulse as inherited gameplay versus retained baseline, and remove unsupported goal detection claim. For immediate no-gameplay cleanup proposal, distinguish normal gravity/friction solver from future shot/pass/curve behavior. Do not change values or implement anything now. If inherited tuning retained pending Owner confirmation, say so explicitly; not a clean-foundation proof.

## RF-F13 — OPEN, bounded Owner decision needed before implementation

Manifest§3.2 still promises carrier-following possession while exact kinematics are pending. A pending essential behavior is not an executable cleanup contract. Prepare two explicit Owner options at the deletion gate, without selecting/implementing them: (A) free ball only after cleanup, no possession/dribble/collection until Owner-led new gameplay; (B) retain a precisely identified existing possession subset temporarily. Recommend A for clean restart; preserve stadium physics and current rig foundation. State which minimal wiring adaptations each option needs. Do not silently build a new follow algorithm. Actual choice will be requested when presenting cleanup scope, per Owner stop instruction.

## Focused correction contract

No broad rewrite/new Argon scan. Correct retained solver statement table from exact numbered source, its actual dependency list and pending possession options only; one discovery-report006, RF02 pointers/status, refreshed hashes. Keep65-hash success separate from prose accuracy. No source/tests/Studio/Git/new gameplay/Idle. Auto push report with Enter, no monitoring. Once evidence is accurate, Codex presents bounded deletion scope and possession choice to Owner; no runtime action before confirmation.
