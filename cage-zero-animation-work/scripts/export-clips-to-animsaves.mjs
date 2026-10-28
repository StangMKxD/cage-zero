import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const WORKSPACE = 'C:/Users/Stang/cage-zero/cage-zero-animation-work';
const ARTIFACTS_DIR = join(WORKSPACE, 'artifacts');
const AI_TOOLS = 'C:/Users/Stang/AI-Tools';

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

async function call(name, args = {}) {
  const control = JSON.parse(await readFile(join(AI_TOOLS, 'motion-tools/.local/animation-rpc.json'), 'utf8'));
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
  if (!r.ok || data.isError) throw new Error(`${name} failed: ${JSON.stringify(data)}`);
  const text = data.content?.find((x) => x.type === 'text')?.text;
  return text ? JSON.parse(text) : data;
}

async function waitJob(jobId) {
  for (let i = 0; i < 40; i++) {
    const j = await call('motion_studio_job', { jobId });
    if (j.status === 'succeeded') return j;
    if (!['queued', 'running'].includes(j.status)) throw new Error(`Job ${jobId} failed: ${JSON.stringify(j)}`);
    await new Promise((r) => setTimeout(r, 400));
  }
  throw new Error(`Job ${jobId} timed out`);
}

const sessions = await call('motion_studio_sessions');
const session = sessions.find(
  (s) =>
    s.online &&
    s.snapshot?.placeId === '137721422246269' &&
    s.snapshot?.activeRig?.name === 'PreviewRig_R15_Boy_Height30'
);
if (!session) throw new Error('Active Edit session with PreviewRig_R15_Boy_Height30 not found');

const rigId = session.snapshot.activeRig.id;
const results = [];

for (const clipName of CLIPS) {
  const assetMeta = JSON.parse(await readFile(join(ARTIFACTS_DIR, `${clipName}.asset.json`), 'utf8'));
  const preflightQueued = await call('motion_studio_validate_animation_export', {
    sessionId: session.id,
    rigId,
    assetId: assetMeta.id,
    jointMap: {},
  });
  const preflightJob = await waitJob(preflightQueued.jobId);
  const preflight = preflightJob.result;

  const saveQueued = await call('motion_studio_save_animation', {
    sessionId: session.id,
    rigId,
    assetId: assetMeta.id,
    jointMap: {},
    expectedFingerprint: preflight.assetFingerprint,
    userApprovedFingerprint: preflight.assetFingerprint,
    expectedPreflightFingerprint: preflight.preflightFingerprint,
  });
  const saveJob = await waitJob(saveQueued.jobId);

  results.push({
    clipName,
    assetId: assetMeta.id,
    assetFingerprint: preflight.assetFingerprint,
    preflightFingerprint: preflight.preflightFingerprint,
    frameCount: preflight.frameCount,
    poseCount: preflight.poseCount,
    markerCount: preflight.markerCount,
    animatedTrackCount: preflight.animatedTrackCount,
    saveResult: saveJob.result,
  });
}

await writeFile(join(ARTIFACTS_DIR, 'dribble-export-evidence.json'), JSON.stringify({ sessionId: session.id, rigId, results }, null, 2));
console.log(JSON.stringify({ ok: true, exportedCount: results.length, clips: results.map((r) => ({ clipName: r.clipName, frameCount: r.frameCount, markerCount: r.markerCount, saved: r.saveResult?.saved })) }, null, 2));
