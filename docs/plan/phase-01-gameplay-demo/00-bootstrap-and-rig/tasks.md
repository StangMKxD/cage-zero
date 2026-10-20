# Tasks — 00-bootstrap-and-rig

**Phase 1 | PAUSED_BY_OWNER | Turn OWNER (Stang) | Review 010 / Round 5 NOT DISPATCHED**
Owner Stang · Planner/Reviewer Codex · Implementer AGY Teamwork-preview (Session: e86ac30e-006d-4338-9a90-5f5e3b002028, Run: run-phase00-agy-impl-01)
Baseline main @ `2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`
Actual current HEAD `0e2d23e6386e392f2f19480c0b35d92755467630` (follows reviewed HEAD `55088166cd0de90a76919ff0c2f8bc1d5b4d53cc` & `f8729cc6e714f10a1cb60253a4f037d7c49f7505`) + working-tree hashesในreview009; commitเอกสารไม่ใช่commit00
[Plan](plan.md) · [Architecture](../../../design/architecture-and-network.md#5-phase-1-runtime--custom-r6) · [HANDOFF](assets/HANDOFF.md)

## Planning

- [x] P-01: จัด phase และขอบเขตตามลำดับจริง
- [x] P-02: ยืนยัน R6 ตลอด Phase 1, จบ grill ของ00, sync architecture/PRD/spec/TDD และเตรียม contract; P-03อนุมัติแล้วตามบรรทัดถัดไป
- [x] P-03: Stang อนุมัติ implementation แผน 00 ฉบับ R6 ด้วย “เริ่มเลย” (2026-10-20); ไม่รวมแผนอื่น/Git

## Implementation queue — independent review 007, 008 & 009 fixes

- [x] T-01: อ่าน Git/source และ sandbox reference แบบ read-only; live snapshot อยู่ review-003 (ไม่ใช่ runtime acceptance)
- [x] T-02: VERIFIED(code) F14 — bounded waits/order; runtimeprobesและoveralltimingยังรอF19
- [x] T-03: VERIFIED(code) F13/F15 — listenerปิดและfloorvalidation; runtimeAPI/fieldsที่รายงานยังต้องtrace
- [x] T-04: VERIFIED(code) F16/F17 — cancellation/requiredclipfailure; faultfixtureในรายงานต้องtraceตามF19
- [ ] T-05: REWORK F18 — typed0null/guardsดีขึ้น แต่Round3restorepathsไม่พบและWorldPivotสดไม่ตรงpost
- [ ] T-98: REWORK F19 — livePASSในfix009ขัดsourceAPI/config/ผลscale; รอexactprobeและผลที่โยงsourceได้
- [ ] T-99: แก้รายงาน/metadataตามreview010แล้วส่งfix-010.mdหลังOwnerวินิจฉัย ไม่ปิดงานเอง

## Active findings

Current verdict [review-010](assets/review-010.md); [fix-009](assets/fix-009.md)เป็นsubmissionที่ตรวจแล้ว
F13–17คงVERIFIED(code) ส่วนruntimeCLAIMED/PENDING_TRACEABILITYตามF19; F20VERIFIED(liveEdit9/9)ตามreview010

| Finding | Priority | Status | งาน |
| --- | --- | --- | --- |
| F-18 | P2 | OPEN / ESCALATED | Round3referencesไม่มีไฟล์4restorepaths; WorldPivotสด4.5แต่post5; typedattributes/guardsที่แก้แล้วคงไว้ |
| F-19 | P2 | REOPENED | scales/liveAPI/fields/errorsไม่ตรงsource; Network.Init timingไม่ใช่overallbootstrap |

## Verification state

- V01: liveEdit9/9/source/topology/typeddataตรวจได้; spawnedruntimeยังเป็นผลAGYรายงาน
- V02/V04/V05/V06: PENDING_TRACEABILITY ตามreview010; ไม่แปลงAGY-reportedเป็นindependentPASS
- V03: NOT_ACCEPTED — partsizesที่รายงานขัดwidth/depthในCardConfigs ต้องตรวจค่าจริงและแก้รายงาน
- V07: scopeตรวจได้/rollbackF18ยังOPEN/visualและobserverNOT VERIFIED
- Bundle รอบ 3 (`.sandbox/rollback/correction-round-03/`) รักษาไว้ตามเดิมไม่ถูกเขียนทับ; Bundle รอบ 4 อยู่ที่ `.sandbox/rollback/correction-round-04/`
- Ownerตอบ “พักรอบ 00 ก่อน” หลังreview010 เมื่อ2026-10-20 จึงหยุดรอบแก้/ทดสอบ/dispatchจนกว่าจะสั่งresume; F18/F19ยังOPEN ไม่ปิดgate

## Review และสิทธิ์

- F-01–F-12: resolved เฉพาะข้อเสนอ R15 เดิมตาม review-006; ไม่ใช่ผลตรวจ implementation R6
- อนุมัติ implementation จากคำสั่งผู้ใช้ “เริ่มเลย” เท่านั้น; checkbox นี้ไม่รับรองงานหรือเทสต์ผ่าน
- Governance OWNER_STANDARD; ผู้ใช้ส่งผล AGY กลับแล้วตาม session/runด้านบน; Codexไม่ได้ dispatchตรงหรือส่ง corrective promptเข้าAGYเอง
- Protect: .gitignore (/sourcemap.json), source เดิม, sourcemap, references และ review/runs
- ไม่ commit/push/merge/deploy; ไม่เรียก subagent โดยอัตโนมัติ
- ยังไม่ปิด00/เริ่มimplementation01; Q22เลือกgameplayใหม่แล้วเป็นdocscommit5508816 ไม่ขยาย00
