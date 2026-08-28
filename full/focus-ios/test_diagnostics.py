#!/usr/bin/env python3
"""Controls for the focus-ios primary-diagnostic parser."""

from __future__ import annotations

import unittest

from diagnostics import primary_error_messages


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


if __name__ == "__main__":
    unittest.main()
