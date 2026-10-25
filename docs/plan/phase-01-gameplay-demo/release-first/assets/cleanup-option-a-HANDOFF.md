# RF02-CLEANUP-A — Authorized execution contract

2026-10-25 · Owner Stang · Controller/reviewer Codex · Implementer agyanimation/3.8 Flash (verified w2:p49,tabw2:t3M). Governance OWNER_STANDARD, normal prompt, single writer. Argon idle; use only after an evidenced bounded blocker, not a new full scan.

## Authorization / baseline

Owner explicitly approved OPTION_A_CLEANUP_SCOPE as formulated in review013: remove legacy02/03 runtime and leave free-ball physics only. This contract activates that bounded source cleanup, superseding older docs-only/stop-before-deletion clauses ONLY for this work. R15/new gameplay/Idle/Studio operations/commit/push/merge/publish remain NOT AUTHORIZED. Original Plan00 review status/findings unchanged; narrow modifications of shared bootstrap/R6 hooks below are the approved cleanup exception, not resumption of rig development.

HEAD at Controller preflight `25a67d5575e31034a5a08290873b9c401357d33a`; src/tests clean; docs/agent.md dirty and protected. Read agent.md,docs/READ,RF02 tasks,review013,discovery006,manifest,Argon spot audit and this contract. This contract/Owner A selection supersedes contradictory OptionB/keep-Pass/Curve text in provisional manifest. Follow actual code, not blind deletion by old line ranges.

## Preflight and recovery gate — before source mutation

1. Capture actual status/log/ref and compare34 source fingerprints in discovery006; stop on unexplained source drift. Record own doc before-state; preserve concurrent docs edits.
2. Verify edits cannot be auto-synced/hot-reloaded into Studio. No live sync/Studio mutation authorized; if unable to establish that boundary, push BLOCKED with evidence before source edits. Do not kill unrelated processes or toggle Studio settings silently.
3. Make an exact recoverable copy of files to edit/delete, preserving relative paths and a SHA256 manifest, in a uniquely named directory under `C:/Users/Stang/cage-zero-cleanup-backups/`. Verify resolved paths stay under that explicit directory and repo sources under `C:/Users/Stang/cage-zero/`. No recursive wildcard delete/move, Git reset or alteration of protected .sandbox/rollback. No secrets/env copying. Backup before any edit; no commit authorization.

## Exact source file scope

Delete ONLY these10 dedicated files after incoming wiring is decoupled:
- src/client/character/R6ActionPoseController.luau
- src/server/services/SkillMoveService.luau
- src/shared/configs/PlayerActionPoseConfigs.luau
- src/client/controllers/InputController.luau.bak_fc27
- src/server/services/BallService.luau.bak_fc27
- tests/e2e/Tier1_AirLeanPhysics.luau
- tests/e2e/Tier1_BallPopPhysics.luau
- tests/e2e/Tier1_PlayerActions.luau
- tests/e2e/Tier1_SkillMovesAndDefense.luau
- tests/e2e/Tier1_StateJumpPhysics.luau

Allow MODIFY only these13 shared files for necessary removal/wiring/type/test-registration surgery:
- src/client/character/R6AnimationController.luau
- src/client/controllers/InputController.luau
- src/client/init.client.luau
- src/server/init.server.luau
- src/server/services/BallService.luau
- src/shared/Constants.luau
- src/shared/Network.luau
- src/shared/Types.luau
- src/shared/configs/RigAnimationConfigs.luau
- tests/e2e/BundledTestRunner.luau
- tests/e2e/TestHarness.luau
- tests/e2e/TestRunner.luau
- tests/e2e/run_all.ps1

CameraShiftLockController.luau may receive ONLY minimal decoupling of existing slide/airborne locks if required to retain current camera behavior; document exact necessity. Do not delete/rewrite camera, AirLeanSolver or JumpModel in this immediate pass: isolate unused references and keep these files as inert reference material. No new controllers/modules/gameplay stubs. If additional source files need edits, stop and present exact evidence; do not extend allowlist yourself.

Preserve byte-for-byte seven uncertain files: TrainingHUD,AirLeanConfigs,JumpConfigs,SkillMoveConfigs,DuelUIController,DuelChoiceModal,DuelEngineService. Also preserve CagePhysicsService (including visibility fixes and excluded floor-smash tuning),RigAndCardService,default.project.json, all other source, old docs/assets/animation-library/rollback/history. Inert files may still mention old symbols; distinguish these from active references. Remove shared definitions only when their retained-file type dependencies permit it; preserve existing explicitly deprecated compatibility types when necessary, report them, do not weaken types or fabricate APIs to make checks pass.

## Required resulting behavior

- Existing Module00 R6 rig/locomotion and Cage01 remain; no R15/avatar normalization, Idle authoring, new movement feel, added animations/UI or new ball possession.
- Server free ball only: remove player stamina/actions/possession collection/carrier follow; keep ball creation/reset, normal gravity, existing normal turf friction, cage collision stepping, rolling/part sync. No Pass-special gravity/friction, curveImpulse action integration, old action router/remote handlers or skill dependencies active. Do not change baseline ball radius/speed/normal physics tuning. Dormant API references do not justify keeping active old gameplay.
- Ball never acquires a carrier during this baseline; any retained SetPossessor entrypoint cannot activate possession. Prefer removing unused entrypoint rather than inventing temporary gameplay/no-op API; document API removal impact on inert legacy prototypes and do not bootstrap them.
- Remove action-pose hooks from existing R6 animation code while preserving baseline locomotion. Remove obsolete input/remote connections and restore native jump behavior previously suppressed by removed gameplay; no new input bindings. Uncertain HUD is not initialized.
- Consumer-before-provider edit order, atomic source edit group with no intermediate runtime/sync. Do not claim textual stage order alone proves transformed program correct.

## Verification scope

Implementer may run READ-ONLY static/document checks only in this contract: git diff --check, scope diff/status, hashes, rg exact reference search, syntax/type analysis with an already installed approved tool only after checking it is non-mutating. No installs/generators/application tests/Studio simulation/sync. Do not execute tests/e2e/run_all.ps1 as proof of runtime: inspect it and report its actual capability. Do not delete/relax foundation assertions to fabricate PASS; retained integration tests depending on removed gameplay remain explicit unresolved verification limitations unless covered by approved registration cleanup.

Check exact10 deletion set, no out-of-scope edits, protected fingerprints unchanged, active requires/pcall requires/FindFirstChild loaders, registrations/remotes/type references, helper/callback closure, missing endpoints and stale type consumers. Any syntax/analysis blocker must be reported, not hidden behind successful link checks. Fresh static review is required; no claim of full functional/UAT PASS without runtime evidence.

## Documentation / reporting / finish

Update RF02 tasks/notes cleanup status and add one assets/cleanup-option-a-report-001.md with actual ref,backup location,changed/deleted files,own scope diff summary,exact commands/results,protected/source hashes and remaining risks. Preserve old reports and Codex directives/reviews/HANDOFF. No extra summary artifacts/full diffs.

Push READY_FOR_REVIEW/BLOCKED automatically once per milestone with Enter to verified Codex (last known w2:p43); no monitoring/SEND REPORT wait/retry loops. Codex independently reviews actual diff and delegates in-scope fixes. STOP after cleanup delivery. No new R15/gameplay/Idle or original Plan00 closure. Owner will direct next stage from Idle after separate confirmation. No Git stage/commit/push/merge/deploy/publish authority.
