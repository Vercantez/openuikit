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
}
_CONTROLLED_COMPILE_OPTIONS = {
    "-emit-object",
    "-emit-module",
    "-emit-module-path",
    "-load-plugin-executable",
    "-module-cache-path",
    "-module-name",
    "-o",
}
_CONTROLLED_LINK_OPTIONS = {"-o"}
_ALLOWED_ABSOLUTE_ARGUMENTS = {"/usr/lib", "/usr/lib/swift"}


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
    manifest["executable_link_arguments"] = _arguments(
        manifest.get("executable_link_arguments"),
        "executable_link_arguments",
        _CONTROLLED_LINK_OPTIONS,
    )

    artifacts = _array(manifest.get("artifacts"), "artifacts")
    if not artifacts:
        raise CorePackageError("artifacts must not be empty")
    seen: set[str] = set()
    verified_artifacts: list[dict[str, Any]] = []
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
        verified_artifacts.append({"path": relative, "sha256": actual, "size": size})
    manifest["artifacts"] = verified_artifacts

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
        preview = {
            "developer_tools_support_object": object_relative,
            "plugin_module": "OpenUIKitPreviewMacros",
            "plugin_sha256": plugin_sha,
        }
    manifest["preview"] = preview

    required_artifacts = {
        f"{paths['modules']}/{module}.swiftmodule"
        for module in (
            "FoundationEssentials",
            "OpenCoreGraphics",
            "OpenUIKit",
            "OpenCombine",
            "Combine",
            "Foundation",
            "UIKit",
        )
    }
    required_artifacts.update(
        f"{paths['libraries']}/lib{module}.dylib"
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
    if preview is not None:
        required_artifacts.add(
            f"{paths['modules']}/DeveloperToolsSupport.swiftmodule"
        )
        required_artifacts.add(preview["developer_tools_support_object"])
    for directory_key in ("libraries", "resources"):
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
    group.add_argument("--emit-summary", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    try:
        root, manifest = validate(arguments.package_root)
        if arguments.emit_swift_arguments:
            sys.stdout.buffer.write(
                b"".join(token.encode("utf-8") + b"\0" for token in manifest["swift_compile_arguments"])
            )
        elif arguments.emit_link_arguments:
            sys.stdout.buffer.write(
                b"".join(token.encode("utf-8") + b"\0" for token in manifest["executable_link_arguments"])
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
