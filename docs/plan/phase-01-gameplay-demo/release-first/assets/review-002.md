# Release-First — Independent Review 002

2026-10-25 · Codex · **CHANGES_REQUESTED** (two remaining findings). Documentation review only; no runtime deletion or R15 implementation authorization.

Reviewed HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + working tree. Fix001 SHA256 `514d02ea49d16d253a331b9f278388a31cddddcd542c8906f90f6a96a74ebc416`.

## Independently checked

- RF02 inventory has34 unique paths; set equals `git diff --name-only 617f523 HEAD -- src tests` exactly. This proves comparison coverage, not complete dependency closure or provenance.
- All25 hash rows in fix001 match current files.
- Inspected and reran the reported Node link checker:25 markdown files,60 relative links/anchors, SUCCESS. Fix report's earlier24/51 is its earlier snapshot; no claim of full global-doc coverage. Checker has a simplified slug implementation; result is a focused document check, not runtime verification.
- `git diff --stat -- src tests` and `git status --short -- src tests` empty. Current source/test trees match HEAD; no application tests or Studio actions performed.

## Stable findings

| ID | Review002 status | Evidence / remaining correction |
|---|---|---|
| RF-F01 | **OPEN — partial correction** |34 paths and provisional/no-cleanup-ready labels corrected. Originating commit claims still wrong: inventory gives SkillMoveService and SkillMoveConfigs4d1ba7a, but `git log --diff-filter=A --format='%h %s' -- <path>` reports25a67d5 for both; CameraShiftLockController is4d1ba7a, not4571ced. Recheck every concrete commit claim with actual history. Record first tracked commit vs behavioral introduction separately; a bulk checkpoint is not proof of original authorship. Fix001 §2.1 itself lists nonexistent tests/tier1 paths and runner.luau/run_all.luau while actual files are tests/e2e with TestRunner/BundledTestRunner/TestHarness/run_all.ps1. Do not rewrite historical fix001; explicitly correct these in the next report and align active inventory. Provisional discovery/consumer closure stays pending. |
| RF-F02 | **VERIFIED for planning correction** |617f523 is labelled comparison checkpoint, existing gameplay acknowledged, no whole-file reset, later CagePhysics hunks need evaluation. No completed hunk analysis or source removal sign-off implied. |
| RF-F03 | **VERIFIED for planning correction** |Active RF02 references actual controllers/services; prototype references labelled external, unsupported R6 causal diagnosis removed. External prototype contents not independently verified. |
| RF-F04 | **OPEN — partial correction** |No per-move cooldown target and BodyCheck launch decision pending are corrected. RF03 plan §2 introduces F as preserved target key. Owner Q6 selected LMB Shoot/Slide, E Pass/Poke, RMB Curve/BodyCheck, retireMMB; new source does not authorize F. Restore that mapping throughout active docs, or label an alternative proposal requiring Owner decision. No need to reopen settled mapping merely to repair this error. Keep forward collision/Strength/LooseBall/no-auto-possession/no-I-frame/recovery semantics. |
| RF-F05 | **VERIFIED for planning correction** |Per-copy model, duplicate policy pending, four economic invariants, conditional Robux release gate present. selectedCharacterId referring to instance versus definition remains explicitly pending in global schema; resolve identity before implementation contract. This is not storage implementation sign-off. |
| RF-F06 | **VERIFIED with stated limits** |Actual checker readable/rerunnable and25 post-hashes match. Current tracked source/tests unchanged. Retrospective untouched-file claims are implementer assertions without independent before-manifest proof. Preserve that limitation. |

## Next assignment

Normal prompt; fix only RF-F01 provenance/report errata and RF-F04 target mapping, refresh own final hashes/link results in one fix002 report. Same docs allowlist; no source/tests/Studio/Git mutations, no new agents, no editing Codex-owned six legacy files/directives/HANDOFF. Preserve prior reports. No blanket approval or cleanup-ready claim. No monitoring: own-pane outcome/HOW TO CHECK, Owner inspection/explicit SEND REPORT, then one callback with Enter. Original Plan00 findings and architecture findings retain their actual status.
