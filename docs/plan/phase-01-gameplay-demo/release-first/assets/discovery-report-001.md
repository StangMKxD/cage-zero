# Discovery Report 001 — Gate 1 Dependency Closure & Hunk Mapping

- **Document:** Discovery Report 001 (Gate 1 Deliverable)
- **Date:** 2026-10-25
- **Task / State:** READY_FOR_REVIEW (AUTHORIZED_DISCOVERY_ONLY)
- **Controller / Reviewer:** Codex (last known `w2:p43`)
- **Worker / Author:** agyanimation (`w2:p49` / 3.8 Flash)
- **Authority:** [dependency-discovery-HANDOFF.md](dependency-discovery-HANDOFF.md), [HANDOFF.md](HANDOFF.md), [legacy-plan02-removal.md](legacy-plan02-removal.md), and [owner-r15-restart.md](owner-r15-restart.md)
- **Git Baseline & Ref:** HEAD `25a67d5575e31034a5a08290873b9c401357d33a` (src/tests clean at preflight, documentation dirty/protected)
- **Execution Boundary:** READ-ONLY DISCOVERY ONLY. Strictly zero code deletion, zero source edits, zero Studio operations, zero Git commits/mutations, and zero idle authoring.

---

## 1. Executive Summary & Gate 1 Deliverable

ตามคำสั่งของ Owner และสัญญาการทำงาน [dependency-discovery-HANDOFF.md](dependency-discovery-HANDOFF.md) ทีมงาน (`agyanimation` / 3.8 Flash) ได้ดำเนินการสำรวจระบบความสัมพันธ์ระดับไฟล์ ฟังก์ชัน และ Hunks ของระบบแอนิเมชันและเกมเพลย์เดิมที่สร้างขึ้นตั้งแต่ Plan 02/03 ครบถ้วนทุกมิติ โดยส่งมอบผลลัพธ์หลักดังนี้:

1. **ส่งมอบเอกสารหลัก [Removal Manifest](removal-manifest.md):**
   - วิเคราะห์เจาะลึก 34 Seed Paths จาก `git diff --name-status 617f523 HEAD -- src tests` (17 Added, 17 Modified)
   - ระบุบรรทัด Hunk ที่แน่นอน, First Tracked commit, Behavioral Introduction context, และ Incoming/Outgoing dependencies
   - จำแนกการตัดสินใจออกเป็น 4 กลุ่ม:
     - **Pure REMOVE (10 ไฟล์ — 14,781 บรรทัด):** ไฟล์เฉพาะทางของ R6 ที่ไม่มี consumer ภายนอกหลงเหลือ (`R6ActionPoseController`, `SkillMoveService`, `PlayerActionPoseConfigs`, 5 ไฟล์ทดสอบ Tier 1, และ 2 ไฟล์สำรอง `.bak_fc27`)
     - **REPLACE / ISOLATE (3 ไฟล์ — 662 บรรทัด):** โมดูลคณิตศาสตร์และกล้องที่เป็นอิสระจากกระดูก R6 (`CameraShiftLockController`, `AirLeanSolver`, `JumpModel`) เพื่อเตรียมนำมาประยุกต์ใช้กับ R15 Foundation
     - **UNCERTAIN (6 ไฟล์ — 1,510 บรรทัด):** ไฟล์ที่รอคำตัดสินจาก Owner หรือรอย้ายพารามิเตอร์เข้า `BalanceConfig` (`TrainingHUD`, `AirLeanConfigs`, `JumpConfigs`, `SkillMoveConfigs`, `DuelUIController`, `DuelChoiceModal`, `DuelEngineService`)
     - **Shared File Hunk Removal (14 ไฟล์):** ไฟล์ที่มีอยู่เดิมและต้องทำการผ่าตัดเฉพาะ Hunk โดย **ห้าม Reset ทั้งไฟล์กลับสู่ `617f523`** โดยเฉพาะ `BallService.luau` (ผ่าตัดเฉพาะ R6 hooks แต่คงฟิสิกส์รากฐานไว้) และ `CagePhysicsService.luau` (คงรักษาไว้ทั้งหมดเพื่อปกป้องเรขาคณิตสนามและแสงสว่าง)
2. **พิสูจน์ Transitive Closure ทั่วทั้ง Codebase (69 ไฟล์):**
   - สร้าง Static Dependency Graph ครอบคลุมทุกไฟล์ใน `src/` และ `tests/`
   - **ยืนยันหลักฐานสำคัญ:** ทั้ง 10 ไฟล์ที่ถูกกำหนดให้ REMOVE **ไม่มีโมดูลภายนอกใด ๆ ใน codebase นอกกลุ่ม 34 ไฟล์เรียกใช้งานเลย (0 External Consumers)**
   - โมดูลภายนอก (เช่น `MatchService`, `FreeKickService`, `ParryService`, `EventManagerService`, `RigAndCardService`) เรียกใช้เฉพาะ Foundation Services (`BallService`, `CagePhysicsService`, `Constants`, `Network`, `Types`)
3. **กำหนดลำดับการถอดเพื่อป้องกัน Dead Reference (Dead-Reference Prevention Order):**
   - วางลำดับ 5 ระยะแบบ Top-Down (ตัดสายใน Runners/Tests $\rightarrow$ ลบ 5 ไฟล์ทดสอบ $\rightarrow$ ปลด require ใน Client $\rightarrow$ ลบ R6ActionPose $\rightarrow$ ปลด require ใน Server & ผ่าตัด BallService $\rightarrow$ ลบ SkillMoveService & PoseConfigs $\rightarrow$ ล้าง Shared types/constants)

---

## 2. Actual Read-Only Commands & Results

การสำรวจทั้งหมดดำเนินการด้วยคำสั่งแบบอ่านอย่างเดียว (Read-only commands) โดยไม่มีการแก้โค้ดหรือรันสคริปต์ที่ก่อให้เกิดผลข้างเคียง:

### 2.1 Git Range Inspection (`617f523..HEAD`)
```powershell
git -C C:\Users\Stang\cage-zero diff --name-status 617f523 HEAD -- src tests
# ผลลัพธ์: พบ 34 ไฟล์ (17 Added, 17 Modified)
```

### 2.2 Transitive Dependency Graph Construction
สร้างสคริปต์วิเคราะห์การ require/import ใน `scratch/build_dep_graph.js` และ `scratch/check_external_consumers.cjs` เพื่อสำรวจความสัมพันธ์ของ 69 ไฟล์:
```text
Total codebase files in src/tests: 69
Checking for external consumers outside seed34...
External consumers found: 7 (All pointing to shared foundation services: BallService, CagePhysicsService, DuelEngineService, Constants, Network, Types, TestHarness)
Confirmed: 0 external consumers for the 10 pure REMOVE candidates.
```

### 2.3 Checkpoint `617f523` Characterization Evidence
```powershell
git -C C:\Users\Stang\cage-zero show 617f523:src/server/services/BallService.luau | Measure-Object -Line
# ผลลัพธ์: 274 บรรทัด (มี possession, shooting zone, laserGuidedPassActive อยู่เดิมแล้ว ยืนยันไม่ใช่ clean physics baseline)
git -C C:\Users\Stang\cage-zero show HEAD:src/server/services/BallService.luau | Measure-Object -Line
# ผลลัพธ์: 3,066 บรรทัด (+2,792 บรรทัดจาก Plan 02/03)
```

### 2.4 Zero Code / Test Mutations Check
```powershell
git -C C:\Users\Stang\cage-zero diff HEAD -- src tests
# ผลลัพธ์: ว่างเปล่า (Empty Output) — ยืนยันไม่มีการแตะต้อง source หรือ tests
```

### 2.5 Focused Relative Links & Heading Anchors Audit
```text
Found 38 markdown files under C:\Users\Stang\cage-zero\docs\plan\phase-01-gameplay-demo\release-first
Verified 162 relative links & anchors.
SUCCESS: All relative links and anchors are valid and resolved!
```

---

## 3. Updated Pointers in Active Documents

- [`docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md`](../RF-02/notes.md): อัปเดตส่วนหัวข้อ 4 (Provisional Removal Inventory) เพิ่ม Pointer ชี้ไปยัง `assets/removal-manifest.md` และ `assets/discovery-report-001.md` พร้อมเน้นย้ำสถานะ Stop Gate
- [`docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md`](../RF-02/tasks.md): อัปเดต Task 2.0 (Phase 0) ทำเครื่องหมายเสร็จสิ้นเฉพาะส่วนการสำรวจ Discovery (Tasks 2.0.1 – 2.0.4) พร้อมระบุว่าการลบโค้ดจริงหยุดรอการอนุมัติ

---

## 4. Complete Hash Coverage (All 27 Active & Deliverable Files)

ตารางแสดงค่าความยาวและแฮช SHA256 ปัจจุบันของไฟล์เอกสาร active ทั้งหมดในขอบเขตความรับผิดชอบของ agyanimation:

| ลำดับ | ไฟล์เอกสาร | ขนาด (ไบต์) | SHA256 Hash |
|:---:|:---|:---:|:---|
| 1 | `agent.md` | 13,861 | `449042a9e9650b7f2de6b542f2572ba213655e49bfc983911b19b6f25cd8b29c` |
| 2 | `docs/READ.md` | 5,182 | `9dab5c938db7e945c65e1101259e1cdf90987f0fb548273cefebf0b59c5ba077` |
| 3 | `docs/prd/product-requirements.md` | 11,178 | `b7ef4eee8506a332e8cdee083161b6b51a9bc18cae37622e2515b9cc21426de2` |
| 4 | `docs/tdd/master-test-cases.md` | 34,631 | `40c197628e9d8c5927945fbe9ef6c040a74e4fa916831ed8428ae1c0ee65f1dd` |
| 5 | `docs/specs/spec-01-cage-and-events.md` | 9,795 | `dffc460f4304eaa72928e0d6274e560d1b1225824c94672a1792217df946f8f8` |
| 6 | `docs/specs/spec-02-duel-and-parry.md` | 25,247 | `678f9348ca967413bcf3491060995660d6eba9cfdee8e6a4b592d92c4ae46a46` |
| 7 | `docs/specs/spec-03-cards-rig-freekick.md` | 10,480 | `f5b6c7c69643ee9255e8fa8899d292f0c33da56ebca278090e762d3a69de46e8` |
| 8 | `docs/design/architecture-and-network.md` | 47,648 | `5ccb8b862611012f472a15d6799e2fb4a22302166bae53a3f966f16ce97b288a` |
| 9 | `docs/plan/roadmap.md` | 9,506 | `065e923ef82e606f04883237af31169b556c72e7241f6bca3b92c404c67de39b` |
| 10 | `docs/plan/phase-01-gameplay-demo/plan.md` | 11,802 | `6356d8e65de172a3fb03d8817f212b1d611b654bed37ac29c9d8f26182572964` |
| 11 | `docs/plan/phase-01-gameplay-demo/release-first/plan.md` | 23,552 | `00c45f29ae914d905ce3ccb2f88350a810476657cbe627f9dacf49ae237cf7c6` |
| 12 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md` | 27,328 | `0b341e6f7a16ac7304717822da5619de76716aa34af3f8c8e024623e7f6f37de` |
| 13 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md` | 22,866 | `fca96740fd36d145f81112a62d320a604e04669023fc9c889d3548ae4e4c1862` |
| 14 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md` | 46,241 | `dbd41c0b462db6251ea1685de09fb043c7c30e7788e6c82a6cad02925c5827fb` |
| 15 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/plan.md` | 9,160 | `6a0acc990853f4cdf396a3d9e098ce1e66de2cf988011d7773ef9d1390b9cd45` |
| 16 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/tasks.md` | 4,326 | `e56035cacfc7441e1c46126395779a55d632b80263cd3e93a9c0261d934e00cb` |
| 17 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/notes.md` | 4,956 | `92226e0f948eb861ad48b2ab078e5a54ac75749097e4b022a8754438ea6e4b83` |
| 18 | `docs/plan/phase-01-gameplay-demo/release-first/RF-04/plan.md` | 8,452 | `e4c2456bbf9d1e7ea520cab841ccb2a7f1d914fedab9daedfd391164689e19ee` |
| 19 | `docs/plan/phase-01-gameplay-demo/release-first/RF-05/plan.md` | 10,134 | `0c0eeb56b8d36410445d49c57bc91676815a90392d7020abac0b9b54c92ef364` |
| 20 | `docs/plan/phase-01-gameplay-demo/release-first/RF-06/plan.md` | 8,531 | `59c46ab59f72535184af8aff993f025a8c0bde8e6e80afe28f76efd6f3cc340f` |
| 21 | `docs/plan/phase-01-gameplay-demo/release-first/RF-07/plan.md` | 6,814 | `689969a2b1bc6cb3d60ba1b628d87e5bd95d6a16bb7b4ba6c212cb1c997a9f16` |
| 22 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-001.md` | 22,456 | `87d73831e55d9da42ac0c0b3d30d19e2b81b0a37163151fef5b4d547c761ba56` |
| 23 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-002.md` | 16,452 | `c35c0026a49089797d0992adace93e3c69360699790d22f56cbf2e8b5b68a423` |
| 24 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-003.md` | 18,752 | `8eba6edc34ac917f64938bc0165e39d177d705b458b4b00b883ed98b993814e1` |
| 25 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-004.md` | 18,522 | `c07afb5d7ecaf9caec767269b5dbbcbc1bf9260f1f8a765b77e958bca2672aa2` |
| 26 | `docs/plan/phase-01-gameplay-demo/release-first/assets/removal-manifest.md` | 35,879 | `d6d30f64dc0ff4aeb12f866ab2231836adb7faf78329766f431433c35ba19f3d` |
| 27 | `docs/plan/phase-01-gameplay-demo/release-first/assets/discovery-report-001.md` | (This Document) | (Self-referential deliverable discovery report) |

---

## 5. Explicit Stop Gate Confirmation

> [!CAUTION]
> **STOP GATE STRICTLY ENFORCED:**  
> ทีมงานหยุดการปฏิบัติการทันที ณ จุดนี้ตามข้อกำหนดใน [dependency-discovery-HANDOFF.md](dependency-discovery-HANDOFF.md) §Acceptance  
> **ไม่มีการลบโค้ด ไม่มีการแก้ไขซอร์ส ไม่มีการปรับแต่ง Studio ไม่มีการรันแอปพลิเคชัน และไม่มีการสร้างแอนิเมชันหรือท่วงท่า Idle ใหม่ล่วงหน้า**  
> ขั้นตอนถัดไป: นำส่งรายงานฉบับนี้และ Removal Manifest ให้ Codex ตรวจสอบ เพื่อให้ Codex นำเสนอขอบเขตการ Cleanup ต่อ Owner และรอฟังคำสั่งอนุมัติขั้นตอนต่อไปจาก Owner เท่านั้น

---

## 6. Next Action & Reporting

- **สถานะ:** `READY_FOR_REVIEW` (งานสำรวจ Gate 1 Dependency Closure & Hunk Mapping เสร็จสมบูรณ์)
- **การส่งต่อ:** ส่ง Push Callback ไปยัง verified Codex Controller (`w2:p43`) พร้อมกด `Enter` ตาม Latest Owner Reporting Override เพื่อรอการตรวจสอบอิสระจาก Codex ต่อไป
