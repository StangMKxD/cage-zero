# Master Test Cases & TDD Acceptance Criteria (`docs/tdd/master-test-cases.md`)

เกณฑ์ปัจจุบันอ้าง Phase 1 plan และ accepted decisions; ผู้ใช้ยืนยัน R6 ตลอด Phase 1 เมื่อ 2026-10-20 Q22ยืนยันฟุตบอลต่อเนื่อง/SkillMovesแทนChoiceแล้วเมื่อ2026-10-20; เกณฑ์ใหม่ด้านล่างเป็นPlanned/NOT RUN แยกจากhistoricalbaseline

## กฎเหล็กทั่วไปที่ต้องตรวจทุก Module (Global Invariants)
- `[INV-01]` ลงมือตาม phase/dependency และ HANDOFF ที่ Owner อนุมัติ implementation; Codex ตรวจหลักฐานอิสระ ไม่ใช้ APPROVED เก่าข้าม gate
- `[INV-02]` ไม่ใช้ avatar/animation pack ส่วนตัว; Phase 1 ใช้ Single Custom R6 ตลอด phase ส่วน Phase 2 ยังไม่กำหนดการเปลี่ยน rig
- `[INV-03]` ห้ามมีระบบรองเท้าสตั๊ด (No Boots/Cleats System) มีเฉพาะชุด `Battle Threads` (คอสเมติกเท่านั้น ไม่มี Trait slots และไม่มีหิน Trait ใน Target)
- `[INV-04]` ห้ามให้ `Mutated Gear` เพิ่มสเตตัสในสนาม (เพิ่มเฉพาะราคาขาย, VFX, และตัวคูณ Cash/EXP หลังจบแมตช์)
- `[INV-05]` Skill Moves/ท่าเข้าสกัดตรวจcost/CD/recoveryบนServer; 16 Innate Traits เป็นคุณสมบัติติดตัวละครเท่านั้น (ผันแปร 0, 1, 2, ... รายการ); Trait ตรวจสอบเงื่อนไขบน Server ไม่คืนผลชนะ Choice จาก baseline
- `[INV-06]` บอลสัมผัสได้ตลอดทุกDash/Skill ไม่มีI-frame/Choice trigger/สโลว์เปิดดวล/คัตซีนล็อกคู่/timedParry
- `[INV-07]` ปุ่มตามทีมที่ครองสำเร็จล่าสุดแยกจากactualholder; block/wall/ceilingไม่เปลี่ยนteamcontext ยิง/ส่งต้องมีballreachจริง
- `[INV-08]` เป้าหมายสกิล 7 ท่าไม่ซ้ำ (1★..5★) ติดตั้ง 3 ช่อง (โดยมี 5 แอนิเมชันเดิมอยู่ระหว่างการปรับแก้ตาม HANDOFF §Q รอการตรวจรับ) ตัวเริ่มต้นเพดานสกิล 5 ดาว ไม่เท่ากับ Tier/Stats; ไม่มีคัตซีนแพ้ชนะหรือสตั้นผลดวล
- `[INV-09]` หน้าจอ UI ทั้งหมดต้องควบคุมผ่าน `UIManager.luau` ตัวเดียว ห้ามเปิดหน้าต่างซ้อนทับกัน
- `[INV-10]` การคำนวณสำคัญทั้งหมดต้องเป็น `Server-Authoritative 100%`

---

## เกณฑ์ตรวจรับรายโมดูล (Module Acceptance Criteria)

### Phase 1 / 00: `00-bootstrap-and-rig` — Custom R6
1. **[TC-00-01] Source/topology:** source 9 จุดตรง repo; R6 มี 7 BaseParts รวม HRP, 6 Motor6Ds, Humanoid.RigType=R6, Animator และหน้าอนิเมะ; PrimaryPart=HRP ไม่ใช้ avatar/รองเท้าสตั๊ด
2. **[TC-00-02] Bootstrap:** server Network→Rig; client Network→R6AnimationController; deadline รวม 10s ไม่โหลด Match/Parry/UI/collection และ getters เดิมไม่เปลี่ยน
3. **[TC-00-03] Scale:** 4 presets ไป–กลับ 3 รอบ ตรวจ base Size/C0/C1 และ R6 ground clearance ไม่คูณสะสม; 6 joints ไม่มี knee/elbow checks แบบ R15
4. **[TC-00-04] Motion:** idle/walk/run/jump/fall เปลี่ยน pose จริงจาก R6 clips หลัง Animator อยู่ Workspace; แยก server state, client PostSimulation และ visual incomplete ไม่เทียบ raw Transform ข้ามฝั่ง
5. **[TC-00-05] Lifecycle:** explicit floor/anchor valid-or-error; repeated death 3 รอบ, out-of-bounds, old timer race และออกเกมไม่เกิดซ้ำ/สะสม connection
6. **[TC-00-06] Sync/rollback:** before/after manifests ครบ files/subtree ตรวจทั้งชุดก่อน restore; หยุดเมื่อมีงานแทรก source/asset/visual ที่ไม่ตรวจยัง NOT VERIFIED
รายละเอียด: [plan 00](../plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md) / [Tasks](../plan/phase-01-gameplay-demo/00-bootstrap-and-rig/tasks.md)

### Phase 1 / 01: `01-cage-physics` — A/B/C comparison
1. **[TC-01-01] Surface coverage:** A4walls/flat roof; B8walls/flat roof; C8walls+central roof/bevel45°/corner seams มีvisualและfinite collisionตรงcatalogเดียว
2. **[TC-01-02] Collision envelope:** high speed/grazing/multi-contact/corners/roof seamsใช้swept radius/remainingdt/step budget รายงานescape/clippingจริงตามspeed/dt/radiusที่ตรวจ ไม่อ้างzero clippingทุกinput
3. **[TC-01-03] Base rebound cases:** ceiling lob, transomเหนือคานจริง, corner bumpers nominal1.25ก่อนcap, ramp25°เฉพาะfootprint และback zone14; markerไม่เปลี่ยนtrajectory
4. **[TC-01-04] Fair comparison:** shape/mechanics passesแยกกัน profile/config/launch/seed/dtระบุชัด eventsปิดใน01 เก็บlanding/second-ball/อ่านเกมและผลfailจริง ไม่ตั้งwinnerก่อนวัด
5. **[TC-01-05] R6/scene integration:** R6เดินrampและอ้อมหลังgoalได้ explicitfloorจาก00ยังถูกต้อง ไม่มีMatch/goal scoring/ball actions/event gameplayเกินscope

## Phase1 gameplay หลัง Q22 — Planned / NOT RUN

### 02 บอล การเคลื่อนที่ และcontext

1. **[TC-P1-02-01]** ทีมAครอง→ปล่อย/ส่ง/ยิง→wall/ceiling→Bบล็อกบอลแรงแล้วเด้ง: Aทั้งทีมยังยิง/ส่ง/ยิงโค้ง; เมื่อBครองได้จริงจึงสลับทั้งทีม ตรวจactualholderแยกcontext/reset
2. **[TC-P1-02-02]** ยิงตรง/ปุ่มยิงโค้งโดยตรง/Passแบบเดียวหลายมุมและแรง/ชาร์จ/เล็ง3Dและfirst-timeจากบอลชิ่งที่อยู่ในระยะได้ ไม่มีบอลในระยะยิงไม่ได้และinputเก่าไม่กลายเป็นสไลด์กลางคัน
3. **[TC-P1-02-03]** DirectionalJumpล็อกทิศกลางอากาศ เดิน/Sprint/Dash/ShiftLock/Header/Volley/Blockใช้จริง Serverตรวจmove/cost/contacts; ไม่อ้างว่าปุ่มมีชื่อแล้วผ่าน
4. **[TC-P1-02-04]** จิ้ม/ยืนตัดบอลพื้นความเร็วรับไหวได้ครอง ลูกแรง/สูงโดนตัวเด้งอิสระ เกณฑ์สูง/เร็ว/ระยะและconfigที่ทดสอบระบุชัด ไม่รับทุกลูกอัตโนมัติ
5. **[TC-P1-02-05]** Staminaไม่พอไม่ออกท่าที่จ่ายไม่ไหว ยังเดิน/ยิง/ส่ง/ยืนตัดบอลได้ ล้าแตะบอลห่างขึ้นตามconfigไม่สุ่มเสียบอล การregen/resetไม่มีเกินเพดานหรือค่าติดลบ
6. **[TC-P1-02-06]** ทดสอบปล่อย/รับ/ตาย/ออกเกม/เปลี่ยนroundไม่ค้างผู้ครอง/teamcontext/contacts; callbacksเก่าไม่ทับgenerationใหม่ fixtureไม่เปิดMatch/economy

Ownerdelta2026-10-21เพิ่มacceptance02 (ทุกข้อNOT RUNหลังport; ผล34/34และ141/141ในAGYfix-001เป็นhistorical ไม่รับรองsourceใหม่):
7. **[TC-P1-02-07]** ดึงselectedSprint/Dash/kick/Pass/curve/gaugeจากprototype3ที่ระบุhash ปรับR6และรักษาfix-001groundrest/cameraDash/Knock-onครั้งเดียว/StateChangedjump/servercharge/finite/lifecycle ไม่เปิดSkillMoves/Feint/secondballloop
8. **[TC-P1-02-08]** keyboard/mouse→server→ball→segmentedgaugeจริง Passหนึ่งชุดเล็งต่ำ/สูง/ชิ่งตามมุมและแรง ไม่มีT/LobPass; ส่งlegacyLobPassต้องrejectไม่mutation รวมfirst-timePassไม่กลายเป็นShootเอง
9. **[TC-P1-02-09]** ฝ่ายรับใช้Slideเท่านั้นในรอบนี้ ทดสอบhit/miss/near-miss/ground-air/cost/CD/recovery/contact/cleanup ไม่มีauto-stunหรือauto-possession; contextเปลี่ยนขณะholdยกเลิกintentเก่า ไม่เปลี่ยนShootเป็นSlideกลางคัน
10. **[TC-P1-02-10]** เกจhold/tap/เต็ม/ปล่อย/cancelตรงservercharge เมื่อdeath/respawn/reset/focuslost/exhausted/contextstaleไม่ค้างและไม่ยิงซ้ำ start→releaseใช้intentเดียวกันได้ครั้งเดียว start→cancelแล้วreleaseต้องreject duplicateในphaseเดิมไม่mutation และfailurefeedbackไม่ล้างintentใหม่ ไม่อ้างclipid/12tracknameเป็นR6poseผ่าน

### 03 Skill Moves และเกมรับ

1. **[TC-P1-03-01]** เป้าหมาย 7 ท่าไม่ซ้ำ (1★ Knock-On, 1★ Open Up Fake Shot, 2★ Body Feint, 3★ Heel Chop, 4★ Sombrero Flick, 4★ Lane Change, 5★ Elastico) ติดตั้ง 3 ช่องเลือกได้ข้ามระดับภายในเพดานตัวละคร (Drag Back & Turn และ La Croqueta เป็นท่า Retired ทางประวัติศาสตร์); ตัวทดสอบเพดาน 5 ดาว ไม่มี 15 ท่าหรือ gacha/persistence ใน Demo
2. **[TC-P1-03-02]** กดช่อง+ทิศเริ่มได้ทุกท่า มี R6 ท่าร่างที่อ่านจังหวะ/ทิศได้ (5 ท่าเดิมที่ถูกปฏิเสธอยู่ในกระบวนการปรับแก้ตาม HANDOFF §Q รอตรวจรับ visual); loaded asset/provenance และ runtime pose ตรวจจริง ไม่ใช้แค่ ID/track name เป็น PASS
3. **[TC-P1-03-03]** ทุกท่ารวมDashยังสัมผัสบอลเพื่อสกัดได้ระหว่างanimation ไม่มีI-frame/ล็อกคู่/ชนะmatrix/ผู้ชมถูกตัดกล้อง/ปุ่มFeintเดิม
4. **[TC-P1-03-04]** Slideพื้นฐานportใน02แล้วตรวจreuse/regressionใน03 (ขยายตาม Sliding, คลุมบอล +0.8 studs ด้วย Clean Sweeper D3); Quick Pokeสั้นไว (ระยะตาม Poke Reach, ไวขึ้น 20% ด้วย Lightning Poke #18); Body Check พุ่งชนด้านหน้าเปรียบเทียบ Strength ต่าง (สูตรคำนวณละเอียด PENDING รอการจูน) บอลหลุดเป็น Loose Ball (ไม่มี auto-possession, ไม่มี I-frame, วืดติด recovery โดยลด 25% ด้วย Elastic Recovery #19) ครองต่อได้เมื่อเข้าถึงจริง ผลฟาวล์อ่านต่อจาก05
5. **[TC-P1-03-05]** ชนคู่แข่งธรรมดาช้าลงแต่ไม่สั่งเสียบอลจากชนตัวอย่างเดียว เพื่อนผ่านตัวกันได้แต่บอลยังรับ/บล็อกตามcontact; ยืนบล็อกไม่ดูดลูกแรง/สูง
6. **[TC-P1-03-06]** skillCDแยก จ่ายต้นทุนได้ก่อนออก ต้องจบช่วงท่าร่วมก่อนต่อ; กด3ช่อง/Dash/สกัดลัดช่วงล็อกไม่ได้
7. **[TC-P1-03-07]** recoveryพลาดช้าลง/ล็อกSkillDashเข้าสกัดซ้ำ ยิงส่งเมื่อท่าเอื้อ สไลด์รอลุก ตรวจsuccess/fail/interrupt/reset ไม่ใช้stunแพ้ดวลเก่าหรือfirst-time miss penaltyของPhase2
8. **[TC-P1-03-08]** เปลี่ยนloadoutเฉพาะก่อนรอบ/หยุดรีเซ็ต; เปลี่ยนกลางเล่น/ใช้slotไม่ถูก/ดาวไม่พอ/invaliddirหรือstalegenerationถูกrejectจริง ไม่ล้างCDด้วยการเปลี่ยนชุดกลางจังหวะ

### 06 Debug/Training และ08 UI

1. **[TC-P1-06-01]** ปรับ 13 Outfield Base Stats (ช่วง 0.90–1.15, ค่ากลาง 1.00), สลับ 16 Trait Toggles, และสลับ 5 Character Archetype Presets (Speedster Striker, Cage Playmaker, Power Target, Iron Stopper, Sweeper Destroyer) เฉพาะ test session; อ่าน Server effective ค่าแล้ววัด runtime ตรง config คืน default/จบ session ไม่มี override ค้าง ไม่เขียน profile/default source ถาวร
2. **[TC-P1-06-02]** เสก/เลือก/ย้าย/ทีม/จำนวน/preset/ลบ/resetDummyหลายรอบ มีlimitและcleanup ไม่สะสมconnections/timers/ผู้ครองบอลหรือทำลายinstanceนอกscope
3. **[TC-P1-06-03]** invalidvalues/เกินrange/ไม่มีสิทธิ์ไม่เปลี่ยนค่าทดลอง; scenario/config/seedและinitialcontextระบุให้ทำซ้ำได้ ไม่เปิดsettingsจริงหรือAIจากแผนที่ยังไม่พร้อม
4. **[TC-P1-08-01]** label3คู่ตรงServercontext/CD/cost/recovery,3slotsเลือกก่อนรอบ,เปลี่ยนcontextขณะกดไม่เปลี่ยนintent,reset/respawnคืนinput/กล้อง
5. **[TC-P1-08-02]** ไม่มีChoice Modal/ParryPrompt/คัตซีนล็อกคู่หรือUIสุ่ม/แมตช์/ตลาดที่Phase2ยังไม่ทำ; visualอ่านท่าจริงที่ไม่ได้ตรวจยังNOT VERIFIED

### 07 Event 4 — Rebound Rush (Accepted / NOT RUN)

1. **[TC-P1-07-01]** A/B/C: wall/ceiling/bevelเข้าtargetSpeedคงที่ floor/ramp/goalframe/player/pillar/NPCไม่boost ตรวจspeed/normal/surfaceIDจริง
2. **[TC-P1-07-02]** ชนต่อเนื่องไม่สะสมtargetหรือคูณbumperซ้ำ contactค้าง/ส่งซ้ำ/มุมหลายผิวในstepเดียวไม่เพิ่มแรงซ้ำ บอลเร็วกว่าtargetไม่ถูกลดเพราะevent
3. **[TC-P1-07-03]** จบ/cancel/switchไม่มีvelocityลดฉับพลัน contactsใหม่ไม่boostและคืนresponseปกติ ตรวจbounceหลังEndและstatecleanup
4. **[TC-P1-07-04]** Debugเปลี่ยนtarget/Active durationเฉพาะsessionและคืนdefaultได้ ปฏิเสธค่าที่ไม่finite/เกินenvelopeที่solverรองรับ รายงานconfig/speed/dt/radiusที่ตรวจ ไม่อ้างผ่านจากUIมีปุ่ม

5. **[TC-P1-07-05]** Overdriveทุกทีม/actorใช้Staminaไม่จำกัดระหว่างActive แต่Dash/Skill/สกัดยังเคารพCD/recovery/ballreach ไม่มีI-frame/บัฟspeedหรือshotpowerเพิ่ม
6. **[TC-P1-07-06]** highlightแสงวิ่ง/infiniteindicatorตรงeventstate latejoin/respawn/reset/cancel/switchไม่ค้าง UI/resource EndเติมStamina100%ครั้งเดียวแล้วกลับใช้ปกติ CD/recoveryเดินต่อไม่reset Endซ้ำไม่เติมให้generationเก่า
7. **[TC-P1-07-07]** LowRoofA/B/Cใต้เพดานflat12จากplayingfloorจริง ทดสอบsweptballcontactระหว่างลด/Active/คืน geometryตรงภาพ ไม่มีbevel/planeซ้ำหรือช่องหนีที่seams
8. **[TC-P1-07-08]** บอลอยู่สูง/ผู้เล่นกระโดด/GK/คานประตูไม่ถูกทับค้างหรือตัดผ่านโดยteleportกลบ End/cancelคืนoriginalroof/attributes/contactsครบ เก็บเวลาชิ่งจริง ไม่อ้าง2เท่าอัตโนมัติ

### Phase2 deferred gates

- **[TC-P2-DEFER-01]** ต้องมีสุ่มตัวละคร03 (รองรับ 13 Outfield Stats ขอบเขต 0.90–1.15, 4 Deferred GK Stats หลัง 04, 16 Innate Traits ติดตัวละครผันแปร 0..N รายการ, 5 Archetypes เพดาน 2★–5★, ถอด Trait slots/หิน Trait ออกจาก Target)/สุ่มสกิลพร้อมinventory04/สุ่มเอฟเฟค05ผ่านtransactions02ก่อนmetaUI07; สูตร/เรต/ราคา/pity/reroll/ของซ้ำ/ดาวเปิดgrillก่อนimplementation ไม่เพิ่มค่า/พลังถาวรจากDebug
- **[TC-P2-DEFER-02]** แอนิเมชันและเสียจังหวะเมื่อfirst-timeยิงส่งวืดต้องส่งมอบจากimplementationcontractงานขยายก่อนFullUAT08 ไม่ใช้เป็นgatePhase1และไม่เขียนแทนในงานUAT

## Historical module acceptance — Superseded reference

รายการด้านล่างเป็นbaselineเก่าที่เก็บตรวจย้อนหลัง โดยเฉพาะParry/Choice/Signature/คัตซีน/เลขโมดูลถูกsupersedeตามQ22 ไม่ใช่gateปัจจุบันและไม่ให้เปิดระบบเก่าก่อนsync

### Module 02: `02-ball-control-and-parry`
1. **`[TC-02-01]` Parry vs Duel Separation:** เมื่อส่งบอลหรือยิงบอลผ่านรัศมี `5 Studs` ของกองหลัง ระบบต้องขึ้นสัญญาณ `Parry` (`0.35 วินาที`) เสมอ โดยไม่ตัดเข้าหน้าจอดวล Choice
2. **`[TC-02-02]` Server-Verified Parry Timing:** การตรวจสอบจังหวะกด `Parry` คำนวณฝั่ง Server ป้องกันการโกงเวลาจาก Client หากกดพลาดติด Recovery Cooldown `0.5 วินาที`

### Module 03: `03-duel-choice-engine`
1. **`[TC-03-01]` Shooting Zone Check:** ชอยส์ `Snap Shot` ต้องไม่ปรากฏให้กดเด็ดขาดหากผู้ถือบอลอยู่นอก `Shooting Zone`
2. **`[TC-03-02]` Shot Block Exclusivity:** กองหลังมีชอยส์ `Shot Block` ให้เลือกเฉพาะตอนอยู่ในหน้าจอดวล 1v1 (`<= 6 Studs`) เท่านั้น
3. **`[TC-03-03]` Mistake Mechanics:** เมื่อ Stamina `< 15%`, จับบอลแรกแย่, หักเลี้ยว 180 องศา, สไลด์วืด หรือหันหลังให้บอล ระบบลดเวลาเลือก (`0.8s -> 0.45s`) และล็อกชอยส์ตามตารางส่วนที่ 4.3 อย่างถูกต้อง

### Module 04: `04-cards-animations-freekick`
1. **`[TC-04-01]` Signature Choice Cooldown & Buffs:** ชอยส์พิเศษของนักเตะดังติด Cooldown ทันทีหลังใช้ และมอบบัฟตามเวลาที่กำหนดจริง โดยสเตตัสการ์ด Tier สูงห่างจากการ์ดเริ่มต้นไม่เกิน 15%
2. **`[TC-04-02]` Tier Cutscene Limit:** จำนวนอนิเมชันชนะดวลไม่เกิน 3 ท่าต่อตัวละครตามระดับ Tier (`B=1`, `A=2`, `S=3`)
3. **`[TC-04-03]` FC27 Free Kick Physics:** ระบบฟรีคิกคำนวณวิถีโค้ง (`Magnus Effect`) และการส่าย (`Knuckleball`) ตามจุดสัมผัสบอลและแถบจังหวะได้จริง

### Module 05: `05-dynamic-match-events`
1. **`[TC-05-01]` The Blackout Void:** ขอบกรงและเพดานมองไม่เห็นด้วยตาเปล่า แต่ยังสะท้อนลูกบอลได้เหมือนเดิม และเห็นเสาโกลเรืองแสง ลูกบอลนีออน และตัวผู้เล่นชัดเจน
2. **`[TC-05-02]` Favela Alleyway & Pillar Lockdown:** ตำแหน่ง NPC คนเดินผ่านซิงก์ตรงกันทุกผู้เล่นและสะท้อนบอลได้จริง ส่วนเสาคอนกรีตมีวงเตือนล่วงหน้า `1.5 วินาที` ก่อนผุดและชิ่งบอลได้ 100%

### Module 06: `06-traits-threads-economy`
1. **`[TC-06-01]` No Boots & Zero P2W Mutations:** ยืนยัน 100% ว่าไม่มีระบบรองเท้าสตั๊ด และ `Mutated Gear` ไม่บวก Speed, Shot Power หรือโอกาสชนะดวลในสนาม
2. **`[TC-06-02]` Server Trait Cooldown:** หิน `Trait` ทุกชิ้นมี Cooldown ฝั่ง Server ไม่สามารถกดใช้รัวๆ ได้
3. **`[TC-06-03]` Atomic Trade Lock:** ระบบเทรดมีการล็อกธุรกรรมป้องกันไอเทมสูญหายหรือปั๊มของซ้ำ

### Module 07: `07-ui-navigation-and-screens`
1. **`[TC-07-01]` Complete Screen Routing:** กดเชื่อมต่อไปยังทุกหน้าจอ (`MainMenu` -> `Lobby` -> `Locker` / `Summon` / `Trade` / `ModeSelect` -> `PreMatch` -> `MatchHUD` -> `PostMatch` -> `Lobby`) ได้ครบโดยไม่มีหน้าต่างค้างหรือซ้อนทับกัน
2. **`[TC-07-02]` Locker Sync:** สวมใส่การ์ด, ชุด `Battle Threads`, และหิน `Trait` แล้วข้อมูลอัปเดตตรงกับ Server ทันที
3. **`[TC-07-03]` Duel Modal Locks:** ปุ่ม `Snap Shot` ถูกล็อกหากอยู่นอกระยะยิง และแสดงไอคอนแม่กุญแจสีแดงเมื่อติด `Mistake`

### Module 08: `08-integration-and-uat`
1. **`[TC-08-01]` End-to-End Match Loop:** เชื่อมต่อวงจรแมตช์ตั้งแต่เลือกตำแหน่ง เข้าแข่ง สลับอีเวนต์ จบแมตช์คำนวณรางวัลคูณตาม `Mutated Gear` และแสดงผลที่ `PostMatchSummaryScreen` ครบถ้วน

### 02 — Owner visual rework / fix-003 (NOT RUN)

- **[TC-P1-02-11]** RealR6selectedSprint/Dash/chargeShoot/Pass/Curve/Slideอ่านท่าต่างกันตามprototype3 ไม่มีjumpclipแทนSlide; worldpose/stancefoot/clearanceและsourceprofilemappingตรวจจริง ไม่ใช้assetID/13tracks/TC40schemaแทนvisualผ่าน
- **[TC-P1-02-12]** ShiftLockเริ่มON L/LeftAlt/RightAlttoggle, ShiftยังSprint, cursor/shoulderตามSandbox; normalyawตามcameraแต่Slide/Jumpคงทิศที่commit ไม่มีcamerafight/drift Menu/TextBox/focuslost/death/reset/respawnคืนstateครบ ทดสอบ30/60/120fpsตามที่ทำได้ ไม่บังคับscreenshot/video
- **[TC-P1-02-13]** ส่งmissing/wrongmetadata/legacy/invalidphase/cross-intent-release/chargeActionไม่ตรง/terminalreplayแล้วไม่มีball/resource mutation; releaseไม่มีstartไม่เลือกpowerจากclient ส่วนstart→release/cancelที่ถูกต้องทำครั้งเดียว
- **[TC-P1-02-14]** TeamAครอง→BSlidehitบอลInFlightไม่ครอง: AยังบุกจนBรับจริง; hitไม่ติดmisspenalty missจึงrecover/Dashถูกบล็อก predictionreject/earlyreleaseกลางair/focuslostไม่ค้างforces/charge/WalkSpeed
- **[TC-P1-02-15]** บอลแรงชนพื้นแล้วsolverคืนvelocityขึ้นต้องยังเด้ง ไม่ถูกgroundsettleตัด ส่วนบอลนิ่ง/lowenergyหยุดได้; jumpผู้เล่นจริงห้ามหักvelocityแนวราบ ไม่ตรวจแค่mockoverride; callbacksของcharacterเก่าไม่แก้ตัวใหม่

OwnervisualREJECTEDหลังfix-002ไม่หายไปเพราะ40/40Edit เมื่อทำfix-003ต้องfreshEdit/Live/visual/affected01regressionผูกhashปัจจุบัน เอฟเฟกต์เต็มแผนอื่นไม่เป็นblocker02
