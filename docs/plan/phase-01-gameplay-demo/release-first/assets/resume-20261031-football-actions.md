> **RESUMED:** Owner said ทำต่อ on2026-10-31. Checkpoint22c3731 complete; current work is right-foot hitbox tuning. Follow current tasks.md and football-hitbox-report-001.md; pause details below are history.

# จุดทำต่อ — พักตาม Owner 2026-10-31

เมื่อ Owner เปิด session เดิมแล้วพิมพ์ **ทำต่อ** ให้ทำงานตามบริบทนี้ต่อ ไม่ถามให้เล่าใหม่ ไม่มอบงานให้ AGY (Owner สั่ง Root ทำเอง)

## สถานะและลำดับที่ต้องรักษา

PAUSED_BY_OWNER. ห้ามทำงานต่ออัตโนมัติจน Owner บอกทำต่อ. ยังไม่มี commit ใหม่ของงานรอบนี้ และยังไม่ได้เริ่ม hitbox. คำสั่ง Owner คือ **commit งานเปลี่ยนอนิเมชั่น/ยิง/ส่ง/กลับตัวให้เสร็จก่อนเริ่มระบบ hitbox**. ไม่ push/publish. เก็บโค้ดเดิมเป็น comment และรักษา dirty files เดิม

1. เปลี่ยนยิงใช้ Motion asset `0a38ab54-20b0-4a2e-a540-847aa0a8b6da` (StrikeFowardJog v2)
2. กลับตัวขณะ sprint ใช้ `fcecd793-16d1-47fb-b4e0-8f4d9819640a` เฉพาะทิศตรงข้าม W→S / A→D และคู่กลับกัน หรือเมาส์หันแรง. โค้ดเริ่มจูน keyboard179.9°, mouse110°ภายใน0.25s, clipเล่นจบใน0.7s. 90°ยังลดความเร็วเดิมแต่ไม่เล่นท่ากลับตัว
3. เดินเลี้ยงใช้ `69f7c65f-4959-47c5-8e12-7deff157295e` (JogForward v2)
4. วิ่งไม่มีบอลและวิ่งเลี้ยงใช้ `c63773e9-fb88-4394-8fab-90f97527655c` (FastRun v2)
5. ระบบส่งใช้ `a35ae5a3-0737-4b19-beaf-9f82c78e26de` (SoccerPass v2). Owner เลือก **E ค้างง้าง ปล่อยส่ง**
6. ท่าง้างยึดช่วงต้นคลิปนั้น ๆ. แก้ prechargeก่อนบอลมา: Beginได้แม้ยังไม่มีบอล, Release รอบอลเข้าเท้าได้1sก่อนเล่นเตะ. ยังต้องตรวจจริงว่ารับ/ส่ง/ยิงสำเร็จเมื่อบอลมาช้าและเมื่อมีบอลอยู่แล้ว ไม่แย่งบอลที่คู่แข่งถืออยู่
7. หลังตรวจและcommitข้อ1–6แล้ว จึงทำ hitboxด้านหน้าplayerเท่านั้น แสดงให้เห็นระยะที่เตะได้ และยิงแป๊กจากมุม/ขอบสัมผัส. Owner ยืนยัน **แรงลดและทิศคลาดตามด้านที่สัมผัส**. ยังไม่ได้ลงมือข้อ7

## งานที่ลงมือแล้ว (ไม่ใช่ technical signoff)

- ใหม่: `src/shared/FootballClipReferenceData.luau` snapshot exact5assetข้างต้นแบบcompact94KB, `FootballAnimation.luau` Build/Sample/FK, `FootballActionRules.luau`, `configs/FootballActionConfigs.luau`, `client/controllers/ReverseTurnAnimationController.luau`
- แก้ ShotController รองรับE/Shot/Pass chargeและWaitingBall, BallService state machine/nonce/finiteaim/ชนเท้าก่อนปล่อยบอล, ShotModel samplingคลิปเดียวกันserver/client; SprintSpeedRules/SprintService reverseevent; locomotion/dribble helpers/configs/bindingsและbootstrap
- Shared clips sourceเวลาง้าง Shot0.3s, Pass0.367s; releaseRate1.4. จังหวะสัมผัส sourceShot0.433–0.48, Pass0.50–0.55. ต้องทดสอบฟีล/บอลจริงก่อนยืนยัน
- Sourceเดิมเก็บcomment. Backupก่อนแก้ `.sandbox/before-football-actions-20261031/src` และ tracked.patch
- Rojo build `.sandbox/football-actions-before-hitbox.rbxlx` PASS; diffcheck src PASS
- Actual Studio cloned-module checks: FootballActions2744 assertions PASS, existingSprint34 PASS. ต้องรันใหม่หลังแก้เพิ่มเติม
- Sync/compile/exact readback16ไฟล์ผ่าน (ล่าสุดรวม marker2ตัวของเดิน/วิ่งเลี้ยงแล้ว). `.sandbox/football-action-files.json` / sync-football-actions.cjs
- Actual E input test no-ball: Charging→WaitingBall→Whiff→Complete, Pass_standing/release weight1. **ยังไม่ได้พิสูจน์กรณีมีบอลยิง/ส่งสำเร็จจริง**
- รอบPlayแรกพบ Walk/RunDribble ไม่ผ่านvalidationเพราะขาดTouchL/R; เติมmarkersในDribbleAnimationHelperและExpectedMarkerCount2แล้ว แต่ยังไม่ได้ทดสอบPlayใหม่หลังแก้
- Edit requirecacheมีModuleที่เคยfailจากsource truncatedก่อนcompact; อย่าตีความ cached error เป็นผลsourceปัจจุบัน. latest helper validation probeล้มด้วยrequested module experienced error; ต้องอ่านstackให้ชัด/ใช้freshcloneครบdependenciesหรือfreshPlay. อาจเหลือ `ServerStorage.FootballChecks` และ `StarterPlayer.StarterPlayerScripts.Client.character.FootballHelperProbe` จากfailedprobe ให้ตรวจและล้างเฉพาะของทดสอบก่อนทดสอบ/บันทึกplace
- ShotConfigsยังมีlegacytimingfieldsที่ไม่ตรงFootballActionRulesใหม่ ควรปรับ/อธิบายconsumerให้ชัดก่อนcommit. Runtimeใหม่ใช้FootballActionRules/Configsเป็นหลัก
- ก่อนcommitตรวจdiffและdependencyให้self-contained. มี dirty sourceก่อนเริ่มจำนวนมาก; ไม่ใช้git add . เหมารวม .gitignore, outputagy, generated artifacts หรือ AGY tests ที่ไม่เกี่ยวข้อง

## Studio ค้าง: หลักฐานและการกู้สถานะ

- Studioล่าสุด id `4ea9947f-aee2-49e4-b8d3-294d5ebcb4ce`, Cage-Zero137721422246269;ต้องlistสดทุกครั้ง. process20784 at01:44:25. ตอนพักกลับEditและตอบสนองได้แล้ว ไม่มีการkillStudio
- StopPlayใช้270225ms (~4m30s). log RAM available781MBระหว่างStop /2599MBหลังเสร็จ, ServerStorage16996instances. มีMotionwidgetduplicatewarning แต่ยังไม่พิสูจน์ว่าเป็นตัวทำให้Stopช้าโดยตรง
- Editก่อนcleanupมี406329instances /373840Poses /276KFS. Workspace previewRig190852descendants (AnimSaves86children/94940descendants และbackupfoldersอีกหลายชุด). PluginGuiมีMotionEditorRigclone190787descendants
- พบสาเหตุการcloneบวมใน `C:/Users/Stang/AI-Tools/motion-tools/studio/Preview.lua:16`: model:Clone() เอาAnimSaves/backupไปด้วย. ยังไม่ได้patchtoolsourceหรือinstallpluginใหม่ ปัญหาสามารถเกิดซ้ำถ้าเปิดpreviewผ่านโค้ดเดิม
- Auto-reviewปฏิเสธล้างpreviewครั้งแรก; Ownerต่อมาชัดเจนอนุญาต **ล้างเฉพาะสำเนาพรีวิว**. จากนั้นลบเฉพาะKFS/CurveAnimationใต้PluginGuiService WorldModel/MotionEditorRig130sequences /190532instances สำเร็จ; sourceRigก่อน/หลัง190852เท่าเดิม, totalเหลือ215797. RAMworkingSetลดจาก~2.83GBเป็น~2.60GB. ไม่มีsourceAnimSaves/backupถูกลบ
- อย่าเปิดหนัก/cloneพรีวิวซ้ำก่อนตรวจresource. หากแก้toolcloneให้ทำแบบไม่คัดลอกanimationstorageตั้งแต่ต้นและคงsource/unsaveddraft; ไม่ติดตั้งpermanentpluginหรือแก้globalMCPโดยพลการ

## Motion Tools cleanup ที่เสร็จแล้วก่อนงานนี้

- library103→29: Mixamo v2ทั้งหมด15 +runtimeที่ใช้อีก14. เก็บpinnedce84fc90และ0a38ab54. สำรองhashverifiedครบ103ที่ `.sandbox/motion-library-backup-20261031-011134`
- APIverify29/pinsครบ/removed74ไม่อยู่. `.sandbox/motion-library-cleanup-verified.json`
- Place1เป็นgame.Nameเดิม แต่placeIdเป็นCage-Zeroถูกอยู่แล้ว แก้ชื่อEditเป็นCage-Zeroแล้ว. ห้ามไปแก้Placeอื่น
- Nodebridgeเดิมอาจยังรัน; localMotiontokenห้ามแสดง. CLI `C:/Users/Stang/AI-Tools/motion-tools-control.mjs status --place 137721422246269`

## เครื่องมือของรอบนี้

- `.sandbox/prepare-football-clips.cjs` อ่านexactlibraryIDsสร้างsnapshot; อย่าสุ่มเอาv3แทน
- `.sandbox/wire-football-bindings.cjs`, `wire-server-actions.cjs` **รันแล้ว ห้ามรันซ้ำ** (จะarchive/patchซ้ำ)
- `.sandbox/football-source-server.cjs` readonly localhost18769ใช้syncsourceผ่านHttpService;หยุดเมื่อพักแล้ว ต้องเปิดใหม่เฉพาะเมื่อต้องsync. จำกัดอ่านsrc/*.luau ไม่ใช่serverเผยแพร่
- `.sandbox/sync-football-actions.cjs` สร้างsyncเฉพาะไฟล์ที่ต่างจากbeforebackup พร้อมcompile/readbackguards;ตรวจโค้ดก่อนรัน
