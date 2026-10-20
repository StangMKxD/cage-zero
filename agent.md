# PROJECT AGENT STATE & ROUTER

## CURRENT PLANNING STATE

- **ACTIVE_PHASE:** `docs/plan/phase-01-gameplay-demo`
- **ACTIVE_MODULE:** 00-bootstrap-and-rig prerequisite; execution/review tracked separately from this gameplay design commit
- **CURRENT_DESIGN:** Q22 Accepted / Planned — ฟุตบอลต่อเนื่องแทนChoice, 5 Skill Moves/3ช่อง, ตัวเริ่มต้นSkill5ดาว
- **CURRENT_PLAN:** `docs/plan/phase-01-gameplay-demo/plan.md`
- **NEXT_PLAN:** 01-cage-physics implementationรอ00ผ่านgate; 02บอล/movementแล้ว03SkillMoves/เกมรับตามdependency
- **IMPLEMENTATION_APPROVAL:** AUTHORIZED_FOR_00จากคำสั่ง“เริ่มเลย”เดิมเท่านั้น; Q22อนุญาตเอกสารไม่ขยาย00และไม่อนุมัติ01–09/Phase2
- **GAMEPLAY_SPEC:** `docs/specs/spec-02-duel-and-parry.md`
- **ACCEPTED_DECISIONS:** `docs/plan/phase-01-gameplay-demo/01-cage-physics/notes.md` N37–N44
- **PHASE_2:** `docs/plan/phase-02-full-match-and-progression/plan.md`; DeferredจนPhase1ผ่านครบ
- **PLAN_IDENTIFIERS:** ใช้เลขและโฟลเดอร์แผนเดิม พาธ03-dribble-duelเป็นlegacyของSkillMoves/เกมรับ ไม่ใช่Choiceระบบเดิม

## STRICT OPERATING RULES

1. อ่านdocs/READ, แผน/tasks/HANDOFFที่เกี่ยวข้อง และarchitectureก่อนงาน
2. Codexวางแผน/Controller/IndependentReviewer; AGYimplementsหลังOwnerอนุมัติ ไม่ใช้draft/รายงานเก่าข้ามgate
3. Phase1ใช้CustomR6/หน้าอนิเมะ/NoBoots ไม่ใช้avatarหรือanimationpackส่วนตัว Mutationsไม่เพิ่มพลังสนาม
4. Sourceหลักอยู่src/; Studioต้องpreflighttarget/path/hash/currentbeforeและเก็บrollbackครบ .sandboxเป็นignoredreference/evidence
5. Choice/matrix/สโลว์เปิดดวล/คัตซีนล็อกคู่/สตั้นแพ้ดวล/FeintเดิมถูกแทนตามQ22 เก็บDash ไม่มีI-frame; endpoint/sourceเก่าไม่ใช่targetที่อนุมัติทั้งหมด
6. งาน00/source/ผลรีวิวที่ยังค้างเป็นworking treeแยกจากเอกสารรอบนี้ ไม่อ้างว่าผ่านจากการcommitแผน และไม่เปลี่ยนสัญญา00เพื่อเริ่มfeatureใหม่
7. ตัวเลขจูนผ่านDebug06; settingsจริง/persistence/สุ่มตัวละคร–สกิล–เอฟเฟค/ท่าเพิ่ม/first-time miss animation-recoveryอยู่Phase2 ไม่เปิดล่วงหน้า

## CURRENT GIT AUTHORIZATION

Stangสั่งหลังQ22ว่า “ถ้าเสร็จ ไม่มีอะไรค้างแล้ว commit เลย” อนุญาตlocalcommitเอกสารรอบgameplay/architecture/PRD/spec/TDD/phaseplansเมื่อเช็กครบ ไม่รวมsource/ผลรีวิวและไฟล์แผน00/push/merge/deploy ปกป้อง.gitignore/sourcemap/.sandboxและงานค้าง
คำสั่งcommit/pushเก่าเป็นสิทธิ์เฉพาะรอบนั้น ไม่มีการอนุมัติให้AGYcommitเองหรือspawnworkerจากการปรับแผนนี้
