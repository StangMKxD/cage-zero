# Cleanup A — Studio sync & foundation readiness

> **Review016 in-scope clarification:** Approved skill-remote retirement also requires backing up and removing ONLY existing `ReplicatedStorage.CageZeroRemotes.SkillMoveRequest`, `.SkillMoveReplicate`, `.TackleActionRequest` RemoteEvents left in Edit after Source sync. Current7 Sources already match repo. Reverify exact target/classes/mode; preserve other remotes. Bounded local Play may confirm12 canonical remotes and no recreation, then return Edit. No new gameplay/source rewrite/Argon/publish authority.

2026-10-25 · Owner Stang explicitly requests syncing and reporting readiness for new basic-gameplay plan. Controller/reviewer Codex; implementer agyanimation/3.8 Flash w2:p49, normal prompt, single Studio/source writer. Argon unused. This authorizes bounded Studio synchronization and smoke verification of reviewed CleanupA only. No new R15/player-avatar normalization,Idle/locomotion/action authoring,new gameplay,Git mutations or publish. Original Plan00 findings remain unchanged.

## Baseline and target guard

- Read latest agent.md/READ,review015,cleanup-option-a-HANDOFF and current source/fix report. HEAD expected25a67d5575e31034a5a08290873b9c401357d33a + exact reviewed CleanupA source diff + protected docs dirty. Recheck file hashes against fix001; stop on unexplained drift.
- Enumerate connected Studio instances with MCP. Intended target **Cage-Zero PlaceId137721422246269** (historical ID, must verify name AND ID/current DataModel). Do not assume a numeric Place4 handle is identity. No new Studio process/place/session; no ReferenceSandbox112091950831355/AnimationSandbox133472167342841 edits. If target missing/ambiguous, report BLOCKED.
- Inspect current edit/play state; do not overwrite running live/public-server state or another user's active Play session. Establish safe local Edit context before source writes. Preserve Studio's pre-existing unsynced work: read exact target Sources/paths/classes before mutation. If differing from identifiable approved before/after revisions, preserve and report unexpected drift, not overwrite blindly.

## Recovery and exact sync footprint

Capture before-state Sources of every target script and exact instance metadata/path/hash before writes/deletes in a unique directory under C:/Users/Stang/cage-zero-cleanup-backups/ (distinct from original source backup). Recoverable copy of all3 deleted modules required. No new full snapshot of unrelated place, no secrets. Resolve intended paths; do not recurse-delete broad containers. No overwriting existing .sandbox/rollback.

Use default.project.json mapping and verified actual paths; synchronize only7 modified runtime scripts:
- src/client/character/R6AnimationController.luau
- src/client/controllers/InputController.luau
- src/client/init.client.luau
- src/server/init.server.luau
- src/server/services/BallService.luau
- src/shared/Network.luau
- src/shared/configs/RigAnimationConfigs.luau

Remove only the3 exact legacy runtime ModuleScript instances corresponding to R6ActionPoseController,SkillMoveService,PlayerActionPoseConfigs after consumers are updated and before Play. The2 .bak files and5 deleted tests are repository cleanup; do not infer similarly named Studio instances may be deleted. No whole-directory/full-project sync that touches unrelated scripts/tests/assets. Protected RigAndCardService,CagePhysicsService,7uncertain modules,math solvers,rig models,geometry/lighting/assets remain untouched in Edit. No auto-sync watcher left active.

After sync read Sources back and prove equality to repo (or documented line-ending-normalized equality), classes/paths correct, deleted modules absent,protected-neighbor/source fingerprints unchanged. Don't treat a successful write as runtime verification.

## Authorized local smoke verification

Start/stop one bounded local Play/Run through Studio MCP only when preflight is safe; user has authorized this smoke check via sync/readiness request. Capture fresh console window/time so historical errors aren't treated as new. No old full BundledTestRunner which still asserts deleted gameplay; no claiming72tests pass. No keyboard automation outside local test or native Edit dock clicking.

Check actual initialization of Network/CagePhysics/RigAndCard/Ball and client rig/camera/native locomotion where available. Validate cleanup free ball (Free/no possessor; no legacy input/action/skill remotes), current R6 spawn remains, cage floor/colliders present, ball state finite and server stepping/part sync. For rebound, use only a reversible runtime test impulse/position fixture on the existing ball and restore afterwards; this is a physics probe, not new kick/pass mechanics or permanent config tuning. Distinguish observed assertions from visual/feel acceptance. If client presence/input isn't testable, mark it NOT VERIFIED, never mock success.

Stop local Play after verification and restore Edit context; remove only own temporary fixtures without disturbing user content. No saving/publishing or modifying Studio assets/rig/game settings to make tests pass. No R15/Idle preview creation. Preserve verified code state ready for next Owner-led stage.

## Failures and correction authority

In-scope cleanup source bugs may be corrected only in existing CleanupA allowlist, with exact evidence and fresh static review report. Backup changed source and update repo+Studio consistently, reverify affected checks. No touching protected foundational files merely to pass smoke; report blocker for Controller if required. No broad reinstatement of retired APIs/noop fictions, no new controls or extra gameplay. Do not fabricate engine PASS or auto-close findings.

## Report / stop

One assets/cleanup-studio-sync-report-001.md: actualtargetPlaceId/DataModel/mode,repoSHA+sourcehashes,before-backup,exact changed/removed paths,post-sync parity,console/runtime observations,restoration,limitations and READY_FOR_OWNER_IDLE_PLANNING or BLOCKED verdict. UpdateRF02tasks/notes with implementation claims pending independent review. Auto push report to verified Codexw2:p43 with Enter atREADY/BLOCKED; no monitoring/retryloops. STOP after report. Basic gameplay begins only after Owner's next instruction and Owner directs Idle first.
