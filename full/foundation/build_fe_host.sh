#!/bin/bash
# build_fe_host.sh -- MACOS ONLY.  Build the SAME 202 sources with Apple's
# toolchain against Apple's SDK, and run the URL oracle natively.
#
# WHAT THIS ISOLATES, and what it does not.  It answers ONE question: does
# swift-foundation release/6.2.2's `_SwiftURL` reproduce, on all 809 real URL
# literals, what real macOS Foundation's `URL` produced?  No machorun, no
# staged sysroot, no Mach-O loader -- so a failure here is the PORT's, and a
# failure that appears only in the Mach-O build is the STACK's.  Neither run
# can tell you that on its own, which is why both exist.
#
# It is NOT a "same bytes both sides" gate.  The golden was produced by
# Foundation's URL, which on Darwin is runtime-flag-selected and normally
# `_BridgedURL` (NSURL-backed); this builds `_SwiftURL`.  Differences are
# findings about the two implementations, not automatically defects.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only" >&2; exit 1; }
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SF=${SF:-$ROOT/scratch/swift-foundation}
SC=${SC:-$ROOT/scratch/swift-collections}
OUT=${OUT:-$ROOT/scratch/fe_host}
TARGET=${TARGET:-arm64-apple-macos15.0}
mkdir -p "$OUT"
SWIFTC=(xcrun swiftc -target "$TARGET" -wmo)

echo "== swift-collections"
for pair in "InternalCollectionsUtilities:InternalCollectionsUtilities" \
            "OrderedCollections:OrderedCollections" "_RopeModule:RopeModule"; do
    mod=${pair%%:*}; dir=${pair##*:}
    srcs=(); while IFS= read -r f; do srcs+=("$f"); done < <(find "$SC/Sources/$dir" -name '*.swift' | sort)
    "${SWIFTC[@]}" -parse-as-library -module-name "$mod" -I "$OUT" \
        -emit-module -emit-module-path "$OUT/$mod.swiftmodule" \
        -c -o "$OUT/$mod.o" "${srcs[@]}"
done

echo "== _FoundationCShims"
for c in platform_shims string_shims uuid; do
    xcrun clang -target "$TARGET" -O2 -I "$SF/Sources/_FoundationCShims/include" \
        -c -o "$OUT/$c.o" "$SF/Sources/_FoundationCShims/$c.c"
done

# Upstream's flags, identical to build_fe.sh -- see that file for why each one
# is here and what its absence cost.
AVAIL="macOS 15, iOS 18, tvOS 18, watchOS 11"
FEATURES=()
for f in VariadicGenerics LifetimeDependence AddressableTypes AllowUnsafeAttribute \
         BuiltinModule AccessLevelOnImport StrictConcurrency; do
    FEATURES+=(-enable-experimental-feature "$f")
done
for v in 6.0.2 6.1 6.2; do
    FEATURES+=(-enable-experimental-feature "AvailabilityMacro=FoundationPreview $v:$AVAIL")
done
for f in InferSendableFromCaptures MemberImportVisibility; do
    FEATURES+=(-enable-upcoming-feature "$f")
done

SRCS=(); while IFS= read -r f; do SRCS+=("$f"); done < <(
    find "$SF/Sources/FoundationEssentials" -name '*.swift' | sort)
echo "== FoundationEssentials: ${#SRCS[@]} files"
"${SWIFTC[@]}" -parse-as-library -module-name FoundationEssentials \
    -package-name SwiftFoundation -I "$OUT" \
    -Xcc -fmodule-map-file="$SF/Sources/_FoundationCShims/include/module.modulemap" \
    -Xcc -I"$SF/Sources/_FoundationCShims/include" \
    "${FEATURES[@]}" \
    -emit-module -emit-module-path "$OUT/FoundationEssentials.swiftmodule" \
    -c -o "$OUT/FoundationEssentials.o" "${SRCS[@]}"

echo "== url_runner"
"${SWIFTC[@]}" -module-name url_runner -I "$OUT" \
    -Xcc -fmodule-map-file="$SF/Sources/_FoundationCShims/include/module.modulemap" \
    -Xcc -I"$SF/Sources/_FoundationCShims/include" \
    -o "$OUT/url_runner" \
    "$ROOT/full/oracle-url/url_runner.swift" \
    "$OUT/FoundationEssentials.o" "$OUT/InternalCollectionsUtilities.o" \
    "$OUT/OrderedCollections.o" "$OUT/_RopeModule.o" \
    "$OUT/platform_shims.o" "$OUT/string_shims.o" "$OUT/uuid.o"
echo "== built $OUT/url_runner"
