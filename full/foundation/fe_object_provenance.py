#!/usr/bin/env python3
"""Attest the reusable FoundationEssentials object closure.

``build_full.sh`` produces a set of objects that the true-iOS platform builder
relinks later.  A source-subject digest protects the whole build, while this
ledger makes the byte-level relationship explicit: every consumed FE object is
hashed, and every project-owned source that directly owns one of those objects
is hashed beside it.  Verification renders the expected ledger from the active
project checkout and the supplied full-build directory, then compares it
byte-for-byte with the recorded ledger.

The paths below deliberately mirror the FE_OBJECTS arrays in build_full.sh and
build_true_ios_platform_frameworks.sh.  Adding an object to that reusable
closure therefore requires adding it here as well, where tests enforce the
complete contract.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import re
import stat
import sys
from typing import Iterable


SCHEMA = "true-ios-full-fe-object-provenance-v1"
SHA256_RE = re.compile(r"[0-9a-f]{64}\Z")

# Paths are relative to build/full.
FE_OBJECTS = (
    "foundation/essentials/FoundationEssentials.o",
    "foundation/collections/InternalCollectionsUtilities.o",
    "foundation/collections/OrderedCollections.o",
    "foundation/collections/_RopeModule.o",
    "foundation/os/os.o",
    "foundation/cshims/platform_shims.o",
    "foundation/cshims/string_shims.o",
    "foundation/cshims/uuid.o",
    "foundation/essentials/fm_unimplemented.o",
    "foundation/essentials/removefile_compat.o",
    "foundation/essentials/uuid_compat.o",
)

# Direct project-owned source relationships.  Upstream Foundation and
# Collections inputs are covered by the full source subject and pinned-input
# digest; these rows close the local compatibility sources that can otherwise
# be accidentally paired with an object from an older checkout.
PROJECT_OWNED_SOURCES = (
    ("foundation/os/os.o", "full/foundation/os-module/os.swift"),
    (
        "foundation/essentials/fm_unimplemented.o",
        "full/foundation/fm_unimplemented.c",
    ),
    (
        "foundation/essentials/removefile_compat.o",
        "full/foundation/removefile_compat.c",
    ),
    (
        "foundation/essentials/removefile_compat.o",
        "full/foundation/removefile_compat.h",
    ),
    (
        "foundation/essentials/uuid_compat.o",
        "full/foundation/uuid_compat.c",
    ),
)


class ProvenanceError(ValueError):
    """The requested provenance operation is unsafe or inconsistent."""


def _regular_file(path: Path, description: str) -> Path:
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError as error:
        raise ProvenanceError(f"missing {description}: {path}") from error
    if path.is_symlink() or not stat.S_ISREG(mode):
        raise ProvenanceError(f"{description} is not a regular non-symlink file: {path}")
    return path


def _sha256(path: Path, description: str) -> str:
    path = _regular_file(path, description)
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def render(project: Path, full: Path, subject: str) -> bytes:
    if not SHA256_RE.fullmatch(subject):
        raise ProvenanceError("full source subject must be one lowercase SHA-256")
    project = project.resolve(strict=True)
    full = full.resolve(strict=True)

    object_set = set(FE_OBJECTS)
    source_object_set = {object_path for object_path, _ in PROJECT_OWNED_SOURCES}
    if not source_object_set.issubset(object_set):
        raise ProvenanceError("project-owned source map names an unconsumed FE object")

    rows = [f"schema\t{SCHEMA}", f"full-subject\t{subject}"]
    for object_path, source_path in PROJECT_OWNED_SOURCES:
        digest = _sha256(project / source_path, f"project-owned FE source {source_path}")
        rows.append(f"source\t{object_path}\t{source_path}\t{digest}")
    for object_path in FE_OBJECTS:
        digest = _sha256(full / object_path, f"reusable FE object {object_path}")
        rows.append(f"object\t{object_path}\t{digest}")
    return ("\n".join(rows) + "\n").encode("ascii")


def _first_difference(expected: bytes, recorded: bytes) -> str:
    expected_lines = expected.decode("ascii", errors="replace").splitlines()
    recorded_lines = recorded.decode("ascii", errors="replace").splitlines()
    for index, (wanted, got) in enumerate(
        zip(expected_lines, recorded_lines, strict=False), 1
    ):
        if wanted != got:
            return f"line {index}: expected {wanted!r}, recorded {got!r}"
    if len(expected_lines) != len(recorded_lines):
        return (
            "line count differs: "
            f"expected {len(expected_lines)}, recorded {len(recorded_lines)}"
        )
    return "byte encoding differs"


def verify(project: Path, full: Path, subject: str, attestation: Path) -> None:
    expected = render(project, full, subject)
    attestation = _regular_file(attestation, "FE object provenance attestation")
    recorded = attestation.read_bytes()
    if recorded != expected:
        raise ProvenanceError(
            "FE object provenance does not match the active project sources and "
            f"full-build objects ({_first_difference(expected, recorded)})"
        )


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("attest", "verify"):
        operation = subparsers.add_parser(command)
        operation.add_argument("--project", required=True, type=Path)
        operation.add_argument("--full", required=True, type=Path)
        operation.add_argument("--subject", required=True)
        if command == "verify":
            operation.add_argument("--attestation", required=True, type=Path)
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    arguments = _parser().parse_args(argv)
    try:
        if arguments.command == "attest":
            sys.stdout.buffer.write(
                render(arguments.project, arguments.full, arguments.subject)
            )
        else:
            verify(
                arguments.project,
                arguments.full,
                arguments.subject,
                arguments.attestation,
            )
    except (OSError, ProvenanceError) as error:
        print(f"fe_object_provenance: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
