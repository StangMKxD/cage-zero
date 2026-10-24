# Spec 03 — การ์ดนักเตะหลาย Tier, Custom Rig, Skill Moves และฟรีคิก FC27

> ผู้ใช้ยืนยัน Custom R6 ตลอด Phase 1 เมื่อ 2026-10-20 และให้ Codex ปรับแผน/architecture; เป็น accepted design ไม่ใช่ implementation approval ส่วน Phase 2 ยังไม่กำหนดการเปลี่ยน rig [แผน 00](../plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md) / [Architecture](../design/architecture-and-network.md#5-phase-1-runtime--custom-r6)

## 1. โครงกระดูกมาตรฐานเดียว (Single Standard Custom Rig)
- **ห้ามโหลดโมเดลอวาตารผู้เล่นจาก Roblox มาลงสนามเด็ดขาด**
- Phase 1 ใช้ Custom R6 มาตรฐานเดียว: 6 visible parts + HumanoidRootPart และ 6 Motor6Ds ไม่ใช่เปลี่ยน Enum ของ skeleton R15; เกมกำหนด PrimaryPart=HumanoidRootPart
- ใช้ R6 standard locomotion ผ่าน Animator และเก็บ config/source ใน repo; ไม่ใช้ R15 clips หรือ animation pack ส่วนตัว
- scale จาก base sizes/joints และ ground clearance ของ R6 ไม่คัดสูตร HipHeight ของ R15; แผน 00 ไม่เพิ่ม stats/กาชา
- ปรับค่า `HeightScale` และ `WidthScale` ตามข้อมูลการ์ดนักเตะต้นแบบเป็น Easter Egg โดยเชื่อมโยงกับ 5 Character Archetypes ของเกม:
  - นักเตะอิงเมสซี่ (`Leon`): `HeightScale = 0.92` → ต้นแบบสาย **Cage Playmaker** (เพดานสกิล 5★)
  - นักเตะอิงเนย์มาร์ (`Ney`): `HeightScale = 0.98` → ต้นแบบสาย **Speedster Striker** (เพดานสกิล 4★)
  - นักเตะอิงโรนัลโด้ (`Ronan`): `HeightScale = 1.03` → ต้นแบบสาย **Power Target** (เพดานสกิล 3★) และ **Sweeper Destroyer** (เพดานสกิล 3★)
  - นักเตะอิงฮาแลนด์/ฟานไดจ์ค (`Vandik`): `HeightScale = 1.08` → ต้นแบบสาย **Iron Stopper** (เพดานสกิล 2★)

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
