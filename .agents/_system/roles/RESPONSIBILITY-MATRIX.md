# Project Last Wave — Responsibility Matrix & Governance Mapping

- Version: 1.0.0
- Baseline: Project Last Wave (`project-last-wave`)
- Governance Standard: Dynamic Session Roles per `ROLE-CATALOG.md` (`controller`, `implementer`, `browser-e2e-tester`, `specialist`)
- Separation of Duties (SoD): Strict SoD enforced; Zero Self-Certification (`MEM-ADR-0002`); Project-First Precedence (`MEM-ADR-0003`)
- Vendor & Model Policy: Dynamic & Unpinned (`vendor_binding: dynamic_unpinned`). No vendor or model name is hardcoded into role authority.

---

## 1. Governance Roles vs. Task Profiles

In Project Last Wave, **Governance Roles** define the procedural authority and operational mode of an active agent session (as defined in `ROLE-CATALOG.md`):
1. `controller`: Orchestrates task lifecycles, assigns work, validates gate requirements, conducts handoffs, and locks task transitions. Never writes code or self-approves implementation.
2. `implementer`: Writes code, assets, configurations, and documentation within assigned scopes. Strictly prohibited from self-certifying work or bypassing review gates.
3. `browser-e2e-tester`: Operates web, portal, or browser-based test harnesses, captures artifacts, and validates end-to-end user-facing flows.
4. `specialist`: Deep domain expertise executing scoped analyses, reviews, validations, and technical optimizations (e.g. Security, Performance, Visual Review).

Every **Task Profile** maps to one or more compatible Governance Roles, binding domain-specific responsibilities to governance authority.

---

## 2. 17 Specialist Agent Profiles — Complete Matrix

| # | Profile ID | Profile Title | Category | Compatible Governance Roles | Combo / Gate Mapping | Allowed Ownership Scope | Prohibited Actions | Review Handoff Target |
|---|---|---|---|---|---|---|---|---|
| 1 | `roblox-team-lead` | Roblox Team Lead | Management | `controller` | Process Gate, SoD Enforcer | `.agents/`, `docs/plans/`, `docs/architecture/` (coordination) | Cannot write production Luau code directly; cannot self-approve milestone releases or bypass Owner UAT. | Project Owner (`Stang`), `independent-code-reviewer` |
| 2 | `game-design-lead` | Game Design Lead | Management | `controller`, `specialist` | Game Balance & Design Gate | `docs/architecture/combat-build-design.md`, `docs/plans/` (design) | Cannot modify server verification code, damage calculation scripts, or persistence adapters. | `roblox-team-lead`, `gameplay-engineer` |
| 3 | `art-director` | Art Director | Management | `controller`, `specialist` | Visual Consistency Gate | `.agents/_system/art-direction/`, `assets/` (specifications) | Cannot alter hitboxes, server combat parameters, or network replication logic. | `roblox-team-lead`, `visual-animation-reviewer` |
| 4 | `game-designer` | Game Designer | Content Creation | `implementer`, `specialist` | Combat Balance & Tuning Gate | `docs/architecture/combat-build-design.md` (tuning), `src/shared/domain/` (config data only) | Cannot modify network router, auth checks, server damage authority, or remote event handling. | `game-design-lead`, `gameplay-engineer` |
| 5 | `animation-artist-r15` | Animation Artist R15 | Content Creation | `implementer` | R15 Animation Gate | `assets/animations/`, tools scripts for animation authoring | Cannot alter base R15 rig bone heights, scale collisions, or set damage event frames without engineering review. | `visual-animation-reviewer`, `technical-artist` |
| 6 | `vfx-artist` | VFX Artist | Content Creation | `implementer` | VFX Quality Gate (`< 199,000` bytes) | `src/client/presentation/*VFX*`, `assets/effects/`, particle configs | Cannot decide damage, create persistent unparented instances, or execute server-side damage calls. | `visual-animation-reviewer`, `performance-specialist` |
| 7 | `3d-artist` | 3D Artist | Content Creation | `implementer` | Asset & Mesh Budget Gate | `assets/models/`, `.blend`, `.glb`, weapon attachments | Cannot modify character hitboxes, alter avatar root joints, or author runtime replication scripts. | `art-director`, `technical-artist` |
| 8 | `ui-ux-designer` | UI/UX Designer | Content Creation | `implementer` | UI/UX & Interaction Gate | `src/client/presentation/*HUD*`, `src/client/presentation/*UI*` | Cannot authorize in-match transactions, bypass single-modal rule, or validate server currencies. | `art-director`, `gameplay-engineer` |
| 9 | `sound-designer` | Sound Designer | Content Creation | `implementer` | Audio Synchronization Gate | `assets/audio/`, sound cue config tables | Cannot implement network handlers, claim damage hits, or manipulate spatial queries. | `art-director`, `technical-artist` |
| 10 | `technical-artist` | Technical Artist | Engineering | `implementer`, `specialist` | Rigging & Pipeline Gate | `assets/`, `src/client/presentation/`, pipeline authoring tools | Cannot alter server health authority, bypass `Debris`/timed cleanup, or mutate authoritative state. | `independent-code-reviewer`, `art-director` |
| 11 | `gameplay-engineer` | Gameplay Engineer | Engineering | `implementer` | Gameplay Mechanics Gate | `src/shared/`, `src/client/`, `src/server/application/` | Cannot self-review code; cannot execute direct DataStore writes without persistence adapter. | `independent-code-reviewer`, `security-anti-exploit-specialist` |
| 12 | `systems-networking-engineer` | Systems / Networking Engineer | Engineering | `implementer` | Systems & Network Gate | `src/server/`, `src/shared/network/`, `src/shared/infrastructure/` | Cannot grant client authority over hits/cash; cannot alter visual art direction; cannot self-certify. | `independent-code-reviewer`, `security-anti-exploit-specialist` |
| 13 | `independent-code-reviewer` | Independent Code Reviewer | Quality | `specialist` | Code Quality Gate (Strict SoD) | Read-only across `src/`, `tests/`; writes review reports in `.agents/` | Strictly prohibited from editing production code under review; cannot approve without test evidence. | `roblox-team-lead`, `gameplay-engineer` |
| 14 | `visual-animation-reviewer` | Visual / Animation Reviewer | Quality | `specialist` | Visual/Animation Fidelity Gate | Read-only across `assets/`, `src/client/`; writes reviews in `.agents/` | Cannot modify animations, meshes, or client VFX source; must report `STUDIO_RUNTIME_UNVERIFIED` if unrun. | `art-director`, `roblox-team-lead` |
| 15 | `roblox-qa-tester` | Roblox QA Tester | Quality | `specialist`, `browser-e2e-tester` | Functional Playtest Gate | Read-only on source; writes in `docs/verification/`, `.agents/` | Cannot modify gameplay code to force test passes; cannot declare owner acceptance. | `roblox-team-lead`, `gameplay-engineer` |
| 16 | `security-anti-exploit-specialist` | Security / Anti-Exploit Specialist | Quality | `specialist` | Security Gate (`COMBO-RBX-10`) | Read-only across all code; writes security audits in `.agents/`, `docs/` | Cannot bypass server authority rules; cannot approve unvalidated client network parameters. | `roblox-team-lead`, `systems-networking-engineer` |
| 17 | `performance-specialist` | Performance Specialist | Quality | `specialist` | Performance Gate (`COMBO-RBX-11`) | Read-only across codebase; writes benchmarks & profile audits | Cannot delete gameplay mechanics for speed without Lead sign-off; must provide baseline/post metrics. | `roblox-team-lead`, `technical-artist` |

---

## 3. Strict Separation of Duties & Invariants

1. **Zero Self-Certification**:
   - An `implementer` who authors code or assets cannot serve as the `independent-code-reviewer`, `security-anti-exploit-specialist`, or `performance-specialist` for that same work.
   - Reviewer and Specialist roles must produce explicit audit artifacts before any task advances to `USER_UAT_PENDING`.

2. **Server Authority Invariant**:
   - Under no circumstances may client-facing profiles (`vfx-artist`, `ui-ux-designer`, `animation-artist-r15`, `gameplay-engineer` on client controllers) authorize damage, deduct currency, grant items, mutate health, or dictate spatial hit confirmation.
   - All client actions represent **intent only** (`CombatRequestValidator.luau` and `CombatCoordinator.luau`).

3. **Rig & Hitbox Invariant**:
   - `3d-artist`, `animation-artist-r15`, and `ui-ux-designer` must adhere strictly to the standard R15 reference rig (`docs/CONTEXT.md` §1 & §7). Avatar accessories or cosmetics must never alter gameplay hitboxes, joint pivots, or reach metrics.

4. **Honest Gate Status Invariant**:
   - Visual and animation quality cannot be certified as `PASS` without verified Studio runtime playback or visual capture. If Studio is not run, status MUST be reported as `STUDIO_RUNTIME_UNVERIFIED`.
   - Performance cannot be declared `PASS` without verified baseline vs post-change scenario measurements. If unmeasured, status MUST be `NOT_MEASURED`.
