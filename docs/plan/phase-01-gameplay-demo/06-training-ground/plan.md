# 06-training-ground — สนามซ้อม หุ่น และเครื่องมือทดสอบ

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [01-cage-physics](../01-cage-physics/plan.md), [02-player-actions](../02-player-actions/plan.md)

## Scope
- ฉากซ้อมสำหรับทดลอง movement/บอล/ท่าเลี้ยงและการแย่งบอล/โกล/ลูกนิ่งและอีเวนต์
- spawn/สั่งหุ่นคู่ซ้อม รีเซ็ตบอลและฉากด้วยเครื่องมือเฉพาะการซ้อม
- ใช้หุ่น/HUD ขั้นต่ำช่วยตรวจแผนก่อนหน้าได้ แล้วเก็บขอบเขตสนามซ้อมครบก่อนปิด phase
- แผง Debug สำหรับปรับค่าจูนการเล่นและจัด Dummy ตามคำสั่งผู้ใช้2026-10-20 รายละเอียดด้านล่างเป็นงานวางแผน ยังไม่อนุมัติimplementation06

## Debug tuning และ Dummy — Phase 1

- ปรับค่าจูนระหว่างทดสอบได้โดยเห็นค่าdefault/currentและคืนค่าเริ่มต้นได้ ไม่ต้องแก้sourceทุกครั้ง
- **การควบคุม 13 Outfield Base Stats (ช่วงสมดุล 0.90–1.15 หรือ −10% ถึง +15%, ค่ากลาง 1.00):**
  - ตัวปรับค่า 13 รายการ: `Speed` (#1), `Jump` (#2), `Shot Power` (#3), `Curve` (#4), `Sliding` (#5), `Strength` (#6), `Dribbling` (#7), `Stamina` (#9), `Pass Velocity` (#16), `Acceleration/Dash` (#27), `Poke Reach` (#30), `Recovery/Reflex` (#32), `Block` (ใหม่)
  - รองรับการปรับและอ่านผลกระทบจริง (Effective Stat Multiplier) โดยค่าอยู่นอกช่วง 0.90–1.15 จะถูก Server ปฏิเสธ (ยกเว้นผลจาก Trait ตามเงื่อนไข)
- **ตัวเลือก Toggle เปิด/ปิด 16 Character Traits สำหรับทดสอบ:**
  - ยิง/ชิ่ง (4): `Whipped Finesse`, `Trivela Master`, `Knuckle Emperor`, `Wall-Breaker`
  - เทคนิค/เคลื่อนที่ (7): `Second Wind` (#10), `Velvet Touch` (#13), `One-Touch Specialist` (#14), `Acrobat / Sky Striker` (#15), `Quick Footwork` (#17), `Lightning Poke` (#18), `Elastic Recovery` (#19)
  - กองหลัง/เกมรับ (5): `Iron Wall Block` (D1), `Bulldozer Impact` (D2), `Clean Sweeper` (D3), `Shadow Chaser` (D5), `Cage Guardian` (D7)
- **ปุ่มสลับ 5 Character Archetype Presets สำเร็จรูป:**
  - สลับระหว่าง `Speedster Striker`, `Cage Playmaker`, `Power Target`, `Iron Stopper`, `Sweeper Destroyer` ได้ทันที พร้อมโหลดชุด Stats 13 ค่าและ Trait ตัวอย่างครบถ้วน (ดูตารางใน [Phase 2 / 03 Plan](../../phase-02-full-match-and-progression/03-player-gacha-and-stats/plan.md) และ [notes N-61](../01-cage-physics/notes.md#n-61--accepted-decision-13-outfield-base-stats-4-deferred-gk-stats-16-innate-traits-5-character-archetypes-and-body-check-target-mechanics-2026-10-24))
- เมื่อระบบ07พร้อม เพิ่มtargetSpeed/เวลาActiveของRebound Rushในกลุ่มค่าจูนที่รองรับ ไม่สร้างeventphysicsใน06แทน07
- เมื่อevent5/6พร้อม เพิ่มtoggleสถานะOverdrive/เวลาActive และLowRoofheight(default12)/warning-descentตามช่วงที่ปลอดภัย ใช้modifierของ07ไม่แก้staminacostหรือgeometrybaseถาวร
- ค่าDebugมีผลเฉพาะtest session มีvalidationและServerเป็นผู้applyค่าที่กระทบเกม; ค่าไม่ถูกต้องต้องrejectพร้อมเหตุผล ไม่เปลี่ยนdefaultของเกมหรือข้อมูลตัวละครถาวรจากแผงนี้
- เสก/เลือก/ย้าย/ลบ/รีเซ็ตDummyเป็นรายตัวและทั้งชุดได้ พร้อมpresetสำหรับซ้อม ตัวอย่างที่เสนอคือยืนนิ่ง วิ่งตามเส้นทาง ครองบอล/รับบอล และตัวบล็อก; โกลใช้ระบบ04เมื่อพร้อม ไม่สร้างAIเต็มระบบเพิ่มจากรายการตัวอย่างนี้
- เปลี่ยนจำนวน/ทีม/จุดเกิดและbehaviorที่รองรับของDummyได้โดยไม่ปิดเปิดStudioใหม่; ใช้R6ตามสัญญา00สำหรับหุ่นที่แทนผู้เล่น มีlimitจำนวนและcleanupเมื่อจบ/รีเซ็ตฉาก
- เตรียมscenarioซ้ำได้จากชุดค่า/preset/ตำแหน่งเริ่มต้นที่ระบุในผลทดสอบ แสดงค่าที่ใช้จริงและแยกจากผลผ่าน/ไม่ผ่านของruntime
- เครื่องมือจูนขั้นต่ำยืมใช้ทดสอบแผนก่อน06ได้ตามdependencyเดิม แต่ไม่ทำแผน00เพิ่ม และไม่ถือว่า06ส่งมอบแล้ว; scenarioที่ระบบเจ้าของยังไม่พร้อมให้ระบุpending
- ระบบตั้งค่าฉบับใช้งานจริงและการบันทึก/จัดการค่าถาวรเก็บไว้ [Phase 2 / 07-meta-ui](../../phase-02-full-match-and-progression/07-meta-ui/plan.md) ตามคำสั่งผู้ใช้ รายละเอียดค่ารวมเกม/ค่ารายผู้เล่นและสิทธิ์จัดการให้grillเมื่อเปิดแผนนั้น

## Acceptance / ก่อนลงมือ
- เริ่มทดสอบ/สลับ scenario/รีเซ็ตแล้ว state ไม่ค้าง
- เครื่องมือ debug ไม่กลายเป็นสิทธิ์ในโหมดแข่งขัน; รูปแบบหุ่นที่ยังไม่ล็อกให้ grill ก่อนทำ
- เปลี่ยนความเร็วพื้นฐานจากแผงแล้วอ่านค่าeffectiveบนServerและทดลองเคลื่อนที่ได้ตรงค่า คืนdefault/จบsessionแล้วไม่มีoverrideค้าง
- spawn/move/สลับpreset/ลบ/resetDummyแล้วไม่สะสมหุ่น, connections, timers หรือเจ้าของบอลเก่า และไม่ลบinstanceที่เป็นของผู้ใช้นอกtestscope
- ค่าที่เกินช่วง/ไม่ใช่ชนิดที่รองรับ/คำสั่งที่ไม่มีสิทธิ์ไม่เปลี่ยนเกม; บันทึกค่าconfig/scenarioที่ใช้กับผลตรวจ ไม่เรียกเพียงการเห็นปุ่มว่าruntimePASS

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน
