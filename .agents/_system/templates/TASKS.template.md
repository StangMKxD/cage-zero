# Task Board: {{TASK_SLUG}}
<!-- LINE_BUDGET: Soft target <= 70 lines | Compaction trigger at 90 lines -->
> **[LIVE TURN BANNER]**  
> **Active Role:** `{{ACTIVE_ROLE}}` | **Board State:** `{{BOARD_STATE}}` (`READY` | `IN_PROGRESS` | `IN_REVIEW` | `REWORK` | `ESCALATED` | `READY_FOR_UAT` | `COMPLETE`)  
> **Round:** `{{ROUND_NUMBER}}` / 2 | **Base SHA:** `{{BASE_GIT_SHA}}`  
> **Commit Policy:** Reviewer-Led after Stang Written Approval (Task-ID Scoped)  
> **Canonical Project Board Pointer:** [docs/plans/TASKS.md](file:///C:/Users/Stang/roblox-game/project-last-wave/docs/plans/TASKS.md)

---

### Section 1: Workstreams
- [ ] `T-01` [{{PROFILE_1}}]: {{T01_TITLE}} (`{{T01_STATUS}}`)
- [ ] `T-02` [{{PROFILE_2}}]: {{T02_TITLE}} (`{{T02_STATUS}}`)
- [ ] `T-03` [{{PROFILE_3}}]: {{T03_TITLE}} (`{{T03_STATUS}}`)

---

### Section 2: Active Bug Queue (Current Round Only)
<!-- Findings from prior rounds auto-evict to archive-log.md upon verification -->
- `None` <!-- Format when active: - [ ] F-01 [SEVERITY] Description (Assigned: role) -->

---

### Section 3: Verification Gates
<!-- Selective Evidence: Passing tests record inline exit 0. Failing tests link to evidence/ -->
- [ ] `G-ENG-01` Static Analysis: `NOT_RUN`
  - Inline evidence: `selene .` (pending) | `stylua --check .` (pending)
- [ ] `G-ANIM-02` R15 Animation: `NOT_RUN`
- [ ] `G-VFX-03` VFX & Size (<199KB): `NOT_RUN`
- [ ] `G-FEEL-04` Combat Feel / Hitstop: `NOT_RUN`
- [ ] `RBX-10` Anti-Exploit / Server Authority: `NOT_RUN`
- [ ] `RBX-11` MicroProfiler Budget (<12ms): `NOT_RUN`
- [ ] `G-VIS-07` Visual Playback / Screen Capture: `NOT_RUN`
- [ ] `G-OWN-08` Stang Final UAT & Closure Sign-off: `USER_UAT_PENDING`

---

### Section 4: Closure, Commit Plan & Knowledge Promotion Gate
- **Staged Files:** {{CHANGED_FILES_SUMMARY}}
- **Proposed Commit Title:** `{{COMMIT_TYPE}}({{PLAN_ID}}/{{TASK_ID}}): {{COMMIT_SUMMARY}}`
- **Knowledge Promotion:** Candidate items flagged for `docs/` or `Cjobsidian/` (pending Stang approval).
- **Next Required Action:** `{{NEXT_ACTION}}`
