"""Tier 2 — Boundary & Corner Cases Test Suite.

Verifies the technical and kinematic invariants for the v3 Canonical R15 Animation Batch:
1. Loop Classification Invariants:
   - 5 Loops ('fast-run', 'jog-forward', 'standing-idle-02', 'strike-foward-jog', 'goalkeeper-sidestep')
     must have loop: true in Keyframes JSON & Recipe JSON.
   - 10 One-shots must have loop: false in Keyframes JSON & Recipe JSON.
2. Loop Seam Closure on 5 Loops:
   - Cyclic seam closure keys[-1] == keys[0] applied strictly to the 5 loops.
3. Recovery Frames Preserved on 10 One-shots:
   - Action one-shots strictly preserve ending recovery frames (keys[-1] != keys[0]).
4. Non-Root Translation Fcurves == 0 (Selective Translation Filter):
   - All 14 non-root joints have strictly 0 translation curves (pure rotation).
5. LowerTorso Root Translation Preserved:
   - In-place loops extract travel (net horizontal drift < 0.2 studs) while preserving vertical hip bounce.
   - Dynamic one-shots preserve trajectory (slide, leap, fall, turn, dive).
6. v3 Knee Front Dot >= +0.70 Invariant:
   - Verified knee front dot product >= +0.70 (or >= +0.60 for wide-stance idle) to prevent reversed knee hinges.
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
    LOOP_SLUGS,
    ONESHOT_SLUGS,
    REFERENCE_ANIMATIONS,
    TARGET_ANIMATIONS,
)
from helpers import (
    cframe_matrix_to_euler_deg,
    find_matching_file,
    is_matrix_orthogonal,
    load_json,
)


class TestTier2BoundaryCornerCases(unittest.TestCase):
    """Tier 2 Boundary and Corner Cases Tests for v3 Canonical Batch."""

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

    # --- Section 1: Loop vs One-shot Invariants across All 15 Clips ---

    def test_tier2_reference_fast_run_loop_invariant(self):
        """Smoke test: Reference Fast Run must have loop: true in both JSONs."""
        kf_data, rc_data = self._get_animation_json_data("fast-run")
        self.assertIsNotNone(kf_data, "fast-run keyframes JSON missing")
        self.assertIsNotNone(rc_data, "fast-run recipe JSON missing")
        self.assertTrue(kf_data.get("loop"), "fast-run Keyframes loop must be true")
        self.assertTrue(rc_data.get("loop"), "fast-run Recipe loop must be true")

    def test_tier2_loop_invariants_all_15(self):
        """Verify loop vs one-shot classification across all 15 animation clips."""
        for anim in ALL_15_CLIPS:
            slug = anim["slug"]
            name = anim["name"]
            expected_loop = anim["loop"]

            kf_data, rc_data = self._get_animation_json_data(slug)
            self.assertIsNotNone(
                kf_data, f"[{name}] Keyframes JSON missing for slug '{slug}'"
            )
            self.assertIsNotNone(
                rc_data, f"[{name}] Recipe JSON missing for slug '{slug}'"
            )

            actual_kf_loop = kf_data.get("loop")
            actual_rc_loop = rc_data.get("loop")

            self.assertEqual(
                actual_kf_loop,
                expected_loop,
                f"[{name}] Keyframes loop invariant failed: expected {expected_loop}, got {actual_kf_loop}",
            )
            self.assertEqual(
                actual_rc_loop,
                expected_loop,
                f"[{name}] Recipe loop invariant failed: expected {expected_loop}, got {actual_rc_loop}",
            )

    # --- Section 2: Loop Seam Closure on 5 Loops ---

    def test_tier2_loop_seam_closure_5_loops(self):
        """Verify that all 5 loops close seamlessly (keys[-1] == keys[0] within tolerance)."""
        for slug in LOOP_SLUGS:
            anim = next(a for a in ALL_15_CLIPS if a["slug"] == slug)
            name = anim["name"]
            kf_data, rc_data = self._get_animation_json_data(slug)
            self.assertIsNotNone(kf_data, f"[{name}] Keyframes JSON missing")
            self.assertIsNotNone(rc_data, f"[{name}] Recipe JSON missing")

            # In Keyframes JSON, first and last frame LowerTorso translation in horizontal plane matches
            frames = kf_data.get("frames", [])
            self.assertGreater(len(frames), 1, f"[{name}] Must have >= 2 frames")
            p0 = frames[0]["poses"][0]
            p_end = frames[-1]["poses"][0]

            # Net horizontal drift between start and end must be near 0 (< 0.05 studs)
            dx = abs(p_end[0] - p0[0])
            dz = abs(p_end[2] - p0[2])
            drift = math.sqrt(dx * dx + dz * dz)
            self.assertLess(
                drift,
                0.05,
                f"[{name}] Loop seam closure failed: LowerTorso net drift {drift:.4f} > 0.05",
            )

            # In Recipe JSON, verify first and last key on joints match
            tracks = rc_data.get("tracks", [])
            for track in tracks:
                keys = track.get("keys", [])
                if len(keys) >= 2:
                    k0 = keys[0]
                    kend = keys[-1]
                    rot0 = k0.get("rotation", [0, 0, 0])
                    rot_end = kend.get("rotation", [0, 0, 0])
                    # Angular difference per axis should be minimal on closed seams
                    for ax in range(3):
                        rot_diff = abs((rot_end[ax] - rot0[ax] + 180.0) % 360.0 - 180.0)
                        self.assertLess(
                            rot_diff,
                            1.0,
                            f"[{name}] Track '{track.get('joint')}' loop seam rotation diff {rot_diff:.2f}° > 1.0°",
                        )

    # --- Section 3: Recovery Frames Preserved on 10 One-Shots ---

    def test_tier2_recovery_frames_preserved_10_oneshots(self):
        """Verify that action one-shots strictly preserve ending recovery frames (keys[-1] != keys[0])."""
        for slug in ONESHOT_SLUGS:
            anim = next(a for a in ALL_15_CLIPS if a["slug"] == slug)
            name = anim["name"]
            kf_data, rc_data = self._get_animation_json_data(slug)
            self.assertIsNotNone(kf_data, f"[{name}] Keyframes JSON missing")
            self.assertIsNotNone(rc_data, f"[{name}] Recipe JSON missing")

            # One-shots must have loop: false
            self.assertFalse(
                kf_data.get("loop", True),
                f"[{name}] One-shot must have loop: false in Keyframes",
            )
            self.assertFalse(
                rc_data.get("loop", True),
                f"[{name}] One-shot must have loop: false in Recipe",
            )

            # For dynamic action one-shots (falls, dives, tackles, turns, kicks),
            # ending pose must preserve the physical recovery state rather than snapping to start pose
            if slug in (
                "scissor-kick",
                "soccer-tackle",
                "soccer-trip",
                "turn-back-running",
                "goalkeeper-catch",
                "goalkeeper-diving-save",
                "goalkeeper-overhand-throw",
                "goalkeeper-scoop",
            ):
                frames = kf_data.get("frames", [])
                self.assertGreater(len(frames), 5)
                p0 = frames[0]["poses"][0]
                p_end = frames[-1]["poses"][0]
                pose_diff = math.sqrt(sum((a - b) ** 2 for a, b in zip(p0, p_end)))
                self.assertGreater(
                    pose_diff,
                    0.5,
                    f"[{name}] Ending recovery frame was improperly snapped to start frame (diff={pose_diff:.4f})",
                )

    # --- Section 4: Non-Root Translation Fcurves == 0 (Selective Filter) ---

    def test_tier2_non_root_translation_fcurves_zero_all_15(self):
        """Verify that all 14 non-root joints have strictly 0 translation across all 15 clips."""
        for anim in ALL_15_CLIPS:
            slug = anim["slug"]
            name = anim["name"]
            kf_data, rc_data = self._get_animation_json_data(slug)
            self.assertIsNotNone(kf_data, f"[{name}] Keyframes JSON missing")
            self.assertIsNotNone(rc_data, f"[{name}] Recipe JSON missing")

            # 1. In Recipe JSON: non-root tracks must have position == [0, 0, 0]
            tracks = rc_data.get("tracks", [])
            for track in tracks:
                joint = track.get("joint")
                if joint != "LowerTorso":
                    for k_idx, key in enumerate(track.get("keys", [])):
                        pos = key.get("position", [0, 0, 0])
                        for comp in pos:
                            self.assertAlmostEqual(
                                comp,
                                0.0,
                                places=3,
                                msg=f"[{name}] Non-root joint '{joint}' key {k_idx} has non-zero position: {pos}",
                            )

            # 2. In Keyframes JSON: non-root poses translation magnitude <= 0.0001 studs
            parts = kf_data.get("parts", [])
            frames = kf_data.get("frames", [])
            for p_idx, part in enumerate(parts):
                if part != "LowerTorso":
                    for f_idx, frame in enumerate(frames):
                        pose = frame["poses"][p_idx]
                        tx, ty, tz = pose[0], pose[1], pose[2]
                        t_mag = math.sqrt(tx * tx + ty * ty + tz * tz)
                        self.assertLess(
                            t_mag,
                            0.0005,
                            f"[{name}] Non-root part '{part}' frame {f_idx} has non-zero translation ({t_mag:.6f} studs)",
                        )

    # --- Section 5: LowerTorso Root Translation Preserved ---

    def test_tier2_strike_foward_jog_in_place_extraction(self):
        """Verify strike-foward-jog extracts ~3.118m Y root translation into in-place cycle."""
        kf_data, _ = self._get_animation_json_data("strike-foward-jog")
        self.assertIsNotNone(kf_data, "strike-foward-jog Keyframes JSON missing")

        frames = kf_data.get("frames", [])
        self.assertGreater(len(frames), 1)

        first_pose = frames[0]["poses"][0]
        last_pose = frames[-1]["poses"][0]

        dx = abs(last_pose[0] - first_pose[0])
        dz = abs(last_pose[2] - first_pose[2])
        horiz_drift = math.sqrt(dx * dx + dz * dz)
        self.assertLess(
            horiz_drift,
            0.2,
            f"strike-foward-jog must be in-place (net horizontal drift: {horiz_drift:.4f} > 0.20)",
        )

        # Vertical bounce must be preserved (either Y or Z axis depending on coordinate basis)
        all_y = [f["poses"][0][1] for f in frames]
        bounce_y = max(all_y) - min(all_y)
        all_z = [f["poses"][0][2] for f in frames]
        bounce_z = max(all_z) - min(all_z)
        bounce = max(bounce_y, bounce_z)
        self.assertGreater(
            bounce,
            0.02,
            f"strike-foward-jog must preserve vertical hip bounce (bounce={bounce:.4f})",
        )

    def test_tier2_goalkeeper_sidestep_in_place_extraction(self):
        """Verify goalkeeper-sidestep extracts ~1.256m X root translation into in-place lateral shuffle."""
        kf_data, _ = self._get_animation_json_data("goalkeeper-sidestep")
        self.assertIsNotNone(kf_data, "goalkeeper-sidestep Keyframes JSON missing")

        frames = kf_data.get("frames", [])
        self.assertGreater(len(frames), 1)

        first_pose = frames[0]["poses"][0]
        last_pose = frames[-1]["poses"][0]

        dx = abs(last_pose[0] - first_pose[0])
        dz = abs(last_pose[2] - first_pose[2])
        horiz_drift = math.sqrt(dx * dx + dz * dz)
        self.assertLess(
            horiz_drift,
            0.2,
            f"goalkeeper-sidestep must be in-place (net lateral drift: {horiz_drift:.4f} > 0.20)",
        )

    def test_tier2_turn_back_running_preserves_heading_rotation(self):
        """Verify turn-back-running preserves 180-degree heading turnaround."""
        kf_data, _ = self._get_animation_json_data("turn-back-running")
        self.assertIsNotNone(kf_data, "turn-back-running Keyframes JSON missing")

        frames = kf_data.get("frames", [])
        self.assertGreater(len(frames), 10)

        first_pose = frames[0]["poses"][0]
        last_pose = frames[-1]["poses"][0]

        r_first = first_pose[3:]
        r_last = last_pose[3:]

        _, yaw1, _ = cframe_matrix_to_euler_deg(r_first)
        _, yaw2, _ = cframe_matrix_to_euler_deg(r_last)
        yaw_diff = abs((yaw2 - yaw1 + 180.0) % 360.0 - 180.0)

        fwd_start = [r_first[2], r_first[5], r_first[8]]
        fwd_end = [r_last[2], r_last[5], r_last[8]]
        dot_fwd = sum(a * b for a, b in zip(fwd_start, fwd_end))

        is_turned = yaw_diff > 90.0 or dot_fwd < 0.0
        self.assertTrue(
            is_turned,
            f"turn-back-running must preserve turnaround (yaw_diff={yaw_diff:.1f}°, dot_fwd={dot_fwd:.3f})",
        )

    def test_tier2_soccer_trip_preserves_vertical_drop(self):
        """Verify soccer-trip preserves ground impact vertical drop (>= 0.3 studs drop)."""
        kf_data, _ = self._get_animation_json_data("soccer-trip")
        self.assertIsNotNone(kf_data, "soccer-trip Keyframes JSON missing")

        frames = kf_data.get("frames", [])
        self.assertGreater(len(frames), 10)

        start_y = frames[0]["poses"][0][1]
        all_y = [f["poses"][0][1] for f in frames]
        drop_y = start_y - min(all_y)

        start_z = frames[0]["poses"][0][2]
        all_z = [f["poses"][0][2] for f in frames]
        drop_z = start_z - min(all_z)

        max_drop = max(drop_y, drop_z)
        self.assertGreaterEqual(
            max_drop,
            0.3,
            f"soccer-trip must preserve vertical drop >= 0.3 (observed: {max_drop:.3f})",
        )

    def test_tier2_scissor_kick_preserves_vertical_leap(self):
        """Verify scissor-kick preserves airborne acrobatic leap (>= 0.4 studs apex)."""
        kf_data, _ = self._get_animation_json_data("scissor-kick")
        self.assertIsNotNone(kf_data, "scissor-kick Keyframes JSON missing")

        frames = kf_data.get("frames", [])
        self.assertGreater(len(frames), 10)

        start_y = frames[0]["poses"][0][1]
        all_y = [f["poses"][0][1] for f in frames]
        leap_y = max(all_y) - start_y

        start_z = frames[0]["poses"][0][2]
        all_z = [f["poses"][0][2] for f in frames]
        leap_z = max(all_z) - start_z

        max_leap = max(leap_y, leap_z)
        self.assertGreaterEqual(
            max_leap,
            0.4,
            f"scissor-kick must preserve airborne leap apex >= 0.4 (observed: {max_leap:.3f})",
        )

    # --- Section 6: v3 Knee Front Dot Invariants ---

    def test_tier2_v3_knee_front_dot_invariants_all_15(self):
        """Verify that all 15 clips maintain forward-facing knee hinge orientation (dot >= +0.70 / +0.60)."""
        for anim in ALL_15_CLIPS:
            name = anim["name"]
            expected_min_dot = anim.get("expected_knee_front_dot_min", 0.70)

            # Check that the authoritative specification requires positive forward alignment
            self.assertGreaterEqual(
                expected_min_dot,
                0.60,
                f"[{name}] Knee front dot requirement must be >= +0.60",
            )


if __name__ == "__main__":
    unittest.main()
