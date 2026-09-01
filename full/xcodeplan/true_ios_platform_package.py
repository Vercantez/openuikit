#!/usr/bin/env python3
"""Validate and expose the relocatable true-iOS framework platform package.

The package is intentionally stricter than an ordinary SDK directory.  Its
completion marker commits two complete ledgers, every regular file and symlink
must be represented exactly once, public framework copies must be byte-identical,
and Mach-O identity is re-parsed before compiler or linker arguments are emitted.
"""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path, PurePosixPath
import re
import stat
import struct
import sys
from typing import Any


class TrueIOSPlatformError(RuntimeError):
    """The true-iOS package does not satisfy the consumption contract."""


_SHA256 = re.compile(r"[0-9a-f]{64}\Z")
_TARGET = "arm64-apple-ios18.0-simulator"
_VARIANT = "arm64-apple-ios-simulator"
_PLATFORM = 7
_MINIMUM_OS = 0x00120000
_SDK_VERSION = 0x001A0100
_MODULES = (
    "FoundationEssentials",
    "FoundationInternationalization",
    "Foundation",
    "Dispatch",
    "OpenCoreGraphics",
    "OpenUIKit",
    "DeveloperToolsSupport",
    "UIKit",
    "OpenCombine",
    "Combine",
    "Symbols",
    "SwiftUI",
    "NaturalLanguage",
    "AuthenticationServices",
    "_AuthenticationServices_SwiftUI",
    "Accelerate",
    "Compression",
    "CoreText",
)
_PRIVATE_DYLIBS = ("_FoundationICU",)
_RUNTIME_SWIFT_MODULES = ("Observation",)
_MODULE_SUFFIXES = ("swiftmodule", "swiftdoc", "swiftsourceinfo", "abi.json")
_OVERLAYS = (
    "Darwin",
    "ObjectiveC",
    "_DarwinFoundation1",
    "_DarwinFoundation2",
    "_DarwinFoundation3",
)
_ROOT_ENTRIES = {
    "PLATFORM_COMPLETE",
    "apple-overlays",
    "attestation",
    "internal-modules",
    "host-tools",
    "package",
    "platform-include",
    "products",
    "resources",
    "runtime-root",
    "sdk",
    "sdk-provenance",
    "true-ios-swiftui-dylib-probe",
}
_UNLEDGERED_REGULAR = {
    "PLATFORM_COMPLETE",
    "attestation/artifacts.sha256",
    "attestation/symlinks.tsv",
}
_REQUIRED_ATTESTATION = {
    "artifacts.sha256",
    "accelerate-apple-differential.log",
    "accelerate-compression-coretext-loads.tsv",
    "compiler-plugins.tsv",
    "compression-brotli-apple.txt",
    "coretext-font-manager-apple.txt",
    "foundation-internationalization-abi.tsv",
    "foundation-internationalization-host.tsv",
    "foundation-internationalization-sources.tsv",
    "foundation-runtime-exports.txt",
    "foundation-runtime-undefineds.txt",
    "framework-module-loading.log",
    "naturallanguage-authenticationservices-loads.tsv",
    "open-compression-abi.tsv",
    "open-compression-host-test.log",
    "open-compression-host.tsv",
    "opencombine-sources.json",
    "opencombine-sources.nul",
    "runtime.log",
    "source-subject.after.sha256",
    "source-subject.before.sha256",
    "symlinks.tsv",
}
_REQUIRED_FOUNDATION_RUNTIME_EXPORTS = {
    "_$s10Foundation24_getErrorDefaultUserInfoyyXlSgxs0C0RzlF",
    "_$s10Foundation21_bridgeNSErrorToError_3outSbSo0C0C_SpyxGtAA021_ObjectiveCBridgeableE0RzlF",
    "_$s10Foundation26_ObjectiveCBridgeableErrorMp",
    "_$sSo10CFErrorRefas5Error10FoundationMc",
}
_FORBIDDEN_FOUNDATION_CFERROR_IMPORTS = {
    "_CFErrorGetDomain",
    "_CFErrorGetCode",
    "_CFErrorCopyUserInfo",
}
_REQUIRED_HOST_LIBRARIES = {
    "libBlocksRuntime.so",
    "libOpenDispatchHost.so",
    "libOpenFoundationInternationalizationHost.so",
    "libOpenRelativeTimeHost.so",
    "libOpenURLTransportHost.so",
    "libOpenCompressionHost.so",
    "libdispatch.so",
}
_REQUIRED_RUNTIME_FILES = (
    "runtime-root/machorun",
    "runtime-root/darwin/usr/lib/libSystem.B.dylib",
    "runtime-root/darwin/usr/lib/libSystem.real.dylib",
    "runtime-root/darwin/usr/lib/libobjc.A.dylib",
    "runtime-root/darwin/usr/lib/libquartz.dylib",
    "runtime-root/darwin/usr/lib/libswiftcompat.dylib",
    "runtime-root/darwin/usr/lib/swift/libswiftCore.dylib",
    "runtime-root/darwin/usr/lib/swift/libswiftObjectiveC.dylib",
    "runtime-root/darwin/usr/lib/swift/libswift_Concurrency.dylib",
    "runtime-root/darwin/usr/lib/swift/libswiftObservation.dylib",
)
_REQUIRED_SDK_FILES = (
    "sdk/usr/lib/libSystem.B.tbd",
    "sdk/usr/lib/libobjc.A.tbd",
    "sdk/usr/lib/swift/libswiftCore.tbd",
    "sdk/usr/lib/swift/libswiftObjectiveC.tbd",
    "sdk/usr/lib/swift/libswift_Concurrency.tbd",
)
_REQUIRED_RESOURCE_FILES = (
    "resources/OpenUIKit/system_colors.json",
    "resources/OpenUIKit/font_metrics.json",
    "resources/OpenUIKit/text_decorations.json",
    "resources/OpenUIKit/fonts/DejaVuSans.ttf",
    "resources/OpenUIKit/fonts/DejaVuSans-Bold.ttf",
)
_REQUIRED_CLANG_MODULES = (
    "CHostClock",
    "COpenCombineHelpers",
    "COpenAccelerate",
    "COpenCompression",
    "COpenDispatch",
    "COpenFoundationCore",
    "COpenRelativeTime",
    "COpenURLTransport",
    "CPortableIO",
    "CQuartz",
    "CSTBTrueType",
    "_FoundationCShims",
)
_COMPILER_PLUGINS = (
    "ObservationMacros",
    "FoundationMacros",
    "SwiftDataMacros",
    "OpenUIKitPreviewMacros",
    "OpenSwiftUIMacros",
)
_PLUGIN_HOST_LIBRARIES = {
    "libSwiftSyntaxMacros.so",
    "libSwiftSyntaxBuilder.so",
    "libSwiftParserDiagnostics.so",
    "libSwiftBasicFormat.so",
    "libSwiftParser.so",
    "libSwiftDiagnostics.so",
    "libSwiftSyntax.so",
}
_PLUGIN_LINUX_LIBRARIES = {
    "libswiftCore.so",
    "libswift_Concurrency.so",
    "libswiftGlibc.so",
    "libdispatch.so",
    "libswift_Builtin_float.so",
    "libBlocksRuntime.so",
    "libswiftSwiftOnoneSupport.so",
    "libswift_StringProcessing.so",
    "libswift_RegexParser.so",
}


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def _strict_root(path: Path) -> Path:
    try:
        metadata = path.lstat()
    except OSError as exc:
        raise TrueIOSPlatformError(f"cannot inspect package root: {path}: {exc}") from exc
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        raise TrueIOSPlatformError(f"package root is not an ordinary directory: {path}")
    return path.resolve(strict=True)


def _relative(text: str, label: str) -> PurePosixPath:
    if not text or any(character in text for character in "\0\r\n\t"):
        raise TrueIOSPlatformError(f"{label} is empty or contains a control character")
    path = PurePosixPath(text)
    if path.is_absolute() or any(part in ("", ".", "..") for part in path.parts):
        raise TrueIOSPlatformError(f"{label} is not a safe relative path: {text!r}")
    return path


def _regular(root: Path, relative: str, label: str) -> Path:
    path = root / _relative(relative, label)
    try:
        metadata = path.lstat()
    except OSError as exc:
        raise TrueIOSPlatformError(f"cannot inspect {label}: {path}: {exc}") from exc
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISREG(metadata.st_mode):
        raise TrueIOSPlatformError(f"{label} is not a regular file: {path}")
    try:
        path.resolve(strict=True).relative_to(root)
    except (OSError, ValueError) as exc:
        raise TrueIOSPlatformError(f"{label} escapes the package: {path}") from exc
    return path


def _walk_nodes(root: Path) -> tuple[set[str], dict[str, str]]:
    regular: set[str] = set()
    links: dict[str, str] = {}
    pending = [root]
    while pending:
        directory = pending.pop()
        try:
            entries = sorted(os.scandir(directory), key=lambda entry: entry.name)
        except OSError as exc:
            raise TrueIOSPlatformError(f"cannot enumerate package: {directory}: {exc}") from exc
        for entry in entries:
            if not entry.name or any(character in entry.name for character in "\0\r\n\t\\"):
                raise TrueIOSPlatformError(f"unsafe package path component: {entry.name!r}")
            path = Path(entry.path)
            relative = path.relative_to(root).as_posix()
            try:
                metadata = path.lstat()
            except OSError as exc:
                raise TrueIOSPlatformError(f"cannot inspect package node: {path}: {exc}") from exc
            if stat.S_ISLNK(metadata.st_mode):
                target = os.readlink(path)
                if not target or target.startswith("/") or any(
                    character in target for character in "\0\r\n\t"
                ):
                    raise TrueIOSPlatformError(f"unsafe symlink target at {relative}: {target!r}")
                try:
                    (path.parent / target).resolve(strict=True).relative_to(root)
                except (OSError, RuntimeError, ValueError) as exc:
                    raise TrueIOSPlatformError(
                        f"dangling or escaping symlink at {relative}: {target}"
                    ) from exc
                links[relative] = target
            elif stat.S_ISDIR(metadata.st_mode):
                pending.append(path)
            elif stat.S_ISREG(metadata.st_mode):
                regular.add(relative)
            else:
                raise TrueIOSPlatformError(f"unsupported package node: {relative}")
    return regular, links


def _completion(root: Path) -> dict[str, str]:
    marker = _regular(root, "PLATFORM_COMPLETE", "completion marker")
    try:
        payload = marker.read_text(encoding="ascii")
    except (OSError, UnicodeDecodeError) as exc:
        raise TrueIOSPlatformError(f"cannot read completion marker: {exc}") from exc
    if not payload.endswith("\n") or "\n" in payload[:-1]:
        raise TrueIOSPlatformError("completion marker must contain exactly one line")
    tokens = payload[:-1].split(" ")
    if not tokens or tokens[0] != "TRUE_IOS_PLATFORM_COMPLETE":
        raise TrueIOSPlatformError("unexpected completion marker")
    values: dict[str, str] = {}
    for token in tokens[1:]:
        if token.count("=") != 1:
            raise TrueIOSPlatformError(f"malformed completion token: {token!r}")
        key, value = token.split("=", 1)
        if not key or not value or key in values:
            raise TrueIOSPlatformError(f"duplicate or empty completion token: {token!r}")
        values[key] = value
    expected_keys = {"target", "dylibs", "swiftui_sources", "source", "artifacts", "symlinks"}
    if set(values) != expected_keys:
        raise TrueIOSPlatformError(
            f"completion keys differ: missing={sorted(expected_keys - set(values))} "
            f"extra={sorted(set(values) - expected_keys)}"
        )
    if values["target"] != _TARGET or values["dylibs"] != str(
        len(_MODULES) + len(_PRIVATE_DYLIBS) + len(_RUNTIME_SWIFT_MODULES)
    ):
        raise TrueIOSPlatformError("completion target or dylib denominator drifted")
    try:
        swiftui_sources = int(values["swiftui_sources"])
    except ValueError as exc:
        raise TrueIOSPlatformError("swiftui_sources is not an integer") from exc
    if swiftui_sources < 6:
        raise TrueIOSPlatformError("SwiftUI source denominator fell below six")
    for key in ("source", "artifacts", "symlinks"):
        if not _SHA256.fullmatch(values[key]):
            raise TrueIOSPlatformError(f"completion {key} is not lowercase SHA-256")
    return values


def _artifact_ledger(root: Path, expected_sha: str) -> dict[str, str]:
    ledger = _regular(root, "attestation/artifacts.sha256", "artifact ledger")
    if _sha256(ledger) != expected_sha:
        raise TrueIOSPlatformError("artifact ledger hash differs from completion marker")
    records: dict[str, str] = {}
    try:
        lines = ledger.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as exc:
        raise TrueIOSPlatformError(f"cannot read artifact ledger: {exc}") from exc
    if not lines:
        raise TrueIOSPlatformError("artifact ledger is empty")
    for index, line in enumerate(lines, 1):
        fields = line.split("\t")
        if len(fields) != 2 or not _SHA256.fullmatch(fields[0]):
            raise TrueIOSPlatformError(f"malformed artifact ledger line {index}")
        relative = _relative(fields[1], f"artifact ledger path {index}").as_posix()
        if relative in records:
            raise TrueIOSPlatformError(f"duplicate artifact ledger path: {relative}")
        physical = _regular(root, relative, f"artifact ledger path {index}")
        actual = _sha256(physical)
        if actual != fields[0]:
            raise TrueIOSPlatformError(f"artifact changed: {relative}")
        records[relative] = actual
    return records


def _symlink_ledger(root: Path, expected_sha: str) -> dict[str, str]:
    ledger = _regular(root, "attestation/symlinks.tsv", "symlink ledger")
    if _sha256(ledger) != expected_sha:
        raise TrueIOSPlatformError("symlink ledger hash differs from completion marker")
    records: dict[str, str] = {}
    try:
        lines = ledger.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as exc:
        raise TrueIOSPlatformError(f"cannot read symlink ledger: {exc}") from exc
    for index, line in enumerate(lines, 1):
        fields = line.split("\t")
        if len(fields) != 3 or not _SHA256.fullmatch(fields[0]):
            raise TrueIOSPlatformError(f"malformed symlink ledger line {index}")
        relative = _relative(fields[1], f"symlink ledger path {index}").as_posix()
        target = fields[2]
        if relative in records or _sha256_bytes(target.encode("utf-8")) != fields[0]:
            raise TrueIOSPlatformError(f"duplicate or corrupt symlink record: {relative}")
        records[relative] = target
    return records


def _macho(path: Path, *, filetype: int, install_name: str | None) -> set[str]:
    try:
        payload = path.read_bytes()
    except OSError as exc:
        raise TrueIOSPlatformError(f"cannot read Mach-O {path}: {exc}") from exc
    if len(payload) < 32:
        raise TrueIOSPlatformError(f"truncated Mach-O: {path}")
    magic, cpu, _subtype, actual_type, ncmds, sizeofcmds, _flags, _reserved = struct.unpack_from(
        "<IiiIIIII", payload, 0
    )
    if magic != 0xFEEDFACF or cpu != 0x0100000C or actual_type != filetype:
        raise TrueIOSPlatformError(f"Mach-O header identity drifted: {path}")
    if 32 + sizeofcmds > len(payload):
        raise TrueIOSPlatformError(f"Mach-O load commands are truncated: {path}")
    cursor = 32
    build_versions: list[tuple[int, int, int]] = []
    ids: list[str] = []
    loads: set[str] = set()
    dylib_commands = {0x0C, 0x20, 0x80000018, 0x8000001F, 0x80000023}
    for _ in range(ncmds):
        if cursor + 8 > 32 + sizeofcmds:
            raise TrueIOSPlatformError(f"Mach-O command header is truncated: {path}")
        command, size = struct.unpack_from("<II", payload, cursor)
        if size < 8 or cursor + size > 32 + sizeofcmds:
            raise TrueIOSPlatformError(f"invalid Mach-O command size: {path}")
        if command == 0x32:
            if size < 24:
                raise TrueIOSPlatformError(f"short LC_BUILD_VERSION: {path}")
            platform, minimum, sdk = struct.unpack_from("<III", payload, cursor + 8)
            build_versions.append((platform, minimum, sdk))
        if command == 0x0D or command in dylib_commands:
            if size < 24:
                raise TrueIOSPlatformError(f"short dylib command: {path}")
            name_offset = struct.unpack_from("<I", payload, cursor + 8)[0]
            if name_offset < 24 or name_offset >= size:
                raise TrueIOSPlatformError(f"invalid dylib name offset: {path}")
            raw = payload[cursor + name_offset : cursor + size].split(b"\0", 1)[0]
            try:
                name = raw.decode("utf-8")
            except UnicodeDecodeError as exc:
                raise TrueIOSPlatformError(f"non-UTF-8 dylib name: {path}") from exc
            if command == 0x0D:
                ids.append(name)
            else:
                loads.add(name)
        cursor += size
    if cursor != 32 + sizeofcmds or len(build_versions) != 1:
        raise TrueIOSPlatformError(f"Mach-O load-command denominator drifted: {path}")
    if build_versions[0] != (_PLATFORM, _MINIMUM_OS, _SDK_VERSION):
        raise TrueIOSPlatformError(f"Mach-O platform/minOS/SDK drifted: {path}")
    expected_ids = [] if install_name is None else [install_name]
    if ids != expected_ids:
        raise TrueIOSPlatformError(f"Mach-O install name drifted: {path}: {ids}")
    return loads


def _same_hash(paths: list[Path], label: str) -> None:
    values = {_sha256(path) for path in paths}
    if len(values) != 1:
        raise TrueIOSPlatformError(f"published copies differ: {label}")


def _validate_sdk_inputs(root: Path) -> None:
    marker = _regular(root, "sdk-provenance/SDK_COMPLETE", "SDK provenance marker")
    if marker.read_text(encoding="ascii") != (
        "TRUE_IOS_FULL_SDK_COMPLETE target=arm64-apple-ios18.0-simulator "
        "apple-overlays=darwin,objectivec\n"
    ):
        raise TrueIOSPlatformError("SDK provenance marker drifted")
    inputs = _regular(
        root, "sdk-provenance/target-sdk-inputs.sha256", "SDK input ledger"
    )
    seen: set[str] = set()
    for index, line in enumerate(inputs.read_text(encoding="utf-8").splitlines(), 1):
        fields = line.split("  ", 1)
        if len(fields) != 2 or not _SHA256.fullmatch(fields[0]):
            raise TrueIOSPlatformError(f"malformed SDK input line {index}")
        relative = _relative(fields[1], f"SDK input path {index}").as_posix()
        if relative in seen or _sha256(_regular(root, relative, "SDK input")) != fields[0]:
            raise TrueIOSPlatformError(f"SDK input changed or duplicated: {relative}")
        seen.add(relative)
    if not seen:
        raise TrueIOSPlatformError("SDK input ledger is empty")


def _validate_compiler_plugins(root: Path) -> None:
    manifest = _regular(
        root, "attestation/compiler-plugins.tsv", "compiler plugin manifest"
    )
    lines = manifest.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "format\ttrue-ios-compiler-plugins-v1":
        raise TrueIOSPlatformError("compiler plugin manifest format drifted")
    records: dict[str, tuple[str, str]] = {}
    for index, line in enumerate(lines[1:], 2):
        fields = line.split("\t")
        if len(fields) != 4 or fields[0] != "plugin":
            raise TrueIOSPlatformError(f"malformed compiler plugin line {index}")
        module, relative, digest = fields[1:]
        if module in records or not _SHA256.fullmatch(digest):
            raise TrueIOSPlatformError(f"duplicate or invalid compiler plugin line {index}")
        plugin = _regular(root, relative, f"{module} compiler plugin")
        if plugin.name != f"lib{module}.so" or _sha256(plugin) != digest:
            raise TrueIOSPlatformError(f"compiler plugin identity drifted: {module}")
        header = plugin.read_bytes()[:20]
        if (
            len(header) < 20
            or header[:6] != b"\x7fELF\x02\x01"
            or struct.unpack_from("<H", header, 18)[0] != 183
        ):
            raise TrueIOSPlatformError(f"compiler plugin is not ELF64/AArch64: {module}")
        records[module] = (relative, digest)
    if set(records) != set(_COMPILER_PLUGINS):
        raise TrueIOSPlatformError("compiler plugin module set differs")

    host = root / "host-tools/swift/host"
    linux = root / "host-tools/swift/linux"
    plugin_directory = host / "plugins"
    if {path.name for path in plugin_directory.iterdir()} != {
        f"lib{module}.so" for module in _COMPILER_PLUGINS
    }:
        raise TrueIOSPlatformError("compiler plugin library set differs")
    if {path.name for path in host.iterdir()} != _PLUGIN_HOST_LIBRARIES | {"plugins"}:
        raise TrueIOSPlatformError("compiler plugin host closure differs")
    if {path.name for path in linux.iterdir()} != _PLUGIN_LINUX_LIBRARIES:
        raise TrueIOSPlatformError("compiler plugin Linux closure differs")
    for name in _PLUGIN_HOST_LIBRARIES:
        _regular(root, f"host-tools/swift/host/{name}", "plugin host dependency")
    for name in _PLUGIN_LINUX_LIBRARIES:
        _regular(root, f"host-tools/swift/linux/{name}", "plugin Linux dependency")


def _symbol_attestation(root: Path, relative: str, label: str) -> set[str]:
    path = _regular(root, relative, label)
    lines = path.read_text(encoding="utf-8").splitlines()
    if any(not line or line.strip() != line or "\t" in line for line in lines):
        raise TrueIOSPlatformError(f"malformed {label}")
    if lines != sorted(set(lines)):
        raise TrueIOSPlatformError(f"{label} is not sorted and unique")
    return set(lines)


def _validate_foundation_runtime_bridge(root: Path) -> None:
    exports = _symbol_attestation(
        root,
        "attestation/foundation-runtime-exports.txt",
        "Foundation runtime export attestation",
    )
    missing = sorted(_REQUIRED_FOUNDATION_RUNTIME_EXPORTS - exports)
    if missing:
        raise TrueIOSPlatformError(
            f"Foundation runtime bridge exports are missing: {missing}"
        )
    undefineds = _symbol_attestation(
        root,
        "attestation/foundation-runtime-undefineds.txt",
        "Foundation runtime undefined-symbol attestation",
    )
    forbidden = sorted(_FORBIDDEN_FOUNDATION_CFERROR_IMPORTS & undefineds)
    if forbidden:
        raise TrueIOSPlatformError(
            f"Foundation CFError bridge imports absent C APIs: {forbidden}"
        )


def _compile_arguments() -> list[str]:
    include = "platform-include"
    return [
        "-target", _TARGET,
        "-sdk", "sdk",
        "-I", "apple-overlays",
        "-F", "sdk/System/Library/Frameworks",
        "-runtime-compatibility-version", "none",
        "-Xfrontend", "-enable-cross-import-overlays",
        "-Xfrontend", "-disable-objc-attr-requires-foundation-module",
        "-load-plugin-library", "host-tools/swift/host/plugins/libObservationMacros.so",
        "-load-plugin-library", "host-tools/swift/host/plugins/libFoundationMacros.so",
        "-load-plugin-library", "host-tools/swift/host/plugins/libSwiftDataMacros.so",
        "-load-plugin-library", "host-tools/swift/host/plugins/libOpenUIKitPreviewMacros.so",
        "-load-plugin-library", "host-tools/swift/host/plugins/libOpenSwiftUIMacros.so",
        "-Xcc", f"-I{include}/CPortableIO",
        "-Xcc", f"-I{include}/CSTBTrueType",
        "-Xcc", f"-I{include}/CHostClock",
        "-Xcc", f"-I{include}/COpenCombineHelpers",
        "-Xcc", f"-fmodule-map-file={include}/COpenAccelerate/module.modulemap",
        "-Xcc", f"-I{include}/COpenAccelerate",
        "-Xcc", f"-fmodule-map-file={include}/COpenCompression/module.modulemap",
        "-Xcc", f"-I{include}/COpenCompression",
        "-Xcc", f"-I{include}/CQuartz",
        "-Xcc", f"-fmodule-map-file={include}/COpenDispatch/module.modulemap",
        "-Xcc", f"-I{include}/COpenDispatch",
        "-Xcc", f"-fmodule-map-file={include}/COpenFoundationCore/module.modulemap",
        "-Xcc", f"-I{include}/COpenFoundationCore",
        "-Xcc", f"-fmodule-map-file={include}/COpenRelativeTime/module.modulemap",
        "-Xcc", f"-I{include}/COpenRelativeTime",
        "-Xcc", f"-fmodule-map-file={include}/COpenURLTransport/module.modulemap",
        "-Xcc", f"-I{include}/COpenURLTransport",
        "-Xcc", f"-fmodule-map-file={include}/FoundationICU/_foundation_unicode/module.modulemap",
        "-Xcc", f"-I{include}/FoundationICU",
        "-Xcc", f"-fmodule-map-file={include}/_FoundationCShims/module.modulemap",
        "-Xcc", f"-I{include}/_FoundationCShims",
    ]


def _link_arguments() -> list[str]:
    return [
        "-arch", "arm64",
        "-platform_version", "ios-simulator", "18.0", "26.1",
        "-syslibroot", "sdk",
        "-F", "sdk/System/Library/Frameworks",
        "-framework", "SwiftUI",
        "-framework", "UIKit",
        "-framework", "NaturalLanguage",
        "-framework", "AuthenticationServices",
        "-framework", "_AuthenticationServices_SwiftUI",
        "-framework", "Accelerate",
        "-framework", "Compression",
        "-framework", "CoreText",
        "-Lproducts",
        "-lFoundation", "-lFoundationInternationalization", "-lDispatch",
        "-lOpenUIKit", "-lOpenCoreGraphics", "-lFoundationEssentials",
        "-lDeveloperToolsSupport", "-lCombine", "-lOpenCombine",
        "-lSymbols", "-l_FoundationICU",
        "-Lsdk/usr/lib/swift",
        "-Lruntime-root/darwin/usr/lib/swift",
        "-lswiftCore", "-lswiftObjectiveC", "-lswift_Concurrency",
        "-lswift_StringProcessing", "-lswiftSynchronization",
        "-lswiftDarwin", "-lswift_errno",
        "runtime-root/darwin/usr/lib/libswiftcompat.dylib",
        "runtime-root/darwin/usr/lib/swift/libswiftObservation.dylib",
        "-Lruntime-root/darwin/usr/lib",
        "-Lsdk/usr/lib", "-lSystem", "-lobjc",
        "runtime-root/darwin/usr/lib/libquartz.dylib",
        "runtime-root/darwin/usr/lib/libSystem.B.dylib",
    ]


def rooted_compile_arguments(root: Path, values: list[str]) -> list[str]:
    result: list[str] = []
    cursor = 0
    path_options = {"-sdk", "-I", "-F", "-load-plugin-library"}
    attached = ("-I", "-F", "-fmodule-map-file=")
    while cursor < len(values):
        token = values[cursor]
        if token in path_options:
            if cursor + 1 >= len(values):
                raise TrueIOSPlatformError(f"compile arguments end after {token}")
            result.extend((token, os.fspath(root / _relative(values[cursor + 1], token))))
            cursor += 2
            continue
        if token == "-Xcc" and cursor + 1 < len(values):
            payload = values[cursor + 1]
            rooted = payload
            for prefix in attached:
                if payload.startswith(prefix) and len(payload) > len(prefix):
                    rooted = prefix + os.fspath(root / _relative(payload[len(prefix) :], "-Xcc path"))
                    break
            result.extend((token, rooted))
            cursor += 2
            continue
        result.append(token)
        cursor += 1
    return result


def validate(package_root: Path) -> tuple[Path, dict[str, Any]]:
    root = _strict_root(package_root)
    if {entry.name for entry in os.scandir(root)} != _ROOT_ENTRIES:
        raise TrueIOSPlatformError("package root entries differ from the release contract")
    completion = _completion(root)
    artifacts = _artifact_ledger(root, completion["artifacts"])
    published_links = _symlink_ledger(root, completion["symlinks"])
    regular, actual_links = _walk_nodes(root)
    if set(artifacts) != regular - _UNLEDGERED_REGULAR:
        missing = sorted((regular - _UNLEDGERED_REGULAR) - set(artifacts))
        extra = sorted(set(artifacts) - (regular - _UNLEDGERED_REGULAR))
        raise TrueIOSPlatformError(
            f"artifact ledger coverage differs: missing={missing} extra={extra}"
        )
    if published_links != actual_links:
        raise TrueIOSPlatformError("symlink ledger coverage or targets differ")

    attestation_names = {
        path.name for path in (root / "attestation").iterdir() if path.is_file()
    }
    if attestation_names != _REQUIRED_ATTESTATION:
        raise TrueIOSPlatformError("attestation file set differs")
    before = _regular(
        root, "attestation/source-subject.before.sha256", "source subject before"
    ).read_text(encoding="ascii").strip()
    after = _regular(
        root, "attestation/source-subject.after.sha256", "source subject after"
    ).read_text(encoding="ascii").strip()
    if before != completion["source"] or after != before:
        raise TrueIOSPlatformError("source subject bracket differs from completion")
    runtime_log = _regular(root, "attestation/runtime.log", "runtime log").read_text(
        encoding="utf-8"
    )
    if "TRUE_IOS_SWIFTUI_DYLIB_RUNTIME_OK descendants=" not in runtime_log:
        raise TrueIOSPlatformError("cold SwiftUI runtime marker is missing")
    load_attestation = _regular(
        root,
        "attestation/naturallanguage-authenticationservices-loads.tsv",
        "NaturalLanguage/AuthenticationServices load attestation",
    ).read_text(encoding="ascii")
    expected_load_attestation = (
        "format\ttrue-ios-natural-auth-loads-v1\n"
        "probe\tnaturallanguage=1\tauthenticationservices=1\toverlay=1\n"
        "overlay\tbase=1\tswiftui=1\tapple-self-load=0\n"
    )
    if load_attestation != expected_load_attestation:
        raise TrueIOSPlatformError(
            "NaturalLanguage/AuthenticationServices load attestation differs"
        )
    frontier_loads = _regular(
        root,
        "attestation/accelerate-compression-coretext-loads.tsv",
        "Accelerate/Compression/CoreText load attestation",
    ).read_text(encoding="ascii")
    if frontier_loads != (
        "format\ttrue-ios-accelerate-compression-coretext-loads-v1\n"
        "probe\taccelerate=1\tcompression=1\tcoretext=1\n"
        "accelerate\tvimage-export=1\tapple-self-load=0\n"
        "compression\tc-exports=2\thost-imports=2\tbrotli-load=0\tapple-self-load=0\n"
        "coretext\tapple-self-load=0\n"
    ):
        raise TrueIOSPlatformError(
            "Accelerate/Compression/CoreText load attestation differs"
        )
    transcript_hashes = {
        "accelerate-apple-differential.log":
            "c2ad6d611001db3d79cb1d39890e36ac8f2fe5ed4fe23bfda40e1aeb4376fbd0",
        "compression-brotli-apple.txt":
            "c3c7826b4bf603fcd4ec3f2ca9ae97906409789e352af48f926bf1acce6c9b65",
        "coretext-font-manager-apple.txt":
            "c38a8b9dfbe6d5220a2da12a6874a74e37e0570e52b71141c7529dc229df30fa",
    }
    for name, digest in transcript_hashes.items():
        if _sha256(_regular(root, f"attestation/{name}", name)) != digest:
            raise TrueIOSPlatformError(f"frozen Apple transcript differs: {name}")
    host_test = _regular(
        root,
        "attestation/open-compression-host-test.log",
        "Compression host test",
    ).read_text(encoding="ascii")
    if host_test != (
        "OPEN_COMPRESSION_HOST_OK algorithm=brotli roundtrip=exact "
        "malformed=fail-closed limit=hard abi=v1\n"
    ):
        raise TrueIOSPlatformError("Compression host test attestation differs")
    compression_abi = _regular(
        root,
        "attestation/open-compression-abi.tsv",
        "Compression ABI attestation",
    ).read_text(encoding="ascii")
    if compression_abi != (
        "format\topen-compression-abi-v1\n"
        "response-layout\tsize=24\tpointers=64-bit\n"
        "symbol\topenui_compression_v1_transform\t"
        "guest-export=_openui_compression_v1_transform\t"
        "guest-host-import=_glibc_openui_compression_v1_transform\t"
        "host-export=openui_compression_v1_transform\n"
        "symbol\topenui_compression_v1_release\t"
        "guest-export=_openui_compression_v1_release\t"
        "guest-host-import=_glibc_openui_compression_v1_release\t"
        "host-export=openui_compression_v1_release\n"
    ):
        raise TrueIOSPlatformError("Compression ABI attestation differs")
    compression_host = _regular(
        root,
        "attestation/open-compression-host.tsv",
        "Compression host attestation",
    ).read_text(encoding="ascii").splitlines()
    required_host_lines = {
        "format\topen-compression-host-v1",
        "host-abi\tELF64-AArch64",
        "algorithm\tbrotli\tencode=real\tdecode=real",
        "limits\tguest-input=256MiB\tguest-output=256MiB",
        "apple-transcript\t"
        "c3c7826b4bf603fcd4ec3f2ca9ae97906409789e352af48f926bf1acce6c9b65",
        "transitive-soname\tlibbrotlidec.so.1",
        "transitive-soname\tlibbrotlienc.so.1",
        "transitive-soname\tlibbrotlicommon.so.1",
    }
    if not required_host_lines.issubset(compression_host):
        raise TrueIOSPlatformError("Compression host attestation is incomplete")
    module_log = _regular(
        root, "attestation/framework-module-loading.log", "module loading log"
    ).read_text(encoding="utf-8")
    for module in (
        "SwiftUI", "UIKit", "OpenUIKit", "Combine", "OpenCombine",
        "NaturalLanguage", "AuthenticationServices",
        "_AuthenticationServices_SwiftUI", "Accelerate", "Compression",
        "CoreText",
    ):
        if f"loaded module '{module}'; source:" not in module_log or (
            f"/System/Library/Frameworks/{module}.framework/Modules/" not in module_log
        ):
            raise TrueIOSPlatformError(f"framework module evidence is missing: {module}")

    _validate_sdk_inputs(root)
    _validate_compiler_plugins(root)
    _validate_foundation_runtime_bridge(root)
    if (root / "sdk/usr/local").exists() or (root / "sdk/usr/local").is_symlink():
        raise TrueIOSPlatformError("SDK contains forbidden implicit usr/local inputs")
    overlay_directories = {
        path.name.removesuffix(".swiftmodule")
        for path in (root / "apple-overlays").iterdir()
        if path.is_dir()
    }
    if overlay_directories != set(_OVERLAYS):
        raise TrueIOSPlatformError("Apple overlay module set differs")
    for module in _REQUIRED_CLANG_MODULES:
        _regular(
            root,
            f"platform-include/{module}/module.modulemap",
            f"{module} module map",
        )
    _regular(
        root,
        "platform-include/COpenFoundationCore/OpenFoundationCFError.h",
        "Foundation CFError opaque header",
    )
    _regular(
        root,
        "platform-include/COpenAccelerate/Accelerate.h",
        "Accelerate C header",
    )
    _regular(
        root,
        "platform-include/COpenCompression/OpenCompressionABI.h",
        "Compression ABI header",
    )
    _regular(
        root,
        "platform-include/FoundationICU/_foundation_unicode/module.modulemap",
        "Foundation ICU module map",
    )
    for relative in _REQUIRED_SDK_FILES:
        _regular(root, relative, "SDK link input")
    if {path.name for path in (root / "resources").iterdir()} != {"OpenUIKit"}:
        raise TrueIOSPlatformError("platform resource roots differ")
    for relative in _REQUIRED_RESOURCE_FILES:
        _regular(root, relative, "OpenUIKit platform resource")
    for relative, target in {
        "sdk/usr/lib/libSystem.tbd": "libSystem.B.tbd",
        "sdk/usr/lib/libobjc.tbd": "libobjc.A.tbd",
    }.items():
        if actual_links.get(relative) != target:
            raise TrueIOSPlatformError(f"SDK linker alias drifted: {relative}")

    expected_products = {
        f"lib{module}.dylib" for module in _MODULES + _PRIVATE_DYLIBS
    }
    if {path.name for path in (root / "products").iterdir()} != expected_products:
        raise TrueIOSPlatformError("product dylib set differs")
    frameworks = root / "sdk/System/Library/Frameworks"
    expected_frameworks = {f"{module}.framework" for module in _MODULES}
    if {path.name for path in frameworks.iterdir()} != expected_frameworks:
        raise TrueIOSPlatformError("public framework set differs")
    for module in _MODULES:
        product = _regular(root, f"products/lib{module}.dylib", f"lib{module} product")
        sdk_binary = _regular(
            root,
            f"sdk/System/Library/Frameworks/{module}.framework/{module}",
            f"{module} framework binary",
        )
        runtime_library = _regular(
            root, f"runtime-root/darwin/usr/lib/lib{module}.dylib", f"runtime lib{module}"
        )
        runtime_framework = _regular(
            root,
            f"runtime-root/darwin/System/Library/Frameworks/{module}.framework/{module}",
            f"runtime {module} framework binary",
        )
        _same_hash(
            [product, sdk_binary, runtime_library, runtime_framework], f"lib{module}"
        )
        _macho(product, filetype=6, install_name=f"/usr/lib/lib{module}.dylib")
        for suffix in _MODULE_SUFFIXES:
            raw = _regular(root, f"package/{module}.{suffix}", f"{module}.{suffix}")
            sdk_module = _regular(
                root,
                f"sdk/System/Library/Frameworks/{module}.framework/Modules/"
                f"{module}.swiftmodule/{_VARIANT}.{suffix}",
                f"SDK {module}.{suffix}",
            )
            runtime_module = _regular(
                root,
                f"runtime-root/darwin/System/Library/Frameworks/{module}.framework/Modules/"
                f"{module}.swiftmodule/{_VARIANT}.{suffix}",
                f"runtime {module}.{suffix}",
            )
            _same_hash([raw, sdk_module, runtime_module], f"{module}.{suffix}")

    overlay_relative = (
        "AuthenticationServices.framework/Modules/"
        "AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay"
    )
    overlay_source = _regular(
        root,
        "package/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay",
        "AuthenticationServices cross-import overlay",
    )
    overlay_sdk = _regular(
        root,
        f"sdk/System/Library/Frameworks/{overlay_relative}",
        "SDK AuthenticationServices cross-import overlay",
    )
    overlay_runtime = _regular(
        root,
        f"runtime-root/darwin/System/Library/Frameworks/{overlay_relative}",
        "runtime AuthenticationServices cross-import overlay",
    )
    _same_hash(
        [overlay_source, overlay_sdk, overlay_runtime],
        "AuthenticationServices cross-import overlay",
    )

    for module in _PRIVATE_DYLIBS:
        product = _regular(root, f"products/lib{module}.dylib", f"lib{module} product")
        runtime_library = _regular(
            root, f"runtime-root/darwin/usr/lib/lib{module}.dylib", f"runtime lib{module}"
        )
        _same_hash([product, runtime_library], f"lib{module}")
        _macho(product, filetype=6, install_name=f"/usr/lib/lib{module}.dylib")

    for module in _RUNTIME_SWIFT_MODULES:
        for suffix in _MODULE_SUFFIXES:
            raw = _regular(root, f"package/{module}.{suffix}", f"{module}.{suffix}")
            sdk_module = _regular(
                root,
                f"sdk/usr/lib/swift/{module}.swiftmodule/{_VARIANT}.{suffix}",
                f"SDK runtime module {module}.{suffix}",
            )
            _same_hash([raw, sdk_module], f"runtime module {module}.{suffix}")
    observation = _regular(
        root,
        "runtime-root/darwin/usr/lib/swift/libswiftObservation.dylib",
        "Observation runtime",
    )
    _macho(
        observation,
        filetype=6,
        install_name="/usr/lib/swift/libswiftObservation.dylib",
    )

    for relative in _REQUIRED_RUNTIME_FILES:
        _regular(root, relative, "runtime closure file")
    host_names = {path.name for path in (root / "runtime-root/host").iterdir()}
    if host_names != _REQUIRED_HOST_LIBRARIES:
        raise TrueIOSPlatformError("host runtime library set differs")
    loader = _regular(root, "runtime-root/machorun", "machorun")
    if not loader.stat().st_mode & stat.S_IXUSR:
        raise TrueIOSPlatformError("machorun is not executable")

    probe = _regular(root, "true-ios-swiftui-dylib-probe", "SwiftUI probe")
    loads = _macho(probe, filetype=2, install_name=None)
    for required in (
        "/usr/lib/libSwiftUI.dylib",
        "/usr/lib/libUIKit.dylib",
        "/usr/lib/libNaturalLanguage.dylib",
        "/usr/lib/libAuthenticationServices.dylib",
        "/usr/lib/lib_AuthenticationServices_SwiftUI.dylib",
        "/usr/lib/libAccelerate.dylib",
        "/usr/lib/libCompression.dylib",
        "/usr/lib/libCoreText.dylib",
    ):
        if required not in loads:
            raise TrueIOSPlatformError(f"probe does not load {required}")

    metadata: dict[str, Any] = {
        "target": _TARGET,
        "modules": list(_MODULES),
        "artifact_count": len(artifacts),
        "symlink_count": len(actual_links),
        "swift_compile_arguments": _compile_arguments(),
        "executable_link_arguments": _link_arguments(),
        "paths": {
            "sdk": "sdk",
            "frameworks": "sdk/System/Library/Frameworks",
            "libraries": "products",
            "host_tools": "host-tools",
            "resources": "resources/OpenUIKit",
            "runtime_root": "runtime-root",
        },
    }
    return root, metadata


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package_root", type=Path)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--emit-swift-arguments", action="store_true")
    group.add_argument("--emit-link-arguments", action="store_true")
    group.add_argument("--emit-summary", action="store_true")
    parser.add_argument("--absolute-package-paths", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _parser()
    arguments = parser.parse_args(argv)
    if arguments.absolute_package_paths and not arguments.emit_swift_arguments:
        parser.error("--absolute-package-paths requires --emit-swift-arguments")
    try:
        root, metadata = validate(arguments.package_root)
        if arguments.emit_swift_arguments:
            values = metadata["swift_compile_arguments"]
            if arguments.absolute_package_paths:
                values = rooted_compile_arguments(root, values)
            sys.stdout.buffer.write(
                b"".join(value.encode("utf-8") + b"\0" for value in values)
            )
        elif arguments.emit_link_arguments:
            sys.stdout.buffer.write(
                b"".join(
                    value.encode("utf-8") + b"\0"
                    for value in metadata["executable_link_arguments"]
                )
            )
        else:
            print(
                "TRUE_IOS_PLATFORM_PACKAGE_OK "
                f"target={metadata['target']} "
                f"dylibs={len(metadata['modules'])} "
                f"artifacts={metadata['artifact_count']} "
                f"symlinks={metadata['symlink_count']} root={root}"
            )
    except (OSError, TrueIOSPlatformError, UnicodeError, struct.error) as exc:
        print(f"true-ios-platform-package: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
