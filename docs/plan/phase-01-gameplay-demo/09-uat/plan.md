# 09-uat — UAT — Gameplay Demo

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; คำสั่งล่าสุดอนุมัติปรับเอกสารและ commit/push เอกสารเท่านั้น
- **Phase gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **Prerequisites:** [08-gameplay-ui](../08-gameplay-ui/plan.md)
- **Decisions:** [notes](../01-cage-physics/notes.md)

## Scope
- ตรวจการใช้งานร่วมกันของแผน 00–08 ใน Phase 1 ตาม source/ref ล่าสุด
- scenario เล่นบอล/เลี้ยง/ยิงส่ง/กลางอากาศ -> ดวล -> คืนการควบคุม; โกล -> ฟาวล์ -> ลูกนิ่ง -> เล่นต่อ; อีเวนต์ทั้งสาม -> reset/คืนสภาพ
- ตรวจ input/UI/กล้อง/คัตซีนเฉพาะคู่/สตั้น/การไม่แทรก possession และการซิงก์ผู้เล่น/AI
- ตรวจผ่าน Studio MCP และ visual UAT ที่จำเป็น ไม่รวมระบบที่ยังอยู่ Phase 2

## Acceptance / ก่อนลงมือ
- ครบขอบเขต 00–08 และไม่มี blocking findings ค้างก่อนปิด Phase 1
- ผลตรวจระบุ source/ref, วิธีตรวจ, ผลจริง และสิ่งที่ยังไม่ครบ; ไม่ใช้ APPROVED/ผลทดลองเก่าแทน
- ไม่บังคับ screenshot/video หากไม่มีหลักฐานภาพพอให้ระบุ visual verification incomplete และยังไม่ปิด gate
- sync เอกสารตามผลงานและส่งให้ reviewer ตรวจ; Phase 2 เปิดได้เมื่อ UAT นี้ผ่าน project gate
