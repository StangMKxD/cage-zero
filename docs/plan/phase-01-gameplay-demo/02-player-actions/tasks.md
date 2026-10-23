# Tasks — 02-player-actions / single bindings + air lean / fix-007

**IN_PROGRESS / CHANGES_REQUESTED — OWNER_VISUAL_REJECTED** · Owner Stang · Controller Codex · Implementer AGY Teamwork-preview
[Plan](plan.md) / [HANDOFF §8](assets/HANDOFF.md#8-owner-delta--argon-r6-football-animation-pack--2026-10-22) / [review-003](assets/review-003.md) / [review-002](assets/review-002.md) / [TDD](../../../tdd/master-test-cases.md)
Base SHA `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + current dirty-source lockในreview-003; Turn AGY / Manual dispatch ไม่มีauto-loop
Ownerdelta2026-10-22: ใช้ArgonR6Packเป็นต้นแบบvisualใหม่A01–18ตามHANDOFF§8; ง้างค้างไม่สับขา คงgameplay/ShiftLockเดิม ไม่รับรองPlayerZIPทั้งชุด; fix-003คงhistorical ส่งfix-004ใหม่
ยังเว้นท่าโยก/Poke/Shoulder; ไม่มีLobPassแยก; 00/01ยังเปิดและพัก

## งานส่งแก้
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
- F-33 P1 OPEN: signedpitchทำWเอนหลัง/Sเอนหน้า;F-34 P2 OPEN: rawleancompositeหลังbaseLerpข้ามsmoothing. AimF0ถูกOwnerเปลี่ยนเป็นaim3Dแล้วตาม§14 ไม่อ้างchoiceเก่าบังคับต่อ
- F-31 P0 OPEN: duplicatechargetailInput345–347ทำให้Clientrequireที่65ล้ม/HUDไม่เริ่ม;F-32 P1 OPEN: fixtureRUN_SPEEDnil;F-17/F-18ยังไม่ผ่านจาก64PASSเดิม
- F-25..F-30 OPEN ตามreview-003: intermediateclearance/A05-A16runtime/stopcancel/airbornelanding/contactauthority/foot-slip; freshnative/Edit/Live/visualหลังadaptNOT RUN
- F-13..F-18 OPEN; F-20..F-24 OPEN ตามreview-002; F-21มีOwner visual REJECTED
- F-10/F-11/F-12/F-19ดีขึ้นในcodeแต่ไม่ใช้จำนวนtestsรับรองruntime/ปิดfindingทั้งข้อ
- fix-00240/40/243assertionsเป็นAGYreportedEdit; freshLivePlay/visual/01regressionหลังportยังไม่ยืนยัน ไม่ใช้fix-001ผลเก่าแทน
- fix-001/fix-002และreview-001/review-002คงhistorical ห้ามแก้คำตัดสินย้อนหลัง

## Protection
- ปกป้องdirtyworkingtreeทั้งหมด; ไม่มีcommit/reset/revertอัตโนมัติ 00 OPEN / PAUSED_BY_OWNER,01 OPEN / PENDING_TECHNICAL_REVIEW
- Sandbox/reference/rig00/physics01/Network/.gitignore/notes01ที่encodingเสียยังread-only
- เพิ่มsourceได้เฉพาะCameraShiftLockController/R6ActionPoseController/PlayerActionPoseConfigsที่HANDOFF§7อนุญาตและใช้จริง
