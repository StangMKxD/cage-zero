# Pre-Idle foundation review018 — commit gate

2026-10-25 · Codex · **CHANGES_REQUESTED**. Owner explicitly authorizes local commit once scoped review passes, before Idle begins. No commit/push by AGY; no automatic Idle authoring until Controller COMMIT_DONE. No Git commit has been made by this review.

Reviewed ref HEAD25a67d5575e31034a5a08290873b9c401357d33a + current R15/Boy/height source working tree (height task still in progress; not a frozen final delivery). Source hashes at review:
- R15AvatarService: `7491847869063ad2de7b51f549f9fb089efccd0a0424f7bec7f31abdb43a8640`
- R15AnimationController: `0749de448a242da68db8ab43ab64d21fd04c7474a9f9623650c53557da198eaa`
- R15AvatarConfigs: `6b773271d3e91287509165e98a029a90ae4c9d91a4e3d68bf0fe731626c37dda`

## Blocking findings — OPEN

### RF-F21 / HIGH — Server spawn has stale-request and prior-character lifecycle gaps
R15AvatarService disconnects characterConnections at spawn entry before fetching/validating a replacement. A failed model fetch/validation leaves the previous character but removes its death-respawn listener. After GetHumanoidDescriptionFromUserIdAsync returns, it updates lastValidatedDescription before checking generation/player membership; a late request can repopulate cache after leave or overwrite newer request state. The only generation check is after the second yielding call. Keep current character's lifecycle intact until a validated replacement is committed; check current player+generation after every yield and before any shared state/cache write or replacement. Clean superseded descriptions/candidates/connections safely. Only commit cache after valid identity/model path, not a mere pre-validation fetch result. No R6/blank fallback.

### RF-F22 / HIGH — Client ready state can point at removed/stale R15 character
R15AnimationController caches currentHumanoid/currentAnimator without CharacterRemoving/death invalidation or generation checks around WaitForChild yields. IsR15Ready only checks cached rig type, so after removal it may return true for a destroyed character or an older callback may overwrite a newer character's animator. Track exact current character/generation, invalidate on removal/replacement/death, reject stale callbacks after yields and require current valid Humanoid+Animator parentage before readiness. Capture the current character in a local before task.spawn, not a mutable LocalPlayer.Character read inside delayed closure. Preserve existing controls/no custom Idle work.

### RF-F23 / MEDIUM — Avatar acquisition retry is unbounded/inconsistent
Initial description failure recursively retries every3s forever, while model-creation/validation failure just returns with no recovery on first join. Use one bounded, lifecycle-aware retry/backoff path and explicit non-gameplay failure state for both acquisition phases. Do not add UI/screens or install tooling. Retain last valid appearance/lifecycle if present; no stale retry after departure/replacement. Retry policy is a technical safeguard, not new gameplay. Record limit/backoff and tested/unverified outcomes honestly.

## Fix contract / verification / freeze

Existing R15 handoff permits these in-scope lifecycle corrections in R15AvatarService and R15AnimationController, plus necessary config for retry bounds. Finish height report, then include one assets/r15-lifecycle-fix-001.md with exact changed files/hashes and actual source/Studio evidence. Narrow sync and bounded existing respawn/readiness/failure checks authorized; no old test-suite claims or fabricated failure injection. Preserve backup/protected files, no gameplay/Idle/Git/new agents/Argon.

After delivery send SOURCE_FROZEN with final source hashes,report path,target/mode/source parity; then stop editing. Codex independently re-reviews current diff and parity before staging any exact file list. Exclude Argon Idle draft/exports/reports from foundation commit and do not stage all dirty files blindly. Historical pending findings and visual approval remain pending; committing a reviewed checkpoint does not close RF02/Plan00 or approve Idle.
