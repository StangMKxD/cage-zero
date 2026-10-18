# Tasks — MODULE 03: `03-duel-choice-engine`

- `[x] Task 03.1:` เขียน `src/shared/configs/ChoiceConfigs.luau` กำหนดรายการ Choice ของกองหน้า กองกลาง และกองหลัง พร้อมตารางแพ้-ชนะทางกัน (Outcome Matrix)
- `[x] Task 03.2:` เขียน `src/server/services/DuelEngineService.luau` ตรวจจับระยะประชิด (`<= 6 Studs`) ล็อกผู้เล่นทั้ง 2 ฝ่ายเข้าสู่สถานะดวลนาน `0.8 วินาที`
- `[x] Task 03.3:` เพิ่มระบบตรวจสอบ `Shooting Zone` ใน `DuelEngineService.luau` เพื่อเปิด/ปิดปุ่มชอยส์ `Snap Shot` ของฝ่ายรุก
- `[x] Task 03.4:` เพิ่มลอจิกคำนวณข้อผิดพลาด (`Mistake Mechanics`) ทั้งสองฝั่ง (Stamina หมด, จับบอลแรกแย่, หักเลี้ยวกะทันหัน, กองหลังหันหลังให้บอล, กองหลังเพิ่งสไลด์วืด) เพื่อลดเวลาเลือกชอยส์หรือล็อกชอยส์บางตัว
- `[x] Task 03.5:` เขียน `src/client/controllers/DuelUIController.luau` เชื่อมต่อข้อมูลกับ `DuelChoiceModal.luau`
