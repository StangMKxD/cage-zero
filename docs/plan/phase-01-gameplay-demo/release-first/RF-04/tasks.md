> **2026-10-26 ROUTING:** This checklist below is historical and superseded where conflicting. Current feature tasks/state are ONLY in [single live RF02 board](../RF-02/tasks.md), with scope in [Master](../plan.md). No execution/approval inferred from old checkboxes.

# RF-04: Cage Slingshot — Tasks

- **Plan:** [RF-04 Plan](plan.md)
- **Status:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED)
- **Prerequisites:** RF-02 Core Football & R15 Foundation, RF-03 Skill Moves & Defense.

---

## Task Breakdown

### Phase A: Wall Geometry & Detection

- [ ] **Task 4.1: Stadium A Wall & Ceiling Raycast Detection**
  - พัฒนาระบบตรวจสอบระนาบกำแพง 4 ด้านและเพดานใน Stadium A
  - คำนวณ Surface Normal และระยะห่างที่อนุญาตให้เริ่มสถานะ Wall Run
- [ ] **Task 4.2: Wall Physics Constraints & Momentum Conservation**
  - คำนวณเวกเตอร์แรงส่งและการชิ่งของบอลที่กระทบกำแพงตามค่าเดิมของ Plan 01

---

### Phase B: Wall Run & Wall Launch Mechanics

- [ ] **Task 4.3: R15 Wall Run Animation & Controller**
  - สร้างแอนิเมชัน R15 สำหรับการวิ่งไต่กำแพงด้านซ้ายและด้านขวา
  - ควบคุมการใช้ Stamina ระหว่าง Wall Run และการหลุดจากผนังเมื่อหมดแรง
- [ ] **Task 4.4: Wall Launch (Slingshot) System**
  - พัฒนาการดีดตัวออกจากผนัง: Windup (0.20s) → High Velocity Impulse (1.7x Sprint) → Airborne State → Landing Recovery (0.20s)
  - เชื่อมโยงค่าพารามิเตอร์ทั้งหมดใน `BalanceConfig.luau`

---

### Phase C: Aerial Interaction & Counterplay

- [ ] **Task 4.5: Aerial Volley & Pass from Wall**
  - รองรับการแตะบอลหรือยิงลูกวอลเลย์ขณะอยู่ในสถานะ Wall Launch
  - เชื่อมโยง Hitbox กายภาพ ไม่ให้ลูกบอลถูกดูดเข้าหาเท้า
- [ ] **Task 4.6: Aerial Intercept & Counter-Defense**
  - ทดสอบให้ผู้เล่นฝ่ายรับกระโดดบล็อกลูกยิงหรือตัดบอลจากผู้เล่นที่ทำ Wall Launch
  - ยืนยันว่าไม่มีสถานะอมตะ (No I-frame)

---

### Phase D: Multi-client Testing & Visual Gate

- [ ] **Task 4.7: Multi-client Synchronization & Latency Compensation**
  - ตรวจสอบตำแหน่งผู้เล่นบนกำแพงระหว่าง Client 2 เครื่อง ให้ Replicate ตรงกัน
- [ ] **Task 4.8: Owner Visual Acceptance Gate**
  - จัดรอบสาธิต Live Play ให้ Owner ตรวจรับมูฟเมนต์ Cage Slingshot
