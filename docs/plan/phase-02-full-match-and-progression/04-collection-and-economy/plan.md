# 04-collection-and-economy — Collection อุปกรณ์ และเศรษฐกิจ

- **Phase:** 2; **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **Transaction prerequisite:** [02-transactions](../02-transactions/plan.md) ต้องพร้อมก่อนเปิดรายการ Cash/ไอเทมของแผนนี้
- **ข้อสรุปกติกา:** [accepted decisions](../../phase-01-gameplay-demo/01-cage-physics/notes.md)
- **Prerequisites:** [03-player-gacha-and-stats](../03-player-gacha-and-stats/plan.md)
- **Hard gate:** ต้องจบและตรวจรับ Phase 1 ครบก่อน ห้ามเปิดงานแผนนี้ระหว่างเก็บ phase แรก

## Scope
- Battle Threads/Trait/Mutations, Cash/EXP/Level, reward/celebrations และข้อมูล ownership
- คงสกิลเลี้ยง–รับที่ยังเลือกไว้และ cooldown; ตัดสกิลยิง/ส่งตาม accepted decisions
- ไม่มีรองเท้าสตั๊ดและ Mutations ไม่เพิ่มพลังสนาม; รองรับฐานข้อมูลสำหรับเอฟเฟค/ตลาดภายหลัง

## Acceptance / ก่อนลงมือ
- grill รายชื่อ/บัฟที่คงไว้กับที่ตัด และข้อมูลรางวัล/ownership ก่อน schema/API implementation
- ไม่ถือว่าเพิ่ม stats นักเตะแล้วต้องให้ Mutations เพิ่มพลังด้วย

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น
