# RF-03: R15 Skill Moves & Defense — Plan

- **Plan State:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED; awaiting Owner approval)
- **Track:** Phase 1 Release-First
- **Predecessor:** Legacy Plan 03 (`03-dribble-duel`) CANCELLED_BY_OWNER; this is a brand new plan designed on R15.
- **Authority:** Owner Directive 2026-10-25 ([owner-r15-restart.md](../assets/owner-r15-restart.md)), Primary [HANDOFF.md](../assets/HANDOFF.md), and [Release-First Track Plan](../plan.md).
- **Target Rig:** Player Avatar R15 (Normalized to Same Body Dimensions).

---

## 1. Context & Motivation

Legacy Plan 03 (`03-dribble-duel`) ถูกยกเลิกตามคำสั่ง Owner 2026-10-25 เนื่องจากแอนิเมชันเดิมผูกกับโครงสร้าง R6 แผน **RF-03** นี้จึงเป็นแผนใหม่ที่สร้างขึ้นบน **Player Avatar R15 (Normalized to Same Body Dimensions)** สำหรับทักษะการเลี้ยงและหลอกล่อ (Skill Moves) จำนวน 3 ท่าหลักที่จะใช้เปิดตัวใน Public Alpha พร้อมทั้งกำหนดกลไกเกมรับขั้นสูงและการตอบโต้ (Counterplay) โดยผู้เล่นใช้อวาตารของตนเองแต่มีมิติร่างกายและจุดสัมผัสบอลที่ได้มาตรฐานเท่ากันทุกคน

---

## 2. AS-IS / TARGET / DELTA

### AS-IS (สถานะปัจจุบัน)
- **Legacy 03 Assets:** มีร่างแอนิเมชัน R6 เดิม 5 ท่าในคลัง assets และมีแนวคิด 7 ท่าเดิม แต่ไม่สามารถนำ Clip R6 มาใช้กับ R15 ได้โดยตรง
- **Skill Loadout System:** ยังไม่มีระบบติดตั้งสกิลลง 3 ช่องบน R15
- **Defense System:** มีสไลด์และสะกิดพื้นฐานจาก RF-02 แต่ยังขาดการตัดสินใจเรื่อง Body Check สำหรับการเปิดตัว Alpha

### TARGET (เป้าหมายใหม่บน R15)
- **3 Launch Skill Moves:**
  1. **Heavy Knock-On (1★):** แตะบอลยาวไปข้างหน้าแล้วเร่งสปีดฉีกตัวประกบ
  2. **Open Up Fake Shot (1★):** หลอกง้างเท้ายิงเพื่อหลอกดึงจังหวะคู่แข่งแล้วกระชากบอลเปลี่ยนทาง
  3. **Body Feint (2★):** โยกหลอกลำตัวเพื่อทิ้งน้ำหนักหลอกกองหลังแล้วตัดบอลไปอีกด้าน
- **Skill Slot System:** ผู้เล่นมีช่องติดตั้งสกิล 3 ช่อง (Slot 1, Slot 2, Slot 3) สามารถเลือกท่าที่ต้องการลงช่องได้
- **Resource & Timing Model:**
  - สกิลแต่ละท่ามีต้นทุน Stamina ชัดเจน
  - มีเฟรม Windup → Anticipation → Body Motion → Ball Contact Frame → Ball Impulse → Recovery Window
  - **No Invulnerability (No I-frame):** ลูกบอลและตัวผู้เล่นสามารถถูกสกัดหรือแย่งได้ตลอดทุกเฟรมของท่า
  - **No per-move gameplay cooldowns:** ยกเลิก Cooldown ประจำท่าทั้งหมดตามคำสั่ง Owner U2; จังหวะการใช้ท่าถูกควบคุมด้วย Stamina Cost, Recovery Window/Delay, และ Transport/Sprint limits เท่านั้น
- **Defense Scope (Body Check Decision — PENDING):**
  - **สถานะ Body Check:** กำหนดสถานะการรวมใน Launch หรือการเลื่อน (Launch Inclusion vs Deferral) เป็น **PENDING Owner Decision** เท่านั้น (Implementer ไม่มีสิทธิ์อนุญาตข้อยกเว้นขอบเขตด้วยตนเอง)
  - **Target Control Mapping (ตามมติ Owner Q6):**
    - **LMB:** ยิงประตู Shoot (เกมรุก) / สไลด์สกัด Slide Tackle (เกมรับ)
    - **E:** ส่งบอล Pass (เกมรุก; คงข้อยกเว้น Core charging E-FakeShot ไว้) / สะกิดแย่ง Quick Poke (เกมรับ)
    - **RMB:** ยิงไซด์โค้ง Direct Curve (เกมรุก) / พุ่งปะทะด้านหน้า Forward Body Check (เกมรับ)
    - **MMB:** ปลดระวาง (Retire MMB)
    *(ไม่อนุญาตให้ใช้ปุ่ม `F`; คืนค่า Target Control Mapping ตามมติ Q6 ของ Owner โดยสมบูรณ์)*
  - **Semantics:** คงคุณสมบัติ Forward Body Check (การพุ่งปะทะทิศทางด้านหน้า, ตรวจสอบค่า Physical Strength, ผลลัพธ์เป็น Loose Ball ลูกบอลหลุดเป็นอิสระ, ไม่มีการครอบครองบอลอัตโนมัติ No Auto-Possession, ไม่มีช่วงอมตะ No I-frame, และมี Recovery Window หลังการปะทะ) ไว้ในสเปกครบถ้วน
  - การแย่งบอลหลักของ Alpha ปัจจุบันยืนพื้นด้วย Slide Tackle (LMB) และ Quick Poke (E) จาก RF-02
- **Catalog Skills Preservation:**
  - อีก 4 ท่าใน Catalog ได้แก่ **Heel Chop (3★)**, **Sombrero Flick (4★)**, **Lane Change (4★)**, และ **Elastico (5★)** จะถูกเก็บรักษาในฐานะ Future Catalog และ Reference Assets สำหรับ Phase 2 โดยไม่ลบทิ้ง

### DELTA
1. ออกแบบและสร้างแอนิเมชันบน Player Avatar R15 (Normalized to Same Body Dimensions) สำหรับ 3 ท่าเปิดตัว พร้อมระบบ Contact Frame Synchronization
2. พัฒนาระบบ Skill Controller และ Ball Synchronization เชื่อมแรงผลักบอล (Ball Impulse) ให้ตรงกับ Contact Frame ของ R15
3. วางระบบ 3 Skill Slots และการจับคู่ปุ่มกด (Keybinding mapping)
4. กำหนดและจูนค่า Stamina Cost / Recovery Duration ใน `BalanceConfig`
5. ทดสอบการตอบโต้ (Counterplay) และจัดรอบ Owner Visual UAT แยกรายท่า

---

## 3. Acceptance Criteria

1. **R15 Skill Choreography:**
   - ท่า Heavy Knock-On, Open Up Fake Shot, และ Body Feint มีท่วงท่า R15 ที่ชัดเจน ลำตัวบิดและขยับสอดคล้องกับจุดกระทบบอล
2. **Ball Synchronization:**
   - ลูกบอลเคลื่อนที่ออกจากเท้าตรงกับ Contact Frame ของแอนิเมชันอย่างแม่นยำ ไม่ดีเลย์และไม่วาร์ป
3. **Counterplay & Fair Defense:**
   - ผู้เล่นฝ่ายรับสามารถใช้ Slide Tackle หรือ Quick Poke แย่งบอลจากผู้เล่นที่กำลังทำ Skill Move ได้จริงหากเข้าถูกจังหวะ
4. **Stamina & Recovery:**
   - หาก Stamina ไม่เพียงพอ ผู้เล่นไม่สามารถเริ่มท่าได้
   - จบท่ามี Recovery Window ที่จำกัดการกดท่าซ้ำทันที
5. **Slot Management:**
   - ผู้เล่นสามารถติดตั้ง 3 ท่าลงใน 3 ช่องได้อย่างถูกต้อง
6. **Owner Visual Acceptance:**
   - แต่ละท่าต้องผ่านการตรวจรับทางสายตาจาก Owner รายท่า (Per-skill Sign-off)

---

## 4. Rollback & Safety

- หากแอนิเมชันท่าใดมีปัญหา สามารถปิดการติดตั้งท่านั้นใน Loadout โดยไม่กระทบกับอีก 2 ท่าที่เหลือ
- ค่า Parameter ทั้งหมด (Stamina, Impulses, Timings) ควบคุมผ่าน `BalanceConfig`
