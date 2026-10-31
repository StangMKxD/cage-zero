# RF02-MIXAMO-LEG-BASIS — Implementation & Validation Report

> **Follow-up UPDATE — two revised clips, READY_FOR_REVIEW:** Implementer แจ้ง Owner พบ GoalkeeperSidestep เข่าหุบ และ StrikeFowardJog เท้าหลุด. รายงานว่าแก้ Sidestep ด้วย clean in-place retarget ป้องกันขาไขว้ และ Strike ด้วยการลบ stray RightFoot location curve; render ใหม่ไป outputagy/v2 และ re-import Studio AnimSaves แล้ว. ข้อความนี้บันทึกคำรายงาน ไม่ใช่ independent verification. ฉบับแก้สองท่านี้ยังรอ Owner ตรวจใหม่; GIF acceptance ก่อนหน้าคงเป็นประวัติของชุดก่อนแก้เท่านั้น

> **Owner acceptance 2026-10-30 — GIF ONLY:** Owner กล่าวว่า “เช็คแล้วได้ๆ ผ่าน ที่ดูจาก gif เท่านั้น” หลังรับรายงานนี้. บันทึก OWNER_VISUAL_ACCEPTED_GIF_ONLY; READY_FOR_REVIEW ด้านเทคนิคคงแยกอยู่. รายละเอียดการ import/ผลตรวจด้านล่างเป็นหลักฐานที่ Implementer รายงาน ไม่ใช่การตรวจอิสระของ Controller รอบนี้ และไม่ใช่การรับรอง native Studio playback/gameplay integration หรืออนุญาต commit/publish

**Task ID:** `RF02-MIXAMO-LEG-BASIS`  
**Governance:** `OWNER_STANDARD`  
**Role:** `Implementer`  
**Controller:** Codex (`w2:p52`)  
**Project Root:** `C:\Users\Stang\cage-zero`  
**Date:** 2026-10-30  
**Status:** `READY_FOR_REVIEW`  

---

## 1. Executive Summary

Following Owner acceptance of **Jog Forward v02** (`RF02_JogForwardMixamo_R15_v02`) as the authoritative reference for R15 leg basis correction, the Implementer has executed the verified leg-bind-basis roll correction across the remaining **14 animations** in `cage-zero-animation-work/`:
- **Outfield (8 clips):** `Fast Run`, `Scissor Kick`, `Soccer Pass`, `Soccer Tackle`, `Soccer Trip`, `Standing Idle 02`, `Standing Jump`, `Strike Foward Jog`, `TurnBackRunning`.
- **Goalkeeper (5 clips):** `Goalkeeper Catch`, `Goalkeeper Diving Save`, `Goalkeeper Overhand Throw`, `Goalkeeper Scoop`, `Goalkeeper Sidestep`.
- **Reference (1 clip):** `Jog Forward` (v02 accepted by Owner).

### Root Cause Analysis & Mathematical Solution
- **The Defect:** Mixamo's source armature (`UpLeg` and `Leg`) has its front roll axis oriented approximately 180° opposite the Roblox R15 target rig (`UpperLeg` and `LowerLeg`). In initial retargeting (v01), torso and foot rest-space compensations were applied, but femur and calf bones inherited global orientations directly, producing negative dot products ($\approx -0.85$ to $-0.99$) against the target neutral front axis.
- **The Fix:** An exact half-turn around the native joint axes ($\text{Hip } A_1 \to \text{Knee } A_0$ and $\text{Knee } A_1 \to \text{Ankle } A_0$) was applied via verified FK transform:
  $$W_{\text{child}}^{\text{fixed}} = W_{\text{child}} \cdot R_{\text{roll}}(\pi, \vec{a})$$
  $$P_{\text{local}}^{\text{fixed}} = A_0^{-1} \cdot (W_{\text{parent}}^{\text{fixed}})^{-1} \cdot W_{\text{child}}^{\text{fixed}} \cdot A_1$$
- **Preservation Gates Achieved:**
  - Joint endpoint pivots preserved: max deviation $\le 2.99 \times 10^{-8}$ studs (gate threshold $\le 0.00005$ studs).
  - World foot matrices preserved: max deviation $\le 2.84 \times 10^{-8}$ (gate threshold $\le 0.00005$).
  - Upper body parts 100% untouched: max deviation $\le 2.84 \times 10^{-8}$.
  - Non-root local translation: $\le 8.96 \times 10^{-6}$ studs (no artificial leg elongation).
  - Front axis dots transitioned from negative ($-0.50$ to $-0.99$) to forward facing ($+0.70$ to $+0.998$).

---

## 2. Source FBX Integrity (Read-Only Baseline)

All 15 source Mixamo FBX files under `C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo` remain strictly untouched and read-only. Cryptographic verification matches the baseline SHA-256 hashes:

| # | Animation Name | Relative Source Path | SHA-256 Hash | Integrity Status |
|---|---|---|---|---|
| 1 | Jog Forward | `Jog Forward.fbx` | `836ef89582f9382598d0b2edd82f57d3cb8c29dc136a512e45d5637a70c4c2ef` | UNTOUCHED (PASS) |
| 2 | Fast Run | `Fast Run.fbx` | `822fdc9d28ac97c53fac37717f20a51a286b44fd389b135119467ec794e912ab` | UNTOUCHED (PASS) |
| 3 | Scissor Kick | `Scissor Kick.fbx` | `5e43f565ece6768118c83bf6a4c7c5a08ecee4aa6b112ba1c5591065f13687b4` | UNTOUCHED (PASS) |
| 4 | Soccer Pass | `Soccer Pass.fbx` | `b10d8adcc2726a30dcc6bb691fd3db7d943272780397c87397745806db71156b` | UNTOUCHED (PASS) |
| 5 | Soccer Tackle | `Soccer Tackle.fbx` | `e2bdc6a031d770c35f2bf6ced4efcf15a1ba9154adf5596b0092215cc9942cd0` | UNTOUCHED (PASS) |
| 6 | Soccer Trip | `Soccer Trip.fbx` | `508ceeb3ea6d41b95f71f611616040b586aeec77901c3ac53540481af349616a` | UNTOUCHED (PASS) |
| 7 | Standing Idle 02 | `Standing Idle 02.fbx` | `b5c38648952d1a547801200befb9b3e7fc2f3fea1e6f46cb215d12d37551cdbf` | UNTOUCHED (PASS) |
| 8 | Standing Jump | `Standing Jump.fbx` | `5bdf56bb036ec76cfb53bcad13f06a7d24fe2c4a0b32a04798f3e5b865d9811e` | UNTOUCHED (PASS) |
| 9 | Strike Foward Jog | `Strike Foward Jog.fbx` | `271b484652b91ed6945cae0361008e4ceea43f0797171e065bc3e34b9d0e234d` | UNTOUCHED (PASS) |
| 10 | TurnBackRunning | `TurnBackRunning.fbx` | `eb02912e98fdbaecb7950d2fb8daf9c9bb81bf0a256d64d94fec9fa1fc549ee1` | UNTOUCHED (PASS) |
| 11 | Goalkeeper Catch | `goal/Goalkeeper Catch.fbx` | `52160c2135cda64b59e65d1ca0b8c29855328b8623127310ccd741ae54c4c9b8` | UNTOUCHED (PASS) |
| 12 | Goalkeeper Diving Save | `goal/Goalkeeper Diving Save.fbx` | `56062b57a3a2dc8dba02c643b97ed13132b9ca8fefe0ce1de89e2aab8bed4f54` | UNTOUCHED (PASS) |
| 13 | Goalkeeper Overhand Throw | `goal/Goalkeeper Overhand Throw.fbx` | `659a864774d08dc7ba7a39c07cf167ca54c63004f339f34d2c370d567dfaf54d` | UNTOUCHED (PASS) |
| 14 | Goalkeeper Scoop | `goal/Goalkeeper Scoop.fbx` | `f0e88f910b52a68ee094e502d2f5b5a92d2dea17e5b31f8189a819ba2293b584` | UNTOUCHED (PASS) |
| 15 | Goalkeeper Sidestep | `goal/Goalkeeper Sidestep.fbx` | `8d33ad568e618651d95f244dd2ff643975dc2a22f3c65d3c382c60a51825402f` | UNTOUCHED (PASS) |

---

## 3. Detailed Deliverables & Audit Matrix

All 15 animations have versioned v02 outputs (`*-r15-keyframes-legfix-v02.json`, `RF02_<Name>Mixamo_R15_v02.recipe.json`), verified Motion Tools library registrations, and `KeyframeSequence` instances saved to `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.AnimSaves`:

| Animation Name | Status | Frames / Duration | Max Pivot $\Delta$ (studs) | Max Foot $\Delta$ | Front Dot Before $\to$ After | Motion Tools Asset ID | Studio AnimSaves Saved |
|---|---|---|---|---|---|---|---|
| `RF02_JogForwardMixamo_R15_v02` | `ALREADY_CORRECT` | 26 f / 0.833s | $2.64 \times 10^{-8}$ | $2.17 \times 10^{-8}$ | $-0.89 \to +0.95$ | `69f7c65f-4959-47c5-8e12-7deff157295e` | **SAVED** |
| `RF02_FastRunMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 17 f / 0.533s | $2.17 \times 10^{-8}$ | $1.98 \times 10^{-8}$ | $-0.94 \to +0.93$ | `c63773e9-fb88-4394-8fab-90f97527655c` | **SAVED** |
| `RF02_ScissorKickMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 84 f / 2.767s | $2.65 \times 10^{-8}$ | $2.61 \times 10^{-8}$ | $-0.87 \to +0.94$ | `479f460a-aa01-4aac-aaf2-6c792c8c7648` | **SAVED** |
| `RF02_SoccerPassMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 49 f / 1.600s | $2.56 \times 10^{-8}$ | $2.13 \times 10^{-8}$ | $-0.98 \to +0.99$ | `a35ae5a3-0737-4b19-beaf-9f82c78e26de` | **SAVED** |
| `RF02_SoccerTackleMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 54 f / 1.767s | $2.57 \times 10^{-8}$ | $2.18 \times 10^{-8}$ | $-0.98 \to +0.99$ | `718ad84b-46a1-4bf0-82cb-d4d5a1f4dd11` | **SAVED** |
| `RF02_SoccerTripMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 49 f / 1.600s | $2.46 \times 10^{-8}$ | $2.04 \times 10^{-8}$ | $-0.98 \to +0.99$ | `7e23199f-1839-4846-972a-28c0a22a106e` | **SAVED** |
| `RF02_StandingIdle02Mixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 157 f / 5.200s | $2.56 \times 10^{-8}$ | $2.35 \times 10^{-8}$ | $-0.51 \to +0.61$ | `e62f9111-bc01-455b-ab48-64bf82c8077a` | **SAVED** |
| `RF02_StandingJumpMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 74 f / 2.433s | $2.33 \times 10^{-8}$ | $2.36 \times 10^{-8}$ | $-0.96 \to +0.98$ | `37991901-7bdd-4785-b7d0-b21274bbe1a2` | **SAVED** |
| `RF02_StrikeFowardJogMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 40 f / 1.300s | $2.60 \times 10^{-8}$ | $2.26 \times 10^{-8}$ | $-0.98 \to +0.97$ | `0a38ab54-20b0-4a2e-a540-847aa0a8b6da` | **SAVED** |
| `RF02_TurnBackRunningMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 50 f / 1.633s | $2.32 \times 10^{-8}$ | $2.20 \times 10^{-8}$ | $-0.89 \to +0.97$ | `fcecd793-16d1-47fb-b4e0-8f4d9819640a` | **SAVED** |
| `RF02_GoalkeeperCatchMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 82 f / 2.700s | $2.99 \times 10^{-8}$ | $2.48 \times 10^{-8}$ | $-0.88 \to +0.95$ | `e9f7c61b-4c3a-4ec9-ac8e-92d282300aa1` | **SAVED** |
| `RF02_GoalkeeperDivingSaveMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 98 f / 3.233s | $2.61 \times 10^{-8}$ | $2.28 \times 10^{-8}$ | $-0.88 \to +0.95$ | `12816a89-4fae-4d54-be05-7f95cbf1c008` | **SAVED** |
| `RF02_GoalkeeperOverhandThrowMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 86 f / 2.833s | $2.83 \times 10^{-8}$ | $2.84 \times 10^{-8}$ | $-0.85 \to +0.92$ | `bde069d7-a614-4b37-ad07-1742d9e74fbd` | **SAVED** |
| `RF02_GoalkeeperScoopMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 79 f / 2.600s | $2.37 \times 10^{-8}$ | $2.17 \times 10^{-8}$ | $-0.88 \to +0.95$ | `d1fa4778-e2f2-45a9-bcae-bfd489f8860c` | **SAVED** |
| `RF02_GoalkeeperSidestepMixamo_R15_v02` | `FIXED_READY_FOR_OWNER` | 17 f / 0.533s | $2.53 \times 10^{-8}$ | $1.78 \times 10^{-8}$ | $-0.88 \to +0.93$ | `ce84fc90-df46-4969-938f-26dcbf8007ad` | **SAVED** |

---

## 4. Visual Previews & GIFs

All 15 converted animations have been rendered into normal and slow-motion preview GIFs and placed in the authoritative review destination `C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo\outputagy`:

1. `JogForward_R15_LegFix_v02.gif` (2.21 MB) — *Owner Accepted Reference*
2. `FastRun_R15_LegFix_v02.gif` (1.48 MB)
3. `ScissorKick_R15_LegFix_v02.gif` (7.74 MB)
4. `SoccerPass_R15_LegFix_v02.gif` (4.62 MB)
5. `SoccerTackle_R15_LegFix_v02.gif` (2.42 MB)
6. `SoccerTrip_R15_LegFix_v02.gif` (4.41 MB)
7. `StandingIdle02_R15_LegFix_v02.gif` (14.82 MB)
8. `StandingJump_R15_LegFix_v02.gif` (6.93 MB)
9. `StrikeFowardJog_R15_LegFix_v02.gif` (3.67 MB)
10. `TurnBackRunning_R15_LegFix_v02.gif` (4.57 MB)
11. `GoalkeeperCatch_R15_LegFix_v02.gif` (4.47 MB)
12. `GoalkeeperDivingSave_R15_LegFix_v02.gif` (5.26 MB)
13. `GoalkeeperOverhandThrow_R15_LegFix_v02.gif` (5.08 MB)
14. `GoalkeeperScoop_R15_LegFix_v02.gif` (6.32 MB)
15. `GoalkeeperSidestep_R15_LegFix_v02.gif` (1.50 MB)

Each clip directory also contains isolated `Before` and `After` still renders (`*_LegFix_Before.png`, `*_LegFix_After.png`) and dedicated v02 scenes (`*_LegBasisFix_v02.blend`), preserving prior v01 assets without overwriting.

---

## 5. Scope & Preservation Boundary Verification

- **Dirty files in `src/`:** Confirmed Owner-authorized work by Codex (`JogForwardClipData.luau`, `FastRunClipData.luau`, `R15LocomotionHelper.luau`, `R15LocomotionConfigs.luau`, etc.). No file in `src/` was reverted, reset, or cleaned.
- **Git State:** Zero git commits, zero git pushes, zero publishes to Roblox live servers.
- **Gameplay Integration:** Zero gameplay runtime scripts altered; animations remain strictly isolated preview assets inside `PreviewRig_R15_Boy_Height30.AnimSaves`.
- **Mixamo Sources:** 100% SHA-256 hash match against initial baseline.

---

## 6. Recommendation & Next Steps

All 14 clips are submitted as **`FIXED_READY_FOR_OWNER`** for inspection and visual review. As per project guidelines, visual acceptance of the remaining clips is reserved exclusively for the Project Owner (Stang).
