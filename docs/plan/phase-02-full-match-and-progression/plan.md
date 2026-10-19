# Phase 2 — Full Match, Players, Collection and Market

- **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Hard prerequisite:** [Phase 1](../phase-01-gameplay-demo/plan.md) ส่งมอบครบและผ่าน gate ก่อน ไม่ทำแทรกระหว่างเก็บงาน phase แรก
- [Roadmap](../roadmap.md) / [accepted decisions](../phase-01-gameplay-demo/01-cage-physics/notes.md)
- ใช้เลขและชื่อแผนภายใน phase โดยตรง เก็บแผนระดับสูงไว้ grill เมื่อใกล้ทำ

## แผนใน phase
| Plan | ขอบเขต | Delivery |
| --- | --- | --- |
| [00-match-flow](00-match-flow/plan.md) | วงจรแมตช์และเวลาเล่น | ยังไม่เริ่ม |
| [01-match-tiebreak](01-match-tiebreak/plan.md) | โหวตและตัดสินเสมอ | ยังไม่เริ่ม |
| [02-transactions](02-transactions/plan.md) | Transactions — ธุรกรรม Cash และไอเทม | ยังไม่เริ่ม |
| [03-player-gacha-and-stats](03-player-gacha-and-stats/plan.md) | สุ่มนักเตะ ระดับ และ Stats | ยังไม่เริ่ม |
| [04-collection-and-economy](04-collection-and-economy/plan.md) | Collection อุปกรณ์ และเศรษฐกิจ | ยังไม่เริ่ม |
| [05-effect-gacha](05-effect-gacha/plan.md) | สุ่ม สวมใส่ และสะสมเอฟเฟค | ยังไม่เริ่ม |
| [06-market](06-market/plan.md) | ตลาดแผงและธุรกรรม | ยังไม่เริ่ม |
| [07-meta-ui](07-meta-ui/plan.md) | UI แมตช์ Collection และร้านค้า | ยังไม่เริ่ม |
| [08-integration-and-uat](08-integration-and-uat/plan.md) | Full Integration และ UAT | ยังไม่เริ่ม |

## กติกาที่ต้องรักษา
- แมตช์ปกติไม่เกิน 5 นาทีของเวลาเล่น หยุดหลังประตู/เตรียมลูกนิ่ง แต่คัตซีนส่วนตัว/สโลว์เปิดดวลนับต่อ
- Golden Goal/ต่อเวลามีเพดานของตัวเอง หากหมดแล้วยังเสมอจบทันที; การเลือกเล่นต่อต้องเห็นตรงกัน ส่วน shootout ให้โอกาสเท่ากัน
- สุ่มนักเตะมี Tier/rarity และ stats ชุดเล็ก เช่นยิงแรง/ยิงโค้ง/วิ่งเร็ว/พุ่งสกัด/เลี้ยงบอล เป็นคนละเรื่องกับสกิลยิง/ส่งที่ตัดไป ไม่คืนสกิลเหล่านั้น
- ความต่าง stats 15% ใน spec เดิมยังไม่ถูกสั่งยกเลิก; สูตร/ระดับ/การเติบโต/เรต/ราคาให้ grill ภายหลัง
- เอฟเฟคมีสองชุด ยิง+ส่ง และวิ่ง+กระโดด+โยก ไม่มีสเตตัส; ของซ้ำเลือกเก็บขายหรือสลายแต้ม เอฟเฟคขายผ่านแผง Cash เท่านั้น ไม่มี P2P เอฟเฟค
- P2P ของสินค้ากลุ่มเดิมยังไม่ถูกลบทั้งเกม คงข้อห้ามรองเท้าสตั๊ด/Mutations เพิ่มพลังสนาม และ cooldown สกิลที่ยังเก็บ
- ก่อนเปิดแต่ละแผนให้ grill เรื่องที่ยังเปิดและ sync PRD/spec/TDD/API/data/UI ตาม accepted deltas ไม่ออกแบบ implementation ล่วงหน้าทั้ง phase

- 02-transactions เป็นฐานธุรกรรม Cash/ไอเทมร่วม ก่อนเปิดกาชา/collection/ตลาด; 08-integration-and-uat เป็น gate ท้าย phase ทั้งหมด
