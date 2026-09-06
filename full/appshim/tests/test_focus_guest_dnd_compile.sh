#!/bin/bash
# Run inside the guest compiler image after uikit/scripts/guest_route_check.sh.
# Mount support at /w (read-only), repo at /src (read-only), uikit at /uikit
# (read-only), and both arguments at their host paths (OUT writable).
# The fixture exports existing guest identities and uses the real coder,
# extension-host and Progress sources; no replacement NSItemProvider/Progress.
set -euo pipefail
BASE=${1:?Foundation-hidden guest_route_check output}
OUT=${2:?output directory}
mkdir -p "$OUT"
SYS=/w/scratch/sysroot_fe4
FLAGS=(
    -target arm64-apple-macos15.0 -sdk "$SYS"
    -module-cache-path "$OUT/cache" -runtime-compatibility-version none -wmo
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module
    -I "$BASE" -I /w/scratch/fe4_out -I /w/scratch/fe4_collections
    -I /w/scratch/fe4_os
    -Xcc -fmodule-map-file=/w/scratch/swift-foundation/Sources/_FoundationCShims/include/module.modulemap
    -Xcc -I/w/scratch/swift-foundation/Sources/_FoundationCShims/include
    -Xcc -fmodule-map-file=/uikit/Sources/CQuartz/include/module.modulemap
    -Xcc -I/uikit/Sources/CQuartz/include
    -Xcc -fmodule-map-file="$BASE/inc/CPortableIO/module.modulemap"
    -Xcc -fmodule-map-file="$BASE/inc/CSTBTrueType/module.modulemap"
)
swiftc "${FLAGS[@]}" -module-name Foundation -emit-module \
    -emit-module-path "$OUT/Foundation.swiftmodule" \
    /src/full/foundation/tests/FoundationExtensionGuestFixture.swift \
    /src/full/foundation/NSCoder+KeyedCompatibility.swift \
    /src/full/foundation/NSExtensionHost.swift /src/full/foundation/Progress.swift
swiftc "${FLAGS[@]}" -I "$OUT" -parse-as-library -emit-object \
    -o "$OUT/dnd.o" /src/full/appshim/tests/FocusGuestDragDrop.swift

echo FOCUS_GUEST_DND_COMPILE_OK provider=subclass-bridge session=existential progress=Foundation coding=retained
