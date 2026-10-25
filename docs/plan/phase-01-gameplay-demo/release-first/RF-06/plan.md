# RF-06: Match, HUD & Economy — Plan

- **Plan State:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED; awaiting Owner approval)
- **Track:** Phase 1 Release-First
- **Predecessor:** RF-02, RF-03, RF-04, RF-05.
- **Authority:** Owner Directive 2026-10-25 ([owner-r15-restart.md](../assets/owner-r15-restart.md)), Primary [HANDOFF.md](../assets/HANDOFF.md), and [Release-First Track Plan](../plan.md).

---

## 1. Context & Motivation

หัวใจสำคัญของการเปิด Public Alpha คือการที่ผู้เล่นสามารถเล่นแมตช์ได้จริงครบวงจร แผน **RF-06** นี้รวบรวมระบบการแข่งขันแบบ **Casual 2v2**, หน้าต่างแสดงผลเกมเพลย์แบบกระชับ (**Concise HUD**), ร้านค้าพื้นฐานสำหรับซื้อไอเทมตกแต่ง 1 รายการ (**1 Cosmetic Shop**), และการมอบรางวัล Cash หลังจบแมตช์ด้วยธุรกรรมฝั่งเซิร์ฟเวอร์ที่ปลอดภัย

---

## 2. AS-IS / TARGET / DELTA

### AS-IS
- โครงสร้างแมตช์เต็ม (5 นาที, ต่อเวลา, Tiebreak) และร้านค้าเดิมถูกจัดไว้ใน Phase 2 (`00-match-flow`, `01-match-tiebreak`, `07-meta-ui`) ขณะที่ UI เกมเพลย์เดิมอยู่ใน Phase 1 (`08-gameplay-ui`)
- ยังไม่มีวงจรการแข่งขันที่สมบูรณ์เชื่อมโยงกับ Server DataStore

### TARGET
- **Casual 2v2 Match Cycle:**
  - รองรับผู้เล่น 4 คน (2 คนต่อทีม: Home Team vs Away Team)
  - วงจรแมตช์: Match Queue/Ready → Kickoff Reset → Match Timer (3 นาที หรือจูนได้ใน Config) → Goal Detection & Score Update → Celebration & Kickoff Reset → Match End & Results
  - **Incomplete Team Handling:** รองรับการทดสอบด้วย 2 เครื่อง (1v1 Test Mode) ชั่วคราวระหว่างการพัฒนา แต่การตรวจรับขั้นสุดท้ายต้องใช้ 4 ผู้เล่นจริง
  - **No Ranked / No Mandatory GK AI:** รอบ Alpha ไม่มีระบบจัดอันดับ และไม่มีโกล AI บังคับ ประตูเป็นเป้าหมายเปิดโล่งตามสไตล์สตรีทกรง
- **Concise HUD:**
  - ออกแบบ UI ที่สะอาด ไม่รกหน้าจอ แสดงเฉพาะข้อมูลจำเป็น:
    1. หลอดค่าความเหนื่อย (Stamina Gauge)
    2. ไอคอนสกิล 3 ช่อง แสดงสถานะความพร้อม/Recovery
    3. ป้ายคะแนน (Scoreboard) และนาฬิกาการแข่งขัน (Timer)
    4. สัญลักษณ์แจ้งเตือนขอบอล (Request-Ball Indicator) บนหัวเพื่อนร่วมทีม
    5. เครื่องหมายระบุสังกัดทีม (Team Readability Indicator) เหนือศีรษะหรือ Virtual Jersey/Vest Overlay เพื่อให้สามารถระบุฝ่ายในแมตช์ 2v2 ได้ชัดเจนเมื่อผู้เล่นใช้ Player Avatar R15 ของตนเอง
    6. เส้นวิถีโค้งและจุดตกของลูกบอลลอยฟ้า (Live Trajectory & Landing Marker) แสดงผลบนโลก 3D ให้ผู้เล่นทุกคนเห็นแบบเรียลไทม์ รวมถึงการชิ่งสะท้อนผนัง/เพดาน Stadium A
    7. เส้นจำลองการเล็งยิงล่วงหน้า (Prerelease Aim Preview) แสดงผลเฉพาะบนหน้าจอของผู้เล่นที่กำลังชาร์จ/ง้างยิง (Shooter-only preview สำหรับการยิงทั่วไป ทั้งบนพื้นและกลางอากาศ)
- **Economy & 1 Cosmetic Shop:**
  - ได้รับ Cash หลังจบการแข่งขัน (คำนวณฝั่ง Server มอบรางวัลครั้งเดียว ป้องกันการเรียกซ้ำ)
  - ร้านค้า Shop มีไอเทมตกแต่ง (Cosmetic) จำนวน 1 รายการ (เช่น Ball Skin หรือ Jersey Pattern) ที่สามารถซื้อได้ด้วย Cash
  - บันทึกการครอบครองไอเทมลง `PlayerProfile.ownedCosmetics`

### DELTA
1. สร้าง State Machine ควบคุมวงจรแมตช์บนเซิร์ฟเวอร์ (`MatchService`)
2. พัฒนา Concise ScreenGui HUD บน Client
3. สร้างระบบมอบรางวัล Cash และร้านค้า Cosmetic 1 ชิ้น
4. เชื่อมโยงธุรกรรมเข้ากับ `PlayerProfile` DataStore
5. พัฒนาระบบเรนเดอร์เส้นวิถีโค้ง 3D (Trajectory Line) และ Landing Marker ของบอลลอยฟ้าสำหรับทุกคน พร้อม Prerelease Aim Preview สำหรับคนง้างยิง

---

## 3. Acceptance Criteria

1. **Complete Match Flow:**
   - ผู้เล่น 4 คนสามารถเข้าสู่สนาม เริ่มแข่งเมื่อครบเวลา เขี่ยบอล ยิงประตู นับคะแนน และจบการแข่งขันได้อย่างสมบูรณ์
2. **HUD Responsiveness:**
   - หลอด Stamina และไอคอนสกิล 3 ช่องสะท้อนสถานะจริงอย่างลื่นไหล
3. **Transactional Integrity:**
   - รางวัล Cash มอบให้ผู้เล่นถูกต้องเพียงครั้งเดียวเมื่อแมตช์จบ บันทึกสำเร็จ ไม่สามารถส่ง Remote ปลอมเพื่อขอเงินได้
4. **Shop & Equip:**
   - ผู้เล่นสามารถใช้ Cash ซื้อ Cosmetic 1 รายการ สวมใส่ และแสดงผลจริงในสนาม
5. **Session Stability:**
   - หากผู้เล่นหลุดระหว่างแมตช์ การแข่งขันยังดำเนินต่อได้โดยไม่ทำให้เซิร์ฟเวอร์ล่ม
6. **Team Readability:**
   - ผู้เล่นสามารถแยกแยะเพื่อนร่วมทีมและคู่แข่งได้อย่างชัดเจนในสนาม 2v2 แม้ผู้เล่นจะใช้ Player Avatar ส่วนตัวที่แต่งกายหลากหลาย
7. **Trajectory Guidance & Aim Preview Visibility:**
   - ผู้เล่นทุกคนในสนามเห็นเส้นวิถีโค้งและจุดตกของบอลลอยฟ้าอย่างแม่นยำ รวมถึงการชิ่งผนัง/เพดาน; ผู้เล่นที่กำลังง้างยิงเห็นเส้นเล็งล่วงหน้าชัดเจน; เส้นจะอัปเดตหรือล้างทิ้งทันทีเมื่อลูกบอลถูกสัมผัสหรือสกัด

---

## 4. Configuration & Tuning

- เวลาการแข่งขัน, จำนวนประตูตัดสิน (ถ้ามี), และจำนวนเงินรางวัล Cash ถูกควบคุมผ่าน `BalanceConfig`
