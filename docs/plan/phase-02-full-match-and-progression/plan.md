# Phase 2 — Full Match, Players, Collection and Market

- **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_RELEASE_FIRST_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Directive Note (2026-10-25):** คำสั่ง Owner ยกเลิกเฉพาะ legacy Plan 02/03 เดิม ไม่ใช่การยกเลิก Phase 2 ทั้งหมด; Phase 2 ยังคงอยู่ครบถ้วนและจะเปิดดำเนินการเมื่อ [Phase 1 Release-First Track](../phase-01-gameplay-demo/release-first/plan.md) ส่งมอบ Public Alpha สำเร็จ ทั้งนี้รากฐาน Profile และ Cash Gacha เริ่มต้นได้ถูกดึงไปเตรียมความพร้อมล่วงหน้าใน RF-02, RF-05 และ RF-06 แล้ว
- **Hard prerequisite:** [Phase 1 Release-First Track](../phase-01-gameplay-demo/release-first/plan.md) ส่งมอบครบและผ่าน gate ก่อน ไม่ทำแทรกระหว่างเก็บงาน phase แรก
- [Roadmap](../roadmap.md) / [accepted decisions](../phase-01-gameplay-demo/01-cage-physics/notes.md)
- ใช้เลขและชื่อแผนภายใน phase โดยตรง เก็บแผนระดับสูงไว้ grill เมื่อใกล้ทำ

## แผนใน phase
| Plan | ขอบเขต | Delivery |
| --- | --- | --- |
| [00-match-flow](00-match-flow/plan.md) | วงจรแมตช์และเวลาเล่น | ยังไม่เริ่ม |
| [01-match-tiebreak](01-match-tiebreak/plan.md) | โหวตและตัดสินเสมอ | ยังไม่เริ่ม |
| [02-transactions](02-transactions/plan.md) | Transactions — ธุรกรรม Cash และไอเทม | ยังไม่เริ่ม |
| [03-player-gacha-and-stats](03-player-gacha-and-stats/plan.md) | สุ่มนักเตะ ระดับ 13 Outfield Stats, 4 Deferred GK, 16 Innate Traits, 5 Archetypes | ยังไม่เริ่ม |
| [04-collection-and-economy](04-collection-and-economy/plan.md) | สุ่มสกิล Skill Inventory/Collection และเศรษฐกิจ | ยังไม่เริ่ม |
| [05-effect-gacha](05-effect-gacha/plan.md) | สุ่ม สวมใส่ และสะสมเอฟเฟค | ยังไม่เริ่ม |
| [06-market](06-market/plan.md) | ตลาดแผงและธุรกรรม | ยังไม่เริ่ม |
| [07-meta-ui](07-meta-ui/plan.md) | UI แมตช์ Collection ร้านค้า และระบบตั้งค่าฉบับใช้งานจริง | ยังไม่เริ่ม |
| [08-integration-and-uat](08-integration-and-uat/plan.md) | Full Integration และ UAT | ยังไม่เริ่ม |

## กติกาที่ต้องรักษา
- แมตช์ปกติไม่เกิน 5 นาทีของเวลาเล่น หยุดหลังประตู/เตรียมลูกนิ่ง ไม่มีสโลว์เปิดดวล/คัตซีนล็อกคู่จากQ22
- Golden Goal/ต่อเวลามีเพดานของตัวเอง หากหมดแล้วยังเสมอจบทันที; การเลือกเล่นต่อต้องเห็นตรงกัน ส่วน shootout ให้โอกาสเท่ากัน
- สุ่มนักเตะมี Tier/rarity, 13 Outfield Base Stats (ขอบเขต 0.90–1.15 หรือ −10% ถึง +15%), 16 Innate Traits (ติดตัวละครเท่านั้น ผันแปร 0, 1, 2, ... รายการ ไม่มีหิน Trait บนชุด), และ 5 Archetypes (เพดาน 2★–5★) เป็นคนละเรื่องกับสกิลยิง/ส่งที่ตัดไป ไม่คืนสกิลเหล่านั้น
- ขอบเขต Base Stats 0.90–1.15 บังคับเฉพาะ Base Stats ส่วน Trait ตามเงื่อนไขทะลุเกินได้; สูตร/ระดับ/การเติบโต/เรต/ราคา/pity/reroll ให้ grill ภายหลังเมื่อเปิดแผน
- เอฟเฟคมีสองชุด ยิง+ส่ง และวิ่ง+กระโดด+โยก ไม่มีสเตตัส; ของซ้ำเลือกเก็บขายหรือสลายแต้ม เอฟเฟคขายผ่านแผง Cash เท่านั้น ไม่มี P2P เอฟเฟค
- P2P ของสินค้ากลุ่มเดิมยังไม่ถูกลบทั้งเกม คงข้อห้ามรองเท้าสตั๊ด/Mutations เพิ่มพลังสนาม และ cooldown สกิลที่ยังเก็บ
- ก่อนเปิดแต่ละแผนให้ grill เรื่องที่ยังเปิดและ sync PRD/spec/TDD/API/data/UI ตาม accepted deltas ไม่ออกแบบ implementation ล่วงหน้าทั้ง phase

- 02-transactions เป็นฐานธุรกรรม Cash/ไอเทมร่วม ก่อนเปิดกาชา/collection/ตลาด; 08-integration-and-uat เป็น gate ท้าย phase ทั้งหมด
- คำสั่งผู้ใช้2026-10-20: Debugจูนความเร็ว/ค่าทดสอบและเสกDummyอยู่Phase1/06; ระบบตั้งค่าฉบับใช้งานจริง/ค่าถาวรเลื่อนมา07-meta-uiของPhase2 รายละเอียดรอgrill ไม่เปิดimplementationจากบันทึกนี้

## Gameplay extension queue หลัง Q22 — Accepted / Deferred

- ต้องมีสามระบบสุ่ม: ตัวละคร03, สกิล/Skill Inventory04, เอฟเฟค05; Phase1ใช้ตัวเริ่มต้นSkillMove5ดาวและเป้าหมายสกิล 7 ท่าไม่ซ้ำ 3 ช่อง (โดย 5 แอนิเมชันเดิมอยู่ระหว่างปรับแก้รอตรวจรับ) เท่านั้น
- เพิ่มท่าที่เหลือ/ความต่างดาวและStatsเมื่อเปิดแผนเจ้าของ ไม่ตีความชุดทดลองเป็น15ท่าในPhase1
- เพิ่มแอนิเมชันยิง/ส่งจังหวะแรกและเสียจังหวะเมื่อวืดในPhase2 ต้องแยกimplementationcontractของงานขยาย02ก่อนทำและก่อน08Full UAT; รอบนี้ล็อกเพียงdelivery phase ไม่ออกแบบassets/timingหรือย้ายimplementationไปทำในแผนทดสอบ
- ระบบตั้งค่าจริง/ค่าถาวรอยู่07-meta-ui ส่วนDebug/Dummysessionอยู่Phase1/06 คงเดิม
- trait/การ์ดที่อ้างผลชนะChoiceอัตโนมัติต้องทบทวนก่อนใช้กับฟุตบอลต่อเนื่อง ไม่มีI-frame/คัตซีนล็อกคู่กลับมาจากschemaหรือreportเก่า
