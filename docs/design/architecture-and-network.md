# Architecture & Network Contract — Cage Zero

> Current scope: [Phase 1](../plan/phase-01-gameplay-demo/plan.md) ใช้ R6; Stang สั่ง “เริ่มเลย” เมื่อ 2026-10-20 อนุมัติ AGY implementation เฉพาะ [แผน00](../plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md) sourceอยู่ระหว่างcorrectionตามtasksของ00 ส่วน01–09และ [Phase 2](../plan/phase-02-full-match-and-progression/plan.md) ยังไม่เปิด implementation; localcommitเอกสารตามคำสั่งล่าสุดในagent.md ไม่มีsource/push/merge/deployapprovalใหม่

## 0. Source baseline และ Studio MCP
- Source baseline ใน Git คือ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182` มีไฟล์หลายโมดูลอยู่แล้ว การมีโค้ดหรือสถานะ APPROVED เดิมยังไม่ใช่หลักฐานว่าแผนรอบปัจจุบันผ่านการอนุมัติ
- Prototype ที่ผู้ใช้ทดลองใน Studio คือ `FootballSandbox` ใน `sandboxcage-zero` (place `112091950831355`) ใช้ซอร์สคนละชุดกับ `src/`; ต้องเทียบ behavior ก่อนนำมาใช้ ไม่เพิ่มทุกพฤติกรรมของ prototype ลง PRD โดยอัตโนมัติ
- เก็บ sandbox เป็น local reference ใน root `.sandbox/` และ ignore ด้วย `/.sandbox/`; snapshot แรกมี 7 สคริปต์พร้อม manifest ที่ `.sandbox/reference/football-sandbox/` ส่วน `.sandbox/football-sandbox/` เป็น ref ที่มีการแก้ต่อจากภายนอกรอบนี้
- เมื่ออนุมัติลงมือแล้ว ใช้ Studio MCP โดยตรงและเก็บ source หลักใน repo ตรวจ source/path/hash ก่อนเขียน Studio ทุกครั้ง; ไม่ใช้ Rojo เป็นขั้นตอนหลัก
- แยกแพ็กเกจ/fixture ทดลองจาก gameplay ของผู้ใช้ และไม่หยุด Play หรือเขียนทับ source ที่มีการแก้ค้างโดยอัตโนมัติ
- โค้ด/เทสต์ที่ Codex ทำเกินขอบเขตรอบก่อนถูกเก็บที่ `.sandbox/plan1/implementation-attempt/` แล้วคืน source หลักกลับ baseline; ผล 24/24 เป็นหลักฐานของงานทดลองนั้น ไม่ใช่การตรวจรับ Plan 1
- แพ็กเกจ `ServerStorage.CageZeroDevelopment` ที่สร้างไว้เป็น ModuleScripts ทดลองที่ยังไม่เชื่อมกับ gameplay; ไม่ถือเป็น source หลักหรือ release ที่ผ่านอนุมัติ

## 1. เจ้าของระบบใน target architecture
- Server: rig lifecycle/config และผล gameplay/validation ของบอล/Skill Moves/เกมรับ/โกล/ลูกนิ่ง; ไม่เริ่ม MatchService/economy เพื่อให้ Phase 1 ฝึกได้
- Client: native input/กล้อง/visual และ R6 animation playback ไม่ตัดสินการครองบอล/ผลcontact/รางวัลเอง
- Shared: constants/types/config/network definitions; ระบบเก่าใน source ไม่ใช่ target feature ที่อนุมัติทั้งหมด
- avatar locomotion ใช้ native client controls/replication; server เป็นเจ้าของ rig/config และตรวจ gameplay ในแผน 02 ไม่บังคับ server network ownership ทุกตัวเพียงเพื่อให้ตรงคำว่า authoritative

## 2. สัญญา Network ใน baseline (`src/shared/Network.luau`)
ตารางนี้เป็น contract เดิมที่ยังอยู่ใน source ไม่ใช่ contract ใหม่ที่ผ่านการออกแบบครบหลัง grill โดยเฉพาะ Parry/Duel/Choice ที่ถูกแทนตามQ22; แผนที่เลือกลงมือต้องตรวจ/แก้ contract ให้ตรง decisions ก่อน ห้าม reuse endpoint เดิมผิดความหมายหรือเพิ่มเองโดยไม่ระบุในแผน:

| ชื่อ RemoteEvent / Function | ชนิด (Type) | ทิศทาง | พารามิเตอร์ที่ส่ง (Payload) | โมดูลที่ใช้งาน |
| :--- | :--- | :--- | :--- | :--- |
| `BallActionRequest` | `RemoteEvent` | Client -> Server | `(actionType: "Pass" \| "Shoot" \| "Sprint", aimVector: Vector3)` | Module 02 |
| `ParryWindowTrigger` | `RemoteEvent` | Server -> Client | `(ballId: string, windowDuration: number)` | Module 02, 07 |
| `ParryAttemptRequest` | `RemoteEvent` | Client -> Server | `(clientTimestamp: number)` | Module 02 |
| `DuelStartEvent` | `RemoteEvent` | Server -> Client | `(duelId: string, role: "Attacker" \| "Defender", availableChoices: {string}, lockedChoices: {string}, timeLimit: number)` | Module 03, 07 |
| `DuelChoiceSubmit` | `RemoteEvent` | Client -> Server | `(duelId: string, selectedChoiceId: string)` | Module 03, 07 |
| `DuelResultEvent` | `RemoteEvent` | Server -> Client | `(duelId: string, winnerUserId: number, cutsceneAnimId: string, appliedBuff: string?)` | Module 03, 04, 07 |
| `FreeKickStartEvent` | `RemoteEvent` | Server -> Client | `(spotPosition: Vector3, timeLimit: number)` | Module 04, 07 |
| `FreeKickSubmit` | `RemoteEvent` | Client -> Server | `(aimDir: Vector3, spinOffset: Vector2, powerPercent: number, timingZone: "Green" \| "Yellow" \| "Red")` | Module 04, 07 |
| `MatchEventBroadcast` | `RemoteEvent` | Server -> Client | `(eventType: "PillarLockdown" \| "BlackoutVoid" \| "FavelaAlley", state: "Warning" \| "Active" \| "Ended", payload: any)` | Module 05, 07 |
| `InventoryEquipRequest` | `RemoteEvent` | Client -> Server | `(category: "Card" \| "Thread" \| "Trait" \| "Celebration", itemId: string, slotIndex: number?)` | Module 06, 07 |
| `SummonRequest` | `RemoteFunction` | Client -> Server | `(bannerId: string, count: 1 \| 10)` -> คืนค่า `{ObtainedItems}` | Module 06, 07 |
| `TradeActionRequest` | `RemoteEvent` | Client -> Server | `(tradeId: string, action: "AddItem" \| "LockOffer" \| "ConfirmTrade" \| "Cancel", itemUid: string?)` | Module 06, 07 |


## 3. Architecture ของแผน 01 — Cage profiles A/B/C

- ผู้ใช้เพิ่ม 3 profiles เพื่อเทียบทดลอง: A กล่อง4ผนัง/flat roof, B ปาด4มุม8ผนัง/flat roof, C ใช้8ผนังเดียวกับB/ขอบหลังคา45°; ยังไม่เลือก winner/default map
- ผู้ใช้ยืนยัน physicsจริง + markerไกด์ ไม่มีแรงนำบอลเข้าประตู ข้อความหักเข้าหน้าโกล/ตกจุดนัดพบเป็น hypothesis ต้องวัด ไม่เป็น force rule
- CagePhysicsService เป็นเจ้าของ ArenaGeometry catalog ของ activeVariantId: polygon, finite wall/roof faces, normals, thickness, surface IDs, material response, goals/transom, ramps, bumpers และ markers
- visual builder/collision solver/ramp queries อ่าน catalog เดียวกัน; C ต้องรวม central roof/8 bevel faces/corner seams ไม่มีผิวหายหรือ colliderเพดานซ้อนใต้bevel
- เสนอ builderกลาง BuildCageArena(parent?, variantId) แทนชื่อผูก Hex; อัปเดต call sites ภายในscopeเมื่อimplement ไม่สร้าง wrapper ซ้ำถ้าไม่มีconsumerจริง และคง collision/query APIs เว้นมีdeltaระบุชัด
- root model `Workspace.HexCageArena` คงเป็น legacy stable path พร้อม CageVariantId attribute; floorยังเป็น CageFloor ให้ R6 spawn contract ใช้ ไม่ตีความ8/6ด้านจากชื่อroot
- config defaultsร่วม: X±80/Z±120, floor0, max roof32, radius1.25; B/C เสนอ cut20, C bevel width/drop8 ที่45° ขนาดเหล่านี้เป็น design defaults ไม่ใช่ค่าผลิตภัณฑ์หรือ runtime result
- แยก shape pass (ปิด event/boost/lift), mechanics pass (เปิดทีละรายการ), และ event pass ใน07; เก็บ profile/config/launch/dt/seed พร้อม metrics เปรียบเทียบอย่างควบคุมตัวแปร
- bumper nominal1.25/target25% speed gainก่อนspeed cap, ramps25° และ back zone14 คงตามscope ไม่ทำaim assistหรือเพิ่ม responseซ้ำกับengineโดยไม่ตั้งใจ
- swept sphere/time-of-impact ต้องใช้radius/remainingdt/finite bounds และstep budget; ชุดเร็วสูง/corners/grazing/multiple contacts/ceiling seamsเป็นgate แสดงขอบเขตที่ทดสอบ ไม่อ้างzero clippingทุกความเร็วจากclamp/build
- BallService ใน02เป็นเจ้าของบอล/possession; 01ใช้ launch fixtureวัดcollision ไม่เปิด MatchService/goal scoring/Header/Volley gameplayเพื่อทดสอบสนาม
- base rebound5รายการและmapตารางละเอียดอยู่ [plan01](../plan/phase-01-gameplay-demo/01-cage-physics/plan.md); events pillar/ripple/moving signsอยู่ [plan07](../plan/phase-01-gameplay-demo/07-dynamic-field-events/plan.md)
- 07จัดการ transient surfaces/moving propsบนserverและคืนสภาพตามtimeline clientvisual; surface velocity/contact timeของป้ายแกว่งต้องรวมในresponse ไม่อ้างว่าstatic plane solverครอบคลุมของเคลื่อนที่แล้ว ไม่สร้างendpoint/event streamนี้ใน01

## 4. ลำดับและขอบเขตตาม phase
- ใช้โฟลเดอร์แผนจริงใน [Phase 1](../plan/phase-01-gameplay-demo/plan.md) และ [Phase 2](../plan/phase-02-full-match-and-progression/plan.md) ไม่ใช้ชุดรหัส feature แยก
- Phase 1 ใช้ Custom R6 ตลอด phase ตามคำตอบผู้ใช้ 2026-10-20; แผน 00/01 เป็นฐาน Rig/สนาม/physics, 02 บอล/movement, 03 Skill Moves/เกมรับ, 04 โกล, 05 ลูกนิ่ง, 06 ซ้อม/หุ่น, 07 อีเวนต์, 08 gameplay UI และ 09 UAT
- Phase 2 แผน 00/01 แมตช์/ตัดสินเสมอ, 02 transactions, 03 สุ่มตัวละครและ stats ชุดเล็ก, 04 สุ่มสกิล/collection/เศรษฐกิจ, 05 เอฟเฟค, 06 ตลาด, 07 meta UI และ 08 full integration/UAT; transactions เป็นฐานก่อนรายการ Cash/ไอเทม
- โกล/ลูกนิ่ง/อีเวนต์ใน Phase 1 ใช้ controller ฉากฝึกเท่าที่จำเป็น ไม่ดึง full match clock/result/รางวัลของ Phase 2 มาทำก่อน
- การ์ดกาชา/collection/meta UI ที่เคยอยู่แผนคร่อม phase แยกเป็นแผนเฉพาะแล้ว เอฟเฟคสองชุดไม่มีสเตตัสและขายผ่านแผงเท่านั้น สกิลยิง/ส่งที่ตัดไม่กลับมาจาก base stats นักเตะ
- รูปแบบกติกาและ delta จาก spec เดิมดู [accepted decisions](../plan/phase-01-gameplay-demo/01-cage-physics/notes.md); sync ส่วนที่ทำก่อน implementation ไม่ลบฟีเจอร์ที่เลื่อนไป phase ถัดไป
- Phase 2 เริ่มได้เมื่อ Phase 1 เสร็จครบและผ่าน gate เท่านั้น รายงานเก่าไม่ใช้ข้าม gate


## 5. Phase 1 runtime — Custom R6

ผู้ใช้ยืนยันเมื่อ 2026-10-20 “ใช้ R6 ตลอด Phase 1 (แนะนำ)” เป็น accepted design และต่อมาสั่ง “เริ่มเลย” อนุมัติ implementation เฉพาะแผน00ให้ AGY ตาม HANDOFF การกลับ R15 ใน Phase 2 ไม่ใช่งานที่อนุมัติแล้ว

### Bootstrap และเจ้าของโมดูล

- แผน 00 server: Network.Init → RigAndCardService.Init; client: Network.Init → R6AnimationController.Init ไม่ require UI/InputController/MatchService เก่า
- Network.Init(timeoutSec?) ตรวจ folder/12 remotes ตาม name/class ด้วย deadline รวม 10s; client ส่ง bootstrap budget ที่เหลือเข้ามา คง getters/validators/Definitions เดิม
- rig service เป็นเจ้าของ template, player/character generation, scale, safe spawn และ respawn; client module เป็นเจ้าของ tracks/cleanup ของ local character
- source ใหม่ที่จำเป็น: `src/shared/configs/RigAnimationConfigs.luau` (R6 clip profile/provenance) และ `src/client/character/R6AnimationController.luau` (ModuleScript lifecycle) ไม่เพิ่ม procedural locomotion framework
- ใน 00 ไม่เปิด InventoryEquipRequest/Summon/Trade gameplay handlers; server fixture สลับ preset ทดสอบได้โดยไม่ทำ ownership/UI Phase 2

### Rig contract ที่ทุกแผนของ Phase 1 ใช้

| เรื่อง | Target contract |
| --- | --- |
| Template | ServerStorage.CageZeroStandardR6Rig สร้างจาก source/definition คงที่ ไม่ load user appearance |
| Parts | HumanoidRootPart, Torso, Head, Left Arm, Right Arm, Left Leg, Right Leg รวม 7 BaseParts |
| Joints | 6 Motor6Ds: RootJoint, Neck, Left Shoulder, Right Shoulder, Left Hip, Right Hip ตาม standard R6 orientation; Head เชื่อม Torso |
| Root | เกมกำหนด Model.PrimaryPart=HumanoidRootPart และตรวจ Humanoid.RootPart; root ไม่ Anchored |
| Identity | IsStandardCustomRig=true, UsesPlayerAvatar=false, RigProfile=R6, RigSchemaVersion=1 |
| Appearance | fixed anime face/ไม่มี boots; ไม่ห้าม meshes หรือเสื้อผ้าที่ถูกสเปกทั้ง class |
| Presets | 0.92/0.98/1.03/1.08 เดิมจาก CardConfigs; เริ่ม Ronan_TierB ไม่เพิ่ม selection UI/กาชา |
| Scaling | BaseSize/BaseC0/BaseC1 เก็บก่อนปรับครั้งแรก body/head scale แยก ปรับจาก base เสมอไม่คูณสะสม |

คง SpawnCustomRigForPlayer/EquipCardForPlayer/GetEquippedCardId/GetEquippedCardConfig ที่ระบบอื่นเรียก เปลี่ยน builder ที่ชื่อผูก R15 เป็น BuildStandardCustomRig พร้อมผู้เรียกใน service เดิม ไม่สร้าง alias ชื่อ R15 ที่แอบคืน R6 และไม่แก้ Ball/Duel/FreeKick ในแผน 00

R6 ground height ใช้ `Left Leg.Size.Y + HumanoidRootPart.Size.Y/2 + HipHeight`; HipHeight เป็น relative offset ของ template R6 ไม่คัดค่า `2.0*heightScale` ของ source R15

แผน 02/03/04/05/06 อ้าง root/state และ R6 schema ไม่สมมติ RightFoot/UpperTorso/knee/elbow; GK และหุ่นที่ใช้ player rig ใช้ schema เดียวกัน ไม่คัดลอก R15 dummy ทั้งระบบจาก sandbox

### Animation และ character lifecycle

- ใช้ R6 standard clips สำหรับ idle/walk/run/jump/fall; walk/run อาจใช้ clip เดียวปรับ speed ตามมาตรฐานที่ตรวจ ไม่ตีความว่าแผน 00 ต้องสร้าง Sprint/Dash
- Server สร้าง Animator, parent rig เข้า Workspace และตั้ง player.Character ก่อน client โหลด tracks
- R6AnimationController.Init ผูก current character/CharacterAdded รอ RigProfile/RigType/Humanoid/Animator แบบมี timeout; มี handle ต่อ generation และล้าง tracks/connections เมื่อ character เปลี่ยน/ถูกทำลาย
- เก็บ controller เป็น ModuleScript ใต้ Client.character ไม่วาง Animate LocalScript template ให้รันผิด parent; ใช้ controller เดียวไม่เปิด Animate ซ้อน
- clip IDs/source ต้องมี provenance จาก Roblox/native R6 baseline ที่ตรวจได้ บันทึกใน RigAnimationConfigs; ไม่เดา R15 IDs หรือใช้ animation pack ส่วนตัว
- asset loading/compatibility เป็น preflight/runtime gate ของ implementerหลัง approval ไม่ใช่คำถามผลิตภัณฑ์ที่ต้อง grill ใหม่ ถ้าขาดให้หยุดเฉพาะ asset step พร้อมเหตุผล
- native controls/กล้องพื้นฐานยังทำงาน ไม่เปิด cutscene/UI ของแผนอื่น; timer จาก dead character ต้องไม่เกิดใหม่ทับ current generation และ PlayerRemoving ล้าง state

### Floor/spawn seam — 00 ต่อ 01

- Constants กำหนด explicit PRIMARY_FLOOR_PATH และ optional PRIMARY_SPAWN_PATH ไม่กวาดทุก collider
- 00 เลือก Baseplate ที่ผ่านเกณฑ์หรือสร้าง BootstrapTestFloor/BootstrapSpawnLocation ในฐานใหม่; fixture เสนอขนาด 160×2×240 ที่ (0,-1,0) ไม่สร้างกรง/โกล/bumper/ramp
- footprint/edge clearance มาจาก floor/rig bounds; filtered ray Include floor เดียว ตรวจผิวบน จุดผู้เล่นเดิมที่ยังมีชีวิต → anchor → center; ไม่ผ่านให้ error ชัด ไม่คืน world-Y เดา
- root spawn height ใช้สูตร R6 ข้างต้นบวก clearance แล้วรอ settle
- 01 สร้าง HexCageArena ก่อน Rig.Init แล้วเปลี่ยน PRIMARY_FLOOR_PATH ไป Workspace.HexCageArena.CageFloor; bootstrap เพิ่มเฉพาะ CagePhysicsService ไม่เปิด MatchService
- การ retire fixture 00 ทำได้เฉพาะส่วนที่เป็น owner ของขั้นนั้นตาม handoff 01 พร้อม before/after/rollback ไม่ลบ Baseplate ผู้ใช้เหมารวม

### Source/Studio และ verification

- canonical sync 9 Source instances: Shared.Constants/Types/Network/configs.CardConfigs/configs.RigAnimationConfigs; Server กับ services.RigAndCardService; Client กับ character.R6AnimationController
- source อยู่ repo; manifest เก็บ class/path/properties/attributes/hash และ descendants ของ template/fixtureทุกตัว ตรวจ targetใหม่ ไม่ใช้ Studio ID เก่าเป็นสิทธิ์เขียน
- rollback preflight ทั้งชุดก่อน mutate แล้ว restore/delete bottom-up และตรวจ final pre-state; เมื่อมีงานแทรกให้หยุดก่อนเปลี่ยนแปลง
- static scale ตรวจ server; dynamic pose ตรวจ client PostSimulation หลัง stabilization แยก server state ไม่เทียบ raw Transform ข้าม network
- 00 ตรวจ client+server ของ session ที่มีจริง; observer อีก clientตรวจเมื่อพร้อมหรือใน 09 UAT บันทึก pending หากยังไม่มีหลักฐาน ไม่อ้าง multi-client pass
- asset/source/runtime/visual เป็นคนละ gate; snapshot sandbox และข้อเสนอ R15 เก่าไม่รับรอง R6 อัตโนมัติ

แหล่ง API: [Humanoid](https://create.roblox.com/docs/reference/engine/classes/Humanoid), [HipHeight](https://create.roblox.com/docs/reference/engine/classes/Humanoid#HipHeight), [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator#LoadAnimation), [Use animations](https://create.roblox.com/docs/animation/using)

## 6. Continuous football — Q22

**Decision Accepted / Delivery Planned, 2026-10-20** ผู้ใช้ยืนยันQ1–Q22ให้ปรับเอกสารตาม [Spec02](../specs/spec-02-duel-and-parry.md) ไม่มีimplementationใหม่และไม่เปลี่ยนสัญญา00 §5

### Ownership / dependencies

| เจ้าของ | รับผิดชอบ | ใช้ร่วม/ไม่ทำซ้ำ |
| --- | --- | --- |
| 01 CagePhysics | geometry/finite surfaces/ball collision kernel | 02ใช้catalog/solverเดียว; ไม่มีpossessionใน01 |
| 02 Ball/player actions | ball state/ผู้ครองจริง/ทีมโหมดบุก, move/Sprint/Dash/jump, aim/ยิงส่ง/first-time, Stamina | เป็นsingle writerของบอล/ทรัพยากร; 03ร้องขอcontactและจ่ายcostผ่านseamนี้ |
| 03 Skill Moves/defence | catalog5ท่า/3ช่อง/ดาว, Poke/Slide/Shoulder, action/CD/recovery, R6ท่าร่าง | ไม่ทำBallServiceหรือStaminaอีกชุด ไม่เปิดDuelEngine/Choicehandlerเก่า |
| 04/05 | โกลและฟาวล์/ลูกนิ่ง | โกลมีสิทธิ์รับด้วยมือในเขตของตน; รับcontactต่อจาก02/03 |
| 06 Debug/Training | sessionoverrides/defaultrestore/Dummy/scenarios | ใช้ค่าจูนที่ระบบเจ้าของประกาศ ไม่เขียนค่าถาวรหรือการแข่งขันโดยพลการ |
| 08 UI | ปุ่มcontext/3slots/Stamina/CD/recovery/feedbackและloadoutก่อนรอบ | ใช้serverstate ไม่แปลงlabelบนclientเป็นผลครองบอล |
| Phase2 | gacha3กลุ่ม/ownership/Stats/ท่าเพิ่ม/settingsจริง/first-timepolish | ธุรกรรม/ข้อมูลถาวรเปิดหลังPhase1gate ไม่เพิ่มใน00หรือfixture03 |

02/03มีinput/diagnosticsขั้นต่ำในfixtureเพื่อทดสอบได้ก่อนUI08 จึงไม่มีdependencyวนกลับไป08; 03พึ่ง02 ไม่ให้02requireบริการ03เพื่อเริ่มบอลพื้นฐาน รายชื่อAPI/ชื่อserviceที่จะรับแทนDuelEngineต้องfreezeในHANDOFFของเจ้าของก่อนแก้source

### State และ input

- แยกactualballholderกับAttack Context Team (ทีมที่ครองสำเร็จล่าสุด) ผู้ครองอาจเป็นnilตอนลูกชิ่งแต่contextยังอยู่ทีมเดิม
- ทุกคนในทีมcontextใช้ยิง/ส่ง/ยิงโค้งโดยตรง ส่วนอีกทีมใช้Slide/Poke/Shoulder; เพิ่มcontextversionเพื่อให้คำขอที่staleตรวจได้โดยไม่เปลี่ยนท่าเดิมกลางคัน
- teamcontextเปลี่ยนเฉพาะการครองสำเร็จ/resetที่ระบุไว้ ไม่เปลี่ยนจากwall/ceiling/blockedhighball; fixtureระบุinitialteam/ballชัดเจน ไม่ต้องเปิดfullmatch
- inputมีsemanticintentตั้งแต่เริ่มกด Serverตรวจcontext/ballreach/contact/สถานะและcancelเมื่อเงื่อนไขหาย ไม่ตีความShootที่เริ่มค้างให้กลายเป็นSlide
- nativeavatar movement/replicationจาก00คงเดิม การDirectionalJumpล็อกทิศกลางอากาศ/ตรวจDashและmodifiersเป็นงาน02/03 ไม่เปิดเพิ่มในbootstrap00

### Contacts และ action lifecycle

- บอลมีhitboxตลอด ไม่ทำI-frame/ล็อกคู่/หยุดฟิสิกส์ให้animationเล่น; ดาวสูงไม่ใช่คำตอบชนะสกัด
- บอลพื้นรับไหวเข้าครองได้หลังcontactสำเร็จ ลูกแรง/สูงเด้งอิสระ; friendlyplayerผ่านตัวกันได้ แต่บอลยังต้องเล่นตามcontactของมัน
- ชนคู่แข่งธรรมดาช้าลงไม่ยึดบอลอัตโนมัติ Shoulderสำเร็จเสียเหลี่ยม+บอลหลุด Poke/Slideครองได้เมื่อรับไหว; ฟาวล์ให้05ตัดสินต่อ
- ออกท่าผ่านready/windup/contact/end/recoveryตามข้อมูลท่า Serverเป็นเจ้าของvalidtiming แอนิเมชันclientแสดงตามและไม่ส่งผลชนที่เชื่อได้เอง
- ใช้Stamina/cooldown/recoveryส่วนกลาง จ่ายไม่พอไม่ออกท่า คูลดาวน์แยกต่อskillพร้อมช่วงจบท่าร่วม พลาดล็อกSkill/Dash/เข้าสกัดซ้ำแต่ยิงส่งเมื่อท่าเอื้อ สไลด์ต้องลุก
- generation/round/tokenยกเลิกคำขอ/tracks/effectsเก่าเมื่อrespawn/reset/leave ไม่มีtimerมาแก้ตัวใหม่

### Loadout, assets และค่าจูน

- Phase1ตัวเริ่มต้น1ตัว SkillMove5ดาว เลือก3จาก5ท่าฟรีตามSpec02 ไม่มีitemUID/gacha/persistence ดาวไม่ใช่Tierและไม่เปลี่ยนpresets/Default Cardใน00
- เปลี่ยนชุดก่อนรอบ/หยุดรีเซ็ตซ้อม การresetทดสอบต้องแสดงว่าเริ่มscenarioใหม่ ไม่ใช้สลับชุดระหว่างเล่นเพื่อล้างCD
- R6ท่าร่างครบ5ท่าต้องอ่านจังหวะได้ asset/provenance/authoringและช่วงcontactอยู่implementationcontract03 ส่วนidle/walk/run/jump/fallของ00ยังตามสัญญาเดิม
- configระบุcost/CD/commonend/recovery/contactreach/ballspeedthresholdและmovement defaultsให้Debug06ใช้พร้อมsafe ranges; ตัวเลขยังต้องจูนจากrealruntime
- แอนิเมชันพร้อมเสียจังหวะเมื่อfirst-timeยิงส่งวืดเป็นPhase2เท่านั้น Phase1ยังเล่นfirst-timeได้

### Network evolution และ review gates

- ตรวจ12baseline definitions/gettersของ00ตามเดิม การมีDuel*/Parry*remoteไม่ใช่สิทธิ์ให้เปิดhandler; 02/03ต้องออกแบบintent/state/snapshotcontractและscope migrationก่อนลงมือ ไม่reuseชื่อDuelChoiceSubmitเพื่อส่งสกิลคนละความหมาย
- Validate action/slot/ดาว/round/character/context/finiteaim/cost/rate/CD/ballreachบนServer; clientส่งintent ไม่ส่งwinner/guaranteedballclaim
- ไม่มีการเพิ่มremote/schema/sourceในรอบเอกสารนี้ ปัญหาAPIที่พบตอนเปิดแผนแก้เฉพาะallowlistของHANDOFFนั้น
- Gateตาม [TDD](../tdd/master-test-cases.md): actualruntime teamcontext/first-time/ทุกskillและdefence/ต้นทุน/recovery/contacts/cleanup พร้อมvisualอ่านท่าได้ แยกจากstaticchecks/JSsimulation; spectatorผลตามsessionที่ตรวจจริง

## 7. Rebound Rush — Event 4 / Accepted design

แผน07เพิ่มeventเร่งบอลตามคำสั่งOwner2026-10-20: wall/ceiling/bevel contactsที่อยู่ในcatalogทำให้บอลถึงtargetSpeedคงที่ ไม่สะสม ไม่ลดลูกที่เข้าเร็วกว่าtargetและไม่คูณซ้ำกับbumper EventManagerเป็นเจ้าของactivation/target/expiry ส่วนcollision owner01/02applyresponseเพียงจุดเดียวตามsurfaceID/contactจริง; floor/player/pillar/NPC/goalframeไม่อยู่ในsurfacefilter

ตอนEnd/Cancel/Switchให้ถอนoverrideสำหรับcontactsใหม่แต่ไม่เขียนvelocityบอลให้กลับความเร็วปกติทันที เก็บtest envelope/capที่รองรับความเร็วค้างและคืนbaselineโดยไม่กระโดดทิศ/ความเร็ว Debug06ปรับtargetและระยะActiveเฉพาะsessionได้

ตาราง12remotesใน§2เป็นbaselineเดิม enumMatchEventBroadcastยังไม่รวมevent4ในsource; ก่อนimplementation07ต้องfreezecontractdelta/config/allowlistกับผู้เรียก ไม่เพิ่มsource/แก้Networkของ00หรือเปิดeventนี้ในแผน01จากเอกสารรอบนี้

## 8. Overdrive และLow-Roof — Event 5/6

- Overdriveเป็นscopedresourceoverrideจาก07ไปเจ้าของStamina02: ทุกทีมใช้ทรัพยากรไม่จำกัดขณะActive ไม่เปิดCD/recovery bypassและไม่แก้movement/shot power NormalDashcostคงconfigเดิม UI08รับeventstateแล้วแสดงinfinite/highlightsweep ไม่ตัดสินresourceเอง Endเติม100%ครั้งเดียวแล้วกลับใช้ปกติ CD/recoveryไม่reset Endซ้ำ/stalegenerationไม่เติมซ้ำ
- Low-Roof07เป็นtemporarygeometryoverride: flatroofundersideสูงจากplayingfloor12studsทุกprofile ปิดresponseของroof/bevelเดิมเฉพาะช่วงevent ภาพและsolverอ่านsurfaceheight/timeเดียวกันระหว่างลด/คง/คืน
- โกล/ผู้เล่น/บอลต้องไม่ติดหรือทะลุmovingroof surfacevelocity/contacttimeรองรับตามcollisionowner ไม่ใช้visualTweenอย่างเดียวหรือคัดกติกาReboundRushมาเพิ่มspeed
- latejoin/respawn/reset/cancel/switchใช้event/round/generationguards ล้างoverrides/effects/temporarycollidersแล้วคืนค่าที่ownerกำหนด ไม่เขียนpersistence/source00
