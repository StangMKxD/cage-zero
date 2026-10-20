# Spec 03 — การ์ดนักเตะหลาย Tier, Custom Rig, Skill Moves และฟรีคิก FC27

> ผู้ใช้ยืนยัน Custom R6 ตลอด Phase 1 เมื่อ 2026-10-20 และให้ Codex ปรับแผน/architecture; เป็น accepted design ไม่ใช่ implementation approval ส่วน Phase 2 ยังไม่กำหนดการเปลี่ยน rig [แผน 00](../plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md) / [Architecture](../design/architecture-and-network.md#5-phase-1-runtime--custom-r6)

## 1. โครงกระดูกมาตรฐานเดียว (Single Standard Custom Rig)
- **ห้ามโหลดโมเดลอวาตารผู้เล่นจาก Roblox มาลงสนามเด็ดขาด**
- Phase 1 ใช้ Custom R6 มาตรฐานเดียว: 6 visible parts + HumanoidRootPart และ 6 Motor6Ds ไม่ใช่เปลี่ยน Enum ของ skeleton R15; เกมกำหนด PrimaryPart=HumanoidRootPart
- ใช้ R6 standard locomotion ผ่าน Animator และเก็บ config/source ใน repo; ไม่ใช้ R15 clips หรือ animation pack ส่วนตัว
- scale จาก base sizes/joints และ ground clearance ของ R6 ไม่คัดสูตร HipHeight ของ R15; แผน 00 ไม่เพิ่ม stats/กาชา
- ปรับค่า `HeightScale` และ `WidthScale` ตามข้อมูลการ์ดนักเตะต้นแบบเป็น Easter Egg โดยใบหน้ายังคงเป็นสไตล์อนิเมะของเกม:
  - นักเตะอิงเมสซี่ (`Leon`): `HeightScale = 0.92`
  - นักเตะอิงเนย์มาร์ (`Ney`): `HeightScale = 0.98`
  - นักเตะอิงโรนัลโด้ (`Ronan`): `HeightScale = 1.03`
  - นักเตะอิงฮาแลนด์/ฟานไดจ์ค (`Vandik`): `HeightScale = 1.08`

## 2. ดาว Skill Move และตัวเริ่มต้น — Q22 supersedes Signature Choice

Phase1มีตัวเริ่มต้น1ตัว SkillMove5ดาวและค่าพื้นฐานกลาง ใช้5ท่าทดลองฟรี ติดตั้ง3ช่องตาม [Spec02](spec-02-duel-and-parry.md) ดาวจำกัดระดับท่าที่ใช้ได้ ไม่เพิ่มstats/Tierหรือเปลี่ยนCardConfigs/Default Cardและ4scalefixturesของ00

Phase2สุ่มตัวละคร/ดาว/Statsและskill inventory รายการStatsเริ่มgrillจากSpeed,Jump,ShotPower,Curve,Sliding,Strength คงขอบเขตสมดุลการ์ดเดิมจนOwnerปรับอย่างชัดเจน ไม่มีสูตร/เรต/ราคาอนุมัติในรอบนี้

## 3. Animation และสิ่งที่ถูกแทน

Skill5ท่ามีR6ท่าร่างอ่านจังหวะได้ในPhase1โดยไม่หยุดบอล/ล็อกคู่/ทำI-frame; ท่าเฉพาะและassetprovenanceอยู่แผน03 แยกจากlocomotion00

Signature Duel Choice/ชอยส์ที่5/การันตีชนะหรือยิงทะลุบล็อก/จำนวนคัตซีน1–3ตามTierและสโลว์แพ้ชนะถูกsupersedeตามQ22 ไม่ใช้เป็นtargetปัจจุบัน แอนิเมชันพร้อมเสียจังหวะเมื่อยิงส่งจังหวะแรกวืดเลื่อนไปPhase2

## 4. ระบบยิงฟรีคิก & ลูกนิ่ง (สไตล์ FC27 Control)
1. **เล็งทิศทาง (`Aim Line`):** ขยับมุมกล้องเล็งทิศทางเริ่มต้นของลูกบอล พร้อมแสดงเส้นวิถีโค้งจำลองสั้นๆ
2. **เลือกจุดสัมผัสบอล (`Ball Spin Selector`):** เลื่อนเป้าวงกลมบนรูปลูกบอลที่มุมจอเพื่อกำหนดการหมุนของบอล:
   - *แตะขอบซ้าย/ขวา:* บอลปั่นโค้งไซด์โป้งหรือไซด์ก้อย (`Curve Shot` / Magnus Effect)
   - *แตะด้านบน/ล่าง:* ลูกบอลพุ่งฮุกตกพื้น (`Dipping Topspin`) หรือลอยโด่งข้ามกำแพง
   - *แตะกึ่งกลางเป๊ะ:* ลูกยิงส่ายไร้ทิศทาง (`Knuckleball`)
3. **กดแถบจังหวะ (`Timed Power & Accuracy Bar`):** กดครั้งแรกเพื่อชาร์จความแรง และกดซ้ำจังหวะที่แถบวิ่งเข้าโซนสีเขียว (`Green` / `Yellow` / `Red`) เพื่อความแม่นยำสูงสุด
