# Roadmap — ใช้แผนภายใน Phase โดยตรง

**Phase 1: 00 AUTHORIZED / READY_FOR_AGY; 01–09 PLANNING/PENDING | Phase 2: DEFERRED**

## โครงสร้างและลำดับ
- [Phase 1 — Gameplay Demo](phase-01-gameplay-demo/plan.md): 00 bootstrap/Rig -> 01 สนาม/บอล -> 02 player actions -> 03 Skill Moves/เกมรับ -> 04 โกล -> 05 ลูกนิ่ง -> 06 สนามซ้อม -> 07 อีเวนต์ -> 08 gameplay UI -> 09 UAT
- [Phase 2 — Full Game](phase-02-full-match-and-progression/plan.md): 00 แมตช์ -> 01 ตัดสินเสมอ -> 02 transactions -> 03 สุ่มนักเตะ/stats -> 04 สุ่มสกิล/collection/เศรษฐกิจ -> 05 สุ่มเอฟเฟค -> 06 ตลาด -> 07 meta UI -> 08 integration/UAT

โฟลเดอร์แผนย้ายอยู่ใต้ phase จริงแล้ว ใช้ชื่อ phase + ชื่อแผนเป็นที่อยู่เดียว ไม่มีรหัส feature อีกชุดเพื่อ map ไปยังโฟลเดอร์แผนแบน ๆ เดิม และไม่มีการทำหลายแผนพร้อมกันจากการจัดโครงนี้

## Scope และ gate
- Phase 1 คง feature ที่ผู้ใช้เลือกครบ: สนาม/Rig/physics, movement/เลี้ยง, ยิงส่ง/ชาร์จ, กลางอากาศ/บล็อก, Skill5ท่า/3ช่อง/เกมรับ/recovery, โกลคน/AI, ฟาวล์/ลูกนิ่ง, ซ้อม/หุ่น, อีเวนต์6แบบและUI ที่เกี่ยวข้อง
- ระบบแมตช์เต็ม 5 นาที/ตัดสินเสมอ/สุ่มนักเตะและstats/สุ่มสกิล/collection/สุ่มเอฟเฟค/ตลาด/settingsจริง/first-timepolishรอ Phase 2 หลัง Phase 1 เสร็จครบและผ่าน review gate
- ตัวควบคุมฉากฝึกใน Phase 1 ใช้ทดสอบโกล/ลูกนิ่ง/อีเวนต์ได้ แต่ไม่ถือว่าเปิดวงจรแมตช์เต็ม
- สกิลยิง/ส่งจากการ์ดและ Trait ที่ตัดไม่กลับมาเพียงเพราะเพิ่ม base stats นักเตะ
- กติกาที่ตกลงแล้วเก็บที่ [notes](phase-01-gameplay-demo/01-cage-physics/notes.md) ระบบที่เลื่อนจะ grill เมื่อใกล้ทำ; source หลักคงใน repo และใช้ Studio MCP โดยตรง

## ประวัติและอำนาจ
รายงานเก่า/assets/runs ย้ายตามโฟลเดอร์โดยไม่ลบ ชื่อ/เลขเก่าในรายงานเป็นประวัติ ไม่ใช่ APPROVED ของแผนใหม่ งานที่แยกจากแผนเดิมถูกแบ่งขอบเขตเป็นแผนเฉพาะใน phase ที่ถูกต้องแล้ว

Base SHA `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; Owner Stang, Planner Codex, Implementer/Reviewer ยังไม่มอบหมาย ไม่มีการเปลี่ยน source/รัน application tests/merge/deploy; ผู้ใช้อนุญาต commit/push เฉพาะเอกสารและ .gitignore ในรอบนี้


## Current design update — 2026-10-20
ผู้ใช้อนุญาต Codex ปรับแผน/architecture และยืนยัน Custom R6 ตลอด Phase 1; ใช้ R6 standard locomotion และ root/floor contract ให้แผนถัดไปใช้ Phase 2 ยังไม่กำหนดการย้าย rig คำสั่งนี้ไม่ใช่อนุมัติ source/Studio หรือสิทธิ์ commit/push รอบใหม่


แผน01เพิ่มmap comparison A/B/C (4/8/8ผนัง; Cขอบroof45°) และbase rebound5กรณี แผน07เก็บevent rebound trials ผู้ใช้ยืนยันmarkerไกด์ไม่มีแรงช่วย 2026-10-20 การเพิ่มรายการทดลองไม่ใช่สิทธิ์implementationหรือผลUAT


## Historical implementation authorization — ก่อนรับผลAGY 2026-10-20
Stang สั่ง “เริ่มเลย” อนุมัติ AGY ลงมือเฉพาะแผน00 Custom R6 ตาม HANDOFF ปัจจุบัน ยังไม่ส่งคำสั่งเข้า AGY ผ่านแชตนี้และยังไม่มีผลรัน; 01/07/Phase2 และ Git commit/push/merge/deploy ไม่รวมในการอนุมัติครั้งนี้

## Accepted Q22 — 2026-10-20

ฟุตบอลต่อเนื่องแทนChoice; เก็บDash ท่า3ช่องแทนFeint ตัวเริ่มต้นSkill5ดาว1ตัว+5ท่าฟรี ไม่ขยาย00 รายละเอียด [Spec02](../specs/spec-02-duel-and-parry.md) และN37–N44 ส่วนDebug/DummyPhase1/06และPhase2deferralsระบุในphaseplansแล้ว งานอนุมัติรอบนี้เป็นเอกสารเท่านั้น

Stangสั่ง “ถ้าเสร็จ ไม่มีอะไรค้างแล้ว commit เลย” อนุญาตlocalcommitเอกสารรอบนี้หลังตรวจ consistency/links/diff ไม่รวมsource/ผลรีวิวและไฟล์แผน00/push/merge/deploy; สถานะรายงานเก่าด้านบนเป็นประวัติอำนาจแต่ละรอบไม่ใช่สิทธิ์เพิ่ม
