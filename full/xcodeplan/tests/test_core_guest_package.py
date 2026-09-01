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
            "include/CPortableIO",
            "include/CoreImage",
            "include/COpenFoundationCore",
            "include/COpenAccelerate",
            "include/COpenCompression",
            "include/COpenZlib",
            "include/zlib",
            "objects",
            "resources/OpenUIKit/fonts",
            "guest-root/host",
            "guest-root",
            "host-tools/swift/host/plugins",
            "host-tools/swift/linux",
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
            "include/CoreImage/CoreImage.h",
            "include/CoreImage/CIFilterBuiltins.h",
            "include/CoreImage/module.modulemap",
            "include/COpenFoundationCore/OpenFoundationCFError.h",
            "include/COpenFoundationCore/module.modulemap",
            "include/COpenAccelerate/Accelerate.h",
            "include/COpenAccelerate/module.modulemap",
            "include/COpenCompression/OpenCompressionABI.h",
            "include/COpenCompression/module.modulemap",
            "guest-root/host/libOpenCompressionHost.so",
            "include/COpenZlib/OpenZlibABI.h",
            "include/COpenZlib/module.modulemap",
            "include/zlib/zlib.h",
            "include/zlib/module.modulemap",
            "lib/libz.dylib",
            "guest-root/host/libOpenZlibHost.so",
            "host-tools/swift/host/plugins/libObservationMacros.so",
            "host-tools/swift/host/plugins/libFoundationMacros.so",
            "host-tools/swift/host/plugins/libSwiftDataMacros.so",
            "host-tools/swift/host/plugins/libOpenUIKitPreviewMacros.so",
            "host-tools/swift/host/plugins/libOpenSwiftUIMacros.so",
            "host-tools/swift/linux/libswiftCore.so",
        ]
        required_files.extend(
            f"modules/{module}.swiftmodule"
            for module in (
                "FoundationEssentials",
                "OpenCoreGraphics",
                "OpenUIKit",
                "OpenCombine",
                "Dispatch",
                "Combine",
                "Symbols",
                "SwiftUI",
                "_QuickLook_SwiftUI",
                "_PhotosUI_SwiftUI",
                "Foundation",
                "UIKit",
                "CoreImage",
                "QuartzCore",
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
                "CoreGraphics",
                "ImageIO",
                "LinkPresentation",
                "MessageUI",
                "MobileCoreServices",
                "Security",
                "CryptoKit",
                "CommonCrypto",
                "AppIntents",
                "OSLog",
                "UniformTypeIdentifiers",
                "SwiftData",
                "UserNotifications",
                "QuickLook",
                "CoreMedia",
                "AVFoundation",
                "AVKit",
                "Charts",
                "CoreTransferable",
                "Photos",
                "PhotosUI",
                "Accelerate",
                "Compression",
                "CoreText",
                "AdServices",
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
                "Dispatch",
                "Combine",
                "Symbols",
                "SwiftUI",
                "Foundation",
                "UIKit",
                "CoreImage",
                "QuartzCore",
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
                "CoreGraphics",
                "ImageIO",
                "LinkPresentation",
                "MessageUI",
                "MobileCoreServices",
                "Security",
                "CryptoKit",
                "CommonCrypto",
                "AppIntents",
                "OSLog",
                "UniformTypeIdentifiers",
                "SwiftData",
                "UserNotifications",
                "QuickLook",
                "_QuickLook_SwiftUI",
                "_PhotosUI_SwiftUI",
                "CoreMedia",
                "AVFoundation",
                "AVKit",
                "Charts",
                "CoreTransferable",
                "Photos",
                "PhotosUI",
                "Accelerate",
                "Compression",
                "CoreText",
                "AdServices",
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
            "graphics-sources",
            "first-party-sources",
            "first-party-dylib-loads",
            "webkit-sources",
            "sdk-dangling-symlinks",
            "sdk-dangling-exclusions",
            "include-tree",
            "guest-root-tree",
            "openuikit-resources-tree",
            "runtime-closure",
            "compiler-plugins",
        )
        self.manifest_files = {}
        for name in manifest_names:
            path = self.root / f"attestation/{name}.tsv"
            path.write_bytes(f"format\t{name}-v1\n".encode("utf-8"))
            self.manifest_files[name.replace("-", "_")] = path
        plugin_specs = (
            (
                "ObservationMacros",
                "libObservationMacros.so",
                ["ObservableMacro", "ObservationIgnoredMacro", "ObservationTrackedMacro"],
            ),
            (
                "FoundationMacros",
                "libFoundationMacros.so",
                ["ExpressionMacro", "PredicateMacro"],
            ),
            (
                "SwiftDataMacros",
                "libSwiftDataMacros.so",
                ["PersistentModelMacro"],
            ),
            (
                "OpenUIKitPreviewMacros",
                "libOpenUIKitPreviewMacros.so",
                ["UIKitPreviewMacro"],
            ),
            (
                "OpenSwiftUIMacros",
                "libOpenSwiftUIMacros.so",
                ["EntryMacro"],
            ),
        )
        closure_relative = "host-tools/swift/linux/libswiftCore.so"
        compiler_plugins = []
        for module, basename, registrations in plugin_specs:
            relative = f"host-tools/swift/host/plugins/{basename}"
            compiler_plugins.append(
                {
                    "module": module,
                    "load_kind": "library",
                    "path": relative,
                    "sha256": sha256(self.root / relative),
                    "registrations": registrations,
                    "consumer_scopes": ["app", "framework", "package"],
                    "serialized_jobs": False,
                    "host_closure": [
                        {
                            "path": closure_relative,
                            "sha256": sha256(self.root / closure_relative),
                        }
                    ],
                }
            )
        plugin_lines = ["format\tcore-compiler-plugins-v1"]
        for plugin in compiler_plugins:
            plugin_lines.append(
                "\t".join(
                    (
                        "plugin", plugin["module"], plugin["load_kind"],
                        plugin["path"], plugin["sha256"],
                        ",".join(plugin["registrations"]),
                        ",".join(plugin["consumer_scopes"]), "serialized=no",
                    )
                )
            )
        for plugin in compiler_plugins:
            for item in plugin["host_closure"]:
                plugin_lines.append(
                    "\t".join(
                        ("closure", plugin["module"], item["path"], item["sha256"])
                    )
                )
        self.manifest_files["compiler_plugins"].write_text(
            "\n".join(plugin_lines) + "\n", encoding="utf-8"
        )
        artifacts = []
        for relative in required_files:
            if relative in ("guest-root/machorun", "guest-root/.manifest"):
                continue
            path = self.root / relative
            category, name, role = "framework", "Fixture", "fixture"
            if "/plugins/lib" in relative:
                category, role = "host-tool", "plugin"
                name = Path(relative).stem.removeprefix("lib")
            elif relative.startswith("host-tools/"):
                category, name, role = "host-tool", "CompilerPluginClosure", "dependency"
            elif relative.startswith("guest-root/host/"):
                category, name, role = "host-tool", "OpenCompressionHost", "runtime"
            artifacts.append(
                {
                    "category": category,
                    "name": name,
                    "role": role,
                    "path": relative,
                    "sha256": sha256(path),
                    "size": path.stat().st_size,
                }
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
                "-lDispatch",
                "-lCombine",
                "-lSymbols",
                "-lSwiftUI",
                "-l_QuickLook_SwiftUI",
                "-l_PhotosUI_SwiftUI",
                "-lFoundation",
                "-lUIKit",
                "-lCoreImage",
                "-lQuartzCore",
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
                "-lCoreGraphics",
                "-lImageIO",
                "-lLinkPresentation",
                "-lMessageUI",
                "-lMobileCoreServices",
                "-lSecurity",
                "-lCryptoKit",
                "-lCommonCrypto",
                "-lAppIntents",
                "-lOSLog",
                "-lUniformTypeIdentifiers",
                "-lSwiftData",
                "-lUserNotifications",
                "-lQuickLook",
                "-lCoreMedia",
                "-lAVFoundation",
                "-lAVKit",
                "-lCharts",
                "-lCoreTransferable",
                "-lPhotos",
                "-lPhotosUI",
                "-lAccelerate",
                "-lCompression",
                "-lCoreText",
                "-lAdServices",
                "-lz",
            ],
            "format_version": 1,
            "compiler_plugins": compiler_plugins,
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
                "host_tools": "host-tools",
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
                "-Xfrontend",
                "-enable-cross-import-overlays",
                "-load-plugin-library",
                "host-tools/swift/host/plugins/libObservationMacros.so",
                "-load-plugin-library",
                "host-tools/swift/host/plugins/libFoundationMacros.so",
                "-load-plugin-library",
                "host-tools/swift/host/plugins/libSwiftDataMacros.so",
                "-load-plugin-library",
                "host-tools/swift/host/plugins/libOpenUIKitPreviewMacros.so",
                "-load-plugin-library",
                "host-tools/swift/host/plugins/libOpenSwiftUIMacros.so",
                "-I",
                "modules",
                "-Xcc",
                "-Iinclude/CPortableIO",
                "-Xcc",
                "-fmodule-map-file=include/CoreImage/module.modulemap",
                "-Xcc",
                "-Iinclude/CoreImage",
                "-Xcc",
                "-fmodule-map-file=include/COpenFoundationCore/module.modulemap",
                "-Xcc",
                "-Iinclude/COpenFoundationCore",
                "-Xcc",
                "-fmodule-map-file=include/COpenAccelerate/module.modulemap",
                "-Xcc",
                "-Iinclude/COpenAccelerate",
                "-Xcc",
                "-fmodule-map-file=include/COpenCompression/module.modulemap",
                "-Xcc",
                "-Iinclude/COpenCompression",
                "-Xcc",
                "-fmodule-map-file=include/zlib/module.modulemap",
                "-Xcc",
                "-Iinclude/zlib",
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

    def test_compiler_plugin_json_cannot_diverge_from_attested_transport(self) -> None:
        changed = copy.deepcopy(self.manifest)
        changed["compiler_plugins"][2]["registrations"] = ["DifferentMacro"]
        self.write_manifest(changed)
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError,
            "differs from manifests.compiler_plugins",
        ):
            core_guest_package.validate(self.root)

    def test_roots_every_package_compile_path_for_pcm_identity(self) -> None:
        root, manifest = core_guest_package.validate(self.root)
        arguments = core_guest_package.rooted_swift_compile_arguments(
            root, manifest["swift_compile_arguments"]
        )
        self.assertEqual(
            arguments[arguments.index("-sdk") + 1], os.fspath(root / "sdk")
        )
        self.assertEqual(
            arguments[arguments.index("-I") + 1], os.fspath(root / "modules")
        )
        for plugin in self.manifest["compiler_plugins"]:
            self.assertEqual(arguments.count(os.fspath(root / plugin["path"])), 1)
        self.assertIn(f"-I{root}/include/CPortableIO", arguments)
        self.assertIn(
            f"-fmodule-map-file={root}/include/CoreImage/module.modulemap",
            arguments,
        )
        self.assertIn(f"-I{root}/include/CoreImage", arguments)
        self.assertIn(
            f"-fmodule-map-file={root}/include/COpenFoundationCore/module.modulemap",
            arguments,
        )
        self.assertIn(f"-I{root}/include/COpenFoundationCore", arguments)
        self.assertIn(
            f"-fmodule-map-file={root}/include/COpenAccelerate/module.modulemap",
            arguments,
        )
        self.assertIn(f"-I{root}/include/COpenAccelerate", arguments)
        self.assertIn(
            f"-fmodule-map-file={root}/include/COpenCompression/module.modulemap",
            arguments,
        )
        self.assertIn(f"-I{root}/include/COpenCompression", arguments)
        self.assertNotIn("sdk", arguments)
        self.assertNotIn("modules", arguments)
        self.assertFalse(
            any(
                argument.startswith(("-Iinclude/", "-fmodule-map-file=include/"))
                for argument in arguments
            )
        )

    def test_refuses_unattested_host_tool(self) -> None:
        stale = self.root / "host-tools/swift/host/libStale.so"
        stale.write_bytes(b"stale\n")
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError,
            "does not attest every required artifact: host-tools/swift/host/libStale.so",
        ):
            core_guest_package.validate(self.root)

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
        for framework in (
            "Intents",
            "IntentsUI",
            "WebKit",
            "CoreMedia",
            "AVFoundation",
            "AVKit",
            "Charts",
            "CoreTransferable",
            "Photos",
            "PhotosUI",
            "Accelerate",
            "Compression",
            "CoreText",
        ):
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

    def test_refuses_missing_graphics_source_manifest(self) -> None:
        changed = copy.deepcopy(self.manifest)
        del changed["manifests"]["graphics_sources"]
        self.write_manifest(changed)
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError,
            "omits required manifests: graphics_sources",
        ):
            core_guest_package.validate(self.root)

    def test_refuses_missing_coreimage_compile_contract(self) -> None:
        changed = copy.deepcopy(self.manifest)
        pair_end = changed["swift_compile_arguments"].index(
            "-Iinclude/CoreImage"
        ) + 1
        del changed["swift_compile_arguments"][pair_end - 2 : pair_end]
        self.write_manifest(changed)
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError,
            "CoreImage underlying-module pair",
        ):
            core_guest_package.validate(self.root)

    def test_refuses_missing_cferror_compile_contract(self) -> None:
        changed = copy.deepcopy(self.manifest)
        pair_end = changed["swift_compile_arguments"].index(
            "-Iinclude/COpenFoundationCore"
        ) + 1
        del changed["swift_compile_arguments"][pair_end - 2 : pair_end]
        self.write_manifest(changed)
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError,
            "Foundation CFError Clang module pair",
        ):
            core_guest_package.validate(self.root)

    def test_refuses_missing_frontier_c_compile_contract(self) -> None:
        for module in ("COpenAccelerate", "COpenCompression"):
            with self.subTest(module=module):
                changed = copy.deepcopy(self.manifest)
                pair_end = changed["swift_compile_arguments"].index(
                    f"-Iinclude/{module}"
                ) + 1
                del changed["swift_compile_arguments"][pair_end - 2 : pair_end]
                self.write_manifest(changed)
                with self.assertRaisesRegex(
                    core_guest_package.CorePackageError,
                    f"portable {module} Clang module pair",
                ):
                    core_guest_package.validate(self.root)
                self.write_manifest(self.manifest)

    def test_refuses_missing_compression_host_runtime(self) -> None:
        relative = "guest-root/host/libOpenCompressionHost.so"
        changed = copy.deepcopy(self.manifest)
        changed["artifacts"] = [
            artifact
            for artifact in changed["artifacts"]
            if artifact["path"] != relative
        ]
        (self.root / relative).unlink()
        self.write_manifest(changed)
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError,
            "required artifact",
        ):
            core_guest_package.validate(self.root)

    def test_refuses_missing_cross_import_overlay_compile_contract(self) -> None:
        changed = copy.deepcopy(self.manifest)
        pair_end = changed["swift_compile_arguments"].index(
            "-enable-cross-import-overlays"
        ) + 1
        del changed["swift_compile_arguments"][pair_end - 2 : pair_end]
        self.write_manifest(changed)
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError,
            "enable Swift cross-import overlays",
        ):
            core_guest_package.validate(self.root)

    def test_refuses_duplicate_cross_import_overlay_compile_contract(self) -> None:
        changed = copy.deepcopy(self.manifest)
        pair_end = changed["swift_compile_arguments"].index(
            "-enable-cross-import-overlays"
        ) + 1
        changed["swift_compile_arguments"][pair_end:pair_end] = [
            "-Xfrontend",
            "-enable-cross-import-overlays",
        ]
        self.write_manifest(changed)
        with self.assertRaisesRegex(
            core_guest_package.CorePackageError,
            "enable Swift cross-import overlays",
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
