# Fast Run → R15 — Standalone Preview Report 001

สถานะ **READY_FOR_OWNER_REVIEW — STANDALONE CLIP** (รอ Owner ตรวจรับฟีลคลิปแยก ยังไม่ผ่านการรับฟีลจาก Owner). การทำงานครอบคลุมเฉพาะคลิป Fast Run R15 แยก ไม่เชื่อมต่อกับ gameplay source, controller, Animate script หรือระบบเกมจริง ไม่มีการ commit/push/publish.

## ไฟล์สำหรับตรวจ

- [GIF ความเร็วต้นฉบับ 30 FPS](../../../../../cage-zero-animation-work/fast-run/FastRun_R15.gif)
- [GIF ช้าครึ่งหนึ่ง 15 FPS](../../../../../cage-zero-animation-work/fast-run/FastRun_R15_SlowReview.gif)
- [ภาพรวมจังหวะหลัก Contact Sheet](../../../../../cage-zero-animation-work/fast-run/FastRun_R15_ContactSheet.png)
- [FBX R15](../../../../../cage-zero-animation-work/fast-run/FastRun_R15.fbx)
- [Blender สำหรับตรวจ/แก้ต่อ](../../../../../cage-zero-animation-work/fast-run/FastRun_R15_Review.blend)
- [Studio loader/preview](../../../../../cage-zero-animation-work/fast-run/FastRun_R15_Studio.luau)
- [ข้อมูล keyframes](../../../../../cage-zero-animation-work/fast-run/fast-run-r15-keyframes.json)
- [Motion Tools Recipe](../../../../../cage-zero-animation-work/fast-run/RF02_FastRunMixamo_R15_v01.recipe.json)
- [Motion Tools Asset Metadata](../../../../../cage-zero-animation-work/fast-run/RF02_FastRunMixamo_R15_v01.asset.json)

หมายเหตุเส้นทาง: artifacts อยู่ที่ `C:/Users/Stang/cage-zero/cage-zero-animation-work/fast-run`.

## ผลที่ทำ

- **ต้นฉบับ:** `C:/Users/Stang/OneDrive/Desktop/stang/cage-zero-dev/animation-mixamo/Fast Run.fbx`
  - ขนาด: 305,616 bytes, FBX 7700, 65 กระดูก Mixamo, 17 เฟรมที่ 30 FPS.
  - Duration: **0.533333s** (16/30s).
  - SHA-256: `822fdc9d28ac97c53fac37717f20a51a286b44fd389b135119467ec794e912ab`.
  - Hip travel ในต้นฉบับ: -3.017388 หน่วยตามแนวแกน -Y (วิ่งพุ่งหน้า).
- **เป้าหมาย Retarget:** โครงและ mesh จริงของ `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30` ใน Cage-Zero (`137721422246269`), Normalized +30% height, 15 driven parts & AnimationConstraints.
- **การปรับแต่ง Retarget:**
  - จับคู่ Hips → LowerTorso, Spine2 → UpperTorso, Head → Head, และแขน/ขาเป็นข้อต่อ R15 ตามลำดับ.
  - Scale สัดส่วนขา R15: `leg_scale ≈ 2.634078`.
  - ปรับแกนข้อมือ R15 หมุน 90° ให้ฝ่ามือหันเข้าหาลำตัวตามธรรมชาติ.
  - แปลงจากคลิปเดินทาง (Root Motion) เป็น **In-Place Loop** ที่สมบูรณ์ โดยชดเชย virtual forward stride 7.948 studs/cycle.
  - ปรับ 2-Bone IK สำหรับเท้าสัมผัสพื้น (LeftFoot: F07–F10, RightFoot: F01–F02 และ F15–F17) ป้องกันการไถล (foot sliding) และเท้าทะลุพื้น.
  - แก้ไข Quaternion hemisphere flips ทั้งหมด 15 จุด และปรับเส้น Curve ทั้ง 105 เส้นเป็น Bezier พร้อม auto-clamped และ loop tangent matching.
- **Roblox Studio Preview:**
  - สร้างคลิป KeyframeSequence `RF02_FastRunMixamo_R15_v01` (17 keys, Loop = true, Movement priority) ใน `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves`.
  - สร้าง Preview Rig แยกเฉพาะ `Workspace.PreviewRigs.FastRun_R15_Review` วางไว้ที่พิกัด `(12, 4.283, 25)` พร้อม Script เล่นวนอัตโนมัติเมื่อเข้าโหมด Play.
- **Motion Tools Workbench Preview:**
  - นำเข้าสู่ Library ของ Motion Tools สำเร็จ ได้ Asset ID: `af977dc8-9ba2-45fa-beee-89c36fd3044f`.
  - ผ่านการ Audit ของ Motion Tools ครบ 15 tracks / 255 keys.
  - รันคำสั่ง `motion_studio_preview` บน `PreviewRig_R15_Boy_Height30` แบบสด ยืนยันสถานะ `succeeded` (Job ID: `a048f32a-ad5e-4fc6-a121-cb9d7998fa0d`).

## ตารางสรุปผลการตรวจสอบหลักฐาน (Audit Table)

| รายการตรวจ | ผลการตรวจจริง | ขอบเขต / หลักฐาน |
|---|---|---|
| **FBX Source Integrity** | ผ่าน | SHA256 ตรงกับไฟล์ต้นฉบับ ไม่มีการแก้หรือทับต้นฉบับ |
| **Target Rig Accuracy** | ผ่าน | 15 mesh parts ผูกกับ 15 ข้อต่อ R15 ของ PreviewRig_R15_Boy_Height30 ไม่ใช้ Box Proxy |
| **Provenance & Authentic** | ผ่าน | ยืนยัน Studio provenance (`authentic_ready: true`) ผ่าน `authentic_rig` add-on |
| **Curve & Tangent Audit** | ผ่าน | 105 Bezier curves, 0 Linear, 0 Constant; max slope difference 4e-07 |
| **Loop Seam Audit** | ผ่าน | ความต่างตำแหน่ง/การหมุน/สเกลหัวท้ายเป็น 0.0 (Seamless Loop) |
| **Contact Drift Audit** | ผ่าน | LeftFoot max drift 0.0000146 stud, RightFoot max drift 0.00000971 stud (เกณฑ์ < 0.02 stud) |
| **GIF Render & Timing** | ผ่าน | 16 เฟรม, 512×512, loop 0, shared palette; Normal 530ms (30 FPS), Slow 1060ms (15 FPS) |
| **Roblox Studio Import** | ผ่าน | Rig `FastRun_R15_Review` และคลิปใน `AnimSaves` พบจริง; Animator ทดสอบเล่น track IsPlaying = true |
| **Motion Tools Bridge** | ผ่าน | Asset ID `af977dc8-9ba2-45fa-beee-89c36fd3044f` บันทึกใน library และ playback preview ใน Studio ขึ้นสำเร็จ |
| **Scope & Safety** | ผ่าน | ไม่แตะ `src/`, ไม่แก้ controller ผู้เล่น, ไม่แตะลูกบอล/ระบบเกม, ไม่ commit/push |

## จุดที่ปรับแต่งและข้อจำกัดที่ยังเหลือ

1. **จุดที่ปรับแต่ง:**
   - ถอด Root Motion เดินหน้า 3.017 units ออกเพื่อสร้าง treadmill loop ในสถานที่เดิม รองรับระบบ Locomotion ของ Roblox
   - ตรึงฝ่าเท้าช่วง contact ให้ระนาบแนบพื้น ไม่ทะลุพื้นและไม่ลอย
   - จัดทิศทางฝ่ามือของ R15 ให้ไม่บิดเกร็งผิดธรรมชาติ
2. **ข้อจำกัดที่ยังเหลือ:**
   - ใน Blender Preview Render หัวใช้ standard Roblox mesh แทน dynamic head ดั้งเดิม (เนื่องจาก dynamic head ไม่เปิด EditableMesh API) แต่ใน Studio Preview Rig ยังคงหัวและเสื้อผ้าจริงครบถ้วน
   - จังหวะก้าวและรอบขาถูกจูนที่ 30 FPS ดั้งเดิม ยังไม่ได้ผูกกับความเร็ว `WalkSpeed` ของผู้เล่นจริง (รอ Owner ตรวจรับฟีลก่อน)
