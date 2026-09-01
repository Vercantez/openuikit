#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
APP=${1:-/private/tmp/app-wave-20260831/IceCubesApp}
EXPECTED_APP_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_APP_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
CONSUMER=Packages/MediaUI/Sources/MediaUI/MediaUITransferableImage.swift
EXPECTED_CONSUMER_SHA256=feed66510fbe853d42e3baa45701ea195415ccd39692fb520e733654cb5c0e97
BUILD=$(mktemp -d /private/tmp/coretransferable-host-gate-20260831.XXXXXX)
trap 'rm -rf "$BUILD"' EXIT

[ -d "$APP/.git" ]
[ -z "$(git -C "$APP" status --short)" ]
[ "$(git -C "$APP" rev-parse HEAD^{commit})" = "$EXPECTED_APP_COMMIT" ]
[ "$(git -C "$APP" rev-parse HEAD^{tree})" = "$EXPECTED_APP_TREE" ]
[ "$(shasum -a 256 "$APP/$CONSUMER" | awk '{print $1}')" = \
  "$EXPECTED_CONSUMER_SHA256" ]
grep -Fxq 'import CoreTransferable' "$APP/$CONSUMER"
grep -Fq 'DataRepresentation(exportedContentType: .jpeg)' "$APP/$CONSUMER"

# Oracle the exact public declaration shape against Apple's installed module.
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -typecheck "$ROOT/full/coretransferable/tests/CoreTransferableNativeOracle.swift"

xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -emit-module -emit-library -module-name CoreTransferable \
  -emit-module-path "$BUILD/CoreTransferable.swiftmodule" \
  -Xlinker -install_name -Xlinker @rpath/libCoreTransferable.dylib \
  "$ROOT/full/coretransferable/CoreTransferable.swift" \
  -o "$BUILD/libCoreTransferable.dylib"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -I "$BUILD" -L "$BUILD" -lCoreTransferable \
  "$ROOT/full/coretransferable/tests/CoreTransferableHostRuntime.swift" \
  -o "$BUILD/CoreTransferableHostRuntime"
DYLD_LIBRARY_PATH="$BUILD${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
  "$BUILD/CoreTransferableHostRuntime" | tee "$BUILD/runtime.log"
grep -Fxq \
  'CORETRANSFERABLE_HOST_OK data=export file=import multi-representation=builder unsupported=fail-closed' \
  "$BUILD/runtime.log"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -typecheck -I "$BUILD" \
  "$ROOT/full/coretransferable/tests/CoreTransferableNativeOracle.swift"

[ "$(xcrun otool -D "$BUILD/libCoreTransferable.dylib" \
  | grep -Fxc '@rpath/libCoreTransferable.dylib')" -eq 1 ]
! xcrun otool -L "$BUILD/libCoreTransferable.dylib" \
  | grep -F '/System/Library/Frameworks/CoreTransferable.framework/' >/dev/null

printf 'CORETRANSFERABLE_HOST_GATE_OK module=CoreTransferable semantics=data,file,builder,fail-closed\n'
printf 'CORETRANSFERABLE_EXACT_CONSUMER_OK app=%s:%s source=%s:%s\n' \
  "$EXPECTED_APP_COMMIT" "$EXPECTED_APP_TREE" "$CONSUMER" \
  "$EXPECTED_CONSUMER_SHA256"
