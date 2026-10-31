#!/usr/bin/env python3
"""adversarial_challenge_m2_2.py — Empirical Challenger Harness for Milestone 2.

Adversarial Stress Test & Verification Suite for the 10 M2 Outfield Animation Clips:
1. FastRun
2. JogForward
3. ScissorKick
4. SoccerPass
5. SoccerTackle
6. SoccerTrip
7. StandingIdle02
8. StandingJump
9. TurnBackRunning
10. StrikeFowardJog

Validates:
- -r15-keyframes.json: monotonic timestamps, valid normalized quaternions / SO(3) orthogonal matrices,
  root translation presence and dynamics, strict absence of non-root translation.
- .recipe.json: kind="animation", monotonic track timestamps, exactly 15 canonical R15 tracks,
  translation channels identically zeroed on all 14 non-root bones, finite Euler angles in [-720, 720].
- StandingIdle02 subsampling stress test: track keys count strictly <= 128, final key pinned to 5.2s,
  first key pinned to 0.0s, no NaN/Inf, uniform/continuous coverage.
- Seam closure vs one-shot recovery invariants.
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
    {"name": "FastRun", "slug": "fast-run", "loop": True, "priority": "Movement", "expected_duration": 0.5333, "expected_frames": 17},
    {"name": "JogForward", "slug": "jog-forward", "loop": True, "priority": "Movement", "expected_duration": 0.8333, "expected_frames": 26},
    {"name": "ScissorKick", "slug": "scissor-kick", "loop": False, "priority": "Action", "expected_duration": 2.8, "expected_frames": 84},
    {"name": "SoccerPass", "slug": "soccer-pass", "loop": False, "priority": "Action", "expected_duration": 1.6333, "expected_frames": 49},
    {"name": "SoccerTackle", "slug": "soccer-tackle", "loop": False, "priority": "Action", "expected_duration": 1.8, "expected_frames": 54},
    {"name": "SoccerTrip", "slug": "soccer-trip", "loop": False, "priority": "Action", "expected_duration": 1.6333, "expected_frames": 49},
    {"name": "StandingIdle02", "slug": "standing-idle-02", "loop": True, "priority": "Movement", "expected_duration": 5.2, "expected_frames": 157, "subsample_max": 128},
    {"name": "StandingJump", "slug": "standing-jump", "loop": False, "priority": "Action", "expected_duration": 2.4667, "expected_frames": 74},
    {"name": "TurnBackRunning", "slug": "turn-back-running", "loop": False, "priority": "Action", "expected_duration": 1.6667, "expected_frames": 50},
    {"name": "StrikeFowardJog", "slug": "strike-foward-jog", "loop": True, "priority": "Movement", "expected_duration": 1.3, "expected_frames": 40},
]

BASE_DIR = Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\test_output_v3")


def matrix_3x3_to_quaternion(R: List[List[float]]) -> Tuple[float, float, float, float]:
    """Convert 3x3 rotation matrix to quaternion (w, x, y, z) using Shepperd's algorithm."""
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


def matrix_det_3x3(R: List[List[float]]) -> float:
    return (
        R[0][0] * (R[1][1] * R[2][2] - R[1][2] * R[2][1])
        - R[0][1] * (R[1][0] * R[2][2] - R[1][2] * R[2][0])
        + R[0][2] * (R[1][0] * R[2][1] - R[1][1] * R[2][0])
    )


def matrix_ortho_residual(R: List[List[float]]) -> float:
    """Computes max residual ||R * R^T - I||."""
    max_err = 0.0
    for i in range(3):
        for j in range(3):
            val = sum(R[i][k] * R[j][k] for k in range(3))
            expected = 1.0 if i == j else 0.0
            err = abs(val - expected)
            if err > max_err:
                max_err = err
    return max_err


class EmpiricalChallengeRunner:
    def __init__(self):
        self.results: Dict[str, Any] = {}
        self.all_passed = True
        self.failures: List[str] = []

    def record_check(self, clip: str, check_name: str, passed: bool, details: Any):
        if clip not in self.results:
            self.results[clip] = {}
        self.results[clip][check_name] = {"passed": passed, "details": details}
        if not passed:
            self.all_passed = False
            msg = f"[FAIL] [{clip}] {check_name}: {details}"
            self.failures.append(msg)
            print(msg)
        else:
            print(f"[PASS] [{clip}] {check_name}")

    def run_all(self):
        print("================================================================================")
        print(" EMPIRICAL ADVERSARIAL CHALLENGE — M2 OUTFIELD ANIMATION BATCH (10 CLIPS)")
        print("================================================================================")

        for clip_meta in OUTFIELD_CLIPS:
            name = clip_meta["name"]
            slug = clip_meta["slug"]
            is_loop = clip_meta["loop"]
            priority = clip_meta["priority"]
            expected_dur = clip_meta["expected_duration"]
            expected_frames = clip_meta["expected_frames"]

            clip_dir = BASE_DIR / name
            print(f"\n>>> Challenging Outfield Clip: {name} ({slug}) <<<")

            if not clip_dir.is_dir():
                self.record_check(name, "directory_exists", False, f"Missing directory: {clip_dir}")
                continue
            self.record_check(name, "directory_exists", True, str(clip_dir))

            kf_path = clip_dir / f"{name}-r15-keyframes.json"
            rc_path = clip_dir / f"{name}.recipe.json"

            # -----------------------------------------------------------------
            # 1. Challenge -r15-keyframes.json
            # -----------------------------------------------------------------
            if not kf_path.is_file():
                self.record_check(name, "keyframes_exists", False, f"Missing {kf_path.name}")
                continue

            with open(kf_path, "r", encoding="utf-8") as f:
                kf_data = json.load(f)

            # Parts check
            kf_parts = kf_data.get("parts", [])
            parts_match = (kf_parts == CANONICAL_R15_PARTS)
            self.record_check(name, "kf_canonical_parts_15", parts_match, f"Parts len={len(kf_parts)}, match={parts_match}")

            # Parents check
            kf_parents = kf_data.get("parents", [])
            parents_match = (kf_parents == CANONICAL_PARENTS)
            self.record_check(name, "kf_canonical_parents", parents_match, f"Parents len={len(kf_parents)}, match={parents_match}")

            # Loop flag
            kf_loop = kf_data.get("loop")
            self.record_check(name, "kf_loop_flag", kf_loop == is_loop, f"Got {kf_loop}, expected {is_loop}")

            # Frames count
            frames = kf_data.get("frames", [])
            self.record_check(name, "kf_frame_count", len(frames) == expected_frames, f"Got {len(frames)}, expected {expected_frames}")

            # Monotonic timestamps
            kf_times = [fr.get("time") for fr in frames]
            monotonic_kf = True
            min_dt_kf = float("inf")
            for idx in range(len(kf_times) - 1):
                dt = kf_times[idx + 1] - kf_times[idx]
                if dt <= 0:
                    monotonic_kf = False
                if dt < min_dt_kf:
                    min_dt_kf = dt
            self.record_check(name, "kf_monotonic_timestamps", monotonic_kf and kf_times[0] == 0.0,
                              f"Monotonic={monotonic_kf}, t[0]={kf_times[0]}, min_dt={min_dt_kf:.6f}s, t_end={kf_times[-1]}")

            # Poses inspection: Quaternions, Orthogonality, Root vs Non-Root Translation
            max_ortho_err = 0.0
            max_det_err = 0.0
            max_quat_norm_err = 0.0
            non_root_trans_violations = 0
            has_nan_inf = False
            root_translations = []

            for f_idx, fr in enumerate(frames):
                poses = fr.get("poses", [])
                if len(poses) != 15:
                    self.record_check(name, f"frame_{f_idx}_poses_count", False, f"Expected 15 poses, got {len(poses)}")
                    break

                for p_idx, p in enumerate(poses):
                    if len(p) != 12:
                        self.record_check(name, f"frame_{f_idx}_pose_{p_idx}_len", False, f"Expected 12 floats, got {len(p)}")
                        break

                    # Check finite
                    for val in p:
                        if math.isnan(val) or math.isinf(val):
                            has_nan_inf = True

                    # Root vs Non-Root Translation
                    tx, ty, tz = p[0], p[1], p[2]
                    if p_idx == 0:
                        root_translations.append((tx, ty, tz))
                    else:
                        t_mag = math.sqrt(tx * tx + ty * ty + tz * tz)
                        if t_mag > 1e-5:
                            non_root_trans_violations += 1

                    # 3x3 Rotation matrix
                    R = [
                        [p[3], p[4], p[5]],
                        [p[6], p[7], p[8]],
                        [p[9], p[10], p[11]],
                    ]

                    # Orthogonality
                    ortho_err = matrix_ortho_residual(R)
                    if ortho_err > max_ortho_err:
                        max_ortho_err = ortho_err

                    # Determinant
                    det = matrix_det_3x3(R)
                    det_err = abs(det - 1.0)
                    if det_err > max_det_err:
                        max_det_err = det_err

                    # Quaternion reconstruction & normalization
                    q = matrix_3x3_to_quaternion(R)
                    q_norm = math.sqrt(q[0]**2 + q[1]**2 + q[2]**2 + q[3]**2)
                    q_norm_err = abs(q_norm - 1.0)
                    if q_norm_err > max_quat_norm_err:
                        max_quat_norm_err = q_norm_err

            self.record_check(name, "kf_no_nan_inf", not has_nan_inf, f"NaN/Inf found: {has_nan_inf}")
            self.record_check(name, "kf_rotation_orthogonality", max_ortho_err < 1e-4, f"Max ortho error = {max_ortho_err:.8e} (< 1e-4)")
            self.record_check(name, "kf_rotation_determinant", max_det_err < 1e-4, f"Max det error = {max_det_err:.8e} (< 1e-4)")
            self.record_check(name, "kf_quaternion_normalized", max_quat_norm_err < 1e-4, f"Max quaternion norm error = {max_quat_norm_err:.8e} (< 1e-4)")
            self.record_check(name, "kf_non_root_translation_absent", non_root_trans_violations == 0,
                              f"Non-root translation violations = {non_root_trans_violations}")

            # Verify Root Translation Present & Dynamic
            root_xs = [t[0] for t in root_translations]
            root_ys = [t[1] for t in root_translations]
            root_zs = [t[2] for t in root_translations]
            rx_range = max(root_xs) - min(root_xs)
            ry_range = max(root_ys) - min(root_ys)
            rz_range = max(root_zs) - min(root_zs)
            max_root_motion = max(rx_range, ry_range, rz_range)
            # Root motion should be non-zero (even for idle, there is subtle breathing/balance)
            self.record_check(name, "kf_root_translation_present", max_root_motion > 0.001,
                              f"Root translation range: dx={rx_range:.4f}, dy={ry_range:.4f}, dz={rz_range:.4f}, max={max_root_motion:.4f}")

            # Seam closure vs One-shot recovery check in Keyframes
            p0 = frames[0]["poses"]
            pend = frames[-1]["poses"]
            diffs = []
            for j in range(15):
                for k in range(12):
                    diffs.append(abs(p0[j][k] - pend[j][k]))
            max_pose_diff = max(diffs)
            if is_loop:
                self.record_check(name, "kf_loop_seam_closed", max_pose_diff < 1e-4,
                                  f"Max diff between frame 0 and frame N-1 = {max_pose_diff:.8e}")
            else:
                self.record_check(name, "kf_oneshot_recovery_preserved", max_pose_diff > 0.05,
                                  f"Max diff between frame 0 and frame N-1 = {max_pose_diff:.4f} (> 0.05)")

            # -----------------------------------------------------------------
            # 2. Challenge .recipe.json
            # -----------------------------------------------------------------
            if not rc_path.is_file():
                self.record_check(name, "recipe_exists", False, f"Missing {rc_path.name}")
                continue

            with open(rc_path, "r", encoding="utf-8") as f:
                rc_data = json.load(f)

            # Kind attribute
            self.record_check(name, "rc_kind_animation", rc_data.get("kind") == "animation",
                              f"Got {rc_data.get('kind')}, expected 'animation'")

            # Loop attribute
            self.record_check(name, "rc_loop_flag", rc_data.get("loop") == is_loop,
                              f"Got {rc_data.get('loop')}, expected {is_loop}")

            # Priority attribute
            self.record_check(name, "rc_priority", rc_data.get("priority") == priority,
                              f"Got {rc_data.get('priority')}, expected {priority}")

            # Tracks count and canonical names
            tracks = rc_data.get("tracks", [])
            track_joints = [t.get("joint") for t in tracks]
            self.record_check(name, "rc_tracks_count_15", len(tracks) == 15, f"Tracks count = {len(tracks)}")
            self.record_check(name, "rc_canonical_tracks_order", track_joints == CANONICAL_R15_PARTS,
                              f"Track joints match canonical R15 parts exactly: {track_joints == CANONICAL_R15_PARTS}")

            # Tracks keys inspection
            max_track_keys = 0
            rc_non_root_pos_violations = 0
            rc_non_monotonic_tracks = 0
            rc_euler_out_of_bounds = 0
            rc_has_nan_inf = False
            rc_min_euler = float("inf")
            rc_max_euler = float("-inf")

            for t_idx, track in enumerate(tracks):
                joint = track.get("joint")
                keys = track.get("keys", [])
                if len(keys) > max_track_keys:
                    max_track_keys = len(keys)

                # Check monotonic key timestamps
                t_keys_times = [k.get("time") for k in keys]
                for k_i in range(len(t_keys_times) - 1):
                    if t_keys_times[k_i + 1] <= t_keys_times[k_i]:
                        rc_non_monotonic_tracks += 1

                for k in keys:
                    pos = k.get("position", [])
                    rot = k.get("rotation", [])

                    # Non-root position zeroed
                    if joint != "LowerTorso":
                        if pos != [0.0, 0.0, 0.0] and pos != [0, 0, 0]:
                            rc_non_root_pos_violations += 1

                    # Check finite and bounds
                    for val in pos + rot:
                        if math.isnan(val) or math.isinf(val):
                            rc_has_nan_inf = True

                    for ang in rot:
                        if ang < rc_min_euler:
                            rc_min_euler = ang
                        if ang > rc_max_euler:
                            rc_max_euler = ang
                        if not (-720.0 <= ang <= 720.0):
                            rc_euler_out_of_bounds += 1

            self.record_check(name, "rc_monotonic_timestamps", rc_non_monotonic_tracks == 0,
                              f"Non-monotonic track violations = {rc_non_monotonic_tracks}")
            self.record_check(name, "rc_non_root_translation_zeroed", rc_non_root_pos_violations == 0,
                              f"Non-zero non-root position keys = {rc_non_root_pos_violations}")
            self.record_check(name, "rc_no_nan_inf", not rc_has_nan_inf, f"NaN/Inf found in recipe: {rc_has_nan_inf}")
            self.record_check(name, "rc_euler_bounds_720", rc_euler_out_of_bounds == 0,
                              f"Euler range: [{rc_min_euler:.2f}°, {rc_max_euler:.2f}°], out-of-bounds={rc_euler_out_of_bounds}")
            self.record_check(name, "rc_keys_count_within_128", max_track_keys <= 128,
                              f"Max keys per track = {max_track_keys} (<= 128)")

            # -----------------------------------------------------------------
            # 3. Special Stress-Test for StandingIdle02
            # -----------------------------------------------------------------
            if name == "StandingIdle02":
                print("\n>>> STRESS-TESTING StandingIdle02 Subsampling & Boundary Constraints <<<")
                # 157 raw frames -> exactly 128 keys in recipe
                self.record_check("StandingIdle02_Stress", "raw_keyframes_count_157", len(frames) == 157,
                                  f"Raw frames = {len(frames)} (expected 157)")
                self.record_check("StandingIdle02_Stress", "subsampled_keys_count_128", max_track_keys == 128,
                                  f"Track keys count = {max_track_keys} (strictly <= 128)")

                # Verify each of the 15 tracks has EXACTLY 128 keys
                all_tracks_128 = all(len(t.get("keys", [])) == 128 for t in tracks)
                self.record_check("StandingIdle02_Stress", "all_15_tracks_have_128_keys", all_tracks_128,
                                  f"All 15 tracks have 128 keys: {all_tracks_128}")

                # First and final key pinning
                sample_track = tracks[0]
                first_k = sample_track["keys"][0]
                final_k = sample_track["keys"][-1]
                t_first = first_k["time"]
                t_final = final_k["time"]

                self.record_check("StandingIdle02_Stress", "first_key_pinned_zero", abs(t_first - 0.0) < 1e-4,
                                  f"First key time = {t_first} (expected 0.0)")
                self.record_check("StandingIdle02_Stress", "final_key_pinned_5_2s", abs(t_final - 5.2) < 0.005,
                                  f"Final key time = {t_final} (expected 5.2s, diff={abs(t_final - 5.2):.4f}s)")

                # Verify step monotonic intervals across 128 keys
                keys_times = [k["time"] for k in sample_track["keys"]]
                intervals = [keys_times[i + 1] - keys_times[i] for i in range(len(keys_times) - 1)]
                min_interval = min(intervals)
                max_interval = max(intervals)
                avg_interval = sum(intervals) / len(intervals)
                self.record_check("StandingIdle02_Stress", "subsample_monotonic_intervals",
                                  min_interval > 0.0 and max_interval < 0.1,
                                  f"Min interval={min_interval:.4f}s, max={max_interval:.4f}s, avg={avg_interval:.4f}s")

                # Verify LowerTorso preserves subtle balance bounce
                lt_track = next(t for t in tracks if t["joint"] == "LowerTorso")
                lt_positions = [k["position"] for k in lt_track["keys"]]
                lt_z = [p[2] for p in lt_positions]
                lt_y = [p[1] for p in lt_positions]
                lt_z_range = max(lt_z) - min(lt_z)
                lt_y_range = max(lt_y) - min(lt_y)
                self.record_check("StandingIdle02_Stress", "root_motion_subtle_dynamics",
                                  max(lt_z_range, lt_y_range) > 0.001,
                                  f"LowerTorso motion range: dy={lt_y_range:.4f}, dz={lt_z_range:.4f}")

        print("\n================================================================================")
        print(" EMPIRICAL ADVERSARIAL CHALLENGE SUMMARY")
        print("================================================================================")
        print(f"Overall Status: {'ALL PASSED' if self.all_passed else 'FAILURES DETECTED'}")
        print(f"Total Failures: {len(self.failures)}")
        for f in self.failures:
            print(f" - {f}")
        print("================================================================================")

        # Write output json report
        output_report = BASE_DIR / "challenger_m2_empirical_report.json"
        with open(output_report, "w", encoding="utf-8") as f:
            json.dump({
                "all_passed": self.all_passed,
                "total_failures": len(self.failures),
                "failures": self.failures,
                "results": self.results
            }, f, indent=2)
        print(f"Detailed challenge report written to: {output_report}")
        return self.all_passed


if __name__ == "__main__":
    runner = EmpiricalChallengeRunner()
    success = runner.run_all()
    sys.exit(0 if success else 1)
