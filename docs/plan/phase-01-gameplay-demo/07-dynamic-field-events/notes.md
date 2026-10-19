> **Historical baseline notes:** ข้อมูลเดิมก่อนย้าย/แยก phase ให้ใช้ plan.md และ tasks.md ในโฟลเดอร์นี้เป็น scope ปัจจุบัน ผลตรวจ/สถานะเก่าไม่ใช่การรับรองแผนใหม่

# Technical Notes — MODULE 05: `05-dynamic-match-events`

- **EventConfigs & EventManagerService:** ควบคุมวงจร `90s interval` / `40s duration` สำหรับ 3 อีเวนต์เท่านั้น (`PillarLockdown`, `BlackoutVoid`, `FavelaAlley`)
- **BlackoutVoid:** ซ่อนผนังกรงและเพดาน (`Transparency = 1.0`) โดยยังคง Hitbox สะท้อนลูกบอล 100% และเปิด `Highlight` เฉพาะเสาโกล ลูกบอล และตัวผู้เล่น
- **FavelaAlley:** ใช้สมการ `ComputePedestrianPosition` บนทั้ง Server และ Client ทำให้ตำแหน่ง NPC ตรงกันทุกเฟรมโดยไม่เปลืองแบนด์วิดท์
