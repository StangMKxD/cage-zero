# RF-05: Character Gacha, Stats & Traits — Plan

- **Plan State:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED; awaiting Owner approval)
- **Track:** Phase 1 Release-First
- **Predecessor:** RF-02 Core Football & R15 Foundation, RF-03 Skill Moves & Defense.
- **Authority:** Owner Directive 2026-10-25 ([owner-r15-restart.md](../assets/owner-r15-restart.md)), Primary [HANDOFF.md](../assets/HANDOFF.md), and [Release-First Track Plan](../plan.md).

---

## 1. Context & Motivation

เพื่อเตรียมความพร้อมสำหรับการเปิด Public Alpha ระบบความก้าวหน้าของผู้เล่น (Progression) จึงถูกดึงบางส่วนจาก Phase 2 มาสู่ Phase 1 Release-First โดยเน้นเฉพาะระบบตัวละครต้นแบบ 3 ตัว, สถิติ 13 ค่า, คุณสมบัติติดตัว (Innate Traits) ที่เปิดใช้งานจริง 3–4 รายการ และตู้สุ่มตัวละครด้วยเงินรางวัลในเกม (**Earned Cash Gacha**) ที่มีระบบธุรกรรมฝั่งเซิร์ฟเวอร์ที่มั่นคงปลอดภัย

---

## 2. AS-IS / TARGET / DELTA

### AS-IS
- ในโปรเจกต์เดิม ระบบตัวละครและสถิติ 13 ค่าถูกวางแผนไว้ใน Phase 2 (`03-player-gacha-and-stats`) โดยมีข้อมูลสเปกใน `specs/spec-04-traits-threads-economy.md` และการตัดสินใจ N-61 แต่ยังไม่มีการลงมือเขียนโค้ด

### TARGET
- **3 Prototype Characters:**
  - สร้างตัวละครต้นแบบ 3 ตัวสำหรับการเปิดตัว Alpha
  - **ไม่มีอาชีพหรือ Archetype บังคับ:** การเลือกตัวละครขึ้นอยู่กับสไตล์ความชอบของผู้เล่น โดย Archetype เดิม 5 แบบคงไว้เป็นเพียงแนวทางอ้างอิงด้านสมดุล (Balancing Reference)
- **13 Outfield Base Stats (Decoupled from Body Dimensions):**
  - ค่าสถิติ 13 รายการตามที่กำหนดในระบบ (ขอบเขตตัวคูณ 0.90 – 1.15 หรือ ±10-15% จากค่าฐาน):
    1. Sprint Speed, 2. Acceleration, 3. Shot Power, 4. Curve Mastery, 5. Passing Vision, 6. Pass Speed, 7. Ball Control, 8. Agility, 9. Balance, 10. Slide Range, 11. Poke Reaction, 12. Physical Strength, 13. Stamina Capacity
  - ค่าสถิติคำนวณแบบ Dynamic บน Server ไม่บันทึกค่าคำนวณลง Profile ถาวร
  - **กฎเหล็กเรื่องมิติร่างกาย:** สถิติตัวละครทั้ง 13 ค่า และ Character Cards **ไม่เปลี่ยนแปลงขนาดทางกายภาพหรือมิติร่างกายของ Avatar ผู้เล่น** (ผู้เล่นทุกคนใช้ Player Avatar R15 ที่ถูก Normalize ขนาดร่างกายและ Hitbox ให้เท่ากันทั้งหมดเพื่อความยุติธรรมในเกมเพลย์; สถิติส่งผลเฉพาะตัวคูณฟิสิกส์ เช่น สปีดการวิ่ง แรงยิง และระยะสไลด์เท่านั้น)
- **Trait Framework & 3–4 Active Traits:**
  - Trait Framework รองรับแคตตาล็อกคุณสมบัติเดิม 16 รายการ
  - เปิดใช้งานจริงใน Alpha จำนวน 3–4 Traits (เช่น Stamina Recovery Buff, Wall Launch Speed Boost, Tackle Recovery Reduction)
  - Traits เป็นคุณสมบัติติดตัวละคร (Innate Traits) เท่านั้น ไม่มีระบบถอดใส่หิน Trait บนชุดแข่ง
- **Cash-Only Character Gacha & Durable Economic Invariants:**
  - การสุ่มใช้เฉพาะ **Earned Cash** ที่ได้จากการเล่นเกมเท่านั้น
  - **นโยบายความปลอดภัย:** ห้ามเชื่อมโยงเงิน Robux หรือ Starter Cash เข้ากับตู้สุ่มเด็ดขาด จนกว่าจะผ่านการตรวจรับข้อกำหนด Paid-Random Policy ของแพลตฟอร์ม
  - **Server Authoritative & Per-Copy Ownership:**
    - เซิร์ฟเวอร์เป็นผู้ตรวจสอบยอด Cash, หักเงิน, คำนวณสุ่มผลตามตารางเรตกลาง
    - บันทึกตัวละครแบบ **Per-Copy Ownership** ผ่านโครงสร้าง `CharacterInstance` (`{ instanceId: string, characterId: string, acquiredAt: number, level: number }`) ใน `ownedCharacters: { CharacterInstance }` เพื่อเก็บรักษาสำเนาตัวละครที่สุ่มได้ทุกตัว ไม่สูญหาย
  - **Duplicate Handling Policy (PENDING):**
    - นโยบายการจัดการตัวซ้ำ (Duplicate Outcome Policy) มีสถานะเป็น **PENDING Owner Decision** (เจ้าของโปรเจกต์ยังไม่ได้เลือกนโยบายแปลงเป็น Cash หรือแต้มพัฒนา; ระบบต้องเก็บรักษาสำเนาตัวละครทุกตัวไว้จนกว่าจะมีคำสั่งนโยบายที่ชัดเจน)
  - **4 Durable Economic Invariants:**
    1. *Atomic Debit + Grant:* การหัก Cash และการบันทึกมอบสิทธิ์ตัวละคร (Grant copy) รวมทั้ง Request Result ต้องเกิดขึ้นใน Logical Transaction เดียวกัน
    2. *Uncertain Outcomes Reconciled:* หากเกิดข้อผิดพลาดไม่แน่นอนระหว่างทาง (เช่น Crash หรือ Network Timeout ก่อน Client รับผล) ผลลัพธ์ต้องถูก Reconcile อย่างถูกต้องเมื่อ Reconnect
    3. *Retry Not Rerolled:* การ Retry คำขอเดิมที่ค้างหรือส่งซ้ำจาก Client ต้องไม่ทำให้เกิดการสุ่มเรตใหม่ (Roll ใหม่) แต่ต้องคืนผลลัพธ์เดิมที่ถูกตัดสินแล้ว
    4. *Request Deduplication:* การนำ Request ID เดิมมาส่งซ้ำต้องไม่ทำให้เกิดการมอบสิทธิ์ตัวละครหรือหักเงินซ้ำสองครั้ง (Strict Idempotency)

### DELTA
1. สร้าง Module ข้อมูลตัวละคร 3 ตัว พร้อม Base Stats และ Innate Traits
2. เชื่อมโยงค่าสถิติ 13 รายการเข้ากับตัวแปรทางฟิสิกส์ใน `BalanceConfig` (RF-02)
3. พัฒนาระบบตู้สุ่ม Gacha บน Server พร้อมตารางเรตกลาง
4. สร้าง UI หน้าเลือกตัวละคร (Character Selection) และหน้าตู้สุ่มแบบกระชับ

---

## 3. Acceptance Criteria

1. **Character Management & Selection:**
   - ผู้เล่นสามารถดูรายชื่อตัวละครที่มีในครอบครอง และเลือกเปลี่ยนตัวละครลงเล่นได้จริง
2. **Stats Impact Verification:**
   - ความแตกต่างของสถิติ 13 รายการระหว่างตัวละครส่งผลต่อความเร็ว การยิง และการแย่งบอลอย่างรู้สึกได้จริง
3. **Trait Activation:**
   - 3–4 Active Traits ทำงานถูกต้องตามเงื่อนไขที่กำหนด
4. **Durable Gacha Transaction & Invariants:**
   - การสุ่มตัวละครหัก Cash ฝั่ง Server บันทึกข้อมูล `CharacterInstance` ลง DataStore สำเร็จ ไม่เบิ้ล และเก็บครบทุกสำเนา ไม่สูญหายเมื่อ Rejoin
   - ปฏิบัติตาม 4 Durable Economic Invariants อย่างเคร่งครัด (Atomic Debit+Grant, Reconcile on Reconnect, Retry Not Rerolled, Deduplication)
   - Client ไม่สามารถแฮกส่งผลการสุ่มหรือส่งราคามาเองได้
5. **No Robux Gambling:**
   - ไม่มีช่องทางให้ใช้ Robux สุ่มตัวละครในรอบ Alpha

---

## 4. Rollback & Configuration

- ตารางเรตและต้นทุน Cash ในการสุ่มกำหนดไว้ใน `BalanceConfig` สามารถปิดตู้สุ่มหรือปรับค่าเรตได้โดยไม่ต้องแก้ Logic ธุรกรรม
