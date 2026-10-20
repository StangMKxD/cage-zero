# 07-dynamic-field-events — อีเวนต์สนาม6แบบ

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [05-fouls-and-set-pieces](../05-fouls-and-set-pieces/plan.md), [06-training-ground](../06-training-ground/plan.md)

## Scope
- Pillar Lockdown, Blackout Void, Favela Alleyway พร้อม warning/collision/VFX/NPC sync
- ใช้เวลาและตัวควบคุมฉากฝึกสำหรับเปิด สลับ จบ และคืนสภาพ ไม่ต้องมี match clock 5 นาทีก่อน
- เพิ่มอีเวนต์ที่4ตามคำสั่งOwner: Rebound Rush (ชื่อชั่วคราว) ชนผนัง/เพดาน/ขอบลาดแล้วเร่งบอลสู่ความเร็วเป้าหมายคงที่ ไม่สะสม

## Acceptance / ก่อนลงมือ
- เสาเตือนก่อนเกิด/ชิ่งได้ Blackout ซ่อนภาพแต่ยังชนได้ และยังเห็นบอล/โกล/ผู้เล่น
- Favela NPC sync และชนบอล/ขวางทางได้ตาม spec; ตรวจผลกับSkill Moves/เกมรับ/โกล/ลูกนิ่งไม่ให้ state ค้าง
- วัดปัญหาประสิทธิภาพที่พบ ไม่รับรองว่าเฟรมไม่ตกโดยไม่มีหลักฐาน

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น


## Rebound experiments เพิ่มตามคำสั่งผู้ใช้ 2026-10-20

ตารางtrialด้านล่างเป็นส่วนขยายของอีเวนต์เดิมสามชนิด ส่วนRebound Rushเป็นอีเวนต์ที่4ที่Ownerขอเพิ่มภายหลัง และยังไม่ถือว่าทุกรูปแบบถูกเลือกเป็น final gameplay ต้องเทียบกับ map profiles A/B/C จากแผน 01 หลัง prerequisites 05/06 พร้อม

| Event | Trial ที่เพิ่ม | สิ่งที่ต้องวัดและขอบเขต |
| --- | --- | --- |
| **Pillar Lockdown** | ชุดเริ่มทดลอง 3 เสา; response e=1.0–1.15 เป็นช่วงจูน; แถบนีออนชิ่งต่ำ/สูงสองระดับและ cap เอียงบนเสา | วัดเส้นทาง one-two/roof→cap/เสาไกล, contact/seam/เกิดหรือหายเสา, warningและclearance; ไม่รับรองว่าโกลรับไม่ทันหรือบอลหักเข้าเสาไกลทุกครั้ง |
| **Blackout Void** | ซ่อนภาพ wall/roof แต่คง collider; แสงขอบกรง/ceiling markers/โกล/บอล/ผู้เล่น และ Neon Impact Ripple อายุทดลอง1s ณ contact | ripple เป็น visual จาก contact จริง ไม่มีแรงช่วย trajectory; ทุก geometry A/B/C ต้องยังชิ่งเหมือนก่อนดับไฟ ทดสอบ lifetime/cleanup/จำนวนeffectและการอ่านเกม ไม่อ้างว่าเฟรมไม่ตก |
| **Favela Alleyway** | เริ่มทดลอง NPC3คนภายใต้ capเดิม และป้ายสังกะสี/ถังแขวนสลิงที่แกว่งใต้เพดานหน้า goal | moving collider ต้องมี server-authoritative trajectory/เวลาและ surface velocity; แยก visualกับphysics ตรวจ swept contact/เพดาน/goal/GK/ผู้เล่น ไม่ใช้ static-plane reflection อ้างว่า swing physics ผ่าน |

- Phase 1 ใช้ controller ฉากฝึกเปิด/สลับ/จบ/restore; 90s interval และ40s duration เป็น default config ของ eventเดิม ไม่ดึง match clock5นาทีมาเป็น dependency
- เทียบ baselineไม่มีeventกับมีevent แล้วเปลี่ยนหนึ่ง trial feature ต่อรอบ ใช้ launch set/activeVariantId เดียวกับ01; สูตร/response/timing เป็นค่าจูน ไม่เพิ่ม aim assist หรือ markerแรงนำบอล
- หลัง event จบ/cancel/restart ให้คืน geometry/visibility/material/collision state และล้าง transient surfaces/connections/effects/NPC/props ของ eventนั้น ไม่ทิ้ง contact ซ้ำหรือทรัพย์สินค้าง
- รายละเอียด contact payload/activation/replication กับ collision owner ออกแบบใน07; แผน01เตรียม surface IDs/normals/catalogและdiagnosticsเท่านั้น ไม่เพิ่ม endpoint หรือสร้าง moving props ใน01

## Event 4 — Rebound Rush (ชื่อชั่วคราว)

**Decision Accepted / Delivery Planned — 2026-10-20** Ownerขอ “ถ้าโดนกำแพงบอลจะเร่งความเร็วขึ้น” และตอบยืนยันขอบเขต/วิธีเร่ง/ตอนจบอีเวนต์แล้ว ImplementationยังPENDING ไม่ขยาย01หรือ00

- **ผิวที่มีผล:** กำแพงข้าง/หลัง/มุมเฉียง/ผนังเหนือประตู เพดานและขอบหลังคาลาดของA/B/C ไม่รวมพื้น ทางลาดพื้น กรอบประตู ผู้เล่น เสา หรือNPC
- **ความเร็ว:** เมื่อชนจริงสะท้อนทิศตามnormalแล้วเร่งสู่ค่าtargetSpeedคงที่ของอีเวนต์ ชนซ้ำไม่ทบเป็นตัวคูณเพิ่ม กรณีบอลเข้าเร็วกว่าtargetอยู่แล้วอีเวนต์ไม่ลดความเร็วลูกนั้น
- **ไม่บูสต์ซ้ำ:** responseมีเจ้าของเดียวในcollision pipeline ระหว่างeventไม่เอาtargetมาคูณเพิ่มซ้ำกับbumper1.25หรือenginebounce; contactเดิมที่ค้าง/ข้อมูลชนส่งซ้ำไม่สร้างboostใหม่ เมื่อจบคืนresponseปกติของสนาม
- **ช่วงเวลา:** มีผลต่อcontactsใหม่เฉพาะActive ใช้controllerเปิด/สลับ/จบ/คืนสภาพเดิม ไม่เปิดแมตช์เต็มหรือจับคู่กับeventอื่นเอง
- **ตอนจบ:** หยุดบูสต์ใหม่ แต่คงvelocityบอลที่กำลังพุ่ง ปล่อยให้ลด/เปลี่ยนตามฟิสิกส์และการเล่นต่อ ไม่ตัดกลับspeedปกติหรือหยุดบอลเพียงเพราะtimerจบ; cap/cleanupต้องไม่ทำให้เกิดการลดฉับพลันจากการคืนconfig
- **ค่าจูน:** targetSpeedต้องเป็นค่าจำกัดที่solverรองรับและสูงกว่าค่าชิ่งปกติในชุดเปรียบเทียบ ไม่ล็อกตัวเลขตอนวางแผน ให้Debug06ปรับ/แสดงtargetSpeedและเวลาActiveเฉพาะtestsessionได้ พร้อมdefault/restore
- **เจ้าของ:** EventManager07เป็นเจ้าของสถานะ/เวลา/override Collision owner01/02applyผลครั้งเดียวฝั่งServerจากsurfaceID/normalจริง ไม่เพิ่มaim assistหรือยิงเข้าประตูอัตโนมัติ; รายละเอียดAPI/config/networkeventชนิดใหม่ต้องระบุในHANDOFF07ก่อนแก้source

### Acceptance เพิ่ม

1. ทุกprofileA/B/Cตรวจwall/ceiling/bevelจริง ส่วนผิวที่ไม่เกี่ยวไม่เร่ง เก็บspeedเข้า/หลังสะท้อน/หลังeventresponse/targetและsurfaceID
2. หลายbounceยังใช้targetเดิม ไม่เพิ่มเป็นขั้นบันได ไม่ซ้อนbumperboost; contactค้าง/ซ้ำ/seam/multi-contactไม่เร่งซ้ำหรือทำballescape
3. บอลที่เร็วกว่าtargetไม่ถูกลดเพราะevent; targetต้องอยู่ในspeed/dt/radius envelopeที่ตรวจได้ ไม่อ้างรองรับทุกความเร็ว
4. จบ/cancel/switchหยุดboostใหม่และคืนconfigปกติโดยvelocityขณะนั้นไม่กระโดดลง ทดสอบbounceแรกหลังจบด้วย ไม่อาศัยเพียงนับtimer

## Event 5 — Wall-Dash Overdrive / Stamina ไม่จำกัด

**Scope Accepted / Delivery Planned — 2026-10-20** Ownerแก้ข้อเสนอเดิมเป็น “ทุกคน stamina ไม่จำกัด ... ถ้าเกิด event” และขอUIแสงวิ่งเร็วบนหลอด ไม่ใช้เงื่อนไขชิ่ง/Dashไปครองบอลเพื่อรับรางวัลแล้ว

- ระหว่างActive ทุกคนทั้งสองทีมใช้Staminaได้ไม่จำกัด ใช้กติกาเดียวกับactorที่ควบคุมคน/AI ไม่ต้องชนกำแพง เสาประตู หรือเสาอุปสรรค
- ระบบทรัพยากร02รับtemporaryeventmodifierจาก07เพื่อข้ามcost/เงื่อนไขStaminaไม่พอและอาการล้าจากStamina ขณะActive ไม่แก้ค่าต้นทุนปกติในconfigหรือเพิ่มความเร็ววิ่ง/แรงยิงด้วยเหตุจากชื่อevent
- Dash/Skill/ท่าเข้าสกัดยังติดcooldown/ช่วงจบท่า/recovery/เงื่อนไขท่าทางและballcontactตามเดิม ไม่มีI-frameหรือการล้างCD/ลุกจากSlideทันที
- HUDหลอดStaminaมีแถบhighlightวิ่งเร็วและสถานะไม่จำกัดที่อ่านออก ไม่สื่อว่าเป็นบัฟความเร็วตัวละคร; จบ/cancel/reset/เปลี่ยนgenerationให้ล้างeffectและresourceoverride ไม่มีค้างรอบถัดไป
- ผู้เล่นเข้าใหม่/respawnระหว่างActiveรับสถานะeventปัจจุบันจากServer ส่วนตัวเก่าไม่ทิ้งcallback/overrideต่อเนื่องหลังจบ
- **เมื่อจบ:** เติมStaminaทุกคนเป็น100%หนึ่งครั้งแล้วกลับไปใช้ต้นทุน/regenปกติ คูลดาวน์และrecoveryที่เหลือเดินต่อ ไม่รีเซ็ตหรือพักเวลา ตามคำตอบOwner2026-10-20; Endซ้ำของeventเดิมห้ามเติมซ้ำหรือแก้generationเก่า

## Event 6 — Low-Roof Compression

**Scope Accepted / Delivery Planned — 2026-10-20** Ownerเลือกเพดานอีเวนต์เรียบสูง12studsร่วมกันทุกprofile แล้วคืนทรงเดิมเมื่อจบ

- ความสูงอ้างผิวเล่นสนามถึงใต้เพดาน ไม่ตั้งpartcenterY=12โดยไม่หักความหนา ใช้temporaryflatceilingของeventกับA/B/C และเก็บgeometry/visibility/colliderstateเดิมไว้คืน
- สนามCพักการชนของroof/bevelเดิมเฉพาะช่วงoverride ไม่มีbevelที่เลื่อนลงจนขอบเหลือ4studsหรือcolliderสองชุดชนบอลซ้ำ; wallfootprintเดิมคงอยู่
- มีwarningและลดเพดานอย่างต่อเนื่องตามtimeline; visualและcollisioncatalogใช้ความสูง/เวลาชุดเดียว Serverapplymovingcontactกับบอล ไม่ทำเพียงTweenภาพแล้วใช้planeเดิม
- ตรวจballที่อยู่สูง/กำลังกระโดด/โกล/cornerseamsระหว่างลดและคืนเพดาน ไม่ทับค้าง/ทะลุ/เกิดช่องหนี และไม่ใช้teleportบอลหรือผู้เล่นกลบcontactผิด
- ตอนActiveเป็นสนามเพดานต่ำ ไม่ใช่ตัวคูณความเร็วบอล; เวลาชิ่ง/จังหวะที่เร็วขึ้นต้องวัดตามlaunchจริง ไม่รับรองเร็วขึ้น2เท่าเพียงจากความสูง
- จบ/cancel/switch/resetคืนroofทรงและcollisionเดิมของแต่ละprofile พร้อมล้างtemporarysurfaces/handlers ไม่ทิ้งflatplane12ไว้ร่วมกับroofเดิม
- ค่าเริ่มทดลอง12studs; warning/descent/durationและช่วงจูนความสูงที่ปลอดภัยอยู่config/Debug06 มีvalidationตามrig/goal/solverclearance ไม่ขยายsourceหรือbootstrap00

### Acceptance ของEvent5/6

1. Overdrive: ทุกทีมไม่เสีย/ติดgateStaminaระหว่างActive แต่CD/recovery/contactยังบังคับจริง ไม่เพิ่มspeed/powerโดยแอบเปลี่ยนconfig
2. HUDแสงวิ่ง/สถานะไม่จำกัดตรงServer event ผู้เข้าใหม่/respawnเห็นสถานะถูกต้อง จบแล้วล้างoverrideและUI; จบแล้วStaminaเต็ม100%ก่อนกลับใช้ปกติ CD/recoveryไม่รีเซ็ต Endซ้ำไม่เติมซ้ำและresetscenarioไม่รับcallbackจากgenerationเก่า
3. LowRoof: A/B/Cใต้เพดานเรียบ12จากfloorจริง ชิ่งระหว่างmovingphase/Activeได้และไม่มีbevel/ceilingซ้ำ; ทดสอบบอลสูง/คนกระโดด/goalclearance/seams
4. จบ/cancel/switch/resetคืนgeometryครบprestateและไม่มีtransientcontacts/instancesค้าง ผลเวลาfirst/secondceilingbounceเก็บเป็นmeasurement ไม่ใช่คำรับรอง2เท่า
