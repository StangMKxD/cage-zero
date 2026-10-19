# 01-cage-physics — Draft scope contract

- **State:** DRAFT / PLANNING_ONLY; ยังไม่มอบหมาย implementation
- **Authority:** ผู้ใช้สั่งย้ายโฟลเดอร์แผนจริงเข้า phase และปรับเอกสาร ไม่ใช้รหัส feature แยก
- **Active plan:** [plan.md](../plan.md), [tasks](../tasks.md), [notes](../notes.md)
- **Phase:** [Phase 1](../../plan.md); [Phase 2](../../../phase-02-full-match-and-progression/plan.md) รอ phase แรกครบ/ผ่าน gate
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`
- **Implementation approval:** PENDING; approved ตอนนี้เฉพาะการจัดแผน/เอกสาร/โฟลเดอร์
- **Allowed:** agent.md, docs/READ.md, architecture, docs/plan และ path references ที่ได้รับผลจากการย้าย
- **Protect:** sourcemap.json, source code และ sandbox ที่ผู้ใช้/งานอื่นแก้; ไม่ลบประวัติ runs
- **Future execution:** เปิด 00 prerequisite และ 01 ตาม scope ทีละแผน ผ่าน MCP พร้อม source ใน repo
- **Deferred:** Phase 2 ทั้งหมด รวมสุ่มนักเตะ/Tier/stats/เศรษฐกิจ/เอฟเฟค/ตลาด
- **Git:** ผู้ใช้อนุญาต commit/push เฉพาะเอกสารและ .gitignore ของการจัดแผนรอบนี้; ไม่รวม source/sourcemap.json/.sandbox/ หรือ merge/deploy และไม่ใช่สิทธิ์ commit รอบถัดไป

ผลทดลองเก่าใน .sandbox/plan1/implementation-attempt/ ไม่ใช่ acceptance หรือ approval ของแผนใหม่
