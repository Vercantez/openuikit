from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parent
TOOL_DIR = HERE.parent
sys.path.insert(0, os.fspath(TOOL_DIR))

import xcconfig  # noqa: E402


class XcconfigEvaluationTests(unittest.TestCase):
    def test_includes_assignments_comments_quotes_and_continuations_are_ordered(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            nested = root / "Config"
            nested.mkdir()
            (root / "Main.xcconfig").write_text(
                "BASE = local // inline comment\n"
                '#include "Config/First.xcconfig"\n'
                "LIST += tail\n"
                'URL = "https://example.invalid/a//b"\n'
                'TITLE = "Hello" \\\n'
                '"World"\n',
                encoding="utf-8",
            )
            (nested / "First.xcconfig").write_text(
                "/* included values */\n"
                "NAME = $(BASE)-App\n"
                "LIST = one\n"
                '#include "../Second.xcconfig"\n',
                encoding="utf-8",
            )
            (root / "Second.xcconfig").write_text(
                "LIST += two\n"
                "BASE ?= ignored\n",
                encoding="utf-8",
            )

            result = xcconfig.evaluate(
                root,
                "Main.xcconfig",
                {"BASE": "inherited"},
            )

            self.assertEqual(
                result.settings,
                {
                    "BASE": "local",
                    "LIST": "one two tail",
                    "NAME": "$(BASE)-App",
                    "TITLE": "Hello World",
                    "URL": "https://example.invalid/a//b",
                },
            )
            self.assertEqual(
                [item["path"] for item in result.files],
                [
                    "Main.xcconfig",
                    "Config/First.xcconfig",
                    "Second.xcconfig",
                ],
            )
            self.assertTrue(all(len(item["sha256"]) == 64 for item in result.files))
            self.assertEqual(
                result.includes,
                (
                    {
                        "from": "Main.xcconfig",
                        "line": 2,
                        "path": "Config/First.xcconfig",
                        "requested_path": "Config/First.xcconfig",
                    },
                    {
                        "from": "Config/First.xcconfig",
                        "line": 4,
                        "path": "Second.xcconfig",
                        "requested_path": "../Second.xcconfig",
                    },
                ),
            )
            self.assertEqual(result.assignment_count, 8)

    def test_unique_casefold_include_records_tracked_spelling(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Main.xcconfig").write_text(
                '#include "Version.public.xcconfig"\n', encoding="utf-8"
            )
            (root / "Version.Public.xcconfig").write_text(
                "VERSION = 1\n", encoding="utf-8"
            )

            result = xcconfig.evaluate(root, "Main.xcconfig")

            self.assertEqual(result.settings, {"VERSION": "1"})
            self.assertEqual(
                [item["path"] for item in result.files],
                ["Main.xcconfig", "Version.Public.xcconfig"],
            )
            self.assertEqual(
                result.includes[0]["requested_path"], "Version.public.xcconfig"
            )

    def test_missing_escape_cycle_symlink_and_unmodelled_syntax_fail_closed(self) -> None:
        cases = {
            "missing": '#include "Missing.xcconfig"\n',
            "escape": '#include "../Outside.xcconfig"\n',
            "optional": '#include? "Missing.xcconfig"\n',
            "conditional": "NAME[sdk=iphoneos*] = Device\n",
            "malformed": "NAME := Unsupported\n",
        }
        for label, contents in cases.items():
            with self.subTest(label=label), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                (root / "Main.xcconfig").write_text(contents, encoding="utf-8")
                with self.assertRaises(xcconfig.PlanError):
                    xcconfig.evaluate(root, "Main.xcconfig")

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "A.xcconfig").write_text(
                '#include "B.xcconfig"\n', encoding="utf-8"
            )
            (root / "B.xcconfig").write_text(
                '#include "A.xcconfig"\n', encoding="utf-8"
            )
            with self.assertRaisesRegex(xcconfig.PlanError, "include cycle"):
                xcconfig.evaluate(root, "A.xcconfig")

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            outside = root.parent / f"{root.name}-outside.xcconfig"
            outside.write_text("NAME = outside\n", encoding="utf-8")
            link = root / "Linked.xcconfig"
            link.symlink_to(outside)
            try:
                with self.assertRaisesRegex(xcconfig.PlanError, "symlink"):
                    xcconfig.evaluate(root, "Linked.xcconfig")
            finally:
                outside.unlink()

    def test_non_utf8_and_non_string_append_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Bad.xcconfig").write_bytes(b"NAME = \xff\n")
            with self.assertRaisesRegex(xcconfig.PlanError, "not UTF-8"):
                xcconfig.evaluate(root, "Bad.xcconfig")

            (root / "Append.xcconfig").write_text(
                "FLAGS += next\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(xcconfig.PlanError, "non-string inherited"):
                xcconfig.evaluate(root, "Append.xcconfig", {"FLAGS": ["base"]})


if __name__ == "__main__":
    unittest.main()
