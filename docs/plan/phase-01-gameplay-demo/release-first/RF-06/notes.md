# RF-06: Match, HUD & Economy — Notes

- **Date:** 2026-10-25
- **Status:** Planning / Documentation Synchronized
- **Related Docs:**
  - [Release-First Track Plan](../plan.md)
  - [Spec 05 — UI & HUD](../../../../specs/spec-05-ui-navigation-and-hud.md)
  - [Phase 2 Match Flow Plan](../../../phase-02-full-match-and-progression/00-match-flow/plan.md)

---

## 1. Casual 2v2 Focus

- การเลือกใช้รูปแบบ 2v2 ใน Stadium A ช่วยลดความซับซ้อนของ Network replication และ Pathing ทำให้การต่อสู้แย่งบอลเข้มข้น รวดเร็ว และเหมาะกับสไตล์สตรีท
- การไม่บังคับใช้โกล AI (No GK AI) ช่วยหลีกเลี่ยงบั๊กที่เกิดจากการตัดสินใจของ AI และทำให้ประตูเป็นเป้าหมายที่ผู้เล่นต้องช่วยกันบล็อกและป้องกันเอง

---

## 2. Minimal Viable Economy

- แทนที่จะรอระบบตลาด (Market) หรือระบบ Gacha เต็มรูปแบบของ Phase 2 ใน RF-06 เราเปิดใช้วงจรเศรษฐกิจขั้นต่ำคือ: **เล่นแมตช์ → ได้รับ Cash → นำไปสุ่มตัวละคร (RF-05) หรือซื้อ Cosmetic 1 ชิ้นในร้านค้า**
- สิ่งนี้ทำให้เกมมี Retention Loop ทันทีที่เปิด Public Alpha
