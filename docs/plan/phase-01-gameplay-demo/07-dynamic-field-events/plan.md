# 07-dynamic-field-events — อีเวนต์สนามทั้งสามแบบ

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [05-fouls-and-set-pieces](../05-fouls-and-set-pieces/plan.md), [06-training-ground](../06-training-ground/plan.md)

## Scope
- Pillar Lockdown, Blackout Void, Favela Alleyway พร้อม warning/collision/VFX/NPC sync
- ใช้เวลาและตัวควบคุมฉากฝึกสำหรับเปิด สลับ จบ และคืนสภาพ ไม่ต้องมี match clock 5 นาทีก่อน
- ไม่เพิ่มอีเวนต์ชนิดใหม่จากการปรับโครงแผน

## Acceptance / ก่อนลงมือ
- เสาเตือนก่อนเกิด/ชิ่งได้ Blackout ซ่อนภาพแต่ยังชนได้ และยังเห็นบอล/โกล/ผู้เล่น
- Favela NPC sync และชนบอล/ขวางทางได้ตาม spec; ตรวจผลกับ duel/โกล/ลูกนิ่งไม่ให้ state ค้าง
- วัดปัญหาประสิทธิภาพที่พบ ไม่รับรองว่าเฟรมไม่ตกโดยไม่มีหลักฐาน

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น
