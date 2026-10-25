# Target Delta Report 001 — Player Avatar R15 Normalization & Reporting Override

- **Document:** Delta Report 001
- **Date:** 2026-10-25
- **Task / State:** READY_FOR_REVIEW (Documentation Synchronized; Runtime Implementation NOT AUTHORIZED)
- **Controller / Reviewer:** Codex (last known `w2:p43`)
- **Implementer:** agyplan (`w2:p49`)
- **Predecessor Review:** [Review 003](review-003.md) — Verdict: `VERIFIED` สำหรับการแก้ไขเอกสารข้อค้นพบ RF-F01..RF-F06 รอบก่อนหน้า รายงานฉบับนี้จัดทำขึ้นเพื่อรายงานผลการปรับปรุงเอกสารตาม **Owner Target Delta (2026-10-25)** และ **Latest Owner Reporting Override (2026-10-25)** ที่ประกาศเพิ่มเติม
- **Git Baseline & Ref:** HEAD `25a67d5575e31034a5a08290873b9c401357d33a` (ไม่มีการแก้ไข source หรือ tests; ทำการแก้ไขเฉพาะเอกสารที่ agyplan เป็นเจ้าของใน `agent.md` และ `docs/`)

---

## 1. Executive Summary & Directives Covered

สืบเนื่องจากคำสั่งการล่าสุดของ Owner เมื่อวันที่ 2026-10-25 ทางทีม Implementer (agyplan) ได้ดำเนินการปรับปรุงเอกสาร active ทั้งหมดที่อยู่ในขอบเขตความรับผิดชอบให้สอดคล้องกับ 2 คำสั่งสำคัญ ดังนี้:

1. **Owner Target Delta — Player Avatar R15 (Normalized to Same Body Dimensions):**
   - บันทึกการเปลี่ยน Target Rig จากเดิมที่เป็น Game-owned Custom Blocky R15 มาเป็น **Player Avatar R15 (Normalized to Same Body Dimensions)**
   - ผู้เล่นจะใช้โมเดล Avatar ส่วนตัวของตนเองลงเล่นในสนาม โดยระบบจะทำการ Normalize มิติร่างกายและสัดส่วนทางกายภาพให้มีขนาดเท่ากันทั้งหมดทุกผู้เล่น เพื่อรักษาความยุติธรรมในการแข่งขันฟุตบอล
   - บันทึกข้อจำกัดเชิงเทคนิคและ Seams ที่สำคัญ โดยเฉพาะข้อเท็จจริงที่ว่า **Scale numbers ใน `HumanoidDescription` เท่ากัน ไม่ได้รับประกันขนาดทางกายภาพจริงของ arbitrary body packages**
   - ยืนยันกฎเหล็ก: **Character Stats (13 ค่า) และ Character Cards ไม่เปลี่ยนแปลงขนาดร่างกายของผู้เล่น** (ขนาดร่างกายเท่ากันเสมอ; ค่า Scale ในอดีต เช่น Messi 0.92, Haaland 1.08 เป็นเพียงเอกสารอ้างอิงทางประวัติศาสตร์)
   - ไม่มีการเคลมว่า Review 003 รับรอง Target Delta นี้ (คงผล Review 003 ไว้เป็นประวัติศาสตร์ที่รับรอง RF-F01..06)

2. **Latest Owner Reporting Override:**
   - ปรับปรุงข้อกำหนดการรายงานในเอกสารที่ agyplan ถือครอง ให้เป็นไปตามคำสั่งล่าสุดของ Owner:
   - Implementer ส่ง **Push Callback อัตโนมัติ** ไปยัง verified Codex Controller (`w2:p43`) พร้อมกด `Enter` ทันทีเมื่อเข้าสู่สถานะ `READY_FOR_REVIEW`, `BLOCKED`, หรือต้องการ Owner decision โดย **ไม่ต้องรอ Owner ตรวจสอบใน pane หรือสั่ง SEND REPORT อีกต่อไป**
   - กำหนดให้ส่ง 1 รายงานต่อ 1 Milestone (ไม่ส่งทุก tool call, ไม่เกิด retry loop, ไม่ ping-pong อัตโนมัติ)
   - Codex ไม่ต้องทำหน้าที่ poll, wait-loop หรือเฝ้าอ่าน pane ซ้ำ (No monitoring)
   - หากไม่พบ pane ปลายทาง ให้เก็บรายงานไว้ใน repo แล้วแจ้ง delivery blocker

---

## 2. Changed Files Inventory (Docs-Only Allowlist)

การแก้ไขทั้งหมดจำกัดอยู่เฉพาะไฟล์เอกสารที่ agyplan เป็นเจ้าของ โดย **ไม่มีการแตะต้องไฟล์ที่ Codex ถือสิทธิ์** (`owner-r15-restart.md`, `legacy-plan02-removal.md`, `HANDOFF.md`, `review-001..003.md`, `completion-report.md`, `fix-001..002.md`, และ 6 ไฟล์ของ legacy 02/03) และ **ไม่มีการแตะต้อง `src/` หรือ `tests/` โดยเด็ดขาด**:

| ลำดับ | ไฟล์ที่แก้ไข | ขอบเขตการแก้ไข |
|:---:|:---|:---|
| 1 | [`agent.md`](../../../../../agent.md) | อัปเดต LATEST DISPATCH, TARGET_RIG เป็น Player Avatar R15 Normalized, กฎข้อ 4 และ 7 (Push callback override ไม่ต้องรอ SEND REPORT) |
| 2 | [`docs/READ.md`](../../../../READ.md) | อัปเดต Target Rig บรรทัดที่ 3 เป็น Player Avatar R15 Normalized |
| 3 | [`docs/prd/product-requirements.md`](../../../../prd/product-requirements.md) | อัปเดต Header และตาราง Rig เป็น Player Avatar R15 Normalized, Q6 control mapping, และ Decoupling stats/cards |
| 4 | [`docs/tdd/master-test-cases.md`](../../../../tdd/master-test-cases.md) | ปรับปรุง `[INV-02]` และ `[TC-RF02-01]` ให้ตรวจสอบ Player Avatar R15 Normalization, Attachment calibration, และ Accessory collision |
| 5 | [`docs/specs/spec-02-duel-and-parry.md`](../../../../specs/spec-02-duel-and-parry.md) | อัปเดตแบนเนอร์เป็น Player Avatar R15 Equal Size |
| 6 | [`docs/specs/spec-03-cards-rig-freekick.md`](../../../../specs/spec-03-cards-rig-freekick.md) | ปรับข้อกำหนด Rig แทนที่ข้อห้ามเดิม, บันทึก Scale numbers vs actual dimensions seam, และระบุว่า Stats/Cards ไม่ขยาย/หดตัวละคร |
| 7 | [`docs/design/architecture-and-network.md`](../../../../design/architecture-and-network.md) | อัปเดตแบนเนอร์ Target Rig เป็น Player Avatar R15 Normalized |
| 8 | [`docs/plan/roadmap.md`](../../../roadmap.md) | อัปเดตเป้าหมาย Phase 1 Release-First เป็น Player Avatar R15 Equal Size |
| 9 | [`docs/plan/phase-01-gameplay-demo/plan.md`](../../plan.md) | อัปเดต Active Target เป็น Player Avatar R15 Equal Size |
| 10 | [`docs/plan/phase-01-gameplay-demo/release-first/plan.md`](../plan.md) | อัปเดต Title, Target Rig, ข้อ 4 & 7 (Reporting override), ข้อ 8 (Technical seams), แผนภาพ Mermaid, และ DoD |
| 11 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md`](../RF-02/plan.md) | อัปเดต Target Rig, Context, TARGET section (Normalization, Scale numbers seam, stats/cards independent) และ Acceptance |
| 12 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md`](../RF-02/tasks.md) | ปรับ Task 2.2 เป็น Player Avatar R15 Normalization Pipeline & Attachment Calibration, Task 2.4 Retargeting, Task 2.12 Visual acceptance |
| 13 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md`](../RF-02/notes.md) | อัปเดตกฎการรายงาน และเพิ่ม Section 5: Player Avatar R15 Normalization Seams & Unresolved Details ครอบคลุม 9 มิติทางเทคนิค |
| 14 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-03/plan.md`](../RF-03/plan.md) | อัปเดต Target Rig, Context, DELTA, และ Contact frame synchronization บน Player Avatar R15 |
| 15 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-03/tasks.md`](../RF-03/tasks.md) | ปรับปรุง Phase B Tasks (Heavy Knock-On, Open Up Fake Shot, Body Feint) สำหรับ Player Avatar R15 และ Contact frame sync |
| 16 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-03/notes.md`](../RF-03/notes.md) | เพิ่มบันทึกการปรับใช้ Player Avatar R15 Normalized กับ Skill Moves และ Contact frame synchronization |
| 17 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-04/plan.md`](../RF-04/plan.md) | ปรับปรุงระบบ Wall Run และ Wall Launch ให้ระบุการทำงานบน Player Avatar R15 Normalized |
| 18 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-05/plan.md`](../RF-05/plan.md) | ระบุชัดเจนว่าสถิติตัวละครทั้ง 13 ค่า และ Character Cards ไม่เปลี่ยนแปลงขนาดทางกายภาพหรือมิติร่างกายของ Avatar ผู้เล่น |
| 19 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-06/plan.md`](../RF-06/plan.md) | เพิ่มข้อกำหนด Team Readability Indicator / Virtual Jersey Overlay ใน Concise HUD และ Acceptance Criteria สำหรับแมตช์ 2v2 |
| 20 | [`docs/plan/phase-01-gameplay-demo/release-first/assets/delta-001.md`](delta-001.md) | จัดทำรายงานสรุปการแก้ไข Target Delta ฉบับนี้ |

---

## 3. Technical Seams & Unresolved Details Analysis

การเปลี่ยนผ่านสู่ Player Avatar R15 (Normalized to Same Body Dimensions) มีผลกระทบทางเทคนิคที่ต้องบันทึกเป็นลายลักษณ์อักษรอย่างรอบคอบ ดังนี้:

### 3.1 Scale Numbers vs Physical Dimensions Seam
- ในแพลตฟอร์ม Roblox กลไก `HumanoidDescription` รองรับการปรับค่า Scale ได้แก่ `BodyHeightScale`, `BodyWidthScale`, `BodyDepthScale`, และ `HeadScale`
- **ข้อจำกัดเชิงเทคนิค:** การตั้งค่าตัวเลขสเกลเหล่านี้ให้มีค่าเท่ากัน (เช่น 1.0) **ไม่ได้รับประกันว่าขนาดทางกายภาพจริง (Physical Bounding Box / Extents) จะเท่ากัน** เมื่อผู้เล่นสวมใส่ Body Packages ที่มีสัดส่วนต่างกัน (เช่น Classic Blocky, Man, Woman, Boy, Rthro, หรือ Custom Anime Packages)
- ด้วยเหตุนี้ แผนงานจึงระบุให้ต้องมีขั้นตอน Normalization Pipeline ที่วัดขนาด Extents และทำการ Clamp หรือปรับ Scale เชิงฟิสิกส์ให้ Hitbox ทุกตัวละครมีขนาดเท่ากันอย่างแท้จริง

### 3.2 Body Packages Normalization & Permitted Parts (Unresolved Details)
- **ประเด็นที่ยังต้องทดสอบจริง (Unresolved):** การตัดสินใจว่าระบบจะรองรับ Arbitrary Body Packages ทั้งหมดของ Roblox แล้วใช้วิธี Clamp Bounding Box หรือจะจำกัดเฉพาะชิ้นส่วน R15 ที่ผ่านการรับรอง (Whitelisted Standard R15 Packages) หรือจะใช้ Invisible Standard Collision Box ครอบโมเดล
- **นโยบายการทดสอบ:** ประเด็นนี้เป็นงานที่ต้องทำการทดสอบและพิสูจน์ใน Roblox Studio ในขั้นตอน Implement ถัดไป **ห้ามคาดเดาผลการทดสอบหรือด่วนสรุปตัวเลขล่วงหน้าโดยไม่มีหลักฐานจริง**

### 3.3 Ball Contact & Uniform Collision Geometry Seam
- การเตะบอล, การชิ่งบอล, การส่งบอล, และการสกัดบอล (Slide Tackle / Quick Poke) ต้องอาศัยจุดกระทบที่มีความแน่นอน
- Bounding Box เชิงฟิสิกส์สำหรับการปะทะและการสัมผัสบอลต้องมีขนาดมาตรฐานเดียวกันทุกผู้เล่น เพื่อป้องกันความเหลื่อมล้ำ เช่น ผู้เล่นที่ใช้ Avatar ตัวเล็กได้เปรียบในการลอดผ่าน หรือ Avatar ตัวใหญ่ได้เปรียบระยะสกัดบอล

### 3.4 Joint Attachments & Motor6D Seam
- Attachment points ที่ใช้กับลูกบอล เช่น `BallDribbleAttachment`, `LeftFootSocket`, `RightFootSocket`, `HeadContactAttachment` ต้องถูกวางในตำแหน่งเชิงพิกัดสัมพัทธ์ที่ได้มาตรฐาน
- ต้องป้องกันไม่ให้ตำแหน่ง Socket เคลื่อนที่ไปตามสัดส่วนกระดูกที่บิดเบี้ยวของแพ็กเกจพิเศษ

### 3.5 Animation Retargeting & Visual Consistency Seam
- ท่าทางแอนิเมชัน Locomotion, Dribble, Shoot, Slide, Wall Run ที่เล่นบนโครงสร้างกระดูก R15 อาจเกิดอาการเท้าจมพื้น (Foot clipping) หรือเท้าลอยเหนือพื้น (Foot floating) เมื่อเล่นบนโมเดลที่มีความยาวช่วงขาต่างกัน
- ต้องมีการตรวจสอบ Retargeting ใน Studio เพื่อให้ Contact Frame ตรงกับจังหวะที่เท้าสัมผัสบอลจริง

### 3.6 Respawn & Avatar Loading Lifecycle Seam
- วงจรชีวิตการโหลด Avatar ผู้เล่นต้องรอรับฟังอีเวนต์ `Player.CharacterAppearanceLoaded` อย่างสมบูรณ์ก่อนทำการ Clamp มิติร่างกายและแนบ Attachments
- ต้องมี Debounce และ Timeout Fallback เพื่อป้องกัน Race Condition ในกรณีที่ Asset โหลดล่าช้า

### 3.7 Accessory & Clothing Occlusion / Collision Seam
- เครื่องประดับศีรษะ, ปีก, เครื่องประดับหลัง, และ Layered Clothing ของผู้เล่นอาจขัดขวางการเคลื่อนที่ของลูกบอล
- **กฎความปลอดภัย:** กำหนดให้ปิดฟิสิกส์ของเครื่องประดับทุกชิ้นโดยเด็ดขาด: `Accessory.Handle.CanCollide = false`, `CanTouch = false`, `CanQuery = false`

### 3.8 Team Readability Seam
- เมื่อผู้เล่นใช้อวาตารของตนเอง เสื้อผ้าและสีสันจะมีความหลากหลาย ไม่สามารถจำแนกทีม Home vs Away ได้ด้วยเสื้อผ้าปกติ
- กำหนดให้ต้องมีระบบแสดงผลสังกัดทีม ได้แก่ Over-head Team Marker / Nameplate หรือ Virtual Team Jersey / Pinnies Vest Overlay ในแมตช์ 2v2

### 3.9 Character Stats & Cards Decoupling Rule
- สถิติตัวละครทั้ง 13 ค่า และ Character Cards (เช่น Messi, Haaland) **ไม่เปลี่ยนแปลงขนาดทางกายภาพหรือมิติร่างกายของผู้เล่น**
- ผู้เล่นทุกคนมีขนาดร่างกายและ Hitbox เท่ากันเสมอ; ค่าสถิติส่งผลเฉพาะตัวคูณฟิสิกส์ (เช่น WalkSpeed, SprintSpeed, Impulse, Stamina Drain Rate) เท่านั้น

---

## 4. Verification Evidence

### 4.1 Zero Code / Test Mutations Check
ตรวจสอบสถานะ Git Working Tree เพื่อยืนยันว่าไม่มีการแตะต้องไฟล์โค้ดหรือชุดทดสอบ:
```powershell
Set-Location C:\Users\Stang\cage-zero
git diff HEAD -- src tests
# ผลลัพธ์: ว่างเปล่า (Empty Output) — ยืนยันไม่มีการแก้ไข source หรือ tests
```

### 4.2 Relative Links & Heading Anchors Audit
รันสคริปต์ตรวจสอบความถูกต้องของ Markdown Links และ Heading Anchors ในโฟลเดอร์ `docs/plan/phase-01-gameplay-demo/release-first`:
```text
Checked 13 markdown files under release-first
Total relative links checked: 62
Broken file links: 0
Broken heading anchors: 0
Verification result: ALL LINKS & ANCHORS VALID
```

### 4.3 SHA256 Hashes of Deliverable Documents
ตารางค่าแฮช SHA256 ของเอกสาร active ทั้งหมดใน Release-First Track:

| ไฟล์เอกสาร | ขนาด (ไบต์) | SHA256 Hash |
|:---|:---:|:---|
| `docs/plan/phase-01-gameplay-demo/release-first/plan.md` | 20,585 | `5e9abf5f2dec49ba2ed08323a7e71ba72625b379bdbf1d9fa0a3416d08b58898` |
| `docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md` | 22,074 | `226acd8d9ea7aaf94c81901dcbe76e39f446988ebbba3fd1d9837e1f87d00d14` |
| `docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md` | 16,544 | `853ee6368edecdfec3bb85a3bfd69a343ec55fadde0abd5e7695bd32b14e6d4a` |
| `docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md` | 26,777 | `ee592dd029279ed3d6b63d9618bf28626a7678729c4ec600e357e1257aa07201` |
| `docs/plan/phase-01-gameplay-demo/release-first/RF-03/plan.md` | 9,160 | `6a0acc990853f4cdf396a3d9e098ce1e66de2cf988011d7773ef9d1390b9cd45` |
| `docs/plan/phase-01-gameplay-demo/release-first/RF-03/tasks.md` | 4,326 | `e56035cacfc7441e1c46126395779a55d632b80263cd3e93a9c0261d934e00cb` |
| `docs/plan/phase-01-gameplay-demo/release-first/RF-03/notes.md` | 4,956 | `92226e0f948eb861ad48b2ab078e5a54ac75749097e4b022a8754438ea6e4b83` |
| `docs/plan/phase-01-gameplay-demo/release-first/RF-04/plan.md` | 6,763 | `0be60443ff45c14740fbccbead1e968f08e0a9a0882d13a001917c3985785082` |
| `docs/plan/phase-01-gameplay-demo/release-first/RF-05/plan.md` | 10,134 | `0c0eeb56b8d36410445d49c57bc91676815a90392d7020abac0b9b54c92ef364` |
| `docs/plan/phase-01-gameplay-demo/release-first/RF-06/plan.md` | 6,815 | `a978c56ab49968dee8697c667e05cb90a576ae93e6cf31c83a197cf0d524960c` |
| `docs/plan/phase-01-gameplay-demo/release-first/RF-07/plan.md` | 6,814 | `689969a2b1bc6cb3d60ba1b628d87e5bd95d6a16bb7b4ba6c212cb1c997a9f16` |
| `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-001.md` | 22,487 | (Self-referential deliverable report) |

---

## 5. Unresolved Items & Risks

1. **Empirical Studio Validation Required:**
   - รายละเอียดความเข้ากันได้ของ Body Packages ที่หลากหลาย (Package Compatibility Matrix) และแนวทางจัดการส่วนขยายของ Visual Mesh ต้องรอการทดสอบจริงใน Roblox Studio ระหว่างขั้นตอนถัดไป ไม่คาดเดาผลล่วงหน้า
2. **BodyCheck Launch Inclusion vs Deferral:**
   - สถานะการรวม Forward Body Check ใน Launch หรือการเลื่อนไป Phase 2 ยังคงเป็น **PENDING Owner Decision** (สเปกคงคุณสมบัติทางเทคนิคและ Control Key Mapping ตามมติ Q6 ไว้ครบถ้วน)
3. **Duplicate Character Outcome Policy:**
   - นโยบายการจัดการตัวละครซ้ำจากการสุ่ม (Cash Conversion vs Duplication Point) ยังคงเป็น **PENDING Owner Decision** (ระบบรองรับการถือครองรายสำเนา Per-Copy Ownership ไว้ครบถ้วนเพื่อป้องกันข้อมูลสูญหาย)

---

## 6. Next Action & Reporting

- **สถานะ:** `READY_FOR_REVIEW` (การปรับปรุงเอกสาร Target Delta และ Reporting Override เสร็จสมบูรณ์)
- **การส่งต่อ:** ส่ง Push Callback ไปยัง verified Codex Controller (`w2:p43`) พร้อมกด `Enter` ตาม Latest Owner Reporting Override เพื่อรอการตรวจสอบอิสระจาก Codex (Review 004) ต่อไป