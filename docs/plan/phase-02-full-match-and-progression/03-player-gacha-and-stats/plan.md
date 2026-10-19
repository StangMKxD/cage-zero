# 03-player-gacha-and-stats — สุ่มนักเตะ ระดับ และ Stats

- **Phase:** 2; **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **Transaction prerequisite:** [02-transactions](../02-transactions/plan.md) ต้องพร้อมก่อนเปิดรายการ Cash/ไอเทมของแผนนี้
- **ข้อสรุปกติกา:** [accepted decisions](../../phase-01-gameplay-demo/01-cage-physics/notes.md)
- **Prerequisites:** [00-match-flow](../00-match-flow/plan.md)
- **Hard gate:** ต้องจบและตรวจรับ Phase 1 ครบก่อน ห้ามเปิดงานแผนนี้ระหว่างเก็บ phase แรก

## Scope
- สุ่มตัวละครนักเตะ มี Tier/rarity และ stats จำนวนไม่มาก ตั้งต้นจากพลังยิง/ยิงโค้ง/ความเร็ว/พุ่งสกัด/เลี้ยงบอล
- สัดส่วน Custom Rig/ลักษณะการ์ดและ Signature สายเลี้ยง–รับตามข้อกำหนดที่ยังคงไว้
- stats ไม่ใช่การคืนสกิลยิง/ส่งที่ผู้ใช้ตัดออก; ข้อจำกัดความต่าง stats เดิมยังไม่ถูกสั่งยกเลิก

## Acceptance / ก่อนลงมือ
- เก็บความหมาย รายการสุดท้าย จำนวน stats สูตรผลต่อการเล่น ความสัมพันธ์ Tier/การเติบโต/ของซ้ำ/การสุ่มและรายการสกิลไว้ grill ภายหลัง ไม่สรุปสูตรหรือค่าสมดุลใน phase แรก
- ไม่ล็อกสูตร/เรต/ราคาในรอบจัดโครงแผนนี้

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน
