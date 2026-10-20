# Phase 1 — Gameplay Demo

- **State:** PHASE_1 / PLANNING_AND_00_HANDOFF; implementation approval เฉพาะ00 AUTHORIZED (2026-10-20 “เริ่มเลย”); 01–09 PENDING
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`
- ใช้ชื่อโฟลเดอร์แผนด้านล่างโดยตรง ไม่มีชุดรหัส feature แยกจากเลขแผน
- [Roadmap](../roadmap.md) / [ข้อสรุปกติกา](01-cage-physics/notes.md) / [Phase 2](../phase-02-full-match-and-progression/plan.md)

## แผนใน phase — ทำทีละแผนตามลำดับ
| Plan | ขอบเขต | Delivery |
| --- | --- | --- |
| [00-bootstrap-and-rig](00-bootstrap-and-rig/plan.md) | Bootstrap และ Custom R6 | correctionRound3 READY_FOR_AGY ตามtasks00 |
| [01-cage-physics](01-cage-physics/plan.md) | กรง3D A/B/C และฟิสิกส์บอล | DESIGN_DRAFT; implementation ยังไม่เริ่ม |
| [02-player-actions](02-player-actions/plan.md) | บอล/movement/Dash/team inputs/first-time | SCOPE_CONFIRMED; implementation PENDING |
| [03 — Skill Moves/เกมรับ](03-dribble-duel/plan.md) | 5ท่า/3ช่อง Poke/Slide/Shoulder และrecovery | SCOPE_CONFIRMED; implementation PENDING |
| [04-goalkeepers](04-goalkeepers/plan.md) | ผู้รักษาประตูคนและ AI | ยังไม่เริ่ม |
| [05-fouls-and-set-pieces](05-fouls-and-set-pieces/plan.md) | ฟาวล์ ฟรีคิก และจุดโทษ FC27 | ยังไม่เริ่ม |
| [06-training-ground](06-training-ground/plan.md) | สนามซ้อม Debugจูนค่าการเล่น และเสก/จัดDummy | ยังไม่เริ่ม |
| [07-dynamic-field-events](07-dynamic-field-events/plan.md) | อีเวนต์สนาม6แบบ | ยังไม่เริ่ม |
| [08-gameplay-ui](08-gameplay-ui/plan.md) | UI กล้อง และ feedback ของ Demo | ยังไม่เริ่ม |
| [09-uat](09-uat/plan.md) | UAT — Gameplay Demo | ยังไม่เริ่ม |

## Dependency และขอบเขต
- 00 เตรียม Custom R6/root/spawn contract ก่อน implementation ของ 01; 01 สนามรวม bumper/ramp/back zone และเขตอ้างอิงประตู; 02 รวม movement/บอล/กลางอากาศที่ผู้ใช้เลือกครบ
- 03 เป็นSkill Moves3ช่องและเกมรับแบบต่อเนื่อง; 04 โกลคน/AI; 05 ลูกนิ่ง; 06 สนามซ้อม/หุ่น; 07 อีเวนต์6แบบ; 08 UI/กล้องที่รองรับทั้งหมด; 09 UAT ของ Phase 1
- ใช้หุ่นและ HUD ขั้นต่ำจาก 06/08 ช่วยทดสอบแผนก่อนหน้าได้ โดยไม่ถือว่า 06/08 ส่งมอบครบแล้ว
- โกล/ลูกนิ่ง/อีเวนต์ใช้ตัวควบคุมฉากฝึกและ state ที่จำเป็น ไม่ดึงวงจรแมตช์เต็ม/นาฬิกา 5 นาที/การโหวต/รางวัลจาก Phase 2 มาทำแทรก
- UI ของระบบสุ่ม/collection/ตลาด/สรุปแมตช์แยกอยู่แผน UI ใน Phase 2; เอฟเฟคตอบสนองพื้นฐานทำใน phase นี้ได้ แต่ระบบสุ่ม/ownership/ชุดเอฟเฟคยังเลื่อน
- หากต้องขยาย scope เพื่อแก้ dependency ให้เสนอการเปลี่ยนก่อน ไม่ดึงระบบ Phase 2 มาเอง

## Gate ก่อน Phase 2
1. ส่งมอบครบสิบแผนรวม 09-uatตาม scope ที่ผู้ใช้เลือกและไม่มี blocking findings ค้าง
2. ตรวจเส้นทางร่วม บอล/Skill Moves/เกมรับ/โกล/ฟาวล์/ลูกนิ่ง/อีเวนต์และการ reset ไม่ทำ state ค้าง
3. มี verification ผ่าน Studio MCP ที่ source/ref ตรง repo และ visual UAT ที่จำเป็น ไม่ใช้ข้อความ APPROVED หรือผลทดลองเก่าเป็นหลักฐาน
4. เอกสารตรงผลงานและผ่าน project review gate ก่อนเริ่ม Phase 2; คำสั่งล่าสุดให้local commitเอกสารรอบQ22เมื่อจบ ไม่รวมsource/00/push/merge/deployหรือimplementationใหม่

## Grill เมื่อใกล้ทำ
API/contact/animation contractก่อนลงมือ02/03, การควบคุมโกล, ผู้ยิง/กำแพง/จังหวะสอง, รายละเอียดหุ่น, interactionของอีเวนต์กับSkill/contact/ลูกนิ่ง และรูปแบบ UI; ไม่ถามค่าความเร็ว/แรง/ระยะ/cooldown ที่จูนผ่าน config ภายหลังได้

assets/runs และ milestones ที่ย้ายมาจากโครงเก่าเป็นประวัติ module เดิม ไม่ใช่ผลตรวจของ phase/เลขแผนใหม่ เนื้อหาใน PRD/spec/TDD ที่ขัด decisions ต้อง sync เฉพาะส่วนก่อนเริ่ม implementation ของแต่ละแผน


## Rig decision — 2026-10-20
ผู้ใช้ยืนยัน R6 ตลอด Phase 1 รวมผู้เล่น/โกล/หุ่นที่ใช้ player rig; ไม่ย้าย R15 ระหว่าง 00–09 โดยอัตโนมัติ อนิเมชันพื้นฐานใช้ R6 standard clips คงสเกลเดิมเป็นค่าทดสอบ ไม่เพิ่มกาชา/UI ต่อมาสั่ง “เริ่มเลย” อนุมัติ implementation เฉพาะ00ให้ AGY; เริ่มรายละเอียดแผน01ได้โดยไม่ถือว่า00ส่งมอบแล้ว


## Map comparison update — 2026-10-20
ผู้ใช้เพิ่มA/B/Cเพื่อเทียบทดลองใน01 และตอบB/Cเป็น8ผนังจากปาด4มุม กับphysicsจริง+markerไกด์ ไม่มีaim assist; base rebounds5กรณีวัดใน01 ส่วนpillar/ripple/moving signsเป็นtrials07ภายใต้สามeventเดิม ไม่มีwinner/defaultmapหรือผล100%ที่ยืนยันแล้ว

## Continuous football — Accepted Q22, 2026-10-20

[Spec02](../../specs/spec-02-duel-and-parry.md)และN37–N44เป็นคำตอบปัจจุบันแทนChoice/Mistake/คัตซีนล็อกคู่เดิม เก็บDash ลบFeintเดิม มีตัวทดสอบ5ดาว1ตัว/5ท่าฟรี3ช่อง แอนิเมชันท่าร่างR6 ปุ่มทีมครองล่าสุดเปลี่ยนเมื่อครองใหม่จริง บอลมีhitboxเสมอ/ไม่มีI-frame และRecoveryไม่ล็อกการเล่นพื้นฐานเกินกติกา

ไม่มีimplementationapprovalใหม่; ระบบ00ตามHANDOFFเดิม ส่วนPhase2ต้องมีสุ่มตัวละคร/สกิล/เอฟเฟคและfirst-time miss animation/recovery/settingsจริง ท่าเพิ่มเติมที่เคยเสนอ15ท่าไม่อยู่scopePhase1
