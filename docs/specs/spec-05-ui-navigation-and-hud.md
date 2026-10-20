# Spec 05 — Gameplay UI, Skill Loadout และหน้าระบบ Phase2

Decision Accepted / Delivery Planned จากQ22 — 2026-10-20; [UI routing](../design/ui-state-and-routing.md) / [Spec02](spec-02-duel-and-parry.md)

## Phase1 / 08-gameplay-ui

- UIManager routerเดียว ใช้HUDของDemo/Trainingและoverlaysของโกล/ลูกนิ่ง/อีเวนต์ ไม่ต้องสร้างวงจรLobby/แมตช์เต็มก่อน
- ปุ่ม3คู่ยิง↔Slide ส่ง↔Poke ยิงโค้งโดยตรง↔Shoulder แสดงตามทีมครองล่าสุดที่Serverยืนยัน ทั้งทีมคงโหมดบุกระหว่างบอลอิสระจนอีกทีมครองสำเร็จ
- Dash/Sprint/DirectionalJumpคงตาม02; Skill3ช่องใช้ปุ่มช่อง+ทิศเริ่มท่า ไม่มีปุ่มFeintแยก
- แสดง3skill slots/ชื่อท่า/ดาว/cooldown/Stamina/commonend/recovery พร้อมเหตุที่ใช้ไม่ได้ แสดง5ท่าฟรีและตัวเริ่มต้นSkillMove5ดาวให้เลือก3ช่องก่อนรอบ/หยุดรีเซ็ตซ้อม
- Ballreach/การเล่นfirst-timeต้องfeedbackอ่านออก ไม่ให้contextlabelหมายถึงยิงได้ทั้งสนามหรือแปลงท่าระหว่างกดค้าง
- มีR6ท่าร่างทั้ง5ที่อ่านได้โดยไม่ล็อกกล้อง/ผู้เล่นอื่น บอลยังสัมผัสได้; แอนิเมชันพร้อมเสียจังหวะเมื่อfirst-timeวืดอยู่Phase2
- Debug06มีค่าdefault/current/apply/restore, Dummycontrolsและscenarioreset; กั้นเฉพาะtestsessionและสิทธิ์ที่เหมาะสม ไม่บันทึกค่าถาวรผ่านDebug
- ไม่มีChoice modal/Parry prompt/ตารางชนะทาง/สโลว์เปิดดวล/คัตซีนล็อกคู่/สตั้นผู้แพ้จากผลดวล

## Phase2 / meta UI

- หน้าทีม/เลือกโหมด3v3หรือ4v4/แมตช์/ผล/โหวต, LockerและSkill Inventory/Loadoutตามดาว, สุ่มตัวละคร/สุ่มสกิล/สุ่มเอฟเฟค, collection/ตลาดและsettingsฉบับใช้งานจริงตามแผนเจ้าของ
- คงNo Boots/Mutationsไม่เพิ่มพลังสนาม และเอฟเฟคไม่มีstats; เงื่อนไขซื้อขายแต่ละประเภทตามscopePhase2ไม่คัด6ช่อง/เรต/pityจากspecเก่ามาเป็นข้อกำหนดใหม่
- รูปแบบscreens/แพลตฟอร์ม/controls/เรต/pity/ราคา/ownership/profileและpersistenceต้องgrillเมื่อเปิดงาน ไม่มีplaceholderPASS
- หน้าเลือกตำแหน่งหรือไอเทมไม่แสดงChoice matrix/Signature Choiceหรือคัตซีนชนะดวลเก่า

## Acceptance

inputlabelกับServercontextตรงกัน loadoutแก้ไม่ได้กลางรอบ cooldown/costไม่ถูกUIหลบ overlay/reset/respawnคืนinputและกล้อง ไม่มีตัวเลขผลการแข่งขัน/เงิน/การสุ่มคำนวณแทนServer และvisualที่ยังไม่ตรวจคงNOT VERIFIED
