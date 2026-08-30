from __future__ import annotations

import copy
import contextlib
import io
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

import scene_bootstrap  # noqa: E402


APP_SOURCE = b"""\
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {}
"""

SCENE_SOURCE = b"""\
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
}
"""


class SceneBootstrapTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="scene-bootstrap-test.")
        self.parent = Path(self.temporary.name)
        self.root = self.parent / "subject"
        (self.root / "App").mkdir(parents=True)
        (self.root / "Resources").mkdir()
        (self.root / "App/AppDelegate.swift").write_bytes(APP_SOURCE)
        (self.root / "App/SceneDelegate.swift").write_bytes(SCENE_SOURCE)
        self.write_plist()
        self.inventory = {
            "configuration": {
                "project": {"build_settings": {}},
                "target": {
                    "build_settings": {
                        "INFOPLIST_FILE": "Resources/Info.plist",
                        "PRODUCT_NAME": "Probe",
                    }
                },
            },
            "format_version": 1,
            "missing_inputs": [],
            "sources": [
                {"path": "App/AppDelegate.swift"},
                {"path": "App/SceneDelegate.swift"},
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

    def write_plist(
        self,
        *,
        delegate: str = "$(PRODUCT_MODULE_NAME).SceneDelegate",
        multiple: bool = False,
        scene_class: str | None = None,
        storyboard: str | None = None,
    ) -> None:
        configuration: dict[str, object] = {
            "UISceneConfigurationName": "Default Configuration",
            "UISceneDelegateClassName": delegate,
        }
        if scene_class is not None:
            configuration["UISceneClassName"] = scene_class
        if storyboard is not None:
            configuration["UISceneStoryboardFile"] = storyboard
        value = {
            "UIApplicationSceneManifest": {
                "UIApplicationSupportsMultipleScenes": multiple,
                "UISceneConfigurations": {
                    "UIWindowSceneSessionRoleApplication": [configuration]
                },
            }
        }
        (self.root / "Resources/Info.plist").write_bytes(
            plistlib.dumps(value, sort_keys=True)
        )

    def generate(self, inventory: dict | None = None):
        return scene_bootstrap.generate(inventory or self.inventory, self.root)

    def test_generates_exact_build_input_and_provenance(self) -> None:
        generated, record = self.generate()
        self.assertEqual(
            generated.decode("utf-8"),
            """\
import UIKit

// Generated build input: portable UIKit supplies this method on Linux.
extension AppDelegate {
    @MainActor
    static func main() {
        let appDelegate = AppDelegate()
        let application = UIApplicationMain(delegate: appDelegate)
        let scene = application._hostConnectWindowScene(delegate: SceneDelegate())
        application._hostDidBecomeActive()
        PortableUIKitApplicationHost.run(application: application, scene: scene)
    }
}
""",
        )
        self.assertEqual(record["classification"], "generated-build-input")
        self.assertEqual(record["module"], "Probe")
        self.assertEqual(record["inventory_swift_source_count"], 2)
        self.assertEqual(record["app_delegate"]["path"], "App/AppDelegate.swift")
        self.assertEqual(record["scene_delegate"]["path"], "App/SceneDelegate.swift")
        self.assertEqual(record["generated_size"], len(generated))
        self.assertEqual(
            record["generated_sha256"], scene_bootstrap._sha256(generated)
        )

    def test_comments_and_all_swift_string_forms_cannot_inject_main(self) -> None:
        noise = self.root / "App/Noise.swift"
        noise.write_text(
            '''
// @main class Fake: UIApplicationDelegate {}
/* outer /* @main class Nested: UIApplicationDelegate {} */ end */
let normal = "@main class StringFake: UIApplicationDelegate {}"
let multiline = """
@main class MultilineFake: UIApplicationDelegate {}
"""
let raw = #"@main class RawFake: UIApplicationDelegate {}"#
''',
            encoding="utf-8",
        )
        changed = copy.deepcopy(self.inventory)
        changed["sources"].append({"path": "App/Noise.swift"})
        generated, _ = self.generate(changed)
        self.assertIn(b"extension AppDelegate", generated)

    def test_requires_one_direct_main_app_delegate(self) -> None:
        (self.root / "App/AppDelegate.swift").write_text(
            "@main\nstruct PortableApp {}\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(
            scene_bootstrap.BootstrapError, "not a class directly conforming"
        ):
            self.generate()

        (self.root / "App/AppDelegate.swift").write_bytes(APP_SOURCE)
        extra = self.root / "App/Other.swift"
        extra.write_text(
            "@main class Other: UIResponder, UIApplicationDelegate {}\n",
            encoding="utf-8",
        )
        changed = copy.deepcopy(self.inventory)
        changed["sources"].append({"path": "App/Other.swift"})
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "found 2"):
            self.generate(changed)

    def test_scene_delegate_must_match_plist_and_shipping_source(self) -> None:
        self.write_plist(delegate="Probe.MissingDelegate")
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "found 0"):
            self.generate()

        self.write_plist(delegate="OtherModule.SceneDelegate")
        with self.assertRaisesRegex(
            scene_bootstrap.BootstrapError, "unexpected module"
        ):
            self.generate()

        self.write_plist(delegate="$(UNRESOLVED).SceneDelegate")
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "unresolved"):
            self.generate()

    def test_rejects_cross_file_private_delegates_before_emission(self) -> None:
        (self.root / "App/AppDelegate.swift").write_text(
            "@main private class AppDelegate: UIResponder, UIApplicationDelegate {}\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            scene_bootstrap.BootstrapError, "private/fileprivate"
        ):
            self.generate()

        (self.root / "App/AppDelegate.swift").write_bytes(APP_SOURCE)
        (self.root / "App/SceneDelegate.swift").write_text(
            "private class SceneDelegate: UIResponder, UIWindowSceneDelegate {}\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            scene_bootstrap.BootstrapError, "private/fileprivate"
        ):
            self.generate()

        (self.root / "App/SceneDelegate.swift").write_text(
            "fileprivate class SceneDelegate: UIResponder, UIWindowSceneDelegate {}\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            scene_bootstrap.BootstrapError, "private/fileprivate"
        ):
            self.generate()

    def test_rejects_unproven_zero_argument_delegate_construction(self) -> None:
        (self.root / "App/SceneDelegate.swift").write_text(
            "class SceneDelegate: UIResponder, UIWindowSceneDelegate {\n"
            "    init(value: Int) {}\n"
            "}\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            scene_bootstrap.BootstrapError, "zero-argument construction is not proven"
        ):
            self.generate()

        (self.root / "App/SceneDelegate.swift").write_text(
            "class SceneDelegate: CustomResponder, UIWindowSceneDelegate {}\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            scene_bootstrap.BootstrapError, "must directly inherit UIResponder"
        ):
            self.generate()

        (self.root / "App/SceneDelegate.swift").write_bytes(SCENE_SOURCE)
        (self.root / "App/AppDelegate.swift").write_text(
            "@main class AppDelegate: UIResponder, UIApplicationDelegate {\n"
            "    override init() { super.init() }\n"
            "}\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(
            scene_bootstrap.BootstrapError, "zero-argument construction is not proven"
        ):
            self.generate()

    def test_rejects_runtime_shapes_not_implemented_by_first_slice(self) -> None:
        self.write_plist(multiple=True)
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "multiple-scene"):
            self.generate()

        self.write_plist(scene_class="Probe.CustomScene")
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "custom scene"):
            self.generate()

        self.write_plist(storyboard="Main")
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "storyboard"):
            self.generate()

    def test_rejects_incomplete_or_nonapplication_inventory(self) -> None:
        for field, value, message in (
            ("unsupported_features", ["shell phase"], "unsupported"),
            ("missing_inputs", [{"path": "Missing.swift"}], "missing"),
        ):
            changed = copy.deepcopy(self.inventory)
            changed[field] = value
            with self.assertRaisesRegex(scene_bootstrap.BootstrapError, message):
                self.generate(changed)

        changed = copy.deepcopy(self.inventory)
        changed["target"]["product_type"] = "com.apple.product-type.framework"
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "application target"):
            self.generate(changed)

    def test_rejects_path_escape_symlink_and_duplicate_source(self) -> None:
        changed = copy.deepcopy(self.inventory)
        changed["sources"][0]["path"] = "../AppDelegate.swift"
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "safe relative"):
            self.generate(changed)

        link = self.root / "App/Linked.swift"
        link.symlink_to(self.root / "App/AppDelegate.swift")
        changed = copy.deepcopy(self.inventory)
        changed["sources"][0]["path"] = "App/Linked.swift"
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "symlink"):
            self.generate(changed)

        changed = copy.deepcopy(self.inventory)
        changed["sources"].append({"path": "App/AppDelegate.swift"})
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "duplicate source"):
            self.generate(changed)

    def test_output_is_exclusive_and_outside_source_tree(self) -> None:
        generated, _ = self.generate()
        output = self.parent / "generated.swift"
        scene_bootstrap._write_exclusive(output, generated, self.root)
        self.assertEqual(output.read_bytes(), generated)
        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "cannot create"):
            scene_bootstrap._write_exclusive(output, generated, self.root)

        with self.assertRaisesRegex(scene_bootstrap.BootstrapError, "outside"):
            scene_bootstrap._write_exclusive(
                self.root / "generated.swift", generated, self.root
            )
        self.assertFalse((self.root / "generated.swift").exists())

    def test_cli_writes_record_and_refuses_overwrite(self) -> None:
        inventory_path = self.parent / "inventory.json"
        inventory_path.write_text(
            json.dumps(self.inventory, sort_keys=True), encoding="utf-8"
        )
        output = self.parent / "bootstrap.swift"
        stdout = io.StringIO()
        arguments = [
            os.fspath(inventory_path),
            "--source-root",
            os.fspath(self.root),
            "--output",
            os.fspath(output),
        ]
        with contextlib.redirect_stdout(stdout):
            self.assertEqual(scene_bootstrap.main(arguments), 0)
        record = json.loads(stdout.getvalue())
        self.assertEqual(record["classification"], "generated-build-input")
        self.assertTrue(output.read_text(encoding="utf-8").startswith("import UIKit\n"))
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            self.assertEqual(scene_bootstrap.main(arguments), 1)
        self.assertIn("File exists", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
