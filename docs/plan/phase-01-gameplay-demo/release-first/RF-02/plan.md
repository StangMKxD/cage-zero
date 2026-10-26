# RF-02 — Core football & R15 foundation

2026-10-26 · Owner Stang · Planner/Reviewer Codex · Implementer ยังไม่มอบหมาย (ยกเว้นข้อ7ตาม ACK สด) · OWNER_STANDARD

## ขอบเขตปัจจุบัน

ตัวละคร/5คลิป/กล้อง/Shift sprint; รับและเลี้ยงบอล; ส่งยิงปั่น+วอลเลย์พื้นฐาน; Dash/Stamina. ข้อ7รับเลี้ยงบอลและOwner deltaกระโดดสูง/โมเมนตัม/เอน4ทิศ+แก้locomotionที่เกี่ยวข้องอนุมัติให้ลงมือขณะนี้; งานอื่นตาม gate.

งาน T01–T04 ใน [Master Plan](../plan.md) และสถานะจาก [single live board](../RF-02/tasks.md). อ่าน [design](../assets/street-football-design.md) สำหรับสัญญา/Config/ผลกระทบ/เกณฑ์ตรวจรับ. เป้าหมายงานละ1วันเพื่อเห็นฟีเจอร์ครบเส้นทาง ไม่รับประกันระยะเวลาหรือผ่อน gate.

## หลักฐานและสิทธิ์

Owner Q1–Q9 + คำสั่งจัดแผน/commitเอกสาร/เริ่มเฉพาะเลี้ยงรับบอล2026-10-26. การวางแผนไม่อนุมัติโค้ดงานถัดไปอัตโนมัติ. ไม่ commit/push/publish source จนมีสิทธิ์แยก. แผน00/01และ findings เก่าไม่ปิดเอง.

## ตรวจรับ

ต้องมีผลลัพธ์ที่เล่นได้จริง/configจูนได้/negative tests/actual multi-client evidenceเมื่อเกี่ยวข้อง/rollbackและsource parity/Owner feel. NOT RUN ไม่เท่ากับPASS. ข้อกำหนดฟีเจอร์และdependencyใน Master เป็นเกณฑ์หลัก.

## ประวัติ

[แผนก่อนเปลี่ยน Street Football](../assets/plans-before-street-20261026/RF-02--plan.md) เก็บไว้ครบ; สิ่งขัด targetใหม่เป็น historical ไม่ใช่คิวลงมือ.
