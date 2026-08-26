#!/bin/bash
# Build Apple's objc4 as a Mach-O /usr/lib/libobjc.A.dylib -- on Linux.
#
# The whole point of this script is that it is a NATIVE build: the target is
# arm64-apple-macos11, so TARGET_OS_MAC is 1, __arm64__ is predefined, BOOL is
# bool, and the assembler and inline-asm dialects are Apple's own. Every one of
# those was a patch in the ELF port. Here they are the defaults.
#
# Sources come from vendor/objc4 (PRISTINE Apple drop) with patches-macho/*
# applied to a copy at build/objc4-macho-src. patches-macho/ is the honest
# count of what a Mach-O build still needs.
#
#   SDK        Apple's macOS SDK headers (mounted at /sdk/MacOSX.sdk here).
#              Apple builds objc4 against their *internal* SDK; the public one
#              is missing ~20 private headers, which is what vendor/objc4-priv
#              supplies. Those are not patches to objc4 -- objc4's source is
#              unchanged -- they are the parts of the SDK we do not have.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SDK="${OBJC4_SDK:-/sdk/MacOSX.sdk}"
SRC="$ROOT/build/objc4-macho-src"
GEN="$ROOT/build/objc4-macho-gen"
OBJ="$ROOT/build/objc4-macho-obj"
OUT="$ROOT/darwin/usr/lib"
TARGET="${DARWIN_TARGET:-arm64-apple-macos11}"

CLANG="${DARWIN_CLANG:-clang}"
LD64="${LD64:-ld64.lld-18}"

[ -d "$SDK" ] || { echo "build_objc4: no SDK at $SDK" >&2; exit 1; }

# ---------------------------------------------------------------- source copy
rm -rf "$SRC"
mkdir -p "$SRC"
cp -R "$ROOT/vendor/objc4/." "$SRC/"

shopt -s nullglob
PATCHES=("$ROOT/patches-macho"/*.patch)
shopt -u nullglob
for p in "${PATCHES[@]}"; do
    echo "== patch: $(basename "$p")"
    patch -p1 -d "$SRC" --no-backup-if-mismatch < "$p" >/dev/null
done
echo "== patches applied: ${#PATCHES[@]}"

# ------------------------------------------------------------ include tree
# objc4 says <objc/runtime.h>; the headers live flat in runtime/. Apple's
# Xcode project supplies a VFS overlay (vendor/objc4/objc-vfs-overlay); we use
# a symlink tree, exactly as the ELF port does. Not a source change.
rm -rf "$GEN/include"
mkdir -p "$GEN/include/objc"
for h in "$SRC"/runtime/*.h; do
    ln -sf "$h" "$GEN/include/objc/$(basename "$h")"
done
[ -f "$SRC/runtime/OldClasses.subproj/List.h" ] && \
    ln -sf "$SRC/runtime/OldClasses.subproj/List.h" "$GEN/include/objc/List.h"

mkdir -p "$OBJ" "$OUT"

# ---------------------------------------------------------------------- flags
# Compare with ~/objc4-linux/scripts/flags.sh. Gone from that list:
#   -D__arm64__=1 -D__arm64=1   clang predefines both for an Apple arm64 target
#   -D_GNU_SOURCE               not a glibc build
#   -DOBJC4LINUX=1              no Linux branch to select
#   -include darwin-cdefs.h     Darwin's own <sys/cdefs.h> is the real one
INC="-I$GEN/include -I$SRC/runtime -I$ROOT/vendor/objc4-priv"
# OBJC_MACHORUN selects the wide-VA isa layout in patches-macho/0001. It is
# the only build knob this port adds, and it names a property of the HOST
# (a 48-bit user address space), not of the file format.
DEFS="-DNDEBUG -D__OBJC2__=1 -DOBJC_DECLARE_SYMBOLS=1 -DOBJC_MACHORUN=1"
WARN="-Wno-unused-parameter -Wno-unknown-pragmas -Wno-deprecated-declarations
      -Wno-gcc-compat -Wno-unused-function -Wno-unknown-warning-option
      -Wno-unknown-attributes -Wno-ignored-attributes -Wno-nullability-completeness"
COMMON="-target $TARGET -isysroot $SDK -fPIC -fno-strict-aliasing -fblocks
        -fno-exceptions -fno-rtti -fvisibility=hidden -funwind-tables -Os -g0"

CXXFLAGS="-std=gnu++20 $COMMON $DEFS $INC $WARN"
CFLAGS="-std=gnu11 $COMMON $DEFS $INC $WARN"
OBJCXX="-x objective-c++ -fobjc-runtime=macosx-10.15 $CXXFLAGS"
OBJC="-x objective-c -fobjc-runtime=macosx-10.15 $CFLAGS"
ASFLAGS="-x assembler-with-cpp -target $TARGET -isysroot $SDK $DEFS $INC"

# ---------------------------------------------------------------------- build
OBJS=()
fail=0
compile() { # compile <file> <flags...>
    local f="$1"; shift
    local o="$OBJ/$(echo "${f#$SRC/}" | tr '/' '_').o"
    if $CLANG "$@" -c "$f" -o "$o" 2> "$o.log"; then
        OBJS+=("$o")
        if [ -s "$o.log" ]; then echo "   warn $(basename "$f")"; fi
    else
        echo "!! FAIL $(basename "$f")"
        sed -n '1,25p' "$o.log"
        fail=$((fail+1))
    fi
}

echo "== compiling (target $TARGET, sysroot $SDK)"
for f in "$SRC"/runtime/*.mm; do
    case "$f" in *dummy-library-mac-i386*) continue ;; esac
    compile "$f" $OBJCXX
done
for f in "$SRC"/runtime/*.m; do
    compile "$f" $OBJC
done
# Apple's own arm64 assembly, assembled by clang's integrated assembler in
# DARWIN dialect. No translation step, no gen-elf-asm.py.
compile "$SRC/runtime/Messengers.subproj/objc-msg-arm64.s" $ASFLAGS
compile "$SRC/runtime/retain-release-helpers-arm64.s"      $ASFLAGS
compile "$SRC/runtime/objc-sel-table.s"                    $ASFLAGS

echo "== compiled ${#OBJS[@]} objects, $fail failures"
[ "$fail" = 0 ] || { echo "build_objc4: compile stage failed"; exit 1; }

# ----------------------------------------------------------------------- link
echo "== linking $OUT/libobjc.A.dylib"
$LD64 -dylib -arch arm64 -platform_version macos 11.0 11.0 \
      -install_name /usr/lib/libobjc.A.dylib \
      -undefined dynamic_lookup \
      -o "$OUT/libobjc.A.dylib" "${OBJS[@]}" 2>&1 | sed -n '1,40p'

[ -f "$OUT/libobjc.A.dylib" ] || { echo "build_objc4: link failed"; exit 1; }
echo "   -> $OUT/libobjc.A.dylib"
file "$OUT/libobjc.A.dylib"
