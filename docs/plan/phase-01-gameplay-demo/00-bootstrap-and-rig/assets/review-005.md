# Review 005 — ข้อเสนอแผน 00 ฉบับหลังแก้ F-01/F-03/F-08/F-10/F-11

- วันที่: 2026-10-20 (Asia/Bangkok); Reviewer: Codex
- รายงาน: `C:\Users\Stang\Downloads\00_bootstrap_and_rig_audit_and_plan (3).md` (599 บรรทัด)
- SHA-256: `36A5AE3AEE2AEA88D25EC373224658E955C3637AF2C5583FEC4F1237C8B0F2F2`
- Ref ที่ตรวจจริง: `main @ 2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`
- ก่อนตรวจ: `.gitignore` แก้ค้างเดิม; review-001..004 untracked; source/config ไม่มี diff
- Verdict: **CHANGES_REQUESTED เฉพาะ F-12 — ข้อค้างเชิงเทคนิคเดิมแก้ครบในระดับข้อเสนอแล้ว**
- Animation choice และ implementation approval ยัง PENDING ไม่ถือผล review ว่าอนุมัติลงมือหรือผ่าน runtime
- ขอบเขต: อ่านเอกสาร/เทียบ source และตรวจคำสั่ง patch บนข้อความที่สร้างขึ้นเฉพาะใน `.sandbox/` ไม่แตะ source จริง ไม่ใช้ Studio ไม่รัน application tests ไม่แก้แผน/tasks/PRD/TDD/CONTEXT ไม่ commit/push

## ผลตาม Finding IDs เดิม

คำว่า RESOLVED IN PROPOSAL ประเมินข้อความที่เสนอเท่านั้น ไม่เปลี่ยนสถานะงานใน project board และยังต้องตรวจ implementation/evidence จริงภายหลัง

| Finding | ผลรอบนี้ | หลักฐานในรายงาน |
| --- | --- | --- |
| F-01 | RESOLVED IN PROPOSAL | 234–269, 468–504: preflight ทั้งชุดก่อน mutate, snapshot ทุก descendant, ไม่ตรวจ parent เทียบ post-state ซ้ำหลังลบลูกเอง และตรวจ final pre-state |
| F-02 | RESOLVED IN PROPOSAL (คงเดิม) | 99–108/125, 339–385: bootstrap graph จำกัด Network/RigAndCardService และไม่ลบโมดูลอื่น |
| F-03 | RESOLVED IN PROPOSAL ด้าน floor/spawn; OWNER DECISION PENDING ด้าน animation | 144–188: primaryFloor ระบุชื่อ, bounds/edge margin, filtered ray และ valid-or-error ทุก branch; 578–585 คงตัวเลือก animation เป็น PENDING |
| F-04 | RESOLVED IN PROPOSAL (คงเดิม) | 87–95, 190–209, 521/565: ไม่ลบ shared contracts หรือห้าม CharacterMesh ทั้งหมด |
| F-05 | RESOLVED IN PROPOSAL (คงเดิม) | แยก static/snapshot/inference/unknown และคง scale/respawn/fall/race/visual checks ในขั้น 6 |
| F-06 | RESOLVED IN PROPOSAL (คงเดิม) | 9–25: Finding IDs และความหมายยังตรงรายงานก่อนหน้า |
| F-07 | RESOLVED IN PROPOSAL (คงเดิม) | 135–142/406–411: parent Workspace/ตั้ง character ก่อนเริ่ม animation |
| F-08 | RESOLVED IN PROPOSAL | 523–553/566–570: แยก static Server checks, same-DataModel PostSimulation samples, stabilization, client probe และ cleanup default controls โดยไม่เทียบ raw Transform ข้าม network |
| F-09 | RESOLVED IN PROPOSAL (คงเดิม) | 297–338: P-02/HANDOFF ก่อน P-03 และ source; คง Git authorization ชัด |
| F-10 | RESOLVED IN PROPOSAL + COMMAND SAMPLE CHECKED | 217–251: git diff --no-index, output encoding, exit 0/1, mapping -p6 และ check/apply ชัด; ผลตรวจข้อความตัวอย่างด้านล่าง |
| F-11 | RESOLVED IN PROPOSAL สำหรับ Network.Init | 109–124/356–360: deadline เดียวรวม folder/remotes และตรวจ class/name; ส่วนขยายไป getter เดิมดู F-12 |

## หลักฐานตรวจคำสั่ง F-10

- ใช้ข้อความ CRLF สองรุ่นที่สร้างใน `.sandbox/` เท่านั้น ไม่ใช้ไฟล์แอป ไม่เป็น application test
- ทำ snapshot ตาม layout `pre/<relPath>`, `post/<relPath>` และสร้าง patch ด้วยคำสั่ง Git/no-index ของข้อเสนอ
- ผลจริง: diff exit `1` (มีความต่าง), reverse-apply `--check -p6` exit `0`, reverse-apply exit `0`, SHA-256 หลังคืนตรง pre-snapshot (`ByteHashRestored=true`)
- ไม่จำเป็นต้องใช้ `--unsafe-paths` ในตัวอย่างที่ตรวจ path mapping ถูกต้อง แนะนำเอา flag นี้ออกจาก recipe และคง path validation/hash guard ตามเดิม
- ผล structured อยู่ `.sandbox/exports/review005-f4806e2d-result.json`; ไม่อ้างว่าตรวจ rollback ของ Studio subtree หรือทุก encoding/ไฟล์จริงผ่านแล้ว

## Finding ใหม่ที่ต้องตัดออกจากข้อเสนอ

### F-12 [P2] ขยายการแก้ timeout ไป public getters ที่ไม่จำเป็นกับ bootstrap และขัดข้อคงเดิม

- หลักฐานรายงานบรรทัด 124 และ 361 สั่งปรับ `Network.GetRemoteEvent` และ `Network.GetRemoteFunction` ฝั่ง Client ให้เปลี่ยนจาก timeout แยกเป็น deadline รวม 10 วินาที; บรรทัด 355 กลับระบุว่าคง getters เดิมไว้ครบ 100% และเป้าหมาย F-11 ที่ 342 คือ deadline ของ `Network.Init()`
- Source จริง `src/shared/Network.luau:170-173` และ `189-192` รอ Folder ได้ถึง 10 วินาที แล้วรอ remote ได้อีกถึง 10 วินาที พร้อม assert ที่มีอยู่ การเปลี่ยนเป็น deadline รวมจะเปลี่ยนพฤติกรรมเวลา error ของ public getters และกระทบ consumers ของแผนอื่น แม้ signature จะเหมือนเดิม
- แผน 00 แก้ F-11 ได้ครบด้วย `Network.Init(timeoutSec)` และ bootstrap budget โดยไม่ต้องเปลี่ยน getters เดิม การเพิ่ม shared-API behavior change นี้ยังไม่มี scope approval แยก และไม่ควรถือการแก้ finding เป็นสิทธิ์ขยายงานเอง
- ต้องแก้เฉพาะข้อความ: ลบวงเล็บท้ายบรรทัด 124 และ bullet บรรทัด 361 ที่สั่งเปลี่ยน getters; ปรับคำอธิบายสรุปบรรทัด 374 ให้เพิ่มเฉพาะ Init/ปรับ bootstrap budget โดยคง public getters เดิม ไม่ต้องเปิดงาน refactor Network หรือเพิ่ม requirement ของระบบอื่น
- หากต้องการเปลี่ยน getters จริงในอนาคต ให้เสนอ contract/scope change พร้อม consumers/verification แยก ไม่บรรจุเป็น prerequisite ของแผน 00

## สิ่งที่ยังต้องตัดสินใจก่อนล็อก HANDOFF

- Owner ยังไม่ได้เลือกแหล่ง locomotion animation ในหัวข้อ 6; คำแนะนำ reviewer ยังคงตัวเลือก 2 (Roblox R15 มาตรฐาน) ไม่ถือว่าอนุมัติหรือว่า candidate asset IDs โหลดได้จริงแล้ว
- เมื่อเลือกแนวทางแล้ว ต้องล็อก path ของ Animate/controller, แหล่ง config/asset references และ verification ให้สอดคล้องกับวิธีที่เลือกก่อนเปิด implementation; ตอนนี้ยังไม่แก้เอกสารหลักหรือจัด implementation contract แทน Owner
- ข้อเสนอฉบับนี้ยังไม่เป็นหลักฐานว่า rig/movement/respawn/visual ผ่าน การอ่านฐานใหม่และ runtime checks ยังเป็นขั้นอนาคตตามสิทธิ์ที่ได้รับ

## Corrective prompt เฉพาะจุด

> แก้ข้อเสนอฉบับ (3) เฉพาะ F-12 ตาม review-005.md: ลบการเปลี่ยน deadline ของ Network.GetRemoteEvent/GetRemoteFunction ที่บรรทัด 124 และ 361 และปรับสรุป 374 ให้คง getters เดิมทั้งหมด ใช้ deadline รวม 10 วินาทีเฉพาะ Network.Init และ bootstrap budget ตาม F-11 คงส่วน F-01–F-11 ที่ reviewer ระบุแก้ครบในข้อเสนอแล้ว ไม่ rewrite แผน และคง Animation Owner Decision / Implementation Approval เป็น PENDING ไม่แก้ source/เอกสารหลัก ไม่เขียน Studio ไม่รัน Play/application tests ไม่ commit/push หรือเรียก agent เพิ่ม
