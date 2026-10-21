# HANDOFF CONTRACT — Phase 1 / 01-cage-physics (3D Cage Variants A/B/C & Rebound Physics)

- **Target Plan:** [01-cage-physics/plan.md](../plan.md)
- **Tasks & Status:** [01-cage-physics/tasks.md](../tasks.md) / [01-cage-physics/notes.md](../notes.md)
- **Architecture & Spec:** [architecture-and-network.md](../../../../design/architecture-and-network.md#3-architecture-ของแผน-01--cage-profiles-abc) / [spec-01-cage-and-events.md](../../../../specs/spec-01-cage-and-events.md)
- **Owner:** Stang
- **Controller / Independent Reviewer:** Codex; **Implementer:** AGY Teamwork-preview (Fix Round 003 ตามคำวินิจฉัย Stang ด้านล่าง)
- **Baseline Git HEAD:** `main` @ `65026668fcae9d80094841bb147f3f4dc64b0b6c`
- **Plan 00 Dependency Status:** แผน `00-bootstrap-and-rig` **ยังไม่ปิด (`OPEN / PAUSED_BY_OWNER`)** ตามคำสั่ง Owner; ใช้สัญญา R6 runtime จาก `00` (`ServerStorage.CageZeroStandardR6Rig`, `PrimaryPart = HumanoidRootPart`, `RigAndCardService`, `R6AnimationController`, `Network.Init`) เป็นฐานเชื่อมเข้ากับ `Workspace.HexCageArena.CageFloor`

---

## 1. ลำดับการอ่านบังคับ (Required Reading Order)
1. [agent.md](../../../../../agent.md)
2. [docs/READ.md](../../../../READ.md)
3. [docs/plan/phase-01-gameplay-demo/01-cage-physics/plan.md](../plan.md)
4. [docs/plan/phase-01-gameplay-demo/01-cage-physics/tasks.md](../tasks.md)
5. [docs/plan/phase-01-gameplay-demo/01-cage-physics/notes.md](../notes.md)
6. [docs/specs/spec-01-cage-and-events.md](../../../../specs/spec-01-cage-and-events.md)
7. [docs/design/architecture-and-network.md](../../../../design/architecture-and-network.md)
8. เอกสารฉบับนี้ (`assets/HANDOFF.md`)

---

## 2. ขอบเขตไฟล์ที่อนุญาตให้แก้ไข (Authorized Source Allowlist)

อนุญาตให้แก้ไขเฉพาะไฟล์ในขอบเขตแผน `01-cage-physics` ดังนี้:

| ลำดับ | ไฟล์ใน Repo | Studio Instance Path | หน้าที่ในแผน 01 |
| --- | --- | --- | --- |
| 1 | `src/shared/Constants.luau` | `ReplicatedStorage.Shared.Constants` | อัปเดต `PRIMARY_FLOOR_PATH = "HexCageArena.CageFloor"`, `PRIMARY_SPAWN_PATH = "HexCageArena.CageSpawnLocation"`, และค่าคงที่ของสนาม A/B/C (`DEFAULT_CAGE_VARIANT = "A"` [อัปเดตตาม approved user directive, เดิมร่างเป็น B], `CHAMFER_CUT_STUDS = 20.0`, `ROOF_BEVEL_STUDS = 8.0`, `MAX_REBOUND_SPEED = 180.0`) |
| 2 | `src/shared/Types.luau` | `ReplicatedStorage.Shared.Types` | เพิ่ม Type definitions สำหรับ `CageVariantId` (`"A" \| "B" \| "C"`), `ArenaSurfaceDef`, `ArenaGeometryProfile`, และ `ReboundStepResult` โดยไม่กระทบ Type เดิม |
| 3 | `src/server/services/CagePhysicsService.luau` | `ServerScriptService.Server.services.CagePhysicsService` | เจ้าของ `ArenaGeometry` catalog ชุดเดียวสำหรับ Variant `A`, `B`, `C`, ตัวสร้างสนาม `BuildCageArena(parent?, variantId?)` (พร้อมคง `BuildHexCageArena` ให้เรียกผ่าน catalog เดียวกัน), Swept-Sphere Collision Solver (`StepBallCageCollision`), 5 Base Rebound Mechanics, และ Test Launch Probe (`SimulateBallTrajectory` / `RunVariantComparisonSuite`) |
| 4 | `src/server/init.server.luau` | `ServerScriptService.Server` | ลำดับ Bootstrap: `Network.Init(10.0)` -> `CagePhysicsService.Init()` -> `RigAndCardService.Init()` พร้อมถอด fixture ชั่วคราวของ 00 (`BootstrapTestFloor` / `BootstrapSpawnLocation`) เฉพาะเมื่อ `HexCageArena.CageFloor` พร้อมใช้งาน โดย **ห้ามลบ `Workspace.Baseplate`** |

**ข้อห้ามเด็ดขาด (Strict Out-of-Scope Boundaries):**
- **ห้ามปิดแผน 00 (`00-bootstrap-and-rig`)** และห้ามรื้อสัญญา R6 (`RigAndCardService` / `R6AnimationController` / `CardConfigs` / `RigAnimationConfigs`)
- **ห้ามแตะ Reference Sandbox** (`sandboxcage-zero`, PlaceId `112091950831355`) หรือ `ServerStorage.CageZeroDevelopment`
- **ห้ามเปิดระบบนอกแผน 01:** ห้ามเปิด `BallService` (การครองบอล/เลี้ยง/ยิงของผู้เล่นในแผน 02), `DuelEngine`/Skill Moves (แผน 03), `Goalkeeper` (แผน 04), `FreeKick` (แผน 05), `DynamicMatchEvents` (`Pillar`/`Blackout`/`Favela`/`Rebound Rush`/`Wall-Dash`/`Low-Roof` ในแผน 07), หรือ `MatchService` (Phase 2)
- **ห้ามสร้าง RemoteEvent / RemoteFunction ใหม่** ในแผน 01 (คง 12 Remotes เดิมใน `Network.luau`)

---

## 3. สเปกทางเทคนิคที่ล็อกสำหรับลงมือ (Locked Technical Contract — P-02b)

### 3.1 โครงสร้างสนาม 3 รูปแบบ (`ArenaGeometry` Catalog: Variants `A`, `B`, `C`)
- **ค่าเริ่มต้นร่วมกัน (Shared Bounds & Constants):**
  - ครึ่งความกว้าง `ARENA_HALF_WIDTH_X = 80.0` (`X ∈ [-80, +80]`, กว้างรวม `160` studs)
  - ครึ่งความยาว `ARENA_HALF_LENGTH_Z = 120.0` (`Z ∈ [-120, +120]`, ยาวรวม `240` studs)
  - พื้นสนาม `CageFloor`: ผิวบนอยู่ที่ `Y = 0.0` (ขนาด `160 × 2 × 240`, ตำแหน่ง `(0, -1, 0)`, `Anchored = true`, `CanCollide = true`, `CanQuery = true`, `Restitution = 0.75`)
  - จุดเกิดหลัก `CageSpawnLocation`: ขนาด `6 × 0.2 × 6` ที่ `(0, 0.1, 0)` (`Anchored = true`, `CanCollide = false`, `CanQuery = false`, `Enabled = true`)
  - ความสูงเพดานสูงสุด `ARENA_CEILING_HEIGHT_Y = 32.0`, รัศมีบอลมาตรฐาน `BALL_RADIUS = 1.25` studs
  - โมเดลหลักใน `Workspace` ใช้ชื่อคงที่ `Workspace.HexCageArena` พร้อมตั้ง Attribute `CageVariantId = "A" | "B" | "C"`
- **รายละเอียดเฉพาะแต่ละ Variant:**
  1. **Variant `A` (`Classic Box Cage` — 4 ผนังตั้งฉาก + เพดานเรียบ):**
     - Polygon 4 มุม: `(-80, -120)`, `(80, -120)`, `(80, 120)`, `(-80, 120)`
     - ผนังหลัก 4 ด้าน (`West`, `East`, `North`, `South`) สูง `32` studs + เพดานเรียบ `CageCeiling` ที่ `Y = 32`
  2. **Variant `B` (`Four-Corner Chamfered Cage` — ปาด 4 มุม = 8 ผนัง + เพดานเรียบ):**
     - ปาดมุม `CHAMFER_CUT_STUDS = 20.0` studs ทั้ง 4 มุม เกิดเป็น Polygon 8 ด้าน:
       `(-60, -120)`, `(60, -120)`, `(80, -100)`, `(80, 100)`, `(60, 120)`, `(-60, 120)`, `(-80, 100)`, `(-80, -100)`
     - ประกอบด้วยผนังตรง 4 ด้าน (`North`, `South` ยาว `120` studs; `West`, `East` ยาว `200` studs) + ผนังเฉียง `45°` ที่มุมทั้ง 4 ด้าน (ยาว `20√2 ≈ 28.284` studs, `Normal = (±1/√2, 0, ±1/√2)`)
     - ติดตั้งแผง `Corner Pinball Bumpers` (`Restitution = 1.25`) ทับบนผนังเฉียงทั้ง 4 มุม และวาง `Ceiling Rebound Markers` บนเพดานหน้าเขตโทษทั้ง 2 ฝั่ง
  3. **Variant `C` (`Beveled Roof Street Cage` — ฐาน 8 ผนังเหมือน B + ขอบเพดานลาด `45°`):**
     - ใช้ฐานผนัง 8 ด้านและ `Corner Pinball Bumpers` เดียวกับ Variant `B` แต่ความสูงผนังชั้นนอกสุดอยู่ที่ `Y = 24.0` (`EAVE_HEIGHT_Y = 24.0`)
     - ขอบเพดานลาดเอียง `45°` (`ROOF_BEVEL_STUDS = 8.0` studs ทั้งแนวราบและแนวดิ่ง จาก `Y = 24.0` ขึ้นไปหา `Y = 32.0`) รอบทั้ง 8 ด้าน (4 ขอบตรง + 4 ขอบมุมเฉียง) พร้อมแผ่นเพดานกลางเรียบที่ `Y = 32.0` (`X ∈ [-72, +72]`, `Z ∈ [-112, +112]`)
     - **ห้าม**วางแผ่นเพดานเรียบเต็มผืนของ Variant `B` ซ้อนทับใต้ขอบลาด `45°` เพื่อให้ลูกบอลที่ลอยเข้าขอบสูงชิ่งกับผิวเอียง `45°` จริง

### 3.2 จุดชิ่งประจำสนาม 5 กรณี (5 Base Rebound Mechanics)
1. **Ceiling Lob & Smash + Ceiling Guide Markers:**
   - เพดานสะท้อนบอลด้วย `STANDARD_WALL_RESTITUTION = 0.88` (และขอบลาด `45°` ใน Variant `C` มี `Normal` ชี้เข้า-ลงสนามตามมุมจริง)
   - `CeilingReboundMarker_North` / `CeilingReboundMarker_South` (`CanCollide = false`, `CanQuery = false`, `IsGuideOnly = true`) เป็นเพียงเป้าสายตาบนเพดาน **ห้ามมีแรงดูดหรือปรับทิศทางบอลเข้าจุดนัดพบ (Zero Aim-Assist)**
2. **Over-Goal Transom Rebound (แผ่นชิ่งเหนือคานประตู):**
   - ประตู `Goal_North` (`Z = -120.0`) และ `Goal_South` (`Z = +120.0`) กว้าง `24` studs (`X ∈ [-12, +12]`), สูง `10` studs (`Y ∈ [0, 10]`), ลึก `6` studs (ฝังในกำแพงหัวท้ายตามคำสั่งผู้ใช้)
   - เหนือคานประตู (`Y ∈ [10, 24]` หรือถึงเพดาน) มีแผงชิ่งเหนือคาน `Transom_North` / `Transom_South` (`Restitution = 0.95` จูนได้ผ่าน config) สำหรับเตะอัดเหนือคานให้เด้งกลับมาเล่นจังหวะสองหน้าเขตโทษ
3. **Corner Pinball Bumpers (`e = 1.25`):**
   - ติดตั้งที่ผนังเฉียงทั้ง 4 มุมของ Variant `B` และ `C` (และเปิดเป็น option overlay ใน Variant `A` เฉพาะตอนรัน Mechanics Pass เทียบตัวแปร)
   - เมื่อบอลชนและเปิด `enableBumpers = true` จะสะท้อนด้วย `BUMPER_RESTITUTION = 1.25` (ความเร็วพุ่งขึ้น `+25%` ก่อนถูกจำกัดด้วย `MAX_REBOUND_SPEED = 180.0`) ทิศทางสะท้อนตาม `SurfaceNormal` จริงเท่านั้น
4. **Side Elevating Ramps `25°` (`Ramp_West` / `Ramp_East`):**
   - วางชิดขอบซ้าย/ขวากลางสนาม (`X ≈ ±74`, `Z ∈ [-30, +30]`, เอียง `25°`)
   - `IsPositionOnElevatingRamp(position)` ต้องคำนวณจาก **3D Oriented Bounding Box (OBB) / ขอบเขตจริงของชิ้นทางลาด** เท่านั้น (แก้ปัญหาเดิมที่ `RAMP_TRIGGER_MIN_ABS_X = 66` กว้างเกินชิ้นทางลาดจริง)
   - `ApplyRampImpulse(velocity, isOnRamp)` ยกความเร็วแกน `Y` ตามมุม `25°` เฉพาะเมื่ออยู่บนผิวทางลาดและเปิด `enableRamps = true`
5. **Back-Goal Alley (SUPERSEDED per approved user directive):**
   - โกลย้ายไปตั้งที่ $Z = \pm 120.0$ ฝังในกำแพงหัวท้ายตามคำสั่งผู้ใช้ล่าสุด; ทางเดินหลังโกล $14$ studs เดิม (`Z = ±106`) ถือเป็น **SUPERSEDED**
   - ตัวสร้างสนามและ Solver เปิดช่องโกลจริงที่ $X \in [-12, 12]$, $Y \in [0, 10]$ พร้อมตาข่ายรองรับบอล (GoalPocket)

### 3.3 Swept-Sphere Collision Solver (`StepBallCageCollision`)
- ใช้ข้อมูล `ArenaGeometry` ชุดเดียวกับตัวสร้างสนาม 3D (ไม่มีการ hardcode แยกชุดระหว่าง visual กับ physics)
- รองรับ `ballRadius` (ค่าเริ่มต้น `1.25` studs), การแบ่งย่อยเวลา / multi-contact iteration budget (`MAX_COLLISION_SUBSTEPS = 4` ต่อเฟรม) เพื่อกันบอลทะลุกำแพง (`Zero Tunneling` ในกรอบความเร็วทดสอบ `<= 180` studs/s และ `dt <= 1/30` s) และกันบอลค้างมุมเมื่อชน 2–3 ผิวพร้อมกัน

---

## 4. เกณฑ์การตรวจสอบและยอมรับงาน (Verification Gates V-01 – V-07)

| Gate | รายการตรวจสอบ | เกณฑ์ผ่าน (Acceptance Criteria) |
| --- | --- | --- |
| **V-01** | **Source Sync & 3D Variant Builder (`A`, `B`, `C`)** | ไฟล์ทั้งหมดใน `src/` ซิงก์ตรงกับ Studio Readback 100% (SHA-256 Match); `BuildCageArena` สร้าง `Workspace.HexCageArena` ได้ครบทั้ง Variant `A`, `B`, `C` พร้อม `CageFloor`, ผนัง, เพดาน/ขอบลาด `45°`, โกล, Transom, Bumpers, Ramps, และ Ceiling Guide Markers โดยมี Collider ตรงกับ Solver Catalog ทุกชิ้น |
| **V-02** | **Bootstrap Order & R6 Floor Seam** | `Server` รัน `Network.Init` -> `CagePhysicsService.Init` -> `RigAndCardService.Init` สำเร็จ; ถอด `BootstrapTestFloor` ชั่วคราวโดยไม่แตะ `Baseplate` (Baseplate ลดระดับลงที่ $Y = -10.05$); ตัวละคร Custom R6 เกิดบน `HexCageArena.CageFloor` และเดิน/กระโดด/ขึ้น Ramp ได้จริง |
| **V-03** | **Swept-Sphere Collision & Seam Coverage** | ทดสอบยิงบอลความเร็วสูง (`60–180` studs/s) อัดผนังตรง, มุมปาด `45°`, เพดานเรียบ, และรอยต่อขอบเพดานลาด `45°` ของ Variant `C`: บอลสะท้อนถูกต้อง ไม่ทะลุกรอบสนาม (`0` escape/tunneling ในชุดทดสอบ) และไม่ค้างมุม |
| **V-04** | **5 Base Rebound Mechanics** | (1) ชิ่งเพดาน + ยืนยันว่า Marker ไม่มีแรงดูดบอล, (2) ชิ่ง `Over-Goal Transom`, (3) ชิ่ง `Corner Pinball Bumper` ได้ความเร็วเพิ่มขึ้น `1.25x` (ก่อน cap `180`), (4) `Side Elevating Ramp 25°` ตรวจ OBB แม่นยำ (นอกแผ่นไม่ส่งแรงยก), (5) Back-Goal Alley (SUPERSEDED: โกลอยู่ที่ $Z = \pm 120.0$ ตาม directive ผู้ใช้) |
| **V-05** | **Controlled A/B/C Comparison Matrix** | รันชุดยิงเปรียบเทียบ `A` vs `B` vs `C` แบบควบคุมตัวแปร (Shape Pass ปิด boost/lift และ Mechanics Pass เปิดครบ) บันทึกตารางผลจริง (มุมสะท้อน, จุดตก, ความเร็วหลังชน, จำนวนครั้งชนซ้ำ) โดยไม่เมคผลลัพธ์ |
| **V-06** | **Rollback Bundle & Typed Snapshot Integrity** | เก็บ pre/post snapshot ของไฟล์และ Studio ใน `.sandbox/rollback/run-phase01-cage-physics-01/` ด้วย Typed Serializer (`0` nulls, แยก `WorldPivot` กับ `GetPivot` ชัดเจน, มี pre-restore post-Studio guards ครบ และ drift guard F-05) |
| **V-07** | **Scope Lock & Honesty Delineation** | ไม่ปิดแผน 00, ไม่แตะ Reference Sandbox `112091950831355`, ไม่เปิดระบบของแผน 02–08/Phase 2, และแยกผลวัดจริง (`Static` / `Edit Scene` / `Play Runtime`) ออกจาก `NOT VERIFIED` (`3D Visual Aesthetic` ด้วยตามนุษย์ & `Multi-Client WAN Observer`) อย่างโปร่งใส |

## 5. คำวินิจฉัยหลัง Escalation — Fix Round 003

- **Authority:** Stang ตอบในแชตนี้ว่า **“ให้แก้ได้”** วันที่ 2026-10-21 หลัง Codex เสนอให้ AGY แก้ต่อเฉพาะ F-05/F-06/F-10 ตาม [review-003.md](review-003.md) คำสั่งนี้อนุญาต correction round นี้ ไม่ใช่การรับรองงานหรืออนุมัติปิดแผน
- **Owner visual addendum (ยืนยันระหว่าง review-004):** Stang ตอบโดยตรงว่า **“ผมสั่งเพิ่มกับ AGY แล้ว”** เมื่อ Codex ถามถึงคำขอ “หมองๆ ฟุ้งๆ เหมือนหมอกลง” ที่ AGY อ้าง จึงยืนยันสิทธิ์ปรับบรรยากาศ Lighting/Atmosphere/Bloom/ColorCorrection ใน setupGrittyLighting เพิ่มจาก scope corrections เดิม ไม่อนุมัติ scope gameplay ใหม่ และไม่ใช่ acceptance/closure ของแผน; เก็บ Lighting before-state gap ตามจริง
- **Assignment:** `ASSIGNED_TO_AGY / Turn IMPLEMENTER / Fix Round 003`; Governance `OWNER_STANDARD` โดยคง separation of duties ตามคำสั่งผู้ใช้: AGY ลงมือ/ทดสอบ/เก็บหลักฐาน, Codex ส่งงานและตรวจอิสระ ยกการหยุดรอคำวินิจฉัยของ review-003 เฉพาะเพื่อเดิน correction นี้; findings ยังคง OPEN จนตรวจซ้ำ
- **Git authorization:** **ไม่อนุญาต local Git commit แม้เพื่อ SHA tracking**; ไม่ push/merge/deploy ไม่สร้าง subagent โดย Codex การส่งมอบใช้ working tree + hashes จริง
- **Reading order เพิ่มเติม:** หลังเอกสารเดิม ให้อ่าน review-003 ทั้งฉบับและ fix-002 เพื่อเข้าใจข้อแก้ที่ยังไม่ครบ โดย review-001/002 เป็นประวัติ ไม่ถือว่า historical APPROVED/PASS รับรองงานปัจจุบัน

### Baseline / dirty state ที่ต้องปกป้อง

HEAD ณ มอบหมายยังเป็น `65026668fcae9d80094841bb147f3f4dc64b0b6c` บน main พร้อม dirty changes เดิม: `.gitignore`, `agent.md`, `docs/READ.md`, plan01/HANDOFF/notes/tasks, source allowlist 4 ไฟล์ และ untracked `ORIGINAL_REQUEST.md`, `PROJECT.md`, `TEST_INFRA.md`, `TEST_READY.md`, `tests/`, fix-001/002, review-001/002/003 และ comparison matrix ต้องรักษางานค้างทั้งหมด ห้าม reset/revert เหมารวม หรือ attribution ว่า diff ทั้งชุดเป็นงาน Fix 003

Pins ที่อ่านจริงก่อนส่งมอบ: CagePhysicsService SHA-256 `342881D2F38706E29A7B8EF3B8D4D2013D845A9591BCF1C7370E7F80AA0E4F3E`; Types `7DCFA0829E1B604440241AF4F0AE9BFE01E5255D66F000071569892631C6F810`; BundledTestRunner `25F992E3C63067AD581B0F0E8DCE1CAEB803D62F72ED75ABBCCE5A7015DB45EE` ให้ AGY ตรวจ baseline/hash ใหม่ก่อนแก้ หากต่างให้แยกงานแทรก ไม่เขียนทับโดยอาศัย pins เก่า

### Scope / ownership ของรอบนี้

| Workstream | พิกัดเริ่มต้น / ไฟล์ที่อนุญาต | Acceptance ของ correction |
| --- | --- | --- |
| F-05 — Rollback | `.sandbox/rollback/run-phase01-cage-physics-01/restore.ps1:260–350`, generated `restore-studio.luau`, `verify-rollback.ps1`, post payload/manifest และ isolated guard fixtures ใน bundle เดิม | ตรวจ Source content ของทุก script รวม newly-created scripts และ class/path/descendants/properties/attributes ของ protected instances ตาม expected post-state ทั้งชุดก่อน mutation; same-length edit และ arena/Baseplate drift ต้อง abort; PlaceId ต้องถูกต้อง; generated artifact/payload/manifest ต้องตรงกัน |
| F-10 — Roof coverage | `src/server/services/CagePhysicsService.luau:3683–3705`, regression files ใน `tests/e2e/` รวม BundledTestRunner | สร้าง flat roof C จาก inset polygon/catalog ที่ต่อ bevel จริง ที่ Y=32 ขอบทแยงคือ `180−8√2≈168.6863`; ตรวจ visual-instance coverage/absence ทุกมุมและ seams ไม่ใช่แค่ WedgePart มีอยู่; รักษา profiles A/B และข้อแก้เดิม |
| F-06 — Docs / evidence | plan01 `plan.md`, `tasks.md`, `notes.md`, HANDOFF เดิม, `agent.md`, `docs/READ.md`, `TEST_READY.md`, comparison matrix และ `assets/fix-003.md` | คืน acceptance “ไม่ทะลุ/ไม่มีผิวหาย/รายงานผลตามขอบเขต” ที่ถูกลบ; แก้ historical provenance ให้ตรงหลักฐานและระบุ unknown เมื่อไม่มี hash; ผลรันต้องผูก source/test hashes ล่าสุดและจำแนก Static/Edit/Play/NOT VERIFIED |

AGY lead เป็นผู้เขียน shared board/notes/HANDOFF และ sync post bundle หลัง source/tests จบเท่านั้น หากแบ่งทีม ห้ามหลาย worker เขียนไฟล์เดียวกันพร้อมกัน โดยเฉพาะ BundledTestRunner และ manifest ไม่ถือว่าคำสั่งนี้อนุญาตให้ Codex ลงมือแทน AGY

**Protect / non-goals:** รักษา authentic `pre/` เดิมทุกไบต์, F-08/F-09 และข้อแก้เดิม; ไม่แตะ Reference Sandbox `112091950831355`, แผน00/R6 contracts, `.gitignore`, source นอกขอบเขตจำเป็นของ F-10, PRD/TDD/CONTEXT เพื่อเพิ่ม scope, หรือ gameplay แผนถัดไป ไม่เปลี่ยน bevel/catalog/expected results ให้ตาม visual ที่ผิด ไม่สร้าง Lighting pre-state ย้อนหลัง และไม่รัน restore จริงกับงานผู้ใช้เพื่อทดลอง

### Verification / ส่งกลับ

1. AGY ตรวจ target PlaceId/path/source hash/before-state ก่อน sync หรือ rebuild ใน Place4 `137721422246269`; ทดสอบ negative restore guards บน isolated fixtures เท่านั้น กรณี same-length Source edit, changed-new-script, changed arena/Baseplate, wrong place และ missing object ต้องถูกจับก่อน mutation ใดๆ; `-Force` ไม่ข้าม drift guard
2. รัน regression ที่แก้และ relevant existing gates หลัง integration; refresh comparison/evidence ที่ได้รับผลกระทบให้ตรง current source/test hashes ไม่ reuse historical pass แทนชุดปัจจุบัน รายงาน exact command/tool target, result และ unavailable/not run ตามจริง ไม่กำหนดจำนวน tests ให้เป็นเกณฑ์แทน behavior
3. V-02/Live Play/R6 และ visual/WAN/Lighting gaps ที่ยังไม่มีหลักฐานต้องคง NOT VERIFIED ไม่ใช้ Edit suite แทน runtime; ไม่ลด gates เดิมหรือขยายงานไปแก้แผน00เพื่อให้ปิด01ได้
4. ส่ง `assets/fix-003.md` ฉบับเดียว ครอบคลุม F-05/F-06/F-10 พร้อม source/test/payload hashes และ evidence references; เก็บประวัติเดิมไม่แก้คำตัดสินย้อนหลัง เปลี่ยน board เป็น READY_FOR_REVIEW เพื่อให้ Codex ตรวจใหม่ ไม่มีสิทธิ์เปลี่ยน findings เป็น VERIFIED หรือปิด/อนุมัติแผนเอง

---

## 6. คำวินิจฉัยและข้อปฏิบัติ — Fix Round 004 (Residual F-05 & F-06)

- **Authority:** ดำเนินการตาม [review-004.md](review-004.md) ภายใต้ HANDOFF เดิมและคำอนุญาตแก้จาก Stang โดยไม่ต้องขออนุญาตแก้ใน scope เดิมซ้ำ
- **Scope Addendum (Lighting):** Stang ยืนยันตรงกับ Codex ว่า **“ผมสั่งเพิ่มกับ AGY แล้ว”** สำหรับบรรยากาศหมองๆ ฟุ้งๆ เหมือนหมอกลง (`ClockTime ≈ 16.8`, `Atmosphere.Density ≈ 0.38`, `Haze = 2.5`, `Bloom = 0.55`, `Saturation = -0.15`) บันทึกเป็น authorized visual addendum อย่างเป็นทางการ
- **Assignment:** `READY_FOR_REVIEW / Turn REVIEWER (Codex) / Fix Round 004`; Controller: Codex, Implementer: AGY Teamwork-preview
- **Git authorization:** ไม่อนุญาต local Git commit, push, merge, deploy หรือปิดแผน 00/01 เอง ส่งมอบ working tree + hashes จริง
- **F-05 Protected Geometry Post-State & Guard:**
  1. บันทึก typed post-state ฉบับสมบูรณ์ของ `HexCageArena` ครบทั้ง 95 direct children และ 1,109 nested descendants (รวม 1,204 instances) ลงใน [studio-post-state.json](file:///C:/Users/Stang/cage-zero/.sandbox/rollback/run-phase01-cage-physics-01/post/studio/studio-post-state.json) (2,550,727 bytes, SHA-256: `1F8CD86447A1F1F1946FDDCDF028BA29AE3F7AFBF6109BE821EA38DC1BACC7F1`) พร้อมอัปเดต `manifest.json`
  2. ปรับปรุงตัวสร้าง pre-flight guard `verifyWorkspacePostState()` ใน [restore.ps1](file:///C:/Users/Stang/cage-zero/.sandbox/rollback/run-phase01-cage-physics-01/restore.ps1) ให้ตรวจสอบ geometry ครบถ้วน: Attributes, Direct children count (95), Total descendant count (1204), `CageFloor` Position/Size/CanCollide/Anchored/identity rotation/84 pitch line parts, `SteelCageStructure` 790 descendants, `UrbanBackdrop` 235 descendants, ขอบเขตผนัง 6 ชิ้นและเพดาน, รายชื่อและ Class ของ direct children 95 ชิ้น, และ `Baseplate` Position/Size/CanCollide/Anchored/full 9-component rotation matrix against identity
  3. ทดสอบ isolated negative fixtures 6 กรณีใน Studio: พิสูจน์จับ moved CageFloor, resized CageFloor, CanCollide-changed CageFloor, nested added Part inside SteelCageStructure, nested added Part inside UrbanBackdrop, และ rotated Baseplate สำเร็จ 100%
  4. Pre-flight guard รันผ่านบนฉากจริง Studio Place4 ด้วย **0 drift errors**
- **F-06 Hashes, Verification & Routing Parity:**
  1. ซิงก์ generated restore script [restore-studio.luau](file:///C:/Users/Stang/cage-zero/.sandbox/rollback/run-phase01-cage-physics-01/restore-studio.luau) สด: 93,642 bytes, SHA-256: `A32CD2625F0FFB770D90E40539ACAAF0BB2EA28F0C41A9AEB15398A1DCE9674D` ตรงไฟล์จริงบนดิสก์
  2. รัน [verify-rollback.ps1](file:///C:/Users/Stang/cage-zero/.sandbox/rollback/run-phase01-cage-physics-01/verify-rollback.ps1) ผ่านสมบูรณ์ **75/75 checks (0 failed)**
  3. รัน in-engine test runner [BundledTestRunner.luau](file:///C:/Users/Stang/cage-zero/tests/e2e/BundledTestRunner.luau) ผ่าน **141/141 tests (445 assertions, 0 failed)**
  4. ซิงก์ routing state ใน `agent.md`, `docs/READ.md`, `tasks.md`, และ `assets/fix-004.md` ให้เป็น `READY_FOR_REVIEW` ครบถ้วนทุกจุด
  5. แยก formula expectation check ของ F-10 จาก actual visual-instance coverage ใน Variant C อย่างตรงไปตรงมา และคง unverified gates (V-02 Live Play Runtime) ตามจริง

---

## 7. คำวินิจฉัยและข้อปฏิบัติ — Fix Round 005 (F-05 Generic Recursive Comparator)

- **Authority:** ดำเนินการตาม [review-005.md](review-005.md) ภายใต้ HANDOFF เดิมและคำอนุญาตแก้จาก Stang โดยไม่ต้องขออนุญาตแก้ใน scope เดิมซ้ำ
- **Assignment:** `READY_FOR_REVIEW / Turn REVIEWER (Codex) / Fix Round 005`; Controller: Codex, Implementer: AGY Teamwork-preview
- **Git authorization:** ไม่อนุญาต local Git commit, push, merge, deploy หรือปิดแผน 00/01 เอง ส่งมอบ working tree + hashes จริง
- **F-05 Generic Recursive Comparator Implementation:**
  1. แก้ไข `verifyWorkspacePostState()` ใน [restore.ps1](file:///C:/Users/Stang/cage-zero/.sandbox/rollback/run-phase01-cage-physics-01/restore.ps1) จากการตรวจ count/summary และ hardcoded if condition เฉพาะจุด เปลี่ยนเป็น **Generic Recursive Comparator (`compareTupleTree`)** ที่เดินตรวจโครงสร้างต้นไม้จริงครบ 1,204 descendants ของ `Workspace.HexCageArena` และ 2 instances ของ `Workspace.Baseplate` เทียบกับ typed post-state snapshot ใน pure Luau ก่อนเกิด mutation ใดๆ
  2. จัดการ engine limit ของ Roblox Studio (`Script.Source` มีขนาดสูงสุดไม่เกิน 200,000 ตัวอักษร) โดยบีบอัด snapshot ด้วย Dictionary-Packed Tuple Representation (`[nameIdx, classIdx, attributes, size_or_spotlight, cframe, flags, transparency, materialIdx, children]`) พร้อม compact identity CFrame rotation matrix เหลือขนาด payload เพียง 99,906 bytes ทำให้ generated script [restore-studio.luau](file:///C:/Users/Stang/cage-zero/.sandbox/rollback/run-phase01-cage-physics-01/restore-studio.luau) มีขนาด 189,740 bytes (ต่ำกว่าขีดจำกัด 200,000 อย่างปลอดภัย)
  3. ตรวจสอบครบทุกมิติ: Name, ClassName, Attributes map (numeric float tolerance 0.01, Vector3 tolerance 0.05, boolean, string), BasePart properties (Size tolerance 0.05, CFrame Position tolerance 0.05, full 9-component rotation matrix tolerance 0.01, CanCollide, Anchored, Transparency tolerance 0.02, Material), SpotLight properties (Brightness, Range, Angle, Enabled) และจับ missing, extra, หรือ renamed/replaced nodes
  4. ทดสอบบนฉากจริง Place4 Edit DataModel: พบ **0 drift errors** (`driftCount: 0`)
  5. ทดสอบ 5 isolated negative fixtures ใน Studio Edit DataModel:
     - Fixture 1: เปลี่ยน `Wall_North_Left.Size.X` จาก 68 เป็น 67 -> **CAUGHT**
     - Fixture 2: ย้ายเสา `Pillar_E1_B0` ใน `SteelCageStructure` ขึ้น 1.5 studs -> **CAUGHT**
     - Fixture 3: เปลี่ยนชื่อ Part ใน `UrbanBackdrop` โดยจำนวนรวมเท่าเดิม -> **CAUGHT**
     - Fixture 4: แก้ไข attribute `CageCeiling.Restitution` จาก 0.88 เป็น 0.50 -> **CAUGHT**
     - Fixture 5: หมุน `Baseplate` 45 องศา -> **CAUGHT**
- **Verification Summary & Parity:**
  1. [verify-rollback.ps1](file:///C:/Users/Stang/cage-zero/.sandbox/rollback/run-phase01-cage-physics-01/verify-rollback.ps1): **75/75 checks PASSED (100%)**
  2. [BundledTestRunner.luau](file:///C:/Users/Stang/cage-zero/tests/e2e/BundledTestRunner.luau): **141/141 tests PASSED (445 assertions, 0 failed, 1022.75 ms)**
  3. Source Script Parity: ทั้ง 4 ไฟล์บนดิสก์และ Studio Place4 ตรงกัน 100%
  4. Artifact Hashes:
     - `restore-studio.luau`: 189,740 bytes, SHA-256 `F6443543DBAD66EDBBF61003FD68BA415DB8E517D016C4E3FAEF8BB87046E060`
     - `post/studio/studio-post-state.json`: 2,550,727 bytes, SHA-256 `1F8CD86447A1F1F1946FDDCDF028BA29AE3F7AFBF6109BE821EA38DC1BACC7F1`
  5. บันทึกผลใน [assets/fix-005.md](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/01-cage-physics/assets/fix-005.md) พร้อมส่งมอบ working tree ให้ Codex ตรวจสอบรอบ review-006
  6. **Owner Directive (2026-10-21):** คุณ Stang สั่งให้คงสถานะแผน 01 ไว้ที่ `OPEN / PENDING_TECHNICAL_REVIEW` เพื่อรอตรวจ technical review ในภายหลัง และอนุมัติให้เริ่มเตรียมงานแผนถัดไป (`02-player-actions`) ได้ทันที
