# RF02-CAMERA-OFF — temporary normal camera

2026-10-25 · Owner explicitly chose ปิดของเดิม ใช้กล้องปกติชั่วคราว. Controller Codex; implementer Flashw2:p49. Normal prompt,small bounded follow-up. Reviewed pre-Idle foundation committed locally as `5ccb53d69568144c4b43458e84d06029d7937557`,no push. Idle draft deliberately excluded.

## Authority / scope

Disable only automatic initialization and input wiring of existing custom CameraShiftLockController so fresh play uses normal Roblox camera. Advanced center-reticle/free-look/body/shot direction behavior is queued AFTER Idle under advanced-camera-owner-draft.md,not authorized for implementation now.

Allowed source edits ONLY src/client/init.client.luau and src/client/controllers/InputController.luau: remove/skip the two existing CameraShiftLockController require/Init paths. Keep the controller file as inert reference; do not delete or rewrite it. No new camera controller,keybind,RenderStepped loop,reticle,cursor-hiding,root rotation,game settings,rig/height/ball change or R15/Idle authoring.

## Execution and checks

- Verify HEAD5ccb53d and exact working diff; preserve untracked Argon Idle recipe and root camera docs. Before edits capture source/Studio backups and hashes; target actual Cage-Zero137721422246269/Edit,one writer. No full sync or default.project.json/game setting edits.
- Narrow sync only changed2 source instances. Native PlayerModule/camera stays default; no forced center-lock from old controller. Fresh bounded Play checks current R15/height/ball remain,CameraSubject/current camera valid,mouse normal when not actively using native right-mouse camera/menu input;old LeftAlt custom toggle not registered. Distinguish native Roblox camera behaviors from old custom lock; don't fake user input/feel acceptance.
- Restore Edit,source readback parity,protected/source unchanged outside2files,source-only whitespace/reference checks. No full old test suite or new feature tests. Actual Player input capture behavior requiring user check may remain explicitly NOT VERIFIED,not claimed passed from properties only.
- If any additional source seam/game setting appears necessary,report exact blocker rather than expanding scope. No Git stage/commit/push/publish by Flash.

## Ownership / delivery

Flash owns Studio until this small check finishes. Argon remains off Studio; send STUDIO_RELEASED(actualrigpath,height,ref) only after Edit restored and callback sent. Do not integrate Idle source.

One assets/camera-normal-temporary-report-001.md with before/after hashes,exact changed paths,actual observations/limits andSOURCE_FROZEN. UpdateRF02tasks/notes only. Push READY_FOR_REVIEW/BLOCKED withEnter toCodexw2:p43,no monitoring. Codex independently reviews and may make separate local commit under Owner standing authorization after pass. Then releases Argon's existing bounded Idle draft preview. Stop after this task.
