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
import sys


HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SCRIPTS = REPO / "full" / "scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))
from guest_arch import guest_arch, macos15_target, swift_module_triple  # noqa: E402

GUEST_ARCH = guest_arch()
MACOS15_TARGET = macos15_target()
SWIFT_MODULE_TRIPLE = swift_module_triple()
TOOL = HERE / "core_package_manifest.py"
BUILDER = HERE / "build_core_guest_package.sh"
FOUNDATION_COMPATIBILITY_PROBE = HERE / "FoundationHackersCompatibilityProbe.swift"
FOUNDATION_DATA_PLATFORM_ORACLE = (
    REPO / "full/foundation/tests/FoundationDataPlatformOracle.swift"
)
FOUNDATION_DATA_PLATFORM_GOLDEN = (
    REPO / "full/foundation/tests/foundation-data-platform-apple-2026-08-31.txt"
)
BUILD_FULL = REPO / "full/scripts/build_full.sh"
SWIFT_CORE_STAGER = REPO / "full/scripts/stage_swift_core_runtime.py"
HOST_WRAPPER = HERE / "run_core_guest_package_docker.sh"
PHYSICAL_REPLAY_TOOL = HERE / "physical_replay.py"
SINGLE_BIND_GUEST_ROOT_SMOKE = HERE / "test_single_bind_guest_root_docker.sh"
APP_DRIVER = REPO / "full/xcodeplan/build_portable_application_guest.sh"
PREVIEW_EXECUTABLE_EXPORT_SYMBOL = (
    "_$s21DeveloperToolsSupport7PreviewV14_openUIKitBodyACypyScMYcc_tcfC"
)
SWIFT_CORE_AVAILABILITY_SYMBOL = (
    "_$ss042_stdlib_isOSVersionAtLeastOrVariantVersiondE0yBi1_Bw_BwBwBwBwBwtF"
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
    (
        "-lswift_errno",
        "/usr/lib/swift/libswift_errno.dylib",
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
    "full/foundation/NotificationCenter+Combine.swift",
    "full/foundation/Progress.swift",
    "full/foundation/NSCache.swift",
    "full/foundation/FileHandle.swift",
    "full/foundation/Data+Searching.swift",
    "full/foundation/CoreFoundationCompatibility.swift",
    "full/foundation/NSURL.swift",
    "full/foundation/String+CharacterSet.swift",
    "full/foundation/String+FoundationCompatibility.swift",
    "full/foundation/Bundle+Localization.swift",
    "full/foundation/LocalizedStringResource.swift",
    "full/foundation/Stream.swift",
    "full/foundation/URLLoading.swift",
    "full/foundation/URLSession.swift",
    "full/foundation/Scanner.swift",
    "full/foundation/NSError.swift",
    "full/foundation/CFError+Error.swift",
    "full/foundation/NSNumber.swift",
    "full/foundation/Error+LocalizedDescription.swift",
    "full/foundation/JSONSerialization.swift",
    "full/foundation/NSRegularExpression.swift",
    "full/foundation/DateFormatter.swift",
    "full/foundation/ByteCountFormatter.swift",
    "full/foundation/UserDefaults.swift",
    "full/foundation/UbiquitousKeyValueStore.swift",
    "full/foundation/RelativeDateTimeFormatter.swift",
    "full/foundation/FileManager+Enumeration.swift",
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
    "FoundationInternationalization",
    "OpenCoreGraphics",
    "OpenUIKit",
    "OpenCombine",
    "Dispatch",
    "Combine",
    "Symbols",
    "SwiftUI",
    "_QuickLook_SwiftUI",
    "_PhotosUI_SwiftUI",
    "_AuthenticationServices_SwiftUI",
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
    "WidgetKit",
    "OSLog",
    "UniformTypeIdentifiers",
    "SwiftData",
    "UserNotifications",
    "BackgroundTasks",
    "CoreSpotlight",
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
    "NaturalLanguage",
    "AuthenticationServices",
    "FoundationModels",
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


def validate_swift_core_runtime_contract(builder: str, wrapper: str) -> None:
    builder_required = (
        f"SWIFT_CORE_REQUIRED_AVAILABILITY_SYMBOL='{SWIFT_CORE_AVAILABILITY_SYMBOL}'",
        "--expected-machorun-swift-core-sha256",
        "--expected-machorun-objc-sha256",
        'SWIFT_CORE_RUNTIME=$RUNTIME/darwin/usr/lib/swift/libswiftCore.dylib',
        'OBJC_RUNTIME=$RUNTIME/darwin/usr/lib/libobjc.A.dylib',
        'SWIFT_CORE_TBD=$STAGE/sdk/usr/lib/swift/libswiftCore.tbd',
        'require_hash "$SWIFT_CORE_RUNTIME" "$EXPECTED_MACHORUN_SWIFT_CORE_SHA256"',
        'swift_core_tbd_symbol_count=$(awk',
        'swift_core_runtime_symbol_count=$(nm_symbol_count --defined-only',
        '[ "$swift_core_tbd_symbol_count" -eq 1 ]',
        '[ "$swift_core_runtime_symbol_count" -eq 1 ]',
        '[ "$swift_core_objc_load_count" -eq 1 ]',
        'require_hash "$OBJC_RUNTIME" "$EXPECTED_MACHORUN_OBJC_SHA256"',
        "format\\tswift-core-runtime-contract-v1",
        "attestation/swift-core-runtime.tsv",
        "attestation/build-full-swift-core-stage.json",
        "post-machorun-Swift-core",
    )
    wrapper_required = (
        "--expected-machorun-swift-core-sha256",
        "--expected-machorun-objc-sha256",
        'MACHORUN_SWIFT_CORE=$MACHORUN_RUNTIME/lib/swift/libswiftCore.dylib',
        'MACHORUN_OBJC=$MACHORUN_RUNTIME/lib/libobjc.A.dylib',
        "ACTUAL_MACHORUN_SWIFT_CORE_SHA256=",
        "COPIED_MACHORUN_SWIFT_CORE_SHA256=",
        "COPIED_MACHORUN_OBJC_SHA256=",
        "physically copied machorun Swift core hash differs",
        "machorun-swift-core\\tsha256=",
        "machorun-objc\\tsha256=",
        "darwin/usr/lib/swift/libswiftCore.dylib",
    )
    missing = [token for token in builder_required if token not in builder]
    missing.extend(token for token in wrapper_required if token not in wrapper)
    if missing:
        raise AssertionError(f"Swift core runtime contract drifted: {missing}")


def validate_build_full_swift_core_source(source: str) -> None:
    required = (
        "SWIFT_CORE_RUNTIME_SOURCE=${SWIFT_CORE_RUNTIME_SOURCE:-$MACHORUN/darwin/usr/lib/swift/libswiftCore.dylib}",
        "SWIFT_CORE_RUNTIME_EXPECTED_SHA256=",
        'python3 -B "$SWIFT_CORE_RUNTIME_STAGER"',
        '--base "$BASE_RUNTIME_SOURCE/darwin/usr/lib/swift/libswiftCore.dylib"',
        '--expected-sha256 "$SWIFT_CORE_RUNTIME_EXPECTED_SHA256"',
        '--report "$OUT/swift-core-runtime-stage.json"',
        '[ "$(basename "$d")" = libswiftCore.dylib ] && continue',
        "staging libswiftCore.dylib from current machorun runtime",
        "copy\\tdarwin/usr/lib/swift/libswiftCore.dylib\\tdarwin/usr/lib/swift/libswiftCore.dylib",
    )
    missing = [token for token in required if token not in source]
    if missing:
        raise AssertionError(f"build_full Swift core source drifted: {missing}")
    stale_override = (
        "for n in libswiftCore.dylib libswiftObjectiveC.dylib "
        "libswift_Concurrency.dylib"
    )
    if stale_override in source:
        raise AssertionError("build_full Swift core source retained stale override")


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
    # Observation, SwiftUI, AppKit, cross-import overlays, WebKit, first-party
    # gates, the reusable link loop, executable probes, all C/frontier
    # executables, AuthenticationServices' overlay/runtime gate, and the
    # SystemConfiguration and CoreLocation framework/oracle/mixed gates share
    # this pinned runtime.
    if source.count('"$SWIFTUI_RUNTIME_LINK_FLAG"') != 36:
        raise AssertionError("SwiftUI runtime-link scope drifted")
    swiftui_link_start = source.index("-install_name @rpath/libSwiftUI.dylib")
    swiftui_link_end = source.index(
        "swiftui_runtime_load_count=", swiftui_link_start
    )
    swiftui_link = source[swiftui_link_start:swiftui_link_end]
    if swiftui_link.count('"$FULL/swiftcorepatch.o"') != 1:
        raise AssertionError("SwiftUI runtime-compatibility thunk scope drifted")


def validate_observation_platform_contract(source: str) -> None:
    required = (
        "EXPECTED_OBSERVATION_UPSTREAM_COMMIT=ee343b46aef81c3ac7c5d7960cb35a41a88c5a9b",
        "EXPECTED_OBSERVATION_SOURCE_COUNT=6",
        "EXPECTED_OBSERVATION_PLUGIN_SHA=ea6510afdd0a9e4808229c52441e9a67ca24e8ce186fccfd082547a5ee1c1229",
        "-module-name Observation -module-link-name swiftObservation",
        "-install_name /usr/lib/swift/libswiftObservation.dylib",
        "-load-plugin-library host-tools/swift/host/plugins/libObservationMacros.so",
        "guest-root/darwin/usr/lib/swift/libswiftObservation.dylib",
        '"$W/full/observation/tests/ObservationGuestRuntimeProbe.swift"',
        "observation=macro,reexport,registrar,tracking,ignored,one-shot",
        "attestation/observation-sources.tsv",
        "attestation/observation-macro-plugin.tsv",
    )
    missing = [token for token in required if token not in source]
    if missing:
        raise AssertionError(f"Observation platform contract drifted: {missing}")
    if source.count("OBSERVATION_PLUGIN_HOST_LIBS=(") != 1:
        raise AssertionError("Observation host plugin closure drifted")
    if source.count("OBSERVATION_PLUGIN_LINUX_LIBS=(") != 1:
        raise AssertionError("Observation Linux plugin closure drifted")


def validate_swiftui_foundation_essentials_link(source: str) -> None:
    start = source.index("-install_name @rpath/libSwiftUI.dylib")
    end = source.index("swiftui_runtime_load_count=", start)
    link_slice = source[start:end]
    required = (
        '"${COMMON_LINK[@]}" -lFoundation -lFoundationEssentials -lOpenUIKit',
        "swiftui_foundation_load_count=",
        '"@rpath/libFoundation.dylib"',
        "swiftui_foundation_essentials_load_count=",
        '"@rpath/libFoundationEssentials.dylib"',
    )
    missing = [token for token in required if token not in link_slice]
    if missing:
        raise AssertionError(
            f"SwiftUI FoundationEssentials link contract drifted: {missing}"
        )


def validate_symbols_platform_contract(source: str) -> None:
    required = (
        "EXPECTED_SYMBOLS_SWIFT_COUNT=1",
        'assert_exact_swift_set "$UIKIT" Sources/Symbols',
        "-module-name Symbols -module-link-name Symbols",
        '-emit-module-path "$STAGE/modules/Symbols.swiftmodule"',
        '-emit-module-interface-path "$STAGE/modules/Symbols.swiftinterface"',
        "-install_name @rpath/libSymbols.dylib",
        "libSymbols Apple Symbols load count",
        '"@rpath/libSymbols.dylib"',
        "libSwiftUI Symbols load count",
        "symbols=values,markers,swiftui-render",
    )
    missing = [token for token in required if token not in source]
    if missing:
        raise AssertionError(f"Symbols platform contract drifted: {missing}")
    swiftui_start = source.index("-install_name @rpath/libSwiftUI.dylib")
    swiftui_end = source.index("swiftui_symbols_load_count=", swiftui_start)
    if "-lSymbols" not in source[swiftui_start:swiftui_end]:
        raise AssertionError("Symbols platform SwiftUI link drifted")


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
        "swiftui_preview_import_count=$(nm_symbol_count --undefined-only",
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


def validate_preview_standalone_link_contract(source: str) -> None:
    required = (
        "PREVIEW_STANDALONE_LINK_INPUTS=()",
        "PREVIEW_STANDALONE_EXPORT_FLAGS=()",
        "PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS=()",
        'PREVIEW_STANDALONE_LINK_INPUTS+=("$STAGE/objects/developertoolsupport.o")',
        "PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS+=(-lOpenUIKit)",
        'preview_standalone_dts_input_count=$((preview_standalone_dts_input_count + 1))',
        '"${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}"',
        '"${PREVIEW_STANDALONE_LINK_INPUTS[@]}"',
    )
    missing = [token for token in required if token not in source]
    if missing:
        raise AssertionError(
            f"standalone SwiftUI Preview link contract drifted: {missing}"
        )
    if source.count('"${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}"') != 9:
        raise AssertionError("standalone SwiftUI Preview export use count drifted")
    if source.count('"${PREVIEW_STANDALONE_LINK_INPUTS[@]}"') != 10:
        # One use audits the source object and nine uses link executables.
        raise AssertionError("standalone SwiftUI Preview link-input use count drifted")
    slices = (
        (
            "compile/link/run the standalone SwiftData macro and persistence gate",
            "compile/link/run the core package probe",
            "swiftdata_preview_export_count=$(nm_symbol_count --defined-only",
        ),
        (
            "compile/link/run the SwiftUI-only Foundation/Combine/Dispatch reexport gate",
            "compile/link/run the full async Foundation URLSession cold gate",
            "swiftui_reexport_preview_export_count=$(nm_symbol_count --defined-only",
        ),
        (
            "compile/link/run the standalone QuickLook controller gate",
            "typecheck an ordinary QuickLook/SwiftUI cross-import consumer",
            "quicklook_preview_export_count=$(nm_symbol_count --defined-only",
        ),
        (
            "compile/link/run the standalone Charts mark and interaction gate",
            "typecheck the exact-surface IceCubes Charts consumer",
            "charts_preview_export_count=$(nm_symbol_count --defined-only",
        ),
        (
            "compile/link/run the standalone WidgetKit timeline and reload gate",
            "typecheck the exact-surface IceCubes WidgetKit consumer",
            "widgetkit_preview_export_count=$(nm_symbol_count --defined-only",
        ),
        (
            "compile/link/run the standalone Photos authorization and asset gate",
            "compile/link/run the core package probe",
            "photos_preview_export_count=$(nm_symbol_count --defined-only",
        ),
        (
            "compile/link/run the standalone PhotosUI transfer and presentation gate",
            "typecheck an ordinary IceCubes PhotosUI/SwiftUI cross-import consumer",
            "photosui_preview_export_count=$(nm_symbol_count --defined-only",
        ),
        (
            "compile/link/run the standalone AuthenticationServices browser gate",
            "typecheck the IceCubes AuthenticationServices cross-import consumer",
            "authenticationservices_preview_export_count=$(nm_symbol_count --defined-only",
        ),
    )
    for start_marker, end_marker, audit in slices:
        start = source.index(start_marker)
        end = source.index(end_marker, start)
        link_slice = source[start:end]
        for token in (
            '"${PREVIEW_STANDALONE_EXPORT_FLAGS[@]}"',
            '"${PREVIEW_STANDALONE_LINK_INPUTS[@]}"',
            audit,
            '"$PREVIEW_EXECUTABLE_EXPORT_SYMBOL"',
        ):
            if token not in link_slice:
                raise AssertionError(
                    f"standalone SwiftUI Preview link slice drifted: {token}"
                )
    swiftdata_start = source.index(slices[0][0])
    swiftdata_end = source.index(slices[0][1], swiftdata_start)
    if '"${PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS[@]}"' not in source[
        swiftdata_start:swiftdata_end
    ]:
        raise AssertionError(
            "standalone SwiftUI Preview nominal DTS link closure drifted"
        )


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
        self.assertEqual(len([line for line in lines if line.startswith("source\t")]), 34)

    def test_reordered_manifest_is_refused(self) -> None:
        reordered = list(FOUNDATION_SOURCES)
        reordered[0], reordered[1] = reordered[1], reordered[0]
        write_file(self.manifest, "\n".join(reordered) + "\n")
        refusal = self.attest(expected=2)
        self.assertIn("exact ordered 34-path contract", refusal.stderr)

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
            "frameworks/IOKit.framework/Headers",
            "frameworks/IOKit.framework/Modules",
            "frameworks/AppKit.framework/Versions/C/Modules/AppKit.swiftmodule",
            "frameworks/SystemConfiguration.framework/Headers",
            "frameworks/SystemConfiguration.framework/Modules",
            "frameworks/CoreLocation.framework/Headers",
            "frameworks/CoreLocation.framework/Modules/CoreLocation.swiftmodule",
            "include",
            "include/CoreImage",
            "include/COpenFoundationCore",
            "include/COpenAccelerate",
            "include/COpenCompression",
            "include/COpenZlib",
            "include/zlib",
            "include/FoundationICU/_foundation_unicode",
            "objects",
            "resources/OpenUIKit/fonts",
            "guest-root/darwin/usr/lib",
            "guest-root/darwin/System/Library/Frameworks/IOKit.framework/Versions/A",
            "guest-root/darwin/System/Library/Frameworks/AppKit.framework/Versions/C",
            "guest-root/darwin/System/Library/Frameworks/SystemConfiguration.framework",
            "guest-root/darwin/System/Library/Frameworks/CoreLocation.framework",
            "guest-root/host",
            "host-tools/swift/host/plugins",
            "host-tools/swift/linux",
            "probe",
            "attestation",
        ):
            (root / relative).mkdir(parents=True, exist_ok=True)
        for framework in FRAMEWORKS:
            write_file(root / f"modules/{framework}.swiftmodule", framework)
            write_file(root / f"lib/lib{framework}.dylib", f"dylib:{framework}")
        write_file(
            root / "modules/QuickLook.swiftcrossimport/SwiftUI.swiftoverlay",
            "_QuickLook_SwiftUI\n",
        )
        write_file(
            root / "modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay",
            "_PhotosUI_SwiftUI\n",
        )
        write_file(
            root
            / "modules/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay",
            "_AuthenticationServices_SwiftUI\n",
        )
        for dependency in DEPENDENCIES:
            write_file(root / f"modules/{dependency}.swiftmodule", dependency)
        write_file(root / "include/CoreImage/CoreImage.h", "umbrella")
        write_file(
            root / "include/CoreImage/CIFilterBuiltins.h", "generated filters"
        )
        write_file(root / "include/CoreImage/module.modulemap", "module CoreImage {}")
        write_file(
            root / "include/COpenFoundationCore/OpenFoundationCFError.h",
            "typedef struct __CFError *CFErrorRef;\n",
        )
        write_file(
            root / "include/COpenFoundationCore/module.modulemap",
            "module COpenFoundationCore {}\n",
        )
        write_file(root / "include/COpenAccelerate/Accelerate.h", "vImage\n")
        write_file(
            root / "include/COpenAccelerate/module.modulemap",
            "module COpenAccelerate {}\n",
        )
        write_file(
            root / "include/COpenCompression/OpenCompressionABI.h",
            "compression ABI\n",
        )
        write_file(
            root / "include/COpenCompression/module.modulemap",
            "module COpenCompression {}\n",
        )
        write_file(
            root / "include/COpenZlib/OpenZlibABI.h",
            "zlib host ABI\n",
        )
        write_file(
            root / "include/COpenZlib/module.modulemap",
            "module COpenZlib {}\n",
        )
        write_file(root / "include/zlib/zlib.h", "z_stream\n")
        write_file(
            root / "include/zlib/module.modulemap",
            "module zlib { link \"z\" }\n",
        )
        write_file(
            root / "include/FoundationICU/_foundation_unicode/module.modulemap",
            "module _FoundationICU { export * }",
        )
        write_file(root / "lib/lib_FoundationICU.dylib", "full pinned ICU")
        write_file(root / "guest-root/darwin/usr/lib/libquartz.dylib", "quartz")
        write_file(
            root
            / "guest-root/darwin/usr/lib/libOpenFoundationInternationalization.dylib",
            "intl bridge",
        )
        write_file(
            root / "guest-root/host/libOpenFoundationInternationalizationHost.so",
            "intl host",
        )
        write_file(
            root / "guest-root/host/libOpenCompressionHost.so",
            "compression host",
        )
        write_file(
            root / "guest-root/darwin/usr/lib/libOpenCompression.dylib",
            "compression bridge",
        )
        write_file(root / "lib/libz.dylib", "zlib bridge")
        write_file(
            root / "guest-root/darwin/usr/lib/libOpenZlib.dylib",
            "zlib runtime bridge",
        )
        write_file(
            root / "guest-root/host/libOpenZlibHost.so",
            "zlib host",
        )
        write_file(
            root / "frameworks/IOKit.framework/Headers/IOKit.h",
            "portable IOKit ABI\n",
        )
        write_file(
            root / "frameworks/IOKit.framework/Modules/module.modulemap",
            "framework module IOKit {}\n",
        )
        write_file(root / "modules/IOKit.swiftmodule", "portable Swift overlay")
        write_file(root / "frameworks/IOKit.framework/IOKit", "IOKit Mach-O")
        write_file(
            root
            / "guest-root/darwin/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit",
            "IOKit Mach-O",
        )
        write_file(
            root / "guest-root/darwin/usr/lib/swift/libswiftIOKit.dylib",
            "open Swift IOKit overlay runtime",
        )
        for suffix in (
            "abi.json",
            "private.swiftinterface",
            "swiftdoc",
            "swiftinterface",
            "swiftmodule",
            "swiftsourceinfo",
        ):
            write_file(
                root
                / "frameworks/AppKit.framework/Versions/C/Modules/"
                f"AppKit.swiftmodule/{SWIFT_MODULE_TRIPLE}.{suffix}",
                f"AppKit:{suffix}\n",
            )
        write_file(
            root / "frameworks/AppKit.framework/Versions/C/AppKit",
            "AppKit ARM64 Mach-O",
        )
        write_file(
            root
            / "guest-root/darwin/System/Library/Frameworks/"
            "AppKit.framework/Versions/C/AppKit",
            "AppKit ARM64 Mach-O",
        )
        os.symlink("C", root / "frameworks/AppKit.framework/Versions/Current")
        os.symlink(
            "Versions/Current/AppKit", root / "frameworks/AppKit.framework/AppKit"
        )
        os.symlink(
            "Versions/Current/Modules", root / "frameworks/AppKit.framework/Modules"
        )
        for header in (
            "OpenSystemConfiguration.h",
            "SCNetwork.h",
            "SCNetworkReachability.h",
            "SystemConfiguration.h",
        ):
            write_file(
                root / f"frameworks/SystemConfiguration.framework/Headers/{header}",
                f"portable SystemConfiguration ABI: {header}\n",
            )
        write_file(
            root
            / "frameworks/SystemConfiguration.framework/Modules/module.modulemap",
            "framework module SystemConfiguration {}\n",
        )
        write_file(
            root / "frameworks/SystemConfiguration.framework/SystemConfiguration",
            "SystemConfiguration Mach-O",
        )
        write_file(
            root
            / "guest-root/darwin/System/Library/Frameworks/"
            "SystemConfiguration.framework/SystemConfiguration",
            "SystemConfiguration Mach-O",
        )
        write_file(
            root / "frameworks/CoreLocation.framework/Headers/CoreLocation.h",
            "portable CoreLocation ABI\n",
        )
        write_file(
            root / "frameworks/CoreLocation.framework/Modules/module.modulemap",
            "framework module CoreLocation {}\n",
        )
        for suffix in (
            "abi.json",
            "private.swiftinterface",
            "swiftdoc",
            "swiftinterface",
            "swiftmodule",
            "swiftsourceinfo",
        ):
            write_file(
                root
                / "frameworks/CoreLocation.framework/Modules/"
                f"CoreLocation.swiftmodule/{SWIFT_MODULE_TRIPLE}.{suffix}",
                f"CoreLocation:{suffix}\n",
            )
        write_file(
            root / "frameworks/CoreLocation.framework/CoreLocation",
            "CoreLocation mixed Mach-O",
        )
        write_file(
            root
            / "guest-root/darwin/System/Library/Frameworks/"
            "CoreLocation.framework/CoreLocation",
            "CoreLocation mixed Mach-O",
        )
        write_file(root / "guest-root/machorun", "loader")
        write_file(root / "guest-root/.manifest", "fixture-root\n")
        write_file(
            root / "host-tools/swift/host/plugins/libObservationMacros.so",
            "observation macros",
        )
        write_file(
            root / "host-tools/swift/host/plugins/libFoundationMacros.so",
            "foundation macros",
        )
        write_file(
            root / "host-tools/swift/host/plugins/libSwiftDataMacros.so",
            "swiftdata macros",
        )
        write_file(
            root / "host-tools/swift/host/plugins/libFoundationModelsMacros.so",
            "foundation models macros",
        )
        write_file(
            root / "host-tools/swift/host/plugins/libOpenUIKitPreviewMacros.so",
            "open uikit preview macros",
        )
        write_file(
            root / "host-tools/swift/host/plugins/libOpenSwiftUIMacros.so",
            "open swiftui macros",
        )
        write_file(
            root / "host-tools/swift/linux/libswiftCore.so",
            "host Swift runtime",
        )
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
            "appkit-sources.tsv",
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
            MACOS15_TARGET,
            "-sdk",
            "sdk",
            "-F",
            "frameworks",
            "-Xfrontend",
            "-enable-cross-import-overlays",
            "-I",
            "modules",
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
            "-load-plugin-library",
            "host-tools/swift/host/plugins/libObservationMacros.so",
            "-load-plugin-library",
            "host-tools/swift/host/plugins/libFoundationMacros.so",
            "-load-plugin-library",
            "host-tools/swift/host/plugins/libSwiftDataMacros.so",
            "-load-plugin-library",
            "host-tools/swift/host/plugins/libFoundationModelsMacros.so",
            "-load-plugin-library",
            "host-tools/swift/host/plugins/libOpenUIKitPreviewMacros.so",
            "-load-plugin-library",
            "host-tools/swift/host/plugins/libOpenSwiftUIMacros.so",
        ]
        self.link_arguments = [
            "-arch",
            GUEST_ARCH,
            "-platform_version",
            "macos",
            "15.0",
            "15.0",
            "-syslibroot",
            "sdk",
            "-F",
            "frameworks",
            "-framework",
            "AppKit",
            "-framework",
            "IOKit",
            "-framework",
            "SystemConfiguration",
            "-framework",
            "CoreLocation",
            "-lswiftIOKit",
            "-Llib",
            "-lUIKit",
            "-lCoreImage",
            "-lQuartzCore",
            "-lFoundation",
            "-lFoundationInternationalization",
            "-lFoundationEssentials",
            "-lSymbols",
            "-lSwiftUI",
            "-l_QuickLook_SwiftUI",
            "-l_PhotosUI_SwiftUI",
            "-l_AuthenticationServices_SwiftUI",
            "-lIntentsUI",
            "-lIntents",
            "-lWebKit",
            "-lOpenUIKit",
            "-lOpenCoreGraphics",
            "-lCombine",
            "-lOpenCombine",
            "-lDispatch",
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
            "-lWidgetKit",
            "-lOSLog",
            "-lUniformTypeIdentifiers",
            "-lSwiftData",
            "-lUserNotifications",
            "-lBackgroundTasks",
            "-lCoreSpotlight",
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
            "-lNaturalLanguage",
            "-lAuthenticationServices",
            "-lFoundationModels",
        ]
        (root / "compile-flags.rsp").write_bytes(
            b"".join(token.encode() + b"\0" for token in self.compile_arguments)
        )
        (root / "link-inputs.rsp").write_bytes(
            b"".join(token.encode() + b"\0" for token in self.link_arguments)
        )
        closure_path = "host-tools/swift/linux/libswiftCore.so"
        plugin_rows = (
            (
                "ObservationMacros",
                "libObservationMacros.so",
                "ObservableMacro,ObservationIgnoredMacro,ObservationTrackedMacro",
            ),
            (
                "FoundationMacros",
                "libFoundationMacros.so",
                "ExpressionMacro,PredicateMacro",
            ),
            (
                "SwiftDataMacros",
                "libSwiftDataMacros.so",
                "PersistentModelMacro",
            ),
            (
                "FoundationModelsMacros",
                "libFoundationModelsMacros.so",
                "GenerableMacro,GuideMacro",
            ),
            (
                "OpenUIKitPreviewMacros",
                "libOpenUIKitPreviewMacros.so",
                "UIKitPreviewMacro",
            ),
            (
                "OpenSwiftUIMacros",
                "libOpenSwiftUIMacros.so",
                "EntryMacro",
            ),
        )
        compiler_plugin_lines = ["format\tcore-compiler-plugins-v1"]
        for module, basename, registrations in plugin_rows:
            relative = f"host-tools/swift/host/plugins/{basename}"
            compiler_plugin_lines.append(
                "\t".join(
                    (
                        "plugin", module, "library", relative,
                        sha256(root / relative), registrations,
                        "app,framework,package", "serialized=no",
                    )
                )
            )
        for module, _basename, _registrations in plugin_rows:
            compiler_plugin_lines.append(
                "\t".join(
                    (
                        "closure", module, closure_path,
                        sha256(root / closure_path),
                    )
                )
            )
        write_file(
            root / "attestation/compiler-plugins.tsv",
            "\n".join(compiler_plugin_lines) + "\n",
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
        records.append(
            self._artifact(
                "module-metadata",
                "QuickLook",
                "cross-import-overlay",
                "modules/QuickLook.swiftcrossimport/SwiftUI.swiftoverlay",
            )
        )
        records.append(
            self._artifact(
                "module-metadata",
                "PhotosUI",
                "cross-import-overlay",
                "modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay",
            )
        )
        records.append(
            self._artifact(
                "module-metadata",
                "AuthenticationServices",
                "cross-import-overlay",
                "modules/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay",
            )
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
        records.append(
            self._artifact(
                "module-dependency",
                "_FoundationICU",
                "dylib",
                "lib/lib_FoundationICU.dylib",
            )
        )
        records.append(
            self._artifact(
                "module-dependency",
                "_FoundationICU",
                "module-map",
                "include/FoundationICU/_foundation_unicode/module.modulemap",
            )
        )
        records.extend(
            (
                *(
                    self._artifact(
                        "framework",
                        "AppKit",
                        role,
                        "frameworks/AppKit.framework/Versions/C/Modules/"
                        f"AppKit.swiftmodule/{SWIFT_MODULE_TRIPLE}.{suffix}",
                    )
                    for role, suffix in (
                        ("abi-json", "abi.json"),
                        ("private-swiftinterface", "private.swiftinterface"),
                        ("swiftdoc", "swiftdoc"),
                        ("swiftinterface", "swiftinterface"),
                        ("swiftmodule", "swiftmodule"),
                        ("swiftsourceinfo", "swiftsourceinfo"),
                    )
                ),
                self._artifact(
                    "framework",
                    "AppKit",
                    "dylib",
                    "frameworks/AppKit.framework/Versions/C/AppKit",
                ),
                self._artifact(
                    "runtime",
                    "AppKit",
                    "framework-dylib",
                    "guest-root/darwin/System/Library/Frameworks/"
                    "AppKit.framework/Versions/C/AppKit",
                ),
                self._artifact(
                    "framework",
                    "IOKit",
                    "swiftmodule",
                    "modules/IOKit.swiftmodule",
                ),
                self._artifact(
                    "include",
                    "IOKit",
                    "framework-header",
                    "frameworks/IOKit.framework/Headers/IOKit.h",
                ),
                self._artifact(
                    "include",
                    "IOKit",
                    "framework-module-map",
                    "frameworks/IOKit.framework/Modules/module.modulemap",
                ),
                self._artifact(
                    "framework",
                    "IOKit",
                    "c-dylib",
                    "frameworks/IOKit.framework/IOKit",
                ),
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
                self._artifact(
                    "include",
                    "COpenFoundationCore",
                    "opaque-header",
                    "include/COpenFoundationCore/OpenFoundationCFError.h",
                ),
                self._artifact(
                    "include",
                    "COpenFoundationCore",
                    "module-map",
                    "include/COpenFoundationCore/module.modulemap",
                ),
                self._artifact(
                    "include",
                    "COpenAccelerate",
                    "abi-header",
                    "include/COpenAccelerate/Accelerate.h",
                ),
                self._artifact(
                    "include",
                    "COpenAccelerate",
                    "module-map",
                    "include/COpenAccelerate/module.modulemap",
                ),
                self._artifact(
                    "include",
                    "COpenCompression",
                    "abi-header",
                    "include/COpenCompression/OpenCompressionABI.h",
                ),
                self._artifact(
                    "include",
                    "COpenCompression",
                    "module-map",
                    "include/COpenCompression/module.modulemap",
                ),
                self._artifact(
                    "include",
                    "COpenZlib",
                    "abi-header",
                    "include/COpenZlib/OpenZlibABI.h",
                ),
                self._artifact(
                    "include",
                    "COpenZlib",
                    "module-map",
                    "include/COpenZlib/module.modulemap",
                ),
                self._artifact(
                    "include",
                    "zlib",
                    "abi-header",
                    "include/zlib/zlib.h",
                ),
                self._artifact(
                    "include",
                    "zlib",
                    "module-map",
                    "include/zlib/module.modulemap",
                ),
            )
        )
        for header in (
            "OpenSystemConfiguration.h",
            "SCNetwork.h",
            "SCNetworkReachability.h",
            "SystemConfiguration.h",
        ):
            records.append(
                self._artifact(
                    "include",
                    "SystemConfiguration",
                    "framework-header",
                    f"frameworks/SystemConfiguration.framework/Headers/{header}",
                )
            )
        records.append(
            self._artifact(
                "include",
                "SystemConfiguration",
                "framework-module-map",
                "frameworks/SystemConfiguration.framework/Modules/module.modulemap",
            )
        )
        records.append(
            self._artifact(
                "framework",
                "SystemConfiguration",
                "objc-dylib",
                "frameworks/SystemConfiguration.framework/SystemConfiguration",
            )
        )
        records.append(
            self._artifact(
                "include",
                "CoreLocation",
                "framework-header",
                "frameworks/CoreLocation.framework/Headers/CoreLocation.h",
            )
        )
        records.append(
            self._artifact(
                "include",
                "CoreLocation",
                "framework-module-map",
                "frameworks/CoreLocation.framework/Modules/module.modulemap",
            )
        )
        for role, suffix in (
            ("abi-json", "abi.json"),
            ("private-swiftinterface", "private.swiftinterface"),
            ("swiftdoc", "swiftdoc"),
            ("swiftinterface", "swiftinterface"),
            ("swiftmodule", "swiftmodule"),
            ("swiftsourceinfo", "swiftsourceinfo"),
        ):
            records.append(
                self._artifact(
                    "framework",
                    "CoreLocation",
                    role,
                    "frameworks/CoreLocation.framework/Modules/"
                    f"CoreLocation.swiftmodule/{SWIFT_MODULE_TRIPLE}.{suffix}",
                )
            )
        records.append(
            self._artifact(
                "framework",
                "CoreLocation",
                "mixed-dylib",
                "frameworks/CoreLocation.framework/CoreLocation",
            )
        )
        records.append(
            self._artifact(
                "runtime", "CQuartz", "dylib", "guest-root/darwin/usr/lib/libquartz.dylib"
            )
        )
        records.append(
            self._artifact(
                "runtime",
                "OpenFoundationInternationalization",
                "darwin-bridge",
                "guest-root/darwin/usr/lib/libOpenFoundationInternationalization.dylib",
            )
        )
        records.append(
            self._artifact(
                "runtime",
                "Compression",
                "darwin-bridge",
                "guest-root/darwin/usr/lib/libOpenCompression.dylib",
            )
        )
        records.append(
            self._artifact(
                "runtime",
                "Compression",
                "linux-helper",
                "guest-root/host/libOpenCompressionHost.so",
            )
        )
        records.append(
            self._artifact("runtime", "zlib", "darwin-dylib", "lib/libz.dylib")
        )
        records.append(
            self._artifact(
                "runtime",
                "zlib",
                "darwin-bridge",
                "guest-root/darwin/usr/lib/libOpenZlib.dylib",
            )
        )
        records.append(
            self._artifact(
                "runtime",
                "zlib",
                "linux-helper",
                "guest-root/host/libOpenZlibHost.so",
            )
        )
        records.append(
            self._artifact(
                "runtime",
                "OpenFoundationInternationalization",
                "linux-helper",
                "guest-root/host/libOpenFoundationInternationalizationHost.so",
            )
        )
        records.append(
            self._artifact(
                "runtime",
                "IOKit",
                "framework-dylib",
                "guest-root/darwin/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit",
            )
        )
        records.append(
            self._artifact(
                "runtime",
                "SwiftIOKit",
                "overlay-dylib",
                "guest-root/darwin/usr/lib/swift/libswiftIOKit.dylib",
            )
        )
        records.append(
            self._artifact(
                "runtime",
                "SystemConfiguration",
                "framework-dylib",
                "guest-root/darwin/System/Library/Frameworks/"
                "SystemConfiguration.framework/SystemConfiguration",
            )
        )
        records.append(
            self._artifact(
                "runtime",
                "CoreLocation",
                "framework-dylib",
                "guest-root/darwin/System/Library/Frameworks/"
                "CoreLocation.framework/CoreLocation",
            )
        )
        records.append(self._artifact("runtime", "machorun", "executable", "guest-root/machorun"))
        records.append(
            self._artifact(
                "host-tool",
                "ObservationMacros",
                "plugin",
                "host-tools/swift/host/plugins/libObservationMacros.so",
            )
        )
        records.append(
            self._artifact(
                "host-tool",
                "FoundationMacros",
                "plugin",
                "host-tools/swift/host/plugins/libFoundationMacros.so",
            )
        )
        records.append(
            self._artifact(
                "host-tool",
                "SwiftDataMacros",
                "plugin",
                "host-tools/swift/host/plugins/libSwiftDataMacros.so",
            )
        )
        records.append(
            self._artifact(
                "host-tool",
                "FoundationModelsMacros",
                "plugin",
                "host-tools/swift/host/plugins/libFoundationModelsMacros.so",
            )
        )
        records.append(
            self._artifact(
                "host-tool",
                "OpenUIKitPreviewMacros",
                "plugin",
                "host-tools/swift/host/plugins/libOpenUIKitPreviewMacros.so",
            )
        )
        records.append(
            self._artifact(
                "host-tool",
                "OpenSwiftUIMacros",
                "plugin",
                "host-tools/swift/host/plugins/libOpenSwiftUIMacros.so",
            )
        )
        records.append(
            self._artifact(
                "host-tool",
                "ObservationMacros",
                "dependency",
                "host-tools/swift/linux/libswiftCore.so",
            )
        )
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
            "--appkit-sources",
            "attestation/appkit-sources.tsv",
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
            "--compiler-plugins",
            "attestation/compiler-plugins.tsv",
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
        self.assertEqual(document["target"]["triple"], MACOS15_TARGET)
        self.assertEqual(document["paths"]["resources"], "resources/OpenUIKit")
        self.assertEqual(document["paths"]["host_tools"], "host-tools")
        self.assertIsNone(document["preview"])
        self.assertNotIn(str(self.base), json.dumps(document))
        relocated = self.base / "relocated package with spaces"
        shutil.copytree(fixture.root, relocated, symlinks=True)
        run_tool("verify", "--package-root", str(relocated))
        summary = run_canonical(relocated)
        self.assertIn("preview=no", summary.stdout)

    def test_cross_import_overlay_is_typed_and_unknown_category_is_refused(self) -> None:
        fixture = self.fixture(False)
        document = json.loads(
            (fixture.root / "attestation/core-package.json").read_text()
        )
        overlays = [
            artifact
            for artifact in document["artifacts"]
            if artifact["category"] == "module-metadata"
        ]
        self.assertEqual(
            [(item["name"], item["path"], item["role"]) for item in overlays],
            [
                (
                    "QuickLook",
                    "modules/QuickLook.swiftcrossimport/SwiftUI.swiftoverlay",
                    "cross-import-overlay",
                ),
                (
                    "PhotosUI",
                    "modules/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay",
                    "cross-import-overlay",
                ),
                (
                    "AuthenticationServices",
                    "modules/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay",
                    "cross-import-overlay",
                ),
            ],
        )
        for item in overlays:
            path = fixture.root / item["path"]
            self.assertEqual(item["sha256"], sha256(path))
            self.assertEqual(item["size"], path.stat().st_size)

        ledger = fixture.root / "attestation/artifacts.tsv"
        ledger.write_text(
            ledger.read_text(encoding="utf-8").replace(
                "module-metadata\tQuickLook\t",
                "module_metadata\tQuickLook\t",
                1,
            ),
            encoding="utf-8",
            newline="\n",
        )
        refusal = fixture.write_manifest(expected=2)
        self.assertIn("unknown artifact category", refusal.stderr)

    def test_authenticationservices_cross_import_overlay_is_required(self) -> None:
        fixture = self.fixture(False)
        ledger = fixture.root / "attestation/artifacts.tsv"
        lines = ledger.read_text(encoding="utf-8").splitlines()
        ledger.write_text(
            "\n".join(
                line
                for line in lines
                if "modules/AuthenticationServices.swiftcrossimport/"
                not in line
            )
            + "\n",
            encoding="utf-8",
            newline="\n",
        )
        refusal = fixture.write_manifest(expected=2)
        self.assertIn("AuthenticationServices", refusal.stderr)
        self.assertIn("cross-import overlay", refusal.stderr)

    def test_compiler_plugin_manifest_is_structured_and_relocatable(self) -> None:
        fixture = self.fixture(False)
        document = json.loads(
            (fixture.root / "attestation/core-package.json").read_text()
        )
        plugins = document["compiler_plugins"]
        self.assertEqual(
            [plugin["module"] for plugin in plugins],
            [
                "ObservationMacros",
                "FoundationMacros",
                "SwiftDataMacros",
                "FoundationModelsMacros",
                "OpenUIKitPreviewMacros",
                "OpenSwiftUIMacros",
            ],
        )
        self.assertEqual(
            {plugin["module"]: plugin["registrations"] for plugin in plugins},
            {
                "ObservationMacros": [
                    "ObservableMacro",
                    "ObservationIgnoredMacro",
                    "ObservationTrackedMacro",
                ],
                "FoundationMacros": ["ExpressionMacro", "PredicateMacro"],
                "SwiftDataMacros": ["PersistentModelMacro"],
                "FoundationModelsMacros": ["GenerableMacro", "GuideMacro"],
                "OpenUIKitPreviewMacros": ["UIKitPreviewMacro"],
                "OpenSwiftUIMacros": ["EntryMacro"],
            },
        )
        for plugin in plugins:
            self.assertEqual(plugin["load_kind"], "library")
            self.assertEqual(
                plugin["consumer_scopes"], ["app", "framework", "package"]
            )
            self.assertFalse(plugin["serialized_jobs"])
            self.assertEqual(
                [item["path"] for item in plugin["host_closure"]],
                ["host-tools/swift/linux/libswiftCore.so"],
            )

    def test_compiler_plugin_closure_scope_and_load_mutations_are_refused(self) -> None:
        for mutation, expected in (
            (
                lambda text: "\n".join(
                    line
                    for line in text.splitlines()
                    if not line.startswith("closure\tFoundationMacros\t")
                )
                + "\n",
                "native host closure is incomplete",
            ),
            (
                lambda text: text.replace(
                    "\tapp,framework,package\t", "\tapp,package\t", 1
                ),
                "consumer scopes",
            ),
            (
                lambda text: "\n".join(
                    line
                    for line in text.splitlines()
                    if not (
                        line.startswith("plugin\tOpenSwiftUIMacros\t")
                        or line.startswith("closure\tOpenSwiftUIMacros\t")
                    )
                )
                + "\n",
                "omits required modules: OpenSwiftUIMacros",
            ),
        ):
            with self.subTest(expected=expected), tempfile.TemporaryDirectory() as temporary:
                fixture = PackageFixture(Path(temporary) / "package", preview=False)
                path = fixture.root / "attestation/compiler-plugins.tsv"
                path.write_text(mutation(path.read_text(encoding="utf-8")), encoding="utf-8")
                refusal = fixture.write_manifest(expected=2)
                self.assertIn(expected, refusal.stderr)

        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            value = "host-tools/swift/host/plugins/libSwiftDataMacros.so"
            index = fixture.compile_arguments.index(value)
            del fixture.compile_arguments[index - 1 : index + 1]
            (fixture.root / "compile-flags.rsp").write_bytes(
                b"".join(token.encode() + b"\0" for token in fixture.compile_arguments)
            )
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("SwiftDataMacros compiler-plugin load pair count 0", refusal.stderr)

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
        shutil.copytree(fixture.root, relocated, symlinks=True)
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

    def test_iokit_framework_identity_and_contract_are_mandatory(self) -> None:
        fixture = self.fixture(False)
        document = json.loads(
            (fixture.root / "attestation/core-package.json").read_text(
                encoding="utf-8"
            )
        )
        iokit = {
            artifact["path"]: (artifact["category"], artifact["name"], artifact["role"])
            for artifact in document["artifacts"]
            if artifact["name"] == "IOKit"
        }
        self.assertEqual(
            iokit,
            {
                "modules/IOKit.swiftmodule": (
                    "framework",
                    "IOKit",
                    "swiftmodule",
                ),
                "frameworks/IOKit.framework/Headers/IOKit.h": (
                    "include",
                    "IOKit",
                    "framework-header",
                ),
                "frameworks/IOKit.framework/Modules/module.modulemap": (
                    "include",
                    "IOKit",
                    "framework-module-map",
                ),
                "frameworks/IOKit.framework/IOKit": (
                    "framework",
                    "IOKit",
                    "c-dylib",
                ),
                "guest-root/darwin/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit": (
                    "runtime",
                    "IOKit",
                    "framework-dylib",
                ),
            },
        )
        self.assertEqual(
            document["swift_compile_arguments"].count("frameworks"), 1
        )
        self.assertEqual(
            document["executable_link_arguments"].count("IOKit"), 1
        )
        self.assertEqual(
            document["executable_link_arguments"].count("-lswiftIOKit"), 1
        )
        self.assertEqual(
            [
                artifact["path"]
                for artifact in document["artifacts"]
                if artifact["name"] == "SwiftIOKit"
            ],
            ["guest-root/darwin/usr/lib/swift/libswiftIOKit.dylib"],
        )

        write_file(
            fixture.root / "frameworks/IOKit.framework/Headers/Stale.h",
            "stale",
        )
        refusal = run_tool(
            "verify", "--package-root", str(fixture.root), expected=2
        )
        self.assertIn("artifact coverage drifted under frameworks", refusal.stderr)

    def test_iokit_framework_artifacts_and_flag_pairs_are_refused_when_missing(
        self,
    ) -> None:
        iokit_paths = (
            "modules/IOKit.swiftmodule",
            "frameworks/IOKit.framework/Headers/IOKit.h",
            "frameworks/IOKit.framework/Modules/module.modulemap",
            "frameworks/IOKit.framework/IOKit",
            "guest-root/darwin/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit",
            "guest-root/darwin/usr/lib/swift/libswiftIOKit.dylib",
        )
        for relative in iokit_paths:
            with self.subTest(relative=relative), tempfile.TemporaryDirectory() as temporary:
                fixture = PackageFixture(Path(temporary) / "package", preview=False)
                ledger = fixture.root / "attestation/artifacts.tsv"
                ledger.write_text(
                    "\n".join(
                        line
                        for line in ledger.read_text(encoding="utf-8").splitlines()
                        if relative not in line
                    )
                    + "\n",
                    encoding="utf-8",
                )
                refusal = fixture.write_manifest(expected=2)
                self.assertIn("IOKit framework boundary artifacts", refusal.stderr)

        for arguments_name, pair, diagnostic in (
            ("compile_arguments", ["-F", "frameworks"], "framework search pair"),
            ("link_arguments", ["-F", "frameworks"], "framework pair"),
            ("link_arguments", ["-framework", "IOKit"], "framework pair"),
        ):
            with self.subTest(pair=pair), tempfile.TemporaryDirectory() as temporary:
                fixture = PackageFixture(Path(temporary) / "package", preview=False)
                values = getattr(fixture, arguments_name)
                index = next(
                    index
                    for index in range(len(values) - 1)
                    if values[index : index + 2] == pair
                )
                del values[index : index + 2]
                response = (
                    "compile-flags.rsp"
                    if arguments_name == "compile_arguments"
                    else "link-inputs.rsp"
                )
                (fixture.root / response).write_bytes(
                    b"".join(token.encode() + b"\0" for token in values)
                )
                refusal = fixture.write_manifest(expected=2)
                self.assertIn(diagnostic, refusal.stderr)

        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            fixture.link_arguments.remove("-lswiftIOKit")
            (fixture.root / "link-inputs.rsp").write_bytes(
                b"".join(token.encode() + b"\0" for token in fixture.link_arguments)
            )
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("Swift IOKit overlay runtime", refusal.stderr)

    def test_appkit_versioned_framework_identity_is_exact(self) -> None:
        fixture = self.fixture(False)
        document = json.loads(
            (fixture.root / "attestation/core-package.json").read_text(
                encoding="utf-8"
            )
        )
        appkit = {
            artifact["path"]: (artifact["category"], artifact["role"])
            for artifact in document["artifacts"]
            if artifact["name"] == "AppKit"
        }
        expected_paths = {
            "frameworks/AppKit.framework/Versions/C/Modules/"
            f"AppKit.swiftmodule/{SWIFT_MODULE_TRIPLE}.{suffix}"
            for suffix in (
                "abi.json",
                "private.swiftinterface",
                "swiftdoc",
                "swiftinterface",
                "swiftmodule",
                "swiftsourceinfo",
            )
        }
        expected_paths.update(
            {
                "frameworks/AppKit.framework/Versions/C/AppKit",
                "guest-root/darwin/System/Library/Frameworks/"
                "AppKit.framework/Versions/C/AppKit",
            }
        )
        self.assertEqual(set(appkit), expected_paths)
        self.assertEqual(
            os.readlink(fixture.root / "frameworks/AppKit.framework/AppKit"),
            "Versions/Current/AppKit",
        )
        self.assertEqual(
            os.readlink(fixture.root / "frameworks/AppKit.framework/Modules"),
            "Versions/Current/Modules",
        )
        self.assertEqual(
            os.readlink(
                fixture.root / "frameworks/AppKit.framework/Versions/Current"
            ),
            "C",
        )
        self.assertEqual(
            document["executable_link_arguments"].count("AppKit"), 1
        )
        self.assertNotIn("-lAppKit", document["executable_link_arguments"])

    def test_appkit_artifact_identity_link_and_symlink_mutations_are_refused(
        self,
    ) -> None:
        appkit_paths = (
            "frameworks/AppKit.framework/Versions/C/Modules/"
            f"AppKit.swiftmodule/{SWIFT_MODULE_TRIPLE}.swiftmodule",
            "frameworks/AppKit.framework/Versions/C/AppKit",
            "guest-root/darwin/System/Library/Frameworks/"
            "AppKit.framework/Versions/C/AppKit",
        )
        for relative in appkit_paths:
            with self.subTest(relative=relative), tempfile.TemporaryDirectory() as temporary:
                fixture = PackageFixture(Path(temporary) / "package", preview=False)
                ledger = fixture.root / "attestation/artifacts.tsv"
                ledger.write_text(
                    "\n".join(
                        line
                        for line in ledger.read_text(encoding="utf-8").splitlines()
                        if relative not in line
                    )
                    + "\n",
                    encoding="utf-8",
                )
                refusal = fixture.write_manifest(expected=2)
                self.assertIn("AppKit versioned framework boundary", refusal.stderr)

        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            runtime = (
                fixture.root
                / "guest-root/darwin/System/Library/Frameworks/"
                "AppKit.framework/Versions/C/AppKit"
            )
            write_file(runtime, "different AppKit runtime")
            fixture._write_ledger()
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("compile/runtime framework identities differ", refusal.stderr)

        for relative, wrong_target in (
            ("AppKit.framework/AppKit", "Versions/C/AppKit"),
            ("AppKit.framework/Modules", "Versions/C/Modules"),
            ("AppKit.framework/Versions/Current", "D"),
        ):
            for replacement in ("missing", wrong_target):
                with (
                    self.subTest(symlink=relative, replacement=replacement),
                    tempfile.TemporaryDirectory() as temporary,
                ):
                    fixture = PackageFixture(
                        Path(temporary) / "package", preview=False
                    )
                    fixture.write_manifest()
                    link = fixture.root / "frameworks" / relative
                    link.unlink()
                    if replacement != "missing":
                        os.symlink(replacement, link)
                    refusal = run_tool(
                        "verify", "--package-root", str(fixture.root), expected=2
                    )
                    self.assertIn("symlink contract drifted", refusal.stderr)

        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            write_file(fixture.root / "lib/libAppKit.dylib", "flat AppKit")
            fixture._write_ledger()
            ledger = fixture.root / "attestation/artifacts.tsv"
            with ledger.open("a", encoding="utf-8", newline="\n") as handle:
                handle.write(
                    fixture._artifact(
                        "framework", "AppKit", "dylib", "lib/libAppKit.dylib"
                    )
                    + "\n"
                )
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("not libAppKit", refusal.stderr)

        for replacement in ("missing", "flat"):
            with self.subTest(link=replacement), tempfile.TemporaryDirectory() as temporary:
                fixture = PackageFixture(Path(temporary) / "package", preview=False)
                index = next(
                    index
                    for index in range(len(fixture.link_arguments) - 1)
                    if fixture.link_arguments[index : index + 2]
                    == ["-framework", "AppKit"]
                )
                del fixture.link_arguments[index : index + 2]
                if replacement == "flat":
                    fixture.link_arguments.append("-lAppKit")
                (fixture.root / "link-inputs.rsp").write_bytes(
                    b"".join(
                        token.encode() + b"\0" for token in fixture.link_arguments
                    )
                )
                refusal = fixture.write_manifest(expected=2)
                self.assertIn("AppKit framework pair", refusal.stderr)

    def test_systemconfiguration_framework_boundary_is_mandatory(self) -> None:
        paths = (
            "frameworks/SystemConfiguration.framework/Headers/OpenSystemConfiguration.h",
            "frameworks/SystemConfiguration.framework/Headers/SCNetwork.h",
            "frameworks/SystemConfiguration.framework/Headers/SCNetworkReachability.h",
            "frameworks/SystemConfiguration.framework/Headers/SystemConfiguration.h",
            "frameworks/SystemConfiguration.framework/Modules/module.modulemap",
            "frameworks/SystemConfiguration.framework/SystemConfiguration",
            "guest-root/darwin/System/Library/Frameworks/"
            "SystemConfiguration.framework/SystemConfiguration",
        )
        for relative in paths:
            with self.subTest(relative=relative), tempfile.TemporaryDirectory() as temporary:
                fixture = PackageFixture(Path(temporary) / "package", preview=False)
                ledger = fixture.root / "attestation/artifacts.tsv"
                ledger.write_text(
                    "\n".join(
                        line
                        for line in ledger.read_text(encoding="utf-8").splitlines()
                        if relative not in line
                    )
                    + "\n",
                    encoding="utf-8",
                )
                refusal = fixture.write_manifest(expected=2)
                self.assertIn(
                    "SystemConfiguration framework boundary artifacts",
                    refusal.stderr,
                )

        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            pair = ["-framework", "SystemConfiguration"]
            index = next(
                index
                for index in range(len(fixture.link_arguments) - 1)
                if fixture.link_arguments[index : index + 2] == pair
            )
            del fixture.link_arguments[index : index + 2]
            (fixture.root / "link-inputs.rsp").write_bytes(
                b"".join(token.encode() + b"\0" for token in fixture.link_arguments)
            )
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("SystemConfiguration framework pair", refusal.stderr)

    def test_corelocation_identity_boundary_and_link_mutations_are_refused(
        self,
    ) -> None:
        paths = (
            "frameworks/CoreLocation.framework/Headers/CoreLocation.h",
            "frameworks/CoreLocation.framework/Modules/module.modulemap",
            "frameworks/CoreLocation.framework/Modules/"
            f"CoreLocation.swiftmodule/{SWIFT_MODULE_TRIPLE}.swiftmodule",
            "frameworks/CoreLocation.framework/CoreLocation",
            "guest-root/darwin/System/Library/Frameworks/"
            "CoreLocation.framework/CoreLocation",
        )
        for relative in paths:
            with (
                self.subTest(relative=relative),
                tempfile.TemporaryDirectory() as temporary,
            ):
                fixture = PackageFixture(Path(temporary) / "package", preview=False)
                ledger = fixture.root / "attestation/artifacts.tsv"
                ledger.write_text(
                    "\n".join(
                        line
                        for line in ledger.read_text(encoding="utf-8").splitlines()
                        if relative not in line
                    )
                    + "\n",
                    encoding="utf-8",
                )
                refusal = fixture.write_manifest(expected=2)
                self.assertIn(
                    "CoreLocation framework boundary artifacts",
                    refusal.stderr,
                )

        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            runtime = (
                fixture.root
                / "guest-root/darwin/System/Library/Frameworks/"
                "CoreLocation.framework/CoreLocation"
            )
            write_file(runtime, "different CoreLocation runtime")
            fixture._write_ledger()
            refusal = fixture.write_manifest(expected=2)
            self.assertIn(
                "CoreLocation compile/runtime framework identities differ",
                refusal.stderr,
            )

        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            write_file(
                fixture.root / "lib/libCoreLocation.dylib",
                "competing flat CoreLocation",
            )
            fixture._write_ledger()
            ledger = fixture.root / "attestation/artifacts.tsv"
            with ledger.open("a", encoding="utf-8", newline="\n") as handle:
                handle.write(
                    fixture._artifact(
                        "framework",
                        "CoreLocation",
                        "dylib",
                        "lib/libCoreLocation.dylib",
                    )
                    + "\n"
                )
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("not libCoreLocation", refusal.stderr)

        for replacement in ("missing", "flat"):
            with (
                self.subTest(link=replacement),
                tempfile.TemporaryDirectory() as temporary,
            ):
                fixture = PackageFixture(Path(temporary) / "package", preview=False)
                pair = ["-framework", "CoreLocation"]
                index = next(
                    index
                    for index in range(len(fixture.link_arguments) - 1)
                    if fixture.link_arguments[index : index + 2] == pair
                )
                del fixture.link_arguments[index : index + 2]
                if replacement == "flat":
                    fixture.link_arguments.append("-lCoreLocation")
                (fixture.root / "link-inputs.rsp").write_bytes(
                    b"".join(
                        token.encode() + b"\0" for token in fixture.link_arguments
                    )
                )
                refusal = fixture.write_manifest(expected=2)
                self.assertIn("CoreLocation framework pair", refusal.stderr)

    def test_unattested_host_tool_is_refused(self) -> None:
        fixture = self.fixture(False)
        write_file(fixture.root / "host-tools/swift/host/libStale.so", "stale")
        refusal = run_tool("verify", "--package-root", str(fixture.root), expected=2)
        self.assertIn("artifact coverage drifted under host-tools", refusal.stderr)

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

    def test_appkit_source_attestation_is_mandatory(self) -> None:
        fixture = self.fixture(False)
        manifest_path = fixture.root / "attestation/core-package.json"
        document = json.loads(manifest_path.read_text(encoding="utf-8"))
        del document["manifests"]["appkit_sources"]
        manifest_path.write_text(
            json.dumps(document, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        refusal = run_tool("verify", "--package-root", str(fixture.root), expected=2)
        self.assertIn("omits required manifests: appkit_sources", refusal.stderr)

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
            pair_end = fixture.compile_arguments.index("-Iinclude/CoreImage") + 1
            del fixture.compile_arguments[pair_end - 2 : pair_end]
            (fixture.root / "compile-flags.rsp").write_bytes(
                b"".join(token.encode() + b"\0" for token in fixture.compile_arguments)
            )
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("CoreImage underlying-module pair", refusal.stderr)

    def test_cferror_clang_substrate_and_compile_pairs_are_mandatory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            ledger = fixture.root / "attestation/artifacts.tsv"
            ledger.write_text(
                "\n".join(
                    line
                    for line in ledger.read_text(encoding="utf-8").splitlines()
                    if "COpenFoundationCore/module.modulemap" not in line
                )
                + "\n",
                encoding="utf-8",
            )
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("Foundation CFError Clang substrate", refusal.stderr)

        with tempfile.TemporaryDirectory() as temporary:
            fixture = PackageFixture(Path(temporary) / "package", preview=False)
            pair_end = fixture.compile_arguments.index(
                "-Iinclude/COpenFoundationCore"
            ) + 1
            del fixture.compile_arguments[pair_end - 2 : pair_end]
            (fixture.root / "compile-flags.rsp").write_bytes(
                b"".join(token.encode() + b"\0" for token in fixture.compile_arguments)
            )
            refusal = fixture.write_manifest(expected=2)
            self.assertIn("Foundation CFError Clang module pair", refusal.stderr)

    def test_cross_import_overlay_compile_pair_is_mandatory(self) -> None:
        for mutation in ("missing", "duplicate"):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as temporary:
                fixture = PackageFixture(Path(temporary) / "package", preview=False)
                pair_end = fixture.compile_arguments.index(
                    "-enable-cross-import-overlays"
                ) + 1
                if mutation == "missing":
                    del fixture.compile_arguments[pair_end - 2 : pair_end]
                else:
                    fixture.compile_arguments[pair_end:pair_end] = [
                        "-Xfrontend",
                        "-enable-cross-import-overlays",
                    ]
                (fixture.root / "compile-flags.rsp").write_bytes(
                    b"".join(
                        token.encode() + b"\0" for token in fixture.compile_arguments
                    )
                )
                refusal = fixture.write_manifest(expected=2)
                self.assertIn("enable Swift cross-import overlays", refusal.stderr)

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
    def test_published_app_contract_keeps_swift_regex_implicit_import(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        published_contract = source[
            source.index("== write relocatable compile/link contracts") :
            source.index("printf '%s\\0'", source.index("== write relocatable compile/link contracts"))
        ]
        self.assertNotIn(
            "-disable-implicit-string-processing-module-import",
            published_contract,
        )
        self.assertEqual(
            source.count("-disable-implicit-string-processing-module-import"),
            1,
        )

    def test_builder_enables_cross_import_overlays_for_platform_and_consumers(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        self.assertEqual(
            source.count("-Xfrontend -enable-cross-import-overlays"), 3
        )
        cross_import_gate = source[
            source.index("typecheck an ordinary QuickLook/SwiftUI cross-import consumer") :
            source.index("compile/link/run the standalone CoreMedia rational-time gate")
        ]
        self.assertIn('"${SWIFTC[@]}"', cross_import_gate)
        natural_language_gate = source[
            source.index("typecheck untouched-consumer-shaped NaturalLanguage clients") :
            source.index("compile/link/run the standalone AuthenticationServices browser gate")
        ]
        self.assertIn('"${APP_CONSUMER_SWIFTC[@]}"', natural_language_gate)

    def test_app_consumer_compiler_roots_versioned_framework_modules(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        definition_start = source.index("APP_CONSUMER_SWIFTC=(")
        definition = source[
            definition_start : source.index("\nLD=(", definition_start)
        ]
        self.assertEqual(definition.count('-F "$STAGE/frameworks"'), 1)
        widget_consumer_gate = source[
            source.index("typecheck the exact-surface IceCubes WidgetKit consumer") :
            source.index("compile/link/run the standalone CoreTransferable data and file gate")
        ]
        self.assertEqual(widget_consumer_gate.count('"${APP_CONSUMER_SWIFTC[@]}"'), 2)

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
            'let referenceURL = valueURL as NSURL',
            'let cache = NSCache<NSURL, CoreFoundationRuntimeLookupProbe>()',
            'cache.object(forKey: valueURL as NSURL) === cachedObject',
        ):
            self.assertIn(token, compatibility_probe)
        self.assertIn("FoundationHackersCompatibilityProbe.swift", builder)
        self.assertIn("runFoundationHackersCompatibilityProbe(", core_probe)
        marker = (
            "foundation=locks,filehandle,characters,strings,ranges,attributed,objc,number-bridge,data-search,cfurl,url-bridge,cache,reexports,byte-count"
        )
        self.assertIn(marker, builder)
        self.assertIn("foundation=\\(foundationCompatibility)", core_probe)
        self.assertIn("ByteCountFormatter()", core_probe)
        self.assertIn('"1 MB (1,048,576 bytes)"', core_probe)

    def test_builder_pins_the_canonical_105_source_openuikit_tree(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        self.assertEqual(source.count("EXPECTED_FOUNDATION_SOURCE_COUNT=34"), 1)
        self.assertIn(
            "-lOpenCoreGraphics -lCombine -lOpenCombine -lDispatch",
            source,
        )
        self.assertEqual(source.count("EXPECTED_UIKIT_SWIFT_COUNT=105"), 1)
        self.assertNotIn("EXPECTED_UIKIT_SWIFT_COUNT=102", source)
        self.assertEqual(source.count("EXPECTED_SYMBOLS_SWIFT_COUNT=1"), 1)
        self.assertEqual(source.count("EXPECTED_SWIFTUI_SWIFT_COUNT=11"), 1)
        self.assertNotIn("EXPECTED_SWIFTUI_SWIFT_COUNT=9", source)

    def test_localized_string_resources_are_oracled_and_cold_run(self) -> None:
        source = (
            REPO / "full/foundation/LocalizedStringResource.swift"
        ).read_text(encoding="utf-8")
        oracle = (
            REPO
            / "full/foundation/tests/FoundationLocalizedStringResourceOracle.swift"
        ).read_text(encoding="utf-8")
        host_gate = (
            REPO / "full/foundation/tests/test_foundation_guest_text_host.sh"
        ).read_text(encoding="utf-8")
        documentation = (
            REPO / "full/foundation/FOUNDATION_LOCALIZED_STRING_RESOURCE.md"
        ).read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(
            encoding="utf-8"
        )
        builder = BUILDER.read_text(encoding="utf-8")
        for token in (
            "public struct LocalizedStringResource",
            "struct LocalizationValue",
            "enum Placeholder",
            "replacementArguments: options.replacements",
            "BundleDescription",
            "public func encode(to encoder: any Encoder)",
        ):
            self.assertIn(token, source)
        for token in (
            '"Items \\(localizedCount)"',
            '"Ratio \\(1.5)"',
            '"Placeholder \\(placeholder: .int)"',
            "JSONEncoder().encode(",
            "JSONDecoder().decode(",
        ):
            self.assertIn(token, probe)
        self.assertIn("FOUNDATION_LOCALIZED_STRING_RESOURCE_OK", oracle)
        self.assertIn("apple-localized-resource", host_gate)
        self.assertIn("port-localized-resource", host_gate)
        marker = "localization=literal,interpolation,placeholders,codable"
        self.assertIn(marker, probe)
        self.assertIn(marker, builder)
        self.assertIn(marker, documentation)
        self.assertIn("Deliberate remaining boundaries", documentation)

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
            'PLATFORM_HOST_PRELOAD=$DISPATCH_HOST:$FOUNDATION_INTL_HOST:$URL_TRANSPORT_HOST',
        ):
            self.assertIn(token, builder)
        self.assertIn("host/libOpenURLTransportHost.so", driver)
        self.assertIn(
            'LD_PRELOAD="$dispatch_host:$foundation_intl_host:$url_transport_host',
            driver,
        )
        for token in (
            "CURLOPT_SSL_VERIFYPEER, 1L",
            "CURLOPT_SSL_VERIFYHOST, 2L",
            "CURLOPT_FOLLOWLOCATION, 0L",
            "OPENUI_URL_TRANSPORT_MAX_RESPONSE_HEADER_BYTES",
            "OPENUI_URL_TRANSPORT_MAX_RESPONSE_BODY_BYTES",
        ):
            self.assertIn(token, host)
        self.assertNotIn("CURLOPT_FOLLOWLOCATION, 1L", host)

    def test_relative_time_bridge_uses_real_pinned_icu(self) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        driver = APP_DRIVER.read_text(encoding="utf-8")
        host = (REPO / "full/relativetime/OpenRelativeTimeHost.c").read_text(
            encoding="utf-8"
        )
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        for token in (
            "libOpenRelativeTime.dylib",
            "libOpenRelativeTimeHost.so",
            "relative-time-abi.tsv",
            "relative-time-host.tsv",
            "pkg-config --modversion icu-i18n",
            "relative-time-expected-mach-imports.txt",
            "OPEN_RELATIVE_TIME_HOST_OK",
            "$RELATIVE_TIME_HOST",
        ):
            self.assertIn(token, builder)
        self.assertIn("host/libOpenRelativeTimeHost.so", driver)
        self.assertIn("$relative_time_host", driver)
        for token in (
            "ureldatefmt_open(",
            "ureldatefmt_formatNumeric(",
            "ureldatefmt_format(",
            "UNUM_SPELLOUT",
            "OPENUI_RELATIVE_TIME_MAX_OUTPUT_BYTES",
        ):
            self.assertIn(token, host)
        self.assertIn("data-platform=\\(dataPlatform)", probe)

    def test_full_foundation_internationalization_is_pinned_and_reexported(self) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        wrapper = HOST_WRAPPER.read_text(encoding="utf-8")
        driver = APP_DRIVER.read_text(encoding="utf-8")
        foundation = (REPO / "full/appshim/FoundationGuest.swift").read_text(
            encoding="utf-8"
        )
        intl_builder = (
            REPO
            / "full/foundationinternationalization/build_foundation_internationalization.sh"
        ).read_text(encoding="utf-8")
        threading = (
            REPO / "full/foundationinternationalization/FoundationICUCXXThreading.cpp"
        ).read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        for token in (
            "87dbab99780e277b6a4c2a397ab1a894f877b39a",
            "823a4a2a13f60a0fd2715db85a754dda11d5fd39",
            "EXPECTED_FOUNDATION_INTL_SWIFT_COUNT=61",
            "EXPECTED_FOUNDATION_ICU_CPP_COUNT=474",
            "EXPECTED_FOUNDATION_ICU_HEADER_COUNT=205",
            "stubdata=excluded",
            "lib_FoundationICU.dylib",
            "libFoundationInternationalization.dylib",
            "libOpenFoundationInternationalization.dylib",
            "libOpenFoundationInternationalizationHost.so",
            "-DUSE_PACKAGE_DATA=1",
            "-DAPPLE_ICU_CHANGES=1",
            "FoundationInternationalization Swift count",
            "Foundation ICU object count",
        ):
            self.assertIn(token, intl_builder)
        self.assertIn("@_exported import FoundationInternationalization", foundation)
        self.assertIn("-reexport_library", builder)
        self.assertIn(
            "include/FoundationICU/_foundation_unicode/module.modulemap", builder
        )
        self.assertNotIn('-Xcc -I"$STAGE/include")', builder)
        self.assertIn("foundation_internationalization_load_count", builder)
        self.assertIn("foundation_internationalization_reexport_count", builder)
        self.assertIn('command == "LC_LOAD_DYLIB"', builder)
        self.assertIn('command == "LC_REEXPORT_DYLIB"', builder)
        self.assertIn("swift-foundation-icu", wrapper)
        self.assertIn("foundation_intl_host", driver)
        self.assertIn(
            "PLATFORM_HOST_PRELOAD=$DISPATCH_HOST:$FOUNDATION_INTL_HOST:"
            "$URL_TRANSPORT_HOST:$RELATIVE_TIME_HOST:$COMPRESSION_HOST:$ZLIB_HOST",
            builder,
        )
        self.assertIn(
            "EARLY_PLATFORM_HOST_PRELOAD=$DISPATCH_HOST:$URL_TRANSPORT_HOST:"
            "$RELATIVE_TIME_HOST:$COMPRESSION_HOST:$ZLIB_HOST",
            builder,
        )
        self.assertEqual(
            builder.count('LD_PRELOAD="$EARLY_PLATFORM_HOST_PRELOAD'), 7
        )
        self.assertEqual(
            builder.count('LD_PRELOAD="$PLATFORM_HOST_PRELOAD'), 37
        )
        self.assertIn("__libcpp_mutex_lock", threading)
        self.assertIn("__libcpp_condvar_wait", threading)
        self.assertIn("__call_once", threading)
        for token in (
            'Locale(identifier: "en_US_POSIX")',
            'Locale(identifier: "fr_FR")',
            '"12 345,67"',
            '"dans 1 jour"',
            '"https://xn--bcher-kva.example/"',
            "internationalization=icu-fr,number,idna",
        ):
            self.assertIn(token, probe)

    def test_data_platform_models_and_filesystem_are_semantic(self) -> None:
        filesystem = (
            REPO / "full/foundation/FileManager+Enumeration.swift"
        ).read_text(encoding="utf-8")
        resource_key_patch = (
            REPO
            / "full/foundation/patches/FoundationEssentials-URLResourceKey.patch"
        ).read_text(encoding="utf-8")
        foundation_builder = (
            REPO / "full/foundation/build_fe.sh"
        ).read_text(encoding="utf-8")
        storekit = (REPO / "full/storekit/StoreKit.swift").read_text(
            encoding="utf-8"
        )
        oracle = FOUNDATION_DATA_PLATFORM_ORACLE.read_text(encoding="utf-8")
        self.assertEqual(
            sha256(FOUNDATION_DATA_PLATFORM_GOLDEN),
            "cc72856c77fabe0bdfdd2b0dec076f1857cffa4bdbd5e67932dc6d3d124ae400",
        )
        for token in (
            "final class DirectoryEnumerator: Sequence, IteratorProtocol",
            "Darwin.lstat(",
            ".skipsHiddenFiles",
            ".skipsPackageDescendants",
            "func resourceValues(",
            "totalFileAllocatedSize",
            "public extension URLResourceKey",
        ):
            self.assertIn(token, filesystem)
        for token in (
            "public struct URLResourceKey: RawRepresentable, Hashable, Sendable",
            "public let rawValue: String",
        ):
            self.assertIn(token, resource_key_patch)
        for token in (
            'PATCHED_SOURCE_DIR=$W/build/foundationessentials-port-sources',
            'PATCHED_URL_RESOURCE_SOURCE=$PATCHED_SOURCE_DIR/URL-resource-key.swift',
            'patch --batch --forward --fuzz=0 -s -o "$PATCHED_URL_RESOURCE_SOURCE"',
            'SRCS[$source_index]=$PATCHED_URL_SOURCE',
            'patched_url_count" -eq 1',
        ):
            self.assertIn(token, foundation_builder)
        self.assertIn(
            "FoundationEssentials.URLResourceKey",
            (REPO / "full/frameworks/CoreGuestPackageProbe.swift").read_text(
                encoding="utf-8"
            ),
        )
        for token in (
            "public enum StoreKitError: Error, Sendable",
            "case userCancelled",
            "public let displayPrice: String",
            "public let expirationDate: Date?",
            "public let revocationDate: Date?",
        ):
            self.assertIn(token, storekit)
        for token in (
            "OSAllocatedUnfairLock<[Int]>",
            "NSUbiquitousKeyValueStore.default",
            "RelativeDateTimeFormatter()",
            "FileManager.default",
            ".resourceValues(forKeys: fileKeys)",
        ):
            self.assertIn(token, oracle)

    def test_dispatch_is_a_portable_module_and_real_host_scheduler(self) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        driver = APP_DRIVER.read_text(encoding="utf-8")
        cache_gate = builder[
            builder.index(
                "== compile/link/run the Apple-differential NSURL and NSCache cold gate"
            ) : builder.index(
                "== compile/link/run the Apple-differential ByteCountFormatter cold gate"
            )
        ]
        self.assertIn(
            'LD_PRELOAD="$PLATFORM_HOST_PRELOAD',
            cache_gate,
        )
        byte_count_gate = builder[
            builder.index(
                "== compile/link/run the Apple-differential ByteCountFormatter cold gate"
            ) : builder.index("== write relocatable compile/link contracts")
        ]
        self.assertIn(
            'LD_PRELOAD="$PLATFORM_HOST_PRELOAD',
            byte_count_gate,
        )
        for token in (
            "-module-name Dispatch -module-link-name Dispatch",
            "libDispatch.dylib",
            "libOpenDispatch.dylib",
            "libOpenDispatchHost.so",
            "host/libdispatch.so",
            "host/libBlocksRuntime.so",
            "EXPECTED_HOST_DISPATCH_SHA256",
            "GLIBC_2.38",
            "OPEN_DISPATCH_MACHO_OK async-main=drained",
            "private=serial,specific semaphore=signal,timeout",
            "scheduler=immediate,delayed,cancelled,receive-on",
            "FOUNDATION_URLSESSION_MACHO_OK",
            "FOUNDATION_CACHE_MACHO_OK rows=43 apple-differential=exact",
            "FOUNDATION_BYTE_COUNT_MACHO_OK rows=91 apple-differential=exact",
            "attestation/dispatch-runtime.log",
            "attestation/foundation-urlsession-runtime.log",
            "FoundationCacheOracle.swift",
            "foundation-cache-apple-2026-08-31.txt",
            "probe/FoundationCacheRuntime",
            "attestation/foundation-cache-runtime.log",
            "attestation/foundation-cache-apple.txt",
            "FoundationByteCountFormatterOracle.swift",
            "foundation-byte-count-apple-2026-08-31.txt",
            "probe/FoundationByteCountFormatterRuntime",
            "attestation/foundation-byte-count-runtime.log",
            "attestation/foundation-byte-count-apple.txt",
        ):
            self.assertIn(token, builder)
        for token in (
            "host/libOpenDispatchHost.so",
            "host/libdispatch.so",
            "host/libBlocksRuntime.so",
            'LD_LIBRARY_PATH="$guest_root/host',
            'LD_PRELOAD="$dispatch_host:$foundation_intl_host:$url_transport_host',
        ):
            self.assertIn(token, driver)

    def test_swiftui_app_lifecycle_is_a_real_core_product(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        self.assertIn("EXPECTED_SWIFTUI_SWIFT_COUNT=11", source)
        self.assertIn("@UIApplicationDelegateAdaptor", probe)
        self.assertIn("WindowGroup", probe)
        self.assertIn("CoreLifecycleApplication.main", probe)
        self.assertIn("swiftui-app=constructed", probe)

    def test_symbols_is_a_real_module_dylib_and_swiftui_dependency(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        validate_symbols_platform_contract(source)
        self.assertIn("import Symbols", probe)
        self.assertIn("PulseSymbolEffect.pulse != .pulse.byLayer", probe)
        self.assertIn("coreRequireIndefiniteSymbolEffect", probe)
        self.assertIn("coreRequireDiscreteSymbolEffect", probe)
        self.assertIn("SwiftUI.SymbolEffect.pulse", probe)
        for token in (
            "-module-name Symbols -module-link-name Symbols",
            "-install_name @rpath/libSymbols.dylib",
            "libSwiftUI Symbols load count",
            "symbols=values,markers,swiftui-render",
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "Symbols platform"):
                    validate_symbols_platform_contract(
                        source.replace(token, "", 1)
                    )

    def test_builder_requires_exact_uikit_pin_and_fresh_output(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        for token in (
            "--expected-support-commit",
            "--expected-support-tree",
            "--uikit-checkout",
            "--expected-uikit-commit",
            "--expected-uikit-tree",
            "assert_vendor_tree \"$W\" uikit",
            "HEAD:uikit",
            "EXPECTED_UIKIT_TREE=$EXPECTED_INREPO_UIKIT_TREE",
            "output root already exists",
            ".INVALID-DO-NOT-USE",
        ):
            self.assertIn(token, source)
        self.assertNotIn("EXPECTED_UIKIT_COMMIT=83fbcbe", source)

    def test_preview_executable_stays_external_while_library_is_packaged(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        probe = (HERE / "SwiftUICompilerPluginsProbe.swift").read_text(
            encoding="utf-8"
        )
        self.assertIn("'${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros'", source)
        self.assertIn("libOpenUIKitPreviewMacros.so", source)
        self.assertIn("libOpenSwiftUIMacros.so", source)
        self.assertIn("SwiftUICompilerPluginsProbe.swift", source)
        self.assertIn("SWIFTUI_COMPILER_PLUGINS_OK", source)
        self.assertIn("BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE=''", source)
        self.assertIn("BUILD_FULL_PREVIEW_MACRO_PLUGIN=''", source)
        self.assertIn(
            "BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE=disabled", source
        )
        self.assertIn(
            "BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_DISABLED_OWNER="
            "core-package-post-foundation",
            source,
        )
        self.assertIn("Foundation-hidden build_full output", source)
        self.assertIn("@Entry var portableCompilerPluginProbe", probe)
        self.assertEqual(probe.count("#Preview"), 2)
        self.assertIn("probe_dts_count", source)
        self.assertIn(
            "PREVIEW_EXECUTABLE_RESOLUTION_FLAGS=(-undefined dynamic_lookup)",
            source,
        )
        self.assertNotIn("LINK_ARGUMENTS+=(objects/developertoolsupport.o)", source)
        validate_preview_standalone_link_contract(source)

    def test_every_standalone_swiftui_executable_owns_preview_metadata(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        validate_preview_standalone_link_contract(source)
        for token in (
            'PREVIEW_STANDALONE_LINK_INPUTS+=("$STAGE/objects/developertoolsupport.o")',
            "PREVIEW_STANDALONE_NOMINAL_LINK_FLAGS+=(-lOpenUIKit)",
            "swiftdata_preview_export_count=$(nm_symbol_count --defined-only",
            "quicklook_preview_export_count=$(nm_symbol_count --defined-only",
            "widgetkit_preview_export_count=$(nm_symbol_count --defined-only",
            "photos_preview_export_count=$(nm_symbol_count --defined-only",
            "photosui_preview_export_count=$(nm_symbol_count --defined-only",
            "swiftui_reexport_preview_export_count=$(nm_symbol_count --defined-only",
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "standalone SwiftUI Preview"):
                    validate_preview_standalone_link_contract(
                        source.replace(token, "", 1)
                    )

    def test_webkit_is_an_independent_fail_closed_framework_dylib(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        self.assertEqual(len(FRAMEWORKS), 57)
        self.assertEqual(FRAMEWORKS.index("WebKit"), 18)
        for token in (
            "-module-name WebKit -emit-module",
            "-install_name @rpath/libWebKit.dylib",
            '-needed_library "$STAGE/lib/libUIKit.dylib"',
            '-needed_library "$STAGE/lib/libFoundation.dylib"',
            '"$SWIFTUI_RUNTIME_LINK_FLAG"',
            '"$SWIFTUI_RUNTIME_INSTALL_NAME"',
            "/System/Library/Frameworks/WebKit.framework/",
            "webkit-dylib-loads.tsv",
            "strict Swift 6 Hackers WebKit/KVO source-surface gate",
            "full/webkit/tests/HackersWebKitSurface.swift",
            "EXPECTED_HACKERS_WEBKIT_SURFACE_SHA256=fa5ac0e8",
            "Hackers-WebKit-Swift-6-surface",
            "rendering-engine\\tabsent",
            "-lWebKit -lCoreImage",
            "Intents IntentsUI WebKit",
        ):
            self.assertIn(token, source)
        self.assertIn("import WebKit", probe)
        self.assertIn("WKError", probe)
        self.assertIn("webDelegate.commits == 0", probe)
        self.assertIn("webView.observe(", probe)
        self.assertIn("loadingChanges.count == 5", probe)
        self.assertIn("setAllMediaPlaybackSuspended(true)", probe)
        self.assertIn("webkit=state,kvo,engine-unavailable", probe)

    def test_hackers_webkit_swift6_surface_is_digest_pinned(self) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        surface = REPO / "full/webkit/tests/HackersWebKitSurface.swift"
        digest = sha256(surface)
        self.assertEqual(
            digest,
            "fa5ac0e8d8a72453d604cc5a8f24a8a8e9a771249115f569b2cd5b31422f194c",
        )
        self.assertIn(
            f"EXPECTED_HACKERS_WEBKIT_SURFACE_SHA256={digest}", builder
        )
        self.assertIn(
            'require_hash "$HACKERS_WEBKIT_SURFACE"', builder
        )
        self.assertNotEqual(
            hashlib.sha256(surface.read_bytes() + b"\n// mutation\n").hexdigest(),
            digest,
        )

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
        self.assertLess(
            source.index("app-only Foundation identity shim"),
            source.index("DeveloperToolsSupport (canonical target module)"),
        )
        self.assertLess(
            source.index("DeveloperToolsSupport (canonical target module)"),
            source.index("literal UIKit shim"),
        )
        literal_uikit = source[source.index("literal UIKit shim"):]
        literal_uikit = literal_uikit[:literal_uikit.index("literal UIKit IndexPath")]
        self.assertNotIn('-I "$APPINC"', literal_uikit)

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
        builder = BUILDER.read_text(encoding="utf-8")
        build_full = BUILD_FULL.read_text(encoding="utf-8")
        validate_core_single_bind_contract(source)
        validate_swift_core_runtime_contract(builder, source)
        validate_build_full_swift_core_source(build_full)
        self.assertIn(
            "EXPECTED_MACHORUN_TREE=$EXPECTED_INREPO_MACHORUN_TREE",
            builder,
        )
        self.assertNotIn("EXPECTED_MACHORUN_COMMIT=", builder)
        for obsolete_machorun_pin in (
            "d359cd37ac7f12a5048f4993eab6efd8259d9890",
            "e6b1745bef09ac8f1e2d6e6c83f7c70d6dbe49a5",
            "edb99a8574255ddc4c979b2f0cf2615033ff14fd",
            "dd18e0b5e51e26d4673193d341e7c9a864db2fb8",
            "74f46d3b02b372e14f9ca9cee3d8a76ccc96fccb",
            "1f4021b69495c1a743e85f51cb60d2f337b0bc75",
        ):
            self.assertNotIn(
                "EXPECTED_MACHORUN_COMMIT=" + obsolete_machorun_pin,
                builder,
            )
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
            'GUEST_ROOT=$PACKAGE/guest-root',
            "durable guest-root product is missing after Docker",
            "libquartz.dylib",
            "remove-tree",
            "assert_vendor_tree",
            "HEAD:$vendor_name",
            'UIKIT_CHECKOUT=$SUPPORT_CHECKOUT/uikit',
            'MACHORUN_CHECKOUT=$SUPPORT_CHECKOUT/machorun',
            "source=HEAD:",
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
        self.assertIn("expected-machorun-swift-core-sha256", source)
        self.assertIn("COPIED_MACHORUN_SWIFT_CORE_SHA256", source)
        self.assertIn("expected-machorun-objc-sha256", source)
        self.assertIn("COPIED_MACHORUN_OBJC_SHA256", source)
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

    def test_swift_core_runtime_contract_refuses_mutation(self) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        wrapper = HOST_WRAPPER.read_text(encoding="utf-8")
        validate_swift_core_runtime_contract(builder, wrapper)
        mutations = (
            (
                builder.replace(
                    '[ "$swift_core_runtime_symbol_count" -eq 1 ]',
                    '[ "$swift_core_runtime_symbol_count" -ge 0 ]',
                    1,
                ),
                wrapper,
            ),
            (
                builder.replace(
                    "swift_core_runtime_symbol_count=$(nm_symbol_count --defined-only",
                    "swift_core_runtime_symbol_count=$(nm_symbol_count --undefined-only",
                    1,
                ),
                wrapper,
            ),
            (
                builder,
                wrapper.replace(
                    "COPIED_MACHORUN_SWIFT_CORE_SHA256=",
                    "UNATTESTED_MACHORUN_SWIFT_CORE_SHA256=",
                    1,
                ),
            ),
            (
                builder,
                wrapper.replace(
                    "COPIED_MACHORUN_OBJC_SHA256=",
                    "UNATTESTED_MACHORUN_OBJC_SHA256=",
                    1,
                ),
            ),
        )
        for mutated_builder, mutated_wrapper in mutations:
            with self.subTest():
                with self.assertRaisesRegex(AssertionError, "Swift core"):
                    validate_swift_core_runtime_contract(
                        mutated_builder, mutated_wrapper
                    )
        self.assertIn('BUILD_FE_CACHE=$W/scratch/modcache_fe4${FULL_OUT_SUFFIX}', BUILDER.read_text(encoding="utf-8"))
        self.assertIn('SYS=$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}', BUILDER.read_text(encoding="utf-8"))
        self.assertIn('"$BUILD_FE_CACHE"', BUILDER.read_text(encoding="utf-8"))
        self.assertIn("sdk_dangling_symlink_exclusions.tsv", BUILDER.read_text(encoding="utf-8"))
        self.assertIn("sdk-dangling-symlinks.tsv", BUILDER.read_text(encoding="utf-8"))

    def test_swift_core_stager_overrides_a_precisely_mixed_base_root(self) -> None:
        source = BUILD_FULL.read_text(encoding="utf-8")
        validate_build_full_swift_core_source(source)
        mutations = (
            source.replace(
                '[ "$(basename "$d")" = libswiftCore.dylib ] && continue',
                "",
                1,
            ),
            source.replace(
                '--base "$BASE_RUNTIME_SOURCE/darwin/usr/lib/swift/libswiftCore.dylib"',
                "--base /unattested/libswiftCore.dylib",
                1,
            ),
        )
        for mutation in mutations:
            with self.subTest():
                with self.assertRaisesRegex(AssertionError, "build_full Swift core"):
                    validate_build_full_swift_core_source(mutation)

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            canonical = root / "canonical/libswiftCore.dylib"
            stale_base = root / "staged-mrroot/libswiftCore.dylib"
            destination = root / "mrroot-full/libswiftCore.dylib"
            report = root / "swift-core-runtime-stage.json"
            write_file(canonical, b"canonical-dd016-runtime")
            write_file(stale_base, b"stale-583c-runtime")
            write_file(destination, b"preexisting-stale-runtime")
            expected = sha256(canonical)
            result = subprocess.run(
                [
                    "python3",
                    "-B",
                    str(SWIFT_CORE_STAGER),
                    "--canonical",
                    str(canonical),
                    "--base",
                    str(stale_base),
                    "--destination",
                    str(destination),
                    "--expected-sha256",
                    expected,
                    "--report",
                    str(report),
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(destination.read_bytes(), canonical.read_bytes())
            payload = json.loads(report.read_text(encoding="utf-8"))
            self.assertEqual(payload["format"], "swift-core-runtime-stage-v1")
            self.assertFalse(payload["base_matches_canonical"])
            self.assertEqual(payload["base_sha256"], sha256(stale_base))
            self.assertEqual(payload["canonical_sha256"], expected)
            self.assertEqual(payload["staged_sha256"], expected)

            refused_destination = root / "refused/libswiftCore.dylib"
            write_file(refused_destination, b"must-remain-untouched")
            refused = subprocess.run(
                [
                    "python3",
                    "-B",
                    str(SWIFT_CORE_STAGER),
                    "--canonical",
                    str(canonical),
                    "--base",
                    str(stale_base),
                    "--destination",
                    str(refused_destination),
                    "--expected-sha256",
                    "0" * 64,
                    "--report",
                    str(root / "refused.json"),
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(refused.returncode, 2)
            self.assertIn("canonical Swift core hash", refused.stderr)
            self.assertEqual(
                refused_destination.read_bytes(), b"must-remain-untouched"
            )

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
        default_mc = 'MC=${MC:-$W/scratch/modcache_fe4}'
        variable_argv = '-module-cache-path "$MC"'
        literal_argv = '-module-cache-path "$W/scratch/modcache_fe4"'
        for helper in (
            REPO / "full/foundation/build_collections.sh",
            REPO / "full/foundation/build_os_module.sh",
            REPO / "full/foundation/build_fe.sh",
        ):
            text = helper.read_text(encoding="utf-8")
            uses_literal = literal_argv in text
            uses_variable = default_mc in text and variable_argv in text
            self.assertTrue(
                uses_literal or uses_variable,
                f"{helper.name} must write the FE module cache at "
                f"$W/scratch/modcache_fe4 (literal argv or MC default + "
                f'-module-cache-path "$MC")',
            )
            if uses_variable:
                self.assertIn(default_mc, text)
                self.assertIn(variable_argv, text)
        builder = BUILDER.read_text(encoding="utf-8")
        self.assertIn(
            'BUILD_FE_CACHE=$W/scratch/modcache_fe4${FULL_OUT_SUFFIX}',
            builder,
        )
        for cache in ("BUILD_FULL_CACHE", "BUILD_FE_CACHE"):
            self.assertIn(f'"${cache}"', builder)
            self.assertIn(f'touch "${cache}/.INVALID-DO-NOT-USE"', builder)

    def test_foundation_removefile_is_real_tested_and_exported(self) -> None:
        implementation_path = REPO / "full/foundation/removefile_compat.c"
        tests_path = REPO / "full/foundation/removefile_compat_tests.c"
        header_path = REPO / "full/foundation/removefile_compat.h"
        implementation = implementation_path.read_text(encoding="utf-8")
        tests = tests_path.read_text(encoding="utf-8")
        header = header_path.read_text(encoding="utf-8")
        stubs = (REPO / "full/foundation/fm_unimplemented.c").read_text(
            encoding="utf-8"
        )
        builder = BUILDER.read_text(encoding="utf-8")
        build_full = BUILD_FULL.read_text(encoding="utf-8")
        focus = (
            REPO / "full/swiftui/build_focus_onboarding_guest.sh"
        ).read_text(encoding="utf-8")

        for symbol in (
            "removefile",
            "removefileat",
            "removefile_cancel",
            "removefile_state_alloc",
            "removefile_state_free",
            "removefile_state_get",
            "removefile_state_set",
        ):
            self.assertIn(f"{symbol}(", implementation)
            self.assertIn(f"_{symbol}", builder)
        for removed_stub in (
            "MR_STUB(removefile)",
            "MR_STUB(removefile_state_alloc)",
            "MR_STUB(removefile_state_free)",
            "MR_STUB(removefile_state_get)",
            "MR_STUB(removefile_state_set)",
        ):
            self.assertNotIn(removed_stub, stubs)
        for semantic in (
            "lstat(path, &attributes)",
            "opendir(path)",
            "readdir(directory)",
            "unlink(path)",
            "rmdir(path)",
            "REMOVEFILE_KEEP_PARENT",
            "REMOVEFILE_CROSS_MOUNT",
            "ECANCELED",
            "ENOTSUP",
        ):
            self.assertIn(semantic, implementation)
        for state_key in (
            "REMOVEFILE_STATE_CONFIRM_CALLBACK",
            "REMOVEFILE_STATE_ERROR_CALLBACK",
            "REMOVEFILE_STATE_STATUS_CALLBACK",
            "REMOVEFILE_STATE_ERRNO",
            "REMOVEFILE_STATE_FTSENT",
        ):
            self.assertIn(state_key, header)
        marker = (
            "OPEN_FOUNDATION_REMOVEFILE_OK recursive=depth-first "
            "symlink=no-follow keep-parent=yes callbacks=confirm,error,status "
            "cancellation=honored secure=refused"
        )
        self.assertIn("OPEN_FOUNDATION_REMOVEFILE_OK", tests)
        self.assertIn(marker, build_full)
        self.assertIn('"$FE_OUT/removefile_compat.o"', build_full)
        self.assertIn('"$FULL/foundation/essentials/removefile_compat.o"', builder)
        self.assertIn('"$FE_OUT/removefile_compat.o"', focus)
        self.assertIn("removefile-compat-tests.log", builder)
        self.assertIn("FoundationEssentials-removefile", builder)

        with tempfile.TemporaryDirectory() as temporary:
            executable = Path(temporary) / "removefile-compat-tests"
            compile_result = subprocess.run(
                [
                    os.environ.get("CC", "cc"),
                    "-std=c11",
                    "-O2",
                    "-Wall",
                    "-Wextra",
                    "-Werror",
                    "-I",
                    str(header_path.parent),
                    str(implementation_path),
                    str(tests_path),
                    "-o",
                    str(executable),
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(compile_result.returncode, 0, compile_result.stderr)
            result = subprocess.run(
                [str(executable)],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), marker)

    def test_foundation_uses_proven_libsystem_group_xattr_fts_statfs_and_copyfile_adapters(self) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        stubs = (REPO / "full/foundation/fm_unimplemented.c").read_text(
            encoding="utf-8"
        )
        for removed_stub in (
            "MR_STUB(getgrgid_r)",
            "MR_STUB(getgrnam_r)",
            "MR_STUB(fgetxattr)",
            "MR_STUB(fsetxattr)",
            "MR_STUB(getxattr)",
            "MR_STUB(listxattr)",
            "MR_STUB(setxattr)",
            "MR_STUB(fts_close)",
            "MR_STUB(fts_open)",
            "MR_STUB(fts_read)",
            "MR_STUB(fts_set)",
            "MR_STUB(statfs)",
            "MR_STUB(fstatfs)",
            "MR_STUB(copyfile)",
            "MR_STUB(fcopyfile)",
            "MR_STUB(statfs)",
            "MR_STUB(quotactl)",
            "MR_STUB(uname)",
        ):
            self.assertNotIn(removed_stub, stubs)
        for token in (
            "EXPECTED_MACHORUN_LIBSYSTEM_SOURCE_SHA="
            "0d8680f13e023c9f002fad78f1f0382c975f479595cd8cf3fa8eb6da3c42d29b",
            "EXPECTED_MACHORUN_GROUP_FIXTURE_SHA=",
            "EXPECTED_MACHORUN_GROUP_GOLDEN_SHA=",
            "EXPECTED_MACHORUN_GROUP_SOURCE_SHA=",
            "EXPECTED_MACHORUN_XATTR_FIXTURE_SHA=",
            "EXPECTED_MACHORUN_XATTR_GOLDEN_SHA=",
            "EXPECTED_MACHORUN_XATTR_SOURCE_SHA=",
            "EXPECTED_MACHORUN_FTS_FIXTURE_SHA=",
            "EXPECTED_MACHORUN_FTS_GOLDEN_SHA=",
            "EXPECTED_MACHORUN_FTS_STDERR_SHA=",
            "EXPECTED_MACHORUN_FTS_EXIT_SHA=",
            "EXPECTED_MACHORUN_FTS_SOURCE_SHA=",
            "EXPECTED_MACHORUN_FTS_SUMMARY_SHA=",
            "EXPECTED_MACHORUN_FTS_LIBSYSTEM_SOURCE_SHA=",
            "EXPECTED_MACHORUN_STATFS_FIXTURE_SHA=",
            "EXPECTED_MACHORUN_STATFS_GOLDEN_SHA=",
            "EXPECTED_MACHORUN_STATFS_STDERR_SHA=",
            "EXPECTED_MACHORUN_STATFS_EXIT_SHA=",
            "EXPECTED_MACHORUN_STATFS_SOURCE_SHA=",
            "EXPECTED_MACHORUN_STATFS_SUMMARY_SHA=",
            "EXPECTED_MACHORUN_STATFS_LIBSYSTEM_SOURCE_SHA=",
            "EXPECTED_MACHORUN_COPYFILE_FIXTURE_SHA=",
            "EXPECTED_MACHORUN_COPYFILE_GOLDEN_SHA=",
            "EXPECTED_MACHORUN_COPYFILE_STDERR_SHA=",
            "EXPECTED_MACHORUN_COPYFILE_EXIT_SHA=",
            "EXPECTED_MACHORUN_COPYFILE_SOURCE_SHA=",
            "EXPECTED_MACHORUN_COPYFILE_SUMMARY_SHA=",
            "EXPECTED_MACHORUN_COPYFILE_XATTR_GATE_SHA=",
            "EXPECTED_MACHORUN_COPYFILE_LIBSYSTEM_SOURCE_SHA=",
            "EXPECTED_MACHORUN_STATFS_FIXTURE_SHA=",
            "EXPECTED_MACHORUN_STATFS_GOLDEN_SHA=",
            "EXPECTED_MACHORUN_STATFS_STDERR_SHA=",
            "EXPECTED_MACHORUN_STATFS_EXIT_SHA=",
            "EXPECTED_MACHORUN_STATFS_SOURCE_SHA=",
            "EXPECTED_MACHORUN_STATFS_SUMMARY_SHA=",
            "EXPECTED_MACHORUN_STATFS_LIBSYSTEM_SOURCE_SHA=",
            "EXPECTED_MACHORUN_QUOTA_FIXTURE_SHA=",
            "EXPECTED_MACHORUN_QUOTA_GOLDEN_SHA=",
            "EXPECTED_MACHORUN_QUOTA_SOURCE_SHA=",
            "EXPECTED_MACHORUN_UNAME_FIXTURE_SHA=",
            "EXPECTED_MACHORUN_UNAME_GOLDEN_SHA=",
            "EXPECTED_MACHORUN_UNAME_SOURCE_SHA=",
            "tests/bin/grp",
            "tests/expected/grp.stdout",
            "tests/src/grp.c",
            "tests/bin/xattr",
            "tests/expected/xattr.stdout",
            "tests/src/xattr.c",
            "tests/bin/fts",
            "tests/expected/fts.stdout",
            "tests/expected/fts.stderr",
            "tests/expected/fts.exit",
            "tests/src/fts.c",
            "tests/meta/fts.summary.txt",
            "tests/bin/statfs",
            "tests/expected/statfs.stdout",
            "tests/expected/statfs.stderr",
            "tests/expected/statfs.exit",
            "tests/src/statfs.c",
            "tests/meta/statfs.summary.txt",
            "STATFS_PRODUCTION_PATH=/replay",
            '"$RUNTIME/machorun" "$STATFS_FIXTURE" "$STATFS_PRODUCTION_PATH"',
            "tests/bin/copyfile",
            "tests/expected/copyfile.stdout",
            "tests/expected/copyfile.stderr",
            "tests/expected/copyfile.exit",
            "tests/src/copyfile.c",
            "tests/meta/copyfile.summary.txt",
            "scripts/copyfile_xattr_unavailable.sh",
            "copyfile-xattr-unavailable-probe",
            "xattr-unavailable fallback=success",
            "OPEN_FOUNDATION_COPYFILE_XATTR_UNAVAILABLE_OK",
            'awk -v target="$STATFS_PRODUCTION_PATH"',
            "/proc/self/mountinfo",
            'stat -f -c %t "$STATFS_PRODUCTION_PATH"',
            "fakeowner:6a656a63|virtiofs:*",
            "primary=%s bind-filesystem=%s bind-magic=%s abi=2168",
            "OPEN_FOUNDATION_STATFS_OK",
            "OPEN_FOUNDATION_GROUP_LOOKUP_OK",
            "OPEN_FOUNDATION_XATTR_OK",
            "OPEN_FOUNDATION_FTS_OK",
            "OPEN_FOUNDATION_STATFS_OK primary=%s bind-filesystem=%s "
            "bind-magic=%s abi=2168 "
            "path-fd=exact mounts=root,nested flags=translated errno=darwin "
            "oracle=apple-exact",
            "OPEN_FOUNDATION_COPYFILE_OK",
            "OPEN_FOUNDATION_LIBSYSTEM_COMPAT_OK",
            "FoundationEssentials-statfs\\tlibSystem-source=%s\\tfixture=%s\\t"
            "golden=%s\\tstderr=%s\\texit=%s\\tapple-source=%s\\t"
            "apple-summary=%s",
            '$(NF - 1) == "libSystem.real"',
            "group-lookup-macho.log",
            "xattr-macho.log",
            "fts-apple.txt",
            "fts-apple-summary.txt",
            "fts-macho.log",
            "copyfile-apple.txt",
            "copyfile-apple-summary.txt",
            "copyfile-macho.log",
            "copyfile-xattr-unavailable-macho.log",
            "statfs-apple.txt",
            "statfs-apple-summary.txt",
            "statfs-macho.log",
            "libsystem-compat-macho.log",
            "native Linux group static-storage contract drifted",
            "group-lookup-native.normalized.log",
        ):
            self.assertIn(token, builder)
        self.assertEqual(
            builder.count(
                'cp "$STATFS_GOLDEN" "$STAGE/attestation/statfs-apple.txt"'
            ),
            1,
        )
        self.assertEqual(
            builder.count(
                "record_artifact attestation FoundationEssentials "
                "statfs-apple-golden"
            ),
            1,
        )
        self.assertIn(
            "EXPECTED_MACHORUN_STATFS_FIXTURE_SHA="
            "723da2ef92cc06456c909b947950427420f1ce51ba61d71a5c5815555699970a",
            builder,
        )
        self.assertIn(
            "EXPECTED_MACHORUN_STATFS_SOURCE_SHA="
            "86a32bb57849992c8b2ef51a3b493d834fab988c119fdc9c4fcbd61c8ef038b9",
            builder,
        )
        self.assertIn(
            "EXPECTED_MACHORUN_FTS_LIBSYSTEM_SOURCE_SHA="
            "$EXPECTED_MACHORUN_LIBSYSTEM_SOURCE_SHA",
            builder,
        )
        self.assertIn(
            "EXPECTED_MACHORUN_STATFS_LIBSYSTEM_SOURCE_SHA="
            "$EXPECTED_MACHORUN_LIBSYSTEM_SOURCE_SHA",
            builder,
        )
        self.assertIn(
            "EXPECTED_MACHORUN_COPYFILE_LIBSYSTEM_SOURCE_SHA="
            "$EXPECTED_MACHORUN_LIBSYSTEM_SOURCE_SHA",
            builder,
        )
        self.assertIn(
            "EXPECTED_MACHORUN_STATFS_LIBSYSTEM_SOURCE_SHA="
            "$EXPECTED_MACHORUN_LIBSYSTEM_SOURCE_SHA",
            builder,
        )
        for symbol in (
            "_getgrgid",
            "_getgrgid_r",
            "_getgrnam",
            "_getgrnam_r",
            "_fgetxattr",
            "_fsetxattr",
            "_getxattr",
            "_listxattr",
            "_setxattr",
            "_fts_close",
            "_fts_open",
            "_fts_read",
            "_fts_children",
            "_fts_set",
            "_statfs",
            "_fstatfs",
            "_copyfile",
            "_copyfile_state_alloc",
            "_copyfile_state_free",
            "_copyfile_state_get",
            "_copyfile_state_set",
            "_fcopyfile",
            "_statfs",
            "_fstatfs",
            "_quotactl",
            "_uname",
        ):
            self.assertIn(symbol, builder)

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
        foundation_start = source.index(
            "-install_name @rpath/libFoundation.dylib"
        )
        foundation_link = source[
            foundation_start : source.index(
                "foundation_graphics_load_count=", foundation_start
            )
        ]
        self.assertLess(
            foundation_link.index('"${FOUNDATION_RUNTIME_LINK_FLAGS[@]}"'),
            foundation_link.index("-reexport_library"),
        )
        self.assertIn("foundation_object_identifier_core_bind_count=", source)
        self.assertIn("foundation_errno_runtime_bind_count=", source)
        self.assertIn('$(NF - 1) == "libswiftCore"', source)
        self.assertIn('$(NF - 1) == "libswift_errno"', source)

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
                        "Combine Symbols SwiftUI _QuickLook_SwiftUI _PhotosUI_SwiftUI \\",
                        "    _AuthenticationServices_SwiftUI Foundation UIKit CoreImage QuartzCore \\",
                        "    Intents IntentsUI WebKit \\",
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

    def test_observation_platform_is_complete_and_deletion_is_refused(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        validate_observation_platform_contract(source)
        for token in (
            "EXPECTED_OBSERVATION_UPSTREAM_COMMIT=",
            "-module-name Observation -module-link-name swiftObservation",
            "-load-plugin-library host-tools/swift/host/plugins/libObservationMacros.so",
            '"$W/full/observation/tests/ObservationGuestRuntimeProbe.swift"',
            "observation=macro,reexport,registrar,tracking,ignored,one-shot",
        ):
            with self.subTest(deleted=token):
                with self.assertRaisesRegex(AssertionError, "Observation platform"):
                    validate_observation_platform_contract(
                        source.replace(token, "", 1)
                    )

    def test_swiftui_links_foundation_facades_directly(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        validate_swiftui_foundation_essentials_link(source)
        self.assertLess(
            source.index("compile the ordered app-facing Foundation facade manifest"),
            source.index("compile SwiftUI against the app-facing Foundation facade"),
        )
        self.assertIn(
            '"$W/full/frameworks/SwiftUIFoundationReexportProbe.swift"',
            source,
        )
        reexport_probe = (
            HERE / "SwiftUIFoundationReexportProbe.swift"
        ).read_text(encoding="utf-8")
        self.assertIn("import SwiftUI", reexport_probe)
        self.assertNotIn("import Foundation", reexport_probe)
        self.assertNotIn("import Combine", reexport_probe)
        self.assertNotIn("import Dispatch", reexport_probe)
        for token in (
            "NotificationCenter.Publisher",
            "UserDefaults.didChangeNotification",
            "AnyCancellable",
            "DispatchQueue.main",
        ):
            self.assertIn(token, reexport_probe)
        for token in (
            "probe/SwiftUIFoundationReexportProbe",
            "attestation/swiftui-foundation-reexport-runtime.log",
            "SWIFTUI_FOUNDATION_REEXPORT_MACHO_OK import=swiftui-only",
            "SwiftUI Foundation/Combine/Dispatch reexport marker is missing",
        ):
            self.assertIn(token, source)
        for token in (
            '"${COMMON_LINK[@]}" -lFoundation -lFoundationEssentials -lOpenUIKit',
            "swiftui_foundation_load_count=",
            '"@rpath/libFoundation.dylib"',
            "swiftui_foundation_essentials_load_count=",
            '"@rpath/libFoundationEssentials.dylib"',
        ):
            with self.subTest(deleted=token):
                swiftui_start = source.index(
                    "-install_name @rpath/libSwiftUI.dylib"
                )
                token_offset = source.index(token, swiftui_start)
                mutated = (
                    source[:token_offset]
                    + source[token_offset + len(token):]
                )
                with self.assertRaisesRegex(
                    AssertionError, "SwiftUI FoundationEssentials link"
                ):
                    validate_swiftui_foundation_essentials_link(mutated)

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

    def test_foundation_cferror_bridge_is_packaged_and_abi_gated(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        manifest_source = TOOL.read_text(encoding="utf-8")
        canonical_source = CANONICAL_VALIDATOR.read_text(encoding="utf-8")
        bridge = (REPO / "full/foundation/CFError+Error.swift").read_text(
            encoding="utf-8"
        )
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(
            encoding="utf-8"
        )
        for token in (
            "COpenFoundationCore/OpenFoundationCFError.h",
            "COpenFoundationCore/module.modulemap",
            "_$sSo10CFErrorRefas5Error10FoundationMc",
            "foundation-runtime-exports.txt",
            "_CFErrorGetDomain",
            "_CFErrorGetCode",
            "_CFErrorCopyUserInfo",
        ):
            self.assertIn(token, source)
        for token in (
            "-fmodule-map-file=include/COpenFoundationCore/module.modulemap",
            "-Iinclude/COpenFoundationCore",
        ):
            self.assertIn(token, source)
            self.assertIn(token, manifest_source)
            self.assertIn(token, canonical_source)
        self.assertIn("unsafeBitCast(self, to: NSError.self)", bridge)
        self.assertIn("let cfErrorAsError: any Error = cfError", probe)
        self.assertIn(
            "cfErrorAsError._getEmbeddedNSError() === cfError", probe
        )
    def test_background_tasks_and_core_spotlight_are_native_shaped_runtime_products(
        self,
    ) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        background = (
            REPO / "full/backgroundtasks/BackgroundTasks.swift"
        ).read_text(encoding="utf-8")
        spotlight = (REPO / "full/corespotlight/CoreSpotlight.swift").read_text(
            encoding="utf-8"
        )
        corpus = (
            REPO / "full/corespotlight/tests/CorpusConsumerSurface.swift"
        ).read_text(encoding="utf-8")
        host_gate = (
            REPO
            / "full/backgroundtasks/tests/test_background_spotlight_host.sh"
        ).read_text(encoding="utf-8")

        for token in (
            "BGAppRefreshTaskRequest",
            "BGProcessingTaskRequest",
            "pendingTaskRequests() async",
            "cancelAllTaskRequests()",
            "_launchPortableTask",
            "BGTaskSchedulerErrorDomain",
            "pending.append(taskRequest.portableCopy())",
        ):
            self.assertIn(token, background)
        for token in (
            "CSSearchableItemAttributeSet",
            "CSSearchableIndex",
            "indexSearchableItems",
            "deleteSearchableItems",
            "beginIndexBatch",
            "endIndexBatch",
            "indexAppEntities",
            "_searchPortable",
            "item.portableCopy()",
        ):
            self.assertIn(token, spotlight)
        for module in ("BackgroundTasks", "CoreSpotlight"):
            self.assertIn(f"import {module}", corpus)
            self.assertIn(f"import {module}", probe)
            self.assertIn(f"lib{module}.dylib", builder)
            self.assertIn(f"{module}GuestRuntime", builder)
        self.assertIn("-lBackgroundTasks -lDispatch", builder)
        self.assertIn("-lCoreSpotlight -lUniformTypeIdentifiers", builder)
        self.assertIn("backgroundtasks=scheduler,host-driven", probe)
        self.assertIn("corespotlight=index,query,app-entities", probe)
        self.assertIn("xcrun --sdk iphoneos --show-sdk-path", host_gate)
        self.assertIn("-target arm64-apple-ios18.0", host_gate)
        self.assertIn('swiftc -parse-as-library -typecheck -I "$PROOF"', host_gate)
        self.assertIn("BACKGROUND_SPOTLIGHT_HOST_GATE_OK", host_gate)

    def test_widgetkit_is_an_executable_first_party_boundary(self) -> None:
        builder = BUILDER.read_text(encoding="utf-8")
        widgetkit = (REPO / "full/widgetkit/WidgetKit.swift").read_text(
            encoding="utf-8"
        )
        gate = (
            REPO / "full/widgetkit/tests/test_widgetkit_host.sh"
        ).read_text(encoding="utf-8")
        for token in (
            "public protocol TimelineProvider",
            "public protocol IntentTimelineProvider",
            "public protocol AppIntentTimelineProvider",
            "public actor WidgetTimelineRuntime",
            "public final class WidgetCenter",
            "public struct StaticConfiguration",
            "public struct IntentConfiguration",
            "public struct AppIntentConfiguration",
            "case processLocal",
            "case hostDriven",
        ):
            self.assertIn(token, widgetkit)
        for token in (
            "WidgetKit)",
            "-D OPENUIKIT_PORTABLE_SWIFTUI",
            "-lWidgetKit -lAppIntents -lIntents -lSwiftUI",
            "WidgetKitGuestRuntime",
            "WIDGETKIT_HOST_OK",
            "SimplenoteWidgetKitConsumer.swift",
            "record_artifact probe WidgetKitGuestRuntime",
            "record_artifact attestation WidgetKit runtime-log",
        ):
            self.assertIn(token, builder)
        for token in (
            "EXPECTED_ICECUBES_COMMIT=b2db3033",
            "EXPECTED_SIMPLENOTE_COMMIT=9b1bb17",
            '"$frontier_source_count" -eq 18',
            "SimplenoteWidgets/Providers/NoteWidgetProvider.swift",
            "SimplenoteWidgets/Widgets/NoteWidget.swift",
            "SimplenoteWidgets/SimplenoteWidgets.swift",
        ):
            self.assertIn(token, gate)

    def test_thirty_eight_first_party_frameworks_are_real_core_products(self) -> None:
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
            "CoreGraphics",
            "ImageIO",
            "LinkPresentation",
            "MessageUI",
            "MobileCoreServices",
            "Security",
            "CryptoKit",
            "CommonCrypto",
            "AppIntents",
            "WidgetKit",
            "OSLog",
            "UniformTypeIdentifiers",
            "SwiftData",
            "UserNotifications",
            "BackgroundTasks",
            "CoreSpotlight",
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
            "NaturalLanguage",
            "AuthenticationServices",
            "FoundationModels",
        )
        self.assertEqual(FRAMEWORKS[-38:], first_party)
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
        self.assertIn("portable-self-id=%s", source)
        self.assertIn("string-processing=%s", source)
        self.assertIn("openuikit=%s", source)
        self.assertIn("opencoregraphics=%s", source)
        self.assertIn("expected_openuikit_load=1", source)
        self.assertIn("expected_opencoregraphics_load=1", source)
        self.assertIn("lib$framework OpenUIKit load count", source)
        self.assertIn("lib$framework OpenCoreGraphics load count", source)
        self.assertIn(
            "coremedia_load_count - portable_self_id_count", source
        )
        self.assertIn(
            "avfoundation_load_count - portable_self_id_count", source
        )
        self.assertIn("portable install ID count", source)
        self.assertIn("apple-self-load=0", source)
        self.assertIn(
            "frontier-frameworks\\tframeworks=33\\tsources=38\\tinputs=132",
            source,
        )
        self.assertIn(
            "frontier-source' \"$WORK/first-party-sources.pre.tsv\")\" -eq 38",
            source,
        )
        self.assertIn(
            "frontier-input' \"$WORK/first-party-sources.pre.tsv\")\" -eq 132",
            source,
        )
        self.assertIn(
            "compile thirty-eight independent first-party framework modules", source
        )
        accelerate_header = (
            REPO / "full/accelerate/include/Accelerate.h"
        ).read_text(encoding="utf-8")
        self.assertIn(
            "OPENUIKIT_ACCELERATE_EXPORT vImage_Error "
            "vImageBoxConvolve_ARGB8888(",
            accelerate_header,
        )
        self.assertIn("network_string_processing_undefineds", source)
        self.assertIn("direct StringProcessing undefineds, expected 0", source)
        self.assertIn("corespotlight_string_processing_undefineds", source)
        self.assertIn(
            "CoreSpotlight StringProcessing undefined count", source
        )
        self.assertIn("expected_string_processing_load=1", source)
        self.assertIn(
            "lib$framework StringProcessing load count", source
        )
        for imageio_probe_token in (
            "CGImageSourceCreateIncremental(nil)",
            "CGImageSourceGetStatus(incremental) == .statusIncomplete",
            "CGImageSourceUpdateData(incremental, encoded as CFData, true)",
            "CGImageSourceGetStatus(incremental) == .statusComplete",
            "CGImageSourceGetCount(animatedSource) == 2",
            "kCGImagePropertyGIFDelayTime",
            "imageio=static,incremental,animated-gif",
        ):
            self.assertIn(imageio_probe_token, probe)
        self.assertIn("let tgmathRemainder = remquo(CGFloat(257), CGFloat(1))", probe)
        self.assertIn('OpenCoreGraphics.nan("0x42").isNaN', probe)
        network_source = (REPO / "full/network/Network.swift").read_text(
            encoding="utf-8"
        )
        self.assertNotIn(".ranges(of:", network_source)
        self.assertIn("first-party=portable-38", probe)
        self.assertIn("foundationmodels=generated-content,fail-closed", probe)
        self.assertIn("FoundationModelsGuestRuntime", source)
        self.assertIn("FOUNDATIONMODELS_GUEST_MACHO_OK", source)
        self.assertIn("naturallanguage=classifier,apple-29", probe)
        self.assertIn("NaturalLanguageGeneralizationRuntime", source)
        self.assertIn("NATURALLANGUAGE_GUEST_MACHO_OK", source)
        self.assertIn(
            "naturallanguage-generalization-apple-26.1.txt", source
        )
        self.assertIn(
            "NaturalLanguage generalization output differs from Apple 26.1",
            source,
        )
        self.assertIn(
            "NaturalLanguage generalization row count "
            "$naturallanguage_generalization_rows, expected 29",
            source,
        )
        self.assertIn(
            "@rpath/libNaturalLanguage.dylib", source
        )
        self.assertIn("languageHypotheses(withMaximum: 1)", probe)
        self.assertIn(
            "constrainedLanguageRecognizer.languageConstraints = "
            "[.french, .spanish]",
            probe,
        )
        self.assertIn("usernotifications=fail-closed,volatile", probe)
        self.assertIn("UserNotificationsGuestRuntime", source)
        self.assertIn("USERNOTIFICATIONS_GUEST_MACHO_OK", source)
        self.assertIn(
            "full/usernotifications/tests/UserNotificationsHostRuntime.swift",
            source,
        )
        self.assertIn("quicklook=local-image,host-driven", probe)
        self.assertIn("QuickLookGuestRuntime", source)
        self.assertIn("QUICKLOOK_GUEST_MACHO_OK", source)
        self.assertIn("QuickLook.swiftcrossimport", source)
        self.assertIn("lib_QuickLook_SwiftUI.dylib", source)
        self.assertIn("lib_PhotosUI_SwiftUI.dylib", source)
        self.assertIn("media=rational,state,host-driven,fail-closed", probe)
        self.assertIn("charts=basic,fail-closed", probe)
        self.assertIn("CoreMediaGuestRuntime", source)
        self.assertIn("AVFoundationGuestRuntime", source)
        self.assertIn("ChartsGuestRuntime", source)
        self.assertIn("WidgetKitGuestRuntime", source)
        self.assertIn("CoreTransferableGuestRuntime", source)
        self.assertIn("PhotosGuestRuntime", source)
        self.assertIn("PhotosUIGuestRuntime", source)
        self.assertIn("NaturalLanguageGuestRuntime", source)
        self.assertIn("AuthenticationServicesGuestRuntime", source)
        self.assertIn("AVFOUNDATION_HOST_OK", source)
        self.assertIn("CHARTS_HOST_OK", source)
        self.assertIn("WIDGETKIT_HOST_OK", source)
        self.assertIn("CORETRANSFERABLE_HOST_OK", source)
        self.assertIn("PHOTOS_HOST_OK", source)
        self.assertIn("PHOTOSUI_HOST_OK", source)
        self.assertIn("coretransferable=data,file,fail-closed", probe)
        self.assertIn("widgetkit=timelines,process-local,host-driven", probe)
        self.assertIn("photos=authorization,volatile,host-driven", probe)
        self.assertIn("photosui=transfer,binding,host-driven", probe)
        self.assertIn("naturallanguage=deterministic,confidence-gated", probe)
        self.assertIn("authenticationservices=host-driven,fail-closed", probe)
        avfoundation_source = (
            REPO / "full/avfoundation/AVFoundation.swift"
        ).read_text(encoding="utf-8")
        self.assertIn("#if canImport(OpenUIKit)", avfoundation_source)
        self.assertIn("import OpenUIKit", avfoundation_source)
        self.assertIn("-lOpenUIKit", source)
        charts_source = (REPO / "full/charts/Charts.swift").read_text(
            encoding="utf-8"
        )
        self.assertIn("import CoreGraphics", charts_source)
        self.assertIn("-lOpenCoreGraphics", source)
        self.assertIn("oslog=standard-error,signposts", probe)
        self.assertIn("uniform-types=tags,conformance", probe)
        self.assertIn("security=keychain,random", probe)
        for framework in first_party:
            with self.subTest(framework=framework):
                self.assertIn(framework, source)
                self.assertIn(framework, manifest_source)
                self.assertIn(framework, canonical_source)
                self.assertIn(f"import {framework}", probe)
                self.assertIn(f"-l{framework}", source)

        oslog_source = (REPO / "full/oslog/OSLog.swift").read_text(
            encoding="utf-8"
        )
        os_source = (REPO / "full/foundation/os-module/os.swift").read_text(
            encoding="utf-8"
        )
        self.assertIn("@_exported import os", oslog_source)
        self.assertNotIn("struct Logger", oslog_source)
        self.assertIn("public struct OSSignpostType", os_source)
        self.assertIn("public struct OSSignpostID", os_source)
        self.assertIn("public func os_signpost(", os_source)
        self.assertIn(
            '-reexport_library "$STAGE/lib/libFoundationEssentials.dylib"',
            source,
        )
        self.assertIn("os-runtime-reexport=%s", source)
        self.assertIn("foundation-essentials=%s", source)
        self.assertIn("foundation-essentials-ordinary=%s", source)
        self.assertIn("expected_foundation_load=0", source)
        self.assertIn("expected_foundation_essentials_load=2", source)
        self.assertIn(
            "foundation_essentials_load_count - os_runtime_reexport_count",
            source,
        )
        self.assertIn(
            "ordinary FoundationEssentials load count",
            source,
        )
        for token in (
            "standalone OSLog re-export gate",
            "-o \"$STAGE/probe/OSLogGuestRuntime\"",
            '"${COMMON_LINK[@]}" -lOSLog',
            "direct-Foundation-load-count\\t%s",
            "direct-FoundationEssentials-load-count\\t%s",
            "os-runtime-resolution\\tLC_REEXPORT_DYLIB",
            "OSLOG_GUEST_MACHO_OK",
            "attestation/oslog-runtime.log",
            "attestation/oslog-standalone-link.tsv",
        ):
            self.assertIn(token, source)

    def test_revenuecat_adservices_zlib_and_iokit_frontier_is_fail_closed_and_fixed_abi(
        self,
    ) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        adservices = (REPO / "full/adservices/AdServices.swift").read_text(
            encoding="utf-8"
        )
        zlib_header = (REPO / "full/zlib/include/zlib/zlib.h").read_text(
            encoding="utf-8"
        )
        zlib_bridge = (REPO / "full/zlib/OpenZlibBridge.c").read_text(
            encoding="utf-8"
        )
        iokit_header = (REPO / "full/iokit/include/IOKit.h").read_text(
            encoding="utf-8"
        )
        iokit_source = (REPO / "full/iokit/IOKit.c").read_text(
            encoding="utf-8"
        )
        iokit_overlay = (REPO / "full/iokit/IOKit.swift").read_text(
            encoding="utf-8"
        )
        iokit_golden = (
            REPO / "full/iokit/tests/iokit-interface-apple-2026-09-01.txt"
        ).read_text(encoding="utf-8")
        iokit_portable_golden = (
            REPO / "full/iokit/tests/iokit-interface-portable-2026-09-01.txt"
        ).read_text(encoding="utf-8")
        exact_guest = (
            REPO / "full/adservices/tests/test_revenuecat_frontier_guest.sh"
        ).read_text(encoding="utf-8")

        for token in (
            '"com.apple.ap.adservices.attributionError"',
            "platformNotSupported = Code(rawValue: 3)",
            "throw AAAttributionError(.platformNotSupported)",
        ):
            self.assertIn(token, adservices)
        self.assertNotIn("return UUID", adservices)
        for token in (
            '#define ZLIB_VERSION "1.2.12"',
            "typedef struct z_stream_s",
            "ZEXPORT int inflateInit2_",
            "ZEXPORT int inflateEnd",
        ):
            self.assertIn(token, zlib_header)
        for token in (
            '_Static_assert(sizeof(z_stream) == 112',
            '__asm__("_glibc_open_zlib_abi_version")',
            '__asm__("_glibc_open_zlib_inflate_init2")',
            '__asm__("_glibc_open_zlib_inflate")',
            '__asm__("_glibc_open_zlib_inflate_end")',
        ):
            self.assertIn(token, zlib_bridge)
        for token in (
            "/usr/lib/aarch64-linux-gnu/libz.so.1.3",
            "libOpenCompression.dylib",
            "libOpenZlibHost.so",
            "libOpenZlib.dylib",
            "zlib-gzip-apple-2026-09-01.txt",
            "libz.dylib",
            "-lAdServices -lz",
            'framework_link_dependencies+=("$COMPRESSION_DARWIN")',
            '-reexport_library "$ZLIB_DARWIN"',
            "libCompression directly imports a Linux host symbol",
            "libz directly imports a Linux host symbol",
            "/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit",
            "iokit-expected-exports.txt",
            "IOKit framework exports drifted",
            "IOKit framework has unexpected undefined imports",
            "IOKIT_HOST_OK matching=nil services=unsupported iterator=nil properties=nil",
            "IOKIT_GUEST_OK matching=nil services=unsupported iterator=nil properties=nil",
            "iokit-interface-apple.txt",
            "iokit-interface-portable.txt",
            '-module-name IOKit -module-link-name swiftIOKit',
            "-import-underlying-module",
            'record_module_family framework IOKit',
            "-F frameworks -framework AppKit -framework IOKit",
        ):
            self.assertIn(token, source)
        for token in (
            "typedef mach_port_t io_object_t",
            "kIORegistryIterateRecursively = 0x00000001",
            "kIORegistryIterateParents = 0x00000002",
            "kIOReturnUnsupported ((kern_return_t)0xe00002c7u)",
            "IOServiceGetMatchingServices",
            "IORegistryEntrySearchCFProperty",
        ):
            self.assertIn(token, iokit_header)
        for token in (
            "return kIOReturnUnsupported;",
            "*existing = IO_OBJECT_NULL;",
            "return NULL;",
        ):
            self.assertIn(token, iokit_source)
        self.assertNotIn("_glibc_", iokit_header + iokit_source)
        for token in (
            "import Foundation",
            "public func IOBSDNameMatching(",
            "public func IOServiceGetMatchingServices(",
            "public func IORegistryEntrySearchCFProperty(",
            "public var kIOReturnUnsupported: IOReturn",
        ):
            self.assertIn(token, iokit_overlay)
        self.assertEqual(iokit_overlay.count("public var kIOReturn"), 52)
        self.assertNotIn("_glibc_", iokit_overlay)
        self.assertIn("sdk=macOS26.1,xcode=17B55", iokit_golden)
        self.assertIn(
            "types=mach-port:4,io-object:4,io-option:4,kern-return:4",
            iokit_golden,
        )
        self.assertIn(
            "signature-bsd=(mach_port_t,UInt32,String)->CFMutableDictionary?",
            iokit_portable_golden,
        )
        self.assertTrue(iokit_portable_golden.endswith("missing=matching:nil\n"))
        for token in (
            "57043e7e0173c48d64e171944ac76a34d2467fa1",
            "72a2e1e9b6986fadca9b863d235c4a52aab38fb4",
            "f15a4f4a4cab68e397fdfff4bc6b8b64838d19b968d278650834b2a837a3258a",
            "b0998e607a77f25856f7cf65aa34248e910d7157d1215b3ae5ab974579b6ecec",
            "247a96213f5e5f005fb1619024986b38c3c276a7852b30feec049c3d529fcea9",
            '-needed_library "$PACKAGE/lib/libAdServices.dylib"',
            '-needed_library "$PACKAGE/lib/libCompression.dylib"',
            '-needed_library "$PACKAGE/lib/libz.dylib"',
            "REVENUECAT_FRONTIER_GUEST_OK",
            '"$REVENUECAT/Sources/Misc/MacDevice.swift"',
            "RevenueCatIOKitRuntimeSupport.swift",
            "/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit",
            "REVENUECAT_IOKIT_UNTOUCHED_MACHO_OK",
            "consumers=3 runtime=adservices,zlib,iokit",
        ):
            self.assertIn(token, exact_guest)

    def test_accelerate_c_entry_point_survives_hidden_visibility_build(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        header = (
            REPO / "full/accelerate/include/Accelerate.h"
        ).read_text(encoding="utf-8")
        self.assertIn(
            '#define OPENUIKIT_ACCELERATE_EXPORT '
            '__attribute__((visibility("default")))',
            header,
        )
        self.assertIn(
            "OPENUIKIT_ACCELERATE_EXPORT vImage_Error "
            "vImageBoxConvolve_ARGB8888(",
            header,
        )
        self.assertIn("-fvisibility=hidden", source)
        self.assertIn("libAccelerate vImage export count drifted", source)

    def test_cryptokit_has_real_hashes_nonce_and_fail_closed_signing(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        crypto = (REPO / "full/cryptokit/CryptoKit.swift").read_text(
            encoding="utf-8"
        )
        host_gate = (
            REPO / "full/cryptokit/tests/CryptoKitHostTests.swift"
        ).read_text(encoding="utf-8")
        for token in ("_md5", "_sha1", "_sha256", "_sha512"):
            self.assertIn(token, crypto)
        self.assertIn("SystemRandomNumberGenerator", crypto)
        self.assertIn("return signature.count == 64 && false", crypto)
        self.assertIn("import CryptoKit", probe)
        self.assertIn("SHA256.hash", probe)
        self.assertIn("-lCryptoKit", source)
        self.assertIn("CRYPTOKIT_HOST_OK", host_gate)

    def test_commoncrypto_is_a_real_c_sha256_boundary(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        implementation = (
            REPO / "full/commoncrypto/CommonDigest.c"
        ).read_text(encoding="utf-8")
        header = (
            REPO / "full/commoncrypto/include/CommonDigest.h"
        ).read_text(encoding="utf-8")
        host_gate = (
            REPO / "full/commoncrypto/tests/CommonCryptoHostTests.c"
        ).read_text(encoding="utf-8")
        for token in ("CC_SHA256_Init", "CC_SHA256_Update", "CC_SHA256_Final"):
            self.assertIn(token, implementation)
            self.assertIn(token, header)
        self.assertIn("CCommonCrypto/module.modulemap", source)
        self.assertIn("commoncrypto-c.o", source)
        self.assertIn("frontier underlying input count drifted", source)
        for relative in (
            "full/commoncrypto/CommonDigest.c",
            "full/commoncrypto/include/CommonDigest.h",
            "full/commoncrypto/include/module.modulemap",
        ):
            self.assertIn(relative, source)
        self.assertIn("import CommonCrypto", probe)
        self.assertIn("CC_SHA256", probe)
        self.assertIn("COMMONCRYPTO_HOST_OK", host_gate)

    def test_security_is_a_real_keychain_and_randomness_boundary(self) -> None:
        source = BUILDER.read_text(encoding="utf-8")
        probe = (HERE / "CoreGuestPackageProbe.swift").read_text(encoding="utf-8")
        security = (REPO / "full/security/Security.swift").read_text(
            encoding="utf-8"
        )
        host_gate = (
            REPO / "full/security/tests/test_security_host.sh"
        ).read_text(encoding="utf-8")
        self.assertIn("-D OPENUIKIT_PORTABLE_FOUNDATION", source)
        self.assertIn("-lMobileCoreServices -lSecurity", source)
        self.assertIn("SecItemAdd", security)
        self.assertIn("SecItemCopyMatching", security)
        self.assertIn("SystemRandomNumberGenerator", security)
        self.assertIn("return errSecNotAvailable", security)
        self.assertIn("import Security", probe)
        self.assertIn("SecItemCopyMatching", probe)
        self.assertIn("SecRandomCopyBytes", probe)
        self.assertIn("/System/Library/Frameworks/Security.framework/", host_gate)
        self.assertIn("SECURITY_HOST_OK", host_gate)

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
                    "--expected-machorun-swift-core-sha256",
                    "0" * 64,
                    "--expected-machorun-objc-sha256",
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
