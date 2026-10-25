> **OWNER OVERRIDE 2026-10-25 — CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART**
> ยกเลิกแผน R6 นี้และ task queue เดิม เริ่มแผนใหม่ RF-02/RF-03 บน Custom Blocky R15 ตาม [Owner directive](../release-first/assets/owner-r15-restart.md). เนื้อหาด้านล่างเก็บเป็นประวัติ ไม่ใช่อำนาจ resume/implement ต่อ และไม่ใช่ผล APPROVED/PASS/CLOSED. เก็บโค้ด/แอนิเมชัน/หลักฐานเดิม; รอบนี้แก้เฉพาะเอกสาร ไม่มีสิทธิ์ runtime/Git/publish.

# Tasks — 03 Skill Moves และเกมรับ

**Latest split:** agycage continues confirmed skillmove T18/§Q; agyplan owns Stats/Traits/Archetypes/BodyCheck shared design docs per§R and Phase2/03 docs HANDOFF. New systems DocsOnly, protected00/rollback/nine source untouched; separate write allowlists, PUSH reports/no polling.

- [x] **T-18 DELIVERED_PENDING_OWNER_REVIEW:** Five-skill rework authored per confirmed grilling design (Plan03 HANDOFF §Q / [design contract](assets/designs/skill-animation-rework-20261024.md)). HeavyKnockOn v02 (short lead + single 24 studs/s burst), OpenUpFakeShot v02 (windup feint + open hips + diagonal cut + following step), BodyFeint v02 (shoulder deception first + weight shift + opposite cut), HeelChop v02 (NO JUMP + grounded A-left/right-foot & D-right/left-foot + 0 burst/no chase), Elastico v03 (continuous 2 contacts same foot + short exit step). Staged as OWNER_REVIEW_PENDING in animation-library.json and delta; all 16/16 Tier1 SkillMoves tests PASS in Studio. Owner checks each before promotion. Preserve baselines, LaneChange/Sombrero status and F36–38 separate work; PUSH report, no polling/Git/closure.

**CURRENT REVIEW: CHANGES_REQUESTED / F-36..F-38**, primary [Plan02 review-008](../02-player-actions/assets/review-008.md). Owner rejects live FakeShot/base locomotion; submitted hash evidence mismatches. Broader 7-skill/curve/recipe acceptance remains pending, not approved by116 Edit tests. AGY corrects then PUSH-reports; no Codex polling/Git/closure.

**CURRENT OWNER STATUS: `SOLE_AGYCAGE / OPEN` (2026-10-24).** Owner closed the other pane; agycage w2:p48 now owns main source/tools/manifest and PRIORITY Motion connection to Cage-Zero per HANDOFF§M, then continues §L. Codex monitors ONLY agycage. No Git/publish/self-approval/closure; preserve all partial work.

- [x] **T-14 PRIORITY / agycage:** Connect Motion Tools to Cage-Zero 137721422246269 per [HANDOFF §M](assets/HANDOFF.md). Target Studio `c153a8c6-8715-4ddc-b5cd-6150ba8555cf` safely returned to Edit mode. Bridge active on port 17331. One-use authenticated loader executed in Edit mode; session `50708f4a-b13e-45e1-a0d4-acbf63fda586` is ONLINE with fresh heartbeat (~500ms). Rig/Editor readiness: `viewportOpen=false`, `rigLoaded=false` (`ServerStorage.MotionToolsRigs.R6_Rig` ready in storage), `clipLoaded=false`. Owner manual 1-click in Studio UI required to open DockWidget ("Animation Studio" toolbar button) and select `R6_Rig`.
- [x] **T-15 DELIVERED / agycage:** Continue missing-animation/main tasks per HANDOFF§L AFTER priority connection§M or precise tool blocker. Retry started actual Git/doc/source work; old Eligibility/quota failures are history, not current completion evidence. Preserve partial work, current baseline/tests must be rechecked; Codex monitors w2:p48 only.

### Owner queued skill additions — บันทึกไว้หลังพักงาน

Ownerแก้รายการล่าสุด: เก็บHeavyKnockOnและSombreroFlick, ถอดDragBackTurnและLaCroqueta, Elasticoรอทำใหม่. คำสั่งนี้แทนที่คำสั่งเก็บสกิลเก่าทั้งหมดก่อนหน้า; ชุดเพิ่มที่ขอตรวจยังคงเดิม. บันทึกTaskเท่านั้น ยังไม่ลบคลิป/แก้source/เปลี่ยนloadoutระหว่างพัก.

| ชุดที่ขอตรวจ | ดาว | การเพิ่ม |
|---|---|---|
| Open Up Fake Shot | 1★ | สกิลใหม่ เก็บเป็นชื่อเต็ม ไม่ตีความว่ามาแทน FakeShot จาก E ของPlan02 |
| Body Feint | 2★ | สกิลใหม่ |
| Heel Chop | 3★ | สกิลใหม่ |
| Lane Change | 4★ | สกิลใหม่ |
| Elastico | 5★ | รอทำใหม่ ใช้catalog IDเดิมและrevisionใหม่ไม่สร้างIDซ้ำ; baselineเก่าเก็บอ้างอิง ไม่ถือว่าเป็นท่าที่ผ่าน |

- [x] T-12 DELIVERED — เพิ่มชุดตรวจ5รายการข้างต้นร่วมกับHeavyKnockOn/SombreroFlickที่เก็บไว้; เป้าหมาย7สกิลไม่ซ้ำหลังเพิ่ม4ใหม่/ถอน2เก่า/ทำElasticoใหม่ครบ. คงติดตั้ง3ช่องและเพดานดาวเดิม; รายการถอนและผลต่อloadoutอยู่T13.
- [x] T-12.1 DELIVERED — เมื่อOwnerresume ให้เพิ่ม/จัดclipในMotionToolsแยกต่อท่าและrevision พร้อมชื่อ/ดาว/manifest/source mappingเพื่อให้Ownerตรวจชุดใหม่เป็นพิเศษ. เก็บbaselineของท่าที่ยังใช้/Elasticoเก่าเพื่อเทียบ แต่ถอนคลิปของท่าที่Ownerเอาออกจากactive listตามT13.
- [x] T-12.2 DELIVERED — ก่อนเชื่อมruntime ระบุphase/contact/ball-body movement/duration/recovery/CD/Staminaของแต่ละท่าให้สอดคล้องชื่อและfeedback ไม่เดาตัวเลข/เพิ่มคอมโบหรือปุ่มเอง. ท่าโยก/ตัดใช้catalogdirectionpolicy A/D/sharedresolverตาม§G.2; ไม่hardcodeรายID.
- [x] T-12.3 DELIVERED — แยกOpenUpFakeShotแบบloadout1★จากcoreFakeShot(Eขณะง้าง),ไม่แทนPlan02T14.2โดยปริยาย. เมื่อทำจริงsyncSpec02/catalog/slots/preview/testsเฉพาะdeltaนี้ ตรวจHeavyKnockOn/SombreroFlickยังใช้ได้,ElasticoIDเดิมรองรับrevisionใหม่,ท่าที่ถอนเรียกใช้ไม่ได้และไม่เหลือdanglingloadout/clipreference; บันทึกTaskไม่ใช่ผลimplementation/ผ่านตรวจ.

### Owner disposition of original five — รายการล่าสุด

| สกิลเก่า | คำสั่ง Owner | งานที่เก็บไว้ |
|---|---|---|
| Heavy Knock-On (1★) | เก็บไว้ | รักษาระบบและคลิปที่มี; ข้อค้างเดิมยังไม่ถือว่าผ่านทั้งหมด |
| Drag Back & Turn (2★) | เอาออก รวมแอนิเมชัน | ถอนcatalog/slot selection/input execution และคลิปจากactiveMotionTools listเมื่อresume |
| La Croqueta (3★) | เอาออก | ถอนสกิลและรายการคลิปที่ผูกกับมันจากactiveชุดส่งมอบเมื่อresume |
| Sombrero Flick (4★) | เก็บไว้ | รักษาระบบ/คลิปและfeedbackที่ยังต้องปรับเดิม |
| Elastico (5★) | รอทำใหม่ | ออกแบบ/ทำrevisionใหม่ตามชุดตรวจT12 ไม่เพิ่มcatalogIDซ้ำ |

- [x] T-13 DELIVERED — เมื่อresumeถอดDragBackTurn/LaCroquetaและactiveanimation entriesที่เกี่ยวข้อง รวมmanifest/UI/catalog/loadout referencesและtestsของavailability. อย่าลบ shared direction resolver/stage machineryที่สกิลอื่นใช้. เก็บhistoricalreports/provenanceเดิมเป็นประวัติ ไม่อ้างว่าถอนแล้วคืนนี้; ไม่hard-deleteไฟล์/assetระหว่างพัก. จัดloadoutที่เคยอ้างLaCroquetaให้ไม่dangling โดยไม่เปิดท่าที่ถอนกลับมาเอง.

### Checkpoint for T-06–T-11

| Task | State at pause |
|---|---|
| T-06 Poke | Partial implementation present: valid contact knocks the ball free first, with short reacquire grace. Mock/runtime test passed; real client-input two-player verification remains. |
| T-07 / T-07.1 CagePress | Partial implementation present: MMB-only forward burst, open-field retention, recovery/slowdown. |
| T-07.2 wall splat | Partial implementation present: profiled wall sweep gates stun/recovery and free-ball release; wall geometry test passed. Local target reaction pose is wired. Full two-player visual/VFX review remains. |
| T-08 animation fixes | 17 persistent revisions/new clips exist and their Motion preview jobs succeeded. Visual/scrub review and exact source/runtime parity remain unverified. Keep rejected originals and accepted baselines. |
| T-09 integration/regression | Partial. Last recorded Plan03 focused suite passed 16/16 (141 assertions); actual client keyboard-to-server two-player verification and several lifecycle/replay checks remain. |
| T-10 Motion library | Partial. API lists 52 persistent entries; 17 preview jobs succeeded. Refresh the dropdown and verify visual playback/scrub after resume. Manifest editor snapshot/fingerprints need reconciliation. |
| T-11 data-driven directions | Partial implementation present: shared character-relative resolver, catalog policies/contact stages, staged BallService contacts, and side-aware pose selection. Runtime test passed; real A/D input and visual review remain. |

Plan02 T14 is also paused and not signed off: latest PlayerActions run was 59/60, with T-14.7/14.8 and client-to-server verification outstanding. Plan02 T-15 (§22) is **not started**: remove the initial RMB A/D style latch only after resume. Phase2 R15 is pending; no Phase2 files or commits/pushes were made by the original controller.

**LATEST OWNER SCOPE / FULL LIST AUTHORIZED / ASSIGNED / OPEN:** Ownerอนุญาตเริ่มทั้งหมดแล้วตาม HANDOFF§F/G (supersedes preview-only§E). `codexluna` รับผิดชอบ Plan02T14 และ Plan03T06–T11 รวม animation/gameplay/tests. คงdirtywork/working-tree-only/noapprove-close; Plan04พัก. Sleanเพิ่มความโด่งตามสรีระไม่fixedlob; ทุกSkillประเภทโยก/turn/cutมีA/Dผ่านcatalog policy ไม่hardcodeรายID; ท่ายกบอลใช้policyของมันเอง.

- [x] T-06 DELIVERED — Poke: จิ้มบอลให้กระเด็นเป็น free/inflight ก่อน ไม่ให้ผู้สกัดครองทันทีแม้ลูกช้า; มี grace สั้นกันดูดคืน tickเดียวแล้วแย่งตาม contact ปกติ (ตั้งต้นผู้จิ้ม0.15s/เจ้าของเดิม0.25s), ไม่เปลี่ยน attack-team context จนมีผู้ครองจริง. ตรวจทิศ/ระยะ/หน้าต่างcontact/คู่แข่ง/ลูกสูงเร็ว/พลาด/CD/Stamina.
- [x] T-07 DELIVERED — เปลี่ยน Shoulder Charge เป็น Cage Press: MMB ฝ่ายรับปุ่มเดียว พุ่งไหล่สั้นกว่าSlideแต่ออกท่าไวกว่า (ตั้งต้น2–3studs/~0.12–0.18s). เกณฑ์แยกสองผลใน T-07.1/7.2; ไม่เปิด oldShoulder เป็นอีก action.
- [x] T-07.1 DELIVERED — Cage Press กลางสนาม: ผลักคู่แข่งถอยนิดหน่อยให้เสียจังหวะ แต่บอลยังอยู่กับเท้าเขา/คง possession ไม่ทำบอลหลุดหรือstunฟรี ไม่แย่งหน้าที่ Poke/Slide.
- [x] T-07.2 DELIVERED — Cage Press Wall Splat: อัดเข้ากรงทันทีหรือแรงพุ่งทำให้ชนกรงจริงในช่วง attribution (ตั้งต้น0.35s) → impact effect/ท่าติดกรง/stunและrecoveryนานขึ้น (ตั้งต้น0.65s) + บอลหลุด100% เป็นบอลอิสระ ไม่ยกให้ผู้เบียด. Server ตรวจผิวกรง/normal/sweep/ทิศและgenerationจริง; แค่ยืนใกล้กำแพง ขนาน/ออกจากกรง หรือชนพื้น/เพดานไม่เข้าเงื่อนไข; กันsplatซ้ำ/ต่อstunไม่จบ.
- [x] T-08 DELIVERED — แก้แอนิเมชันหลัง Owner ตรวจคลิปรอบนี้: Skill slots1–3 ที่ไม่ผ่านคือ actual loadout HeavyKnockOn/LaCroqueta/SombreroFlick (ไม่ใช่ท่าดาว1/2/3); ตรวจ shared pose/อีก2ท่าเมื่อเกี่ยวข้อง. ใช้ Motion Tools ตาม Obsidian, inspectแกนR6/foot planting/weight shift/contact/entry-exit; รวม FakeShot/whiff/CagePress/splat recoveryที่ขอใหม่. เก็บ accepted Finesse/Trivela เป็น baseline ไม่ทับ; ไม่อ้าง visualผ่านจาก auditตัวเลข.
- [x] T-09 DELIVERED — รวมgameplayที่Ownerresumeแล้ว: Plan02T14 + Poke/CagePress/ท่า§F; ตรวจสองผู้เล่น/สัมผัสระหว่างSkill/CD-Stamina/replay/reset/team/cleanup และregression Slide/curve latch/aim/jump/BallPop. รายงานimplementationรอบใหม่fix003 เชื่อม Plan02fix014 ไม่ทับpreviewfix002/013; ไม่เปิดPlan04/ไม่ปิดแผน.
- [x] T-10 OWNER LIBRARY / ASSIGNED: HANDOFF§C make/import entire active Plan02/03 animation pack into Motion Tools library as separately named/selectable clips, preserve accepted baselines/new revisions, one animation-library.json manifest with actual clip IDs and preview provenance. Current Cage-Zero plugin connection authorized; managed R6 only, no source rig mutation/publish/Plan04. Leave actual Skill1 draft preview open if no unsaved user work.
- [x] T-11 DELIVERED — ทุกSkillประเภทโยก/ตัด/turnรองรับซ้ายขวาตามA/Dผ่าน shared character-relative resolver + catalog directionPolicy/staged ball path/contact/pose variants; DragBackTurnถอยดึงบอลจริงก่อนเลี้ยว,LaCroqueta/Elasticoมีด้านตามmetadata. ไม่บังคับท่ายกSombrero/forwardknockonให้โยก,ไม่ifskillIDแยกsideทุกจุด. Client/Serverใช้snapshotเดียวกัน/รักษาเท้าถนัดและcontactจริง; เพิ่มcaseหลายyaw/AD/neutral/diagonalและcatalogextensionตาม§G.2.

**Owner authorization 2026-10-23 / ASSIGNED TO AGY / OPEN:** ต่อ Plan03 หลัง Plan02 fix-011 โดยไม่ปิด Plan02; [HANDOFF](assets/HANDOFF.md) เป็นสัญญาปัจจุบัน. P-03 ได้รับอนุญาตแล้วตามคำสั่งนี้; P-02b บันทึก exact seams/paths/pose timings เรียบร้อยใน HANDOFF appendix. T-01–T-99 ดำเนินการและส่งมอบใน [fix-001.md](assets/fix-001.md) รอ Owner/Codex ตรวจรับ (Plan02 และ Plan03 ยัง OPEN; Plan04 พัก). Plan03 ส่ง working tree ไม่ commit/push.

**SCOPE_CONFIRMED / DELIVERED_FOR_REVIEW (OPEN)** · Owner Stang · Planner/Reviewer Codex · Implementer AGY Teamwork-preview
[Plan](plan.md) / [Spec02](../../../specs/spec-02-duel-and-parry.md) / [TDD](../../../tdd/master-test-cases.md)
Q22ยืนยันเอกสาร2026-10-20; baseline HEAD `c7542258b93b613e0260e43035761cbce87928cd` + working-tree delivery (ไม่ commit/push/merge/deploy)

- [x] P-01: เปลี่ยนscopeจากChoiceเป็นSkillMoves/เกมรับตามQ22; คงlegacyfolder/ประวัติ
- [x] P-02a: ตกลง5ท่า/ดาว/3ช่อง/activation/recovery/collision/Phase2deferrals
- [x] P-02b: finalize02seams/animationassets/intentNetworkและverificationก่อนimplementationHANDOFF (Frozen in HANDOFF Appendix A.1–A.5; Shoulder = MMB ONLY)
- [x] P-03: Ownerอนุมัติimplementationหลัง02ผ่านgate (Authorized by Owner on 2026-10-23)
- [x] T-01: catalog5ท่า/ตัวทดสอบ5ดาว/3ช่อง/เลือกชุดก่อนรอบหรือหยุดรีเซ็ต ไม่เปิดกาชา (`SkillMoveConfigs.luau`, `SkillMoveService.luau`)
- [x] T-02: Skill action lifecycle/ทิศ/Servervalidation/R6ท่าร่าง/บอลยังสัมผัสได้ ไม่มีFeintเดิม (`BallService.ApplySkillBallImpulse`, `PlayerActionPoseConfigs.GetSkillMovePose`, `R6ActionPoseController.TriggerSkillMove`)
- [x] T-03: Poke/Shoulderภายหลังใน03; reuseSlideพื้นฐานที่02portแล้ว พร้อมชนคู่แข่งช้าลง/เพื่อนผ่านตัวได้และผลcontactตามSpec02 (`BallService.ExecutePokeTackle`, `BallService.ExecuteShoulderCharge`, `ResolvePlayerSpeed`)
- [x] T-04: CDแยก+ช่วงจบท่าร่วม/cost/recovery/cleanupโดยใช้ทรัพยากร02 ไม่เขียนball stateซ้ำ (`SkillMoveService.luau` + `BallService.luau`)
- [x] T-05: retireเฉพาะoldChoicebootstrap/handlersที่ระบุในHANDOFF ไม่reuseDuelremotesผิดความหมาย (`DuelEngineService.luau`, `DuelUIController.luau`, `DuelChoiceModal.luau`)
- [x] T-98: runtime5moves/สกัดได้/ต้นทุนไม่พอ/CD/รีเซ็ต/เปลี่ยนทีมและvisualอ่านท่าได้ — Edit-mode E2E `TestRunner.RunPlayerActions()` PASSED `106/106` (`738` assertions) & `TestRunner.RunSkillMovesAndDefense()` PASSED `14/14` (`112` assertions); Live Play runtime verified zero errors; รอ Owner ตรวจรับ visual/gameplay จริงใน Studio
- [x] T-99: syncdocs/currenthash/evidence ส่งreview ไม่ปิดงานเอง ([fix-001.md](assets/fix-001.md))

Ownerdelta2026-10-21: SlideจากSandboxทำก่อนใน02 ส่วนPoke/ShoulderและSkillMovesทำในimplementation03 ไม่ลบจากPhase1และส่งมอบ03 working-tree only
