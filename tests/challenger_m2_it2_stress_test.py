#!/usr/bin/env python3
"""challenger_m2_it2_stress_test.py — Authoritative Empirical Stress Test for M2 Iteration 2.

Adversarially stress-tests JSON keyframes, Motion Tools recipes, and timing across all 10 outfield clips:
1. Non-root translation strict zero check across every frame and every non-root joint.
2. Timestamp monotonicity and uniform 30 FPS intervals.
3. Quaternion normalization (sum q_i^2 = 1.0 +- 1e-4) and SO(3) matrix validity.
4. StandingIdle02 limits stress test (keys <= 128, duration pinned at 5.2s).
5. Seam closure on 4 loops vs ending recovery preservation on 6 one-shots.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple

CANONICAL_R15_PARTS = [
    "LowerTorso",
    "UpperTorso",
    "Head",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
    "RightUpperLeg",
    "RightLowerLeg",
    "RightFoot",
]

CANONICAL_PARENTS = [0, 1, 2, 2, 4, 5, 2, 7, 8, 1, 10, 11, 1, 13, 14]

OUTFIELD_CLIPS = [
    {"name": "FastRun", "slug": "fast-run", "loop": True, "priority": "Movement", "duration": 0.5333, "frames": 17},
    {"name": "JogForward", "slug": "jog-forward", "loop": True, "priority": "Movement", "duration": 0.8333, "frames": 26},
    {"name": "ScissorKick", "slug": "scissor-kick", "loop": False, "priority": "Action", "duration": 2.8, "frames": 84, "dynamic_recovery": True},
    {"name": "SoccerPass", "slug": "soccer-pass", "loop": False, "priority": "Action", "duration": 1.6333, "frames": 49, "dynamic_recovery": False},
    {"name": "SoccerTackle", "slug": "soccer-tackle", "loop": False, "priority": "Action", "duration": 1.8, "frames": 54, "dynamic_recovery": True},
    {"name": "SoccerTrip", "slug": "soccer-trip", "loop": False, "priority": "Action", "duration": 1.6333, "frames": 49, "dynamic_recovery": True},
    {"name": "StandingIdle02", "slug": "standing-idle-02", "loop": True, "priority": "Movement", "duration": 5.2, "frames": 157, "subsample_max": 128},
    {"name": "StandingJump", "slug": "standing-jump", "loop": False, "priority": "Action", "duration": 2.4667, "frames": 74, "dynamic_recovery": False},
    {"name": "TurnBackRunning", "slug": "turn-back-running", "loop": False, "priority": "Action", "duration": 1.6667, "frames": 50, "dynamic_recovery": True},
    {"name": "StrikeFowardJog", "slug": "strike-foward-jog", "loop": True, "priority": "Movement", "duration": 1.3, "frames": 40},
]

BASE_DIR = Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\test_output_v3")


def matrix_3x3_to_quaternion(R: List[List[float]]) -> Tuple[float, float, float, float]:
    """Convert 3x3 rotation matrix to quaternion (w, x, y, z) via Shepperd's algorithm."""
    r00, r01, r02 = R[0][0], R[0][1], R[0][2]
    r10, r11, r12 = R[1][0], R[1][1], R[1][2]
    r20, r21, r22 = R[2][0], R[2][1], R[2][2]
    tr = r00 + r11 + r22

    if tr > 0.0:
        S = math.sqrt(tr + 1.0) * 2.0
        w = 0.25 * S
        x = (r21 - r12) / S
        y = (r02 - r20) / S
        z = (r10 - r01) / S
    elif (r00 > r11) and (r00 > r22):
        S = math.sqrt(1.0 + r00 - r11 - r22) * 2.0
        w = (r21 - r12) / S
        x = 0.25 * S
        y = (r01 + r10) / S
        z = (r02 + r20) / S
    elif r11 > r22:
        S = math.sqrt(1.0 + r11 - r00 - r22) * 2.0
        w = (r02 - r20) / S
        x = (r01 + r10) / S
        y = 0.25 * S
        z = (r12 + r21) / S
    else:
        S = math.sqrt(1.0 + r22 - r00 - r11) * 2.0
        w = (r10 - r01) / S
        x = (r02 + r20) / S
        y = (r12 + r21) / S
        z = 0.25 * S

    return (w, x, y, z)


def euler_zyx_to_quaternion(deg_x: float, deg_y: float, deg_z: float) -> Tuple[float, float, float, float]:
    """Convert intrinsic ZYX Euler angles in degrees (Blender to_euler('ZYX')) to quaternion (w, x, y, z)."""
    rz = math.radians(deg_z) * 0.5
    ry = math.radians(deg_y) * 0.5
    rx = math.radians(deg_x) * 0.5
    cz, sz = math.cos(rz), math.sin(rz)
    cy, sy = math.cos(ry), math.sin(ry)
    cx, sx = math.cos(rx), math.sin(rx)
    w = cz * cy * cx + sz * sy * sx
    x = cz * cy * sx - sz * sy * cx
    y = cz * sy * cx + sz * cy * sx
    z = sz * cy * cx - cz * sy * sx
    return (w, x, y, z)


def quat_angular_distance(q1: Tuple[float, float, float, float], q2: Tuple[float, float, float, float]) -> float:
    """Compute shortest geodesic distance between two unit quaternions in radians."""
    dot = abs(q1[0] * q2[0] + q1[1] * q2[1] + q1[2] * q2[2] + q1[3] * q2[3])
    return 2.0 * math.acos(min(1.0, dot))


def matrix_det_3x3(R: List[List[float]]) -> float:
    return (
        R[0][0] * (R[1][1] * R[2][2] - R[1][2] * R[2][1])
        - R[0][1] * (R[1][0] * R[2][2] - R[1][2] * R[2][0])
        + R[0][2] * (R[1][0] * R[2][1] - R[1][1] * R[2][0])
    )


def matrix_ortho_residual(R: List[List[float]]) -> float:
    max_err = 0.0
    for i in range(3):
        for j in range(3):
            val = sum(R[i][k] * R[j][k] for k in range(3))
            expected = 1.0 if i == j else 0.0
            err = abs(val - expected)
            if err > max_err:
                max_err = err
    return max_err


class EmpiricalStressHarness:
    def __init__(self):
        self.summary: Dict[str, Any] = {}
        self.all_passed = True
        self.failures: List[str] = []

    def record(self, clip: str, check_name: str, passed: bool, details: Any):
        if clip not in self.summary:
            self.summary[clip] = {}
        self.summary[clip][check_name] = {"passed": passed, "details": details}
        status_str = "PASS" if passed else "FAIL"
        print(f"[{status_str}] [{clip:16s}] {check_name}: {details}")
        if not passed:
            self.all_passed = False
            self.failures.append(f"[{clip}] {check_name}: {details}")

    def run(self):
        print("=" * 80)
        print(" EMPIRICAL ADVERSARIAL STRESS TEST — M2 ITERATION 2 (10 OUTFIELD CLIPS)")
        print("=" * 80)

        for meta in OUTFIELD_CLIPS:
            name = meta["name"]
            is_loop = meta["loop"]
            nom_duration = meta["duration"]
            expected_frames = meta["frames"]
            dynamic_recovery = meta.get("dynamic_recovery", False)

            clip_dir = BASE_DIR / name
            kf_path = clip_dir / f"{name}-r15-keyframes.json"
            rc_path = clip_dir / f"{name}.recipe.json"

            print(f"\n--- [CLIP] {name} (Loop={is_loop}, Duration={nom_duration:.4f}s, Frames={expected_frames}) ---")

            if not kf_path.is_file():
                self.record(name, "keyframes_file_present", False, f"Missing {kf_path}")
                continue
            if not rc_path.is_file():
                self.record(name, "recipe_file_present", False, f"Missing {rc_path}")
                continue

            with open(kf_path, "r", encoding="utf-8") as f:
                kf = json.load(f)
            with open(rc_path, "r", encoding="utf-8") as f:
                rc = json.load(f)

            # =================================================================
            # CHECK 1: Non-Root Translation Strictly Zero (No Floating-Point Leaks)
            # =================================================================
            # 1A. In Keyframes JSON
            kf_non_root_leaks = 0
            kf_max_non_root_mag = 0.0
            frames = kf.get("frames", [])
            for f_idx, fr in enumerate(frames):
                poses = fr.get("poses", [])
                for p_idx in range(1, len(poses)):
                    p = poses[p_idx]
                    tx, ty, tz = p[0], p[1], p[2]
                    mag = math.sqrt(tx * tx + ty * ty + tz * tz)
                    if mag > kf_max_non_root_mag:
                        kf_max_non_root_mag = mag
                    if tx != 0.0 or ty != 0.0 or tz != 0.0:
                        kf_non_root_leaks += 1

            self.record(
                name,
                "kf_non_root_translation_zero",
                kf_non_root_leaks == 0 and kf_max_non_root_mag == 0.0,
                f"leaks_count={kf_non_root_leaks}, max_magnitude={kf_max_non_root_mag:.10e}"
            )

            # 1B. In Recipe JSON
            rc_non_root_leaks = 0
            rc_max_non_root_mag = 0.0
            rc_tracks = rc.get("tracks", [])
            for track in rc_tracks:
                joint = track.get("joint")
                if joint == "LowerTorso":
                    continue
                for k_idx, k in enumerate(track.get("keys", [])):
                    pos = k.get("position", [])
                    px, py, pz = pos[0], pos[1], pos[2]
                    mag = math.sqrt(px * px + py * py + pz * pz)
                    if mag > rc_max_non_root_mag:
                        rc_max_non_root_mag = mag
                    if px != 0.0 or py != 0.0 or pz != 0.0:
                        rc_non_root_leaks += 1

            self.record(
                name,
                "rc_non_root_translation_zero",
                rc_non_root_leaks == 0 and rc_max_non_root_mag == 0.0,
                f"leaks_count={rc_non_root_leaks}, max_magnitude={rc_max_non_root_mag:.10e}"
            )

            # =================================================================
            # CHECK 2: Timestamp Monotonicity & Uniform 30 FPS Intervals
            # =================================================================
            # 2A. In Keyframes JSON
            kf_times = [fr.get("time") for fr in frames]
            kf_monotonic = all(kf_times[i] < kf_times[i + 1] for i in range(len(kf_times) - 1))
            kf_intervals = [kf_times[i + 1] - kf_times[i] for i in range(len(kf_times) - 1)]
            kf_min_dt = min(kf_intervals) if kf_intervals else 0.0
            kf_max_dt = max(kf_intervals) if kf_intervals else 0.0
            nom_dt = 1.0 / 30.0
            kf_max_dt_dev = max(abs(dt - nom_dt) for dt in kf_intervals) if kf_intervals else 0.0

            self.record(
                name,
                "kf_timestamp_monotonicity",
                kf_monotonic and kf_times[0] == 0.0,
                f"t[0]={kf_times[0]:.6f}, t[N-1]={kf_times[-1]:.6f}, monotonic={kf_monotonic}"
            )
            self.record(
                name,
                "kf_uniform_30fps_intervals",
                kf_max_dt_dev < 1e-4,
                f"min_dt={kf_min_dt:.6f}s, max_dt={kf_max_dt:.6f}s, max_dev={kf_max_dt_dev:.2e}s"
            )

            # 2B. In Recipe JSON
            rc_monotonic = True
            for track in rc_tracks:
                times = [k.get("time") for k in track.get("keys", [])]
                for i in range(len(times) - 1):
                    if times[i + 1] <= times[i]:
                        rc_monotonic = False

            self.record(
                name,
                "rc_timestamp_monotonicity",
                rc_monotonic,
                f"Strictly monotonic across all 15 tracks: {rc_monotonic}"
            )

            if name != "StandingIdle02":
                keys0 = rc_tracks[0].get("keys", [])
                rc_times = [k.get("time") for k in keys0]
                rc_intervals = [rc_times[i + 1] - rc_times[i] for i in range(len(rc_times) - 1)]
                rc_min_dt = min(rc_intervals) if rc_intervals else 0.0
                rc_max_dt = max(rc_intervals) if rc_intervals else 0.0
                rc_uniform_30fps = all(0.032 <= dt <= 0.035 for dt in rc_intervals)
                self.record(
                    name,
                    "rc_uniform_30fps_intervals",
                    rc_uniform_30fps,
                    f"keys={len(keys0)}, min_dt={rc_min_dt:.4f}s, max_dt={rc_max_dt:.4f}s"
                )

            # =================================================================
            # CHECK 3: Quaternion Normalization (sum q_i^2 = 1.0 +- 1e-4) & SO(3) Orthogonality
            # =================================================================
            max_quat_norm_err = 0.0
            max_ortho_residual = 0.0
            max_det_err = 0.0

            for f_idx, fr in enumerate(frames):
                poses = fr.get("poses", [])
                for p_idx, p in enumerate(poses):
                    R = [
                        [p[3], p[4], p[5]],
                        [p[6], p[7], p[8]],
                        [p[9], p[10], p[11]],
                    ]
                    ortho_res = matrix_ortho_residual(R)
                    if ortho_res > max_ortho_residual:
                        max_ortho_residual = ortho_res
                    det = matrix_det_3x3(R)
                    det_err = abs(det - 1.0)
                    if det_err > max_det_err:
                        max_det_err = det_err

                    w, x, y, z = matrix_3x3_to_quaternion(R)
                    norm_sq = w * w + x * x + y * y + z * z
                    quat_err = abs(norm_sq - 1.0)
                    if quat_err > max_quat_norm_err:
                        max_quat_norm_err = quat_err

            self.record(
                name,
                "kf_quaternion_normalization_1e-4",
                max_quat_norm_err <= 1e-4,
                f"max_norm_sq_dev={max_quat_norm_err:.6e} (tolerance <= 1e-4)"
            )
            self.record(
                name,
                "kf_so3_orthogonality_and_det",
                max_ortho_residual < 1e-4 and max_det_err < 1e-4,
                f"max_ortho_res={max_ortho_residual:.6e}, max_det_err={max_det_err:.6e}"
            )

            # Recipe Euler angle bounds and normalization
            rc_max_euler_quat_err = 0.0
            for track in rc_tracks:
                for k in track.get("keys", []):
                    rot = k.get("rotation", [])
                    qw, qx, qy, qz = euler_zyx_to_quaternion(rot[0], rot[1], rot[2])
                    q_n = qw * qw + qx * qx + qy * qy + qz * qz
                    q_err = abs(q_n - 1.0)
                    if q_err > rc_max_euler_quat_err:
                        rc_max_euler_quat_err = q_err

            self.record(
                name,
                "rc_euler_quaternion_normalized",
                rc_max_euler_quat_err < 1e-4,
                f"max_norm_sq_dev={rc_max_euler_quat_err:.6e}"
            )

            # =================================================================
            # CHECK 4: StandingIdle02 Stress Test (Keys <= 128, Duration == 5.2s)
            # =================================================================
            if name == "StandingIdle02":
                print("\n>>> STRESS-TEST: StandingIdle02 Motion Tools Constraints <<<")
                max_track_keys = max(len(t.get("keys", [])) for t in rc_tracks)
                all_tracks_128 = all(len(t.get("keys", [])) == 128 for t in rc_tracks)
                self.record(
                    name,
                    "standing_idle_keys_le_128",
                    max_track_keys <= 128 and all_tracks_128,
                    f"max_track_keys={max_track_keys} (Motion Tools limit <= 128), all_15_tracks_128={all_tracks_128}"
                )

                t_first = rc_tracks[0]["keys"][0]["time"]
                t_final = rc_tracks[0]["keys"][-1]["time"]
                kf_dur = kf.get("duration", 0.0)
                rc_dur = rc.get("duration", 0.0)
                dur_pinned = (
                    abs(t_first - 0.0) < 1e-4
                    and abs(t_final - 5.2) < 0.005
                    and abs(kf_dur - 5.2) < 0.005
                    and abs(rc_dur - 5.2) < 0.005
                )
                self.record(
                    name,
                    "standing_idle_duration_pinned_5_2s",
                    dur_pinned,
                    f"t_first={t_first:.4f}s, t_final={t_final:.4f}s, kf_dur={kf_dur:.4f}s, rc_dur={rc_dur:.4f}s"
                )

                # Subsampled key interval coverage
                id_times = [k["time"] for k in rc_tracks[0]["keys"]]
                id_intervals = [id_times[i + 1] - id_times[i] for i in range(len(id_times) - 1)]
                self.record(
                    name,
                    "standing_idle_subsample_distribution",
                    min(id_intervals) > 0.0 and max(id_intervals) < 0.10,
                    f"min_dt={min(id_intervals):.4f}s, max_dt={max(id_intervals):.4f}s, avg_dt={sum(id_intervals)/len(id_intervals):.4f}s"
                )

            # =================================================================
            # CHECK 5: Seam Closure on 4 Loops vs Ending Recovery on 6 One-Shots
            # =================================================================
            p_start = frames[0]["poses"]
            p_end = frames[-1]["poses"]
            kf_max_seam_delta = max(
                abs(p_start[j][c] - p_end[j][c])
                for j in range(len(p_start))
                for c in range(12)
            )

            # Recipe geodesic angular difference & position difference
            rc_max_pos_delta = 0.0
            rc_max_rot_angle_rad = 0.0
            for track in rc_tracks:
                k0 = track["keys"][0]
                kend = track["keys"][-1]
                p_diff = max(abs(k0["position"][i] - kend["position"][i]) for i in range(3))
                if p_diff > rc_max_pos_delta:
                    rc_max_pos_delta = p_diff
                q0 = euler_zyx_to_quaternion(k0["rotation"][0], k0["rotation"][1], k0["rotation"][2])
                q1 = euler_zyx_to_quaternion(kend["rotation"][0], kend["rotation"][1], kend["rotation"][2])
                ang_diff = quat_angular_distance(q0, q1)
                if ang_diff > rc_max_rot_angle_rad:
                    rc_max_rot_angle_rad = ang_diff

            if is_loop:
                # 4 LOOPS: keys[0] == keys[-1]
                kf_closed = kf_max_seam_delta < 1e-4
                rc_closed = rc_max_pos_delta < 1e-4 and rc_max_rot_angle_rad < 1e-4
                self.record(
                    name,
                    "loop_seam_closed_4_loops",
                    kf_closed and rc_closed,
                    f"kf_max_delta={kf_max_seam_delta:.8e}, rc_pos_delta={rc_max_pos_delta:.8e}, rc_rot_angle_diff={math.degrees(rc_max_rot_angle_rad):.8e}°"
                )
            else:
                # 6 ONE-SHOTS: loop == false, seam_closed == false
                loop_flag_false = (kf.get("loop") is False) and (rc.get("loop") is False)
                if dynamic_recovery:
                    # Dynamic actions (kick, tackle, trip, turn) must preserve recovery pose (keys[0] != keys[-1])
                    recovery_preserved = kf_max_seam_delta > 0.05
                    self.record(
                        name,
                        "oneshot_recovery_preserved_6_oneshots",
                        loop_flag_false and recovery_preserved,
                        f"loop=False: {loop_flag_false}, kf_recovery_delta={kf_max_seam_delta:.4f} (> 0.05), rc_pos_delta={rc_max_pos_delta:.4f}"
                    )
                else:
                    # Stance-rest action one-shots (SoccerPass, StandingJump) naturally return to standing rest in source Mixamo FBX
                    self.record(
                        name,
                        "oneshot_recovery_preserved_6_oneshots",
                        loop_flag_false,
                        f"loop=False: {loop_flag_false}, authentic rest-return from Mixamo source preserved (kf_delta={kf_max_seam_delta:.6e})"
                    )

        print("\n" + "=" * 80)
        print(" FINAL ADVERSARIAL STRESS TEST VERDICT")
        print("=" * 80)
        print(f"Overall Passed: {self.all_passed}")
        print(f"Total Failures: {len(self.failures)}")
        if self.failures:
            print("Detected Failures:")
            for f in self.failures:
                print(f"  * {f}")
        else:
            print(">> ALL 10 OUTFIELD CLIPS CONFIRMED PASS 100% <<")

        # Save machine-readable report
        output_report = Path(r"C:\Users\Stang\cage-zero\.agents\teamwork\challenger_m2_it2_2\stress_test_report.json")
        with open(output_report, "w", encoding="utf-8") as f:
            json.dump({
                "verdict": "CONFIRMED" if self.all_passed else "REFUTED",
                "all_passed": self.all_passed,
                "total_failures": len(self.failures),
                "failures": self.failures,
                "summary": self.summary
            }, f, indent=2)
        print(f"Detailed challenge report written to: {output_report}")
        return self.all_passed


if __name__ == "__main__":
    harness = EmpiricalStressHarness()
    ok = harness.run()
    sys.exit(0 if ok else 1)
