# Tasks — MODULE 06: `06-traits-threads-economy`

- `[x] Task 06.1:` เขียน `src/shared/configs/TraitConfigs.luau` และ `ThreadConfigs.luau` กำหนดรายการ Trait การันตีแบบมีคูลดาวน์ (ส่งแม่น 100%, ยิงเข้า 100%, ดวลรับชนะ 100%) และข้อมูลชุด `Battle Threads`
- `[x] Task 06.2:` เขียน `src/server/services/TraitAndThreadService.luau` จัดการการสุ่ม Trait, การใส่/ถอดหิน Trait ลงในช่องของชุด `Battle Threads` และการคำนวณผลคูณเงิน/EXP ของชุดที่ติดสถานะ `Mutated Gear`
- `[x] Task 06.3:` เขียน `src/server/services/TradeMarketService.luau` สร้างระบบแลกเปลี่ยนและตั้งขายชุด `Battle Threads`, หิน `Trait`, และการ์ดนักเตะระหว่างผู้เล่น พร้อมระบบป้องกันการปั๊มของซ้ำ (Anti-Dupe Lock)
