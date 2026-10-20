# Tasks — 01-cage-physics

**Phase 1 | DESIGN_DRAFT / DEPENDS_ON_00 / IMPLEMENTATION_PENDING**
Owner Stang · Planner/Reviewer Codex · Implementer ยังไม่มอบหมาย
[Plan](plan.md) · [Spec](../../../specs/spec-01-cage-and-events.md) · [Architecture](../../../design/architecture-and-network.md)

- [x] P-01: phase layout และ scope สนามเดิม
- [x] P-02a: บันทึกคำสั่งเพิ่ม A/B/C; ผู้ใช้เลือก B/C 8 ผนัง และ physics + marker ไกด์
- [ ] P-02b: ล็อก geometry catalog/API delta/verification matrix/target baseline ก่อน implementation
- [ ] P-03: Owner อนุมัติ contract และ 00 ผ่าน dependency gate จริง

- [ ] T-01: builder/catalog 3 profiles A box, B chamfered 8 ผนัง, C bevel roof 45° จาก config ชุดเดียว
- [ ] T-02: swept collision/finite surfaces/ceiling seams/step budget ทุก profile
- [ ] T-03: transom, 4 corner bumpers, ramp 25° และ back zone 14 พร้อม flags แยก
- [ ] T-04: test launch fixture + shape/mechanics comparison ที่ควบคุมตัวแปร ไม่ทำ BallService gameplay
- [ ] T-05: R6 traversal และ floor/bootstrap seam จาก 00
- [ ] T-98: source/hash, focused probes, visual UAT และตารางผล A/B/C ตาม envelope จริง; ตอนนี้ NOT RUN
- [ ] T-99: sync docs/evidence และส่ง reviewer ไม่ปิดงานเอง

Event pillars/ripple/swinging signs เป็นงานทดลองใน 07 ไม่ทำแทรก 01
Protect user changes/source/reference; Stangอนุญาต local commit เฉพาะเอกสารสนาม/อีเวนต์แยกจาก00 (2026-10-20) ไม่รวม source/ผลงาน00/push/merge/deploy
