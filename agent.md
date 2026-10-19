# PROJECT AGENT STATE & ROUTER

## CURRENT EXECUTION STATE
- **ACTIVE_PHASE**: `docs/plan/phase-01-gameplay-demo`
- **ACTIVE_MODULE**: `01-cage-physics` — เตรียมแผน โดยตรวจ dependency 00 ก่อนลงมือ
- **CURRENT_PHASE**: `PHASE_1 / PLANNING`
- **CURRENT_RUN**: `ยังไม่เปิด implementation run ใหม่`
- **MODULE_STATUS**: `IN_PROGRESS` (กำลังเตรียมแผน)
- **CURRENT_PLAN**: `docs/plan/phase-01-gameplay-demo/01-cage-physics/plan.md`
- **CURRENT_CONTRACT**: `docs/plan/phase-01-gameplay-demo/01-cage-physics/assets/HANDOFF.md` (DRAFT)
- **IMPLEMENTATION_APPROVAL**: `PENDING`; คำสั่งนี้ให้ย้าย/จัดโครงแผนและ sync เอกสารเท่านั้น
- **PHASE_PLAN**: `docs/plan/phase-01-gameplay-demo/plan.md`
- **PHASE_2**: `docs/plan/phase-02-full-match-and-progression/plan.md` — รอ Phase 1 ครบและผ่าน gate
- **ACCEPTED_FEATURE_DECISIONS**: `docs/plan/phase-01-gameplay-demo/01-cage-physics/notes.md`
- **PLAN_IDENTIFIERS**: ใช้ชื่อ phase/โฟลเดอร์แผนโดยตรง ไม่ใช้รหัส feature แยกอีกชุด

## STRICT OPERATING RULES
1. อ่าน docs/READ.md, phase plan, เอกสารของ ACTIVE_MODULE และ spec/design ที่อ้างอิง
2. ทำทีละแผนตาม phase ไม่ลงมือจากการอนุมัติจัดแผน และห้ามเปิด Phase 2 ก่อน Phase 1 ครบ/ผ่าน gate
3. ห้ามใช้ avatar ผู้เล่นหรือรองเท้าสตั๊ด และห้ามให้ Mutations เพิ่มพลังสนาม
4. หลังอนุมัติ implementation ใช้ Studio MCP โดยตรงและเก็บ source ใน repo; .sandbox/ เป็น ignored local ref
5. ประวัติ runs/milestones และข้อความปิดงานเก่าไม่ใช่ approval/ref ของแผนใหม่

## CURRENT GIT AUTHORIZATION
ผู้ใช้อนุญาต commit + push การจัด phase/แผน/UAT/transaction และ .gitignore รอบนี้โดยตรง ไม่รวม source/sourcemap.json/.sandbox/ และไม่ใช่อนุมัติ implementation หรือ commit รอบถัดไป
