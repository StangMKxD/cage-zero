# Target Delta Report 002 — Correction Report for Review 004 (RF-F07 & RF-F08)

- **Document:** Delta Report 002 (Fix Report for Review 004)
- **Date:** 2026-10-25
- **Task / State:** READY_FOR_REVIEW (Documentation Synchronized; Runtime Implementation NOT AUTHORIZED)
- **Controller / Reviewer:** Codex (last known `w2:p43`)
- **Implementer:** agyplan (`w2:p49`)
- **Review Target:** [Review 004](review-004.md) — Verdict: `CHANGES_REQUESTED` (จำกัดเฉพาะการแก้ไขเอกสารทางเทคนิค 2 ข้อ: RF-F07 และ RF-F08)
- **Historical Baseline & Reviews:**
  - [Review 003](review-003.md) — รับรองข้อค้นพบเดิม RF-F01..RF-F06 เป็นประวัติศาสตร์ที่ผ่านการตรวจสอบแล้ว
  - [Delta Report 001](delta-001.md) — รายงานตั้งต้นของการปรับ Target สู่ Player Avatar R15
  - รายงานฉบับนี้จัดทำขึ้นเพื่อแก้ไขข้อบกพร่องตาม [Review 004](review-004.md) อย่างตรงจุด โดยไม่มีการขยายขอบเขต ไม่แก้ไข source, tests, Studio, หรือ Git และไม่แตะต้องไฟล์ที่ Codex ถือสิทธิ์
- **Git Baseline & Ref:** HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + working tree documentation updates (Zero code/test mutations)

---

## 1. Resolution of Review 004 Findings

### 1.1 RF-F07 — CLOSED: Avatar API Vocabulary Conflated
- **ปัญหาเดิม:** เอกสารเดิมใน `RF-02/notes.md` §5.1 เรียก `BodyHeightScale`, `BodyWidthScale`, `BodyDepthScale` ว่าเป็น property ของ `HumanoidDescription` และใน `RF-02/tasks.md` มีการอ้างถึง `ApplyDescriptionReset` ซึ่งไม่ใช่ API มาตรฐาน
- **การแก้ไขในรอบนี้:**
  1. **แยกแยะ API Targets อย่างเด็ดขาด:**
     - ระบุชัดเจนว่าคุณสมบัติสเกลของ [`HumanoidDescription`](https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription) ใน Roblox R15 คือ `HeightScale`, `WidthScale`, `DepthScale`, `HeadScale`, `ProportionScale`, และ `BodyTypeScale` (ไม่มีคำนำหน้า `Body` ยกเว้น `BodyTypeScale`)
     - ระบุชัดเจนว่าอินสแตนซ์ที่มีคำนำหน้า `Body` ได้แก่ `BodyHeightScale`, `BodyWidthScale`, `BodyDepthScale`, `BodyProportionScale`, `BodyTypeScale` (รวมถึง `HeadScale`) เป็นอินสแตนซ์ประเภท `NumberValue` ที่เป็น **ลูก (Children) ของ [`Humanoid`](https://create.roblox.com/docs/reference/engine/classes/Humanoid)** โดยตรง
     - กำหนดข้อห้ามเชิงเทคนิค: ผู้พัฒนาระบบ (Worker) ต้องไม่พยายามเข้าถึงหรือกำหนดค่า `HumanoidDescription.BodyHeightScale` เพราะจะเกิด runtime error
  2. **ปรับปรุง API การโหลดโมเดลเป็นมาตรฐานสากล:**
     - ใน `RF-02/tasks.md` Task 2.2 ตัดการอ้างถึง `ApplyDescriptionReset` และปรับเป็น API สากลที่เอกสารรับรอง เช่น `Humanoid:ApplyDescriptionAsync(description)` หรือกำหนดเป็นกระบวนการกลาง (Humanoid description application pipeline)
  3. **แนบลิงก์เอกสารอ้างอิงหลัก:**
     - [`HumanoidDescription`](https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription)
     - [`Humanoid`](https://create.roblox.com/docs/reference/engine/classes/Humanoid)
- **ไฟล์ที่ได้รับการแก้ไข:**
  - [`RF-02/notes.md`](../RF-02/notes.md) (หัวข้อ 5.1 ข้อ 1)
  - [`RF-02/tasks.md`](../RF-02/tasks.md) (Task 2.2)
  - [`RF-02/plan.md`](../RF-02/plan.md) (หัวข้อ DELTA ข้อ 1)
  - [`release-first/plan.md`](../plan.md) (หัวข้อ 1 ข้อ 8)

---

### 1.2 RF-F08 — CLOSED: Appearance Readiness Contract & Safety Invariant
- **ปัญหาเดิม:** เอกสารเดิมกำหนดเพียงการรอรับฟังอีเวนต์ `Player.CharacterAppearanceLoaded` ซึ่งมีความเสี่ยงที่จะพลาดการตรวจจับหากตัวละครโหลดรูปลักษณ์เสร็จสิ้นไปแล้วก่อนเริ่ม Subscribe (Already-loaded character) ขาดการติดตาม generation token และไม่ได้ระบุกฎความปลอดภัยกรณีเกิด timeout
- **การแก้ไขในรอบนี้:**
  1. **กลไกตรวจสอบคู่ขนาน (Dual-Path Readiness Check + Event):**
     - ตรวจสอบสถานะความพร้อมทันทีผ่าน [`Player:HasAppearanceLoaded()`](https://create.roblox.com/docs/reference/engine/classes/Player#HasAppearanceLoaded) เมื่อเชื่อมต่อตัวละคร เพื่อรองรับกรณี Already-loaded character
     - ควบคู่กับการรับฟังอีเวนต์ [`Player.CharacterAppearanceLoaded`](https://create.roblox.com/docs/reference/engine/classes/Player#CharacterAppearanceLoaded) สำหรับกรณีที่รูปลักษณ์ยังโหลดไม่เสร็จ
  2. **Current-Character Generation Tracking:**
     - กำหนดให้ระบบสร้าง Generation Token / Spawn ID กำกับทุกครั้งที่ตัวละครเกิด เพื่อตรวจสอบว่า callback แบบ asynchronous เป็นของตัวละครปัจจุบันหรือไม่ หากตัวละครตายหรือถูกแทนที่ (Respawned / Replaced) ให้ทิ้ง (discard) callback ที่ล้าสมัยทันที
  3. **Cleanup on Respawn & Disconnect:**
     - กำหนดการเชื่อมต่ออีเวนต์ `CharacterRemoving` และ `PlayerRemoving` เพื่อยกเลิก connection ทำลาย token และเคลียร์วัตถุชั่วคราว
  4. **Idempotent Normalization Pipeline:**
     - กำหนดให้ฟังก์ชันการ Normalize มีคุณสมบัติ Idempotent การเรียกซ้ำบนตัวละครเดิมต้องไม่ทำให้เกิดการเพิ่ม Attachment ซ้ำซ้อน หรือสเกลผิดเพี้ยน
  5. **Preserve Player Visual Identity While Pending:**
     - รักษารูปลักษณ์และเครื่องแต่งกายส่วนตัวของผู้เล่นไว้ตามปกติในระหว่างที่รอการตรวจสอบ
  6. **Critical Safety Invariant (กฎความปลอดภัยเด็ดขาด):**
     - ระบุชัดเจนว่า **หากเกิดกรณี Timeout หรือข้อผิดพลาดในการโหลด/Normalize ระบบต้องไม่ปล่อยให้ตัวละครที่ไม่ผ่านการ Normalize เข้าสู่เกมเพลย์โดยเด็ดขาด (Never silently grant gameplay to an unnormalized character on timeout)**
     - ตัวละครที่ติดปัญหาต้องถูกกักให้อยู่ในสถานะ Non-gameplay (เช่น Loading State / Spectator หรือใช้ Fallback Neutral Rig ชั่วคราว) จนกว่าการตรวจสอบ Hitbox/Geometry จะผ่านการรับรอง
  7. **แนบลิงก์เอกสารอ้างอิงหลัก:**
     - [`Player`](https://create.roblox.com/docs/reference/engine/classes/Player) (หัวข้อ `HasAppearanceLoaded` และ `CharacterAppearanceLoaded`)
- **ไฟล์ที่ได้รับการแก้ไข:**
  - [`RF-02/notes.md`](../RF-02/notes.md) (หัวข้อ 5.1 ข้อ 6)
  - [`RF-02/tasks.md`](../RF-02/tasks.md) (Task 2.2)
  - [`RF-02/plan.md`](../RF-02/plan.md) (หัวข้อ DELTA ข้อ 1)
  - [`release-first/plan.md`](../plan.md) (หัวข้อ 1 ข้อ 8)

---

## 2. Scope of File Modifications in this Fix Round

การแก้ไขในรอบนี้จำกัดเฉพาะเอกสาร Active 4 ไฟล์ที่ agyplan ถือครอง และการจัดทำรายงานฉบับนี้:

1. `docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md` — แก้ไขข้อ RF-F07 (แยกแยะ HumanoidDescription scale properties vs Humanoid child NumberValues) และข้อ RF-F08 (Dual-path appearance check, Generation tracking, Cleanup, และ Timeout safety invariant)
2. `docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md` — แก้ไข Task 2.2 ปรับเป็น API สากล `ApplyDescriptionAsync` และบรรจุเงื่อนไขความปลอดภัย RF-F07/RF-F08
3. `docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md` — ปรับปรุง DELTA ข้อ 1 ให้สอดคล้องกับสัญญาความพร้อมของรูปลักษณ์และ API สเกล
4. `docs/plan/phase-01-gameplay-demo/release-first/plan.md` — ปรับปรุงสรุป Seams ข้อ 8 ให้สอดคล้องกับข้อกำหนดความปลอดภัยและการแยกแยะ API
5. `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-002.md` — รายงานฉบับนี้

*(ไม่มีการแตะต้องซอร์สโค้ดใน `src/`, ชุดทดสอบใน `tests/`, Roblox Studio, หรือ Git แต่อย่างใด)*

---

## 3. Verification Evidence

### 3.1 Zero Code / Test Mutations Check
```powershell
Set-Location C:\Users\Stang\cage-zero
git diff HEAD -- src tests
# ผลลัพธ์: ว่างเปล่า (Empty Output) — ยืนยันว่าไม่มีการแตะต้อง source หรือ tests
```

### 3.2 Relative Links & Heading Anchors Audit
รันสคริปต์ตรวจสอบความถูกต้องของ Relative Links และ Heading Anchors ในโฟลเดอร์ `docs/plan/phase-01-gameplay-demo/release-first`:
```text
Found 30 markdown files under release-first
Verified 97 relative links & anchors.
SUCCESS: All relative links and anchors are valid and resolved!
```

---

## 4. Complete Hash Coverage (All 21 Active & Deliverable Files)

เพื่อตอบสนองข้อสังเกตของ Review 004 เรื่องความครอบคลุมของตารางแฮช ตารางด้านล่างแสดงค่า SHA256 ปัจจุบันของไฟล์เอกสารทั้งหมด 21 ไฟล์ที่อยู่ในขอบเขตความรับผิดชอบของ agyplan:

| ลำดับ | ไฟล์เอกสาร | ขนาด (ไบต์) | SHA256 Hash |
|:---:|:---|:---:|:---|
| 1 | `agent.md` | 12,588 | `fcb183f18ed2641102cbd5d07d6d03f452370db6f81a48a26258c992eaa7f46a` |
| 2 | `docs/READ.md` | 5,182 | `9dab5c938db7e945c65e1101259e1cdf90987f0fb548273cefebf0b59c5ba077` |
| 3 | `docs/prd/product-requirements.md` | 10,843 | `8a16eb48d246dc33fa4910884f31e73681f85d54e21b40c69ecccb29d0e4410f` |
| 4 | `docs/tdd/master-test-cases.md` | 32,829 | `da60572290fc6f99b219d3d7340e93b03820baa3c54c413ed0424d353e910576` |
| 5 | `docs/specs/spec-02-duel-and-parry.md` | 23,149 | `0ec171c0ff0d5784291ee53a99e9dd0b740d6ea4bc29440e1ffce0962f79ba00` |
| 6 | `docs/specs/spec-03-cards-rig-freekick.md` | 10,480 | `f5b6c7c69643ee9255e8fa8899d292f0c33da56ebca278090e762d3a69de46e8` |
| 7 | `docs/design/architecture-and-network.md` | 44,269 | `e2f9034792a6b41f13fd9ba2c9106dfc5b3e23000fe780ff3c75e9dbf9f65a54` |
| 8 | `docs/plan/roadmap.md` | 9,506 | `065e923ef82e606f04883237af31169b556c72e7241f6bca3b92c404c67de39b` |
| 9 | `docs/plan/phase-01-gameplay-demo/plan.md` | 11,802 | `6356d8e65de172a3fb03d8817f212b1d611b654bed37ac29c9d8f26182572964` |
| 10 | `docs/plan/phase-01-gameplay-demo/release-first/plan.md` | 21,265 | `3461bf79b120d2e690b2b2e00e8d5fb2e1067c5f46dc74ab586e0b270add5b17` |
| 11 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md` | 22,739 | `3973aeee91579ec529315f3582149f6b23edff50a757284e88cbc67c7f40ea4b` |
| 12 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md` | 19,464 | `9afec0ea116bc3937f64093f25d7c757f247c5a30a1dee7b8ede821e2b1fd7e4` |
| 13 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md` | 32,127 | `968b81ff56b44c66ce2e81a8fd89b991bb219fee9347db43913a9f7c8d338e4c` |
| 14 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/plan.md` | 9,160 | `6a0acc990853f4cdf396a3d9e098ce1e66de2cf988011d7773ef9d1390b9cd45` |
| 15 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/tasks.md` | 4,326 | `e56035cacfc7441e1c46126395779a55d632b80263cd3e93a9c0261d934e00cb` |
| 16 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/notes.md` | 4,956 | `92226e0f948eb861ad48b2ab078e5a54ac75749097e4b022a8754438ea6e4b83` |
| 17 | `docs/plan/phase-01-gameplay-demo/release-first/RF-04/plan.md` | 6,763 | `0be60443ff45c14740fbccbead1e968f08e0a9a0882d13a001917c3985785082` |
| 18 | `docs/plan/phase-01-gameplay-demo/release-first/RF-05/plan.md` | 10,134 | `0c0eeb56b8d36410445d49c57bc91676815a90392d7020abac0b9b54c92ef364` |
| 19 | `docs/plan/phase-01-gameplay-demo/release-first/RF-06/plan.md` | 6,815 | `a978c56ab49968dee8697c667e05cb90a576ae93e6cf31c83a197cf0d524960c` |
| 20 | `docs/plan/phase-01-gameplay-demo/release-first/RF-07/plan.md` | 6,814 | `689969a2b1bc6cb3d60ba1b628d87e5bd95d6a16bb7b4ba6c212cb1c997a9f16` |
| 21 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-001.md` | 22,456 | `87d73831e55d9da42ac0c0b3d30d19e2b81b0a37163151fef5b4d547c761ba56` |
| 22 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-002.md` | (This Document) | (Self-referential deliverable report) |

---

## 5. Unresolved Items & Scope Preserved

1. **Empirical Studio Validation:** การประเมินความเข้ากันได้ของ Body Packages ใน Studio ยังคงเป็นงานในขั้นตอนถัดไป ไม่มีการเดาผลลัพธ์
2. **BodyCheck Launch Inclusion:** สถานะของ Body Check (รวมใน Launch หรือเลื่อนไป Phase 2) ยังคงเป็น **PENDING Owner Decision**
3. **Duplicate Character Policy:** นโยบายการจัดการตัวซ้ำจากการสุ่มยังคงเป็น **PENDING Owner Decision**

---

## 6. Next Action & Reporting

- **สถานะ:** `READY_FOR_REVIEW` (การแก้ไข RF-F07 และ RF-F08 เสร็จสมบูรณ์)
- **การส่งต่อ:** ส่ง Push Callback ไปยัง verified Codex Controller (`w2:p43`) พร้อมกด `Enter` ตาม Latest Owner Reporting Override เพื่อรอการตรวจสอบอิสระจาก Codex (Review 005 หรือผลตรวจรับ) ต่อไป