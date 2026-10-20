# PROJECT AGENT STATE & ROUTER

## CURRENT EXECUTION STATE
- **ACTIVE_PHASE**: `docs/plan/phase-01-gameplay-demo`
- **ACTIVE_MODULE**: `00-bootstrap-and-rig` — PAUSED_BY_OWNER ตามคำตอบ “พักรอบ 00 ก่อน” หลังreview010; F18/F19ยังOPEN
- **CURRENT_PHASE**: `PHASE_1 / 00_PAUSED_BY_OWNER`
- **CURRENT_RUN**: `run-phase00-agy-impl-01; AGY session e86ac30e-006d-4338-9a90-5f5e3b002028; ผู้ใช้ส่งผลกลับแล้ว`
- **MODULE_STATUS**: `PAUSED_BY_OWNER / REVIEW-010 / Turn OWNER / Round 5 NOT DISPATCHED`
- **CURRENT_PLAN**: `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md`
- **CURRENT_CONTRACT**: `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/HANDOFF.md` (LOCKED_SCOPE / P-03 AUTHORIZED)
- **IMPLEMENTATION_APPROVAL**: `AUTHORIZED_FOR_00`; Stang สั่ง “เริ่มเลย” เมื่อ 2026-10-20 หลังเห็น plan/HANDOFF R6 อนุมัติ AGY แก้ source/target Studio และตรวจตาม 00 เท่านั้น ไม่รวม 01/07/Phase 2
- **PHASE_PLAN**: `docs/plan/phase-01-gameplay-demo/plan.md`
- **NEXT_PLAN**: `01-cage-physics` — ทำรายละเอียดแผนได้; implementation รอ 00 gate
- **PHASE_2**: `docs/plan/phase-02-full-match-and-progression/plan.md` — ยังเลื่อน ไม่มีคำสั่งเปลี่ยน rig ใน phase นี้
- **ACCEPTED_FEATURE_DECISIONS**: `docs/plan/phase-01-gameplay-demo/01-cage-physics/notes.md`
- **GAMEPLAY_DESIGN**: Q22ยืนยันฟุตบอลต่อเนื่อง/Skill5ท่า3ช่อง/ตัวเริ่มต้น5ดาวแทนChoice; ดูSpec02และN37–N44 อนุญาตเอกสาร ไม่ขยาย00
- **PLAN_IDENTIFIERS**: ใช้ชื่อ phase/โฟลเดอร์แผนโดยตรง ไม่เพิ่มรหัส feature แยก

## STRICT OPERATING RULES
1. อ่าน docs/READ.md, active plan/HANDOFF และ architecture ก่อนเริ่มงาน
2. Codex วางแผน/คุมงาน/ตรวจอิสระ; AGY ลงมือหลัง Owner อนุมัติ implementation ไม่ยึด draft/รายงานเก่าเป็น approval
3. Phase 1 ใช้ Single Custom R6 ของเกม ไม่ใช้ avatar/animation pack ส่วนตัว ไม่มีรองเท้าสตั๊ด และ Mutations ไม่เพิ่มพลังสนาม
4. source หลักอยู่ src/; ใช้ Studio MCP หลังตรวจ target/path/hash และ before-state ไม่ใช้ sandbox reference เป็น source หลักอัตโนมัติ
5. sourceR6ยังไม่commit; review010อ่านStudio43e07a67.../137721422246269Editสด9/9ตรงrepo F18typed0nullแต่rollbackreferences/WorldPivotยังต้องแก้ F19runtimeหลักฐานขัดsource ห้ามแก้source/CardConfigsให้ตรงรายงานผิด ไม่เปิด01จน00ผ่านgate
6. Phase 2 รอ Phase 1 ครบจริง; grill รายละเอียดของแผนอื่นเมื่อเปิดแผนนั้น ไม่ขยาย scope เอง

## CURRENT GIT AUTHORIZATION
คำสั่ง commit/push การจัด phase รอบก่อนเป็นสิทธิ์เฉพาะรอบนั้น งานปัจจุบันอนุมัติ AGY implementation/verification แผน 00 ตาม HANDOFF; Codex คง Controller/Reviewer ไม่มีสิทธิ์ commit, push, merge หรือ deploy ใหม่ ปกป้อง .gitignore/source/sourcemap/.sandbox และงานค้างทั้งหมด

คำสั่งล่าสุด2026-10-20: Stangอนุญาต Codex local commit เฉพาะงานที่ไม่เกี่ยวกับ00 รอบนี้เลือกเอกสารสนาม/อีเวนต์01/07และspec01 ไม่รวม source/เอกสาร00 หรือpush/merge/deploy; ต่อมาQ22ยืนยันrequirementฟุตบอลต่อเนื่องแล้ว ไม่เปลี่ยนscope00

ดำเนินการแล้ว: local commit f8729cc6e714f10a1cb60253a4f037d7c49f7505 เฉพาะเอกสารสนาม/อีเวนต์8ไฟล์ ไม่push; baseline AGY/review007ยังใช้2f5f76bพร้อมsource hashesเดิม ไม่มีการแก้sourceจากcommitนี้

คำสั่งหลังQ22: Stangสั่ง “ถ้าเสร็จ ไม่มีอะไรค้างแล้ว commit เลย” อนุญาตlocalcommitเฉพาะเอกสารเกมเพลย์/architecture/PRD/spec/TDD/phaseplansรอบนี้เมื่อเช็กครบ ไม่รวมsource/ผลรีวิวและเอกสาร00/push/merge/deploy สิทธิ์นี้ไม่อนุมัติimplementation02/03
