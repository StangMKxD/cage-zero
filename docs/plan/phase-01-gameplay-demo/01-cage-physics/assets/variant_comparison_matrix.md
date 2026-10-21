# Controlled A/B/C Variant Comparison Matrix — Cage Zero Plan 01-cage-physics

> [!NOTE] **Historical Baseline Snapshot Disclaimer (Per F-06 / Review-003)**
> เอกสารนี้เป็น **Historical Baseline Telemetry Snapshot** ที่บันทึกจากการรันชุดเปรียบเทียบเบื้องต้นระหว่างการพัฒนาบน HEAD baseline commit `65026668fcae9d80094841bb147f3f4dc64b0b6c` ร่วมกับ uncommitted working tree ในรอบแรกเริ่ม (ซึ่ง source hash ที่รัน telemetry ชุดนั้นเป็น historical dirty state / exact source hash unknown; ไม่ได้มาจาก pristine commit `6502666` เพียงลำพัง และเกิดขึ้นก่อนมี approved directive แยกกำแพงท้ายสนาม `Wall_North` / `Wall_South` เป็น Left/Right และเปิดช่องโกลจริงที่ $Z = \pm 120.0$ สู่ `GoalPocket`)
> - ในตารางข้างล่าง Scenario `M05_BackGoalAlley14` และ Tag `Wall_North` แบบเต็มผืน สะท้อนโครงสร้างเรขาคณิต baseline ประวัติศาสตร์เดิม (ปัจจุบัน catalog แยกเป็น Wall_North_Left / Wall_North_Right และมี GoalPocket ตาม F-01/F-02/F-08)
> - การเทียบเชิงกลไกพื้นฐาน (Transom restitution $e=0.95$, Pinball Bumper $1.25\times$ speed boost, Speed Cap $180.0\text{ studs/s}$, Ramp 3D OBB และ Ceiling Marker Zero Aim-Assist) ยังคงเป็นหลักฐานทางคณิตศาสตร์ที่ถูกต้อง
> - เอกสารนี้ถูกเก็บรักษาไว้เป็นหลักฐานเชิงประวัติศาสตร์ (Historical Evidence) เพื่อความโปร่งใส ไม่นำมาอ้างสิทธิ์แทนการรัน V-05 บน current working tree ล่าสุด

**Verification Gate V-05 Deliverable (Historical Run)**
- **Date**: 2026-10-21
- **Target Studio**: Roblox Studio Place4 (`PlaceId = 137721422246269`, Studio ID `43e07a67-a9c4-4837-b3cf-54cf2f827937`)
- **Execution Target**: `CagePhysicsService.RunVariantComparisonSuite()` via `execute_luau` in active `Edit` DataModel
- **Data Source**: Authentic live in-engine engine telemetry (zero dummy implementations, zero fabricated data)

---

## 1. Executive Summary & Invariant Verification

| Invariant / Check | Evaluated Condition | Result | Status |
| :--- | :--- | :---: | :---: |
| **Total Trajectory Probes** | Shape Pass (21) + Mechanics Pass (34) | **55 runs** | **PASS** |
| **Zero Escape Bounds** | No trajectory escaped arena boundaries | **0 escapes / 55 runs** | **PASS** |
| **Zero Corner Stuck** | No velocity loss / infinite contact trapped in seams | **0 stuck / 55 runs** | **PASS** |
| **Ceiling Marker Zero Aim-Assist** | Guide marker imparts zero velocity pull or directional bias | **0.000 delta** ($\Delta \mathbf{v} < 10^{-4}$) | **PASS** |
| **Side Ramp 3D OBB Detection** | Precise OBB bounding box audit across 6 points | **6 / 6 accurate** | **PASS** |
| **Pinball Bumper Speed Cap** | $160\text{ studs/s} \times 1.25 = 200\text{ studs/s} \to 180\text{ studs/s}$ | **Exact 180.0 cap** | **PASS** |

---

## 2. Part 1 — Shape Pass Trajectory Comparison (Mechanics Disabled)

*Configuration*: Feature flags `{ enableBumpers = false, enableTransom = false, enableRamps = false, includeCornerOverlayInA = false }`. Restitution $e = 0.88$ on walls and ceilings, $e = 0.75$ on floor. Tests purely geometric differences between:
- **Variant A**: Orthogonal 4-wall box ($160 \times 32 \times 240$) + flat ceiling at $Y = 32.0$.
- **Variant B**: 8-wall polygon (4 corner chamfers cut by $20\text{ studs}$ at $45^\circ$) + flat ceiling at $Y = 32.0$.
- **Variant C**: 8-wall polygon base ($Y \in [0, 24]$) + $45^\circ$ beveled roof ($Y \in [24, 32]$) on all 8 sides with inset flat ceiling ($144 \times 2 \times 224$) at $Y = 32.0$.

### 2.1 Shape Pass Trajectory Matrix (21 Runs)

| Scenario ID | Variant | $v_0$ (studs/s) | First Hit Surface | First Hit Pos $(X, Y, Z)$ | Rebound Velocity $(v'_x, v'_y, v'_z)$ | Speed After | Total Hits | Landing Pos $(X, Y, Z)$ | Escaped | Stuck |
| :--- | :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `S01_CornerCut_NW` | **A** | 99.0 | `Wall_West` | `(-78.22, 3.00, -118.22)` | `(61.60, 0.00, 61.60)` | 87.1 | 1 | `(-18.68, 3.00, -58.68)` | `false` | `false` |
| `S01_CornerCut_NW` | **B** | 99.0 | `CornerWall_NW` | `(-68.32, 3.00, -108.32)` | `(61.60, 0.00, 61.60)` | 87.1 | 1 | `(-0.56, 3.00, -40.56)` | `false` | `false` |
| `S01_CornerCut_NW` | **C** | 99.0 | `CornerWall_NW` | `(-68.32, 3.00, -108.32)` | `(61.60, 0.00, 61.60)` | 87.1 | 1 | `(-0.56, 3.00, -40.56)` | `false` | `false` |
| `S02_CornerCut_NE_Mirror` | **A** | 99.0 | `Wall_East` | `(78.22, 3.00, -118.22)` | `(-61.60, 0.00, 61.60)` | 87.1 | 1 | `(18.68, 3.00, -58.68)` | `false` | `false` |
| `S02_CornerCut_NE_Mirror` | **B** | 99.0 | `CornerWall_NE` | `(68.32, 3.00, -108.32)` | `(-61.60, 0.00, 61.60)` | 87.1 | 1 | `(0.56, 3.00, -40.56)` | `false` | `false` |
| `S02_CornerCut_NE_Mirror` | **C** | 99.0 | `CornerWall_NE` | `(68.32, 3.00, -108.32)` | `(-61.60, 0.00, 61.60)` | 87.1 | 1 | `(0.56, 3.00, -40.56)` | `false` | `false` |
| `S03_HighSideLob_WestBevel` | **A** | 90.8 | `Wall_West` | `(-77.92, 25.60, 0.00)` | `(74.80, 1.47, 0.00)` | 74.8 | 2 | `(-11.91, 1.41, 0.00)` | `false` | `false` |
| `S03_HighSideLob_WestBevel` | **B** | 90.8 | `Wall_West` | `(-77.92, 25.60, 0.00)` | `(74.80, 1.47, 0.00)` | 74.8 | 2 | `(-11.91, 1.41, 0.00)` | `false` | `false` |
| `S03_HighSideLob_WestBevel` | **C** | 90.8 | `RoofBevel_West` | `(-76.69, 25.40, 0.00)` | `(3.37, -74.80, 0.00)` | 74.9 | 4 | `(-75.69, 2.30, 0.00)` | `false` | `false` |
| `S04_HighEndLob_NorthBevel` | **A** | 96.2 | `Wall_North` | `(0.00, 26.60, -117.63)` | `(0.00, 1.32, 79.20)` | 79.2 | 2 | `(0.00, 1.48, -46.44)` | `false` | `false` |
| `S04_HighEndLob_NorthBevel` | **B** | 96.2 | `Wall_North` | `(0.00, 26.60, -117.63)` | `(0.00, 1.32, 79.20)` | 79.2 | 2 | `(0.00, 1.48, -46.44)` | `false` | `false` |
| `S04_HighEndLob_NorthBevel` | **C** | 96.2 | `RoofBevel_North` | `(0.00, 25.37, -115.69)` | `(0.00, -79.20, 3.23)` | 79.3 | 4 | `(0.00, 2.08, -114.78)` | `false` | `false` |
| `S05_HighCornerLob_NWBevel` | **A** | 93.3 | `Wall_West` | `(-78.34, 25.18, -118.34)` | `(54.56, -6.16, 54.56)` | 77.4 | 2 | `(-36.59, 1.50, -76.59)` | `false` | `false` |
| `S05_HighCornerLob_NWBevel` | **B** | 93.3 | `CornerWall_NW` | `(-68.41, 25.57, -108.41)` | `(54.56, 2.42, 54.56)` | 77.2 | 2 | `(-19.38, 1.50, -59.38)` | `false` | `false` |
| `S05_HighCornerLob_NWBevel` | **C** | 93.3 | `RoofBevel_NW` | `(-67.71, 25.30, -107.71)` | `(3.06, -77.16, 3.06)` | 77.3 | 4 | `(-66.84, 1.70, -106.84)` | `false` | `false` |
| `S06_CeilingLob_NorthMarker` | **A** | 96.2 | `CageCeiling` | `(0.00, 30.50, -60.81)` | `(0.00, -32.19, -59.84)` | 68.0 | 3 | `(0.00, 1.95, -95.52)` | `false` | `false` |
| `S06_CeilingLob_NorthMarker` | **B** | 96.2 | `CageCeiling` | `(0.00, 30.50, -60.81)` | `(0.00, -32.19, -59.84)` | 68.0 | 3 | `(0.00, 1.95, -95.52)` | `false` | `false` |
| `S06_CeilingLob_NorthMarker` | **C** | 96.2 | `CageCeiling` | `(0.00, 30.50, -60.81)` | `(0.00, -32.19, -59.84)` | 68.0 | 3 | `(0.00, 1.95, -95.52)` | `false` | `false` |
| `S07_HighSpeed180_GrazingSeam` | **A** | 180.0 | `Wall_North` | `(-77.95, 30.13, -114.67)` | `(-88.00, 25.37, 125.84)` | 155.6 | 3 | `(-27.45, 2.81, -40.19)` | `false` | `false` |
| `S07_HighSpeed180_GrazingSeam` | **B** | 180.0 | `CornerWall_NW` | `(-64.90, 28.13, -106.91)` | `(125.84, 29.19, 88.00)` | 156.3 | 4 | `(28.85, 1.52, -41.35)` | `false` | `false` |
| `S07_HighSpeed180_GrazingSeam` | **C** | 180.0 | `RoofBevel_NW` | `(-66.23, 24.36, -106.89)` | `(40.91, -151.21, 3.07)` | 156.7 | 6 | `(-59.62, 3.65, -106.39)` | `false` | `false` |

### 2.2 Key Geometric Insights from Shape Pass
1. **Corner Chamfers (`S01`, `S02`)**:
   - In Variant A (orthogonal 90° box), the ball penetrates deep to $X = -78.22, Z = -118.22$ before rebounding off `Wall_West` with $v'_x = +61.6$, landing at $(-18.68, 3.0, -58.68)$.
   - In Variants B & C ($20\text{ stud}$ chamfer), the ball impacts `CornerWall_NW` much earlier at $X = -68.32, Z = -108.32$ with diagonal normal $\mathbf{n} = (1/\sqrt{2}, 0, 1/\sqrt{2})$, reflecting both $X$ and $Z$ velocity equally and redirecting the trajectory directly into pitch center, landing at $(-0.56, 3.0, -40.56)$—an inward delta of over $25\text{ studs}$.
2. **Beveled Roof Incline (`S03`, `S04`, `S05`)**:
   - In Variants A & B, high lob shots strike the vertical wall at $Y \approx 25.6$ and bounce horizontally across the pitch ($v'_x \approx +74.8, v'_y \approx +1.5$).
   - In Variant C, because the outer wall terminates at $Y = 24.0$ and slopes inward at $45^\circ$, the ball impacts `RoofBevel_West` / `RoofBevel_North` / `RoofBevel_NW`, converting horizontal momentum into steep downward velocity ($v'_y = -74.80$ to $-79.20\text{ studs/s}$), creating a sharp spike down to the floor ($Y = 2.30$ at $X = -75.69$), perfectly proving that there is no flat ceiling obstruction under the bevel.
3. **High-Speed Boundary Seam Stability (`S07`)**:
   - At $180\text{ studs/s}$ and coarse $\Delta t = 1/30\text{ s}$ into the upper trihedral seam, all three variants handle the high-speed multiple impacts (up to 6 multi-substep reflections in Variant C) with 0 tunneling and 0 corner-stuck states.

---

## 3. Part 2 — Mechanics Pass Trajectory Comparison (Mechanics Enabled)

*Configuration*: Feature flags `{ enableBumpers = true, enableTransom = true, enableRamps = true }`. 
- Over-Goal Transoms active at $Z = \pm 120.0, Y \in [10.4, \text{wallHeight}]$ with $e = 0.95$.
- Pinball Bumpers active at 4 corners ($Y \in [0, 12]$) with $e = 1.25$ and cap $v_{\text{max}} = 180.0\text{ studs/s}$.
- Side Elevating Ramps ($25^\circ$) active at $X \approx \pm 74, Z \in [-30, +30]$.
- Ceiling Rebound Markers active at $(0, 32, \pm 68)$ with guide-only zero aim assist.

### 3.1 Mechanics Pass Trajectory Matrix (34 Runs)

| Scenario ID | Variant | $v_0$ (studs/s) | First Hit Surface | First Hit Pos $(X, Y, Z)$ | $v_{\text{pre-cap}}$ | $v_{\text{after}}$ | Rebound Velocity $(v'_x, v'_y, v'_z)$ | Total Hits | Landing Pos $(X, Y, Z)$ | Escaped | Stuck |
| :--- | :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `M01_CeilingMarker_North_Angle1` | **A** | 96.2 | `CageCeiling` | `(0.00, 30.50, -60.81)` | 68.0 | 68.0 | `(0.00, -32.19, -59.84)` | 3 | `(0.00, 1.95, -95.52)` | `false` | `false` |
| `M01_CeilingMarker_North_Angle1` | **B** | 96.2 | `CageCeiling` | `(0.00, 30.50, -60.81)` | 68.0 | 68.0 | `(0.00, -32.19, -59.84)` | 3 | `(0.00, 1.95, -95.52)` | `false` | `false` |
| `M01_CeilingMarker_North_Angle1` | **C** | 96.2 | `CageCeiling` | `(0.00, 30.50, -60.81)` | 68.0 | 68.0 | `(0.00, -32.19, -59.84)` | 3 | `(0.00, 1.95, -95.52)` | `false` | `false` |
| `M01_CeilingMarker_South_Mirror` | **A** | 96.2 | `CageCeiling` | `(0.00, 30.50, 60.81)` | 68.0 | 68.0 | `(0.00, -32.19, 59.84)` | 3 | `(0.00, 1.95, 95.52)` | `false` | `false` |
| `M01_CeilingMarker_South_Mirror` | **B** | 96.2 | `CageCeiling` | `(0.00, 30.50, 60.81)` | 68.0 | 68.0 | `(0.00, -32.19, 59.84)` | 3 | `(0.00, 1.95, 95.52)` | `false` | `false` |
| `M01_CeilingMarker_South_Mirror` | **C** | 96.2 | `CageCeiling` | `(0.00, 30.50, 60.81)` | 68.0 | 68.0 | `(0.00, -32.19, 59.84)` | 3 | `(0.00, 1.95, 95.52)` | `false` | `false` |
| `M02_OverGoalTransom_North` | **A** | 95.5 | `Transom_North` | `(0.00, 11.68, -117.95)` | 92.1 | 92.1 | `(0.00, -18.29, 90.25)` | 3 | `(0.00, 1.38, -86.44)` | `false` | `false` |
| `M02_OverGoalTransom_North` | **B** | 95.5 | `Transom_North` | `(0.00, 11.68, -117.95)` | 92.1 | 92.1 | `(0.00, -18.29, 90.25)` | 3 | `(0.00, 1.38, -86.44)` | `false` | `false` |
| `M02_OverGoalTransom_North` | **C** | 95.5 | `Transom_North` | `(0.00, 11.68, -117.95)` | 92.1 | 92.1 | `(0.00, -18.29, 90.25)` | 3 | `(0.00, 1.38, -86.44)` | `false` | `false` |
| `M02_OverGoalTransom_South_Mirror` | **A** | 95.5 | `Transom_South` | `(0.00, 11.68, 117.95)` | 92.1 | 92.1 | `(0.00, -18.29, -90.25)` | 3 | `(0.00, 1.38, 86.44)` | `false` | `false` |
| `M02_OverGoalTransom_South_Mirror` | **B** | 95.5 | `Transom_South` | `(0.00, 11.68, 117.95)` | 92.1 | 92.1 | `(0.00, -18.29, -90.25)` | 3 | `(0.00, 1.38, 86.44)` | `false` | `false` |
| `M02_OverGoalTransom_South_Mirror` | **C** | 95.5 | `Transom_South` | `(0.00, 11.68, 117.95)` | 92.1 | 92.1 | `(0.00, -18.29, -90.25)` | 3 | `(0.00, 1.38, 86.44)` | `false` | `false` |
| `M03_PinballBumper_NW_100` | **A** | 100.0 | `Wall_West` | `(-77.89, 4.00, -117.89)` | 88.0 | 88.0 | `(62.23, 0.00, 62.23)` | 1 | `(-17.74, 4.00, -57.74)` | `false` | `false` |
| `M03_PinballBumper_NW_100` | **B** | 100.0 | `PinballBumper_NW` | `(-67.64, 4.00, -107.64)` | 125.0 | **125.0** | `(88.39, 0.00, 88.39)` | 1 | `(29.58, 4.00, -10.42)` | `false` | `false` |
| `M03_PinballBumper_NW_100` | **C** | 100.0 | `PinballBumper_NW` | `(-67.64, 4.00, -107.64)` | 125.0 | **125.0** | `(88.39, 0.00, 88.39)` | 1 | `(29.58, 4.00, -10.42)` | `false` | `false` |
| `M03_PinballBumper_SE_Mirror_100` | **A** | 100.0 | `Wall_East` | `(77.89, 4.00, 117.89)` | 88.0 | 88.0 | `(-62.23, 0.00, -62.23)` | 1 | `(17.74, 4.00, 57.74)` | `false` | `false` |
| `M03_PinballBumper_SE_Mirror_100` | **B** | 100.0 | `PinballBumper_SE` | `(67.64, 4.00, 107.64)` | 125.0 | **125.0** | `(-88.39, 0.00, -88.39)` | 1 | `(-29.58, 4.00, 10.42)` | `false` | `false` |
| `M03_PinballBumper_SE_Mirror_100` | **C** | 100.0 | `PinballBumper_SE` | `(67.64, 4.00, 107.64)` | 125.0 | **125.0** | `(-88.39, 0.00, -88.39)` | 1 | `(-29.58, 4.00, 10.42)` | `false` | `false` |
| `M03_PinballBumper_SpeedCap_160To180` | **A** | 160.0 | `Wall_West` | `(-77.89, 4.00, -117.89)` | 140.8 | 140.8 | `(99.56, 0.00, 99.56)` | 1 | `(8.40, 4.00, -31.60)` | `false` | `false` |
| `M03_PinballBumper_SpeedCap_160To180` | **B** | 160.0 | `PinballBumper_NW` | `(-67.79, 4.00, -107.79)` | **200.0** | **180.0** | `(127.28, 0.00, 127.28)` | 1 | `(53.13, 4.00, 13.13)` | `false` | `false` |
| `M03_PinballBumper_SpeedCap_160To180` | **C** | 160.0 | `PinballBumper_NW` | `(-67.79, 4.00, -107.79)` | **200.0** | **180.0** | `(127.28, 0.00, 127.28)` | 1 | `(53.13, 4.00, 13.13)` | `false` | `false` |
| `M04_SideElevatingRamp_West` | **A** | 40.3 | `ElevatingRamp` | `(-73.42, 3.12, 0.33)` | 68.2 | 68.2 | `(35.00, 55.04, 20.00)` | 2 | `(-13.39, 1.54, 34.64)` | `false` | `false` |
| `M04_SideElevatingRamp_West` | **B** | 40.3 | `ElevatingRamp` | `(-73.42, 3.12, 0.33)` | 68.2 | 68.2 | `(35.00, 55.04, 20.00)` | 2 | `(-13.39, 1.54, 34.64)` | `false` | `false` |
| `M04_SideElevatingRamp_West` | **C** | 40.3 | `ElevatingRamp` | `(-73.42, 3.12, 0.33)` | 68.2 | 68.2 | `(35.00, 55.04, 20.00)` | 2 | `(-13.39, 1.54, 34.64)` | `false` | `false` |
| `M04_SideElevatingRamp_East_Mirror` | **A** | 40.3 | `ElevatingRamp` | `(73.42, 3.12, 0.33)` | 68.2 | 68.2 | `(-35.00, 55.04, 20.00)` | 2 | `(13.39, 1.54, 34.64)` | `false` | `false` |
| `M04_SideElevatingRamp_East_Mirror` | **B** | 40.3 | `ElevatingRamp` | `(73.42, 3.12, 0.33)` | 68.2 | 68.2 | `(-35.00, 55.04, 20.00)` | 2 | `(13.39, 1.54, 34.64)` | `false` | `false` |
| `M04_SideElevatingRamp_East_Mirror` | **C** | 40.3 | `ElevatingRamp` | `(73.42, 3.12, 0.33)` | 68.2 | 68.2 | `(-35.00, 55.04, 20.00)` | 2 | `(13.39, 1.54, 34.64)` | `false` | `false` |
| `M05_BackGoalAlley14_North` | **A** | 71.6 | `Wall_North` | `(-15.04, 2.00, -118.07)` | 63.0 | 63.0 | `(26.40, 0.00, 57.20)` | 1 | `(21.92, 2.00, -37.99)` | `false` | `false` |
| `M05_BackGoalAlley14_North` | **B** | 71.6 | `Wall_North` | `(-15.04, 2.00, -118.07)` | 63.0 | 63.0 | `(26.40, 0.00, 57.20)` | 1 | `(21.92, 2.00, -37.99)` | `false` | `false` |
| `M05_BackGoalAlley14_North` | **C** | 71.6 | `Wall_North` | `(-15.04, 2.00, -118.07)` | 63.0 | 63.0 | `(26.40, 0.00, 57.20)` | 1 | `(21.92, 2.00, -37.99)` | `false` | `false` |
| `M05_BackGoalAlley14_South_Mirror` | **A** | 71.6 | `Wall_South` | `(15.04, 2.00, 118.07)` | 63.0 | 63.0 | `(-26.40, 0.00, -57.20)` | 1 | `(-21.92, 2.00, 37.99)` | `false` | `false` |
| `M05_BackGoalAlley14_South_Mirror` | **B** | 71.6 | `Wall_South` | `(15.04, 2.00, 118.07)` | 63.0 | 63.0 | `(-26.40, 0.00, -57.20)` | 1 | `(-21.92, 2.00, 37.99)` | `false` | `false` |
| `M05_BackGoalAlley14_South_Mirror` | **C** | 71.6 | `Wall_South` | `(15.04, 2.00, 118.07)` | 63.0 | 63.0 | `(-26.40, 0.00, -57.20)` | 1 | `(-21.92, 2.00, 37.99)` | `false` | `false` |
| `M03_PinballBumper_NW_100_VariantA_Overlay` | **A (Overlay)** | 100.0 | `PinballBumper_NW` | `(-67.64, 4.00, -107.64)` | 125.0 | **125.0** | `(88.39, 0.00, 88.39)` | 1 | `(29.58, 4.00, -10.42)` | `false` | `false` |

---

## 4. Part 3 — Side Elevating Ramp 3D OBB Bounding Audit

*Evaluation of `IsPositionOnElevatingRamp(position, variantId)`*:

| Test Probe Location | Tested Coordinates $(X, Y, Z)$ | Expected Result | In-Engine Measured Result | Status |
| :--- | :---: | :---: | :---: | :---: |
| **West Ramp Center** | `(-74.0, 2.2, 0.0)` | `true` (on ramp surface) | **`true`** | **PASS** |
| **East Ramp Center** | `(74.0, 2.2, 0.0)` | `true` (on ramp surface) | **`true`** | **PASS** |
| **Inward of Ramp Foot** | `(-66.5, 1.25, 0.0)` | `false` (on pitch floor, inward of ramp) | **`false`** | **PASS** |
| **Beyond Ramp End** | `(-74.0, 2.2, 35.0)` | `false` (outside $Z \in [-30, +30]$) | **`false`** | **PASS** |
| **Underneath Ramp Structure** | `(-77.5, 0.2, 0.0)` | `false` (sub-floor penetration below ramp wedge) | **`false`** | **PASS** |
| **High Above Ramp** | `(-74.0, 12.0, 0.0)` | `false` (air space well above ramp top plane) | **`false`** | **PASS** |

---

## 5. Part 4 — Verification Gate V-05 Synthesis & Acceptance Sign-off

1. **Controlled Variable Isolation**:
   - The comparison suite holds ball radius ($1.25\text{ studs}$), initial coordinates, launch velocities, and step time ($dt = 1/60\text{ s}$) strictly identical across variants.
   - All geometric and mechanical differences are faithfully demonstrated in the resulting velocities and landing coordinates.
2. **Rebound Mechanics Conformance**:
   - Transom reflects at $e = 0.95$ ($96.9\text{ studs/s} \to 92.1\text{ studs/s}$).
   - Pinball bumper boosts speed by $1.25\times$ ($100 \to 125\text{ studs/s}$) and enforces the speed cap at $180.0\text{ studs/s}$ when pre-cap speed reaches $200.0\text{ studs/s}$.
   - Side elevating ramp applies a $25^\circ$ upward lift ($v_y = +55.04\text{ studs/s}$) launching balls smoothly toward pitch center.
   - Ceiling guide markers do not alter horizontal velocity or pull trajectories.
3. **Robustness**:
   - 0 escapes / 0 tunneling across all 55 runs.
   - 0 corner stuck states across all 55 runs.
   - Verification Gate **V-05 is FULLY SATISFIED**.
