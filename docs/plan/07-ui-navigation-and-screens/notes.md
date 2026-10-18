# Implementation Notes — MODULE 07: `07-ui-navigation-and-screens`

## Technical Decisions
- **Single UI Router Rule (`UIManager.luau`):** บังคับให้ใน `LOBBY_MODE` เปิดหน้าจอหลักได้ทีละ 1 หน้าเท่านั้น (`GetVisibleLobbyScreenCount() == 1`) และเมื่อเข้าสู่ `MATCH_MODE` จะซ่อน `TopCurrencyBar`, `NavigationDock` และหน้าต่าง Lobby ทั้งหมดทันที
- **Strict Separation of Concerns:** ไฟล์ UI ทั้งหมดทำหน้าที่แสดงผลและส่งคำสั่งผ่าน `RemoteEvents` เท่านั้น ไม่มีลอจิกคำนวณผลแพ้ชนะหรือคำนวณเงินฝั่ง Client
- **`DuelChoiceModal` Lock Badges:** แสดงป้าย `OUT OF SHOOTING ZONE` บนปุ่ม `SnapShot` เมื่ออยู่นอกระยะยิง และแสดงไอคอนแม่กุญแจสีแดง (`showRedPadlockIcon = true`) บนปุ่มที่ติด `Mistake`
