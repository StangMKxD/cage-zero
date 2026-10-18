# UI State Machine & Screen Routing (`src/client/ui/UIManager.luau`)

## 1. โหมดหลักของ `UIManager` (Primary Modes)
1. **`MAIN_MENU` (สถานะเริ่มต้นเข้าเกม):**
   - แสดงเฉพาะ `MainMenuScreen`
   - ซ่อน `TopCurrencyBar`, `NavigationDock` และหน้าจอการแข่งขันทั้งหมด
2. **`LOBBY_MODE` (สถานะอยู่ในตัวเมือง / ห้องเตรียมตัว):**
   - แสดง `TopCurrencyBar` (ด้านบน) และ `NavigationDock` (ด้านล่าง) ตลอดเวลา
   - อนุญาตให้เปิดหน้าจอหลักใน Lobby ได้ทีละ 1 หน้าเท่านั้น (`ModeSelectScreen`, `PreMatchLobbyScreen`, `LockerScreen`, `SummonGachaScreen`, `TradingPlazaScreen`)
   - เมื่อสลับหน้าผ่าน `NavigationDock` ต้องปิดหน้าต่างเดิมทันที ห้ามเปิดซ้อนทับกัน
3. **`MATCH_MODE` (สถานะกำลังแข่งขันในสนามกรง):**
   - ซ่อน UI ของ `LOBBY_MODE` ทั้งหมดทันที (`TopCurrencyBar`, `NavigationDock`, และหน้าต่าง Lobby ทุกบาน)
   - แสดง `MatchHUDScreen` เป็นหน้าจอหลัก
   - ควบคุม Modal/Overlay เฉพาะกิจตามสถานะเกม:
     - `DuelChoiceModal`: เปิดเมื่อเกิด `DuelStartEvent` (`<= 6 Studs`) และซ่อนปุ่มควบคุมทั่วไปชั่วคราว
     - `ParryPromptOverlay`: เปิดเมื่อเกิด `ParryWindowTrigger` (`0.35 วินาที`)
     - `FreeKickOverlay`: เปิดเมื่อเกิด `FreeKickStartEvent`
     - `PostMatchSummaryScreen`: เปิดเมื่อจบการแข่งขัน

## 2. ตารางการเปลี่ยนผ่านสถานะ (State Transition Table)

| สถานะต้นทาง (From) | เหตุการณ์ (Trigger / Action) | สถานะปลายทาง (To) | พฤติกรรมของ `UIManager` |
| :--- | :--- | :--- | :--- |
| `MainMenuScreen` | กดปุ่ม `PLAY` | `LOBBY_MODE` (Hub) | ซ่อน `MainMenuScreen`, เปิด `TopCurrencyBar` + `NavigationDock` |
| `LOBBY_MODE` (Any) | กดปุ่มใน `NavigationDock` | `ModeSelect` / `Locker` / `Summon` / `Trade` | ปิดหน้าจอ Lobby ปัจจุบัน แล้วเปิดหน้าที่เลือกเพียงหน้าเดียว |
| `ModeSelectScreen` | เลือกโหมด (`3v3` / `4v4` / `1v1v1`) | `PreMatchLobbyScreen` | เปิดหน้าเลือกตำแหน่ง (`Forward`, `Midfielder`, `Defender`) |
| `PreMatchLobbyScreen` | ทุกคนกด `READY` | `MATCH_MODE` (`MatchHUDScreen`) | ซ่อน UI ของ Lobby ทั้งหมด เปิด `MatchHUDScreen` |
| `MatchHUDScreen` | `DuelStartEvent` (`<= 6 Studs`) | `DuelChoiceModal` | แสดงปุ่ม Choice 1–5 ตามตำแหน่ง ล็อกปุ่มที่ติด `Mistake` หรืออยู่นอก `Shooting Zone` |
| `MatchHUDScreen` | `ParryWindowTrigger` (`<= 5 Studs`) | `ParryPromptOverlay` | แสดงวงแหวนกด `Parry` `0.35 วินาที` โดยไม่ตัดเข้าหน้าจอดวล |
| `MatchHUDScreen` | หมดเวลาการแข่งขัน | `PostMatchSummaryScreen` | แสดง MVP และคำนวณรางวัลคูณตาม `Mutated Gear` |
| `PostMatchSummaryScreen` | กด `RETURN TO LOBBY` | `LOBBY_MODE` (Hub) | ปิด UI สนามทั้งหมด กลับสู่ `LOBBY_MODE` |
