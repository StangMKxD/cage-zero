# Independent re-review — Plan 01 / Fix Round 002

- วันที่: 2026-10-21 (Asia/Bangkok); Reviewer: Codex
- Technical verdict: **CHANGES_REQUESTED**
- Review board state: **ESCALATED / Turn OWNER (Stang) / Round 3** — F-05 ยังไม่ครบหลัง fix-001 และ fix-002 ไม่ใช่การอนุมัติหรือปิดแผน 00/01
- Reviewed ref: `main` HEAD `65026668fcae9d80094841bb147f3f4dc64b0b6c` + working tree และ untracked files ที่ส่ง Fix 002
- ตรวจตาม `review-002.md`, `fix-002.md`, รายงานแนบ, active PLAN/HANDOFF/tasks, source/test code และ rollback files จริง
- วิธีตรวจ: static review, filesystem hash comparison และ Studio Edit readback เท่านั้น ไม่ require โมดูล ไม่รัน tests/Play/restore ไม่ rebuild ฉาก และไม่ commit/push/merge/deploy

## 1. ฐานที่ตรวจ

Studio ที่อ่านสด: PlaceId `137721422246269`, studio_id `5331d36b-4ba7-4726-9bfe-4e853359c9d6`, Mode Edit, active variant **A**, arena มี 95 direct children ตรงกับรายงานด้านสถานะฉาก

อ่าน Script.Source เป็นส่วนย่อยแล้วรวมกลับตาม byte boundaries ของบรรทัด เทียบกับ local ได้ตรงกันทั้ง 4 ไฟล์:

| File | Bytes | Local = Studio SHA-256 |
| --- | ---: | --- |
| src/shared/Constants.luau | 3163 | `8060F4A96F8E064FD4BFA0B891D1284FF5ADA1D287F4193C749337962B01A28D` |
| src/shared/Types.luau | 5309 | `7DCFA0829E1B604440241AF4F0AE9BFE01E5255D66F000071569892631C6F810` |
| src/server/init.server.luau | 1114 | `F7156D8746B1B695C9039CEF16F86302B783952510F5F98D6AA1E59360DB42C0` |
| src/server/services/CagePhysicsService.luau | 133225 | `342881D2F38706E29A7B8EF3B8D4D2013D845A9591BCF1C7370E7F80AA0E4F3E` |

ตรวจ manifest entries ทั้ง 10 รายการ: working tree, post/files และ post/studio/scripts ตรงกับ manifest hashes ทั้งหมด (10/10 ในแต่ละชุด) typed post snapshot มี hash `B560E8F7F87AAF3714F9663AE31ADE37A281517BA190216635632BDBA58D51EB` ตรงกับ manifest แต่ขนาดไฟล์จริง **96143 bytes** ต่างจาก 6290 bytes ในรายงาน

BundledTestRunner ที่ส่งจริง: **85051 bytes**, SHA-256 **`25F992E3C63067AD581B0F0E8DCE1CAEB803D62F72ED75ABBCCE5A7015DB45EE`** ต่างจาก fix-002 ที่ระบุ 89343 bytes / `45D2D50EC401B2E05E1CE264A0453D3EF16B9501B6B2FD685956041BFF12140F` ไม่ทราบสาเหตุหรือผู้เปลี่ยนไฟล์ จึงไม่สรุปว่าไม่มีการรัน แต่ยังผูกผล **139/139 / 421 assertions** กับ artifact ปัจจุบันไม่ได้

ผล 139 tests และ 75 rollback checks เป็นผลที่ AGY รายงาน Codex ไม่ได้รันซ้ำ การตรวจ hash ข้างต้นเป็นการอ่าน/คำนวณข้อมูล ไม่ใช่การรับรองว่า rollback execution ปลอดภัยครบทุกสถานการณ์

## 2. ผลตรวจตาม Finding IDs

| Finding | ผลตรวจรอบนี้ |
| --- | --- |
| F-05 / P1 | **PARTIAL / OPEN / ESCALATED** — post payload sync และ Force/AllowDrift แก้แล้ว แต่ Studio content/object drift guard ยังไม่เพียงพอ และ restore-studio.luau ที่มีอยู่ยังเป็นฉบับเก่า |
| F-06 / P2 | **PARTIAL / OPEN** — routing และ goal coordinates แก้แล้ว แต่ลบ acceptance โดยไม่มี authority, historical provenance ยังคลาดเคลื่อน และ evidence hashes ไม่ตรง |
| F-08 / P1 | **FIX_VERIFIED_STATIC** — single contact ใช้ h.restitution แล้ว; มี multi-contact policy และ regression 5 tests |
| F-09 / P2 | **FIX_VERIFIED_STATIC** — ArenaSurfaceKind เพิ่ม GoalPocket แล้ว ตรงกับ service ที่ใช้ literal นี้ |
| F-10 / P2 | **PARTIAL / OPEN** — เพิ่ม wedge แก้บางพื้นที่ แต่ flat roof C ใช้ polygon คนละขอบกับ corner bevel catalog และ tests ไม่พิสูจน์ visual coverage |

คงระดับ F-10 เป็น P2 ตาม review-002 แม้ fix-002 เรียกว่า P1 ไม่เพิ่ม Finding ID ใหม่สำหรับปัญหาที่ยังอยู่ในข้อเดิม ผลตรวจ static ไม่ใช่ Owner approval หรือการรับรองครบแผน ข้อ F-01–F-04/F-07 ใช้ผลตรวจข้อแก้เดิมเป็นประวัติ ไม่มีหลักฐานใหม่ในรอบนี้ให้เปิดข้อเดิมเพิ่ม

## 3. รายละเอียดข้อที่ยังค้าง

### F-05 — P1 — Studio guard ไม่ตรวจเนื้อหา Source/geometry จริง

**สิ่งที่แก้แล้ว:** post payload ทั้ง 20 files ตรง manifest; Guard 4b ตรวจ payload integrity; -Force ข้ามเฉพาะ confirmation; -AllowDrift เป็นตัวเลือกแยก; generator มี PlaceId preflight; Lighting before-state gap ยังคงบันทึกตามจริง

**สิ่งที่ยังไม่ครบ:**

1. `restore.ps1:260–277` สร้าง verifyScriptPostState ที่ตรวจแค่ Source length และยอมต่างไม่เกิน 5 bytes การเปลี่ยนข้อความยาวเท่าเดิม เช่น Constants `"A"` เป็น `"C"` ผ่าน guard ได้ แม้เนื้อหาเปลี่ยนแล้ว
2. Branch `if not existedBefore` ตรวจเพียงว่า current มีอยู่ ไม่ตรวจ class หรือ Source เลย ดังนั้น CagePhysicsService ซึ่ง manifest ระบุ existedBeforeRun=false สามารถมี source เปลี่ยนทั้งชุดแล้วยังผ่าน ก่อนถูก Destroy ที่ :327–334
3. ไม่มี expected-post guard ของ descendants/properties/attributes ของ HexCageArena และ Baseplate ก่อน :340–350 ทำให้ arena ที่ผู้ใช้เติมวัตถุ/แก้ geometry หลัง snapshot ยังถูกลบ และ Baseplate ที่เปลี่ยนยังถูก reset ได้ Guard ต้องตรวจทั้งชุดก่อนเปลี่ยนชิ้นแรก
4. `restore-studio.luau` ที่มีอยู่จริง (75166 bytes) ยังเป็น generated script เก่า เริ่ม restore โดยไม่มี preflight block ใหม่ จึงยังเป็น artifact ที่นำไปใช้แล้วไม่มีกลไกที่รายงานอ้าง ไม่ได้รันไฟล์นี้ระหว่าง review

**Correction contract:** หลัง Stang วินิจฉัยให้เดินต่อ ให้เทียบ post Source แบบ byte-for-byte กับ payload หรือใช้ hash ที่ตรวจจริง ไม่ใช้ byte count แทน integrity; ตรวจทุก script รวม newly-created scripts และ protected instance state แบบครบชุดก่อน mutation; สร้าง artifact ให้ตรง generator/manifest และทดสอบ negative fixtures สำหรับ same-length Source edit, changed-new-script, changed arena/Baseplate, wrong place และ missing object โดย AGY ห้าม restore งานจริงเพื่อทดลอง

**Escalation:** ข้อ post-state guard อยู่ใน F-05 ตั้งแต่ review-001 และยังต้องส่งกลับหลัง fix-001 กับ fix-002 จึงครบเงื่อนไขหยุด automatic correction loop ตาม stang-luna/R02 ไม่ใช้ 75/75 internal checks แทนกรณีที่ยังไม่ครอบคลุม

### F-06 — P2 — เอกสารลบเกณฑ์รับงานและหลักฐานยังไม่ผูก artifact ที่ส่งจริง

**สิ่งที่แก้แล้ว:** HANDOFF goal positions เป็น ±120, routing เป็น READY_FOR_REVIEW/Codex Controller/AGY Implementer, plan ตัด back-alley traversal, comparison matrix ติดป้าย historical และไม่ใช้แทน current V-05

**สิ่งที่ยังไม่ครบ:**

1. Git diff ของ `plan.md` ส่วน Acceptance ลบข้อความเดิมทั้งข้อ: **“ไม่ทะลุในชุดทดสอบที่ประกาศและต้องไม่มี visual-only ceiling/ผิวหาย; ถ้าเคสใด fail ให้รายงาน ไม่สรุป ‘100%’ โดยไม่มีขอบเขตข้อมูล”** ไม่มี directive ที่อ้างใน fix-002 อนุญาตให้ยกเลิกเกณฑ์นี้ การ sync back alley ไม่จำเป็นต้องลบเงื่อนไขคุณภาพ/หลักฐานดังกล่าว ต้องคืนข้อกำหนด ไม่ลด spec เพื่อรองรับงานปัจจุบัน
2. Historical disclaimer ของ matrix ระบุ telemetry จาก commit `6502666` แต่ source ที่ commit นี้ยังมี BuildHexCageArena เดิม ไม่มี BuildCageArena/buildVariantCatalog/RunVariantComparisonSuite ดังนั้นควรระบุ HEAD baseline + historical dirty source/ref ที่มีหลักฐานจริง หาก hash ของรุ่นที่รันไม่ทราบให้ระบุ unknown ไม่อ้างว่า commit นี้สร้างผล A/B/C ชุดนั้น
3. BundledTestRunner hash/bytes ใน fix-002 ไม่ตรงไฟล์ที่ส่งจริงตาม §1 และ TEST_READY ยังสรุป 131 tests ขณะที่ fix-002/tasks ระบุ 139 tests แยก historical/current ให้ชัด และผูก actual run กับ source+test hashes ที่ตรงกัน หากไฟล์เปลี่ยนหลังผลรันให้ AGY เก็บผลบน artifact ล่าสุด
4. ใน fix-002 กล่าวว่ารอบ review-002 ยืนยันว่า AGY ไม่เคยรัน Play แต่รายงานรอบก่อนของ AGY เคยอ้าง Play Solo แล้ว สิ่งที่ Codex ระบุคือ **Codex ไม่ได้ยืนยัน Live Play บน source hash ล่าสุดในรอบ review นั้น** ต้องไม่เปลี่ยนความหมายเป็นข้อสรุปเกี่ยวกับทุก historical run ให้คง current V-02 เป็น NOT VERIFIED จนมีหลักฐานตรงชุด

ไม่พบ source diff นอก allowlist หรือ PRD/TDD/architecture/spec diff เพิ่มจาก Git baseline นี้ ประเด็นคือ active PLAN acceptance ถูกลบโดยไม่มี authority และ evidence current/historical ยังสับสน ไม่ใช่หลักฐานอนุญาตให้แก้เอกสารระบบเพิ่ม scope

### F-10 — P2 — Inset polygon ของ flat roof C ไม่ตรงกับ corner bevel

- พิกัด `CagePhysicsService.luau:3683–3705`: halfRoofX=72, halfRoofZ=112 แต่ยังนำ chamfer cut=20 จากผนังฐานมาใช้ตรงๆ ทำให้ innerRoofX=52, innerRoofZ=92 และ flat visual octagon มีขอบทแยง |X|+|Z|=164
- Corner bevel catalog 45° ใช้การ inset ตาม normal 8 studs: ที่ Y=32 ขอบทแยงจริงคือ **|X|+|Z| = 180 − 8√2 ≈ 168.6863** จุดต่อกับ Z=112 อยู่ที่ X≈56.6863 ซึ่งสอดคล้องกับ ceilPoly ในโครงหลังคาเอง ดังนั้น cut สำหรับ flat roof ต้องคำนวณจาก inset polygon ไม่ใช่คัด cut20 เดิม
- จุด `(60,32,106)` มี sum=166 จึงยังอยู่ใน central flat roof ตาม bevel catalog แต่ fix-002 เรียกจุดเดียวกันว่าอยู่นอกกรอบและใช้การไม่มี visual เป็น Zero Protrusion นี่เป็น expected result ที่ผิดกับ source geometry
- ตรวจ coverage แบบพื้นที่ได้โดยไม่อาศัยภาพ: panels 7 ชิ้นปัจจุบันมีพื้นที่ XZ รวม `104×224 + 2×20×184 + 4×(20×20/2) = 31456` ตาราง studs ขณะที่ inset octagon ที่ต่อ bevel จริงมีพื้นที่ประมาณ `31786.98` แม้ไม่ overlap เลยก็ยังขาดอย่างน้อยประมาณ **330.98 ตาราง studs** การเพิ่ม wedge จึงยังไม่พิสูจน์ว่าปิดครบ polygon จริง
- Tests `Tier2_BoundaryCornerCases.luau:186–233` ตรวจ bounds, solver bounce และว่า WedgePart มีอยู่/ไม่ชน แต่ไม่ได้ตรวจ visual polygon coverage หรือ expected outer boundary ที่ถูกต้อง จึงผ่านได้แม้ภาพยังมีช่องว่าง
- Correction contract: ใช้ inset polygon/face intersections จาก catalog เดียวสร้าง flat visual และตรวจ coverage/absence ของทุกมุมกับ bevel seams โดย AGY แยกสิ่งที่วัดจาก catalog กับ visual instances จริง ไม่เปลี่ยน catalog ให้เป็น cut20 เพื่อไล่ตาม test และไม่เคลม Zero Gap จากเพียง object existence

รายละเอียดเรขาคณิตข้างต้นเป็น static mathematical review ไม่ใช่ผลที่ Codex รัน Studio tests หรือสร้าง Variant C ใหม่

## 4. Gate status และคำวินิจฉัยที่ต้องการ

- Source parity: ยืนยันใหม่ 4/4; scene state A/95 children ตรงรายงาน
- V-01/V-03: ยังมี F-10 เรื่อง visual/catalog coverage
- V-05: matrix ที่มีเป็น historical; ไม่มี current comparison artifact ที่ผูก source/test hashes ชัดเจนให้รับรองในรอบนี้
- V-06: payload hashes แก้แล้ว แต่ F-05 ยังบล็อก Studio post-state safety; Lighting pre-state gap คงเดิม
- V-02/Live Play/R6, human visual aesthetics และ WAN observer: **NOT VERIFIED บน source ชุดนี้โดย Codex** AGY เองรายงาน current Play ยังไม่ได้รัน
- ไม่รัน tests/restore แทน AGY และไม่เปลี่ยน source/Studio หรือสถานะอนุมัติของแผน

กฎที่ใช้: [stang-luna SKILL.md](C:/Users/Stang/.codex/skills/stang-luna/SKILL.md:56) ระบุ **“หากบั๊กเดิม F-xx ถูกตีกลับซ้ำ 2 รอบติดต่อกัน (เข้าสู่ Round 3 แล้วยังไม่ผ่าน) ให้เปลี่ยน Board State เป็น ESCALATED หยุดลูปปิงปองทันที และแจ้งขอคำวินิจฉัยจาก Stang”** และ R02 กำหนดเงื่อนไขเดียวกัน จึงบันทึก escalation ใน tasks board และรอ Stang วินิจฉัยก่อนส่ง correction รอบใหม่ ไม่เปิดวงแก้อัตโนมัติ

## 5. Prompt ที่เตรียมไว้สำหรับใช้หลัง Stang วินิจฉัยให้แก้ต่อ

> ดำเนิน Fix Round 003 แบบควบคุมตาม assets/review-003.md เฉพาะ F-05/F-06/F-10 โดยใช้ HANDOFF เดิม รักษาข้อแก้ F-08/F-09 และข้อเดิมที่ตรวจ static แล้ว ก่อนเริ่มบันทึกคำวินิจฉัยของ Stang และ pin working tree/source/test hashes ห้ามเปลี่ยน scope หรือ acceptance เพื่อทำให้ผ่าน คืน acceptance ที่ถูกลบ; ทำ Studio guard ที่ตรวจ Source content ของทุก script และ post-state instances ทั้งชุดก่อน mutation; ใช้ isolated negative fixtures ไม่ restore งานจริง; สร้าง flat visual roof C จาก inset polygon ที่ตรง bevel catalog; แก้ expected tests ที่เอาจุดด้านในไปนับเป็นภายนอก; sync post payload/manifest/generated restore artifact และหลักฐานผลรันให้ตรง hashes ล่าสุด แยก historical/current และ Edit/Play/visual NOT VERIFIED บันทึก assets/fix-003.md ส่ง working tree ให้ Codex ตรวจซ้ำ ไม่ commit/push/merge/deploy/อนุมัติหรือปิดแผนเอง
