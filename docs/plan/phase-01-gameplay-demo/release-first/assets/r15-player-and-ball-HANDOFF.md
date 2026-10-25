# RF02-R15-BASE — Player Avatar R15 & slightly smaller ball

> **Owner visual acceptance — 2026-10-25:** Stang confirms current height is accepted: ความสูงผ่านแล้ว ประมาณนี้แหละ. Lock the displayed ROBLOX Boy height baseline (~6.708 studs,HeightScale1.391,HeadScale1.0,unchanged width/depth). Do not retune size during lifecycle fixes or Idle drafting. This accepts height/size only; remaining lifecycle review,local-commit gate and custom Idle approval are separate.

## Latest Owner size adjustment — roughly30% taller

Owner says current character is too short; increase the common standard height about30% from the current ROBLOX Boy baseline. Apply to everyone, not just Stang. Interpret as taller body, keeping width/depth and ball preview unchanged unless an unavoidable appearance constraint is reported. Keep own face/skin/clothes/hair/accessories and the ROBLOX Boy body package.

Snapshot config at assignment: HeightScale1.0,declared body height5.158/width3.459/depth1.365,root2,2,1,hipHeight2.0. These declared measurements are a baseline to verify, not proof of a measured current pose. Target approx1.30× actual neutral-standing body height excluding accessories (declared baseline would imply approx6.71studs). Do not claim30% physical growth just because a scale property equals1.3. Measure neutral before/after with same method; report actual ratio and compatibility limits. Keep head appearance/proportions visually sensible; no custom Idle or new animation authoring.

Narrow source scope remains R15AvatarConfigs/R15AvatarService for size,derived grounding/spawn clearance; only necessary camera readiness adaptation within prior InputController/bootstrap allowlist if actual evidence requires it. Do not leave hardcoded hipHeight/spawn offsets calibrated for shorter body if they cause floor penetration or floating. Derive/validate support height from actual new geometry,avoid arbitrary movement/jump/physics tuning. Preserve all ball radius1.125/diameter2.25 and ball forces/speeds.

Finish existing body-package sync safely,then apply height change with before-source/Studio backups and exact parity. Test actual Stang R15 appearance,feet/floor grounding,camera framing,one respawn,preserved ball/rebound and same common size on a representative second avatar description. Return Edit,clean only own fixtures. One assets/roblox-boy-height-report-001.md with old/new measured dimensions/ratio,source hashes,sync/readiness evidence and limitations. Auto push report; Flash single writer,Argonunused,no Git/publish/new gameplay/customIdle. Stop for Owner visual acceptance.

## Latest Owner body choice — ROBLOX Boy

Owner first considered Roblox2.0, then explicitly chose **ROBLOX Boy** instead. Use the same verified ROBLOX Boy body package for every player's R15; keep their own compatible face/skin/clothing/hair/hat/accessories. This supersedes preserving arbitrary personal body-part packages in the earlier contract. No Roblox2.0 implementation is authorized or needed. Official reference: https://www.roblox.com/bundles/109/ROBLOX-Boy (bundle identity; resolve actual body-part asset IDs from current official metadata, never use bundle109 as a limb asset ID or guess IDs).

Bounded follow-up source scope: R15AvatarConfigs and R15AvatarService for canonical body selection, measured uniform dimensions and safe avatar lifecycle; no other source changes unless evidenced necessary and reported. Use same common scales and body-part IDs; body dimensions excluding accessories must actually match across two descriptions originally using different packages. Equal root size or equal scale numbers alone is insufficient. Preserve player's own appearance fields rather than applying the bundle's whole outfit/default face/colors. Head/body compatibility conflicts must be disclosed, not silently replace personal appearance.

Fix the existing service's identity failure path while doing this: currently failed user-description fetch falls back to an empty HumanoidDescription and proceeds into gameplay. This contradicts the already approved identity/readiness contract. On failure keep a bounded non-gameplay/loading state or preserve last validated avatar; report failure/retry without blank-avatar gameplay. Validate current generation, Humanoid,R15/body/attachments/dimensions before replacing the previous valid character or granting gameplay. No new gameplay systems or UI screens required.

Back up before mutations; verify exact Cage-Zero and Edit mode; narrow sync of changed2 modules, bounded local Play/respawn/appearance/dimension checks, return Edit. Ball remains radius1.125/diameter2.25; do not retune or resync ball unnecessarily. Native baseline animations only, no custom Idle authoring. Produce one assets/roblox-boy-report-001.md with actual bundle/part provenance,source hashes,appearance preservation,measured size equality and failure/respawn evidence. Push milestone report automatically; stop for Owner visual/Idle direction. Flash single writer, Argon unused.

2026-10-25 · Owner Stang · Controller/reviewer Codex · Implementer agyanimation/3.8 Flash w2:p49. OWNER_STANDARD, normal prompt, single source/Studio writer. Argon not assigned; only an evidenced narrow blocker may justify bounded help.

## Authority / baseline

Owner: เปลี่ยนเป็น R15 ใช้ตัวละครของผมเอง และบอลเล็กลงนิดนึง. This authorizes the narrow R15/avatar foundation migration and ball-size adjustment, including necessary source/Studio sync and bounded local tests. Supersedes old no-R15/protected-Rig restriction only for this task's allowlist. Does NOT authorize custom Idle/locomotion/skill animation authoring,ball possession/shoot/pass/wall gameplay,economy,Git/publish or original Plan00 closure.

Expected HEAD25a67d5575e31034a5a08290873b9c401357d33a + independently reviewed CleanupA source dirty + protected docs dirty. Read latest agent.md/READ,RF02tasks,review015/017,avatar Owner directive and this contract. Verify actual repo/source hashes and current Cage-Zero identity137721422246269; do not reset dirty work. Finish current sync-correction report before new source writes.

Ball interpretation disclosed to Owner: preview radius10% smaller,1.25 ->1.125 studs (diameter2.5 ->2.25), tunable after visual inspection. Preserve all movement/ball speed,force,gravity,normal friction/restitution settings. This is a preview default under the request, not a balance-approved number.

## Before edits

Capture current source/Studio before-state and recoverable hashes in a new unique backup directory under C:/Users/Stang/cage-zero-cleanup-backups/. Verify paths/classes and exact target Edit state, preserve unidentified unsynced changes. No overwriting previous backups or .sandbox/rollback. No whole-project sync/unrelated assets. Studio Play must be stopped safely before source sync; restore Edit after tests. No persistent plugin/watcher left active.

## Allowed source changes

- src/server/init.server.luau — route active spawn/bootstrap to R15 avatar service; old R6 auto-respawn service must not run concurrently.
- src/client/init.client.luau — route to R15 baseline/native animation lifecycle; old R6 controller must not compete.
- src/shared/Constants.luau — only active target flags if required and BALL_RADIUS/BALL_SPAWN_POSITION derived clearance; keep old constants required by inert historical consumers.
- src/server/services/BallService.luau — radius-consistent owned ball sizing for existing/new ball and spawn/reset clearance; no new gameplay/action logic.
- src/client/controllers/InputController.luau — only necessary spawn/native movement readiness compatibility; no new bindings or movement tuning.
- NEW src/server/services/R15AvatarService.luau
- NEW src/shared/configs/R15AvatarConfigs.luau if needed for canonical normalization parameters
- NEW src/client/character/R15AnimationController.luau only if required for standard baseline R15 animation lifecycle; not custom sports poses/Idle design.

Default approach: keep RigAndCardService/R6AnimationController/R6 configs and template as inert recoverable references, switching active bootstraps instead of rewriting/deleting them. No edit of CagePhysicsService,CardConfigs,Network,Types,old models/animation library/test suites. If a necessary seam falls outside this list, report evidence before expanding. Source tests for genuinely necessary lifecycle/normalization checks require a bounded additional file proposal, not a whole suite rewrite.

Docs allowed: RF02plan/tasks/notes,agent.md/READ active pointers,one assets/r15-player-and-ball-report-001.md; preserve Codex contracts/reviews/historical reports. No changed phase scope.

## Required resulting behavior

1. **Actual player's appearance:** Load each Player's own description by UserId (including Stang in Studio), make R15 regardless of previous R6 mode. Preserve identity,face/skin/hair/clothes/accessories where compatible. No game-owned anime face,hardcoded fictional card character or silent blocky-body substitution. Do not hardcode Stang'sUserId for all players.
2. **Same dimensions:** Cards/stats do not alter body size. Normalize gameplay body/contact geometry and compare measured body dimensions excluding accessories; setting equal description scale numbers alone is not proof. Keep appearance/accessory extents distinct from gameplay body. Choose reversible implementation settings, document canonical dimensions and actual evidence. Unsupported packages remain loading/non-gameplay or blocked with explicit reason; no silent unequal-body fallback. Do not promise arbitrary package equivalence without measured support. If preserving Owner appearance and equal geometry conflict, report exact conflict instead of silently stripping body packages.
3. **Safe lifecycle:** One authoritative spawn path,already-present players and rejoin/respawn supported; generation checks after yields,old callback cleanup,one character/Animator,valid HumanoidRootPart/attachments,proper floor clearance and camera subject. Native R15 baseline animations acceptable temporarily, not Owner's custom Idle sign-off. Old R6 clips are not retargeted by renaming. No forced old charge/slide states/jump suppression.
4. **Ball consistent:** Radius1.125 used for rendered size and actual collision solver input,existing owned ball updated too,resting center/spawn height clears floor. Existing CagePhysics reads Constants on fresh initialization; do not patch arena geometry to compensate. Ball remains Free with no possession/collection; velocities/physics coefficients unchanged. Keep all12 canonical remotes, no retired3 recreated.

## Verification / sync / readiness

- Verify current official APIs, not remembered names. Primary references: https://create.roblox.com/docs/reference/engine/classes/Players and https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription. CreateHumanoidModelFromDescriptionAsync accepts explicit R15; choose a lifecycle mechanism based on actual documented API and demonstrate it. No unsupported compatibility claims.
- Static scope/whitespace/reference checks; protected fingerprints. Sync only changed/new source instances and specifically owned ball size state to verified Cage-Zero. Source readback parity and recoverable Edit metadata required. No publishing/game settings changes unless explicitly necessary and proposed first.
- Bounded local Play: actual Stang player R15,appearance matches input description,one spawn/Animator,finite character/floor/camera,ball diameter2.25 and rest/spawn clearance,free state and reversible wall/floor rebound. Test respawn once; stale R6 service does not replace it. Compare own-avatar dimensions against a representative differently proportioned R15 package using temporary fixtures outside active gameplay, then clean fixtures; if no valid equal-size proof mark that requirement unresolved.
- Observe client baseline Idle/movement only for loading/sanity; don't create or iterate new poses. Record screenshots if conveniently available, but no mandatory screenshot gate or fabricated visual acceptance. Owner will judge own-avatar look/ball size and then direct Idle.
- Capture fresh console errors/warnings separately,restore test ball and stopPlay/returnEdit. In-scope source fixes allowed with fresh evidence; don't add old gameplay no-ops to hide errors. No blind full legacy BundledTestRunner.

## Report / stop

One report actualtarget/ref/ownsourcehashes/backup/appearance evidence/measured sizes/respawn/ball/parity/runtime observations/limits. Update RF02status as implementer claim pending Codex. PushREADY/BLOCKED automatically withEntertoverifiedCodexw2:p43,no monitoring or retry loops. STOP after R15+ball delivery. Do not start custom Idle or basic football until Owner next direction. No Git stage/commit/push/merge/deploy/publish.
