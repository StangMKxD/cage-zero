# Spec 05 — ระบบ UI ทั้งหมด, การเชื่อมต่อหน้าจอ และ HUD

## 1. กฎการควบคุมหน้าจอด้วย `UIManager` ตัวเดียว (Single UI Router Rule)
ระบบ UI ทั้งหมดบริหารจัดการผ่าน `src/client/ui/UIManager.luau` โดยแบ่งเป็น **2 โหมดหลัก (`LOBBY_MODE` และ `MATCH_MODE`)** ห้ามเปิดหน้าต่างซ้อนทับกันมั่ว เมื่อเข้าสู่ `MATCH_MODE` ต้องซ่อน UI ของ Lobby ทั้งหมดทันที

## 2. ผังการเชื่อมต่อหน้าจอ (UI Screen Navigation Map)
- `MainMenuScreen` -> กด `PLAY` -> เข้าสู่ `LOBBY_MODE` (`TopCurrencyBar` + `NavigationDock`)
- `NavigationDock` สลับหน้าจอหลักใน Lobby:
  - `PLAY MATCH` -> `ModeSelectScreen` (`3v3 Hex-Cage`, `4v4 Pro`, `1v1v1 King of Cage`) -> `PreMatchLobbyScreen` (เลือก `Forward`, `Midfielder`, `Defender` + กด `READY`) -> ตัดเข้า `MATCH_MODE`
  - `LOCKER` -> `LockerScreen` (3 แท็บ: `Player Cards`, `Battle Threads`, `Celebrations`)
  - `SUMMON` -> `SummonGachaScreen` (ตู้สุ่มการ์ด Tier B/A/S พร้อม Pity `100` และตู้สุ่ม Trait / Battle Threads)
  - `TRADE PLAZA` -> `TradingPlazaScreen` (`Market Booth UI` 6 ช่อง และ `P2P Trade Window` ยืนยัน 2 ชั้น)
  - `TRAINING` -> สนามซ้อมส่วนตัว
- ใน `MATCH_MODE`:
  - แสดง `MatchHUDScreen` เป็นหลัก
  - เมื่อเข้าดวล 1v1 (`<= 6 Studs`): เด้ง `DuelChoiceModal`
  - เมื่อบอลส่ง/ยิงผ่านกองหลัง (`<= 5 Studs`): เด้ง `ParryPromptOverlay` (`0.35 วินาที`)
  - เมื่อได้ลูกนิ่ง/ฟรีคิก: เปิด `FreeKickOverlay`
  - เมื่อหมดเวลาแข่งขัน: เปิด `PostMatchSummaryScreen` (`Play Again` -> `PreMatchLobbyScreen`, `Return Lobby` -> `LOBBY_MODE`)

## 3. รายละเอียดองค์ประกอบในแต่ละหน้าจอ (Screen-by-Screen Specs)
1. **`MainMenuScreen.luau`:** โลโก้เกม, ตัวละคร Custom Rig โพสท่าประจำการ์ด, ปุ่ม `PLAY`, ปุ่ม `SETTINGS`
2. **`TopCurrencyBar.luau` & `NavigationDock.luau`:** แสดง `Cash`, เลเวล, `EXP`, ตัวคูณจากชุด Mutated และแถบปุ่มเมนู 5 ปุ่ม (`Play`, `Locker`, `Summon`, `Trade`, `Training`)
3. **`ModeSelectScreen.luau` & `PreMatchLobbyScreen.luau`:** การ์ดเลือกโหมด และหน้าเลือกตำแหน่ง (`FW`, `MF`, `DF`) พร้อมพรีวิวชุด Choice ประจำตำแหน่งและปุ่ม `READY`
4. **`LockerScreen.luau`:** พรีวิวโมเดล Custom Rig หมุน 360 องศา + ตารางเก็บของ 3 แท็บ (`Cards`, `Battle Threads` พร้อมช่อง `Trait Slot 1-2`, `Celebrations`)
5. **`SummonGachaScreen.luau`:** แบนเนอร์หน้าตู้, เรต (`Tier S: 0.5%`, `Tier A: 9.5%`, `Tier B: 90%`), ตัวนับ Pity (`0/100`), ปุ่ม `Summon x1` และ `Summon x10`
6. **`TradingPlazaScreen.luau`:** `Market Booth UI` (6 ช่อง) และ `P2P Trade Window` (กด `1. Lock Offer` และรอนับถอยหลัง `3 วินาที` ก่อนกด `2. Confirm Trade`)
7. **`MatchHUDScreen.luau`:** สกอร์บอร์ด, เวลานับถอยหลัง, `Event Alert Banner`, `Stamina Bar` (กะพริบสีแดงเมื่อ `< 15%`), ป้ายบัฟ/Mistake และ `Skill & Trait Dock`
8. **`DuelChoiceModal.luau`:** หลอดเวลา (`0.8 วิ` หรือ `0.45 วิ`), ปุ่ม Choice 1–5 ตามตำแหน่ง, ป้าย `OUT OF SHOOTING ZONE` บนปุ่ม `Snap Shot` เมื่ออยู่นอกระยะยิง และไอคอนแม่กุญแจสีแดงทับปุ่มที่ติด `Mistake`
9. **`ParryPromptOverlay.luau`:** วงแหวนหดเข้าตรงกลางภายใน `0.35 วินาที` พร้อมปุ่ม `[F] PARRY`
10. **`FreeKickOverlay.luau`:** เส้นเล็งวิถีบอล, `Spin Cursor` บนรูปลูกบอล และหลอด `Timed Power Bar` กด 2 จังหวะ
11. **`PostMatchSummaryScreen.luau`:** ตัวละคร MVP เล่นท่าดีใจ, ตารางคะแนน, กล่องคำนวณรางวัล (`Base Match Reward` + `Mutated Thread Bonus` = `Total Cash & EXP`), ปุ่ม `PLAY AGAIN` และ `RETURN TO LOBBY`
