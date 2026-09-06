#!/usr/bin/env bash
# Run the very same synchronous value tests against the pinned Apple module.
# Caller supplies a private, already-booted simulator; this script owns none.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo 'WEBKIT_PAGE_VALUE_NATIVE_UNAVAILABLE: requires Xcode 26.1' >&2
    exit 2
fi
[ "$(xcodebuild -version | paste -sd '|')" = 'Xcode 26.1|Build version 17B55' ] || exit 2
[ "$(xcrun --sdk iphonesimulator --show-sdk-platform-version)" = '26.1' ] || exit 2
[ "$(xcrun --sdk iphonesimulator --show-sdk-build-version)" = '23B77' ] || exit 2
: "${WEBKIT_ORACLE_DEVICE:?Set WEBKIT_ORACLE_DEVICE to your private booted simulator UUID}"
: "${SIM_DEVICE_SUFFIX:?Set SIM_DEVICE_SUFFIX to your private simulator suffix}"
xcrun simctl list devices --json | python3 -c '
import json, os, sys
matches = [d for ds in json.load(sys.stdin)["devices"].values() for d in ds
           if d["udid"] == os.environ["WEBKIT_ORACLE_DEVICE"]]
assert len(matches) == 1 and matches[0]["state"] == "Booted"
assert matches[0]["name"].endswith(os.environ["SIM_DEVICE_SUFFIX"])
'
OUT=$(mktemp -d /tmp/webkit-page-values.XXXXXX)
trap 'rm -rf "$OUT"' EXIT
python3 - "$HERE/agent/WebKitPageValueTests.swift" "$OUT/main.swift" <<'PY'
from pathlib import Path
import re, sys
names = re.findall(r'^func (test\w+)\(\)', Path(sys.argv[1]).read_text(), re.M)
assert names
Path(sys.argv[2]).write_text(
    'import WebKit\n@main struct ValueOracle { @MainActor static func main() {\n'
    + ''.join(f'{name}()\n' for name in names)
    + f'print("WEBKIT_PAGE_VALUE_NATIVE_OK tests={len(names)}")\n'
    + '} }\n')
PY
xcrun swiftc -warnings-as-errors -parse-as-library \
    -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
    -target arm64-apple-ios26.1-simulator \
    "$HERE/agent/WebKitPageValueTests.swift" "$OUT/main.swift" -o "$OUT/ValueOracle"
xcrun simctl spawn "$WEBKIT_ORACLE_DEVICE" "$OUT/ValueOracle"
