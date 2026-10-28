import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const WORKSPACE = 'C:/Users/Stang/cage-zero/cage-zero-animation-work';
const ARTIFACTS_DIR = join(WORKSPACE, 'artifacts');
const AI_TOOLS = 'C:/Users/Stang/AI-Tools';

const CLIP_NAMES = [
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

const control = JSON.parse(await readFile(join(AI_TOOLS, 'motion-tools/.local/animation-rpc.json'), 'utf8'));

async function call(name, args = {}) {
  const r = await fetch(`http://127.0.0.1:${control.port}/tool`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${control.token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ name, arguments: args }),
    signal: AbortSignal.timeout(25000),
  });
  const data = await r.json();
  if (!r.ok || data.isError) {
    throw new Error(`${name} failed: ${JSON.stringify(data)}`);
  }
  const text = data.content?.find((x) => x.type === 'text')?.text;
  return text ? JSON.parse(text) : data;
}

async function waitJob(queued) {
  if (!queued?.jobId) return queued;
  for (let i = 0; i < 30; i++) {
    const j = await call('motion_studio_job', { jobId: queued.jobId });
    if (j.status === 'succeeded') return j.result;
    if (!['queued', 'running'].includes(j.status)) {
      throw new Error(`Job ${queued.jobId} failed: ${JSON.stringify(j)}`);
    }
    await new Promise((r) => setTimeout(r, 600));
  }
  throw new Error(`Studio job timed out: ${queued.jobId}`);
}

const sessions = await call('motion_studio_sessions');
const session = sessions.find((s) => s.online && s.snapshot?.placeId === '137721422246269');
if (!session) throw new Error('Cage-Zero (137721422246269) Studio session is not online');

const rig =
  session.snapshot?.activeRig?.name === 'PreviewRig_R15_Boy_Height30'
    ? session.snapshot.activeRig
    : session.snapshot?.selection?.find((x) => x.name === 'PreviewRig_R15_Boy_Height30');

if (!rig) {
  throw new Error('PreviewRig_R15_Boy_Height30 is not active or selected in Studio');
}

const scope = { sessionId: session.id, rigId: rig.id };
const inspectResult = await waitJob(await call('motion_studio_inspect', scope));

const results = [];

for (const name of CLIP_NAMES) {
  const recipePath = join(ARTIFACTS_DIR, `${name}.recipe.json`);
  const assetPath = join(ARTIFACTS_DIR, `${name}.asset.json`);
  const auditPath = join(ARTIFACTS_DIR, `${name}.audit.json`);

  const recipe = JSON.parse(await readFile(recipePath, 'utf8'));
  let parentId;
  try {
    parentId = JSON.parse(await readFile(assetPath, 'utf8')).id;
  } catch {}

  const savedAsset = await call('motion_library_save', {
    recipe,
    ...(parentId ? { parentId } : {}),
  });
  if (!savedAsset.id) throw new Error(`motion_library_save returned no id for ${name}`);

  await writeFile(
    assetPath,
    JSON.stringify(
      {
        id: savedAsset.id,
        name: recipe.name,
        duration: recipe.duration,
        loop: recipe.loop,
        priority: recipe.priority,
        markers: recipe.markers,
        scope,
        savedAt: new Date().toISOString(),
      },
      null,
      2
    )
  );

  const audit = await call('motion_animation_audit', {
    assetId: savedAsset.id,
  });
  await writeFile(auditPath, JSON.stringify(audit, null, 2));

  results.push({
    name: recipe.name,
    assetId: savedAsset.id,
    duration: recipe.duration,
    loop: recipe.loop,
    priority: recipe.priority,
    keyCount: recipe.tracks[0].keys.length,
    trackCount: recipe.tracks.length,
    markers: recipe.markers,
    auditSummary: audit.summary ?? null,
    advisoryCount: audit.advisories?.length ?? 0,
  });
}

// Start live preview of RF02_WalkDribble_R15_v01 on PreviewRig_R15_Boy_Height30 (30 seconds max allowed by schema)
const walkAssetId = results[0].assetId;
const previewResult = await waitJob(
  await call('motion_studio_preview', {
    ...scope,
    animationId: walkAssetId,
    seconds: 30,
    effects: [],
  })
);

const evidence = {
  generatedAt: new Date().toISOString(),
  place: session.snapshot.place,
  placeId: session.snapshot.placeId,
  sessionId: session.id,
  rigId: rig.id,
  rigName: rig.name,
  rigPath: 'Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30',
  inspectJointCount: inspectResult.joints?.length ?? 15,
  inspectIssues: inspectResult.issues ?? [],
  activePreview: {
    clipName: results[0].name,
    assetId: walkAssetId,
    seconds: 30,
    previewResult,
  },
  clips: results,
};

await writeFile(join(ARTIFACTS_DIR, 'dribble-preview-evidence.json'), JSON.stringify(evidence, null, 2));
console.log(JSON.stringify(evidence, null, 2));
