# Release-First — Single Live Task Board
2026-10-26 · OWNER_STANDARD · Controller/Reviewer Codex · Owner Stang
Base44c2810580a74727bf8eca7f5578576e14d4a516 + protected dirty source/camera/animation; no code staged by planning.
Turn: IMPLEMENTER T02 + explicitly authorized momentumjump/airlean delta (acknowledged new AGY); Controller owns docs/board. Commit policy: Owner authorized DOCUMENTS commit; source needs separate authorization.
[Plan](../plan.md) · [Design](../assets/street-football-design.md) · [Owner checklist](../assets/owner-checklist.md) · [Old board](../assets/plans-before-street-20261026/RF-02--tasks.md)

## Feature tasks (all code/config/UI/verification inside each feature)
| ID | Feature | Depends | State / owner |
| --- | --- | --- | --- |
| T01 | RF02 five-clip locomotion/camera/sprint checkpoint | foundation | OWNER_VISUAL_ACCEPTED / CHANGES_REQUESTED technical; Codex review; implementer frozen |
| T02 | RF02 dribble/receive + high momentumjump/airlean — Owner checklist7 delta | foundation; retain T01 fixes | IMPLEMENTING; acknowledged AGY; [contract](../assets/dribble-receive-HANDOFF.md) |
| T03 | RF02 pass/shoot/curve/basic volley | T02 | PLANNED; unassigned |
| T04 | RF02 dash/stamina/control polish | T01,T02 | PLANNED; unassigned |
| T05 | RF03 street kick/slide/poke/block/body-check + HP | T02,T04 | PLANNED; unassigned |
| T06 | RF03 gauge + ground/air Orbs | T03,T05 | PLANNED; unassigned |
| T07 | RF04 Wall Run/Wall Launch | T03,T04,T05 | PLANNED; unassigned; beforeT08 |
| T08 | RF05 SIX Supers in ONE feature | T06,T07 | PLANNED; unassigned |
| T09 | RF05 baseline profile/loadout/gauge-only upgrade | T08 | PLANNED; unassigned |
| T10 | RF06 2v2/GoldenGoal/rewards | T03,T05,T08,T09 | PLANNED; unassigned |
| T11 | RF06 concise HUD / feedback | T06,T08,T10 | PLANNED; unassigned |
| T12 | RF07 4-player/security/performance/Owner release + final doc sync | T01..11 | PLANNED; unassigned |
Targets one focused day/feature, sixSupers one task; time is estimate, unmet checks remain open. No auto splitting/new gameplay or approval from checkbox.

## Active findings
| ID | Severity | Scope / status |
| --- | --- | --- |
| RF-F24/25 | Medium | Prior camera near-wall/async lifecycle risks; [review024](../assets/review-024.md), still OPEN |
| RF-F26 | Observation | Post-LoadTracks guard hardening; actual yield/race NOT PROVEN; review025 |
| RF-F27 | Medium | Sprint client intent can remain true after server cancellation/rejection; review025 OPEN |
| RF-F28 | Medium | Land Action track not interrupted by grounded movement; review025 OPEN |
| RF-F29/30 | Medium/Low | Sprint bind generation and numeric signal type; review025 OPEN |
Prior A/F findings preserved in historical reports/old board; no closure by routing.

## Evidence gates
- Owner visual first6 accepted2026-10-26, including actual locomotion; Dash specifically NOT implemented per report.
- AGY five-clip report READY_FOR_REVIEW; static Controller audit CHANGES_REQUESTED, not blanket technical pass. [review025](../assets/review-025.md).
- Planning-only checks: local links/config requirement coverage/diff whitespace/staged-path audit pending final run.
- T02 tests/sync/actual multiplayer evidence PENDING; new requirements code NOT RUN.
- Production published animation IDs/permissions absent: release blocker for custom clips, Studio fallback not production proof.

## Deferred / authorization
Phase2: special dribble3+extra4; gacha/13stats/Traits/multiple character tuning; advanced aerial hold/trajectory; extra modes/economy/Robux/shops. Walls stayPhase1.
Removed, not deferred: fouls/free kick/cards/penalties/regular overtime/SuperMastery power scaling.
Owner requested docs commit now, no push. Do not stage concurrent source, previous notes/HANDOFF/camera draft or AGY reports without explicit inclusion/review.
Full RF02/Phase1 and legacy00/01 remain open. No automatic implementation beyond T02.