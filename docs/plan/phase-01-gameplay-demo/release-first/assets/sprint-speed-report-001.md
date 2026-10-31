# Sprint ตามจำนวนปุ่มและมุมเลี้ยว — 30/10/2026

สถานะ **DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**. Owner ยืนยันปุ่มเดียวเร็วสุด32 และเวลาลดความเร็ว0.7วินาทีแล้วคืนแบบsmooth. แทนกติกา forward28.8/ข้างหลัง25.92ของ smooth-turn-report001 เฉพาะส่วนความเร็ว. ไม่ commit/push/publish/ปิดงาน

## กติกาปัจจุบันเมื่อกด Shift

| Input / การเปลี่ยนทิศ | Server speed cap |
|---|---|
| กด W/A/S/D ปุ่มเดียวค้าง | 32 |
| WA/WD/SA/SD ค้าง | 28.8 |
| เปลี่ยนทิศ45–90° เช่น W→D โดยปล่อยปุ่มเดิมก่อน | 28.8นาน0.7วินาที แล้วไต่กลับ32เมื่อเหลือปุ่มเดียว |
| เปลี่ยนทิศ135–180° เช่น W→SA/SD/S | 25.92นาน0.7วินาที แล้วไต่กลับ32สำหรับปุ่มเดียว หรือ28.8สำหรับเฉียง |

- จำทิศก่อนหน้าข้ามช่วงปล่อยปุ่มสั้น ๆ ไม่เกิน0.3วินาที (ค่าเริ่มจูน). หยุดนานกว่านี้เริ่มทิศใหม่โดยไม่มีโทษค้าง
- เก็บทิศเริ่มเลี้ยวในหน้าต่างลดความเร็ว เพื่อให้ W→SD ที่ส่งผ่านคีย์กลาง WD/D ยังนับ135°. การส่ง intentซ้ำทิศเดิมไม่ยืดเวลา และทิศย่อยไม่ล้างโทษหักกลับ
- คืนความเร็ว32stud/sต่อวินาทีหลังพ้นช่วงลด (ค่าเริ่มจูน). ไม่ล็อคทิศ/ไม่คิวinput/ไม่คืนท่าcut
- Server เลือกตัวเลขจาก configและกติกาเอง; clientส่งแกนforward/lateral {-1,0,1}จริง. ลบการคูณ turn-speed dip ซ้ำเฉพาะตอน sprint; ยังคงเดิน/การชะลอจากบอลติดสิ่งกีดขวาง
- คง G/charge8, airborne sprint reset, jump momentum/yaw/lean, animationและระบบบอลเดิม. โค้ดที่แทนจากรอบก่อนเก็บcommentตามคำสั่ง Owner; baseline4ไฟล์รอบนี้สำรองเพิ่มใน `.sandbox/sprint-turn-before`

ไฟล์หลัก: SprintConfigs, SprintSpeedRules, SprintService, SprintController, MovementHeadingPreviewController. สคริปต์ syncและhash manifestเพิ่ม SprintSpeedRules แล้ว

## ตรวจเฉพาะขอบเขตนี้

อัปเดต holdล่าสุด0.7s: config syntax/readbackตรง, freshกติกา34assertions/0failedที่hold0.7และbuildผ่าน. คงkey-up memory0.3sและความเร็ว/อัตราคืนเดิม. หยุดPlayที่Ownerเปิดอยู่เพื่อsync; คืนEditพร้อมลองรอบถัดไป. ไม่ได้รันkeyboard traceใหม่สำหรับ0.7s; trace0.3sด้านล่างเป็นหลักฐานรอบก่อนปรับเวลา

- Studio syntax5/5และ baselineก่อนsyncตรง5/5; readbackตรง5/5. SprintSpeedRulesรุ่นเพิ่มจำทิศเริ่มเลี้ยว compile/readbackซ้ำตรง
- เทสต์ `tests/animation/SprintSpeed.spec.luau`: **34 assertions /0 failed** บน fresh config+rules cloneใน Studio. ครอบคลุม4cardinals/4diagonals,90°/135°/180°, key-up gap, hold0.3/recovery, long hold, repeated intent, staged SD และ invalid axes
- Rojo build `.sandbox/sprint-turn-speed-preview.rbxlx` ผ่าน; `git diff --check` ผ่าน. ไม่ใช่ full typecheck/regression
- คีย์จริง MCP W→D→W→S→SD: Server WalkSpeed32→28.8→32→28.8→32→25.92→32→28.8. ไม่กด W/D พร้อมกันในช่วงเปลี่ยน W→D. บันทึก `.sandbox/sprint-turn-speed-trace.json`
- คง28.8ก่อนเฟรมเริ่มคืนประมาณ0.317s; คง25.92ประมาณ0.332s (sampled frames); configกำหนด0.3s แล้วคืนทีละเฟรม. เห็นขั้นคืน29.346/29.859ฯลฯและ26.430/27.004ฯลฯ. วัดเป็น WalkSpeedฝั่งserver ไม่ใช่ความเร็วเดินทางจริงทุกสถานการณ์
- Actual traceข้างบนก่อนเพิ่มการจำทิศเริ่มเลี้ยวสำหรับ staged SD; รุ่นสุดท้ายตรวจกติกาเสริมนั้นด้วยเทสต์34ข้อสดใหม่. ตัวเลข/hold/recoveryของเคส traceไม่ได้เปลี่ยน
- Consoleมีเฉพาะ BlenderAnimations Packages/asset203785492ผิดชนิดเดิม; ไม่พบ errorจากsourceที่แก้ในsmoke. หยุดPlayและคืนEditแล้ว

Studio Cage-Zero137721422246269 session dd80e2b6-cc00-48a2-b435-4c35da7ca276. รอ Ownerลองฟีลความเร็ว/การคืนตัว; checklistข้อ7ยังไม่ผ่าน. ไม่ตรวจtechnicalชุดใหญ่ก่อน Ownerรับฟีล
