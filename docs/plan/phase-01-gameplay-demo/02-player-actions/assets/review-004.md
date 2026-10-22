# Review 004 — fix-004 static follow-up / Owner visual rejection

- Date: 2026-10-22 Asia/Bangkok; Reviewer Codex. **Verdict: CHANGES_REQUESTED / OWNER_VISUAL_REJECTED.**
- Actual ref main HEAD `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + working tree hashes below. Local tracking reports main ahead1 of origin/main; no fetch performed, so not a statement of live remote state.
- Scope: targeted static follow-up of fix-004 claims and active pose routing; not a full review of all source/tests or Studio parity. Owner says animations still do not resemble submitted reference and requests AGY Boost, stronger visual polish, sync, commit and push.
- Read fix-004/source/bootstrap/Rojo mapping and git status/log. No application tests, Studio execution, source edits, commit or push by Codex. Runtime cache/source mismatch remains UNKNOWN until AGY checks target/source/runtime identity.

## Findings / stable IDs

### F-21 — P1 / OPEN: authored poses are not routed through all active movement paths
R6ActionPoseController:612–634 still builds only torso/neck lean with identity arms/hips, while native walk/sprint clips are still present in RigAnimationConfigs:131–143. New GetLocomotionPose/Get8WayStrafePose definitions alone do not prove A01–A05 are the poses seen by the player.
PlayerActionPoseConfigs:633 returns a fixed Slide pose, with line632 explicitly preserving constants for TC-P02-40 compatibility, rather than consuming the authored A17 entry/active/exit sequence.
GetDashPose:501 and GetChargePose still use hand-tuned formulas; any difference from authored defining poses must be explicitly mapped/measured, not hidden behind provenance labels.
**Correction:** trace A01–A18 from real input/state to evaluator to final joints; connect intended authored profiles and remove competing old tracks for joints owned by those profiles. Replace test-driven fixed visual constants with behavior/reference-aware checks without weakening gameplay assertions. Preserve rig/gameplay contracts.

### F-28 — P1 / OPEN: active airborne path still samples A06 at one fixed phase
PlayerActionPoseConfigs:667–668 GetJumpPose returns SampleAuthoredPose("A06",0.50); active R6ActionPoseController:607–610 calls this while airborne. Actual flight attributes/input latch alone do not make the pose pass through takeoff/ascent/apex/descent.
**Correction:** bind actual flight phase/state into the pose evaluator and native landing transition; do not alter vertical physics/anchorroot to produce the image.

### F-17 / F-18 / F-25..F-30 — review remains open
fix-004 claims RESOLVED/49tests/in-engine100%; these are implementer-reported. Displayed Live evidence includes rig/attribute/hold/mirror probes, which does not independently establish all eighteen animations resemble reference across their defining poses or prove current Studio runtime reads the same code as disk.
No Codex native/runtime/visual sign-off in this review. Preserve existing IDs; add action→profile→finaljoint comparison and source/cache generation evidence per HANDOFF§9.

## Source lock

| File | SHA-256 |
| --- | --- |
| `C:/Users/Stang/cage-zero/src/shared/configs/PlayerActionPoseConfigs.luau` | `e32c41d82c92ff268617762ba0a78b6c7f1a4a36605e1c164cf6794433525064` |
| `C:/Users/Stang/cage-zero/src/client/character/R6ActionPoseController.luau` | `ea8990aaa0e0bb3158acd5a5cd8398ad00cc9ba781938b7ccfe2498baf1d3cf7` |
| `C:/Users/Stang/cage-zero/src/client/character/R6AnimationController.luau` | `e739965c177ef2bc3d516853cb7a1958a363ae8202b727db542a698b0f838030` |
| `C:/Users/Stang/cage-zero/src/shared/configs/RigAnimationConfigs.luau` | `b3476df4afe12ad1fb83b3f3b33724ff4ae58ca4bf36e79b888341d5e1dbe02d` |
| `C:/Users/Stang/cage-zero/src/client/controllers/InputController.luau` | `539196aa766f0ed22fd7a47a9b50e215c29041be1948ec6455ee1dbf6d71ae30` |
| `C:/Users/Stang/cage-zero/tests/e2e/Tier1_PlayerActions.luau` | `05454e52d41ce63f9ca5ba02cd5e7da4211665030e8841b9853f99752dcc3be1` |

## Follow-up / new Git authorization
Use original HANDOFF§8 plus §9 Boost supplement. New user instruction authorizes AGY Lead scoped local commits and push for current Plan02 work; this supersedes older blanket no-commit/no-push for this task only. Use a Plan02 work branch, record WIP accurately, no force push/merge/deploy/approve/close. Preserve unrelated dirty files and old reports; next correction report fix-005.

