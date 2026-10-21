# 01-cage-physics — สนามกรง 3D A/B/C และฟิสิกส์บอล

- **Phase:** 1; **State:** OPEN / PENDING_TECHNICAL_REVIEW (Implementation complete per fix-005; Owner instructed to hold technical review for later and proceed to 02-player-actions; does not close Plan 01)
- **Owner:** Stang; **Controller:** Codex; **Implementer:** AGY Teamwork-preview
- **Implementation approval:** P-03 Implementation Complete per fix-005; technical review paused by Owner (แผน `00` คง `OPEN / PAUSED_BY_OWNER`, แผน `01` คง `OPEN / PENDING_TECHNICAL_REVIEW`)
- **Baseline:** `main` @ `65026668fcae9d80094841bb147f3f4dc64b0b6c`
- [Tasks](tasks.md) / [Notes](notes.md) / [HANDOFF](assets/HANDOFF.md) / [Architecture](../../../design/architecture-and-network.md) / [Spec 01](../../../specs/spec-01-cage-and-events.md) / [Phase](../plan.md)
- **Prerequisite & Seam:** ใช้สัญญา R6 runtime จากแผน 00 (`ServerStorage.CageZeroStandardR6Rig`, `PrimaryPart=HumanoidRootPart`, `RigAndCardService`, `R6AnimationController`) เชื่อมเข้ากับ `Workspace.HexCageArena.CageFloor` โดยยังไม่ปิดแผน 00
- **คำตอบผู้ใช้ 2026-10-20 & Directives:**
  - B/C ปาด 4 มุมเป็น 8 ผนัง และใช้ฟิสิกส์การชิ่งจริง + marker ไกด์ ไม่มีแรงนำบอลเข้าจุดนัดพบ
  - **Approved Directive Deltas (Provenance: `ORIGINAL_REQUEST.md`):**
    1. ประตูย้ายไปฝังกำแพงหัวท้ายที่ $Z = \pm 120.0$; สัญญาทางเดินหลังโกล 14 studs เดิมถือเป็น **SUPERSEDED**
    2. Default cage variant ตั้งเป็น `"A"` (`DEFAULT_CAGE_VARIANT = "A"`)
    3. ลดระดับ Baseplate ลงที่ $Y = -10.05$ (หน้าบน $Y = -2.05 < -2.00$) เพื่อแยกการชนกับ CageFloor ที่ $Y = 0.0$
    4. `.gitignore` คง `/.agents/` ตามคำสั่งผู้ใช้

## Scope และขอบเขต

- เตรียมสนาม A/B/C สำหรับเทียบทดลอง ไม่เลือกผู้ชนะหรือ default map สุดท้ายก่อนมีข้อมูล; เปิดทีละ variant ในฉากทดลอง
- ทุกผิวกำแพง/เพดานที่ออกแบบเป็นผิวชิ่งต้องมี collider/solver surface ตรงภาพ รวมรอยต่อ เพดานลาด และมุม; “ชิ่งได้ทุกจุด” เป็นเป้าหมาย coverage ไม่ใช่ผลพิสูจน์ zero tunneling ทุกความเร็ว
- builder/solver ใช้ geometry catalog เดียว รวม finite faces/normal/thickness/ball radius/ramp footprint
- คง R6 ตลอด Phase 1, bumper nominal 1.25, ramp 25°; ไม่เปิด full match/GK/ball possession/duel/UI หรือ event gameplay ใน 01
- test launch fixture ใช้เพื่อวัด collision เท่านั้น ไม่ถือว่าส่งมอบการยิง/เลี้ยง/Header/Volley ของแผน 02

## Map list — 3 โครงสร้างกรงสำหรับเทียบทดลอง

| Profile | ลักษณะกำแพงข้างและมุม | เพดาน | ฟีลที่ต้องทดลอง ไม่ใช่ผลรับรอง |
| --- | --- | --- | --- |
| **A — Classic Box Cage** | กล่องสี่เหลี่ยม 4 ผนัง ตรง/ตั้งฉาก อ้างรูปแบบ FootballSandbox โดยไม่แก้ prototype | เรียบขนานพื้น สูงเริ่มทดลอง 32 studs (ช่วง 30–32 เป็นค่าจูน) | baseline อ่าน one-two ง่าย; ตรวจมุมสอง/สามผิวว่ามีเด้งย้อนหรือค้างหรือไม่ ไม่อ้างว่าทุกลูกย้อนทางเดิม |
| **B — Four-Corner Chamfered Cage** | สี่เหลี่ยมปาด 4 มุม = **8 ผนัง**: 4 ผนังหลัก + 4 ผนังเฉียง ติด bumper ที่ผนังเฉียง | เรียบ + Ceiling Rebound Markers หน้าเขตโทษสองฝั่ง | ทดลองการตัดบอลเข้าหน้าโกลจากมุมเฉียง/ลดการค้างมุม ทิศขึ้นกับจุดยิง มุมเข้า normal และความเร็ว ไม่ auto-cross |
| **C — Beveled Roof Street Cage** | ใช้ footprint/ผนัง 8 ด้านเดียวกับ B เพื่อแยกผลหลังคา | กลางเรียบ ขอบเชื่อมผนังกับเพดานลาด 45° รอบกรง; มี faces ต่อกันครบที่มุม | ทดลองชิ่งบริเวณขอบสูงแล้วลงกลางสนามสำหรับลูกกลางอากาศ ไม่รับรองว่าจะตกหน้าประตูทุกมุม |

ชื่อ Hex-Cage เดิมเป็น label ของ baseline ไม่ใช่ geometry 6 ผนังที่ต้องคงไว้ใน B/C รอบเปรียบเทียบนี้ การเปลี่ยนเป็น 8 ผนังมาจากคำตอบผู้ใช้โดยตรง ไม่ขยายกลับไปทำแบบ 6 ผนังเพิ่มอีก profile

## Geometry/config และสัญญาใช้ร่วมกัน

- ใช้ bounds/goal positions/ball radius/material response เหมือนกันเมื่อเทียบ shape: ค่าเริ่มต้น X±80/Z±120, floor Y=0, max ceiling Y=32, ball radius 1.25 เป็น design defaults ไม่ใช่ค่าผลิตภัณฑ์ที่ล็อกถาวร
- A polygon: `(-80,-120),(80,-120),(80,120),(-80,120)`
- B/C polygon เสนอ cut 20 studs: `(-60,-120),(60,-120),(80,-100),(80,100),(60,120),(-60,120),(-80,100),(-80,-100)`; cut length เป็น config
- C เสนอ bevel width/drop 8 studs ที่ 45°: outer wall/eave Y=24, central roof Y=32; inset polygon/8 bevel faces/corner seams สร้างจาก config เดียว ห้ามเหลือช่องหรือเอา flat ceiling ของ B มาชนซ้ำใต้ bevel
- goal front planes Z±120.0 (integrated into end walls; back zone 14 studs is SUPERSEDED per directive); ตรวจความกว้าง/ความลึก/คานจริงและ R6 clearance
- CagePhysicsService เป็นเจ้าของ ArenaGeometry catalog และ activeVariantId; visual builder, swept sphere solver, ramp queries และ marker layout อ่านข้อมูลชุดเดียวกัน
- เสนอ builder API กลาง `BuildCageArena(parent?, variantId)` แทนชื่อผูก Hex; บันทึก/อัปเดตผู้เรียกเดิมของ BuildHexCageArena ในขอบเขต service/bootstrap/fixture ตอน implement ไม่สร้าง wrapper ซ้ำโดยไม่มี consumer จริง
- คง ComputeReboundVelocity/StepBallCageCollision/ApplyRampImpulse/zone queries เดิม เว้นมี contract delta ที่ระบุชัดก่อนลงมือ; ไม่มี remote ใหม่ใน 01
- คง root model path `Workspace.HexCageArena` เป็น legacy stable path เพื่อให้ floor seam จาก 00 ใช้ได้; Attribute CageVariantId บอก geometry จริง อย่าอนุมาน 6 ด้านจากชื่อ root
- bootstrap 01 สร้าง arena ก่อน Rig.Init และ PRIMARY_FLOOR_PATH ชี้ `Workspace.HexCageArena.CageFloor`; retire fixture 00 เฉพาะส่วนที่เป็น owner พร้อม rollback ไม่ลบ Baseplate ผู้ใช้

## จุดชิ่งประจำสนาม — Base Rebound Mechanics

| กรณี | สิ่งที่จะทดลองใน 01 | การแปลผลและ dependency |
| --- | --- | --- |
| **Ceiling Lob & Smash** | launch เข้าผิวเพดานหลายมุม/แรง; วาง ceiling sweet-spot markers หน้า goal ทั้งสองฝั่ง | marker ชี้จุดเล็ง/ตัวอย่างวิถีเท่านั้น ไม่ snap ลูกลงจุดนัดพบ; เก็บ landing distribution ระยะตก และเวลารับบอล; Header/Volley จริงตรวจใน 02/09 |
| **Over-Goal Transom Rebound** | แยก surface เหนือคานจาก goal frame ตาม geometry จริง; ลอง response สูงขึ้นเป็น config | ไม่ hardcode Y=9–32 แทนความสูงคาน/roof จริง โดยเฉพาะ C; วัดโอกาสได้ second ball ไม่รับรองว่าตกเส้นเขตโทษพอดี |
| **Corner Pinball Bumpers** | B/C วาง 4 แผงที่ผนังเฉียง; A ใช้เป็น baseline และเพิ่ม bumper overlay แยกรอบเพื่อไม่ปนผล shape | nominal response 1.25/เป้าหมาย speed gain 25% ก่อน speed cap ของ solver; บันทึก input/output จริง ไม่ auto-aim หน้าโกล และไม่บวก response ซ้ำกับ engine |
| **Side Elevating Ramps 25°** | วางซ้าย/ขวากลางสนามตาม CFrame/Size จริง ตรวจ footprint/height/edge และยกบอลตอน launch ออกจาก ramp | นอกปลาย/ด้านข้าง/ใต้ ramp ไม่ได้ lift; แรงยกจูนได้ ท่าเลี้ยง/ยิงจาก ramp จริงเป็น 02 |
| **Back-Goal Alley (SUPERSEDED)** | โกลอยู่ที่ $Z = \pm 120.0$ ตาม directive ล่าสุด ไม่มีทางเดินหลังโกล | วัดลูกย้อนสู่หน้าประตู/ข้ามคาน; ไม่เริ่ม goal scoring logic ใน 01 |

## แผนเทียบที่ควบคุมตัวแปร

1. **Shape pass:** A/B/C ใช้ response/ball properties/launch inputs/goal positions/seed/dt envelope เดียวกัน ปิด events, bumper boost และ ramp lift ชั่วคราวใน test config เพื่อวัดผล shape/roof
2. **Mechanics pass:** เปิด transom/bumper/ramp ทีละรายการ ทำรอบ mirrored ซ้าย-ขวาและ goal ทั้งสองฝั่ง; คงชื่อ profile/feature flags ใน evidence
3. **Event pass:** ใช้ data set เดียวกันเมื่อถึงแผน 07 หลัง 05/06 gates ไม่ย้าย event physics/VFX/NPC มาทำใน 01
4. ใช้ launch points ที่อยู่ใน free volume ร่วมกัน และชุดเฉพาะ surface/มุมเพิ่มอย่างมี label ไม่เทียบชุดยิงคนละอย่างแล้วสรุปว่า shape ใดดีกว่า
5. วัด clipping/escape, repeated-contact/ค้างมุม, speed ก่อน/หลัง/ก่อน cap, landing distribution, เวลา second ball, ความอ่านง่ายและ R6 traversal; ประกาศ speed/dt/radius envelope ที่ตรวจจริง
6. ตารางผล A/B/C เริ่ม NOT RUN ทุกช่อง เลือกสนามหลักจากผลทดลอง/Owner decision ภายหลัง ไม่ตั้ง B หรือ C ชนะไว้ล่วงหน้า

## Acceptance / verification

- surface coverage ทุก wall/roof/seam ของแต่ละ profile ตรง collider/solver จาก catalog เดียว ไม่ใช้ rectangle clamp แล้วอ้างว่า octagon/bevel ผ่าน
- swept sphere/time-of-impact ใช้ radius/remaining dt รองรับ high speed, grazing และ corner หลาย contact; จัดการ step budget/contact dedup พร้อมระบุข้อจำกัดเมื่อหมด budget
- ramp bounds/แรงยก, transom/frame และ goal zone ตรวจแยก; R6 เดิน/กระโดด/ramp ได้โดยไม่เปลี่ยน rig schema (back alley Z=±106 เดิมถือเป็น superseded per approved directive ที่ย้ายโกลไปฝัง Z=±120)
- marker ไม่เปลี่ยน velocity/trajectory; final landing เป็นผล reflection จริงของมุมยิง ไม่ใช่ aim assist
- ไม่ทะลุในชุดทดสอบที่ประกาศและต้องไม่มี visual-only ceiling/ผิวหาย; ถ้าเคสใด fail ให้รายงาน ไม่สรุป ‘100%’ โดยไม่มีขอบเขตข้อมูล
- focused probes/tests + Studio visual UAT ตรง source/ref; runtime ที่ไม่ได้ตรวจยัง NOT VERIFIED
- ไม่มี MatchService/ball actions/full match/UI/event gameplay เกินแผน 01

## ยังไม่ล็อก

ความหนา/epsilon/contact budget/material responses, cut size/bevel width และตำแหน่ง marker เป็นค่าจูนที่กำหนดจาก geometry/evidence ใน scope ตาม [assets/HANDOFF.md](assets/HANDOFF.md) ส่วนรูปแบบสนามที่ใช้จริงเลือกหลังเทียบ และ interaction events/duel/GK/ลูกนิ่ง grill เมื่อเปิดแผนเจ้าของ
