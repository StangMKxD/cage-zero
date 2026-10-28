# RF02-DRIBBLE-RECEIVE — Report 003 (Owner AUTHORITATIVE CHANGE: continuous front control, no touch-phase gate)

Status: **READY_FOR_REVIEW_DISK_ONLY** · **NOT_SYNCED** (Studio untouched this round; previous one-shot sync holds OLD code) · live Luau / visual **NOTRUN** · no Git. Reports 001/002 preserved. Backup: `.sandbox/rollback/rf02-dribble-front-control-pre-report003/`.

## Scope (allowlist only; no extra files)
BallService, DribbleConfigs, DribbleGeometryHelper, MovementHeadingPreviewController. SprintController/SprintService hashes unchanged (139D29F8…4924E / F8CDD3AC…949294). Jump/Air/cage physics/camera untouched.

## Behavior
- **Front control (server, valid current grounded carrier only):** each step the ball is pulled toward a feasible target FRONT_DISTANCE (walk 2.9 / sprint 3.3) ahead of the ACTUAL body heading (RootPart LookVector), `v = carrierVel + clamp(gain*err, 30)`, capped 48. Ball genuinely travels with the carrier (no weld/teleport/duplicate). Replaces timed taps; `DribbleConfigs` touch/lead/gate keys removed.
- **No touch-phase / queue / timeout:** `updateDribbleTurnGate`, queued turn, contact phase and timer deleted from the heading controller; heading follows the latest intent immediately via the accepted 360° shortest-arc smoothing. `IsTurnGated()` kept for API, returns false. No automatic possession loss on turn.
- **Dribbling turn slow-down (carrier only):** `DRIBBLE_TURN_*` configs: factor 1 at ≤25°, → 0.60 walk / 0.45 sprint at 180°, exponent 1.3; drops immediately, recovers at 3.0/s. Non-carrier keeps accepted camera-config dip.
- **Joint body+cage (RF-F51):** `ResolveBodyCage`: vertical gate on shared feet origin (feet = RootY − PLAYER_FEET_OFFSET, span 5.5) → exact first TOI vs body circle → cage-box check; if cage clamp leaves the ball inside the body, picks the nearest FEASIBLE ring point (72 candidates). Front target also slides to feasible flank when the front is outside the cage and returns to front when the carrier turns away. Blocked (flank >60°) slows carrier ×0.5; no feasible target ×0.2 via `DribbleSpeedFactor` attribute.
- **Rolling:** ball CFrame spin = actual horizontal travel / radius (zero travel ⇒ zero spin, so stops at rest). Idle: ball brakes at IDLE_BRAKE_RATE=10/s (needed — a 3.5/s cushion let a sprint stop overrun LOOSE_BALL_DISTANCE; found by test).
- **Retained:** receive/steal/loose-ball eligibility, contest debouncing, free-ball solver, shared feet origin (RF-F53 client contact predicate no longer exists).

## Evidence — `.sandbox/test_rf02_front_control_report003.js`: ALL PASS (JS port, NOT live Luau, non-masking vectors)
1. Sustained control: walk 10 s ball 3.03–3.14 ahead, sprint 6 s 3.18–3.77, behind=0, clearance ≥ 2.425.
2. Immediate turns (90/135/180 sprint, 180 walk): yaw responds SAME frame; factor 1→0.82/0.65/0.45/0.60→1.0; owned; min clearance ≥ 2.425.
3. Sprint→stop (zero spin at rest), 720° direction sweep, 40 reversals: owned, clearance held.
4. Rolling: spin == travel/radius.
5. Review035 case carrier x78/ball x78.5 → (78.829, 2.279): in cage (≤78.875) AND body dist 2.425 (old residual 0.875 fixed); run into wall then turn away: min clearance 2.425, ball back at front (0.24 off); corner sprint in/out; carrier outside cage flagged infeasible.
6. dt 0.05 / 0.10 sustained and mixed spikes with reversals: clearance held.
7. Initial overlap 0.5 → 2.558 bounded; vertical-disjoint untouched.
8. Ball >7.5 releases control; non-carrier ball untouched.
9. 5000-case fuzz finite (incl. zero facing).
`rojo build` OK; stale-key grep 0; Sprint hashes preserved. Old suites 001/002 harnesses are historical (obsolete model).

## Tuning (all `DribbleConfigs`)
FRONT_DISTANCE_WALK/SPRINT 2.9/3.3, FRONT_GAIN 14, FRONT_MAX_REL_SPEED 30, DRIBBLE_TURN_DIP_THRESHOLD_DEG 25, MIN_FACTOR walk/sprint 0.60/0.45, EXPONENT 1.3, RECOVERY_RATE 3.0, BLOCKED_FLANK_ANGLE_DEG 60, BLOCKED/INFEASIBLE factor 0.5/0.2, IDLE_BRAKE_RATE 10, FLANK_ANGLE_STEPS 72.

## Limits / unverified
- No luau-analyze available: Luau type/syntax checked only by `rojo build` + review, never executed.
- Sprint dribble ball stays ~3.2–3.8 studs ahead (more than walk); stays > body radius by design, may look far; tune FRONT_DISTANCE_SPRINT if needed in playtest.
- Real Humanoid acceleration/deceleration, replication latency and server-vs-client heading timing are not modelled (sim stops/starts instantly); carrier-speed attribute reaches client with replication delay.
- Carrier cylinder radius 1.25 / height 5.5 are assumptions, not measured per-part bounds; other players' bodies and obstacles are not part of clearance.
- Resolve `infeasible` flag is a safety net (ring always feasible when clamp overlaps body); only the front-target infeasible path (carrier outside box) is exercised.
- Sprint stop leaves ball coasting up to ~3 studs ahead before resting (brake 10/s); player may need to step to it.
- NOT synced: Studio still has the previous code until Owner requests sync.

## Hashes (sha256 prefix)
BallService af7ab24b…, DribbleConfigs eeba748d…, Helper ac70e521…, MovementHeading 042f7d1e…, test 21a0d0c5…
