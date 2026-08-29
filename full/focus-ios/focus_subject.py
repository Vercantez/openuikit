#!/usr/bin/env python3
"""Fail-closed attestation for the exact Focus Swift source subject."""

from __future__ import annotations

import hashlib
import json
import os
import stat
import subprocess
import sys
from pathlib import Path
from typing import NoReturn


def refuse(message: str) -> NoReturn:
    print(f"REFUSED Focus source subject: {message}", file=sys.stderr)
    raise SystemExit(2)


def git(repo: Path, *arguments: str) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(repo), *arguments],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        detail = result.stderr.decode(errors="replace").strip()
        refuse(f"git {' '.join(arguments)} failed: {detail}")
    return result.stdout


def sha256(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def live_swift_paths(app: Path) -> set[str]:
    paths: set[str] = set()
    for directory, child_directories, filenames in os.walk(app, followlinks=False):
        base = Path(directory)
        for child in list(child_directories):
            candidate = base / child
            if candidate.is_symlink():
                child_directories.remove(child)
                if candidate.name.endswith(".swift"):
                    paths.add(candidate.relative_to(app).as_posix())
        for filename in filenames:
            if filename.endswith(".swift"):
                paths.add((base / filename).relative_to(app).as_posix())
    return paths


def main() -> None:
    if len(sys.argv) != 4:
        print(
            "usage: focus_subject.py APP EXPECTED_COMMIT OUTPUT_JSON",
            file=sys.stderr,
        )
        raise SystemExit(64)

    raw_app = Path(sys.argv[1])
    if raw_app.is_symlink():
        refuse(f"application root is a symlink: {raw_app}")
    try:
        app = raw_app.resolve(strict=True)
    except FileNotFoundError:
        refuse(f"application root does not exist: {raw_app}")
    expected_commit = sys.argv[2]
    output = Path(sys.argv[3])

    repo_text = git(app, "rev-parse", "--show-toplevel").decode().strip()
    repo = Path(repo_text).resolve(strict=True)
    try:
        app_relative = app.relative_to(repo).as_posix()
    except ValueError:
        refuse(f"application root {app} is outside repository {repo}")
    if app_relative != "focus-ios":
        refuse(f"expected repository subdirectory 'focus-ios', got {app_relative!r}")

    head = git(repo, "rev-parse", "HEAD").decode().strip()
    if head != expected_commit:
        refuse(f"expected commit {expected_commit}, got {head}")

    status = git(repo, "status", "--porcelain=v1", "--untracked-files=all")
    if status:
        refuse("checkout has tracked or untracked changes:\n" + status.decode(errors="replace"))

    tree_output = git(
        repo,
        "ls-tree",
        "-r",
        "-z",
        "--name-only",
        head,
        "--",
        app_relative,
    )
    prefix = app_relative + "/"
    tracked = {
        path[len(prefix) :]
        for path in tree_output.decode().split("\0")
        if path.startswith(prefix) and path.endswith(".swift")
    }
    live = live_swift_paths(app)
    if live != tracked:
        missing = sorted(tracked - live)
        extra = sorted(live - tracked)
        refuse(
            "Swift inventory differs from the pinned tree; "
            f"missing={missing!r}, extra={extra!r}"
        )

    records: list[dict[str, object]] = []
    for relative in sorted(tracked):
        source = app / relative
        mode = source.lstat().st_mode
        if not stat.S_ISREG(mode) or source.is_symlink():
            refuse(f"Swift input is not a regular non-symlink file: {relative}")
        live_payload = source.read_bytes()
        tree_path = f"{app_relative}/{relative}"
        committed_payload = git(repo, "show", f"{head}:{tree_path}")
        if live_payload != committed_payload:
            refuse(f"Swift input bytes differ from pinned commit: {relative}")
        records.append(
            {
                "path": relative,
                "sha256": sha256(live_payload),
                "size": len(live_payload),
            }
        )

    digest_payload = b"".join(
        record["path"].encode()
        + b"\0"
        + record["sha256"].encode()
        + b"\0"
        + str(record["size"]).encode()
        + b"\n"
        for record in records
    )
    report = {
        "schema": 1,
        "repository_commit": head,
        "application_root": app_relative,
        "swift_source_count": len(records),
        "swift_subject_sha256": sha256(digest_payload),
        "sources": records,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print(
        "  Focus source subject: "
        f"{len(records)} pinned Swift files, {report['swift_subject_sha256']}"
    )


if __name__ == "__main__":
    main()
