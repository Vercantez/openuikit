#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
APP=${1:-/private/tmp/app-wave-20260831/IceCubesApp}
EXPECTED_APP_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_APP_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
MEDIA_CONSUMER=Packages/MediaUI/Sources/MediaUI/MediaUIView.swift
EXPECTED_MEDIA_SHA256=f7931526360e8f5d39820b4660fcfcf29c9a6b23a4fa1aeda20acce24062d1a1
STATUS_CONSUMER=Packages/StatusKit/Sources/StatusKit/Editor/Components/MediaPickerPanelView.swift
EXPECTED_STATUS_SHA256=1f06735860db9675ff2eca3106fdebe896a298d472ec31e4c6df1567114bc9d0
BUILD=$(mktemp -d /private/tmp/photos-host-gate-20260831.XXXXXX)
trap 'rm -rf "$BUILD"' EXIT

[ -d "$APP/.git" ]
[ -z "$(git -C "$APP" status --short)" ]
[ "$(git -C "$APP" rev-parse HEAD^{commit})" = "$EXPECTED_APP_COMMIT" ]
[ "$(git -C "$APP" rev-parse HEAD^{tree})" = "$EXPECTED_APP_TREE" ]
[ "$(shasum -a 256 "$APP/$MEDIA_CONSUMER" | awk '{print $1}')" = \
  "$EXPECTED_MEDIA_SHA256" ]
[ "$(shasum -a 256 "$APP/$STATUS_CONSUMER" | awk '{print $1}')" = \
  "$EXPECTED_STATUS_SHA256" ]
grep -Fq 'PHPhotoLibrary.authorizationStatus(for: .addOnly)' \
  "$APP/$MEDIA_CONSUMER"
grep -Fq 'PHAsset.fetchAssets(with: .image, options: options)' \
  "$APP/$STATUS_CONSUMER"
grep -Fq 'requestImageDataAndOrientation(' "$APP/$STATUS_CONSUMER"
grep -Fq 'requestImage(' "$APP/$STATUS_CONSUMER"

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -typecheck -parse-as-library -target arm64-apple-ios18.0 -sdk "$SDK" \
  "$ROOT/full/photos/tests/PhotosNativeOracle.swift"

xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -emit-module -emit-library -module-name Photos \
  -emit-module-path "$BUILD/Photos.swiftmodule" \
  -Xlinker -install_name -Xlinker @rpath/libPhotos.dylib \
  "$ROOT/full/photos/Photos.swift" -o "$BUILD/libPhotos.dylib"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -I "$BUILD" -L "$BUILD" -lPhotos \
  "$ROOT/full/photos/tests/PhotosHostRuntime.swift" \
  -o "$BUILD/PhotosHostRuntime"
DYLD_LIBRARY_PATH="$BUILD${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
  "$BUILD/PhotosHostRuntime" | tee "$BUILD/runtime.log"
grep -Fxq \
  'PHOTOS_HOST_OK authorization=fail-closed,host-driven assets=volatile fetch=filtered,sorted,limited image=data,thumbnail' \
  "$BUILD/runtime.log"

[ "$(xcrun otool -D "$BUILD/libPhotos.dylib" \
  | grep -Fxc '@rpath/libPhotos.dylib')" -eq 1 ]
! xcrun otool -L "$BUILD/libPhotos.dylib" \
  | grep -F '/System/Library/Frameworks/Photos.framework/' >/dev/null

printf 'PHOTOS_HOST_GATE_OK module=Photos semantics=authorization,volatile-assets,images,fail-closed\n'
printf 'PHOTOS_EXACT_CONSUMERS_OK app=%s:%s sources=%s:%s,%s:%s\n' \
  "$EXPECTED_APP_COMMIT" "$EXPECTED_APP_TREE" \
  "$MEDIA_CONSUMER" "$EXPECTED_MEDIA_SHA256" \
  "$STATUS_CONSUMER" "$EXPECTED_STATUS_SHA256"
