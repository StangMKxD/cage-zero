# RF02-DRIBBLE-RECEIVE — Report 002 (review034 RF-F49..52 rework)

Status: **READY_FOR_REVIEW_DISK_ONLY** · Studio **NOT_SYNCED / NOT CALLED** · live Luau/visual **NOTRUN** · no Git ops. report-001 preserved unchanged.
Scope: BallService, DribbleConfigs, DribbleGeometryHelper, phase-only MovementHeadingPreviewController. Sprint/Jump/Air/CagePhysics untouched.

## Fixes
- **RF-F49** [DribbleGeometryHelper](file:///C:/Users/Stang/cage-zero/src/shared/DribbleGeometryHelper.luau): removed sign-plane crossing and closest-normal endpoint projection. Now exact first time-of-impact (quadratic, relative circle vs radius 2.425) → contact point, restitution response on the contact normal, remaining-dt continuation (floored to ≥Dmin). Collision-free sweeps return unchanged. Already-overlap (c≤0) keeps bounded push (cap 2.5 studs/step, ≥8 studs/s outward).
- **RF-F50** exactly-inward tap: zero-projection falls back to horizontal tangent (then facing); degenerate sum guarded; NaN fallback. JS port now uses non-masking vectors (Unit of zero → NaN, no `||0`).
- **RF-F51** BallService: vertical span overlap gate in helper; ball Y vs root span [-3,+2.5]±ball radius. Joint cage clamp after body response (ball center ≤ 80−1.125 / 120−1.125) without editing CagePhysics; velocity into wall zeroed. `lastActiveCarrierCand` now cleared on invalid-carrier and loose-ball exits; reset each step. p0 = actual previous recorded root position per user (`carrierPrevRootPos`), not p1−v·dt. Server contact window now also requires vertical gap.
- **RF-F52** client queue: contact = phase `Contact` AND horizontal ≤ SPRINT_CONTACT_MAX_DIST AND vertical ≤ MAX_RECEIVE_VERTICAL_GAP (missing phase defaults `Free`, not Contact). At contact the **latest raw intent** wins (stale queue discarded). Queue timestamp set only on queue birth / direction change (not every frame). Timeout drops the gate and follows current raw intent; it does not grant a queued turn nor fake contact.

## Evidence (offline JS port, NOT live Luau) — `.sandbox/test_rf02_review034_fixes.js`: ALL PASS
- RF49a safe side pass x6: unchanged (did=false, pos/vel identical).
- RF49b grazing x-3→3,z1: corrected path legs (b0→TOI contact, contact→end) min = 2.4250 ≥ 2.425; correction < 6 studs.
- RF49c head-on: ends on origin side, ≥Dmin, bounded.
- RF50: finite unit, not directed through body; fully degenerate vectors finite.
- RF51: wall case carrier x78/ball x78.5 → ball x = 78.875 (cage limit held). **Residual body distance 0.875 < 2.425: cage and body constraints are infeasible there; cage wins, overlap with body is NOT resolved.** Vertical-disjoint (ball y20) untouched.
- Randomized 2000 moving-carrier sweeps: finite; endpoint exterior (endpoint-only metric; path legs covered by RF49b/c).
- RF52: East queued then West at contact → West; timestamp not refreshed under held input, timeout drops gate; vertical gap / Free phase not contact.
- Legacy `.sandbox/test_rf02_dribble_front_control.js` still exit 0 (its queue/contact port is the older model — not production-equivalent evidence for RF52; superseded by the new test).
- `rojo build` OK.

## Limits / assumptions (no universal zero-clipping claim)
- Carrier modeled as radius 1.25 cylinder (assumption, no measured rig bounds); ball radius 1.125.
- Integrated BallService dt capped at MAX_DT_SIMULATION 0.10; helper-direct dt 0.15 does not prove integrated dt 0.15.
- Ball path is treated as a straight segment per step; carrier relative path linear. Rotation of body (non-circular) not modelled.
- Near cage walls body/cage may be infeasible (above); no multi-carrier/other-player bodies.
- Client queue contact mirrors production predicate but client reads ball Part position, server phase attribute may lag one replication tick.

## Hashes (SHA256)
SprintController 139D29F8…4924E, SprintService F8CDD3AC…949294 — unchanged.
BallService 15DAD37D…5F7A · Helper 7F60436C…9FBA · MovementHeading B77F9F09…E7DA · DribbleConfigs 216A5A7D…B33A
