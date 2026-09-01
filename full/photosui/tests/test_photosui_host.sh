#!/usr/bin/env bash
set -euo pipefail

W=$(cd "$(dirname "$0")/../../.." && pwd)
APP=${ICECUBES_APP_ROOT:-/private/tmp/app-wave-20260831/IceCubesApp}
EXPECTED_APP_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_APP_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
PROBE_ROOT=$(mktemp -d /private/tmp/photosui-host.XXXXXX)
trap 'rm -rf "$PROBE_ROOT"' EXIT

fail() {
    printf 'photosui-host-test: %s\n' "$*" >&2
    exit 1
}

[ -d "$APP/.git" ] || fail "missing pinned IceCubes checkout: $APP"
[ "$(git -C "$APP" rev-parse HEAD)" = "$EXPECTED_APP_COMMIT" ] \
    || fail 'IceCubes commit drifted'
[ "$(git -C "$APP" rev-parse 'HEAD^{tree}')" = "$EXPECTED_APP_TREE" ] \
    || fail 'IceCubes tree drifted'
[ -z "$(git -C "$APP" status --porcelain --untracked-files=all)" ] \
    || fail 'IceCubes checkout is dirty'

declare -a EXACT_SOURCES=(
    'Packages/StatusKit/Sources/StatusKit/Editor/Components/AccessoryView.swift:349c7002ae71e1d541eed12173e30cb6527c53f5bc7f836d0e7d74b0115061b4'
    'Packages/StatusKit/Sources/StatusKit/Editor/Components/MediaContainer.swift:4dc278da00ab5982ab28d8fee9db0edc983716ce6934ccc78403309664abf711'
    'Packages/StatusKit/Sources/StatusKit/Editor/Components/UTTypeSupported.swift:1eab6d68d63f4bc95a5cd0b185d857f4eca35a4175d12dd0dfed8452fa74f799'
    'Packages/StatusKit/Sources/StatusKit/Editor/EditorStore.swift:ddbebf90c661b1a2e143f7585e578deb2633ab7bdfe28fa74bd8866875151232'
    'Packages/StatusKit/Sources/StatusKit/Editor/MainView.swift:9e76377c701ed09537aa00614aef7c4e1976c46921f917b4694abe4ac1d9ba63'
    'Packages/StatusKit/Sources/StatusKit/Editor/Components/MediaPickerPanelView.swift:1f06735860db9675ff2eca3106fdebe896a298d472ec31e4c6df1567114bc9d0'
)
for row in "${EXACT_SOURCES[@]}"; do
    relative=${row%%:*}
    expected=${row##*:}
    [ "$(shasum -a 256 "$APP/$relative" | awk '{print $1}')" = "$expected" ] \
        || fail "untouched source drifted: $relative"
done

xcrun swiftc -parse-as-library -emit-library -emit-module \
    -module-name CoreTransferable \
    -emit-module-path "$PROBE_ROOT/CoreTransferable.swiftmodule" \
    -o "$PROBE_ROOT/libCoreTransferable.dylib" \
    "$W/full/coretransferable/CoreTransferable.swift"
xcrun swiftc -parse-as-library -emit-library -emit-module \
    -module-name PhotosUI \
    -emit-module-path "$PROBE_ROOT/PhotosUI.swiftmodule" \
    -o "$PROBE_ROOT/libPhotosUI.dylib" \
    "$W/full/photosui/PhotosUI.swift"
xcrun swiftc -parse-as-library -emit-library -emit-module \
    -I "$PROBE_ROOT" -L "$PROBE_ROOT" \
    -module-name _PhotosUI_SwiftUI \
    -emit-module-path "$PROBE_ROOT/_PhotosUI_SwiftUI.swiftmodule" \
    -o "$PROBE_ROOT/lib_PhotosUI_SwiftUI.dylib" \
    "$W/full/photosui/PhotosUISwiftUI.swift" \
    -lCoreTransferable -lPhotosUI
mkdir -p "$PROBE_ROOT/PhotosUI.swiftcrossimport"
cp "$W/full/photosui/SwiftUI.swiftoverlay" \
    "$PROBE_ROOT/PhotosUI.swiftcrossimport/SwiftUI.swiftoverlay"

xcrun swiftc -parse-as-library -I "$PROBE_ROOT" -L "$PROBE_ROOT" \
    "$W/full/photosui/tests/PhotosUIHostRuntime.swift" \
    -o "$PROBE_ROOT/PhotosUIHostRuntime" \
    -l_PhotosUI_SwiftUI -lPhotosUI -lCoreTransferable
DYLD_LIBRARY_PATH="$PROBE_ROOT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$PROBE_ROOT/PhotosUIHostRuntime" | tee "$PROBE_ROOT/host.log"
grep -Fxq \
    'PHOTOSUI_HOST_OK filter=images,videos transfer=typed,async,completion presentation=fail-closed,host-driven selection=bounded,binding' \
    "$PROBE_ROOT/host.log" || fail 'host semantic marker is missing'

xcrun swiftc -parse-as-library -typecheck \
    -Xfrontend -enable-cross-import-overlays \
    -I "$PROBE_ROOT" \
    "$W/full/photosui/tests/IceCubesPhotosUIConsumer.swift"

xcrun swiftc -parse-as-library \
    "$W/full/photosui/tests/PhotosUINativeOracle.swift" \
    -o "$PROBE_ROOT/PhotosUINativeOracle"
"$PROBE_ROOT/PhotosUINativeOracle" | tee "$PROBE_ROOT/native.log"
grep -Fxq \
    'PHOTOSUI_APPLE_OK filter=images,videos item=identified modifier=multiple-selection' \
    "$PROBE_ROOT/native.log" || fail 'Apple native oracle marker is missing'

printf '%s\n' \
    'PHOTOSUI_HOST_GATE_OK module=PhotosUI,_PhotosUI_SwiftUI semantics=filter,typed-transfer,host-driven,binding,fail-closed'
printf 'PHOTOSUI_EXACT_CONSUMERS_OK app=%s:%s sources=' \
    "$EXPECTED_APP_COMMIT" "$EXPECTED_APP_TREE"
printf '%s' "${EXACT_SOURCES[0]}"
for row in "${EXACT_SOURCES[@]:1}"; do printf ',%s' "$row"; done
printf '\n'
