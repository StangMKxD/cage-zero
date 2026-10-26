> **CURRENT TARGET 2026-10-26 — Street Football:** [authoritative Phase1 plan](release-first/plan.md) supersedes conflicting target/delivery statements below (retained as historical/reference). Phase1: R15/core ball + kick/slide/poke/block/normal body-check, separate CombatHP/stun/I-frame, gauge+ground/air Orbs, **RF04 walls BEFORE six Supers**, one-use timed armed Super/manual aim/no homing/no guaranteed goal, capped gauge-rate-only per-copy earnedCash upgrade,2v2/tiedGoldenGoal. Remove foul/free kick/cards/penalties/regular overtime/SuperMastery power scaling. Extra dribble skills/gacha/13stats/Traits/advanced aerial hold+guides/shops deferredPhase2; walls remainPhase1. Owner approved docs commit and checklist7 dribble/receive plus later explicit high momentumjump/four-way airlean and relevant locomotion fixes now; no blanket source implementation/commit/push/publish authority. Owner first6 visual accepted; technical review remains separate. Historical code/reviews/findings not erased.

# Phase 1 — Gameplay Demo & Release-First Track

- **State:** RELEASE_FIRST_PROPOSED / R15_RESTART; คำสั่ง Owner 2026-10-25 ยกเลิก legacy 02/03 (`CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART`) เพื่อเดินหน้า [Release-First Track](release-first/plan.md) บน **Player Avatar R15 (Normalized to Same Body Dimensions)** (`RF-02` ถึง `RF-07`) มุ่งสู่ Public Alpha (แทนที่ Custom Blocky R15 เดิม; รักษารูปลักษณ์ผู้เล่นแต่บังคับขนาดร่างกายเท่ากันทั้งหมด; ขนาดไม่เปลี่ยนตาม Stats/Cards); 00/01 ยังเปิด; Phase 2 เลื่อน
- **Owner:** Stang; Controller/Reviewer: Codex; Implementer: agyplan w2:p49 (Docs only ในรอบนี้)
- **Baseline:** main @ `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + working tree ตาม HANDOFF
- [Roadmap](../roadmap.md) / [Release-First Master Plan](release-first/plan.md) / [ข้อสรุปกติกา](01-cage-physics/notes.md) / [Phase 2](../phase-02-full-match-and-progression/plan.md)

## Release-First Track (Active Target — Restart on Player Avatar R15 Equal Size)

| Plan | Scope | Target Delivery |
| --- | --- | --- |
| [RF-02 Core Football & R15 Foundation](release-first/RF-02/plan.md) | Player Avatar R15 Normalized, Ball/Contact, Pass/Shoot/Volley/Whiff, Slide/Poke, Profile & Config | PROPOSED / DOCS_SYNCED |
| [RF-03 R15 Skill Moves & Defense](release-first/RF-03/plan.md) | 3 Launch Skills (Heavy Knock-On, Open Up Fake Shot, Body Feint), 3 Slots, Stamina/Recovery, Counterplay | PROPOSED / DOCS_SYNCED |
| [RF-04 Cage Slingshot](release-first/RF-04/plan.md) | Stadium A 4 Walls/Ceiling, Wall Run, Wall Launch, Aerial Intercept/Volley | PROPOSED / DOCS_SYNCED |
| [RF-05 Gacha, Stats & Traits](release-first/RF-05/plan.md) | 3 ตัวละครต้นแบบ, 13 Outfield Stats, 3–4 Active Traits, Cash Gacha | PROPOSED / DOCS_SYNCED |
| [RF-06 Match, HUD & Economy](release-first/RF-06/plan.md) | Casual 2v2, Concise HUD, 1 Cosmetic Shop, Match Reward Commit | PROPOSED / DOCS_SYNCED |
| [RF-07 Publish Gate](release-first/RF-07/plan.md) | Robux Definite Outcome Product, Multi-client UAT, ProcessReceipt, Owner Publish | PROPOSED / DOCS_SYNCED |

## โครงสร้างเดิม (Legacy Plans & Historical Status)
| Plan | ขอบเขต | Delivery / สถานะปัจจุบัน |
| --- | --- | --- |
| [00-bootstrap-and-rig](00-bootstrap-and-rig/plan.md) | Bootstrap และ Custom R6 | OPEN / PAUSED_BY_OWNER (เก็บ Upgrade/Monetization specs) |
| [01-cage-physics](01-cage-physics/plan.md) | กรง3D A/B/C และฟิสิกส์บอล | OPEN / PENDING_TECHNICAL_REVIEW; บอลฟิสิกส์คงค่าเดิม |
| [02-player-actions](02-player-actions/plan.md) | บอล/movement/teaminputs/first-time + selectiveSandbox/Slide/เกจ | **CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART** (แทนที่ด้วย RF-02) |
| [03 — Skill Moves/เกมรับ](03-dribble-duel/plan.md) | เป้าหมาย 7 ท่าไม่ซ้ำ/3ช่อง (5 แอนิเมชันเดิม) | **CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART** (แทนที่ด้วย RF-03) |
| [04-goalkeepers](04-goalkeepers/plan.md) | ผู้รักษาประตูคนและ AI | เลื่อนไป Phase 2 (Casual 2v2 ไม่บังคับ GK AI) |
| [05-fouls-and-set-pieces](05-fouls-and-set-pieces/plan.md) | ฟาวล์ ฟรีคิก และจุดโทษ FC27 | เลื่อนไป Phase 2 (ใช้เกมเพลย์ต่อเนื่องใน Alpha) |
| [06-training-ground](06-training-ground/plan.md) | สนามซ้อม Debugจูนค่าการเล่น (13 Stats, 16 Traits, 5 Presets) และเสก/จัดDummy | รวมเฉพาะ Debug/Config ใน RF-02/RF-05; โหมดซ้อมเต็มเลื่อน |
| [07-dynamic-field-events](07-dynamic-field-events/plan.md) | อีเวนต์สนาม6แบบ | Wall Rebound รวมใน RF-04; อีเวนต์เต็มเลื่อน |
| [08-gameplay-ui](08-gameplay-ui/plan.md) | UI กล้อง และ feedback ของ Demo | รวม Concise HUD ใน RF-06; Full UI เลื่อน |
| [09-uat](09-uat/plan.md) | UAT — Gameplay Demo | รวมเข้ากับ Multi-client UAT ใน RF-07 |

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
