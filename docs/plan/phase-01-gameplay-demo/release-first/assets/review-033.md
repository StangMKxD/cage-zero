# Review033 — RF-F46/RF-F48 offline fix verification
2026-10-27 · Controller Codex · baseb374102 unchanged
**SOURCE + OFFLINE MODEL VERIFIED; STUDIO RUNTIME / PARITY PENDING.** Owneraccepted360feel preserved. No new blocking sourcefinding within the2Sprintfiles reviewed thisround. This is not fullRF02/security/productionapproval.

## Current fix reviewed
- Client shared alive/currentreference/non-disabled predicate gates start and retry; heldkeys/movingintent remain separate from optimisticstate.
- Landingresume only forced from actualairborneoldstate; ordinaryLanded->Running no duplicate start while alreadyactive.
- New serverSprintRequested plus serverflag makes stop reliable even after optimisticstate cleared onnegativeack. Inputineligibility/contextloss/airborne stops clearrequest andcancelretry.
- Serverrejection now resets BOTH WalkSpeed16 andIsSprintingfalse before negativeacksequence, avoiding split effectiveproperty/state.
- Reviewed diff limitedSprintController andSprintService vsb374102. No camera/turnspeed/360policy/ball/air/jump changes; no sourceedits byController.

## Independently executed checks
1. Node .sandbox/test_rf_f46_comprehensive.js —8/8suitesPASS (RF46midairresume,serverairreject,360policy,domain/legacyvalidation,ratelimitretry,RF48landing/Shiftrelease,focusloss,negativeackcooldownstop).
2. Node .sandbox/review/rf46-stop-after-landing.js —PASS, output landedSpeed32,beforeRelease32/clienttrue/servertrue,afterShiftRelease16/clientfalse/serverfalse,passedtrue. This exactcounterexample previouslyfailedat32.
3. Rojo build default.project.json --output $TEMP/cage-zero-sprint-review006.rbxlx —PASS. Packaging, notLuaucompiler/typecheck.
4. git diff --check —PASS, existingLF/CRLFwarningsonly.
5. Testharness attributeevents nowfireonlyprev!==value. Read port vscurrentLuaufix andsourcepaths; theseare handportedJSstate-models, NOT literalLuauruntime ormultiplayer execution.

## Pinned source identity
- src/client/controllers/SprintController.luau SHA256139D29F86597E3587A558A115A25D6F92D1CEDF731D717ECF398D8E37344924E
- src/server/services/SprintService.luau SHA256F8CDD3ACF8FD7BCE8E18C878F4104BCBF31ABF63738C026314A7B3EA0B949294
HEAD remainsb374102. Fixesuncommitted; no amend/reset/newcommit/push/publish byController.

## Remaining mandatory runtime gate
list_roblox_studios independentlyreturns[]; respectOwnerclosedStudio, no reopen. LatesttwoSprintsource changes have NOT been synced/readback or testedinliveRoblox byController. Onreconnectverifycorrectplace137721422246269/mode,backupactualStudiosource,narrowsync2Sprintfiles,EXACTreadback/removeanytempseam,then initializedinputtest: Shiftmoving jump->neutral->moving->land; Landed->Runningquickly thenreleaseShift; stop/focuslossduringnegativeack; repeatedlanding/respawn. Verifyactualserver16afterstop/32wheneligible, no lingeringretry. Keepaccepted360camera/turnfeel andcapturedjumpmomentum. Unavailablelatency/4client/collision/exploit testsremainNOTRUN.
RF-F46/RF-F48 are verifiedfixed atsource/model level only; runtimeclosurepending. RF-F47report006nowuses360spec andcorrectNode-model limits. PriorRF-F24/25/42remainOPEN/outofscope; dribblePAUSED. No furtherautomaticfixhandoffthisround; readyforStudio syncwhenavailable.