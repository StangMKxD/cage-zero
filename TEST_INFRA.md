# TEST_INFRA.md — E2E Test Infrastructure Specification
## Project: Cage Zero — Plan 01-cage-physics
**Document Version:** 1.0.0  
**Target Place:** Roblox Studio `Place4` (`PlaceId = 137721422246269`)  
**Scope:** 3D Cage Variants A/B/C, Swept-Sphere Collision Solver, 5 Base Rebound Mechanics, R6 Floor Seam, and Bootstrap Chaining  
**Authoritative Sources:** `PROJECT.md`, `docs/plan/phase-01-gameplay-demo/01-cage-physics/assets/HANDOFF.md`, `ORIGINAL_REQUEST.md`

---

## 1. Test Philosophy (Requirement-Driven & Opaque-Box)

The Cage Zero E2E test suite adheres to strict **requirement-driven, opaque-box testing** principles:
1. **Opaque-Box Contract Testing:** Tests interact exclusively with public service APIs, exposed modules, and physical engine DataModel states. Internal implementation details (private helper variables, local unexported closures) are never mocked or relied upon.
2. **Authoritative Mathematical Derivations:** Expected outputs are derived directly from the physical and mathematical specifications locked in `PROJECT.md` and `HANDOFF.md`:
   - Specular reflection law: $\vec{v}' = \vec{v} - (1 + e)(\vec{v} \cdot \hat{n})\hat{n}$
   - Restitution coefficients: Floor ($e = 0.75$), Standard Walls/Ceiling ($e = 0.88$), Transom ($e = 0.95$), Corner Bumpers ($e = 1.25$ nominal, capped at $180\text{ studs/s}$).
   - Boundary coordinates: Variant A ($160 \times 240$, ceiling $Y = 32$), Variant B ($20\text{-stud}$ chamfers, 8 walls), Variant C ($8\text{-wall}$ base, $45^\circ$ roof bevel from $Y = 24$ to $Y = 32$, inset ceiling $144 \times 224$ at $Y = 32$ with zero flat roof overlap under the bevel).
   - Side Elevating Ramps: True 3D OBB footprint ($X \approx \pm 74$, $Z \in [-30, +30]$, angle $25^\circ$), strictly returning `false` at $X = \pm 66.5$.
   - Guide Markers: Pure visual guides (`CanCollide = false`, `CanQuery = false`) with exactly $0.000$ trajectory or velocity delta (zero aim-assist).
   - Baseplate Lowering: Lowered to $Y = -10.05$ (top at $Y = -2.05$), eliminating Z-fighting with `CageFloor` ($Y \in [-2, 0]$).
3. **Zero Facade / Anti-Drift Guarantee:** No fake tests, stub passes, or trivial assertions. Tests execute actual multi-step continuous trajectory simulations, collision substepping, swept-sphere queries, and physical DataModel inspection.
4. **Self-Containment & Isolation:** Each test case creates or uses isolated configurations, resets overrides upon completion, and executes independently of execution order.

---

## 2. Feature Inventory Mapping (F01 to F24)

Every feature identified in `PROJECT.md` is explicitly covered across the 4-tier test suite:

| Feature ID | Feature Name | Primary Test Tier | Test Module / Scenario | Verification Criterion |
|---|---|---|---|---|
| **F01** | Unified Arena Catalog | Tier 1 | `Tier1_FeatureCoverage` (TC-F01-01..05) | Single catalog profiles for Variants A, B, C; matches mathematical constants |
| **F02** | Variant A Builder | Tier 1 | `Tier1_FeatureCoverage` (TC-F02-01..05) | 4 orthogonal walls, flat ceiling $Y=32$, $160 \times 240$ footprint, correct collision tags |
| **F03** | Variant B Builder | Tier 1 | `Tier1_FeatureCoverage` (TC-F03-01..05) | 8 walls, 4x 20-stud chamfered corners, 4 pinball bumper wedges, flat ceiling $Y=32$ |
| **F04** | Variant C Builder | Tier 1 | `Tier1_FeatureCoverage` (TC-F04-01..05) | 8 walls base ($Y \le 24$), 8x $45^\circ$ roof bevels ($Y \in [24, 32]$), inset ceiling ($144 \times 224$), zero flat ceiling overlap |
| **F05** | Swept-Sphere Solver | Tier 1 & 2 | `Tier1_FeatureCoverage` & `Tier2_BoundaryCornerCases` | Continuous collision detection, accurate TOI calculation, penetration prevention |
| **F06** | Multi-Contact Substepping | Tier 1 & 2 | `Tier1_FeatureCoverage` & `Tier2_BoundaryCornerCases` | Up to 4 substeps per step, remaining $dt$ consumption, zero stuck states in corners |
| **F07** | Convex Polytope Safety Guard | Tier 1 & 2 | `Tier1_FeatureCoverage` & `Tier2_BoundaryCornerCases` | Out-of-bounds containment projection, zero escapes across all trajectories |
| **F08** | High-Speed Ball Reflection | Tier 1 & 2 | `Tier1_FeatureCoverage` & `Tier2_BoundaryCornerCases` | Specular rebound velocity calculation from $60$ to $180\text{ studs/s}$ |
| **F09** | Ceiling Lob & Smash | Tier 1 | `Tier1_FeatureCoverage` (TC-F09-01..05) | Restitution $e = 0.88$, downward angle reflection, smash velocity retention |
| **F10** | Zero Aim-Assist Guide Markers | Tier 1 | `Tier1_FeatureCoverage` (TC-F10-01..05) | `CanCollide = false`, `CanQuery = false`, exactly $0$ trajectory deviation between marker on/off |
| **F11** | Over-Goal Transom Rebound | Tier 1 | `Tier1_FeatureCoverage` (TC-F11-01..05) | Rebound zone $Y \in [10, 24]$, $Z = \pm 106$, $e = 0.95$, reflects balls back into midfield |
| **F12** | Corner Pinball Bumpers | Tier 1 & 2 | `Tier1_FeatureCoverage` & `Tier2_BoundaryCornerCases` | 4 corner wedges, $e = 1.25$ (+25% boost), capped strictly at $180\text{ studs/s}$ |
| **F13** | Elevating Ramps 25° OBB Query | Tier 1 & 2 | `Tier1_FeatureCoverage` & `Tier2_BoundaryCornerCases` | True 3D OBB test: `false` at $X = \pm 66.5$, `true` on ramp body, height/Z bounds respected |
| **F14** | Elevating Ramps Vertical Impulse | Tier 1 | `Tier1_FeatureCoverage` (TC-F14-01..05) | Upward velocity boost along $25^\circ$ slope when on ramp and enabled; 0 impulse when off |
| **F15** | 14-Stud Back-Goal Alley | Tier 1 | `Tier1_FeatureCoverage` (TC-F15-01..05) | Unobstructed zone $Z \in [\pm 106, \pm 120]$, $14\text{ studs}$ depth, ball rebounds & player pass |
| **F16** | Bootstrap Startup Chaining | Tier 1 | `Tier1_FeatureCoverage` (TC-F16-01..05) | Sequential order: `Network.Init` $\to$ `CagePhysicsService.Init` $\to$ `RigAndCardService.Init` |
| **F17** | Primary Floor & Spawn Pathing | Tier 1 | `Tier1_FeatureCoverage` (TC-F17-01..05) | Points to `Workspace.HexCageArena.CageFloor` and `CageSpawnLocation` |
| **F18** | Temporary Fixture Retirement | Tier 1 | `Tier1_FeatureCoverage` (TC-F18-01..05) | Retires `BootstrapTestFloor` and `BootstrapSpawnLocation`; preserves `Workspace.Baseplate` |
| **F19** | Baseplate Z-Fighting Lowering | Tier 1 | `Tier1_FeatureCoverage` (TC-F19-01..05) | Baseplate lowered to $Y = -10.05$ (top at $Y = -2.05$), completely below `CageFloor` bottom |
| **F20** | Single Custom R6 Rig Spawning | Tier 1 | `Tier1_FeatureCoverage` (TC-F20-01..05) | Single R6 rig spawns cleanly on `CageFloor` without falling through or clipping |
| **F21** | R6 Play Solo Traversal | Tier 1 | `Tier1_FeatureCoverage` (TC-F21-01..05) | Traversal clearances verified: ramp ascent clearance, 14-stud back-goal corridor width |
| **F22** | Controlled Comparison Suite | Tier 3 | `Tier3_CrossFeatureCombos` & Comparison Suite | Runs 7 Shape Pass and 11 Mechanics Pass scenarios across A, B, C |
| **F23** | Measured Comparison Matrix Asset | Tier 3 | `Tier3_CrossFeatureCombos` | Matrix structure, metrics (speed, bounce count, landing coords) verified |
| **F24** | Rollback Bundle Integrity | Tier 1 | `Tier1_FeatureCoverage` (TC-F24-01..05) | Snapshot files exist, 0 JSON nulls, separate `WorldPivot` vs `GetPivot` |

---

## 3. Test Architecture & Runner Specification

### 3.1 Directory Layout
All test code is strictly co-located within `tests/e2e/` (never in `.agents/teamwork/`):
```
tests/e2e/
├── TestHarness.luau               # Assertion library, test runner, reporter
├── Tier1_FeatureCoverage.luau     # Feature coverage (>=5 tests per feature)
├── Tier2_BoundaryCornerCases.luau # Edge, boundary, grazing, and corner cases
├── Tier3_CrossFeatureCombos.luau  # Pairwise & compound cross-feature interactions
├── Tier4_RealWorldRallyScenarios.luau # Full 60s rally & match play simulations
├── TestRunner.luau                # Master test suite runner & JSON aggregator
├── run_all.ps1                    # PowerShell automation script for test execution
└── run_all.js                     # Node.js runner utility
```

### 3.2 Test Execution Semantics
- **Execution Engine:** Luau runtime inside Roblox Studio (`Place4` / PlaceId `137721422246269`) executed via the `Roblox_Studio` MCP `execute_luau` tool or Studio Command Bar.
- **Pass/Fail Semantics:**
  - A test is marked **PASSED** only when all assertions within the test block succeed.
  - An assertion failure immediately records the expected value, actual value, failure message, and test name.
  - The master test runner returns an exit code / status: `status = "PASSED"` when `failedCount == 0`, otherwise `status = "FAILED"`.
- **Diagnostic Output:**
  ```json
  {
    "totalTests": 125,
    "passedTests": 125,
    "failedTests": 0,
    "durationMs": 342,
    "tiers": {
      "Tier1": { "total": 70, "passed": 70, "failed": 0 },
      "Tier2": { "total": 35, "passed": 35, "failed": 0 },
      "Tier3": { "total": 12, "passed": 12, "failed": 0 },
      "Tier4": { "total": 8,  "passed": 8,  "failed": 0 }
    },
    "failures": []
  }
  ```

---

## 4. Tier Definitions & Coverage Thresholds

### 4.1 Tier 1: Feature Coverage (Threshold: $\ge 5$ tests per feature)
Covers baseline happy paths and functionality for all 14 core arena mechanics and infrastructure items:
1. **F01 Unified Arena Catalog:** Profile schema, surface counts, dimensions for A, B, C.
2. **F02 Variant A Geometry:** 4 walls, flat ceiling $Y=32$, dimensions $160 \times 240 \times 32$.
3. **F03 Variant B Geometry:** 8 walls, $20\text{-stud}$ chamfers, bumpers present, ceiling $Y=32$.
4. **F04 Variant C Geometry:** 8 base walls, 8 $45^\circ$ bevels, inset ceiling $144 \times 224$ at $Y=32$, zero flat overlap.
5. **F05 Swept-Sphere Collision Solver:** Finite collision step, swept sphere $r = 1.25$, normal reflection.
6. **F06 Multi-Contact Substepping:** Substep division, $dt$ advancement, multi-hit handling up to 4 substeps.
7. **F07 Boundary & Safety Containment:** Bounds check, clamping/projection, zero escape.
8. **F08 Specular Rebound Calculation:** Formula adherence $\vec{v}' = \vec{v} - (1+e)(\vec{v}\cdot\hat{n})\hat{n}$, speed retention.
9. **F09 Ceiling Lob & Smash:** Restitution $e = 0.88$, downward angle deflection.
10. **F10 Guide Markers Zero Pull:** Identical trajectories with guide marker enabled vs disabled ($\Delta = 0$).
11. **F11 Over-Goal Transom:** Crossbar threshold $Y \in [10, 24]$, $e = 0.95$, reflection into midfield.
12. **F12 Corner Pinball Bumpers:** $e = 1.25$ (+25% boost), reflection along chamfer normal.
13. **F13 Side Elevating Ramps OBB:** OBB containment, `false` at $X = \pm 66.5$, `true` on ramp.
14. **F14 Ramp Upward Impulse:** Impulse application along $25^\circ$ angle, $v_y$ boost when on ramp.
15. **F15 Back-Goal Alley (14 studs):** $Z \in [\pm 106, \pm 120]$, $14\text{ studs}$ corridor clearance.
16. **F16–F21 Bootstrap & Scene Seam:** Chaining sequence, Baseplate lowered to $Y = -10.05$ (top at $Y = -2.05$), fixture retirement.

### 4.2 Tier 2: Boundary & Corner Cases (Threshold: $\ge 5$ tests per boundary domain)
Stresses the physical engine at the extreme edges of parameter space:
1. **Velocity Extremes:**
   - Maximum speed ($180\text{ studs/s}$) collision without tunneling.
   - Low-speed creeping ($0.05\text{ studs/s}$) resting contact.
   - High-speed bumper collision clamping at exactly $180\text{ studs/s}$.
2. **Grazing & Shallow Angles:**
   - $1^\circ$ near-parallel glance along straight wall.
   - $3^\circ$ glance along chamfered corner wall.
   - $5^\circ$ glance along ceiling surface.
   - $89^\circ$ steep normal impact.
3. **Multi-Surface Seams & Corner Junctions:**
   - Orthogonal wall-wall seam (X/Z intersection).
   - Chamfer-to-wall seam intersection.
   - Wall-to-roof bevel seam ($Y = 24.0$).
   - Roof bevel-to-inset ceiling seam ($Y = 32.0$).
   - Floor-to-wall seam ($Y = 0.0$).
4. **Elevating Ramp Spatial Boundaries:**
   - Inward threshold: $X = \pm 66.5$ (outside, must be `false`) vs $X = \pm 68.0$ (inside, must be `true`).
   - Lengthwise threshold: $Z = \pm 29.99$ (inside) vs $Z = \pm 30.01$ (outside).
   - Vertical clearance: $Y = 1.0$ (on ramp surface) vs $Y = 15.0$ (high above ramp, must not trigger).
5. **Transom & Goal Aperture Thresholds:**
   - Just below crossbar: $Y = 9.95$ (goal mouth zone, not transom).
   - Just above crossbar: $Y = 10.05$ (transom rebound zone, $e = 0.95$).
   - Transom top edge: $Y = 23.95$ (transom zone) vs $Y = 24.05$ (eave/wall zone).
   - Goal post lateral edges: $X = \pm 11.95$ (transom width) vs $X = \pm 12.05$ (back wall).

### 4.3 Tier 3: Cross-Feature Combinations (Threshold: $\ge 8$ compound interaction scenarios)
Verifies multi-feature interactions where physical mechanics chain together:
1. **Ramp Launch $\to$ Ceiling Lob Smash:** Ball ascends $25^\circ$ ramp, receives upward impulse, hits ceiling ($e=0.88$), and rebounds downward.
2. **Ramp Launch $\to$ Variant C $45^\circ$ Roof Bevel:** Ball launched from ramp impacts the sloped roof bevel, deflecting down and inwards.
3. **Corner Pinball Bumper $\to$ Over-Goal Transom:** Ball hits corner bumper with $+25\%$ boost, travels diagonally across arena, and impacts transom above crossbar.
4. **Back-Goal Alley Traversal $\to$ Corner Bumper Rebound:** Ball driven through the $14\text{-stud}$ alley behind the goal, bounces off back wall, and glances off rear corner bumper.
5. **High-Speed Lob Passing Through Guide Marker:** Trajectory directly intersecting guide marker tested with marker present vs absent; confirms $0.000$ deviation.
6. **Elevating Ramp Incline $\to$ Wall Glancing Angle:** Compound collision where ball hits ramp near wall seam.
7. **Over-Goal Transom $\to$ Floor Ground Bounce:** Transom rebound ($e = 0.95$) landing on floor ($e = 0.75$), verifying kinetic energy decay chain.
8. **Variant C Dual Bevel Corner Rebound:** Ball striking the compound seam between North roof bevel and North-West corner roof bevel.

### 4.4 Tier 4: Real-World Application Scenarios (Threshold: $\ge 4$ full rally simulations)
Simulates end-to-end, chaotic match play across extended time horizons:
1. **Scenario 4.1: Continuous 60-Second Match Rally (Variants A, B, C):**
   - High-cadence ball rally with gravity ($g = -65\text{ studs/s}^2$).
   - Randomized directional strikes across all 3 variants.
   - Asserts: $0$ ball escapes, $0$ corner stuck conditions, $0$ NaN coordinates, total bounce count $> 30$, kinetic energy bounded.
2. **Scenario 4.2: Box-to-Box Counterattack with Midfield Ramp Launch:**
   - Goalkeeper clearance launched from $Z = -100$, travels over midfield, hits $25^\circ$ ramp, gains altitude, strikes opposing transom at $Z = +106$, and rebounds into penalty area.
3. **Scenario 4.3: Corner Chaos Multi-Bumper Pinball Sequence:**
   - Rapid multi-ricochet test bouncing between SW bumper, North wall, NE bumper, and floor.
4. **Scenario 4.4: High-Arc Lob & Aerial Volley Setup:**
   - Ball lofted high to ceiling guide marker, rebounds downward with $e = 0.88$, creating an aerial heading opportunity at $Y \approx 8$.

---

## 5. Summary of Verification Gates & Thresholds

| Tier | Focus | Minimum Required Tests | Target Pass Rate |
|---|---|---|---|
| **Tier 1** | Feature Coverage across F01–F24 | $\ge 70$ tests ($\ge 5$ per feature) | 100% |
| **Tier 2** | Boundary & Corner Cases | $\ge 35$ tests ($\ge 5$ per boundary domain) | 100% |
| **Tier 3** | Cross-Feature Combinations | $\ge 12$ compound interaction scenarios | 100% |
| **Tier 4** | Real-World Rally Scenarios | $\ge 8$ extended match rally runs | 100% |
| **Total** | **Comprehensive E2E Suite** | **$\ge 125$ tests / assertions** | **100%** |
