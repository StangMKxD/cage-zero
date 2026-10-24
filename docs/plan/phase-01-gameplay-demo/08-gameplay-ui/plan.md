# 08-gameplay-ui — UI กล้อง และ feedback ของ Demo

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [03-dribble-duel](../03-dribble-duel/plan.md), [04-goalkeepers](../04-goalkeepers/plan.md), [05-fouls-and-set-pieces](../05-fouls-and-set-pieces/plan.md), [06-training-ground](../06-training-ground/plan.md), [07-dynamic-field-events](../07-dynamic-field-events/plan.md)

**Ownerexception2026-10-21:** segmentedchargegauge/controlsของSprint/Dash/kick/Pass/curve/Slideที่เลือกจากSandboxให้adaptในTrainingHUDของ02ก่อน; 08รับต่อและจัดUIรวมภายหลัง ไม่สร้างgauge/chargeauthorityอีกชุด ไม่อนุมัติ08ทั้งแผน

## Scope
- HUD/ปุ่ม3คู่ตามทีมครองล่าสุด/กล้อง/feedbackสำหรับบอล Skill3ช่อง เกมรับ โกล ลูกนิ่ง อีเวนต์และสนามซ้อม
- ไม่มีDuel Modal/Parry prompt/สโลว์เปิดดวล/คัตซีนล็อกคู่; แสดงดาว/CD/Stamina/recoveryและloadout 3 ช่อง (จากเป้าหมาย 7 ท่าไม่ซ้ำ) ก่อนรอบ/หยุดรีเซ็ตซ้อม
- หน้าระบบสุ่ม/ตลาด/collection/สรุปแมตช์อยู่แผน UI ของ Phase 2 ไม่เปิดทำงานหรือใช้ข้อมูลปลอมอ้างว่าส่งแล้ว

## Acceptance / ก่อนลงมือ
- หน้าจอและ input ที่ phase นี้ใช้ต่อกันได้ ไม่ค้าง/ซ้อนผิด state และไม่คำนวณผลแพ้ชนะเอง
- contextสลับเมื่อครองบอลใหม่จริง pendinginputไม่กลายเป็นท่าอีกแบบ loadoutไม่เปลี่ยนกลางรอบ reset/respawnคืนกล้องและinput; ตรวจvisualอ่านท่าR6และกติกาปุ่มจริง

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น

- [Scope event5/6] HUDหลอดStaminaมีhighlightวิ่งเร็วและสถานะไม่จำกัดจากOverdrive พร้อมคืนUIเมื่อจบ/respawn; LowRoofมีwarning/eventstateตาม07 ไม่แปลงUIเป็นบัฟความเร็วหรือผลphysics
