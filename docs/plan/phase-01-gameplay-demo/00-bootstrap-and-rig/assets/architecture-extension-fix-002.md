# Architecture Extension Fix Report — 002 (DOCS-ARCH-20261024)

- **Task Assignment:** `DOCS-ARCH-20261024` — Correction Round 2
- **Role / Implementer:** `agyplan` (`w2:p49`), Tab `w2:t3M`
- **Controller / Reviewer:** `Codex` (`w2:p43`, Tab `w2:t3E`, kind `codex`)
- **Review Being Addressed:** [architecture-extension-review-002.md](architecture-extension-review-002.md) (`CHANGES_REQUESTED`)
- **Preceding Fix Report:** [architecture-extension-fix-001.md](architecture-extension-fix-001.md)
- **Original Report:** [architecture-extension-report-001.md](architecture-extension-report-001.md)
- **Current Ref:** `c7542258b93b613e0260e43035761cbce87928cd` + dirty working tree (Skill moves active concurrently in `agycage`)
- **Execution Scope:** **DOCUMENTATION ONLY** under STILL-OPEN **Plan 00** (`00-bootstrap-and-rig`) and global architecture/schema allowlist.
- **Reporting Gate:** **STRICT OWNER GATE** — Summarize outcome in own pane, **WAIT for Owner inspection and explicit SEND REPORT request**; no auto-monitoring or unsolicited callback to Codex.

---

## 1. Executive Summary

ทีม `agyplan` ได้ดำเนินการแก้ไขและปรับปรุงข้อค้นพบทั้งหมด **A-01 ถึง A-06** ตามรายงานการตรวจสอบอิสระ [architecture-extension-review-002.md](architecture-extension-review-002.md) อย่างครบถ้วนสมบูรณ์ ภายใต้ขอบเขต **DOCUMENTATION ONLY** โดยรักษาคำตัดสินเด็ดขาดของ Owner ข้อ `U1–U13` ไว้อย่างถูกต้อง ไม่มีการแตะต้องซอร์สโค้ด ไม่มีการรันแอปพลิเคชันเทสต์ ไม่มีการแก้ไขไฟล์ใน Phase 2 และไม่มีการทำ Git mutations ใด ๆ ทั้งสิ้น

---

## 2. ตารางการแก้ไขข้อค้นพบรอบที่ 2 (Corrected Findings Inventory A-01..A-06)

| Finding ID | ระดับความสำคัญ | สาระของข้อค้นพบใน Review 002 | การแก้ไขที่ดำเนินการในรอบนี้ (Fix Action Round 2) | สถานะ |
| :--- | :--- | :--- | :--- | :--- |
| **A-01** | **High** | ตาราง Trait (§4) ถอด victim loss ของ Bulldozer ออกและแต่งชะงัก +0.25s เพิ่ม; Velvet ใส่ทางเลือก 80% ที่ไม่ได้ร้องขอ; ยอดคืน Stamina กลายเป็นช่วงตัวเลขใหม่ 10–12/10–15/15–20 แทนที่จะสอบกลับตาม Source 12/15/20% | • **คืนเอฟเฟกต์ลด Stamina ของเหยื่อใน Bulldozer Impact ตาม Source ดั้งเดิม** โดยกำหนดปริมาณตัวเลขเป็น **`PENDING TUNING`** (ไม่แต่งตัวเลข 15 ลอยๆ) และคงระยะชะงักของผู้ถูกชนที่ **`+0.15s` ตาม Tier I เดิม** (ถอด `+0.25s` ที่แต่งเพิ่มออก)<br>• **Velvet Touch:** กำหนดต้นทุนดูดบอลแรกไม่เสีย Stamina (`trapStaminaCost = 0`) ตาม Source ดั้งเดิม (ถอดทางเลือก 80% ออกเด็ดขาด)<br>• **ยอดคืน Stamina:** สอบกลับขนาดตัวเลขตาม Source (Trivela `+10%`, Wall-Breaker `+12%`, Lightning Poke `+15%`, Iron Wall `+20%`) โดยกำหนดรูปแบบฐานการคิด (`% Max Stamina` vs `% Action Cost` หรือ Flat Points) และการ Dedupe (1 ครั้ง/ทริกเกอร์) เป็น **PROPOSED / PENDING TUNING** ใน [upgrade-limit-break.md §4](designs/upgrade-limit-break.md#4-ตารางสอบกลับ-trait-ปกติ-tier-i-สู่ขั้นตื่นรู้-tier-ii-ทั้ง-16-รายการ) | **FIXED & VERIFIED** |
| **A-02** | **High** | Upgrade §5.3 ระบุว่าธุรกรรมที่ไม่แน่นอนจะคงสภาพเดิมได้อย่างปลอดภัย (Timeout/Uncertain Result ไม่ได้แปลว่าไม่เกิดการคอมมิต); การเขียน Dedupe แยกก่อน Mutation ไม่ปลอดภัยหากไม่มี State Protocol; DataStoreService:UpdateAsync ไม่ใช่ตัวรับ API | • ระบุชัดเจนว่า **ผลลัพธ์ที่ไม่แน่นอน (Uncertain Result / Timeout) ไม่ได้รับประกันว่าการคอมมิตไม่เกิดขึ้น (An uncertain result does NOT establish non-commit)**<br>• กำหนด **Durable Atomic Commit**: การตรวจสอบสิทธิ์กับสถานะปัจจุบันที่จะคอมมิต, การตัดวัตถุดิบ/เงิน Cash, การเพิ่มระดับ, และการบันทึกประวัติคำขอสำเร็จ (`processedRequestIds[requestId]`) **จะต้องคอมมิตร่วมกันอย่างสมบูรณ์ภายใน `UpdateAsync` ครั้งเดียว** บนคีย์ Aggregate ของโปรไฟล์ผู้เล่น<br>• วางกลไก **Reconciliation Protocol**: เมื่อ Client ทำการ Retry หรือโหลดโปรไฟล์ใหม่ Server จะต้องตรวจสอบ `processedRequestIds[requestId]` เพื่อส่งคืนผลลัพธ์เดิมโดยไม่ตัดของซ้ำ<br>• ปรับ Pseudocode ให้เรียกบน DataStore Object (`playerProfileDataStore:UpdateAsync`) แทน DataStoreService ตรงๆ; ส่วนการเลือก Provider และ Session Locking คงสถานะ **PROPOSED / PENDING ARCHITECTURE** ใน [upgrade-limit-break.md §5.3](designs/upgrade-limit-break.md#53-ความปลอดภัยของธุรกรรมตีบวก-durable-single-owner-invariants---a-02-compliance) | **FIXED & VERIFIED** |
| **A-03** | **High** | Monetization §3.3 ตรวจสอบเฉพาะ PaidGacha; ตกหล่น StarterPack/DirectRobux และไอเทมเงินจริงอื่นใน ItemProvenance; ตรวจเฉพาะผู้ขายตอนตั้งแผง ขาดการตรวจผู้เล่นทั้งสองฝ่ายในการเทรดและผู้ซื้อในตลาด; การเก็บ isTradeable ในไอเทมไม่สามารถทดแทนการตรวจสดได้ | • ขยายขอบเขตการกำกับดูแลการเทรดให้ครอบคลุมไอเทมทุกชิ้นที่มีประวัติได้มาจากเงินจริงตามโมเดล `ItemProvenance` (`PaidGacha`, `StarterPack`, `DirectRobuxPurchase`, etc.)<br>• **ตรวจเช็กผู้เล่นทั้งสองฝ่าย (Both Sender AND Receiver):** ในการเทรด P2P เซิร์ฟเวอร์ต้องตรวจ `PolicyService` สดของทั้งคู่ หากฝ่ายใดฝ่ายหนึ่งมี `IsPaidItemTradingAllowed == false` ธุรกรรมที่มี Paid Items ต้องถูกระงับทันที<br>• **ตรวจเช็กสองจังหวะในระบบตลาด (Market Booth):** ตรวจผู้ตั้งขาย ณ เวลาขึ้นแผง (`Listing Time`) และตรวจผู้ซื้อ ณ เวลาสั่งซื้อ (`Purchase Time`)<br>• ระบุชัดเจนว่าแฟล็ก `isTradeable` ในไอเทมเป็นเพียงคุณสมบัติสถิติ ไม่สามารถทดแทนการตรวจสิทธิ์จริงจาก `PolicyService` ณ เวลาทำธุรกรรมได้; ส่วนข้อเสนอ Blanket Trade Ban คงสถานะ **PROPOSED PRODUCT CHOICE** ใน [monetization-identity-celebration.md §3.3](designs/monetization-identity-celebration.md#33-การปฏิบัติตามนโยบาย-roblox-paid-random--paid-item-trading-policy-a-03-compliance) และ [data-schema.md §3.2](../../../../design/data-schema.md#32-celebration--visual-identity-schema-a-03--a-04-compliance) | **FIXED & VERIFIED** |
| **A-04** | **High** | สเปก Upgrade และ data-schema ยังไม่ตรงกัน (baseHeightScale vs heightScale, baseStats vs baseStatModifiers, ownedCelebrationIds vs ownedCelebrations); สมการ EffectiveStat รวมบัฟเงื่อนไขแต่ฟังก์ชันส่งเฉพาะค่าสถิติ ทำให้แคชตอน Spawn อาจแช่แข็งผลวิ่งกวด/พื้นที่; คำว่า All Actions กำกวม | • **ประสาน Canonical Schema เป็นหนึ่งเดียว 100%:** ใน `CharacterDefinition` ใช้ `heightScale`, `widthScale`, `baseSkillMoveStarsCeiling`, `baseStats`, `innateTraitIds` (พร้อมระบุ alias mapping ชัดเจน); ในโปรไฟล์ใช้ `ownedCelebrationIds: { string }` (alias: `ownedCelebrations`) ตรงกันทุกฉบับ<br>• **แยกสองชั้นอย่างเคร่งครัด:**<br>  1. *Static Derived Profile (`StaticCardProfile`):* คำนวณ Base + Custom Allocations (cap 1.15) ตอน Spawn และแคชได้ในระดับ Session พร้อมสัญญา Invalidation เมื่ออัปเกรด/รีสเปก<br>  2. *Dynamic Action Context Evaluation (`EvaluateActionStat`):* ประเมินผลบัฟเงื่อนไข Trait สดรายแอ็กชันในสนามตามตำแหน่งและบริบทจริง **ห้ามแคชค้างไว้ในหน่วยความจำระดับ Spawn เด็ดขาด**<br>• **ระบุเจาะจง 5 กลุ่มแอ็กชันตามคำสั่ง Owner U3:** สิทธิประโยชน์ลด Stamina ที่ระดับ `+5` (0.80x) มีผลเฉพาะ **1. Skill Moves (3 ช่อง), 2. Sprint/Dash, 3. Slide Tackle, 4. Quick Poke, 5. Body Check** เท่านั้น ไม่ใช้คำว่า All Actions กำกวม และไม่ครอบคลุมการยิง/กระโดด/ดูดบอลแรก ใน [upgrade-limit-break.md §5.1–5.2](designs/upgrade-limit-break.md#51-การแยก-persistent-owned-card-record-ออกจาก-runtime-derived-profile-a-04-canonical-schema) และ [data-schema.md §3.1](../../../../design/data-schema.md#31-persistent-card-record-vs-runtime-derived-profile-a-04-canonical-schema) | **FIXED & VERIFIED** |
| **A-05** | **Medium** | Mermaid Layer 3 ยังคงอ้างสิทธิ์ "ปลอดลิขสิทธิ์ / ไม่ละเมิดเครื่องหมายการค้า" ขัดกับ Disclaimer ที่ระบุว่ายังไม่ได้รับการตรวจสอบสิทธิ์ | • ตัดข้อความและถ้อยคำรับรองความปลอดภัยทางกฎหมาย ("ปลอดลิขสิทธิ์", "ไม่ละเมิดเครื่องหมายการค้า", "ปลอดภัยทางกฎหมาย 100%") ออกทั้งหมดใน Mermaid ไดอะแกรมและเนื้อหาทุกจุด<br>• คงตัวละครต้นแบบทั้ง 6 เป็นเพียง **กรณีศึกษาตัวอย่างเพื่อการออกแบบสถาปัตยกรรม (Illustrative Architectural Examples)** โดยระบุชัดเจนว่าสิทธิ์ในชื่อ รูปลักษณ์ และเครื่องหมายการค้าถือเป็นประเด็นที่ยังไม่ได้รับการตรวจรับรอง (Unresolved Rights) ซึ่งต้องผ่านการตรวจทางกฎหมายจริงก่อนพัฒนา ใน [monetization-identity-celebration.md §4, §4.3, §7](designs/monetization-identity-celebration.md) | **FIXED & VERIFIED** |
| **A-06** | **High** | ความสัมพันธ์เชิงคณิตศาสตร์ Request 1.0s + Cutscene 4.0s = 5.0s เกินเส้นตาย Hard Deadline 4.5s; Fallback และ Deadline ถูกนำเสนอเป็นข้อบังคับโดยไม่มีการเลือกจาก Owner; Heading §4, §5, §5.3 พิมพ์ติดย่อหน้าก่อนหน้าทำให้ Heading Anchors พัง | • **แก้ไข Heading Anchors:** แยกบรรทัดเว้นวรรคให้ถูกต้องหน้า `## 4.`, `## 5.`, และ `### 5.3` ทำให้ Anchor ของหัวข้อทำงานสมบูรณ์ 100%<br>• **แจกแจงความสัมพันธ์เชิงคณิตศาสตร์:** $T_{\text{elapsed}} = t_{\text{req}} + t_{\text{cutscene}}$ ชี้ให้เห็นว่า $1.0\text{s} + 4.0\text{s} = 5.0\text{s}$ ซึ่งจะเกินเส้นตายหากกำหนดตายตัวไว้ที่ 4.5s<br>• **นำเสนอทางเลือกเชิงสถาปัตยกรรม (Architectural Alternatives - PROPOSED PENDING OWNER SELECTION):**<br>  - *ทางเลือก 1 (Dynamic Deadline เพดานสูงสุด 5.0s):* Server ขยายเส้นตายตามเวลาจริง $T_{\text{goal}} + t_{\text{req}} + t_{\text{cutscene}}$ (สูงสุดไม่เกิน 5.0s) เพื่อให้เล่นคัตซีน 3.0–4.0s จบสมบูรณ์ทุกท่า<br>  - *ทางเลือก 2 (บีบ Request Window เหลือ 0.5s ใต้ Deadline 4.5s):* ให้เวลาส่งคำขอ $\le 0.5\text{s}$ รวมกับคัตซีน $\le 4.0\text{s} = 4.5\text{s}$ พอดีกับ Deadline 4.5s<br>  - *ทางเลือก 3 (Server Pre-selection ทันทีไม่ต้องรอ Request):* Server สั่งเล่นท่าที่สวมใส่ทันทีที่ $T_{\text{goal}}$ ($t_{\text{req}} = 0$) จบคัตซีนใน 3.0–4.0s<br>  - *ทางเลือก 4 (Graceful Truncation):* เส้นตายตายตัว 4.5s หากส่งช้าให้ Blend-out ออกก่อน 4.5s<br>• นโยบาย Fallback (สลับใช้ Default Celebration หรือข้าม) และการเลือกเส้นตาย ระบุเป็น **PROPOSED ARCHITECTURE** โดยรักษาสัญญาคัตซีน 3.0–4.0s และ Impact Frame 0.15s ไว้อย่างถูกต้อง ใน [monetization-identity-celebration.md §5.2](designs/monetization-identity-celebration.md#52-กลไกและลำดับเวลาคัตซีนท่าดีใจหลังยิงประตู-celebration-timeline--deadline-origin---a-06-compliance) | **FIXED & VERIFIED** |

---

## 3. หลักฐานการปกป้องซอร์สโค้ดและสโคป (Scope & Protection Verification)

### 3.1 ตรวจสอบ Protected 9 Source Files (100% Exact Byte Match)
ซอร์สโค้ดหลักทั้ง 9 ไฟล์มีค่าแฮช SHA-256 ตรงกับก่อนเริ่มงานทุกไบต์ (9/9 EXACT MATCH):

| Protected Source File Path | Baseline SHA-256 | Current Post-Hash SHA-256 | Verification Result |
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

### 3.2 ขอบเขตการทำงานเฉพาะส่วน (Own Hunk Scope vs Working Tree)
- **Zero Phase 2 Writes:** ไม่มีการแก้ไขไฟล์ใน `docs/plan/phase-02-*`
- **Zero Source / Test Writes:** ไม่มีการเขียนใน `src/`, `tests/`, หรือ `.sandbox/rollback/`
- **Zero Git Mutations:** ไม่มีการสั่ง `git commit`, `push`, `add`, หรือสลับกิ่ง
- **เอกสารในขอบเขตการแก้ไขเฉพาะรอบนี้ (Own Touched Files in Fix Round 2):**
  1. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/upgrade-limit-break.md`
  2. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/monetization-identity-celebration.md`
  3. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md`
  4. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/tasks.md`
  5. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/notes.md`
  6. `docs/design/architecture-and-network.md`
  7. `docs/design/data-schema.md`
  8. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/architecture-extension-fix-002.md` *(เอกสารรายงานผลรอบแก้ฉบับใหม่นี้)*

---

## 4. บัญชีลายนิ้วมือไฟล์ในรอบการแก้ไข (File Hashes Inventory)

| ลำดับ | รายการไฟล์ | Pre-Fix Hash (Fix 001 Post-State) | Post-Fix Hash (Fix 002 Final) |
| :---: | :--- | :--- | :--- |
| 1 | `docs/.../designs/upgrade-limit-break.md` | `a1285ad94058c0bdf7d2a3ffc3d3bc9434707b308abf45266b02ad9c57f4e592` | `dc646e2a228a74751b621f807e6cb8da5bdea9db38906bad69d0d3b3376132b9` |
| 2 | `docs/.../designs/monetization-identity-celebration.md` | `950cbb28e27914de014b51b8ed4df1a566661db8ed053b879a0642031896414e` | `4da78511fdc2c9f043ed128eaae17a2c39f9f427151d216f232ae12112a69536` |
| 3 | `docs/.../00-bootstrap-and-rig/plan.md` | `45e83ac3a420546b90e680eb2cc4ce720525da3d022a6ae783f39eb7ae253132` | `64cb228e6a10abffbaa3f44b1f25711e34de095230ec08438d671032edec787d` |
| 4 | `docs/.../00-bootstrap-and-rig/tasks.md` | `6dd0f8685994b64e9fe1bdcd67c3daf5e818fb97cccdbfedc9977c7cf2285408` | `f70cb68f03be03847554c01208eee33a6e5dec04496941a81cfb2790c9e25a6d` |
| 5 | `docs/.../00-bootstrap-and-rig/notes.md` | `760f25f1f5179c16fe12bda3de188a2154432a3d30ee29545e90f202461b3c2b` | `dac9b88228237569cda79fe550603efc5d221fe1f8d849db2469ef1c59db64c3` |
| 6 | `docs/design/architecture-and-network.md` | `c1b74cd39ecedbced6642038185106d9aa6cbecc301e9749467d61166ba5d838` | `72d64e14f6220c481e4974bb12bba6eea582b24cbfb88bd36e76e7e39ed415e9` |
| 7 | `docs/design/data-schema.md` | `be17f8557521ef5bfabd898c4946cf8defc288f720c4752c35c36c4d84b71054` | `9dc95719cd44e157b0f45e762fb30aef8bd19aca809148a7432cc9a7d44d3b0e` |
| 8 | `docs/READ.md` | `7b4d5c693686ab6c4676a41197bce6a263b995f4525a64e52fefc04b98ed1618` | `7b4d5c693686ab6c4676a41197bce6a263b995f4525a64e52fefc04b98ed1618` |
| 9 | `docs/plan/roadmap.md` | `4c46e64eb1a6536b1e7816e4455953ca081c7ab336e8d36427ba7fce988be425` | `4c46e64eb1a6536b1e7816e4455953ca081c7ab336e8d36427ba7fce988be425` |

---

## 5. ผลการตรวจสอบความถูกต้องเชิงโปรแกรม (Programmatic Verification Evidence)

1. **การตรวจสอบลิงก์และ Heading Anchors (Links & Anchors Verification):**
   - รันการตรวจสอบความถูกต้องของทุกลิงก์ภายในเอกสารที่แก้ไข: **0 Broken File Links**
   - ตรวจสอบความถูกต้องของ Heading Anchors ที่แก้ไข (`## 4.`, `## 5.`, `### 5.3`): แยกบรรทัดเว้นวรรคถูกต้องทั้งหมด Anchor ใช้งานได้สมบูรณ์ (PASS)
2. **การตรวจสอบความสอดคล้องเชิงความหมายและคณิตศาสตร์ (Semantic Arithmetic Checks):**
   - ยอดวัตถุดิบการ์ดซ้ำ Uncap: `1 + 1 + 2 + 2 + 3` = `9 ใบ` (PASS)
   - แต้ม Custom Stat Points: `2 (ที่ +2) + 3 (ที่ +3)` = `5 แต้ม` (+0.05) และเพดาน `Base + Custom <= 1.15` (PASS)
   - ตรวจสอบเพดานฟิสิกส์ Wall-Breaker Tier II: `restitution <= 1.15` เสมอ (`math.min(baseRestitution + 0.20, 1.15)`) (PASS)
   - ความสัมพันธ์เวลาท่าดีใจ: $1.0\text{s} + 4.0\text{s} = 5.0\text{s}$ ได้รับการแก้ไขและแจกแจงทางเลือกเชิงสถาปัตยกรรมอย่างถูกต้อง (PASS)
3. **การตรวจสอบ Trait Awakening และขอบเขตตัวเลข (Invariants Verification):**
   - ตรวจสอบรายชื่อ Trait ครบถ้วน 16/16 รายการในตาราง Tier II (PASS)
   - คืนผลการลด Stamina ของเหยื่อใน Bulldozer Impact โดยปริมาณตัวเลขเป็น `PENDING TUNING` และคงระยะชะงัก `+0.15s` ของ Tier I (ถอด `+0.25s` ออก) (PASS)
   - Velvet Touch กำหนด `trapStaminaCost = 0` ตาม Source ดั้งเดิม (ถอดทางเลือก 80% ออก) (PASS)
   - ตรวจสอบขนาดยอดคืน Stamina ตาม Source: Trivela `+10%`, Wall-Breaker `+12%`, Lightning Poke `+15%`, Iron Wall `+20%` (PASS)
4. **การตรวจสอบสถาปัตยกรรมธุรกรรม (Transaction Ordering & Uncertain Results):**
   - ระบุชัดเจนว่าผลลัพธ์ที่ไม่แน่นอน (Uncertain Result) ไม่ได้รับประกันว่าการคอมมิตไม่เกิดขึ้น (PASS)
   - รวมการตรวจสอบสิทธิ์กับ State ที่กำลังจะคอมมิต, การตัดวัตถุดิบ, และ Dedupe Key อยู่ใน Durable Atomic Commit เดียวกันผ่าน `UpdateAsync` (PASS)
   - มีโพรโทคอล Reconcile ป้องกันการตัดของซ้ำตอน Retry (PASS)
   - ปรับ Pseudocode เรียกผ่าน DataStore Object (PASS)
5. **การตรวจสอบนโยบาย Roblox Policy & Paid Trading:**
   - ครอบคลุมไอเทมทุกชิ้นที่ได้จากเงินจริง (`PaidGacha`, `StarterPack`, `DirectRobux`) (PASS)
   - บังคับตรวจสดผู้เล่นทั้งสองฝ่าย (Sender/Receiver) ในการเทรด P2P และทั้งผู้ตั้งขาย/ผู้ซื้อในตลาด (PASS)
   - ระบุชัดเจนว่าแฟล็ก `isTradeable` ในไอเทมไม่สามารถแทนที่การตรวจสดได้ (PASS)
6. **การตรวจสอบความสอดคล้องของ Schema:**
   - โครงสร้าง `CharacterDefinition` และ `PlayerProfileDataExtension` ประสานตรงกัน 100% ข้ามเอกสารทั้ง 3 ฉบับ (PASS)
   - แยก `StaticCardProfile` (แคชตอน Spawn ได้) ออกจาก `EvaluateActionStat` (ประเมินสดรายแอ็กชัน ห้ามแคชค้าง) ชัดเจน (PASS)
   - ระบุส่วนลด Stamina ที่ +5 เฉพาะ 5 กลุ่มแอ็กชันตามคำสั่ง Owner U3 (PASS)
7. **การตรวจสอบการตัดคำรับรองทางกฎหมาย (IP Assurances Removal):**
   - ปราศจากถ้อยคำ "ปลอดลิขสิทธิ์", "ไม่ละเมิดเครื่องหมายการค้า", หรือ "ปลอดภัยทางกฎหมาย 100%" ในทุกเอกสาร (PASS)

---

## 6. วิธีที่ Owner และ Codex สามารถตรวจสอบงาน (HOW TO CHECK)

ท่านสามารถเข้าตรวจสอบรายละเอียดการแก้ไขตามหัวข้อและลิงก์สัมพัทธ์ที่ถูกต้องได้ดังนี้:
1. **ตรวจสอบตาราง Trait Tier II และการสอบกลับขนาดตัวเลข (Finding A-01):**
   - ดูที่ [upgrade-limit-break.md §4](designs/upgrade-limit-break.md#4-ตารางสอบกลับ-trait-ปกติ-tier-i-สู่ขั้นตื่นรู้-tier-ii-ทั้ง-16-รายการ)
   - ตรวจแถว 6 (Velvet Touch `trapStaminaCost = 0`), แถว 13 (Bulldozer คืน victim stamina drain ระบุเป็น PENDING TUNING และคง stagger +0.15s), แถว 2/4/10/12 (คืน Stamina ขนาด 10/12/15/20% ตาม Source)
2. **ตรวจสอบธุรกรรม Durable Atomic Commit และการจัดการผลลัพธ์ไม่แน่นอน (Finding A-02):**
   - ดูที่ [upgrade-limit-break.md §5.3](designs/upgrade-limit-break.md#53-ความปลอดภัยของธุรกรรมตีบวก-durable-single-owner-invariants---a-02-compliance)
   - ตรวจดูหลักการ Uncertain Result, การรวม Dedupe กับการตัดวัตถุดิบใน Atomic Commit เดียว, และโพรโทคอล Reconcile
3. **ตรวจสอบนโยบาย Roblox Paid-Item Trading Coverage (Finding A-03):**
   - ดูที่ [monetization-identity-celebration.md §3.3](designs/monetization-identity-celebration.md#33-การปฏิบัติตามนโยบาย-roblox-paid-random--paid-item-trading-policy-a-03-compliance)
   - ตรวจดูการขยายความครอบคลุม Paid Items ทั้งหมด, การตรวจผู้เล่นทั้งสองฝ่าย (Sender/Receiver), และการตรวจผู้ซื้อ/ผู้ขายในตลาด
   - ดูที่ [data-schema.md §3.2](../../../../design/data-schema.md#32-celebration--visual-identity-schema-a-03--a-04-compliance)
4. **ตรวจสอบ Schema กลางและการแยก Static Profile ออกจาก Dynamic Context (Finding A-04):**
   - ดูที่ [upgrade-limit-break.md §5.1–5.2](designs/upgrade-limit-break.md#51-การแยก-persistent-owned-card-record-ออกจาก-runtime-derived-profile-a-04-canonical-schema)
   - ดูที่ [data-schema.md §3.1](../../../../design/data-schema.md#31-persistent-card-record-vs-runtime-derived-profile-a-04-canonical-schema)
   - ตรวจดูการประสานชื่อฟิลด์ `CharacterDefinition` และ `ownedCelebrationIds` รวมถึงการระบุเจาะจง 5 กลุ่มแอ็กชันตาม U3
5. **ตรวจสอบการตัดคำรับรองสิทธิ์ทางกฎหมาย (Finding A-05):**
   - ดูที่ [monetization-identity-celebration.md §4](designs/monetization-identity-celebration.md#4-ระบบการแสดงเอกลักษณ์นักเตะและการแยกฝั่งทีม-3-layer-visual-identity-system) ใน Mermaid Layer 3
   - ดูที่ [monetization-identity-celebration.md §4.3](designs/monetization-identity-celebration.md#43-เลเยอร์ที่-3-กฎการตั้งชื่อหลบลิขสิทธิ์และ-6-ตัวละครต้นแบบ-illustrative-candidate-roster---a-05-compliance) ในข้อ 2
6. **ตรวจสอบความสัมพันธ์เวลาท่าดีใจและทางเลือกเชิงสถาปัตยกรรม (Finding A-06):**
   - ดูที่ [monetization-identity-celebration.md §5.2](designs/monetization-identity-celebration.md#52-กลไกและลำดับเวลาคัตซีนท่าดีใจหลังยิงประตู-celebration-timeline--deadline-origin---a-06-compliance)
   - ตรวจดูการแจกแจง $1.0\text{s} + 4.0\text{s} = 5.0\text{s}$ และ 4 ทางเลือกเชิงสถาปัตยกรรมที่นำเสนอเป็น PROPOSED PENDING OWNER SELECTION
   - ตรวจสอบความสมบูรณ์ของหัวข้อ `## 4.`, `## 5.`, และ `### 5.3`
7. **ตรวจสอบบันทึกความคืบหน้าของ Plan 00:**
   - ตรวจดู [notes.md](../notes.md#docs-arch-20261024--independent-review-002-corrections-a-01a-06-2026-10-24) และ [tasks.md](../tasks.md)

---

## 7. ประเด็นที่ยังเปิดอยู่เพื่อรอการ Grill ในอนาคต (Open Grill Questions)

ข้อค้นพบทั้งหมด A-01 ถึง A-06 ได้รับการแก้ไขในเชิงสถาปัตยกรรมและเอกสารอย่างครบถ้วน โดยไม่มีประเด็นติดขัด (Blocker) ที่ขัดขวางการตรวจรับสเปกในรอบนี้ ประเด็นที่คงค้างต่อไปนี้ได้รับการทำเครื่องหมายอย่างถูกต้องว่าเป็น **PROPOSED / PENDING GRILL** สำหรับการตัดสินใจเมื่อเริ่มแผนงานที่เกี่ยวข้อง:
1. **การเลือกทางเลือกเส้นเวลาและหน้าต่างคำขอท่าดีใจ (Celebration Timing Policy Selection):** เลือกระหว่าง (1) Dynamic Deadline เพดาน 5.0s, (2) Request Window 0.5s ใต้ Deadline 4.5s, หรือ (3) Server Pre-selection เพื่อสรุปในการจัดทำระบบแมตช์
2. **อัตราการแลกเปลี่ยน Shards และราคากลางเงิน Cash:** รอการ Grill ในระบบเศรษฐกิจ Phase 2 แผน 04
3. **การอนุมัติ Gamepasses ทั้ง 4 รายการ:** รอการ Grill แยกตามแผน 02/04/06/07
4. **การตรวจสอบสิทธิ์เครื่องหมายการค้าจริง (Commercial IP Clearance):** เป็นขั้นตอนทางกฎหมายภายนอกก่อนการเปิดวางจำหน่ายจริง
