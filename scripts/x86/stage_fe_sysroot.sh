#!/usr/bin/env bash
# Linux sibling of full/foundation/stage_fe_sysroot.sh (which stays Darwin-only
# because it reads Xcode). Stages scratch/sysroot_fe4-x86_64 BESIDE the arm64
# tree. Never writes scratch/sysroot_fe4. Never copies an arm64 Mach-O into the
# x86 sysroot under a production name.
#
# Textual Darwin overlays (*.swiftinterface, apinotes) are copied FROM the
# existing arm64 sysroot_fe4 when present -- they are SDK text, not objects.
# Arch-specific Swift.swiftmodule slices and dylibs are not.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.inc
. "$HERE/common.inc"

W=${W:?set W to the openuikit tree}
# shellcheck disable=SC1091
. "$W/full/scripts/guest_arch.inc"
MACHORUN=${MACHORUN:-$W/machorun}
ARM_SYS=${ARM_SYS:-$W/scratch/sysroot_fe4}
SYS=${SYS:-$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}}
OBJC4=${OBJC4:-$MACHORUN/vendor/objc4/runtime}

if [ "$ARCH" != x86_64 ]; then
    echo "stage_fe_sysroot_x86: this sibling is the x86_64 Linux path; arm64 keeps full/foundation/stage_fe_sysroot.sh" >&2
    exit 2
fi
case "$SYS" in
    *-x86_64) ;;
    *)
        echo "stage_fe_sysroot_x86: refusing to write unsuffixed sysroot $SYS (arm64 tree must stay)" >&2
        exit 2
        ;;
esac
[ "$SYS" != "$ARM_SYS" ] || {
    echo "stage_fe_sysroot_x86: SYS equals the arm64 sysroot; refuse" >&2
    exit 2
}

stage_absent() {
    local rel=$1 src=$2 label=$3
    if [ -e "$SYS/usr/include/$rel" ]; then
        echo "  REFUSED (already present, would shadow): $rel" >&2
        return 0
    fi
    [ -f "$src/$rel" ] || return 0
    mkdir -p "$(dirname "$SYS/usr/include/$rel")"
    cp "$src/$rel" "$SYS/usr/include/$rel"
    echo "  + $rel   [$label]"
}

copy_if_x86_macho() {
    local src=$1 dest=$2
    [ -f "$src" ] || return 0
    if phase2_is_arm64_macho "$src"; then
        echo "  skip arm64 Mach-O $(basename "$src") (would poison the x86 sysroot)" >&2
        return 0
    fi
    if ! phase2_is_x86_macho "$src"; then
        echo "  skip non-x86 $(basename "$src"): $(file -b "$src")" >&2
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
}

rm -rf "$SYS"
mkdir -p "$SYS/usr/include" "$SYS/usr/lib/swift"
phase2_ensure_sdk_settings "$SYS"

echo "== headers from machorun/sdk (not Xcode)"
cp -R "$MACHORUN/sdk/usr/include/." "$SYS/usr/include/"

echo "== x86_64 dylibs from machorun/darwin (arm64 copies refused)"
if [ -d "$MACHORUN/darwin/usr/lib" ]; then
    while IFS= read -r -d '' dylib; do
        rel=${dylib#"$MACHORUN/darwin/usr/lib/"}
        copy_if_x86_macho "$dylib" "$SYS/usr/lib/$rel"
    done < <(find "$MACHORUN/darwin/usr/lib" -type f \( -name '*.dylib' -o -name '*.so' \) -print0)
fi

echo "== .tbd from x86 darwin dylibs via machorun gen_tbd (never copy arm64 tbds)"
# find -type f skipped gen_tbd's libobjc.tbd symlink; -lobjc needs that name.
phase2_stage_darwin_tbds_into_sysroot "$SYS" "$MACHORUN" || {
    echo "stage_fe_sysroot_x86: darwin .tbd stage failed (run machorun/scripts/gen_tbd.sh first)" >&2
    exit 2
}

artifacts=$W/swiftcore-macho/artifacts
x86_core=$artifacts/swift-macosx/x86_64/libswiftCore.dylib
x86_mod=$artifacts/swift-macosx/Swift.swiftmodule/x86_64-apple-macos.swiftmodule
x86_bf_mod=$artifacts/swift-macosx/_Builtin_float.swiftmodule/x86_64-apple-macos.swiftmodule

echo "== ObjectiveC Clang module"
mkdir -p "$SYS/usr/include/objc"
for h in NSObject.h NSObjCRuntime.h Protocol.h; do
    [ -f "$OBJC4/$h" ] && cp "$OBJC4/$h" "$SYS/usr/include/objc/$h"
done
cat > "$SYS/usr/include/module.modulemap" <<'EOF'
module ObjectiveC [system] {
  header "objc/objc.h"
  header "objc/objc-api.h"
  header "objc/runtime.h"
  header "objc/message.h"
  export *
  module NSObject  { header "objc/NSObject.h"      export * }
  module Protocol  { header "objc/Protocol.h"      export * }
  module Runtime   { header "objc/NSObjCRuntime.h" export * }
}
EOF
if [ -f "$OBJC4/Module/ObjectiveC.apinotes" ]; then
    cp "$OBJC4/Module/ObjectiveC.apinotes" "$SYS/usr/include/ObjectiveC.apinotes"
fi
bash "$W/full/foundation/stage_objc_platform_headers.sh" "$SYS/usr/include"

echo "== sdk-gaps (file-by-file, refuse shadowing -- same rule as the Darwin recipe)"
gaps=$W/full/sdk-gaps/usr/include
if [ -d "$gaps" ]; then
    while IFS= read -r -d '' gap; do
        rel=${gap#"$gaps"/}
        stage_absent "$rel" "$gaps" "sdk-gap"
    done < <(find "$gaps" -type f -print0)
fi

echo "== measurement headers (shared list; stage_absent from arm64 sysroot_fe4)"
phase2_stage_measurement_headers_from_arm "$SYS" "$ARM_SYS"
fe_sysroot_append_vm_copy "$SYS/usr/include/mach/vm_map.h"

if [ -f "$ARM_SYS/usr/include/_DarwinFoundation2.apinotes" ]; then
    cp "$ARM_SYS/usr/include/_DarwinFoundation2.apinotes" \
        "$SYS/usr/include/_DarwinFoundation2.apinotes"
fi

# ORDER: base module.modulemap (ObjectiveC) then the Darwin family. The
# generator appends extern module lines; running it first would lose Darwin.
echo "== Darwin family Clang modulemaps (underlying Objective-C module Darwin)"
phase2_install_darwin_modulemaps \
    "$SYS" "$ARM_SYS" "$MACHORUN/scripts/gen_darwin_modulemap.py" \
    || echo "  (Darwin family incomplete; FE will fail with 'underlying Objective-C module Darwin not found' or a missing header named by Darwin_C.modulemap)"

echo "== textual Darwin overlays from the arm64 sysroot, if any (no dylibs, no arm64 .swiftmodule slices)"
OVERLAYS_COPIED=0
if [ -d "$ARM_SYS/usr/lib/swift" ]; then
    while IFS= read -r -d '' item; do
        rel=${item#"$ARM_SYS/usr/lib/swift/"}
        case "$rel" in
            *.dylib|*.tbd|*.a) continue ;;
            */arm64-apple-macos.*|arm64-apple-macos.*) continue ;;
            */arm64e-apple-macos.*|arm64e-apple-macos.*) continue ;;
            os.swiftmodule|os.swiftmodule/*)
                # Apple's os overlay @_exported-imports Clang os.*, which this
                # sysroot does not declare. FE uses full/foundation/os-module.
                continue
                ;;
        esac
        case "$(file -b "$item")" in
            Mach-O*) continue ;;
        esac
        dest="$SYS/usr/lib/swift/$rel"
        mkdir -p "$(dirname "$dest")"
        cp -a "$item" "$dest"
        OVERLAYS_COPIED=$((OVERLAYS_COPIED + 1))
    done < <(find "$ARM_SYS/usr/lib/swift" -type f -print0)
fi

echo "== x86 Swift runtime into $SYS/usr/lib/swift (toolchain layout; not left only in artifacts/)"
mkdir -p "$SYS/usr/lib/swift"
if [ -f "$x86_core" ] && phase2_is_x86_macho "$x86_core"; then
    cp -f "$x86_core" "$SYS/usr/lib/swift/libswiftCore.dylib"
    echo "  + usr/lib/swift/libswiftCore.dylib (x86_64)"
else
    echo "  no x86_64 libswiftCore.dylib in swiftcore-macho/artifacts (measured wall)"
fi
if [ -f "$x86_mod" ]; then
    mkdir -p "$SYS/usr/lib/swift/Swift.swiftmodule"
    for f in "$artifacts/swift-macosx/Swift.swiftmodule"/x86_64-apple-macos.*; do
        [ -f "$f" ] || continue
        cp -f "$f" "$SYS/usr/lib/swift/Swift.swiftmodule/$(basename "$f")"
    done
    echo "  + usr/lib/swift/Swift.swiftmodule/x86_64-apple-macos.*"
else
    echo "  no x86_64-apple-macos Swift.swiftmodule (arm64 slice is not a substitute)"
fi
if [ -f "$x86_bf_mod" ]; then
    mkdir -p "$SYS/usr/lib/swift/_Builtin_float.swiftmodule"
    for f in "$artifacts/swift-macosx/_Builtin_float.swiftmodule"/x86_64-apple-macos.*; do
        [ -f "$f" ] || continue
        cp -f "$f" "$SYS/usr/lib/swift/_Builtin_float.swiftmodule/$(basename "$f")"
    done
    echo "  + usr/lib/swift/_Builtin_float.swiftmodule/x86_64-apple-macos.*"
else
    echo "  no x86_64-apple-macos _Builtin_float.swiftmodule"
fi

echo "== overlay .tbd from x86 overlay dylibs (never copy arm64 usr/lib/swift tbds)"
phase2_stage_overlay_tbds_into_sysroot "$SYS"
echo "  usr/lib/swift tbds: $(find "$SYS/usr/lib/swift" -maxdepth 1 -name '*.tbd' | wc -l | tr -d ' ')"

empty_tbd=$(find "$SYS" -name '*.tbd' -size 0 -print -quit)
[ -z "$empty_tbd" ] || {
    echo "stage_fe_sysroot_x86: empty .tbd is a linker lie: $empty_tbd" >&2
    exit 2
}

overlay_if=$(phase2_sysroot_overlay_if "$ARM_SYS" "$artifacts" || true)
dmap_for_stamp=$(phase2_sysroot_dmap_input "$ARM_SYS")
phase2_write_sysroot_stamp "$SYS/$PHASE2_SYSROOT_STAMP" \
    "$x86_core" "$x86_mod" "$x86_bf_mod" \
    "$MACHORUN/scripts/gen_darwin_modulemap.py" \
    "${overlay_if:-}" \
    "$dmap_for_stamp" \
    "$FE_SYSROOT_MEASUREMENT_HEADERS_FILE"
echo "  wrote $SYS/$PHASE2_SYSROOT_STAMP (input-keyed; restage when these shas change)"

echo "== $SYS"
echo "  usr/include : $(find "$SYS/usr/include" -type f | wc -l | tr -d ' ') headers"
echo "  modulemaps  : $(find "$SYS/usr/include" -maxdepth 1 -name '*.modulemap' | wc -l | tr -d ' ')"
echo "  textual overlays copied from arm64 sysroot: $OVERLAYS_COPIED"

# Overlay SDK copies $SYS (unexpanded Darwin.modulemap, same bytes as main).
# VM-only expansions (overlay-darwin Intel math.h, ioctl stub, artifact
# Darwin overlays, SwiftOnone) land on the sibling snapshot.
echo "== FE clang sysroot (expanded Darwin.modulemap; overlay SDK is not this tree)"
phase2_stage_fe_clang_sysroot "$SYS" "$W" || true
fe_clang=$(phase2_fe_clang_sysroot "$SYS")
if [ -f "$fe_clang/usr/include/Darwin.modulemap" ]; then
    echo "  FE clang Darwin.modulemap: $(wc -l < "$fe_clang/usr/include/Darwin.modulemap" | tr -d ' ') lines at $fe_clang"
fi

if [ ! -d "$SYS/usr/lib/swift/Darwin.swiftmodule" ] \
    && [ ! -f "$SYS/usr/lib/swift/Darwin.swiftinterface" ]; then
    if [ -d "$fe_clang/usr/lib/swift/Darwin.swiftmodule" ] \
        || [ -f "$fe_clang/usr/lib/swift/Darwin.swiftinterface" ]; then
        echo "  Darwin overlays: VM-only on $fe_clang (overlay-copied SYS matches main)"
    else
        echo "  CANNOT_STAGE_XCODE_DARWIN_OVERLAYS: no Darwin.swiftmodule/swiftinterface in $ARM_SYS (Linux cannot materialize Apple's overlay interfaces)"
        exit 3
    fi
fi
if [ -e "$SYS/usr/lib/libobjc.tbd" ] && phase2_tbd_is_x86_target "$SYS/usr/lib/libobjc.tbd"; then
    echo "  libobjc.tbd: x86_64-macos (alias for gen_tbd libobjc.A.tbd)"
else
    echo "  libobjc.tbd: ABSENT or not x86_64-macos (-lobjc will not resolve render_full.o)"
fi
if [ -d "$SYS/usr/lib/swift/Darwin.swiftmodule" ] \
    || [ -f "$SYS/usr/lib/swift/Darwin.swiftinterface" ]; then
    echo "  Darwin overlays: present (textual, from $ARM_SYS)"
fi
phase2_report_darwin_overlay_path "$SYS" "$ARM_SYS"
if [ -f "$SYS/usr/include/Darwin.modulemap" ]; then
    miss=$(phase2_darwin_modulemap_missing_headers "$SYS" || true)
    if [ -n "$miss" ]; then
        echo "  Darwin.modulemap: present but headers missing: $miss"
    else
        echo "  Darwin.modulemap: present; all header paths resolve"
        echo "  _modules shims: $(find "$SYS/usr/include/_modules" -type f 2>/dev/null | wc -l | tr -d ' ')"
    fi
else
    echo "  Darwin.modulemap: ABSENT (underlying Objective-C module Darwin will not be found)"
fi
meas_miss=$(phase2_measurement_headers_missing "$SYS" || true)
if [ -n "$meas_miss" ]; then
    echo "  measurement headers missing: $meas_miss"
else
    echo "  measurement headers: all present"
fi
if [ -f "$SYS/usr/lib/swift/libswiftCore.dylib" ]; then
    echo "  libswiftCore: $(phase2_macho_cpu "$SYS/usr/lib/swift/libswiftCore.dylib") at usr/lib/swift/libswiftCore.dylib"
fi
