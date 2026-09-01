from __future__ import annotations

from pathlib import Path
import tempfile
import unittest
from unittest import mock

import sys

XCODEPLAN = Path(__file__).resolve().parents[1]
if str(XCODEPLAN) not in sys.path:
    sys.path.insert(0, str(XCODEPLAN))

import application_platform_package


class ApplicationPlatformPackageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def test_refuses_missing_and_ambiguous_completion_markers(self) -> None:
        with self.assertRaisesRegex(
            application_platform_package.ApplicationPlatformError, "neither"
        ):
            application_platform_package.validate(self.root)
        (self.root / "attestation").mkdir()
        (self.root / "attestation/core-package.json").write_text("{}")
        (self.root / "PLATFORM_COMPLETE").write_text("complete\n")
        with self.assertRaisesRegex(
            application_platform_package.ApplicationPlatformError, "ambiguously"
        ):
            application_platform_package.validate(self.root)

    @mock.patch.object(application_platform_package.core_guest_package, "validate")
    def test_normalizes_core_package(self, validate: mock.Mock) -> None:
        (self.root / "attestation").mkdir()
        (self.root / "attestation/core-package.json").write_text("{}")
        validate.return_value = (
            self.root,
            {
                "target": {"triple": "arm64-apple-macos15.0"},
                "paths": {
                    "guest_root": "guest-root",
                    "resources": "resources",
                    "libraries": "libraries",
                },
                "preview": None,
                "swift_compile_arguments": ["-target", "arm64-apple-macos15.0"],
                "executable_link_arguments": ["-arch", "arm64"],
            },
        )
        root, contract = application_platform_package.validate(self.root)
        self.assertEqual(root, self.root)
        self.assertEqual(contract["kind"], "core")
        self.assertEqual(contract["bundle_layout"], "macos")
        self.assertEqual(contract["paths"]["runtime_root"], "guest-root")
        self.assertEqual(contract["app_compile_diagnostic_arguments"], [])

    @mock.patch.object(
        application_platform_package.true_ios_platform_package, "validate"
    )
    def test_normalizes_true_ios_package(self, validate: mock.Mock) -> None:
        (self.root / "PLATFORM_COMPLETE").write_text("complete\n")
        validate.return_value = (
            self.root,
            {
                "target": "arm64-apple-ios18.0-simulator",
                "paths": {
                    "runtime_root": "runtime-root",
                    "resources": "resources/OpenUIKit",
                    "libraries": "products",
                },
                "swift_compile_arguments": [
                    "-target",
                    "arm64-apple-ios18.0-simulator",
                ],
                "executable_link_arguments": [
                    "-platform_version",
                    "ios-simulator",
                ],
            },
        )
        root, contract = application_platform_package.validate(self.root)
        self.assertEqual(root, self.root)
        self.assertEqual(contract["kind"], "true-ios")
        self.assertEqual(contract["bundle_layout"], "ios")
        self.assertEqual(contract["contract_file"], "PLATFORM_COMPLETE")
        self.assertEqual(contract["preview"], None)
        self.assertEqual(contract["app_compile_diagnostic_arguments"], [])

    @mock.patch.object(
        application_platform_package.true_ios_platform_package,
        "rooted_compile_arguments",
    )
    def test_true_ios_rooting_delegates_to_authoritative_validator(
        self, rooted: mock.Mock
    ) -> None:
        rooted.return_value = ["-sdk", str(self.root / "sdk")]
        contract = {
            "kind": "true-ios",
            "swift_compile_arguments": ["-sdk", "sdk"],
        }
        self.assertEqual(
            application_platform_package.rooted_swift_compile_arguments(
                self.root, contract
            ),
            rooted.return_value,
        )
        rooted.assert_called_once_with(self.root, ["-sdk", "sdk"])


if __name__ == "__main__":
    unittest.main()
