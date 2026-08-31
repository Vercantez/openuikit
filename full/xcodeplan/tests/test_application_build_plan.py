from __future__ import annotations

import copy
import hashlib
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

    def add_intentdefinition(self) -> list[str]:
        inputs = [
            "App/Base.lproj/Intents.intentdefinition",
            "App/fr.lproj/Intents.strings",
            "App/de.lproj/Intents.strings",
        ]
        contents = (
            b"intent-definition-v1\n",
            b'"intent.title" = "Bloquer";\n',
            b'"intent.title" = "Blockieren";\n',
        )
        for relative, payload in zip(inputs, contents, strict=True):
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(payload)
        self.inventory["sources"].insert(
            1,
            {
                "path": "App/Intents.intentdefinition",
                "variant_paths": inputs,
            },
        )
        return inputs

    def use_swiftui_app(self) -> None:
        (self.root / "App/AppDelegate.swift").write_text(
            "import UIKit\n"
            "final class AppDelegate: NSObject, UIApplicationDelegate {}\n",
            encoding="utf-8",
        )
        (self.root / "App/ProbeApp.swift").write_text(
            "import SwiftUI\n"
            "import UIKit\n"
            "@main struct ProbeApp: App {\n"
            "    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate\n"
            "    var body: some Scene { WindowGroup { Text(\"Probe\") } }\n"
            "}\n",
            encoding="utf-8",
        )
        self.inventory["sources"].append({"path": "App/ProbeApp.swift"})
        (self.root / "Resources/Info.plist").write_bytes(
            plistlib.dumps({"CFBundleName": "Probe"}, sort_keys=True)
        )

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
        self.assertEqual(
            plan["summary"],
            {
                "compiler_input_files": 0,
                "compiler_inputs": 0,
                "resource_files": 3,
                "resource_inputs": 2,
                "swift_sources": 3,
            },
        )
        self.assertEqual(plan["compiler_inputs"], [])
        self.assertEqual(plan["format_version"], 2)
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

        legacy = copy.deepcopy(plan)
        del legacy["bootstrap"]["entry_point"]
        application_build_plan.verify(legacy, self.root)

    def test_swiftui_app_plan_freezes_default_main_without_scene_requirements(self) -> None:
        self.use_swiftui_app()
        generated, plan = application_build_plan.plan(self.inventory, self.root)

        self.assertEqual(
            generated,
            b"// Generated build input: ProbeApp inherits SwiftUI.App's default main; "
            b"no competing entry point is emitted.\n",
        )
        self.assertNotIn(b"static func main", generated)
        self.assertEqual(
            plan["bootstrap"]["entry_point"], "swiftui-app-default-main"
        )
        self.assertEqual(
            plan["bootstrap"]["swiftui_app"],
            {
                "path": "App/ProbeApp.swift",
                "sha256": hashlib.sha256(
                    (self.root / "App/ProbeApp.swift").read_bytes()
                ).hexdigest(),
                "type": "ProbeApp",
            },
        )
        self.assertNotIn("scene_delegate", plan["bootstrap"])
        self.assertEqual(plan["summary"]["swift_sources"], 4)
        application_build_plan.verify(plan, self.root)

        for name, mutate in {
            "entry": lambda value: value["bootstrap"].__setitem__(
                "entry_point", "uikit-scene-bootstrap"
            ),
            "type": lambda value: value["bootstrap"]["swiftui_app"].__setitem__(
                "type", "OtherApp"
            ),
            "generated": lambda value: value["bootstrap"].__setitem__(
                "generated_sha256", "0" * 64
            ),
            "schema": lambda value: value["bootstrap"].__setitem__(
                "unexpected", True
            ),
        }.items():
            with self.subTest(mutation=name):
                changed = copy.deepcopy(plan)
                mutate(changed)
                with self.assertRaises(application_build_plan.BuildPlanError):
                    application_build_plan.verify(changed, self.root)

    def test_local_package_graph_is_embedded_verified_and_materialized(self) -> None:
        package = self.root / "LocalKit"
        (package / "Sources/LocalKit").mkdir(parents=True)
        (package / "Package.swift").write_text(
            "// swift-tools-version: 6.4\n"
            "import PackageDescription\n"
            "let package = Package(\n"
            "  name: \"LocalKit\",\n"
            "  products: [.library(name: \"LocalKit\", targets: [\"LocalKit\"])],\n"
            "  targets: [.target(name: \"LocalKit\")]\n"
            ")\n",
            encoding="utf-8",
        )
        source = package / "Sources/LocalKit/LocalKit.swift"
        source.write_text("public struct LocalKit {}\n", encoding="utf-8")
        self.inventory["local_package_references"] = [
            {"relative_path": "LocalKit"}
        ]
        self.inventory["package_products"] = [
            {
                "name": "LocalKit",
                "origin": "local",
                "relative_path": "LocalKit",
            }
        ]

        generated, plan = application_build_plan.plan(self.inventory, self.root)
        graph = plan["local_package_graph"]
        self.assertEqual(graph["summary"]["local_targets"], 1)
        self.assertEqual(graph["targets"][0]["target_id"], "LocalKit#LocalKit")
        application_build_plan.verify(plan, self.root)

        output = self.parent / "package-output"
        application_build_plan._write_new_directory(
            output, generated, plan, self.root
        )
        self.assertEqual(
            (output / "local-package-targets.nul").read_bytes(),
            b"LocalKit#LocalKit\0",
        )
        prepared = json.loads(
            (output / "prepared-inputs.json").read_text(encoding="utf-8")
        )
        self.assertIn("local-package-graph.json", prepared)
        self.assertIn("local-package-targets.nul", prepared)

        source.write_text("public struct Changed {}\n", encoding="utf-8")
        with self.assertRaises(application_build_plan.BuildPlanError):
            application_build_plan.verify(plan, self.root)

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
        self.assertEqual((output / "compiler-inputs.nul").read_bytes(), b"")
        prepared = json.loads(
            (output / "prepared-inputs.json").read_text(encoding="utf-8")
        )
        self.assertEqual(
            set(prepared),
            {
                "GeneratedSceneBootstrap.swift",
                "app-sources.nul",
                "application-build-plan.json",
                "compiler-inputs.nul",
            },
        )
        self.assertEqual(
            prepared["compiler-inputs.nul"], hashlib.sha256(b"").hexdigest()
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

    def test_classifies_and_attests_localized_intentdefinition_inputs(self) -> None:
        inputs = self.add_intentdefinition()
        generated, plan = application_build_plan.plan(self.inventory, self.root)
        self.assertEqual(
            [entry["path"] for entry in plan["sources"]],
            [
                "App/AppDelegate.swift",
                "App/SceneDelegate.swift",
                "App/Model.swift",
            ],
        )
        self.assertEqual(len(plan["compiler_inputs"]), 1)
        compiler_input = plan["compiler_inputs"][0]
        self.assertEqual(
            {key: compiler_input[key] for key in ("provider", "logical_path", "primary_path")},
            {
                "provider": "open-intentdefinition",
                "logical_path": "App/Intents.intentdefinition",
                "primary_path": "App/Base.lproj/Intents.intentdefinition",
            },
        )
        self.assertEqual(
            [entry["path"] for entry in compiler_input["input_files"]], inputs
        )
        for record in compiler_input["input_files"]:
            payload = (self.root / record["path"]).read_bytes()
            self.assertEqual(record["sha256"], hashlib.sha256(payload).hexdigest())
            self.assertEqual(record["size"], len(payload))
        self.assertEqual(plan["summary"]["compiler_inputs"], 1)
        self.assertEqual(plan["summary"]["compiler_input_files"], 3)
        application_build_plan.verify(plan, self.root)

        output = self.parent / "intent-output"
        application_build_plan._write_new_directory(
            output, generated, plan, self.root
        )
        self.assertEqual(
            (output / "compiler-inputs.nul").read_bytes(),
            b"".join(relative.encode("utf-8") + b"\0" for relative in inputs),
        )
        prepared = json.loads(
            (output / "prepared-inputs.json").read_text(encoding="utf-8")
        )
        self.assertEqual(
            prepared["compiler-inputs.nul"],
            hashlib.sha256((output / "compiler-inputs.nul").read_bytes()).hexdigest(),
        )

    def test_direct_intentdefinition_input_is_one_compiler_record(self) -> None:
        path = self.root / "App/Direct.intentdefinition"
        path.write_bytes(b"direct-intent\n")
        self.inventory["sources"].append({"path": "App/Direct.intentdefinition"})
        _generated, plan = application_build_plan.plan(self.inventory, self.root)
        compiler_input = plan["compiler_inputs"][0]
        self.assertEqual(compiler_input["logical_path"], "App/Direct.intentdefinition")
        self.assertEqual(compiler_input["primary_path"], "App/Direct.intentdefinition")
        self.assertEqual(
            [record["path"] for record in compiler_input["input_files"]],
            ["App/Direct.intentdefinition"],
        )
        application_build_plan.verify(plan, self.root)

    def test_verifier_detects_every_compiler_input_byte_and_schema_change(self) -> None:
        inputs = self.add_intentdefinition()
        _generated, plan = application_build_plan.plan(self.inventory, self.root)

        for relative in inputs:
            with self.subTest(mutated=relative):
                path = self.root / relative
                original = path.read_bytes()
                path.write_bytes(original + b"mutation")
                with self.assertRaisesRegex(
                    application_build_plan.BuildPlanError,
                    "compiler input changed",
                ):
                    application_build_plan.verify(plan, self.root)
                path.write_bytes(original)

        mutations = {
            "provider": lambda value: value["compiler_inputs"][0].__setitem__(
                "provider", "unknown"
            ),
            "logical": lambda value: value["compiler_inputs"][0].__setitem__(
                "logical_path", "App/Other.intentdefinition"
            ),
            "primary": lambda value: value["compiler_inputs"][0].__setitem__(
                "primary_path", inputs[1]
            ),
            "order": lambda value: value["compiler_inputs"][0]["input_files"].reverse(),
            "hash": lambda value: value["compiler_inputs"][0]["input_files"][0].__setitem__(
                "sha256", "0" * 64
            ),
            "extra": lambda value: value["compiler_inputs"][0].__setitem__(
                "unexpected", True
            ),
        }
        for name, mutate in mutations.items():
            with self.subTest(schema=name):
                changed = copy.deepcopy(plan)
                mutate(changed)
                with self.assertRaises(application_build_plan.BuildPlanError):
                    application_build_plan.verify(changed, self.root)

        changed = copy.deepcopy(plan)
        del changed["compiler_inputs"]
        with self.assertRaisesRegex(
            application_build_plan.BuildPlanError, "compiler_inputs"
        ):
            application_build_plan.verify(changed, self.root)

        changed = copy.deepcopy(plan)
        changed["compiler_inputs"] = []
        with self.assertRaisesRegex(
            application_build_plan.BuildPlanError, "summary"
        ):
            application_build_plan.verify(changed, self.root)

        changed = copy.deepcopy(plan)
        changed["compiler_inputs"].append(
            copy.deepcopy(changed["compiler_inputs"][0])
        )
        with self.assertRaisesRegex(
            application_build_plan.BuildPlanError, "repeats compiler input"
        ):
            application_build_plan.verify(changed, self.root)

        changed = copy.deepcopy(plan)
        changed["summary"]["compiler_input_files"] += 1
        with self.assertRaisesRegex(
            application_build_plan.BuildPlanError, "summary"
        ):
            application_build_plan.verify(changed, self.root)

    def test_refuses_unsupported_intentdefinition_variant_topologies(self) -> None:
        inputs = self.add_intentdefinition()
        base_entry = copy.deepcopy(self.inventory["sources"][1])
        cases = {
            "empty": [],
            "no-primary": inputs[1:],
            "multiple-primary": [inputs[0], "App/fr.lproj/Intents.intentdefinition"],
            "primary-not-first": [inputs[1], inputs[0]],
            "wrong-type": [inputs[0], "App/fr.lproj/Intents.json"],
            "wrong-stem": [inputs[0], "App/fr.lproj/Other.strings"],
            "not-localized": ["App/Intents.intentdefinition", inputs[1]],
            "duplicate": [inputs[0], inputs[1], inputs[1]],
            "aliased-locale": [inputs[0], inputs[1], "App/FR.lproj/Intents.strings"],
        }
        for name, variants in cases.items():
            with self.subTest(name=name):
                changed = copy.deepcopy(self.inventory)
                changed["sources"][1] = copy.deepcopy(base_entry)
                changed["sources"][1]["variant_paths"] = variants
                for relative in variants:
                    path = self.root / relative
                    if path.exists():
                        continue
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(b"unsupported topology fixture\n")
                with self.assertRaises(application_build_plan.BuildPlanError):
                    application_build_plan.plan(changed, self.root)

        linked = self.root / "App/es.lproj/Intents.strings"
        linked.parent.mkdir(parents=True, exist_ok=True)
        linked.symlink_to(self.root / inputs[1])
        changed = copy.deepcopy(self.inventory)
        changed["sources"][1]["variant_paths"] = [
            inputs[0],
            "App/es.lproj/Intents.strings",
        ]
        with self.assertRaisesRegex(
            application_build_plan.BuildPlanError, "symlink"
        ):
            application_build_plan.plan(changed, self.root)

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
