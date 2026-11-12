# Automatic Role Routing Rules

## 1. Overview
This document defines the automatic routing logic used by the **Orchestrator** and **Roblox Team Lead** to classify incoming task requests and dynamically dispatch work to specialized AI agents.

Reference: [docs/workflows/roblox-agent-workflow.md](../../docs/workflows/roblox-agent-workflow.md)

---

## 2. Task Intake & Classification Matrix

| Task Category | Primary Triggers / Keywords | Assigned Specialists | Mandatory Independent Reviewers |
|---|---|---|---|
| **Sandbox Prototyping** | "ทดลอง", "Prototype", "Sandbox", "Combo", "Kit" | Game Designer, Gameplay Engineer, Animator, VFX Artist, Technical Artist | Independent Code Reviewer, Visual/Animation Reviewer |
| **Combat Engineering** | "Combat", "Hitbox", "Damage", "Cooldown", "Stun", "M1" | Gameplay Engineer, Systems/Networking Engineer | Independent Code Reviewer, Security Specialist (if remote exposed) |
| **Animation & Rigging** | "Animation", "R15", "Keyframe", "Pose", "Attack Anim" | R15 Animator, Technical Artist | Visual/Animation Reviewer |
| **Visual Effects (VFX)** | "VFX", "Particle", "Aura", "Beam", "Impact", "Slash" | VFX Artist, Technical Artist | Visual/Animation Reviewer, Performance Specialist |
| **Technical Art Integration**| "Attachment", "Socket", "Bone Sync", "Camera Shake" | Technical Artist | Visual/Animation Reviewer, Gameplay Engineer |
| **UI / HUD** | "HUD", "Cooldown Icon", "Health Bar", "Menu", "UI" | UI/UX Designer, Gameplay Engineer | Visual/Animation Reviewer, Code Reviewer |
| **Audio / Sound Design** | "SFX", "Audio", "Hit Sound", "Combat Music" | Sound Designer, Technical Artist | Team Lead |
| **Production Integration** | "นำไปใช้จริง", "Integrate", "Production" | All Disciplines (14-Step Workflow) | Independent Code Reviewer, Visual Reviewer, QA Tester, Security Specialist |

---

## 3. Dynamic Team Formation Rules

1. **Minimal Sufficiency:** Never instantiate unnecessary roles. A pure animation tweak task does not spawn a Systems Engineer or Security Specialist.
2. **Strict Reviewer Separation:** The agent acting as **Independent Code Reviewer** or **Visual/Animation Reviewer** must NEVER be the agent that implemented the code or asset.
3. **Escalation Path:**
   - Any task involving `RemoteEvent`, `DataStore`, or currency must route through `Security/Anti-Exploit Specialist`.
   - Any task emitting continuous particles (>100 particles/sec) or running per-frame Heartbeat loops must route through `Performance Specialist`.
4. **Tool/Harness Inavailability Fallback:** If live Roblox Studio cannot be automated or is unavailable, tasks must tag results with `STUDIO_NOT_TESTED` and proceed via pure Luau unit harnesses. Agents must NEVER simulate fake test runs.
