#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
APP=${1:-/private/tmp/app-wave-20260831/IceCubesApp}
EXPECTED_APP_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_APP_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
BUILD=$(mktemp -d /private/tmp/avfoundation-host-gate-20260831.XXXXXX)
trap 'rm -rf "$BUILD"' EXIT

declare -a SOURCES=(
  'IceCubesApp/App/Main/AppView.swift:a4cfdb67eec5c832f8b72f7f9233601f2ff1b0472a6b16cb428a3bcf85eb1ac1'
  'IceCubesApp/App/Main/IceCubesApp.swift:4ea92d4063af550dc98ae9474d9f78b6327d7a797972eaa2d208d00b704fda8b'
  'Packages/Env/Sources/Env/SoundEffectManager.swift:952cff2564433aca87f1fecb13dfb573896905709d54adee06c2d7523e2e3f2d'
  'Packages/MediaUI/Sources/MediaUI/MediaUIAttachmentVideoView.swift:317cd7775c1935047e15dd75c32ce7e0617f2247d9a45ed7cc252b092537fca3'
  'Packages/MediaUI/Sources/MediaUI/MediaUIView.swift:f7931526360e8f5d39820b4660fcfcf29c9a6b23a4fa1aeda20acce24062d1a1'
  'Packages/StatusKit/Sources/StatusKit/Editor/Components/Compressor.swift:adb309da1d5814916e039f9f2d337506de46e7847b2413f3908d342b2e26dc5a'
  'Packages/StatusKit/Sources/StatusKit/Editor/Components/MediaView.swift:b9bcb3b9e109cdff143dbc14ca38f5863129cd7a2c0a8fcf044111cf03099a65'
  'Packages/StatusKit/Sources/StatusKit/Editor/Components/UTTypeSupported.swift:1eab6d68d63f4bc95a5cd0b185d857f4eca35a4175d12dd0dfed8452fa74f799'
  'Packages/StatusKit/Sources/StatusKit/Editor/EditorStore.swift:ddbebf90c661b1a2e143f7585e578deb2633ab7bdfe28fa74bd8866875151232'
)

[ -d "$APP/.git" ] || { echo "missing app checkout: $APP" >&2; exit 2; }
[ -z "$(git -C "$APP" status --short)" ] || {
  echo 'app checkout is not untouched' >&2
  exit 2
}
[ "$(git -C "$APP" rev-parse HEAD^{commit})" = "$EXPECTED_APP_COMMIT" ]
[ "$(git -C "$APP" rev-parse HEAD^{tree})" = "$EXPECTED_APP_TREE" ]
for entry in "${SOURCES[@]}"; do
  path=${entry%%:*}
  expected=${entry##*:}
  [ "$(shasum -a 256 "$APP/$path" | awk '{print $1}')" = "$expected" ]
done

grep -Fxq 'import AVKit' "$APP/Packages/Env/Sources/Env/SoundEffectManager.swift"
grep -Fq 'player?.seek(to: CMTime.zero)' \
  "$APP/Packages/MediaUI/Sources/MediaUI/MediaUIAttachmentVideoView.swift"
grep -Fq 'AVAssetExportPreset1920x1080' \
  "$APP/Packages/StatusKit/Sources/StatusKit/Editor/Components/Compressor.swift"
grep -Fq 'let generator = AVAssetImageGenerator(asset: asset)' \
  "$APP/Packages/StatusKit/Sources/StatusKit/Editor/EditorStore.swift"

mkdir -p "$BUILD/host/modules" "$BUILD/host/lib" "$BUILD/ios/modules"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -emit-module -emit-library -module-name CoreMedia \
  "$ROOT/full/coremedia/CoreMedia.swift" \
  -emit-module-path "$BUILD/host/modules/CoreMedia.swiftmodule" \
  -o "$BUILD/host/lib/libCoreMedia.dylib"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -emit-module -emit-library -module-name AVFoundation \
  -I "$BUILD/host/modules" -L "$BUILD/host/lib" -lCoreMedia \
  "$ROOT/full/avfoundation/AVFoundation.swift" \
  -emit-module-path "$BUILD/host/modules/AVFoundation.swiftmodule" \
  -o "$BUILD/host/lib/libAVFoundation.dylib"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -I "$BUILD/host/modules" -L "$BUILD/host/lib" \
  -lAVFoundation -lCoreMedia \
  "$ROOT/full/avfoundation/tests/AVFoundationHostRuntime.swift" \
  -o "$BUILD/AVFoundationHostRuntime"
DYLD_LIBRARY_PATH="$BUILD/host/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
  "$BUILD/AVFoundationHostRuntime" | tee "$BUILD/runtime.log"
grep -Fxq \
  'AVFOUNDATION_HOST_OK time=rational player=host-driven audio=state export=fail-closed,host-driven frame=fail-closed,host-driven' \
  "$BUILD/runtime.log"

xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library "$ROOT/full/coremedia/tests/CoreMediaTranscript.swift" \
  -o "$BUILD/CoreMediaNativeTranscript"
"$BUILD/CoreMediaNativeTranscript" > "$BUILD/coremedia-native.txt"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -I "$BUILD/host/modules" -L "$BUILD/host/lib" \
  -lCoreMedia "$ROOT/full/coremedia/tests/CoreMediaTranscript.swift" \
  -o "$BUILD/CoreMediaPortableTranscript"
DYLD_LIBRARY_PATH="$BUILD/host/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
  "$BUILD/CoreMediaPortableTranscript" > "$BUILD/coremedia-portable.txt"
cmp "$BUILD/coremedia-native.txt" "$BUILD/coremedia-portable.txt"

SDK=$(xcrun --sdk iphoneos --show-sdk-path)
TARGET=arm64-apple-ios18.0
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -target "$TARGET" -sdk "$SDK" -emit-module \
  -module-name CoreMedia "$ROOT/full/coremedia/CoreMedia.swift" \
  -emit-module-path "$BUILD/ios/modules/CoreMedia.swiftmodule"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -target "$TARGET" -sdk "$SDK" -emit-module \
  -module-name AVFoundation -I "$BUILD/ios/modules" \
  "$ROOT/full/avfoundation/AVFoundation.swift" \
  -emit-module-path "$BUILD/ios/modules/AVFoundation.swiftmodule"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -parse-as-library -target "$TARGET" -sdk "$SDK" -emit-module \
  -module-name AVKit -I "$BUILD/ios/modules" \
  "$ROOT/full/avkit/AVKit.swift" \
  -emit-module-path "$BUILD/ios/modules/AVKit.swiftmodule"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -typecheck -parse-as-library -target "$TARGET" -sdk "$SDK" \
  -I "$BUILD/ios/modules" \
  "$ROOT/full/avfoundation/tests/IceCubesAVConsumer.swift"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
  -typecheck -parse-as-library -target "$TARGET" -sdk "$SDK" \
  "$ROOT/full/avfoundation/tests/AVFoundationNativeOracle.swift"

if otool -L "$BUILD/host/lib/libAVFoundation.dylib" \
    | grep -Fq '/AVFoundation.framework/'; then
  echo 'portable libAVFoundation unexpectedly loads Apple AVFoundation' >&2
  exit 1
fi

echo 'AVFOUNDATION_HOST_GATE_OK modules=CoreMedia,AVFoundation,AVKit semantics=rational,state,host-driven,fail-closed'
printf 'AVFOUNDATION_EXACT_CONSUMER_OK app=%s:%s sources=%s\n' \
  "$EXPECTED_APP_COMMIT" "$EXPECTED_APP_TREE" "${#SOURCES[@]}"
