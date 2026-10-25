# Gate 1 Discovery — Correction Report 002

> **Reference:** Gate 1 Independent Review 008 (`CHANGES_REQUESTED` — Findings RF-F11 through RF-F14).  
> **Authority:** `dependency-discovery-HANDOFF.md` & latest primary `HANDOFF.md`.  
> **Role & Model:** Implementer (`agyanimation`, pane `w2:p49`), designated **3.8 Flash**, normal prompt.  
> **Baseline Commit:** HEAD `25a67d5575e31034a5a08290873b9c401357d33a` | **Seed Diff:** `617f523..HEAD` (34 files across `src/` and `tests/`).  
> **Contract & Boundary:** Strictly READ-ONLY dependency mapping and documentation corrections. Zero code deletions, zero source modifications, zero Studio operations, zero Git mutations/commits, zero application runtime tests, zero new gameplay/Idle authoring.  
> **Explicit Stop Gate:** STOP BEFORE removing old code or implementing new gameplay. Owner leads new gameplay starting from **Idle standing pose first**.

---

## 1. Summary of Review 008 Corrected Findings

| Finding ID | Severity | Root Cause & Defect in Discovery 001 | Corrective Action Applied in Manifest & Report 002 |
| :--- | :---: | :--- | :--- |
| **RF-F11** | **HIGH** | Proposed surgery named nonexistent symbols (`ActionPoseTrigger`, `AirLeanUpdate` in Network; `R6ActionPoseType`, `SkillMoveType` in Types); physical line anchors were inaccurate because `Measure-Object -Line` skipped blanks (`BallService` physical 3,366 vs 3,066 non-empty); server require/init anchors were off by 1; `InputController` ranges spanned almost entire file. | Corrected to literal diff symbols: `RemoteNames.SkillMoveRequest`, `SkillMoveReplicate`, `TackleActionRequest`, and types `KickActionType`, `ChargeActionType`, `SkillMoveId`, etc. Server bootstrap anchors corrected to exact lines 16 and 32 in `init.server.luau`. Both physical and non-empty lines explicitly reported for all 34 files. Formulated precise function-by-function hunk ranges for `InputController.luau` (2,209 lines) and `BallService.luau` (3,366 lines). |
| **RF-F12** | **HIGH** | Static regex module graph was treated as proof of safe removal; did not prove full transitive semantic/lifecycle closure, missed dynamic requires, remote handlers, and event connections; backup files were omitted. Preserved external callers were unmapped. | Disclosed all static tool limitations. Mapped preserved caller APIs: `FreeKickService` (`SetPossessor`, `SetBallPositionAndVelocity`, `GetBallState`), `ParryService` (`GetBallState`, `SetPossessor`, `GetPlayerTeamSide`). Audited `MatchService.luau` and revealed that its calls to `BallService.SpawnBall` and `StepBallPhysics` are STALE LEGACY methods from an early Phase 2 draft absent in HEAD `BallService.luau`; explicitly documented that dead legacy calls must NOT be preserved in `BallService`. |
| **RF-F13** | **HIGH** | Post-cleanup runtime contract and preservation choices were underspecified (manifest planned to keep shooting zones while Owner wanted legacy 02 removed; `CagePhysicsService` hunks were kept entirely as 'beneficial'). Future PASS on retained tests was overpromised. | Clearly delineated Plan 00/01 foundation vs legacy 02/03 gameplay to remove. Disaggregated `CagePhysicsService.luau` hunks: floor-smash downward rebound ($v.Y < -32 \rightarrow \text{restitution} = 0.84$) classified as **UNCERTAIN / PENDING TECHNICAL REVIEW**, while Gritty Lighting haze/glare/bloom adjustments classified as **PRESERVE VISUAL FIX** per Owner §14.4. Clarified that future PASS on retained Tier 1–4 tests is an **acceptance goal**, not a guaranteed outcome, because tests assert on removed 02 features and will require adaptation. |
| **RF-F14** | **MEDIUM** | Arithmetic mismatch: UNCERTAIN enumerated 7 files (14–20) while summary stated 6; 5-phase text conflicted with 7-stage diagram; checkpoint note conflated post-`617f523` lighting hunks. Complete source fingerprints and physical line metrics were missing. | Recomputed and reconciled arithmetic: 10 Pure REMOVE + 3 REPLACE/ISOLATE + 7 UNCERTAIN + 14 Shared Modified = 34 files (31,322 physical lines, 28,327 non-empty lines). Aligned 7 execution stages in both text and Mermaid diagram. Corrected checkpoint note (lighting hunks merged after `617f523` in commit `25a67d5`, preventing blind revert). Included complete 34-file source fingerprint table (bytes + SHA256) and verified docs table. |

---

## 2. Errata from Discovery Report 001

1. **Inventory Count Errata:**
   - *Previous Text:* Stated Group 3 (UNCERTAIN) was 6 files (1,510 lines).
   - *Actual Data:* The table enumerated 7 files (`TrainingHUD`, `AirLeanConfigs`, `JumpConfigs`, `SkillMoveConfigs`, `DuelUIController`, `DuelChoiceModal`, `DuelEngineService`).
   - *Correction:* Group 3 is officially 7 files (1,620 physical lines / 1,426 non-empty lines). Total seed diff is $10 + 3 + 7 + 14 = 34$ files (31,322 physical lines / 28,327 non-empty lines).
2. **Sequence Alignment Errata:**
   - *Previous Text:* Section 3 described 5 phases, while the Mermaid diagram depicted 7 stages.
   - *Correction:* Both text and Mermaid diagram are now unified into 7 discrete execution stages (Stage 1 Test Decoupling $\rightarrow$ Stage 2 Pure Tier 1 Tests $\rightarrow$ Stage 3 Client Poses $\rightarrow$ Stage 4 Client Input $\rightarrow$ Stage 5 Server Services $\rightarrow$ Stage 6 Shared Configs $\rightarrow$ Stage 7 Shared Contracts).
3. **Line Metric Coordinates Errata:**
   - *Previous Text:* `BallService.luau` was reported as 3,066 lines (from PowerShell `Measure-Object -Line`).
   - *Correction:* `Measure-Object -Line` omits empty lines. The true physical line count of `BallService.luau` is 3,366 lines. All line counts across the inventory now report both physical and non-empty metrics.
4. **Symbol Nomenclature Errata:**
   - *Previous Text:* Assumed symbols `ActionPoseTrigger`, `AirLeanUpdate` in `Network.luau` and `R6ActionPoseType`, `SkillMoveType` in `Types.luau`.
   - *Correction:* Literal diffs against `617f523..HEAD` confirm that actual added symbols are `RemoteNames.SkillMoveRequest`, `SkillMoveReplicate`, `TackleActionRequest` and types `KickActionType`, `ChargeActionType`, `SkillMoveId`, etc.
5. **Server Bootstrap Anchors Errata:**
   - *Previous Text:* Anchored server requires at lines 15 and 31.
   - *Correction:* Real source lines in `src/server/init.server.luau` are line 16 (`local SkillMoveService = require(...)`) and line 32 (`SkillMoveService.Init()`).
6. **CagePhysics Hunk Classification Errata:**
   - *Previous Text:* Kept all `CagePhysicsService.luau` hunks under a blanket claim of being 'beneficial'.
   - *Correction:* Hunks are disaggregated into UNCERTAIN floor-smash gameplay tuning (L69, L1345–1348) vs PRESERVE visual bugfix for gritty lighting (L3216–3253) per Owner §14.4.
7. **Baseline Checkpoint Errata:**
   - *Previous Text:* Checkpoint `617f523` was described as containing the visual fixes.
   - *Correction:* Commit `617f523` was the baseline before legacy gameplay; lighting and floor-smash hunks were added subsequently in commit `25a67d5`. Blind restore to `617f523` is therefore prohibited.

---

## 3. Read-Only Verification Evidence

### 3.1 Git Working Tree Cleanliness
```powershell
git -C C:\Users\Stang\cage-zero diff HEAD -- src tests
# Output: (empty - 0 bytes, 0 modifications in src/ or tests/)
```

### 3.2 Exact Server Bootstrap Anchors (`src/server/init.server.luau`)
```luau
Line 16: local SkillMoveService = require(Services:WaitForChild("SkillMoveService"))
...
Line 32: SkillMoveService.Init()
```

### 3.3 Exact Preserved Caller Invocations
```luau
-- src/server/services/FreeKickService.luau
Line 104: BallService.SetPossessor(nil)
Line 105: BallService.SetBallPositionAndVelocity(spotPosition, Vector3.zero)
Line 136: BallService.SetPossessor(nil)
Line 137: local ballState = BallService.GetBallState()
Line 139: BallService.SetBallPositionAndVelocity(startPos, trajectory.initialVelocity)

-- src/server/services/ParryService.luau
Line 85:  local ballState = BallService.GetBallState()
Line 93:  BallService.SetPossessor(userId, 0)
Line 104: local ballState = BallService.GetBallState()
Line 117: local playerTeam = BallService.GetPlayerTeamSide(player.UserId)

-- src/server/services/MatchService.luau (Stale Legacy Invocations)
Line 136: BallService.SpawnBall(session.ballId, Vector3.new(0, 4, 0))
Line 159: BallService.SpawnBall(session.ballId, Vector3.new(0, 4, 0))
Line 189: local ballState = BallService.StepBallPhysics(session.ballId, dt)
Line 264: BallService.Init()
```

---

## 4. Source Code Fingerprint Table (34 Seed Files)

| # | Status | Source File Path | Physical Lines | Non-Empty Lines | Bytes | SHA256 Hash |
| :---: | :---: | :--- | :---: | :---: | :---: | :--- |
| 1 | A | `src/client/character/R6ActionPoseController.luau` | 892 | 792 | 31,512 | `1e9bf741770416a6cd56009e98e870ea63c701a67b0c9d4b6038bd9c407d4d7f` |
| 2 | M | `src/client/character/R6AnimationController.luau` | 814 | 710 | 24,245 | `6e3a0a2a190e08e7fcf1810e17511e5906c32b7cda7c21b67d370acb7d85669a` |
| 3 | A | `src/client/controllers/CameraShiftLockController.luau` | 214 | 180 | 7,566 | `9c8c366ef910531dd5b384bd3417571cc0ad4a7555a2edda7f7ae76348fc553a` |
| 4 | M | `src/client/controllers/DuelUIController.luau` | 32 | 22 | 826 | `f0b9b2e5a3e1fa70749eb45c34a8c6777f920179654722bd1962409a5966c538` |
| 5 | M | `src/client/controllers/InputController.luau` | 2209 | 2013 | 81,952 | `3b5d87dab23a151031e2be01b727fdd0251ab20c8e6d4765dcae0120419e04c4` |
| 6 | A | `src/client/controllers/InputController.luau.bak_fc27` | 2165 | 1972 | 80,252 | `07232cb3444f71a3c6bb1328dda9691bb04d792109e71d52146f4f172fe9962a` |
| 7 | A | `src/client/controllers/TrainingHUD.luau` | 663 | 587 | 24,943 | `c45584f0b306d71ea26d9bac6e7d896b2f5b5220a26a31eb880e109a309eb1f1` |
| 8 | M | `src/client/init.client.luau` | 76 | 61 | 3,641 | `4731c0449a26ad48f1ae3385c3103643f61d64653c0f2b50799539bbc0c86c93` |
| 9 | M | `src/client/ui/screens/DuelChoiceModal.luau` | 140 | 119 | 4,033 | `a07c87593b29251fd16a23c21b96951baa4d49ec0a2016afaa6da51c51c4bf8e` |
| 10 | M | `src/server/init.server.luau` | 33 | 24 | 1,525 | `17d24b2f5199fda3f3a8bbf2cc6c469c2f7252428f48d4fc3456dcdf07926b2b` |
| 11 | M | `src/server/services/BallService.luau` | 3366 | 3066 | 128,835 | `8428841655f8a02e42b89df7aa71aa17648515e271dd96b321b9199ab830e2dd` |
| 12 | A | `src/server/services/BallService.luau.bak_fc27` | 3331 | 3030 | 127,081 | `74283c0d6d62ebf03ea7191c5d8a7b59c0de4d064869fae52706b2cf06269bfd` |
| 13 | M | `src/server/services/CagePhysicsService.luau` | 3840 | 3544 | 134,755 | `6917748947501e306b14530691076e19d3a35145f514d89fa7c6999a49234eac` |
| 14 | M | `src/server/services/DuelEngineService.luau` | 415 | 364 | 13,349 | `38a1bc895b047995eb7ce6479c88ed25cdccee348edba9022ff485c7f9149b1e` |
| 15 | A | `src/server/services/SkillMoveService.luau` | 348 | 295 | 11,923 | `26fd2d97fefa7bca3ce7dd9bdee3f2becce3ea4c86e86161d52eb15274ef01c4` |
| 16 | A | `src/shared/AirLeanSolver.luau` | 245 | 216 | 9,731 | `b61e8bda9cbd30f69a94b532d04fa082a644c0cd9a759ff0d946d2a8e2b6dd40` |
| 17 | M | `src/shared/Constants.luau` | 229 | 213 | 7,525 | `da340ae6b09bfc42ce6681b8c1871da5315621b38a17c77162bc25c0471292b6` |
| 18 | A | `src/shared/JumpModel.luau` | 123 | 109 | 3,984 | `ca95fc70e3a7199f326bd79ca18ad2d6e047afc09fe3e75ed5564800178435bc` |
| 19 | M | `src/shared/Network.luau` | 297 | 270 | 9,931 | `217668ce752348d046bf0f7963a3a72ff7133ff5ad57fafb9aea7d4a7abf96a5` |
| 20 | M | `src/shared/Types.luau` | 420 | 381 | 9,799 | `64b9e53831833c3d90f5563beeffa2171ee9abb3ea9662878c8d6216f17a0c59` |
| 21 | A | `src/shared/configs/AirLeanConfigs.luau` | 49 | 42 | 1,857 | `e78f8325e6527ce69152f7dfdbd675589c68a7e303d8e543aec906c44ca2151e` |
| 22 | A | `src/shared/configs/JumpConfigs.luau` | 50 | 41 | 1,581 | `57d83dc538ea4d59ea803979ccffce1805522cfc12098ebf3b88abed5c728c8d` |
| 23 | A | `src/shared/configs/PlayerActionPoseConfigs.luau` | 3928 | 3793 | 192,720 | `ba0ecbb542ec1134d8b742cd2cb9afdd06892d238e89adbc4b9a2fb3d190794f` |
| 24 | M | `src/shared/configs/RigAnimationConfigs.luau` | 271 | 262 | 10,012 | `e6bff0c9c2e1d1de841d9f83a1f99396cc0ba01fb89bd36aa29bb6a10e82c028` |
| 25 | A | `src/shared/configs/SkillMoveConfigs.luau` | 271 | 251 | 9,449 | `f079ab6d49817d017b60a08637efb405c197a107ed25442997277549b064cfef` |
| 26 | M | `tests/e2e/BundledTestRunner.luau` | 2191 | 1978 | 91,657 | `c9f3bb0fabedad70f1cbc912aac4944734548d26f0337a4d2cbced1eda1d586c` |
| 27 | M | `tests/e2e/TestHarness.luau` | 314 | 278 | 9,927 | `0715455c938e5585364973078c5590469495f03f666bc1096ae49d4ab5bc960b` |
| 28 | M | `tests/e2e/TestRunner.luau` | 245 | 198 | 10,213 | `cf8f795ddb68d05487962d8da27a5e5640c237f2b461a6cc994a5a220f9114f8` |
| 29 | A | `tests/e2e/Tier1_AirLeanPhysics.luau` | 530 | 444 | 24,280 | `4cd6397b14b5c9fe2d0f50a01251d99073e62afd4ef17d1b7799ab2fb57b05ad` |
| 30 | A | `tests/e2e/Tier1_BallPopPhysics.luau` | 341 | 276 | 13,474 | `0ed2f4be7eb475807112928ae723fafeebe67e12b10c91b6a235c08501538c43` |
| 31 | A | `tests/e2e/Tier1_PlayerActions.luau` | 2188 | 1877 | 103,367 | `4fe3da7a349d44f2f9d19223aeed08eec4f0d0d70f9849d2e55218adf1ea6659` |
| 32 | A | `tests/e2e/Tier1_SkillMovesAndDefense.luau` | 623 | 539 | 27,544 | `5185125aad90c4baa0049fb2e9eb6e51e30157ab16607739e2fa3bf5cc1a5981` |
| 33 | A | `tests/e2e/Tier1_StateJumpPhysics.luau` | 414 | 332 | 15,751 | `7a753656998afd184f7d1c26586b4e3c6e44d47c3f872dfd48c97b13d107a81b` |
| 34 | M | `tests/e2e/run_all.ps1` | 55 | 48 | 2,424 | `559b99f902a2599851d80440645ca4e624f6618a0595bd9b6e530ec73da05351` |

---

## 5. Active Documentation Fingerprints (27 Tracked Files)

| # | Tracked Documentation Path | Bytes | SHA256 Hash |
| :---: | :--- | :---: | :--- |
| 1 | `agent.md` | 13,861 | `449042a9e9650b7f2de6b542f2572ba213655e49bfc983911b19b6f25cd8b29c` |
| 2 | `docs/READ.md` | 5,182 | `9dab5c938db7e945c65e1101259e1cdf90987f0fb548273cefebf0b59c5ba077` |
| 3 | `docs/prd/product-requirements.md` | 11,178 | `b7ef4eee8506a332e8cdee083161b6b51a9bc18cae37622e2515b9cc21426de2` |
| 4 | `docs/tdd/master-test-cases.md` | 34,631 | `40c197628e9d8c5927945fbe9ef6c040a74e4fa916831ed8428ae1c0ee65f1dd` |
| 5 | `docs/specs/spec-01-cage-and-events.md` | 9,795 | `dffc460f4304eaa72928e0d6274e560d1b1225824c94672a1792217df946f8f8` |
| 6 | `docs/specs/spec-02-duel-and-parry.md` | 25,247 | `678f9348ca967413bcf3491060995660d6eba9cfdee8e6a4b592d92c4ae46a46` |
| 7 | `docs/specs/spec-03-cards-rig-freekick.md` | 10,480 | `f5b6c7c69643ee9255e8fa8899d292f0c33da56ebca278090e762d3a69de46e8` |
| 8 | `docs/design/architecture-and-network.md` | 47,648 | `5ccb8b862611012f472a15d6799e2fb4a22302166bae53a3f966f16ce97b288a` |
| 9 | `docs/plan/roadmap.md` | 9,506 | `065e923ef82e606f04883237af31169b556c72e7241f6bca3b92c404c67de39b` |
| 10 | `docs/plan/phase-01-gameplay-demo/plan.md` | 11,802 | `6356d8e65de172a3fb03d8817f212b1d611b654bed37ac29c9d8f26182572964` |
| 11 | `docs/plan/phase-01-gameplay-demo/release-first/plan.md` | 23,552 | `00c45f29ae914d905ce3ccb2f88350a810476657cbe627f9dacf49ae237cf7c6` |
| 12 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/plan.md` | 27,328 | `0b341e6f7a16ac7304717822da5619de76716aa34af3f8c8e024623e7f6f37de` |
| 13 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md` | 23,129 | `e57b8760de2b33fc71fd21d9c53f97a97052104df2ca3655c369b8184da5cdb8` |
| 14 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md` | 46,241 | `dbd41c0b462db6251ea1685de09fb043c7c30e7788e6c82a6cad02925c5827fb` |
| 15 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/plan.md` | 9,160 | `6a0acc990853f4cdf396a3d9e098ce1e66de2cf988011d7773ef9d1390b9cd45` |
| 16 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/tasks.md` | 4,326 | `e56035cacfc7441e1c46126395779a55d632b80263cd3e93a9c0261d934e00cb` |
| 17 | `docs/plan/phase-01-gameplay-demo/release-first/RF-03/notes.md` | 4,956 | `92226e0f948eb861ad48b2ab078e5a54ac75749097e4b022a8754438ea6e4b83` |
| 18 | `docs/plan/phase-01-gameplay-demo/release-first/RF-04/plan.md` | 8,452 | `e4c2456bbf9d1e7ea520cab841ccb2a7f1d914fedab9daedfd391164689e19ee` |
| 19 | `docs/plan/phase-01-gameplay-demo/release-first/RF-05/plan.md` | 10,134 | `0c0eeb56b8d36410445d49c57bc91676815a90392d7020abac0b9b54c92ef364` |
| 20 | `docs/plan/phase-01-gameplay-demo/release-first/RF-06/plan.md` | 8,531 | `59c46ab59f72535184af8aff993f025a8c0bde8e6e80afe28f76efd6f3cc340f` |
| 21 | `docs/plan/phase-01-gameplay-demo/release-first/RF-07/plan.md` | 6,814 | `689969a2b1bc6cb3d60ba1b628d87e5bd95d6a16bb7b4ba6c212cb1c997a9f16` |
| 22 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-001.md` | 22,456 | `87d73831e55d9da42ac0c0b3d30d19e2b81b0a37163151fef5b4d547c761ba56` |
| 23 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-002.md` | 16,452 | `c35c0026a49089797d0992adace93e3c69360699790d22f56cbf2e8b5b68a423` |
| 24 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-003.md` | 18,752 | `8eba6edc34ac917f64938bc0165e39d177d705b458b4b00b883ed98b993814e1` |
| 25 | `docs/plan/phase-01-gameplay-demo/release-first/assets/delta-004.md` | 18,522 | `c07afb5d7ecaf9caec767269b5dbbcbc1bf9260f1f8a765b77e958bca2672aa2` |
| 26 | `docs/plan/phase-01-gameplay-demo/release-first/assets/discovery-report-001.md` | 14,167 | `23d07091ffa35710bcb3e537d47e1265b851336f21e2ac6f6fd1cba462342873` |
| 27 | `docs/plan/phase-01-gameplay-demo/release-first/assets/removal-manifest.md` | 30,829 | `9905e2a30367197d39d6268821539f3bc59e659c8120ce5ccf832f30544391d5` |

---

## 6. Stop Gate Enforcement & Next Action

> [!IMPORTANT]
> **GATE 1 READ-ONLY DISCOVERY COMPLETE — STOP GATE ACTIVATED:**  
> All 4 findings RF-F11 through RF-F14 from Review 008 are fully addressed with source-backed evidence.  
> As required by the contract and Owner directive:
> 1. ZERO code removal, zero source modifications, zero Studio operations, and zero Git mutations have been performed.
> 2. Implementer STOP is strictly enforced before any runtime surgery or new gameplay authoring.
> 3. Codex Controller will present the concrete deletion scope from `removal-manifest.md` to Owner for confirmation.
> 4. After Owner authorization, Owner will lead new gameplay authoring starting from **Idle standing pose first**.
