> **OWNER OVERRIDE 2026-10-25 — CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART**
> ยกเลิกแผน R6 นี้และ task queue เดิม เริ่มแผนใหม่ RF-02/RF-03 บน Custom Blocky R15 ตาม [Owner directive](../release-first/assets/owner-r15-restart.md). เนื้อหาด้านล่างเก็บเป็นประวัติ ไม่ใช่อำนาจ resume/implement ต่อ และไม่ใช่ผล APPROVED/PASS/CLOSED. เก็บโค้ด/แอนิเมชัน/หลักฐานเดิม; รอบนี้แก้เฉพาะเอกสาร ไม่มีสิทธิ์ runtime/Git/publish.

# 03 — Skill Moves 3 ช่อง และเกมรับ

> **Current Active Scope & Routing (DOCS-20261024):**
> - **Active Target Catalog:** 7 ท่าไม่ซ้ำ (1★ Heavy Knock-On, 1★ Open Up Fake Shot, 2★ Body Feint, 3★ Heel Chop, 4★ Sombrero Flick, 4★ Lane Change, 5★ Elastico) ติดตั้งได้ 3 ช่อง
> - **Animation Rework & Verification Gate:** 5 แอนิเมชันเดิมที่ถูกปฏิเสธ (Knock-On, Open Up Fake Shot, Body Feint, Heel Chop, Sombrero Flick) อยู่ระหว่างการปรับแก้ตามสัญญาหลัก [primary HANDOFF §Q](assets/HANDOFF.md) โดย `agycage` (T11); การตรวจรับทางสายตา (visual) และ runtime ยังคง **PENDING** รอ Owner ตรวจรับ
> - **Retired Skills:** `Drag Back & Turn (2★)` และ `La Croqueta (3★)` ปลดระวางจาก active target loadout (คงไว้เป็นบันทึกประวัติศาสตร์ ไม่ลบทำลาย)
> - **Lane & Authority:** `agyplan` รับผิดชอบเฉพาะงานเอกสารสเปกและแผน; `agycage` ดำเนินงานโค้ด/แอนิเมชันในเลนของตน ไม่มีการ takeover หรือปิดงานตนเอง

> **Historical Context & Superseded Notes (Preserved Reference):**
> - *Superseded 9-Skill Queue (2026-10-24):* ข้อเสนอเดิมเคยให้เก็บทุกท่ารวม 9 สกิล; ปัจจุบันแทนที่ด้วย 7 ท่าไม่ซ้ำ (ถอน 2 ท่าเก่า)
> - *Superseded 5-Skill Baseline:* สโคปเริ่มแรกเดิมมี 5 ท่าพื้นฐาน (Knock-On, Drag Back, Croqueta, Sombrero, Elastico)
> - *Historical Playtest (2026-10-23):* บันทึกการทดสอบ Poke/CagePress เดิมใน HANDOFF §B

- **State:** SCOPE_CONFIRMED / IMPLEMENTATION_PENDING; [สถานะงาน](tasks.md)
- Owner Stang; Planner/Reviewer Codex; Implementerยังไม่มอบหมาย
- Q22ยืนยันเอกสาร2026-10-20; ไม่มีimplementationapprovalใหม่; localcommitเอกสารตามคำสั่งล่าสุดในagent.md
- Planning HEAD f8729cc6e714f10a1cb60253a4f037d7c49f7505 + dirty files; ต้องpreflightใหม่ก่อนHANDOFF
- Prerequisite [02-player-actions](../02-player-actions/plan.md); [Spec02](../../../specs/spec-02-duel-and-parry.md) / [Architecture](../../../design/architecture-and-network.md#6-continuous-football--q22) / [Phase1](../plan.md)
- พาธ03-dribble-duelเป็นlegacyที่เก็บเพื่อรักษาลิงก์/รายงาน ไม่ได้อนุญาตChoice Duelเดิม

**Ownerdelta2026-10-21:** ดึงSlideจากSandboxก่อนใน02; Poke/Shoulderทำภายหลังในแผนนี้ ยังไม่เปิด03ทั้งแผนและไม่ดึงท่าโยก/5SkillMovesรอบport02

## Scope

- **Target Skill Moves (7 ท่าไม่ซ้ำ ติดตั้ง 3 ช่อง):**
  - 1★ Heavy Knock-On (Forward Burst)
  - 1★ Open Up Fake Shot (Angle Open Fake)
  - 2★ Body Feint (Directional Feint — ทดแทน Drag Back & Turn ที่ปลดระวาง)
  - 3★ Heel Chop (Sharp 90-degree Cut — ทดแทน La Croqueta ที่ปลดระวาง)
  - 4★ Sombrero Flick (Lob over defender)
  - 4★ Lane Change (Side Hop / Double Touch)
  - 5★ Elastico (Snap Direction Change)
  - *สถานะแอนิเมชัน:* 5 แอนิเมชันอยู่ในกระบวนการปรับแก้ตาม HANDOFF §Q รอการตรวจรับ visual จาก Owner
- ตัวเริ่มต้น 1 ตัวเพดาน Skill Move 5 ดาว ติดตั้งได้ 3 ช่องเลือกข้ามดาวภายในเพดาน; ไม่เปลี่ยน Tier/Rig/Default Card ของ 00
- กดช่องสกิล + ทิศทางตอนเริ่มท่า ไม่ใช้ปุ่ม Feint เดิมแยกอีกชุด เก็บ Dash จาก 02
- มี R6 แอนิเมชันท่าร่างอ่านจังหวะและทิศได้ครบตามข้อกำหนด; asset/provenance/authoring และ contact timing ต้องเตรียมและตรวจรับก่อนปิดแผน
- บอลถูกแย่งระหว่างทุกท่าได้ ดาวสูงไม่ชนะอัตโนมัติ ไม่มีI-frame/กันคนอื่นแทรก
- เกมรับตามcontextทีมจาก02: reuseSlideที่02portแล้ว (ไกล/พลาดรอลุก, ขยายระยะสไลด์ตาม Sliding, บอลนำหน้า +0.8 studs ด้วย Clean Sweeper D3); ส่งมอบ Quick Poke สั้นออกไว (ระยะตาม Poke Reach, ไวขึ้น 20% ด้วย Lightning Poke #18) และ Body Check / การพุ่งชน (ปะทะด้านหน้าเปรียบเทียบ Strength ต่าง (สูตรคำนวณละเอียด PENDING รอการจูน), บอลหลุดเป็น Loose Ball แย่งจังหวะสอง, ไม่มี auto-possession, ไม่มี I-frame, วืดติด recovery โดยลด 25% ด้วย Elastic Recovery #19, ลูกพุ่งตามทิศหันหน้าและชะงัก +0.15s ด้วย Bulldozer Impact D2) ภายหลังใน03 แทน Shoulder Charge เดิม ไม่ทำSlideซ้ำ
- ผังปุ่มรับเป้าหมาย: LMB Slide Tackle, E Quick Poke, RMB Body Check / Dash Tackle (ปลดระวาง MMB); หมายเหตุ AS-IS ในโค้ดปัจจุบันยังเป็น RMB Poke / MMB CagePress (เอกสารนี้อัปเดต Target เท่านั้น ไม่แก้โค้ด)
- โดนบอลพื้นรับไหวจึงเข้าครอง ลูกแรง/สูงเด้งอิสระ; ชนตัวคู่แข่งธรรมดาช้าลง เพื่อนผ่านกันได้ บอลยังเล่นตามcontact
- คูลดาวน์แยกท่า + ช่วงจบท่าร่วม จ่ายStaminaก่อนออกท่า (ลด 25% ใน Defensive Third ด้วย Cage Guardian D7); พลาดติดrecoveryช้าลงและล็อกSkill/Dash/เข้าสกัดซ้ำ ยังยิงส่งเมื่อท่าเอื้อ โดย commonEndLag และ missed skill recovery ลดลง 20% ด้วย Quick Footwork #17 (ไม่ลดสกิล cooldown)
- เปลี่ยนloadoutก่อนรอบหรือหยุด/รีเซ็ตซ้อมเท่านั้น ไม่เปลี่ยนกลางเล่นเพื่อหนีCD ไม่มีinventory/gacha/persistenceในPhase1

## Architecture / ownership

- ใช้BallService/Movement-Stamina seamของ02เป็นsingle ownerของบอลและค่าความเคลื่อนที่; 03กำหนดaction lifecycle/cost/CD/hit window/animationและขอให้02ประมวลผล contact/possession
- Servervalidateslot/ดาว/ทิศ/ผู้ครอง/ระยะ/สถานะ/recovery/cost/cooldown/generationก่อนapply; clientไม่ส่งผลชนะหรือบังคับตัวเป้าหมายให้แพ้เอง
- UI08แสดง3ช่อง/ดาว/CD/Stamina/ช่วงล็อกและcontextจริง; fixture02/03ใช้ทดสอบขั้นต่ำได้ก่อน08
- แผน05ใช้contactของSlide/Body Checkเพื่อออกแบบฟาวล์ภายหลัง ไม่ย้ายระบบ05มาทำใน03
- ขอบเขตNetwork/config/animation moduleและชื่อserviceที่จะรับแทนDuelEngineServiceต้องระบุในimplementationHANDOFF03ก่อนแก้ sourceเก่ายังไม่ใช่targetที่ส่งมอบแล้ว

## Acceptance

- ครบ 7 ท่าเป้าหมาย / ติดตั้ง 3 ช่อง / เพดานดาว / เลือกทิศ / ท่าร่าง R6 ที่อ่านได้ (5 แอนิเมชันผ่านการตรวจรับ visual จาก Owner); high-star ถูกสกัดได้ ไม่มีบอลหาย hitbox หรือ physics หยุดเพราะ animation
- ทดสอบPoke/Slide/Body Checkสำเร็จและพลาด ผลครอง/บอลหลุดเป็นLoose Ballตรงกติกา; ชนเพื่อนกับคู่แข่งแยกกันจริง
- ต้นทุนจ่ายไม่พอไม่ออกท่า CDแยกและcommon end/recoveryห้ามกดลัด; ยังเล่นพื้นฐานตามท่าที่ทำได้
- เปลี่ยนpreset/ชุด/รีเซ็ต/ตาย/ออกเกมไม่ทำให้CDหรือhandlerซ้อน/ค้าง ไม่ทับcharacter generationใหม่
- ไม่มีDuel trigger/Choice Modal/matrix/สโลว์เปิดดวล/คัตซีนล็อกคู่/สตั้นแพ้ดวล/timedParry/ปุ่มFeintเก่าในruntime

## Deferred / ข้อจำกัด

ท่าเพิ่ม/สุ่มสกิลและownership/ดาวตัวละครหลายตัว/13 Outfield Stats/16 Innate Traits/5 Archetypes ไปPhase2 ([03-player-gacha-and-stats](../../phase-02-full-match-and-progression/03-player-gacha-and-stats/plan.md)); first-time miss animation/recoveryไปPhase2แยกจากrecoveryสกิลและสไลด์ที่ต้องมีPhase1 ตัวเลขจูนผ่าน06ก่อนสรุปสมดุล ไม่เปิดimplementationหรือเปลี่ยนสัญญา00จากเอกสารนี้

assets/runsและnotesbaselineเดิมเก็บเป็นประวัติเท่านั้น ฟีเจอร์Choiceที่กล่าวในรายงานเก่าไม่ใช่scopeปัจจุบัน
