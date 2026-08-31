#!/usr/bin/env python3
"""Physical-copy and immutable-input primitives for a cold guest replay.

The host wrapper intentionally uses this small, standard-library-only helper
instead of host-specific ``cp`` extensions.  Regular files are copied through
userspace reads and exclusive destination writes, so a destination can never
be a hard link to its source.  Snapshots describe only replay-relevant
semantics: path, file type, permission mode, symlink target, size, and content
SHA-256.  Timestamps, ownership, and inode numbers are deliberately omitted.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile
from typing import Iterable, Iterator


FORMAT = "core-guest-physical-input-v1"
COPY_FORMAT = "core-guest-physical-copy-v1"
GIT_COPY_FORMAT = "core-guest-git-copy-proof-v1"
BUFFER_SIZE = 1024 * 1024


class ReplayError(RuntimeError):
    """A fail-closed replay preparation or validation error."""


def fail(message: str) -> "None":
    raise ReplayError(message)


def normalized_relative(value: str) -> str:
    if not value or value == ".":
        return "."
    candidate = value.rstrip("/")
    if (
        candidate.startswith("/")
        or candidate in ("", ".", "..")
        or candidate.startswith("../")
        or "/../" in candidate
        or candidate.endswith("/..")
        or candidate.startswith("./")
        or "/./" in candidate
        or candidate.endswith("/.")
        or "//" in candidate
    ):
        fail(f"relative path is not normalized: {value!r}")
    return candidate


def require_real_directory(path: Path, label: str) -> None:
    try:
        metadata = path.lstat()
    except FileNotFoundError:
        fail(f"{label} does not exist: {path}")
    if not stat.S_ISDIR(metadata.st_mode) or path.is_symlink():
        fail(f"{label} is not a real directory: {path}")


def require_regular_file(path: Path, label: str) -> os.stat_result:
    try:
        metadata = path.lstat()
    except FileNotFoundError:
        fail(f"{label} does not exist: {path}")
    if not stat.S_ISREG(metadata.st_mode) or path.is_symlink():
        fail(f"{label} is not a regular non-symlink file: {path}")
    return metadata


def hash_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while chunk := source.read(BUFFER_SIZE):
            digest.update(chunk)
    return digest.hexdigest()


def mode_string(metadata: os.stat_result) -> str:
    return f"{stat.S_IMODE(metadata.st_mode):04o}"


def entry_record(path: Path, relative: str) -> dict[str, object]:
    metadata = path.lstat()
    record: dict[str, object] = {
        "mode": mode_string(metadata),
        "path": relative,
    }
    if stat.S_ISDIR(metadata.st_mode):
        record["type"] = "directory"
    elif stat.S_ISREG(metadata.st_mode):
        record.update(
            {
                "sha256": hash_file(path),
                "size": metadata.st_size,
                "type": "file",
            }
        )
    elif stat.S_ISLNK(metadata.st_mode):
        record.update({"target": os.readlink(path), "type": "symlink"})
    else:
        fail(f"unsupported input file type at {path}")
    return record


def canonical_record(record: dict[str, object]) -> bytes:
    return (
        json.dumps(record, ensure_ascii=True, sort_keys=True, separators=(",", ":"))
        + "\n"
    ).encode("ascii")


def excluded(relative: str, exclusions: tuple[str, ...]) -> bool:
    return any(relative == item or relative.startswith(item + "/") for item in exclusions)


def walk_records(root: Path, exclusions: tuple[str, ...]) -> Iterator[dict[str, object]]:
    require_real_directory(root, "snapshot root")
    yield entry_record(root, ".")

    def visit(directory: Path, prefix: str) -> Iterator[dict[str, object]]:
        try:
            children = sorted(os.scandir(directory), key=lambda item: os.fsencode(item.name))
        except OSError as error:
            fail(f"cannot enumerate {directory}: {error}")
        for child in children:
            relative = child.name if not prefix else f"{prefix}/{child.name}"
            if excluded(relative, exclusions):
                continue
            path = directory / child.name
            record = entry_record(path, relative)
            yield record
            if record["type"] == "directory":
                yield from visit(path, relative)

    yield from visit(root, "")


def atomic_write(path: Path, payload: bytes) -> None:
    parent = path.parent
    require_real_directory(parent, "output parent")
    if path.exists() or path.is_symlink():
        fail(f"output already exists: {path}")
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(payload)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
    except BaseException:
        temporary.unlink(missing_ok=True)
        raise


def records_payload(records: Iterable[dict[str, object]]) -> bytes:
    return b"".join(canonical_record(record) for record in records)


def snapshot(root: Path, output: Path, exclusions: tuple[str, ...]) -> None:
    normalized = tuple(sorted({normalized_relative(item) for item in exclusions}))
    if "." in normalized:
        fail("snapshot root itself cannot be excluded")
    header = {
        "exclude": list(normalized),
        "format": FORMAT,
        "type": "header",
    }
    payload = canonical_record(header) + records_payload(walk_records(root, normalized))
    atomic_write(output, payload)


def read_manifest(path: Path) -> list[dict[str, object]]:
    require_regular_file(path, "manifest")
    records: list[dict[str, object]] = []
    try:
        with path.open("r", encoding="ascii") as source:
            for line_number, line in enumerate(source, start=1):
                value = json.loads(line)
                if not isinstance(value, dict):
                    fail(f"manifest {path}:{line_number} is not an object")
                records.append(value)
    except (UnicodeError, json.JSONDecodeError) as error:
        fail(f"manifest is not canonical JSON lines: {path}: {error}")
    if not records or records[0].get("format") != FORMAT:
        fail(f"manifest has the wrong format: {path}")
    return records


def compare(before: Path, after: Path) -> None:
    before_bytes = before.read_bytes()
    after_bytes = after.read_bytes()
    if before_bytes == after_bytes:
        return
    before_records = read_manifest(before)
    after_records = read_manifest(after)
    before_map = {str(record.get("path", "<header>")): record for record in before_records}
    after_map = {str(record.get("path", "<header>")): record for record in after_records}
    changes: list[str] = []
    for relative in sorted(set(before_map) | set(after_map), key=os.fsencode):
        if relative not in before_map:
            changes.append(f"added {relative}")
        elif relative not in after_map:
            changes.append(f"removed {relative}")
        elif before_map[relative] != after_map[relative]:
            changes.append(f"changed {relative}")
        if len(changes) == 20:
            break
    detail = ", ".join(changes) if changes else "noncanonical byte drift"
    fail(f"immutable replay inputs changed: {detail}")


def set_times(path: Path, metadata: os.stat_result, *, symlink: bool = False) -> None:
    try:
        os.utime(
            path,
            ns=(metadata.st_atime_ns, metadata.st_mtime_ns),
            follow_symlinks=not symlink,
        )
    except (NotImplementedError, OSError):
        if not symlink:
            raise


def copy_regular(source: Path, destination: Path, metadata: os.stat_result) -> str:
    digest = hashlib.sha256()
    descriptor = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with source.open("rb") as input_file, os.fdopen(descriptor, "wb") as output_file:
            while chunk := input_file.read(BUFFER_SIZE):
                digest.update(chunk)
                output_file.write(chunk)
    except BaseException:
        try:
            os.close(descriptor)
        except OSError:
            pass
        raise
    os.chmod(destination, stat.S_IMODE(metadata.st_mode), follow_symlinks=True)
    set_times(destination, metadata)
    copied = destination.lstat()
    if (metadata.st_dev, metadata.st_ino) == (copied.st_dev, copied.st_ino):
        fail(f"physical copy unexpectedly shares an inode: {source}")
    if copied.st_size != metadata.st_size:
        fail(f"physical copy size differs: {source} -> {destination}")
    return digest.hexdigest()


def make_tree_writable(path: Path) -> None:
    for current, _directories, _files in os.walk(path, topdown=True, followlinks=False):
        metadata = os.lstat(current)
        os.chmod(current, stat.S_IMODE(metadata.st_mode) | stat.S_IWUSR | stat.S_IXUSR)


def copy_tree(source: Path, destination: Path, label: str, output: Path) -> None:
    require_real_directory(source, "copy source")
    if destination.exists() or destination.is_symlink():
        fail(f"copy destination already exists: {destination}")
    require_real_directory(destination.parent, "copy destination parent")
    resolved_source = source.resolve()
    resolved_destination = destination.parent.resolve() / destination.name
    if resolved_destination == resolved_source or resolved_source in resolved_destination.parents:
        fail(f"copy destination overlaps its source: {source} -> {destination}")
    records: list[dict[str, object]] = []
    counters = {"bytes": 0, "directories": 0, "files": 0, "symlinks": 0}

    def visit(source_dir: Path, destination_dir: Path, relative: str) -> None:
        metadata = source_dir.lstat()
        os.mkdir(destination_dir, 0o700)
        records.append(
            {"mode": mode_string(metadata), "path": relative, "type": "directory"}
        )
        counters["directories"] += 1
        children = sorted(os.scandir(source_dir), key=lambda item: os.fsencode(item.name))
        for child in children:
            child_source = source_dir / child.name
            child_destination = destination_dir / child.name
            child_relative = child.name if relative == "." else f"{relative}/{child.name}"
            child_metadata = child_source.lstat()
            if stat.S_ISDIR(child_metadata.st_mode):
                visit(child_source, child_destination, child_relative)
            elif stat.S_ISREG(child_metadata.st_mode):
                digest = copy_regular(child_source, child_destination, child_metadata)
                records.append(
                    {
                        "mode": mode_string(child_metadata),
                        "path": child_relative,
                        "sha256": digest,
                        "size": child_metadata.st_size,
                        "type": "file",
                    }
                )
                counters["bytes"] += child_metadata.st_size
                counters["files"] += 1
            elif stat.S_ISLNK(child_metadata.st_mode):
                target = os.readlink(child_source)
                os.symlink(target, child_destination)
                set_times(child_destination, child_metadata, symlink=True)
                records.append(
                    {
                        "mode": mode_string(child_metadata),
                        "path": child_relative,
                        "target": target,
                        "type": "symlink",
                    }
                )
                counters["symlinks"] += 1
            else:
                fail(f"unsupported input file type at {child_source}")
        os.chmod(destination_dir, stat.S_IMODE(metadata.st_mode))
        set_times(destination_dir, metadata)

    try:
        visit(source, destination, ".")
    except BaseException:
        if destination.exists() and not destination.is_symlink():
            make_tree_writable(destination)
            shutil.rmtree(destination)
        raise

    manifest_payload = records_payload(records)
    report = {
        "bytes": counters["bytes"],
        "destination": str(destination),
        "directories": counters["directories"],
        "files": counters["files"],
        "format": COPY_FORMAT,
        "label": label,
        "manifest_sha256": hashlib.sha256(manifest_payload).hexdigest(),
        "source": str(source),
        "symlinks": counters["symlinks"],
    }
    atomic_write(output, canonical_record(report))


def copy_file(source: Path, destination: Path, label: str, output: Path) -> None:
    metadata = require_regular_file(source, "copy source")
    if destination.exists() or destination.is_symlink():
        fail(f"copy destination already exists: {destination}")
    require_real_directory(destination.parent, "copy destination parent")
    digest = copy_regular(source, destination, metadata)
    report = {
        "bytes": metadata.st_size,
        "destination": str(destination),
        "format": COPY_FORMAT,
        "label": label,
        "mode": mode_string(metadata),
        "sha256": digest,
        "source": str(source),
        "type": "file",
    }
    atomic_write(output, canonical_record(report))


def git_tracked_paths(repository: Path) -> list[str]:
    import subprocess

    result = subprocess.run(
        ["git", "-C", str(repository), "ls-files", "-z"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode:
        fail(
            f"cannot enumerate tracked files in {repository}: "
            + result.stderr.decode("utf-8", "replace").strip()
        )
    return [os.fsdecode(item) for item in result.stdout.split(b"\0") if item]


def prove_git_copy(source: Path, destination: Path, label: str, output: Path) -> None:
    require_real_directory(source, "Git copy source")
    require_real_directory(destination, "Git copy destination")
    paths = git_tracked_paths(source)
    files = 0
    symlinks = 0
    for relative in paths:
        source_path = source / relative
        destination_path = destination / relative
        source_metadata = source_path.lstat()
        destination_metadata = destination_path.lstat()
        source_kind = stat.S_IFMT(source_metadata.st_mode)
        destination_kind = stat.S_IFMT(destination_metadata.st_mode)
        if source_kind != destination_kind:
            fail(f"Git copy file type differs at {relative}")
        if stat.S_ISREG(source_metadata.st_mode):
            files += 1
            if (source_metadata.st_dev, source_metadata.st_ino) == (
                destination_metadata.st_dev,
                destination_metadata.st_ino,
            ):
                fail(f"Git copy shares a tracked-file inode at {relative}")
        elif stat.S_ISLNK(source_metadata.st_mode):
            symlinks += 1
            if os.readlink(source_path) != os.readlink(destination_path):
                fail(f"Git copy symlink differs at {relative}")
        else:
            fail(f"unsupported tracked Git entry type at {relative}")
    report = {
        "destination": str(destination),
        "files_with_distinct_inodes": files,
        "format": GIT_COPY_FORMAT,
        "label": label,
        "source": str(source),
        "symlinks": symlinks,
        "tracked_entries": len(paths),
    }
    atomic_write(output, canonical_record(report))


def remove_tree(path: Path, expected_parent: Path) -> None:
    require_real_directory(expected_parent, "cleanup parent")
    require_real_directory(path, "cleanup target")
    if path.parent != expected_parent:
        fail(f"cleanup target is not a direct child of {expected_parent}: {path}")

    make_tree_writable(path)
    shutil.rmtree(path)


def publish(source: Path, destination: Path, expected_parent: Path) -> None:
    require_real_directory(source, "publish source")
    require_real_directory(expected_parent, "publish parent")
    if destination.parent != expected_parent:
        fail(
            f"publish destination is not a direct child of {expected_parent}: "
            f"{destination}"
        )
    if destination.exists() or destination.is_symlink():
        fail(f"publish destination already exists: {destination}")
    if source.stat().st_dev != expected_parent.stat().st_dev:
        fail("publish source and destination parent are on different filesystems")
    os.rename(source, destination)
    require_real_directory(destination, "published output")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    copy_tree_parser = commands.add_parser("copy-tree")
    copy_tree_parser.add_argument("--source", required=True, type=Path)
    copy_tree_parser.add_argument("--destination", required=True, type=Path)
    copy_tree_parser.add_argument("--label", required=True)
    copy_tree_parser.add_argument("--output", required=True, type=Path)

    copy_file_parser = commands.add_parser("copy-file")
    copy_file_parser.add_argument("--source", required=True, type=Path)
    copy_file_parser.add_argument("--destination", required=True, type=Path)
    copy_file_parser.add_argument("--label", required=True)
    copy_file_parser.add_argument("--output", required=True, type=Path)

    proof_parser = commands.add_parser("prove-git-copy")
    proof_parser.add_argument("--source", required=True, type=Path)
    proof_parser.add_argument("--destination", required=True, type=Path)
    proof_parser.add_argument("--label", required=True)
    proof_parser.add_argument("--output", required=True, type=Path)

    snapshot_parser = commands.add_parser("snapshot")
    snapshot_parser.add_argument("--root", required=True, type=Path)
    snapshot_parser.add_argument("--output", required=True, type=Path)
    snapshot_parser.add_argument("--exclude", action="append", default=[])

    compare_parser = commands.add_parser("compare")
    compare_parser.add_argument("--before", required=True, type=Path)
    compare_parser.add_argument("--after", required=True, type=Path)

    remove_parser = commands.add_parser("remove-tree")
    remove_parser.add_argument("--path", required=True, type=Path)
    remove_parser.add_argument("--expected-parent", required=True, type=Path)

    publish_parser = commands.add_parser("publish")
    publish_parser.add_argument("--source", required=True, type=Path)
    publish_parser.add_argument("--destination", required=True, type=Path)
    publish_parser.add_argument("--expected-parent", required=True, type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    arguments = build_parser().parse_args(argv)
    if arguments.command == "copy-tree":
        copy_tree(arguments.source, arguments.destination, arguments.label, arguments.output)
    elif arguments.command == "copy-file":
        copy_file(arguments.source, arguments.destination, arguments.label, arguments.output)
    elif arguments.command == "prove-git-copy":
        prove_git_copy(
            arguments.source,
            arguments.destination,
            arguments.label,
            arguments.output,
        )
    elif arguments.command == "snapshot":
        snapshot(arguments.root, arguments.output, tuple(arguments.exclude))
    elif arguments.command == "compare":
        compare(arguments.before, arguments.after)
    elif arguments.command == "remove-tree":
        remove_tree(arguments.path, arguments.expected_parent)
    elif arguments.command == "publish":
        publish(arguments.source, arguments.destination, arguments.expected_parent)
    else:
        fail(f"unknown command: {arguments.command}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ReplayError, OSError) as error:
        print(f"physical_replay: REFUSING -- {error}", file=sys.stderr)
        raise SystemExit(2)
