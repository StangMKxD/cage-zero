# PROJECT AGENT STATE & ROUTER

## CURRENT EXECUTION STATE
- **ACTIVE_MODULE**: `00-bootstrap-and-rig`
- **CURRENT_RUN**: `run-01`
- **MODULE_STATUS**: `READY_FOR_REVIEW` (ตัวเลือก: `IN_PROGRESS` | `READY_FOR_REVIEW` | `NEEDS_FIX` | `APPROVED`)

## STRICT OPERATING RULES
1. อ่านเฉพาะไฟล์ใน `docs/plan/<ACTIVE_MODULE>/` และไฟล์สเปกที่อ้างอิงถึงเท่านั้น
2. ห้ามทำข้ามไป Module ถัดไปจนกว่า `MODULE_STATUS` จะเปลี่ยนเป็น `APPROVED` และมีไฟล์ `handoff.md` จาก Codex
3. ห้ามใช้โมเดลอวาตารผู้เล่น, ห้ามทำระบบรองเท้าสตั๊ด, และห้ามให้ Mutated Gear เพิ่มสเตตัสในสนามเด็ดขาด
