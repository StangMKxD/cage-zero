# RF-02: Core Football & R15 Foundation — Plan

- **Plan State:** PROPOSED / DOCUMENTATION_SYNCED (Implementation NOT AUTHORIZED; awaiting Owner approval)
- **Track:** Phase 1 Release-First
- **Predecessor:** Legacy Plan 02 (`02-player-actions`) CANCELLED_BY_OWNER; this is a brand new plan designed on R15.
- **Authority:** Owner Directive 2026-10-25 ([owner-r15-restart.md](../assets/owner-r15-restart.md)), Primary [HANDOFF.md](../assets/HANDOFF.md), and [Release-First Track Plan](../plan.md).
- **Target Rig:** Player Avatar R15 (Normalized to Same Body Dimensions) (แทนที่ Custom Blocky R15 ตาม Owner Target Delta 2026-10-25; ผู้เล่นใช้ Avatar ของตนเองแต่ถูก Normalized ขนาดร่างกายและมิติ Collision/Contact geometry ให้เท่ากันทุกคน; ขนาดร่างกายไม่เปลี่ยนตาม Stats/Cards).

---

## 1. Context & Motivation

Legacy Plan 02 (`02-player-actions`) ถูกยกเลิกตามคำสั่ง Owner 2026-10-25 เนื่องจากแผนเดิมผูกกับโครงสร้าง R6 ซึ่งมีข้อจำกัดด้านความชัดเจนของท่วงท่าอนิเมชัน และไม่สอดคล้องกับเป้าหมาย Public Alpha ใหม่
แผน **RF-02** นี้จึงถูกสร้างขึ้นใหม่ทั้งหมด เพื่อวางรากฐานฟุตบอลกรง 3D บน **Player Avatar R15 (Normalized to Same Body Dimensions)** เพื่อรักษาอัตลักษณ์และรูปลักษณ์ Avatar ของผู้เล่นควบคู่กับการบังคับมิติและสัดส่วนร่างกายให้มีขนาดเท่ากันทุกคนเพื่อความยุติธรรม พร้อมเตรียมโครงสร้าง Backend Profile และ Config สำหรับทั้งระบบการเล่นและระบบเศรษฐกิจ

---

## 2. AS-IS / TARGET / DELTA

### AS-IS (สถานะปัจจุบันใน Workspace)
- **Rig:** `ServerStorage.CageZeroStandardR6Rig` (โครงสร้าง 6 ชิ้นส่วน, 6 Motor6D ใน Plan 00)
- **Ball & Physics (Comparison Checkpoint `617f523`):** `BallService.luau` และ `CagePhysicsService.luau` ในคอมมิต `617f523` ไม่ใช่ baseline ฟิสิกส์บริสุทธิ์ แต่มีโค้ด possession/shoot/pass, shooting-zone logic, และ `laserGuidedPassActive` อยู่เดิมแล้ว ส่วน `CagePhysicsService.luau` มี hunk ปรับแต่งพื้นเด้ง (`FLOOR_SMASH_RESTITUTION`) และ lighting ภายหลัง
- **Codebase Artifacts จาก Plan 02/03 ใน Repo:** โค้ดที่พัฒนาใน repo จริงได้แก่ `src/client/controllers/InputController.luau`, `src/client/character/R6ActionPoseController.luau`, `src/client/controllers/CameraShiftLockController.luau`, `src/server/services/BallService.luau` (hunk การครองบอลและท่าร่าง), และ `src/server/services/SkillMoveService.luau` *(หมายเหตุ: ไฟล์ `FootballClient.client.luau`, `FootballServer.server.luau`, `ShiftLockDribble.luau` เป็นโค้ดใน external prototype `C:/Users/Stang/FootballSandbox` นอก repository ไม่ใช่ไฟล์ใน repo)*
- **Review/Finding:** มี finding ด้าน visual (review-002: OWNER_VISUAL_REJECTED) และ finding สถาปัตยกรรมค้าง A-01..A-06 ซึ่งต้องคงประวัติไว้ โดยไม่สรุปเกินจริงว่า R6 เป็นสาเหตุเดียวที่พิสูจน์แล้วของความล้มเหลวด้าน visual

### TARGET (เป้าหมายใหม่บน Player Avatar R15 Equal Size)
- **Rig & Normalization Model:**
  - ใช้โมเดล **Player Avatar R15** ของผู้เล่นแต่ละคน โดยผ่านกระบวนการ **Normalization** สัดส่วนและมิติกายภาพจริงของร่างกาย (Height, Width, Depth, HipHeight, Collision Box) ให้มีขนาดเท่ากันทุกคน
  - **Scale Numbers vs Actual Dimensions Seam:** ตระหนักว่าตัวเลข Scale numbers ใน HumanoidDescription เท่ากันไม่ได้รับประกันขนาดจริงของ arbitrary body packages (เช่น Layered Clothing, RTHRO bundles, non-blocky packages, oversized avatars); ต้องมีกลไก Normalization และคัดกรอง Permitted Visual Parts โดยรายละเอียดของ Visual-package ยังเป็น Unresolved design detail (ไม่เดาผลการทดสอบหรือสัญญาว่า arbitrary packages จะคงรูปเดิมได้ 100% ภายใต้ geometry เดียวกัน)
  - **Character Stats / Cards:** สถิติตัวละคร 13 ค่าและการ์ดจะไม่เปลี่ยนแปลงขนาดร่างกายของผู้เล่นในสนาม (No physical size variation from stats/cards)
- **Locomotion & Air Movement:** เดิน, วิ่ง (Sprint), Dash สั้น, Directional Jump พร้อม Air Lean และ Apex Hang-feel; การยิง/ส่งจังหวะแรก (First-time) และการเตะวืด (Whiff penalty) มีแอนิเมชันและการเสียจังหวะ; **ไม่มีคูลดาวน์รายท่า (No per-move gameplay cooldowns)** ตามคำตัดสิน Owner U2 โดยจำกัดด้วย Stamina, Recovery window, และการควบคุมทางกายภาพ
- **Controls & Keybinding Model (ตามมติ Owner Q6):**
  - **LMB:** Shoot (เกมรุก) / Slide Tackle (เกมรับ)
  - **E:** Pass (เกมรุก; คงข้อยกเว้น Core charging E-FakeShot) / Quick Poke (เกมรับ)
  - **RMB:** Direct Curve (เกมรุก) / Forward Body Check (เกมรับ; สถานะ Launch Inclusion vs Deferral รอ PENDING Owner Decision)
  - **MMB:** ปลดระวาง (Retire MMB)
  *(ไม่อนุญาตให้ใช้ปุ่ม `F`; คงคู่ปุ่มตามมติ Q6 ของ Owner อย่างเคร่งครัด)*
- **Ball Interaction:**
  - สัมผัสบอลด้วย Hitbox กายภาพจริง ไม่มีระบบลูกบอลวาร์ปเข้าเท้าจากระยะไกล (No Remote Ball Teleportation)
  - **ข้อยกเว้นการรับบอลกลางอากาศ (Assisted Aerial Reception Exception):** ยกเว้นข้อห้าม auto-catch เดิมเฉพาะกรณีรับบอลกลางอากาศ: ผู้เล่นที่กระโดด (Jump) หรือ Wall Launch ที่เข้าชน Hitbox บอลจริงและมีความเร็วสัมพัทธ์ (Relative approach speed) ไม่เกินเกณฑ์ จะสามารถจับครองบอลกลางอากาศและเข้าสู่สถานะ **ลอยค้างเล็งชั่วครู่ (Brief airborne hold)** เพื่อเล็ง 3D และง้างยิงกลางอากาศได้ (supersedes always-fall-normally เฉพาะ action นี้; หากความเร็วสัมพัทธ์สูงเกินจะสะท้อนเป็น Loose Ball; ห้ามการวาร์ปบอลจากระยะไกล; บอลมี Hitbox แย่งได้ตลอดเวลา ไม่มี I-frame และไม่มี gameplay cooldown)
  - **Live Trajectory & Landing Guide:** ผู้เล่นทุกคนมองเห็นเส้นวิถีโค้งและจุดตกของบอลลอยฟ้าล่วงหน้าแบบเรียลไทม์ รวมถึงการชิ่งสะท้อนผนัง/เพดานของ Stadium A พร้อม Prerelease Aim Preview แสดงเฉพาะผู้เล่นที่กำลังง้างยิง (Visual Guidance ไม่รับประกันผลลัพธ์ล่วงหน้าและถูกล้าง/คำนวณใหม่เมื่อบอลถูกสัมผัสหรือสกัด)
  - Manual Pass เล็งทิศทาง 3D
  - ปุ่ม Request-Ball ส่งเฉพาะ visual/audio signal หาเพื่อนร่วมทีม **ไม่เกิดการ Auto-Pass เด็ดขาด**
  - ปุ่มยิงตรง (Shoot บน LMB) และยิงโค้ง (Curve Shot บน RMB) แยกปุ่มชัดเจน
- **Basic Defense:**
  - Slide Tackle (LMB): พุ่งสกัดต่ำ หากพลาดจะติด Recovery รอจังหวะลุก
  - Quick Poke (E): สะกิดบอลระยะประชิด รวดเร็ว แย่งบอลจากการสัมผัสจริง (ไม่มี per-move cooldowns)
  - **Goalkeeper Physical Reach:** ผู้รักษาประตูต้องเข้าถึงตำแหน่งและสัมผัสบอลจริงในระยะที่ถูกต้อง การพุ่งถูกทิศทางเพียงอย่างเดียวไม่การันตีการเซฟ (No correct-direction guaranteed save; ไม่เพิ่ม GK AI ใน launch scope)
- **Backend Foundation:**
  - `PlayerProfile` schema: รองรับ `schemaVersion`, `cash`, `ownedCharacters: { CharacterInstance }` (โมเดลการถือครองรายสำเนา โดย duplicate outcome policy มีสถานะ **PENDING** การตัดสินใจของ Owner), `selectedCharacterId`, `ownedCosmetics`, `entitlements`, `processedPurchaseIds`, `profileRevision`
  - `BalanceConfig`: แหล่งรวมค่าสมดุลการเคลื่อนที่ แรงบอล และสถิติต่าง ๆ แยกออกจาก Game Logic อย่างเด็ดขาด (ไม่มีฟิลด์ cooldown)
  - **Durable Economic Invariants:** Debit + Grant สำเร็จในธุรกรรมเดียวกัน, Unreconciled outcomes ปรับยอดเมื่อ reconnect, Retry ไม่ reroll, Request ID ป้องกันการให้ของซ้ำ

### DELTA (สิ่งที่ต้องทำใหม่และจัดการ)
1. **Player Avatar R15 Loading & Normalization Pipeline:** จัดการวงจรชีวิตการโหลด Avatar ผู้เล่นแบบ Dual-path ([`Player:HasAppearanceLoaded()`](https://create.roblox.com/docs/reference/engine/classes/Player#HasAppearanceLoaded) + [`CharacterAppearanceLoaded`](https://create.roblox.com/docs/reference/engine/classes/Player#CharacterAppearanceLoaded)), ติดตาม Generation token, กำหนดให้ Timeout ห้ามปล่อยตัวละครที่ไม่ผ่านการ Normalize เข้าเกมเพลย์เด็ดขาด, แยกแยะ `HumanoidDescription` scale properties (`HeightScale` ฯลฯ) ออกจาก `Humanoid` child `NumberValue` (`BodyHeightScale` ฯลฯ), ใช้กระบวนการ Normalize Bounding Box / Collision Box ให้เท่ากันทุกผู้เล่นเพื่อความยุติธรรม, กำหนดตำแหน่ง Attachment ที่ได้มาตรฐาน (Left/Right Foot, DribbleSocket) และปิดการชน Physics Collision ของ Accessory ทุกชิ้น
2. **Reuse Audit (ไม่ Port อัตโนมัติ):** ตรวจสอบ Logic จาก legacy 02 เพื่อคัดเลือกโค้ดที่นำกลับมาใช้ได้ (เช่น การคำนวณเวกเตอร์วิถีบอล, Segmented Charge Gauge logic) โดยปรับให้เข้ากับ R15 Motor6D และไม่นำ R6 hardcoded joint offsets มาใช้
3. **New R15 Animation Choreography & Retargeting:** จัดทำ Timing และ Pose ใหม่บน R15 สำหรับ Run, Sprint, Dash, Kick, Curve, Header, Volley, Whiff, Slide, Poke พร้อมตรวจสอบ Animation Retargeting บนหลากหลาย Avatar packages
4. **Input & Camera Integration:** รองรับ Shift Lock, Keybinds ยิง/ส่งแยกปุ่มตามมติ Owner Q6, ปุ่มขอบอล
5. **Durable Profile DataStore & BalanceConfig Module:** วางโครงสร้าง Module สำหรับ Profile และ Configuration
6. **Assisted Aerial Control & Live Trajectory Guidance System:** พัฒนาระบบตรวจสอบการชนบอลกลางอากาศและ Relative Speed Limit, วงจรสถานะ Brief Airborne Hold พร้อมการคืนแรงโน้มถ่วง, โมดูลคำนวณเส้นวิถีโค้ง/จุดตกสะท้อนผนัง และ Prerelease Aim Preview

---

## 3. Detailed Acceptance Criteria

1. **R15 Avatar Normalization & Mechanics Verification:**
   - ตัวละคร Player Avatar R15 ของผู้เล่นแต่ละคนถูก Normalize มิติร่างกายให้มีขนาดเท่ากันตามเกณฑ์มาตรฐาน และสามารถเคลื่อนไหวครบ Loop (Idle, Walk, Sprint, Dash) และตอบสนองต่อ Jump/Air Lean อย่างเป็นธรรมชาติ
   - ลูกบอลสัมผัสกับเท้า R15 ด้วย Collision จริง ไม่เกิดการ Snapping หรือ Teleport เข้าเท้า
   - Accessory และเสื้อผ้าไม่มีผลต่อการชนทางกายภาพของลูกบอล (No accessory physics interference)
2. **Passing & Shooting Verification:**
   - ผู้เล่นส่งบอลแบบ Manual 3D ไปยังตำแหน่งเป้าหมายได้ถูกต้องตามแรงชาร์จ
   - การกดขอบอล (Request-Ball) แสดงตัวบ่งชี้ชัดเจนบนหัวผู้เล่น แต่ผู้ถือบอลยังต้องกดส่งเอง
   - การยิงตรงและยิงโค้งแยกการทำงานชัดเจน วิถีโค้งคำนวณจาก Curve parameter ใน BalanceConfig
3. **Aerial, Brief Hold & Whiff Mechanics:**
   - การกระโดดเตะ/โหม่งกลางอากาศ (Volley/Header) ทำงานเมื่อบอลอยู่ในระยะสัมผัสที่ถูกต้อง
   - การกระโดดเข้าชน Hitbox บอลกลางอากาศที่ความเร็วสัมพัทธ์ไม่เกินเกณฑ์ สามารถจับครองบอลและเข้าสู่สถานะ Brief Airborne Hold เพื่อเล็ง 3D และง้างยิงได้จริง (หากเร็วเกินไปบอลจะกระดอนออกเป็น Loose Ball; คู่แข่งสามารถเข้าแย่งบอลได้ตลอดเวลา ไม่มี I-frame)
   - หากเตะพลาด (Whiff) ผู้เล่นจะเสียจังหวะชะงักตาม Whiff Penalty Window ที่กำหนด
4. **Defense & Goalkeeper Mechanics:**
   - Slide Tackle พุ่งสกัดโดนบอลจริง และมี Recovery window ที่ต้องลุกขึ้น
   - Quick Poke สะกิดเปลี่ยนทิศทางบอลได้ในระยะประชิด
   - ผู้รักษาประตูเซฟบอลได้จากการเข้าถึงตำแหน่งและสัมผัสบอลจริงในระยะที่ถูกต้องเท่านั้น (ไม่มีการเซฟอัตโนมัติจากการพุ่งถูกทิศทาง)
5. **Data & Config Foundation:**
   - Schema บันทึกข้อมูล Profile เริ่มต้นถูกต้อง รองรับการเก็บสำเนาตัวละคร (`CharacterInstance`) โดย duplicate outcome policy มีสถานะ PENDING การตัดสินใจของ Owner
   - `BalanceConfig` สามารถปรับจูนค่าความเร็ว แรงบอล และ recovery window ได้จากตารางกลางโดยไม่ต้องแก้โค้ดระบบ (ไม่มี per-move cooldowns)
   - สถิติตัวละครไม่ส่งผลต่อขนาดทางกายภาพของร่างกาย
6. **Live Trajectory & Visual Aim Guidance:**
   - ผู้เล่นทุกคนมองเห็นเส้นวิถีโค้งและจุดตกของบอลลอยฟ้าล่วงหน้า รวมถึงการสะท้อนผนัง/เพดาน และเส้นจะถูกรีเฟรชทันทีเมื่อบอลถูกสัมผัสหรือสกัด
   - ผู้เล่นที่กำลังง้างยิงมองเห็น Prerelease Aim Preview บนหน้าจอของตนเอง
7. **Owner Visual Acceptance:**
   - ท่วงท่าและ Animation ของ R15 ทั้งหมดบน Player Avatar รวมถึงจังหวะการรับบอลกลางอากาศและการลอยค้างเล็ง ต้องผ่านการตรวจรับทางสายตาโดย Owner ใน Studio / Live Play

---

## 4. Migration & Rollback Strategy

- **Historical Isolation:** เก็บโค้ดและ Assets ของ R6 เดิมไว้ใน Branch/Repo เพื่อเป็นเอกสารอ้างอิงและประวัติศาสตร์ ไม่มีการลบทิ้ง
- **Seam Isolation:** พัฒนา Module R15 ในลักษณะ Seam ที่สะอาด แยกโครงสร้าง Rig และ Controller ออกจาก legacy implementation
- **Rollback:** หากการทดสอบบน R15 พบปัญหาที่ไม่สามารถแก้ไขได้ ระบบสามารถสลับ Config กลับไปชี้ชุดทดสอบเดิมได้โดยไม่กระทบประวัติ Git

---

## 5. Legacy Plan 02/03 Removal & Cleanup Strategy (Owner Delta 2026-10-25)

ตามคำสั่ง [legacy-plan02-removal.md](../assets/legacy-plan02-removal.md) เจ้าของต้องการนำ Animation/Gameplay เก่าที่สร้างตั้งแต่ Plan 02 ออกจริงสำหรับ R15 restart โดยมีหลักปฏิบัติดังนี้:

### 5.1 สถานะของ Removal Manifest (Provisional Inventory Only)
- ตารางรายการถอดถอนในแผนนี้มีสถานะเป็น **การสำรวจเบื้องต้นแบบอ่านอย่างเดียว (Provisional Inventory / Read-Only Discovery)** ยังไม่ใช่ข้อกำหนดสั่งถอดถอนที่พร้อมประมวลผล (Not an executable cleanup instruction)
- **ความจริงของ Checkpoint `617f523`:** คอมมิต `617f523` เป็นเพียง Comparison Checkpoint เท่านั้น ไม่ใช่ baseline ฟิสิกส์บอลบริสุทธิ์ เพราะ `BallService.luau` ณ จุดนั้นมีโค้ด possession/shoot/pass, shooting-zone, และ `laserGuidedPassActive` อยู่เดิมแล้ว ส่วน `CagePhysicsService.luau` มี hunk ปรับปรุง `FLOOR_SMASH_RESTITUTION` และ lighting ในภายหลัง ดังนั้นการทำความสะอาดจึง **ห้ามใช้วิธี Restore/Reset ไฟล์ทั้งไฟล์กลับสู่ `617f523`** แต่ต้องระบุ hunk ที่ต้องการถอดอย่างละเอียด

### 5.2 การจัดหมวดหมู่เบื้องต้น 34 ไฟล์ใน `src` และ `tests` (Provisional Classification)
1. **KEEP (คงรักษาไว้):**
   - **Plan 00 Foundation:** `src/server/services/RigAndCardService.luau`, baseline `src/client/character/R6AnimationController.luau` (โครงสร้าง bootstrap)
   - **Plan 01 Arena & Physics:** `src/server/services/CagePhysicsService.luau` (ประเมิน hunk ปรับแต่งพื้นเด้ง/lighting ร่วมด้วย ไม่เหมารวมเป็น 100% Plan 01), และ core physics ใน `src/server/services/BallService.luau`
   - **Pre-existing Tests:** `tests/e2e/Tier1_FeatureCoverage.luau` (มีอยู่ก่อน Plan 02 ต้องคงไว้ ห้ามใช้ wildcard ลบทิ้ง)
   - **Historical Evidence & Assets:** เอกสาร reviews (review-001..008), fixes (fix-001..015), HANDOFF ทั้งหมด, โฟลเดอร์ `argon-r6-pack` และ `animation-library.json`
2. **REMOVE (ถอดถอนไฟล์ที่เกิดใหม่ใน 02/03 และไม่มี consumer):**
   - คอนโทรลเลอร์/เซอร์วิส R6: `src/client/character/R6ActionPoseController.luau`, `src/server/services/SkillMoveService.luau`
   - คอนฟิกท่า R6: `src/shared/configs/PlayerActionPoseConfigs.luau`
   - ไฟล์สำรองชั่วคราว: `src/client/controllers/InputController.luau.bak_fc27`, `src/server/services/BallService.luau.bak_fc27`
   - ไฟล์ทดสอบ 5 ไฟล์ที่สร้างขึ้นใน 02/03 (ระบุรายชื่อชัดเจน ไม่ใช้ wildcard): `tests/e2e/Tier1_AirLeanPhysics.luau`, `tests/e2e/Tier1_BallPopPhysics.luau`, `tests/e2e/Tier1_PlayerActions.luau`, `tests/e2e/Tier1_SkillMovesAndDefense.luau`, `tests/e2e/Tier1_StateJumpPhysics.luau`
3. **HUNK REMOVE (ถอดเฉพาะ Hunk ในไฟล์ร่วม):**
   - `src/server/services/BallService.luau`: ถอดเฉพาะ Hunk ของ 02/03 (possession loops, R6 pose hooks, FakeShot cancel, state jump, curve resolution) คงเรขาคณิตและการเชื่อมต่อ CagePhysics ไว้
   - `src/client/controllers/InputController.luau`: ถอด keybinds และ action mapping ของ 02/03 คืนสู่ baseline
   - `src/client/character/R6AnimationController.luau`: ถอดจุดเชื่อมต่อกับ `R6ActionPoseController`
   - `src/server/init.server.luau` & `src/client/init.client.luau`: ถอด bootstrap require/init ของเซอร์วิสที่ถูกถอดออก ไม่ให้มี Dead Require
   - `src/shared/Constants.luau`, `Network.luau`, `Types.luau`, `configs/RigAnimationConfigs.luau`: ถอดเฉพาะ constant, remote, และ type ของ 02/03
   - `tests/e2e/BundledTestRunner.luau`, `TestHarness.luau`, `TestRunner.luau`, `run_all.ps1`: ถอดการอ้างอิงถึง 5 ไฟล์ทดสอบที่ถูกลบ
4. **REPLACE (เตรียมทดแทนด้วย R15 Foundation):**
   - `src/shared/AirLeanSolver.luau`, `src/shared/JumpModel.luau`, `src/client/controllers/CameraShiftLockController.luau` (เก็บตรรกะคณิตศาสตร์ไว้ประยุกต์กับ R15)
5. **UNCERTAIN (ต้องสำรวจ Dependency ให้เสร็จสิ้นก่อนตัดสิน):**
   - `src/client/controllers/TrainingHUD.luau`, `src/client/controllers/DuelUIController.luau`, `src/client/ui/screens/DuelChoiceModal.luau`, `src/server/services/DuelEngineService.luau`, `src/shared/configs/AirLeanConfigs.luau`, `src/shared/configs/JumpConfigs.luau`, `src/shared/configs/SkillMoveConfigs.luau`

### 5.3 Execution & Model Policy
- **Docs-Only Gate:** รอบปัจจุบันเป็นการเตรียมเอกสาร Provisional Inventory เท่านั้น **ห้ามถอดโค้ดจริง, ห้ามแก้ Studio, และห้ามแก้ Git ในรอบนี้**
- **Worker Assignment:** ผู้รับหน้าที่ถอดโค้ดจริงในลำดับถัดไปคือ `agyanimation` โดยใช้โมเดล **3.8 Flash** เป็นหลักเมื่อยืนยัน pane identity แล้ว; โมเดล **Argon** จะถูกใช้เฉพาะกรณีติดขัดเชิงเทคนิคที่มีความซับซ้อนสูงและ Flash แสดงหลักฐานปัญหาชัดเจนเท่านั้น
- **Gate การลงมือ:** การถอดโค้ดจริงจะเกิดขึ้นได้ต่อเมื่อ Owner ตรวจรับและอนุมัติ Removal Manifest ที่สมบูรณ์แล้วอย่างเป็นทางการ
