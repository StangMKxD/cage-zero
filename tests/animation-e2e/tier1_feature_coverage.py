"""Tier 1 — Feature Coverage Test Suite.

Verifies that for each of the 15 Mixamo animation clips (and reference baselines):
1. Output folder exists in `cage-zero-animation-work/<slug>/`.
2. Converted R15 FBX exists and has valid size (> 10KB = 10,240 bytes).
3. R15 Keyframes JSON exists, parses as valid JSON, duration > 0, contains 15 driven parts.
4. Motion Tools recipe JSON exists, parses as valid JSON, matches animation schema with 15 tracks.
5. Preview GIF exists in `<slug>/` AND in `outputagy/` (or `outputagy/v3/`).
6. Preview GIF is a valid animated GIF (>= 15 frames, dimensions 512x512, loop=0 infinite).
"""

import os
import sys
import unittest
from pathlib import Path
from typing import Any, Dict, Optional

_CUR_DIR = Path(__file__).resolve().parent
if str(_CUR_DIR) not in sys.path:
    sys.path.insert(0, str(_CUR_DIR))

from config import (
    ALL_15_CLIPS,
    ANIMATION_WORK_DIR,
    EXPECTED_R15_PARTS,
    GIF_EXPECTED_DIMENSIONS,
    GIF_EXPECTED_LOOP,
    GIF_MIN_FRAMES,
    OUTPUTAGY_DIR_LOCAL,
    OUTPUTAGY_DIR_ONEDRIVE,
    OUTPUTAGY_V3_LOCAL,
    OUTPUTAGY_V3_ONEDRIVE,
    REFERENCE_ANIMATIONS,
    TARGET_ANIMATIONS,
)
from helpers import find_matching_file, load_json, parse_gif


class TestTier1FeatureCoverage(unittest.TestCase):
    """Tier 1 Feature Coverage Tests across all 15 clips."""

    def _find_outputagy_gif(self, anim: Dict[str, Any]) -> Optional[Path]:
        """Resolve preview GIF in outputagy (v3 preferred, with v2/v1 fallback across local and OneDrive)."""
        slug = anim["slug"]
        v03_name = anim.get("gif_name_v03", f"{anim['name'].replace(' ', '')}_R15_v03.gif")
        legacy_name = anim.get("gif_name_legacy", f"{anim['name'].replace(' ', '')}_R15.gif")

        # Candidate paths in priority order
        search_dirs = [
            OUTPUTAGY_V3_ONEDRIVE,
            OUTPUTAGY_V3_LOCAL,
            OUTPUTAGY_DIR_ONEDRIVE / "v2",
            OUTPUTAGY_DIR_LOCAL / "v2",
            OUTPUTAGY_DIR_ONEDRIVE,
            OUTPUTAGY_DIR_LOCAL,
            OUTPUTAGY_DIR_ONEDRIVE / "v1",
            OUTPUTAGY_DIR_LOCAL / "v1",
        ]

        candidate_names = [
            v03_name,
            v03_name.replace("_v03.gif", "_LegFix_v02.gif"),
            legacy_name,
            f"{slug}*.gif",
            f"*{slug.replace('-', '')}*.gif",
        ]

        for d in search_dirs:
            if not d.is_dir():
                continue
            for name_pattern in candidate_names:
                match = find_matching_file(d, [name_pattern])
                if match and match.is_file():
                    return match

        return None

    def _verify_animation_outputs(self, anim: Dict[str, Any], is_reference: bool = False):
        slug = anim["slug"]
        slug_dir = ANIMATION_WORK_DIR / slug
        name = anim["name"]

        # 1. Output directory existence
        self.assertTrue(
            slug_dir.is_dir(),
            f"[{name}] Output directory missing: {slug_dir}",
        )

        # 2. Converted R15 FBX exists and has valid size (> 10KB = 10,240 bytes)
        fbx_path = find_matching_file(
            slug_dir,
            [
                anim.get("fbx_name", ""),
                f"{slug}*.fbx",
                f"*{name.replace(' ', '')}*.fbx",
                "*_R15.fbx",
                "*.fbx",
            ],
        )
        self.assertIsNotNone(
            fbx_path,
            f"[{name}] Converted R15 FBX not found in {slug_dir}",
        )
        fbx_size = fbx_path.stat().st_size
        self.assertGreater(
            fbx_size,
            10240,
            f"[{name}] R15 FBX {fbx_path.name} is too small ({fbx_size} bytes <= 10KB)",
        )

        # 3. R15 Keyframes JSON exists, parses as valid JSON, duration > 0, contains 15 driven parts
        kf_path = find_matching_file(
            slug_dir,
            [
                anim.get("keyframes_name", ""),
                f"{slug}-r15-keyframes-legfix-v02.json",
                f"{slug}-r15-keyframes.json",
                "*keyframes*.json",
            ],
        )
        self.assertIsNotNone(
            kf_path,
            f"[{name}] R15 Keyframes JSON not found in {slug_dir}",
        )
        ok_kf, kf_data, err_kf = load_json(kf_path)
        self.assertTrue(ok_kf, f"[{name}] Keyframes JSON parse error: {err_kf}")
        self.assertIsInstance(kf_data, dict, f"[{name}] Keyframes root must be a JSON object")

        # Duration > 0
        duration = kf_data.get("duration", 0)
        self.assertGreater(
            duration, 0, f"[{name}] Keyframes duration must be > 0 (found {duration})"
        )

        # 15 driven parts
        parts = kf_data.get("parts", [])
        self.assertEqual(
            len(parts),
            15,
            f"[{name}] Keyframes must contain exactly 15 parts, found {len(parts)}: {parts}",
        )
        for expected_part in EXPECTED_R15_PARTS:
            self.assertIn(
                expected_part,
                parts,
                f"[{name}] Expected part '{expected_part}' missing from keyframes parts",
            )

        # Frames check
        frames = kf_data.get("frames", [])
        self.assertGreater(
            len(frames), 0, f"[{name}] Keyframes 'frames' array must not be empty"
        )
        first_frame = frames[0]
        self.assertIn("time", first_frame, f"[{name}] Keyframe must have 'time'")
        self.assertIn("poses", first_frame, f"[{name}] Keyframe must have 'poses'")
        self.assertEqual(
            len(first_frame["poses"]),
            15,
            f"[{name}] Keyframe poses count must equal 15 parts",
        )

        # 4. Motion Tools recipe JSON exists, parses as valid JSON, matches animationSchema with 15 tracks
        recipe_path = find_matching_file(
            slug_dir,
            [
                anim.get("recipe_name", ""),
                f"RF02_*{name.replace(' ', '')}*.recipe.json",
                f"*{name.replace(' ', '')}*.recipe.json",
                "*.recipe.json",
            ],
        )
        self.assertIsNotNone(
            recipe_path,
            f"[{name}] Motion Tools recipe JSON not found in {slug_dir}",
        )
        ok_rc, rc_data, err_rc = load_json(recipe_path)
        self.assertTrue(ok_rc, f"[{name}] Recipe JSON parse error: {err_rc}")
        self.assertIsInstance(rc_data, dict, f"[{name}] Recipe root must be a JSON object")

        # Schema verification: tracks array
        tracks = rc_data.get("tracks", [])
        self.assertEqual(
            len(tracks),
            15,
            f"[{name}] Recipe must contain exactly 15 tracks, found {len(tracks)}",
        )
        track_joints = [t.get("joint") for t in tracks if isinstance(t, dict)]
        for expected_part in EXPECTED_R15_PARTS:
            self.assertIn(
                expected_part,
                track_joints,
                f"[{name}] Expected part '{expected_part}' missing from recipe tracks",
            )

        # 5. Preview GIF exists in <slug>/ AND in outputagy/
        gif_in_slug = find_matching_file(
            slug_dir,
            [
                anim.get("gif_name_v03", ""),
                f"*{name.replace(' ', '')}*_v03.gif",
                f"*{name.replace(' ', '')}*_v02.gif",
                anim.get("gif_name_legacy", ""),
                "*_R15.gif",
                "*.gif",
            ],
        )
        self.assertIsNotNone(
            gif_in_slug,
            f"[{name}] Preview GIF not found in slug directory {slug_dir}",
        )

        gif_in_outputagy = self._find_outputagy_gif(anim)
        self.assertIsNotNone(
            gif_in_outputagy,
            f"[{name}] Preview GIF missing from outputagy destinations",
        )

        # 6. Preview GIF is valid animated GIF (>= 15 frames, dimensions 512x512, loop property)
        # Check slug GIF
        gif_slug_info = parse_gif(gif_in_slug)
        self.assertTrue(
            gif_slug_info["valid"],
            f"[{name}] Slug GIF is not a valid GIF: {gif_slug_info['error']}",
        )
        self.assertEqual(
            (gif_slug_info["width"], gif_slug_info["height"]),
            GIF_EXPECTED_DIMENSIONS,
            f"[{name}] Slug GIF dimensions must be 512x512, found {gif_slug_info['width']}x{gif_slug_info['height']}",
        )
        self.assertGreaterEqual(
            gif_slug_info["frames"],
            GIF_MIN_FRAMES,
            f"[{name}] Slug GIF frames must be >= {GIF_MIN_FRAMES}, found {gif_slug_info['frames']}",
        )
        self.assertEqual(
            gif_slug_info["loop"],
            GIF_EXPECTED_LOOP,
            f"[{name}] Slug GIF loop must be {GIF_EXPECTED_LOOP} (infinite), found {gif_slug_info['loop']}",
        )

        # Check outputagy GIF
        gif_out_info = parse_gif(gif_in_outputagy)
        self.assertTrue(
            gif_out_info["valid"],
            f"[{name}] outputagy GIF ({gif_in_outputagy}) is not a valid GIF: {gif_out_info['error']}",
        )
        self.assertEqual(
            (gif_out_info["width"], gif_out_info["height"]),
            GIF_EXPECTED_DIMENSIONS,
            f"[{name}] outputagy GIF dimensions must be 512x512, found {gif_out_info['width']}x{gif_out_info['height']}",
        )
        self.assertGreaterEqual(
            gif_out_info["frames"],
            GIF_MIN_FRAMES,
            f"[{name}] outputagy GIF frames must be >= {GIF_MIN_FRAMES}, found {gif_out_info['frames']}",
        )
        self.assertEqual(
            gif_out_info["loop"],
            GIF_EXPECTED_LOOP,
            f"[{name}] outputagy GIF loop must be {GIF_EXPECTED_LOOP} (infinite), found {gif_out_info['loop']}",
        )

    # Reference Smoke Test (Verifies test logic itself passes on completed pipeline output)
    def test_tier1_reference_fast_run(self):
        """Smoke check Tier 1 requirements against verified reference fast-run."""
        self._verify_animation_outputs(REFERENCE_ANIMATIONS[0], is_reference=True)

    # All 15 Target Animation Tests
    def test_tier1_fast_run(self):
        self._verify_animation_outputs(ALL_15_CLIPS[0])

    def test_tier1_jog_forward(self):
        self._verify_animation_outputs(ALL_15_CLIPS[1])

    def test_tier1_standing_idle_02(self):
        self._verify_animation_outputs(ALL_15_CLIPS[2])

    def test_tier1_strike_foward_jog(self):
        self._verify_animation_outputs(ALL_15_CLIPS[3])

    def test_tier1_goalkeeper_sidestep(self):
        self._verify_animation_outputs(ALL_15_CLIPS[4])

    def test_tier1_scissor_kick(self):
        self._verify_animation_outputs(ALL_15_CLIPS[5])

    def test_tier1_soccer_pass(self):
        self._verify_animation_outputs(ALL_15_CLIPS[6])

    def test_tier1_soccer_tackle(self):
        self._verify_animation_outputs(ALL_15_CLIPS[7])

    def test_tier1_soccer_trip(self):
        self._verify_animation_outputs(ALL_15_CLIPS[8])

    def test_tier1_standing_jump(self):
        self._verify_animation_outputs(ALL_15_CLIPS[9])

    def test_tier1_turn_back_running(self):
        self._verify_animation_outputs(ALL_15_CLIPS[10])

    def test_tier1_goalkeeper_catch(self):
        self._verify_animation_outputs(ALL_15_CLIPS[11])

    def test_tier1_goalkeeper_diving_save(self):
        self._verify_animation_outputs(ALL_15_CLIPS[12])

    def test_tier1_goalkeeper_overhand_throw(self):
        self._verify_animation_outputs(ALL_15_CLIPS[13])

    def test_tier1_goalkeeper_scoop(self):
        self._verify_animation_outputs(ALL_15_CLIPS[14])

    def test_tier1_all_15_clips_feature_coverage(self):
        """Comprehensive batch verification across all 15 clips."""
        for anim in ALL_15_CLIPS:
            self._verify_animation_outputs(anim)


if __name__ == "__main__":
    unittest.main()
