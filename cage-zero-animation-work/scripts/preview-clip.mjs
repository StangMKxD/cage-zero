import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

const WORKSPACE = 'C:/Users/Stang/cage-zero/cage-zero-animation-work';
const ARTIFACTS_DIR = join(WORKSPACE, 'artifacts');
const AI_TOOLS = 'C:/Users/Stang/AI-Tools';

const CLIP_ALIASES = {
  walk: 'RF02_WalkDribble_R15_v01',
  run: 'RF02_RunDribble_R15_v01',
  aw: 'RF02_CutDiagFrontLeft_AW_R15_v01',
  wd: 'RF02_CutDiagFrontRight_WD_R15_v01',
  as: 'RF02_CutDiagBackLeft_AS_R15_v01',
  sd: 'RF02_CutDiagBackRight_SD_R15_v01',
  ws: 'RF02_CutReverse_WS_R15_v01',
  gloop: 'RF02_GMode_SlowControlLoop_R15_v01',
  gdrag: 'RF02_GMode_SoleDragBack_WS_R15_v01',
};

const arg = (process.argv[2] ?? 'walk').toLowerCase();
const seconds = Math.min(30, Math.max(1, Number(process.argv[3] ?? 30)));
const clipName = CLIP_ALIASES[arg] ?? process.argv[2];

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
  if (!r.ok || data.isError) throw new Error(`${name} failed: ${JSON.stringify(data)}`);
  const text = data.content?.find((x) => x.type === 'text')?.text;
  return text ? JSON.parse(text) : data;
}

const sessions = await call('motion_studio_sessions');
const session =
  sessions.find(
    (s) =>
      s.online &&
      s.snapshot?.placeId === '137721422246269' &&
      (s.snapshot?.activeRig?.name === 'PreviewRig_R15_Boy_Height30' ||
        s.snapshot?.selection?.some((x) => x.name === 'PreviewRig_R15_Boy_Height30'))
  ) ?? sessions.find((s) => s.online && s.id === '0e7f69a9-ee63-4987-96ee-ca653f2883bd');

if (!session) {
  throw new Error('Target Edit session with PreviewRig_R15_Boy_Height30 not found');
}

const rig =
  session.snapshot?.activeRig?.name === 'PreviewRig_R15_Boy_Height30'
    ? session.snapshot.activeRig
    : session.snapshot?.selection?.find((x) => x.name === 'PreviewRig_R15_Boy_Height30');

if (arg === 'status') {
  console.log(
    JSON.stringify(
      {
        rpcPort: control.port,
        pid: control.pid,
        sessionId: session.id,
        online: session.online,
        placeId: session.snapshot?.placeId,
        rig,
      },
      null,
      2
    )
  );
  process.exit(0);
}

const assetMeta = JSON.parse(await readFile(join(ARTIFACTS_DIR, `${clipName}.asset.json`), 'utf8'));

const queued = await call('motion_studio_preview', {
  sessionId: session.id,
  rigId: rig.id,
  animationId: assetMeta.id,
  seconds,
  effects: [],
});

for (let i = 0; i < 25; i++) {
  const j = await call('motion_studio_job', { jobId: queued.jobId });
  if (j.status === 'succeeded') {
    console.log(JSON.stringify({ clipName, assetId: assetMeta.id, seconds, result: j.result }, null, 2));
    process.exit(0);
  }
  if (!['queued', 'running'].includes(j.status)) throw new Error(JSON.stringify(j));
  await new Promise((r) => setTimeout(r, 500));
}
