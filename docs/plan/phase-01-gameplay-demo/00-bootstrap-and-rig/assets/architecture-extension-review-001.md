# DOCS-ARCH-20261024 — Independent Review 001

Reviewer: Codex · Verdict: **CHANGES_REQUESTED** · Documentation only.
Reviewed ref: `c7542258b93b613e0260e43035761cbce87928cd` + dirty working tree, 2026-10-24.
Snapshot: all nine deliverable hashes in architecture-extension-report-001.md match current files; report SHA256 `5fa75ac8c4869b36985ee0ed72c7d2408d73f4467261e3132bef469506d8fbe8` matches the submitted report. All nine protected source post-hashes also match. Staged diff empty. This verifies current bytes, not retrospective authorship or every zero-write claim; pre-existing/concurrent source and Phase2 changes exist. No application tests run.

Original Plan00 runtime remains PAUSED_BY_OWNER; review010 F18/F19 OPEN. This review neither resumes nor closes it. New architecture is correctly located under Plan00. Core U1–U13 progression placement is represented, but the following contracts block acceptance.

## Findings — OPEN

### A-01 — High: Trait table invents values and changes units
`designs/upgrade-limit-break.md` §4: percentage refunds become flat +10/+15/+20 stamina; Bulldozer adds an unapproved victim loss of 15; Iron Wall substitutes math.random(3,4) for a physical rebound target band. Clean Sweeper +=1.1 can add to the existing .8 instead of replacing its bonus. Wall-Breaker TierII must explicitly preserve the restitution cap1.15 absent a new decision. Restore source intent; mark refund basis, triggers/deduplication, missing amounts and composition PENDING. Do not choose them implicitly. Preserve TierI conditions/effects when TierII upgrades only selected parameters.

### A-02 — High: Transaction guarantee and deduplication ordering unsupported
Upgrade §5.3 claims a ProfileStore / MemoryStore Transaction plus unconditional rollback; no provider/protocol is selected. It records idempotency only after success, leaving a retry/crash ambiguity. Specify durable single-owner aggregate invariants: server validation, request dedupe and material/cash consumption plus upgrade/result committed together; publish only after durable success, reconcile uncertain outcomes. Provider/session locking, cross-owner operations and recovery protocol remain PROPOSED/PENDING; no native cross-store ACID or guaranteed rollback claim. Equipped/locked/in-match eligibility choices must also be labelled proposed unless traced to approval.

### A-03 — High: Paid trading gate is missing and schema contradicts policy
Monetization §3.3 uses random-item restrictions to decide trading; global data-schema §3.2 says all paid-random items are always untradeable. Neither expresses the independent IsPaidItemTradingAllowed player gate. Model server-side policy checks for all affected trading/market paths and paid provenance, with unknown/error policy handling explicit. A stricter blanket product ban requires a separate decision. Keep disclosure of actual numeric odds before paid acquisition. Direct purchase/Battle Pass alternatives are proposals, not new mandatory products.

### A-04 — High: Multiple incompatible target schemas
Upgrade §5 and global schema §3 disagree on field names (cardInstanceUid/cardUid, cardId/characterId, allocations, awakening and extra Trait). Global schema persists effective stars/profile while upgrade says pure derivation, without cache/invalidation contract. Celebration schemas disagree on categories/fields; impact offset/timestamp is confused with the .15s duration. Shard map reuses duplicate-card counts despite conversion ratios pending. Select one canonical PROPOSED schema and reference it, or provide explicit mappings; separate source state from derived profiles and duration from offset. Do not freeze conversion units.

### A-05 — Medium: Unapproved choices presented as verified targets
Monetization §3.1 promotes TierA/choose-three starter eligibility to Verified Target, though U7 only settles one card+Cash and HANDOFF leaves roster pending. §6 fixes two preset slots (and seven future slots), despite gamepasses deferred. Candidate Ney scale .98 differs from archetype .92 without explaining an unapproved override. Header APPROVED DESIGN is too broad for pending choices. Distinguish accepted decisions from source proposals; retain candidate examples as illustrative. Remove IP-safe assertions in summary/diagram that contradict the later unverified-rights disclaimer.

### A-06 — Medium: Celebration timeline has an undefined deadline origin
Monetization §5.2 allows a 2s request window then a 3–4s cutscene but a 4s deadline without its origin; late valid requests cannot satisfy all three. The 2s window/audience/skip behavior are not settled. Document proposed timing alternatives and unresolved choices; server-owned match-flow deadline/cleanup must be coherent, including missing/disconnected requester and local camera restoration. Do not silently pick a new product rule.

## Corrective scope and evidence
AGY revises only existing DOCS-ARCH allowlist and one correction report, preserving original reports/reviews and old runtime state. No source/tests/Studio/Phase2 files/Git mutations/new agents. Re-run document link+anchor and arithmetic checks with reproducible commands/output, regenerate post-hashes after changes, list own file/hunk scope separately from whole dirty tree. Resolve HOW TO CHECK section numbers. D-ARCH02/03 need rework; checked tasks are implementer completion claims, not reviewer approval.

Use the same primary HANDOFF. No monitoring: present outcome + HOW TO CHECK in agyplan; await Owner inspection/explicit SEND REPORT, then submit one report with Enter to the verified Controller pane.

## Primary technical references
- [Roblox paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items): separate eligibility for paid random acquisition and paid item trading.
- [Roblox data stores](https://create.roblox.com/docs/cloud-services/data-stores) and [player data purchasing](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing): per-key updates/session protection; no evidence here for the claimed generic cross-store transaction.
