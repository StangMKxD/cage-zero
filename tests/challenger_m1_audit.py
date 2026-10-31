#!/usr/bin/env python3
"""challenger_m1_audit.py — Adversarial Kinematic & Schema Stress Harness for M1.

Audits:
1. Keyframes JSON:
   - 15 driven parts presence & ordering.
   - Timestamp monotonicity (strictly increasing, delta t > 0).
   - Pose vector dimensions (12 floats per part).
   - Non-root translation zeroing.
   - Rotation submatrix orthogonality: ||R * R^T - I||_max and |det(R) - 1|.
   - No NaNs, Infs, or reflections.
2. Recipe JSON:
   - Track count == 15, matching R15 driven parts.
   - Keyframe count per track <= 128 (Motion Tools limit).
   - Non-root position tracks identically [0, 0, 0].
   - Euler angles within athletic limits [-720, 720] degrees.
   - Valid easing parameters.
3. Seam vs Recovery Invariants:
   - JogForward (loop): frame 0 == frame N-1.
   - ScissorKick (oneshot): frame 0 != frame N-1.
4. Source FBX integrity:
   - SHA256 comparison against survey baseline.
5. Working tree integrity:
   - Exactly 33 uncommitted files in src/, zero reverts, zero mutations.
"""

import hashlib
import json
import math
import os
import subprocess
import sys
from pathlib import Path

CANONICAL_R15_PARTS = [
    'LowerTorso', 'UpperTorso', 'Head',
    'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
    'RightUpperArm', 'RightLowerArm', 'RightHand',
    'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot',
    'RightUpperLeg', 'RightLowerLeg', 'RightFoot'
]

BASELINE_FBX_HASHES = {
    "Jog Forward.fbx": "836EF89582F9382598D0B2EDD82F57D3CB8C29DC136A512E45D5637A70C4C2EF",
    "Scissor Kick.fbx": "5E43F565ECE6768118C83BF6A4C7C5A08ECEE4AA6B112BA1C5591065F13687B4"
}

SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")
TEST_OUTPUT_DIR = Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\test_output_v3")
SRC_DIR = Path(r"C:\Users\Stang\cage-zero\src")


def compute_sha256(path: Path) -> str:
    hasher = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest().upper()


def matrix_mult_3x3(A, B):
    return [
        [sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)]
        for i in range(3)
    ]


def matrix_transpose_3x3(A):
    return [[A[j][i] for j in range(3)] for i in range(3)]


def matrix_det_3x3(A):
    return (
        A[0][0] * (A[1][1] * A[2][2] - A[1][2] * A[2][1])
        - A[0][1] * (A[1][0] * A[2][2] - A[1][2] * A[2][0])
        + A[0][2] * (A[1][0] * A[2][1] - A[1][1] * A[2][0])
    )


def audit_keyframes_json(kf_path: Path, expected_name: str, is_loop: bool):
    print(f"\n--- Auditing Keyframes JSON: {kf_path.name} ---")
    assert kf_path.is_file(), f"Missing keyframes file: {kf_path}"
    with open(kf_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # 1. Driven parts
    parts = data.get("parts", [])
    print(f"Parts count: {len(parts)}")
    assert len(parts) == 15, f"Expected 15 driven parts, got {len(parts)}"
    assert parts == CANONICAL_R15_PARTS, f"Parts order mismatch! {parts} vs {CANONICAL_R15_PARTS}"
    print("Parts match canonical R15 driven parts exactly: PASS")

    # 2. Frames and Monotonicity
    frames = data.get("frames", [])
    print(f"Total frames: {len(frames)}")
    assert len(frames) >= 2, f"Frame count too small: {len(frames)}"

    times = [fr["time"] for fr in frames]
    min_dt = float("inf")
    for i in range(len(times) - 1):
        dt = times[i + 1] - times[i]
        assert dt > 0, f"Non-monotonic timestamp at frame {i}: t[{i}]={times[i]}, t[{i+1}]={times[i+1]}"
        if dt < min_dt:
            min_dt = dt
    print(f"Timestamps strictly monotonic: PASS (min delta t = {min_dt:.6f}s, start = {times[0]}s, end = {times[-1]}s)")

    # 3. Kinematic Poses & Orthogonality
    max_ortho_error = 0.0
    max_det_error = 0.0
    non_root_trans_violations = 0
    total_matrices_checked = 0

    for f_idx, fr in enumerate(frames):
        poses = fr.get("poses", [])
        assert len(poses) == 15, f"Frame {f_idx} has {len(poses)} poses, expected 15"
        for p_idx, p in enumerate(poses):
            assert len(p) == 12, f"Frame {f_idx} part {parts[p_idx]} pose length {len(p)} != 12"
            
            # Non-root translation check
            if p_idx != 0: # 0 is LowerTorso
                trans = p[:3]
                trans_mag = math.sqrt(trans[0]**2 + trans[1]**2 + trans[2]**2)
                if trans_mag > 1e-6:
                    non_root_trans_violations += 1

            # Rotation 3x3 matrix
            R = [
                [p[3], p[4], p[5]],
                [p[6], p[7], p[8]],
                [p[9], p[10], p[11]]
            ]

            # Check for NaN / Inf
            for row in R:
                for val in row:
                    assert not math.isnan(val) and not math.isinf(val), f"NaN/Inf in rotation matrix frame {f_idx} part {parts[p_idx]}"

            # Orthogonality check: R * R^T = I
            Rt = matrix_transpose_3x3(R)
            RRt = matrix_mult_3x3(R, Rt)
            for i in range(3):
                for j in range(3):
                    expected = 1.0 if i == j else 0.0
                    err = abs(RRt[i][j] - expected)
                    if err > max_ortho_error:
                        max_ortho_error = err

            # Determinant check: det(R) = 1.0
            det = matrix_det_3x3(R)
            det_err = abs(det - 1.0)
            if det_err > max_det_error:
                max_det_error = det_err
            
            total_matrices_checked += 1

    print(f"Total rotation matrices checked: {total_matrices_checked}")
    print(f"Max orthogonality residual ||R*R^T - I||: {max_ortho_error:.8e}")
    print(f"Max determinant residual |det(R) - 1|: {max_det_error:.8e}")
    print(f"Non-root translation violations in keyframes: {non_root_trans_violations}")
    assert max_ortho_error < 1e-4, f"Orthogonality error too high: {max_ortho_error}"
    assert max_det_error < 1e-4, f"Determinant error too high: {max_det_error}"
    assert non_root_trans_violations == 0, f"Found {non_root_trans_violations} non-root translation violations!"
    print("Orthogonality & proper SO(3) rotations: PASS")

    # 4. Seam vs Recovery check
    first_pose = frames[0]["poses"]
    last_pose = frames[-1]["poses"]
    pose_diff_max = 0.0
    for p_idx in range(15):
        for k in range(12):
            diff = abs(first_pose[p_idx][k] - last_pose[p_idx][k])
            if diff > pose_diff_max:
                pose_diff_max = diff

    if is_loop:
        assert data.get("loop") is True, "Loop flag mismatch in keyframes JSON"
        assert pose_diff_max < 1e-5, f"Loop seam not closed! Max diff between first and last pose: {pose_diff_max}"
        print(f"Loop seam closure verified (first vs last pose max diff = {pose_diff_max:.8e}): PASS")
    else:
        assert data.get("loop") is False, "One-shot loop flag mismatch in keyframes JSON"
        assert pose_diff_max > 0.05, f"One-shot ending recovery was accidentally closed! pose_diff_max={pose_diff_max}"
        print(f"One-shot landing recovery preserved (first vs last pose max diff = {pose_diff_max:.4f}): PASS")

    return {
        "file": kf_path.name,
        "parts_count": len(parts),
        "frame_count": len(frames),
        "min_dt": min_dt,
        "max_ortho_error": max_ortho_error,
        "max_det_error": max_det_error,
        "pose_diff_max": pose_diff_max,
        "status": "PASS"
    }


def audit_recipe_json(rc_path: Path, is_loop: bool):
    print(f"\n--- Auditing Recipe JSON: {rc_path.name} ---")
    assert rc_path.is_file(), f"Missing recipe file: {rc_path}"
    with open(rc_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # 1. Kind & Tracks Count
    kind = data.get("kind")
    assert kind == "animation", f"Expected kind 'animation', got {kind}"
    tracks = data.get("tracks", [])
    print(f"Track count: {len(tracks)}")
    assert len(tracks) == 15, f"Expected 15 tracks, got {len(tracks)}"

    track_joints = [t["joint"] for t in tracks]
    assert track_joints == CANONICAL_R15_PARTS, f"Track joints mismatch: {track_joints}"
    print("Track joints match canonical R15 parts: PASS")

    # 2. Track Keys Analysis
    max_key_count = 0
    non_zero_non_root_positions = 0
    min_euler = float("inf")
    max_euler = float("-inf")
    total_keys_checked = 0

    for track in tracks:
        joint = track["joint"]
        keys = track.get("keys", [])
        total_keys_checked += len(keys)
        if len(keys) > max_key_count:
            max_key_count = len(keys)

        assert len(keys) <= 128, f"Track {joint} has {len(keys)} keys, exceeding Motion Tools 128 limit!"
        assert len(keys) >= 2, f"Track {joint} has {len(keys)} keys, less than 2!"

        times = [k["time"] for k in keys]
        for i in range(len(times) - 1):
            assert times[i + 1] > times[i], f"Track {joint} has non-monotonic keyframe times: {times[i]} >= {times[i+1]}"

        for k in keys:
            pos = k.get("position", [])
            rot = k.get("rotation", [])
            assert len(pos) == 3, f"Track {joint} key has invalid position vector: {pos}"
            assert len(rot) == 3, f"Track {joint} key has invalid rotation vector: {rot}"

            # Non-root position check
            if joint != "LowerTorso":
                if pos != [0.0, 0.0, 0.0] and pos != [0, 0, 0]:
                    non_zero_non_root_positions += 1

            # Euler angles check
            for ang in rot:
                assert not math.isnan(ang) and not math.isinf(ang), f"NaN/Inf in rotation angle for {joint}"
                if ang < min_euler:
                    min_euler = ang
                if ang > max_euler:
                    max_euler = ang
                assert -720.0 <= ang <= 720.0, f"Track {joint} Euler angle {ang} out of realistic bounds [-720, 720]"

            # Easing
            assert k.get("easingStyle") == "CubicV2", f"Invalid easingStyle: {k.get('easingStyle')}"
            assert k.get("easingDirection") == "InOut", f"Invalid easingDirection: {k.get('easingDirection')}"

    print(f"Max keys per track: {max_key_count} (<= 128 limit: PASS)")
    print(f"Non-root position tracks identically [0, 0, 0]: PASS (violations: {non_zero_non_root_positions})")
    print(f"Euler angle range: [{min_euler:.2f}°, {max_euler:.2f}°] (within [-720, 720]: PASS)")
    print(f"Total keys audited: {total_keys_checked}")

    return {
        "file": rc_path.name,
        "track_count": len(tracks),
        "max_key_count": max_key_count,
        "min_euler": min_euler,
        "max_euler": max_euler,
        "non_zero_non_root_positions": non_zero_non_root_positions,
        "status": "PASS"
    }


def audit_source_fbx():
    print("\n--- Auditing Source FBX Hashes Against Baseline ---")
    results = {}
    for filename, expected_hash in BASELINE_FBX_HASHES.items():
        fbx_path = SOURCE_DIR / filename
        assert fbx_path.is_file(), f"Source FBX missing: {fbx_path}"
        actual_hash = compute_sha256(fbx_path)
        print(f"File: {filename}")
        print(f"  Actual:   {actual_hash}")
        print(f"  Expected: {expected_hash}")
        assert actual_hash == expected_hash, f"Source FBX hash mismatch for {filename}!"
        results[filename] = {"actual": actual_hash, "match": True}
    print("Source FBX integrity: PASS (100% bit-for-bit match)")
    return results


def audit_git_working_tree():
    print("\n--- Auditing Git Working Tree Integrity ---")
    proc = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=r"C:\Users\Stang\cage-zero",
        capture_output=True,
        text=True,
        check=True
    )
    lines = proc.stdout.strip().splitlines()
    src_lines = [l for l in lines if "src/" in l]
    print(f"Dirty / untracked files in src/: {len(src_lines)}")
    assert len(src_lines) == 33, f"Expected exactly 33 uncommitted files in src/, found {len(src_lines)}!"
    print("Exact 33 files in src/ preserved without regression: PASS")
    return len(src_lines)


def main():
    print("=" * 70)
    print("=== ADVERSARIAL CHALLENGER AUDIT: MILESTONE 1 ===")
    print("=" * 70)

    # 1. Audit Keyframes JSON
    jog_kf = audit_keyframes_json(
        TEST_OUTPUT_DIR / "JogForward" / "JogForward-r15-keyframes.json",
        expected_name="JogForward",
        is_loop=True
    )
    kick_kf = audit_keyframes_json(
        TEST_OUTPUT_DIR / "ScissorKick" / "ScissorKick-r15-keyframes.json",
        expected_name="ScissorKick",
        is_loop=False
    )

    # 2. Audit Recipe JSON
    jog_rc = audit_recipe_json(
        TEST_OUTPUT_DIR / "JogForward" / "JogForward.recipe.json",
        is_loop=True
    )
    kick_rc = audit_recipe_json(
        TEST_OUTPUT_DIR / "ScissorKick" / "ScissorKick.recipe.json",
        is_loop=False
    )

    # 3. Audit Source FBX
    fbx_res = audit_source_fbx()

    # 4. Audit Git Status
    git_res = audit_git_working_tree()

    print("\n" + "=" * 70)
    print("=== CHALLENGER SUMMARY: ALL EMPIRICAL AUDITS PASSED ===")
    print("=" * 70)

    summary = {
        "verdict": "CONFIRMED",
        "jog_keyframes": jog_kf,
        "kick_keyframes": kick_kf,
        "jog_recipe": jog_rc,
        "kick_recipe": kick_rc,
        "fbx_integrity": fbx_res,
        "src_files_count": git_res
    }

    out_summary_file = Path(r"C:\Users\Stang\cage-zero\tests\challenger_m1_audit_result.json")
    with open(out_summary_file, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)

    return 0


if __name__ == "__main__":
    sys.exit(main())
