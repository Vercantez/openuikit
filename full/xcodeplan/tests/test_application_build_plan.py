from __future__ import annotations

import copy
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


class ApplicationBuildPlanTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="application-build-plan-test.")
        self.parent = Path(self.temporary.name)
        self.root = self.parent / "subject"
        (self.root / "App").mkdir(parents=True)
        (self.root / "Resources/Assets.xcassets/Accent.colorset").mkdir(parents=True)
        (self.root / "App/AppDelegate.swift").write_text(
            "import UIKit\n@main class AppDelegate: UIResponder, UIApplicationDelegate {}\n",
            encoding="utf-8",
        )
        (self.root / "App/SceneDelegate.swift").write_text(
            "import UIKit\nclass SceneDelegate: UIResponder, UIWindowSceneDelegate {}\n",
            encoding="utf-8",
        )
        (self.root / "App/Model.swift").write_text("struct Model {}\n", encoding="utf-8")
        (self.root / "Resources/Assets.xcassets/Contents.json").write_text(
            '{"info":{"author":"xcode","version":1}}\n', encoding="utf-8"
        )
        (self.root / "Resources/Assets.xcassets/Accent.colorset/Contents.json").write_text(
            '{"colors":[],"info":{"author":"xcode","version":1}}\n',
            encoding="utf-8",
        )
        (self.root / "Resources/Launch.storyboard").write_text(
            "<document/>\n", encoding="utf-8"
        )
        (self.root / "Resources/Info.plist").write_bytes(
            plistlib.dumps(
                {
                    "UIApplicationSceneManifest": {
                        "UIApplicationSupportsMultipleScenes": False,
                        "UISceneConfigurations": {
                            "UIWindowSceneSessionRoleApplication": [
                                {
                                    "UISceneConfigurationName": "Default",
                                    "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
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
                        "INFOPLIST_FILE": "Resources/Info.plist",
                        "PRODUCT_BUNDLE_IDENTIFIER": "org.example.Probe",
                        "PRODUCT_NAME": "Probe",
                    }
                },
            },
            "format_version": 1,
            "missing_inputs": [],
            "resources": [
                {
                    "path": "Resources/Assets.xcassets",
                    "relative_path": "Resources/Assets.xcassets",
                },
                {
                    "path": "Resources/Launch.storyboard",
                    "relative_path": "Resources/Base.lproj/Launch.storyboard",
                },
            ],
            "sources": [
                {"path": "App/AppDelegate.swift"},
                {"path": "App/SceneDelegate.swift"},
                {"path": "App/Model.swift"},
            ],
            "target": {
                "name": "Probe",
                "product_name": "Probe",
                "product_type": "com.apple.product-type.application",
            },
            "unsupported_features": [],
        }

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_freezes_complete_ordered_source_and_resource_graph(self) -> None:
        generated, plan = application_build_plan.plan(self.inventory, self.root)
        self.assertIn(b"extension AppDelegate", generated)
        self.assertEqual(plan["classification"], "portable-application-build-plan")
        self.assertEqual(plan["module"], "Probe")
        self.assertEqual(plan["bundle_identifier"], "org.example.Probe")
        self.assertEqual(
            [entry["path"] for entry in plan["sources"]],
            [
                "App/AppDelegate.swift",
                "App/SceneDelegate.swift",
                "App/Model.swift",
            ],
        )
        self.assertEqual(plan["summary"], {"resource_files": 3, "resource_inputs": 2, "swift_sources": 3})
        catalog = plan["resources"][0]
        self.assertEqual(catalog["kind"], "directory")
        self.assertEqual(catalog["bundle_destination"], "Assets.xcassets")
        self.assertEqual(
            plan["resources"][1]["bundle_destination"],
            "Base.lproj/Launch.storyboard",
        )
        self.assertEqual(
            [entry["path"] for entry in catalog["files"]],
            [
                "Resources/Assets.xcassets/Accent.colorset/Contents.json",
                "Resources/Assets.xcassets/Contents.json",
            ],
        )

    def test_cli_output_is_exclusive_and_contains_nul_source_manifest(self) -> None:
        inventory_path = self.parent / "inventory.json"
        inventory_path.write_text(json.dumps(self.inventory), encoding="utf-8")
        output = self.parent / "output"
        self.assertEqual(
            application_build_plan.main(
                [
                    os.fspath(inventory_path),
                    "--source-root",
                    os.fspath(self.root),
                    "--output-dir",
                    os.fspath(output),
                ]
            ),
            0,
        )
        self.assertEqual(
            (output / "app-sources.nul").read_bytes().split(b"\0")[:-1],
            [
                b"App/AppDelegate.swift",
                b"App/SceneDelegate.swift",
                b"App/Model.swift",
            ],
        )
        self.assertEqual(
            application_build_plan.main(
                [
                    os.fspath(inventory_path),
                    "--source-root",
                    os.fspath(self.root),
                    "--output-dir",
                    os.fspath(output),
                ]
            ),
            1,
        )
        self.assertEqual(
            application_build_plan.main(
                [
                    os.fspath(output / "application-build-plan.json"),
                    "--source-root",
                    os.fspath(self.root),
                    "--verify",
                ]
            ),
            0,
        )

    def test_verifier_detects_source_resource_and_info_plist_mutation(self) -> None:
        _generated, plan = application_build_plan.plan(self.inventory, self.root)
        application_build_plan.verify(plan, self.root)

        source = self.root / "App/Model.swift"
        original_source = source.read_bytes()
        source.write_text("struct Changed {}\n", encoding="utf-8")
        with self.assertRaisesRegex(application_build_plan.BuildPlanError, "source changed"):
            application_build_plan.verify(plan, self.root)
        source.write_bytes(original_source)

        resource = self.root / "Resources/Assets.xcassets/Contents.json"
        original_resource = resource.read_bytes()
        resource.write_text("{}\n", encoding="utf-8")
        with self.assertRaisesRegex(application_build_plan.BuildPlanError, "resource changed"):
            application_build_plan.verify(plan, self.root)
        resource.write_bytes(original_resource)

        plist = self.root / "Resources/Info.plist"
        original_plist = plist.read_bytes()
        plist.write_bytes(original_plist + b"\n")
        with self.assertRaisesRegex(application_build_plan.BuildPlanError, "Info.plist changed"):
            application_build_plan.verify(plan, self.root)

    def test_refuses_non_swift_sources_and_resource_symlinks(self) -> None:
        changed = copy.deepcopy(self.inventory)
        (self.root / "App/Bridge.m").write_text("void bridge(void) {}\n", encoding="utf-8")
        changed["sources"].append({"path": "App/Bridge.m"})
        with self.assertRaisesRegex(application_build_plan.BuildPlanError, "compiler provider"):
            application_build_plan.plan(changed, self.root)

        changed = copy.deepcopy(self.inventory)
        os.symlink(
            self.root / "Resources/Info.plist",
            self.root / "Resources/Assets.xcassets/linked.json",
        )
        with self.assertRaisesRegex(application_build_plan.BuildPlanError, "contains a symlink"):
            application_build_plan.plan(changed, self.root)

    def test_refuses_outputs_inside_source_tree(self) -> None:
        generated, plan = application_build_plan.plan(self.inventory, self.root)
        with self.assertRaisesRegex(application_build_plan.BuildPlanError, "outside"):
            application_build_plan._write_new_directory(
                self.root / "build-plan", generated, plan, self.root
            )

    def test_refuses_colliding_and_unsafe_resource_destinations(self) -> None:
        changed = copy.deepcopy(self.inventory)
        changed["resources"][1]["bundle_destination"] = "Assets.xcassets"
        with self.assertRaisesRegex(
            application_build_plan.BuildPlanError, "destination collision"
        ):
            application_build_plan.plan(changed, self.root)

        changed = copy.deepcopy(self.inventory)
        changed["resources"][1]["bundle_destination"] = (
            "Assets.xcassets/Nested.storyboard"
        )
        with self.assertRaisesRegex(
            application_build_plan.BuildPlanError, "destination collision"
        ):
            application_build_plan.plan(changed, self.root)

        changed = copy.deepcopy(self.inventory)
        changed["resources"][0]["bundle_destination"] = "../escape"
        with self.assertRaisesRegex(application_build_plan.BuildPlanError, "safe relative"):
            application_build_plan.plan(changed, self.root)


if __name__ == "__main__":
    unittest.main()
