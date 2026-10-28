# Review034 — Dribble/front-control disk-only review
2026-10-27 · Controller Codex · **CHANGES_REQUESTED** RF-F49..52
Owner scope: DRIBBLEONLY/DISKONLY, noStudio sync/Play/writes. No appsource edits orStudio calls inthisreview. No newfeatures orcommit.

## RF-F49 — P1: sweep endpoint projection still intersects torso and moves collision-free balls
DribbleGeometryHelper:68–106 flags anyfront-to-backplane crossing as collision regardless lateralclearance; thenprojects endpoint onto chosenradius. It does not solvefirst impact/time-of-contact or guaranteecorrectedtrajectoryseparation.
Independentcounterexamples executed using existingJSgeometryport atdt.10/Vrel60 (withinreportedlimits):
- Safe sidepass x6,z-3->+3,stationarycarrier: truepathmin6>2.425, but didSeparate=true; endpoint shifted7.6117studs to(.5881,-2.3526). No collisionexists, largejump violates no-farmagnet/teleport requirement.
- Grazing sweep x-3->+3,z1: correctedendpointdistance2.425 yet correctedstraightsegment minimum2.1904479<2.425, so remains penetrating despite endpointpass.
Required: continuous first-contact/validsafeconstraint response (notclosestnormalprojection+signplane), ensure relevant correctedpathsegments stayexterior andcollision-freepaths unchanged. Keep boundedspeed/steps andsameinitialside; no longdistancemagnet disguised ascollisionresponse. Tests mustsample/assertresolvedpath, notjustendpoints.

## RF-F50 — P1: exactly-inward tap normalizes zero vector
ComputeTurnCoordinatedImpulse:158 does (blended+relUnit*inwardDot).Unit. Facing/movement both(0,0,-1), ballrelative(0,0,3) =>projectionexactzero. Unguardednormalizationcanproduce nonfinitevelocity; configspeedcapdoesnotrepairNaN. This can occurduringturn/ballbehind/overlap, preciselythetargetfeature.
OriginalJSharness masksit: Unitreturnszero atsmallmagnitude and constructor x||0 convertsNaNto0. Reviewerengine-like/non-maskingvector modelproducesfiniteDirection=false foraboveinput. NotclaimedliveLuauexecution. Add explicitdegeneracyfallback/finiteguards; updateporttoavoidNaNmasking. Assertfiniteunit/zerointent accordingcontract, no directionthroughbody.

## RF-F51 — P1: body correction overrides cage and missing height/lifecycle guards
BallService:680 runsCagePhysics, then:703–729 appliesbodyseparationwithoutrecheckingcage. IndependentgeometrycasewithactualarenaHalfWidthX80: carrierX78,already-overlapballX78.5 (insideballcenterlimit78.875), correctionreturnsX80.425outsidewall. Reconcile bothconstraints withboundedfeasibility/fallback, notlastwritewins. Do NOT changecage/gravity/globalcollisionparameters.
HelperignoresYcompletelydespite reportclaimverticalspan[-3,+2.5]. RootY3,ballY20 pathfronttorearstill gets correctedhorizontally. lastActiveCarrierCand assignedBEFORE grounded/contact/loose/steal exits; canremain afterpossessionreleased, andintegration checksrootParentonly. Therefore overhead/looseball orpreviouscarrier maybeaffected outsideauthorizedgroundcontrol. Gate actualcurrentcarrier/generation/ground/verticalsphere-overlap andrecord realpreviousvalidatedrootposition; p0=p1-vp*dt is notactualsweptpath underacceleration/turn/teleport. MAX_DT_SIMULATION.10means directhelper.15test doesNOTprove integratedBallServicedt.15 behavior.

## RF-F52 — P2: turn queue violates latestintent/contact contract; model differsfromsource
MovementHeading:296/303 consumes oldqueuedTurnDirection before updatingfromcurrentrawintent. Example: Eastqueuedwhileleading; onnextcontact userrequestsWest; effectivebecomesoldEast. Mustlatestintentwin.
:292refreshesqueuedTurnTime everysharpturnframe, soholdsharpinputneverreaches.8timeout. Conversely timeoutpath:315canreleasewithoutrealcontact whenitdoesfire. Use correctqueuebirth/update semantics andsafehandoff/no forcedrun; do not grantcontactbyelapsedtimer.
Clientcontactpredicate accepts horizontallynearball regardlessvertical/relativespeed/servereligibility; defaultphaseContact onmissingstateunsafe. ReportJSharness adds cadenceReady to distancebranch whileproductiondoesnot. Modelalso usesplayer.velocity asmoveDir whileactualserver readsHumanoid.MoveDirection thenfacingfallback. Queue/contacttestclaims not equalactualproductionbranchcoverage. Unifyauthority/permission semantics andtestcurrentproduction-equivalentflow, no hiddenrules inport.

## Independently completed checks
- Ranreported .sandbox/test_rf02_dribble_front_control.js:14/14suitesPASS. ItisahandportedJSsimulation,notLuau/runtimeproof. 180/90turntests reported separatedEvents0, sodo notexercisecollisionresponse; those passesdo notprovezero-penetrationresolution.
- Rannew .sandbox/review/dribble-geometry-counterexamples.js. Outputs: safe-pathcorrection7.6117, correctedpathmin2.19045, overheadunexpectedseparationtrue, wallafterX80.425>78.875, zeronormalizationnonfinite. Thisisindependentinvarianttests ofport/math, notStudioorrealmultiplayer.
- ReadLuauhelper/clientgate/BallServicecallordering toconfirmcounterexamples maptoactualsource. Modelactualbodyradius fixed1.25; no measuredrigbounds evidence, so labelasassumptionnotall15partbodyguarantee.
- git diff --check PASS(existingLF/CRLFwarnings). Reviewedsource scope4dribblefiles; SprintControllerSHA139D29F86597E3587A558A115A25D6F92D1CEDF731D717ECF398D8E37344924E andSprintServiceF8CDD3ACF8FD7BCE8E18C878F4104BCBF31ABF63738C026314A7B3EA0B949294 preservedexactly.
- No livevisual/runtime, noStudio source/parity claimed. NOT_SYNCED perOwner. No autonomouscommit/publish/newpane.

## Rework scope
Same4dribblefiles/config/helper+focusedofflinetests, preserveacceptedmovement/360smoothing andfrozenSprint/Jump/Air/CagePhysics. Fixrootalgorithms/currentphasequeue, notaddingfeatures orweakeninggates/testassertions. Include resolvedpath grazing, safe-clearpass unchanged, finiteinwardtap, vertical-disjoint, cage+bodyjointconstraints, realcarrierchanges andlatestqueue-oncontact cases. Preserveoldreport001, newdribble-front-control-report-002.md. AllworkDISKONLY/noSYNC/noPlay untilOwner says. No claiming universalzero-clipping from endpoints/modelboundaries.