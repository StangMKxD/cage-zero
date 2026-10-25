# Cleanup Studio Sync — Independent Review016

2026-10-25 · Codex · **CHANGES_REQUESTED — residual retired RemoteEvents**.
Reviewed repo HEAD `25a67d5575e31034a5a08290873b9c401357d33a` + cleanup working tree. Report001 SHA256 `857796cb08359951626838b5b8525b1b118d67d2f97d95b184a0ac208f2e2e83`.

## Independent live read-only checks

- list_roblox_studios confirms Cage-Zero PlaceId137721422246269,Studio instance ab5aa575-5e53-41b6-b1ab-e2c8bc7c29c0. get_studio_state confirms Edit DataModel only.
- Read7 synced Sources from Edit and compared actual strings against repo file contents:7 checked,0 raw or normalized mismatches.
- Exact3 retired ModuleScript paths absent in Edit: R6ActionPoseController,SkillMoveService,PlayerActionPoseConfigs.
- Did not rerun Play or physics probes. Implementer report describes spawn/rebound/console results; those observations are not independent Controller runtime reruns. Protected-neighbor byte/hash equality is not re-proved merely by the report's list of byte lengths.

## Findings

### RF-F19 / MEDIUM — Retired network instances still exist in target Edit scene
Direct inspection of ReplicatedStorage.CageZeroRemotes returns15 children, including SkillMoveRequest,SkillMoveReplicate,TackleActionRequest. Current Network Source removes those3 keys/Definitions; sync alone does not remove previously created instances. Therefore report's zero legacy skill/action remotes assertion is inaccurate. Within the Owner-approved retirement of these skill/tackle remotes, back up exact3 instances'path/class/attributes then remove only these3 RemoteEvents on verified Cage-Zero in Edit. Reject class/path drift and preserve all unrelated remotes. This is not an instruction to remove other historical Parry/Duel remotes.

Re-read Edit network folder; current canonical Network has12 Definitions, not15 active canonical remotes. A bounded fresh local Play check should confirm the retired3 are not recreated; stop back to Edit. No new code/gameplay/Idle or broad resync needed:7 source files already match.

### RF-F20 / MEDIUM — Readiness claims require precise evidence limits
Correct report in a new fix report:15 instantiated names are not15 valid current canonical definitions; one retained asset warning means avoid zero-warnings blanket wording. Separate engine observations actually captured from inferred client input/visual behavior: seeing native properties is not proof of every key/animation feel working. Current check suffices for Owner Idle planning only after residual cleanup; never imply R15 or visual acceptance.

## Corrective assignment

Same cleanup-studio-sync contract; exact retired3 remote-instance cleanup is a clarification of previously approved skill-remote retirement. Capture reversible metadata backup first, verify target/mode, no other scene mutation. One cleanup-studio-sync-fix-001.md with exact removed paths,Edit/Play absence checks,canonical12 names,source parity/protected evidence and mode restoration. Preserve old report, no source edits unless an evidenced in-scope bug arises. No Argon,Git,publish,R15/Idle/new gameplay. Auto push report, no monitoring.
