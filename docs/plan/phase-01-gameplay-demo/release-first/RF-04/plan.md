# RF-04: Cage Slingshot — Plan

- **Plan State:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED; awaiting Owner approval)
- **Track:** Phase 1 Release-First
- **Predecessor:** RF-03 R15 Skill Moves & Defense.
- **Authority:** Owner Directive 2026-10-25 ([owner-r15-restart.md](../assets/owner-r15-restart.md)), Primary [HANDOFF.md](../assets/HANDOFF.md), and [Release-First Track Plan](../plan.md).
- **Core Identity:** **CAGE SLINGSHOT — Turn the Walls Into Your Weapon.**

---

## 1. Context & Motivation

หัวใจสำคัญที่เป็นจุดขายเดี่ยวของ Cage Zero คือระบบ **Cage Slingshot** ในสนามกรงสี่เหลี่ยม Stadium A (4 ผนังเรียบ + เพดาน) ผู้เล่นสามารถวิ่งไต่กำแพง (**Wall Run**) และดีดตัวพุ่งออกจากกำแพงด้วยความเร็วสูง (**Wall Launch**) เพื่อช่วงชิงตำแหน่ง บล็อกลูกกลางอากาศ หรือกระโดดยิงวอลเลย์ ขณะที่ลูกบอลสามารถชิ่งกำแพงและเพดานด้วยฟิสิกส์จริง

---

## 2. AS-IS / TARGET / DELTA

### AS-IS
- สนาม Stadium A ใน Plan 01 มีโครงสร้าง 4 ผนังและเพดานพร้อมระบบฟิสิกส์การชิ่งบอล (`CagePhysicsService`) แต่ยังไม่มีระบบปฏิสัมพันธ์ของตัวละครกับกำแพง (ไม่มี Wall Run หรือ Wall Launch)

### TARGET
- **Stadium A Physical Rebound:** คงขนาดสนามและคุณสมบัติการเด้งของลูกบอลตามค่าเดิมของ Plan 01 บอลชิ่งผนังและเพดานด้วยโมเมนตัมจริง
- **Full Wall Run:** เมื่อผู้เล่นเคลื่อนที่เข้าชิดกำแพงในมุมที่เหมาะสมและกดปุ่มวิ่ง จะสามารถวิ่งไต่ตามแนวระนาบของกำแพงได้ต่อเนื่องโดยใช้ Stamina
- **Wall Launch:** ผู้เล่นสามารถดีดตัวออกจากผนังพุ่งเข้าสู่พื้นที่กลางอากาศด้วยความเร็วสูง
  - *Initial Tunable Proposals:*
    - `launchSpeedMultiplier`: 1.7x เทียบกับ Sprint
    - `maxDistanceStuds`: 28 studs
    - `windupSec`: 0.20 วินาที
    - `landingRecoverySec`: 0.20 วินาที
    - `staminaCost`: 25 stamina
  *(ค่าทั้งหมดเป็นตัวแปรใน `BalanceConfig` สามารถปรับจูนได้ ไม่ใช่ข้อสรุปว่าสมดุลแล้ว)*
- **Aerial Pass & Volley from Wall:** ผู้เล่นสามารถส่งบอลให้ชิ่งกำแพงลอยมารับเอง หรือดีดตัวออกจากกำแพงเพื่อยิงวอลเลย์กลางอากาศ
- **Wall Launch Aerial Reception & Rebound Prediction (Owner Decision 2026-10-25):**
  - ผู้เล่นสามารถ Wall Launch พุ่งออกจากกำแพงเข้าชน Hitbox บอลกลางอากาศเพื่อเปิดใช้งาน **Assisted Aerial Reception** เข้าสู่สถานะ **Brief Airborne Hold** เพื่อเล็ง 3D และง้างยิงกลางอากาศได้จริง (หาก relative approach speed ไม่เกินเกณฑ์)
  - เส้นวิถีโค้งและจุดตกของบอล (Live Trajectory & Landing Guide) จะคำนวณการชิ่งสะท้อนผนังและเพดาน Stadium A ล่วงหน้าให้ทุกคนเห็น ช่วยให้ผู้เล่นกะจังหวะวิ่งไต่กำแพงและดีดตัวดักรับบอลได้แม่นยำ
- **Fair Defense & Counterplay:**
  - **No Invulnerability:** ผู้เล่นที่ Wall Launch ไม่มี I-frame
  - ฝ่ายรับสามารถอ่านวิถีการพุ่งและเข้าบล็อกหรือสกัดบอลกลางอากาศได้ด้วย Directional Jump / Header / Block จาก RF-02

### DELTA
1. สร้างโมดูลตรวจจับระนาบผนัง (Wall Detection Raycast / Surface Normal)
2. พัฒนาระบบแอนิเมชัน Player Avatar R15 สำหรับ Wall Run (ไต่กำแพงซ้าย/ขวา) และ Wall Launch (ท่าย่อดีดตัวและพุ่งกลางอากาศ) บนสัดส่วนร่างกายที่ Normalized เท่ากัน
3. ปรับแต่งการปฏิสัมพันธ์ของลูกบอลระหว่างอยู่บนกำแพง (Wall Dribble & Wall Kick)
4. จูนค่าแรงดีดและ Stamina ใน `BalanceConfig`
5. เชื่อมโยง Wall Launch เข้ากับระบบ Assisted Aerial Reception และระบบคำนวณเส้นวิถีสะท้อนผนัง/เพดาน (Wall & Ceiling Rebound Prediction)

---

## 3. Acceptance Criteria

1. **Wall Run Mechanics:**
   - ตัวละคร Player Avatar R15 (Normalized to Same Body Dimensions) สามารถเกาะและวิ่งไปตามแนวผนังทั้ง 4 ด้านของ Stadium A ได้อย่างราบรื่น
   - Stamina ลดลงอย่างต่อเนื่องระหว่าง Wall Run และหลุดจากกำแพงเมื่อ Stamina หมด
2. **Wall Launch Execution:**
   - การดีดตัวออกจากกำแพงมี Windup สั้น ๆ (0.20 วินาที) ก่อนพุ่งออกไปตามทิศทางที่เล็ง
   - เมื่อลงสู่พื้น มีช่วง Landing Recovery (0.20 วินาที) ก่อนเคลื่อนที่ปกติ
3. **Aerial Reception, Volley & Rebound Prediction:**
   - สาธิตวงจร: ส่งบอลชิ่งผนัง → เส้นวิถีสะท้อนผนัง/เพดานและจุดตกแสดงผลสมบูรณ์ → Wall Run → Wall Launch ดีดตัวพุ่งชน Hitbox บอลด้วยความเร็วที่ถูกต้อง → เข้าสู่สถานะ Brief Airborne Hold เล็งและยิง Volley กลางอากาศได้จริง
   - ฝ่ายรับสามารถกระโดดบล็อกลูกยิงหรือตัดบอลกลางอากาศได้ (ลูกบอลมี Hitbox ตลอดเวลา ไม่มี I-frame)
4. **Physical Integrity:**
   - ไม่มีการวาร์ปลูกบอล และไม่มีการล็อกมุมดูดผู้เล่นเข้าหากำแพงแบบผิดธรรมชาติ
5. **Owner Visual Acceptance:**
   - ท่วงท่าการไต่และดีดตัวออกจากผนังผ่านการตรวจรับทางสายตาจาก Owner

---

## 4. Rollback & Tuning

- ทุกค่าพารามิเตอร์ของแรงดีด ระยะทาง และเวลาฟื้นตัวถูกควบคุมผ่าน `BalanceConfig` สามารถปรับเปลี่ยนได้ทันทีโดยไม่ต้องแก้โค้ดระบบ
