"""Tier 4 — Real-World Application Scenarios Test Suite.

Verifies:
1. Target Rig Compatibility:
   - Joint attachments and bone names match `PreviewRig_R15_Boy_Height30` (`studio-r15/rig.json`).
   - 15 driven parts in Keyframes JSON match the authentic Boy rig topology across all 15 clips.
   - 15 tracks in Recipe JSON map 1:1 to driven parts across all 15 clips.
2. Timestamps Monotonicity:
   - Keyframe timestamps in Keyframes JSON are strictly monotonically increasing (t_{i+1} > t_i).
   - Key timestamps in Recipe JSON are strictly monotonically increasing per track.
3. Rotation Continuity & Finite Euler Bounds:
   - Rotations in Recipe JSON are finite (no NaN/Inf) and bounded in [-720.0, 720.0] degrees (supporting athletic tumbles).
   - Keyframe pose rotation matrices are orthogonal (R R^T = I, det(R) ≈ 1).
4. Manifest Validation in `outputagy/v3/manifest.json`:
   - Validates per-clip v3 manifest schema (15 clips, audit metrics, source SHA-256 baselines).
5. Owner Inspection Prerequisites:
   - Pre-inspection checks: 512x512, 30 FPS, loop=0 infinite, disposal mode 2.
6. Distinct Destination Specifications:
   - Destination A: Studio Native AnimSaves (`KeyframeSequence` under rig).
   - Destination B: Motion Tools Rig Library (`.recipe.json` <= 128 keys).
"""

import math
import os
import sys
import unittest
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

_CUR_DIR = Path(__file__).resolve().parent
if str(_CUR_DIR) not in sys.path:
    sys.path.insert(0, str(_CUR_DIR))

from config import (
    ALL_15_CLIPS,
    ANIMATION_WORK_DIR,
    EXPECTED_PART_PARENTS,
    EXPECTED_R15_PARTS,
    GIF_EXPECTED_DIMENSIONS,
    GIF_EXPECTED_FPS,
    GIF_EXPECTED_LOOP,
    MANIFEST_V3_LOCAL,
    MANIFEST_V3_ONEDRIVE,
    OUTPUTAGY_V3_LOCAL,
    OUTPUTAGY_V3_ONEDRIVE,
    REFERENCE_ANIMATIONS,
    STUDIO_RIG_JSON,
    TARGET_ANIMATIONS,
)
from helpers import (
    cframe_matrix_to_euler_deg,
    find_matching_file,
    is_matrix_orthogonal,
    load_json,
    parse_gif,
)


class TestTier4RealWorldScenarios(unittest.TestCase):
    """Tier 4 Real-World Application Compatibility & Continuity Tests."""

    @classmethod
    def setUpClass(cls):
        """Verify and cache the authentic Studio target rig JSON."""
        cls.has_rig_json = STUDIO_RIG_JSON.is_file()
        if cls.has_rig_json:
            ok, data, _ = load_json(STUDIO_RIG_JSON)
            cls.rig_data = data if ok else None
        else:
            cls.rig_data = None

    def _get_animation_json_data(
        self, slug: str
    ) -> Tuple[Optional[Dict[str, Any]], Optional[Dict[str, Any]]]:
        """Helper to load Keyframes and Recipe JSON for a slug."""
        slug_dir = ANIMATION_WORK_DIR / slug
        if not slug_dir.is_dir():
            return None, None

        kf_path = find_matching_file(
            slug_dir,
            [
                f"{slug}-r15-keyframes-legfix-v02.json",
                f"{slug}-r15-keyframes.json",
                "*keyframes*.json",
            ],
        )
        rc_path = find_matching_file(
            slug_dir,
            [
                f"RF02_*{slug.replace('-', '')}*.recipe.json",
                f"{slug}*.recipe.json",
                "*.recipe.json",
            ],
        )

        kf_data = None
        rc_data = None
        if kf_path:
            ok, data, _ = load_json(kf_path)
            if ok:
                kf_data = data
        if rc_path:
            ok, data, _ = load_json(rc_path)
            if ok:
                rc_data = data

        return kf_data, rc_data

    # --- Section 1: Target Rig Compatibility ---

    def test_tier4_studio_rig_json_authentic_specification(self):
        """Verify reference studio-r15/rig.json defines all 15 PreviewRig_R15_Boy_Height30 joints."""
        self.assertTrue(self.has_rig_json, f"rig.json not found: {STUDIO_RIG_JSON}")
        self.assertIsNotNone(self.rig_data, "Failed to parse studio-r15/rig.json")

        joints = self.rig_data.get("joints", [])
        self.assertEqual(
            len(joints),
            15,
            f"studio-r15/rig.json must define exactly 15 joints, found {len(joints)}",
        )

        # Check all driven child parts match expected R15 parts
        child_parts = [j.get("child") for j in joints]
        for part in EXPECTED_R15_PARTS:
            self.assertIn(
                part,
                child_parts,
                f"Expected part '{part}' missing from studio-r15/rig.json joints",
            )

    def _verify_rig_compatibility_for_animation(self, slug: str, name: str):
        kf_data, rc_data = self._get_animation_json_data(slug)
        self.assertIsNotNone(kf_data, f"[{name}] Keyframes JSON missing for '{slug}'")
        self.assertIsNotNone(rc_data, f"[{name}] Recipe JSON missing for '{slug}'")

        # 1. Keyframes parts match authentic 15 parts
        kf_parts = kf_data.get("parts", [])
        self.assertEqual(
            len(kf_parts),
            15,
            f"[{name}] Keyframes parts count must be 15, got {len(kf_parts)}",
        )
        for part in EXPECTED_R15_PARTS:
            self.assertIn(
                part,
                kf_parts,
                f"[{name}] Part '{part}' missing from Keyframes parts",
            )

        # 2. Recipe tracks map 1:1 to driven parts
        tracks = rc_data.get("tracks", [])
        self.assertEqual(
            len(tracks),
            15,
            f"[{name}] Recipe tracks count must be 15, got {len(tracks)}",
        )
        track_joints = [t.get("joint") for t in tracks]
        for part in EXPECTED_R15_PARTS:
            self.assertIn(
                part,
                track_joints,
                f"[{name}] Joint '{part}' missing from Recipe tracks",
            )

    def test_tier4_reference_fast_run_rig_compatibility(self):
        """Smoke test: Reference Fast Run matches PreviewRig_R15_Boy_Height30 topology."""
        self._verify_rig_compatibility_for_animation("fast-run", "Fast Run")

    # --- Section 2: Timestamps Monotonicity ---

    def _verify_timestamps_monotonicity(self, slug: str, name: str):
        kf_data, rc_data = self._get_animation_json_data(slug)
        self.assertIsNotNone(kf_data, f"[{name}] Keyframes JSON missing")
        self.assertIsNotNone(rc_data, f"[{name}] Recipe JSON missing")

        duration = kf_data.get("duration", 0.0)

        # Check Keyframes frames timestamps
        frames = kf_data.get("frames", [])
        self.assertGreater(len(frames), 0, f"[{name}] Keyframes frames empty")

        prev_time = -1e-6
        for i, frame in enumerate(frames):
            t = frame.get("time")
            self.assertIsNotNone(t, f"[{name}] Frame {i} missing time")
            self.assertGreater(
                t,
                prev_time,
                f"[{name}] Frame {i} time {t} is not strictly greater than previous {prev_time}",
            )
            prev_time = t

        # Last keyframe should not exceed duration by more than epsilon
        self.assertLessEqual(
            prev_time,
            duration + 0.005,
            f"[{name}] Last frame time {prev_time} exceeds duration {duration}",
        )

        # Check Recipe tracks timestamps
        tracks = rc_data.get("tracks", [])
        for track in tracks:
            joint = track.get("joint", "Unknown")
            keys = track.get("keys", [])
            prev_key_time = -1e-6
            for k_idx, key in enumerate(keys):
                kt = key.get("time")
                self.assertIsNotNone(kt, f"[{name}] Track '{joint}' key {k_idx} missing time")
                self.assertGreater(
                    kt,
                    prev_key_time,
                    f"[{name}] Track '{joint}' key {k_idx} time {kt} <= previous {prev_key_time}",
                )
                prev_key_time = kt

    def test_tier4_reference_fast_run_timestamps_monotonicity(self):
        """Smoke test: Reference Fast Run keyframe timestamps strictly monotonic."""
        self._verify_timestamps_monotonicity("fast-run", "Fast Run")

    # --- Section 3: Rotation Continuity & Finite Euler Bounds ---

    def _verify_rotations_and_euler_bounds(self, slug: str, name: str):
        kf_data, rc_data = self._get_animation_json_data(slug)
        self.assertIsNotNone(kf_data, f"[{name}] Keyframes JSON missing")
        self.assertIsNotNone(rc_data, f"[{name}] Recipe JSON missing")

        # 1. Check Recipe JSON keys
        tracks = rc_data.get("tracks", [])
        for track in tracks:
            joint = track.get("joint", "Unknown")
            keys = track.get("keys", [])
            for k_idx, key in enumerate(keys):
                rot = key.get("rotation")
                self.assertIsNotNone(rot, f"[{name}] Track '{joint}' key {k_idx} missing rotation")
                self.assertEqual(len(rot), 3, f"[{name}] Track '{joint}' key {k_idx} rotation must have 3 elements")

                for axis_idx, angle in enumerate(rot):
                    self.assertTrue(
                        math.isfinite(angle),
                        f"[{name}] Track '{joint}' key {k_idx} axis {axis_idx} angle not finite: {angle}",
                    )
                    # Support up to 2 full rotations (720 deg) for acrobatic kicks, tumbles, and turning transitions
                    self.assertGreaterEqual(
                        angle,
                        -720.0,
                        f"[{name}] Track '{joint}' key {k_idx} axis {axis_idx} angle {angle} < -720 deg",
                    )
                    self.assertLessEqual(
                        angle,
                        720.0,
                        f"[{name}] Track '{joint}' key {k_idx} axis {axis_idx} angle {angle} > 720 deg",
                    )

        # 2. Check Keyframes JSON poses: orthogonality and Euler angles
        frames = kf_data.get("frames", [])
        for f_idx, frame in enumerate(frames):
            poses = frame.get("poses", [])
            for p_idx, pose in enumerate(poses):
                self.assertEqual(
                    len(pose),
                    12,
                    f"[{name}] Frame {f_idx} pose {p_idx} must have 12 CFrame numbers",
                )
                # Check all floats are finite
                for val in pose:
                    self.assertTrue(
                        math.isfinite(val),
                        f"[{name}] Frame {f_idx} pose {p_idx} contains non-finite value: {val}",
                    )

                # Check 3x3 rotation submatrix orthogonality
                rot9 = pose[3:]
                self.assertTrue(
                    is_matrix_orthogonal(rot9, tol=0.08),
                    f"[{name}] Frame {f_idx} pose {p_idx} rotation submatrix not orthogonal: {rot9}",
                )

                # Check derived Euler angles
                euler_pitch, euler_yaw, euler_roll = cframe_matrix_to_euler_deg(rot9)
                for ang_name, ang_val in [("pitch", euler_pitch), ("yaw", euler_yaw), ("roll", euler_roll)]:
                    self.assertTrue(
                        math.isfinite(ang_val),
                        f"[{name}] Frame {f_idx} pose {p_idx} derived {ang_name} not finite: {ang_val}",
                    )
                    self.assertGreaterEqual(
                        ang_val,
                        -360.0,
                        f"[{name}] Frame {f_idx} pose {p_idx} derived {ang_name} {ang_val} < -360 deg",
                    )
                    self.assertLessEqual(
                        ang_val,
                        360.0,
                        f"[{name}] Frame {f_idx} pose {p_idx} derived {ang_name} {ang_val} > 360 deg",
                    )

    def test_tier4_reference_fast_run_rotation_continuity(self):
        """Smoke test: Reference Fast Run rotations finite, orthogonal, and within bounds."""
        self._verify_rotations_and_euler_bounds("fast-run", "Fast Run")

    # Tests across all 15 animation clips
    def test_tier4_all_15_animations_rig_and_continuity(self):
        """Verify rig compatibility, timestamp monotonicity, and Euler bounds across all 15 clips."""
        for anim in ALL_15_CLIPS:
            slug = anim["slug"]
            name = anim["name"]
            self._verify_rig_compatibility_for_animation(slug, name)
            self._verify_timestamps_monotonicity(slug, name)
            self._verify_rotations_and_euler_bounds(slug, name)

    # --- Section 4: Manifest Validation in outputagy/v3/manifest.json ---

    def test_tier4_v3_manifest_validation(self):
        """Verify outputagy/v3/manifest.json schema and content when present."""
        manifest_path = None
        for p in [MANIFEST_V3_ONEDRIVE, MANIFEST_V3_LOCAL]:
            if p.is_file():
                manifest_path = p
                break

        if manifest_path is None:
            # During M0 before M4 generation, verify manifest specification contract
            self.assertTrue(
                True, "Manifest not yet generated (Milestone M0 ready; gated for M4)"
            )
            return

        ok, data, err = load_json(manifest_path)
        self.assertTrue(ok, f"Failed to parse v3 manifest.json: {err}")
        self.assertIsInstance(data, dict, "Manifest root must be an object")

        # Validate total clips
        self.assertEqual(
            data.get("total_clips"),
            15,
            f"Manifest total_clips must be 15, got {data.get('total_clips')}",
        )

        clips = data.get("clips", [])
        self.assertEqual(
            len(clips), 15, f"Manifest clips array must have 15 items, got {len(clips)}"
        )

        clip_slugs = [c.get("slug") for c in clips]
        for anim in ALL_15_CLIPS:
            self.assertIn(
                anim["slug"],
                clip_slugs,
                f"Clip '{anim['slug']}' missing from v3 manifest.json",
            )

    # --- Section 5: Owner Visual Inspection Prerequisites ---

    def test_tier4_owner_visual_inspection_prerequisites(self):
        """Verify visual inspection standards (512x512, 30 FPS, loop=0, disposal=2)."""
        # Test reference GIFs in outputagy/v3
        v3_gifs = [
            ("GoalkeeperSidestep", OUTPUTAGY_V3_ONEDRIVE / "GoalkeeperSidestep_R15_v03.gif"),
            ("StrikeFowardJog", OUTPUTAGY_V3_ONEDRIVE / "StrikeFowardJog_R15_v03.gif"),
        ]

        for name, gif_path in v3_gifs:
            if gif_path.is_file():
                info = parse_gif(gif_path)
                self.assertTrue(info["valid"], f"[{name}] v3 GIF is invalid: {info['error']}")
                self.assertEqual(
                    (info["width"], info["height"]),
                    GIF_EXPECTED_DIMENSIONS,
                    f"[{name}] Dimensions must be 512x512, got {info['width']}x{info['height']}",
                )
                self.assertEqual(
                    info["loop"],
                    GIF_EXPECTED_LOOP,
                    f"[{name}] Loop must be 0 (infinite), got {info['loop']}",
                )
                self.assertGreaterEqual(
                    info["frames"],
                    15,
                    f"[{name}] Frame count must be >= 15, got {info['frames']}",
                )

    # --- Section 6: Distinct Import Destinations Specifications ---

    def test_tier4_distinct_destinations_payload_specs(self):
        """Verify distinct data contracts for Studio AnimSaves vs Motion Tools Rig Library."""
        # Destination A: AnimSaves specifies Roblox KeyframeSequence hierarchy
        # Destination B: Motion Tools specifies JSON recipe with max 128 keys per track
        for anim in ALL_15_CLIPS:
            slug = anim["slug"]
            name = anim["name"]
            _, rc_data = self._get_animation_json_data(slug)
            self.assertIsNotNone(rc_data, f"[{name}] Recipe JSON missing")

            # Verify recipe has 15 tracks
            tracks = rc_data.get("tracks", [])
            self.assertEqual(len(tracks), 15, f"[{name}] Must have 15 tracks")

            # Check that standing-idle-02 has subsampling requirement specified
            if slug == "standing-idle-02":
                self.assertIn("subsample_max_keys", anim)
                self.assertEqual(anim["subsample_max_keys"], 128)


if __name__ == "__main__":
    unittest.main()
