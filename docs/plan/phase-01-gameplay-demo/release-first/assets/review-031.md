# Review031 — b374102 technical review after Owner feel acceptance
2026-10-27 · Controller Codex · commit b374102971c6d6d08ce189c7f7daf74b4391a837 (parent9db6122)
**OWNER_VISUAL_ACCEPTED for current360locomotion; TECHNICAL CHANGES_REQUESTED (RF-F46).** No rollback/amend/new source commit performed.

## Authority and exact current spec
Read live implementer pane history: Owner answered Q1–Q4 with Custom Camera-Relative360 (walk/run faceWASD travel), Q2 shortestturn/speeddip, Q3sprint32anymovingdirection, Q4reticleactionaim independent; Owner then said ได้ประมาณนี้แหละ, commitไว้เลย, and passedfeel for technicalreview. These newer explicitOwnerdecisions supersede earlier rootgrill hybrid/forward-only rules. Commit authority and Ownerfeel are confirmed, not inferred from implementerlabel.
Current target: allmovingdirections faceactualtravel with20rad/s shortestarcs andconfiguredsharpturnspeeddip, Shift+moving sprint32in360, idlekeepsheading, airyawlock unchanged. Do not restoreoldside/back16policy as a bugfix.
Commit is a broad54file checkpoint (~71464insertions), including prior unreviewed dribble/jump/assets. Workingtree was clean at reviewstart. A successful camerareview does not approve pauseddribble or close RF-F24/25/42/legacy00/01/wholeRF02.

## RF-F46 — P2: midair intent transition strands sprint after landing
SprintController.syncSprintIntent (around75–114) derives eligibility ONLY Shiftheld+isMovingIntent; no currentground/air gate before setting optimistic isSprinting=true and firing. checkRetrySprint rejects airborne scheduling, and SprintService.setSprintState rejects airborne grants without SprintRejectedSeq (sequence only increments on rate-limit rejection).
Reachable normal input path for current360spec:
1. Shift+W sprint32; jump transitions client false/serverfalse16 while retainingheldShift.
2. Inair W+S cancelsmovement -> SetMovementIntent(false).
3. Stillinair addA orreleaseW so resolvedmovementnonzero -> SetMovementIntent(true) sets optimistictrue/sendsstart. Choose timing beyond.05ratewindow: serverrejects Freefallcontext, no rejectionseq, attribute alreadyfalse, clientcheckRetrySprint returns withouttimer becauseairborne.
4. Landed handler calls syncSprintIntent; cachedoptimistictrue causes earlyreturn. Movement intent remainsnonzero so no later SetMovementIntent call resends. Server stays16 despite Shiftheld+moving, clientthinkssprinttrue.
This is confirmed source/control-flow finding; NOT claimed observed live in thisreview becauseStudio disconnected. Regression harness uses EXACT extracted currentclient/serverfunctions and isolatedclock/signal/character mocks, saved .sandbox/review/b374102-sprint-air-resume-repro.luau. Harness NOTRUN (noStudio/localLuauinterpreter). Run it whenavailable, then prove real input landing behavior.
Required: all sprintrequest/retry paths use one current eligiblelocomotion predicate, maintainheldinput independently; reject/defer airstarts without optimistictrue persisting; landing explicitly reconciles authoritative state and resumes eligibleheldintent. No broadspeed/turn/camera/jump retune. Add no-change attribute context rejection test plus midair moving->neutral->moving,landing,lateack,cancel/death checks. Preserve capturedtakeoff momentum.

## RF-F47 — P2: report004 evidence does not match committed360code
Report004 Suite1.6 claims {isShiftHeld=true,forward=-1} gives16, but currentSprintService compatibilityroute treats forward~=0 as moving, granting32 (correctfornew360policy). Suite4 claims hybrid/idle-face-reticle preserved, while committed movement intentionally facestravelallkeys and idleholdsheading. Oldassetgap prose says Runonlyforward, no longer current. Therefore those oldtests cannot substantiate currentcommit; retain historicalresults as historical, produce fresh current-spec tests/hashes. Report004'slength/checksum and finalnarrative alone do not fix staleassertions.

## Technical checks completed / limits
- Pinned parent/commit, inspected current5camera/sprint source files, bootstrap dependencies, related air/jump/pausedball seams and priorreports/findings. No native code changes byController.
- LiveHerdr ownerQ1–Q4/commit/feel acceptance verified via specificcurrentprojectpane. No otherpanes/tabs changed, no newagent.
- rojo build default.project.json --output $TEMP/cage-zero-b374102-review.rbxlx PASS. Packaging only, not Luautyping. Workingtree clean beforethisreviewdocs.
- Studio get_studio_state returns no connectedinstances. Current sourceparity/testseam/actualinput/sprintlanding/latency/performance NOTindependentlyverified; don't reopenStudio or claimruntimePASS.
- Existing reportparity5files is implementerclaim. Prior independent parity/report003 applies olderrevision, not thiscommit.
- RF-F44 legacytrue rejected and forward-domain compatibility sourceguards nowpresent. RF-F45 rejectionseq/groundedretry added, fixes originalratelimit-onlynoedgepath in source; fullclosure needs currentpredicate/landing tests (RF-F46). No allegation of arbitraryspeed acceptance from isMovingintent: it remains clientintent, serverchoosesboundedconfigspeed.
- Existing serverRF-F42catchup gap remainsOPEN and contained, no security/publishapproval. Broadcheckpointcontains BallService/DribbleConfigs from pausedwork, not a delivereddribblesystem.

## Minimal return scope
Sameexistingcameratask/pane; fixonlySprintController/SprintService ifnecessary plus focusedregression andreport005, no gameplay policychange, no reset/amend/commit/push/publish. Preserveb374102 as authorizedcheckpoint andallOwneraccepted360feel. Controller syncs currenttarget docs/checklist; no ball/jump/source expansion. IfStudiostilloffline, preparefix/harness andreport exactunruntests, not fakeALLPASS.