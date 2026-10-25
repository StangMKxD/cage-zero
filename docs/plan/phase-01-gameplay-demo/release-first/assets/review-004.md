# Release-First — Target Delta001 Review004

2026-10-25 · Codex · **CHANGES_REQUESTED — two bounded technical-documentation corrections**.
Scope: new Player Avatar R15 target and push-report override only. Review003 RF-F01..06 remains historical scoped verification.

Reviewed ref: HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + working tree. Delta001 SHA256 `87d73831e55d9da42ac0c0b3d30d19e2b81b0a37163151fef5b4d547c761ba56`.

## Checked

- Active target documents describe Player Avatar R15 with standardized body/contact geometry, stats/cards decoupled from size, and body-package support unresolved pending empirical evaluation. No claim of Studio success is accepted here.
- Reported checker rerun:29 markdown files,97 relative links/anchors, SUCCESS. This checks the release-first tree with simplified slug logic, not every global document.
- All11 file/hash rows actually present in delta001 match current bytes. Changed-file list has20 entries;11 hashes are not evidence for all20 files. No exhaustive protection/attribution claim made by reviewer.
- git diff --numstat -- src tests empty. No app tests, Studio mutation, Git mutation or runtime approval.

## Findings

### RF-F07 — MEDIUM / OPEN: Avatar API vocabulary conflated
RF02 notes §5.1 calls BodyHeightScale/BodyWidthScale/BodyDepthScale properties of HumanoidDescription. Actual description properties are HeightScale/WidthScale/DepthScale; Body-prefixed scale NumberValues are children of Humanoid. Separate these targets explicitly so a worker cannot copy nonexistent properties. RF02 tasks references ApplyDescriptionReset; use the current documented async method when naming a concrete API, or keep the step provider-neutral until implementation design is selected. Link primary documentation instead of implying unverified pseudocode is executable.

### RF-F08 — MEDIUM / OPEN: Appearance readiness contract misses already-loaded/replaced character
RF02 notes §5.1(6) and delta001 §3.6 require waiting for CharacterAppearanceLoaded. An event-only wait can miss readiness already reached before subscription. Document a readiness check plus event path, bounded failure/fallback, current-character/generation check, cleanup on respawn/disconnect and idempotent normalization. Explicitly preserve player identity while normalization is pending; no gameplay-ready state before validation. A timeout must not silently grant an unnormalized player gameplay access. Keep implementation mechanism proposed; no Studio test claim required in this documentation correction.

## Correction / reporting

Same bounded docs-only allowlist, preserve existing reports and Codex-owned files. One delta correction report; refresh hashes for all files in the claimed correction scope or clearly identify partial coverage. Re-run focused document checks; no new agents/code/tests/Studio/Git. Push-report automatically at READY_FOR_REVIEW/BLOCKED/needed Owner decision with Enter to verified Codex; no Owner SEND REPORT gate and no monitoring. Do not reopen settled target/controls or expand package-policy scope. Original pending gameplay/product choices and cleanup discovery gates remain.

Primary references checked2026-10-25:
- [HumanoidDescription](https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription)
- [Humanoid](https://create.roblox.com/docs/reference/engine/classes/Humanoid)
- [Player appearance readiness](https://create.roblox.com/docs/reference/engine/classes/Player)
