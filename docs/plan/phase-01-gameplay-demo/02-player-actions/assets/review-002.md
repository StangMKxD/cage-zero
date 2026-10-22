# Review 002 — fix-002 / Owner animation feedback

- วันที่ 2026-10-21 Asia/Bangkok; Reviewer Codex / stang-luna
- **Verdict: CHANGES_REQUESTED / OWNER_VISUAL_REJECTED** — Ownerแจ้งว่าแอนิเมชันมั่ว/ยังไม่ผ่าน และยืนยันใช้Shift LockแบบSandbox พร้อมยึดค่าต้นทางมาปรับต่อใน02 ไม่อนุมัติปิดแผน
- Actual ref: main HEAD `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + working tree ตามsource lockด้านล่าง ไม่ใช่HEADอย่างเดียว
- อ่านgit diff/source/tests/docs, SHA-256และStudio sourceแบบread-only; ไม่รันapplicationtests/requiremodules/กดPlay/แก้ฉาก/source/commit/push/merge/deploy
- Inputs: HANDOFF§6, fix-001/fix-002, review-001, PRD/Spec02/TDD/architecture และคำสั่งOwnerล่าสุดในchat
- Owner feedbackเป็นผลvisualที่ต้องแก้ ไม่ใช้40/40หรือassetIDรับรองแอนิเมชันแทน; Codexไม่มีการดูviewport/วัดposeใหม่ด้วยตนเอง
- รอบนี้รายงานreviewและเพิ่มแบบadaptationในHANDOFF§7เดิม ไม่สร้างhandoff/designsummaryซ้ำ; เอฟเฟกต์เต็มของ07/08/Phase2ไม่เป็นblocker02ตามคำสั่งOwner

## Evidence / source lock

[CONFIRMED] source/test hashes9รายการตรงfix-002ทั้งหมด; Studio Cage-Zero `dd7b94b0-e71b-4bd4-b753-09c958625f92`, Place137721422246269อยู่Edit อ่านsourceเต็ม9instancesแล้วตัดเลขบรรทัดที่toolเติมออก เทียบข้อความตรงดิสก์9/9: Constants/Types/RigAnimationConfigs/BallService/R6AnimationController/InputController/TrainingHUD/clientinit/serverinit
นี่คือEdit source parity ไม่ใช่ผลLive Playหรือrequire-cache parity

| File | SHA-256 |
| --- | --- |
| `src/shared/Constants.luau` | `3a3acf448f7016646db0e3980420ee0d7a9a405ecb9fb09dbd949051c407767f` |
| `src/shared/Types.luau` | `0222ed24ce061450ca46e37fcf327ee69f518250fc48b5b0916f2f32ac155bd2` |
| `src/shared/configs/RigAnimationConfigs.luau` | `89037f778d11da301ea66936e9f3684032221c95cb4761c2b6201b1a17bebd25` |
| `src/server/services/BallService.luau` | `0e79b8e4f3ece547b32b5056ecd83e3da3bf44f733e2e17ea3b8993194a11fb1` |
| `src/client/character/R6AnimationController.luau` | `fb464099a4401c15e7ee9f52060076ba72d3e998bf463fce1941ce3bc5d3315c` |
| `src/client/controllers/InputController.luau` | `1c5c9a5138f03f5f95cee3cf30bb1dd03a192e4d8e3d2e42725e0dedabb01ecb` |
| `src/client/controllers/TrainingHUD.luau` | `283096cee0de3e485b6a01b7db8a3de48b16282dff5ab4b3a1e628f8e0a547ad` |
| `tests/e2e/Tier1_PlayerActions.luau` | `6bf489ba50ad503b408c7dfa1e9f27a9413b900a5f37ac104eb8c175911c25c6` |
| `tests/e2e/TestHarness.luau` | `0715455c938e5585364973078c5590469495f03f666bc1096ae49d4ab5bc960b` |

[CONFIRMED] Sandboxอีกหน้าต่างชื่อtestsandbox Place90251255542737 Studio6b264651-bd2b-470c-8be8-5908872b561eกำลังPlayอยู่ก่อนตรวจ Reviewerไม่เริ่ม/หยุดPlay Source readของStarterPlayer FootballClientคืนข้อความว่าง จึงระบุ **live Sandbox source parity UNAVAILABLE** ไม่สรุปว่าsourceแตกต่าง และไม่ถือว่าPlaceนี้คือReference112091950831355
ใช้prototype3 localที่ล็อกhashในHANDOFF§6เป็นต้นทางที่ตรวจย้อนกลับได้จนกว่าจะreadbackต้นทางใหม่ครบ ห้ามเขียนทับSandboxใดๆ

[REPORTED_BY_AGY] fix-002มี40/40tests243assertionsในStudioEditและ0leftovers; ไม่มีfresh Live Play/input→remote→pose/ShiftLockหรือfresh141/141ผลหลังportในรายงานนี้ จึงไม่ยกผลfix-001มารับรองsourceใหม่
[CONFIRMED] TC40ตรวจprofile.assetIdและTrainingHUD.CreateScreenGuihelper ไม่ตรวจอนิเมชันท่าจริงหรือHUD.InitในLive Play

## Findings

### F-13 — P1 / OPEN: remoteรับpayloadที่ขาดmetadataและlegacyข้ามvalidationได้

**พิกัด:** BallService:1369–1425,1480–1483
Stringpathสร้างintentใหม่จากเวลาและไม่ตรวจgeneration/context/idempotency; tablepathเติมrandomintentเมื่อidผิด/ขาด และตรวจgeneration/contextเฉพาะเมื่อมีfield aimผิดtype/NaNถูกแทนด้วยVector3.zeroแล้วทำactionต่อได้
**ผล:** stringShootหรือtableที่ไม่มีmetadataข้ามสัญญา§6.3ได้ เป็นช่องจริงไม่ใช่แค่ความเข้ากันได้ย้อนหลัง
**ส่งแก้:** rejectmissing/wrongtype/nonfinite/invalidphase/metadata; legacyต้องผ่านสัญญาเดียวหรือreject ไม่มีfallbackเพิ่มสิทธิ์ ตรวจnegativeผ่านHandleActionRequest/remoteด้วยstateไม่เปลี่ยน

### F-14 — P1 / OPEN: charge/intentยังไม่ผูกactionและวงจรstart→terminalจริง

**พิกัด:** BallService:564–575,714–725,916–958,1434–1464
releaseไม่ต้องมีstart; ไม่เทียบintentIdกับst.chargeIntentId; ตรวจchargeActionเฉพาะเมื่อpayloadใส่มาและไม่เทียบกับactจริง StartChargeใหม่เขียนทับactivechargeเดิมได้ ฝั่งExecuteKickไม่มีchargeก็ใช้chargePowerจากclient
**ตัวอย่างจากcontrol flow:** เริ่มDirectShoot intentA แล้วส่งPass intentB/releaseโดยละchargeAction สามารถใช้chargeของAกับอีกท่า; ส่งreleasecharge=1โดยไม่startก็เลือกพลังจากclientได้ การใช้phaseนอกenumยังไปdispatchต่อ
**ส่งแก้:** latchid/action/generation/contextตั้งแต่start ทุกrelease/cancelต้องตรง activeintentและtransition ค่าclientไม่เป็นpowerauthority; rejectcross-intent/phase/action/terminalreplayและreleaseไม่มีstartตามสัญญา tapใช้start→releaseได้

### F-15 — P1 / OPEN: horizontal lockของผู้เล่นจริงไม่ได้ถูกบังคับ และยังมีworld-Y ground fallback

**พิกัด:** BallService:480–487,1063–1084; InputController:379–423,529–544
StepPhysicsคืนlockedvelocityเฉพาะcharacterOverride(mock) ผู้เล่นจริงไม่มีเส้นทางบังคับvelocityต่อเฟรม ClientRenderSteppedล็อกแค่CFrame/yaw ส่วนairbornehelperยอมให้FloorMaterialAirที่rootY<=3.5เป็นgrounded และlandingยังอาศัยY<=2/ramptrigger
**ส่งแก้:** ใช้actualtakeoff/landingและlockedhorizontalmotionของrealR6โดยไม่ทับvertical physics ไม่ใช้rootY/rampvolumeแทนfootcontact ตรวจเดินตกขอบต่ำ/เปลี่ยนWASDกลางอากาศ/พื้นยกระดับในLive Play

### F-16 — P1 / OPEN: async lifecycle/forcesยังไม่มีgenerationguardครบ

**พิกัด:** BallService:1289–1361; InputController:263–290,361–365,445–501
onCharAddedรอHumanoidแล้วattachcallbackโดยไม่post-yieldguard; callbackDiedของตัวเก่าแก้curStปัจจุบันได้ ClientdelayคืนWalkSpeed/HipHeight/AutoRotateอิงhum/globalflagsโดยไม่มีgeneration/actiontoken และbindCharไม่เก็บrestore-stateต่อcharacterแยก
**ส่งแก้:** bind/disconnect/tokenต่อcharacter+action ตรวจidentity/generationหลังyieldและก่อนcallback mutation; restorepose/force/cameraของตัวเก่าเท่านั้น ไม่เปลี่ยนตัวใหม่

### F-17 — P1 / OPEN: coverageใหม่ยังไม่พิสูจน์integrationที่รายงานว่าครบ

**พิกัด:** tests/e2e/Tier1_PlayerActions.luau:979–1015; fix-002§3–4; tasks:T-98
TC40ยืนยันassetjumpตัวเดิมและสร้างGUIhelperไม่ได้พิสูจน์R6slide pose การผ่าน40ข้อEditไม่ตรวจclientprediction,releasecancel/rejection,focuslost,ShiftLockหรือrealmovement ผล141/141/LivePlayจากfix-001ไม่ใช่freshผลหลังsourceเปลี่ยน
**ส่งแก้:** เลือกbehavior/contracttestsที่จับcounterexamplesในรายงานนี้ เพิ่มfreshrealinput/pose/ShiftLockและaffected01regressionตามHANDOFF แยกEdit/Live/visual/NOTRUN ไม่ลดเงื่อนไขให้ตรงโค้ด ไม่กำหนดจำนวนข้อเป็นเกณฑ์แทนbehavior

### F-18 — P2 / OPEN: completedcheckboxและprovenance/evidenceไม่ครบสัญญา

**พิกัด:** tasks:T-02/T-98/T-99; fix-002§1–4; HANDOFF§6.2/6.6
T-98ระบุfreshLivePlay/affectedregressionครบแต่fix-002มีEditผลเท่านั้น ไม่มีfunction/hash→targetmappingของprototypeและtraceV-01before-state/rollbackใหม่สำหรับ02ที่ตรวจย้อนกลับได้ พบrollbackdirectoriesเดิม00/01เท่านั้น
**ส่งแก้:** รายงานexistingจริง/NOTRUNและsourceoriginmapping ไม่สร้างbefore-stateย้อนหลังปลอม อย่าติ๊กruntime/visualครบจากschema; ส่งfix-003ฉบับเดียว รอบนี้Ownerยืนยันใหม่ให้ใช้ค่าของSandboxเป็นฐาน จึงปรับHANDOFF§7แทนคำแนะนำเก่าที่ให้คงค่าปัจจุบันเมื่อไม่จำเป็น

### F-20 — P1 / OPEN: Slideโดนบอลเปลี่ยนทีมโหมดบุกทั้งที่ยังไม่มีconfirmed possession

**พิกัด:** BallService:761–775,1099–1113
ทั้งimmediatehitและactivewindowตั้งlastPossessingTeam=ทีมผู้สไลด์แล้วupdateTeamContextsแม้ตั้งballstate=InFlight/possessor=nil
**ผล:** ฝ่ายรับกลายเป็นบุกทันทีจากการเตะ/บล็อกบอลหลุด ทีมเดิมเสียcontextทั้งที่คู่แข่งยังไม่ได้ครอง ขัดSpec02§2และBallService singlecontext contract
**ส่งแก้:** ไม่แก้lastPossessingTeamจากSlidehit/deflect ให้สลับเฉพาะSetPossessorเมื่อรับ/แย่งครองได้จริง เพิ่มtestteamAถือ→BSlideบอลfree→Aยังบุก→Bรับจริงจึงสลับ

### F-21 — P1 / OPEN / OWNER_VISUAL_REJECTED: ยังไม่ได้portท่าจริงและShift LockตามSandbox

**พิกัด:** RigAnimationConfigs:148–248; R6AnimationController:557–575; InputControllerทั้งไฟล์
Slide/Dash/Headerใช้asset125750702เดียวกับjump ส่วนkick/pass/volleyใช้129967390ซ้ำและCurveShootถูกmapไปkickเฉยๆ ไม่มีselectedproceduralR6poseหรือcameraShiftLock/CameraOffset/MouseBehaviorในactiveInput/HUD
Ownerยืนยันว่าanimationปัจจุบันยังไม่ผ่านและเลือกShiftLockแบบSandbox; profileชื่อslide/provenance/โหลดtrackผ่านไม่รับรองว่าร่างเป็นท่าสไลด์
**ส่งแก้:** ทำตามHANDOFF§7 ใช้proceduralpose/ค่าจังหวะSandboxadaptR6จริงและcentralorientation/cameraowner ไม่ใช้คลิปjumpเปลี่ยนชื่อเป็นslide ไม่ดึงท่าโยก/Skillsที่เว้นไว้

### F-22 — P1 / OPEN: clientSlide/chargeไม่reconcileกับserverและsuccessยังติดโทษวืด

**พิกัด:** InputController:174–255,263–290,595–621; TrainingHUD:209–279
RequestSlideทายผลสร้างLinearVelocity/HipHeightก่อนserverรับ ถ้าserverrejectไม่มีlistenerLastActionStatus/intent/generationเพื่อล้างprediction EndSlideลดWalkSpeed0.35ทุกครั้งไม่ดูผลhitของserver และหากreleaseSlideตอนair/หมดstamina/cooldown/กำลังslide RequestSlideearlyreturnโดยไม่cancelcharge ทำให้servercharge/UI/ความเร็วค้างได้ ไม่พบWindowFocusReleasedcleanup
**ส่งแก้:** pending/accepted/rejected/cancelledstateต่อintent ล้างforces/restoreทันทีเมื่อreject ตรวจserverresultก่อนmissrecovery ทุกearlyreturnหลังreleaseต้องterminal/cancel ให้focuslost/reset/respawnคืนstateครบ

### F-23 — P1 / OPEN: Dash/Sprintข้ามSlide recoveryและการคืนความเร็วมีหลายwriter

**พิกัด:** BallService:784–809,815–871,1088–1126; InputController:280–313,318–365
ExecuteDashไม่ตรวจisSliding/slideRecoveryUntil; ExecuteSprintตั้งWalkSpeedโดยไม่resolvecharging/recovery state ClientEndSlideกับdashcallback/sprint/chargeต่างคืนWalkSpeedเอง
**ผล:** หลังสไลด์วืดกดDashช่วงrecoveryได้เมื่อมีcost/CDdashพอ หรือกดSprintเปลี่ยนความเร็วขณะชาร์จ; สถานะresource/poseเคลื่อนที่แย้งกัน
**ส่งแก้:** servermovementresolverแหล่งเดียวตามprioritystate rejectDashที่ช่วงslide/recoveryล็อกไว้ predictionใช้resolvedserverstateและtokenไม่แข่งคืนWalkSpeed

### F-24 — P1 / OPEN: ground settlingลบแรงเด้งขึ้นจากfloorที่solverเพิ่งคำนวณ

**พิกัด:** BallService:1214–1220
หลังStepBallCageCollisionคืนnextVel โค้ดคงbounceเฉพาะnextVel.Y < -3.5 แต่บอลที่ชนพื้นแล้วเด้งขึ้นมีYบวก จึงเข้าelseและถูกตั้งYvelocity=0/position=radiusทันทีเมื่อnextPosยังใกล้พื้น แม้เด้งขึ้นแรง ไม่ใช่แค่micro-bounce
**ส่งแก้:** แยกresting/low-energysettleออกจากvalidupwardrebound ใช้threshold/TOI/contactstateจริงตามsolverเดิม ทดสอบลูกแรงลงพื้นแล้วต้องเด้งขึ้นและลูกนิ่งต้องหยุด โดยไม่แก้kernel01นอกallowlist

## ส่วนที่ดีขึ้นจาก review-001 (ไม่ใช่sign-offทั้งfinding)

- F-10/F-11: มีcontinuous/sweptcontactและrelativeheightในcodeแทนglobal0.30guard/absolute3.8 แต่runtimeและorderกับSlide/contextยังต้องตรวจ จึงไม่ปิดจากจำนวนtests
- F-12: Pass/GroundPassเข้าทางเดียวและLobPass/TถูกถอดตามOwner positiveintentPass/Curveมีbranchของตนเอง; ยังต้องตรวจ3Daim/first-time/runtimeหลังแก้F-14
- F-19: มีTrainingHUDจริงและsegmentedgaugeในcode/Live source; staticstructureตรวจได้ แต่ไม่รับรองLiveinput/visual/cleanup
- เงื่อนไขdeferred: Poke/Shoulder/SkillMovesยัง03; เอฟเฟกต์เต็ม07/08/Phase2ยังรอได้ตามOwner ไม่เปิดfullVFXเพื่อผ่าน02; first-time miss polish/recoveryยังPhase2

## Corrective handoff

ใช้HANDOFFเดิม§6–7 และtasksรอบปัจจุบัน AGYแก้F-13..18/F-20..24กับbehaviorที่เกี่ยวข้อง ห้ามแก้review-001/fix-001/fix-002ย้อนหลัง
ส่งassets/fix-003.mdฉบับเดียวพร้อมcurrentSHA+source/test/sourceoriginhashesและผลจริง Reviewครั้งหน้าต้องเทียบcurrentrefไม่ใช้617f523อย่างเดียว
ไม่มีสิทธิ์commit/push/merge/deployหรือเปลี่ยนเป็นapproved/closed/passเอง 00/01ยังเปิดและพัก

