#!/usr/bin/env python3
"""Create and verify the portable application's multi-object compile contract."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
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
_SDK_SETTINGS_WARNING = b"warning: Could not read SDKSettings.json for SDK at: sdk\n"
_MACRO_SEPARATOR = b"------------------------------\n"
_MACRO_HEADER = re.compile(rb"@__swiftmacro_[A-Za-z0-9_$]+\.swift\n")


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


def _canonical_executable(value: str | Path, label: str) -> Path:
    entry = _absolute(value, label)
    try:
        executable = entry.resolve(strict=True)
    except (OSError, RuntimeError) as exc:
        raise ObjectContractError(f"cannot resolve {label}: {entry}: {exc}") from exc
    _regular(executable, label)
    if not os.access(executable, os.X_OK):
        raise ObjectContractError(f"{label} is not executable: {executable}")
    return executable


def _new_file(path: Path, data: bytes, label: str) -> None:
    _ordinary_directory(path.parent, f"{label} parent")
    try:
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
    except OSError as exc:
        raise ObjectContractError(f"cannot create {label}: {path}: {exc}") from exc
    with os.fdopen(descriptor, "wb") as handle:
        handle.write(data)


def _new_directory(path: Path, label: str) -> None:
    if path.exists() or path.is_symlink():
        raise ObjectContractError(f"{label} already exists: {path}")
    _ordinary_directory(path.parent, f"{label} parent")
    try:
        path.mkdir(mode=0o755)
    except OSError as exc:
        raise ObjectContractError(f"cannot create {label}: {path}: {exc}") from exc


def _outside_source_root(source_root: Path, path: Path, label: str) -> None:
    _ordinary_directory(source_root, "application source root")
    _ordinary_directory(path.parent, f"{label} parent")
    try:
        candidate = path.parent.resolve(strict=True) / path.name
        candidate.relative_to(source_root.resolve(strict=True))
    except ValueError:
        return
    except OSError as exc:
        raise ObjectContractError(f"cannot resolve {label}: {path}: {exc}") from exc
    raise ObjectContractError(f"{label} must be outside the application source root")


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
    if preview_spelling_count != 1:
        raise ObjectContractError(
            "Preview evidence sources must contain exactly one #Preview spelling: "
            f"found {preview_spelling_count}"
        )
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


def _read_canonical_json(path: Path, label: str) -> dict[str, Any]:
    _regular(path, label)
    try:
        payload = path.read_bytes()
        value = json.loads(payload, object_pairs_hook=_reject_duplicate_json_keys)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ObjectContractError(f"cannot parse {label}: {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ObjectContractError(f"{label} is not a JSON object")
    if payload != _canonical_json(value):
        raise ObjectContractError(f"{label} is not canonical JSON")
    return value


def _preview_expansion(stderr: Path) -> tuple[bytes, bytes, str, int, int]:
    _regular(stderr, "Preview expansion diagnostic")
    try:
        diagnostic = stderr.read_bytes()
    except OSError as exc:
        raise ObjectContractError(
            f"cannot read Preview expansion diagnostic: {stderr}: {exc}"
        ) from exc
    if not diagnostic or b"\0" in diagnostic or b"\r" in diagnostic:
        raise ObjectContractError(
            "Preview expansion diagnostic is empty or contains a forbidden byte"
        )
    body = diagnostic
    if body.startswith(_SDK_SETTINGS_WARNING):
        body = body[len(_SDK_SETTINGS_WARNING) :]
    if not _MACRO_HEADER.match(body):
        raise ObjectContractError("Preview expansion diagnostic header drifted")
    header_end = body.index(b"\n") + 1
    framed = body[header_end:]
    if framed.count(_MACRO_SEPARATOR) != 2:
        raise ObjectContractError(
            "Preview expansion diagnostic must contain exactly two separators"
        )
    if not framed.startswith(_MACRO_SEPARATOR) or not framed.endswith(_MACRO_SEPARATOR):
        raise ObjectContractError("Preview expansion diagnostic framing drifted")
    expansion = framed[len(_MACRO_SEPARATOR) : -len(_MACRO_SEPARATOR)]
    if not expansion.startswith(b"@available(") or not expansion.endswith(b"}\n"):
        raise ObjectContractError("Preview expansion is not one complete declaration")
    if expansion.count(b"DeveloperToolsSupport.PreviewRegistry") != 1:
        raise ObjectContractError(
            "Preview expansion must contain exactly one PreviewRegistry conformance"
        )
    if expansion.count(
        b"static func makePreview() throws -> DeveloperToolsSupport.Preview"
    ) != 1:
        raise ObjectContractError(
            "Preview expansion must contain exactly one makePreview declaration"
        )
    if b"#Preview" in expansion:
        raise ObjectContractError("Preview expansion recursively contains #Preview")
    file_match = re.search(
        rb'static var fileID: String \{\n[ \t]+"([^"\r\n]+)"\n[ \t]+\}',
        expansion,
    )
    line_match = re.search(
        rb"static var line: Int \{\n[ \t]+([0-9]+)\n[ \t]+\}", expansion
    )
    column_match = re.search(
        rb"static var column: Int \{\n[ \t]+([0-9]+)\n[ \t]+\}", expansion
    )
    if file_match is None or line_match is None or column_match is None:
        raise ObjectContractError("Preview expansion source-location contract drifted")
    try:
        file_id = file_match.group(1).decode("utf-8")
    except UnicodeDecodeError as exc:
        raise ObjectContractError("Preview expansion fileID is not UTF-8") from exc
    line = int(line_match.group(1))
    column = int(column_match.group(1))
    if line < 1 or column < 1:
        raise ObjectContractError("Preview expansion source location is not positive")
    return diagnostic, expansion, file_id, line, column


def _published_preview_source_hash(
    preview_source_audit: Path, relative: str, payload: bytes
) -> None:
    document = _read_canonical_json(preview_source_audit, "Preview source audit")
    if (
        document.get("classification") != "portable-preview-evidence-source-audit"
        or document.get("format_version") != 1
        or document.get("preview_spelling_count") != 1
    ):
        raise ObjectContractError("Preview source audit identity drifted")
    records = document.get("sources")
    if not isinstance(records, list):
        raise ObjectContractError("Preview source audit has no source records")
    matches = [
        record
        for record in records
        if isinstance(record, dict) and record.get("path") == relative
    ]
    if len(matches) != 1:
        raise ObjectContractError(
            "materialized Preview source is not exactly once in the bounded source audit"
        )
    record = matches[0]
    if record.get("sha256") != hashlib.sha256(payload).hexdigest() or record.get(
        "size"
    ) != len(payload):
        raise ObjectContractError("bounded Preview source record differs from source bytes")


def _preview_materialization_expected(
    source_root: Path,
    application_source_list: Path,
    preview_source_audit: Path,
    expansion_stderr: Path,
    output_root: Path,
    compile_source_list: Path,
    module_name: str,
) -> tuple[Path, bytes, bytes, bytes]:
    _ordinary_directory(source_root, "application source root")
    if not module_name.isascii() or not module_name.isidentifier():
        raise ObjectContractError(f"module name is not a portable identifier: {module_name!r}")
    relative_sources = _read_nul_paths(
        application_source_list, "application source list"
    )
    source_paths: list[Path] = []
    preview_candidates: list[tuple[int, str, Path, bytes]] = []
    spelling_count = 0
    for index, relative in enumerate(relative_sources):
        path = _materialized_source(
            source_root, relative, f"application source[{index}]"
        )
        payload = path.read_bytes()
        count = payload.count(b"#Preview")
        spelling_count += count
        if count:
            preview_candidates.append((index, relative, path, payload))
        source_paths.append(path)
    if spelling_count != 1 or len(preview_candidates) != 1:
        raise ObjectContractError(
            "application target must contain exactly one #Preview spelling for "
            f"materialization: found {spelling_count}"
        )
    preview_index, relative, _original_path, original = preview_candidates[0]
    _published_preview_source_hash(preview_source_audit, relative, original)

    marker = b"#Preview {"
    span_offset = original.find(marker)
    if span_offset < 0 or original.find(marker, span_offset + 1) >= 0:
        raise ObjectContractError("terminal Preview declaration spelling drifted")
    line_start = original.rfind(b"\n", 0, span_offset) + 1
    line = original.count(b"\n", 0, span_offset) + 1
    column = span_offset - line_start + 1
    if column != 1 or span_offset != line_start:
        raise ObjectContractError("materialized #Preview must begin at column one")
    span = original[span_offset:]
    if re.fullmatch(rb"#Preview \{\n(?s:.+)\n\}\n", span) is None:
        raise ObjectContractError(
            "materialized #Preview must be one terminal trailing-closure declaration"
        )
    opening = span.index(b"{")
    closing = span.rfind(b"}")
    macro_body = span[opening + 1 : closing].strip()
    if not macro_body or b"\0" in macro_body:
        raise ObjectContractError("materialized #Preview has an empty or invalid body")

    diagnostic, expansion, file_id, expansion_line, expansion_column = (
        _preview_expansion(expansion_stderr)
    )
    expected_file_id = f"{module_name}/{PurePosixPath(relative).name}"
    if file_id != expected_file_id:
        raise ObjectContractError(
            f"Preview expansion fileID {file_id!r}, expected {expected_file_id!r}"
        )
    if expansion_line != line or expansion_column != column:
        raise ObjectContractError(
            "Preview expansion source location differs from the replaced declaration"
        )
    if expansion.count(macro_body) != 1:
        raise ObjectContractError(
            "Preview expansion does not retain the exact trailing-closure body once"
        )

    generated_names = list(
        re.finditer(
            rb"(?m)^struct (\$[A-Za-z0-9_]+): "
            rb"DeveloperToolsSupport\.PreviewRegistry \{$",
            expansion,
        )
    )
    if len(generated_names) != 1 or expansion.count(b"$") != 1:
        raise ObjectContractError(
            "Preview expansion must contain exactly one compiler-generated registry name"
        )
    generated_match = generated_names[0]
    generated_identifier = generated_match.group(1)
    materialized_identifier = (
        "__OpenUIKitMaterializedPreviewRegistry_"
        + hashlib.sha256(expansion).hexdigest()[:32]
    ).encode("ascii")
    if materialized_identifier in original or materialized_identifier in expansion:
        raise ObjectContractError("materialized Preview registry identifier collides")
    identifier_start, identifier_end = generated_match.span(1)
    materialized_expansion = (
        expansion[:identifier_start]
        + materialized_identifier
        + expansion[identifier_end:]
    )
    if materialized_expansion.count(materialized_identifier) != 1:
        raise ObjectContractError("Preview registry identifier substitution count drifted")
    if b"$" in materialized_expansion:
        raise ObjectContractError(
            "materialized Preview expansion retains a compiler-reserved identifier"
        )

    prefix = original[:span_offset]
    derived = prefix + materialized_expansion
    if derived.count(b"#Preview") != 0:
        raise ObjectContractError("materialized source retains a #Preview spelling")
    if derived.count(b"DeveloperToolsSupport.PreviewRegistry") != 1:
        raise ObjectContractError("materialized source registry count drifted")

    materialized_path = output_root.joinpath(*PurePosixPath(relative).parts)
    compile_paths = list(source_paths)
    compile_paths[preview_index] = materialized_path
    compile_payload = b"".join(os.fsencode(path) + b"\0" for path in compile_paths)
    leading_context = original[max(0, span_offset - 128) : span_offset]
    document = {
        "application_source_count": len(relative_sources),
        "classification": "portable-preview-materialization-audit",
        "compile_source_list": {
            "path": str(compile_source_list),
            "sha256": hashlib.sha256(compile_payload).hexdigest(),
            "size": len(compile_payload),
        },
        "derived": {
            "path": str(materialized_path),
            "sha256": hashlib.sha256(derived).hexdigest(),
            "size": len(derived),
        },
        "expansion": {
            "diagnostic_sha256": hashlib.sha256(diagnostic).hexdigest(),
            "diagnostic_size": len(diagnostic),
            "file_id": file_id,
            "line": expansion_line,
            "column": expansion_column,
            "payload_sha256": hashlib.sha256(expansion).hexdigest(),
            "payload_size": len(expansion),
            "registry_count": 1,
            "identifier_substitution": {
                "count": 1,
                "generated_identifier": generated_identifier.decode("ascii"),
                "generated_identifier_sha256": hashlib.sha256(
                    generated_identifier
                ).hexdigest(),
                "materialized_identifier": materialized_identifier.decode("ascii"),
                "materialized_identifier_sha256": hashlib.sha256(
                    materialized_identifier
                ).hexdigest(),
            },
            "materialized_payload_sha256": hashlib.sha256(
                materialized_expansion
            ).hexdigest(),
            "materialized_payload_size": len(materialized_expansion),
        },
        "format_version": 1,
        "materialized_source_count": 1,
        "module_name": module_name,
        "original_source_count": len(relative_sources) - 1,
        "source": {
            "body_sha256": hashlib.sha256(macro_body).hexdigest(),
            "body_size": len(macro_body),
            "column": column,
            "leading_context_hex": leading_context.hex(),
            "leading_context_size": len(leading_context),
            "line": line,
            "path": relative,
            "prefix_sha256": hashlib.sha256(prefix).hexdigest(),
            "prefix_size": len(prefix),
            "sha256": hashlib.sha256(original).hexdigest(),
            "size": len(original),
            "span_offset": span_offset,
            "span_sha256": hashlib.sha256(span).hexdigest(),
            "span_size": len(span),
            "trailing_context_hex": "",
        },
    }
    return materialized_path, derived, compile_payload, _canonical_json(document)


def materialize_preview_expansion(
    source_root_value: str | Path,
    application_source_list_value: str | Path,
    preview_source_audit_value: str | Path,
    expansion_stderr_value: str | Path,
    output_root_value: str | Path,
    compile_source_list_value: str | Path,
    audit_value: str | Path,
    module_name: str,
) -> None:
    source_root = _absolute(source_root_value, "application source root")
    application_source_list = _absolute(
        application_source_list_value, "application source list"
    )
    preview_source_audit = _absolute(preview_source_audit_value, "Preview source audit")
    expansion_stderr = _absolute(
        expansion_stderr_value, "Preview expansion diagnostic"
    )
    output_root = _absolute(output_root_value, "Preview materialization root")
    compile_source_list = _absolute(
        compile_source_list_value, "materialized application source list"
    )
    audit = _absolute(audit_value, "Preview materialization audit")
    for path, label in (
        (output_root, "Preview materialization root"),
        (compile_source_list, "materialized application source list"),
        (audit, "Preview materialization audit"),
    ):
        _outside_source_root(source_root, path, label)
    if output_root.exists() or output_root.is_symlink():
        raise ObjectContractError(
            f"Preview materialization root already exists: {output_root}"
        )
    for path, label in (
        (compile_source_list, "materialized application source list"),
        (audit, "Preview materialization audit"),
    ):
        if path.exists() or path.is_symlink():
            raise ObjectContractError(f"{label} already exists: {path}")
    materialized_path, derived, compile_payload, audit_payload = (
        _preview_materialization_expected(
            source_root,
            application_source_list,
            preview_source_audit,
            expansion_stderr,
            output_root,
            compile_source_list,
            module_name,
        )
    )
    _new_directory(output_root, "Preview materialization root")
    current = output_root
    relative_parent = materialized_path.relative_to(output_root).parent
    for component in relative_parent.parts:
        current /= component
        _new_directory(current, "Preview materialization directory")
    _new_file(materialized_path, derived, "materialized Preview source")
    _new_file(
        compile_source_list,
        compile_payload,
        "materialized application source list",
    )
    _new_file(audit, audit_payload, "Preview materialization audit")


def verify_preview_materialization(
    source_root_value: str | Path,
    application_source_list_value: str | Path,
    preview_source_audit_value: str | Path,
    expansion_stderr_value: str | Path,
    output_root_value: str | Path,
    compile_source_list_value: str | Path,
    audit_value: str | Path,
    module_name: str,
) -> None:
    source_root = _absolute(source_root_value, "application source root")
    application_source_list = _absolute(
        application_source_list_value, "application source list"
    )
    preview_source_audit = _absolute(preview_source_audit_value, "Preview source audit")
    expansion_stderr = _absolute(
        expansion_stderr_value, "Preview expansion diagnostic"
    )
    output_root = _absolute(output_root_value, "Preview materialization root")
    compile_source_list = _absolute(
        compile_source_list_value, "materialized application source list"
    )
    audit = _absolute(audit_value, "Preview materialization audit")
    for path, label in (
        (output_root, "Preview materialization root"),
        (compile_source_list, "materialized application source list"),
        (audit, "Preview materialization audit"),
    ):
        _outside_source_root(source_root, path, label)
    _ordinary_directory(output_root, "Preview materialization root")
    materialized_path, derived, compile_payload, audit_payload = (
        _preview_materialization_expected(
            source_root,
            application_source_list,
            preview_source_audit,
            expansion_stderr,
            output_root,
            compile_source_list,
            module_name,
        )
    )
    _regular(materialized_path, "materialized Preview source")
    _regular(compile_source_list, "materialized application source list")
    _regular(audit, "Preview materialization audit")
    if materialized_path.read_bytes() != derived:
        raise ObjectContractError("materialized Preview source differs from derivation")
    if compile_source_list.read_bytes() != compile_payload:
        raise ObjectContractError("materialized application source list differs")
    if audit.read_bytes() != audit_payload:
        raise ObjectContractError("Preview materialization audit differs")
    actual_files: list[Path] = []
    actual_directories: list[Path] = []
    for directory, directory_names, file_names in os.walk(output_root, followlinks=False):
        directory_path = Path(directory)
        for name in directory_names:
            path = directory_path / name
            _ordinary_directory(path, "Preview materialization directory")
            actual_directories.append(path)
        for name in file_names:
            path = directory_path / name
            _regular(path, "Preview materialization file")
            actual_files.append(path)
    if actual_files != [materialized_path]:
        raise ObjectContractError(
            "Preview materialization root contains an unexpected file set"
        )
    expected_directories: list[Path] = []
    current = output_root
    for component in materialized_path.relative_to(output_root).parent.parts:
        current /= component
        expected_directories.append(current)
    if actual_directories != expected_directories:
        raise ObjectContractError(
            "Preview materialization root contains an unexpected directory set"
        )


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
    nm = _canonical_executable(nm_value, "llvm-nm")
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
    nm = _canonical_executable(nm_value, "llvm-nm")
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

    materialize = commands.add_parser("materialize-preview-expansion")
    materialize.add_argument("--source-root", required=True)
    materialize.add_argument("--application-source-list", required=True)
    materialize.add_argument("--preview-source-audit", required=True)
    materialize.add_argument("--expansion-stderr", required=True)
    materialize.add_argument("--output-root", required=True)
    materialize.add_argument("--compile-source-list", required=True)
    materialize.add_argument("--audit", required=True)
    materialize.add_argument("--module-name", required=True)

    verify_materialization = commands.add_parser("verify-preview-materialization")
    verify_materialization.add_argument("--source-root", required=True)
    verify_materialization.add_argument("--application-source-list", required=True)
    verify_materialization.add_argument("--preview-source-audit", required=True)
    verify_materialization.add_argument("--expansion-stderr", required=True)
    verify_materialization.add_argument("--output-root", required=True)
    verify_materialization.add_argument("--compile-source-list", required=True)
    verify_materialization.add_argument("--audit", required=True)
    verify_materialization.add_argument("--module-name", required=True)

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
        elif args.command == "materialize-preview-expansion":
            materialize_preview_expansion(
                args.source_root,
                args.application_source_list,
                args.preview_source_audit,
                args.expansion_stderr,
                args.output_root,
                args.compile_source_list,
                args.audit,
                args.module_name,
            )
        elif args.command == "verify-preview-materialization":
            verify_preview_materialization(
                args.source_root,
                args.application_source_list,
                args.preview_source_audit,
                args.expansion_stderr,
                args.output_root,
                args.compile_source_list,
                args.audit,
                args.module_name,
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
