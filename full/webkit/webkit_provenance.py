#!/usr/bin/env python3
"""Fail-closed source and untouched-Focus provenance for portable WebKit."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys


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


def safe_relative(raw: str, label: str) -> str:
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
    for index, component in enumerate(PurePosixPath(relative).parts):
        cursor /= component
        try:
            mode = cursor.lstat().st_mode
        except FileNotFoundError:
            refuse(f"missing {label}: {relative}")
        if stat.S_ISLNK(mode):
            refuse(f"symlinked {label}: {relative}")
        last = index == len(PurePosixPath(relative).parts) - 1
        if last and not stat.S_ISREG(mode):
            refuse(f"non-file {label}: {relative}")
        if not last and not stat.S_ISDIR(mode):
            refuse(f"non-directory ancestor for {label}: {relative}")
    return cursor


def load_policy(path: Path) -> dict:
    if path.is_symlink() or not path.is_file():
        refuse(f"policy is not a regular file: {path}")
    try:
        policy = json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        refuse(f"invalid policy JSON: {error}")
    if set(policy) != {
        "classification",
        "focus",
        "native_oracle",
        "schema",
        "source_manifest",
        "sources",
    }:
        refuse("policy key set drifted")
    if policy["schema"] != 1:
        refuse("policy schema drifted")
    if policy["classification"] != "portable-first-party-webkit-guest-v1":
        refuse("policy classification drifted")
    return policy


def validate_record(root: Path, record: dict, label: str) -> tuple[str, str]:
    if set(record) != {"path", "sha256"}:
        refuse(f"{label} record key set drifted")
    relative = safe_relative(record["path"], f"{label} path")
    expected = record["sha256"]
    if not re.fullmatch(r"[0-9a-f]{64}", expected):
        refuse(f"invalid {label} digest: {relative}")
    actual = sha256(regular_beneath(root, relative, label))
    if actual != expected:
        refuse(f"{label} digest drifted: {relative}")
    return relative, actual


def write_new(path: Path, lines: list[str]) -> None:
    if path.exists() or path.is_symlink():
        refuse(f"refusing to overwrite output: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def production(args: argparse.Namespace) -> None:
    root = Path(args.support_root)
    policy_path = Path(args.policy)
    policy = load_policy(policy_path)
    manifest_record = policy["source_manifest"]
    manifest_relative, manifest_digest = validate_record(
        root, manifest_record, "WebKit source manifest"
    )
    manifest_path = root / manifest_relative
    payload = manifest_path.read_bytes()
    if not payload.endswith(b"\n") or b"\r" in payload or b"\x00" in payload:
        refuse("WebKit source manifest must be UTF-8/LF with one final LF")
    try:
        manifest_sources = payload.decode("utf-8")[:-1].split("\n")
    except UnicodeDecodeError as error:
        refuse(f"WebKit source manifest is not UTF-8: {error}")
    expected_sources = [record["path"] for record in policy["sources"]]
    if manifest_sources != expected_sources:
        refuse(
            f"WebKit source manifest must contain the exact ordered "
            f"{len(expected_sources)}-path contract"
        )
    if len(set(expected_sources)) != len(expected_sources):
        refuse("WebKit production policy contains duplicate sources")
    records = [
        validate_record(root, record, f"WebKit production source {index}")
        for index, record in enumerate(policy["sources"], 1)
    ]
    actual_top_level = {
        path.relative_to(root).as_posix()
        for path in (root / "full/webkit").glob("*.swift")
    }
    if actual_top_level != set(expected_sources):
        refuse("unmanifested or missing top-level WebKit Swift source")

    oracle = policy["native_oracle"]
    if set(oracle) != {
        "golden",
        "ios_simulator_sdk_build",
        "signature_source",
        "xcode_build",
        "xcode_version",
    }:
        refuse("native oracle key set drifted")
    signature = validate_record(root, oracle["signature_source"], "native signature oracle")
    golden = validate_record(root, oracle["golden"], "native oracle golden")
    lines = [
        "format\twebkit-guest-sources-v1",
        f"policy\t{sha256(policy_path)}",
        f"manifest\t{manifest_digest}\tcount={len(records)}",
    ]
    lines.extend(
        f"source\t{index}\t{relative}\t{digest}"
        for index, (relative, digest) in enumerate(records, 1)
    )
    lines.extend(
        (
            f"native-signature\t{signature[0]}\t{signature[1]}",
            f"native-golden\t{golden[0]}\t{golden[1]}",
            "native-sdk\t"
            f"xcode={oracle['xcode_version']}\tbuild={oracle['xcode_build']}\t"
            f"ios-simulator-sdk-build={oracle['ios_simulator_sdk_build']}",
        )
    )
    write_new(Path(args.output), lines)


def git_value(root: Path, *arguments: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *arguments],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        refuse(f"git {' '.join(arguments)} failed: {result.stderr.strip()}")
    return result.stdout.strip()


def focus(args: argparse.Namespace) -> None:
    support_root = Path(args.support_root)
    focus_root = Path(args.focus_root)
    policy_path = Path(args.policy)
    policy = load_policy(policy_path)
    contract = policy["focus"]
    if set(contract) != {
        "application_subdirectory",
        "commit",
        "main_source_manifest",
        "sources",
        "tree",
    }:
        refuse("Focus policy key set drifted")
    if git_value(focus_root, "rev-parse", "HEAD") != contract["commit"]:
        refuse("Focus commit drifted")
    if git_value(focus_root, "rev-parse", "HEAD^{tree}") != contract["tree"]:
        refuse("Focus tree drifted")
    if git_value(focus_root, "status", "--porcelain", "--untracked-files=no"):
        refuse("Focus tracked worktree is not untouched")
    app_relative = safe_relative(
        contract["application_subdirectory"], "Focus application subdirectory"
    )
    app_root = focus_root / app_relative
    if app_root.is_symlink() or not app_root.is_dir():
        refuse("Focus application subdirectory is missing or symlinked")

    main_relative, main_digest = validate_record(
        support_root, contract["main_source_manifest"], "Focus main source manifest"
    )
    main = json.loads((support_root / main_relative).read_text(encoding="utf-8"))
    if main.get("repository_commit") != contract["commit"]:
        refuse("Focus main source manifest commit drifted")
    present = main.get("present_sources")
    if not isinstance(present, list) or len(present) != 129:
        refuse("Focus main source denominator drifted")

    expected = [record["path"] for record in contract["sources"]]
    if len(expected) != 6 or len(set(expected)) != 6:
        refuse("Focus WebKit source policy must contain exactly six unique paths")
    if any(path not in present for path in expected):
        refuse("Focus WebKit source escaped the exact main target")
    records = [
        validate_record(app_root, record, f"Focus WebKit source {index}")
        for index, record in enumerate(contract["sources"], 1)
    ]
    observed: list[str] = []
    for relative in present:
        source = regular_beneath(app_root, relative, "Focus main source")
        if re.search(r"(?m)^import[ \t]+WebKit[ \t]*$", source.read_text(encoding="utf-8")):
            observed.append(relative)
    if observed != expected:
        refuse(f"Focus WebKit import inventory drifted: {observed!r}")
    lines = [
        "format\tfocus-webkit-usage-v1",
        f"focus\tcommit={contract['commit']}\ttree={contract['tree']}",
        f"main-sources\t{main_relative}\t{main_digest}\tcount={len(present)}",
    ]
    lines.extend(
        f"consumer\t{index}\t{relative}\t{digest}"
        for index, (relative, digest) in enumerate(records, 1)
    )
    write_new(Path(args.output), lines)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    subparsers = result.add_subparsers(dest="command", required=True)
    for name, function in (("production", production), ("focus", focus)):
        command = subparsers.add_parser(name)
        command.add_argument("--support-root", required=True)
        command.add_argument("--policy", required=True)
        command.add_argument("--output", required=True)
        if name == "focus":
            command.add_argument("--focus-root", required=True)
        command.set_defaults(function=function)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        args.function(args)
    except Refusal as error:
        print(f"REFUSED: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
