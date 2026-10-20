# 07-meta-ui — UI แมตช์ Collection และร้านค้า

- **Phase:** 2; **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **Transaction prerequisite:** [02-transactions](../02-transactions/plan.md) ต้องพร้อมก่อนเปิดรายการ Cash/ไอเทมของแผนนี้
- **ข้อสรุปกติกา:** [accepted decisions](../../phase-01-gameplay-demo/01-cage-physics/notes.md)
- **Prerequisites:** [00-match-flow](../00-match-flow/plan.md), [01-match-tiebreak](../01-match-tiebreak/plan.md), [03-player-gacha-and-stats](../03-player-gacha-and-stats/plan.md), [04-collection-and-economy](../04-collection-and-economy/plan.md), [05-effect-gacha](../05-effect-gacha/plan.md), [06-market](../06-market/plan.md)
- **Hard gate:** ต้องจบและตรวจรับ Phase 1 ครบก่อน ห้ามเปิดงานแผนนี้ระหว่างเก็บ phase แรก

## Scope
- หน้าทีม/เริ่ม–จบแมตช์/เวลา/ผล/โหวต และหน้าLocker/สุ่มตัวละคร/สุ่มสกิล/Skill Inventory-Loadout/Stats/สุ่มเอฟเฟค/สลายแต้ม/ตลาด
- เชื่อมกับ UI gameplay จาก Phase 1 ผ่าน router เดิม ไม่สร้าง UI คำนวณเงินหรือผลแมตช์เอง
- ระบบตั้งค่าฉบับใช้งานจริง รวมการบันทึก/คืนค่าตามที่ออกแบบภายหลัง ย้ายมาจากข้อเสนอDebugตามคำสั่งผู้ใช้2026-10-20; [Phase1/06](../../phase-01-gameplay-demo/06-training-ground/plan.md)ทำเฉพาะเครื่องมือจูนและเสกDummyในtestsession
- รายละเอียดหน้าตั้งค่า/ค่ารวมเกมหรือค่ารายผู้เล่น/สิทธิ์และpersistenceให้grillเมื่อเปิดแผน ไม่ให้หน้าตั้งค่าเข้าถึงdeveloper tuningหรือเปลี่ยนค่าการแข่งขันโดยพลการ

## Acceptance / ก่อนลงมือ
- ระบบปลายทางทำงานจริง ไม่มีปุ่มที่แสร้งว่าระบบที่ยังไม่ทำพร้อมใช้งาน
- grill รูปแบบหน้าจอเมื่อเปิดระบบที่เกี่ยวข้อง

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน
