# MODULE 00 EXECUTION RESULT — `00-bootstrap-and-rig` (`run-02`)

- **IMPLEMENTED_BY**: Agy (Team Implementer)
- **MODULE**: `00-bootstrap-and-rig`
- **RUN**: `run-02`
- **STATUS**: `APPROVED`

## 1. รายการแก้ไขที่ดำเนินการครบถ้วน (`[FIX-M00-01]` ถึง `[FIX-M00-05]`)
- **`[FIX-M00-01]` (`src/server/services/RigAndCardService.luau`):**
  - ตั้งค่า `humanoid.AutomaticScalingEnabled = false` เสมอ และบันทึกค่าสเกลเป็น Attribute บน `humanoid` แทน `NumberValue` ป้องกันการสเกลซ้อน 2 เด้ง
  - แก้การคำนวณ `Motor6D` ใน `ApplyCardScale` ให้ `inst.C0` คูณด้วย `getScaleVecForPart(inst.Part0)` และ `inst.C1` คูณด้วย `getScaleVecForPart(inst.Part1)` ทำให้ข้อต่อ `Neck.C1` บนชิ้นส่วน `Head` ไม่เพี้ยนทุกส่วนสูง (`0.92` ถึง `1.08`)
- **`[FIX-M00-02]` (`src/server/services/RigAndCardService.luau`):**
  - ผูก `humanoid.Died:Connect` ให้หน่วงเวลา `2.0 วินาที` แล้วเกิดใหม่เป็น `Single Custom R15 Rig` อัตโนมัติ
  - เชื่อม `InventoryEquipRequest.OnServerEvent` สำหรับหมวด `"Card"` เพื่อตรวจสอบการ์ดและเรียก `EquipCardForPlayer(player, itemId)` ทันที
- **`[FIX-M00-03]` (`src/shared/Types.luau`):**
  - เพิ่ม `ThreadRarity`, `TradeStatus`, `TraitStoneInstance`, `TradeSessionData`, `BoothListingData`, ฟิลด์ `rarity: ThreadRarity` ใน `BattleThreadInstance`, และ `ownedTraits: { TraitStoneInstance }` ใน `PlayerProfileData`
- **`[FIX-M00-04]` (`src/shared/Network.luau`):**
  - เพิ่ม Lazy Remote Creation บน Server ใน `GetRemoteEvent` / `GetRemoteFunction` และเพิ่มฟังก์ชันตรวจสอบ Payload (`IsFiniteVector3`, `IsNonEmptyString`, `IsNumberInRange`)
- **`[FIX-M00-05]` (`docs/plan/`):**
  - สร้างโฟลเดอร์ `uat-images/.gitkeep` และ `fix-images/.gitkeep` ครบทุก `runs/run-XX/` ของทุกโมดูล (`00` ถึง `08`)
