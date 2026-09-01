#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
APP=${1:-/private/tmp/app-wave-20260831/IceCubesApp}
EXPECTED_APP_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_APP_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
ENV_CONSUMER=Packages/Env/Sources/Env/QuickLook.swift
EXPECTED_ENV_SHA256=dfb388c000bd3ee97a64f9df13bcf3bd82e20ca9db947383887be3e4889c1888
OVERLAY_CONSUMER=Packages/MediaUI/Sources/MediaUI/QuickLookToolbarItem.swift
EXPECTED_OVERLAY_SHA256=e280a8e1f74163c55fab7c8f55573c71810af42f0cc828b32ba81aba38ed067c
BUILD=$(mktemp -d /private/tmp/quicklook-host-gate-20260831.XXXXXX)
trap 'rm -rf "$BUILD"' EXIT

[ -d "$APP/.git" ] || { printf 'missing app checkout: %s\n' "$APP" >&2; exit 2; }
[ -z "$(git -C "$APP" status --short)" ] \
  || { printf 'app checkout is not untouched\n' >&2; exit 2; }
[ "$(git -C "$APP" rev-parse HEAD^{commit})" = "$EXPECTED_APP_COMMIT" ]
[ "$(git -C "$APP" rev-parse HEAD^{tree})" = "$EXPECTED_APP_TREE" ]
[ "$(shasum -a 256 "$APP/$ENV_CONSUMER" | awk '{print $1}')" = \
  "$EXPECTED_ENV_SHA256" ]
[ "$(shasum -a 256 "$APP/$OVERLAY_CONSUMER" | awk '{print $1}')" = \
  "$EXPECTED_OVERLAY_SHA256" ]
grep -Fxq 'import QuickLook' "$APP/$ENV_CONSUMER"
grep -Fq '.quickLookPreview($localPath)' "$APP/$OVERLAY_CONSUMER"

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -parse-as-library -emit-module -emit-library \
  -module-name QuickLook \
  -emit-module-path "$BUILD/QuickLook.swiftmodule" \
  "$ROOT/full/quicklook/QuickLook.swift" \
  -o "$BUILD/libQuickLook.dylib"

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -parse-as-library -emit-module \
  -module-name _QuickLook_SwiftUI -I "$BUILD" \
  -emit-module-path "$BUILD/_QuickLook_SwiftUI.swiftmodule" \
  "$ROOT/full/quicklook/QuickLookSwiftUI.swift"
mkdir -p "$BUILD/QuickLook.swiftcrossimport"
cp "$ROOT/full/quicklook/SwiftUI.swiftoverlay" \
  "$BUILD/QuickLook.swiftcrossimport/SwiftUI.swiftoverlay"

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -parse-as-library -I "$BUILD" -L "$BUILD" -lQuickLook \
  "$ROOT/full/quicklook/tests/QuickLookHostRuntime.swift" \
  -o "$BUILD/QuickLookHostRuntime"
DYLD_LIBRARY_PATH="$BUILD${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
  "$BUILD/QuickLookHostRuntime" | tee "$BUILD/runtime.log"
grep -Fxq \
  'QUICKLOOK_HOST_OK item=metadata presentation=host-driven selection=synchronized unsupported=fail-closed' \
  "$BUILD/runtime.log"

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -typecheck -parse-as-library -I "$BUILD" \
  "$ROOT/full/quicklook/tests/IceCubesQuickLookConsumer.swift"

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -typecheck -parse-as-library -target arm64-apple-ios18.0 \
  -sdk "$SDK" -module-name PortableQuickLook \
  "$ROOT/full/quicklook/QuickLook.swift"
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  -typecheck -parse-as-library -target arm64-apple-ios18.0 \
  -sdk "$SDK" \
  "$ROOT/full/quicklook/tests/QuickLookNativeOracle.swift"

if otool -L "$BUILD/libQuickLook.dylib" | grep -Fq QuickLook.framework; then
  echo 'portable libQuickLook unexpectedly loads Apple QuickLook.framework' >&2
  exit 1
fi

echo 'QUICKLOOK_HOST_GATE_OK module=QuickLook overlay=_QuickLook_SwiftUI semantics=local-image,host-driven,fail-closed'
printf 'QUICKLOOK_EXACT_CONSUMER_OK app=%s:%s sources=%s:%s,%s:%s\n' \
  "$EXPECTED_APP_COMMIT" "$EXPECTED_APP_TREE" \
  "$ENV_CONSUMER" "$EXPECTED_ENV_SHA256" \
  "$OVERLAY_CONSUMER" "$EXPECTED_OVERLAY_SHA256"
