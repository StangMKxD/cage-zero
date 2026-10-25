# Spec 02 — ฟุตบอลต่อเนื่อง, Skill Moves และเกมรับ

> **Owner Directive 2026-10-25 (Release-First on Player Avatar R15 Equal Size):** แผน legacy 02 และ 03 เดิมถูกยกเลิก (`CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART`) และแทนที่ด้วย Release-First Track บน **Player Avatar R15 (Normalized to Same Body Dimensions)** (แทนที่ Custom Blocky R15 เดิม; รักษาอัตลักษณ์ผู้เล่นแต่บังคับขนาดร่างกายเท่ากันทั้งหมด; ขนาดไม่เปลี่ยนตาม Stats/Cards): [RF-02 Core Football & R15 Foundation](../plan/phase-01-gameplay-demo/release-first/RF-02/plan.md) และ [RF-03 R15 Skill Moves & Defense](../plan/phase-01-gameplay-demo/release-first/RF-03/plan.md). ท่าเปิดตัว Alpha มี 3 ท่าบน R15 คือ Heavy Knock-On (1★), Open Up Fake Shot (1★), Body Feint (2★) ติดตั้ง 3 ช่อง; อีก 4 ท่า (Heel Chop, Sombrero Flick, Lane Change, Elastico) เก็บเป็น catalog อ้างอิงสำหรับ Phase 2; บอลมี Hitbox กายภาพตลอดเวลา ไม่มี I-frame, ไม่มี ball teleportation และไม่มี auto-catch (ยกเว้นข้อยกเว้นการรับบอลกลางอากาศที่สัมผัสบอลจริงและผ่านเกณฑ์ความเร็วสัมพัทธ์ตาม Owner Decision; ห้ามการวาร์ปบอลจากระยะไกล); ปุ่มควบคุมเกมรับ/รุกตรงตามมติ Owner Q6 (LMB Shoot/Slide, E Pass/Poke, RMB Curve/ForwardBodyCheck [Pending Launch], MMB retired)

### Latest Owner delta — core FakeShot aim-side ball touch (2026-10-24)

- Grounded attacking LMB/RMB charge + E retains core FakeShot cancel/terminalization behavior, but a valid controlled-ball contact must visibly touch/cut the ball left/right from the AIM side at activation; stationary/cosmetic-only FakeShot is superseded.
- Server validates aim/side/ownership/contact/recovery and uses one shared character-relative direction for ball and pose. Camera/movement disagreement must follow aim; no world-X/A-D-only substitute, teleport, weld, invulnerability or unowned-ball capture. Existing stale-release/replay/reset/airborne/range safeguards remain.
- This is separate from queued OpenUpFakeShot1★ loadout skill. Exact implementation/neutral-policy/tuning evidence and tests: Plan02 primary HANDOFF§23/T16; no approval/closure or unrelated scope change.

> **Owner latest possession pop:** Grounded+personalpossession+Space=BallPopตามmovement ตัวยังอยู่พื้น แล้วkeyup/pressใหม่เมื่อballfreeจึงเป็นjumpปกติตาม[HANDOFF02§16](../plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md). คงballphysicsเดิม เปลี่ยนเพียงinitialpoplaunch ไม่auto-jump/ไม่สร้างSkill03ใหม่.

> **Owner jump adaptation:** ตาม[HANDOFF02§15](../plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md)ปรับjumpเป็นstate-based+singlelaunch โดยยังล็อกmomentum/facingและให้mouseaim3Dได้. หนึ่งvalidmanualairreleaseต่อflight;Rising/Apex/Fallingออกบอลได้เมื่อvalidcontact และapexให้ผลดีที่สุดแบบsoftcontinuous ไม่hardgate. คงaim-relativeboundedlean/ปุ่มล่าสุด;ไม่มีStyles/JumpMeter/SnakeJumpหรือcamera-lockเพิ่ม.

> **Owner latest tuning:** airshotเปลี่ยนมาใช้aim3D/เป้าที่เล็งเป็นฐานแล้วเบี่ยงเพียงเล็กน้อยตามleanตาม[HANDOFF02§14](../plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md) แทนlockedF0shotbaseด้านล่าง;F0ยังใช้ล็อกyaw/ทิศบินcharacter. Wเอนหน้า/Sเอนหลังและต้องsmooth;ลดBloom/Haze/ballglowแบบpresentation-onlyโดยไม่เปลี่ยนสีทีม/geometry/physicskernel. Plan02ยังไม่ปิด.

> **Owner delta 2026-10-23:** ปุ่มmanualshootของ02เป็นgroundLMB Direct/RMB Curve และairLMB Direct/RMB Volley;หนึ่งphysicalbindingต่อaction. GroundA/ซ้าย=Finesse,D/ขวา=Trivela. AirWASDใช้bodypitch/rollโดยไม่เปลี่ยนyaw/ทิศบินที่commit;balllaunch/spinคำนวณServerจากlockedfacing+aimelevation+acceptedleanตาม[HANDOFF02§12](../plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md). ข้อความairconversion/Headerfallbackเก่าที่ขัดถูกแทนเฉพาะขอบเขตนี้;ไม่ได้เปิดPlan03/04หรือปิดPlan02.

Decision Accepted / Delivery Planned; Stang ยืนยัน Q1–Q22 เมื่อ 2026-10-20 “ตรงตามนี้ ปรับแผนและเอกสารได้ (แนะนำ)” อนุญาตแก้เอกสาร ไม่ใช่ implementation approval ของ02/03 พาธไฟล์เดิมคงไว้ให้อ้างอิงได้

**Owner supersession 2026-10-21:** ต่อจากAGYfix-001 ดึง sprint/dash/kick/Pass/curve+เกจจากSandbox เว้นท่าโยก ตัดLobPassแยก ดึงSlideก่อน ส่วนPoke/Shoulderทำใน03ภายหลัง; รายละเอียดการลงมืออยู่HANDOFF02 ข้อความอนุมัติเฉพาะเอกสารด้านบนเป็นรอบQ22เดิม

## 1. ขอบเขต Phase 1

- เก็บเดิน/Sprint/Dash/Stamina/Shift Lock ยิงตรง/Passแบบเดียวเล็ง3DและปรับแรงตามSandbox ไม่มีLobPass/ปุ่มส่งโด่งแยก; ยิงโค้งเป็นปุ่มออกลูกโดยตรง แยกจากยิงปกติ ไม่ใช่ modifier ที่ต้องกดคู่ยิง/ส่ง
- Directional Jump เลือกทิศเคลื่อนตัวก่อนกระโดดและเปลี่ยนทิศกลางอากาศไม่ได้; Header/Volley/บล็อกกลางอากาศใช้ระบบบอลตามแผน02 ไม่มีผลชนะทางอัตโนมัติ
- **Assisted Aerial Control & Brief Airborne Hold (Owner Decision 2026-10-25):** ข้อยกเว้นชัดเจนต่อข้อห้าม auto-catch เดิมสำหรับการเล่นกลางอากาศ: ผู้เล่นที่กระโดด (Jump) หรือ Wall Launch ที่เข้าสัมผัส Hitbox ของบอลจริงในอากาศ โดยมีความเร็วสัมพัทธ์ (Relative approach speed) อยู่ในเกณฑ์ที่กำหนด จะสามารถจับครองบอลกลางอากาศและเข้าสู่สถานะลอยค้างเล็งชั่วครู่ (Brief airborne hold) เพื่อเล็ง 3D และง้างยิงได้ก่อนกลับสู่การร่วงลงปกติ (หากความเร็วสัมพัทธ์สูงเกินเกณฑ์บอลจะกระดอนออกเป็น Loose Ball; ห้ามการวาร์ปบอลจากระยะไกล; บอลยังคงมี Hitbox แย่งได้ตลอดเวลา ไม่มี I-frame และไม่มี gameplay cooldown)
- **Goalkeeper Physical Contact Counterplay:** ผู้รักษาประตูต้องเข้าถึงตำแหน่งและมี Physical Contact กับบอลจริงในระยะที่ถูกต้อง การพุ่งถูกทิศทางเพียงอย่างเดียวไม่การันตีการเซฟประตู (No correct-direction guaranteed save)
- Skill Move 3ช่องแทนปุ่ม Feint เดิม ใช้ปุ่มช่อง+ทิศทางตอนเริ่มท่า ไม่มีคอมโบกดปุ่มเพิ่มเติมตามดาว
- Choice Duel/หน้าจอเลือกชอยส์/ตารางชนะทาง/สโลว์เปิดดวล/คัตซีนล็อกคู่/สตั้นผู้แพ้จากผลดวลถูกตัดตามQ22 ไม่เปลี่ยนชื่อแล้วเปิดกลไกเดิม
- บอลมี hitbox และถูกแย่งได้ตลอด ไม่มี I-frame ใน Dash/สกิล/การปะทะ ไม่มี timed Parry

## 2. ปุ่มตามทีมที่ครองบอลล่าสุด (TARGET vs AS-IS)

### ตารางคู่ปุ่มเป้าหมาย (TARGET Keybinding Map — 3 คู่ปุ่มหลัก)

| Context ที่ Server ยืนยัน | ปุ่มหลัก (`LMB`) | ปุ่มรอง (`E`) | ปุ่มที่สาม (`RMB`) | ปุ่มที่ยกเลิก (`MMB`) |
| --- | --- | --- | --- | --- |
| **ทีมเราครองบอล / บอลอิสระหลังบุก** | **ยิง (Shoot)** | **ส่ง (Pass)** | **ยิงโค้งโดยตรง (Direct Curve Shot)** | *RETIRED* |
| **ทีมคู่แข่งเป็นฝ่ายครองล่าสุด** | **Slide Tackle** (LMB) | **Quick Poke** (E) | **Body Check / พุ่งชน** (RMB) | *RETIRED* |

- **ข้อยกเว้นพิเศษของการชาร์จยิง (Core FakeShot Special Case):** ขณะกดชาร์จยิงบุก (LMB/RMB) อยู่ การกดปุ่ม `E` จะทำงานเป็น **FakeShot Cancel** ตัดเข้าหาทิศที่เล็งพร้อมแตะบอลเปลี่ยนมุมทันที นี่คือข้อยกเว้นของบริบทบุกเดิม ไม่ใช่ปุ่มใหม่หรือสกิลในช่อง Loadout
- **สถานะ AS-IS ในโค้ดปัจจุบัน เทียบกับ TARGET:**
  - *AS-IS ในโค้ดปัจจุบัน:* ฝั่งรับใช้ `RMB` = Quick Poke, `MMB` = CagePress (ยังไม่เปลี่ยนโค้ดตามคำสั่ง documentation-only)
  - *TARGET ตามสเปกใหม่:* ฝั่งรับใช้ `LMB` = Slide Tackle, `E` = Quick Poke, `RMB` = Body Check / Dash Tackle; ปลดระวาง `MMB` ออกจากผังปุ่มเป้าหมาย
- ทั้งทีมคงโหมดบุกหลังยิง/ส่ง/ชิ่ง ไม่ใช่เฉพาะคนออกบอลล่าสุด
- ปุ่มเปลี่ยนฝั่งเมื่ออีกทีมรับ/แย่งจนได้ครองบอลสำเร็จ การบล็อกจนบอลเด้ง/ชิ่งกำแพงหรือเพดานไม่เปลี่ยนโหมด
- การเห็นปุ่มยิงไม่ได้ให้สิทธิ์ยิงจากระยะไกล ลูกต้องอยู่ในระยะสัมผัสและเงื่อนไขเล่นบอลจริง; Phase1 ยิง/ส่งจังหวะแรกได้โดยไม่ต้องจับครองก่อน
- Server แยกผู้ครองบอลจริงจากทีมที่ยังคงโหมดบุก; fixture เริ่ม/รีเซ็ตต้องระบุ initial ball/context ชัดเจน ไม่ต้องมีแมตช์เต็ม
- การสลับปุ่มไม่ตีความ input ที่เริ่มเป็นท่าหนึ่งให้กลายเป็นอีกท่ากลางคัน; intent ที่เงื่อนไขหมดแล้วต้องยกเลิกอย่างชัดเจน

## 3. บอล การชน และเกมรับ (Body Check & Outfield Stats Integration)

- บอลพื้นที่รับไหวในระยะสัมผัสเมื่อแย่ง/ตัดได้เข้าครองได้; ลูกแรง/ลูกสูงโดนตัวให้เด้งอิสระ ไม่จับทุกลูกจากเพียงการยืนขวาง
- ชนตัวคู่แข่งธรรมดาทำให้เคลื่อนช้าลง ไม่สั่งเสียบอลทันทีจากการชนร่างอย่างเดียว เพื่อนร่วมทีมผ่านตัวกันได้; ลูกบอลยังเล่น/รับ/บล็อกตามกติกาของบอล
- **การพุ่งชน (Body Check / Dash Tackle) — แทน Shoulder Charge เดิม:**
  - *กติกา Target:* พุ่งชนไปข้างหน้าเข้าหาผู้ถือบอล ไม่ต้องเช็กมุมไหล่ด้านข้าง (Side-Shoulder) และไม่ต้องพึ่งการอัดกำแพง
  - *การคำนวณแรงปะทะ:* ใช้ค่าสเตตัส `Strength` เปรียบเทียบระหว่างผู้เล่น ส่งผลต่อการตอบสนองต่อแรงปะทะ (Contact Response) และระยะเวลาชะงัก (Stagger duration) ของผู้ถูกชน โดยสูตรคำนวณ/ต้านทานโดยละเอียดยัง PENDING รอการจูนสมดุล
  - *ผลลัพธ์ของบอล:* ลูกบอลจะกระเด็นหลุดออกจากเท้าเป็น **บอลอิสระ (Loose Ball)** ทันที เพื่อให้ทั้งสองฝ่ายเข้าแย่งเก็บบอลจังหวะสอง
  - *Invariants เด็ดขาด:* **ไม่มี Auto-Possession** (ผู้ชนไม่ดูดบอลเข้าเท้าอัตโนมัติ), **ไม่มี I-frame** ระหว่างพุ่งชน, และหากพุ่งชนวืดจะติด Recovery Lockout ตามปกติ
  - *ความต่างกับ AS-IS ปัจจุบัน:* โค้ดปัจจุบันใน runtime มี CagePress ที่ครองบอลติดเท้าในที่โล่งและปล่อยบอลเฉพาะตอนชนกำแพง; ในเอกสาร Target นี้ถูกแทนที่ด้วย Body Check บอลหลุดอิสระ
- **Quick Poke:** ระยะสั้น ออกไว เสี่ยงเสียจังหวะน้อยกว่า Slide; ระยะยื่นเท้าคำนวณจากค่า `Poke Reach`
- **Slide Tackle:** ระยะไกลกว่า พลาดแล้วต้องรอลุก; ระยะและความเร็วไถลคำนวณจากค่า `Sliding` การโดนคนก่อนบอลตรวจต่อในแผน 05
- **Block / Jump Block / Header / Volley:**
  - อาศัย contact และวิถีจริง; รัศมีตรวจจับบล็อกขยายตามค่า `Block` และลดความเร็วลูกสะท้อน
  - กระโดด Directional Jump ได้รับผลจากค่า `Jump`
- **ความเชื่อมโยงกับ Outfield Base Stats (13 ค่า) และ Character Traits (16 รายการ):**
  - กติกาการเล่นทั้งหมดถูกออกแบบให้รองรับ 13 Outfield Base Stats (ดู [notes N-61](../plan/phase-01-gameplay-demo/01-cage-physics/notes.md#n-61--accepted-decision-13-outfield-base-stats-4-deferred-gk-stats-16-innate-traits-5-character-archetypes-and-body-check-target-mechanics-2026-10-24) และ [Phase 2 / 03 Plan](../plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/plan.md))
  - Trait ฝั่งรับเฉพาะทาง (เช่น `Iron Wall Block D1`, `Bulldozer Impact D2`, `Clean Sweeper D3`, `Shadow Chaser D5`, `Cage Guardian D7`, `Elastic Recovery #19`, `Lightning Poke #18`) ขยายขีดความสามารถการเล่นเกิน Base Cap 1.15 ได้ตามเงื่อนไขของแต่ละ Trait

## 4. ชุดท่าเป้าหมายและตัวเริ่มต้น (Target 7 Unique Skill Moves across 3 Slots)

| ดาวสกิล | Skill Move (เป้าหมาย 7 ท่าไม่ซ้ำ) | บทบาท / การเคลื่อนไหว | สถานะแอนิเมชัน |
| --- | --- | --- | --- |
| 1★ | **Heavy Knock-On** | แตะกระชากยาวไปข้างหน้าเพื่อวิ่งตามความเร็วสูง | อยู่ระหว่างปรับแก้ (HANDOFF §Q) รอตรวจรับ |
| 1★ | **Open Up Fake Shot** | หลอกยิงเปิดมุมลำตัวเปลี่ยนทางบอล | อยู่ระหว่างปรับแก้ (HANDOFF §Q) รอตรวจรับ |
| 2★ | **Body Feint** | ทิ้งน้ำหนักหลอกโยกตัวแล้วแตะออกด้านข้าง | อยู่ระหว่างปรับแก้ (HANDOFF §Q) รอตรวจรับ |
| 3★ | **Heel Chop** | ตอกส้นหักมุม 90 องศาตัดเข้าใน | อยู่ระหว่างปรับแก้ (HANDOFF §Q) รอตรวจรับ |
| 4★ | **Sombrero Flick** | งัดบอลลอยข้ามศีรษะแนวรับ | อยู่ระหว่างปรับแก้ (HANDOFF §Q) รอตรวจรับ |
| 4★ | **Lane Change** | ก้าวแตะสลับเท้าหลบด้านข้าง (Double Touch) | ชุดท่าเป้าหมายใหม่ (HANDOFF §Q) |
| 5★ | **Elastico** | หลอกแตะออกนอกแล้วตวัดกลับเข้าในอย่างรวดเร็ว | ชุดตรวจเดิม รักษารูปแบบคลิป |

- **การติดตั้งและข้อกำหนด:** ตัวเริ่มต้นมีเพดาน Skill Move 5 ดาว ติดตั้งได้ 3 ช่อง เลือกข้ามระดับดาวได้ภายในเพดานตัวละคร; เปลี่ยนก่อนเริ่มรอบหรือหยุด/รีเซ็ตซ้อม
- **สถานะแอนิเมชันและการตรวจรับ:** 5 แอนิเมชันเดิมที่ถูกปฏิเสธ (Heavy Knock-On, Open Up Fake Shot, Body Feint, Heel Chop, Sombrero Flick) อยู่ในกระบวนการปรับแก้ตาม HANDOFF §Q โดยการตรวจรับด้าน visual และ runtime ยังคง PENDING รอ Owner ตรวจรับ
- **ท่าประวัติศาสตร์ที่ปลดระวาง (Historical / Retired Skills):**
  - `Drag Back & Turn (2★)`: ถอนออกจาก active target loadout (ทดแทนด้วย Body Feint 2★)
  - `La Croqueta (3★)`: ถอนออกจาก active target loadout (ทดแทนด้วย Heel Chop 3★)
  - ข้อมูลและคลิปเดิมคงไว้เป็นบันทึกประวัติศาสตร์ ไม่ลบทำลายหลักฐาน

## 5. Stamina, cooldown และ recovery

- ในโหมดปกติ Sprint/Dash/Skill Move/ท่าเข้าสกัดที่มีต้นทุนต้องมีStaminaพอจ่าย; จ่ายไม่พอใช้ท่านั้นไม่ได้ ยังเดิน ยิง ส่ง และยืนตัดบอลได้
- ตอนล้าแตะบอลห่างขึ้นตาม config ไม่สุ่มสั่งให้เสียบอล; ค่าcost/regen/ระยะ/ความเร็ว/เวลาต้องจูนจากการทดลอง
- คูลดาวน์แยกต่อสกิล แต่ต้องผ่านช่วงจบท่าร่วมก่อนใช้ท่าถัดไป ไม่มีการกดข้ามท่าเพื่อหนีการสกัด
- สกิล/เข้าสกัดพลาดมีrecovery: ช้าลงและใช้Skill Move/Dash/เข้าสกัดซ้ำไม่ได้ แต่เล็ง/ยิง/ส่งได้เมื่ออยู่ในท่าที่เล่นบอลได้ สไลด์รอลุกก่อน
- recoveryของการยิง/ส่งจังหวะแรกวืดพร้อมแอนิเมชันอยู่Phase2 ไม่เอามาใช้เป็นเงื่อนไขผ่านPhase1

- อีเวนต์Overdriveใน07ยกเว้นcost/เงื่อนไขStaminaระหว่างActiveให้ทุกทีม แต่ไม่ยกเว้นcooldown/ช่วงจบท่า/recoveryหรือเพิ่มI-frame

## 6. งานถัดไปและอำนาจ

Phase2: สุ่มตัวละคร/สุ่มสกิล/สุ่มเอฟเฟค, ท่าเพิ่มเติม, ระบบ 13 Outfield Base Stats, 4 Deferred GK Stats, 16 Innate Traits, 5 Character Archetypes ([03-player-gacha-and-stats](../plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/plan.md)), ระบบตั้งค่าจริง/ค่าถาวร, แอนิเมชันยิงส่งจังหวะแรกและเสียจังหวะเมื่อวืด รายละเอียดเรต/ราคา/การเติบโต/ขีดสมดุลรอgrillตามแผนเจ้าของ

เจ้าของ Phase1: [02-player-actions](../plan/phase-01-gameplay-demo/02-player-actions/plan.md), [03 Skill Moves/เกมรับ](../plan/phase-01-gameplay-demo/03-dribble-duel/plan.md), [06 Debug/Dummy](../plan/phase-01-gameplay-demo/06-training-ground/plan.md), [08 UI](../plan/phase-01-gameplay-demo/08-gameplay-ui/plan.md) และ [TDD](../tdd/master-test-cases.md) ไม่ขยายสัญญางาน00; รอบQ22เดิมอนุมัติเฉพาะเอกสาร ส่วนOwnerdirective2026-10-21อนุญาตเฉพาะselectiveportตามHANDOFF02

## 7. Owner visual supersession — 2026-10-21

Ownerไม่รับรองแอนิเมชันfix-002และเลือกShift LockแบบSandbox: เริ่มON สลับL/Alt เมาส์กลางจอ/กล้องเยื้องไหล่/8waystrafe ปล่อยเมาส์เมื่อmenu/focuslost ใช้selectedproceduralposeและค่าของprototype3เป็นฐานadaptR6ก่อนจูน02ตามHANDOFF§7 ไม่ใช้ชื่อclipหรือEdittestcountแทนposeจริง เอฟเฟกต์เต็มที่มีแผนเจ้าของรอตามแผนเดิมได้ ไม่เปิดท่าโยก/Poke/Shoulderหรือfirst-time-misspolishจากคำสั่งนี้
