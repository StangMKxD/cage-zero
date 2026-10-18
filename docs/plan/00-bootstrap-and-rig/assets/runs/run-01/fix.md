# CODEX FIX REQUESTS - 00-bootstrap-and-rig (run-01)

- **STATUS**: `REJECTED` (ต้องแก้ไขทั้ง 5 รายการใน `run-02`)

1. **`[FIX-M00-01]` (`src/server/services/RigAndCardService.luau`):**
   - ตั้ง `humanoid.AutomaticScalingEnabled = false` และห้ามสร้าง `NumberValue` (`BodyHeightScale` ฯลฯ) ลงใน `Humanoid` เพื่อไม่ให้เอนจิน Roblox สเกลซ้อน 2 เด้ง
   - ใน `ApplyCardScale` ตอนอัปเดต `Motor6D` ต้องคูณ `inst.C0` ด้วย Scale ของ `inst.Part0` และ `inst.C1` ด้วย Scale ของ `inst.Part1` (โดย `Head` ใช้ `headScaleVec`) เพื่อไม่ให้ข้อต่อคอ (`Neck`) ลอยหรือจม
2. **`[FIX-M00-02]` (`src/server/services/RigAndCardService.luau`):**
   - ผูก `humanoid.Died:Connect` ใน `SpawnCustomRigForPlayer` เพื่อหน่วงเวลา `2.0 วินาที` แล้วเกิดใหม่เป็น Custom Rig เสมอ
   - ผูก `InventoryEquipRequest.OnServerEvent` สำหรับหมวด `"Card"` เพื่อเรียก `EquipCardForPlayer(player, itemId)`
3. **`[FIX-M00-03]` (`src/shared/Types.luau`):**
   - เพิ่ม `ThreadRarity`, `TradeStatus`, `TraitStoneInstance`, `TradeSessionData`, `BoothListingData`, เพิ่ม `rarity: ThreadRarity` ใน `BattleThreadInstance`, และเปลี่ยน `ownedTraits: { TraitStoneInstance }` ใน `PlayerProfileData`
4. **`[FIX-M00-04]` (`src/shared/Network.luau`):**
   - เพิ่ม Lazy Creation บน Server ใน `GetRemoteEvent` และ `GetRemoteFunction`
   - เพิ่ม `IsFiniteVector3`, `IsNonEmptyString`, และ `IsNumberInRange`
5. **`[FIX-M00-05]` (`docs/plan/`):**
   - สร้างโฟลเดอร์ `uat-images/` และ `fix-images/` พร้อมไฟล์ `.gitkeep` ในทุก `assets/runs/run-XX/` ของทุกโมดูล (`00` ถึง `08`)
