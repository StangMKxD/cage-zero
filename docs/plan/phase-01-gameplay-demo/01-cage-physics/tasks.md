# Tasks — 01-cage-physics

**Phase 1 | OPEN / PENDING_TECHNICAL_REVIEW (Fix Round 005 complete; technical check held for later by Owner) | Controller: Codex | Implementer: AGY Teamwork-preview**
Owner Stang · Controller Codex · Implementer AGY Teamwork-preview
Baseline `main` @ `65026668fcae9d80094841bb147f3f4dc64b0b6c` (แผน `00-bootstrap-and-rig` คงสถานะ `OPEN / PAUSED_BY_OWNER`, แผน `01` ยังไม่ปิด คงสถานะ `OPEN / PENDING_TECHNICAL_REVIEW`)
**Review Board: PENDING_TECHNICAL_REVIEW | Fix Round 005 | Turn OWNER / CODEX** — แก้ไข F-05 เสร็จสมบูรณ์ด้วย Generic Recursive Comparator (fix-005.md); Owner (คุณ Stang) สั่งพักรอ technical review ภายหลัง โดยยังไม่ปิดแผน 01 และอนุมัติให้เริ่มเตรียมงานแผนถัดไป 02-player-actions; สิทธิ์แก้ scope เดิมคงเดิม ห้าม commit/push/merge/deploy
[Plan](plan.md) · [HANDOFF](assets/HANDOFF.md) · [Spec](../../../specs/spec-01-cage-and-events.md) · [Architecture](../../../design/architecture-and-network.md)

## Planning & Contract Lock

- [x] P-01: phase layout และ scope สนามเดิม
- [x] P-02a: บันทึกคำสั่งเพิ่ม A/B/C; ผู้ใช้เลือก B/C 8 ผนัง และ physics + marker ไกด์
- [x] P-02b: ล็อก geometry catalog/API delta/verification matrix (`V-01`–`V-07`)/target baseline ใน [assets/HANDOFF.md](assets/HANDOFF.md)
- [x] P-03: Implementation executed per HANDOFF and approved directives; fix rounds fix-001 & fix-002 conducted for review findings F-01..F-10; pending Codex re-review & Owner sign-off (แผน 00 ยังคง `OPEN / PAUSED`)

## Implementation Queue (T-01 – T-99)

- [x] T-01: สร้าง `ArenaGeometry` catalog ชุดเดียวและ `BuildCageArena(parent?, variantId?)` รองรับ 3 profiles (`A` Classic Box 4 ผนัง, `B` Chamfered 8 ผนัง, `C` Bevel Roof 45° 8 ผนัง) พร้อมตั้ง `Workspace.HexCageArena` และ `CageFloor` (F-01/F-02: แบ่ง Wall_North/South ซ้าย-ขวา เปิดปากโกล และเพิ่ม GoalPocket)
- [x] T-02: อัปเกรด Swept-Sphere Collision Solver (`StepBallCageCollision`) บน finite surfaces, มุมปาด 8 ด้าน, รอยต่อเพดานลาด 45° ของ Variant C (F-04 parity), post corner TOI solver (F-03), multi-contact step budget (`MAX_COLLISION_SUBSTEPS = 4`), และ GoalPocket restitution 0.40 priority (F-08/F-09/F-10)
- [x] T-03: 구현 5 Base Rebound Mechanics: (1) Ceiling Lob/Smash + Ceiling Guide Markers (ไม่มีแรงดูดบอล), (2) Over-Goal Transom Rebound, (3) 4 Corner Pinball Bumpers (`e = 1.25`), (4) Side Elevating Ramps `25°` (ตรวจ OBB ขอบจริง), และ (5) Back-Goal Alley (SUPERSEDED: โกลย้ายไป $Z = \pm 120.0$ ตาม directive ผู้ใช้)
- [x] T-04: สร้าง Test Launch Probe (`SimulateBallTrajectory` / `RunVariantComparisonSuite`) สำหรับรัน Shape Pass และ Mechanics Pass เปรียบเทียบ A/B/C แบบควบคุมตัวแปร โดยไม่เปิด `BallService` gameplay
- [x] T-05: เชื่อมรอยต่อ Bootstrap & Floor Seam จากแผน 00 (`Network.Init` -> `CagePhysicsService.Init` -> `RigAndCardService.Init`, ชี้ `PRIMARY_FLOOR_PATH = "HexCageArena.CageFloor"`, ถอด `BootstrapTestFloor` ชั่วคราวโดยไม่แตะ `Baseplate`; Baseplate ลดระดับลงที่ $Y = -10.05$)
- [x] T-98: เก็บ Typed Rollback Snapshot (`.sandbox/rollback/run-phase01-cage-physics-01/`), ซิงก์และยืนยัน SHA-256 readback, เพิ่ม drift guard / payload check / Studio pre-flight check ใน restore.ps1 (F-05), รัน 141 E2E tests และ audits ใน Roblox Studio Place4 Edit DataModel
- [x] T-99: อัปเดตเอกสาร บันทึก fix-005.md และส่งสรุปผลการตรวจสอบให้ Codex/Owner เพื่อ re-review (ไม่ปิดแผน 00/01 และไม่ปิดงานเองโดยพลการ)

## ขอบเขตและการปกป้อง (Governance & Protection)

- Fix 005: **READY_FOR_REVIEW** — แก้ไข F-05 เสร็จสมบูรณ์ด้วย Generic Recursive Comparator; ส่ง `assets/fix-005.md` และ working tree พร้อม hashes ให้ Codex ตรวจซ้ำ รักษา F-01..F-04, F-06..F-10 และข้อแก้เดิมครบถ้วน; ห้าม commit/push/merge/deploy หรืออนุมัติปิดแผนเอง

- แผน `00-bootstrap-and-rig` ยังไม่ปิด (`OPEN / PAUSED_BY_OWNER`) ตามคำสั่งของ Stang
- Event pillars/ripple/swinging signs/Rebound Rush/Wall-Dash/Low-Roof เป็นงานของแผน `07-dynamic-field-events` ไม่ทำแทรกในแผน `01`
- ปกป้อง Reference Sandbox (`112091950831355`), `.gitignore`, และประวัติ `.sandbox/rollback/` ทุกชุด
