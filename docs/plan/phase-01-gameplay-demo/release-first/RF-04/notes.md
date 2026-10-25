# RF-04: Cage Slingshot — Notes

- **Date:** 2026-10-25
- **Status:** Planning / Documentation Synchronized
- **Related Docs:**
  - [Release-First Track Plan](../plan.md)
  - [Stadium A Specs](../../01-cage-physics/plan.md)

---

## 1. Identity Focus

- Cage Zero มีจุดเด่นคือการใช้กำแพงเป็นอาวุธ ("Turn the walls into your weapon")
- แผน RF-04 ยกระดับกรง Stadium A จากเพียงขอบเขตจำกัดพื้นที่ ให้กลายเป็นองค์ประกอบเกมเพลย์หลักที่เปลี่ยนจังหวะการเล่นจากระนาบ 2D สู่มิติ 3D อย่างแท้จริง

---

## 2. Tuning Philosophy

- ค่าความเร็วและระยะทางเริ่มต้น:
  - `launchSpeedMultiplier`: 1.7x เทียบกับ Sprint
  - `maxDistanceStuds`: 28 studs
  - `windupSec`: 0.20 วินาที
  - `landingRecoverySec`: 0.20 วินาที
  - `staminaCost`: 25 stamina
- ค่าเหล่านี้ถูกจัดให้เป็นค่าตั้งต้นสำหรับการทดสอบ (Tunable Proposals) ไม่ใช่ข้อสรุปว่าเกิดสมดุลสมบูรณ์แบบแล้ว โดยต้องผ่านการเล่นจริงและการปรับจูนตามความเห็นของ Owner
