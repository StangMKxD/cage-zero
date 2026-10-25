# Gate1 Discovery — Review011

2026-10-25 · Codex · **CHANGES_REQUESTED — remaining cleanup boundaries only**.
Ref HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + docs. Discovery004 SHA256 `e2969e35a67dd69ecd0bf8831843056ad73ffcb609828e06bd299e0bdbb4fa60`.
All64 source/doc fingerprints match; focused checker47 markdown/175 links SUCCESS; source/tests status empty. No app tests/Studio/Git mutation. No further Argon assignment.

## Stable findings

- **RF-F11 OPEN / narrowed to BallService range evidence:** three Types fields corrected. But manifest says L2550–2851 is a free-ball block to preserve intact. Actual L2550 is still possession dribble touch impulse; possession branch continues through2721, with tackles/off-balance changes around2690–2718. Free/InFlight branch starts `else`2722/comment2723. Even that branch includes legacy interception/auto-possession and inFlightAction variants around2775–2828. Correct these exact classifications; do not reclassify whole blocks from approximate headings. Unclosed branches must be treated as one function adaptation, not raw line deletion.
- **RF-F12 OPEN / remaining symbol closure:** deleting player-state processing/providers while retaining old collection/interception code still leaves state references. Show the retained free-ball solver/part-sync statements and their exact dependencies separately from all player possession/tackle/collection logic. Player-state/helper retention must match that chosen scope. Existing source evidence demonstrates BallAction router removal; do not claim complete closure until these inner references are mapped.
- **RF-F13 OPEN / unauthorized new-gameplay postcondition:** manifest§5.1 promises normalized R15 after cleanup, contradicting stop-before-new-runtime. Cleanup leaves existing rig foundation unchanged; R15 begins only after later Owner approval/Idle direction. Manifest§3.2 introduces simplified fixed1.8-stud dribble plus new clean movement/character lifecycle behavior. Those are gameplay adaptations, not automatically authorized cleanup invariants. Separate (A) legacy removal/necessary syntactic wiring changes from (B) later new gameplay/Idle/R15 work. Do not silently preserve or implement a newly simplified dribble system as foundation. If runnable ball foundation requires a choice about possession collection, mark it explicitly pending in the proposed cleanup contract rather than inventing behavior.
- RF-F14/RF-F15 retain scoped verification from review010. All implementation remains stopped.

## Required focused correction

Update only manifest's BallService inner partition, retained dependency subset and immediate post-cleanup state plus RF02 pointers and one discovery-report005. No new full manifest rewrite or Argon scan. Distinguish actual existing behavior, future adaptation proposal, and Owner decision; no fabricated numeric thresholds or pass claims. Keep uncertain files excluded. Before proposing actual deletion, present concrete scope without promising R15/new dribbling during cleanup. Source/history read-only; no tests/Studio/Git/code/Idle work. Auto push-report, no monitoring.
