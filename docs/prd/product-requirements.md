# Product Requirements — Cage Zero

Owner Stang; Planner/Reviewer Codex. **Owner Override 2026-10-25 (Release-First Target):** คำสั่ง Owner ยกเลิก legacy 02/03 (`CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART`) และเริ่มต้น [Release-First Track](../plan/phase-01-gameplay-demo/release-first/plan.md) บน **Player Avatar R15 (Normalized to Same Body Dimensions)** (แทนที่ Custom Blocky R15 เดิม; รักษาอัตลักษณ์ผู้เล่นแต่บังคับขนาดร่างกายเท่ากันทั้งหมด; ขนาดไม่เปลี่ยนตาม Stats/Cards) มุ่งสู่ Public Alpha พร้อม Cage Slingshot, 3 Active Skills, 3 ตัวละคร, 13 Outfield Stats, 3-4 Active Traits, Cash Gacha และ Casual 2v2 โดยคงประวัติศาสตร์เดิมไว้ครบถ้วน

## เป้าหมาย

ฟุตบอลสตรีทกรง 3D แบบต่อเนื่อง เน้นทักษะการเคลื่อนที่ อ่านบอล เลือกจังหวะชิ่ง/ท่าเลี้ยง/เข้าสกัด และเปิดช่องตอบโต้ที่ยุติธรรม Phase 1 Release-First มุ่งสู่ Public Alpha พร้อมแมตช์ Casual 2v2 และระบบเศรษฐกิจขั้นต่ำที่ปลอดภัย

## ขอบเขต Phase 1 Release-First (Active Target)

| ด้าน | ข้อกำหนด |
| --- | --- |
| Rig / ตัวละคร | **Player Avatar R15 (Normalized to Same Body Dimensions)** (ผู้เล่นใช้ Avatar ของตนเองแต่ถูก Normalized ขนาดร่างกายและมิติ Collision/Contact geometry ให้เท่ากันทั้งหมด; Scale numbers เท่ากันไม่รับประกันขนาดจริงของ arbitrary body packages จึงต้องมีระบบ Normalization; ขนาดร่างกายไม่เปลี่ยนตาม Stats/Cards; R6 เดิมเก็บไว้เป็นประวัติศาสตร์อ้างอิง) |
| สนาม & อัตลักษณ์ | **Stadium A (4 ผนังเรียบ + เพดาน)** พร้อมอัตลักษณ์ **Cage Slingshot**: Full Wall Run ไต่กำแพง และ Wall Launch ดีดตัวความเร็วสูงกลางอากาศเพื่อยิง/บล็อก |
| การเคลื่อนที่ | เดิน/Sprint/Dash/Stamina/Shift Lock; Directional Jump ล็อกทิศทางกลางอากาศพร้อม Air Lean และ Apex Hang-feel |
| การเล่นบอล | ส่งบอล Manual 3D ตามแรงชาร์จ, ปุ่มขอบอล (Request-Ball) ส่งเฉพาะสัญญาณ Marker **ไม่ auto-pass**, ยิงตรงและยิงโค้งแยกปุ่มชัดเจน, Header/Volley กลางอากาศ |
| การปะทะ/บอล | ลูกบอลฟิสิกส์จริง ไม่มี teleport เข้าเท้า และไม่มี auto-catch (ยกเว้นข้อยกเว้นการรับบอลกลางอากาศที่สัมผัสบอลจริงและผ่านเกณฑ์ความเร็วสัมพัทธ์ตาม Owner Decision; ห้ามการวาร์ปบอลจากระยะไกล); บอลมี Hitbox ตลอดเวลา ไม่มี I-frame |
| เกมรับ | Slide Tackle (LMB) พุ่งสกัดต่ำ (พลาดมี Recovery รอลุก) และ Quick Poke (E) สะกิดบอลระยะประชิด; Forward Body Check (RMB ตามมติ Owner Q6; MMB ปลดระวาง) สถานะ Launch Inclusion vs Deferral เป็น **PENDING Owner Decision** (Semantics: พุ่งปะทะด้านหน้า, Strength check, Loose Ball, No Auto-Possession, No I-frame, Recovery Delay) |
| Skill Moves | **3 Launch Skills บน R15**: Heavy Knock-On (1★), Open Up Fake Shot (1★), Body Feint (2★) ติดตั้งได้ 3 ช่อง มี Stamina cost และ Recovery window; อีก 4 ท่า (Heel Chop, Sombrero Flick, Lane Change, Elastico) เก็บเป็น catalog สำหรับ Phase 2 |
| ตัวละคร & สถิติ | ตัวละครต้นแบบ 3 ตัว (ไม่มีอาชีพบังคับ), 13 Outfield Base Stats (PAC, SHO, PAS, DRI, DEF, PHY และย่อย ขอบเขต 0.90–1.15), และ 3–4 Active Traits (จาก Framework 16 รายการ) |
| เศรษฐกิจ & Progression | **Earned Cash Gacha** (สุ่มตัวละครด้วยเงินในเกมเท่านั้น ห้ามใช้ Robux สุ่ม), ร้านค้า Cosmetic 1 รายการ, และบันทึก PlayerProfile แบบ Server Authoritative |
| แมตช์ & HUD | แมตช์ **Casual 2v2** จบครบวงจร (Kickoff, Goals, Timer 3 นาที, End match), Concise HUD (Stamina, Skill 3 ช่อง, Scoreboard, Timer, Request-ball marker) |
| Publish Gate | สินค้า Robux ผลลัพธ์แน่นอน 1 รายการ (Optional), ProcessReceipt แบบ Idempotent, Multiplayer UAT 4 คน, Owner เป็นผู้กด Publish |

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

Training/3v3/4v4คงไว้ ไม่มี1v1v1กลับมา งาน00ยังตามHANDOFFเดิม รอบQ22เดิมยืนยันเอกสารเท่านั้น; Ownerdelta2026-10-21อนุญาตAGYแก้source/targetStudioเฉพาะHANDOFF02 ไม่ให้commit/push/merge/deployหรือปิดแผน

Ownerเพิ่มevent4หลังQ22: ชนกำแพง/เพดาน/ขอบลาดแล้วเร่งบอลสู่targetSpeedคงที่ไม่สะสม จบeventหยุดboostใหม่แต่คงvelocity ตาม[plan07](../plan/phase-01-gameplay-demo/07-dynamic-field-events/plan.md) เป็นscopeเอกสารที่Acceptedไม่ใช่implementationapproval

Ownerเพิ่มevent5/6: Wall-Dash Overdriveให้ทุกคนStaminaไม่จำกัดโดยไม่ต้องชิ่ง คงCD/recoveryและมีUIhighlightหลอด; Low-Roofใช้temporaryflatceilingใต้ผิวสูง12studsทุกprofileแล้วคืนroofเดิม จบOverdriveเติมStaminaเต็ม100%แล้วใช้ปกติโดยCD/recoveryยังเดินต่อ รายละเอียดอยู่plan07

Owner delta2026-10-21: selective reuse sprint/dash/kick/Pass/curve+segmentedchargeUIและSlide ต่อจากAGYfix-001 เว้นFeint/Cut/SkillMoves ย้ายเกจขั้นต่ำมา02ก่อนfullUI08 ไม่ยกSandboxทั้งระบบ อำนาจลงมือจำกัดตามHANDOFF02 ไม่ใช่ผลตรวจผ่านหรือสิทธิ์commit/push/merge/deploy

Ownervisualdelta2026-10-21หลังfix-002: animationยังไม่ผ่าน ให้02reuseselectedSandboxproceduralposesและsettingsพร้อมShift LockแบบSandbox แล้วค่อยจูน ไม่ใช่เพิ่มrigR15/ท่าโยก/Skillslotsหรือใช้jumpclipแทนSlide เอฟเฟกต์เต็มที่อยู่07/08/Phase2คงรอแผนเจ้าของได้ แบบและallowlistอยู่HANDOFF02§7
