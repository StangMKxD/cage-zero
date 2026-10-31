# Owner NPCMotion walking loop — normal possessed walking

2026-10-29 · Root personal implementation · **DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**.

> **Owner follow-up — level gaze:** Owner requested removing the bowed head. Only WalkDribble Head rotation now compensates for cumulative LowerTorso/UpperTorso lean, preserving source horizontal gaze/roll and all other joints. The original all-source-rotation comparison below describes the pre-adjustment import; Head is intentionally adapted now. Fresh actual Luau sample comparisons:23,474 unchanged non-head/other-clip joint samples; original combined gaze pitch -54.109..-40.469°, adjusted maximum absolute pitch0.00000854°, heading dot>=0.99999994. Live after-render probe at walk track weight>0.99:50samples, head gaze -0.01062..+0.00403°, carrier loss0.91keys/markers retained, single walk sequence rebuilt; prior sequence in `WalkHeadLevel_Backup_20261029`. Build/diff check exit0 and independent source readback exact. Source backup `.sandbox/before-walk-head-level.luau`, live summary `.sandbox/walk-head-level-play-summary.json`. Studio Edit; human visual review pending. No commit/publish.

Owner supplied a full slow walking loop and requested it for ordinary walking while possessing/dribbling, without making it a cut. Owner also requested a prior-version commit.

## Prior checkpoint

Created local **290726b** `feat(RF02/SPRINT-CUT): เก็บท่า cut ตามตัวอย่างก่อนเปลี่ยนท่าเดิน` before edits. This saves8 files for the previous sprint-cut version, without push. New walking-loop work remains uncommitted.

## Changes

- `WalkDribbleReferenceData.luau`: full91 supplied frames,0..3 seconds,15 joints,49 numeric values/frame. Original root travel and radians retained as immutable reference data. Parser checks numeric fields, strictly increasing times and complete loop extent.
- `DribbleClipData.luau`: normal WalkDribble now samples those exact joint rotations. Preserves original frame timestamps through optional frameTimes in the existing builder. Runtime loop is **3.0s /91keys /Movement /looped**, replacing the previous1.04s walk variant. Source Core priority is adapted to Movement to fit existing locomotion blending.
- Original horizontal root travel is omitted to keep the existing game-controlled character/ball movement and avoid the reference's final-frame position snap. Vertical pelvis position uses the existing normalized-rig support correction. Joint rotations are not softened, mirrored or replaced with run/cut data.
- Added ordinary TouchL markers0.4/1.7333s and TouchR1.0/2.3667s plus entry/loop markers (6 total), using the existing validated touch-intent path. These are integration marker placements, not proof of exact mesh-to-ball contact.
- `DribbleActionConfigs.luau`: only WalkDribble metadata changed to match. Existing input/carrier/sprint/air logic untouched. Source sync generator now includes the new reference module.
- Rebuilt only WalkDribble sequence; original under `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.WalkNPCMotion_Backup_20261029`. Other12clips, including latest sprint cuts/G/run, preserved.

## Actual verification

| Check | Result |
|---|---|
| Raw data | 91 rows×49 finite numbers, increasing0..3 times, identical source loop endpoint data |
| Fresh Studio module require / clip metadata | Passed;91keys,6markers, timestamps match source within1e-6 |
| Source rotation fidelity | All91×15 joint rotations match original reference matrices, max component error1.27e-7 |
| Loop seam | Joint rotations and grounded pelvis position agree within1e-4; root X/Z zero throughout sampled frames |
| Other-clip regression | 21,780 exact joint samples across12other clips unchanged |
| Actual rig FK | Sampled121poses: foot gap>=0.3243, knee gap>=0.3957, foot-box bottom0.0151..0.4104studs. No center-line crossing in samples; does not certify mesh overlap clearance |
| Live MCP keyboard W→S walking | Walk track duration3/looped/Movement, actual TouchL/R callbacks, two DidLoop events, ServerDribbleTouchClip=WalkDribble, no carrier loss in1,108observed frames including idle/tool delays |
| Walk/run transition portion | Existing Run and ReverseRight tracks observed when Shift was deliberately added after reversing direction; old sprint cut logic remains in place, not added to walking |
| Separate no-Shift walk-only smoke | 860observed frames including idle/tool delays, WalkSpeed16 throughout, cuts0 and carrier loss0 |
| Build / whitespace | `rojo build default.project.json -o .sandbox/walk-npcmotion-build.rbxlx` and `git diff --check` exit0 |
| Final independent readback | Reference module + clip data + config exact; Studio returned Edit |

Evidence: `.sandbox/walk-npcmotion-play-summary.json`, `.sandbox/walk-npcmotion-only-summary.json`. Existing asset203785492 type mismatch warnings remain; no new dribble error in captured output. No dedicated strict typecheck/full regression/multiplayer/performance certification. Human animation feel acceptance remains pending. This in-place adaptation does not certify world-space foot locking or exact visual foot/ball contact.

Try new Play, collect ball, walk normally with WASD without G/Shift. No new cut was authored in this task, no movement/ball-distance tuning, publish, push or task closure.
