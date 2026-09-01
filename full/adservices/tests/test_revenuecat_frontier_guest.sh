#!/usr/bin/env bash
# Compile and cold-run the exact pinned RevenueCat AdServices, zlib, and IOKit
# consumers against a completed relocatable core package. Run inside the pinned
# ARM64 Linux production image; neither the package nor the vendor checkout is
# edited.

set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

W=${W:-/w}
PACKAGE=${1:?usage: test_revenuecat_frontier_guest.sh PACKAGE REVENUECAT OUTPUT}
REVENUECAT=${2:?usage: test_revenuecat_frontier_guest.sh PACKAGE REVENUECAT OUTPUT}
OUTPUT=${3:?usage: test_revenuecat_frontier_guest.sh PACKAGE REVENUECAT OUTPUT}

EXPECTED_COMMIT=57043e7e0173c48d64e171944ac76a34d2467fa1
EXPECTED_TREE=72a2e1e9b6986fadca9b863d235c4a52aab38fb4

die() {
    printf 'revenuecat_frontier_guest: %s\n' "$*" >&2
    exit 2
}

case "$OUTPUT" in
    /*/revenuecat-frontier-proof|/*/revenuecat-frontier-proof-[A-Za-z0-9._-]*) ;;
    *) die "output must be an absolute narrowly named RevenueCat proof path: $OUTPUT" ;;
esac
[ ! -e "$OUTPUT" ] || die "output already exists: $OUTPUT"
[ -f "$PACKAGE/PACKAGE_COMPLETE" ] && [ ! -L "$PACKAGE/PACKAGE_COMPLETE" ] \
    || die 'completed core package is missing'
[ -d "$REVENUECAT/.git" ] || die 'RevenueCat checkout is missing'
[ "$(git -C "$REVENUECAT" rev-parse HEAD^{commit})" = "$EXPECTED_COMMIT" ] \
    || die 'RevenueCat commit drifted'
[ "$(git -C "$REVENUECAT" rev-parse HEAD^{tree})" = "$EXPECTED_TREE" ] \
    || die 'RevenueCat tree drifted'
[ -z "$(git -C "$REVENUECAT" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'RevenueCat checkout is not untouched'

require_source() {
    local relative=$1 expected=$2
    [ -f "$REVENUECAT/$relative" ] && [ ! -L "$REVENUECAT/$relative" ] \
        || die "RevenueCat source is missing or linked: $relative"
    [ "$(sha256sum "$REVENUECAT/$relative" | awk '{print $1}')" = "$expected" ] \
        || die "RevenueCat source hash drifted: $relative"
}
require_source Sources/Attribution/AttributionFetcher.swift \
    f15a4f4a4cab68e397fdfff4bc6b8b64838d19b968d278650834b2a837a3258a
require_source Sources/Attribution/AttributionTypeFactory.swift \
    8cd377185534fd99063bcd41fae693d2f41a46b06b2323c50ebfd402bdba765d
require_source Sources/Attribution/TrackingManagerProxy.swift \
    c7af9cdaa134ff38b715e04b19989878e48e5313d6d2ea8e5f0c3363db287471
require_source Sources/Attribution/ASIdManagerProxy.swift \
    874f73d1d67762b9c849dcfe8458743de58da0afdf47599061ba7bb431cd8969
require_source Sources/Networking/RCContainer+Compression.swift \
    b0998e607a77f25856f7cf65aa34248e910d7157d1215b3ae5ab974579b6ecec
require_source Sources/Misc/MacDevice.swift \
    247a96213f5e5f005fb1619024986b38c3c276a7852b30feec049c3d529fcea9

python3 -B "$W/full/frameworks/core_package_manifest.py" verify \
    --package-root "$PACKAGE"
mkdir -p "$OUTPUT/objects" "$OUTPUT/probe" \
    "$OUTPUT/module-cache/adservices" "$OUTPUT/module-cache/zlib" \
    "$OUTPUT/module-cache/iokit"
mapfile -d '' -t compile_arguments < "$PACKAGE/compile-flags.rsp"
mapfile -d '' -t link_arguments < "$PACKAGE/link-inputs.rsp"

(
    cd "$PACKAGE"
    swiftc "${compile_arguments[@]}" -swift-version 5 -wmo \
        -module-cache-path "$OUTPUT/module-cache/adservices" \
        -parse-as-library -module-name RevenueCatAttributionRuntime \
        -emit-object -o "$OUTPUT/objects/revenuecat-attribution.o" \
        "$REVENUECAT/Sources/Attribution/AttributionFetcher.swift" \
        "$REVENUECAT/Sources/Attribution/AttributionTypeFactory.swift" \
        "$REVENUECAT/Sources/Attribution/TrackingManagerProxy.swift" \
        "$REVENUECAT/Sources/Attribution/ASIdManagerProxy.swift" \
        "$W/full/adservices/tests/RevenueCatAttributionRuntimeSupport.swift"
    ld64.lld-18 -dead_strip -ignore_auto_link \
        -exported_symbol __mh_execute_header \
        -rpath "$PACKAGE/lib" \
        -needed_library "$PACKAGE/lib/libAdServices.dylib" \
        -o "$OUTPUT/probe/RevenueCatAttributionRuntime" \
        "$OUTPUT/objects/revenuecat-attribution.o" \
        "${link_arguments[@]}"

    swiftc "${compile_arguments[@]}" -swift-version 5 -wmo \
        -module-cache-path "$OUTPUT/module-cache/zlib" \
        -parse-as-library -module-name RevenueCatZlibRuntime \
        -emit-object -o "$OUTPUT/objects/revenuecat-zlib.o" \
        "$REVENUECAT/Sources/Networking/RCContainer+Compression.swift" \
        "$W/full/zlib/tests/RevenueCatZlibRuntimeSupport.swift"
    ld64.lld-18 -dead_strip -ignore_auto_link \
        -exported_symbol __mh_execute_header \
        -rpath "$PACKAGE/lib" \
        -needed_library "$PACKAGE/lib/libCompression.dylib" \
        -needed_library "$PACKAGE/lib/libz.dylib" \
        -o "$OUTPUT/probe/RevenueCatZlibRuntime" \
        "$OUTPUT/objects/revenuecat-zlib.o" \
        "${link_arguments[@]}"

    swiftc "${compile_arguments[@]}" -swift-version 5 -wmo \
        -module-cache-path "$OUTPUT/module-cache/iokit" \
        -parse-as-library -module-name RevenueCatIOKitRuntime \
        -emit-object -o "$OUTPUT/objects/revenuecat-iokit.o" \
        "$REVENUECAT/Sources/Misc/MacDevice.swift" \
        "$W/full/iokit/tests/RevenueCatIOKitRuntimeSupport.swift"
    ld64.lld-18 -dead_strip -ignore_auto_link \
        -exported_symbol __mh_execute_header \
        -rpath "$PACKAGE/lib" \
        -o "$OUTPUT/probe/RevenueCatIOKitRuntime" \
        "$OUTPUT/objects/revenuecat-iokit.o" \
        "${link_arguments[@]}"
)

for executable in RevenueCatAttributionRuntime RevenueCatZlibRuntime \
    RevenueCatIOKitRuntime; do
    llvm-otool-18 -hv "$OUTPUT/probe/$executable" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
        || die "$executable is not an ARM64 Mach-O executable"
done
llvm-otool-18 -L "$OUTPUT/probe/RevenueCatAttributionRuntime" \
    | grep -Fq '@rpath/libAdServices.dylib' \
    || die 'exact attribution consumer does not load portable AdServices'
llvm-otool-18 -L "$OUTPUT/probe/RevenueCatZlibRuntime" \
    | grep -Fq '@rpath/libCompression.dylib' \
    || die 'exact gzip consumer does not load portable Compression'
llvm-otool-18 -L "$OUTPUT/probe/RevenueCatZlibRuntime" \
    | grep -Fq '@rpath/libz.dylib' \
    || die 'exact gzip consumer does not load portable zlib'
iokit_install_name=/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
iokit_load_count=$(llvm-otool-18 -L "$OUTPUT/probe/RevenueCatIOKitRuntime" \
    | awk -v expected="$iokit_install_name" \
        '$1 == expected { count++ } END { print count + 0 }')
[ "$iokit_load_count" -eq 1 ] \
    || die "exact MacDevice consumer IOKit load count $iokit_load_count, expected 1"

guest_root=$PACKAGE/guest-root
preload=$guest_root/host/libOpenDispatchHost.so:$guest_root/host/libOpenFoundationInternationalizationHost.so:$guest_root/host/libOpenURLTransportHost.so:$guest_root/host/libOpenRelativeTimeHost.so:$guest_root/host/libOpenCompressionHost.so:$guest_root/host/libOpenZlibHost.so
for executable in RevenueCatAttributionRuntime RevenueCatZlibRuntime \
    RevenueCatIOKitRuntime; do
    (
        cd "$OUTPUT"
        LD_LIBRARY_PATH="$guest_root/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        LD_PRELOAD="$preload${LD_PRELOAD:+:$LD_PRELOAD}" \
            MACHORUN_ROOT="$guest_root" \
            "$guest_root/machorun" "./probe/$executable"
    ) | tee "$OUTPUT/$executable.log"
done
grep -Fxq \
    'REVENUECAT_ADSERVICES_UNTOUCHED_MACHO_OK commit=57043e7 source=f15a4f4 token=unavailable' \
    "$OUTPUT/RevenueCatAttributionRuntime.log" \
    || die 'exact RevenueCat attribution marker is missing'
grep -Fxq \
    'REVENUECAT_ZLIB_UNTOUCHED_MACHO_OK commit=57043e7 source=b0998e6 gzip=exact malformed=fail-closed bytes=77' \
    "$OUTPUT/RevenueCatZlibRuntime.log" \
    || die 'exact RevenueCat gzip marker is missing'
grep -Fxq \
    'REVENUECAT_IOKIT_UNTOUCHED_MACHO_OK commit=57043e7 source=247a962 registry=unavailable' \
    "$OUTPUT/RevenueCatIOKitRuntime.log" \
    || die 'exact RevenueCat MacDevice marker is missing'

{
    printf 'format\trevenuecat-frontier-proof-v1\n'
    printf 'repository\tcommit=%s\ttree=%s\n' "$EXPECTED_COMMIT" "$EXPECTED_TREE"
    printf 'attribution-log\t%s\n' \
        "$(sha256sum "$OUTPUT/RevenueCatAttributionRuntime.log" | awk '{print $1}')"
    printf 'zlib-log\t%s\n' \
        "$(sha256sum "$OUTPUT/RevenueCatZlibRuntime.log" | awk '{print $1}')"
    printf 'iokit-log\t%s\n' \
        "$(sha256sum "$OUTPUT/RevenueCatIOKitRuntime.log" | awk '{print $1}')"
} > "$OUTPUT/PROOF_COMPLETE"
printf 'REVENUECAT_FRONTIER_GUEST_OK commit=%s consumers=3 runtime=adservices,zlib,iokit\n' \
    "$EXPECTED_COMMIT"
