# Independent review — Plan 01-cage-physics

- วันที่ตรวจ: 2026-10-21 (Asia/Bangkok); Reviewer: Codex
- Verdict: **CHANGES_REQUESTED** — ไม่เปลี่ยนสถานะอนุมัติ/ปิดแผน 00 หรือ 01
- Reviewed ref: `main` HEAD `65026668fcae9d80094841bb147f3f4dc64b0b6c` **ร่วมกับ working tree และ untracked tests/docs** ณ รอบนี้ ไม่ใช่การรับรอง HEAD เพียงอย่างเดียว
- ขอบเขต: PLAN/HANDOFF, diff จาก baseline, source allowlist 4 ไฟล์, tests/e2e, comparison matrix, rollback bundle และรายงาน User Feedback Fixes ที่ผู้ใช้แนบ
- วิธีตรวจ: static review, อ่าน/hash ไฟล์, Studio Edit readback อย่างเดียว ไม่ require โมดูล ไม่สร้างสนาม ไม่รัน application tests/Play และไม่แก้ source
- ใช้ HANDOFF เดิมต่อสำหรับข้อแก้ใน scope; รายงานนี้ไม่ใช่ implementation approval หรือ scope expansion

## 1. หลักฐานและข้อจำกัด

Studio ที่อ่านสด: `Cage-Zero`, PlaceId `137721422246269`, studio_id `5331d36b-4ba7-4726-9bfe-4e853359c9d6`, Mode `Edit`, active variant `A`.

อ่าน Script.Source เป็นส่วนย่อยแล้วรวมกลับตามลำดับ เทียบ UTF-8 SHA-256 กับไฟล์ local ได้ตรงกันทั้ง 4 ไฟล์:

| Source | Bytes | Local = Studio SHA-256 |
| --- | ---: | --- |
| src/shared/Constants.luau | 3163 | `8060F4A96F8E064FD4BFA0B891D1284FF5ADA1D287F4193C749337962B01A28D` |
| src/shared/Types.luau | 5293 | `6498E44E7380AEE66A83503C46C0B6B450F3D6C2A9F3A1DF775CB89053123600` |
| src/server/init.server.luau | 1114 | `F7156D8746B1B695C9039CEF16F86302B783952510F5F98D6AA1E59360DB42C0` |
| src/server/services/CagePhysicsService.luau | 130843 | `5405C65736031A63896A05038E6DA1EECCA28388AB94E6CA194C80AFAE9D9C50` |

BundledTestRunner local SHA-256: `EF70503154D32DF6400DA51224A9AAB583BD1CC9CFF2B64403695E25F80284DB`.

ไม่พบ source ที่เปลี่ยนนอก 4 ไฟล์ allowlist เทียบ baseline; bootstrap ไม่เปิด BallService/MatchService/บริการ gameplay ของแผนถัดไป และเอกสารแผน 00 ไม่อยู่ใน diff รอบนี้ PRD/TDD/architecture/spec ไม่มี diff จาก baseline นี้

รายงานแนบระบุ 131/131 tests และ audits ผ่าน แต่ตัวเลขนี้เป็น **ผลที่ AGY รายงาน** ไม่ใช่ผลรันซ้ำโดย Codex และไม่เพียงพอรับรอง V-01–V-07 ทั้งหมด ตัวอย่าง assertions ที่ยังรับรองโกลเก่าดู F-02 การตรวจภาพจริง/asset appearance และ Play Runtime บน source hash ล่าสุดยัง **NOT VERIFIED** ในรอบนี้ ไม่ได้ร้องขอภาพหรือวิดีโอเพิ่ม

ไฟล์ `assets/runs/run-01/review.md` ที่มี APPROVED เป็นไฟล์ประวัติจาก commit `2f5f76b` ไม่ใช้รับรอง working tree ปัจจุบัน

## 2. Findings

### F-01 — P1 — Solver ยังปิดปากประตูด้วยกำแพงเต็ม

- พิกัด: `src/server/services/CagePhysicsService.luau:194–220`, `997–1032`, `1279–1286`, `3443–3447`
- Builder ปิด CanCollide/CanQuery ของ Wall_North/South แล้วสร้างผนังซ้าย/ขวาเพื่อเปิดปากโกล แต่ catalog ที่ solver อ่านยังเป็นผนังเต็มกว้าง 160/120 studs และ `canCollide=true` นอกจากนี้ containment clamp บังคับ `abs(Z) <= 120-radius` ทุกตำแหน่งโดยไม่เว้นช่องโกล
- อ่าน Studio สดพบ Wall_North `CanCollide=false`, Size `(160,32,2)` และ Goal_North เป็นช่องไม่ชนที่ `(0,5,-120)` ตรงกับ builder แต่ไม่ตรงกับ solver
- ผล: บอลจาก solver เด้งกลับหน้าช่องโกลที่ภาพ/engine เปิดไว้ เช่นจุดเริ่ม `(0,5,-117)`, velocity `(0,0,-180)`, dt `1/30`, radius `1.25` จะพบ Wall_North แทนการผ่านช่องโกล; นี่เป็นข้อสรุปจากโค้ด **ยังไม่ได้รัน reproduction**
- แก้โดยให้ catalog, builder, solver และ containment ใช้ geometry ของช่องโกล/goal pocket ชุดเดียว เพิ่ม regression ที่บอลผ่านกึ่งกลางโกลทั้งสองฝั่ง แต่ยังชนเสา/คาน/ผนังข้าง ไม่เปิดระบบแข่งขันหรือ scoring gameplay เพิ่ม

### F-02 — P1 — คงเขตโกลเก่าเพื่อให้ tests เดิมผ่าน ทำให้ query คืนผลผิด

- พิกัด: `src/server/services/CagePhysicsService.luau:915–942`; `tests/e2e/Tier1_FeatureCoverage.luau:666–669`; `tests/e2e/Tier2_BoundaryCornerCases.luau:230–273`
- `CheckGoalScored` ยังคงเงื่อนไข Z `[-112,-106]` และ `[106,112]` เพิ่มจากโกลจริง ±120 พร้อมคอมเมนต์ legacy test probe corridor; ดังนั้น query ที่ `(0,5,-108)` คืน North ทั้งที่อยู่หน้าโกลจริง 12 studs ส่วน `IsBehindGoal360Zone` ยังอ้าง ±106 แม้ GOAL_BACK_ZONE_STUDS=0
- Tests ยังคาดหวังผลผิดนี้ เช่น TC-F11-04 ต้องให้ -108 เป็นโกล และ TC-T2-GOAL-05 ต้องให้ 108 เป็น back alley
- แก้ query และ tests ให้ตรง geometry/คำสั่งเปลี่ยนโกลล่าสุด เอา fallback สำหรับ test เก่าออก เพิ่ม negative cases ที่ ±108 และบริเวณหน้าโกล ใช้ semantics ของ query ที่ตกลงไว้ ไม่ขยายเป็น match scoring system

### F-03 — P1 — Swept sphere พลาดการชนขอบเสาที่เข้าและออกระหว่าง step

- พิกัด: `src/server/services/CagePhysicsService.luau:1095–1105`
- เมื่อจุดเข้า expanded AABB อยู่นอก rounded corner โค้ดตรวจแค่ปลาย segment แล้ว return nil หากปลายก็อยู่นอก ทำให้พลาด segment ที่ผ่าน sphere–OBB contact interval ระหว่างกลาง
- ตัวอย่างเชิงคณิตศาสตร์ใน envelope ที่ประกาศ: Variant A, start `(-15,5,-118.6)`, velocity `(180,0,0)`, dt `1/30`, radius `1.25`, ปิด ramps/boosts เสา GoalPost_North_Left มี X `[-12.4,-11.6]`, Z `[-120.4,-119.6]` ระยะห่างแกน Z = 1 จุดเข้า expanded box ที่ X=-13.65 มี distance `sqrt(1.25^2+1^2)=1.6008` และปลาย X=-9 ก็อยู่นอก แต่ที่ X=-13.15 distance=1.25 จึงชนจริงในระหว่าง step โค้ดกลับทิ้ง candidate; containment ไม่ช่วยเพราะเส้นทางอยู่ในขอบสนาม
- หลักฐานนี้เป็น **static mathematical counterexample** ไม่ใช่ผลรันทดสอบ แก้ให้หา TOI ของ face/edge/corner หรือ contact interval จริง เพิ่ม public-interface regression สำหรับตัวอย่างนี้และ mirrored cases อย่าใช้ end projection แทนหลักฐานชนเสา

### F-04 — P1 — หลังคามุม C ที่มองเห็นลาดคนละมุมกับ collider/solver

- พิกัด: `src/server/services/CagePhysicsService.luau:378–400` เทียบ `3571–3585`; `notes.md:181–183`
- Catalog สร้าง corner bevel 45° โดยเลื่อนแนวราบตาม diagonal normal 8 studs และขึ้น 8 studs แต่ visual ใหม่ใช้ `slopeVec=(-8,8,-8)` ซึ่งมีแนวราบ `sqrt(8^2+8^2)=11.3137` studs จึงลาด `atan(8/11.3137)=35.264°` ไม่ใช่ 45°
- ผล: ป้ายผล Zero Protrusions วัดเฉพาะภาพไม่ยืนยัน surface parity ผู้เล่นจะเห็นหลังคาที่ไม่ตรงกับจุดชน/ทิศสะท้อนของ collider และ solver
- แก้จาก corner face ใน catalog ชุดเดียว ไม่คำนวณ visual slope แยก เพิ่มตรวจ plane normal และตำแหน่งทุก roof face รวมจุดต่อทั้ง 8 ด้าน ก่อนรับรอง V-01/V-03

### F-05 — P1 — Rollback/evidence เป็นชุดเก่า และ restore ไม่มี guard ป้องกันงานที่เปลี่ยนหลัง snapshot

- พิกัด: `.sandbox/rollback/run-phase01-cage-physics-01/manifest.json:42–44,126–128`; `restore.ps1:89–104,128–143`; `CagePhysicsService.luau:2979–3042`
- Manifest อ้าง Constants hash `4A7AE0...` และ CagePhysicsService `E004D550...` (71446 bytes) แต่ชุด local=Studio ปัจจุบันเป็น `8060F4...` และ `5405C657...` (130843 bytes) ดังนั้น flags repoStudioParityMatch=true ใน manifest รับรองชุดเก่า ไม่ใช่งานที่ส่งรอบนี้
- restore ตรวจ pre-files กับ Git baseline แล้ว Copy-Item ทับปลายทาง โดยไม่มีการเทียบ current files กับ expected post-state ก่อนเริ่ม จึงมีความเสี่ยงทับงานที่แก้เพิ่มหลัง snapshot นอกจากนี้ snapshot JSON pre/post ไม่พบ Lighting/Sky/Atmosphere ที่ builder ปัจจุบันแก้ รวมถึงการลบ Sky ซ้ำ
- แก้โดยรักษา authentic pre/ เดิม อัปเดต post snapshot/manifest ให้ตรงชุดส่งมอบ เพิ่ม current-post drift guards ก่อน mutation ทั้ง local/Studio และระบุ/ครอบคลุมขอบเขต Lighting ที่มี before-state จริง หากข้อมูลก่อนเปลี่ยนไม่มีให้บันทึก gap ตามจริง ห้ามสร้างย้อนแล้วอ้างเป็น pre-state ไม่ให้รัน restore จริงระหว่างแก้โดยพลการ

### F-06 — P2 — Canonical plan/acceptance ไม่ตามคำสั่งเพิ่มเติม และยังบอกว่ารอเริ่มงาน

- พิกัด: `plan.md:3–5,16,35,50`; `tasks.md:13,19–24`; `assets/HANDOFF.md:31,82–84,97–99`; `docs/specs/spec-01-cage-and-events.md:12`
- `ORIGINAL_REQUEST.md` บันทึก directive ย้ายโกลไป ±120/ยกเลิก back alley, ตั้ง A, ลด Baseplate และอนุญาต ignore .agents แต่ PLAN/HANDOFF ยังตรวจ ±106/back alley14/default B; P-03 กับ tasks ยังไม่บันทึกการส่งมอบ ทั้งที่ notes รายงานเสร็จหลายรอบ จึงไม่มี acceptance contract ปัจจุบันที่สอดคล้องกัน
- บันทึก directive เป็น provenance ที่ทีมเก็บ ไม่ใช่การยืนยันอิสระว่าทุกข้อความมี Owner approval แล้ว โดยเฉพาะ visual upgrade ทั้ง A/B/C และเมือง/Lighting ให้ผูกขอบเขตกับคำสั่งจริงที่มีอยู่ ห้ามตีความรายงานหรือการขอตรวจครั้งนี้เป็นอนุมัติเพิ่ม
- แก้โดย sync เฉพาะ approved deltas พร้อมอ้าง provenance ใน HANDOFF เดิม/notes และจำแนกของเก่าว่า superseded; คง owner decisions/approval gates ที่ยังค้าง ไม่เติม approval หรือเปลี่ยน CLOSED/PASS เอง ไม่คืน back alley เพื่อไล่ตาม tests เก่า และไม่แก้ PRD/TDD/CONTEXT ขยาย scope เพื่อรองรับโค้ดภายหลัง

### F-07 — P2 — คำสั่งตรวจ local พิมพ์ผล 131 tests โดยไม่ได้รัน tests

- พิกัด: `tests/e2e/run_all.ps1:20–53`; `TEST_READY.md:144–150,199–204`
- Script ตรวจเพียงว่าไฟล์ทั้ง 7 มีอยู่ แล้วพิมพ์ว่า All 131 tests have been 100% verified แบบไม่มีเงื่อนไข แม้ tests มี assertion fail หรือ Studio ไม่เปิดก็ยังจบสำเร็จได้ ขณะที่ TEST_READY แนะนำคำสั่งนี้ในฐานะ Local/CI validation พร้อมสถานะพร้อม review/deployment
- แก้ให้แยก file-presence check จากการ execute tests อย่างชัดเจน เอา success claim ที่ไม่มาจากผลรันออก หากยังไม่มี engine runner ให้รายงาน NOT RUN/UNAVAILABLE ตามจริง และอ้าง actual Studio run ด้วย source/test hash โดยแยก Edit analytical tests ออกจาก Live Play/R6 และ visual gates

## 3. ข้อแก้ feedback 4 จุดที่เห็นใน source

- RunoffSlab top=-0.10, เริ่ม |Z|=121 และ OuterAlleyApron top=-0.15 ตรงกับรายงานแก้การบังเส้น จาก static geometry
- overlapsGoalMouth ถูกใช้ข้าม lower braces/rails ที่ทับช่องประตู แต่เป็นการข้ามทั้ง bay ไม่ใช่ตัดปลายคานให้จบที่เสาประตูดังถ้อยคำรายงาน
- Touchline X=±79.4 และ HalfwayLine=158.8 มีจริง; goal line ของ A กว้าง 159.4 รวม lw ส่วน B/C ใช้เส้นแยกตามมุมปาด
- Skybox/Atmosphere/ตึกมีโค้ดเปลี่ยนจริง แต่คุณภาพภาพและ asset load ไม่ได้ตรวจด้วยตาในรอบนี้ จึงยังไม่รับรองคำว่าเข้าธีมหรือภาพผ่าน 100%

## 4. Prompt ส่งกลับ AGY (copy-ready)

> ตรวจและแก้ Plan 01-cage-physics ตาม assets/review-001.md ข้อ F-01–F-07 โดยใช้ assets/HANDOFF.md เดิม ก่อนแก้ให้ตรวจ baseline/current working tree และ reconcile approved directives ที่มีหลักฐานกับ PLAN/HANDOFF/tests โดยห้ามเพิ่ม scope หรือสร้าง approval ย้อนหลัง ส่วนที่ไม่มีสิทธิ์ชัดเจนให้หยุดเฉพาะส่วนนั้นและรายงาน ห้ามคืนโกล ±106/back alley14 เพื่อรักษา test เก่า แก้ catalog/builder/solver ให้ตรงกัน เปิดช่องโกลจริง เอา legacy goal query ออก แก้ swept-sphere edge/corner TOI และ roof C surface parity พร้อม regression ตาม counterexamples ในรายงาน จากนั้น AGY รัน targeted checks และ gates ที่เกี่ยวข้องบน hash ล่าสุด แยก Static/Edit/Play/visual ที่ยัง NOT VERIFIED รักษา authentic pre/ และป้องกัน rollback ทับ post drift บันทึกผลจริงใน assets/fix-001.md พร้อม source/test hashes และ evidence references ส่ง working tree ให้ Codex ตรวจซ้ำ ไม่ commit/push/merge/deploy ไม่ปิดหรืออนุมัติแผน 00/01 และไม่ใช้ historical APPROVED เป็นผลรับรองรอบนี้
