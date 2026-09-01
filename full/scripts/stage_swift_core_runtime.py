#!/usr/bin/env python3
"""Stage the canonical Mach-O Swift core over any stale base-runtime copy."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import tempfile


class StageError(RuntimeError):
    pass


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require_regular(path: Path, label: str) -> os.stat_result:
    try:
        metadata = path.lstat()
    except FileNotFoundError as error:
        raise StageError(f"{label} is missing: {path}") from error
    if not stat.S_ISREG(metadata.st_mode):
        raise StageError(f"{label} is not a regular non-symlink file: {path}")
    return metadata


def validate_sha256(value: str) -> None:
    if len(value) != 64 or any(character not in "0123456789abcdef" for character in value):
        raise StageError("expected SHA-256 must be lowercase 64-hex")


def atomic_copy(source: Path, destination: Path, mode: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists() or destination.is_symlink():
        require_regular(destination, "existing destination")
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{destination.name}.INCOMPLETE.", dir=destination.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as output, source.open("rb") as input_stream:
            shutil.copyfileobj(input_stream, output, length=1024 * 1024)
            output.flush()
            os.fsync(output.fileno())
        os.chmod(temporary, stat.S_IMODE(mode))
        os.replace(temporary, destination)
    finally:
        if temporary.exists() or temporary.is_symlink():
            temporary.unlink()


def write_report(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() or path.is_symlink():
        raise StageError(f"report path already exists: {path}")
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.INCOMPLETE.", dir=path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as stream:
            json.dump(payload, stream, sort_keys=True, separators=(",", ":"))
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if temporary.exists() or temporary.is_symlink():
            temporary.unlink()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--canonical", required=True, type=Path)
    parser.add_argument("--base", required=True, type=Path)
    parser.add_argument("--destination", required=True, type=Path)
    parser.add_argument("--expected-sha256", required=True)
    parser.add_argument("--report", required=True, type=Path)
    arguments = parser.parse_args()

    try:
        validate_sha256(arguments.expected_sha256)
        canonical_metadata = require_regular(arguments.canonical, "canonical Swift core")
        require_regular(arguments.base, "base-runtime Swift core")
        canonical_sha = sha256(arguments.canonical)
        base_sha = sha256(arguments.base)
        if canonical_sha != arguments.expected_sha256:
            raise StageError(
                f"canonical Swift core hash {canonical_sha}, expected {arguments.expected_sha256}"
            )
        atomic_copy(arguments.canonical, arguments.destination, canonical_metadata.st_mode)
        staged_sha = sha256(arguments.destination)
        if staged_sha != canonical_sha:
            raise StageError(
                f"staged Swift core hash {staged_sha}, expected canonical {canonical_sha}"
            )
        payload: dict[str, object] = {
            "base_matches_canonical": base_sha == canonical_sha,
            "base_sha256": base_sha,
            "canonical_sha256": canonical_sha,
            "destination": str(arguments.destination),
            "format": "swift-core-runtime-stage-v1",
            "staged_sha256": staged_sha,
        }
        write_report(arguments.report, payload)
    except StageError as error:
        parser.error(str(error))

    print(
        "SWIFT_CORE_RUNTIME_STAGED "
        f"sha256={canonical_sha} base_matches={int(base_sha == canonical_sha)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
