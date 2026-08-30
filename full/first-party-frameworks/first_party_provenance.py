#!/usr/bin/env python3
"""Fail-closed source provenance for seven portable first-party frameworks."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import stat
import sys


FRAMEWORKS = (
    "LocalAuthentication",
    "SafariServices",
    "Network",
    "StoreKit",
    "AudioToolbox",
    "CoreHaptics",
    "PassKit",
)
EXPECTED_COUNTS = {
    "LocalAuthentication": (46, 11, 2),
    "SafariServices": (132, 17, 2),
    "Network": (31, 10, 1),
    "StoreKit": (48, 14, 1),
    "AudioToolbox": (29, 7, 1),
    "CoreHaptics": (6, 4, 1),
    "PassKit": (58, 8, 1),
}


class Refusal(RuntimeError):
    pass


def refuse(message: str) -> None:
    raise Refusal(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def require_hex(value: object, length: int, label: str) -> str:
    if not isinstance(value, str) or not re.fullmatch(
        rf"[0-9a-f]{{{length}}}", value
    ):
        refuse(f"invalid {label}")
    return value


def safe_relative(raw: object, label: str) -> str:
    if not isinstance(raw, str):
        refuse(f"{label} is not a string")
    path = PurePosixPath(raw)
    if (
        not raw
        or path.is_absolute()
        or path.as_posix() != raw
        or any(part in ("", ".", "..") for part in path.parts)
        or any(character in raw for character in "\\\x00\r\n\t")
    ):
        refuse(f"unsafe {label}: {raw!r}")
    return raw


def regular_beneath(root: Path, relative: str, label: str) -> Path:
    safe_relative(relative, label)
    cursor = root
    parts = PurePosixPath(relative).parts
    for index, component in enumerate(parts):
        cursor /= component
        try:
            mode = cursor.lstat().st_mode
        except FileNotFoundError:
            refuse(f"missing {label}: {relative}")
        if stat.S_ISLNK(mode):
            refuse(f"symlinked {label}: {relative}")
        if index == len(parts) - 1:
            if not stat.S_ISREG(mode):
                refuse(f"non-file {label}: {relative}")
        elif not stat.S_ISDIR(mode):
            refuse(f"non-directory ancestor for {label}: {relative}")
    return cursor


def require_keys(value: object, expected: set[str], label: str) -> dict:
    if not isinstance(value, dict) or set(value) != expected:
        refuse(f"{label} key set drifted")
    return value


def load_policy(path: Path) -> dict:
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        refuse(f"missing policy: {path}")
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
        refuse(f"policy is not a regular non-symlink file: {path}")
    try:
        policy = json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        refuse(f"invalid policy JSON: {error}")
    require_keys(
        policy,
        {
            "bases",
            "classification",
            "corpus",
            "frameworks",
            "schema",
            "test_inputs",
            "top_source_manifest",
        },
        "policy",
    )
    if policy["schema"] != 1:
        refuse("policy schema drifted")
    if policy["classification"] != "portable-first-party-frameworks-seven-v1":
        refuse("policy classification drifted")
    return policy


def validate_record(root: Path, value: object, label: str) -> tuple[str, str, int]:
    record = require_keys(value, {"path", "sha256"}, f"{label} record")
    relative = safe_relative(record["path"], f"{label} path")
    expected = require_hex(record["sha256"], 64, f"{label} SHA-256")
    path = regular_beneath(root, relative, label)
    actual = sha256(path)
    if actual != expected:
        refuse(f"{label} digest drifted: {relative}")
    return relative, actual, path.stat().st_size


def read_manifest(path: Path, label: str) -> list[str]:
    payload = path.read_bytes()
    if not payload.endswith(b"\n") or payload.endswith(b"\n\n"):
        refuse(f"{label} must have exactly one final LF")
    if b"\r" in payload or b"\0" in payload:
        refuse(f"{label} contains a forbidden control byte")
    try:
        lines = payload[:-1].decode("utf-8").split("\n")
    except UnicodeDecodeError as error:
        refuse(f"{label} is not UTF-8: {error}")
    if not lines or any(not line for line in lines):
        refuse(f"{label} contains an empty path")
    return lines


def validate_bases(policy: dict) -> tuple[dict, dict]:
    bases = require_keys(policy["bases"], {"support", "uikit"}, "bases")
    support = require_keys(bases["support"], {"commit", "tree"}, "support base")
    uikit = require_keys(bases["uikit"], {"commit", "tree"}, "UIKit base")
    for label, value in (("support", support), ("UIKit", uikit)):
        require_hex(value["commit"], 40, f"{label} commit")
        require_hex(value["tree"], 40, f"{label} tree")
    return support, uikit


def validate_corpus(root: Path, policy: dict) -> tuple[str, str]:
    corpus = require_keys(
        policy["corpus"],
        {
            "app_count",
            "census_sha256",
            "census_tool",
            "focus_commit",
            "focus_tree",
            "frameworks",
            "ordered_file_inventory_sha256",
            "pins_manifest",
        },
        "corpus",
    )
    if corpus["app_count"] != 20:
        refuse("corpus app count drifted")
    require_hex(corpus["census_sha256"], 64, "corpus census digest")
    require_hex(
        corpus["ordered_file_inventory_sha256"], 64,
        "corpus ordered-file digest",
    )
    require_hex(corpus["focus_commit"], 40, "Focus commit")
    require_hex(corpus["focus_tree"], 40, "Focus tree")
    census_path, census_digest, _ = validate_record(
        root, corpus["census_tool"], "corpus census tool"
    )
    pins_path, pins_digest, _ = validate_record(
        root, corpus["pins_manifest"], "corpus pins manifest"
    )
    records = corpus["frameworks"]
    if not isinstance(records, list) or [item.get("name") for item in records] != list(
        FRAMEWORKS
    ):
        refuse("corpus framework order drifted")
    seen_focus_paths: set[tuple[str, str]] = set()
    for record in records:
        require_keys(
            record,
            {
                "focus_files",
                "import_file_count",
                "importing_app_count",
                "name",
                "ordered_file_inventory_sha256",
            },
            "corpus framework",
        )
        name = record["name"]
        expected_files, expected_apps, expected_focus = EXPECTED_COUNTS[name]
        if (
            record["import_file_count"],
            record["importing_app_count"],
            len(record["focus_files"]),
        ) != (expected_files, expected_apps, expected_focus):
            refuse(f"{name} corpus counts drifted")
        require_hex(
            record["ordered_file_inventory_sha256"], 64,
            f"{name} ordered-file digest",
        )
        for focus in record["focus_files"]:
            require_keys(focus, {"bytes", "path", "sha256"}, f"{name} Focus file")
            path = safe_relative(focus["path"], f"{name} Focus path")
            if type(focus["bytes"]) is not int or focus["bytes"] <= 0:
                refuse(f"invalid {name} Focus byte count")
            digest = require_hex(focus["sha256"], 64, f"{name} Focus file digest")
            seen_focus_paths.add((path, digest))
    if len(seen_focus_paths) != 8:
        refuse("exact Focus source identity set drifted")
    return f"{census_path}:{census_digest}", f"{pins_path}:{pins_digest}"


def production(args: argparse.Namespace) -> None:
    root = Path(args.support_root)
    try:
        mode = root.lstat().st_mode
    except FileNotFoundError:
        refuse(f"missing support root: {root}")
    if stat.S_ISLNK(mode) or not stat.S_ISDIR(mode):
        refuse(f"support root is not a regular directory: {root}")
    policy = load_policy(Path(args.policy))
    support, uikit = validate_bases(policy)
    census, pins = validate_corpus(root, policy)

    framework_records = policy["frameworks"]
    if not isinstance(framework_records, list) or [
        item.get("name") for item in framework_records
    ] != list(FRAMEWORKS):
        refuse("production framework order drifted")

    ordered_sources: list[str] = []
    output_lines = [
        "format\tfirst-party-framework-sources-v1",
        f"support-base\t{support['commit']}\t{support['tree']}",
        f"uikit-base\t{uikit['commit']}\t{uikit['tree']}",
        f"corpus-census\t{policy['corpus']['census_sha256']}\t{census}",
        f"corpus-pins\t{pins}",
    ]
    for index, value in enumerate(framework_records, 1):
        record = require_keys(
            value,
            {"directory", "manifest", "name", "sources", "uses_uikit"},
            f"framework {index}",
        )
        name = record["name"]
        directory = safe_relative(record["directory"], f"{name} directory")
        if type(record["uses_uikit"]) is not bool:
            refuse(f"{name} uses_uikit is not Boolean")
        manifest_relative, manifest_digest, _ = validate_record(
            root, record["manifest"], f"{name} source manifest"
        )
        manifest_sources = read_manifest(
            root / manifest_relative, f"{name} source manifest"
        )
        sources = record["sources"]
        if not isinstance(sources, list) or len(sources) != 1:
            refuse(f"{name} must have the exact one-source production boundary")
        expected_sources = [source["path"] for source in sources]
        if manifest_sources != expected_sources:
            refuse(f"{name} source manifest order drifted")
        physical = sorted(
            path.relative_to(root).as_posix()
            for path in (root / directory).glob("*.swift")
            if path.is_file() or path.is_symlink()
        )
        if physical != expected_sources:
            refuse(f"{name} physical Swift source set drifted")
        for source_index, source in enumerate(sources, 1):
            relative, digest, size = validate_record(
                root, source, f"{name} source {source_index}"
            )
            ordered_sources.append(relative)
            output_lines.append(
                f"source\t{index}\t{name}\t{relative}\t{digest}\t{size}"
            )
        output_lines.append(
            f"manifest\t{index}\t{name}\t{manifest_relative}\t{manifest_digest}"
        )

    top_relative, top_digest, _ = validate_record(
        root, policy["top_source_manifest"], "top source manifest"
    )
    if read_manifest(root / top_relative, "top source manifest") != ordered_sources:
        refuse("top source manifest order drifted")
    output_lines.append(f"top-manifest\t{top_relative}\t{top_digest}")

    tests = policy["test_inputs"]
    if not isinstance(tests, list) or len(tests) != 7:
        refuse("test-input cardinality drifted")
    seen_test_paths: set[str] = set()
    for index, record in enumerate(tests, 1):
        relative, digest, size = validate_record(root, record, f"test input {index}")
        if relative in seen_test_paths:
            refuse("duplicate test input")
        seen_test_paths.add(relative)
        output_lines.append(f"test-input\t{index}\t{relative}\t{digest}\t{size}")

    output = Path(args.output)
    if output.exists() or output.is_symlink():
        refuse(f"refusing to overwrite output: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(output_lines) + "\n", encoding="utf-8", newline="\n")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    subparsers = result.add_subparsers(dest="command", required=True)
    command = subparsers.add_parser("production")
    command.add_argument("--support-root", required=True)
    command.add_argument("--policy", required=True)
    command.add_argument("--output", required=True)
    command.set_defaults(action=production)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        args.action(args)
    except Refusal as error:
        print(f"first_party_provenance: REFUSING -- {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
