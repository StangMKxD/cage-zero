# Target Delta Report 004 — Aerial Delta Corrections & Invariant Alignment (Review 006 Response)

- **Document:** Delta Report 004 (Corrections responding to [Review 006](review-006.md))
- **Date:** 2026-10-25
- **Task / State:** READY_FOR_REVIEW (Documentation Synchronized; Runtime Implementation NOT AUTHORIZED)
- **Controller / Reviewer:** Codex (last known `w2:p43`)
- **Implementer:** agyplan (`w2:p49`)
- **Authority & Inputs:**
  - Review Directives: [Review 006](review-006.md) (`CHANGES_REQUESTED` — RF-F09 & RF-F10)
  - Owner Design Decisions: [aerial-control-owner-decisions.md](aerial-control-owner-decisions.md)
  - Historical Delta Reports: [Delta 001](delta-001.md), [Delta 002](delta-002.md), [Delta 003](delta-003.md)
- **Git Baseline & Ref:** HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + working tree documentation updates (Zero code/test mutations)

---

## 1. Executive Summary & Resolution of Findings

ตามผลการตรวจสอบใน [Review 006](review-006.md) โดย Codex ทีม Implementer (agyplan) ได้ดำเนินการแก้ไขปรับปรุงเอกสารให้สอดคล้องตามข้อกำหนดที่ได้รับมอบหมายครบถ้วนทั้ง 2 ประเด็น (RF-F09 และ RF-F10):

### 1.1 Resolution of RF-F09: Reconciling Acceptance, DoD & Invariants with Aerial Reception Exception
- **ปัญหาเดิม:** ใน `release-first/plan.md` §4 Definition of Done (DoD) รวมถึงข้อความใน Acceptance และ Global Invariants เดิม ยังคงระบุข้อห้ามครอบจักรวาลว่า "ไม่มี auto-catch" โดยไม่ได้ระบุข้อยกเว้นการรับบอลกลางอากาศที่ผ่านการรับรองแล้ว (Contact + Relative-Speed Gated Aerial Reception) ซึ่งอาจทำให้เกิดความขัดแย้งเชิงตรรกะว่า DoD ปฏิเสธฟีเจอร์ที่ได้รับอนุมัติ
- **การแก้ไข:**
  1. ปรับปรุง `release-first/plan.md` §4 DoD (ข้อ 1) ให้ระบุข้อยกเว้นอย่างเป็นเอกภาพ: `โดยลูกบอลไม่ teleport และไม่มี auto-catch (ยกเว้นข้อยกเว้นการรับบอลกลางอากาศที่สัมผัสบอลจริงและผ่านเกณฑ์ความเร็วสัมพัทธ์ตาม Owner Decision; ห้ามการวาร์ปหรือดูดบอลจากระยะไกลโดยเด็ดขาด)`
  2. ปรับปรุง `release-first/plan.md` §2 รายการที่ 1 (Core Ball Mechanics) ให้สอดคล้องกับข้อยกเว้น
  3. ปรับปรุง `docs/prd/product-requirements.md` (ตารางข้อกำหนดการปะทะ/บอล) ให้ระบุข้อยกเว้นชัดเจน
  4. ปรับปรุง `docs/specs/spec-02-duel-and-parry.md` (Directive แถบประกาศหัวข้อ) ให้ระบุข้อยกเว้นชัดเจน
  5. ปรับปรุง `docs/tdd/master-test-cases.md` (`[INV-07]`) ให้ระบุข้อยกเว้นการรับบอลกลางอากาศอย่างถูกต้อง
  6. **คงสภาพข้อห้ามสำคัญ:** การครอบครองบอลจากระยะไกล (Distant possession) และการดูด/เทเลพอร์ตบอล (Ball teleportation) ยังคงเป็นข้อห้ามเด็ดขาดทุกกรณี

### 1.2 Resolution of RF-F10: Preview Scope Alignment & Proposed Technical Contracts Labeling
- **ปัญหาเดิม:**
  1. เอกสาร `RF-02/notes.md` §6.1(3) และ `RF-06/plan.md` §2(7) จำกัดให้ Prerelease Aim Preview แสดงผลเฉพาะผู้เล่นที่ง้างยิงกลางอากาศ ทั้งที่มติ Owner Q3(B) และเอกสารการตัดสินใจระบุให้เป็น Aim Preview ของผู้เล่นที่กำลังง้างยิงทั่วไปก่อนปล่อยบอล (Shooter-only windup preview)
  2. เอกสาร `RF-02/notes.md` §6.2 ระบุให้การสัมผัสกำแพงหรือการปะทะกับคู่แข่งทำให้ยกเลิก Hold หรือเสียการครองบอลทันที ทั้งที่การปะทะเฉียดกัน (Incidental contact) ไม่ควรทำให้บอลหลุดอัตโนมัติ และการตัดสินผลยังไม่ได้ข้อยุติ
  3. สูตรความเร็วสัมพัทธ์ $|v_{player} - v_{ball}|$ เป็นการเลือกใช้ 3D Magnitude ซึ่ง Owner ยังไม่ได้เลือกชอยส์ระหว่าง Magnitude เทียบกับ Radial Closing Component และการระงับแรงโน้มถ่วง (Suspending Gravity) เป็นเพียงกลไกหนึ่งที่ยังไม่ผ่านการพิสูจน์การหยุดความเร็วแนวดิ่ง
- **การแก้ไข:**
  1. **ขยายขอบเขต Preview สู่ Shooter ทั่วไป:** ปรับปรุง `RF-06/plan.md` §2(7), `RF-02/notes.md` §6.1(3) และ `docs/design/architecture-and-network.md` §1.1 ให้ Prerelease Aim Preview เป็นการแสดงผลสำหรับผู้เล่นทุกคนที่กำลังง้างยิง (Windup / Charge) ไม่จำกัดเฉพาะกลางอากาศ ขณะที่ Aerial Hold ยังคงเป็นแอ็กชันเฉพาะกลางอากาศ
  2. **แยกแยะ Required Invariants ออกจาก Proposed Transition Policies:** ปรับปรุงโครงสร้าง `RF-02/notes.md` §6.2 อย่างชัดเจน:
     - **Required Invariants (ข้อกำหนดตายตัวที่ต้องมี):** การลอยค้างต้องมีระยะเวลาจำกัดแน่นอน (Finite & Bounded Duration), ลูกบอลต้องมองเห็นและแย่งได้ตลอดเวลา (Contestable Ball), ไม่มี I-frame/no cooldown, และต้องมีสัญญาล้างสถานะเมื่อตาย เกิดใหม่ ตกถึงพื้น หรือหลุดการเชื่อมต่อ (Cleanup Contract)
     - **Proposed Policies (นโยบายเปลี่ยนผ่านที่รอทดสอบ Feel):** การยกเลิก Hold เมื่อชนกำแพง และนโยบายการปะทะกับคู่แข่ง ถูกระบุสถานะชัดเจนว่าเป็น **PROPOSED technical design / Owner choice pending** โดยเน้นย้ำว่าการแย่งบอลสำเร็จต้องเกิดจากการเข้าสกัดที่ผ่านการตรวจสอบสมบูรณ์ (Validated successful tackle) เท่านั้น การสัมผัสเฉียดกัน (Incidental contact) จะไม่ทำให้บอลหลุดโดยอัตโนมัติ
  3. **ระบุสถานะกลไกและสูตรคำนวณเป็น Proposed Implementation Choice:**
     - ระบุชัดเจนว่าสูตรความเร็วสัมพัทธ์ (3D Magnitude $|v_{player} - v_{ball}|$ เทียบกับ Radial Closing Component) เป็น **PROPOSED implementation choice / technical contract pending**
     - ระบุชัดเจนว่ากลไกการหยุดตัวในอากาศ (เช่น Dampening ความเร็วแนวดิ่ง หรือ LinearVelocity/VectorForce) และการคืนแรงส่งโมเมนตัม (Momentum Restoration) เป็น **PROPOSED technical contract pending**
  4. ไม่มีการเปิดประเด็นสอบถามตัวเลขใหม่ (No new numeric grill) และไม่มีการรื้อฟื้น 4 ข้อยุติหลักที่ Owner รับรองแล้ว

---

## 2. Modified Files & Exact Hunks Summary

| ลำดับ | ไฟล์ที่แก้ไข | หัวข้อที่แก้ไขปรับปรุง |
|:---:|:---|:---|
| 1 | [`docs/plan/phase-01-gameplay-demo/release-first/plan.md`](../plan.md) | แก้ไข §2 ข้อ 1 (Core Ball Mechanics) และ §4 DoD ข้อ 1 เพื่อผสานข้อยกเว้น Aerial Reception |
| 2 | [`docs/prd/product-requirements.md`](../../../../prd/product-requirements.md) | ปรับตารางข้อกำหนดการปะทะ/บอลให้ระบุข้อยกเว้น Aerial Reception |
| 3 | [`docs/specs/spec-02-duel-and-parry.md`](../../../../specs/spec-02-duel-and-parry.md) | ปรับ Directive Header ให้ระบุข้อยกเว้น Aerial Reception |
| 4 | [`docs/tdd/master-test-cases.md`](../../../../tdd/master-test-cases.md) | ปรับ `[INV-07]` ให้ระบุข้อยกเว้น Aerial Reception ชัดเจน |
| 5 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md`](../RF-02/notes.md) | ระบุ Proposed Relative Speed Formula, Proposed Hold Mechanism, ขยาย Aim Preview สู่ Shooter ทั่วไป, และแยก Required Invariants ออกจาก Proposed Transition Policies ใน §6.2 |
| 6 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-06/plan.md`](../RF-06/plan.md) | ปรับ Prerelease Aim Preview ใน §2 ข้อ 7 ให้เป็น Shooter-only windup preview ทั่วไป |
| 7 | [`docs/design/architecture-and-network.md`](../../../../design/architecture-and-network.md) | ระบุสูตร Relative Speed และกลไก Hold ใน §1.1 เป็น PROPOSED technical contracts pending |
| 8 | [`docs/plan/phase-01-gameplay-demo/release-first/assets/delta-004.md`](delta-004.md) | จัดทำรายงานแก้ไขฉบับนี้ |

*(หมายเหตุ: ไฟล์ที่ Codex ถือสิทธิ์ ได้แก่ `aerial-control-owner-decisions.md`, `owner-r15-restart.md`, `legacy-plan02-removal.md`, `HANDOFF.md`, `review-*.md`, รายงานประวัติศาสตร์ `completion-report.md`, `fix-*.md`, `delta-001..003.md`, และ 6 ไฟล์ legacy 02/03 ไม่มีการแตะต้อง; ไม่มี diff ใน `src/` หรือ `tests/`)*

---

## 3. Verification Evidence

### 3.1 Zero Code / Test Mutations Check
```powershell
Set-Location C:\Users\Stang\cage-zero
git diff HEAD -- src tests
# ผลลัพธ์: ว่างเปล่า (Empty Output) — ยืนยันไม่มีการแตะต้อง source หรือ tests
```

### 3.2 Relative Links & Heading Anchors Audit
รันสคริปต์ตรวจสอบความถูกต้องของ Markdown Links และ Heading Anchors ในโฟลเดอร์ `docs/plan/phase-01-gameplay-demo/release-first`:
```text
Found 35 markdown files under C:\Users\Stang\cage-zero\docs\plan\phase-01-gameplay-demo\release-first
Verified 127 relative links & anchors.
SUCCESS: All relative links and anchors are valid and resolved!
```

---

## 4. Complete Hash Coverage (All 24 Active & Deliverable Files)

ตารางแสดงค่าความยาวและแฮช SHA256 ปัจจุบันของไฟล์เอกสาร active ทั้งหมดในขอบเขตความรับผิดชอบของ agyplan:

| ลำดับ | ไฟล์เอกสาร | ขนาด (ไบต์) | SHA256 Hash |
|:---:|:---|:---:|:---|
| 1 | `agent.md` | 13,861 | `449042a9e9650b7f2de6b542f2572ba213655e49bfc983911b19b6f25cd8b29c` |
| 2 | `docs/READ.md` | 5,182 | `9dab5c938db7e945c65e1101259e1cdf90987f0fb548273cefebf0b59c5ba077` |
| 3 | `docs/prd/product-requirements.md` | 11,178 | `b7ef4eee8506a332e8cdee083161b6b51a9bc18cae37622e2515b9cc21426de2` |
| 4 | `docs/tdd/master-test-cases.md` | 34,631 | `40c197628e9d8c5927945fbe9ef6c040a74e4fa916831ed8428ae1c0ee65f1dd` |
| 5 | `docs/specs/spec-01-cage-and-events.md` | 9,795 | `dffc460f4304eaa72928e0d6274e560d1b1225824c94672a1792217df946f8f8` |
| 6 | `docs/specs/spec-02-duel-and-parry.md` | 25,247 | `678f9348ca967413bcf3491060995660d6eba9cfdee8e6a4b592d92c4ae46a46` |
| 7 | `docs/specs/spec-03-cards-rig-freekick.md` | 10,480 | `f5b6c7c69643ee9255e8fa8899d292f0c33da56ebca278090e762d3a69de46e8` |
| 8 | `docs/design/architecture-and-network.md` | 47,648 | `5ccb8b862611012f472a15d6799e2fb4a22302166bae53a3f966f16ce97b288a` |
| 9 | `docs/plan/roadmap.md` | 9,506 | `065e923ef82e606f04883237af31169b556c72e7241f6bca3b92c404c67de39b` |
| 10 | `docs/plan/phase-01-gameplay-demo/plan.md` | 11,802 | `6356d8e65de172a3fb03d8817f212b1d611b654bed37ac29c9d8f26182572964` |
| 11 | `docs/plan/phase-01-gameplay-demo/release-first/plan.md` | 23,552 | `00c45f29ae914d905ce3ccb2f88350a810476657cbe627f9dacf49ae237cf7c6` |
| 12 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md` | 27,328 | `0b341e6f7a16ac7304717822da5619de76716aa34af3f8c8e024623e7f6f37de` |
| 13 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md` | 22,095 | `4e0dfc51565b0eaf8915f152689488d3853db6d3088e3a5a6e5cd92ded4bab3c` |
| 14 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md` | 45,489 | `e82f40f13c2fab16aa3c36be1f437da285d9305b3a540b52bf2563453704188e` |
| 15 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/plan.md` | 9,160 | `6a0acc990853f4cdf396a3d9e098ce1e66de2cf988011d7773ef9d1390b9cd45` |
| 16 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/tasks.md` | 4,326 | `e56035cacfc7441e1c46126395779a55d632b80263cd3e93a9c0261d934e00cb` |
| 17 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/notes.md` | 4,956 | `92226e0f948eb861ad48b2ab078e5a54ac75749097e4b022a8754438ea6e4b83` |
| 18 | `docs/plan/phase-01-gameplay-demo/release-first/RF-04/plan.md` | 8,452 | `e4c2456bbf9d1e7ea520cab841ccb2a7f1d914fedab9daedfd391164689e19ee` |
| 19 | `docs/plan/phase-01-gameplay-demo/release-first/RF-05/plan.md` | 10,134 | `0c0eeb56b8d36410445d49c57bc91676815a90392d7020abac0b9b54c92ef364` |
| 20 | `docs/plan/phase-01-gameplay-demo/release-first/RF-06/plan.md` | 8,531 | `59c46ab59f72535184af8aff993f025a8c0bde8e6e80afe28f76efd6f3cc340f` |
| 21 | `docs/plan/phase-01-gameplay-demo/release-first/RF-07/plan.md` | 6,814 | `689969a2b1bc6cb3d60ba1b628d87e5bd95d6a16bb7b4ba6c212cb1c997a9f16` |
| 22 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-001.md` | 22,456 | `87d73831e55d9da42ac0c0b3d30d19e2b81b0a37163151fef5b4d547c761ba56` |
| 23 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-002.md` | 16,452 | `c35c0026a49089797d0992adace93e3c69360699790d22f56cbf2e8b5b68a423` |
| 24 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-003.md` | 18,752 | `8eba6edc34ac917f64938bc0165e39d177d705b458b4b00b883ed98b993814e1` |
| 25 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-004.md` | (This Document) | (Self-referential deliverable correction report) |

---

## 5. Unresolved Items & Scope Preserved

1. **Tunable Parameters (Tuning & Technical Contract Pending):**
   - ค่าขอบเขตความเร็วสัมพัทธ์ (Relative Speed Limit), ระยะเวลาลอยค้าง (Hold Duration Sec), แรงส่งเมื่อยิง (Release Momentum), กรอบเวลาป้องกันการรับซ้ำ (Re-entry Protection Window) และขอบเขตระยะพยากรณ์วิถีบอล (Predictive Horizon) มีสถานะเป็น **PENDING Empirical Tuning** ในขั้นตอนพัฒนา ไม่กำหนดตัวเลขลอย ๆ ขึ้นมาเองโดยไม่มีการทดสอบจริงใน Studio
2. **Goalkeeper AI Remains Deferred:**
   - การเซฟของโกลยืนพื้นบน Physical Contact เท่านั้น และไม่มีการเพิ่ม Goalkeeper AI เป็นข้อกำหนดใน Alpha Launch (คงไว้ใน Phase 2)
3. **Historical Pending Choices Preserved:**
   - สถานะของ Forward Body Check (รวมใน Launch หรือเลื่อนไป Phase 2) ยังคงเป็น **PENDING Owner Decision**
   - นโยบายการจัดการตัวละครซ้ำจากการสุ่มยังคงเป็น **PENDING Owner Decision**
   - การตรวจสอบความเข้ากันได้ของ Arbitrary Body Packages ใน Studio ยังคงเป็นงานในขั้นตอนถัดไป

---

## 6. Next Action & Reporting

- **สถานะ:** `READY_FOR_REVIEW` (การแก้ไข RF-F09 และ RF-F10 ตาม Review 006 เสร็จสมบูรณ์)
- **การส่งต่อ:** ส่ง Push Callback ไปยัง verified Codex Controller (`w2:p43`) พร้อมกด `Enter` ตาม Latest Owner Reporting Override เพื่อรอการตรวจสอบอิสระจาก Codex ต่อไป
