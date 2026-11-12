# Implementation Plan: {{TASK_TITLE}}
**Task ID:** `{{TASK_ID}}` (e.g. `TASK-YYYYMMDD-NNN`)  
**Task Slug:** `{{TASK_SLUG}}`  
**Governing Milestone:** `{{GOVERNING_MILESTONE}}` (e.g. `PLAN 03 Combat`)  
**Governance Mode:** `{{GOVERNANCE_MODE}}` (`OWNER_STANDARD` | `STRICT_IMPLEMENTER` | `SOLO_EXPRESS`)  
**Base Git SHA:** `{{BASE_GIT_SHA}}`  
**Owner / Authorizer:** Stang  

---

## 1. Objective & Problem Statement
{{CONCISE_OBJECTIVE_DESCRIPTION}}

---

## 2. Scope Lock & Boundaries

### 2.1 In-Scope (Strictly Allowed Paths)
- `{{ALLOWED_FILE_PATTERN_1}}`
- `{{ALLOWED_FILE_PATTERN_2}}`

### 2.2 Out-of-Scope (Strictly Prohibited Paths)
- `src/server/Data/**` (DataStore persistence is strictly untouched unless granted)
- No autonomous `git commit`, `git push`, or Roblox place publishing.
- No unapproved milestone expansion.

---

## 3. Architecture & Impact Analysis
- **Target Subsystems:** {{TARGET_SUBSYSTEMS}}
- **Direct Callers / Consumers:** {{CALLERS}}
- **Required Modules:** {{REQUIRED_MODULES}}
- **Cyclic Require Check:** Verified acyclic structure.
- **CombatVFXController Size Guard:** Current bytes: `{{CURRENT_BYTES}}` / Max limit: `199,000 bytes`.

---

## 4. Workstream Breakdown

| Workstream ID | Description | Responsible Specialist Profile | Output Artifacts |
|---|---|---|---|
| `T-01` | {{T01_DESCRIPTION}} | {{T01_ROLE}} | {{T01_FILES}} |
| `T-02` | {{T02_DESCRIPTION}} | {{T02_ROLE}} | {{T02_FILES}} |
| `T-03` | {{T03_DESCRIPTION}} | {{T03_ROLE}} | {{T03_FILES}} |

---

## 5. Mandatory Verification Gates

- [ ] **`G-ENG-01` (Engineering):** Selene exit 0, StyLua exit 0, `--!strict` typing.
- [ ] **`G-ANIM-02` (Animation):** Valid R15 Motor6D markers (HitboxStart, HitboxEnd).
- [ ] **`G-VFX-03` (VFX):** CombatVFXController < 199KB, Debris timeout on emitters.
- [ ] **`G-FEEL-04` (Combat Feel):** Hitstop 40-120ms, authoritative knockback.
- [ ] **`RBX-10` (Security):** Server authority on damage, math.isfinite(), typeof().
- [ ] **`RBX-11` (Performance):** Frame time < 12ms, Heartbeat < 4ms, zero memory leaks.
- [ ] **`G-VIS-07` (Visual Review):** UI responsive, visual capture verified.
- [ ] **`G-OWN-08` (Owner Gate):** Stang explicit sign-off before git commit.

---

## 6. Rollback & Revert Strategy
- Git baseline checkout command: `git checkout {{BASE_GIT_SHA}} -- {{CHANGED_FILES_LIST}}`
- Roblox Studio revert: Discard unsaved test place changes or reload Place backup.
