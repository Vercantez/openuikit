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
                "SwiftUI",
                "Foundation",
                "UIKit",
                "Intents",
                "IntentsUI",
                "WebKit",
                "LocalAuthentication",
                "SafariServices",
                "Network",
                "StoreKit",
                "AudioToolbox",
                "CoreHaptics",
                "PassKit",
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
                "SwiftUI",
                "Foundation",
                "UIKit",
                "Intents",
                "IntentsUI",
                "WebKit",
                "LocalAuthentication",
                "SafariServices",
                "Network",
                "StoreKit",
                "AudioToolbox",
                "CoreHaptics",
                "PassKit",
            )
        )
        for relative in required_files:
            target = self.root / relative
            target.write_bytes((relative + "\n").encode("utf-8"))
        self.sdk_tree = self.root / "attestation/sdk-tree.tsv"
        self.sdk_tree.write_bytes(
            b"format\tcore-tree-v1\ndirectory\tsdk\tempty=yes\n"
        )
        manifest_names = (
            "artifact-ledger",
            "input-provenance",
            "source-sets",
            "foundation-sources",
            "intents-sources",
            "first-party-sources",
            "first-party-dylib-loads",
            "webkit-sources",
            "sdk-dangling-symlinks",
            "sdk-dangling-exclusions",
            "include-tree",
            "guest-root-tree",
            "openuikit-resources-tree",
            "runtime-closure",
        )
        self.manifest_files = {}
        for name in manifest_names:
            path = self.root / f"attestation/{name}.tsv"
            path.write_bytes(f"format\t{name}-v1\n".encode("utf-8"))
            self.manifest_files[name.replace("-", "_")] = path
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
                "-lFoundationEssentials",
                "-lOpenCoreGraphics",
                "-lOpenUIKit",
                "-lOpenCombine",
                "-lCombine",
                "-lSwiftUI",
                "-lFoundation",
                "-lUIKit",
                "-lIntents",
                "-lIntentsUI",
                "-lWebKit",
                "-lLocalAuthentication",
                "-lSafariServices",
                "-lNetwork",
                "-lStoreKit",
                "-lAudioToolbox",
                "-lCoreHaptics",
                "-lPassKit",
            ],
            "format_version": 1,
            "manifests": {
                **{
                    name: {
                        "path": path.relative_to(self.root).as_posix(),
                        "sha256": sha256(path),
                    }
                    for name, path in self.manifest_files.items()
                },
                "sdk_tree": {
                    "path": "attestation/sdk-tree.tsv",
                    "sha256": sha256(self.sdk_tree),
                }
            },
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

    def publish_sdk_tree(self, payload: bytes) -> None:
        self.sdk_tree.write_bytes(payload)
        self.manifest["manifests"]["sdk_tree"]["sha256"] = sha256(self.sdk_tree)
        self.write_manifest(self.manifest)

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

    def test_refuses_a_package_without_real_swiftui_module_or_dylib(self) -> None:
        for relative in (
            "modules/SwiftUI.swiftmodule",
            "lib/libSwiftUI.dylib",
        ):
            with self.subTest(relative=relative):
                changed = copy.deepcopy(self.manifest)
                changed["artifacts"] = [
                    artifact
                    for artifact in changed["artifacts"]
                    if artifact["path"] != relative
                ]
                target = self.root / relative
                target.unlink()
                self.write_manifest(changed)
                with self.assertRaisesRegex(
                    core_guest_package.CorePackageError,
                    "required artifact",
                ):
                    core_guest_package.validate(self.root)
                target.write_bytes((relative + "\n").encode("utf-8"))
                self.write_manifest(self.manifest)

    def test_refuses_missing_first_party_module_dylib_or_link_argument(self) -> None:
        for framework in ("Intents", "IntentsUI", "WebKit"):
            for relative in (
                f"modules/{framework}.swiftmodule",
                f"lib/lib{framework}.dylib",
            ):
                with self.subTest(framework=framework, relative=relative):
                    changed = copy.deepcopy(self.manifest)
                    changed["artifacts"] = [
                        artifact
                        for artifact in changed["artifacts"]
                        if artifact["path"] != relative
                    ]
                    target = self.root / relative
                    target.unlink()
                    self.write_manifest(changed)
                    with self.assertRaisesRegex(
                        core_guest_package.CorePackageError, "required artifact"
                    ):
                        core_guest_package.validate(self.root)
                    target.write_bytes((relative + "\n").encode("utf-8"))
                    self.write_manifest(self.manifest)

            changed = copy.deepcopy(self.manifest)
            changed["executable_link_arguments"].remove(f"-l{framework}")
            self.write_manifest(changed)
            with self.assertRaisesRegex(
                core_guest_package.CorePackageError,
                "required framework exactly once",
            ):
                core_guest_package.validate(self.root)
            self.write_manifest(self.manifest)

    def test_refuses_missing_intents_source_manifest(self) -> None:
        changed = copy.deepcopy(self.manifest)
        del changed["manifests"]["intents_sources"]
        self.write_manifest(changed)
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError,
            "omits required manifests: intents_sources",
        ):
            core_guest_package.validate(self.root)

    def test_refuses_missing_webkit_source_manifest(self) -> None:
        changed = copy.deepcopy(self.manifest)
        del changed["manifests"]["webkit_sources"]
        self.write_manifest(changed)
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError,
            "omits required manifests: webkit_sources",
        ):
            core_guest_package.validate(self.root)

    def test_sdk_tree_ledger_accepts_a_safe_internal_symlink(self) -> None:
        target = self.root / "sdk/usr/lib/target.tbd"
        target.parent.mkdir(parents=True)
        target.write_bytes(b"target\n")
        os.symlink("target.tbd", target.parent / "alias.tbd")
        target_hash = hashlib.sha256(target.read_bytes()).hexdigest()
        symlink_hash = hashlib.sha256(b"target.tbd").hexdigest()
        self.publish_sdk_tree(
            (
                "format\tcore-tree-v1\n"
                "directory\tsdk\tempty=no\n"
                "directory\tsdk/usr\tempty=no\n"
                "directory\tsdk/usr/lib\tempty=no\n"
                f"symlink\tsdk/usr/lib/alias.tbd\t{symlink_hash}\ttarget.tbd\n"
                f"file\tsdk/usr/lib/target.tbd\t{target_hash}\t7\n"
            ).encode("utf-8")
        )
        core_guest_package.validate(self.root)

    def test_refuses_sdk_tree_drift_and_manifest_mutation(self) -> None:
        (self.root / "sdk/unattested.tbd").write_bytes(b"stale\n")
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError, "SDK tree differs"
        ):
            core_guest_package.validate(self.root)

        (self.root / "sdk/unattested.tbd").unlink()
        self.sdk_tree.write_bytes(b"format\tcore-tree-v1\n")
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError, "manifest changed"
        ):
            core_guest_package.validate(self.root)

    def test_refuses_unsafe_sdk_symlinks_even_if_ledgers_match(self) -> None:
        dangling = self.root / "sdk/dangling.tbd"
        os.symlink("missing.tbd", dangling)
        dangling_hash = hashlib.sha256(b"missing.tbd").hexdigest()
        self.publish_sdk_tree(
            (
                "format\tcore-tree-v1\n"
                "directory\tsdk\tempty=no\n"
                f"symlink\tsdk/dangling.tbd\t{dangling_hash}\tmissing.tbd\n"
            ).encode("utf-8")
        )
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError, "dangling SDK symlink"
        ):
            core_guest_package.validate(self.root)

        dangling.unlink()
        escaping = self.root / "sdk/escaping.tbd"
        os.symlink("../outside.tbd", escaping)
        escaping_hash = hashlib.sha256(b"../outside.tbd").hexdigest()
        self.publish_sdk_tree(
            (
                "format\tcore-tree-v1\n"
                "directory\tsdk\tempty=no\n"
                f"symlink\tsdk/escaping.tbd\t{escaping_hash}\t../outside.tbd\n"
            ).encode("utf-8")
        )
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError, "escaping SDK symlink"
        ):
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

        for option in (
            "-wmo",
            "-whole-module-optimization",
            "-disable-batch-mode",
            "-enable-batch-mode",
            "-dump-macro-expansions",
            "-output-file-map",
            "-primary-file",
        ):
            with self.subTest(driver_owned=option):
                changed = copy.deepcopy(self.manifest)
                changed["swift_compile_arguments"].append(option)
                self.write_manifest(changed)
                with self.assertRaisesRegex(
                    core_guest_package.CorePackageError, "driver-owned"
                ):
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
