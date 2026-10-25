# Gate1 — Read-only dependency closure & hunk mapping

2026-10-25 · Owner Stang · Controller/reviewer Codex · Worker agyanimation/3.8 Flash, verified pane w2:p49.
State: AUTHORIZED_DISCOVERY_ONLY. Actual HEAD `25a67d5575e31034a5a08290873b9c401357d33a`; src/tests clean at dispatch, documentation dirty/protected. Recheck before work. No new agents or Argon scans by default.

## Deliverable / ownership

Write one primary `assets/removal-manifest.md` with exact paths/symbols/current line anchors, originating evidence, consumers, KEEP/REMOVE/REPLACE/UNCERTAIN decisions and ordered cleanup plan. Add one `assets/discovery-report-001.md` containing actual read-only commands/results, reviewed ref, hashes, coverage and blockers. Update RF02 notes/tasks with pointers/status only; preserve Codex-owned files and historical reports. Avoid duplicate checklists or copies of diffs.

## Required read-only work

1. Read current directives, reviews001–007, RF02 docs and actual history/source. The34-path checkpoint comparison is an initial seed, not the whole dependency universe. Extend to all affected live references/configuration/bootstrap/fixtures discovered.
2. Enumerate direct/transitive require/import and registration references, remotes/types/constants, controller/service lifecycle, pose/animation loading, HUD/input and test runners. Give source evidence, not unverified no-consumers claims. Distinguish runtime wiring from preserved historical assets/docs.
3. For every proposed shared-file edit identify exact symbols/hunks and reasons, including BallService/CagePhysics/bootstrap/R6 controller/configs.617f523 is not a clean restore target. Preserve Plan00/01 foundation and unrelated later fixes; uncertain provenance is UNCERTAIN, not automatic KEEP/REMOVE.
4. Include dead-reference prevention order, source/Studio synchronization implications (read-only evidence only), expected interim state after cleanup, and rollback/checkpoint proposal that does not reset current docs or erase history. No actual Git/staging/commit/config operations.
5. Describe minimal meaningful future checks to prove foundation still works and legacy runtime references gone. Listing commands is allowed; do not run application tests/Studio simulation now. Read-only static text/reference/document checks allowed. No downloads/installs.
6. Identify issues that truly block safe removal; supply bounded evidence. Do not invent new gameplay, normalize Avatar, author Idle/animations, or run source-modifying generators. BodyCheck/duplicate policy does not block read-only discovery; leave settled/pending design alone.

## Acceptance / stop gate

- Complete reference evidence for each proposed removal/replacement, explicit handling of incoming consumers and shared contracts, no wildcard source deletion or whole-file restore. No falsely resolved UNCERTAIN rows; disclose irreducible unknowns/Studio parity limitations.
- Actual ref/fingerprints tie manifest to current files; compare src/tests current state to preflight, and distinguish dirty doc authorship. Reproducible document links/anchors/static checks.
- Codex reviews actual evidence. Correct in-scope docs findings under this same contract; do not self-approve. If a hard ambiguity requires Owner, push BLOCKED with narrow question.
- **Even if manifest verifies, STOP before code deletion/source or Studio edits and new gameplay.** Owner must see exact cleanup proposal and confirm next action. First new gameplay/visual task will be Owner-led Idle, not autonomous full locomotion.

## Reporting

Push READY_FOR_REVIEW/BLOCKED/necessary Owner decision automatically once per milestone to verified Codex (last known w2:p43) using Herdr prompt with Enter. No SEND REPORT wait. No monitoring/polling. No automatic repetitive retries; disclose delivery failure. Claim submission separately from completion or review.
