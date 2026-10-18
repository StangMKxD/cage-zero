# MODULE 02: `02-ball-control-and-parry` (ระบบเลี้ยง ส่ง ยิง & ระบบกองหลัง Parry)

## 1. เป้าหมาย (Objective)
สร้างระบบครองบอล วิ่งสปรินต์ (Stamina), การส่งบอล, การยิงปกติ และระบบ **Parry เสี้ยววินาที** สำหรับกองหลังเมื่อมีลูกบอลถูกเตะพุ่งผ่านโซนป้องกัน

## 2. เอกสารสเปกที่อ้างอิง (Referenced Specs)
- `docs/specs/spec-02-duel-and-parry.md`
- `docs/design/architecture-and-network.md`

## 3. ห้ามทำเกินขอบเขต (Out of Scope)
- ห้ามเอาหน้าจอดวล Choice มาปนกับระบบ Parry เด็ดขาด

## 4. เกณฑ์ตรวจรับสำหรับ Codex (TDD Acceptance Criteria)
1. เมื่อส่งบอลผ่านหน้ากองหลัง ระบบต้องขึ้นสัญญาณ Parry เสมอ (ไม่ตัดเข้าหน้าจอดวล Choice)
2. การตรวจสอบจังหวะกด Parry คำนวณฝั่ง Server ป้องกันการโกงเวลาจาก Client
