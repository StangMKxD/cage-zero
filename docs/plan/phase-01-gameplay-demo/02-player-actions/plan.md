# 02-player-actions — เคลื่อนที่ เลี้ยง ยิงส่ง และกลางอากาศ

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [01-cage-physics](../01-cage-physics/plan.md)

## Scope
- เดิน/Sprint/Stamina/Shift Lock เลี้ยงบอล Dash/Knock-On และ Feint หลบระยะดวล
- ยิงตรง/Finesse/Trivela ส่งเรียด/โด่ง เล็ง 3D และชาร์จระหว่างเคลื่อนที่/กลางอากาศได้ แต่ชาร์จแล้วขยับช้าลง
- กระโดด Header/Volley และกระโดดบล็อก บอลเด้งอิสระ ไม่มี timed Parry นอกดวล
- ยิงปกติไม่ล็อก Shooting Zone; ไม่สร้าง full match หรือระบบ stats นักเตะจากการสุ่ม

## Acceptance / ก่อนลงมือ
- ท่าเปลี่ยน state ต่อกันได้และผลถูกตรวจบน Server
- บล็อกไม่ดูดบอลเข้าครองอัตโนมัติ และไม่มี Parry prompt/Choice ยิงส่งกลับมา
- config จูนตัวเลขได้โดยไม่เปลี่ยนกติกาฟีเจอร์ที่ตกลง

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น
