#!/usr/bin/env bash
set -euo pipefail

die() {
    printf 'COREAUDIOTYPES_AGENT_GATE_REFUSING: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel 2>/dev/null) \
    || die 'framework is not inside a Git worktree'

for command_name in python3 swiftc; do
    command -v "$command_name" >/dev/null 2>&1 \
        || die "$command_name is unavailable"
done
if [ -n "${CC:-}" ]; then
    C_COMPILER=$CC
elif command -v clang >/dev/null 2>&1; then
    C_COMPILER=clang
elif command -v cc >/dev/null 2>&1; then
    C_COMPILER=cc
else
    die 'no C compiler is available'
fi
command -v "$C_COMPILER" >/dev/null 2>&1 \
    || die "configured C compiler is unavailable: $C_COMPILER"
for stale in .build build scratch; do
    [ ! -e "$FRAMEWORK_ROOT/$stale" ] \
        || die "stale product directory exists: $stale"
done

bash "$FRAMEWORK_ROOT/tests/acceptance/test_host.sh"

TMP=$(mktemp -d "${TMPDIR:-/tmp}/coreaudiotypes-agent.XXXXXX") \
    || die 'cannot create isolated stage'
cleanup() {
    find "$TMP" -depth -delete
}
trap cleanup EXIT HUP INT TERM

SOURCES=()
while IFS= read -r relative; do
    [ -n "$relative" ] || die 'blank product-source row'
    SOURCES+=("$REPO_ROOT/$relative")
done < "$FRAMEWORK_ROOT/coreaudiotypes_guest_sources.txt"
[ "${#SOURCES[@]}" -gt 0 ] || die 'empty product-source manifest'

swiftc -warnings-as-errors -parse-as-library -enable-library-evolution \
    -emit-library -emit-module \
    -emit-module-interface-path "$TMP/CoreAudioTypes.swiftinterface" \
    -module-name CoreAudioTypes \
    -emit-module-path "$TMP/CoreAudioTypes.swiftmodule" \
    -o "$TMP/libCoreAudioTypes.dylib" \
    "${SOURCES[@]}"
test -s "$TMP/libCoreAudioTypes.dylib" \
    || die 'libCoreAudioTypes.dylib was not produced'

grep -Fq 'public typealias OSType = Swift.UInt32' "$TMP/CoreAudioTypes.swiftinterface" \
    || die 'OSType alias is absent from emitted interface'
grep -Fq 'public typealias OSStatus = Swift.Int32' "$TMP/CoreAudioTypes.swiftinterface" \
    || die 'OSStatus alias is absent from emitted interface'
if grep -Eq 'CoreAudioTypesFlexibleArray|coreAudioTypesFourCC' "$TMP/CoreAudioTypes.swiftinterface"; then
    die 'an internal helper leaked into the emitted interface'
fi

TARGET=$(swiftc -print-target-info \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["target"]["triple"])')
mkdir "$TMP/symbols"
SYMBOLGRAPH_ARGS=(
    -module-name CoreAudioTypes
    -I "$TMP"
    -target "$TARGET"
    -output-dir "$TMP/symbols"
)
if command -v swift-symbolgraph-extract >/dev/null 2>&1; then
    SYMBOLGRAPH_TOOL=$(command -v swift-symbolgraph-extract)
elif command -v xcrun >/dev/null 2>&1; then
    SYMBOLGRAPH_TOOL=$(xcrun --find swift-symbolgraph-extract)
    SYMBOLGRAPH_ARGS+=( -sdk "$(xcrun --sdk macosx --show-sdk-path)" )
else
    die 'swift-symbolgraph-extract is unavailable'
fi
"$SYMBOLGRAPH_TOOL" "${SYMBOLGRAPH_ARGS[@]}"

python3 -B - \
    "$TMP/symbols/CoreAudioTypes.symbols.json" \
    "$FRAMEWORK_ROOT/reference/public-surface.tsv" \
    "$FRAMEWORK_ROOT/tests/agent/CoreAudioTypesAppleOracleRuntime.swift" <<'PY'
import csv
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    graph = json.load(handle)
current = {
    (
        symbol["kind"]["identifier"],
        ".".join(symbol.get("pathComponents", [])),
        symbol["names"]["title"],
    )
    for symbol in graph["symbols"]
}
with open(sys.argv[2], encoding="utf-8", newline="") as handle:
    reference = {
        (row["kind"], row["path"], row["title"])
        for row in csv.DictReader(handle, delimiter="\t")
    }
compatibility_scaffolding = {
    ("swift.typealias", "OSType", "OSType"),
    ("swift.typealias", "OSStatus", "OSStatus"),
    ("swift.property", "AudioChannelBitmap.rawValue", "rawValue"),
    ("swift.property", "AudioChannelFlags.rawValue", "rawValue"),
    ("swift.property", "AudioTimeStampFlags.rawValue", "rawValue"),
    ("swift.property", "SMPTETimeFlags.rawValue", "rawValue"),
}
dependency_deferred = {
    entry for entry in reference if entry[1].startswith("AVAudioSession.ErrorCode")
}
expected = (reference - dependency_deferred) | compatibility_scaffolding
if current != expected:
    extra = sorted(current - expected)
    missing = sorted(expected - current)
    raise SystemExit(
        "COREAUDIOTYPES_AGENT_GATE_REFUSING: emitted surface differs "
        f"extra={extra} missing={missing}"
    )
required_values = set()
with open(sys.argv[2], encoding="utf-8", newline="") as handle:
    for row in csv.DictReader(handle, delimiter="\t"):
        kind = row["kind"]
        path = row["path"]
        if path.startswith("AVAudioSession.ErrorCode"):
            continue
        if kind == "swift.var" and "." not in path:
            required_values.add(path)
        elif kind in {"swift.enum.case", "swift.type.property"}:
            required_values.add(path + ".rawValue")
observed_values = set()
with open(sys.argv[3], encoding="utf-8") as handle:
    for line in handle:
        stripped = line.strip()
        if stripped.startswith("expectBits("):
            observed_values.add(stripped.rsplit('"', 2)[1])
if observed_values != required_values:
    raise SystemExit(
        "COREAUDIOTYPES_AGENT_GATE_REFUSING: Apple-oracle inventory differs "
        f"extra={sorted(observed_values - required_values)} "
        f"missing={sorted(required_values - observed_values)}"
    )
print(
    "COREAUDIOTYPES_PUBLIC_SURFACE_OK "
    f"pinned={len(reference)} dependency_deferred={len(dependency_deferred)} "
    f"scaffolding={len(compatibility_scaffolding)} "
    f"oracle_values={len(observed_values)}"
)
PY

run_with_library() {
    if [ "$(uname -s)" = Darwin ]; then
        DYLD_LIBRARY_PATH="$TMP${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" "$@"
    else
        LD_LIBRARY_PATH="$TMP${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$@"
    fi
}

swiftc -warnings-as-errors -I "$TMP" \
    "$FRAMEWORK_ROOT/tests/agent/CoreAudioTypesRuntime.swift" \
    "$TMP/libCoreAudioTypes.dylib" \
    -o "$TMP/runtime"
runtime_output=$(run_with_library "$TMP/runtime")
printf '%s\n' "$runtime_output" | grep -Fqx 'COREAUDIOTYPES_AGENT_RUNTIME_OK' \
    || die 'ordinary-import runtime marker is absent'

swiftc -warnings-as-errors -parse-as-library -I "$TMP" \
    "$FRAMEWORK_ROOT/tests/agent/CoreAudioTypesAppleOracleRuntime.swift" \
    "$TMP/libCoreAudioTypes.dylib" \
    -o "$TMP/apple-oracle-runtime"
oracle_output=$(run_with_library "$TMP/apple-oracle-runtime")
printf '%s\n' "$oracle_output" \
    | grep -Fqx 'COREAUDIOTYPES_APPLE_ORACLE_VALUES_OK' \
    || die 'Apple-oracle value marker is absent'

swiftc -warnings-as-errors -parse-as-library \
    "${SOURCES[@]}" \
    "$FRAMEWORK_ROOT/tests/agent/CoreAudioTypesFlexibleArrayRuntime.swift" \
    -o "$TMP/flexible-runtime"
flexible_output=$("$TMP/flexible-runtime")
printf '%s\n' "$flexible_output" \
    | grep -Fqx 'COREAUDIOTYPES_FLEXIBLE_ARRAY_OK' \
    || die 'flexible-array marker is absent'

"$C_COMPILER" -std=c11 -Wall -Wextra -Werror \
    "$FRAMEWORK_ROOT/tests/agent/CoreAudioTypesCLayout.c" \
    -o "$TMP/c-layout"
c_output=$("$TMP/c-layout")
printf '%s\n' "$c_output" | grep -Fqx 'COREAUDIOTYPES_C_LAYOUT_OK' \
    || die 'C-layout marker is absent'
[ "$(printf '%s\n' "$c_output" | wc -l | tr -d ' ')" = 70 ] \
    || die 'C-layout fixture emitted an unexpected number of observations'
c_trail=$(printf '%s\n' "$c_output" | grep '^TRAIL ')
swift_trail=$(printf '%s\n' "$runtime_output" | grep '^TRAIL ')
[ "$c_trail" = "$swift_trail" ] \
    || die "C/Swift trailing-array layout differs: C=$c_trail Swift=$swift_trail"

swiftc -warnings-as-errors -parse-as-library -typecheck -I "$TMP" \
    "$FRAMEWORK_ROOT/tests/agent/CoreAudioTypesCoreFoundationIdentity.swift"

file "$TMP/libCoreAudioTypes.dylib"
"$C_COMPILER" --version | sed -n '1,3p'
printf '%s\n' "$runtime_output"
printf '%s\n' "$oracle_output"
printf '%s\n' "$flexible_output"
printf '%s\n' "$c_trail"
printf 'COREAUDIOTYPES_AGENT_INTEGRATION_OK module=CoreAudioTypes dylib=libCoreAudioTypes.dylib\n'
