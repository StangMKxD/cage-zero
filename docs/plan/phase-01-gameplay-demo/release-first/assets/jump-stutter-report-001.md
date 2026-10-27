# jump-stutter-report-001 (RF02-DRIBBLE-RECEIVE, jump-only)

Status: READY_FOR_REVIEW. Implementer: Claude Sonnet 5.5 (Medium) in pane argon, resumed after an interrupted Argon session. Dribble, front-ball and touch-phase work stays PAUSED; BallService and DribbleConfigs are untouched.

## Changed files (4)
| File | SHA-256 (disk = Studio Edit, verified by length and checksum) |
|---|---|
| src/shared/configs/JumpConfigs.luau | B6E4A3817D3CBE73775C0403165F96C916CAA29E219CDDBDF89DCB7F1C4DD012 |
| src/server/services/JumpService.luau | 7A448011C24ADB53D5693A7D1E0ADCC09ECBBC441A7557F488CA27BCB4BE59F2 |
| src/client/controllers/AirMovementController.luau | 490140B49BBFD23083EACDF0C6017D2789203584561B0C9ABCF17B9B79A6EA4C |
| src/client/controllers/MovementHeadingPreviewController.luau | 21660911843058A18E3A91334FAD9ED35C1CAC3BB49D8F5697B44693E011B4EE |

Backups from before editing: `.sandbox/rollback/rf02-jump-stutter-pre/` (disk and .studio-source).

## Causes found (measured in the normal initialized Play flow)
1. **Server snaps a descending character.** The server's vertical envelope used a liftoff clock and replicated position that lag the owning client. In Studio the server logged `posY` 4.7 to 5.5 studs above `expY` for about 14 frames of descent. Each frame ran `hrp.CFrame = ...`, which snapped the client (+2.5 studs up at t=0.77 in a stand jump).
   - Result: `JumpServerCorrectionCount` went up by about 16 per jump, on **every** jump including a stand jump.
2. **Takeoff-frame correction (earlier Argon trace).** The server wrote a stale yaw, or took coalesced `Freefall` as a ledge fall. That sent the character back to the ground: 5 of 6 moving-turn jumps aborted at 5.7 to 8.6 studs instead of 15.5.
3. **Native input overwrote `Humanoid.Jump` and `Move`.** `PlayerScripts` has no PlayerModule, so Roblox's input step at RenderPriority.Input (100) ran after Heartbeat and reset `Humanoid.Jump` to false. That gave 8 of 8 tap-jump failures.
   - A press on the Landed edge was eaten by Landed to Running.
   - `MoveDirection` stayed non-zero in the air.

## Fixes
- **JumpService:**
  - Classify `Freefall` by initial vy (`LEDGE_FALL_MAX_INITIAL_VY`).
  - Latch yaw during `TAKEOFF_YAW_SETTLE_WINDOW_SEC`.
  - Correct the soft-apex integral.
  - Per-step anti-teleport plus a cumulative horizontal radius.
  - Preserve velocity on a CFrame correction.
  - **Descent skew:** `expectedY = max(expectedYAt(t), expectedYAt(t - SERVER_FLIGHT_CLOCK_SKEW_SEC))`. While rising this is the same strict bound; it only relaxes while falling. No validator was disabled and the base tolerance (4.0) is unchanged.
  - Opt-in telemetry only: `JumpServerCorrectionCount` and `JumpServerLastReason`, gated on the `JumpDiagEnabled` attribute.
- **AirMovementController:**
  - Deadband-guarded yaw lock, so no per-frame CFrame teleport.
  - Same `Freefall` classification as the server.
  - Telemetry attributes on `Character`.
- **MovementHeadingPreviewController:**
  - Movement and jump step bound with `BindToRenderStep` at Input+5 (before physics, after native input); unbound in `Cleanup`.
  - `Move(0)` while airborne.
  - Jump buffer of 0.14s (`JUMP_BUFFER_WINDOW_SEC`), cleared on `Jumping` and on reset; landing-edge retry uses `ChangeState(Jumping)`.
- Preserved: `JUMP_POWER` 72, soft apex, four-way lean, yaw lock, takeoff momentum, `MAX_AIR_HORIZONTAL_SPEED`.

## Evidence (actual Play, real controller handlers)
Studio `1d7a6b31-...`, place 137721422246269. Keys were injected through a temporary attribute seam that called the real `onInputBegan`/`onInputEnded`. No OS input or focus was used. The seam and the diagnostic telemetry were removed afterwards (see the readback below).

| Scenario | Before | After |
|---|---|---|
| Stand tap-jump, 6 trials | 6/6 launched, ~16 server corrections per jump (97 over 6) | 6/6 launched, 1 correction in total, 0 upward snaps |
| Walk (W) jump, 6 trials | launched, ~16 corrections per jump | 6/6 launched, 0 corrections |
| W to D chord change on the jump frame, 6 trials | 5/6 aborted early (earlier Argon trace) | 6/6 rise 15.50 to 15.60, 0 corrections |
| W to A just after liftoff, 6 trials | launched, ~16 corrections per jump | 6/6, 0 corrections |
| Landing-edge retry (tap, land, tap), 6 trials | not measured in this form | 6/6 second jump launched |
| Yaw deviation in air (30 flights) | not measured | 0.0 deg |
| Lean | not re-measured | W -14.9, S +15.0, A roll +14.9, D roll -15.0 deg pitch/roll, yaw 0.00 dev, back to 0 after landing |
| Air-only distance | not re-measured | stand 0.0, walk about 13.0 studs (stand < walk) |
| Death mid-flight with W held, then respawn | not run | new character: AnimationConstraint, `MovePreviewActive` true, not airborne, jump rise 15.53 |

## NOT RUN
- Sprint (Shift) and stand < walk < sprint air distance: the seam has no Shift. Only stand < walk was measured. The takeoff momentum code was not changed.
- Camera 360 orbit while airborne (the yaw-lock check used chord changes only), wall and ceiling collision guard, server negative exploit tests, high-latency or real-network runs (only Studio Play Solo with ~0.6 ms ping).
- Owner manual tuning and retest. This is not a claim that gameplay is signed off.
- Static check: `rojo build default.project.json` built OK. `git diff --check` printed only existing LF/CRLF warnings.

## Final state
- Studio is in Edit mode.
- Disk and Studio Edit lengths and checksums match for all 4 files; the ends of both match (readback at 08:55).
- Persistent Motion bridge was not touched.
- No Git, publish or board edits.
