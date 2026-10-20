# Review 006 — ตรวจแก้ F-12 และคำสั่ง apply

- วันที่: 2026-10-20 (Asia/Bangkok); Reviewer: Codex
- รายงานที่ตรวจ: `C:\Users\Stang\Downloads\00_bootstrap_and_rig_audit_and_plan (4).md` (599 บรรทัด)
- SHA-256: `A2A7C8B724789E2DC21784B80510D6137FF6BD5C23D7EB3A97ABAA78466DC384`
- เทียบกับฉบับ (3): SHA-256 `36A5AE3AEE2AEA88D25EC373224658E955C3637AF2C5583FEC4F1237C8B0F2F2` และ review-005
- Git ref จริง: `main @ 2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`
- Working tree ก่อนตรวจ: `.gitignore` แก้ค้างเดิม; review-001..005 ยัง untracked; source/config ไม่มี diff
- Verdict: **F-12 แก้ครบในข้อเสนอ; ไม่พบ blocking technical finding เพิ่มจาก diff รอบนี้**
- Findings F-01–F-12 มีผล RESOLVED IN PROPOSAL ในส่วนเชิงเทคนิคเท่านั้น; การเลือก animation, การอนุมัติแผน/HANDOFF และ implementation ยังไม่ถูกอนุมัติจากรายงานนี้
- รอบนี้เพิ่มเฉพาะรายงาน review อ่านและเปรียบเทียบเอกสาร ไม่แก้ source/แผนหลัก/PRD/TDD/CONTEXT ไม่ใช้ Studio ไม่รัน application tests หรือ commit/push

## ผลตรวจเฉพาะข้อที่ส่งแก้

| รายการ | ผลตรวจ | หลักฐานฉบับ (4) |
| --- | --- | --- |
| F-12: ไม่เปลี่ยน public getters | RESOLVED IN PROPOSAL | 125 คืนเฉพาะ folder; 356 คง getters เดิม; 357–361 เพิ่ม deadline ภายใน Init โดยไม่มีคำสั่งเปลี่ยน getters; 374 ระบุชัดว่าคง InitServer/GetRemoteEvent/GetRemoteFunction/Validators 100% |
| F-10: ถอด unsafe-paths | คำแนะนำถูกนำไปใช้ครบในคำสั่ง | ตรวจรูปแบบ `apply --unsafe-paths` ได้ 0 จุด; คำสั่งยังคง -p6, check/reverse apply และ hash guard |
| F-01–F-11 ที่แก้ครบก่อนหน้า | คงผล RESOLVED IN PROPOSAL | เปรียบเทียบ diff กับฉบับ (3) ไม่พบการเปลี่ยนลอจิก bootstrap, rig, floor/spawn, two-phase rollback หรือ runtime verification นอกเหนือจาก F-12/การถอด flag |
| Scope/approval | คงเดิม | 7 และ 595–599 ยังเป็น PROPOSED / IMPLEMENTATION_APPROVAL PENDING / ANIMATION_OWNER_DECISION PENDING |

วิธีตรวจ: `git -c core.autocrlf=false diff --no-index --unified=0 -- <report3> <report4>`; exit 1 หมายถึงพบความต่างตามปกติ ตรวจ hunks ของเนื้อหาและคำสั่งแล้ว ไม่ใช่ผล build/test ของเกม และไม่ต้องรัน command sample F-10 ซ้ำเพราะการถอด flag ตรงกับ specimen ที่ตรวจไว้ใน review-005 แล้ว

## หมายเหตุเอกสารก่อนย้ายเข้า repository (ไม่เปิด blocking technical finding ใหม่)

- ลิงก์ GitHub/Roblox หลายจุดถูกเปลี่ยนจาก direct URL เป็น `google.com/search?q=...` เช่น 3, 59, 80, 528, 583 ควรคืน URL ปลายทางตรงจากฉบับ (3) เมื่อ sync เอกสาร ไม่จำเป็นต้องรื้อข้อเสนออีกฉบับเพียงเพื่อแก้ลิงก์
- บรรทัด 6 ระบุว่า context ZIP เดิมมี review-005 ด้วย แต่ ZIP ที่ Codex จัดมี review-001..004 เท่านั้น (ยืนยันจากการจัดชุดและ manifest) จึงควรแยกที่มาว่า context ZIP เดิม + review-005 ที่นำมาใช้เพิ่มภายหลัง ไม่แก้ประวัติแพ็กเกจย้อนหลัง
- การระบุ Drive upload เป็นข้อมูลที่ผู้ใช้ส่งมา รอบนี้ตรวจไฟล์ local ที่ระบุเท่านั้น ไม่อ้างว่ายืนยันเนื้อหาหรือสิทธิ์บน Google Drive แล้ว

## ขั้นต่อไปที่ยังต้องได้รับคำสั่ง

- เลือกแนวทาง locomotion animation ในหัวข้อ 6; reviewer ยังคงแนะนำตัวเลือก 2 (R15 มาตรฐาน) แต่ไม่บันทึกว่าผู้ใช้เลือกแล้ว และไม่อ้างว่า candidate asset IDs ผ่าน compatibility แล้ว
- หลังตกลงแนวทางและได้รับคำสั่งเตรียมแผน/สัญญา ให้ทำ P-02 และตรวจ scope/spec delta เฉพาะแผน 00 ก่อนจัด HANDOFF ที่ระบุไฟล์/instances/verification/Git authorization ให้ครบ
- ยังไม่เปิด P-03 หรือเขียน source/Studio จากการส่งรายงานนี้; runtime/visual acceptance คง NOT VERIFIED จนมีงานและหลักฐานจริง

ไม่ต้องส่งข้อเสนอวนแก้เชิงเทคนิคต่อจาก F-12 แล้ว การแก้ลิงก์/ที่มารายงานทำพร้อม doc sync ที่ได้รับอนุญาตได้ โดยคงข้อกำหนดและ approval gates เดิม
