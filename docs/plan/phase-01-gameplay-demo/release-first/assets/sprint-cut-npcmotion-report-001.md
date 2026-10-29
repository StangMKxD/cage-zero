# Sprint cuts — Owner NPCMotion reference adaptation

2026-10-29 · Root direct implementation · **DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**. Owner asked to replace sprint ball-lock cut animations using the supplied cut-left style, apply it to other directions, sync and check syntax. No independent self-signoff.

## Requested checkpoint

Before any cut changes, created local commit **c0a9c1f** `feat(RF02/WALK-DRIBBLE): เก็บท่าเดินเลี้ยงบอลแบบนุ่มก่อนปรับท่า cut`, saving5 files for the current soft walk version. Prior G checkpoint remains2ab782d. No push. New cut work remains uncommitted for Owner playtest.

## Animation changes

- New `SprintCutReferenceData.luau` retains13 decimated samples from the supplied NPCMotion **1.6..3.0s** approach/plant/pivot/exit segment, 15 joints and49 numeric columns per row. This is a sampled adaptation, not an exact import of the entire original91-frame/3s animation. Source radians use CFrame.Angles (same XYZ convention as the supplied matrix function); CFrame interpolation avoids Euler-wrap jumps near the pivot.
- `DribbleClipData.luau` adapts the sampled segment to front-left/front-right45°, back-left/back-right135°, reversal180°. Right clips mirror left joint names and rotations; sharper turns add braking/twist. Removed superseded cut pose generators.
- Original horizontal root travel (ending around Z=-29.48) and accumulated heading are not applied. Existing cut controller remains movement authority. Only bounded local weight shift/lean plus grounded pelvis correction is baked into poses. Entry/exit blend to existing run choreography.
- Five existing clip names/durations/key counts/markers preserved: front0.68s/137keys each, back0.76s/153keys each, reversal0.82s/165keys. Existing ReverseLeft/ReverseRight input bindings still share the single reversal sequence, as before. G reverse, G loops, walk and sprint loops unchanged.
- Kept **Action** priority and one-shot behavior required by the existing integration; the example's Core priority would not reliably override Movement locomotion. No new remote, server validation, speed, possession, ball physics or cut-lock timing changes.
- Synced two modules with readback; rebuilt only five cut sequences. Prior sequences preserved under `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.SprintCutNPCMotion_Backup_20261029`. Sync generator/payloads/manifest include the new reference module.

## Actual verification

| Check | Result |
|---|---|
| Reference parser | 13 strictly increasing times,15 joints,49 fields/frame; malformed stride rejected |
| Syntax/runtime compile | Fresh Studio Luau require of new reference/data modules passed; cold Play bootstrap also succeeded |
| Clip validation | 5 cuts /745 keys; expected markers, durations, joints, Action and non-looped metadata passed |
| Regression pose sampling | 8 non-cut clips unchanged across14,520 exact joint samples, including G/walk/run |
| Directional symmetry | 3,630 mirrored joint-rotation sample comparisons passed |
| Actual normalized-rig FK | 121 samples/cut: min foot gap0.6015, min knee gap0.7250; foot-box bottom0.0150..0.7737. No crossed legs in these samples; not full rendered mesh clearance certification |
| Live keyboard MCP | FrontLeft, FrontRight, BackLeft, BackRight and ReverseLeft all observed playing Action non-looped tracks at0.68/0.76/0.82s |
| Marker/lifecycle | Touch markers, ControlRelease and ClipEnd observed for all5 clips; lock→unlock observed, final lock=false; carrier retained across7,701 telemetry frames including idle/tool delays |
| Build | `rojo build default.project.json -o .sandbox/npcmotion-sprint-cuts-build.rbxlx` exit0 |
| Whitespace | `git diff --check` exit0 |
| Final independent readback | Both modules exact; Studio returned Edit |

Actual input sequences used Shift with W/A/D/S chords, then G+W to move the carrier away from the boundary before a clear S→AS transition verified BackLeft. No controller Init/TryStart calls or manual marker/possession grants were used. Repeated cut activations and a final early cancellation during key release were observed; existing input/controller logic was not changed by this animation-only task. ReverseRight's separate input path was not independently exercised; it uses the same verified reversal sequence.

Console retains existing unrelated asset203785492 type mismatch warnings. Dedicated strict typecheck tools were not available from Get-Command; do not interpret runtime syntax/require checks as full strict analysis. Human visual similarity, full cancellation/death/respawn matrix, multiplayer/latency and performance profiling remain unverified. Studio fallback assets only, no publish.

Evidence: `.sandbox/npcmotion-cuts-play-summary.json` and `.sandbox/npcmotion-cuts-fk.json`. Try a new Play, collect the ball, hold Shift and enter AW/WD/AS/SD; W→S tests reversal. Owner visual acceptance remains pending. No new-work commit, push or task closure.
