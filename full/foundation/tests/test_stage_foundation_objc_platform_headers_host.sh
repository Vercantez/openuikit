#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
STAGER=$ROOT/full/foundation/stage_objc_platform_headers.sh
PROOF=$(mktemp -d /private/tmp/foundation-objc-platform-stager.XXXXXX)
cleanup() {
    /usr/bin/trash "$PROOF" 2>/dev/null || true
}
trap cleanup EXIT

DESTINATION=$PROOF/include
mkdir -p "$DESTINATION"
printf 'preserve-unrelated\n' > "$DESTINATION/unrelated.txt"

first_output=$(bash "$STAGER" "$DESTINATION")
test "$first_output" = \
    "FOUNDATION_OBJC_PLATFORM_HEADERS_STAGED_OK headers=5 destination=$DESTINATION"
python3 - "$DESTINATION" \
    "$ROOT/full/foundation/foundation_objc_platform_headers.sha256" \
    "$PROOF/inodes-before.txt" <<'PY'
import hashlib
from pathlib import Path
import sys

destination = Path(sys.argv[1])
manifest = Path(sys.argv[2])
inode_output = Path(sys.argv[3])
rows = []
for line in manifest.read_text().splitlines():
    expected, relative = line.split("  ", 1)
    target = destination / relative
    assert target.is_file() and not target.is_symlink()
    assert hashlib.sha256(target.read_bytes()).hexdigest() == expected
    rows.append(f"{relative}\t{target.stat().st_ino}")
inode_output.write_text("\n".join(rows) + "\n")
PY
test "$(cat "$DESTINATION/unrelated.txt")" = preserve-unrelated

second_output=$(bash "$STAGER" "$DESTINATION")
test "$second_output" = "$first_output"
python3 - "$DESTINATION" \
    "$ROOT/full/foundation/foundation_objc_platform_headers.sha256" \
    "$PROOF/inodes-after.txt" <<'PY'
from pathlib import Path
import sys

destination = Path(sys.argv[1])
manifest = Path(sys.argv[2])
inode_output = Path(sys.argv[3])
rows = []
for line in manifest.read_text().splitlines():
    _, relative = line.split("  ", 1)
    target = destination / relative
    rows.append(f"{relative}\t{target.stat().st_ino}")
inode_output.write_text("\n".join(rows) + "\n")
PY
cmp "$PROOF/inodes-before.txt" "$PROOF/inodes-after.txt"

printf 'mutation\n' >> "$DESTINATION/Foundation/NSObject.h"
if bash "$STAGER" "$DESTINATION" \
    > "$PROOF/mutated.stdout" 2> "$PROOF/mutated.stderr"; then
    echo 'mutated Foundation header was accepted' >&2
    exit 1
fi
grep -Fq 'Foundation header destination already differs for Foundation/NSObject.h' \
    "$PROOF/mutated.stderr"
rm "$DESTINATION/Foundation/NSObject.h"
bash "$STAGER" "$DESTINATION" >/dev/null

rm "$DESTINATION/Foundation/NSZone.h"
ln -s "$ROOT/full/foundation/include/Foundation/NSZone.h" \
    "$DESTINATION/Foundation/NSZone.h"
if bash "$STAGER" "$DESTINATION" \
    > "$PROOF/symlink.stdout" 2> "$PROOF/symlink.stderr"; then
    echo 'symlink Foundation header was accepted' >&2
    exit 1
fi
grep -Fq 'Foundation header destination is a symlink' \
    "$PROOF/symlink.stderr"

PARTIAL_DESTINATION=$PROOF/partial/include
mkdir -p "$PARTIAL_DESTINATION" "$PROOF/escape"
ln -s "$PROOF/escape" "$PARTIAL_DESTINATION/Foundation"
if bash "$STAGER" "$PARTIAL_DESTINATION" \
    > "$PROOF/partial.stdout" 2> "$PROOF/partial.stderr"; then
    echo 'symlink parent Foundation header path was accepted' >&2
    exit 1
fi
grep -Fq 'Foundation header destination traverses symlink' \
    "$PROOF/partial.stderr"
test ! -e "$PARTIAL_DESTINATION/CoreFoundation"
test ! -e "$PARTIAL_DESTINATION/arpa"

if (
    cd "$PROOF"
    bash "$STAGER" relative/include
) > "$PROOF/relative.stdout" 2> "$PROOF/relative.stderr"; then
    echo 'relative Foundation header destination was accepted' >&2
    exit 1
fi
grep -Fq 'Foundation header destination must be absolute' \
    "$PROOF/relative.stderr"

test -z "$(find "$DESTINATION" -type f -name '.*.??????' -print -quit)"
printf 'FOUNDATION_OBJC_PLATFORM_HEADER_STAGER_HOST_OK headers=5 idempotent=inode mutation=refused partial=none\n'
