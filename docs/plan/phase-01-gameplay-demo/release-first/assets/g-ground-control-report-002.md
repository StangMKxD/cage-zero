# G duel stance — Owner refinement 2026-10-29

Root implemented personally; **DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**. No independent self-signoff.

Owner requested more side-step motion, wider legs, bent knees/lower body, forward lean, arms spread and bent forward, smoother motion. Both source modules and six G AnimSaves sequences updated and synced; user-controlled ball distance preserved.

- Stance: outward hip roll 9°, hip flexion 22°, knees 44–56°, pelvis/chest forward lean 7°/9°, arms spread about 30°, elbows about 58°. Side steps add alternating 6.5° hip roll, 6° fore/aft swing and knee flexion.
- Replaced positive-half-wave knee/absolute-value bob with continuous sinusoids; added smooth support-height correction while baking poses, using measured normalized ROBLOX Boy Height30 rig offsets/foot boxes. No added per-frame physics or IK loop.
- Direction changes in DribbleAnimationController retain normalized G gait phase and existing 0.18s fade instead of restarting at phase zero.
- Only DribbleClipData / DribbleAnimationController changed as game source for this refinement. Non-G pose functions and Definitions/BuildKeyframeSequence source compare equal (excluding trailing EOF whitespace). Names/durations/markers remain stable. Existing sync payloads/manifest regenerated.

## Actual checks

| Check | Result |
|---|---|
| Fresh Studio Luau module require / ValidateClip / exact endpoint pose comparisons | Passed six G clips / 1,018 keys; temporary modules destroyed |
| Actual rig forward kinematics, 121 samples per G clip, all 8 foot box corners | Authored feet bottom 0.015..0.225 studs, foot lateral gap >=1.4747, knee lateral gap >=1.3507; assumes normalized player root Y=4.183 |
| Fresh Play actual G idle→A→D→W+Shift→release G | Correct tracks, G speed8/release RunDribble speed32, no carrier loss in recorded groups |
| After-render phase continuity | Dominant-track phase errors 0.0139 / 0.00027 / 0.0602 cycles across three direction changes |
| After-render lateral foot motion | About 0.38–0.47 studs per foot during side-step samples |
| Build / whitespace | rojo build default.project.json -o .sandbox/g-duel-stance-build.rbxlx and git diff --check exit0 |
| Final independent readback | Both modules exact; Studio returned Edit |

Runtime blending still produced transient foot-box floor penetration (lowest G sample about -0.152 studs), despite standalone baked poses clearing the floor. This does not certify full rendered mesh clearance or human visual acceptance. Existing asset203785492 type warnings remain; multiplayer, full regression and profiling not run. Source-comparison check initially reported a trailing-newline-only difference; rerun explicitly ignoring EOF whitespace passed.

Backups: `.sandbox/before-g-duel-DribbleClipData.luau`, `.sandbox/before-g-duel-DribbleAnimationController.luau`; previous Studio sequences in `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.GDuelStance_Backup_20261029`. Live telemetry summary: `.sandbox/g-duel-play-summary.json`.

Ready for Owner to start new Play, collect ball, hold G and alternate A/D/W/S. No commit/publish/closure or external-pane dispatch.
