# RF02-DRIBBLE-ANIMATION — Preparation Readiness Note

- **Timestamp:** 2026-10-27T21:59+07:00
- **Task ID:** `RF02-DRIBBLE-ANIMATION`
- **Role / Session:** `implementer (ANIMATION ONLY)` (`w2:p52`, Model: Gemini 4 Argon (Medium))
- **Report To:** Controller (`w2:p43`)
- **Isolated Workspace:** `C:\Users\Stang\cage-zero\cage-zero-animation-work`
- **Main Project (`C:\Users\Stang\cage-zero`):** Strictly READ-ONLY (0 mutations, 0 Git operations)

## 1. Scope & Grill Status (Owner Q1–Q3 Confirmed, Q4–Q6 Pending)
- **Confirmed Base Scope (Q1–Q3):**
  - Author **2 base循环/locomotion dribble clips** only: `WALK_DRIBBLE` and `RUN_DRIBBLE`.
  - **Preview-first workflow** on the dedicated R15 preview rig before any runtime integration.
  - Ball movement visibly responds to WASD (exact lateral pattern pending **Q4**).
  - Rolling, close-control, collision, and runtime physics/wiring belong exclusively to Controller (`Codex`).
  - Cling / close-control animations belong to **FUTURE G mode** (goal-facing, slow movement) — **excluded** from current clip scope.
- **Pending Grill (Q4–Q6):** Do **NOT** author, import, overwrite, or preview clips until Q4–Q6 are answered and the actionable authoring contract is dispatched.

## 2. Live Persistent Motion Bridge & Session Inspection (Read-Only)
- **Wrapper Metadata (`C:\Users\Stang\AI-Tools\motion-tools\.local\animation-rpc.json`):**
  - Recorded `rpcPort`: `56595`
  - Recorded `rpcPid`: `23540` (matches `C:\Users\Stang\AI-Tools\output\motion-persistent.pid`, last written `2026-10-26T13:50:58Z`)
  - Credentials/tokens: omitted (never printed).
- **Local Motion Bridge Metadata (`C:\Users\Stang\AI-Tools\motion-tools\.local\connection.json`):**
  - Recorded `bridgePort`: `17331`
  - Credentials/tokens: omitted (never printed).
- **Live Process & Socket Check (2026-10-27T21:57+07:00):**
  - `RobloxStudioBeta.exe` is running (`PID 4468`).
  - Persistent bridge process `PID 23540` (`run-animation-session.mjs`) is **NOT currently running** (`Get-Process -Id 23540` absent), and neither `127.0.0.1:56595` (`/tool`) nor `127.0.0.1:17331` (`/health`) is listening (`ECONNREFUSED`).
  - **Compliance:** Per contract instruction (*"Do not start duplicate bridge, restart/stop it"*), no bridge process was started or restarted.
  - **Action Needed Before Authoring/Preview:** Controller (`w2:p43`) or Owner needs to restore/start the single persistent `C:\Users\Stang\AI-Tools\run-animation-session.mjs` bridge process (or authorize this pane to start it once) so `127.0.0.1:<rpcPort>/tool` and `127.0.0.1:17331` come back online.

## 3. Target R15 Preview Rig Identity (Read-Only Verified)
- **Place Identity:** `Cage-Zero` (`PlaceId: 137721422246269`)
- **Studio Preview Rig Path:** `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30`
- **Motion Tools Rig Name:** `PreviewRig_R15_Boy_Height30`
- **Last Recorded Motion `sessionId` / `rigId` (`motion-live-verification.json`):**
  - `sessionId`: `bddb7b8a-3f31-4eac-a36b-9c42e0ef0325` (will refresh via `motion_studio_sessions` once bridge is online)
  - `rigId`: `e7b49964-475d-4246-b724-7343bf0e231e`
- **Rig Dimensions & Attributes (`PreviewRig_R15_Boy_Height30.backup.json`):**
  - `RigType`: `R15`, `BodyPackage`: `ROBLOX Boy`, `HeightScale`: `1.391`, `HipHeight`: `2.792`, `TargetBodyHeight`: `6.708` studs, `hrpPosition`: `[0, 4.183, 45]`
  - **15 Driven `AnimationConstraint` Joints:**
    `LowerTorso` (`Root`), `UpperTorso` (`Waist`), `Head` (`Neck`),
    `LeftUpperArm` (`LeftShoulder`), `LeftLowerArm` (`LeftElbow`), `LeftHand` (`LeftWrist`),
    `RightUpperArm` (`RightShoulder`), `RightLowerArm` (`RightElbow`), `RightHand` (`RightWrist`),
    `LeftUpperLeg` (`LeftHip`), `LeftLowerLeg` (`LeftKnee`), `LeftFoot` (`LeftAnkle`),
    `RightUpperLeg` (`RightHip`), `RightLowerLeg` (`RightKnee`), `RightFoot` (`RightAnkle`).
- **Existing Protected Locomotion Baseline Clips (`AnimSaves` & `motion-tools/artifacts/library/`):**
  - `RF02_Idle_Ready_R15_v01` (`b8e4f7b0-b0fe-4cd6-96d7-33947eda2a87`, `4.80s`, `Idle`, `loop=true`)
  - `RF02_Walk_Ready_R15_v01` (`b22ee64a-e476-4ca5-a664-26c53a968c90`, `1.12s`, `Movement`, `loop=true`, 33 keyframes)
  - `RF02_Run_Ready_R15_v01` (`03fd7618-789a-4e40-b47e-e492fb0587bb`, `0.76s`, `Movement`, `loop=true`, 33 keyframes)
  - `RF02_Jump_Ready_R15_v01` (`d7083e55-bb83-46c4-9c18-04d21e8a9428`, `1.80s`, `Action`, `loop=false`)
  - `RF02_Land_Ready_R15_v01` (`ba62c33d-7e11-4954-b6f3-04ac1b776cab`, `0.84s`, `Action`, `loop=false`)
  - *(All 5 existing clips and `AnimSaves` are strictly read-only / protected).*

## 4. Exact Preview-Only Artifact Paths for Later Authoring
All new draft recipes, audits, and preview evidence for `WALK_DRIBBLE` and `RUN_DRIBBLE` will be written exclusively inside the isolated workspace (`C:\Users\Stang\cage-zero\cage-zero-animation-work\`) unless the final authoring contract specifies additional paths:
1. **Walk Dribble Draft Recipe:** `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\RF02_WalkDribble_R15_v01.recipe.json`
2. **Walk Dribble Asset Metadata:** `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\RF02_WalkDribble_R15_v01.asset.json`
3. **Walk Dribble Audit Output:** `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\RF02_WalkDribble_R15_v01.audit.json`
4. **Run Dribble Draft Recipe:** `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\RF02_RunDribble_R15_v01.recipe.json`
5. **Run Dribble Asset Metadata:** `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\RF02_RunDribble_R15_v01.asset.json`
6. **Run Dribble Audit Output:** `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\RF02_RunDribble_R15_v01.audit.json`
7. **Preview Verification Evidence:** `C:\Users\Stang\cage-zero\cage-zero-animation-work\artifacts\dribble-preview-evidence.json`
8. **Motion Library Store (Managed by Motion Tools MCP on `motion_library_save`):** `C:\Users\Stang\AI-Tools\motion-tools\artifacts\library\<new-uuid>.json` (new clip IDs only; never overwriting the 5 existing UUIDs; no `motion_studio_save_animation` to `AnimSaves` until explicitly instructed).
