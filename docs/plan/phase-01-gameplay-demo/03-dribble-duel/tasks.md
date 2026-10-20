# Tasks — 03 Skill Moves และเกมรับ

**SCOPE_CONFIRMED / IMPLEMENTATION_PENDING** · Owner Stang · Planner/Reviewer Codex · Implementerยังไม่มอบหมาย
[Plan](plan.md) / [Spec02](../../../specs/spec-02-duel-and-parry.md) / [TDD](../../../tdd/master-test-cases.md)
Q22ยืนยันเอกสาร2026-10-20; planningHEADf8729cc+dirtyfiles localcommitเอกสารตามคำสั่งล่าสุดในagent.md ไม่รวมsource/push/merge/deploy

- [x] P-01: เปลี่ยนscopeจากChoiceเป็นSkillMoves/เกมรับตามQ22; คงlegacyfolder/ประวัติ
- [x] P-02a: ตกลง5ท่า/ดาว/3ช่อง/activation/recovery/collision/Phase2deferrals
- [ ] P-02b: finalize02seams/animationassets/intentNetworkและverificationก่อนimplementationHANDOFF
- [ ] P-03: Ownerอนุมัติimplementationหลัง02ผ่านgate
- [ ] T-01: catalog5ท่า/ตัวทดสอบ5ดาว/3ช่อง/เลือกชุดก่อนรอบหรือหยุดรีเซ็ต ไม่เปิดกาชา
- [ ] T-02: Skill action lifecycle/ทิศ/Servervalidation/R6ท่าร่าง/บอลยังสัมผัสได้ ไม่มีFeintเดิม
- [ ] T-03: Poke/Slide/Shoulder/ชนคู่แข่งช้าลง/เพื่อนผ่านตัวได้และผลcontactตามSpec02
- [ ] T-04: CDแยก+ช่วงจบท่าร่วม/cost/recovery/cleanupโดยใช้ทรัพยากร02 ไม่เขียนball stateซ้ำ
- [ ] T-05: retireเฉพาะoldChoicebootstrap/handlersที่ระบุในHANDOFF ไม่reuseDuelremotesผิดความหมาย
- [ ] T-98: runtime5moves/สกัดได้/ต้นทุนไม่พอ/CD/รีเซ็ต/เปลี่ยนทีมและvisualอ่านท่าได้; ตอนนี้NOT RUN
- [ ] T-99: syncdocs/currenthash/evidence ส่งreview ไม่ปิดงานเอง
