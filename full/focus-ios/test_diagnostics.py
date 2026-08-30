#!/usr/bin/env python3
"""Controls for the focus-ios primary-diagnostic parser."""

from __future__ import annotations

import unittest

from pathlib import Path

from diagnostics import (
    diagnostic_delta_lines,
    normalized_primary_lines,
    primary_error_messages,
)


class PrimaryDiagnosticTests(unittest.TestCase):
    def test_counts_primary_lines_not_rendering_or_source_text(self) -> None:
        log = """\
/tmp/Source With Spaces.swift:10:4: error: first real diagnostic
 8 | func callback(error: Error?) {}
10 | bad()
   |    `- error: first real diagnostic
<unknown>:0: error: driver diagnostic without a column
note: error: text in a note is not a primary diagnostic
"""
        self.assertEqual(
            primary_error_messages(log),
            [
                "first real diagnostic",
                "driver diagnostic without a column",
            ],
        )

    def test_empty_and_warning_only_logs_are_zero(self) -> None:
        self.assertEqual(primary_error_messages(""), [])
        self.assertEqual(
            primary_error_messages("/tmp/A.swift:1:1: warning: warning only\n"),
            [],
        )

    def test_normalization_is_fresh_root_independent_and_sorted(self) -> None:
        log = """\
/private/tmp/run.123/focus/Z File.swift:9:2: error: second
/private/tmp/run.123/focus/A File.swift:1:7: error: first
<unknown>:0: error: driver
"""
        self.assertEqual(
            normalized_primary_lines(
                log,
                [("focus", Path("/private/tmp/run.123/focus"))],
            ),
            [
                "<unknown>\t0\t\tdriver",
                "focus/A File.swift\t1\t7\tfirst",
                "focus/Z File.swift\t9\t2\tsecond",
            ],
        )

    def test_normalization_refuses_unclassified_absolute_paths(self) -> None:
        with self.assertRaisesRegex(ValueError, "unclassified absolute"):
            normalized_primary_lines(
                "/outside/Source.swift:1:1: error: drift\n",
                [("focus", Path("/focus"))],
            )

    def test_delta_preserves_duplicate_diagnostic_multiplicity(self) -> None:
        shared = "focus/A.swift\t1\t1\tshared"
        removed = "focus/B.swift\t2\t2\tremoved"
        added = "focus/C.swift\t3\t3\tadded"
        self.assertEqual(
            diagnostic_delta_lines(
                [shared, shared, removed],
                [shared, added, added],
            ),
            [
                "format\tfocus-primary-delta-v1",
                "baseline-count\t3",
                "candidate-count\t3",
                "removed-count\t2",
                "added-count\t2",
                f"removed\t1\t{shared}",
                f"removed\t1\t{removed}",
                f"added\t2\t{added}",
            ],
        )


if __name__ == "__main__":
    unittest.main()
