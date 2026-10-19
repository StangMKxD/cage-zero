# 00-bootstrap-and-rig — Bootstrap และ Custom R15

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)

## Scope
- ตรวจ source/config และขอบเขต sandbox ที่ใช้เป็น reference ผ่าน MCP
- ใช้ Single Custom R15/ใบหน้าอนิเมะ/สัดส่วน Rig ตามข้อกำหนดเดิม ไม่ใช้ avatar ผู้เล่นและไม่มีรองเท้าสตั๊ด
- เก็บ source หลักใน repo และซิงก์ Studio หลังตรวจ path/source; ไม่ต้องมีระบบสุ่มนักเตะก่อน

## Acceptance / ก่อนลงมือ
- Rig ใช้งานได้กับ movement/อนิเมชันพื้นฐาน และ source ใน Studio ตรงกับ repo
- ตรวจสิ่งที่มีอยู่ก่อน ไม่ถือข้อความ APPROVED หรือผล build เดิมเป็นหลักฐานรอบนี้

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น
