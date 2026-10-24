# DOCS-20261024 — Report 001: Stats (13+4), Innate Traits (16), Archetypes (5) & Body Check

- **Task Identifier:** `DOCS-20261024`
- **Execution Role:** `agyplan w2:p49` / tab `w2:t3M`
- **Controller / Reviewer:** `Codex w2:p43` / tab `w2:t3E`
- **Source Specification:** `C:\Users\Stang\Downloads\Cage Zero - Full Stats, Traits, Archetypes & Codex Prompt Specification.md`
  - Source SHA256: `B1E36553CB8556EA2B9F020761AF1E243077A2475607A75D1B39186FE2B861CC` (Verified matching)
- **Current Git HEAD:** `c7542258b93b613e0260e43035761cbce87928cd` + dirty working tree
- **Status:** `READY_FOR_REVIEW` (Documentation alignment only; Phase 2 implementation remains DEFERRED; Module 00 remains PAUSED_BY_OWNER)

---

## 1. Governance & Reporting Gate Override

> **LATEST OWNER DIRECTIVE (2026-10-24):**
> Codex does NOT monitor or poll `agyplan` or `agycage`.
> The Owner will inspect this work directly in this pane first. Only after the Owner provides an explicit instruction to send the report will the consolidated report be dispatched to Controller Codex `w2:p43`.
> No automatic push, callback, progress ping, or ACK is sent to Codex prior to Owner authorization.

### How Owner Can Check the Updated Documents
Owner can inspect the changes using standard Git tools or direct file inspection:
1. **Git diff check (Docs only):**
   ```powershell
   git diff c7542258b93b613e0260e43035761cbce87928cd -- docs/
   ```
2. **Review Canonical Target Specifications:**
   - [Phase 2 / 03 Plan](file:///C:/Users/Stang/cage-zero/docs/plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/plan.md): Full tables for 13 Outfield Stats, 4 Deferred GK Stats, 16 Innate Traits, 5 Character Archetypes (65 values), formula math, and gacha deferral rules.
   - [Data Schema Target](file:///C:/Users/Stang/cage-zero/docs/design/data-schema.md): Typed Luau models for 13 stats fields, 16 TraitIds, 5 ArchetypeIds, innate traits array, cosmetic BattleThreads (no trait slots), and labelled history.
   - [Spec 02 (Duels & Body Check)](file:///C:/Users/Stang/cage-zero/docs/specs/spec-02-duel-and-parry.md): TARGET button map (LMB Shoot/Slide, E Pass/Poke, RMB Curve/BodyCheck, MMB retired; core charging E-FakeShot exception preserved; AS-IS code noted), Body Check forward loose-ball contact semantics vs historical CagePress.
   - [Spec 04 (Innate Traits & Economy)](file:///C:/Users/Stang/cage-zero/docs/specs/spec-04-traits-threads-economy.md): Innate traits only (variable 0..N), removal of Battle Threads trait slots / stones from Target, cosmetic & mutation multipliers preserved.
   - [Notes N-61](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/01-cage-physics/notes.md#n-61--accepted-decision-13-outfield-base-stats-4-deferred-gk-stats-16-innate-traits-5-character-archetypes-and-body-check-target-mechanics-2026-10-24): Complete accepted decision record appended after N-60.
   - [Training Ground 06 Plan](file:///C:/Users/Stang/cage-zero/docs/plan/phase-01-gameplay-demo/06-training-ground/plan.md): 13 stat sliders, 16 trait toggles, 5 archetype presets scoped strictly to test sessions.

---

## 2. Protected 9 Files Integrity Guard (Zero Drift Verified)

No modifications were made to `src/` (all `.luau` files), tests, configuration, `.gitignore`, or Module 00. The 9 protected files have identical SHA256 before and after:

| Protected File Path | Baseline SHA256 | Post-Edit SHA256 | Drift Status |
| :--- | :--- | :--- | :--- |
| `src/shared/Constants.luau` | `DA340AE6B09BFC42CE6681B8C1871DA5315621B38A17C77162BC25C0471292B6` | `DA340AE6B09BFC42CE6681B8C1871DA5315621B38A17C77162BC25C0471292B6` | **0 DRIFT (MATCH)** |
| `src/shared/Types.luau` | `64B9E53831833C3D90F5563BEEFFA2171EE9ABB3EA9662878C8D6216F17A0C59` | `64B9E53831833C3D90F5563BEEFFA2171EE9ABB3EA9662878C8D6216F17A0C59` | **0 DRIFT (MATCH)** |
| `src/shared/Network.luau` | `217668CE752348D046BF0F7963A3A72FF7133FF5AD57FAFB9AEA7D4A7ABF96A5` | `217668CE752348D046BF0F7963A3A72FF7133FF5AD57FAFB9AEA7D4A7ABF96A5` | **0 DRIFT (MATCH)** |
| `src/shared/configs/CardConfigs.luau` | `E558086E96A167780FEBCC24D8CBADB88EE7C37EA271A2F37DC548C1F3B48662` | `E558086E96A167780FEBCC24D8CBADB88EE7C37EA271A2F37DC548C1F3B48662` | **0 DRIFT (MATCH)** |
| `src/shared/configs/RigAnimationConfigs.luau` | `E6BFF0C9C2E1D1DE841D9F83A1F99396CC0BA01FB89BD36AA29BB6A10E82C028` | `E6BFF0C9C2E1D1DE841D9F83A1F99396CC0BA01FB89BD36AA29BB6A10E82C028` | **0 DRIFT (MATCH)** |
| `src/server/init.server.luau` | `17D24B2F5199FDA3F3A8BBF2CC6C469C2F7252428F48D4FC3456DCDF07926B2B` | `17D24B2F5199FDA3F3A8BBF2CC6C469C2F7252428F48D4FC3456DCDF07926B2B` | **0 DRIFT (MATCH)** |
| `src/server/services/RigAndCardService.luau` | `A6D8D9EA45470B10ED8C77FABBA0E491B04D87EBF470F23DAE47EA04E0DD8CFC` | `A6D8D9EA45470B10ED8C77FABBA0E491B04D87EBF470F23DAE47EA04E0DD8CFC` | **0 DRIFT (MATCH)** |
| `src/client/init.client.luau` | `4731C0449A26AD48F1AE3385C3103643F61D64653C0F2B50799539BBC0C86C93` | `4731C0449A26AD48F1AE3385C3103643F61D64653C0F2B50799539BBC0C86C93` | **0 DRIFT (MATCH)** |
| `src/client/character/R6AnimationController.luau` | `6E3A0A2A190E08E7FCF1810E17511E5906C32B7CDA7C21B67D370ACB7D85669A` | `6E3A0A2A190E08E7FCF1810E17511E5906C32B7CDA7C21B67D370ACB7D85669A` | **0 DRIFT (MATCH)** |

---

## 3. Planner's Own Edits Fingerprint Manifest

The working tree already contains pre-existing and concurrent modifications by `agycage` working on confirmed skill moves (in `src/`, `tests/`, etc.). We do NOT claim that the entire working tree is docs-only. Below is the exact before/after cryptographic fingerprint of **only the files modified by `agyplan`**:

| # | File Path (All under `docs/`) | Baseline SHA256 (Before) | Updated SHA256 (After) | Modification Scope |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `docs/plan/phase-01-gameplay-demo/01-cage-physics/notes.md` | `58949AF6C41C3CAF4C0401BEC676D0B3A8593D8D92711077E9FA433CEB8118AD` | `5A259347BA031451C68687659A4161BA1C254831380822735F2AA0DC47B35F48` | Appended `## N-61` with Q1–Q6 accepted decisions |
| 2 | `docs/specs/spec-02-duel-and-parry.md` | `5D8B4F4A37CD8FDAC3A59E9DAA890AC8F61F7E9B690B38F11D484097CF3A24F0` | `EC5D911D5002408FBED3FFF17473AC2CC0CED056FD5879756459F3B724E6A81C` | Body Check loose-ball mechanics, TARGET 3 pairs keybindings vs AS-IS, stats/traits link |
| 3 | `docs/design/architecture-and-network.md` | `81D58372D042F5B905F737259D0B6A3E003E5B9400A3B9A269ED92F3C762A6BB` | `BC78BE84AF8BFA4D1E0B443EAD8B51D5940B6F0BA894284133B62CDFFF997274` | §6 updated with 13 stats, Body Check loose ball, TARGET bindings vs AS-IS |
| 4 | `docs/plan/phase-01-gameplay-demo/02-player-actions/plan.md` | `3AC3AE64ED2330703F1B5FD5CF897AE4BC77A8AAD381590B2F8BC48E930CAB55` | `06B92991096B86DEE8975581C5AC83D39FC4E3A5F3525CEE9DDC226E1AE2ACA1` | TARGET bindings map, stats/traits reception parameters, core E-FakeShot exception |
| 5 | `docs/plan/phase-01-gameplay-demo/03-dribble-duel/plan.md` | `04706249F65D22A04549A7D0321DE630842927C4A2BB1055C510C1307EB3FF9E` | `3071ECBEE854BF5371D8C839CE2945BC805F07B56A6C1E7E93A91E28CD5EED7F` | Quick Poke & Body Check replacing Shoulder Charge, traits impact, AS-IS vs TARGET |
| 6 | `docs/plan/phase-01-gameplay-demo/06-training-ground/plan.md` | `111D77156538BC9D2701122DA88F4DF653178578CD3F7D0C9DBD45C5132A2A46` | `1776F5E53A4D5A17095DF15905E4C9A1FACCE41FA22E1B8B8BDD03E3CA1C0666` | Debug tuning controls: 13 stats sliders, 16 trait toggles, 5 presets |
| 7 | `docs/plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/plan.md` | `08D407D9B3F73667F794717C11DBCD8A3A0408B62C875AA4855D85081DED4378` | `D90164B30AF5FF9D0BDDCB9255312ADCA4E6B0204CE2DC7C406FE765FEC56724` | Canonical specification: 13 Outfield Stats, 4 Deferred GK, 16 Traits, 5 Archetypes (65 values) |
| 8 | `docs/plan/phase-02-full-match-and-progression/04-collection-and-economy/plan.md` | `BFC33C52FEA4662AA7D405D8FACDF9F7EFCA51115D9AE1FA26210D178F374F24` | `440BDC90463B68E58BE5565501E7E06BC534DFE685FA7034962C45902E6DEEB4` | Innate traits only; removed BattleThreads trait slots / stones from Target |
| 9 | `docs/specs/spec-03-cards-rig-freekick.md` | `37E686DD0D8FD1B7A79308A050AB429996D596E87CE39114559F04BE4DAA97E8` | `6CCA83A03E4103809262EE3AF89BC4396D42BE922EF0D1EC0C822D5F122781C1` | 4 R6 scales linked to 5 Archetypes, skill ceilings, freekick stats link |
| 10 | `docs/specs/spec-04-traits-threads-economy.md` | `CDC7404A45EA43D6E0C7E3E33C86275D29FB85902D1BDCC04F3616C7B11BB57E` | `DD63F98A0FEFA3BA01D5E9FBEC7F0CF4AF8C48E4A01FA739DE68369ED102A5AE` | 16 Innate traits, cosmetic BattleThreads (no slots/stones), labelled history |
| 11 | `docs/design/data-schema.md` | `4D567F2DBADDDA62CB163FDB2932C11124DD9B01947D2E13A628EB52C1184A08` | `9232CD04028F67E488608E5F5BC621DF790D783CAEA307F764214879123C74B8` | Target Luau schemas (13 stats, 16 TraitId, 5 ArchetypeId, innate traits) vs Baseline history |
| 12 | `docs/READ.md` | `8873DEF866A235F1ECE1CC01EBCA06099FCE22C661C275F3316B75B7C765F5AA` | `E137CC2ABB3BDB0587FD9A30BACF4E7B6B82FF05ADDADAA630BFABD9D0FD732B` | DOCS-20261024 dispatch routing, Body Check update, reporting gate override |
| 13 | `docs/plan/roadmap.md` | `04BE8EF9C72128A63985A9351BA255F2CE5BB990A86A83E41AD859FD06885C4A` | `5A258D8816FDB462FED3E51264C607A3044B652AC4A6283CF1B9C2ADF58300F7` | Roadmap aligned with 13 stats, 16 innate traits, 5 archetypes |
| 14 | `docs/plan/phase-01-gameplay-demo/plan.md` | `67E1B18D710F78EBD7D6545AE06ADFD6B5AC462EA5A8C0C657C5785812CC8A59` | `AE625A35BA8F82B19FC2B96E6DF5A75811811F074C40D2507F9AE5A89D2B0B6B` | Plan 03 / 06 scope descriptions updated (Quick Poke / Body Check / 13 stats) |
| 15 | `docs/plan/phase-02-full-match-and-progression/plan.md` | `C977381217633BB958C192954976B73D4FB37486DF8F643B5E8AB2299D20CB3B` | `FEF7FC6706F82162C554CC60E1F0F26AF0BB0E7481CA4923E5E8BE3A2591D31B` | Plan 03 scope updated with 13 Outfield Stats, 4 GK, 16 Traits, 5 Archetypes |
| 16 | `docs/tdd/master-test-cases.md` | `26319522B740A01E7073B0F229CD057B452BF3F36338984EBE52E13B1902B9CE` | `6EC825798815F499E31A0ADAD9C833180CFFF60BE38797485D0C73C1868A9C64` | Invariants INV-03/05, test cases TC-P1-03-04, TC-P1-06-01, TC-P2-DEFER-01 |
| 17 | `docs/plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/tasks.md` | `7972446A8A04C14B8E7414EE05F9DEE336FEEA734ED6BBF519FDC72531407D8E` | `2C8C445F38D0795DF0618AFA4865285C1DDEF815D777FE7CFD6CEF5C8A340623` | Tasks D-01 through D-04 checked off |
| 18 | `docs/plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/notes.md` | `B8C569CBC8A32084B523C0DF57467F129ABB2998B8157438261EEC6BB4A65D64` | `004981413D5ED4B11D26F41BEEA06A70E94177D0D4B9034BE66D65AACB194263` | DOCS-20261024 entry added |
| 19 | `docs/plan/phase-02-full-match-and-progression/03-player-gacha-and-stats/assets/HANDOFF.md` | *(Baseline in repo)* | `EDADC88A191D377CE2B793DB95FE528C18026F2914CC36950B1FB22BC75A0B0D` | Updated with Owner reporting gate override |

---

## 4. Gap Crosswalk: AS-IS vs Planned vs Target

| Topic | AS-IS Runtime / Code State | Previous Plan / Baseline Docs | TARGET Specification (DOCS-20261024) |
| :--- | :--- | :--- | :--- |
| **Defensive Button 3** | Runtime implements `MMB` CagePress (open-field retain, wall-splat release). | `Shoulder Charge` (side-shoulder angle requirement, wall-splat stun). | **`Body Check / Dash Tackle` (RMB):** Forward valid contact against ball carrier; calculated via Strength comparison (`attackerStrength - defenderStrength`); short carrier recovery + **LOOSE ball** (pops free, no auto-possession, no I-frame, whiff recovery). |
| **Control Map** | RMB = Poke, MMB = CagePress. | 3 button pairs with Shoulder Charge on button 3. | **TARGET 3 Pairs:** LMB Shoot ↔ Slide, E Pass ↔ Poke, RMB DirectCurve ↔ BodyCheck. **MMB RETIRED.** Core charging E-FakeShot exception preserved. AS-IS code unchanged. |
| **Outfield Base Stats** | Default card / fixture has uniform 1.00 stats. | Small set of stats (Speed, Jump, ShotPower, Curve, Sliding, Strength). | **Exactly 13 Outfield Stats:** Speed, Jump, Shot Power, Curve, Sliding, Strength, Dribbling, Stamina, Pass Velocity, Accel/Dash, Poke Reach, Recovery/Reflex, Block. Bounds `0.90–1.15` (−10% to +15%, neutral `1.00`). |
| **Goalkeeper Stats** | No GK stats in codebase. | Mention of 4 GK stats (#23–#26). | **4 GK Stats Deferred:** `#23 Dive Reach`, `#24 Handling`, `#25 Reflex/Dive Recovery`, `#26 Box Distribution` deferred until Phase 1 / 04 delivery. |
| **Character Traits** | No traits implemented. | Concept draft with BattleThreads trait slots, stones, and removed #11. | **Exactly 16 Innate Traits:** Innate to character ONLY. Variable count (0, 1, 2, ...). Conditional buffs can exceed 1.15 base cap. Trivela Master grants +10% speed with single outside spin relative to normal curve (everyone retains ordinary Trivela). Trait slots/stones removed from Target. |
| **Character Archetypes** | 4 R6 scale fixtures (0.92, 0.98, 1.03, 1.08) in `CardConfigs.luau`. | Concept archetypes with partial stat mentions. | **5 Archetypes (65 values):** Speedster Striker (0.98, 4★), Cage Playmaker (0.92, 5★), Power Target (1.03, 3★), Iron Stopper (1.08, 2★), Sweeper Destroyer (1.03, 3★). All 65 values copied faithfully. |
| **Debug 06 Controls** | Planned debug panel. | Generic speed/jump sliders. | **Session-Only Controls:** 13 stat sliders, 16 trait toggles, 5 preset buttons. Strictly non-persistent; does not mutate production cards. |
| **Battle Threads & Mutations** | Legacy schema with `maxTraitSlots` and `ownedTraits`. | Concept of gear slots and stone trading. | **Cosmetic & Reward-Only:** Pure appearance + post-match Cash/EXP multipliers. Trait slots and trait stones removed from Target; historical baseline labelled. |

---

## 5. Mathematical & Inventory Verification

1. **Inventory Counts:**
   - Outfield Base Stats: Exactly 13 stats verified.
   - Goalkeeper Deferred Stats: Exactly 4 stats verified (#23, #24, #25, #26).
   - Character Traits: Exactly 16 traits verified (4 shooting/wall, 7 technique/mobility, 5 defense). Legacy #11 confirmed excluded.
   - Character Archetypes: Exactly 5 archetypes verified.
   - Preset Values Matrix: Exactly 5 archetypes × 13 stats = 65 values verified against source table.
2. **Bounds & Multiplier Math:**
   - Multiplier range: $M \in [0.90, 1.15]$ (represents $-10\%$ to $+15\%$, neutral $1.00$).
   - Delta math: $\text{statBonus} = \Delta = M - 1 \in [-0.10, +0.15]$.
   - Inverse formulas:
     - Dribbling: $\text{dribbleOffsetZ} = \text{BASE\_OFFSET} \times (1 - \Delta)$
     - Recovery: $\text{recoveryDuration} = \text{BASE\_RECOVERY} \times (1 - \Delta)$
   - Trait composition: Conditional trait buffs may take effective multiplier $> 1.15$ without clamping.
3. **Trivela Master Single Spin Inversion:**
   - Normal Curve: $\text{spinVector}$
   - Trivela: $\text{spinVector} = -\text{spinVector}$ (resolved once).
   - Trait: adds $+10\%$ speed; does NOT invert spin a second time.
4. **Link Integrity & Anchors:**
   - Relative links between `01-cage-physics/notes.md`, `spec-02-duel-and-parry.md`, `spec-03-cards-rig-freekick.md`, `spec-04-traits-threads-economy.md`, `data-schema.md`, `02-player-actions/plan.md`, `03-dribble-duel/plan.md`, `06-training-ground/plan.md`, and `03-player-gacha-and-stats/plan.md` verified.
   - Pre-existing out-of-scope broken links in other historical reports preserved untouched.

---

## 6. Remaining Open Decisions & Explicit Disclaimers

1. **Phase 2 Gacha Policies Remain Pending:**
   - Rates, pity counters, currency pricing, duplicate conversion mechanics, rerolls, and trading transaction limits are intentionally unresolved and await formal grilling when Phase 2 is unlocked.
2. **Module 00 & Phase 1 Gates Intact:**
   - Module 00 (`00-bootstrap-and-rig`) remains `OPEN / PAUSED_BY_OWNER` with F18/F19 OPEN.
   - Plan 01 (`01-cage-physics`) remains `OPEN / PENDING_TECHNICAL_REVIEW`.
   - Phase 2 remains `DEFERRED / LOCKED_UNTIL_PHASE_1_COMPLETE`.
   - No runtime code implementation has been opened by this documentation assignment.

---

## 7. Submission Status

- **Assignment Status:** `READY_FOR_REVIEW` (Documentation only).
- **Turn:** Waiting for Owner inspection in this pane. No message sent to Codex `w2:p43` before explicit Owner instruction.
