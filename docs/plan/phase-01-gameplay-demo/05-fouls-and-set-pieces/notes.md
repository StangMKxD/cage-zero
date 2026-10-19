> **Historical baseline notes:** ข้อมูลเดิมก่อนย้าย/แยก phase ให้ใช้ plan.md และ tasks.md ในโฟลเดอร์นี้เป็น scope ปัจจุบัน ผลตรวจ/สถานะเก่าไม่ใช่การรับรองแผนใหม่

# Technical Notes — MODULE 04: `04-cards-animations-freekick`

- **CardConfigs:** กำหนดการ์ดนักเตะครบทั้ง `Tier B` (1 ท่าชนะดวล), `Tier A` (2 ท่า), และ `Tier S` (3 ท่า) โดยจำกัดค่าสเตตัสห่างจากการ์ดเริ่มต้นไม่เกิน 15% และทุก `Signature Choice` มี Cooldown ฝั่ง Server
- **CameraCutsceneController:** ใช้เทคนิคถอน Inverse Offset ก่อนคำนวณมุมกล้องเฟรมถัดไป (`MEM-FIX-0003`) ป้องกันปัญหา Camera Drift 100%
- **FreeKickService:** คำนวณ `Magnus Force` (Curve), `Dipping Topspin`, และ `Knuckleball` (เมื่อ `spinOffset.Magnitude < 0.15`) ร่วมกับโซนจังหวะ `Green` / `Yellow` / `Red`
