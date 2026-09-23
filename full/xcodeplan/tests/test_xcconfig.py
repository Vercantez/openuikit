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
            "optional-unsafe": '#include? "/abs/Missing.xcconfig"\n',
            "optional-trailing": '#include? "A.xcconfig" junk\n',
            "conditional-malformed": "NAME[platform=ios] = Device\n",
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

    def test_optional_include_matches_measured_xcode_semantics(self) -> None:
        # Xcode 26.1 (xcodebuild -showBuildSettings -xcconfig, 2026-09-23):
        # a missing #include? is silent, a present one is evaluated in textual
        # order, and "SEMI = value;" evaluates to "value".
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "repo"
            (root / "cfg").mkdir(parents=True)
            (root / "cfg" / "present.xcconfig").write_text(
                "FROM_PRESENT = yes\nORDER = present\n"
                '#include "nested.xcconfig"\n',
                encoding="utf-8",
            )
            (root / "cfg" / "nested.xcconfig").write_text(
                "NESTED = yes\n", encoding="utf-8"
            )
            (root / "Main.xcconfig").write_text(
                "ORDER = before\n"
                '#include? "cfg/missing.xcconfig"\n'
                '#include? "cfg/present.xcconfig"\n'
                '#include? "../../SharedXcodeSettings/ProjectSettings.xcconfig"\n'
                "SEMI = value;\n"
                'QUOTED = "a;"\n'
                "AFTER_OPTIONAL = yes\n",
                encoding="utf-8",
            )

            result = xcconfig.evaluate(root, "Main.xcconfig")

            self.assertEqual(
                result.settings,
                {
                    "AFTER_OPTIONAL": "yes",
                    "FROM_PRESENT": "yes",
                    "NESTED": "yes",
                    "ORDER": "present",
                    "QUOTED": "a;",
                    "SEMI": "value",
                },
            )
            self.assertEqual(
                [item["path"] for item in result.files],
                ["Main.xcconfig", "cfg/present.xcconfig", "cfg/nested.xcconfig"],
            )
            self.assertEqual(
                result.includes,
                (
                    {
                        "from": "Main.xcconfig",
                        "line": 2,
                        "optional": True,
                        "requested_path": "cfg/missing.xcconfig",
                        "skipped": "absent",
                    },
                    {
                        "from": "Main.xcconfig",
                        "line": 3,
                        "optional": True,
                        "path": "cfg/present.xcconfig",
                        "requested_path": "cfg/present.xcconfig",
                    },
                    {
                        "from": "cfg/present.xcconfig",
                        "line": 3,
                        "path": "cfg/nested.xcconfig",
                        "requested_path": "nested.xcconfig",
                    },
                    {
                        "from": "Main.xcconfig",
                        "line": 4,
                        "optional": True,
                        "requested_path": "../../SharedXcodeSettings/ProjectSettings.xcconfig",
                        "skipped": "absent-outside-source-root",
                    },
                ),
            )

    def test_destination_conditional_assignments_are_recorded_not_applied(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Main.xcconfig").write_text(
                "CODE_SIGN_IDENTITY[sdk=iphoneos*] = iPhone Developer\n"
                "OTHER_LDFLAGS[sdk=iphonesimulator*][arch=arm64] = -lsim\n"
                "CODE_SIGN_STYLE = Automatic\n",
                encoding="utf-8",
            )
            result = xcconfig.evaluate(root, "Main.xcconfig")
            self.assertEqual(result.settings, {"CODE_SIGN_STYLE": "Automatic"})
            self.assertEqual(result.assignment_count, 1)
            self.assertEqual(
                result.conditional,
                (
                    {
                        "conditions": ["[sdk=iphoneos*]"],
                        "key": "CODE_SIGN_IDENTITY",
                        "line": 1,
                        "operator": "=",
                        "path": "Main.xcconfig",
                        "value": "iPhone Developer",
                    },
                    {
                        "conditions": ["[sdk=iphonesimulator*]", "[arch=arm64]"],
                        "key": "OTHER_LDFLAGS",
                        "line": 2,
                        "operator": "=",
                        "path": "Main.xcconfig",
                        "value": "-lsim",
                    },
                ),
            )

    def test_optional_include_of_an_existing_file_outside_the_root_is_refused(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "repo"
            root.mkdir()
            (Path(directory) / "Shared.xcconfig").write_text(
                "SECRET = outside\n", encoding="utf-8"
            )
            (root / "Main.xcconfig").write_text(
                '#include? "../Shared.xcconfig"\n', encoding="utf-8"
            )
            with self.assertRaisesRegex(xcconfig.PlanError, "outside the xcconfig source root"):
                xcconfig.evaluate(root, "Main.xcconfig")

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
