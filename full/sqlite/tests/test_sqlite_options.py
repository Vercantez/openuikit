from __future__ import annotations

import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

import sqlite_options  # noqa: E402

ROOT = HERE.parents[2]
APPLE = ROOT / "uikit/Tools/oracle2/guestsqliteoptions/transcript-ios26.1.txt"


def guest_like(apple: str, rows) -> str:
    """A transcript the guest should print: Apple's head and pragmas, our rows."""
    lines = [l for l in apple.splitlines() if not l.startswith("opt ")]
    options = ["opt COMPILER=clang-18.1.3"] + [f"opt {o}" for o in sqlite_options.expected_guest_rows(rows)]
    return "\n".join(lines[:2] + options + lines[2:]) + "\n"


class SqliteOptionsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.rows = sqlite_options.load()
        self.apple = APPLE.read_text(encoding="utf-8")

    def test_table_covers_every_measured_apple_row_in_order(self) -> None:
        self.assertEqual(
            [line[4:] for line in self.apple.splitlines() if line.startswith("opt ")],
            sqlite_options.apple_rows(self.rows),
        )

    def test_flags_define_every_reproduced_row(self) -> None:
        flags = sqlite_options.flags(self.rows)
        self.assertIn("-DSQLITE_ENABLE_FTS4", flags)
        self.assertIn("-DSQLITE_THREADSAFE=2", flags)
        self.assertIn("-DSQLITE_DEFAULT_AUTOVACUUM=0", flags)
        self.assertIn("-DSQLITE_ENABLE_LOCKING_STYLE=0", flags)
        self.assertNotIn("-DSQLITE_ENABLE_LOCKING_STYLE=1", flags)
        self.assertFalse([f for f in flags if "CODEC" in f or "COMPILER" in f])

    def test_check_accepts_the_expected_guest_and_refuses_drift(self) -> None:
        good = guest_like(self.apple, self.rows)
        self.assertEqual(sqlite_options.check(good, self.apple, self.rows), [])
        cases = {
            "missing option": good.replace("opt ENABLE_FTS5\n", ""),
            "extra option": good.replace("opt USE_URI\n", "opt USE_URI\nopt ENABLE_ICU\n"),
            "version": good.replace("libversion 3.51.0", "libversion 3.50.4"),
            "pragma": good.replace("pragma file page_size 4096", "pragma file page_size 1024"),
            "no compiler": good.replace("opt COMPILER=clang-18.1.3\n", ""),
        }
        for label, text in cases.items():
            with self.subTest(label=label):
                self.assertTrue(sqlite_options.check(text, self.apple, self.rows))


if __name__ == "__main__":
    unittest.main()
