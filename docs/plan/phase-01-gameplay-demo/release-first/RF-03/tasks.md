# RF-03: R15 Skill Moves & Defense — Tasks

- **Plan:** [RF-03 Plan](plan.md)
- **Status:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED)
- **Prerequisites:** RF-02 Core Football & R15 Foundation approved and functional.

---

## Task Breakdown

### Phase A: Architecture & 3 Slots Setup

- [ ] **Task 3.1: Skill Slots & Loadout Management Module**
  - สร้างโครงสร้างข้อมูลสำหรับ Skill Loadout (3 Slots: Slot 1, Slot 2, Slot 3)
  - เชื่อมโยง Keybinds (เช่น 1, 2, 3 หรือ Q, E, C ตามการตั้งค่า)
- [ ] **Task 3.2: BalanceConfig Integration for Skills**
  - กำหนดตารางค่าใช้จ่าย Stamina, ระยะส่งผล, และ Recovery Time ของแต่ละท่าใน `BalanceConfig.luau` (ไม่มี per-move cooldowns ตามคำสั่ง Owner U2)

---

### Phase B: Launch Skill Moves (Player Avatar R15 Animation & Ball Sync)

- [ ] **Task 3.3: Heavy Knock-On (1★)**
  - สร้างแอนิเมชัน Player Avatar R15: จังหวะแตะบอลยาวด้วยข้างเท้าด้านนอกแล้วก้าวยาวเร่งสปีด พร้อมตรวจสอบ Contact Frame Sync บนอวาตารที่หลากหลาย
  - เชื่อม Ball Impulse ให้บอลพุ่งไปข้างหน้าตรงกับ Contact Frame
  - ทดสอบการกด Dash ควบคู่และจังหวะกวดบอล
- [ ] **Task 3.4: Open Up Fake Shot (1★)**
  - สร้างแอนิเมชัน Player Avatar R15: จังหวะหลอกง้างเท้ายิง แล้วเบรกดึงบอลตัดออกด้านข้าง
  - จัดการ Ball Impulse เปลี่ยนทิศทางบอลฉับพลัน
- [ ] **Task 3.5: Body Feint (2★)**
  - สร้างแอนิเมชัน Player Avatar R15: ทิ้งน้ำหนักหลอกไปทางหนึ่งแล้วแตะบอลออกอีกทาง
  - ซิงค์การขยับของสะโพกและเท้า R15 กับวิถีการกลิ้งของบอล

---

### Phase C: Defense & Counterplay

- [ ] **Task 3.6: Counterplay & Mid-skill Interception Verification**
  - ทดสอบการใช้ Slide และ Quick Poke จาก RF-02 เข้าสกัดผู้เล่นที่กำลังทำท่า 3 ท่า
  - ตรวจสอบว่าลูกบอลมี Hitbox ตลอดเวลา ไม่มีช่วงอมตะ (No I-frame)
- [ ] **Task 3.7: Body Check Mechanics Specification (PENDING Owner Decision)**
  - บันทึก Semantics ของ Forward Body Check (พุ่งปะทะทางด้านหน้า, Physical Strength check, ผลลัพธ์เป็น Loose Ball, No Auto-Possession, No I-frame, Recovery Delay)
  - กำหนด Target Key Mapping ตามมติ Owner Q6: **RMB** (เกมรุก: Direct Curve / เกมรับ: Body Check; คู่กับ LMB: Shoot/Slide, E: Pass/Poke; MMB ปลดระวาง; ไม่อนุญาตปุ่ม F) ไว้ในสเปก
  - ระบุสถานะ Launch Inclusion vs Deferral เป็น **PENDING Owner Decision** (Implementer ไม่มีสิทธิ์อนุญาตข้อยกเว้นขอบเขตหรือสั่ง Defer เองโดยไม่ได้รับอนุมัติ)

---

### Phase D: Catalog Preservation & Visual Gate

- [ ] **Task 3.8: Catalog Skills Documentation & Asset Archiving**
  - จัดเก็บข้อมูล 4 ท่าที่เหลือ (Heel Chop, Sombrero Flick, Lane Change, Elastico) ใน Catalog Spec เป็นรายการที่จะพัฒนาใน Phase 2
- [ ] **Task 3.9: Owner Per-Skill Visual Sign-off Gate**
  - จัดรอบทดสอบ Studio ให้ Owner ตรวจสอบท่วงท่าทั้ง 3 ท่าแบบแยกรายท่า
