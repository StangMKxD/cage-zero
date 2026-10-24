# Review 008 — fix-014 / Plan03 fix-003, Owner runtime rejection

**Verdict: CHANGES_REQUESTED / OWNER_RUNTIME_AND_VISUAL_REJECTED.** Codex, 2026-10-24. Plan02/03 remain OPEN; no approval/closure/Git action. Focused blocking review; broader 7-skill/curve/recipe sign-off is deferred until corrected current-ref evidence, not implicitly passed.

## Ref, attribution and evidence limits

- Actual HEAD `c7542258b93b613e0260e43035761cbce87928cd`, branch `codex/plan02-animation-rework`, dirty Working Tree incl prior protected work. Do not attribute all diff to this submission.
- Inspected current files and hashes (independently computed Get-FileHash, not transcribed from formatted tables):
  - BallService: `2985e93b2e0449cffe30cc69dfd13032d147d194da19f8e3860e193fd4cd80b7`
  - InputController: `8eacf3f36ad6f830a2f0e0689ae84524513d89ac0cc17cbee9dda4c9b4cb4239`
  - PlayerActionPoseConfigs: `18c19b642de01de6fb56cff59ed72a3e2f9d3f6d8ba36abac4d38d4935d5d600`
  - Tier1_PlayerActions: `692a7e64924a6c55faca0c850287ed330de991e2df052949416087acd71eeec4`
- AGY reports116/116 Edit-mode tests,877 assertions. Codex did NOT execute application tests; inspected code/test assertions/reports. Owner reports actual FakeShot ball remains stationary and Idle/Walk/Run/Jump still look stock. These are current runtime/visual rejections, not superseded by Edit results.
- Motion exact-CageZero heartbeat previously independently confirmed online; that does not establish playable animation/ball behavior. Visual/playback/live-input verification remains incomplete; no screenshot/video requirement.

## Findings / stable IDs

### F-36 [HIGH] Core FakeShot still fails Owner's live ball-cut acceptance

**CONFIRMED symptom:** Owner: “บอลมันยังอยู่กับที่อยู่เลยตอน fakeshot”. Existing TC-P02-61 (`tests/e2e/Tier1_PlayerActions.luau:1987`) creates mock players, directly calls HandleActionRequest, then immediately checks internal GetBallState().position. It does not drive actual client E input, replicated/world ball or multiple Heartbeat/dribble frames. BallService ExecuteFakeShot:2040 changes internal position/velocity; possession follow around2410 applies a temporary side offset. This is not proof of the visible real-client result. Root cause remains UNKNOWN until reproduced: stale runtime source/cache, rejected/missing client intent/aim, possession-follow overwrite, replication/visible ball mismatch and too-short movement are hypotheses, not conclusions.

Required: reproduce in the ACTUAL Cage-Zero Play client/server with a held Direct/Curve charge and E; record accepted/rejected intent, validated aim/side, ownership, internal ball + actual visible ball positions over time through contact/recovery. Trace current source/cache/parity and all ball position writers. Fix demonstrated cause without teleport/anchor/weld/I-frame/ownership capture or changing ball physics globally. Validate left/right aim, opposite movement, rotated yaw/near-neutral policy, subsequent dribble frames, stale releases/replay/recovery/invalid ownership/air/range and matching R6 foot/body pose. Preserve old safeguards; no increasing test counts as substitute for visible ball touch.

### F-37 [HIGH] Submitted fingerprints do not bind the test claim to actual files

Independent comparison of11 source/test hash table rows across fix014/fix003 found **10 mismatches**, one match (unchanged SkillMoveService). Most mismatches share57 leading hex characters then differ. Example BallService report ends `...0E193FD705A921`, actual ends `...0e193fd4cd80b7`. This is an evidence mismatch; no assumption about intent or unobserved cause. Current116/116 claim cannot serve as current-ref sign-off from these fingerprints alone.

Required: regenerate hashes programmatically as complete strings/JSON, never reconstruct tails from truncated Format-Table output. Preserve historical reports as historical; add corrected source/evidence mapping in next fix report, including ALL synced source/test files (not merely11/11 claim), actual Studio instance/DataModel/cache state and executed runner/result. Rerun necessary verification on the exact final source and compare hashes again before reporting READY_FOR_REVIEW. No tests run by Codex, no retroactive fabricated evidence or overwriting original findings.

### F-38 [HIGH] Base locomotion remains native R6, not the prepared custom set

**CONFIRMED static path + Owner visual rejection:** Owner says idle/walk/run/jump look normal. `R6AnimationController.luau:370` loads tracks from RigAnimationConfigs; `RigAnimationConfigs.luau:31` onward labels profiles Roblox Native Standard R6: idle180435571, walk/run180426354, jump125750702. Manifest contains P02_Idle_Ready/P02_Walk_Cycle/P02_Sprint_Cycle/P02_Jump_Fall_Directional recipes, but schema/library presence does not wire those into live locomotion. Stock Animate conflicts, track priorities, action overlay and runtime cache must also be checked, not assumed the only cause.

Owner's latest feedback authorizes a narrow base-animation wiring correction (HANDOFF02§24). Connect the prepared custom idle/walk/run/sprint/jump/fall/landing as applicable to the ACTUAL player lifecycle, preserve single custom R6, generation cleanup and action priority. Do not alter rig/stats/jump/ball physics or use personal animation packs/fabricated asset IDs. Reuse source/recipe conventions or explicitly author missing editable drafts; no upload/publish required/authorized. Default fallback must be explicit NOT CUSTOM-VERIFIED, not counted as the requested set. Verify actual player states visually and through active track/pose/source mapping, including transition to/from charge/action, respawn/reset and no competing Animate/duplicate tracks.

## Correction contract and next review

Same approved HANDOFF; agycage is sole implementer. Fix F36 first, then F38, repair F37 evidence with final exact-ref checks. Use scoped source/test and narrow new animation-wiring allowlist from§24; preserve all dirty work and historical reports. Deliver ONE new Plan02 `assets/fix-015.md` addressing F36–38, with crosslink from Plan03 if needed, not duplicate reports. Report actual partial/NOT RUN/BLOCKED outcomes; no self-pass/close/Git/publication. Send one push report to Codex w2:p43 under§O when ready or blocked. Codex will not resume polling.

This is first review rejection of F36–38; stable IDs must remain unchanged. Other prior findings/00/01/04/Phase2 gates are not closed by this review. Full six-dimension acceptance is not issued: scope/contract/runtime/evidence blockers above prevent sign-off.
