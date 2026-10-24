# Spec 04 — Innate Traits, Battle Threads, Mutations และตลาด (Phase 2 Target & Baseline)

Q22 และ DOCS-20261024 ล็อกสเปกทางการสำหรับระบบ Innate Traits, ชุดสวมใส่, และตลาดแลกเปลี่ยน; เอกสารนี้ไม่อนุมัติเปิดเศรษฐกิจใน Phase 1 และต้องผ่านเกณฑ์ Phase 1 ทั้งหมดก่อนเปิดดำเนินการ

---

## 1. ระบบ Innate Character Traits (16 รายการ) — คุณสมบัติติดตัวละครเท่านั้น

- **Trait ติดตัวละครเท่านั้น (Innate to Character ONLY):** Trait ไม่ใช่ไอเทมหินถอดใส่ได้ และไม่มีช่องสล็อตบนชุดสวมใส่ใน Target Design
- **จำนวน Trait ผันแปร (Variable Cardinality):** ตัวละครแต่ละตัวมี Trait ติดตัวจำนวนไม่ตายตัว (อาจมี 0, 1, 2, ... รายการ); คู่ Trait ใน 5 Archetypes เป็นเพียงตัวอย่างความเหมาะสม
- **การทะลุเพดานสเตตัส (Conditional Trait Composition):** บัฟของ Trait สามารถส่งผลให้ Effective Stat สูงเกิน Base Cap 1.15 ได้ตามเงื่อนไข (ไม่ถูก Clamp กลับมาที่ 1.15)
- **สิทธิเข้าถึง Trivela พื้นฐาน:** ผู้เล่นทุกคนสามารถใช้ท่า Trivela ได้โดยไม่ต้องปลดล็อก Trait; สำหรับ `Trivela Master` จะเพิ่มความเร็วต้น `+10%` และกลับทิศสปิน (`spinVector = -spinVector`) เพียงครั้งเดียวเทียบกับลูกปั่นปกติ
- **รายการ 16 Innate Traits ที่ยอมรับ (ดูรายละเอียดสูตรใน [03-player-gacha-and-stats](../plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/plan.md)):**
  1. *สายยิง/ชิ่ง (4):* `Whipped Finesse`, `Trivela Master`, `Knuckle Emperor`, `Wall-Breaker`
  2. *สายเทคนิค/เคลื่อนที่ (7):* `Second Wind` (#10), `Velvet Touch` (#13), `One-Touch Specialist` (#14), `Acrobat / Sky Striker` (#15), `Quick Footwork` (#17), `Lightning Poke` (#18), `Elastic Recovery` (#19) *(#11 ตัดออกถาวร)*
  3. *สายกองหลัง/เกมรับ (5):* `Iron Wall Block` (D1), `Bulldozer Impact` (D2), `Clean Sweeper` (D3), `Shadow Chaser` (D5), `Cage Guardian` (D7)

---

## 2. อุปกรณ์สวมใส่ "Battle Threads" (Cosmetic Only — ไม่มีระบบสตั๊ด และไม่มี Trait Slots ใน Target)

- **ห้ามสร้างระบบรองเท้าสตั๊ด (No Boots/Cleats System):** อุปกรณ์สวมใส่มีเพียงชุด **"Battle Threads"** เท่านั้น
- **บทบาทด้านความสวยงาม (Purely Cosmetic):** เป็นชุดสตรีท เสื้อคลุม หรือเกราะเบาอนิเมะเพื่อความเท่ของผู้เล่น
- **ถอดระบบ Trait Slots / Trait Stones ออกจาก Target:**
  - ใน Target Design ใหม่: ชุด Battle Threads **ไม่มีช่องใส่หิน Trait (`maxTraitSlots` ถูกถอดออก)**
  - ถอดหิน `Trait Stone` และการซื้อขายหิน Trait ออกจาก Target Design ทั้งหมด
  - คงข้อมูลเดิมไว้เป็นประวัติศาสตร์แบบมีป้ายกำกับ (Labelled History) ในส่วน Baseline Reference ด้านล่างโดยไม่ลบข้อมูลย้อนหลัง

---

## 3. ระบบ Mutated Gear (ของกลายพันธุ์เพื่อความเท่และคูณฟาร์ม — Zero Pay-to-Win)

- ชุด `Battle Threads` มีโอกาสสุ่มติดสถานะกลายพันธุ์ (`Golden Aura`, `Void Glitch`, `Blood Moon Flame`) จากอีเวนต์พิเศษ
- **ผลลัพธ์ที่อนุญาต:**
  1. เพิ่มเอฟเฟกต์ออร่ารอบตัวและรอยเท้าเรืองแสงเวลาวิ่งในสนาม (VFX)
  2. เพิ่มมูลค่าราคาขายและความต้องการในตลาดเทรดของผู้เล่น
  3. สุ่มมอบบัฟ **คูณเงิน (`Cash Multiplier x1.5 ถึง x5`)** หรือ **คูณค่าประสบการณ์ (`EXP Multiplier x1.5 ถึง x3`)** หลังจบแมตช์เท่านั้น
- **ข้อห้ามเด็ดขาด:** ห้ามเพิ่มความเร็ววิ่ง พลังยิง ความแรงพุ่งชน หรือสิทธิ์ชนะการปะทะในสนามเด็ดขาด

---

## 4. ระบบตลาดแลกเปลี่ยน (`TradeMarketService` — Historical / Proposed Draft Pending Phase 2 Decision)

- **Market Booth (ร่างข้อเสนอเดิม / รอสรุป Phase 2):** ตั้งแผงขายชุด `Battle Threads` (คอสเมติก) และการ์ดนักเตะด้วยเงิน `Cash` (ร่างเดิมระบุ 6 ช่องต่อแผง เป็นตัวเลขดราฟต์ทางประวัติศาสตร์ ยังไม่ถือเป็นข้อยืนยันทางการ และรอการ Grill เมื่อเปิดแผน Phase 2) — *ยืนยันการตัดหิน Trait Stone ออกจาก Target อย่างถาวร*
- **P2P Trade 2 ชั้น (ร่างข้อเสนอเดิม / รอสรุป Phase 2):** กลไกความปลอดภัยแบบ 2 ชั้น: ผู้เล่นทั้งสองฝั่งต้องกด `1. Lock Offer` ก่อน (หากมีการเปลี่ยนของ สถานะ Lock จะหลุดทันที) จากนั้นปุ่ม `2. Confirm Trade` จะนับถอยหลัง (ร่างเดิมระบุ 3 วินาที เป็นตัวเลขดราฟต์ทางประวัติศาสตร์ ยังไม่ยืนยันเป็นข้อกำหนดทางการ) พร้อมระบบล็อกธุรกรรม (`Atomic Transaction / Anti-Dupe Lock`) บน Server
- **สถานะการตัดสินใจ:** นโยบายตลาด อัตราภาษี ราคา และจำนวนช่อง/เวลา ยังไม่ได้รับการอนุมัติเป็น Target requirement ในรอบนี้ และจัดเป็นข้อเสนอดราฟต์รอการตัดสินใจใน Phase 2 ตามที่ระบุใน Phase 2 / 03 Plan

---

## 5. ข้อมูลอ้างอิงโครงสร้างเดิม (Labelled Historical Baseline Reference)

> ส่วนนี้เป็นข้อมูลบันทึกประวัติก่อนการปรับ DOCS-20261024 ซึ่งเคยออกแบบให้มี Trait Slots 1–2 ช่องบนชุด Battle Threads และมีไอเทมหิน Trait Stone ในกระเป๋า ข้อมูลนี้คงไว้เพื่อการตรวจสอบย้อนหลังทางประวัติศาสตร์เท่านั้น ไม่ใช่ Target ปัจจุบัน:
> - *Historical Trait Slots:* เคยกำหนด `maxTraitSlots: number` (`1` หรือ `2` ช่อง) บน `BattleThreadInstance`
> - *Historical Trait Inventory:* เคยกำหนด `ownedTraits: {TraitStoneInstance}` ใน `PlayerProfileData`
> - *Historical Stone Trading:* เคยอนุญาตให้ถอดหิน Trait Stone ไปวางขายในตลาด
