# RF-07: Publish Gate — Notes

- **Date:** 2026-10-25
- **Status:** Planning / Documentation Synchronized
- **Related Docs:**
  - [Release-First Track Plan](../plan.md)
  - [Legacy Plan 09 UAT](../../09-uat/plan.md)

---

## 1. Owner Prerogative

- กฎเหล็กของโปรเจกต์ Cage Zero คือ AI/Codex/Implementer ไม่มีสิทธิ์สั่ง Publish หรือ Deploy สู่สาธารณะด้วยตนเอง
- แผน RF-07 ทำหน้าที่เตรียมความพร้อมด้านเทคนิค ความปลอดภัย และการทดสอบทั้งหมด เพื่อส่งต่อให้ Owner เป็นผู้กด Publish เมื่อเห็นว่าคุณภาพถึงเกณฑ์

---

## 2. Monetization Prerequisite Reminder (RF-F05 Compliance)

- **Conditional on Selecting Launch Product:**
  - การทดสอบ `MarketplaceService.ProcessReceipt` และการตั้งค่าสินค้า Robux เป็นเงื่อนไขที่ขึ้นอยู่กับการตัดสินใจของ Owner ว่าจะเลือกวางขายสินค้า Robux ในรอบ Alpha หรือไม่
  - หาก Owner เลือกเปิดตัว Public Alpha แบบ Free-to-play 100% โดยไม่มีสินค้า Robux ระบบ ProcessReceipt จะไม่เป็นข้อผูกมัดหรืออุปสรรคขัดขวางการเปิดตัว (Not an unconditional release blocker)
- ย้ำเตือนข้อกำหนด: หากมีการขายสินค้า Robux ในรอบ Alpha จะต้องเป็นสินค้าที่ผู้ซื้อได้รับของตรงตัวแน่นอน (Definite Outcome) เท่านั้น เช่น แพ็กเกจเริ่มต้นหรือชุดแข่งพิเศษ
- การนำ Robux ไปเชื่อมกับตู้สุ่มยังคงถูกล็อกไว้จนกว่าจะเข้าสู่การประเมินความพร้อมใน Phase 2 (ห้ามเด็ดขาดใน Alpha)
