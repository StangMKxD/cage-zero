# 01-cage-physics — สนามกรงและฟิสิกส์บอล

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](notes.md)
- **Prerequisites:** [00-bootstrap-and-rig](../00-bootstrap-and-rig/plan.md)

## Scope
- Hex-Cage พร้อมพื้น/ผนัง/เพดาน ประตู bumper/ramp/back zone ครบตาม scope ที่เลือก
- ข้อมูล geometry ชุดเดียวกับ collision รวมรัศมีบอล/normal/ความหนาและการชนความเร็วสูง
- คง bumper 1.25, ramp 25 องศา, back zone 14 Studs ตาม spec เดิม และพื้นที่อ้างอิงเขตโทษสำหรับแผนโกล/ลูกนิ่ง

## Acceptance / ก่อนลงมือ
- ชิ่งทุกด้าน/เพดาน/bumper ตรงชิ้นสนาม ไม่ทะลุในกรณีที่ทดสอบจริงและระบุข้อจำกัด
- ramp footprint/แรงยกและการวิ่งอ้อมประตูผ่านทั้ง focused tests และ visual UAT

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น
