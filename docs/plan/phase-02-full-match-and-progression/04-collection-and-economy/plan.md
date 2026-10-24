# 04-collection-and-economy — สุ่มสกิล, Skill Inventory, Collection และเศรษฐกิจ

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
- Battle Threads (ชุดตกแต่ง), Mutations (VFX + คูณ Cash/EXP หลังแข่ง), Cash/EXP/Level, reward/celebrations และข้อมูล ownership ตัวละคร/สกิล
- Traits ติดตัวละครเท่านั้น (Innate Traits ใน [03-player-gacha-and-stats](../03-player-gacha-and-stats/plan.md)): ถอดช่องใส่ Trait บนชุด Battle Threads, ถอดหิน Trait Stone และถอดเส้นทางการเทรดหิน Trait ออกจาก Target Design ทั้งหมด (คงข้อมูลเดิมเป็นประวัติศาสตร์แบบมีป้ายกำกับ)
- หน้าจอ Collection แสดงตัวละครพร้อม Innate Traits ประจำตัว (0, 1, 2, ... รายการ); ไม่มีการแสดงผลหรือจัดการหิน Trait แยกต่างหาก
- เป็นเจ้าของสุ่มสกิล/สะสมท่า/Skill Inventory/ownershipและloadout3ช่องตามเพดานดาวต่อจากPhase1 มีท่าเพิ่มเติมที่Ownerเลือกเมื่อเปิดPhase2 คงcost/CD/recoveryและการถูกสกัดได้
- ไม่มีรองเท้าสตั๊ดและ Mutations ไม่เพิ่มพลังสนาม; รองรับฐานข้อมูลสำหรับเอฟเฟค/ตลาดภายหลัง

## Acceptance / ก่อนลงมือ
- grill รายชื่อ/บัฟที่คงไว้กับที่ตัด และข้อมูลรางวัล/ownership ก่อน schema/API implementation
- ไม่ถือว่าเพิ่ม stats นักเตะแล้วต้องให้ Mutations เพิ่มพลังด้วย

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น

## Skill gacha — Accepted scope / Deferred delivery จากQ22

ต้องมีสุ่มสกิลแยกจากสุ่มตัวละคร03และเอฟเฟค05 ธุรกรรม02ต้องพร้อมก่อน การสุ่ม/ของซ้ำ/เรต/pity/ราคา/ช่องทางได้ฟรี/การซื้อขายท่าและdata schemaยังต้องgrill ไม่อนุมัติให้ขายหรือเทรดสกิลโดยอัตโนมัติจากการเพิ่มSkill Inventory

ไม่เปิดSignature Choice/การชนะmatrix/ยิงส่งการันตีจากbaseline และไม่ตีความท่าฟรีในDemoว่าได้ทำinventory/persistenceแล้ว
