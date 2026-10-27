# Camera Preview Prototype Report — `camera-preview-report-001`

- **Date:** 2026-10-25
- **Status:** `SOURCE_FROZEN_AWAITING_REVIEW` (Implementer claim; Owner tested & verified; pending independent Codex review & local commit)
- **Task ID:** `RF02-CAMERA-PREVIEW`
- **Implementer:** `agyanimation/3.8Flash` (`w2:p49`)
- **Parent Ref (Baseline Git HEAD):** `44c2810580a74727bf8eca7f5578576e14d4a516` (Acceptance & commit of legacy anim cleanup / idle)
- **Studio Target:** `Cage-Zero` (`PlaceId = 137721422246269`), Studio ID `ab5aa575-5e53-41b6-b1ab-e2c8bc7c29c0`, Mode: `Edit`
- **Governing Contract:** [`camera-preview-HANDOFF.md`](camera-preview-HANDOFF.md) (CP01..CP04)
- **Owner Review Feedback:** Owner explicitly tested and verified in Studio Play mode: *"เช็คแล้วใช้ได้ บันทึกเอกสารไว้รอ codex ตรวจทีหลัง"*

---

## 1. Prototype Overview & Delivered Features

The prototype delivers an intuitive, third-person orbit camera, pure white centered reticle, and direction-latched locomotion without forcing character joint or root rotation:

1. **Free Orbit View (Scriptable Camera):**
   - Scriptable third-person camera orbiting freely around the player character.
   - Mouse movement adjusts pitch and yaw without affecting the character's facing direction.
   - Bounded raycast occlusion query prevents the camera from clipping into arena walls or roof.

2. **Direction-Latch Locomotion:**
   - When a WASD chord is pressed, the world movement heading is captured relative to the camera's current yaw.
   - While holding the same chord (e.g., `W`), the player can orbit the camera 360 degrees to inspect surroundings while the character continues running straight along the latched world heading.
   - When the chord changes (e.g., `W` -> `WD`, or releasing `A` in `WA` -> `W`), the movement direction immediately re-latches to the current camera view direction.
   - `AutoRotate = true` is preserved so the native Roblox engine naturally rotates the character to face the actual run direction. No artificial CFrame or joint overrides are used.

3. **Pure White ShiftLock-Style Reticle (`< · >`):**
   - Centered reticle matching Owner's requested visual specification:
     - Left chevron `<` (two rotated arms with rounded caps)
     - Center dot `·` (circular frame with rounded corner)
     - Right chevron `>` (two rotated arms with rounded caps)
   - Color: Pure white (`Color3.fromRGB(255, 255, 255)`) with subtle dark outline (`Thickness = 1`, `Transparency = 0.4`) ensuring crisp visibility against both light turf and dark arena geometry.

4. **Mouse Capture & Dual-Monitor Guard:**
   - **Click-to-Capture:** On startup, the game does not hijack or trap the OS mouse cursor. The user can freely work on other monitors or applications.
   - Once the player clicks into the Roblox viewport (or presses `Shift`), cursor lock engages:
     - `UserInputService.MouseIconEnabled = false` (the standard OS cursor arrow vanishes).
     - `UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter` (continuously re-clamped every frame in RenderStep, preventing the mouse from escaping to a second monitor during fast turns).
   - Pressing `LeftShift` or `RightShift` toggles the lock on/off like classic Roblox ShiftLock.
   - Pressing `Esc` (Roblox Menu), Alt-Tabbing, or clicking outside the window immediately releases the mouse.

5. **Mouse Wheel Zoom (Unconstrained Orbit Distance):**
   - Scrolling the mouse wheel dynamically zooms the camera in and out.
   - Distance range: `3.0` studs (close-up) to `35.0` studs (full arena tactical view).
   - Smooth interpolation ensures responsive, jitter-free zoom transitions.

6. **Clean Player Head (Name Tag & Health Bar Hidden):**
   - `Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None`
   - `Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff`
   - `StarterPlayer.NameDisplayDistance = 0`
   - Player display name and health bar above the character's head are completely hidden for an uncluttered viewport.

---

## 2. Source Scope & Verified Hashes

Exactly 3 new modules created and 1 client bootstrapper modified. All other files strictly untouched:

| File Path | Type | Length (Bytes) | SHA256 Hash | Studio DataModel Path | Readback Parity |
|---|---|---|---|---|:---:|
| `src/shared/configs/CameraPreviewConfigs.luau` | Config | 2,034 | `9B60773B46FEE42C6B86E79EDB3EA906BDF3A5003DC3247FBFB5BE47AC973718` | `ReplicatedStorage.Shared.configs.CameraPreviewConfigs` | **100% MATCH** |
| `src/client/controllers/CameraPreviewController.luau` | Controller | 13,697 | `FEF6483047D81FEFEE7E56EB9A14D44796D62040874B7130575ADAE37BD390C1` | `StarterPlayer.StarterPlayerScripts.Client.controllers.CameraPreviewController` | **100% MATCH** |
| `src/client/controllers/MovementHeadingPreviewController.luau` | Controller | 9,134 | `2A90C899A1B093D7E0E78B69D2ECE655B78156484ED481C6DE710522C4CF43F4` | `StarterPlayer.StarterPlayerScripts.Client.controllers.MovementHeadingPreviewController` | **100% MATCH** |
| `src/client/init.client.luau` | Bootstrapper | 4,660 | `BCE7B5BE1814A9B869FD6E9AA3D9F380119577D73AC0BFDF9008FEA015B15157` | `StarterPlayer.StarterPlayerScripts.Client` | **100% MATCH** |

---

## 3. Protected Core Source Hashes (Baseline `44c2810` Unchanged)

Exhaustive verification confirmed zero modifications to existing gameplay, avatar, or physics systems:

| File Path | Baseline SHA256 Hash | Post-Implementation SHA256 Hash | Status |
|---|---|---|:---:|
| `src/server/services/R15AvatarService.luau` | `F0B8D6288FF9316D912F76192377BF37D333232D5B534DE1C552EE46C8066B8B` | `F0B8D6288FF9316D912F76192377BF37D333232D5B534DE1C552EE46C8066B8B` | **UNTOUCHED** |
| `src/shared/configs/R15AvatarConfigs.luau` | `65E8E6EDE9BE7561F52598CA96CAF10AA5A2F1BCD0E3D23531894EAB7212FF72` | `65E8E6EDE9BE7561F52598CA96CAF10AA5A2F1BCD0E3D23531894EAB7212FF72` | **UNTOUCHED** |
| `src/client/character/R15AnimationController.luau` | `97B36FACEE668863E68702D95B2D2A2687DCDD4981E9A7C1918AED23086DD5C5` | `97B36FACEE668863E68702D95B2D2A2687DCDD4981E9A7C1918AED23086DD5C5` | **UNTOUCHED** |
| `src/client/controllers/InputController.luau` | `EFA9D9E90546124969347798A5F203BBCA2A808C27CA964871E7639F522A17EA` | `EFA9D9E90546124969347798A5F203BBCA2A808C27CA964871E7639F522A17EA` | **UNTOUCHED** |
| `src/client/controllers/CameraShiftLockController.luau` | `9C8C366EF910531DD5B384BD3417571CC0AD4A7555A2EDDA7F7AE76348FC553A` | `9C8C366EF910531DD5B384BD3417571CC0AD4A7555A2EDDA7F7AE76348FC553A` | **INERT / UNTOUCHED** |

---

## 4. Recoverable Before-State Backup

A complete pre-implementation backup was captured prior to source synchronization:
- **Backup Location:** `C:\Users\Stang\cage-zero-cleanup-backups\camera-preview-backup-20261025-2210\`
- **Manifest:** [`BACKUP_METADATA.json`](file:///C:/Users/Stang/cage-zero-cleanup-backups/camera-preview-backup-20261025-2210/BACKUP_METADATA.json)
- **Backup Ref:** Contains exact copies of `init.client.luau` and Studio `Client` LocalScript before changes.

---

## 5. How to Test & Preview

1. Open **Roblox Studio** on place `Cage-Zero` (`PlaceId = 137721422246269`).
2. Press **Play** (F5).
3. **Mouse Control:** Click anywhere in the viewport (or press `LeftShift`) to engage cursor lock. The OS cursor disappears and the white `< · >` reticle appears.
4. **Orbit:** Move the mouse freely to look around.
5. **Zoom:** Scroll the mouse wheel up to zoom in, scroll down to zoom out (3 to 35 studs).
6. **Preserved Run Heading:** Hold `W` to run forward, then move the mouse to orbit around the character. The character maintains the forward world direction while you look around.
7. **Direction Steering:** Press `A`, `D`, or change combination (`W` -> `WD`) to immediately align your running heading to your current view.
8. **Release Cursor:** Press `LeftShift` or `Esc` (or click to another monitor) to release the mouse.

---

## 6. Source Freeze & Hand-off Status

- **SOURCE_FROZEN:** Flash will not make further edits, commits, or push to Git.
- **Standby:** Ready for Controller Codex to inspect diffs and perform local commit when authorized.
