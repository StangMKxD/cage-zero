# Smooth turn / ถอดล็อคบอล — 30/10/2026

สถานะ **DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**. Owner สั่งเริ่มต่อจากโน้ตเมื่อคืนและสั่งเพิ่มให้เก็บโค้ดเก่าเป็น comment. ยังไม่ใช่ Owner acceptance หรือ technical sign-off; ไม่ commit/push/publish.

## ผลที่เปลี่ยน

- ไม่มี cut commitment, บังคับจบท่า, จำทิศ cut หรือคิวกระโดดผูกกับ cut แล้ว. WASD/กล้องเลี้ยวต่อเนื่อง รับทิศล่าสุด ไม่มี one-shot cut มาคั่นท่าวิ่ง
- ถอดทางเรียก client/helper/server cut intents และ ball guide เฉพาะ cut; touch markers ของการเลี้ยงปกติยังใช้ทางเดิม
- โค้ดเก่าที่แทนออกเก็บเป็น block comment ท้ายไฟล์ตาม Owner. DribbleCutController, DribbleCutTimeline และ SprintCutReferenceData ยังคงไฟล์ไว้เป็น comment ทั้งหมด ไม่มี runtime caller
- ท่า cut/sole-drag เดิม 6 คลิปย้ายจาก AnimSaves ไป `ServerStorage.BeforeLockRemoval_20261030.RetiredFromAnimSaves`; เก็บคลิปสำรองก่อนย้ายด้วย
- ท่าเลี้ยวต่อกับ run gait โดยใช้ visual root joint owner เดิมใน AirMovementController เฉพาะ grounded branch. ไม่เพิ่มผู้เขียน joint อีกตัว; airborne yaw/momentum/4-way lean เดิมคงอยู่
- ค่าเริ่มจูน `GroundTurnConfigs`: response45ms, facing20rad/s, rollสูงสุด9°, pitchสูงสุด3°. Roll อิงทั้งทิศที่ต้องการและอัตราการหมุนตัว มี smooth fade; ไม่ขวาง input หรือรอจบท่า
- Server กำหนด Sprint W/WA/WD = **28.8**; A/D/S/SA/SD = **25.92**. ค่าหลังเป็นค่าเริ่มจูนตามข้อเสนอ ไม่ใช่ Owner ยืนยันตัวเลข. Client ส่ง forward intent จริงแทนค่า1ตลอด และอัปเดตเมื่อเปลี่ยนกลุ่มทิศ
- คง G speed8/distance1.95/separation1.85, ยิง54–128, ง้างเคลื่อนที่8, เตะลม และ jump/landing ชุดล่าสุด. พารามิเตอร์ setup บอลยิงเดิม9.5/28ย้ายชื่อจาก cut config ไป ShotConfigs เพื่อไม่ผูกกับระบบที่เลิกใช้

## Backup ก่อนแก้

`C:/Users/Stang/OneDrive/Desktop/stang/cage-zero-dev/backups/cage-zero-before-lock-removal-20261030.zip`

SHA256: `D0353295ED36F6EF1CE91D702FB46EF0D32AFE396AEAEDDF970C953E06788DB1`

รวม source/config/tests/docs/สคริปต์ sync ก่อนแก้, HEAD290726b, working-tree.patch และ scene keyframes/poses/markers ครบ6คลิปใน `pre-smooth-turn-20261030/scene-cut-sequences.json`. อ่าน ZIP ได้518รายการ; JSON scene parse ได้6คลิป; ปลายทาง hash ตรงต้นฉบับ. Export ก้อนแรกถูกเครื่องมือตัดข้อความ จึงดึงใหม่เป็น25ส่วนและแทนใน ZIP ก่อนย้าย scene; hashด้านบนคือ archiveฉบับครบเท่านั้น. ไม่ใช่ full-place backup; สนาม/rigเดิมไม่ได้แก้

## ตรวจจริงเฉพาะรอบนี้

| รายการ | ผล / ขอบเขต |
|---|---|
| Studio syntax compile ด้วย loadstring ไม่ execute | 17/17ไฟล์ที่เปลี่ยนผ่าน; lean2ไฟล์ที่จูนท้าย compile ซ้ำผ่าน |
| ตรวจ source ก่อน sync | 17/17ตรง baselineก่อนแก้ ป้องกัน sync ทับงานอื่น |
| Studio source readback | 17/17ตรงดิสก์; lean2ไฟล์ท้าย readbackตรงอีกครั้ง |
| Fresh module load | 10/10สำเร็จ; BallService ต้อง cloneไว้ใต้ servicesเพื่อให้ sibling dependenciesถูกต้อง |
| Active clip definitions | 8รายการ (7loop+shot), ไม่มี cut/sole-drag one-shot |
| Rojo build | `rojo build default.project.json -o .sandbox/smooth-turn-owner-preview.rbxlx` ผ่าน |
| Actual keyboard smoke | Server WalkSpeed W+Shift28.799999; A+Shift25.920000, Running/IsSprinting=true. รอบแรกทดสอบAหลังชนขอบสนามได้16 จึงย้าย playerกลับกลางสนามใน Playแล้ววัดซ้ำ |
| Ground turn visual telemetry | จูนท้าย actual W→WD→D→W peak roll4.7638°. เป็น telemetry ไม่แทนการดูภาพของ Owner |
| Console | ไม่พบ errorจาก sourceที่แก้ระหว่าง smoke; ยังมี BlenderAnimations Packages และ asset203785492ผิดชนิดเดิม ไม่ได้แก้ในงานนี้ |
| Diff whitespace | `git diff --check` ผ่าน; ไม่ใช่ Luau typecheck/full regression |

Studio target: Cage-Zero137721422246269, session `dd80e2b6-cc00-48a2-b435-4c35da7ca276`. เริ่มและหยุด Playผ่าน MCP; ส่งคืน Edit. ไม่รันชุด cutเดิมเพื่ออ้างว่าพฤติกรรมใหม่ผ่าน และไม่ตรวจ technicalใหญ่ก่อน Ownerรับฟีล

## Owner ลองต่อ

- W/WA/WDกับShift, สลับA/D/Sและย้อนทิศเร็ว ๆ: เห็นการเอนพอเหมาะ เลี้ยวต่อได้ ไม่ติดท่า/กระโดดคิวเดิม
- ลองครองบอลระหว่างเลี้ยว และลอง G/ง้างยิง/กระโดดดูการต่อท่า. การรับ/แย่ง/ชนผนังและ authority/regressionรายละเอียดรอหลังรับฟีล
- ปรับค่าใน GroundTurnConfigs และ SprintConfigs ได้ตามฟีลที่ Ownerเลือก. Checklistข้อ7ยังไม่ผ่านจน Ownerตรวจเอง
