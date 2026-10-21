# Independent re-review — Plan 01-cage-physics / fix-001

- วันที่: 2026-10-21 (Asia/Bangkok); Reviewer: Codex
- Verdict: **CHANGES_REQUESTED** — ไม่อนุมัติหรือปิดแผน 00/01
- Reviewed ref: `main` HEAD `65026668fcae9d80094841bb147f3f4dc64b0b6c` + working tree/untracked files หลัง fix-001
- Inputs: `review-001.md`, `fix-001.md`, รายงานแนบจากผู้ใช้, PLAN/HANDOFF/tasks, source, regression tests และ rollback artifacts จริง
- วิธีตรวจ: static review + filesystem hashes + Studio Edit Source/property readback เท่านั้น ไม่รัน application tests/Play ไม่ require โมดูล ไม่เปลี่ยนฉาก/source และไม่ commit/push/merge/deploy

## 1. ฐานที่ตรวจและหลักฐาน

อ่าน Studio สดจาก PlaceId `137721422246269`, studio_id `5331d36b-4ba7-4726-9bfe-4e853359c9d6`, Mode Edit แล้วรวม Source ที่อ่านเป็นส่วนย่อย เทียบ UTF-8 bytes กับ local ได้ตรงกันครบ 4 ไฟล์:

| File | Bytes | Local = Studio SHA-256 |
| --- | ---: | --- |
| src/shared/Constants.luau | 3163 | `8060F4A96F8E064FD4BFA0B891D1284FF5ADA1D287F4193C749337962B01A28D` |
| src/shared/Types.luau | 5293 | `6498E44E7380AEE66A83503C46C0B6B450F3D6C2A9F3A1DF775CB89053123600` |
| src/server/init.server.luau | 1114 | `F7156D8746B1B695C9039CEF16F86302B783952510F5F98D6AA1E59360DB42C0` |
| src/server/services/CagePhysicsService.luau | 131694 | `6DF9195BB7C00638FEAEEF4F298B0513FDB8B35842504A37E43D37EFCB0ED99C` |

BundledTestRunner local hash: `AE928EFFCE359418C1E28D877C5B11E57E0002536C259B864C746DAE02171EC7`.

131/131 tests / 374 assertions เป็น **ผลที่ AGY รายงาน** รอบนี้ Codex ไม่ได้รันซ้ำ ไม่ใช้ตัวเลขนี้แทนการตรวจ type contracts, snapshot integrity, Live Play/R6 หรือ visual coverage ผล source readback ไม่ยืนยันว่า ModuleScript cache/ฉากเดิมถูก rebuild จาก Source ปัจจุบันแล้ว

Scene property readback พบ active variant **B** ขณะที่รายงานส่งมอบระบุ A; Wall_North มี Size `(120,32,2)`, CanCollide=false และ GoalPocket colliders อยู่จริง (เช่น GoalBackNet_North `(0,5,-126)`, Size `(24,10,0.5)`, Restitution=0.4) ไม่ทราบว่าใครสลับ variant หลังรายงาน จึงบันทึกเป็น state discrepancy ให้ยืนยันจุดส่งมอบ ไม่สรุปว่า AGY รายงานเท็จ และไม่สั่ง reset ฉากเอง

ไม่พบ diff ของ PRD/TDD/architecture/spec จาก Git baseline นี้ และ source ที่เปลี่ยนยังจำกัดใน allowlist 4 ไฟล์ การเปลี่ยนเอกสารใน fix-001 เป็นการพยายาม sync directive เดิม แต่ยังไม่ครบตาม F-06

## 2. สถานะ Finding เดิม

| ID | ผลตรวจซ้ำ | หลักฐาน/ขอบเขต |
| --- | --- | --- |
| F-01 | FIX_VERIFIED_STATIC สำหรับข้อกำแพงปิดปากโกลเดิม | catalog แยก end-wall segments และเปิดช่อง containment แล้ว; tests เพิ่ม center shots North/South ที่ Tier1:330–344; มีปัญหาใหม่ของ GoalPocket แยก F-08/F-09 |
| F-02 | FIX_VERIFIED_STATIC | CagePhysicsService:1046–1070 เอา corridor ±106..112 ออก, back alley query คืน false เมื่อ depth=0; tests เปลี่ยนเป็นโกล ±121 และ negative cases ±108 |
| F-03 | FIX_VERIFIED_STATIC | :1242–1293 ค้นหา distance minimum ภายใน interval และ bisection; Tier1:363–378 เพิ่ม counterexample ทั้งเสาซ้าย/ขวา ไม่ได้ยืนยันผลรันเอง |
| F-04 | FIX_VERIFIED_STATIC สำหรับมุมเอียงเดิม | :3665–3666 visual bevel ใช้ CFrame ของ catalog จึงแก้ 35.264° เป็น plane เดียวกับ collider; ไม่ได้หมายความว่าพื้นที่ roof visual ครบทุกจุด ดู F-10 |
| F-05 | **PARTIAL / OPEN — P1** | manifest เปลี่ยนแล้ว แต่ post snapshot bytes ยังเก่า และ Studio restore ยังไม่มี post-state guard |
| F-06 | **PARTIAL / OPEN — P2** | เอกสารหลักเปลี่ยนบางส่วน แต่ HANDOFF ยังมีโกล ±106 และ routing/ผลเทียบยังไม่ตามชุดปัจจุบัน |
| F-07 | FIX_VERIFIED_STATIC สำหรับผล 131 tests ที่พิมพ์เองเดิม | run_all.ps1 เอาข้อความเคลมผ่านออกและระบุ NOT RUN/UNAVAILABLE; TEST_READY แยก file-presence จาก engine execution แล้ว ไม่ใช่หลักฐานว่าทุก gate ผ่าน |

FIX_VERIFIED_STATIC เป็นผลตรวจข้อแก้ในโค้ด/เอกสารตามหลักฐานที่ระบุ ไม่ใช่ Owner approval หรือการรับรอง full regression ไม่เปลี่ยนสถานะ task/plan ให้ผ่านจากตารางนี้

## 3. Findings ที่ยังต้องแก้

### F-05 — P1 — เปลี่ยนเฉพาะ manifest แต่ post snapshots ยังไม่ตรง และ guard ยังไม่ครอบคลุม Studio

- พิกัด: `.sandbox/rollback/run-phase01-cage-physics-01/manifest.json:42–44,126–128`, `post/files/src/...`, `post/studio/scripts/src/...`, `restore.ps1:106–140,224–279`
- Hash local ตรง manifest ใหม่ทั้ง 10 entries แต่ตรวจไฟล์จริงใน **post/files และ post/studio/scripts** พบ Constants ยังเป็น `4A7AE0C993EDCBDF9F216F1E47026DD1EE7B76B41D9FD2FF9BDE414945EA1FD8` แทน `8060F4...`; CagePhysicsService ยังเป็น `E004D5504F2C10F0B669DAF78435EB95E427C3B8E2173AFC876D1691B77686D2` แทน `6DF919...` รวม 4 snapshot files ไม่ตรง manifest
- ดังนั้นผล `restore.ps1 -DryRun -Mode FilesOnly` ผ่าน 5 guards ไม่พิสูจน์ความสมบูรณ์ของ V-06 เพราะ guard ใหม่ตรวจ working tree ไม่ตรวจว่า post bundle payload ตรงกับ manifest หรือไม่
- Guard ใหม่ไม่มี Studio readback ส่วน Luau ที่สร้างยังเขียน Source/Destroy arena/reset Baseplate โดยไม่มีการตรวจ PlaceId และ expected post-state ทั้งชุดก่อน mutation การตรวจ local ที่เวลา generate ไม่ป้องกัน Studio ที่ drift หลังจากนั้น
- `-Force` ซึ่งเดิมใช้ข้าม confirmation สามารถข้าม drift guard ใหม่ด้วย ต้องแยกการยืนยันจากการอนุญาตทับ drift ตามเจตนาจริง ไม่ให้คำสั่งเดิมที่ใช้ Force เพื่อไม่ถามยืนยันไปปิด guard โดยไม่รู้ตัว
- Lighting baseline gap ถูกบันทึกแล้ว เป็นการแก้ด้าน honesty ที่ถูกต้อง แต่ gap ยังมีอยู่ ไม่ใช่ rollback Lighting ที่ครบถ้วน
- ส่งแก้: รักษา authentic pre/ เดิม; sync post/files, post/studio/scripts, typed post snapshot และ manifest ให้สอดคล้องกัน; เพิ่ม Studio PlaceId/post-state guards แบบตรวจทั้งชุดก่อนเปลี่ยนชิ้นแรก และทดสอบ negative drift ใน fixture โดย AGY ไม่รัน restore จริงบนงานผู้ใช้โดยพลการ

### F-06 — P2 — Acceptance/routing/evidence ยังขัดกัน

- พิกัด: `assets/HANDOFF.md:73` ยังระบุ Goal_North/South Z=±106 ขณะที่ข้อ 5 บอก ±120; `plan.md` acceptance ยังเขียน R6 อ้อมหลังโกลได้; `agent.md:5,8,11` และ `docs/READ.md:4` ยัง READY_FOR_IMPLEMENTATION/AGY Controller แต่ plan/tasks เปลี่ยนเป็น READY_FOR_REVIEW/Codex Controller
- `TEST_READY.md:81–83,118` ยังอธิบายโกล ±106 และ back alley เดิม; comparison matrix ยังมี first-hit tag `Wall_North` และ M05_BackGoalAlley14 โดยไม่แยกว่าเป็น historical/stale ทั้งที่ catalog ปัจจุบันไม่ชน Wall_North เต็มแล้ว
- ส่งแก้: ใช้ HANDOFF เดิม reconcile approved deltas ให้ครบทุกส่วนที่เป็น active contract; เก็บผลเก่าได้แต่ระบุ historical/source hash อย่านำผลเดิมเป็น current V-05; ผูก scope visual A/B/C/Lighting กับคำสั่งจริงที่มีอยู่ ไม่สร้าง approval ย้อนหลัง และไม่แก้ PRD/TDD/CONTEXT เพิ่ม scope เพื่อให้ตรง implementation
- เอกสารไม่มีการเปลี่ยนสถานะแผนเป็น CLOSED/APPROVED ใน fix นี้ แต่การติ๊ก implementation complete ยังไม่ใช่ reviewer verification

### F-08 — P1 (ใหม่) — GoalPocket restitution 0.40 ถูก resolve เป็น 0.88

- พิกัด: `src/server/services/CagePhysicsService.luau:648–650,714–718,1571–1589`
- GoalPocket ใหม่ใช้ e=0.40 แต่ chosenRestitution เริ่มด้วย STANDARD_WALL_RESTITUTION=0.88 แล้วเปลี่ยนเฉพาะเมื่อ h.restitution สูงกว่า (ยกเว้น floor/bumper) กรณีชนตาข่ายเพียงผิวเดียวจึงยังใช้ 0.88 แม้ catalog/Studio attribute บอก 0.40
- Static counterexample สำหรับ AGY: start `(0,5,-123)`, velocity `(0,0,-60)`, dt `1/30`, radius `1.25`, Variant A; ชน GoalBackNet_North ที่ center Z=-124.5 ระหว่าง step ค่าที่ควรสะท้อนตาม catalog คือ Vz=+24 แต่ branch ปัจจุบันเลือก +52.8 การ projection ตอนจบไม่แก้เพราะลูกยังอยู่ใน pocket bounds ตัวอย่างนี้ **ยังไม่ได้รันโดย Codex**
- ส่งแก้: single hit ใช้ restitution ของผิวที่ชนจริง กำหนด policy สำหรับ simultaneous contacts ชัดเจน และเพิ่ม regression ที่ public solver สำหรับ net back/side/top รวม mirrored goals ตรวจอัตราความเร็วจริง ไม่ตรวจเฉพาะ attribute

### F-09 — P2 (ใหม่) — GoalPocket ไม่อยู่ใน shared surface type

- พิกัด: `src/shared/Types.luau:146–160,169–171` เทียบ `CagePhysicsService.luau:714,1159,1298,3617`
- เพิ่ม kind="GoalPocket" ใน service ที่เป็น --!strict แต่ union ArenaSurfaceKind ไม่มี literal นี้ ขณะที่ ArenaSurfaceDef.kind บังคับใช้ union เดิม จึงทำให้ source ใหม่ไม่สอดคล้อง shared type contract; runtime tests ที่ผ่านไม่ตรวจสิ่งนี้
- ส่งแก้: เพิ่ม/ปรับ type ให้ตรง contract ใน Types ซึ่งอยู่ใน allowlist แล้ว ตรวจ strict type analysis ตามเครื่องมือที่มีและรายงาน unavailable หากไม่มี ห้าม cast any หรือขยายเป็น string เพื่อกลบปัญหา จากนั้น sync/hash Types ใหม่และอัปเดต post bundle
- เป็นข้อสรุปจากการอ่าน type declaration ไม่ใช่การอ้างว่า Codex รัน compiler แล้ว

### F-10 — P2 (ใหม่) — Flat roof visual ของ C มีช่องว่างใต้ collider

- พิกัด: `src/server/services/CagePhysicsService.luau:3627–3634`
- หลังแก้มุม bevel แล้ว แผ่น CageCeiling หลักยังซ่อนอยู่ และ visual แยกเป็น center X∈[-52,52], side strips ที่ |X|∈[52,72]/|Z|≤92 และ corner patches รอบ `(±56,±96)` ขนาด 14×(6√2) ซึ่งขอบ Z ไปได้เพียงประมาณ ±103.95
- Static geometry counterexample: จุด `(54,32,108)` อยู่ใน central ceiling collider และอยู่ด้านในของ roof polygon C แต่ไม่มี flat visual panel ครอบคลุม (เกิน center X=52, เกิน side strip Z=92, เกิน corner patch Z≈103.95) และไม่อยู่บน bevel plane จึงเห็นช่องโล่งที่บอลยังชนเพดานล่องหนได้ การตรวจแค่ normal 45° หรือ zero protrusions ไม่ตรวจ missing coverage
- ส่งแก้: สร้าง flat roof visual จาก inset polygon/catalog ที่เป็นแหล่งเดียวกับ collider ปิด corner seams ให้ครบ; AGY ตรวจจุดนี้และ mirrored points ด้วย geometry/scene evidence ไม่จำเป็นต้องส่ง screenshot/video และไม่เพิ่ม profile/feature ใหม่

## 4. ข้อจำกัด verification และรอบถัดไป

- Source parity 4/4 ยืนยันใหม่แล้ว; geometry build/runtime result บน hash นี้ยังอาศัยรายงาน AGY และมีข้อบกพร่อง static ข้างต้น
- Live Play/R6 traversal, human visual aesthetics และ WAN observer ยัง **NOT VERIFIED โดย Codex ในรอบนี้**; เอกสาร fix-001 ไม่ควรนำ Edit analytical suite ไปแทน gates เหล่านี้
- F-05/F-06 ยังเป็นการส่งกลับครั้งแรกหลัง fix-001 ไม่ถึงเกณฑ์ 3-strike circuit breaker

## 5. Prompt ส่ง AGY (copy-ready)

> แก้ตาม assets/review-002.md โดยใช้ HANDOFF เดิม: F-05/F-06 ที่ยัง OPEN และข้อใหม่ F-08/F-09/F-10 รักษาข้อแก้ F-01/F-02/F-03/F-04/F-07 ที่ตรวจ static แล้ว ก่อนลงมือ pin working tree/hash และตรวจสิทธิ์/approved deltas เดิมให้ครบ อย่าเพิ่ม scope หรือ approval ย้อนหลัง แก้ restitution ของ GoalPocket, shared type, roof visual coverage และ rollback post payload/Studio drift guards ให้ครบ รักษา authentic pre/; อย่าใช้ -Force เพื่อข้าม guard แก้เอกสาร active contract และระบุ historical matrix ให้ชัด AGY รัน regression ตาม counterexamples และ verification ที่ได้รับผลกระทบบน source/test hashes ใหม่ แยก Edit/Play/visual NOT VERIFIED และยืนยัน active variant ณ จุดส่งมอบ (Codex อ่านพบ B ขณะรายงานระบุ A; อย่าเขียนทับการเปลี่ยนของผู้ใช้หากมี) ส่ง assets/fix-002.md พร้อมหลักฐานจริงและ working tree ให้ Codex ตรวจซ้ำ ไม่ commit/push/merge/deploy หรือปิด/อนุมัติแผนเอง
