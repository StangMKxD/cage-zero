# G close-control — Low steps without sole rolling

2026-10-29 · Owner direct instruction: “ปรับทางเทคนิค และอนเมชั่นต่อเลย คือไม่ต้องยกขามาคลึงบอลแล้ว” / “นายทำเองเลยงานนี้”. Root implemented personally; **DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**, not independent technical signoff. This bounded Owner delta supersedes prior source freeze for this change only.

## Changes

- `DribbleClipData.luau`: replaced six G pose functions (idle, forward, backward, left, right, legacy reverse) with low alternating steps/quiet ready stance. Removed overhead sole reaches, cross-body sweeps, deep crouches and pelvis lunges. Joint translation on legs is zero; upper-leg pitch ≤18°, knee pitch ≤22°, pelvis translation ≤0.06185 studs. Existing clip names, lengths, priorities, key counts and marker timing retained for binding compatibility; legacy names containing SoleRoll now contain the new step poses.
- `DribbleAnimationController.luau`: evaluates goal mode before the stationary early return, so held G at rest continues its ready loop and returns to normal idle on release.
- No ball-distance/config/server-physics tuning. Owner's 1.95/1.85 G settings retained. Walk/run/cut pose data retained.
- Synced both modules to the verified Cage-Zero Edit datamodel with unchanged-source/editor guards and independent exact readback. Rebuilt only six G clips in `PreviewRig_R15_Boy_Height30.AnimSaves`. Prior six sequences preserved under sibling folder `GNoSoleRoll_Backup_20261029`.
- Regenerated existing sync payloads and source hash manifest so future sync cannot restore obsolete G poses.

## Actual verification

| Check | Result |
|---|---|
| Fresh cloned Luau module require + BuildKeyframeSequence + ValidateClip | Passed 6 G bindings / 1,018 keyframes, correct metadata; no leg translations or high hip/knee poses |
| Before/after non-G clip comparison in actual Studio Luau | Passed 7 clips / 17,584 exact Pose CFrame comparisons; both temporary modules destroyed |
| Fresh Play, actual keyboard G held at rest | Ready loop active, horizontal velocity approximately 0, WalkSpeed 8, touch count increased |
| Actual G+W/S/A/D, including Shift+D | Correct directional loop, speed 8, peak horizontal velocity 8, no carrier loss in smoke |
| Release G with Shift+W still held | Normal RunDribble and speed 32 restored, no carrier loss |
| After-render foot probe at RenderPriority.Last+1 | G foot bottom-center Y about -0.0475..0.147 studs; feet stay at turf level rather than on top of ball. Small floor intersections remain; this is not full mesh collision or toe-corner clearance proof |
| `rojo build default.project.json -o .sandbox/g-no-sole-roll-build.rbxlx` | Passed exit 0 |
| `git diff --check` | Passed exit 0, LF/CRLF warnings only |
| Independent final source readback | Both changed modules exact; Studio returned Edit |

Console still reports asset `203785492` type mismatch three times, as in Review036; no dribble-specific error in captured output. No published animation IDs, multiplayer/latency, complete respawn/menu/focus/jump matrix or performance profiling tested. Owner visual assessment remains pending; telemetry does not substitute for human visual acceptance.

## Evidence / rollback / how to try

- Local smoke summary: `.sandbox/g-grounded-play-summary.json` (after-render actual tracks/attributes/foot positions).
- Disk backups: `.sandbox/before-g-grounded-DribbleClipData.luau` and `.sandbox/before-g-grounded-DribbleAnimationController.luau`. Studio sequence backup folder above. Restore only these scoped files/sequences if requested, preserving unrelated dirty work.
- Start a new Play, collect the ball, hold G and try W/S/A/D; hold Shift too, then release G while continuing W+Shift. At rest G should use a quiet ready stance; moving G should use low steps. No Motion bridge settings or published assets changed.
- `focused-verification` reference file unavailable: `C:\Users\Stang\.teamai\team-repo\skills\focused-verification\references\verification-selection.md`. Used the inspected local code/handback contract and R04/R05 to select the explicit checks above; did not invent that missing file's instructions.

No commit, push, publish, external-pane dispatch or task closure. Earlier Review036 observations remain historical; Owner-controlled distance issue withdrawn and module parity restored separately.
