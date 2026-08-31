#!/usr/bin/env python3
"""Materialize a relocatable macOS-style guest application bundle.

The application and OpenUIKit trees are read-only inputs.  Every byte copied
into ``Contents/Resources`` is checked against the frozen application build
plan (or freshly hashed for platform resources), and output reuse is refused.
The executable and framework closure are installed by the compiler driver in
a later step; this tool owns only the deterministic bundle/resource skeleton.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import stat
import sys
from typing import Any

import application_build_plan

XCASSETS_DIR = Path(__file__).resolve().parents[1] / "xcassets"
if os.fspath(XCASSETS_DIR) not in sys.path:
    sys.path.insert(0, os.fspath(XCASSETS_DIR))
import xcassets_tool  # noqa: E402


class BundleMaterializationError(RuntimeError):
    """A frozen resource graph cannot be represented as an app bundle."""


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _canonical_json(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode(
        "utf-8"
    )


def _safe_relative(value: str, label: str) -> PurePosixPath:
    try:
        return application_build_plan._relative(value, label)
    except application_build_plan.BuildPlanError as exc:
        raise BundleMaterializationError(str(exc)) from exc


def _strict_directory(path: Path, label: str) -> Path:
    try:
        metadata = path.lstat()
    except OSError as exc:
        raise BundleMaterializationError(
            f"cannot inspect {label}: {path}: {exc}"
        ) from exc
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        raise BundleMaterializationError(
            f"{label} is not an ordinary directory: {path}"
        )
    return path.resolve(strict=True)


def _outside_source(output: Path, source_root: Path) -> None:
    try:
        output.resolve(strict=False).relative_to(source_root)
    except ValueError:
        return
    raise BundleMaterializationError(
        "application bundle output must be outside source root"
    )


def _copy_bytes(
    source: Path,
    destination: Path,
    expected_sha256: str | None,
    records: list[dict[str, Any]],
    bundle_root: Path,
    source_class: str,
) -> None:
    if destination.exists() or destination.is_symlink():
        raise BundleMaterializationError(
            f"bundle destination already exists: {destination}"
        )
    destination.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
    data = source.read_bytes()
    digest = _sha256(data)
    if expected_sha256 is not None and digest != expected_sha256:
        raise BundleMaterializationError(f"resource changed after planning: {source}")
    destination.write_bytes(data)
    destination.chmod(0o644)
    copied = destination.read_bytes()
    if copied != data:
        raise BundleMaterializationError(
            f"copied resource differs from input: {destination}"
        )
    records.append(
        {
            "bundle_path": destination.relative_to(bundle_root).as_posix(),
            "sha256": digest,
            "size": len(data),
            "source_class": source_class,
        }
    )


def _copy_application_resources(
    plan: dict[str, Any],
    source_root: Path,
    resources_root: Path,
    bundle_root: Path,
    records: list[dict[str, Any]],
    empty_directories: list[str],
) -> None:
    claimed: set[str] = set()
    for index, raw in enumerate(plan["resources"]):
        resource = application_build_plan._mapping(raw, f"resources[{index}]")
        source_value = application_build_plan._string(
            resource.get("path"), f"resources[{index}].path"
        )
        source_relative = _safe_relative(source_value, f"resources[{index}].path")
        destination_relative = _safe_relative(
            application_build_plan._string(
                resource.get("bundle_destination"),
                f"resources[{index}].bundle_destination",
            ),
            f"resources[{index}].bundle_destination",
        )
        folded = destination_relative.as_posix().casefold()
        if folded == "openuikit" or folded.startswith("openuikit/"):
            raise BundleMaterializationError(
                "application resource collides with reserved OpenUIKit platform resources: "
                f"{destination_relative}"
            )
        if folded in claimed:
            raise BundleMaterializationError(
                f"duplicate bundle resource destination: {destination_relative}"
            )
        claimed.add(folded)
        source = source_root / source_relative
        destination = resources_root / destination_relative
        kind = resource.get("kind")
        if kind == "file":
            _copy_bytes(
                source,
                destination,
                application_build_plan._string(
                    resource.get("sha256"), f"resources[{index}].sha256"
                ),
                records,
                bundle_root,
                "application",
            )
            continue
        if kind != "directory":
            raise BundleMaterializationError(
                f"unsupported resource record kind: {kind!r}"
            )
        destination.mkdir(mode=0o755, parents=True, exist_ok=False)
        for raw_empty in application_build_plan._list(
            resource.get("empty_directories"), f"resources[{index}].empty_directories"
        ):
            empty_source = _safe_relative(
                application_build_plan._string(raw_empty, "empty resource directory"),
                "empty resource directory",
            )
            try:
                suffix = empty_source.relative_to(source_relative)
            except ValueError as exc:
                raise BundleMaterializationError(
                    f"empty resource directory escapes its input: {empty_source}"
                ) from exc
            empty_destination = destination / suffix
            empty_destination.mkdir(mode=0o755, parents=True, exist_ok=True)
            empty_directories.append(
                empty_destination.relative_to(bundle_root).as_posix()
            )
        for file_index, raw_file in enumerate(
            application_build_plan._list(
                resource.get("files"), f"resources[{index}].files"
            )
        ):
            file_record = application_build_plan._mapping(
                raw_file, f"resources[{index}].files[{file_index}]"
            )
            file_relative = _safe_relative(
                application_build_plan._string(
                    file_record.get("path"),
                    f"resources[{index}].files[{file_index}].path",
                ),
                f"resources[{index}].files[{file_index}].path",
            )
            try:
                suffix = file_relative.relative_to(source_relative)
            except ValueError as exc:
                raise BundleMaterializationError(
                    f"resource file escapes its directory input: {file_relative}"
                ) from exc
            _copy_bytes(
                source_root / file_relative,
                destination / suffix,
                application_build_plan._string(
                    file_record.get("sha256"),
                    f"resources[{index}].files[{file_index}].sha256",
                ),
                records,
                bundle_root,
                "application",
            )


def _copy_platform_resources(
    source_root: Path,
    destination_root: Path,
    bundle_root: Path,
    records: list[dict[str, Any]],
    empty_directories: list[str],
) -> None:
    required = {
        "system_colors.json",
        "font_metrics.json",
        "fonts/DejaVuSans.ttf",
        "fonts/DejaVuSans-Bold.ttf",
    }
    found: set[str] = set()

    def visit(source: Path, destination: Path, relative: PurePosixPath) -> None:
        entries = sorted(os.scandir(source), key=lambda item: item.name.encode("utf-8"))
        if not entries:
            destination.mkdir(mode=0o755, parents=True, exist_ok=True)
            empty_directories.append(destination.relative_to(bundle_root).as_posix())
        for entry in entries:
            child_relative = relative / entry.name
            if entry.is_symlink():
                raise BundleMaterializationError(
                    f"OpenUIKit platform resources contain a symlink: {child_relative}"
                )
            if entry.is_dir(follow_symlinks=False):
                visit(Path(entry.path), destination / entry.name, child_relative)
            elif entry.is_file(follow_symlinks=False):
                found.add(child_relative.as_posix())
                _copy_bytes(
                    Path(entry.path),
                    destination / entry.name,
                    None,
                    records,
                    bundle_root,
                    "OpenUIKit-platform",
                )
            else:
                raise BundleMaterializationError(
                    "OpenUIKit platform resources contain an unsupported node: "
                    f"{child_relative}"
                )

    destination_root.mkdir(mode=0o755, parents=True, exist_ok=False)
    visit(source_root, destination_root, PurePosixPath())
    missing = sorted(required - found)
    if missing:
        raise BundleMaterializationError(
            "OpenUIKit platform resource package is incomplete: " + ", ".join(missing)
        )


def _ordered_asset_catalogs(
    plan: dict[str, Any], resources_root: Path
) -> list[Path]:
    """Return materialized catalogs in target build-phase order.

    Most Xcode inventories publish each ``.xcassets`` wrapper as one resource.
    Folder references and SwiftPM resource directories can instead contain one
    or more catalogs, so descend those inputs deterministically but never walk
    inside a catalog.  The resource planner has already rejected overlapping
    destinations and symlinks before this runs.
    """

    catalogs: list[Path] = []

    def visit(directory: Path) -> None:
        if directory.name.endswith(".xcassets"):
            catalogs.append(directory)
            return
        for entry in sorted(
            os.scandir(directory), key=lambda item: item.name.encode("utf-8")
        ):
            if entry.is_symlink():
                raise BundleMaterializationError(
                    f"materialized application resource contains a symlink: {entry.path}"
                )
            if entry.is_dir(follow_symlinks=False):
                visit(Path(entry.path))

    for index, raw in enumerate(plan["resources"]):
        resource = application_build_plan._mapping(raw, f"resources[{index}]")
        if resource.get("kind") != "directory":
            continue
        destination = _safe_relative(
            application_build_plan._string(
                resource.get("bundle_destination"),
                f"resources[{index}].bundle_destination",
            ),
            f"resources[{index}].bundle_destination",
        )
        visit(resources_root / destination)
    return catalogs


def _record_generated_asset_index(
    generated_root: Path,
    bundle_root: Path,
    records: list[dict[str, Any]],
) -> None:
    """Attest every generated index byte and normalize its filesystem modes."""

    for directory, directory_names, file_names in os.walk(generated_root):
        directory_names.sort(key=lambda value: value.encode("utf-8"))
        file_names.sort(key=lambda value: value.encode("utf-8"))
        current = Path(directory)
        current.chmod(0o755)
        for name in directory_names:
            child = current / name
            if child.is_symlink():
                raise BundleMaterializationError(
                    f"generated asset index contains a symlink: {child}"
                )
        for name in file_names:
            child = current / name
            metadata = child.lstat()
            if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISREG(metadata.st_mode):
                raise BundleMaterializationError(
                    f"generated asset index contains an unsupported node: {child}"
                )
            data = child.read_bytes()
            digest = _sha256(data)
            child.chmod(0o644)
            relative = child.relative_to(generated_root)
            if len(relative.parts) == 3 and relative.parts[0] == "Resources":
                shard, filename = relative.parts[1:]
                if shard != digest[:2] or not filename.startswith(digest + "."):
                    raise BundleMaterializationError(
                        f"generated asset payload is not content-addressed: {child}"
                    )
            records.append(
                {
                    "bundle_path": child.relative_to(bundle_root).as_posix(),
                    "sha256": digest,
                    "size": len(data),
                    "source_class": "OpenUIKit-generated-xcassets",
                }
            )


def materialize(
    plan: dict[str, Any],
    source_root: Path,
    platform_resources: Path,
    output_app: Path,
    attestation: Path,
    remote_cache_root: Path | None = None,
) -> dict[str, Any]:
    source_root = _strict_directory(source_root, "application source root")
    platform_resources = _strict_directory(
        platform_resources, "OpenUIKit platform resource root"
    )
    _outside_source(output_app, source_root)
    if output_app.suffix != ".app":
        raise BundleMaterializationError("application bundle output must end in .app")
    if output_app.exists() or output_app.is_symlink():
        raise BundleMaterializationError(
            f"application bundle already exists: {output_app}"
        )
    if attestation.exists() or attestation.is_symlink():
        raise BundleMaterializationError(
            f"attestation output already exists: {attestation}"
        )
    if not output_app.parent.is_dir() or not attestation.parent.is_dir():
        raise BundleMaterializationError(
            "bundle and attestation parents must already exist"
        )

    try:
        application_build_plan.verify(plan, source_root, remote_cache_root)
    except application_build_plan.BuildPlanError as exc:
        raise BundleMaterializationError(str(exc)) from exc

    output_app.mkdir(mode=0o755)
    contents = output_app / "Contents"
    resources = contents / "Resources"
    (contents / "MacOS").mkdir(mode=0o755, parents=True)
    resources.mkdir(mode=0o755)
    (contents / "Frameworks").mkdir(mode=0o755)

    records: list[dict[str, Any]] = []
    empty_directories: list[str] = []
    bootstrap = application_build_plan._mapping(plan.get("bootstrap"), "bootstrap")
    info = application_build_plan._mapping(bootstrap.get("info_plist"), "info_plist")
    info_relative = _safe_relative(
        application_build_plan._string(info.get("path"), "info_plist.path"),
        "info_plist.path",
    )
    _copy_bytes(
        source_root / info_relative,
        contents / "Info.plist",
        application_build_plan._string(info.get("sha256"), "info_plist.sha256"),
        records,
        output_app,
        "application-info",
    )
    _copy_application_resources(
        plan, source_root, resources, output_app, records, empty_directories
    )
    _copy_platform_resources(
        platform_resources,
        resources / "OpenUIKit",
        output_app,
        records,
        empty_directories,
    )

    catalogs = _ordered_asset_catalogs(plan, resources)
    asset_index: dict[str, Any] | None = None
    if catalogs:
        generated_assets = resources / "OpenUIKit" / "AssetCatalogs"
        try:
            asset_index = xcassets_tool.index_catalogs(
                [os.fspath(path) for path in catalogs],
                os.fspath(output_app),
                os.fspath(generated_assets),
            )
        except (OSError, xcassets_tool.Refusal) as exc:
            raise BundleMaterializationError(
                f"cannot compile source-form asset catalogs: {exc}"
            ) from exc
        _record_generated_asset_index(generated_assets, output_app, records)

    records.sort(key=lambda item: item["bundle_path"].encode("utf-8"))
    empty_directories.sort(key=lambda item: item.encode("utf-8"))
    result = {
        "application_build_plan_sha256": _sha256(_canonical_json(plan)),
        "bundle": output_app.name,
        "classification": "portable-application-bundle-materialization",
        "empty_directories": empty_directories,
        "files": records,
        "format_version": 1,
        "summary": {
            "application_files": sum(
                item["source_class"].startswith("application") for item in records
            ),
            "asset_catalog_assets": len(asset_index["assets"])
            if asset_index is not None
            else 0,
            "asset_catalog_files": sum(
                item["source_class"] == "OpenUIKit-generated-xcassets"
                for item in records
            ),
            "asset_catalogs": len(asset_index["catalogs"])
            if asset_index is not None
            else 0,
            "asset_catalog_unresolved": len(asset_index["unresolved"])
            if asset_index is not None
            else 0,
            "empty_directories": len(empty_directories),
            "files": len(records),
            "platform_files": sum(
                item["source_class"] == "OpenUIKit-platform" for item in records
            ),
        },
    }
    attestation.write_bytes(_canonical_json(result))
    return result


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("plan", type=Path)
    parser.add_argument("--source-root", required=True, type=Path)
    parser.add_argument("--platform-resources", required=True, type=Path)
    parser.add_argument("--output-app", required=True, type=Path)
    parser.add_argument("--attestation", required=True, type=Path)
    parser.add_argument("--remote-cache-root", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    try:
        plan = application_build_plan._mapping(
            json.loads(arguments.plan.read_text(encoding="utf-8")), "build plan"
        )
        result = materialize(
            plan,
            arguments.source_root,
            arguments.platform_resources,
            arguments.output_app,
            arguments.attestation,
            arguments.remote_cache_root,
        )
        print(
            "APPLICATION_BUNDLE_RESOURCES_OK "
            f"files={result['summary']['files']} "
            f"application={result['summary']['application_files']} "
            f"platform={result['summary']['platform_files']} "
            f"asset-catalogs={result['summary']['asset_catalogs']} "
            f"asset-records={result['summary']['asset_catalog_assets']}"
        )
    except (
        BundleMaterializationError,
        OSError,
        json.JSONDecodeError,
        KeyError,
        TypeError,
    ) as exc:
        print(f"application-bundle: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
