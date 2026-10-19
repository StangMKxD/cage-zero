# 06-market — ตลาดแผงและธุรกรรม

- **Phase:** 2; **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **Transaction prerequisite:** [02-transactions](../02-transactions/plan.md) ต้องพร้อมก่อนเปิดรายการ Cash/ไอเทมของแผนนี้
- **ข้อสรุปกติกา:** [accepted decisions](../../phase-01-gameplay-demo/01-cage-physics/notes.md)
- **Prerequisites:** [04-collection-and-economy](../04-collection-and-economy/plan.md), [05-effect-gacha](../05-effect-gacha/plan.md)
- **Hard gate:** ต้องจบและตรวจรับ Phase 1 ครบก่อน ห้ามเปิดงานแผนนี้ระหว่างเก็บ phase แรก

## Scope
- เอฟเฟคขายเป็นชุดผ่านแผง Cash เท่านั้น ไม่มี P2P สำหรับเอฟเฟค
- P2P สินค้ากลุ่มเดิมยังไม่ถูกสั่งลบทั้งเกม ต้องรักษาขอบเขตเดิม
- ownership/ล็อกธุรกรรม/การตั้งขายและซื้อไม่ทำไอเทมสูญหายหรือซ้ำ

## Acceptance / ก่อนลงมือ
- grill flow แผง/การค้นหา/ตั้งขาย/จัดการของและ UI ก่อนลงรายละเอียด
- เทียบ source/data contract และทดสอบธุรกรรมตาม scope ที่อนุมัติ

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน
