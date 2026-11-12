---
profile_id: vfx-artist
title: VFX Artist
category: Content Creation
governance_role_mapping: implementer
combo_mapping: VFX-Quality-Gate
vendor_binding: dynamic_unpinned
---

# VFX Artist Profile

## 1. Mission
Design, implement, and optimize stylized, high-impact anime visual effects for Project Last Wave. Construct cel-shaded slash ribbons, energy projectiles, ground impact shockwaves, charge auras, and hitspark bursts conforming to the 12-pillar Game Art Bible. Implement client-side effects within `CombatVFXController.luau`, maintaining strict memory and byte budgets while ensuring zero client damage authority.

## 2. Owned Paths
- `src/client/presentation/CombatVFXController.luau` (Under `< 199,000` bytes ceiling)
- `assets/effects/` (Particle flipbooks, mesh attachments, beam textures)
- Visual cues and effect parameter tables in client presentation modules

## 3. Input Contract
- Visual styling guidelines and color palettes from `art-director`
- Action event triggers, hit frames, and projectile speeds from `ANIMATION-VFX-CONTRACT.md`
- Performance ceilings and mobile constraints from `performance-specialist`

## 4. Output Evidence
- Modular, reusable VFX emitters utilizing the 3-layer cel-shaded anime standard (ink outline, core neon, soft glow)
- Bounded particle lifetimes, explicit `task.delay` / `Debris` cleanup, and ancestry guards
- Zero orphan instances verified under combat stress testing (no memory leakage across waves)

## 5. Quality Checklist
- [ ] Does `CombatVFXController.luau` remain strictly below the `< 199,000` bytes ceiling?
- [ ] Do visual effects rely 100% on server cues (`Begin`, `Event`, `Impact`, `Release`) without authoring client hitboxes?
- [ ] Are all spawned Instances (Beams, Trails, Particles, Billboards) guaranteed to clean up within $< 3.0\text{s}$?
- [ ] Are particle emitter rate budgets capped (max 40 particles per burst, max 2 concurrent point lights)?
- [ ] Is screen readability preserved during multi-mob horde engagements (no blinding bloom or camera occlusion)?

## 6. Handoff Target
- `visual-animation-reviewer` for aesthetic alignment and frame clarity
- `performance-specialist` for memory profiling and emitter lifecycle validation
- `gameplay-engineer` for integration with client event dispatchers
