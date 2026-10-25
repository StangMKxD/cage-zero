# Target Delta Report 003 — Assisted Aerial Control & Trajectory Guidance Integration

- **Document:** Delta Report 003
- **Date:** 2026-10-25
- **Task / State:** READY_FOR_REVIEW (Documentation Synchronized; Runtime Implementation NOT AUTHORIZED)
- **Controller / Reviewer:** Codex (last known `w2:p43`)
- **Implementer:** agyplan (`w2:p49`)
- **Authority & Inputs:**
  - Owner Design Decisions: [aerial-control-owner-decisions.md](aerial-control-owner-decisions.md) (Q1 recommended, Q2 B, Q3 recommended B, Q4 recommended A)
  - Historical Reviews: [Review 003](review-003.md) (VERIFIED RF-F01..06 historical), [Review 004](review-004.md) / [Delta Report 002](delta-002.md) (RF-F07 & RF-F08 corrections)
- **Git Baseline & Ref:** HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + working tree documentation updates (Zero code/test mutations)

---

## 1. Executive Summary: 4 Accepted Design Decisions

ตามคำสั่งของ Owner และบันทึกข้อตกลงการออกแบบใน [aerial-control-owner-decisions.md](aerial-control-owner-decisions.md) ทีม Implementer (agyplan) ได้ดำเนินการบูรณาการข้อยุติการออกแบบระบบช่วยรับบอลกลางอากาศ (Assisted Aerial Control) และเส้นพยากรณ์วิถีบอล (Trajectory Guidance) เข้าสู่เอกสาร active ของ Release-First Track ครบถ้วนทั้ง 4 มิติ:

### 1.1 Contact-gated Aerial Reception with Relative Speed Limit (Q1 Recommended)
- **ข้อยกเว้นต่อกฎ Blanket No-Auto-Catch เดิม:** อนุญาตให้เกิดการครอบครองบอลกลางอากาศ (Airborne possession) ได้เฉพาะกรณีที่:
  1. ตัวละครที่กระโดด (Jump) หรือพุ่งจากกำแพง (Wall Launch) เกิดการสัมผัสทางกายภาพจริงกับ Hitbox ของลูกบอล (Actual hitbox contact)
  2. ความเร็วสัมพัทธ์ในการเข้าหาบอล (Relative approach speed) ไม่เกินเกณฑ์ที่กำหนด ($|v_{player} - v_{ball}| \le \text{receptionLimit}$)
- **การสะท้อนเมื่อความเร็วเกินเกณฑ์:** หากความเร็วสัมพัทธ์สูงเกินขอบเขต บอลจะกระดอนสะท้อนออกเป็น Loose Ball / Deflection ไม่เกิดการครอบครองบอล
- **ไม่ใช่เงื่อนไขความเร็วขั้นต่ำ:** กลไกนี้ไม่ใช่การบังคับให้ผู้เล่นต้อง Sprint ด้วยความเร็วขั้นต่ำเพื่อปลดล็อก
- **Server Authority & Anti-Teleport:** เซิร์ฟเวอร์เป็นผู้ตัดสินการสัมผัสและความเร็วสัมพัทธ์อย่างเด็ดขาด **ห้ามมิให้มีการวาร์ปหรือเทเลพอร์ตบอลเข้าตัวจากระยะไกลโดยเด็ดขาด**

### 1.2 Brief Aerial Aiming Hold (Q2 B)
- **การลอยค้างเล็งชั่วครู่:** เมื่อรับบอลกลางอากาศสำเร็จ ระบบจะระงับแรงโน้มถ่วงชั่วคราวเพื่อให้ผู้เล่นลอยค้างกลางอากาศเป็นช่วงเวลาสั้น ๆ (Brief Hold Duration) สำหรับการเล็ง 3D และง้างยิง (Windup) ก่อนจะกลับสู่แรงโน้มถ่วงและร่วงลงพื้นตามปกติ
- **การแทนที่กติกาเดิม:** ข้อยุตินี้แทนที่ข้อกำหนดเดิมที่บังคับให้ตัวละครต้องร่วงลงตามปกติเสมอ (Supersedes always-fall-normally เฉพาะ action นี้)
- **ความโปร่งใสและไม่มีสิทธิ์อมตะ:** ลูกบอลต้องมองเห็นได้ชัดเจนและมี Hitbox ตลอดเวลา โดยคู่แข่งสามารถเข้าแย่ง บล็อก หรือสกัดได้ตลอดทุกเฟรม (No I-frame, no guaranteed skill win)
- **ห้ามบินต่อเนื่องและไม่มีคูลดาวน์:** ห้ามมีระบบบินต่อเนื่องไม่จำกัด (No infinite flight), ห้ามเชื่อมต่อการลอยค้างซ้ำซ้อน (No stall chaining), และไม่มี per-move gameplay cooldown

### 1.3 Live Trajectory Guide + Landing Marker & Prerelease Aim Preview (Q3 Recommended B)
- **การแสดงผลสำหรับทุกคน (All Players):** ผู้เล่นทุกคนในสนามมองเห็นเส้นวิถีโค้งพยากรณ์ของลูกบอลลอยฟ้า (Predicted Curved Trajectory) และจุดตกกระทบพื้น (Landing Marker) รวมถึงการคำนวณการชิ่งสะท้อนผนังและเพดาน Stadium A ล่วงหน้าแบบเรียลไทม์
- **การคำนวณใหม่แบบไดนามิก:** เส้นวิถีและจุดตกจะถูกคำนวณใหม่ทันทีเมื่อสถานะลูกบอลเปลี่ยน หรือเมื่อเกิดการสัมผัส/สกัด/ชนสิ่งกีดขวาง
- **Prerelease Aim Preview:** ผู้เล่นที่กำลังง้างยิงกลางอากาศจะมองเห็นเส้นวิถีเล็งและจุดตกจำลองเฉพาะบนหน้าจอของตนเองในระหว่างการชาร์จ
- **ข้อจำกัดเชิงเทคนิค:** เส้นวิถีและจุดตกเป็นเพียงไกด์นำสายตา (Visual Guidance) ไม่ใช่แรงบังคับฟิสิกส์ และไม่รับประกันผลลัพธ์ในอนาคต

### 1.4 Goalkeeper Skill through Physical Contact (Q4 Recommended A)
- ผู้รักษาประตูต้องเคลื่อนที่เข้าสู่ตำแหน่ง จังหวะ และมี **Physical Contact สัมผัสกับลูกบอลจริงในระยะที่ถูกต้อง** จึงจะเซฟประตูได้
- การพุ่งตัวถูกทิศทางเพียงอย่างเดียวไม่การันตีว่าจะเซฟบอลได้ (No correct-direction guaranteed save)
- สนับสนุนเกมรับที่อ่านจังหวะได้ (Readable counterplay) โดยไม่ถือเป็นข้อผูกมัดว่าทุกลูกยิงต้องเซฟได้จากทุกตำแหน่ง และ **ไม่มีการเพิ่ม Goalkeeper AI เข้ามาเป็นข้อกำหนดของ Alpha Launch** (โกล AI ยังคงเลื่อนไป Phase 2 ตามเดิม)

---

## 2. Scope of File Modifications in this Delta

การบูรณาการในรอบนี้ดำเนินการเฉพาะเอกสารที่ agyplan ถือครอง โดยครอบคลุม 11 ไฟล์หลัก:

| ลำดับ | ไฟล์ที่แก้ไข | หัวข้อที่บูรณาการ |
|:---:|:---|:---|
| 1 | [`agent.md`](../../../../../agent.md) | เพิ่มสรุป Owner Aerial-Control Design Delta ใน LATEST DISPATCH |
| 2 | [`docs/design/architecture-and-network.md`](../../../../design/architecture-and-network.md) | เพิ่มหัวข้อ 1.1 วางสถาปัตยกรรม Server Authority on Aerial Reception, Client Trajectory Rendering, และ Goalkeeper Physical Reach |
| 3 | [`docs/specs/spec-01-cage-and-events.md`](../../../../specs/spec-01-cage-and-events.md) | บันทึกการคำนวณเส้นวิถีสะท้อนผนังและเพดาน Stadium A ล่วงหน้าแบบเรียลไทม์ |
| 4 | [`docs/specs/spec-02-duel-and-parry.md`](../../../../specs/spec-02-duel-and-parry.md) | บันทึกข้อยกเว้นการรับบอลกลางอากาศ (Contact + Speed Gated), Brief Hold, บอลแย่งได้ตลอดเวลา (No I-frame), และ Goalkeeper physical reach |
| 5 | [`docs/tdd/master-test-cases.md`](../../../../tdd/master-test-cases.md) | ปรับปรุง `[TC-RF02-02]`, `[TC-RF02-04]`, `[TC-RF04-03]`, และ `[TC-RF06-02]` ให้ครอบคลุมการทดสอบ Aerial Reception, Brief Hold, Trajectory Guidance, และ GK Contact |
| 6 | [`docs/plan/phase-01-gameplay-demo/release-first/plan.md`](../plan.md) | เพิ่มสรุป Seams ข้อ 9 บันทึก 4 ข้อยุติการออกแบบ และอัปเดตแผนภาพ Mermaid |
| 7 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md`](../RF-02/plan.md) | ปรับปรุง Target Ball Interaction, DELTA ข้อ 6, และ Acceptance Criteria ข้อ 3, 4, 6 สำหรับระบบรับบอลกลางอากาศและ Trajectory |
| 8 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md`](../RF-02/tasks.md) | ขยาย Task 2.8 เป็น Aerial Reception, Brief Hold, Volley & Whiff Lifecycle และเพิ่ม Task 2.8.1 Live Trajectory System |
| 9 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md`](../RF-02/notes.md) | เพิ่ม Section 6 ครอบคลุม 4 ข้อยุติการออกแบบ, Finite State Machine, เงื่อนไข Cleanup และรายการพารามิเตอร์ที่รอปรับจูน |
| 10 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-04/plan.md`](../RF-04/plan.md) | เชื่อมโยง Wall Launch เข้ากับ Assisted Aerial Reception และระบบพยากรณ์การสะท้อนผนัง/เพดาน |
| 11 | [`docs/plan/phase-01-gameplay-demo/release-first/RF-06/plan.md`](../RF-06/plan.md) | เพิ่มข้อกำหนด Live Trajectory & Landing Marker และ Prerelease Aim Preview ใน Concise HUD, DELTA, และ Acceptance |
| 12 | [`docs/plan/phase-01-gameplay-demo/release-first/assets/delta-003.md`](delta-003.md) | จัดทำรายงานสรุปฉบับนี้ |

*(ไฟล์ของ Codex ได้แก่ `aerial-control-owner-decisions.md`, `owner-r15-restart.md`, `legacy-plan02-removal.md`, `HANDOFF.md`, `review-*.md`, และ 6 ไฟล์ legacy 02/03 ไม่มีการแตะต้อง; ไม่มี diff ใน `src/` หรือ `tests/`)*

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
Found 33 markdown files under release-first
Verified 110 relative links & anchors.
SUCCESS: All relative links and anchors are valid and resolved!
```

---

## 4. Complete Hash Coverage (All 23 Active & Deliverable Files)

ตารางแสดงค่าความยาวและแฮช SHA256 ปัจจุบันของไฟล์เอกสาร active ทั้งหมดในขอบเขตความรับผิดชอบของ agyplan:

| ลำดับ | ไฟล์เอกสาร | ขนาด (ไบต์) | SHA256 Hash |
|:---:|:---|:---:|:---|
| 1 | `agent.md` | 13,861 | `449042a9e9650b7f2de6b542f2572ba213655e49bfc983911b19b6f25cd8b29c` |
| 2 | `docs/READ.md` | 5,182 | `9dab5c938db7e945c65e1101259e1cdf90987f0fb548273cefebf0b59c5ba077` |
| 3 | `docs/prd/product-requirements.md` | 10,843 | `8a16eb48d246dc33fa4910884f31e73681f85d54e21b40c69ecccb29d0e4410f` |
| 4 | `docs/tdd/master-test-cases.md` | 34,296 | `d22a53a53fb10996563e5174b2fc9a26a768c8aee152da58f78a1b26ac31a21c` |
| 5 | `docs/specs/spec-01-cage-and-events.md` | 9,795 | `dffc460f4304eaa72928e0d6274e560d1b1225824c94672a1792217df946f8f8` |
| 6 | `docs/specs/spec-02-duel-and-parry.md` | 24,912 | `f15dfc926d8c15318b7ede2f28d21bbbfeeb6a17ef831528023ec7033dc976c7` |
| 7 | `docs/specs/spec-03-cards-rig-freekick.md` | 10,480 | `f5b6c7c69643ee9255e8fa8899d292f0c33da56ebca278090e762d3a69de46e8` |
| 8 | `docs/design/architecture-and-network.md` | 47,297 | `a33d1bcf8214e82812b33629fc7308f88d9761adb50e065067ea29cf0ee01873` |
| 9 | `docs/plan/roadmap.md` | 9,506 | `065e923ef82e606f04883237af31169b556c72e7241f6bca3b92c404c67de39b` |
| 10 | `docs/plan/phase-01-gameplay-demo/plan.md` | 11,802 | `6356d8e65de172a3fb03d8817f212b1d611b654bed37ac29c9d8f26182572964` |
| 11 | `docs/plan/phase-01-gameplay-demo/release-first/plan.md` | 22,831 | `bd08f4b3088d55e71404f80c3a5be65b21c4370b344a0b5f486ab8252bf71b69` |
| 12 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md` | 27,328 | `0b341e6f7a16ac7304717822da5619de76716aa34af3f8c8e024623e7f6f37de` |
| 13 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md` | 22,095 | `4e0dfc51565b0eaf8915f152689488d3853db6d3088e3a5a6e5cd92ded4bab3c` |
| 14 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md` | 41,856 | `3eed972fe9bc019191c042d50539e6c3221e26d02b4c2a33cce110f33ecc2812` |
| 15 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/plan.md` | 9,160 | `6a0acc990853f4cdf396a3d9e098ce1e66de2cf988011d7773ef9d1390b9cd45` |
| 16 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/tasks.md` | 4,326 | `e56035cacfc7441e1c46126395779a55d632b80263cd3e93a9c0261d934e00cb` |
| 17 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/notes.md` | 4,956 | `92226e0f948eb861ad48b2ab078e5a54ac75749097e4b022a8754438ea6e4b83` |
| 18 | `docs/plan/phase-01-gameplay-demo/release-first/RF-04/plan.md` | 8,452 | `e4c2456bbf9d1e7ea520cab841ccb2a7f1d914fedab9daedfd391164689e19ee` |
| 19 | `docs/plan/phase-01-gameplay-demo/release-first/RF-05/plan.md` | 10,134 | `0c0eeb56b8d36410445d49c57bc91676815a90392d7020abac0b9b54c92ef364` |
| 20 | `docs/plan/phase-01-gameplay-demo/release-first/RF-06/plan.md` | 8,413 | `8726bfcd6082d9a12248d668ef42e9b7ab08bbabeeb3e14d6fca0e8dfa763bd2` |
| 21 | `docs/plan/phase-01-gameplay-demo/release-first/RF-07/plan.md` | 6,814 | `689969a2b1bc6cb3d60ba1b628d87e5bd95d6a16bb7b4ba6c212cb1c997a9f16` |
| 22 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-001.md` | 22,456 | `87d73831e55d9da42ac0c0b3d30d19e2b81b0a37163151fef5b4d547c761ba56` |
| 23 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-002.md` | 16,452 | `c35c0026a49089797d0992adace93e3c69360699790d22f56cbf2e8b5b68a423` |
| 24 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-003.md` | (This Document) | (Self-referential deliverable report) |

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

- **สถานะ:** `READY_FOR_REVIEW` (การบูรณาการระบบ Assisted Aerial Control & Trajectory Guidance เข้าสู่เอกสาร active เสร็จสมบูรณ์)
- **การส่งต่อ:** ส่ง Push Callback ไปยัง verified Codex Controller (`w2:p43`) พร้อมกด `Enter` ตาม Latest Owner Reporting Override เพื่อรอการตรวจสอบอิสระจาก Codex ต่อไป