#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
APP=${1:-/private/tmp/app-wave-20260831/IceCubesApp}
SWIFTSOUP=${2:-/private/tmp/icecubes-remote-cache-v3-20260831/objects/sha256/68/6849e872eba1be19c0f0681885de5f3e9ea852cada1f2d0d3c88749e5674907e/repository}
EXPECTED_APP_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_APP_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
EXPECTED_SOUP_COMMIT=8d6ad267714cac3ae747cefdd21f7a6665006e1f
EXPECTED_SOUP_TREE=6e04f61b3cb45c12ec9bb3c86b1f76748e055d8d
EXPECTED_MODELS_DIGEST=5a3c19d508c19f43f74395725b87c9f3e44bd5b16da9d6dd7ba6a92f19a2b71a
FRONTIER=$ROOT/full/swiftdata/tests/icecubes_swiftdata_frontier.tsv
OUTPUT=$(mktemp -d /private/tmp/swiftdata-host-proof.XXXXXX)
trap 'rm -rf "$OUTPUT"' EXIT

for checkout in "$APP" "$SWIFTSOUP"; do
    [ -d "$checkout/.git" ] || { printf 'missing checkout: %s\n' "$checkout" >&2; exit 2; }
    [ -z "$(git -C "$checkout" status --short)" ] \
        || { printf 'checkout is not untouched: %s\n' "$checkout" >&2; exit 2; }
done
[ "$(git -C "$APP" rev-parse HEAD^{commit})" = "$EXPECTED_APP_COMMIT" ]
[ "$(git -C "$APP" rev-parse HEAD^{tree})" = "$EXPECTED_APP_TREE" ]
[ "$(git -C "$SWIFTSOUP" rev-parse HEAD^{commit})" = "$EXPECTED_SOUP_COMMIT" ]
[ "$(git -C "$SWIFTSOUP" rev-parse HEAD^{tree})" = "$EXPECTED_SOUP_TREE" ]

python3 -B - "$APP" "$FRONTIER" "$EXPECTED_MODELS_DIGEST" <<'PY'
from pathlib import Path
import hashlib
import re
import sys

app, policy, expected_models_digest = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
observed = []
pattern = re.compile(r"^\s*import\s+SwiftData\s*$", re.MULTILINE)
for source in sorted(app.rglob("*.swift")):
    if pattern.search(source.read_text(encoding="utf-8")):
        observed.append((
            source.relative_to(app).as_posix(),
            hashlib.sha256(source.read_bytes()).hexdigest(),
        ))
expected = []
for line in policy.read_text(encoding="utf-8").splitlines():
    fields = line.split("\t")
    if fields[0] == "source":
        expected.append(tuple(fields[1:]))
if observed != expected or len(observed) != 27:
    raise SystemExit(f"SwiftData import frontier drifted:\n{observed!r}")

rows = []
for source in sorted((app / "Packages/Models/Sources/Models").rglob("*.swift")):
    rows.append(
        f"{source.relative_to(app).as_posix()}\t"
        f"{hashlib.sha256(source.read_bytes()).hexdigest()}\n"
    )
digest = hashlib.sha256("".join(rows).encode()).hexdigest()
if len(rows) != 54 or digest != expected_models_digest:
    raise SystemExit(f"Models target drifted: count={len(rows)} digest={digest}")
PY

HOST_LIB=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host
FOUNDATION_MACROS=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins/libFoundationMacros.dylib

xcrun swiftc -parse-as-library -emit-library \
    -module-name SwiftDataMacros -I "$HOST_LIB" -L "$HOST_LIB" \
    -Xlinker -rpath -Xlinker "$HOST_LIB" \
    "$ROOT/full/swiftdata/SwiftDataMacros.swift" \
    -o "$OUTPUT/libSwiftDataMacros.dylib"

xcrun swiftc -parse-as-library -module-name SwiftData \
    -emit-module -emit-module-path "$OUTPUT/SwiftData.swiftmodule" \
    -emit-library -Xlinker -install_name -Xlinker @rpath/libSwiftData.dylib \
    -load-plugin-library "$OUTPUT/libSwiftDataMacros.dylib" \
    "$ROOT/full/swiftdata/SwiftData.swift" -o "$OUTPUT/libSwiftData.dylib"

mapfile -t SWIFTSOUP_SOURCES < <(find "$SWIFTSOUP/Sources" \
    -type f -name '*.swift' -print | LC_ALL=C sort)
[ "${#SWIFTSOUP_SOURCES[@]}" -eq 60 ]
xcrun swiftc -parse-as-library -module-name SwiftSoup \
    -emit-module -emit-module-path "$OUTPUT/SwiftSoup.swiftmodule" \
    "${SWIFTSOUP_SOURCES[@]}"

mapfile -t MODELS_SOURCES < <(find "$APP/Packages/Models/Sources/Models" \
    -type f -name '*.swift' -print | LC_ALL=C sort)
[ "${#MODELS_SOURCES[@]}" -eq 54 ]
xcrun swiftc -parse-as-library -suppress-warnings -module-name Models \
    -typecheck -I "$OUTPUT" \
    -load-plugin-library "$OUTPUT/libSwiftDataMacros.dylib" \
    -load-plugin-library "$FOUNDATION_MACROS" \
    "${MODELS_SOURCES[@]}"

xcrun swiftc -parse-as-library -I "$OUTPUT" -L "$OUTPUT" -lSwiftData \
    -load-plugin-library "$OUTPUT/libSwiftDataMacros.dylib" \
    -load-plugin-library "$FOUNDATION_MACROS" \
    "$ROOT/full/swiftdata/tests/SwiftDataHostRuntime.swift" \
    -o "$OUTPUT/SwiftDataHostRuntime"

DYLD_LIBRARY_PATH="$OUTPUT" "$OUTPUT/SwiftDataHostRuntime" \
    2>"$OUTPUT/SwiftDataHostRuntime.stderr" \
    | grep -Fxq \
    'SWIFTDATA_HOST_RUNTIME_OK models=2 predicate=filtered sort=descending query=live rollback=restored durable=fail-closed macro=attached'
[ "$(grep -Fxc 'SwiftData: durable storage unavailable; using a volatile in-memory container' \
    "$OUTPUT/SwiftDataHostRuntime.stderr")" -eq 1 ]

[ "$(xcrun otool -D "$OUTPUT/libSwiftData.dylib" \
    | grep -Fc '@rpath/libSwiftData.dylib')" -eq 1 ]
! xcrun otool -L "$OUTPUT/libSwiftData.dylib" \
    | grep -F '/System/Library/Frameworks/SwiftData.framework/' >/dev/null

printf 'SWIFTDATA_HOST_GATE_OK module=SwiftData dylib=standalone macros=SwiftDataMacros,FoundationMacros\n'
printf 'SWIFTDATA_EXACT_MODELS_OK app=%s:%s imports=27 models=54:%s swiftsoup=%s:%s:60\n' \
    "$EXPECTED_APP_COMMIT" "$EXPECTED_APP_TREE" "$EXPECTED_MODELS_DIGEST" \
    "$EXPECTED_SOUP_COMMIT" "$EXPECTED_SOUP_TREE"
