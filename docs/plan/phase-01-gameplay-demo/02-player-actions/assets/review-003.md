# Review 003 — Argon R6 Football Animation Pack / Plan 02 adaptation

- Date: 2026-10-22 Asia/Bangkok; Reviewer: Codex / stang-luna.
- **Verdict: DESIGN_REFERENCE_ONLY / CHANGES_REQUESTED_FOR_RUNTIME_ADOPTION.** มีข้อมูลพอใช้เป็นต้นแบบแก้แอนิเมชัน02 แต่ห้ามติดตั้ง PosePlayer ทั้งไฟล์หรือถือว่า Live Play/visual ผ่านแล้ว
- Actual reviewed ref: main HEAD `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + dirty working tree; source lock ด้านล่าง ไม่ใช่ HEAD อย่างเดียว
- Incoming ZIP: `C:\Users\Stang\Downloads\Roblox_R6_Football_Animation_Pack-20261022T055539Z-1-001.zip`
- ZIP SHA-256: `c82ef41b057e2a1a0675fd9b2771670a428f3f5720254cee13a8676177b46d49`.
- Inputs: ZIP 28 entries (23 PNG, 2 Luau, README, animation-spec, prompt); agent/READ/plan/tasks/HANDOFF02; Spec02/PRD/TDD/architecture; current source and relevant Git doc diffs.
- วิธีตรวจ: อ่านแพ็ก/source แบบ static, ตรวจภาพทั้ง23ผ่าน contact sheets และภาพ rig/A11/A12/A17 เต็ม, parse literal pose tables โดยไม่ execute Luau, คำนวณ FK/OBB/reference contact ใหม่ด้วย independent mathematical model.
- ไม่รัน packaged Luau, application tests, Studio Play, require, scene mutation หรือ commit/push/merge/deploy. ไม่มี full six-dimension sign-off ของ implementation fix-003 หรือ findings เก่าในรอบนี้
- Evidence: [argon-r6-static-review.json](evidence/argon-r6-static-review.json). Script/model ไม่ใช่ Roblox engine และไม่พิสูจน์ native interpolation/smoothing/actual ground/real character/runtime parity.

## สิ่งที่ตรวจได้ / ข้อจำกัด

[CONFIRMED] ครบ A01–A18, variants A15 finesse/trivela, A16 ground/lob และ A18 hit/miss; ภาพใช้ rigid R6 ไม่มีข้อศอก/เข่าเพิ่ม ขนาดและ rest frames ตรงฐาน rig00 Scale1; มี hold-phase สำหรับ A12/A14 และสูตร conjugation ของ Motor6D ที่รักษาแกน Part0.
[CONFIRMED: independent calculation] 104 stored keyframes รวม base/variant มี OBB minima ตรงค่าที่อ้างภายใน0.003stud; reference contact point error สูงสุด0.000811stud. นี่คือ authored reference geometry ที่ HRP height ตามแต่ละเฟรม ไม่ใช่ engine/runtime result.
[UNKNOWN] ความต่อเนื่องจริง/น้ำหนักท่า/ความสนุก/input→server→pose/remote observers/cleanupและvisual acceptance ในStudio. ทุก gate runtime ของรอบนี้ NOT RUN.
[CONFIRMED] user รอบนี้เลือก redesign visual ใหม่/realistic fast football, ค้างท่าง้างไม่สับขา; designใหม่แทนแหล่ง visual แบบเดิมได้เฉพาะท่า02 ส่วน gameplay/camera/ball/rig contractเดิมคงไว้ตาม HANDOFF§8.

## Findings ใหม่ — คง F-ID เก่าทั้งหมด

### F-25 — P1 / OPEN: keyframe clearance ไม่รับรองการ blend ระหว่างเฟรม
**พิกัด ZIP:** Data A11:1026–1140, A17:1862–1945, A18:1947–2166; Player:117–157,509–518.
แต่ละ stored pose พ้นพื้นไม่ได้แปลว่าระหว่าง interpolationพ้นพื้น README/specอ้างไม่มีเฟรมทะลุพื้นโดยไม่มี native runtime evidence. Independent model ที่201samples/profile (linear Transform translation + shortest-path SO(3) rotation, linear reference-HRP height, ไม่ใช้ smoothing) พบ A11 t=.935 LeftLeg minY=-.43978; A17 t=.18 LeftLeg=-.38473; A18 miss t=.24 RightLeg=-.42462stud รวมถึงท่าอื่นในevidence.
**ส่งแก้:** AGYยืนยันด้วย native CFrame evaluation บนR6จริง แล้วแก้ in-between/support/root visual trajectory หรือเพิ่มkeyframeเฉพาะที่จำเป็น ตรวจfinal blended outputทั้งเข้า/ออก/variants/actual floor/scale; ไม่ยกHRP/เปลี่ยนphysicsหรือanchorเพื่อซ่อนข้อผิดพลาด. ค่าข้างบนเป็น static model counterexamples ไม่ใช่ engine measurement.

### F-26 — P1 / OPEN: A05/A16 ที่ Player เล่นไม่ใช่ชุด geometry ในภาพ
**พิกัด ZIP:** Player:361–429; Data A05:484–585, A16:1622–1860.
A05เมื่อมีmoveDirectionLocalจะทิ้งauthoredkeyframesและใช้synthPoseอีกชุด independent FKของสูตรนี้ที่phase0/HRP3/directionsettledให้right-strafe minY=-.223653และleft-strafe=-.252314 ไม่ใช่ค่าclearanceในภาพ. A16ยังblendground/lobและlerpทุกjointเข้าหาidentityด้วยpowerScale=.65+.35power ทำให้rootclearance/support/contactเปลี่ยนจากภาพ แม้variantground/power.6ที่ภาพแสดงก็ถูกคูณ.86ตอนplay.
**ส่งแก้:** เลือกrepresentationเดียวให้ภาพ/data/runtimeตรงกันจริง; ตรวจ8ทิศ+เปลี่ยนทิศ+หยุด และpassหลายมุม/แรงโดยคงroot/support correction ไม่ย่อbodyposeทั้งตัวอย่างไร้constraint. ชื่อlobเป็นvisualvariantของPassเดิมเท่านั้น ไม่คืนaction/remote/keyแยก.

### F-27 — P1 / OPEN: Stop/cancel ไม่เป็น terminal และ auto-next ปลุกท่ากลับมาได้
**พิกัด ZIP:** Player:252–288,306–329,444–499,535–556.
Stop(fade>0)ตั้งtargetweight0แต่ไม่หยุดtimeline/auto-nextหรือclearactiveเมื่อfadeจบ; Stopระหว่างA04หรือA17แล้วถึงปลายจะPlay A03/A18ซึ่งตั้งweightกลับ1. Stop(0)คืนTransformแต่connectionยังเขียนidentity; Animate/ownershipคืนเฉพาะDestroy และไม่มีcharacter-generation lifecycleของเกมรองรับ.
**ส่งแก้:** explicit playback/cancel/fade/terminalstate + action/generationtoken; auto-nextต้องใช้ได้เฉพาะactionที่ยังvalid คืนownership/restอย่างกำหนดได้เมื่อจบ/cancel/reject/death/respawn ไม่คืนcachedC0ทับscale/characterใหม่. ทดสอบผ่านpubliclifecycleของcontrollerที่adaptแล้ว ไม่ติดตั้งpreviewStopCompetingTracksบนplayerจริง.

### F-28 — P1 / OPEN: airborne/landing และ HRP reference ยังไม่มี adapter เข้าสถานะจริง
**พิกัด ZIP:** Data:597 และ A06/A08–A11 hrpRefY; Player:348–440,454–463. Current InputController:124–133; R6ActionPoseController:264–397.
StateAirborne mapvyด้วยreference38/clamp.08–.98 โดยไม่มีactualLandedtransitionและไม่ใช้nextAnimOnComplete=A07ของA06. hrpRefY/worldcontactในdataเป็นmetadata ไม่ถูกใช้ในPlayer ดังนั้นท่าที่วาดที่HRP4.15ไม่ได้รับประกันclearance/contactเมื่อเริ่มที่heightอื่น. README previewPlay(A11)ไม่ได้ทำphysicaljump.
**ส่งแก้:** ใช้actualtakeoff/up/apex/down/landedและพื้นใต้เท้าของcharacterปัจจุบัน ไม่worldYfallback/อ้างduration.72เป็นflighttime ไม่แก้jumpvelocityเพื่อเข้าภาพ. A11ลงพื้นตามจริงไม่ลุกกลางอากาศ/ไม่teleportroot; หากไม่มีข้อมูลพอให้รายงานexactadaptergap ไม่เพิ่มservercontractเอง.

### F-29 — P1 / OPEN: proposed contact timing/style ต้องผูก resolved action ก่อนใช้กับบอลจริง
**พิกัด ZIP:** Data A13:1224–1228,A15:1386–1390,A16:1626–1630,A17:1866–1870; Player:290–302,348–518.
**พิกัด repo:** InputController:117–180,651; BallService:184–191,639–730; HANDOFF§7.3.
contactPhase/contactworldpointเป็นmetadata Playerไม่ผูกserveroutcomeและsmoothingยังเปลี่ยนเวลาที่poseถึงcontact. เช่นA13 .42*.28=.1176s และA17duration.55ต่างจากgameplayslide.44. Clientปัจจุบันtriggerจากrequestedactionในขณะที่serverอาจresolveเป็นHeader/Volley/style/footอีกแบบ.
**ส่งแก้:** mapภาพ→profile→serverresolvedaction/sequence/intent/generation; ใช้ResolvedKickFoot/ResolvedCurveStyleตามข้อมูลจริง รวมการmirrorเท้าซ้ายอย่างถูกspace. retime/phasealignกับการปล่อยบอลจริงโดยไม่เพิ่มphysicalwindupdelay/เปลี่ยนSlideCDหรือcost. กำหนดposewriterเดียวภายใต้R6controllerเดิม ห้ามให้importedTransformplayerรันแข่งกับcurrentC0writer/defaulttracks.

### F-30 — P2 / OPEN: Walk cadence ยังไม่แก้ foot sliding ตามความเร็ว20
**พิกัด ZIP:** animation-spec:204–217; Player:450–453; DataA02:220–311.
specคำนวณgeometrycycle4.86stud/.48s≈10.13stud/s แต่reference20; playbackSpeed=MoveSpeed/20ยังคงratioผิดเดิม ไม่มีfootplantlockingในPlayer. ไม่ถือการคูณspeedแล้วจบว่าเท้าไม่ไถล.
**ส่งแก้:** จูนstride/cadence/supporttrajectoryกับความเร็วจริง คงWalk20/Sprint32และR6schema ตรวจและรายงานfoot-slipจริง โดยไม่เปลี่ยนmovementbalanceเพื่อชดเชยภาพ. ความรู้สึกสุดท้ายรอOwnerดูในLivePlay.

## Scope/document integrity

- baselineมีข้อขัดแย้งเดิม: notes02 N14:306–313 และ InputController:164–173 ทำshot-whiff/slowdown แต่ plan02:38/Spec02:59ยังdeferfirst-time-shot/passwhiffไปPhase2. ZIP18ท่านี้ไม่เพิ่มshotwhiff. บันทึกเป็นbaselineconflictเท่านั้น ไม่ใช้รายงานAGYเป็นapprovalใหม่ และไม่ลบ/ขยายscopeผ่านงานanimationนี้เงียบๆ.
- OwnerdeltaในnotesN13ระบุVolley/Bicycleแล้วแต่HANDOFFเก่ายังเว้นscissorบางข้อความ; §8ล็อกเฉพาะvisual A10/A11จากชุดที่userส่ง ไม่เพิ่มstandinglaunch/jumpimpulse/ballisticsจากspecแพ็ก.
- เอกสารกลางที่ต้องsyncให้เปลี่ยนเฉพาะแหล่งvisual/acceptanceของ02ที่ได้รับคำสั่งนี้ ห้ามเพิ่มspec/planอื่นหรือแก้historicalreview/fixให้เป็นpass. baselinePRD/TDDdiffที่มีอยู่ไม่ถือว่าเป็นงานรอบนี้ทั้งหมด.
- F-13..18/F-20..24จากreview002และข้อเก่าที่รอreviewคงสถานะเดิม ไม่ปิดจากผลpackmathหรือAGYclaims. F-21เป็นงานvisualintegrationเดิมที่sourcevisualเปลี่ยนตามOwner ไม่สร้างfindingซ้ำ.

## Current source lock — ก่อน AGY รับรอบนี้

| File | SHA-256 |
| --- | --- |
| PlayerActionPoseConfigs.luau | f41e9b782e800cb4e2ed465bd06e8a2d227a2f79f0271ee3804ce216b5bc4acb |
| R6ActionPoseController.luau | 798c592783a40159fe11f0ec2efbcad94be022f97317264effcb413aecbdfdf3c |
| R6AnimationController.luau | 70daebfe80b3b36127aa338b91f2177f9209fc24127c4c3f71932031c27ca0e2 |
| RigAnimationConfigs.luau | 89037f778d11da301ea66936e9f3684032221c95cb4761c2b6201b1a17bebd25 |
| InputController.luau | 03daff87b7f1f7230fc089a886aa2d8e721945005fdbE46ad8d8246db9d9790a |
| BallService.luau (read-only in this delta) | 7e109383afc9fd9d260e8bc4624ae29c2d801a89af7274dda3e7f5d70c05704a |
| Types.luau (read-only in this delta) | 8341ba0ae2a34785ee33838e5a4483b3fe417f71ea3915926f7f301734593747 |
| Constants.luau (read-only in this delta) | 90dbd499918ad8e7997d823d114c0dd9ecc82f20763ef2b8e5fad91e583d4013 |
| tests/e2e/Tier1_PlayerActions.luau | 277d78b6eb41ed65241d8fa9753ca52efd08a1b9f92611b76587462868720595 |

IncomingDataSHA `2f53441cff05ddc150ff3f1496787823735254bd3604b4b4efccdfd0fa0d2dfa`; PlayerSHA `15d58d328617aeaf00013703930a8e2c09b7de0e08e742f6850172aac206e91d`; SpecSHA `1b114ac64a649826bcbac0c35cc9b44979cea9c2cac2829b00af9315a22e9123`.
ส่งแก้ตามHANDOFF§8; AGYส่งfix-004ใหม่ (fix-003มีอยู่แล้วและไม่เขียนย้อนหลัง). currenthashต้องตรวจใหม่ก่อนลงมือและก่อนส่งreview.

