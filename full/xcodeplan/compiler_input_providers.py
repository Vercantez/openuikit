#!/usr/bin/env python3
"""Run and attest portable compilers for non-Swift Xcode target inputs.

The application build plan freezes every physical compiler input.  This tool
materializes generated Swift under one fresh output-owned directory, publishes
the only ordered source list consumed by the Swift driver, and can reconstruct
the complete attestation after compilation or execution.  Application and
vendor trees remain read-only.
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
import tempfile
from typing import Any


HERE = Path(__file__).resolve().parent
INTENTS_TOOL_DIR = HERE.parent / "intents"
sys.path.insert(0, os.fspath(INTENTS_TOOL_DIR))

import intentdefinition_compiler  # noqa: E402


CLASSIFICATION = "portable-application-derived-sources"
FORMAT_VERSION = 1
PROVIDER_NAME = "open-intentdefinition"
SOURCE_LIST_NAME = "derived-sources.nul"
ATTESTATION_NAME = "derived-sources-attestation.json"
PROVIDERS_DIRECTORY = "providers"
SHA256_LENGTH = 64


class ProviderError(RuntimeError):
    """A frozen compiler input or derived output violates the contract."""


def refuse(message: str) -> None:
    raise ProviderError(message)


def _sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _canonical_json(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode(
        "utf-8"
    )


def _reject_duplicate_json_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            refuse(f"application build plan contains duplicate JSON key: {key!r}")
        result[key] = value
    return result


def _mapping(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict) or not all(isinstance(key, str) for key in value):
        refuse(f"{label} must be a string-keyed object")
    return value


def _array(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        refuse(f"{label} must be an array")
    return value


def _string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        refuse(f"{label} must be a non-empty string")
    if any(character in value for character in "\x00\r\n\t"):
        refuse(f"{label} contains a forbidden control character")
    return value


def _safe_relative(value: Any, label: str) -> str:
    text = _string(value, label)
    path = PurePosixPath(text)
    if (
        path.is_absolute()
        or path.as_posix() != text
        or not path.parts
        or any(part in ("", ".", "..") for part in path.parts)
    ):
        refuse(f"{label} is not a normalized relative path: {text!r}")
    return text


def _ordinary_directory(path: Path, label: str) -> Path:
    try:
        metadata = path.lstat()
    except OSError as error:
        refuse(f"cannot inspect {label}: {path}: {error}")
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        refuse(f"{label} is not an ordinary directory: {path}")
    return path.resolve(strict=True)


def _regular(path: Path, label: str) -> Path:
    try:
        metadata = path.lstat()
    except OSError as error:
        refuse(f"cannot inspect {label}: {path}: {error}")
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISREG(metadata.st_mode):
        refuse(f"{label} is not a regular non-symlink file: {path}")
    return path


def _materialized(root: Path, relative_value: str, label: str) -> Path:
    relative = PurePosixPath(relative_value)
    current = root
    for component in relative.parts:
        current /= component
        try:
            metadata = current.lstat()
        except OSError as error:
            refuse(f"cannot inspect {label}: {current}: {error}")
        if stat.S_ISLNK(metadata.st_mode):
            refuse(f"{label} traverses a symlink: {current}")
    _regular(current, label)
    try:
        current.resolve(strict=True).relative_to(root)
    except (OSError, ValueError) as error:
        refuse(f"{label} escapes source root: {current}: {error}")
    return current


def _load_plan(path: Path) -> tuple[bytes, dict[str, Any]]:
    _regular(path, "application build plan")
    payload = path.read_bytes()
    try:
        plan = _mapping(
            json.loads(payload, object_pairs_hook=_reject_duplicate_json_keys),
            "application build plan",
        )
    except (UnicodeError, json.JSONDecodeError) as error:
        refuse(f"cannot parse application build plan: {error}")
    if plan.get("classification") != "portable-application-build-plan":
        refuse("unexpected application build-plan classification")
    if plan.get("format_version") != 2:
        refuse("unsupported application build-plan format version")
    module = _string(plan.get("module"), "application module")
    if not module.isascii() or not module.isidentifier():
        refuse(f"application module is not a portable Swift identifier: {module!r}")
    _array(plan.get("compiler_inputs"), "application compiler_inputs")
    return payload, plan


def _validate_input_record(
    raw: Any,
    index: int,
    source_root: Path,
    seen_paths: set[str],
) -> tuple[dict[str, Any], Path]:
    label = f"compiler_inputs[{index}]"
    record = _mapping(raw, label)
    expected_keys = {"provider", "logical_path", "primary_path", "input_files"}
    if set(record) != expected_keys:
        refuse(f"{label} keys differ from the provider contract")
    provider = _string(record.get("provider"), f"{label}.provider")
    if provider != PROVIDER_NAME:
        refuse(f"unsupported compiler-input provider: {provider!r}")
    logical_path = _safe_relative(record.get("logical_path"), f"{label}.logical_path")
    if not logical_path.lower().endswith(".intentdefinition"):
        refuse(f"{label}.logical_path is not an .intentdefinition input")
    primary_path = _safe_relative(record.get("primary_path"), f"{label}.primary_path")
    inputs = _array(record.get("input_files"), f"{label}.input_files")
    if not inputs:
        refuse(f"{label}.input_files is empty")

    normalized_inputs: list[dict[str, Any]] = []
    definition_paths: list[str] = []
    primary: Path | None = None
    for input_index, raw_input in enumerate(inputs):
        input_label = f"{label}.input_files[{input_index}]"
        item = _mapping(raw_input, input_label)
        if set(item) != {"path", "sha256", "size"}:
            refuse(f"{input_label} keys differ from the frozen-file contract")
        relative = _safe_relative(item.get("path"), f"{input_label}.path")
        if relative in seen_paths:
            refuse(f"duplicate physical compiler input: {relative}")
        seen_paths.add(relative)
        suffix = PurePosixPath(relative).suffix.lower()
        if suffix not in (".intentdefinition", ".strings"):
            refuse(f"unsupported intent-definition variant input: {relative}")
        if suffix == ".intentdefinition":
            definition_paths.append(relative)
        expected_hash = _string(item.get("sha256"), f"{input_label}.sha256")
        if (
            len(expected_hash) != SHA256_LENGTH
            or any(character not in "0123456789abcdef" for character in expected_hash)
        ):
            refuse(f"{input_label}.sha256 is not lowercase SHA-256")
        expected_size = item.get("size")
        if (
            not isinstance(expected_size, int)
            or isinstance(expected_size, bool)
            or expected_size < 0
        ):
            refuse(f"{input_label}.size is not a nonnegative integer")
        physical = _materialized(source_root, relative, input_label)
        actual_size = physical.stat().st_size
        actual_hash = _sha256(physical)
        if actual_size != expected_size or actual_hash != expected_hash:
            refuse(f"frozen compiler input changed: {relative}")
        if relative == primary_path:
            primary = physical
        normalized_inputs.append(
            {"path": relative, "sha256": actual_hash, "size": actual_size}
        )
    if (
        definition_paths != [primary_path]
        or primary is None
        or normalized_inputs[0]["path"] != primary_path
    ):
        refuse(
            f"{label} must begin with exactly one .intentdefinition primary input"
        )
    logical = PurePosixPath(logical_path)
    primary_relative = PurePosixPath(primary_path)
    if primary_relative != logical:
        if (
            not primary_relative.parent.name.endswith(".lproj")
            or primary_relative.parent.parent != logical.parent
            or primary_relative.name != logical.name
        ):
            refuse(f"{label}.primary_path is not a matching localized variant")
    expected_strings_name = logical.stem + ".strings"
    for item in normalized_inputs[1:]:
        localized = PurePosixPath(item["path"])
        if (
            localized.name != expected_strings_name
            or not localized.parent.name.endswith(".lproj")
            or localized.parent.parent != logical.parent
        ):
            refuse(f"{label} contains a mismatched localization variant")
    return {
        "provider": provider,
        "logical_path": logical_path,
        "primary_path": primary_path,
        "input_files": normalized_inputs,
    }, primary


def _inputs(plan: dict[str, Any], source_root: Path) -> list[tuple[dict[str, Any], Path]]:
    result: list[tuple[dict[str, Any], Path]] = []
    seen_paths: set[str] = set()
    for index, raw in enumerate(_array(plan["compiler_inputs"], "compiler_inputs")):
        result.append(_validate_input_record(raw, index, source_root, seen_paths))
    logical_paths = [record["logical_path"] for record, _path in result]
    if len(logical_paths) != len(set(logical_paths)):
        refuse("compiler_inputs contains duplicate logical paths")
    return result


def _tool_record() -> dict[str, Any]:
    tool = _regular(
        INTENTS_TOOL_DIR / "intentdefinition_compiler.py",
        "intent-definition compiler",
    )
    return {
        "compiler_name": intentdefinition_compiler.COMPILER_NAME,
        "compiler_version": intentdefinition_compiler.COMPILER_VERSION,
        "path": "full/intents/intentdefinition_compiler.py",
        "sha256": _sha256(tool),
        "size": tool.stat().st_size,
    }


def _provider_directory(index: int) -> str:
    return f"{PROVIDERS_DIRECTORY}/{index:06d}-{PROVIDER_NAME}"


def _source_list_payload(sources: list[dict[str, Any]]) -> bytes:
    return b"".join(item["path"].encode("utf-8") + b"\0" for item in sources)


def _provider_outputs(
    root: Path,
    input_records: list[tuple[dict[str, Any], Path]],
    *,
    generating: bool,
    module: str,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    providers: list[dict[str, Any]] = []
    sources: list[dict[str, Any]] = []
    seen_swift_names: dict[str, int] = {}
    for index, (input_record, primary) in enumerate(input_records):
        relative_directory = _provider_directory(index)
        output_directory = root / relative_directory
        if generating:
            intentdefinition_compiler.generate(primary, output_directory, module)
        try:
            manifest = intentdefinition_compiler.verify(output_directory)
        except intentdefinition_compiler.Refusal as error:
            refuse(f"intent-definition provider verification failed: {error}")
        if manifest.get("module_name") != module:
            refuse(f"provider[{index}] generated for a different module")
        input_manifest = _mapping(manifest.get("input"), f"provider[{index}] input")
        if input_manifest.get("sha256") != input_record["input_files"][
            [item["path"] for item in input_record["input_files"]].index(
                input_record["primary_path"]
            )
        ]["sha256"]:
            refuse(f"provider[{index}] manifest does not bind its primary input")
        output_manifest_path = output_directory / "intentdefinition-manifest.json"
        provider_sources: list[dict[str, Any]] = []
        for raw_output in _array(manifest.get("outputs"), f"provider[{index}] outputs"):
            item = _mapping(raw_output, f"provider[{index}] output")
            filename = _safe_relative(item.get("path"), f"provider[{index}] output path")
            if PurePosixPath(filename).parent != PurePosixPath("."):
                refuse(f"provider[{index}] emitted a nested output path")
            if not filename.endswith(".swift"):
                continue
            swift_name = _string(
                item.get("swift_name"), f"provider[{index}] output Swift name"
            )
            previous = seen_swift_names.get(swift_name)
            if previous is not None:
                refuse(
                    f"generated Swift declaration {swift_name!r} is duplicated by "
                    f"providers {previous} and {index}"
                )
            seen_swift_names[swift_name] = index
            physical = _regular(output_directory / filename, "generated Swift source")
            relative = f"{relative_directory}/{filename}"
            record = {
                "path": relative,
                "provider_index": index,
                "sha256": _sha256(physical),
                "size": physical.stat().st_size,
                "swift_name": swift_name,
            }
            provider_sources.append(record)
            sources.append(record)
        providers.append(
            {
                "index": index,
                "input": input_record,
                "manifest": {
                    "path": f"{relative_directory}/intentdefinition-manifest.json",
                    "sha256": _sha256(output_manifest_path),
                    "size": output_manifest_path.stat().st_size,
                },
                "name": PROVIDER_NAME,
                "source_count": len(provider_sources),
                "sources": provider_sources,
            }
        )
    return providers, sources


def _document(
    plan_payload: bytes,
    module: str,
    tool: dict[str, Any],
    providers: list[dict[str, Any]],
    sources: list[dict[str, Any]],
    source_list_payload: bytes,
) -> dict[str, Any]:
    return {
        "build_plan_sha256": _sha256_bytes(plan_payload),
        "classification": CLASSIFICATION,
        "format_version": FORMAT_VERSION,
        "input_count": len(providers),
        "module_name": module,
        "provider_count": len(providers),
        "providers": providers,
        "source_count": len(sources),
        "source_list": {
            "path": SOURCE_LIST_NAME,
            "sha256": _sha256_bytes(source_list_payload),
            "size": len(source_list_payload),
        },
        "sources": sources,
        "tool": tool,
    }


def generate(
    plan_path: Path,
    source_root_value: Path,
    output_root: Path,
) -> dict[str, Any]:
    source_root = _ordinary_directory(source_root_value, "application source root")
    plan_payload, plan = _load_plan(plan_path)
    input_records = _inputs(plan, source_root)
    if not output_root.is_absolute() or output_root.name in ("", ".", ".."):
        refuse("derived-source output root must be an absolute child path")
    parent = _ordinary_directory(output_root.parent, "derived-source output parent")
    output_root = parent / output_root.name
    if output_root.exists() or output_root.is_symlink():
        refuse(f"derived-source output root already exists: {output_root}")
    temporary = Path(
        tempfile.mkdtemp(prefix=f".{output_root.name}.INCOMPLETE.", dir=parent)
    )
    try:
        (temporary / PROVIDERS_DIRECTORY).mkdir(mode=0o755)
        providers, sources = _provider_outputs(
            temporary,
            input_records,
            generating=True,
            module=plan["module"],
        )
        source_list_payload = _source_list_payload(sources)
        (temporary / SOURCE_LIST_NAME).write_bytes(source_list_payload)
        document = _document(
            plan_payload,
            plan["module"],
            _tool_record(),
            providers,
            sources,
            source_list_payload,
        )
        (temporary / ATTESTATION_NAME).write_bytes(_canonical_json(document))
        os.replace(temporary, output_root)
    except BaseException:
        shutil.rmtree(temporary, ignore_errors=True)
        raise
    return document


def verify(
    plan_path: Path,
    source_root_value: Path,
    output_root_value: Path,
) -> tuple[dict[str, Any], list[Path]]:
    source_root = _ordinary_directory(source_root_value, "application source root")
    output_root = _ordinary_directory(output_root_value, "derived-source output root")
    plan_payload, plan = _load_plan(plan_path)
    input_records = _inputs(plan, source_root)
    actual_names = sorted(entry.name for entry in os.scandir(output_root))
    expected_names = sorted(
        (ATTESTATION_NAME, PROVIDERS_DIRECTORY, SOURCE_LIST_NAME)
    )
    if actual_names != expected_names:
        refuse("derived-source output root contains an unexpected artifact")
    providers_root = _ordinary_directory(
        output_root / PROVIDERS_DIRECTORY, "derived-source providers root"
    )
    expected_provider_names = [
        PurePosixPath(_provider_directory(index)).name
        for index in range(len(input_records))
    ]
    actual_provider_names = sorted(entry.name for entry in os.scandir(providers_root))
    if actual_provider_names != expected_provider_names:
        refuse("derived-source provider directory set drifted")
    providers, sources = _provider_outputs(
        output_root,
        input_records,
        generating=False,
        module=plan["module"],
    )
    source_list = _regular(output_root / SOURCE_LIST_NAME, "derived-source list")
    source_list_payload = source_list.read_bytes()
    expected_source_list = _source_list_payload(sources)
    if source_list_payload != expected_source_list:
        refuse("derived-source ordered NUL list drifted")
    document = _document(
        plan_payload,
        plan["module"],
        _tool_record(),
        providers,
        sources,
        source_list_payload,
    )
    attestation = _regular(
        output_root / ATTESTATION_NAME, "derived-source attestation"
    )
    if attestation.read_bytes() != _canonical_json(document):
        refuse("derived-source attestation differs from current inputs/outputs/tool")
    physical_sources = [
        _materialized(output_root, item["path"], "attested derived Swift source")
        for item in sources
    ]
    return document, physical_sources


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("generate", "verify"):
        command = commands.add_parser(name)
        command.add_argument("--build-plan", required=True, type=Path)
        command.add_argument("--source-root", required=True, type=Path)
        command.add_argument("--output-root", required=True, type=Path)
        command.add_argument("--emit-sources", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "generate":
            document = generate(args.build_plan, args.source_root, args.output_root)
            sources = [args.output_root / item["path"] for item in document["sources"]]
        else:
            _document_value, sources = verify(
                args.build_plan, args.source_root, args.output_root
            )
        if args.emit_sources:
            sys.stdout.buffer.write(
                b"".join(os.fsencode(path) + b"\0" for path in sources)
            )
        return 0
    except (ProviderError, intentdefinition_compiler.Refusal, OSError) as error:
        print(f"compiler-input-providers: REFUSING -- {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
