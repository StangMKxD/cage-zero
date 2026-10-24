# Tasks — 02-player-actions / single bindings + air lean / fix-015

- [x] **T-16 REWORK F-36 / RESOLVED in fix-015:** Real FakeShot 2.4-stud aimed lateral cut implemented and verified over multi-frame dribble follow. Server authority + immediate local visual prediction with 0ms latency. Verified across 20-frame simulation and 61/61 tests in Studio DataModel. [fix-015](assets/fix-015.md).
- [x] **T-17 REWORK F-38 / RESOLVED in fix-015:** Base locomotion custom procedural wiring (Priority 9) implemented in `R6ActionPoseController` (Ready Idle `A01`, Walk `A02`, Sprint `A03`, Jump/Fall `A06`, Landing `A07`). Stock Roblox tracks muted in `R6AnimationController`. [fix-015](assets/fix-015.md).
- [x] **F-37 HIGH / evidence repair / RESOLVED in fix-015:** Full untruncated 64-hex SHA256 fingerprints generated programmatically via node script for all 23 synced source and test files. Bound to fresh 116/116 passed test evidence in Cage-Zero Edit DataModel. [fix-015](assets/fix-015.md).

**Latest dispatch2026-10-24:** Owner resumes main continuation in **agycage w2:p48**, per Plan03 primary HANDOFF§L. Prioritize TC-P02-33/fresh evidence, T14.7–14.8 and T15§22; preserve dirty source. Sandbox preview/session belongs to agycagezero; Codex monitors only agycage. Historical baseline/assignee text below is superseded for this dispatch; current HEADc7542258b93b613e0260e43035761cbce87928cd+dirty. No Git/closure/Phase2 authority.

**ขอบเขตล่าสุด / ASSIGNED:** Owner ตรวจคลิปแล้วและสั่งเริ่มทั้งหมดตามลิสต์ Plan03 HANDOFF§F/G; ยกเลิก pauseแบบpreview-only§E. `codexluna` ทำ T14.1–14.8 รวม gameplay/แอนิเมชัน/verification. Sเอนหลังเพิ่มความโด่งตามสรีระแบบต่อเนื่อง ไม่ใช่ fixed high lob/facing override. Working-tree only, Plan02OPEN; Plan04พัก.

**READY_FOR_REVIEW** · Owner Stang · Controller Codex · Implementer AGY Teamwork-preview
[Plan](plan.md) / [HANDOFF §8](assets/HANDOFF.md#8-owner-delta--argon-r6-football-animation-pack--2026-10-22) / [review-003](assets/review-003.md) / [review-002](assets/review-002.md) / [TDD](../../../tdd/master-test-cases.md)
Base SHA `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + current dirty-source lockในreview-003; Turn AGY / Manual dispatch ไม่มีauto-loop
Ownerdelta2026-10-22: ใช้ArgonR6Packเป็นต้นแบบvisualใหม่A01–18ตามHANDOFF§8; ง้างค้างไม่สับขา คงgameplay/ShiftLockเดิม ไม่รับรองPlayerZIPทั้งชุด; fix-003คงhistorical ส่งfix-004ใหม่
ยังเว้นท่าโยก/Poke/Shoulder; ไม่มีLobPassแยก; 00/01ยังเปิดและพัก

## งานส่งแก้
- [x] T-15 ASSIGNED / LATEST OWNER — HANDOFF§22 เอาinitialA/Dstylelockออก: RMBง้างก่อนแล้วเปลี่ยนmovement/A/Dได้ตลอดชาร์จ ซ้ายFinesse/ขวาTrivelaเท้าขวา,holdposeblendลื่นไม่resetcharge;Serverใช้currentacceptedrelease-sideไม่ถูกstartlatchทับ. Snapshotเมื่อปล่อยเท่านั้น;testD→hold→A=Finesseและinverse=Trivela/สลับหลายครั้ง/neutral/rotatedyaw/FakeShotcleanup/actualtrajectory. AirVolleyเดิม;ไม่เปลี่ยนscaleยิงส่งหรือscopeอื่น.
- [x] T-14 OWNER PLAYTEST / ASSIGNED: Ownerอนุญาตเริ่มครบ T14.1–14.8 แล้ว ตาม HANDOFF§21 ที่แก้ล่าสุด + Plan03§F/G; codexlunaลงมือ/testและส่งตรวจ ไม่ปิดแผนเอง.
- [x] T-14.1 ASSIGNED — ย้ายส่งบอลไป E ปุ่มเดียว: ตรวจไม่ซ้ำ binding; เลิก Pass ที่เมาส์กลาง; E กด/ปล่อยชาร์จส่งตามเดิมเมื่อไม่ได้ง้างยิง; อัปเดต HUD/คู่มือ. MMB ฝ่ายรับยังเป็น Cage Press ตาม Plan03.
- [x] T-14.2 ASSIGNED — Fake Shot: บนพื้นง้าง LMB ยิงตรงหรือ RMB ยิงปั่นค้าง แล้วกด E ให้ยกเลิกยิง/หลอกยิงทันที ไม่ส่งบอล; Server จบ intent เดิม ปล่อยเมาส์หรือ E ภายหลังต้องไม่ยิง/ส่ง/เริ่มชาร์จใหม่เอง ต้องกดใหม่เพื่อยิงครั้งต่อไป.
- [x] T-14.3 ASSIGNED — Fake Shot animation/คุมบอลหลบ: partial swing → หยุด/บังบอลด้วยเท้า → ออกท่าตามทิศ ใช้ท่าเดิมที่เหมาะหรือทำ revision ผ่าน Motion Tools (ตั้งต้น0.25–0.35s). คุมเฉพาะบอลที่ครองตาม dribble ปกติ ไม่ดูดบอล/วาร์ป/ล็อกฟิสิกส์/กันสกัด และไม่เพิ่มเป็น Skill slot ที่6; nonpossessor ไม่ได้ครองบอลฟรี.
- [x] T-14.4 ASSIGNED — Sกลางอากาศเพิ่ม loftเล็กน้อยตามสรีระ/ท่าสัมผัสจริง: shared config-driven computation จาก accepted smoothed lean/contact orientation, ยิ่งเอนมากค่อยเพิ่ม elevationแบบbounded ไม่fixed32/40/forcedfacing/highlob. คงฐานaim3D/yaw-momentumlock/neutral/energy/globalphysics; validHeader/Volley/Directเท่านั้น. ตรวจcontinuity/diagonal/nearvertical/camerayaw/contactheightและapexจริงตาม Plan03§G.1.
- [x] T-14.5 ASSIGNED — แยกความเร็วส่งกับยิงธรรมดาให้ชัด: neutral ground Pass ตั้งเป้าความเร็วจริง24–40studs/s เพื่อรับ/สกัดง่ายกว่า Direct เดิม; คิดจากสูตรชาร์จจริง ไม่แค่เปลี่ยนชื่อ constant. คง Pass3D ปุ่มเดียว/วิถีโด่งตามaim ไม่มี aim magnet หรือรับเข้าครองอัตโนมัติ.
- [x] T-14.6 ASSIGNED — Attacking miss recovery กันสแปม: เตะวืด/ไม่มี valid ball contact ทั้งพื้นและกระโดดยิง จูนให้ยาวอ่านออกตามOwner§F20/21 (ค่าเก่าground0.35sเร็วไป) พร้อมท่าเสียจังหวะ/slowdown และ Server gate ยิงซ้ำ/Skill/Dash/tackle/FakeShot bypass. ไม่ลงโทษลูกยิงที่สัมผัสบอลสำเร็จแต่ไม่เข้าประตู; ลงพื้น/ปล่อยปุ่ม/cancel/เปลี่ยนcontextต้องไม่ล้าง deadline.
- [x] T-14.7 ASSIGNED — Intent/cleanup/verification: FakeShot stale release/replay, recovery spamสลับLMB/RMB/E/Space, cancel/death/reset/generation, airwhiff→land→shoot, valid Passไม่ล้าง recovery และยังคง flight budget; ทดสอบจริง input→Server→ball พร้อม pass/loft/recovery metrics, boot/HUD/source parity. ส่ง implementation fix014 เชื่อม Plan03fix003 โดยไม่ซ้ำรายงานและไม่ปิดแผน.
- [x] T-14.8 ASSIGNED — Ownerชี้ท่าแก้แล้วตาม Plan03§F:4/7/11/20/21/23/24 และท่าใหม่FakeShot/activeairwhiff/contact ให้ขา-ลำตัวชัด/recoveryอ่านออก/clipกับServergateตรงกัน.22อธิบายlegacyunwired;35tentativeรอintegrationอนาคตไม่เปิดBicycle. เก็บacceptedFinesse/Trivela/fix012latchและbaseline/revisionแยกในlibrary.

**ข้อที่พัก/ถูกแทนชัดเจน:** X กลางอากาศพักไว้ก่อน. ข้อเสนอ S+RMB จักรยานอากาศยิงย้อนหลังถูกคำสั่งท้ายของ Owner แทนด้วย Sเอนหลัง→บอลโด่งไปหน้า (T-14.4); ห้ามนำกลับมา implement เอง. Plan04/GK ยังพัก.
- [x] T-11 PRIORITY§17/review007: F35 client getAimDirection แก้ต้นทาง camera yaw ใน air คืนเป้า 3D จริงทั้ง ground/air + real camera→payload→server→ball trace คง body lock/physics/BallPop ส่ง fix-010
- [x] T-10 OWNERDELTA§16: groundpersonalpossessorSpace=BallPopตามmovement/playergrounded;releaseSpace+pressใหม่เมื่อballfree=normaljump;คงballphysicsทั้งชุดเปลี่ยนเฉพาะinitialpoplaunch,ไม่auto-jump/แย่งball/เปิดSombreroSkill03;รวมในfix009
- [x] T-09 OWNERDELTA§15: adaptstate-basedcustomjump/singlelaunch+momentum/yawlock;mouseaim3Dยังได้;airreleaseหนึ่งครั้งต่อflight+softapexดีที่สุด กดได้ทั้งช่วงลอย;ไม่เพิ่มStyles/JumpMeter/SnakeJump;ทำหลังbaseline§13–14นิ่ง;รวมในfix009
- [x] T-08 OWNERDELTA§14: F-33W/Sworldtilt,F-34smoothlean;shotbase=aim3D+smallboundeddeviationแทนF0;ลดBloomซ้อน/Haze+ballNeonแบบpresentation-only คงyawlock/physicsgeometry;รวมในfix008
- [x] T-07 PRIORITY§13/review006: F-31InputControllerparseblocker+F-32AirLeanfixtureundefinedconstant;คืนdefaultClientboot/HUD/newbindingsและrealballinputก่อนงานอื่น ส่งfix008 ไม่ปิดแผน
- [x] T-06 OWNERDELTA§12: onebindingต่อaction;groundLMBDirect/RMBCurve,airLMBDirect/RMBVolley;A=Finesse/D=Trivela;airWASDlean+serverphysicsตามlockedfacing/pitch ไม่มีHeader/Bicyclefallback;ส่งfix007
- [x] T-05D: AGYส่งfix006movingjump/off-ballตาม§11แล้ว ยังรอCodexreview; temporaryHeaderเดิมถูกแทนด้วยOwner§12 ไม่กลับไปทำHeader;Plan02ยังOPEN/03รอฐานร่วม/04พัก
- [x] T-05C PRIORITY: Owner latest HANDOFF§10 — adaptprototype3jump/nativeimpulseและoff-ballfirst-timekick; reproduce input→server→ballจริงก่อนfix ไม่ทำระบบใหม่; currentHEAD e38e2f4+dirty ตรวจใหม่ก่อนเริ่ม
- [ ] T-05B: Owner Boost supplement ตามHANDOFF§9/review004: พิสูจน์disk→Edit→runningclient, แก้activeposepathsและเทียบภาพA01–18; Leadมีสิทธิ์scopedcommit/pushบนbranchงาน ไม่approve/close/merge/deploy
- [x] P-01: Ownerdeltaเดิม+คำยืนยันanimation/Shift Lock/ค่าต้นทางล่าสุดบันทึกในHANDOFF§7 ไม่ใช่อนุมัติปิดงาน
- [x] P-02: Controllerออกreview-002เทียบactualref/hashes/LiveEditSource9/9; เอฟเฟกต์เต็มไม่เป็นblocker02
- [ ] T-01: แก้F-20/F-24 lastteamเปลี่ยนเฉพาะconfirmedpossession และgroundrestไม่ลบvalidupwardrebound; รักษาcontacts/first-time
- [ ] T-02: แก้F-15/F-16/F-23 realjump lock/lifecycle/servermovementpriority; ใช้selectedSandboxparamsตาม§7 ไม่anchorroot/แก้rigschema
- [ ] T-03: แก้F-13/F-14 requiredmetadata/legacy/phase/activeintent-chargebinding; ยืนยันsingle3DPassและLobPassrejectไม่mutation
- [ ] T-04: แก้F-20/F-22/F-23 Slidehit/miss/serveroutcome/prediction/cancel/recovery; ไม่auto-possession/stun ไม่เปลี่ยนteamจากแค่เตะบอลหลุด
- [ ] T-05: แก้F-21และF-25..F-30 adaptArgonA01–18/variantsตามHANDOFF§8; singleposewriter/nativeclearance/state-contact/hold/cancel คงShiftLockL/Alt/shoulder/menu/focusและgameplayเดิม
- [ ] T-98: แก้F-17 freshcontract/behavior/LivePlay/pose/ShiftLock/cleanup/affected01regressionตามcurrenthashes ตอนนี้NOT RUN
- [x] T-99: syncOwnerdelta§12เฉพาะscopeที่อนุญาต ส่งassets/fix-007.mdฉบับเดียว เก็บfix001–006historical;รายงานGitSHA/hash/test/ข้อค้าง ไม่ปิดแผนเอง

## Review queue
- F-35 P1 OPEN: current5c33d5fclientairaimdiscardscamerayawก่อนส่งServer;ไม่ปิดจากsolverunitหรือ116PASSเดิม
- F-33 P1 OPEN: signedpitchทำWเอนหลัง/Sเอนหน้า;F-34 P2 OPEN: rawleancompositeหลังbaseLerpข้ามsmoothing. AimF0ถูกOwnerเปลี่ยนเป็นaim3Dแล้วตาม§14 ไม่อ้างchoiceเก่าบังคับต่อ
- F-31 P0 OPEN: duplicatechargetailInput345–347ทำให้Clientrequireที่65ล้ม/HUDไม่เริ่ม;F-32 P1 OPEN: fixtureRUN_SPEEDnil;F-17/F-18ยังไม่ผ่านจาก64PASSเดิม
- F-25..F-30 OPEN ตามreview-003: intermediateclearance/A05-A16runtime/stopcancel/airbornelanding/contactauthority/foot-slip; freshnative/Edit/Live/visualหลังadaptNOT RUN
- F-13..F-18 OPEN; F-20..F-24 OPEN ตามreview-002; F-21มีOwner visual REJECTED
- F-10/F-11/F-12/F-19ดีขึ้นในcodeแต่ไม่ใช้จำนวนtestsรับรองruntime/ปิดfindingทั้งข้อ
- fix-00240/40/243assertionsเป็นAGYreportedEdit; freshLivePlay/visual/01regressionหลังportยังไม่ยืนยัน ไม่ใช้fix-001ผลเก่าแทน
- fix-001/fix-002และreview-001/review-002คงhistorical ห้ามแก้คำตัดสินย้อนหลัง

## Owner delta — right-foot dominant & curve movement/freeze / fix-011 & fix-012

- [x] T-13: Implement HANDOFF §19 & §20: actual character-relative movement priority (`ResolveCurveSideFromMovement`) for right-foot Finesse (left/neutral) vs right-foot Trivela (right), signed lateral ball curvature (`-rightVec` Magnus direction so Finesse curls right-to-left and Trivela curls left-to-right), and initial RMB press curve-selection freeze (`chargeCurveSide`/`Style`/`Foot` latched on press, immune to mid-hold A/D switch, cleared on release/cancel/reset/context/death) while preserving accepted Finesse/Trivela R6 poses, 3D camera aim, airborne Volley, BallPop, and Plan 03 working tree. Completed in fix-012; Plan02 remains OPEN.
- [x] T-12: Implement HANDOFF §18: Plan02 right-foot character; A/left Finesse inside right foot, D/right Trivela outside right foot. Remove ball-side auto-left selection from active preview/server/animation flow. Verify left/center/right ball positions and movement intent with camera/yaw variations; preserve §17 aiming and airborne Volley. Completed in fix-011; Plan02 remains OPEN.

## Protection
- ปกป้องdirtyworkingtreeทั้งหมด; ไม่มีcommit/reset/revertอัตโนมัติ 00 OPEN / PAUSED_BY_OWNER,01 OPEN / PENDING_TECHNICAL_REVIEW
- Sandbox/reference/rig00/physics01/Network/.gitignore/notes01ที่encodingเสียยังread-only
- เพิ่มsourceได้เฉพาะCameraShiftLockController/R6ActionPoseController/PlayerActionPoseConfigsที่HANDOFF§7อนุญาตและใช้จริง
