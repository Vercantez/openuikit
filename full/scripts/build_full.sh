#!/bin/bash
# build_full.sh -- build the FULL OpenUIKit module (not the vendored slice) as
# arm64-apple-macos Mach-O on Linux, plus a Foundation-free scene renderer.
#
# ~/uikit IS NEVER EDITED AND NEVER COPIED. It is bind-mounted read-only at
# /uikit and compiled in place. Exactly two files are not ~/uikit's:
#   full/shims/FoundationNames.swift  OpenUIKit's own pre-M15 declarations of
#                                     IndexPath/NSRange/TimeInterval, restored
#                                     (provenance in that file's header)
#   full/driver/main.swift            replaces openrender's two Foundation-using
#                                     files; SceneBuilder.swift is compiled verbatim
#
# QUARTZ IS BUILT FROM ~/uikit's OWN CQuartz, not machorun's staged libquartz.
# Measured reason: machorun's copy is an older sync of ~/quartz and does not
# export the straight-alpha codec entry points (QZImageDecodeRGBA,
# QZImageFreeRGBA, QZImageEncodePNG, QZImageEncodeJPEG) that
# Sources/OpenUIKit/ImageCodec.swift calls. Building the version OpenUIKit
# expects is what keeps the header and the implementation in step.
#
# Runs in swift-macho-spike:noble.  /w = ~/swift-macho-linux, /uikit = ~/uikit:ro
set -euo pipefail
W=/w
UIKIT=/uikit
SYS=$W/scratch/sysroot_full            # private sysroot copy, quartz removed
OUT=$W/build/full
ROOTDIR=$W/scratch/mrroot_full         # guest root for this renderer
MC=$W/scratch/modcache_full
mkdir -p "$OUT" "$MC"

# ---- private sysroot -------------------------------------------------------
# The shared sysroot carries machorun's OLD quartz headers under
# usr/include/quartz with a modulemap naming the module `Quartz`. Both the
# headers and the module name are wrong for this build, and a second modulemap
# over the same headers would be ambiguous to clang -- so the private copy
# simply drops them and the CQuartz module comes from ~/uikit's own
# Sources/CQuartz/include/module.modulemap, unmodified.
if [ ! -d "$SYS" ]; then
    echo "== staging private sysroot (machorun's old quartz removed)"
    cp -a "$W/scratch/sysroot" "$SYS"
    rm -rf "$SYS/usr/include/quartz"
fi

SWIFTC=(swiftc -target arm64-apple-macos13.0 -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -wmo
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0 -syslibroot "$SYS" -rpath /usr/lib/swift)
CC=(clang-18 -target arm64-apple-macos13.0 -isysroot "$SYS" -O2)

# ---- guest root ------------------------------------------------------------
if [ ! -d "$ROOTDIR" ]; then
    echo "== staging guest root"
    mkdir -p "$ROOTDIR/darwin/usr/lib/swift"
    for d in "$W/scratch/mrroot/darwin/usr/lib/"*.dylib; do
        # NOT libquartz: machorun's is an older sync of ~/quartz and is rebuilt
        # below from ~/uikit's CQuartz. Copying it here would satisfy the
        # freshness check and silently link the guest against the old ABI.
        case "$(basename "$d")" in libquartz.dylib) continue ;; esac
        cp "$d" "$ROOTDIR/darwin/usr/lib/"
    done
    cp "$W/scratch/mrroot/darwin/usr/lib/swift/"*.dylib "$ROOTDIR/darwin/usr/lib/swift/"
    cp -R "$W/scratch/mrroot/darwin/System" "$ROOTDIR/darwin/" 2>/dev/null || true
    cp "$W/scratch/mrroot/machorun" "$ROOTDIR/machorun"
fi
SWIFTCOMPAT=$ROOTDIR/darwin/usr/lib/libswiftcompat.dylib

# ---- libSystem umbrella, extended for _Concurrency -------------------------
# The full module carries @MainActor (real UIKit does), so the guest loads
# libswift_Concurrency.dylib, which imports 22 symbols our userland lacks --
# measured with nm against this guest root, listed in full/shims/concpatch.c.
#
# The umbrella pattern is docs/RUNTIME.md §4's, applied one layer further out.
# machorun's libSystem.B.dylib is ALREADY an umbrella over libSystem.real.dylib,
# and machorun searches a bound image's reexport deps but cannot chase
# per-symbol trie reexports -- so the new symbols cannot be added by a sibling
# dylib, they have to be inside something libSystem.B.dylib reexports or
# defines. This renames the existing umbrella to a third install name and wraps
# it, leaving machorun's own dylibs untouched on disk.
NEED_UMBRELLA=0
[ -f "$ROOTDIR/.conc_umbrella" ] || NEED_UMBRELLA=1
for src in "$W/full/shims/concpatch.c" "$W/full/shims/conccxx.cpp" "$W/full/shims/lowheap.c"; do
    [ "$src" -nt "$ROOTDIR/.conc_umbrella" ] && NEED_UMBRELLA=1
done
if [ "$NEED_UMBRELLA" = 1 ]; then
    echo "== libSystem umbrella + concpatch (22 _Concurrency symbols)"
    LIB=$ROOTDIR/darwin/usr/lib
    # The inner name is EXACTLY as long as "/usr/lib/libSystem.B.dylib":
    # set_id_dylib.pl rewrites LC_ID_DYLIB in place and requires the new name to
    # fit the existing command, and llvm-install-name-tool cannot touch this
    # file at all (it refuses LC_REEXPORT_DYLIB, cmd 0x8000001f).
    if [ ! -f "$LIB/libSysBaseConc.dylib" ]; then
        cp "$LIB/libSystem.B.dylib" "$LIB/libSysBaseConc.dylib"
        perl "$W/scripts/set_id_dylib.pl" "$LIB/libSysBaseConc.dylib" /usr/lib/libSysBaseConc.dylib
    fi
    "${CC[@]}" -O1 -c -o "$OUT/concpatch.o" "$W/full/shims/concpatch.c"
    ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0 \
        -syslibroot "$ROOTDIR/darwin" -dylib \
        -install_name /usr/lib/libSystem.B.dylib -undefined dynamic_lookup \
        -o "$OUT/libSystem.B.conc.dylib" "$OUT/concpatch.o" \
        -reexport_library "$LIB/libSysBaseConc.dylib"
    cp "$OUT/libSystem.B.conc.dylib" "$LIB/libSystem.B.dylib"

    # libc++ side: __cxa_pure_virtual and the typed operator new bind against
    # libc++, not libSystem (dyld_info -fixups), and two-level binding means a
    # definition in the wrong library is invisible. Same umbrella trick, same
    # same-length install-name constraint.
    if [ ! -f "$LIB/libcxxbc.dylib" ]; then
        cp "$LIB/libc++.1.dylib" "$LIB/libcxxbc.dylib"
        perl "$W/scripts/set_id_dylib.pl" "$LIB/libcxxbc.dylib" /usr/lib/libcxxbc.dylib
    fi
    clang-18 -target arm64-apple-macos13.0 -isysroot "$SYS" -O1 -std=c++17 \
        -fno-exceptions -fno-rtti -nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1 \
        -c -o "$OUT/conccxx.o" "$W/full/shims/conccxx.cpp"
    ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0 \
        -syslibroot "$ROOTDIR/darwin" -dylib \
        -install_name /usr/lib/libc++.1.dylib -undefined dynamic_lookup \
        -o "$OUT/libc++.1.conc.dylib" "$OUT/conccxx.o" \
        -reexport_library "$LIB/libcxxbc.dylib"
    cp "$OUT/libc++.1.conc.dylib" "$LIB/libc++.1.dylib"

    # A SECOND libSystem, identical plus full/shims/lowheap.c, kept alongside
    # rather than installed. run_suite.sh --lowheap swaps it in to MEASURE
    # whether the remaining suite failures are all the one heap-placement bug;
    # the default guest root never sees it.
    "${CC[@]}" -O1 -c -o "$OUT/lowheap.o" "$W/full/shims/lowheap.c"
    ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0 \
        -syslibroot "$ROOTDIR/darwin" -dylib \
        -install_name /usr/lib/libSystem.B.dylib -undefined dynamic_lookup \
        -o "$LIB/libSystem.B.lowheap.dylib" "$OUT/concpatch.o" "$OUT/lowheap.o" \
        -reexport_library "$LIB/libSysBaseConc.dylib"

    touch "$ROOTDIR/.conc_umbrella"
    echo "   -> libSystem.B.dylib + libc++.1.dylib re-umbrella'd with the 22 symbols"
    echo "   -> libSystem.B.lowheap.dylib built alongside (measurement, not installed)"
fi

# ---- libquartz, from ~/uikit's CQuartz -------------------------------------
# Flags mirror machorun/scripts/build_quartz.sh exactly (-fno-exceptions
# -fno-rtti because machorun has no unwinder for compact __unwind_info; stock
# LLVM-18 libc++ headers with the same three -D flags; clang's DEFAULT floating
# point mode, so the pixel diff measures the loader and not -ffast-math).
QOBJ=$OUT/quartz-obj
if [ ! -f "$ROOTDIR/darwin/usr/lib/libquartz.dylib" ] || [ -n "${QUARTZ_REBUILD:-}" ]; then
    echo "== libquartz from /uikit/Sources/CQuartz ($(ls "$UIKIT"/Sources/CQuartz/*.cpp | wc -l) TUs)"
    mkdir -p "$QOBJ"
    QINC="-I$UIKIT/Sources/CQuartz/include -I$UIKIT/Sources/CQuartz"
    QCXX=(-std=gnu++17 -fno-exceptions -fno-rtti -fPIC -Os -g0 -DNDEBUG
          -Wno-unused-parameter -Wno-unused-function
          -nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1
          -D__STDC_WANT_LIB_EXT1__=0
          -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_NONE
          "-D_LIBCPP_VERBOSE_ABORT(...)=__builtin_trap()")
    QOBJS=()
    for f in "$UIKIT"/Sources/CQuartz/*.cpp; do
        o="$QOBJ/$(basename "$f" .cpp).o"
        clang-18 -target arm64-apple-macos13.0 -isysroot "$SYS" "${QCXX[@]}" $QINC -c "$f" -o "$o"
        QOBJS+=("$o")
    done
    # -syslibroot the GUEST root: our libSystem.B/libc++.1 are umbrellas that
    # LC_REEXPORT_DYLIB /usr/lib/*.real.dylib, and the linker has to be able to
    # resolve those install names to files.
    ld64.lld-18 -dylib -arch arm64 -platform_version macos 13.0 13.0 \
        -syslibroot "$ROOTDIR/darwin" \
        -install_name /usr/lib/libquartz.dylib -undefined dynamic_lookup \
        -o "$ROOTDIR/darwin/usr/lib/libquartz.dylib" "${QOBJS[@]}" \
        "$ROOTDIR/darwin/usr/lib/libc++.1.dylib" "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib"
    echo "   -> libquartz.dylib ($(nm -gU "$ROOTDIR/darwin/usr/lib/libquartz.dylib" 2>/dev/null | grep -c QZ) QZ exports)"
fi
# A .tbd is not needed: link the guest directly against the dylib we just built.
QUARTZLIB=$ROOTDIR/darwin/usr/lib/libquartz.dylib

# ---- C targets: compiled from ~/uikit's own sources ------------------------
echo "== C targets (CPortableIO, CSTBTrueType)"
"${CC[@]}" -I"$UIKIT/Sources/CPortableIO/include" -c \
    -o "$OUT/cportableio.o" "$UIKIT/Sources/CPortableIO/io.c"
"${CC[@]}" -I"$UIKIT/Sources/CSTBTrueType/include" -c \
    -o "$OUT/cstbtruetype.o" "$UIKIT/Sources/CSTBTrueType/stb_impl.c"

# ~/uikit has no modulemap for these two (SPM generates one); write them into a
# private include dir so ~/uikit stays untouched.
mkdir -p "$OUT/inc/CPortableIO" "$OUT/inc/CSTBTrueType"
cp "$UIKIT/Sources/CPortableIO/include/"*.h "$OUT/inc/CPortableIO/"
cp "$UIKIT/Sources/CSTBTrueType/include/"*.h "$OUT/inc/CSTBTrueType/"
cat >"$OUT/inc/CPortableIO/module.modulemap" <<'EOF'
module CPortableIO { header "cportableio.h" export * }
EOF
cat >"$OUT/inc/CSTBTrueType/module.modulemap" <<'EOF'
module CSTBTrueType { header "stb_truetype.h" export * }
EOF
CINC=(-Xcc -I"$OUT/inc/CPortableIO" -Xcc -I"$OUT/inc/CSTBTrueType"
      -Xcc -I"$UIKIT/Sources/CQuartz/include")

# ---- OpenCoreGraphics ------------------------------------------------------
echo "== OpenCoreGraphics ($(ls "$UIKIT"/Sources/OpenCoreGraphics/*.swift | wc -l) files, verbatim)"
"${SWIFTC[@]}" "${CINC[@]}" -module-name OpenCoreGraphics \
    -emit-object -emit-module -emit-module-path "$OUT/OpenCoreGraphics.swiftmodule" \
    -o "$OUT/opencoregraphics.o" "$UIKIT"/Sources/OpenCoreGraphics/*.swift

# ---- OpenUIKit (+ the restored Foundation names) ---------------------------
UIKIT_SRCS=()
while IFS= read -r f; do UIKIT_SRCS+=("$f"); done < <(find "$UIKIT/Sources/OpenUIKit" -name '*.swift' | sort)
echo "== OpenUIKit (${#UIKIT_SRCS[@]} files verbatim, incl. AutoLayout/ + FoundationNames.swift)"
"${SWIFTC[@]}" "${CINC[@]}" -I "$OUT" -module-name OpenUIKit \
    -emit-object -emit-module -emit-module-path "$OUT/OpenUIKit.swiftmodule" \
    -o "$OUT/openuikit.o" \
    "${UIKIT_SRCS[@]}" "$W/full/shims/FoundationNames.swift"

# ---- the renderer: ~/uikit's SceneBuilder verbatim + our main ---------------
echo "== renderer (SceneBuilder.swift verbatim + full/driver/main.swift)"
"${SWIFTC[@]}" "${CINC[@]}" -I "$OUT" -module-name render_full \
    -emit-object -o "$OUT/render_full.o" \
    "$UIKIT/Sources/openrender/SceneBuilder.swift" "$W/full/driver/main.swift"

# ---- link ------------------------------------------------------------------
# swiftcore-FIRST: the staged libSystem.tbd still advertises swift_*, so a
# system-first link binds _swift_release into libSystem, which no longer
# defines it, and the guest dies at load (docs/ISA_MASK_VERDICT.md §7).
echo "== link"
"${LD[@]}" -exported_symbol __mh_execute_header -rpath @loader_path \
    -L/usr/lib/swift -lswiftCore "$SWIFTCOMPAT" \
    -L/usr/lib -lSystem -lobjc "$QUARTZLIB" \
    -o "$OUT/render_full" \
    "$OUT/render_full.o" "$OUT/openuikit.o" "$OUT/opencoregraphics.o" \
    "$OUT/cportableio.o" "$OUT/cstbtruetype.o"

echo "== done"; ls -l "$OUT/render_full"
