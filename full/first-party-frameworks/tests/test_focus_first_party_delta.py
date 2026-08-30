#!/usr/bin/env python3
"""Fail-closed tests for exact untouched-Focus diagnostic attribution."""

from __future__ import annotations

from pathlib import Path
import subprocess
import tempfile
import unittest


TOOL = Path(__file__).resolve().parents[1] / "focus_first_party_delta.py"


class FocusDeltaTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.focus = self.root / "focus"
        self.focus.mkdir()
        self.first = self.focus / "First.swift"
        self.second = self.focus / "Second.swift"
        self.first.write_text("let first = 1\n", encoding="utf-8")
        self.second.write_text("let second = 2\n", encoding="utf-8")
        self.baseline = self.root / "baseline.log"
        self.candidate = self.root / "candidate.log"
        self.baseline.write_text(
            f"{self.first}:1:1: error: first gap\n"
            f"{self.second}:1:2: error: second gap\n",
            encoding="utf-8",
        )
        self.candidate.write_text(
            f"{self.second}:1:2: error: second gap\n",
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def run_gate(self, expected: int = 0) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [
                "python3",
                "-B",
                str(TOOL),
                "--baseline-log",
                str(self.baseline),
                "--candidate-log",
                str(self.candidate),
                "--focus-root",
                str(self.focus),
                "--target",
                "arm64-apple-macos15.0",
                "--require-no-added",
                "--output",
                str(self.root / "delta.tsv"),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def test_exact_multiset_delta_is_written(self) -> None:
        result = self.run_gate()
        self.assertIn("baseline=2 candidate=1 removed=1 added=0", result.stdout)
        self.assertEqual(
            (self.root / "delta.tsv").read_text().splitlines()[-1],
            "removed\t1\tFirst.swift\t1\t1\tfirst gap",
        )

    def test_added_diagnostic_is_refused_without_output(self) -> None:
        self.candidate.write_text(
            self.candidate.read_text()
            + f"{self.first}:1:3: error: newly exposed gap\n",
            encoding="utf-8",
        )
        refusal = self.run_gate(expected=2)
        self.assertIn("introduced 1 primary diagnostics", refusal.stderr)
        self.assertFalse((self.root / "delta.tsv").exists())

    def test_outside_source_is_refused(self) -> None:
        outside = self.root / "Outside.swift"
        outside.write_text("let outside = 3\n", encoding="utf-8")
        self.candidate.write_text(
            f"{outside}:1:1: error: escaped subject\n", encoding="utf-8"
        )
        refusal = self.run_gate(expected=2)
        self.assertIn("outside untouched Focus", refusal.stderr)

    def test_existing_output_is_refused(self) -> None:
        self.run_gate()
        refusal = self.run_gate(expected=2)
        self.assertIn("refusing to overwrite", refusal.stderr)


if __name__ == "__main__":
    unittest.main()
