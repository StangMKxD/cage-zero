# RF02-R15-BASE — R15 Lifecycle & Edge Cases Fix Report 001

**Date:** 2026-10-25 · **Author:** `agyanimation` (3.8 Flash, pane `w2:p49`) · **Controller/Reviewer:** Codex (`w2:p43`) · **Owner:** Stang  
**Status:** **SOURCE_FROZEN / READY_FOR_CODEX_REVIEW_AND_LOCAL_COMMIT**  
**Baseline HEAD:** `25a67d5575e31034a5a08290873b9c401357d33a` (Source working tree: 22 files total)  
**Contract Reference:** [`r15-player-and-ball-HANDOFF.md`](r15-player-and-ball-HANDOFF.md) & [`review-018.md`](review-018.md)  
**Studio Target:** `Cage-Zero` (PlaceId: `137721422246269`, Studio Instance ID: `ab5aa575-5e53-41b6-b1ab-e2c8bc7c29c0`, DataModel: `Edit`)  

---

## 1. Executive Summary & Review 018 Resolutions

In response to Review 018 (`CHANGES_REQUESTED`) and the Owner's directive locking the visual height baseline (*"ความสูงผ่านแล้ว ประมาณนี้แหละ. Lock current Boy height ~6.708 studs / HeightScale 1.391 / HeadScale 1"*), implementer `agyanimation` resolved all three review findings (`RF-F21`, `RF-F22`, `RF-F23`) and addressed all three mid-fix lifecycle edge cases without altering the approved height and ball dimensions.

### Summary of Completed Fixes:
1. **RF-F21 Server Lifecycle & Replacement Integrity:**
   - Prior character connections are **never** disconnected at spawn entry. They remain fully active until the new replacement candidate model is 100% validated and ready to commit.
   - Generation token checks (`activeRequestGeneration[userId] == thisRequest` and `player:IsDescendantOf(Players)`) are enforced **after every yielding API call** (`GetHumanoidDescriptionFromUserIdAsync` and `CreateHumanoidModelFromDescriptionAsync`).
   - Stale or superseded candidate models are immediately destroyed if the generation check fails.
   - Avatar description caching (`lastValidatedDescription[userId]`) is committed **only** on the validated path, never prematurely upon raw fetch.
2. **RF-F22 Client Readiness & Character Tracking:**
   - `R15AnimationController` tracks exact `currentCharacter` and `characterGeneration`.
   - `existingChar` is captured in a local variable before `task.spawn` in `Init()`.
   - Structural readiness gate: `IsR15Ready()` strictly verifies that `currentCharacter == localPlayer.Character`, `Humanoid` is alive (`Health > 0`) and descendant of Character, and `Animator` is a valid descendant of `Humanoid`.
   - Immediate invalidation on `CharacterRemoving` and `Humanoid.Died`.
3. **RF-F23 Bounded & Lifecycle-Aware Acquisition Retry:**
   - Defined authoritative retry policy in `R15AvatarConfigs`: `MAX_ACQUISITION_RETRIES = 3`, `RETRY_BASE_DELAY_SEC = 2.0`.
   - Bounded backoff retry applies consistently across both initial description fetch failures and candidate model creation failures.
   - Explicit non-gameplay failure state entered if retries are exhausted without ever spawning a blank gameplay avatar.
4. **Mid-Fix Edge Case 1 (Committed Character Generation Token):**
   - Separated in-flight `activeRequestGeneration[userId]` from committed `committedCharacterGeneration[userId]`.
   - The `Humanoid.Died` listener captures `committedCharacterGeneration[userId]`. A failed replacement attempt increments request generation without touching committed generation, guaranteeing that the existing alive character's respawn listener **never becomes inert**.
5. **Mid-Fix Edge Case 2 (Dead Character Respawn Check):**
   - Candidate model creation failure checks `isExistingAlive` (`existingHum.Health > 0 and in Workspace`). Dead characters during respawn do **not** shortcircuit the bounded retry loop.
6. **Mid-Fix Edge Case 3 (Client Character Match Pre-Check):**
   - `onCharacterAdded` checks `localPlayer.Character == character` **before** incrementing `characterGeneration` or calling `invalidateCharacterState()`, preventing delayed background tasks from invalidating a newer active character.

---

## 2. Source Files & Studio Edit Readback Parity

All three modified files were synchronized to `Cage-Zero` Edit DataModel and verified for 100% byte-for-byte and SHA256 equality:

| File Relative Path | Disk Bytes | Studio Bytes | Disk / Studio SHA256 Hash | Parity Status |
| :--- | :---: | :---: | :---: | :---: |
| `src/shared/configs/R15AvatarConfigs.luau` | 3,835 | 3,835 | `65e8e6ede9be7561f52598ca96caf10aa5a2f1bcd0e3d23531894eab7212ff72` | **EXACT MATCH (100%)** |
| `src/server/services/R15AvatarService.luau` | 10,104 | 10,104 | `f0b8d6288ff9316d912f76192377bf37d333232d5b534de1c552ee46c8066b8b` | **EXACT MATCH (100%)** |
| `src/client/character/R15AnimationController.luau` | 5,293 | 5,293 | `97b36facee668863e68702d95b2d2a2687dcdd4981e9a7c1918aed23086dd5c5` | **EXACT MATCH (100%)** |

---

## 3. Live Play Smoke & Lifecycle Verification

Performed in local Play mode (`Cage-Zero`, PlaceId `137721422246269`):
1. **Initial Authoritative Spawn:**
   - Player: `StangMKxD` (UserId `2772253354`).
   - RigType: `Enum.HumanoidRigType.R15`.
   - BodyPackage: `"ROBLOX Boy"` with personal `Traditional Chinese Hat` preserved.
   - Body Height: `6.708 studs` (HeightScale `1.391`, HeadScale `1.0`, Width `3.459`, Depth `1.366`).
   - `HipHeight`: `2.792 studs`, `gapToFloor`: `-0.017 studs` (grounded cleanly on turf).
   - Single Animator: `Workspace.StangMKxD.Humanoid.Animator`.
2. **Client Readiness Gate:**
   - `R15AnimationController.IsR15Ready()` returns `true`.
   - `GetHumanoid()` returns `Workspace.StangMKxD.Humanoid`.
   - `GetAnimator()` returns `Workspace.StangMKxD.Humanoid.Animator`.
   - `GetCharacter()` matches `localPlayer.Character`.
3. **Death & Invalidation Gate:**
   - When `Humanoid.Health = 0`, client `humanoid.Died` fires and clears `currentAnimator` and `currentHumanoid`.
   - `IsR15Ready()` immediately returns `false` during the death window.
4. **Respawn & Generation Token Integrity:**
   - After `2.0s` delay, server validates new candidate model and commits replacement.
   - `committedCharacterGeneration` increments to `2`.
   - Character respawns with `Health = 100`, `BodyPackage = "ROBLOX Boy"`, and single Animator.
   - Client detects new character, validates hierarchy post-yield, and `IsR15Ready()` transitions back to `true` pointing to the new Humanoid and Animator.
   - Stale R6 spawner remained completely inert.
5. **Ball Invariants:**
   - `Workspace.CageMatchBall` radius `1.125 studs` (diameter `2.25 studs`), resting at `(0, 1.125, 0)`.
   - Physics coefficients (turf friction `1.6`, restitution `0.88`, gravity `-65.0`) preserved.
6. **Console Output:**
   - **0 Lua runtime errors**.
   - Only 1 pre-existing asset warning: `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type`.

---

## 4. Studio Edit Mode & Preview Rig Verification

- Studio mode restored to **`Edit`**.
- Anchored Preview Rig verified at **`Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30`**:
  - Position: `(0, 4.183, 45)` at field sideline.
  - `HumanoidRootPart.Anchored = true`.
  - `Humanoid.HipHeight = 2.792 studs`.
  - Dimensions: Height `6.708 studs`, Width `3.459 studs`, Depth `1.366 studs`.
  - Single Animator: `Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30.Humanoid.Animator`.
  - Appearance: Stang outfit + `Traditional Chinese Hat` over ROBLOX Boy limbs.

---

## 5. Source Freeze & Commit Gate

- **SOURCE_FROZEN:** Implementer `agyanimation` has frozen all source edits across the working tree.
- **Git Actions:** Flash has **not** performed any Git stage, commit, or push operations per policy.
- **Argon Idle Hold:** Argon (`w2:p48`) Idle authoring is explicitly on hold until Codex issues `COMMIT_DONE`.
- **Standing by:** Awaiting Codex independent review of the frozen foundation and local commit.
