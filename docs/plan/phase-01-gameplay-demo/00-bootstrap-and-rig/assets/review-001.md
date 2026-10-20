# Review 001 — ข้อเสนอ Bootstrap และ Custom R15

- วันที่: 2026-10-20 (Asia/Bangkok); Reviewer: Codex
- เป้าหมาย: ตรวจรายงาน/ข้อเสนอแผนของ Gemini ยังไม่ใช่การตรวจรับ implementation
- รายงานที่ตรวจ: `C:\Users\Stang\Downloads\00_bootstrap_and_rig_audit_and_plan.md`
- SHA-256 ของรายงาน: `D82536218F5557BDD26A3924CCA8951E4FF26485AAA2EE1D08F241B293549CE5`
- Git ref ที่ตรวจจริง: `main @ 2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`
- ฐานก่อนตรวจ: มีเฉพาะ `.gitignore` แก้ค้าง เพิ่ม `/sourcemap.json`; เป็นงานเดิมที่ต้องรักษา
- Verdict ของข้อเสนอ: **CHANGES_REQUESTED — ยังไม่พร้อมใช้เป็น implementation contract**
- ไม่เปลี่ยนสถานะ/approval ของแผน ไม่แก้ source, PRD, TDD, CONTEXT หรือเอกสารควบคุม

## สิ่งที่ยืนยันได้และขอบเขตหลักฐาน

- CONFIRMED: Entrypoints เรียก `Network.Init()` (`src/server/init.server.luau:15`, `src/client/init.client.luau:37`) แต่ `src/shared/Network.luau` ไม่มีฟังก์ชันนี้ มี `InitServer` ที่บรรทัด 146 จริง อย่างไรก็ตามยังไม่ได้รันเพื่อยืนยันลำดับ error แรก เพราะมี require/WaitForChild ก่อนถึงจุดนี้
- CONFIRMED: Server โหลด `MatchService` ก่อน Init (`src/server/init.server.luau:12`); โมดูลนั้น require services อื่นที่ระดับบนสุด (`src/server/services/MatchService.luau:11-19`)
- CONFIRMED: เส้นทาง clone rig ตั้ง attribute ใบหน้า แต่ไม่เรียก `lockAnimeFaceOnHead` และไม่ตรวจ Animator (`src/server/services/RigAndCardService.luau:183-195`); procedural path สร้าง Animator แต่ไม่มี Animate/AnimationTrack ในฟังก์ชัน (`247-260`)
- CONFIRMED: source/config ที่ตรวจไม่ต่างระหว่าง `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182` กับ HEAD ปัจจุบัน: `git diff <old-sha> HEAD --stat -- src default.project.json` ไม่มี output จึงแยก source baseline เดิมออกจาก SHA ที่ตรวจรอบนี้ ไม่ถือว่า baseline เดิมผิดเพียงเพราะไม่ใช่ HEAD
- CONFIRMED (live MCP รอบนี้): `list_roblox_studios` พบ `Place1`, studio ID `a400d378-bf6b-4afb-aa3d-cb0530553486`; `get_studio_state` เป็น Edit / available DataModel Edit
- CONFIRMED (อ่าน properties ผ่าน MCP): `game.Name = Place1`, `game.PlaceId = 0`, `game.GameId = 0`; ไม่พบ direct child `ServerStorage.CageZeroStandardR15Rig` ใน instance นี้ ยังไม่ได้ค้น rig ที่อื่น
- UNKNOWN: instance นี้เป็นไฟล์ local ของเกมเป้าหมายหรือไม่; ยังเทียบกับ place `112091950831355` ใน `docs/design/architecture-and-network.md:7` ไม่ได้ ไม่เขียน Studio หรือเปลี่ยน mode
- UNKNOWN: source/hierarchy ของ Studio เป้าหมาย, template/animation ที่จะเลือกใช้, runtime และ visual readiness ของ rig ไม่รันทดสอบหรือ Play ในรอบนี้
- ข้อดีของรายงาน: เปิดเผยว่าอ่าน archive, ไม่ปลอมผล Studio และรักษา implementation approval เป็น PENDING

## Findings

### F-01 [P1] Rollback คืนทั้งไฟล์จาก HEAD อาจทำลายงานค้างและงานขั้นก่อนหน้า

- หลักฐาน: รายงานบรรทัด 139, 171, 203, 250 ใช้ `git checkout HEAD -- <files>` และสั่งลบ HANDOFF
- ผลกระทบ: ป้องกันเพียง `.gitignore` ไม่พอ หากมีงานเดิมในไฟล์เป้าหมาย หรือคืนขั้น 5 หลังทำขั้น 3–4 จะลบการเปลี่ยนแปลงที่ไม่ใช่ของขั้นนั้นด้วย; การคืน Source อย่างเดียวไม่ครอบคลุม instance/property ที่สร้างใหม่
- ต้องแก้: บันทึก pre-step state ของแต่ละไฟล์/instance รวมการมีอยู่เดิม, Source, class/path และ properties ที่จะเปลี่ยน; คืนเฉพาะส่วนต่างของขั้นนั้น ตรวจว่าไม่มีการแก้แทรกระหว่างทางก่อนคืน หากชนกันให้หยุด ห้ามคืนจาก HEAD หรือลบไฟล์ที่อาจมีอยู่ก่อนโดยอัตโนมัติ

### F-02 [P1] ห้ามเฉพาะ Init ยังไม่ปิด dependency ของ bootstrap

- หลักฐาน: รายงานบรรทัด 159–166 เน้นไม่เรียก Init และใช้ grep ชื่อ services; แต่ `src/client/init.client.luau:11-34` รอ ui/controllers และ require screens/controllers ก่อนถึง `Network.Init()`
- ผลกระทบ: ทำตามแผนแบบตรงตัวแล้วยังอาจรอ child ที่ไม่ได้ sync หรือโหลดโค้ดนอกแผนตั้งแต่ require การไม่มี `.Init()` ไม่พิสูจน์ว่าโมดูลไม่ได้ทำงาน
- ต้องแก้: ระบุ bootstrap ขั้นต่ำทั้ง server/client และ dependency graph ของ top-level require/WaitForChild; ตัดเส้นทางโหลดที่ไม่ใช้จาก entrypoint ของรอบนี้อย่างชัดเจน ไม่ลบ implementation ของระบบอื่น; เลือกแนวทาง Network API เดียวพร้อม error/timeout behavior ไม่เพิ่ม helper ซ้ำโดยไม่มีความจำเป็น เกณฑ์ตรวจต้องครอบคลุมการเข้าถึง dependency ทั้งเส้นทาง

### F-03 [P1] Allowlist การส่งเข้า Studio ยังไม่ครอบคลุม rig/animation และฉากตรวจ

- หลักฐาน: รายงานบรรทัด 179 อนุญาตแก้เฉพาะ RigAndCardService/Constants แต่บรรทัด 185 ยังเสนอทั้ง Animate script และ AnimationTrack; บรรทัด 213–230 ระบุ sync Source เพียง 7 instances โดยไม่กำหนดขั้นสร้าง parent/class เมื่อยังไม่มี
- ผลกระทบ: ยังไม่มีสัญญาว่าจะเก็บ/ส่ง template หรือ Animate source จาก repo อย่างไร, เลือก animation assets ใด และใช้ได้กับ skeleton/สิทธิ์ของ place หรือไม่; ยังไม่ระบุพื้นที่ปลอดภัยและวิธีไม่ให้ prototype เดิมรันแข่งกัน จึงรับรอง movement/animation ตาม acceptance ไม่ได้
- ต้องแก้: หลังอ่าน Studio เป้าหมายแล้ว เลือกของเดิมหนึ่งแนวทาง ระบุ asset/source paths, classes, parents, enabled states, animation references และวิธีเก็บกลับ repo; ระบุการสร้าง/อัปเดต instance ที่ขาดและ rollback ให้ครบ กำหนดฉากกับจุดเกิดจากของจริง และแผนแยก fixture โดยไม่ย้าย/ปิด prototype เอง หากต้องเพิ่มไฟล์/instance ให้เสนอ scope ก่อนลงมือ
- ห้ามใช้ `CFrame.new(0, 5, 0)` หรือเกณฑ์ `Y < -5` เป็นตำแหน่งปลอดภัยที่รับรองแล้ว (รายงาน 187, 199) จนทราบพื้น/จุดเกิดจริง

### F-04 [P2] การ cleanup ข้ามระบบและลบเครื่องแต่งกายเกินข้อกำหนดแผน 00

- หลักฐาน: รายงานบรรทัด 60–61 เสนอจัดการ PARRY constants/remotes; 128 เสนอแก้ Parry/ยิงส่งในเอกสาร แม้ allowlist ของ Spec 03 ที่ 120 จำกัดหัวข้อ 1; 184 เสนอลบ CharacterMesh/ShirtGraphic จาก template
- ผลกระทบ: การไม่เปิดระบบเก่าใน bootstrap ไม่ได้ให้สิทธิ์ลบ contract ที่มี consumers ของแผนอื่น และ No Boots ไม่ได้ให้สิทธิ์ลบส่วนหน้าตา/ชุดทั้งหมด ขัดเจตนาใช้ของเดิมต่อและรักษา backlog ตาม accepted decisions N-19/N-23/N-24
- ต้องแก้: จำกัดเอกสารและ code changes ให้รองรับ bootstrap/rig ที่อนุมัติเท่านั้น ตารางข้อขัดแย้งต้องแยก current-plan correction จาก deferred cleanup; ไม่เปลี่ยน PRD/TDD/CONTEXT/spec ส่วนอื่นหรือ shared contract โดยอัตโนมัติ การเอารองเท้าออกต้องระบุชิ้นที่ตรวจพบและวิธีจำแนกจริง ไม่ลบทั้ง class แทนการตรวจ

### F-05 [P2] บางข้อสรุปยืนยันเกินหลักฐานและเกณฑ์ตรวจยังไม่ครอบคลุมความเสี่ยงที่อ้าง

- หลักฐาน: รายงานตาราง C ยืนยันไม่มีรองเท้า/ป้องกัน avatar แต่ template ยังไม่ถูกอ่าน; ยืนยันตกแมพแล้วเกิดซ้ำ/Connection Leak ทั้งที่ยังไม่มี runtime reproduction; บรรทัด 238–246 ตรวจเพียงสลับสัดส่วนและตายหนึ่งเส้นทาง
- ผลกระทบ: Attributes/constant flags และการพบ Part มาตรฐานไม่พิสูจน์ภาพของ template; การเก็บ connection references เพิ่มใน `RigAndCardService.luau:369-372` เป็นข้อเท็จจริง แต่ไม่ใช่หลักฐานยืนยัน active connection leak; การไม่พบ Animate ในฟังก์ชันหนึ่งยังไม่ตัดเส้นทาง StarterCharacterScripts/ตัวควบคุมอื่นใน Studio
- ต้องแก้: ใช้ CONFIRMED เฉพาะ static facts; ผลเคลื่อนไหว/ภาพ/asset loading และเหตุการณ์ตายเป็น INFERRED/UNKNOWN จนมีหลักฐาน เพิ่มวิธีตรวจแบบจำกัดขอบเขตสำหรับ template ที่เลือกและ fallback หากยังคงรองรับ, สลับ scale ไป–กลับโดยไม่สะสม, ตาย/เกิดซ้ำ, ตกฉาก, delayed respawn ของ character เก่า, client readiness และ animation ที่เล่นจริง ระบุ expected result/timeout/หลักฐานที่จำเป็น ไม่ถือ attribute หรือ grep เป็น functional/visual pass และไม่บังคับ screenshot/video

## ข้อแก้ความเข้าใจเพิ่มเติม

- `agent.md:5` ระบุ dependency 00 อยู่แล้ว การชี้ active 01 ไม่ได้พิสูจน์ว่าข้าม 00; เมื่อเริ่มงาน 00 จริงจึงเสนอ sync router ให้ชัดตามคำสั่งผู้ใช้ โดยไม่ปลอม approval
- Studio PlaceId 0 ไม่พิสูจน์ว่าไฟล์ผิด ต้องเปิดหรือยืนยันไฟล์/place เป้าหมายก่อนทำ target-specific inventory
- คำถามเรื่อง rig/animation source ให้ AGY อ่านของจริงก่อน ถาม Owner เฉพาะตัวเลือกที่เหลือ ไม่ผลักข้อเท็จจริงที่ค้นได้ให้ Owner ตัดสินใจ
- HANDOFF ในอนาคตต้องระบุสิทธิ์ Git ชัด: รอบนี้ไม่มีสิทธิ์ local commit, push, merge หรือ deploy; การส่งแผนใหม่ไม่เปลี่ยนสิทธิ์นั้น

## ส่งแก้ข้อเสนอให้ Gemini/AGY

แก้ข้อเสนอเดิมตาม F-01–F-05 โดยคง Finding IDs และทำตารางตอบว่าปรับตรงไหน ไม่ implement และไม่แก้เอกสารหลักในรอบแก้ข้อเสนอ แยก audit จาก archive ออกจาก live MCP supplement ข้างต้น; ทำ read-only inventory ต่อได้เมื่อระบุ Studio เป้าหมายได้แล้ว จากนั้นเสนอแผนที่มีไฟล์/instance, prerequisite, คำสั่งหรือ action, expected result, stop condition และ pre-step rollback ครบทุกขั้น คง PROPOSED / IMPLEMENTATION PENDING จนมี approval จริง ส่งข้อเสนอที่แก้แล้วให้ Codex ตรวจซ้ำก่อนจัดทำ HANDOFF สำหรับ implementation
