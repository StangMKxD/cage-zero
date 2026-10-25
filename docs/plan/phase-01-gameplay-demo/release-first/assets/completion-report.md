# Release-First Track & R15 Restart — Completion Report

- **Date:** 2026-10-25
- **Task:** Owner Override & Owner Delta — R15 Restart, Legacy 02/03 Cancellation, Legacy Runtime Removal Manifest & Global Synchronization
- **Implementer (Docs):** agyplan w2:p49
- **Controller / Reviewer:** Codex w2:p43
- **Owner:** Stang
- **State:** DOCUMENTATION_COMPLETED / AWAITING_OWNER_INSPECTION (Runtime Implementation NOT AUTHORIZED)

---

## 1. คำสั่งและการตอบสนองต่อ Directives

### 1.1 Owner Directive (2026-10-25)
- **ยกเลิก Legacy Plan 02 (`02-player-actions`) และ 03 (`03-dribble-duel`)**: มีสถานะเป็น `CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART` ยุติ task queue เดิม (Codex เป็นผู้ใส่ cancellation banners ทั้ง 6 ไฟล์)
- **เริ่ม Release-First Track บน Custom Blocky R15**: สร้างโครงสร้างเอกสารแผนใหม่ทั้งหมด 6 แผน (`RF-02` ถึง `RF-07`) มุ่งสู่ Public Alpha
- **รักษาประวัติศาสตร์ครบถ้วน**: เก็บ source, assets, animation-library, reviews, fixes, และ unresolved findings (A-01..A-06, F-13..F-24) ไว้ครบถ้วน ไม่ย้อน Git หรือลบประวัติ

### 1.2 Owner Removal Delta (2026-10-25 & `legacy-plan02-removal.md`)
- **การถอด Runtime เก่าของ 02/03 ออกจริง**: กำหนดให้ RF-02 มี **Phase 0: Legacy Plan 02/03 Removal & Cleanup Gate** จัดทำ Removal Manifest แบบ READ-ONLY (จัดหมวดหมู่ File/Symbol/Hunk: KEEP, REMOVE, REPLACE, UNCERTAIN)
- **รักษา Foundation แผน 00/01**: ห้ามลบ `BallService.luau` หรือ `CagePhysicsService.luau` เหมารวม โดยถอดเฉพาะ Hunk ของ 02 ออกจาก `BallService.luau` เพื่อคืนสู่สภาพ baseline ของ Plan 01 (`617f523`)
- **นโยบายโมเดลลงมือภายหลัง**: ผู้ลงมือถอดโค้ดจริงคือ `agyanimation` ใช้ **3.8 Flash** เป็นหลักเมื่อยืนยัน pane identity แล้ว; ใช้ **Argon** เฉพาะจุดติดขัดด้าน dependency ที่ซับซ้อนตามที่ Flash แสดงหลักฐานปัญหา

---

## 2. รายการไฟล์ที่สร้างและปรับปรุง (Changed Files)

### 2.1 ไฟล์ที่สร้างขึ้นใหม่ใน Release-First Track (20 ไฟล์)
1. `docs/plan/phase-01-gameplay-demo/release-first/plan.md` — แผนแม่บท Release-First Track, Legacy Mapping, และ Definition of Done
2. `docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md` — แผน Core Football & R15 Foundation พร้อมส่วน Removal & Cleanup Strategy
3. `docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md` — รายการงาน RF-02 ละเอียด รวมถึง Phase 0: Removal & Cleanup Gate
4. `docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md` — บันทึกประวัติ, Reuse evaluation, และ Removal Manifest Table
5. `docs/plan/phase-01-gameplay-demo/release-first/RF-03/plan.md` — แผน R15 Skill Moves & Defense (3 ท่าเปิดตัว, 3 ช่อง, Body Check evaluation)
6. `docs/plan/phase-01-gameplay-demo/release-first/RF-03/tasks.md` — รายการงาน RF-03
7. `docs/plan/phase-01-gameplay-demo/release-first/RF-03/notes.md` — บันทึกการจัดการ 3 ท่าเปิดตัว vs 4 ท่าที่เก็บใน catalog
8. `docs/plan/phase-01-gameplay-demo/release-first/RF-04/plan.md` — แผน Cage Slingshot (Stadium A, Wall Run, Wall Launch, Air Intercept)
9. `docs/plan/phase-01-gameplay-demo/release-first/RF-04/tasks.md` — รายการงาน RF-04
10. `docs/plan/phase-01-gameplay-demo/release-first/RF-04/notes.md` — บันทึกตัวแปรจูนเนอร์ Wall Launch (1.7x, 28 studs, 0.20s windup/landing)
11. `docs/plan/phase-01-gameplay-demo/release-first/RF-05/plan.md` — แผน Character Gacha, 13 Outfield Stats, และ 3–4 Active Traits
12. `docs/plan/phase-01-gameplay-demo/release-first/RF-05/tasks.md` — รายการงาน RF-05
13. `docs/plan/phase-01-gameplay-demo/release-first/RF-05/notes.md` — บันทึกนโยบายความปลอดภัย Cash-only Gacha
14. `docs/plan/phase-01-gameplay-demo/release-first/RF-06/plan.md` — แผน Match, HUD & Economy (Casual 2v2, Concise HUD, 1 Cosmetic Shop)
15. `docs/plan/phase-01-gameplay-demo/release-first/RF-06/tasks.md` — รายการงาน RF-06
16. `docs/plan/phase-01-gameplay-demo/release-first/RF-06/notes.md` — บันทึกวงจร Casual 2v2 และ Minimal viable economy
17. `docs/plan/phase-01-gameplay-demo/release-first/RF-07/plan.md` — แผน Publish Gate (ProcessReceipt Idempotency, 4-Player UAT, Owner Publish)
18. `docs/plan/phase-01-gameplay-demo/release-first/RF-07/tasks.md` — รายการงาน RF-07
19. `docs/plan/phase-01-gameplay-demo/release-first/RF-07/notes.md` — บันทึก Owner Publish Prerogative
20. `docs/plan/phase-01-gameplay-demo/release-first/assets/completion-report.md` — รายงานสรุปฉบับนี้

### 2.2 ไฟล์ระบบส่วนกลางที่ได้รับการปรับปรุงอย่างเจาะจง (Narrow Global Sync — 13 ไฟล์)
1. `agent.md` — อัปเดต Latest Dispatch (Owner Override & Removal Delta), Active Phase เป็น Release-First, Target Rig เป็น Custom Blocky R15, Model policy (3.8 Flash default / Argon exception)
2. `docs/READ.md` — เพิ่มหัวข้อ OWNER-OVERRIDE-20261025 ชี้ไปยัง Release-First Track และ RF-02, ระบุสถานะ legacy 02/03 ถูกยกเลิก
3. `docs/plan/roadmap.md` — เพิ่ม Release-First Track (Active Target) และบันทึกคำสั่ง R15 restart
4. `docs/plan/phase-01-gameplay-demo/plan.md` — เพิ่มตาราง Release-First Track (`RF-02`..`RF-07`) ควบคู่กับประวัติแผนเดิม
5. `docs/plan/phase-02-full-match-and-progression/plan.md` — บันทึกความชัดเจนว่า Phase 2 ยังคงอยู่ครบถ้วน (ไม่ถูกยกเลิก) แต่เลื่อนไปทำหลัง Public Alpha โดยรากฐาน Profile และ Cash Gacha ถูกดึงมาเริ่มใน RF-02/05/06
6. `docs/prd/product-requirements.md` — อัปเดตข้อกำหนด Rig เป็น Custom Blocky R15, Cage Slingshot, 3 Launch Skills, 13 Outfield Stats, และ 3-4 Active Traits
7. `docs/design/architecture-and-network.md` — บันทึกการเปลี่ยน Target Rig เป็น R15 ใน Release-First และการคงประวัติข้อค้าง A-01..A-06
8. `docs/design/data-schema.md` — เพิ่มโครงสร้าง ReleaseFirstPlayerProfile schema ใน Section 1.6
9. `docs/tdd/master-test-cases.md` — ปรับ [INV-02] เป็น Custom Blocky R15 และเพิ่มชุดเกณฑ์ตรวจรับ `TC-RF02` ถึง `TC-RF07`
10. `docs/specs/spec-01-cage-and-events.md` — ระบุการใช้ Stadium A เป็นสนามหลักของ Public Alpha เพื่อรองรับ Cage Slingshot
11. `docs/specs/spec-02-duel-and-parry.md` — ระบุการเปลี่ยนสู่ Custom Blocky R15 และ 3 Launch Skills (Heavy Knock-On, Open Up Fake Shot, Body Feint)
12. `docs/specs/spec-03-cards-rig-freekick.md` — ระบุ Target Rig ใหม่เป็น Custom Blocky R15 พร้อมรักษาประวัติ R6
13. `docs/specs/spec-05-ui-navigation-and-hud.md` — ระบุการใช้ Concise HUD ใน RF-06 แทน Full UI Shell

### 2.3 ไฟล์ที่ได้รับการคุ้มครองและไม่มีการแก้ไขเด็ดขาด (Protected Files)
- 6 ไฟล์ Legacy Plan 02/03 (`plan/tasks/notes`) ที่มี banner ของ Codex
- `docs/plan/phase-01-gameplay-demo/release-first/assets/owner-r15-restart.md`
- `docs/plan/phase-01-gameplay-demo/release-first/assets/legacy-plan02-removal.md`
- `docs/plan/phase-01-gameplay-demo/release-first/assets/HANDOFF.md`
- โค้ดทั้งหมดใน `src/`, `tests/`, และ assets (คงสภาพเดิม 100% ไม่มีการแก้โค้ดหรือ Git ในรอบนี้)

---

## 3. สรุป Legacy Plan 02/03 Removal Manifest (Preflight Baseline)

อิงตามประวัติ Git ระหว่าง Baseline `617f523bb2529a2ec40bfb1107de5f6a32a208ae` ถึง HEAD `25a67d5575e31034a5a08290873b9c401357d33a`:

| การจัดหมวดหมู่ | รายการไฟล์ / ออบเจกต์ | แนวทางการปฏิบัติการ (เมื่อได้รับอนุมัติลงมือ) |
|---|---|---|
| **KEEP** | `src/server/services/CagePhysicsService.luau`<br/>`src/server/services/RigAndCardService.luau`<br/>`src/client/character/R6AnimationController.luau` (Baseline)<br/>`docs/plan/phase-01-gameplay-demo/02-player-actions/assets/*`<br/>`docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/*` | **ห้ามลบ/ห้ามย้อนประวัติ**: รักษาฟิสิกส์สนาม A/B/C, ระบบ bootstrap rig และเอกสารประวัติศาสตร์/assets เดิมทั้งหมด |
| **REMOVE** | `src/client/character/R6ActionPoseController.luau`<br/>`src/server/services/SkillMoveService.luau`<br/>`src/shared/configs/PlayerActionPoseConfigs.luau`<br/>`src/client/controllers/InputController.luau.bak_fc27`<br/>`src/server/services/BallService.luau.bak_fc27`<br/>`tests/e2e/Tier1_*.luau` (5 ไฟล์ R6) | ถอดถอนไฟล์ออกทั้งหมดเนื่องจากผูกกับข้อจำกัด R6 และไม่มี consumer อื่น |
| **HUNK REMOVE** | `src/server/services/BallService.luau`<br/>`src/client/controllers/InputController.luau`<br/>`src/server/init.server.luau`<br/>`src/client/init.client.luau`<br/>`src/shared/Network.luau`, `Types.luau`, `Constants.luau` | **ห้ามลบทั้งไฟล์**: ถอดเฉพาะ Hunk ที่เพิ่มใน 02/03 คืนสภาพ `BallService` สู่ baseline ของ 01 เพื่อเก็บเรขาคณิตและการเชื่อมต่อ CagePhysics ไว้สมบูรณ์ |
| **REPLACE** | `src/shared/AirLeanSolver.luau`<br/>`src/shared/JumpModel.luau`<br/>`src/client/controllers/CameraShiftLockController.luau` | เก็บตรรกะคณิตศาสตร์เพื่อนำมาเป็นต้นแบบสร้างใหม่บน Custom Blocky R15 |
| **UNCERTAIN** | `src/client/controllers/TrainingHUD.luau`<br/>`src/shared/configs/SkillMoveConfigs.luau` | คัดแยกคอนฟิก 3 ท่าเปิดตัวเข้า `BalanceConfig` ก่อนตัดสินใจขั้นสุดท้าย |

---

## 4. ข้อขัดแย้งและการจัดการ (Conflicts & Resolutions)

1. **R6 vs R15 Rig Decision:**
   - *Conflict:* เอกสารเก่าระบุการใช้ Custom R6 ตลอด Phase 1
   - *Resolution:* คำสั่ง Owner Directive 2026-10-25 ถือเป็นอำนาจสูงสุดในการ Override ยกเลิก R6 สำหรับ Plan 02/03 และเริ่มต้น Release-First Track บน Custom Blocky R15 โดยเอกสารเก่าคงไว้เป็นประวัติศาสตร์อ้างอิง
2. **Whole File Deletion vs Hunk Reversion:**
   - *Conflict:* มีความเสี่ยงที่จะเกิดการลบ `BallService.luau` หรือ `CagePhysicsService.luau` ทั้งไฟล์
   - *Resolution:* กำหนดกฎเหล็กใน Removal Manifest ว่า `CagePhysicsService` เป็น KEEP 100% และ `BallService` เป็น HUNK REMOVE คืนสภาพเฉพาะ Hunk ของ 02 เพื่อรักษาฟิสิกส์สนามของ 01 ไว้
3. **Execution Safety:**
   - *Conflict:* คำสั่งถอดโค้ดอาจถูกตีความว่าให้ลงมือลบไฟล์ทันที
   - *Resolution:* ปฏิบัติตามคำสั่งและข้อกำหนดอย่างเคร่งครัด รอบนี้เป็น **Documentation Only** ไม่อนุญาตให้ถอดโค้ดจริงจนกว่า Owner จะตรวจรับ Manifest

---

## 5. การตรวจสอบความสอดคล้อง (Verification & Integrity)

- **Git Status:** ไฟล์ที่ถูกแก้ไขเป็นไฟล์เอกสาร Markdown เท่านั้น ไม่มีไฟล์ `.luau` ถูกแก้ไขหรือลบ
- **Link & Heading Anchors:** ทุกลิงก์ภายใน `release-first/` และ global docs ถูกต้องตามโครงสร้างจริง
- **Protection Compliance:** 6 ไฟล์ legacy 02/03 และไฟล์ directive/handoff ของ Codex ไม่ถูกแตะต้อง

---

## 6. คำแนะนำสำหรับ Owner (How to Check)

Owner สามารถตรวจสอบความถูกต้องของเอกสารได้จากลำดับดังนี้:
1. ตรวจสอบแผนแม่บท: `docs/plan/phase-01-gameplay-demo/release-first/plan.md`
2. ตรวจสอบแผนรากฐานและ Removal Manifest: `docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md`, `tasks.md`, และ `notes.md`
3. ตรวจสอบแผนสกิล R15: `docs/plan/phase-01-gameplay-demo/release-first/RF-03/plan.md`
4. ตรวจสอบแผน Cage Slingshot: `docs/plan/phase-01-gameplay-demo/release-first/RF-04/plan.md`
5. ตรวจสอบการซิงก์ส่วนกลาง: `agent.md`, `docs/READ.md`, และ `docs/plan/roadmap.md`

*(เมื่อ Owner ตรวจสอบเสร็จสิ้นและให้ความเห็นชอบ จึงจะสามารถส่งมอบงานให้ `agyanimation` บน 3.8 Flash ดำเนินการถอดโค้ดตาม Removal Manifest ต่อไป)*
