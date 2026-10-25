# Gate 1 Discovery — Correction Report 004

> **Reference:** Gate 1 Independent Review 010 (`CHANGES_REQUESTED` — Narrowed Remaining Source-Evidence Corrections).  
> **Authority:** `dependency-discovery-HANDOFF.md` & latest primary `HANDOFF.md`.  
> **Role & Model:** Implementer (`agyanimation`, pane `w2:p49`), designated **3.8 Flash**, normal prompt. (Argon spot audit completed; no further Argon work).  
> **Baseline Commit:** HEAD `25a67d5575e31034a5a08290873b9c401357d33a` | **Seed Diff:** `617f523..HEAD` (34 files across `src/` and `tests/`).  
> **Contract & Boundary:** Strictly READ-ONLY dependency mapping and documentation corrections. Zero code deletions, zero source modifications, zero Studio operations, zero Git mutations/commits, zero application runtime tests, zero new gameplay/Idle authoring.  
> **Explicit Stop Gate:** STOP BEFORE removing old code or implementing new gameplay. Owner leads new gameplay starting from **Idle standing pose first**.

---

## 1. Summary of Review 010 Dispositions & Targeted Evidence

| Finding ID | Review 010 Status | Remaining Requirement | Corrective Action Applied in Manifest & Report 004 |
| :--- | :---: | :--- | :--- |
| **RF-F14** | **VERIFIED** | Metrics explicitly distinguish Get-Content/Split/Nonempty; category counts coherent; snapshot fingerprints current. | Maintained standardized 3-metric reporting ($31,288$ GC / $31,322$ split / $28,327$ nonempty lines; $1,231,664$ bytes). |
| **RF-F15** | **VERIFIED** | Plan ordering verified (client callers before providers, server callers before server providers; atomic non-runnable edit group and Studio sync barrier stated). | Maintained strict consumer-before-provider sequence. Updated Mermaid diagram to explicitly depict that UNCERTAIN items are **HELD pending Owner decision**, not unconditionally deleted. |
| **RF-F11** | **OPEN (Narrowed)** | Fix exact 3 literal field names in `Types.PlayerMovementSnapshot` at lines 342, 357, and 358. | Corrected to exact source literals: `chargeCurveSide: CurveSideIntent?` (L342), `activeSkillMove: SkillMoveId?` (L357), and `activeTackle: TackleActionType?` (L358). Mapped all coupled fields in `BallSnapshot` (L318) and `PlayerMovementSnapshot` (L330–359). |
| **RF-F12 / RF-F13** | **OPEN (Narrowed)** | Establish **Retained-Function Internal Closure** for `BallService.Init`, `BallService.StepPhysics`, and `InputController.Init`/`bindChar`. Avoid arbitrary mid-function slices. Trace all internal callbacks, helpers, and state references until zero calls to removed providers remain. | **Complete internal closure established:**<br>1. **`BallService.Init`:** L3337–3341 (`BallActionRequest` remote listener to `HandleActionRequest`) is **REMOVED**; `setupPlayerLifecycle` (L2852–2980) is **ADAPTED** to excise stamina/jump disabling; L3351–3356 (`pendingCagePresses` clearing) is **REMOVED**; foundation ball spawning, reset, and possessor release on disconnect are **RETAINED**.<br>2. **`BallService.StepPhysics`:** Player state loop (L2274–2450) is **REMOVED** (deleting stamina drain, dashing, cage press, and directional jump FSM calling `JumpModel`); dribble following is **ADAPTED** to fixed socket offset (excising skill-busy/dragBack); free ball trajectory and stadium polytope containment (L2550–2851) are **RETAINED**.<br>3. **`InputController.Init` & `bindChar`:** Top-level requires (L17–28) are **EXCISED in Stage 3**; `bindChar` (L1302–1528) is **ADAPTED as a unified closure** (deleting humanoid jump suppression, landing recovery pose listeners, and action status listeners); RenderStepped loop (L1550–1912) and legacy keybinds (L1913–2150) are **EXCISED**; standard ShiftLock and camera WASD movement vectors are **RETAINED**. |

---

## 2. Targeted Errata from Discovery Report 003

1. **Exact Types Field Names Errata (RF-F11):**
   - *Previous Text:* Named fields as `curveSide`, `skillMoveId`, and `tackleType`.
   - *Actual Source:* In `src/shared/Types.luau` (`PlayerMovementSnapshot` L321–360):
     - Line 342 is `chargeCurveSide: CurveSideIntent?,`
     - Line 357 is `activeSkillMove: SkillMoveId?,`
     - Line 358 is `activeTackle: TackleActionType?,`
2. **BallService.Init Internal Closure Errata (RF-F12/13):**
   - *Previous Text:* Broadly labeled `BallService.Init` (L3320–3366) as KEEP foundation.
   - *Actual Source:* Lines 3339–3341 connect `BallActionRequest` to `HandleActionRequest` (which is marked REMOVE). Lines 3351–3356 clear `pendingCagePresses` (cage press is marked REMOVE). These lines must be excised/adapted, not kept as-is.
3. **BallService.StepPhysics Internal Closure Errata (RF-F12/13):**
   - *Previous Text:* Broadly labeled `BallService.StepPhysics` (L2271–2851) as KEEP foundation with a vague skill-hook note.
   - *Actual Source:* Lines 2274–2450 execute the player state loop, containing stamina drain/regen, dash decay, directional jump FSM calling removed `JumpModel`, slide recovery, and cage press wall splatting. This entire block (L2274–2450) must be excised. Only free ball physics stepping (L2550–2851) and basic dribble socket following are retained.
4. **InputController.Init & bindChar Syntactic Slice Errata (RF-F12/13):**
   - *Previous Text:* Cited Lines 1294–1327 as retained foundation.
   - *Actual Source:* Line 1302 opens `local function bindChar(char: Model)`, which continues to Line 1528. Slicing at 1327 leaves an unclosed function. Furthermore, Lines 17–28 require removed modules, and lines 1353–1356 disable humanoid jumping. `bindChar` must be adapted as a unified closure, restoring default Roblox jumping and excising action pose/status listeners.
5. **Mermaid Diagram UNCERTAIN Treatment Errata:**
   - *Previous Diagram:* Depicted Stage 6 deleting UNCERTAIN configs.
   - *Actual Policy:* All 7 UNCERTAIN files (`TrainingHUD`, `AirLeanConfigs`, `JumpConfigs`, `SkillMoveConfigs`, `DuelUIController`, `DuelChoiceModal`, `DuelEngineService`) are **EXPLICITLY EXCLUDED from immediate cleanup**. Their consumer hooks are decoupled, and the files remain untouched on disk pending Owner review.

---

## 3. Read-Only Verification Evidence

### 3.1 Git Working Tree Cleanliness
```powershell
git -C C:\Users\Stang\cage-zero diff HEAD -- src tests
# Output: (empty - 0 bytes, 0 modifications in src/ or tests/)
```

### 3.2 Exact Types Literal Fields (`src/shared/Types.luau`)
```luau
Line 342: 	chargeCurveSide: CurveSideIntent?,
...
Line 357: 	activeSkillMove: SkillMoveId?,
Line 358: 	activeTackle: TackleActionType?,
```

### 3.3 Exact Retained-Function Internals Verification
```luau
-- src/server/services/BallService.luau L3339-3341 (Excised in Stage 5)
3339: 	ballActionEvent.OnServerEvent:Connect(function(player: Player, actionPayload: any, maybeAim: any, maybeCharge: any)
3340: 		BallService.HandleActionRequest(player, actionPayload, maybeAim, maybeCharge)
3341: 	end)

-- src/client/controllers/InputController.luau L17-28 (Excised in Stage 3)
17: local AirLeanSolver = require(Shared:WaitForChild("AirLeanSolver"))
18: local JumpModel = require(Shared:WaitForChild("JumpModel"))
20: local PlayerActionPoseConfigs = require(SharedConfigs:WaitForChild("PlayerActionPoseConfigs"))
26: local R6ActionPoseController = require(Character:WaitForChild("R6ActionPoseController"))
28: local TrainingHUD = require(Controllers:WaitForChild("TrainingHUD"))
```

---

## 4. Source Code Fingerprint Table (34 Seed Files)

| # | Status | Source File Path | `Get-Content` Lines | `Split-Lines` | Non-Empty Lines | Bytes | SHA256 Hash |
| :---: | :---: | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | A | `src/client/character/R6ActionPoseController.luau` | 891 | 892 | 792 | 31,512 | `1e9bf741770416a6cd56009e98e870ea63c701a67b0c9d4b6038bd9c407d4d7f` |
| 2 | M | `src/client/character/R6AnimationController.luau` | 813 | 814 | 710 | 24,245 | `6e3a0a2a190e08e7fcf1810e17511e5906c32b7cda7c21b67d370acb7d85669a` |
| 3 | A | `src/client/controllers/CameraShiftLockController.luau` | 213 | 214 | 180 | 7,566 | `9c8c366ef910531dd5b384bd3417571cc0ad4a7555a2edda7f7ae76348fc553a` |
| 4 | M | `src/client/controllers/DuelUIController.luau` | 31 | 32 | 22 | 826 | `f0b9b2e5a3e1fa70749eb45c34a8c6777f920179654722bd1962409a5966c538` |
| 5 | M | `src/client/controllers/InputController.luau` | 2208 | 2209 | 2013 | 81,952 | `3b5d87dab23a151031e2be01b727fdd0251ab20c8e6d4765dcae0120419e04c4` |
| 6 | A | `src/client/controllers/InputController.luau.bak_fc27` | 2164 | 2165 | 1972 | 80,252 | `07232cb3444f71a3c6bb1328dda9691bb04d792109e71d52146f4f172fe9962a` |
| 7 | A | `src/client/controllers/TrainingHUD.luau` | 662 | 663 | 587 | 24,943 | `c45584f0b306d71ea26d9bac6e7d896b2f5b5220a26a31eb880e109a309eb1f1` |
| 8 | M | `src/client/init.client.luau` | 75 | 76 | 61 | 3,641 | `4731c0449a26ad48f1ae3385c3103643f61d64653c0f2b50799539bbc0c86c93` |
| 9 | M | `src/client/ui/screens/DuelChoiceModal.luau` | 139 | 140 | 119 | 4,033 | `a07c87593b29251fd16a23c21b96951baa4d49ec0a2016afaa6da51c51c4bf8e` |
| 10 | M | `src/server/init.server.luau` | 32 | 33 | 24 | 1,525 | `17d24b2f5199fda3f3a8bbf2cc6c469c2f7252428f48d4fc3456dcdf07926b2b` |
| 11 | M | `src/server/services/BallService.luau` | 3365 | 3366 | 3066 | 128,835 | `8428841655f8a02e42b89df7aa71aa17648515e271dd96b321b9199ab830e2dd` |
| 12 | A | `src/server/services/BallService.luau.bak_fc27` | 3330 | 3331 | 3030 | 127,081 | `74283c0d6d62ebf03ea7191c5d8a7b59c0de4d064869fae52706b2cf06269bfd` |
| 13 | M | `src/server/services/CagePhysicsService.luau` | 3839 | 3840 | 3544 | 134,755 | `6917748947501e306b14530691076e19d3a35145f514d89fa7c6999a49234eac` |
| 14 | M | `src/server/services/DuelEngineService.luau` | 414 | 415 | 364 | 13,349 | `38a1bc895b047995eb7ce6479c88ed25cdccee348edba9022ff485c7f9149b1e` |
| 15 | A | `src/server/services/SkillMoveService.luau` | 347 | 348 | 295 | 11,923 | `26fd2d97fefa7bca3ce7dd9bdee3f2becce3ea4c86e86161d52eb15274ef01c4` |
| 16 | A | `src/shared/AirLeanSolver.luau` | 244 | 245 | 216 | 9,731 | `b61e8bda9cbd30f69a94b532d04fa082a644c0cd9a759ff0d946d2a8e2b6dd40` |
| 17 | M | `src/shared/Constants.luau` | 228 | 229 | 213 | 7,525 | `da340ae6b09bfc42ce6681b8c1871da5315621b38a17c77162bc25c0471292b6` |
| 18 | A | `src/shared/JumpModel.luau` | 122 | 123 | 109 | 3,984 | `ca95fc70e3a7199f326bd79ca18ad2d6e047afc09fe3e75ed5564800178435bc` |
| 19 | M | `src/shared/Network.luau` | 296 | 297 | 270 | 9,931 | `217668ce752348d046bf0f7963a3a72ff7133ff5ad57fafb9aea7d4a7abf96a5` |
| 20 | M | `src/shared/Types.luau` | 419 | 420 | 381 | 9,799 | `64b9e53831833c3d90f5563beeffa2171ee9abb3ea9662878c8d6216f17a0c59` |
| 21 | A | `src/shared/configs/AirLeanConfigs.luau` | 48 | 49 | 42 | 1,857 | `e78f8325e6527ce69152f7dfdbd675589c68a7e303d8e543aec906c44ca2151e` |
| 22 | A | `src/shared/configs/JumpConfigs.luau` | 49 | 50 | 41 | 1,581 | `57d83dc538ea4d59ea803979ccffce1805522cfc12098ebf3b88abed5c728c8d` |
| 23 | A | `src/shared/configs/PlayerActionPoseConfigs.luau` | 3927 | 3928 | 3793 | 192,720 | `ba0ecbb542ec1134d8b742cd2cb9afdd06892d238e89adbc4b9a2fb3d190794f` |
| 24 | M | `src/shared/configs/RigAnimationConfigs.luau` | 270 | 271 | 262 | 10,012 | `e6bff0c9c2e1d1de841d9f83a1f99396cc0ba01fb89bd36aa29bb6a10e82c028` |
| 25 | A | `src/shared/configs/SkillMoveConfigs.luau` | 270 | 271 | 251 | 9,449 | `f079ab6d49817d017b60a08637efb405c197a107ed25442997277549b064cfef` |
| 26 | M | `tests/e2e/BundledTestRunner.luau` | 2190 | 2191 | 1978 | 91,657 | `c9f3bb0fabedad70f1cbc912aac4944734548d26f0337a4d2cbced1eda1d586c` |
| 27 | M | `tests/e2e/TestHarness.luau` | 313 | 314 | 278 | 9,927 | `0715455c938e5585364973078c5590469495f03f666bc1096ae49d4ab5bc960b` |
| 28 | M | `tests/e2e/TestRunner.luau` | 244 | 245 | 198 | 10,213 | `cf8f795ddb68d05487962d8da27a5e5640c237f2b461a6cc994a5a220f9114f8` |
| 29 | A | `tests/e2e/Tier1_AirLeanPhysics.luau` | 529 | 530 | 444 | 24,280 | `4cd6397b14b5c9fe2d0f50a01251d99073e62afd4ef17d1b7799ab2fb57b05ad` |
| 30 | A | `tests/e2e/Tier1_BallPopPhysics.luau` | 340 | 341 | 276 | 13,474 | `0ed2f4be7eb475807112928ae723fafeebe67e12b10c91b6a235c08501538c43` |
| 31 | A | `tests/e2e/Tier1_PlayerActions.luau` | 2187 | 2188 | 1877 | 103,367 | `4fe3da7a349d44f2f9d19223aeed08eec4f0d0d70f9849d2e55218adf1ea6659` |
| 32 | A | `tests/e2e/Tier1_SkillMovesAndDefense.luau` | 622 | 623 | 539 | 27,544 | `5185125aad90c4baa0049fb2e9eb6e51e30157ab16607739e2fa3bf5cc1a5981` |
| 33 | A | `tests/e2e/Tier1_StateJumpPhysics.luau` | 413 | 414 | 332 | 15,751 | `7a753656998afd184f7d1c26586b4e3c6e44d47c3f872dfd48c97b13d107a81b` |
| 34 | M | `tests/e2e/run_all.ps1` | 54 | 55 | 48 | 2,424 | `559b99f902a2599851d80440645ca4e624f6618a0595bd9b6e530ec73da05351` |

---

## 5. Active Documentation Fingerprints (30 Tracked Files)

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
| 13 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md` | 24,054 | `aba52fdfe206bd392c91e5245cfdfb1b15f28caaec1c1d6cf9869a20c2217aef` |
| 14 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md` | 47,139 | `fd3a01b66b7d8cd5140f23359dab39518c8b7686b68d61b10360a5019c3b506a` |
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
| 26 | `docs/plan/phase-01-gameplay-demo/release-first/assets/discovery-spot-audit.md` | 9,902 | `ae36d059f0ae0dfaa7a09e8b562668117a842a1fc62a2dfb6e8c7dd48b1df9d9` |
| 27 | `docs/plan/phase-01-gameplay-demo/release-first/assets/discovery-report-001.md` | 14,167 | `23d07091ffa35710bcb3e537d47e1265b851336f21e2ac6f6fd1cba462342873` |
| 28 | `docs/plan/phase-01-gameplay-demo/release-first/assets/discovery-report-002.md` | 18,180 | `dcce21cb408b6114ce27f6c488d1cb6c182337da4c3bb86a52029625e82976ed` |
| 29 | `docs/plan/phase-01-gameplay-demo/release-first/assets/discovery-report-003.md` | 19,259 | `c128cef2c26f7a0f7ad12ad732b9afef6c43759c7ce90bf4231e3660b5e081de` |
| 30 | `docs/plan/phase-01-gameplay-demo/release-first/assets/removal-manifest.md` | 29,657 | `a98e81f2ee427320b753001642c6a7d9477882ad8039a8a1d6396d31a41cc359` |

---

## 6. Stop Gate Enforcement & Next Action

> [!IMPORTANT]
> **GATE 1 READ-ONLY DISCOVERY COMPLETE — STOP GATE ACTIVATED:**  
> All requirements from Review 008, 009, and 010 are fully satisfied with source-backed evidence:
> 1. RF-F14 line metrics verified and consistent down to the single digit.
> 2. RF-F15 consumer-before-provider order verified and enforced.
> 3. RF-F11 literal field names in `Types.luau` corrected.
> 4. RF-F12 / RF-F13 internal retained-function closure for `BallService.Init`, `StepPhysics`, and `InputController.Init`/`bindChar` fully traced and detailed.
> 5. UNCERTAIN files explicitly excluded from immediate deletion in both text and diagram.
> 
> **MANDATORY STOP:** Implementer STOP is strictly enforced before any runtime surgery or new gameplay authoring. Codex Controller will present the concrete deletion scope to Owner for confirmation. After Owner authorization, Owner will lead new gameplay authoring starting from **Idle standing pose first**.
