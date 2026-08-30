#!/usr/bin/env python3
"""Freeze every application compile/package input from an xcodeplan inventory.

This is the bridge between project discovery and a Linux-hosted compiler.  It
does not edit the application tree.  It verifies and records the complete
ordered Swift source set, recursively records every resource byte, and emits
the generated single-scene entry point into a new output directory.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import stat
import sys
from typing import Any

import scene_bootstrap


class BuildPlanError(RuntimeError):
    """The inventory cannot become an exact portable application build."""


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


def _source_records(inventory: dict[str, Any], root: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, raw in enumerate(_list(inventory.get("sources"), "sources")):
        entry = _mapping(raw, f"sources[{index}]")
        value = _string(entry.get("path"), f"sources[{index}].path")
        if value in seen:
            raise BuildPlanError(f"duplicate source path: {value}")
        seen.add(value)
        if not value.lower().endswith(".swift"):
            raise BuildPlanError(
                f"non-Swift application source needs a compiler provider: {value}"
            )
        records.append(_file_record(root, value, f"sources[{index}].path"))
    if not records:
        raise BuildPlanError("inventory contains no Swift sources")
    return records


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

    sources = _source_records(inventory, root)
    resources = _resource_records(inventory, root)
    target = _mapping(inventory.get("target"), "target")
    result = {
        "bootstrap": bootstrap,
        "bundle_identifier": _bundle_identifier(inventory),
        "classification": "portable-application-build-plan",
        "format_version": 1,
        "module": bootstrap["module"],
        "product_name": _string(target.get("product_name"), "target.product_name"),
        "resources": resources,
        "sources": sources,
        "summary": {
            "resource_inputs": len(resources),
            "resource_files": sum(
                1 if item["kind"] == "file" else len(item["files"])
                for item in resources
            ),
            "swift_sources": len(sources),
        },
    }
    return generated, result


def verify(build_plan: dict[str, Any], source_root: Path) -> None:
    if build_plan.get("classification") != "portable-application-build-plan":
        raise BuildPlanError("input is not a portable application build plan")
    if build_plan.get("format_version") != 1:
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

    bootstrap = _mapping(build_plan.get("bootstrap"), "build plan bootstrap")
    info_plist = _mapping(bootstrap.get("info_plist"), "build plan bootstrap.info_plist")
    info_path = _string(info_plist.get("path"), "build plan bootstrap.info_plist.path")
    info_record = _file_record(root, info_path, "build plan bootstrap.info_plist.path")
    if info_record["sha256"] != info_plist.get("sha256"):
        raise BuildPlanError(f"application Info.plist changed after planning: {info_path}")


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
        (output / "prepared-inputs.json").write_bytes(
            _canonical_json(
                {
                    "GeneratedSceneBootstrap.swift": _sha256(generated),
                    "application-build-plan.json": _sha256(plan_bytes),
                    "app-sources.nul": _sha256((output / "app-sources.nul").read_bytes()),
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
            f"resource_files={build_plan['summary']['resource_files']} "
            f"sha256={_sha256(_canonical_json(build_plan))}"
        )
    except (BuildPlanError, OSError, json.JSONDecodeError) as exc:
        print(f"application-build-plan: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
