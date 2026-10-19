# 02-transactions — Transactions — ธุรกรรม Cash และไอเทม

- **Phase:** 2; **State:** DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; คำสั่งล่าสุดอนุมัติปรับเอกสารและ commit/push เอกสารเท่านั้น
- **Phase gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **Prerequisites:** [00-match-flow](../00-match-flow/plan.md)
- **Decisions:** [notes](../../phase-01-gameplay-demo/01-cage-physics/notes.md)

## Scope
- ฐานธุรกรรมร่วมสำหรับ Cash/ไอเทม/ownership ของ reward, สุ่มนักเตะ, สุ่มเอฟเฟค, สลายแลกแต้ม และซื้อขาย
- บันทึกรายการ/สถานะ/ต้นเหตุและผลเปลี่ยนแปลงที่ตรวจสอบย้อนกลับได้ โดยประวัติสำเร็จไม่ถูกแก้ย้อนหลังเงียบ ๆ
- ตรวจการโอน Cash/ไอเทมแบบ atomic และป้องกันคำขอซ้ำ/idempotency ไม่หักซ้ำหรือสร้างของซ้ำ
- กรณีคำขอล้มเหลว/หลุดระหว่างรายการต้องไม่เหลือยอดหรือ ownership เปลี่ยนเพียงบางส่วน

## Acceptance / ก่อนลงมือ
- เก็บรายละเอียด schema/API/สิทธิ์เห็นประวัติ/สถานะล้มเหลวและการคืนรายการไว้ grill ก่อน implementation
- ทดสอบรายการสำเร็จ/ล้มเหลว/คำขอซ้ำ/รายการพร้อมกันด้วย source/ref จริงเมื่อถึง Phase 2
- ไม่ถือว่าระบบเทรดเก่าเป็น transaction ทั้งระบบโดยไม่ตรวจขอบเขตและหลักฐาน
- ห้ามเริ่ม implementation ก่อน Phase 1 รวม 09-uat เสร็จครบและผ่าน gate
