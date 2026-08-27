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
# MACHORUN=/machorun is a read-only bind mount of ~/machorun, so the guest root
# is always staged from the CURRENT loader and userland rather than from a copy
# that silently goes stale. That mattered once already: a guest root staged
# before machorun's heap-below-2^47 fix (9659e73) reproduced a bug that had
# been fixed upstream hours earlier.
MACHORUN=${MACHORUN:-/machorun}
if [ ! -d "$ROOTDIR" ]; then
    echo "== staging guest root from $MACHORUN"
    mkdir -p "$ROOTDIR/darwin/usr/lib/swift"
    cp "$MACHORUN/build/machorun" "$ROOTDIR/machorun"
    # The Swift runtime dylibs and the Foundation/CoreFoundation loud-abort
    # stubs are NOT machorun's -- they are the spike's staged Apple simulator
    # runtime and shims (docs/RUNTIME.md §4), so they come from scratch/mrroot.
    [ -d "$W/scratch/mrroot/darwin/System" ] && cp -R "$W/scratch/mrroot/darwin/System" "$ROOTDIR/darwin/"
    cp "$W/scratch/mrroot/darwin/usr/lib/swift/"*.dylib "$ROOTDIR/darwin/usr/lib/swift/"
    cp "$W/scratch/mrroot/darwin/usr/lib/libswiftcompat.dylib" "$ROOTDIR/darwin/usr/lib/"
    for d in "$MACHORUN/darwin/usr/lib/"*.dylib; do
        # NOT libquartz: machorun's is an older sync of ~/quartz and is rebuilt
        # below from ~/uikit's CQuartz. Copying it here would satisfy the
        # freshness check and silently link the guest against the old ABI.
        # libquartz: machorun's is an older sync of ~/quartz, rebuilt below from
        # ~/uikit's CQuartz. libSystem.B/libc++.1: rebuilt below as umbrellas.
        case "$(basename "$d")" in
            libquartz.dylib|libSystem.B.dylib|libc++.1.dylib) continue ;;
        esac
        cp "$d" "$ROOTDIR/darwin/usr/lib/"
    done
fi
SWIFTCOMPAT=$ROOTDIR/darwin/usr/lib/libswiftcompat.dylib

# ---- libSystem / libc++ umbrellas -----------------------------------------
# ONE umbrella per library, over machorun's CURRENT dylib, carrying BOTH sets
# of additions:
#   spike/syspatch.c   + spike/cxxpatch.cpp   the 47+5 symbols the staged Apple
#                                             Swift runtime needs (docs/RUNTIME.md §4)
#   full/shims/concpatch.c + conccxx.cpp      the 22 more libswift_Concurrency needs
#
# Building one umbrella rather than stacking mine on top of the spike's is not
# tidiness: stacking meant wrapping whatever libSystem.B.dylib happened to be in
# scratch/mrroot, which is a COPY that goes stale. It did -- a root staged before
# machorun's heap-below-2^47 fix (9659e73) reproduced a bug fixed upstream hours
# earlier. Everything is now rebuilt from ~/machorun on every run.
#
# Which library owns which symbol is dyld_info's answer, not a preference: these
# images bind two-level, so a definition in the wrong library is invisible.
if [ ! -f "$ROOTDIR/.umbrellas" ] || \
   [ "$MACHORUN/darwin/usr/lib/libSystem.B.dylib" -nt "$ROOTDIR/.umbrellas" ] || \
   [ "$W/full/shims/concpatch.c" -nt "$ROOTDIR/.umbrellas" ] || \
   [ "$W/full/shims/conccxx.cpp" -nt "$ROOTDIR/.umbrellas" ] || \
   [ "$W/full/shims/lowheap.c" -nt "$ROOTDIR/.umbrellas" ]; then
    echo "== libSystem + libc++ umbrellas (syspatch + concpatch)"
    LIB=$ROOTDIR/darwin/usr/lib

    cp "$MACHORUN/darwin/usr/lib/libSystem.B.dylib" "$LIB/libSystem.real.dylib"
    llvm-install-name-tool-18 -id /usr/lib/libSystem.real.dylib "$LIB/libSystem.real.dylib"
    cp "$MACHORUN/darwin/usr/lib/libc++.1.dylib" "$LIB/libc++.real.dylib"
    llvm-install-name-tool-18 -id /usr/lib/libc++.real.dylib "$LIB/libc++.real.dylib"

    "${CC[@]}" -O1 -c -o "$OUT/syspatch.o"  "$W/spike/syspatch.c"
    "${CC[@]}" -O1 -c -o "$OUT/concpatch.o" "$W/full/shims/concpatch.c"
    clang-18 -target arm64-apple-macos13.0 -isysroot "$SYS" -O1 -std=c++17 \
        -fno-exceptions -nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1 \
        -c -o "$OUT/cxxpatch.o" "$W/spike/cxxpatch.cpp"
    clang-18 -target arm64-apple-macos13.0 -isysroot "$SYS" -O1 -std=c++17 \
        -fno-exceptions -fno-rtti -nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1 \
        -c -o "$OUT/conccxx.o" "$W/full/shims/conccxx.cpp"

    ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0 -syslibroot "$ROOTDIR/darwin" \
        -dylib -install_name /usr/lib/libSystem.B.dylib -undefined dynamic_lookup \
        -o "$LIB/libSystem.B.dylib" "$OUT/syspatch.o" "$OUT/concpatch.o" \
        -reexport_library "$LIB/libSystem.real.dylib"
    ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0 -syslibroot "$ROOTDIR/darwin" \
        -dylib -install_name /usr/lib/libc++.1.dylib -undefined dynamic_lookup \
        -o "$LIB/libc++.1.dylib" "$OUT/cxxpatch.o" "$OUT/conccxx.o" \
        "$LIB/libSystem.B.dylib" -reexport_library "$LIB/libc++.real.dylib"

    # A second libSystem, identical plus full/shims/lowheap.c, kept alongside
    # rather than installed. See that file's header: it is a FAILED experiment,
    # retained so the next person does not repeat it.
    "${CC[@]}" -O1 -c -o "$OUT/lowheap.o" "$W/full/shims/lowheap.c"
    ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0 -syslibroot "$ROOTDIR/darwin" \
        -dylib -install_name /usr/lib/libSystem.B.dylib -undefined dynamic_lookup \
        -o "$LIB/libSystem.B.lowheap.dylib" "$OUT/syspatch.o" "$OUT/concpatch.o" "$OUT/lowheap.o" \
        -reexport_library "$LIB/libSystem.real.dylib"

    touch "$ROOTDIR/.umbrellas"
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
# ---- the app path -----------------------------------------------------------
# NO Foundation module: see full/appshim/UIKit.swift for why a small one is
# worse than none. NSCoder rides in OpenUIKit instead.
# APPINC is deliberately a DIFFERENT directory from OUT: the Foundation probe
# must be visible to the app modules and invisible to the library, or
# OpenUIKit/OpenCoreGraphics switch to their Foundation branches and demand the
# full Darwin geometry contract. See full/appshim/Foundation.swift.
APPINC=$OUT/appinc; mkdir -p "$APPINC"
echo "== app path (Foundation probe + UIKit shim + RealAppProbe: UNMODIFIED app source)"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" -module-name Foundation \
    -emit-module -emit-module-path "$APPINC/Foundation.swiftmodule" \
    -emit-object -o "$OUT/foundation.o" "$W/full/appshim/Foundation.swift"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" -I "$OUT" -I "$APPINC" -module-name UIKit \
    -emit-module \
    -emit-module-path "$APPINC/UIKit.swiftmodule" \
    -emit-object -o "$OUT/uikitshim.o" "$W/full/appshim/UIKit.swift"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" -I "$OUT" -I "$APPINC" -default-isolation MainActor \
    -module-name RealAppProbe -emit-module -emit-module-path "$OUT/RealAppProbe.swiftmodule" \
    -emit-object -o "$OUT/realappprobe.o" \
    "$UIKIT"/Sources/RealAppProbe/*.swift "$UIKIT"/Sources/RealAppProbe/Vendored/*.swift

# The renderer sees APPINC too: RealApp.swift imports RealAppProbe, whose
# interface transitively names UIKit and Foundation.
echo "== renderer (SceneBuilder.swift + RealApp.swift verbatim + full/driver/main.swift)"
"${SWIFTC[@]}" "${CINC[@]}" -I "$OUT" -I "$APPINC" -module-name render_full \
    -emit-object -o "$OUT/render_full.o" \
    "$UIKIT/Sources/openrender/SceneBuilder.swift" "$UIKIT/Sources/openrender/RealApp.swift" \
    "$W/full/driver/main.swift"

# ---- link ------------------------------------------------------------------
# swiftcore-FIRST: the staged libSystem.tbd still advertises swift_*, so a
# system-first link binds _swift_release into libSystem, which no longer
# defines it, and the guest dies at load (docs/ISA_MASK_VERDICT.md §7).
echo "== link"
# -L the guest root's lib dir so the umbrella's LC_REEXPORT_DYLIB of
# /usr/lib/libSystem.real.dylib resolves. The umbrella is linked directly
# (rather than via -lSystem) because the SDK .tbd does not advertise
# pthread_main_np, which the APP path needs and the render path does not.
"${LD[@]}" -exported_symbol __mh_execute_header -rpath @loader_path \
    -L"$ROOTDIR/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$SWIFTCOMPAT" \
    -L/usr/lib -lSystem -lobjc "$QUARTZLIB" \
    "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib" \
    -o "$OUT/render_full" \
    "$OUT/render_full.o" "$OUT/realappprobe.o" "$OUT/uikitshim.o" "$OUT/foundation.o" \
    "$OUT/openuikit.o" "$OUT/opencoregraphics.o" \
    "$OUT/cportableio.o" "$OUT/cstbtruetype.o"

echo "== done"; ls -l "$OUT/render_full"
