#!/usr/bin/env python3

from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[3]
BUILDER = ROOT / "full/xcodeplan/build_true_ios_platform_frameworks.sh"
PROBE = ROOT / "full/xcodeplan/tests/TrueIOSSwiftUIDylibProbe.swift"


class TrueIOSPlatformFrameworkTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.builder = BUILDER.read_text(encoding="utf-8")
        cls.probe = PROBE.read_text(encoding="utf-8")

    def test_builder_is_valid_strict_shell(self) -> None:
        subprocess.run(["bash", "-n", str(BUILDER)], check=True)
        self.assertIn("set -euo pipefail", self.builder)

    def test_builder_emits_the_split_first_party_dylib_graph(self) -> None:
        for module in (
            "FoundationEssentials",
            "OpenCoreGraphics",
            "OpenUIKit",
            "DeveloperToolsSupport",
            "UIKit",
            "OpenCombine",
            "Combine",
            "SwiftUI",
        ):
            self.assertIn(f"lib{module}.dylib", self.builder)
            self.assertIn(f"/usr/lib/lib{module}.dylib", self.builder)

        self.assertIn('TARGET=arm64-apple-ios18.0-simulator', self.builder)
        self.assertIn('PLATFORM=ios-simulator', self.builder)
        self.assertIn('SDK_VERSION=26.1', self.builder)
        self.assertIn('-framework SwiftUI -framework UIKit', self.builder)

    def test_public_modules_are_consumed_from_framework_bundles(self) -> None:
        self.assertIn('FRAMEWORKS=$SDK_OUT/System/Library/Frameworks', self.builder)
        self.assertIn('stage_framework "$module"', self.builder)
        self.assertIn('-Rmodule-loading', self.builder)
        self.assertIn('for module in SwiftUI UIKit OpenUIKit Combine OpenCombine', self.builder)
        self.assertIn(
            'loaded module \'$module\'; source: \'$expected_module_path\'',
            self.builder,
        )

    def test_build_is_source_preserving_atomic_and_stale_safe(self) -> None:
        self.assertIn('uikit_status=$(git -C "$UIKIT" status', self.builder)
        self.assertIn('SOURCE_SUBJECT_BEFORE=$(source_subject)', self.builder)
        self.assertIn('SOURCE_SUBJECT_AFTER=$(source_subject)', self.builder)
        self.assertIn('rm -rf -- "$OUTPUT_ROOT"', self.builder)
        self.assertIn('stage=$(mktemp -d', self.builder)
        self.assertIn('rm -rf -- "$BUILD" "$INCLUDE"', self.builder)
        self.assertIn('mv "$stage" "$OUTPUT_ROOT"', self.builder)

    def test_probe_exercises_swiftui_through_uikit_at_runtime(self) -> None:
        self.assertIn('import SwiftUI', self.probe)
        self.assertIn('import UIKit', self.probe)
        self.assertIn('UIHostingController', self.probe)
        self.assertIn('VStack(spacing:', self.probe)
        self.assertIn('Button("Advance")', self.probe)
        self.assertIn('precondition(renderedText && renderedButton)', self.probe)
        marker = 'TRUE_IOS_SWIFTUI_DYLIB_RUNTIME_OK'
        self.assertIn(marker, self.probe)
        self.assertIn(marker, self.builder)


if __name__ == "__main__":
    unittest.main()
