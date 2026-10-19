# 08-gameplay-ui — UI กล้อง และ feedback ของ Demo

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [03-dribble-duel](../03-dribble-duel/plan.md), [04-goalkeepers](../04-goalkeepers/plan.md), [05-fouls-and-set-pieces](../05-fouls-and-set-pieces/plan.md), [06-training-ground](../06-training-ground/plan.md), [07-dynamic-field-events](../07-dynamic-field-events/plan.md)

## Scope
- HUD/ปุ่มควบคุม/กล้อง/เอฟเฟคตอบสนองสำหรับการเล่น ดวล โกล ลูกนิ่ง อีเวนต์และสนามซ้อม
- Duel Modal ไม่มีปุ่มยิง/ส่งและไม่มี Parry prompt นอกดวล; คัตซีนเฉพาะคู่
- หน้าระบบสุ่ม/ตลาด/collection/สรุปแมตช์อยู่แผน UI ของ Phase 2 ไม่เปิดทำงานหรือใช้ข้อมูลปลอมอ้างว่าส่งแล้ว

## Acceptance / ก่อนลงมือ
- หน้าจอและ input ที่ phase นี้ใช้ต่อกันได้ ไม่ค้าง/ซ้อนผิด state และไม่คำนวณผลแพ้ชนะเอง
- รองรับผู้เล่นนอกคู่ดวลและการคืนกล้อง; ตรวจ visual UAT ตาม feature จริง

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น
