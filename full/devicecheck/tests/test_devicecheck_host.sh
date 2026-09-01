#!/usr/bin/env bash
# Linux swiftc source-surface typecheck, cold runtime, boundary, and
# provenance gate for the DeviceCheck pilot. Does not require an Apple SDK
# or corpus application checkouts.

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
FRAMEWORK_DIR=$ROOT/full/devicecheck
REFERENCE=$FRAMEWORK_DIR/reference
SOURCE=$FRAMEWORK_DIR/DeviceCheck.swift
MANIFEST=$FRAMEWORK_DIR/devicecheck_guest_sources.txt
BOUNDARY=$REFERENCE/devicecheck-public-boundary.tsv
PROVENANCE=$REFERENCE/apple-sdk-inputs.sha256
SYMBOLS=$REFERENCE/DeviceCheck.symbols.json
CORPUS=$REFERENCE/devicecheck-corpus-2026-09-01.tsv
SURFACE=$HERE/DeviceCheckSourceSurface.swift
RUNTIME=$HERE/DeviceCheckGuestRuntime.swift

fail() {
    printf 'devicecheck-host-test: %s\n' "$*" >&2
    exit 1
}

if command -v swiftc >/dev/null 2>&1; then
    SWIFTC=$(command -v swiftc)
elif [ -x /opt/swift/usr/bin/swiftc ]; then
    SWIFTC=/opt/swift/usr/bin/swiftc
elif [ -x /opt/swift-6.2.1/usr/bin/swiftc ]; then
    SWIFTC=/opt/swift-6.2.1/usr/bin/swiftc
else
    fail 'swiftc is not on PATH'
fi

OUTPUT=$(mktemp -d "${TMPDIR:-/tmp}/devicecheck-host.XXXXXX")
cleanup() {
    case "$OUTPUT" in
        /tmp/devicecheck-host.*|/private/tmp/devicecheck-host.*)
            rm -rf -- "$OUTPUT" ;;
        *)
            if [ -n "${TMPDIR:-}" ]; then
                case "$OUTPUT" in
                    "$TMPDIR"/devicecheck-host.*) rm -rf -- "$OUTPUT" ;;
                esac
            fi
            ;;
    esac
}
trap cleanup EXIT

[ -f "$SOURCE" ] && [ ! -L "$SOURCE" ] || fail 'DeviceCheck.swift is missing'
[ -f "$MANIFEST" ] && [ ! -L "$MANIFEST" ] || fail 'guest sources manifest is missing'
[ -f "$BOUNDARY" ] && [ ! -L "$BOUNDARY" ] || fail 'public boundary ledger is missing'
[ -f "$PROVENANCE" ] && [ ! -L "$PROVENANCE" ] || fail 'SDK provenance ledger is missing'
[ -f "$SYMBOLS" ] && [ ! -L "$SYMBOLS" ] || fail 'symbol graph is missing'
[ -f "$CORPUS" ] && [ ! -L "$CORPUS" ] || fail 'corpus ledger is missing'
[ -f "$SURFACE" ] && [ ! -L "$SURFACE" ] || fail 'source-surface program is missing'
[ -f "$RUNTIME" ] && [ ! -L "$RUNTIME" ] || fail 'guest runtime program is missing'

grep -Fxq 'full/devicecheck/DeviceCheck.swift' "$MANIFEST" \
    || fail 'guest sources manifest does not list DeviceCheck.swift'
manifest_count=$(grep -cve '^[[:space:]]*$' "$MANIFEST" || true)
[ "$manifest_count" -eq 1 ] \
    || fail "guest sources manifest should list exactly one file, got $manifest_count"

expected_symbols_hash=1dfdf2eca72c60f92fa3ff4319a9a5df27d0fab38b7fb34170471553afd34edc
actual_symbols_hash=$(sha256sum "$SYMBOLS" | awk '{ print $1 }')
[ "$actual_symbols_hash" = "$expected_symbols_hash" ] \
    || fail "DeviceCheck.symbols.json hash drifted: $actual_symbols_hash"
grep -Fq "$expected_symbols_hash  derived/DeviceCheck.symbols.json" "$PROVENANCE" \
    || fail 'provenance ledger does not pin the committed symbol graph'
provenance_rows=$(grep -cE '^[0-9a-f]{64}  ' "$PROVENANCE" || true)
[ "$provenance_rows" -eq 7 ] \
    || fail "provenance ledger should pin 7 SDK inputs, got $provenance_rows"

private_names='DCAppAttestDeviceService|DCAppAttestServicePriv|DCAppAttestWebAuthService'
if grep -E "$private_names" "$SOURCE" >/dev/null; then
    fail 'DeviceCheck.swift exports a private TBD class'
fi
grep -Fq 'class DCDevice' "$SOURCE" || fail 'DCDevice is missing'
grep -Fq 'class DCAppAttestService' "$SOURCE" || fail 'DCAppAttestService is missing'
grep -Fq 'let DCErrorDomain' "$SOURCE" || fail 'DCErrorDomain is missing'
grep -Fq 'struct DCError' "$SOURCE" || fail 'DCError is missing'
grep -Fq 'isSupported' "$SOURCE" || fail 'isSupported is missing'
grep -Fq 'generateToken' "$SOURCE" || fail 'generateToken is missing'
grep -Fq 'generateKey' "$SOURCE" || fail 'generateKey is missing'
grep -Fq 'attestKey' "$SOURCE" || fail 'attestKey is missing'
grep -Fq 'generateAssertion' "$SOURCE" || fail 'generateAssertion is missing'
grep -Fq 'featureUnsupported' "$SOURCE" || fail 'featureUnsupported is missing'

python3 - "$BOUNDARY" "$CORPUS" "$SYMBOLS" "$SOURCE" <<'PY'
import json
import sys
from pathlib import Path

boundary, corpus, symbols_path, source_path = map(Path, sys.argv[1:])
source = source_path.read_text()
private = []
public_classes = []
public_data = []
with boundary.open() as handle:
    header = handle.readline()
    if not header.startswith("kind\tname\tpolicy\tevidence"):
        raise SystemExit("boundary ledger header drifted")
    for line in handle:
        line = line.rstrip("\n")
        if not line:
            continue
        kind, name, policy, _evidence = line.split("\t", 3)
        if policy == "private-exclusion":
            private.append(name)
            if name in source:
                raise SystemExit(f"private TBD name leaked into source: {name}")
        elif kind == "objc-class" and policy == "public":
            public_classes.append(name)
        elif kind == "data-symbol" and policy == "public":
            public_data.append(name)

if private != [
    "DCAppAttestDeviceService",
    "DCAppAttestServicePriv",
    "DCAppAttestWebAuthService",
]:
    raise SystemExit("private TBD exclusions drifted")
for name in public_classes:
    if f"class {name}" not in source:
        raise SystemExit(f"public class missing from source: {name}")
if public_data != ["_DCErrorDomain"]:
    raise SystemExit("public data symbols drifted")
if "let DCErrorDomain" not in source:
    raise SystemExit("DCErrorDomain is missing from source")

required = []
with corpus.open() as handle:
    header = handle.readline()
    if not header.startswith("repository\tcommit\tpath\tsha256\trequired-surface"):
        raise SystemExit("corpus ledger header drifted")
    for line in handle:
        line = line.rstrip("\n")
        if not line:
            continue
        _repo, _commit, _path, _digest, surface = line.split("\t", 4)
        for token in surface.split(","):
            token = token.strip()
            if token and token != "import DeviceCheck":
                required.append(token)

missing = []
for token in required:
    needle = token.split(".")[-1]
    if needle not in source:
        missing.append(token)
if missing:
    raise SystemExit("corpus required-surface missing: " + ", ".join(missing))

graph = json.loads(symbols_path.read_text())
needed = []
for symbol in graph["symbols"]:
    ident = symbol.get("identifier", {}).get("precise", "")
    if "SYNTHESIZED" in ident:
        continue
    title = symbol.get("names", {}).get("title")
    if not title:
        continue
    if title in {
        "!=(_:_:)",
        "==(_:_:)",
        "~=(_:_:)",
        "hash(into:)",
        "hashValue",
        "localizedDescription",
        "errorCode",
        "errorUserInfo",
        "init(rawValue:)",
    }:
        continue
    needed.append(title)

checks = {
    "DCError": "struct DCError",
    "DCError.Code": "enum Code",
    "DCError.Code.unknownSystemFailure": "case unknownSystemFailure",
    "DCError.Code.featureUnsupported": "case featureUnsupported",
    "DCError.Code.invalidInput": "case invalidInput",
    "DCError.Code.invalidKey": "case invalidKey",
    "DCError.Code.serverUnavailable": "case serverUnavailable",
    "errorDomain": "static var errorDomain",
    "init(_:userInfo:)": "init(_ code: Code, userInfo:",
    "code": "let code: Code",
    "unknownSystemFailure": "unknownSystemFailure",
    "featureUnsupported": "featureUnsupported",
    "invalidInput": "invalidInput",
    "invalidKey": "invalidKey",
    "serverUnavailable": "serverUnavailable",
    "DCDevice": "class DCDevice",
    "current": "class var current",
    "isSupported": "var isSupported",
    "generateToken(completionHandler:)": "func generateToken(\n        completionHandler",
    "generateToken()": "func generateToken() async throws -> Data",
    "DCAppAttestService": "class DCAppAttestService",
    "shared": "class var shared",
    "generateKey(completionHandler:)": "func generateKey(\n        completionHandler",
    "generateKey()": "func generateKey() async throws -> String",
    "attestKey(_:clientDataHash:completionHandler:)": "func attestKey(\n        _ keyId: String,\n        clientDataHash: Data,\n        completionHandler",
    "attestKey(_:clientDataHash:)": "func attestKey(\n        _ keyId: String,\n        clientDataHash: Data\n    ) async throws -> Data",
    "generateAssertion(_:clientDataHash:completionHandler:)": "func generateAssertion(\n        _ keyId: String,\n        clientDataHash: Data,\n        completionHandler",
    "generateAssertion(_:clientDataHash:)": "func generateAssertion(\n        _ keyId: String,\n        clientDataHash: Data\n    ) async throws -> Data",
    "DCErrorDomain": "let DCErrorDomain",
}
for title in needed:
    snippet = checks.get(title)
    if snippet is None:
        raise SystemExit(f"unmapped public symbol-graph title: {title}")
    if snippet not in source:
        raise SystemExit(f"symbol-graph surface missing from source: {title}")
print("DEVICECHECK_CONTRACT_OK")
PY

"$SWIFTC" -parse-as-library -typecheck -module-name DeviceCheck "$SOURCE"

uname_s=$(uname -s)
if [ "$uname_s" = Darwin ]; then
    libname=libDeviceCheck.dylib
else
    libname=libDeviceCheck.so
fi

"$SWIFTC" -parse-as-library -emit-module -emit-library \
    -module-name DeviceCheck \
    -emit-module-path "$OUTPUT/DeviceCheck.swiftmodule" \
    "$SOURCE" \
    -o "$OUTPUT/$libname"

"$SWIFTC" -parse-as-library -typecheck -I "$OUTPUT" "$SURFACE"

"$SWIFTC" -parse-as-library -I "$OUTPUT" -L "$OUTPUT" -lDeviceCheck \
    -Xlinker -rpath -Xlinker "$OUTPUT" \
    "$RUNTIME" \
    -o "$OUTPUT/DeviceCheckGuestRuntime"

if [ "$uname_s" = Darwin ]; then
    DYLD_LIBRARY_PATH="$OUTPUT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
        "$OUTPUT/DeviceCheckGuestRuntime" | tee "$OUTPUT/runtime.log"
else
    LD_LIBRARY_PATH="$OUTPUT${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        "$OUTPUT/DeviceCheckGuestRuntime" | tee "$OUTPUT/runtime.log"
fi

grep -Fxq \
    'DEVICECHECK_GUEST_OK singleton=2 callbacks=4 async=4 fail-closed=1' \
    "$OUTPUT/runtime.log" \
    || fail 'guest runtime marker is missing'

if command -v nm >/dev/null 2>&1; then
    if nm -g "$OUTPUT/$libname" 2>/dev/null | grep -E "$private_names" >/dev/null; then
        fail 'shared library exports a private TBD class'
    fi
fi

if [ -n "${DEVICECHECK_CORPUS_ROOT:-}" ]; then
    while IFS=$'\t' read -r repository commit relative expected_hash required_surface; do
        [ -n "$repository" ] || continue
        [ "$repository" != repository ] || continue
        source_file=$DEVICECHECK_CORPUS_ROOT/$repository/$relative
        [ -f "$source_file" ] || fail "corpus source missing: $repository/$relative"
        [ "$(sha256sum "$source_file" | awk '{ print $1 }')" = "$expected_hash" ] \
            || fail "corpus source hash drifted: $repository/$relative"
        [ -z "$(git -C "$DEVICECHECK_CORPUS_ROOT/$repository" status --porcelain --untracked-files=all)" ] \
            || fail "corpus checkout is not untouched: $repository"
        [ "$(git -C "$DEVICECHECK_CORPUS_ROOT/$repository" rev-parse HEAD)" = "$commit" ] \
            || fail "corpus commit drifted: $repository"
        _=$required_surface
        "$SWIFTC" -parse-as-library -typecheck -I "$OUTPUT" "$source_file" \
            || fail "corpus typecheck failed: $repository/$relative"
    done < "$CORPUS"
fi

printf 'DEVICECHECK_HOST_GATE_OK module=DeviceCheck surface=typecheck runtime=fail-closed boundary=public-only provenance=pinned corpus=required-surface\n'
