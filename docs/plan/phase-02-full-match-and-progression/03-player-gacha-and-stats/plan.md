# 03-player-gacha-and-stats — สุ่มนักเตะ ระดับ และ Stats

- **Phase:** 2; **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น (DOCS-20261024)
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **Transaction prerequisite:** [02-transactions](../02-transactions/plan.md) ต้องพร้อมก่อนเปิดรายการ Cash/ไอเทมของแผนนี้
- **ข้อสรุปกติกา:** [accepted decisions](../../phase-01-gameplay-demo/01-cage-physics/notes.md#n-61--accepted-decision-13-outfield-base-stats-4-deferred-gk-stats-16-innate-traits-5-character-archetypes-and-body-check-target-mechanics-2026-10-24)
- **Prerequisites:** [00-match-flow](../00-match-flow/plan.md)
- **Hard gate:** ต้องจบและตรวจรับ Phase 1 ครบก่อน ห้ามเปิดงานแผนนี้ระหว่างเก็บ phase แรก

---

## 1. ขอบเขตและกฎเกณฑ์พื้นฐาน (Accepted Scope & Canonical Rules)

1. **ขอบเขต Base Stats (0.90–1.15):**
   - ค่า Base Stats มีขอบเขตสมดุลระหว่าง `0.90` ถึง `1.15` หมายถึง **−10% ถึง +15%** โดยมี `1.00` เป็นค่ามาตรฐานกลาง (ไม่ใช่ ±15%)
   - สเกลตัวคูณ $M \in [0.90, 1.15]$, ส่วนต่างโบนัส $\text{statBonus} = \Delta = M - 1 \in [-0.10, +0.15]$
   - ค่าคำนวณแบบผกผัน (เช่น ระยะบอลห่างตัวของ Dribbling, ระยะเวลา Recovery Lockout) ให้ใช้สูตรเชิงเส้น $(1 - \Delta)$ โดยตรงเท่านั้น (Linear Inverse: $BASE \times (1 - \text{statBonus})$) และห้ามนำ $1.14$ ไปใส่ใน $(1 + \Delta)$ จนกลายเป็น $+114\%$
2. **การทำงานร่วมกับ Trait (Trait Composition):**
   - เพดาน `0.90–1.15` บังคับใช้เฉพาะ **Base Stats** เท่านั้น
   - บัฟจาก Conditional Trait สามารถทำให้ค่า Effective Stat ทะลุเกินเพดาน `1.15` ได้ตามเงื่อนไข ห้ามตัดกลับมาที่ 1.15 หรือสร้างเพดานรวมซ้อนโดยพลการ
3. **Trivela Master (ไม่ปิดกั้น Trivela พื้นฐาน):**
   - ผู้เล่นทุกคนสามารถใช้ท่า Trivela ปกติได้โดยไม่ต้องปลดล็อก Trait
   - Trait `Trivela Master` เพิ่มความเร็วต้น `+10%` และกลับทิศสปิน (`spinVector = -spinVector`) เพียง **ครั้งเดียว** เทียบกับแกนลูกปั่นโค้งปกติ ห้ามกลับทิศสปินซ้ำสองจนกลายเป็นลูกปั่นธรรมดา
4. **ความจุ Trait ประจำตัว (Innate Trait Cardinality):**
   - Trait เป็นคุณสมบัติติดตัวละคร (**Innate Traits**) เท่านั้น จำนวนไม่คงที่ที่ 2 รายการ ตัวละครอาจมี Trait ได้ตั้งแต่ 0, 1, 2, ... รายการ
   - คู่ Trait ในตาราง 5 Archetypes เป็นเพียง **ตัวอย่างความเหมาะสม (Illustrative Examples)** ไม่ใช่สล็อตบังคับ 2 ช่องตายตัว
5. **ยกเลิก Trait บนชุดและหิน Trait (No Gear Traits / No Trait Stones in Target):**
   - ถอดระบบช่องใส่ Trait บนชุด Battle Threads, หิน Trait Stone, และการเทรดหิน Trait ออกจาก Target Design ทั้งหมด
   - ชุด Battle Threads และ Mutations คงขอบเขตเพื่อความสวยงามและโบนัสฟาร์ม (VFX, ตัวคูณ Cash/EXP หลังจบแมตช์) โดยไม่มีสเตตัสและไม่มีหิน Trait
6. **การรอการตัดสินใจด้านเศรษฐกิจและกาชา (Gacha Policies Remain Pending):**
   - อัตราการสุ่ม (Rates), ระบบการันตี (Pity), ราคา (Prices), การจัดการของซ้ำ (Duplicates), นโยบายการรีโรล (Rerolls), และการซื้อขาย ยังไม่ถูกกำหนดในรอบนี้และรอการ Grill เมื่อเปิดแผน Phase 2

---

## 2. ตาราง Outfield Base Stats (13 ค่า)

| ลำดับ | ชื่อ Stat (รหัส) | ความหมายและผลลัพธ์ในเกมเพลย์ | สูตร Luau และตรรกะทางเทคนิค | แผนที่รับผิดชอบ |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Speed** (`#1`) | ความเร็ววิ่งสูงสุดตอนเดินและ Sprint ทั้งมีบอลและไม่มีบอล | `Humanoid.WalkSpeed = BASE_SPEED * (1 + statBonus) * stateMultiplier` | Phase 1: 02, 06<br>Phase 2: 03 |
| **2** | **Jump** (`#2`) | ความสูงในการกระโดด Directional Jump สำหรับโหม่ง/วอลเลย์/บล็อก | `AssemblyLinearVelocity.Y = BASE_JUMP_IMPULSE * (1 + statBonus)` หรือ `JumpPower` | Phase 1: 02, 06<br>Phase 2: 03 |
| **3** | **Shot Power** (`#3`) | ความเร็วลูกยิงตรงและความแรงสะท้อนชิ่งกำแพง/เพดาน | `ballVelocity = aimDir * (BASE_SHOT_SPEED * chargeRatio * (1 + statBonus))` | Phase 1: 01, 02, 06<br>Phase 2: 03 |
| **4** | **Curve** (`#4`) | องศาการเลี้ยวโค้งของปุ่ม Direct Curve Shot และลูกนิ่ง FC27 | `magnusForce = spinVec:Cross(ballVel) * (BASE_CURVE * (1 + statBonus))` | Phase 1: 02, 05, 06<br>Phase 2: 03 |
| **5** | **Sliding** (`#5`) | ความเร็วและระยะทางของการพุ่ง Slide Tackle | `slideVel = hrp.CFrame.LookVector * (BASE_SLIDE_SPEED * (1 + statBonus))` | Phase 1: 03, 05, 06<br>Phase 2: 03 |
| **6** | **Strength** (`#6`) | ส่งผลต่อการปะทะ Body Check และการทนแรงปะทะ (การเปรียบเทียบค่า Strength ระหว่างผู้เล่นส่งผลต่อระยะเวลาชะงัก/Knockback recovery และการหลุดเป็น Loose Ball โดยสูตรคำนวณ/ต้านทานโดยละเอียดยัง PENDING รอการจูน) | การเปรียบเทียบค่า Strength ส่งผลต่อ Contact Response / Loose Ball (สูตรคำนวณละเอียด PENDING) | Phase 1: 02, 03, 06<br>Phase 2: 03 |
| **7** | **Dribbling** (`#7`) | ลดระยะห่างบอลขณะเลี้ยง (เลี้ยงติดเท้ามากขึ้น: `dribbleOffsetZ = BASE_OFFSET * (1 - statBonus)`) และช่วยรักษาระยะบอลใกล้ตัวแม้ Stamina ต่ำ | `dribbleOffsetZ = BASE_OFFSET * (1 - statBonus)` | Phase 1: 02, 03, 06<br>Phase 2: 03 |
| **8** | **Stamina** (`#9`) | ความจุหลอด Stamina สูงสุดสำหรับ Sprint, Dash, Skill Moves, ท่าสกัด | `maxStamina = 100 * (1 + statBonus)` | Phase 1: 02, 03, 06<br>Phase 2: 03 |
| **9** | **Pass Velocity** (`#16`) | ความเร็วลูกส่งเรียด/โด่ง ช่วยให้เคาะชิ่งกำแพง (Wall One-Two) เร็วขึ้น | `passSpeed = BASE_PASS_SPEED * chargeRatio * (1 + statBonus)` | Phase 1: 02, 06<br>Phase 2: 03 |
| **10** | **Acceleration / Dash** (`#27`) | อัตราเร่งความเร็วจากจุดหยุดนิ่ง และระยะ/ความเร็วพุ่งของปุ่ม Dash | `accelRate = ACCEL_RATE * (1 + statBonus)`<br>`dashImpulse = BASE_DASH * (1 + statBonus)` | Phase 1: 02, 06<br>Phase 2: 03 |
| **11** | **Poke Reach** (`#30`) | ระยะยื่นเท้าจิ้มสกัดของปุ่ม Quick Poke | `pokeBoxSizeZ = BASE_POKE_REACH * (1 + statBonus)` ใน `GetPartBoundsInBox` | Phase 1: 03, 06<br>Phase 2: 03 |
| **12** | **Recovery / Reflex** (`#32`) | ลดเวลาชะงัก (Recovery Lockout) หลังใช้สกิลพลาด สไลด์วืด ชนวืด หรือลงพื้น | `recoveryDuration = BASE_RECOVERY * (1 - statBonus)` | Phase 1: 02, 03, 06<br>Phase 2: 03 |
| **13** | **Block** (`ใหม่`) | รัศมี Hitbox กระโดดบล็อก/ยืนขวาง และลดความเร็วสะท้อนให้ตกใกล้ตัว | `blockHitboxRadius = BASE_BLOCK_RADIUS * (1 + statBonus)`<br>`reboundSpeed *= (1 - statBonus * 0.5)` | Phase 1: 02, 03, 06<br>Phase 2: 03 |

---

## 3. Goalkeeper Deferred Stats (4 ค่า — รอเปิดหลัง Phase 1 / 04)

- **`#23 Dive Reach`:** เพิ่มระยะและความเร็วพุ่งเซฟซ้าย/ขวาในเขตโทษ
- **`#24 Handling`:** เพิ่มเพดานความเร็วลูกยิงที่โกลสามารถรับติดมือ (Catch) แทนการปัดกระฉอก
- **`#25 Reflex / Dive Recovery`:** ลดเวลาลุกขึ้นยืนหลังพุ่งเซฟเพื่อรับมือลูกชิ่งซ้ำ
- **`#26 Box Distribution`:** เพิ่มความเร็วและระยะการขว้างบอลหรือเปิดเกมจากเขตโทษ

---

## 4. รายละเอียด Character Traits (16 รายการ)

### 4.1 หมวดยิงพิเศษและชิ่งกำแพง (4 Traits)
1. **Whipped Finesse (ปั่นโค้งแรง):** Direct Curve Shot เสียความเร็วต้นน้อยลง (ปรับตัวคูณจาก `0.80` เป็น `0.95`) และลูกมุดลงท้ายวิถี
2. **Trivela Master (ไซด์ก้อยแรง):** ทุกคนใช้ Trivela ได้; ผู้มี Trait นี้ได้ความเร็วต้น `+10%` พร้อมกลับทิศสปิน (`spinVector = -spinVector`) ครั้งเดียวเทียบกับลูกปั่นปกติ
3. **Knuckle Emperor (ยิงบอลส่าย):** ชาร์จยิงตรงในโซน Sweet Spot (`85%–95%`) บอลจะไร้สปิน ส่ายไปมาตาม `math.sin(elapsed * 18)` และมุดลงกลางอากาศ
4. **Wall-Breaker (ยิงอัดกำแพงพุ่งแรง):** ลูกยิง/ส่งที่ชิ่งกำแพงกรงครั้งแรกได้รับโบนัส restitution `+0.15` (เพดานไม่เกิน `1.15`)

### 4.2 หมวดเทคนิค การเคลื่อนที่ และการตั้งหลัก (7 Traits — Legacy #11 ตัดออก)
5. **Second Wind (`#10` \- ฟื้นพลังงานไว):** เมื่อไม่กด Sprint และไม่ติด Recovery อัตราฟื้นฟู Stamina เพิ่มขึ้น `+25%`
6. **Velvet Touch (`#13` \- ดูดบอลแรงติดเท้า):** ขยายเพดานความเร็วบอลที่รับเข้าครองได้ทันที (`maxTrapSpeed * 1.25`) บอลไม่กระฉอก
7. **One-Touch Specialist (`#14` \- จอมซัดจังหวะแรก):** ยิง/ส่งจังหวะแรก (First-Time) แม่นยำสมบูรณ์ (เบี่ยงเบนเพิ่มเติมเป็น 0) และใน Phase 2 ลดเวลาเสียหลักเมื่อเตะวืดลง `30%`
8. **Acrobat / Sky Striker (`#15` \- จ้าวเวหาโหม่ง/วอลเลย์):** ขณะกระโดดลอยตัว (`Freefall`) ลูกโหม่งและวอลเลย์แรงขึ้น `+12%` พร้อมมุมกดลงหน้ากรอบ
9. **Quick Footwork (`#17` \- จบสกิลไว):** ลดเวลาหน่วงช่วงจบท่าร่วม (`commonEndLag`) และเวลาเสียจังหวะเมื่อใช้สกิล 1–5 ดาวพลาดลง `20%` (ไม่ลด Cooldown ท่า)
10. **Lightning Poke (`#18` \- จิ้มฉกบอลไว):** ลดเวลาออกท่า (`pokeStartupTime`) และเวลาชะงักหลังจิ้มของ Quick Poke ลง `20%`
11. **Elastic Recovery (`#19` \- ลุกไวหลังสไลด์/พุ่งชนพลาด):** ลดเวลาล็อกตัวหลังกด Slide Tackle หรือ Body Check วืดลง `25%`

### 4.3 หมวดกองหลังและเกมรับ (5 Traits — D1, D2, D3, D5, D7)
12. **Iron Wall Block (`D1` \- บล็อกเหล็กดูดซับแรง):** เมื่อกระโดดบล็อกหรือยืนขวางลูกยิง บอลที่เด้งชนตัวลดความเร็วลงเหลือ `25%` (`incomingSpeed * 0.25`) ตกลงพื้นใกล้ตัวในรัศมี `4–6 Studs`
13. **Bulldozer Impact (`D2` \- พุ่งชนสะเทือน):** พุ่งชน (Body Check) โดนผู้ถือบอล บอลที่หลุดจะกระเด็นไปตามทิศที่ผู้ชนหันหน้า (`defenderHRP.CFrame.LookVector * POP_SPEED`) และคู่แข่งชะงักนานขึ้น `+0.15s`
14. **Clean Sweeper (`D3` \- สไลด์กวาดใสสะอาด):** ขยาย Hitbox เกี่ยวลูกบอลด้านหน้าตอนกด Slide Tackle ยื่นนำหน้าตัวคน `+0.8 Studs` ช่วยให้โดนบอลก่อนโดนคน
15. **Shadow Chaser (`D5` \- กัดไม่ปล่อย):** วิ่งไล่กวดด้านหลังผู้ถือบอลคู่แข่งในระยะ `<= 25 Studs` ได้โบนัสความเร็ววิ่ง `+7%` (`WalkSpeed * 1.07`)
16. **Cage Guardian (`D7` \- ปราการหน้ากรอบ):** เมื่ออยู่ในโซน 1/3 หน้าประตูฝั่งตัวเอง (Defensive Third) ใช้ Stamina สำหรับ Dash, Slide และ Body Check น้อยลง `25%` (`staminaCost * 0.75`)

---

## 5. ตาราง 5 Character Archetypes (65 ค่าสเตตัสสมบูรณ์)

| Archetype (สายตัวละคร) | สเกล R6 (00) | เพดานสกิล | สเตตัสเด่น (1.06–1.15) | สเตตัสกลาง (1.00) | สเตตัสด้อย (0.90–0.95) | ตัวอย่าง Innate Traits (ตัวอย่าง ไม่ใช่ล็อก 2 ช่อง) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Speedster Striker**<br>(จรวดทางเรียบ) | `0.98` (Ney) | **4★** | Speed: **1.14**<br>Accel/Dash: **1.15**<br>Shot Power: **1.08**<br>Sliding: **1.06** | Dribbling: **1.00**<br>Stamina: **1.00**<br>Pass Velocity: **1.00**<br>Recovery: **1.00** | Strength: **0.90**<br>Block: **0.90**<br>Jump: **0.94**<br>Curve: **0.95**<br>Poke Reach: **0.95** | `Knuckle Emperor` + `Second Wind` |
| **2. Cage Playmaker**<br>(พ่อมดชิ่งกรง) | `0.92` (Leon) | **5★** | Dribbling: **1.15**<br>Curve: **1.14**<br>Pass Velocity: **1.12**<br>Accel/Dash: **1.10**<br>Recovery: **1.10** | Speed: **1.00**<br>Stamina: **1.00**<br>Poke Reach: **1.00** | Strength: **0.90**<br>Jump: **0.90**<br>Block: **0.90**<br>Sliding: **0.92**<br>Shot Power: **0.95** | `Trivela Master` + `Velvet Touch`<br>*(ตัวเลือก: `Wall-Breaker`)* |
| **3. Power Target**<br>(รถถังหน้าเป้า) | `1.03` (Ronan) | **3★** | Shot Power: **1.15**<br>Strength: **1.12**<br>Jump: **1.12**<br>Curve: **1.06** | Speed: **1.00**<br>Stamina: **1.00**<br>Pass Velocity: **1.00**<br>Block: **1.00** | Accel/Dash: **0.92**<br>Sliding: **0.92**<br>Dribbling: **0.94**<br>Poke Reach: **0.94**<br>Recovery: **0.94** | `Acrobat (Sky Striker)` + `One-Touch Specialist`<br>*(ตัวเลือก: `Whipped Finesse`)* |
| **4. Iron Stopper**<br>(กำแพงเหล็กหน้ากรอบ) | `1.08` (Vandik) | **2★** | Strength: **1.15**<br>Block: **1.15**<br>Jump: **1.12**<br>Poke Reach: **1.10**<br>Sliding: **1.08** | Pass Velocity: **1.00**<br>Stamina: **1.00**<br>Recovery: **1.00** | Dribbling: **0.90**<br>Curve: **0.90**<br>Accel/Dash: **0.92**<br>Speed: **0.94**<br>Shot Power: **0.95** | `Iron Wall Block (D1)` + `Bulldozer Impact (D2)`<br>*(ตัวเลือก: `Cage Guardian D7`)* |
| **5. Sweeper Destroyer**<br>(ตัวกวาดไล่ล่า) | `1.03` (Ronan) | **3★** | Sliding: **1.14**<br>Poke Reach: **1.14**<br>Stamina: **1.12**<br>Recovery: **1.12**<br>Speed: **1.10** | Accel/Dash: **1.00**<br>Strength: **1.00**<br>Block: **1.00**<br>Pass Velocity: **1.00**<br>Jump: **1.00** | Shot Power: **0.92**<br>Curve: **0.92**<br>Dribbling: **0.95** | `Shadow Chaser (D5)` + `Clean Sweeper (D3)`<br>*(ตัวเลือก: `Lightning Poke #18`)* |

*(รวมค่าสเตตัส 13 ค่า x 5 Archetypes = 65 ค่าตัวเลขครบถ้วนตามเอกสารต้นทาง)*

---

## 6. Acceptance & Gate Policy

1. **ไม่เปิด Runtime Implementation ใน Phase 1:** ข้อมูลทั้งหมดในแผนนี้ถูกล็อกเป็นสเปกทางการ แต่ห้ามนำไปเปิดใช้งานหรือสร้างโค้ด runtime ใน Phase 1 สำหรับเครื่องมือทดสอบใน [Phase 1 / 06-training-ground](../../phase-01-gameplay-demo/06-training-ground/plan.md) เป็นเครื่องมือแบบ Session-only ในสนามซ้อมเท่านั้น และสถานะการเปิดโค้ด Implementation ของ Debug 06 ยังคงเป็น **PENDING** รอการอนุมัติแยกต่างหาก ห้ามสร้างหรือแก้ไขโค้ด runtime ใดๆ ในงานเอกสารนี้
2. **Phase 1 Demo Baseline & Target Skills:** ตัวละครเริ่มต้นของ Phase 1 ใช้ค่ากลาง 1.00; กรอบเป้าหมายสกิลคือ 7 ท่าไม่ซ้ำ (1★..5★) ติดตั้ง 3 ช่อง โดย 5 แอนิเมชันที่ถูกปฏิเสธอยู่ในกระบวนการปรับแก้ตาม HANDOFF §Q รอตรวจรับ visual จาก Owner ไม่ถือว่าเปิด runtime delivery ของสกิลหรือสเตตัสในรอบนี้
3. **ตรวจสอบความสอดคล้อง:** ตรวจสอบสูตร ตัวคูณ ขอบเขต และ ID อ้างอิงให้ตรงกับ [spec-02](../../../specs/spec-02-duel-and-parry.md), [spec-03](../../../specs/spec-03-cards-rig-freekick.md), [spec-04](../../../specs/spec-04-traits-threads-economy.md) และ [data-schema](../../../design/data-schema.md)
