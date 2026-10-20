# Review 008 — re-review fix-007 / Correction Round 2

- **Verdict: ESCALATED / CHANGES_REQUIRED** — ยังไม่ปิด00 ไม่เริ่ม01 และไม่ commit ผลงาน00
- Reviewer Codex / stang-luna; 2026-10-20; ไม่แก้โปรแกรม/รันapplication tests/Play/commit/push/merge/deploy
- Actual ref: **HEAD `f8729cc6e714f10a1cb60253a4f037d7c49f7505` + working-tree hashesด้านล่าง**; AGY source baseเดิม `2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c` ไม่ได้เปลี่ยน sourceจากcommitเอกสารf8729cc
- AGY session `e86ac30e-006d-4338-9a90-5f5e3b002028`; run `run-phase00-agy-impl-01`; F13–17 verifiedเฉพาะcode correction ส่วน runtime gatesคงpending
- Intake attachment SHA256 `069A171E82517ED7CF002BAB699460BF46C5354442F479B6BFD815D9438A2EDF`; fix-007 SHA256 `D17F2C4785B6D541A0E58250D4DE5A40BB155D39C85B31321EFEAA6D97A900CC`
- F18/F19ค้างจากreview007และถูกส่งกลับอีกครั้งเมื่อจะเข้าสู่correction Round3 จึงหยุดautomatic ping-pongตาม3-Strike ไม่ dispatchต่อเอง; รอOwnerวินิจฉัยตามท้ายรายงาน

## ผลการตรวจแต่ละ Finding

| Finding | ผล independent review | พิกัดหลัก |
| --- | --- | --- |
| F-13 P1 | **VERIFIED — code** ไม่มี listener equipในInit; API/definitionsคงเดิม | RigAndCardService:686–707 |
| F-14 P2 | **VERIFIED — code** Network.Initก่อนcontroller, remaining budgetทุกbootstrap wait, ไม่มีtop-level unbounded config waits | init.client:23–44; controller:40–84,474–481 |
| F-15 P2 | **VERIFIED — code** invalid primary fail, ตรวจAnchored/CanCollide/CanQuery/size, ตรวจray normalและhit margin | RigAndCardService:347–481 |
| F-16 P2 | **VERIFIED — code** cleanupinvalidate token/generation; post-yield/currentCharacter/Workspace guardsก่อนpublish | controller:114–153,214–239,318–369 |
| F-17 P2 | **VERIFIED — code** requiredcliperror/Lengthไม่พร้อมทำให้ไม่readyและล้างpartial handles | controller:270–363 |
| F-18 P2 | **OPEN / ESCALATED** manifestยังไม่ถูกต้องครบชุดตามรายละเอียดด้านล่าง | manifest:131–185 |
| F-19 P2 | **OPEN / ESCALATED** static/JSsimulationยังถูกเรียกว่าmeasured runtime gatesPASS | fix-007:49–144; verify_phase00.js:51–55,118–192,233–299 |
| F-20 P1 (ใหม่) | **OPEN** sourceในStudioยังเป็นrevisionก่อนcorrectionทั้ง4ไฟล์ที่แก้ | 4pathsในตารางhashด้านล่าง |

การปิดcode findingไม่ใช่การยืนยันruntimeทั้งหมดจากNode; F19ยังคุมหลักฐานacceptanceของ00 ห้ามเปลี่ยนไปเป็นPASSเพราะตารางนี้

## F-18 — rollback manifestยังไม่สามารถใช้เป็นsafe restore contract

[CONFIRMED] filesystem pre hashesและcurrent working-tree post hashesตามmanifestตรงจริง แต่post copiesใน `.sandbox/rollback/run-phase00-agy-impl-01/post/` ยังเก่าสำหรับRigAndCardService/init.client/RigAnimationConfigs/R6AnimationControllerทั้ง4ไฟล์ จึงห้ามเรียกpost bundleว่าตรงrevisionนี้ทั้งหมด

[CONFIRMED] `manifest.json` ระบุ `descendantsCount=15` แต่รายการมี17ตัว และpath Motor6DผิดเทียบStudio/sourceจริง:
- actual `HumanoidRootPart.RootJoint`, manifest `Torso.RootJoint`
- actual `Torso.Neck`, manifest `Head.Neck`
- actual `Torso.Right Shoulder/Left Shoulder/Right Hip/Left Hip`, manifestวางแต่ละjointใต้limb
ไม่มีpost hashes/sourcesของStudio scripts หรือpostproperties/attributes/child setsสำหรับcomplete subtree guard คำสั่ง “contains post-state instances” จึงตรวจไม่ได้ว่ามีงานอื่นแทรกหรือไม่

[CONFIRMED] historical Studio instance before-stateถูกระบุNOT VERIFIEDอย่างถูกต้องแล้ว แต่ `studioScriptPreState` ยังกล่าวVERIFIED/ตรงgitHEADโดยไม่มีoriginalcaptureอ้างอิง จึงยังไม่ใช่หลักฐานbefore-state การเก็บsourcepreจากrepoไม่พิสูจน์ว่าStudioเคยมีsourceนั้น

**สิ่งที่ต้องแก้เมื่อOwnerอนุญาตให้ดำเนินต่อ:** รักษาประวัติrunแรกที่ไม่ทราบไว้ตรงๆ; แยกfilesystempre/postแต่ละcorrectionไม่ทับsnapshotเก่า, จัดcurrent Studio baselineใหม่จากreadbackจริงก่อนเขียนพร้อมpath/class/source/hash/properties/attributes/childrenครบscope และactualtarget; ตรวจguardทั้งชุดก่อนmutation ไม่มีการลองrollbackจริงเพื่อสร้างหลักฐาน; ไม่ restoreเอกสารค้างหรือcommitเอกสารf8729cc การยอมรับhistorical gapไม่ยกเว้นguard/manifestที่ยังแก้ได้

## F-19 — 72 checks ไม่ใช่runtime measurementsของimplementation

อ่านตัวตรวจที่fix007อ้าง **โดยไม่execute**:
`C:/Users/Stang/.gemini/antigravity-cli/brain/19d212ec-bb22-4416-bff2-9e1ffa712bc5/scratch/verify_phase00.js`
SHA256 `F318EF8DD4526F7405A6C695327222AEBB0905F651D78DA6E85E9109DFFEBB52`

- lines51–55: hashผ่านเพราะlength=64 ไม่ได้compareกับStudio
- lines89–112: ตรวจindex/includesในsource ไม่จับเวลาclientbootstrapจริง; “bootstrap assertions <5ms” เป็นเวลาตรวจsource
- lines118–192: presets/baseSizesถูกเขียนซ้ำในJavaScript, คูณแล้วหารค่าของตัวเอง; ไม่เรียกApplyCardScaleจริง, ไม่อ่านMotor6D.C0/C1/rotations, reverse loopเพียงassignตัวแปร; drift=0/standingheightนี้เป็นsimulationไม่ใช่rigmeasurements
- lines233–249: includesคำว่าtoken/generation ไม่ได้ทดสอบCharacterRemoving/delay/respawn race
- lines256–282: includesvalidationและนับmanifestentries ไม่ได้ทำinvalidfloorprobeหรืออ่านStudio
- ไม่มีclient PostSimulation/pose samples, loadedLengthผลจริง, controls/camera, ตาย3รอบ/void/race/leaveผลจริงบนrevisionนี้

fix007ยังระบุV01–07 **PASS(Measured)** รวมmotion/lifecycle จึงไม่ผ่านF19 แม้แยกvisual/multi-clientเป็นNOT VERIFIEDแล้ว รายงาน8edgecasesไม่มีrepro/scriptอ้างอิงที่เพียงพอในfix007 ไม่ใช้จำนวนchecksแทนacceptance

**ต้องทำหลังsource syncที่ถูกต้อง:** AGYทดสอบตามV01–07จริงในtargetdevelopmentStudio ระบุelapsed/values/path/hash/กรณีที่รันพอให้ตรวจเกณฑ์ แยกstatic/simulation/runtime/asset/visual/observer; ไม่ต้องเพิ่มtestframeworkหรือเก็บlogทุกpass ไม่ต้องscreenshot/video; visualที่ยังไม่มีinspectionคงincomplete อย่าอ้างassetdelivery URLว่าคือผลโหลดสำเร็จ

F17ใช้Lengthเป็นpropertyที่มีจริงใน [AnimationTrack reference](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack#Length) แต่ยังต้องมีผลโหลด/poseจริงตามHANDOFF; generic animationreferenceURLในconfigอ่านผ่านweb toolไม่ได้ จึงไม่อ้างว่าURLเสียหรือพิสูจน์nativeclipIDsจากURLนั้นได้

## F-20 — Studio sourceยังไม่ใช่revisionที่ส่งreview

[CONFIRMED] list/getstate/read-only exportจากStudioที่เชื่อมอยู่ตอนreview:
- studio ID `a9611fd4-ad70-4254-9790-21fea517dc77`, mode Edit
- tool label Untitled Experience; game.Name Place1, PlaceId `137721422246269`, GameId `10772059094`
- ID/placeต่างจากrunที่รายงานเดิม (95ffe9c8.../PlaceId0); ไม่อนุมานว่าใครpublishหรือย้ายplace
- source9pathsมีครบ แต่ **matchเพียง5/9** อีก4ตรงreview007ก่อนแก้ทุกไฟล์ จึงยังมีinventorylistener/unbounded waits/oldanimationcontrollerในStudioนี้
- templateactualมี17descendants,7BaseParts/6Motor6Ds; เป็นscene/sourceinspection ไม่ใช่runtimepass
- snapshot `.sandbox/exports/phase00-review008/studio-readonly.json` ignoredlocal ไม่ใช่historicalbeforeของrunแรก

**Correctionที่ต้องทำ:** AGYreconcileactualdevelopmenttargetกับrunก่อนsync; snapshotcurrentbeforeที่ตรวจได้จริง แล้วsyncเฉพาะallowlist4sourceที่เปลี่ยนและreadbackSHA9/9 ก่อนruntimeprobes ห้ามpublish/เปลี่ยนplaymodeที่ผู้ใช้กำลังใช้อยู่/แตะreference sandbox ไม่มีสิทธิ์ให้Codexแก้Studioแทนจากreviewนี้

## Source lock — working tree และStudio readback

| Path | Repo SHA256 | Studio SHA256 |
| --- | --- | --- |
| src/shared/Constants.luau | DB9AC36D26C72B73C3248A2FF17CDC8FFB13E6FA947B551D078BB4E4161FD888 | ตรง |
| src/shared/Types.luau | EE9F02D17420A26974CADF62E1FE9EBC0B95E61EADF9AAA2E7FA47626AD47108 | ตรง |
| src/shared/Network.luau | 147CEBF912EB7219DF239A0BC98E6A86257A20AE5890CD7B59B75FB8AC9EF8AB | ตรง |
| src/shared/configs/CardConfigs.luau | E558086E96A167780FEBCC24D8CBADB88EE7C37EA271A2F37DC548C1F3B48662 | ตรง |
| src/shared/configs/RigAnimationConfigs.luau | FFDA487ED869B544953F148F36D23F027687C7B74D296E2A257571349F2DE2C9 | 6C8F343B76DF8D752E1F26706F427465DA677CD6CD32E261E707A0E194119D96 |
| src/server/init.server.luau | 93758403E932664DDD88E9A78EA8175B936F199777494CD11248178931A50E3E | ตรง |
| src/server/services/RigAndCardService.luau | A6D8D9EA45470B10ED8C77FABBA0E491B04D87EBF470F23DAE47EA04E0DD8CFC | 6678E93111D0F20FD5DEAE2B5EF55606C3C16E8F15EE9D49296B031FF65D18CC |
| src/client/init.client.luau | E1D4C440C98CF84E12A5121F37476A74335E1E794A66C54C86A519754000E2F6 | A4BA52E542B3137FA42201B4E5E2FABA7E8CC65004C8715B68661D28DCE15EA3 |
| src/client/character/R6AnimationController.luau | 61490D844AB4FF97FDE5A756C7EAC81316AA7E3A95F5D1D9B4622AA62A6587A6 | F70CA202B5263CF62E96D33B247A8EAF1BFCDFAF05261C3122CC83E7AE7F882E |

Scopecheckกับoriginalbaseline: sourceเดิม5แก้+2ใหม่ตามallowlist,39sourceเดิมไม่เปลี่ยน รวมTypes/CardConfigs; `git diff --check`ผ่าน HEADf8729ccคงเดิม ไม่มีcommit00; เอกสารchoice/specใหม่ยังรอrequirementผู้ใช้

## Owner decision / contract สำหรับดำเนินต่อ

[stang-luna SKILL.md](C:/Users/Stang/.codex/skills/stang-luna/SKILL.md) บังคับ: “หากบั๊กเดิม F-xx ถูกตีกลับซ้ำ 2 รอบติดต่อกัน (เข้าสู่ Round 3 แล้วยังไม่ผ่าน) ให้เปลี่ยน Board State เป็น ESCALATED หยุดลูปปิงปองทันที และแจ้งขอคำวินิจฉัยจาก Stang”
ใช้กับF18/F19รอบนี้; ไม่ถือว่าการยอมรับreportของAGYเท่ากับOwnerยกเว้นgate

เสนอให้Ownerยอมรับ **เฉพาะ historical Studio before-stateที่กู้ไม่ได้ของrunแรก** โดยบันทึกข้อจำกัดถาวร และให้AGYสร้างcurrentbaselineใหม่ก่อนcorrection/sync/runtimeverifyตามข้างบน ไม่อนุมัติPASS/ปิด00หรือข้ามruntimeจากการตัดสินใจนี้ อีกทางคือกู้originalsession/savedplace/versionที่มีหลักฐานจริงก่อนดำเนินต่อ

**Promptพร้อมส่งเมื่อOwnerวินิจฉัยให้เดินต่อเท่านั้น:**
แก้F18/F19/F20ตามreview008 ใช้HANDOFFเดิมและขอบเขต00; ไม่รื้อF13–17ที่codeแก้แล้ว ตรวจactualHEADf8729cc+hashes, เก็บbeforeของtargetปัจจุบันจริงก่อนsync4source, readback9/9และรันV01–07ตามcaseจริง แยกstatic/simulation/runtime/visual ไม่เรียกNode72checksว่าruntimePASS คงhistoricalgapตามOwnerdecision ส่งหนึ่งไฟล์assets/fix-008.mdพร้อมnotes/tasks READY_FOR_REVIEW ห้ามcommit/push/merge/deploy/spawn/เริ่ม01/07/Phase2และไม่ปรับchoiceโดยไม่มีrequirementใหม่

