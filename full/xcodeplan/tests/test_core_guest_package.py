from __future__ import annotations

import copy
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
TOOL_DIR = HERE.parent
sys.path.insert(0, os.fspath(TOOL_DIR))

import core_guest_package  # noqa: E402


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class CoreGuestPackageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="core-guest-package-test.")
        self.root = Path(self.temporary.name) / "package"
        for relative in (
            "sdk",
            "modules",
            "lib",
            "include",
            "objects",
            "resources/OpenUIKit/fonts",
            "guest-root",
            "attestation",
        ):
            (self.root / relative).mkdir(parents=True, exist_ok=True)
        required_files = [
            "resources/OpenUIKit/system_colors.json",
            "resources/OpenUIKit/font_metrics.json",
            "resources/OpenUIKit/fonts/DejaVuSans.ttf",
            "resources/OpenUIKit/fonts/DejaVuSans-Bold.ttf",
            "guest-root/machorun",
            "guest-root/.manifest",
            "objects/DeveloperToolsSupport.o",
        ]
        required_files.extend(
            f"modules/{module}.swiftmodule"
            for module in (
                "FoundationEssentials",
                "OpenCoreGraphics",
                "OpenUIKit",
                "OpenCombine",
                "Combine",
                "Foundation",
                "UIKit",
                "DeveloperToolsSupport",
            )
        )
        required_files.extend(
            f"lib/lib{module}.dylib"
            for module in (
                "FoundationEssentials",
                "OpenCoreGraphics",
                "OpenUIKit",
                "OpenCombine",
                "Combine",
                "Foundation",
                "UIKit",
            )
        )
        for relative in required_files:
            target = self.root / relative
            target.write_bytes((relative + "\n").encode("utf-8"))
        artifacts = []
        for relative in required_files:
            if relative.startswith("guest-root/"):
                continue
            path = self.root / relative
            artifacts.append(
                {"path": relative, "sha256": sha256(path), "size": path.stat().st_size}
            )
        self.manifest = {
            "artifacts": artifacts,
            "classification": "open-uikit-core-guest-package",
            "executable_link_arguments": [
                "-arch",
                "arm64",
                "-syslibroot",
                "sdk",
                "-rpath",
                "/usr/lib/swift",
                "-rpath",
                "@executable_path/../Frameworks",
                "-Llib",
            ],
            "format_version": 1,
            "paths": {
                "guest_root": "guest-root",
                "includes": "include",
                "libraries": "lib",
                "modules": "modules",
                "objects": "objects",
                "resources": "resources/OpenUIKit",
                "sdk": "sdk",
            },
            "preview": {
                "app_compile_diagnostic_arguments": [
                    "-Xfrontend",
                    "-dump-macro-expansions",
                ],
                "developer_tools_support_object": "objects/DeveloperToolsSupport.o",
                "plugin_module": "OpenUIKitPreviewMacros",
                "plugin_sha256": "a" * 64,
            },
            "swift_compile_arguments": [
                "-target",
                "arm64-apple-macos15.0",
                "-sdk",
                "sdk",
                "-I",
                "modules",
                "-Xcc",
                "-Iinclude/CPortableIO",
            ],
            "target": {"triple": "arm64-apple-macos15.0"},
        }
        self.write_manifest(self.manifest)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_manifest(self, manifest: dict) -> None:
        (self.root / "attestation/core-package.json").write_text(
            json.dumps(manifest, sort_keys=True, separators=(",", ":")) + "\n",
            encoding="utf-8",
        )

    def test_validates_and_emits_exact_argument_arrays(self) -> None:
        root, manifest = core_guest_package.validate(self.root)
        self.assertEqual(root, self.root.resolve())
        self.assertEqual(
            manifest["swift_compile_arguments"], self.manifest["swift_compile_arguments"]
        )
        self.assertEqual(
            manifest["executable_link_arguments"],
            self.manifest["executable_link_arguments"],
        )
        self.assertEqual(
            core_guest_package.main([os.fspath(self.root), "--emit-summary"]), 0
        )

    def test_refuses_artifact_mutation_and_path_symlink(self) -> None:
        (self.root / "lib/libUIKit.dylib").write_text("changed\n", encoding="utf-8")
        with self.assertRaisesRegex(core_guest_package.CorePackageError, "artifact changed"):
            core_guest_package.validate(self.root)

        (self.root / "lib/libUIKit.dylib").write_text(
            "lib/libUIKit.dylib\n", encoding="utf-8"
        )
        (self.root / "modules").rename(self.root / "real-modules")
        os.symlink(self.root / "real-modules", self.root / "modules")
        with self.assertRaisesRegex(core_guest_package.CorePackageError, "symlink"):
            core_guest_package.validate(self.root)

    def test_refuses_host_paths_and_driver_owned_options(self) -> None:
        changed = copy.deepcopy(self.manifest)
        changed["swift_compile_arguments"].extend(["-I", "/private/tmp/leak"])
        self.write_manifest(changed)
        with self.assertRaisesRegex(core_guest_package.CorePackageError, "absolute host path"):
            core_guest_package.validate(self.root)

        changed = copy.deepcopy(self.manifest)
        changed["swift_compile_arguments"].extend(["-o", "stolen.o"])
        self.write_manifest(changed)
        with self.assertRaisesRegex(core_guest_package.CorePackageError, "driver-owned"):
            core_guest_package.validate(self.root)

    def test_preview_contract_is_atomic_and_object_stays_in_objects(self) -> None:
        changed = copy.deepcopy(self.manifest)
        changed["preview"]["plugin_module"] = "WrongMacros"
        self.write_manifest(changed)
        with self.assertRaisesRegex(core_guest_package.CorePackageError, "plugin_module"):
            core_guest_package.validate(self.root)

        changed = copy.deepcopy(self.manifest)
        changed["preview"]["developer_tools_support_object"] = "lib/libUIKit.dylib"
        self.write_manifest(changed)
        with self.assertRaisesRegex(core_guest_package.CorePackageError, "outside paths.objects"):
            core_guest_package.validate(self.root)

        changed = copy.deepcopy(self.manifest)
        changed["preview"]["app_compile_diagnostic_arguments"] = ["-dump-ast"]
        self.write_manifest(changed)
        with self.assertRaisesRegex(core_guest_package.CorePackageError, "macro-expansion"):
            core_guest_package.validate(self.root)

        changed = copy.deepcopy(self.manifest)
        changed["executable_link_arguments"].append(
            "objects/DeveloperToolsSupport.o"
        )
        self.write_manifest(changed)
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError, "exactly once"
        ):
            core_guest_package.validate(self.root)


if __name__ == "__main__":
    unittest.main()
