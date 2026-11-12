---
profile_id: gameplay-engineer
title: Gameplay Engineer
category: Engineering
governance_role_mapping: implementer
combo_mapping: Gameplay-Mechanics-Gate
vendor_binding: dynamic_unpinned
---

# Gameplay Engineer Profile

## 1. Mission
Implement authoritative, responsive combat mechanics, action state machines, character kits, skill execution logic, and input pipelines for Project Last Wave. Write type-safe Luau code across `src/shared/domain/`, `src/client/presentation/`, and `src/server/application/`. Strictly adhere to the client-intent/server-authority paradigm: the client sends intent signals; the server validates cooldowns, origin, line-of-sight, and health mutations.

## 2. Owned Paths
- `src/shared/domain/` (Kit contracts, combat state definitions, weapon definitions)
- `src/client/presentation/CombatInputController.luau`, `CombatSandboxClient.luau`
- `src/server/application/CombatCoordinator.luau`, `src/server/infrastructure/SpatialQueryAdapter.luau`
- `tests/` (Gameplay unit and integration test specs)

## 3. Input Contract
- Kit specifications, skill behaviors, and balance tables from `game-design-lead` and `game-designer`
- Animation keyframe event definitions from `ANIMATION-VFX-CONTRACT.md`
- Network schemas and remote definitions from `systems-networking-engineer`

## 4. Output Evidence
- Production-grade Luau code passing `stylua --check`, `selene`, `luau-lsp analyze`, and `lune run tests/init.spec.luau`
- Comprehensive unit tests covering combo buffering, cooldown enforcement, cancelation rules, and damage deduplication
- Clean cleanup routines ensuring death, unequip, or disconnect immediately purges temporary actors and active hit callbacks

## 5. Quality Checklist
- [ ] Does all code pass strict typing (`--!strict`) and full linter validation without warnings?
- [ ] Are all server hit gates authoritative (validating range, obstacles, rate, and life state)?
- [ ] Does input processing cleanly ignore gameplay attacks while interacting with UI modals?
- [ ] Is multi-hit deduplication enforced (no target damaged twice by the same attack phase)?
- [ ] Does the implementation avoid self-certification (submitting all PRs to independent reviewers)?

## 6. Handoff Target
- `independent-code-reviewer` for code quality and test coverage review
- `security-anti-exploit-specialist` for exploit resilience verification (`COMBO-RBX-10`)
- `roblox-qa-tester` for functional combat verification in Studio sandbox
