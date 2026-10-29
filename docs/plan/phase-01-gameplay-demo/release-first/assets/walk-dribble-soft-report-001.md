# Normal walking dribble — softer run choreography

2026-10-29 · Root direct implementation · **DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**.

Owner requested normal walking dribble and explicitly authorized committing the prior version first, then clarified: use the same system as running dribble, with softer animation.

## Prior-version checkpoint

Created local commit **2ab782d** `feat(RF02/G-CONTROL): เก็บเวอร์ชันท่าเลี้ยงบอล G ก่อนปรับท่าเดิน` on `codex/plan02-animation-rework` before any walk changes. Includes18 existing source/config/artifact/report files; working tree was clean immediately afterward. This is an Owner-requested checkpoint, not independent technical approval. No push. New walking work remains uncommitted.

## Implementation

- Only game source changed: `src/client/character/DribbleClipData.luau`. Walk pose now derives directly from accepted `runDribblePose` choreography, preserving its alternating-touch phases. Hip pitch62%, knee flexion65%, arm swing48%, torso/head rotation55%; arm bend reduced around36° and body lunge reduced. Ground support correction is baked using the existing normalized-rig helper.
- Same existing controller, possession/sprint/air guards, actual TouchL/TouchR marker path and validated server touch system. No new movement system, remotes, physics, G tuning or ball-distance changes.
- Retained WalkDribble1.04s/209keys/Movement/looped and original markers TouchL0.195 / TouchR0.715. Run remains0.72s. Existing slower walk cadence plus reduced amplitudes provides the softer variation.
- Synced exact module source and rebuilt only WalkDribble in AnimSaves. Prior sequence under `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.WalkDribbleSoft_Backup_20261029`. Regenerated existing sync payloads/hash manifest.

## Actual evidence

- Fresh old/new Studio Luau comparisons: **12 other clips unchanged across21,780 exact pose samples**, including all G and Run/cuts. Walk loop endpoints exact, ValidateClip passed. Hip peak walk38.39° vs run61.92°.
- Forward kinematics against actual normalized rig: foot bottom0.015..0.5834 studs; foot lateral gap>=0.7925, knee gap>=0.8214. This does not certify full mesh collision clearance.
- First fresh-Play smoke: actual walk track1.04s/speed16, run track0.72s/speed32 and return-to-walk route observed, no carrier loss in recorded groups. Settled walk foot-box bottom0.0143..0.5840. Initial marker telemetry was inconclusive and not called passed.
- Follow-up live test explicitly confirmed real carrier before input, attached observers to actual Animator tracks, then W2.5s→S1.5s: **8 real WalkDribble marker callbacks, TouchL4/TouchR4**, character touch count8, ServerDribbleTouchClip=WalkDribble, both feet observed, no carrier loss across803 observed frames including tool delays/idle. No manual controller Init/marker invocation or possession grant. Character repositioned next to the actual free ball through temporary server test setup, then normal receive established possession before testing.
- `rojo build default.project.json -o .sandbox/walk-dribble-soft-build.rbxlx` exit0; `git diff --check` exit0. Existing unrelated asset203785492 type warnings remain. No full regression, multiplayer/latency, world-foot-lock or performance claims.
- Local evidence: `.sandbox/walk-soft-play-summary.json`, `.sandbox/walk-soft-markers.json`. Human animation feel acceptance remains pending. Studio returned Edit; independent final source readback exact.

Try new Play, collect ball, walk with WASD without G/Shift, then hold/release Shift. Walk should retain the run-dribble rhythm with gentler arms, body and legs. G and running remain checkpoint versions. No new-work commit/publish/task closure.
