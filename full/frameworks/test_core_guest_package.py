#!/usr/bin/env python3
"""Static and manifest-contract tests for the cold core guest package."""

from __future__ import annotations

import copy
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
TOOL = HERE / "core_package_manifest.py"
BUILDER = HERE / "build_core_guest_package.sh"
FOUNDATION_COMPATIBILITY_PROBE = HERE / "FoundationHackersCompatibilityProbe.swift"
BUILD_FULL = REPO / "full/scripts/build_full.sh"
HOST_WRAPPER = HERE / "run_core_guest_package_docker.sh"
PHYSICAL_REPLAY_TOOL = HERE / "physical_replay.py"
SINGLE_BIND_GUEST_ROOT_SMOKE = HERE / "test_single_bind_guest_root_docker.sh"
APP_DRIVER = REPO / "full/xcodeplan/build_portable_application_guest.sh"
PREVIEW_EXECUTABLE_EXPORT_SYMBOL = (
    "_$s21DeveloperToolsSupport7PreviewV14_openUIKitBodyACypyScMYcc_tcfC"
)
CANONICAL_VALIDATOR = REPO / "full/xcodeplan/core_guest_package.py"
CORE_FRESH_PATHS = (
    "w/build",
    "w/scratch/modcache_full",
    "w/scratch/modcache_fe4",
    "w/scratch/mrroot_full",
)
CORE_TMPFS_PATHS = (
    "/tmp:rw,exec,nosuid,nodev,mode=1777",
)
CORE_FRESH_PATH_BLOCK = "FRESH_PATHS=(\n" + "".join(
    f"    {path}\n" for path in CORE_FRESH_PATHS
) + ")"
FOUNDATION_RUNTIME_LINK_CONTRACT = (
    (
        "-lswift_StringProcessing",
        "/usr/lib/swift/libswift_StringProcessing.dylib",
        1,
    ),
    (
        "-lswiftSynchronization",
        "/usr/lib/swift/libswiftSynchronization.dylib",
        2,
    ),
    (
        "-lswiftDarwin",
        "/usr/lib/swift/libswiftDarwin.dylib",
        1,
    ),
    (
        "-lswift_Concurrency",
        "/usr/lib/swift/libswift_Concurrency.dylib",
        1,
    ),
)
SWIFTUI_RUNTIME_LINK_CONTRACT = (
    "-lswift_Concurrency",
    "/usr/lib/swift/libswift_Concurrency.dylib",
)
FOUNDATION_RUNTIME_UNDEFINED_CONTRACT = (
    ("EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS", 19, "17_StringProcessing"),
    ("EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS", 2, "15Synchronization"),
    ("EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS", 0, "12_RegexParser"),
    ("EXPECTED_FOUNDATION_DARWIN_UNDEFINEDS", 2, "6Darwin"),
)
FOUNDATION_SOURCES = (
    "full/appshim/FoundationGuest.swift",
    "full/appshim/FoundationOpenUIKitAliases.swift",
    "full/appshim/FoundationOpenUIKitServiceAliases.swift",
    "full/appshim/FoundationOpenUIKitValueAliases.swift",
    "full/foundation/NSString.swift",
    "full/foundation/CharacterSet.swift",
    "full/foundation/NSLock.swift",
    "full/foundation/FileHandle.swift",
    "full/foundation/Data+Searching.swift",
    "full/foundation/CoreFoundationCompatibility.swift",
    "full/foundation/String+CharacterSet.swift",
    "full/foundation/String+FoundationCompatibility.swift",
    "full/foundation/Bundle+Localization.swift",
    "full/foundation/Stream.swift",
    "full/foundation/URLLoading.swift",
    "full/foundation/URLSession.swift",
    "full/foundation/Scanner.swift",
    "full/foundation/NSError.swift",
    "full/foundation/NSNumber.swift",
    "full/foundation/Error+LocalizedDescription.swift",
    "full/foundation/JSONSerialization.swift",
    "full/foundation/NSRegularExpression.swift",
    "full/foundation/DateFormatter.swift",
    "full/foundation/UserDefaults.swift",
)
SDK_DANGLING_EXCLUSIONS = (
    ("usr/lib/swift/libswiftCloudKit.tbd", "../../../System/Library/Frameworks/CloudKit.framework/CloudKit.tbd"),
    ("usr/lib/swift/libswiftCreateML.tbd", "../../../System/Library/Frameworks/CreateML.framework/Versions/Current/CreateML.tbd"),
    ("usr/lib/swift/libswiftIdentityLookup.tbd", "../../../System/Library/Frameworks/IdentityLookup.framework/IdentityLookup.tbd"),
    ("usr/lib/swift/libswiftNetwork.tbd", "../../../System/Library/Frameworks/Network.framework/Network.tbd"),
    ("usr/lib/swift/libswiftPencilKit.tbd", "../../../System/Library/Frameworks/PencilKit.framework/PencilKit.tbd"),
    ("usr/lib/swift/libswiftShazamKit.tbd", "../../../System/Library/Frameworks/ShazamKit.framework/Versions/A/ShazamKit.tbd"),
    ("usr/lib/swift/libswiftSoundAnalysis.tbd", "../../..//System/Library/Frameworks/SoundAnalysis.framework/Versions/A/SoundAnalysis.tbd"),
    ("usr/lib/swift/libswiftSoundAnalysis_Private.tbd", "../../..//System/Library/Frameworks/SoundAnalysis.framework/Versions/A/SoundAnalysis.tbd"),
    ("usr/lib/swift/libswiftVirtualization.tbd", "../../../System/Library/Frameworks/Virtualization.framework/Versions/Current/Virtualization.tbd"),
)
FRAMEWORKS = (
    "FoundationEssentials",
    "OpenCoreGraphics",
    "OpenUIKit",
    "OpenCombine",
    "Combine",
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
)
DEPENDENCIES = (
    "InternalCollectionsUtilities",
    "OrderedCollections",
    "_RopeModule",
    "os",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run_tool(*arguments: str, expected: int = 0) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["python3", "-B", str(TOOL), *arguments],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != expected:
        raise AssertionError(
            f"manifest command returned {result.returncode}, expected {expected}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def run_canonical(
    package: Path, expected: int = 0
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [
            "python3",
            "-B",
            str(CANONICAL_VALIDATOR),
            str(package),
            "--emit-summary",
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != expected:
        raise AssertionError(
            f"canonical validator returned {result.returncode}, expected {expected}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result


def write_file(path: Path, payload: bytes | str = b"fixture") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(payload, str):
        path.write_text(payload, encoding="utf-8", newline="\n")
    else:
        path.write_bytes(payload)


def validate_core_single_bind_contract(source: str) -> None:
    missing = [path for path in CORE_FRESH_PATHS if source.count(path) < 2]
    if missing:
        raise AssertionError(f"core fresh-path contract drifted: {missing}")
    if source.count(CORE_FRESH_PATH_BLOCK) != 1:
        raise AssertionError("core exact fresh-path contract drifted")
    missing_tmpfs = [path for path in CORE_TMPFS_PATHS if source.count(path) != 1]
    if missing_tmpfs:
        raise AssertionError(f"core tmpfs contract drifted: {missing_tmpfs}")
    if source.count('-v "$REPLAY_ROOT:/replay:rw"') != 1:
        raise AssertionError("core single-bind contract drifted")
    docker_arguments = source[source.index("DOCKER_ARGS=(") : source.index("BUILD_ARGS=(")]
    if docker_arguments.count("\n    -v ") != 1:
        raise AssertionError("core single-bind count drifted")
    if docker_arguments.count("\n    --tmpfs ") != 1:
        raise AssertionError("core single-tmpfs contract drifted")
    if "--tmpfs /replay/" in docker_arguments:
        raise AssertionError("core nested-tmpfs contract drifted")


def validate_foundation_runtime_links(source: str) -> None:
    missing = [
        token
        for flag, install_name, expected_count in FOUNDATION_RUNTIME_LINK_CONTRACT
        for token in (flag, install_name)
        if source.count(token) != expected_count
    ]
    if missing:
        raise AssertionError(f"Foundation runtime-link contract drifted: {missing}")


def validate_swiftui_runtime_link(source: str) -> None:
    missing = [
        token for token in SWIFTUI_RUNTIME_LINK_CONTRACT
        if source.count(token) != 1
    ]
    if missing:
        raise AssertionError(f"SwiftUI runtime-link contract drifted: {missing}")
    # One direct SwiftUI link, one reusable dependency token in each of the
    # seven first-party links, and one executable probe link.
    if source.count('"$SWIFTUI_RUNTIME_LINK_FLAG"') != 3:
        raise AssertionError("SwiftUI runtime-link scope drifted")
    swiftui_link_start = source.index("-install_name @rpath/libSwiftUI.dylib")
    swiftui_link_end = source.index(
        "swiftui_runtime_load_count=", swiftui_link_start
    )
    swiftui_link = source[swiftui_link_start:swiftui_link_end]
    if swiftui_link.count('"$FULL/swiftcorepatch.o"') != 1:
        raise AssertionError("SwiftUI runtime-compatibility thunk scope drifted")


def validate_core_preview_export_contract(source: str) -> None:
    assignment = (
        "PREVIEW_EXECUTABLE_EXPORT_SYMBOL="
        f"'{PREVIEW_EXECUTABLE_EXPORT_SYMBOL}'"
    )
    required_once = (
        assignment,
        'PROBE_EXPORT_FLAGS+=(-exported_symbol "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")',
        "preview_export_definition_count=$(nm_symbol_count --defined-only",
        "staged_preview_definition_count=$(nm_symbol_count --defined-only",
        "uikit_preview_import_count=$(nm_symbol_count --undefined-only",
        "probe_preview_export_count=$(nm_symbol_count --defined-only",
        "libUIKit-preview-initializer-import-count",
        "executable-preview-initializer-export-count",
    )
    drifted = [token for token in required_once if source.count(token) != 1]
    if drifted:
        raise AssertionError(f"core Preview executable-export contract drifted: {drifted}")
    if "-export_dynamic" in source or "-exported_symbols_list" in source:
        raise AssertionError("core Preview export must remain one exact symbol")


def validate_preview_plugin_single_job_contract(
    builder: str, build_full: str
) -> None:
    builder_counts = {
        "-load-plugin-executable": 2,
        "-j1": 2,
        '"${PREVIEW_FLAGS[@]}"': 3,
        "core-preview-input-v2": 1,
        "plugin-driver-job-count\\t1": 1,
    }
    build_full_counts = {
        "-load-plugin-executable": 1,
        "-j1": 1,
        '"${PREVIEW_SWIFT_FLAGS[@]}"': 5,
    }
    drifted = [
        f"builder:{token}"
        for token, count in builder_counts.items()
        if builder.count(token) != count
    ]
    drifted.extend(
        f"build-full:{token}"
        for token, count in build_full_counts.items()
        if build_full.count(token) != count
    )
    if drifted:
        raise AssertionError(
            f"Preview plugin single-job compiler census drifted: {drifted}"
        )
    if (
        '"$PREVIEW_MACRO_PLUGIN#OpenUIKitPreviewMacros" -j1)' not in builder
        or "'${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros' -j1" not in builder
        or '"$BUILD_FULL_PREVIEW_MACRO_PLUGIN#OpenUIKitPreviewMacros"\n'
        "        -j1" not in build_full
    ):
        raise AssertionError("Preview plugin single-job flag ordering drifted")


def validate_foundation_runtime_undefineds(source: str) -> None:
    for assignment, expected, predicate in FOUNDATION_RUNTIME_UNDEFINED_CONTRACT:
        match = re.search(rf"(?m)^{re.escape(assignment)}=([0-9]+)$", source)
        if match is None or int(match.group(1)) != expected:
            raise AssertionError(
                f"Foundation runtime-undefined assignment drifted: {assignment}"
            )
        if source.count(f'index($0, "{predicate}")') != 1:
            raise AssertionError(
                f"Foundation runtime-undefined predicate drifted: {predicate}"
            )
    if source.count('llvm-nm-18 -u -j "$WORK/foundation.o"') != 1:
        raise AssertionError("Foundation runtime-undefined inventory drifted")


class FoundationManifestTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        for index, relative in enumerate(FOUNDATION_SOURCES, 1):
            write_file(self.root / relative, f"// source {index}\n")
        self.manifest = self.root / "full/foundation/foundation_guest_sources.txt"
        write_file(self.manifest, "\n".join(FOUNDATION_SOURCES) + "\n")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def attest(self, expected: int = 0) -> subprocess.CompletedProcess[str]:
        return run_tool(
            "foundation-sources",
            "--support-root",
            str(self.root),
            "--manifest",
            str(self.manifest),
            "--output",
            str(self.root / "attestation.tsv"),
            expected=expected,
        )

    def test_exact_order_is_attested(self) -> None:
        self.attest()
        lines = (self.root / "attestation.tsv").read_text().splitlines()
        self.assertEqual(lines[0], "format\tfoundation-guest-sources-v1")
        self.assertEqual(len([line for line in lines if line.startswith("source\t")]), 24)

    def test_reordered_manifest_is_refused(self) -> None:
        reordered = list(FOUNDATION_SOURCES)
        reordered[0], reordered[1] = reordered[1], reordered[0]
        write_file(self.manifest, "\n".join(reordered) + "\n")
        refusal = self.attest(expected=2)
        self.assertIn("exact ordered 24-path contract", refusal.stderr)

    def test_symlinked_source_is_refused(self) -> None:
        source = self.root / FOUNDATION_SOURCES[-1]
        source.unlink()
        source.symlink_to(self.root / FOUNDATION_SOURCES[0])
        refusal = self.attest(expected=2)
        self.assertIn("symlink", refusal.stderr)


class SDKDanglingSymlinkTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.sdk = self.root / "sdk"
        self.sdk.mkdir()
        self.exclusions = self.root / "exclusions.tsv"
        lines = ["format\tsdk-dangling-symlink-exclusions-v1"]
        lines.extend(
            f"symlink\t{relative}\t{target}"
            for relative, target in SDK_DANGLING_EXCLUSIONS
        )
        write_file(self.exclusions, "\n".join(lines) + "\n")
        for relative, target in SDK_DANGLING_EXCLUSIONS:
            path = self.sdk / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            os.symlink(target, path)
        write_file(self.sdk / "usr/lib/swift/valid-target.tbd", "valid\n")
        os.symlink("valid-target.tbd", self.sdk / "usr/lib/swift/libValid.tbd")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_checked_manifest_pins_exact_raw_path_target_pairs(self) -> None:
        checked = HERE / "sdk_dangling_symlink_exclusions.tsv"
        self.assertEqual(checked.read_bytes(), self.exclusions.read_bytes())

    def test_normalized_inventory_attests_then_removes_only_verified_links(self) -> None:
        inventory = self.root / "normalized.tsv"
        run_tool(
            "inventory-tree",
            "--root",
            str(self.sdk),
            "--logical-root",
            "sdk",
            "--dangling-exclusions",
            str(self.exclusions),
            "--output",
            str(inventory),
        )
        payload = inventory.read_text(encoding="utf-8")
        self.assertIn("sdk/usr/lib/swift/libValid.tbd", payload)
        self.assertNotIn("libswiftCloudKit.tbd", payload)

        observed = self.root / "observed.tsv"
        run_tool(
            "dangling-symlinks",
            "--root",
            str(self.sdk),
            "--exclusions",
            str(self.exclusions),
            "--output",
            str(observed),
            "--remove",
        )
        observed_text = observed.read_text(encoding="utf-8")
        self.assertIn("count=9", observed_text)
        self.assertIn("../../..//System/Library/Frameworks/SoundAnalysis", observed_text)
        for relative, _target in SDK_DANGLING_EXCLUSIONS:
            self.assertFalse((self.sdk / relative).is_symlink())
        self.assertTrue((self.sdk / "usr/lib/swift/libValid.tbd").is_symlink())
        run_tool(
            "inventory-tree",
            "--root",
            str(self.sdk),
            "--logical-root",
            "sdk",
            "--output",
            str(self.root / "packaged.tsv"),
        )

    def test_target_drift_is_refused(self) -> None:
        path = self.sdk / SDK_DANGLING_EXCLUSIONS[0][0]
        path.unlink()
        os.symlink("../../../wrong-target.tbd", path)
        refusal = run_tool(
            "dangling-symlinks",
            "--root",
            str(self.sdk),
            "--exclusions",
            str(self.exclusions),
            "--output",
            str(self.root / "observed.tsv"),
            expected=2,
        )
        self.assertIn("target-drift", refusal.stderr)

    def test_unexpected_dangling_link_is_refused(self) -> None:
        os.symlink("missing.tbd", self.sdk / "usr/lib/swift/unreviewed.tbd")
        refusal = run_tool(
            "inventory-tree",
            "--root",
            str(self.sdk),
            "--logical-root",
            "sdk",
            "--dangling-exclusions",
            str(self.exclusions),
            "--output",
            str(self.root / "normalized.tsv"),
            expected=2,
        )
        self.assertIn("unexpected", refusal.stderr)


class PackageFixture:
    def __init__(self, root: Path, preview: bool) -> None:
        self.root = root
        self.preview = preview
        for relative in (
            "sdk",
            "modules",
            "lib",
            "include",
            "include/CoreImage",
            "objects",
            "resources/OpenUIKit/fonts",
            "guest-root/darwin/usr/lib",
            "probe",
            "attestation",
        ):
            (root / relative).mkdir(parents=True, exist_ok=True)
        for framework in FRAMEWORKS:
            write_file(root / f"modules/{framework}.swiftmodule", framework)
            write_file(root / f"lib/lib{framework}.dylib", f"dylib:{framework}")
        for dependency in DEPENDENCIES:
            write_file(root / f"modules/{dependency}.swiftmodule", dependency)
        write_file(root / "include/CoreImage/CoreImage.h", "umbrella")
        write_file(
            root / "include/CoreImage/CIFilterBuiltins.h", "generated filters"
        )
        write_file(root / "include/CoreImage/module.modulemap", "module CoreImage {}")
        write_file(root / "guest-root/darwin/usr/lib/libquartz.dylib", "quartz")
        write_file(root / "guest-root/machorun", "loader")
        write_file(root / "guest-root/.manifest", "fixture-root\n")
        write_file(root / "probe/CoreGuestPackageProbe", "probe")
        write_file(root / "resources/OpenUIKit/system_colors.json", "{}\n")
        write_file(root / "resources/OpenUIKit/font_metrics.json", "{}\n")
        write_file(root / "resources/OpenUIKit/fonts/DejaVuSans.ttf", "system-font")
        write_file(root / "resources/OpenUIKit/fonts/DejaVuSans-Bold.ttf", "bold-font")
        for name in (
            "input-provenance.tsv",
            "source-sets.tsv",
            "foundation-sources.tsv",
            "intents-sources.tsv",
            "graphics-sources.tsv",
            "first-party-sources.tsv",
            "first-party-dylib-loads.tsv",
            "webkit-sources.tsv",
            "webkit-dylib-loads.tsv",
            "sdk-dangling-symlinks.tsv",
            "sdk-dangling-symlink-exclusions.tsv",
            "include-tree.tsv",
            "guest-root-tree.tsv",
            "openuikit-resources-tree.tsv",
            "runtime-closure.tsv",
        ):
            write_file(root / f"attestation/{name}", f"format\t{name}\n")
        write_file(
            root / "attestation/sdk-tree.tsv",
            "format\tcore-tree-v1\ndirectory\tsdk\tempty=yes\n",
        )
        self.compile_arguments = [
            "-target",
            "arm64-apple-macos15.0",
            "-sdk",
            "sdk",
            "-I",
            "modules",
            "-Xcc",
            "-fmodule-map-file=include/CoreImage/module.modulemap",
            "-Xcc",
            "-Iinclude/CoreImage",
        ]
        self.link_arguments = [
            "-arch",
            "arm64",
            "-platform_version",
            "macos",
            "15.0",
            "15.0",
            "-syslibroot",
            "sdk",
            "-Llib",
            "-lUIKit",
            "-lCoreImage",
            "-lQuartzCore",
            "-lFoundation",
            "-lFoundationEssentials",
            "-lSwiftUI",
            "-lIntentsUI",
            "-lIntents",
            "-lWebKit",
            "-lOpenUIKit",
            "-lOpenCoreGraphics",
            "-lCombine",
            "-lOpenCombine",
            "-lLocalAuthentication",
            "-lSafariServices",
            "-lNetwork",
            "-lStoreKit",
            "-lAudioToolbox",
            "-lCoreHaptics",
            "-lPassKit",
        ]
        (root / "compile-flags.rsp").write_bytes(
            b"".join(token.encode() + b"\0" for token in self.compile_arguments)
        )
        (root / "link-inputs.rsp").write_bytes(
            b"".join(token.encode() + b"\0" for token in self.link_arguments)
        )
        self.plugin: Path | None = None
        if preview:
            write_file(root / "modules/DeveloperToolsSupport.swiftmodule", "dts-module")
            write_file(root / "objects/developertoolsupport.o", "dts-object")
            self.plugin = root.parent / "OpenUIKitPreviewMacros-tool"
            write_file(self.plugin, "host-plugin")
            self.plugin.chmod(0o755)
            (root / "preview-plugin-load-flag.rsp").write_bytes(
                b"-load-plugin-executable\0"
                b"${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros\0-j1\0"
            )
            write_file(
                root / "attestation/preview-input.tsv",
                "\n".join(
                    (
                        "format\tcore-preview-input-v2",
                        "module-name\tDeveloperToolsSupport",
                        "module-path\tmodules/DeveloperToolsSupport.swiftmodule",
                        f"module-sha256\t{sha256(root / 'modules/DeveloperToolsSupport.swiftmodule')}",
                        "object-path\tobjects/developertoolsupport.o",
                        f"object-sha256\t{sha256(root / 'objects/developertoolsupport.o')}",
                        "plugin-basename\tOpenUIKitPreviewMacros-tool",
                        f"plugin-sha256\t{sha256(self.plugin)}",
                        "plugin-elf-class\tELF64",
                        "plugin-elf-machine\tAArch64",
                        "plugin-toolchain\tSwift version 6.2.4",
                        "plugin-swiftsyntax-revision\t4799286537280063c85a32f09884cfbca301b1a1",
                        "plugin-registration\tOpenUIKitPreviewMacros",
                        "plugin-load-flags\tpreview-plugin-load-flag.rsp",
                        "plugin-driver-job-count\t1",
                    )
                )
                + "\n",
            )
        self._write_ledger()

    def _artifact(self, category: str, name: str, role: str, relative: str) -> str:
        path = self.root / relative
        return "\t".join(
            (category, name, role, relative, sha256(path), str(path.stat().st_size))
        )

    def _write_ledger(self) -> None:
        records = ["format\tcore-artifacts-v1"]
        for framework in FRAMEWORKS:
            records.append(
                self._artifact(
                    "framework", framework, "swiftmodule", f"modules/{framework}.swiftmodule"
                )
            )
            records.append(
                self._artifact("framework", framework, "dylib", f"lib/lib{framework}.dylib")
            )
        for dependency in DEPENDENCIES:
            records.append(
                self._artifact(
                    "module-dependency",
                    dependency,
                    "swiftmodule",
                    f"modules/{dependency}.swiftmodule",
                )
            )
        records.extend(
            (
                self._artifact(
                    "include",
                    "CoreImage",
                    "umbrella-header",
                    "include/CoreImage/CoreImage.h",
                ),
                self._artifact(
                    "include",
                    "CoreImage",
                    "submodule-header",
                    "include/CoreImage/CIFilterBuiltins.h",
                ),
                self._artifact(
                    "include",
                    "CoreImage",
                    "module-map",
                    "include/CoreImage/module.modulemap",
                ),
            )
        )
        records.append(
            self._artifact(
                "runtime", "CQuartz", "dylib", "guest-root/darwin/usr/lib/libquartz.dylib"
            )
        )
        records.append(self._artifact("runtime", "machorun", "executable", "guest-root/machorun"))
        for relative in sorted(
            path.relative_to(self.root).as_posix()
            for path in (self.root / "resources/OpenUIKit").rglob("*")
            if path.is_file()
        ):
            role = "runtime-resource"
            if relative.endswith("DejaVuSans.ttf"):
                role = "system-font"
            elif relative.endswith("DejaVuSans-Bold.ttf"):
                role = "bold-font"
            records.append(self._artifact("resource", "OpenUIKit", role, relative))
        if self.preview:
            records.append(
                self._artifact(
                    "module-dependency",
                    "DeveloperToolsSupport",
                    "swiftmodule",
                    "modules/DeveloperToolsSupport.swiftmodule",
                )
            )
            records.append(
                self._artifact(
                    "object",
                    "DeveloperToolsSupport",
                    "object",
                    "objects/developertoolsupport.o",
                )
            )
        write_file(self.root / "attestation/artifacts.tsv", "\n".join(records) + "\n")

    def write_manifest(
        self, expected: int = 0
    ) -> subprocess.CompletedProcess[str]:
        arguments = [
            "write",
            "--package-root",
            str(self.root),
            "--artifact-ledger",
            str(self.root / "attestation/artifacts.tsv"),
            "--artifact-ledger-relative",
            "attestation/artifacts.tsv",
            "--input-provenance",
            "attestation/input-provenance.tsv",
            "--source-sets",
            "attestation/source-sets.tsv",
            "--foundation-sources",
            "attestation/foundation-sources.tsv",
            "--intents-sources",
            "attestation/intents-sources.tsv",
            "--graphics-sources",
            "attestation/graphics-sources.tsv",
            "--first-party-sources",
            "attestation/first-party-sources.tsv",
            "--first-party-dylib-loads",
            "attestation/first-party-dylib-loads.tsv",
            "--webkit-sources",
            "attestation/webkit-sources.tsv",
            "--sdk-inventory",
            "attestation/sdk-tree.tsv",
            "--sdk-dangling-symlinks",
            "attestation/sdk-dangling-symlinks.tsv",
            "--sdk-dangling-exclusions",
            "attestation/sdk-dangling-symlink-exclusions.tsv",
            "--include-inventory",
            "attestation/include-tree.tsv",
            "--guest-inventory",
            "attestation/guest-root-tree.tsv",
            "--resource-inventory",
            "attestation/openuikit-resources-tree.tsv",
            "--runtime-closure",
            "attestation/runtime-closure.tsv",
            "--compile-rsp",
            "compile-flags.rsp",
            "--link-rsp",
            "link-inputs.rsp",
        ]
        if self.preview:
            assert self.plugin is not None
            arguments.extend(
                (
                    "--preview-attestation",
                    "attestation/preview-input.tsv",
                    "--external-preview-plugin",
                    str(self.plugin),
                )
            )
        return run_tool(*arguments, expected=expected)


class PackageContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.base = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def fixture(self, preview: bool) -> PackageFixture:
        fixture = PackageFixture(self.base / ("preview" if preview else "plain"), preview)
        fixture.write_manifest()
        return fixture

    def test_plain_schema_is_relocatable(self) -> None:
        fixture = self.fixture(False)
        document = json.loads((fixture.root / "attestation/core-package.json").read_text())
        self.assertEqual(document["classification"], "open-uikit-core-guest-package")
        self.assertEqual(document["format_version"], 1)
        self.assertEqual(document["target"]["triple"], "arm64-apple-macos15.0")
        self.assertEqual(document["paths"]["resources"], "resources/OpenUIKit")
        self.assertIsNone(document["preview"])
        self.assertNotIn(str(self.base), json.dumps(document))
        relocated = self.base / "relocated package with spaces"
        shutil.copytree(fixture.root, relocated)
        run_tool("verify", "--package-root", str(relocated))
        summary = run_canonical(relocated)
        self.assertIn("preview=no", summary.stdout)

    def test_preview_is_external_and_dts_is_driver_owned(self) -> None:
        fixture = self.fixture(True)
        document = json.loads((fixture.root / "attestation/core-package.json").read_text())
        preview = document["preview"]
        self.assertEqual(preview["plugin_module"], "OpenUIKitPreviewMacros")
        self.assertEqual(preview["plugin_driver_job_count"], 1)
        self.assertEqual(
            preview["load_arguments"],
            [
                "-load-plugin-executable",
                "${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros",
                "-j1",
            ],
        )
        self.assertEqual(
            preview["developer_tools_support_object"],
            "objects/developertoolsupport.o",
        )
        self.assertEqual(
            preview["app_compile_diagnostic_arguments"],
            ["-Xfrontend", "-dump-macro-expansions"],
        )
        self.assertNotIn("objects/developertoolsupport.o", document["executable_link_arguments"])
        self.assertEqual(
            (fixture.root / "preview-plugin-load-flag.rsp").read_bytes(),
            b"-load-plugin-executable\0"
            b"${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros\0-j1\0",
        )
        self.assertFalse((fixture.root / "OpenUIKitPreviewMacros-tool").exists())
        self.assertNotIn(str(fixture.plugin), json.dumps(document))
        assert fixture.plugin is not None
        run_tool(
            "verify",
            "--package-root",
            str(fixture.root),
            "--preview-plugin",
            str(fixture.plugin),
        )
        summary = run_canonical(fixture.root)
        self.assertIn("preview=yes", summary.stdout)
        relocated = self.base / "relocated preview package"
        shutil.copytree(fixture.root, relocated)
        run_tool("verify", "--package-root", str(relocated))
        self.assertIn("preview=yes", run_canonical(relocated).stdout)

    def test_preview_single_job_manifest_mutations_are_refused(self) -> None:
        cases = (
            (
                b"-load-plugin-executable\0"
                b"${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros\0",
                "wrong token contract",
            ),
            (
                b"-load-plugin-executable\0"
                b"${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros\0-j2\0",
                "wrong token contract",
            ),
            (
                b"-load-plugin-executable\0"
                b"${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros\0-j1\0-j1\0",
                "wrong token contract",
            ),
        )
        for index, (payload, diagnostic) in enumerate(cases):
            with self.subTest(payload=payload):
                fixture = PackageFixture(self.base / f"job-mutation-{index}", True)
                (fixture.root / "preview-plugin-load-flag.rsp").write_bytes(payload)
                refusal = fixture.write_manifest(expected=2)
                self.assertIn(diagnostic, refusal.stderr)

        fixture = PackageFixture(self.base / "job-count-mutation", True)
        attestation = fixture.root / "attestation/preview-input.tsv"
        attestation.write_text(
            attestation.read_text(encoding="utf-8").replace(
                "plugin-driver-job-count\t1\n",
                "plugin-driver-job-count\t2\n",
            ),
            encoding="utf-8",
            newline="\n",
        )
        refusal = fixture.write_manifest(expected=2)
        self.assertIn("driver job count is not one", refusal.stderr)

    def test_changed_resource_is_refused(self) -> None:
        fixture = self.fixture(False)
        write_file(fixture.root / "resources/OpenUIKit/system_colors.json", "changed\n")
        refusal = run_tool("verify", "--package-root", str(fixture.root), expected=2)
        self.assertIn("artifact hash drifted", refusal.stderr)

    def test_unattested_library_is_refused(self) -> None:
        fixture = self.fixture(False)
        write_file(fixture.root / "lib/libStale.dylib", "stale")
        refusal = run_tool("verify", "--package-root", str(fixture.root), expected=2)
        self.assertIn("artifact coverage drifted under lib", refusal.stderr)

    def test_every_framework_dylib_is_in_the_reusable_link_contract(self) -> None:
        fixture = self.fixture(False)
        manifest_path = fixture.root / "attestation/core-package.json"
        original_document = json.loads(manifest_path.read_text(encoding="utf-8"))
        for framework in FRAMEWORKS:
            with self.subTest(framework=framework):
                document = copy.deepcopy(original_document)
                token = f"-l{framework}"
                document["executable_link_arguments"].remove(token)
                manifest_path.write_text(
                    json.dumps(document, indent=2, sort_keys=True) + "\n",
                    encoding="utf-8",
                )
                (fixture.root / "link-inputs.rsp").write_bytes(
                    b"".join(
                        value.encode("utf-8") + b"\0"
                        for value in document["executable_link_arguments"]
                    )
                )
                refusal = run_tool(
                    "verify", "--package-root", str(fixture.root), expected=2
                )
                self.assertIn("required token exactly once", refusal.stderr)
        manifest_path.write_text(
            json.dumps(original_document, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    def test_intents_source_attestation_is_mandatory(self) -> None:
        fixture = self.fixture(False)
        manifest_path = fixture.root / "attestation/core-package.json"
        document = json.loads(manifest_path.read_text(encoding="utf-8"))
        del document["manifests"]["intents_sources"]
        manifest_path.write_text(
            json.dumps(document, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        refusal = run_tool("verify", "--package-root", str(fixture.root), expected=2)
        self.assertIn("omits required manifests: intents_sources", refusal.stderr)

    def test_graphics_source_attestation_is_mandatory(self) -> None:
        fixture = self.fixture(False)
        manifest_path = fixture.root / "attestation/core-package.json"
        document = json.loads(manifest_path.read_text(encoding="utf-8"))
        del document["manifests"]["graphics_sources"]
        manifest_path.write_text(
            json.dumps(document, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        refusal = run_tool("verify", "--package-root", str(fixture.root), expected=2)
        self.assertIn("omits required manifests: graphics_sources", refusal.stderr)

    def test_coreimage_underlying_module_inputs_are_mandatory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            ledger = fixture.root / "attestation/artifacts.tsv"
            ledger.write_text(
                "\n".join(
                    line
                    for line in ledger.read_text(encoding="utf-8").splitlines()
                    if "include/CoreImage/module.modulemap" not in line
                )
                + "\n",
                encoding="utf-8",
            )
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("CoreImage underlying-module artifacts are absent", refusal.stderr)

    def test_coreimage_compile_pairs_are_mandatory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            fixture.compile_arguments = fixture.compile_arguments[:-2]
            (fixture.root / "compile-flags.rsp").write_bytes(
                b"".join(token.encode() + b"\0" for token in fixture.compile_arguments)
            )
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("CoreImage underlying-module pair", refusal.stderr)

    def test_webkit_source_attestation_is_mandatory(self) -> None:
        fixture = self.fixture(False)
        manifest_path = fixture.root / "attestation/core-package.json"
        document = json.loads(manifest_path.read_text(encoding="utf-8"))
        del document["manifests"]["webkit_sources"]
        manifest_path.write_text(
            json.dumps(document, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        refusal = run_tool("verify", "--package-root", str(fixture.root), expected=2)
        self.assertIn("omits required manifests: webkit_sources", refusal.stderr)

    def test_webkit_framework_deletion_is_refused_by_both_validators(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            fixture.write_manifest()
            (fixture.root / "lib/libWebKit.dylib").unlink()
            refusal = run_tool(
                "verify", "--package-root", str(fixture.root), expected=2
            )
            self.assertIn("missing", refusal.stderr)
            canonical = run_canonical(fixture.root, expected=1)
            self.assertIn("WebKit", canonical.stderr)

    def test_preview_plugin_hash_is_optionally_revalidated(self) -> None:
        fixture = self.fixture(True)
        assert fixture.plugin is not None
        write_file(fixture.plugin, "changed plugin")
        fixture.plugin.chmod(0o755)
        refusal = run_tool(
            "verify",
            "--package-root",
            str(fixture.root),
            "--preview-plugin",
            str(fixture.plugin),
            expected=2,
        )
        self.assertIn("plugin hash drifted", refusal.stderr)


class ShellContractTests(unittest.TestCase):
    def test_foundation_hackers_frontier_is_foundation_only_and_runs(self) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        core_probe = (HERE / "CoreGuestPackageProbe.swift").read_text(
            encoding="utf-8"
        )
        compatibility_probe = FOUNDATION_COMPATIBILITY_PROBE.read_text(
            encoding="utf-8"
        )
        self.assertEqual(
            re.findall(r"(?m)^import ([A-Za-z0-9_]+)$", compatibility_probe),
            ["Foundation"],
        )
        for token in (
            "let scalar: CGFloat",
            "Int(ceil(CGFloat(11) / 10)) == 2",
            "os_unfair_lock_trylock",
            "let lock = NSLock()",
            "CharacterSet.uppercaseLetters",
            "CharacterSet.lowercaseLetters",
            "CharacterSet.letters",
            "CharacterSet.alphanumerics",
            "CharacterSet.symbols",
            "CharacterSet.decimalDigits",
            "precomposedStringWithCanonicalMapping",
            'caseInsensitiveCompare("focus")',
            "replacingCharacters(",
            'cString(using: .utf8)',
            "NSRange(2..<7)",
            "scalar as NSNumber",
            "NSClassFromString(",
            'NSSelectorFromString("filterWithType:")',
            "NSStringFromClass(CoreFoundationRuntimeLookupProbe.self)",
            "NSStringFromSelector(runtimeSelector)",
            "trimmingCharacters(in: .whitespaces)",
            "FileHandle(forReadingAtPath:",
            "readDataToEndOfFile()",
            "handle.read(upToCount: 1)",
            "handle.readToEnd()",
            "try! handle.close()",
            "bytes.range(of: needle)",
            "options: .backwards",
            "CFURLCreateWithString(",
            '"https://example.invalid/a b" as CFString',
        ):
            self.assertIn(token, compatibility_probe)
        self.assertIn("FoundationHackersCompatibilityProbe.swift", builder)
        self.assertIn("runFoundationHackersCompatibilityProbe(", core_probe)
        marker = (
            "foundation=locks,filehandle,characters,strings,ranges,attributed,objc,number-bridge,data-search,cfurl,reexports"
        )
        self.assertIn(marker, builder)
        self.assertIn("foundation=\\(foundationCompatibility)", core_probe)

    def test_builder_pins_the_canonical_105_source_openuikit_tree(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        self.assertEqual(source.count("EXPECTED_FOUNDATION_SOURCE_COUNT=24"), 1)
        self.assertEqual(source.count("EXPECTED_UIKIT_SWIFT_COUNT=105"), 1)
        self.assertNotIn("EXPECTED_UIKIT_SWIFT_COUNT=102", source)
        self.assertEqual(source.count("EXPECTED_SWIFTUI_SWIFT_COUNT=8"), 1)
        self.assertNotIn("EXPECTED_SWIFTUI_SWIFT_COUNT=7", source)

    def test_foundation_links_the_cgfloat_owner_directly(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        foundation_link = source[source.index(
            "-install_name @rpath/libFoundation.dylib"
        ):source.index(
            "-install_name @rpath/libSwiftUI.dylib"
        )]
        self.assertIn("-lOpenCoreGraphics", foundation_link)
        self.assertIn("foundation_graphics_load_count", foundation_link)
        self.assertIn(
            '"@rpath/libOpenCoreGraphics.dylib"',
            foundation_link,
        )
        self.assertIn(
            "libFoundation OpenCoreGraphics load count",
            foundation_link,
        )

    def test_url_transport_bridge_and_linux_helper_are_packaged_fail_closed(self) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        driver = APP_DRIVER.read_text(encoding="utf-8")
        host = (REPO / "full/urltransport/OpenURLTransportHost.c").read_text(
            encoding="utf-8"
        )
        for token in (
            "libOpenURLTransport.dylib",
            "libOpenURLTransportHost.so",
            "url-transport-abi.tsv",
            "url-transport-host.tsv",
            "url-transport-expected-mach-imports.txt",
            "curl-config --ssl-backends",
            "curl-config --ca",
            "url-transport-transitive-sonames.txt",
            'LD_PRELOAD="$URL_TRANSPORT_HOST',
        ):
            self.assertIn(token, builder)
        self.assertIn("host/libOpenURLTransportHost.so", driver)
        self.assertIn('LD_PRELOAD="$url_transport_host', driver)
        for token in (
            "CURLOPT_SSL_VERIFYPEER, 1L",
            "CURLOPT_SSL_VERIFYHOST, 2L",
            "CURLOPT_FOLLOWLOCATION, 0L",
            "OPENUI_URL_TRANSPORT_MAX_RESPONSE_HEADER_BYTES",
            "OPENUI_URL_TRANSPORT_MAX_RESPONSE_BODY_BYTES",
        ):
            self.assertIn(token, host)
        self.assertNotIn("CURLOPT_FOLLOWLOCATION, 1L", host)

    def test_swiftui_app_lifecycle_is_a_real_core_product(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        self.assertIn("EXPECTED_SWIFTUI_SWIFT_COUNT=8", source)
        self.assertIn("@UIApplicationDelegateAdaptor", probe)
        self.assertIn("WindowGroup", probe)
        self.assertIn("CoreLifecycleApplication.main", probe)
        self.assertIn("swiftui-app=constructed", probe)

    def test_builder_requires_exact_uikit_pin_and_fresh_output(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        for token in (
            "--expected-support-commit",
            "--expected-support-tree",
            "--uikit-checkout",
            "--expected-uikit-commit",
            "--expected-uikit-tree",
            "assert_clean_commit \"$UIKIT\"",
            "output root already exists",
            ".INVALID-DO-NOT-USE",
        ):
            self.assertIn(token, source)
        self.assertNotIn("EXPECTED_UIKIT_COMMIT=83fbcbe", source)

    def test_preview_plugin_is_never_packaged_or_target_linked(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        self.assertIn("'${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros'", source)
        self.assertIn("probe_dts_count", source)
        self.assertIn("UIKIT_UNDEFINED_FLAGS=(-undefined dynamic_lookup)", source)
        self.assertNotIn("LINK_ARGUMENTS+=(objects/developertoolsupport.o)", source)

    def test_webkit_is_an_independent_fail_closed_framework_dylib(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        self.assertEqual(len(FRAMEWORKS), 20)
        self.assertEqual(FRAMEWORKS[-8], "WebKit")
        for token in (
            "-module-name WebKit -emit-module",
            "-install_name @rpath/libWebKit.dylib",
            '-needed_library "$STAGE/lib/libUIKit.dylib"',
            '-needed_library "$STAGE/lib/libFoundation.dylib"',
            "/System/Library/Frameworks/WebKit.framework/",
            "webkit-dylib-loads.tsv",
            "rendering-engine\\tabsent",
            "-lWebKit -lCoreImage",
            "Intents IntentsUI WebKit",
        ):
            self.assertIn(token, source)
        self.assertIn("import WebKit", probe)
        self.assertIn("WKPortableError", probe)
        self.assertIn("webDelegate.commits == 0", probe)
        self.assertIn("webkit=engine-unavailable", probe)

    def test_preview_core_export_is_exact_and_mutation_is_refused(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        validate_core_preview_export_contract(source)
        for token in (
            'PROBE_EXPORT_FLAGS+=(-exported_symbol "$PREVIEW_EXECUTABLE_EXPORT_SYMBOL")',
            "staged_preview_definition_count=$(nm_symbol_count --defined-only",
            "uikit_preview_import_count=$(nm_symbol_count --undefined-only",
            "probe_preview_export_count=$(nm_symbol_count --defined-only",
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "export contract"):
                    validate_core_preview_export_contract(source.replace(token, "", 1))
        with self.assertRaisesRegex(AssertionError, "export contract"):
            validate_core_preview_export_contract(
                source.replace(
                    PREVIEW_EXECUTABLE_EXPORT_SYMBOL,
                    PREVIEW_EXECUTABLE_EXPORT_SYMBOL + "_MUTATED",
                    1,
                )
            )
        app_source = APP_DRIVER.read_text(encoding="utf-8")
        self.assertEqual(app_source.count(PREVIEW_EXECUTABLE_EXPORT_SYMBOL), 1)

    def test_build_full_preview_hook_preserves_early_visibility_boundary(self) -> None:
        source = BUILD_FULL.read_text(encoding="utf-8")
        self.assertIn("PREVIEW_INPUT_COUNT", source)
        self.assertIn("${PREVIEW_SWIFT_FLAGS[@]}", source)
        self.assertIn("${PREVIEW_LINK_OBJECTS[@]}", source)
        self.assertLess(source.index("literal UIKit shim"), source.index("app-only Foundation identity shim"))

    def test_every_preview_plugin_compile_is_single_job_and_mutation_refuses(self) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        build_full = BUILD_FULL.read_text(encoding="utf-8")
        validate_preview_plugin_single_job_contract(builder, build_full)
        mutations = (
            (builder.replace("-j1", "-j2", 1), build_full),
            (builder.replace('"${PREVIEW_FLAGS[@]}"', "", 1), build_full),
            (builder, build_full.replace("-j1", "-j2", 1)),
            (builder, build_full.replace('"${PREVIEW_SWIFT_FLAGS[@]}"', "", 1)),
        )
        for mutated_builder, mutated_build_full in mutations:
            with self.subTest():
                with self.assertRaisesRegex(AssertionError, "single-job"):
                    validate_preview_plugin_single_job_contract(
                        mutated_builder, mutated_build_full
                    )

    def test_host_wrapper_physically_stages_one_content_verified_bind(self) -> None:
        source = HOST_WRAPPER.read_text(encoding="utf-8")
        helper = PHYSICAL_REPLAY_TOOL.read_text(encoding="utf-8")
        validate_core_single_bind_contract(source)
        for token in (
            "--network none",
            "--read-only",
            '-v "$REPLAY_ROOT:/replay:rw"',
            'git clone --no-hardlinks --no-local --quiet "$SUPPORT_CHECKOUT"',
            'git clone --no-hardlinks --no-local --quiet "$UIKIT_CHECKOUT"',
            'git clone --no-hardlinks --no-local --quiet "$MACHORUN_CHECKOUT"',
            '--source "$MACHORUN_LOADER"',
            '--source "$MACHORUN_RUNTIME"',
            '--source "$STAGED_INPUT_ROOT/$relative"',
            "input-manifest.pre.jsonl",
            "input-manifest.post.jsonl",
            "content-manifest-pre-post",
            "guest-root-post-build.tsv",
            "durable guest-root product is missing after Docker",
            "libquartz.dylib",
            "remove-tree",
        ):
            self.assertIn(token, source)
        self.assertNotIn('"$STAGED_INPUT_ROOT/sysroot_fe4:/w/', source)
        self.assertNotIn('"$UIKIT_CHECKOUT:/uikit:', source)
        self.assertNotIn('"$MACHORUN_CHECKOUT:/machorun:', source)
        self.assertIn("--container-image SHA256_IMAGE_ID", source)
        self.assertIn("container image must be an exact sha256 content ID", source)
        self.assertIn("docker image inspect --format '{{.Id}}'", source)
        self.assertIn("expected linux/arm64", source)
        self.assertIn("expected-machorun-loader-sha256", source)
        self.assertIn("COPIED_MACHORUN_LOADER_SHA256", source)
        for preview_report in (
            "copy-preview-module.json",
            "copy-preview-object.json",
            "copy-preview-plugin.json",
        ):
            self.assertEqual(source.count(preview_report), 1)
        self.assertIn('"$CONTAINER_IMAGE"', source)
        self.assertNotIn("IMAGE=${IMAGE:-", source)
        self.assertIn(
            'core_guest_package.py "$W/build/core-package" --emit-summary', source
        )
        self.assertIn(".INVALID-DO-NOT-USE", source)
        self.assertLess(
            source.index('--before "$EVIDENCE/input-manifest.pre.jsonl"'),
            source.index('--source "$PACKAGE" --destination "$OUTPUT_ROOT"'),
        )
        for semantic in (
            '"mode": mode_string(metadata)',
            '"target": os.readlink(path)',
            '"sha256": hash_file(path)',
            '"type": "file"',
            '"type": "symlink"',
        ):
            self.assertIn(semantic, helper)
        self.assertIn('BUILD_FE_CACHE=$W/scratch/modcache_fe4', BUILDER.read_text(encoding="utf-8"))
        self.assertIn('"$BUILD_FE_CACHE"', BUILDER.read_text(encoding="utf-8"))
        self.assertIn("sdk_dangling_symlink_exclusions.tsv", BUILDER.read_text(encoding="utf-8"))
        self.assertIn("sdk-dangling-symlinks.tsv", BUILDER.read_text(encoding="utf-8"))

    def test_single_bind_control_refuses_nested_tmpfs_and_missing_fresh_path(self) -> None:
        source = HOST_WRAPPER.read_text(encoding="utf-8")
        nested_tmpfs = source.replace(
            '    -v "$REPLAY_ROOT:/replay:rw"\n',
            "    --tmpfs /replay/w/scratch/mrroot_full:rw,exec,mode=0777\n"
            '    -v "$REPLAY_ROOT:/replay:rw"\n',
            1,
        )
        with self.assertRaisesRegex(AssertionError, "single-tmpfs|nested-tmpfs"):
            validate_core_single_bind_contract(nested_tmpfs)

        without_fe_cache = source.replace(
            "    w/scratch/modcache_fe4\n",
            "",
            1,
        )
        with self.assertRaisesRegex(AssertionError, "fresh-path"):
            validate_core_single_bind_contract(without_fe_cache)

    def test_live_single_bind_smoke_links_and_rechecks_the_guest_root(self) -> None:
        source = SINGLE_BIND_GUEST_ROOT_SMOKE.read_text(encoding="utf-8")
        self.assertEqual(source.count('-v "$REPLAY_ROOT:/replay:rw"'), 1)
        self.assertEqual(source.count("--tmpfs /tmp:"), 1)
        self.assertNotIn("--tmpfs /replay/", source)
        for product in (
            "libSystem.B.dylib",
            "libc++.1.dylib",
            "libquartz.dylib",
        ):
            self.assertIn(product, source)
        self.assertEqual(source.count("ld64.lld-18 -arch arm64"), 3)
        self.assertIn("for number in $(seq 1 48)", source)
        self.assertIn("host cannot see durable product after Docker", source)
        self.assertIn("SINGLE_BIND_GUEST_ROOT_OK", source)

    def test_build_full_write_target_census_is_fully_overlaid(self) -> None:
        build_full = BUILD_FULL.read_text(encoding="utf-8")
        for helper in (
            "build_collections.sh",
            "build_os_module.sh",
            "build_cshims.sh",
            "build_fe.sh",
        ):
            self.assertIn(helper, build_full)
        for helper in (
            REPO / "full/foundation/build_collections.sh",
            REPO / "full/foundation/build_os_module.sh",
            REPO / "full/foundation/build_fe.sh",
        ):
            self.assertIn(
                '-module-cache-path "$W/scratch/modcache_fe4"',
                helper.read_text(encoding="utf-8"),
            )
        builder = BUILDER.read_text(encoding="utf-8")
        for cache in ("BUILD_FULL_CACHE", "BUILD_FE_CACHE"):
            self.assertIn(f'"${cache}"', builder)
            self.assertIn(f'touch "${cache}/.INVALID-DO-NOT-USE"', builder)

    def test_foundation_runtime_links_are_exact_and_deletion_is_refused(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        validate_foundation_runtime_links(source)
        self.assertNotIn("-lswift_RegexParser", source)
        for flag, install_name, _expected_count in FOUNDATION_RUNTIME_LINK_CONTRACT:
            for token in (flag, install_name):
                with self.subTest(deleted=token):
                    with self.assertRaisesRegex(AssertionError, "runtime-link"):
                        validate_foundation_runtime_links(source.replace(token, "", 1))
        for spelling in (
            "Foundation runtime link input is missing",
            "Foundation staged runtime dylib is missing",
            "Foundation staged runtime ID",
            "libFoundation runtime load count",
        ):
            self.assertIn(spelling, source)

    def test_swiftui_runtime_link_is_exact_and_deletion_is_refused(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        validate_swiftui_runtime_link(source)
        self.assertEqual(
            source.count(
                '-emit-module-path "$STAGE/modules/SwiftUI.swiftmodule"'
            ),
            1,
        )
        self.assertEqual(
            source.count("-install_name @rpath/libSwiftUI.dylib"),
            1,
        )
        self.assertEqual(
            source.count(
                "\n".join(
                    (
                        "Combine SwiftUI Foundation UIKit CoreImage QuartzCore Intents IntentsUI WebKit \\",
                        '    "${FIRST_PARTY_FRAMEWORKS[@]}"; do',
                    )
                )
            ),
            2,
        )
        self.assertIn(
            'record_artifact framework "$framework" dylib '
            '"lib/lib$framework.dylib"',
            source,
        )
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        self.assertIn("import SwiftUI", probe)
        self.assertIn('_ = Text("core-package")', probe)
        for token in SWIFTUI_RUNTIME_LINK_CONTRACT:
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "runtime-link"):
                    validate_swiftui_runtime_link(source.replace(token, "", 1))
        with self.assertRaisesRegex(AssertionError, "runtime-link scope"):
            validate_swiftui_runtime_link(
                source.replace('"$SWIFTUI_RUNTIME_LINK_FLAG"', "", 1)
            )
        swiftui_link_start = source.index(
            "-install_name @rpath/libSwiftUI.dylib"
        )
        swiftui_patch_offset = source.index(
            '"$FULL/swiftcorepatch.o"', swiftui_link_start
        )
        without_swiftui_patch = (
            source[:swiftui_patch_offset]
            + source[swiftui_patch_offset + len('"$FULL/swiftcorepatch.o"'):]
        )
        with self.assertRaisesRegex(
            AssertionError, "runtime-compatibility thunk scope"
        ):
            validate_swiftui_runtime_link(without_swiftui_patch)
        for spelling in (
            "SwiftUI runtime link input is missing",
            "SwiftUI staged runtime dylib is missing",
            "SwiftUI staged runtime ID",
            "libSwiftUI runtime load count",
        ):
            self.assertIn(spelling, source)

    def test_coreimage_dotted_submodule_and_quartzcore_are_real_boundaries(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        manifest_source = TOOL.read_text(encoding="utf-8")
        canonical_source = CANONICAL_VALIDATOR.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        module_map = (REPO / "full/coreimage/include/module.modulemap").read_text(
            encoding="utf-8"
        )
        quartzcore = (REPO / "full/quartzcore/QuartzCore.swift").read_text(
            encoding="utf-8"
        )
        self.assertIn("explicit module CIFilterBuiltins", module_map)
        self.assertIn("import CoreImage.CIFilterBuiltins", probe)
        self.assertIn("import QuartzCore", probe)
        self.assertIn("-module-name CoreImage -import-underlying-module", source)
        self.assertIn("-install_name @rpath/libCoreImage.dylib", source)
        self.assertIn("-install_name @rpath/libQuartzCore.dylib", source)
        self.assertIn("-lCoreImage -lQuartzCore", source)
        self.assertNotIn("libCIFilterBuiltins.dylib", source)
        self.assertIn("public typealias CALayer = OpenUIKit.CALayer", quartzcore)
        for token in (
            "-fmodule-map-file=include/CoreImage/module.modulemap",
            "-Iinclude/CoreImage",
            "graphics_sources",
        ):
            self.assertIn(token, manifest_source + canonical_source + source)

    def test_foundation_runtime_undefineds_are_exact_and_mutation_is_refused(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        validate_foundation_runtime_undefineds(source)
        self.assertIn("foundation-undefined-symbols.txt", source)
        for assignment, expected, predicate in FOUNDATION_RUNTIME_UNDEFINED_CONTRACT:
            with self.subTest(mutated=assignment):
                mutated = source.replace(
                    f"{assignment}={expected}", f"{assignment}={expected + 1}", 1
                )
                with self.assertRaisesRegex(AssertionError, "runtime-undefined"):
                    validate_foundation_runtime_undefineds(mutated)
            with self.subTest(deleted=predicate):
                with self.assertRaisesRegex(AssertionError, "runtime-undefined"):
                    validate_foundation_runtime_undefineds(
                        source.replace(predicate, "deleted-predicate", 1)
                    )

    def test_seven_first_party_frameworks_are_real_core_products(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        manifest_source = TOOL.read_text(encoding="utf-8")
        canonical_source = CANONICAL_VALIDATOR.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        first_party = (
            "LocalAuthentication",
            "SafariServices",
            "Network",
            "StoreKit",
            "AudioToolbox",
            "CoreHaptics",
            "PassKit",
        )
        self.assertEqual(FRAMEWORKS[-7:], first_party)
        self.assertEqual(
            source.count(
                'python3 -B "$FIRST_PARTY_PROVENANCE_TOOL" production'
            ),
            2,
        )
        self.assertIn(
            '-install_name "@rpath/lib$framework.dylib"', source
        )
        self.assertIn("first-party-dylib-loads-v1", source)
        self.assertIn("apple-self-load=0", source)
        self.assertIn("network_string_processing_undefineds", source)
        self.assertIn("direct StringProcessing undefineds, expected 0", source)
        network_source = (REPO / "full/network/Network.swift").read_text(
            encoding="utf-8"
        )
        self.assertNotIn(".ranges(of:", network_source)
        self.assertIn("first-party=fail-closed-7", probe)
        for framework in first_party:
            with self.subTest(framework=framework):
                self.assertIn(framework, source)
                self.assertIn(framework, manifest_source)
                self.assertIn(framework, canonical_source)
                self.assertIn(f"import {framework}", probe)
                self.assertIn(f"-l{framework}", source)

    def test_host_wrapper_refuses_a_mutable_image_tag_before_docker(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            fake_docker = Path(temporary) / "docker"
            write_file(fake_docker, "#!/bin/sh\nexit 91\n")
            fake_docker.chmod(0o755)
            environment = os.environ.copy()
            environment["PATH"] = f"{temporary}:{environment['PATH']}"
            zero = "0" * 40
            result = subprocess.run(
                [
                    "/bin/bash",
                    str(HOST_WRAPPER),
                    "--container-image",
                    "swift-macho-spike:noble",
                    "--support-checkout",
                    "/support",
                    "--expected-support-commit",
                    zero,
                    "--expected-support-tree",
                    zero,
                    "--staged-input-root",
                    "/inputs",
                    "--uikit-checkout",
                    "/uikit",
                    "--expected-uikit-commit",
                    zero,
                    "--expected-uikit-tree",
                    zero,
                    "--machorun-checkout",
                    "/machorun",
                    "--expected-machorun-commit",
                    zero,
                    "--expected-machorun-tree",
                    zero,
                    "--expected-machorun-loader-sha256",
                    "0" * 64,
                    "--output-root",
                    "/new-output",
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=environment,
                check=False,
            )
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("exact sha256 content ID", result.stderr)


if __name__ == "__main__":
    unittest.main()
