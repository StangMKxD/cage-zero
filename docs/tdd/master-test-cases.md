# Master Test Cases & TDD Acceptance Criteria (`docs/tdd/master-test-cases.md`)

เอกสารนี้รวบรวมเกณฑ์การตรวจรับงาน (TDD Acceptance Criteria) สำหรับ **Codex** ในการตรวจสอบแต่ละ Module ตั้งแต่ `00` ถึง `08`

## กฎเหล็กทั่วไปที่ต้องตรวจทุก Module (Global Invariants)
- `[INV-01]` ห้ามทำข้าม Module จนกว่า Module ปัจจุบันจะมี `handoff.md` (`STATUS: APPROVED`) จาก Codex
- `[INV-02]` ห้ามใช้โมเดลอวาตารผู้เล่น ต้องใช้ `Single Custom R15 Rig` มาตรฐานเดียวเสมอ
- `[INV-03]` ห้ามมีระบบรองเท้าสตั๊ด (No Boots/Cleats System) มีเฉพาะชุด `Battle Threads`
- `[INV-04]` ห้ามให้ `Mutated Gear` เพิ่มสเตตัสในสนาม (เพิ่มเฉพาะราคาขาย, VFX, และตัวคูณ Cash/EXP หลังจบแมตช์)
- `[INV-05]` สกิลพิเศษและ `Trait` ที่การันตีผลลัพธ์ 100% ทุกชิ้นต้องมี `Cooldown` ฝั่ง Server
- `[INV-06]` แยก `Choice Duel` (`<= 6 Studs`) กับ `Parry` (`<= 5 Studs`, `0.35 วินาที`) ออกจากกันชัดเจน
- `[INV-07]` ปุ่ม `Snap Shot` กดได้เฉพาะเมื่ออยู่ใน `Shooting Zone` เท่านั้น
- `[INV-08]` อนิเมชันชนะดวลมีได้สูงสุดไม่เกิน 3 ท่าตามระดับ Tier (`B=1`, `A=2`, `S=3`)
- `[INV-09]` หน้าจอ UI ทั้งหมดต้องควบคุมผ่าน `UIManager.luau` ตัวเดียว ห้ามเปิดหน้าต่างซ้อนทับกัน
- `[INV-10]` การคำนวณสำคัญทั้งหมดต้องเป็น `Server-Authoritative 100%`

---

## เกณฑ์ตรวจรับรายโมดูล (Module Acceptance Criteria)

### Module 00: `00-bootstrap-and-rig`
1. **`[TC-00-01]` โครงสร้างโฟลเดอร์:** โครงสร้างโฟลเดอร์และไฟล์ตรงตามแผนผังในส่วนที่ 2 ของ `startprojects.md` ครบ 100%
2. **`[TC-00-02]` Custom R15 Rig & Scale:** เมื่อผู้เล่นเข้าเกม โมเดลอวาตารเดิมถูกแทนที่ด้วย Custom Rig มาตรฐานเดียวเสมอ และปรับส่วนสูง (`HeightScale`, `WidthScale`) ตามค่า Config ของการ์ดนักเตะได้โดยกระดูกไม่เพี้ยน
3. **`[TC-00-03]` Scope & Network Contract:** `src/shared/Types.luau`, `Constants.luau`, และ `Network.luau` กำหนด RemoteEvents/RemoteFunctions ครบทั้ง 12 รายการตามตารางส่วนที่ 4.8 และไม่มีการแอบเขียนระบบฟิสิกส์ลูกบอลหรือระบบดวลเกินขอบเขต

### Module 01: `01-cage-physics`
1. **`[TC-01-01]` Zero Clipping & Reflection:** ลูกบอลชิ่งผนังกรง 6 เหลี่ยมทุกด้าน, เพดาน และแผง Bumper (`Restitution = 1.25`) ตามสมการ `R = V - 2(V·N)N` ได้แม่นยำโดยไม่ทะลุออกจากกรง
2. **`[TC-01-02]` Elevating Ramps & 360° Goal Zone:** เมื่อเลี้ยงบอลขึ้นทางลาดริมเส้น (`25 องศา`) แล้วเตะ ลูกบอลลอยโด่งเข้ากลางสนามตามค่า `Upward Impulse` และพื้นที่หลังประตู (`14 Studs`) สามารถวิ่งอ้อมหรือชิ่งกำแพงได้จริง

### Module 02: `02-ball-control-and-parry`
1. **`[TC-02-01]` Parry vs Duel Separation:** เมื่อส่งบอลหรือยิงบอลผ่านรัศมี `5 Studs` ของกองหลัง ระบบต้องขึ้นสัญญาณ `Parry` (`0.35 วินาที`) เสมอ โดยไม่ตัดเข้าหน้าจอดวล Choice
2. **`[TC-02-02]` Server-Verified Parry Timing:** การตรวจสอบจังหวะกด `Parry` คำนวณฝั่ง Server ป้องกันการโกงเวลาจาก Client หากกดพลาดติด Recovery Cooldown `0.5 วินาที`

### Module 03: `03-duel-choice-engine`
1. **`[TC-03-01]` Shooting Zone Check:** ชอยส์ `Snap Shot` ต้องไม่ปรากฏให้กดเด็ดขาดหากผู้ถือบอลอยู่นอก `Shooting Zone`
2. **`[TC-03-02]` Shot Block Exclusivity:** กองหลังมีชอยส์ `Shot Block` ให้เลือกเฉพาะตอนอยู่ในหน้าจอดวล 1v1 (`<= 6 Studs`) เท่านั้น
3. **`[TC-03-03]` Mistake Mechanics:** เมื่อ Stamina `< 15%`, จับบอลแรกแย่, หักเลี้ยว 180 องศา, สไลด์วืด หรือหันหลังให้บอล ระบบลดเวลาเลือก (`0.8s -> 0.45s`) และล็อกชอยส์ตามตารางส่วนที่ 4.3 อย่างถูกต้อง

### Module 04: `04-cards-animations-freekick`
1. **`[TC-04-01]` Signature Choice Cooldown & Buffs:** ชอยส์พิเศษของนักเตะดังติด Cooldown ทันทีหลังใช้ และมอบบัฟตามเวลาที่กำหนดจริง โดยสเตตัสการ์ด Tier สูงห่างจากการ์ดเริ่มต้นไม่เกิน 15%
2. **`[TC-04-02]` Tier Cutscene Limit:** จำนวนอนิเมชันชนะดวลไม่เกิน 3 ท่าต่อตัวละครตามระดับ Tier (`B=1`, `A=2`, `S=3`)
3. **`[TC-04-03]` FC27 Free Kick Physics:** ระบบฟรีคิกคำนวณวิถีโค้ง (`Magnus Effect`) และการส่าย (`Knuckleball`) ตามจุดสัมผัสบอลและแถบจังหวะได้จริง

### Module 05: `05-dynamic-match-events`
1. **`[TC-05-01]` The Blackout Void:** ขอบกรงและเพดานมองไม่เห็นด้วยตาเปล่า แต่ยังสะท้อนลูกบอลได้เหมือนเดิม และเห็นเสาโกลเรืองแสง ลูกบอลนีออน และตัวผู้เล่นชัดเจน
2. **`[TC-05-02]` Favela Alleyway & Pillar Lockdown:** ตำแหน่ง NPC คนเดินผ่านซิงก์ตรงกันทุกผู้เล่นและสะท้อนบอลได้จริง ส่วนเสาคอนกรีตมีวงเตือนล่วงหน้า `1.5 วินาที` ก่อนผุดและชิ่งบอลได้ 100%

### Module 06: `06-traits-threads-economy`
1. **`[TC-06-01]` No Boots & Zero P2W Mutations:** ยืนยัน 100% ว่าไม่มีระบบรองเท้าสตั๊ด และ `Mutated Gear` ไม่บวก Speed, Shot Power หรือโอกาสชนะดวลในสนาม
2. **`[TC-06-02]` Server Trait Cooldown:** หิน `Trait` ทุกชิ้นมี Cooldown ฝั่ง Server ไม่สามารถกดใช้รัวๆ ได้
3. **`[TC-06-03]` Atomic Trade Lock:** ระบบเทรดมีการล็อกธุรกรรมป้องกันไอเทมสูญหายหรือปั๊มของซ้ำ

### Module 07: `07-ui-navigation-and-screens`
1. **`[TC-07-01]` Complete Screen Routing:** กดเชื่อมต่อไปยังทุกหน้าจอ (`MainMenu` -> `Lobby` -> `Locker` / `Summon` / `Trade` / `ModeSelect` -> `PreMatch` -> `MatchHUD` -> `PostMatch` -> `Lobby`) ได้ครบโดยไม่มีหน้าต่างค้างหรือซ้อนทับกัน
2. **`[TC-07-02]` Locker Sync:** สวมใส่การ์ด, ชุด `Battle Threads`, และหิน `Trait` แล้วข้อมูลอัปเดตตรงกับ Server ทันที
3. **`[TC-07-03]` Duel Modal Locks:** ปุ่ม `Snap Shot` ถูกล็อกหากอยู่นอกระยะยิง และแสดงไอคอนแม่กุญแจสีแดงเมื่อติด `Mistake`

### Module 08: `08-integration-and-uat`
1. **`[TC-08-01]` End-to-End Match Loop:** เชื่อมต่อวงจรแมตช์ตั้งแต่เลือกตำแหน่ง เข้าแข่ง สลับอีเวนต์ จบแมตช์คำนวณรางวัลคูณตาม `Mutated Gear` และแสดงผลที่ `PostMatchSummaryScreen` ครบถ้วน
