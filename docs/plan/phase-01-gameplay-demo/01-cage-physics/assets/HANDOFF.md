# 01-cage-physics — Design dependency contract (draft)

- **State:** DRAFT / DEPENDS_ON_00; ยังไม่มอบหมาย implementation
- **Authority:** ผู้ใช้ให้ Codex จบ architecture/ปรับแผน และเลือก R6 ตลอด Phase 1 เมื่อ 2026-10-20
- **Plan:** [plan.md](../plan.md) / [tasks](../tasks.md) / [notes](../notes.md)
- **Baseline:** main @ `2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`
- **Implementation approval:** PENDING และต้องรอ 00 runtime/dependency gate จริง
- **Input จาก 00:** R6 schema, PrimaryPart=HumanoidRootPart, rig lifecycle API และ explicit primary floor/anchor
- **Design owners:** CagePhysicsService เจ้าของ geometry catalog ที่ builder/solver ใช้ร่วมกัน; BallService ใน 02 เจ้าของ ball state/possession
- **Bootstrap delta ในอนาคต:** สร้าง HexCageArena ก่อน Rig.Init, เปลี่ยน primary floor ไป Workspace.HexCageArena.CageFloor โดยไม่เปิด MatchService
- **Current allowed work:** เอกสาร/geometry design ของ 01 ตามคำสั่งวางแผน ไม่เขียน source หรือ Studio จาก contract นี้
- **Future source scope:** CagePhysicsService, config/entrypoint เฉพาะ arena/floor integration และ focused verification ที่ระบุเมื่อจัด implementation contract ไม่แตะ R6 animation/duel/GK/economy เอง
- **Protect:** source/sourcemap/.gitignore/reference sandbox และ historical runs ทุกชุด
- **Deferred:** ball actions, GK, duel/cutscene, full match/economy/Phase 2 ตาม phase plan
- **Git:** Stang อนุญาต local commit เฉพาะเอกสารสนาม/อีเวนต์ที่แยกจาก00 เมื่อ2026-10-20; ไม่รวม source/ผลงาน00 หรือ push/merge/deploy และไม่ใช่ implementation approval
- **Next gate:** ตรวจ geometry contract/verification และ baseline ใหม่ก่อนเสนอ Owner อนุมัติ implementation; ไม่ใช้ผลทดลอง .sandbox/plan1/implementation-attempt เป็น acceptance

ใช้แผนนี้ต่อจาก architecture ได้ ไม่ต้อง grill R6/R15 ซ้ำ และไม่ถือว่า 00/01 ส่งมอบแล้วจากงานเอกสาร


## Map design delta — 2026-10-20
- เปรียบเทียบAกล่อง4ผนัง/Bปาด4มุม8ผนัง/CฐานB+roof bevel45°ตามplan01 ไม่มีwinnerล่วงหน้าและmarkerไม่มีแรงนำบอล
- Scopeเมื่อจัดimplementation contractต้องรวมgeometrycatalog/variantconfig, builder APIกลางBuildCageArenaและcallersที่ได้รับผล, finite wall/roof collision, base rebound5กรณี และtest launch fixtureที่ไม่ใช่BallService gameplay
- root/floor pathจาก00ยังคง Workspace.HexCageArena.CageFloor โดยใช้CageVariantIdบอกshapeจริง ไม่infer6ด้านจากชื่อlegacy
- ทำshape passก่อนแล้วmechanics pass ไม่ทำpillar/ripple/swinging signsแทรก01 งานเหล่านั้นอยู่07
