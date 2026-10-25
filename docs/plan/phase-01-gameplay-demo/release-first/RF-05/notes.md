# RF-05: Character Gacha, Stats & Traits — Notes

- **Date:** 2026-10-25
- **Status:** Planning / Documentation Synchronized
- **Related Docs:**
  - [Release-First Track Plan](../plan.md)
  - [Spec 04 — Economy & Traits](../../../../specs/spec-04-traits-threads-economy.md)
  - [Decision N-61](../../01-cage-physics/notes.md#n-61--accepted-decision-13-outfield-base-stats-4-deferred-gk-stats-16-innate-traits-5-character-archetypes-and-body-check-target-mechanics-2026-10-24)

---

## 1. Compliance & Monetization Safety

- ในรอบ Public Alpha ระบบตู้สุ่มจะจำกัดเฉพาะ **Earned Cash** ที่ผู้เล่นได้รับจากการจบแมตช์เท่านั้น
- เพื่อให้สอดคล้องกับนโยบายของ Roblox ว่าด้วย Paid Random Items จะไม่มีการเปิดขาย Cash ด้วย Robux เพื่อนำมาสุ่ม จนกว่าจะมีการตรวจสอบเรื่องอายุผู้เล่น, การเปิดเผยเรต (Odds Disclosure), และกลไกทางกฎหมายที่ครบถ้วน

---

## 2. Character Archetype Philosophy

- Archetype 5 รูปแบบที่มีการออกแบบไว้เดิม (Speedster, Playmaker, Target Man, Anchor, Enforcer) จะถูกใช้เป็นเพียงแนวทางอ้างอิงในการกระจายค่าพลัง (Balancing Reference)
- ผู้เล่นไม่ถูกจำกัดด้วยคลาสหรืออาชีพตายตัว สามารถปรับแต่งสไตล์การเล่นผ่านการเลือกตัวละคร, สกิล 3 ช่อง และการเคลื่อนไหวในสนาม

---

## 3. Per-Copy Ownership & Durable Economic Invariants (RF-F05 Compliance)

- **Per-Copy Ownership Model:**
  - ตัวละครในครอบครองถูกจัดเก็บในโครงสร้าง `CharacterInstance`: `{ instanceId: string, characterId: string, acquiredAt: number, level: number }` ภายใต้ `ownedCharacters: { CharacterInstance }`
  - สุ่มได้ตัวซ้ำจะได้รับ Instance ID ใหม่และจัดเก็บสำเนาไว้ทั้งหมด ไม่มีการสูญหายของสำเนาตัวละคร
- **Duplicate Outcome Policy: PENDING:**
  - เจ้าของโปรเจกต์ยังไม่ได้เลือกนโยบายแปลงเป็น Cash หรือแต้มพัฒนา (Duplicate Conversion is unselected by Owner)
  - ห้าม Implementer ตัดสินใจแปลงเป็น Cash ชดเชยหรือแปลงแต้มเองจนกว่าจะมีคำสั่งอนุมัตินโยบายจาก Owner
- **4 Durable Economic Invariants:**
  1. *Atomic Debit + Grant:* การหักเงินและการมอบสิทธิ์ตัวละครพร้อม Request Result ต้องเกิดขึ้นใน Logical Transaction เดียวกัน
  2. *Uncertain Outcomes Reconciled:* ข้อผิดพลาดที่ไม่แน่นอนระหว่างบันทึก DataStore ต้อง Reconcile คืนสถานะถูกต้องเมื่อ Reconnect
  3. *Retry Not Rerolled:* การ Retry คำขอเดิมต้องคืนผลลัพธ์เดิมที่ตัดสินแล้วเสมอ ไม่มีการสุ่มเรตซ้ำ
  4. *Request Deduplication:* ห้ามให้คำขอ Request ID เดิมทำให้เกิดการหักเงินหรือให้สิทธิ์ตัวละครซ้ำสอง (Strict Idempotency)
