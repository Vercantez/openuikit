#!/usr/bin/env bash
# Build the AppKit core framework against an existing portable core package.
# This is an independent Linux/ARM64 proof; the production core builder later
# rebuilds SwiftUI and StoreKit with their AppKit interop sources.

set -euo pipefail

W=${W:-/w}
PACKAGE=${1:?usage: build_appkit_focused_guest.sh PACKAGE OUTPUT}
OUTPUT=${2:?usage: build_appkit_focused_guest.sh PACKAGE OUTPUT}
TARGET=arm64-apple-macos15.0
MIN_OS=15.0
APPKIT_ID=/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit
EXPECTED_EXPORT_COUNT=198
EXPECTED_EXPORT_SHA=dd9b850d2dcf4deb398752a950248a229b4374c40fa948727fa13ef9f50a2b15
EXPECTED_IMPORT_SHA=58c8c02cadac24ec680699924a8e4bcc7701562519242e74316b752b048195a4

die() {
    printf 'build_appkit_focused_guest: %s\n' "$*" >&2
    exit 2
}

case "$OUTPUT" in
    /*/appkit-focused-proof|/*/appkit-focused-proof-[A-Za-z0-9._-]*) ;;
    *) die "output must be an absolute narrowly named AppKit proof path: $OUTPUT" ;;
esac
[ ! -e "$OUTPUT" ] || die "output already exists: $OUTPUT"
[ -f "$PACKAGE/PACKAGE_COMPLETE" ] && [ ! -L "$PACKAGE/PACKAGE_COMPLETE" ] \
    || die 'completed core package is missing'
[ -f "$PACKAGE/modules/Foundation.swiftmodule" ] \
    || die 'portable Foundation module is missing'
[ -f "$PACKAGE/lib/libFoundation.dylib" ] \
    || die 'portable Foundation runtime is missing'
[ -x "$PACKAGE/guest-root/machorun" ] || die 'Machorun is missing'

mkdir -p "$OUTPUT/work/module-cache" "$OUTPUT/probe" "$OUTPUT/attestation"
cp -a "$PACKAGE/lib" "$OUTPUT/lib"
cp -a "$PACKAGE/guest-root" "$OUTPUT/guest-root"

framework=$OUTPUT/frameworks/AppKit.framework
versioned=$framework/Versions/C
module_dir=$versioned/Modules/AppKit.swiftmodule
runtime_framework=$OUTPUT/guest-root/darwin/System/Library/Frameworks/AppKit.framework
runtime_versioned=$runtime_framework/Versions/C
mkdir -p "$module_dir" "$runtime_versioned"

mapfile -d '' -t compile_arguments < "$PACKAGE/compile-flags.rsp"
package_root=$(cd "$PACKAGE" && pwd -P)
absolute_compile_arguments=()
for argument in "${compile_arguments[@]}"; do
    case "$argument" in
        sdk|modules|frameworks|host-tools/*|include/*)
            argument=$package_root/$argument
            ;;
        -Iinclude/*)
            argument=-I$package_root/${argument#-I}
            ;;
        -Fframeworks)
            argument=-F$package_root/frameworks
            ;;
        -fmodule-map-file=include/*)
            argument=-fmodule-map-file=$package_root/${argument#*=}
            ;;
    esac
    absolute_compile_arguments+=("$argument")
done

(
    cd "$PACKAGE"
    swiftc "${absolute_compile_arguments[@]}" -parse-as-library \
        -module-cache-path "$OUTPUT/work/module-cache" \
        -module-name AppKit -module-link-name AppKit \
        -enable-library-evolution -no-verify-emitted-module-interface \
        -emit-module \
        -emit-module-path "$module_dir/arm64-apple-macos.swiftmodule" \
        -emit-module-interface-path \
            "$module_dir/arm64-apple-macos.swiftinterface" \
        -emit-object -o "$OUTPUT/work/appkit.o" \
        "$W/full/appkit/AppKit.swift"

    ld64.lld-18 -arch arm64 \
        -platform_version macos "$MIN_OS" "$MIN_OS" -syslibroot sdk \
        -dylib -dead_strip -ignore_auto_link \
        -install_name "$APPKIT_ID" -rpath @loader_path \
        -o "$versioned/AppKit" "$OUTPUT/work/appkit.o" \
        -Llib -Lguest-root/darwin/usr/lib -Lsdk/usr/lib/swift \
        -lFoundation -lFoundationEssentials -lOpenUIKit -lOpenCoreGraphics \
        -lCombine -lOpenCombine -lDispatch \
        -lswiftCore -lswiftObjectiveC -lswift_Concurrency \
        guest-root/darwin/usr/lib/swift/libswiftObservation.dylib \
        guest-root/darwin/usr/lib/libswiftcompat.dylib \
        -Lsdk/usr/lib -lSystem -lobjc \
        guest-root/darwin/usr/lib/libquartz.dylib \
        guest-root/darwin/usr/lib/libSystem.B.dylib
)

ln -s C "$framework/Versions/Current"
ln -s Versions/Current/AppKit "$framework/AppKit"
ln -s Versions/Current/Modules "$framework/Modules"
cp "$versioned/AppKit" "$runtime_versioned/AppKit"
ln -s C "$runtime_framework/Versions/Current"
ln -s Versions/Current/AppKit "$runtime_framework/AppKit"

cmp "$versioned/AppKit" "$runtime_versioned/AppKit" \
    || die 'compile/runtime AppKit binaries differ'
for binary in "$versioned/AppKit" "$runtime_versioned/AppKit"; do
    llvm-otool-18 -hv "$binary" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
        || die "not an ARM64 Mach-O dylib: $binary"
    [ "$(llvm-otool-18 -D "$binary" | tail -n 1)" = "$APPKIT_ID" ] \
        || die "AppKit install identity drifted: $binary"
done

llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$versioned/AppKit" | LC_ALL=C sort -u \
    > "$OUTPUT/attestation/appkit-exports.txt"
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$versioned/AppKit" | LC_ALL=C sort -u \
    > "$OUTPUT/attestation/appkit-imports.txt"
llvm-otool-18 -L "$versioned/AppKit" \
    > "$OUTPUT/attestation/appkit-loads.txt"
awk 'NR > 1 { print $1 }' "$OUTPUT/attestation/appkit-loads.txt" \
    > "$OUTPUT/attestation/appkit-load-identities.txt"
export_count=$(wc -l < "$OUTPUT/attestation/appkit-exports.txt" \
    | tr -d '[:space:]')
[ "$export_count" -eq "$EXPECTED_EXPORT_COUNT" ] \
    || die "AppKit export count $export_count, expected $EXPECTED_EXPORT_COUNT"
[ "$(sha256sum "$OUTPUT/attestation/appkit-exports.txt" | awk '{print $1}')" \
    = "$EXPECTED_EXPORT_SHA" ] || die 'AppKit exact export contract drifted'
[ "$(sha256sum "$OUTPUT/attestation/appkit-imports.txt" | awk '{print $1}')" \
    = "$EXPECTED_IMPORT_SHA" ] || die 'AppKit exact import contract drifted'
cmp "$W/full/appkit/tests/appkit-load-identities.txt" \
    "$OUTPUT/attestation/appkit-load-identities.txt" \
    || die 'AppKit exact load closure drifted'
[ "$(awk -v expected="$APPKIT_ID" '$1 == expected { count++ } END { print count + 0 }' \
    "$OUTPUT/attestation/appkit-loads.txt")" -eq 1 ] \
    || die 'AppKit self identity is missing or duplicated'
[ "$(awk '$1 == "@rpath/libFoundation.dylib" { count++ } END { print count + 0 }' \
    "$OUTPUT/attestation/appkit-loads.txt")" -eq 1 ] \
    || die 'AppKit portable Foundation load is missing or duplicated'
if grep -Fq '/System/Library/Frameworks/Foundation.framework/' \
    "$OUTPUT/attestation/appkit-loads.txt"; then
    die 'AppKit loads Apple Foundation rather than the portable runtime'
fi

compile_probe() {
    local name=$1 source=$2 mode=$3
    local object=$OUTPUT/work/$name.o
    local -a parse_arguments=()
    if [ "$mode" = library ]; then
        parse_arguments=(-parse-as-library)
    elif [ "$mode" != script ]; then
        die "unknown Swift probe mode: $mode"
    fi
    (
        cd "$PACKAGE"
        swiftc "${absolute_compile_arguments[@]}" -F "$OUTPUT/frameworks" \
            -module-cache-path "$OUTPUT/work/module-cache" \
            "${parse_arguments[@]}" -module-name "$name" -emit-object \
            -o "$object" "$source"
        ld64.lld-18 -dead_strip -ignore_auto_link \
            -arch arm64 -platform_version macos "$MIN_OS" "$MIN_OS" \
            -syslibroot "$package_root/sdk" \
            -exported_symbol __mh_execute_header \
            -rpath @loader_path/../lib -needed_library "$versioned/AppKit" \
            -o "$OUTPUT/probe/$name" "$object" \
            -L"$OUTPUT/lib" -L"$package_root/lib" \
            -L"$package_root/guest-root/darwin/usr/lib" \
            -L"$package_root/sdk/usr/lib/swift" \
            -lFoundation -lFoundationEssentials -lOpenUIKit \
            -lOpenCoreGraphics -lCombine -lOpenCombine -lDispatch \
            -lswiftCore -lswiftObjectiveC -lswift_Concurrency \
            "$package_root/guest-root/darwin/usr/lib/swift/libswiftObservation.dylib" \
            "$package_root/guest-root/darwin/usr/lib/libswiftcompat.dylib" \
            -L"$package_root/sdk/usr/lib" -lSystem -lobjc \
            "$package_root/guest-root/darwin/usr/lib/libquartz.dylib" \
            "$package_root/guest-root/darwin/usr/lib/libSystem.B.dylib"
    )
    llvm-otool-18 -hv "$OUTPUT/probe/$name" \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
        || die "$name is not an ARM64 Mach-O executable"
    [ "$(llvm-otool-18 -L "$OUTPUT/probe/$name" \
        | awk -v expected="$APPKIT_ID" '$1 == expected { count++ } END { print count + 0 }')" -eq 1 ] \
        || die "$name AppKit load is missing or duplicated"
}
compile_probe AppKitGuestRuntime \
    "$W/full/appkit/tests/AppKitGuestRuntime.swift" library
compile_probe AppKitInterfaceOracle \
    "$W/full/appkit/tests/AppKitInterfaceOracle.swift" script

preload_libraries=()
for host_library in \
    libOpenDispatchHost.so \
    libOpenFoundationInternationalizationHost.so \
    libOpenURLTransportHost.so \
    libOpenRelativeTimeHost.so \
    libOpenCompressionHost.so \
    libOpenZlibHost.so; do
    if [ -f "$OUTPUT/guest-root/host/$host_library" ]; then
        preload_libraries+=("$OUTPUT/guest-root/host/$host_library")
    fi
done
preload=$(IFS=:; printf '%s' "${preload_libraries[*]}")
run_probe() {
    local name=$1
    (
        cd "$OUTPUT"
        LD_LIBRARY_PATH="$OUTPUT/guest-root/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        LD_PRELOAD="$preload${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$OUTPUT/guest-root" \
            "$OUTPUT/guest-root/machorun" "./probe/$name"
    ) > "$OUTPUT/attestation/$name.log" 2> "$OUTPUT/attestation/$name.stderr"
}
run_probe AppKitGuestRuntime
run_probe AppKitInterfaceOracle
grep -Fxq \
    'APPKIT_GUEST_MACHO_OK surface=application,alert,workspace,window,font,color ui=headless workspace=fail-closed alert=cancel-or-abort fonts=unavailable' \
    "$OUTPUT/attestation/AppKitGuestRuntime.log" \
    || die 'AppKit cold runtime marker is missing'
cmp "$W/full/appkit/tests/appkit-interface-apple-xcode-26.1.txt" \
    "$OUTPUT/attestation/AppKitInterfaceOracle.log" \
    || die 'AppKit guest interface differs from Apple'

{
    printf 'format\tappkit-focused-proof-v1\n'
    printf 'install-name\t%s\n' "$APPKIT_ID"
    printf 'framework\t%s\n' \
        "$(sha256sum "$versioned/AppKit" | awk '{print $1}')"
    printf 'module\t%s\n' \
        "$(sha256sum "$module_dir/arm64-apple-macos.swiftmodule" | awk '{print $1}')"
    printf 'exports\tcount=%s\tsha256=%s\n' "$export_count" \
        "$(sha256sum "$OUTPUT/attestation/appkit-exports.txt" | awk '{print $1}')"
    printf 'apple-differential\trows=10\tsha256=%s\n' \
        "$(sha256sum "$OUTPUT/attestation/AppKitInterfaceOracle.log" | awk '{print $1}')"
    printf 'cold-runtime\tsha256=%s\n' \
        "$(sha256sum "$OUTPUT/attestation/AppKitGuestRuntime.log" | awk '{print $1}')"
} > "$OUTPUT/PROOF_COMPLETE"

printf 'APPKIT_FOCUSED_GUEST_OK exports=%s apple-rows=10 cold=1 identity=Versions/C\n' \
    "$export_count"
