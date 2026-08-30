from __future__ import annotations

import json
import os
from pathlib import Path
import plistlib
import sys
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
TOOL_DIR = HERE.parent
sys.path.insert(0, os.fspath(TOOL_DIR))

import application_build_plan  # noqa: E402
import materialize_application_bundle  # noqa: E402


class MaterializeApplicationBundleTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="materialize-app-bundle-test.")
        self.parent = Path(self.temporary.name)
        self.source = self.parent / "source"
        (self.source / "App").mkdir(parents=True)
        (self.source / "Resources/Assets.xcassets/AccentColor.colorset").mkdir(
            parents=True
        )
        (self.source / "Resources/Base.lproj").mkdir(parents=True)
        (self.source / "App/AppDelegate.swift").write_text(
            "import UIKit\n@main class AppDelegate: UIResponder, UIApplicationDelegate {}\n",
            encoding="utf-8",
        )
        (self.source / "App/SceneDelegate.swift").write_text(
            "import UIKit\nclass SceneDelegate: UIResponder, UIWindowSceneDelegate {}\n",
            encoding="utf-8",
        )
        (self.source / "Resources/Assets.xcassets/Contents.json").write_text(
            '{"info":{"author":"xcode","version":1}}\n', encoding="utf-8"
        )
        (
            self.source
            / "Resources/Assets.xcassets/AccentColor.colorset/Contents.json"
        ).write_text(
            '{"colors":[],"info":{"author":"xcode","version":1}}\n',
            encoding="utf-8",
        )
        (self.source / "Resources/Base.lproj/Launch.storyboard").write_text(
            "<document/>\n", encoding="utf-8"
        )
        (self.source / "Info.plist").write_bytes(
            plistlib.dumps(
                {
                    "UIApplicationSceneManifest": {
                        "UIApplicationSupportsMultipleScenes": False,
                        "UISceneConfigurations": {
                            "UIWindowSceneSessionRoleApplication": [
                                {
                                    "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                                }
                            ]
                        },
                    }
                },
                sort_keys=True,
            )
        )
        self.inventory = {
            "configuration": {
                "project": {"build_settings": {}},
                "target": {
                    "build_settings": {
                        "INFOPLIST_FILE": "Info.plist",
                        "PRODUCT_BUNDLE_IDENTIFIER": "org.example.Probe",
                    }
                },
            },
            "format_version": 1,
            "missing_inputs": [],
            "unsupported_features": [],
            "target": {
                "name": "Probe",
                "product_name": "Probe",
                "product_type": "com.apple.product-type.application",
            },
            "sources": [
                {"path": "App/AppDelegate.swift"},
                {"path": "App/SceneDelegate.swift"},
            ],
            "resources": [
                {
                    "path": "Resources/Assets.xcassets",
                    "relative_path": "Resources/Assets.xcassets",
                },
                {
                    "path": "Resources/Base.lproj/Launch.storyboard",
                    "relative_path": "Resources/Base.lproj/Launch.storyboard",
                },
            ],
        }
        _generated, self.plan = application_build_plan.plan(self.inventory, self.source)

        self.platform = self.parent / "platform"
        (self.platform / "fonts").mkdir(parents=True)
        for relative in (
            "system_colors.json",
            "font_metrics.json",
            "text_decorations.json",
            "fonts/DejaVuSans.ttf",
            "fonts/DejaVuSans-Bold.ttf",
        ):
            target = self.platform / relative
            target.write_bytes((relative + "\n").encode("utf-8"))

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_materializes_complete_relocatable_resource_bundle(self) -> None:
        output = self.parent / "Probe.app"
        attestation = self.parent / "bundle.json"
        result = materialize_application_bundle.materialize(
            self.plan, self.source, self.platform, output, attestation
        )
        self.assertTrue((output / "Contents/MacOS").is_dir())
        self.assertTrue((output / "Contents/Frameworks").is_dir())
        self.assertEqual(
            (output / "Contents/Resources/Assets.xcassets/Contents.json").read_bytes(),
            (self.source / "Resources/Assets.xcassets/Contents.json").read_bytes(),
        )
        self.assertEqual(
            (output / "Contents/Resources/Base.lproj/Launch.storyboard").read_bytes(),
            b"<document/>\n",
        )
        self.assertEqual(
            (output / "Contents/Resources/OpenUIKit/system_colors.json").read_bytes(),
            b"system_colors.json\n",
        )
        self.assertEqual(result["summary"]["application_files"], 4)
        self.assertEqual(result["summary"]["platform_files"], 5)
        self.assertEqual(json.loads(attestation.read_text()), result)

        with self.assertRaisesRegex(
            materialize_application_bundle.BundleMaterializationError, "already exists"
        ):
            materialize_application_bundle.materialize(
                self.plan, self.source, self.platform, output, self.parent / "other.json"
            )

    def test_refuses_mutated_application_and_incomplete_platform(self) -> None:
        (self.source / "Resources/Base.lproj/Launch.storyboard").write_text(
            "changed\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(
            materialize_application_bundle.BundleMaterializationError, "changed after planning"
        ):
            materialize_application_bundle.materialize(
                self.plan,
                self.source,
                self.platform,
                self.parent / "Changed.app",
                self.parent / "changed.json",
            )

        (self.source / "Resources/Base.lproj/Launch.storyboard").write_text(
            "<document/>\n", encoding="utf-8"
        )
        (self.platform / "font_metrics.json").unlink()
        with self.assertRaisesRegex(
            materialize_application_bundle.BundleMaterializationError, "incomplete"
        ):
            materialize_application_bundle.materialize(
                self.plan,
                self.source,
                self.platform,
                self.parent / "Incomplete.app",
                self.parent / "incomplete.json",
            )

    def test_refuses_platform_symlink_and_reserved_application_path(self) -> None:
        os.symlink(
            self.platform / "system_colors.json", self.platform / "linked-system-colors.json"
        )
        with self.assertRaisesRegex(
            materialize_application_bundle.BundleMaterializationError, "symlink"
        ):
            materialize_application_bundle.materialize(
                self.plan,
                self.source,
                self.platform,
                self.parent / "Symlink.app",
                self.parent / "symlink.json",
            )

        (self.platform / "linked-system-colors.json").unlink()
        changed = json.loads(json.dumps(self.plan))
        changed["resources"][0]["bundle_destination"] = "OpenUIKit/app-data"
        with self.assertRaisesRegex(
            materialize_application_bundle.BundleMaterializationError, "reserved"
        ):
            materialize_application_bundle.materialize(
                changed,
                self.source,
                self.platform,
                self.parent / "Reserved.app",
                self.parent / "reserved.json",
            )


if __name__ == "__main__":
    unittest.main()
