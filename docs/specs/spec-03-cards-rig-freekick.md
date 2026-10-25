# Spec 03 — การ์ดนักเตะหลาย Tier, Custom Rig, Skill Moves และฟรีคิก FC27

> **Owner Directive 2026-10-25 (Release-First Target Rig — Player Avatar R15 Equal Size):** คำสั่ง Owner ยกเลิก legacy 02/03 (`CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART`) เพื่อเริ่ม [Release-First Track](../plan/phase-01-gameplay-demo/release-first/plan.md) บน **Player Avatar R15 (Normalized to Same Body Dimensions)** (ผู้เล่นใช้ Avatar ตนเองแต่ถูก Normalize ขนาดและมิติ Collision/Contact geometry ให้มีขนาดเท่ากันทั้งหมด แทนที่ game-owned Custom Blocky R15 เดิม; ขนาดร่างกายไม่เปลี่ยนตาม Stats/Cards; รักษารูปลักษณ์ผู้เล่นแต่บังคับขนาดร่างกายเท่ากันทั้งหมด); โครงสร้าง R6 ด้านล่างคงไว้เป็นประวัติศาสตร์อ้างอิงของ legacy 00/01/02

## 1. โครงกระดูกเป้าหมาย (Release-First Target Rig vs Historical Reference)
- **Target ใหม่ (Release-First Track):** ใช้ **Player Avatar R15 (Normalized to Same Body Dimensions)** โดยรักษารูปลักษณ์และอัตลักษณ์ Avatar ของผู้เล่นแต่ละคน แต่ระบบจะทำการ Normalization สเกลและมิติกายภาพจริงของร่างกาย (Collision Box, Height, Width, Depth, HipHeight) ให้มีขนาดเท่ากันทุกคนเพื่อความยุติธรรมในสนาม
  - *ข้อพิจารณาทางเทคนิคเรื่อง Body Packages:* ตัวเลข Scale numbers ใน HumanoidDescription เท่ากันไม่ได้รับประกันขนาดจริงของ arbitrary body packages (เช่น RTHRO, Chibi, Layered Clothing); แผน RF-02 ต้องกำหนด Seam ด้าน Normalization, Attachment points, Bounding Box, และการกรอง Accessory ที่บดบังทัศนวิสัย
- **Stats/Cards ไม่เปลี่ยนขนาดร่างกาย (No Physical Size Variation from Cards):** สถิติตัวละคร 13 ค่าหรือการ์ดนักเตะจะ **ไม่เปลี่ยนแปลงขนาดทางกายภาพของร่างกาย** ใน Target ใหม่นี้; การปรับแต่ง `HeightScale` / `WidthScale` ตาม Archetype ในอดีต (เช่น 0.92, 1.08) คงไว้เป็นเพียงประวัติศาสตร์อ้างอิง (Historical Reference) ไม่นำมาปรับสเกลขนาดตัวในสนาม
- **Historical Baseline (Legacy 00/01/02):** เดิมใช้ Custom R6 (6 visible parts + HumanoidRootPart) เก็บไว้เป็นประวัติศาสตร์อ้างอิง ไม่ใช้เป็น target ในการรันงานใหม่
- scale จาก base sizes/joints และ ground clearance ปรับตาม R15; แผน RF-02 จัดการ Attachment จุดสัมผัสบอล (LeftFootSocket, RightFootSocket, BallDribbleAttachment)
- **Historical Archetype Scale Presets (ประวัติศาสตร์อ้างอิงด้านตัวคูณ ไม่ใช่ขนาดร่างกายจริง):**
  - นักเตะอิงเมสซี่ (`Leon`): อ้างอิงสไตล์ **Cage Playmaker** (เพดานสกิล 5★)
  - นักเตะอิงเนย์มาร์ (`Ney`): อ้างอิงสไตล์ **Speedster Striker** (เพดานสกิล 4★)
  - นักเตะอิงโรนัลโด้ (`Ronan`): อ้างอิงสไตล์ **Power Target** (เพดานสกิล 3★) และ **Sweeper Destroyer** (เพดานสกิล 3★)
  - นักเตะอิงฮาแลนด์/ฟานไดจ์ค (`Vandik`): อ้างอิงสไตล์ **Iron Stopper** (เพดานสกิล 2★)

## 2. ดาว Skill Move และตัวเริ่มต้น — Q22 & DOCS-20261024 Target Specs

Phase 1 มีตัวเริ่มต้น 1 ตัว เพดาน Skill Move 5 ดาว และค่าพื้นฐานกลาง (1.00x) กรอบเป้าหมายสกิลคือ 7 ท่าไม่ซ้ำ (1★..5★) ติดตั้งได้ 3 ช่องตาม [Spec02](spec-02-duel-and-parry.md) โดยมี 5 แอนิเมชันเดิมที่ถูกปฏิเสธอยู่ในกระบวนการปรับแก้ตาม HANDOFF §Q ของ Plan 03 (รอการตรวจรับ visual จาก Owner) ดาวจำกัดระดับท่าที่ใช้ได้ ไม่เพิ่ม stats/Tier หรือเปลี่ยน CardConfigs/Default Card และ 4 scale fixtures ของ 00

Phase2 ระบบการ์ดและตัวละครล็อกสเปกทางการ:
- **13 Outfield Base Stats:** `Speed`, `Jump`, `Shot Power`, `Curve`, `Sliding`, `Strength`, `Dribbling`, `Stamina`, `Pass Velocity`, `Acceleration/Dash`, `Poke Reach`, `Recovery/Reflex`, `Block` ภายใต้กรอบสมดุล `0.90–1.15` (−10% ถึง +15%, ค่ากลาง `1.00`)
- **4 Goalkeeper Stats Deferred:** `Dive Reach`, `Handling`, `Reflex/Dive Recovery`, `Box Distribution` รอเปิดหลังจบ [Phase 1 / 04-goalkeepers](../plan/phase-01-gameplay-demo/04-goalkeepers/plan.md)
- **16 Innate Traits:** ติดตัวละครเท่านั้น (ไม่ใช่หิน Trait บนชุด), จำนวนผันแปร (0, 1, 2, ... รายการ) บัฟตามเงื่อนไขสามารถเกิน Base Cap 1.15 ได้
- **เพดานสกิลตาม Archetype:** จำกัดระดับดาวของท่าสกิลที่ติดตั้งได้ (`2★–5★`)
- รายละเอียดตาราง 65 ค่าสเตตัสและสูตรทั้งหมดดูที่ [03-player-gacha-and-stats](../plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/plan.md) และ [notes N-61](../plan/phase-01-gameplay-demo/01-cage-physics/notes.md#n-61--accepted-decision-13-outfield-base-stats-4-deferred-gk-stats-16-innate-traits-5-character-archetypes-and-body-check-target-mechanics-2026-10-24) โค้ด runtime ใน Phase 1 ไม่ถูกแก้ไข

## 3. Animation และสิ่งที่ถูกแทน

ชุดเป้าหมายสกิล 7 ท่า (ติดตั้ง 3 ช่อง) มีแอนิเมชันท่าร่าง R6 ที่อ่านจังหวะได้ใน Phase 1 โดยไม่หยุดบอล/ล็อกคู่/ทำ I-frame โดย 5 แอนิเมชันอยู่ในกระบวนการปรับแก้ตาม HANDOFF §Q รอการตรวจรับ visual; ท่าเฉพาะและ asset provenance อยู่ที่แผน 03 แยกจาก locomotion 00

Signature Duel Choice/ชอยส์ที่5/การันตีชนะหรือยิงทะลุบล็อก/จำนวนคัตซีน1–3ตามTierและสโลว์แพ้ชนะถูกsupersedeตามQ22 ไม่ใช้เป็นtargetปัจจุบัน แอนิเมชันพร้อมเสียจังหวะเมื่อยิงส่งจังหวะแรกวืดเลื่อนไปPhase2

## 4. ระบบยิงฟรีคิก & ลูกนิ่ง (สไตล์ FC27 Control)
1. **เล็งทิศทาง (`Aim Line`):** ขยับมุมกล้องเล็งทิศทางเริ่มต้นของลูกบอล พร้อมแสดงเส้นวิถีโค้งจำลองสั้นๆ
2. **เลือกจุดสัมผัสบอล (`Ball Spin Selector`):** เลื่อนเป้าวงกลมบนรูปลูกบอลที่มุมจอเพื่อกำหนดการหมุนของบอล:
   - *แตะขอบซ้าย/ขวา:* บอลปั่นโค้งไซด์โป้งหรือไซด์ก้อย (`Curve Shot` / Magnus Effect)
   - *แตะด้านบน/ล่าง:* ลูกบอลพุ่งฮุกตกพื้น (`Dipping Topspin`) หรือลอยโด่งข้ามกำแพง
   - *แตะกึ่งกลางเป๊ะ:* ลูกยิงส่ายไร้ทิศทาง (`Knuckleball`)
3. **กดแถบจังหวะ (`Timed Power & Accuracy Bar`):** กดครั้งแรกเพื่อชาร์จความแรง และกดซ้ำจังหวะที่แถบวิ่งเข้าโซนสีเขียว (`Green` / `Yellow` / `Red`) เพื่อความแม่นยำสูงสุด
- **ความเชื่อมโยงกับสเตตัสและ Trait:** องศาการเลี้ยวโค้งของลูกนิ่งแปรผันตามค่าสเตตัส `Curve` และได้รับผลส่งเสริมจาก Trait พิเศษ (เช่น `Whipped Finesse` มุดลงท้ายวิถี, `Trivela Master` ไซด์ก้อยแรง, และ `Knuckle Emperor` ส่ายไร้สปินในโซน Sweet Spot) ดูรายละเอียดใน [03-player-gacha-and-stats](../plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/plan.md)
