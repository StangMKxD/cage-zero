# RF02-R15-BASE — Player Avatar R15 & Smaller Ball Report 001

**Date:** 2026-10-25 · **Author:** `agyanimation` (3.8 Flash, pane `w2:p49`) · **Controller/Reviewer:** Codex (`w2:p43`) · **Owner:** Stang  
**Status:** **READY_FOR_OWNER_IDLE_CONTROL** (Implementer claim; pending independent Codex review)  
**Baseline HEAD:** `25a67d5575e31034a5a08290873b9c401357d33a` (Source working tree: 22 files total)  
**Contract Reference:** [`r15-player-and-ball-HANDOFF.md`](r15-player-and-ball-HANDOFF.md)  
**Review Reference:** [`review-017.md`](review-017.md) (Cleanup Studio sync verified)  
**Studio Target:** `Cage-Zero` (PlaceId: `137721422246269`, Studio Instance ID: `ab5aa575-5e53-41b6-b1ab-e2c8bc7c29c0`, DataModel: `Edit`)  
**Pre-Mutation Backup Directory:** `C:/Users/Stang/cage-zero-cleanup-backups/r15-ball-backup-20261025-1940/`

---

## 1. Executive Summary & Verification Verdict

Per the Owner's explicit directive (*"เปลี่ยนเป็น R15 ใช้ตัวละครของผมเอง และบอลเล็กลงนิดนึง"*) and the authorized [`r15-player-and-ball-HANDOFF.md`](r15-player-and-ball-HANDOFF.md), implementer `agyanimation` implemented the Player Avatar R15 lifecycle and smaller ball size adjustment.

### Key Milestones Achieved:
1. **Pre-Mutation Recoverable Backup (RB-01):**
   Captured all 5 pre-existing source files and Studio instances into `C:/Users/Stang/cage-zero-cleanup-backups/r15-ball-backup-20261025-1940/` with full SHA256 manifest.
2. **Authoritative R15 Player Avatar Spawner (RB-02):**
   - Implemented `R15AvatarService.luau` using official documented API `Players:CreateHumanoidModelFromDescriptionAsync(desc, Enum.HumanoidRigType.R15)`.
   - Spawns each player using their actual Roblox avatar description (`player.UserId`, e.g., Stang `2772253354`).
   - Preserves player identity, accessories (`Traditional Chinese Hat`), shirt, pants, and body colors. Zero fictional card avatars or forced anime faces.
   - Normalizes description scales to 1.0 (`HeightScale = 1.0`, `WidthScale = 1.0`, `DepthScale = 1.0`, `HeadScale = 1.0`, `BodyTypeScale = 0.0`, `ProportionScale = 0.0`) via `R15AvatarConfigs.luau`.
   - Canonical root geometry: `HumanoidRootPart` is exactly `(2.0, 2.0, 1.0)` and `HipHeight = 2.0` across all avatars.
   - Tested respawn: Character died, waited 2.0s delay, respawned cleanly with exact same R15 avatar and single `Animator`. Stale R6 spawner (`RigAndCardService`) is completely inert and did not compete.
3. **Smaller Ball Preview (10% reduction) (RB-03):**
   - Configured `BALL_RADIUS = 1.125` studs (diameter `2.25` studs, 10% smaller than previous 1.25 radius / 2.5 diameter) and `BALL_SPAWN_POSITION = Vector3.new(0, 1.125, 0)` in `Constants.luau`.
   - Updated `BallService.luau` to size both newly spawned and pre-existing `CageMatchBall` instances to `(2.25, 2.25, 2.25)`.
   - Reversible physics rebound probe: Collision at East Wall (`x = 78.76`), velocity reversed from `+29.20` to `-25.01`, continuous finite coordinates, Part CFrame sync, and reset to baseline `(0, 1.125, 0)`.
   - All physics forces, ball velocity, gravity (`-65.0`), turf friction (`1.6`), and restitution (`0.88`) remain unchanged.
4. **Studio Synchronization & Readback Parity (RB-04):**
   - Synchronized all 7 modified and new runtime scripts to Studio `Edit` DataModel. Readback verification confirms **100% byte-for-byte exact equality** (`rawMatch = true`, identical SHA256).
   - Verified 12 canonical remotes in `ReplicatedStorage.CageZeroRemotes` remain intact.
   - Fresh console check: **0 Lua runtime errors** (only 1 historical asset warning `rbxassetid://203785492`).
   - Restored Studio safely to `Edit` mode; zero temporary fixtures left in Workspace.

**Verdict:** **`READY_FOR_OWNER_IDLE_CONTROL`**. R15 player avatar and smaller ball are live, synchronized, and verified in engine. STOP gate enforced. Awaiting Owner's visual review and direction starting from Idle pose first.

---

## 2. Pre-Mutation Backup & Source Hashes (RB-01)

Backup directory: `C:/Users/Stang/cage-zero-cleanup-backups/r15-ball-backup-20261025-1940/`

| File Path | Status | Pre-Mutation Bytes | Pre-Mutation SHA256 |
| :--- | :---: | :---: | :--- |
| `src/server/init.server.luau` | Modified | 1,418 | `229025e496b38713f63105b346e3aca06cdf46e8d235121d1636dbb2b8ac477e` |
| `src/client/init.client.luau` | Modified | 3,340 | `77f27a522d2f2eddfd94de6d3514daf8c2282bd19a935e4ba1b564218cd3b61c` |
| `src/shared/Constants.luau` | Modified | 7,525 | `da340ae6b09bfc42ce6681b8c1871da5315621b38a17c77162bc25c0471292b6` |
| `src/server/services/BallService.luau` | Modified | 9,271 | `39d85d449f178da95f3e8d014e301d7cb7dc6e568ecaac7b9469cbdf8b234629` |
| `src/client/controllers/InputController.luau` | Verified | 1,539 | `a3c2cadf011dbe8106131511c258ce82b832dad9d0748337b38a301e01cba449` |

---

## 3. Synchronized Source Scope & Readback Parity (RB-04)

Read back directly from Studio `Edit` DataModel and verified against repository source files:

| File Path | Studio Instance | Repo Bytes | Studio Bytes | Raw Match | Normalized Match | Verified SHA256 |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `src/server/init.server.luau` | `game.ServerScriptService.Server` | 1,504 | 1,504 | **TRUE** | **TRUE** | `9234131a7c0d59fc3d929be5af006f1d64fa55e89e6c70543b2fd132fdb8e5d9` |
| `src/client/init.client.luau` | `game.StarterPlayer.StarterPlayerScripts.Client` | 3,465 | 3,465 | **TRUE** | **TRUE** | `db8ce436235f820c8435554883a743c236c7de363b7506ec4eeeeab489cf03dd` |
| `src/shared/Constants.luau` | `game.ReplicatedStorage.Shared.Constants` | 7,565 | 7,565 | **TRUE** | **TRUE** | `9d724d6c833d311f652a97a2d08b2be39e8e60ca852f1c3daab17166554f06a0` |
| `src/server/services/BallService.luau` | `game.ServerScriptService.Server.services.BallService` | 9,869 | 9,869 | **TRUE** | **TRUE** | `6cc90e29d0314b630583ae3488752f75aea95abb049fec2742baded70c62efdd` |
| `src/server/services/R15AvatarService.luau` | `game.ServerScriptService.Server.services.R15AvatarService` | 5,137 | 5,137 | **TRUE** | **TRUE** | `644bc2f08bc94098de03de687639c669e14bee588b4c6cc4953f05abbfac76cc` |
| `src/shared/configs/R15AvatarConfigs.luau` | `game.ReplicatedStorage.Shared.configs.R15AvatarConfigs` | 1,741 | 1,741 | **TRUE** | **TRUE** | `0afb04401e3124260532db1c01f5de1ded556566b9f936b60105a8b9477ebc3a` |
| `src/client/character/R15AnimationController.luau` | `game.StarterPlayer.StarterPlayerScripts.Client.character.R15AnimationController` | 1,659 | 1,659 | **TRUE** | **TRUE** | `0749de448a242da68db8ab43ab64d21fd04c7474a9f9623650c53557da198eaa` |

### Preserved Inert References:
- `src/server/services/RigAndCardService.luau`: Preserved byte-for-byte; not initialized in `init.server.luau`.
- `src/client/character/R6AnimationController.luau`: Preserved byte-for-byte; not initialized in `init.client.luau`.
- `src/shared/configs/RigAnimationConfigs.luau`: Preserved byte-for-byte.

---

## 4. R15 Avatar Lifecycle & Dimensions Evidence (RB-02)

### 4.1 Actual Appearance & Lifecycle Verification
- **Player:** `StangMKxD` (UserId `2772253354`)
- **RigType:** `Enum.HumanoidRigType.R15`
- **Model Name:** `Workspace.StangMKxD`
- **Accessories Preserved:** `Traditional Chinese Hat` (`AccessoryType.Hat`)
- **Clothing Preserved:** Shirt ID `6169665556`, Pants ID `6457926750`
- **Attributes:** `IsR15PlayerAvatar = true`, `AvatarUserId = 2772253354`, `RigType = "R15"`
- **Animator Count:** Exactly **1** (`Workspace.StangMKxD.Humanoid.Animator`)
- **Humanoid Properties:** `WalkSpeed = 16`, `JumpPower = 50`, `Health = 100`, `HipHeight = 2.0`
- **Respawn Test:**
  - Invoked `humanoid.Health = 0`.
  - Waited 2.8s (exceeding 2.0s delay in `R15AvatarConfigs.RESPAWN_DELAY_SEC`).
  - Player cleanly respawned with a new character instance named `StangMKxD`.
  - Rig remained `Enum.HumanoidRigType.R15`, Health reset to 100, exactly 1 `Animator`, accessories intact.
  - Stale R6 `RigAndCardService` did NOT run or interfere.

### 4.2 Measured Body Dimensions Comparison
Measured via Studio script excluding accessories:

| Metric | Stang R15 Avatar | Standard Blocky R15 Baseline | Difference / Ratio |
| :--- | :---: | :---: | :---: |
| **HumanoidRootPart Size** | `Vector3.new(2.0, 2.0, 1.0)` | `Vector3.new(2.0, 2.0, 1.0)` | **0.00% (Identical Contact Geometry)** |
| **Humanoid.HipHeight** | `2.0 studs` | `2.0 studs` | **0.00% (Identical Floor Clearance)** |
| **Body Height** | `5.02 studs` | `5.19 studs` | ~3.3% variance (due to shoe/hair mesh) |
| **Body Width** | `3.79 studs` | `4.00 studs` | ~5.2% variance |
| **Body Depth** | `1.33 studs` | `1.20 studs` | ~10.8% variance |

*Disclosure: To satisfy the Owner's directive to use his own avatar ("เป็นตัวละครของผมเอง"), the avatar's native mesh package is preserved. The contact/root part (`HumanoidRootPart`) and `HipHeight` are 100% identical (`2, 2, 1` and `2.0`). Scale values are normalized to 1.0 across all axes.*

---

## 5. Smaller Ball Physics Evidence (RB-03)

### 5.1 Dimensions & Resting State
- **Ball Part:** `Workspace.CageMatchBall`
- **Rendered Size:** `Vector3.new(2.25, 2.25, 2.25)` (diameter: 2.25 studs, radius: 1.125 studs; exactly 10% smaller than previous 2.50 diameter / 1.25 radius).
- **Spawn / Resting Position:** `(0, 1.125, 0)` with floor clearance.
- **State:** `state = "Free"`, `possessorUserId = 0` (zero possession / collection).

### 5.2 Physics Rebound Probe (East Wall Collision)
Launched ball from `X = 78`, `Y = 1.125` towards East Wall (`Wall_East` at `X = 81`) with `vx = +30.0`:
- Step 1: `x = 78.50`, `vx = +29.20`, `partX = 78.50`, `partY = 1.125`
- Step 2: Wall collision detected at `x = 78.7567` (deeper penetration compared to 78.52 due to smaller 1.125 radius). Rebound velocity `vx = -25.01`, `partX = 78.7567`, `partY = 1.125`.
- Step 3: `x = 78.34`, `vx = -24.34`, `partX = 78.34`
- Step 4: `x = 77.93`, `vx = -23.69`, `partX = 77.93`
- Step 5: `x = 77.54`, `vx = -23.06`, `partX = 77.54`
- Step 6: `x = 77.15`, `vx = -22.45`, `partX = 77.15`
- **Part CFrame Sync:** `ballPart.Position == ballState.position` at every step.
- **Finite Coordinates:** Zero NaN / Inf throughout trajectory.
- **Restoration:** Reversibly reset via `ResetBall(Vector3.new(0, 1.125, 0))` to resting position `(0, 1.125, 0)` with velocity `(0, 0, 0)`.

---

## 6. Console Logs & Clean Restoration

- **Console Log Check:**
  - **0 Lua runtime errors** across entire Play session.
  - **1 pre-existing asset warning:** `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` (historical asset ID from initial place creation).
- **Clean Mode Restoration:** Returned Studio safely to `Edit` DataModel. Verified `CageMatchBall` maintains `Size = (2.25, 2.25, 2.25)` and position `(0, 1.125, 0)`. Zero temporary test fixtures left in Workspace.

---

## 7. Scope Limits & STOP Gate Enforced

1. **No Custom Idle / Sports Poses Authored:** The character currently plays Roblox's native R15 animation baseline. Custom athletic Idle pose design begins only in the next stage under direct Owner control.
2. **No Ball Gameplay Authored:** Zero kicking, passing, shooting, or carrier follow mechanics added.
3. **No Keybindings Added:** Preserved existing `CameraShiftLockController` with native `LeftAlt`.
4. **No Git Actions:** Zero commits, staging, branches, or pushes performed.

**Next Step:** STOP. Owner will evaluate own-avatar look and ball size in Studio, then direct custom Idle pose authoring.
