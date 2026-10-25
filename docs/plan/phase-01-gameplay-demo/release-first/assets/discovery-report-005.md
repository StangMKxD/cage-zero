# Gate 1 Discovery — Correction Report 005

> **Reference:** Gate 1 Independent Review 011 (`CHANGES_REQUESTED` — Remaining Cleanup Boundaries Only).  
> **Authority:** `dependency-discovery-HANDOFF.md` & latest primary `HANDOFF.md`.  
> **Role & Model:** Implementer (`agyanimation`, pane `w2:p49`), designated **3.8 Flash**, normal prompt. (No Argon re-assignment).  
> **Baseline Commit:** HEAD `25a67d5575e31034a5a08290873b9c401357d33a` | **Seed Diff:** `617f523..HEAD` (34 files across `src/` and `tests/`).  
> **Contract & Boundary:** Strictly READ-ONLY dependency mapping and documentation corrections. Zero code deletions, zero source modifications, zero Studio operations, zero Git mutations/commits, zero application runtime tests, zero new gameplay/Idle authoring.  
> **Explicit Stop Gate:** STOP BEFORE removing old code or implementing new gameplay. Owner leads new gameplay starting from **Idle standing pose first**.

---

## 1. Summary of Review 011 Dispositions & Focused Corrections

| Finding ID | Review 011 Status | Core Defect in Discovery 004 | Corrective Action Applied in Manifest & Report 005 |
| :--- | :---: | :--- | :--- |
| **RF-F11** | **OPEN (Narrowed to BallService range)** | Manifest §3.2 claimed L2550–2851 was a free-ball block to preserve intact. In reality, L2550 is still inside the possession branch (which extends through L2721 and includes tackles/off-balance at L2690–2718). Free ball branch only begins at `else` L2722 (comment L2723), and even that branch contains legacy interception/auto-possession at L2776–2829. | Corrected exact line partition of `BallService.StepPhysics`:<br>1. **L2451–2721 (Possession Branch):** Excise legacy dragBack/close-control and tackles/off-balance (L2690–2718). Retain alive-possessor check.<br>2. **L2722–2775 (Free Ball Solver Subset):** RETAIN foundation gravity, turf contact, and cage containment/rebound physics.<br>3. **L2776–2829 (Legacy Collection Loop):** EXCISE legacy cooldowns/interception. Mark future reception policy as **PENDING TECHNICAL CONTRACT & OWNER AERIAL/GROUND CONTROL SPEC**.<br>4. **L2830–2850 (Part Sync):** RETAIN foundation position, roll spin, and Part CFrame sync. |
| **RF-F12** | **OPEN (Remaining Symbol Closure)** | Deleting player-state processing while keeping old collection/interception code (L2776–2829) would leave dangling state references. | Excised the legacy collection loop (L2776–2829) from the free-ball step, completely removing `playerStates` references from free-ball physics. Delineated the autonomous solver/part-sync statements and their exact self-contained dependencies. |
| **RF-F13** | **OPEN (Unauthorized New-Gameplay Postcondition)** | Manifest §5.1 promised normalized R15 immediately after cleanup, and §3.2 introduced a simplified "fixed 1.8-stud dribble" plus clean movement redesign as cleanup invariants. | **Explicitly separated immediate cleanup invariants from future new gameplay proposals:**<br>1. **Existing Rig Foundation Unchanged:** Cleanup preserves existing Module 00 Custom R6 foundation. R15 avatar normalization begins ONLY after Owner approves new Idle first.<br>2. **Zero Invented Dribbling Mechanics:** Cleanup does NOT implement a new 1.8-stud dribble. Possession is minimally held or released to Free. Dribble kinematics and ball reception are marked **PROPOSED FUTURE GAMEPLAY (PENDING OWNER DIRECTION)**. |

---

## 2. Targeted Errata from Discovery Report 004

1. **BallService.StepPhysics Range Classification Errata (RF-F11):**
   - *Previous Text:* Claimed L2550–2851 was free-ball physics to retain intact.
   - *Actual Source:*
     - L2550 is still inside the possession branch (`if ballState.state == "Possessed"`), which continues through L2721 and contains tackles/off-balance stumbles at L2690–2718.
     - The free-ball branch begins at `else` L2722 (comment L2723).
     - Inside that branch, L2776–2829 contains legacy swept proximity collection, kicker cooldowns, and auto-possession.
     - Only L2724–2775 (autonomous solver) and L2830–2850 (part sync) are true foundation statements.
2. **Post-Cleanup Rig & Dribble Postcondition Errata (RF-F13):**
   - *Previous Text:* Promised R15 avatar baseline and simplified 1.8-stud dribble as immediate cleanup postconditions.
   - *Actual Policy:* Immediate cleanup touches NO rig assets and invents NO new dribble mechanics. Rig remains existing Custom R6 foundation; R15 and new dribble/reception mechanics begin only when Owner leads new gameplay starting from Idle standing pose first.

---

## 3. Read-Only Verification Evidence

### 3.1 Git Working Tree Cleanliness
```powershell
git -C C:\Users\Stang\cage-zero diff HEAD -- src tests
# Output: (empty - 0 bytes, 0 modifications in src/ or tests/)
```

### 3.2 Exact Boundary Verification in `src/server/services/BallService.luau`
```luau
-- Possession branch end & Free ball branch start
Line 2721: 		end
Line 2722: 	else
Line 2723: 		-- Free or InFlight Ball
Line 2724: 		local r = Constants.BALL_RADIUS
...
-- Legacy collection loop inside Free branch (Excised / Marked Pending)
Line 2776: 		-- F-10 & F-11: Swept contact and relative body height check (no 0.3s global immunity!)
Line 2782: 		for userId, st in pairs(playerStates) do
Line 2823: 							BallService.SetPossessor(userId)
Line 2829: 		end
...
-- Final Part synchronization (Retained Foundation)
Line 2831: 		ballState.position = nextPos
Line 2832: 		ballState.velocity = nextVel
Line 2846: 	if ballPart then
Line 2847: 		ballPart.CFrame = CFrame.new(ballState.position) * ballSpinRotation
Line 2848: 	end
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

## 5. Active Documentation Fingerprints (31 Tracked Files)

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
| 13 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/tasks.md` | 24,621 | `a91d8c31dc70f37150ed5460b354799fe5002b35b2a5cd2184dc0e078c99fb0b` |
| 14 | `docs/plan/phase-01-gameplay-demo/release-first/RF-02/notes.md` | 47,727 | `143a135219b8be95055dbe7a069dfcce6384fd7fcfc0b33cac4b00392f667109` |
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
| 30 | `docs/plan/phase-01-gameplay-demo/release-first/assets/discovery-report-004.md` | 18,061 | `e2969e35a67dd69ecd0bf8831843056ad73ffcb609828e06bd299e0bdbb4fa60` |
| 31 | `docs/plan/phase-01-gameplay-demo/release-first/assets/removal-manifest.md` | 31,873 | `398806e5198df8ca8ad7e09b289863dcdbc70958b78102b4cadd99c49912ad54` |

---

## 6. Stop Gate Enforcement & Next Action

> [!IMPORTANT]
> **GATE 1 READ-ONLY DISCOVERY COMPLETE — STOP GATE ACTIVATED:**  
> All cleanup boundaries and internal function partitions are verified against literal source:
> 1. RF-F11 range classifications in `BallService.StepPhysics` corrected to exact lines (L2451–2721 possession/tackles, L2722–2775 free solver, L2776–2829 legacy collection, L2830–2850 part sync).
> 2. RF-F12 symbol closure confirmed with zero remaining `playerStates` references in the free-ball step.
> 3. RF-F13 immediate cleanup contract strictly preserves existing Custom R6 foundation (no premature R15 promises) and invents zero new dribbling mechanics (dribble & reception marked PENDING Owner Idle direction).
> 
> **MANDATORY STOP:** Implementer STOP is strictly enforced before any runtime surgery or new gameplay authoring. Codex Controller will present the concrete deletion scope to Owner for confirmation. After Owner authorization, Owner will lead new gameplay authoring starting from **Idle standing pose first**.
