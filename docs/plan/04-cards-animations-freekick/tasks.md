# Tasks — MODULE 04: `04-cards-animations-freekick`

- `[ ] Task 04.1:` เขียน `src/shared/configs/CardConfigs.luau` กำหนดข้อมูลการ์ดนักเตะแต่ละ Tier, สัดส่วนความสูง, ชอยส์ดวลพิเศษ (เช่น เมสซี่เลี้ยงผ่าน 100% + Boost ส่ง/ยิง, โรนัลโด้ยิงทะลุบล็อก), คูลดาวน์ และรายการอนิเมชัน
- `[ ] Task 04.2:` เขียน `src/client/controllers/CameraCutsceneController.luau` ทำมุมกล้องซูมสโลว์โมชันสุดเบียวเมื่อชนะดวล พร้อมสุ่มเล่นท่าชนะดวลตามจำนวนที่ Tier การ์ดมี (สูงสุดไม่เกิน 3 ท่า เช่น แตะลอดดาก, Rainbow Flick, Elastico) และแสดงท่าดีใจ Easter Egg หลังยิงประตู
- `[ ] Task 04.3:` เขียน `src/server/services/FreeKickService.luau` และ `src/client/controllers/FreeKickUIController.luau` สร้างระบบยิงลูกนิ่งแบบ FC27 (เล็งเป้า + เลือกจุดสัมผัสบอลเพื่อปั่นโค้ง/ส่าย + กดแถบจังหวะ Timed Bar)
