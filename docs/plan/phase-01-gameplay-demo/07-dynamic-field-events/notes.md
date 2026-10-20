## Event 5/6 — 2026-10-20

Ownerเปลี่ยนWall-Dash Overdriveเป็นStaminaไม่จำกัดสำหรับทุกคนระหว่างevent ไม่ต้องชิ่งหรือรับballเพื่อเติม และมีแถบhighlightวิ่งเร็วบนหลอด; คูลดาวน์/recoveryปกติคงเดิม Ownerยืนยันเมื่อจบเติมStaminaเต็ม100%แล้วใช้ปกติ โดยCD/recoveryที่เหลือไม่รีเซ็ต OwnerเลือกLow-Roofใช้เพดานเรียบ12studsทุกmapแล้วคืนทรงเดิม จึงรวมcatalog6events ScopeAccepted/Plannedไม่ใช่implementationapproval ไม่รับรองตัวเลข2เท่าหรือเปลี่ยนDashcostปกติจากข้อความตัวอย่าง

## Event 4 decision — 2026-10-20

Ownerขอเพิ่มอีเวนต์ชิ่งแล้วเร่งบอล จากคำตอบสามข้อ: รวมกำแพง/เพดาน/ขอบลาด, เร่งสู่ความเร็วเป้าหมายคงที่ไม่สะสม, จบแล้วหยุดboostใหม่แต่คงความเร็วปัจจุบัน ชื่อRebound Rushเป็นชื่อชั่วคราว รายละเอียดอยู่plan.md; เป็นAccepted/Plannedไม่ใช่implementationapproval Supersedeเฉพาะข้อจำกัดเดิมที่มี3events ส่วนtrialของ3eventเดิมคงไว้

## Current trial decision — 2026-10-20
ผู้ใช้เพิ่มรายการทดลองชิ่งกับ pillarสองระดับ/capเอียง, Blackout impact ripple และ Favela ป้ายแขวนแกว่ง ให้เก็บในแผน07 ไม่ทำแทรก01 ตัวเลขเป็น trial config ไม่ใช่ผล gameplay ที่พิสูจน์แล้ว; B/C เป็น8ผนังและ markerเป็นไกด์ไม่มีแรงช่วยตาม N-34/N-35

> **Historical baseline notes:** ข้อมูลเดิมก่อนย้าย/แยก phase ให้ใช้ plan.md และ tasks.md ในโฟลเดอร์นี้เป็น scope ปัจจุบัน ผลตรวจ/สถานะเก่าไม่ใช่การรับรองแผนใหม่

# Technical Notes — MODULE 05: `05-dynamic-match-events`

- **EventConfigs & EventManagerService:** ควบคุมวงจร `90s interval` / `40s duration` สำหรับ 3 อีเวนต์เท่านั้น (`PillarLockdown`, `BlackoutVoid`, `FavelaAlley`)
- **BlackoutVoid:** ซ่อนผนังกรงและเพดาน (`Transparency = 1.0`) โดยยังคง Hitbox สะท้อนลูกบอล 100% และเปิด `Highlight` เฉพาะเสาโกล ลูกบอล และตัวผู้เล่น
- **FavelaAlley:** ใช้สมการ `ComputePedestrianPosition` บนทั้ง Server และ Client ทำให้ตำแหน่ง NPC ตรงกันทุกเฟรมโดยไม่เปลืองแบนด์วิดท์

OwnerยืนยันEndStaminaแล้วและสั่ง “เสร็จแล้ว commit push เลย” เมื่อ2026-10-20 อนุญาตcommit/pushเอกสารอีเวนต์ที่ตรวจแล้ว ไม่รวมsourceหรือผลงาน00 และไม่ใช่implementationapproval
