# Gate1 Discovery — Review009

2026-10-25 · Codex · **CHANGES_REQUESTED**. Same read-only contract; no removal or gameplay authorization.
HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + docs working tree. All61 actual source/doc fingerprint rows in discovery-report002 match disk. Matching hashes of source files do not validate manually authored descriptions of them.

## Stable findings

- **RF-F11 OPEN / HIGH:** Manifest§3.3 claims server bootstrap52 physical lines and retained requires/inits for DuelEngine/Match/FreeKick/Parry/EventManager, but current server bootstrap has32 Get-Content lines and does not initialize those services. Client bootstrap is75 Get-Content lines, not86, and does not contain AirLeanController/SkillMoveController/JumpVfxController (rg across src finds none).§3.5 still lists absent Types.AirLeanState and JumpFSMState. Network remotes are table entries at27/28/29 with corresponding Definitions, not RemoteNames assignments at38/39/41. Regenerate evidence from actual line-numbered text. A trailing newline convention can explain3365vs3366, not fabricated52/86 bootstrap counts or nonexistent modules. No handwritten reconstruction of source allowed.
- **RF-F12 OPEN / HIGH, partial improvement:** Regex limitations and stale Match API notes improve honesty, but current bootstrap/reachability claims directly contradict actual files. Need actual initialized-service/handler closure and exact APIs/fields to retain or deactivate; do not keep FreeKick/Parry gameplay APIs simply because unreachable prototype files mention them. Clearly distinguish detected module edges, manually checked symbol edges, and unresolved/dynamic edges. Static limitation disclosure is not completion of closure.
- **RF-F13 OPEN / HIGH, partial improvement:** CagePhysics uncertainty/visibility split and test goals corrected. Exact valid foundation entrypoint set and post-cleanup runnable-state contract still depends on the incorrect bootstrap above. Keep uncertainty explicit and avoid cleanup-ready claim. Do not invent fallback stubs/new gameplay to paper over unresolved dependency paths.
- **RF-F14 OPEN / MEDIUM, partial improvement:** Category totals10+3+7+14 now coherent. Source metric tables/coordinate examples still disagree on physical lines; standardize one definition (Get-Content numbering or split-lines with explicit final empty row), verify every table row and totals automatically, and correct erroneous descriptive claims as errata.

## New finding

- **RF-F15 OPEN / HIGH — Removal order regressed:** Seven-stage plan deletes R6ActionPoseController in Stage3 before Stage4 removes InputController/init/R6AnimationController references. That violates the original consumer-before-provider rule. Reorder or explicitly define one non-runnable atomic edit group with no reload/sync between its edits; do not claim intermediate states have no dead requires. Source and Studio sync barriers must be defined before execution; no actual sync now.

## Bounded escalation and corrections

Repeated factual source-mapping errors justify one limited Argon spot audit, not a broad scan: only server/client bootstraps, Network and Types plus exact references directly needed. Argon owns only assets/discovery-spot-audit.md; Flash owns removal-manifest and new discovery-report003/RF02 pointers. Preserve all historical reports/Codex artifacts. Flash must consume actual extracted evidence, not invent corrected symbols. No new agents, code/tests/Studio/Git actions or Idle work. Argon returns once and stops; Flash implements documentation corrections. Auto milestone push reports, no monitoring. Owner confirmation remains required before cleanup/new runtime.
