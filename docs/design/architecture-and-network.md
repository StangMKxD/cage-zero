# Architecture & Network Contract (`src/shared/Network.luau`)

## 1. โครงสร้าง Client-Server (100% Server-Authoritative)
- **Server (`src/server/services/`):** คำนวณและตรวจสอบผลแพ้-ชนะในการดวล (`DuelEngineService`), ระยะยิง (`Shooting Zone`), หน้าต่างเวลา `Parry` (`ParryService`), คูลดาวน์ของ `Trait` และ `Signature Choice`, ฟิสิกส์การชิ่งลูกบอล (`CagePhysicsService`, `BallService`), อีเวนต์สนาม (`EventManagerService`), การสร้าง `Single Custom R15 Rig` (`RigAndCardService`), การสุ่มกาชา และการเทรดของ (`TraitAndThreadService`, `TradeMarketService`)
- **Client (`src/client/controllers/` & `src/client/ui/`):** รับอินพุตผู้เล่น ส่งคำขอผ่าน `RemoteEvent`/`RemoteFunction` แสดงผลมุมกล้องคัตซีน (`CameraCutsceneController`), เอฟเฟกต์สนาม (`EventVFXController`) และควบคุมหน้าจอผ่าน `UIManager.luau`
- **Shared (`src/shared/`):** เก็บ `Types.luau`, `Constants.luau`, `Network.luau` และตารางคอนฟิกใน `src/shared/configs/`

## 2. สัญญาการเชื่อมต่อ Network มาตรฐาน (`src/shared/Network.luau`)
ห้ามตั้งชื่อ Remote แยกกันเอง ทุกโมดูลต้องเรียกใช้ชื่อตามตารางนี้ 100%:

| ชื่อ RemoteEvent / Function | ชนิด (Type) | ทิศทาง | พารามิเตอร์ที่ส่ง (Payload) | โมดูลที่ใช้งาน |
| :--- | :--- | :--- | :--- | :--- |
| `BallActionRequest` | `RemoteEvent` | Client -> Server | `(actionType: "Pass" \| "Shoot" \| "Sprint", aimVector: Vector3)` | Module 02 |
| `ParryWindowTrigger` | `RemoteEvent` | Server -> Client | `(ballId: string, windowDuration: number)` | Module 02, 07 |
| `ParryAttemptRequest` | `RemoteEvent` | Client -> Server | `(clientTimestamp: number)` | Module 02 |
| `DuelStartEvent` | `RemoteEvent` | Server -> Client | `(duelId: string, role: "Attacker" \| "Defender", availableChoices: {string}, lockedChoices: {string}, timeLimit: number)` | Module 03, 07 |
| `DuelChoiceSubmit` | `RemoteEvent` | Client -> Server | `(duelId: string, selectedChoiceId: string)` | Module 03, 07 |
| `DuelResultEvent` | `RemoteEvent` | Server -> Client | `(duelId: string, winnerUserId: number, cutsceneAnimId: string, appliedBuff: string?)` | Module 03, 04, 07 |
| `FreeKickStartEvent` | `RemoteEvent` | Server -> Client | `(spotPosition: Vector3, timeLimit: number)` | Module 04, 07 |
| `FreeKickSubmit` | `RemoteEvent` | Client -> Server | `(aimDir: Vector3, spinOffset: Vector2, powerPercent: number, timingZone: "Green" \| "Yellow" \| "Red")` | Module 04, 07 |
| `MatchEventBroadcast` | `RemoteEvent` | Server -> Client | `(eventType: "PillarLockdown" \| "BlackoutVoid" \| "FavelaAlley", state: "Warning" \| "Active" \| "Ended", payload: any)` | Module 05, 07 |
| `InventoryEquipRequest` | `RemoteEvent` | Client -> Server | `(category: "Card" \| "Thread" \| "Trait" \| "Celebration", itemId: string, slotIndex: number?)` | Module 06, 07 |
| `SummonRequest` | `RemoteFunction` | Client -> Server | `(bannerId: string, count: 1 \| 10)` -> คืนค่า `{ObtainedItems}` | Module 06, 07 |
| `TradeActionRequest` | `RemoteEvent` | Client -> Server | `(tradeId: string, action: "AddItem" \| "LockOffer" \| "ConfirmTrade" \| "Cancel", itemUid: string?)` | Module 06, 07 |
