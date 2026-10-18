# CODEX AUDIT REPORT - 00-bootstrap-and-rig (run-01)

## 1. VERDICT
- **STATUS**: `REJECTED`
- **AUDITED_BY**: Chief Architect / Codex

## 2. CHECKLIST VERIFICATION
- [FAIL] ตรงตามขอบเขตงานใน `plan.md` โดยไม่มีฟีเจอร์เกินสั่ง (`Types.luau` ขาด Type สำคัญตาม `data-schema.md` และโครงสร้างโฟลเดอร์ `runs/` ขาด `.gitkeep`)
- [FAIL] การคำนวณสำคัญอยู่ฝั่ง Server 100% (`Network.luau` ขาด Lazy Remote Creation และ Payload Validators; `RigAndCardService.luau` ยังไม่เชื่อม `InventoryEquipRequest`)
- [FAIL] ผ่านเกณฑ์ TDD ของโมดูลนี้ครบทุกข้อ (`RigAndCardService.luau` มีบั๊ก Double-Scaling และ `Neck.C1` ใช้ `scaleVec` ของลำตัวทำให้คอลอย/จม รวมถึงไม่เกิดใหม่เมื่อ `Humanoid.Died`)

## 3. FIX REQUESTS (บันทึกลงใน `fix.md` หากไม่ผ่าน)
- ดูรายละเอียดทั้ง 5 รายการ (`[FIX-M00-01]` ถึง `[FIX-M00-05]`) ใน `fix.md`
