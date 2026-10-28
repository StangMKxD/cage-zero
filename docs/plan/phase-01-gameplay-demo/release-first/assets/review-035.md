# Review035 — Dribble rework002 / ESCALATED technical decision
2026-10-27 · Controller Codex · **ESCALATED** (RF-F51/52 second consecutive rejection, enteringRound3)
Owner scope remains DRIBBLEONLY/DISKONLY. No appsource edits/Studio calls/sync/Play/Git byReviewer. No next automatic fixdispatch; preserve frozenwork pendingOwnerdecision.

## Verified progress
Executed .sandbox/test_rf02_review034_fixes.js independently: allprovidedJSportchecksPASS. RF-F49 firstTOI safe-sidepass/grazinglegcases improved, RF-F50 degenerateinwardtap guardedfinite with non-maskingvectors. Theseare offlineport/sourcechecks, not actualLuau/Studio or universal no-clippingproof. SprintController/SprintService exact pinnedhashes preserved. WhitespacecheckPASS. Report002 honestly statesremainingconstraints/runtimeNOTRUN.

## Remaining blocking issues
### RF-F51 — body/cage constraints still not jointly satisfied
Root x78,ballx78.5 -> finalballx78.875 obeyscage but bodycenter distance.875<Dmin2.425: penetrationdepth1.55. Calling cagewins doesNOTmeetOwner no-body-penetration acceptance.
The reportedcase isNOT globallyinfeasible undercurrent2Dmodel: independentcandidate(78.875,1.125,2.2616365756) hasbodydistance2.425,insidecage,correction2.292515<=max2.5. The originaloutwardnormal+x alone is infeasible, not allflankdirections. Needboundedfeasiblesolution/validpath; do notlabeloverlaptestPASSagainstOwnerrequirement merelybecausewallclampPASS.
### RF-F52 — timeout still grants the requested turn without contact
Code clearsqueue then sets effectiveWorldDirection=rawDir attimeout. It changesactualdirectionevenwhilephaseLeading/dist5/noContact; renamingit dropgate ratherthan queuedturn doesnotchangeoutcome.
Independentportcase: North effective,Eastqueued Leadingdist5 at t0; stillLeadingdist5 at t.85 =>effectiveEast,contactfalse. Violates waituntilrealfootcontact. Newtestassertsgatefalse, nottheactual requiredunchangedheading, soitsPASS isnotacceptance.
### RF-F53 — client/server contact height reference mismatch
MovementHeadingPreviewController uses abs(ballY-rootY)<=2.2; BallService uses abs(ballY-(rootY-PLAYER_FEET_OFFSET))<=2.2 withoffset2.8. Theseare notsamefootgate.
Numeric representativepose (notclaimedactualrigmeasurement): rootY4,ballY1.125 =>serverfeetgap.075allows,clientrootgap2.875rejects. HigherOwnerR15canthereforelegitimatelycontact onserverwhileclientwaitsthenbypassesturnvia timeout. Shared groundedfeet-relativeevidence needed; no broadeningthresholdstohidemismatch.

## Independent additional evidence
Ran .sandbox/review/dribble-rework-contact-cases.js usingthecurrentofflineport. Itconfirmsfeasiblewallflank,contactheightdisagreement andtimeoutunearnedturn outputs. Originaltestsrununchangedbeforethesechecks. No actualOwnercharacter/Studio tests andno sync.

## Concrete repair proposal for Owner decision (same scope, not new feature)
A. Replace final cageclamp-priority withboundedjointfeasibility choice: firstTOIresponse, then legalcircle/cage candidates (radialprojection ifvalid, circle-edge intersections/flanks withminimumdisplacement), checkresolvedpath/body+arena together. Useactualcagequery seam withouteditingglobalCagePhysics. Iftruly no safecontrolledforwardpath, safelystop/handoffcontrol duephysicalblockedcontact; never silentlyacceptbodypenetration orreleasepossessioneveryframetofakefrontball. The reproducedwallcase alreadyhasafeasiblenearbycandidatewithinexistingcap.
B. Onefeet-relativecontactpredicate sharedbyserver/client, includingground/phase/radius/vertical/speed rules. Preserve authoritativecontactphase; missing/stalestate mustnotfabricatecontact. Matchactualnormalizedriggeometryandreportassumptions.
C. Latestintentqueue isseparatefrompermission. Timeout maydiscardstaleintent/reportlostcontact, butmaynotauthorizea turnwhiledeclaringactivecarriercontactabsent. Ifballactuallyescapescontrol,serverreleasesitforactualcontactfailure independentofsharpturnrequest; clientthenrestoresnormalmovement. Neverforcecontinuingrunafterkeyrelease.
D. Add invariants beforecode: wallcase hasBOTHbodydistance>=2.425 ANDinsidecage, samecontactresult root4/ball1.125 onbothsides, noactualdirectionchange underleading/noContact evenaftertimeout, thenallpriorcases. Tests remainofflineandfaithful; no weakerassertionstopass.
Thisproposal changesimplementationwithinexistingdribbleallowlist only, preserves accepted360movement/Sprint/Jump andnoSYNC. Itdoesnotapproveballteleports/skills/shoot/pass/newassets. Ownerdecisionneededtoresume thirdfixround afterCircuitBreaker.

## Governance
stang-luna/SKILL.md:56: samefindingrejected2consecutiverounds ->ESCALATED,stopautomaticpingpong,requestStangdecision; mirroredR02:30. RF-F51/52 remainnotfixedsoautomaticRound3dispatchhalted. ThisisnotOwnerpausedglobalprojectstatus; sourcefrozenfortechnicaldecision only. No commit/push/publish orMotionchange.