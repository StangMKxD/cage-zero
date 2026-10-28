import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { join } from 'node:path';

const WORKSPACE = 'C:/Users/Stang/cage-zero/cage-zero-animation-work';
const ARTIFACTS_DIR = join(WORKSPACE, 'artifacts');

const JOINTS = [
  'LowerTorso',
  'UpperTorso',
  'Head',
  'LeftUpperArm',
  'LeftLowerArm',
  'LeftHand',
  'RightUpperArm',
  'RightLowerArm',
  'RightHand',
  'LeftUpperLeg',
  'LeftLowerLeg',
  'LeftFoot',
  'RightUpperLeg',
  'RightLowerLeg',
  'RightFoot',
];

const r3 = (v) => Math.round(v * 1000) / 1000;
const vec3 = (x, y, z) => [r3(x), r3(y), r3(z)];
const deg2rad = (d) => (d * Math.PI) / 180;
const sin2p = (u, phaseDeg = 0) => Math.sin(2 * Math.PI * u + deg2rad(phaseDeg));
const cos2p = (u, phaseDeg = 0) => Math.cos(2 * Math.PI * u + deg2rad(phaseDeg));

// Smooth cubic Hermite / bell window on [t0, t1], peaking at tm
function pulse(u, u0, um, u1) {
  if (u <= u0 || u >= u1) return 0;
  if (u <= um) {
    const s = (u - u0) / (um - u0);
    return s * s * (3 - 2 * s);
  }
  const s = (u1 - u) / (u1 - um);
  return s * s * (3 - 2 * s);
}

function smoothstep(u, u0, u1) {
  if (u <= u0) return 0;
  if (u >= u1) return 1;
  const s = (u - u0) / (u1 - u0);
  return s * s * (3 - 2 * s);
}

function buildTracks(duration, keyCount, poseAt) {
  const tracks = JOINTS.map((joint) => ({ joint, keys: [] }));
  for (let i = 0; i < keyCount; i++) {
    const u = i / (keyCount - 1);
    const time = r3(u * duration);
    const pose = poseAt(u, time);
    for (const track of tracks) {
      const jp = pose[track.joint] ?? { position: [0, 0, 0], rotation: [0, 0, 0] };
      track.keys.push({
        time,
        position: jp.position ? vec3(...jp.position) : [0, 0, 0],
        rotation: jp.rotation ? vec3(...jp.rotation) : [0, 0, 0],
        easingStyle: 'Linear',
        easingDirection: 'InOut',
      });
    }
  }
  return tracks;
}


// ---- Cut enhancement (RF02 owner request 2026-10-28: more leg reach, more action, smoother) ----
// Quintic smootherstep bell: zero velocity AND acceleration at both ends (smoother than cubic pulse).
function pulseQ(u, u0, um, u1) {
  if (u <= u0 || u >= u1) return 0;
  const q = (s) => s * s * s * (s * (s * 6 - 15) + 10);
  return u <= um ? q((u - u0) / (um - u0)) : q((u1 - u) / (u1 - um));
}
const CUT_GAIN = { leg: 1.6, torso: 1.4, arm: 1.45, head: 1.2, pos: 1.6 };
function cutGainFor(joint) {
  if (joint.includes('Leg') || joint.includes('Foot')) return CUT_GAIN.leg;
  if (joint.includes('Arm') || joint.includes('Hand')) return CUT_GAIN.arm;
  if (joint === 'Head') return CUT_GAIN.head;
  return CUT_GAIN.torso;
}
// Amplifies the delta from the u=0 pose so the clip still starts/ends on the neutral pose.
function enhanceCut(poseAt) {
  const base = poseAt(0, 0);
  return (u, t) => {
    const p = poseAt(u, t);
    const out = {};
    for (const [joint, s] of Object.entries(p)) {
      const b = base[joint] ?? { position: [0, 0, 0], rotation: [0, 0, 0] };
      const g = cutGainFor(joint);
      const rot = (s.rotation ?? [0, 0, 0]).map((v, i) => (b.rotation?.[i] ?? 0) + (v - (b.rotation?.[i] ?? 0)) * g);
      const pos = (s.position ?? [0, 0, 0]).map((v, i) => (b.position?.[i] ?? 0) + (v - (b.position?.[i] ?? 0)) * CUT_GAIN.pos);
      out[joint] = { position: pos, rotation: rot };
    }
    return out;
  };
}
function buildCutTracks(duration, keyCount, poseAt) {
  return buildTracks(duration, keyCount, enhanceCut(poseAt));
}

// 1. WALK_DRIBBLE (RF02_WalkDribble_R15_v01)
// In-place R15 walk dribble cycle (1.04s, 33 keys, loop=true, priority=Movement).
// No periodic side-sway on held W (LowerTorso X stays within subtle support weight shift <= 0.018 studs).
// Distinct left/right controlled forward ball-tap extension at TouchL (0.195s / u=0.1875) and TouchR (0.715s / u=0.6875).
function makeWalkDribble() {
  const duration = 1.04;
  const keyCount = 33;
  const tracks = buildTracks(duration, keyCount, (u) => {
    const uLoop = u >= 1 ? 0 : u;
    const touchL = pulse(uLoop, 0.06, 0.1875, 0.34);
    const touchR = pulse(uLoop, 0.56, 0.6875, 0.84);

    // Subtle vertical rhythm (2 per cycle), minimal lateral shift (no side-sway)
    const pelY = -0.055 + 0.022 * cos2p(2 * uLoop, -25);
    const pelX = -0.015 * sin2p(uLoop, 0);
    const pelZ = 0.012 * (touchL + touchR) - 0.006;

    const pelPitch = -5.5 - 1.2 * cos2p(2 * uLoop, 0);
    const pelYaw = -4.5 * cos2p(uLoop, 0);
    const pelRoll = 1.6 * sin2p(uLoop, 0);

    const chestPitch = -5.0 - 1.0 * (touchL + touchR);
    const chestYaw = 6.2 * cos2p(uLoop, 0);
    const chestRoll = -1.4 * sin2p(uLoop, 0);

    // Head looks slightly down toward the ball in front (+8.5 deg counter-pitch + gentle gaze)
    const headPitch = 8.5 + 1.5 * (touchL + touchR);
    const headYaw = -1.7 * cos2p(uLoop, 0);
    const headRoll = -0.2 * sin2p(uLoop, 0);

    // Arms wider than plain walk for ball-shielding balance
    const lArmPitch = -20 * cos2p(uLoop, 0) + 4 * touchR;
    const rArmPitch = 20 * cos2p(uLoop, 0) + 4 * touchL;
    const lElbow = 28 + 8 * sin2p(uLoop, 15);
    const rElbow = 28 - 8 * sin2p(uLoop, 15);

    // Legs: base walk swing + controlled forward instep/laces touch reach at TouchL / TouchR
    const lHipPitch = 23 * cos2p(uLoop, -18) + 9.5 * touchL;
    const lHipYaw = -5.5 * touchL + 1.5 * sin2p(uLoop, 0);
    const lHipRoll = -1.2 - 1.8 * touchL;

    const lKneePitch =
      -12 -
      18 * (0.5 - 0.5 * cos2p(uLoop, -55)) -
      14 * pulse(uLoop, 0.52, 0.78, 0.98) +
      6 * touchL;

    // Foot points slightly down and turns slightly inward at TouchL for soft inside/laces nudge
    const lFootPitch = 7 * cos2p(uLoop, 10) - 14 * touchL;
    const lFootYaw = -9 * touchL;
    const lFootRoll = 1.0 + 3.5 * touchL;

    const uR = (uLoop + 0.5) % 1;
    const rHipPitch = 23 * cos2p(uR, -18) + 9.5 * touchR;
    const rHipYaw = 5.5 * touchR - 1.5 * sin2p(uLoop, 0);
    const rHipRoll = 1.2 + 1.8 * touchR;

    const rKneePitch =
      -12 -
      18 * (0.5 - 0.5 * cos2p(uR, -55)) -
      14 * pulse(uR, 0.52, 0.78, 0.98) +
      6 * touchR;

    const rFootPitch = 7 * cos2p(uR, 10) - 14 * touchR;
    const rFootYaw = 9 * touchR;
    const rFootRoll = -1.0 - 3.5 * touchR;

    return {
      LowerTorso: { position: [pelX, pelY, pelZ], rotation: [pelPitch, pelYaw, pelRoll] },
      UpperTorso: { position: [0, 0, 0], rotation: [chestPitch, chestYaw, chestRoll] },
      Head: { position: [0, 0, 0], rotation: [headPitch, headYaw, headRoll] },
      LeftUpperArm: { position: [0, 0, 0], rotation: [lArmPitch, 3.0 * cos2p(uLoop, 0), -10.5] },
      LeftLowerArm: { position: [0, 0, 0], rotation: [lElbow, 0, 0] },
      LeftHand: { position: [0, 0, 0], rotation: [-3 * cos2p(uLoop, 0), 0, -5] },
      RightUpperArm: { position: [0, 0, 0], rotation: [rArmPitch, 3.0 * cos2p(uLoop, 0), 10.5] },
      RightLowerArm: { position: [0, 0, 0], rotation: [rElbow, 0, 0] },
      RightHand: { position: [0, 0, 0], rotation: [3 * cos2p(uLoop, 0), 0, 5] },
      LeftUpperLeg: { position: [0, 0, 0], rotation: [lHipPitch, lHipYaw, lHipRoll] },
      LeftLowerLeg: { position: [0, 0, 0], rotation: [lKneePitch, 0, 0] },
      LeftFoot: { position: [0, 0, 0], rotation: [lFootPitch, lFootYaw, lFootRoll] },
      RightUpperLeg: { position: [0, 0, 0], rotation: [rHipPitch, rHipYaw, rHipRoll] },
      RightLowerLeg: { position: [0, 0, 0], rotation: [rKneePitch, 0, 0] },
      RightFoot: { position: [0, 0, 0], rotation: [rFootPitch, rFootYaw, rFootRoll] },
    };
  });

  return {
    kind: 'animation',
    name: 'RF02_WalkDribble_R15_v01',
    duration,
    loop: true,
    priority: 'Movement',
    markers: [
      { name: 'LeftSupportEntry', time: 0.0, value: 'left_cycle_start' },
      { name: 'TouchL', time: 0.195, value: 'left_foot_ball_touch' },
      { name: 'MidCycleTransition', time: 0.52, value: 'right_half_entry' },
      { name: 'TouchR', time: 0.715, value: 'right_foot_ball_touch' },
      { name: 'WalkDribbleLoop', time: 1.04, value: 'loop_seam' },
    ],
    tracks,
  };
}

// 2. RUN_DRIBBLE (RF02_RunDribble_R15_v01)
// In-place R15 sprint/run dribble cycle (0.72s, 33 keys, loop=true, priority=Movement).
// Forward torso lean, no periodic side-sway on held W, quick forward laces micro-taps at TouchL (0.135s) and TouchR (0.495s).
function makeRunDribble() {
  const duration = 0.72;
  const keyCount = 33;
  const tracks = buildTracks(duration, keyCount, (u) => {
    const uLoop = u >= 1 ? 0 : u;
    const touchL = pulse(uLoop, 0.05, 0.1875, 0.33);
    const touchR = pulse(uLoop, 0.55, 0.6875, 0.83);

    const pelY = -0.032 + 0.038 * cos2p(2 * uLoop, -35);
    const pelX = -0.018 * sin2p(uLoop, 0);
    const pelZ = 0.028 * cos2p(2 * uLoop, 0);

    const pelPitch = -11.5 - 1.5 * (touchL + touchR);
    const pelYaw = -11.0 * cos2p(uLoop, 0);
    const pelRoll = 2.2 * sin2p(uLoop, 0);

    const chestPitch = -13.0 - 1.2 * (touchL + touchR);
    const chestYaw = 14.0 * cos2p(uLoop, 0);
    const chestRoll = -1.8 * sin2p(uLoop, 0);

    const headPitch = 20.5 + 1.5 * (touchL + touchR);
    const headYaw = -3.0 * cos2p(uLoop, 0);
    const headRoll = -0.4 * sin2p(uLoop, 0);

    const lArmPitch = -44 * cos2p(uLoop, -10);
    const rArmPitch = 44 * cos2p(uLoop, -10);
    const lElbow = 72 + 16 * sin2p(uLoop, 10);
    const rElbow = 72 - 16 * sin2p(uLoop, 10);

    const lHipPitch = 46 * cos2p(uLoop, -22) + 11 * touchL;
    const lHipYaw = -3.5 * cos2p(uLoop, 0) - 3.0 * touchL;
    const lHipRoll = -1.5 - 1.5 * touchL;

    const lKneePitch =
      -18 -
      48 * (0.5 - 0.5 * cos2p(uLoop, -65)) +
      10 * touchL;

    // Laces push-forward tap at TouchL (plantarflexion)
    const lFootPitch = 12 * cos2p(uLoop, 15) - 22 * touchL;
    const lFootYaw = -4.0 * touchL;
    const lFootRoll = 1.2;

    const uR = (uLoop + 0.5) % 1;
    const rHipPitch = 46 * cos2p(uR, -22) + 11 * touchR;
    const rHipYaw = 3.5 * cos2p(uR, 0) + 3.0 * touchR;
    const rHipRoll = 1.5 + 1.5 * touchR;

    const rKneePitch =
      -18 -
      48 * (0.5 - 0.5 * cos2p(uR, -65)) +
      10 * touchR;

    const rFootPitch = 12 * cos2p(uR, 15) - 22 * touchR;
    const rFootYaw = 4.0 * touchR;
    const rFootRoll = -1.2;

    return {
      LowerTorso: { position: [pelX, pelY, pelZ], rotation: [pelPitch, pelYaw, pelRoll] },
      UpperTorso: { position: [0, 0, 0], rotation: [chestPitch, chestYaw, chestRoll] },
      Head: { position: [0, 0, 0], rotation: [headPitch, headYaw, headRoll] },
      LeftUpperArm: { position: [0, 0, 0], rotation: [lArmPitch, 7.5 * cos2p(uLoop, 0), -12.0] },
      LeftLowerArm: { position: [0, 0, 0], rotation: [lElbow, 0, 0] },
      LeftHand: { position: [0, 0, 0], rotation: [-5 * cos2p(uLoop, 0), 0, -6] },
      RightUpperArm: { position: [0, 0, 0], rotation: [rArmPitch, 7.5 * cos2p(uLoop, 0), 12.0] },
      RightLowerArm: { position: [0, 0, 0], rotation: [rElbow, 0, 0] },
      RightHand: { position: [0, 0, 0], rotation: [5 * cos2p(uLoop, 0), 0, 6] },
      LeftUpperLeg: { position: [0, 0, 0], rotation: [lHipPitch, lHipYaw, lHipRoll] },
      LeftLowerLeg: { position: [0, 0, 0], rotation: [lKneePitch, 0, 0] },
      LeftFoot: { position: [0, 0, 0], rotation: [lFootPitch, lFootYaw, lFootRoll] },
      RightUpperLeg: { position: [0, 0, 0], rotation: [rHipPitch, rHipYaw, rHipRoll] },
      RightLowerLeg: { position: [0, 0, 0], rotation: [rKneePitch, 0, 0] },
      RightFoot: { position: [0, 0, 0], rotation: [rFootPitch, rFootYaw, rFootRoll] },
    };
  });

  return {
    kind: 'animation',
    name: 'RF02_RunDribble_R15_v01',
    duration,
    loop: true,
    priority: 'Movement',
    markers: [
      { name: 'LeftDriveEntry', time: 0.0, value: 'left_stance_entry' },
      { name: 'TouchL', time: 0.135, value: 'left_foot_sprint_tap' },
      { name: 'RightDriveEntry', time: 0.36, value: 'right_stance_entry' },
      { name: 'TouchR', time: 0.495, value: 'right_foot_sprint_tap' },
      { name: 'RunDribbleLoop', time: 0.72, value: 'loop_seam' },
    ],
    tracks,
  };
}

// 3. DIAGONAL FRONT CUTS (AW = Front-Left, WD = Front-Right)
// One-shot (0.44s, 23 keys, loop=false, priority=Action).
// dirSign = +1 for Front-Left (AW: plant Right, cut/touch with Left foot at 0.18s, ControlRelease at 0.36s)
// dirSign = -1 for Front-Right (WD: plant Left, cut/touch with Right foot at 0.18s, ControlRelease at 0.36s)
function makeDiagFrontCut(dirSign, name, chordLabel) {
  const duration = 0.44;
  const keyCount = 45;
  const isLeft = dirSign > 0;
  const tracks = buildCutTracks(duration, keyCount, (u) => {
    const plant = pulseQ(u, 0.0, 0.22, 0.65);
    const touch = pulseQ(u, 0.14, 0.409, 0.76); // peaks at t = 0.18s (u = 0.409)
    const drive = pulseQ(u, 0.38, 0.68, 0.98);

    // Lower center of gravity on brake, slight lateral lean into new diagonal direction
    const pelY = -0.045 - 0.095 * plant - 0.04 * drive;
    const pelX = -dirSign * 0.065 * plant + dirSign * 0.055 * drive;
    const pelZ = -0.035 * plant + 0.03 * drive;

    const pelPitch = -6.0 - 6.5 * plant - 4.0 * drive;
    const pelYaw = dirSign * (-10 * plant + 22 * touch + 14 * drive);
    const pelRoll = dirSign * (-5.5 * plant + 6.5 * drive);

    const chestPitch = -5.5 - 5.0 * plant - 3.5 * drive;
    const chestYaw = dirSign * (14 * touch + 8 * drive);
    const chestRoll = dirSign * (4.0 * plant - 5.0 * drive);

    const headPitch = 9.0 + 6.5 * plant + 4.0 * touch;
    const headYaw = dirSign * (10 * touch + 6 * drive);

    // Plant leg vs Cut/Touch leg
    const plantHipPitch = 26 * plant + 10 * touch - 8 * drive;
    const plantHipRoll = -dirSign * (8.5 * plant + 4.0 * touch);
    const plantKneePitch = -14 - 32 * plant - 18 * touch;
    const plantFootPitch = 10 * plant - 8 * drive;

    const cutHipPitch = -10 * plant + 36 * touch + 18 * drive;
    const cutHipYaw = dirSign * (-14 * touch + 8 * drive);
    const cutHipRoll = dirSign * (11 * touch + 5 * drive);
    const cutKneePitch = -14 - 24 * plant - 14 * touch - 12 * drive;
    const cutFootPitch = -16 * touch + 6 * drive;
    const cutFootYaw = dirSign * (-18 * touch);
    const cutFootRoll = dirSign * (8 * touch);

    return {
      LowerTorso: { position: [pelX, pelY, pelZ], rotation: [pelPitch, pelYaw, pelRoll] },
      UpperTorso: { position: [0, 0, 0], rotation: [chestPitch, chestYaw, chestRoll] },
      Head: { position: [0, 0, 0], rotation: [headPitch, headYaw, 0] },
      LeftUpperArm: {
        position: [0, 0, 0],
        rotation: [isLeft ? -26 * touch + 14 * drive : 28 * plant - 12 * touch, 4 * dirSign * touch, -16 - 8 * plant],
      },
      LeftLowerArm: { position: [0, 0, 0], rotation: [38 + 24 * plant + 14 * touch, 0, 0] },
      LeftHand: { position: [0, 0, 0], rotation: [0, 0, -6] },
      RightUpperArm: {
        position: [0, 0, 0],
        rotation: [isLeft ? 28 * plant - 12 * touch : -26 * touch + 14 * drive, 4 * dirSign * touch, 16 + 8 * plant],
      },
      RightLowerArm: { position: [0, 0, 0], rotation: [38 + 24 * plant + 14 * touch, 0, 0] },
      RightHand: { position: [0, 0, 0], rotation: [0, 0, 6] },
      LeftUpperLeg: {
        position: [0, 0, 0],
        rotation: isLeft ? [cutHipPitch, cutHipYaw, cutHipRoll] : [plantHipPitch, 0, plantHipRoll],
      },
      LeftLowerLeg: {
        position: [0, 0, 0],
        rotation: [isLeft ? cutKneePitch : plantKneePitch, 0, 0],
      },
      LeftFoot: {
        position: [0, 0, 0],
        rotation: isLeft ? [cutFootPitch, cutFootYaw, cutFootRoll] : [plantFootPitch, 0, -plantHipRoll * 0.4],
      },
      RightUpperLeg: {
        position: [0, 0, 0],
        rotation: isLeft ? [plantHipPitch, 0, plantHipRoll] : [cutHipPitch, cutHipYaw, cutHipRoll],
      },
      RightLowerLeg: {
        position: [0, 0, 0],
        rotation: [isLeft ? plantKneePitch : cutKneePitch, 0, 0],
      },
      RightFoot: {
        position: [0, 0, 0],
        rotation: isLeft ? [plantFootPitch, 0, -plantHipRoll * 0.4] : [cutFootPitch, cutFootYaw, cutFootRoll],
      },
    };
  });

  return {
    kind: 'animation',
    name,
    duration,
    loop: false,
    priority: 'Action',
    markers: [
      { name: 'PlantBrake', time: 0.08, value: `${chordLabel}_brake_plant` },
      {
        name: isLeft ? 'TouchL' : 'TouchR',
        time: 0.18,
        value: `${chordLabel}_diagonal_cut_touch_${isLeft ? 'left' : 'right'}`,
      },
      { name: 'ControlRelease', time: 0.36, value: 'cut_exit_ready' },
      { name: 'ClipEnd', time: 0.44, value: 'one_shot_complete' },
    ],
    tracks,
  };
}

// 4. DIAGONAL BACKWARD PULL-CUTS (AS = Back-Left 135 deg, SD = Back-Right 135 deg)
// One-shot (0.52s, 27 keys, loop=false, priority=Action).
// First touch locks/drags the ball back at 0.16s, second touch redirects into back-diagonal exit at 0.30s, ControlRelease at 0.44s.
function makeDiagBackCut(dirSign, name, chordLabel) {
  const duration = 0.52;
  const keyCount = 53;
  const isLeft = dirSign > 0;
  const tracks = buildCutTracks(duration, keyCount, (u) => {
    const reach = pulseQ(u, 0.0, 0.308, 0.62); // peaks at t = 0.16s (u = 0.308)
    const redirect = pulseQ(u, 0.32, 0.577, 0.88); // peaks at t = 0.30s (u = 0.577)

    const pelY = -0.05 - 0.11 * reach - 0.075 * redirect;
    const pelX = dirSign * (-0.04 * reach + 0.07 * redirect);
    const pelZ = -0.04 * reach + 0.055 * redirect;

    const pelPitch = -6.0 - 4.5 * reach + 3.0 * redirect;
    const pelYaw = dirSign * (12 * reach + 32 * redirect);
    const pelRoll = dirSign * (-4.5 * reach + 5.5 * redirect);

    const chestPitch = -6.0 - 5.5 * reach - 3.0 * redirect;
    const chestYaw = dirSign * (10 * reach + 18 * redirect);
    const chestRoll = dirSign * (3.0 * reach - 4.0 * redirect);

    const headPitch = 11.0 + 7.5 * reach + 4.0 * redirect;
    const headYaw = dirSign * (8 * reach + 12 * redirect);

    // Lead foot reaches forward onto ball at 0.16s (sole drag back-diagonal), opposite foot taps/redirects at 0.30s
    const dragHipPitch = 40 * reach - 12 * redirect;
    const dragHipYaw = dirSign * (10 * reach + 16 * redirect);
    const dragHipRoll = dirSign * (6 * reach + 8 * redirect);
    const dragKneePitch = -14 - 16 * reach - 34 * redirect;
    const dragFootPitch = -18 * reach + 8 * redirect;
    const dragFootYaw = dirSign * (-14 * reach);

    const supHipPitch = 18 * reach + 30 * redirect;
    const supHipYaw = dirSign * (-8 * redirect);
    const supHipRoll = -dirSign * (7 * reach + 4 * redirect);
    const supKneePitch = -14 - 36 * reach - 20 * redirect;
    const supFootPitch = 12 * reach - 14 * redirect;
    const supFootYaw = dirSign * (-16 * redirect);

    return {
      LowerTorso: { position: [pelX, pelY, pelZ], rotation: [pelPitch, pelYaw, pelRoll] },
      UpperTorso: { position: [0, 0, 0], rotation: [chestPitch, chestYaw, chestRoll] },
      Head: { position: [0, 0, 0], rotation: [headPitch, headYaw, 0] },
      LeftUpperArm: {
        position: [0, 0, 0],
        rotation: [isLeft ? -28 * reach + 18 * redirect : 24 * reach - 20 * redirect, 0, -18 - 8 * reach],
      },
      LeftLowerArm: { position: [0, 0, 0], rotation: [42 + 22 * reach + 18 * redirect, 0, 0] },
      LeftHand: { position: [0, 0, 0], rotation: [0, 0, -6] },
      RightUpperArm: {
        position: [0, 0, 0],
        rotation: [isLeft ? 24 * reach - 20 * redirect : -28 * reach + 18 * redirect, 0, 18 + 8 * reach],
      },
      RightLowerArm: { position: [0, 0, 0], rotation: [42 + 22 * reach + 18 * redirect, 0, 0] },
      RightHand: { position: [0, 0, 0], rotation: [0, 0, 6] },
      LeftUpperLeg: {
        position: [0, 0, 0],
        rotation: isLeft ? [dragHipPitch, dragHipYaw, dragHipRoll] : [supHipPitch, supHipYaw, supHipRoll],
      },
      LeftLowerLeg: {
        position: [0, 0, 0],
        rotation: [isLeft ? dragKneePitch : supKneePitch, 0, 0],
      },
      LeftFoot: {
        position: [0, 0, 0],
        rotation: isLeft ? [dragFootPitch, dragFootYaw, 3] : [supFootPitch, supFootYaw, 2],
      },
      RightUpperLeg: {
        position: [0, 0, 0],
        rotation: isLeft ? [supHipPitch, supHipYaw, supHipRoll] : [dragHipPitch, dragHipYaw, dragHipRoll],
      },
      RightLowerLeg: {
        position: [0, 0, 0],
        rotation: [isLeft ? supKneePitch : dragKneePitch, 0, 0],
      },
      RightFoot: {
        position: [0, 0, 0],
        rotation: isLeft ? [supFootPitch, supFootYaw, -2] : [dragFootPitch, dragFootYaw, -3],
      },
    };
  });

  return {
    kind: 'animation',
    name,
    duration,
    loop: false,
    priority: 'Action',
    markers: [
      { name: 'PlantBrake', time: 0.08, value: `${chordLabel}_brake_entry` },
      {
        name: isLeft ? 'TouchL' : 'TouchR',
        time: 0.16,
        value: `${chordLabel}_sole_lock_drag_${isLeft ? 'left' : 'right'}`,
      },
      {
        name: isLeft ? 'TouchR' : 'TouchL',
        time: 0.30,
        value: `${chordLabel}_exit_redirect_${isLeft ? 'right' : 'left'}`,
      },
      { name: 'ControlRelease', time: 0.44, value: 'cut_exit_ready' },
      { name: 'ClipEnd', time: 0.52, value: 'one_shot_complete' },
    ],
    tracks,
  };
}

// 5. OPPOSITE-DIRECTION REVERSAL (W -> S 180 deg Pull-Back Hook)
// One-shot (0.56s, 29 keys, loop=false, priority=Action).
// Hard brake plant (Left leg), Right foot sole locks & pulls ball back at TouchR (0.16s),
// hips open right to hook/turn while Left foot cushions at TouchL (0.36s), ControlRelease at 0.48s.
function makeReverseCutWS() {
  const duration = 0.56;
  const keyCount = 57;
  const tracks = buildCutTracks(duration, keyCount, (u) => {
    const lock = pulseQ(u, 0.0, 0.286, 0.60); // peaks at t = 0.16s (u = 0.286)
    const hook = pulseQ(u, 0.30, 0.643, 0.92); // peaks at t = 0.36s (u = 0.643)

    const pelY = -0.05 - 0.125 * lock - 0.085 * hook;
    const pelX = -0.045 * lock + 0.05 * hook;
    const pelZ = -0.05 * lock + 0.065 * hook;

    const pelPitch = -6.0 - 5.5 * lock + 2.5 * hook;
    const pelYaw = -14 * lock - 34 * hook;
    const pelRoll = 4.5 * lock - 5.0 * hook;

    const chestPitch = -6.5 - 6.0 * lock - 3.5 * hook;
    const chestYaw = -10 * lock - 20 * hook;
    const chestRoll = -3.0 * lock + 3.5 * hook;

    const headPitch = 12.0 + 9.0 * lock + 5.0 * hook;
    const headYaw = -8 * lock - 12 * hook;

    // Left support leg plants deep during sole lock, then steps/taps ball at 0.36s
    const lHipPitch = 20 * lock + 28 * hook;
    const lHipYaw = -12 * hook;
    const lHipRoll = -6.5 * lock - 3.0 * hook;
    const lKneePitch = -14 - 38 * lock - 22 * hook;
    const lFootPitch = 14 * lock - 15 * hook;
    const lFootYaw = 14 * hook;

    // Right leg reaches forward to trap ball with sole at 0.16s, then sweeps back under body
    const rHipPitch = 44 * lock - 18 * hook;
    const rHipYaw = -8 * lock - 18 * hook;
    const rHipRoll = 4.0 * lock + 7.5 * hook;
    const rKneePitch = -14 - 14 * lock - 42 * hook;
    const rFootPitch = -22 * lock + 10 * hook;
    const rFootYaw = 12 * lock;

    return {
      LowerTorso: { position: [pelX, pelY, pelZ], rotation: [pelPitch, pelYaw, pelRoll] },
      UpperTorso: { position: [0, 0, 0], rotation: [chestPitch, chestYaw, chestRoll] },
      Head: { position: [0, 0, 0], rotation: [headPitch, headYaw, 0] },
      LeftUpperArm: { position: [0, 0, 0], rotation: [30 * lock - 22 * hook, 0, -20 - 8 * lock] },
      LeftLowerArm: { position: [0, 0, 0], rotation: [46 + 24 * lock + 16 * hook, 0, 0] },
      LeftHand: { position: [0, 0, 0], rotation: [0, 0, -6] },
      RightUpperArm: { position: [0, 0, 0], rotation: [-32 * lock + 24 * hook, 0, 20 + 8 * lock] },
      RightLowerArm: { position: [0, 0, 0], rotation: [46 + 24 * lock + 16 * hook, 0, 0] },
      RightHand: { position: [0, 0, 0], rotation: [0, 0, 6] },
      LeftUpperLeg: { position: [0, 0, 0], rotation: [lHipPitch, lHipYaw, lHipRoll] },
      LeftLowerLeg: { position: [0, 0, 0], rotation: [lKneePitch, 0, 0] },
      LeftFoot: { position: [0, 0, 0], rotation: [lFootPitch, lFootYaw, 2.5] },
      RightUpperLeg: { position: [0, 0, 0], rotation: [rHipPitch, rHipYaw, rHipRoll] },
      RightLowerLeg: { position: [0, 0, 0], rotation: [rKneePitch, 0, 0] },
      RightFoot: { position: [0, 0, 0], rotation: [rFootPitch, rFootYaw, -2.5] },
    };
  });

  return {
    kind: 'animation',
    name: 'RF02_CutReverse_WS_R15_v01',
    duration,
    loop: false,
    priority: 'Action',
    markers: [
      { name: 'HardBrake', time: 0.08, value: 'WS_reversal_brake' },
      { name: 'TouchR', time: 0.16, value: 'sole_lock_pullback_right' },
      { name: 'TouchL', time: 0.36, value: 'reverse_control_tap_left' },
      { name: 'ControlRelease', time: 0.48, value: 'cut_exit_ready' },
      { name: 'ClipEnd', time: 0.56, value: 'one_shot_complete' },
    ],
    tracks,
  };
}

// 6. G-MODE SLOW GOAL-FACING CLOSE CONTROL LOOP (RF02_GMode_SlowControlLoop_R15_v01)
// In-place R15 goal-facing slow close-control cycle (1.12s, 33 keys, loop=true, priority=Movement).
// Crouched poised stance facing goal, alternating sole-roll / inside-foot close touches (TouchL at 0.245s, TouchR at 0.805s).
function makeGModeSlowLoop() {
  const duration = 1.12;
  const keyCount = 33;
  const tracks = buildTracks(duration, keyCount, (u) => {
    const uLoop = u >= 1 ? 0 : u;
    const touchL = pulse(uLoop, 0.06, 0.21875, 0.42);
    const touchR = pulse(uLoop, 0.56, 0.71875, 0.92);

    const pelY = -0.095 + 0.018 * cos2p(2 * uLoop, -20);
    const pelX = -0.022 * sin2p(uLoop, 0);
    const pelZ = -0.015 + 0.014 * (touchL + touchR);

    // Chest and head stay squared toward the goal (minimal yaw oscillation)
    const pelPitch = -7.5 - 1.0 * (touchL + touchR);
    const pelYaw = -2.5 * cos2p(uLoop, 0);
    const pelRoll = 1.8 * sin2p(uLoop, 0);

    const chestPitch = -6.5;
    const chestYaw = 2.5 * cos2p(uLoop, 0);
    const chestRoll = -1.5 * sin2p(uLoop, 0);

    const headPitch = 11.5 + 1.5 * (touchL + touchR);
    const headYaw = 0;

    const lArmPitch = -12 * cos2p(uLoop, 0);
    const rArmPitch = 12 * cos2p(uLoop, 0);

    const lHipPitch = 20 + 8 * cos2p(uLoop, -15) + 12 * touchL;
    const lHipYaw = -8 * touchL;
    const lHipRoll = -4.5 - 4.0 * touchL;
    const lKneePitch = -26 - 12 * (0.5 - 0.5 * cos2p(uLoop, -45)) + 6 * touchL;
    const lFootPitch = 10 - 18 * touchL;
    const lFootYaw = -12 * touchL;

    const uR = (uLoop + 0.5) % 1;
    const rHipPitch = 20 + 8 * cos2p(uR, -15) + 12 * touchR;
    const rHipYaw = 8 * touchR;
    const rHipRoll = 4.5 + 4.0 * touchR;
    const rKneePitch = -26 - 12 * (0.5 - 0.5 * cos2p(uR, -45)) + 6 * touchR;
    const rFootPitch = 10 - 18 * touchR;
    const rFootYaw = 12 * touchR;

    return {
      LowerTorso: { position: [pelX, pelY, pelZ], rotation: [pelPitch, pelYaw, pelRoll] },
      UpperTorso: { position: [0, 0, 0], rotation: [chestPitch, chestYaw, chestRoll] },
      Head: { position: [0, 0, 0], rotation: [headPitch, headYaw, 0] },
      LeftUpperArm: { position: [0, 0, 0], rotation: [lArmPitch, 0, -16] },
      LeftLowerArm: { position: [0, 0, 0], rotation: [42, 0, 0] },
      LeftHand: { position: [0, 0, 0], rotation: [0, 0, -6] },
      RightUpperArm: { position: [0, 0, 0], rotation: [rArmPitch, 0, 16] },
      RightLowerArm: { position: [0, 0, 0], rotation: [42, 0, 0] },
      RightHand: { position: [0, 0, 0], rotation: [0, 0, 6] },
      LeftUpperLeg: { position: [0, 0, 0], rotation: [lHipPitch, lHipYaw, lHipRoll] },
      LeftLowerLeg: { position: [0, 0, 0], rotation: [lKneePitch, 0, 0] },
      LeftFoot: { position: [0, 0, 0], rotation: [lFootPitch, lFootYaw, 3] },
      RightUpperLeg: { position: [0, 0, 0], rotation: [rHipPitch, rHipYaw, rHipRoll] },
      RightLowerLeg: { position: [0, 0, 0], rotation: [rKneePitch, 0, 0] },
      RightFoot: { position: [0, 0, 0], rotation: [rFootPitch, rFootYaw, -3] },
    };
  });

  return {
    kind: 'animation',
    name: 'RF02_GMode_SlowControlLoop_R15_v01',
    duration,
    loop: true,
    priority: 'Movement',
    markers: [
      { name: 'GStanceEntry', time: 0.0, value: 'goal_facing_close_control_start' },
      { name: 'TouchL', time: 0.245, value: 'g_mode_sole_roll_left' },
      { name: 'GMidStance', time: 0.56, value: 'goal_facing_mid_cycle' },
      { name: 'TouchR', time: 0.805, value: 'g_mode_sole_roll_right' },
      { name: 'GControlLoop', time: 1.12, value: 'loop_seam' },
    ],
    tracks,
  };
}

// 7. G-MODE SOLE DRAG-BACK (W -> S while holding G, keeping chest/head facing goal)
// One-shot (0.52s, 27 keys, loop=false, priority=Action).
function makeGModeSoleDragBack() {
  const duration = 0.52;
  const keyCount = 53;
  const tracks = buildCutTracks(duration, keyCount, (u) => {
    const trap = pulseQ(u, 0.0, 0.269, 0.58); // peaks at t = 0.14s (u = 0.269)
    const pull = pulseQ(u, 0.28, 0.654, 0.92); // peaks at t = 0.34s (u = 0.654)

    const pelY = -0.095 - 0.065 * trap - 0.045 * pull;
    const pelX = -0.025 * trap + 0.02 * pull;
    const pelZ = -0.03 * trap + 0.055 * pull;

    // Stays goal-facing (yaw near 0!)
    const pelPitch = -7.5 - 3.5 * trap + 2.5 * pull;
    const pelYaw = -4.0 * trap + 2.0 * pull;
    const chestPitch = -6.5 - 4.0 * trap - 2.0 * pull;
    const chestYaw = 4.0 * trap - 2.0 * pull;
    const headPitch = 12.0 + 7.5 * trap + 4.0 * pull;

    // Left leg supports and hops back slightly, then cushions at 0.34s
    const lHipPitch = 22 + 10 * trap + 16 * pull;
    const lKneePitch = -28 - 18 * trap - 14 * pull;
    const lFootPitch = 12 - 12 * pull;

    // Right foot reaches forward onto ball top at 0.14s (TouchR), rolls ball back under body
    const rHipPitch = 20 + 28 * trap - 10 * pull;
    const rKneePitch = -26 + 10 * trap - 24 * pull;
    const rFootPitch = 8 - 26 * trap + 6 * pull;

    return {
      LowerTorso: { position: [pelX, pelY, pelZ], rotation: [pelPitch, pelYaw, 0] },
      UpperTorso: { position: [0, 0, 0], rotation: [chestPitch, chestYaw, 0] },
      Head: { position: [0, 0, 0], rotation: [headPitch, 0, 0] },
      LeftUpperArm: { position: [0, 0, 0], rotation: [18 * trap - 12 * pull, 0, -18 - 6 * trap] },
      LeftLowerArm: { position: [0, 0, 0], rotation: [46 + 16 * trap, 0, 0] },
      LeftHand: { position: [0, 0, 0], rotation: [0, 0, -6] },
      RightUpperArm: { position: [0, 0, 0], rotation: [-20 * trap + 14 * pull, 0, 18 + 6 * trap] },
      RightLowerArm: { position: [0, 0, 0], rotation: [46 + 16 * trap, 0, 0] },
      RightHand: { position: [0, 0, 0], rotation: [0, 0, 6] },
      LeftUpperLeg: { position: [0, 0, 0], rotation: [lHipPitch, -4 * pull, -4.5] },
      LeftLowerLeg: { position: [0, 0, 0], rotation: [lKneePitch, 0, 0] },
      LeftFoot: { position: [0, 0, 0], rotation: [lFootPitch, -6 * pull, 2.5] },
      RightUpperLeg: { position: [0, 0, 0], rotation: [rHipPitch, 4 * trap, 4.5] },
      RightLowerLeg: { position: [0, 0, 0], rotation: [rKneePitch, 0, 0] },
      RightFoot: { position: [0, 0, 0], rotation: [rFootPitch, 6 * trap, -2.5] },
    };
  });

  return {
    kind: 'animation',
    name: 'RF02_GMode_SoleDragBack_WS_R15_v01',
    duration,
    loop: false,
    priority: 'Action',
    markers: [
      { name: 'SoleTrapEntry', time: 0.06, value: 'g_mode_sole_reach' },
      { name: 'TouchR', time: 0.14, value: 'g_mode_sole_lock_drag_right' },
      { name: 'TouchL', time: 0.34, value: 'g_mode_cushion_settle_left' },
      { name: 'ControlRelease', time: 0.44, value: 'cut_exit_ready' },
      { name: 'ClipEnd', time: 0.52, value: 'one_shot_complete' },
    ],
    tracks,
  };
}

await mkdir(ARTIFACTS_DIR, { recursive: true });

const clips = [
  makeWalkDribble(),
  makeRunDribble(),
  makeDiagFrontCut(+1, 'RF02_CutDiagFrontLeft_AW_R15_v01', 'AW'),
  makeDiagFrontCut(-1, 'RF02_CutDiagFrontRight_WD_R15_v01', 'WD'),
  makeDiagBackCut(+1, 'RF02_CutDiagBackLeft_AS_R15_v01', 'AS'),
  makeDiagBackCut(-1, 'RF02_CutDiagBackRight_SD_R15_v01', 'SD'),
  makeReverseCutWS(),
  makeGModeSlowLoop(),
  makeGModeSoleDragBack(),
];

for (const clip of clips) {
  const filePath = join(ARTIFACTS_DIR, `${clip.name}.recipe.json`);
  await writeFile(filePath, JSON.stringify(clip, null, 2));
}

console.log(
  JSON.stringify(
    clips.map((c) => ({
      name: c.name,
      duration: c.duration,
      loop: c.loop,
      priority: c.priority,
      keyCount: c.tracks[0].keys.length,
      markers: c.markers,
    })),
    null,
    2
  )
);
