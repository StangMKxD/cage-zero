# jump-stutter-report-002 (backward / different-from-facing jump) - BLOCKED (partial)

Status: **BLOCKED**. The fix is on disk, but the AFTER trials and the final Studio readback were not completed. Studio disconnected during the AFTER harness run (`Target is closed (INVOKE_ExecuteLuau.runCode_ToRequester, DMN_ID_PLAYCLIENT)`). Then `list_roblox_studios` returned `[]` at 09:17. Cause unknown; it may have been closed by the Owner. report-001 is preserved. Dribble stays PAUSED.

## Measured BEFORE (initialized Play, place 137721422246269, studio `20eb6cfa-...`)
Keys were injected through the temporary seam into the real `onInputBegan`/`onInputEnded`, so this is real handler logic, not OS key input. 4 trials per scenario, 28 in total. Per-frame PostSimulation sampling.

| Scenario | Takeoff face-vs-velocity | maxFrameDV (studs/s) | maxPosResid (studs) | serverCorr | yawDev |
|---|---|---|---|---|---|
| W held, jump (forward) | 0 deg | 2.4 | 0.02 | 0 | 0.00 |
| S held, jump (backward, facing = travel) | 0 deg | 2.4 | 0.02 | 0 | 0.00 |
| W, then S + Space on the jump frame (reverse) | 180 deg | 32.0 (3 of 4 trials) | 0.40-0.53 | 0 | 0.00 |
| W, then D + Space | 90 deg | 22.6 | 0.28-0.38 | 0 | 0.00 |
| W, then A + Space | 90 deg | 22.6 | 0.28-0.47 | 0 | 0.00 |
| W, then S+D + Space | 135 deg | 29.6 (2 of 4 trials) | 0.49 | 0 | 0.00 |
| Mid-air W to S | - | 2.4 | 0.02 | 0 | 0.00 |

Frame-by-frame trace (W held, then S + Space on the jump frame):
- Stepped t=0.033: hv=(0,-16), state Jumping.
- Post t=0.034: hv=(0,+16), vy 74.7. The horizontal velocity is flipped by 32 studs/s in one frame.

The server was not involved (0 corrections) and yaw stayed locked (0.00 deg). This is a **physical velocity discontinuity**, not a joint or yaw jerk, and I did not run a separate joint-jerk measurement.
- Cause: `AirMovementController.onLiftoff` picks `takeoffDirection` from the new `MoveDirection`. `onStepped` then overwrites `AssemblyLinearVelocity` with `takeoffDirection * takeoffSpeed` on the very first frame. The actual ground velocity (the old direction) is discarded.
- Cases where travel and facing agree show no jump in velocity.

## Fix on disk (NOT yet verified in Play)
- `JumpConfigs.TAKEOFF_VELOCITY_BLEND_SEC = 0.10`.
- `AirMovementController`: record the actual horizontal velocity at liftoff (`takeoffStartHoriz`).
  - For `TAKEOFF_VELOCITY_BLEND_SEC`, drive the horizontal velocity with `takeoffStartHoriz:Lerp(takeoffVector, alpha)`.
  - The vector never exceeds `takeoffSpeed`, so there is no boost.
  - The collision guard is held off until the blend ends, because a 180 degree blend passes through low speed.
- Unchanged: yaw lock, `takeoffDirection` selection (input still sets the travel vector, independent of facing), lean, soft apex, validators and tolerances. The body is not rotated.

| File | SHA-256 on disk |
|---|---|
| JumpConfigs.luau | FD5E2A7743D89C873DB9E2850A2B75A2D1E047909DFB92DE1DE42BF6AC20DD8E |
| AirMovementController.luau | 9CA3956F5CA8D103F7B26292FE3FBA7158CD2DAD46D1C7133ABD1326994BC159 |
| JumpService.luau (unchanged since report-001) | 7A448011C24ADB53D5693A7D1E0ADCC09ECBBC441A7557F488CA27BCB4BE59F2 |
| MovementHeadingPreviewController.luau (unchanged) | 21660911843058A18E3A91334FAD9ED35C1CAC3BB49D8F5697B44693E011B4EE |

Pre-edit backup: `.sandbox/rollback/rf02-jump-backward-pre/` (4 files).

## Sync / readback
- 09:14: the two edited files were patched into Studio Edit. Length and checksum matched disk (JumpConfigs 4551, AirMovementController 20196). Play was then started with the temporary input seam still in `MovementHeadingPreviewController`.
- The final cleanup was **not** done: the seam removal and the final disk-vs-Studio hash check did not run, because Studio disconnected.
- Unknown: whether the Studio session (including the seam) was saved. If the Owner reopens the place, the seam may still be present in Studio's `MovementHeadingPreviewController`. Disk has no seam. Re-sync from disk before any Owner test.

## NOT RUN
- AFTER trials (backward, opposite, side, diagonal, direction change at the jump frame, forward regression): the harness run was interrupted.
- Fresh init, respawn and camera orbit for this fix.
- Sprint, exploit negatives, network and collision tests.
- Static: rojo build and `git diff --check` were not re-run after this edit.
- Owner retest.

## Resume steps
1. Reconnect Studio and check the current mode.
2. Re-sync the 4 disk files into Studio and verify parity (this removes any leftover seam).
3. Re-add the temporary seam and run the 8-scenario harness at 6 trials each. Expect maxFrameDV about 2 to 6 studs/s for the reversal cases.
4. Remove the seam, verify parity again, then run rojo build.
