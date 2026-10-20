# 00-bootstrap-and-rig — Bootstrap และ Custom R6

- **Phase:** 1; **State:** PAUSED_BY_OWNER — Ownerสั่ง “พักรอบ 00 ก่อน” หลังreview010 ไม่ส่งRound5/ไม่แก้หรือทดสอบต่อจนกว่าจะresume; F18/F19ยังOPEN historicalgaprunแรกACCEPTED_GAPคงเดิม
- **Owner:** Stang; **Planner/Reviewer:** Codex; **Implementer:** AGY Teamwork-preview (session e86ac30e-006d-4338-9a90-5f5e3b002028; correction Round2)
- **Authority:** 2026-10-20 ผู้ใช้เลือก R6 แล้วตอบยืนยัน “ใช้ R6 ตลอด Phase 1 (แนะนำ)” และอนุญาต Codex ปรับแผน/architecture
- **Implementation approval:** AUTHORIZED_FOR_00 — Stang สั่ง “เริ่มเลย” เมื่อ 2026-10-20 อนุมัติให้ AGY แก้ source/target Studio และตรวจตาม HANDOFF นี้ ไม่รวมแผน 01/07/Phase 2 และไม่มีสิทธิ์ commit/push/merge/deploy
- **Reviewed baseline:** main @ `2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`; source ตรง baseline เดิม `6d0f273dc...`
- **Session/log:** ผู้ใช้ส่งผล run-phase00-agy-impl-01 แล้ว; [review-007](assets/review-007.md) บันทึก actual HEAD + working-tree source hashes และข้อแก้ ไม่มี implementation sign-off
- [Tasks](tasks.md) / [Notes](notes.md) / [HANDOFF](assets/HANDOFF.md) / [Architecture](../../../design/architecture-and-network.md#5-phase-1-runtime--custom-r6) / [Phase](../plan.md)

## เป้าหมายและขอบเขต

เตรียมฐานเกมใหม่ที่สร้าง Single Custom R6 ของเกมได้จาก repo มีใบหน้าอนิเมะ อนิเมชันพื้นฐาน การเกิด/เกิดใหม่ และปรับสัดส่วนเดิมได้ ใช้ต่อทุกแผนของ Phase 1 โดยไม่โหลดรูปลักษณ์/animation pack ส่วนตัวของผู้เล่น

- ใช้โค้ดเดิมใน `src/` เป็นฐาน ปรับเฉพาะ bootstrap/network/rig และเพิ่ม client animation module กับ config ที่จำเป็น
- คง presets 0.92/0.98/1.03/1.08 จาก CardConfigs เป็นค่าทดสอบ; ผู้เล่นเริ่ม preset เดิม Ronan_TierB การสลับทดสอบทำจาก server fixture ไม่เพิ่ม UI/กาชา/ownership
- Server สร้าง `ServerStorage.CageZeroStandardR6Rig`, clone ต่อผู้เล่น, ตั้ง PrimaryPart เป็น HumanoidRootPart และ CharacterAutoLoads=false
- Client ใช้ locomotion clips มาตรฐาน R6 ผ่าน Animator ที่สร้างบน Server; ไม่สร้าง procedural locomotion controller ใหม่
- ฐานใหม่ไม่มี rig/source/floor ล่วงหน้าได้ ไม่ใช่ defect; fixture ขั้นต่ำเป็นของแผนนี้ ไม่ใช่สนามกรงแผน 01
- Reference `sandboxcage-zero` place `112091950831355` เป็น read-only; ไม่ sync/disable prototype หรือยก sandbox ทั้งชุดเข้ามา

## ไม่อยู่ในแผนนี้

บอล/เลี้ยง/Dash/Feint/Slide/ยิงส่ง/โกล/ดวล/คัตซีนเฉพาะเกม/สนามกรง/UI/economy/กาชา/ตลาด/Phase 2 ไม่มีการย้ายเป็น R15 ภายหลังโดยอัตโนมัติ และไม่แก้ public Network getters หรือ consumers ของแผนอื่น

## สัญญา runtime ที่ใช้ต่อ

| เจ้าของ | ข้อตกลง |
| --- | --- |
| Server bootstrap | Network.Init → RigAndCardService.Init เท่านั้น ไม่ require MatchService หรือ services อื่น |
| Client bootstrap | Network.Init → R6AnimationController.Init เท่านั้น ไม่โหลด UI/InputController เก่า |
| Network | เพิ่ม Init(timeoutSec?) ด้วย deadline รวม 10s ที่รวม bootstrap waits; คง 12 Definitions และ getters/validators เดิม |
| Rig | R6 มี 6 visible body parts + HumanoidRootPart, 6 Motor6Ds, Humanoid.RigType=R6, Animator และ Head.AnimeFaceDecal; root ไม่ Anchored |
| API | คง SpawnCustomRigForPlayer/EquipCardForPlayer/GetEquippedCardId/GetEquippedCardConfig; เปลี่ยน constructor ที่ผูก R15 เป็น BuildStandardCustomRig และอัปเดตผู้เรียกภายในไฟล์เดียว |
| Root | Character.PrimaryPart=HumanoidRootPart; แผนถัดไปอ้าง root/geometry ไม่สมมติ RightFoot/UpperTorso หรือ knee joints |
| Scale | ใช้ BaseSize/BaseC0/BaseC1 คงที่; body/head scale แยกกัน ไม่มีการคูณสะสม; R6 HipHeight ใช้ relative offset ไม่คัดสูตร R15 |
| Spawn | ใช้ primary floor path/anchor ที่ระบุชัดใน config; valid-or-error หลัง filtered raycast กับ floor นั้นและตรวจ footprint |
| Respawn | died connection ต่อ character และ generation/token ยกเลิก timer ของ character เก่า; ล้างเมื่อตาย/ออกเกม |
| Animation | `R6AnimationController` จัด tracks/cleanup ต่อ local character; clips/config/source เก็บใน repo; โหลดเมื่อ Animator อยู่ Workspace แล้ว |

## พื้นและจุดเกิด

- preflight เลือก Baseplate ที่ผ่านเกณฑ์ หรือสร้าง BootstrapTestFloor/BootstrapSpawnLocation ในฐานใหม่; บันทึก path ที่เลือกใน Constants ไม่กวาดทุก anchored collider
- fixture เสนอขนาด 160×2×240 ที่ center (0,-1,0); ไม่สร้างกรง/ประตู/bumper/ramp ในแผน 00
- ระยะขอบคำนวณจาก R6 collision footprint; จุดผู้เล่นเดิมที่ยังมีชีวิต → spawn anchor → floor center; ไม่ผ่านทุกจุดให้ error พร้อมเหตุผล
- root height สำหรับ R6 อ้าง `Left Leg.Size.Y + RootPart.Size.Y/2 + HipHeight` และ clearance; ไม่ใช้ `2.0 * heightScale` แบบ R15
- แผน 01 จะสลับ primary floor ไป `Workspace.HexCageArena.CageFloor` หลังสร้างสนาม ก่อนเรียก rig Init; แผน 00 ไม่เริ่ม CagePhysicsService เอง

## งานและลำดับลงมือภายหลัง approval

1. preflight Git/target Studio ที่เป็นฐานใหม่ เก็บ before state; ไม่ใช้ชื่อ/Studio ID เก่าเป็นสิทธิ์เขียน
2. แก้ bootstrap/Network.Init โดยไม่เปลี่ยน public getters หรือ endpoint semantics
3. สร้าง R6 definition/builder/scale/spawn/respawn จาก source; คง API ที่มี consumers
4. เตรียม R6 clip config และ client controller; ตรวจ provenance/compatibility ของคลิปกับ R6 ไม่ใช้ R15 IDs เดิม
5. sync source 9 จุดตาม HANDOFF แบบ parent→child พร้อม template/floor fixture และ before/after manifest
6. ตรวจ acceptance; sync docs และส่ง working tree/evidence ให้ Codex ตรวจ ไม่ปิดงานตนเอง

## Acceptance และหลักฐาน

- [TC-00-01] source 9 จุดใน Studio ตรง repo แบบ SHA-256; topology R6 ถูกต้อง ไม่มี avatar ส่วนตัว/รองเท้าสตั๊ด
- [TC-00-02] client ready ภายใน deadline รวม 10s; ไม่เปิด MatchService/Parry/UI/collection; default controls และกล้องพื้นฐานใช้งานได้
- [TC-00-03] scale 4 presets ไป–กลับ 3 รอบ: body/head sizes, joint offsets และ ground clearance ถูกต้อง ไม่คูณสะสม ไม่ใช้เกณฑ์ 16 parts/15 joints ของ R15
- [TC-00-04] idle/เดิน/วิ่งตามความเร็ว/กระโดด/ตก มี pose เปลี่ยนจริงบน client; แยก server state/replication และ visual check ไม่เทียบ raw Transform ข้าม network
- [TC-00-05] ตาย/เกิดซ้ำ 3 รอบ, ตกฉาก, delayed respawn race และออกเกมไม่เกิด timer/connection ซ้ำ; จุดเกิดอยู่เหนือ floor ที่เลือก
- [TC-00-06] pre/post snapshot ครบ files/instances/descendants; rollback preflight ทั้งชุดก่อน restore; ถ้ามีงานแทรกให้หยุด
- visual/asset/multi-client observer ที่ไม่มีหลักฐานต้องคง NOT VERIFIED ไม่อ้างว่าผ่านจาก build หรือรายงาน R15 เดิม

## สถานะพร้อมแผนถัดไป

architecture และ scope R6 ตกลงแล้ว ไม่มีคำถามผลิตภัณฑ์ค้างสำหรับ 00; การยืนยันไฟล์ฐานใหม่และ clip loading เป็น preflight/runtime gate ของ implementation ไม่ใช่เหตุให้วน grill ใหม่ แผน 01 เริ่มทำรายละเอียดเอกสารจากสัญญานี้ได้ แต่ implementation ของ 01 ต้องรอ 00 ผ่าน gate จริง
