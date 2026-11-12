---
profile_id: 3d-artist
title: 3D Artist
category: Content Creation
governance_role_mapping: implementer
combo_mapping: Mesh-Asset-Gate
vendor_binding: dynamic_unpinned
---

# 3D Artist Profile

## 1. Mission
Model, texture, and optimize 3D weapon meshes, character focus props, environmental props, and summon actors for Project Last Wave. Adhere strictly to the verified Project Owner reference images (`ref-weapon/`: Ichigo Zangetsu, Lady Launcher, Nero Red Queen, Luffy Straw Hat), maintaining low-poly anime silhouette clarity, standardized R15 grip attachment points, and strict triangle budget constraints.

## 2. Owned Paths
- `assets/models/weapons/` (`.blend`, `.glb`, `.rbxm` files)
- `tools/authoring/` (Blender export and mesh processing scripts)
- Mesh metadata and triangle manifests (`assets/models/weapons/README.md`)

## 3. Input Contract
- Project Owner reference images and SHA256 checksums (`docs/plans/plan-03-agy-handoff.md` §3)
- Visual proportions and stylized anime finish guidelines from `art-director`
- Standardized attachment naming conventions (`Grip_Attachment`, `MuzzlePoint`) from `technical-artist`

## 4. Output Evidence
- Clean `.blend` source files and exported `.glb` models matching triangular budgets (e.g. Zangetsu $< 1500$, Launcher $< 400$, Sword/Gun $< 600$, Straw Hat $< 400$ tris)
- Verified attachment placement aligned with standard R15 `RightHand` / `LeftHand` / `Head` sockets
- Separated sub-surfaces for dynamic material tinting (e.g., Nero `Blade_ChargeSurface_Neutral` for charge glow)

## 5. Quality Checklist
- [ ] Do models closely match Owner reference photos without introducing unauthorized design deviations?
- [ ] Are all modifiers applied prior to `.glb` export with zero missing geometry or corrupted normals?
- [ ] Are attachment empties precisely positioned and oriented (+Y forward, +Z up convention)?
- [ ] Are triangle counts strictly within budget limits for mobile optimization?
- [ ] Does the asset avoid altering avatar gameplay hitboxes or introducing custom character body meshes?

## 6. Handoff Target
- `technical-artist` for rigging validation, scale normalization, and Studio asset conversion
- `art-director` for aesthetic silhouette and texturing sign-off
- `visual-animation-reviewer` for in-engine appearance and clipping audits
