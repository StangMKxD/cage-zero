---
profile_id: systems-networking-engineer
title: Systems / Networking Engineer
category: Engineering
governance_role_mapping: implementer
combo_mapping: Systems-Network-Gate
vendor_binding: dynamic_unpinned
---

# Systems / Networking Engineer Profile

## 1. Mission
Architect and maintain robust, high-performance client-server networking, remote event routers, persistence adapters, and world lifecycle coordinators for Project Last Wave. Implement replay-safe, rate-limited network protocols (`NetworkRouter.luau`, `CombatRequestValidator.luau`), profile data store wrappers (`ProfileStore` adapter), and multiplayer state replication. Enforce zero client trust across all remote interfaces.

## 2. Owned Paths
- `src/server/infrastructure/` (Network routers, request validators, spatial queries)
- `src/shared/network/` (Remote definitions, packet payloads, serialization schemas)
- `src/server/CombatSandboxServer.luau`, `src/server/infrastructure/ProfileServiceAdapter.luau`
- `tests/network/` (Adversarial network simulation tests)

## 3. Input Contract
- Remote payload requirements and action intent types from `gameplay-engineer`
- Data persistence and session lifecycle requirements from `docs/architecture/data-lifecycle.md`
- Security guardrails from `security-anti-exploit-specialist` (`COMBO-RBX-10`)

## 4. Output Evidence
- Strict rate-limiting and schema validation preventing spoofed, malformed, or out-of-order network calls
- Safe profile loading and session locking routines with idempotent Developer Product receipt processing
- Clean network serialization benchmarks minimizing replication bandwidth during wave combat

## 5. Quality Checklist
- [ ] Are all RemoteEvents strictly validated on the server for argument count, types, and value bounds?
- [ ] Is client replay protection active (rejecting duplicate action requests or timestamp drift)?
- [ ] Are persistence operations resilient against server crashes with zero duplicate grants?
- [ ] Is transient match data strictly isolated from cross-match persistent profile data?
- [ ] Does the network architecture operate without any client authority over health, cash, or unlocks?

## 6. Handoff Target
- `security-anti-exploit-specialist` for remote tampering audits (`COMBO-RBX-10`)
- `performance-specialist` for network replication and bandwidth profiling (`COMBO-RBX-11`)
- `independent-code-reviewer` for architectural compliance review
