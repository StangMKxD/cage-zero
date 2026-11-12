# File Ownership & Boundary Isolation Rules

## 1. Overview
To prevent merge conflicts, parallel race conditions, and architectural degradation, strict file ownership boundaries are enforced across all subagents and tasks.

Reference: [docs/workflows/roblox-agent-workflow.md](../../docs/workflows/roblox-agent-workflow.md)

---

## 2. Directory Ownership Matrix

| Directory / Path | Exclusive Write Owner(s) | Read Access | Prohibited Operations |
|---|---|---|---|
| `AGENTS.md` | Project Owner / Governance Subagent | All Agents | Silent rewriting; removing historical authorizations |
| `README.md` | Documentation / Project Lead | All Agents | Claiming non-existent tools or unverified features |
| `docs/READ.md` | Documentation Subagent | All Agents | Omitting canonical paths; inaccurate status reporting |
| `docs/workflows/*` | Architecture / Workflow Subagent | All Agents | Changing workflow rules without Owner approval |
| `docs/plans/TASKS.md` | Task Execution Board Writer (AGY / Codex) | All Agents | Spawning secondary or conflicting task boards |
| `docs/decisions/*` | Project Owner (Stang) | All Agents | Modifying Owner decisions or fabricating approvals |
| `src/**` | Gameplay & Systems Engineers (Production scope only) | All Agents | Modifying during Sandbox experiments |
| `tests/**` | QA Tester / Engineers (Production test suite) | All Agents | Removing tests to force passing checks |
| `.sandbox/experiments/<slug>/` | Assigned Sandbox Specialist Team | All Agents | Modifying other experiment slugs |
| `.sandbox/approved/<slug>/` | Frozen Reference System (Orchestrator snapshot) | All Agents | Editing existing approved references (Immutable) |
| `.agents/<task-slug>/run_XX/` | Assigned Agent Run Workspace | All Agents | Overwriting prior runs (`run_01` vs `run_02`) |
| `.agents/_archive/` | Historical Archive System (Read-Only) | All Agents | Any modification or deletion |

---

## 3. Strict Boundary Rules

1. **Sandbox Isolation:** No code within `.sandbox/` may import or modify files within `src/`, `assets/`, or `tools/`.
2. **Production Protection:** During a sandbox experiment, `src/` is strictly READ-ONLY. No temporary prototype modules may be placed in `src/`.
3. **Discipline File Isolation:**
   - **Gameplay Engineer:** Owns `source/code/*.luau` in their assigned run.
   - **R15 Animator:** Owns `source/assets/*Animation*.luau` in their assigned run.
   - **VFX Artist:** Owns `source/assets/*VFX*.luau` or VFX definitions in their assigned run.
   - **Independent Reviewer:** Owns `review/*.md`.
   - **QA Tester:** Owns `evidence/*.md` and `testing/*.md`.
