# RF02-R15-BASE — ROBLOX Boy +30% Height Steering Report 001

**Date:** 2026-10-25 · **Author:** `agyanimation` (3.8 Flash, pane `w2:p49`) · **Controller/Reviewer:** Codex (`w2:p43`) · **Owner:** Stang  
**Status:** **READY_FOR_OWNER_VISUAL_REVIEW / STUDIO_RELEASED_FOR_ARGON_IDLE_PREVIEW**  
**Baseline HEAD:** `25a67d5575e31034a5a08290873b9c401357d33a` (Source working tree: 22 files total)  
**Contract Reference:** [`r15-player-and-ball-HANDOFF.md`](r15-player-and-ball-HANDOFF.md) (Latest Owner size adjustment: ~30% taller) & [`idle-motion-HANDOFF.md`](idle-motion-HANDOFF.md)  
**Studio Target:** `Cage-Zero` (PlaceId: `137721422246269`, Studio Instance ID: `ab5aa575-5e53-41b6-b1ab-e2c8bc7c29c0`, DataModel: `Edit`)  
**Pre-Mutation Backup Directory:** `C:/Users/Stang/cage-zero-cleanup-backups/roblox-boy-height-backup-20261025-2005/`

---

## 1. Executive Summary & Verification Verdict

Per the Owner's directive (*"OWNER NEW SIZE STEERING: currentBoytooShort, increase STANDARD HEIGHT ~30% for EVERYONE. Keep width/depth, face/clothes/hair/hats, ball radius 1.125 diameter 2.25 and physics unchanged"*), implementer `agyanimation` implemented the ~30% standard height increase for all players, calibrated the physical body geometry to hit the target `~6.71 studs`, adjusted derived `HipHeight` and spawn clearance for turf grounding, verified readback parity, performed live Play smoke tests, constructed a dedicated Preview Rig for Argon's Motion Tools, and returned Studio cleanly to `Edit` mode.

### Key Milestones Achieved:
1. **Measured ~30% Height Steering Proven (RB-07):**
   - Baseline Height (`HeightScale = 1.0`): `5.1583 studs` (neutral standing body height excluding accessories).
   - Target Height (+30.0% physical growth): `5.1583 * 1.30 = 6.7058 studs` (~`6.71 studs`).
   - Calibrated `HeightScale`: Set to `1.391` in canonical configuration.
     - *Technical rationale:* Setting `HeightScale = 1.30` alone with `HeadScale = 1.0` only achieves `6.350 studs` (+23.10%) because the head remains unscaled. Setting `HeightScale = 1.391` delivers **`6.7083 studs`** (+30.05% physical growth), hitting the Owner's target `~6.71 studs` while keeping natural head proportions.
   - Body Width (`3.459 studs`) and Body Depth (`1.366 studs`): **0.00% difference / exactly preserved**.
   - HeadScale (`1.0`): Head size `(1.198, 1.202, 1.211)` preserved; personal `Traditional Chinese Hat` fits cleanly.
2. **Derived Turf Grounding & Spawn Clearance (RB-07):**
   - In R15, leg length scales proportionally with `HeightScale` (`2.008 * 1.391 = 2.793 studs`).
   - `CANONICAL_HIP_HEIGHT` updated from hardcoded `2.0` to derived **`2.792 studs`**.
   - `SPAWN_HEIGHT_OFFSET` updated from `3.2` to derived **`4.45 studs`** (clears floor by ~0.27 studs on drop).
   - Measured live turf contact (`gapToFloor`): **`-0.017 studs`** (< 1.8 mm into turf surface) in Play mode, and **`-0.00047 studs`** (< 0.05 mm) on the Edit preview rig. **Zero floating and zero turf clipping!**
3. **Ball Invariants Preserved:**
   - Ball radius: `1.125 studs` (diameter `2.25 studs`).
   - Resting position: `(0, 1.125, 0)` on `CageFloor` top (`Y = 0`).
   - Velocity, turf friction (`1.6`), restitution (`0.88`), and gravity (`-65.0`) completely unchanged.
4. **Respawn & Identity Lifecycle Verified:**
   - Player `StangMKxD` spawns with `BodyPackage = "ROBLOX Boy"`, `Traditional Chinese Hat`, Shirt ID `6169665524`, Pants ID `6457926684`, and 1 `Animator`.
   - Respawn test: Killed character, waited 2.0s delay, respawned cleanly with identical +30% height, Boy package, hat, and single Animator. Stale R6 spawner remained completely inert.
   - Console: **0 Lua runtime errors** (only 1 historical asset warning `rbxassetid://203785492`).
5. **Argon Preview Rig Ready & Studio Released:**
   - Constructed anchored preview rig at **`Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30`** at sideline position `(0, 4.183, 45)`.
   - Studio restored to **`Edit` mode**. Studio release notification sent to Argon (`w2:p48`).

**Verdict:** **`READY_FOR_OWNER_VISUAL_REVIEW / STUDIO_RELEASED_FOR_ARGON_IDLE_PREVIEW`**.

---

## 2. Pre-Mutation Backup & Source Parity (RB-07)

### Pre-Mutation Backup:
- Directory: `C:/Users/Stang/cage-zero-cleanup-backups/roblox-boy-height-backup-20261025-2005/`
- `R15AvatarConfigs.luau`: SHA256 `1345cb7d8ea4311f2cce3cc684d99d54d6bc88a63f0009b90c9d2b0411a0683b`
- `R15AvatarService.luau`: SHA256 `3aa44881b1de07ca1bb082cc9e863e24ab761a569aea648c9b7b5c1c3dd4b1eb`

### Synchronized Files & Readback Parity in Studio Edit Mode:
| File Relative Path | Disk Bytes | Studio Bytes | Disk / Studio SHA256 | Parity Status |
| :--- | :---: | :---: | :---: | :---: |
| `src/shared/configs/R15AvatarConfigs.luau` | 3,683 | 3,683 | `6b773271d3e91287509165e98a029a90ae4c9d91a4e3d68bf0fe731626c37dda` | **EXACT MATCH (100%)** |
| `src/server/services/R15AvatarService.luau` | 6,633 | 6,633 | `7491847869063ad2de7b51f549f9fb089efccd0a0424f7bec7f31abdb43a8640` | **EXACT MATCH (100%)** |

---

## 3. Measured Physical Dimensions & Ratio Comparison

Measured in Roblox Studio using the exact neutral bounding box algorithm excluding accessories:

| Metric / Dimension | Baseline (`HeightScale = 1.0`) | New Height (`HeightScale = 1.391`) | Measured Ratio | Percentage Delta |
| :--- | :---: | :---: | :---: | :---: |
| **Neutral Body Height** | `5.1583 studs` | **`6.7083 studs`** (~`6.71 studs`) | **1.3005x** | **+30.05% taller** |
| **Neutral Body Width** | `3.4592 studs` | `3.4592 studs` | 1.0000x | **0.00% (Preserved)** |
| **Neutral Body Depth** | `1.3659 studs` | `1.3659 studs` | 1.0000x | **0.00% (Preserved)** |
| **HumanoidRootPart Size** | `2.0, 2.0, 1.0` | `2.0, 2.782, 1.0` | 1.391x (Y) | +39.1% (Y only) |
| **Humanoid.HipHeight** | `2.000 studs` | **`2.792 studs`** | 1.396x | Derived for grounding |
| **Spawn Height Offset** | `3.200 studs` | **`4.450 studs`** | 1.391x | Derived floor clearance |
| **Turf Gap (`footBottomY - floorTopY`)** | `-0.0088 studs` | **`-0.0175 studs`** | — | Clean turf contact (<1.8 mm) |

### Part-by-Part Comparison Across Body Limbs:
| Part Name | Baseline Size (studs) | New Size (+30% Height) | Ratio Y | Width / Depth Status |
| :--- | :---: | :---: | :---: | :---: |
| **UpperTorso** | `1.8154, 1.7732, 1.1102` | `1.8154, 2.4665, 1.1102` | 1.391x | Width & Depth identical |
| **LowerTorso** | `1.6962, 0.5661, 0.9525` | `1.6962, 0.7875, 0.9525` | 1.391x | Width & Depth identical |
| **RightUpperArm / LeftUpperArm** | `0.5699, 1.0948, 0.7828` | `0.5699, 1.5229, 0.7828` | 1.391x | Width & Depth identical |
| **RightLowerArm / LeftLowerArm** | `0.6271, 0.9477, 0.6166` | `0.6271, 1.3182, 0.6166` | 1.391x | Width & Depth identical |
| **RightHand / LeftHand** | `0.6933, 1.1018, 0.7443` | `0.6933, 1.5326, 0.7443` | 1.391x | Width & Depth identical |
| **RightUpperLeg / LeftUpperLeg** | `0.7597, 1.3789, 0.7694` | `0.7597, 1.9180, 0.7694` | 1.391x | Width & Depth identical |
| **RightLowerLeg / LeftLowerLeg** | `0.7420, 1.0774, 0.8213` | `0.7420, 1.4987, 0.8213` | 1.391x | Width & Depth identical |
| **RightFoot / LeftFoot** | `0.8362, 0.6279, 1.2425` | `0.8362, 0.8735, 1.2425` | 1.391x | Width & Depth identical |
| **Head** | `1.1978, 1.2024, 1.2109` | `1.1978, 1.2024, 1.2109` | 1.000x | **Natural Head Proportion Preserved** |

### Stang vs User 1 Dimensions Check (+30% Height):
Comparing Stang (`UserId = 2772253354`) vs User 1 (`Roblox`):
- All 15 limb, torso, and root parts: **0.000000 stud difference** across both players.
- Head variance: Sub-millimeter `0.011 stud` (1.1 mm) due to Stang's custom head mesh vs default User 1 head mesh.
- Preserved accessories: Stang retains `Traditional Chinese Hat`; User 1 retains `ROBLOXCap`.

---

## 4. Live Runtime & Respawn Verification (RB-07)

- **Player:** `StangMKxD`
- **RigType:** `Enum.HumanoidRigType.R15`
- **BodyPackage Attribute:** `"ROBLOX Boy"`
- **Humanoid.HipHeight:** `2.792 studs`
- **HumanoidRootPart.Position.Y:** `4.1835 studs`
- **Foot Bottom Position:** `-0.0177 studs` relative to `floorTopY = 0` (clean turf ground contact).
- **Accessories Preserved:** `Traditional Chinese Hat` (`AccessoryType.Hat`).
- **Clothing Preserved:** Shirt (`6169665524`), Pants (`6457926684`).
- **Single Animator:** `Workspace.StangMKxD.Humanoid.Animator` (Count: 1).
- **Respawn Lifecycle:** Character killed -> 2.0s delay -> respawned cleanly with `Health = 100`, `BodyPackage = "ROBLOX Boy"`, `Traditional Chinese Hat`, 1 `Animator`, and `HipHeight = 2.792`. Stale R6 spawner remained inert.
- **Ball Invariants:** `CageMatchBall` radius `1.125 studs` (diameter `2.25 studs`), resting at `Y = 1.125` on `CageFloor`, physics forces unchanged.
- **Console Log Output:** **0 Lua runtime errors** (only 1 historical asset warning `rbxassetid://203785492`).

---

## 5. Preview Rig for Argon Motion Tools (Stage A Release)

In accordance with [`idle-motion-HANDOFF.md`](idle-motion-HANDOFF.md), a dedicated preview rig matching the finalized +30% height baseline was constructed in Edit mode:
- **Full Path:** `game.Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30`
- **World Position:** `(0, 4.183, 45)` (field sideline, feet grounded cleanly at `Y = -0.00047` on turf).
- **Root Part:** `HumanoidRootPart` is **Anchored** (`true`).
- **Humanoid:** `RigType = R15`, `HipHeight = 2.792`, `DisplayName = "Preview Rig (+30% Boy)"`.
- **Animator:** Exactly 1 Animator present at `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.Humanoid.Animator`.
- **Attributes:**
  - `IsPreviewRig = true`
  - `BodyPackage = "ROBLOX Boy"`
  - `HeightScale = 1.391`
  - `TargetBodyHeight = 6.708`
  - `HipHeight = 2.792`
- **Appearance:** Stang's personal skin colors, `Traditional Chinese Hat`, and outfit applied over canonical ROBLOX Boy limbs.

---

## 6. Scope Boundaries & Technical Limitations

1. **No Custom Idle Authored:** Flash did NOT author custom poses, sports stances, or idle clips. Native R15 baseline animations remain active. Custom Idle authoring is delegated to Argon (`w2:p48`) under `idle-motion-HANDOFF.md`.
2. **No Ball Gameplay Introduced:** No ball possession, carry, tackle, shoot, or pass mechanics. The ball remains in a pure Free physics state.
3. **Studio Released:** Studio mode is restored to `Edit`. Flash has relinquished Studio write locks, allowing Argon to inspect and preview animations.
4. **Git Policy Strictly Followed:** Zero Git stage, commit, push, or branch operations performed.
