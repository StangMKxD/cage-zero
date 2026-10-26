> **CURRENT TARGET 2026-10-26 — Street Football:** [authoritative Phase1 plan](../plan/phase-01-gameplay-demo/release-first/plan.md) supersedes conflicting target/delivery statements below (retained as historical/reference). Phase1: R15/core ball + kick/slide/poke/block/normal body-check, separate CombatHP/stun/I-frame, gauge+ground/air Orbs, **RF04 walls BEFORE six Supers**, one-use timed armed Super/manual aim/no homing/no guaranteed goal, capped gauge-rate-only per-copy earnedCash upgrade,2v2/tiedGoldenGoal. Remove foul/free kick/cards/penalties/regular overtime/SuperMastery power scaling. Extra dribble skills/gacha/13stats/Traits/advanced aerial hold+guides/shops deferredPhase2; walls remainPhase1. Owner approved docs commit and checklist7 dribble/receive plus later explicit high momentumjump/four-way airlean and relevant locomotion fixes now; no blanket source implementation/commit/push/publish authority. Owner first6 visual accepted; technical review remains separate. Historical code/reviews/findings not erased.

# Spec 01 — สนามกรง 3D และอีเวนต์เปลี่ยนสภาพสนาม

> **Owner Directive 2026-10-25 (Release-First Arena Target):** สำหรับ [Release-First Track](../plan/phase-01-gameplay-demo/release-first/plan.md) มุ่งสู่ Public Alpha ได้เลือก **Stadium A (4 ผนังเรียบ + เพดาน)** เป็นสนามหลักในการแข่งขัน Casual 2v2 เพื่อรองรับกลไก **Cage Slingshot** (Wall Run / Wall Launch ใน [RF-04](../plan/phase-01-gameplay-demo/release-first/RF-04/plan.md)) โดยคงฟิสิกส์การชิ่งบอลเดิม ส่วน Profile B/C และ Dynamic Events ทั้ง 6 แบบ ถูกเลื่อนไปต่อยอดใน Phase 2 ตามลำดับ

## 1. สเปกสนามกรง 3D — profile comparison
สนามแข่งขันเป็นการรวม 5 มิติการเล่นไว้ในสนามเดียว คำนวณการสะท้อนฝั่ง Server (`R = V - 2(V·N)N`):

| องค์ประกอบสนาม | รายละเอียดการทำงานและฟิสิกส์ |
| :--- | :--- |
| **1. กรง 3D A/B/C และเพดานชิ่ง** | Aกล่อง4ผนัง/เพดานเรียบ, Bปาด4มุม8ผนัง/เพดานเรียบ, Cฐาน8ผนังเดียวกับB/ขอบหลังคา45° ทุกผิวที่เป็นผิวชิ่งต้องมีgeometry/collisionตรงกัน markerบนเพดานเป็นไกด์ไม่มีแรงนำบอล; ใน Stadium A ลูกบอลลอยฟ้าแสดงเส้นวิถีพยากรณ์พร้อมการชิ่งผนัง/เพดานและจุดตกให้ผู้เล่นทุกคนเห็นแบบเรียลไทม์ตามมติ Owner 2026-10-25 |
| **2. Corner Pinball Bumpers** | B/Cมี4แผงบนผนังเฉียง nominal1.25/targetspeedgain25%ก่อนspeedcap ทิศตามnormalไม่auto-cross; Aใช้baselineและเทียบoverlayแยกรอบ |
| **3. โกลมีพื้นที่เล่นด้านหลัง (`360° Goal Zone`)** | ตัวประตูตั้งยื่นออกมาจากผนังหลัง `14 Studs` ทำให้ผู้เล่นเลี้ยงบอลอ้อมหลังโกล หรือเตะบอลอัดกำแพงหลังโกลเพื่อให้บอลเด้งย้อนกลับมาหน้าปากประตูได้ |
| **4. ทางลาดริมเส้น (`Elevating Ramps`)** | ขอบสนามซ้าย-ขวามีทางลาดเอียง `25 องศา` เมื่อผู้เล่นเลี้ยงบอลขึ้นทางลาดแล้วกดส่งหรือเตะ บอลจะได้รับแรงยกตัว (`Upward Impulse`) ลอยโด่งข้ามหัวกองหลังเข้ากลางสนามทันทีเพื่อให้เพื่อนวิ่งเข้าชาร์จกลางอากาศ |
| **5. โหมดทีมและTraining** | คง3v3/4v4และTraining; 1v1v1ถูกตัดตามaccepted decision N-08 ไม่คืนจากspecเก่า |

## 2. สเปก 6 อีเวนต์เปลี่ยนสภาพสนามกลางแมตช์ (Dynamic Match Events)
Phase1 ใช้ controllerฉากฝึกเปิด/สลับ/จบ/คืนสภาพได้ ไม่ต้องมีmatch clock5นาที; 90s interval/40s durationเป็นdefaultconfigของสามeventเดิม ไม่ใช่การอนุมัติfull match:

| ชื่ออีเวนต์ | การเปลี่ยนแปลงของสภาพแวดล้อม | ผลกระทบต่อเกมเพลย์ & การรองรับผู้เล่น |
| :--- | :--- | :--- |
| **Event 1: เสาโผล่ขวางสนาม (`Pillar Lockdown`)** | เสาคอนกรีตขนาดใหญ่ 2–4 ต้นพุ่งขึ้นมาจากพื้นสนามตามจุดยุทธศาสตร์ (มีวงเตือนสีแดงบนพื้นล่วงหน้า `1.5 วินาที` พร้อมเสียงไซเรนก่อนเสาผุด) | เสาบล็อกทางวิ่งและขวางวิถียิงตรงๆ แต่พื้นผิวเสาสะท้อนบอลได้ 100% ผู้เล่นสามารถเตะบอลชิ่งเสาทำมุมหักศอก 90 องศาเพื่อหลบกองหลังได้ |
| **Event 2: หลุมดำมืดมิด (`The Blackout Void`)** | สภาพแวดล้อมรอบสนาม ผนังกรง และเพดานกลายเป็นสีดำสนิททั้งหมด (`Transparency = 1` หรือกลืนไปกับหมอกสีดำ) มองไม่เห็นขอบชิ่งแมพ เห็นเพียง **เสาโกลเรืองแสง, ลูกบอลนีออน และตัวผู้เล่นทุกคนที่มี Highlight สีทีม** | ผนังชิ่งยังคงมี Hitbox เหมือนเดิมแต่แค่มองไม่เห็น ผู้เล่นต้องใช้ความจำระยะสนาม (Spatial Memory) ในการชิ่งบอล หรือเปลี่ยนมาต่อบอลสั้นเท้าสู่เท้า |
| **Event 3: ตรอกสลัมบราซิล (`Favela Alleyway`)** | เปลี่ยนบรรยากาศขอบสนามเป็นกำแพงสังกะสีและตึกแถวซอยแคบสไตล์บราซิล พร้อมปล่อย **NPC คนเดินผ่าน (Pedestrians)** เดินตัดผ่านในสนาม | NPC ใช้โมเดล Low-Poly จำนวนจำกัด (2–3 ตัว) คำนวณตำแหน่งบน Server ตามเส้นทาง Waypoint คงที่แล้วส่งค่าเวลาเริ่มต้นให้ Client วาดอนิเมชันตรงกัน ตัว NPC มี Hitbox สะท้อนบอลและขวางทางวิ่ง ผู้เล่นสามารถใช้ NPC เป็นกำแพงบังกองหลัง หรือเตะชิ่งตัว NPC ได้ |
| **Event 4: Rebound Rush (ชื่อชั่วคราว)** | ชนกำแพง/เพดาน/ขอบลาดแล้วเร่งสู่targetSpeedคงที่ของevent ไม่เพิ่มทบทุกbounce | ใช้กับA/B/C ไม่รวมพื้น/เสา/NPC/ผู้เล่น ไม่ซ้อนbumperboost จบeventหยุดเพิ่มแรงแต่คงvelocityปัจจุบัน; ค่าจูนผ่านDebug รายละเอียดและacceptanceอยู่plan07 |
| **Event 5: Wall-Dash Overdrive** | ทุกทีมStaminaไม่จำกัดเฉพาะActive ไม่ต้องชิ่งหรือDashไปรับบอลเพื่อรับรางวัล | cooldown/recoveryยังปกติ HUDมีhighlightวิ่งเร็วบนหลอด ไม่ใช่เพิ่มmovement speed; จบแล้วเติมStamina100%หนึ่งครั้งและใช้ปกติ ไม่รีเซ็ตCD/recovery |
| **Event 6: Low-Roof Compression** | ใช้เพดานeventเรียบใต้ผิวสูงจากสนาม12studsร่วมทุกA/B/C แล้วคืนroofเดิมเมื่อจบ | warning/ลดต่อเนื่อง visualกับcolliderตรงกัน ไม่มีbevelCค้างหรือซ้อน ทดสอบball/player/goalclearance ไม่รับรองเวลาบอลเร็วขึ้น2เท่า |

## 3. Trial extensions และความหมายของ coverage

Base rebound5รายการ (ceiling lob/smash, over-goal transom, corner bumpers, side ramps25°, back-goal14) เป็นชุดทดลอง01; interactionกับpillarสองระดับ/capเอียง, Blackout ripple1s และ Favela moving signsอยู่07ตามplan; Rebound Rushเป็นevent4ที่Ownerเพิ่มภายหลัง แยกจากtrialเดิม

คำว่า “ชิ่งทุกจุด/100%” เป็นเป้าหมายออกแบบcoverageของผิว ไม่ใช่หลักฐานว่าทุกรูปมุม/แรง/dtไม่ทะลุ ให้รายงานsurface matrix, supported speed/dt envelope และข้อจำกัดจริง ฟีลจุดตก/ตัดเข้าgoal/volleyต้องวัด ไม่มีการsnap/forceไปsweet spot
