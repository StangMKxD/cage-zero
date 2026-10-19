# 01-match-tiebreak — โหวตและตัดสินเสมอ

- **Phase:** 2; **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../../phase-01-gameplay-demo/01-cage-physics/notes.md)
- **Prerequisites:** [00-match-flow](../00-match-flow/plan.md)
- **Hard gate:** ต้องจบและตรวจรับ Phase 1 ครบก่อน ห้ามเปิดงานแผนนี้ระหว่างเก็บ phase แรก

## Scope
- จบเวลาปกติเลือก Golden Goal/จุดโทษ/จบเสมอ/ต่อเวลา ต้องเห็นตรงกันจึงเล่นต่อ ไม่ตรงกันจบเสมอ
- Golden Goal/ต่อเวลามีเพดานของตัวเอง หมดแล้วยังเสมอจบเสมอทันที ไม่โหวตวน
- shootout ทีมจัดลำดับ ยิงสลับโอกาสเท่ากัน หากยังเท่ากันใช้ Sudden Death

## Acceptance / ก่อนลงมือ
- grill timeout การโหวต/ผู้ยิง/โกลและผู้เล่นออกก่อน implementation
- ทดสอบทางออกทุกแบบและไม่จ่ายผลแมตช์ซ้ำ

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน
