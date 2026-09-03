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

echo "== headers from machorun/sdk (not Xcode)"
cp -R "$MACHORUN/sdk/usr/include/." "$SYS/usr/include/"

echo "== x86_64 dylibs from machorun/darwin (arm64 copies refused)"
if [ -d "$MACHORUN/darwin/usr/lib" ]; then
    while IFS= read -r -d '' dylib; do
        rel=${dylib#"$MACHORUN/darwin/usr/lib/"}
        copy_if_x86_macho "$dylib" "$SYS/usr/lib/$rel"
    done < <(find "$MACHORUN/darwin/usr/lib" -type f \( -name '*.dylib' -o -name '*.so' \) -print0)
fi

echo "== .tbd from machorun/sdk (generated against the x86 loader + dylibs)"
if [ -d "$MACHORUN/sdk/usr/lib" ]; then
    while IFS= read -r -d '' tbd; do
        [ -s "$tbd" ] || {
            echo "stage_fe_sysroot_x86: empty .tbd is a linker lie: $tbd" >&2
            exit 2
        }
        cp -f "$tbd" "$SYS/usr/lib/$(basename "$tbd")"
    done < <(find "$MACHORUN/sdk/usr/lib" -maxdepth 1 -type f -name '*.tbd' -print0)
    if [ -d "$MACHORUN/sdk/usr/lib/swift" ]; then
        mkdir -p "$SYS/usr/lib/swift"
        while IFS= read -r -d '' tbd; do
            [ -s "$tbd" ] || {
                echo "stage_fe_sysroot_x86: empty .tbd is a linker lie: $tbd" >&2
                exit 2
            }
            cp -f "$tbd" "$SYS/usr/lib/swift/$(basename "$tbd")"
        done < <(find "$MACHORUN/sdk/usr/lib/swift" -maxdepth 1 -type f -name '*.tbd' -print0 2>/dev/null || true)
    fi
fi

echo "== Swift.swiftmodule: only an x86_64-apple-macos slice, never the arm64 one under this name"
artifacts=$W/swiftcore-macho/artifacts
x86_core=$artifacts/swift-macosx/x86_64/libswiftCore.dylib
x86_mod=$artifacts/swift-macosx/Swift.swiftmodule/x86_64-apple-macos.swiftmodule
if [ -f "$x86_core" ] && phase2_is_x86_macho "$x86_core"; then
    mkdir -p "$SYS/usr/lib/swift"
    cp -f "$x86_core" "$SYS/usr/lib/swift/libswiftCore.dylib"
    echo "  + libswiftCore.dylib (x86_64)"
else
    echo "  no x86_64 libswiftCore.dylib in swiftcore-macho/artifacts (measured wall)"
fi
if [ -f "$x86_mod" ]; then
    mkdir -p "$SYS/usr/lib/swift/Swift.swiftmodule"
    for f in "$artifacts/swift-macosx/Swift.swiftmodule"/x86_64-apple-macos.*; do
        [ -f "$f" ] || continue
        cp -f "$f" "$SYS/usr/lib/swift/Swift.swiftmodule/$(basename "$f")"
    done
    echo "  + Swift.swiftmodule/x86_64-apple-macos.*"
else
    echo "  no x86_64-apple-macos.swiftmodule (arm64 slice is not a substitute)"
fi

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

echo "== textual Darwin overlays from the arm64 sysroot, if any (no dylibs, no arm64 .swiftmodule slices)"
OVERLAYS_COPIED=0
if [ -d "$ARM_SYS/usr/lib/swift" ]; then
    while IFS= read -r -d '' item; do
        rel=${item#"$ARM_SYS/usr/lib/swift/"}
        case "$rel" in
            *.dylib|*.tbd|*.a) continue ;;
            */arm64-apple-macos.*|arm64-apple-macos.*) continue ;;
            */arm64e-apple-macos.*|arm64e-apple-macos.*) continue ;;
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
if [ -f "$ARM_SYS/usr/include/_DarwinFoundation2.apinotes" ]; then
    cp "$ARM_SYS/usr/include/_DarwinFoundation2.apinotes" \
        "$SYS/usr/include/_DarwinFoundation2.apinotes"
    OVERLAYS_COPIED=$((OVERLAYS_COPIED + 1))
fi

if ! grep -q 'vm_copy' "$SYS/usr/include/mach/vm_map.h" 2>/dev/null; then
    cat >> "$SYS/usr/include/mach/vm_map.h" <<'EOF'
/* APPENDED by scripts/x86/stage_fe_sysroot.sh -- MEASUREMENT ONLY. */
extern kern_return_t vm_copy(vm_map_t target_task, vm_address_t source_address,
                             vm_size_t size, vm_address_t dest_address);
EOF
fi

empty_tbd=$(find "$SYS" -name '*.tbd' -size 0 -print -quit)
[ -z "$empty_tbd" ] || {
    echo "stage_fe_sysroot_x86: empty .tbd is a linker lie: $empty_tbd" >&2
    exit 2
}

echo "== $SYS"
echo "  usr/include : $(find "$SYS/usr/include" -type f | wc -l | tr -d ' ') headers"
echo "  textual overlays copied from arm64 sysroot: $OVERLAYS_COPIED"
if [ ! -d "$SYS/usr/lib/swift/Darwin.swiftmodule" ] \
    && [ ! -f "$SYS/usr/lib/swift/Darwin.swiftinterface" ]; then
    echo "  CANNOT_STAGE_XCODE_DARWIN_OVERLAYS: no Darwin.swiftmodule/swiftinterface in $ARM_SYS (Linux cannot materialize Apple's overlay interfaces)"
    exit 3
fi
echo "  Darwin overlays: present (textual, from $ARM_SYS)"
