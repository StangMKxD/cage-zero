# RF-03: R15 Skill Moves & Defense — Notes

- **Date:** 2026-10-25
- **Status:** Planning / Documentation Synchronized
- **Related Docs:**
  - [Release-First Track Plan](../plan.md)
  - [RF-02 Plan](../RF-02/plan.md)
  - [Legacy Plan 03 Cancelled Notes](../../03-dribble-duel/notes.md)

---

## 1. Design Evolution & R15 Decision

- ใน legacy Plan 03 เดิม ทีมงานพยายามดัดแปลงท่า R6 ให้มีทัศนวิสัยที่ดีขึ้น แต่พบปัญหาเรื่องความแข็งของข้อต่อและความไม่เป็นธรรมชาติเมื่อเทียบกับฟุตบอลสตรีทจริง
- คำสั่ง Owner 2026-10-25 ให้ยกเลิกแผน 03 เดิมและย้ายมา R15 ส่งผลให้เราสามารถใช้ประโยชน์จากการบิดตัวของเอวและข้อต่อขา R15 ในการถ่ายทอดน้ำหนักการหลอกล่อ (เช่น Body Feint) ได้อย่างสมบูรณ์แบบ
- **Owner Target Delta (2026-10-25):** กำหนดให้ใช้ **Player Avatar R15 (Normalized to Same Body Dimensions)** โดยผู้เล่นใช้อวาตารของตนเองแต่ขนาดและมิติร่างกายถูก Normalize เท่ากันทุกคน ส่งผลให้การทำ Skill Moves ต้องคำนึงถึง Animation Retargeting และ Contact Frame Sync เพื่อให้จุดเตะ/สัมผัสบอลบนอวาตารที่หลากหลายมีความแม่นยำและไม่เกิด Visual Desync หรือ Hitbox คลาดเคลื่อน

---

## 2. Launch 3 Skills vs Preserved 4 Skills

- **3 ท่าที่คัดเลือกสำหรับ Alpha Launch:**
  1. *Heavy Knock-On (1★):* สกิลระดับพื้นฐาน เน้นการฉีกพื้นที่ว่าง เหมาะกับผู้เล่นสายความเร็ว
  2. *Open Up Fake Shot (1★):* สกิลหลอกดึงจังหวะ เหมาะกับการดวล 1v1 หน้าปากประตู
  3. *Body Feint (2★):* สกิลหลอกเปลี่ยนทิศทางแบบคลาสสิก เหมาะกับการเลี้ยงตัดแนวรับ
- **4 ท่าที่เก็บรักษาไว้เป็น Future Catalog ใน Phase 2:**
  - Heel Chop (3★)
  - Sombrero Flick (4★)
  - Lane Change (4★)
  - Elastico (5★)
  *(ทุกท่าจะยังคงมีเอกสารและ Reference Assets เก็บไว้ในโปรเจกต์ ไม่ถูกลบทิ้ง)*

---

## 3. Defense Balance & Body Check (PENDING Decision)

- **Owner Decision Gate on Body Check:**
  - การตัดสินใจว่า **Body Check** จะรวมอยู่ใน Alpha Launch หรือเลื่อน (Defer) ไป Phase 2 เป็น **PENDING Owner Decision** เท่านั้น
  - Implementer ไม่มีสิทธิ์อนุญาตข้อยกเว้นขอบเขตด้วยตนเอง หรือตัดทิ้ง/สั่ง Defer โดยพลการ
  - ในระหว่างรอการตัดสินใจ สเปกต้องคงนิยาม **Forward Body Check** (การพุ่งปะทะทางด้านหน้า, Physical Strength check, Loose Ball, No Auto-Possession, No I-frame, Recovery Delay) และ Target Key Mapping ตามมติ Owner Q6: **RMB** (คู่กับ LMB: Shoot/Slide, E: Pass/Poke; MMB ปลดระวาง; ไม่อนุญาตให้ใช้ปุ่ม F) ไว้ครบถ้วน ไม่ปรับลดเป็นเพียง Shoulder Barge
  - การแย่งบอลหลักของ Alpha ปัจจุบันยืนพื้นด้วย **Slide Tackle** (RF-02) และ **Quick Poke** (RF-02)

---

## 4. Resource & Timing Model (No Per-Move Cooldowns)

- สอดคล้องตามคำสั่ง Owner U2: **ยกเลิก Per-move Gameplay Cooldown ทั้งหมด**
- การควบคุมจังหวะการใช้ทักษะ (Skill Moves) อาศัยเพียง Stamina Cost, Recovery Window/Delay หลังจบท่า และ Transport/Sprint limits เท่านั้น ไม่มี Cooldown แยกรายท่าขัดขวางจังหวะการเล่น
