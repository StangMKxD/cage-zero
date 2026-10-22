# Roblox R6 Football Animation Pack — คู่มือการใช้งานชุดข้อมูลและโค้ดอ้างอิง

ชุดไฟล์นี้ประกอบด้วยสเปคท่าทางแบบละเอียด ภาพอ้างอิงทางเทคนิค (`rig-reference.png` และ `A01.png`–`A18.png` พร้อมไฟล์แยก Variants) และโค้ด Luau อ้างอิง (`R6FootballPoseData.luau`, `R6FootballPosePlayer.luau`) สำหรับนำไปสร้างหรือขับเคลื่อน Animation ฟุตบอลบนตัวละคร **Classic Roblox R6 (Motor6D)** ได้โดยตรง

> **สถานะของโค้ด (Code Status)**: `Untested reference code` — โค้ด Luau ชุดนี้ได้รับการตรวจสอบความถูกต้องทางคณิตศาสตร์ของเมทริกซ์ `CFrame`, ลำดับการคูณมุม Euler `XYZ`, สมการแปลงแกน `Motor6D.Transform`, และการตรวจสอบกล่องชนพื้น 8 มุม (`OBB_min_Y >= 0`) ด้วยตัวแก้สมการ Forward Kinematics อัตโนมัติแล้ว แต่ยังไม่ได้รันทดสอบภายในสภาพแวดล้อม Roblox Studio จริง

## 1. โครงสร้างไฟล์ในชุดส่งมอบ

| ชื่อไฟล์ | ประเภท | รายละเอียด |
| :--- | :--- | :--- |
| `animation-spec.md` | เอกสารสเปคหลัก | รายละเอียดครบทั้ง 18 ท่า (`A01`–`A18`), ตารางมุม 6 ข้อต่อทุก Keyframe, ข้อมูล OBB Clearance, จุดสัมผัสลูกบอล และการเปลี่ยนท่า |
| `R6FootballPoseData.luau` | Luau ModuleScript | ข้อมูล Keyframes, เวลา Proposed Timing, โหมดการเล่น, จุดปะทะลูกบอล และ Variants ครบทั้ง `A01`–`A18` |
| `R6FootballPosePlayer.luau` | Luau ModuleScript | ตัวเล่นและคำนวณท่าทาง (`Motor6D.Transform` Evaluator) รองรับ `Loop`, `OneShot`, `Hold`, 8-Way Strafe และ 3D Parametric Pass |
| `rig-reference.png` | ภาพอ้างอิงโครงสร้าง | แผ่นภาพ Orthographic 3 มุม (ด้านหน้า ด้านข้าง ด้านหลัง) กำกับขนาด studs, ชื่อ Part, จุดหมุน `Motor6D`, แกนพิกัด และขนาดลูกบอล `R = 1.25 studs` |
| `A01.png` – `A18.png` | ภาพอ้างอิงรายท่า | แผ่นภาพ Keyframes เต็มตัวครบทุกท่า พร้อมมุมกล้องหลัก + มุมกล้องเสริม, เส้นพื้น `Y = 0`, เฟส `t`, ลูกศรทิศแรง และจุดปะทะบอล |
| `A15-finesse.png`, `A15-trivela.png` | ภาพอ้างอิง Variant | แผ่นภาพแยกละเอียดสำหรับท่ายิงปั่นโค้งข้างเท้าด้านใน (`Finesse`) และข้างเท้าด้านนอก (`Trivela`) |
| `A16-ground.png`, `A16-lob.png` | ภาพอ้างอิง Variant | แผ่นภาพแยกละเอียดสำหรับท่าส่งบอลเรียดพื้น (`Ground Pass`) และส่งบอลยกโด่ง (`Lob Pass`) |
| `prompt.txt` | Text File | ชุดคำสั่ง Prompt ภาษาอังกฤษและโครงสร้างพารามิเตอร์ที่ใช้สร้างภาพอ้างอิงทั้งหมด |

## 2. วิธีติดตั้งและใช้งานกับ Preview Rig ใน Roblox Studio

1. สร้างหุ่น **Classic R6 Rig** ใน `Workspace` (ผ่านเมนู `Avatar -> Rig Builder -> R6 -> Block Avatar`)
2. สร้างโฟลเดอร์หรือวาง `R6FootballPoseData.luau` และ `R6FootballPosePlayer.luau` เป็น `ModuleScript` ไว้ใน `ReplicatedStorage` (ใช้ชื่อ `R6FootballPoseData` และ `R6FootballPosePlayer`)
3. สร้าง `LocalScript` (เช่น ใน `StarterPlayerScripts` หรือใช้รันผ่าน Command Bar / Preview Script) เพื่อขับเคลื่อน Preview Rig ดังตัวอย่างต่อไปนี้:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local R6FootballPosePlayer = require(ReplicatedStorage:WaitForChild("R6FootballPosePlayer"))

-- อ้างอิงหุ่น R6 ที่ต้องการทดสอบ
local character = workspace:WaitForChild("R6PreviewRig")

-- สร้าง PosePlayer (พารามิเตอร์ที่สอง true = ปิดสคริปต์ Animate เริ่มต้นและหยุดแทร็กที่แย่งเขียน Motor6D เดียวกัน)
local player = R6FootballPosePlayer.new(character, true)
player:Start()

-- ตัวอย่างที่ 1: เล่นท่าพร้อมเล่น (A01 Idle / Ready)
player:Play("A01")

-- ตัวอย่างที่ 2: ทดสอบการเดิน (A02) และสปรินต์ (A03) แบบเชื่อมเฟสขา (Phase-Synced)
task.wait(2.0)
player:Play("A02", { playbackSpeed = 1.0 })
task.wait(1.5)
player:Play("A03", { playbackSpeed = 1.0 }, true) -- preservePhase = true เพื่อไม่ให้ขากระตุก

-- ตัวอย่างที่ 3: ทดสอบการง้างยิงปั่นโค้ง (A14 Hold) แล้วปล่อยยิงไซด์ก้อย (A15 Trivela)
task.wait(1.5)
player:Play("A14")        -- เข้าช่วง Enter (0.20s) แล้วล็อกท่า Hold ค้างไว้ที่ t = 0.50
task.wait(0.8)            -- ค้างท่าง้างไว้ 0.8 วินาที (ขาไม่สับ ไม่แทรกท่าเดิน)
player:ReleaseHold("trivela") -- ปล่อยยิงเข้าสู่ A15 Variant "trivela" ทันที

-- ตัวอย่างที่ 4: ทดสอบการส่งบอล 3D Pass (A16) แบบแปรตามแรงและมุมเงย
task.wait(1.2)
player:Play("A16", {
    passPower = 0.85,
    passElevationDeg = 32.0, -- ช้อนใต้ลูกบอลส่งโด่ง (Lob Pass)
})

-- ตัวอย่างที่ 5: เลื่อนดูทีละ Keyframe (Scrubbing) สำหรับผู้ทำ Animation ในปลั๊กอิน
task.wait(1.2)
player:Play("A11") -- Bicycle Kick
player:SetPhase(0.48, 1.0) -- ล็อกดูเฟรมปะทะบอลกลางอากาศที่ t = 0.48
```

## 3. หลักการทำงานร่วมกับ Roblox `Animator` และการนำไปสร้าง KeyframeSequence

* **การขับเคลื่อนด้วย `Motor6D.Transform`**: `R6FootballPosePlayer` เขียนค่าลงในพร็อพเพอร์ตี้ `Motor6D.Transform` ในจังหวะ `RunService.PreSimulation` (ซึ่งทำงานหลังขั้นตอนคำนวณของ `Animator` แต่ก่อนขั้นฟิสิกส์)
* **การป้องกันแทร็กแย่งเขียนข้อต่อ (Track Competition)**: หากต้องการขับทั้งตัวด้วย `R6FootballPosePlayer` เมธอด `StopCompetingTracks()` จะปิด `Character.Animate` ชั่วคราวและสั่ง `:Stop(0)` กับแทร็กที่กำลังเล่นอยู่ใน `Humanoid.Animator` เมื่อเรียก `player:Destroy()` ระบบจะคืนค่า `Transform = CFrame.identity`, คืน `C0/C1` เดิม และเปิด `Animate` กลับมาตามปกติ
* **การแปลงเป็น `KeyframeSequence` เพื่ออัปโหลดขึ้น Roblox**: หากผู้ทำ Animation ต้องการนำท่าใน `R6FootballPoseData` ไปสร้างเป็น `KeyframeSequence` ใน Roblox Studio สามารถวนลูปอ่านแต่ละ `KeyframeSpec` แล้วสร้าง `Pose` instance ตามชื่อ Part (`Torso`, `Head`, `Right Arm`, `Left Arm`, `Right Leg`, `Left Leg`) โดยใส่ค่า `Pose.CFrame = buildMotorTransform(baseC0, spec.pos, spec.rotDeg, Vector3.one)` ได้ทันที เพราะ `Pose.CFrame` ใน `KeyframeSequence` ใช้ปริภูมิเดียวกับ `Motor6D.Transform` ทุกประการ
