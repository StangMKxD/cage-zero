# Gate1 Discovery — Review010

2026-10-25 · Codex · **CHANGES_REQUESTED — narrow remaining source-evidence corrections**.
HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + docs. Discovery003 SHA256 `c128cef2c26f7a0f7ad12ad732b9afef6c43759c7ce90bf4231e3660b5e081de`.

All63 source/doc hash rows match; existing link checker45 files/167 links SUCCESS; src/tests status empty. No application tests/Studio/Git mutation. Argon bounded audit finished; no further Argon work assigned.

## Stable finding disposition

- **RF-F14 VERIFIED:** metrics explicitly distinguish Get-Content/Split/Nonempty; category counts coherent and snapshot fingerprints current.
- **RF-F15 VERIFIED for plan ordering:** client callers now removed before providers, server callers before server providers; atomic non-runnable edit group and Studio sync barrier stated. Execution still not authorized.
- **RF-F11 OPEN, narrowed:** audited bootstrap/Network/type exports corrected. Manifest§3.5.B still names three coupled fields incorrectly: actual Types PlayerMovementSnapshot fields are `chargeCurveSide` at342 (not curveSide), `activeSkillMove` at357 (not skillMoveId), `activeTackle` at358 (not tackleType). Replace with exact literals; no new spot audit necessary. Function entry anchors in InputController/BallService largely match source, but they do not establish internal retained-function closure.
- **RF-F12/RF-F13 OPEN, narrowed to retained-function internals:** active/dormant distinction now correct. Manifest§3.1 still broadly KEEP BallService.Init3320..EOF and StepPhysics2271..2851, with only a vague internal skill-hook exception. Init3339..3343 obtains BallActionRequest and connects a callback to HandleActionRequest, which is marked REMOVE. Init also binds setupPlayerLifecycle and PlayerRemoving closures that use playerStates/pendingCagePresses. StepPhysics starts by processing old stamina/flight/player states and invokes other helpers. Keeping these ranges intact while removing router/state providers is not a runnable foundation contract. Likewise InputController retained Init1294..1327 already defines a bindChar closure that continues outside that range and resets old action state; it cannot be retained as a free-standing syntactic slice.

## Required final targeted evidence

1. Correct exact three field names above.
2. For retained BallService.Init/StepPhysics and InputController.Init only, enumerate callbacks/helpers/state fields they actually reference and mark each retain/remove/adapt at exact source anchors, including remote registration and player lifecycle. Explain intended completed function structure; no slicing mid-function. Trace referenced helper dependencies until no removed providers remain, or explicitly mark unresolved gate and refrain from cleanup-ready claim. Use extracted source evidence, not hypothetical code. Avoid widening to unrelated dormant services or rewriting whole manifest again.
3. For uncertain providers/TrainingHUD/solver configs, state clearly whether excluded from the immediate cleanup proposal or included with exact consumer removal; diagram must not unconditionally delete undecided items. Keep R6 idle/rig foundation and stadium physics but no new R15/gameplay/Idle authoring.
4. One discovery-report004 with errata and refreshed fingerprints, no old report edits. Source remains read-only, no tests/Studio/Git. Source-preserving future adaptation may be described, not implemented now. Automatic push report; no monitoring. Owner will be asked before deletion/new gameplay once evidence is ready.

This review does not mark the removal manifest safe merely because other documentation findings verified. Owner authorized continued read-only preparation/corrections; that authority remains the only execution scope here.
