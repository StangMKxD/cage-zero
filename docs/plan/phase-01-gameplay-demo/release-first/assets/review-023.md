# R15 Idle draft — Review023 / Owner visual acceptance

2026-10-25 · Codex · **OWNER_VISUAL_ACCEPTED / CANONICAL_DRAFT_STRUCTURE_VERIFIED**.
Owner explicitly confirms ผมเช็คแล้ว idleผ่านแล้ว. This accepts RF02_Idle_Ready_R15_v01 preview, not other animations or a runtime integration/published asset.

Baseline9fbce58eb90ed6b7e6a39b00a5744455ee639811. Report001 SHA256 `0458a94f2dcddf4cb6eaacc1dc4af377f4f466b5ec5eea8f8de3217bd52c792a`.
Reviewed artifact SHA256:
- recipe `37ea4e018e18699feea9de74528dc804983c35ec960cb8caade2932a8ea0f607`
- audit `3da389fc2c1e7625fef250c3242f7a44c31b8a8a2a5dbbf2ebed73e586c318ff`
- preview-before backup `853886d324f38ba656e38dcf03b63af51c26b4c98ffcd19b5d4a3059c7a0bf2e`

## Independent structure checks

Recipe parses with15joint tracks,9keys each,4.8s loop,Idle priority,no Root track. First/last poses equal for all15tracks. Read actual native KeyframeSequence at Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves.RF02_Idle_Ready_R15_v01:9frames,144poses,5markers,Looptrue,PriorityIdle,duration4.80000019,all9HumanoidRootPartPoseweights0,first/last poses+CFrames/weights identical.

Owner accepted the actual akimbo/head-and-chest scan/playful foot-tap style. Head and UpperTorso are animated, so future look-at-ball/aim layers must explicitly blend/mask these channels instead of concurrently overwriting them. Camera orbit alone need not modify pose joints; movement/shot-facing belongs to its own heading controller. Do not modify accepted Idle to make camera code easier without Owner review.

## Provenance / limits

- Motion library UUID b8e4f7b0-b0fe-4cd6-96d7-33947eda2a87 is NOT a published Roblox numeric animation ID. The clip is a local recipe/native sequence; game integration/export permissions are a separate task. Do not use UUID as rbxassetid or assume it is installed as live-player Idle.
- Report preflight hashes6b773.../749184... reflect an earlier source revision, not the final lifecycle hashes already committed9fbce58. Source unchanged-by-Argon does not mean those are current hashes. Report's config BALL.Diameter reference is descriptive; actual ball sizing comes from Constants. None of these prose fields is used as current source-parity evidence.
- Reported54old external Motion-library removals are outside this draft-only contract's write list. Their exact deleted inventory/recovery has NOT been verified in this review; this verdict covers only the accepted new clip/artifacts and does not retrospectively authorize external/global cleanup. Preserve existing archive/history and do not perform more external deletes.
- Canonical exact9frame saved path above is authoritative; a5frame viewport-cache sequence with the same name also exists. Do not accidentally load the cache when integrating/exporting the approved clip.

Local commit of these3JSON artifacts,report,Owner-acceptance handoff/review allowed under standing checkpoint permission. No active-player integration,newposes,asset upload,Git push or automatic camera implementation. Argon stays stopped; no further prompt/pose iteration needed.
