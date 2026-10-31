# Cut commitment, shooting and low jump arms

2026-10-29 · Root implements personally after Owner grilling decisions1A/combined held direction/0.7s, then confirmed Shift/jump/no-input behavior and subsequent shot/jump adjustments. DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST. All work remains uncommitted; no independent acceptance or publish.

## Resulting behavior

- Sprint cut: full61 source frames compressed2s→0.7s. LowerTorso pitch bounded±16°, UpperTorso±12°; support-foot grounding retained. Short sprint-only fades0.05/0.07; legacy GoalReverse fades retained. Full original raw reference remains available.
- The active cut keeps its original direction/ball choreography through completion. Changing WA→WD stores the latest combined held direction; after completion it runs toward WD without queuing another cut. Shift release, opposite keys and ordinary cancel packets cannot abort an eligible carrier's committed cut. Real death/airborne/possession loss still invalidate it.
- Ball remains under the cut's validated trap/strike/exit guide until the0.7s end; no free-drift tail or invisible underlying run touches. Server continues accepted markers after Shift release and rejects early cancel/new cut/G mode. Completion metadata reports Complete. Existing body/cage sweep retained.
- Space during cut buffers one jump, consumed after completion; releasing/contradicting movement keys finishes the current cut then stops. A short settle window consumes intermediate key-up combinations after opposite keys so they cannot trigger an accidental second cut. Latest direction is overwritten, never an action queue.
- Shooting strength increased46–112→54–128stud/s. Charging can move, with server WalkSpeed8 matching G. Upper-body charge pose leaves pelvis/leg weights free for walking; Shift/rate-limit paths cannot raise the charge WalkSpeed. Existing ground-contact/charge/cooldown validation remains.
- Subsequent Owner animation-only request: shot playback1.25×, retain reference source0–0.7s only,22keys/0.56s. Contact0.24–0.29336s maps to the same authored foot poses. End spin/recovery source tail removed; BlendOut0.48 fades quickly. Strength remains54–128, unchanged by this animation refinement.
- Jump/landing arms lowered: shoulder pitch±8°, abduction12°, elbows25–40°. Other body/leg/reference rotations unchanged; same low arms apply to existing four-way lean. Scene Jump/Land and five sprint cuts refreshed with old versions saved under Cut07_WaistJump_Backup_20261029. Sprint-cut runtime now prefers authored source data over stale scene clips.

## Fresh targeted evidence

- Studio fresh Play requires/specs:366 timeline +28 cut intent +947 shot +22 shot intent +2898 jump checks passed. Cut/shot intent fixtures use isolated uninitialized BallService clones; cut fixture uses actual grounded Humanoid/root with isolated attributes to avoid live SprintService interference. Not a full strict typecheck or multiplayer regression.
- Actual keyboard WA→WD + Shift release: one cut; active direction stays on the original left cut while desired direction is right; new desired direction applies after completion, with no replay. Track length0.7.
- Actual opposite-key test on a fresh Play baseline: one cut, no premature end, final movement vector0, carrier retained. Earlier run exposed an extra cut during intermediate key-up combinations; settle handling added and the fresh case passed.
- Actual buffered Space: one jump at0.7141s after cut start, queued flag retained until completion then consumed once; normal self-lob/possession release follows airborne behavior. An instantaneous MCP keyPress did not exercise the intended held input; explicit70ms keyDown/keyUp did.
- Actual mouse shot:0.56s full track, ball contact observed0.2510s after server start; measured speed122.21 at power0.9309 (below configured128 maximum). Final quick-fade smoke completed, ShotActivefalse and no Action2 track left after recovery.
- Charging movement exercised with held mouse and W across MCP calls: server WalkSpeed8 and nonzero horizontal movement observed. Cross-call input arrived late (approximately4.7s), so movement reached2.95 before the existing5s charge timeout cancelled safely; full sustained8stud/s physical travel was not measured in that fixture. Do not interpret the timeout as a completed shot.
- Fixed-camera low-arm pose sheet inspected. Neutral hands approximately0.23/0.36stud below LowerTorso center; with±15° lean, hand offsets ranged approximately−0.81..+0.27stud. Temporary pose fixture removed.
- Initial stale2s scene cuts failed the new duration validator; replaced scene clips and made sprint-cut runtime source-backed. Edit MCP module caching also retained an old timeline during one check; fresh Play checks above passed. QA-only harness parse/input-position errors were corrected; they are not counted as product failures or successful tests.
- Existing BlenderAnimations plugin Packages errors and asset203785492 mismatch remain unrelated. No WSL.

Final gates FRESH: node prepare-sync-payload.mjs refreshed26entries; rojo build default.project.json -o .sandbox/cut-commit-shot-waist-final.rbxlx exit0; git diff --check exit0; independent disk/Edit readback26/26 exact; Studio Edit. Temporary preview removed. Owner visual/feel review remains pending.
