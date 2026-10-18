# Product Requirements Document (PRD) — Cage Zero

## 1. เป้าหมายผลิตภัณฑ์ (Product Objectives)
สร้างเกมฟุตบอลสตรีทกรงเหล็กสไตล์อนิเมะบน Roblox ที่ผสมผสานการเคลื่อนที่ฟิสิกส์ 3 มิติในกรง 6 เหลี่ยม เข้ากับการดวลอ่านใจแบบ 1v1 Choice และการกด Parry เสี้ยววินาที โดยมีระบบสะสมการ์ดนักเตะ ชุด `Battle Threads` และตลาดแลกเปลี่ยนที่ยุติธรรม (Zero Pay-to-Win)

## 2. กฎเหล็กทางธุรกิจและเกมเพลย์ (Strict Product Constraints)
1. **No Player Avatar Models:** บังคับใช้ `Single Custom R15 Rig` มาตรฐานเดียวทุกตัวละคร ปรับเฉพาะ Scale ส่วนสูง/ความกว้างตามนักเตะต้นแบบ
2. **No Boots/Cleats System:** ตัดระบบรองเท้าสตั๊ดออกทั้งหมด มีเฉพาะชุดสวมใส่ `Battle Threads` เท่านั้น
3. **Zero Pay-to-Win Mutations:** `Mutated Gear` มอบเฉพาะเอฟเฟกต์ VFX, มูลค่าตลาดเทรด และตัวคูณเงิน/EXP หลังจบแมตช์ (`Cash x1.5–x5`, `EXP x1.5–x3`) ห้ามเพิ่มค่าพลังในสนาม
4. **Cooldown-Gated Guaranteed Skills:** สกิลพิเศษของการ์ดและหิน `Trait` ที่การันตีผลลัพธ์ 100% ต้องมี Cooldown เสมอ ห้ามเป็น Passive ถาวร
5. **Choice Duel vs. Parry Separation:**
   - `Choice Duel` เกิดเมื่อผู้ถือบอลเข้าประชิดกองหลัง `<= 6 Studs`
   - `Parry` เกิดเมื่อลูกส่ง/ลูกยิงพุ่งผ่านรัศมี `5 Studs` ของกองหลัง (หน้าต่างกด `0.35 วินาที`) โดยไม่ตัดเข้าหน้าจอดวล
6. **Shooting Zone Enforcement:** ปุ่ม `Snap Shot` ในการดวลกดได้เฉพาะเมื่ออยู่ใน `Shooting Zone` เท่านั้น
7. **Tier-Capped Cutscenes:** ท่าคัตซีนชนะดวลมีได้สูงสุดไม่เกิน 3 ท่าตามระดับ Tier (`Tier B = 1`, `Tier A = 2`, `Tier S = 3`)
8. **Single UI Router (`UIManager`):** หน้าจอทั้งหมดควบคุมผ่าน State Machine ของ `UIManager.luau` แยก `LOBBY_MODE` และ `MATCH_MODE` ออกจากกันอย่างเด็ดขาด
9. **Server-Authoritative 100%:** ทุกการคำนวณผลแพ้ชนะ ระยะยิง คูลดาวน์ ฟิสิกส์บอล กาชา และการเทรด คำนวณบน Server เท่านั้น

## 3. โหมดการเล่น (Game Modes)
- **3v3 Hex-Cage:** โหมดทีมมาตรฐานในสนามกรง 6 เหลี่ยม
- **4v4 Pro Team:** โหมดทีมขนาดใหญ่เน้นการต่อบอลและชิ่งกำแพง
- **1v1v1 King of the Cage:** โหมดกรงเดือดที่ใช้ประตูกลางสนาม
- **Training Ground:** สนามซ้อมส่วนตัวสำหรับซ้อมเตะชิ่งกรง, ซ้อมยิงฟรีคิก FC27 และซ้อมกด Parry

## 4. ลำดับการพัฒนา (Sequential Module Roadmap)
พัฒนาเรียงตามลำดับ `Module 00` ถึง `Module 08` โดยห้ามข้ามโมดูลจนกว่าจะได้รับการอนุมัติ (`STATUS: APPROVED`) และไฟล์ `handoff.md` จาก Codex ในแต่ละโมดูล
