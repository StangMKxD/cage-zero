# Jog Forward → R15 — Owner รับฟีลคลิปแยกแล้ว

สถานะ **OWNER_VISUAL_ACCEPTED — STANDALONE CLIP** เมื่อ30/10/2026. Ownerยืนยันว่า **“ได้ผ่านนน”** หลังส่งคลิป/GIFแยกให้ตรวจ. การรับฟีลครอบคลุมท่าJog Forward R15ชุดนี้; ล่าสุดOwnerสั่งทดลองกับR15จริงและเลือกJog→Walk/FastRun→Runแล้ว ดู [รายงานเชื่อมล่าสุด](walk-jog-run-fastrun-report-001.md). การรับฟีลคลิปเดิมไม่ใช่การรับรอบเชื่อม/fullgameplayหรือการปิดRF-02. ไม่มีคำสั่งcommit/push/publish

## ไฟล์สำหรับตรวจ

- [GIF ความเร็วต้นฉบับ](../../../../../cage-zero-animation-work/jog-forward/JogForward_R15.gif)
- [GIF ช้าครึ่งหนึ่ง](../../../../../cage-zero-animation-work/jog-forward/JogForward_R15_SlowReview.gif)
- [ภาพรวมจังหวะหลัก](../../../../../cage-zero-animation-work/jog-forward/JogForward_R15_ContactSheet.png)
- [FBX R15](../../../../../cage-zero-animation-work/jog-forward/JogForward_R15.fbx)
- [Blender สำหรับตรวจ/แก้ต่อ](../../../../../cage-zero-animation-work/jog-forward/JogForward_R15_Review.blend)
- [Studio loader/preview](../../../../../cage-zero-animation-work/jog-forward/JogForward_R15_Studio.luau)
- [ข้อมูล keyframes](../../../../../cage-zero-animation-work/jog-forward/jog-r15-keyframes.json)

หมายเหตุเส้นทาง: artifactsอยู่ที่ `C:/Users/Stang/cage-zero/cage-zero-animation-work/jog-forward`. ลิงก์ด้านบนเป็นลิงก์ภายในrepo

## ผลที่ทำ

- ต้นฉบับ `C:/Users/Stang/OneDrive/Desktop/stang/cage-zero-dev/animation-mixamo/Jog Forward.fbx`: FBX7700,65กระดูกMixamo,26เฟรมที่30FPS. Duration **0.833333s**. SHA256 `836ef89582f9382598d0b2edd82f57d3cb8c29dc136a512e45d5637a70c4c2ef`
- นำเข้าจริงใน persistent Blender5.2.3LTS ผ่านMCP; เก็บต้นฉบับและฉากก่อนแก้. ไม่เรียก Blender background/ไม่ปิดแอป
- ส่งออกmeshจริง14ส่วนและjoint15จุดของ `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30` ผ่านStudioAssetService/AnimationConstraint attachments แล้วสร้างR15skin/armatureจากข้อมูลนั้น. ไม่มีbox proxyหรือbodygeometryที่เดาขึ้น
- หัวdynamicเดิมไม่อนุญาตEditableMesh: **เฉพาะBlender/GIFใช้meshหัวมาตรฐานที่มากับRoblox** โดยคงตำแหน่ง/ขนาดหัวและจุดต่อเดิม. สีbodyตามsource; classicShirt/Pants/faceไม่ได้bakeลงภาพGIF. PreviewในStudioคงหัว/เสื้อผ้าจริงจากrigต้นทาง; ไม่แก้appearanceผู้เล่น
- จับคู่Hips→LowerTorso, spineสะสม→UpperTorso, neck/head→Head และแขน/ขาเป็นข้อต่อR15. คงจังหวะก้าว แกว่งแขน เอนตัว และช่วงลอยจากreference; ปรับแกนข้อมือให้ฝ่ามือR15หันเข้าลำตัวและใช้IKปรับช่วงรับน้ำหนักตามความยาวขาจริง
- คลิปเป็นin-place, Loop, Movement priority,15drivenparts. มี26keysรวมclosingkeyซ้ำ; GIFใช้25เฟรมไม่ใส่closingkeyซ้ำ. Curveทั้งหมดBezier; แก้quaternion hemisphere flipsก่อนexport
- แยกเกมคลิป `RF02_JogForwardMixamo_R15_v01` และrig `Workspace.PreviewRigs.JogForward_R15_Review`. มีScriptเฉพาะStudioสำหรับเล่นวนเมื่อกดPlay. คลิปอยู่ในAnimSavesของrigนี้และrigต้นทาง; ไม่เปลี่ยนbinding locomotionเดิม

## หลักฐานตรวจรอบนี้

| ตรวจ | ผล / ขอบเขต |
|---|---|
| Toolchain / authenticity | repository auditและruntimeauditผ่านสำหรับskinned-FBX;15meshผูกกับ16boneรวมroot, อ้างอิงข้อมูลส่งออกStudio. CautionedBlender2.6.3ตรวจhashและregisterแล้ว; **ไม่ได้อ้างว่าCreatorStoreplugintransferทำงาน** เพราะpluginเดิมมีPackageserror |
| Calibration | geometryตามSize/CFrameจริง,1Blenderunit=1stud; nativeR15proportionsคงเดิม |
| Curves |105curves/2730Bezierkeys; ไม่มีLinear/Constant/non-pose/meshanimationcurves. Minadjacentquaterniondot0.96479หลังแก้continuity |
| Loop | endpointlocation/rotation/scale difference0; tangent auditผ่าน |
| Contact | ตรวจLeftFoot8–15/RightFoot1–2และ20–26. Maxdrift0.00000673stud ต่ำกว่า0.02stud. **ตรวจโดยชดเชยvirtualforwardtravel5.6758stud/cycle**; เป็นtreadmill/in-placeaudit ไม่ได้อ้างว่าเท้าin-placeอยู่นิ่งในworld |
| Visual | ตรวจภาพมุมหน้า/ข้างและkeyposes; ดูPNGเรนเดอร์จริงก่อนประกอบGIF. Ownerยืนยันรับฟีลคลิปแยกแล้ว; ไม่ถือmetadataเป็นการรับฟีลแทนOwner |
| GIF | Pillow11.3.0;25frames,512×512,loop0,sharedpalette,disposal2; normal830ms/slow1660ms. เปิดไฟล์กลับตรวจจำนวน/ขนาด/เวลาและframe differencesแล้ว |
| Studio | actualAnimatorบนR15เล่นวน: length0.8333333135,weight1,Movement; serverและclientพบtrackจริง. samplingห่าง0.2sเห็นเท้า/มือ/ลำตัวเปลี่ยนตำแหน่ง. Loaderสร้าง26keys/15partsสำเร็จ |
| Studio capture limit | screenshotในPlayออกมืดมีเฉพาะHUDแม้ชี้กล้องใหม่ จึง **ไม่อ้างว่าภาพPlayในStudioผ่านvisual**. ภาพที่ดูได้จริงคือBlender/native-meshrenders; ข้อมูลtrack/การเคลื่อนมาจากStudioจริง |
| Console / return | ไม่พบerrorจากคลิปใหม่; ยังมีBlenderAnimations Packagesและasset203785492ผิดชนิดเดิม. คืนStudioEditแล้ว; Blenderเปิดreviewfileค้างไว้ |

ผลรายละเอียด: `final-audit.json`, `gif-validation.json`, `fbx-export.json`, `plant-metadata.json` และ`studio-r15/*.json` ในartifactfolder. GIF quantizeเวลาเป็นหน่วย10ms จึง830msเทียบclip833.333ms

## การนำไปใช้ขั้นต่อไป

1. Ownerรับฟีลคลิปแยกที่ส่งตรวจแล้ว; GIFปกติ/แบบช้าและไฟล์ต้นฉบับเก็บไว้สำหรับอ้างอิง
2. ในStudioเลือก `Workspace > PreviewRigs > JogForward_R15_Review` แล้วกดPlayเพื่อดูคลิปแยก; ชื่อclip `RF02_JogForwardMixamo_R15_v01`
3. ล่าสุดเชื่อมJogกับWalkตามคำสั่งOwnerแล้ว; Runใช้FastRun. รอOwnerตรวจรอบเชื่อม ยังไม่ได้เพิ่มDribbleTouchจากคลิปJogนี้
