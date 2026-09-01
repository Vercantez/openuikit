#!/usr/bin/env python3
"""Validate and expose one relocatable OpenUIKit core guest package.

The framework builder publishes compiler/linker argument arrays that are
evaluated with the package root as the working directory.  This validator
rehashes every declared product, rejects host-build path leakage, and emits
NUL-delimited arguments for a shell caller without re-parsing quoting syntax.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import sys
from typing import Any


class CorePackageError(RuntimeError):
    """The core guest package does not satisfy the executable-build contract."""


_SHA256 = re.compile(r"[0-9a-f]{64}\Z")
_PATH_KEYS = {
    "sdk",
    "modules",
    "libraries",
    "includes",
    "objects",
    "resources",
    "guest_root",
    "host_tools",
}
_CONTROLLED_COMPILE_OPTIONS = {
    "-emit-object",
    "-emit-module",
    "-emit-module-path",
    "-disable-batch-mode",
    "-dump-macro-expansions",
    "-enable-batch-mode",
    "-load-plugin-executable",
    "-module-cache-path",
    "-module-name",
    "-o",
    "-output-file-map",
    "-primary-file",
    "-whole-module-optimization",
    "-wmo",
}
_CONTROLLED_LINK_OPTIONS = {"-o"}
_ALLOWED_ABSOLUTE_ARGUMENTS = {"/usr/lib", "/usr/lib/swift"}
_PREVIEW_DIAGNOSTIC_ARGUMENTS = ["-Xfrontend", "-dump-macro-expansions"]
_SWIFT_PACKAGE_PATH_OPTIONS = {
    "-F",
    "-I",
    "-L",
    "-load-plugin-library",
    "-sdk",
    "-vfsoverlay",
}
_SWIFT_ATTACHED_PACKAGE_PATH_OPTIONS = (
    "-fmodule-map-file=",
    "-isystem",
    "-iquote",
    "-ivfsoverlay",
    "-F",
    "-I",
    "-L",
)
_REQUIRED_FRAMEWORKS = (
    "FoundationEssentials",
    "OpenCoreGraphics",
    "OpenUIKit",
    "OpenCombine",
    "Dispatch",
    "Combine",
    "Symbols",
    "SwiftUI",
    "_QuickLook_SwiftUI",
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
)
_REQUIRED_FRAMEWORK_LINK_ARGUMENTS = tuple(
    f"-l{name}" for name in _REQUIRED_FRAMEWORKS
)
_REQUIRED_MANIFESTS = {
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

_REQUIRED_COMPILER_PLUGIN_MODULES = {
    "ObservationMacros",
    "FoundationMacros",
    "SwiftDataMacros",
    "OpenUIKitPreviewMacros",
    "OpenSwiftUIMacros",
}


def _mapping(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise CorePackageError(f"{label} must be an object")
    return value


def _array(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise CorePackageError(f"{label} must be an array")
    return value


def _string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise CorePackageError(f"{label} must be a non-empty string")
    if any(character in value for character in ("\0", "\r", "\n")):
        raise CorePackageError(f"{label} contains a forbidden control character")
    return value


def _relative(value: Any, label: str) -> PurePosixPath:
    text = _string(value, label)
    path = PurePosixPath(text)
    if path.is_absolute() or not path.parts or any(
        component in ("", ".", "..") for component in path.parts
    ):
        raise CorePackageError(f"{label} is not a safe package-relative path: {text!r}")
    return path


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
        raise CorePackageError(f"cannot inspect package root: {path}: {exc}") from exc
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        raise CorePackageError(f"package root is not an ordinary directory: {path}")
    return path.resolve(strict=True)


def _materialized(root: Path, relative: PurePosixPath, label: str) -> Path:
    current = root
    for index, component in enumerate(relative.parts):
        current /= component
        try:
            metadata = current.lstat()
        except OSError as exc:
            raise CorePackageError(f"cannot inspect {label}: {current}: {exc}") from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise CorePackageError(f"{label} traverses a symlink: {current}")
        if index < len(relative.parts) - 1 and not stat.S_ISDIR(metadata.st_mode):
            raise CorePackageError(f"{label} parent is not a directory: {current}")
    try:
        current.resolve(strict=True).relative_to(root)
    except (OSError, ValueError) as exc:
        raise CorePackageError(f"{label} escapes package root: {current}") from exc
    return current


def _directory(root: Path, value: Any, label: str) -> tuple[str, Path]:
    relative = _relative(value, label)
    materialized = _materialized(root, relative, label)
    if not materialized.is_dir():
        raise CorePackageError(f"{label} is not a directory: {materialized}")
    return relative.as_posix(), materialized


def _regular_file(root: Path, value: Any, label: str) -> tuple[str, Path]:
    relative = _relative(value, label)
    materialized = _materialized(root, relative, label)
    if not materialized.is_file():
        raise CorePackageError(f"{label} is not a regular file: {materialized}")
    return relative.as_posix(), materialized


def _arguments(value: Any, label: str, controlled: set[str]) -> list[str]:
    result = [_string(item, f"{label}[{index}]") for index, item in enumerate(_array(value, label))]
    if not result:
        raise CorePackageError(f"{label} must not be empty")
    for token in result:
        if token in controlled:
            raise CorePackageError(f"{label} contains driver-owned option: {token}")
        if token.startswith("/") and token not in _ALLOWED_ABSOLUTE_ARGUMENTS:
            raise CorePackageError(f"{label} leaks an absolute host path: {token}")
    return result


def _root_package_argument(root: Path, value: str, label: str) -> str:
    """Give a package-relative compiler path one stable physical identity.

    Swift serializes Clang module provenance into prebuilt `.swiftmodule` files.
    Running from the package root is therefore not equivalent to spelling the
    package path absolutely: Clang rejects a PCM first seen as `/platform/sdk`
    when a downstream compile later presents the same directory as `sdk`.
    """
    if value.startswith("/"):
        if value not in _ALLOWED_ABSOLUTE_ARGUMENTS:
            raise CorePackageError(
                f"{label} contains an absolute path outside the allowlist: {value}"
            )
        return value
    relative = _relative(value, label)
    return os.fspath(_materialized(root, relative, label))


def _root_attached_package_argument(root: Path, value: str, label: str) -> str:
    for prefix in _SWIFT_ATTACHED_PACKAGE_PATH_OPTIONS:
        if value.startswith(prefix) and len(value) > len(prefix):
            path = value[len(prefix) :]
            return prefix + _root_package_argument(root, path, label)
    return value


def rooted_swift_compile_arguments(root: Path, arguments: list[str]) -> list[str]:
    """Root every path-bearing package compiler argument at ``root``.

    The input remains the relocatable manifest array. This derived array is
    for an actual compiler invocation at the package's mounted location.
    """
    rooted: list[str] = []
    cursor = 0
    while cursor < len(arguments):
        token = arguments[cursor]
        if token in _SWIFT_PACKAGE_PATH_OPTIONS:
            if cursor + 1 >= len(arguments):
                raise CorePackageError(
                    f"swift_compile_arguments ends after path option: {token}"
                )
            rooted.extend(
                (
                    token,
                    _root_package_argument(
                        root,
                        arguments[cursor + 1],
                        f"swift_compile_arguments[{cursor + 1}]",
                    ),
                )
            )
            cursor += 2
            continue
        if token == "-Xcc":
            if cursor + 1 >= len(arguments):
                raise CorePackageError("swift_compile_arguments ends after -Xcc")
            rooted.extend(
                (
                    token,
                    _root_attached_package_argument(
                        root,
                        arguments[cursor + 1],
                        f"swift_compile_arguments[{cursor + 1}]",
                    ),
                )
            )
            cursor += 2
            continue
        rooted.append(
            _root_attached_package_argument(
                root, token, f"swift_compile_arguments[{cursor}]"
            )
        )
        cursor += 1
    return rooted


def _require_coreimage_compile_contract(arguments: list[str]) -> None:
    for argument in (
        "-fmodule-map-file=include/CoreImage/module.modulemap",
        "-Iinclude/CoreImage",
    ):
        count = sum(
            arguments[index : index + 2] == ["-Xcc", argument]
            for index in range(len(arguments) - 1)
        )
        if count != 1:
            raise CorePackageError(
                "swift_compile_arguments must contain the CoreImage "
                "underlying-module pair exactly once: -Xcc " + argument
            )


def _require_cross_import_compile_contract(arguments: list[str]) -> None:
    pair = ["-Xfrontend", "-enable-cross-import-overlays"]
    count = sum(
        arguments[index : index + 2] == pair
        for index in range(len(arguments) - 1)
    )
    if count != 1:
        raise CorePackageError(
            "swift_compile_arguments must enable Swift cross-import overlays "
            "exactly once: -Xfrontend -enable-cross-import-overlays"
        )


def _sdk_symlink_target(
    sdk_root: Path, relative: PurePosixPath, target: str
) -> bytes:
    if not target or any(
        character in target for character in ("\0", "\r", "\n", "\t")
    ):
        raise CorePackageError(
            f"unsafe SDK symlink target at {relative.as_posix()}: {target!r}"
        )
    try:
        target_bytes = target.encode("utf-8")
    except UnicodeEncodeError as exc:
        raise CorePackageError(
            f"SDK symlink target is not UTF-8 at {relative.as_posix()}"
        ) from exc
    if target.startswith("/"):
        raise CorePackageError(
            f"absolute SDK symlink target at {relative.as_posix()}: {target}"
        )
    components = list(relative.parent.parts)
    for component in target.split("/"):
        if component in ("", "."):
            continue
        if component == "..":
            if not components:
                raise CorePackageError(
                    f"escaping SDK symlink target at {relative.as_posix()}: {target}"
                )
            components.pop()
        else:
            components.append(component)
    if not components:
        raise CorePackageError(
            f"SDK symlink resolves to the SDK root at {relative.as_posix()}: {target}"
        )
    destination = sdk_root.joinpath(*components)
    try:
        resolved = destination.resolve(strict=True)
    except (OSError, RuntimeError) as exc:
        raise CorePackageError(
            f"dangling SDK symlink at {relative.as_posix()}: {target}"
        ) from exc
    try:
        resolved.relative_to(sdk_root)
    except ValueError as exc:
        raise CorePackageError(
            f"escaping SDK symlink target at {relative.as_posix()}: {target}"
        ) from exc
    return target_bytes


def _sdk_tree_ledger(sdk_root: Path, logical_root: str) -> bytes:
    """Rebuild the builder's core-tree-v1 SDK ledger without following links."""

    records = ["format\tcore-tree-v1"]

    def visit(physical: Path, relative: PurePosixPath) -> None:
        logical = (
            logical_root
            if relative.as_posix() == "."
            else f"{logical_root}/{relative.as_posix()}"
        )
        try:
            mode = physical.lstat().st_mode
        except OSError as exc:
            raise CorePackageError(
                f"cannot inspect SDK tree entry: {logical}: {exc}"
            ) from exc
        if stat.S_ISLNK(mode):
            try:
                target = os.readlink(physical)
            except OSError as exc:
                raise CorePackageError(
                    f"cannot read SDK symlink: {logical}: {exc}"
                ) from exc
            target_bytes = _sdk_symlink_target(sdk_root, relative, target)
            records.append(
                "\t".join(
                    ("symlink", logical, _sha256_bytes(target_bytes), target)
                )
            )
            return
        if stat.S_ISREG(mode):
            records.append(
                "\t".join(
                    ("file", logical, _sha256(physical), str(physical.stat().st_size))
                )
            )
            return
        if not stat.S_ISDIR(mode):
            raise CorePackageError(f"unsupported node in SDK tree: {logical}")
        try:
            entries = sorted(os.scandir(physical), key=lambda entry: entry.name)
        except OSError as exc:
            raise CorePackageError(f"cannot enumerate SDK tree: {logical}: {exc}") from exc
        records.append(
            "\t".join(
                ("directory", logical, "empty=yes" if not entries else "empty=no")
            )
        )
        for entry in entries:
            if (
                entry.name in ("", ".", "..")
                or "\\" in entry.name
                or any(
                    character in entry.name
                    for character in ("\0", "\r", "\n", "\t")
                )
            ):
                raise CorePackageError(
                    f"unsafe path component in SDK tree beneath {logical}: {entry.name!r}"
                )
            try:
                entry.name.encode("utf-8")
            except UnicodeEncodeError as exc:
                raise CorePackageError(
                    f"non-UTF-8 path component in SDK tree beneath {logical}"
                ) from exc
            child = (
                PurePosixPath(entry.name)
                if relative.as_posix() == "."
                else relative / entry.name
            )
            visit(Path(entry.path), child)

    visit(sdk_root, PurePosixPath("."))
    return ("\n".join(records) + "\n").encode("utf-8")


def validate(package_root: Path) -> tuple[Path, dict[str, Any]]:
    root = _strict_root(package_root)
    manifest_relative = PurePosixPath("attestation/core-package.json")
    manifest_path = _materialized(root, manifest_relative, "core package manifest")
    if not manifest_path.is_file():
        raise CorePackageError(f"core package manifest is not a regular file: {manifest_path}")
    try:
        manifest = _mapping(json.loads(manifest_path.read_text(encoding="utf-8")), "manifest")
    except (OSError, json.JSONDecodeError) as exc:
        raise CorePackageError(f"cannot read core package manifest: {exc}") from exc

    if manifest.get("classification") != "open-uikit-core-guest-package":
        raise CorePackageError("unexpected core package classification")
    if manifest.get("format_version") != 1:
        raise CorePackageError("unsupported core package format_version")
    target = _mapping(manifest.get("target"), "target")
    if _string(target.get("triple"), "target.triple") != "arm64-apple-macos15.0":
        raise CorePackageError("core package target must be arm64-apple-macos15.0")

    raw_paths = _mapping(manifest.get("paths"), "paths")
    if set(raw_paths) != _PATH_KEYS:
        missing = sorted(_PATH_KEYS - set(raw_paths))
        extra = sorted(set(raw_paths) - _PATH_KEYS)
        raise CorePackageError(f"core package path keys differ: missing={missing} extra={extra}")
    paths: dict[str, str] = {}
    physical_paths: dict[str, Path] = {}
    for key in sorted(_PATH_KEYS):
        relative, physical = _directory(root, raw_paths[key], f"paths.{key}")
        paths[key] = relative
        physical_paths[key] = physical
    manifest["paths"] = paths

    raw_manifests = _mapping(manifest.get("manifests"), "manifests")
    if not raw_manifests:
        raise CorePackageError("manifests must not be empty")
    missing_manifests = sorted(_REQUIRED_MANIFESTS - set(raw_manifests))
    if missing_manifests:
        raise CorePackageError(
            "core package omits required manifests: " + ", ".join(missing_manifests)
        )
    verified_manifests: dict[str, dict[str, str]] = {}
    seen_manifest_paths: set[str] = set()
    manifest_files: dict[str, Path] = {}
    for name in sorted(raw_manifests):
        if not isinstance(name, str) or not name or any(
            character in name for character in ("\0", "\r", "\n", "\t")
        ):
            raise CorePackageError(f"unsafe manifest record name: {name!r}")
        record = _mapping(raw_manifests[name], f"manifests.{name}")
        if set(record) != {"path", "sha256"}:
            raise CorePackageError(
                f"manifests.{name} must contain exactly path and sha256"
            )
        relative, physical = _regular_file(
            root, record.get("path"), f"manifests.{name}.path"
        )
        if relative in seen_manifest_paths:
            raise CorePackageError(f"duplicate manifest path: {relative}")
        seen_manifest_paths.add(relative)
        expected = _string(record.get("sha256"), f"manifests.{name}.sha256")
        if not _SHA256.fullmatch(expected):
            raise CorePackageError(
                f"manifests.{name}.sha256 is not lowercase SHA-256"
            )
        actual = _sha256(physical)
        if actual != expected:
            raise CorePackageError(f"core package manifest changed: {relative}")
        verified_manifests[name] = {"path": relative, "sha256": actual}
        manifest_files[name] = physical
    sdk_tree_path = manifest_files.get("sdk_tree")
    if sdk_tree_path is None:
        raise CorePackageError("manifests.sdk_tree is required")
    published_sdk_tree = sdk_tree_path.read_bytes()
    actual_sdk_tree = _sdk_tree_ledger(physical_paths["sdk"], paths["sdk"])
    if published_sdk_tree != actual_sdk_tree:
        raise CorePackageError(
            "packaged SDK tree differs from manifests.sdk_tree ledger"
        )
    manifest["manifests"] = verified_manifests

    for relative in (
        "system_colors.json",
        "font_metrics.json",
        "fonts/DejaVuSans.ttf",
        "fonts/DejaVuSans-Bold.ttf",
    ):
        required = physical_paths["resources"] / relative
        if required.is_symlink() or not required.is_file() or required.stat().st_size == 0:
            raise CorePackageError(f"required OpenUIKit resource is missing: {required}")
    for relative in ("machorun", ".manifest"):
        required = physical_paths["guest_root"] / relative
        if required.is_symlink() or not required.is_file() or required.stat().st_size == 0:
            raise CorePackageError(f"required guest-root file is missing: {required}")

    manifest["swift_compile_arguments"] = _arguments(
        manifest.get("swift_compile_arguments"),
        "swift_compile_arguments",
        _CONTROLLED_COMPILE_OPTIONS,
    )
    _require_coreimage_compile_contract(manifest["swift_compile_arguments"])
    _require_cross_import_compile_contract(manifest["swift_compile_arguments"])
    manifest["executable_link_arguments"] = _arguments(
        manifest.get("executable_link_arguments"),
        "executable_link_arguments",
        _CONTROLLED_LINK_OPTIONS,
    )
    if manifest["executable_link_arguments"].count("-Llib") != 1:
        raise CorePackageError("executable_link_arguments must contain -Llib exactly once")
    for required in _REQUIRED_FRAMEWORK_LINK_ARGUMENTS:
        if manifest["executable_link_arguments"].count(required) != 1:
            raise CorePackageError(
                "executable_link_arguments must contain required framework exactly once: "
                + required
            )

    artifacts = _array(manifest.get("artifacts"), "artifacts")
    if not artifacts:
        raise CorePackageError("artifacts must not be empty")
    seen: set[str] = set()
    verified_artifacts: list[dict[str, Any]] = []
    artifact_records: dict[str, dict[str, Any]] = {}
    for index, raw in enumerate(artifacts):
        artifact = _mapping(raw, f"artifacts[{index}]")
        relative, physical = _regular_file(
            root, artifact.get("path"), f"artifacts[{index}].path"
        )
        if relative in seen:
            raise CorePackageError(f"duplicate artifact path: {relative}")
        seen.add(relative)
        expected = _string(artifact.get("sha256"), f"artifacts[{index}].sha256")
        if not _SHA256.fullmatch(expected):
            raise CorePackageError(f"artifacts[{index}].sha256 is not lowercase SHA-256")
        actual = _sha256(physical)
        if actual != expected:
            raise CorePackageError(f"core package artifact changed: {relative}")
        size = artifact.get("size")
        if not isinstance(size, int) or isinstance(size, bool) or size < 0:
            raise CorePackageError(f"artifacts[{index}].size must be a nonnegative integer")
        if physical.stat().st_size != size:
            raise CorePackageError(f"core package artifact size changed: {relative}")
        category = _string(artifact.get("category"), f"artifacts[{index}].category")
        role = _string(artifact.get("role"), f"artifacts[{index}].role")
        name = _string(artifact.get("name"), f"artifacts[{index}].name")
        artifact_records[relative] = {
            "category": category,
            "name": name,
            "role": role,
            "sha256": actual,
        }
        verified_artifacts.append({"path": relative, "sha256": actual, "size": size})
    manifest["artifacts"] = verified_artifacts

    raw_plugins = _array(manifest.get("compiler_plugins"), "compiler_plugins")
    if not raw_plugins:
        raise CorePackageError("compiler_plugins must not be empty")
    dependency_paths = sorted(
        path
        for path, record in artifact_records.items()
        if record["category"] == "host-tool" and record["role"] == "dependency"
    )
    seen_plugin_modules: set[str] = set()
    seen_plugin_paths: set[str] = set()
    verified_plugins: list[dict[str, Any]] = []
    for index, raw_plugin in enumerate(raw_plugins):
        plugin = _mapping(raw_plugin, f"compiler_plugins[{index}]")
        required_keys = {
            "module", "load_kind", "path", "sha256", "registrations",
            "consumer_scopes", "serialized_jobs", "host_closure",
        }
        if set(plugin) != required_keys:
            raise CorePackageError(
                f"compiler_plugins[{index}] keys differ: "
                f"missing={sorted(required_keys - set(plugin))} "
                f"extra={sorted(set(plugin) - required_keys)}"
            )
        module = _string(plugin.get("module"), f"compiler_plugins[{index}].module")
        if not module.isidentifier() or module in seen_plugin_modules:
            raise CorePackageError(f"unsafe or duplicate compiler plugin module: {module}")
        seen_plugin_modules.add(module)
        kind = _string(plugin.get("load_kind"), f"compiler_plugins[{index}].load_kind")
        if kind not in ("library", "executable"):
            raise CorePackageError(f"unsupported compiler plugin load kind: {kind}")
        plugin_relative, _plugin_file = _regular_file(
            root, plugin.get("path"), f"compiler_plugins[{index}].path"
        )
        if plugin_relative in seen_plugin_paths:
            raise CorePackageError(f"duplicate compiler plugin path: {plugin_relative}")
        seen_plugin_paths.add(plugin_relative)
        plugin_digest = _string(
            plugin.get("sha256"), f"compiler_plugins[{index}].sha256"
        )
        record = artifact_records.get(plugin_relative)
        if (
            record is None
            or record["category"] != "host-tool"
            or record["role"] != "plugin"
            or record["sha256"] != plugin_digest
        ):
            raise CorePackageError(
                f"compiler plugin artifact/hash differs: {plugin_relative}"
            )
        registrations = _array(
            plugin.get("registrations"), f"compiler_plugins[{index}].registrations"
        )
        if (
            not registrations
            or not all(isinstance(value, str) and value.isidentifier() for value in registrations)
            or registrations != sorted(set(registrations))
        ):
            raise CorePackageError(f"{module} registrations are malformed or unsorted")
        scopes = _array(
            plugin.get("consumer_scopes"), f"compiler_plugins[{index}].consumer_scopes"
        )
        if scopes != ["app", "framework", "package"]:
            raise CorePackageError(
                f"{module} consumer scopes must be app,framework,package"
            )
        serialized = plugin.get("serialized_jobs")
        if not isinstance(serialized, bool):
            raise CorePackageError(f"{module} serialized_jobs must be Boolean")
        raw_closure = _array(
            plugin.get("host_closure"), f"compiler_plugins[{index}].host_closure"
        )
        verified_closure: list[dict[str, str]] = []
        for closure_index, raw_item in enumerate(raw_closure):
            item = _mapping(
                raw_item,
                f"compiler_plugins[{index}].host_closure[{closure_index}]",
            )
            if set(item) != {"path", "sha256"}:
                raise CorePackageError(f"{module} host closure record keys drifted")
            relative, _physical = _regular_file(
                root,
                item.get("path"),
                f"compiler_plugins[{index}].host_closure[{closure_index}].path",
            )
            digest = _string(
                item.get("sha256"),
                f"compiler_plugins[{index}].host_closure[{closure_index}].sha256",
            )
            closure_record = artifact_records.get(relative)
            if (
                closure_record is None
                or closure_record["category"] != "host-tool"
                or closure_record["role"] != "dependency"
                or closure_record["sha256"] != digest
            ):
                raise CorePackageError(f"{module} host closure differs: {relative}")
            verified_closure.append({"path": relative, "sha256": digest})
        if [item["path"] for item in verified_closure] != dependency_paths:
            raise CorePackageError(f"{module} native host closure is incomplete")
        option = "-load-plugin-library" if kind == "library" else "-load-plugin-executable"
        value = plugin_relative if kind == "library" else f"{plugin_relative}#{module}"
        occurrences = sum(
            manifest["swift_compile_arguments"][cursor : cursor + 2]
            == [option, value]
            for cursor in range(len(manifest["swift_compile_arguments"]) - 1)
        )
        if occurrences != 1:
            raise CorePackageError(
                f"{module} compiler plugin load pair count {occurrences}, expected 1"
            )
        verified_plugins.append(
            {
                "module": module,
                "load_kind": kind,
                "path": plugin_relative,
                "sha256": plugin_digest,
                "registrations": registrations,
                "consumer_scopes": scopes,
                "serialized_jobs": serialized,
                "host_closure": verified_closure,
            }
        )
    missing_plugins = sorted(_REQUIRED_COMPILER_PLUGIN_MODULES - seen_plugin_modules)
    if missing_plugins:
        raise CorePackageError(
            "core package omits required compiler plugins: " + ", ".join(missing_plugins)
        )
    compiler_plugin_manifest = manifest_files.get("compiler_plugins")
    if compiler_plugin_manifest is None:
        raise CorePackageError("manifests.compiler_plugins is required")
    expected_plugin_lines = ["format\tcore-compiler-plugins-v1"]
    for plugin in verified_plugins:
        expected_plugin_lines.append(
            "\t".join(
                (
                    "plugin",
                    plugin["module"],
                    plugin["load_kind"],
                    plugin["path"],
                    plugin["sha256"],
                    ",".join(plugin["registrations"]),
                    ",".join(plugin["consumer_scopes"]),
                    "serialized=yes" if plugin["serialized_jobs"] else "serialized=no",
                )
            )
        )
    for plugin in verified_plugins:
        for item in plugin["host_closure"]:
            expected_plugin_lines.append(
                "\t".join(
                    ("closure", plugin["module"], item["path"], item["sha256"])
                )
            )
    expected_plugin_payload = "\n".join(expected_plugin_lines) + "\n"
    try:
        actual_plugin_payload = compiler_plugin_manifest.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise CorePackageError(f"cannot read compiler-plugin manifest: {exc}") from exc
    if actual_plugin_payload != expected_plugin_payload:
        raise CorePackageError(
            "compiler_plugins JSON differs from manifests.compiler_plugins"
        )
    manifest["compiler_plugins"] = verified_plugins

    preview = manifest.get("preview")
    if preview is not None:
        preview = _mapping(preview, "preview")
        if _string(preview.get("plugin_module"), "preview.plugin_module") != "OpenUIKitPreviewMacros":
            raise CorePackageError("preview.plugin_module must be OpenUIKitPreviewMacros")
        plugin_sha = _string(preview.get("plugin_sha256"), "preview.plugin_sha256")
        if not _SHA256.fullmatch(plugin_sha):
            raise CorePackageError("preview.plugin_sha256 is not lowercase SHA-256")
        object_relative, _object = _regular_file(
            root,
            preview.get("developer_tools_support_object"),
            "preview.developer_tools_support_object",
        )
        object_path = PurePosixPath(object_relative)
        objects_path = PurePosixPath(paths["objects"])
        try:
            object_path.relative_to(objects_path)
        except ValueError as exc:
            raise CorePackageError(
                "DeveloperToolsSupport object is outside paths.objects"
            ) from exc
        diagnostic_arguments = _arguments(
            preview.get("app_compile_diagnostic_arguments"),
            "preview.app_compile_diagnostic_arguments",
            set(),
        )
        if diagnostic_arguments != _PREVIEW_DIAGNOSTIC_ARGUMENTS:
            raise CorePackageError(
                "preview.app_compile_diagnostic_arguments must request the exact "
                "bounded macro-expansion dump"
            )
        preview = {
            "app_compile_diagnostic_arguments": diagnostic_arguments,
            "developer_tools_support_object": object_relative,
            "plugin_module": "OpenUIKitPreviewMacros",
            "plugin_sha256": plugin_sha,
        }
    manifest["preview"] = preview
    for token in manifest["executable_link_arguments"]:
        if token.startswith("@") and not token.startswith(
            ("@executable_path", "@loader_path", "@rpath")
        ):
            raise CorePackageError(
                f"executable_link_arguments contains an opaque response input: {token}"
            )
        if preview is not None and preview["developer_tools_support_object"] in token:
            raise CorePackageError(
                "executable_link_arguments must not link DeveloperToolsSupport; "
                "the application driver owns that object exactly once"
            )

    required_artifacts = {
        f"{paths['modules']}/{module}.swiftmodule"
        for module in _REQUIRED_FRAMEWORKS
    }
    required_artifacts.update(
        f"{paths['libraries']}/lib{module}.dylib"
        for module in _REQUIRED_FRAMEWORKS
    )
    required_artifacts.update(
        {
            f"{paths['includes']}/CoreImage/CoreImage.h",
            f"{paths['includes']}/CoreImage/CIFilterBuiltins.h",
            f"{paths['includes']}/CoreImage/module.modulemap",
        }
    )
    if preview is not None:
        required_artifacts.add(
            f"{paths['modules']}/DeveloperToolsSupport.swiftmodule"
        )
        required_artifacts.add(preview["developer_tools_support_object"])
    for directory_key in ("libraries", "resources", "host_tools"):
        directory = physical_paths[directory_key]
        for candidate in directory.rglob("*"):
            if candidate.is_symlink():
                raise CorePackageError(
                    f"paths.{directory_key} contains a symlink: {candidate}"
                )
            if candidate.is_file():
                required_artifacts.add(candidate.relative_to(root).as_posix())
            elif not candidate.is_dir():
                raise CorePackageError(
                    f"paths.{directory_key} contains an unsupported node: {candidate}"
                )
    missing_artifacts = sorted(required_artifacts - seen)
    if missing_artifacts:
        raise CorePackageError(
            "core package does not attest every required artifact: "
            + ", ".join(missing_artifacts)
        )
    return root, manifest


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package_root", type=Path)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--emit-swift-arguments", action="store_true")
    group.add_argument("--emit-link-arguments", action="store_true")
    group.add_argument("--emit-app-diagnostic-arguments", action="store_true")
    group.add_argument("--emit-summary", action="store_true")
    parser.add_argument(
        "--absolute-package-paths",
        action="store_true",
        help="root path-bearing Swift arguments at the validated package root",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _parser()
    arguments = parser.parse_args(argv)
    if arguments.absolute_package_paths and not arguments.emit_swift_arguments:
        parser.error("--absolute-package-paths requires --emit-swift-arguments")
    try:
        root, manifest = validate(arguments.package_root)
        if arguments.emit_swift_arguments:
            values = manifest["swift_compile_arguments"]
            if arguments.absolute_package_paths:
                values = rooted_swift_compile_arguments(root, values)
            sys.stdout.buffer.write(
                b"".join(token.encode("utf-8") + b"\0" for token in values)
            )
        elif arguments.emit_link_arguments:
            sys.stdout.buffer.write(
                b"".join(token.encode("utf-8") + b"\0" for token in manifest["executable_link_arguments"])
            )
        elif arguments.emit_app_diagnostic_arguments:
            preview = manifest["preview"]
            values = preview["app_compile_diagnostic_arguments"] if preview else []
            sys.stdout.buffer.write(
                b"".join(token.encode("utf-8") + b"\0" for token in values)
            )
        else:
            print(
                "CORE_GUEST_PACKAGE_OK "
                f"target={manifest['target']['triple']} "
                f"artifacts={len(manifest['artifacts'])} "
                f"preview={'yes' if manifest['preview'] is not None else 'no'} "
                f"root={root}"
            )
    except (CorePackageError, OSError, KeyError, TypeError) as exc:
        print(f"core-guest-package: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
