#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <sdk-usr-include-directory>" >&2
    exit 64
fi

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
DESTINATION=$1

python3 - \
    "$ROOT" \
    "$DESTINATION" \
    "$ROOT/full/foundation/foundation_objc_headers.txt" \
    "$ROOT/full/foundation/foundation_objc_platform_headers.sha256" <<'PY'
import hashlib
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import sys
import tempfile

root = Path(sys.argv[1]).resolve(strict=True)
destination_argument = Path(sys.argv[2])
foundation_manifest = Path(sys.argv[3])
hash_manifest = Path(sys.argv[4])

if not destination_argument.is_absolute():
    raise SystemExit("Foundation header destination must be absolute")
if destination_argument.is_symlink() or not destination_argument.is_dir():
    raise SystemExit("Foundation header destination must be a real directory")
destination = destination_argument.resolve(strict=True)
if destination in {Path("/"), Path("/usr"), Path("/usr/include"), Path.home()}:
    raise SystemExit(f"refusing unsafe Foundation header destination: {destination}")

foundation_headers = foundation_manifest.read_text().splitlines()
if foundation_headers != sorted(foundation_headers):
    raise SystemExit("Foundation Objective-C header manifest is not sorted")
if len(foundation_headers) != len(set(foundation_headers)) or not foundation_headers:
    raise SystemExit("Foundation Objective-C header manifest has duplicates or is empty")

entries: list[tuple[str, str]] = []
for line in hash_manifest.read_text().splitlines():
    match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
    if match is None:
        raise SystemExit(f"invalid Foundation header hash row: {line!r}")
    entries.append((match.group(2), match.group(1)))

relative_paths = [relative for relative, _ in entries]
if relative_paths != sorted(relative_paths):
    raise SystemExit("Foundation Objective-C platform hash manifest is not sorted")
if len(entries) != len(set(relative_paths)) or len(entries) != 5:
    raise SystemExit("Foundation Objective-C platform hash manifest cardinality drifted")
if relative_paths != foundation_headers + ["arpa/inet.h"]:
    raise SystemExit("Foundation Objective-C platform/header manifests disagree")

def checked_relative(value: str) -> PurePosixPath:
    relative = PurePosixPath(value)
    if relative.is_absolute() or not relative.parts or any(
        part in {"", ".", ".."} for part in relative.parts
    ):
        raise SystemExit(f"unsafe Foundation header relative path: {value!r}")
    return relative

def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()

validated: list[tuple[Path, Path, str]] = []
for relative_value, expected_hash in entries:
    relative = checked_relative(relative_value)
    if relative_value == "arpa/inet.h":
        source = root / "full/sdk-gaps/usr/include" / Path(*relative.parts)
    else:
        source = root / "full/foundation/include" / Path(*relative.parts)
    if source.is_symlink() or not source.is_file():
        raise SystemExit(f"Foundation header source is not a regular file: {source}")
    actual_hash = digest(source)
    if actual_hash != expected_hash:
        raise SystemExit(
            f"Foundation header source hash drifted for {relative_value}: "
            f"{actual_hash} != {expected_hash}"
        )

    target = destination / Path(*relative.parts)
    parent = destination
    for part in relative.parts[:-1]:
        parent = parent / part
        if parent.is_symlink():
            raise SystemExit(f"Foundation header destination traverses symlink: {parent}")
        if parent.exists() and not parent.is_dir():
            raise SystemExit(f"Foundation header destination parent is not a directory: {parent}")
    if target.is_symlink():
        raise SystemExit(f"Foundation header destination is a symlink: {target}")
    if target.exists():
        if not target.is_file():
            raise SystemExit(f"Foundation header destination is not a regular file: {target}")
        actual_target_hash = digest(target)
        if actual_target_hash != expected_hash:
            raise SystemExit(
                f"Foundation header destination already differs for {relative_value}: "
                f"{actual_target_hash} != {expected_hash}"
            )
    validated.append((source, target, expected_hash))

# No target is touched until every source, path and pre-existing destination
# has passed validation. New files are atomically installed; matching files
# are deliberately left in place so a second invocation is a true no-op.
for source, target, expected_hash in validated:
    if target.exists():
        continue
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=target.parent,
            prefix=f".{target.name}.",
            delete=False,
        ) as temporary:
            temporary_name = temporary.name
            with source.open("rb") as stream:
                shutil.copyfileobj(stream, temporary)
            temporary.flush()
            os.fsync(temporary.fileno())
        os.chmod(temporary_name, 0o644)
        if digest(Path(temporary_name)) != expected_hash:
            raise SystemExit(f"staged Foundation header hash mismatch: {target}")
        os.replace(temporary_name, target)
        temporary_name = None
    finally:
        if temporary_name is not None:
            Path(temporary_name).unlink(missing_ok=True)

for _, target, expected_hash in validated:
    if target.is_symlink() or not target.is_file() or digest(target) != expected_hash:
        raise SystemExit(f"Foundation header post-stage verification failed: {target}")

print(
    "FOUNDATION_OBJC_PLATFORM_HEADERS_STAGED_OK "
    f"headers={len(validated)} destination={destination}"
)
PY
