# MASTER PROJECT BLUEPRINT, CODEX AUDIT REPORT & FULL IMPLEMENTATION GUIDE (`startprojects.md`)

เอกสารฉบับนี้คือ **Single Source of Truth & Active Remediation Guide (คัมภีร์หลักและใบสั่งแก้งานฉบับสมบูรณ์)** สำหรับโปรเจกต์ **`cage-zero`** หลังจากตรวจสอบซอร์สโค้ดและโครงสร้างทั้งหมดใน Commit ล่าสุด (`MODULE 00: run-01`)

ผลการตรวจสอบจาก **Chief Architect / Codex**: **`STATUS: REJECTED (ไม่ผ่านเกณฑ์ 5 ข้อใน Module 00 และยังเหลือ Module 01–08 ที่เป็นไฟล์ Stub ว่างเปล่า)`**

ให้ AI Agents (**Agy** และ **Codex**) อ่าน **ส่วนที่ 0 (รายการสั่งแก้ด่วนสำหรับ Module 00 `run-02`)** ทำการแก้ไขให้ผ่านเกณฑ์ ออกใบ `handoff.md` แล้ว **เดินหน้าเขียนโค้ดจริงของ Module 01 ถึง Module 08 ต่อเนื่องจนจบโปรเจกต์ตามรายละเอียดเชิงลึกในเอกสารนี้ทันที**

---

## ส่วนที่ 0: ผลการตรวจโค้ดจริงของ `cage-zero` (MODULE 00 `run-01` AUDIT & MANDATORY FIXES)

จากการตรวจสอบไฟล์ทั้งหมดในโปรเจกต์ `cage-zero` ที่ส่งมา พบว่า **Agy** เพิ่งทำเฉพาะ `MODULE 00` (`run-01`) ส่วนไฟล์ใน `MODULE 01` ถึง `MODULE 08` ยังเป็นเพียงไฟล์ Stub ว่างเปล่า (`MODULE_SCOPE = "..."`) และแม้แต่ใน **`MODULE 00` (`run-01`) เองก็มีบั๊กวิกฤตและจุดที่หลุดสเปก 5 รายการที่ต้องสั่งแก้ (`REJECTED`)** ดังนี้:

### รายการบั๊กที่ตรวจพบใน `MODULE 00` (`run-01`) และวิธีแก้ที่ถูกต้องสำหรับ `run-02`

| รหัสบั๊ก | ไฟล์ที่มีปัญหาและบรรทัดที่ผิด | สาเหตุของปัญหา (Root Cause) | คำสั่งแก้ไขบังคับสำหรับ Agy ใน `run-02` (Mandatory Fix) |
| :--- | :--- | :--- | :--- |
| **`[FIX-M00-01]`**<br>*(วิกฤต: โมเดลเบี้ยว & คอลอย)* | `src/server/services/RigAndCardService.luau`<br>*(บรรทัด 225 และ 253–295)* | 1. **Double Scaling Bug:** ใน `BuildStandardCustomR15Rig` ตั้งค่า `humanoid.AutomaticScalingEnabled = true` แล้วใน `ApplyCardScale` สั่งคูณ `Part.Size` และ `Motor6D.C0/C1` ด้วยมือ **แถมยัง** สร้าง `NumberValue` (`BodyHeightScale`, `BodyWidthScale` ฯลฯ) ลงใน `Humanoid` ซ้ำอีก ทำให้เอนจิน Roblox สเกลซ้อนเป็น 2 เด้ง (`scale^2`)<br>2. **Neck Joint Detachment Bug (บรรทัด 263–283):** ชิ้นส่วน `Head` ถูกสเกลด้วย `clampedHead` (`1.00`) แต่ข้อต่อ `Neck.C1` (ซึ่งเป็นจุดยึดฝั่ง `Part1 = Head`) กลับถูกคูณด้วย `scaleVec` (`clampedHeight` เช่น `1.08` ของ Vandik หรือ `0.92` ของ Leon) ทำให้หัวลอยหลุดจากคอในการ์ดตัวสูง และหัวจมลงไปในอกในการ์ดตัวเตี้ย! | 1. ใน `BuildStandardCustomR15Rig` ต้องตั้งค่า **`humanoid.AutomaticScalingEnabled = false`** เสมอ และห้ามสร้าง `BodyHeightScale` `NumberValue` ลงใน `Humanoid` (ให้เก็บเป็น Attribute บน `rigModel` และ `humanoid` แทน เพื่อไม่ให้ Roblox สเกลซ้อน)<br>2. ใน `ApplyCardScale` ตอนคำนวณ `Motor6D`:<br>- `inst.C0` ต้องคูณด้วย Scale ของ `inst.Part0`<br>- `inst.C1` ต้องคูณด้วย Scale ของ `inst.Part1` (หาก `Part1.Name == "Head"` ต้องใช้ `Vector3.new(clampedHead, clampedHead, clampedHead)` ห้ามใช้ `scaleVec` ของลำตัวเด็ดขาด!) |
| **`[FIX-M00-02]`**<br>*(วิกฤต: ตัวละครตายแล้วไม่เกิดใหม่ & ไม่เชื่อม Remote)* | `src/server/services/RigAndCardService.luau`<br>*(บรรทัด 303–375)* | 1. เมื่อตั้ง `Players.CharacterAutoLoads = false` เวลาตัวละครตกแมพหรือ `Humanoid.Died` ผู้เล่นจะค้างและไม่เกิดใหม่อีกเลย เพราะไม่ได้ผูก Event `humanoid.Died`<br>2. ไม่ได้ผูก `Network.GetRemoteEvent("InventoryEquipRequest")` สำหรับหมวด `"Card"` ทำให้เมื่อผู้เล่นขอเปลี่ยนการ์ดจาก Client ตัวละครไม่เปลี่ยนสัดส่วนจริง | 1. ใน `SpawnCustomRigForPlayer` ต้องผูก `humanoid.Died:Connect` เพื่อหน่วงเวลา `2.0 วินาที` แล้วเรียก `SpawnCustomRigForPlayer` ให้เกิดใหม่ด้วย Custom Rig อัตโนมัติ<br>2. เพิ่มฟังก์ชันเชื่อม `InventoryEquipRequest.OnServerEvent` เมื่อ `category == "Card"` ให้ตรวจสอบว่าการ์ดมีอยู่จริงใน `CardConfigs` แล้วเรียก `EquipCardForPlayer(player, itemId)` ทันที |
| **`[FIX-M00-03]`**<br>*(ผิดสเปก Data Schema)* | `src/shared/Types.luau`<br>*(บรรทัด 45–75)* | โครงสร้าง Type ใน `Types.luau` ตกหล่นฟิลด์บังคับจาก `docs/design/data-schema.md`:<br>1. `BattleThreadInstance` ขาดฟิลด์ `rarity: ThreadRarity` (`"Common" \| "Rare" \| "Epic" \| "Legendary"`)<br>2. `PlayerProfileData.ownedTraits` ถูกเขียนเป็น `{ string }` แทนที่จะเป็น `{ TraitStoneInstance }` ที่มี `traitUid: string` (ถ้าไม่มี UID เฉพาะชิ้น จะไม่สามารถอ้างอิง `itemUid` ในระบบเทรดป้องกันการปั๊มของได้)<br>3. ขาด Type `TradeSessionData`, `BoothListingData`, และ Payload Types ของ Network | อัปเดต `src/shared/Types.luau` ให้มีครบทุก Type ตาม `docs/design/data-schema.md`:<br>- เพิ่ม `export type ThreadRarity = "Common" \| "Rare" \| "Epic" \| "Legendary"`<br>- เพิ่ม `rarity: ThreadRarity` ใน `BattleThreadInstance`<br>- เพิ่ม `export type TraitStoneInstance = { traitUid: string, traitId: string, acquiredAt: number }`<br>- เปลี่ยน `ownedTraits: { TraitStoneInstance }` ใน `PlayerProfileData`<br>- เพิ่ม `TradeSessionData` และ `BoothListingData` ให้ครบถ้วน |
| **`[FIX-M00-04]`**<br>*(ช่องโหว่ Race Condition & Payload Validation)* | `src/shared/Network.luau`<br>*(บรรทัด 147–176)* | 1. บนฝั่ง Server หาก Service ใดเรียก `Network.GetRemoteEvent(name)` ก่อนที่ `Network.InitServer()` จะสร้างลูกครบ `getOrCreateRemotesFolder()` จะคืนโฟลเดอร์ว่าง ทำให้ `folder:FindFirstChild(def.name)` ได้ค่า `nil` และเกิด Error แครชทันที<br>2. ไม่มีฟังก์ชันช่วยตรวจสอบชนิดข้อมูล (`Payload Validators`) สำหรับป้องกัน Client ส่งค่า `NaN` หรือชนิดข้อมูลปลอมมาให้ Server | 1. ใน `Network.GetRemoteEvent` และ `Network.GetRemoteFunction` ฝั่ง Server หากยังไม่มี Remote ชื่อนั้นในโฟลเดอร์ ให้สร้าง `Instance.new(def.kind)` ให้อัตโนมัติทันที (Lazy Creation)<br>2. เพิ่มฟังก์ชัน `Network.IsFiniteVector3(v: any): boolean`, `Network.IsNonEmptyString(s: any, maxLen: number?): boolean`, และ `Network.IsNumberInRange(n: any, minVal: number, maxVal: number): boolean` สำหรับใช้ในทุก Server Service |
| **`[FIX-M00-05]`**<br>*(โครงสร้างโฟลเดอร์ไม่ครบ 100% ตามส่วนที่ 2)* | `docs/plan/`<br>*(ทุก Module `00` ถึง `08`)* | 1. ใน `docs/plan/00-bootstrap-and-rig/assets/runs/run-01/` ไม่มีโฟลเดอร์ `uat-images/` และ `fix-images/`<br>2. ใน `docs/plan/01-cage-physics/` ถึง `08-integration-and-uat/` มีแค่ `assets/` แต่ไม่มีโฟลเดอร์ `assets/runs/run-01/` (พร้อมไฟล์ตั้งต้นและโฟลเดอร์รูป) ตามที่กำหนดในแผนผังส่วนที่ 2 | 1. สร้างโฟลเดอร์ `uat-images/` และ `fix-images/` (ใส่ไฟล์ `.gitkeep` ไว้เพื่อให้ Git เก็บโฟลเดอร์เข้า Repo ได้) ในทุก `assets/runs/run-XX/` ของทุกโมดูล (`00` ถึง `08`)<br>2. บันทึกผลการตรวจรอบ `run-01` ของ Module 00 ว่า `REJECTED` ลงใน `run-01/review.md` และ `run-01/fix.md` จากนั้นเปิดโฟลเดอร์ `run-02/` แก้ไขทั้ง 5 ข้อให้ผ่าน แล้วออกใบ `handoff.md` (`STATUS: APPROVED & CLOSED`) เพื่อปลดล็อกไปทำ `MODULE 01` ทันที |

---

## ส่วนที่ 1: กฎเหล็กสำหรับ AI Agents (STRICT ANTI-DRIFT & ANTI-HALLUCINATION RULES)

AI Agent ทุกตัวที่เข้ามาทำงานในโปรเจกต์นี้ **ต้องปฏิบัติตามกฎเหล็ก 11 ข้อนี้แบบ 100%**:

1. **ห้ามทำข้าม Module เด็ดขาด (Sequential Module Lock):** ต้องทำงานทีละ Module ตามลำดับ (`00` -> `01` -> `02` -> ... -> `08`) ห้ามเขียนโค้ดของ Module ถัดไปจนกว่า Module ปัจจุบันจะมีไฟล์ `handoff.md` ที่ได้รับการอนุมัติ (`STATUS: APPROVED & CLOSED`) จาก **Codex** ในโฟลเดอร์ `assets/runs/run-XX/` รอบล่าสุด
2. **ห้ามใช้โมเดลอวาตารของผู้เล่น (No Player Avatar Models):** ตัวละครทุกตัวในสนามต้องใช้ **โครงกระดูกมาตรฐานเดียวของเกม (Single Custom R15 Rig)** เท่านั้น เพื่อให้ระบบอนิเมชันการดวลและท่าดีใจไม่เพี้ยน โดยตั้ง `Humanoid.AutomaticScalingEnabled = false` ปรับเฉพาะความสูง/สัดส่วน (`HeightScale`, `WidthScale`) ด้วยการคำนวณฝั่ง Server ที่ไม่ทำให้ข้อต่อ `Neck` หรือ `Motor6D` เพี้ยน และล็อกใบหน้าเป็นสไตล์อนิเมะของเกม
3. **ห้ามทำระบบรองเท้าสตั๊ด (No Boots/Cleats System):** ในสโคปนี้ **ตัดระบบรองเท้าสตั๊ดออกทั้งหมด** อุปกรณ์สวมใส่มีเพียงชุด **"Battle Threads"** เท่านั้น ห้ามแอบสร้างระบบรองเท้าเพิ่มเองเด็ดขาด
4. **ห้ามให้ Mutated Gear เพิ่มสเตตัสในสนาม (Zero Pay-to-Win Mutations):** ของกลายพันธุ์ (Mutated Gear) มีไว้เพื่อ **เพิ่มราคาขาย/มูลค่าการเทรด, แสดงเอฟเฟกต์ออร่าความเท่ (VFX), และสุ่มมอบบัฟคูณเงิน (Cash Multiplier) หรือคูณ EXP เท่านั้น** ห้ามเพิ่มความเร็ววิ่ง พลังยิง หรือโอกาสชนะดวลในสนามเด็ดขาด
5. **Trait และสกิลการันตี 100% ต้องมี Cooldown เสมอ:** สกิลพิเศษของนักเตะดังและ Trait การันตีผลลัพธ์ (เช่น เลี้ยงผ่าน 100%, ส่งถึงเพื่อน 100%, ยิงเข้า 100%, เกมรับดวลชนะ 100%) **ห้ามทำงานตลอดเวลา (Passive 100% ถาวร)** ทุกอันต้องมีระบบ Cooldown และเงื่อนไขสถานการณ์ที่ชัดเจน
6. **แยกบทบาท "การดวล 1v1 (Choice Duel)" กับ "การตัดบอลส่ง (Parry)" ออกจากกันอย่างชัดเจน:**
   - **การดวล 1v1 (Choice Duel):** เกิดขึ้นเฉพาะเมื่อผู้ถือบอลเข้าประชิดกองหลังในระยะที่กำหนด (`<= 6 Studs`) หน้าจอจะสโลว์โมชันและขึ้นปุ่ม Choice ให้ทั้ง 2 ฝ่ายกดเลือก (ฝั่งกองหลังจะมี Choice `Shot Block` เฉพาะในหน้าจอดวลนี้เท่านั้น)
   - **การตัดบอลส่ง/ลูกยิงผ่านทาง (Parry System):** เมื่อลูกบอลถูกเตะส่งหรือยิงพุ่งผ่านโซนรอบตัวกองหลัง (`<= 5 Studs`) **จะไม่ตัดเข้าหน้าจอดวล** แต่ให้กองหลังกดปุ่ม `Parry / Intercept` ให้ตรงจังหวะเสี้ยววินาที (`0.35 วินาที`) เพื่อสกัดบอล
7. **ปุ่ม Choice "ยิงฉับพลัน (Snap Shot)" ต้องเช็กระยะยิงเสมอ:** ผู้เล่นฝ่ายรุกจะเห็นและกดเลือกชอยส์ยิงในการดวลได้ **ก็ต่อเมื่ออยู่ในระยะยิงที่ระบบกำหนด (Shooting Zone)** เท่านั้น ห้ามให้กดยิงจากแดนตัวเองได้
8. **อนิเมชันดวลชนะมีได้ไม่เกิน 3 ท่าตาม Tier:** ตัวละครแต่ละตัวมีอนิเมชันคัตซีนตอนดวลชนะ (เช่น ซูมมุมกล้องเบียวๆ แตะลอดดากสโลว์โมชัน, Rainbow Flick, Elastico) ได้สูงสุดไม่เกิน 3 ท่าตามระดับ Tier ของการ์ด (`B = 1`, `A = 2`, `S = 3`) และเน้นความเท่/Easter Egg แทนการอัดสเตตัสเว่อร์เกินจริง
9. **ระบบ UI ต้องควบคุมด้วย `UIManager` ตัวเดียว (Single UI Router Rule):** หน้าจอทั้งหมดต้องเชื่อมโยงกันผ่าน State Machine ของ `UIManager.luau` ห้ามเปิดหน้าต่างซ้อนทับกันมั่ว (เช่น เมื่อเข้าสู่สถานะ `MATCH_MODE` ต้องซ่อน UI ของ Lobby ทั้งหมดทันที และเมื่อเปิด `DuelChoiceModal` ต้องซ่อนปุ่มควบคุมทั่วไปชั่วคราว)
10. **เก็บหลักฐานเฉพาะสิ่งสำคัญ (Clean Assets Policy):** ห้ามเก็บ Log ขยะหรือประวัติ Commit ย่อยทุกบรรทัด ให้บันทึกเฉพาะ Commit หลักตอนจบงานลงใน `assets/milestones.md` และเก็บรูป/ผลเทสต์แยกตามรอบ `assets/runs/run-XX/` เท่านั้น
11. **Server-Authoritative 100%:** การคำนวณผลแพ้-ชนะในการดวล, ระยะยิง, คูลดาวน์ของ Trait, ฟิสิกส์ลูกบอล, การสุ่มกาชา และการเทรดของ ต้องคำนวณและตรวจสอบฝั่ง Server เสมอ ห้ามเชื่อค่าที่ส่งมาจาก Client โดยไม่ตรวจสอบ

---

## ส่วนที่ 2: โครงสร้างโฟลเดอร์มาตรฐาน (MASTER DIRECTORY ARCHITECTURE)

เมื่อแก้ไขโปรเจกต์ **Agy** ต้องตรวจสอบให้แน่ใจว่ามีโครงสร้างโฟลเดอร์และไฟล์ครบถ้วนตามแผนผังนี้ (ใช้ไฟล์ `.gitkeep` ในโฟลเดอร์รูปที่ยังว่างเพื่อให้ Git Track โฟลเดอร์ครบ 100%):

```text
├── agent.md                                    # กฎเหล็ก บทบาทหน้าที่ และตัวชี้ตำแหน่ง Module ปัจจุบัน
├── default.project.json                        # ไฟล์ตั้งค่า Rojo สำหรับเชื่อมโค้ดเข้า Roblox Studio
├── startprojects.md                            # คัมภีร์หลักฉบับนี้
├── docs/
│   ├── context/
│   │   ├── vision.md                           # ภาพรวมเกม แกนหลัก และกฎการออกแบบ
│   │   └── glossary.md                         # นิยามคำศัพท์ในโปรเจกต์ (Battle Threads, Parry, Choice Duel ฯลฯ)
│   ├── prd/
│   │   └── product-requirements.md             # ข้อกำหนดฟีเจอร์และเป้าหมายผู้เล่น
│   ├── specs/
│   │   ├── spec-01-cage-and-events.md          # สเปกสนามกรง 5 มิติ และอีเวนต์ทั้ง 3 แบบ
│   │   ├── spec-02-duel-and-parry.md           # สเปกดวล 1v1 Choice, ตำแหน่ง, ข้อผิดพลาด และ Parry
│   │   ├── spec-03-cards-rig-freekick.md       # สเปกการ์ดนักเตะ, Custom Rig, อนิเมชันเบียว และฟรีคิก FC27
│   │   ├── spec-04-traits-threads-economy.md   # สเปก Trait, ชุด Battle Threads, Mutated Gear และระบบเทรด
│   │   └── spec-05-ui-navigation-and-hud.md    # สเปกการเชื่อมหน้าจอ UI ทั้งหมด, Flow การเปลี่ยนหน้า และ HUD
│   ├── design/
│   │   ├── architecture-and-network.md         # โครงสร้าง Client-Server, RemoteEvents, State Machine
│   │   ├── ui-state-and-routing.md             # ผังการเชื่อมหน้าจอ UI (Screen Router & Modal Stack)
│   │   └── data-schema.md                      # โครงสร้างข้อมูลผู้เล่น การ์ด ชุด และตลาดแลกเปลี่ยน
│   ├── tdd/
│   │   └── master-test-cases.md                # เกณฑ์การทดสอบทั้งหมดที่ Codex ใช้ตรวจรับงาน
│   └── plan/
│       ├── roadmap.md                          # แผนผังลำดับการพัฒนาทั้ง 9 Modules (00 ถึง 08)
│       ├── 00-bootstrap-and-rig/               # [Module 00] โครงสร้างโปรเจกต์ & Custom Rig มาตรฐานเดียว
│       │   ├── plan.md
│       │   ├── tasks.md
│       │   ├── notes.md
│       │   └── assets/
│       │       ├── milestones.md
│       │       └── runs/
│       │           ├── run-01/                 # รอบแรก (ถูก REJECTED จาก 5 จุดในส่วนที่ 0)
│       │           │   ├── review.md
│       │           │   ├── fix.md
│       │           │   ├── result.md
│       │           │   ├── handoff.md
│       │           │   ├── uat-images/
│       │           │   └── fix-images/
│       │           └── run-02/                 # รอบแก้ไข (เมื่อแก้ครบ 5 จุดแล้วให้ Codex อนุมัติที่นี่)
│       │               ├── review.md
│       │               ├── fix.md
│       │               ├── result.md
│       │               ├── handoff.md
│       │               ├── uat-images/
│       │               └── fix-images/
│       ├── 01-cage-physics/                    # [Module 01] สนามกรง 5 มิติ & ฟิสิกส์การชิ่งกำแพง/เพดาน
│       │   ├── plan.md
│       │   ├── tasks.md
│       │   ├── notes.md
│       │   └── assets/
│       │       ├── milestones.md
│       │       └── runs/
│       │           └── run-01/
│       │               ├── review.md
│       │               ├── fix.md
│       │               ├── result.md
│       │               ├── handoff.md
│       │               ├── uat-images/
│       │               └── fix-images/
│       ├── 02-ball-control-and-parry/          # [Module 02] ระบบเลี้ยง ส่ง ยิง & ระบบกองหลัง Parry
│       │   ├── plan.md
│       │   ├── tasks.md
│       │   ├── notes.md
│       │   └── assets/
│       │       ├── milestones.md
│       │       └── runs/
│       │           └── run-01/
│       ├── 03-duel-choice-engine/              # [Module 03] ระบบดวล 1v1 Choice, ตำแหน่ง & ข้อผิดพลาด
│       │   ├── plan.md
│       │   ├── tasks.md
│       │   ├── notes.md
│       │   └── assets/
│       │       ├── milestones.md
│       │       └── runs/
│       │           └── run-01/
│       ├── 04-cards-animations-freekick/       # [Module 04] การ์ดนักเตะหลาย Tier, อนิเมชันเบียว & ฟรีคิก FC27
│       │   ├── plan.md
│       │   ├── tasks.md
│       │   ├── notes.md
│       │   └── assets/
│       │       ├── milestones.md
│       │       └── runs/
│       │           └── run-01/
│       ├── 05-dynamic-match-events/            # [Module 05] 3 อีเวนต์สนาม (เสาขวาง, หลุมดำ, สตรีทบราซิล)
│       │   ├── plan.md
│       │   ├── tasks.md
│       │   ├── notes.md
│       │   └── assets/
│       │       ├── milestones.md
│       │       └── runs/
│       │           └── run-01/
│       ├── 06-traits-threads-economy/          # [Module 06] Trait มีคูลดาวน์, Battle Threads & Mutated Gear
│       │   ├── plan.md
│       │   ├── tasks.md
│       │   ├── notes.md
│       │   └── assets/
│       │       ├── milestones.md
│       │       └── runs/
│       │           └── run-01/
│       ├── 07-ui-navigation-and-screens/       # [Module 07] ระบบ UI ทั้งหมด การเชื่อมหน้าจอ Lobby, HUD & ร้านค้า
│       │   ├── plan.md
│       │   ├── tasks.md
│       │   ├── notes.md
│       │   └── assets/
│       │       ├── milestones.md
│       │       └── runs/
│       │           └── run-01/
│       └── 08-integration-and-uat/             # [Module 08] เชื่อมต่อทุกระบบ ทดสอบสมดุล & ปิดโปรเจกต์
│           ├── plan.md
│           ├── tasks.md
│           ├── notes.md
│           └── assets/
│               ├── milestones.md
│               └── runs/
│                   └── run-01/
└── src/
    ├── client/
    │   ├── init.client.luau
    │   ├── controllers/
    │   │   ├── InputController.luau
    │   │   ├── CameraCutsceneController.luau
    │   │   ├── DuelUIController.luau
    │   │   ├── FreeKickUIController.luau
    │   │   ├── ParryIndicatorController.luau
    │   │   └── EventVFXController.luau
    │   └── ui/
    │       ├── UIManager.luau
    │       ├── UITheme.luau
    │       ├── components/
    │       │   ├── TopCurrencyBar.luau
    │       │   ├── NavigationDock.luau
    │       │   ├── ItemCardSlot.luau
    │       │   ├── CooldownRingButton.luau
    │       │   └── ToastNotification.luau
    │       └── screens/
    │           ├── MainMenuScreen.luau
    │           ├── ModeSelectScreen.luau
    │           ├── PreMatchLobbyScreen.luau
    │           ├── LockerScreen.luau
    │           ├── SummonGachaScreen.luau
    │           ├── TradingPlazaScreen.luau
    │           ├── MatchHUDScreen.luau
    │           ├── DuelChoiceModal.luau
    │           ├── ParryPromptOverlay.luau
    │           ├── FreeKickOverlay.luau
    │           └── PostMatchSummaryScreen.luau
    ├── server/
    │   ├── init.server.luau
    │   └── services/
    │       ├── MatchService.luau
    │       ├── CagePhysicsService.luau
    │       ├── BallService.luau
    │       ├── DuelEngineService.luau
    │       ├── ParryService.luau
    │       ├── FreeKickService.luau
    │       ├── EventManagerService.luau
    │       ├── RigAndCardService.luau
    │       ├── TraitAndThreadService.luau
    │       └── TradeMarketService.luau
    └── shared/
        ├── Constants.luau
        ├── Types.luau
        ├── Network.luau
        └── configs/
            ├── CardConfigs.luau
            ├── ChoiceConfigs.luau
            ├── TraitConfigs.luau
            ├── ThreadConfigs.luau
            └── EventConfigs.luau
```

---

## ส่วนที่ 3: ขั้นตอนการทำงานต่อเนื่องระหว่าง `Agy` และ `Codex` (CONTINUOUS EXECUTION PROTOCOL)

เพื่อให้โปรเจกต์เดินหน้าตั้งแต่แก้ `Module 00 (run-02)` ไปจนจบ `Module 08` โดยไม่หยุดค้างกลางคัน ให้ทำงานตามลำดับดังนี้:

1. **เฟสแก้ไข `Module 00` (`run-02`):**
   - บันทึกผลตรวจที่ตกใน `docs/plan/00-bootstrap-and-rig/assets/runs/run-01/review.md` (`STATUS: REJECTED`) และ `fix.md` (ระบุ `FIX-M00-01` ถึง `FIX-M00-05`)
   - สร้างโฟลเดอร์ `docs/plan/00-bootstrap-and-rig/assets/runs/run-02/`
   - **Agy** แก้ไขโค้ด `RigAndCardService.luau`, `Types.luau`, `Network.luau` และสร้างโฟลเดอร์ `uat-images/` / `fix-images/` ให้ครบทุกโมดูล
   - **Codex** ตรวจสอบ `run-02` เมื่อผ่านครบทุกข้อ ให้ออกใบ `handoff.md` (`STATUS: APPROVED & CLOSED`) อัปเดต `milestones.md` และเปลี่ยน `ACTIVE_MODULE` ใน `agent.md` เป็น `01-cage-physics`
2. **เฟสพัฒนาต่อเนื่อง `Module 01` ถึง `Module 08`:**
   - ในแต่ละ Module ให้ **Agy** อ่านสเปกและพิมพ์เขียวโค้ดใน **ส่วนที่ 4 และ ส่วนที่ 5** ของเอกสารนี้ เขียนโค้ดจริง (ห้ามใส่แค่ Stub ว่างๆ!) อัปเดต `tasks.md` เป็น `[x]` และเขียนสรุปใน `assets/runs/run-01/result.md`
   - ทันทีที่ **Agy** ทำจบแต่ละ Module ให้ **Codex** เข้ามาตรวจโค้ดจริงเทียบกับ `docs/tdd/master-test-cases.md` ทันที:
     - หากพบจุดผิด ให้สั่งแก้ใน `fix.md` และเปิด `run-02` แก้จนกว่าจะผ่าน
     - หากผ่านครบ 100% ให้เขียน `review.md` (`STATUS: APPROVED`), ออกใบ `handoff.md` (`STATUS: APPROVED & CLOSED`), อัปเดต `milestones.md` และขยับ `ACTIVE_MODULE` ใน `agent.md` ไปยัง Module ถัดไปทันที จนจบ `MODULE 08`

---

## ส่วนที่ 4: รายละเอียดสเปกเกมและอัลกอริทึมเชิงลึก (COMPLETE TECHNICAL & GAMEPLAY SPECIFICATIONS)

### 4.1 สเปกสนามกรง 5 มิติ และสมการฟิสิกส์ (`CagePhysicsService.luau`)
1. **เรขาคณิตสนามกรง 6 เหลี่ยม (`Hex-Cage 3D`):**
   - จุดศูนย์กลางสนามอยู่ที่ `Vector3.new(0, 0, 0)`, รัศมีสนามตามยาว (`Z-Axis`) `120 Studs`, ตามกว้าง (`X-Axis`) `80 Studs`, ความสูงเพดานตาข่าย `32 Studs`
   - ผนังทั้ง 6 ด้านทำมุมสะท้อนเข้าหากลางสนาม พร้อมเพดานตาข่ายด้านบน (`CeilingNormal = Vector3.new(0, -1, 0)`)
   - จุดมาร์กมุมชิ่ง (`Rebound Markers`): วางไว้ที่กึ่งกลางผนังเฉียงทั้ง 4 มุม และบนเพดานหน้ากรอบเขตโทษ 2 จุด
2. **สมการการสะท้อนเวกเตอร์ (`Rebound Vector Math`):**
   - เมื่อลูกบอลที่มีความเร็ว $\vec{V}$ ชนพื้นผิวที่มี Normal Vector $\vec{N}$ (ขนาด 1 หน่วย):
     $$\vec{V}_{\text{reflected}} = \left(\vec{V} - 2(\vec{V} \cdot \vec{N})\vec{N}\right) \times e$$
   - ค่าสัมประสิทธิ์การสะท้อน ($e$):
     - ผนังกรงมาตรฐานและเพดาน: $e = 0.88$
     - แผงดีดมุมกรง (`Pinball Bumpers`): $e = 1.25$ (ตาม `Constants.BUMPER_RESTITUTION` จำกัดความเร็วสูงสุดหลังดีดไม่เกิน `180 Studs/s` เพื่อป้องกันลูกบอลทะลุกำแพง)
     - เสาคอนกรีตในอีเวนต์ `Pillar Lockdown`: $e = 1.00$
3. **พื้นที่หลังโกล 360° (`360° Goal Zone`):**
   - ประตูทั้งสองฝั่งตั้งอยู่ที่ `Z = -106` และ `Z = +106` โดยผนังหลังกรงอยู่ที่ `Z = -120` และ `Z = +120` (เว้นระยะหลังโกล `14 Studs` ตาม `Constants.GOAL_BACK_ZONE_STUDS`)
   - ด้านหลังโกลเป็นกำแพงทึบที่ผู้เล่นสามารถเลี้ยงบอลอ้อมหลังประตู หรือเตะอัดผนังหลังโกลให้เด้งกลับมาหน้าปากประตูได้
4. **ทางลาดริมเส้น (`Elevating Ramps`):**
   - วางอยู่ริมเส้นซ้าย (`X = -72`) และขวา (`X = +72`) เอียงทำมุม `25 องศา` (`Constants.ELEVATING_RAMP_ANGLE_DEG`)
   - เมื่อผู้เล่นหรือลูกบอลเคลื่อนที่ผ่านโซนทางลาดแล้วกดส่ง/เตะ ระบบจะบวกแรงยกตัวแนวดิ่ง `UpwardImpulse = math.sin(math.rad(25)) * horizontalSpeed + 38` เพื่อให้ลูกลอยโด่งเข้ากลางสนาม

### 4.2 สเปก 3 อีเวนต์เปลี่ยนสภาพสนามกลางแมตช์ (`EventManagerService.luau` & `EventVFXController.luau`)
- วงจรเวลา: สุ่มเกิดทุกๆ `90 วินาที` (`MATCH_EVENT_INTERVAL_SEC`), แจ้งเตือนล่วงหน้า (`Warning State`) และคงอยู่นาน `40 วินาที` (`MATCH_EVENT_DURATION_SEC`) ก่อนคืนค่าสนามกลับสู่ปกติ (`Ended State`)
1. **`PillarLockdown` (เสาโผล่ขวางสนาม):**
   - สุ่มตำแหน่งเสา 3 ต้นจากพิกัดยุทธศาสตร์ (หน้ากรอบเขตโทษซ้าย/ขวา และกลางสนาม)
   - ส่ง `MatchEventBroadcast("PillarLockdown", "Warning", { positions = ... })` แสดงวงเตือนสีแดงบนพื้นนาน `1.5 วินาที` (`PILLAR_WARNING_LEAD_SEC`)
   - เมื่อเข้าสถานะ `"Active"` ดันเสาคอนกรีตขนาด `Vector3.new(6, 28, 6)` ขึ้นมาจากพื้น มี Tag `"ReboundPillar"` ที่สะท้อนลูกบอลด้วย $e = 1.00$
2. **`BlackoutVoid` (หลุมดำมืดมิด):**
   - เมื่อเข้าสถานะ `"Active"` สั่ง `EventVFXController` ปรับผนังกรง เพดาน และพื้นรอบนอกให้มืดสนิท (`Wall.Transparency = 1`, `Lighting.FogEnd = 90`, `Lighting.FogColor = Color3.new(0, 0, 0)`)
   - เปิด `Highlight` และวัสดุ `Enum.Material.Neon` เฉพาะที่ **เสาโกลทั้ง 2 ฝั่ง, ลูกบอล, และตัวละครผู้เล่นทุกคน** (Hitbox ของกำแพงกรงยังคงสะท้อนลูกบอลตามปกติ 100%)
3. **`FavelaAlley` (ตรอกสลัมบราซิล):**
   - สลับฉากขอบกรงเป็นกำแพงสังกะสีบราซิล และสร้างข้อมูลเส้นทางเดินของ NPC คนเดินผ่าน (`Pedestrians`) จำนวน `3 ตัว` บน Server
   - ตำแหน่งของ NPC คำนวณด้วยฟังก์ชันเชิงเส้นตามเวลา Server (`pos = startPos:Lerp(endPos, alpha)`) ทำให้ทั้ง Server (`CagePhysicsService` สำหรับเช็กการชนชิ่งบอล) และ Client (`EventVFXController` สำหรับแสดงโมเดล Low-Poly) เห็นตำแหน่งเดียวกันเป๊ะทุกเฟรมโดยไม่ต้องส่ง Packet ถี่ๆ

### 4.3 สเปกระบบครองบอล, ระยะยิง, ระบบ Parry เสี้ยววินาที และการดวล 1v1 Choice
1. **การตรวจสอบระยะยิง (`Shooting Zone Check`):**
   - สำหรับผู้เล่นทีมบุกฝั่งใต้ (บุกไปทาง `+Z`): อยู่ใน `Shooting Zone` เมื่อ `ballPosition.Z >= 10` (เข้าเขตแดนคู่แข่ง)
   - สำหรับผู้เล่นทีมบุกฝั่งเหนือ (บุกไปทาง `-Z`): อยู่ใน `Shooting Zone` เมื่อ `ballPosition.Z <= -10`
   - สำหรับโหมด `1v1v1 King of the Cage` (โกลกลาง): อยู่ใน `Shooting Zone` เมื่อระยะห่างจากโกลกลาง `<= 55 Studs`
2. **ระบบกองหลังกด Parry สกัดลูกส่ง/ลูกยิง (`ParryService.luau`):**
   - ทำงานเฉพาะเมื่อลูกบอล **ไม่มีคนถือครอง (`Possessor == nil`)** และกำลังเคลื่อนที่ด้วยความเร็วหลังถูกส่งหรือยิง เข้ามาในรัศมี `<= 5.0 Studs` (`PARRY_INTERCEPT_RADIUS_STUDS`) ของผู้เล่นฝ่ายรับ
   - **ห้ามตัดเข้าหน้าจอดวล 1v1 เด็ดขาด!**
   - Server บันทึกเวลาเริ่มต้น `windowStartTime = os.clock()` และส่ง `ParryWindowTrigger` ไปยัง Client ของกองหลังคนนั้น (หน้าต่างเวลานาน `0.35 วินาที` ตาม `PARRY_WINDOW_DURATION_SEC`)
   - เมื่อกองหลังกดปุ่ม Parry (`ParryAttemptRequest`):
     - หาก `os.clock() - windowStartTime <= 0.35` และกองหลังไม่ติดสถานะคูลดาวน์: **Perfect Parry!** กองหลังตัดบอลมาครองที่เท้าทันที (`BallService.SetPossessor(defender)`)
     - หากกดช้าเกิน `0.35 วินาที` หรือกดก่อนมีสัญญาณ: **Missed Parry!** กองหลังติดสถานะ `MissedSlideRecovery` นาน `0.50 วินาที` (`PARRY_MISS_RECOVERY_SEC`) ซึ่งจะกลายเป็นโทษ `Mistake` หากถูกเข้าดวลต่อทันที
3. **ระบบดวล 1v1 Choice (`DuelEngineService.luau` & `ChoiceConfigs.luau`):**
   - ทำงานเมื่อผู้ถือบอล (`Attacker`) เข้าใกล้ผู้เล่นฝ่ายรับ (`Defender`) ในระยะ `<= 6.0 Studs` (`CHOICE_DUEL_TRIGGER_DISTANCE_STUDS`)
   - **การคัดกรองปุ่ม Choice ตามตำแหน่งและเงื่อนไข:**
     - `Forward`: `{"SpeedBurst", "TechNutmeg", "QuickPass", "SnapShot", signatureChoiceId}`
     - `Midfielder`: `{"ThroughPass", "WallBouncePass", "LobPass", "BodyFeint", "SnapShot", signatureChoiceId}`
     - `Defender` (เฉพาะในหน้าจอดวล 1v1 นี้เท่านั้น): `{"HardTackle", "JockeyIntercept", "ShotBlock", signatureDefChoiceId}`
   - **การล็อกปุ่ม (`lockedChoices`) และลดเวลาจาก `Mistake Mechanics`:**
     - หากอยู่นอก `Shooting Zone`: เพิ่ `"SnapShot"` เข้าไปใน `lockedChoices` (ห้ามกดยิงเด็ดขาด!)
     - หาก `Signature Choice` ของการ์ดยังติด Cooldown: เพิ่ม `signatureChoiceId` เข้าไปใน `lockedChoices`
     - หากฝ่ายรุกติด Mistake (`Stamina < 15%`, `BadFirstTouch`, หรือ `SharpTurnOffBalance`): ลดเวลาเลือกจาก `0.80 วิ` เหลือ `0.45 วิ` (`CHOICE_DUEL_MISTAKE_WINDOW_SEC`) และเพิ่ม `"TechNutmeg"` / `"BodyFeint"` เข้าไปใน `lockedChoices`
     - หากฝ่ายรับติด Mistake (`MissedSlideRecovery`, `BackTurned`, หรือ `SprintOvershoot`): เพิ่ม `"JockeyIntercept"` เข้าไปใน `lockedChoices`
   - **ตารางตัดสินผลแพ้-ชนะ (`ChoiceConfigs.ResolveDuel`):**
     - `Signature Choice` (เมื่อไม่ติด Cooldown):
       - `"PhantomLaPulga"` (Leon Tier S): ชนะเกมรับปกติ 100% + มอบบัฟ `ZoneFocus` (`+35%` ส่งและยิง นาน `4 วินาที`)
       - `"KnuckleEmperor"` (Ronan Tier S): เมื่ออยู่ในระยะยิง ชนะ `"ShotBlock"` 100% และยิงพุ่งเข้ากรอบทันที
       - `"SambaIllusion"` (Ney Tier S): ชนะเกมรับปกติ 100% + ทำให้กองหลังติด Stun ลุกช้าลง `1.0 วินาที`
       - `"ColossusWall"` (Vandik Tier S - ฝั่งรับ): ชนะชอยส์เลี้ยงและยิงปกติของฝ่ายรุก 100% แย่งบอลมาครองทันที
     - ชอยส์มาตรฐาน:
       - `SpeedBurst` ชนะ `JockeyIntercept` และ `ShotBlock`, แพ้ `HardTackle`
       - `TechNutmeg` / `BodyFeint` ชนะ `HardTackle` และ `ShotBlock`, แพ้ `JockeyIntercept`
       - `QuickPass` / `WallBouncePass` / `LobPass` ชนะ `HardTackle` และ `ShotBlock`, แพ้ `JockeyIntercept`
       - `ThroughPass` ชนะ `ShotBlock` และ `HardTackle`, แพ้ `JockeyIntercept`
       - `SnapShot` (เฉพาะในระยะยิง) ชนะ `HardTackle` และ `JockeyIntercept`, แพ้ `ShotBlock`
       - กรณีเลือกชอยส์ชนกันหรือหมดเวลา: หากฝ่ายรุกติด Mistake ฝ่ายรับชนะทันที มิฉะนั้นคำนวณจากสเตตัสการ์ด (ซึ่งต่างกันไม่เกิน 15%)

---

## ส่วนที่ 5: พิมพ์เขียวโค้ดและการแก้ไขรายโมดูล (HAND-HOLDING CODE BLUEPRINTS FOR MODULES 00–08)

### 5.1 พิมพ์เขียวการแก้ `MODULE 00` (`run-02`) ให้ผ่าน 100%

#### 1) แก้ไข `src/shared/Types.luau` ให้ครบตาม Data Schema:
ต้องมี Type ครบตามรายการนี้:
```luau
--!strict
export type PlayerPosition = "Forward" | "Midfielder" | "Defender"
export type DuelRole = "Attacker" | "Defender"
export type CardTier = "B" | "A" | "S"
export type ThreadRarity = "Common" | "Rare" | "Epic" | "Legendary"
export type BallActionType = "Pass" | "Shoot" | "Sprint"
export type FreeKickTimingZone = "Green" | "Yellow" | "Red"
export type MatchEventType = "PillarLockdown" | "BlackoutVoid" | "FavelaAlley"
export type MatchEventState = "Warning" | "Active" | "Ended"
export type InventoryCategory = "Card" | "Thread" | "Trait" | "Celebration"
export type SummonCount = number
export type TradeActionType = "AddItem" | "LockOffer" | "ConfirmTrade" | "Cancel"
export type TradeStatus = "Active" | "Locked" | "Completed" | "Cancelled"
export type UIMode = "MAIN_MENU" | "LOBBY_MODE" | "MATCH_MODE"
export type MutationType = "GoldenAura" | "VoidGlitch" | "BloodMoonFlame"

export type RigScaleConfig = {
	heightScale: number,
	widthScale: number,
	headScale: number,
	depthScale: number,
	proportionScale: number,
}

export type StatModifiers = {
	speedMultiplier: number,
	shotMultiplier: number,
	passMultiplier: number,
	tackleMultiplier: number,
}

export type PlayerCardConfig = {
	cardId: string,
	displayName: string,
	archetypeName: string,
	tier: CardTier,
	defaultPosition: PlayerPosition,
	rigScale: RigScaleConfig,
	statModifiers: StatModifiers,
	signatureChoiceId: string,
	signatureCooldownSec: number,
	winCutsceneAnimIds: { string },
	celebrationAnimId: string,
}

export type MutationData = {
	mutationType: MutationType,
	vfxId: string,
	cashMultiplier: number,
	expMultiplier: number,
	tradeValueBonus: number,
}

export type BattleThreadInstance = {
	threadUid: string,
	threadConfigId: string,
	rarity: ThreadRarity,
	maxTraitSlots: number,
	equippedTraitIds: { string },
	mutation: MutationData?,
}

export type TraitStoneInstance = {
	traitUid: string,
	traitId: string,
	acquiredAt: number,
}

export type ObtainedItem = {
	itemUid: string,
	category: InventoryCategory,
	configId: string,
	tierOrRarity: string,
}

export type TradeSessionData = {
	tradeId: string,
	initiatorUserId: number,
	partnerUserId: number,
	initiatorOfferUids: { string },
	partnerOfferUids: { string },
	initiatorLocked: boolean,
	partnerLocked: boolean,
	lockTimestamp: number?,
	initiatorConfirmed: boolean,
	partnerConfirmed: boolean,
	status: TradeStatus,
}

export type BoothListingData = {
	listingId: string,
	sellerUserId: number,
	itemUid: string,
	category: InventoryCategory,
	priceCash: number,
}

export type PlayerProfileData = {
	userId: number,
	cash: number,
	level: number,
	exp: number,
	pityCounter: number,
	equippedCardId: string,
	equippedThreadUid: string?,
	equippedCelebrationId: string,
	ownedCards: { string },
	ownedThreads: { BattleThreadInstance },
	ownedTraits: { TraitStoneInstance },
}

local Types = {}
return table.freeze(Types)
```

#### 2) แก้ไข `src/server/services/RigAndCardService.luau` (แก้ Double-Scaling, แก้คอลอย `Neck.C1`, เพิ่มระบบเกิดใหม่อัตโนมัติ และเชื่อม `InventoryEquipRequest`):
- ใน `BuildStandardCustomR15Rig`:
  - ตั้งค่า **`humanoid.AutomaticScalingEnabled = false`** (สำคัญมาก! เพื่อไม่ให้ Roblox สเกลซ้อนทับกับลอจิก `ApplyCardScale` ของเรา)
- ใน `ApplyCardScale(rigModel: Model, cardId: string?)`:
  - กำหนดฟังก์ชันหา Scale Vector ของแต่ละชิ้นส่วน:
    ```luau
    local bodyScaleVec = Vector3.new(clampedWidth, clampedHeight, clampedDepth)
    local headScaleVec = Vector3.new(clampedHead, clampedHead, clampedHead)
    local function getScaleVecForPart(part: BasePart?): Vector3
        if part and part.Name == "Head" then
            return headScaleVec
        end
        return bodyScaleVec
    end
    ```
  - ตอนอัปเดต `Motor6D`:
    ```luau
    inst.C0 = scaleCFrameOffset(baseC0, getScaleVecForPart(inst.Part0))
    inst.C1 = scaleCFrameOffset(baseC1, getScaleVecForPart(inst.Part1))
    ```
    วิธีนี้ทำให้ `Neck.C0` (ซึ่งอยู่บน `UpperTorso`) สเกลตามความสูงลำตัว (`bodyScaleVec`) และ `Neck.C1` (ซึ่งอยู่บน `Head`) สเกลตามขนาดหัว (`headScaleVec`) คอจึงแนบสนิทพอดี 100% ทุกส่วนสูง (`0.92` ถึง `1.08`)!
  - บันทึกค่าสเกลเป็น Attribute บน `humanoid` (`humanoid:SetAttribute("BodyHeightScale", clampedHeight)` ฯลฯ) แทนการสร้าง `NumberValue` ที่ไปกระตุ้นเอนจิน Roblox
- ใน `SpawnCustomRigForPlayer`:
  - ผูก `humanoid.Died:Connect` เพื่อเรียก `task.delay(2.0, ...)` ให้ตัวละครเกิดใหม่เป็น Custom Rig เสมอ
- ใน `RigAndCardService.Init()`:
  - ผูก `Network.GetRemoteEvent("InventoryEquipRequest").OnServerEvent` เมื่อ `category == "Card"` ให้เรียก `RigAndCardService.EquipCardForPlayer(player, itemId)`

---

### 5.2 พิมพ์เขียวการพัฒนา `MODULE 01` ถึง `MODULE 08` (ห้ามปล่อยเป็น Stub เด็ดขาด)

เมื่อปิด `MODULE 00` (`run-02`) แล้ว ให้ **Agy** และ **Codex** ไล่ทำทีละโมดูลตามรายละเอียดต่อไปนี้:

1. **`MODULE 01: 01-cage-physics` (`src/server/services/CagePhysicsService.luau`):**
   - สร้างฟังก์ชัน `BuildHexCageArena(parent: Instance?): Model` สร้างสนามกรง 6 เหลี่ยม 3 มิติ ประกอบด้วย:
     - พื้นสนาม (`CageFloor`), ผนังตาข่าย 6 ด้าน (`HexWall_1` ถึง `HexWall_6`), เพดานตาข่าย (`CageCeiling`)
     - แผงดีดมุมกรง 4 จุด (`PinballBumper_1` ถึง `PinballBumper_4` ตั้งค่า Attribute `Restitution = 1.25`)
     - จุดมาร์กมุมชิ่งเรืองแสง 6 จุด (`ReboundMarker_1` ถึง `ReboundMarker_6`)
     - ประตู 2 ฝั่ง (`Goal_North` ที่ `Z = -106`, `Goal_South` ที่ `Z = 106`) เว้นระยะหลังโกล `14 Studs` ให้วิ่งอ้อมและชิ่งกำแพงหลังโกลได้
     - ทางลาดริมเส้นซ้าย-ขวา (`ElevatingRamp_Left`, `ElevatingRamp_Right` เอียง `25 องศา`)
   - สร้างฟังก์ชัน `ComputeReboundVelocity(incidentVelocity: Vector3, surfaceNormal: Vector3, restitution: number): Vector3` คำนวณ $\vec{R} = (\vec{V} - 2(\vec{V} \cdot \vec{N})\vec{N}) \times e$ พร้อมจำกัดความเร็วสูงสุดไม่เกิน `180 Studs/s`
   - สร้างฟังก์ชัน `ApplyRampImpulse(velocity: Vector3, isOnRamp: boolean): Vector3` บวกแรงยกตัวเมื่อเตะบอลขึ้นทางลาดริมเส้น

2. **`MODULE 02: 02-ball-control-and-parry` (`BallService.luau`, `ParryService.luau`, `InputController.luau`, `ParryIndicatorController.luau`):**
   - `BallService.luau`:
     - จัดการสถานะลูกบอล (`Position`, `Velocity`, `PossessorUserId`, `LastKickerUserId`), ระบบ Stamina ของผู้เล่นทุกคน (`0.0` ถึง `1.0`, ลดลงเมื่อ Sprint และฟื้นฟูเมื่อเดินปกติ)
     - ฟังก์ชัน `IsInShootingZone(ballPosition: Vector3, attackingTeam: string, gameMode: string): boolean`
     - ฟังก์ชัน `ExecuteBallAction(player: Player, actionType: Types.BallActionType, aimVector: Vector3)` ตรวจสอบฝั่ง Server ก่อนส่งหรือยิง
   - `ParryService.luau`:
     - ตรวจจับเมื่อลูกบอลที่ถูกส่งหรือยิงพุ่งเข้าใกล้ผู้เล่นฝ่ายรับในระยะ `<= 5.0 Studs` (`Constants.PARRY_INTERCEPT_RADIUS_STUDS`) **โดยไม่เปิดหน้าจอดวล 1v1**
     - เปิดหน้าต่างเวลา `0.35 วินาที` (`ParryWindowTrigger`) และตรวจสอบ `ParryAttemptRequest` ด้วยเวลา `os.clock()` บน Server:
       - หากทันเวลา: เปลี่ยนผู้ถือครองบอลเป็นกองหลังทันที (`Perfect Parry`)
       - หากไม่ทันเวลา: ติดสถานะ `MissedSlideRecovery` นาน `0.50 วินาที`

3. **`MODULE 03: 03-duel-choice-engine` (`ChoiceConfigs.luau`, `DuelEngineService.luau`, `DuelUIController.luau`):**
   - `ChoiceConfigs.luau`:
     - กำหนดชุด Choice ประจำตำแหน่ง (`Forward`, `Midfielder`, `Defender`) โดย `ShotBlock` มีเฉพาะในชุดของ `Defender` ตอนเข้าดวล 1v1 เท่านั้น
     - กำหนดตาราง `ResolveChoiceOutcome(attackerChoice: string, defenderChoice: string, attackerHasMistake: boolean, defenderHasMistake: boolean)`
   - `DuelEngineService.luau`:
     - ตรวจจับเมื่อผู้ถือบอลเข้าประชิดกองหลังในระยะ `<= 6.0 Studs` (`Constants.CHOICE_DUEL_TRIGGER_DISTANCE_STUDS`)
     - ตรวจสอบ `BallService.IsInShootingZone`: หากอยู่นอกระยะยิง ต้องใส่ `"SnapShot"` ลงใน `lockedChoices` เสมอ!
     - ตรวจสอบ `Mistake Mechanics` ทั้งฝั่งครองบอล (`Stamina < 0.15`, `BadFirstTouch`, `SharpTurnOffBalance`) และฝั่งรับ (`MissedSlideRecovery`, `BackTurned`, `SprintOvershoot`) เพื่อลดเวลาจาก `0.80s` เหลือ `0.45s` และล็อกปุ่มตามสเปก
     - ส่ง `DuelStartEvent` ไปยังผู้เล่นทั้งสอง และตัดสินผลเมื่อได้รับ `DuelChoiceSubmit` หรือเมื่อหมดเวลา

4. **`MODULE 04: 04-cards-animations-freekick` (`CardConfigs.luau`, `CameraCutsceneController.luau`, `FreeKickService.luau`, `FreeKickUIController.luau`):**
   - `CardConfigs.luau` & `DuelEngineService.luau`:
     - จัดการ Cooldown ของ `Signature Choice` ฝั่ง Server (เช่น `PhantomLaPulga` คูลดาวน์ `45s` เลี้ยงผ่าน 100% + บัฟส่ง/ยิง `+35%` นาน `4s`, `KnuckleEmperor` คูลดาวน์ `50s` ยิงทะลุ `ShotBlock` 100%, `SambaIllusion` คูลดาวน์ `40s`, `ColossusWall` คูลดาวน์ `45s`)
     - ตรวจสอบให้แน่ใจว่า `winCutsceneAnimIds` มีจำนวนไม่เกินระดับ Tier (`B = 1`, `A = 2`, `S = 3`)
   - `CameraCutsceneController.luau`:
     - เมื่อรับ `DuelResultEvent` ให้ซูมกล้องมุมต่ำสโลว์โมชัน `0.6 วินาที` เล่นท่าชนะดวล (`SlowMoNutmeg`, `RainbowFlick`, `ElasticoFlash`, `HeelChop`) และเล่นท่าดีใจ Easter Egg หลังยิงประตู
   - `FreeKickService.luau` & `FreeKickUIController.luau`:
     - คำนวณวิถีลูกนิ่ง FC27 จาก `aimDir`, `spinOffset` (คำนวณแรงโค้ง `Magnus Force` จากแกน X, แรงมุด `Dipping Topspin` จากแกน Y, และลูกส่าย `Knuckleball` เมื่อ `spinOffset.Magnitude < 0.15`) ร่วมกับตัวคูณความแม่นยำตามโซนเวลา (`Green = 1.0`, `Yellow = 0.75`, `Red = 0.40`)

5. **`MODULE 05: 05-dynamic-match-events` (`EventConfigs.luau`, `EventManagerService.luau`, `EventVFXController.luau`):**
   - `EventConfigs.luau` & `EventManagerService.luau`:
     - วงจรสุ่มเกิดอีเวนต์ทุก `90 วินาที` นาน `40 วินาที`
     - `PillarLockdown`: แจ้งเตือนล่วงหน้า `1.5 วินาที` ก่อนดันเสาคอนกรีตขึ้นมาขวางสนามและเปิดการชิ่งบอลกับเสา
     - `BlackoutVoid`: ซ่อนขอบกรงและเพดานให้มืดสนิท เห็นเฉพาะเสาโกลเรืองแสง ลูกบอลนีออน และไฮไลต์ตัวผู้เล่น
     - `FavelaAlley`: สร้างเส้นทางเดิน Waypoints ของ NPC คนเดินผ่าน 3 ตัวที่ซิงก์เวลาตรงกันระหว่าง Server และ Client พร้อม Hitbox สะท้อนบอล

6. **`MODULE 06: 06-traits-threads-economy` (`TraitConfigs.luau`, `ThreadConfigs.luau`, `TraitAndThreadService.luau`, `TradeMarketService.luau`):**
   - `TraitConfigs.luau`: กำหนดหิน Trait ที่มี Cooldown ฝั่ง Server (`LaserGuidedPass` 35s, `MiracleFinish` 60s, `IronLockdown` 45s)
   - `ThreadConfigs.luau`: กำหนดชุด `Battle Threads` (มีช่องใส่หิน Trait `1–2 ช่อง` **ไม่มีรองเท้าสตั๊ด**) และกำหนดค่า `MutationData` (`GoldenAura`, `VoidGlitch`, `BloodMoonFlame` ที่บวกเฉพาะ `cashMultiplier 1.5–5.0`, `expMultiplier 1.5–3.0`, `tradeValueBonus`, และ `vfxId` **โดยไม่มีค่าสเตตัสในสนาม**)
   - `TraitAndThreadService.luau`: จัดการโปรไฟล์ผู้เล่น, ตู้สุ่มกาชาพร้อมระบบ Pity `100`, การสวมใส่ชุด/หิน Trait, และการคำนวณตัวคูณรางวัลหลังจบแมตช์
   - `TradeMarketService.luau`: จัดการแผงขายของ (`Market Booth` 6 ช่อง) และหน้าต่างเทรด P2P ยืนยัน 2 ชั้น (`LockOffer` -> นับถอยหลัง `3.0 วินาที` -> `ConfirmTrade`) พร้อม Atomic Lock ป้องกันการปั๊มไอเทมซ้ำ

7. **`MODULE 07: 07-ui-navigation-and-screens` (`UIManager.luau`, `UITheme.luau`, `components/*.luau`, `screens/*.luau`):**
   - `UIManager.luau`: ควบคุม State Machine (`MAIN_MENU`, `LOBBY_MODE`, `MATCH_MODE`), การสลับหน้าจอใน Lobby ทีละหน้าโดยไม่ซ้อนทับกัน และการเปิด/ปิด Overlay ในสนาม (`DuelChoiceModal`, `ParryPromptOverlay`, `FreeKickOverlay`, `PostMatchSummaryScreen`)
   - เขียนโค้ดสร้างโครงสร้าง UI และสถานะการทำงานครบทั้ง 5 Components และ 11 Screens ตามสเปกส่วนที่ 4.7

8. **`MODULE 08: 08-integration-and-uat` (`MatchService.luau`, `init.server.luau`, `init.client.luau`):**
   - `MatchService.luau`: เชื่อมต่อทุกระบบเข้าด้วยกัน ตั้งแต่วงจรจับคู่ เลือกตำแหน่ง (`FW`/`MF`/`DF`) เริ่มแมตช์ อัปเดตฟิสิกส์บอล/ดวล/Parry/อีเวนต์สนาม คำนวณประตู สรุปผลรางวัลคูณตาม `Mutated Battle Threads` และส่งผลลัพธ์ไปยัง `PostMatchSummaryScreen`
   - อัปเดต `src/server/init.server.luau` และ `src/client/init.client.luau` ให้ Initialize ทุก Service และ Controller ครบวงจร

---

## ส่วนที่ 6: คำสั่งสำหรับสั่งรัน AI Agent เพื่อแก้บั๊กและลุยต่อจนจบ (PROMPT TO FIX & CONTINUE)

หลังจากคุณนำไฟล์ `startprojects.md` ฉบับนี้ไปวางทับไฟล์เดิมในโฟลเดอร์โปรเจกต์ `cage-zero` แล้ว ให้สั่ง AI Agent ด้วยข้อความนี้ได้เลย:

> **"อ่านไฟล์ `startprojects.md` ฉบับอัปเดตล่าสุด (โดยเฉพาะส่วนที่ 0 และส่วนที่ 5) ให้ละเอียด: ตอนนี้ `MODULE 00 (run-01)` ไม่ผ่านการตรวจจาก Codex (`STATUS: REJECTED`) เนื่องจากพบปัญหา 5 ข้อ (`FIX-M00-01` ถึง `FIX-M00-05`) ให้ดำเนินการดังนี้ทันที:**
> **1. บันทึกผลการตรวจ `REJECTED` และรายการแก้ไขทั้ง 5 ข้อลงใน `docs/plan/00-bootstrap-and-rig/assets/runs/run-01/review.md` และ `fix.md`**
> **2. เปิดโฟลเดอร์ `run-02` ใน `MODULE 00` แล้วแก้ไขโค้ดทั้ง 5 จุด (`RigAndCardService.luau`, `Types.luau`, `Network.luau`, และสร้างโฟลเดอร์ `runs/run-01/uat-images` & `fix-images` ให้ครบทุกโมดูล) จากนั้นตรวจรับงานและออกใบ `handoff.md` (`STATUS: APPROVED & CLOSED`)**
> **3. เมื่อปิด `MODULE 00` เสร็จแล้ว ให้เดินหน้าเขียนโค้ดจริง (ห้ามเว้นเป็น Stub!) และตรวจรับงานผ่าน Codex ทีละโมดูลต่อเนื่องตั้งแต่ `MODULE 01` ไปจนจบ `MODULE 08` ตามพิมพ์เขียวในส่วนที่ 5 ของ `startprojects.md` จนครบสมบูรณ์ 100%"**
