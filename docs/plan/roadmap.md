# Roadmap — ใช้แผนภายใน Phase โดยตรง

**Phase 1: SCOPE_SELECTED / PLANNING | Phase 2: DEFERRED | Implementation approval: PENDING**

## โครงสร้างและลำดับ
- [Phase 1 — Gameplay Demo](phase-01-gameplay-demo/plan.md): 00 bootstrap/Rig -> 01 สนาม/บอล -> 02 player actions -> 03 ดวล -> 04 โกล -> 05 ลูกนิ่ง -> 06 สนามซ้อม -> 07 อีเวนต์ -> 08 gameplay UI -> 09 UAT
- [Phase 2 — Full Game](phase-02-full-match-and-progression/plan.md): 00 แมตช์ -> 01 ตัดสินเสมอ -> 02 transactions -> 03 สุ่มนักเตะ/stats -> 04 collection/เศรษฐกิจ -> 05 สุ่มเอฟเฟค -> 06 ตลาด -> 07 meta UI -> 08 integration/UAT

โฟลเดอร์แผนย้ายอยู่ใต้ phase จริงแล้ว ใช้ชื่อ phase + ชื่อแผนเป็นที่อยู่เดียว ไม่มีรหัส feature อีกชุดเพื่อ map ไปยังโฟลเดอร์แผนแบน ๆ เดิม และไม่มีการทำหลายแผนพร้อมกันจากการจัดโครงนี้

## Scope และ gate
- Phase 1 คง feature ที่ผู้ใช้เลือกครบ: สนาม/Rig/physics, movement/เลี้ยง, ยิงส่ง/ชาร์จ, กลางอากาศ/บล็อก, duel/cutscene/stun, โกลคน/AI, ฟาวล์/ลูกนิ่ง, ซ้อม/หุ่น, อีเวนต์สามแบบและ UI ที่เกี่ยวข้อง
- ระบบแมตช์เต็ม 5 นาที/ตัดสินเสมอ/สุ่มนักเตะและ stats/collection/สุ่มเอฟเฟค/ตลาดรอ Phase 2 หลัง Phase 1 เสร็จครบและผ่าน review gate
- ตัวควบคุมฉากฝึกใน Phase 1 ใช้ทดสอบโกล/ลูกนิ่ง/อีเวนต์ได้ แต่ไม่ถือว่าเปิดวงจรแมตช์เต็ม
- สกิลยิง/ส่งจากการ์ดและ Trait ที่ตัดไม่กลับมาเพียงเพราะเพิ่ม base stats นักเตะ
- กติกาที่ตกลงแล้วเก็บที่ [notes](phase-01-gameplay-demo/01-cage-physics/notes.md) ระบบที่เลื่อนจะ grill เมื่อใกล้ทำ; source หลักคงใน repo และใช้ Studio MCP โดยตรง

## ประวัติและอำนาจ
รายงานเก่า/assets/runs ย้ายตามโฟลเดอร์โดยไม่ลบ ชื่อ/เลขเก่าในรายงานเป็นประวัติ ไม่ใช่ APPROVED ของแผนใหม่ งานที่แยกจากแผนเดิมถูกแบ่งขอบเขตเป็นแผนเฉพาะใน phase ที่ถูกต้องแล้ว

Base SHA `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; Owner Stang, Planner Codex, Implementer/Reviewer ยังไม่มอบหมาย ไม่มีการเปลี่ยน source/รัน application tests/merge/deploy; ผู้ใช้อนุญาต commit/push เฉพาะเอกสารและ .gitignore ในรอบนี้
