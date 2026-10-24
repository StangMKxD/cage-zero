# Architecture Extension Fix Report — 001 (DOCS-ARCH-20261024)

- **Task Assignment:** `DOCS-ARCH-20261024` — Correction Round 1
- **Role / Implementer:** `agyplan` (`w2:p49`), Tab `w2:t3M`
- **Controller / Reviewer:** `Codex` (`w2:p43`, Tab `w2:t3E`, kind `codex`)
- **Review Being Addressed:** [architecture-extension-review-001.md](architecture-extension-review-001.md) (`CHANGES_REQUESTED`)
- **Original Report:** [architecture-extension-report-001.md](architecture-extension-report-001.md)
- **Current Ref:** `c7542258b93b613e0260e43035761cbce87928cd` + dirty working tree (Skill moves active concurrently in `agycage`)
- **Execution Scope:** **DOCUMENTATION ONLY** under STILL-OPEN **Plan 00** (`00-bootstrap-and-rig`) and global architecture/schema allowlist.
- **Reporting Gate:** **STRICT OWNER GATE** — Summarize outcome in own pane, **WAIT for Owner inspection and explicit SEND REPORT request**; no auto-monitoring or unsolicited callback to Codex.

---

## 1. Executive Summary

ทีม `agyplan` ได้ดำเนินการแก้ไขข้อค้นพบทั้งหมด **A-01 ถึง A-06** ตามรายงานการตรวจสอบอิสระ [architecture-extension-review-001.md](architecture-extension-review-001.md) อย่างครบถ้วนสมบูรณ์ ภายใต้ขอบเขต **DOCUMENTATION ONLY** โดยรักษาคำตัดสินเด็ดขาดของ Owner ข้อ `U1–U13` ไว้อย่างถูกต้อง ไม่มีการแตะต้องซอร์สโค้ด ไม่มีการรันแอปพลิเคชันเทสต์ และไม่มีการแก้ไขไฟล์ใน Phase 2 ใด ๆ ทั้งสิ้น

---

## 2. ตารางการแก้ไขข้อค้นพบรายข้อ (Corrected Findings Inventory A-01..A-06)

| Finding ID | ระดับความสำคัญ | สาระของข้อค้นพบเดิม | การแก้ไขที่ดำเนินการในรอบนี้ (Fix Action) | สถานะ |
| :--- | :--- | :--- | :--- | :--- |
| **A-01** | **High** | ตาราง Trait (§4) กำหนดตัวเลขคืน Stamina แบนราบ, เพิ่ม victim loss 15 ใน Bulldozer โดยไม่ได้รับอนุมัติ, ใช้ math.random ใน Iron Wall, Clean Sweeper มีความกำกวมเรื่องการบวกทับซ้อน, และ Wall-Breaker ไม่ระบุแคป 1.15 | • คงเงื่อนไขและผลเดิมของ Tier I ครบทั้ง 16 รายการ<br>• `Wall-Breaker` Tier II กำหนดเพดานการเด้งสะท้อนคงที่ `restitution <= 1.15` เสมอ (`math.min(baseRestitution + 0.20, 1.15)`)<br>• `Bulldozer Impact` ถอดการลด Stamina ของเหยื่อออกอย่างเด็ดขาด คงเฉพาะระยะเวลาชะงัก (Stagger Duration) และลด Stamina ผู้พุ่งชน<br>• `Iron Wall Block` เปลี่ยนเป็นรัศมีตกกระทบเชิงกายภาพ (`Physical Target Band 3–4 Studs` หน้าผู้บล็อก) แทน `math.random`<br>• `Clean Sweeper` ระบุชัดเจนเป็นการ **แทนที่** โบนัสเดิม โดยระยะกวาดบอลรวมเป็น `+1.1 Studs` (ไม่ใช่การบวกทบเป็น 1.9)<br>• ระบุฐานการฟื้น Stamina (`% Max Stamina` vs `Flat Points`), การ Dedupe 1 ครั้ง/ทริกเกอร์, และตัวเลขจูนเป็น **PROPOSED / PENDING TUNING** ใน [upgrade-limit-break.md §4](designs/upgrade-limit-break.md#4-ตารางสอบกลับ-trait-ปกติ-tier-i-สู่ขั้นตื่นรู้-tier-ii-ทั้ง-16-รายการ) | **FIXED & VERIFIED** |
| **A-02** | **High** | Upgrade §5.3 อ้างสิทธิ์ ProfileStore/MemoryStore Transaction และ Unconditional Rollback โดยไม่มีการรองรับ; บันทึก Idempotency หลังสำเร็จทำให้เกิดความเสี่ยงตอน Retry | • ตัดข้อความอ้างอิง Cross-Store Distributed ACID Transaction หรือ Universal Rollback ออกทั้งหมด<br>• กำหนด **Durable Single-Owner Aggregate Invariants** 5 ลำดับ: (1) Server Validation, (2) Client Idempotency Key (`requestId`) บันทึกล่วงหน้า/ร่วมกับการเขียน, (3) Atomic Consumption & Level Mutation ร่วมกันบนคีย์ DataStore เดี่ยวของเจ้าของโปรไฟล์, (4) Publish สถานะเฉพาะหลัง Durable Write สำเร็จ, (5) Reconcile ผลลัพธ์ที่ไม่แน่นอนผ่าน Retry หรือ Pending State<br>• ระบุ Storage Provider, Session Locking, และเงื่อนไขการห้ามตีบวกการ์ดใน Deck/Locked เป็น **PROPOSED ELIGIBILITY / PENDING ARCHITECTURE** ใน [upgrade-limit-break.md §5.3](designs/upgrade-limit-break.md#53-ความปลอดภัยของธุรกรรมตีบวก-durable-single-owner-invariants---a-02-compliance) | **FIXED & VERIFIED** |
| **A-03** | **High** | Monetization §3.3 ตรวจสอบเพียงการสุ่มเพื่อห้ามเทรด และ data-schema §3.2 ระบุว่าไอเทมสุ่มเงินจริงห้ามเทรดทุกกรณี โดยตกหล่นเกต `IsPaidItemTradingAllowed` ของ Roblox PolicyService | • จำแนกเกตการตรวจสอบของ `PolicyService` ออกเป็น 2 เกตอิสระ: `ArePaidRandomItemsRestricted` (การซื้อ/สุ่ม) และ `IsPaidItemTradingAllowed` (การเทรด/ตลาด)<br>• ออกแบบ Server-side Policy Gate บล็อกการนำไอเทมที่มีประวัติ `sourceType == "PaidGacha"` ไปเทรดหรือตั้งขายเมื่อผู้เล่นมี `IsPaidItemTradingAllowed == false`<br>• วางกลไก **Fail-Closed Error Handling**: หาก PolicyService ขัดข้อง ให้ถือว่าถูกจำกัดสิทธิ์ไว้ก่อนโดยอัตโนมัติ<br>• ปรับปรุง `data-schema.md §3.2` ให้สอดคล้อง และระบุว่าข้อเสนอแบนการเทรดแบบเหมารวม (Blanket Ban) จัดเป็น **PROPOSED PRODUCT CHOICE** ใน [monetization-identity-celebration.md §3.3](designs/monetization-identity-celebration.md#33-การปฏิบัติตามนโยบาย-roblox-paid-random-items-policy-a-03-compliance) | **FIXED & VERIFIED** |
| **A-04** | **High** | สเปก Upgrade §5 และ data-schema §3 ใช้ชื่อฟิลด์ไม่ตรงกัน; data-schema บันทึกค่า Effective Stars/Stamina Profile ที่ Derive ได้ลง Database; สเปกท่าดีใจสับสนระหว่าง Duration และ Impact Offset; Shard Map ใช้หน่วยการ์ดซ้ำ | • กำหนด **Canonical Proposed Schema** ชุดเดียวประสานตรงกัน 100% (`cardUid`, `characterId`, `allocatedCustomStats`, `awakenedTraitId`, `bankedAwakeningRight`, `extraTraitId`, `provenance`)<br>• แยก **Persistent State** (`OwnedCardInstance` บันทึกเฉพาะข้อมูลดิบ) ออกจาก **Runtime Derived Profile** (`EffectiveCardProfile` คำนวณสดในหน่วยความจำโดยไม่บันทึกลง Database พร้อมสัญญา Cache Invalidation)<br>• ประสานสเปกท่าดีใจ: แยก `cutsceneDurationSec` (3.0–4.0s) ออกจาก `impactFrameDurationSec` (0.15s ถ้วน) และ `impactFrameTriggerOffsetSec` ชัดเจน<br>• `cardShards` ระบุเป็นหน่วยนับดิบ โดยอัตราแลกเปลี่ยน Shard คงสถานะ **PENDING GRILL** ใน [data-schema.md §3](../../../../design/data-schema.md#3-plan-00-foundation-architecture-extension-schema-docs-arch-20261024---a-03--a-04-harmonized) และ [upgrade-limit-break.md §5.1](designs/upgrade-limit-break.md#51-การแยก-persistent-owned-card-record-ออกจาก-runtime-derived-profile-a-04-canonical-schema) | **FIXED & VERIFIED** |
| **A-05** | **Medium** | Monetization §3.1 ยกระดับตัวเลือก Starter Pack 3 ตัวเป็น Verified Target; §6 ฟิกซ์ Preset 2+7 ช่องทั้งที่ Gamepass ถูกพัก; สเกล Ney 0.98 ขัดกับ Archetype 0.92; Header APPROVED กว้างเกินไป; อ้างความปลอดภัยลิขสิทธิ์ 100% ขัดกับ Disclaimer | • ปรับ Header สเปกทั้งสองฉบับเป็น `FOUNDATION ARCHITECTURE SPECIFICATION` (ระบุสถานะ PROPOSED / PENDING ชัดเจน)<br>• Starter Pack: คง U7 (1 การ์ด Tier A + Cash) ส่วนกลไกการเลือกการ์ดระบุเป็น **PROPOSED PENDING DECISION**<br>• ถอดการระบุ Preset 2+7 ช่องตายตัวออก ระบุเป็น **PROPOSED PENDING GRILL**<br>• อธิบายสเกล Ney `0.98` ว่าเป็นตัวอย่างเชิงภาพลักษณ์จาก Demo Preset ใน Plan 00 เดิม (Leon `0.92`, Ney `0.98`) การสรุปค่าจริงจะอิงตาม Production Roster Approval<br>• ตัดข้อความอ้าง "ปลอดภัยทางกฎหมาย 100%" ออก และคงคำเตือนความเสี่ยงทางกฎหมาย (IP Legal Disclaimer) ใน [monetization-identity-celebration.md §1, §3.1, §4.3, §7](designs/monetization-identity-celebration.md) | **FIXED & VERIFIED** |
| **A-06** | **Medium** | Timeline ท่าดีใจมี Request Window 2s + Cutscene 3–4s ขัดแย้งกับ Deadline 4s โดยไม่ระบุจุดเริ่ม (Deadline Origin) และขาดการจัดการกรณี Client หลุด | • กำหนดจุดเริ่มต้นของเส้นเวลา ณ จังหวะลูกบอลข้ามเส้นประตู (**`T_goal`**) ภายใต้การควบคุมของ `00-match-flow`<br>• กำหนด Request Window สั้นลงเป็น `1.0 วินาที` จาก `T_goal` สำหรับ Client ผู้ทำประตู<br>• เพิ่มระบบ **Fallback อัตโนมัติ**: หาก Client ไม่ส่งคำขอภายใน 1.0s หรือหลุดการเชื่อมต่อ Server จะสลับใช้ท่าดีใจมาตรฐานของการ์ด (Default Card Celebration) ทันทีโดยไม่ค้างเกม<br>• คัตซีนเล่น 3.0–4.0 วินาที พร้อม Impact Frame 0.15 วินาที<br>• กำหนด **Server Hard Deadline** สูงสุดไม่เกิน **`4.5 วินาทีจาก T_goal`** เพื่อบังคับคืนมุมกล้องปกติและรีเซ็ตสู่จุดเขี่ยบอลโดยไม่มีเงื่อนไข<br>• ตัวเลือกการกดข้ามคัตซีนและมุมกล้องผู้ชมระบุเป็น **PROPOSED / PENDING CHOICES** ใน [monetization-identity-celebration.md §5.2](designs/monetization-identity-celebration.md#52-กลไกและลำดับเวลาคัตซีนท่าดีใจหลังยิงประตู-celebration-timeline--deadline-origin---a-06-compliance) | **FIXED & VERIFIED** |

---

## 3. หลักฐานการปกป้องซอร์สโค้ดและสโคป (Scope & Protection Verification)

### 3.1 ตรวจสอบ Protected 9 Source Files (100% Intact Match)
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
- **ขอบเขตการแก้ไขเฉพาะรอบนี้ (Own Touched Files in Fix Round 1):**
  1. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/upgrade-limit-break.md`
  2. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/designs/monetization-identity-celebration.md`
  3. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md`
  4. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/tasks.md`
  5. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/notes.md`
  6. `docs/design/architecture-and-network.md`
  7. `docs/design/data-schema.md`
  8. `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/assets/architecture-extension-fix-001.md` *(เอกสารรายงานผลรอบแก้ฉบับนี้)*

---

## 4. บัญชีลายนิ้วมือไฟล์ในรอบการแก้ไข (File Hashes Inventory)

| ลำดับ | รายการไฟล์ | Pre-Fix Hash (Report 001 Baseline) | Post-Fix Hash (Fix 001 Final) |
| :---: | :--- | :--- | :--- |
| 1 | `docs/.../designs/upgrade-limit-break.md` | `8a9df3b1950864395158a8e9dbe0b25e7e52f9df154dce8a6aa8352cf6b421ae` | `a1285ad94058c0bdf7d2a3ffc3d3bc9434707b308abf45266b02ad9c57f4e592` |
| 2 | `docs/.../designs/monetization-identity-celebration.md` | `6c0bbea0e2ccc66110a7337f408a43e581d340da96ec8dd3693177e8a90bf91c` | `950cbb28e27914de014b51b8ed4df1a566661db8ed053b879a0642031896414e` |
| 3 | `docs/.../00-bootstrap-and-rig/plan.md` | `e9a4bdccb3edf55b9e60878d35a34311b1c9d961602ecfdb3fa062d193e29c6f` | `45e83ac3a420546b90e680eb2cc4ce720525da3d022a6ae783f39eb7ae253132` |
| 4 | `docs/.../00-bootstrap-and-rig/tasks.md` | `496a8f61f26663e7aeae6013d6f779dc01942aaca92eb63e880c4e09145e5240` | `6dd0f8685994b64e9fe1bdcd67c3daf5e818fb97cccdbfedc9977c7cf2285408` |
| 5 | `docs/.../00-bootstrap-and-rig/notes.md` | `7e2f255f5f4ea18929b09aac890b31ba5fc66cd1d7b3081b8053bea77d2dc81d` | `760f25f1f5179c16fe12bda3de188a2154432a3d30ee29545e90f202461b3c2b` |
| 6 | `docs/design/architecture-and-network.md` | `e7ddb4a655e151893929531a0044e84c70b7f81b65e9f30b657a4743507fbe34` | `c1b74cd39ecedbced6642038185106d9aa6cbecc301e9749467d61166ba5d838` |
| 7 | `docs/design/data-schema.md` | `ad62d11d68a424bc779f449dfdb279b31a809749a738b43aa262b43958b32c4b` | `be17f8557521ef5bfabd898c4946cf8defc288f720c4752c35c36c4d84b71054` |
| 8 | `docs/READ.md` | `7b4d5c693686ab6c4676a41197bce6a263b995f4525a64e52fefc04b98ed1618` | `7b4d5c693686ab6c4676a41197bce6a263b995f4525a64e52fefc04b98ed1618` |
| 9 | `docs/plan/roadmap.md` | `4c46e64eb1a6536b1e7816e4455953ca081c7ab336e8d36427ba7fce988be425` | `4c46e64eb1a6536b1e7816e4455953ca081c7ab336e8d36427ba7fce988be425` |

---

## 5. ผลการตรวจสอบความถูกต้องเชิงโปรแกรม (Programmatic Verification Evidence)

1. **การตรวจสอบลิงก์ภายในเครื่อง (Markdown Links & Anchors):**
   - รันการตรวจสอบความถูกต้องของทุกลิงก์ภายในเอกสารที่แก้ไข: **0 Broken Links**
2. **การตรวจสอบ Trait Awakening และขอบเขตตัวเลข (Invariants Verification):**
   - ตรวจสอบรายชื่อ Trait ครบถ้วน 16/16 รายการในตาราง Tier II
   - ตรวจสอบเพดานฟิสิกส์ Wall-Breaker Tier II: `restitution <= 1.15` เสมอ (PASS)
   - ตรวจสอบการถอด Victim Stamina Loss ออกจาก Bulldozer Impact: ไม่มี `victimStaminaLoss` ในตาราง (PASS)
   - ตรวจสอบรัศมีตกกระทบ Iron Wall Block: ใช้ Physical Target Band `3–4 Studs` ไม่มี `math.random` (PASS)
   - ตรวจสอบการแทนที่ Hitbox Clean Sweeper: กำหนดเป็น `+1.1 Studs` ทดแทนโบนัสเดิม (PASS)
3. **การตรวจสอบสถาปัตยกรรมธุรกรรม (Transaction Ordering):**
   - ตรวจสอบการตัดข้อความ Cross-Store ACID / Universal Rollback ออก (PASS)
   - ตรวจสอบการเรียงลำดับ Idempotency Key ก่อนบันทึกการเปลี่ยนแปลง (PASS)
4. **การตรวจสอบนโยบาย Roblox Policy:**
   - ตรวจสอบการระบุ 2 เกตอิสระ: `ArePaidRandomItemsRestricted` และ `IsPaidItemTradingAllowed` พร้อมกลไก Fail-Closed (PASS)
5. **การตรวจสอบความสอดคล้องของ Schema:**
   - ตรวจสอบการแยก Persistent Source Model (`OwnedCardInstance`) ออกจาก Runtime Derived Profile (`EffectiveCardProfile`) ชัดเจน ไม่มี Stored Derived Values (PASS)
   - ตรวจสอบการแยก Cutscene Duration (3.0–4.0s) ออกจาก Impact Frame Duration (0.15s) และ Impact Frame Trigger Offset (PASS)

---

## 6. วิธีที่ Owner และ Codex สามารถตรวจสอบงาน (HOW TO CHECK)

ท่านสามารถเข้าตรวจสอบรายละเอียดการแก้ไขตามหัวข้อและลิงก์สัมพัทธ์ที่ถูกต้องได้ดังนี้:
1. **ตรวจสอบตาราง Trait Tier II (Finding A-01):**
   - ดูที่ [upgrade-limit-break.md §4](designs/upgrade-limit-break.md#4-ตารางสอบกลับ-trait-ปกติ-tier-i-สู่ขั้นตื่นรู้-tier-ii-ทั้ง-16-รายการ)
   - ตรวจแถว 4 (Wall-Breaker cap 1.15), แถว 12 (Iron Wall Physical Band 3–4), แถว 13 (Bulldozer ถอด victim drain), แถว 14 (Clean Sweeper +1.1 replacement)
2. **ตรวจสอบธุรกรรม Single-Owner Aggregate (Finding A-02):**
   - ดูที่ [upgrade-limit-break.md §5.3](designs/upgrade-limit-break.md#53-ความปลอดภัยของธุรกรรมตีบวก-durable-single-owner-invariants---a-02-compliance)
   - ดูการเรียงลำดับ Validation -> Dedupe Key -> Atomic Mutation -> Publish Success
3. **ตรวจสอบนโยบาย Roblox Paid-Random & Trading Gate (Finding A-03):**
   - ดูที่ [monetization-identity-celebration.md §3.3](designs/monetization-identity-celebration.md#33-การปฏิบัติตามนโยบาย-roblox-paid-random-items-policy-a-03-compliance)
   - ดูการแยกเกต `ArePaidRandomItemsRestricted` และ `IsPaidItemTradingAllowed` ร่วมกับ Fail-Closed
4. **ตรวจสอบ Schema กลางที่ปรับปรุงให้ตรงกัน (Finding A-04):**
   - ดูที่ [data-schema.md §3](../../../../design/data-schema.md#3-plan-00-foundation-architecture-extension-schema-docs-arch-20261024---a-03--a-04-harmonized)
   - ตรวจดูการแยก `OwnedCardInstance` (Persistent) และ `EffectiveCardProfile` (Runtime Derived) ใน §3.1
   - ตรวจดูการแยก Cutscene Duration และ Impact Frame Duration ใน §3.2
5. **ตรวจสอบการปรับสถานะ Proposal / Illustrative Roster (Finding A-05):**
   - ดูที่ [monetization-identity-celebration.md §3.1](designs/monetization-identity-celebration.md#31-street-legend-starter-bundle-ซื้อได้-1-ครั้งต่อบัญชี---u4-u7) (Starter Pack Roster เป็น PROPOSED PENDING)
   - ดูที่ [monetization-identity-celebration.md §4.3](designs/monetization-identity-celebration.md#43-เลเยอร์ที่-3-กฎการตั้งชื่อหลบลิขสิทธิ์และ-6-ตัวละครต้นแบบ-illustrative-candidate-roster---a-05-compliance) (คำอธิบายสเกล Ney 0.98 และ IP Disclaimer)
6. **ตรวจสอบ Timeline ท่าดีใจและ Deadline Origin (Finding A-06):**
   - ดูที่ [monetization-identity-celebration.md §5.2](designs/monetization-identity-celebration.md#52-กลไกและลำดับเวลาคัตซีนท่าดีใจหลังยิงประตู-celebration-timeline--deadline-origin---a-06-compliance)
   - ตรวจดูจุดเริ่ม `T_goal`, Request Window 1.0s, Default Fallback, และ Hard Server Deadline 4.5s
7. **ตรวจสอบบันทึกความคืบหน้าของ Plan 00:**
   - ตรวจดู [notes.md](../notes.md#docs-arch-20261024--independent-review-001-corrections-a-01a-06-2026-10-24) และ [tasks.md](../tasks.md)

---

## 7. ประเด็นที่ยังเปิดอยู่เพื่อรอการ Grill ในอนาคต (Open Grill Questions)

ข้อค้นพบทั้งหมด A-01 ถึง A-06 ได้รับการแก้ไขในเชิงสถาปัตยกรรมและเอกสารอย่างครบถ้วน โดยไม่มีประเด็นติดขัด (Blocker) ที่ขัดขวางการตรวจรับสเปกในรอบนี้ ประเด็นที่คงค้างต่อไปนี้ได้รับการทำเครื่องหมายอย่างถูกต้องว่าเป็น **PROPOSED / PENDING GRILL** สำหรับการตัดสินใจเมื่อเริ่มแผนงานที่เกี่ยวข้อง:
1. **อัตราการแลกเปลี่ยน Shards และราคากลางเงิน Cash:** รอการ Grill ในระบบเศรษฐกิจ Phase 2 แผน 04
2. **การอนุมัติ Gamepasses ทั้ง 4 รายการ:** รอการ Grill แยกตามแผน 02/04/06/07
3. **การตรวจสอบสิทธิ์เครื่องหมายการค้าจริง (Commercial IP Clearance):** เป็นขั้นตอนทางกฎหมายภายนอกก่อนการเปิดวางจำหน่ายจริง
