#!/usr/bin/env bash
# guest_route_check.sh — compile OpenUIKit / UIKit / CQuartz the way the
# Mach-O GUEST library route does: Darwin sysroot, FoundationEssentials
# visible, no Foundation.swiftmodule. Catches the pickers/print/TextKit
# class of regression (x86 cycle c4dce839: NSNumber / URL / Data in scope)
# on the operator Mac in well under 10 minutes.
#
# Usage (from uikit/):  scripts/guest_route_check.sh
# Env: SWIFT_MACHO_LINUX, SWIFT_MACHO_IMAGE, SYS, FE_OUT, COLLECTIONS, OSMOD
set -euo pipefail
cd "$(dirname "$0")/.."
UIKIT=$PWD
ROOT=$(git rev-parse --show-toplevel)
fail() { echo "guest_route_check: $*" >&2; exit 2; }

SUPPORT=${SWIFT_MACHO_LINUX:-}
if [ -z "$SUPPORT" ]; then
  for cand in \
      "$ROOT" \
      "$ROOT/../swift-macho-linux" \
      /Users/miguelsalinas/swift-macho-linux \
      /Users/miguelsalinas/openuikit; do
    [ -d "$cand/scratch/sysroot_fe4/usr/include" ] && { SUPPORT=$(cd "$cand" && pwd -P); break; }
  done
fi
[ -n "${SUPPORT:-}" ] || fail "no guest sysroot (set SWIFT_MACHO_LINUX)"
SYS=${SYS:-$SUPPORT/scratch/sysroot_fe4}
[ -d "$SYS/usr/include" ] || fail "missing sysroot $SYS"

FE_OUT=${FE_OUT:-}
if [ -z "$FE_OUT" ]; then
  if [ -f "$SUPPORT/scratch/fe4_out/FoundationEssentials.swiftmodule" ]; then
    FE_OUT=$SUPPORT/scratch/fe4_out
    COLLECTIONS=${COLLECTIONS:-$SUPPORT/scratch/fe4_collections}
    OSMOD=${OSMOD:-$SUPPORT/scratch/fe4_os}
  elif [ -f "$SUPPORT/build/full/foundation/essentials/FoundationEssentials.swiftmodule" ]; then
    FE_OUT=$SUPPORT/build/full/foundation/essentials
    COLLECTIONS=${COLLECTIONS:-$SUPPORT/build/full/foundation/collections}
    OSMOD=${OSMOD:-$SUPPORT/build/full/foundation/os}
  fi
fi
[ -f "${FE_OUT:-}/FoundationEssentials.swiftmodule" ] || fail "missing FoundationEssentials at FE_OUT=$FE_OUT"
[ -d "${COLLECTIONS:-}" ] || fail "missing collections modules"
[ -d "${OSMOD:-}" ] || fail "missing os module"
[ -f "$ROOT/full/shims/FoundationNames.swift" ] || fail "missing full/shims/FoundationNames.swift"
[ -f "$ROOT/full/foundation/foundationessentials_import_guard.swift" ] \
  || fail "missing foundationessentials_import_guard.swift"
[ -d "$UIKIT/Sources/CQuartz" ] || fail "missing Sources/CQuartz"

IMAGE=${SWIFT_MACHO_IMAGE:-}
if [ -z "$IMAGE" ]; then
  if docker image inspect swift-macho-spike:noble >/dev/null 2>&1; then
    IMAGE=swift-macho-spike:noble
  else
    IMAGE=$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
      | grep '^swift-macho-spike:' | head -1 || true)
  fi
fi
[ -n "$IMAGE" ] || fail "no swift-macho-spike image (set SWIFT_MACHO_IMAGE)"
command -v docker >/dev/null || fail "docker is required"
docker info >/dev/null 2>&1 || fail "docker is not running"

OUT=${GUEST_ROUTE_OUT:-/tmp/guest-route-check-$$}
rm -rf "$OUT"
mkdir -p "$OUT"
START=$(date +%s)
echo "==> guest library route (Foundation hidden)"
echo "    image=$IMAGE"
echo "    support=$SUPPORT"
echo "    uikit=$UIKIT"
echo "    fe=$FE_OUT"

# The container is Linux; it cross-compiles arm64-apple-macos against the
# bind-mounted Darwin sysroot. OpenUIKit sees FoundationEssentials and never
# a module named Foundation (the measured umbrella-shadows-reexport hazard).
docker run --rm \
  -v "$UIKIT:/uikit:ro" \
  -v "$ROOT:/src:ro" \
  -v "$SUPPORT:/w:ro" \
  -v "$OUT:/out" \
  -e FE_OUT_REL="${FE_OUT#$SUPPORT/}" \
  -e COLLECTIONS_REL="${COLLECTIONS#$SUPPORT/}" \
  -e OSMOD_REL="${OSMOD#$SUPPORT/}" \
  -w /tmp \
  "$IMAGE" \
  bash -lc '
set -euo pipefail
die() { echo "guest_route_check-container: $*" >&2; exit 2; }
command -v swiftc >/dev/null && command -v clang-18 >/dev/null \
  || die "container missing swiftc/clang-18"
TARGET=arm64-apple-macos15.0
SYS=/w/scratch/sysroot_fe4
FE=/w/$FE_OUT_REL
COLLECTIONS=/w/$COLLECTIONS_REL
OSMOD=/w/$OSMOD_REL
SF=/w/scratch/swift-foundation
OUT=/out
mkdir -p "$OUT/module-cache" "$OUT/inc/CPortableIO" "$OUT/inc/CSTBTrueType" "$OUT/quartz-obj"
cp /uikit/Sources/CPortableIO/include/cportableio.h "$OUT/inc/CPortableIO/"
cp /uikit/Sources/CSTBTrueType/include/stb_truetype.h "$OUT/inc/CSTBTrueType/"
printf "%s\n" "module CPortableIO { header \"cportableio.h\" export * }" \
  > "$OUT/inc/CPortableIO/module.modulemap"
printf "%s\n" "module CSTBTrueType { header \"stb_truetype.h\" export * }" \
  > "$OUT/inc/CSTBTrueType/module.modulemap"

SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS"
  -module-cache-path "$OUT/module-cache"
  -runtime-compatibility-version none -wmo
  -Xfrontend -disable-implicit-string-processing-module-import
  -Xfrontend -disable-objc-attr-requires-foundation-module)
CINC=(-Xcc -fmodule-map-file=/uikit/Sources/CQuartz/include/module.modulemap
  -Xcc -I/uikit/Sources/CQuartz/include
  -Xcc -fmodule-map-file="$OUT/inc/CPortableIO/module.modulemap"
  -Xcc -I"$OUT/inc/CPortableIO"
  -Xcc -fmodule-map-file="$OUT/inc/CSTBTrueType/module.modulemap"
  -Xcc -I"$OUT/inc/CSTBTrueType"
  -Xcc -I/src/full/hostclock/include)
FEMODULES=(-I "$FE" -I "$COLLECTIONS" -I "$OSMOD"
  -Xcc -fmodule-map-file="$SF/Sources/_FoundationCShims/include/module.modulemap"
  -Xcc -I"$SF/Sources/_FoundationCShims/include")

echo "== guard: Foundation hidden, FoundationEssentials required"
if "${SWIFTC[@]}" "${CINC[@]}" -typecheck -module-name GuardMissingFoundationEssentials \
    /src/full/foundation/foundationessentials_import_guard.swift >/dev/null 2>&1; then
  die "FE guard passed without the staged FoundationEssentials module path"
fi
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -typecheck \
  -module-name GuardFoundationEssentials \
  /src/full/foundation/foundationessentials_import_guard.swift
echo "   -> exact visibility holds"

echo "== CQuartz ($(ls /uikit/Sources/CQuartz/*.cpp | wc -l | tr -d " ") TUs)"
QINC="-I/uikit/Sources/CQuartz/include -I/uikit/Sources/CQuartz"
QCXX=(-std=gnu++17 -fno-exceptions -fno-rtti -fPIC -Os -g0 -DNDEBUG
      -Wno-unused-parameter -Wno-unused-function
      -nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1
      -D__STDC_WANT_LIB_EXT1__=0
      -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_NONE
      "-D_LIBCPP_VERBOSE_ABORT(...)=__builtin_trap()")
for f in /uikit/Sources/CQuartz/*.cpp; do
  o="$OUT/quartz-obj/$(basename "$f" .cpp).o"
  clang-18 -target "$TARGET" -isysroot "$SYS" "${QCXX[@]}" $QINC -c "$f" -o "$o"
done
echo "   -> CQuartz objects"

clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -I/uikit/Sources/CPortableIO/include \
  -c /uikit/Sources/CPortableIO/io.c -o "$OUT/cportableio.o"

mapfile -t OCG < <(find /uikit/Sources/OpenCoreGraphics -type f -name "*.swift" | LC_ALL=C sort)
mapfile -t OUI < <(find /uikit/Sources/OpenUIKit -type f -name "*.swift" | LC_ALL=C sort)
echo "== OpenCoreGraphics (${#OCG[@]} files)"
"${SWIFTC[@]}" "${CINC[@]}" -module-name OpenCoreGraphics \
  -emit-object -emit-module -emit-module-path "$OUT/OpenCoreGraphics.swiftmodule" \
  -o "$OUT/opencoregraphics.o" "${OCG[@]}"
echo "== OpenUIKit (${#OUI[@]} files, Foundation hidden)"
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT" \
  -module-name OpenUIKit -emit-object -emit-module \
  -emit-module-path "$OUT/OpenUIKit.swiftmodule" -o "$OUT/openuikit.o" \
  "${OUI[@]}" /src/full/shims/FoundationNames.swift
echo "== UIKit shim (Foundation hidden)"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
  -I "$OUT" -module-name UIKit -emit-object -emit-module \
  -emit-module-path "$OUT/UIKit.swiftmodule" -o "$OUT/uikit.o" \
  /uikit/Sources/UIKitShim/UIKit.swift
echo "GUEST_ROUTE_COMPILE_OK openuikit=${#OUI[@]} opencoregraphics=${#OCG[@]}"
'

END=$(date +%s)
ELAPSED=$((END - START))
echo "GUEST_ROUTE_CHECK_OK elapsed=${ELAPSED}s out=$OUT"
if [ "$ELAPSED" -ge 600 ]; then
  echo "guest_route_check: warning: took ${ELAPSED}s (bar is under 10 minutes)" >&2
fi
