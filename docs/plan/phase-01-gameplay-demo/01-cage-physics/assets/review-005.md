# Independent re-review — Plan 01 / Fix Round 004

- วันที่: 2026-10-21 (Asia/Bangkok); Reviewer: Codex
- Technical verdict: **CHANGES_REQUESTED — คง OPEN เฉพาะ F-05/P1**
- Review board: **ESCALATED / Review 005** — F-05 ยังไม่ครบหลัง fix-003 และ fix-004 ในรอบที่เดินต่อจากคำวินิจฉัยล่าสุด ไม่ใช่การยกเลิกสิทธิ์แก้ใน scope เดิมหรืออนุมัติ/ปิดแผน
- Reviewed ref: `main` HEAD `65026668fcae9d80094841bb147f3f4dc64b0b6c` + working tree/untracked files ที่ส่ง fix-004
- Inputs: review-004, fix-004, HANDOFF §5–6, active routing docs, generated restore/generator, manifest และ typed post snapshot
- วิธีตรวจ: static review, filesystem hashes/JSON inspection, Studio Edit property readback เท่านั้น ไม่รัน tests/Play/guard/restore ไม่แก้ source หรือฉาก และไม่ commit/push/merge/deploy

## 1. หลักฐานที่ยืนยันได้

| Artifact | Actual SHA-256 |
| --- | --- |
| restore-studio.luau (93642 bytes) | `A32CD2625F0FFB770D90E40539ACAAF0BB2EA28F0C41A9AEB15398A1DCE9674D` |
| post/studio/studio-post-state.json (2550727 bytes) | `1F8CD86447A1F1F1946FDDCDF028BA29AE3F7AFBF6109BE821EA38DC1BACC7F1` |
| src/server/services/CagePhysicsService.luau | `09B564258699F4CF3BE76483EE9D819D610A7F47A69A3F977D1F0E40E0F7D7AB` |
| tests/e2e/BundledTestRunner.luau | `9BD24D9E2836C37D49CCBB9F8A0B48B41C429AB0AF03C54F84B874E3BFB8291B` |

Generated restore และ snapshot hashes ตรง fix-004 และ snapshot hash ตรง manifest ปัญหา hash ผิดของ generated restore รอบก่อนแก้แล้ว Source allowlist 4 ไฟล์และ test runner มี local hashes เท่าเดิมจาก review-004 จึงตรวจเฉพาะ delta ของ guard/snapshot/docs รอบนี้ **ไม่ได้ทำ fresh Studio Source SHA-256 parity ทั้งชุดซ้ำ**

Manifest entries 10 รายการ: local files, post/files และ post/studio/scripts ตรง expected hashes ทั้งหมด ตรวจ JSON recursive พบ **95 direct children / 1204 descendants** พร้อม capturedAt=`2026-10-21T08:10:06.708Z` เป็น post inventory ใหม่ แก้ snapshot เก่า 29 children แล้ว

Studio ที่อ่านสด: PlaceId `137721422246269`, studio_id `5331d36b-4ba7-4726-9bfe-4e853359c9d6`, Mode Edit, variant A, 95 direct children / 1204 descendants, SteelCageStructure 790 descendants, UrbanBackdrop 235 descendants และ CageFloor 84 children ตรงจำนวนใน snapshot/report ตัวอย่างผนัง Wall_North_Left มี Position=(-46,16,-121), Size=(68,32,2)

141/141 tests, 445 assertions, 75/75 bundle checks และ negative fixtures 6/6 เป็น **ผลที่ AGY รายงาน** Codex ไม่ได้รันซ้ำ การตรวจ snapshot counts/hash ไม่ใช่การรับรองว่าทุก property ใน snapshot ตรง live scene หรือ guard ครอบคลุมทั้งหมด

## 2. ผลตรวจ Finding IDs

| ID | ผลตรวจ |
| --- | --- |
| F-06 / P2 | **FIX_VERIFIED_STATIC** — generated restore hash ตรงไฟล์จริง; routing ณ ส่งงานเป็น READY_FOR_REVIEW/Turn REVIEWER สอดคล้องกัน และจำแนก bundle checks/geometry fixtures/unverified gates แล้ว |
| F-05 / P1 | **PARTIAL / OPEN** — snapshot ครบและ concrete counterexamples รอบก่อนถูกเพิ่ม checks แต่ guard ยังไม่ใช้ snapshot เพื่อเทียบ descendant properties/attributes ทั้งชุด |

ไม่เพิ่ม Finding ID ใหม่ เพราะข้อค้างเป็น F-05 เดิมตาม HANDOFF §5 ที่กำหนด class/path/descendants/properties/attributes ของ protected post-state ไม่ใช่การเพิ่ม scope หรือขอ feature ใหม่ การยืนยัน F-06 เป็นผลตรวจข้อแก้ ไม่ใช่ Owner approval หรือ sign-off ปิดแผน

## 3. F-05 — P1 — เพิ่ม hardcoded checks แต่ยังไม่มี recursive post-state comparison

**สิ่งที่แก้แล้ว:** บันทึก post tree ครบ 1204 descendants; floor Position/Size/CanCollide/Anchored/rotation; counts ของ nested folders; boundary positions บางแกน; Baseplate full rotation และ generated script ที่ตรง hash ข้อแก้เหล่านี้ครอบคลุม fixtures ที่รายงานทั้ง 6 กรณีจากการอ่าน code paths

**ส่วนที่ยังไม่ครบ:** `restore-studio.luau:118–300` และ generator ใน restore.ps1 ยังตรวจ summary/counts กับ named conditions ที่เลือกไว้เอง ไม่โหลด/ฝัง expected post inventory แล้วเทียบ recursively

- :180–198 ตรวจ SteelCageStructure/UrbanBackdrop เพียง class ของ Folder และ descendant counts ไม่ตรวจชื่อ/class/path/attributes/properties ของ descendants แต่ละตัว
- :201–236 ตรวจผนังเฉพาะ CanCollide และตำแหน่ง X หรือ Z บางแกน ไม่ตรวจ Size, full CFrame หรือ attributes ตาม snapshot
- :239–268 ตาราง 95 direct children มีเพียงชื่อ และใช้ FindFirstChild ตรวจว่ามีอยู่ ไม่เทียบ class/state ของแต่ละรายการตามที่รายงานอ้าง

**Static counterexamples ที่จะยังผ่านโดยไม่มี Source/hash หรือ counts เปลี่ยน:**

1. เปลี่ยน `Wall_North_Left.Size.X` จาก 68 เป็น 67 โดยคง Position.Z=-121 และ CanCollide=true — boundary branch ผ่าน และทุก count/name เท่าเดิม
2. ย้าย/หมุนคานหรือเสาเดิมภายใน SteelCageStructure หรือแก้ property ของอาคารเดิมใน UrbanBackdrop — folder/total counts ไม่เปลี่ยน และไม่มีการเทียบ properties ของชิ้นนั้น ก่อนถูกลบพร้อม arena
3. เปลี่ยนชื่อหรือแทนที่ nested Part หนึ่งชิ้นด้วยอีกชิ้น โดยคงจำนวนเท่าเดิม — direct list/count และ folder counts ยังเท่าเดิม ไม่มี path/class comparison ของ nested nodes

นี่เป็นผลจากการอ่าน control flow ไม่ใช่การทดลอง mutate ฉากผู้ใช้ระหว่าง review หากเรียก restore หลังการเปลี่ยนเช่นนี้ guard ปัจจุบันจะไม่พบความต่าง แล้ว `arena:Destroy()` ยังลบงานผู้ใช้ได้ นี่คือ failure mode เดิมของ F-05 การผ่าน 6 fixture cases ไม่พิสูจน์ protection ของ post-state ทั้งชุด

### Correction contract ที่ต้องทำให้ครบ

ไม่ควรแก้ด้วยการเพิ่ม if สำหรับตัวอย่างข้างบนทีละข้อ ให้ใช้ typed post inventory ที่มีแล้วเป็น expected data สำหรับ **generic recursive comparator** ใน generated preflight:

1. เทียบ tree ของ protected roots แบบ exact inventory: ชื่อ/class/path, membership และ attributes ของแต่ละ node พร้อมตรวจ missing/extra/replaced nodes ไม่ใช้ count เท่ากันเป็นเงื่อนไขเพียงอย่างเดียว
2. เทียบทุก property ที่บันทึกและอยู่ในสัญญาของ protected node นั้น โดยใช้ type-aware comparison และ tolerance ที่ระบุชัดสำหรับ numeric/CFrame data; รวม full CFrame/Size/collision state ของทุก BasePart และ attributes map ไม่ใช่เฉพาะ floor หรือผนังบางแกน
3. ให้ generator ฝัง/อ้าง immutable expected post data ที่ผูกกับ manifest และ generated artifact hash ก่อนใช้งาน ตรวจ protected set ทั้งหมดก่อน mutation แรก รักษา Source SHA-256 checks และ pre/ ที่ถูกต้องแล้ว
4. AGY ทดสอบ generic comparator บน isolated fixtures แบบเปลี่ยนหนึ่ง property ของ descendant ที่ไม่ใช่ hardcoded key part, เปลี่ยนชื่อ/class หรือแทนที่ node แบบ count เท่าเดิม และ unmodified fixture ต้องผ่าน โดยไม่ restore ฉากจริงเพื่อทดสอบ
5. Sync manifest/post payload/generated restore/evidence และรายงานด้วย hashes ที่ส่งจริง ไม่เปลี่ยน acceptance ให้เป็นเพียงการผ่านรายชื่อ fixtures

แนวทางนี้อยู่ใน F-05/HANDOFF §5 เดิม ไม่เปลี่ยน geometry gameplay, PRD/TDD/CONTEXT หรือเพิ่มระบบนอกแผน การเขียน snapshot ครบแล้วช่วยให้ทำ comparison นี้ได้โดยไม่ต้องแต่ง expected state ใหม่จากค่าที่เดา

## 4. Gate status / escalation

- V-06 ยังบล็อกที่ F-05 แม้ artifact hashes และ post inventory counts แก้แล้ว
- F-06 แก้ได้ตาม §2; ไม่เปลี่ยนผล review-004 ย้อนหลัง
- V-02/Live Play/R6, actual Variant C visual coverage และ WAN observer ยัง NOT VERIFIED ตามขอบเขตที่รายงาน; V-05 current comparison ยังไม่มี evidence ใหม่ที่ตรวจในรอบนี้; Lighting before-state gap คงเดิม
- ไม่มี source diff นอก allowlist หรือ PRD/TDD/architecture/spec diff เพิ่มจาก Git baseline นี้

F-05 ยังต้องส่งกลับหลัง fix-003 และ fix-004 หลังคำวินิจฉัยให้เดินต่อครั้งล่าสุด จึงบันทึก **ESCALATED** ตาม [stang-luna SKILL.md](C:/Users/Stang/.codex/skills/stang-luna/SKILL.md:56) และ R02 ที่ระบุให้หยุด automatic ping-pong เมื่อข้อเดิม “ถูกตีกลับซ้ำ 2 รอบติดต่อกัน” รอบนี้เป็นการแจ้งปัญหาวิธี implementation ให้ Stang เห็นอย่างเป็นรูปธรรม ไม่ใช่ขอสิทธิ์แก้ scope เดิมใหม่หรืออนุญาต Codex ลงมือแทน AGY ไม่มีการ dispatch agent/แก้อัตโนมัติในรอบตรวจนี้

## 5. ข้อความส่ง AGY สำหรับแก้แนวทางภายใต้คำอนุญาตเดิม

> ตรวจ assets/review-005.md แล้วแก้ F-05 เดิมโดยเปลี่ยนจาก hardcoded counts/if checks เป็น generic recursive comparator ที่เทียบ protected live tree กับ typed post inventory จริงครบชื่อ/class/path/attributes/properties ก่อน mutation แรก อย่าเพิ่มเฉพาะ if สำหรับ counterexamples ทีละข้อ รักษา Source hash guard, authentic pre/, source/gameplay และข้อแก้ F-06 ที่ตรวจ static แล้ว ใช้ isolated negative fixtures สำหรับ arbitrary nested property edit และ same-count rename/class replacement รวม unmodified fixture ต้องผ่าน ห้าม restore ฉากจริงเพื่อทดลอง Sync generated artifact/manifest/evidence ให้ตรง hashes ที่ส่งจริง บันทึก assets/fix-005.md และส่ง working tree ให้ Codex ตรวจซ้ำ ไม่เพิ่ม scope ลด acceptance commit/push/merge/deploy หรืออนุมัติ/ปิดแผนเอง
