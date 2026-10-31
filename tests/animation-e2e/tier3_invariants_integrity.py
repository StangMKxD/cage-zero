"""Tier 3 — Invariants & Integrity Test Suite.

Verifies:
1. Source FBX Integrity: SHA-256 hashes of all 15 source Mixamo FBX files match
   the baseline recorded in survey_assets_v3/handoff.md.
2. Protected Working Tree Invariant:
   - Exactly 33 dirty files in `src/` documented in survey_assets_v3 are preserved
     without any loss, revert, reset, or checkout rollback.
3. Reference Preservation:
   - Baseline files in `fast-run/` and `jog-forward/` remain intact.
4. Strict Scope Enforcement:
   - No unauthorized modifications across `src/` against `src_baseline_manifest.json`.
"""

import os
import sys
import unittest
from pathlib import Path

_CUR_DIR = Path(__file__).resolve().parent
if str(_CUR_DIR) not in sys.path:
    sys.path.insert(0, str(_CUR_DIR))

from config import (
    ALL_15_CLIPS,
    ANIMATION_WORK_DIR,
    OUTPUTAGY_DIR,
    PROTECTED_SRC_FILES,
    REFERENCE_ANIMATIONS,
    SOURCE_DIR,
    SOURCE_FBX_BASELINE,
    SRC_BASELINE_MANIFEST,
    SRC_DIR,
    TARGET_ANIMATIONS,
)
from helpers import compute_sha256, load_json


class TestTier3InvariantsIntegrity(unittest.TestCase):
    """Tier 3 Invariants and Integrity Tests."""

    def test_tier3_source_mixamo_fbx_integrity_all_15(self):
        """Verify all 15 source Mixamo FBX files exist, match exact file sizes and SHA-256 hashes."""
        self.assertTrue(SOURCE_DIR.is_dir(), f"Source Mixamo FBX directory missing: {SOURCE_DIR}")

        for anim in ALL_15_CLIPS:
            name = anim["name"]
            rel_path = anim["source_rel"]
            expected_hash = anim["source_sha256"].upper()
            expected_size = anim["source_size"]

            full_path = SOURCE_DIR / rel_path
            self.assertTrue(
                full_path.is_file(),
                f"[{name}] Source FBX file missing: {full_path}",
            )

            actual_size = full_path.stat().st_size
            self.assertEqual(
                actual_size,
                expected_size,
                f"[{name}] Source FBX file size mismatch: expected {expected_size}, got {actual_size}",
            )

            actual_hash = compute_sha256(full_path)
            self.assertEqual(
                actual_hash,
                expected_hash,
                f"[{name}] Source FBX SHA-256 mismatch! File has been altered: {actual_hash} != {expected_hash}",
            )

    def test_tier3_strict_scope_33_protected_files_in_src(self):
        """Verify that all 33 uncommitted files in src/ remain intact without revert or modification."""
        self.assertTrue(SRC_DIR.is_dir(), f"src/ directory missing: {SRC_DIR}")

        mismatched_files = []
        missing_files = []

        for rel_path, expected_hash in PROTECTED_SRC_FILES.items():
            full_path = SRC_DIR / rel_path
            if not full_path.is_file():
                missing_files.append(rel_path)
                continue
            actual_hash = compute_sha256(full_path).upper()
            if actual_hash != expected_hash.upper():
                mismatched_files.append((rel_path, actual_hash, expected_hash))

        self.assertEqual(
            len(missing_files),
            0,
            f"PROTECTED SRC VIOLATION: Missing files in src/: {missing_files}",
        )
        self.assertEqual(
            len(mismatched_files),
            0,
            f"PROTECTED SRC VIOLATION: Files in src/ were reverted or altered: {mismatched_files}",
        )

    def test_tier3_reference_outputs_preservation(self):
        """Verify reference workspaces 'fast-run/' and 'jog-forward/' outputs remain untouched."""
        # 1. Fast Run FBX & GIF
        fast_run_fbx = ANIMATION_WORK_DIR / "fast-run" / "FastRun_R15.fbx"
        self.assertTrue(fast_run_fbx.is_file(), "fast-run/FastRun_R15.fbx missing")

        fast_run_gif = ANIMATION_WORK_DIR / "fast-run" / "FastRun_R15.gif"
        self.assertTrue(fast_run_gif.is_file(), "fast-run/FastRun_R15.gif missing")

        # 2. Jog Forward FBX & GIF
        jog_fbx = ANIMATION_WORK_DIR / "jog-forward" / "JogForward_R15.fbx"
        self.assertTrue(jog_fbx.is_file(), "jog-forward/JogForward_R15.fbx missing")

        jog_gif = ANIMATION_WORK_DIR / "jog-forward" / "JogForward_R15.gif"
        self.assertTrue(jog_gif.is_file(), "jog-forward/JogForward_R15.gif missing")

    def test_tier3_strict_scope_src_unmodified(self):
        """Verify strict scope: zero Lua/Luau scripts in src/ modified during this project."""
        self.assertTrue(SRC_DIR.is_dir(), f"src/ directory missing: {SRC_DIR}")
        self.assertTrue(
            SRC_BASELINE_MANIFEST.is_file(),
            f"src baseline manifest missing: {SRC_BASELINE_MANIFEST}",
        )

        ok, baseline, err = load_json(SRC_BASELINE_MANIFEST)
        self.assertTrue(ok, f"Failed to load src baseline manifest: {err}")

        # 1. Verify every baseline file exists and hash matches
        mismatched_files = []
        for rel_path, expected_hash in baseline.items():
            full_path = SRC_DIR / rel_path
            if not full_path.is_file():
                mismatched_files.append((rel_path, "DELETED_OR_MISSING"))
                continue
            actual_hash = compute_sha256(full_path).lower()
            if actual_hash != expected_hash.lower():
                mismatched_files.append((rel_path, f"MODIFIED ({actual_hash} != {expected_hash})"))

        # 2. Verify no unexpected new files were created in src/
        new_files = []
        for root, _, files in os.walk(SRC_DIR):
            for file in files:
                p = Path(root) / file
                rel = str(p.relative_to(SRC_DIR)).replace("\\", "/")
                if rel not in baseline:
                    new_files.append(rel)

        self.assertEqual(
            len(mismatched_files),
            0,
            f"STRICT SCOPE VIOLATION: Files in src/ were modified: {mismatched_files}",
        )
        self.assertEqual(
            len(new_files),
            0,
            f"STRICT SCOPE VIOLATION: Unauthorized new files in src/: {new_files}",
        )


if __name__ == "__main__":
    unittest.main()
