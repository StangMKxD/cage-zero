# Review030 — Final grill hybrid facing / forward-only sprint
2026-10-27 · Codex Controller · **CHANGES_REQUESTED** RF-F44/45; directional animation gap remains; Owner feel not accepted.
Scope current camera-relative finalgrilldelta, report00348tests. No source edits or Play/input tests byController.

## RF-F44 — Medium: forward-only policy bypass through legacy payload
SprintService.onSprintIntentRequest still allows boolean payload and sets shouldSprint=payload without forwardintent validation. It also accepts any finite forward>0 (100 permitted) although actual resolved input domain is -1,0,1. Currentclient uses table exclusively; do not retain legacytrue bypass as active ingress. Reject sprint-start without validdirection and constrain forwarddomain; optionalfalse-only fail-safe stop if genuinely needed. No arbitrary client-speedresult authority.
Executed EXACT current server setSprintState/onSprintIntentRequest with fake character andclock, alongside exactclient sync functions: inputforward=-1,serverrequesttrue => WalkSpeed32,IsSprintingtrue. Table{isShiftHeld=true,forward=100} also starts32. This is direct handler test, not claimed livekeyboard or fullnetworkexploit proof. It contradicts currentforward-onlycontract regardless of normalclientvisual behavior.

## RF-F45 — Medium: sub-rate-window direction changes strand held sprint
Currentclient suppresses send when optimistic isSprinting==eligible and only schedulesretry on serverIsSprinting attribute CHANGES. Sequence within50ms:
- t10.00 forward+Shift => clienttrue/server32/attrtrue
- t10.01 backward => clientfalse/server16/attrfalse
- t10.02 forward => clienttrue; serverrejects ratelimit and SetAttribute(false) while alreadyfalse, so no negativeackedge/retry
- t11.00 unchangedheldforward+Shift sync => client returns withoutsend; serverstill16,clientthinkstrue
Deterministically executed EXACT currentclient syncSprintIntent+SetForwardIntent and EXACT currentserverhandler withfakeclock/remote/character. Output initial32,stop16,final16,clienttrue,serverfalse,rejectionAttributeEdges0. No gameplayscene mutation. Reducing rate limit from.20to.05 does not solve this; report003 rapidtest step.06s is outside rejectionwindow and missesfailure.
Required: reconcile start-rejection even when authoritative booleanstaysfalse (requestack/sequence or boundedgrounded retry, not per-frameremotes). Stop remainsimmediate; retry cancelled on inputineligible/focus/death/generationchange, no airborneresumeloop/staleackoverride. Keep requested, optimistic and authoritative state distinctions. Test <ratewindow orders, rejected startfromfalse, Shift+W direction swaps, landing, dualShift andserver32iffeligible.

## Verified nonblocking parts / evidence limits
- Source hybridfacing chooses travel yaw only forward>0, camera yaw otherwise; diagonalnormalization/cancellation retained. RF-F43 nativeORairflag/eligiblegroundguards now present. Scope improved; no closing earlier RF-F25lifecycle automatically.
- Independentreadback5/5exactmatches disk/StudioEdit at place137721422246269, hasDIAG_SEAM_BEGINfalse for all5. Source hashes match report003's5entries. Whitespace targeted check priorPASS, no newsourcewrite byreview.
- Report48scenarios are implementer results; independently reproduced counterexamples are not inthose48. No claim all48false; coverage was insufficient. Full livekeyboard/4clientnetwork/latency/security/performance NOTRUN byController thisreview.
- No authored strafe/backwalk clips. CurrentWalk16side/back is fallback, NOT visualanimationacceptance and not fullOwnergoalcomplete. Existing forwardRun shouldonlyplay eligibleforward; current speedgate flaws mustfixfirst. Do not author newassets without scopedOwnerreview/approval.
- RF-F42servercatchup remainsOPEN,outofcurrentcamera correction; jumpfilesfrozen/dribblePAUSED. Do not silentlychangejump tosolve sprint.

## Return
Samepane/sametask fixes withinalreadyallowed SprintController/SprintService/SprintConfigs (+minimalNetworkonlyifnecessary), preservehybridfacing andjump. No newpane/Git/publish. Preserve report003, writecamera-relative-report-004.md with exact runnable regressions, honest unrunchecks andanimationgap. Backup/narrowsync/readback5orchangedmodule closure, remove temporaryseams beforeOwner test. No rate-limit deletion/tolerancebluntchanges toclaimPASS.