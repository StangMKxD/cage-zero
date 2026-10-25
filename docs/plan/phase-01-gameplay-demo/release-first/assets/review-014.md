# RF02-CLEANUP-A — Independent implementation review014

2026-10-25 · Codex · **CHANGES_REQUESTED**. Source cleanup authorized, no R15/Idle/new gameplay/Studio/app tests/Git mutations.
Reviewed actual ref: HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + current source/docs diff. Implementation report SHA256 `312ead76ea2e8aaeabd4fcfb907403cc3be951ba0b59c63e8399194748df4873`.

## Independently verified

- Exact10 deleted paths match approved list. Nine modified source/test files are within allowlist; no out-of-scope source changes detected.
- All21 existing-file source/protected hash rows in report match current disk; protected12 remain outside the source diff.
- Backup24 rows validated against actual backup bytes,0 mismatches; normalizedLF backup contents equal each HEAD file,0 differences. Recovery location: C:/Users/Stang/cage-zero-cleanup-backups/backup-option-a-20261025-1804.
- Removed active pose/skill requires verified by source/diff inspection; retained mentions in comments or explicitly inert files are not live dependencies.
- git diff --check passes whitespace/error checks. No application tests or Studio verification by Codex; delimiter balance is not a Luau parser/typecheck/runtime result. Claimed complete runtime behavior is not independently verified.

## New findings — OPEN

### RF-F16 / HIGH — Cleanup recreates retired gameplay APIs as compatibility fiction
BallService tail adds SpawnBall/StepBallPhysics, explicitly documented as stale and absent in HEAD during discovery. Adds constant/no-op IsInShootingZone/HandleActionRequest/ExecuteKick/Slide/Jump/Dash/Poke/CagePress and other fabricated gameplay adapters; InputController similarly replaces removed actions with no-op methods and invented fixed flight/charge snapshots. These were not permitted: execution contract says no new gameplay stubs, and dormant prototypes must not drive active API preservation. SpawnBall even ignores spawnPos; StepBallPhysics would double-step if later called alongside Heartbeat.

Remove newly created compatibility APIs and obsolete state/getters lacking an evidenced active foundation consumer. For any genuinely necessary retained adapter, name its exact live caller and obtain a bounded contract correction instead of silently inventing behavior. Keep only authorized existing free-ball state/physics and existing rig/camera wiring. Inert historical modules/tests may remain visibly incompatible; do not hide that with constant-success zone checks or fake gameplay methods. Retained shared type definitions required by protected inert files may remain as documented deprecated definitions.

### RF-F17 / MEDIUM — Unapproved new Ctrl camera binding
InputController.Init adds LeftControl -> CameraShiftLockController.Toggle. Existing preserved CameraShiftLockController already owns LeftAlt input (lines134–141), and this assignment permits no new input bindings. Remove duplicate Ctrl input handler; keep existing controller's Init/idempotent wiring. Do not introduce a new user-facing control during cleanup.

### RF-F18 / MEDIUM — Evidence report overstates checks and conflates attribution
Report says git diff --check proves0 syntax errors; it does not parse Luau. Keep parser/typecheck status NOT RUN/UNAVAILABLE unless actual suitable tool evidence exists; delimiter balance is limited static evidence. Report source-only diff separately: current `git diff --stat -- src tests` is19 files,258 insertions,20329 deletions, not the all-working-tree38-file/478/20421 total attributed to cleanup. Label any all-tree totals as mixed pre-existing documentation. Avoid fixed72-test/Place4 engine readiness claims without current actual harness/target verification. No new runtime test authorization inferred. Retain documented inability to verify engine behavior.

## Corrective handoff

Same cleanup-option-a-HANDOFF, in-scope corrections permitted. Flash sole source writer; no Argon/new agents. Preserve backup and protected files/history; no new gameplay, tests or Studio actions. One cleanup-option-a-fix-001 report with current own-source diff,protected hashes,actual static commands and limitations. Refresh hashes after edits. Auto push READY/BLOCKED with Enter, no monitoring. Codex re-reviews actual diff; STOP after cleanup, Owner leads Idle later.
