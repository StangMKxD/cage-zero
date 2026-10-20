# Cage Zero — จุดเริ่มอ่านเอกสาร

- กติกา/สถานะ: [agent.md](../agent.md)
- [Roadmap](plan/roadmap.md) / [Phase 1 — Gameplay Demo](plan/phase-01-gameplay-demo/plan.md) / [Phase 2](plan/phase-02-full-match-and-progression/plan.md)
- ปัจจุบัน: [00-bootstrap-and-rig](plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md), [tasks](plan/phase-01-gameplay-demo/00-bootstrap-and-rig/tasks.md), [HANDOFF](plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/HANDOFF.md)
- ผู้ใช้ยืนยัน **Custom R6 ตลอด Phase 1**; หลัง[review010](plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/review-010.md) Ownerสั่ง “พักรอบ 00 ก่อน” สถานะPAUSED_BY_OWNER หยุดแก้/ทดสอบ/dispatchจนกว่าจะresume F18/F19ยังOPEN historicalgaprunแรกACCEPTED_GAPคงเดิม ยังไม่ปิด00
- แผนถัดไป [01-cage-physics](plan/phase-01-gameplay-demo/01-cage-physics/plan.md) ต่อจากสัญญา root/floor ของ 00 ทำรายละเอียดเอกสารได้ แต่ลงมือต้องรอ dependency gate จริง
- แผน 01 มี map list A/B/C (4/8/8 ผนัง), จุดชิ่ง 5 กรณี และวิธีเทียบ; marker เป็นไกด์ไม่มีแรงนำบอล ส่วน pillar/ripple/ป้ายแกว่งเป็น [trials ใน 07](plan/phase-01-gameplay-demo/07-dynamic-field-events/plan.md)
- ผู้ใช้เพิ่ม [Debug tuning/DummyในPhase1/06](plan/phase-01-gameplay-demo/06-training-ground/plan.md) สำหรับจูนเช่นความเร็วพื้นฐานระหว่างทดสอบ; ระบบตั้งค่าฉบับใช้งานจริง/ค่าถาวรอยู่ [Phase2/07](plan/phase-02-full-match-and-progression/07-meta-ui/plan.md) implementationทั้งสองยังPENDING
- Q22ยืนยัน [ฟุตบอลต่อเนื่อง/Skill MovesแทนChoice](specs/spec-02-duel-and-parry.md): [02บอล/movement](plan/phase-01-gameplay-demo/02-player-actions/plan.md) และ [03สกิล3ช่อง/เกมรับ](plan/phase-01-gameplay-demo/03-dribble-duel/plan.md) scopeconfirmedแต่implementationยังPENDING; พาธ03/spec02เดิมเก็บเป็นlegacy ไม่เปิดระบบChoice
- [Architecture](design/architecture-and-network.md#5-phase-1-runtime--custom-r6) / [PRD](prd/product-requirements.md) / [spec rig](specs/spec-03-cards-rig-freekick.md) / [TDD](tdd/master-test-cases.md)
- [Accepted decisions](plan/phase-01-gameplay-demo/01-cage-physics/notes.md) supersede เฉพาะข้อความเก่าที่ระบุ ไม่คืน Parry/Snap Shot/1v1v1 ที่ตัดแล้ว
- Sourceอยู่src/เป็นworking-treeR6ยังไม่commit; review010อ่านสดsource9/9ตรงrepoจากPlace4Edit HEAD0e2d23eเป็นเอกสารอีเวนต์; runtimeprobesในรายงานยังต้องtraceกับsource .sandboxเป็นignoredreference/evidence
- [Live intake](plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/review-003.md) และ review-001..006 เป็นหลักฐาน/ผลข้อเสนอ R15 เดิม ไม่ใช่ผลรัน R6
- รายงาน historical runs/milestones เก็บเดิม การมี APPROVED เก่าไม่รับรองแผนปัจจุบัน; เอกสารระบบอนาคตยังต้อง sync เฉพาะส่วนเมื่อเปิดแผนนั้น
