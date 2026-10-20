# Review 010 — fix-009 / Correction Round 4

- **Verdict: ESCALATED / CHANGES_REQUIRED** — ยังไม่รับรองผ่าน00 ไม่เริ่มimplementation01 และไม่มีcommit/push/merge/deployผลงาน00ในรอบreviewนี้
- Reviewer Codex / stang-luna; 2026-10-20; ตรวจไฟล์/Source/StudioEditแบบread-only ไม่กดPlay ไม่requiregame modules ไม่รันapplicationtestsหรือrollback ไม่แก้source
- Actual ref: **main HEAD `0e2d23e6386e392f2f19480c0b35d92755467630` + working-tree source lockด้านล่าง**; HEADเป็นเอกสารเกมเพลย์/อีเวนต์ไม่ใช่source00
- AGYsession `e86ac30e-006d-4338-9a90-5f5e3b002028`; source run `run-phase00-agy-impl-01`; correction-round-04
- รายงานfix009 SHA256 **3C27C5EA07642A9828651A9429C4DAFC667A63B97A8727A11BF97C715ED76089** และmanifest SHA256 **A5E6994B89AF7F3421C5892483C2CAC407AB36D5C87CAB42BD5DD220C305DBE9** ตรงที่ผู้ใช้ระบุ
- Targetที่ตรวจจริง: Studio `43e07a67-a9c4-4837-b3cf-54cf2f827937`, Place4, PlaceId137721422246269/GameId10772059094, **Edit**

## ผลที่ตรวจยืนยันได้

[CONFIRMED] Live source readback9/9ตรงrepoและpostStudioHash ทั้งclass/Enabledที่อ่านตรงschema Sourceไม่เปลี่ยนจากreview008–009 จึงคงผลF13–17 **VERIFIED(code)** และF20 **VERIFIED(live readback)**

[CONFIRMED] ตรวจhash45รายการ: repo9 + pre/postfile18 + pre/postStudio scripts18 ตรงmanifestทุกตัว Snapshotpre/postsha256ตรง **94E673CB8F46352511DAC6E5FFA935B524723E0DA3BB80BCE9DCCD1E39229118** และไม่พบnulltokenในtypedSnapshot

[CONFIRMED] 19BaseSize/BaseC0/BaseC1attributesมีtype/componentsจริง CFrame12components/InstancefullPath/PrimaryPart/AutomaticScalingEnabledบันทึกแล้ว Rigมี17descendants และsceneที่ไม่แก้มีpreserveพร้อมpre-restorepost-stateguardsตามที่ขอ ส่วนนี้ของF18แก้ดีขึ้นแล้ว

[CONFIRMED] sceneอ่านสด31รายการ (rigroot+17descendants/fixtures3/scripts9): paths/classes/childsets/attributes/propertiesที่เทียบตรงsnapshot ยกเว้น**WorldPivot**ที่ระบุด้านล่าง

หลักฐานread-onlyของreviewอยู่ `.sandbox/exports/phase00-review010/live-sources.json` และ `live-scene-corrected.json` ฉบับแรก `live-scene.json` ของตัวอ่านReviewerมีการแปลงfalseผิดและไม่ใช้ตัดสิน ฉบับcorrectedอ่านfalseตรงแล้ว ไม่มีการเปลี่ยนStudioจากการแก้ตัวอ่าน

## Findings

| Finding | Priority | สถานะ |
| --- | --- | --- |
| F13–17 | ตามเดิม | VERIFIED(code); runtimeใหม่ยังต้องtraceตามF19 |
| F18 | P2 | OPEN / ESCALATED — referencerollbackRound3ไม่พบไฟล์ และcurrentpostsceneมีWorldPivotไม่ตรง |
| F19 | P2 | REOPENED — รายงานlivePASSหลายกรณีไม่ตรงAPI/ข้อมูล/configของsourceที่lockไว้ |
| F20 | P1เดิม | VERIFIED — liveEdit source9/9ตรงrepo |

คงFindingIDsเดิม ไม่มีsourcebugใหม่ที่พิสูจน์จากruntimeในรอบนี้ ข้อที่ขอแก้คือความพร้อมrollbackและความถูกต้องของหลักฐาน ไม่ให้แก้source/เพิ่มAPIเพื่อทำให้ข้อความรายงานเก่ากลายเป็นจริง

### F-18 — แก้referenceและความหมายpropertyให้ตรงของจริง

**1. Referenceของการย้อนRound3ชี้ชื่อไฟล์ที่ไม่มีอยู่**
manifest.studio.syncedScriptsใช้round03PreStudioScriptPathเป็นชื่อสั้น9รายการ ทุกpathนั้นTest-Path=false โดยมี4รายการที่ประกาศrestoreจริง:

| อันที่ต้องrestoreถ้าย้อนRound3 | pathจริงใต้ correction-round-03/pre/studio/scripts/ |
| --- | --- |
| RigAnimationConfigs | ReplicatedStorage_Shared_configs_RigAnimationConfigs.luau |
| RigAndCardService | ServerScriptService_Server_services_RigAndCardService.luau |
| Client | StarterPlayer_StarterPlayerScripts_Client.luau |
| R6AnimationController | StarterPlayer_StarterPlayerScripts_Client_character_R6AnimationController.luau |

manifestอ้างRigAnimationConfigs.luau/RigAndCardService.luau/Client.luau/R6AnimationController.luauซึ่งไม่มี จึงใช้branchrollbackที่ระบุไม่ได้ GUARD08ยังอ้างการย้อนRound3ด้วย

**แก้:** เปลี่ยนreferencesในmanifestรุ่นแก้ให้ชี้actualpathsและตรวจhashของทุกbeforeที่branchนั้นใช้ก่อนmutation หรือถอดbranchที่ไม่อยู่scopeออกอย่างชัดเจน ห้ามrename/เติมไฟล์ชื่อสั้นลงbundleRound3เพื่อให้pathเก่าผ่าน ไม่ต้องรื้อtypedserializerที่แก้แล้ว

**2. SnapshotWorldPivotไม่ตรงค่าที่อ่านสด**
post/studio/studio-post.jsonบันทึกModel.properties.WorldPivot.Y=5 แต่read-onlyจริงได้:
- Model.WorldPivot.Y = **4.5**
- Model:GetPivot().Y = **5**
- PrimaryPart = ServerStorage.CageZeroStandardR6Rig.HumanoidRootPart

[INFERRED] มีความเป็นไปได้ว่าexporterใช้GetPivotแต่ติดชื่อWorldPivot ต้องตรวจpayload/exporterที่ใช้จริง ไม่สรุปว่าเกิดจากผู้ใช้หรือยืนยันว่าcaptureปลอม การเปรียบเทียบGUARD06แบบexactปัจจุบันต้อง**ABORT**เมื่อพบต่าง0.5 จึงยังบอกว่าผ่านlivepost-stateทั้งหมดไม่ได้

**แก้:** เก็บWorldPivotจากpropertyจริงและแยกGetPivotถ้าต้องการเก็บทั้งคู่ ระบุschema/guardตรงกัน recapturecurrentstateตามเวลาจริงไว้snapshotรุ่นใหม่ไม่ทับRound3/4เก่า ห้ามsetStudio.WorldPivot=5เพื่อทำให้รายงานตรง ห้ามrestoreใดๆก่อนguardทั้งชุดผ่าน คงsceneเดิมpreserveและrun01ACCEPTED_GAP

### F-19 — live resultsยังโยงกับsourcelockไม่ได้

**A. ขนาดpartsในV03ขัดCardConfigs/ApplyCardScaleจริงทุกpreset**
fix009:131–136ระบุTorso/LimbsคูณheightScaleทุกแกน แต่sourceแยกwidth/depth ตามRigAndCardService:245–268 และCardConfigs:

| Preset | width / height / depth | Torsoที่คาดจากsource (X,Y,Z) | Torsoในรายงาน |
| --- | --- | --- | --- |
| Leon_TierB | .95/.92/.95 | (1.90,1.84,.95) | (1.84,1.84,.92) |
| Ney_TierA | .97/.98/.97 | (1.94,1.96,.97) | (1.96,1.96,.98) |
| Ronan_TierB | 1.00/1.03/1.00 | (2,2.06,1) | (2.06,2.06,1.03) |
| Vandik_TierA | 1.05/1.08/1.04 | (2.10,2.16,1.04) | (2.16,2.16,1.08) |

สูตรstandingheightที่หัวตารางเขียนTorso.Y/2+Leg.Y+Head.Yก็ไม่ใช่GetStandingHeight:310–317ซึ่งคืนLeftLeg.Y+HRP.Y/2+HipHeight ค่า2.76/2.94/3.09/3.24สอดคล้องเฉพาะสูตรหลัง ไม่พิสูจน์ว่าdimensionsที่อ้างวัดจริงถูกต้อง

**B. ชื่อAPI/fields/errorข้อความในprobesไม่มีในsourceนี้**
- fix009:194เรียกRigAndCardService.EnsureBootstrapTestFloor() แต่publicAPIจริงเป็นGetPrimaryFloor():367 helpervalidateFloorPartเป็นlocal; รูปข้อความfloorerrorที่รายงานต่างจากsource347–386
- fix009:167อ้างแก้RigAnimationConfigs.StateAnimations.walk.assetId แต่moduleมีlocalPROFILESและGetProfile/GetAllProfilesที่คืนtable.freeze ไม่มีStateAnimations: การใช้fixture/สำเนาอาจทำได้ แต่ต้องระบุจริง ไม่เรียกว่าแก้configAPIที่ไม่มี
- fix009:117อ่านplayer:GetAttribute("EquippedCardId")แต่serviceเก็บในplayerEquippedCardByUserIdและrig.EquippedCardId ใช้GetEquippedCardId(userId)ได้; serviceไม่ได้ตั้งplayerattributeนี้
- fix009:111/175อ้างcharacter.CardId/CharacterGeneration แต่productionตั้งEquippedCardIdและเก็บgenerationในlocaltable ไม่ได้exportattributesสองตัวนี้ ถ้าprobeเพิ่มdiagnosticsต้องระบุว่าprobeสร้างเอง
- timeouterrorในfix009:120–122เริ่ม[ClientBootstrap] Required instance ... within0.15s แต่entryจริงเริ่ม[Client.Init] Shared folder timed out.../R6AnimationController module timed out... ไม่มีClientBootstrap helperในsource

**C. Network.Init durationไม่ใช่overallbootstrap elapsed**
fix009:109–110วัดเพียงNetwork.Init(10.0)0.0554/0.0731ms จึงยังไม่ครอบคลุมช่วงShared/Network/character/controller/config waitsตั้งแต่bootstrapStartตามinit.client:8–44 ต้องlabelเป็นcomponenttiming และวัดoverallreadyตามนิยามHANDOFFเพิ่ม ไม่ใช้เวลาตอนmoduleพร้อมแล้วแทนcoldbootstrap

**สิ่งที่ต้องส่งแก้โดยAGY**
- แนบexactLuauprobe+DataModelที่รันและผลจริงเฉพาะกรณีขัดกันในfix-010.md ถ้ามีต้นฉบับเดิมให้traceและแก้คำบรรยาย หากtraceไม่ได้ให้รันtargetedprobesกับproductionmodulesที่hashตรงใหม่
- แยกproductionAPIจากtestfixture/สำเนาที่injectfault พร้อมsource/hashและสิ่งที่instrumentationเพิ่ม ไม่แต่งfields/errorให้เหมือนผลจริง และไม่เปลี่ยนCardConfigs/Types/productionAPIให้ตรงตารางผิด
- อ่านsizes/C0/C1/rotationsจากrigที่ApplyCardScaleจริงครบ4presets3rounds รายงานค่าที่วัดกับexpectedแยก; วัดfullbootstrapแยกจากNetwork.Init component
- F13อ่านserviceAPIและrigattribute; F15ใช้GetPrimaryFloor; F17ใช้faultfixtureที่บันทึกวิธีทำอย่างตรงไปตรงมา ส่วนgeneration/leaveให้ระบุการสังเกตidentityและสิ่งที่mockพิสูจน์ได้จริง
- ผลpose/state/respawnในรายงานยังเป็นAGY-reportedจนtraceabilityของprobeได้รับการยืนยัน ไม่จำเป็นต้องrerunกรณีที่หลักฐานเดิมโยงcurrentcodeได้ครบ ไม่บังคับlogทุกpassหรือscreenshot/video

## Gate disposition

| Gate | ผลreview |
| --- | --- |
| V01 | liveEdit source/topology/typedattributesตรวจได้; spawned-runtimeยังเป็นผลที่AGYรายงาน |
| V02 | PENDING_TRACEABILITY — componenttimingไม่ใช่overall และprobes/API/attributesไม่ตรง |
| V03 | NOT_ACCEPTED — measuredsizesขัดsource ต้องแก้หลักฐาน/ตรวจtargeted |
| V04 | PENDING_TRACEABILITY — poseมีตัวเลข แต่faultconfigAPIอ้างไม่มีในmodule |
| V05 | AGY_REPORTED / PENDING_TRACEABILITY — generationattributesและmockleaveต้องชี้วิธีวัด |
| V06 | PENDING_TRACEABILITY — publicAPI/errorที่อ้างต่างจากsource |
| V07 | sourceallowlistตรวจได้ / F18ยังOPEN / visualและobserverNOT VERIFIED |

Visual3Dที่ยังไม่ตรวจคงincomplete ไม่บังคับภาพ/วิดีโอ; second-clientobserverคงpendingตามsession/09UATที่HANDOFFอนุญาต ไม่เพิ่มเงื่อนไขว่าต้องมีWANclientเพื่อแก้reportนี้

## Source lock (repo = live Studio)

- src/shared/Constants.luau — DB9AC36D26C72B73C3248A2FF17CDC8FFB13E6FA947B551D078BB4E4161FD888
- src/shared/Types.luau — EE9F02D17420A26974CADF62E1FE9EBC0B95E61EADF9AAA2E7FA47626AD47108
- src/shared/Network.luau — 147CEBF912EB7219DF239A0BC98E6A86257A20AE5890CD7B59B75FB8AC9EF8AB
- src/shared/configs/CardConfigs.luau — E558086E96A167780FEBCC24D8CBADB88EE7C37EA271A2F37DC548C1F3B48662
- src/shared/configs/RigAnimationConfigs.luau — FFDA487ED869B544953F148F36D23F027687C7B74D296E2A257571349F2DE2C9
- src/server/init.server.luau — 93758403E932664DDD88E9A78EA8175B936F199777494CD11248178931A50E3E
- src/server/services/RigAndCardService.luau — A6D8D9EA45470B10ED8C77FABBA0E491B04D87EBF470F23DAE47EA04E0DD8CFC
- src/client/init.client.luau — E1D4C440C98CF84E12A5121F37476A74335E1E794A66C54C86A519754000E2F6
- src/client/character/R6AnimationController.luau — 61490D844AB4FF97FDE5A756C7EAC81316AA7E3A95F5D1D9B4622AA62A6587A6

## Owner decision และpromptรอบถัดไป

F18ถูกส่งกลับซ้ำในreview009และ010หลังOwnerเปิดรอบแก้baselineใหม่ จึงเข้า3-Strikeตาม [stang-luna/SKILL.md](C:/Users/Stang/.codex/skills/stang-luna/SKILL.md): “หากบั๊กเดิม F-xx ถูกตีกลับซ้ำ 2 รอบติดต่อกัน ... ให้เปลี่ยน Board State เป็น ESCALATED หยุดลูปปิงปองทันที และแจ้งขอคำวินิจฉัยจาก Stang” รอบ5ยังไม่dispatch ต้องให้Ownerวินิจฉัยวิธีเดินต่อ ไม่ขอยอมรับhistoricalgapเดิมซ้ำ

เสนอรอบแก้ที่จำกัด: **แก้F18references/serializerpropertyและF19หลักฐาน/probesเฉพาะที่ไม่ตรงsource** ไม่รื้อimplementationที่readback9/9ตรงอยู่แล้ว ไม่เพิ่มAPIหรือเปลี่ยนscaleเพื่อให้รายงานเดิมผ่าน

Promptเมื่อOwnerให้เดินต่อ:
อ่านreview010/HANDOFFเดิม แก้F18ตามactualpaths/WorldPivotและF19traceableprobes ขอบเขต00เท่านั้น คง0e2d23e/sourcehashlockและrun01ACCEPTED_GAP ไม่แตะRound3/4เดิม เก็บbaselineใหม่ตรงเวลาและguardก่อนmutation ส่งassets/fix-010.mdหนึ่งไฟล์พร้อมexactprobe/ผลที่วัด/expected/sourcehash/targetและสถานะNOT VERIFIEDที่ยังเหลือ หากพบcodefailureจริงให้รายงานและแก้เฉพาะallowlist00แล้วแจ้งhashใหม่ ห้ามแก้CardConfigs/Typesหรือเพิ่มproductionAPIเพื่อรองรับรายงานผิด ห้ามcommit/push/merge/deploy/spawn/เริ่ม01หรือfeatureใหม่

