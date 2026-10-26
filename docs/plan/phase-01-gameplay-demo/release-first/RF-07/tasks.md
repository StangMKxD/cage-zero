> **2026-10-26 ROUTING:** This checklist below is historical and superseded where conflicting. Current feature tasks/state are ONLY in [single live RF02 board](../RF-02/tasks.md), with scope in [Master](../plan.md). No execution/approval inferred from old checkboxes.

# RF-07: Publish Gate — Tasks

- **Plan:** [RF-07 Plan](plan.md)
- **Status:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED)
- **Prerequisites:** RF-02 through RF-06 fully verified.

---

## Task Breakdown

### Phase A: Robux & Transaction Idempotency (Conditional on Selecting Launch Product)

- [ ] **Task 7.1: ProcessReceipt Handler & Deduplication (Conditional Gate)**
  - *เงื่อนไข:* บังคับใช้และทดสอบเฉพาะเมื่อ Owner ตัดสินใจมีสินค้า Robux ในวันเปิดตัว Alpha (ไม่เป็น unconditional release blocker หากเปิดตัวแบบ 100% Free-to-play)
  - พัฒนา `ReceiptService.luau` ผูกกับ `MarketplaceService.ProcessReceipt`
  - ตรวจสอบ `processedPurchaseIds` ใน PlayerProfile ก่อนมอบสินค้า
  - รองรับกรณี Retry และ Server Reconnect
- [ ] **Task 7.2: Definite-Outcome Product Configuration**
  - ตั้งค่า Product ID สำหรับ 1 สินค้า Robux ผลลัพธ์แน่นอน (หากได้รับอนุมัติจาก Owner ให้เป็น launch requirement)

---

### Phase B: Security, Stress & Negative Testing

- [ ] **Task 7.3: Remote Exploits & Argument Validation**
  - ทดสอบส่ง Payload แปลกปลอม (NaN, Inf, Type Mismatch) เข้าทุก RemoteFunction / RemoteEvent
  - ยืนยันว่า Server ตัดทิ้งอย่างปลอดภัย
- [ ] **Task 7.4: DataStore Failure Simulation**
  - จำลองกรณี DataStore API คืนค่า Error เพื่อตรวจสอบ Fallback และการป้องกันข้อมูลผู้เล่นทับซ้อน

---

### Phase C: Multiplayer UAT & Experience Pass

- [ ] **Task 7.5: 4-Player Live Match UAT**
  - รันการแข่งขัน 2v2 ร่วมกับ Owner และทีมงาน
  - บันทึก Framerate, Network Ping, และความพึงพอใจด้าน Visual
- [ ] **Task 7.6: UI & Localization Polish**
  - ตรวจสอบฟอนต์, ขนาดตัวหนังสือ, และข้อความแนะนำปุ่มควบคุมบนจอ

---

### Phase D: Owner Final Gate & Alpha Launch

- [ ] **Task 7.7: Alpha Release Checklist Verification**
  - ตรวจสอบ Icon, Thumbnail, และ Game Settings ใน Creator Hub
- [ ] **Task 7.8: Owner Sign-off & Public Publish**
  - เจ้าของเกมตรวจสอบความพร้อมขั้นสุดท้ายและดำเนินการกด Publish สู่ Public Alpha
