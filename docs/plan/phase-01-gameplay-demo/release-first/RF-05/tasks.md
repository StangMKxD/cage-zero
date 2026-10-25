# RF-05: Character Gacha, Stats & Traits — Tasks

- **Plan:** [RF-05 Plan](plan.md)
- **Status:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED)
- **Prerequisites:** RF-02 Core Football & R15 Foundation, RF-03 Skill Moves & Defense.

---

## Task Breakdown

### Phase A: 3 Characters & 13 Stats Definitions

- [ ] **Task 5.1: 3 Prototype Character Profiles**
  - กำหนดข้อมูลตัวละครเริ่มต้น 3 ตัว (Alpha Archetypes reference: Speedster, Playmaker, Defender)
  - กำหนดค่า Base Stats 13 ค่า (ขอบเขตตัวคูณ 0.90 – 1.15)
- [ ] **Task 5.2: Server Stats Multiplier Calculation**
  - เชื่อมโยงสถิติ 13 ค่าเข้ากับตัวแปรควบคุมการเคลื่อนที่ ยิง ส่ง และสกัดในฝั่ง Server
  - ตรวจสอบความถูกต้องของการคำนวณแบบ Dynamic (ไม่บันทึกค่าที่คำนวณแล้วลง Profile ถาวร)

---

### Phase B: Trait Framework & Active Traits

- [ ] **Task 5.3: Trait Framework (16 Catalog Support)**
  - ออกแบบ Trait Engine รองรับการตรวจจับ Event ในสนาม
- [ ] **Task 5.4: 3–4 Active Traits Implementation**
  - พัฒนาและเปิดใช้งาน Traits 3–4 ตัวแรกสำหรับการเปิดตัว
  - ทดสอบการแสดงผลและผลกระทบของ Trait ในการแข่งขันจริง

---

### Phase C: Cash Gacha & Persistence

- [ ] **Task 5.5: Server-side Gacha Transaction Engine & Durable Invariants**
  - สร้างตารางเรตการสุ่มใน `BalanceConfig`
  - พัฒนาฟังก์ชัน Server-authoritative Roll: ตรวจสอบ Cash → หัก Cash → สุ่มตัวละคร → บันทึกสำเนาลง DataStore
  - รองรับการบันทึกตัวละครแบบ **Per-Copy Ownership** (`CharacterInstance: { instanceId, characterId, acquiredAt, level }`) เก็บรักษาสำเนาครบทุกตัว
  - ระบุนโยบาย Duplicate Outcome Policy เป็น **PENDING Owner Decision** (ห้ามแปลงเป็น Cash/แต้มพัฒนาเองโดยไม่ได้รับอนุมัติ)
  - บังคับใช้ 4 Durable Economic Invariants: (1) Atomic Debit+Grant+Request Result, (2) Reconcile uncertain outcomes เมื่อ Reconnect, (3) Retry not rerolled (คืนผลเดิม), (4) Request deduplication ป้องกัน double grant
- [ ] **Task 5.6: Character Selection UI & Gacha Flow**
  - หน้า UI แสดงตัวละครที่ครอบครองและปุ่มเลือกใช้
  - หน้า UI ตู้สุ่ม Cash Gacha แสดงผลลัพธ์การสุ่มแบบกระชับ

---

### Phase D: Testing & Gate

- [ ] **Task 5.7: Negative Testing & Exploit Verification**
  - ทดสอบกรณีส่ง Remote ปลอม, การกดรัว (Spam click), เงินไม่พอ, และ DataStore timeout
- [ ] **Task 5.8: Persistence & Save/Load Verification**
  - ทดสอบ Rejoin เซิร์ฟเวอร์ ข้อมูลตัวละครและ Cash คงอยู่ถูกต้อง
