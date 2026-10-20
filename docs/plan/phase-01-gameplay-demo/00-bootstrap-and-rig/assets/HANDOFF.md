# 00-bootstrap-and-rig — Custom R6 implementation contract

- **State:** LOCKED_SCOPE / PAUSED_BY_OWNER — “พักรอบ 00 ก่อน” หลังreview010; Round5 NOT DISPATCHED หยุดงานจนกว่าจะresume คงhistoricalgaprunแรกACCEPTED_GAP
- **Authority:** ผู้ใช้อนุญาต Codex ปรับแผน/architecture และตอบ “ใช้ R6 ตลอด Phase 1 (แนะนำ)” เมื่อ 2026-10-20
- **Design:** [plan](../plan.md), [tasks](../tasks.md), [architecture](../../../../design/architecture-and-network.md#5-phase-1-runtime--custom-r6) และ accepted decisions N-32/N-33
- **Owner:** Stang; **Planner/Reviewer:** Codex; **Implementer:** AGY Teamwork-preview; session e86ac30e-006d-4338-9a90-5f5e3b002028 / run-phase00-agy-impl-01; Codexไม่มีช่องdispatchตรง ผลกลับผ่านผู้ใช้
- **Baseline:** main @ `2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`; source ยังตรง `6d0f273dc...`
- **Implementation approval / P-03:** AUTHORIZED_FOR_00 — Stang สั่ง “เริ่มเลย” เมื่อ 2026-10-20 อนุมัติ AGY ทำ source/target Studio/verification ตามขอบเขต00 ไม่รวม01/07/Phase2
- **Governance:** OWNER_STANDARD; Turn=OWNER (Stang); PAUSED_BY_OWNER F18/F19ยังOPEN เก็บreview010และหลักฐานไว้ ไม่แก้/ทดสอบ/dispatchหรือปิด00ระหว่างพัก
- **Git:** ไม่อนุญาต local commit/push/merge/deploy รวมถึง commit เพื่อ SHA tracking; ส่ง working tree เท่านั้น ไม่เรียก subagent หรือส่งข้อความงานอื่นอัตโนมัติ
- **Protect:** .gitignore ที่เพิ่ม /sourcemap.json, เอกสาร/รีวิวที่แก้ค้าง, sourcemap.json, historical runs และ .sandbox/reference ทั้งหมด; ตรวจ git status อีกครั้งก่อนรับงาน

> ข้อความ baseline lock/ขั้นถัดไปเดิมเป็นประวัติก่อนรับงาน สถานะปัจจุบันใช้tasks/review008และOwnerdecisionท้ายสัญญานี้ scopeและruntimeacceptanceคงเดิม ยอมรับเฉพาะhistoricalStudio before-stategaprunแรก ไม่เริ่มแผนถัดไป

## อ่านก่อนเริ่ม

agent.md → docs/READ.md → plan/tasks/notes ของ 00 → architecture §5 → PRD/spec-03 §1/TDD Phase1/00; review-003 ใช้อ้าง sandbox snapshot เท่านั้น review-001..006 เป็นผลข้อเสนอ R15 ไม่ใช่ผล R6

## Scope ที่อนุมัติสำหรับ AGY

Custom R6 ของเกม, bootstrap ขั้นต่ำ, standard R6 locomotion, scale เดิม, spawn/respawn/race และ fixture ยืน/เดิน ไม่มีบอล/ดวล/Dash/โกล/กรง/UI/กาชา/เศรษฐกิจหรือ migration R15

### Source allowlist

| ไฟล์ | งาน |
| --- | --- |
| src/server/init.server.luau | Network.Init → RigAndCardService.Init ไม่ require MatchService |
| src/client/init.client.luau | Network.Init → R6AnimationController.Init ไม่รอ ui/controllers เก่า |
| src/shared/Network.luau | เพิ่ม Init(timeoutSec?) deadline รวม 10s; ไม่เปลี่ยน getters/Definitions/validators |
| src/shared/Constants.luau | ชื่อ R6 template, schema/profile, explicit floor/anchor config; คงค่าระบบอื่น |
| src/server/services/RigAndCardService.luau | R6 builder/scale/spawn/respawn/lifecycle; คง API ที่ consumers ใช้ |
| src/shared/configs/RigAnimationConfigs.luau (ใหม่) | R6 clip IDs/state profile/provenance ที่ตรวจได้จริง |
| src/client/character/R6AnimationController.luau (ใหม่) | ModuleScript ผูก local character generation/Animator/tracks/cleanup |

Types.luau และ CardConfigs.luau อ่าน/sync ตามเดิม ไม่แก้ในสัญญานี้ Default project mapping เดิมรองรับ source ใหม่ได้ ไม่แก้ build config
Docs ที่แก้ท้ายงานได้: เอกสารแผน 00 และ architecture/spec/TDD เฉพาะ delta จากผลงานจริง ห้ามขยาย requirement/เปลี่ยน Owner decision เพื่อให้เทสต์ผ่าน

### Studio allowlist — ต้องตรวจ target ใหม่

- เฉพาะฐานใหม่สำหรับ Cage Zero ที่ผู้ใช้ระบุ; Place1 เป็นชื่อ snapshot เดิม ไม่ใช่ Studio ID ถาวร
- shared source 5 จุด: ReplicatedStorage.Shared.Constants / Types / Network / configs.CardConfigs / configs.RigAnimationConfigs
- server 2 จุด: ServerScriptService.Server (Script, Legacy) / Server.services.RigAndCardService (ModuleScript)
- client 2 จุด: StarterPlayer.StarterPlayerScripts.Client (LocalScript) / Client.character.R6AnimationController (ModuleScript)
- สร้าง parents ที่ขาดตาม class/path เหล่านี้; class ชนกันให้หยุด ไม่แทนที่เอง
- ServerStorage.CageZeroStandardR6Rig และ descendants ที่ builder สร้าง; PRIMARY_FLOOR_PATH ชี้ Baseplate ที่ตรวจแล้ว หรือ BootstrapTestFloor/BootstrapSpawnLocation ที่สร้างในรอบนี้
- ห้ามเขียน/disable/move prototype sandbox place 112091950831355 และ ServerStorage.CageZeroDevelopment

## ลำดับงาน

1. **Preflight:** ใช้ P-03 จากคำสั่ง “เริ่มเลย” นี้ ไม่ถามอนุมัติเดิมซ้ำ; ตรวจ SHA/dirty files เทียบ baseline manifest และเก็บ pre-step state ก่อนเขียน ห้ามหยุด Play ของผู้ใช้เอง ตรวจ target Edit Studio ก่อนขั้น sync; ถ้ามีเพียง sandbox reference หรือ target ยังไม่เปิด ให้ทำ repo/source/asset research ที่ไม่พึ่ง target ต่อได้ และหยุดเฉพาะขั้นเขียน/Play ของ target ที่ยังระบุไม่ได้
2. **Bootstrap:** Network.Init ตรวจ folder/name/class ครบ 12 definitions ภายใน budget รวม 10s; client waits Shared/Network รวมอยู่ใน budget ไม่แก้ GetRemoteEvent/GetRemoteFunction หรือเปิดระบบ deferred
3. **R6 definition:** ยึด standard R6 topology/orientation จาก Roblox/native baseline ที่ตรวจได้ บันทึก base geometry/joints ใน source ไม่เปลี่ยน Enum บน R15
4. **Rig lifecycle:** template 6 body parts + HRP / 6 joints / Humanoid R6 / Animator / fixed face; PrimaryPart=HRP, root ไม่ Anchored; เปลี่ยน BuildStandardCustomR15Rig เป็น BuildStandardCustomRig พร้อมผู้เรียกภายใน service คง external API อื่น
5. **Scale/spawn:** BaseSize/BaseC0/BaseC1 คงที่แยก body/head; R6 standing height = Left Leg.Size.Y + HRP.Size.Y/2 + HipHeight; explicit primary floor/anchor และ footprint/raycast ต้อง valid-or-error ไม่คืน cutoff-Y/ตำแหน่งเดา
6. **Respawn:** player/character generation guard, died connection แยกจาก player listeners, timer เก่าห้ามทับ character ใหม่ และ PlayerRemoving ล้าง state; ไม่เปิด inventory/gacha handler ของ Phase 2
7. **R6 animation:** controller เป็น ModuleScript; server-created Animator ต้องอยู่ Workspace ก่อน client โหลดคลิป ตั้ง timeout และ per-character handle; รองรับ idle/walk/run/jump/fall ผ่าน standard R6 clips ไม่รับ animation pack ผู้เล่น ไม่เปิด controller ซ้อน Animate
8. **Clip provenance gate:** อ่าน official/native R6 reference ที่เข้าถึงได้ เก็บ IDs/state/provenance ใน RigAnimationConfigs ตรวจ compatibility/การโหลดจริงหลัง approval ถ้าไม่ยืนยันได้หยุดเฉพาะ asset step ไม่เดา IDs หรือสร้าง procedural controller ทดแทนโดยพลการ
9. **Sync:** source 9 จุดและ template/fixture ตาม owner ของขั้นนั้น อ่าน hash กลับและบันทึก post-state ครบ subtree ไม่ใช้ snapshot name/hash เก่าแทนการอ่านใหม่
10. **Verification + doc sync:** ตรวจ gate ด้านล่าง บันทึกผลเฉพาะที่รันจริง และส่ง working tree ให้ Codex review ไม่ปิดงานเอง

## Gates ที่ต้องรายงานผลจริง

| Gate | เกณฑ์ |
| --- | --- |
| V-01 | source 9/9 hash ตรง repo; template R6 topology/attributes/face/No Boots; ไม่มี avatar ส่วนตัว |
| V-02 | bootstrap ready รวม ≤10s, ไม่มี error จาก source รอบนี้; ไม่เปิด Match/Parry/UI/collection; controls/กล้องพื้นฐานทำงาน |
| V-03 | 4 presets ไป–กลับ 3 รอบ ตรวจ server sizes/C0/C1/rotations จาก base และ R6 ground clearance; drift tolerance 1e-4 สำหรับ static values |
| V-04 | idle/move/jump/fall เปลี่ยน pose จริงจาก R6 clips; client PostSimulation หลัง settle; server ตรวจ state/positions แยก ไม่เทียบ raw Transform ข้าม network |
| V-05 | ตาย/เกิด 3 รอบ, ตกนอก floor, timer race (สร้าง charB ระหว่าง old timer) และออกเกม; current generation ไม่ถูก old callback ทับ |
| V-06 | explicit floor อยู่ใต้จุดเกิดและห่างขอบตาม rig footprint; ไม่ spawn ใต้พื้นหรือบนลูกบอล |
| V-07 | no out-of-scope diff; source/runtime/asset/visual เป็นคนละผล ระบุ NOT VERIFIED ของสิ่งที่ไม่ได้ตรวจ |

- ตรวจ topology/scale ที่ R6 joints จริง ไม่ใช้ knees/elbows หรือ count 16/15 ของ R15
- movement probe รัน client ที่เป็น owner พัก/คืน default controls และ cleanup ในทุกทางออก timeout/fail; observer client เพิ่มเป็นหลักฐานเมื่อ session รองรับ ไม่อ้าง multi-client pass โดยไม่มีผล
- ถ้า rig invalid/asset load fail/source ชนกัน ให้ส่ง error/ค่าที่อ่านได้จริง ไม่เปลี่ยน acceptance ให้ผ่าน

## Rollback และ preservation

- Single writer ต่อ scope; เก็บ pre/post snapshots ของแต่ละขั้นใน .sandbox/rollback/<runId>/<stepId> โดยไม่ทับ reference เดิม
- ก่อนย้อนงานตรวจไฟล์และ instance ทั้งชุดว่า current ตรง post-state รวม subtree/children/properties หากต่างให้หยุดทั้งหมดก่อน mutate
- ไฟล์เดิม: คืน bytes จาก pre-snapshot ได้หลัง hash guard ทั้งชุดผ่าน; ไฟล์ใหม่: ลบเฉพาะของขั้นนั้น; ตรวจ final pre-hash/exists อีกครั้ง ไม่ใช้ HEAD เป็นจุดคืนงาน
- Studio: manifest ต้องมี descendants ทุกตัวที่สร้าง/แก้; หลัง preflight จึง restore/delete bottom-up ไม่ตรวจ parent เทียบ post-children ซ้ำหลังลบลูกเอง ตรวจ final pre-state ครบ
- ไม่ reset/checkout ทั้ง repo, ไม่ใช้ unsafe-paths, ไม่ลบ root/ทรัพย์สินผู้ใช้คำนวณโดยไม่ตรวจขอบเขต หากใช้ patch ให้เทียบ pre/post โดยตรงและยึด recipe F-10 ที่ตรวจแล้ว
- ส่ง diff/evidence และข้อจำกัดจริง ไม่มีสิทธิ์ commit/push หรือเปลี่ยน APPROVED/PASS/CLOSED แทน Owner

## ขั้นถัดไป

Stang อนุมัติ implementation แผน 00 แล้ว ผู้ใช้ส่ง prompt/HANDOFF นี้ให้ AGY บน local ได้ทันที AGY ใส่ session/run ID และเริ่มลำดับงาน 1 จากนั้นส่ง working tree/หลักฐานให้ Codex ตรวจ ไม่ถือว่าผ่านจากการอนุมัติเริ่ม แผน01/07ยังไม่เปิด implementation และ source ณ handoff ยังไม่ใช่ R6


## Baseline lock และพิกัดรับงาน

- Base SHA ตามหัวสัญญา; working-tree dirty snapshot/hash ของไฟล์ก่อนรับงานอยู่ `.sandbox/rollback/phase00-handoff-20261020/baseline.json` ตรวจ manifest นี้และ git status ก่อนแก้ ห้ามทับเอกสารค้างเพราะไม่ได้อยู่ใน commit
- Server pointers: `src/server/init.server.luau:12`, `src/server/services/RigAndCardService.luau:27` (schema), `:183` (builder), `:263` (scale), `:342` (spawn), `:439` (Init)
- Shared pointers: `src/shared/Network.luau:110`/`:146` (เพิ่ม Init โดยคง getters158/177), `src/shared/Constants.luau:12` (ชื่อtemplate/config)
- Client pointer: `src/client/init.client.luau:11` เป็นต้นไป (ถอด UI/controllers เก่า); source ใหม่สองไฟล์ตาม allowlist ยังไม่มี
- จัดกลุ่มงานต่อเนื่องโดย lead เดียว: S1 Network/Constants/server entry/Rig service → S2 clip config/client entry/animation module → S3 Studio/probes/doc sync ไม่มีสิทธิ์ spawn worker เพิ่มจากการแบ่งกลุ่มนี้
- V-01..V-07 ยัง NOT RUN ขณะ handoff; วิธีตรวจคือ targeted code review/Studio probes และ runtime/visual ตาม gates ไม่ต้องติดตั้ง test framework หรือรัน full-game suite ที่ยังเปิดระบบนอกscope
- หลักฐานส่งกลับ: session/run ID, actual HEAD/working-tree diff, source hashes, gateผลจริง/ข้อจำกัด และ notes/tasks อัปเดตเป็น READY_FOR_REVIEW เมื่อเสร็จ ห้ามตั้ง owner approval/closure เอง

## Correction Round 3 — Owner decision 2026-10-20

Stangตอบ “ยอมรับช่องว่างเดิม แล้วเก็บ baseline ใหม่ก่อนเดินต่อ (แนะนำ)” ในคำถามF18หลังreview008 อนุญาตเดินต่อเฉพาะcorrection00 ยอมรับเฉพาะStudio before-stateที่ขาดก่อนrunแรก ไม่ย้อนหลังสร้างประวัติ ไม่ปิดF18/F19/F20หรือruntimegate

1. อ่านreview008; preflightactualHEADปัจจุบัน (ล่าสุดf8729cc6e714f10a1cb60253a4f037d7c49f7505) พร้อมworking-tree hashes ไม่resetงานค้าง; commitf8729ccเป็นเอกสารสนามที่Ownerอนุญาตแล้ว
2. ก่อนmutateเก็บcurrentbeforeของfilesและStudioครบscopeในโฟลเดอร์correctionใหม่ใต้.sandbox/rollback/ ระบุactualStudioID/PlaceId/โหมดและเวลา Snapshotreview008เป็นreferenceไม่ใช่currentbeforeอัตโนมัติ; ล่าสุดtargeta9611fd4.../PlaceId137721422246269 Edit ต้องlist/getstateใหม่ก่อนใช้
3. F18: manifestจากreadbackจริง path/class/source/hash/properties/attributes/childsets/subtreeครบและcountตรง; pre/postต่อขั้นไม่ทับsnapshotเก่า เปรียบเทียบguardทั้งชุดก่อนrestore ไม่ย้อนจริงเพื่อพิสูจน์และไม่อ้างrepoก่อนrunเป็นStudiohistoricalbefore
4. F20: sync4sourceที่ต่างตามreview008จากrepoไปtargetdevelopmentที่ตรวจแล้ว ได้แก่RigAndCardService/init.client/R6AnimationController/RigAnimationConfigs จากนั้นreadbackSHAครบ9/9 ไม่publishหรือแตะreferenceplace112091950831355
5. F19: AGYรันruntimeV01–07ตามHANDOFFจริง รวมbootstrapelapsed/12remotes,4presetsไปกลับ3รอบอ่านsizes/C0/C1/rotations/groundclearance,loadedclipsและclientPostSimulationpose,controls/camera,death3รอบ/void/timerrace/leave,invalidfloorและcancelledsetup/failedasset; รายงานNOT VERIFIEDของกรณีที่sessionทำไม่ได้ ไม่ใช้Node72checksรับรองruntime
6. F13–17codeแก้แล้ว ไม่รื้อใหม่โดยไม่มีหลักฐาน failure; sourceแก้เพิ่มได้เฉพาะallowlist00เมื่อruntimeพบปัญหาในscope ไม่เปลี่ยนpublicgetters/Definitions/Types/CardConfigs/requirementเพื่อให้ผ่าน
7. ส่งassets/fix-008.mdหนึ่งไฟล์รวมทุกfinding พร้อมcurrenthashes/target/manifestpaths/gateผลจริงและข้อจำกัด แล้วnotes/tasksเป็นREADY_FOR_REVIEW ไม่มีสิทธิ์commit/push/merge/deploy/spawn/เริ่ม01/07/Phase2/ปรับchoice ไม่อ้างรับงานหรือรันแล้วจากสัญญานี้
