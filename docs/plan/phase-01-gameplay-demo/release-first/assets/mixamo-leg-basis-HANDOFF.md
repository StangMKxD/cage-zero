# RF02-MIXAMO-LEG-BASIS — งานต่อหลัง Jog v02 ผ่าน

2026-10-30 · Governance OWNER_STANDARD · Controller Codex w2:p52 · Base SHA 290726b6f1560c61500694ab3038e720371f1f12 + dirty working tree ต้องรักษาทั้งหมด

Owner รับ Jog v02 แล้วด้วยคำว่า “ได้แล้วสั่งงานเลย ทำกับอนิเมชั่นที่ยังขาด”. การรับนี้ครอบคลุมตัวอย่างแก้แกนขา Jog เท่านั้น ไม่ปิด RF02 หรือรับรองคลิปอื่นทั้งหมด

## การส่งมอบ

task_status=READY_FOR_REVIEW; report_delivery=ACKED; owner_visual=ACCEPTED_GIF_ONLY

ได้รับ REPORT READY_FOR_REVIEW พร้อม [รายงาน001](mixamo-leg-basis-report-001.md) และ Owner ยืนยันผ่านเฉพาะที่ดูจาก GIF. ไม่ถือว่าตรวจ native Studio/ตัวละครจริงหรือ technical signoff แล้ว ไม่อนุญาต runtime binding เพิ่ม/commit/publish จากการรับ GIF นี้

ส่ง TASK_HANDOFF ผ่าน direct Herdr prompt แล้ว ข้อความเข้าบทสนทนาและช่อง prompt ว่าง. ได้รับ TASK_ACK task_id=RF02-MIXAMO-LEG-BASIS role=implementer status=STARTING_EXECUTION พร้อม ROLE_ACK/การยืนยันรักษา src และประสานงานย่อยแล้ว

Owner ยืนยันแล้วว่าเป็น pane agy w2:p5K. ผู้รับตอบ ROLE_ACK implementer สำหรับ task นี้พร้อม return route w2:p52 และ READY_FOR_HANDOFF ใน terminal; ยืนยันประสานงานย่อยระงับ rollback src แล้ว ตรวจสดพบ done และ normal prompt ก่อนส่ง contract

ประวัติ preflight: ชื่อ agyuimplementer ไม่อยู่ registry แต่ Owner ยืนยัน agy w2:p5K คือผู้รับ. ข้อความ rollback src จากงานเก่าถูกยกเลิกตาม preservation boundary แล้วโดยคำตอบผู้รับ; ไม่ถือเป็นหลักฐาน audit ทุกไฟล์. Return route Codex w2:p52 ต้อง resolve สดก่อนรายงาน ไม่ส่งซ้ำถ้าหลักฐานรับข้อความไม่ชัดเจน

## ขอบเขตที่อนุญาต

1. ตรวจ inventory ต้นฉบับ C:/Users/Stang/OneDrive/Desktop/stang/cage-zero-dev/animation-mixamo เทียบ artifact ที่มีแล้ว ห้ามนับแค่มี GIF ว่าผ่านการแก้แกนขา
2. เริ่ม Fast Run ซึ่งยังเป็น v01 แล้วตรวจ/แก้รายการที่ยังขาด correction: Scissor Kick, Soccer Pass, Soccer Tackle, Soccer Trip, Standing Idle 02, Standing Jump, Strike Foward Jog, TurnBackRunning. Jog Forward ใช้ v02 ที่ Owner รับแล้วเป็น reference; ไม่สร้างซ้ำ/ไม่แก้กลับ
3. มี artifact goalkeeper อีกห้าชุดใน working tree แต่ไม่อยู่ไฟล์ FBX ชั้นบนที่ตรวจพบรอบนี้: ตรวจ source manifest/งานเดิมก่อน รวมในงานนี้เฉพาะเมื่อยืนยันว่าเป็นชุด Mixamo เดิมของ session; ห้ามแต่ง source หรือสร้าง gameplay เพิ่ม
4. Ownership: cage-zero-animation-work/scripts/ ตัวแปลงที่เกี่ยวข้อง, โฟลเดอร์คลิปข้างต้น, isolated preview assets/manifest/report ใหม่. Controller ถือ tasks.md และ owner-checklist.md; Implementer ส่งผลผ่านรายงานใหม่ ไม่เขียนทับ checklist
5. อนุญาตนำเข้าพรีวิว R15 จริงใน Studio AnimSaves และ Motion Tools แบบชื่อ version ใหม่ ตรวจ source/rig/session ก่อน; รักษา draft และ scene เดิม ใช้ writer เดียวกับ Blender/Studio. ยังไม่เปลี่ยน binding ตัวละครจริงของคลิปอื่น
6. ห้ามแก้/restore/reset/clean/delete src/ หรือ dirty files ใด ๆ เพื่อทำให้การทดสอบสะอาด. JogForwardClipData, FastRunClipData, R15LocomotionHelper และ R15LocomotionConfigs เป็นงานที่ Owner สั่ง ไม่ใช่ไฟล์แปลกปลอม. ไม่ commit/push/publish ไม่เปลี่ยน input/ball/speed/physics/rig dimensions; โค้ดเก่าเก็บ comment และ backup

## สาเหตุและวิธีแก้ที่ยืนยันจากตัวอย่าง

FastRun retarget_fast_run.py:54 ชดเชย source_rest → target_rest เฉพาะ torso/head/foot แต่ขาใช้ global rotation ตรง ๆ ที่บรรทัด68. Source/target bind ขายาวชี้ใกล้กัน แต่ front axis ของ femur/calf กลับด้านใกล้180° ทำให้ mesh เข่า/น่องหันผิด แม้ปลายกระดูกตรงแล้ว. ไม่ใช่ขนาด rig หรือ local translation ที่ยืดขา

Reference: cage-zero-animation-work/jog-forward/fix_leg_roll.cjs:17–22 และ review_legfix_v02.py. ใช้ joint frames จริงจาก jog-forward/studio-r15/rig.json; FK Wchild=Wparent*A0*P*inverse(A1). แก้ half-turn รอบเส้นแกนขาจริง (Hip A1→Knee A0, Knee A1→Ankle A0) เฉพาะสี่ part ที่พิสูจน์ว่ากลับด้าน; เก็บ pivot ทั้งสองข้างเดิม เก็บ feet world matrices เดิม แล้วหา local pose ใหม่ inverse(A0)*inverse(WparentFixed)*WchildFixed*A1. ต้องชดเชย local feet ตาม parent ด้วย

แก้ basis ให้ถูกตั้งแต่ retarget และ IK orientation stage เพื่อไม่ให้ IK เขียนทับคืน. ใช้ full affine inverse ไม่สมมติ transpose เท่ากับ inverse ของ float matrix. ห้ามพลิก Euler180 ทุกคลิปแบบเหมารวม ห้าม apply correction ซ้ำถ้ามี metadata. ไม่ clamp มุม/เปลี่ยน timing/บิด rig เพื่อซ่อนปัญหา

## หลักฐาน Jog และเกณฑ์ตรวจรับงานต่อ

- Jog native regression เดิม RED ด้วย --before (front axis กลับด้าน) และ GREEN หลังแก้; 26keys /0.833333s unchanged. ดู leg-roll-regression.json
- max pivot difference 2.64133e-8 stud; max foot matrix difference 2.17129e-8; upper body unchanged; max non-root local translation 7.62759e-6 stud
- ตัวอย่างภาพ: Jog_LegFix_Before.png / Jog_LegFix_After.png; GIF JogForward_R15_LegFix_v02.gif; แยก scene JogForward_LegBasisFix_v02.blend. ไม่ overwrite active FastRun Blender file
- แต่ละคลิป: บันทึก source SHA256 ก่อน/หลัง, วินิจฉัย bind basis, key count/duration/loop/priority, geometry/pivot/foot preservation และ quaternion continuity. สำหรับ loop ตรวจ seam/contact โดยชดเชย virtual travel; one-shot ไม่บังคับปิด loop
- ตรวจ syntax/build เฉพาะที่เกี่ยวข้อง และเล่น actual R15 preview ผ่าน MCP พร้อม normal/slow GIF. แยก numerical/visual evidence; ไม่เรียกแค่ import success ว่า visual pass
- ส่ง inventory: ALREADY_CORRECT / FIXED_READY_FOR_OWNER / BLOCKED พร้อมชื่อ asset/ไฟล์/หลักฐาน. เก็บ v01 ไม่ทับชุดที่ Owner รับแล้ว. รายงาน READY_FOR_REVIEW ให้ Controller; Owner ตรวจแต่ละชุดก่อนเชื่อม runtime เพิ่ม

## ข้อความนำส่งเมื่อยืนยันตัวรับแล้ว

ROLE_ACK implementer และ return route ต้องครบก่อน: อ่าน AGENTS.md ที่มีจริง, docs/READ.md และใบงานนี้ ลงมือ RF02-MIXAMO-LEG-BASIS ตาม scope เท่านั้น Owner รับ Jog v02 แล้ว ให้เริ่ม FastRun และทำ correction/preview ของรายการที่ยังขาด รักษา dirty src ทั้งหมด ห้าม rollback Git baseline ไม่ commit/publish ส่งรายงานใหม่พร้อมรายการจริงและผลตรวจกลับ Codex w2:p52 หลัง resolve route สด
