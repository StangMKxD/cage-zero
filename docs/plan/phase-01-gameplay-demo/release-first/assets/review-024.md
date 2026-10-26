# Review024 — AGY saved motion and camera preview

2026-10-26 · Codex Controller · animation draft STRUCTURE_TECHNICALLY_VERIFIED; camera CHANGES_REQUESTED; live idle PENDING_IMPLEMENTATION.

Owner accepts preliminary animation appearance and authorizes idle runtime integration in current session. This is not full RF02 approval or production asset verification.

## Independently checked
- Base HEAD 44c2810580a74727bf8eca7f5578576e14d4a516, protected existing dirty tree inspected.
- Parsed recipe JSONs and calculated SHA256 with PowerShell Get-FileHash: all five recipe hashes exactly match idle/walk-run report records. Each has 15 joint tracks. Idle 9 frames/4.8s; walk 33/1.12s; run 33/0.76s; jump 49/1.8s; land 29/0.84s.
- Roblox Studio read-only execute_luau (Edit) on connected Cage-Zero placeId 137721422246269 confirms exact canonical AnimSaves names, frame counts, duration (float tolerance), loop and priority for all five clips. Idle/walk/run loop; jump/land do not. Idle priority Idle, walk/run Movement, jump/land Action.
- src/client/character/R15AnimationController.luau remains a lifecycle/readiness controller, without custom idle playback; report correctly states no runtime animation wiring.

## Findings
- RF-F24 (medium, camera scope): CameraPreviewController.luau onCameraUpdate uses math.max(cfg.MinDistance, hit.Distance - cfg.CollisionMargin). If a wall is closer than MinDistance=3, the final camera can be placed beyond the hit, violating near-wall occlusion. OcclusionRadius config is unused, so thin ray also does not protect camera volume. Owner visual acceptance is preserved, but collision edge cases need a separate bounded correction/retest; not included in idle implementation.
- RF-F25 (medium, camera lifecycle): camera and movement setupCharacter yield without generation/current-character checks and bind CharacterAdded after initial yielding setup. Rapid respawn can leave stale references or miss replacement; suspendNativeControls task can Disable after Cleanup. Static causal risk identified, no live reproduction claimed. Separate camera follow-up.
- Runtime asset limitation: reports contain Motion UUID/local KeyframeSequences only, no published numeric AnimationId. Native Studio temporary registration cannot be used in published games. Explicit production configuration is required; idle contract records fallback and missing ID instead of inventing one.
- Jump clip includes anticipation/airborne/touchdown across 1.8s. Future runtime jump integration needs phase/state synchronization; owner preview acceptance does not prove matching live ballistic timing.

## Evidence limits
No Play, input capture, visual re-acceptance, cloud upload, Git commit/push or plan closure performed. External RobloxMotion.plugin.lua patch and transient accessory callbacks reported by AGY were not independently verified; no retrospective external-write authorization. Remaining audit file hashes, pose channel parity, multi-player replication, production permissions and live camera edge cases are unverified. Python executable unavailable; PowerShell checks used successfully.

Follow-up [idle-runtime-HANDOFF.md](idle-runtime-HANDOFF.md) authorizes only idle playback implementation and focused tests. Preserve accepted canonical clips and all existing work.