# Original User Request

## Initial Request — 2026-10-20T16:13:25Z

Use a full multi-agent team (spawn subagents: sentinel, worker_impl, victory_auditor/reviewer) to implement and verify Plan `01-cage-physics` (3D Cage Variants A/B/C, Swept-Sphere Collision Solver, 5 Base Rebound Mechanics, and Module 00 R6 Floor Seam) for Cage Zero in Roblox Studio (`Place4` / PlaceId `137721422246269`) strictly according to the locked `HANDOFF.md` contract.

Working directory: C:\Users\Stang\cage-zero
Integrity mode: development

Reference material:
- `C:\Users\Stang\cage-zero\agent.md`
- `C:\Users\Stang\cage-zero\docs\READ.md`
- `C:\Users\Stang\cage-zero\docs\plan\phase-01-gameplay-demo\01-cage-physics\plan.md`
- `C:\Users\Stang\cage-zero\docs\plan\phase-01-gameplay-demo\01-cage-physics\tasks.md`
- `C:\Users\Stang\cage-zero\docs\plan\phase-01-gameplay-demo\01-cage-physics\assets\HANDOFF.md`

## Requirements

### R1. Scope Lock, Plan 00 Preservation & Typed Rollback Bundle (`sentinel`)
Keep Plan `00-bootstrap-and-rig` status as `OPEN / PAUSED_BY_OWNER` without closing Plan 00 or altering its R6 runtime contract (`ServerStorage.CageZeroStandardR6Rig`, `HumanoidRootPart`, `RigAndCardService`, `R6AnimationController`, `Network.Init`). Verify `.sandbox/rollback/run-phase01-cage-physics-01/` (note: if `pre/` already contains the authentic pre-modification baseline at commit `65026668fcae9d80094841bb147f3f4dc64b0b6c` before `CagePhysicsService` was synced, preserve `pre/` intact so the true pre-baseline is not overwritten by post-run state) and ensure both Pre-Baseline and Post-Baseline Snapshots in `.sandbox/rollback/run-phase01-cage-physics-01/` have `0` nulls and explicit separation of `WorldPivot` vs `GetPivot`, complete with `manifest.json`, `restore.ps1`, and `verify-rollback.ps1`. Do not touch the reference sandbox (`112091950831355`), `.gitignore`, or out-of-scope modules (`02`–`08` / Phase 2), and do not run git commit, push, merge, or deploy.

### R2. 3D Cage Variants A/B/C & Swept-Sphere Collision Solver (`worker_impl` — T-01, T-02)
Modify only the authorized source allowlist (`src/shared/Constants.luau`, `src/shared/Types.luau`, `src/server/services/CagePhysicsService.luau`, `src/server/init.server.luau`). Implement a single unified `ArenaGeometry` catalog and `BuildCageArena(parent?, variantId?)` supporting Variant `A` (4-wall orthogonal box + flat ceiling at `Y = 32`), Variant `B` (4-corner `20`-stud chamfer = 8 walls + flat ceiling), and Variant `C` (8-wall base + `45°` beveled roof `8` studs from `Y = 24` to `Y = 32` with no overlapping full flat ceiling underneath the bevel). Implement `StepBallCageCollision` as a swept-sphere collision solver (`BALL_RADIUS = 1.25`, multi-contact step budget `MAX_COLLISION_SUBSTEPS = 4`, finite surface bounds) using the exact same `ArenaGeometry` catalog.

### R3. 5 Base Rebound Mechanics & Controlled A/B/C Test Probe (`worker_impl` — T-03, T-04)
Implement the 5 base rebound mechanics with independent feature flags: (1) Ceiling Lob & Smash (`e = 0.88`) with guide-only `CeilingReboundMarker_North`/`South` (`CanCollide = false`, `CanQuery = false`, zero aim-assist/velocity pull), (2) Over-Goal Transom rebound (`Goal_North`/`South` at `Z = ±106`, width `24`, height `10`, depth `6`, with transom rebound above the crossbar at `e = 0.95`), (3) 4 Corner Pinball Bumpers (`e = 1.25`, capped by `MAX_REBOUND_SPEED = 180.0`), (4) Side Elevating Ramps `25°` (`Ramp_West`/`East` at `X ≈ ±74`, `Z ∈ [-30, +30]`) using true 3D Oriented Bounding Box (OBB) detection in `IsPositionOnElevatingRamp(position)` and `ApplyRampImpulse(velocity, isOnRamp)`, and (5) `14-Stud` Back-Goal Alley (`Z = ±106` to `Z = ±120` unobstructed). Provide `SimulateBallTrajectory` / `RunVariantComparisonSuite` to run controlled Shape Pass and Mechanics Pass comparisons across Variants `A`, `B`, and `C` without activating `BallService` or `MatchService`.

### R4. Bootstrap Chaining, Floor Seam & Studio Verification (`worker_impl` & `victory_auditor` — T-05, T-98, T-99)
Chain `src/server/init.server.luau` in exact order: `Network.Init(10.0)` -> `CagePhysicsService.Init()` -> `RigAndCardService.Init()`, point `PRIMARY_FLOOR_PATH = "HexCageArena.CageFloor"` and `PRIMARY_SPAWN_PATH = "HexCageArena.CageSpawnLocation"`, and retire temporary `BootstrapTestFloor` / `BootstrapSpawnLocation` fixtures only once `HexCageArena.CageFloor` is active while keeping `Workspace.Baseplate` intact. Sync all allowlisted scripts to Roblox Studio (`Place4` / `137721422246269`), verify 100% SHA-256 readback match, execute live verification (`V-01`–`V-07`), and record the measured A/B/C comparison matrix in `docs/plan/phase-01-gameplay-demo/01-cage-physics/assets/`.

## Verification Resources

- Locked contract and acceptance gates: `C:\Users\Stang\cage-zero\docs\plan\phase-01-gameplay-demo\01-cage-physics\assets\HANDOFF.md` (`V-01` through `V-07`)
- Target Roblox Studio instance: `Place4` (`PlaceId = 137721422246269`) via `Roblox_Studio` MCP tools (`list_roblox_studios`, `get_studio_state`, `execute_luau`, `start_stop_play`, `get_console_output`)
- Existing rollback format reference: `C:\Users\Stang\cage-zero\.sandbox\rollback\`

## Acceptance Criteria

### V-01 — Source Sync & 3D Variant Builder (`A`, `B`, `C`)
- [ ] All files in `src/` match Studio Script/ModuleScript readback 100% by SHA-256 hash.
- [ ] `BuildCageArena` builds `Workspace.HexCageArena` for Variants `A` (4 walls), `B` (8 walls + flat ceiling), and `C` (8 walls + `45°` beveled roof with no flat ceiling overlap under the bevel), including `CageFloor`, `CageSpawnLocation`, goals, transoms, corner bumpers, `25°` side ramps, and non-collidable ceiling guide markers matching the solver catalog.

### V-02 — Bootstrap Order & R6 Floor Seam
- [ ] `ServerScriptService.Server` initializes `Network.Init(10.0)` -> `CagePhysicsService.Init()` -> `RigAndCardService.Init()` with zero errors.
- [ ] `BootstrapTestFloor` and `BootstrapSpawnLocation` are retired while `Workspace.Baseplate` remains intact.
- [ ] In Play Solo runtime, the Single Standard Custom R6 rig spawns on `Workspace.HexCageArena.CageFloor` and can walk, jump, ascend the `25°` ramp, and traverse the `14-stud` back-goal alley.

### V-03 — Swept-Sphere Collision & Seam Coverage
- [ ] High-speed ball trajectories (`60–180` studs/s, `BALL_RADIUS = 1.25`) reflect accurately off straight walls, `45°` chamfered corners, flat ceiling, and Variant `C` `45°` roof bevel seams with `0` tunneling/escapes and `0` corner-stuck states across the declared test suite.

### V-04 — 5 Base Rebound Mechanics
- [ ] (1) Ceiling rebound (`e = 0.88`) works and `CeilingReboundMarker` has zero velocity/trajectory pull (`0` delta between marker-enabled and marker-disabled trajectories).
- [ ] (2) Over-Goal Transom (`e = 0.95`) reflects shots above the crossbar (`Y > 10`) back into play.
- [ ] (3) Corner Pinball Bumpers apply `e = 1.25` speed boost capped at `MAX_REBOUND_SPEED = 180.0`.
- [ ] (4) `IsPositionOnElevatingRamp` checks the true 3D OBB of the `25°` ramp (`false` at `X = ±66.5` inward of the ramp, `false` above/below/beyond the ramp, `true` on the ramp surface) and `ApplyRampImpulse` lifts `Y` velocity only when on the ramp and enabled.
- [ ] (5) `14-Stud` Back-Goal Alley (`Z = ±106` to `±120`) allows unobstructed ball rebounds and player passage behind both goals.

### V-05 — Controlled A/B/C Comparison Matrix
- [ ] Controlled comparison suite runs across Variants `A`, `B`, and `C` for both Shape Pass (mechanics boosts disabled) and Mechanics Pass (bumpers & ramps enabled), recording actual reflection vectors, landing coordinates, post-hit speeds, and bounce counts in `assets/`.

### V-06 — Rollback Bundle & Typed Snapshot Integrity
- [ ] `.sandbox/rollback/run-phase01-cage-physics-01/` contains complete pre- and post-state snapshots of repo files and Studio instances with `0` JSON `null` values, separate `WorldPivot` and `GetPivot` fields, and verification/restore scripts.

### V-07 — Scope Lock & Honesty Delineation
- [ ] Plan `00-bootstrap-and-rig` remains `OPEN / PAUSED_BY_OWNER`, Reference Sandbox `112091950831355` is untouched, no out-of-scope services/remotes are enabled, no git commit/push/merge/deploy is performed, and the report explicitly separates verified runtime evidence from `NOT VERIFIED` items (human 3D visual aesthetics & multi-client WAN observer).


## Follow-up — 2026-10-20T16:35:55Z

[Owner Approved Update — Fix Floor Z-Fighting with Baseplate]
The user noticed floor flickering (Z-fighting) when walking because `Workspace.HexCageArena.CageFloor` (`Size = 160x2x240`, `Position = (0, -1, 0)`, `topY = 0`) and `Workspace.Baseplate` (`Size = 2048x16x2048`, `Position = (0, -8, 0)`, `topY = 0`) shared the exact same top surface plane at `Y = 0.0`.
The Owner approved moving `Workspace.Baseplate` down to `Position = (0, -10.05, 0)` (so its top surface is at `Y = -2.05`, cleanly beneath `CageFloor`'s bottom at `Y = -2.0` while keeping `Baseplate` intact as required by HANDOFF).

Please ensure `worker_impl` includes this in `CagePhysicsService` (e.g. inside `BuildCageArena` and/or `RetireBootstrapFixtures`: if `parent:FindFirstChild("Baseplate")` is a `BasePart` whose top `Y > -2.05`, set its `Position` to `Vector3.new(baseplate.Position.X, -2.05 - baseplate.Size.Y * 0.5, baseplate.Position.Z)` without deleting `Baseplate`), syncs it to Studio (`Place4`), and ensures the post-baseline snapshot and `V-01`..`V-07` verification reflect this cleanly.


## Follow-up — 2026-10-20T16:42:06Z

[Owner Approved Directive — Standard Goal Posts at Cage Wall Edge]
The Owner (Stang) has explicitly ordered the following design change for the goals in `01-cage-physics`:
1. Goal Placement (อยู่ขอบกรง):
   - Move the goals to the back boundary edge of the cage (`Z = ±120.0`), flush with the back wall (no 14-stud back alley, standard street/futsal cage style).
   - Set `GOAL_BACK_ZONE_STUDS = 0.0` (or adapt back wall / goal mouth alignment at `Z = ±120.0`).
2. Goal Geometry (โครงเสาประตูแบบปกติ):
   - Replace the single neon volume block with standard physical goal posts:
     - Left Post (เสาซ้าย): vertical post (e.g. `X = -12`, `Y ∈ [0, 10]`, post thickness ~0.8 studs, `CanCollide = true`, metal/white)
     - Right Post (เสาขวา): vertical post (e.g. `X = +12`, `Y ∈ [0, 10]`, post thickness ~0.8 studs, `CanCollide = true`, metal/white)
     - Crossbar (คานบน): horizontal bar (`X ∈ [-12, +12]`, `Y = 10`, post thickness ~0.8 studs, `CanCollide = true`, metal/white)
     - Goal Detection Volume / Mouth: open passage for ball scoring detection (`CheckGoalScored`) with `CanCollide = false`.
   - The Over-Goal Transom panel sits above the crossbar (`Y ∈ [10, wallHeightY]`) flush at `Z = ±120.0`.

Please ensure Orchestrator and `worker_impl` incorporate this into `Constants.luau`, `Types.luau`, and `CagePhysicsService.luau` (in `ArenaGeometry` catalog, `BuildCageArena`, and collision/goal check logic), sync to Studio (`Place4`), and update the verification suite / acceptance criteria accordingly.


## Follow-up — 2026-10-20T17:18:49Z

[Owner Directive — Final Completion Action: Auto-Shutdown]
The Owner (Stang) has instructed:
"ถ้างานเสร็จแล้ว shutdown เครื่องให้หน่อยได้ไหม เพิ่มไว้ใน milestone สุดท้าย"

Note on execution:
1. Please ensure that all milestones, source sync, Play Solo tests, V-01..V-07 evidence, and final reports are completely written and saved to disk.
2. Once everything is 100% completed and verified, report back the full completion to parent.
3. The parent agent will execute the graceful shutdown (`shutdown /s /t 120`) after receiving the final completion report so no subagent logs or artifacts are lost.


## Follow-up — 2026-10-20T19:30:44Z

[Owner Directive Clarification — DO NOT REVERT .gitignore]
Notice: The addition of `/.agents/` to `.gitignore` was an EXPLICIT DIRECTIVE from the Owner (Stang) in chat: "gitignore folder .agents ด้วย".
Do NOT revert `/.agents/` from `.gitignore`. The Owner's explicit live directive overrides the static baseline protection for this specific line.
Please instruct `orchestrator_2` and explorers to preserve `/.agents/` in `.gitignore`, and focus the fix round on:
1. `normalizeVariantId` alias support ("HexStreetVariantC", etc.)
2. Goal posts and crossbar relocated to $Z = \pm 120.0$ at the cage back boundary.


## Follow-up — 2026-10-21T01:46:59Z

## HANDOFF ADDENDUM: Clean Concrete Street-Football Pitch & Rectangular Cage (Variant A Visual Parity with Reference Sandbox)

### Objective
Owner (Stang) requested that **Variant `"A"`** (`DEFAULT_CAGE_VARIANT = "A"`) in `C:\Users\Stang\cage-zero\src\server\services\CagePhysicsService.luau` and live Roblox Studio (`Place4` / `137721422246269`, `studio_id = "5331d36b-4ba7-4726-9bfe-4e853359c9d6"`) look like a **clean, normal concrete pitch enclosed by a rectangular cage with nothing blue/neon blocking the middle**, matching the visual style of `C:\Users\Stang\cage-zero\.sandbox\reference\football-sandbox\server\ArenaBuilder.luau`.

### Required Implementation Tasks
1. **Remove/Hide All Glowing Blue/Neon Clutter in Variant `A`** (`C:\Users\Stang\cage-zero\src\server\services\CagePhysicsService.luau`):
   - `CageSpawnLocation` at `(0, 0.1, 0)` must remain `Transparency = 1.0` (`CanCollide = false, CanQuery = false`) so there is no blue square in the middle of the floor.
   - `Goal_North` and `Goal_South` (`kind = "GoalFrame"`) must remain `Transparency = 1.0` (`CanCollide = false`) so the goal mouth is open.
   - `Transom_North` and `Transom_South` (`kind = "GoalTransom"`) must use the same clean translucent glass material/color as the cage walls (`Color3.fromRGB(165, 195, 220)`, `Enum.Material.Glass`, `Transparency = 0.84`).
   - In Variant `"A"` (when `not includeOverlayInA`), `ElevatingRamp_Left`, `ElevatingRamp_Right`, `CeilingReboundMarker_North`, and `CeilingReboundMarker_South` must not appear as visible neon obstacles/markers inside the 3D arena (set their `BasePart` `Transparency = 1.0`, and for `ElevatingRamp_*` in Variant `"A"` when `not includeOverlayInA`, set `BasePart.CanCollide = false, BasePart.CanQuery = false` in `BuildCageArena`, while keeping `GetArenaGeometryProfile` surface definitions intact so all analytical trajectory tests `V-01`–`V-05` continue to pass).
2. **Clean Concrete Pitch Markings & Open Goal Nets / Steel Cage Frame** (inspired by `C:\Users\Stang\cage-zero\.sandbox\reference\football-sandbox\server\ArenaBuilder.luau`):
   - In `BuildCageArena`:
     - Add white pitch markings (`Color3.fromRGB(238, 242, 246)`, `Enum.Material.SmoothPlastic`, `CanCollide = false, CanQuery = false, CanTouch = false`, parented under `CageFloor` so `RigAndCardService` raycast `rayResult.Instance:IsDescendantOf(floor)` is 100% preserved):
       - Outer touchlines (`X = ±79.8`, `Z = ±119.8`), halfway line (`Z = 0`), center circle (`Radius = 20`) + center spot, North & South penalty areas (`Width = 64`, `Depth = 28`), goal areas (`Width = 36`, `Depth = 10`), and penalty spots (`Z = ±98`).
     - Add visual Goal Back Frame & Mesh Net behind `GoalPost_*` and `GoalCrossbar_*` at North (`Z = -120` to `-126`) and South (`Z = +120` to `+126`) with white/silver stanchions and semi-transparent mesh net panels/strands (`CanCollide = false, CanQuery = false`), and ensure `Wall_North` / `Wall_South` visually leave the `24 × 10` goal mouth (`X ∈ [-12, 12], Y ∈ [0, 10]`) open in the 3D scene (e.g., left/right wall segments in 3D while keeping `Wall_North`/`Wall_South` attributes/parts valid).
     - Add clean dark-steel structural cage frame pillars, horizontal rails, and ceiling cross-beams (`Color3.fromRGB(38, 44, 52)`, `Enum.Material.Metal`, `CanCollide = false, CanQuery = false`) around the perimeter so the rectangular cage looks like a true street-football cage.
3. **Sync & Verify in Roblox Studio (`5331d36b-4ba7-4726-9bfe-4e853359c9d6`)**:
   - Sync `C:\Users\Stang\cage-zero\src\server\services\CagePhysicsService.luau` to `ServerScriptService.Server.services.CagePhysicsService` in Studio and verify byte/SHA-256 parity.
   - Rebuild `Workspace.HexCageArena` in Studio `Edit` mode with Variant `"A"` (`CagePhysicsService.BuildCageArena( workspace, "A" )`).
   - Run verification checks confirming:
     - `Workspace.HexCageArena` has `CageVariantId = "A"`.
     - No visible neon/cyan parts obstruct the middle of the pitch.
     - `V-01`–`V-05` geometry & trajectory checks still pass 100%.
     - `Workspace.Baseplate` remains intact at `Y = -10.05` (no Z-fighting).


## 2026-10-22T06:23:47Z

Adapt the Argon R6 Football Animation Pack (A01–A18) into the existing Cage Zero R6 custom rig action system for Plan 02 (`02-player-actions`) in `C:\Users\Stang\cage-zero`, enforcing realistic athletic football locomotion, non-slip footwork, non-dislocating joints, discrete jump handling, and held shooting stance without foot shuffling or HRP anchoring.

Working directory: `C:\Users\Stang\cage-zero`
Integrity mode: development

## Baseline & Verified Artifacts
- **Current HEAD:** `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + working tree
- **ZIP Path:** `C:\Users\Stang\Downloads\Roblox_R6_Football_Animation_Pack-20261022T055539Z-1-001.zip`
- **ZIP SHA-256:** `c82ef41b057e2a1a0675fd9b2771670a428f3f5720254cee13a8676177b46d49` (VERIFIED)
- **Reference Extraction Path:** `docs/plan/phase-01-gameplay-demo/02-player-actions/assets/designs/argon-r6-pack/` (VERIFIED 28 entries)
- **Source Locks (Pre-flight):**
  - `src/shared/configs/PlayerActionPoseConfigs.luau`: `f41e9b782e800cb4e2ed465bd06e8a2d227a2f79f0271ee3804ce216b5bc4acb`
  - `src/client/character/R6ActionPoseController.luau`: `798c592783a40159fe11f0ec2efbcad94be022f97317264effcb413aecbfdf3c`
  - `src/client/character/R6AnimationController.luau`: `70daebfe80b3b36127aa338b91f2177f9209fc24127c4c3f71932031c27ca0e2`
  - `src/shared/configs/RigAnimationConfigs.luau`: `89037f778d11da301ea66936e9f3684032221c95cb4761c2b6201b1a17bebd25`
  - `src/client/controllers/InputController.luau`: `03daff87b7f1f7230fc089a886aa2d8e721945005fdbe46ad8d8246db9d9790a`
  - `src/server/services/BallService.luau`: `7e109383afc9fd9d260e8bc4624ae29c2d801a89af7274dda3e7f5d70c05704a` (READ-ONLY)
  - `src/shared/Types.luau`: `8341ba0ae2a34785ee33838e5a4483b3fe417f71ea3915926f7f301734593747` (READ-ONLY)
  - `src/shared/Constants.luau`: `90dbd499918ad8e7997d823d114c0dd9ecc82f20763ef2b8e5fad91e583d4013` (READ-ONLY)
  - `tests/e2e/Tier1_PlayerActions.luau`: `277d78b6eb41ed65241d8fa9753ca52efd08a1b9f92611b76587462868720595`

---

## Disjoint Team Ownership & Responsibilities

| Role | Exclusive File Ownership | Responsibilities |
| :--- | :--- | :--- |
| **Lead Orchestrator** | `docs/plan/.../02-player-actions/assets/fix-004.md`, `plan.md`, `tasks.md`, `notes.md` | Preflight, Studio sync coordinator, intermediate doc synchronization, single report author. |
| **Explorer / Challenger** | Read-Only (no file writes) | Inspect ZIP and callgraph, challenge edge cases for F-25..F-30, verify scope limits. |
| **Worker 1 (Pose Data)** | `src/shared/configs/PlayerActionPoseConfigs.luau` | Adapt A01–A18 and variants (finesse/trivela, ground/lob, hit/miss), record image provenance, adjust support & clearance. |
| **Worker 2 (Pose Runtime)** | `src/client/character/R6ActionPoseController.luau` | Single authoritative joint writer, Part0-to-Motor6D conversion, terminal cancel/fade states, character generation token binding, clean release. |
| **Worker 3 (Animator)** | `src/client/character/R6AnimationController.luau`, `src/shared/configs/RigAnimationConfigs.luau` | Track ownership deconfliction with procedural poses, suppress walk/run during charge hold, restore track control cleanly. |
| **Worker 4 (Input / State)** | `src/client/controllers/InputController.luau` | One-shot jump key release guard (fix continuous jump holding), bind visual intent to server-resolved actions/foot/style, real takeoff/landing lifecycle. |
| **Test Engineer** | `tests/e2e/Tier1_PlayerActions.luau` | In-engine native behavioral and pose verification via public interfaces, Studio test execution coordination. |

---

## Requirements

### R1. Adaptation of A01–A18 Poses into Single Joint Writer Architecture (T-05, F-21, F-25, F-26)
- Adapt the 18 authored poses and visual variants (A01 Idle, A02 Walk, A03 Sprint, A04 Dash, A05 8-Way Strafe, A06 Jump Apex, A07 Landing Cushion, A08 Header, A09 Block, A10 Volley, A11 Bicycle Kick, A12 Direct Shoot Windup, A13 Direct Shoot Follow-through, A14 Curve Shoot Windup, A15 Curve Shoot Follow-through, A16 Single 3D Pass, A17 Slide Tackle, A18 Slide Recovery / Miss) into `PlayerActionPoseConfigs.luau`.
- Ensure native in-engine CFrame evaluation prevents floor penetration (`minY >= 0`) during intermediate blending and transitions without modifying HRP height or physical rig schemas.
- Reconcile A05 strafe and A16 pass representations so runtime output matches authored design geometry. Ground and lob passes remain visual variants of the single 3D pass action.

### R2. Strict Terminal Cancel, Generation Guard & Track Ownership (F-27)
- In `R6ActionPoseController.luau`, implement explicit terminal states for stop, cancel, and reject with generation token validation. Auto-next must never resurrect interrupted actions.
- In `R6AnimationController.luau`, ensure default locomotion tracks do not fight or write over procedural poses during hold stances (e.g. charging shot). Once an action completes or cancels, joint and track ownership must be released cleanly to the active character.

### R3. Discrete Jump Guard & Real Flight / Landing Lifecycle (F-28, User Directive)
- In `InputController.luau`, implement a one-shot discrete key release guard for Spacebar (`Enum.KeyCode.Space`), ensuring that holding down the jump key does NOT cause repeated bunny-hopping or lock the airborne state.
- Bind aerial transitions to actual flight lifecycle (`takeoff -> ascent -> apex -> descent -> landed`) and ground contact raycasts, eliminating hardcoded flight timers (`0.72s`) and world-Y fallbacks. Acrobatic bicycle kick must land naturally without mid-air upright snapping.

### R4. Action Outcome Binding & Contact Synchronization (F-29)
- Bind Header, Volley, Bicycle Kick, and Curve Shoot to server-resolved actions, styles (`Finesse` vs `Trivela`), and kicking foot (`Right` vs `Left`), including correct axis mirroring for left-foot execution.
- Align visual contact phases with actual ball release without introducing artificial windup delays, ball writer conflicts, or altering cooldown/stamina costs.

### R5. Foot Sliding Mitigation at Target Velocities (F-30)
- Calibrate locomotion stride trajectories and animation cadence to match authoritative game velocities (`WALK_SPEED = 20.0`, `SPRINT_SPEED = 32.0`).
- Measure and document residual foot-slip empirically without altering core gameplay speed or balance parameters.

---

## Acceptance Criteria

### 1. Verification & Test Evidence
- [ ] Tier 1 Player Actions test suite (`Tier1_PlayerActions.luau`) passes with 0 failures in Roblox Studio Edit DataModel.
- [ ] Jump input requires explicit key release before another jump can trigger (no continuous auto-jump or airborne lock while holding Space).
- [ ] During shot charge hold (`IsCharging == true`), the character maintains the windup stance smoothly without legs shuffling or walking cycles layering over it, while retaining 50% movement speed without HRP anchoring.
- [ ] All 18 action poses and variants evaluate without limb dislocation, maintaining exact shoulder and hip socket pivots (`(1, 0.5, 0)`, `(-1, 0.5, 0)`, `(1, -1, 0)`, `(-1, -1, 0)`).
- [ ] Left plant leg remains grounded during curve shot charge and follow-through.

### 2. Governance & Deliverable Constraints
- [ ] Single consolidated report created at `docs/plan/phase-01-gameplay-demo/02-player-actions/assets/fix-004.md` detailing A01–A18 mappings, rationale, SHA-256 hashes, test evidence, and F-25..F-30 status.
- [ ] No git commit, push, merge, deploy, or branch alteration.
- [ ] No plan closure (Plans 00, 01, and 02 remain open).
- [ ] Strict Scope Guard maintained: Plan 03 (Poke/Shoulder, Skill Moves) and Plan 04 (Goalkeeper) remain excluded.
