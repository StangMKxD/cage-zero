# ท่าง้างยิงใหม่ — 30/10/2026

**DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**. Owner ขอให้ง้างเท้าไว้ด้านหลัง ดูทรงตัว ไม่เหมือนจะล้ม ใช้ท่าเดิมเป็นrefด้านkeyframe/smooth. ยังไม่ใช่Owneracceptance; ไม่commit/publish

- แยก `ShotChargeClipData` จากคลิปเตะเดิม. ท่าเดิมหยุดframe0และmaskขาทั้งหมด; ท่าใหม่ดึงขาขวาไปด้านหลัง/พับเข่า82° ขาซ้ายเป็นขารับน้ำหนัก ลำตัวรวมเอนหน้าเพียง6°และหักคอชดเชยให้หน้าตรง
- ใช้arm silhouetteจากShotModel/referenceเดิมโดยจำกัดมุมแขน/บิดตัว และใช้sample timesจากreferenceเดิม. เข้าbackswing0.22sด้วยquintic easing+Cubic keys แล้วค้างที่จุดholdในPreAnimation ไม่หยุดที่frameเตะที่ไม่เหมาะกับการยืนค้าง
- แยกstanding/moving track. Standingควบคุมขารับน้ำหนักและground pose; movingปล่อยpelvis/ขาซ้ายให้locomotionทำงาน และblendขาขวา0.8ให้ยังเห็นง้างด้านหลัง. เปลี่ยนtrackตามการเคลื่อนโดยคงphaseและcrossfade0.12s
- ปล่อยยิงcrossfade0.12sเข้าคลิปเตะเดิม. ไม่เปลี่ยนSourceEnd0.7/Duration0.56, ContactAt0.24/ContactEnd0.29336, แรง/curve/สิทธิ์บอล/ง้างเคลื่อนที่8. คงเตะลมและปุ่มยิงเดิม
- โค้ดเดิมเก็บcommentในShotController/ShotConfigs; ก่อนแก้เก็บbaselineใน `.sandbox/charge-backswing-before`

## ตรวจเฉพาะภาพและsyntax

- Syntaxและexactsync3/3: ShotController, ShotConfigs, ShotChargeClipData. Rojo build `.sandbox/charge-backswing-preview.rbxlx` และdiff whitespaceผ่าน
- ตรวจrigจริง: normalizedR15มี15AnimationConstraints; FKsnapshotใช้Attachment0/1จริง ไม่ได้วาดdummyใหม่. ดูภาพสามจังหวะ0/0.11/0.22sผ่านscreen_captureแล้ว ลำตัวมั่นคงขึ้นและเท้าไปด้านหลัง
- FKfootZสัมพันธ์root: -0.064→0.935→1.341stud (บวกคือด้านหลัง); holdfootY1.718เทียบcanonicalroot4.183. posesupportGroundคุมเท้าซ้าย; ไม่ย้ายrootเกมจริง
- Playคีย์จริงคลิกซ้ายค้าง/ปล่อย และW+คลิกซ้ายค้าง/ปล่อย: standinghold59frames, movinghold60frames; ทั้งสองtrackเล่นจริง. RenderedrightfootZค้างด้านหลังช่วง1.288–1.378stud. พบreleaseanimation65framesรวมสองรอบ. เป็นsmoke/telemetry ไม่ใช่การรับฟีลของOwnerหรือfulltechnicalQA
- ConsoleมีเฉพาะBlenderAnimations Packages/asset203785492เดิม ไม่พบerrorจากsourceที่แก้. หยุดPlayกลับEdit

เก็บคลิปใหม่2ชุดใน `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves` ชื่อ `RF02_ShotChargeBackswing_R15_v02` และ `RF02_ShotChargeBackswingMoving_R15_v02`. ภาพposeสามจังหวะย้ายเก็บที่ `ServerStorage.ShotChargePosePreview_20261030` หลังตรวจแล้ว ไม่วางค้างในสนาม

Studio Cage-Zero137721422246269 sessiondd80e2b6-cc00-48a2-b435-4c35da7ca276. รอOwnerลองยืนง้าง/เดินง้าง/ปล่อยยิงและการต่อท่าจริงก่อนtechnicalละเอียด; checklistข้อ9ยังไม่ผ่าน
