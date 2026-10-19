# 05-fouls-and-set-pieces — ฟาวล์ ฟรีคิก และจุดโทษ FC27

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [04-goalkeepers](../04-goalkeepers/plan.md)

## Scope
- Slide โดนคนก่อนบอลเป็นฟาวล์ นอกเขตฟรีคิก ในเขตจุดโทษ ไม่มีใบเหลือง–แดง
- ลูกนิ่งใช้ FC27 aim/spin/timing และโกลของแผน 04
- ฉากฝึกมี state เตรียม/เริ่ม/จบลูกนิ่งเท่าที่ทดสอบจำเป็น ไม่รวม shootout ตัดสินแมตช์หรือระบบการ์ด

## Acceptance / ก่อนลงมือ
- ฟาวล์/ตำแหน่งตั้งบอล/การยิง/คืนสู่การเล่นครบเส้นทาง
- วิถีสัมพันธ์กับ aim/spin/timing และ input ถูกตรวจบน Server
- grill ผู้ยิง/กำแพง/จังหวะสองและ sync spec ก่อนลงมือ

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น
