# Project Execution Roadmap (Modules 00 to 08)

การพัฒนาโปรเจกต์ **Cage Zero** ต้องดำเนินการตามลำดับ `Sequential Module Lock` ห้ามทำข้ามโมดูลจนกว่าโมดูลปัจจุบันจะได้รับ `STATUS: APPROVED` และไฟล์ `handoff.md` จาก **Codex**:

| ลำดับ | โฟลเดอร์โมดูล (`docs/plan/`) | เป้าหมายหลัก (Scope Summary) | สถานะเริ่มต้น |
| :---: | :--- | :--- | :---: |
| **00** | `00-bootstrap-and-rig` | โครงสร้างโปรเจกต์, เอกสาร `docs/`, ตั้งค่า Rojo, `Network.luau` และ `Single Custom R15 Rig` ที่ปรับ Scale ตามการ์ด | `READY_FOR_REVIEW` |
| **01** | `01-cage-physics` | สนามกรง 6 เหลี่ยม 3D, เพดานชิ่ง, `Pinball Bumpers`, `360° Goal Zone`, `Elevating Ramps` และฟิสิกส์การสะท้อนฝั่ง Server | `LOCKED` |
| **02** | `02-ball-control-and-parry` | ระบบครองบอล, Stamina, ส่ง/ยิงปกติ และระบบกองหลังกด `Parry` เสี้ยววินาที (`0.35s`) เมื่อบอลพุ่งผ่านรัศมี `5 Studs` | `LOCKED` |
| **03** | `03-duel-choice-engine` | ระบบดวล 1v1 (`<= 6 Studs`) แยก Choice ตามตำแหน่ง (`FW`/`MF`/`DF`), เช็ก `Shooting Zone` และคำนวณ `Mistake Mechanics` | `LOCKED` |
| **04** | `04-cards-animations-freekick` | การ์ดนักเตะหลาย Tier (`B`/`A`/`S`), ชอยส์พิเศษพร้อม Cooldown/Buff, กล้องคัตซีนชนะดวล 1–3 ท่า และฟรีคิก FC27 | `LOCKED` |
| **05** | `05-dynamic-match-events` | ระบบสุ่ม 3 อีเวนต์กลางแมตช์ (`Pillar Lockdown`, `The Blackout Void`, `Favela Alleyway`) ทุก `90 วินาที` | `LOCKED` |
| **06** | `06-traits-threads-economy` | หิน `Trait` มีคูลดาวน์, ชุด `Battle Threads` (ไม่มีรองเท้าสตั๊ด), `Mutated Gear` คูณ Cash/EXP และระบบตลาดเทรด `TradeMarketService` | `LOCKED` |
| **07** | `07-ui-navigation-and-screens` | ระบบ `UIManager.luau` ควบคุม `LOBBY_MODE` และ `MATCH_MODE`, Reusable Components และหน้าจอ UI ทั้ง 11 หน้า | `LOCKED` |
| **08** | `08-integration-and-uat` | เชื่อมต่อ `MatchService.luau` ครบวงจร ทดสอบสมดุลและรัน UAT ครบทุกเคสใน `master-test-cases.md` | `LOCKED` |
