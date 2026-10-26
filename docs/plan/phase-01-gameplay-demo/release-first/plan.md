# Cage Zero — Phase 1 Release-First: Street Football

2026-10-26 · Plan Owner Stang · Planner/Reviewer Codex · OWNER_STANDARD
Baseline: 44c2810580a74727bf8eca7f5578576e14d4a516 + protected dirty tree (locomotion/camera/sprint). Implementer for future tasks: ยังไม่มอบหมาย; active checklist7 uses separate acknowledged AGY. Session trace: Owner conversation 2026-10-26; per-task direct Herdr ACK. Status/ownership: [RF-02/tasks.md](RF-02/tasks.md), the single live board.

**Authority:** Owner requested this design, answered Q1–Q9, moved excess to Phase 2, explicitly kept RF-04 walls BEFORE Super, and authorized committing completed docs plus implementing checklist7 dribble/receive plus later explicit higher momentum jump/four-way airlean and relevant locomotion fixes now. This document is a reviewable plan; it is not blanket permission to implement all later tasks, commit source or publish. Historical approvals/findings retain their scope. Prior plan snapshots: [history](assets/plans-before-street-20261026/plan.md).

## Product and Phase 1 finish line
Casual 2v2 street football in Stadium A (4 walls + roof), normalized ROBLOX Boy R15 with personal appearance, manual aim and real ball interaction. Finish base play, legal contact, HP/stun, gauge/orbs, wall gameplay, six Supers, a small gauge-only upgrade and complete match loop in Phase 1. Foul/free kick/yellow-red cards/penalty shootout/regular extra time are REMOVED from target, not deferred for automatic return. Legacy source stays inert until a separately approved removal manifest; old references are historical.

## Confirmed requirements
| Area | Phase 1 rule |
| --- | --- |
| Street contact | Kick opponent = brief flinch/balance loss, never possession loss, including HP-zero kick. Successful slide = fall + loose ball. Poke/block/manual normal body-check included; normal body-check can miss and uses validated contact, no auto-possession. |
| HP | Separate CombatHP from Humanoid.Health; no combat death. Config MaxHP/damage/regen delay/rate; zero -> stun 1–1.5s (config) -> recover HP. Lifecycle death remains lifecycle, not street damage. |
| Protection | Shared short victim invincibility after kick/knockdown/stun; protected hit gives no damage/stun/gauge. Ball remains contestable: I-frame protects player contact, not ball or possession. Repeated legal kicks of same victim after protection are allowed. |
| Gauge | 0..100; valid kick/slide/intercept/ball-play events plus Gauge Orb. Victim kick gain strictly greater than attacker's before clipping; cap/rounding can equalize displayed values at100. Real new hits allowed; no reward from same action/contact twice. |
| Orbs | Replace pickup concept with server-spawned ground AND airborne Gauge Orbs, bounded arena positions/lifetime/count. Player or ball contact collects atomically once; ball awards server-verified latest toucher within attribution window. Unknown attribution does not collect; no shared team grant. |
| Super loadout | Equip exactly one of six BEFORE match; frozen at kickoff, no in-match swap. All manual aim, missable/interceptable, no homing/auto-aim/guaranteed goal. |
| Timed Super | Gauge100 -> arm spends100 immediately; one use within config deadline. Miss/expiry costs gauge, no refund; no earning while armed. Execute consumes single-use token once; effect duration separately config (Frost area/flight/rush), not a second reusable mode. Invalid execute cannot grant another activation. |
| Six Supers | Curve Master (more curve), Power Shot (more impulse), Frost Zone (aimed area, brief freeze with escape/telegraph), Overdrive (aimed speed burst), Breaker Rush (upgraded body-check: strong visible knockback), Knuckle Shot (server-seeded bounded ball wobble). Normal body-check exists independently of Breaker. |
| Counterplay | Telegraph/windup/recovery/range/force/duration config. All contact effects respect same I-frame. Breaker knockback bounded by collision/arena safety; no throwing through wall or unbounded stun. No targeting lock even for Frost/Knuckle. |
| Upgrade | Cancel Super Mastery power scaling. Earned Cash-only upgrades on selected character copy; no duplicate consumption/random success. Increase ONLY gauge earn multiplier with hard server cap. No stronger/longer Super, no stat or stamina discount, no I-frame bypass. |
| Match | Regulation configurable (initial existing target3min); if leading at expiry, finish. Tied -> GOLDEN_GOAL, next valid goal wins, no regular extra-time clock or penalties. Aborted match from disconnection/server shutdown cannot invent winner or duplicate rewards. |
| Numbers | Every balance number/duration/cap/range/count/sampling rate/cost in versioned config, including100 gauge threshold and1–1.5 stun interval. Values are tuning targets, not proven balance. |

## Order and feature-sized tasks
One task is a complete feature across server/client/config/UI/tests, not a horizontal technical layer. Target one focused working day per task with Owner tuning; estimates are not a promise. Six Supers deliberately remain ONE task with six internal acceptance checks. If day target is exceeded, freeze/report remaining checklist and agree continuation; never weaken gates or silently omit a Super. No automatic scope expansion.

| Task | Plan / visible outcome | Depends on | Acceptance / first-day scope |
| --- | --- | --- | --- |
| T01 | RF-02 Close five-clip locomotion/camera/sprint checkpoint | current tree | Owner visual accepted; resolve technical review findings and verify lifecycle; Dash not falsely claimed implemented. |
| T02 | RF-02 Dribble and receive (checklist7, ACTIVE AUTHORIZED) | foundation; retain T01 follow-ups | Contact/timed touches, no glue/teleport, competitor can steal, config ready for Owner tuning; later Owner delta adds high momentum jump/4-way airlean and prior jump fixes on same writer. [contract](assets/dribble-receive-HANDOFF.md) |
| T03 | RF-02 Manual pass/shoot/curve and basic aerial finish | T02 | Finite 3D aim/charge, real contact, volley/whiff, server impulse; no auto-pass/goal. Advanced aerial hold/trajectory deferred. |
| T04 | RF-02 Normal dash/stamina and basic control polish | T01,T02 | Directional dash can miss; stamina/recovery config; move arbiter ready for knockback/freeze. No dribble-special skills. |
| T05 | RF-03 Street combat/HP/normal body-check | T02,T04 | Kick preserves possession; slide knocks down/releases; poke/block/normal rush; HP/I-frame/idempotent accepted hit pipeline. |
| T06 | RF-03 Gauge and ground/air Orbs | T03,T05 | Real event rewards, victim>attacker, same-victim new hit allowed, no duplicate hit/orb reward; capped multiplier hook. |
| T07 | **RF-04 Wall Run/Wall Launch** | T03,T04,T05 | Existing Owner checklist wall -> launch -> receive/shoot with counterplay; integrates protection/ball contact without new I-frame. MUST precede T08. |
| T08 | RF-05 **All six Supers as one feature** | T06,T07 | Arm/execute/expiry/loadout; six effects + counterplay; Breaker knockback and Knuckle share server ball/contact APIs; no homing. |
| T09 | RF-05 Small profile/loadout/gauge-only upgrade | T08 | One free baseline copy, six selectable Supers, earned Cash upgrade cap, durable debit+upgrade/result; reconnect/retry same result. No gacha/13 stats. |
| T10 | RF-06 2v2 match / Golden Goal / rewards | T03,T05,T08,T09 | Join/kickoff/score/regulation/tied-GG/end/reset; atomic goal/winner/reward; disconnect cancellation policy. |
| T11 | RF-06 Minimal HUD / tuning feedback | T06,T08,T10 | HP/stun/I-frame,0..100 gauge,orb credit,armed timer/one Super,score/GG/team; Shift sprint/Alt capture preserved. |
| T12 | RF-07 Combined 4-player security/performance/Owner release gate + doc sync | T01..T11 | Latency/contests/spam/reset/reconnect, regression and budget measurements; production animation IDs permission verified; Owner publish only. |

Implementer for T03..T12: ยังไม่มอบหมาย; Controller/Reviewer Codex. All pending until bounded authorization. T02 is user's explicit exception, not wait for every later task. Do not block T02 solely on unrelated old camera findings; track relevant lifecycle risks.

## Architecture and actual repository seams
Detailed evidence, service contracts, configuration, event ordering and tests: [street-football-design.md](assets/street-football-design.md). No source changes from planning. Owner later authorized higher momentum jump/four-way airlean on the SAME checklist7 AGY; future shooting/pass aim tuning remains deferred to T03. Reuse existing central ball solver; no second competing physics loop. Separate authoritative HP/gauge/Super state from animation and personal appearance. Publish state snapshots/events; clients predict presentation only.

## Phase 2 / removed scope
Deferred: 3 special dribble skills (Heavy Knock-On/Open Up Fake Shot/Body Feint), extra four catalog skills, gacha/3 distinct characters/13 gameplay stats/16-trait catalog (3–4 active later), advanced aerial contact-hold/trajectory visualization, training mode, additional arenas/events, ranked/GK AI/larger teams, cosmetic shop/Robux products, awakening/stat allocation/stamina upgrade systems, trading/FX/replay. Their reusable schemas remain references, not implemented.
The accepted advanced aerial/GK design is not revoked, only delivery deferred. Phase2 13-stat variants conflict across old RF05 and data-schema: choose one canonical catalog before implementation. Traits that auto-guide passes/guarantee finishes must be redesigned or remain disabled; they cannot bypass new manual/counterplay contract.
REMOVED, no auto Phase2 return: fouls/free kick/cards/penalties/regular overtime and Super Mastery power progression. Prior upgrade stat/stamina benefits superseded by gauge-only target.

## Approval / completion
Plan decisions accepted by Owner Q1–Q9 plus latest scope corrections; future task dispatch still explicit. Owner authorized docs commit on2026-10-26. Each task ends Working Tree + actual checks + review; no autonomous source commit/push/publish. Full RF02/Phase1 and legacy00/01 remain open until their actual gates. Local plan commit does not certify game ready. Owner checklist must distinguish visual acceptance from technical verification.