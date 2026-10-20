# Product Requirements — Cage Zero

Owner Stang; Planner/Reviewer Codex. **Decision Accepted / Delivery Planned** — ผู้ใช้ยืนยัน Q22 “ตรงตามนี้ ปรับแผนและเอกสารได้ (แนะนำ)” เมื่อ2026-10-20 หลังQ1–Q21 อนุญาตเอกสาร/architecture/spec/TDDเท่านั้น Implementation02/03และแผนอื่นยังPENDING งาน00ยึดสัญญาเดิม

## เป้าหมาย

ฟุตบอลสตรีทกรง3Dแบบต่อเนื่อง เน้นทักษะการเคลื่อนที่ อ่านบอล เลือกจังหวะชิ่ง/ท่าเลี้ยง/เข้าสกัด และเปิดช่องตอบโต้ที่ยุติธรรม Phase1เป็นGameplay Demoพร้อมฉากซ้อม ไม่ต้องมีวงจรแมตช์เต็ม

## ขอบเขต Phase1

| ด้าน | ข้อกำหนด |
| --- | --- |
| Rig/ตัวทดสอบ | Custom R6/หน้าอนิเมะ ไม่ใช่avatarหรือanimation packผู้เล่น; ตัวพื้นฐาน1ตัว Skill Move5ดาว ไม่เปลี่ยน4scale fixturesและDefault Cardของ00 |
| สนาม | Aกล่อง4ผนัง Bปาด4มุม8ผนัง CฐานB+ขอบroof45°; base rebounds5รายการ markerไกด์ไม่auto-aim ไม่มีwinnerก่อนทดลอง |
| การเคลื่อนที่ | เดิน/Sprint/Dash/Stamina/Shift Lock; Directional Jumpล็อกทิศเคลื่อนตัวกลางอากาศ |
| การเล่นบอล | ยิงตรง/ยิงโค้งปุ่มแยก ส่งเรียด/โด่ง เล็ง3D/ชาร์จตามระบบเดิม Header/Volley/Block และยิงส่งจังหวะแรก |
| ปุ่มสลับ | ทีมครองล่าสุดใช้ยิง/ส่ง/ยิงโค้ง ทั้งทีมคงโหมดบุกตอนบอลอิสระ เปลี่ยนฝั่งเมื่ออีกทีมครองสำเร็จ; ฝ่ายรับใช้Slide/Poke/Shoulder |
| บอล/ปะทะ | hitboxจริงตลอด ไม่มีI-frame; บอลพื้นที่รับไหวแย่งเข้าครองได้ ลูกแรง/สูงบล็อกแล้วเด้งอิสระ; ชนคู่แข่งช้าลง เพื่อนผ่านตัวกันได้ |
| เกมรับ | Pokeสั้น/ไว Slideไกลแต่ต้องรอลุกเมื่อพลาด Shoulderด้านข้างทำให้เสียเหลี่ยมและบอลหลุดอิสระ |
| Skill Moves | 1★Heavy Knock-On,2★Drag Back & Turn,3★La Croqueta,4★Sombrero Flick,5★Elastico; ฟรี5ท่าเลือกใส่3ช่อง กดช่อง+ทิศตอนเริ่ม มีR6ท่าร่างอ่านจังหวะได้ |
| ข้อจำกัดท่า | ดาวจำกัดสิทธิ์ใช้ท่า ไม่การันตีผล; Staminaไม่พอใช้ท่าที่มีต้นทุนไม่ได้; คูลดาวน์แยก+ช่วงจบท่าร่วม; เปลี่ยนชุดก่อนรอบ/หยุดหรือรีเซ็ตซ้อม |
| Recovery | พลาดแล้วช้าลงและล็อกSkill/Dash/เข้าสกัดซ้ำ ยังเล่นบอลพื้นฐานเมื่อท่าเอื้อ สไลด์รอลุก; แอนิเมชันและลงโทษยิงส่งจังหวะแรกวืดเลื่อนไปPhase2 |
| ระบบรอบสนาม | โกลคน/AI ฟาวล์และลูกนิ่งFC27 Training/Debugค่าจูน/Dummy อีเวนต์6ชนิด HUD และUAT ตามแผนเจ้าของ |

## ข้อกำหนดที่คงไว้และสิ่งที่ถูกแทน

- Choice Duel/choice matrix/สโลว์เปิดดวล/คัตซีนล็อกคู่/สตั้นแพ้ดวล/ปุ่มFeintเดิมถูกแทนด้วยฟุตบอลต่อเนื่องและSkill3ช่อง; เก็บDash ไม่มีtimedParryหรือSnapShot modalกลับมา
- การยิงโค้งพื้นฐานไม่ใช่Signatureยิงหรือบัฟจากการ์ดที่เคยตัด; ความสามารถยิง/ส่งไม่ถูกล็อกด้วยShooting Zone
- Serverเป็นเจ้าของผลสำคัญและvalidation กล้อง/UIผ่านrouterเดียว ไม่ให้ปุ่มหรือanimationตัดสินผู้ครอง/ผล contactเอง
- No Boots; Mutated Gearไม่มีstatsสนาม คงข้อจำกัดสมดุลการ์ดเดิมจนมีOwnerเปลี่ยน ไม่อนุมานว่าตัวเริ่มต้น5ดาวต้องเป็นTierสูงสุด
- ตัวเลขแรง/ระยะ/ความเร็ว/cost/cooldownเป็นค่าจูนจากtest session ไม่รับรองสมดุลหรือ“ไม่ทะลุ100%”ก่อนมีหลักฐาน

## Phase2 — Deferred

ต้องมีสุ่มตัวละคร + สุ่มสกิล + สุ่มเอฟเฟค, skill inventory/ownershipและท่าเพิ่ม, ความต่างดาว/Statsนักเตะ, แมตช์เต็ม/ธุรกรรม/collection/ตลาด/meta UI, ระบบตั้งค่าฉบับใช้งานจริง/ค่าถาวร และแอนิเมชันพร้อมเสียจังหวะเมื่อยิงส่งจังหวะแรกวืด แต่ละเรื่องเปิดgrill/implementationตามgateหลังPhase1ผ่าน; สูตร/เรต/ราคาและGuaranteed Traitเก่าที่อ้างChoiceต้องทบทวน ไม่ถือว่าอนุมัติให้ย้ายเอฟเฟกต์นั้นเข้าระบบใหม่ทันที

## เอกสารเจ้าของและการส่งมอบ

[Spec02](../specs/spec-02-duel-and-parry.md) เป็นรายละเอียดเกมเพลย์; [architecture](../design/architecture-and-network.md), [TDD](../tdd/master-test-cases.md), [Phase1](../plan/phase-01-gameplay-demo/plan.md), [Phase2](../plan/phase-02-full-match-and-progression/plan.md) และ [accepted decisions](../plan/phase-01-gameplay-demo/01-cage-physics/notes.md) ต้องตรงกันก่อนลงมือ

Training/3v3/4v4คงไว้ ไม่มี1v1v1กลับมา งาน00ยังตามHANDOFFเดิม ไม่มีการอนุมัติsource/Studio/commit/push/merge/deployใหม่จากการยืนยันเอกสารนี้

Ownerเพิ่มevent4หลังQ22: ชนกำแพง/เพดาน/ขอบลาดแล้วเร่งบอลสู่targetSpeedคงที่ไม่สะสม จบeventหยุดboostใหม่แต่คงvelocity ตาม[plan07](../plan/phase-01-gameplay-demo/07-dynamic-field-events/plan.md) เป็นscopeเอกสารที่Acceptedไม่ใช่implementationapproval

Ownerเพิ่มevent5/6: Wall-Dash Overdriveให้ทุกคนStaminaไม่จำกัดโดยไม่ต้องชิ่ง คงCD/recoveryและมีUIhighlightหลอด; Low-Roofใช้temporaryflatceilingใต้ผิวสูง12studsทุกprofileแล้วคืนroofเดิม จบOverdriveเติมStaminaเต็ม100%แล้วใช้ปกติโดยCD/recoveryยังเดินต่อ รายละเอียดอยู่plan07
