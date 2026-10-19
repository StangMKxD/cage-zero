# Cage Zero — จุดเริ่มอ่านเอกสาร

- กติกาและ router: [agent.md](../agent.md)
- [Roadmap](plan/roadmap.md) ใช้เลขแผนภายในแต่ละ phase โดยตรง
- [Phase 1 — Gameplay Demo](plan/phase-01-gameplay-demo/plan.md): โฟลเดอร์แผน 00–09 รวม UAT อยู่ภายใน phase นี้จริง
- [Phase 2 — Full Game](plan/phase-02-full-match-and-progression/plan.md): โฟลเดอร์แผน 00–08 รวม transaction และ full UAT รอ Phase 1 เสร็จครบ
- เริ่มตรวจ [00-bootstrap-and-rig](plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md) แล้วเตรียม [01-cage-physics](plan/phase-01-gameplay-demo/01-cage-physics/plan.md) ทีละแผน
- แผนปัจจุบัน: [tasks](plan/phase-01-gameplay-demo/01-cage-physics/tasks.md), [accepted decisions](plan/phase-01-gameplay-demo/01-cage-physics/notes.md), [draft contract](plan/phase-01-gameplay-demo/01-cage-physics/assets/HANDOFF.md)
- [Architecture](design/architecture-and-network.md), [PRD](prd/product-requirements.md), [spec สนาม](specs/spec-01-cage-and-events.md), [TDD เดิม](tdd/master-test-cases.md): ก่อน implement ต้อง sync ส่วนที่ขัดกับ accepted decisions ไม่คัดกติกาเก่าที่ถูกตัดกลับมา

Source หลักอยู่ src/ และใช้ Studio MCP; prototype/reference อยู่ .sandbox/ ที่ gitignore และไม่ใช่ source หรือ spec ที่อนุมัติอัตโนมัติ ผลทดลองก่อนหน้าคงใน .sandbox/plan1/implementation-attempt/

รายงานเก่าถูกย้ายตามโฟลเดอร์เพื่อรักษาประวัติ ชื่อ/เลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับใหม่
