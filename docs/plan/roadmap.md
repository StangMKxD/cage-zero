> **CURRENT TARGET 2026-10-26 — Street Football:** [authoritative Phase1 plan](phase-01-gameplay-demo/release-first/plan.md) supersedes conflicting target/delivery statements below (retained as historical/reference). Phase1: R15/core ball + kick/slide/poke/block/normal body-check, separate CombatHP/stun/I-frame, gauge+ground/air Orbs, **RF04 walls BEFORE six Supers**, one-use timed armed Super/manual aim/no homing/no guaranteed goal, capped gauge-rate-only per-copy earnedCash upgrade,2v2/tiedGoldenGoal. Remove foul/free kick/cards/penalties/regular overtime/SuperMastery power scaling. Extra dribble skills/gacha/13stats/Traits/advanced aerial hold+guides/shops deferredPhase2; walls remainPhase1. Owner approved docs commit and checklist7 dribble/receive plus later explicit high momentumjump/four-way airlean and relevant locomotion fixes now; no blanket source implementation/commit/push/publish authority. Owner first6 visual accepted; technical review remains separate. Historical code/reviews/findings not erased.

# Roadmap — ใช้แผนภายใน Phase โดยตรง

**Phase 1: Release-First Track (`RF-02`..`RF-07`) PROPOSED / DOCUMENTATION_SYNCED (Restart on Player Avatar R15 Equal Size); Legacy 02/03 CANCELLED_BY_OWNER; 00/01 OPEN; Phase 2: DEFERRED**

## โครงสร้างและลำดับ
- **[Release-First Track (Active Target)](phase-01-gameplay-demo/release-first/plan.md):** [RF-02 Core Football & R15 Foundation](phase-01-gameplay-demo/release-first/RF-02/plan.md) -> [RF-03 R15 Skill Moves & Defense](phase-01-gameplay-demo/release-first/RF-03/plan.md) -> [RF-04 Cage Slingshot](phase-01-gameplay-demo/release-first/RF-04/plan.md) -> [RF-05 Gacha, Stats & Traits](phase-01-gameplay-demo/release-first/RF-05/plan.md) -> [RF-06 Match, HUD & Economy](phase-01-gameplay-demo/release-first/RF-06/plan.md) -> [RF-07 Publish Gate](phase-01-gameplay-demo/release-first/RF-07/plan.md) -> **Public Alpha**
- [Phase 1 — Gameplay Demo (Historical Structure)](phase-01-gameplay-demo/plan.md): 00 bootstrap/Rig -> 01 สนาม/บอล -> legacy 02/03 (ยกเลิกแล้ว) -> 04–09 (เลื่อน/รวมใน RF track)
- [Phase 2 — Full Game](phase-02-full-match-and-progression/plan.md): 00 แมตช์ -> 01 ตัดสินเสมอ -> 02 transactions -> 03 สุ่มนักเตะ/stats -> 04 สุ่มสกิล/collection/เศรษฐกิจ -> 05 สุ่มเอฟเฟค -> 06 ตลาด -> 07 meta UI -> 08 integration/UAT

## Owner Override 2026-10-25 — R15 Restart & Release-First Track
คำสั่ง Owner 2026-10-25 ยกเลิก legacy Plan 02 (`02-player-actions`) และ 03 (`03-dribble-duel`) เดิม (`CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART`) เพื่อเปลี่ยน Rig Target เป็น **Player Avatar R15 (Normalized to Same Body Dimensions)** (แทนที่ Custom Blocky R15 เดิม; รักษาอัตลักษณ์ผู้เล่นแต่บังคับขนาดร่างกายเท่ากันทั้งหมด; ขนาดไม่เปลี่ยนตาม Stats/Cards) และเดินหน้าแผนงาน 6 แผนของ Release-First Track มุ่งสู่ Public Alpha โดยเก็บรักษา source code, assets, reviews, และ unresolved findings เดิมไว้เป็นประวัติศาสตร์ครบถ้วน ไม่ใช่การยกเลิก Phase 2 ทั้งหมด

โฟลเดอร์แผนย้ายอยู่ใต้ phase จริงแล้ว ใช้ชื่อ phase + ชื่อแผนเป็นที่อยู่เดียว ไม่มีรหัส feature อีกชุดเพื่อ map ไปยังโฟลเดอร์แผนแบน ๆ เดิม และไม่มีการทำหลายแผนพร้อมกันจากการจัดโครงนี้

## Scope และ gate
- Phase 1 คง feature ที่ผู้ใช้เลือกครบ: สนาม/Rig/physics, movement/เลี้ยง, ยิงส่ง/ชาร์จ, กลางอากาศ/บล็อก, Skill Moves (เป้าหมาย 7 ท่าไม่ซ้ำ / 3 ช่อง, 5 ท่าแอนิเมชันอยู่ระหว่างปรับแก้รอตรวจรับ)/เกมรับ/recovery, โกลคน/AI, ฟาวล์/ลูกนิ่ง, ซ้อม/หุ่น, อีเวนต์6แบบและUI ที่เกี่ยวข้อง
- ระบบแมตช์เต็ม 5 นาที/ตัดสินเสมอ/สุ่มนักเตะและ 13 Outfield Stats/16 Innate Traits/5 Archetypes/สุ่มสกิล/collection/สุ่มเอฟเฟค/ตลาด/settingsจริง/first-timepolishรอ Phase 2 หลัง Phase 1 เสร็จครบและผ่าน review gate
- ตัวควบคุมฉากฝึกใน Phase 1 ใช้ทดสอบโกล/ลูกนิ่ง/อีเวนต์ และมีแผง Debug จูน 13 Stats / 16 Traits / 5 Presets เฉพาะ session ได้ แต่ไม่ถือว่าเปิดวงจรแมตช์เต็ม
- สกิลยิง/ส่งจากการ์ดและ Trait ที่ตัดไม่กลับมา; Traits เป็นคุณสมบัติติดตัวละครเท่านั้น (Innate Traits 0, 1, 2, ... รายการ) และถอดระบบ Trait Slots บนชุด Battle Threads ออกจาก Target
- **Foundation Architecture Extension (DOCS-ARCH-20261024):** ออกแบบสเปกสถาปัตยกรรมรากฐานใน Plan 00 สำหรับระบบอัปเกรด/Limit Break (+0 ถึง +5) และระบบ Monetization/Visual Identity/Celebration ตามคำตัดสิน Owner U1–U13 รายละเอียดใน [Upgrade Design](phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/upgrade-limit-break.md) และ [Monetization Design](phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/monetization-identity-celebration.md); การลงโค้ดจริงยัง DEFERRED
- กติกาที่ตกลงแล้วเก็บที่ [notes](phase-01-gameplay-demo/01-cage-physics/notes.md) (รวม [N-61](phase-01-gameplay-demo/01-cage-physics/notes.md#n-61--accepted-decision-13-outfield-base-stats-4-deferred-gk-stats-16-innate-traits-5-character-archetypes-and-body-check-target-mechanics-2026-10-24)) ระบบที่เลื่อนจะ grill เมื่อใกล้ทำ; source หลักคงใน repo และใช้ Studio MCP โดยตรง

## ประวัติและอำนาจ
รายงานเก่า/assets/runs ย้ายตามโฟลเดอร์โดยไม่ลบ ชื่อ/เลขเก่าในรายงานเป็นประวัติ ไม่ใช่ APPROVED ของแผนใหม่ งานที่แยกจากแผนเดิมถูกแบ่งขอบเขตเป็นแผนเฉพาะใน phase ที่ถูกต้องแล้ว

Base SHA `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; Owner Stang, Planner Codex, Implementer/Reviewer ยังไม่มอบหมาย ไม่มีการเปลี่ยน source/รัน application tests/merge/deploy; ผู้ใช้อนุญาต commit/push เฉพาะเอกสารและ .gitignore ในรอบนี้


## Current design update — 2026-10-20
ผู้ใช้อนุญาต Codex ปรับแผน/architecture และยืนยัน Custom R6 ตลอด Phase 1; ใช้ R6 standard locomotion และ root/floor contract ให้แผนถัดไปใช้ Phase 2 ยังไม่กำหนดการย้าย rig คำสั่งนี้ไม่ใช่อนุมัติ source/Studio หรือสิทธิ์ commit/push รอบใหม่


แผน01เพิ่มmap comparison A/B/C (4/8/8ผนัง; Cขอบroof45°) และbase rebound5กรณี แผน07เก็บevent rebound trials ผู้ใช้ยืนยันmarkerไกด์ไม่มีแรงช่วย 2026-10-20 การเพิ่มรายการทดลองไม่ใช่สิทธิ์implementationหรือผลUAT


## Historical implementation authorization — ก่อนรับผลAGY 2026-10-20
Stang สั่ง “เริ่มเลย” อนุมัติ AGY ลงมือเฉพาะแผน00 Custom R6 ตาม HANDOFF ปัจจุบัน ยังไม่ส่งคำสั่งเข้า AGY ผ่านแชตนี้และยังไม่มีผลรัน; 01/07/Phase2 และ Git commit/push/merge/deploy ไม่รวมในการอนุมัติครั้งนี้

## Accepted Q22 — 2026-10-20

ฟุตบอลต่อเนื่องแทนChoice; เก็บDash ท่า3ช่องแทนFeint ตัวเริ่มต้นSkill5ดาว1ตัว (ประวัติเดิม5ท่าฟรี ปัจจุบันเป้าหมาย 7 ท่าไม่ซ้ำ/3ช่องตาม HANDOFF §Q) ไม่ขยาย00 รายละเอียด [Spec02](../specs/spec-02-duel-and-parry.md) และN37–N44 ส่วนDebug/DummyPhase1/06และPhase2deferralsระบุในphaseplansแล้ว งานอนุมัติรอบนี้เป็นเอกสารเท่านั้น

Stangสั่ง “ถ้าเสร็จ ไม่มีอะไรค้างแล้ว commit เลย” อนุญาตlocalcommitเอกสารรอบนี้หลังตรวจ consistency/links/diff ไม่รวมsource/ผลรีวิวและไฟล์แผน00/push/merge/deploy; สถานะรายงานเก่าด้านบนเป็นประวัติอำนาจแต่ละรอบไม่ใช่สิทธิ์เพิ่ม
