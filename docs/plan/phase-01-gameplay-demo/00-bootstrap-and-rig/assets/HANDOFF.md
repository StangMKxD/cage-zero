# 00-bootstrap-and-rig — Custom R6 implementation contract

## DOCS-ARCH-20261024 — ACTIVE documentation extension, runtime still PAUSED

**Authority:** Owner requests reviewing two new files, finding current-work conflicts, defining integration/specs and assigning agyplan. Owner previously corrected routing: architecture belongs to STILL-OPEN **Plan00**, not another Phase2 assignment, with a separate future commit scope. This section authorizes ONLY foundation DOCUMENTATION in Plan00. Original rig implementation remains PAUSED_BY_OWNER, Round5 NOT DISPATCHED, F18/F19 OPEN; no code/runtime/Studio/test/rollback/Git permission. The uploaded boilerplate forbidding Plan00-doc edits and routing everything into Phase2 is superseded ONLY for this explicit new documentation scope. Original paused contract/reviews/evidence remain historical and unchanged below.

### Sources, current baseline and ownership

- Project root `C:/Users/Stang/cage-zero`; actual HEAD `c7542258b93b613e0260e43035761cbce87928cd` + protected pre-existing/concurrent dirty tree; staged empty at Controller preflight. Last5 c754225/7cdca7f/5c33d5f/a7178da/b579530. Input65026668 is historical, not current HEAD. No reset/rebase/checkout/stage/commit/push/config changes.
- `C:/Users/Stang/Downloads/cage-zero-upgrade-limit-break-spec.md`,184lines, SHA256 `e2f687b62831975562e6b57c2f19a93ba902b2d7b0f5df53f9ad6ed8ed80defd`.
- `C:/Users/Stang/Downloads/cage-zero-monetization-identity-celebration-spec.md`,194lines, SHA256 `0bc921626f174de1dc228a7fe3ad249800ab2c6ed97b9790db039f2bea703071`.
- Read both FULL files and relevant current docs/source READ-ONLY. Their duplicated Master Prompts contain superseded rules; latest Owner U1–U13 below wins. Owner-approved Stats13/Traits16/Archetypes5 decisions remain inputs; do not reopen settled questions or silently overwrite prior round reports.
- Document lead agyplan w2:p49/tabw2:t3M; Controller Codex w2:p43. Normal prompt, no new agents. agycage's skillmove source/tests/recipes/manifests/task/review artifacts remain its lane, never touched here.

### Accepted Owner decisions U1–U13 (override input tables)

| Decision | Confirmed contract |
|---|---|
| U1 | +3 unlocks Awakening of ONE Trait the character has. +2/+3 give small Stats. +5 unlocks exactly ONE additional character Trait equip slot, not fixed third slot/3total, not a gear Trait stone. Base innate Trait count stays variable including0. |
| U2 | TARGET game has NO per-move gameplay Cooldown; uses Stamina while retaining Recovery/end-lag/action lifecycle. This is a future design delta, NOT permission to remove current source cooldowns. Transport rate limits/Server validation remain separate safeguards. |
| U3 | At+5, SkillMove/Dash/Slide/Poke/BodyCheck all use0.80 of their applicable base cost. +4 only SkillMove/Dash use0.88; +5 replaces that profile rather than multiplying0.88×0.80 or applying only8% to tackles. Other effect composition not decided is explicitly pending. |
| U4 | Purchasable rewards described are character card/Cash; Stats/skill stars/innate Traits come from the character, no separate direct stat/star/Trait sales. Do not make an unproven Zero-Pay-to-Win guarantee from stat caps: identify paid progression honestly. |
| U5 | Skill ceiling increase moves to+5: base+1★, maximum5★ (2→3,3→4,4→5,5→5). Skill EQUIP slots stay3. No star increase at+3. |
| U6 | Custom stat points relocate to+2:2points and+3:3more,5points total; eachpoint adds0.01 to selected stat multiplier. No duplicate point award at+1/+4. Base+custom allocations still≤1.15; prior base floor0.90 and conditional Trait-above-cap rule retained. |
| U7 | Starter Pack contains ONE character card + Cash ONLY. Remove jacket/Mutation/FX/gear Trait slots from this bundle; no hidden stat/star/Trait bonuses. Exact eligible card list/Cash amount/price remain pending if not determined. |
| U8 | ALL FOUR Gamepasses (VIP/FastRoll/MultiSummon/LoadoutPresets/ProTrader) are DEFERRED FOR GRILL WHEN THEIR PLAN STARTS, not accepted/current purchase promises. Preserve source proposals as labelled deferred reference, no automatic entitlement activation. |
| U9 | Player may choose ONE eligible Trait to Awaken. If character has0Trait at+3, bank that right until it has a Trait, including the extra equipped Trait after+5. Do not invent first/second-index targets or waste/replace the right with an invented reward. |
| U10 | The additional+5 slot can choose from ALL available/released Traits in the game; no stone purchase, donor card or Collection unlock prerequisite. Today catalog has16; avoid a permanently hardcoded selection count. |
| U11 | Base5★ gets no additional15% high-star stamina discount. It retains ordinary+5 cost20%reduction/extra Trait and other confirmed benefits; no double-compensation. |
| U12 | Discounts apply ONLY to existing applicable cost. If base cost0, it stays0; do not invent shooting/Jump/Trap/FirstTime fees to make a TierII discount useful. Clearly label unbound channels. |
| U13 | Additional Trait may NOT duplicate a Trait the character already has; select another released ID, reject duplicates on Server. No duplicated-effect stacking or gear Trait system. |

### Requested feature content to specify (uncontradicted file content stays traceable)

- Upgrade+0→+5: duplicate-card/shard + Cash sink, guaranteed success when valid, no failure/downgrade. Requested step duplicates1/1/2/2/3 (9total beyond base card); exact Cash/shard conversion/eligible duplicate-definition rules remain pending, not invented.
- Final level map: +1 source-requested post-match Cash/EXP+10% with stat points MOVED away; +2 two statpoints; +3 three additional statpoints + one bankable chosen Trait Awakening right; +4 Skill/Dash cost×0.88 + animated back number/shoulder aura, stat points MOVED away; +5 one additional Trait slot + skill ceiling+1 capped5 + cost×0.80 for specified groups + source-requested awakened celebration treatment/title. No second automatic Trait awakening at+5 and no fixed total Trait count. Explicitly label retained file perks vs unresolved tuning instead of silently fabricating approvals.
- Preserve all16 source TierII effect proposals with exact stated numeric differences/triggers and a TierI→TierII trace table, but activation is ONE chosen Trait under U1/U9, not slots1/2 at levels2/5. U2/U12 and prior phase restrictions override incompatible assumptions. Refund basis, trigger definitions, event deduplication, effect stacking, respec/retarget costs/limits and missing tuning remain explicit pending decisions. Never award per-frame repeated refunds or exceed resource maximum by assumption; document required correctness invariants and tests, not implemented behavior.
- Starter card+Cash is the current limited bundle target. Four Gamepasses deferred underU8. Repeated Cash products/paid-ticket details, prices/product IDs/eligible Starter roster are not silently frozen from examples. Record only source-requested proposals when not confirmed. Account-once purchase and receipt/entitlement/grant idempotence require a future authoritative adapter; no payment APIs called in this job.
- Identity: SAME game-owned custom R6, not personal player avatar/R15 replacement. Three-layer future presentation: team-readable vest/foot-ring/indicator, card back-number/one accessory toggle, signature idle/dribble stance. Team identification must survive signature/awakening VFX. Define cardinality/cleanup and pose priority with existing action/base-locomotion layers without mutating rig/scales/physics now. Five archetypes and six illustrative named identities in input are not the same count; archetype defaults vs per-card examples need clear labels. Existing preset scales/default card stay untouched; example roster/scales/names are not automatic final catalog/legal clearance.
- Celebration:3 effect-gacha categories (BallActionFXSet,MovementFXSet,CelebrationCutscene). Source requests3–4s post-goal cinematic,0.15s impact frame and cosmetic Signature Sync, compatible with any character; matching identity only adds visual treatment, no stats. Server match phase/clock/deadline governs when it can play; audience/skip/reduced-FX/camera details not settled remain pending, not client-controlled clock authority. Preserve existing no-P2P-FX rule; Cash booth/disassembly concepts require policy/ownership safety.
- Do not label names/homages100% copyright-safe or assets cleared without evidence. Keep examples as candidate identities and record rights/provenance review as unverified. No new trademark/club/audio assets or asset uploads.

### Required architecture/schema integration seams (DESIGN, not new source services)

1. Separate immutable CharacterDefinition/Archetype/Stat/Trait/TraitTier/Celebration definitions from mutable OwnedCard INSTANCE UID, level, point allocations/unspent points, selected awakenedTraitId/right, exactly-one additionalTraitId and ownership. No implicit global upgrade of all copies of a character; ambiguity remains explicit. Trait identity, not array position, is the Awakening target; field/types are documented target proposals until implementation freeze.
2. Show a pure effective-profile derivation: base+custom points bounded perstat, current accepted conditional Trait layer, +5starcap, per-level cost profile; retain Recovery and existing context/generation/contact validations. No per-move cooldown in TARGET; no mutation of live code. List stat/trait/refund composition questions rather than treating additive and multiplicative alternatives as equivalent.
3. Future transaction seams: validate→reserve/consume duplicate UID/shard/Cash→upgrade/allocate/chooseTrait→persist one authoritative outcome→replicate. Receipt/command retries and simultaneous upgrade/equip/trade cannot double-spend/grant. Protect equipped/locked/in-use cards with an explicit future policy, not invented silent consumption.
4. Monetary entitlement/Starter grant/reward settlement/market interfaces must be server authoritative, atomic/idempotent at the defined boundary; no client purchase-success flag as authority. Preserve provenance of paid-value items through trades/upgrades/shards; product IDs/prices and runtime services remain unimplemented.
5. Shared rendering seams: card equip→effective identity snapshot→team precedence→cosmetic/accessory/stance; goal event→allowed presentation deadline→celebration/signature visual→cleanup/camera restoration. Signature visuals and upgrade title do not alter hitboxes, success, collision or clock control. Separate player loadout3slots from saved preset counts (Gamepass proposals deferred).
6. Policy boundary (official docs verified2026-10-24): paid random rewards include use of Robux-backed currency/tickets; odds must be disclosed before acquisition, user eligibility checked via PolicyService and paid-item trading gated. Cash booth is not an eligibility bypass. Record policy failure/unknown handling and planned tests; no claim of implemented/compliant behavior from documentation alone.
   - https://create.roblox.com/docs/production/monetization/paid-random-items
   - https://create.roblox.com/docs/reference/engine/classes/PolicyService
7. Include a current-ASIS→requested-source→Owner-resolved-TARGET→future-consumer/gate matrix. Existing gameplay/currency/gacha/collection/UI/market/matchflow docs may be READ to define seams; no Phase2 file edits or implementation task dispatch in this round.

### Exclusive write allowlist / separate future commit group

- This existing Plan00 HANDOFF + Plan00 plan.md/tasks.md/notes.md, ONLY a clearly separated Docs Architecture Extension subsection; never rewrite original paused rig scope/findings/history as passed.
- NEW `assets/designs/upgrade-limit-break.md` and `assets/designs/monetization-identity-celebration.md` under THIS Plan00. Put integration/decision/conflict tables in these two specs or the Plan00 extension section, not many duplicate summaries.
- Narrow additive links/extension-contract sections in `docs/design/architecture-and-network.md`, `docs/design/data-schema.md`, `docs/READ.md`, `docs/plan/roadmap.md` ONLY as necessary to anchor Plan00. These are already dirty from prior rounds: preserve content, record exact new section/hunks and before/after hashes for this new separate commit group.
- ONE `assets/architecture-extension-report-001.md` plus compact own-edit fingerprint/evidence manifest if needed. No code/executables/tool launch/Studio writes/new dependency/app tests. Docs-only link/count/arithmetic checks allowed.
- DO NOT edit ANY Phase2 plan/task/notes/HANDOFF/report files for this new job. Do not move/rewrite/mark closed the prior DOCS-20261024 submission/review. Its review remains history/separate round. Do not touch Plan01acceptednotes or agycage's skill documents/source/tests/recipes/manifests, rootagent/.gitignore/ORIGINAL_REQUEST, src/ (especially protected9), tests/, .sandbox/rollback/reference, historical Plan00 review/fix/rollback evidence.
- Separate future commit scope = new Plan00 foundation specs + their bounded Plan00/routing/schema pointer hunks ONLY, excluding old Stats round and skillmove work. Record own files/section markers/ref/full untruncated hashes; NO staging or actual commit/push/merge/publication authorized.

### Execution, validation and Owner reporting gate

Preflight actual Git/status, current paused00/review010 guards and own/protected before fingerprints. Build the conflict/dependency map FIRST; use U1–U13 rather than stale source prose. Draft the two specs/integration/schema concepts in Thai with decision status Accepted/Proposed/Deferred/NeedsDecision separated from delivery Planned/NotImplemented. Do not create fake accepted outcomes for unresolved matters; progress independent sections and return exact new conflict if necessary, no repeated grilling of answered questions.

Validate level/point totals, duplicate counts, statcaps/bonus-vs-multiplier math, variable innate count/extraSlot=1/no duplicate,1Awakening target,5★cap/3equips, explicit0cost behavior/Recovery retention,16TierII mappings, bundle contents/Gamepasses deferred,6exampleidentities vs5archetypes,3FX categories and cosmetic-only sync. Verify source/protected0runtime scope and new local links/anchors. Include actual command/result summaries and current source/doc refs; never reconstruct truncated hashes or claim full tree docs-only when old/concurrent source changes exist.

When ready, give actual report path/outcome/HOW TO CHECK in YOUR OWN pane and WAIT Owner inspection plus explicit SEND REPORT request. Then one consolidated `herdr agent prompt w2:p43 $report` to verified Codex target (submits Enter), no waiting/double-Enter/callback spam. Codex does NOT monitor. Do not self-approve/close, resume F18/F19, implement features, or perform Git actions. This new documentation extension does not lift any runtime gates.

- **State:** LOCKED_SCOPE / PAUSED_BY_OWNER — “พักรอบ 00 ก่อน” หลังreview010; Round5 NOT DISPATCHED หยุดงานจนกว่าจะresume คงhistoricalgaprunแรกACCEPTED_GAP
- **Authority:** ผู้ใช้อนุญาต Codex ปรับแผน/architecture และตอบ “ใช้ R6 ตลอด Phase 1 (แนะนำ)” เมื่อ 2026-10-20
- **Design:** [plan](../plan.md), [tasks](../tasks.md), [architecture](../../../../design/architecture-and-network.md#5-phase-1-runtime--custom-r6) และ accepted decisions N-32/N-33
- **Owner:** Stang; **Planner/Reviewer:** Codex; **Implementer:** AGY Teamwork-preview; session e86ac30e-006d-4338-9a90-5f5e3b002028 / run-phase00-agy-impl-01; Codexไม่มีช่องdispatchตรง ผลกลับผ่านผู้ใช้
- **Baseline:** main @ `2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`; source ยังตรง `6d0f273dc...`
- **Implementation approval / P-03:** AUTHORIZED_FOR_00 — Stang สั่ง “เริ่มเลย” เมื่อ 2026-10-20 อนุมัติ AGY ทำ source/target Studio/verification ตามขอบเขต00 ไม่รวม01/07/Phase2
- **Governance:** OWNER_STANDARD; Turn=OWNER (Stang); PAUSED_BY_OWNER F18/F19ยังOPEN เก็บreview010และหลักฐานไว้ ไม่แก้/ทดสอบ/dispatchหรือปิด00ระหว่างพัก
- **Git:** ไม่อนุญาต local commit/push/merge/deploy รวมถึง commit เพื่อ SHA tracking; ส่ง working tree เท่านั้น ไม่เรียก subagent หรือส่งข้อความงานอื่นอัตโนมัติ
- **Protect:** .gitignore ที่เพิ่ม /sourcemap.json, เอกสาร/รีวิวที่แก้ค้าง, sourcemap.json, historical runs และ .sandbox/reference ทั้งหมด; ตรวจ git status อีกครั้งก่อนรับงาน

> ข้อความ baseline lock/ขั้นถัดไปเดิมเป็นประวัติก่อนรับงาน สถานะปัจจุบันใช้tasks/review008และOwnerdecisionท้ายสัญญานี้ scopeและruntimeacceptanceคงเดิม ยอมรับเฉพาะhistoricalStudio before-stategaprunแรก ไม่เริ่มแผนถัดไป

## อ่านก่อนเริ่ม

agent.md → docs/READ.md → plan/tasks/notes ของ 00 → architecture §5 → PRD/spec-03 §1/TDD Phase1/00; review-003 ใช้อ้าง sandbox snapshot เท่านั้น review-001..006 เป็นผลข้อเสนอ R15 ไม่ใช่ผล R6

## Scope ที่อนุมัติสำหรับ AGY

Custom R6 ของเกม, bootstrap ขั้นต่ำ, standard R6 locomotion, scale เดิม, spawn/respawn/race และ fixture ยืน/เดิน ไม่มีบอล/ดวล/Dash/โกล/กรง/UI/กาชา/เศรษฐกิจหรือ migration R15

### Source allowlist

| ไฟล์ | งาน |
| --- | --- |
| src/server/init.server.luau | Network.Init → RigAndCardService.Init ไม่ require MatchService |
| src/client/init.client.luau | Network.Init → R6AnimationController.Init ไม่รอ ui/controllers เก่า |
| src/shared/Network.luau | เพิ่ม Init(timeoutSec?) deadline รวม 10s; ไม่เปลี่ยน getters/Definitions/validators |
| src/shared/Constants.luau | ชื่อ R6 template, schema/profile, explicit floor/anchor config; คงค่าระบบอื่น |
| src/server/services/RigAndCardService.luau | R6 builder/scale/spawn/respawn/lifecycle; คง API ที่ consumers ใช้ |
| src/shared/configs/RigAnimationConfigs.luau (ใหม่) | R6 clip IDs/state profile/provenance ที่ตรวจได้จริง |
| src/client/character/R6AnimationController.luau (ใหม่) | ModuleScript ผูก local character generation/Animator/tracks/cleanup |

Types.luau และ CardConfigs.luau อ่าน/sync ตามเดิม ไม่แก้ในสัญญานี้ Default project mapping เดิมรองรับ source ใหม่ได้ ไม่แก้ build config
Docs ที่แก้ท้ายงานได้: เอกสารแผน 00 และ architecture/spec/TDD เฉพาะ delta จากผลงานจริง ห้ามขยาย requirement/เปลี่ยน Owner decision เพื่อให้เทสต์ผ่าน

### Studio allowlist — ต้องตรวจ target ใหม่

- เฉพาะฐานใหม่สำหรับ Cage Zero ที่ผู้ใช้ระบุ; Place1 เป็นชื่อ snapshot เดิม ไม่ใช่ Studio ID ถาวร
- shared source 5 จุด: ReplicatedStorage.Shared.Constants / Types / Network / configs.CardConfigs / configs.RigAnimationConfigs
- server 2 จุด: ServerScriptService.Server (Script, Legacy) / Server.services.RigAndCardService (ModuleScript)
- client 2 จุด: StarterPlayer.StarterPlayerScripts.Client (LocalScript) / Client.character.R6AnimationController (ModuleScript)
- สร้าง parents ที่ขาดตาม class/path เหล่านี้; class ชนกันให้หยุด ไม่แทนที่เอง
- ServerStorage.CageZeroStandardR6Rig และ descendants ที่ builder สร้าง; PRIMARY_FLOOR_PATH ชี้ Baseplate ที่ตรวจแล้ว หรือ BootstrapTestFloor/BootstrapSpawnLocation ที่สร้างในรอบนี้
- ห้ามเขียน/disable/move prototype sandbox place 112091950831355 และ ServerStorage.CageZeroDevelopment

## ลำดับงาน

1. **Preflight:** ใช้ P-03 จากคำสั่ง “เริ่มเลย” นี้ ไม่ถามอนุมัติเดิมซ้ำ; ตรวจ SHA/dirty files เทียบ baseline manifest และเก็บ pre-step state ก่อนเขียน ห้ามหยุด Play ของผู้ใช้เอง ตรวจ target Edit Studio ก่อนขั้น sync; ถ้ามีเพียง sandbox reference หรือ target ยังไม่เปิด ให้ทำ repo/source/asset research ที่ไม่พึ่ง target ต่อได้ และหยุดเฉพาะขั้นเขียน/Play ของ target ที่ยังระบุไม่ได้
2. **Bootstrap:** Network.Init ตรวจ folder/name/class ครบ 12 definitions ภายใน budget รวม 10s; client waits Shared/Network รวมอยู่ใน budget ไม่แก้ GetRemoteEvent/GetRemoteFunction หรือเปิดระบบ deferred
3. **R6 definition:** ยึด standard R6 topology/orientation จาก Roblox/native baseline ที่ตรวจได้ บันทึก base geometry/joints ใน source ไม่เปลี่ยน Enum บน R15
4. **Rig lifecycle:** template 6 body parts + HRP / 6 joints / Humanoid R6 / Animator / fixed face; PrimaryPart=HRP, root ไม่ Anchored; เปลี่ยน BuildStandardCustomR15Rig เป็น BuildStandardCustomRig พร้อมผู้เรียกภายใน service คง external API อื่น
5. **Scale/spawn:** BaseSize/BaseC0/BaseC1 คงที่แยก body/head; R6 standing height = Left Leg.Size.Y + HRP.Size.Y/2 + HipHeight; explicit primary floor/anchor และ footprint/raycast ต้อง valid-or-error ไม่คืน cutoff-Y/ตำแหน่งเดา
6. **Respawn:** player/character generation guard, died connection แยกจาก player listeners, timer เก่าห้ามทับ character ใหม่ และ PlayerRemoving ล้าง state; ไม่เปิด inventory/gacha handler ของ Phase 2
7. **R6 animation:** controller เป็น ModuleScript; server-created Animator ต้องอยู่ Workspace ก่อน client โหลดคลิป ตั้ง timeout และ per-character handle; รองรับ idle/walk/run/jump/fall ผ่าน standard R6 clips ไม่รับ animation pack ผู้เล่น ไม่เปิด controller ซ้อน Animate
8. **Clip provenance gate:** อ่าน official/native R6 reference ที่เข้าถึงได้ เก็บ IDs/state/provenance ใน RigAnimationConfigs ตรวจ compatibility/การโหลดจริงหลัง approval ถ้าไม่ยืนยันได้หยุดเฉพาะ asset step ไม่เดา IDs หรือสร้าง procedural controller ทดแทนโดยพลการ
9. **Sync:** source 9 จุดและ template/fixture ตาม owner ของขั้นนั้น อ่าน hash กลับและบันทึก post-state ครบ subtree ไม่ใช้ snapshot name/hash เก่าแทนการอ่านใหม่
10. **Verification + doc sync:** ตรวจ gate ด้านล่าง บันทึกผลเฉพาะที่รันจริง และส่ง working tree ให้ Codex review ไม่ปิดงานเอง

## Gates ที่ต้องรายงานผลจริง

| Gate | เกณฑ์ |
| --- | --- |
| V-01 | source 9/9 hash ตรง repo; template R6 topology/attributes/face/No Boots; ไม่มี avatar ส่วนตัว |
| V-02 | bootstrap ready รวม ≤10s, ไม่มี error จาก source รอบนี้; ไม่เปิด Match/Parry/UI/collection; controls/กล้องพื้นฐานทำงาน |
| V-03 | 4 presets ไป–กลับ 3 รอบ ตรวจ server sizes/C0/C1/rotations จาก base และ R6 ground clearance; drift tolerance 1e-4 สำหรับ static values |
| V-04 | idle/move/jump/fall เปลี่ยน pose จริงจาก R6 clips; client PostSimulation หลัง settle; server ตรวจ state/positions แยก ไม่เทียบ raw Transform ข้าม network |
| V-05 | ตาย/เกิด 3 รอบ, ตกนอก floor, timer race (สร้าง charB ระหว่าง old timer) และออกเกม; current generation ไม่ถูก old callback ทับ |
| V-06 | explicit floor อยู่ใต้จุดเกิดและห่างขอบตาม rig footprint; ไม่ spawn ใต้พื้นหรือบนลูกบอล |
| V-07 | no out-of-scope diff; source/runtime/asset/visual เป็นคนละผล ระบุ NOT VERIFIED ของสิ่งที่ไม่ได้ตรวจ |

- ตรวจ topology/scale ที่ R6 joints จริง ไม่ใช้ knees/elbows หรือ count 16/15 ของ R15
- movement probe รัน client ที่เป็น owner พัก/คืน default controls และ cleanup ในทุกทางออก timeout/fail; observer client เพิ่มเป็นหลักฐานเมื่อ session รองรับ ไม่อ้าง multi-client pass โดยไม่มีผล
- ถ้า rig invalid/asset load fail/source ชนกัน ให้ส่ง error/ค่าที่อ่านได้จริง ไม่เปลี่ยน acceptance ให้ผ่าน

## Rollback และ preservation

- Single writer ต่อ scope; เก็บ pre/post snapshots ของแต่ละขั้นใน .sandbox/rollback/<runId>/<stepId> โดยไม่ทับ reference เดิม
- ก่อนย้อนงานตรวจไฟล์และ instance ทั้งชุดว่า current ตรง post-state รวม subtree/children/properties หากต่างให้หยุดทั้งหมดก่อน mutate
- ไฟล์เดิม: คืน bytes จาก pre-snapshot ได้หลัง hash guard ทั้งชุดผ่าน; ไฟล์ใหม่: ลบเฉพาะของขั้นนั้น; ตรวจ final pre-hash/exists อีกครั้ง ไม่ใช้ HEAD เป็นจุดคืนงาน
- Studio: manifest ต้องมี descendants ทุกตัวที่สร้าง/แก้; หลัง preflight จึง restore/delete bottom-up ไม่ตรวจ parent เทียบ post-children ซ้ำหลังลบลูกเอง ตรวจ final pre-state ครบ
- ไม่ reset/checkout ทั้ง repo, ไม่ใช้ unsafe-paths, ไม่ลบ root/ทรัพย์สินผู้ใช้คำนวณโดยไม่ตรวจขอบเขต หากใช้ patch ให้เทียบ pre/post โดยตรงและยึด recipe F-10 ที่ตรวจแล้ว
- ส่ง diff/evidence และข้อจำกัดจริง ไม่มีสิทธิ์ commit/push หรือเปลี่ยน APPROVED/PASS/CLOSED แทน Owner

## ขั้นถัดไป

Stang อนุมัติ implementation แผน 00 แล้ว ผู้ใช้ส่ง prompt/HANDOFF นี้ให้ AGY บน local ได้ทันที AGY ใส่ session/run ID และเริ่มลำดับงาน 1 จากนั้นส่ง working tree/หลักฐานให้ Codex ตรวจ ไม่ถือว่าผ่านจากการอนุมัติเริ่ม แผน01/07ยังไม่เปิด implementation และ source ณ handoff ยังไม่ใช่ R6


## Baseline lock และพิกัดรับงาน

- Base SHA ตามหัวสัญญา; working-tree dirty snapshot/hash ของไฟล์ก่อนรับงานอยู่ `.sandbox/rollback/phase00-handoff-20261020/baseline.json` ตรวจ manifest นี้และ git status ก่อนแก้ ห้ามทับเอกสารค้างเพราะไม่ได้อยู่ใน commit
- Server pointers: `src/server/init.server.luau:12`, `src/server/services/RigAndCardService.luau:27` (schema), `:183` (builder), `:263` (scale), `:342` (spawn), `:439` (Init)
- Shared pointers: `src/shared/Network.luau:110`/`:146` (เพิ่ม Init โดยคง getters158/177), `src/shared/Constants.luau:12` (ชื่อtemplate/config)
- Client pointer: `src/client/init.client.luau:11` เป็นต้นไป (ถอด UI/controllers เก่า); source ใหม่สองไฟล์ตาม allowlist ยังไม่มี
- จัดกลุ่มงานต่อเนื่องโดย lead เดียว: S1 Network/Constants/server entry/Rig service → S2 clip config/client entry/animation module → S3 Studio/probes/doc sync ไม่มีสิทธิ์ spawn worker เพิ่มจากการแบ่งกลุ่มนี้
- V-01..V-07 ยัง NOT RUN ขณะ handoff; วิธีตรวจคือ targeted code review/Studio probes และ runtime/visual ตาม gates ไม่ต้องติดตั้ง test framework หรือรัน full-game suite ที่ยังเปิดระบบนอกscope
- หลักฐานส่งกลับ: session/run ID, actual HEAD/working-tree diff, source hashes, gateผลจริง/ข้อจำกัด และ notes/tasks อัปเดตเป็น READY_FOR_REVIEW เมื่อเสร็จ ห้ามตั้ง owner approval/closure เอง

## Correction Round 3 — Owner decision 2026-10-20

Stangตอบ “ยอมรับช่องว่างเดิม แล้วเก็บ baseline ใหม่ก่อนเดินต่อ (แนะนำ)” ในคำถามF18หลังreview008 อนุญาตเดินต่อเฉพาะcorrection00 ยอมรับเฉพาะStudio before-stateที่ขาดก่อนrunแรก ไม่ย้อนหลังสร้างประวัติ ไม่ปิดF18/F19/F20หรือruntimegate

1. อ่านreview008; preflightactualHEADปัจจุบัน (ล่าสุดf8729cc6e714f10a1cb60253a4f037d7c49f7505) พร้อมworking-tree hashes ไม่resetงานค้าง; commitf8729ccเป็นเอกสารสนามที่Ownerอนุญาตแล้ว
2. ก่อนmutateเก็บcurrentbeforeของfilesและStudioครบscopeในโฟลเดอร์correctionใหม่ใต้.sandbox/rollback/ ระบุactualStudioID/PlaceId/โหมดและเวลา Snapshotreview008เป็นreferenceไม่ใช่currentbeforeอัตโนมัติ; ล่าสุดtargeta9611fd4.../PlaceId137721422246269 Edit ต้องlist/getstateใหม่ก่อนใช้
3. F18: manifestจากreadbackจริง path/class/source/hash/properties/attributes/childsets/subtreeครบและcountตรง; pre/postต่อขั้นไม่ทับsnapshotเก่า เปรียบเทียบguardทั้งชุดก่อนrestore ไม่ย้อนจริงเพื่อพิสูจน์และไม่อ้างrepoก่อนrunเป็นStudiohistoricalbefore
4. F20: sync4sourceที่ต่างตามreview008จากrepoไปtargetdevelopmentที่ตรวจแล้ว ได้แก่RigAndCardService/init.client/R6AnimationController/RigAnimationConfigs จากนั้นreadbackSHAครบ9/9 ไม่publishหรือแตะreferenceplace112091950831355
5. F19: AGYรันruntimeV01–07ตามHANDOFFจริง รวมbootstrapelapsed/12remotes,4presetsไปกลับ3รอบอ่านsizes/C0/C1/rotations/groundclearance,loadedclipsและclientPostSimulationpose,controls/camera,death3รอบ/void/timerrace/leave,invalidfloorและcancelledsetup/failedasset; รายงานNOT VERIFIEDของกรณีที่sessionทำไม่ได้ ไม่ใช้Node72checksรับรองruntime
6. F13–17codeแก้แล้ว ไม่รื้อใหม่โดยไม่มีหลักฐาน failure; sourceแก้เพิ่มได้เฉพาะallowlist00เมื่อruntimeพบปัญหาในscope ไม่เปลี่ยนpublicgetters/Definitions/Types/CardConfigs/requirementเพื่อให้ผ่าน
7. ส่งassets/fix-008.mdหนึ่งไฟล์รวมทุกfinding พร้อมcurrenthashes/target/manifestpaths/gateผลจริงและข้อจำกัด แล้วnotes/tasksเป็นREADY_FOR_REVIEW ไม่มีสิทธิ์commit/push/merge/deploy/spawn/เริ่ม01/07/Phase2/ปรับchoice ไม่อ้างรับงานหรือรันแล้วจากสัญญานี้
