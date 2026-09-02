#!/usr/bin/env bash
# Compare the exact named-resource Bundle slice with Apple Foundation, then
# build all OpenCoreGraphics/OpenUIKit sources for target15 and run the same
# contract through machorun, including a dynamically linked framework class.

set -euo pipefail
umask 077

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
SUPPORT=${SWIFT_MACHO_LINUX:-"$REPO/../swift-macho-linux"}
if [ ! -d "$SUPPORT/scratch" ]; then
    SUPPORT=$(git -C "$REPO" rev-parse --show-toplevel)
fi
IMAGE=${SWIFT_MACHO_IMAGE:-swift-macho-spike:noble}
PROBE=$REPO/Tools/bundleprobe/main.swift
FRAMEWORK_PROBE=$REPO/Tools/bundleprobe/FrameworkFinder.swift
SYSROOT=$SUPPORT/scratch/sysroot_fe4
GUEST_ROOT=$SUPPORT/scratch/mrroot_full
REPO_ROOT=$(git -C "$REPO" rev-parse --show-toplevel)

fail() {
    echo "prove_portable_bundle: $*" >&2
    exit 2
}

[[ -f "$PROBE" && -f "$FRAMEWORK_PROBE" ]] || fail "Bundle probe sources are missing"
[[ -d "$SYSROOT/usr/include" ]] || fail "missing target15 sysroot: $SYSROOT"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/openuikit-bundle.XXXXXX")
cleanup() {
    if [[ "${KEEP_PORTABLE_BUNDLE_PROBE:-0}" == "1" ]]; then
        echo "kept Bundle proof: $WORK"
    else
        rm -rf "$WORK"
    fi
}
trap cleanup EXIT

write_plist() {
    plist_path=$1
    executable=$2
    identifier=$3
    package_type=$4
    mkdir -p "$(dirname "$plist_path")"
    printf '%s\n' \
        '<?xml version="1.0" encoding="UTF-8"?>' \
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
        '<plist version="1.0"><dict>' \
        "<key>CFBundleExecutable</key><string>$executable</string>" \
        "<key>CFBundleIdentifier</key><string>$identifier</string>" \
        "<key>CFBundleName</key><string>$executable</string>" \
        "<key>CFBundlePackageType</key><string>$package_type</string>" \
        '<key>CFBundleDevelopmentRegion</key><string>en</string>' \
        '</dict></plist>' > "$plist_path"
}

populate_resources() {
    resource_root=$1
    mkdir -p "$resource_root/nested"
    printf 'extensionless\n' > "$resource_root/extensionless"
    printf 'alpha\n' > "$resource_root/alpha.txt"
    printf 'double suffix\n' > "$resource_root/alpha.txt.txt"
    printf 'nested\n' > "$resource_root/nested/child.txt"
    printf 'outside leaf\n' > "${resource_root}.outside.txt"
    mkdir -p "${resource_root}.outside-dir"
    printf 'outside directory\n' > "${resource_root}.outside-dir/child.txt"
    ln -s "../$(basename "$resource_root").outside.txt" "$resource_root/leaf-escape.txt"
    ln -s "../$(basename "$resource_root").outside-dir" "$resource_root/via-outside"
    ln -s nested/child.txt "$resource_root/inside-link.txt"
}

make_fixtures() {
    fixture_root=$1
    flat=$fixture_root/Flat.bundle
    structured=$fixture_root/Structured.app
    framework=$fixture_root/Probe.framework
    main=$fixture_root/MainProbe.app
    dynamic=$main/Contents/Frameworks/DynamicProbe.framework

    mkdir -p "$main/Contents/MacOS" "$dynamic/Resources"
    populate_resources "$flat"
    populate_resources "$structured/Contents/Resources"
    populate_resources "$framework/Resources"
    populate_resources "$main/Contents/Resources"
    populate_resources "$dynamic/Resources"
    write_plist "$flat/Info.plist" Flat org.openui.bundle.flat BNDL
    write_plist "$structured/Contents/Info.plist" Structured org.openui.bundle.structured APPL
    write_plist "$framework/Resources/Info.plist" Probe org.openui.bundle.static-framework FMWK
    write_plist "$main/Contents/Info.plist" BundleProbe org.openui.bundle.main APPL
    write_plist "$dynamic/Resources/Info.plist" DynamicProbe org.openui.bundle.dynamic FMWK
    printf 'ordinary\n' > "$fixture_root/ordinary-file"
    printf 'outside\n' > "$fixture_root/outside.txt"
    printf 'root child\n' > "$fixture_root/root-child.txt"
}

make_fixtures "$WORK/native"
make_fixtures "$WORK/guest"

echo "==> native Apple Bundle oracle"
if [ "$(uname -s)" = Darwin ] && command -v xcrun >/dev/null; then
mkdir -p "$WORK/native-modules"
native_framework=$WORK/native/MainProbe.app/Contents/Frameworks/DynamicProbe.framework/DynamicProbe
xcrun swiftc -swift-version 5 -parse-as-library \
    -module-name BundleProbeFramework -emit-module \
    -emit-module-path "$WORK/native-modules/BundleProbeFramework.swiftmodule" \
    -emit-library -o "$native_framework" "$FRAMEWORK_PROBE" \
    -Xlinker -install_name -Xlinker @rpath/DynamicProbe.framework/DynamicProbe
xcrun swiftc -swift-version 5 -I "$WORK/native-modules" "$PROBE" \
    -Xlinker "$native_framework" \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    -o "$WORK/native/MainProbe.app/Contents/MacOS/BundleProbe"
"$WORK/native/MainProbe.app/Contents/MacOS/BundleProbe" "$WORK/native" \
    | tee "$WORK/native.log"
grep '^\(root\|main\|flat\|structured\|framework\|dynamic\|init\)\.' \
    "$WORK/native.log" > "$WORK/native.contract"
else
echo "CURSOR_ENV_MACOS_ORACLE_LOCAL_ONLY host=$(uname -s)"
fi

echo "==> Foundation-hidden ARM64 Mach-O Bundle guest"
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
[[ -x "$GUEST_ROOT/machorun" ]] || fail "missing machorun guest root: $GUEST_ROOT"
[[ -f "$SUPPORT/build/full/swiftcorepatch.o" ]] \
    || fail "missing full-build Swift runtime patch object"
[[ -f "$SUPPORT/build/full/foundation/essentials/FoundationEssentials.swiftmodule" ]] \
    || fail "missing full-build FoundationEssentials module"
docker run --rm \
    -v "$REPO:/uikit:ro" \
    -v "$SUPPORT:/w:ro" \
    -v "$WORK:/work" \
    -w /tmp \
    "$IMAGE" \
    bash -lc '
set -euo pipefail
TARGET=arm64-apple-macos15.0
SYS=/w/scratch/sysroot_fe4
ROOT=/w/scratch/mrroot_full
SHARED=/w/build/full
OUT=/work/guest-build
APP=/work/guest/MainProbe.app
mkdir -p "$OUT/modules" "$OUT/module-cache"

SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS"
  -module-cache-path "$OUT/module-cache"
  -runtime-compatibility-version none -wmo
  -Xfrontend -disable-implicit-string-processing-module-import
  -Xfrontend -disable-objc-attr-requires-foundation-module)
CINC=(-Xcc -fmodule-map-file=/uikit/Sources/CQuartz/include/module.modulemap
  -Xcc -I/uikit/Sources/CQuartz/include
  -Xcc -I"$SHARED/inc/CPortableIO"
  -Xcc -I"$SHARED/inc/CSTBTrueType")
FEMODULES=(-I "$SHARED/foundation/essentials"
  -I "$SHARED/foundation/collections"
  -I "$SHARED/foundation/os"
  -Xcc -fmodule-map-file=/w/scratch/swift-foundation/Sources/_FoundationCShims/include/module.modulemap
  -Xcc -I/w/scratch/swift-foundation/Sources/_FoundationCShims/include)

clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -c /uikit/Sources/CPortableIO/io.c -o "$OUT/cportableio.o"

mapfile -t OCG_SOURCES < <(find /uikit/Sources/OpenCoreGraphics -type f -name "*.swift" | sort)
mapfile -t OUI_SOURCES < <(find /uikit/Sources/OpenUIKit -type f -name "*.swift" | sort)
[[ ${#OCG_SOURCES[@]} -eq 12 ]] || { echo "expected 12 OpenCoreGraphics sources" >&2; exit 1; }
[[ ${#OUI_SOURCES[@]} -eq 100 ]] || { echo "expected 100 OpenUIKit sources" >&2; exit 1; }
printf "OpenCoreGraphics source count: %s\n" "${#OCG_SOURCES[@]}"
printf "OpenUIKit source count: %s\n" "${#OUI_SOURCES[@]}"

"${SWIFTC[@]}" "${CINC[@]}" -module-name OpenCoreGraphics \
  -emit-object -emit-module \
  -emit-module-path "$OUT/modules/OpenCoreGraphics.swiftmodule" \
  -o "$OUT/opencoregraphics.o" "${OCG_SOURCES[@]}"
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT/modules" \
  -module-name OpenUIKit -emit-object -emit-module \
  -emit-module-path "$OUT/modules/OpenUIKit.swiftmodule" \
  -o "$OUT/openuikit.o" "${OUI_SOURCES[@]}" /w/full/shims/FoundationNames.swift

"${SWIFTC[@]}" -parse-as-library -module-name BundleProbeFramework \
  -emit-module -emit-module-path "$OUT/modules/BundleProbeFramework.swiftmodule" \
  -emit-object -o "$OUT/framework.o" /uikit/Tools/bundleprobe/FrameworkFinder.swift
ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
  -syslibroot "$SYS" -dylib -undefined dynamic_lookup \
  -install_name @rpath/DynamicProbe.framework/DynamicProbe \
  -o "$APP/Contents/Frameworks/DynamicProbe.framework/DynamicProbe" \
  "$OUT/framework.o"

"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT/modules" \
  -module-name BundleProbe -emit-object -o "$OUT/probe.o" \
  /uikit/Tools/bundleprobe/main.swift

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
  "$SHARED/foundation/essentials/uuid_compat.o")

ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
  -syslibroot "$SYS" -rpath /usr/lib/swift -rpath @loader_path \
  -rpath @executable_path/../Frameworks \
  -dead_strip -exported_symbol __mh_execute_header \
  -L"$ROOT/darwin/usr/lib" \
  -L/usr/lib/swift -lswiftCore "$ROOT/darwin/usr/lib/libswiftcompat.dylib" \
  -L/usr/lib -lSystem -lobjc "$ROOT/darwin/usr/lib/libquartz.dylib" \
  "$ROOT/darwin/usr/lib/libSystem.B.dylib" \
  -o "$APP/Contents/MacOS/BundleProbe" \
  "$OUT/probe.o" "$OUT/openuikit.o" "$OUT/opencoregraphics.o" \
  "$OUT/cportableio.o" "$SHARED/cstbtruetype.o" "$SHARED/hostclock.o" \
  "$SHARED/swiftcorepatch.o" "${FE_OBJECTS[@]}" \
  "$APP/Contents/Frameworks/DynamicProbe.framework/DynamicProbe"

file "$OUT/opencoregraphics.o" "$OUT/openuikit.o" \
  "$APP/Contents/Frameworks/DynamicProbe.framework/DynamicProbe" \
  "$APP/Contents/MacOS/BundleProbe"
OPENUIKIT_RESOURCE_ROOT=/uikit/Sources/OpenUIKit/Resources \
  MACHORUN_ROOT="$ROOT" "$ROOT/machorun" \
  "$APP/Contents/MacOS/BundleProbe" /work/guest
' | tee "$WORK/guest.log"

grep '^\(root\|main\|flat\|structured\|framework\|dynamic\|init\)\.' \
    "$WORK/guest.log" > "$WORK/guest.contract"
diff -u "$WORK/native.contract" "$WORK/guest.contract"
grep -Fqx 'BUNDLE_ROOT_RESOURCE_CONTRACT_OK' "$WORK/native.log" \
    || fail "native root-resource marker is missing"
grep -Fqx 'BUNDLE_ROOT_RESOURCE_CONTRACT_OK' "$WORK/guest.log" \
    || fail "guest root-resource marker is missing"
grep -Fqx 'BUNDLE_EXACT_NAMED_RESOURCE_CONTRACT_OK' "$WORK/native.log" \
    || fail "native marker is missing"
grep -Fqx 'BUNDLE_EXACT_NAMED_RESOURCE_CONTRACT_OK' "$WORK/guest.log" \
    || fail "guest marker is missing"
grep -Fqx 'BUNDLE_GUEST_FAIL_CLOSED_OK' "$WORK/guest.log" \
    || fail "guest fail-closed marker is missing"
grep -Fqx 'BUNDLE_GUEST_SYMLINK_COMPONENT_GATE_OK' "$WORK/guest.log" \
    || fail "guest symlink-component marker is missing"

echo "PASS: Apple and Foundation-hidden ARM64 Mach-O Bundle contracts match"
elif bash "$REPO_ROOT/.cursor/attest-cursor-env.sh"; then
echo "CURSOR_ENV_TOOLCHAIN_ATTESTED Bundle guest compile uses the pinned swift:6.2-noble toolchain; execution cannot proceed on this host"
bash "$REPO_ROOT/.cursor/refuse-arm64-execution.sh" || exit $?
else
fail "Docker is required for the Linux-hosted guest, and CURSOR_ENV attestation failed"
fi
