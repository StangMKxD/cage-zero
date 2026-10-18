# Technical Notes — MODULE 00: `00-bootstrap-and-rig`

- **2026-10-18 (Acceptance & Bootstrap):** เริ่มดำเนินการ `MODULE 00: 00-bootstrap-and-rig` ตาม `startprojects.md`
- **Git Setup:** ตั้งค่า Repository ที่ `C:\Users\Stang\cage-zero` เชื่อมต่อ `origin` ไปยัง `https://github.com/StangMKxD/cage-zero.git` บนกิ่ง `main` เรียบร้อยแล้ว
- **Task 00.1 (`[x]`):** สร้าง `agent.md` ที่ Root และโครงสร้างเอกสารทั้งหมดใน `docs/context/`, `docs/prd/`, `docs/specs/`, `docs/design/`, `docs/tdd/`, และ `docs/plan/` (ครบทั้ง 9 Modules `00` ถึง `08`)
- **Task 00.2 (`[x]`):** สร้าง `default.project.json` สำหรับ Rojo 7.7.1 และโครงสร้างไฟล์ใน `src/client`, `src/server`, `src/shared` ครบ 100% ตามแผนผังส่วนที่ 2 (ไฟล์ของ Module `01`–`08` เป็นโมดูลตั้งต้น `--!strict` ที่ไม่มีลอจิกเกินขอบเขต)
- **Task 00.3 (`[x]`):** เขียน `src/shared/Types.luau`, `src/shared/Constants.luau`, และ `src/shared/Network.luau` กำหนด RemoteEvents/RemoteFunctions ครบทั้ง 12 รายการตามตารางส่วนที่ 4.8
- **Task 00.4 (`[x]`):** เขียน `src/server/services/RigAndCardService.luau` และ `src/shared/configs/CardConfigs.luau` ปิด `Players.CharacterAutoLoads = false`, บังคับสร้าง `Single Custom R15 Rig` มาตรฐานเดียวพร้อมล็อกใบหน้าสไตล์อนิเมะ (`AnimeFaceLocked = true`), และปรับขนาดชิ้นส่วนรวมถึงออฟเซ็ต `Motor6D` (`C0`/`C1`) ตาม `HeightScale` / `WidthScale` ของการ์ดนักเตะ (`Leon = 0.92`, `Ney = 0.98`, `Ronan = 1.03`, `Vandik = 1.08`) โดยกระดูกไม่เพี้ยน
- **Verification:** ทดสอบคอมไพล์โปรเจกต์ด้วย `rojo sourcemap` และ `rojo build default.project.json` ผ่านสมบูรณ์ (`0 errors`)
