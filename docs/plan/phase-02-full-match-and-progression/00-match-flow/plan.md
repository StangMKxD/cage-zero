# 00-match-flow — วงจรแมตช์และเวลาเล่น

- **Phase:** 2; **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../../phase-01-gameplay-demo/01-cage-physics/notes.md)
- **Hard gate:** ต้องจบและตรวจรับ Phase 1 ครบก่อน ห้ามเปิดงานแผนนี้ระหว่างเก็บ phase แรก

## Scope
- แมตช์ 3v3/4v4 เต็มวงจร: ทีม/ตำแหน่ง/เขี่ยเริ่ม/สกอร์/เวลาเล่นปกติ 5 นาที/จบแมตช์
- นาฬิกาหยุดช่วงดีใจหลังประตูและเตรียมลูกนิ่ง เดินต่อในสโลว์เปิดดวลและคัตซีนส่วนตัว
- เชื่อมกลไก Phase 1 เข้ากับ session จริง โดยยังไม่รวมเศรษฐกิจที่ยังไม่เปิด

## Acceptance / ก่อนลงมือ
- grill คนออกกลางเกมและรายละเอียด flow ก่อนล็อก implementation
- ตรวจทั้งวงจรและขอบเวลา/goal/reset ตาม source จริง

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน
