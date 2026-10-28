# RF02-DRIBBLE-ANIMATION — Authoring & Preview Report (`ANIMATION-REPORT.md`)

- **Task ID:** `RF02-DRIBBLE-ANIMATION`
- **Role / Session:** `implementer (ANIMATION ONLY)` (`w2:p52`, Model: Gemini 4 Argon (Medium))
- **Report To:** Controller (`w2:p43`)
- **Timestamp:** 2026-10-27T22:12+07:00
- **Isolated Workspace:** `C:\Users\Stang\cage-zero\cage-zero-animation-work`
- **Main Project (`C:\Users\Stang\cage-zero`):** Strictly READ-ONLY (0 source/doc edits, 0 Git operations, 0 `AnimSaves` writes, 0 published assets)

---

## 1. Live Motion Tools & Preview Rig Identity

| Property | Value |
|---|---|
| **Place / PlaceId** | `Cage-Zero` (`137721422246269`) — Studio `Edit` Mode |
| **Persistent Bridge Daemon** | `C:\Users\Stang\AI-Tools\run-animation-session.mjs` (`pid: 25028`, `rpcPort: 54034` read fresh from `animation-rpc.json`, `bridgePort: 17331`, `health: 200 OK`) |
| **Live Motion `sessionId`** | `0e7f69a9-ee63-4987-96ee-ca653f2883bd` (`online: true`) |
| **Target Preview Rig Path** | `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30` |
| **Target Preview Rig ID** | `d360f7b9-0c8d-4edb-b405-630594559c92` (`15/15` `AnimationConstraint` joints inspected, `0` issues) |
| **Camera Framing** | Framed 3/4 front-left at `PreviewRig_R15_Boy_Height30` (`Pivot: (0, 4.183, 45)`) |

---

## 2. Authored Clips Inventory, Mapping, Durations & Markers

All 9 clips are authored for the normalized R15 topology (`15/15` driven joints: `LowerTorso`, `UpperTorso`, `Head`, `LeftUpperArm`, `LeftLowerArm`, `LeftHand`, `RightUpperArm`, `RightLowerArm`, `RightHand`, `LeftUpperLeg`, `LeftLowerLeg`, `LeftFoot`, `RightUpperLeg`, `RightLowerLeg`, `RightFoot`), saved into the local Motion Tools library (new UUIDs only; all 5 existing accepted locomotion UUIDs untouched), and audited via `motion_animation_audit`.

### A. Base In-Place Dribble Cycles (`loop = true`, `priority = Movement`)
Designed for continuous travel with distinct left/right forefoot/instep ball-control touches and **no periodic lateral ball/body sway on held `W`**:

| Clip Name | Motion Library `assetId` | Input / State Mapping | Duration | Keys | Loop | Markers (`time` : `name` / `value`) |
|---|---|---|---|---|---|---|
| `RF02_WalkDribble_R15_v01` | `dd820132-adba-4028-a2a9-bee3ed64c69a` | `WALK_DRIBBLE` (Base walk dribble cycle, all directions) | `1.04s` | `33` (`495` total) | `true` | `0.000s`: `LeftSupportEntry` (`left_cycle_start`)<br>`0.195s`: **`TouchL`** (`left_foot_ball_touch`)<br>`0.520s`: `MidCycleTransition` (`right_half_entry`)<br>`0.715s`: **`TouchR`** (`right_foot_ball_touch`)<br>`1.040s`: `WalkDribbleLoop` (`loop_seam`) |
| `RF02_RunDribble_R15_v01` | `cfb4c569-e5e3-4fa3-a799-a9efb1183f63` | `RUN_DRIBBLE` (Sprint / run dribble cycle, forward lean + laces micro-taps) | `0.72s` | `33` (`495` total) | `true` | `0.000s`: `LeftDriveEntry` (`left_stance_entry`)<br>`0.135s`: **`TouchL`** (`left_foot_sprint_tap`)<br>`0.360s`: `RightDriveEntry` (`right_stance_entry`)<br>`0.495s`: **`TouchR`** (`right_foot_sprint_tap`)<br>`0.720s`: `RunDribbleLoop` (`loop_seam`) |

### B. Discrete One-Shot Ball-Lock / Directional Cut Clips (`loop = false`, `priority = Action`)
Triggered **once** upon entering diagonal chords (`AW`, `WD`, `AS`, `SD`) or opposite-direction reversal (`W -> S`, not simultaneous `W+S`). Each clip plays to completion (`ClipEnd`) with an explicit `ControlRelease` marker so Controller runtime can hold/queue movement until the cut finishes:

| Clip Name | Motion Library `assetId` | Local Input Mapping (Relative to Facing) | Duration | Keys | Loop | Markers (`time` : `name` / `value`) |
|---|---|---|---|---|---|---|
| `RF02_CutDiagFrontLeft_AW_R15_v01` | `8c17c3a4-a473-4b4d-914c-3662ca946249` | Enter **`AW`** (`+45°` Front-Left diagonal cut; right plant, left foot cut touch) | `0.44s` | `23` (`345` total) | `false` | `0.08s`: `PlantBrake` (`AW_brake_plant`)<br>`0.18s`: **`TouchL`** (`AW_diagonal_cut_touch_left`)<br>`0.36s`: **`ControlRelease`** (`cut_exit_ready`)<br>`0.44s`: `ClipEnd` (`one_shot_complete`) |
| `RF02_CutDiagFrontRight_WD_R15_v01` | `e37739fd-4431-4112-b30e-fe3dbd76d156` | Enter **`WD`** (`-45°` Front-Right diagonal cut; left plant, right foot cut touch) | `0.44s` | `23` (`345` total) | `false` | `0.08s`: `PlantBrake` (`WD_brake_plant`)<br>`0.18s`: **`TouchR`** (`WD_diagonal_cut_touch_right`)<br>`0.36s`: **`ControlRelease`** (`cut_exit_ready`)<br>`0.44s`: `ClipEnd` (`one_shot_complete`) |
| `RF02_CutDiagBackLeft_AS_R15_v01` | `3eb60542-5028-404c-83b5-4d7c125dcbe2` | Enter **`AS`** (`+135°` Back-Left pull-cut; left sole drag + right redirect) | `0.52s` | `27` (`405` total) | `false` | `0.08s`: `PlantBrake` (`AS_brake_entry`)<br>`0.16s`: **`TouchL`** (`AS_sole_lock_drag_left`)<br>`0.30s`: **`TouchR`** (`AS_exit_redirect_right`)<br>`0.44s`: **`ControlRelease`** (`cut_exit_ready`)<br>`0.52s`: `ClipEnd` (`one_shot_complete`) |
| `RF02_CutDiagBackRight_SD_R15_v01` | `8988e5d2-8782-4ba3-8b48-05a8f4ad4abb` | Enter **`SD`** (`-135°` Back-Right pull-cut; right sole drag + left redirect) | `0.52s` | `27` (`405` total) | `false` | `0.08s`: `PlantBrake` (`SD_brake_entry`)<br>`0.16s`: **`TouchR`** (`SD_sole_lock_drag_right`)<br>`0.30s`: **`TouchL`** (`SD_exit_redirect_left`)<br>`0.44s`: **`ControlRelease`** (`cut_exit_ready`)<br>`0.52s`: `ClipEnd` (`one_shot_complete`) |
| `RF02_CutReverse_WS_R15_v01` | `30cbe19c-759c-43bf-810b-bf45d124c4c9` | Opposite-direction reversal **`W -> S`** (`180°` sole lock pull-back hook + inside tap) | `0.56s` | `29` (`435` total) | `false` | `0.08s`: `HardBrake` (`WS_reversal_brake`)<br>`0.16s`: **`TouchR`** (`sole_lock_pullback_right`)<br>`0.36s`: **`TouchL`** (`reverse_control_tap_left`)<br>`0.48s`: **`ControlRelease`** (`cut_exit_ready`)<br>`0.56s`: `ClipEnd` (`one_shot_complete`) |

### C. G-Mode Goal-Facing Slow Close-Control Drafts (`G hold`)
Authored for goal-facing slow close-control (`Shift` does not accelerate, `WASD` goal-relative, chest/head remain squared toward goal):

| Clip Name | Motion Library `assetId` | Input / State Mapping | Duration | Keys | Loop | Markers (`time` : `name` / `value`) |
|---|---|---|---|---|---|---|
| `RF02_GMode_SlowControlLoop_R15_v01` | `039de0b2-5126-43b5-b5a4-9f11286410c7` | `G_HOLD_LOOP` (Low poised goal-facing close-control cycle with alternating sole rolls) | `1.12s` | `33` (`495` total) | `true` | `0.000s`: `GStanceEntry` (`goal_facing_close_control_start`)<br>`0.245s`: **`TouchL`** (`g_mode_sole_roll_left`)<br>`0.560s`: `GMidStance` (`goal_facing_mid_cycle`)<br>`0.805s`: **`TouchR`** (`g_mode_sole_roll_right`)<br>`1.120s`: `GControlLoop` (`loop_seam`) |
| `RF02_GMode_SoleDragBack_WS_R15_v01` | `1829f456-6329-49b0-9e22-a2a8e86f35ea` | `G_HOLD_WS_DRAG` (`W -> S` one-shot sole drag-back while keeping chest/head facing goal) | `0.52s` | `27` (`405` total) | `false` | `0.06s`: `SoleTrapEntry` (`g_mode_sole_reach`)<br>`0.14s`: **`TouchR`** (`g_mode_sole_lock_drag_right`)<br>`0.34s`: **`TouchL`** (`g_mode_cushion_settle_left`)<br>`0.44s`: **`ControlRelease`** (`cut_exit_ready`)<br>`0.52s`: `ClipEnd` (`one_shot_complete`) |

---

## 3. Isolated Workspace Artifact Paths & Quick Preview Commands

- **Generator Script:** `C:\Users\Stang\cage-zero\cage-zero-animation-work\scripts\generate-dribble-clips.mjs`
- **Library Save + Audit + Preview Runner:** `C:\Users\Stang\cage-zero\cage-zero-animation-work\scripts\register-and-audit-clips.mjs`
- **Quick Clip Switcher (for Owner live inspection):** `C:\Users\Stang\cage-zero\cage-zero-animation-work\scripts\preview-clip.mjs`
  - Run any clip on `PreviewRig_R15_Boy_Height30` in Studio:
    - `node scripts/preview-clip.mjs walk 30` (`RF02_WalkDribble_R15_v01`)
    - `node scripts/preview-clip.mjs run 30` (`RF02_RunDribble_R15_v01`)
    - `node scripts/preview-clip.mjs aw 30` (`RF02_CutDiagFrontLeft_AW_R15_v01`)
    - `node scripts/preview-clip.mjs wd 30` (`RF02_CutDiagFrontRight_WD_R15_v01`)
    - `node scripts/preview-clip.mjs as 30` (`RF02_CutDiagBackLeft_AS_R15_v01`)
    - `node scripts/preview-clip.mjs sd 30` (`RF02_CutDiagBackRight_SD_R15_v01`)
    - `node scripts/preview-clip.mjs ws 30` (`RF02_CutReverse_WS_R15_v01`)
    - `node scripts/preview-clip.mjs gloop 30` (`RF02_GMode_SlowControlLoop_R15_v01`)
    - `node scripts/preview-clip.mjs gdrag 30` (`RF02_GMode_SoleDragBack_WS_R15_v01`)
- **Recipe / Asset / Audit Files:**
  - `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\<ClipName>.recipe.json`
  - `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\<ClipName>.asset.json`
  - `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\<ClipName>.audit.json`
  - `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\dribble-preview-evidence.json`

---

## 4. Known Gaps & Non-Executed Actions (By Contract)
1. **No `AnimSaves` / Studio Save Yet:** Per contract (*"Let Owner inspect preview first, no runtime integration/publish/upload/overwrite accepted locomotion/AnimSaves"*), clips are saved in the Motion Tools library and previewed via temporary `MotionPreview_PreviewRig_R15_Boy_Height30` clone only; `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves` has **not** been modified.
2. **Motion Tools GUI `activeRig` Note:** Because `PreviewRig_R15_Boy_Height30` was selected via Studio `Selection` (`snapshot.selection`) rather than clicked inside the Motion Tools plugin window (`snapshot.activeRig`), `motion_studio_inspect` and `motion_studio_preview` work directly on `rigId: d360f7b9-0c8d-4edb-b405-630594559c92`, while `motion_studio_save_animation` (when later authorized after Owner visual pass) requires clicking `PreviewRig_R15_Boy_Height30` once in the Motion Tools Rig Library UI if exporting directly via the plugin.
3. **No Ball Prop in Isolated Rig Preview:** Motion Tools previews the R15 character rig clone only; actual ball rolling, front-lead offset, and cut pause/release coupling are owned by Controller (`w2:p43`) in game runtime.
