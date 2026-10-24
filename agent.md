# PROJECT AGENT STATE & ROUTER

## LATEST DISPATCH — 2026-10-24
- **Latest confirmed design:** Owner confirmed five-skill choreography after grilling; primary HANDOFF§Q and assets/designs/skill-animation-rework-20261024.md authorize scoped new revisions/prototype coupling, pending Owner per-skill visual review. Supersedes§P hold only; no auto-promotion/Git/closure. Push reports§O, no polling.
- **Latest communication override:** Owner stops Codex monitoring; agycage continues approved work and PUSH-reports READY_FOR_REVIEW/BLOCKED/new Owner action to verified Codex **w2:p43**, per primary HANDOFF§O. Supersedes monitor-only/no-callback text below; no approval/closure authority.
- **Latest Owner override:** other pane closed; **agycage w2:p48 sole writer**, priority connect Motion Tools to **Cage-Zero137721422246269** per primary HANDOFF§M, then §L main work. Supersedes parallel/Sandbox-only ownership below; preserve both panes' partial artifacts. Monitor only agycage. No Git/publish/closure authority.
- Owner resumes missing-animation/main Plan02/03 continuation in **agycage w2:p48**; normal prompt, single source/shared-board writer. Follow primary `03-dribble-duel/assets/HANDOFF.md` **§L**, current tasks and Plan02§21–22. Current HEADc7542258b93b613e0260e43035761cbce87928cd+dirty; historical baseline/pause text below is superseded ONLY for this scoped dispatch.
- **agycagezero w2:p3X** continues ONLY §K AnimationSandbox133472167342841 preview; owns that session/editor and single animation-library.json, not source/shared boards. Main writer authors new drafts/delta separately; coordinated import barrier, no duplicate session/server/writers. **Codex monitors only agycage**, per Owner. Plan00/01/04/GK/Phase2/Bridge remain paused; no Git/publish/approval/closure authority.

## CURRENT EXECUTION STATE
- **ACTIVE_PHASE**: `docs/plan/phase-01-gameplay-demo`
- **ACTIVE_MODULE**: `02-player-actions` — `IN_PROGRESS / CHANGES_REQUESTED — OWNER_VISUAL_REJECTED`; review-002 / HANDOFF§7; OwnerยืนยันreuseSandboxposes/settings+Shift Lock แล้วจูน02 ส่งfix-003แบบmanual
- **PREVIOUS_MODULE_STATUS**: `00-bootstrap-and-rig` — `OPEN / PAUSED_BY_OWNER`; `01-cage-physics` — `OPEN / PENDING_TECHNICAL_REVIEW` (**ยังไม่ปิดแผน 00 และ 01** ตามคำสั่ง Owner; รอ technical check ภายหลัง)
- **CONTROLLER**: `Codex`; **IMPLEMENTER**: `AGY Teamwork-preview` (Reviewer อิสระคือ Codex; Implementer คือ AGY Teamwork-preview ตามกติกาโปรเจกต์)
- **CURRENT_BASELINE**: `main` @ `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + dirty working tree ตาม source lock ใน HANDOFF02
- **CURRENT_PLAN**: `docs/plan/phase-01-gameplay-demo/02-player-actions/plan.md`
- **CURRENT_CONTRACT**: `docs/plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md` §6–7; tasksเป็นงานส่งแก้/review-002เป็นคำตัดสิน
- **PHASE_PLAN**: `docs/plan/phase-01-gameplay-demo/plan.md`
- **PHASE_2**: `docs/plan/phase-02-full-match-and-progression/plan.md` — ยังเลื่อน ไม่มีคำสั่งเปลี่ยน rig ใน phase นี้
- **ACCEPTED_FEATURE_DECISIONS**: `docs/plan/phase-01-gameplay-demo/01-cage-physics/notes.md`
- **GAMEPLAY_DESIGN**: Q22 ยืนยันฟุตบอลต่อเนื่อง/Skill 5 ท่า 3 ช่อง/ตัวเริ่มต้น 5 ดาวแทน Choice; ดู Spec02 และ N37–N44
- **PLAN_IDENTIFIERS**: ใช้ชื่อ phase/โฟลเดอร์แผนโดยตรง ไม่เพิ่มรหัส feature แยก

## STRICT OPERATING RULES
1. อ่าน `docs/READ.md`, active plan/HANDOFF และ architecture ก่อนเริ่มงาน
2. AGY Teamwork-preview ทำหน้าที่ Implementer และ Codex ทำหน้าที่ Controller ตรวจสอบอิสระ; คงมาตรฐานการตรวจสอบหลักฐานจริง (Static / Edit Scene / Live Play Runtime / Rollback Manifest) และไม่ปิดงานเองโดยพลการ
3. แผน `00-bootstrap-and-rig` คงสถานะ `OPEN / PAUSED_BY_OWNER` (ยังไม่ปิดแผน 00); แผน `01-cage-physics` ใช้สัญญา R6 (`ServerStorage.CageZeroStandardR6Rig`, `HumanoidRootPart`, `RigAndCardService`, `R6AnimationController`) เชื่อมกับ `Workspace.HexCageArena.CageFloor`
4. Phase 1 ใช้ Single Custom R6 ของเกม ไม่ใช้ avatar/animation pack ส่วนตัว ไม่มีรองเท้าสตั๊ด และ Mutations ไม่เพิ่มพลังสนาม
5. source หลักอยู่ `src/`; ใช้ Studio MCP หลังตรวจ target/path/hash และ before-state ไม่แตะ Reference Sandbox (`112091950831355`)
6. Phase 2 รอ Phase 1 ครบจริง; ไม่ขยาย scope ข้ามแผนโดยไม่ได้รับอนุมัติ

## CURRENT GIT AUTHORIZATION
- Baselineปัจจุบันmain617f523+workingtree ตามreview-002/source lock; ไม่มีสิทธิ์commitใหม่ใน02
- ห้าม push, merge, deploy หรือลบ branch โดยไม่มีคำสั่งชัดเจนจาก Owner
- ปกป้อง `.gitignore`, `src/`, `sourcemap.json`, Reference Sandbox (`112091950831355`) และ `.sandbox/rollback/` ทุกชุด

## LATEST OWNER SCOPE — 2026-10-21
- ต่อจากรายงานAGYfix-001 ดึง sprint/dash/kick/pass/curve+เกจจากprototype3 เว้นท่าโยก ตัดLobPassแยก ดึงSlideก่อน Poke/Shoulderภายหลังใน03; selectedUIมา02ก่อนfullUI08ตามคำสั่งนี้
- CodexControllerจัดแผน/HANDOFFและreview; AGYลงมือเฉพาะallowlist§6 ไม่แก้Sandbox/reference/rig00/physics01 และไม่เปลี่ยนreview/fixhistoricalเป็นผลผ่านใหม่
- ผลAGY34/34/160assertions,141/141/445assertionsและLivePlayยังรอCodexre-review; ต้องfreshหลังport F-10..F-19ยังไม่ปิดจากclaimsImplementer
- localcommit01ที่Ownerสั่งเสร็จแล้วคือ617f523 ไม่ได้อนุญาตcommit02/เพิ่มcommit/push/merge/deployหรือปิดแผน

## OWNER VISUAL DIRECTIVE / REVIEW-002 — 2026-10-21
- Animationยังไม่ผ่าน ใช้proceduralposeและค่าต่างๆจากSandboxเป็นฐานadaptR6 ไม่เปลี่ยนชื่อjumpclipเป็นSlide ใช้ShiftLockแบบSandboxL/Alt/shoulder/menu/focusตามHANDOFF§7 แล้วจูนใน02
- F-13..18/F-20..24ยังOPEN ผล40/40Editและsourceparityไม่แทนLivePlay/poseผ่าน; เอฟเฟกต์เต็ม07/08/Phase2รอแผนเจ้าของได้ ส่งfix-003manual ไม่commit/push/merge/deployหรือปิดงานเอง
