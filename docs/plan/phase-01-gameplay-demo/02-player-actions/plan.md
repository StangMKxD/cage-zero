# 02-player-actions — บอล การเคลื่อนที่ และปุ่มตามทีม

> **Owner visual delta 2026-10-22:** ใช้ Argon R6 Football Animation Pack เป็นต้นแบบรูปลักษณ์ใหม่ของ A01–A18 ตาม [HANDOFF §8](assets/HANDOFF.md#8-owner-delta--argon-r6-football-animation-pack--2026-10-22) และ [review-003](assets/review-003.md). แทนเฉพาะการบังคับรูปลักษณ์จาก Sandbox ที่ขัดกับแบบใหม่ คง R6 schema/gameplay/physics/keymap/Shift Lock เดิม; ง้างค้างไม่สับขา. ZIP เป็น reference ไม่ใช่โค้ดพร้อมติดตั้งหรือผลผ่าน Runtime; ส่ง fix-004 โดยไม่ปิด findings เดิมหรือขยาย scope จาก preview timings.

- **State:** IN_PROGRESS / CHANGES_REQUESTED — OWNER_VISUAL_REJECTED; [สถานะงาน](tasks.md)
- **Owner:** Stang; **Controller:** Codex; **Implementer:** AGY Teamwork-preview
- **Authorization:** คุณ Stang สั่งเริ่มงาน 02-player-actions ได้เลย (แผน 01 พักรอ technical review ภายหลัง โดยยังไม่ปิดแผน)
- **Baseline:** `main` @ `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + working tree ตาม AGY fix-002 และ source lock ใน review-002; รักษาข้อแก้เดิมและงาน 00/01
- Prerequisite [01-cage-physics](../01-cage-physics/plan.md); [Phase1](../plan.md) / [Spec02](../../../specs/spec-02-duel-and-parry.md) / [Architecture](../../../design/architecture-and-network.md#6-continuous-football--q22)

## Scope/เจ้าของ

- บอลจริง/การเลี้ยง/ครอง/ปล่อย/รับ/deflect และทีมที่ครองสำเร็จล่าสุดเป็นข้อมูลคนละส่วน BallServiceเป็นsingle writerของบอล
- เดิน/Sprint/Dash/Stamina/Shift Lockคงไว้; กระโดดล็อกทิศเคลื่อนตัวก่อนขึ้น เปลี่ยนกลางอากาศไม่ได้ รองรับHeader/Volley/Blockตามcontactจริง
- ยิงตรง/ยิงโค้งปุ่มแยก/Passแบบเดียวเล็ง3DและปรับแรงจากSandbox; ไม่มีปุ่ม/action LobPass แยก ให้พลิกแพลงวิถีจากPassปกติ ชาร์จแล้วยังเคลื่อนที่/เล่นกลางอากาศได้ตามเงื่อนไข โดยชาร์จแล้วเคลื่อนช้าลง
- ทีมครองล่าสุดใช้ยิง/ส่ง/ยิงโค้ง; อีกทีมใช้SlideจากSandboxรอบนี้ ส่วนPoke/Shoulderทำภายหลังใน03 ทั้งทีมคงปุ่มบุกตอนบอลอิสระหลังยิง/ส่ง/ชิ่ง สลับเฉพาะเมื่ออีกทีมครองสำเร็จ
- Phase1เล่นบอลจังหวะแรกได้ไม่ต้องจับครองก่อน แต่ต้องอยู่ในระยะสัมผัส/เงื่อนไขบอลจริง ปุ่มยิงของเพื่อนที่ไม่มีบอลไม่ทำให้ยิงจากระยะไกลได้
- รับบอลพื้นที่รับไหวเข้าpossessionได้ ลูกแรง/สูงโดนตัวเด้งอิสระ ไม่มีI-frameหรือการซ่อนhitboxระหว่างDash/Skill
- Staminaเป็นทรัพยากรร่วมให้03ใช้: ต้องจ่ายไหวก่อนออกท่าที่มีต้นทุน ล้ายังเดิน/ยิง/ส่ง/ยืนตัดบอลได้ แต่เลี้ยงแตะห่างขึ้น ไม่มีสุ่มบังคับเสียบอล
- เตรียมtraining fixtureระบุinitialball/ทีม/จุดเริ่ม/รีเซ็ตและinput/HUDขั้นต่ำให้ตรวจได้ ไม่รอfullUI08หรือเปิดMatchService

## Seam กับ03/04/05/06/08

- 03เรียกผ่านบอล/possession/contactและทรัพยากรร่วม02 ไม่เขียนผู้ครองบอล/คูณmovement statsซ้ำ
- 03เป็นเจ้าของSkill5ท่า/3ช่อง/Poke/Shoulderภายหลัง; รอบ02รับselective portของSlideผ่านresource/contactownerเดิม ไม่ทำSlideซ้ำใน03และไม่เปิดChoice/Feintเดิม
- โกล04ใช้กติกาในเขตของตนต่อจากบอลนี้ ไม่เอากติกาผู้เล่นสนามไปแทนการรับมือของโกล
- 05ตัดสินฟาวล์/ลูกนิ่งตามcontactsที่ตรวจได้; 06overrideค่าจูนเฉพาะtestsession; 08แสดงcontextและสถานะจากServer
- Network/Types migrationต้องระบุexactcontract/allowlistในHANDOFFของแผนก่อนแก้ ไม่เปลี่ยน12definitions/gettersของ00ระหว่างเก็บงาน00

## Acceptance

- บอล/ผู้ครอง/ทีมโหมดบุกไม่ค้างเมื่อปล่อย/ชิ่ง/บล็อก/รับ/เปลี่ยนทีม/reset/death/leave
- inputเดิมไม่กลายเป็นสไลด์กลางคันเมื่อcontextสลับ Serverreject/cancelเมื่อเงื่อนไขไม่ครบ
- first-timeยิง/ส่งเล่นได้ทั้งบอลเข้าและบอลชิ่งจริง; blockersยังสัมผัสได้ ไม่มีการรับประกันเข้าประตูหรือauto-catchบอลแรง
- DirectionalJumpเปลี่ยนทิศกลางอากาศไม่ได้; Sprint/Dash/cost/exhaustionตรวจServerและแยกจากvisual
- ใช้source/hashปัจจุบันตรวจruntime ไม่ใช้เพียงsnapshot/JSsimulationรับรองผล; syncdocs/TDDแล้วส่งreview

## Deferred

[Phase2](../../phase-02-full-match-and-progression/plan.md)รับแอนิเมชันยิง/ส่งจังหวะแรกพร้อมเสียจังหวะเมื่อวืด ต้องเปิดimplementationplanก่อนทำ ไม่เป็นเกณฑ์Phase1; สุ่ม/Statsหลายตัว/ownership/ระบบตั้งค่าถาวรไม่อยู่02 งาน00ไม่ขยาย

## Owner delta — Sandbox adaptation ต่อจาก AGY fix-001 (2026-10-21)

- Ownerยืนยันดึง sprint/dash/kick/pass/ยิงโค้งและเกจชาร์จ **เว้นท่าโยก**; “ดึงระบบslideมา แต่จะทำpoke shoulderทีหลัง”; รายงานAGYที่แนบเป็นฐานให้ปรับเพิ่ม ไม่ใช่ให้ย้อนกลับsourceรอบแรก
- ใช้ส่วนที่เลือกจาก `.sandbox/prototype3/` ตามรายงาน ปรับเข้ากับCustom R6/BallServiceเดิม ต้นทางSandboxและimmutableReferenceเป็นread-only ไม่ยกทั้งโปรเจกต์
- รักษาonGround/rollingrest, cameraDash+Knock-on Dashเดิม, StateChangedjump, servercharge, finite/lifecycleguardsและTrainingHUDจากfix-001; ไม่เพิ่มKnock-onซ้ำหรืออ้างว่าส่งมอบHeavyKnockOnskill03
- ย้ายsegmented charge gauge/controlsขั้นต่ำมา02ก่อนfullUI08ตามคำสั่งนี้ ไม่เปิดFullUI/Dummytools/score/Match/economyหรือeffectpacksจากSandbox
- ฝ่ายบุกยังใช้ยิง/ส่ง/โค้งแม้ไม่มีบอลส่วนตัว ห้ามเอาเงื่อนไขSandbox “ไม่มีบอล=Slide” มาแทนteamcontext; Slideต้องservervalidatecost/CD/contact/recovery ไม่มีI-frameหรือauto-stun/auto-possession
- ใช้keymapfix-001: Q/F Dash, C/G/MMB Pass, E/LMB ShootหรือSlideตามcontextตอนเริ่ม, R/V/RMB Curve, SpaceJump, Xtrainingreset; ถอนT/LobPass ไม่เปลี่ยนintentกลางhold
- ตัวเลขเดิมเป็นค่าจูน: ดิสก์fix-001 Walk16/Sprint24/Dash46; HIGH_JUMP_POWER65ไม่ใช่ความเร็วแนวราบ65 เกณฑ์Headerเดิม3.2เป็นstudsไม่ใช่เมตร
- เกณฑ์เพิ่ม: Passแบบเดียวเล่นได้หลายมุม/แรง, legacyLobPassreject, segmentedgaugeตรงserverchargeและcancelครบ, Slidehit/miss/near-miss/ground-air/cost/CD/recovery/cleanupจริงบนR6
- Codexตรวจlocalhashรายงานใหม่ตรง8/8 แต่ยังไม่รับรองผล34/34/141/141หรือLivePlay; หลังportต้องตรวจfreshตามHANDOFF ทุกgateใหม่NOT RUN ไม่ปิดF-10..F-19จากclaimsCLOSEDในfix-001
- ขอบเขตลงมือ/contract/allowlist/sourcehashอยู่[HANDOFF](assets/HANDOFF.md); ส่งfix-002ฉบับเดียว ไม่commit/push/merge/deploy งาน00/01ยังพักและเปิดตามเดิม

## Owner visual directive — 2026-10-21 / ต่อจากfix-002

Ownerแจ้งanimationยังไม่ผ่าน ยืนยันShift LockแบบSandbox และให้ยึดค่าต่างๆ/จังหวะที่Sandboxทำไว้ดีแล้วก่อนจูนต่อใน02; [HANDOFF§7](assets/HANDOFF.md#7-owner-locked-r6-animation--shift-lock-adaptation--2026-10-21)มีอำนาจแทนคำแนะนำเดิมที่ให้คงค่าปัจจุบันเมื่อไม่จำเป็นต้องเปลี่ยน
ต้องportselectedproceduralR6posesของSprint/Dash/kick/Pass/curve/Slideจากprototype3 พร้อม8waystrafeและShiftLockเริ่มON/LหรือAlttoggle/shoulder(1.75,0.45,0)/cursor/menu/focuscleanup ไม่ใช้jumpclipเปลี่ยนชื่อเป็นSlideหรือชื่อ12tracksเป็นเกณฑ์ผ่าน
ใช้statepriority/pose-camera-rotationownerเดียว ปรับmappingจากR15ลง6Motor6Dเดิม ไม่เปลี่ยนrigschema/anchorroot/เปิดballwriterใหม่ ตัวเลขตั้งต้นจากselectedSandboxparamsในHANDOFF§7ไม่ใช่finalbalance
review-002คือCHANGES_REQUESTED: F-13..18และF-20..24ยังต้องแก้และตรวจfresh แม้localreporthashes9/9และStudioEditSource9/9ตรงกัน ไม่มีการรับรองผล40tests/LivePlayหรือปิดfinding
เอฟเฟกต์เต็มที่มีแผนเจ้าของ07/08/Phase2รอตามแผนเดิมได้ ไม่เป็นblockerของ02; selectedactionhelperเล็กทำได้เท่าที่scopeเดิมอนุญาตโดยไม่เปิดpack/ownership
