> **Historical baseline notes:** ข้อมูลเดิมก่อนย้าย/แยก phase ให้ใช้ plan.md และ tasks.md ในโฟลเดอร์นี้เป็น scope ปัจจุบัน ผลตรวจ/สถานะเก่าไม่ใช่การรับรองแผนใหม่

# Technical Notes — MODULE 03: `03-duel-choice-engine`

- **ChoiceConfigs:** กำหนดชุด Choice แยกตาม `Forward`, `Midfielder`, และ `Defender` (มี `ShotBlock` เฉพาะในการดวล 1v1) พร้อมฟังก์ชัน `ResolveChoiceOutcome`
- **DuelEngineService:** ตรวจระยะประชิด `<= 6.0 Studs`, ล็อกปุ่ม `SnapShot` และ `KnuckleEmperor` ทันทีหากอยู่นอก `Shooting Zone`, และคำนวณ `Mistake Mechanics` ลดเวลาจาก `0.80s` เหลือ `0.45s` พร้อมล็อก `TechNutmeg`/`BodyFeint` (ฝั่งบุก) หรือ `JockeyIntercept` (ฝั่งรับ)
