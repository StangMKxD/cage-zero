# สเปคชุด Animation ฟุตบอลสำหรับ Roblox R6 (A01–A18)

เอกสารสเปคทางวิศวกรรมฉบับสมบูรณ์สำหรับผู้สร้าง Animation และนักพัฒนาระบบเกมฟุตบอลบนโครงสร้าง **Classic Roblox R6 (Motor6D 6 ข้อต่อ)** ทุกค่ามุม, ตำแหน่งชดเชย (Translation), ขอบกล่องชนพื้น (Oriented Bounding Box — OBB clearance), และจุดสัมผัสลูกบอล (Radius = `1.25 studs`) คำนวณและตรวจสอบความสอดคล้องตรงกัน 100% กับไฟล์โค้ด `R6FootballPoseData.luau`, `R6FootballPosePlayer.luau` และแผ่นภาพอ้างอิง `rig-reference.png` ถึง `A18.png`

## 1. โครงสร้าง R6 Rig และลำดับชั้น Motor6D

ใช้โครงสร้าง Classic Roblox R6 มาตรฐาน (`Scale = 1.0`, ไม่มี `Bone` instances, ไม่มีการหักงอข้อศอก เข่า ข้อมือ หรือข้อเท้ากลางชิ้นส่วน):

| ชื่อชิ้นส่วน (Part) | ขนาด (Size X, Y, Z หน่วย studs) | คุณสมบัติและการแสดงผล | ตำแหน่งศูนย์กลางท่ายืนมาตรฐาน (World X, Y, Z) |
| :--- | :--- | :--- | :--- |
| `HumanoidRootPart` | `2, 2, 1` | โปร่งใส (`Transparency = 1`), แกนอ้างอิงหลักของตัวละคร | `(0.00, 3.00, 0.00)` |
| `Torso` | `2, 2, 1` | ลำตัวกลาง เชื่อมต่อข้อต่อทั้ง 6 จุด | `(0.00, 3.00, 0.00)` |
| `Head` | `2, 1, 1` | ศีรษะ อยู่เหนือขอบบนของ Torso | `(0.00, 4.50, 0.00)` |
| `Right Arm` | `1, 2, 1` | แขนขวาแท่งแข็งชิ้นเดียว ขนาบข้างขวา (+X) ของ Torso | `(+1.50, 3.00, 0.00)` |
| `Left Arm` | `1, 2, 1` | แขนซ้ายแท่งแข็งชิ้นเดียว ขนาบข้างซ้าย (-X) ของ Torso | `(-1.50, 3.00, 0.00)` |
| `Right Leg` | `1, 2, 1` | ขาขวาแท่งแข็งชิ้นเดียว ใต้ซีกขวาของ Torso (ฝ่าเท้าแตะ `Y = 0`) | `(+0.50, 1.00, 0.00)` |
| `Left Leg` | `1, 2, 1` | ขาซ้ายแท่งแข็งชิ้นเดียว ใต้ซีกซ้ายของ Torso (ฝ่าเท้าแตะ `Y = 0`) | `(-0.50, 1.00, 0.00)` |
| `Football (Ball)` | ทรงกลม `R = 1.25` (`D = 2.50`) | ลูกฟุตบอลขนาดจริงเทียบสัดส่วนขา R6 | วางพื้นที่ `Center Y = 1.25` |

ลำดับชั้นของข้อต่อ `Motor6D` (ใช้ชื่อจริงรวมช่องว่างตรงตาม Roblox R6):

```text
HumanoidRootPart
└─ RootJoint (Part0 = HumanoidRootPart, Part1 = Torso)
   ├─ Neck (Part0 = Torso, Part1 = Head)
   ├─ Right Shoulder (Part0 = Torso, Part1 = Right Arm)
   ├─ Left Shoulder (Part0 = Torso, Part1 = Left Arm)
   ├─ Right Hip (Part0 = Torso, Part1 = Right Leg)
   └─ Left Hip (Part0 = Torso, Part1 = Left Leg)
```

## 2. ระบบพิกัด (Coordinate Spaces) และการแปลงแกน Motor6D

### 2.1 นิยามแกนพิกัดอ้างอิงของตัวละคร (Character / Part0 Reference Space)

* **`+X` (Right)**: ด้านขวาของตัวละคร (ไม่ใช่ด้านขวาของคนดูภาพ)
* **`+Y` (Up)**: ทิศชี้ขึ้นด้านบน (พื้นสนามอยู่ที่ `World Y = 0.00 studs`)
* **`-Z` (Forward)**: ด้านหน้าของตัวละคร (`LookVector = (0, 0, -1)`)
* **`+Z` (Backward)**: ด้านหลังของตัวละคร (`BackVector = (0, 0, +1)`)

### 2.2 การแยกปริภูมิพิกัด (4 Coordinate Spaces) ที่ต้องไม่สับสน

| ปริภูมิพิกัด (Space) | จุดกำเนิดและแกนอ้างอิง | บทบาทในสเปคและโค้ดชุดนี้ |
| :--- | :--- | :--- |
| **1. World Space** | พื้นสนาม `Y = 0`, แกนโลกของ Workspace | ใช้วัดความสูงจริงเทียบพื้น (`OBB_min_Y >= 0`), ตำแหน่งลูกบอล `Ball.Center`, และจุดปะทะบนผิว Part |
| **2. Character / HRP Space** | จุดศูนย์กลาง `HumanoidRootPart` (ท่ายืน `Y = 3.00 studs`) | ปริภูมิอ้างอิงของ `RootJoint` (`Part0 = HRP`) และเวกเตอร์ความเร็วการเคลื่อนที่ (`MoveDirection`) |
| **3. Part0 Reference Space** | `HRP` สำหรับ `RootJoint`; `Torso` สำหรับ `Neck`, `Shoulders`, `Hips` | **ปริภูมิที่ใช้ระบุค่ามุมและระยะเลื่อนในตาราง Keyframe ทั้งหมดของเอกสารนี้** รอบจุดหมุน `p = baseC0.Position` |
| **4. Motor Joint Local Space** | ปริภูมิภายในของ `baseC0` (ซึ่งถูกหมุนด้วยเมทริกซ์ `B`, `R`, หรือ `L`) | ปริภูมิของพร็อพเพอร์ตี้ `Motor6D.Transform` ที่ส่งให้เอนจิน Roblox คำนวณด้วยสมการ `Transform = baseC0:Inverse() * P * baseC0` |

### 2.3 Rest Joint Frames (`baseC0`, `baseC1`) และสมการแปลงแกนสู่ `Motor6D.Transform`

ที่ `Scale = 1` ค่าตั้งต้นของ R6 Rig กำหนดโดยเมทริกซ์หมุนฐาน:

* `B = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)` (เท่ากับ `CFrame.Angles(-90°, 0°, 180°)`)
* `R = CFrame.Angles(0, math.rad(90), 0)`
* `L = CFrame.Angles(0, math.rad(-90), 0)`

| ชื่อข้อต่อ (Motor6D) | `baseC0` (ในปริภูมิ Part0) | `baseC1` (ในปริภูมิ Part1) | จุดหมุน `p = baseC0.Position` (ใน Part0 Space) |
| :--- | :--- | :--- | :--- |
| `RootJoint` | `B` | `B` | `(0.0, 0.0, 0.0)` |
| `Neck` | `CFrame.new(0, 1, 0) * B` | `CFrame.new(0, -0.5, 0) * B` | `(0.0, 1.0, 0.0)` |
| `Right Shoulder` | `CFrame.new(1, 0.5, 0) * R` | `CFrame.new(-0.5, 0.5, 0) * R` | `(1.0, 0.5, 0.0)` |
| `Left Shoulder` | `CFrame.new(-1, 0.5, 0) * L` | `CFrame.new(0.5, 0.5, 0) * L` | `(-1.0, 0.5, 0.0)` |
| `Right Hip` | `CFrame.new(1, -1, 0) * R` | `CFrame.new(0.5, 1, 0) * R` | `(1.0, -1.0, 0.0)` |
| `Left Hip` | `CFrame.new(-1, -1, 0) * L` | `CFrame.new(-0.5, 1, 0) * L` | `(-1.0, -1.0, 0.0)` |

**สมการแปลงค่าตารางสู่ `Motor6D.Transform` (ป้องกันปัญหาขาเตะด้านหน้ากลายเป็นกางขาออกข้าง):**

เอนจิน Roblox คำนวณตำแหน่งชิ้นส่วนด้วยสมการ:
`Part0.CFrame * C0 * Transform = Part1.CFrame * C1`

เมื่อผู้ออกแบบกำหนดการเคลื่อนที่ `D` ใน **Part0 Reference Space** รอบจุดหมุน `p = baseC0.Position` โดยใช้ลำดับการคูณมุม Euler แบบ **XYZ** (`CFrame.Angles(rx, ry, rz) = Rx(rx) * Ry(ry) * Rz(rz)`):

1. `D = CFrame.new(tx * scaleX, ty * scaleY, tz * scaleZ) * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))`
2. `P = CFrame.new(p) * D * CFrame.new(-p)`
3. `Transform = baseC0:Inverse() * P * baseC0`

**ความหมายทางกายภาพของมุม `(rx, ry, rz)` ในตารางทุกท่า (Part0 Space, ลำดับการคูณ XYZ):**

* **`rx` (Pitch รอบแกน +X):**
  * สำหรับ `RootJoint (Torso)` และ `Neck (Head)`: **`-rx` = โน้มตัว/ก้มหน้าไปข้างหน้า (-Z)**, **`+rx` = เอนหลัง/เงยหน้าไปข้างหลัง (+Z)**
  * สำหรับ `Shoulders (Arms)` และ `Hips (Legs)`: **`+rx` = เหวี่ยงแขน/เตะขาไปด้านหน้า (-Z)**, **`-rx` = ดึงแขน/ง้างขาไปด้านหลัง (+Z)**
* **`ry` (Yaw รอบแกน +Y):**
  * **`+ry`** = หันหรือบิดทวนเข็มนาฬิกาเมื่อมองจากด้านบน (หันไปทางซ้าย `-X` ของตัวละคร; สำหรับขาขวาคือบิดเข้าด้านใน, สำหรับขาซ้ายคือเปิดออกด้านนอก)
  * **`-ry`** = หันหรือบิดตามเข็มนาฬิกาเมื่อมองจากด้านบน (หันไปทางขวา `+X` ของตัวละคร; สำหรับขาขวาคือหมุนเปิดสะโพกออกด้านนอก เช่น ท่าแปบอล/Finesse)
* **`rz` (Roll รอบแกน +Z):**
  * สำหรับ `Torso` และ `Head`: **`+rz` = เอียงตัว/เอียงหัวไปทางซ้าย (-X)**, **`-rz` = เอียงตัว/เอียงหัวไปทางขวา (+X)**
  * สำหรับ `Arms` และ `Legs`: **`+rz` = กางแขนขวา/ขาขวาออกทางขวา (+X)** (หรือหุบแขนซ้าย/ขาซ้ายเข้าแกนกลาง), **`-rz` = กางแขนซ้าย/ขาซ้ายออกทางซ้าย (-X)** (หรือหุบแขนขวา/ขาขวาเข้าแกนกลาง)

## 3. สรุปภาพรวมชุด Animation ทั้ง 18 ท่า (Master Index)

*หมายเหตุ: เวลา Duration, Blend-in, Blend-out และ Contact Phase ทั้งหมดเป็น **Proposed animation timing** ที่ออกแบบและปรับจูนให้สอดคล้องกับความเร็วอ้างอิงและฟิสิกส์ R6*

| ID | ชื่อท่า (Animation Name) | โหมด (Mode) | Proposed Duration (s) | Blend In / Out (s) | Contact Phase | ไฟล์ภาพอ้างอิง |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **A01** | Idle / Ready | `Loop` | `1.60 s` | `0.15 / 0.12 s` | — | `A01.png` |
| **A02** | Walk (Forward & Backward) | `Loop` | `0.48 s` | `0.12 / 0.12 s` | t = 0.00 (Right Strike), t = 0.50 (Left Strike) | `A02.png` |
| **A03** | Sprint | `Loop` | `0.38 s` | `0.10 / 0.12 s` | t = 0.00 (Right Drive), t = 0.50 (Left Drive); Airborne float at t = 0.25 & 0.75 | `A03.png` |
| **A04** | Dash Burst | `One-shot` | `0.22 s` | `0.03 / 0.06 s` | t = 0.00..0.27 (Left Foot Push-Off), t = 1.00 (Right/Left Sprint Catch) | `A04.png` |
| **A05** | Shift Lock 8-Way Strafe | `Loop (2D Directional Blend Space: F, B, L, R, FL, FR, BL, BR)` | `0.44 s` | `0.08 / 0.10 s` | t = 0.00 & t = 0.50 (Alternating lateral/diagonal plant) | `A05.png` |
| **A06** | Directional Jump / Fall | `One-shot / State-driven Airborne` | `0.72 s` | `0.04 / 0.04 s` | t = 0.00 (Ground Takeoff Impulse); Airborne for t > 0.08 until Raycast/State Landed | `A06.png` |
| **A07** | Landing Cushion | `One-shot (Additive / Interruptible)` | `0.24 s` | `0.03 / 0.08 s` | t = 0.00..0.33 (Ground Impact Cushion) | `A07.png` |
| **A08** | Header | `One-shot` | `0.48 s` | `0.06 / 0.10 s` | t = 0.45 (0.216 s) — Forehead impact on Ball | `A08.png` |
| **A09** | Aerial Block | `One-shot` | `0.52 s` | `0.05 / 0.10 s` | t = 0.42 (0.218 s) — Anterior Torso / Chest Wall impact | `A09.png` |
| **A10** | Mid-Air Volley | `One-shot` | `0.56 s` | `0.05 / 0.10 s` | t = 0.46 (0.258 s) — Right Leg anterior instep mid-air strike | `A10.png` |
| **A11** | Bicycle Kick | `One-shot` | `0.88 s` | `0.06 / 0.12 s` | t = 0.48 (0.422 s) — Overhead inverted Right Leg strike (+Z ball trajectory) | `A11.png` |
| **A12** | Direct Shoot Wind-up / Hold | `Hold (Enter t=0.00..0.50 [0.18s] -> Freeze at t=0.50 -> Release to A13 or Cancel t=0.50..1.00 [0.16s])` | `0.34 s` | `0.06 / 0.08 s` | — | `A12.png` |
| **A13** | Direct Shoot Follow-Through | `One-shot` | `0.42 s` | `0.00 / 0.10 s` | t = 0.28 (0.118 s) — Right Leg anterior surface (0.00, -0.55, -0.50) strikes grounded ball | `A13.png` |
| **A14** | Curve Shoot Wind-up / Hold | `Hold (Enter t=0.00..0.50 [0.20s] -> Freeze at t=0.50 -> Release to A15 [Finesse/Trivela] or Cancel t=0.50..1.00 [0.16s])` | `0.36 s` | `0.06 / 0.08 s` | — | `A14.png` |
| **A15** | Curve Shoot Follow-Through (Finesse & Trivela Variants) | `One-shot (2 Visual Variants: 'finesse' and 'trivela')` | `0.44 s` | `0.00 / 0.10 s` | t = 0.30 (0.132 s) — Finesse hits Medial (-X) face; Trivela hits Lateral (+X) face | `A15.png` (`A15-finesse.png`, `A15-trivela.png`) |
| **A16** | Single 3D Pass (Parametric Ground & Lob Pass) | `One-shot (Parametric over passPower ∈ [0,1] and passElevation ∈ [0°, 45°])` | `0.36 s` | `0.05 / 0.08 s` | t = 0.32 (0.115 s) — Inside-foot push (Ground) or low-edge wedge scoop (Lob) | `A16.png` (`A16-ground.png`, `A16-lob.png`) |
| **A17** | Slide Tackle | `One-shot` | `0.55 s` | `0.05 / 0.00 s` | t = 0.38 (0.209 s) — Extended Right Leg front-boot contact on grounded ball | `A17.png` |
| **A18** | Slide Recovery (Hit & Miss Visual Variants) | `One-shot (Shared KF1/KF4 with 'hit' and 'miss' visual mid-phase variants at KF2/KF3)` | `0.44 s` | `0.00 / 0.10 s` | — | `A18.png` |

## 4. รายละเอียดสเปคท่าทางรายตัว (A01–A18 Complete Specification)

### A01 — Idle / Ready

* **1) ID / ชื่อ / โหมด**: `A01` — **Idle / Ready** | โหมด: **`Loop`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A01.png` (แสดงครบ 5 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front (-Z View)`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `1.60 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.15 s`, `blendOut = 0.12 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `ไม่มีการปะทะลูกบอลโดยตรง (Locomotion / Utility)`
  * **การอิงสถานะจริง (State Binding)**: `Grounded & MoveSpeed < 0.5 studs/s`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A01 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Neutral Athletic Ready (Start)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.63, +0.18, +0.64)`, ฝ่าเท้าซ้าย = `(-0.62, +0.11, +0.13)`) — ฐานยืนกว้างเล็กน้อย ขาซ้ายนำหน้าเล็กน้อย ลำตัวโน้มหน้า -8° พร้อมออกตัวทุกทิศ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.140, +0.000)` | `(-8.0°, -4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

**Keyframe 2 — `t = 0.25` (`0.400 s`): Inhale & Slight Right Weight Shift**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.63, +0.15, +0.49)`, ฝ่าเท้าซ้าย = `(-0.63, +0.16, +0.01)`) — ถ่ายน้ำหนักมาฝั่งขวาเล็กน้อย (+0.04 studs) พร้อมจังหวะหายใจเข้า ยกอกขึ้นเล็กน้อย*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.040, +0.159, -0.020)` | `(-7.0°, -2.0°, -1.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางขวา (+X) 0.04 studs, ยกระดับลำตัว (ขึ้น +Y) 0.16 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.02 studs, โน้มหน้า (-rx) 7.0°, บิดลำตัวหันทางขวา (-ry) 2.0°, เอียงลำตัวทางขวา (-rz) 1.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+7.0°, +2.0°, +1.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 7.0°, หันศีรษะมองทางซ้าย (+ry) 2.0°, เอียงศีรษะทางซ้าย (+rz) 1.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+13.0°, -8.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 13.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+11.0°, +8.0°, -13.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 11.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 13.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-4.0°, -4.0°, +5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 4.0°, เปิดออกด้านนอก (-ry) 4.0°, กางออกด้านขวา (+rz) 5.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, -3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 8.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 3.0° |

**Keyframe 3 — `t = 0.50` (`0.800 s`): Center Settle & Low Ready Micro-Dip**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.64, +0.20, +0.74)`, ฝ่าเท้าซ้าย = `(-0.64, +0.12, +0.25)`) — กดจุดศูนย์ถ่วงเข้ากลาง โน้มลำตัว -10° สายตามองตรง (-Z) พร้อมชิงจังหวะ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.137, +0.000)` | `(-10.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 10.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, -5.0°, +11.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 11.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +5.0°, -11.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 11.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-7.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 7.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+7.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 7.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

**Keyframe 4 — `t = 0.75` (`1.200 s`): Slight Left Weight Shift & Counter-Arm**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.62, +0.20, +0.71)`, ฝ่าเท้าซ้าย = `(-0.62, +0.08, +0.16)`) — ถ่ายน้ำหนักกลับฝั่งซ้าย (-0.04 studs) ผ่อนไหล่แต่รักษาโครงสร้างสมดุล*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.040, +0.128, +0.020)` | `(-7.5°, -5.0°, +1.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.04 studs, ยกระดับลำตัว (ขึ้น +Y) 0.13 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.02 studs, โน้มหน้า (-rx) 7.5°, บิดลำตัวหันทางขวา (-ry) 5.0°, เอียงลำตัวทางซ้าย (+rz) 1.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+7.5°, +5.0°, -1.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 7.5°, หันศีรษะมองทางซ้าย (+ry) 5.0°, เอียงศีรษะทางขวา (-rz) 1.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+9.0°, -6.0°, +13.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 9.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 13.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+16.0°, +6.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 16.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 14.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, -5.0°, +3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 8.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 3.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+5.0°, +5.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 5.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 5.0° |

**Keyframe 5 — `t = 1.00` (`1.600 s`): Neutral Athletic Ready (Loop Closure)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.63, +0.18, +0.64)`, ฝ่าเท้าซ้าย = `(-0.62, +0.11, +0.13)`) — เฟรมปิดลูปตรงกับ t=0.00 ทุกค่า 100% เพื่อวนลูปไร้รอยต่อ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.140, +0.000)` | `(-8.0°, -4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A01

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Dual support (Staggered: Left Leg +6° forward, Right Leg -6° back, weight shifting ±0.04 studs laterally)
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.156 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A01

* **เข้าจากท่า (Enter From)**: A02 Walk, A03 Sprint, A07 Landing Cushion, A12/A14 Hold Cancel, A13/A15/A16/A18 Recovery
* **ออกไปท่า (Exit To)**: A02 Walk (0.10s), A03 Sprint (0.10s), A04 Dash Burst (0.04s), A06 Jump (0.04s), A12/A14 Shoot Wind-up (0.08s), A16 Pass (0.06s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Crossfade blendOut 0.12s via exponential decay or direct pose blend into active locomotion/action track.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: เนื่องจากขา R6 ย่อเข่าไม่ได้ การลดระดับลำตัวทำได้โดยกาง/เหลื่อมขาหน้า-หลัง (±6°) และโน้ม Torso (-8° ถึง -10°) เพื่อให้ดูพร้อมสปริงตัวโดยมุมกล่องขาไม่จมพื้น

### A02 — Walk (Forward & Backward)

* **1) ID / ชื่อ / โหมด**: `A02` — **Walk (Forward & Backward)** | โหมด: **`Loop`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A02.png` (แสดงครบ 5 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front-Left 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.48 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.12 s`, `blendOut = 0.12 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.00 (Right Strike), t = 0.50 (Left Strike)`
  * **การอิงสถานะจริง (State Binding)**: `Grounded & 0.5 <= MoveSpeed <= 24 studs/s (PlaybackSpeed = MoveSpeed / 20.0)`
  * **การคำนวณความสัมพันธ์ Stride Length / Cycle Duration (ที่ความเร็วอ้างอิง `20 studs/s`)**:
    * ขา R6 ยาว `L = 2.00 studs` เมื่อก้าวสลับหน้า-หลังด้วยมุมสะโพก `rx = +36°` ถึง `-34°` ร่วมกับการบิดสะโพก `ry = ±8°` จะได้ระยะก้าวเรขาคณิตต่อ 1 ก้าว `L_step = 2.0 * (sin 36° + sin 34°) + 1.0 * sin 8° = 2.43 studs` หรือครบวงจร 2 ก้าว `L_cycle_geom = 4.86 studs`
    * ที่รอบเวลา `T_cycle = 0.48 s` (ความถี่ก้าว `4.17 ก้าว/วินาที`) ความเร็วการกวาดเท้าเชิงเรขาคณิตอยู่ที่ `10.13 studs/s` ซึ่งต่ำกว่าความเร็วเกม `20 studs/s` ตามข้อจำกัดขาสั้นของหุ่น R6
    * **วิธีลด Foot Sliding**: (1) ใช้การกวาดมุมสะโพกขาค้ำยัน (`Stance Leg`) แบบเชิงเส้น (Linear angular velocity) แทนกราฟ Sine ปกติ เพื่อให้ความเร็วแนวราบของฝ่าเท้าคงที่ตลอดช่วงแตะพื้น (2) ผูก `PlaybackSpeed = MoveSpeed / 20.0` และ (3) ใช้การยุบ-ยก `RootJoint ty` (`+0.18 studs` ตอนกางขากว้างสุด และ `+0.04 studs` ตอนขารับน้ำหนักตั้งฉาก) เพื่อให้ขอบล่างของกล่องขา (`OBB_min_Y = 0.010 studs`) สัมผัสระนาบพื้นพอดีโดยไม่จมพื้น

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A02 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Right Foot Strike / Double Support**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.47, +0.25, -0.79)`, ฝ่าเท้าซ้าย = `(-0.34, +0.60, +1.63)`) — เท้าขวาสัมผัสพื้นด้านหน้า (+36°) แขนซ้ายเหวี่ยงสวนด้านหน้า (+34°) ลำตัวบิดรับจังหวะ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.041, +0.000)` | `(-10.0°, +8.0°, +1.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.04 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางซ้าย (+ry) 8.0°, เอียงลำตัวทางซ้าย (+rz) 1.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -8.0°, -1.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0°, หันศีรษะมองทางขวา (-ry) 8.0°, เอียงศีรษะทางขวา (-rz) 1.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-30.0°, +0.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 30.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+34.0°, +0.0°, -8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 34.0°, กางออกด้านซ้าย (-rz) 8.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+36.0°, +0.0°, +2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 36.0°, กางออกด้านขวา (+rz) 2.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-34.0°, +0.0°, -2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 34.0°, กางออกด้านซ้าย (-rz) 2.0° |

**Keyframe 2 — `t = 0.25` (`0.120 s`): Right Mid-Stance / Left Passing**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.49, +0.12, +0.46)`, ฝ่าเท้าซ้าย = `(-0.81, +0.15, -0.12)`) — ขาขวารับน้ำหนักเต็มแท่งใต้ลำตัว ขาซ้ายก้าวผ่าน (Passing) กางออกเล็กน้อย (-6°) เพื่อเคลียร์พื้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.030, +0.125, +0.000)` | `(-10.0°, +0.0°, -2.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางขวา (+X) 0.03 studs, ยกระดับลำตัว (ขึ้น +Y) 0.12 studs, โน้มหน้า (-rx) 10.0°, เอียงลำตัวทางขวา (-rz) 2.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +0.0°, +2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0°, เอียงศีรษะทางซ้าย (+rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+4.0°, +0.0°, +10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 4.0°, กางออกด้านขวา (+rz) 10.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-4.0°, +0.0°, -10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 4.0°, กางออกด้านซ้าย (-rz) 10.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+2.0°, +0.0°, +2.5°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 2.0°, กางออกด้านขวา (+rz) 2.5° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +0.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 18.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 3 — `t = 0.50` (`0.240 s`): Left Foot Strike / Opposite Contact**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.34, +0.60, +1.63)`, ฝ่าเท้าซ้าย = `(-0.47, +0.25, -0.79)`) — เท้าซ้ายสัมผัสพื้นด้านหน้า (+36°) แขนขวาเหวี่ยงสวนด้านหน้า (+34°) สมมาตรกับ t=0.00*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.041, +0.000)` | `(-10.0°, -8.0°, -1.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.04 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางขวา (-ry) 8.0°, เอียงลำตัวทางขวา (-rz) 1.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +8.0°, +1.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0°, หันศีรษะมองทางซ้าย (+ry) 8.0°, เอียงศีรษะทางซ้าย (+rz) 1.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+34.0°, +0.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 34.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-30.0°, +0.0°, -8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 30.0°, กางออกด้านซ้าย (-rz) 8.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-34.0°, +0.0°, +2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 34.0°, กางออกด้านขวา (+rz) 2.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+36.0°, +0.0°, -2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 36.0°, กางออกด้านซ้าย (-rz) 2.0° |

**Keyframe 4 — `t = 0.75` (`0.360 s`): Left Mid-Stance / Right Passing**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.81, +0.15, -0.12)`, ฝ่าเท้าซ้าย = `(-0.49, +0.12, +0.46)`) — ขาซ้ายรับน้ำหนักเต็มแท่ง ขาขวาก้าวผ่าน (Passing) พร้อมยกขอบเท้าพ้นพื้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.030, +0.125, +0.000)` | `(-10.0°, +0.0°, +2.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.03 studs, ยกระดับลำตัว (ขึ้น +Y) 0.12 studs, โน้มหน้า (-rx) 10.0°, เอียงลำตัวทางซ้าย (+rz) 2.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +0.0°, -2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0°, เอียงศีรษะทางขวา (-rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-4.0°, +0.0°, +10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 4.0°, กางออกด้านขวา (+rz) 10.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+4.0°, +0.0°, -10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 4.0°, กางออกด้านซ้าย (-rz) 10.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +0.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 18.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+2.0°, +0.0°, -2.5°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 2.0°, กางออกด้านซ้าย (-rz) 2.5° |

**Keyframe 5 — `t = 1.00` (`0.480 s`): Right Foot Strike (Loop Closure)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.47, +0.25, -0.79)`, ฝ่าเท้าซ้าย = `(-0.34, +0.60, +1.63)`) — ครบรอบก้าวเดิน 0.48 วินาที ต่อเข้า t=0.00 แบบไร้รอยต่อ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.041, +0.000)` | `(-10.0°, +8.0°, +1.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.04 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางซ้าย (+ry) 8.0°, เอียงลำตัวทางซ้าย (+rz) 1.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -8.0°, -1.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0°, หันศีรษะมองทางขวา (-ry) 8.0°, เอียงศีรษะทางขวา (-rz) 1.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-30.0°, +0.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 30.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+34.0°, +0.0°, -8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 34.0°, กางออกด้านซ้าย (-rz) 8.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+36.0°, +0.0°, +2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 36.0°, กางออกด้านขวา (+rz) 2.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-34.0°, +0.0°, -2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 34.0°, กางออกด้านซ้าย (-rz) 2.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A02

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: t=0.00..0.50: Right Leg stance sweep (+36° to -34°); t=0.50..1.00: Left Leg stance sweep (+36° to -34°). Backward Walk reverses phase (t_back = 1 - t) and sets RootJoint rx = -3°.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.117 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A02

* **เข้าจากท่า (Enter From)**: A01 Idle (0.12s), A03 Sprint (phase-synced 0.12s), A07 Landing Cushion (0.08s)
* **ออกไปท่า (Exit To)**: A01 Idle (0.12s), A03 Sprint (phase-synced 0.10s), A04 Dash Burst (0.04s), A06 Jump (0.05s), A12/A14/A16/A17 Actions
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `Right Hip, Left Hip, Right Shoulder, Left Shoulder, RootJoint, Neck`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Phase-matched blend into A03 Sprint (preserving t) or damped 0.12s blendOut to A01 Idle.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: ข้อจำกัดเรขาคณิต R6: ขายาว 2.0 studs ที่มุมก้าว ±36° ได้ระยะก้าวเรขาคณิต ~2.49 studs/ก้าว (4.98 studs/รอบ) ที่ความเร็วเกม 20 studs/s จึงใช้รอบ 0.48s ร่วมกับการกวาดขาความเร็วเชิงมุมคงที่ (Linear Stance Sweep) และการปรับ PlaybackSpeed = v/20 เพื่อลดอาการเท้าไถล (foot sliding) โดยไม่ทำให้ขาสับถี่เกินธรรมชาติ

### A03 — Sprint

* **1) ID / ชื่อ / โหมด**: `A03` — **Sprint** | โหมด: **`Loop`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A03.png` (แสดงครบ 5 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front-Right 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.38 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.10 s`, `blendOut = 0.12 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.00 (Right Drive), t = 0.50 (Left Drive); Airborne float at t = 0.25 & 0.75`
  * **การอิงสถานะจริง (State Binding)**: `Grounded & MoveSpeed > 24 studs/s (Reference 32 studs/s)`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A03 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Right Drive Contact & Forward Lean**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.27, +0.29, -0.79)`, ฝ่าเท้าซ้าย = `(-0.11, +1.55, +2.45)`) — ลำตัวโน้มพุ่งไปข้างหน้า -24° ขาขวาก้าวสูงรับแรงขับ (+56°) แขนซ้ายพุ่งนำ (+64°)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.056, +0.000)` | `(-24.0°, +14.0°, +2.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.06 studs, โน้มหน้า (-rx) 24.0°, บิดลำตัวหันทางซ้าย (+ry) 14.0°, เอียงลำตัวทางซ้าย (+rz) 2.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+20.0°, -12.0°, -2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 20.0°, หันศีรษะมองทางขวา (-ry) 12.0°, เอียงศีรษะทางขวา (-rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-56.0°, +0.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 56.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+64.0°, +8.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 64.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+56.0°, +0.0°, +3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 56.0°, กางออกด้านขวา (+rz) 3.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-52.0°, +0.0°, -3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 52.0°, กางออกด้านซ้าย (-rz) 3.0° |

**Keyframe 2 — `t = 0.25` (`0.095 s`): Right Push-Off / Airborne Float Phase**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.220 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.49, +0.62, +1.53)`, ฝ่าเท้าซ้าย = `(-0.85, +0.32, +0.30)`) — จังหวะลอยตัวสั้น (Flight phase) เท้าทั้งสองพ้นพื้น >= 0.22 studs ขาซ้ายแทงทะลุขึ้นหน้า*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.040, +0.226, -0.050)` | `(-26.0°, +0.0°, -3.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางขวา (+X) 0.04 studs, ยกระดับลำตัว (ขึ้น +Y) 0.23 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.05 studs, โน้มหน้า (-rx) 26.0°, เอียงลำตัวทางขวา (-rz) 3.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+22.0°, +0.0°, +2.5°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 22.0°, เอียงศีรษะทางซ้าย (+rz) 2.5° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +0.0°, +16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 8.0°, กางออกด้านขวา (+rz) 16.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +0.0°, -16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 8.0°, กางออกด้านซ้าย (-rz) 16.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +0.0°, +3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 8.0°, กางออกด้านขวา (+rz) 3.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+28.0°, +0.0°, -7.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 28.0°, กางออกด้านซ้าย (-rz) 7.0° |

**Keyframe 3 — `t = 0.50` (`0.190 s`): Left Drive Contact & Counter-Torque**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.11, +1.55, +2.45)`, ฝ่าเท้าซ้าย = `(-0.27, +0.29, -0.79)`) — เท้าซ้ายลงกระแทกส่งแรง ขาขวาเหยียดส่งหลังสุด (-52°) แขนขวาฟันขึ้นหน้า (+64°)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.056, +0.000)` | `(-24.0°, -14.0°, -2.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.06 studs, โน้มหน้า (-rx) 24.0°, บิดลำตัวหันทางขวา (-ry) 14.0°, เอียงลำตัวทางขวา (-rz) 2.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+20.0°, +12.0°, +2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 20.0°, หันศีรษะมองทางซ้าย (+ry) 12.0°, เอียงศีรษะทางซ้าย (+rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+64.0°, -8.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 64.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-56.0°, +0.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 56.0°, กางออกด้านซ้าย (-rz) 14.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-52.0°, +0.0°, +3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 52.0°, กางออกด้านขวา (+rz) 3.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+56.0°, +0.0°, -3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 56.0°, กางออกด้านซ้าย (-rz) 3.0° |

**Keyframe 4 — `t = 0.75` (`0.285 s`): Left Push-Off / Airborne Float Phase**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.220 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.85, +0.32, +0.30)`, ฝ่าเท้าซ้าย = `(-0.49, +0.62, +1.53)`) — จังหวะลอยตัวฝั่งซ้าย ขาขวาพุ่งทะลุผ่านแกนกลางเตรียมลงสัมผัสพื้นรอบถัดไป*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.040, +0.226, -0.050)` | `(-26.0°, +0.0°, +3.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.04 studs, ยกระดับลำตัว (ขึ้น +Y) 0.23 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.05 studs, โน้มหน้า (-rx) 26.0°, เอียงลำตัวทางซ้าย (+rz) 3.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+22.0°, +0.0°, -2.5°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 22.0°, เอียงศีรษะทางขวา (-rz) 2.5° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +0.0°, +16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 8.0°, กางออกด้านขวา (+rz) 16.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +0.0°, -16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 8.0°, กางออกด้านซ้าย (-rz) 16.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+28.0°, +0.0°, +7.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 28.0°, กางออกด้านขวา (+rz) 7.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +0.0°, -3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 8.0°, กางออกด้านซ้าย (-rz) 3.0° |

**Keyframe 5 — `t = 1.00` (`0.380 s`): Right Drive Contact (Loop Closure)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.27, +0.29, -0.79)`, ฝ่าเท้าซ้าย = `(-0.11, +1.55, +2.45)`) — ครบรอบสปรินต์ 0.38 วินาที ต่อเข้า t=0.00 ตรงกันทุกแกน*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.056, +0.000)` | `(-24.0°, +14.0°, +2.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.06 studs, โน้มหน้า (-rx) 24.0°, บิดลำตัวหันทางซ้าย (+ry) 14.0°, เอียงลำตัวทางซ้าย (+rz) 2.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+20.0°, -12.0°, -2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 20.0°, หันศีรษะมองทางขวา (-ry) 12.0°, เอียงศีรษะทางขวา (-rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-56.0°, +0.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 56.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+64.0°, +8.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 64.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+56.0°, +0.0°, +3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 56.0°, กางออกด้านขวา (+rz) 3.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-52.0°, +0.0°, -3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 52.0°, กางออกด้านซ้าย (-rz) 3.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A03

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: High-drive alternating stance (t=0.00 Right, t=0.50 Left) with true airborne suspension phases at t=0.25 and t=0.75 (min clearance 0.22 studs).
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.015 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.160 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A03

* **เข้าจากท่า (Enter From)**: A02 Walk (Phase-synced t_sprint = t_walk, 0.10s), A04 Dash Burst (chains at t=0.50 Left Drive, 0.06s), A01 Idle (0.10s)
* **ออกไปท่า (Exit To)**: A02 Walk (Phase-synced t_walk = t_sprint, 0.12s), A01 Idle (0.14s), A06 Jump (0.04s), A17 Slide Tackle (0.05s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `Right Hip, Left Hip, Right Shoulder, Left Shoulder, RootJoint, Neck`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Phase-synchronized crossfade to A02 Walk when speed drops below 24 studs/s so the active lead leg never reverses mid-swing.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: การโน้ม Torso -24° และการเหวี่ยงขาถึง +56°/-52° ทำให้ขอบล่างของขาเฉียงต้องชดเชย RootJoint ty = +0.34 studs ในจังหวะแตะพื้นเพื่อป้องกันมุมกล่องขาทะลุพื้น

### A04 — Dash Burst

* **1) ID / ชื่อ / โหมด**: `A04` — **Dash Burst** | โหมด: **`One-shot`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A04.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Top-Front 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.22 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.03 s`, `blendOut = 0.06 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.00..0.27 (Left Foot Push-Off), t = 1.00 (Right/Left Sprint Catch)`
  * **การอิงสถานะจริง (State Binding)**: `Triggered on Dash input (0.22s burst window); HRP moved by gameplay controller`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A04 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Entry Coil & Rear Foot Load**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.80, +0.16, +0.26)`, ฝ่าเท้าซ้าย = `(-0.82, +0.78, +1.92)`) — Entry: ถอยจุดศูนย์ถ่วงสายตา (tz=+0.18) อัดแรงลงขาซ้ายด้านหลัง เตรียมระเบิดตัว*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.071, +0.180)` | `(-18.0°, -10.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.07 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.18 studs, โน้มหน้า (-rx) 18.0°, บิดลำตัวหันทางขวา (-ry) 10.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+16.0°, +10.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 16.0°, หันศีรษะมองทางซ้าย (+ry) 10.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-38.0°, +0.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 38.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+36.0°, +0.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 36.0°, กางออกด้านซ้าย (-rz) 14.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+28.0°, +0.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 28.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-32.0°, +0.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 32.0°, กางออกด้านซ้าย (-rz) 4.0° |

**Keyframe 2 — `t = 0.27` (`0.060 s`): Explosive Push-Off & Chest Drop**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.34, +0.28, -0.53)`, ฝ่าเท้าซ้าย = `(-0.16, +2.15, +2.71)`) — Burst Start: ขาซ้ายถีบส่งหลังสุด (-58°) ขาขวาแทงนำ (+64°) ลำตัวกดต่ำพุ่งขนานพื้น (-34°)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.103, +0.040)` | `(-34.0°, +12.0°, +3.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.10 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.04 studs, โน้มหน้า (-rx) 34.0°, บิดลำตัวหันทางซ้าย (+ry) 12.0°, เอียงลำตัวทางซ้าย (+rz) 3.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+28.0°, -12.0°, -2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 28.0°, หันศีรษะมองทางขวา (-ry) 12.0°, เอียงศีรษะทางขวา (-rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-68.0°, +0.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 68.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+74.0°, +10.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 74.0°, เปิดออกด้านนอก (+ry) 10.0°, กางออกด้านซ้าย (-rz) 14.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+64.0°, +0.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 64.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-58.0°, +0.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 58.0°, กางออกด้านซ้าย (-rz) 4.0° |

**Keyframe 3 — `t = 0.68` (`0.150 s`): Peak Horizontal Surge (Visual Offset -Z)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.120 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.47, +0.28, -0.39)`, ฝ่าเท้าซ้าย = `(-0.32, +1.68, +2.33)`) — Burst Peak: ส่ง visual offset tz=-0.18 studs นำหน้า HRP ชั่วคราว อ่านแรงพุ่งชัดเจนโดยไม่ลอยสูงเหมือนกระโดด*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.093, -0.180)` | `(-30.0°, +8.0°, +2.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.09 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.18 studs, โน้มหน้า (-rx) 30.0°, บิดลำตัวหันทางซ้าย (+ry) 8.0°, เอียงลำตัวทางซ้าย (+rz) 2.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+24.0°, -8.0°, -1.5°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 24.0°, หันศีรษะมองทางขวา (-ry) 8.0°, เอียงศีรษะทางขวา (-rz) 1.5° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-42.0°, +0.0°, +15.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 42.0°, กางออกด้านขวา (+rz) 15.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+56.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 56.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+48.0°, +0.0°, +3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 48.0°, กางออกด้านขวา (+rz) 3.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-44.0°, +0.0°, -3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 44.0°, กางออกด้านซ้าย (-rz) 3.0° |

**Keyframe 4 — `t = 1.00` (`0.220 s`): Exit Catch -> Seamless Hand-off to Sprint**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.11, +1.55, +2.45)`, ฝ่าเท้าซ้าย = `(-0.27, +0.29, -0.79)`) — Exit: คืน tz=0.00 และจัดท่าตรงกับ A03 Sprint (t=0.50 Left Drive) เพื่อวิ่งต่อทันทีโดยขาไม่กระตุก*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.056, +0.000)` | `(-24.0°, -14.0°, -2.5°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.06 studs, โน้มหน้า (-rx) 24.0°, บิดลำตัวหันทางขวา (-ry) 14.0°, เอียงลำตัวทางขวา (-rz) 2.5° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+20.0°, +12.0°, +2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 20.0°, หันศีรษะมองทางซ้าย (+ry) 12.0°, เอียงศีรษะทางซ้าย (+rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+64.0°, -8.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 64.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-56.0°, +0.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 56.0°, กางออกด้านซ้าย (-rz) 14.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-52.0°, +0.0°, +3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 52.0°, กางออกด้านขวา (+rz) 3.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+56.0°, +0.0°, -3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 56.0°, กางออกด้านซ้าย (-rz) 3.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A04

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Left Leg explosive push-off (t=0.00..0.27), Right Leg lead drive (rx=+64°), transitioning cleanly into A03 Sprint at t=0.50.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.087 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A04

* **เข้าจากท่า (Enter From)**: A01 Idle (0.03s), A02 Walk (0.03s), A03 Sprint (0.03s), A05 Strafe (0.03s)
* **ออกไปท่า (Exit To)**: A03 Sprint at phase t=0.50 (0.06s), A02 Walk (0.08s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: KF4 matches A03 Sprint KF3 (t=0.50) with RootJoint tz returned to 0.00 so hand-off into Sprint has zero positional snap.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: แยก Visual Offset (RootJoint tz จาก +0.18 ไป -0.18 แล้วคืน 0.00) ออกจากตำแหน่ง HRP จริงอย่างเด็ดขาด ทำให้เห็นแรงกระชากต้นจังหวะโดยไม่ทำให้ hitbox วาร์ป

### A05 — Shift Lock 8-Way Strafe

* **1) ID / ชื่อ / โหมด**: `A05` — **Shift Lock 8-Way Strafe** | โหมด: **`Loop (2D Directional Blend Space: F, B, L, R, FL, FR, BL, BR)`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A05.png` (แสดงครบ 5 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Front (-Z Shift-Lock View)` และมุมเสริม `Top-Front 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.44 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.08 s`, `blendOut = 0.10 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.00 & t = 0.50 (Alternating lateral/diagonal plant)`
  * **การอิงสถานะจริง (State Binding)**: `ShiftLock Enabled & Grounded (Driven by local MoveDirection vector in HRP space)`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A05 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Wide Lateral Push-Off (Strafe Right Contact)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+1.08, +0.22, +0.49)`, ฝ่าเท้าซ้าย = `(-1.79, +0.62, +0.55)`) — ลำตัวหันหน้า -Z ตาม Shift Lock เอียงตัวเข้าหาทิศขวา (rz=-8°) ขาขวาก้าวเปิดออก (+28°) ขาซ้ายถีบส่ง*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.352, +0.000)` | `(-10.0°, -8.0°, -8.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.35 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางขวา (-ry) 8.0°, เอียงลำตัวทางขวา (-rz) 8.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +8.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0°, หันศีรษะมองทางซ้าย (+ry) 8.0°, เอียงศีรษะทางซ้าย (+rz) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+18.0°, -8.0°, +26.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 26.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-14.0°, +8.0°, -22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 14.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 22.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+8.0°, -8.0°, +28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 8.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 28.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +6.0°, -24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 8.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 24.0° |

**Keyframe 2 — `t = 0.25` (`0.110 s`): Low Shuffle Glide / Mid-Gather**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.040 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.52, +0.16, +0.51)`, ฝ่าเท้าซ้าย = `(-0.69, +0.46, +0.01)`) — ดึงขาซ้ายรวบเข้าหาแกนกลาง (rz=+6°) โดยไม่ไขว้ขาตัดกัน เพื่อพร้อมเปลี่ยนทิศได้ทุกเมื่อ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.050, +0.304, +0.000)` | `(-11.0°, -6.0°, -10.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางขวา (+X) 0.05 studs, ยกระดับลำตัว (ขึ้น +Y) 0.30 studs, โน้มหน้า (-rx) 11.0°, บิดลำตัวหันทางขวา (-ry) 6.0°, เอียงลำตัวทางขวา (-rz) 10.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+11.0°, +6.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 11.0°, หันศีรษะมองทางซ้าย (+ry) 6.0°, เอียงศีรษะทางซ้าย (+rz) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+6.0°, -6.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +6.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 18.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+4.0°, -6.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 4.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+12.0°, +4.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 12.0°, เปิดออกด้านนอก (+ry) 4.0°, หุบเข้าหาลำตัว (+rz) 6.0° |

**Keyframe 3 — `t = 0.50` (`0.220 s`): Left Plant & Right Lead Reach**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+1.21, +0.39, +1.07)`, ฝ่าเท้าซ้าย = `(-1.21, +0.38, +0.08)`) — เท้าซ้ายวางรับน้ำหนัก ขาขวากางเหยียดนำทางขวา (+32°) แขนกางช่วยถ่วงสมดุลด้านข้าง*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.030, +0.347, +0.000)` | `(-10.0°, -10.0°, -6.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.03 studs, ยกระดับลำตัว (ขึ้น +Y) 0.35 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางขวา (-ry) 10.0°, เอียงลำตัวทางขวา (-rz) 6.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +10.0°, +5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0°, หันศีรษะมองทางซ้าย (+ry) 10.0°, เอียงศีรษะทางซ้าย (+rz) 5.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-14.0°, -8.0°, +22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 14.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 22.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+20.0°, +8.0°, -26.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 20.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 26.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -10.0°, +32.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 10.0°, กางออกด้านขวา (+rz) 32.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |

**Keyframe 4 — `t = 0.75` (`0.330 s`): Right Plant & Left Push Recovery**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.76, +0.12, +0.35)`, ฝ่าเท้าซ้าย = `(-1.49, +0.40, +0.50)`) — ขาขวารับน้ำหนักเต็มแท่ง ขาซ้ายกางออกเตรียมถีบส่งในรอบถัดไป*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.020, +0.250, +0.000)` | `(-11.0°, -8.0°, -7.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางขวา (+X) 0.02 studs, ยกระดับลำตัว (ขึ้น +Y) 0.25 studs, โน้มหน้า (-rx) 11.0°, บิดลำตัวหันทางขวา (-ry) 8.0°, เอียงลำตัวทางขวา (-rz) 7.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+11.0°, +8.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 11.0°, หันศีรษะมองทางซ้าย (+ry) 8.0°, เอียงศีรษะทางซ้าย (+rz) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -8.0°, +20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 20.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-6.0°, +8.0°, -20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 20.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 16.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-4.0°, +6.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 4.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 18.0° |

**Keyframe 5 — `t = 1.00` (`0.440 s`): Wide Lateral Push-Off (Loop Closure)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+1.08, +0.22, +0.49)`, ฝ่าเท้าซ้าย = `(-1.79, +0.62, +0.55)`) — ครบรอบ সাইด์สเต็ป 0.44 วินาที ต่อเข้า t=0.00 ตรงกันทุกค่า*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.352, +0.000)` | `(-10.0°, -8.0°, -8.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.35 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางขวา (-ry) 8.0°, เอียงลำตัวทางขวา (-rz) 8.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +8.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0°, หันศีรษะมองทางซ้าย (+ry) 8.0°, เอียงศีรษะทางซ้าย (+rz) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+18.0°, -8.0°, +26.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 26.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-14.0°, +8.0°, -22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 14.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 22.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+8.0°, -8.0°, +28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 8.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 28.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +6.0°, -24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 8.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 24.0° |

#### ตารางพารามิเตอร์ครบทั้ง 8 ทิศทางของ A05 Shift Lock 8-Way Strafe

| ทิศทาง (Direction) | เวกเตอร์เคลื่อนที่ใน HRP Space | Torso Pitch `rx` (deg) | Torso Yaw `ry` (deg) | Torso Roll `rz` (deg) | Neck Yaw ชดเชย `ry` (deg) | แอมพลิจูดก้าวหน้า-หลัง `hip_rx` (deg) | แอมพลิจูดก้าวข้าง `hip_rz` (deg) | ลักษณะ Footwork และการทรงตัว |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **F (0°)** | `(0, 0, -1)` | `-10.0°` | `+0.0°` | `+0.0°` | `+0.0°` | `+36.0°` | `+2.0°` | เดินหน้าตรง โน้มอก -10° ก้าวหน้า-หลังตามแกน Z |
| **FR (+45°)** | `(+0.71, 0, -0.71)` | `-9.0°` | `-24.0°` | `-6.0°` | `+20.0°` | `+28.0°` | `+18.0°` | เฉียงหน้าขวา บิดสะโพก/ลำตัว -24° หันคอชดเชย +20° ก้าวเฉียงเปิดสะโพกขวา |
| **R (+90°)** | `(+1, 0, 0)` | `-10.0°` | `-8.0°` | `-8.0°` | `+8.0°` | `+8.0°` | `+28.0°` | สไลด์ข้างขวา (Side-shuffle) เอียงตัว -8° กางขาตามแกน X โดยไม่ไขว้ขา |
| **BR (+135°)** | `(+0.71, 0, +0.71)` | `-5.0°` | `+24.0°` | `-6.0°` | `-20.0°` | `-26.0°` | `+18.0°` | ถอยเฉียงขวา (Drop-step) เปิดสะโพกซ้าย +24° ถอยขาขวาลงรับน้ำหนัก |
| **B (180°)** | `(0, 0, +1)` | `-4.0°` | `+0.0°` | `+0.0°` | `+0.0°` | `-32.0°` | `+3.0°` | ถอยหลังตรง ลำตัวตั้งขึ้น (-4°) ก้าวถอยด้วยปลายเท้า ส่งแรงย้อนเฟส |
| **BL (-135°)** | `(-0.71, 0, +0.71)` | `-5.0°` | `-24.0°` | `+6.0°` | `+20.0°` | `-26.0°` | `-18.0°` | ถอยเฉียงซ้าย (Drop-step) เปิดสะโพกขวา -24° หันคอชดเชย +20° |
| **L (-90°)** | `(-1, 0, 0)` | `-10.0°` | `+8.0°` | `+8.0°` | `-8.0°` | `+8.0°` | `-28.0°` | สไลด์ข้างซ้าย เอียงตัว +8° กางขาซ้ายนำ + ขาขวารวบตาม |
| **FL (-45°)** | `(-0.71, 0, -0.71)` | `-9.0°` | `+24.0°` | `+6.0°` | `-20.0°` | `+28.0°` | `-18.0°` | เฉียงหน้าซ้าย บิดลำตัว +24° หันคอชดเชย -20° ก้าวเฉียงเปิดสะโพกซ้าย |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A05

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Side-shuffle / diagonal drop-step without leg crossover so instantaneous direction reversal never tangles limbs.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.352 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A05

* **เข้าจากท่า (Enter From)**: A01 Idle (0.08s), A02 Walk (0.08s), A03 Sprint (0.10s)
* **ออกไปท่า (Exit To)**: A01 Idle (0.10s), A04 Dash Burst (0.03s), A06 Jump (0.04s), A12/A14/A16/A17 Actions
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: 2D Bilinear / Polar Blend over normalized local velocity (vx, vz) with exponential smoothing (lambda = 14 s^-1) and signed hip-twist clamping (|ry| <= 24°) to prevent 180° flip when switching between forward-diagonal and backward-diagonal quadrants.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: ไม่ใช้ท่าไขว้ขา (Carioca crossover) เพราะหากผู้เล่นกดสลับซ้าย-ขวา (A/D) ทันที ขา R6 ที่เป็นแท่งแข็งจะกวาดทะลุกัน จึงใช้ Side-shuffle ผสมการบิดสะโพกไม่เกิน ±24° แทน

### A06 — Directional Jump / Fall

* **1) ID / ชื่อ / โหมด**: `A06` — **Directional Jump / Fall** | โหมด: **`One-shot / State-driven Airborne`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A06.png` (แสดงครบ 5 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front-Right 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.72 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.04 s`, `blendOut = 0.04 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.00 (Ground Takeoff Impulse); Airborne for t > 0.08 until Raycast/State Landed`
  * **การอิงสถานะจริง (State Binding)**: `Phase mapped dynamically from vertical velocity: t = clamp(0.5 - 0.5*(vy / v_jump), 0.12, 0.98) while Airborne`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A06 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Takeoff Coil & Directional Impulse Lock**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.71, +0.14, -0.08)`, ฝ่าเท้าซ้าย = `(-0.71, +0.61, +1.65)`) — Takeoff: กดลำตัวโน้มหน้า -18° ดึงแขนสองข้างไปด้านหลัง (-36°) เตรียมเหวี่ยงส่งแรงถีบขึ้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.095, +0.000)` | `(-18.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.10 studs, โน้มหน้า (-rx) 18.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+22.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 22.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-36.0°, +0.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 36.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-36.0°, +0.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 36.0°, กางออกด้านซ้าย (-rz) 14.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+28.0°, -6.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 28.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-24.0°, +6.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 24.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 2 — `t = 0.25` (`0.180 s`): Ascent Drive (Rising Velocity vy > 0)**
*(HRP Ref Y = `4.10 studs` | Lowest OBB Corner Clearance = **`+0.800 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.86, +1.17, -0.99)`, ฝ่าเท้าซ้าย = `(-0.80, +1.11, +1.14)`) — Ascent: เหวี่ยงแขนชูขึ้น (+110°/+95°) ขาขวาแทงนำ (+42°) ขาซ้ายเหยียดส่งหลัง (-28°)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.299, +0.000)` | `(-6.0°, -8.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.30 studs, โน้มหน้า (-rx) 6.0°, บิดลำตัวหันทางขวา (-ry) 8.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +8.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 14.0°, หันศีรษะมองทางซ้าย (+ry) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+110.0°, +0.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 110.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+95.0°, +0.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 95.0°, กางออกด้านซ้าย (-rz) 18.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+42.0°, +0.0°, +5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 42.0°, กางออกด้านขวา (+rz) 5.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-28.0°, +0.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 28.0°, กางออกด้านซ้าย (-rz) 5.0° |

**Keyframe 3 — `t = 0.50` (`0.360 s`): Dynamic Apex Transition (vy ≈ 0)**
*(HRP Ref Y = `4.80 studs` | Lowest OBB Corner Clearance = **`+1.500 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.78, +1.84, -1.06)`, ฝ่าเท้าซ้าย = `(-0.78, +1.63, +0.05)`) — Apex: จุดเปลี่ยนความเร็วแนวดิ่ง (vy ผ่าน 0) กางแขนทรงตัว (+34°/-34°) ไม่ค้างแข็งแต่ไหลผ่านตามค่า vy*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.142, +0.000)` | `(+8.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.14 studs, เอนหลัง (+rx) 8.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+4.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+68.0°, +0.0°, +34.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 68.0°, กางออกด้านขวา (+rz) 34.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+68.0°, +0.0°, -34.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 68.0°, กางออกด้านซ้าย (-rz) 34.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, -6.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-14.0°, +6.0°, -8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 8.0° |

**Keyframe 4 — `t = 0.78` (`0.560 s`): Descent Counter-Balance (vy < 0)**
*(HRP Ref Y = `4.00 studs` | Lowest OBB Corner Clearance = **`+0.700 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.74, +0.93, +0.77)`, ฝ่าเท้าซ้าย = `(-0.75, +0.85, -0.11)`) — Descent: ก้มมองจุดลงพื้น (-10°) กางแขนถ่วงอากาศ สลับขานำเตรียมแตะพื้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.151, +0.000)` | `(-8.0°, +4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.15 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางซ้าย (+ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-10.0°, -4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 10.0°, หันศีรษะมองทางขวา (-ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+28.0°, +0.0°, +42.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 28.0°, กางออกด้านขวา (+rz) 42.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+28.0°, +0.0°, -42.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 28.0°, กางออกด้านซ้าย (-rz) 42.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-12.0°, -4.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 12.0°, เปิดออกด้านนอก (-ry) 4.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+16.0°, +4.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 16.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 5 — `t = 1.00` (`0.720 s`): Pre-Landing Reach (Hands off to A07)**
*(HRP Ref Y = `3.15 studs` | Lowest OBB Corner Clearance = **`+0.100 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.71, +0.41, +1.14)`, ฝ่าเท้าซ้าย = `(-0.71, +0.20, -0.03)`) — Pre-Touchdown: จัดขาเหลื่อมหน้า-หลังพร้อมซับแรงส่งต่อไปยัง A07 Landing Cushion ทันทีที่แตะพื้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.055, +0.000)` | `(-12.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.06 studs, โน้มหน้า (-rx) 12.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-6.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +0.0°, +24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 14.0°, กางออกด้านขวา (+rz) 24.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +0.0°, -24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, กางออกด้านซ้าย (-rz) 24.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-16.0°, -5.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 16.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +5.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 6.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A06

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Left Leg rear push-off at t=0.00; airborne suspension t=0.10..1.00; prepares staggered dual-leg catch into A07.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+6.730 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A06

* **เข้าจากท่า (Enter From)**: A01 Idle (0.04s), A02 Walk (0.04s), A03 Sprint (0.04s), A05 Strafe (0.04s)
* **ออกไปท่า (Exit To)**: A07 Landing Cushion (0.03s on Landed), A08 Header (0.06s), A09 Aerial Block (0.06s), A10 Mid-Air Volley (0.06s), A11 Bicycle Kick (0.08s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Transitions immediately to A07 Landing Cushion upon HumanoidStateType.Landed or ground raycast hit.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: ทิศทางเอียงตัว (Pitch/Roll bias ±10°) ถูกล็อกตามเวกเตอร์ความเร็วแนวราบตอนกระโดดขึ้น (Takeoff) และไม่หักเลี้ยวกลางอากาศ तसेचไม่ใช้ค่า ty ของอนิเมชันไปแก้ความสูงฟิสิกส์จริง

### A07 — Landing Cushion

* **1) ID / ชื่อ / โหมด**: `A07` — **Landing Cushion** | โหมด: **`One-shot (Additive / Interruptible)`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A07.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front (-Z View)`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.24 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.03 s`, `blendOut = 0.08 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.00..0.33 (Ground Impact Cushion)`
  * **การอิงสถานะจริง (State Binding)**: `Triggered on Landed state transition; never locks player movement input`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A07 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Touchdown Contact (From A06 Descent)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.71, +0.32, +1.14)`, ฝ่าเท้าซ้าย = `(-0.71, +0.11, -0.03)`) — เริ่มแตะพื้นด้วยขาเหลื่อมหน้า-หลัง (+18°/-16°) รับโมเมนตัมแนวดิ่ง*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.115, +0.000)` | `(-12.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.12 studs, โน้มหน้า (-rx) 12.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +0.0°, +24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 14.0°, กางออกด้านขวา (+rz) 24.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +0.0°, -24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, กางออกด้านซ้าย (-rz) 24.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-16.0°, -5.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 16.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +5.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 2 — `t = 0.33` (`0.080 s`): Peak Impact Absorption (Split-Leg R6 Cushion)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.75, +0.95, +2.09)`, ฝ่าเท้าซ้าย = `(-0.74, +0.12, +0.10)`) — ซับแรงสูงสุด: กางขาเหลื่อมหน้า-หลัง (+30°/-28°) และกางออก (±10°) ทำให้ลด RootJoint ty ลงและกดอกต่ำ (-24°) ได้โดยขาไม่ทะลุพื้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.109, +0.000)` | `(-24.0°, -6.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.11 studs, โน้มหน้า (-rx) 24.0°, บิดลำตัวหันทางขวา (-ry) 6.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+20.0°, +6.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 20.0°, หันศีรษะมองทางซ้าย (+ry) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+28.0°, -8.0°, +28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 28.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 28.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-18.0°, +8.0°, -26.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 18.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 26.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-28.0°, -8.0°, +10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 28.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 10.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+30.0°, +8.0°, -10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 30.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 10.0° |

**Keyframe 3 — `t = 0.67` (`0.160 s`): Elastic Rebound & Hip Gather**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.68, +0.30, +1.16)`, ฝ่าเท้าซ้าย = `(-0.68, +0.09, +0.16)`) — สปริงตัวกลับขึ้นจากแรงกด ดึงขากลับเข้าสู่ระยะพร้อมก้าววิ่งต่อทันที*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.111, +0.000)` | `(-14.0°, -4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.11 studs, โน้มหน้า (-rx) 14.0°, บิดลำตัวหันทางขวา (-ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+12.0°, +4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 12.0°, หันศีรษะมองทางซ้าย (+ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+16.0°, -6.0°, +16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 16.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 16.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+12.0°, +6.0°, -16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 12.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 16.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-12.0°, -6.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 12.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 4 — `t = 1.00` (`0.240 s`): Ready / Locomotion Recovery**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.63, +0.18, +0.64)`, ฝ่าเท้าซ้าย = `(-0.62, +0.11, +0.13)`) — คืนสู่ท่า A01 Ready เต็มตัว (หรือ blend ออกเข้า Walk/Sprint ได้ตั้งแต่ t=0.33 โดยไม่ล็อกการควบคุม)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.140, +0.000)` | `(-8.0°, -4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A07

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Split-stance dual support (Left Leg forward +30°, Right Leg back -28°, roll ±10°) enabling true center-of-mass drop without R6 knees.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.140 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A07

* **เข้าจากท่า (Enter From)**: A06 Directional Jump / Fall (0.03s), A08/A09/A10 Aerial Actions (0.04s)
* **ออกไปท่า (Exit To)**: A01 Idle (0.08s), A02 Walk (interruptible immediately with 0.08s blend), A03 Sprint (0.08s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `Right Hip, Left Hip (blended 50% if player holds move input during landing)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Non-blocking playback: if MoveDirection.Magnitude > 0.1, blends 50% of RootJoint/Torso dip as an additive cushion over Walk/Sprint.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: เพราะ R6 ไม่มีเข่า การกด RootJoint ty ลงตรงๆ ในท่ายืนขาตรงจะทำให้จมพื้นทันที ทางแก้เชิงกลศาสตร์คือต้องกางขาหน้า-หลัง (±30°) และด้านข้าง (±10°) เพื่อให้ความสูงแนวดิ่งของขาทั้งแท่งลดลงจาก 2.00 studs เหลือ ~1.93 studs พร้อมโน้ม Torso -24°

### A08 — Header

* **1) ID / ชื่อ / โหมด**: `A08` — **Header** | โหมด: **`One-shot`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A08.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front-Left 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.48 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.06 s`, `blendOut = 0.10 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.45 (0.216 s) — Forehead impact on Ball`
  * **การอิงสถานะจริง (State Binding)**: `Executable Standing or Airborne (Reference preview shown at low aerial jump HRP.Y = 3.60 studs at contact)`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A08 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Torso Arch & Chest Expansion Coil**
*(HRP Ref Y = `3.45 studs` | Lowest OBB Corner Clearance = **`+0.400 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.68, +0.47, -0.21)`, ฝ่าเท้าซ้าย = `(-0.68, +0.47, -0.42)`) — ง้างลำตัวเป็นคันธนู (Torso rx=+22°, Neck rx=+12°) กางแขนไปด้านหลัง ขาพับส่งแรงจากสะโพก*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.019, +0.120)` | `(+22.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.02 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.12 studs, เอนหลัง (+rx) 22.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+12.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 12.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-28.0°, +0.0°, +32.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 28.0°, กางออกด้านขวา (+rz) 32.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-28.0°, +0.0°, -32.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 28.0°, กางออกด้านซ้าย (-rz) 32.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-24.0°, -5.0°, +5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 24.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 5.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-18.0°, +5.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 18.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 5.0° |

**Keyframe 2 — `t = 0.45` (`0.216 s`): Forehead Strike Contact (Kinetic Whip)**
*(HRP Ref Y = `3.60 studs` | Lowest OBB Corner Clearance = **`+0.500 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.64, +0.58, -0.04)`, ฝ่าเท้าซ้าย = `(-0.64, +0.57, +0.25)`) — Contact (t=0.45): พับลำตัวฟาดไปข้างหน้า (-20°) คอกดส่งแรง (-10°) หน้าผากปะทะผิวบอลด้านหลังบน*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.061, -0.140)` | `(-20.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.06 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.14 studs, โน้มหน้า (-rx) 20.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-10.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 10.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-42.0°, +0.0°, +22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 42.0°, กางออกด้านขวา (+rz) 22.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-42.0°, +0.0°, -22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 42.0°, กางออกด้านซ้าย (-rz) 22.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+26.0°, -4.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 26.0°, เปิดออกด้านนอก (-ry) 4.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +4.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 4.0° |

**Keyframe 3 — `t = 0.72` (`0.346 s`): Full Torso Follow-Through & Pike**
*(HRP Ref Y = `3.30 studs` | Lowest OBB Corner Clearance = **`+0.250 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.68, +0.37, +0.12)`, ฝ่าเท้าซ้าย = `(-0.68, +0.48, +0.96)`) — Follow-through: ส่งแรงต่อเนื่องจากแกนลำตัว (-28°) แขนกวาดไปด้านหลังช่วยถ่วงไม่ให้หัวทิ่ม*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.018, -0.180)` | `(-28.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.02 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.18 studs, โน้มหน้า (-rx) 28.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-14.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 14.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-48.0°, +0.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 48.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-48.0°, +0.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 48.0°, กางออกด้านซ้าย (-rz) 18.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+32.0°, -5.0°, +5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 32.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 5.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +5.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 8.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 5.0° |

**Keyframe 4 — `t = 1.00` (`0.480 s`): Balance Recovery & Landing Prep**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.68, +0.26, +0.92)`, ฝ่าเท้าซ้าย = `(-0.68, +0.12, +0.01)`) — คืนสมดุลลำตัวและจัดขารับพื้น ต่อเข้า A07 Landing Cushion หรือ A01 Ready*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.136, +0.000)` | `(-10.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 10.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+12.0°, +0.0°, +16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 12.0°, กางออกด้านขวา (+rz) 16.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+12.0°, +0.0°, -16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 12.0°, กางออกด้านซ้าย (-rz) 16.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-12.0°, -4.0°, +5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 12.0°, เปิดออกด้านนอก (-ry) 4.0°, กางออกด้านขวา (+rz) 5.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +4.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 5.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A08

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Airborne hip counter-snap (legs swing from -24° back-arch to +26° forward pike to balance torso whip); lands on staggered legs at t=1.00.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.015 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.595 studs`
* **เรขาคณิตการปะทะลูกบอล (Ball Contact Geometry ที่ `t = 0.45`, `time = 0.216 s`)**:
  * **ชิ้นส่วนที่สัมผัสลูกบอล**: `Head`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน Part Local Space**: `(+0.000, +0.500, -0.500) studs`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน World / Character Space**: `(+0.000, +5.095, -1.415) studs`
  * **ตำแหน่งจุดศูนย์กลางลูกบอล (`R = 1.25 studs`)**: `(+0.000, +5.047, -2.664) studs`
  * **ระยะห่างจากผิวกล่อง OBB ถึงจุดศูนย์กลางบอล**: **`1.250 studs`** (เท่ากับรัศมีลูกบอล `1.250 studs` พอดี ไม่มีการย่อขนาดบอลและไม่มีขาเอื้อมไม่ถึง)

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A08

* **เข้าจากท่า (Enter From)**: A06 Directional Jump (0.06s), A01 Idle (0.06s), A02/A03 Locomotion (0.06s)
* **ออกไปท่า (Exit To)**: A07 Landing Cushion (0.04s if landing), A01 Idle (0.10s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Blends into A07 Landing Cushion on ground contact or 0.10s crossfade to A01.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: จำกัดมุมก้ม-เงยของ Neck ไม่ให้เกิน +12° ถึง -14° เพื่อไม่ให้หัว R6 บิดหลุดขอบ Torso โดยใช้การพับ Torso (+22° ไป -28°) เป็นตัวสร้างแรงโหม่งหลัก

### A09 — Aerial Block

* **1) ID / ชื่อ / โหมด**: `A09` — **Aerial Block** | โหมด: **`One-shot`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A09.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front-Right 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.52 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.05 s`, `blendOut = 0.10 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.42 (0.218 s) — Anterior Torso / Chest Wall impact`
  * **การอิงสถานะจริง (State Binding)**: `Airborne intercept state (Reference HRP.Y = 3.75 studs at contact)`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A09 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Intercept Rise & Arms Pin Behind Back**
*(HRP Ref Y = `3.50 studs` | Lowest OBB Corner Clearance = **`+0.450 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.42, +0.75, -1.26)`, ฝ่าเท้าซ้าย = `(-1.00, +0.68, +0.61)`) — ขึ้นขวางวิถีบอล: หันอกเฉียงรับบอล (ry=+18°) เก็บแขนสองข้างไพล่หลัง (-34°) ชัดเจน ไม่ใช้มือปัดบอล*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.132, +0.000)` | `(+6.0°, +18.0°, -6.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.13 studs, เอนหลัง (+rx) 6.0°, บิดลำตัวหันทางซ้าย (+ry) 18.0°, เอียงลำตัวทางขวา (-rz) 6.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-8.0°, -14.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 8.0°, หันศีรษะมองทางขวา (-ry) 14.0°, เอียงศีรษะทางซ้าย (+rz) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-34.0°, +20.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 34.0°, บิดเข้าด้านใน (+ry) 20.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-34.0°, -20.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 34.0°, บิดเข้าด้านใน (-ry) 20.0°, กางออกด้านซ้าย (-rz) 6.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+22.0°, -8.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 22.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-16.0°, +8.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 16.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 12.0° |

**Keyframe 2 — `t = 0.42` (`0.218 s`): Broad Chest / Upper-Torso Wall Contact**
*(HRP Ref Y = `3.75 studs` | Lowest OBB Corner Clearance = **`+0.700 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.33, +1.24, -1.74)`, ฝ่าเท้าซ้าย = `(-1.00, +0.95, +0.64)`) — Contact (t=0.42): แผ่นอกด้านหน้า (Torso) ขวางรับลูกบอลเต็มใบ เก็บคาง (-16°) และล็อกแขนไพล่หลัง (-42°)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.142, +0.000)` | `(+12.0°, +22.0°, -8.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, เอนหลัง (+rx) 12.0°, บิดลำตัวหันทางซ้าย (+ry) 22.0°, เอียงลำตัวทางขวา (-rz) 8.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-16.0°, -18.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 16.0°, หันศีรษะมองทางขวา (-ry) 18.0°, เอียงศีรษะทางซ้าย (+rz) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-42.0°, +24.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 42.0°, บิดเข้าด้านใน (+ry) 24.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-42.0°, -24.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 42.0°, บิดเข้าด้านใน (-ry) 24.0°, กางออกด้านซ้าย (-rz) 4.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+28.0°, -10.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 28.0°, เปิดออกด้านนอก (-ry) 10.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-22.0°, +10.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 22.0°, เปิดออกด้านนอก (+ry) 10.0°, กางออกด้านซ้าย (-rz) 14.0° |

**Keyframe 3 — `t = 0.72` (`0.374 s`): Impact Absorption Recoil in Air**
*(HRP Ref Y = `3.40 studs` | Lowest OBB Corner Clearance = **`+0.350 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.13, +0.75, -1.46)`, ฝ่าเท้าซ้าย = `(-0.87, +0.56, +0.63)`) — ซับแรงปะทะกลางอากาศ ลำตัวเอนรับแรงสะท้อน (tz=+0.10, rx=+18°) ก่อนคลายแขนออกเพื่อทรงตัวลงพื้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.121, +0.100)` | `(+18.0°, +26.0°, -10.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.12 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.10 studs, เอนหลัง (+rx) 18.0°, บิดลำตัวหันทางซ้าย (+ry) 26.0°, เอียงลำตัวทางขวา (-rz) 10.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-12.0°, -20.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 12.0°, หันศีรษะมองทางขวา (-ry) 20.0°, เอียงศีรษะทางซ้าย (+rz) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-24.0°, +14.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 24.0°, บิดเข้าด้านใน (+ry) 14.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-24.0°, -14.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 24.0°, บิดเข้าด้านใน (-ry) 14.0°, กางออกด้านซ้าย (-rz) 18.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+14.0°, -6.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-26.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 26.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |

**Keyframe 4 — `t = 1.00` (`0.520 s`): Re-Center & Touchdown Preparation**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.65, +0.26, +0.92)`, ฝ่าเท้าซ้าย = `(-0.87, +0.18, +0.02)`) — คืนแกนลำตัวกลับด้านหน้าและวางเท้าลงสู่ A07 Landing Cushion*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.153, +0.000)` | `(-10.0°, +6.0°, -2.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.15 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางซ้าย (+ry) 6.0°, เอียงลำตัวทางขวา (-rz) 2.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, -6.0°, +2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางขวา (-ry) 6.0°, เอียงศีรษะทางซ้าย (+rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +0.0°, +20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 14.0°, กางออกด้านขวา (+rz) 20.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +0.0°, -20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, กางออกด้านซ้าย (-rz) 20.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-14.0°, -5.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 14.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+16.0°, +5.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 16.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 6.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A09

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Wide airborne defensive spread (Right Leg forward-abducted +28°/+18°, Left Leg back -22°); lands into dual-leg cushion.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.015 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.987 studs`
* **เรขาคณิตการปะทะลูกบอล (Ball Contact Geometry ที่ `t = 0.42`, `time = 0.218 s`)**:
  * **ชิ้นส่วนที่สัมผัสลูกบอล**: `Torso`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน Part Local Space**: `(+0.062, +0.255, -0.500) studs`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน World / Character Space**: `(-0.098, +4.235, -0.438) studs`
  * **ตำแหน่งจุดศูนย์กลางลูกบอล (`R = 1.25 studs`)**: `(-0.566, +4.476, -1.572) studs`
  * **ระยะห่างจากผิวกล่อง OBB ถึงจุดศูนย์กลางบอล**: **`1.250 studs`** (เท่ากับรัศมีลูกบอล `1.250 studs` พอดี ไม่มีการย่อขนาดบอลและไม่มีขาเอื้อมไม่ถึง)

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A09

* **เข้าจากท่า (Enter From)**: A06 Directional Jump (0.05s), A01/A02/A05 Defensive Stance (0.06s)
* **ออกไปท่า (Exit To)**: A07 Landing Cushion (0.04s), A01 Idle (0.10s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Hands off to A07 Landing Cushion on ground contact.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: แยกภาพจำออกจาก A08 Header อย่างชัดเจนด้วยการบิด Torso เฉียง (+22°), กดคางเก็บหัว (-16°), และพับแขนทั้งสองไพล่หลัง (-42°) เพื่อสื่อการบล็อกด้วยหน้าอกโดยไม่แฮนด์บอล

### A10 — Mid-Air Volley

* **1) ID / ชื่อ / โหมด**: `A10` — **Mid-Air Volley** | โหมด: **`One-shot`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A10.png` (แสดงครบ 5 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front-Right 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.56 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.05 s`, `blendOut = 0.10 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.46 (0.258 s) — Right Leg anterior instep mid-air strike`
  * **การอิงสถานะจริง (State Binding)**: `Airborne volley (Reference HRP.Y = 3.80 studs at contact; Ball center Y = 3.25 studs)`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A10 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Airborne Side-Tilt & Kicking Leg Chamber**
*(HRP Ref Y = `3.55 studs` | Lowest OBB Corner Clearance = **`+0.500 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+1.20, +1.65, +2.07)`, ฝ่าเท้าซ้าย = `(+0.51, +0.85, -1.42)`) — ลอยตัวเอียงลำตัวทางซ้าย (rz=+22°) เปิดสะโพกขวา (-28°) ง้างขาขวาไปด้านหลัง (-48°) เตรียมฟาดวอลเลย์*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.087, +0.000)` | `(+12.0°, -28.0°, +22.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.09 studs, เอนหลัง (+rx) 12.0°, บิดลำตัวหันทางขวา (-ry) 28.0°, เอียงลำตัวทางซ้าย (+rz) 22.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-6.0°, +24.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 6.0°, หันศีรษะมองทางซ้าย (+ry) 24.0°, เอียงศีรษะทางขวา (-rz) 14.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-38.0°, -12.0°, +36.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 38.0°, เปิดออกด้านนอก (-ry) 12.0°, กางออกด้านขวา (+rz) 36.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+42.0°, +12.0°, -48.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 42.0°, เปิดออกด้านนอก (+ry) 12.0°, กางออกด้านซ้าย (-rz) 48.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-48.0°, -18.0°, +28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 48.0°, เปิดออกด้านนอก (-ry) 18.0°, กางออกด้านขวา (+rz) 28.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+28.0°, +10.0°, -16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 28.0°, เปิดออกด้านนอก (+ry) 10.0°, กางออกด้านซ้าย (-rz) 16.0° |

**Keyframe 2 — `t = 0.25` (`0.140 s`): Hip Whip Initiation & Scissor Fold**
*(HRP Ref Y = `3.75 studs` | Lowest OBB Corner Clearance = **`+0.750 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+2.61, +1.99, -0.05)`, ฝ่าเท้าซ้าย = `(+0.32, +0.87, -0.67)`) — เริ่มบิดสะโพกกลับเข้าหาบอล ขาซ้ายพับลงหลังเพื่อสร้างแรงปฏิกิริยา (Scissor torque) ส่งขาขวา*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.308, +0.000)` | `(+18.0°, -6.0°, +28.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.31 studs, เอนหลัง (+rx) 18.0°, บิดลำตัวหันทางขวา (-ry) 6.0°, เอียงลำตัวทางซ้าย (+rz) 28.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +6.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 6.0°, เอียงศีรษะทางขวา (-rz) 18.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-24.0°, +0.0°, +42.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 24.0°, กางออกด้านขวา (+rz) 42.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+54.0°, +0.0°, -56.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 54.0°, กางออกด้านซ้าย (-rz) 56.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -14.0°, +26.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 14.0°, กางออกด้านขวา (+rz) 26.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +8.0°, -20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 8.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 20.0° |

**Keyframe 3 — `t = 0.46` (`0.258 s`): Mid-Air Side-Volley Strike [Contact]**
*(HRP Ref Y = `3.80 studs` | Lowest OBB Corner Clearance = **`+0.850 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.99, +4.23, -2.78)`, ฝ่าเท้าซ้าย = `(+0.82, +1.10, -0.33)`) — Contact (t=0.46): ขาขวาทั้งแท่งฟาดขึ้นหน้า (+64°) ลำตัวเอียงถ่วงสมดุล (rx=+24°, rz=+32°) หน้าแข้ง/หลังเท้าขวาปะทะลูกบอลกลางอากาศ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.351, -0.060)` | `(+24.0°, +26.0°, +32.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.35 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.06 studs, เอนหลัง (+rx) 24.0°, บิดลำตัวหันทางซ้าย (+ry) 26.0°, เอียงลำตัวทางซ้าย (+rz) 32.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-12.0°, -22.0°, -20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 12.0°, หันศีรษะมองทางขวา (-ry) 22.0°, เอียงศีรษะทางขวา (-rz) 20.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-44.0°, +12.0°, +34.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 44.0°, บิดเข้าด้านใน (+ry) 12.0°, กางออกด้านขวา (+rz) 34.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+36.0°, -14.0°, -52.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 36.0°, บิดเข้าด้านใน (-ry) 14.0°, กางออกด้านซ้าย (-rz) 52.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+64.0°, -16.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 64.0°, เปิดออกด้านนอก (-ry) 16.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-36.0°, +12.0°, -22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 36.0°, เปิดออกด้านนอก (+ry) 12.0°, กางออกด้านซ้าย (-rz) 22.0° |

**Keyframe 4 — `t = 0.72` (`0.403 s`): High Across-Body Follow-Through**
*(HRP Ref Y = `3.45 studs` | Lowest OBB Corner Clearance = **`+0.450 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.73, +3.35, -2.17)`, ฝ่าเท้าซ้าย = `(+0.78, +0.72, -0.39)`) — Follow-through: ขาขวากวาดผ่านหน้าลำตัว (+78°, rz=-8°) ขาซ้ายเริ่มกางลงเตรียมรับพื้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.323, -0.040)` | `(+18.0°, +42.0°, +24.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.32 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.04 studs, เอนหลัง (+rx) 18.0°, บิดลำตัวหันทางซ้าย (+ry) 42.0°, เอียงลำตัวทางซ้าย (+rz) 24.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-10.0°, -34.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 10.0°, หันศีรษะมองทางขวา (-ry) 34.0°, เอียงศีรษะทางขวา (-rz) 14.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-52.0°, +18.0°, +28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 52.0°, บิดเข้าด้านใน (+ry) 18.0°, กางออกด้านขวา (+rz) 28.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+18.0°, -18.0°, -40.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 18.0°, บิดเข้าด้านใน (-ry) 18.0°, กางออกด้านซ้าย (-rz) 40.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+78.0°, -10.0°, -8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 78.0°, เปิดออกด้านนอก (-ry) 10.0°, หุบเข้าหาลำตัว (-rz) 8.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-28.0°, +8.0°, -16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 28.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 16.0° |

**Keyframe 5 — `t = 1.00` (`0.560 s`): Upright Re-Alignment & Landing Catch**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.84, +0.17, -0.12)`, ฝ่าเท้าซ้าย = `(-0.49, +0.29, +1.14)`) — ดึงลำตัวกลับตั้งตรง ลงพื้นด้วยขาซ้ายนำแล้วซับแรงต่อเข้า A07 Landing Cushion*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.158, +0.000)` | `(-10.0°, +8.0°, +4.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.16 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางซ้าย (+ry) 8.0°, เอียงลำตัวทางซ้าย (+rz) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, -8.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางขวา (-ry) 8.0°, เอียงศีรษะทางขวา (-rz) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+12.0°, +0.0°, +20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 12.0°, กางออกด้านขวา (+rz) 20.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+16.0°, +0.0°, -20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 16.0°, กางออกด้านซ้าย (-rz) 20.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+14.0°, -4.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (-ry) 4.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-16.0°, +4.0°, -8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 16.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 8.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A10

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Airborne scissor counter-balance (Left Leg swings backward -36° during strike, then drops first to catch landing at t=1.00).
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.015 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+6.336 studs`
* **เรขาคณิตการปะทะลูกบอล (Ball Contact Geometry ที่ `t = 0.46`, `time = 0.258 s`)**:
  * **ชิ้นส่วนที่สัมผัสลูกบอล**: `Right Leg`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน Part Local Space**: `(-0.500, -1.000, +0.208) studs`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน World / Character Space**: `(+0.608, +3.850, -2.881) studs`
  * **ตำแหน่งจุดศูนย์กลางลูกบอล (`R = 1.25 studs`)**: `(+0.449, +3.920, -4.119) studs`
  * **ระยะห่างจากผิวกล่อง OBB ถึงจุดศูนย์กลางบอล**: **`1.250 studs`** (เท่ากับรัศมีลูกบอล `1.250 studs` พอดี ไม่มีการย่อขนาดบอลและไม่มีขาเอื้อมไม่ถึง)

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A10

* **เข้าจากท่า (Enter From)**: A06 Directional Jump (0.05s), A01/A02/A03 Launch into Volley (0.06s)
* **ออกไปท่า (Exit To)**: A07 Landing Cushion (0.04s), A01 Idle (0.10s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Transitions to A07 Landing Cushion upon touchdown.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: ใช้การเอียง Torso (rx=+24°, ry=+26°, rz=+32°) ร่วมกับการหมุนสะโพกขวา (rx=+64°, ry=-16°, rz=+18°) เพื่อให้ขา R6 แท่งเดียวกวาดในระนาบเฉียงแบบ Side-Volley ได้สมจริงโดยไม่ต้องงอเข่า

### A11 — Bicycle Kick

* **1) ID / ชื่อ / โหมด**: `A11` — **Bicycle Kick** | โหมด: **`One-shot`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A11.png` (แสดงครบ 6 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Back-Right 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.88 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.06 s`, `blendOut = 0.12 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.48 (0.422 s) — Overhead inverted Right Leg strike (+Z ball trajectory)`
  * **การอิงสถานะจริง (State Binding)**: `Requires Airborne / Launch height: Torso World Y >= 2.25 studs at inversion apex (Reference Torso World Y = 4.40 studs at t = 0.48)`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A11 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Back-Lean Launch & Left Knee/Leg Pump**
*(HRP Ref Y = `3.20 studs` | Lowest OBB Corner Clearance = **`+0.250 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.68, +0.36, -0.87)`, ฝ่าเท้าซ้าย = `(-0.68, +2.17, -2.61)`) — เริ่มเอนหลัง (+36°) ยกขาซ้ายหลอกนำขึ้นก่อน (+48°) ขาขวาง้างส่งแรงถีบตัวขึ้นสู่อากาศ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.012, +0.000)` | `(+36.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.01 studs, เอนหลัง (+rx) 36.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-18.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 18.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+55.0°, +0.0°, +20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 55.0°, กางออกด้านขวา (+rz) 20.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+55.0°, +0.0°, -20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 55.0°, กางออกด้านซ้าย (-rz) 20.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-28.0°, +0.0°, +5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 28.0°, กางออกด้านขวา (+rz) 5.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+48.0°, +0.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 48.0°, กางออกด้านซ้าย (-rz) 5.0° |

**Keyframe 2 — `t = 0.24` (`0.211 s`): Inversion Pitch & Scissor Cocking**
*(HRP Ref Y = `3.85 studs` | Lowest OBB Corner Clearance = **`+1.400 studs`** ที่ชิ้นส่วน `Right Arm` | ฝ่าเท้าขวา = `(+0.71, +2.25, -2.79)`, ฝ่าเท้าซ้าย = `(-0.71, +4.89, -1.21)`) — พลิกลำตัวหงายหลัง (+108°) ขาซ้ายชี้ฟ้าถ่วงโมเมนตัม (+62°) ขาขวาง้างต่ำเตรียมสับสลับขา (Scissor)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -1.280, +0.100)` | `(+108.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 1.28 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.10 studs, เอนหลัง (+rx) 108.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-24.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 24.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+20.0°, +0.0°, +38.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 20.0°, กางออกด้านขวา (+rz) 38.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+20.0°, +0.0°, -38.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 20.0°, กางออกด้านซ้าย (-rz) 38.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-36.0°, +0.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 36.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+62.0°, +0.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 62.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 3 — `t = 0.48` (`0.422 s`): Inverted Overhead Strike [Ball Contact]**
*(HRP Ref Y = `4.15 studs` | Lowest OBB Corner Clearance = **`+1.800 studs`** ที่ชิ้นส่วน `Head` | ฝ่าเท้าขวา = `(+0.64, +6.31, +0.79)`, ฝ่าเท้าซ้าย = `(-0.64, +5.22, -2.22)`) — Contact (t=0.48): ลำตัวกลับหัว (+154°) ขาขวาฟาดข้ามศีรษะ (+58° ใน Torso space) ปะทะบอลด้านหลังศีรษะที่ความสูง ~5.1 studs*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.459, +0.150)` | `(+154.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.46 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.15 studs, เอนหลัง (+rx) 154.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-28.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 28.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-20.0°, +0.0°, +44.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 20.0°, กางออกด้านขวา (+rz) 44.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-20.0°, +0.0°, -44.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 20.0°, กางออกด้านซ้าย (-rz) 44.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+58.0°, +0.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 58.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-46.0°, +0.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 46.0°, กางออกด้านซ้าย (-rz) 4.0° |

**Keyframe 4 — `t = 0.68` (`0.598 s`): Overhead Follow-Through & Arm Reach Down**
*(HRP Ref Y = `3.55 studs` | Lowest OBB Corner Clearance = **`+1.100 studs`** ที่ชิ้นส่วน `Left Arm` | ฝ่าเท้าขวา = `(+0.51, +4.97, +0.35)`, ฝ่าเท้าซ้าย = `(-0.29, +3.59, -2.64)`) — Follow-through: ขาขวากวาดส่งบอลข้ามหัวสุดระยะ (+76°) เก็บคาง (-30°) กางแขนไปด้านหลัง (-62°) เตรียมรับพื้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -1.071, +0.200)` | `(+128.0°, +8.0°, +6.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 1.07 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.20 studs, เอนหลัง (+rx) 128.0°, บิดลำตัวหันทางซ้าย (+ry) 8.0°, เอียงลำตัวทางซ้าย (+rz) 6.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-30.0°, -6.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 30.0°, หันศีรษะมองทางขวา (-ry) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-62.0°, +0.0°, +26.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 62.0°, กางออกด้านขวา (+rz) 26.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-62.0°, +0.0°, -26.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 62.0°, กางออกด้านซ้าย (-rz) 26.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+76.0°, +0.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 76.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-24.0°, +0.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 24.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 5 — `t = 0.84` (`0.739 s`): Horizontal Back/Arm Cushion Breakfall**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.020 studs`** ที่ชิ้นส่วน `Left Arm` | ฝ่าเท้าขวา = `(+0.72, +1.90, -2.77)`, ฝ่าเท้าซ้าย = `(-0.56, +1.11, -2.91)`) — Breakfall: แผ่นหลังและแขนสองข้างวางซับแรงขนานพื้น (rx=+82°) เก็บคาง (-28°) ทำให้ศีรษะลอยพ้นพื้นปลอดภัย*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -1.702, +0.150)` | `(+82.0°, +12.0°, +4.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 1.70 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.15 studs, เอนหลัง (+rx) 82.0°, บิดลำตัวหันทางซ้าย (+ry) 12.0°, เอียงลำตัวทางซ้าย (+rz) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-28.0°, -8.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 28.0°, หันศีรษะมองทางขวา (-ry) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-14.0°, +0.0°, +24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 14.0°, กางออกด้านขวา (+rz) 24.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-14.0°, +0.0°, -24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 14.0°, กางออกด้านซ้าย (-rz) 24.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+24.0°, +0.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 24.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +0.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 10.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 6 — `t = 1.00` (`0.880 s`): Snap-Up Recovery to Athletic Ready**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.64, +0.18, +0.57)`, ฝ่าเท้าซ้าย = `(-0.64, +0.13, +0.00)`) — ดีดตัวลุกกลับสู่ท่ายืนพร้อมเล่น (A01 Ready) ครบวงจร 0.88 วินาที*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.152, +0.000)` | `(-6.0°, +0.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.15 studs, โน้มหน้า (-rx) 6.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +0.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+12.0°, -6.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 12.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+12.0°, +6.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 12.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 14.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 8.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 8.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A11

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Left Leg pumps upward first (t=0.00..0.24) to generate angular momentum, then scissors down (-46°) as Right Leg whips overhead (+58°); Back + Both Arms cushion landing at t=0.84.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.015 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+6.606 studs`
* **เรขาคณิตการปะทะลูกบอล (Ball Contact Geometry ที่ `t = 0.48`, `time = 0.422 s`)**:
  * **ชิ้นส่วนที่สัมผัสลูกบอล**: `Right Leg`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน Part Local Space**: `(-0.067, -1.000, -0.500) studs`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน World / Character Space**: `(+0.574, +6.050, +1.214) studs`
  * **ตำแหน่งจุดศูนย์กลางลูกบอล (`R = 1.25 studs`)**: `(+0.613, +5.929, +2.457) studs`
  * **ระยะห่างจากผิวกล่อง OBB ถึงจุดศูนย์กลางบอล**: **`1.250 studs`** (เท่ากับรัศมีลูกบอล `1.250 studs` พอดี ไม่มีการย่อขนาดบอลและไม่มีขาเอื้อมไม่ถึง)

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A11

* **เข้าจากท่า (Enter From)**: A06 Directional Jump (0.06s), A01/A02 Standing Launch (0.06s with jump impulse)
* **ออกไปท่า (Exit To)**: A01 Idle (0.12s), A02 Walk (0.12s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Self-contained 6-keyframe arc including breakfall cushion (KF5) and kip-up recovery (KF6) to A01.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: ข้อจำกัดความสูงและพื้นที่ (Hard Geometric Constraint): 1) ในท่ากลับหัว (RootJoint rx = 154°–180°) ขอบบนของ Head อยู่ห่างจากจุดศูนย์กลาง Torso 2.00 studs (มุมกล่อง 2.15 studs) ดังนั้นจุดศูนย์กลาง Torso ต้องอยู่สูงกว่า World Y = 2.15 studs เสมอ (ในสเปคนี้ที่ t=0.48 Torso World Y = 4.40 studs จึงมีระยะห่างหัวพ้นพื้น 2.41 studs) หากสั่งเล่นท่านี้ขณะที่ Torso World Y < 2.15 studs หัวจะทะลุพื้นทันที 2) พื้นที่ปลอดภัยรอบตัวต้องมีรัศมีอย่างน้อย Z ∈ [-2.4, +2.8] studs และเพดาน Y >= 6.0 studs

### A12 — Direct Shoot Wind-up / Hold

* **1) ID / ชื่อ / โหมด**: `A12` — **Direct Shoot Wind-up / Hold** | โหมด: **`Hold (Enter t=0.00..0.50 [0.18s] -> Freeze at t=0.50 -> Release to A13 or Cancel t=0.50..1.00 [0.16s])`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A12.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front-Right 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.34 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.06 s`, `blendOut = 0.08 s`
  * **Hold Range**: `t = 0.50 (Entered at 0.18 s; holds indefinitely until Release or Cancel signal)`
  * **Contact Phase**: `ไม่มีการปะทะลูกบอลโดยตรง (Locomotion / Utility)`
  * **การอิงสถานะจริง (State Binding)**: `Shoot Charge Active; Full-body joint override locks visual pose while HRP remains un-anchored`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A12 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Enter: Plant Foot Step & Shoulder Turn**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.67, +0.36, +1.23)`, ฝ่าเท้าซ้าย = `(-0.48, +0.03, -0.02)`) — Enter (t=0.00): วางเท้าซ้ายนำ (+10°) เริ่มดึงขาขวาไปด้านหลัง (-22°) กางแขนซ้ายนำสมดุล*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.081, +0.000)` | `(-8.0°, -8.0°, +2.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.08 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 8.0°, เอียงลำตัวทางซ้าย (+rz) 2.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +8.0°, -2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 6.0°, หันศีรษะมองทางซ้าย (+ry) 8.0°, เอียงศีรษะทางขวา (-rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-16.0°, +0.0°, +16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 16.0°, กางออกด้านขวา (+rz) 16.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+24.0°, +8.0°, -20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 24.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 20.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-22.0°, -4.0°, +5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 22.0°, เปิดออกด้านนอก (-ry) 4.0°, กางออกด้านขวา (+rz) 5.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +4.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 4.0° |

**Keyframe 2 — `t = 0.35` (`0.126 s`): Enter: Deep Backswing Loading**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.52, +1.21, +2.17)`, ฝ่าเท้าซ้าย = `(-0.32, +0.05, +0.08)`) — Loading (t=0.35): ง้างขาขวาขึ้นสูง (-48°) บิดลำตัวเปิดไหล่ขวา (-14°) สะสมพลังงานศักย์*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.040, +0.126, +0.040)` | `(-12.0°, -14.0°, +5.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.04 studs, ยกระดับลำตัว (ขึ้น +Y) 0.13 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.04 studs, โน้มหน้า (-rx) 12.0°, บิดลำตัวหันทางขวา (-ry) 14.0°, เอียงลำตัวทางซ้าย (+rz) 5.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +14.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 14.0°, เอียงศีรษะทางขวา (-rz) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-34.0°, -6.0°, +22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 34.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 22.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+42.0°, +12.0°, -28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 42.0°, เปิดออกด้านนอก (+ry) 12.0°, กางออกด้านซ้าย (-rz) 28.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-48.0°, -6.0°, +7.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 48.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 7.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +5.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 5.0° |

**Keyframe 3 — `t = 0.50` (`0.180 s`): HOLD LOCK: Coiled Power Stance (Frozen Pose)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.36, +1.67, +2.44)`, ฝ่าเท้าซ้าย = `(-0.26, +0.06, +0.12)`) — HOLD (t=0.50): ค้างท่าง้างยิงตรง ขาขวาง้าง -58° ขาซ้ายปักหลัก +16° ห้ามสับขาหรือปน loop เดินเด็ดขาด*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.060, +0.149, +0.060)` | `(-14.0°, -18.0°, +6.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.06 studs, ยกระดับลำตัว (ขึ้น +Y) 0.15 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.06 studs, โน้มหน้า (-rx) 14.0°, บิดลำตัวหันทางขวา (-ry) 18.0°, เอียงลำตัวทางซ้าย (+rz) 6.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +18.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0°, หันศีรษะมองทางซ้าย (+ry) 18.0°, เอียงศีรษะทางขวา (-rz) 5.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-42.0°, -8.0°, +24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 42.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 24.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+50.0°, +14.0°, -32.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 50.0°, เปิดออกด้านนอก (+ry) 14.0°, กางออกด้านซ้าย (-rz) 32.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-58.0°, -6.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 58.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+16.0°, +6.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 16.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 4 — `t = 1.00` (`0.340 s`): Cancel Branch: Smooth De-escalation to Ready**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.63, +0.18, +0.64)`, ฝ่าเท้าซ้าย = `(-0.62, +0.11, +0.13)`) — Cancel (t=0.50->1.00, 0.16s): หากยกเลิกการชาร์จ ลดขาขวาลงกลับสู่ท่า A01 Ready อย่างนุ่มนวล (ถ้าปล่อยยิงจะส่งจาก KF3 ไป A13 KF1 ทันที)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.140, +0.000)` | `(-8.0°, -4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A12

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Left Leg planted forward (+16° rx, -6° rz) bearing 100% visual weight; Right Leg locked at -58° rear chamber throughout Hold.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.216 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A12

* **เข้าจากท่า (Enter From)**: A01 Idle (0.06s), A02 Walk (0.06s), A03 Sprint (0.06s), A05 Strafe (0.06s)
* **ออกไปท่า (Exit To)**: A13 Direct Shoot Follow-Through (0.00s direct hand-off from KF3 on Release), A01 Idle / A02 Walk (0.16s via KF3->KF4 on Cancel)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: On Release: immediately starts A13 at t=0.00 (whose KF1 matches A12 KF3). On Cancel: advances t from 0.50 to 1.00 over 0.16s and blends out.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: ในระหว่าง Hold (t=0.50) PosePlayer จะเขียนทับ Motor6D ทั้ง 6 ข้อต่อด้วยน้ำหนัก 1.0 และปิดการ blend ของ Walk/Sprint ชั่วคราว จึงไม่มีอาการขาสับหรือสลับเท้ากลางอากาศ แต่ไม่แตะต้อง HRP.Anchored หรือความเร็วฟิสิกส์

### A13 — Direct Shoot Follow-Through

* **1) ID / ชื่อ / โหมด**: `A13` — **Direct Shoot Follow-Through** | โหมด: **`One-shot`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A13.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front-Left 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.42 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.00 s`, `blendOut = 0.10 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.28 (0.118 s) — Right Leg anterior surface (0.00, -0.55, -0.50) strikes grounded ball`
  * **การอิงสถานะจริง (State Binding)**: `Triggered upon Release of A12 Direct Shoot Hold`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A13 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Release Initiation (Exact Hand-off from A12 Hold)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.36, +1.67, +2.44)`, ฝ่าเท้าซ้าย = `(-0.26, +0.06, +0.12)`) — รับท่าต่อจาก A12 KF3 (Hold) ตรงกัน 100% เริ่มปลดล็อกสะโพกเหวี่ยงขาขวาลงหาบอล*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.060, +0.149, +0.060)` | `(-14.0°, -18.0°, +6.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.06 studs, ยกระดับลำตัว (ขึ้น +Y) 0.15 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.06 studs, โน้มหน้า (-rx) 14.0°, บิดลำตัวหันทางขวา (-ry) 18.0°, เอียงลำตัวทางซ้าย (+rz) 6.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +18.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 10.0°, หันศีรษะมองทางซ้าย (+ry) 18.0°, เอียงศีรษะทางขวา (-rz) 5.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-42.0°, -8.0°, +24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 42.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 24.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+50.0°, +14.0°, -32.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 50.0°, เปิดออกด้านนอก (+ry) 14.0°, กางออกด้านซ้าย (-rz) 32.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-58.0°, -6.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 58.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+16.0°, +6.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 16.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 2 — `t = 0.28` (`0.118 s`): Instep Power Strike [Ball Contact]**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.74, +0.33, -0.65)`, ฝ่าเท้าซ้าย = `(-0.43, +0.14, +0.61)`) — Contact (t=0.28): ขาขวาพุ่งผ่านแนวดิ่ง (+26°) หน้าแข้ง/หลังเท้าขวาอัดกลางลูกบอล (Y=1.25) เต็มข้อ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.040, +0.164, +0.000)` | `(-6.0°, +4.0°, +5.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.04 studs, ยกระดับลำตัว (ขึ้น +Y) 0.16 studs, โน้มหน้า (-rx) 6.0°, บิดลำตัวหันทางซ้าย (+ry) 4.0°, เอียงลำตัวทางซ้าย (+rz) 5.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-10.0°, -4.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 10.0°, หันศีรษะมองทางขวา (-ry) 4.0°, เอียงศีรษะทางขวา (-rz) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +0.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 8.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +8.0°, -28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 28.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+26.0°, +0.0°, +3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 26.0°, กางออกด้านขวา (+rz) 3.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +4.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 8.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 5.0° |

**Keyframe 3 — `t = 0.62` (`0.260 s`): High Power Follow-Through & Counter-Twist**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.15, +1.88, -2.20)`, ฝ่าเท้าซ้าย = `(-0.08, +0.14, +0.10)`) — Follow-through: ขาขวาเหวี่ยงส่งสูง (+68°) ลำตัวเอนหลังเล็กน้อย (+10°) และบิดซ้าย (+22°) แขนซ้ายกวาดไปด้านหลัง (-44°)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.040, +0.229, -0.040)` | `(+10.0°, +22.0°, +8.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.04 studs, ยกระดับลำตัว (ขึ้น +Y) 0.23 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.04 studs, เอนหลัง (+rx) 10.0°, บิดลำตัวหันทางซ้าย (+ry) 22.0°, เอียงลำตัวทางซ้าย (+rz) 8.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -20.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 6.0°, หันศีรษะมองทางขวา (-ry) 20.0°, เอียงศีรษะทางขวา (-rz) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+38.0°, +10.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 38.0°, บิดเข้าด้านใน (+ry) 10.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-44.0°, -8.0°, -24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 44.0°, บิดเข้าด้านใน (-ry) 8.0°, กางออกด้านซ้าย (-rz) 24.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+68.0°, +4.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 68.0°, บิดเข้าด้านใน (+ry) 4.0°, หุบเข้าหาลำตัว (-rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-18.0°, +4.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 18.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 6.0° |

**Keyframe 4 — `t = 1.00` (`0.420 s`): Step-Down Recovery to Ready**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.61, +0.11, -0.00)`, ฝ่าเท้าซ้าย = `(-0.62, +0.19, +0.72)`) — วางเท้าขวาลงพื้นด้านหน้า คืนสมดุลพร้อมวิ่งต่อทันที*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.137, +0.000)` | `(-8.0°, +4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางซ้าย (+ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, -4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางขวา (-ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, -4.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (-ry) 4.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 8.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -4.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 4.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +4.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 8.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 4.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A13

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Left Leg anchors stance throughout strike (rx shifts from +16° to -18° as pelvis drives over plant foot); Right Leg steps down at t=1.00.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.313 studs`
* **เรขาคณิตการปะทะลูกบอล (Ball Contact Geometry ที่ `t = 0.28`, `time = 0.118 s`)**:
  * **ชิ้นส่วนที่สัมผัสลูกบอล**: `Right Leg`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน Part Local Space**: `(+0.116, -0.664, -0.500) studs`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน World / Character Space**: `(+0.776, +0.824, -1.007) studs`
  * **ตำแหน่งจุดศูนย์กลางลูกบอล (`R = 1.25 studs`)**: `(+0.650, +1.250, -2.176) studs`
  * **ระยะห่างจากผิวกล่อง OBB ถึงจุดศูนย์กลางบอล**: **`1.250 studs`** (เท่ากับรัศมีลูกบอล `1.250 studs` พอดี ไม่มีการย่อขนาดบอลและไม่มีขาเอื้อมไม่ถึง)

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A13

* **เข้าจากท่า (Enter From)**: A12 Direct Shoot Wind-up / Hold (0.00s seamless hand-off from A12 KF3)
* **ออกไปท่า (Exit To)**: A01 Idle (0.10s), A02 Walk (0.10s), A03 Sprint (0.10s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Crossfades out over 0.10s after t=1.00 into active locomotion or A01 Idle.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: จุดปะทะบอลที่ t=0.28 ใช้ด้านหน้าของแท่งขาขวา (rx=+26°, ry=0°) ปะทะลูกบอลที่วางพื้น (Ball.Center.Y = 1.25 studs) โดยตรง ไม่บิดขาออกข้างเพื่อให้ต่างจากท่ายิงปั่นโค้ง (A15)

### A14 — Curve Shoot Wind-up / Hold

* **1) ID / ชื่อ / โหมด**: `A14` — **Curve Shoot Wind-up / Hold** | โหมด: **`Hold (Enter t=0.00..0.50 [0.20s] -> Freeze at t=0.50 -> Release to A15 [Finesse/Trivela] or Cancel t=0.50..1.00 [0.16s])`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A14.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front (-Z View)`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.36 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.06 s`, `blendOut = 0.08 s`
  * **Hold Range**: `t = 0.50 (Entered at 0.20 s; holds indefinitely without foot shuffling)`
  * **Contact Phase**: `ไม่มีการปะทะลูกบอลโดยตรง (Locomotion / Utility)`
  * **การอิงสถานะจริง (State Binding)**: `Curve Shoot Charge Active; Full-body override with zero walk-cycle bleed`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A14 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Enter: Wide Oblique Plant & Hip Open**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.32, +0.39, +1.36)`, ฝ่าเท้าซ้าย = `(-1.05, +0.28, -0.44)`) — Enter: ก้าวเท้าซ้ายเฉียงออกด้านซ้าย (tx=-0.08) เปิดสะโพกและลำตัวเฉียง (-18°) กางขาขวาออกด้านข้าง (+14°)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.080, +0.245, +0.040)` | `(-6.0°, -18.0°, -6.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.08 studs, ยกระดับลำตัว (ขึ้น +Y) 0.24 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.04 studs, โน้มหน้า (-rx) 6.0°, บิดลำตัวหันทางขวา (-ry) 18.0°, เอียงลำตัวทางขวา (-rz) 6.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +16.0°, +5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 6.0°, หันศีรษะมองทางซ้าย (+ry) 16.0°, เอียงศีรษะทางซ้าย (+rz) 5.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-18.0°, -10.0°, +24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 18.0°, เปิดออกด้านนอก (-ry) 10.0°, กางออกด้านขวา (+rz) 24.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+28.0°, +12.0°, -28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 28.0°, เปิดออกด้านนอก (+ry) 12.0°, กางออกด้านซ้าย (-rz) 28.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-24.0°, -16.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 24.0°, เปิดออกด้านนอก (-ry) 16.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+12.0°, +10.0°, -10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 12.0°, เปิดออกด้านนอก (+ry) 10.0°, กางออกด้านซ้าย (-rz) 10.0° |

**Keyframe 2 — `t = 0.35` (`0.140 s`): Enter: Angled Sweeping Chamber**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.01, +0.85, +2.11)`, ฝ่าเท้าซ้าย = `(-1.06, +0.21, -0.59)`) — Chamber: บิดลำตัวเปิดกว้าง (-26°) ง้างขาขวาเฉียงออกด้านข้าง (rx=-42°, ry=-24°, rz=+20°)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.120, +0.163, +0.060)` | `(-9.0°, -26.0°, -8.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.12 studs, ยกระดับลำตัว (ขึ้น +Y) 0.16 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.06 studs, โน้มหน้า (-rx) 9.0°, บิดลำตัวหันทางขวา (-ry) 26.0°, เอียงลำตัวทางขวา (-rz) 8.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +24.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 24.0°, เอียงศีรษะทางซ้าย (+rz) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-32.0°, -14.0°, +32.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 32.0°, เปิดออกด้านนอก (-ry) 14.0°, กางออกด้านขวา (+rz) 32.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+46.0°, +18.0°, -38.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 46.0°, เปิดออกด้านนอก (+ry) 18.0°, กางออกด้านซ้าย (-rz) 38.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-42.0°, -24.0°, +20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 42.0°, เปิดออกด้านนอก (-ry) 24.0°, กางออกด้านขวา (+rz) 20.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+16.0°, +12.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 16.0°, เปิดออกด้านนอก (+ry) 12.0°, กางออกด้านซ้าย (-rz) 12.0° |

**Keyframe 3 — `t = 0.50` (`0.200 s`): HOLD LOCK: Open-Hip Curve Chamber (Frozen Pose)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.26, +1.23, +2.39)`, ฝ่าเท้าซ้าย = `(-1.07, +0.24, -0.76)`) — HOLD (t=0.50): ค้างท่าง้างยิงโค้ง เปิดสะโพกขวา (-28°) และกางขา (+24°) พร้อมเข้าได้ทั้ง Finesse และ Trivela ด้วยเท้าขวาข้างเดิม*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.140, +0.169, +0.080)` | `(-10.0°, -32.0°, -10.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.14 studs, ยกระดับลำตัว (ขึ้น +Y) 0.17 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.08 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางขวา (-ry) 32.0°, เอียงลำตัวทางขวา (-rz) 10.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +30.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 30.0°, เอียงศีรษะทางซ้าย (+rz) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-38.0°, -16.0°, +36.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 38.0°, เปิดออกด้านนอก (-ry) 16.0°, กางออกด้านขวา (+rz) 36.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+54.0°, +20.0°, -44.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 54.0°, เปิดออกด้านนอก (+ry) 20.0°, กางออกด้านซ้าย (-rz) 44.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-52.0°, -28.0°, +24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 52.0°, เปิดออกด้านนอก (-ry) 28.0°, กางออกด้านขวา (+rz) 24.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +14.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (+ry) 14.0°, กางออกด้านซ้าย (-rz) 14.0° |

**Keyframe 4 — `t = 1.00` (`0.360 s`): Cancel Branch: Smooth Return to Ready**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.63, +0.18, +0.64)`, ฝ่าเท้าซ้าย = `(-0.62, +0.11, +0.13)`) — Cancel (t=0.50->1.00): คืนตัวจากท่าง้างปั่นโค้งกลับสู่ A01 Ready อย่างราบรื่น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.140, +0.000)` | `(-8.0°, -4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A14

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Left Leg planted wide laterally (tx=-0.14, rx=+18°, rz=-14°); Right Leg held in wide oblique chamber (rx=-52°, ry=-28°, rz=+24°).
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.269 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A14

* **เข้าจากท่า (Enter From)**: A01 Idle (0.06s), A02 Walk (0.06s), A03 Sprint (0.06s), A05 Strafe (0.06s)
* **ออกไปท่า (Exit To)**: A15-finesse Follow-Through (0.00s direct from KF3), A15-trivela Follow-Through (0.00s direct from KF3), A01 Idle (0.16s via KF3->KF4 Cancel)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Direct 0.00s hand-off from KF3 into either A15-finesse or A15-trivela (both start from A14 KF3 so the kicking foot never teleports or swaps).
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: ต่างจาก A12 อย่างชัดเจนด้วยการบิดลำตัว ry=-32°, เอียงตัว rz=-10°, และกางขาขวาออกข้าง rz=+24° พร้อมหมุนเปิดสะโพก ry=-28° ทำให้ผู้เล่นอ่านออกทันทีว่ากำลังชาร์จยิงปั่นโค้ง

### A15 — Curve Shoot Follow-Through (Finesse & Trivela Variants)

* **1) ID / ชื่อ / โหมด**: `A15` — **Curve Shoot Follow-Through (Finesse & Trivela Variants)** | โหมด: **`One-shot (2 Visual Variants: 'finesse' and 'trivela')`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A15.png` และแผ่นภาพแยก Variant: `A15-finesse.png`, `A15-trivela.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Front (-Z View)` และมุมเสริม `Top-Front 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.44 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.00 s`, `blendOut = 0.10 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.30 (0.132 s) — Finesse hits Medial (-X) face; Trivela hits Lateral (+X) face`
  * **การอิงสถานะจริง (State Binding)**: `Triggered upon Release of A14 Curve Shoot Hold (selected by curve sign / variant parameter)`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A15 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

##### Variant `finesse` — A15-finesse (Inside-Foot Curl)

**[FINESSE] Keyframe 1 — `t = 0.00` (`0.000 s`): Release from A14 Hold (External Hip Rotation Lock)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.26, +1.23, +2.39)`, ฝ่าเท้าซ้าย = `(-1.07, +0.24, -0.76)`) — เริ่มเหวี่ยงจาก A14 KF3 โดยหมุนเปิดสะโพกขวาออกด้านนอก (ry=-28° -> -48°) เพื่อหันข้างเท้าด้านในเข้าหาบอล*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.140, +0.169, +0.080)` | `(-10.0°, -32.0°, -10.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.14 studs, ยกระดับลำตัว (ขึ้น +Y) 0.17 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.08 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางขวา (-ry) 32.0°, เอียงลำตัวทางขวา (-rz) 10.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +30.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 30.0°, เอียงศีรษะทางซ้าย (+rz) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-38.0°, -16.0°, +36.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 38.0°, เปิดออกด้านนอก (-ry) 16.0°, กางออกด้านขวา (+rz) 36.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+54.0°, +20.0°, -44.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 54.0°, เปิดออกด้านนอก (+ry) 20.0°, กางออกด้านซ้าย (-rz) 44.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-52.0°, -28.0°, +24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 52.0°, เปิดออกด้านนอก (-ry) 28.0°, กางออกด้านขวา (+rz) 24.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +14.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (+ry) 14.0°, กางออกด้านซ้าย (-rz) 14.0° |

**[FINESSE] Keyframe 2 — `t = 0.30` (`0.132 s`): Finesse Inside-Surface Whip Contact [Ball Contact]**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+1.46, +0.70, -0.97)`, ฝ่าเท้าซ้าย = `(-0.23, +0.12, +0.44)`) — Contact (t=0.30): หมุนขาขวาทั้งแท่งเปิดออก (ry=-48°) ใช้พื้นผิวด้านใน (Medial face X=-0.50) ปั่นเฉือนผิวบอลด้านขวา-หลัง*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.100, +0.277, +0.000)` | `(-4.0°, +8.0°, +14.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.10 studs, ยกระดับลำตัว (ขึ้น +Y) 0.28 studs, โน้มหน้า (-rx) 4.0°, บิดลำตัวหันทางซ้าย (+ry) 8.0°, เอียงลำตัวทางซ้าย (+rz) 14.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-8.0°, -8.0°, -10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 8.0°, หันศีรษะมองทางขวา (-ry) 8.0°, เอียงศีรษะทางขวา (-rz) 10.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +0.0°, +28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 14.0°, กางออกด้านขวา (+rz) 28.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +12.0°, -36.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 8.0°, เปิดออกด้านนอก (+ry) 12.0°, กางออกด้านซ้าย (-rz) 36.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+28.0°, -48.0°, +16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 28.0°, เปิดออกด้านนอก (-ry) 48.0°, กางออกด้านขวา (+rz) 16.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, +10.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (+ry) 10.0°, กางออกด้านซ้าย (-rz) 12.0° |

**[FINESSE] Keyframe 3 — `t = 0.65` (`0.286 s`): Crescent Wrap Follow-Through Across Body**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.44, +2.68, -2.15)`, ฝ่าเท้าซ้าย = `(+0.20, +0.18, +0.01)`) — Follow-through: ขาขวากวาดโค้งตัดหน้าลำตัวไปทางซ้าย (rx=+62°, rz=-18°, ry=-52°) ลำตัวเอียงซ้าย (+16°) สื่อแรงปั่นโค้งเข้าในชัดเจน*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.060, +0.321, -0.040)` | `(+8.0°, +28.0°, +16.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.06 studs, ยกระดับลำตัว (ขึ้น +Y) 0.32 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.04 studs, เอนหลัง (+rx) 8.0°, บิดลำตัวหันทางซ้าย (+ry) 28.0°, เอียงลำตัวทางซ้าย (+rz) 16.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -24.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 6.0°, หันศีรษะมองทางขวา (-ry) 24.0°, เอียงศีรษะทางขวา (-rz) 12.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+46.0°, +16.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 46.0°, บิดเข้าด้านใน (+ry) 16.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-48.0°, -14.0°, -28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 48.0°, บิดเข้าด้านใน (-ry) 14.0°, กางออกด้านซ้าย (-rz) 28.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+62.0°, -52.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 62.0°, เปิดออกด้านนอก (-ry) 52.0°, หุบเข้าหาลำตัว (-rz) 18.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-16.0°, +8.0°, -10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 16.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 10.0° |

**[FINESSE] Keyframe 4 — `t = 1.00` (`0.440 s`): Balanced Recovery to Ready**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.72, +0.15, +0.03)`, ฝ่าเท้าซ้าย = `(-0.52, +0.18, +0.70)`) — คลายมุมหมุนสะโพกขวาและวางเท้าลงสู่ท่าพร้อมเล่น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.151, +0.000)` | `(-8.0°, +4.0°, +2.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.15 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางซ้าย (+ry) 4.0°, เอียงลำตัวทางซ้าย (+rz) 2.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, -4.0°, -2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางขวา (-ry) 4.0°, เอียงศีรษะทางขวา (-rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+12.0°, -4.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 12.0°, เปิดออกด้านนอก (-ry) 4.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, +4.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+8.0°, -8.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 8.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +6.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 8.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 4.0° |

##### Variant `trivela` — A15-trivela (Outside-Foot Reverse Curl)

**[TRIVELA] Keyframe 1 — `t = 0.00` (`0.000 s`): Release from A14 Hold (Internal Hip Twist Prep)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.26, +1.23, +2.39)`, ฝ่าเท้าซ้าย = `(-1.07, +0.24, -0.76)`) — เริ่มจาก A14 KF3 เดียวกัน แต่บิดสะโพกขวาเข้าด้านในอย่างรวดเร็วเพื่อหันข้างเท้าด้านนอก (Lateral face) เข้าหาบอล*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.140, +0.169, +0.080)` | `(-10.0°, -32.0°, -10.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.14 studs, ยกระดับลำตัว (ขึ้น +Y) 0.17 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.08 studs, โน้มหน้า (-rx) 10.0°, บิดลำตัวหันทางขวา (-ry) 32.0°, เอียงลำตัวทางขวา (-rz) 10.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +30.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 30.0°, เอียงศีรษะทางซ้าย (+rz) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-38.0°, -16.0°, +36.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 38.0°, เปิดออกด้านนอก (-ry) 16.0°, กางออกด้านขวา (+rz) 36.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+54.0°, +20.0°, -44.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 54.0°, เปิดออกด้านนอก (+ry) 20.0°, กางออกด้านซ้าย (-rz) 44.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-52.0°, -28.0°, +24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 52.0°, เปิดออกด้านนอก (-ry) 28.0°, กางออกด้านขวา (+rz) 24.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +14.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (+ry) 14.0°, กางออกด้านซ้าย (-rz) 14.0° |

**[TRIVELA] Keyframe 2 — `t = 0.30` (`0.132 s`): Trivela Outside-Surface Slice Contact [Ball Contact]**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(-0.47, +0.28, +0.01)`, ฝ่าเท้าซ้าย = `(-1.83, +0.49, +0.24)`) — Contact (t=0.30): บิดขาขวาเข้าด้านใน (ry=+38°) และหุบข้ามแกนกลาง (rz=-12°) ใช้ผิวด้านนอก (Lateral face X=+0.50) เฉือนซ้าย-หลังของลูกบอล*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.120, +0.200, +0.000)` | `(-8.0°, -12.0°, -14.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.12 studs, ยกระดับลำตัว (ขึ้น +Y) 0.20 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 12.0°, เอียงลำตัวทางขวา (-rz) 14.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-6.0°, +12.0°, +10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 6.0°, หันศีรษะมองทางซ้าย (+ry) 12.0°, เอียงศีรษะทางซ้าย (+rz) 10.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-22.0°, -8.0°, +32.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 22.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 32.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+34.0°, +14.0°, -34.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 34.0°, เปิดออกด้านนอก (+ry) 14.0°, กางออกด้านซ้าย (-rz) 34.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+26.0°, +38.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 26.0°, บิดเข้าด้านใน (+ry) 38.0°, หุบเข้าหาลำตัว (-rz) 12.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, +12.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (+ry) 12.0°, กางออกด้านซ้าย (-rz) 14.0° |

**[TRIVELA] Keyframe 3 — `t = 0.65` (`0.286 s`): OutwardWhip Slice Follow-Through**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.32, +1.01, -2.17)`, ฝ่าเท้าซ้าย = `(-1.82, +0.30, +0.44)`) — Follow-through: ขาขวาสะบัดกวาดออกทางขวา (rx=+58°, ry=+42°, rz=+26°) ลำตัวเอียงขวา (rz=-18°) สื่อวิถีไซด์ก้อย (Trivela) ชัดเจน*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.100, -0.065, -0.020)` | `(+6.0°, +8.0°, -18.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.10 studs, ลดระดับลำตัว (ลง -Y) 0.07 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.02 studs, เอนหลัง (+rx) 6.0°, บิดลำตัวหันทางซ้าย (+ry) 8.0°, เอียงลำตัวทางขวา (-rz) 18.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-4.0°, -8.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 4.0°, หันศีรษะมองทางขวา (-ry) 8.0°, เอียงศีรษะทางซ้าย (+rz) 14.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-36.0°, -12.0°, +42.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 36.0°, เปิดออกด้านนอก (-ry) 12.0°, กางออกด้านขวา (+rz) 42.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+22.0°, +10.0°, -24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 22.0°, เปิดออกด้านนอก (+ry) 10.0°, กางออกด้านซ้าย (-rz) 24.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+58.0°, +42.0°, +26.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 58.0°, บิดเข้าด้านใน (+ry) 42.0°, กางออกด้านขวา (+rz) 26.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-14.0°, +10.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 14.0°, เปิดออกด้านนอก (+ry) 10.0°, กางออกด้านซ้าย (-rz) 12.0° |

**[TRIVELA] Keyframe 4 — `t = 1.00` (`0.440 s`): Balanced Recovery to Ready**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.62, +0.09, +0.22)`, ฝ่าเท้าซ้าย = `(-0.76, +0.20, +0.62)`) — คลายมุมบิดสะโพกและวางเท้าขวาลงพื้นพร้อมเคลื่อนที่ต่อ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.134, +0.000)` | `(-8.0°, -4.0°, -2.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.13 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 4.0°, เอียงลำตัวทางขวา (-rz) 2.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, +2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 4.0°, เอียงศีรษะทางซ้าย (+rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 14.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +6.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 8.0°, บิดเข้าด้านใน (+ry) 6.0°, กางออกด้านขวา (+rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-8.0°, +4.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 8.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 4.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A15

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Left Leg stays planted laterally (tx=-0.10 to -0.12); Torso banks Left (+14°/+16° rz) for Finesse vs Right (-14°/-18° rz) for Trivela.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.412 studs`
* **เรขาคณิตการปะทะลูกบอล (Ball Contact Geometry ที่ `t = 0.30`, `time = 0.132 s`)**:
  * **ชิ้นส่วนที่สัมผัสลูกบอล**: `Right Leg`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน Part Local Space**: `(-0.500, -0.202, -0.085) studs`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน World / Character Space**: `(+0.842, +1.391, -1.150) studs`
  * **ตำแหน่งจุดศูนย์กลางลูกบอล (`R = 1.25 studs`)**: `(-0.091, +1.250, -1.971) studs`
  * **ระยะห่างจากผิวกล่อง OBB ถึงจุดศูนย์กลางบอล**: **`1.250 studs`** (เท่ากับรัศมีลูกบอล `1.250 studs` พอดี ไม่มีการย่อขนาดบอลและไม่มีขาเอื้อมไม่ถึง)
  * **Variant `finesse` (`A15-finesse (Inside-Foot Curl)`)**: จุดปะทะบน `Right Leg` Local = `(-0.500, -0.202, -0.085)`, World Contact = `(+0.842, +1.391, -1.150)`, Ball Center = `(-0.091, +1.250, -1.971)`, ระยะห่างผิว = `1.250 studs`
  * **Variant `trivela` (`A15-trivela (Outside-Foot Reverse Curl)`)**: จุดปะทะบน `Right Leg` Local = `(+0.500, +0.161, -0.500)`, World Contact = `(+0.154, +1.439, -0.331)`, Ball Center = `(+1.225, +1.250, -0.946)`, ระยะห่างผิว = `1.250 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A15

* **เข้าจากท่า (Enter From)**: A14 Curve Shoot Wind-up / Hold (0.00s direct hand-off from A14 KF3)
* **ออกไปท่า (Exit To)**: A01 Idle (0.10s), A02 Walk (0.10s), A03 Sprint (0.10s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: 0.10s crossfade after t=1.00 into locomotion or A01.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: เนื่องจาก R6 ไม่มีข้อเท้าให้กระดกบิดปลายเท้า การสื่อท่า Finesse และ Trivela จึงทำโดยหมุนแกน Y ของสะโพกขวาทั้งแท่ง (ry=-48° เพื่อหันหน้าตัดด้านใน -X ของขาเข้าปะทะบอลใน Finesse และ ry=+38° เพื่อหันหน้าตัดด้านนอก +X เข้าเฉือนบอลใน Trivela) ร่วมกับทิศทางการกวาดขา (rz=-18° ข้ามลำตัว vs rz=+26° กวาดออกนอก) และการเอียง Torso สวนทางกันอย่างชัดเจน

### A16 — Single 3D Pass (Parametric Ground & Lob Pass)

* **1) ID / ชื่อ / โหมด**: `A16` — **Single 3D Pass (Parametric Ground & Lob Pass)** | โหมด: **`One-shot (Parametric over passPower ∈ [0,1] and passElevation ∈ [0°, 45°])`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A16.png` และแผ่นภาพแยก Variant: `A16-ground.png`, `A16-lob.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front-Right 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.36 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.05 s`, `blendOut = 0.08 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.32 (0.115 s) — Inside-foot push (Ground) or low-edge wedge scoop (Lob)`
  * **การอิงสถานะจริง (State Binding)**: `Single 3D Pass action; Pose = Lerp(GroundPose, LobPose, clamp(elevationDeg/35, 0, 1)) scaled by (0.65 + 0.35*power)`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A16 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

##### Variant `ground` — A16-ground (Driven Ground Pass: elevation=0°, power=0.6)

**[GROUND] Keyframe 1 — `t = 0.00` (`0.000 s`): Compact Pass Chamber (Open Hip Push Prep)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.73, +0.51, +1.55)`, ฝ่าเท้าซ้าย = `(-0.53, +0.06, -0.14)`) — Ground Pass Prep: ง้างสั้นกระชับ (rx=-28°) แต่หมุนเปิดสะโพกขวา (ry=-36°) เพื่อใช้แปข้างเท้าด้านในส่งบอลแม่นยำ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.050, +0.123, +0.020)` | `(-8.0°, -14.0°, +2.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.05 studs, ยกระดับลำตัว (ขึ้น +Y) 0.12 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.02 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 14.0°, เอียงลำตัวทางซ้าย (+rz) 2.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +14.0°, -2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 6.0°, หันศีรษะมองทางซ้าย (+ry) 14.0°, เอียงศีรษะทางขวา (-rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-18.0°, -6.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 18.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+26.0°, +8.0°, -22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 26.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 22.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-28.0°, -36.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 28.0°, เปิดออกด้านนอก (-ry) 36.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+12.0°, +6.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 12.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 6.0° |

**[GROUND] Keyframe 2 — `t = 0.32` (`0.115 s`): Flat Inside-Foot Push Contact [Ground Pass]**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.93, +0.27, -0.58)`, ฝ่าเท้าซ้าย = `(-0.49, +0.15, +0.65)`) — Contact (t=0.32): แปบอลเรียดพื้นด้วยผิวด้านในของขาขวา (ry=-42°, rx=+22°) ลำตัวก้มคุมบอล (-8°) ไม่ให้บอลเหิน*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.040, +0.160, +0.000)` | `(-8.0°, +4.0°, +4.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.04 studs, ยกระดับลำตัว (ขึ้น +Y) 0.16 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางซ้าย (+ry) 4.0°, เอียงลำตัวทางซ้าย (+rz) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -4.0°, -3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 6.0°, หันศีรษะมองทางขวา (-ry) 4.0°, เอียงศีรษะทางขวา (-rz) 3.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +0.0°, +16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 8.0°, กางออกด้านขวา (+rz) 16.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +6.0°, -20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 20.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+22.0°, -42.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 22.0°, เปิดออกด้านนอก (-ry) 42.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, +4.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 5.0° |

**[GROUND] Keyframe 3 — `t = 0.65` (`0.234 s`): Controlled Short Follow-Through (Abrupt Stop)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.55, +0.61, -1.35)`, ฝ่าเท้าซ้าย = `(-0.36, +0.15, +0.60)`) — Short Follow-through: หยุดขาขวาที่ +34° (ต่ำกว่าท่ายิงเต็มข้อ A13 ที่ +68° ครึ่งหนึ่ง) เพื่อดึงขากลับไปเล่นต่อได้เร็ว*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.030, +0.167, -0.020)` | `(-4.0°, +12.0°, +5.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.03 studs, ยกระดับลำตัว (ขึ้น +Y) 0.17 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.02 studs, โน้มหน้า (-rx) 4.0°, บิดลำตัวหันทางซ้าย (+ry) 12.0°, เอียงลำตัวทางซ้าย (+rz) 5.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-4.0°, -12.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 4.0°, หันศีรษะมองทางขวา (-ry) 12.0°, เอียงศีรษะทางขวา (-rz) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+20.0°, +6.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 20.0°, บิดเข้าด้านใน (+ry) 6.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-16.0°, -4.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 16.0°, บิดเข้าด้านใน (-ry) 4.0°, กางออกด้านซ้าย (-rz) 18.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+34.0°, -38.0°, +2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 34.0°, เปิดออกด้านนอก (-ry) 38.0°, กางออกด้านขวา (+rz) 2.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-10.0°, +4.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 10.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 5.0° |

**[GROUND] Keyframe 4 — `t = 1.00` (`0.360 s`): Instant Play Continuation Ready**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.63, +0.18, +0.64)`, ฝ่าเท้าซ้าย = `(-0.62, +0.11, +0.13)`) — คืนสู่ท่าพร้อมเล่นภายใน 0.36 วินาที*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.140, +0.000)` | `(-8.0°, -4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

##### Variant `lob` — A16-lob (Lofted / Chipped Pass: elevation=35°, power=0.85)

**[LOB] Keyframe 1 — `t = 0.00` (`0.000 s`): Lob Pass Chamber (Deeper Dip & Backswing)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.57, +0.83, +1.90)`, ฝ่าเท้าซ้าย = `(-0.38, +0.13, -0.57)`) — Lob Pass Prep: ง้างขาขวาลึกขึ้น (-42°) และก้าวเท้าซ้ายย่อรับน้ำหนัก (+18°) เพื่อสอดเท้าเข้าใต้ลูกบอล*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.060, +0.167, +0.040)` | `(-4.0°, -20.0°, +4.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.06 studs, ยกระดับลำตัว (ขึ้น +Y) 0.17 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.04 studs, โน้มหน้า (-rx) 4.0°, บิดลำตัวหันทางขวา (-ry) 20.0°, เอียงลำตัวทางซ้าย (+rz) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+4.0°, +18.0°, -3.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 4.0°, หันศีรษะมองทางซ้าย (+ry) 18.0°, เอียงศีรษะทางขวา (-rz) 3.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-28.0°, -8.0°, +22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 28.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 22.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+38.0°, +12.0°, -28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 38.0°, เปิดออกด้านนอก (+ry) 12.0°, กางออกด้านซ้าย (-rz) 28.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-42.0°, -28.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 42.0°, เปิดออกด้านนอก (-ry) 28.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +8.0°, -8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 18.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 8.0° |

**[LOB] Keyframe 2 — `t = 0.32` (`0.115 s`): Under-Ball Wedge Scoop Contact [Lob Pass]**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.92, +0.62, -1.41)`, ฝ่าเท้าซ้าย = `(-0.41, +0.05, +0.06)`) — Contact (t=0.32): เอนลำตัวไปด้านหลัง (+6°) สอดขอบล่างของเท้าขวา (y=-0.85 ใน Leg space) ช้อนเข้าใต้ศูนย์กลางบอล (Y=0.68 vs Ball Y=1.25)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.050, +0.147, +0.020)` | `(+6.0°, +6.0°, +6.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.05 studs, ยกระดับลำตัว (ขึ้น +Y) 0.15 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.02 studs, เอนหลัง (+rx) 6.0°, บิดลำตัวหันทางซ้าย (+ry) 6.0°, เอียงลำตัวทางซ้าย (+rz) 6.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-8.0°, -6.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 8.0°, หันศีรษะมองทางขวา (-ry) 6.0°, เอียงศีรษะทางขวา (-rz) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+4.0°, +0.0°, +20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 4.0°, กางออกด้านขวา (+rz) 20.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +8.0°, -26.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 26.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+28.0°, -26.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 28.0°, เปิดออกด้านนอก (-ry) 26.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-10.0°, +6.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 10.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 6.0° |

**[LOB] Keyframe 3 — `t = 0.65` (`0.234 s`): Upward Chip Lift Follow-Through**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.03, +1.65, -2.13)`, ฝ่าเท้าซ้าย = `(-0.17, +0.10, -0.03)`) — Lob Follow-through: ยกขาขวาช้อนขึ้น (+52°) พร้อมเอนหลัง (+10°) ส่งวิถีบอลลอยโด่งข้ามแนวรับ*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(-0.040, +0.200, -0.020)` | `(+10.0°, +18.0°, +8.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางซ้าย (-X) 0.04 studs, ยกระดับลำตัว (ขึ้น +Y) 0.20 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.02 studs, เอนหลัง (+rx) 10.0°, บิดลำตัวหันทางซ้าย (+ry) 18.0°, เอียงลำตัวทางซ้าย (+rz) 8.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-4.0°, -16.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 4.0°, หันศีรษะมองทางขวา (-ry) 16.0°, เอียงศีรษะทางขวา (-rz) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+28.0°, +8.0°, +16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 28.0°, บิดเข้าด้านใน (+ry) 8.0°, กางออกด้านขวา (+rz) 16.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-28.0°, -6.0°, -22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 28.0°, บิดเข้าด้านใน (-ry) 6.0°, กางออกด้านซ้าย (-rz) 22.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+52.0°, -24.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 52.0°, เปิดออกด้านนอก (-ry) 24.0°, หุบเข้าหาลำตัว (-rz) 6.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-14.0°, +6.0°, -6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 6.0° |

**[LOB] Keyframe 4 — `t = 1.00` (`0.360 s`): Instant Play Continuation Ready**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.63, +0.18, +0.64)`, ฝ่าเท้าซ้าย = `(-0.62, +0.11, +0.13)`) — คืนสู่ท่าพร้อมเล่นภายใน 0.36 วินาที*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.140, +0.000)` | `(-8.0°, -4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A16

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Left Leg planted beside ball; compact swing amplitude allows immediate return to sprint/walk within 0.36s.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.263 studs`
* **เรขาคณิตการปะทะลูกบอล (Ball Contact Geometry ที่ `t = 0.32`, `time = 0.115 s`)**:
  * **ชิ้นส่วนที่สัมผัสลูกบอล**: `Right Leg`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน Part Local Space**: `(-0.500, -0.012, -0.219) studs`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน World / Character Space**: `(+0.520, +1.273, -0.893) studs`
  * **ตำแหน่งจุดศูนย์กลางลูกบอล (`R = 1.25 studs`)**: `(-0.464, +1.250, -1.664) studs`
  * **ระยะห่างจากผิวกล่อง OBB ถึงจุดศูนย์กลางบอล**: **`1.250 studs`** (เท่ากับรัศมีลูกบอล `1.250 studs` พอดี ไม่มีการย่อขนาดบอลและไม่มีขาเอื้อมไม่ถึง)
  * **Variant `ground` (`A16-ground (Driven Ground Pass: elevation=0°, power=0.6)`)**: จุดปะทะบน `Right Leg` Local = `(-0.500, -0.012, -0.219)`, World Contact = `(+0.520, +1.273, -0.893)`, Ball Center = `(-0.464, +1.250, -1.664)`, ระยะห่างผิว = `1.250 studs`
  * **Variant `lob` (`A16-lob (Lofted / Chipped Pass: elevation=35°, power=0.85)`)**: จุดปะทะบน `Right Leg` Local = `(-0.500, -1.000, -0.500)`, World Contact = `(+0.610, +0.903, -1.972)`, Ball Center = `(+0.724, +1.250, -3.167)`, ระยะห่างผิว = `1.250 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A16

* **เข้าจากท่า (Enter From)**: A01 Idle (0.05s), A02 Walk (0.05s), A03 Sprint (0.05s), A05 Strafe (0.05s)
* **ออกไปท่า (Exit To)**: A01 Idle (0.08s), A02 Walk (0.08s), A03 Sprint (0.08s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Fast 0.08s blendOut after t=1.00.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: การแปรรูปท่าตามแรงและมุมเล็ง (Parametric Law): 1) ตามมุมเงย alpha = clamp(elevationDeg/35°, 0, 1): Torso rx ที่จุดปะทะเปลี่ยนจาก -8° (กดบอลเรียด) เป็น +6° (เอนหลังช้อนใต้บอล) และ Right Hip ry เปลี่ยนจาก -42° (แปเต็มใบ) เป็น -26° (ตักด้วยสันเท้าด้านในส่วนล่าง) 2) ตามแรงส่ง p ∈ [0,1]: แอมพลิจูดการง้างและ follow-through คูณด้วยตัวคูณ s_p = 0.65 + 0.35*p โดยยังจำกัดเพดาน follow-through สูงสุดที่ +52° เพื่อไม่ให้กลายเป็นท่ายิงเต็มข้อ (A13 +68°)

### A17 — Slide Tackle

* **1) ID / ชื่อ / โหมด**: `A17` — **Slide Tackle** | โหมด: **`One-shot`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A17.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Top-Front 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.55 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.05 s`, `blendOut = 0.00 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `t = 0.38 (0.209 s) — Extended Right Leg front-boot contact on grounded ball`
  * **การอิงสถานะจริง (State Binding)**: `Slide Tackle active window; chains directly into A18 Slide Recovery at t = 1.00`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A17 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

**Keyframe 1 — `t = 0.00` (`0.000 s`): Drop Entry & Hip Side-Collapse**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.02, +1.45, -2.37)`, ฝ่าเท้าซ้าย = `(-1.54, +0.23, -0.03)`) — Entry (t=0.00): ทิ้งสะโพกลงต่ำ (ty=-0.58) เอนหลัง (+24°) เหยียดขาขวานำเข้าหาบอล ขาซ้ายกางออกข้างจากสะโพกทั้งแท่ง*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.108, +0.050)` | `(+24.0°, +14.0°, -10.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.11 studs, เลื่อนลำตัวไปด้านหลัง (+Z) 0.05 studs, เอนหลัง (+rx) 24.0°, บิดลำตัวหันทางซ้าย (+ry) 14.0°, เอียงลำตัวทางขวา (-rz) 10.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-16.0°, -12.0°, +6.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 16.0°, หันศีรษะมองทางขวา (-ry) 12.0°, เอียงศีรษะทางซ้าย (+rz) 6.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +0.0°, +26.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 18.0°, กางออกด้านขวา (+rz) 26.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-28.0°, +0.0°, -20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 28.0°, กางออกด้านซ้าย (-rz) 20.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+46.0°, -8.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 46.0°, เปิดออกด้านนอก (-ry) 8.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-22.0°, -16.0°, -22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 22.0°, บิดเข้าด้านใน (-ry) 16.0°, กางออกด้านซ้าย (-rz) 22.0° |

**Keyframe 2 — `t = 0.38` (`0.209 s`): Active Full-Extension Slide [Ball Contact]**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.39, +1.21, -3.13)`, ฝ่าเท้าซ้าย = `(-2.36, +0.67, -2.09)`) — Active Slide (t=0.38): Torso ลดต่ำ (ty=-1.52, World Y=1.48) เอนหลัง +58° ขาขวาเหยียดขนานพื้นปะทะลูกบอล ขาซ้ายจัดมุมจากสะโพก (rx=+16°, ry=-28°, rz=-30°) ขนานพื้นโดยไม่งอเข่า*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -1.027, -0.180)` | `(+58.0°, +22.0°, -16.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 1.03 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.18 studs, เอนหลัง (+rx) 58.0°, บิดลำตัวหันทางซ้าย (+ry) 22.0°, เอียงลำตัวทางขวา (-rz) 16.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-28.0°, -18.0°, +10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 28.0°, หันศีรษะมองทางขวา (-ry) 18.0°, เอียงศีรษะทางซ้าย (+rz) 10.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+34.0°, +8.0°, +32.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 34.0°, บิดเข้าด้านใน (+ry) 8.0°, กางออกด้านขวา (+rz) 32.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-40.0°, +0.0°, -22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 40.0°, กางออกด้านซ้าย (-rz) 22.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+28.0°, -10.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 28.0°, เปิดออกด้านนอก (-ry) 10.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+16.0°, -28.0°, -30.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 16.0°, บิดเข้าด้านใน (-ry) 28.0°, กางออกด้านซ้าย (-rz) 30.0° |

**Keyframe 3 — `t = 0.72` (`0.396 s`): Turf Glide & Sweep Follow-Through**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.82, +1.13, -2.90)`, ฝ่าเท้าซ้าย = `(-2.44, +0.66, -2.00)`) — Glide (t=0.72): ไถลต่อเนื่องด้วยแรงเฉื่อย ขาขวากวาดผ่านจุดปะทะ แขนซ้ายยันประคองด้านหลังใกล้พื้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.939, -0.240)` | `(+62.0°, +28.0°, -18.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.94 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.24 studs, เอนหลัง (+rx) 62.0°, บิดลำตัวหันทางซ้าย (+ry) 28.0°, เอียงลำตัวทางขวา (-rz) 18.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-30.0°, -22.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 30.0°, หันศีรษะมองทางขวา (-ry) 22.0°, เอียงศีรษะทางซ้าย (+rz) 12.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+42.0°, +12.0°, +24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 42.0°, บิดเข้าด้านใน (+ry) 12.0°, กางออกด้านขวา (+rz) 24.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-36.0°, +0.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 36.0°, กางออกด้านซ้าย (-rz) 18.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+24.0°, +4.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 24.0°, บิดเข้าด้านใน (+ry) 4.0°, หุบเข้าหาลำตัว (-rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+14.0°, -30.0°, -32.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 14.0°, บิดเข้าด้านใน (-ry) 30.0°, กางออกด้านซ้าย (-rz) 32.0° |

**Keyframe 4 — `t = 1.00` (`0.550 s`): Slide Exit & Brace Preparation (Hands off to A18)**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.30, +0.99, -2.65)`, ฝ่าเท้าซ้าย = `(-2.01, +0.61, -1.71)`) — Exit (t=1.00): ชะลอความเร็วสไลด์ ตั้งแขนซ้ายและสะโพกเตรียมส่งเข้าท่าลุก A18 Slide Recovery*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.327, -0.100)` | `(+46.0°, +20.0°, -14.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.33 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.10 studs, เอนหลัง (+rx) 46.0°, บิดลำตัวหันทางซ้าย (+ry) 20.0°, เอียงลำตัวทางขวา (-rz) 14.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-22.0°, -16.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 22.0°, หันศีรษะมองทางขวา (-ry) 16.0°, เอียงศีรษะทางซ้าย (+rz) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+22.0°, +6.0°, +20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 22.0°, บิดเข้าด้านใน (+ry) 6.0°, กางออกด้านขวา (+rz) 20.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-32.0°, +0.0°, -16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 32.0°, กางออกด้านซ้าย (-rz) 16.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +0.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 18.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, -22.0°, -24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, บิดเข้าด้านใน (-ry) 22.0°, กางออกด้านซ้าย (-rz) 24.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A17

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Low reclined hip/glute and trailing Left Leg (angled at rx=+16°, ry=-28°, rz=-30° from hip so the rigid limb lies flat along the ground without knee flexion) + Left Arm rear brace.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.015 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.091 studs`
* **เรขาคณิตการปะทะลูกบอล (Ball Contact Geometry ที่ `t = 0.38`, `time = 0.209 s`)**:
  * **ชิ้นส่วนที่สัมผัสลูกบอล**: `Right Leg`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน Part Local Space**: `(+0.365, -1.000, -0.233) studs`
  * **จุดสัมผัสบนผิวชิ้นส่วนใน World / Character Space**: `(-0.047, +1.448, -3.262) studs`
  * **ตำแหน่งจุดศูนย์กลางลูกบอล (`R = 1.25 studs`)**: `(-0.385, +1.250, -4.449) studs`
  * **ระยะห่างจากผิวกล่อง OBB ถึงจุดศูนย์กลางบอล**: **`1.250 studs`** (เท่ากับรัศมีลูกบอล `1.250 studs` พอดี ไม่มีการย่อขนาดบอลและไม่มีขาเอื้อมไม่ถึง)

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A17

* **เข้าจากท่า (Enter From)**: A03 Sprint (0.05s), A02 Walk (0.05s), A05 Strafe (0.05s)
* **ออกไปท่า (Exit To)**: A18 Slide Recovery (0.00s direct hand-off from KF4)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Seamless 0.00s transition into A18 Slide Recovery (A18 KF1 matches A17 KF4).
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: เพราะขาหลัง (Left Leg) ของ R6 พับเข่าไม่ได้ จึงใช้การเอน Torso (+58°) บิดเอียงลำตัว (ry=+22°, rz=-16°) แล้วกางขาซ้ายออกจากสะโพก (rx=+16°, ry=-28°, rz=-30°) ทำให้แท่งขาซ้ายวางราบขนานพื้น (OBB min Y = 0.015 studs) โดยไม่มีส่วนใดจมพื้น

### A18 — Slide Recovery (Hit & Miss Visual Variants)

* **1) ID / ชื่อ / โหมด**: `A18` — **Slide Recovery (Hit & Miss Visual Variants)** | โหมด: **`One-shot (Shared KF1/KF4 with 'hit' and 'miss' visual mid-phase variants at KF2/KF3)`**
* **2) ภาพอ้างอิง (Key Poses Sheet)**: `A18.png` (แสดงครบ 4 Keyframes เต็มตัว พร้อมมุมกล้องหลัก `Side (-X View)` และมุมเสริม `Front-Right 3/4 View`)
* **3) Timeline (Proposed animation timing)**:
  * **Duration สำหรับ Preview**: `0.44 วินาที` (`t = 0.00` ถึง `1.00`)
  * **Blend-in / Blend-out**: `blendIn = 0.00 s`, `blendOut = 0.10 s`
  * **Hold Range**: `ไม่มี (ไม่ค้างท่า)`
  * **Contact Phase**: `ไม่มีการปะทะลูกบอลโดยตรง (Locomotion / Utility)`
  * **การอิงสถานะจริง (State Binding)**: `Follows A17 Slide Tackle completion; visual variant chosen by tackle hit-result flag without altering gameplay stun/velocity`

#### ตาราง Keyframe ครบ 6 ข้อต่อของ A18 (Coordinate Space: `Part0 Reference Space` รอบ `p = baseC0.Position`, ลำดับการคูณมุม: `Euler XYZ`)

##### Variant `hit` — A18-hit (On-Ball Clean Pop-Up Recovery)

**[HIT] Keyframe 1 — `t = 0.00` (`0.000 s`): Shared Entry from A17 Slide Exit**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.30, +0.99, -2.65)`, ฝ่าเท้าซ้าย = `(-2.01, +0.61, -1.71)`) — Shared KF1 (t=0.00): รับท่าต่อจาก A17 KF4 ตรงกัน 100% แขนซ้ายและสะโพกตั้งฐานพยุง*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.327, -0.100)` | `(+46.0°, +20.0°, -14.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.33 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.10 studs, เอนหลัง (+rx) 46.0°, บิดลำตัวหันทางซ้าย (+ry) 20.0°, เอียงลำตัวทางขวา (-rz) 14.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-22.0°, -16.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 22.0°, หันศีรษะมองทางขวา (-ry) 16.0°, เอียงศีรษะทางซ้าย (+rz) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+22.0°, +6.0°, +20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 22.0°, บิดเข้าด้านใน (+ry) 6.0°, กางออกด้านขวา (+rz) 20.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-32.0°, +0.0°, -16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 32.0°, กางออกด้านซ้าย (-rz) 16.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +0.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 18.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, -22.0°, -24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, บิดเข้าด้านใน (-ry) 22.0°, กางออกด้านซ้าย (-rz) 24.0° |

**[HIT] Keyframe 2 — `t = 0.35` (`0.154 s`): On-Ball Variant: Energetic Hip Pop & Chest Whip**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.19, +0.74, -1.78)`, ฝ่าเท้าซ้าย = `(-1.21, +0.31, +0.65)`) — On-Ball (t=0.35): เมื่อสกัดโดนบอล โมเมนตัมหยุดที่บอล ดึงขาสองข้างสลับหน้า-หลัง (+38°/-26°) ดีดสะโพกขึ้นเร็ว*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.149, +0.000)` | `(+10.0°, +10.0°, -8.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.15 studs, เอนหลัง (+rx) 10.0°, บิดลำตัวหันทางซ้าย (+ry) 10.0°, เอียงลำตัวทางขวา (-rz) 8.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -8.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 6.0°, หันศีรษะมองทางขวา (-ry) 8.0°, เอียงศีรษะทางซ้าย (+rz) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+36.0°, +0.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 36.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-24.0°, +0.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 24.0°, กางออกด้านซ้าย (-rz) 14.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+38.0°, -6.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 38.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-26.0°, -8.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 26.0°, บิดเข้าด้านใน (-ry) 8.0°, กางออกด้านซ้าย (-rz) 14.0° |

**[HIT] Keyframe 3 — `t = 0.70` (`0.308 s`): On-Ball Variant: Forward Drive Step Rise**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.52, +0.08, +0.01)`, ฝ่าเท้าซ้าย = `(-0.73, +0.51, +1.50)`) — On-Ball (t=0.70): ยกลำตัวขึ้นโน้มหน้า (-16°) พร้อมก้าวขาขวาออกวิ่งไล่บอลต่อทันที*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.094, +0.000)` | `(-16.0°, +4.0°, -2.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.09 studs, โน้มหน้า (-rx) 16.0°, บิดลำตัวหันทางซ้าย (+ry) 4.0°, เอียงลำตัวทางขวา (-rz) 2.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+14.0°, -4.0°, +2.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 14.0°, หันศีรษะมองทางขวา (-ry) 4.0°, เอียงศีรษะทางซ้าย (+rz) 2.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(-18.0°, +0.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนขวาไปด้านหลัง (-rx) 18.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+28.0°, +0.0°, -14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 28.0°, กางออกด้านซ้าย (-rz) 14.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+22.0°, -4.0°, +5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 22.0°, เปิดออกด้านนอก (-ry) 4.0°, กางออกด้านขวา (+rz) 5.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(-20.0°, +4.0°, -5.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาซ้ายไปด้านหลัง (-rx) 20.0°, เปิดออกด้านนอก (+ry) 4.0°, กางออกด้านซ้าย (-rz) 5.0° |

**[HIT] Keyframe 4 — `t = 1.00` (`0.440 s`): Shared Exit: Athletic Ready Stance**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.63, +0.18, +0.64)`, ฝ่าเท้าซ้าย = `(-0.62, +0.11, +0.13)`) — Shared KF4 (t=1.00): กลับสู่ท่ายืนพร้อมเล่น A01 Ready ครบสมบูรณ์*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.140, +0.000)` | `(-8.0°, -4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

##### Variant `miss` — A18-miss (Whiff Roll-Over Push-Up Recovery)

**[MISS] Keyframe 1 — `t = 0.00` (`0.000 s`): Shared Entry from A17 Slide Exit**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(-0.30, +0.99, -2.65)`, ฝ่าเท้าซ้าย = `(-2.01, +0.61, -1.71)`) — Shared KF1 (t=0.00): รับท่าต่อจาก A17 KF4 ตรงกัน 100% แขนซ้ายและสะโพกตั้งฐานพยุง*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, -0.327, -0.100)` | `(+46.0°, +20.0°, -14.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ลดระดับลำตัว (ลง -Y) 0.33 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.10 studs, เอนหลัง (+rx) 46.0°, บิดลำตัวหันทางซ้าย (+ry) 20.0°, เอียงลำตัวทางขวา (-rz) 14.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(-22.0°, -16.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ก้มศีรษะ/เก็บคาง (-rx) 22.0°, หันศีรษะมองทางขวา (-ry) 16.0°, เอียงศีรษะทางซ้าย (+rz) 8.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+22.0°, +6.0°, +20.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 22.0°, บิดเข้าด้านใน (+ry) 6.0°, กางออกด้านขวา (+rz) 20.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-32.0°, +0.0°, -16.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 32.0°, กางออกด้านซ้าย (-rz) 16.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(+18.0°, +0.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาขวาไปด้านหน้า (+rx) 18.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, -22.0°, -24.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, บิดเข้าด้านใน (-ry) 22.0°, กางออกด้านซ้าย (-rz) 24.0° |

**[MISS] Keyframe 2 — `t = 0.35` (`0.154 s`): Miss/Whiff Variant: Side-Roll Hand Plant Brace**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.75, +0.45, +1.67)`, ฝ่าเท้าซ้าย = `(-2.10, +0.73, +0.52)`) — Miss Variant (t=0.35): เมื่อสไลด์วืด แรงเฉื่อยพาตัวไถลเลยไป จึงพลิกตัวคว่ำลงเล็กน้อย (-18°) ใช้แขนดันพื้นพยุงตัวขึ้น*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.060, -0.049, -0.060)` | `(-18.0°, +28.0°, -16.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางขวา (+X) 0.06 studs, ลดระดับลำตัว (ลง -Y) 0.05 studs, เลื่อนลำตัวไปด้านหน้า (-Z) 0.06 studs, โน้มหน้า (-rx) 18.0°, บิดลำตัวหันทางซ้าย (+ry) 28.0°, เอียงลำตัวทางขวา (-rz) 16.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+14.0°, -22.0°, +10.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 14.0°, หันศีรษะมองทางขวา (-ry) 22.0°, เอียงศีรษะทางซ้าย (+rz) 10.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+34.0°, +12.0°, +22.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 34.0°, บิดเข้าด้านใน (+ry) 12.0°, กางออกด้านขวา (+rz) 22.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+24.0°, +0.0°, -28.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 24.0°, กางออกด้านซ้าย (-rz) 28.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-32.0°, -12.0°, +14.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 32.0°, เปิดออกด้านนอก (-ry) 12.0°, กางออกด้านขวา (+rz) 14.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+34.0°, +8.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 34.0°, เปิดออกด้านนอก (+ry) 8.0°, กางออกด้านซ้าย (-rz) 18.0° |

**[MISS] Keyframe 3 — `t = 0.70` (`0.308 s`): Miss/Whiff Variant: Heavy Push-Up & Turn Rise**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.015 studs`** ที่ชิ้นส่วน `Left Leg` | ฝ่าเท้าขวา = `(+0.69, +0.51, +1.73)`, ฝ่าเท้าซ้าย = `(-1.24, +0.22, +0.44)`) — Miss Variant (t=0.70): ดันลำตัวที่ก้มต่ำ (-22°) ขึ้นมาตั้งหลักด้วยขาซ้ายนำ (+26°)*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.030, -0.010, +0.000)` | `(-22.0°, +14.0°, -6.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เลื่อนลำตัวทางขวา (+X) 0.03 studs, ลดระดับลำตัว (ลง -Y) 0.01 studs, โน้มหน้า (-rx) 22.0°, บิดลำตัวหันทางซ้าย (+ry) 14.0°, เอียงลำตัวทางขวา (-rz) 6.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+18.0°, -14.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 18.0°, หันศีรษะมองทางขวา (-ry) 14.0°, เอียงศีรษะทางซ้าย (+rz) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+16.0°, +0.0°, +18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 16.0°, กางออกด้านขวา (+rz) 18.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(-22.0°, +0.0°, -18.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างแขนซ้ายไปด้านหลัง (-rx) 22.0°, กางออกด้านซ้าย (-rz) 18.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-24.0°, -6.0°, +8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 24.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 8.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+26.0°, +6.0°, -8.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 26.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 8.0° |

**[MISS] Keyframe 4 — `t = 1.00` (`0.440 s`): Shared Exit: Athletic Ready Stance**
*(HRP Ref Y = `3.00 studs` | Lowest OBB Corner Clearance = **`+0.010 studs`** ที่ชิ้นส่วน `Right Leg` | ฝ่าเท้าขวา = `(+0.63, +0.18, +0.64)`, ฝ่าเท้าซ้าย = `(-0.62, +0.11, +0.13)`) — Shared KF4 (t=1.00): กลับสู่ท่ายืนพร้อมเล่น A01 Ready ครบสมบูรณ์*

| ชื่อข้อต่อ (Motor6D) | Translation `tx, ty, tz` (studs) | Rotation `rx, ry, rz` (deg) | Coordinate Space | ลำดับการคูณ | คำอธิบายการเคลื่อนที่ของร่างกาย |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RootJoint` | `(+0.000, +0.140, +0.000)` | `(-8.0°, -4.0°, +0.0°)` | `HRP Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ยกระดับลำตัว (ขึ้น +Y) 0.14 studs, โน้มหน้า (-rx) 8.0°, บิดลำตัวหันทางขวา (-ry) 4.0° |
| `Neck` | `(+0.000, +0.000, +0.000)` | `(+8.0°, +4.0°, +0.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เงยศีรษะ (+rx) 8.0°, หันศีรษะมองทางซ้าย (+ry) 4.0° |
| `Right Shoulder` | `(+0.000, +0.000, +0.000)` | `(+10.0°, -6.0°, +12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนขวาไปด้านหน้า (+rx) 10.0°, เปิดออกด้านนอก (-ry) 6.0°, กางออกด้านขวา (+rz) 12.0° |
| `Left Shoulder` | `(+0.000, +0.000, +0.000)` | `(+14.0°, +6.0°, -12.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงแขนซ้ายไปด้านหน้า (+rx) 14.0°, เปิดออกด้านนอก (+ry) 6.0°, กางออกด้านซ้าย (-rz) 12.0° |
| `Right Hip` | `(+0.000, +0.000, +0.000)` | `(-6.0°, -5.0°, +4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | ดึง/ง้างขาขวาไปด้านหลัง (-rx) 6.0°, เปิดออกด้านนอก (-ry) 5.0°, กางออกด้านขวา (+rz) 4.0° |
| `Left Hip` | `(+0.000, +0.000, +0.000)` | `(+6.0°, +5.0°, -4.0°)` | `Torso Space (Part0)` | `XYZ (Rx*Ry*Rz)` | เหวี่ยงขาซ้ายไปด้านหน้า (+rx) 6.0°, เปิดออกด้านนอก (+ry) 5.0°, กางออกด้านซ้าย (-rz) 4.0° |

#### 5) ข้อมูลเรขาคณิต (Geometry & Contact Verification) ของ A18

* **ขารับน้ำหนักและตำแหน่งฝ่าเท้า**: Left Arm + Left Hip brace at t=0.00; split-leg scissor lift at t=0.35..0.70; dual ready stance at t=1.00.
* **การตรวจ Oriented Bounding Box (OBB Clearance จากพื้น `World Y = 0`)**: ตรวจสอบมุมทั้ง 8 ของทุกชิ้นส่วน R6 แล้ว จุดต่ำสุดของท่าอยู่ที่ **`+0.010 studs`** (ไม่มีเฟรมใดที่มุมกล่องของเท้า ลำตัว แขน หรือศีรษะทะลุต่ำกว่า `Y = 0.000 studs`) และจุดสูงสุดของร่างกายอยู่ที่ `+5.198 studs`

#### 6) การเชื่อมต่อท่าและข้อจำกัด (Transitions & R6 Constraints) ของ A18

* **เข้าจากท่า (Enter From)**: A17 Slide Tackle (0.00s direct hand-off from A17 KF4)
* **ออกไปท่า (Exit To)**: A01 Idle (0.10s), A02 Walk (0.10s), A03 Sprint (0.10s)
* **ข้อต่อที่ถูก Override**: `RootJoint, Neck, Right Shoulder, Left Shoulder, Right Hip, Left Hip`
* **ข้อต่อที่ยังใช้ Locomotion ได้**: `ไม่มี (Full-body pose control เพื่อความแม่นยำของจุดศูนย์ถ่วง)`
* **วิธีคืน Pose เมื่อจบหรือยกเลิก**: Both 'hit' and 'miss' variants share identical KF1 (t=0.00) and KF4 (t=1.00) and identical 0.44s duration so visual feedback differs without affecting game balance.
* **การจัดการ Foot Sliding, Clipping และข้อจำกัดของ R6**: ใช้ KF1 (t=0.00) และ KF4 (t=1.00) ร่วมกัน 100% และแตกแขนงเฉพาะ KF2 (t=0.35) กับ KF3 (t=0.70) เพื่อแยกภาษากายระหว่างสกัดโดนบอล (ดีดตัวขึ้นหน้าทันที) กับสไลด์พลาด (พลิกอกดันพื้นลุกขึ้น) โดยไม่ไปแก้ระยะเวลาล็อกตัวละครของระบบเกม
