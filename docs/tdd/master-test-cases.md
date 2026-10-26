> **CURRENT TARGET 2026-10-26 — Street Football:** [authoritative Phase1 plan](../plan/phase-01-gameplay-demo/release-first/plan.md) supersedes conflicting target/delivery statements below (retained as historical/reference). Phase1: R15/core ball + kick/slide/poke/block/normal body-check, separate CombatHP/stun/I-frame, gauge+ground/air Orbs, **RF04 walls BEFORE six Supers**, one-use timed armed Super/manual aim/no homing/no guaranteed goal, capped gauge-rate-only per-copy earnedCash upgrade,2v2/tiedGoldenGoal. Remove foul/free kick/cards/penalties/regular overtime/SuperMastery power scaling. Extra dribble skills/gacha/13stats/Traits/advanced aerial hold+guides/shops deferredPhase2; walls remainPhase1. Owner approved docs commit and checklist7 dribble/receive plus later explicit high momentumjump/four-way airlean and relevant locomotion fixes now; no blanket source implementation/commit/push/publish authority. Owner first6 visual accepted; technical review remains separate. Historical code/reviews/findings not erased.

# Master Test Cases & TDD Acceptance Criteria (`docs/tdd/master-test-cases.md`)

เกณฑ์ปัจจุบันปรับปรุงตามคำสั่ง **Owner Override 2026-10-25**: ยกเลิก legacy 02/03 (`CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART`) เพื่อเดินหน้า [Release-First Track](../plan/phase-01-gameplay-demo/release-first/plan.md) บน **Player Avatar R15 (Normalized to Same Body Dimensions)** (`RF-02` ถึง `RF-07`) มุ่งสู่ Public Alpha; เกณฑ์ใหม่ด้านล่างเป็น Planned/NOT RUN แยกจาก historical baseline ชัดเจน

## กฎเหล็กทั่วไปที่ต้องตรวจทุก Module (Global Invariants)
- `[INV-01]` ลงมือตาม phase/dependency และ HANDOFF ที่ Owner อนุมัติ implementation; Codex ตรวจหลักฐานอิสระ ไม่ใช้ APPROVED เก่าข้าม gate
- `[INV-02]` สำหรับ **Release-First Track (`RF-02`..`RF-07`) ใช้ Player Avatar R15 (Normalized to Same Body Dimensions)** ผู้เล่นใช้โมเดล Avatar ของตนเองแต่ถูก Normalization ให้ขนาดมิติร่างกายและ Collision/Contact geometry เท่ากันทั้งหมด (Scale numbers เท่ากันไม่รับประกันขนาดจริงของ arbitrary body packages จึงต้องมีระบบ Normalization; ขนาดไม่เปลี่ยนตาม Stats/Cards); R6 เดิมคงไว้เป็น historical reference
- `[INV-03]` ห้ามมีระบบรองเท้าสตั๊ด (No Boots/Cleats System) มีเฉพาะชุด `Battle Threads` (คอสเมติกเท่านั้น ไม่มี Trait slots และไม่มีหิน Trait ใน Target)
- `[INV-04]` ห้ามให้ `Mutated Gear` เพิ่มสเตตัสในสนาม (เพิ่มเฉพาะราคาขาย, VFX, และตัวคูณ Cash/EXP หลังจบแมตช์)
- `[INV-05]` Skill Moves/ท่าเข้าสกัดตรวจ cost/CD/recovery บน Server; 16 Innate Traits เป็นคุณสมบัติติดตัวละครเท่านั้น (ผันแปร 0, 1, 2, ... รายการ); Trait ตรวจสอบเงื่อนไขบน Server ไม่คืนผลชนะ Choice จาก baseline
- `[INV-06]` บอลสัมผัสได้ตลอดทุก Dash/Skill ไม่มี I-frame/Choice trigger/สโลว์เปิดดวล/คัตซีนล็อกคู่/timedParry
- `[INV-07]` ปุ่มตามทีมที่ครองสำเร็จล่าสุดแยกจาก actual holder; block/wall/ceiling ไม่เปลี่ยน team context ยิง/ส่งต้องมี ball reach จริง; ไม่มี ball teleport หรือ auto-catch (ยกเว้นข้อยกเว้นการรับบอลกลางอากาศที่สัมผัสบอลจริงและผ่านเกณฑ์ความเร็วสัมพัทธ์ตาม Owner Decision; ห้ามการวาร์ปบอลจากระยะไกล)
- `[INV-08]` Phase 1 Release-First ใช้ 3 Launch Skills บน R15 (Heavy Knock-On, Open Up Fake Shot, Body Feint) ติดตั้ง 3 ช่อง; อีก 4 ท่า (Heel Chop, Sombrero Flick, Lane Change, Elastico) เก็บเป็น catalog reference สำหรับ Phase 2
- `[INV-09]` หน้าจอ UI ทั้งหมดต้องควบคุมผ่าน `UIManager.luau` ตัวเดียว ห้ามเปิดหน้าต่างซ้อนทับกัน
- `[INV-10]` การคำนวณสำคัญทั้งหมดต้องเป็น `Server-Authoritative 100%`

---

## เกณฑ์ตรวจรับ Release-First Track (Planned / NOT RUN)

### RF-02: Core Football & R15 Foundation
- **[TC-RF02-01] R15 Rig & Normalization Integrity:** Player Avatar R15 ถูกโหลดและ Normalize ขนาดร่างกายให้มีมิติ/ความสูงเท่ากันตามเกณฑ์มาตรฐาน, Motor6D joint hierarchy ถูกต้อง, ค่า HipHeight มาตรฐาน, Attachments สัมผัสบอลครบ และไม่มี collision จาก accessories
- **[TC-RF02-02] Ball Contact, Anti-Teleport & Aerial Reception:** ลูกบอลสัมผัสเท้าด้วย Raycast/Hitbox จริง; บอลไม่ teleport เข้าเท้าจากระยะไกล; ข้อยกเว้นเฉพาะการรับบอลกลางอากาศ (Assisted Aerial Reception) ที่อนุญาตให้ครองบอลและเข้าสู่ Brief Airborne Hold ได้เมื่อชน Hitbox จริงและ relative approach speed อยู่ในเกณฑ์ (หากความเร็วสัมพัทธ์สูงเกินจะสะท้อนเป็น Loose Ball)
- **[TC-RF02-03] Passing & Shooting:** ส่งบอลแบบ Manual 3D ตามแรงชาร์จ, ปุ่มขอบอลส่งสัญญาณ Marker เท่านั้น (No auto-pass), ยิงตรงและยิงโค้งแยกปุ่ม
- **[TC-RF02-04] Jump, Air Lean, Brief Hold & Whiff:** Directional Jump ล็อกทิศกลางอากาศ; เมื่อรับบอลกลางอากาศสำเร็จเข้าสู่ Brief Airborne Hold ชั่วครู่เพื่อเล็ง/ง้างยิงก่อนร่วงลงปกติ (ไม่มี I-frame บอลแย่งได้ตลอด); เตะวืดติด Whiff Penalty
- **[TC-RF02-05] Basic Defense & Target Controls:** ปุ่มควบคุมตรงตามมติ Owner Q6 (LMB: Shoot/Slide, E: Pass/Poke, RMB: Curve/ForwardBodyCheck, MMB: Retired); Slide Tackle พุ่งสกัดต่ำ (พลาดรอลุก), Quick Poke สะกิดบอลระยะประชิด (ไม่มี per-move cooldowns); โกลเซฟได้จากการสัมผัสบอลจริงเท่านั้น ไม่มีการเซฟอัตโนมัติจากการพุ่งถูกทิศทาง
- **[TC-RF02-06] Profile & Config:** PlayerProfile schema บันทึก DataStore ถูกต้อง, BalanceConfig ควบคุมตัวแปรสมดุลจากส่วนกลาง

### RF-03: R15 Skill Moves & Defense
- **[TC-RF03-01] 3 Launch Skills:** Heavy Knock-On, Open Up Fake Shot, Body Feint ทำงานบน R15 ตรง Contact Frame
- **[TC-RF03-02] Counterplay & No I-frame:** ผู้เล่นที่ทำ Skill Move สามารถถูก Slide หรือ Poke แย่งบอลได้กลางท่า
- **[TC-RF03-03] Slots & Stamina:** ติดตั้งได้ 3 ช่อง และใช้ Stamina ตาม BalanceConfig
- **[TC-RF03-04] Owner Visual UAT:** ผ่านการตรวจรับทางสายตาจาก Owner รายท่า

### RF-04: Cage Slingshot
- **[TC-RF04-01] Wall Run:** วิ่งไต่ผนัง Stadium A 4 ด้านได้ราบรื่น ใช้ Stamina ต่อเนื่อง
- **[TC-RF04-02] Wall Launch:** ดีดตัวออกจากกำแพงด้วยความเร็ว 1.7x Sprint, Windup 0.20s, Landing Recovery 0.20s
- **[TC-RF04-03] Wall Launch Aerial Reception & Rebound Prediction:** ดีดตัวออกจากกำแพงเข้าชน Hitbox บอลกลางอากาศเพื่อรับบอลครอง (Relative approach speed gated); แสดงเส้นทางวิถีบอลชิ่งผนัง/เพดานและจุดตกล่วงหน้าให้ทุกคนเห็นแบบเรียลไทม์

### RF-05: Character Gacha, Stats & Traits
- **[TC-RF05-01] 3 Characters & 13 Stats:** ตัวละคร 3 ตัวมีความแตกต่างของสถิติ 13 ค่า (0.90..1.15) ส่งผลต่อ gameplay จริง
- **[TC-RF05-02] 3–4 Active Traits:** Traits ติดตัวละครทำงานถูกต้องตามเงื่อนไข
- **[TC-RF05-03] Cash Gacha Persistence:** สุ่มตัวละครด้วย Earned Cash ฝั่ง Server บันทึก DataStore สำเร็จ ไม่เบิ้ล

### RF-06: Match, HUD & Economy
- **[TC-RF06-01] Casual 2v2 Flow:** แมตช์ 4 ผู้เล่นเริ่ม แข่ง ยิงประตู นับคะแนน และจบการแข่งขันสมบูรณ์
- **[TC-RF06-02] Concise HUD & Trajectory Guides:** Stamina bar, 3 Skill slots, Scoreboard, Timer ตอบสนองทันที; เส้นวิถีโค้งและจุดตกบอลลอยฟ้าแสดงให้ทุกคนเห็น; Prerelease Aim Preview แสดงเฉพาะคนง้างยิง
- **[TC-RF06-03] 1 Cosmetic Shop & Reward:** ได้รับ Cash หลังจบแมตช์ ซื้อ Cosmetic 1 รายการและสวมใส่ได้

### RF-07: Publish Gate
- **[TC-RF07-01] ProcessReceipt Idempotency:** รับชำระเงิน Robux 1 รายการแบบ Idempotent ป้องกันของเบิ้ล
- **[TC-RF07-02] Multiplayer 4-Player UAT:** เล่นจริง 4 คน ไม่พบบอลหาย บอลวาร์ป หรือบั๊กหลุดเฟรม
- **[TC-RF07-03] Owner Sign-off:** Owner ตรวจรับและกด Publish สู่ Public Alpha ด้วยตนเอง

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

## Street Football acceptance matrix — 2026-10-26 current target
All rows PLANNED / NOT RUN for new systems; Owner old visual acceptance is not a runtime security test.
| Group | Required cases | Task |
| --- | --- | --- |
| Contact/HP | kick flinch retains ball including zeroHP; slide fall loose; normal body-check miss; no combat death; regen/stun1..1.5; protection rejects damage+gauge; same victim NEW action afterI-frame legal | T05 |
| Gauge/Orb | event replay/one collision repeated callbacks; source earn budgets; victim>attacker at different upgrades;0/99/100 clamps; ground+air Orb; ball/player simultaneous claim; stale/unknown last toucher leaves Orb | T06 |
| Walls before Super | wallrun/launch/contact receive/finish/counterplay/ceiling/corner/noI-frame | T07 |
| Six Supers | each manual aim/no homing/telegraph/miss;100 arm debit,one use,expiry,duplicate execute,reset/leave; Frost protection; Overdrive envelope; Breaker knockback/cage cap; seeded Knuckle fast multi-bounce | T08 |
| Upgrade | earnedCash-only,selected owned copy,cap/rate-only,no power/stamina changes; concurrent debit/retry/rejoin returns same durable result | T09 |
| Match | lead timeout end,tie->GG,first goal atomic win,no penalties/overtime/TeamA tied winner; clock-boundary goal,double sensor,disconnect cancellation,shutdown/reward replay/reset | T10 |
| Momentumjump/Airlean | stand<walk<sprint forward distance,higherjump,vy slows apex then falls,4-way lean/neutral,ceiling/ledge/rapidjump/death cleanup; aim seam only/no shooting change; fake boosted velocity rejected | active checklist7 delta |
| Network/performance |4clients+50..150ms,simultaneous contact,NaN/inf/malformed/spam,stale generation; same baseline step time/query/network/instances; publish clip IDs/permissions | each +T12 |
No removed foul/free-kick/card/penalty/overtime tests are release requirements; old cases below/above are historical where conflicting. Exact commands and outcomes required per task; no fabricated PASS.