#!/usr/bin/env python3
"""Freeze every application compile/package input from an xcodeplan inventory.

This is the bridge between project discovery and a Linux-hosted compiler.  It
does not edit the application tree.  It verifies and records the complete
ordered Swift source set, recursively records every resource byte, and emits
the generated single-scene entry point into a new output directory.  Supported
non-Swift compiler inputs remain a separate, provider-owned graph.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import stat
import sys
import unicodedata
from typing import Any

import scene_bootstrap


class BuildPlanError(RuntimeError):
    """The inventory cannot become an exact portable application build."""


_INTENTDEFINITION_PROVIDER = "open-intentdefinition"


def _mapping(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise BuildPlanError(f"{label} must be an object")
    return value


def _list(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise BuildPlanError(f"{label} must be an array")
    return value


def _string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise BuildPlanError(f"{label} must be a non-empty string")
    if "\n" in value or "\r" in value or "\0" in value:
        raise BuildPlanError(f"{label} contains a forbidden control character")
    return value


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _canonical_json(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode(
        "utf-8"
    )


def _relative(value: str, label: str) -> PurePosixPath:
    relative = PurePosixPath(value)
    if relative.is_absolute() or not relative.parts or any(
        part in ("", ".", "..") for part in relative.parts
    ):
        raise BuildPlanError(f"{label} is not a safe relative path: {value!r}")
    return relative


def _normalized_relative(value: str, label: str) -> PurePosixPath:
    relative = _relative(value, label)
    if relative.as_posix() != value:
        raise BuildPlanError(f"{label} is not a normalized relative path: {value!r}")
    return relative


def _materialized(root: Path, value: str, label: str) -> Path:
    relative = _relative(value, label)
    current = root
    for component in relative.parts:
        current = current / component
        try:
            metadata = current.lstat()
        except OSError as exc:
            raise BuildPlanError(f"cannot inspect {label}: {current}: {exc}") from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise BuildPlanError(f"{label} traverses a symlink: {current}")
        if current != root / relative and not stat.S_ISDIR(metadata.st_mode):
            raise BuildPlanError(f"{label} parent is not a directory: {current}")
    try:
        current.resolve(strict=True).relative_to(root)
    except (OSError, ValueError) as exc:
        raise BuildPlanError(f"{label} escapes the source root: {current}") from exc
    return current


def _file_record(root: Path, value: str, label: str) -> dict[str, Any]:
    path = _materialized(root, value, label)
    metadata = path.lstat()
    if not stat.S_ISREG(metadata.st_mode):
        raise BuildPlanError(f"{label} is not a regular file: {path}")
    data = path.read_bytes()
    return {"path": value, "sha256": _sha256(data), "size": len(data)}


def _resource_record(root: Path, value: str, label: str) -> dict[str, Any]:
    path = _materialized(root, value, label)
    metadata = path.lstat()
    if stat.S_ISREG(metadata.st_mode):
        return {"kind": "file", **_file_record(root, value, label)}
    if not stat.S_ISDIR(metadata.st_mode):
        raise BuildPlanError(f"{label} is not a regular file or directory: {path}")

    files: list[dict[str, Any]] = []
    directories: list[str] = []

    def visit(directory: Path, relative: PurePosixPath) -> None:
        entries = sorted(os.scandir(directory), key=lambda item: item.name.encode("utf-8"))
        if not entries:
            directories.append(relative.as_posix())
        for entry in entries:
            child_relative = relative / entry.name
            if entry.is_symlink():
                raise BuildPlanError(f"{label} contains a symlink: {child_relative}")
            if entry.is_dir(follow_symlinks=False):
                visit(Path(entry.path), child_relative)
            elif entry.is_file(follow_symlinks=False):
                data = Path(entry.path).read_bytes()
                files.append(
                    {
                        "path": child_relative.as_posix(),
                        "sha256": _sha256(data),
                        "size": len(data),
                    }
                )
            else:
                raise BuildPlanError(
                    f"{label} contains an unsupported filesystem node: {child_relative}"
                )

    visit(path, PurePosixPath(value))
    return {
        "empty_directories": directories,
        "files": files,
        "kind": "directory",
        "path": value,
    }


def _intentdefinition_record(
    root: Path, logical_value: str, physical_values: list[str], label: str
) -> dict[str, Any]:
    logical = _normalized_relative(logical_value, f"{label}.logical_path")
    if logical.suffix != ".intentdefinition":
        raise BuildPlanError(
            f"{label}.logical_path is not an .intentdefinition: {logical_value}"
        )
    if not physical_values:
        raise BuildPlanError(f"{label} has no physical input files")

    paths = [
        _normalized_relative(value, f"{label}.input_files[{index}].path")
        for index, value in enumerate(physical_values)
    ]
    portable_paths = [
        unicodedata.normalize("NFC", path.as_posix().casefold()) for path in paths
    ]
    if len(set(portable_paths)) != len(portable_paths):
        raise BuildPlanError(f"{label} contains duplicate or aliased physical paths")

    direct = len(paths) == 1 and paths[0] == logical
    if direct:
        primary = paths[0]
    else:
        primary_candidates = [
            path for path in paths if path.suffix == ".intentdefinition"
        ]
        if len(primary_candidates) != 1:
            raise BuildPlanError(
                f"{label} must contain exactly one physical .intentdefinition"
            )
        primary = primary_candidates[0]
        if paths[0] != primary:
            raise BuildPlanError(
                f"{label} physical .intentdefinition must be the first variant"
            )
        expected_strings_name = f"{logical.stem}.strings"
        seen_localizations: set[str] = set()
        for index, path in enumerate(paths):
            if len(path.parts) < 2 or path.parent.parent != logical.parent:
                raise BuildPlanError(
                    f"{label}.input_files[{index}] is not an immediate localized sibling"
                )
            localization = path.parent.name
            if not localization.endswith(".lproj") or localization == ".lproj":
                raise BuildPlanError(
                    f"{label}.input_files[{index}] is not inside an .lproj directory"
                )
            localization_key = unicodedata.normalize("NFC", localization.casefold())
            if localization_key in seen_localizations:
                raise BuildPlanError(
                    f"{label} repeats localization directory {localization!r}"
                )
            seen_localizations.add(localization_key)
            expected_name = logical.name if index == 0 else expected_strings_name
            if path.name != expected_name:
                raise BuildPlanError(
                    f"{label}.input_files[{index}] has unsupported localized name: "
                    f"{path.name!r}, expected {expected_name!r}"
                )
            if index > 0 and path.suffix != ".strings":
                raise BuildPlanError(
                    f"{label}.input_files[{index}] is not an ordered .strings input"
                )

    input_files = [
        _file_record(root, path.as_posix(), f"{label}.input_files[{index}].path")
        for index, path in enumerate(paths)
    ]
    return {
        "provider": _INTENTDEFINITION_PROVIDER,
        "logical_path": logical.as_posix(),
        "primary_path": primary.as_posix(),
        "input_files": input_files,
    }


def _compiler_input_record(
    entry: dict[str, Any], index: int, root: Path
) -> dict[str, Any]:
    label = f"sources[{index}]"
    logical_value = _string(entry.get("path"), f"{label}.path")
    logical = _normalized_relative(logical_value, f"{label}.path")
    if logical.suffix != ".intentdefinition":
        raise BuildPlanError(
            f"non-Swift application source needs a compiler provider: {logical_value}"
        )
    raw_variants = entry.get("variant_paths")
    if raw_variants is None:
        physical_values = [logical.as_posix()]
    else:
        physical_values = [
            _string(raw, f"{label}.variant_paths[{variant_index}]")
            for variant_index, raw in enumerate(
                _list(raw_variants, f"{label}.variant_paths")
            )
        ]
        if not physical_values:
            raise BuildPlanError(f"{label}.variant_paths must not be empty")
    return _intentdefinition_record(root, logical.as_posix(), physical_values, label)


def _source_records(
    inventory: dict[str, Any], root: Path
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    records: list[dict[str, Any]] = []
    compiler_inputs: list[dict[str, Any]] = []
    seen: set[str] = set()
    seen_portable: set[str] = set()
    seen_compiler_files: set[str] = set()
    for index, raw in enumerate(_list(inventory.get("sources"), "sources")):
        entry = _mapping(raw, f"sources[{index}]")
        value = _string(entry.get("path"), f"sources[{index}].path")
        if value in seen:
            raise BuildPlanError(f"duplicate source path: {value}")
        seen.add(value)
        portable_value = unicodedata.normalize("NFC", value.casefold())
        if portable_value in seen_portable:
            raise BuildPlanError(f"duplicate or aliased source path: {value}")
        seen_portable.add(portable_value)
        if value.lower().endswith(".swift"):
            if "variant_paths" in entry:
                raise BuildPlanError(
                    f"Swift application source cannot be a variant group: {value}"
                )
            records.append(_file_record(root, value, f"sources[{index}].path"))
        else:
            compiler_input = _compiler_input_record(entry, index, root)
            for input_file in compiler_input["input_files"]:
                portable_file = unicodedata.normalize(
                    "NFC", input_file["path"].casefold()
                )
                if portable_file in seen_compiler_files:
                    raise BuildPlanError(
                        "compiler inputs repeat one physical file: "
                        f"{input_file['path']}"
                    )
                seen_compiler_files.add(portable_file)
            compiler_inputs.append(compiler_input)
    if not records:
        raise BuildPlanError("inventory contains no Swift sources")
    return records, compiler_inputs


def _resource_records(inventory: dict[str, Any], root: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    seen: set[str] = set()
    destinations: list[tuple[tuple[str, ...], str]] = []
    for index, raw in enumerate(_list(inventory.get("resources"), "resources")):
        entry = _mapping(raw, f"resources[{index}]")
        value = _string(entry.get("path"), f"resources[{index}].path")
        if value in seen:
            raise BuildPlanError(f"duplicate resource path: {value}")
        seen.add(value)
        destination = _resource_destination(entry, index)
        components = tuple(component.casefold() for component in PurePosixPath(destination).parts)
        for previous_components, previous in destinations:
            shared = min(len(components), len(previous_components))
            if components[:shared] == previous_components[:shared]:
                raise BuildPlanError(
                    "resource bundle destination collision: "
                    f"{previous!r} and {destination!r}"
                )
        destinations.append((components, destination))
        record = _resource_record(root, value, f"resources[{index}].path")
        record["bundle_destination"] = destination
        records.append(record)
    return records


def _resource_destination(entry: dict[str, Any], index: int) -> str:
    """Resolve the bundle-relative destination emitted by xcodeplan.

    Filesystem-synchronised Xcode application groups conventionally carry a
    top-level ``Resources`` directory.  That directory is an organisational
    source root, not a directory inside the application bundle, so preserve
    everything beneath it.  Traditional build-phase entries are copied by
    basename, except localised ``*.lproj`` descendants whose localisation
    directory must remain visible.  The deliberately explicit rule keeps the
    packager deterministic and lets future project frontends publish a direct
    ``bundle_destination`` when their copy semantics are richer.
    """

    explicit = entry.get("bundle_destination")
    if explicit is not None:
        return _relative(
            _string(explicit, f"resources[{index}].bundle_destination"),
            f"resources[{index}].bundle_destination",
        ).as_posix()

    raw_relative = entry.get("relative_path")
    if raw_relative is not None:
        relative = _relative(
            _string(raw_relative, f"resources[{index}].relative_path"),
            f"resources[{index}].relative_path",
        )
        parts = relative.parts
        if len(parts) > 1 and parts[0] == "Resources":
            return PurePosixPath(*parts[1:]).as_posix()
        for offset, component in enumerate(parts):
            if component.endswith(".lproj"):
                return PurePosixPath(*parts[offset:]).as_posix()
        return PurePosixPath(parts[-1]).as_posix()

    source = _relative(
        _string(entry.get("path"), f"resources[{index}].path"),
        f"resources[{index}].path",
    )
    return PurePosixPath(source.parts[-1]).as_posix()


def _bundle_identifier(inventory: dict[str, Any]) -> str | None:
    configuration = _mapping(inventory.get("configuration"), "configuration")
    project = _mapping(configuration.get("project"), "configuration.project")
    target = _mapping(configuration.get("target"), "configuration.target")
    project_settings = _mapping(project.get("build_settings"), "project build_settings")
    target_settings = _mapping(target.get("build_settings"), "target build_settings")
    raw = target_settings.get(
        "PRODUCT_BUNDLE_IDENTIFIER", project_settings.get("PRODUCT_BUNDLE_IDENTIFIER")
    )
    if raw is None:
        return None
    return _string(raw, "PRODUCT_BUNDLE_IDENTIFIER")


def plan(inventory: dict[str, Any], source_root: Path) -> tuple[bytes, dict[str, Any]]:
    try:
        root = scene_bootstrap._strict_root(source_root)
        generated, bootstrap = scene_bootstrap.generate(inventory, root)
    except scene_bootstrap.BootstrapError as exc:
        raise BuildPlanError(str(exc)) from exc

    sources, compiler_inputs = _source_records(inventory, root)
    resources = _resource_records(inventory, root)
    target = _mapping(inventory.get("target"), "target")
    result = {
        "bootstrap": bootstrap,
        "bundle_identifier": _bundle_identifier(inventory),
        "classification": "portable-application-build-plan",
        "compiler_inputs": compiler_inputs,
        "format_version": 2,
        "module": bootstrap["module"],
        "product_name": _string(target.get("product_name"), "target.product_name"),
        "resources": resources,
        "sources": sources,
        "summary": {
            "compiler_input_files": sum(
                len(item["input_files"]) for item in compiler_inputs
            ),
            "compiler_inputs": len(compiler_inputs),
            "resource_inputs": len(resources),
            "resource_files": sum(
                1 if item["kind"] == "file" else len(item["files"])
                for item in resources
            ),
            "swift_sources": len(sources),
        },
    }
    return generated, result


def _verify_bootstrap(
    bootstrap: dict[str, Any],
    build_plan: dict[str, Any],
    sources: list[dict[str, Any]],
    root: Path,
) -> None:
    if bootstrap.get("classification") != "generated-build-input":
        raise BuildPlanError("build plan bootstrap has an invalid classification")
    raw_entry_point = bootstrap.get("entry_point")
    if raw_entry_point is None and {
        "app_delegate",
        "scene_delegate",
    }.issubset(bootstrap):
        # Format-2 UIKit plans created before entry-point classification are
        # still valid. Reparse and verify them under the same strict branch;
        # only the new SwiftUI branch requires an explicit discriminator.
        entry_point = "uikit-scene-bootstrap"
    else:
        entry_point = _string(
            raw_entry_point, "build plan bootstrap.entry_point"
        )
    if entry_point not in {"uikit-scene-bootstrap", "swiftui-app-default-main"}:
        raise BuildPlanError(f"unsupported application entry point: {entry_point}")

    common_keys = {
        "classification",
        "generated_sha256",
        "generated_size",
        "info_plist",
        "inventory_swift_source_count",
        "module",
    }
    if raw_entry_point is not None:
        common_keys.add("entry_point")
    expected_keys = common_keys | (
        {"app_delegate", "scene_delegate"}
        if entry_point == "uikit-scene-bootstrap"
        else {"swiftui_app"}
    )
    if set(bootstrap) != expected_keys:
        raise BuildPlanError("build plan bootstrap schema changed or is inconsistent")
    if bootstrap.get("module") != build_plan.get("module"):
        raise BuildPlanError("build plan bootstrap module is inconsistent")
    if bootstrap.get("inventory_swift_source_count") != len(sources):
        raise BuildPlanError("build plan bootstrap source count is inconsistent")

    source_data: dict[str, bytes] = {}
    parsed_sources: list[tuple[str, Path, bytes, str]] = []
    for index, record in enumerate(sources):
        relative = _string(record.get("path"), f"build plan sources[{index}].path")
        path = _materialized(root, relative, f"build plan sources[{index}].path")
        data = path.read_bytes()
        try:
            masked = scene_bootstrap._mask_swift_noncode(data.decode("utf-8"))
        except (UnicodeDecodeError, scene_bootstrap.BootstrapError) as exc:
            raise BuildPlanError(f"cannot reparse application source: {relative}: {exc}") from exc
        source_data[relative] = data
        parsed_sources.append((relative, path, data, masked))

    try:
        actual_entry, app_name, app_path, app_data = (
            scene_bootstrap._find_application_entry_point(parsed_sources)
        )
    except scene_bootstrap.BootstrapError as exc:
        raise BuildPlanError(str(exc)) from exc
    if actual_entry != entry_point:
        raise BuildPlanError("application entry point changed after planning")

    def verify_source_record(raw: Any, label: str, name: str, path: str, data: bytes) -> None:
        record = _mapping(raw, label)
        if set(record) != {"path", "sha256", "type"}:
            raise BuildPlanError(f"{label} schema changed or is inconsistent")
        expected = {"path": path, "sha256": _sha256(data), "type": name}
        if record != expected or source_data.get(path) != data:
            raise BuildPlanError(f"{label} changed after planning")

    info_plist = _mapping(bootstrap.get("info_plist"), "build plan bootstrap.info_plist")
    if set(info_plist) != {"path", "sha256"}:
        raise BuildPlanError("build plan bootstrap.info_plist schema changed")
    info_path = _string(info_plist.get("path"), "build plan bootstrap.info_plist.path")
    info_record = _file_record(root, info_path, "build plan bootstrap.info_plist.path")
    if info_record["sha256"] != info_plist.get("sha256"):
        raise BuildPlanError(f"application Info.plist changed after planning: {info_path}")
    try:
        plist = _mapping(
            plistlib.loads((root / info_path).read_bytes()),
            "build plan bootstrap Info.plist",
        )
    except (plistlib.InvalidFileException, ValueError) as exc:
        raise BuildPlanError(f"cannot parse build plan Info.plist: {exc}") from exc

    if entry_point == "uikit-scene-bootstrap":
        verify_source_record(
            bootstrap.get("app_delegate"),
            "build plan bootstrap.app_delegate",
            app_name,
            app_path,
            app_data,
        )
        try:
            scene_name = scene_bootstrap._scene_delegate_name(
                plist, _string(bootstrap.get("module"), "build plan bootstrap.module")
            )
            scene_path, scene_data = scene_bootstrap._find_scene_delegate(
                parsed_sources, scene_name
            )
        except scene_bootstrap.BootstrapError as exc:
            raise BuildPlanError(str(exc)) from exc
        verify_source_record(
            bootstrap.get("scene_delegate"),
            "build plan bootstrap.scene_delegate",
            scene_name,
            scene_path,
            scene_data,
        )
        generated = scene_bootstrap._uikit_generated_source(app_name, scene_name)
    else:
        verify_source_record(
            bootstrap.get("swiftui_app"),
            "build plan bootstrap.swiftui_app",
            app_name,
            app_path,
            app_data,
        )
        generated = scene_bootstrap._swiftui_generated_source(app_name)

    if bootstrap.get("generated_size") != len(generated) or bootstrap.get(
        "generated_sha256"
    ) != _sha256(generated):
        raise BuildPlanError("generated bootstrap provenance changed or is inconsistent")


def verify(build_plan: dict[str, Any], source_root: Path) -> None:
    if build_plan.get("classification") != "portable-application-build-plan":
        raise BuildPlanError("input is not a portable application build plan")
    if build_plan.get("format_version") != 2:
        raise BuildPlanError("unsupported application build-plan format_version")
    try:
        root = scene_bootstrap._strict_root(source_root)
    except scene_bootstrap.BootstrapError as exc:
        raise BuildPlanError(str(exc)) from exc

    sources = _list(build_plan.get("sources"), "build plan sources")
    for index, raw in enumerate(sources):
        expected = _mapping(raw, f"build plan sources[{index}]")
        value = _string(expected.get("path"), f"build plan sources[{index}].path")
        actual = _file_record(root, value, f"build plan sources[{index}].path")
        if actual != expected:
            raise BuildPlanError(f"application source changed after planning: {value}")

    compiler_inputs = _list(
        build_plan.get("compiler_inputs"), "build plan compiler_inputs"
    )
    seen_compiler_logical: set[str] = set()
    seen_compiler_files: set[str] = set()
    for index, raw in enumerate(compiler_inputs):
        expected = _mapping(raw, f"build plan compiler_inputs[{index}]")
        provider = _string(
            expected.get("provider"),
            f"build plan compiler_inputs[{index}].provider",
        )
        if provider != _INTENTDEFINITION_PROVIDER:
            raise BuildPlanError(
                f"build plan compiler_inputs[{index}] has unsupported provider: "
                f"{provider}"
            )
        logical = _string(
            expected.get("logical_path"),
            f"build plan compiler_inputs[{index}].logical_path",
        )
        portable_logical = unicodedata.normalize("NFC", logical.casefold())
        if portable_logical in seen_compiler_logical:
            raise BuildPlanError(
                f"build plan repeats compiler input logical path: {logical}"
            )
        seen_compiler_logical.add(portable_logical)
        raw_files = _list(
            expected.get("input_files"),
            f"build plan compiler_inputs[{index}].input_files",
        )
        physical_values = [
            _string(
                _mapping(
                    raw_file,
                    f"build plan compiler_inputs[{index}].input_files[{file_index}]",
                ).get("path"),
                f"build plan compiler_inputs[{index}].input_files[{file_index}].path",
            )
            for file_index, raw_file in enumerate(raw_files)
        ]
        for physical in physical_values:
            portable_file = unicodedata.normalize("NFC", physical.casefold())
            if portable_file in seen_compiler_files:
                raise BuildPlanError(
                    f"build plan repeats physical compiler input: {physical}"
                )
            seen_compiler_files.add(portable_file)
        actual = _intentdefinition_record(
            root,
            logical,
            physical_values,
            f"build plan compiler_inputs[{index}]",
        )
        if actual != expected:
            raise BuildPlanError(
                "application compiler input changed after planning: "
                f"{expected.get('primary_path', logical)}"
            )

    resources = _list(build_plan.get("resources"), "build plan resources")
    for index, raw in enumerate(resources):
        expected = _mapping(raw, f"build plan resources[{index}]")
        value = _string(expected.get("path"), f"build plan resources[{index}].path")
        actual = _resource_record(root, value, f"build plan resources[{index}].path")
        actual["bundle_destination"] = _relative(
            _string(
                expected.get("bundle_destination"),
                f"build plan resources[{index}].bundle_destination",
            ),
            f"build plan resources[{index}].bundle_destination",
        ).as_posix()
        if actual != expected:
            raise BuildPlanError(f"application resource changed after planning: {value}")

    summary = _mapping(build_plan.get("summary"), "build plan summary")
    actual_summary = {
        "compiler_input_files": sum(
            len(_list(item.get("input_files"), "compiler input files"))
            for item in compiler_inputs
        ),
        "compiler_inputs": len(compiler_inputs),
        "resource_inputs": len(resources),
        "resource_files": sum(
            1
            if item.get("kind") == "file"
            else len(_list(item.get("files"), "resource files"))
            for item in resources
        ),
        "swift_sources": len(sources),
    }
    if summary != actual_summary:
        raise BuildPlanError("application build-plan summary changed or is inconsistent")

    bootstrap = _mapping(build_plan.get("bootstrap"), "build plan bootstrap")
    _verify_bootstrap(bootstrap, build_plan, sources, root)


def _write_new_directory(
    output: Path, generated: bytes, build_plan: dict[str, Any], source_root: Path
) -> None:
    root = source_root.resolve(strict=True)
    try:
        output.resolve(strict=False).relative_to(root)
    except ValueError:
        pass
    else:
        raise BuildPlanError("build-plan output must be outside application source root")
    if output.exists() or output.is_symlink():
        raise BuildPlanError(f"output directory already exists: {output}")
    try:
        output.mkdir(mode=0o755, parents=False)
        (output / "GeneratedSceneBootstrap.swift").write_bytes(generated)
        plan_bytes = _canonical_json(build_plan)
        (output / "application-build-plan.json").write_bytes(plan_bytes)
        (output / "app-sources.nul").write_bytes(
            b"".join(item["path"].encode("utf-8") + b"\0" for item in build_plan["sources"])
        )
        (output / "compiler-inputs.nul").write_bytes(
            b"".join(
                input_file["path"].encode("utf-8") + b"\0"
                for compiler_input in build_plan["compiler_inputs"]
                for input_file in compiler_input["input_files"]
            )
        )
        (output / "prepared-inputs.json").write_bytes(
            _canonical_json(
                {
                    "GeneratedSceneBootstrap.swift": _sha256(generated),
                    "application-build-plan.json": _sha256(plan_bytes),
                    "app-sources.nul": _sha256((output / "app-sources.nul").read_bytes()),
                    "compiler-inputs.nul": _sha256(
                        (output / "compiler-inputs.nul").read_bytes()
                    ),
                }
            )
        )
    except Exception:
        # Leave a visible partial directory. Reuse is forbidden, so a failed
        # preparation can never be mistaken for a successful cached plan.
        raise


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inventory", type=Path)
    parser.add_argument("--source-root", required=True, type=Path)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument(
        "--verify",
        action="store_true",
        help="treat INVENTORY as an existing application-build-plan JSON and rehash its source tree",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    try:
        raw = _mapping(
            json.loads(arguments.inventory.read_text(encoding="utf-8")), "inventory"
        )
        if arguments.verify:
            if arguments.output_dir is not None:
                raise BuildPlanError("--verify and --output-dir are mutually exclusive")
            verify(raw, arguments.source_root)
            print(
                f"APPLICATION_BUILD_INPUTS_OK sources={len(raw['sources'])} "
                f"compiler_inputs={len(raw['compiler_inputs'])} "
                f"resources={len(raw['resources'])}"
            )
            return 0
        if arguments.output_dir is None:
            raise BuildPlanError("--output-dir is required when creating a build plan")
        inventory = raw
        generated, build_plan = plan(inventory, arguments.source_root)
        _write_new_directory(
            arguments.output_dir, generated, build_plan, arguments.source_root
        )
        print(
            f"APPLICATION_BUILD_PLAN_OK sources={build_plan['summary']['swift_sources']} "
            f"compiler_inputs={build_plan['summary']['compiler_inputs']} "
            f"resource_files={build_plan['summary']['resource_files']} "
            f"sha256={_sha256(_canonical_json(build_plan))}"
        )
    except (BuildPlanError, OSError, json.JSONDecodeError) as exc:
        print(f"application-build-plan: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
