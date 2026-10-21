# Project: Cage Zero — Plan 01-cage-physics

## Architecture
Cage Zero is a fast-paced physics-driven soccer/arena game on Roblox Studio.
Plan `01-cage-physics` establishes the 3D enclosed arena, continuous collision detection, rebound mechanics, and seamless player movement:
- **Arena Geometry**: Single unified catalog `ArenaGeometry` supporting Variants A (orthogonal 4 walls), B (8 walls with 20-stud chamfered corners), and C (8 walls with 45° beveled roof from Y=24 to Y=32, with inset ceiling at Y=32 and no flat ceiling overlap under the bevel).
- **Collision Solver**: Continuous swept-sphere collision solver (`BALL_RADIUS = 1.25`, `MAX_COLLISION_SUBSTEPS = 4`) handling high-speed balls (60–180 studs/s) with 0 tunneling and 0 corner-stuck states.
- **5 Base Rebound Mechanics**:
  1. Ceiling Lob & Smash ($e = 0.88$) with non-collidable zero-aim-assist guide markers.
  2. Over-Goal Transom ($e = 0.95$) for balls hitting above the crossbar ($Y \in [10, 24]$) flush at $Z = \pm 120.0$.
  3. 4 Corner Pinball Bumpers ($e = 1.25$, $+25\%$ boost capped at $180\text{ studs/s}$).
  4. Side Elevating Ramps 25° with true 3D Oriented Bounding Box (OBB) query and upward velocity impulse.
  5. Standard Physical Goal Posts & Transom at Cage Boundary ($Z = \pm 120.0$): Left/Right vertical posts at $X = \pm 12$ ($Y \in [0, 10]$), horizontal crossbar at $Y = 10$ ($X \in [-12, +12]$) with post thickness ~0.8 studs, metal/white, `CanCollide = true`, open goal mouth for scoring detection (`CanCollide = false`), and `GOAL_BACK_ZONE_STUDS = 0.0`.
- **Bootstrap & Seam**: Startup sequence `Network.Init(10.0)` -> `CagePhysicsService.Init()` -> `RigAndCardService.Init()`. Primary floor is `Workspace.HexCageArena.CageFloor`, temporary `BootstrapTestFloor` fixtures are retired, and `Workspace.Baseplate` is lowered to $Y = -10.05$ (top at $Y = -2.05$) to eliminate Z-fighting while remaining intact.
- **Rollback Safety**: Typed snapshots in `.sandbox/rollback/run-phase01-cage-physics-01/` with 0 JSON nulls, separate `WorldPivot` vs `GetPivot`, accompanied by `manifest.json`, `restore.ps1`, and `verify-rollback.ps1`.

---

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| F01 | Unified Arena Catalog | Single mathematical catalog for all arena surfaces across Variants A, B, and C | M2 | Survey / HANDOFF |
| F02 | Variant A Builder | 4-wall orthogonal box ($160 \times 240$) with flat ceiling at $Y=32$ | M2 | Survey / HANDOFF |
| F03 | Variant B Builder | 8-wall box with 4 corner 20-stud chamfers and flat ceiling at $Y=32$ | M2 | Survey / HANDOFF |
| F04 | Variant C Builder | 8-wall base ($Y \in [0, 24]$) + 8 45° roof bevels ($Y \in [24, 32]$) + inset ceiling ($144 \times 224$ at $Y=32$) with no flat ceiling overlap | M2 | Survey / HANDOFF |
| F05 | Swept-Sphere Solver | Continuous collision detection with slab TOI test for sphere against finite OBB surfaces | M3 | Survey / HANDOFF |
| F06 | Multi-Contact Substepping | Budget of up to 4 collision substeps per physics frame with remaining $dt$ advancement | M3 | Survey / HANDOFF |
| F07 | Convex Polytope Safety Guard | Out-of-bounds safety projection clamping positions inside half-space inequalities | M3 | Survey / HANDOFF |
| F08 | High-Speed Ball Reflection | Specular reflection $v' = v - (1 + e)(v \cdot n)n$ for ball speeds 60–180 studs/s | M3 | Survey / HANDOFF |
| F09 | Ceiling Lob & Smash | Ceiling restitution $e = 0.88$ allowing downward lob/smash rebounds | M3 | Survey / HANDOFF |
| F10 | Zero Aim-Assist Guide Markers | Non-collidable (`CanCollide = false`, `CanQuery = false`) visual markers with 0 velocity pull | M3 | Survey / HANDOFF |
| F11 | Over-Goal Transom Rebound | Rebound zone above crossbar ($Y \in [10, Y_{eave}]$, $Z = \pm 106$) with $e = 0.95$ | M3 | Survey / HANDOFF |
| F12 | Corner Pinball Bumpers | 4 bumper wedges applying $e = 1.25$ (+25% boost) capped at $180\text{ studs/s}$ | M3 | Survey / HANDOFF |
| F13 | Elevating Ramps 25° OBB Query | True 3D Oriented Bounding Box query in `IsPositionOnElevatingRamp` returning `false` at $X = \pm 66.5$ | M3 | Survey / HANDOFF |
| F14 | Elevating Ramps Vertical Impulse | Upward impulse in `ApplyRampImpulse` boosting $v_y$ along the 25° incline | M3 | Survey / HANDOFF |
| F15 | Standard Goal Posts & Edge Transom | Left/Right posts ($X = \pm 12$), crossbar ($Y = 10$) ~0.8-stud thick metal/white, open goal mouth, `GOAL_BACK_ZONE_STUDS = 0.0` at $Z = \pm 120.0$ | M2 | Owner Directive |
| F16 | Bootstrap Startup Chaining | Exact sequence: `Network.Init(10.0)` -> `CagePhysicsService.Init()` -> `RigAndCardService.Init()` | M4 | Survey / HANDOFF |
| F17 | Primary Floor & Spawn Pathing | `PRIMARY_FLOOR_PATH = "Workspace.HexCageArena.CageFloor"` and `CageSpawnLocation` | M4 | Survey / HANDOFF |
| F18 | Temporary Fixture Retirement | Retire `BootstrapTestFloor` and `BootstrapSpawnLocation` while keeping `Baseplate` intact | M4 | Survey / HANDOFF |
| F19 | Baseplate Z-Fighting Lowering | Lower `Workspace.Baseplate` to `Position = (0, -10.05, 0)` ($Y = -2.05$) to eliminate floor flicker | M2 | Owner Approved Update |
| F20 | Single Custom R6 Rig Spawning | R6 rig spawns cleanly on `CageFloor` with 0 floor seam clipping | M4 | Survey / HANDOFF |
| F21 | R6 Play Solo Traversal | R6 character walks, jumps, climbs 25° ramp, and traverses 14-stud alley | M4 | Survey / HANDOFF |
| F22 | Controlled Comparison Suite | `RunVariantComparisonSuite` running 7 Shape Pass and 11 Mechanics Pass scenarios across A, B, C | M5 | Survey / HANDOFF |
| F23 | Measured Comparison Matrix Asset | Export comparison results to `docs/plan/phase-01-gameplay-demo/01-cage-physics/assets/` | M5 | Survey / HANDOFF |
| F24 | Rollback Bundle Integrity | `.sandbox/rollback/run-phase01-cage-physics-01/` with 0 nulls, separate pivots, `manifest.json`, `restore.ps1`, `verify-rollback.ps1` | M1 | Survey / HANDOFF |

---

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Rollback Bundle & Baseline Safety | Generate `restore.ps1`, `verify-rollback.ps1`, verify authentic `pre/` baseline preservation, validate 0 nulls & separate pivots | none | DONE |
| M2 | Source Harmonization, Z-Fighting Fix & Studio Sync | Reconcile duration parameters in `CagePhysicsService.luau` (lines 1476, 1559), implement Baseplate lowering to $Y = -10.05$, implement Standard Goal Posts & Edge Transom ($Z = \pm 120.0$), sync to Studio Place4, verify 100% SHA-256 readback match (V-01) | M1 | DONE |
| M3 | Geometry, Solver & 5 Rebound Mechanics Verification | Verify Variants A/B/C geometry, swept-sphere solver (0 escapes, 0 stuck), and all 5 rebound mechanics in Studio (V-03, V-04) | M2 | DONE |
| M4 | Bootstrap Chaining, Floor Seam & R6 Traversal | Verify startup chaining, fixture retirement, Play Solo R6 rig spawn on `CageFloor`, ramp climbing, and 14-stud alley traversal (V-02) | M2 | DONE |
| M5 | Comparison Matrix, Post-Snapshot & Victory Certification | Execute `RunVariantComparisonSuite`, export comparison matrix asset, generate typed post-baseline snapshot, verify V-01..V-07, and pass Forensic Victory Audit | M3, M4 | DONE |

---

## Interface Contracts

### `src/shared/Constants.luau`
- `ARENA_MODEL_NAME = "HexCageArena"`
- `DEFAULT_CAGE_VARIANT: Types.CageVariantId = "B"`
- `PRIMARY_FLOOR_PATH = "Workspace.HexCageArena.CageFloor"`
- `PRIMARY_SPAWN_PATH = "Workspace.HexCageArena.CageSpawnLocation"`
- `ARENA_HALF_WIDTH_X = 80.0`, `ARENA_HALF_LENGTH_Z = 120.0`, `ARENA_CEILING_HEIGHT_Y = 32.0`
- `CHAMFER_CUT_STUDS = 20.0`, `ROOF_BEVEL_STUDS = 8.0`, `ROOF_EAVE_HEIGHT_Y = 24.0`
- `BALL_RADIUS = 1.25`, `FLOOR_RESTITUTION = 0.75`, `STANDARD_WALL_RESTITUTION = 0.88`, `TRANSOM_RESTITUTION = 0.95`, `BUMPER_RESTITUTION = 1.25`
- `MAX_REBOUND_SPEED = 180.0`, `MAX_COLLISION_SUBSTEPS = 4`
- `GOAL_WIDTH_X = 24.0`, `GOAL_HEIGHT_Y = 10.0`, `GOAL_DEPTH_Z = 6.0`, `GOAL_BACK_ZONE_STUDS = 14`
- `ELEVATING_RAMP_ANGLE_DEG = 25`

### `src/shared/Types.luau`
- `type CageVariantId = "A" | "B" | "C"`
- `type ArenaSurfaceKind = "Floor" | "Wall" | "Chamfer" | "Ceiling" | "RoofBevel" | "Transom" | "GoalPost" | "PinballBumper" | "ElevatingRamp"`
- `type ReboundFeatureFlags = { ceilingMarkerGuideOnly: boolean, transomRebound: boolean, pinballBumpers: boolean, elevatingRamps: boolean, backGoalAlley: boolean }`
- `type ArenaSurfaceDef = { name: string, kind: ArenaSurfaceKind, cframe: CFrame, size: Vector3, normal: Vector3, restitution: number, isBumper: boolean?, isRamp: boolean?, isGoalZone: boolean?, isMarker: boolean? }`
- `type ArenaGeometryProfile = { variantId: CageVariantId, surfaces: { ArenaSurfaceDef }, wallCount: number, hasChamfers: boolean, hasRoofBevel: boolean, ceilingHeightY: number, eaveHeightY: number }`
- `type ReboundStepResult = { position: Vector3, velocity: Vector3, collided: boolean, hitSurfaceName: string?, substepsUsed: number, penetrationDepth: number? }`

### `src/server/services/CagePhysicsService.luau`
- `Init(): ()`
- `BuildCageArena(parent: Instance?, variantId: Types.CageVariantId?): Model`
- `BuildHexCageArena(parent: Instance?, variantId: Types.CageVariantId?): Model`
- `RetireBootstrapFixtures(parent: Instance?): ()`
- `GetArenaGeometry(variantId: Types.CageVariantId?): Types.ArenaGeometryProfile`
- `StepBallCageCollision(position: Vector3, velocity: Vector3, dt: number, variantId: Types.CageVariantId?, flags: Types.ReboundFeatureFlags?): Types.ReboundStepResult`
- `IsPositionOnElevatingRamp(position: Vector3): (boolean, string?)`
- `ApplyRampImpulse(velocity: Vector3, isOnRamp: boolean): Vector3`
- `SimulateBallTrajectory(initialPos: Vector3, initialVel: Vector3, duration: number, dt: number?, variantId: Types.CageVariantId?, flags: Types.ReboundFeatureFlags?): any`
- `RunVariantComparisonSuite(): any`

---

## Code Layout
- `src/shared/Constants.luau`: Physical constants, bounds, arena paths.
- `src/shared/Types.luau`: Domain types and interfaces for geometry and solver.
- `src/server/services/CagePhysicsService.luau`: Unified catalog, builder, collision solver, 5 rebound mechanics, test comparison suite.
- `src/server/init.server.luau`: Bootstrap startup chaining and fixture retirement.
- `.sandbox/rollback/run-phase01-cage-physics-01/`: Rollback snapshots, manifests, and scripts.
