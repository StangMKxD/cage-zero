# Review 004 — ข้อเสนอ Bootstrap และ Custom R15 หลังได้รับ live evidence

- วันที่: 2026-10-20 (Asia/Bangkok); Reviewer: Codex
- รายงานที่ตรวจ: `C:\Users\Stang\Downloads\00_bootstrap_and_rig_audit_and_plan (2).md` (444 บรรทัด)
- SHA-256 รายงาน: `FE9680CA1079828F1C58958A9E0A4F9B0B4399DF76ED03FB793FF73BA62986F4`
- Ref ที่ตรวจจริง: `main @ 2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`
- Baseline ของ working tree: `.gitignore` แก้ค้างเดิม; review-001/002/003 ยัง untracked; `git diff --name-only -- src default.project.json` ไม่มี output
- เทียบกับ: review-001/002, live evidence intake review-003 และ snapshot/hash comparison ใน `.sandbox/exports/phase00-readonly-20261020-081e9d76/`
- Verdict: **CHANGES_REQUESTED เฉพาะข้อค้างด้านล่าง — ยังไม่ใช่ implementation approval**
- เป็นการตรวจใหม่ตามรายงานที่ผู้ใช้ส่ง ไม่ dispatch งานแก้/เปิด automatic ping-pong หลัง escalation ไม่แก้แผน/tasks หรืออำนาจอนุมัติแทน Owner
- รอบนี้อ่านไฟล์และตรวจเครื่องมือ/เอกสาร API เท่านั้น เพิ่มเฉพาะรายงาน review ไม่แก้ source หรือเอกสารหลัก ไม่ใช้ Studio ไม่รัน application tests ไม่ commit/push

## ผลตาม Finding IDs เดิม

คำว่า RESOLVED หมายถึงข้อความข้อเสนอแก้ประเด็นเดิมแล้ว ไม่ใช่ยืนยันผล implementation/runtime และไม่ใช่ปิดงานใน project board

| Finding | ผลในข้อเสนอรอบนี้ | เหตุผล/หลักฐานในรายงาน |
| --- | --- | --- |
| F-01 | PARTIAL / OPEN | 217–239, 254–279, 291–320, 346–371: มี pre/post state และ hash guard แล้ว แต่ rollback หลายชั้นยังล้มเหลวจากลำดับตรวจ/ลบและ manifest ลูกไม่ครบ |
| F-02 | RESOLVED IN PROPOSAL | 92–110, 241–277: graph ทั้ง server/client ตัด require/WaitForChild ระบบอื่น ไม่ลบ implementation เดิม; timeout contract ที่เพิ่มใหม่ดู F-11 |
| F-03 | PARTIAL / OPEN + OWNER DECISION PENDING | 35–41, 114–149, 327–364: แยกฐานใหม่/reference, สร้าง rig จาก source และ allowlist ชัดขึ้น; floor selection/fallback ยังไม่แน่นอน และต้องเลือกแนวทาง animation ก่อนล็อก contract |
| F-04 | RESOLVED IN PROPOSAL | 82–90, 151–170, 387/415: คง contracts/meshes และตรวจเฉพาะ No Boots; แยก current-plan corrections จาก deferred cleanup |
| F-05 | RESOLVED IN PROPOSAL | 43–78, 395–420: แยก static/live/inference, เพิ่ม scale round-trip, repeated death, fall, race และ visual incomplete; วิธีวัด joint ที่ยังค้างดู F-08 |
| F-06 | RESOLVED IN PROPOSAL | 9–23: ตารางคืนความหมาย Finding IDs เดิมถูกต้องแล้ว |
| F-07 | RESOLVED IN PROPOSAL | 121–128, 296–301: เริ่ม animation หลัง rig เข้า Workspace และกำหนด character แล้ว ไม่โหลดใน Build |
| F-08 | PARTIAL / OPEN | 389–403, 416–418: เลิกใช้สูตร World-Y ที่ผิดแล้ว แต่ยังไม่กำหนดฝั่งและจังหวะวัด Transform ให้ถูกต้อง |
| F-09 | RESOLVED IN PROPOSAL | 202–245: มี P-02/HANDOFF ก่อน P-03/source พร้อม scope delta และระบุสิทธิ์ Git ชัด คงต้องตรวจเอกสารจริงหลัง Owner อนุญาตให้จัดทำ |

## Findings เดิมที่ยังค้าง

### F-01 [P1] ตรวจ post-state ระหว่างไล่ลบลูก ทำให้ rollback หยุดที่ parent

- หลักฐาน: รายงาน 368–371 กำหนดวน bottom-up แล้วตรวจ `childrenNames` เทียบ post-state ของแต่ละ instance ก่อนคืน/ลบ
- กรณีตามแผนเอง: สร้าง `Server.services.RigAndCardService` ใหม่ เมื่อ rollback ลบ RigAndCardService ก่อน รายชื่อลูกของ services จะว่าง ซึ่งต่างจาก post-state ที่ยังมี RigAndCardService จึงเข้า STOP แม้ไม่มีผู้ใดแก้แทรก
- อีกช่องว่าง: manifest ที่ 347 ระบุพาธในสามกลุ่ม แต่กลุ่ม rig ที่ 343 ระบุเพียง root Model; ไม่มีรายการ snapshot/ownership ของ parts, joints, humanoid, animator, decal และ descendants ทุกตัว ทำให้กฎลบเฉพาะ leaf ที่ 371 คืน subtree นี้ไม่ครบ และตรวจการแก้ property ภายใน rig เดิมไม่ได้
- ต้องแก้เป็นสองช่วง: (1) preflight เทียบทุก target/subtree กับ post-state โดยยังไม่ mutate หากต่างให้หยุดทั้งหมด (2) เมื่อผ่านจึงคืน/lบในลำดับที่กำหนด โดยยอมรับความเปลี่ยนแปลงที่เกิดจาก rollback ของตนเองและตรวจ final pre-state ครบ ต้องบันทึก descendants ที่ขั้นนั้นสร้าง/แก้จริงด้วย ไม่ใช้ root child names เป็นหลักฐานแทนทั้ง subtree
- แก้ branch ที่ 238/279 ให้ตรงนโยบาย hash mismatch: หากกำหนด STOP เมื่อมีการแก้แทรก ห้ามตีความ `git apply --check` ที่ไม่ชนว่าอนุญาตย้อนงานต่อเอง

### F-03 [P2] Floor allowlist และ fallback ยังเลือกผิดวัตถุหรือไม่สิ้นสุดด้วยผลที่กำหนด

- หลักฐาน: 142 รวม BaseParts ที่ Anchored/CanCollide ซึ่งรวมกำแพง/หลังคา/แท่นได้; 147 ยิงจาก World-Y=100 ลง 200; 149 fallback ไป `allowedFloorInstances[1]` โดยยังไม่กำหนด primary floor/order และ 148–149 ไม่มีผลลัพธ์ชัดเมื่อ hit ใกล้ขอบไม่ถึง 2 studs หรือ fallback เองไม่ผ่าน
- ต้องแก้ให้เล็กตามขอบเขตฐานใหม่: หลังอ่าน Place1 เลือกพื้นหนึ่งชิ้น/ชุดที่ยืนยันแล้ว เช่น Baseplate ที่รองรับจุดเกิด หรือ BootstrapTestFloor ที่สร้างในขั้น 5 บันทึกเป็น explicit allowed floor และ primary spawn anchor ไม่กวาดทุก anchored collider หรือเลือก `[1]` ตามลำดับการวน
- กำหนด ray origin/range และ footprint ตาม bounds ของพื้น/rig ที่เลือก; ทุกเส้นทางต้องคืน valid spawn หรือ error ชัดเจนเมื่อไม่มีพื้น/จุดเกิด/ระยะขอบที่ผ่าน ห้ามยอมรับหลังคาหรือ ray miss เป็นจุดเกิด และไม่ต้องสร้างระบบ geometry ทั่วไปเกิน fixture ของแผน 00
- การเสนอพิกัด/ขนาด fixture ใหม่ใน 137–138 ทำได้ในฐานะ design proposal ไม่ใช่ข้อเท็จจริงที่ตรวจแล้ว และต้องอยู่ใน scope ที่ Owner รับทราบ ไม่ต้องมี fixture/rig อยู่ในฐานใหม่ก่อนจึงทำแผนได้
- เรื่อง animation ยังเป็นการตัดสินใจค้างที่ระบุถูกต้องแล้วใน 426–432 ไม่ถือการไม่มี animation ใน reference เป็นบั๊ก แนะนำเริ่มจาก Roblox R15 locomotion มาตรฐานที่ตรวจ provenance/compatibility ได้ แทนเพิ่ม procedural controller ทั้งชุดเพื่อเก็บทุกอย่างใน repo โดยไม่จำเป็น

### F-08 [P2] สมการ joint ดีขึ้น แต่ยังอ้างว่าอ่านได้ถูกเสมอระหว่าง animation

- หลักฐาน: 394/416 ใช้สมการ Transform พร้อม tolerance 1e-3 และอ้างว่าเป็นจริงเสมอทั้ง rest/animated pose; 400/403 ระบุ client movement แต่ไม่ได้ล็อกว่าตรวจ joint continuity/pose บน DataModel ฝั่งใดและจังหวะใด
- เอกสาร Roblox ระบุ `Motor6D.Transform` เป็น NotReplicated และนำไปใช้แบบ batch หลัง PreSimulation ก่อน physics ดังนั้นค่าท่าบน client กับค่าที่อ่านจาก server หรือช่วงก่อน physics ไม่ใช่ snapshot ชุดเดียวกัน การตรวจทันทีหลัง Equip หรืออ่านคนละฝั่งอาจให้ false failure
- ต้องแก้: แยก static BaseC0/BaseC1/scale check จาก dynamic geometry check; ระบุฝั่งที่ evaluate animation, จุดเก็บตัวอย่างหลังการอัปเดต pose/physics ใน frame เดียวกัน และช่วงรอ stabilization ให้ชัด ตรวจ replication ด้วยการสังเกตผลแต่ละฝั่ง ไม่อ้างว่า raw Transform ต้องเท่าข้ามเครือข่าย
- สำหรับ movement probe ให้เลือกหนึ่งลำดับที่ชัดในการพัก/คืน default controls และ cleanup เมื่อ fail/timeout ไม่ใช้เงื่อนไข client หรือ ControlModule ที่ยังคลุมเครือเพื่อให้ผ่านตัวเลข
- แหล่งหลัก: [Motor6D.Transform](https://create.roblox.com/docs/reference/engine/classes/Motor6D#Transform), [Roblox creator-docs source](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/Motor6D.yaml#L101)

## Findings ใหม่

### F-10 [P2] คำสั่ง `diff -u` ไม่ใช่เครื่องมือ diff แบบ Unix ใน PowerShell ปัจจุบัน

- หลักฐานในรายงาน: 227/268/306 สั่ง `diff -u pre/<file> post/<file>` แล้วนำผลไป `git apply -R`
- ผลตรวจเครื่องจริงแบบ read-only: `Get-Command diff -All` พบเพียง Alias `diff → Compare-Object` ไม่ใช่ GNU diff; `git.exe` มีที่ `C:\Program Files\Git\cmd\git.exe`
- ผลกระทบ: AGY ที่ทำตามคำสั่งตรงตัวจะไม่ได้ unified patch ที่ apply กลับได้
- ต้องแก้: เลือก direct comparison ที่มีจริง เช่น `git diff --no-index` ระหว่าง pre/post snapshots ซึ่งไม่ใช่การเทียบ Git index พร้อมระบุ shell, working directory, output encoding, header/path mapping และวิธี check/apply กลับไปยังไฟล์จริงอย่างเจาะจง รับ exit code 1 ของ diff ว่ามีความต่างตามปกติ ไม่ใช่คำสั่งล้มเหลว; ยังคง pre/post hash guard ของ F-01 ห้ามกลับไปใช้ `git diff -- <working files>`

### F-11 [P2] Network Init ระบุ timeout รวม 10 วินาที แต่ให้รอ 10 วินาทีต่อ remote

- หลักฐาน: 109/414 กำหนด client readiness ครบทั้ง 12 remotes ภายใน 10 วินาที; 260 ให้ WaitForChild folder 10 วินาที แล้ววน WaitForChild remote ทีละชื่ออีก 10 วินาที โดยไม่ระบุ assert/type check หลังการรอแต่ละ remote
- ผลกระทบ: เมื่อ remotes ขาดหลายตัว ลูปอาจรอหลายช่วงรวมเกิน 10 วินาที และหากผล nil ถูกข้ามก็อาจคืน Folder ทั้งที่ readiness ไม่ครบ ขัด timeout/error contract ที่แผนระบุเอง
- ต้องแก้: ใช้ deadline รวมเดียวและเวลาคงเหลือเมื่อรอแต่ละ child พร้อมตรวจทุกชื่อ/RemoteEvent หรือ RemoteFunction ตาม Definitions; เมื่อเวลาหมดให้ error บอกชื่อที่ขาดชัดเจน ไม่เปลี่ยน readiness gate เป็นเวลานานขึ้นเพื่อรองรับลูปเดิม

## การตัดสินใจและ prompt ส่งแก้เฉพาะจุด

- สิ่งที่ Owner ยังต้องเลือก: แนวทาง locomotion animation ของหัวข้อ 6 แนะนำตัวเลือก 2 (Roblox R15 มาตรฐาน) โดยตรวจ source/asset references และ compatibility ก่อนล็อก implementation ไม่ถือว่ารายงานนี้ตรวจ asset IDs ทั้งห้าผ่านแล้ว
- แหล่งข้อมูลมาตรฐานสำหรับการออกแบบ: [Roblox — Use animations](https://create.roblox.com/docs/animation/using) ซึ่งอธิบาย Animate และช่อง animation ของแต่ละสถานะ
- ไม่ต้องรื้อข้อเสนอหรือ audit sandbox ซ้ำเพื่อแก้ข้อที่ปิดแล้ว คง F-02/F-04/F-05/F-06/F-07/F-09 ตามผลรอบนี้ และแก้เฉพาะข้อค้าง/ตัวเลือกที่มีผลต่อ contract

ข้อความคัดลอกส่ง Gemini/AGY:

> ปรับข้อเสนอเดิมเฉพาะ F-01, F-03, F-08, F-10 และ F-11 ตาม review-004.md คง Finding IDs และส่วนที่ reviewer ระบุ RESOLVED IN PROPOSAL ไม่ rewrite ทั้งแผน แก้ rollback เป็น preflight ทั้งชุดก่อน restore พร้อม manifest descendants, เปลี่ยน diff command ให้ใช้ได้ใน PowerShell จริง, จำกัด floor/spawn เป็น fixture ที่ระบุชัดพร้อม valid-or-error ทุก branch, ระบุ client/frame sampling ของ joints, และใช้ deadline รวม 10 วินาทีของ Network Init ส่วน animation คง PENDING จน Owner เลือกแนวทาง รอบนี้แก้เฉพาะข้อเสนอที่ส่งกลับ ไม่แก้ source/PRD/TDD/CONTEXT/แผนหลัก ไม่เขียน Studio ไม่รัน Play/tests ไม่ spawn agent ไม่ commit/push และไม่เปลี่ยน approval
