import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const ARTIFACTS = 'C:/Users/Stang/cage-zero/cage-zero-animation-work/artifacts';
const OUT_FILE = 'C:/Users/Stang/cage-zero/src/client/character/DribbleClipData.luau';

const CLIPS = [
  'RF02_WalkDribble_R15_v01',
  'RF02_RunDribble_R15_v01',
  'RF02_CutDiagFrontLeft_AW_R15_v01',
  'RF02_CutDiagFrontRight_WD_R15_v01',
  'RF02_CutDiagBackLeft_AS_R15_v01',
  'RF02_CutDiagBackRight_SD_R15_v01',
  'RF02_CutReverse_WS_R15_v01',
  'RF02_GMode_SlowControlLoop_R15_v01',
  'RF02_GMode_SoleDragBack_WS_R15_v01',
];

const nTime = (v) => {
  const r = Math.round(Number(v) * 10000) / 10000;
  return Object.is(r, -0) ? 0 : r;
};

const nRot = (v) => {
  const r = Math.round(Number(v) * 100) / 100;
  return Object.is(r, -0) ? 0 : r;
};

const nPos = (v) => {
  const r = Math.round(Number(v) * 1000) / 1000;
  return Object.is(r, -0) ? 0 : r;
};

let out = `--!strict
-- src/client/character/DribbleClipData.luau
-- Immutable Authored R15 Dribble, Directional Cut, and G-Mode Close-Control Animation Data
-- Governed by RF02-DRIBBLE-ANIMATION-INTEGRATION Contract (2026-10-27).
-- Provides deterministic KeyframeSequence construction with 15 R15 joints and KeyframeMarkers.

export type MarkerEntry = {
\tt: number,
\tname: string,
\tvalue: string,
}

export type ClipRecipe = {
\tname: string,
\tduration: number,
\tloop: boolean,
\tpriority: Enum.AnimationPriority,
\ttimes: { number },
\tmarkers: { MarkerEntry },
\tlowerTorsoPos: { number },
\trotations: { [string]: { number } },
}

local R15_TREE = {
\tname = "HumanoidRootPart",
\tchildren = {
\t\t{
\t\t\tname = "LowerTorso",
\t\t\tchildren = {
\t\t\t\t{
\t\t\t\t\tname = "UpperTorso",
\t\t\t\t\tchildren = {
\t\t\t\t\t\t{ name = "Head", children = {} },
\t\t\t\t\t\t{ name = "LeftUpperArm", children = { { name = "LeftLowerArm", children = { { name = "LeftHand", children = {} } } } } },
\t\t\t\t\t\t{ name = "RightUpperArm", children = { { name = "RightLowerArm", children = { { name = "RightHand", children = {} } } } } },
\t\t\t\t\t},
\t\t\t\t},
\t\t\t\t{ name = "LeftUpperLeg", children = { { name = "LeftLowerLeg", children = { { name = "LeftFoot", children = {} } } } } },
\t\t\t\t{ name = "RightUpperLeg", children = { { name = "RightLowerLeg", children = { { name = "RightFoot", children = {} } } } } },
\t\t\t},
\t\t},
\t},
}

local Recipes: { [string]: ClipRecipe } = {
`;

for (const clipName of CLIPS) {
  const recipe = JSON.parse(await readFile(join(ARTIFACTS, `${clipName}.recipe.json`), 'utf8'));
  const prio = recipe.priority === 'Movement' ? 'Enum.AnimationPriority.Movement' : 'Enum.AnimationPriority.Action';
  const times = recipe.tracks[0].keys.map((k) => nTime(k.time));
  const ltTrack = recipe.tracks.find((t) => t.joint === 'LowerTorso');
  const ltPos = [];
  for (const k of ltTrack.keys) {
    ltPos.push(nPos(k.position[0]), nPos(k.position[1]), nPos(k.position[2]));
  }

  out += `\t["${clipName}"] = {\n`;
  out += `\t\tname = "${clipName}",\n`;
  out += `\t\tduration = ${nTime(recipe.duration)},\n`;
  out += `\t\tloop = ${recipe.loop ? 'true' : 'false'},\n`;
  out += `\t\tpriority = ${prio},\n`;
  out += `\t\ttimes = {${times.join(',')}},\n`;
  out += `\t\tmarkers = {\n`;
  for (const m of recipe.markers) {
    out += `\t\t\t{ t = ${nTime(m.time)}, name = "${m.name}", value = "${m.value ?? ''}" },\n`;
  }
  out += `\t\t},\n`;
  out += `\t\tlowerTorsoPos = {${ltPos.join(',')}},\n`;
  out += `\t\trotations = {\n`;
  for (const tr of recipe.tracks) {
    const flatRot = [];
    for (const k of tr.keys) {
      flatRot.push(nRot(k.rotation[0]), nRot(k.rotation[1]), nRot(k.rotation[2]));
    }
    out += `\t\t\t["${tr.joint}"] = {${flatRot.join(',')}},\n`;
  }
  out += `\t\t},\n`;
  out += `\t},\n`;
}

out += `}

local function poseCFrameAt(recipe: ClipRecipe, jointName: string, frameIndex: number): CFrame
\tlocal rot = recipe.rotations[jointName]
\tif not rot then
\t\treturn CFrame.identity
\tend
\tlocal base = (frameIndex - 1) * 3
\tlocal rx = rot[base + 1] or 0
\tlocal ry = rot[base + 2] or 0
\tlocal rz = rot[base + 3] or 0
\tif jointName == "LowerTorso" then
\t\tlocal pos = recipe.lowerTorsoPos
\t\tlocal px = pos[base + 1] or 0
\t\tlocal py = pos[base + 2] or 0
\t\tlocal pz = pos[base + 3] or 0
\t\treturn CFrame.new(px, py, pz) * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
\tend
\treturn CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
end

local DribbleClipData = {
\tRecipes = Recipes,
}

function DribbleClipData.BuildKeyframeSequence(clipName: string): KeyframeSequence?
\tlocal recipe = Recipes[clipName]
\tif not recipe then
\t\treturn nil
\tend

\tlocal sequence = Instance.new("KeyframeSequence")
\tsequence.Name = recipe.name
\tsequence.Loop = recipe.loop
\tsequence.Priority = recipe.priority

\tlocal function buildPose(node: any, frameIndex: number): Pose
\t\tlocal pose = Instance.new("Pose")
\t\tpose.Name = node.name
\t\tlocal hasTrack = recipe.rotations[node.name] ~= nil
\t\tpose.Weight = if hasTrack then 1 else 0
\t\tpose.EasingStyle = Enum.PoseEasingStyle.CubicV2
\t\tpose.EasingDirection = Enum.PoseEasingDirection.InOut
\t\tpose.CFrame = poseCFrameAt(recipe, node.name, frameIndex)
\t\tfor _, child in ipairs(node.children) do
\t\t\tpose:AddSubPose(buildPose(child, frameIndex))
\t\tend
\t\treturn pose
\tend

\tfor frameIndex, timeSec in ipairs(recipe.times) do
\t\tlocal frame = Instance.new("Keyframe")
\t\tframe.Time = timeSec
\t\tframe:AddPose(buildPose(R15_TREE, frameIndex))
\t\tfor _, m in ipairs(recipe.markers) do
\t\t\tif math.abs(m.t - timeSec) <= 0.015 then
\t\t\t\tlocal marker = Instance.new("KeyframeMarker")
\t\t\t\tmarker.Name = m.name
\t\t\t\tmarker.Value = m.value
\t\t\t\tframe:AddMarker(marker)
\t\t\tend
\t\tend
\t\tsequence:AddKeyframe(frame)
\tend

\treturn sequence
end

return table.freeze(DribbleClipData)
`;

await writeFile(OUT_FILE, out, 'utf8');
console.log('Generated DribbleClipData.luau:', out.split('\n').length, 'lines,', Buffer.byteLength(out, 'utf8'), 'bytes');
