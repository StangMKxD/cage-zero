# Notes — 06-training-ground

- Phase 1; เตรียม grill รายละเอียดก่อน implementation
- ข้อสรุปที่ตกลงแล้วอยู่ใน [accepted decisions](../01-cage-physics/notes.md) ไม่คัดลอกหรือถามซ้ำโดยไม่มีเหตุเปลี่ยน
- Source baseline/ผลตรวจเดิมไม่ใช่ approval ของแผนใหม่

## Debug scope — 2026-10-20

ผู้ใช้ขอเพิ่มในplanDebug: ปรับค่าการเล่นเช่นความเร็วพื้นฐานและเสกDummyหลายแบบสำหรับทดสอบในPhase1 ส่วนระบบตั้งค่าเกมฉบับใช้งานจริงเลื่อนไปphaseถัดไป บันทึกเป็นAccepted design / Planned ไม่ใช่implementation approval ใช้sessionoverridesและคืนdefaultได้ รายชื่อค่าจูน/presetที่เสนอในplanยังต้องล็อกก่อนลงมือ ไม่ดึงระบบสุ่ม/ข้อมูลถาวรเข้ามาและไม่เปลี่ยนสัญญา00
