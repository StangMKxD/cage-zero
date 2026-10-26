# Street Football — Technical Design

2026-10-26 · Codex · Design only; future implementation follows bounded task authorization.

## Repository evidence

| Observed seam | Verified fact | Plan implication |
| --- | --- | --- |
| src/server/init.server.luau | Starts Network/CagePhysics/R15Avatar/Ball/Sprint only | Legacy Match/FreeKick/Parry files are not proof of active integration. |
| BallService.luau:71,134,141,184 | Anchored non-touchable visual; server simulated position/velocity; possession setter clears owner/getter nil | Restore contact-based possession atop existing solver, no second physics loop or Touched/weld glue. |
| MatchService.luau:142,163,213 | Calls obsolete SpawnBall/StepBallPhysics; timeout always ends; >= gives TeamA a tied win | Migrate contracts and state machine, never enable unchanged. |
| FreeKickService.luau:39 | Historical curve/dip/Knuckle math exists | Audit reusable math, keep free-kick gameplay inert. |
| TraitConfigs.luau | LaserGuidedPass/guaranteed-finish legacy definitions remain | Consumer audit; no auto-guided/guaranteed traits in new target. |
| data-schema.md vs old RF05 | Both list13 stats with different names | Defer and reconcile catalog before Phase2, do not silently combine. |
| SprintService.luau | Configured server speed16/32 and boolean intent | Does not by itself prove movement anti-cheat; lifecycle findings remain. |
| idle-runtime-report-001.md | Five clips/sprint claimed, no Dash, published IDs absent | Owner first6 visual accepted; independent findings/asset release gate remain. |
| upgrade-limit-break.md | Old +0..+5 stat/stamina/awakening benefits | New target gauge-rate only; historical text not implementation permission. |

No active authoritative HP/gauge/Orb/six-Super system established. Pickup replacement is a product plan, not proof an active pickup spawner exists.

## Authoritative owners

- BallService alone owns position/velocity/spin/possessor/last validated touch and existing swept cage solver. Conceptual seam ApplyBallContact/ReleasePossession/GetBallSnapshot; exact signatures frozen per task. No competing Heartbeat writer.
- ContactResolver/CombatService validates actionId, actor generation, active window, geometry/team/relative speed and victim protection. Emits immutable accepted ContactEvent; client cannot declare hit/victim outcome. CombatHP/StunUntil/InvulnerableUntil separate from Humanoid.Health.
- GaugeService consumes accepted server events, owns0..100 and bounded dedup/earn-window budgets. Per action-target dedup permits a NEW real action against SAME victim after protection. No dribble-tick farming or permanent victim blacklist.
- OrbService owns bounded registry/spawns/expiry/atomic claims. Detect swept simulated ball and authoritative character geometry; the visual ball cannot trigger Touched. Resolve simultaneous claims once in deterministic simulation order. Ball claim uses recent server lastTouchUserId/time, no attribution => Orb remains available.
- SuperService owns locked loadout, gauge debit, activationId, deadline, one execution token and effect state. Six strategies call ball/contact/movement services. Normal body-check and Breaker share sweep pipeline, different configured forces.
- MovementState composes base/sprint/dash/wall/Overdrive/knockback/freeze/stun with one effective writer. Involuntary states override voluntary movement. Validate displacement/ability envelope; WalkSpeed assignment alone is not anti-cheat.
- MatchService owns regulation/GOLDEN_GOAL/terminal winner/cancellation and round generation. ProfileService owns durable earnedCash/copy/upgrade/loadout preferences. Never persist each hit or transient HP/gauge/effect.
- Client owns input/camera/animation/HUD/telegraph presentation, reconciles server truth. No animation marker/client contact decides possession/reward.

## Contact outcomes

| Action | Player outcome | Ball outcome | Reward/protection |
| --- | --- | --- | --- |
| Kick opponent | damage+brief flinch; zeroHP stun1–1.5s, no death | retain possession INCLUDING zeroHP kick | victim gain>attacker before capacity clipping; shared I-frame |
| Slide success | damage/knockdown; miss recovery | loose, no auto-possession attacker | one accepted action-target reward |
| Poke/block | manual actual ball contact | solver impulse/interception | meaningful ball-play event only |
| Normal body-check | directed missable rush, bounded stagger/knockdown | valid dislodge to loose, never auto-grant | common contact/I-frame |
| Breaker Rush | visible strong knockback within cage safety caps | loose on contact, no target lock | one activation; once per target |
| Protected victim | no new damage/stun/knockback | ball still contestable | no protected damage-hit gauge |

Kick-stun blocks control but does not itself clear possession. Ball remains physical/stealable: another valid tackle or ball interception may release it. I-frame protects player contact, never grants ball immunity. HP regen after combat delay; zero -> stun -> restore HP. All durations/damage/caps config.

## Super lifecycle

CHARGING -> READY at100 -> ARMED (atomic debit100,activationId,deadline) -> EXECUTED or EXPIRED -> CHARGING. One use; miss/expiry loses gauge. No earning while armed. Effect duration starts on execute and differs from arm deadline; not reusable timed mode. Consume valid execution token before effect. Invalid payload has no effect/refund; corrected request may retry until deadline if token unconsumed. Reject stale/foreign/duplicate activation, wrong match/loadout/generation, nonfinite/out-of-range aim. Reset/leave cancels without refund; effects have bounded cleanup owner.

| Super | Execution/counterplay | Config |
| --- | --- | --- |
| Curve Master | One manually aimed ball contact, more capped spin, interceptable | spin multiplier/cap/windup/speed cap |
| Power Shot | One manually aimed higher impulse, contact required | impulse/contact/windup/max speed |
| Frost Zone | Aimed arena point with range/LOS check, visible telegraph, short opponent freeze, I-frame honored | radius/aim range/telegraph/freeze/zone TTL |
| Overdrive | Self directed burst, collision stops/projects, never target following | speed/time/distance/recovery/sweep budget |
| Breaker Rush | Directed swept body-check, clearly throws opponent back, can miss | rush speed/distance/horizontal+vertical knockback caps/knockdown/recovery |
| Knuckle Shot | One aimed strike; seeded bounded lateral wobble, no destination attraction | seed/amplitude/frequency/accel/flight TTL/speed cap |

Super strength/range/duration independent of upgrade. Add curve/wobble before existing swept cage collision, same dt/substep budget. Never impulse anchored visual separately. Tests include grazing/corners/roof/high-speed multi-bounce. Six effects remain one feature task with six internal gates.

## Gauge, upgrade and persistence

Eligible events: valid kick/received kick,slide/intercept,distinct meaningful ball play (completed pass/interception/shot). No reward each dribble frame, self/team fake combat or duplicate collision callback. Real repeated same-victim hit remains allowed after I-frame; source/window caps limit farming without banning targets.

Increment = eligibleBase * capped selected-copy earn multiplier, then source/window budgets, then capacity0..100. Preserve victim>attacker even when their upgrade levels differ: constrain attacker entitlement below victim entitlement before capacity clipping. Merely base weights do not prove this invariant. Display can equalize at100 due capacity.

Phase1 one free baseline copy; earnedCash-only deterministic upgrade, no gacha/duplicate burn/random success. Upgrade changes ONLY gauge earn rate; hard cap enforced server-side. No HP/stat/stamina/ability power benefit. Atomic debit+level+request result; selected owned copy/level/cost/config version validated server-side. Concurrent retry/rejoin returns committed result, no second debit. Inventory actual profile schema before choosing migration/framework; no assumption durable services are already ready.

## Match and reset ordering

LOBBY -> READY -> KICKOFF -> REGULATION -> (lead=>RESULTS | tie=>GOLDEN_GOAL) -> RESULTS -> RESET. No normal overtime or penalty phase. Server monotonic timer; validate goal timestamp at/before regulation deadline before score evaluation. First valid Golden Goal atomically terminalizes before reward; duplicate/same-frame second goal cannot win or pay again. No TeamA tie default. If departure makes match unable to continue, cancel without invented winner; reconnect grace configurable. Shutdown reconciles committed results only.

Proposed reset defaults for review: kickoff/goal resets cancel armed/effects and clear match HP/gauge/Orb registry; no carry-over old-generation contacts. Orb spawning only active play. This reset detail is implementation config policy, not claimed separately Owner-accepted; revisit before match task if feel requires gauge carry-over.

## Config groups and schema

- StreetCombatConfig: HP/regen/damage/reach/angles/flinch/stun range1..1.5/I-frame/recovery/knockback caps.
- GaugeConfig: threshold100/event weights/victim ratio/window budgets/dedup TTL+capacity/earn cap.
- GaugeOrbConfig: ground+air spawn weights/bounds/cadence/count/radius/TTL/last-touch window/query cadence.
- SuperConfig: six IDs/arm deadline/manual aim validation and per-effect caps/telegraph/force/flight limits.
- UpgradeConfig: per-copy level cap,cost/bonus table,MaxEarnMultiplier,configVersion. Pending tuning, no invented economy acceptance.
- MatchConfig: existing target180s configurable,reconnect grace/reset/reward/cancellation; no active penalty/overtime settings.
- Durable: schemaVersion,earnedCash,owned baseline instanceId,gaugeUpgradeLevelByCopy,equippedSuperId,bounded processedRequest results. Runtime: actorGeneration,CombatHP,status deadlines,gauge,activationId,matchGeneration,lastBallTouch. No SuperMastery power field.

## Multiplayer, performance and anti-exploit gates

Bounded existing server tick; 4-player target, configured max Orbs/zones/effect TTL and capped query work. Registry candidates, no whole-Workspace scans. Small transition events plus rate-limited snapshots; no particle/dribble per-frame remotes. Pool visual effects. Measure same4-player scenario before/after: server step time/p95 frame/query count/network/instances/track growth; record device/workload, no unmeasured universal60FPS claim.

Validate type/finite vectors/normalization/range/context/team/current character+match/sequence/replay/rate limiting. No client cost,level,reward,target-hit,HP or ball transform authority. Network-owned character movement needs envelope validation/reconciliation beyond speed property. Latency50–150ms and concurrent contact tests; absent actual multi-client tests = NOT RUN.

Trace: STREET+HP->T05; GAUGE+ORB->T06; WALL->T07 BEFORE T08; six SUPER->T08; UPGRADE->T09; MATCH->T10; HUD->T11; config/security/multiplayer/performance every task plusT12.

Negative tests: fake/replay/stale contact; one collision many callbacks; SAME victim new legal action; protected hit/no gauge; kick-stun retains ball; simultaneous Orb/stale toucher; threshold/cap/victim inequality at differing upgrades; duplicate arm/expired execute; freeze/knockback stacking; two Golden Goals/clock boundary/disconnect/shutdown replay. Separate Owner visual acceptance, implementer claims and independent results.

## Primary references

[Client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary), [network ownership and movement validation](https://create.roblox.com/docs/scripting/security/network-ownership), [design for performance](https://create.roblox.com/docs/performance-optimization/design), [network delay testing](https://create.roblox.com/docs/projects/client-server). These inform architecture; they do not certify this game's security or speed.

## Later Owner-authorized momentum jump / air lean
Checklist7 implementer also owns higher jump, gradual vertical slowdown near apex, forward range from captured takeoff speed and four-way air lean; exact scope/gates in dribble-receive-HANDOFF.md. Reuse audited JumpModel math only; no global gravity/ball solver change. Bounded character-only air envelope and additive visual layer, future server-validated aim orientation seam. Shot/pass/curve tuning remains later. One writer; no newpane for unfinished same task. Prior jump lifecycle/land/Sprint corrections perreview025.
