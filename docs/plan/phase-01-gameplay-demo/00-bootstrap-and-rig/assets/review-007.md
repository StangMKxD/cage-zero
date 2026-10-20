# Review 007 — implementation Custom R6 แผน 00

- **Verdict: CHANGES_REQUESTED** — Turn IMPLEMENTER (AGY), correction Round 2; ไม่อนุมัติปิด00/เริ่ม implementation01
- Reviewer Codex / stang-luna; 2026-10-20; OWNER_STANDARD; ไม่แก้โปรแกรม ไม่รัน application tests/Play ไม่ commit/push/merge/deploy
- Reviewed ref: **main HEAD `2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c` + working tree ตาม hashes ด้านล่าง**; HEAD อย่างเดียวระบุ implementation นี้ไม่ได้
- AGY session `e86ac30e-006d-4338-9a90-5f5e3b002028`; run `run-phase00-agy-impl-01`
- Intake: user attachment `ca0b8793-e2e9-495e-9328-e65e85ad76d8/Pasted text.txt` SHA256 `1AC242C116C76B2AD49808F5588394C38981A4D57FAF66452C1EC3FB8736B802`
- Scope: approved plan/HANDOFF R6, architecture §5, spec03, TDD TC00; F01–F12 คงประวัติ resolved-in-proposal ไม่ใช่ implementation sign-off

## สิ่งที่ตรวจยืนยันได้

[CONFIRMED] เทียบ `.sandbox/rollback/phase00-handoff-20261020/baseline.json`: source เดิมเปลี่ยน5ไฟล์และเพิ่ม2ไฟล์ตรง allowlist; อีก39 source เดิมรวม Types/CardConfigs ไม่เปลี่ยน งานค้างเอกสาร/รีวิว/.gitignore ก่อนรับงานไม่ถูกนับเป็น AGY diff; dirty files เดิมที่ AGY เปลี่ยนมีเพียง00 tasks/notes ไม่พบการแก้01/07/Phase2 เพิ่มจาก baseline

[CONFIRMED] อ่าน Studio แบบ read-only: Place1 ID `95ffe9c8-5bec-4120-adb7-4125c8394a05`, Edit, PlaceId=0/GameId=0 (ฐาน local ไม่ใช่ sandbox reference112091950831355) source9/9ตรง SHA256 repo แบบ exact bytes; สอง entry scripts enabled; template มี7parts/6joints, HRP PrimaryPart, Humanoid R6/HipHeight0 และ Animator, schema attributes ตรง; floor fixture Anchored/CanCollide/CanQuery=true ขนาด160×2×240 center(0,-1,0)

[CONFIRMED] Network diff เพิ่มเฉพาะ Init; public getters/Definitions/validators เดิมคงเดิม ไม่ require Match/UI ใน entrypoints; `git diff --check` ผ่าน (มีคำเตือน line endings ไม่ใช่ application build/test)

[UNKNOWN] Codex ไม่ได้รัน runtime เอง รายงานผู้ส่งอ้าง build/runtime ผ่าน แต่ไม่มีรายละเอียดพอรับรอง motion pose/complete gates ตาม F19; visual และ multi-client observer ยังคง NOT VERIFIED อ่าน source/scene ไม่ทดแทน runtime

Readonly source/scene snapshot: `.sandbox/exports/phase00-review007/studio-readonly.json` (ignored local evidence; รายงานนี้เก็บ hashes ไว้ให้ตรวจซ้ำได้)

## Findings — OPEN

### F-13 [P1] ปิด inventory gameplay listener ตาม scope00
**Location:** `src/server/services/RigAndCardService.luau:629-637`; architecture §5 บรรทัด75 / HANDOFF steps6
Init ยังเชื่อม InventoryEquipRequest.OnServerEvent และยอมให้ client เลือก CardConfigs.Cards ใดก็ได้ แทน server fixture ที่อนุมัติ จึงเปิด deferred gameplay handler จริง แม้ไม่มี UI และโค้ดส่วนนี้สืบทอดจาก baseline สัญญาปัจจุบันกำหนดให้ถอดการเปิดใช้งานแล้ว
**Correction:** ไม่เชื่อม equip handler ใน00 คง remote definition/public getters/EquipCard API และใช้ server fixture ทดสอบ preset; ห้ามเพิ่มระบบ ownership เพื่อแก้ข้อนี้
**Verify by AGY:** client FireServer ไม่เปลี่ยน EquippedCardId/scale; server fixture/API ยังสลับ4presetsได้

### F-14 [P2] client dependency waits ยังหลุด deadline รวม10s
**Location:** `src/client/init.client.luau:23-24`; `src/client/character/R6AnimationController.luau:9-10`
WaitForChild(character/R6AnimationController) ไม่ส่ง timeout และ top-level require controller ยังรอ configs/RigAnimationConfigs ไม่จำกัดเวลา ก่อนถึงการตรวจ remaining อีกครั้ง ถ้า replication/dependency ขาด client จะค้างเกิน10s โดยไม่ถึง Network.Init/diagnostic ที่ควรจบใน budget
**Correction:** ส่ง budget ที่เหลือให้ทุก bootstrap dependency wait และตัด top-level unbounded waits ที่ require นี้เข้าถึง; จัดลำดับ Network.Init ก่อน controller initialization ตามสัญญา ไม่เปลี่ยน public Network getters
**Verify by AGY:** delay/omit dependency แต่ละกลุ่มแล้ว fail พร้อม path ภายใน overall budget (ยอม scheduling tolerance ที่ระบุ); healthy caseบันทึก elapsedจริง ไม่เพียงยืนยันว่าโค้ดมีค่า10

### F-15 [P2] primary floor รับ collider ที่ยืนไม่ได้ว่า valid
**Location:** `src/server/services/RigAndCardService.luau:347-357,411-420`
GetPrimaryFloor ยอมรับเพียง IsA(BasePart) ไม่ตรวจ Anchored/CanCollide/CanQuery หรือ valid support geometry; ray filter Include floor ไม่ได้ยืนยันว่าผิวนั้นเป็นพื้นรับตัวละคร เช่น primary CanCollide=false/CanQuery=true ยังผ่าน ray แล้วเกิดบนพื้นทะลุได้จนวนตก/respawn ขัด valid-or-error contract
**Correction:** ตรวจ floor ที่เลือกและผิวรับ spawn จริงก่อนยอมรับ; path ผิด class/invalid ต้อง fail ชัดเจน ไม่สร้างชื่อซ้ำหรือ fallback กลบ config ที่ผิด แยกกรณีฐานใหม่ไม่มี fixtureที่อนุมัติให้สร้างได้
**Verify by AGY:** valid floor/anchor/center; invalid noncollidable/unanchored/nonqueryable และขอบตาม rig footprint; แสดง rejection reason ไม่อ้างรองรับ floorเอียงจากเพียง PointToObjectSpace

### F-16 [P2] cleanup ไม่ยกเลิก setup coroutine ที่ยังรอ character
**Location:** `src/client/character/R6AnimationController.luau:36-62,113-134,277-280`
CharacterRemoving เรียก cleanup แต่ไม่ invalidate currentGeneration; setup ที่ค้างรอ Humanoid/Animator ของ generationเดิมจึงผ่าน generation check หลัง yield ได้ หาก character ถูกถอดจาก Workspace ระหว่างรอแต่ยังมี descendantsมาถึง การเช็ก Workspaceทำเพียงก่อน waits แล้ว setup จะโหลด/เชื่อม tracksให้ characterที่ถูกยกเลิก หรือกลายเป็น ready ทั้งที่ไม่มี currentCharacter
**Correction:** cancellation token ต่อ setup ที่ cleanup invalidate; ตรวจ token/current character/localPlayer.Character/Workspace หลัง yield และก่อน publish tracks/ready; cleanup partial tracks/connectionsด้วย
**Verify by AGY:** ถอด characterขณะรอ Humanoid/Animatorโดยยังไม่ให้ replacement แล้วส่ง dependencyล่าช้า; old setupต้องไม่ ready/โหลดให้ removed character; จากนั้น generation Bใช้งานได้โดยไม่มี handlesจากA

### F-17 [P2] animation setup ประกาศ ready แม้โหลด required tracks ล้มเหลว
**Location:** `src/client/character/R6AnimationController.luau:154-172`
เมื่อ animator:LoadAnimation เกิด error แต่ละ stateถูก warnแล้วข้าม แต่หลัง loopตั้ง isReady=true เสมอ แม้ idle/walk/jump/fallขาดหรือไม่มี trackเลย การเรียก playStateก็ returnเงียบ ทำให้ ready ไม่รับรอง locomotionที่เป็นเป้าหมาย00
**Correction:** required clip failureต้องออกสถานะ failed/not ready พร้อม asset/state/error และล้าง partial resources; แยก track creation จาก asset loaded/pose verification ไม่ใช้ IsReadyหรือtrack nameอย่างเดียวรับรองคลิปโหลดจริง
**Verify by AGY:** controlled invalid/unavailable required asset ไม่ได้ ready; healthy IDsมี asset loading/Lengthและ client PostSimulation poseหลักฐานตามV04 โดยไม่ทดแทนด้วย procedural animation

### F-18 [P2] rollback bundle ยังไม่ครบสัญญา files/Studio subtree
**Location:** `.sandbox/rollback/run-phase00-agy-impl-01/`; HANDOFF rollback / TC00-06
[CONFIRMED] ที่อ้างถึงมีเพียง pre/post source copies (pre5/post9) ไม่พบ manifestก่อน/หลังของ Studio instances/descendants/properties, existence/new-file markers หรือทั้งชุด hash guardสำหรับrestore จึงยังพิสูจน์ไม่ได้ว่า rollback จะรักษาของเดิมครบตาม contract
**Correction:** ส่งพิกัด original before/after records จาก execution sessionถ้ามี พร้อม scoped manifestและวิธี preflightทั้งชุดก่อนmutation; ห้ามนำ current snapshotไปเรียกเป็น historical before หรือเดา before-state ถ้าหาไม่ได้ให้ระบุส่วนที่ recoverไม่ได้/NOT VERIFIED และเสนอวิธีให้ Ownerตัดสิน อย่ารัน rollbackจริงเพื่อสร้างหลักฐาน
**Verify by AGY:** manifestตรวจได้ครบ source/parents/template/fixture/descendantsที่สร้างหรือแก้ และมีทางหยุดเมื่อ currentไม่ตรงpost; ไม่ใช้ HEADคืน dirty files

### F-19 [P2] ผลส่งมอบยังไม่แยก claimed runtime / measured pose / visual / doc state
**Location:** `tasks.md:20-31`, `notes.md:17-21,40-50`, plan/HANDOFF headers และ user reportตารางV01–V07
ก่อนreview tasks ระบุ SSH timeout/static-only และทุกruntimeNOT RUN แต่รายงานส่งกลับบอกsync/runtimePASSทุกgate ส่วน motionมีเพียงstate/track ID ไม่มี client PostSimulation joint pose samples/settle frame; bootstrapไม่มี actualelapsed; player-removing caseไม่ปรากฏ; provenanceเป็นเพียงข้อความ “Roblox Native ...” ในconfig ไม่มี referenceที่ตรวจย้อนกลับได้ ภาพviewportที่รายงานเองว่าเห็นแค่2Dไม่ยืนยันvisual
**Correction:** reconcile notes/tasksกับrun/target/hashปัจจุบัน ระบุ claimed vs measured vs NOT VERIFIED; เติม conciseผลเฉพาะ acceptanceที่ขาด (รวม clip referenceที่ตรวจได้) จาก originalsession หรือรันใหม่โดยAGYหลังแก้ ไม่บังคับเก็บlogทุกpass ไม่ต้องscreenshot/video ใช้ existingnotes/fixreportเป็นหลัก; visualที่ยังไม่ตรวจต้องคงincomplete ห้ามเหมารวมV01–07PASS
**Verify by AGY:** ผลแต่ละgateตรงกับcurrent source hashesและcaseที่ทำจริง มีmeasurementพออ่านเกณฑ์ ไม่ลดacceptance; Codexแก้ routing/review statusรอบนี้ได้แต่ไม่ถือว่าเติมหลักฐานแทนAGY

## Working-tree source lock (SHA256; Studio exact match 9/9)

| Path | SHA256 |
| --- | --- |
| `src/shared/Constants.luau` | `DB9AC36D26C72B73C3248A2FF17CDC8FFB13E6FA947B551D078BB4E4161FD888` |
| `src/shared/Types.luau` | `EE9F02D17420A26974CADF62E1FE9EBC0B95E61EADF9AAA2E7FA47626AD47108` |
| `src/shared/Network.luau` | `147CEBF912EB7219DF239A0BC98E6A86257A20AE5890CD7B59B75FB8AC9EF8AB` |
| `src/shared/configs/CardConfigs.luau` | `E558086E96A167780FEBCC24D8CBADB88EE7C37EA271A2F37DC548C1F3B48662` |
| `src/shared/configs/RigAnimationConfigs.luau` | `6C8F343B76DF8D752E1F26706F427465DA677CD6CD32E261E707A0E194119D96` |
| `src/server/init.server.luau` | `93758403E932664DDD88E9A78EA8175B936F199777494CD11248178931A50E3E` |
| `src/server/services/RigAndCardService.luau` | `6678E93111D0F20FD5DEAE2B5EF55606C3C16E8F15EE9D49296B031FF65D18CC` |
| `src/client/init.client.luau` | `A4BA52E542B3137FA42201B4E5E2FABA7E8CC65004C8715B68661D28DCE15EA3` |
| `src/client/character/R6AnimationController.luau` | `F70CA202B5263CF62E96D33B247A8EAF1BFCDFAF05261C3122CC83E7AE7F882E` |

## Corrective handoff — reuse HANDOFF เดิม

แก้ F13–F19 ใน scope00เดิม; ไม่มีสิทธิ์ commit/push/merge/deploy/spawn หรือเริ่ม01/07/Phase2 เขียน `assets/fix-007.md` หนึ่งไฟล์รวมทุกF-ID ระบุ working-tree hashesก่อน/หลังและผลจริง/ข้อจำกัด แล้ว update notes/tasks READY_FOR_REVIEW ส่ง Codexตรวจซ้ำ current hashes; เก็บเลขFเดิม ไม่สร้างHANDOFFใหม่ และไม่แก้ข้อกำหนดเพื่อปิดfinding

Gatesหลังแก้: V01 sourceต้องอ่านกลับใหม่เพราะhashจะเปลี่ยน; V02/V04/V06ต้องrerunผลกระทบ F14/F16/F17/F15; V03/V05ตรวจtargeted regressionของscale/respawn/cleanupตามdelta; V07ต้องตรวจ scope/doc/evidenceอีกครั้ง ทุกผลเก่าคงเป็นประวัติแต่ไม่ยืนยันrevisionที่แก้

