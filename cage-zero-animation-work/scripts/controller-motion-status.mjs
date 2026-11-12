import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

/**
 * controller-motion-status.mjs
 *
 * Status probe for animation toolchains:
 * - Checks Motion Tools RPC bridge status (C:/Users/Stang/AI-Tools/motion-tools/.local/animation-rpc.json).
 * - Checks OpenRig evaluation directory and local web server status (http://localhost:4330).
 * Reports verified real-time facts without fabricated pipeline readiness.
 */

const MOTION_RPC_FILE = 'C:/Users/Stang/AI-Tools/motion-tools/.local/animation-rpc.json';
const OPENRIG_DIR = 'C:/Users/Stang/AI-Tools/openrig-evaluation';

async function checkMotionTools() {
  if (!existsSync(MOTION_RPC_FILE)) {
    return {
      connected: false,
      status: 'CONFIG_NOT_FOUND',
      detail: `animation-rpc.json not found at ${MOTION_RPC_FILE}`,
    };
  }

  let cfg;
  try {
    cfg = JSON.parse(readFileSync(MOTION_RPC_FILE, 'utf8'));
  } catch (err) {
    return {
      connected: false,
      status: 'CONFIG_INVALID',
      detail: `Failed to parse ${MOTION_RPC_FILE}: ${err.message}`,
    };
  }

  try {
    const r = await fetch(`http://127.0.0.1:${cfg.port}/tool`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${cfg.token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ name: 'motion_studio_sessions', arguments: {} }),
      signal: AbortSignal.timeout(2000),
    });
    if (!r.ok) {
      return {
        connected: false,
        status: 'HTTP_ERROR',
        rpcPort: cfg.port,
        pid: cfg.pid,
        detail: `HTTP ${r.status}`,
      };
    }
    const data = await r.json();
    if (data.isError) {
      return {
        connected: false,
        status: 'TOOL_ERROR',
        rpcPort: cfg.port,
        pid: cfg.pid,
        detail: JSON.stringify(data),
      };
    }
    const block = data.content?.find((x) => x.type === 'text');
    const sessions = block ? JSON.parse(block.text) : [];
    return {
      connected: true,
      status: 'ONLINE',
      rpcPort: cfg.port,
      pid: cfg.pid,
      sessionCount: sessions.length,
      sessions: sessions.map((s) => ({
        id: s.id,
        online: s.online,
        placeId: s.snapshot?.placeId,
        activeRig: s.snapshot?.activeRig?.name,
      })),
    };
  } catch (err) {
    return {
      connected: false,
      status: 'DISCONNECTED',
      rpcPort: cfg?.port,
      pid: cfg?.pid,
      detail: err.message,
    };
  }
}

async function checkOpenRig() {
  const isAvailable = existsSync(OPENRIG_DIR);
  const pkgPath = resolve(OPENRIG_DIR, 'package.json');
  let version = 'unknown';
  if (isAvailable && existsSync(pkgPath)) {
    try {
      const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));
      version = pkg.version ?? 'unknown';
    } catch {}
  }

  let serverRunning = false;
  try {
    const res = await fetch('http://localhost:4330', { signal: AbortSignal.timeout(1000) });
    serverRunning = res.ok;
  } catch {
    serverRunning = false;
  }

  return {
    evaluationDirFound: isAvailable,
    path: OPENRIG_DIR,
    version,
    serverOnline: serverRunning,
    status: !isAvailable
      ? 'NOT_FOUND'
      : serverRunning
        ? 'EVALUATION_SERVER_ONLINE'
        : 'EVALUATION_DIR_FOUND_SERVER_OFFLINE',
    pipelineActive: false,
    limitations:
      'OpenRig Studio is an AI generative animation tool in evaluation; it has no automated recipe import or AnimSaves injection pipeline for Cage-Zero.',
  };
}

const motionStatus = await checkMotionTools();
const openRigStatus = await checkOpenRig();

const output = {
  timestamp: new Date().toISOString(),
  motionTools: {
    connected: motionStatus.connected,
    status: motionStatus.status,
    rpcPort: motionStatus.rpcPort,
    detail: motionStatus.detail ?? 'Active',
    sessions: motionStatus.sessions,
  },
  openRig: {
    status: openRigStatus.status,
    path: openRigStatus.path,
    version: openRigStatus.version,
    serverOnline: openRigStatus.serverOnline,
    pipelineActive: openRigStatus.pipelineActive,
    limitations: openRigStatus.limitations,
  },
  assessment: motionStatus.connected
    ? 'Motion Tools bridge is ONLINE and responsive.'
    : 'Motion Tools bridge is DISCONNECTED (port not responding). OpenRig is an evaluation tool and is not an active pipeline replacement.',
};

console.log(JSON.stringify(output, null, 2));
