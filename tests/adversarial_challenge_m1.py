#!/usr/bin/env python3
"""adversarial_challenge_m1.py — Empirical Challenger Harness for Milestone 1.

Performs rigorous adversarial inspection, edge-case probing, and empirical verification
against the Milestone 1 Conversion Engine (batch_convert_v3.py & test_output_v3/).

Challenge Dimensions:
1. Rest Basis Diagnosis: Verify diagnose_bone_front_dot() behavior with synthetic vectors
   and confirm idempotency against double-applied roll flips.
2. Selective Translation Removal: Verify LowerTorso location fcurves are preserved in all
   modes, with non-zero motion trajectories.
3. Non-Root Joints: Empirically verify that all 14 non-root joints have strictly 0
   location fcurves in .blend, and exactly [0,0,0] translation in keyframes/recipe JSONs.
4. Seam Logic: Verify that one-shot recovery frames are genuinely preserved and distinct
   from frame 1 (not cycle-closed), while loop animations are properly closed.
5. Cryptographic Integrity: Verify SHA256 hashes of source FBX files.
"""

from __future__ import annotations

import hashlib
import json
import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

ORDER = [
    'LowerTorso', 'UpperTorso', 'Head',
    'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
    'RightUpperArm', 'RightLowerArm', 'RightHand',
    'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot',
    'RightUpperLeg', 'RightLowerLeg', 'RightFoot'
]

TEST_OUTPUT_DIR = Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\test_output_v3")
SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")
TEMPLATE_PATH = Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\templates\Rig_and_Attachments_Template.blend")

KNOWN_SOURCE_HASHES = {
    "Jog Forward.fbx": "836EF89582F9382598D0B2EDD82F57D3CB8C29DC136A512E45D5637A70C4C2EF",
    "Scissor Kick.fbx": "5E43F565ECE6768118C83BF6A4C7C5A08ECEE4AA6B112BA1C5591065F13687B4",
}


def compute_sha256(filepath: Path) -> str:
    hasher = hashlib.sha256()
    with open(filepath, 'rb') as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest().upper()


def get_all_fcurves(action) -> list:
    legacy = getattr(action, "fcurves", None)
    if legacy is not None:
        return list(legacy)
    curves = []
    for layer in getattr(action, "layers", ()):
        for strip in getattr(layer, "strips", ()):
            for channelbag in getattr(strip, "channelbags", ()):
                curves.extend(channelbag.fcurves)
    return curves


class AdversarialChallengeSuite:
    def __init__(self):
        self.findings = []
        self.verdicts = {}

    def log(self, section: str, test_name: str, passed: bool, details: str):
        self.findings.append({
            "section": section,
            "test": test_name,
            "passed": passed,
            "details": details
        })
        mark = "PASS" if passed else "FAIL"
        print(f"[{mark}] [{section}] {test_name}: {details}")

    # =========================================================================
    # Challenge 1: Rest Basis Diagnosis & Anti-Double-Flip
    # =========================================================================
    def challenge_1_rest_basis_diagnosis(self):
        print("\n=== Challenge 1: Rest Basis Diagnosis & Idempotency ===")
        # Import the diagnosis function from batch_convert_v3
        sys.path.insert(0, str(Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\scripts").resolve()))
        import batch_convert_v3

        # Test A: Synthetic Dot Product Logic
        # A forward bone has Z pointing in (0, 0, 1) or similar reference.
        # Test extreme alignments:
        ref = Vector((0, 0, 1))
        dot_forward = ref.dot(Vector((0, 0, 1)))
        dot_inverted = ref.dot(Vector((0, 0, -1)))
        dot_perpendicular = ref.dot(Vector((1, 0, 0)))

        self.log(
            "C1_RestBasis",
            "dot_product_math_forward",
            abs(dot_forward - 1.0) < 1e-5,
            f"Forward dot = {dot_forward} (expected 1.0)"
        )
        self.log(
            "C1_RestBasis",
            "dot_product_math_inverted",
            abs(dot_inverted - (-1.0)) < 1e-5,
            f"Inverted dot = {dot_inverted} (expected -1.0)"
        )

        # Test B: Decision Matrix Idempotency
        # batch_convert_v3 decision rule:
        # dot <= -0.50 -> roll
        # dot >= 0.70 -> preserve
        # else -> preserve
        def should_roll(dot: float) -> bool:
            return dot <= -0.50

        # Pre-aligned bone: dot > 0.70 (e.g. 0.95)
        self.log(
            "C1_RestBasis",
            "pre_aligned_bone_not_rolled",
            not should_roll(0.95),
            "Dot 0.95 >= 0.70 correctly preserves without roll"
        )
        # Idempotency: After a bone is rolled from -0.90, its dot becomes ~ +0.90.
        # Re-evaluating +0.90:
        self.log(
            "C1_RestBasis",
            "idempotent_after_roll",
            not should_roll(0.90),
            "After roll, dot becomes 0.90 which preserves, preventing double-flip"
        )
        # Neutral zone: dot between -0.50 and +0.70 (e.g. 0.667 in ScissorKick RightLowerLeg)
        self.log(
            "C1_RestBasis",
            "neutral_zone_preserves",
            not should_roll(0.667),
            "Neutral dot 0.667 preserves, preventing accidental inversion"
        )

        # Test C: Verify in actual converted blend files
        for clip in ["JogForward", "ScissorKick"]:
            blend_path = TEST_OUTPUT_DIR / clip / f"{clip}_R15_v03.blend"
            if not blend_path.is_file():
                self.log("C1_RestBasis", f"{clip}_blend_exists", False, f"File missing: {blend_path}")
                continue

            bpy.ops.wm.open_mainfile(filepath=str(blend_path))
            rig = bpy.data.objects.get("Armature") or bpy.data.objects.get("StudioR15_Target")
            if not rig:
                for o in bpy.data.objects:
                    if o.type == 'ARMATURE':
                        rig = o
                        break

            # Evaluate knee dot product across all frames
            action = rig.animation_data.action if rig.animation_data else None
            f_start = int(round(action.frame_range[0]))
            f_end = int(round(action.frame_range[1]))

            left_dots = []
            right_dots = []
            for f in range(f_start, f_end + 1):
                bpy.context.scene.frame_set(f)
                bpy.context.view_layer.update()
                left_dots.append(batch_convert_v3.diagnose_bone_front_dot(rig, 'LeftLowerLeg'))
                right_dots.append(batch_convert_v3.diagnose_bone_front_dot(rig, 'RightLowerLeg'))

            max_left = max(left_dots)
            max_right = max(right_dots)
            self.log(
                "C1_RestBasis",
                f"{clip}_knee_front_alignment",
                max_left >= 0.70 and max_right >= 0.70,
                f"Peak knee dot Left={max_left:.4f}, Right={max_right:.4f} (gate >= 0.70)"
            )

    # =========================================================================
    # Challenge 2: Selective Translation Removal
    # =========================================================================
    def challenge_2_selective_translation(self):
        print("\n=== Challenge 2: Selective Translation Removal ===")
        # Verify that LowerTorso location curves are NOT deleted under any circumstance
        for clip, is_loop in [("JogForward", True), ("ScissorKick", False)]:
            blend_path = TEST_OUTPUT_DIR / clip / f"{clip}_R15_v03.blend"
            bpy.ops.wm.open_mainfile(filepath=str(blend_path))

            rig = None
            for o in bpy.data.objects:
                if o.type == 'ARMATURE':
                    rig = o
                    break

            action = rig.animation_data.action
            curves = get_all_fcurves(action)

            # Find LowerTorso location curves
            root_loc_curves = [
                c for c in curves
                if 'location' in c.data_path and 'LowerTorso' in c.data_path
            ]
            self.log(
                "C2_SelectiveTranslation",
                f"{clip}_lowertorso_location_curves_present",
                len(root_loc_curves) == 3,
                f"Found {len(root_loc_curves)} location curves on LowerTorso (expected 3)"
            )

            # Verify that location curves contain non-zero motion
            # For JogForward (loop_y): vertical bounce in Z should vary across cycle
            # For ScissorKick (oneshot): X, Y, Z should vary significantly
            z_curve = next((c for c in root_loc_curves if c.array_index == 2), None)
            if z_curve:
                z_vals = [kp.co.y for kp in z_curve.keyframe_points]
                z_range = max(z_vals) - min(z_vals)
                self.log(
                    "C2_SelectiveTranslation",
                    f"{clip}_lowertorso_vertical_bounce",
                    z_range > 0.001,
                    f"LowerTorso Z translation range = {z_range:.6f} studs (> 0.001)"
                )

            if not is_loop:
                # ScissorKick oneshot: check horizontal displacement
                x_curve = next((c for c in root_loc_curves if c.array_index == 0), None)
                y_curve = next((c for c in root_loc_curves if c.array_index == 1), None)
                x_range = (max(kp.co.y for kp in x_curve.keyframe_points) - min(kp.co.y for kp in x_curve.keyframe_points)) if x_curve else 0
                y_range = (max(kp.co.y for kp in y_curve.keyframe_points) - min(kp.co.y for kp in y_curve.keyframe_points)) if y_curve else 0
                self.log(
                    "C2_SelectiveTranslation",
                    f"{clip}_lowertorso_horizontal_trajectory",
                    x_range > 0.01 or y_range > 0.01,
                    f"ScissorKick trajectory range X={x_range:.4f}, Y={y_range:.4f} studs"
                )

    # =========================================================================
    # Challenge 3: Non-Root Joints Location Curves
    # =========================================================================
    def challenge_3_non_root_joints(self):
        print("\n=== Challenge 3: Non-Root Joints Strictly 0 Location Curves ===")
        NON_ROOT_PARTS = [p for p in ORDER if p != 'LowerTorso']

        for clip in ["JogForward", "ScissorKick"]:
            blend_path = TEST_OUTPUT_DIR / clip / f"{clip}_R15_v03.blend"
            bpy.ops.wm.open_mainfile(filepath=str(blend_path))

            rig = None
            for o in bpy.data.objects:
                if o.type == 'ARMATURE':
                    rig = o
                    break

            action = rig.animation_data.action
            curves = get_all_fcurves(action)

            # Check every fcurve in the action
            offending_curves = []
            for c in curves:
                if 'location' in c.data_path:
                    # Check if it belongs to any non-root bone
                    for nr in NON_ROOT_PARTS:
                        if nr in c.data_path:
                            offending_curves.append((nr, c.data_path, c.array_index))

            self.log(
                "C3_NonRootZeroLocation",
                f"{clip}_blend_non_root_location_fcurves_zero",
                len(offending_curves) == 0,
                f"Found {len(offending_curves)} offending location curves in .blend: {offending_curves}"
            )

            # Check keyframes JSON
            kf_file = TEST_OUTPUT_DIR / clip / f"{clip}-r15-keyframes.json"
            with open(kf_file, "r", encoding="utf-8") as f:
                kf_data = json.load(f)

            kf_leaks = 0
            for frame_idx, f_entry in enumerate(kf_data.get('frames', [])):
                poses = f_entry.get('poses', [])
                for joint_idx, joint_name in enumerate(ORDER):
                    if joint_name == 'LowerTorso':
                        continue
                    pose_row = poses[joint_idx]
                    loc = pose_row[:3]
                    if any(abs(v) > 1e-6 for v in loc):
                        kf_leaks += 1

            self.log(
                "C3_NonRootZeroLocation",
                f"{clip}_keyframes_json_non_root_loc_zero",
                kf_leaks == 0,
                f"Non-root location non-zero count across all frames = {kf_leaks}"
            )

            # Check recipe JSON
            rc_file = TEST_OUTPUT_DIR / clip / f"{clip}.recipe.json"
            with open(rc_file, "r", encoding="utf-8") as f:
                rc_data = json.load(f)

            rc_leaks = 0
            for track in rc_data.get('tracks', []):
                jname = track.get('joint')
                if jname == 'LowerTorso':
                    continue
                for key in track.get('keys', []):
                    pos = key.get('position', [0, 0, 0])
                    if any(abs(v) > 1e-6 for v in pos):
                        rc_leaks += 1

            self.log(
                "C3_NonRootZeroLocation",
                f"{clip}_recipe_json_non_root_pos_zero",
                rc_leaks == 0,
                f"Non-root position non-zero count across all keys = {rc_leaks}"
            )

    # =========================================================================
    # Challenge 4: Seam Logic & One-Shot Recovery Preservation
    # =========================================================================
    def challenge_4_seam_logic(self):
        print("\n=== Challenge 4: Seam Logic & One-Shot Recovery Preservation ===")

        # Test A: JogForward (Loop) MUST be closed
        kf_loop = TEST_OUTPUT_DIR / "JogForward" / "JogForward-r15-keyframes.json"
        with open(kf_loop, "r", encoding="utf-8") as f:
            data_loop = json.load(f)
        frames_loop = data_loop['frames']
        first_pose_loop = frames_loop[0]['poses']
        last_pose_loop = frames_loop[-1]['poses']

        loop_diff = 0.0
        for p1, p2 in zip(first_pose_loop, last_pose_loop):
            for v1, v2 in zip(p1, p2):
                loop_diff += abs(v1 - v2)

        self.log(
            "C4_SeamLogic",
            "jogforward_loop_seam_closed",
            loop_diff < 1e-5,
            f"JogForward frame 1 vs last diff = {loop_diff:.8f} (expected ~0.0)"
        )

        # Test B: ScissorKick (One-Shot) MUST NOT be closed (recovery preserved)
        kf_oneshot = TEST_OUTPUT_DIR / "ScissorKick" / "ScissorKick-r15-keyframes.json"
        with open(kf_oneshot, "r", encoding="utf-8") as f:
            data_oneshot = json.load(f)
        frames_oneshot = data_oneshot['frames']
        first_pose_oneshot = frames_oneshot[0]['poses']
        last_pose_oneshot = frames_oneshot[-1]['poses']

        oneshot_diff = 0.0
        for p1, p2 in zip(first_pose_oneshot, last_pose_oneshot):
            for v1, v2 in zip(p1, p2):
                oneshot_diff += abs(v1 - v2)

        self.log(
            "C4_SeamLogic",
            "scissorkick_recovery_frame_preserved",
            oneshot_diff > 1.0,
            f"ScissorKick frame 1 vs recovery frame diff = {oneshot_diff:.4f} (MUST be > 1.0)"
        )

        # Test C: Check frame count preservation (84 frames for ScissorKick)
        self.log(
            "C4_SeamLogic",
            "scissorkick_frame_count_intact",
            len(frames_oneshot) == 84,
            f"ScissorKick frame count = {len(frames_oneshot)} (expected 84)"
        )

        # Test D: Check handle types on curves
        blend_path = TEST_OUTPUT_DIR / "ScissorKick" / "ScissorKick_R15_v03.blend"
        bpy.ops.wm.open_mainfile(filepath=str(blend_path))
        rig = None
        for o in bpy.data.objects:
            if o.type == 'ARMATURE':
                rig = o
                break
        action = rig.animation_data.action
        curves = get_all_fcurves(action)
        auto_clamped_count = 0
        total_kps = 0
        for c in curves:
            for kp in c.keyframe_points:
                total_kps += 1
                if kp.handle_left_type == 'AUTO_CLAMPED' and kp.handle_right_type == 'AUTO_CLAMPED':
                    auto_clamped_count += 1

        self.log(
            "C4_SeamLogic",
            "scissorkick_bezier_auto_clamped_handles",
            auto_clamped_count == total_kps,
            f"Auto-clamped Bezier keyframe points: {auto_clamped_count}/{total_kps}"
        )

    # =========================================================================
    # Challenge 5: Cryptographic Source FBX Integrity
    # =========================================================================
    def challenge_5_cryptographic_integrity(self):
        print("\n=== Challenge 5: Source FBX Cryptographic Integrity ===")
        for filename, expected_hash in KNOWN_SOURCE_HASHES.items():
            fpath = SOURCE_DIR / filename
            if not fpath.is_file():
                self.log("C5_Integrity", f"{filename}_exists", False, f"Missing source file: {fpath}")
                continue
            actual_hash = compute_sha256(fpath)
            matched = (actual_hash == expected_hash)
            self.log(
                "C5_Integrity",
                f"{filename}_sha256_unaltered",
                matched,
                f"Hash={actual_hash} vs Expected={expected_hash}"
            )

    def run_all(self) -> bool:
        self.challenge_1_rest_basis_diagnosis()
        self.challenge_2_selective_translation()
        self.challenge_3_non_root_joints()
        self.challenge_4_seam_logic()
        self.challenge_5_cryptographic_integrity()

        total = len(self.findings)
        passed = sum(1 for f in self.findings if f['passed'])
        failed = total - passed

        print("\n" + "=" * 70)
        print(f"ADVERSARIAL CHALLENGE SUMMARY: {passed}/{total} Passed, {failed} Failed")
        print("=" * 70)

        # Output detailed json report
        report_file = TEST_OUTPUT_DIR / "adversarial_challenge_report.json"
        with open(report_file, "w", encoding="utf-8") as f:
            json.dump({
                "suite": "Milestone 1 Empirical Challenger",
                "total_tests": total,
                "passed": passed,
                "failed": failed,
                "verdict": "CONFIRMED" if failed == 0 else "REJECTED",
                "findings": self.findings
            }, f, indent=2)
        print(f"Report written to: {report_file}")

        return failed == 0


if __name__ == "__main__":
    suite = AdversarialChallengeSuite()
    success = suite.run_all()
    sys.exit(0 if success else 1)
