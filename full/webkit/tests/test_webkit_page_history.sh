#!/usr/bin/env bash
# Same asynchronous history assertions on pinned iOS 26.1 and the Linux model.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
OUT=$(mktemp -d /tmp/webkit-page-history.XXXXXX)
trap 'rm -rf "$OUT"' EXIT
if [ "${1:-host}" = native ]; then
    [ "$(xcodebuild -version | paste -sd '|')" = 'Xcode 26.1|Build version 17B55' ] || exit 2
    [ "$(xcrun --sdk iphonesimulator --show-sdk-platform-version)" = 26.1 ] || exit 2
    [ "$(xcrun --sdk iphonesimulator --show-sdk-build-version)" = 23B77 ] || exit 2
    : "${WEBKIT_ORACLE_DEVICE:?Set your private booted simulator UUID}"
    : "${SIM_DEVICE_SUFFIX:?Set your private simulator suffix}"
    xcrun simctl list devices --json | python3 -c '
import json, os, sys
matches = [d for ds in json.load(sys.stdin)["devices"].values() for d in ds
           if d["udid"] == os.environ["WEBKIT_ORACLE_DEVICE"]]
assert len(matches) == 1 and matches[0]["state"] == "Booted"
assert matches[0]["name"].endswith(os.environ["SIM_DEVICE_SUFFIX"])
'
    xcrun swiftc -warnings-as-errors -parse-as-library \
        -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
        -target arm64-apple-ios26.1-simulator \
        "$HERE/WebKitPageHistoryOracle.swift" -o "$OUT/HistoryOracle"
    xcrun simctl spawn "$WEBKIT_ORACLE_DEVICE" "$OUT/HistoryOracle"
else
    SOURCES=()
    while IFS= read -r source; do SOURCES+=("$ROOT/$source"); done < "$HERE/../webkit_guest_sources.txt"
    swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
        -module-name WebKit -emit-module-path "$OUT/WebKit.swiftmodule" \
        "${SOURCES[@]}" -o "$OUT/libWebKit.so"
    swiftc -warnings-as-errors -parse-as-library -I "$OUT" \
        "$HERE/WebKitPageHistoryOracle.swift" "$OUT/libWebKit.so" -o "$OUT/HistoryOracle"
    LD_LIBRARY_PATH="$OUT" timeout --signal=TERM --kill-after=5s 60s "$OUT/HistoryOracle"
fi
