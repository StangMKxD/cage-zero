# Quality Gates Specification

## 1. Overview
Quality gates ensure high-standard production assets and robust Luau code. Every task must pass through the appropriate discipline gates before reaching the Orchestrator or the Project Owner.

Reference: [docs/workflows/roblox-agent-workflow.md](../../docs/workflows/roblox-agent-workflow.md)

---

## 2. Gate Definitions by Discipline

### 2.1 Gate QG-GAMEPLAY (Gameplay Engineering)
- **Input Responsiveness:** Sub-frame simulated input handling (<16ms).
- **Combo Buffer Window:** Validated non-zero window for chained attacks (e.g. 0.25s–0.45s).
- **Hitbox Integrity:** Spatial query or box cast bounds verified against character reach.
- **State Cleanup:** Ability interruptions (stun, knockback, death) unconditionally reset attack state.
- **Pure Luau Test:** Zero runtime syntax or type errors in pure Luau test runner.

### 2.2 Gate QG-ANIMATION (R15 Character Animation)
- **R15 Bone Schema:** Keyframes target only standard R15 limbs; zero invalid bone names.
- **Joint Deformation:** Keyframes do not cause joint disarticulation or unnatural stretching.
- **Pacing & Readability:** Clear anticipation (windup), hit apex, and recovery follow-through.
- **Event Markers:** Standard chronological order: `HitStart` <= `HitActive` <= `HitEnd`.

### 2.3 Gate QG-VFX (Visual Effects & Particles)
- **Readability:** Visual effect does not mask combat telegraphs or player hitboxes.
- **Particle Budget:** Max 50 particles per standard M1 hit; max 200 for finisher/skill bursts.
- **Memory & Cleanup:** Every ParticleEmitter or temporary light has explicit lifetime and `Debris` cleanup.
- **Theme Consistency:** Color palette matches anime combat art direction (e.g. Gold/Cyan for Ki).

### 2.4 Gate QG-TECHART (Technical Art & Sync)
- **Marker Alignment:** VFX and audio trigger events occur in exact synchronization with animation apex.
- **Attachment Anchor:** Effects spawn from valid attachments (`RootAttachment`, `RightHandAttachment`).
- **Camera Shake:** Controlled duration (<0.25s) and amplitude (<1.5 studs) to avoid player disorientation.

### 2.5 Gate QG-SECURITY (Security & Server Authority)
- **Authority Rule:** Client sends intent only (`RequestM1`); server validates cooldown, distance, and stamina.
- **Sanitization:** Server never trusts client-supplied damage, target IDs without raycast validation, or currency.

### 2.6 Gate QG-REVIEW (Independent Review)
- **Separation:** Independent reviewer must be a different role/agent instance from the implementer.
- **Sign-off:** Must produce a documented verdict: `PASS`, `CHANGES_REQUESTED`, or `REJECTED`.

---

## 3. Honesty & Environment Tagging
- If a gate requires live Roblox Studio execution but the test harness ran headless in pure Luau, the status MUST be recorded as `STUDIO_NOT_TESTED`.
- Never claim `VERIFIED` on live engine behaviors without verifiable engine execution output.
