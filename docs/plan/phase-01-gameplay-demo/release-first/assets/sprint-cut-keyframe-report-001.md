# Sprint cut — sprint-cut.md / marker-driven ball timing

2026-10-29 · Root direct implementation under Owner request · **DONE_BY_IMPL / READY_FOR_OWNER_PLAYTEST**. No independent self-signoff, commit, push or publish.

Reference read-only: `C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\sprint-cut.md`, SHA256 `1960ac9419cc32c033b782e690416939ac098ca7828cc83b9d82d42eee2a116d`. Imported the complete61-frame/2-second segment,49 values/frame and15 joints, replacing the prior sampled reference. Root horizontal travel/accumulated heading remain game-controlled; poses are in-place and vertically grounded on the normalized rig. Five unique cut clips cover six existing bindings; ReverseLeft/ReverseRight still share one reversal clip. Walk/run/G poses preserved.

## Authored timing and ball behavior

| Source frame | Time | Marker / behavior |
|---|---:|---|
|4|0.1333s|BallTrap; left-pivot clip uses L, mirrored right uses R|
|8|0.2667s|TouchL/TouchR Strike; actual matching marker permits direction change/push|
|20|0.6667s|ControlRelease; free movement heading and ordinary ball tracking resume|
|54|1.8s|BlendOut; the visible cut returns to the running layer|
|60|2.0s|ClipEnd; one-shot cleanup/cancellation|

The reference foot selection was checked with actual-rig FK: at trap time, the left foot is approximately0.017stud from the ball surface at the authored2.55stud trap radius; right foot is2.103stud away. Thus the left foot traps/strikes in the base clip, and the right clip mirrors it. Marker placements are authored adaptations; they are not an engine mesh-contact detector.

- New shared DribbleCutTimeline defines phase validation, speed dip0.45 during plant and recovery by release. MovementHeading uses actual track time only while a sprint cut owns movement; SprintController/JumpService not rewritten.
- Client sends correlated cut IDs and Trap/Strike/Release intent. Server checks current character, carrier, ground, server-observed sprint, finite direction/ID, cooldown, active sequence, clip, foot, phase order and bounded time window. Duplicate/late/forged markers cannot restart or advance a cut.
- Removed the old36%-of-duration fallback for new sprint cuts: no real accepted strike marker means no fabricated strike. Unchanged GoalReverse retains its legacy path.
- Ball closes to the bounded trap radius2.55, stays on the entry line through trap, then receives a smaller marker-driven push/exit lead. Cut pulse boost reduced0.72→0.35, impulse11.5→4, maximum added lead0.45. New cut path retains normal body/cage sweep rather than the old body-circle bypass.
- Background run markers are suppressed on both client and server until the visible cut blends out at1.8, including the period after heading release. That period rolls from the last strike without invisible run-loop micro-taps. Cancellation clears the cut and remaining cut impulse.
- Actual RPC receipt probing reproduced W→S reversal arriving during a one-frame Sprint=false/WalkSpeed16 transition. Added **0.12s grace from server-observed sprint history**, not client timestamps; expires when sprint does not resume. Shift/menu/air/cancel guards remain.
- Full2s one-shot and existing track lock remain: heading/ball release is at0.6667; existing jump/new-cut guards still depend on the active one-shot until completion/cancellation. Human playtest should assess this2s commitment.

## Verification actually run

- Fresh actual Studio requires for changed animation/helper/controller/server modules passed. Rojo packaging and git diff --check passed. Dedicated strict typecheck/full regression not claimed.
- Public timeline spec: **366 checks passed**; final server-intent spec: **27 checks passed**, including timing, wrong foot/clip/sequence, duplicate start/marker, background run tap, cancellation/replay and expired sprint context. Tests live in `tests/animation/`. Server tests use an isolated BallService clone, a grounded live rig and a table identity; no fabricated Player/network grant. Setup attempts to create a Player/ground a clone were unavailable and are not counted as passes.
- Six bindings validate61keys each,2s, non-looped Action metadata; five unique sequences rebuilt. **14,520 exact non-cut joint samples unchanged** across eight clips in preflight.
- Actual keyboard MCP observed FrontLeft/FrontRight/BackLeft/BackRight/ReverseLeft tracks and Trap→Strike→Release. Front directions completed BlendOut/ClipEnd; back directions also exercised cancellation during recovery. Reversal was re-tested through full2s after the sprint-transition fix. ReverseRight's separate input route was not independently exercised; it uses the same reversal clip.
- Final left/right marker-role run completed both clips, correct L/R BallTrap and Strike, server phase acceptance and cleanup, no observed carrier loss.27-check validation rerun passed after final visual-marker suppression change.
- After-render observations: reversal ball/root distance2.4325..4.3661studs across31cut samples; back/cancel run2.8469..4.4653 across52samples. Pre-strike server offset stayed on entry line (dot approximately1). Raw independent server-root sampling also had distances as low as1.847 in one direction; do not treat this as blanket swept-body/mesh clearance signoff or erase prior geometry findings.
- Full reference FK can have crossed foot X coordinates in some sampled turns (minimum about-0.1764), while knee X gap stays positive; no claim that every foot/leg mesh pair is clear. Owner should inspect actual style and foot/ball contact.
- Local Studio latency only; multiplayer/latency, complete jump/death/respawn/focus matrix, production animation publishing and profiling NOT RUN. Existing unrelated asset203785492 type warnings were observed in earlier smoke rounds.

## Sync / recovery / handback

Updated8game source files: shared timeline/config, reference/data, helper, cut controller, heading controller, BallService. Generator/payloads/hash manifest refreshed. Independent final readback **8/8 exact**; Studio **Edit**. Prior five sequences preserved in `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.SprintCutKeyframe_Backup_20261029`.

During work, disk unexpectedly returned to the pre-task snapshot and the entire ignored .sandbox directory disappeared; Studio retained the new source. Owner confirmed no manual undo. Git reflog showed no reset; process inventory showed no standalone rojo process. Cause is **unattributed**, not claimed fixed. Recovered from captured/Studio source and saved `cut-keyframe-recovery.json` (9source files including the pre-existing untracked walking reference, plus2tests). A new probe and source files remained intact across subsequent Play start/stop cycles and final checks. No watcher/process was terminated or reconfigured.

Evidence in .sandbox: final client/server captures, reversal captures and intermediate full-direction captures. The durable recovery bundle is retained because of the workspace-loss incident. No new commit was requested in this turn; HEAD remains290726b and all new work is reviewable working tree.

Owner test: start a new Play, acquire ball, build Sprint first, then AW/WD/AS/SD or W→S. Look for brief plant, foot-led direction change, controlled roll and clean recovery; also try releasing Shift or opening the menu mid-cut. Visual acceptance remains Owner's.
