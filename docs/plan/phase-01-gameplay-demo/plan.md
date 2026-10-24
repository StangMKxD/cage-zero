# Phase 1 — Gameplay Demo

- **State:** PHASE_1 / 02_CHANGES_REQUESTED_OWNER_VISUAL; Owner2026-10-21ให้02selectiveportตามHANDOFFล่าสุด 00/01ยังเปิดและพัก 03ส่วนที่เหลือ–09ยังรอgate
- **Owner:** Stang; Controller/Reviewer: Codex; Implementerของactive02: AGY Teamwork-preview; แผนอื่นตามสัญญาของตน
- **Baseline:** main @ `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + working tree ตามHANDOFF02
- ใช้ชื่อโฟลเดอร์แผนด้านล่างโดยตรง ไม่มีชุดรหัส feature แยกจากเลขแผน
- [Roadmap](../roadmap.md) / [ข้อสรุปกติกา](01-cage-physics/notes.md) / [Phase 2](../phase-02-full-match-and-progression/plan.md)

## แผนใน phase — ทำทีละแผนตามลำดับ
| Plan | ขอบเขต | Delivery |
| --- | --- | --- |
| [00-bootstrap-and-rig](00-bootstrap-and-rig/plan.md) | Bootstrap และ Custom R6 | OPEN / PAUSED_BY_OWNER |
| [01-cage-physics](01-cage-physics/plan.md) | กรง3D A/B/C และฟิสิกส์บอล | OPEN / PENDING_TECHNICAL_REVIEW; localcheckpoint617f523 |
| [02-player-actions](02-player-actions/plan.md) | บอล/movement/teaminputs/first-time + selectiveSandbox/Slide/เกจ | CHANGES_REQUESTED / OWNER_VISUAL_REJECTED; fix-003manualตามHANDOFF§7 |
| [03 — Skill Moves/เกมรับ](03-dribble-duel/plan.md) | เป้าหมาย 7 ท่าไม่ซ้ำ/3ช่อง (5 แอนิเมชันอยู่ระหว่างปรับแก้รอตรวจรับ) Quick Poke/Body CheckภายหลังและreuseSlideจาก02 | SCOPE_CONFIRMED; implementationที่เหลือPENDING |
| [04-goalkeepers](04-goalkeepers/plan.md) | ผู้รักษาประตูคนและ AI | ยังไม่เริ่ม |
| [05-fouls-and-set-pieces](05-fouls-and-set-pieces/plan.md) | ฟาวล์ ฟรีคิก และจุดโทษ FC27 | ยังไม่เริ่ม |
| [06-training-ground](06-training-ground/plan.md) | สนามซ้อม Debugจูนค่าการเล่น (13 Stats, 16 Traits, 5 Presets) และเสก/จัดDummy | ยังไม่เริ่ม |
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

[Spec02](../../specs/spec-02-duel-and-parry.md)และN37–N44เป็นคำตอบปัจจุบันแทนChoice/Mistake/คัตซีนล็อกคู่เดิม เก็บDash ลบFeintเดิม มีตัวทดสอบเพดาน5ดาว1ตัว (เป้าหมาย 7 ท่าไม่ซ้ำ ติดตั้ง 3 ช่อง ตาม HANDOFF §Q) แอนิเมชันท่าร่างR6 ปุ่มทีมครองล่าสุดเปลี่ยนเมื่อครองใหม่จริง บอลมีhitboxเสมอ/ไม่มีI-frame และRecoveryไม่ล็อกการเล่นพื้นฐานเกินกติกา

รอบQ22เดิมไม่มีimplementationapprovalใหม่; Ownerdelta2026-10-21อนุญาตเฉพาะ02ตามHANDOFFล่าสุด ระบบ00ตามสัญญาเดิม ส่วนPhase2ต้องมีสุ่มตัวละคร/สกิล/เอฟเฟคและfirst-time miss animation/recovery/settingsจริง ท่าเพิ่มเติมที่เคยเสนอ15ท่าไม่อยู่scopePhase1

Ownerdelta2026-10-21: selectedchargegauge/controlsและSlideจากSandboxทำใน02ก่อน โดยต่อจากfix-001 ห้ามยกท่าโยก/FullUI08มา ส่งแบบเดียว3Dแทนส่งเรียด/โด่งแยก Quick Poke/Body Checkยัง03ภายหลัง อำนาจลงมือจำกัดHANDOFF02 ไม่มีผลอนุมัติหรือปิดแผนอื่น

Ownervisualdirectiveหลังfix-002: 02ใช้ท่า/ค่าตั้งต้นSandboxadaptR6พร้อมShiftLockแล้วจูนต่อ animationปัจจุบันยังไม่ผ่าน เอฟเฟกต์เต็มที่มีแผนเจ้าของรอได้ ไม่มีการปิดแผน00/01/02หรือเปิด03ทั้งแผน
