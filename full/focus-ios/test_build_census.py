#!/usr/bin/env python3
"""Static teeth for the raw-swiftc census/generated-build boundary."""

import hashlib
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("build_census.sh")
CENSUS = Path(__file__).with_name("census-swiftui-s15-2026-08-28.txt")


class BuildCensusTests(unittest.TestCase):
    def test_bundle_accessor_is_narrow_generated_build_support(self) -> None:
        text = SCRIPT.read_text()
        self.assertIn("DesignSystem|Widget|Licenses|Onboarding", text)
        self.assertIn("$OUT/generated-build-support/$target", text)
        self.assertIn("Generated build support: SwiftPM Bundle.module census accessor", text)
        self.assertIn('fatalError("compile-only census accessor")', text)

    def test_generated_accessor_is_an_extra_compiler_input_not_an_app_copy(self) -> None:
        text = SCRIPT.read_text()
        self.assertIn('srcs+=("$accessor")', text)
        self.assertIn('find "$srcdir" -name \'*.swift\' -print0', text)
        self.assertNotRegex(
            text,
            r"(?m)^\s*(cp|mv|sed|perl)\b.*(?:\$APP|\$P)/",
        )

    def test_every_census_compile_remains_whole_module_optimization(self) -> None:
        text = SCRIPT.read_text()
        self.assertIn("-wmo -target", text)
        self.assertIn("swiftc -typecheck -wmo", text)

    def test_reviewed_s15_classification_is_pinned(self) -> None:
        payload = CENSUS.read_bytes()
        self.assertEqual(
            hashlib.sha256(payload).hexdigest(),
            "667821b62719a422997f4b364a5c71d082fbc4568ae000b049f59311e75a1f03",
        )
        text = payload.decode()
        self.assertIn("target-DesignSystem            0 primary diagnostics", text)
        self.assertIn("target-Onboarding             64 primary diagnostics", text)
        self.assertIn("app                          696 primary diagnostics", text)


if __name__ == "__main__":
    unittest.main()
