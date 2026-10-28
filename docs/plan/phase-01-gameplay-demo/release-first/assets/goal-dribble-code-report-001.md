# RF02 G close-control / cut integration — Root code report 001
Status: DONE_BY_IMPL for G code; Owner preview/integration gate pending for animation cuts. No independent technical signoff or commit.
Owner directs Root to code and agy to author previews; approval evidence: final Q4-Q9 and ทำgด้วยเลยก็ได้ อนุญาต. Main source writer Root; animation workspace isolated/read-only main project.

## Behavior / scope
- G HOLD on ground: face center of opposing goal, normalized goal-relative WASD (W in/S out/A-D strafe), speed8. Camera aim remains independent. Release restores accepted360 movement and Shift sprint. Air ignores grounded facing and preserves liftoff yaw/lean/momentum.
- Server derives target from BallService teamSide + existing Constants goal planes; no client-supplied goal/position/possession. Mode intent validates boolean and exact current live character,20Hz start cap, unthrottled release,0.5s lease expiry, death/respawn/leave cleanup. Separate limiter persists across false requests. G Shift requests are capped/rejected with existing negative acknowledgment contract.
- Controlled G ball target2.55studs, using same custom solver and joint-safe target search; no long-range capture or physics swap. Normal lead distances now walk2.75/sprint3.1. Existing actual-ball render rebasing retained.
- Discrete diagonal-entry/opposing-direction cut detection prepared. Same held chord never repeats; W+S zero input doesn't trigger; release/press reversal grace0.25s. Latest intent resumes after real approved one-shot finishes. Safety resets cancel lock. Missing/unloaded/unapproved clips never create artificial movement freeze. ApprovedCutAnimations intentionally EMPTY until Owner accepts preview and authorizes integration. No preview assets imported/published.

## Edited/new source
- Shared DribbleActionConfigs (G balance and empty approved cut map), DribbleControlRules (pure goal/cut math).
- Client MovementHeadingPreviewController G/cut input integration, new DribbleCutController actual-track lifecycle.
- Server BallService G intent/context/expiry/close target/attack goal replication.
- SprintService minimal G guard + rate-rejection speed cap + negative acknowledgment. Existing RF46/48 behavior retained; SprintService hash changes intentionally for this approved addition, not claimed preserved. SprintController remains unchanged139D29F8...4924E.
- Existing Root dribble replication fix in DribblePresentationController/client bootstrap retained from prior step; no animation/jump/air/camera/cage physics files changed this step.

## Actual evidence
- .sandbox/test_rf02_goal_dribble.luau:52/52 actual Luau pure rule checks via disposable ModuleScripts in Edit (NOT JS port).
- .sandbox/test_rf02_goal_intent.luau:12/12 actual BallService public-function validation checks with isolated fixture/module (NOT live network singleton).
- Fresh require/compile of6 new/changed modules succeeded in Edit. Rojo packaging and git diff --check PASS; no full type/lint run (local tools unavailable).
- Actual Play, real user_keyboard_input G + W/D/S + Shift + release: client164G frames, maxWalkSpeed8, max horizontalSpeed8.000001, IsSprinting0frames, min goal-facing dot0.998799. Server165G frames, maxSpeed8.001728, maxWalkSpeed8, IsSprinting0frames. Goal-relative forward/back/right observed. ReleaseG while Shift+W restored speed32 both sides.
- Actual player remote (not module fixture): attempted sprint while G granted -> speed8, sprintfalse, negativeAcktrue. Unapproved cut function returns startedfalse/lockedfalse.
- Actual client remote lease test: true -> active8 at0.2s; without refresh -> inactive16 after additional0.65s.
- Real G+D+Space jump:52air frames, max yaw deviation0rad, landedtrue.
- Real menu opened while G+W still physically held: modefalse, MoveDirection0, near-zero velocity. Keys released/menu closed afterward.
- All new/changed source synced to Edit with exact readback. Returned Studio Edit; original preview rig still present; no Controller fixture/probe modules left. Motion bridge untouched, preview writer returned to animation pane.

## Honest limits / NOTRUN
- G runtime checked one actual player/team in local Studio; both goal-side math in unit tests, not2player live. Real latency/multiplayer/performance/respawn stress, camera orbit live and all8directions real-input not run. Pure direction tests cover8directions/four goal bases.
- A direct execute_luau require of BallService has isolated module state (workspace owner2772253354 vs required-module owner0); therefore direct-module free-ball-expiry attempt is NOT valid singleton runtime evidence and is not counted PASS. Expiry loop sits before free-ball early return; main lease tested through real remote above. Free-ball-only real-singleton lease remains NOTRUN.
- Old live body-box overlap/cage edge issues are not blanket closed. Before G step, latest root render fix removed behind frames in99-frame sample but2body-box overlaps remained; server snapshot samples can be closer than configured ring during network-root updates. G sample client minfront2.425, server2.3105; no claim of complete collision proof.
- Walk/run/cut/G animation clips9 are preview-only in animation workspace ANIMATION-REPORT.md. Their visual acceptance and actual gameplay track/contact coupling pending Owner. Movement will not stop for those cuts before accepted assets are connected.
- No Git commit/push/publish. No shooting/pass/combat/Super additions.
