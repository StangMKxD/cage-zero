# Review 001 — 02-player-actions

- วันที่: 2026-10-21 (Asia/Bangkok)
- Reviewer: Codex / stang-luna; ตรวจ implementation, scope และหลักฐานแบบ read-only
- **Verdict: CHANGES_REQUESTED — ยังไม่รับรอง T-01 ถึง T-99 ครบตาม acceptance**
- Actual reviewed ref: `main` HEAD `65026668fcae9d80094841bb147f3f4dc64b0b6c` + working tree ตาม source lock ด้านล่าง ไม่ใช่ HEAD อย่างเดียว
- ไม่แก้ source, ไม่รัน application tests, ไม่ require game modules, ไม่กด Play, ไม่ cleanup/แก้ Studio และไม่ commit/push/merge/deploy
- รอบนี้สร้างเฉพาะรายงานนี้ ไม่เปลี่ยนสถานะแผน/checkbox หรือคำตัดสิน historical; 00/01 ยังเปิดและพักตามคำสั่งเดิม
- Finding IDs ในรายงานนี้เป็นของ **แผน 02** เริ่ม F-10 เพื่อไม่ชน F-01–F-09 ที่ AGY ใช้ใน notes ของแผนนี้ ไม่ใช่ findings ของแผน 00/01

## Ref และขอบเขตที่ตรวจ

อ่าน `agent.md` (โปรเจกต์ไม่มี `AGENTS.md`), `docs/READ.md`, plan/tasks/notes/HANDOFF ของ 02, PRD, Spec02, context, architecture, TDD, Git diff และ untracked tests ที่เกี่ยวข้อง

[CONFIRMED] HEAD/index: `main` ที่ SHA ข้างต้น; staged diff ว่าง มีงานเดิม 01 ปะปนใน working tree จึงไม่เหมารวม diff ทั้งหมดว่าเป็นงาน 02

[CONFIRMED] เทียบ source ปัจจุบันกับ `.sandbox/rollback/run-phase01-cage-physics-01/post/files/`: `CagePhysicsService.luau`, `Network.luau`, `RigAndCardService.luau` ตรงกันแบบ SHA-256; ไม่พบเหตุให้กล่าวว่า 02 แก้สามไฟล์นี้จาก snapshot ดังกล่าว งาน 01 และ `.gitignore` ที่ dirty ยังต้องปกป้อง ไม่สั่ง revert

[CONFIRMED] `git diff --name-only -- docs/prd docs/tdd docs/specs docs/context docs/design` ว่าง: ไม่มีการแก้ PRD/TDD/spec/context/architecture ใน working-tree diff รอบนี้ ขอบเขตเนื้อหาหลักใน plan02 ไม่เปลี่ยนจาก HEAD ยกเว้น state/authorization/baseline แต่ handoff และ claims ส่งมอบมีช่องว่างตาม F-18

### Source lock (SHA-256 ของไฟล์บนดิสก์)

| File | SHA-256 |
| --- | --- |
| `src/shared/Constants.luau` | `e97a010c2550524d865edbdba3ae247f4a4c588069932652f0078d0d7f45ec56` |
| `src/shared/Types.luau` | `5b2f84a96b25e31c42ad72cfa655ca5918e57a6c1f3fdfdc1e6e1092c3e4f22f` |
| `src/shared/configs/RigAnimationConfigs.luau` | `93eadbea066d79af58c0b39527587b070be3d885c29ed2bc0ad1c90831448ae8` |
| `src/server/services/BallService.luau` | `31074c7c7ea2c7e4a35fb9bf55270777b1f1d2fded71bfa29e3507b61288c5f6` |
| `src/server/services/CagePhysicsService.luau` | `09b564258699f4cf3be76483ee9d819d610a7f47a69a3f977d1f0e40e0f7d7ab` |
| `src/server/init.server.luau` | `ef6254ba5676f1afec8837c6f8d7c309296e8748585602a22c5af412f5261b67` |
| `src/client/init.client.luau` | `e15cb07ad050dbcfc01f055d3e1b7a823e519ec8ba940fcca40591cdb03cffd2` |
| `src/client/character/R6AnimationController.luau` | `31f25e757b1f6b4be3b047622d870dc6fe6781902bfd83129ee0e655f052f9a9` |
| `src/client/controllers/InputController.luau` | `5f4ba41360b0b87fd58ad58a42e59f2d8920c795198712fd9d948027b52bc363` |
| `tests/e2e/Tier1_PlayerActions.luau` | `4861638d659eec65b3b69d9eacc11657d954a1011bb13d47d1ad6082ece54362` |
| `tests/e2e/TestHarness.luau` | `047341fe5594a0ef94a08933a397ab02ac25815834075cde949f3cc39999226b` |

Document lock ก่อนเขียนรายงาน: plan `dae55c5839845e5cd2baab471bb9d4bf0660459d5d6d28ddd56b9161d23f8368`; tasks `be9a2dd1014797ecda3b2471a1b3eeff6b063db72994f42c2c1dc06e72e6ed12`; notes `6fb99c89eedbf0495bbacc90caa5f848fa7ed11f73f069566fdce6c7ce5e6dcf`; HANDOFF `4a4f6a695be2c86880913b45fc3e6d84aca7287e0bb805b74f61620c4ddc3954`

### Studio readback ที่ตรวจจริง

- `list_roblox_studios`: `Cage-Zero`, PlaceId `137721422246269`, Studio ID **`4357ddc0-d195-4f8c-bc73-90c1a7484fd0`**; `get_studio_state`: **Edit** เท่านั้น
- `search_game_tree` ตรวจ paths ก่อน `script_read`; อ่าน source เต็มเก้าไฟล์ตามตาราง แล้วตัดเฉพาะเลขบรรทัดที่ tool เติมออก เทียบข้อความกับดิสก์: **ตรง 9/9 แบบ exact text**; hash บนดิสก์ตรง N-05 ทั้งเก้าไฟล์
- Paths: `ReplicatedStorage.Shared.{Constants,Types,configs.RigAnimationConfigs}`, `ServerScriptService.Server` และ `.services.{BallService,CagePhysicsService}`, `StarterPlayer.StarterPlayerScripts.Client` และ `.character.R6AnimationController`, `.controllers.InputController`
- Workspace direct children: `Terrain`, `Baseplate`, `CageMatchBall`, `Camera`, `HexCageArena`; **ไม่พบ mock ระดับบนหรือ `__TestMocks` ใน snapshot นี้** ไม่ใช่หลักฐานว่า cleanup ครอบคลุม interruption ทุกชนิดหรือไม่มี nested leftovers ทุกแห่ง
- ไม่ตรวจภาพ viewport/ท่าร่างจริง: **visual verification INCOMPLETE**; ไม่ขอ screenshot/video เป็น gate
- Readback นี้ยืนยัน source และ Edit scene เท่านั้น ไม่ยืนยัน require cache, Live Play behavior หรือผลทดสอบ 26/26 ย้อนหลัง

## Findings ที่ต้องแก้

### F-10 — P1 / OPEN: ปิด player contacts ระหว่างครองบอลและ 0.30 วินาทีหลังออกบอล

**พิกัด:** `src/server/services/BallService.luau:564–605`, `:178–183`

[CONFIRMED] branch `Possessed` ทำเพียงเลื่อนบอลตาม root ไม่มีตรวจผู้เล่นอื่น/ball contacts; player collection/deflection อยู่ใน branch `Free/InFlight` เท่านั้น และ guard `now - lastKickTime > 0.30` ปิดการตรวจนี้สำหรับผู้เล่นทุกคนหลังยิง/ส่ง ขณะที่ Part บอล `CanCollide/CanTouch/CanQuery=false` จึงไม่มี engine contact สำรอง

[INFERRED] บอลที่กำลังเลี้ยงและบอลที่เพิ่งออกจากเท้าผ่านผู้ขวางได้โดย contact handler ไม่ทำงาน รวมถึงช่วง Dash; ไม่ตรง Spec02 §1/§3 และ TDD INV-06/TC-P1-02-03/04 ไม่จำเป็นต้องมี Slide/Poke/Shoulder ของ 03 เพื่อทดสอบช่องว่างนี้

**แก้/ตรวจรับ:** ให้ owner บอลประเมิน contact ที่เกี่ยวข้องทุกสถานะ ไม่ใช้ global immunity หลังออกบอล หากกันผู้เตะรับซ้ำให้จำกัดเฉพาะ contact ของผู้เตะโดยไม่ปิดคนอื่น; ทดสอบผู้ขวางระยะใกล้หลังเตะและ contact ขณะเลี้ยง/Dash พร้อมตรวจ actual holder แยก last team

### F-11 — P1 / OPEN: ลูกสูง/ผู้เล่นกลางอากาศไม่ถูกบล็อก และตรวจคนเฉพาะตำแหน่งปลาย step

**พิกัด:** `src/server/services/BallService.luau:591–625`

[CONFIRMED] หลัง solver สนามคืน `nextPos` โค้ดตรวจเพียงระยะจากตำแหน่งปลาย step ถึง root และกำหนด **world Y ของบอล <= 3.8** จึงข้ามบอล Y>3.8 ทุกลูก แม้ root/ตัวผู้บล็อกกระโดดขึ้นไปถึงบอลแล้ว ไม่มี player swept contact ระหว่างต้น/ปลาย step

[INFERRED] jump block ที่ตำแหน่ง rootY=6/ballY=6 ไม่เข้าทาง deflection; ลูกเร็วที่ข้ามรัศมีตัวแล้วพ้นออกไปใน step เดียวอาจทะลุตัว การที่ solver สนามมี swept collision ไม่ได้ครอบคลุม player contacts ให้ BallService โดยอัตโนมัติ

**แก้/ตรวจรับ:** วัด contact/ความสูงเทียบร่างจริง แยกเกณฑ์รับไหวกับเกณฑ์ชน/บล็อก และตรวจเส้นทางบอลกับผู้เล่น; ทดสอบบอลสูงชนตัว/หัวขณะลอย, ตัวบน ramp, ลูกเร็วข้ามทั้ง hitbox ภายใน step และ near miss ต้องไม่ดูดบอล

### F-12 — P1 / OPEN: first-time pass และ curve ถูกเปลี่ยนเป็นลูกยิงเสมอ

**พิกัด:** `src/server/services/BallService.luau:347–371`

[CONFIRMED] เมื่อผู้สั่งไม่ใช่ possessor แต่ระยะถึงบอลผ่าน branch แรกไม่พิจารณา `actionType` เลย: ทุกคำสั่งกลายเป็น Header ความเร็ว 78 หรือ Volley ความเร็ว 118 ใช้ `shotMultiplier` รวมถึง GroundPass/LobPass/CurveShoot; charge/curve/pass trajectory ไม่ถูกใช้ ชนิด Header ยังอิง absolute world Y อย่างเดียว

**แก้/ตรวจรับ:** รักษา intent ยิง/ส่งเรียด/ส่งโด่ง/ยิงโค้งเมื่อเล่นจังหวะแรกและเลือก contact ตามร่างจริง; ทดสอบแต่ละปุ่มกับบอลเข้า/บอลชิ่งโดยไม่เรียก `SetPossessor` ก่อน ยืนยันวิถีและประเภทการออกบอล ไม่ใช่เพียงเปลี่ยน label

### F-13 — P1 / OPEN: payload ยังทำให้เกิดค่าความเร็วไม่ finite และ action ไม่ผ่าน validation ครบ

**พิกัด:** `src/server/services/BallService.luau:303–336`, `:364–371`, `:657–695`

[CONFIRMED] `charge` ตรวจเพียง `type == number` แล้ว `math.clamp` ไม่ใช้ `Network.IsNumberInRange`; รับ NaN ผ่านทางนี้ได้ ส่วน aim แนวตั้ง `(0,1,0)` เป็น finite vector ที่ผ่าน validator แต่ GroundPass/LobPass normalize `(0,0,0)` และ CurveShoot normalize right vector ศูนย์ ไม่มี guard final velocity ก่อนเขียน state นอกจากนี้ไม่มี request rate limit และ ExecuteKick/Jump/Dash ไม่ตรวจ Humanoid สุขภาพ/character generation ของคำขอ

[INFERRED] malformed numeric payload สามารถปนเปื้อน ball velocity/position ได้ และคำขอจากตัวตายหรือส่งถี่อาจเปลี่ยน state ทั้งที่เงื่อนไขเล่นบอลหมดแล้ว การตรวจ finite aim อย่างเดียวไม่พอ

**แก้/ตรวจรับ:** reject nonfinite charge/ผลคำนวณ, normalize horizontal aim อย่างปลอดภัย, validate current character/alive/context/rate ก่อน mutation; ทดสอบ NaN/Inf/vertical aim/zero aim/คำขอถี่/ตัวตาย โดยตรวจ state ไม่เปลี่ยนเมื่อ reject

### F-14 — P1 / OPEN: charge และการคืนความเร็วเชื่อ client โดยไม่มี authoritative charge state

**พิกัด:** `src/client/controllers/InputController.luau:72–97`, `:127–134`, `:158–162`, `:186–195`; `src/server/services/BallService.luau:335–336`, `:394–421`, `:657–695`

[CONFIRMED] เริ่มชาร์จเปลี่ยน WalkSpeed ฝั่ง client เป็น 8 เท่านั้น ไม่มี Begin/Cancel/Release charge บน server; client ส่ง charge เต็มได้ทันที Serverไม่ทราบช่วงต้องชะลอ/intent เดิม การปล่อย E/cancel คืนความเร็วจาก local `isSprinting` ไม่ใช่ server stamina/sprint state; `RequestSprint(true)` ตั้ง local speed=24 ก่อนรู้ว่า server ปฏิเสธหรือไม่

[INFERRED] กด Shift ขณะ stamina หมดแล้วปล่อย E สามารถคืนความเร็ว client เป็น 24 ทั้งที่ server ยืนยันไม่ได้ sprint; การชาร์จไม่ถูก enforce ตาม acceptance ฝั่ง server

**แก้/ตรวจรับ:** กำหนด charge intent/state contract ให้ serverตรวจเวลา/ความเร็ว/การยกเลิกและใช้ resolved movement state คืนความเร็ว; ทดสอบ exhausted+Shift+E, sprint ขณะชาร์จ, cancel จาก context/death/reset และคำขอ charge เต็มทันทีตาม protocol ที่ล็อกไว้ ห้ามเพิ่ม remote/schema ก่อนผ่าน F-18

### F-15 — P1 / OPEN: airborne lock อิง flag คำขอแทนวงจร takeoff/landing จริง

**พิกัด:** `src/server/services/BallService.luau:427–430`, `:463–483`, `:534–551`; `src/server/services/CagePhysicsService.luau:1004–1024` (อ่านเพื่อเทียบ seam เท่านั้น)

[CONFIRMED] `isAirborne` ถูกตั้งเมื่อรับ DirectionalJump ไม่ได้ derive จาก Humanoid air state; คำขอแรกยอมรับแม้กำลังตกอยู่ การ Dash ตรวจเพียง flag นี้; landing ปลดล็อกเมื่อ FloorMaterialไม่ใช่ Air หรือ rootY<=2 หรือ `IsPositionOnElevatingRamp` ซึ่งเป็น trigger volume ของบอล มิใช่หลักฐานสัมผัสเท้ากับพื้น ไม่มี takeoff phase ป้องกันการปลดล็อกทันทีเมื่อ FloorMaterialยังเป็นพื้นในเฟรมรับคำขอ

[INFERRED] เดินตกขอบโดยไม่ส่ง Jump แล้วกด Dash/Jump ยอมรับได้; อยู่เหนือ ramp ใน trigger volume อาจปลดล็อกกลางอากาศ ชุด mock ย้าย CFrame ไม่พิสูจน์ว่า live takeoff/landing ปลอด race

**แก้/ตรวจรับ:** ผูก state กับ takeoff/airborne/landing ของตัวละครจริงและ contact ของพื้น, รักษา horizontal vector จนลงพื้นจริง; ทดสอบ sprint jump, เดินตกขอบ, กระโดดเหนือ ramp โดยไม่แตะ, กดซ้ำ, landing และ Dash rejection ใน Live Play โดยไม่แก้ owner ฟิสิกส์ 01 นอกสัญญา

### F-16 — P1 / OPEN: movement/input state ข้าม death/respawn/reset และ team context เปลี่ยนไม่ครบ

**พิกัด:** `src/server/services/BallService.luau:61–67`, `:149–164`, `:239–243`, `:490–505`, `:698–709`; `src/client/controllers/InputController.luau:127–142`

[CONFIRMED] server subscribe เพียง PlayerAdded/Removing ไม่มี CharacterAdded/Removing/Died หรือ generation guard ใน BallService; helpers ResetPlayerState/ClearAllPlayerStates ไม่มี production lifecycle caller; ResetBall ไม่ reset movement/input generation Client bindChar เพิ่มเฉพาะ context listener ไม่ล้าง `chargeStartTime`/`isSprinting` หรือ disconnect listener ตัวเก่า

[CONFIRMED] `SetPlayerTeamSide` ของผู้ครองปัจจุบันเปลี่ยน team ของ state แต่ไม่ปรับ/resolve actual possession กับ `lastPossessingTeam`; state ที่สร้างใหม่ default Attacking เสมอ และ Init ไม่ enumerate existing players

[INFERRED] charge/airborne/sprint/cooldown ของตัวก่อนอาจมีผลกับตัวใหม่; ปล่อย E ที่เริ่มก่อนตายยิงจากตัวใหม่ได้เมื่อเงื่อนไขระยะผ่าน; team transfer ขณะครองทำให้ผู้ครองกับทีมโหมดบุกขัดกัน จึงไม่ครบ TC-P1-02-06

**แก้/ตรวจรับ:** ระบุและทำ lifecycle reset ตาม character/session generation โดยรักษา team ที่ถูกต้อง ไม่รับ intent เก่า; resolve possession/team change ให้สอดคล้อง; ตรวจ death/respawn/leave/reset/team-change และ existing-player initialization พร้อม assertions ที่ state จริง

### F-17 — P1 / OPEN: 26/26 ไม่รองรับ claims runtime และมี assertions ที่ผ่านโดยไม่แตะพฤติกรรมเป้าหมาย

**พิกัด:** `tests/e2e/Tier1_PlayerActions.luau:81–115`, `:345–360`, `:385–404`, `:429–445`, `:540–579`, `:604`; `tests/e2e/TestHarness.luau:183–226`; `02-player-actions/notes.md:N-05/N-06`

[CONFIRMED] mock root Anchored, ไม่มี live client; suiteเรียก serviceโดยตรง ไม่ require InputController ไม่เดินผ่าน RemoteEvent ในการทดสอบนี้ TC18 ตรวจเพียงมี methods ไม่ได้โหลด/เล่น track บน character จริง TC13 ตรวจแค่ไม่ครอง/ความเร็วยังสูง ไม่ตรวจว่าทิศสะท้อนเปลี่ยน จึงผ่านได้แม้ไม่ deflect

[CONFIRMED] TC25 ตั้ง diff=0 **ก่อน** StepPhysics(0.05), แต่ contact ถูกตรวจหลัง solverเคลื่อนบอล จึงไม่ได้บังคับ diff=0 ณ branch ที่อ้างว่าตรวจ TC15 หลังย้ายลงพื้นตรวจเพียง action context ไม่เป็น nil ไม่ assert ว่า airborne lock ถูกล้าง

[CONFIRMED] numeric comparators เช่น `toBeCloseTo`/`toBeGreaterThan` และ vector distance comparatorไม่ reject NaN; NaNทำให้ relational comparison เป็น false จึงอาจผ่าน assertion นี้ได้โดยค่าเสีย

[CONFIRMED] cleanup อยู่ก่อน/ท้าย suiteแบบ sequential ไม่ใช่ protected runner teardown; errorใน testcaseถูก pcallแล้ว suiteไปต่อ แต่ runner error/interrupt ก่อนบรรทัด604ยังข้าม cleanupได้ และ errorใน testcaseอาจทิ้ง mock/stateปนเคสถัดไปจนจบ suite การตั้ง Transparencyไม่ได้ล้าง state

**แก้/ตรวจรับ:** แยก unit/Edit-engine ผลจริงจาก Live Play, แก้ assertionsให้พิสูจน์ contact/landingที่อ้างและ finite values, มี per-case teardown/error handling และ startup recoveryสำหรับ interrupt โดยรายงานข้อจำกัดตามจริง; ผูก run กับ source/test/payload hashes และ TC-P1-02-01..06 ไม่อ้างจำนวนข้อเป็น coverage ทั้งหมด ไม่ต้องเพิ่มภาพหรือวิดีโอ

### F-18 — P2 / OPEN: contract migration และเอกสารสถานะยังไม่ครบ; ห้ามถือ claims เป็น approval ขยาย scope

**พิกัด:** `02-player-actions/plan.md:30`, `02-player-actions/assets/HANDOFF.md:28–90`, `02-player-actions/tasks.md:9–17`, `agent.md`, `docs/READ.md`, `docs/plan/phase-01-gameplay-demo/plan.md`, `docs/tdd/master-test-cases.md:3–45`

[CONFIRMED] planกำหนดให้ finalize exact API/Network/Types allowlist ก่อนแก้ แต่ HANDOFFระบุระดับ workstream ไม่มี payload/schema delta, state/intent/snapshot/version/generation contract, dirty-file fingerprint หรือรายการทุกไฟล์ที่แก้จริง (เช่น Types/Constants/config/bootstrap) ขณะที่ P-02b ถูกติ๊กเสร็จ

[CONFIRMED] tasks T-99 ถูกติ๊กเสร็จ แต่ TDDปัจจุบันยังระบุ Planned/NOT RUN โดยไม่มี mapping ไป TC-P02; phase planยังบอก 01–09 implementation PENDING; READทั้งบอก02ครบและอีกบรรทัดบอกimplementation02ยังPENDING `agent.md` rewriteนำบริบท F18/F19 ของ00ที่ยังเปิดออกจาก router และลดรายละเอียด Git authorization เดิม แม้ยังมีรายงาน historicalอยู่ ห้ามตีความว่าข้อค้างเหล่านั้นปิดแล้ว

[CONFIRMED] plan02 Deferred และ Spec02 §5/architectureระบุ first-time animation/miss recoveryอยู่Phase2 แต่ notes N-03อ้าง Header/Volley animationเป็นสิ่งที่ขาดตามสเปก02และเพิ่ม profiles; ไม่พบ change approval ที่ชี้ว่ามีการย้าย deferred requirementมาเป็น gate02 จึง **ไม่ใช้การขาด first-time animationเป็น finding blocker** และไม่สั่งขยายงานนี้เพิ่ม

**แก้/ตรวจรับ:** Controller reconcile HANDOFFเดิมและ locked allowlist/contractกับ approved scopeก่อนส่งแก้ code, ผูก approvalจริงไม่สร้างคำอนุมัติย้อนหลัง; AGYซิงก์สถานะและ TC mappingโดยรักษาhistorical/open findings/ข้อห้าม Git, ไม่ติ๊กผ่านข้อที่ยังไม่ตรวจ หากต้องย้าย deferred scopeหรือแตะ protected files ให้เสนอ change requestและหยุดเฉพาะส่วนนั้น ไม่ auto-removeงานค้างของผู้ใช้

### F-19 — P2 / OPEN: T-05 ยังไม่มี training fixture/HUD ขั้นต่ำที่ตรวจแบบ live ได้

**พิกัด:** `02-player-actions/plan.md` Scopeข้อ training fixture; `02-player-actions/tasks.md:T-05`; `src/server/init.server.luau:26–27`, `src/client/init.client.luau:46–58`, `src/server/services/BallService.luau:490–505`; `tests/e2e/TestRunner.luau`

[CONFIRMED] production bootstrapเปิด BallService/InputController; hooks SetPlayerTeamSide/ResetBallมีอยู่ แต่ไม่พบ production callerสำหรับเลือกscenario/initialteam/startpositions/resetครบชุด หรือ HUDขั้นต่ำที่ผูก server context/staminaให้ตรวจ T-05; fixtureที่พบเป็นmockภายใน Edit suite TestRunnerมาตรฐานยังรันชุด01 ไม่เรียก PlayerActions suite

**แก้/ตรวจรับ:** ส่ง fixtureสำหรับตรวจ02ที่ระบุ initialball/team/จุดเริ่ม/resetและแสดงserver context/staminaขั้นต่ำ พร้อมวิธีรันปัจจุบันที่ทำซ้ำได้ โดยล็อกไฟล์ในHANDOFFก่อน ไม่เปิด MatchService/full UI08/debug settingsถาวร06/Phase2 และไม่อ้าง hooksอย่างเดียวว่า T-05ครบแล้ว

## ผลตรวจหกมิติ

| มิติ | ผล |
| --- | --- |
| Scope | ไม่พบ PRD/TDD/spec/context เพิ่มใน diff; 01 physics/Network/RigService ตรง post01 แต่ contract allowlist/deferred attributionยังไม่ครบ (F-18) |
| Architecture/contracts | Single ball writerมีจริง แต่ continuous contacts/first-time/lifecycleไม่ครบ (F-10..12/F-15..16) |
| Safety/validation | ยังไม่ครบ finite output, alive/generation/rateและauthoritative charge (F-13..14) |
| Quality/conventions | ปัญหาที่รายงานเป็น behavior/contract/test reliability ไม่ใช้ความชอบเชิง styleเป็น blocker |
| Verification | Local hashesและStudioEdit parityยืนยันได้; 26/26และ141/141เป็นผลรายงานAGY ไม่ใช่การรันทดสอบอิสระในรอบนี้; Live Play/visualยังไม่ยืนยัน (F-17) |
| Documentation | T-99/TC mapping/router/phase stateยังไม่สอดคล้อง (F-18); live fixtureยังไม่ครบ (F-19) |

## ขอบเขตการแก้และส่งกลับ

1. Reuse HANDOFFเดิม; Controllerต้องล็อก exact migration/allowlistจาก approved scopeก่อน dependent edits ไม่เปิดแผน03/06/08/Phase2หรือย้อนแก้งาน00/01ที่พักอยู่
2. AGYแก้ F-10..F-19 ภายในขอบเขตที่ล็อกแล้ว และเพิ่มเฉพาะ verificationที่พิสูจน์ findings ไม่ปรับspec/acceptanceให้ตรงโค้ดที่ผิด
3. ส่ง `assets/fix-001.md` ฉบับเดียว ระบุ F-ID, paths, actual reviewed HEAD+working-tree hashes, exact Studio target/mode, วิธีรันและผลจริง แยก static/Edit-engine/Live Play/visual/NOT RUN ไม่ทำรายงานซ้ำหลายไฟล์และไม่เก็บ full diff
4. คง00 `OPEN / PAUSED_BY_OWNER`, 01 `OPEN / PENDING_TECHNICAL_REVIEW`; ห้าม commit/push/merge/deployหรือเปลี่ยนเป็นapproved/closed/passเอง รอบนี้ไม่มีการมอบอำนาจ Gitเพิ่ม
5. Codex re-review current ref/hashหลังแก้ การตรง source 9/9และสนามสะอาดใน Editครั้งนี้ไม่ใช่การรับรองแผน02ครบ
