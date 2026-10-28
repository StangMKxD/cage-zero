# Review032 — RF-F46 working-tree fix / stop after landing rejection
2026-10-27 · Codex Controller · baseb374102 retained · **CHANGES_REQUESTED RF-F48**
Owner360feel acceptance preserved, no camera/speedpolicy redesign. Only SprintController/SprintService source changed; no source edits/Studio mutation/Git byReviewer.

## RF-F48 — P2: duplicated landing start can leave speed32 after Shift release
SprintController:237–240 force-resends on BOTH Landed and Running. Typical close transitions can send start twicewithin.05s. First grant setsserverWalkSpeed32/IsSprintingtrue. Second israte-rejected by SprintService:107–113, clearingIsSprintingfalse/incrementingrejectSeq but NOT resettingWalkSpeed32. Clientnegativeedge sets optimisticfalse. IfShift released before70msretry, syncSprintIntent:96 andreset:150 sendstopONLYifoptimistictrue, so nostoppacket is sent;retrycancels, server remains32.
Reproduced in independent extension of implementer's JSport harness, correcting mock attribute semantics to fireonlywhenvaluechanged:
- Freefall,holdShift+moving -> Landed: speed32.
- +10ms Running: speed32,clientfalse,serverIsSprintingfalse.
- releaseShift thenadvance1s: speed32 (expected16),clientfalse/serverflagfalse. Verdictfalse.
Artifact .sandbox/review/rf46-stop-after-landing.js. Ran with Node successfully; it reports failingbehavior ratherthan runtimeexitfailure. This is isolated JSport/model evidence and source-control-flow reproduction, NOT actual Luau/Studio/multiplayer proof.
Required: reconcile effective speed and sprintflag on rejection, stop must not dependsolelyon optimistictrue; avoid duplicate landingresume request/force-reset for ordinaryLanded->Running. Ensure heldintents/lastrequest/authority distinct and authoritative stop delivered evenafternegativeack. Preserveall360controls andcapturedtakeoffmomentum. Do not solve by removingratelimit, extendingtimeouts or suppressingstop/rejection tests.

## RF-F46/F47 progress and verification
- Read workingdiff: client now has shared alive/valid/non-disabled predicate for sync/retry andservernegativeedge on contextrejection. Original midairre-engagement cause is addressed in source.
- Independently ran .sandbox/test_rf_f46_comprehensive.js:5/5suitespassed (originalcase/model360/domain/retry). These are a manual JSport of Luaulogic, not exactLuauexecution.
- Existingmock char.SetAttribute calls attributechangedlisteners evenunchanged; Roblox doesnot. Correct model before claiming negativeedgecoverage. Addedreviewcase correctsthis locally without editing implementerharness/appsource.
- Report005 nowuses360spec consistently (oldreport004 retainedashistory); F47fresh-doc direction improved. Runtime gates remainNOTRUN, no fulltechnicalclosure.
- Studio list empty, not reopened. Source liveparity/sync/inputs/replication/collision testsNOTRUN. No pretendingNodePASSisStudioPASS. Rojo packaging claim exists; whitespace diffcheckpassed inreviewread.
- Workingtree codechanges limited2Sprintfiles, reports/Controllerdocsseparate. Currentcommitb374102notamended/reverted. Jump/Air/dribble remainfrozen/paused.

## Return
Sameexistingtask/pane andapproved Sprintscope. Add exactLanded->Running+ShiftreleasebeforeRetry case, focusloss/stopdirection atsameedge, originalmidairresume andratelimit cases with realistic attributeedge semantics. RequireWalkSpeed16 andIsSprintingfalse afterstop, no pendingtasklaterre-enables; 360heldsprintstill32whenallowed. Newreport006 preserves005. Backup+narrowsync/readback ONLYwhenStudioreconnectsandbeforeOwnerretest; no newGit/commit/publish/Motionstop or changingOwnerfeel.