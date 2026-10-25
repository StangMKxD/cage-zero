# Release-First documentation — Independent Review 001

2026-10-25 · Reviewer Codex · **CHANGES_REQUESTED**. No runtime removal authorized by this review.

Reviewed HEAD: `25a67d5575e31034a5a08290873b9c401357d33a` + documentation working tree. Completion report SHA256 `01b73b5e0889a79e8d9be93fba2234f5d8f692f65c8f730445255f775eaabcbd`; RF02 notes `7dc9c87a8d4015e876824377f4bcadf9bc90bf7cae82bbe95475fcbaa008ad99`; RF02 tasks `221b0315b920330291b3e03d6f3eddeB59dcaf138658bf7181b90ed2698f37c6` (case-insensitive hex).

Current tracked changes are agent.md and docs only; no src/tests changes reported by git status. New release-first tree exists. This is current-state evidence, not independent proof of every historical zero-write claim. Legacy cancellation and R15 target are correctly represented in the new track. Original runtime/review findings remain unresolved; no application tests run.

## Findings — OPEN

### RF-F01 / HIGH — Removal manifest is not an executable, complete inventory
RF02 notes §4 and completion report §3 omit changed paths present in `git diff --name-status 617f523 HEAD -- src tests`: DuelEngineService, DuelUIController, DuelChoiceModal, AirLeanConfigs, JumpConfigs, RigAnimationConfigs, modified R6AnimationController, test runners/harness/run_all. Wildcard Tier1_*.luau is not a safe five-file deletion list (pre-existing Tier1_FeatureCoverage also matches). No exact symbols/hunks, originating commits or consumer references support the claim no other consumers. Keep this table explicitly provisional; list every changed/new path and exact test names, plus references introduced elsewhere, classify unresolved paths UNCERTAIN. Prove closure of requires/registrations/remotes/test imports before any removal instruction becomes executable.

### RF-F02 / HIGH — Checkpoint is misrepresented as a clean physics-only baseline
`git show 617f523:src/server/services/BallService.luau` already contains possession/shoot/pass, shooting-zone logic and laserGuidedPassActive. Thus restoring this snapshot is not equivalent to removing all undesired gameplay. `git diff 617f523 HEAD -- src/server/services/CagePhysicsService.luau` shows FLOOR_SMASH_RESTITUTION and floor-bounce behavior plus lighting changes; KEEP100% skips inspection of post-baseline hunks. Treat617f523 as comparison checkpoint only, explain which pre-existing behavior must remain versus be removed/replaced, and classify actual post-checkpoint hunks. Preserve foundation without asserting every current byte is Plan01. No whole-file restore/reset.

### RF-F03 / HIGH — AS-IS evidence names nonexistent source paths
RF02 plan/notes/tasks refer to src/client/FootballClient.client.luau, src/server/FootballServer.server.luau and ShiftLockDribble.luau. `rg --files src` finds none of these names. Replace with actual repo controllers/services and symbol references, or label external/prototype references with their real location and unverified status. Do not claim high R15 compatibility or diagnose R6 as the proven cause of visual failure without evidence.

### RF-F04 / HIGH — Gameplay cooldown and BodyCheck authority drift
RF02 task2.3 includes DashCooldown/PokeCooldown; RF03 permits anything except unusually long cooldowns. Owner U2 removed per-move gameplay cooldown globally, retaining stamina/recovery and transport limits. Align all active targets. RF03's conditional permission to defer BodyCheck and its Shoulder Barge wording are not an Owner decision: mark launch inclusion/defer PENDING, preserve forward BodyCheck semantics and target key mapping until resolved. Implementer cannot grant its own scope exception.

### RF-F05 / HIGH — Economic contracts introduce unselected duplicate behavior
RF02/global profile uses ownedCharacters:{string}, RF05 task5.5 commits to Duplicate Conversion without a selected conversion policy. Owner source requires ownership/duplicates/save/load, not automatic conversion. State duplicate outcome policy PENDING and model per-copy ownership or an explicit pending alternative without losing copies. Carry durable roll/grant/dedupe invariants before RF05: same committed debit+grant+request result, uncertain outcomes reconciled, retry not rerolled, request reuse cannot grant twice. RF07 Robux receipt tests conditional on selecting a launch product, not an unconditional release blocker.

### RF-F06 / MEDIUM — Verification claims lack reproducible evidence
Completion report states all internal links/anchors correct but provides no command/output, exact file hash inventory or reviewed scope fingerprint. Add reproducible file AND heading-anchor check commands/results and final hashes of own deliverables. Preserve six Codex legacy files/directives/HANDOFF; record limitations rather than claiming unproved protection. Report actual own hunks, not all current changes as implementer work.

## Corrective assignment

Reuse primary HANDOFF; normal prompt, same docs allowlist, no source/tests/Studio/Git mutations/new agents. Fix RF-F01..06 in one correction report and keep IDs stable. Do not mark runtime cleanup ready until the manifest is evidence-backed; discovery may be a separate read-only task if not completed here. Do not hide pending Owner decisions. No monitoring; own-pane HOW TO CHECK then Owner inspection/explicit SEND REPORT before one callback with Enter.
