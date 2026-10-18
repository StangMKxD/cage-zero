# MODULE 06: `06-traits-threads-economy` (ระบบ Trait มีคูลดาวน์, ชุด Battle Threads & Mutated Gear)

## 1. เป้าหมาย (Objective)
สร้างระบบสุ่ม Trait (แบบมีคูลดาวน์), ระบบสวมใส่ชุด `Battle Threads` (ไม่มีรองเท้าสตั๊ด), ระบบ `Mutated Gear` (เพิ่มราคา/เอฟเฟกต์/คูณเงินหรือ EXP โดยไม่เพิ่มสเตตัสโกง) และระบบตลาดเทรดระหว่างผู้เล่น

## 2. เอกสารสเปกที่อ้างอิง (Referenced Specs)
- `docs/specs/spec-04-traits-threads-economy.md`
- `docs/design/data-schema.md`
- `docs/design/architecture-and-network.md`

## 3. ห้ามทำเกินขอบเขต (Out of Scope)
- ห้ามเพิ่มระบบรองเท้าสตั๊ด และห้ามให้ Mutated Gear บวกค่าพลังในสนามเด็ดขาด

## 4. เกณฑ์ตรวจรับสำหรับ Codex (TDD Acceptance Criteria)
1. ตรวจสอบโค้ดยืนยัน 100% ว่าไม่มีระบบรองเท้าสตั๊ด และ `Mutated Gear` ไม่มีผลบวกค่า Speed, Shot Power หรือโอกาสชนะดวลในสนาม (บวกเฉพาะราคาขาย, เอฟเฟกต์ VFX, และตัวคูณ Cash/EXP เท่านั้น)
2. Trait ทุกชิ้นมีระบบ Cooldown ฝั่ง Server ไม่สามารถกดใช้รัวๆ ได้
3. ระบบเทรดมีการล็อกธุรกรรม (Atomic Transaction) ป้องกันไอเทมสูญหายหรือปั๊มของ
