# Independent re-review — Plan 01 / Fix Round 003

- วันที่: 2026-10-21 (Asia/Bangkok); Reviewer: Codex
- Verdict: **CHANGES_REQUESTED — คง OPEN F-05/P1 และ F-06/P2**; F-10 แก้ geometry ได้ในระดับ static
- Reviewed ref: `main` HEAD `65026668fcae9d80094841bb147f3f4dc64b0b6c` + current working tree/untracked files หลัง fix-003
- Authority: รอบแก้นี้ได้รับคำวินิจฉัย Stang “ให้แก้ได้” หลัง review-003 แล้ว; ในรอบตรวจนี้ Stang ยืนยันเพิ่มโดยตรงว่า **“ผมสั่งเพิ่มกับ AGY แล้ว”** สำหรับบรรยากาศหมอง/ฟุ้ง/หมอก จึงไม่ถือการปรับ Lighting นี้เป็น unauthorized scope
- วิธีตรวจ: อ่าน source/docs/tests/rollback artifacts, filesystem hashes และ Studio Edit Source/property readback เท่านั้น ไม่รัน tests/Play/restore ไม่ rebuild ฉาก ไม่แก้ source และไม่ commit/push/merge/deploy
- ไม่อนุมัติหรือปิดแผน 00/01 และไม่ใช้รายงาน AGY เป็น independent test execution ของ Codex

## 1. หลักฐานที่ตรวจได้ใหม่

Studio: PlaceId `137721422246269`, studio_id `5331d36b-4ba7-4726-9bfe-4e853359c9d6`, Mode Edit, active variant **A**, arena มี **95 direct children** อ่านค่า Lighting.ClockTime≈16.8, Atmosphere.Density≈0.38 และ Haze=2.5 ตรงค่าที่รายงาน (มี float precision ของ engine)

อ่าน Script.Source เป็นส่วนย่อยรวมกลับแล้วเทียบ UTF-8 bytes กับ local ตรงกัน 4/4:

| File | Bytes | Local = Studio SHA-256 |
| --- | ---: | --- |
| src/shared/Constants.luau | 3163 | `8060F4A96F8E064FD4BFA0B891D1284FF5ADA1D287F4193C749337962B01A28D` |
| src/shared/Types.luau | 5309 | `7DCFA0829E1B604440241AF4F0AE9BFE01E5255D66F000071569892631C6F810` |
| src/server/init.server.luau | 1114 | `F7156D8746B1B695C9039CEF16F86302B783952510F5F98D6AA1E59360DB42C0` |
| src/server/services/CagePhysicsService.luau | 134331 | `09B564258699F4CF3BE76483EE9D819D610A7F47A69A3F977D1F0E40E0F7D7AB` |

- BundledTestRunner: **89351 bytes**, `9BD24D9E2836C37D49CCBB9F8A0B48B41C429AB0AF03C54F84B874E3BFB8291B` ตรงกับ fix-003 รอบนี้ แก้ปัญหา artifact hash ของ test runner รอบก่อนแล้ว
- Manifest script entries 10 รายการ: local files, post/files และ post/studio/scripts ตรง hashes ใน manifest ทั้งหมด
- Post snapshot hash `DA0E86DE6833A5720564E51A43C3A61CEF4D133D9B0C3AED94456D3719B6A2C3` ตรง manifest แต่การตรง hash ไม่พิสูจน์ว่า snapshot ครบ/สด ดู F-05
- Generated restore-studio.luau: **84634 bytes**, actual SHA-256 **`4A8292DF494118C2488AE8B7D80C88D7E7D93428DDAB2474CDCE59AB50E08EAF`** ไม่ตรง `F5C1B69DE07842B1EB55D93BF775B3CF4BC64BDEB1CD37C9FBE13F85E0EBAFF5` ที่ fix-003:22 อ้าง
- ผล 141/141 tests, 445 assertions, 75/75 rollback checks และ negative fixtures เป็น **ผลที่ AGY รายงาน** ไม่ใช่ผลรันซ้ำโดย Codex

ไม่พบ diff ของ PRD/TDD/architecture/spec เพิ่มจาก Git baseline นี้ source diff ยังอยู่ใน allowlist 4 ไฟล์ ส่วน Lighting ได้รับคำยืนยันจากผู้ใช้แล้ว การอ่านค่า scalar ของแสงไม่ใช่การรับรองคุณภาพภาพหรือ screen capture ที่ AGY อ้าง

## 2. สถานะข้อแก้

| ID | ผลตรวจ |
| --- | --- |
| F-05 / P1 | **PARTIAL / OPEN** — script content SHA-256 และ generated guard แก้แล้ว แต่ protected geometry ยังตรวจเพียง summary ไม่ใช่ expected post-state ครบชุด |
| F-06 / P2 | **PARTIAL / OPEN** — คืน acceptance/historical provenance/test count และ runner hash แล้ว; ยังมี generated restore hash และ routing state ที่ไม่ตรงรายงาน |
| F-10 / P2 | **FIX_VERIFIED_STATIC** — C visual cut เปลี่ยนเป็น 4+8√2≈15.3137, ขอบทแยง 180−8√2≈168.6863 ตรง catalog; พื้นที่ 7 pieces ตรง inset octagon และแก้เพดาน grid ตามขอบเดียวกัน |

ผล FIX_VERIFIED_STATIC ไม่ใช่ plan approval หรือ full runtime verification ข้อแก้อื่นจาก review ก่อนยังคงประวัติตามเดิม ไม่เพิ่ม Finding ID สำหรับปัญหาค้างใน F-05/F-06

## 3. F-05 — P1 — Geometry guard ยังปล่อยการแก้ผู้ใช้ที่ไม่เปลี่ยน direct child count

**สิ่งที่แก้แล้ว:** `restore-studio.luau:75–115` ตรวจ class, Source length แบบ exact และ SHA-256 ครบทุก script รวม CagePhysicsService แล้ว; ตรวจ PlaceId ก่อน mutation; generated artifact บนดิสก์มี preflight ใหม่แล้ว; post script payload hashes สอดคล้องกัน

**สิ่งที่ยังไม่ครบตาม HANDOFF §5:** `restore-studio.luau:118–158` และ generator `restore.ps1:357–397` ตรวจ arena เพียง Model, variant A, direct child count=95 และการมีอยู่ของ BasePart สำคัญ 6 ชิ้น Baseplate ตรวจเพียง Position/Size ยังไม่มี comparison ของ descendant tree, ชื่อ/class/path ทั้งชุด, attributes และ property values ที่ใช้ระบุ protected post-state

Static counterexamples ที่จะผ่าน guard ปัจจุบันโดย Source hashes ไม่เปลี่ยน:

- ย้าย `HexCageArena.CageFloor.CFrame` หรือเปลี่ยน Size/CanCollide ของพื้น — ยังเป็น BasePart ชื่อเดิม, variant A, direct children=95 จึงไม่ถูกตรวจ ก่อน arena ถูก Destroy
- เพิ่ม Part ภายใน `SteelCageStructure` หรือ `UrbanBackdrop` เดิม — direct child count ของ arena ไม่เพิ่ม แต่ผู้ใช้เพิ่ม descendant จริงและจะถูกลบไปพร้อม arena
- หมุน Baseplate โดยคง Position และ Size เดิม — guard ไม่ตรวจ rotation แต่ restore จะเขียน CFrame กลับและทับการเปลี่ยนนี้

นี่เป็นการอ่าน control flow ไม่ใช่การทดลองแก้ฉากผู้ใช้ระหว่าง review Negative fixtures ที่เปลี่ยน variant, เพิ่ม direct child หรือเลื่อน Baseplate ตรวจได้เฉพาะกรณีเหล่านั้น จึงยังไม่ครอบคลุม residual drift ที่ระบุข้างต้น

Post snapshot ที่ hash ตรง manifest มี `capturedAt=2026-10-20T20:48:54.217Z` และ `workspaceFixtures.HexCageArena.children` เพียง **29 รายการ** ขณะที่ฉากปัจจุบันมี **95 direct children** จึงยังไม่ใช่ expected-state inventory เต็มของ arena ปัจจุบัน การอัปเดต script hashes ไม่ทำให้ geometry payload นี้ครบโดยอัตโนมัติ

**ส่งแก้ใน F-05 เดิม:** รักษา authentic pre/; เก็บ typed post-state ปัจจุบันที่ครอบคลุมทุก protected instance/descendant ที่จะถูกลบหรือเปลี่ยน แล้วสร้าง comparison ก่อน mutation จาก inventory นี้ ตรวจ properties/attributes ที่เกี่ยวข้องและ Baseplate full CFrame ไม่ใช้ hardcoded child count เป็นตัวแทน integrity เพิ่ม isolated negative fixtures สำหรับกรณีข้างต้น โดยห้าม restore งานจริงเพื่อทดลอง รักษากลไก Source SHA-256 ที่แก้ถูกแล้ว

## 4. F-06 — P2 — หลักฐานของ generated restore และสถานะส่งมอบยังไม่ตรงจริง

**สิ่งที่แก้แล้ว:** PLAN คืน acceptance “ไม่ทะลุ/ไม่มีผิวหาย/รายงานตามขอบเขต”; comparison matrix ระบุ historical HEAD + dirty source hash unknown; TEST_READY ระบุ 141 tests และประวัติ 131→139→141; test runner hash ตรงไฟล์จริง; current Live Play/R6 ยังคง NOT VERIFIED ไม่มีการยกเลิก gates เพื่อทำให้ผ่าน

**ยังต้องแก้:**

1. fix-003:22 ระบุ generated restore hash `F5C1B69...` แต่ไฟล์จริง hash `4A8292DF...` แม้ bytes เท่ากัน ต้องอ้าง artifact ที่ทดสอบจริงให้ถูกและระบุหากไฟล์เปลี่ยนหลังผลรัน ไม่สรุป VALIDATED กับ hash คนละชุด โดยเฉพาะ negative fixtures ของ guard
2. fix-003 ส่วนสถานะและรายงานแนบระบุ agent/READ/tasks เป็น READY_FOR_REVIEW แต่ ณ รับตรวจ agent.md, docs/READ.md และหัว/turn banner ของ tasks ยัง ASSIGNED_TO_AGY ขณะที่ bullet ส่งมอบใน tasks เป็น READY_FOR_REVIEW การ sync ต้องครอบคลุม active routing ไม่ใช่เพียงบรรทัดเดียว หลัง review นี้ board ถูกส่งกลับ CHANGES_REQUESTED ไม่ใช่อนุมัติงาน
3. อย่าขยายข้ออ้าง “75/75 checks / 100% valid” ไปแทน geometry drift cases ที่ยังไม่อยู่ในการตรวจตาม F-05 แยก script/payload hash verification จาก protected geometry completeness

คำขอปรับบรรยากาศได้รับคำยืนยันโดยตรงจาก Stang ในรอบนี้แล้ว จึงบันทึกเป็น scope addendum ใน HANDOFF เดิม ไม่ต้องขออนุญาตซ้ำสำหรับงานหมอกที่ยืนยันนี้ และไม่ถือว่าคำยืนยันดังกล่าวเป็นการอนุมัติ physics/rollback/ปิดแผน

## 5. F-10 — ข้อจำกัดของ verification ที่ยังต้องรายงานตรงไปตรงมา

โค้ด builder เปลี่ยนสูตร cut/positions/sizes ของ visual pieces ให้ตรง catalog และ area test อ่าน Size ของ instances จริง จึงยืนยันข้อแก้เดิมได้ในระดับ static

อย่างไรก็ตาม TC-T2-ROOF-05 ที่ `Tier2_BoundaryCornerCases.luau:285–323` ประกาศ isInsideVisualCeiling และ constants ใน test เอง ไม่อ่าน CFrame/coverage ของ actual visual instances จึงเป็น mathematical expectation check ไม่ใช่หลักฐานอิสระว่า instances ถูกวางถูกทุกจุด รูป wedge/การมองเห็นจริงใน Variant C ยัง **NOT VERIFIED โดย Codex** ไม่ใช้ test นี้รับรอง visual 100% หากเก็บหลักฐานเพิ่มให้ตรวจตำแหน่ง/รูปทรงของ visual instances จริง ไม่มีข้อกำหนดให้ส่งภาพหรือวิดีโอ

## 6. Gates / ส่งแก้ต่อ

- V-01 source parity: ยืนยันใหม่ 4/4; geometry/math ของข้อ F-10 แก้แล้วในระดับ static
- V-06: post script payload hashes ตรง แต่ F-05 protected geometry post-state guard ยังบล็อก
- V-05: comparison artifact ที่มีเป็น historical; current controlled comparison ยังไม่มีหลักฐานใหม่ที่ผูก ref ในรอบนี้
- V-02/Live Play/R6, visual UAT และ WAN observer: ยัง NOT VERIFIED บน source ชุดนี้โดย Codex; Lighting before-state gap คงเดิม ไม่สร้างข้อมูลย้อนหลัง
- ใช้คำอนุญาต correction เดิมของ Stang สำหรับข้อค้างใน scope F-05/F-06 ไม่เพิ่ม feature/scope ไม่ขอ approval ปิดแผนจากการแก้บางข้อสำเร็จ และไม่เขียน code/รัน tests แทน AGY

## 7. Prompt ส่ง AGY

> แก้ residual F-05/P1 และ F-06/P2 ตาม assets/review-004.md ภายใต้ HANDOFF เดิมและคำอนุญาตแก้จาก Stang รักษาข้อแก้ F-10 และ script content SHA-256 เดิมที่ตรวจ static แล้ว ทำ typed post inventory ของ protected geometry ให้ตรงฉากจริงครบ descendants/properties/attributes แล้วให้ guard เทียบทั้งชุดก่อน mutation รวม Baseplate rotation เพิ่ม isolated fixtures สำหรับ moved/resized/CanCollide-changed CageFloor, nested added Part และ rotated Baseplate ห้าม restore งานจริงเพื่อทดลอง Sync payload/manifest/generated restore artifact และ hash/ผลรันในรายงานให้ตรงกันทั้งชุด แก้ routing state ให้สอดคล้อง แยก formula-only roof test จาก actual visual-instance coverage และคง unverified gates ตามจริง Stang ยืนยันคำขอหมอกแล้ว ไม่ต้องย้อนถามสิทธิ์งานหมอก ส่ง assets/fix-004.md พร้อม hashes/evidence ล่าสุดให้ Codex ตรวจซ้ำ ห้ามเพิ่ม scope ลด acceptance commit/push/merge/deploy หรืออนุมัติ/ปิดแผนเอง
