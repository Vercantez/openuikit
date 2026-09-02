#!/usr/bin/env python3
"""prepare.py prints denominators and is idempotent on verify."""

from __future__ import annotations

from pathlib import Path
import re
import subprocess
import unittest
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "env"))

from ledger import sha256_file  # noqa: E402
from prepare import prepare, summarize, host_arch, expected_cannot_for_host  # noqa: E402
from contract import load_contract  # noqa: E402

PREPARE = ROOT / "scripts" / "env" / "prepare.py"
SUMMARY = re.compile(
    r"^ENV_PREPARE_SUMMARY satisfied=(\d+)/(\d+) cold-built=(\d+)/(\d+) "
    r"staged=(\d+)/(\d+) CANNOT=(\d+)/(\d+) unsatisfied=(\d+) host=\S+ gate=\S+"
)


class PrepareTests(unittest.TestCase):
    def test_verify_only_focus_widget_prints_denominators(self) -> None:
        proc = subprocess.run(
            [
                "python3",
                str(PREPARE),
                "--gate",
                "focus-widget",
                "--verify-only",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr + proc.stdout)
        summary = [line for line in proc.stdout.splitlines() if line.startswith("ENV_PREPARE_SUMMARY ")]
        self.assertEqual(len(summary), 1, proc.stdout)
        match = SUMMARY.match(summary[0])
        self.assertIsNotNone(match, summary[0])
        sat, sat_d, built, built_d, staged, staged_d, cannot, cannot_d, unsatisfied = (
            int(g) for g in match.groups()
        )
        self.assertGreater(sat_d, 0)
        self.assertGreaterEqual(sat, 0)
        self.assertLessEqual(sat, sat_d)
        self.assertGreaterEqual(cannot_d, 2)  # x86_64 expected CANNOT set is large
        print(summary[0])
        self.assertIn("gate=focus-widget", summary[0])

    def test_rerun_is_idempotent_status_set(self) -> None:
        first = subprocess.run(
            ["python3", str(PREPARE), "--gate", "focus-widget", "--verify-only"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        second = subprocess.run(
            ["python3", str(PREPARE), "--gate", "focus-widget", "--verify-only"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        first_summary = [ln for ln in first.stdout.splitlines() if ln.startswith("ENV_PREPARE_SUMMARY ")][0]
        second_summary = [ln for ln in second.stdout.splitlines() if ln.startswith("ENV_PREPARE_SUMMARY ")][0]
        self.assertEqual(first_summary, second_summary)

    def test_libswiftCore_artifact_hash_is_the_contract_pin(self) -> None:
        artifact = ROOT / "swiftcore-macho/artifacts/swift-macosx/arm64/libswiftCore.dylib"
        self.assertTrue(artifact.is_file())
        self.assertEqual(
            sha256_file(artifact),
            "dd01686e06c81a21755bb864b43dad446c011e6c60c6b387b3b332c0a12708cb",
        )

    def test_materialize_stages_libswiftCore_and_fixes_mktemp_root(self) -> None:
        proc = subprocess.run(
            ["python3", str(PREPARE), "--gate", "focus-widget", "--no-fetch"],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr + proc.stdout)
        self.assertTrue((ROOT / "build" / "full").is_dir())
        dest = ROOT / "machorun/darwin/usr/lib/swift/libswiftCore.dylib"
        self.assertTrue(dest.is_file(), proc.stdout)
        self.assertEqual(
            sha256_file(dest),
            "dd01686e06c81a21755bb864b43dad446c011e6c60c6b387b3b332c0a12708cb",
        )
        self.assertRegex(proc.stdout, r"ENV_PREPARE_(STAGED|SATISFIED) id=libswiftCore")
        self.assertIn("CURSOR_ENV_CANNOT_BUILD_LOADER", proc.stdout)
        summary = [ln for ln in proc.stdout.splitlines() if ln.startswith("ENV_PREPARE_SUMMARY ")][0]
        print(summary)

    def test_summarize_counts_match_outcomes(self) -> None:
        contract = load_contract(ROOT)
        outcomes = prepare(ROOT, "focus-widget", verify_only=True, fetch=False)
        line = summarize(
            outcomes,
            host_arch(),
            "focus-widget",
            expected_cannot_for_host(contract, host_arch(), "Linux"),
        )
        self.assertTrue(SUMMARY.match(line), line)
        cannot_rows = [o for o in outcomes if o.status == "cannot"]
        self.assertTrue(any(o.marker == "CURSOR_ENV_CANNOT_BUILD_LOADER" for o in cannot_rows) or host_arch() in ("aarch64", "arm64"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
