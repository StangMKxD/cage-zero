# MODULE 00: `00-bootstrap-and-rig` (ตั้งค่าโครงสร้างโปรเจกต์ & โมเดลกระดูกมาตรฐาน)

## 1. เป้าหมาย (Objective)
สร้างโครงสร้างโฟลเดอร์เอกสารและซอร์สโค้ดทั้งหมด ตั้งค่า Rojo (`default.project.json`) และสร้างระบบโหลดตัวละครด้วย `Custom R15 Rig` มาตรฐานเดียวที่ปรับความสูงตามข้อมูลนักเตะได้โดยไม่ใช้โมเดลอวาตารของผู้เล่น

## 2. เอกสารสเปกและดีไซน์ที่อ้างอิง (Referenced Specs & Designs)
- `docs/specs/spec-03-cards-rig-freekick.md` (ส่วนที่ 1: โครงกระดูกมาตรฐานเดียว `Single Standard Custom Rig` และสัดส่วน `HeightScale` / `WidthScale`)
- `docs/design/architecture-and-network.md` (สัญญาการเชื่อมต่อ `src/shared/Network.luau` ทั้ง 12 รายการ)
- `docs/design/data-schema.md` (`src/shared/Types.luau`)

## 3. ห้ามทำเกินขอบเขต (Out of Scope)
- ห้ามเพิ่งเขียนระบบฟิสิกส์ลูกบอลหรือระบบดวลในโมดูลนี้
- ห้ามใช้โมเดลอวาตารของผู้เล่น (`Players.CharacterAutoLoads = false` หรือบังคับแทนที่ด้วย Custom R15 Rig ของเกมเสมอ)
- ห้ามทำระบบรองเท้าสตั๊ด

## 4. เกณฑ์ตรวจรับสำหรับ Codex (TDD Acceptance Criteria)
1. โครงสร้างโฟลเดอร์ตรงตามแผนผังในส่วนที่ 2 ของ `startprojects.md` ครบ 100%
2. เมื่อผู้เล่นเข้าเกม โมเดลอวาตารเดิมถูกแทนที่ด้วย Custom Rig มาตรฐานเดียวเสมอ และปรับส่วนสูงตามค่า Config ได้โดยกระดูกไม่เพี้ยน
