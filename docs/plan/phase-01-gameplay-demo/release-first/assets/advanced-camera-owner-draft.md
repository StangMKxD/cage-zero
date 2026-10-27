# Owner camera direction — queued AFTER Idle

> **Latest Owner prototype direction:** Idle preview accepted. Owner now authorizes a camera preview and specifies view-only camera rotation with center reticle and preserved running direction. [camera-preview-HANDOFF.md](camera-preview-HANDOFF.md) controls exact source/Studio scope. Disclosed prototype mapping snapshots world heading per held-input combination; new chord/currentview updates heading,including diagonal->W. No head/chest/root pose writes or shot integration. Owner will judge this feel;do not silently replace the approved Idle.

> **Idle dependency:** Owner accepted RF02_Idle_Ready_R15_v01 preview; canonical clip animates Head and UpperTorso (see review023). Orbit/view input alone must not overwrite Idle pose joints. If future look-at-ball/aim requires head/chest rotation, specify blend/mask/priority and smooth return to accepted Idle. Character/world heading is controlled separately from clip RootPose; do not conflate camera yaw with forced body yaw. This is a planning seam,not new camera implementation permission.

2026-10-25 · Source: Owner describes Illegal Soccer-like viewing/movement and answers camera questions. This is design context, not implementation authorization for advanced camera now.

## Accepted intent

- Replace old ShiftLock with an advanced center-reticle mode: cursor hidden during active aiming/view control, no visible pointer dragging/jumping,comfortable camera movement.
- Viewing direction and character running/facing are not always forcibly the same. Player can look toward the ball while continuing movement and use A/D/S according to the direction viewed; W alone should follow the camera. When dropping diagonal input to W alone, follow the camera immediately.
- On shooting, character faces the viewed/aimed direction. Existing ball trajectory/landing guides aid distance judgment; don't invent an automatic shot/success rule.
- Advanced mode is AFTER Owner-led Idle work. Do not hard-code an invented WA/WD world-heading latch from the Controller's earlier question: Owner's explanation emphasizes compensating with A/D/S as view changes. Exact input/heading feel must be shown in a small Owner-controlled preview before committing that detailed behavior. No need to ask Owner technical vocabulary.
- Owner explicitly chooses temporarily disabling old ShiftLock now and using normal camera until advanced mode is ready.

Normal-camera temporary task is governed separately by camera-normal-temporary-HANDOFF.md. No new reticle/free-look/ball-tracking system is implemented by that temporary task. Manual ability to look at ball is not an approved automatic ball-follow camera.
