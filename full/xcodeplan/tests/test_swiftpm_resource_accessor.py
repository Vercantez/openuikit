#!/usr/bin/env python3
"""swiftpm_resource_accessor: Xcode 26.1's generated Bundle.module accessor."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

import swiftpm_resource_accessor as accessor  # noqa: E402

GOLDEN = HERE / "fixtures/swiftpm-accessor/ResPkg_ResLib.xcode26.1-iphonesimulator.swift"


class SwiftPMResourceAccessorTests(unittest.TestCase):
    def test_byte_identical_to_xcode_26_1(self) -> None:
        # DerivedSources/resource_bundle_accessor.swift from
        # `xcodebuild -scheme ResPkg -destination 'generic/platform=iOS Simulator'`
        # for package ResPkg, target ResLib, resources: [.process("Resources")].
        self.assertEqual(accessor.accessor_source("ResPkg_ResLib"), GOLDEN.read_bytes())

    def test_bundle_stem_is_c99_package_and_module(self) -> None:
        self.assertEqual(accessor.bundle_stem("ActivityLog", "ActivityLog"), "ActivityLog_ActivityLog")
        self.assertEqual(accessor.bundle_stem("Core-Utilities", "Core"), "Core_Utilities_Core")
        self.assertEqual(accessor.bundle_stem("3D", "Kit"), "_3D_Kit")

    def test_the_stem_is_the_only_variable_part(self) -> None:
        text = accessor.accessor_source("ActivityLog_ActivityLog").decode()
        self.assertEqual(text.replace("ActivityLog_ActivityLog", "ResPkg_ResLib"), GOLDEN.read_text())
        self.assertIn('let bundleName = "ActivityLog_ActivityLog"', text)
        self.assertIn("Bundle.main.resourceURL", text)

    def test_unsafe_stems_are_refused(self) -> None:
        for stem in ["", "a b", 'x"); evil("', "1abc", "a.bundle"]:
            with self.assertRaises(accessor.AccessorError, msg=stem):
                accessor.accessor_source(stem)

    def test_cli_writes_the_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "resource_bundle_accessor.swift"
            subprocess.run([sys.executable, str(HERE.parent / "swiftpm_resource_accessor.py"),
                            "ResPkg_ResLib", str(out)], check=True)
            self.assertEqual(out.read_bytes(), GOLDEN.read_bytes())


if __name__ == "__main__":
    unittest.main()
