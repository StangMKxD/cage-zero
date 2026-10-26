> **Latest pane policy (Owner2026-10-26):** create a new AGY pane only for a NEW task or after Owner explicitly passes previous work. Never replace a closed pane to continue unfinished same task without new authorization. Current dribble+momentumjump/airlean stays on its existing acknowledged AGY; Owner first6 visual acceptance distinct from technical findings. Latest task authority is assets/dribble-receive-HANDOFF.md; docs commit allowed, source Git not included.

> **CURRENT TARGET 2026-10-26 — Street Football:** [authoritative Phase1 plan](docs/plan/phase-01-gameplay-demo/release-first/plan.md) supersedes conflicting target/delivery statements below (retained as historical/reference). Phase1: R15/core ball + kick/slide/poke/block/normal body-check, separate CombatHP/stun/I-frame, gauge+ground/air Orbs, **RF04 walls BEFORE six Supers**, one-use timed armed Super/manual aim/no homing/no guaranteed goal, capped gauge-rate-only per-copy earnedCash upgrade,2v2/tiedGoldenGoal. Remove foul/free kick/cards/penalties/regular overtime/SuperMastery power scaling. Extra dribble skills/gacha/13stats/Traits/advanced aerial hold+guides/shops deferredPhase2; walls remainPhase1. Owner approved docs commit and checklist7 dribble/receive plus later explicit high momentumjump/four-way airlean and relevant locomotion fixes now; no blanket source implementation/commit/push/publish authority. Owner first6 visual accepted; technical review remains separate. Historical code/reviews/findings not erased.

# PROJECT AGENT STATE & ROUTER

> **Current pre-Idle checkpoint — 2026-10-25:** CleanupA + ROBLOX Boy R15/player appearance/+30% owner-accepted height/smaller ball/lifecycle reviewed in [review019](docs/plan/phase-01-gameplay-demo/release-first/assets/review-019.md). Owner authorizes Codex local checkpoint commit; no push. Sources frozen; no new Idle or camera implementation in this snapshot. Later camera-off/Idle work requires its bounded assignment and one Studio writer. Historical approval/paused findings below retain their own scope.

> **LATEST OWNER AUTHORIZATION — 2026-10-25 Cleanup A:** agyanimation/3.8 Flash may execute ONLY the bounded source cleanup in [cleanup-option-a-HANDOFF](docs/plan/phase-01-gameplay-demo/release-first/assets/cleanup-option-a-HANDOFF.md), tracked in RF02/tasks CA01–04. Supersedes docs-only/deletion stop below only for that allowlist. Existing rig/cage preserved, free ball only. No R15/new gameplay/Idle/Studio/app tests/Git mutations; original rig review findings unchanged. Auto push reports, no monitoring.

## LATEST DISPATCH — 2026-10-25 (OWNER TARGET DELTA: PLAYER AVATAR R15 EQUAL SIZE)
- **Owner R15 Target Delta ([owner-r15-restart.md](docs/plan/phase-01-gameplay-demo/release-first/assets/owner-r15-restart.md)):** Owner สั่งการล่าสุดให้ใช้ **Player Avatar R15 (Normalized to Same Body Dimensions)** โดยผู้เล่นใช้โมเดล Avatar ของตนเองแต่ถูก Normalized มิติและสัดส่วนร่างกายให้มีขนาดเท่ากันทั้งหมด แทนที่ game-owned Custom Blocky R15 เดิม; รักษาอัตลักษณ์และรูปลักษณ์ผู้เล่นภายใต้กรอบกายภาพที่ได้มาตรฐานเดียวกัน
- **Normalization & Body Dimensions Seam:** ตัวเลข Scale numbers เท่ากันไม่รับประกันขนาดจริงของ arbitrary body packages; บันทึก seam ของ Body package normalization, Contact/Collision hitbox, Joint attachments, Animation retargeting, Respawn lifecycle, Accessory occlusion, และ Team readability; สถิติตัวละคร/การ์ดไม่เปลี่ยนขนาดร่างกายตาม target ใหม่นี้
- **Owner Aerial-Control Design Delta ([aerial-control-owner-decisions.md](docs/plan/phase-01-gameplay-demo/release-first/assets/aerial-control-owner-decisions.md)):** ข้อยุติการออกแบบระบบช่วยรับบอลกลางอากาศและวิถีลูกบอล: (1) Contact-and-speed-gated aerial reception (ยกเว้นข้อห้าม auto-catch สำหรับการชนจริงที่ relative speed ไม่เกินเกณฑ์ ไม่มีการวาร์ปบอล); (2) Brief airborne hold to aim (ลอยค้างเล็งชั่วครู่ บอลยังแย่งได้ ไม่มี I-frame); (3) Live trajectory + landing marker (ทุกคนเห็นเส้นวิถีบอลลอยฟ้าและการชิ่งผนัง/เพดาน พร้อม aim preview สำหรับคนยิง); (4) Physical goalkeeper contact (เซฟได้จากการสัมผัสบอลจริงเท่านั้น ไม่มีการเซฟอัตโนมัติจากการพุ่งถูกทาง และไม่เพิ่ม GK AI ใน launch)
- **Owner Removal Delta ([legacy-plan02-removal.md](docs/plan/phase-01-gameplay-demo/release-first/assets/legacy-plan02-removal.md)):** เจ้าของสั่งถอด runtime/animation/gameplay ที่สร้างตั้งแต่ Plan 02 ออกจริงสำหรับ R15 restart; กำหนดให้ RF-02 มี preflight cleanup และ removal manifest gate (KEEP/REMOVE/REPLACE/UNCERTAIN) อิง Git baseline `617f523`; รักษา Plan 00/01 foundation (BallService/CagePhysics/rig bootstrap) และ historical assets/reviews ไม่ลบเหมารวม
- **Documentation Ownership:** Codex จัดการ cancellation banners บน legacy 02/03 ทั้ง 6 ไฟล์ และสร้าง `release-first/assets/owner-r15-restart.md` + `legacy-plan02-removal.md`; agyplan (Implementer) จัดทำ Release-First Track (`RF-02`..`RF-07`) และ sync global pointers ตาม primary HANDOFF
- **Model Policy for Downstream:** ผู้ลงมือถอดโค้ดจริงในลำดับถัดไปคือ `agyanimation` ใช้ **3.8 Flash** เป็นหลักเมื่อ verify ชื่อ pane แล้ว; ใช้ **Argon** เฉพาะจุดติดขัดที่มีหลักฐาน; ตอนนี้ยัง docs-only ห้ามถอด source/Studio/Git
- **Rules & Bounds:** ห้ามแก้ไข 6 ไฟล์ legacy 02/03 และห้ามแก้ไฟล์ assets/directives ของ Codex; RF02/RF03 เป็นแผนใหม่ ไม่ใช่ continuation/refactor ของ R6; เก็บ source/assets/reviews เดิมและ unresolved findings (A-01..A-06, F-13..F-24) ไว้เป็นประวัติศาสตร์ ไม่นับเป็นผ่าน
- **Communication & Authority:** ตาม Latest Owner Reporting Override (2026-10-25) AGY ส่ง push callback อัตโนมัติเมื่อ READY_FOR_REVIEW / BLOCKED / ต้องการ Owner decision พร้อมกด Enter ไปยัง verified Codex Controller (last known w2:p43) ไม่ต้องรอ Owner ตรวจหรือ SEND REPORT อีก; Controller ไม่ monitoring/poll/waitloop; ส่ง 1 รายงานต่อ milestone ไม่วน retry/ping-pong; ไม่อนุญาตให้แก้ไขโค้ด/Studio/ทดสอบแอป/Git commit/push/merge/deploy ใด ๆ ในรอบนี้ (Documentation Only)

## HISTORICAL DISPATCH — 2026-10-24
- **Latest confirmed design:** Owner confirmed five-skill choreography after grilling; primary HANDOFF§Q and assets/designs/skill-animation-rework-20261024.md authorize scoped new revisions/prototype coupling, pending Owner per-skill visual review. Supersedes§P hold only; no auto-promotion/Git/closure. Push reports§O, no polling.
- **Latest communication override:** Owner stops Codex monitoring; agycage continues approved work and PUSH-reports READY_FOR_REVIEW/BLOCKED/new Owner action to verified Codex **w2:p43**, per primary HANDOFF§O. Supersedes monitor-only/no-callback text below; no approval/closure authority.
- **Latest Owner override:** other pane closed; **agycage w2:p48 sole writer**, priority connect Motion Tools to **Cage-Zero137721422246269** per primary HANDOFF§M, then §L main work. Supersedes parallel/Sandbox-only ownership below; preserve both panes' partial artifacts. Monitor only agycage. No Git/publish/closure authority.
- Owner resumes missing-animation/main Plan02/03 continuation in **agycage w2:p48**; normal prompt, single source/shared-board writer. Follow primary `03-dribble-duel/assets/HANDOFF.md` **§L**, current tasks and Plan02§21–22. Current HEADc7542258b93b613e0260e43035761cbce87928cd+dirty; historical baseline/pause text below is superseded ONLY for this scoped dispatch.
- **agycagezero w2:p3X** continues ONLY §K AnimationSandbox133472167342841 preview; owns that session/editor and single animation-library.json, not source/shared boards. Main writer authors new drafts/delta separately; coordinated import barrier, no duplicate session/server/writers. **Codex monitors only agycage**, per Owner. Plan00/01/04/GK/Phase2/Bridge remain paused; no Git/publish/approval/closure authority.

## CURRENT EXECUTION STATE
- **ACTIVE_PHASE**: `docs/plan/phase-01-gameplay-demo/release-first` (Release-First Track)
- **ACTIVE_MODULE**: `RF-02` (Core Football & R15 Foundation) — `PROPOSED / DOCUMENTATION_SYNCED`
- **LEGACY_MODULE_STATUS**: `02-player-actions` & `03-dribble-duel` — `CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART`; `00-bootstrap-and-rig` — `OPEN / PAUSED_BY_OWNER`; `01-cage-physics` — `OPEN / PENDING_TECHNICAL_REVIEW` (**ยังไม่ปิดแผน 00 และ 01** ตามคำสั่ง Owner; รอ technical check ภายหลัง)
- **CONTROLLER**: `Codex`; **IMPLEMENTER**: `agyplan w2:p49` (Reviewer อิสระคือ Codex; Implementer คือ AGY Teamwork-preview / agyplan ตามกติกาโปรเจกต์)
- **CURRENT_BASELINE**: `main` @ `617f523bb2529a2ec40bfb1107de5f6a32a208ae` + dirty working tree ตาม source lock ใน HANDOFF
- **CURRENT_PLAN**: `docs/plan/phase-01-gameplay-demo/release-first/plan.md` & `RF-02/plan.md`
- **CURRENT_CONTRACT**: `docs/plan/phase-01-gameplay-demo/release-first/assets/HANDOFF.md` & `owner-r15-restart.md`
- **TARGET_RIG**: `Player Avatar R15 (Normalized to Same Body Dimensions)` (แทนที่ Custom Blocky R15 ตาม Owner Target Delta 2026-10-25; รักษาอัตลักษณ์ผู้เล่นแต่บังคับขนาดมิติร่างกายเท่ากันทั้งหมด; R6 เดิมคงไว้เป็นประวัติศาสตร์)
- **PHASE_PLAN**: `docs/plan/phase-01-gameplay-demo/plan.md` (เพิ่ม mapping เข้า Release-First Track)
- **PHASE_2**: `docs/plan/phase-02-full-match-and-progression/plan.md` — ยังเลื่อน ไม่ได้ยกเลิกทั้ง Phase; ส่วน Profile/Cash Gacha ดึงมาเริ่มใน Release-First
- **ACCEPTED_FEATURE_DECISIONS**: `docs/plan/phase-01-gameplay-demo/01-cage-physics/notes.md`
- **GAMEPLAY_DESIGN**: Q22 ยืนยันฟุตบอลต่อเนื่อง/Skill 3 ช่อง/Cage Slingshot; ดู Spec02 และ N37–N44
- **PLAN_IDENTIFIERS**: ใช้ชื่อ phase/โฟลเดอร์แผนโดยตรง (เช่น `release-first/RF-02`) ไม่เพิ่มรหัส feature แยก

## STRICT OPERATING RULES
1. อ่าน `docs/READ.md`, active plan/HANDOFF และ architecture ก่อนเริ่มงาน
2. agyplan ทำหน้าที่ Implementer (Docs) และ Codex ทำหน้าที่ Controller ตรวจสอบอิสระ; คงมาตรฐานการตรวจสอบหลักฐานจริง (Static / Edit Scene / Live Play Runtime / Rollback Manifest) และไม่ปิดงานเองโดยพลการ
3. แผน `00-bootstrap-and-rig` คงสถานะ `OPEN / PAUSED_BY_OWNER` (ยังไม่ปิดแผน 00); แผน `01-cage-physics` คงสถานะ `OPEN / PENDING_TECHNICAL_REVIEW` บอลฟิสิกส์คงค่าเดิม
4. Target Rig ของ Release-First คือ Player Avatar R15 ที่ถูก Normalize มิติร่างกายให้มีขนาดเท่ากันทั้งหมด (ขนาดร่างกายไม่เปลี่ยนตาม Stats/Cards; รักษารูปลักษณ์ผู้เล่นแต่บังคับขนาด Collision/Contact geometry เดียวกัน); ไม่มีรองเท้าสตั๊ด และ Mutations ไม่เพิ่มพลังสนาม
5. source หลักอยู่ `src/`; รอบนี้อนุญาต **จัดทำ/ปรับปรุงเอกสารเท่านั้น** ห้ามแก้โค้ด/Studio/ทดสอบแอป/Git commit/push/merge/publish
6. ห้ามแก้ไข 6 ไฟล์ legacy 02/03 (`plan/tasks/notes`) และห้ามแก้ `owner-r15-restart.md` ที่ Codex ถือสิทธิ์
7. Controller ไม่ monitoring/poll; Implementer ส่ง push callback อัตโนมัติเมื่อ READY_FOR_REVIEW / BLOCKED / ต้องการ Owner decision ไปยัง Controller w2:p43 พร้อม Enter (1 รายงานต่อ milestone, ไม่ retry loop/ping-pong); หากไม่พบ pane ปลายทางให้เก็บรายงานไว้ใน repo และแจ้ง delivery blocker

## CURRENT GIT AUTHORIZATION
- Baselineปัจจุบันmain617f523+workingtree ตามreview-002/source lock; ไม่มีสิทธิ์commitใหม่ใน02
- ห้าม push, merge, deploy หรือลบ branch โดยไม่มีคำสั่งชัดเจนจาก Owner
- ปกป้อง `.gitignore`, `src/`, `sourcemap.json`, Reference Sandbox (`112091950831355`) และ `.sandbox/rollback/` ทุกชุด

## LATEST OWNER SCOPE — 2026-10-21
- ต่อจากรายงานAGYfix-001 ดึง sprint/dash/kick/pass/curve+เกจจากprototype3 เว้นท่าโยก ตัดLobPassแยก ดึงSlideก่อน Poke/Shoulderภายหลังใน03; selectedUIมา02ก่อนfullUI08ตามคำสั่งนี้
- CodexControllerจัดแผน/HANDOFFและreview; AGYลงมือเฉพาะallowlist§6 ไม่แก้Sandbox/reference/rig00/physics01 และไม่เปลี่ยนreview/fixhistoricalเป็นผลผ่านใหม่
- ผลAGY34/34/160assertions,141/141/445assertionsและLivePlayยังรอCodexre-review; ต้องfreshหลังport F-10..F-19ยังไม่ปิดจากclaimsImplementer
- localcommit01ที่Ownerสั่งเสร็จแล้วคือ617f523 ไม่ได้อนุญาตcommit02/เพิ่มcommit/push/merge/deployหรือปิดแผน

## OWNER VISUAL DIRECTIVE / REVIEW-002 — 2026-10-21
- Animationยังไม่ผ่าน ใช้proceduralposeและค่าต่างๆจากSandboxเป็นฐานadaptR6 ไม่เปลี่ยนชื่อjumpclipเป็นSlide ใช้ShiftLockแบบSandboxL/Alt/shoulder/menu/focusตามHANDOFF§7 แล้วจูนใน02
- F-13..18/F-20..24ยังOPEN ผล40/40Editและsourceparityไม่แทนLivePlay/poseผ่าน; เอฟเฟกต์เต็ม07/08/Phase2รอแผนเจ้าของได้ ส่งfix-003manual ไม่commit/push/merge/deployหรือปิดงานเอง
