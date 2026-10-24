# Architecture Extension Report — 001 (DOCS-ARCH-20261024)

- **Task Assignment:** `DOCS-ARCH-20261024` — New Owner-Resolved Foundation Documentation Task
- **Role / Implementer:** `agyplan` (`w2:p49`), Tab `w2:t3M`
- **Controller / Reviewer:** `Codex` (`w2:p43`, Tab `w2:t3E`, kind `codex`)
- **Authority / Contract:** [HANDOFF (Plan 00 Extension)](../assets/HANDOFF.md) & Owner Directives `U1–U13`
- **Current HEAD:** `c7542258b93b613e0260e43035761cbce87928cd` + dirty working tree (Skill moves active concurrently in `agycage`)
- **Execution Scope:** **DOCUMENTATION ONLY** placed under STILL-OPEN **Plan 00** (`00-bootstrap-and-rig`) for a separate future commit scope.
- **Reporting Gate:** **STRICT OWNER GATE** — Summarize in own pane, **WAIT for Owner inspection and explicit SEND REPORT request**; no auto-monitoring or unsolicited callback to Codex.

---

## 1. Executive Summary

Owner Stang วินิจฉัยข้อขัดแย้งเชิงตำแหน่งเอกสาร โดยมีคำสั่งชี้ขาดให้นำสถาปัตยกรรมและสเปกของระบบ **Upgrade / Limit Break** และ **Monetization / Visual Identity / Celebration** บรรจุลงในแผนงานที่ยังเปิดอยู่คือ **Plan 00 (`00-bootstrap-and-rig`)** แทนที่จะใส่ใน Phase 2 เพื่อจัดกลุ่มเป็น commit สถาปัตยกรรมรากฐานแยกต่างหากในอนาคต

ทีม `agyplan` ได้ดำเนินการจัดทำเอกสารข้อกำหนดสถาปัตยกรรม (Design Specs) จำนวน 2 ฉบับสมบูรณ์ พร้อมเชื่อมโยงเข้ากับระบบเอกสารหลักของโปรเจกต์ (Plan 00, Global Architecture, Global Data Schema, Roadmap, และ READ.md) ภายใต้ขอบเขต **DOCUMENTATION ONLY** โดยผสานคำตัดสินเด็ดขาดของ Owner ข้อ `U1–U13` เหนือตารางข้อเสนอเดิมในไฟล์ดาวน์โหลดอย่างถูกต้องครบถ้วน

---

## 2. การผสานคำตัดสินเด็ดขาดของ Owner (U1–U13 Verification Matrix)

| รหัสข้อตกลง | สาระสำคัญทางเทคนิคที่ Owner ตัดสิน | การนำไปปฏิบัติในสเปก Plan 00 | สถานะการตรวจสอบ |
| :--- | :--- | :--- | :--- |
| **U1** | • `+3` เบิกเนตร (Awaken) 1 Trait ที่มีอยู่เดิม<br>• `+2` และ `+3` แจกแต้มสเตตัส (+0.02 และ +0.03)<br>• `+5` ปลดล็อกสล็อต Trait ติดตัวละครเพิ่ม 1 ช่องถ้วน (ห้ามซ้ำเดิม, ไม่ใช่หิน Trait บนชุด) | บันทึกใน [upgrade-limit-break.md §1, §3](designs/upgrade-limit-break.md) และ [data-schema.md §3.1](../../../../design/data-schema.md) | **VERIFIED (COMPLIANT)** |
| **U2** | TARGET เกมไม่มี Cooldown รายท่า แต่ใช้การจัดการหลอด Stamina ร่วมกับ Recovery Lockout / End-Lag / Action Lifecycle (ห้ามแก้โค้ดที่มี Cooldown อยู่ในปัจจุบัน) | ระบุเป็นเป้าหมายใน [upgrade-limit-break.md §1, §2](designs/upgrade-limit-break.md); ซอร์สโค้ดไม่ถูกแตะต้อง | **VERIFIED (COMPLIANT)** |
| **U3** | • ที่ `+5` ทุก Action (Skill, Dash, Slide, Poke, BodyCheck) ใช้ Stamina ต้นทุน `0.80x` (ลด 20%)<br>• ที่ `+4` ลดเฉพาะ Skill/Dash เหลือ `0.88x` (ลด 12%)<br>• โปรไฟล์ `+5` เข้ามาแทนที่ `+4` โดยสมบูรณ์ ไม่นำมาคูณทับซ้อน | กำหนดฟังก์ชัน `staminaCostProfile = "FullAwakening_Level5"` ใน [upgrade-limit-break.md §3](designs/upgrade-limit-break.md) | **VERIFIED (COMPLIANT)** |
| **U4** | ห้ามขายสเตตัส, ดาวสกิล, หรือ Trait ตรงด้วยเงินจริง; สิ่งที่ซื้อได้จำกัดเฉพาะการ์ดตัวละคร (Gacha/Starter Pack) และเงิน Cash; ไม่เคลม Zero-P2W ลอยๆ | บันทึกใน [monetization-identity-celebration.md §1, §2](designs/monetization-identity-celebration.md) | **VERIFIED (COMPLIANT)** |
| **U5** | การปลดล็อกเพดานดาวสกิล (`+1★` สูงสุดไม่เกิน 5★) ย้ายไปอยู่ที่ขั้น `+5` (ไม่เพิ่มที่ขั้น `+3`); สล็อตติดตั้งสกิลคงที่ 3 ช่องเสมอ | บันทึกใน [upgrade-limit-break.md §3, Level 5](designs/upgrade-limit-break.md) | **VERIFIED (COMPLIANT)** |
| **U6** | แต้ม Custom Stat Points แจกเฉพาะที่ `+2` (2 แต้ม) และ `+3` (3 แต้ม) รวม 5 แต้มถ้วน (+0.01 ต่อแต้ม, ผลรวม Base + Custom ไม่เกิน 1.15); `+1` และ `+4` ไม่มีแจกแต้ม | บันทึกใน [upgrade-limit-break.md §3](designs/upgrade-limit-break.md) และ [data-schema.md §3.1](../../../../design/data-schema.md) | **VERIFIED (COMPLIANT)** |
| **U7** | Starter Pack จำกัด 1 สิทธิ์ต่อบัญชี (`hasPurchasedStarterPack`); ภายในบรรจุ **เฉพาะการ์ด Tier A เลือกได้ 1 ใบ + Cash เริ่มต้นเท่านั้น**; ถอดเสื้อ Jacket, Mutations, เอฟเฟกต์ และหิน Trait ออกทั้งหมด | กำหนด Schema ใน [monetization-identity-celebration.md §2](designs/monetization-identity-celebration.md) | **VERIFIED (COMPLIANT)** |
| **U8** | Gamepasses ทั้ง 4 รายการ (VIP, FastRoll/MultiSummon, Tactical Loadouts, Pro Trader) ระบุสถานะ **DEFERRED FOR GRILL** รอพิจารณาเมื่อถึงแผนที่เกี่ยวข้อง | ระบุตารางสถานะใน [monetization-identity-celebration.md §3](designs/monetization-identity-celebration.md) | **VERIFIED (COMPLIANT)** |
| **U9** | ผู้เล่นเป็นผู้เลือกเบิกเนตร 1 Trait ที่มีอยู่เดิมที่ขั้น `+3`; หากตัวละครมี 0 Trait ให้ **ฝากสิทธิ์ (Banked Right)** ไว้เบิกเนตร Trait ที่ได้รับในภายหลัง (เช่น สล็อตพิเศษที่ `+5`) | กำหนดฟิลด์ `bankedAwakeningRight = true` ใน [upgrade-limit-break.md §3](designs/upgrade-limit-break.md) | **VERIFIED (COMPLIANT)** |
| **U10** | สล็อต Trait เพิ่มเติมที่ `+5` สามารถเลือกจาก Trait ทั้งหมดที่ปล่อยในเกม (ปัจจุบัน 16 รายการ) | ระบุใน [upgrade-limit-break.md §3, §4](designs/upgrade-limit-break.md) | **VERIFIED (COMPLIANT)** |
| **U11** | การ์ดตัวละครที่มี Base 5★ ตั้งแต่เริ่มต้น จะ **ไม่ได้รับส่วนลด Stamina พิเศษ 15% ซ้อน** | ระบุเงื่อนไขใน [upgrade-limit-break.md §2, §3](designs/upgrade-limit-break.md) | **VERIFIED (COMPLIANT)** |
| **U12** | ส่วนลด Stamina ใช้เฉพาะกับ Action ที่มีต้นทุน Stamina อยู่เดิมเท่านั้น; การกระทำที่เป็น 0 Cost (จับบอล, วอลเลย์, โหม่ง, ยิงจังหวะแรก) จะไม่มีการคิดค่าธรรมเนียม Stamina เพิ่ม | บันทึกใน [upgrade-limit-break.md §1, §3](designs/upgrade-limit-break.md) | **VERIFIED (COMPLIANT)** |
| **U13** | สล็อต Trait เพิ่มเติมที่ `+5` **ห้ามเลือกซ้ำกับ Trait เดิมที่มีอยู่บนตัวละครเด็ดขาด** | กำหนด Server Validation Seam ใน [upgrade-limit-break.md §3, §6](designs/upgrade-limit-break.md) | **VERIFIED (COMPLIANT)** |

---

## 3. เอกสารที่จัดทำและแก้ไขในชุดงานนี้ (Deliverables Inventory)

### 3.1 สเปกสถาปัตยกรรมรากฐานใหม่ (New Foundation Design Specs)
1. **[`docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/upgrade-limit-break.md`](designs/upgrade-limit-break.md)**:
   - ตารางเปรียบเทียบ 4 มิติ (AS-IS, Input Source, TARGET U1–U13, Consumer Seams).
   - ระบบ Limit Break `+0` ถึง `+5` ใช้วัตถุดิบการ์ดซ้ำ 1/1/2/2/3 ใบ (รวม 9 ใบ ติด 100%).
   - แต้ม Custom Stat Points 2 แต้มที่ `+2`, 3 แต้มที่ `+3` (รวม 5 แต้ม แคป `1.15`).
   - ตาราง Tracing ครบทั้ง 16 Traits จาก Tier I สู่ Tier II Awakening.
   - สถาปัตยกรรมข้อมูลแยก `CharacterDefinition` (Immutable) ออกจาก `OwnedCardInstance` (Mutable).
2. **[`docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/monetization-identity-celebration.md`](designs/monetization-identity-celebration.md)**:
   - ตารางเปรียบเทียบ 4 มิติ.
   - Starter Pack จำกัด 1 ครั้งต่อบัญชี (เฉพาะ 1 การ์ด Tier A + Cash).
   - Gamepasses ทั้ง 4 รายการ DEFERRED FOR GRILL.
   - Seams รองรับระเบียบ Roblox Paid-Random Items Policy (`PolicyService.GetPolicyInfoForPlayerAsync`, `ArePaidRandomItemsRestricted`, อัตราความน่าจะเป็น, แบนการเทรด, `ItemProvenance`).
   - 3-Layer Visual Identity System บน Single Custom R6 (Bib Cyan/Crimson + Identity Kit + Anime Face Decal) พร้อม 6 ตัวละครอัตลักษณ์ตัวอย่างสำหรับ 5 Archetypes และข้อจำกัดทางกฎหมาย Homage IP.
   - 3-Category FX Gacha (Ball Action, Movement, Goal Celebration) สวยงามล้วน ไม่มีสเตตัส.
   - Cutscene ท่าดีใจ 3–4 วินาที พร้อม Anime Impact Frame 0.15 วินาที ภายใต้การควบคุมของ `00-match-flow`.
   - Signature Sync Bonus เป็นโบนัสความสวยงามและเสียงพิเศษเท่านั้น.

### 3.2 การอัปเดตเอกสารหลักที่เกี่ยวข้อง (Narrow Additive Hunks)
- **[`docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md`](../plan.md)**: เพิ่มหัวข้อย่อยสเปกสถาปัตยกรรมรากฐานใหม่ โดยคงสถานะ Runtime PAUSED_BY_OWNER / F18-F19 OPEN.
- **[`docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/tasks.md`](../tasks.md)**: เช็กเครื่องหมายงาน `D-ARCH-01` ถึง `D-ARCH-04` ครบถ้วน.
- **[`docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/notes.md`](../notes.md)**: บันทึกมติ `DOCS-ARCH-20261024`, สรุป U1–U13, และหลักฐานความปลอดภัยของสโคป.
- **[`docs/design/architecture-and-network.md`](../../../../design/architecture-and-network.md)**: เพิ่ม Section 9 บันทึกสถาปัตยกรรม Progression Authority, PolicyService Seams, Visual Identity Pipeline, และ Match Flow Celebration Authority.
- **[`docs/design/data-schema.md`](../../../../design/data-schema.md)**: เพิ่ม Section 3 บันทึก Typed Luau Models (`CharacterDefinition`, `OwnedCardInstance`, `CelebrationDefinition`, `PlayerProfileDataExtension`, `ItemProvenance`).
- **[`docs/READ.md`](../../../../READ.md)**: เพิ่มหัวข้อทางเข้าเอกสารสำหรับงาน DOCS-ARCH-20261024.
- **[`docs/plan/roadmap.md`](../../../roadmap.md)**: เพิ่มบันทึกสถาปัตยกรรมรากฐานในส่วนสรุป Roadmap.

---

## 4. หลักฐานการปกป้องซอร์สโค้ดและสโคป (Scope & Protection Verification)

### 4.1 ตรวจสอบ Protected 9 Source Files (100% Intact Match)
ซอร์สโค้ดพื้นฐานทั้ง 9 ไฟล์ไม่มีการแตะต้องหรือแก้ไขใด ๆ โดยมีค่าแฮช SHA-256 ตรงกับก่อนเริ่มงานทุกไบต์:

| Protected Source File Path | Pre-State SHA-256 | Post-State SHA-256 | Verification Result |
| :--- | :--- | :--- | :--- |
| `src/shared/Constants.luau` | `da340ae6b09bfc42ce6681b8c1871da5315621b38a17c77162bc25c0471292b6` | `da340ae6b09bfc42ce6681b8c1871da5315621b38a17c77162bc25c0471292b6` | **EXACT MATCH** |
| `src/shared/Types.luau` | `64b9e53831833c3d90f5563beeffa2171ee9abb3ea9662878c8d6216f17a0c59` | `64b9e53831833c3d90f5563beeffa2171ee9abb3ea9662878c8d6216f17a0c59` | **EXACT MATCH** |
| `src/shared/Network.luau` | `217668ce752348d046bf0f7963a3a72ff7133ff5ad57fafb9aea7d4a7abf96a5` | `217668ce752348d046bf0f7963a3a72ff7133ff5ad57fafb9aea7d4a7abf96a5` | **EXACT MATCH** |
| `src/shared/configs/CardConfigs.luau` | `e558086e96a167780febcc24d8cbadb88ee7c37ea271a2f37dc548c1f3b48662` | `e558086e96a167780febcc24d8cbadb88ee7c37ea271a2f37dc548c1f3b48662` | **EXACT MATCH** |
| `src/shared/configs/RigAnimationConfigs.luau` | `e6bff0c9c2e1d1de841d9f83a1f99396cc0ba01fb89bd36aa29bb6a10e82c028` | `e6bff0c9c2e1d1de841d9f83a1f99396cc0ba01fb89bd36aa29bb6a10e82c028` | **EXACT MATCH** |
| `src/server/init.server.luau` | `17d24b2f5199fda3f3a8bbf2cc6c469c2f7252428f48d4fc3456dcdf07926b2b` | `17d24b2f5199fda3f3a8bbf2cc6c469c2f7252428f48d4fc3456dcdf07926b2b` | **EXACT MATCH** |
| `src/server/services/RigAndCardService.luau` | `a6d8d9ea45470b10ed8c77fabba0e491b04d87ebf470f23dae47ea04e0dd8cfc` | `a6d8d9ea45470b10ed8c77fabba0e491b04d87ebf470f23dae47ea04e0dd8cfc` | **EXACT MATCH** |
| `src/client/init.client.luau` | `4731c0449a26ad48f1ae3385c3103643f61d64653c0f2b50799539bbc0c86c93` | `4731c0449a26ad48f1ae3385c3103643f61d64653c0f2b50799539bbc0c86c93` | **EXACT MATCH** |
| `src/client/character/R6AnimationController.luau` | `6e3a0a2a190e08e7fcf1810e17511e5906c32b7cda7c21b67d370acb7d85669a` | `6e3a0a2a190e08e7fcf1810e17511e5906c32b7cda7c21b67d370acb7d85669a` | **EXACT MATCH** |

### 4.2 ขอบเขตการห้ามแตะต้อง (Strict Boundary Guarantees)
- **Zero Phase 2 Writes:** ไม่มีการแก้ไขไฟล์ใด ๆ ในโฟลเดอร์ `docs/plan/phase-02-*` ในรอบงานนี้
- **Zero Source / Test Writes:** ไม่มีการสร้างหรือแก้ไขไฟล์ในโฟลเดอร์ `src/`, `tests/`, หรือ `.sandbox/rollback/`
- **Zero Historical Overwrites:** รายงานเดิม (`docs-update-001.md`, `review-001.md`, `docs-fix-001.md` ใน Phase 2 และ `review-001`–`review-010` ใน Plan 00) ถูกสงวนไว้เป็นประวัติศาสตร์ครบถ้วน
- **Zero Git Mutations:** ไม่มีการสั่ง `git commit`, `git push`, `git add`, หรือการสลับกิ่งใด ๆ Working Tree ที่มีงานค้างของ `agycage` ถูกรักษาไว้ตามเดิมทุกประการ

---

## 5. บัญชีลายนิ้วมือไฟล์ทั้งหมดในชุดงานนี้ (Full File Hashes Inventory)

| ลำดับ | รายการไฟล์ | สถานะก่อนหน้า (Pre-Hash) | สถานะปัจจุบัน (Post-Hash SHA-256) |
| :---: | :--- | :--- | :--- |
| 1 | `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/upgrade-limit-break.md` | *(NEW FILE)* | `8a9df3b1950864395158a8e9dbe0b25e7e52f9df154dce8a6aa8352cf6b421ae` |
| 2 | `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/monetization-identity-celebration.md` | *(NEW FILE)* | `6c0bbea0e2ccc66110a7337f408a43e581d340da96ec8dd3693177e8a90bf91c` |
| 3 | `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md` | `7af577b226b7dfe36e7f963510ba0a223b718687f76326862b9689f940d30d44` | `e9a4bdccb3edf55b9e60878d35a34311b1c9d961602ecfdb3fa062d193e29c6f` |
| 4 | `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/tasks.md` | `44b4d805a73988eb483c8a4b0d84e4d49600675d29e9da06e50176e26920c1a7` | `496a8f61f26663e7aeae6013d6f779dc01942aaca92eb63e880c4e09145e5240` |
| 5 | `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/notes.md` | `6eb9b0d08c3b212d7ddafdd5eea65e90feac9f39be6b7339d58006bf48c791ac` | `7e2f255f5f4ea18929b09aac890b31ba5fc66cd1d7b3081b8053bea77d2dc81d` |
| 6 | `docs/design/architecture-and-network.md` | `bba42670383a753df00fb8bb716052cf95f43ef04ac17870eec35ab05158023a` | `e7ddb4a655e151893929531a0044e84c70b7f81b65e9f30b657a4743507fbe34` |
| 7 | `docs/design/data-schema.md` | `9232cd04028f67e488608e5f5bc621df790d783caea307f764214879123c74b8` | `ad62d11d68a424bc779f449dfdb279b31a809749a738b43aa262b43958b32c4b` |
| 8 | `docs/READ.md` | `e137cc2abb3bdb0587fd9a30bacf4e7b6b82ff05addadaa630bfabd9d0fd732b` | `7b4d5c693686ab6c4676a41197bce6a263b995f4525a64e52fefc04b98ed1618` |
| 9 | `docs/plan/roadmap.md` | `0d07b478a4ccbd1815cedc406cd2960a4ac946ef97996c9b035e3574dd3cb743` | `4c46e64eb1a6536b1e7816e4455953ca081c7ab336e8d36427ba7fce988be425` |

---

## 6. ผลการตรวจสอบความถูกต้องเชิงโปรแกรม (Programmatic Verification Evidence)

1. **การตรวจสอบลิงก์และจุดเชื่อมโยง (Markdown Link & Anchor Validation):**
   - รันการตรวจสอบความถูกต้องของลิงก์ภายในเครื่องทั้งหมดที่อ้างอิงข้ามไฟล์
   - ผลการตรวจ: **0 Broken Links** (ลิงก์สัมพัทธ์ทั้งหมดสามารถเข้าถึงไฟล์เป้าหมายได้ 100%)
2. **การตรวจสอบตัวเลขและสูตรคำนวณ (Mathematical Consistency):**
   - การ์ดซ้ำสำหรับการ Limit Break: `1 + 1 + 2 + 2 + 3 = 9 ใบ` (ความน่าจะเป็นสำเร็จ 100%)
   - แต้ม Custom Stat Points: `2 (ขั้น +2) + 3 (ขั้น +3) = 5 แต้ม` (แต่ละแต้มเพิ่ม +0.01 รวมสูงสุด +0.05, ไม่เกินเพดาน 1.15)
   - การตื่นรู้ Trait: เลือกได้ 1 Trait ที่ขั้น `+3` (ฝากสิทธิ์ได้ถ้ามี 0 Trait)
   - สล็อต Trait พิเศษ: ปลดล็อกแน่นอน 1 ช่องที่ขั้น `+5` (เลือกจาก 16 Traits ในเกม ห้ามซ้ำเดิม)
   - ดาวสกิล: เพิ่มเพดานดาว `+1★` ที่ขั้น `+5` (แคปเพดานไม่เกิน 5★, สล็อตใส่ 3 ช่องคงเดิม)
   - โปรไฟล์ Stamina: `+4` ลดเฉพาะ Skill/Dash เหลือ `0.88x`; `+5` ปรับทุก Action เหลือ `0.80x` (ไม่คิดค่า Stamina เพิ่มสำหรับแอ็กชัน 0-cost)
3. **การตรวจสอบ Trait Awakening:**
   - รายชื่อ Traits ครบทั้ง 16 รายการถูกแจกแจงคุณสมบัติปกติ (`Tier I`) และขั้นตื่นรู้ (`Tier II`) อย่างสมบูรณ์ครบถ้วนในตาราง

---

## 7. วิธีที่ Owner สามารถตรวจสอบงาน (HOW OWNER CAN CHECK)

Owner สามารถเข้าตรวจสอบเอกสารที่จัดทำขึ้นใหม่และส่วนที่มีการแก้ไขได้ตามเส้นทางสัมพัทธ์ดังต่อไปนี้:
1. **ตรวจสอบสเปกระบบอัปเกรด/Limit Break:** [upgrade-limit-break.md](designs/upgrade-limit-break.md)
   - ดูตาราง 4-Way Comparison ใน §2
   - ดูแผนผังและตารางผลประโยชน์ระดับ `+0` ถึง `+5` ใน §3
   - ดูตาราง Tracing ทั้ง 16 Traits สู่ Tier II Awakening ใน §4
2. **ตรวจสอบสเปกระบบ Monetization, Visual Identity และ Celebration:** [monetization-identity-celebration.md](designs/monetization-identity-celebration.md)
   - ดูข้อกำหนด Starter Pack (การ์ด Tier A 1 ใบ + Cash เท่านั้น) ใน §2
   - ดูสถานะการระงับ Gamepasses ทั้ง 4 รายการ (DEFERRED FOR GRILL) ใน §3
   - ดูข้อกำหนดการปฏิบัติตามนโยบาย Roblox Paid-Random Items Policy ใน §4
   - ดูระบบ Visual Identity 3 ชั้น (Bib Overlay Cyan/Crimson) และ 6 อัตลักษณ์ตัวละครใน §5
   - ดูสเปกคัตซีนท่าดีใจ 3–4 วินาที และ Impact Frame 0.15 วินาที ใน §6
3. **ตรวจสอบโครงสร้างข้อมูลที่บันทึกลงสถาปัตยกรรมกลาง:**
   - ตรวจดู [architecture-and-network.md §9](../../../../design/architecture-and-network.md#9-foundation-architecture-extension--plan-00-docs-arch-20261024)
   - ตรวจดู [data-schema.md §3](../../../../design/data-schema.md#3-plan-00-foundation-architecture-extension-schema-docs-arch-20261024)
4. **ตรวจสอบบันทึกความคืบหน้าของ Plan 00:**
   - ตรวจดู [notes.md](../notes.md) และ [tasks.md](../tasks.md)

---

## 8. ข้อจำกัดและประเด็นที่คงค้างเพื่อการตัดสินใจในอนาคต (Disclaimers & Open Items)

1. **อัตราแลกเปลี่ยนเศษการ์ด (Shard Ratios) และราคากลางเงิน Cash:**
   - อัตราการแปลงการ์ดซ้ำเป็นเศษการ์ด (Card Shards) และราคาค่าธรรมเนียมเงิน Cash ในการ Limit Break แต่ละขั้น ยังคงเป็นข้อเสนอที่รอการ Grill และตัดสินใจขั้นสุดท้ายเมื่อเริ่มทำแผนระบบเศรษฐกิจ
2. **การพิจารณา Gamepasses ทั้ง 4 รายการ:**
   - Gamepass (VIP, FastRoll/MultiSummon, Tactical Loadouts, Pro Trader) ยังไม่ผ่านการอนุมัติ และจะถูกนำมาสัมภาษณ์ (Grill) แยกต่างหากเมื่อแผนงานที่เกี่ยวข้องเริ่มต้น
3. **ความเสี่ยงทางกฎหมายลิขสิทธิ์และเครื่องหมายการค้า (IP Legal Disclaimer):**
   - การนำเสนอ 6 อัตลักษณ์ตัวละคร (เช่น Ronan, Ney, Leon, Vandik, Kaiser, Sae) เป็นเพียงกรณีศึกษาตัวอย่าง (Illustrative Candidate Identities) โดยอาศัยหลักการ Homage Naming
   - **คำเตือนสำคัญ:** ข้อเสนอนี้ยังไม่ได้รับการตรวจสอบหรือรับรองความปลอดภัยทางกฎหมาย 100% จากที่ปรึกษาทางกฎหมายจริง ห้ามเคลมว่าปราศจากความเสี่ยงทางละเมิดสิทธิ์โดยเด็ดขาด
4. **สถานะ Runtime ของ Plan 00:**
   - สถานะการพัฒนาและทดสอบทางเทคนิคของ Plan 00 เดิมยังคงเป็น **PAUSED_BY_OWNER** (F18/F19 OPEN) เอกสารนี้เป็นเพียงส่วนขยายด้านสถาปัตยกรรม ไม่ใช่การเปิดทดสอบหรือตรวจรับระบบฟิสิกส์/Rig แต่อย่างใด
