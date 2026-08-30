#!/bin/bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
OPENUIKIT_SOURCE=${1:-${OPENUIKIT_SOURCE:-}}
[ -n "$OPENUIKIT_SOURCE" ] || {
    printf 'usage: %s /path/to/pinned/OpenUIKit\n' "$0" >&2
    exit 2
}
[ -f "$OPENUIKIT_SOURCE/Package.swift" ] || {
    printf 'not an OpenUIKit package: %s\n' "$OPENUIKIT_SOURCE" >&2
    exit 2
}

OUT=$(mktemp -d /tmp/first-party-frameworks-host.XXXXXX)
cleanup() {
    case "$OUT" in
        /tmp/first-party-frameworks-host.*|/private/tmp/first-party-frameworks-host.*)
            rm -rf -- "$OUT" ;;
        *) printf 'refusing unsafe cleanup path: %s\n' "$OUT" >&2 ;;
    esac
}
trap cleanup EXIT

cp "$HERE/HostPackage.swift" "$OUT/Package.swift"
for framework in LocalAuthentication SafariServices Network StoreKit \
    AudioToolbox CoreHaptics PassKit; do
    case "$framework" in
        LocalAuthentication) directory=localauthentication ;;
        SafariServices) directory=safariservices ;;
        Network) directory=network ;;
        StoreKit) directory=storekit ;;
        AudioToolbox) directory=audiotoolbox ;;
        CoreHaptics) directory=corehaptics ;;
        PassKit) directory=passkit ;;
        *) printf 'unknown framework: %s\n' "$framework" >&2; exit 2 ;;
    esac
    manifest="$ROOT/full/$directory/${directory}_guest_sources.txt"
    mkdir -p "$OUT/Sources/$framework"
    while IFS= read -r relative; do
        [ -n "$relative" ] || continue
        cp "$ROOT/$relative" "$OUT/Sources/$framework/$(basename "$relative")"
    done < "$manifest"
done

if ! OPENUIKIT_SOURCE="$OPENUIKIT_SOURCE" \
    swift build --package-path "$OUT" -c release \
    > "$OUT/swift-build.log" 2>&1; then
    sed -n '1,260p' "$OUT/swift-build.log" >&2
    exit 3
fi
BIN=$(OPENUIKIT_SOURCE="$OPENUIKIT_SOURCE" \
    swift build --package-path "$OUT" -c release --show-bin-path)

for framework in LocalAuthentication SafariServices Network StoreKit \
    AudioToolbox CoreHaptics PassKit; do
    dylib="$BIN/lib$framework.dylib"
    [ -f "$dylib" ] || {
        printf 'missing dynamic framework product: %s\n' "$dylib" >&2
        exit 3
    }
    [ "$(xcrun otool -D "$dylib" | grep -Fc "@rpath/lib$framework.dylib")" -eq 1 ]
    if xcrun otool -L "$dylib" \
        | grep -F "/System/Library/Frameworks/$framework.framework/" >/dev/null; then
        printf 'portable %s dylib loads Apple framework\n' "$framework" >&2
        exit 3
    fi
done

xcrun swiftc -parse-as-library "$HERE/FirstPartyHostRuntime.swift" \
    -I "$BIN/Modules" -L "$BIN" \
    -lLocalAuthentication -lSafariServices -lNetwork -lStoreKit \
    -lAudioToolbox -lCoreHaptics -lPassKit \
    -Xcc -fmodule-map-file="$BIN/CPortableIO.build/module.modulemap" \
    -Xcc -I -Xcc "$OPENUIKIT_SOURCE/Sources/CPortableIO/include" \
    -Xcc -fmodule-map-file="$BIN/CSTBTrueType.build/module.modulemap" \
    -Xcc -I -Xcc "$OPENUIKIT_SOURCE/Sources/CSTBTrueType/include" \
    -Xcc -fmodule-map-file="$OPENUIKIT_SOURCE/Sources/CQuartz/include/module.modulemap" \
    -Xcc -I -Xcc "$OPENUIKIT_SOURCE/Sources/CQuartz/include" \
    -o "$OUT/FirstPartyHostRuntime"
DYLD_LIBRARY_PATH="$BIN${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$OUT/FirstPartyHostRuntime" | tee "$OUT/runtime.log"
grep -Fx \
    'FIRST_PARTY_FRAMEWORKS_HOST_OK auth=unavailable safari=failed network=unsatisfied store=unavailable audio=recorded-unsupported haptics=unsupported passkit=unavailable' \
    "$OUT/runtime.log" >/dev/null

printf 'FIRST_PARTY_FRAMEWORKS_HOST_DYLIBS_OK count=7 apple-loads=absent\n'
