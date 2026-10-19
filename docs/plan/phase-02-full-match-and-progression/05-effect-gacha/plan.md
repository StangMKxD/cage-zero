# 05-effect-gacha — สุ่ม สวมใส่ และสะสมเอฟเฟค

- **Phase:** 2; **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **Transaction prerequisite:** [02-transactions](../02-transactions/plan.md) ต้องพร้อมก่อนเปิดรายการ Cash/ไอเทมของแผนนี้
- **ข้อสรุปกติกา:** [accepted decisions](../../phase-01-gameplay-demo/01-cage-physics/notes.md)
- **Prerequisites:** [04-collection-and-economy](../04-collection-and-economy/plan.md)
- **Hard gate:** ต้องจบและตรวจรับ Phase 1 ครบก่อน ห้ามเปิดงานแผนนี้ระหว่างเก็บ phase แรก

## Scope
- สองชุด: ยิง+ส่ง และวิ่ง+กระโดด+โยก หนึ่งชุดครบหมวด สวมต่างธีมได้
- เลือกหมวดก่อนสุ่มด้วย Cash; rarity ต่างด้านภาพ ไม่มีค่าสเตตัส
- ของซ้ำเก็บก่อน เลือกเก็บขายหรือสลายเป็นแต้มเอง สลายแล้วชิ้นนั้นถูกใช้ไป แต้มแลกชุดที่ต้องการ

## Acceptance / ก่อนลงมือ
- grill ธีม/rarity/แต้มแลกและรายละเอียดการได้/สวมใส่ภายหลัง
- ไม่แยกโยกหรือแต่ละท่ามาขายเพิ่ม และไม่สร้าง P2P เอฟเฟค

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน
