# Release-First — Target Delta003 Review006

2026-10-25 · Codex · **CHANGES_REQUESTED — bounded consistency correction**.
Review005 already exists for RF-F07/08; this new aerial delta is Review006, not a replacement of Review005.

Reviewed ref HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + docs working tree. Delta003 SHA256 `8eba6edc34ac917f64938bc0165e39d177d705b458b4b00b883ed98b993814e1`.

## Evidence and accepted alignment

All23 reported file/hash rows match current bytes. Reran existing focused link checker:34 markdown files,127 relative links/anchors,SUCCESS. Source/test status empty at review. No application tests, Studio actions or Git mutations. Actual-contact assisted aerial reception, brief hold, contestable visible ball, live curved/rebound guidance and physical goalkeeper counterplay are represented; no launch GKAI requirement added.

## New findings — OPEN

### RF-F09 / MEDIUM — Acceptance still forbids the approved reception exception
release-first/plan.md §4 DoD still says no auto-catch without the new exception. Reconcile all active acceptance/test/invariant text with contact+relative-speed-gated aerial possession. Distant possession/teleport remain forbidden. Use one accepted definition; do not let the legacy blanket rule reject the requested feature.

### RF-F10 / MEDIUM — Preview scope and technical proposals presented as accepted rules
RF02 notes §6.1 and RF06 plan §2 restrict prerelease preview to an airborne shooter, whereas Owner Q3(B) and the primary decision doc provide shooter-only windup preview without that restriction. Align with general shooter windup preview, while aerial hold remains its own action.

RF02 notes §6.2 chooses immediate hold cancellation on wall contact and loss of possession on opponent contact/slide/impact. Those are not automatically implied by a contestable ball: a successful validated tackle can win possession, incidental contact need not always dislodge it. Label proposed transition policies PENDING technical design/Owner choice where they alter feel, rather than Accepted behavior. Keep death/disconnect cleanup and finite hold as required invariants.

Likewise, relative approach speed formula |v_player-v_ball| selects full relative-speed magnitude; the accepted design did not settle radial closing component versus magnitude. Label that exact estimator as a proposed implementation choice. Suspending gravity is one possible mechanism for brief hold, not a proven way to stop an existing vertical velocity; keep mechanism/momentum restoration pending technical contract. Do not add another interview for tuning numbers or reopen the four settled feature choices.

## Correction assignment

Same narrow docs-only allowlist. One delta correction report, preserve prior reports/Codex-owned docs. Fix active DoD/preview scope; clearly distinguish accepted behavior from proposed finite-state implementation details. Refresh own hashes and document checks. No source/tests/Studio/Git/new agents. Auto push-report READY/BLOCKED/needed Owner decision with Enter to verified Controller, no monitoring/SEND REPORT wait. Prior scoped verifications remain unchanged; runtime implementation and actual removal remain gated.
