# Jump / apex / landing reference integration

2026-10-29 · Root implements personally under direct Owner instruction. DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST; no independent acceptance, commit, push, publish or plan closure.

## Reference and behavior

- Owner file `C:/Users/Stang/OneDrive/Desktop/stang/cage-zero-dev/animation/jump.md`:91frames/3s/15joints, SHA256 `05965eb19bcae16abcc45548eec49d286fb555d450a124104a289ea002c34a08`.
- Preserve all source joint rotations. Split into Jump0–1.5s and Land source1.5–3s,46keys each, Action/non-loop. Runtime launch starts at source0.9s; source1.2667 is the apex pose; source1.4667 is the descent hold, before the end of the flight clip. Root travel/height are owned by existing Humanoid flight; support-height compensation is baked only into landing poses.
- Sample the flight track in PreAnimation from actual vertical speed. Rising Freefall continues rising pose; near-apex ±6stud/s holds source1.2667; descent cannot reach landing early. Ledge fall skips launch/apex to the fall hold. Play precedes TimePosition/AdjustSpeed(0).
- The same complete reference pose supports neutral/left/right/forward/back lean through existing AirMovementController root attachment/C0 overlay. No new yaw turn, speed/height/momentum/gravity/ball-lob tuning; AirMovementController and JumpConfigs unchanged.
- Land starts on a grounded state with FloorMaterial support. A real-input test exposed transient Landed/Running while FloorMaterial remained Air; the animation now retains flight until actual support and observes FloorMaterial changes. Prior landing overlay fades out within0.02s on a new liftoff. Moving can blend out landing after0.18s without movement stun; stationary recovery retains the reference.
- Scene Jump/Land sequences replaced in AnimSaves; previous versions preserved in `PreviewRig_R15_Boy_Height30.JumpReference_Backup_20261029`. Runtime helper builds the source-backed two clips, so scene-only sync cannot silently restore old animation. Idle/Walk/Run source clips retained.
- Shared R15PoseSupport now contains the existing canonical support/FK math used by shot and landing. Shot's full947 checks reran successfully after extraction.

## Guidance actually read through Roblox MCP

Called list_skills and skill(`rbx-docs-search`); no dedicated animation skill was listed. Used official [AnimationTrack](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack), [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService), [task scheduler](https://create.roblox.com/docs/performance-optimization/microprofiler/task-scheduler), and [HumanoidStateType](https://create.roblox.com/docs/reference/engine/enums/HumanoidStateType) guidance for track positioning, PreAnimation ordering and real landing detection. No WSL.

## Actual checks

- JumpReference.spec:2898 checks after final apex hold change. Includes all reference rotations in flight/grounded adapters, monotonic bounded phase sampling, ±6 apex hold, passive fall, split lengths/key counts and non-loop metadata. Fresh client helper/controller requires succeeded. Not a full strict typecheck.
- Actual real keyboard jumps: neutral,A,D,W,S,546 sampled frames. Correct authored Action track length1.5, speed0, weight1 at apex; zero incorrect jump metadata and zero weighted Land frames while FloorMaterialAir/rootY>5. Lean reaches approximately±0.2616rad (15°) on both pitch/roll axes.
- Final exact-apex follow-up: actual left lean retained approximately0.261rad while four sampled apex frames used source1.2667 exactly. A transition sample can precede PreAnimation by one frame.
- Passive drop fixture:11 falling frames held source1.4667 with no wrong time; landing observed. Two initial phase-attribute samples still said Land from the preceding grounded recovery before the Freefall observer ran; those attributes alone are not counted as new landing-track triggers.
- Independent landing FK against actual Studio rig C0/C1/foot sizes:46 source frames, lowest support-foot bottom0.015095–0.019230stud above reference floor.
- Fixed-camera five-pose apex screenshot inspected through MCP. Initial heavy full-rig preview timed out; replaced with a slim951-instance pose fixture, captured all five poses and removed the temporary fixture. Owner visual/feel acceptance remains pending.
- Existing BlenderAnimations plugin Packages errors and asset203785492 mismatch remain unrelated. Multiplayer/production asset publishing not claimed.

Final gates FRESH: node prepare-sync-payload.mjs refreshed25entries; rojo build default.project.json -o .sandbox/shot-jump-final-build.rbxlx exit0; git diff --check exit0; independent disk/Edit source readback25/25 exact. Final Studio mode Edit. Temporary pose fixtures removed. All work remains uncommitted; Owner feel review is pending.
