# MODULE 03: `03-duel-choice-engine` (ระบบดวล 1v1 Choice, ตำแหน่ง & ข้อผิดพลาด)

## 1. เป้าหมาย (Objective)
สร้างระบบดวล 1v1 เมื่อผู้ถือบอลเข้าประชิดกองหลัง แสดง Choice แยกตามตำแหน่ง (`Forward`, `Midfielder`, `Defender`) ตรวจสอบระยะยิงสำหรับชอยส์ยิง และคำนวณบทลงโทษจากข้อผิดพลาด (`Mistake Mechanics`)

## 2. เอกสารสเปกที่อ้างอิง (Referenced Specs)
- `docs/specs/spec-02-duel-and-parry.md`
- `docs/design/architecture-and-network.md`

## 3. ห้ามทำเกินขอบเขต (Out of Scope)
- ห้ามให้กองหลังกดชอยส์ `Shot Block` นอกหน้าจอดวล 1v1

## 4. เกณฑ์ตรวจรับสำหรับ Codex (TDD Acceptance Criteria)
1. ชอยส์ `Snap Shot` ต้องไม่ปรากฏให้กดเด็ดขาดหากผู้ถือบอลอยู่นอกระยะยิงที่กำหนด
2. กองหลังมีชอยส์ `Shot Block` ให้เลือกเฉพาะตอนอยู่ในหน้าจอดวล 1v1 เท่านั้น
3. เมื่อ Stamina หมดหรือหันหลังให้บอล ระบบลดโอกาสชนะและล็อกชอยส์ตามตารางสเปกในส่วนที่ 4.3 อย่างถูกต้อง
