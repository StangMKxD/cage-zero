# G walking steps — low alternating foot lift

2026-10-29 · Owner direct refinement: upper body and leg silhouette accepted; replace side-to-side leg waving with slow directional steps and a small foot lift. Root implemented personally; **DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**, no independent self-signoff.

## Change

Only DribbleClipData changed as game source. Kept the existing G upper-body pose output, idle stance, clip metadata and phase-preserving controller. Added an authored foot trajectory: 60% stance / 40% swing per foot, opposite half-cycle phases, 0.18-stud swing lift. Directional targets use low Hermite swing paths and a backward stance stroke instead of rocking hip angles alone. A two-bone leg solve bakes targets into ordinary hip/knee/ankle rotations using the measured normalized rig; no runtime IK, extra render loop or movement/ball tuning. This is an in-place gait, not a world-space foot-lock solver.

Five moving G sequences rebuilt; stationary G sequence preserved. Previous sequences: `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.GWalkingSteps_Backup_20261029`. Source backup: `.sandbox/before-g-tiptoe-DribbleClipData.luau`. Existing sync payloads/hash manifest regenerated.

## Actual checks

- Fresh Studio Luau old/new pose comparisons: 19,239 sample comparisons confirmed all nine upper-body joints unchanged in G and all non-G poses unchanged. Seven loop endpoints pass within 0.001 tolerance.
- Actual rig forward kinematics, 121 samples per G definition: moving foot bottom 0.020..0.200 studs; lateral gap >=0.9767, knee gap >=1.0024; no crossing in the samples. Uses live rig joint offsets and 8-corner foot boxes, normalized root Y=4.183.
- ValidateClip passed five rebuilt sequences / 793 keys; temporary modules destroyed. Source synced with editor/concurrent-source guard and exact readback.
- Fresh Play keyboard G+A→D→W→S. After-render probe selected settled moving G tracks with weight >0.99. Directional frames: left52 / right56 / forward56 / backward55 =219. Every frame has a support foot below0.05 studs; both-feet-lifted frames=0. Each direction contains both left and right low-lift frames. Min foot bottom0.0068, max0.1994; speed8 throughout, no carrier loss.
- One extra G-idle transition sample was recorded separately and is not included in those219 settled directional frames. Transition-blend clearance and world-space sliding are not certified by the settled-frame test.
- `rojo build default.project.json -o .sandbox/g-walking-steps-build.rbxlx` and `git diff --check`: exit0. Summary: `.sandbox/g-walking-play-summary.json`. Human visual acceptance remains pending; multiplayer/full regression/performance not run.

Try new Play, collect ball, hold G and move A/D/W/S. Upper-body stance should be as before, with visible low alternating lift and step/plant rather than continuous leg swaying. No commit/publish/task closure.
