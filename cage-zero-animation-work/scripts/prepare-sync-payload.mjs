import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';

const ROOT = 'C:/Users/Stang/cage-zero';
const FILES = [
{"disk":"src/client/character/JogForwardClipData.luau","studioPath":["StarterPlayer","StarterPlayerScripts","Client","character","JogForwardClipData"],"className":"ModuleScript"},
{"disk":"src/client/character/FastRunClipData.luau","studioPath":["StarterPlayer","StarterPlayerScripts","Client","character","FastRunClipData"],"className":"ModuleScript"},
{"disk":"src/client/character/ShotChargeClipData.luau","studioPath":["StarterPlayer","StarterPlayerScripts","Client","character","ShotChargeClipData"],"className":"ModuleScript"},
{"disk":"src/shared/SprintSpeedRules.luau","studioPath":["ReplicatedStorage","Shared","SprintSpeedRules"],"className":"ModuleScript"},
{"disk":"src/shared/configs/GroundTurnConfigs.luau","studioPath":["ReplicatedStorage","Shared","configs","GroundTurnConfigs"],"className":"ModuleScript"},
{"disk":"src/shared/configs/SprintConfigs.luau","studioPath":["ReplicatedStorage","Shared","configs","SprintConfigs"],"className":"ModuleScript"},
{"disk":"src/shared/DribbleControlRules.luau","studioPath":["ReplicatedStorage","Shared","DribbleControlRules"],"className":"ModuleScript"},
{"disk":"src/client/controllers/SprintController.luau","studioPath":["StarterPlayer","StarterPlayerScripts","Client","controllers","SprintController"],"className":"ModuleScript"},
{"disk":"src/client/controllers/AirMovementController.luau","studioPath":["StarterPlayer","StarterPlayerScripts","Client","controllers","AirMovementController"],"className":"ModuleScript"},
  {"disk":"src/server/services/SprintService.luau","studioPath":["ServerScriptService","Server","services","SprintService"],"className":"ModuleScript"},
  {"disk":"src/shared/R15PoseSupport.luau","studioPath":["ReplicatedStorage","Shared","R15PoseSupport"],"className":"ModuleScript"},
  {"disk":"src/shared/JumpAnimationTiming.luau","studioPath":["ReplicatedStorage","Shared","JumpAnimationTiming"],"className":"ModuleScript"},
  {"disk":"src/client/character/JumpReferenceData.luau","studioPath":["StarterPlayer","StarterPlayerScripts","Client","character","JumpReferenceData"],"className":"ModuleScript"},
  {"disk":"src/client/character/JumpClipData.luau","studioPath":["StarterPlayer","StarterPlayerScripts","Client","character","JumpClipData"],"className":"ModuleScript"},
  {"disk":"src/client/character/R15LocomotionHelper.luau","studioPath":["StarterPlayer","StarterPlayerScripts","Client","character","R15LocomotionHelper"],"className":"ModuleScript"},
  {"disk":"src/client/character/R15AnimationController.luau","studioPath":["StarterPlayer","StarterPlayerScripts","Client","character","R15AnimationController"],"className":"ModuleScript"},
  {"disk":"src/shared/configs/R15LocomotionConfigs.luau","studioPath":["ReplicatedStorage","Shared","configs","R15LocomotionConfigs"],"className":"ModuleScript"},
  {"disk":"src/shared/ShotReferenceData.luau","studioPath":["ReplicatedStorage","Shared","ShotReferenceData"],"className":"ModuleScript"},
  {"disk":"src/shared/ShotModel.luau","studioPath":["ReplicatedStorage","Shared","ShotModel"],"className":"ModuleScript"},
  {"disk":"src/shared/ShotRules.luau","studioPath":["ReplicatedStorage","Shared","ShotRules"],"className":"ModuleScript"},
  {"disk":"src/shared/configs/ShotConfigs.luau","studioPath":["ReplicatedStorage","Shared","configs","ShotConfigs"],"className":"ModuleScript"},
  {"disk":"src/client/controllers/ShotController.luau","studioPath":["StarterPlayer","StarterPlayerScripts","Client","controllers","ShotController"],"className":"ModuleScript"},
  { disk: 'src/shared/DribbleCutTimeline.luau', studioPath: ['ReplicatedStorage', 'Shared', 'DribbleCutTimeline'], className: 'ModuleScript' },
  { disk: 'src/shared/configs/DribbleActionConfigs.luau', studioPath: ['ReplicatedStorage', 'Shared', 'configs', 'DribbleActionConfigs'], className: 'ModuleScript' },
  { disk: 'src/shared/DribbleGeometryHelper.luau', studioPath: ['ReplicatedStorage', 'Shared', 'DribbleGeometryHelper'], className: 'ModuleScript' },
  { disk: 'src/client/character/DribbleClipData.luau', studioPath: ['StarterPlayer', 'StarterPlayerScripts', 'Client', 'character', 'DribbleClipData'], className: 'ModuleScript' },
  { disk: 'src/client/character/SprintCutReferenceData.luau', studioPath: ['StarterPlayer', 'StarterPlayerScripts', 'Client', 'character', 'SprintCutReferenceData'], className: 'ModuleScript' },
  { disk: 'src/client/character/WalkDribbleReferenceData.luau', studioPath: ['StarterPlayer', 'StarterPlayerScripts', 'Client', 'character', 'WalkDribbleReferenceData'], className: 'ModuleScript' },
  { disk: 'src/client/character/DribbleAnimationHelper.luau', studioPath: ['StarterPlayer', 'StarterPlayerScripts', 'Client', 'character', 'DribbleAnimationHelper'], className: 'ModuleScript' },
  { disk: 'src/client/character/DribbleAnimationController.luau', studioPath: ['StarterPlayer', 'StarterPlayerScripts', 'Client', 'character', 'DribbleAnimationController'], className: 'ModuleScript' },
  { disk: 'src/client/controllers/DribbleCutController.luau', studioPath: ['StarterPlayer', 'StarterPlayerScripts', 'Client', 'controllers', 'DribbleCutController'], className: 'ModuleScript' },
  { disk: 'src/client/controllers/DribblePresentationController.luau', studioPath: ['StarterPlayer', 'StarterPlayerScripts', 'Client', 'controllers', 'DribblePresentationController'], className: 'ModuleScript' },
  { disk: 'src/client/controllers/MovementHeadingPreviewController.luau', studioPath: ['StarterPlayer', 'StarterPlayerScripts', 'Client', 'controllers', 'MovementHeadingPreviewController'], className: 'ModuleScript' },
  { disk: 'src/client/init.client.luau', studioPath: ['StarterPlayer', 'StarterPlayerScripts', 'Client'], className: 'LocalScript' },
  { disk: 'src/server/services/BallService.luau', studioPath: ['ServerScriptService', 'Server', 'services', 'BallService'], className: 'ModuleScript' },
];

const entries = [];
for (const f of FILES) {
  const raw = await readFile(`${ROOT}/${f.disk}`, 'utf8');
  const normalized = raw.replace(/\r\n/g, '\n');
  if (normalized !== raw) {
    await writeFile(`${ROOT}/${f.disk}`, normalized, 'utf8');
  }
  const sha256 = createHash('sha256').update(normalized, 'utf8').digest('hex');
  entries.push({ ...f, content: normalized, sha256, bytes: Buffer.byteLength(normalized, 'utf8') });
}

function buildLuau(subset) {
  return `local HttpService = game:GetService("HttpService")
local entries = HttpService:JSONDecode([========[${JSON.stringify(subset.map((e) => ({ disk: e.disk, studioPath: e.studioPath, className: e.className, content: e.content })))}]========])
local results = {}
for _, item in ipairs(entries) do
	local cur: Instance = game
	for i = 1, #item.studioPath - 1 do
		local seg = item.studioPath[i]
		if i == 1 then
			cur = game:GetService(seg)
		else
			cur = cur:FindFirstChild(seg)
		end
	end
	local leafName = item.studioPath[#item.studioPath]
	local inst = cur:FindFirstChild(leafName)
	if not inst then
		inst = Instance.new(item.className)
		inst.Name = leafName
		inst.Parent = cur
	end
	;(inst :: any).Source = item.content
	local readback = (inst :: any).Source
	table.insert(results, {
		file = item.disk,
		exact = (readback == item.content),
		len = #readback,
	})
end
return HttpService:JSONEncode(results)
`;
}

await writeFile('C:/Users/Stang/cage-zero/cage-zero-animation-work/artifacts/studio-sync-1.luau', buildLuau(entries.filter((e) => !e.disk.endsWith('DribbleClipData.luau'))), 'utf8');
await writeFile('C:/Users/Stang/cage-zero/cage-zero-animation-work/artifacts/studio-sync-2.luau', buildLuau(entries.filter((e) => e.disk.endsWith('DribbleClipData.luau'))), 'utf8');
await writeFile(
  'C:/Users/Stang/cage-zero/cage-zero-animation-work/artifacts/synced-files-hashes.json',
  JSON.stringify(entries.map((e) => ({ disk: e.disk, sha256: e.sha256, bytes: e.bytes })), null, 2),
  'utf8'
);
console.log(JSON.stringify(entries.map((e) => ({ disk: e.disk, sha256: e.sha256, bytes: e.bytes })), null, 2));
