# Legacy animation removal — inventory and bounded cleanup preparation

2026-10-25 · Owner requests removing old animations and rebuilding new ones. Codex controller; Flashw2:p49 owns legacy animation inventory/cleanup; Argonw2:p48 owns ONE new R15 Idle draft/preview. HEAD9fbce58eb90ed6b7e6a39b00a5744455ee639811 + root Idle-handoff change + protected Argon draft assets. No Git actions by AGY.

## Scope meaning

Owner authorizes removal of obsolete Cage-Zero R6/legacyPlan02–03 animation runtime and raw clip/recipe libraries. Preserve new R15 Boy+30% identity/lifecycle,ball/arena,Argon's assets/animations/idle-r15 and current preview rig. No deletion by names Idle/Walk/Animation alone, no touching other places/global Motion libraries or published Roblox assets. Preserve historical review/fix/decision docs,Git history,backups and .sandbox/rollback.

## Phase1 — read-only inventory first

Write one assets/legacy-animation-removal-manifest.md with exact repo path / Studio path,class,hash or before-state,provenance R6 vs R15,actual active consumers and REMOVE/KEEP/UNCERTAIN. Identify candidates including inert R6AnimationController/RigAnimationConfigs,old animation-library JSON,old R6 recipes and exact Animation/KeyframeSequence instances. Inspect all direct/transitive loaders and retained test references; distinguish active runtime from historical/inert references. Do not classify ordinary rig models or every Animator as old animation trash.

No source/asset/Studio deletion yet: Codex must review exact list and lock the implementation allowlist under the already requested removal scope. Do not repeat a full unrelated repository scan or redesign. Source/docs history from current9fbce58 can support recovery; any scene object needs reversible exact before-copy/metadata before execution. If a genuine unknown remains, keep it UNCERTAIN rather than guessing.

Flash may read repo and metadata concurrently but does NOT mutate Studio while Argon previews. Send one coordination notice; no monitoring/polling. Do not read/modify the new R15 draft library. No source fixes or tests/Play runs in inventory phase.

## Report / next gate

Push LEGACY_ANIMATION_MANIFEST_READY or BLOCKED with Enter to verified Codexw2:p43, manifest path and exact candidate counts. Codex reviews and dispatches bounded deletion once file/consumer scope is concrete; no need to re-ask Owner whether they want the old animations removed. Studio mutation must wait explicit Argon release and safe Edit target. No wildcards,whole-folder deletion with mixed R15 content,source framework rewrite,Git commit/push,publish or new animations. Argon budget untouched by this cleanup.
