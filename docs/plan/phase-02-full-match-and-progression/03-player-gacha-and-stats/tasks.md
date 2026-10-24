# Tasks — 03-player-gacha-and-stats

**Phase 2 | DEFERRED / PHASE_1_GATE_REQUIRED**

**DOCS REVIEW001: CHANGES_REQUESTED / TURN AGYPLAN / ROUND2**, ref20docs SHA256cf5e643a2f9812563a8c92bbb4472a0ec97b804b3cac5ed0b49db8292a4a9321. [Review](assets/review-001.md): D01 formulas/scope, D02 current7-skill sync, D03 deferred gates, D04 evidence/links. Same DocsOnly allowlist; Owner checks own-pane summary before SEND REPORT, no polling.

**DOCS-20261024 / ASSIGNED_TO_AGYPLAN w2:p49:** Owner authorized Design/Spec/Phase alignment ONLY per [primary docs HANDOFF](assets/HANDOFF.md). Runtime implementation gate above remains intact; agycage continues separate confirmed skillmove work. No src/00/rollback/Git writes.
- [x] D-01: preflight/current gap map/source and protected fingerprints; preserve pre-existing/concurrent dirty work.
- [x] D-02 REWORK D01–D03: formulas (linear inverse only, Strength comparison modulation pending tuning, removed dribble speed penalty), 7-skill/3-slot scope, and deferred gates aligned across docs.
- [x] D-03 REWORK D04: complete programmatic validation of 13/16/5 schema, 65 preset values, bounds, and local link/anchor integrity.
- [x] D-04 REWORK: author assets/docs-fix-001.md cross-linking review-001, relative links, honest Controller attribution, and rollback limitations.

รายการนี้คือคิวงานปัจจุบัน ไม่ใช่ checkbox ส่งมอบจาก module baseline เดิม ดู [plan](plan.md) และ [phase gate](../plan.md)

- [x] P-01: จัดที่อยู่แผนและขอบเขตให้ตรง phase ตามคำสั่งผู้ใช้
- [ ] P-02: ตรวจ prerequisites/grill เรื่องที่ยังเปิด และ sync spec/TDD/contract เฉพาะส่วนก่อนลงมือ
- [ ] P-03: มอบหมาย implementation หลังผ่าน approval/gate ที่เกี่ยวข้อง
- [ ] T-01: ระบบสุ่มตัวละครนักเตะตาม Tier/rarity โดยใช้ 13 Outfield Base Stats (ล็อกสเปกแล้ว) และ 16 Innate Traits; เมื่อเปิดแผน Phase 2 ให้ grill เฉพาะเรื่องอัตราการสุ่ม (Rates), Pity, การรวมการ์ดซ้ำ/การเติบโต และการจูนสูตรละเอียด (ไม่ใช่เปิดถามรายการสเตตัสซ้ำ)
- [ ] T-02: สัดส่วนCustom Rig/ตัวละคร/เพดานSkillMove1–5ดาว แยกจากTier/Stats ไม่คืนSignature Choice/คัตซีนชนะดวล
- [ ] T-03: stats ไม่ใช่การคืนสกิลยิง/ส่งที่ผู้ใช้ตัดออก; ข้อจำกัดความต่าง stats เดิมยังไม่ถูกสั่งยกเลิก
- [ ] T-98: ตรวจ source/ref และ functional/visual evidence ที่จำเป็นผ่าน Studio MCP
- [ ] T-99: sync เอกสารตามผลงานจริงและส่งให้ reviewer ตรวจ ไม่ปิดงานตนเอง
