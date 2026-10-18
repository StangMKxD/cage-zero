# Project Execution Roadmap (Modules 00 to 08)

การพัฒนาโปรเจกต์ **Cage Zero** ดำเนินการตามลำดับ `Sequential Module Lock` ครบทั้ง 9 โมดูล (`00` ถึง `08`) และผ่านการตรวจรับ `STATUS: APPROVED & CLOSED` ครบทุกโมดูลแล้ว:

| ลำดับ | โฟลเดอร์โมดูล (`docs/plan/`) | เป้าหมายหลัก (Scope Summary) | สถานะปัจจุบัน |
| :---: | :--- | :--- | :---: |
| **00** | `00-bootstrap-and-rig` | โครงสร้างโปรเจกต์, เอกสาร `docs/`, ตั้งค่า Rojo, `Network.luau` และ `Single Custom R15 Rig` ที่ปรับ Scale ตามการ์ด (`run-02` Fixed & Closed) | `APPROVED & CLOSED` |
| **01** | `01-cage-physics` | สนามกรง 6 เหลี่ยม 3D, เพดานชิ่ง, `Pinball Bumpers`, `360° Goal Zone`, `Elevating Ramps` และฟิสิกส์การสะท้อนฝั่ง Server | `APPROVED & CLOSED` |
| **02** | `02-ball-control-and-parry` | ระบบครองบอล, Stamina, ส่ง/ยิงปกติ และระบบกองหลังกด `Parry` เสี้ยววินาที (`0.35s`) เมื่อบอลพุ่งผ่านรัศมี `5 Studs` | `APPROVED & CLOSED` |
| **03** | `03-duel-choice-engine` | ระบบดวล 1v1 (`<= 6 Studs`) แยก Choice ตามตำแหน่ง (`FW`/`MF`/`DF`), เช็ก `Shooting Zone` และคำนวณ `Mistake Mechanics` | `APPROVED & CLOSED` |
| **04** | `04-cards-animations-freekick` | การ์ดนักเตะหลาย Tier (`B`/`A`/`S`), ชอยส์พิเศษพร้อม Cooldown/Buff, กล้องคัตซีนชนะดวล 1–3 ท่า และฟรีคิก FC27 | `APPROVED & CLOSED` |
| **05** | `05-dynamic-match-events` | ระบบสุ่ม 3 อีเวนต์กลางแมตช์ (`Pillar Lockdown`, `The Blackout Void`, `Favela Alleyway`) ทุก `90 วินาที` | `APPROVED & CLOSED` |
| **06** | `06-traits-threads-economy` | หิน `Trait` มีคูลดาวน์, ชุด `Battle Threads` (ไม่มีรองเท้าสตั๊ด), `Mutated Gear` คูณ Cash/EXP และระบบตลาดเทรด `TradeMarketService` | `APPROVED & CLOSED` |
| **07** | `07-ui-navigation-and-screens` | ระบบ `UIManager.luau` ควบคุม `LOBBY_MODE` และ `MATCH_MODE`, Reusable Components และหน้าจอ UI ทั้ง 11 หน้า | `APPROVED & CLOSED` |
| **08** | `08-integration-and-uat` | เชื่อมต่อ `MatchService.luau` ครบวงจร ทดสอบสมดุลและรัน UAT ครบทุกเคสใน `master-test-cases.md` | `APPROVED & CLOSED` |
