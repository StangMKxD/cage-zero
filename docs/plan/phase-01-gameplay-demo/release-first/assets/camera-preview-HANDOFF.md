# RF02-CAMERA-PREVIEW — view-only orbit,center reticle and preserved run heading

2026-10-25 · Owner Stang explicitly requests camera preview now after accepting Idle. Controller Codex; implementer Flashw2:p49/3.8 normal prompt. Argon stays stopped; no new agents. Baseline HEAD44c2810580a74727bf8eca7f5578576e14d4a516 + root task docs only; verify current ref/diff.

## Accepted latest intent / prototype interpretation

- Owner says กล้องเปลี่ยนแค่มุมมองพอ and และมีเป้ากลางจอเหมือนshiftlockแต่หันมองทางอื่นได้แต่คงทิศทางวิ่ง.
- Create one Owner-reviewable Studio-local camera prototype: third-person view with centered reticle,hidden pointer while controlling view,free orbit without directly rotating character'shead/chest/root. Native movement may rotate body toward actual movement; camera orbit alone must not.
- Direction-latch interpretation disclosed to Owner: capture world movement heading when the held WASD combination changes. While same combination remains held,camera may orbit while that world direction stays constant. Releasing/changing combination recomputes from current camera yaw; WA/WD -> W follows current view immediately. No forced root look-at-camera. This is a feel prototype for Owner review,not a final broad movement spec.
- Shooting would face aimed view in future; NO shot/ball/action handlers or body snap on clicking in this task. New approved Idle recipe/KeyframeSequence stays unchanged and not integrated by camera work. No head/chest look-at-ball writes.

## Source scope / single-writer contract

Create only:
1. src/client/controllers/CameraPreviewController.luau — camera/reticle/cursor lifecycle
2. src/client/controllers/MovementHeadingPreviewController.luau — only the movement input adapter needed for preserved world heading
3. src/shared/configs/CameraPreviewConfigs.luau — explicit prototype settings/Studio gate
Modify only src/client/init.client.luau for bounded optional prototype startup after base readiness. Do not rewrite InputController,R15AvatarService,R15AnimationController,height/ball configs,Network,otherUI or .project settings. If another seam is truly required,report exact evidence first. Keep old CameraShiftLockController inert; do not resurrect its AutoRotate/root-yaw code.

Keep active prototype Studio-only by default; public/non-Studio keeps existing normal camera until Owner later accepts rollout. No persistent game setting flip,extra desktop app,package installation,published asset or UI dashboard. No gameplay frameworks/ball possession/skills/economy/source animation changes.

## Required technical boundaries

- One camera writer and one movement writer while prototype active. Correctly suspend/replace native movement only for supported desktop test context; do not let PlayerModule and customMove fight each frame or permanently disable native controls. Unsupported devices fall back to normal camera/controls,not broken touch/gamepad.
- Mouse movement alters view only. Use current documented Roblox camera/input API,not OS cursor warping. No HumanoidRootPart.CFrame/Motor6D/AnimationConstraint/Neck/Waist/AutoRotate writes to force facing. Humanoid:Move world direction is the sole movement pathway if needed; engine handles orientation. Normalize diagonal input,zero movement on no keys,menu/focus-loss/death;rebuild safely on respawn.
- Preserve camera FOV/default sensitivity settings globally; own tunable orbit sensitivity/pitch limits/distance/focus-height allowed as preview settings. Start behind/above tallR15 so body,feet and nearby ball readable. Defaults are artistic preview values,not balance acceptance.
- Center reticle uses viewport center (account for GuiInset),small/readable. Pointer hidden/center-captured only when active,focused,not menu/chat/textbox. Release and restore cursor/control when menu opens,window loses focus,character dies/prototype disables;no trapped cursor. No new keyboard toggle or keybinding chosen without Owner direction; Stop Studio exits prototype. No debug technical labels in player HUD.
- Camera should handle walls/roof with bounded local occlusion queries excluding own character/preview fixtures,not cut through arena. No camera/physics solver/geometry changes. Report limits honestly; no unbounded casts/loops.
- Lifecycle: current character+generation guards around yields,clear stale references/connections,ownGui cleanup,idempotentInit andexplicitCleanup restoring previous camera/mouse/control state. Handle CurrentCamera replacement and new character without restoring a destroyed subject. No WaitForChild/yield inside render callback,no duplicate loops after respawn.

## Preflight / synchronization / evidence

Read agent.md,READ,advanced-camera-owner-draft,review023 and currentbootstrap. Use project skills first,then Comet/Darkmatter and Roblox input/UI/character skills. Official references verified2026-10-25: https://create.roblox.com/docs/reference/engine/classes/Camera ; https://create.roblox.com/docs/reference/engine/classes/UserInputService . Prove actual API use rather than assuming a legacy pattern.

Backup exact source/Studio before-state under unique C:/Users/Stang/cage-zero-cleanup-backups/. Verify Cage-Zero137721422246269,current safeEdit and ownership. If Owner is inPlay do not interrupt;prepare source/read-only first and report need for safe release. Flash owns bounded Studio camera test; no Argon concurrent edits.

Sync only new3modules and modifiedclientbootstrap using default mapping; no whole-project import. Readback parity;protectedR15/height/ball/approvedIdle source/data hashes unchanged. Basic static syntax/whitespace/reference check with accurate tool limitations. No old full test suite.

Bounded local Play check: centered reticle/hidden pointer,view rotates without stationary character yaw,holdWASD+view changes preserve world direction,changing chord (including WA->W)uses newcamera direction,no diagonal speed boost,no stuck motion onrelease/focus/menu/death. Test respawn/prototypeCleanup returns native controls/camera/pointer. Measure actual input observations; do not mock success from internal properties if input tooling unavailable. Screenshot/how-to-preview helpful;no mandatory video. No custom Idle authoring or gameplay integration. ReturnEdit after own smoke;don'tstop Owner's later independent Play.

## Delivery / stop

One assets/camera-preview-report-001.md with currentref/ownfiles/hashes,backup,sourceStudio parity,actualinput/scene observations,limits,visualhowto and SOURCE_FROZEN. RF02tasks/notes pointers only;preserve historicalreports/contracts/newIdle. Push READY_FOR_OWNER_CAMERA_PREVIEW or BLOCKED withEntertoverifiedCodexw2:p43,one milestone report,no monitoring. No Gitstage/commit/push byFlash;Codexreviewsbeforeanylocalcommit. STOP for Owner camera feel feedback;no follow-on pose,shooting,look-at-ball automation or production rollout.
