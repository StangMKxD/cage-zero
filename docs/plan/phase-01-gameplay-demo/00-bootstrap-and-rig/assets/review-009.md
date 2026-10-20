# Review 009 — fix-008 / Correction Round 3

- **Verdict: CHANGES_REQUESTED / WAITING_TARGET_RUNTIME** — ยังไม่ปิด00 ไม่เปิดimplementation01 ไม่commit/push/merge/deployผลงาน00
- Reviewer Codex / stang-luna; 2026-10-20; ตรวจsource/เอกสาร/ไฟล์หลักฐานและMCPinventoryแบบread-only ไม่รันapplication tests/Play/rollback ไม่แก้โปรแกรม
- Actual reviewed ref: **main HEAD `55088166cd0de90a76919ff0c2f8bc1d5b4d53cc` + working-tree hashesในตารางด้านล่าง**; 5508816/f8729ccเป็นเอกสาร Source00ยังไม่commit
- AGY session `e86ac30e-006d-4338-9a90-5f5e3b002028`; run `run-phase00-agy-impl-01`; correction bundle `.sandbox/rollback/correction-round-03/`
- Intake SHA256 `7F0A022F37FFF9DBFC5B68CB03190C84C35E152F320B8C5121A60065447286A7`; fix-008 SHA256 `8CA3915145270E8AF2024073D98E1376B59D9655E553ED0CA0C840535929C29C`
- Ownerยอมรับhistoricalrun01before-stateเป็น**ACCEPTED_GAP**แล้วตามคำตอบหลังreview008 ไม่มีการยกเลิก/ขออนุมัติช่องว่างเดิมซ้ำ; currentbaseline/guardsก่อนเขียนยังเป็นข้อกำหนดเดิมที่ต้องทำให้ครบ

## ผลต่อ Findings

| Finding | ผลตรวจ |
| --- | --- |
| F-13–F-17 | คง **VERIFIED(code)** ตามreview008; hashesไม่เปลี่ยน ไม่มีผลruntimeใหม่มารับรองแทน |
| F-18 P2 | **OPEN / REWORK** — เส้นทาง/countและไฟล์สำรองดีขึ้น แต่snapshotสูญค่าtypedattributesและก่อนrestoreยังไม่guardStudio source/subtreeครบ |
| F-19 P2 | **VERIFIED(reporting correction)** — fix008ไม่เรียกJSsimulationว่าruntimePASSและระบุV02–V06ยังไม่ตรวจ นี่ไม่ใช่runtime sign-off |
| F-20 P1 | **VERIFIED(recorded readback bundle)** — pre/postscriptbytes/hashครบ9และpostตรงrepo; currentliveconfirmationต้องอ่านใหม่ก่อนruntimeเมื่อtargetกลับมา |

ไม่มีการขยายscopeแก้Choiceใหม่ใน00 Q22/commit5508816เป็นงานเอกสารแยก คำว่า“รอrequirementchoice”ท้ายsubmissionเป็นข้อมูลเก่า ไม่เปลี่ยนสัญญาR6ของ00

## หลักฐานที่ยืนยันได้

[CONFIRMED] manifest.filesystem.filesทั้ง9: currentrepo/pre-files/post-filesตรงsha256ทุกตัว; studio pre/postscriptsทั้ง9ตรงpreStudioHash/postStudioHashจริง โดย4ก่อนsyncตรงreview008 และ4หลังsyncตรงrepo ไม่ใช่เพียงhashlength64หรือเอาrepoก่อนrunมาแทนStudiobefore

[CONFIRMED] baseline/postJSONมีrigroot+17descendants เส้นทางRootJoint/Neck/Shoulders/Hipsถูกแก้ตรงsourceแล้ว historicalrun01ระบุACCEPTED_GAPตามOwner

[CONFIRMED] ณreviewนี้MCPinventoryแสดงเพียงstudio `45d41811-b785-47dc-b9af-40c69911f99d` / reference `sandboxcage-zero` place112091950831355; targetPlace1/137721422246269ไม่อยู่ในรายการ ไม่หยุด/แก้referenceและไม่อนุมานสถานะPlay/crashจากinventoryอย่างเดียว

[CONFIRMED] sourcehashเหมือนfix007/review008 จึงไม่มีsource deltaใหม่ให้ทดสอบแทนAGY; `git diff --check`ผ่าน เป็นการตรวจเอกสาร/workingtreeไม่ใช่application build/test

## F-18 — สิ่งที่ยังไม่ครบและวิธีแก้เฉพาะจุด

### 1. Snapshotเก็บtypedattributesเป็นnull

`pre/studio/studio-baseline.json:50,66–67` และจุดอื่น รวม **19attributes** (BaseSize7 และBaseC0/BaseC1ของ6joints) เป็นnull; post/studio/studio-post.jsonมีอาการเดียวกัน SourceRigAndCardService:156,184–185ตั้งค่าVector3/CFrameเหล่านี้จริง การเทียบnullกับnullไม่พิสูจน์ว่าbase geometryไม่เปลี่ยน และrestoreจากnullทำให้ข้อมูลscaleหาย

snapshotrootpropertiesยังว่าง ไม่บันทึกPrimaryPart; partsมีPositionแต่ไม่มีCFrameครบrotation และHumanoid.AutomaticScalingEnabledไม่ปรากฏ จึงยังไม่ใช่baselineที่รับรองrestoreค่าที่สำคัญของrigครบได้

**แก้:** serializerต้องเก็บtypeและcomponentsของVector3/CFrame และinstance referencesเป็นfullpathที่resolveได้ รวมproperties/attributesที่ใช้ตรวจหรือrestoreในscope ไม่คัดค่าจากR6sourceมาเรียกเป็นhistoricalcapture เก็บsnapshotใหม่เมื่อtargetพร้อมและระบุเวลารอบปัจจุบัน; เก็บไฟล์รอบ3เดิมไว้เป็นประวัติที่มีข้อจำกัด

### 2. Guardsก่อนrestoreยังไม่มีStudio post-state comparison

`manifest.json:272–276` ก่อนrestoreตรวจHEAD/protectedfiles/repo9filesและStudioidentityเท่านั้น ไม่มีguardว่าcurrentStudio scriptsยังตรง**postStudioHash** หรือsubtree paths/classes/children/properties/attributesตรงpost snapshotทั้งหมด

GUARD06ที่manifest:280ตรวจpreStudioHash**หลัง**restore จึงป้องกันการทับsourceที่ผู้ใช้แก้แทรกไม่ได้ และGUARD07ตรวจGitไม่ครอบคลุมStudioinstancechanges

**แก้:** เปรียบเทียบcurrentกับpostของทุกไฟล์และStudioinstancesในชุดที่จะrestoreก่อนmutationครั้งแรก; ข้อใดต่างให้หยุดทั้งชุด รวมguardของไฟล์snapshotเอง ใช้ข้อมูลtypedที่ครบ ไม่ใช้เพียงinstancecount/StudioID

### 3. Round3ไม่ควรลบsceneที่มีอยู่ก่อนsync

`manifest.json:248,258,267` ยังใช้ `delete_subtree_or_restore` / `delete_or_restore` ทั้งที่Round3baselineมีrig/floor/spawnอยู่แล้ว และงานที่รายงานคือsync4sources

**แก้:** ระบุmutationแต่ละขั้นให้แน่นอน ส่วนsceneที่ไม่แก้เป็นpreserve/no-op ห้ามdeleteจากการrollbackRound3 ถ้าแก้จริงจึงมีbefore/afterและrestoreเฉพาะค่าที่ownedและguardผ่าน ไม่ใช้rollbackrunแรกที่Ownerยอมรับgapมาแทนcurrentcorrection ไม่รันrollbackจริงเพื่อสร้างหลักฐาน

F18คงFindingIDเดิม ข้อcount/paths/pre-postfilehashที่แก้แล้วไม่ต้องรื้อใหม่ การแก้guards/serializerเป็นงานที่Ownerอนุญาตให้เก็บbaselineใหม่ก่อนเดินต่ออยู่แล้ว ไม่เป็นคำขอขยายงาน00หรือยกเว้นgateเพิ่ม

## Gate ปัจจุบัน

| Gate | ผล independent review |
| --- | --- |
| V-01 | PARTIAL — archive9/9hashและtopology17ตรวจได้ แต่livecurrenttargetไม่พร้อม และmetadatarestoreยังไม่ครบF18 |
| V-02–V-06 | UNVERIFIED_AT_RUNTIME — ยังต้องAGYรันbootstrapelapsed/scale/pose/lifecycle/floorตามHANDOFF |
| V-07 | Scopeตรวจได้ / rollbackF18ยังไม่ผ่าน / visualและobserverNOT VERIFIED |

การหยุดruntimeในreferenceเป็นการทำตามcontract ไม่ใช่การปิดgateหรือเหตุให้บังคับเปลี่ยนเกณฑ์ การเห็นloadedtrack/stateอย่างเดียวไม่แทนclientPostSimulationpose; ไม่บังคับscreenshot/videoและไม่บังคับlogทุกpass

## Working-tree / recorded post readback lock

| Source | SHA256 (repo = saved postStudio) |
| --- | --- |
| src/shared/Constants.luau | DB9AC36D26C72B73C3248A2FF17CDC8FFB13E6FA947B551D078BB4E4161FD888 |
| src/shared/Types.luau | EE9F02D17420A26974CADF62E1FE9EBC0B95E61EADF9AAA2E7FA47626AD47108 |
| src/shared/Network.luau | 147CEBF912EB7219DF239A0BC98E6A86257A20AE5890CD7B59B75FB8AC9EF8AB |
| src/shared/configs/CardConfigs.luau | E558086E96A167780FEBCC24D8CBADB88EE7C37EA271A2F37DC548C1F3B48662 |
| src/shared/configs/RigAnimationConfigs.luau | FFDA487ED869B544953F148F36D23F027687C7B74D296E2A257571349F2DE2C9 |
| src/server/init.server.luau | 93758403E932664DDD88E9A78EA8175B936F199777494CD11248178931A50E3E |
| src/server/services/RigAndCardService.luau | A6D8D9EA45470B10ED8C77FABBA0E491B04D87EBF470F23DAE47EA04E0DD8CFC |
| src/client/init.client.luau | E1D4C440C98CF84E12A5121F37476A74335E1E794A66C54C86A519754000E2F6 |
| src/client/character/R6AnimationController.luau | 61490D844AB4FF97FDE5A756C7EAC81316AA7E3A95F5D1D9B4622AA62A6587A6 |

## Corrective prompt — ใช้HANDOFFเดิม

อ่านreview009 แก้เฉพาะF18ที่ยังOPEN: typedattribute/propertyserializer, guardStudiopostsource/subtreeทั้งชุดก่อนrestore, sceneที่ไม่เปลี่ยนให้preserve ไม่ทับbundleรอบ3/ไม่กุbeforeย้อนหลัง คงrun01ACCEPTED_GAPตามOwner ไม่รื้อF13–17หรือsyncซ้ำหากreadback9/9ตรงอยู่แล้ว

เมื่อtargetdevelopmentPlace1/137721422246269เปิดและพร้อม ให้list/getstateใหม่ (StudioIDอาจเปลี่ยน) เก็บcurrentbaselineที่อ่านได้จริงแล้วAGYรันV01–07ตามHANDOFF รวมscale4presets3รอบ/clientpose/3deaths/void/race/leave/floor ไม่แตะหรือหยุดreference112091950831355 เก็บผลstatic/scene/runtime/asset/visual/observerแยกจริง

ส่งassets/fix-009.mdหนึ่งไฟล์รวมF18และผลruntime พร้อมsourcehash/target/baselinepathsและnotes/tasksREADY_FOR_REVIEW; ถ้าtargetยังไม่พร้อมให้แก้งานofflineที่ทำได้แล้วระบุpendingเฉพาะruntime ไม่อ้างรับงาน/รันสำเร็จจากprompt ห้ามcommit/push/merge/deploy/spawn/เริ่ม01/ระบบใหม่จากQ22 ไม่มีการขออนุมัติช่องว่างrunแรกซ้ำ

