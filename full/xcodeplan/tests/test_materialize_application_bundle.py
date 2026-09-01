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
        (self.source / "Resources/Assets.xcassets/Logo.imageset").mkdir()
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
            '{"colors":[{"idiom":"universal","color":{"color-space":"srgb",'
            '"components":{"red":"0x33","green":"0x66","blue":"0x99",'
            '"alpha":"1.000"}}}],"info":{"author":"xcode","version":1}}\n',
            encoding="utf-8",
        )
        (self.source / "Resources/Assets.xcassets/Logo.imageset/Contents.json").write_text(
            '{"images":[{"idiom":"universal","filename":"logo@2x.png",'
            '"scale":"2x"}],"info":{"author":"xcode","version":1}}\n',
            encoding="utf-8",
        )
        (self.source / "Resources/Assets.xcassets/Logo.imageset/logo@2x.png").write_bytes(
            b"\x89PNG\r\n\x1a\nportable-logo-payload"
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
        asset_root = output / "Contents/Resources/OpenUIKit/AssetCatalogs"
        asset_index = json.loads((asset_root / "index.json").read_text())
        self.assertEqual(asset_index["format"], "openuikit-xcassets-index")
        self.assertEqual(asset_index["app"], "Probe.app")
        self.assertEqual(
            asset_index["catalogs"],
            ["Contents/Resources/Assets.xcassets"],
        )
        self.assertEqual(set(asset_index["assets"]), {"AccentColor", "Logo"})
        self.assertEqual(
            asset_index["assets"]["AccentColor"]["variants"][0]["srgb"],
            [0.2, 0.4, 0.6, 1.0],
        )
        logo = asset_index["assets"]["Logo"]["variants"][0]["payload"]
        self.assertEqual(logo["filename"], "logo@2x.png")
        self.assertEqual(
            (asset_root / "Resources" / logo["file"]).read_bytes(),
            b"\x89PNG\r\n\x1a\nportable-logo-payload",
        )
        self.assertEqual(result["summary"]["application_files"], 6)
        self.assertEqual(result["summary"]["platform_files"], 5)
        self.assertEqual(result["summary"]["asset_catalogs"], 1)
        self.assertEqual(result["summary"]["asset_catalog_assets"], 2)
        self.assertEqual(result["summary"]["asset_catalog_files"], 2)
        self.assertEqual(result["summary"]["asset_catalog_unresolved"], 0)
        generated = [
            record
            for record in result["files"]
            if record["source_class"] == "OpenUIKit-generated-xcassets"
        ]
        self.assertEqual(len(generated), 2)
        self.assertTrue(
            any(record["bundle_path"].endswith("/index.json") for record in generated)
        )
        self.assertEqual(json.loads(attestation.read_text()), result)
        self.assertEqual(result["bundle_layout"], "macos")

        with self.assertRaisesRegex(
            materialize_application_bundle.BundleMaterializationError, "already exists"
        ):
            materialize_application_bundle.materialize(
                self.plan, self.source, self.platform, output, self.parent / "other.json"
            )

    def test_materializes_flat_ios_application_bundle(self) -> None:
        output = self.parent / "ProbeIOS.app"
        attestation = self.parent / "ios-bundle.json"
        result = materialize_application_bundle.materialize(
            self.plan,
            self.source,
            self.platform,
            output,
            attestation,
            bundle_layout="ios",
        )

        self.assertFalse((output / "Contents").exists())
        self.assertTrue((output / "Info.plist").is_file())
        self.assertTrue((output / "Frameworks").is_dir())
        self.assertEqual(
            (output / "Base.lproj/Launch.storyboard").read_bytes(),
            b"<document/>\n",
        )
        self.assertEqual(
            (output / "OpenUIKit/system_colors.json").read_bytes(),
            b"system_colors.json\n",
        )
        asset_index = json.loads(
            (output / "OpenUIKit/AssetCatalogs/index.json").read_text()
        )
        self.assertEqual(asset_index["catalogs"], ["Assets.xcassets"])
        self.assertEqual(result["bundle_layout"], "ios")
        self.assertEqual(json.loads(attestation.read_text()), result)

    def test_refuses_unknown_bundle_layout(self) -> None:
        with self.assertRaisesRegex(
            materialize_application_bundle.BundleMaterializationError,
            "unsupported application bundle layout",
        ):
            materialize_application_bundle.materialize(
                self.plan,
                self.source,
                self.platform,
                self.parent / "Unknown.app",
                self.parent / "unknown.json",
                bundle_layout="watchos",
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

    def test_materializes_swiftpm_resource_bundles_and_indexes_their_assets(self) -> None:
        package = self.source / "Package"
        package_sources = package / "Sources/Pack"
        package_catalog = package_sources / "PackAssets.xcassets/PackColor.colorset"
        package_catalog.mkdir(parents=True)
        (package / "Package.swift").write_text(
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let package = Package(name: \"PackageResources\", "
            "products: [.library(name: \"Pack\", targets: [\"Pack\"])], "
            "targets: [.target(name: \"Pack\", resources: ["
            ".copy(\"payload.json\"), .process(\"PackAssets.xcassets\")])])\n",
            encoding="utf-8",
        )
        (package_sources / "Pack.swift").write_text(
            "public struct Pack { public init() {} }\n", encoding="utf-8"
        )
        (package_sources / "payload.json").write_text(
            '{"portable":true}\n', encoding="utf-8"
        )
        (package_sources / "PackAssets.xcassets/Contents.json").write_text(
            '{"info":{"author":"xcode","version":1}}\n', encoding="utf-8"
        )
        (package_catalog / "Contents.json").write_text(
            '{"colors":[{"idiom":"universal","color":{'
            '"color-space":"srgb","components":{"red":"1.000",'
            '"green":"0.000","blue":"0.000","alpha":"1.000"}}}],'
            '"info":{"author":"xcode","version":1}}\n',
            encoding="utf-8",
        )
        inventory = json.loads(json.dumps(self.inventory))
        inventory["local_package_references"] = [{"relative_path": "Package"}]
        inventory["package_products"] = [
            {"name": "Pack", "origin": "local", "relative_path": "Package"}
        ]
        _generated, plan = application_build_plan.plan(inventory, self.source)

        output = self.parent / "PackageResources.app"
        attestation = self.parent / "package-resources.json"
        result = materialize_application_bundle.materialize(
            plan, self.source, self.platform, output, attestation
        )
        resource_bundle = (
            output
            / "Contents/Resources/PackageResources_Pack.bundle"
        )
        self.assertEqual(
            (resource_bundle / "payload.json").read_bytes(), b'{"portable":true}\n'
        )
        self.assertTrue(
            (resource_bundle / "PackAssets.xcassets/Contents.json").is_file()
        )
        self.assertEqual(result["summary"]["swiftpm_resource_bundles"], 1)
        self.assertEqual(result["summary"]["swiftpm_resource_files"], 3)
        asset_index = json.loads(
            (
                output / "Contents/Resources/OpenUIKit/AssetCatalogs/index.json"
            ).read_text(encoding="utf-8")
        )
        self.assertEqual(len(asset_index["catalogs"]), 2)
        self.assertIn("PackColor", asset_index["assets"])

        (package_sources / "payload.json").write_text(
            '{"portable":false}\n', encoding="utf-8"
        )
        with self.assertRaises(application_build_plan.BuildPlanError):
            application_build_plan.verify(plan, self.source)


if __name__ == "__main__":
    unittest.main()
