# Owner camera direction — queued AFTER Idle

2026-10-25 · Source: Owner describes Illegal Soccer-like viewing/movement and answers camera questions. This is design context, not implementation authorization for advanced camera now.

## Accepted intent

- Replace old ShiftLock with an advanced center-reticle mode: cursor hidden during active aiming/view control, no visible pointer dragging/jumping,comfortable camera movement.
- Viewing direction and character running/facing are not always forcibly the same. Player can look toward the ball while continuing movement and use A/D/S according to the direction viewed; W alone should follow the camera. When dropping diagonal input to W alone, follow the camera immediately.
- On shooting, character faces the viewed/aimed direction. Existing ball trajectory/landing guides aid distance judgment; don't invent an automatic shot/success rule.
- Advanced mode is AFTER Owner-led Idle work. Do not hard-code an invented WA/WD world-heading latch from the Controller's earlier question: Owner's explanation emphasizes compensating with A/D/S as view changes. Exact input/heading feel must be shown in a small Owner-controlled preview before committing that detailed behavior. No need to ask Owner technical vocabulary.
- Owner explicitly chooses temporarily disabling old ShiftLock now and using normal camera until advanced mode is ready.

Normal-camera temporary task is governed separately by camera-normal-temporary-HANDOFF.md. No new reticle/free-look/ball-tracking system is implemented by that temporary task. Manual ability to look at ball is not an approved automatic ball-follow camera.
