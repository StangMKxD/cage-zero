# Review 007 — fix-009 completion / targeted airborne aim regression

- Date: 2026-10-23 Asia/Bangkok; Reviewer Codex / stang-luna.
- **Verdict: CHANGES_REQUESTED / F-35 OPEN.** Targeted review of reported airshot direction only, not full sign-off of jump/BallPop or all older findings.
- Actual ref: `5c33d5f060a9f613d6841767637bf917f9a69614` on codex/plan02-animation-rework; parent `a7178da844d2aa56cefe4c38d665f2af5f9e7391`; unrelated dirty docs/CagePhysicsService preserved.
- Monitoring: fresh herdr tab/agent discovery resolved agycagezero=w2:p3X, idle with fix009 report and commit5c33d5f. This confirms completion submission, not test-result acceptance.
- Owner reports S/backtilt shot still travels identically in one direction despite aiming elsewhere; scope narrowed to aim transport, retain working jump/BallPop/ballphysics.
- Static inspection of actualsource/callers and fix009; no app tests, source edits, sync, restart, input injection, commit or push by Codex in this review. Studio read-only discovery found Cage-Zero Place137721422246269 currentlyEdit; old Client session not available for fresh replay.

## F-35 — P1 / OPEN: Client discards camera yaw before sending airborne shot intent

**Coordinates:** src/client/controllers/InputController.luau:120–134 and RequestKick:204,241; BallService:816–823; AirLeanSolver:99 onward.
getAimDirection reads camera LookVector but when isAirborneLocked=true reconstructs a vector from jumpCommitDir.X/Z and cameraLook.Y only (128–132). Mouse/camera yaw is discarded and every airborne shot keeps the committed horizontal direction.
RequestKick sends this already-locked vector as aimDirection. BallService and the new aim-relative solver correctly accept that vector; testing the solver with supplied aim vectors alone cannot detect this upstream loss.
This directly violates HANDOFF§14/15/16: characterfacing/momentum staylocked, while ballaim must follow currentreticle3D with onlysmalltiltdeflection. It explains why S/backtilt and different aimed azimuths can still fire along one identical horizontal line. Exact current-runtime reproduction remains AGY's required gate; static control-flow cause is confirmed.

**Correction:** Remove the airborne aim-vector reconstruction from the shared client aim-acquisition path. Keep full validatedcamera/reticle3D direction for bothground andair, preserving existing no-camera fallback. Do not remove character rotation/momentum locks or rework solver/gravity/power to compensate for incorrect input.
Audit all production callers/prediction/release/reconciliation so a later branch does not reinstate jumpCommitDir/F0/HRPLook as shotbase.
Owner calling S/backtilt a bicycle-like shot does not authorize restoring BicycleKick/Header input mapping. Retain latest LMBDirect/RMBairVolley unless separately clarified.

## Required independent seam verification

- Samebodylockedfacing, fixedleanS and sameballfixture/charge, cameraaimyaw0/+60/-60/180 then realLMB/RMBpress+release: capture camera/reticleaim → actualpayload → serverreceived/resolvedaim → actualballlaunchvector. The launch must follow changedaim with existingprofilebias and<=5deg EXTRAlean cone.
- KeepbodyYaw/XZmomentumlocked whilecameraaimchanges. Do not hardcode cameraaim=facing in testfixtures.
- Test S/backtilt and neutral/A/D/W, nearverticalaimbasis, UI/defaultboot+singlebindings, BallPop→releaseSpace→jump→airshot. Assert actualclientinputpipeline, not directExecuteKick/suppliedaim solver-only tests.
- Fix009 Live evidence reports methodresult ok/flight flags, but has no above camera-yaw transport trace. 116/116 is AGY-reported, not Codex approval.
- Sourceparity→freshPlay/require-cache generation required; no screenshots/video mandate. VisualINCOMPLETE if not observed.

## Source lock / follow-up

Input SHA256 `45a9b97f16a7d78306c1c103fbf82f4d92444068c57de3e91a6d503320af1028`.
BallService SHA256 `32222b587e74b59cc1479e715a24d69ceeb8115ff1604ef75a88cb94d3cb0d72`.
AirLeanSolver SHA256 `ef01c7069d2ea60efbcbebf728a11e5149d56a08e0762977f8d5b2411e237ce5`.
Use original HANDOFF02§17, normalfocusedfix. Nextreportfix010; preservefix009. Plan02OPEN,03waiting,04PAUSED. Oldfindings not closed by this targeted review.

