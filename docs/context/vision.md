# Project Vision — Cage Zero (Anime Street Hex-Cage Football)

## 1. ภาพรวมของเกม (Core Vision)
**Cage Zero** คือเกมฟุตบอลสตรีทกรงเหล็ก 6 เหลี่ยมสไตล์อนิเมะบน Roblox ที่เน้นจังหวะการตัดสินใจเชิงกลยุทธ์ (Tactical Mind-Games), ฟิสิกส์การชิ่งกำแพง/เพดาน 5 มิติ และคัตซีนอนิเมชันสุดเบียว โดยให้ผู้เล่นที่มีทักษะ ไหวพริบ และการอ่านทางคู่ต่อสู้สามารถเอาชนะคู่แข่งได้โดยไม่พึ่งระบบ Pay-to-Win

## 2. เสาหลักการออกแบบ (Core Design Pillars)
1. **5-in-1 Extreme Hex-Cage Arena:** สนามกรง 6 เหลี่ยม 3D พร้อมเพดานตาข่ายชิ่งบอล, แผงดีด Pinball Bumpers (`Restitution = 1.25`), พื้นที่เล่นหลังโกล 360° (`14 Studs`), ทางลาดริมเส้น (`25 องศา`) และรองรับทั้งโหมด `3v3`, `4v4` และ `1v1v1 King of the Cage`
2. **Tactical 1v1 Choice Duel vs. Split-Second Parry:**
   - แยกการดวลประชิดตัว (`Choice Duel` ระยะ `<= 6 Studs`) ออกจากระบบสกัดบอลพุ่งผ่านทาง (`Parry System` ระยะ `5 Studs`, หน้าต่างกด `0.35 วินาที`) อย่างชัดเจน
   - ชุด Choice แตกต่างกันตามตำแหน่ง (`Forward`, `Midfielder`, `Defender`) และคำนวณบทลงโทษจากข้อผิดพลาด (`Mistake Mechanics`)
3. **Single Standard Custom R15 Rig & Anime Aesthetics:**
   - ตัวละครทุกตัวใช้โครงกระดูกมาตรฐานเดียว (`Single Custom R15 Rig`) ล็อกใบหน้าสไตล์อนิเมะ และปรับเฉพาะสัดส่วนความสูง/ความกว้าง (`HeightScale`, `WidthScale`) ตามนักเตะต้นแบบ
   - คัตซีนชนะดวลสูงสุดไม่เกิน 3 ท่าตามระดับ Tier การ์ด (`Tier B = 1`, `Tier A = 2`, `Tier S = 3`)
4. **Fair Progression & Zero Pay-to-Win Economy:**
   - ไม่มีระบบรองเท้าสตั๊ด (No Boots/Cleats System) มีเฉพาะชุดสวมใส่ **"Battle Threads"** และหิน **Trait**
   - สกิลและการ์ดการันตีผลลัพธ์ 100% ทุกชิ้นต้องมี **Cooldown** ฝั่ง Server เสมอ
   - **Mutated Gear** เพิ่มเฉพาะมูลค่าการเทรด, เอฟเฟกต์ออร่า VFX และตัวคูณเงิน/EXP หลังจบแมตช์ (`Cash Multiplier x1.5–x5`, `EXP Multiplier x1.5–x3`) ห้ามบวกสเตตัสในสนามเด็ดขาด
5. **100% Server-Authoritative Architecture:**
   - การคำนวณผลดวล, ระยะยิง (`Shooting Zone`), คูลดาวน์ Trait, ฟิสิกส์ลูกบอล, การสุ่มกาชา และการเทรด ต้องตรวจสอบบน Server ทั้งหมด
