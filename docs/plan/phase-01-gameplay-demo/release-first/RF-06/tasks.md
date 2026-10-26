> **2026-10-26 ROUTING:** This checklist below is historical and superseded where conflicting. Current feature tasks/state are ONLY in [single live RF02 board](../RF-02/tasks.md), with scope in [Master](../plan.md). No execution/approval inferred from old checkboxes.

# RF-06: Match, HUD & Economy — Tasks

- **Plan:** [RF-06 Plan](plan.md)
- **Status:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED)
- **Prerequisites:** RF-02, RF-03, RF-04, RF-05.

---

## Task Breakdown

### Phase A: Match State Machine

- [ ] **Task 6.1: Server-side Casual 2v2 State Machine**
  - สร้าง `MatchService` จัดการ State: `WaitingForPlayers`, `Countdown`, `Playing`, `GoalScored`, `MatchEnd`
  - รองรับโหมด 2 ผู้เล่นสำหรับการทดสอบย่อย
- [ ] **Task 6.2: Ball & Player Reset upon Kickoff**
  - พัฒนาระบบ Reset ตำแหน่งผู้เล่นและลูกบอลกึ่งกลางสนามเมื่อเริ่มเกมหรือหลังทำประตู

---

### Phase B: Concise HUD

- [ ] **Task 6.3: In-game HUD Development**
  - สร้าง Stamina Bar แสดงการใช้และฟื้นฟูแรง
  - สร้าง 3 Skill Slots Widget แสดงไอคอนและวงกลมคูลดาวน์
  - สร้าง Scoreboard และ Match Timer บริเวณด้านบนของจอ
- [ ] **Task 6.4: Request-Ball Marker UI**
  - เชื่อมโยงสัญญาณกดขอบอลให้แสดง Marker เหนือหัวตัวละครแบบ 3D BillboardGui

---

### Phase C: Match Rewards & 1 Cosmetic Shop

- [ ] **Task 6.5: Server Match Reward Commit**
  - ฟังก์ชันคำนวณและมอบเงินรางวัล Cash เมื่อสถานะเปลี่ยนเป็น `MatchEnd`
  - ตรวจสอบ Idempotency ป้องกันการจ่ายรางวัลซ้ำซ้อน
- [ ] **Task 6.6: Basic Cosmetic Shop (1 Item)**
  - ออกแบบ UI ร้านค้าง่าย ๆ แสดงไอเทม Cosmetic 1 รายการ (เช่น Alpha Neon Ball Skin)
  - ฟังก์ชันซื้อและบันทึกการครอบครองใน `PlayerProfile`

---

### Phase D: Multi-player Simulation & Acceptance

- [ ] **Task 6.7: 4-Player Match Simulation**
  - รันการทดสอบแมตช์ 2v2 ครบ 4 ผู้เล่นจริง ตรวจสอบการนับแต้มและมอบรางวัล
