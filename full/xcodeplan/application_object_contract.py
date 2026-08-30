#!/usr/bin/env python3
"""Create and verify the portable application's multi-object compile contract."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import stat
import struct
import subprocess
import sys
from typing import Any, Iterable


class ObjectContractError(RuntimeError):
    """The application object or bounded Preview contract is invalid."""


_MACHO_64_MAGIC = 0xFEEDFACF
_CPU_TYPE_ARM64 = 0x0100000C
_MH_OBJECT = 0x1


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _canonical_json(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode(
        "utf-8"
    )


def _safe_text(value: str, label: str) -> str:
    if not value or any(character in value for character in "\0\r\n\t"):
        raise ObjectContractError(f"{label} is empty or contains a control character")
    return value


def _absolute(value: str | Path, label: str) -> Path:
    path = Path(_safe_text(os.fspath(value), label))
    if not path.is_absolute():
        raise ObjectContractError(f"{label} is not absolute: {path}")
    return path


def _ordinary_directory(path: Path, label: str) -> None:
    try:
        metadata = path.lstat()
    except OSError as exc:
        raise ObjectContractError(f"cannot inspect {label}: {path}: {exc}") from exc
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        raise ObjectContractError(f"{label} is not an ordinary directory: {path}")


def _regular(path: Path, label: str) -> None:
    try:
        metadata = path.lstat()
    except OSError as exc:
        raise ObjectContractError(f"cannot inspect {label}: {path}: {exc}") from exc
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISREG(metadata.st_mode):
        raise ObjectContractError(f"{label} is not a regular file: {path}")


def _new_file(path: Path, data: bytes, label: str) -> None:
    _ordinary_directory(path.parent, f"{label} parent")
    try:
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
    except OSError as exc:
        raise ObjectContractError(f"cannot create {label}: {path}: {exc}") from exc
    with os.fdopen(descriptor, "wb") as handle:
        handle.write(data)


def _sources(values: Iterable[str]) -> list[str]:
    sources = [_safe_text(value, f"source[{index}]") for index, value in enumerate(values)]
    if len(sources) < 2:
        raise ObjectContractError("multi-object compilation requires at least two sources")
    if len(set(sources)) != len(sources):
        raise ObjectContractError("multi-object compilation contains duplicate sources")
    for index, source in enumerate(sources):
        path = _absolute(source, f"source[{index}]")
        _regular(path, f"source[{index}]")
    return sources


def _expected_map(object_root: Path, sources: list[str]) -> dict[str, dict[str, str]]:
    return {
        source: {"object": str(object_root / f"{index:06d}.o")}
        for index, source in enumerate(sources)
    }


def create_output_map(
    output_map_value: str | Path,
    object_root_value: str | Path,
    source_values: Iterable[str],
) -> None:
    output_map = _absolute(output_map_value, "output-file map")
    object_root = _absolute(object_root_value, "application object root")
    sources = _sources(source_values)
    if output_map.exists() or output_map.is_symlink():
        raise ObjectContractError(f"output-file map already exists: {output_map}")
    if object_root.exists() or object_root.is_symlink():
        raise ObjectContractError(f"application object root already exists: {object_root}")
    _ordinary_directory(object_root.parent, "application object-root parent")
    try:
        object_root.mkdir(mode=0o755)
    except OSError as exc:
        raise ObjectContractError(
            f"cannot create application object root: {object_root}: {exc}"
        ) from exc
    payload = json.dumps(
        _expected_map(object_root, sources), ensure_ascii=False, indent=2
    ).encode("utf-8") + b"\n"
    _new_file(output_map, payload, "output-file map")


def _reject_duplicate_json_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ObjectContractError(f"duplicate JSON key in output-file map: {key!r}")
        result[key] = value
    return result


def _read_output_map(path: Path) -> dict[str, Any]:
    _regular(path, "output-file map")
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=_reject_duplicate_json_keys,
        )
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ObjectContractError(f"cannot parse output-file map: {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ObjectContractError("output-file map is not a JSON object")
    return value


def _arm64_macho_object(path: Path, label: str) -> None:
    _regular(path, label)
    try:
        header = path.read_bytes()[:32]
    except OSError as exc:
        raise ObjectContractError(f"cannot read {label}: {path}: {exc}") from exc
    if len(header) != 32:
        raise ObjectContractError(f"{label} has a truncated Mach-O header: {path}")
    magic, cpu_type, _cpu_subtype, file_type, *_rest = struct.unpack(
        "<IIIIIIII", header
    )
    if magic != _MACHO_64_MAGIC or cpu_type != _CPU_TYPE_ARM64 or file_type != _MH_OBJECT:
        raise ObjectContractError(f"{label} is not an ARM64 Mach-O object: {path}")


def verify_objects(
    output_map_value: str | Path,
    object_root_value: str | Path,
    audit_value: str | Path,
    source_values: Iterable[str],
    *,
    publish_audit: bool = True,
) -> list[Path]:
    output_map = _absolute(output_map_value, "output-file map")
    object_root = _absolute(object_root_value, "application object root")
    audit = _absolute(audit_value, "application object audit")
    sources = _sources(source_values)
    _ordinary_directory(object_root, "application object root")
    actual_map = _read_output_map(output_map)
    expected_map = _expected_map(object_root, sources)
    if list(actual_map.items()) != list(expected_map.items()):
        raise ObjectContractError("output-file map source/order/object contract drifted")

    expected_names = [f"{index:06d}.o" for index in range(len(sources))]
    try:
        actual_names = sorted(entry.name for entry in os.scandir(object_root))
    except OSError as exc:
        raise ObjectContractError(
            f"cannot enumerate application object root: {object_root}: {exc}"
        ) from exc
    if actual_names != expected_names:
        raise ObjectContractError(
            "application object set is not exhaustive: "
            f"actual={actual_names!r} expected={expected_names!r}"
        )

    objects: list[Path] = []
    records: list[dict[str, Any]] = []
    for index, source in enumerate(sources):
        object_path = object_root / expected_names[index]
        _arm64_macho_object(object_path, f"application object[{index}]")
        objects.append(object_path)
        records.append(
            {
                "index": index,
                "object": str(object_path),
                "sha256": _sha256(object_path),
                "size": object_path.stat().st_size,
                "source": source,
            }
        )
    document = {
        "classification": "portable-application-object-audit",
        "format_version": 1,
        "object_count": len(records),
        "objects": records,
        "output_file_map": {
            "path": str(output_map),
            "sha256": _sha256(output_map),
            "size": output_map.stat().st_size,
        },
    }
    audit_payload = _canonical_json(document)
    if publish_audit:
        _new_file(audit, audit_payload, "application object audit")
    else:
        _regular(audit, "published application object audit")
        if audit.read_bytes() != audit_payload:
            raise ObjectContractError(
                "published application object audit differs from current objects/map"
            )
    return objects


def _read_nul_paths(path: Path, label: str) -> list[str]:
    _regular(path, label)
    try:
        payload = path.read_bytes()
    except OSError as exc:
        raise ObjectContractError(f"cannot read {label}: {path}: {exc}") from exc
    if not payload or not payload.endswith(b"\0"):
        raise ObjectContractError(f"{label} is empty or not NUL terminated")
    raw_values = payload[:-1].split(b"\0")
    if not raw_values or any(not value for value in raw_values):
        raise ObjectContractError(f"{label} contains an empty record")
    values: list[str] = []
    for index, raw in enumerate(raw_values):
        try:
            value = raw.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise ObjectContractError(f"{label}[{index}] is not UTF-8") from exc
        _safe_text(value, f"{label}[{index}]")
        relative = PurePosixPath(value)
        if (
            relative.is_absolute()
            or not relative.parts
            or any(component in ("", ".", "..") for component in relative.parts)
            or relative.as_posix() != value
        ):
            raise ObjectContractError(
                f"{label}[{index}] is not a normalized relative path: {value!r}"
            )
        values.append(value)
    if len(set(values)) != len(values):
        raise ObjectContractError(f"{label} contains duplicate paths")
    return values


def _materialized_source(root: Path, relative_value: str, label: str) -> Path:
    relative = PurePosixPath(relative_value)
    current = root
    for component in relative.parts:
        current /= component
        try:
            metadata = current.lstat()
        except OSError as exc:
            raise ObjectContractError(f"cannot inspect {label}: {current}: {exc}") from exc
        if stat.S_ISLNK(metadata.st_mode):
            raise ObjectContractError(f"{label} traverses a symlink: {current}")
    _regular(current, label)
    try:
        current.resolve(strict=True).relative_to(root.resolve(strict=True))
    except (OSError, ValueError) as exc:
        raise ObjectContractError(f"{label} escapes source root: {current}") from exc
    return current


def validate_preview_sources(
    source_root_value: str | Path,
    application_source_list_value: str | Path,
    preview_source_list_value: str | Path,
    audit_value: str | Path,
) -> list[Path]:
    source_root = _absolute(source_root_value, "application source root")
    application_source_list = _absolute(
        application_source_list_value, "application source list"
    )
    preview_source_list = _absolute(preview_source_list_value, "Preview source list")
    audit = _absolute(audit_value, "Preview source audit")
    _ordinary_directory(source_root, "application source root")
    application_sources = _read_nul_paths(
        application_source_list, "application source list"
    )
    preview_sources = _read_nul_paths(preview_source_list, "Preview source list")
    if len(preview_sources) >= len(application_sources):
        raise ObjectContractError(
            "Preview evidence sources must be a proper subset; "
            "full-module macro dumping is forbidden"
        )
    positions: list[int] = []
    for relative in preview_sources:
        try:
            positions.append(application_sources.index(relative))
        except ValueError as exc:
            raise ObjectContractError(
                f"Preview evidence source is not in the application target: {relative}"
            ) from exc
    if positions != sorted(positions):
        raise ObjectContractError(
            "Preview evidence sources do not preserve application source order"
        )

    paths: list[Path] = []
    records: list[dict[str, Any]] = []
    preview_spelling_count = 0
    for index, relative in enumerate(preview_sources):
        path = _materialized_source(
            source_root, relative, f"Preview evidence source[{index}]"
        )
        payload = path.read_bytes()
        preview_spelling_count += payload.count(b"#Preview")
        paths.append(path)
        records.append(
            {
                "index": index,
                "path": relative,
                "sha256": hashlib.sha256(payload).hexdigest(),
                "size": len(payload),
            }
        )
    if preview_spelling_count < 1:
        raise ObjectContractError("Preview evidence sources contain no #Preview spelling")
    document = {
        "application_source_count": len(application_sources),
        "classification": "portable-preview-evidence-source-audit",
        "format_version": 1,
        "preview_source_count": len(preview_sources),
        "preview_source_list_sha256": _sha256(preview_source_list),
        "preview_spelling_count": preview_spelling_count,
        "sources": records,
    }
    _new_file(audit, _canonical_json(document), "Preview source audit")
    return paths


def _nm_symbols(nm: Path, mode: str, path: Path, label: str) -> set[str]:
    _regular(path, label)
    try:
        result = subprocess.run(
            [
                str(nm),
                mode,
                "--extern-only",
                "--just-symbol-name",
                str(path),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
    except OSError as exc:
        raise ObjectContractError(f"cannot execute llvm-nm: {nm}: {exc}") from exc
    if result.returncode != 0 or result.stderr:
        raise ObjectContractError(
            f"nm failed for {label}: rc={result.returncode} stderr={result.stderr!r}"
        )
    symbols: set[str] = set()
    for line in result.stdout.splitlines():
        if not line:
            continue
        if line != line.strip() or any(character in line for character in "\0\r\t"):
            raise ObjectContractError(f"nm emitted a malformed symbol for {label}: {line!r}")
        symbols.add(line)
    return symbols


def _cross_file_document(nm: Path, objects: list[Path]) -> dict[str, Any]:
    if len(objects) < 2 or len(set(objects)) != len(objects):
        raise ObjectContractError("cross-file audit requires distinct application objects")
    definitions = [
        _nm_symbols(nm, "--defined-only", path, f"application object[{index}]")
        for index, path in enumerate(objects)
    ]
    undefined = [
        _nm_symbols(nm, "--undefined-only", path, f"application object[{index}]")
        for index, path in enumerate(objects)
    ]
    providers: dict[str, list[int]] = {}
    for index, symbols in enumerate(definitions):
        for symbol in symbols:
            providers.setdefault(symbol, []).append(index)
    edges: list[dict[str, Any]] = []
    for consumer, symbols in enumerate(undefined):
        for symbol in sorted(symbols):
            for provider in providers.get(symbol, []):
                if provider != consumer:
                    edges.append(
                        {"consumer": consumer, "provider": provider, "symbol": symbol}
                    )
    edges.sort(key=lambda item: (item["consumer"], item["provider"], item["symbol"]))
    if not edges:
        raise ObjectContractError("application has no measured cross-file symbol edge")
    document = {
        "classification": "portable-application-cross-file-symbol-audit",
        "edge_count": len(edges),
        "edges": edges,
        "format_version": 1,
        "object_count": len(objects),
    }
    return document


def audit_cross_file_symbols(
    nm_value: str | Path, audit_value: str | Path, object_values: Iterable[str]
) -> dict[str, Any]:
    nm = _absolute(nm_value, "llvm-nm")
    _regular(nm, "llvm-nm")
    if not os.access(nm, os.X_OK):
        raise ObjectContractError(f"llvm-nm is not executable: {nm}")
    audit = _absolute(audit_value, "cross-file symbol audit")
    objects = [
        _absolute(value, f"application object[{index}]")
        for index, value in enumerate(object_values)
    ]
    document = _cross_file_document(nm, objects)
    _new_file(audit, _canonical_json(document), "cross-file symbol audit")
    return document


def audit_linked_executable(
    nm_value: str | Path,
    executable_value: str | Path,
    cross_file_audit_value: str | Path,
    audit_value: str | Path,
    object_values: Iterable[str],
) -> dict[str, Any]:
    nm = _absolute(nm_value, "llvm-nm")
    _regular(nm, "llvm-nm")
    if not os.access(nm, os.X_OK):
        raise ObjectContractError(f"llvm-nm is not executable: {nm}")
    executable = _absolute(executable_value, "application executable")
    cross_file_audit = _absolute(cross_file_audit_value, "cross-file symbol audit")
    audit = _absolute(audit_value, "linked executable symbol audit")
    objects = [
        _absolute(value, f"application object[{index}]")
        for index, value in enumerate(object_values)
    ]
    if len(objects) < 2 or len(set(objects)) != len(objects):
        raise ObjectContractError("linked executable audit requires distinct app objects")
    current_cross_file = _cross_file_document(nm, objects)
    _regular(cross_file_audit, "published cross-file symbol audit")
    if cross_file_audit.read_bytes() != _canonical_json(current_cross_file):
        raise ObjectContractError(
            "published cross-file symbol audit differs from current objects"
        )
    internal_references = {
        str(edge["symbol"]) for edge in current_cross_file["edges"]
    }
    executable_undefined = _nm_symbols(
        nm, "--undefined-only", executable, "application executable"
    )
    unresolved = sorted(internal_references & executable_undefined)
    if unresolved:
        raise ObjectContractError(
            f"linked executable retains app-internal undefined symbols: {unresolved!r}"
        )
    document = {
        "classification": "portable-application-linked-symbol-audit",
        "cross_file_edge_count": current_cross_file["edge_count"],
        "executable_sha256": _sha256(executable),
        "format_version": 1,
        "measured_cross_file_symbol_count": len(internal_references),
        "object_count": len(objects),
        "unresolved_internal_symbols": [],
    }
    _new_file(audit, _canonical_json(document), "linked executable symbol audit")
    return document


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    create = commands.add_parser("create-output-map")
    create.add_argument("--output-map", required=True)
    create.add_argument("--object-root", required=True)
    create.add_argument("sources", nargs="+")

    verify = commands.add_parser("verify-objects")
    verify.add_argument("--output-map", required=True)
    verify.add_argument("--object-root", required=True)
    verify.add_argument("--audit", required=True)
    verify.add_argument("sources", nargs="+")

    reverify = commands.add_parser("reverify-objects")
    reverify.add_argument("--output-map", required=True)
    reverify.add_argument("--object-root", required=True)
    reverify.add_argument("--audit", required=True)
    reverify.add_argument("sources", nargs="+")

    preview = commands.add_parser("validate-preview-sources")
    preview.add_argument("--source-root", required=True)
    preview.add_argument("--application-source-list", required=True)
    preview.add_argument("--preview-source-list", required=True)
    preview.add_argument("--audit", required=True)

    cross = commands.add_parser("audit-cross-file-symbols")
    cross.add_argument("--nm", required=True)
    cross.add_argument("--audit", required=True)
    cross.add_argument("objects", nargs="+")

    linked = commands.add_parser("audit-linked-executable")
    linked.add_argument("--nm", required=True)
    linked.add_argument("--executable", required=True)
    linked.add_argument("--cross-file-audit", required=True)
    linked.add_argument("--audit", required=True)
    linked.add_argument("objects", nargs="+")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "create-output-map":
            create_output_map(args.output_map, args.object_root, args.sources)
        elif args.command == "verify-objects":
            objects = verify_objects(
                args.output_map, args.object_root, args.audit, args.sources
            )
            sys.stdout.buffer.write(
                b"".join(os.fsencode(path) + b"\0" for path in objects)
            )
        elif args.command == "reverify-objects":
            verify_objects(
                args.output_map,
                args.object_root,
                args.audit,
                args.sources,
                publish_audit=False,
            )
        elif args.command == "validate-preview-sources":
            paths = validate_preview_sources(
                args.source_root,
                args.application_source_list,
                args.preview_source_list,
                args.audit,
            )
            sys.stdout.buffer.write(
                b"".join(os.fsencode(path) + b"\0" for path in paths)
            )
        elif args.command == "audit-cross-file-symbols":
            audit_cross_file_symbols(args.nm, args.audit, args.objects)
        elif args.command == "audit-linked-executable":
            audit_linked_executable(
                args.nm,
                args.executable,
                args.cross_file_audit,
                args.audit,
                args.objects,
            )
        else:  # pragma: no cover - argparse owns this branch.
            raise AssertionError(args.command)
    except ObjectContractError as exc:
        print(f"application-object-contract: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
