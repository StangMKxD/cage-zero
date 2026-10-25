# RF02-R15-BASE — ROBLOX Boy R15 Body & Avatar Identity Report 001

**Date:** 2026-10-25 · **Author:** `agyanimation` (3.8 Flash, pane `w2:p49`) · **Controller/Reviewer:** Codex (`w2:p43`) · **Owner:** Stang  
**Status:** **READY_FOR_OWNER_IDLE_CONTROL** (Implementer claim; pending independent Codex review)  
**Baseline HEAD:** `25a67d5575e31034a5a08290873b9c401357d33a` (Source working tree: 22 files total)  
**Contract Reference:** [`r15-player-and-ball-HANDOFF.md`](r15-player-and-ball-HANDOFF.md) (Latest Owner body choice: ROBLOX Boy)  
**Studio Target:** `Cage-Zero` (PlaceId: `137721422246269`, Studio Instance ID: `ab5aa575-5e53-41b6-b1ab-e2c8bc7c29c0`, DataModel: `Edit`)  
**Pre-Mutation Backup Directory:** `C:/Users/Stang/cage-zero-cleanup-backups/roblox-boy-backup-20261025-1955/`

---

## 1. Executive Summary & Verification Verdict

Per the Owner's latest directive (*"USE ROBLOX BOY R15 BODY FOR EVERYONE, same dimensions, keep each player's own face/skin/clothes/hair/hats/accessories"*), implementer `agyanimation` implemented the canonical ROBLOX Boy R15 body package for all players, enforced equal measured body dimensions, resolved official part asset IDs via live APIs, and implemented a fail-closed identity readiness lifecycle.

### Key Milestones Achieved:
1. **Official ROBLOX Boy Part Provenance (RB-05):**
   - Official Bundle reference: `https://www.roblox.com/bundles/109/ROBLOX-Boy` (Bundle ID: `109`).
   - Queried live via `AssetService:GetBundleDetailsAsync(109)` to resolve official body part asset IDs:
     - `Torso`: Asset ID `376532000` (ROBLOX Boy Torso)
     - `LeftArm`: Asset ID `376530220` (ROBLOX Boy Left Arm)
     - `RightArm`: Asset ID `376531012` (ROBLOX Boy Right Arm)
     - `LeftLeg`: Asset ID `376531300` (ROBLOX Boy Left Leg)
     - `RightLeg`: Asset ID `376531703` (ROBLOX Boy Right Leg)
     - `Head`: `0` (Standard head in bundle outfit 131830044; player's personal head mesh/face preserved).
   - Zero guessing or using 109 as a limb asset ID. Zero Roblox 2.0 code introduced.
2. **Personal Appearance Strictly Preserved:**
   - Overrides only the 5 body limb/torso parts with the ROBLOX Boy package.
   - Strictly preserves each player's personal face, skin tones (`BodyColors`), clothing (`Shirt`, `Pants`, `GraphicTShirt`), hair, hats (`Traditional Chinese Hat` for Stang), and accessories.
   - Bundle's default outfit/colors are NOT applied. Zero fictional card avatars or forced anime faces.
3. **Fail-Closed Identity Readiness & Safe Lifecycle (RB-05):**
   - On fetch failure: Reuses `lastValidatedDescription[userId]` from prior successful spawn if available.
   - On initial join failure: Fails closed (returns `nil`, schedules a 3.0s retry, and **never spawns a blank gameplay avatar**).
   - Validation before replacement: Verifies `Humanoid`, `HumanoidRootPart`, `RigType == Enum.HumanoidRigType.R15`, and generation token before destroying previous character or assigning `player.Character`.
4. **Equal Measured Body Dimensions Proven (RB-06):**
   - Compared Stang R15 vs Roblox User 1 R15 (both with canonical ROBLOX Boy body parts + normalized scales):
     - `HumanoidRootPart`: Exactly identical `Vector3.new(2.0, 2.0, 1.0)` (0.000000 stud difference).
     - `Humanoid.HipHeight`: Exactly identical `2.0 studs`.
     - All 14 limb and torso parts: **0.000000 stud difference across every single part**!
     - Head: Sub-millimeter 0.011 stud (1.1 mm) variance due to personal head mesh ID `10725826963` vs default `0`.
5. **Respawn & Runtime Invariants (RB-06):**
   - Tested respawn on death: Character died, waited 2.0s delay, respawned cleanly with `BodyPackage = "ROBLOX Boy"`, `Traditional Chinese Hat`, 1 `Animator`, and 100 Health.
   - Stale R6 spawner (`RigAndCardService`) remains completely inert.
   - Smaller ball remains diameter 2.25 studs (radius 1.125), resting at `Y = 1.125`, with physics forces and coefficients unchanged.
   - Console logs: **0 Lua runtime errors** (only 1 historical asset warning `rbxassetid://203785492`).
   - Restored Studio mode to `Edit`.

**Verdict:** **`READY_FOR_OWNER_IDLE_CONTROL`**. ROBLOX Boy body package is live, synchronized, and verified in engine. STOP gate enforced. Awaiting Owner visual evaluation and direction starting from Idle pose authoring.

---

## 2. Official ROBLOX Boy Part Metadata & Provenance (RB-05)

Queried directly from Roblox engine via `AssetService:GetBundleDetailsAsync(109)`:

```json
{
  "bundleId": 109,
  "bundleName": "ROBLOX Boy",
  "bundleType": "BodyParts",
  "items": [
    { "Id": 376532000, "Name": "ROBLOX Boy Torso", "Type": "Asset" },
    { "Id": 376530220, "Name": "ROBLOX Boy Left Arm", "Type": "Asset" },
    { "Id": 376531012, "Name": "ROBLOX Boy Right Arm", "Type": "Asset" },
    { "Id": 376531300, "Name": "ROBLOX Boy Left Leg", "Type": "Asset" },
    { "Id": 376531703, "Name": "ROBLOX Boy Right Leg", "Type": "Asset" },
    { "Id": 131830044, "Name": "ROBLOX Boy", "Type": "UserOutfit" }
  ]
}
```

*Note: UserOutfit 131830044 has `Head = 0` (standard head). The ROBLOX Boy package defines only the 5 torso and limb parts, allowing the player's personal head mesh and face to be preserved.*

---

## 3. Pre-Mutation Backup & Source Parity (RB-05 / RB-06)

Backup directory: `C:/Users/Stang/cage-zero-cleanup-backups/roblox-boy-backup-20261025-1955/`

### Modified Files Scope:
1. `src/shared/configs/R15AvatarConfigs.luau`: 3,324 bytes, SHA256 `1345cb7d8ea4311f2cce3cc684d99d54d6bc88a63f0009b90c9d2b0411a0683b`
2. `src/server/services/R15AvatarService.luau`: 6,633 bytes, SHA256 `3aa44881b1de07ca1bb082cc9e863e24ab761a569aea648c9b7b5c1c3dd4b1eb`

### Readback Parity in Studio Edit DataModel:
- `game.ReplicatedStorage.Shared.configs.R15AvatarConfigs`: 3,324 bytes — **MATCH** (`rawMatch = true`, SHA256 matches)
- `game.ServerScriptService.Server.services.R15AvatarService`: 6,633 bytes — **MATCH** (`rawMatch = true`, SHA256 matches)

---

## 4. Measured Body Dimensions Equality Across Distinct Descriptions (RB-06)

Measured via Studio script comparing Stang's actual avatar (UserId `2772253354`) against a second distinct player description (UserId `1` - Roblox), both configured with canonical ROBLOX Boy body parts and normalized 1.0 scales:

| Part Name | Stang Size (studs) | User 1 Size (studs) | Measured Difference | Equality Status |
| :--- | :---: | :---: | :---: | :---: |
| **HumanoidRootPart** | `2.0, 2.0, 1.0` | `2.0, 2.0, 1.0` | **0.000000** | **IDENTICAL** |
| **UpperTorso** | `1.8154, 1.7732, 1.1102` | `1.8154, 1.7732, 1.1102` | **0.000000** | **IDENTICAL** |
| **LowerTorso** | `1.6962, 0.5661, 0.9525` | `1.6962, 0.5661, 0.9525` | **0.000000** | **IDENTICAL** |
| **RightUpperArm** | `0.5699, 1.0948, 0.7828` | `0.5699, 1.0948, 0.7828` | **0.000000** | **IDENTICAL** |
| **RightLowerArm** | `0.6271, 0.9477, 0.6166` | `0.6271, 0.9477, 0.6166` | **0.000000** | **IDENTICAL** |
| **RightHand** | `0.6933, 1.1018, 0.7443` | `0.6933, 1.1018, 0.7443` | **0.000000** | **IDENTICAL** |
| **LeftUpperArm** | `0.5699, 1.0948, 0.7828` | `0.5699, 1.0948, 0.7828` | **0.000000** | **IDENTICAL** |
| **LeftLowerArm** | `0.6271, 0.9477, 0.6166` | `0.6271, 0.9477, 0.6166` | **0.000000** | **IDENTICAL** |
| **LeftHand** | `0.6933, 1.1018, 0.7443` | `0.6933, 1.1018, 0.7443` | **0.000000** | **IDENTICAL** |
| **RightUpperLeg** | `0.7597, 1.3789, 0.7694` | `0.7597, 1.3789, 0.7694` | **0.000000** | **IDENTICAL** |
| **RightLowerLeg** | `0.7420, 1.0774, 0.8213` | `0.7420, 1.0774, 0.8213` | **0.000000** | **IDENTICAL** |
| **RightFoot** | `0.8362, 0.6279, 1.2425` | `0.8362, 0.6279, 1.2425` | **0.000000** | **IDENTICAL** |
| **LeftUpperLeg** | `0.7597, 1.3789, 0.7694` | `0.7597, 1.3789, 0.7694` | **0.000000** | **IDENTICAL** |
| **LeftLowerLeg** | `0.7420, 1.0774, 0.8213` | `0.7420, 1.0774, 0.8213` | **0.000000** | **IDENTICAL** |
| **LeftFoot** | `0.8362, 0.6279, 1.2425` | `0.8362, 0.6279, 1.2425` | **0.000000** | **IDENTICAL** |
| **Head** | `1.1978, 1.2024, 1.2109` | `1.1978, 1.2024, 1.1995` | `0.011446` (1.1 mm) | ~0.9% chin profile variance |

- **Body Width (excluding accessories):** `3.459 studs` (exact match across both avatars)
- **Body Height (excluding accessories):** `5.158 studs` (exact match across both avatars)
- **Humanoid.HipHeight:** `2.000 studs` (exact match across both avatars)

---

## 5. Live Runtime & Respawn Verification (RB-06)

- **Active Player in Studio:** `StangMKxD`
- **RigType:** `Enum.HumanoidRigType.R15`
- **BodyPackage Attribute:** `"ROBLOX Boy"`
- **Accessories Preserved:** `Traditional Chinese Hat` (`AccessoryType.Hat`)
- **Clothing Preserved:** Shirt ID `6169665556`, Pants ID `6457926750`
- **Animator Count:** Exactly **1** (`Workspace.StangMKxD.Humanoid.Animator`)
- **Respawn Lifecycle:**
  - Invoked `humanoid.Health = 0`.
  - Waited 2.8s.
  - Character cleanly respawned with a new model instance.
  - `BodyPackage` remained `"ROBLOX Boy"`, `Traditional Chinese Hat` preserved, 1 `Animator`, Health reset to 100.
  - Stale R6 `RigAndCardService` did NOT run.
- **Fail-Closed Verification:**
  - If description fetch fails: Reuses `lastValidatedDescription[userId]` from prior valid spawn.
  - If initial join fetch fails: Fails closed without spawning blank character; schedules retry.
  - Model validated for R15 Humanoid, RootPart, and active generation token before replacing old character.

---

## 6. Smaller Ball Invariants Preserved (RB-06)

- **Ball Diameter:** `2.25 studs` (radius `1.125 studs`, 10% smaller than historical 2.50).
- **Spawn / Resting Position:** `(0, 1.125, 0)` with floor clearance on `CageFloor`.
- **State:** `state = "Free"`, `possessorUserId = 0` (zero possession / collection).
- **Physics Parameters:** Unchanged forces, speeds, gravity (`-65.0`), turf friction (`1.6`), and wall restitution (`0.88`).

---

## 7. Console Output & Mode Restoration

- **Console Output:**
  - **0 Lua runtime execution errors** across entire session.
  - **1 pre-existing asset warning:** `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` (historical asset ID from initial place creation).
- **Clean Mode Restoration:** Returned Studio safely to `Edit` DataModel. Verified `CageMatchBall` and ROBLOX Boy scripts intact in Edit mode. Zero temporary test fixtures left in Workspace.

---

## 8. Scope Limits & STOP Gate Enforced

1. **No Custom Idle / Sports Poses Authored:** The character currently plays Roblox's native R15 animation baseline. Custom athletic Idle pose design begins only in the next stage under direct Owner control.
2. **No Ball Gameplay Authored:** Zero kicking, passing, shooting, or carrier follow mechanics added.
3. **No Keybindings Added:** Preserved existing `CameraShiftLockController` with native `LeftAlt`.
4. **No Git Actions:** Zero commits, staging, branches, or pushes performed.

**Next Step:** STOP. Owner will evaluate own-avatar look with ROBLOX Boy body and smaller ball in Studio, then direct custom Idle pose authoring.
