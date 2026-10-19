# 04-goalkeepers — ผู้รักษาประตูคนและ AI

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [02-player-actions](../02-player-actions/plan.md)

## Scope
- ช่องโกลรวมใน 3v3/4v4: ผู้เล่นสนาม 2/3 + โกล 1 ใช้ฉากฝึกจำลองช่อง/ฝั่งโดยไม่เปิดแมตช์เต็ม
- ไม่มีคนเลือกให้ AI รับหน้าที่ คนแทน AI ได้ตอนหยุดเล่น
- โกลรับ/ปัดด้วยมือและพุ่งเซฟในเขตโทษ นอกเขตเล่นเหมือนผู้เล่นสนาม คนและ AI ใช้กติกาเดียวกัน

## Acceptance / ก่อนลงมือ
- ทดสอบโกลทั้งสองแบบ การเปลี่ยนผู้ครองตำแหน่ง และขอบเขตใช้มือ
- บอล/possession และการออกนอกเขตไม่ค้าง; ไม่สร้าง full match เพื่อใช้โกล
- grill การควบคุมและพฤติกรรม AI ก่อน implementation

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน
