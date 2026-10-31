#!/usr/bin/env python3
"""Master E2E Test Runner for CAGE ZERO — Mixamo to Roblox R15 Animation Conversion.

Executes and reports 4-tier automated test suites across all 15 animations (v3 Canonical Batch):
- Tier 1: Feature Coverage (Folder, FBX, Keyframes, Recipe, GIF)
- Tier 2: Boundary & Corner Cases (Loop/One-shot, in-place root extraction, knee front dot, action preservation)
- Tier 3: Invariants & Integrity (Source FBX hashes, 33 protected src/ files, zero scope drift)
- Tier 4: Real-World Application Scenarios (Target rig compatibility, timestamps monotonicity, v3 manifest)

Usage:
    python test_runner.py                    # Run full test suite across all 4 tiers
    python test_runner.py --tier 3           # Run specific tier (1, 2, 3, or 4)
    python test_runner.py --smoke            # Run smoke tests on reference data (fast-run)
    python test_runner.py --slug standing-idle-02  # Run tests for specific slug
    python test_runner.py --json-report report.json  # Output JSON summary
"""

import argparse
import json
import os
import sys
import time
import unittest
from pathlib import Path
from typing import Any, Dict, List, Optional

_CUR_DIR = Path(__file__).resolve().parent
if str(_CUR_DIR) not in sys.path:
    sys.path.insert(0, str(_CUR_DIR))

from config import (
    ALL_15_CLIPS,
    REFERENCE_ANIMATIONS,
    TARGET_ANIMATIONS,
    WORKSPACE_ROOT,
)
from tier1_feature_coverage import TestTier1FeatureCoverage
from tier2_boundary_corner_cases import TestTier2BoundaryCornerCases
from tier3_invariants_integrity import TestTier3InvariantsIntegrity
from tier4_real_world_scenarios import TestTier4RealWorldScenarios


class CustomTestResult(unittest.TestResult):
    """Custom TestResult that captures structured results for formatted reporting."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.test_records: List[Dict[str, Any]] = []

    def startTest(self, test):
        super().startTest(test)
        self._start_time = time.time()

    def addSuccess(self, test):
        super().addSuccess(test)
        elapsed = time.time() - self._start_time
        self.test_records.append({
            "test": test.id(),
            "name": test._testMethodName,
            "status": "PASS",
            "elapsed": elapsed,
            "message": "",
        })

    def addFailure(self, test, err):
        super().addFailure(test, err)
        elapsed = time.time() - self._start_time
        msg = str(err[1])
        self.test_records.append({
            "test": test.id(),
            "name": test._testMethodName,
            "status": "FAIL",
            "elapsed": elapsed,
            "message": msg,
        })

    def addError(self, test, err):
        super().addError(test, err)
        elapsed = time.time() - self._start_time
        msg = str(err[1])
        self.test_records.append({
            "test": test.id(),
            "name": test._testMethodName,
            "status": "ERROR",
            "elapsed": elapsed,
            "message": msg,
        })


def build_suite(
    tiers: List[int],
    smoke_only: bool = False,
    slug_filter: Optional[str] = None,
) -> unittest.TestSuite:
    """Build filtered or complete test suite based on CLI options."""
    suite = unittest.TestSuite()
    loader = unittest.TestLoader()

    tier_classes = {
        1: TestTier1FeatureCoverage,
        2: TestTier2BoundaryCornerCases,
        3: TestTier3InvariantsIntegrity,
        4: TestTier4RealWorldScenarios,
    }

    for t in tiers:
        cls = tier_classes.get(t)
        if not cls:
            continue
        test_names = loader.getTestCaseNames(cls)

        for name in test_names:
            if smoke_only:
                # Include reference tests and tier 3 baseline tests
                if "reference" in name or t == 3 or "rig_json" in name:
                    suite.addTest(cls(name))
            elif slug_filter:
                # Filter by animation slug or name
                clean_slug = slug_filter.lower().replace("-", "_")
                if clean_slug in name.lower() or t == 3:
                    suite.addTest(cls(name))
            else:
                suite.addTest(cls(name))

    return suite


def print_banner():
    print("=" * 80)
    print(" CAGE ZERO — Mixamo to Roblox R15 v3 Canonical Animation E2E Test Suite")
    print(" Target: Place 137721422246269 | Rig: PreviewRig_R15_Boy_Height30 (15 Clips)")
    print("=" * 80)


def print_summary_table(records: List[Dict[str, Any]], total_elapsed: float):
    print("\n" + "-" * 80)
    print(f"{'STATUS':<8} | {'ELAPSED':<8} | {'TEST NAME'}")
    print("-" * 80)

    pass_count = 0
    fail_count = 0
    err_count = 0

    for rec in records:
        status = rec["status"]
        elapsed = f"{rec['elapsed']:.3f}s"
        name = rec["name"]

        if status == "PASS":
            pass_count += 1
            print(f"\033[92m{status:<8}\033[0m | {elapsed:<8} | {name}")
        elif status == "FAIL":
            fail_count += 1
            print(f"\033[91m{status:<8}\033[0m | {elapsed:<8} | {name}")
        else:
            err_count += 1
            print(f"\033[93m{status:<8}\033[0m | {elapsed:<8} | {name}")

    print("-" * 80)
    print(
        f"TOTAL: {len(records)} | PASSED: {pass_count} | FAILED: {fail_count} | ERRORS: {err_count} | TIME: {total_elapsed:.3f}s"
    )
    print("-" * 80)

    if fail_count > 0 or err_count > 0:
        print("\nFAILURE DETAILS:")
        for rec in records:
            if rec["status"] in ("FAIL", "ERROR"):
                print(f"\n[X] {rec['name']}:")
                # Indent message
                lines = rec["message"].strip().split("\n")
                first_few = lines[:8]
                for l in first_few:
                    print(f"    {l}")
                if len(lines) > 8:
                    print(f"    ... [{len(lines)-8} lines truncated]")
        print("\n" + "=" * 80)


def main():
    parser = argparse.ArgumentParser(
        description="Run CAGE ZERO Mixamo to Roblox R15 Animation E2E Tests"
    )
    parser.add_argument(
        "--tier",
        type=str,
        default="1,2,3,4",
        help="Comma-separated tier numbers to run (default: 1,2,3,4)",
    )
    parser.add_argument(
        "--smoke",
        action="store_true",
        help="Run only smoke checks on reference pipeline (Fast Run) and integrity",
    )
    parser.add_argument(
        "--slug",
        type=str,
        default=None,
        help="Filter tests for a specific animation slug (e.g. standing-idle-02)",
    )
    parser.add_argument(
        "--json-report",
        type=str,
        default=None,
        help="Path to write JSON test report",
    )
    parser.add_argument(
        "--allow-pending",
        action="store_true",
        help="Exit code 0 if all failures are due to pending unbuilt animations",
    )

    args = parser.parse_args()

    try:
        tiers = [int(t.strip()) for t in args.tier.split(",") if t.strip()]
    except ValueError:
        print(f"Invalid tier argument: {args.tier}. Expected integers like '1,2,3,4'")
        sys.exit(2)

    print_banner()
    print(f"Configuration: Tiers={tiers} | SmokeOnly={args.smoke} | SlugFilter={args.slug}")

    suite = build_suite(tiers, smoke_only=args.smoke, slug_filter=args.slug)
    result = CustomTestResult()

    start_time = time.time()
    suite.run(result)
    total_elapsed = time.time() - start_time

    print_summary_table(result.test_records, total_elapsed)

    # Output JSON Report if requested
    if args.json_report:
        report_data = {
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "total": len(result.test_records),
            "passed": len(result.test_records) - len(result.failures) - len(result.errors),
            "failed": len(result.failures),
            "errors": len(result.errors),
            "elapsed_seconds": total_elapsed,
            "records": result.test_records,
        }
        report_path = Path(args.json_report)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        with open(report_path, "w", encoding="utf-8") as f:
            json.dump(report_data, f, indent=2)
        print(f"JSON report written to: {report_path}")

    # Determine exit code
    if len(result.failures) == 0 and len(result.errors) == 0:
        print("\n>> ALL EXECUTED TESTS PASSED (100% SUCCESS) <<\n")
        sys.exit(0)
    else:
        # Check if allow_pending is set
        if args.allow_pending:
            # Check if all failures are missing folders / files from unbuilt animations
            all_pending = True
            for f in result.failures:
                msg = str(f[1]).lower()
                if "missing" not in msg and "not found" not in msg and "does not exist" not in msg:
                    all_pending = False
                    break
            if all_pending and len(result.errors) == 0:
                print("\n>> ALL FAILURES ARE DUE TO PENDING UNBUILT ANIMATIONS (M0 READY) <<\n")
                sys.exit(0)

        print(f"\n>> TEST RUN COMPLETED WITH {len(result.failures)} FAILURES AND {len(result.errors)} ERRORS <<\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
