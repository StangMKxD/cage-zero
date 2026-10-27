# RF02-LOCOMOTION-AERIAL-DRAFT — R15 Walk, Run, Jump & Land + Accessory Fix Report 001 (For Codex Review)

- **Date:** 2026-10-25
- **Implementer:** Argon (`w2:p48` / `agycageim`)
- **Controller / Reviewer:** Codex (`w2:p43`)
- **Authorization & Owner Directives (Chronological):**
  1. `ทำ animation เดิน กับ วิ่ง ต่อหน่อย`
  2. `ระบบกล้องผ่านแล้ว ผมเช็คเอง นายทำมาเลยแล้วรายงาน spec ขอบเขตให้ codex ตรวจทีหลังอีกที ตอนนี้ codex limit อยู่`
  3. `ท่าเดินขอให้ smooth ขึ้นอีก มันยังดูกระตุก เพิ่ม frame เข้าไป`
  4. `ท่าวิ่งให้ก้าวขาไกลกว่านี้หน่อย ที่นายทำมันเหมือนท่าวิ่ง roblox ปกติ`
  5. `และทำท่ากระโดด ลงพื้น ไว้รอได้เลย`
  6. `ขยับลำตัวเหมือนเดิม แต่ไม่ไปแนวตรงข้ามกับต้นขา ... ลองปรับตามแบบนี้ [ตาราง 9 เฟส R15]`
  7. `ปรับให้เวลาเพิ่มขึ้นมันเร็วไปเยอะเลยอะ เอาที่เหมาะสม ตอนเตรียมให้งอแขนขึ้นนิดนึงเหมือนง้างจะกระโดด ตอนกระโดดขึ้นกางแขนแต่เอาลงนิดนึง`
  8. `เข่างอไปข้างหลังเยอะกว่านี้ ลำตัวกดไปข้างหน้านิดนึง`
  9. `ให้ต้นขา ยกขึ้นสูงหน่อย`
  10. `แล้วทำไมหมวก ที่ตัวละครผมสวมอยู่มันไม่ตามหัวอะ มันไม่ขยับตาม ทุก animation เลย`
  11. `โอเคแล้วพักได้ เขียนเอกสารรายงานรอ codex รีวิว`
- **State:** `OWNER_APPROVED_SAVED_TO_ANIMSAVES_AWAITING_CODEX_REVIEW`
- **Studio Lock Status:** `STUDIO_RELEASED` (Background Motion Tools daemon `task-147` stopped cleanly after saving all 4 `KeyframeSequence`s to `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves`).

---

## 1. Bounded Scope & Disjoint Ownership Spec (For Codex Review)

1. **Zero Project Source / Runtime Mutation:**
   - No files under `src/`, `default.project.json`, or shared plan/tasks files were modified.
   - No live player `R15AnimationController` runtime wiring or Roblox cloud asset upload (`rbxassetid://`) was performed.
   - No Git commit or push was executed.
2. **Preserved Approved Idle Clip (`review-023.md` Compliance):**
   - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/idle-r15/RF02_Idle_Ready_R15_v01.recipe.json` (`SHA-256: 37EA4E018E18699FEEA9DE74528DC804983C35EC960CB8CAADE2932A8EA0F607`)
   - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/idle-r15/RF02_Idle_Ready_R15_v01.audit.json` (`SHA-256: 3DA389FC2C1E7625FEF250C3242F7A44C31B8A8A2A5DBBF2EBED73E586C318FF`)
   - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/idle-r15/PreviewRig_R15_Boy_Height30.backup.json` (`SHA-256: 853886D324F38BA656E38DCF03B63AF51C26B4C98FFCD19B5D4A3059C7A0BF2E`)
   - `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves.RF02_Idle_Ready_R15_v01` (`KeyframeSequence`, `9` keyframes, `Loop = true`, `Priority = Enum.AnimationPriority.Idle`) remains 100% intact.
3. **Owned New Artifact Paths & SHA-256 Hashes:**
   - **Walk (`walk-r15`):**
     - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/walk-r15/RF02_Walk_Ready_R15_v01.recipe.json`
       - SHA-256: `568302207A866BE9A6683576DEFB4E3383C56CA105389373E288E7628DF52C8C`
     - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/walk-r15/RF02_Walk_Ready_R15_v01.audit.json`
       - SHA-256: `9CBC2C75443F7BE8E64C94121553DD34C79B032BC857D3DC134B680FD8E53484`
   - **Run (`run-r15`):**
     - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/run-r15/RF02_Run_Ready_R15_v01.recipe.json`
       - SHA-256: `9C680CFBA370C0FF4D211C05941C8E804FFC4E4B5973268569836023EA3B585E`
     - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/run-r15/RF02_Run_Ready_R15_v01.audit.json`
       - SHA-256: `2787E269EAE05790E4484905AB6CED45F38D4F93FC9BDF8CFBBA8CE58D0F522C`
   - **Jump (`jump-r15`):**
     - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/jump-r15/RF02_Jump_Ready_R15_v01.recipe.json`
       - SHA-256: `B31A523723EBD482649F6D75F5814F0C1C79CFF835954BEB214A4884EDC21005`
     - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/jump-r15/RF02_Jump_Ready_R15_v01.audit.json`
       - SHA-256: `71507B3C64A1DD17BCCC2972EB286B4AC3D2264FBCDFDC2A4C66E064632E521E`
   - **Land (`land-r15`):**
     - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/land-r15/RF02_Land_Ready_R15_v01.recipe.json`
       - SHA-256: `777435C879253D945D252261B12DD41D29447AAC8D369EEE6017B55C782BDC49`
     - `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/land-r15/RF02_Land_Ready_R15_v01.audit.json`
       - SHA-256: `385779D5FEDABD724EDA11424C5E0ECDC205E42DCE39B19585E0B4CEC8058173`
   - **Report:**
     - `docs/plan/phase-01-gameplay-demo/release-first/assets/walk-run-motion-report-001.md`

---

## 2. Animation Specifications, Fingerprints & `AnimSaves` Persistence

All 4 new clips were authored across all 15 R15 joints (`LowerTorso`, `UpperTorso`, `Head`, `LeftUpperArm`, `LeftLowerArm`, `LeftHand`, `RightUpperArm`, `RightLowerArm`, `RightHand`, `LeftUpperLeg`, `LeftLowerLeg`, `LeftFoot`, `RightUpperLeg`, `RightLowerLeg`, `RightFoot` — `100%` rig coverage, `5/5` semantic roles), audited at `60Hz`, validated with `motion_studio_validate_animation_export`, approved by Owner Stang, and saved to `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves` via `motion_studio_save_animation`.

### A. Walk — `RF02_Walk_Ready_R15_v01`
- **Motion Library Asset UUID (local only):** `b22ee64a-e476-4ca5-a664-26c53a968c90`
- **Duration / Density:** `1.12s`, `33` keyframes (`0.035s` step, `495` keys, `528` poses)
- **Loop / Priority:** `loop: true`, `priority: "Movement"` (`Enum.AnimationPriority.Movement`)
- **Curve Formulation:** Continuous $C^\infty$ 2-harmonic gait curves sampled at 32 sub-steps with `Linear` segment interpolation (eliminating piecewise `CubicV2 InOut` zero-velocity pauses) and exact `t=0` / `t=1.12s` loop closure.
- **Fingerprints & Saved `KeyframeSequence`:**
  - `assetFingerprint`: `c6f945e2b8e70bb69a88a9320d67b7796676cf49777c5f8abe7b5bb98b875877`
  - `preflightFingerprint`: `b1626ec9a97729385005a1f220e41b19466a40f4b24566e16257ad0b8ebe1e43`
  - `AnimSaves` Path: `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves.RF02_Walk_Ready_R15_v01` (`33` keyframes)

### B. Long-Stride Run — `RF02_Run_Ready_R15_v01`
- **Motion Library Asset UUID (local only):** `03fd7618-789a-4e40-b47e-e492fb0587bb`
- **Duration / Density:** `0.76s`, `33` keyframes (`0.02375s` step, `495` keys, `528` poses)
- **Loop / Priority:** `loop: true`, `priority: "Movement"` (`Enum.AnimationPriority.Movement`)
- **Curve Formulation:** High-extension athletic sprint stride (`105°` hip scissor split from `+57.4°` front reach to `-52.0°` rear drive, `-10°` front shin whip extension, `-8°` rear push-off extension, `-99°` heel-to-butt recovery fold, and `LowerTorso` flight-phase vertical bounce `+0.17` to `-0.14` studs).
- **Fingerprints & Saved `KeyframeSequence`:**
  - `assetFingerprint`: `95337270a9973aed024e2b4bcd3819dad73609d29cfab5d0573a274558659abe`
  - `preflightFingerprint`: `6cc633d7e3e83265306296660c695cf4a26a950918893f5a42cb327218b4c4ab`
  - `AnimSaves` Path: `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves.RF02_Run_Ready_R15_v01` (`33` keyframes)

### C. Jump — `RF02_Jump_Ready_R15_v01`
- **Motion Library Asset UUID (local only):** `d7083e55-bb83-46c4-9c18-04d21e8a9428`
- **Duration / Density:** `1.80s`, `49` keyframes (`0.0375s` step, `735` keys, `784` poses)
- **Loop / Priority:** `loop: false`, `priority: "Action"` (`Enum.AnimationPriority.Action`)
- **Curve Formulation:** 9-phase R15 jump table evaluated via Fritsch-Carlson Monotone Cubic Hermite Spline (zero overshoot between phases):
  - **Timing (`0.00s..1.80s`):** Stand ready (`0.00s`), start dip (`0.18s`), max dip (`0.36s`), push-off (`0.56s`), rising (`0.85s`), apex (`1.08s`), descent (`1.38s`), touchdown cushion (`1.56s`), recover to stand (`1.80s`).
  - **Arm Windup & Lowered Mid-Air Spread:** Elbows bend upward during dip (`Left/RightLowerArm rx: +55°` at `0.36s`) with shoulders swung back (`rx: -20°`), then spread symmetrically outward/forward-diagonal at a moderate height (`Left/RightUpperArm rz: ∓38°, rx: +15°, ry: ∓10°`, `Left/RightLowerArm rx: +20°`) at apex (`1.08s`).
  - **Forward Torso Lean:** `LowerTorso` (`rx: -2°..-8°`) and `UpperTorso` (`rx: -2.5°..-13°` at dip, `-7°..-8.5°` airborne, `-12°` at touchdown) maintain a forward athletic lean throughout (never tilting backward against the thighs), with `Head` (`rx: +4°..+18°`) keeping gaze level.
  - **Higher Thigh Lift & Deeper Backward Knee Bend:** `Left/RightUpperLeg` lift symmetrically to `+28° -> +35°` in mid-air (`0.85s -> 1.08s`) while `Left/RightLowerLeg` bend deeply backward (`-45°` at dip, `-50° -> -65°` airborne, `-42°` touchdown cushion).
- **Fingerprints & Saved `KeyframeSequence`:**
  - `assetFingerprint`: `910d427991eb39e9d0ad55d43c5327577ba603afb802d62ef0a1652a10a707fa`
  - `preflightFingerprint`: `695540f6116deff90df0119b5fbab865a58779acdc509a59d1fb014d3d018555`
  - `AnimSaves` Path: `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves.RF02_Jump_Ready_R15_v01` (`49` keyframes)

### D. Land — `RF02_Land_Ready_R15_v01`
- **Motion Library Asset UUID (local only):** `ba62c33d-7e11-4954-b6f3-04ac1b776cab`
- **Duration / Density:** `0.84s`, `29` keyframes (`0.03s` step, `435` keys, `464` poses)
- **Loop / Priority:** `loop: false`, `priority: "Action"` (`Enum.AnimationPriority.Action`)
- **Curve Formulation:** Symmetrical impact absorption (`Left/RightLowerLeg rx: -42°`, `Left/RightUpperLeg rx: +22°`, `LowerTorso ty: -0.32`, forward torso lean `UpperTorso rx: -12°`) recovering smoothly to standing pose at `0.84s`.
- **Fingerprints & Saved `KeyframeSequence`:**
  - `assetFingerprint`: `d641cb997508ca5b3999cd24d205479179014d73b40186d632a9dd0b880b9d1b`
  - `preflightFingerprint`: `59fd95cd7c0164ecc80f53349b01e49de590036fb3f78197cff856213828fd6c`
  - `AnimSaves` Path: `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves.RF02_Land_Ready_R15_v01` (`29` keyframes)

---

## 3. Accessory (`Traditional Chinese Hat`) Diagnosis & Fix

### Root Cause
1. **Motion Tools Viewport (`MotionEditorRig`):** In `C:\Users\Stang\AppData\Local\Roblox\Plugins\RobloxMotion.plugin.lua`, the dock widget's `showPose(time)` evaluated `Authoring.apply(nodes, tracks, ...)` on `viewportClone` (`PluginGuiService.PluginGui.Workspace.Editor.RigViewport.PreviewWorld.MotionEditorRig`), where all parts are `Anchored = true`. Because `Authoring.apply` only updated `Motor6D`/`AnimationConstraint` joints (`Head`, `UpperTorso`, etc.) without updating `Accessory` handles via their matching `Attachment`s (`HatAttachment`), the hat remained frozen at its initial `CFrame` across all animations.
2. **Workspace Preview Rig (`PreviewRig_R15_Boy_Height30`):** `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30["Traditional Chinese Hat"].Handle` had `HatAttachment` matching `Head.HatAttachment`, but lacked an `AccessoryWeld` instance.

### Applied Fix (Outside `cage-zero` Repository Scope)
1. **Workspace Rig `AccessoryWeld`:** Created `AccessoryWeld` (`Part0 = Handle`, `Part1 = Head`, `C0 = Handle.HatAttachment.CFrame`, `C1 = Head.HatAttachment.CFrame`) on `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30["Traditional Chinese Hat"].Handle`.
2. **Motion Tools Plugin & Live Session Sync:**
   - Bound `RunService.RenderStepped` and `RunService.Heartbeat` in the active Studio Edit session to align any `Accessory.Handle` in `PreviewWorld` models to `part.CFrame * bodyAtt.CFrame * hatAtt.CFrame:Inverse()`.
   - Patched `Authoring.apply` in `C:\Users\Stang\AppData\Local\Roblox\Plugins\RobloxMotion.plugin.lua` (lines `705–723`) so future Studio sessions automatically keep `Accessory` handles locked to their parent body attachment during viewport scrubbing and playback.

---

## 4. Verification Summary (`AnimSaves` Snapshot on `PreviewRig_R15_Boy_Height30`)

| Name | ClassName | Keyframes | Loop | Priority |
|---|---|---:|---|---|
| `RF02_Idle_Ready_R15_v01` | `KeyframeSequence` | `9` | `true` | `Enum.AnimationPriority.Idle` |
| `RF02_Walk_Ready_R15_v01` | `KeyframeSequence` | `33` | `true` | `Enum.AnimationPriority.Movement` |
| `RF02_Run_Ready_R15_v01` | `KeyframeSequence` | `33` | `true` | `Enum.AnimationPriority.Movement` |
| `RF02_Jump_Ready_R15_v01` | `KeyframeSequence` | `49` | `false` | `Enum.AnimationPriority.Action` |
| `RF02_Land_Ready_R15_v01` | `KeyframeSequence` | `29` | `false` | `Enum.AnimationPriority.Action` |
