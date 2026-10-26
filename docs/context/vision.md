> **CURRENT TARGET 2026-10-26 — Street Football:** [authoritative Phase1 plan](../plan/phase-01-gameplay-demo/release-first/plan.md) supersedes conflicting target/delivery statements below (retained as historical/reference). Phase1: R15/core ball + kick/slide/poke/block/normal body-check, separate CombatHP/stun/I-frame, gauge+ground/air Orbs, **RF04 walls BEFORE six Supers**, one-use timed armed Super/manual aim/no homing/no guaranteed goal, capped gauge-rate-only per-copy earnedCash upgrade,2v2/tiedGoldenGoal. Remove foul/free kick/cards/penalties/regular overtime/SuperMastery power scaling. Extra dribble skills/gacha/13stats/Traits/advanced aerial hold+guides/shops deferredPhase2; walls remainPhase1. Owner approved docs commit and checklist7 dribble/receive plus later explicit high momentumjump/four-way airlean and relevant locomotion fixes now; no blanket source implementation/commit/push/publish authority. Owner first6 visual accepted; technical review remains separate. Historical code/reviews/findings not erased.

# Project Vision — Cage Zero

Decision Accepted จาก Q22 / Delivery Planned — 2026-10-20; [ข้อกำหนดเกมเพลย์](../specs/spec-02-duel-and-parry.md) และ [Phase1](../plan/phase-01-gameplay-demo/plan.md) เป็นขอบเขตปัจจุบัน Implementationใหม่ต้องผ่านgateของแผนเจ้าของ

Cage Zero เป็นฟุตบอลสตรีทในกรง3D เน้นการเคลื่อนที่ อ่านวิถีบอล ชิ่งกำแพง/เพดาน เลือกท่าเลี้ยงและเข้าสกัดในจังหวะจริง ใช้รูปลักษณ์อนิเมะบน Custom R6 ของเกม

- ทดลองสนาม A/B/C แบบ4/8/8ผนังและขอบเพดาน45° เลือกจากผลทดสอบ markerเป็นไกด์ไม่มีแรงนำบอล
- ฟุตบอลต่อเนื่อง: ยิง/ส่ง/ยิงโค้ง จังหวะแรก Dash กระโดดล็อกทิศ และเกมรับPoke/Slide/Shoulder ไม่มีChoice Duelหรือคัตซีนล็อกคู่
- บอลยังถูกแย่งได้ตลอด Skill Move5ท่าเลือกใส่3ช่อง ใช้Stamina/cooldown/recoveryเพื่อเปิดช่องตอบโต้
- Phase1มีตัวเริ่มต้น1ตัว Skill Move5ดาว ค่าพื้นฐานกลางและท่าทดลองฟรี R6/หน้าอนิเมะ/No Boots ใช้ต่อจาก00
- Debugจูนค่าการเล่นและเสกDummyเพื่อเทียบสมดุลได้ ระบบตั้งค่าจริงและการบันทึกถาวรอยู่Phase2
- Phase2มีสุ่มตัวละคร/สกิล/เอฟเฟคและระบบแมตช์/เศรษฐกิจ/ตลาด รายละเอียดความต่างผู้เล่นรอออกแบบ โดย Mutations ไม่เพิ่มพลังสนาม
- Serverตรวจบอล/ผู้ครอง/ปุ่มตามทีม/ต้นทุน/คูลดาวน์/ผล contact; clientดูแล input/กล้อง/animation/feedback ไม่มีการตัดสินชนะสกัดจากดาวหรือแอนิเมชันอย่างเดียว

พาธและรายงาน Choice เดิมเป็นประวัติที่ถูกsupersedeตามQ22 ไม่ใช้เป็นสิทธิ์เปิดกลไกเก่า และไม่มีการย้ายเป็นR15ในPhase2โดยอัตโนมัติ
