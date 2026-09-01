#!/usr/bin/env python3
"""Fail-closed manifests for the relocatable core Mach-O guest package."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import stat
import sys
from typing import Iterable


CLASSIFICATION = "open-uikit-core-guest-package"
FORMAT_VERSION = 1
PREVIEW_SWIFTSYNTAX_REVISION = "4799286537280063c85a32f09884cfbca301b1a1"
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
    "full/foundation/ByteCountFormatter.swift",
    "full/foundation/UserDefaults.swift",
    "full/foundation/UbiquitousKeyValueStore.swift",
    "full/foundation/RelativeDateTimeFormatter.swift",
    "full/foundation/FileManager+Enumeration.swift",
)
PATHS = {
    "sdk": "sdk",
    "modules": "modules",
    "libraries": "lib",
    "includes": "include",
    "objects": "objects",
    "resources": "resources/OpenUIKit",
    "guest_root": "guest-root",
    "host_tools": "host-tools",
}
REQUIRED_DIRECTORIES = tuple(PATHS.values()) + ("probe", "attestation")
REQUIRED_MANIFESTS = {
    "artifact_ledger",
    "input_provenance",
    "source_sets",
    "foundation_sources",
    "intents_sources",
    "graphics_sources",
    "first_party_sources",
    "first_party_dylib_loads",
    "webkit_sources",
    "sdk_tree",
    "sdk_dangling_symlinks",
    "sdk_dangling_exclusions",
    "include_tree",
    "guest_root_tree",
    "openuikit_resources_tree",
    "runtime_closure",
    "compiler_plugins",
}
REQUIRED_COMPILER_PLUGIN_MODULES = {
    "ObservationMacros",
    "FoundationMacros",
    "SwiftDataMacros",
    "OpenUIKitPreviewMacros",
    "OpenSwiftUIMacros",
}
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
)
REQUIRED_FRAMEWORK_LINK_ARGUMENTS = tuple(f"-l{name}" for name in FRAMEWORKS)
MODULE_DEPENDENCIES = (
    "InternalCollectionsUtilities",
    "OrderedCollections",
    "_RopeModule",
    "os",
)
ARTIFACT_CATEGORIES = {
    "framework",
    "module-dependency",
    "include",
    "object",
    "runtime",
    "host-tool",
    "resource",
    "probe",
    "attestation",
    "sdk",
}


class Refusal(RuntimeError):
    pass


def refuse(message: str) -> None:
    raise Refusal(message)


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_relative(raw: str, what: str = "package path") -> str:
    if not raw or "\\" in raw or any(ch in raw for ch in "\x00\r\n\t"):
        refuse(f"unsafe {what}: {raw!r}")
    path = PurePosixPath(raw)
    if path.is_absolute() or path.as_posix() != raw:
        refuse(f"non-normalized {what}: {raw!r}")
    if any(part in ("", ".", "..") for part in path.parts):
        refuse(f"traversing {what}: {raw!r}")
    return raw


def require_directory_no_link(path: Path, what: str) -> None:
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        refuse(f"missing {what}: {path}")
    if stat.S_ISLNK(mode):
        refuse(f"{what} is a symlink: {path}")
    if not stat.S_ISDIR(mode):
        refuse(f"{what} is not a directory: {path}")


def require_regular_no_link(path: Path, what: str) -> None:
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        refuse(f"missing {what}: {path}")
    if stat.S_ISLNK(mode):
        refuse(f"{what} is a symlink: {path}")
    if not stat.S_ISREG(mode):
        refuse(f"{what} is not a regular file: {path}")


def require_regular_beneath(root: Path, relative: str, what: str) -> Path:
    require_directory_no_link(root, f"{what} root")
    safe_relative(relative, f"{what} relative path")
    cursor = root
    for index, component in enumerate(PurePosixPath(relative).parts):
        cursor = cursor / component
        try:
            mode = cursor.lstat().st_mode
        except FileNotFoundError:
            refuse(f"missing {what} path component: {cursor}")
        if stat.S_ISLNK(mode):
            refuse(f"{what} path component is a symlink: {cursor}")
        if index == len(PurePosixPath(relative).parts) - 1:
            if not stat.S_ISREG(mode):
                refuse(f"{what} is not a regular file: {cursor}")
        elif not stat.S_ISDIR(mode):
            refuse(f"{what} ancestor is not a directory: {cursor}")
    return cursor


def write_text_new(path: Path, text: str) -> None:
    if path.exists() or path.is_symlink():
        refuse(f"refusing to overwrite output: {path}")
    require_directory_no_link(path.parent, "output parent")
    path.write_text(text, encoding="utf-8", newline="\n")


def validate_foundation_sources(
    support_root: Path, manifest: Path
) -> list[tuple[int, str, str]]:
    require_directory_no_link(support_root, "support root")
    require_regular_no_link(manifest, "Foundation source manifest")
    payload = manifest.read_bytes()
    if b"\r" in payload or b"\x00" in payload:
        refuse("Foundation source manifest must be UTF-8/LF text")
    if not payload.endswith(b"\n"):
        refuse("Foundation source manifest must end in one LF")
    try:
        text = payload.decode("utf-8")
    except UnicodeDecodeError as error:
        refuse(f"Foundation source manifest is not UTF-8: {error}")
    lines = text[:-1].split("\n")
    if tuple(lines) != FOUNDATION_SOURCES:
        refuse(
            "Foundation source manifest must contain the exact ordered "
            f"{len(FOUNDATION_SOURCES)}-path contract"
        )
    if len(set(lines)) != len(lines):
        refuse("Foundation source manifest contains a duplicate")
    records: list[tuple[int, str, str]] = []
    for index, relative in enumerate(lines, 1):
        safe_relative(relative, "Foundation source path")
        lowered = PurePosixPath(relative).name.lower()
        if "probe" in lowered or "test" in lowered:
            refuse(f"Foundation source manifest contains a probe/test: {relative}")
        path = require_regular_beneath(
            support_root, relative, f"Foundation source {index}"
        )
        records.append((index, relative, sha256_file(path)))
    return records


def foundation_command(args: argparse.Namespace) -> None:
    support_root = Path(args.support_root)
    manifest = Path(args.manifest)
    records = validate_foundation_sources(support_root, manifest)
    output = [
        "format\tfoundation-guest-sources-v1",
        f"manifest\t{sha256_file(manifest)}\tcount={len(records)}",
    ]
    output.extend(
        f"source\t{index}\t{relative}\t{digest}"
        for index, relative, digest in records
    )
    write_text_new(Path(args.output), "\n".join(output) + "\n")


def _relative_symlink_target(relative: PurePosixPath, target: str) -> str:
    if not target or "\x00" in target or "\r" in target or "\n" in target:
        refuse(f"unsafe symlink target at {relative}: {target!r}")
    if target.startswith("/"):
        refuse(f"absolute symlink target at {relative}: {target}")
    parts: list[str] = list(relative.parent.parts)
    for component in PurePosixPath(target).parts:
        if component in ("", "."):
            continue
        if component == "..":
            if not parts:
                refuse(f"escaping symlink target at {relative}: {target}")
            parts.pop()
        else:
            parts.append(component)
    if not parts:
        refuse(f"symlink resolves to inventory root at {relative}: {target}")
    return PurePosixPath(*parts).as_posix()


def read_dangling_exclusions(path: Path) -> dict[str, str]:
    require_regular_no_link(path, "SDK dangling-symlink exclusion manifest")
    payload = path.read_bytes()
    if b"\r" in payload or b"\x00" in payload or not payload.endswith(b"\n"):
        refuse("SDK dangling-symlink exclusion manifest must be UTF-8/LF text")
    try:
        lines = payload.decode("utf-8")[:-1].split("\n")
    except UnicodeDecodeError as error:
        refuse(f"SDK dangling-symlink exclusion manifest is not UTF-8: {error}")
    if not lines or lines[0] != "format\tsdk-dangling-symlink-exclusions-v1":
        refuse("SDK dangling-symlink exclusion manifest format drifted")
    records: list[tuple[str, str]] = []
    for index, line in enumerate(lines[1:], 1):
        fields = line.split("\t")
        if len(fields) != 3 or fields[0] != "symlink":
            refuse(f"malformed SDK dangling-symlink exclusion record {index}")
        relative = safe_relative(fields[1], "SDK dangling-symlink path")
        _relative_symlink_target(PurePosixPath(relative), fields[2])
        records.append((relative, fields[2]))
    if not records:
        refuse("SDK dangling-symlink exclusion manifest is empty")
    if records != sorted(records):
        refuse("SDK dangling-symlink exclusion manifest is not sorted")
    if len({relative for relative, _target in records}) != len(records):
        refuse("SDK dangling-symlink exclusion manifest contains a duplicate path")
    return dict(records)


def verified_dangling_symlinks(
    root: Path, exclusions: dict[str, str]
) -> dict[str, str]:
    require_directory_no_link(root, "SDK inventory root")
    observed: dict[str, str] = {}

    def visit(directory: Path, relative: PurePosixPath) -> None:
        for entry in sorted(os.scandir(directory), key=lambda item: item.name):
            child = PurePosixPath(entry.name) if relative.as_posix() == "." else relative / entry.name
            physical = Path(entry.path)
            mode = physical.lstat().st_mode
            key = child.as_posix()
            if stat.S_ISLNK(mode):
                target = os.readlink(physical)
                resolved = _relative_symlink_target(child, target)
                if not os.path.lexists(root / resolved):
                    observed[key] = target
                elif key in exclusions:
                    refuse(f"excluded SDK symlink is no longer dangling: {key} -> {target}")
                continue
            if key in exclusions:
                refuse(f"excluded SDK path is no longer a symlink: {key}")
            if stat.S_ISDIR(mode):
                visit(physical, child)
            elif not stat.S_ISREG(mode):
                refuse(f"unsupported node in SDK inventory: {key}")

    visit(root, PurePosixPath("."))
    missing = sorted(set(exclusions) - set(observed))
    unexpected = sorted(set(observed) - set(exclusions))
    drifted = sorted(
        relative
        for relative in set(observed) & set(exclusions)
        if observed[relative] != exclusions[relative]
    )
    if missing or unexpected or drifted:
        refuse(
            "SDK dangling-symlink set drifted: "
            f"missing={missing} unexpected={unexpected} target-drift={drifted}"
        )
    return observed


def inventory_records(
    root: Path,
    logical_root: str,
    reject_symlinks: bool,
    dangling_exclusions: dict[str, str] | None = None,
) -> list[tuple[str, ...]]:
    require_directory_no_link(root, "inventory root")
    safe_relative(logical_root, "inventory logical root")
    exclusions = dangling_exclusions or {}
    if exclusions:
        verified_dangling_symlinks(root, exclusions)
    records: list[tuple[str, ...]] = []

    def visit(physical: Path, relative: PurePosixPath) -> None:
        logical = (
            logical_root
            if relative.as_posix() == "."
            else f"{logical_root}/{relative.as_posix()}"
        )
        mode = physical.lstat().st_mode
        if stat.S_ISLNK(mode):
            target = os.readlink(physical)
            resolved = _relative_symlink_target(relative, target)
            if not os.path.lexists(root / resolved):
                if relative.as_posix() in exclusions:
                    return
                refuse(f"dangling symlink in inventory: {logical} -> {target}")
            if reject_symlinks:
                refuse(f"symlink is forbidden in {logical_root}: {logical}")
            records.append(
                ("symlink", logical, sha256_bytes(target.encode()), target)
            )
            return
        if stat.S_ISREG(mode):
            records.append(
                ("file", logical, sha256_file(physical), str(physical.stat().st_size))
            )
            return
        if not stat.S_ISDIR(mode):
            refuse(f"unsupported node in inventory: {logical}")
        entries = sorted(os.scandir(physical), key=lambda entry: entry.name)
        included = []
        for entry in entries:
            child = PurePosixPath(entry.name) if relative.as_posix() == "." else relative / entry.name
            if child.as_posix() not in exclusions:
                included.append(entry)
        records.append(("directory", logical, "empty=yes" if not included else "empty=no"))
        for entry in entries:
            child = PurePosixPath(entry.name) if relative.as_posix() == "." else relative / entry.name
            visit(Path(entry.path), child)

    visit(root, PurePosixPath("."))
    return records


def inventory_command(args: argparse.Namespace) -> None:
    exclusions = (
        read_dangling_exclusions(Path(args.dangling_exclusions))
        if args.dangling_exclusions
        else None
    )
    records = inventory_records(
        Path(args.root), args.logical_root, args.reject_symlinks, exclusions
    )
    output = ["format\tcore-tree-v1"]
    output.extend("\t".join(record) for record in records)
    write_text_new(Path(args.output), "\n".join(output) + "\n")


def dangling_symlinks_command(args: argparse.Namespace) -> None:
    root = Path(args.root)
    manifest = Path(args.exclusions)
    exclusions = read_dangling_exclusions(manifest)
    observed = verified_dangling_symlinks(root, exclusions)
    if args.remove:
        for relative in sorted(observed):
            path = root / relative
            path.unlink()
            if path.exists() or path.is_symlink():
                refuse(f"failed to remove verified SDK dangling symlink: {relative}")
    output = [
        "format\tsdk-dangling-symlinks-v1",
        f"exclusions\t{sha256_file(manifest)}\tcount={len(observed)}",
    ]
    output.extend(
        f"symlink\t{relative}\t{sha256_bytes(target.encode())}\t{target}"
        for relative, target in sorted(observed.items())
    )
    write_text_new(Path(args.output), "\n".join(output) + "\n")


def read_artifacts(package: Path, ledger: Path) -> list[dict[str, str]]:
    require_regular_no_link(ledger, "artifact ledger")
    lines = ledger.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "format\tcore-artifacts-v1":
        refuse("artifact ledger format is not core-artifacts-v1")
    artifacts: list[dict[str, str]] = []
    seen: set[str] = set()
    for number, line in enumerate(lines[1:], 2):
        fields = line.split("\t")
        if len(fields) != 6:
            refuse(f"artifact ledger line {number} does not have six fields")
        category, name, role, relative, expected, expected_size = fields
        if category not in ARTIFACT_CATEGORIES:
            refuse(f"unknown artifact category on line {number}: {category}")
        if not name or not role or any(ch.isspace() for ch in name + role):
            refuse(f"unsafe artifact name/role on line {number}")
        safe_relative(relative, "artifact path")
        if relative in seen:
            refuse(f"duplicate artifact path: {relative}")
        seen.add(relative)
        if len(expected) != 64 or any(ch not in "0123456789abcdef" for ch in expected):
            refuse(f"invalid artifact SHA-256 on line {number}")
        physical = require_regular_beneath(package, relative, "artifact")
        actual = sha256_file(physical)
        if actual != expected:
            refuse(f"artifact hash drifted for {relative}: {actual}")
        if not expected_size.isdecimal() or int(expected_size) != physical.stat().st_size:
            refuse(f"artifact size drifted for {relative}")
        artifacts.append(
            {
                "category": category,
                "name": name,
                "role": role,
                "path": relative,
                "sha256": expected,
                "size": int(expected_size),
            }
        )
    return artifacts


def read_nul_tokens(package: Path, relative: str, what: str) -> list[str]:
    safe_relative(relative, f"{what} path")
    path = require_regular_beneath(package, relative, what)
    payload = path.read_bytes()
    if not payload or not payload.endswith(b"\x00"):
        refuse(f"{what} must be nonempty and NUL-terminated")
    raw = payload[:-1].split(b"\x00")
    if any(not token for token in raw):
        refuse(f"{what} contains an empty token")
    try:
        tokens = [token.decode("utf-8") for token in raw]
    except UnicodeDecodeError as error:
        refuse(f"{what} is not UTF-8: {error}")
    if any("\x00" in token or "\r" in token or "\n" in token for token in tokens):
        refuse(f"{what} contains a control character")
    return tokens


def parse_key_value(path: Path, expected_format: str) -> dict[str, str]:
    require_regular_no_link(path, expected_format)
    values: dict[str, str] = {}
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != f"format\t{expected_format}":
        refuse(f"{path} does not use {expected_format}")
    for number, line in enumerate(lines[1:], 2):
        fields = line.split("\t", 1)
        if len(fields) != 2 or not fields[0] or not fields[1]:
            refuse(f"malformed {expected_format} line {number}")
        if fields[0] in values:
            refuse(f"duplicate {expected_format} key: {fields[0]}")
        values[fields[0]] = fields[1]
    return values


def checked_manifest(package: Path, relative: str, what: str) -> dict[str, str]:
    safe_relative(relative, f"{what} path")
    path = require_regular_beneath(package, relative, what)
    return {"path": relative, "sha256": sha256_file(path)}


def compiler_plugins_json(
    package: Path,
    artifacts: list[dict[str, str]],
    relative: str,
    compile_tokens: list[str],
) -> list[dict[str, object]]:
    """Parse and prove the relocatable, production compiler-plugin contract.

    Every packaged library plugin is declared once, carries its external-macro
    registrations and consumer scopes, and names a complete packaged native
    host closure.  Keeping this separate from Preview's externally supplied
    executable plugin lets package, framework, and app compiles share one
    ordinary `-load-plugin-library` transport.
    """
    path = require_regular_beneath(
        package, safe_relative(relative, "compiler-plugin manifest path"),
        "compiler-plugin manifest",
    )
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "format\tcore-compiler-plugins-v1":
        refuse("compiler-plugin manifest format drifted")
    plugin_rows: list[tuple[str, str, str, str, str, str, str]] = []
    closure_rows: dict[str, list[tuple[str, str]]] = {}
    saw_closure = False
    for number, line in enumerate(lines[1:], 2):
        fields = line.split("\t")
        if fields[0] == "plugin":
            if saw_closure or len(fields) != 8:
                refuse(f"malformed or unordered compiler-plugin row {number}")
            plugin_rows.append(tuple(fields[1:]))  # type: ignore[arg-type]
        elif fields[0] == "closure":
            saw_closure = True
            if len(fields) != 4:
                refuse(f"malformed compiler-plugin closure row {number}")
            closure_rows.setdefault(fields[1], []).append((fields[2], fields[3]))
        else:
            refuse(f"unknown compiler-plugin record on line {number}")
    if not plugin_rows:
        refuse("compiler-plugin manifest contains no plugins")

    artifact_by_path = {str(item["path"]): item for item in artifacts}
    dependency_paths = sorted(
        str(item["path"])
        for item in artifacts
        if item["category"] == "host-tool" and item["role"] == "dependency"
    )
    if not dependency_paths:
        refuse("compiler-plugin packaged host closure is empty")
    expected_scopes = ["app", "framework", "package"]
    seen_modules: set[str] = set()
    seen_paths: set[str] = set()
    result: list[dict[str, object]] = []
    for module, kind, plugin_relative, digest, raw_registrations, raw_scopes, raw_serialized in plugin_rows:
        if not module.isidentifier() or module in seen_modules:
            refuse(f"unsafe or duplicate compiler-plugin module: {module}")
        seen_modules.add(module)
        if kind not in ("library", "executable"):
            refuse(f"unsupported compiler-plugin load kind: {kind}")
        safe_relative(plugin_relative, f"{module} plugin path")
        if plugin_relative in seen_paths:
            refuse(f"duplicate compiler-plugin path: {plugin_relative}")
        seen_paths.add(plugin_relative)
        artifact = artifact_by_path.get(plugin_relative)
        if (
            artifact is None
            or artifact["category"] != "host-tool"
            or artifact["role"] != "plugin"
            or artifact["sha256"] != digest
        ):
            refuse(f"{module} plugin artifact/hash differs from its ledger")
        registrations = raw_registrations.split(",")
        if (
            not registrations
            or registrations != sorted(set(registrations))
            or any(not value.isidentifier() for value in registrations)
        ):
            refuse(f"{module} macro registrations are malformed or unsorted")
        scopes = raw_scopes.split(",")
        if scopes != expected_scopes:
            refuse(f"{module} consumer scopes must be app,framework,package")
        if raw_serialized not in ("serialized=yes", "serialized=no"):
            refuse(f"{module} serialized-job requirement is malformed")
        closure = closure_rows.get(module, [])
        if [value[0] for value in closure] != dependency_paths:
            refuse(f"{module} native host closure is incomplete or unordered")
        closure_json: list[dict[str, str]] = []
        for closure_relative, closure_digest in closure:
            item = artifact_by_path.get(closure_relative)
            if (
                item is None
                or item["category"] != "host-tool"
                or item["role"] != "dependency"
                or item["sha256"] != closure_digest
            ):
                refuse(f"{module} closure artifact/hash differs: {closure_relative}")
            closure_json.append(
                {"path": closure_relative, "sha256": closure_digest}
            )
        option = "-load-plugin-library" if kind == "library" else "-load-plugin-executable"
        expected_argument = plugin_relative if kind == "library" else f"{plugin_relative}#{module}"
        occurrences = sum(
            compile_tokens[index : index + 2] == [option, expected_argument]
            for index in range(len(compile_tokens) - 1)
        )
        if occurrences != 1:
            refuse(
                f"{module} compiler-plugin load pair count {occurrences}, expected 1"
            )
        result.append(
            {
                "module": module,
                "load_kind": kind,
                "path": plugin_relative,
                "sha256": digest,
                "registrations": registrations,
                "consumer_scopes": scopes,
                "serialized_jobs": raw_serialized == "serialized=yes",
                "host_closure": closure_json,
            }
        )
    if set(closure_rows) != seen_modules:
        refuse("compiler-plugin closure names differ from declared plugins")
    missing_modules = sorted(REQUIRED_COMPILER_PLUGIN_MODULES - seen_modules)
    if missing_modules:
        refuse(
            "compiler-plugin manifest omits required modules: "
            + ", ".join(missing_modules)
        )
    return result


def require_framework_boundary(artifacts: list[dict[str, str]]) -> None:
    for framework in FRAMEWORKS:
        selected = [item for item in artifacts if item["category"] == "framework" and item["name"] == framework]
        if not any(item["role"] == "swiftmodule" for item in selected):
            refuse(f"framework {framework} has no swiftmodule artifact")
        if not any(item["role"] == "dylib" for item in selected):
            refuse(f"framework {framework} has no dylib artifact")
    for module in MODULE_DEPENDENCIES:
        if not any(
            item["category"] == "module-dependency"
            and item["name"] == module
            and item["role"] == "swiftmodule"
            for item in artifacts
        ):
            refuse(f"module dependency {module} has no swiftmodule artifact")
    required_icu = {
        ("dylib", "lib/lib_FoundationICU.dylib"),
        (
            "module-map",
            "include/FoundationICU/_foundation_unicode/module.modulemap",
        ),
    }
    actual_icu = {
        (str(item["role"]), str(item["path"]))
        for item in artifacts
        if item["category"] == "module-dependency"
        and item["name"] == "_FoundationICU"
    }
    if not required_icu.issubset(actual_icu):
        refuse("full _FoundationICU module/dylib dependency is absent")
    required_internationalization_runtime = {
        ("darwin-bridge", "guest-root/darwin/usr/lib/libOpenFoundationInternationalization.dylib"),
        ("linux-helper", "guest-root/host/libOpenFoundationInternationalizationHost.so"),
    }
    actual_internationalization_runtime = {
        (str(item["role"]), str(item["path"]))
        for item in artifacts
        if item["category"] == "runtime"
        and item["name"] == "OpenFoundationInternationalization"
    }
    if not required_internationalization_runtime.issubset(
        actual_internationalization_runtime
    ):
        refuse("FoundationInternationalization runtime bridge/helper is absent")
    if not any(
        item["category"] == "runtime"
        and item["name"] == "CQuartz"
        and item["role"] == "dylib"
        for item in artifacts
    ):
        refuse("CQuartz runtime dylib is absent")
    for role in ("system-font", "bold-font"):
        if not any(
            item["category"] == "resource"
            and item["name"] == "OpenUIKit"
            and item["role"] == role
            for item in artifacts
        ):
            refuse(f"OpenUIKit {role} artifact is absent")
    required_coreimage_includes = {
        ("umbrella-header", "include/CoreImage/CoreImage.h"),
        ("submodule-header", "include/CoreImage/CIFilterBuiltins.h"),
        ("module-map", "include/CoreImage/module.modulemap"),
    }
    actual_coreimage_includes = {
        (str(item["role"]), str(item["path"]))
        for item in artifacts
        if item["category"] == "include" and item["name"] == "CoreImage"
    }
    missing_coreimage_includes = sorted(
        required_coreimage_includes - actual_coreimage_includes
    )
    if missing_coreimage_includes:
        refuse(
            "CoreImage underlying-module artifacts are absent: "
            + ", ".join(path for _role, path in missing_coreimage_includes)
        )


def require_coreimage_compile_contract(tokens: list[str]) -> None:
    for argument in (
        "-fmodule-map-file=include/CoreImage/module.modulemap",
        "-Iinclude/CoreImage",
    ):
        count = sum(
            tokens[index : index + 2] == ["-Xcc", argument]
            for index in range(len(tokens) - 1)
        )
        if count != 1:
            refuse(
                "compile flags must contain CoreImage underlying-module pair "
                f"exactly once: -Xcc {argument}"
            )


def require_cross_import_compile_contract(tokens: list[str]) -> None:
    pair = ["-Xfrontend", "-enable-cross-import-overlays"]
    count = sum(
        tokens[index : index + 2] == pair
        for index in range(len(tokens) - 1)
    )
    if count != 1:
        refuse(
            "compile flags must enable Swift cross-import overlays exactly once: "
            "-Xfrontend -enable-cross-import-overlays"
        )


def require_exhaustive_artifact_tree(
    package: Path,
    artifacts: list[dict[str, object]],
    relative_root: str,
) -> None:
    root = package / safe_relative(relative_root, "exhaustive tree root")
    require_directory_no_link(root, f"exhaustive artifact tree {relative_root}")
    physical: set[str] = set()
    for directory, names, files in os.walk(root, followlinks=False):
        directory_path = Path(directory)
        for name in names:
            candidate = directory_path / name
            if candidate.is_symlink():
                refuse(f"symlink in exhaustive artifact tree: {candidate}")
        for name in files:
            candidate = directory_path / name
            require_regular_no_link(candidate, "exhaustive tree file")
            physical.add(candidate.relative_to(package).as_posix())
    recorded = {
        str(item["path"])
        for item in artifacts
        if str(item.get("path", "")).startswith(f"{relative_root}/")
    }
    if physical != recorded:
        refuse(
            f"artifact coverage drifted under {relative_root}: "
            f"missing={sorted(physical - recorded)} extra={sorted(recorded - physical)}"
        )


def preview_json(
    package: Path,
    artifacts: list[dict[str, str]],
    preview_relative: str | None,
    external_plugin: str | None,
) -> dict[str, object] | None:
    dts = [item for item in artifacts if item["name"] == "DeveloperToolsSupport"]
    if preview_relative is None:
        if dts:
            refuse("DeveloperToolsSupport artifacts exist without preview attestation")
        return None
    safe_relative(preview_relative, "preview attestation path")
    preview_path = require_regular_beneath(package, preview_relative, "preview attestation")
    values = parse_key_value(preview_path, "core-preview-input-v2")
    required = {
        "module-name",
        "module-path",
        "module-sha256",
        "object-path",
        "object-sha256",
        "plugin-basename",
        "plugin-sha256",
        "plugin-elf-class",
        "plugin-elf-machine",
        "plugin-toolchain",
        "plugin-swiftsyntax-revision",
        "plugin-registration",
        "plugin-load-flags",
        "plugin-driver-job-count",
    }
    if set(values) != required:
        refuse(f"preview attestation keys drifted: {sorted(set(values) ^ required)}")
    if values["module-name"] != "DeveloperToolsSupport":
        refuse("preview target module name is not DeveloperToolsSupport")
    if values["plugin-basename"] != "OpenUIKitPreviewMacros-tool":
        refuse("preview plugin basename drifted")
    if values["plugin-registration"] != "OpenUIKitPreviewMacros":
        refuse("preview plugin registration name drifted")
    if values["plugin-swiftsyntax-revision"] != PREVIEW_SWIFTSYNTAX_REVISION:
        refuse("preview SwiftSyntax revision drifted")
    if values["plugin-driver-job-count"] != "1":
        refuse("preview plugin driver job count is not one")
    if values["plugin-elf-class"] != "ELF64" or values["plugin-elf-machine"] != "AArch64":
        refuse("preview plugin is not native ELF64/AArch64")
    module = next(
        (
            item
            for item in dts
            if item["role"] == "swiftmodule" and item["path"] == values["module-path"]
        ),
        None,
    )
    obj = next(
        (
            item
            for item in dts
            if item["role"] == "object" and item["path"] == values["object-path"]
        ),
        None,
    )
    if module is None or module["sha256"] != values["module-sha256"]:
        refuse("DeveloperToolsSupport module does not match preview attestation")
    if obj is None or obj["sha256"] != values["object-sha256"]:
        refuse("DeveloperToolsSupport object does not match preview attestation")
    load_tokens = read_nul_tokens(
        package, values["plugin-load-flags"], "preview plugin load flags"
    )
    if load_tokens != [
        "-load-plugin-executable",
        "${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros",
        "-j1",
    ]:
        refuse("preview plugin load flags have the wrong token contract")
    if external_plugin is not None:
        plugin = Path(external_plugin)
        require_regular_no_link(plugin, "external preview plugin")
        if plugin.name != values["plugin-basename"]:
            refuse("preview plugin has the wrong basename")
        if sha256_file(plugin) != values["plugin-sha256"]:
            refuse("external preview plugin hash drifted")
    return {
        "plugin_sha256": values["plugin-sha256"],
        "plugin_module": values["plugin-registration"],
        "plugin_basename": values["plugin-basename"],
        "plugin_elf_class": values["plugin-elf-class"],
        "plugin_elf_machine": values["plugin-elf-machine"],
        "plugin_toolchain": values["plugin-toolchain"],
        "plugin_swiftsyntax_revision": values["plugin-swiftsyntax-revision"],
        "plugin_driver_job_count": 1,
        "developer_tools_support_module": {
            "path": values["module-path"],
            "sha256": values["module-sha256"],
        },
        "developer_tools_support_object": values["object-path"],
        "developer_tools_support_object_sha256": values["object-sha256"],
        "load_arguments_rsp": values["plugin-load-flags"],
        "load_arguments": [
            "-load-plugin-executable",
            "${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros",
            "-j1",
        ],
        "app_compile_diagnostic_arguments": [
            "-Xfrontend",
            "-dump-macro-expansions",
        ],
    }


def validate_document(
    package: Path,
    document: dict[str, object],
    external_plugin: str | None = None,
) -> None:
    if document.get("classification") != CLASSIFICATION:
        refuse("core package classification drifted")
    if document.get("format_version") != FORMAT_VERSION:
        refuse("core package format version drifted")
    if document.get("target") != {
        "triple": "arm64-apple-macos15.0",
        "minimum_os": "15.0",
    }:
        refuse("core package target drifted")
    if document.get("paths") != PATHS:
        refuse("core package paths drifted")
    for relative in REQUIRED_DIRECTORIES:
        safe_relative(relative, "package directory path")
        require_directory_no_link(package / relative, f"package directory {relative}")
    artifacts = document.get("artifacts")
    if not isinstance(artifacts, list):
        refuse("core package artifacts are not an array")
    seen: set[str] = set()
    for artifact in artifacts:
        if not isinstance(artifact, dict):
            refuse("core package artifact is not an object")
        relative = artifact.get("path")
        digest = artifact.get("sha256")
        size = artifact.get("size")
        if (
            not isinstance(relative, str)
            or not isinstance(digest, str)
            or not isinstance(size, int)
            or size < 0
        ):
            refuse("core package artifact path/hash/size is malformed")
        safe_relative(relative, "JSON artifact path")
        if relative in seen:
            refuse(f"duplicate JSON artifact path: {relative}")
        seen.add(relative)
        path = require_regular_beneath(package, relative, "JSON artifact")
        if sha256_file(path) != digest:
            refuse(f"JSON artifact hash drifted: {relative}")
        if path.stat().st_size != size:
            refuse(f"JSON artifact size drifted: {relative}")
    require_exhaustive_artifact_tree(package, artifacts, "lib")
    require_exhaustive_artifact_tree(package, artifacts, "resources/OpenUIKit")
    require_exhaustive_artifact_tree(package, artifacts, "host-tools")
    manifests = document.get("manifests")
    if not isinstance(manifests, dict):
        refuse("core package manifests are missing")
    missing_manifests = sorted(REQUIRED_MANIFESTS - set(manifests))
    if missing_manifests:
        refuse("core package omits required manifests: " + ", ".join(missing_manifests))
    for value in manifests.values():
        if not isinstance(value, dict):
            refuse("core package manifest record is malformed")
        relative = value.get("path")
        digest = value.get("sha256")
        if not isinstance(relative, str) or not isinstance(digest, str):
            refuse("core package manifest path/hash is malformed")
        path = require_regular_beneath(package, safe_relative(relative), "JSON manifest")
        if sha256_file(path) != digest:
            refuse(f"JSON manifest hash drifted: {relative}")
    ledger_record = manifests.get("artifact_ledger")
    if not isinstance(ledger_record, dict):
        refuse("artifact ledger manifest record is missing")
    ledger_relative = ledger_record.get("path")
    if not isinstance(ledger_relative, str):
        refuse("artifact ledger manifest path is malformed")
    ledger_artifacts = read_artifacts(
        package,
        require_regular_beneath(
            package,
            safe_relative(ledger_relative, "artifact ledger manifest path"),
            "artifact ledger manifest",
        ),
    )
    if artifacts != ledger_artifacts:
        refuse("JSON artifact records differ from the artifact ledger")
    require_framework_boundary(ledger_artifacts)
    expected_fonts = {
        {"system-font": "system", "bold-font": "bold"}[str(item["role"])]: {
            "path": item["path"],
            "sha256": item["sha256"],
        }
        for item in ledger_artifacts
        if item["category"] == "resource"
        and item["name"] == "OpenUIKit"
        and item["role"] in ("system-font", "bold-font")
    }
    if document.get("openuikit_runtime") != {
        "resource_root": PATHS["resources"],
        "font_paths": expected_fonts,
    }:
        refuse("OpenUIKit runtime resource/font paths drifted")
    rsp = document.get("response_files")
    if not isinstance(rsp, dict) or rsp.get("encoding") != "nul-delimited-utf8":
        refuse("response-file encoding contract drifted")
    compile_tokens = read_nul_tokens(
        package, str(rsp.get("compile")), "compile flags"
    )
    link_tokens = read_nul_tokens(package, str(rsp.get("link")), "link inputs")
    for key in ("swift_compile_arguments", "executable_link_arguments"):
        values = document.get(key)
        if not isinstance(values, list) or not values or not all(
            isinstance(value, str) and "\x00" not in value for value in values
        ):
            refuse(f"{key} is not a nonempty JSON string array")
    if document["swift_compile_arguments"] != compile_tokens:
        refuse("JSON Swift compile arguments differ from the NUL response file")
    if document["executable_link_arguments"] != link_tokens:
        refuse("JSON executable link arguments differ from the NUL response file")
    if link_tokens.count("-Llib") != 1:
        refuse("link inputs must contain -Llib exactly once")
    require_coreimage_compile_contract(compile_tokens)
    require_cross_import_compile_contract(compile_tokens)
    for required in REQUIRED_FRAMEWORK_LINK_ARGUMENTS:
        if link_tokens.count(required) != 1:
            refuse(f"link inputs must contain required token exactly once: {required}")
    compiler_plugin_manifest = manifests.get("compiler_plugins")
    if not isinstance(compiler_plugin_manifest, dict) or not isinstance(
        compiler_plugin_manifest.get("path"), str
    ):
        refuse("core package has no compiler-plugin manifest")
    rebuilt_compiler_plugins = compiler_plugins_json(
        package,
        ledger_artifacts,
        str(compiler_plugin_manifest["path"]),
        compile_tokens,
    )
    if document.get("compiler_plugins") != rebuilt_compiler_plugins:
        refuse("compiler_plugins JSON differs from its attested manifest")

    preview = document.get("preview", "missing")
    if preview == "missing":
        refuse("core package preview classification is missing")
    if preview is not None:
        preview_manifest = manifests.get("preview_input")
        if not isinstance(preview_manifest, dict) or not isinstance(
            preview_manifest.get("path"), str
        ):
            refuse("Preview package has no preview-input manifest")
        rebuilt_preview = preview_json(
            package,
            ledger_artifacts,
            str(preview_manifest["path"]),
            external_plugin,
        )
        if preview != rebuilt_preview:
            refuse("Preview JSON differs from the preview-input attestation")
        if not isinstance(preview, dict):
            refuse("core package preview record is malformed")
        required_preview = {
            "plugin_sha256",
            "plugin_module",
            "plugin_basename",
            "plugin_elf_class",
            "plugin_elf_machine",
            "plugin_toolchain",
            "plugin_swiftsyntax_revision",
            "plugin_driver_job_count",
            "developer_tools_support_module",
            "developer_tools_support_object",
            "developer_tools_support_object_sha256",
            "load_arguments_rsp",
            "load_arguments",
            "app_compile_diagnostic_arguments",
        }
        if set(preview) != required_preview:
            refuse("core package preview keys drifted")
        if preview["plugin_module"] != "OpenUIKitPreviewMacros":
            refuse("core package preview plugin module drifted")
        if preview["plugin_driver_job_count"] != 1:
            refuse("core package preview plugin driver job count drifted")
        if preview["load_arguments"] != [
            "-load-plugin-executable",
            "${PREVIEW_PLUGIN}#OpenUIKitPreviewMacros",
            "-j1",
        ]:
            refuse("core package preview load arguments drifted")
        if read_nul_tokens(
            package, str(preview["load_arguments_rsp"]), "preview load flags"
        ) != preview["load_arguments"]:
            refuse("preview JSON load arguments differ from its NUL response file")
        dts_object = safe_relative(
            str(preview["developer_tools_support_object"]),
            "DeveloperToolsSupport object",
        )
        if link_tokens.count(dts_object) != 0:
            refuse(
                "DeveloperToolsSupport object is app-driver-owned and must not "
                "appear in executable_link_arguments"
            )
        module = preview["developer_tools_support_module"]
        if not isinstance(module, dict) or set(module) != {"path", "sha256"}:
            refuse("DeveloperToolsSupport module record is malformed")
        for relative, digest, what in (
            (
                str(module["path"]),
                str(module["sha256"]),
                "DeveloperToolsSupport module",
            ),
            (
                dts_object,
                str(preview["developer_tools_support_object_sha256"]),
                "DeveloperToolsSupport object",
            ),
        ):
            physical = require_regular_beneath(package, safe_relative(relative), what)
            if sha256_file(physical) != digest:
                refuse(f"{what} hash drifted")
        if external_plugin is not None:
            plugin = Path(external_plugin)
            require_regular_no_link(plugin, "external preview plugin")
            if plugin.name != preview["plugin_basename"]:
                refuse("external preview plugin basename drifted")
            if sha256_file(plugin) != preview["plugin_sha256"]:
                refuse("external preview plugin hash drifted")
    else:
        if "preview_input" in manifests:
            refuse("non-Preview package carries a preview-input manifest")
        preview_json(package, ledger_artifacts, None, None)
        if external_plugin is not None:
            refuse("external preview plugin supplied for a package without Preview")

    def reject_absolute(value: object, location: str) -> None:
        if isinstance(value, str) and value.startswith("/"):
            refuse(f"absolute path escaped into relocatable JSON at {location}")
        if isinstance(value, list):
            for index, child in enumerate(value):
                reject_absolute(child, f"{location}[{index}]")
        if isinstance(value, dict):
            for key, child in value.items():
                reject_absolute(child, f"{location}.{key}")

    reject_absolute(document, "root")


def write_command(args: argparse.Namespace) -> None:
    package = Path(args.package_root)
    require_directory_no_link(package, "package root")
    for directory in REQUIRED_DIRECTORIES:
        require_directory_no_link(package / directory, f"package directory {directory}")
    artifacts = read_artifacts(package, Path(args.artifact_ledger))
    require_framework_boundary(artifacts)
    compile_tokens = read_nul_tokens(package, args.compile_rsp, "compile flags")
    link_tokens = read_nul_tokens(package, args.link_rsp, "link inputs")
    if compile_tokens[:2] != ["-target", "arm64-apple-macos15.0"]:
        refuse("compile flags do not begin with the exact target")
    if link_tokens[:8] != [
        "-arch",
        "arm64",
        "-platform_version",
        "macos",
        "15.0",
        "15.0",
        "-syslibroot",
        "sdk",
    ]:
        refuse("link inputs do not begin with the exact ARM64 platform/SDK contract")
    for required in ("-sdk", "sdk", "-I", "modules"):
        if required not in compile_tokens:
            refuse(f"compile flags omit required token: {required}")
    require_coreimage_compile_contract(compile_tokens)
    require_cross_import_compile_contract(compile_tokens)
    if link_tokens.count("-Llib") != 1:
        refuse("link inputs must contain -Llib exactly once")
    for required in REQUIRED_FRAMEWORK_LINK_ARGUMENTS:
        if link_tokens.count(required) != 1:
            refuse(f"link inputs must contain required token exactly once: {required}")
    preview = preview_json(
        package,
        artifacts,
        args.preview_attestation,
        args.external_preview_plugin,
    )
    compiler_plugins = compiler_plugins_json(
        package, artifacts, args.compiler_plugins, compile_tokens
    )
    dts_object_count = link_tokens.count("objects/developertoolsupport.o")
    if dts_object_count != 0:
        refuse(
            "DeveloperToolsSupport object is app-driver-owned and must not occur "
            "in core link inputs"
        )

    frameworks: dict[str, list[dict[str, str]]] = {}
    for name in FRAMEWORKS:
        frameworks[name] = [
            item for item in artifacts if item["category"] == "framework" and item["name"] == name
        ]
    fonts = {
        {"system-font": "system", "bold-font": "bold"}[str(item["role"])]: {
            "path": item["path"],
            "sha256": item["sha256"],
        }
        for item in artifacts
        if item["category"] == "resource" and item["name"] == "OpenUIKit" and item["role"] in ("system-font", "bold-font")
    }
    document: dict[str, object] = {
        "classification": CLASSIFICATION,
        "format_version": FORMAT_VERSION,
        "target": {
            "triple": "arm64-apple-macos15.0",
            "minimum_os": "15.0",
        },
        "paths": PATHS,
        "frameworks": frameworks,
        "module_dependencies": {
            name: [item for item in artifacts if item["category"] == "module-dependency" and item["name"] == name]
            for name in MODULE_DEPENDENCIES
        },
        "artifacts": artifacts,
        "manifests": {
            "artifact_ledger": checked_manifest(package, args.artifact_ledger_relative, "artifact ledger"),
            "input_provenance": checked_manifest(package, args.input_provenance, "input provenance"),
            "source_sets": checked_manifest(package, args.source_sets, "source sets"),
            "foundation_sources": checked_manifest(package, args.foundation_sources, "Foundation sources"),
            "intents_sources": checked_manifest(package, args.intents_sources, "Intents sources"),
            "graphics_sources": checked_manifest(
                package, args.graphics_sources, "CoreImage/QuartzCore sources"
            ),
            "first_party_sources": checked_manifest(
                package, args.first_party_sources, "first-party sources"
            ),
            "first_party_dylib_loads": checked_manifest(
                package, args.first_party_dylib_loads, "first-party dylib loads"
            ),
            "webkit_sources": checked_manifest(
                package, args.webkit_sources, "WebKit sources"
            ),
            "sdk_tree": checked_manifest(package, args.sdk_inventory, "SDK inventory"),
            "sdk_dangling_symlinks": checked_manifest(
                package, args.sdk_dangling_symlinks, "SDK dangling symlinks"
            ),
            "sdk_dangling_exclusions": checked_manifest(
                package, args.sdk_dangling_exclusions, "SDK dangling exclusions"
            ),
            "include_tree": checked_manifest(package, args.include_inventory, "include inventory"),
            "guest_root_tree": checked_manifest(package, args.guest_inventory, "guest-root inventory"),
            "openuikit_resources_tree": checked_manifest(package, args.resource_inventory, "OpenUIKit resource inventory"),
            "runtime_closure": checked_manifest(package, args.runtime_closure, "runtime closure"),
            "compiler_plugins": checked_manifest(
                package, args.compiler_plugins, "compiler plugins"
            ),
        },
        "response_files": {
            "encoding": "nul-delimited-utf8",
            "base": "package-root",
            "compile": safe_relative(args.compile_rsp, "compile response path"),
            "link": safe_relative(args.link_rsp, "link response path"),
        },
        "swift_compile_arguments": compile_tokens,
        "executable_link_arguments": link_tokens,
        "compiler_plugins": compiler_plugins,
        "openuikit_runtime": {
            "resource_root": "resources/OpenUIKit",
            "font_paths": fonts,
        },
        "preview": preview,
    }
    if preview is not None:
        manifests = document["manifests"]
        assert isinstance(manifests, dict)
        manifests["preview_input"] = checked_manifest(
            package,
            args.preview_attestation,
            "Preview input",
        )
    output = package / "attestation/core-package.json"
    write_text_new(output, json.dumps(document, indent=2, sort_keys=True) + "\n")
    validate_document(package, document, args.external_preview_plugin)


def verify_command(args: argparse.Namespace) -> None:
    package = Path(args.package_root)
    path = require_regular_beneath(
        package, "attestation/core-package.json", "core package JSON"
    )
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        refuse(f"cannot parse core package JSON: {error}")
    if not isinstance(document, dict):
        refuse("core package JSON root is not an object")
    validate_document(package, document, args.preview_plugin)
    print(
        "CORE_PACKAGE_MANIFEST_OK "
        f"sha256={sha256_file(path)} artifacts={len(document['artifacts'])}"
    )


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    subparsers = result.add_subparsers(dest="command", required=True)

    foundation = subparsers.add_parser("foundation-sources")
    foundation.add_argument("--support-root", required=True)
    foundation.add_argument("--manifest", required=True)
    foundation.add_argument("--output", required=True)
    foundation.set_defaults(handler=foundation_command)

    inventory = subparsers.add_parser("inventory-tree")
    inventory.add_argument("--root", required=True)
    inventory.add_argument("--logical-root", required=True)
    inventory.add_argument("--output", required=True)
    inventory.add_argument("--reject-symlinks", action="store_true")
    inventory.add_argument("--dangling-exclusions")
    inventory.set_defaults(handler=inventory_command)

    dangling = subparsers.add_parser("dangling-symlinks")
    dangling.add_argument("--root", required=True)
    dangling.add_argument("--exclusions", required=True)
    dangling.add_argument("--output", required=True)
    dangling.add_argument("--remove", action="store_true")
    dangling.set_defaults(handler=dangling_symlinks_command)

    write = subparsers.add_parser("write")
    write.add_argument("--package-root", required=True)
    write.add_argument("--artifact-ledger", required=True)
    write.add_argument("--artifact-ledger-relative", required=True)
    write.add_argument("--input-provenance", required=True)
    write.add_argument("--source-sets", required=True)
    write.add_argument("--foundation-sources", required=True)
    write.add_argument("--intents-sources", required=True)
    write.add_argument("--graphics-sources", required=True)
    write.add_argument("--first-party-sources", required=True)
    write.add_argument("--first-party-dylib-loads", required=True)
    write.add_argument("--webkit-sources", required=True)
    write.add_argument("--sdk-inventory", required=True)
    write.add_argument("--sdk-dangling-symlinks", required=True)
    write.add_argument("--sdk-dangling-exclusions", required=True)
    write.add_argument("--include-inventory", required=True)
    write.add_argument("--guest-inventory", required=True)
    write.add_argument("--resource-inventory", required=True)
    write.add_argument("--runtime-closure", required=True)
    write.add_argument("--compiler-plugins", required=True)
    write.add_argument("--compile-rsp", required=True)
    write.add_argument("--link-rsp", required=True)
    write.add_argument("--preview-attestation")
    write.add_argument("--external-preview-plugin")
    write.set_defaults(handler=write_command)

    verify = subparsers.add_parser("verify")
    verify.add_argument("--package-root", required=True)
    verify.add_argument("--preview-plugin")
    verify.set_defaults(handler=verify_command)
    return result


def main(argv: Iterable[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        args.handler(args)
    except Refusal as error:
        print(f"core_package_manifest: REFUSING -- {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
