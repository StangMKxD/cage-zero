# Tasks — 02-player-actions / Boost visual rework / fix-005

**IN_PROGRESS / CHANGES_REQUESTED — OWNER_VISUAL_REJECTED** · Owner Stang · Controller Codex · Implementer AGY Teamwork-preview
[Plan](plan.md) / [HANDOFF §8](assets/HANDOFF.md#8-owner-delta--argon-r6-football-animation-pack--2026-10-22) / [review-003](assets/review-003.md) / [review-002](assets/review-002.md) / [TDD](../../../tdd/master-test-cases.md)
Base SHA `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + current dirty-source lockในreview-003; Turn AGY / Manual dispatch ไม่มีauto-loop
Ownerdelta2026-10-22: ใช้ArgonR6Packเป็นต้นแบบvisualใหม่A01–18ตามHANDOFF§8; ง้างค้างไม่สับขา คงgameplay/ShiftLockเดิม ไม่รับรองPlayerZIPทั้งชุด; fix-003คงhistorical ส่งfix-004ใหม่
ยังเว้นท่าโยก/Poke/Shoulder; ไม่มีLobPassแยก; 00/01ยังเปิดและพัก

## งานส่งแก้
- [ ] T-05B: Owner Boost supplement ตามHANDOFF§9/review004: พิสูจน์disk→Edit→runningclient, แก้activeposepathsและเทียบภาพA01–18; Leadมีสิทธิ์scopedcommit/pushบนbranchงาน ไม่approve/close/merge/deploy
- [x] P-01: Ownerdeltaเดิม+คำยืนยันanimation/Shift Lock/ค่าต้นทางล่าสุดบันทึกในHANDOFF§7 ไม่ใช่อนุมัติปิดงาน
- [x] P-02: Controllerออกreview-002เทียบactualref/hashes/LiveEditSource9/9; เอฟเฟกต์เต็มไม่เป็นblocker02
- [ ] T-01: แก้F-20/F-24 lastteamเปลี่ยนเฉพาะconfirmedpossession และgroundrestไม่ลบvalidupwardrebound; รักษาcontacts/first-time
- [ ] T-02: แก้F-15/F-16/F-23 realjump lock/lifecycle/servermovementpriority; ใช้selectedSandboxparamsตาม§7 ไม่anchorroot/แก้rigschema
- [ ] T-03: แก้F-13/F-14 requiredmetadata/legacy/phase/activeintent-chargebinding; ยืนยันsingle3DPassและLobPassrejectไม่mutation
- [ ] T-04: แก้F-20/F-22/F-23 Slidehit/miss/serveroutcome/prediction/cancel/recovery; ไม่auto-possession/stun ไม่เปลี่ยนteamจากแค่เตะบอลหลุด
- [ ] T-05: แก้F-21และF-25..F-30 adaptArgonA01–18/variantsตามHANDOFF§8; singleposewriter/nativeclearance/state-contact/hold/cancel คงShiftLockL/Alt/shoulder/menu/focusและgameplayเดิม
- [ ] T-98: แก้F-17 freshcontract/behavior/LivePlay/pose/ShiftLock/cleanup/affected01regressionตามcurrenthashes ตอนนี้NOT RUN
- [ ] T-99: แก้F-18 provenance/state/evidence/docscope ส่งassets/fix-005.mdฉบับเดียว เก็บfix-004historical; รายงานGitSHAs/branch/ข้อค้างตาม§9 ไม่ปิดfindingเอง

## Review queue
- F-25..F-30 OPEN ตามreview-003: intermediateclearance/A05-A16runtime/stopcancel/airbornelanding/contactauthority/foot-slip; freshnative/Edit/Live/visualหลังadaptNOT RUN
- F-13..F-18 OPEN; F-20..F-24 OPEN ตามreview-002; F-21มีOwner visual REJECTED
- F-10/F-11/F-12/F-19ดีขึ้นในcodeแต่ไม่ใช้จำนวนtestsรับรองruntime/ปิดfindingทั้งข้อ
- fix-00240/40/243assertionsเป็นAGYreportedEdit; freshLivePlay/visual/01regressionหลังportยังไม่ยืนยัน ไม่ใช้fix-001ผลเก่าแทน
- fix-001/fix-002และreview-001/review-002คงhistorical ห้ามแก้คำตัดสินย้อนหลัง

## Protection
- ปกป้องdirtyworkingtreeทั้งหมด; ไม่มีcommit/reset/revertอัตโนมัติ 00 OPEN / PAUSED_BY_OWNER,01 OPEN / PENDING_TECHNICAL_REVIEW
- Sandbox/reference/rig00/physics01/Network/.gitignore/notes01ที่encodingเสียยังread-only
- เพิ่มsourceได้เฉพาะCameraShiftLockController/R6ActionPoseController/PlayerActionPoseConfigsที่HANDOFF§7อนุญาตและใช้จริง
