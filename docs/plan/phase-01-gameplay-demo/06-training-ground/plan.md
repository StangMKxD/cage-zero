# 06-training-ground — สนามซ้อม หุ่น และเครื่องมือทดสอบ

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [01-cage-physics](../01-cage-physics/plan.md), [02-player-actions](../02-player-actions/plan.md)

## Scope
- ฉากซ้อมสำหรับทดลอง movement/บอล/ดวล/โกล/ลูกนิ่งและอีเวนต์
- spawn/สั่งหุ่นคู่ซ้อม รีเซ็ตบอลและฉากด้วยเครื่องมือเฉพาะการซ้อม
- ใช้หุ่น/HUD ขั้นต่ำช่วยตรวจแผนก่อนหน้าได้ แล้วเก็บขอบเขตสนามซ้อมครบก่อนปิด phase

## Acceptance / ก่อนลงมือ
- เริ่มทดสอบ/สลับ scenario/รีเซ็ตแล้ว state ไม่ค้าง
- เครื่องมือ debug ไม่กลายเป็นสิทธิ์ในโหมดแข่งขัน; รูปแบบหุ่นที่ยังไม่ล็อกให้ grill ก่อนทำ

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน
