# RF03-MIXAMO-V3-R15-CANONICAL — Handoff & Resume Plan (Full 15-Clips Scope)

**สถานะ:** IN_EXECUTION / SCOPE_UPDATED_BY_OWNER (ขยายขอบเขตเป็น 15 คลิปเต็มตามคำสั่ง Owner)  
**วันที่ปรับปรุง:** 2026-10-30  
**Project:** `C:\Users\Stang\cage-zero`  
**Task ID:** `RF03-MIXAMO-V3-R15-CANONICAL`  
**Role:** Implementer (`agy w2:p5K`)  
**Controller:** Codex `w2:p52`  
**Project Owner:** Stang  

---

## 1. คำสั่งปรับปรุงขอบเขตจาก Owner (Owner Direct Directive)

Owner คุณ Stang มีคำสั่งโดยตรง: **"ไหนๆละ ทำ animation ใหม่ทั้งหมดเลย รวม GoalkeeperSidest StrikeFowardjog ด้วย"**  
ดังนั้น ขอบเขตงานจึงขยายครอบคลุมอนิเมชั่น Mixamo ทั้งหมด 15 คลิปในคลังงาน เข้าสู่ Canonical R15 Pipeline v3 เพื่อให้ได้โครงสร้างกระดูกและคุณภาพชุดเดียวกันทั้งหมดตั้งแต่ต้น

---

## 2. บัญชีรายการอนิเมชั่นทั้งหมด 15 รายการ (Complete 15-Clips Inventory)

โฟลเดอร์ต้นทาง: `C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo` (Read-Only)  
โฟลเดอร์ปลายทาง: `C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo\outputagy\v3`

1. `Fast Run.fbx` (Loop)
2. `Jog Forward.fbx` (Loop)
3. `Scissor Kick.fbx` (One-Shot)
4. `Soccer Pass.fbx` (One-Shot)
5. `Soccer Tackle.fbx` (One-Shot)
6. `Soccer Trip.fbx` (One-Shot)
7. `Standing Idle 02.fbx` (Loop)
8. `Standing Jump.fbx` (One-Shot)
9. `Strike Foward Jog.fbx` (Loop/Run — รวมเข้ามาทำใหม่สู่ v3 เต็มรูปแบบ)
10. `TurnBackRunning.fbx` (One-Shot/Transition)
11. `goal/Goalkeeper Catch.fbx` (One-Shot)
12. `goal/Goalkeeper Diving Save.fbx` (One-Shot)
13. `goal/Goalkeeper Overhand Throw.fbx` (One-Shot)
14. `goal/Goalkeeper Scoop.fbx` (One-Shot)
15. `goal/Goalkeeper Sidestep.fbx` (Loop/Locomotion — รวมเข้ามาทำใหม่สู่ v3 เต็มรูปแบบ)

---

## 3. กฎและเทคนิคการแก้ไข (Technical Corrections & Invariants)

1. **การวินิจฉัย Bone Basis รายคลิป (Per-clip Diagnosis):**
   - วินิจฉัย source/target rest basis และ metadata ที่มีอยู่เดิมในแต่ละคลิป
   - **ห้าม blanket flip 180° หัวไหล่หรือหัวเข่าแบบเหมารวม และห้าม apply ซ้ำสองรอบ**
   - ตรวจสอบ Euler Y / Rest Bone Roll ให้แน่ชัดก่อนปรับแต่ง
2. **การรักษาความต่อเนื่องของโครงสร้าง (Rig & Kinematics Preservation):**
   - รักษา Joint Pivots, Child World Transforms และสัมผัสเท้ากับพื้นตามเจตนาเดิม (Intended foot contacts)
3. **การลบ Location Curves ที่ผิดพลาด (Selective Translation Filtering):**
   - แยกแยะ Authentic Root / Pelvis translation channels ที่มีการเคลื่อนที่จริง
   - **ห้าม blind zero ทุก channel ของกระดูกย่อย** แต่ให้ตัดเฉพาะ translation offset ที่รั่วไหลผิดปกติ
4. **การปิด Seam เฉพาะ Loop vs รักษา Recovery ของ One-Shot:**
   - ห้ามทำ `keys[-1] = keys[0]` แบบเหมารวมทุกคลิป
   - จำกัด Seam Closure เฉพาะอนิเมชั่นที่เป็น **LOOPS** (เช่น Fast Run, Jog Forward, Standing Idle 02, Strike Foward Jog, Goalkeeper Sidestep)
   - **ต้องรักษา Ending / Recovery เฟรมสุดท้ายของคลิป ONE-SHOTS** (เตะ, กระโดด, พุ่งรับ, ล้ม, ขว้าง) ห้ามบังคับวนลูปกลับมาท่าเริ่มต้น
5. **Canonical Template & Rig Verification:**
   - ใช้ `cage-zero-animation-work/templates/Rig_and_Attachments_Template.blend` เป็นแกนอ้างอิง
   - ตรวจสอบความถูกต้องกับ Visual Mesh และ Attachments ของ `PreviewRig_R15_Boy_Height30` ใน Roblox Studio
6. **Blender & Source Integrity:**
   - ใช้ Single Coordinated Persistent Blender MCP Session
   - โฟลเดอร์ FBX ต้นฉบับคงสถานะ Read-Only และตรวจสอบ Hash (SHA256) ก่อน/หลัง
   - รักษา Timing, Frame count และ Action versions เดิมทั้งหมด

---

## 4. ปลายทางการส่งออกและการตรวจรับ

- เรนเดอร์ GIF ทั้ง 15 คลิปไปยัง:
  `C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo\outputagy\v3\<ClipName>_R15_v03.gif`
  พร้อม Manifest กำกับ: Source, Action, Loop type, Duration, Corrections applied, Audit results
- **Owner Visual Approval Gate:** ต้องส่ง GIF ทั้ง 15 คลิปให้ Owner ตรวจรับทางสายตาก่อนนำเข้า Studio เสมอ
- **Studio Integration:** Studio `AnimSaves` และ `Motion Tools` เป็น 2 ปลายทางที่แยกจากกัน ต้องยืนยันหลักฐานการนำเข้าทั้งสองทางหลังจาก Owner อนุมัติเท่านั้น
- **ข้อห้ามเด็ดขาด:** ห้ามแตะต้องหรือ rollback/reset/clean โฟลเดอร์ `src/`, ห้าม commit/push/publish
