# RF-07: Publish Gate — Plan

- **Plan State:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED; awaiting Owner approval)
- **Track:** Phase 1 Release-First
- **Predecessor:** RF-02 through RF-06.
- **Authority:** Owner Directive 2026-10-25 ([owner-r15-restart.md](../assets/owner-r15-restart.md)), Primary [HANDOFF.md](../assets/HANDOFF.md), and [Release-First Track Plan](../plan.md).

---

## 1. Context & Motivation

แผน **RF-07** คือประตูด่านสุดท้าย (Final Gate) ก่อนการเปิดตัว **Public Alpha** โดยมุ่งเน้นการตรวจสอบความปลอดภัย ความเสถียรของระบบมัลติเพลเยอร์ ธุรกรรมทางการเงิน (ProcessReceipt) และการปฏิบัติตามมาตรฐานการเผยแพร่ของ Roblox โดยมี **Owner เป็นผู้มีสิทธิ์ตัดสินใจและกดปุ่ม Publish เพียงผู้เดียว**

---

## 2. AS-IS / TARGET / DELTA

### AS-IS
- ในโปรเจกต์เดิม แผน 09-uat เน้นเฉพาะการทดสอบ Demo การเล่นเบื้องต้น และระบบธุรกรรม Robux ยังไม่ได้ถูกผสานรวม

### TARGET
- **Definite-Outcome Robux Product (Conditional Launch Requirement):**
  - **เงื่อนไขขึ้นอยู่กับการเลือกสินค้าของ Owner (Conditional on selecting a launch product):** การทดสอบและเปิดใช้งานระบบชำระเงิน Robux Receipt ผ่าน `MarketplaceService.ProcessReceipt` จะเป็นเงื่อนไขที่ต้องตรวจรับเฉพาะเมื่อ Owner เลือกเปิดขายสินค้า Robux ในวันเปิดตัว Alpha เท่านั้น; **ไม่ใช่เงื่อนไขบังคับที่บล็อกการเปิดตัว (Not an unconditional release blocker)** หาก Owner ตัดสินใจเปิดตัว Public Alpha แบบ Free-to-Play โดยไม่มีสินค้า Robux
  - หาก Owner ตัดสินใจให้มีสินค้า Robux ในวันเปิดตัว จะรองรับสินค้าที่มีผลลัพธ์แน่นอน 1 รายการ (เช่น Alpha Founder Starter Bundle หรือชุดแข่งพิเศษ)
  - ห้ามใช้ระบบสุ่มด้วย Robux ในรอบนี้เด็ดขาด
  - หากมีการใช้งาน ระบบรับชำระเงินผ่าน `MarketplaceService.ProcessReceipt` ต้องมีคุณสมบัติ **Idempotency** อย่างสมบูรณ์: ตรวจสอบ `PurchaseId` ป้องกันการจ่ายของซ้ำ แม้เกิดเหตุการณ์ Crash หรือ Rejoin ก่อนตอบ `PurchaseGranted`
- **Multiplayer 4-Player UAT:**
  - ทดสอบการแข่งขัน 2v2 ด้วยผู้เล่นจริง 4 คนพร้อมกันใน Live Server
  - ตรวจสอบความหน่วง (Latency), การ Replicate ลูกบอล, ทัศนวิสัยบนกำแพง, และความลื่นไหลของ R15
- **Security & Stress Verification:**
  - ตรวจสอบช่องโหว่ Remote Event: การส่งค่า NaN, Inf, ค่าพิกัดติดลบ หรือค่าโกงความเร็ว
  - ทดสอบกรณี DataStore ล่ม: ระบบต้องมี Error Handling ที่นุ่มนวล ไม่ทำให้ข้อมูลผู้เล่นพัง
- **Roblox Publishing Compliance:**
  - ไอคอนเกม (Icon), ภาพหน้าปก (Thumbnail), และคำอธิบายเกม (Description) ครบถ้วน
  - การตั้งค่าความปลอดภัยและกลุ่มอายุ (Age Recommendation) ถูกต้อง
  - **Owner Publish Authority:** เจ้าของเกมเป็นผู้กด Publish สู่ Public Alpha

### DELTA
1. สร้างโมดูล `ReceiptService` รองรับ ProcessReceipt แบบ Idempotent
2. จัดทำ Test Script จำลองการส่งข้อมูลโจมตี Remote และ DataStore Outage
3. รัน Multiplayer UAT ร่วมกับ Owner
4. เตรียมแพ็กเกจเอกสารและ Assets สำหรับการขึ้น Public Alpha

---

## 3. Acceptance Criteria

1. **Idempotent Purchase Processing (Conditional Gate):**
   - ในกรณีที่ Owner เลือกวางจำหน่ายสินค้า Robux ในวันเปิดตัว: การจำลองซื้อ Robux สำเร็จ มอบของถูกต้อง และเมื่อส่งซ้ำระบบไม่มอบของเบิ้ล (หาก Owner เลือกเปิดตัวแบบไม่มีสินค้า Robux เกณฑ์นี้จะไม่เป็น Unconditional Release Blocker ต่อการเปิดตัว Alpha)
2. **Zero P0 / P1 Blocker in Multiplayer:**
   - ในการทดสอบ 4 ผู้เล่น ไม่พบอาการบอลหาย, บอลวาร์ป, ผู้เล่นทะลุกำแพง หรือเกมค้าง
3. **Exploit Resilience:**
   - การดัดแปลงแพ็กเก็ตจาก Client ถูกปฏิเสธโดยเซิร์ฟเวอร์ และมีบันทึก Security Log
4. **Platform Compliance:**
   - ผ่านเกณฑ์นโยบายของ Roblox ครบถ้วน
5. **Owner Explicit Sign-off:**
   - Owner ลงนามตรวจรับผลงานทั้งหมดและดำเนินการ Publish ด้วยตนเอง

---

## 4. Rollback Plan

- หากพบปัญหา Critical ในวันเปิดตัว เซิร์ฟเวอร์สามารถปิดรับผู้เล่นใหม่ (Private Place) ได้ทันทีผ่านการตั้งค่าของ Owner
