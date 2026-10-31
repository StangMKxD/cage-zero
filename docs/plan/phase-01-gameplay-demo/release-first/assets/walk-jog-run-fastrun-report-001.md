# R15 ตัวละครจริง: Walk = Jog Forward / Run = FastRun

สถานะ **DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**. OwnerอนุญาตทดลองกับR15จริงแล้วเลือกให้JogForwardเป็นWalkและFastRunเป็นRun. ยังรอOwnerรับฟีลรอบเชื่อมจริง; ไม่commit/push/publish

## การเชื่อมล่าสุด

| State ของตัวละครตัวเปล่า | คลิป | Keys / duration |
|---|---|---|
| Walk | RF02_JogForwardMixamo_R15_v01 | 26 /0.833333s |
| Run /กดShift | RF02_FastRunMixamo_R15_v01 | 17 /0.533333s |

- ใช้Jogที่Ownerรับฟีลแล้ว และFastRunที่มีอยู่จริงในAnimSaves. FastRunอ่านCFrames/markersจากคลิปนั้นโดยตรง ไม่ทับหรือretargetต้นฉบับใหม่
- เพิ่มJogForwardClipData/FastRunClipDataเป็นimmutableStudiofallback; HelperเลือกตามWalk/Runและตรวจspecก่อนลงAnimatorจริง. ไม่พึ่งว่าคลิปในฉากจะถูกแก้ภายหลังหรือไม่
- แก้เฉพาะ4ไฟล์: `src/client/character/JogForwardClipData.luau`, `FastRunClipData.luau`, `R15LocomotionHelper.luau`, `src/shared/configs/R15LocomotionConfigs.luau`. ค่าเดิน/วิ่ง ความเร็ว/turn0.7s และชุดเลี้ยงบอล/G/ยิง/jumpเดิมคงเดิม
- binding/resolverเก่าเก็บcomment. Backupก่อนทดลอง: `.sandbox/jog-live-before` และก่อนเลือกWalkJog/RunFast: `.sandbox/walk-jog-run-fast-before`
- อัปเดตsyncgenerator/hashpayloadให้มีทั้ง2data modules และใช้long-stringdelimiterที่ไม่ชนJSONซ้อนในmodule

## ตรวจบนตัวละครผู้เล่นจริงผ่าน MCP

- Rigเป็นR15/15AnimationConstraintsจริง. เทียบAttachment0/1กับrigต้นทาง: แกนหมุนต่าง0°ทุกjoint;สะโพก/เข่า/ข้อเท้าและแขนตรงกัน. ต่างเฉพาะตำแหน่งคอประมาณ0.005978stud. ข้อมูลนี้ไม่พิสูจน์สาเหตุของเส้นกระดูกที่ดูต่างในMotionTools
- Syntax/exactReadbackผ่านทั้ง4ไฟล์ใน2รอบsync; buildclipเทียบspec: Walk26keys/Run17keys,Loopและ15drivenparts
- actualW→Shift+W→ปล่อยShift→หยุด บนตัวละครผู้เล่น: Walktracklength0.8333333135,Runtrack0.5333333611;ทั้งคู่Movement/Loop/speed1 และmaxweight1. บันทึก24walkframes/18runframes,carrierframes0
- หลักฐาน: `cage-zero-animation-work/jog-forward/walk-jog-run-fastrun-runtime.json`. ใช้serverScriptชั่วคราวเฉพาะPlayเพื่อจัดตัวละคร/บอลแยกกันสำหรับทดสอบตัวเปล่า; Scriptและstateนั้นหายเมื่อStop ไม่เพิ่มsetupลงเกม
- Rojo build `.sandbox/jog-walk-fast-run-trial.rbxlx` และdiffwhitespaceผ่าน. ไม่ใช่fullregression/Ownerfeelacceptance
- ConsoleมีPackageserrorจากBlenderAnimationsและasset203785492เดิม; ไม่พบerrorจากการเปลี่ยนWalk/Run. หยุดPlayคืนEditแล้ว

Studio target Cage-Zero137721422246269 session5744491e-5633-4f29-948b-147b6494d005. เป็นการทดลองกับผู้เล่นจริงในStudio; ยังไม่มีpublishedanimationIDหรือการpublishplace

## Owner ลองต่อ

กดPlay แล้วลองเดินตัวเปล่าและกดShiftวิ่ง/ปล่อยShiftกลับเดิน. หากกำลังครองบอลให้ยิงปล่อยบอลก่อน เพื่อเห็นชุดWalk/Runปกติ; ขณะครองบอลระบบใช้ชุดWalkDribble/RunDribbleแยก. ตรวจแนวเข่า/เท้า/แขนและการต่อท่า แล้วแจ้งผลให้ปรับต่อ
