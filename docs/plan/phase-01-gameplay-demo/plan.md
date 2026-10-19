# Phase 1 — Gameplay Demo

- **State:** SCOPE_SELECTED / PLAN_DRAFT; implementation approval PENDING
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`
- ใช้ชื่อโฟลเดอร์แผนด้านล่างโดยตรง ไม่มีชุดรหัส feature แยกจากเลขแผน
- [Roadmap](../roadmap.md) / [ข้อสรุปกติกา](01-cage-physics/notes.md) / [Phase 2](../phase-02-full-match-and-progression/plan.md)

## แผนใน phase — ทำทีละแผนตามลำดับ
| Plan | ขอบเขต | Delivery |
| --- | --- | --- |
| [00-bootstrap-and-rig](00-bootstrap-and-rig/plan.md) | Bootstrap และ Custom R15 | ยังไม่เริ่ม |
| [01-cage-physics](01-cage-physics/plan.md) | สนามกรงและฟิสิกส์บอล | ยังไม่เริ่ม |
| [02-player-actions](02-player-actions/plan.md) | เคลื่อนที่ เลี้ยง ยิงส่ง และกลางอากาศ | ยังไม่เริ่ม |
| [03-dribble-duel](03-dribble-duel/plan.md) | ดวลเลี้ยงผ่านและคัตซีน | ยังไม่เริ่ม |
| [04-goalkeepers](04-goalkeepers/plan.md) | ผู้รักษาประตูคนและ AI | ยังไม่เริ่ม |
| [05-fouls-and-set-pieces](05-fouls-and-set-pieces/plan.md) | ฟาวล์ ฟรีคิก และจุดโทษ FC27 | ยังไม่เริ่ม |
| [06-training-ground](06-training-ground/plan.md) | สนามซ้อม หุ่น และเครื่องมือทดสอบ | ยังไม่เริ่ม |
| [07-dynamic-field-events](07-dynamic-field-events/plan.md) | อีเวนต์สนามทั้งสามแบบ | ยังไม่เริ่ม |
| [08-gameplay-ui](08-gameplay-ui/plan.md) | UI กล้อง และ feedback ของ Demo | ยังไม่เริ่ม |
| [09-uat](09-uat/plan.md) | UAT — Gameplay Demo | ยังไม่เริ่ม |

## Dependency และขอบเขต
- 00 ตรวจฐาน source/MCP/Custom R15 ก่อน 01; 01 สนามรวม bumper/ramp/back zone และเขตอ้างอิงประตู; 02 รวม movement/บอล/กลางอากาศที่ผู้ใช้เลือกครบ
- 03 เป็นดวลเลี้ยงผ่านพร้อมคัตซีนและสตั้น; 04 โกลคน/AI; 05 ลูกนิ่ง; 06 สนามซ้อม/หุ่น; 07 อีเวนต์ทั้งสาม; 08 UI/กล้องที่รองรับทั้งหมด; 09 UAT ของ Phase 1
- ใช้หุ่นและ HUD ขั้นต่ำจาก 06/08 ช่วยทดสอบแผนก่อนหน้าได้ โดยไม่ถือว่า 06/08 ส่งมอบครบแล้ว
- โกล/ลูกนิ่ง/อีเวนต์ใช้ตัวควบคุมฉากฝึกและ state ที่จำเป็น ไม่ดึงวงจรแมตช์เต็ม/นาฬิกา 5 นาที/การโหวต/รางวัลจาก Phase 2 มาทำแทรก
- UI ของระบบสุ่ม/collection/ตลาด/สรุปแมตช์แยกอยู่แผน UI ใน Phase 2; เอฟเฟคตอบสนองพื้นฐานทำใน phase นี้ได้ แต่ระบบสุ่ม/ownership/ชุดเอฟเฟคยังเลื่อน
- หากต้องขยาย scope เพื่อแก้ dependency ให้เสนอการเปลี่ยนก่อน ไม่ดึงระบบ Phase 2 มาเอง

## Gate ก่อน Phase 2
1. ส่งมอบครบสิบแผนรวม 09-uatตาม scope ที่ผู้ใช้เลือกและไม่มี blocking findings ค้าง
2. ตรวจเส้นทางร่วม บอล/ดวล/โกล/ฟาวล์/ลูกนิ่ง/อีเวนต์และการ reset ไม่ทำ state ค้าง
3. มี verification ผ่าน Studio MCP ที่ source/ref ตรง repo และ visual UAT ที่จำเป็น ไม่ใช้ข้อความ APPROVED หรือผลทดลองเก่าเป็นหลักฐาน
4. เอกสารตรงผลงานและผ่าน project review gate ก่อนเริ่ม Phase 2; คำสั่งล่าสุดให้ commit/push เอกสารครั้งนี้ได้ แต่ไม่ใช่คำสั่ง implement/merge/deploy

## Grill เมื่อใกล้ทำ
ตารางชนะทาง/Mistake ใหม่, การควบคุมโกล, ผู้ยิง/กำแพง/จังหวะสอง, รายละเอียดหุ่น, interaction ของอีเวนต์กับ duel/ลูกนิ่ง และรูปแบบ UI; ไม่ถามค่าความเร็ว/แรง/ระยะ/cooldown ที่จูนผ่าน config ภายหลังได้

assets/runs และ milestones ที่ย้ายมาจากโครงเก่าเป็นประวัติ module เดิม ไม่ใช่ผลตรวจของ phase/เลขแผนใหม่ เนื้อหาใน PRD/spec/TDD ที่ขัด decisions ต้อง sync เฉพาะส่วนก่อนเริ่ม implementation ของแต่ละแผน
