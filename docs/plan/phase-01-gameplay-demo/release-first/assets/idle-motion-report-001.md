# Idle Motion Preview Report — `RF02-IDLE-DRAFT` (`idle-motion-report-001`)

- **Status:** `READY_FOR_OWNER_IDLE_REVIEW` (Owner Visual Review: **PASSED / `"ผ่านแล้ว"`**)
- **Task ID:** `RF02-IDLE-DRAFT`
- **Owner / Implementer:** `agycageim/4Argon` (`w2:p48`)
- **Verified Parent Refs:**
  - Camera-Normal Baseline Commit: `9fbce58eb90ed6b7e6a39b00a5744455ee639811`
  - Foundation Commit: `5ccb53d69568144c4b43458e84d06029d7937557`
  - Source Hashes Preserved (Untouched):
    - `src/shared/configs/R15AvatarConfigs.luau`: `6b773271d3e91287509165e98a029a90ae4c9d91a4e3d68bf0fe731626c37dda`
    - `src/server/services/R15AvatarService.luau`: `7491847869063ad2de7b51f549f9fb089efccd0a0424f7bec7f31abdb43a8640`

---

## 1. Studio & Motion Tools Connection Verification

| Check | Result | Evidence |
| :--- | :--- | :--- |
| **Roblox Studio Instance** | Verified (`Edit` mode) | `studio_id: ab5aa575-5e53-41b6-b1ab-e2c8bc7c29c0`, `place_name: Cage-Zero`, `place_id: 137721422246269`, `datamodel_type: Edit` |
| **Motion Tools Bridge Server** | Online (`127.0.0.1:17331`) | Local daemon `C:/Users/Stang/AI-Tools/run-animation-session.mjs` connected to `motion-tools/dist/src/index.js` |
| **Motion Tools Studio Session** | Online (`motion_studio_sessions`) | `sessionId: 656c65ba-1394-4531-aa18-296a01604414`, `online: true`, `place: "Cage-Zero"`, `placeId: 137721422246269`, `pluginVersion: "1.0.0"` (GC-pinned via `_G.__MotionToolsKeepAlive` + installed at `%LOCALAPPDATA%\Roblox\Plugins\RobloxMotion.plugin.lua`) |
| **Rig Inspection (`motion_studio_inspect`)** | Succeeded (`15/15` joints) | `rigId: 0022e8ae-5010-4dab-a526-e522575a8cdc`, `rigName: "PreviewRig_R15_Boy_Height30"`, `rigType: "R15"`, 15 `AnimationConstraint` joints |
| **Library Save (`motion_library_save`)** | Succeeded | `assetId: b8e4f7b0-b0fe-4cd6-96d7-33947eda2a87`, `assetFingerprint: 6c7804c4a037537c54f34839b1e9a2d09250a90a972650662e795ee3178b3057` (`RF02_Idle_Ready_R15_v01`, sole clip in clean Motion Tools library) |
| **Export Preflight (`motion_studio_validate_animation_export`)** | Valid (`valid: true`) | `format: "KeyframeSequence"`, `frameCount: 9`, `poseCount: 144`, `markerCount: 5`, `animatedTrackCount: 15`, all 15 R15 joints mapped (`preflightFingerprint: dc19e8ac80a6816e6fb6281b09e1624ea06f894d491e8eb337309d6a8ad1f041`) |
| **Studio Save (`motion_studio_save_animation`)** | Succeeded (Post-Owner Approval) | Saved native `KeyframeSequence` at `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves.RF02_Idle_Ready_R15_v01` |
| **Owner Visual Preview & Sign-Off** | Passed (`"ผ่านแล้ว"`) | Owner reviewed live in **Motion Tools Animation Studio** (`viewportOpen: true`) and approved the akimbo + slow left-right look + smooth playful foot tap idle |

---

## 2. Target Preview Rig & Backup Verification

- **Preview Rig Path:** `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30`
- **Pre-Mutation Backup Path:** [`PreviewRig_R15_Boy_Height30.backup.json`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/animations/idle-r15/PreviewRig_R15_Boy_Height30.backup.json)
- **Verified Rig Identity & Proportions:**
  - `RigType`: `Enum.HumanoidRigType.R15` (ROBLOX Boy MeshParts + 15 `AnimationConstraint` joints + `Animator`)
  - `HumanoidRootPart.Position`: `(0, 4.183, 45)` (`Anchored = true`)
  - `Measured Rest Extents`: Height `6.7110` studs (target `~6.708` studs, `+30%` over `5.16` baseline), Width `3.4592` studs, Depth `1.3659` studs
  - `Humanoid.HipHeight`: `2.792` studs
  - `HeadScale`: `1.0` (proportional head preserved)
  - `Accessory`: `Traditional Chinese Hat` (`Accessory`) preserved and synced to `Head`
  - `Ball Parity Reference`: `2.25` studs diameter (`R15AvatarConfigs.BALL.Diameter = 2.25`, untouched)

---

## 3. Authored R15 Idle Clip Specification & Audit Summary

- **Clip Name:** `RF02_Idle_Ready_R15_v01`
- **Recipe Path:** [`RF02_Idle_Ready_R15_v01.recipe.json`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/animations/idle-r15/RF02_Idle_Ready_R15_v01.recipe.json)
- **Audit Evidence Path:** [`RF02_Idle_Ready_R15_v01.audit.json`](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/release-first/assets/animations/idle-r15/RF02_Idle_Ready_R15_v01.audit.json)
- **Local Studio Sequence Path:** `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves.RF02_Idle_Ready_R15_v01` (`KeyframeSequence`)
- **Clip Parameters:**
  - `Duration`: `4.8s` (9 keyframe phases at `0.0s, 0.6s, 1.2s, 1.8s, 2.4s, 3.0s, 3.6s, 4.2s, 4.8s` with `CubicV2` / `InOut` easing across all 135 keys)
  - `Loop`: `true` (exact `t = 0.0s` and `t = 4.8s` pose identity across all 15 joints; `0.0000` loop seam discontinuity)
  - `Priority`: `Idle` (`Enum.AnimationPriority.Idle`)
  - `Root Motion`: None (`rootMotionTracks = 0`; `HumanoidRootPart` stays fixed; `LowerTorso` uses only subtle vertical/lateral weight shift `<= 0.055` studs)
  - `Driven Joint Coverage`: `15 / 15` directly animatable R15 joints (`LowerTorso`, `UpperTorso`, `Head`, `LeftUpperArm`, `LeftLowerArm`, `LeftHand`, `RightUpperArm`, `RightLowerArm`, `RightHand`, `LeftUpperLeg`, `LeftLowerLeg`, `LeftFoot`, `RightUpperLeg`, `RightLowerLeg`, `RightFoot`)
  - `Support Contacts`: `LeftFoot` (`0.0..4.8s` support) and `RightFoot` (`0.0..1.8s` and `4.2..4.8s` support, with playful light foot tap/kick at `2.4s..3.6s`)
  - `Motion Character`: Hands-on-hips (akimbo / เท้าเอว) football stance (`LeftHand` and `RightHand` resting at waist `X ≈ ±0.89, Y ≈ 3.39` with elbows flared `X ≈ ±1.63`), slow smooth left-to-right head and chest scan (`+21°` left at `1.2s` -> `-18.5°` right at `2.4s`), and a smooth weight shift onto the planted left leg with a light, playful right-foot kick/tap (`3.0s` apex, `3.6s` soft recoil, `4.2s..4.8s` smooth return to stance).

---

## 4. Legacy Library Independence Confirmation (`review-021`)

- **Zero Legacy Library Dependency:** Motion Tools is **NOT** loading, reading, or depending on `docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/animation-library.json` or `docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/delta-agycage.json`.
- **Clean Runtime Library:** All 54 legacy R6 / Plan 02–03 clips were removed from `C:/Users/Stang/AI-Tools/motion-tools/artifacts/library/`, leaving only the independent R15 clip `RF02_Idle_Ready_R15_v01` (`b8e4f7b0-b0fe-4cd6-96d7-33947eda2a87.json`).
- **Studio Ownership Released (`STUDIO_RELEASED`):** Studio (`Cage-Zero`, `137721422246269`, `Edit` mode) is released for Flash (`w2:p49`) and Codex (`w2:p43`). `docs/plan/phase-01-gameplay-demo/release-first/assets/animations/idle-r15/` and `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30` remain protected.
