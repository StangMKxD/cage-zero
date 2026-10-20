# Cage Zero — จุดเริ่มอ่านเอกสาร

- กติกา/บทบาท: [agent.md](../agent.md)
- [Roadmap](plan/roadmap.md), [Phase1](plan/phase-01-gameplay-demo/plan.md), [Phase2](plan/phase-02-full-match-and-progression/plan.md); implementationของแผนใหม่ยังPENDING
- Q22ยืนยันฟุตบอลต่อเนื่องแทนChoice เมื่อ2026-10-20: [Spec02](specs/spec-02-duel-and-parry.md), [PRD](prd/product-requirements.md), [accepted decisions N37–N44](plan/phase-01-gameplay-demo/01-cage-physics/notes.md)
- เริ่มจาก [00 Bootstrap/R6](plan/phase-01-gameplay-demo/00-bootstrap-and-rig/plan.md) และgateของ00ก่อน [01สนามA/B/C](plan/phase-01-gameplay-demo/01-cage-physics/plan.md); source/ผลรีวิว00ที่ยังค้างไม่รวมในเอกสารcommitรอบgameplayนี้
- [02บอล/movement/Dash/team inputs/first-time](plan/phase-01-gameplay-demo/02-player-actions/plan.md) → [03SkillMoves5ท่า/3ช่อง/เกมรับ](plan/phase-01-gameplay-demo/03-dribble-duel/plan.md); พาธ03/spec02เดิมเป็นlegacy ไม่อนุญาตChoice Duelกลับมา
- [06 Debug/Dummy](plan/phase-01-gameplay-demo/06-training-ground/plan.md) จูนเช่นความเร็วพื้นฐานเฉพาะtestsessionได้; [Phase2/07settingsจริง](plan/phase-02-full-match-and-progression/07-meta-ui/plan.md) ดูแลระบบตั้งค่า/persistenceเมื่อเปิดแผน
- Phase2ต้องมี [สุ่มตัวละคร03](plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/plan.md), [สุ่มสกิล/SkillInventory04](plan/phase-02-full-match-and-progression/04-collection-and-economy/plan.md), [สุ่มเอฟเฟค05](plan/phase-02-full-match-and-progression/05-effect-gacha/plan.md) และfirst-time animation/miss recoveryตามextension queue
- [Architecture](design/architecture-and-network.md#6-continuous-football--q22), [R6contract](design/architecture-and-network.md#5-phase-1-runtime--custom-r6), [UI routing](design/ui-state-and-routing.md), [TDD](tdd/master-test-cases.md)
- Sourceหลักsrc/; .sandboxเป็นignoredreference/evidence snapshotและรายงานเก่าไม่ใช่ผลผ่านของระบบใหม่ ต้องอ้างcurrentref/hash/ผลruntimeจริง
- Stangอนุญาตlocalcommitเอกสารรอบนี้เมื่อครบ ไม่รวมsource/ผลรีวิว00/push/merge/deployหรือimplementationfeatureใหม่
