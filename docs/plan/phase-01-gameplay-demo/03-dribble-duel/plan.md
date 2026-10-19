# 03-dribble-duel — ดวลเลี้ยงผ่านและคัตซีน

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [02-player-actions](../02-player-actions/plan.md)

## Scope
- เข้าเขตเกิด Duel Event อัตโนมัติ Feint ใช้หลบระยะ สโลว์ทั้งสนามสั้น ๆ ตอนเปิดแล้วกลับปกติ
- ชอยส์พื้นฐานร่วม: กระชาก/โยกหลอก/ลอดขา ฝ่ายรับพุ่งสกัด/คุมเชิง/ดักทาง ไม่มีชอยส์ยิง/ส่ง/Snap Shot/Shot Block เดิม
- ผู้ชนะครองบอลพร้อมคัตซีนเฉพาะคู่ ผู้แพ้สตั้นหลังคืนการควบคุม คนอื่นแทรกคู่ไม่ได้
- คนอื่นเคลื่อนที่ได้หลังช่วงสโลว์; คัตซีนส่วนตัวไม่หยุดนาฬิกาเมื่อเปิดระบบแมตช์ใน Phase 2

## Acceptance / ก่อนลงมือ
- trigger/ผลรุกและรับ/ownership/คืนการควบคุมไม่ค้างหรือเปิดดวลซ้ำผิดจังหวะ
- คัตซีนไม่แย่งกล้องผู้เล่นนอกคู่; ไม่มีผลยิง/ส่งใน choice matrix
- ก่อนลงมือ grill ตารางชนะทางและ Mistake ที่ยังเกี่ยวข้อง ไม่คัด matrix เก่ามาทั้งชุด

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น
