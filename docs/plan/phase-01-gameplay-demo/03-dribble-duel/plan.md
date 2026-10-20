# 03 — Skill Moves 3 ช่อง และเกมรับ

- **State:** SCOPE_CONFIRMED / IMPLEMENTATION_PENDING; [สถานะงาน](tasks.md)
- Owner Stang; Planner/Reviewer Codex; Implementerยังไม่มอบหมาย
- Q22ยืนยันเอกสาร2026-10-20; ไม่มีimplementationapprovalใหม่; localcommitเอกสารตามคำสั่งล่าสุดในagent.md
- Planning HEAD f8729cc6e714f10a1cb60253a4f037d7c49f7505 + dirty files; ต้องpreflightใหม่ก่อนHANDOFF
- Prerequisite [02-player-actions](../02-player-actions/plan.md); [Spec02](../../../specs/spec-02-duel-and-parry.md) / [Architecture](../../../design/architecture-and-network.md#6-continuous-football--q22) / [Phase1](../plan.md)
- พาธ03-dribble-duelเป็นlegacyที่เก็บเพื่อรักษาลิงก์/รายงาน ไม่ได้อนุญาตChoice Duelเดิม

## Scope

- Skill Move5ท่า1–5ดาวตามcatalogSpec02: Heavy Knock-On, Drag Back & Turn, La Croqueta, Sombrero Flick, Elastico
- ตัวเริ่มต้น1ตัว Skill Move5ดาว ใช้5ท่าทดลองฟรี เลือกติดตั้ง3ช่องข้ามดาวภายในเพดาน; ไม่เปลี่ยนTier/Rig/Default Cardของ00
- กดช่องสกิล+ทิศทางตอนเริ่มท่า ไม่ใช้ปุ่มFeintเดิมแยกอีกชุด เก็บDashจาก02
- มีR6แอนิเมชันท่าร่างอ่านจังหวะและทิศได้ทั้ง5; asset/provenance/authoringและcontact timingต้องเตรียมก่อนลงมือ03 ไม่อ้างว่าใช้clip00ครบแล้ว
- บอลถูกแย่งระหว่างทุกท่าได้ ดาวสูงไม่ชนะอัตโนมัติ ไม่มีI-frame/กันคนอื่นแทรก
- เกมรับตามcontextทีมจาก02: Quick Pokeสั้นออกไว, Slideไกลแต่พลาดรอลุก, Shoulderด้านข้างทำให้เสียเหลี่ยมและบอลหลุดอิสระ
- โดนบอลพื้นรับไหวจึงเข้าครอง ลูกแรง/สูงเด้งอิสระ; ชนตัวคู่แข่งธรรมดาช้าลง เพื่อนผ่านกันได้ บอลยังเล่นตามcontact
- คูลดาวน์แยกท่า + ช่วงจบท่าร่วม จ่ายStaminaก่อนออกท่า; พลาดติดrecoveryช้าลงและล็อกSkill/Dash/เข้าสกัดซ้ำ ยังยิงส่งเมื่อท่าเอื้อ
- เปลี่ยนloadoutก่อนรอบหรือหยุด/รีเซ็ตซ้อมเท่านั้น ไม่เปลี่ยนกลางเล่นเพื่อหนีCD ไม่มีinventory/gacha/persistenceในPhase1

## Architecture / ownership

- ใช้BallService/Movement-Stamina seamของ02เป็นsingle ownerของบอลและค่าความเคลื่อนที่; 03กำหนดaction lifecycle/cost/CD/hit window/animationและขอให้02ประมวลผล contact/possession
- Servervalidateslot/ดาว/ทิศ/ผู้ครอง/ระยะ/สถานะ/recovery/cost/cooldown/generationก่อนapply; clientไม่ส่งผลชนะหรือบังคับตัวเป้าหมายให้แพ้เอง
- UI08แสดง3ช่อง/ดาว/CD/Stamina/ช่วงล็อกและcontextจริง; fixture02/03ใช้ทดสอบขั้นต่ำได้ก่อน08
- แผน05ใช้contactของSlide/Shoulderเพื่อออกแบบฟาวล์ภายหลัง ไม่ย้ายระบบ05มาทำใน03
- ขอบเขตNetwork/config/animation moduleและชื่อserviceที่จะรับแทนDuelEngineServiceต้องระบุในimplementationHANDOFF03ก่อนแก้ sourceเก่ายังไม่ใช่targetที่ส่งมอบแล้ว

## Acceptance

- ครบ5ท่า/3ช่อง/ดาว/เลือกทิศ/ท่าร่างR6ที่อ่านได้; high-starถูกสกัดได้ ไม่มีบอลหายhitboxหรือphysicsหยุดเพราะanimation
- ทดสอบPoke/Slide/Shoulderสำเร็จและพลาด ผลครอง/บอลหลุดตรงกติกา; ชนเพื่อนกับคู่แข่งแยกกันจริง
- ต้นทุนจ่ายไม่พอไม่ออกท่า CDแยกและcommon end/recoveryห้ามกดลัด; ยังเล่นพื้นฐานตามท่าที่ทำได้
- เปลี่ยนpreset/ชุด/รีเซ็ต/ตาย/ออกเกมไม่ทำให้CDหรือhandlerซ้อน/ค้าง ไม่ทับcharacter generationใหม่
- ไม่มีDuel trigger/Choice Modal/matrix/สโลว์เปิดดวล/คัตซีนล็อกคู่/สตั้นแพ้ดวล/timedParry/ปุ่มFeintเก่าในruntime

## Deferred / ข้อจำกัด

ท่าเพิ่ม/สุ่มสกิลและownership/ดาวตัวละครหลายตัวไปPhase2; first-time miss animation/recoveryไปPhase2แยกจากrecoveryสกิลและสไลด์ที่ต้องมีPhase1 ตัวเลขจูนผ่าน06ก่อนสรุปสมดุล ไม่เปิดimplementationหรือเปลี่ยนสัญญา00จากเอกสารนี้

assets/runsและnotesbaselineเดิมเก็บเป็นประวัติเท่านั้น ฟีเจอร์Choiceที่กล่าวในรายงานเก่าไม่ใช่scopeปัจจุบัน
