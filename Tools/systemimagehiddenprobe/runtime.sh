#!/bin/zsh
# Fresh Foundation-hidden ARM64 Mach-O build and Linux machorun execution for
# the bounded system-image provider. Exactly one Docker container is used.
set -euo pipefail

candidate_root="$(cd "$(dirname "$0")/../.." && pwd -P)"
support_root="${1:-$candidate_root/../swift-macho-linux}"
machorun_root="${2:-$candidate_root/../machorun}"
support_commit=777e7c083a90452841009f56eec959c098761113
image="${SWIFT_MACHO_IMAGE:-swift-macho-spike:noble}"
container_name=openuikit-system-image-hidden-runtime

[[ "$(git -C "$support_root" rev-parse HEAD)" == "$support_commit" ]]
[[ -z "$(git -C "$support_root" status --porcelain)" ]]
[[ -x "$machorun_root/build/machorun" ]]
[[ -x "$support_root/scratch/mrroot_full/machorun" ]]
[[ -f "$support_root/build/full/foundation/essentials/FoundationEssentials.o" ]]
[[ -f "$support_root/scratch/mrroot_full/darwin/usr/lib/libquartz.dylib" ]]
git -C "$candidate_root" diff --quiet HEAD -- \
    Sources/CQuartz Sources/CPortableIO Sources/CSTBTrueType
MACHORUN="$machorun_root" "$support_root/scripts/require_fresh_root.sh" \
    "$support_root/scratch/mrroot_full"
docker info >/dev/null
[[ -z "$(docker ps -aq --filter name=^/${container_name}$)" ]]

probe_tmp="$(mktemp -d /private/tmp/system-image-hidden-runtime.XXXXXX)"
trap 'rm -rf -- "$probe_tmp"' EXIT

docker run --rm --name "$container_name" \
    -v "$candidate_root:/uikit:ro" \
    -v "$support_root:/w:ro" \
    -v "$machorun_root:/machorun:ro" \
    -v "$probe_tmp:/out" \
    -w /tmp "$image" bash -lc '
set -euo pipefail
TARGET=arm64-apple-macos15.0
MINOS=15.0
SYS=/w/scratch/sysroot_fe4
ROOT=/w/scratch/mrroot_full
SHARED=/w/build/full
OUT=/out
mkdir -p "$OUT/module-cache" "$OUT/uikitinc"

SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS"
  -module-cache-path "$OUT/module-cache"
  -runtime-compatibility-version none -wmo
  -Xfrontend -disable-implicit-string-processing-module-import
  -Xfrontend -disable-objc-attr-requires-foundation-module)
CINC=(-Xcc -fmodule-map-file=/uikit/Sources/CQuartz/include/module.modulemap
  -Xcc -I/uikit/Sources/CQuartz/include
  -Xcc -fmodule-map-file="$SHARED/inc/CPortableIO/module.modulemap"
  -Xcc -I"$SHARED/inc/CPortableIO"
  -Xcc -fmodule-map-file="$SHARED/inc/CSTBTrueType/module.modulemap"
  -Xcc -I"$SHARED/inc/CSTBTrueType")
FEMODULES=(-I "$SHARED/foundation/essentials"
  -I "$SHARED/foundation/collections"
  -I "$SHARED/foundation/os"
  -Xcc -fmodule-map-file=/w/scratch/swift-foundation/Sources/_FoundationCShims/include/module.modulemap
  -Xcc -I/w/scratch/swift-foundation/Sources/_FoundationCShims/include)

mapfile -t OCG_SOURCES < <(find /uikit/Sources/OpenCoreGraphics -type f -name "*.swift" | sort)
mapfile -t OUI_SOURCES < <(find /uikit/Sources/OpenUIKit -type f -name "*.swift" | sort)
[[ ${#OCG_SOURCES[@]} -eq 12 ]]
[[ ${#OUI_SOURCES[@]} -eq 101 ]]

echo "== fresh candidate modules: OpenCoreGraphics=12 OpenUIKit=101"
"${SWIFTC[@]}" "${CINC[@]}" -module-name OpenCoreGraphics \
  -emit-object -emit-module \
  -emit-module-path "$OUT/OpenCoreGraphics.swiftmodule" \
  -o "$OUT/opencoregraphics.o" "${OCG_SOURCES[@]}"
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT" \
  -module-name OpenUIKit -emit-object -emit-module \
  -emit-module-path "$OUT/OpenUIKit.swiftmodule" \
  -o "$OUT/openuikit.o" "${OUI_SOURCES[@]}" \
  /w/full/shims/FoundationNames.swift
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
  -I "$OUT" -module-name UIKit -emit-object -emit-module \
  -emit-module-path "$OUT/uikitinc/UIKit.swiftmodule" \
  -o "$OUT/uikitshim.o" /uikit/Sources/UIKitShim/UIKit.swift

echo "== literal UIKit Foundation-hidden probe object"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
  -I "$OUT" -I "$OUT/uikitinc" -module-name SystemImageHiddenProbe \
  -emit-object -o "$OUT/probe.o" \
  /uikit/Tools/systemimagehiddenprobe/main.swift

echo "== fresh unchanged C dependency objects"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -I/uikit/Sources/CPortableIO/include \
  -c /uikit/Sources/CPortableIO/io.c -o "$OUT/cportableio.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -I/uikit/Sources/CSTBTrueType/include \
  -c /uikit/Sources/CSTBTrueType/stb_impl.c -o "$OUT/cstbtruetype.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -I/w/full/hostclock/include \
  -c /w/full/hostclock/hostclock.c -o "$OUT/hostclock.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -c /w/full/shims/swiftcorepatch.c -o "$OUT/swiftcorepatch.o"

FE_OBJECTS=(
  "$SHARED/foundation/essentials/FoundationEssentials.o"
  "$SHARED/foundation/collections/InternalCollectionsUtilities.o"
  "$SHARED/foundation/collections/OrderedCollections.o"
  "$SHARED/foundation/collections/_RopeModule.o"
  "$SHARED/foundation/os/os.o"
  "$SHARED/foundation/cshims/platform_shims.o"
  "$SHARED/foundation/cshims/string_shims.o"
  "$SHARED/foundation/cshims/uuid.o"
  "$SHARED/foundation/essentials/fm_unimplemented.o"
  "$SHARED/foundation/essentials/uuid_compat.o"
)

echo "== link ARM64 Mach-O guest"
ld64.lld-18 -arch arm64 -platform_version macos "$MINOS" "$MINOS" \
  -syslibroot "$SYS" -dead_strip -exported_symbol __mh_execute_header \
  -rpath /usr/lib/swift -rpath @loader_path \
  -L"$ROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
  "$ROOT/darwin/usr/lib/libswiftcompat.dylib" \
  -L/usr/lib -lSystem -lobjc "$ROOT/darwin/usr/lib/libquartz.dylib" \
  "$ROOT/darwin/usr/lib/libSystem.B.dylib" \
  -o "$OUT/systemimagehiddenprobe" \
  "$OUT/probe.o" "$OUT/uikitshim.o" "$OUT/openuikit.o" \
  "$OUT/opencoregraphics.o" "$OUT/cportableio.o" \
  "$OUT/cstbtruetype.o" "$OUT/hostclock.o" "$OUT/swiftcorepatch.o" \
  "${FE_OBJECTS[@]}"
file "$OUT/systemimagehiddenprobe"
sha256sum "$OUT/systemimagehiddenprobe"

echo "== execute through Linux machorun"
MACHORUN_ROOT="$ROOT" "$ROOT/machorun" "$OUT/systemimagehiddenprobe"
'

print "FOUNDATION_HIDDEN_LINUX_RUNTIME_OK support=$support_commit"
