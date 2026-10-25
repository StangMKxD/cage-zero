# Legacy animation removal — Review021 / locked execution scope

2026-10-25 · Codex · **VERIFIED INVENTORY / BOUNDED REMOVAL ASSIGNED** under Owner request to delete old animations. No new animation/gameplay or blanket asset deletion authority.
Ref HEAD9fbce58eb90ed6b7e6a39b00a5744455ee639811 + protected Argon/root doc work. Manifest SHA256 `e94e0ee821946be6d2bfb982ad5f2171081231ca5f55d3360801529e06ca63af`.

## Independent evidence

All6 repo file hashes match manifest. rg source/test inspection finds no active R6AnimationController loader; RigAnimationConfigs consumed only by the retired controller. Historical references are not active imports. Original statement zeroTestRunner references is imprecise because the maintained repo test runner exists; it is not the orphan root Studio copy and must not be deleted here.

Read-only Studio Edit inspection on Cage-Zero137721422246269 confirms all6 proposed scene objects/classes/Source sizes and R6_Rig Humanoid R6 with9default Animation descendants. Current R15 Height30 preview is present and R15. No scene mutation or tests by Controller.

## Narrowed approved allowlist —10 targets

**Delete exact6 repo files R01–R06 in manifest, only if current pre-hashes match:**
1. src/client/character/R6AnimationController.luau
2. src/shared/configs/RigAnimationConfigs.luau
3. docs/plan/phase-01-gameplay-demo/02-player-actions/assets/designs/argon-r6-pack/R6FootballPoseData.luau
4. docs/plan/phase-01-gameplay-demo/02-player-actions/assets/designs/argon-r6-pack/R6FootballPosePlayer.luau
5. docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/animation-library.json
6. docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/animation-library.delta-agycage.json

**Delete exact4 Studio targets after before-backup and Argon release:**
1. StarterPlayer.StarterPlayerScripts.Client.character.R6AnimationController (ModuleScript)
2. ReplicatedStorage.Shared.configs.RigAnimationConfigs (ModuleScript)
3. ReplicatedStorage.PlayerActionPoseConfigs (orphan old pose ModuleScript)
4. ServerStorage.MotionToolsRigs.R6_Rig.Animate (LocalScript plus its exact9 defaultR6 Animation descendants/own config values)

Do NOT delete entire R6_Rig Model: preserve ordinary rig body/Humanoid/Animator. Do NOT delete ReplicatedStorage.Tier1_PlayerActions or ReplicatedStorage.TestRunner: these are non-animation orphan test infrastructure,excluded from this task. Maintained repo tests/e2e/TestRunner untouched. U01 historical design doc and U02spec/23PNGs preserved as reference; no further Owner question needed to follow history preservation.

## Execution contract (Flash only)

1. Wait explicit Argon STUDIO_RELEASED and confirmation it is not currently loading either oldR6JSON library; no polling. Until then prepare read-only/backup only, no library or Studio mutation. Argon still owns newIdle preview; do not interrupt it.
2. Recheck HEAD/status/hash,target PlaceId/Edit and each exact class/path. Capture recoverable6 file copies with hashes and full Source/subtree metadata for4scene targets in a unique backup under C:/Users/Stang/cage-zero-cleanup-backups/. For Animate subtree includeSource,9Animation IDs and config value structure; if backup cannot reconstruct,stop rather than deleting. No published asset deletion or .sandbox/rollback changes.
3. Delete ONLY exact listed files/scene targets. Verify all resolved filesystem paths under repo,no wildcard/recursive parent directory deletion. Remove no unrelated source code; no edits to active client bootstraps except historical comment cleanup if actually necessary and documented. Prefer leaving inert comments/history over expanding source scope.
4. Protect all R15 services/configs,ball/arena,CameraShiftLock inert source,current R15 preview and assets/animations/idle-r15. Do not touch global Motion libraries/other places/new Animations. Preserve stable R15 instance/clip metadata; preview's natural playing transforms are not cleanup changes.
5. Static active-reference/scope/whitespace checks,protected source hashes and exactscene absence. Only a short authorized local foundation smoke after preview safely released if necessary;no full old test suite,no new gameplay/Idle integration. RestoreEdit and remove only own temporary probe. Do not interpret this as permission to stop Owner'sPlay.
6. One assets/legacy-animation-removal-report-001.md with deletion set,before-backup,pre/post checks,source hashes,safeMode/release evidence and limitations. Update RF02notes/tasks pointers only;preserve historical reports and this review. Label historical links to removedrawassets as retrievable from9fbce58,not live files; no bulk rewriting old evidence.

Auto push READY_FOR_REVIEW/BLOCKED with Enter to verified Codexw2:p43,no monitoring. No stage/commit/push by Flash; Controller re-reviews actual diff and localcommit under standing Owner permission only after pass. No Argon cleanup work/newagents. STOP after delivery.
