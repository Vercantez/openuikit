#!/bin/bash
# build_full.sh -- build the FULL OpenUIKit module (not the vendored slice) as
# arm64-apple-macos Mach-O on Linux, plus a Foundation-umbrella-free scene
# renderer. FoundationEssentials is a real production dependency: it owns the
# app-facing IndexPath identity exported by literal UIKit.
#
# ~/uikit IS NEVER EDITED AND NEVER COPIED. It is bind-mounted read-only at
# /uikit and compiled in place. The project-owned inputs are explicit:
#   full/shims/FoundationNames.swift  OpenUIKit's remaining pre-M15
#                                     NSRange/TimeInterval fallbacks plus the
#                                     Foundation-free IndexSet. Its historical
#                                     IndexPath is excluded when the canonical
#                                     FoundationEssentials type is available.
#   full/driver/*.swift               replaces openrender's two Foundation-using
#                                     files and supplies run-loop/app/bundle/value
#                                     self-tests; SceneBuilder.swift and RealApp.swift
#                                     are compiled verbatim
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
TARGET=arm64-apple-macos15.0           # FoundationEssentials' declared floor
MINOS=15.0
SYS=$W/scratch/sysroot_fe4             # Darwin + FE compile sysroot
OUT=$W/build/full
ROOTDIR=$W/scratch/mrroot_full         # guest root for this renderer
MC=$W/scratch/modcache_full
SF=$W/scratch/swift-foundation
SC=$W/scratch/swift-collections
FE_RUNTIME_SOURCE=${FE_RUNTIME_SOURCE:-$W/scratch/mrroot_fe}
FE_BUILD=$OUT/foundation
FE_OUT=$FE_BUILD/essentials
FE_COLLECTIONS=$FE_BUILD/collections
FE_OS=$FE_BUILD/os
FE_CSHIMS=$FE_BUILD/cshims
PINNED_INPUTS_TOOL=$W/full/foundation/pinned_inputs.pl

# ---- pinned upstream compile inputs ---------------------------------------
# This preflight happens before outputs or success markers are touched. The
# exact Git trees own the compiler manifests; ordinary `git status` is not
# enough because ignored .build* directories can contain Swift files that an
# unrestricted recursive walk would consume.
[ -d "$SYS/usr/include" ] || {
    echo "build_full: no FE sysroot at $SYS; run full/foundation/stage_fe_sysroot.sh" >&2
    exit 2
}
[ -f "$PINNED_INPUTS_TOOL" ] || {
    echo "build_full: no pinned-input tool at $PINNED_INPUTS_TOOL" >&2
    exit 2
}
echo "== verifying exact pinned upstream compile inputs"
PINNED_SOURCE_STATE_BEFORE=$(perl "$PINNED_INPUTS_TOOL" verify \
    --swift-foundation "$SF" --swift-collections "$SC" --digest-only)
echo "   -> $PINNED_SOURCE_STATE_BEFORE"

# Bracket the complete source/resource subject used by the focused UIHelpers
# guest proof. The runner re-computes this exact content digest; a leftover
# render_full from another checkout or commit cannot pass on timestamps alone.
# uihelpers_subject includes the verified upstream digest above.
UIHELPERS_SUBJECT_BEFORE=$(bash "$W/full/scripts/uihelpers_subject.sh" "$W" "$UIKIT")
mkdir -p "$OUT" "$MC" "$FE_OUT" "$FE_COLLECTIONS" "$FE_OS" "$FE_CSHIMS"
# These files are commit markers for a completely successful build. Remove
# them before mutating any output, so a failed or interrupted rebuild can never
# leave yesterday's attestation blessing today's partial binary.
rm -f "$OUT/uihelpers-subject.sha256" "$OUT/uihelpers-artifacts.sha256"

SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -wmo
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch arm64 -platform_version macos "$MINOS" "$MINOS" -syslibroot "$SYS" -rpath /usr/lib/swift)
CC=(clang-18 -target "$TARGET" -isysroot "$SYS" -O2)

# ---- guest root ------------------------------------------------------------
# MACHORUN=/machorun is a read-only bind mount of ~/machorun, so the guest root
# is always staged from the CURRENT loader and userland rather than from a copy
# that silently goes stale. That mattered once already: a guest root staged
# before machorun's heap-below-2^47 fix (9659e73) reproduced a bug that had
# been fixed upstream hours earlier.
MACHORUN=${MACHORUN:-/machorun}
# REFUSE WITHOUT THE MOUNT, rather than silently building half a root.
# Measured 2026-08-27: invoked without `-v ~/machorun:/machorun:ro`, every `-nt`
# test below compares against a path that does not exist and is therefore FALSE,
# so the loader copy AND the umbrella rebuild are both skipped -- with no error,
# exit 0, and a `render_full` that links fine against whatever the root happened
# to contain. That is the same class as the half-and-half root the comment above
# describes, except it leaves no trace at all. The docs' own §5 reproduce command
# omitted the mount, so this was reachable by following the instructions.
for req in "$MACHORUN/build/machorun" "$MACHORUN/darwin/usr/lib/libSystem.B.dylib"; do
    [ -e "$req" ] && continue
    cat >&2 <<EOF

build_full: REFUSING TO BUILD -- $req is missing.

  MACHORUN=$MACHORUN does not look like a machorun checkout. Without it every
  freshness test below is silently FALSE and the loader + umbrella steps are
  skipped, producing a guest root assembled from whatever was already on disk.

  Add the mount:
    docker run --rm -v ~/swift-macho-linux:/w -v ~/uikit:/uikit:ro \\
        -v ~/machorun:/machorun:ro -w /w \\
        swift-macho-spike:noble bash full/scripts/build_full.sh

  (If machorun is checked out elsewhere, mount it and set MACHORUN=<that path>.)
EOF
    exit 2
done
# RE-STAGED WHENEVER THE LOADER MOVES, not only when the root is missing.
# Staging on first creation only was not enough, and the gap was not
# theoretical: the umbrellas below are rebuilt from machorun's CURRENT
# libSystem.B.dylib on every run, while the loader sat at whatever version was
# current when the directory was made. On 2026-08-27 that produced a guest root
# whose libSystem wanted `_mr_report_backtrace` from a loader too old to have
# it -- and, before it failed loudly, a 108-scene scoreboard of 64 ok / 43
# crashed taken against a loader predating machorun's malloc_type fix (0f39750,
# "the 46 scenes it was smashing"). HALF A ROOT FROM ONE VERSION AND HALF FROM
# ANOTHER READS AS A REAL RESULT.
if [ ! -d "$ROOTDIR" ] || [ "$MACHORUN/build/machorun" -nt "$ROOTDIR/machorun" ]; then
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

# The three Swift runtime dylibs are NOT machorun copies. They come from the
# spike's recorded Apple-runtime root, and that source can change without the
# machorun loader changing. Synchronise them independently of the root-staging
# condition above; otherwise a second build rewrites the manifest with the new
# source digest while leaving the old runtime bytes in place, and its own
# freshness guard can never become green.
for d in "$W/scratch/mrroot/darwin/usr/lib/swift/"*.dylib; do
    [ -f "$d" ] || { echo "build_full: no staged Swift runtime dylibs in $W/scratch/mrroot" >&2; exit 2; }
    target="$ROOTDIR/darwin/usr/lib/swift/$(basename "$d")"
    if ! cmp -s "$d" "$target"; then
        echo "== restaging $(basename "$d") from scratch/mrroot"
        cp "$d" "$target"
    fi
done
SWIFTCOMPAT=$ROOTDIR/darwin/usr/lib/libswiftcompat.dylib

# FoundationEssentials pulls this nine-dylib Swift overlay closure. The source
# root is staged on macOS by full/foundation/stage_swift_overlays.sh; this
# Linux build copies only the closure additions, never that root's loader,
# libSystem, libswiftCore, or libswift_Concurrency. Those remain owned by the
# current full-root staging above.
FE_OVERLAYS=(
    libswiftDarwin.dylib
    libswiftSynchronization.dylib
    libswift_Builtin_float.dylib
    libswift_DarwinFoundation1.dylib
    libswift_DarwinFoundation2.dylib
    libswift_DarwinFoundation3.dylib
    libswift_RegexParser.dylib
    libswift_StringProcessing.dylib
    libswift_errno.dylib
)
echo "== staging FoundationEssentials Swift runtime closure"
for name in "${FE_OVERLAYS[@]}"; do
    source="$FE_RUNTIME_SOURCE/darwin/usr/lib/swift/$name"
    target="$ROOTDIR/darwin/usr/lib/swift/$name"
    [ -f "$source" ] && [ ! -L "$source" ] || {
        echo "build_full: missing regular FE runtime overlay: $source" >&2
        exit 2
    }
    if ! cmp -s "$source" "$target"; then
        cp "$source" "$target"
        echo "   staged $name"
    fi
done

# Keep the extensionless Foundation/CoreFoundation loud-abort stubs in step
# independently of loader freshness too.  They are real transitive load
# inputs of the staged Swift runtime, but the old root manifest only enumerated
# *.dylib and therefore could neither notice their absence nor their drift.
for framework in Foundation CoreFoundation; do
    source="$W/scratch/mrroot/darwin/System/Library/Frameworks/$framework.framework/$framework"
    target="$ROOTDIR/darwin/System/Library/Frameworks/$framework.framework/$framework"
    [ -f "$source" ] && [ ! -L "$source" ] || {
        echo "build_full: no regular staged $framework loud-abort stub in $W/scratch/mrroot" >&2
        exit 2
    }
    mkdir -p "$(dirname "$target")"
    if ! cmp -s "$source" "$target"; then
        echo "== restaging $framework loud-abort stub from scratch/mrroot"
        cp "$source" "$target"
    fi
done

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
# Rebuild on every invocation. These dylibs are independently loaded outputs;
# timestamp-triggered reuse could record a current source digest over an old
# umbrella when content changed without a newer mtime.
{
    echo "== libSystem + libc++ umbrellas (syspatch + concpatch)"
    LIB=$ROOTDIR/darwin/usr/lib

    # THE RENAME USES scripts/set_id_dylib.pl, NOT llvm-install-name-tool.
    # Measured 2026-08-27: llvm-install-name-tool-18 (this container) and
    # Homebrew LLVM 21.1.3 (host) BOTH die with
    #   error: unsupported load command (cmd=0x8000001f)
    # on libc++.1.dylib, which since machorun #55 carries LC_REEXPORT_DYLIB of
    # libc++abi. Three LLVM majors apart makes that a design fact about
    # llvm-objcopy, not a version skew, so `set -e` killed this script here and
    # scratch/mrroot_full could not be rebuilt by its own pipeline at all. The
    # 108/108 scoreboard of task #67 was obtained past this break by hand.
    # set_id_dylib.pl edits ONLY the 8-byte-aligned LC_ID_DYLIB field in place
    # (growing the command out of the linker's header padding when the new name
    # is longer, as it is for libc++), leaving every content byte alone -- which
    # is also the invariant require_fresh_root.sh grades .real files on.
    # Graded byte-for-byte against Apple's tooling by scripts/set_id_dylib_test.sh.
    rename_id() {   # rename_id <src> <dst-file> <new-install-name>
        cp "$1" "$2"
        perl "$W/scripts/set_id_dylib.pl" "$2" "$3" >/dev/null
        # Read it back through a DIFFERENT reader than the one that wrote it.
        local got
        got=$(llvm-otool-18 -D "$2" 2>/dev/null | tail -1)
        [ "$got" = "$3" ] || { echo "build_full: LC_ID_DYLIB rewrite failed on $2 -- reads '$got', wanted '$3'" >&2; exit 1; }
        echo "   $(basename "$2") <- $(basename "$1")  id=$got"
    }
    rename_id "$MACHORUN/darwin/usr/lib/libSystem.B.dylib" "$LIB/libSystem.real.dylib" /usr/lib/libSystem.real.dylib
    rename_id "$MACHORUN/darwin/usr/lib/libc++.1.dylib"    "$LIB/libc++.real.dylib"    /usr/lib/libc++.real.dylib

    "${CC[@]}" -O1 -c -o "$OUT/syspatch.o"  "$W/spike/syspatch.c"
    "${CC[@]}" -O1 -c -o "$OUT/concpatch.o" "$W/full/shims/concpatch.c"
    clang-18 -target "$TARGET" -isysroot "$SYS" -O1 -std=c++17 \
        -fno-exceptions -nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1 \
        -c -o "$OUT/cxxpatch.o" "$W/spike/cxxpatch.cpp"
    clang-18 -target "$TARGET" -isysroot "$SYS" -O1 -std=c++17 \
        -fno-exceptions -fno-rtti -nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1 \
        -c -o "$OUT/conccxx.o" "$W/full/shims/conccxx.cpp"

    ld64.lld-18 -arch arm64 -platform_version macos "$MINOS" "$MINOS" -syslibroot "$ROOTDIR/darwin" \
        -dylib -install_name /usr/lib/libSystem.B.dylib -undefined dynamic_lookup \
        -o "$LIB/libSystem.B.dylib" "$OUT/syspatch.o" "$OUT/concpatch.o" \
        -reexport_library "$LIB/libSystem.real.dylib"
    ld64.lld-18 -arch arm64 -platform_version macos "$MINOS" "$MINOS" -syslibroot "$ROOTDIR/darwin" \
        -dylib -install_name /usr/lib/libc++.1.dylib -undefined dynamic_lookup \
        -o "$LIB/libc++.1.dylib" "$OUT/cxxpatch.o" "$OUT/conccxx.o" \
        "$LIB/libSystem.B.dylib" -reexport_library "$LIB/libc++.real.dylib"

    # A second libSystem, identical plus full/shims/lowheap.c, kept alongside
    # rather than installed. See that file's header: it is a FAILED experiment,
    # retained so the next person does not repeat it.
    "${CC[@]}" -O1 -c -o "$OUT/lowheap.o" "$W/full/shims/lowheap.c"
    ld64.lld-18 -arch arm64 -platform_version macos "$MINOS" "$MINOS" -syslibroot "$ROOTDIR/darwin" \
        -dylib -install_name /usr/lib/libSystem.B.dylib -undefined dynamic_lookup \
        -o "$LIB/libSystem.B.lowheap.dylib" "$OUT/syspatch.o" "$OUT/concpatch.o" "$OUT/lowheap.o" \
        -reexport_library "$LIB/libSystem.real.dylib"

    # The umbrella must DEFINE the symbols that are its whole reason to exist.
    # __NSGetMachExecuteHeader is the discriminator: no machorun libSystem has
    # ever exported it (checked with nm and `git log -S`), it comes only from
    # full/shims/concpatch.c, and every scene dies at load without it. That is
    # exactly the state a `MRROOT_REFRESH=1` left this root in for most of
    # 2026-08-27 -- so the property is asserted here, at the moment it is built.
    for sym in __NSGetMachExecuteHeader; do
        llvm-nm-18 --extern-only --defined-only "$LIB/libSystem.B.dylib" 2>/dev/null \
            | awk '{print $NF}' | grep -qx "$sym" || {
            echo "build_full: the libSystem umbrella does not define $sym -- it is not an umbrella, it is a copy" >&2
            exit 1; }
    done
    echo "   umbrella libSystem.B: $(llvm-nm-18 --extern-only --defined-only "$LIB/libSystem.B.dylib" | wc -l) own defs (incl. __NSGetMachExecuteHeader), reexporting libSystem.real"

    touch "$ROOTDIR/.umbrellas"
}

# ---- the manifest: which files here are COPIES and which are BUILT ---------
# A guest root is a MIXTURE, and a freshness check that cannot tell the two
# apart is worse than none: scripts/require_fresh_root.sh used to grade the
# libSystem UMBRELLA against machorun's plain libSystem (false DRIFT every time,
# with a remedy that deleted the shim layer) while SKIPPING libSystem.real, the
# one file where staleness is a real question.
#
# WRITTEN HERE, BY THE SCRIPT THAT BUILDS THEM, on purpose. The classification
# is a property of how the root was assembled, so keeping a second copy of it
# inside the guard would be a thing to forget: the manifest goes stale exactly
# when the build changes, which is when someone is already editing this file.
#
#   copy      <in-root>  <in-machorun>                   grade: byte-identical
#   staged    <in-root>  <source-sha> <source> [upstream] grade: byte-identical to the
#                                                        recorded external source; optional
#                                                        upstream records an intentional override
#   renamed   <in-root>  <in-machorun>                   grade: identical outside LC_ID_DYLIB
#   umbrella  <in-root>  - <sym> <deps...>               grade: newer than deps, defines <sym>,
#                                                        re-exports its .real
#   local     <in-root>  <in-machorun|-> <reason>        not graded; an <in-machorun> here
#                                                        EXCUSES that upstream file from MISSING
echo "== manifest ($ROOTDIR/.manifest)"
{
    echo "# generated by full/scripts/build_full.sh -- do not hand-edit"
    printf 'copy\tmachorun\tbuild/machorun\n'
    for n in libc++abi.dylib libobjc.A.dylib libswiftcompat.dylib; do
        printf 'copy\tdarwin/usr/lib/%s\tdarwin/usr/lib/%s\n' "$n" "$n"
    done
    for n in libswiftCore.dylib libswiftObjectiveC.dylib libswift_Concurrency.dylib; do
        source="$W/scratch/mrroot/darwin/usr/lib/swift/$n"
        source_sha=$(shasum -a 256 "$source" | cut -d' ' -f1)
        if [ "$n" = libswiftCore.dylib ]; then
            # machorun now also carries a DIFFERENT libswiftCore. This full root
            # intentionally overrides it with the spike runtime, so the final
            # field accounts for that upstream path without pretending the
            # bytes are a copy of it.
            printf 'staged\tdarwin/usr/lib/swift/%s\t%s\t%s\tdarwin/usr/lib/swift/%s\n' \
                "$n" "$source_sha" "$source" "$n"
        else
            printf 'staged\tdarwin/usr/lib/swift/%s\t%s\t%s\n' "$n" "$source_sha" "$source"
        fi
    done
    for n in "${FE_OVERLAYS[@]}"; do
        source="$FE_RUNTIME_SOURCE/darwin/usr/lib/swift/$n"
        source_sha=$(shasum -a 256 "$source" | cut -d' ' -f1)
        printf 'staged\tdarwin/usr/lib/swift/%s\t%s\t%s\n' "$n" "$source_sha" "$source"
    done
    for framework in Foundation CoreFoundation; do
        source="$W/scratch/mrroot/darwin/System/Library/Frameworks/$framework.framework/$framework"
        source_sha=$(shasum -a 256 "$source" | cut -d' ' -f1)
        printf 'staged\tdarwin/System/Library/Frameworks/%s.framework/%s\t%s\t%s\n' \
            "$framework" "$framework" "$source_sha" "$source"
    done
    printf 'renamed\tdarwin/usr/lib/libSystem.real.dylib\tdarwin/usr/lib/libSystem.B.dylib\n'
    printf 'renamed\tdarwin/usr/lib/libc++.real.dylib\tdarwin/usr/lib/libc++.1.dylib\n'
    printf 'umbrella\tdarwin/usr/lib/libSystem.B.dylib\t-\t__NSGetMachExecuteHeader\tdarwin/usr/lib/libSystem.real.dylib\tspike/syspatch.c\tfull/shims/concpatch.c\n'
    printf 'umbrella\tdarwin/usr/lib/libc++.1.dylib\t-\t-\tdarwin/usr/lib/libc++.real.dylib\tspike/cxxpatch.cpp\tfull/shims/conccxx.cpp\n'
    printf 'local\tdarwin/usr/lib/libquartz.dylib\tdarwin/usr/lib/libquartz.dylib\tbuilt from /uikit Sources/CQuartz; machorun'"'"'s copy is an older sync without the codec entry points\n'
    printf 'local\tdarwin/usr/lib/libSystem.B.lowheap.dylib\t-\ta FAILED experiment kept deliberately; see full/shims/lowheap.c\n'
} > "$ROOTDIR/.manifest"

# ---- libquartz, from ~/uikit's CQuartz -------------------------------------
# Flags mirror machorun/scripts/build_quartz.sh exactly (-fno-exceptions
# -fno-rtti because machorun has no unwinder for compact __unwind_info; stock
# LLVM-18 libc++ headers with the same three -D flags; clang's DEFAULT floating
# point mode, so the pixel diff measures the loader and not -ffast-math).
QOBJ=$OUT/quartz-obj
# Always rebuild. This dylib is loaded separately from render_full and the root
# manifest deliberately labels it local, so a source digest cannot attest a
# cached copy. Rebuilding plus the artifact hash published below closes that
# otherwise-real false-green path.
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
    clang-18 -target "$TARGET" -isysroot "$SYS" "${QCXX[@]}" $QINC -c "$f" -o "$o"
    QOBJS+=("$o")
done
# -syslibroot the GUEST root: our libSystem.B/libc++.1 are umbrellas that
# LC_REEXPORT_DYLIB /usr/lib/*.real.dylib, and the linker has to be able to
# resolve those install names to files.
ld64.lld-18 -dylib -arch arm64 -platform_version macos "$MINOS" "$MINOS" \
    -syslibroot "$ROOTDIR/darwin" \
    -install_name /usr/lib/libquartz.dylib -undefined dynamic_lookup \
    -o "$ROOTDIR/darwin/usr/lib/libquartz.dylib" "${QOBJS[@]}" \
    "$ROOTDIR/darwin/usr/lib/libc++.1.dylib" "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib"
# llvm-nm-18, not nm: the container's `nm` is GNU binutils and CANNOT READ
# MACH-O -- it printed "file format not recognized" to the stderr this line
# was discarding, grep counted an empty stream, and the build cheerfully
# reported "(0 QZ exports)" about a dylib carrying 388. A counter that reads
# zero when the tool failed is worse than no counter: it looks like a result.
QZN=$(llvm-nm-18 --extern-only --defined-only "$ROOTDIR/darwin/usr/lib/libquartz.dylib" | grep -c '_QZ')
[ "$QZN" -gt 0 ] || { echo "build_full: libquartz.dylib exports no QZ symbols" >&2; exit 1; }
echo "   -> libquartz.dylib ($QZN QZ exports)"
# A .tbd is not needed: link the guest directly against the dylib we just built.
QUARTZLIB=$ROOTDIR/darwin/usr/lib/libquartz.dylib

# ---- C targets: compiled from ~/uikit's own sources ------------------------
echo "== C targets (CPortableIO, CSTBTrueType)"
"${CC[@]}" -I"$UIKIT/Sources/CPortableIO/include" -c \
    -o "$OUT/cportableio.o" "$UIKIT/Sources/CPortableIO/io.c"
"${CC[@]}" -I"$UIKIT/Sources/CSTBTrueType/include" -c \
    -o "$OUT/cstbtruetype.o" "$UIKIT/Sources/CSTBTrueType/stb_impl.c"
# CHostClock: the two primitives a run loop needs from its host, and the only
# ones -- OpenUIKit owns no clock by design (UIWindow.tick takes the time from
# whoever drives it).
"${CC[@]}" -I"$W/full/hostclock/include" -c -o "$OUT/hostclock.o" "$W/full/hostclock/hostclock.c"
# The stdlib entry points our compiler emits and the staged Apple runtime does
# not export. LINKED INTO THE EXECUTABLE rather than into a libswiftCore
# umbrella: llvm-install-name-tool cannot rewrite Apple's libswiftCore at all
# (it carries LC_SEGMENT_SPLIT_INFO, cmd 0x1e), so the rename the umbrella
# pattern needs is not available for that library. An object file outranks a
# .tbd, so the linker resolves the symbol here and emits no import.
"${CC[@]}" -c -o "$OUT/swiftcorepatch.o" "$W/full/shims/swiftcorepatch.c"

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
      -Xcc -I"$W/full/hostclock/include"
      -Xcc -I"$UIKIT/Sources/CQuartz/include")

# ---- FoundationEssentials: built here, not borrowed as a stale object -------
# This is the production full path. Every invocation rebuilds the exact pinned
# upstream sources, stages their modules beside OpenUIKit, and later links all
# dependency objects into both executables. There is no swift-system checkout
# in this graph; the local os-module source is part of the project subject.
echo "== FoundationEssentials production inputs ($TARGET)"
rm -rf "$FE_BUILD"
mkdir -p "$FE_OUT" "$FE_COLLECTIONS" "$FE_OS" "$FE_CSHIMS"
W="$W" SC="$SC" SYS="$SYS" OUT="$FE_COLLECTIONS" TARGET="$TARGET" \
    PINNED_INPUTS_TOOL="$PINNED_INPUTS_TOOL" \
    bash "$W/full/foundation/build_collections.sh"
W="$W" SYS="$SYS" OUT="$FE_OS" TARGET="$TARGET" \
    bash "$W/full/foundation/build_os_module.sh"
W="$W" SF="$SF" SYS="$SYS" OUT="$FE_CSHIMS" TARGET="$TARGET" \
    PINNED_INPUTS_TOOL="$PINNED_INPUTS_TOOL" \
    bash "$W/full/foundation/build_cshims.sh"
W="$W" SF="$SF" SYS="$SYS" OSMOD="$FE_OS" COLLECTIONS="$FE_COLLECTIONS" \
    TARGET="$TARGET" PINNED_INPUTS_TOOL="$PINNED_INPUTS_TOOL" \
    bash "$W/full/foundation/build_fe.sh" \
    -parse-as-library \
    -emit-module -emit-module-path "$FE_OUT/FoundationEssentials.swiftmodule" \
    -c -o "$FE_OUT/FoundationEssentials.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O1 -nostdinc \
    -DOPEN_FOUNDATION_UUID_COMPAT=1 \
    -c "$W/full/foundation/fm_unimplemented.c" -o "$FE_OUT/fm_unimplemented.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O1 \
    -c "$W/full/foundation/uuid_compat.c" -o "$FE_OUT/uuid_compat.o"

FEMODULES=(
    -I "$FE_OUT" -I "$FE_COLLECTIONS" -I "$FE_OS"
    -Xcc -fmodule-map-file="$SF/Sources/_FoundationCShims/include/module.modulemap"
    -Xcc -I"$SF/Sources/_FoundationCShims/include"
)
FE_OBJECTS=(
    "$FE_OUT/FoundationEssentials.o"
    "$FE_COLLECTIONS/InternalCollectionsUtilities.o"
    "$FE_COLLECTIONS/OrderedCollections.o"
    "$FE_COLLECTIONS/_RopeModule.o"
    "$FE_OS/os.o"
    "$FE_CSHIMS/platform_shims.o"
    "$FE_CSHIMS/string_shims.o"
    "$FE_CSHIMS/uuid.o"
    "$FE_OUT/fm_unimplemented.o"
    "$FE_OUT/uuid_compat.o"
)

# ---- module-visibility contract -------------------------------------------
# Foundation must remain absent (the tiny app-only shim is not a real
# umbrella), while FoundationEssentials must be present. Prove both the desired
# compile and the adversarial absence: a missing -I must not silently fall back
# to full/shims/FoundationNames.swift's historical rival IndexPath.
echo "== guard: Foundation hidden, FoundationEssentials required"
if "${SWIFTC[@]}" "${CINC[@]}" -typecheck -module-name GuardMissingFoundationEssentials \
    "$W/full/foundation/foundationessentials_import_guard.swift" >/dev/null 2>&1; then
    echo "   FATAL: FE guard passed without the staged FoundationEssentials module path" >&2
    exit 1
fi
cat >"$OUT/guard_teeth.swift" <<'EOF'
// The same mechanism aimed at a module that IS visible. This compile MUST
// fail; if it succeeds, #error is not being evaluated and the checked-in guard is
// decoration.
#if canImport(Swift)
#error("TEETH_OK")
#endif
EOF
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -typecheck \
    -module-name GuardFoundationEssentials \
    "$W/full/foundation/foundationessentials_import_guard.swift"
if "${SWIFTC[@]}" "${CINC[@]}" -typecheck -module-name GuardTeeth "$OUT/guard_teeth.swift" >/dev/null 2>&1; then
    echo "   FATAL: the guard cannot fail -- #error is not being evaluated" >&2
    exit 1
fi
echo "   -> exact visibility holds, missing-FE fallback refused, #error has teeth"

# ---- OpenCoreGraphics ------------------------------------------------------
echo "== OpenCoreGraphics ($(ls "$UIKIT"/Sources/OpenCoreGraphics/*.swift | wc -l) files, verbatim)"
"${SWIFTC[@]}" "${CINC[@]}" -module-name OpenCoreGraphics \
    -emit-object -emit-module -emit-module-path "$OUT/OpenCoreGraphics.swiftmodule" \
    -o "$OUT/opencoregraphics.o" "$UIKIT"/Sources/OpenCoreGraphics/*.swift

# ---- OpenUIKit (canonical FE IndexPath + remaining fallback names) ----------
UIKIT_SRCS=()
while IFS= read -r f; do UIKIT_SRCS+=("$f"); done < <(find "$UIKIT/Sources/OpenUIKit" -name '*.swift' | sort)
echo "== OpenUIKit (${#UIKIT_SRCS[@]} files verbatim, incl. AutoLayout/ + FoundationNames.swift)"
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT" -module-name OpenUIKit \
    -emit-object -emit-module -emit-module-path "$OUT/OpenUIKit.swiftmodule" \
    -o "$OUT/openuikit.o" \
    "${UIKIT_SRCS[@]}" "$W/full/shims/FoundationNames.swift"

# Keep this focused probe honest even though the combined renderer below must
# see APPINC for RealAppProbe. A separate typecheck before APPINC exists proves
# UIHelpersTest itself needs only the Foundation-umbrella-invisible OpenUIKit
# module (FoundationEssentials remains an explicit transitive dependency).
echo "== UIHelpers surface probe (Foundation umbrella invisible)"
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT" \
    -module-name UIHelpersSurfaceGuard \
    -typecheck "$W/full/driver/UIHelpersTest.swift"

# ---- literal UIKit + app path ----------------------------------------------
# UIKit gets its own include directory and is compiled BEFORE the intentionally
# tiny app-only Foundation module exists. That is a semantic boundary, not
# ordering trivia: Sources/UIKitShim/UIKit.swift must select its
# FoundationEssentials re-export branch. A stale Foundation.swiftmodule can
# never flip it because APPINC is not on this invocation's search path.
UIKITINC=$OUT/uikitinc
APPINC=$OUT/appinc
rm -rf "$UIKITINC" "$APPINC"
mkdir -p "$UIKITINC" "$APPINC"
echo "== literal UIKit shim (FoundationEssentials branch, actual /uikit source)"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT" \
    -module-name UIKit -emit-module -emit-module-path "$UIKITINC/UIKit.swiftmodule" \
    -emit-object -o "$OUT/uikitshim.o" "$UIKIT/Sources/UIKitShim/UIKit.swift"

# Compile the app-shaped proof while no Foundation module is visible. Its only
# import is UIKit; qualified FE/OpenUIKit conversions prove re-export and exact
# identity rather than merely checking that an unqualified spelling exists.
echo "== literal UIKit IndexPath compile proof"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
    -I "$OUT" -I "$UIKITINC" -module-name LiteralUIKitIndexPathProbe \
    -emit-object -o "$OUT/literal_uikit_indexpath_probe.o" \
    "$W/full/foundation/literal_uikit_indexpath_probe.swift"

# The vendored corpus also contains an explicit `import Foundation` for
# NSCoder. Keep that measured one-name module app-only; it is compiled after
# UIKit and never enters OpenUIKit's module search path.
echo "== app-only Foundation NSCoder shim + RealAppProbe (UNMODIFIED app source)"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT" \
    -module-name Foundation -emit-module -emit-module-path "$APPINC/Foundation.swiftmodule" \
    -emit-object -o "$OUT/foundation.o" "$W/full/appshim/Foundation.swift"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
    -I "$OUT" -I "$UIKITINC" -I "$APPINC" -default-isolation MainActor \
    -module-name RealAppProbe -emit-module -emit-module-path "$OUT/RealAppProbe.swiftmodule" \
    -emit-object -o "$OUT/realappprobe.o" \
    "$UIKIT"/Sources/RealAppProbe/*.swift "$UIKIT"/Sources/RealAppProbe/Vendored/*.swift

# The renderer sees both app include roots: RealApp.swift imports RealAppProbe,
# whose interface transitively names UIKit, Foundation, and FoundationEssentials.
echo "== renderer (SceneBuilder.swift + RealApp.swift verbatim + full/driver/main.swift)"
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" \
    -I "$OUT" -I "$UIKITINC" -I "$APPINC" -module-name render_full \
    -emit-object -o "$OUT/render_full.o" \
    "$UIKIT/Sources/openrender/SceneBuilder.swift" "$UIKIT/Sources/openrender/RealApp.swift" \
    "$W/full/driver/RunLoop.swift" "$W/full/driver/RunLoopTest.swift" \
    "$W/full/driver/LaunchByName.swift" "$W/full/driver/LaunchTest.swift" \
    "$W/full/driver/IndexSetTest.swift" "$W/full/driver/PasteboardTest.swift" \
    "$W/full/driver/UIHelpersTest.swift" \
    "$W/full/driver/Plist.swift" "$W/full/driver/Bundle.swift" "$W/full/driver/BundleTest.swift" \
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
COMMON_LINK_OBJECTS=(
    "$OUT/uikitshim.o" "$OUT/openuikit.o" "$OUT/opencoregraphics.o"
    "$OUT/cportableio.o" "$OUT/cstbtruetype.o" "$OUT/hostclock.o"
    "$OUT/swiftcorepatch.o"
    "${FE_OBJECTS[@]}"
)
"${LD[@]}" -dead_strip -exported_symbol __mh_execute_header -rpath @loader_path \
    -L"$ROOTDIR/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$SWIFTCOMPAT" \
    -L/usr/lib -lSystem -lobjc "$QUARTZLIB" \
    "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib" \
    -o "$OUT/render_full" \
    "$OUT/render_full.o" "$OUT/realappprobe.o" "$OUT/foundation.o" \
    "${COMMON_LINK_OBJECTS[@]}"

"${LD[@]}" -dead_strip -exported_symbol __mh_execute_header -rpath @loader_path \
    -L"$ROOTDIR/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$SWIFTCOMPAT" \
    -L/usr/lib -lSystem -lobjc "$QUARTZLIB" \
    "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib" \
    -o "$OUT/indexpath_identity_probe" \
    "$OUT/literal_uikit_indexpath_probe.o" "${COMMON_LINK_OBJECTS[@]}"

# ---- bundle fixtures -------------------------------------------------------
# Built here rather than committed, so they cannot drift from what the test
# expects. The oracle2 .apps cover the HAPPY cases (both layouts, real plists);
# these cover what a real app hits first, and what a careless Bundle collapses
# into one indistinguishable nil.
#   Probe.app   contains render_full itself, so Bundle.main has something real
#               to resolve -- the SAME binary run from inside a .app and from
#               outside it must answer differently.
#   NoKeys.app  a VALID plist carrying none of the CFBundle* keys: absent KEY.
#   Empty.app   a .app directory with no Info.plist at all:        absent FILE.
echo "== bundle fixtures (Probe.app, NoKeys.app, Empty.app)"
rm -rf "$OUT/Probe.app" "$OUT/NoKeys.app" "$OUT/Empty.app"
mkdir -p "$OUT/Probe.app" "$OUT/NoKeys.app" "$OUT/Empty.app"
cp "$OUT/render_full" "$OUT/Probe.app/probe"
printf 'hello from the bundle\n' >"$OUT/Probe.app/hello.txt"
cat >"$OUT/Probe.app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>probe</string>
	<key>CFBundleIdentifier</key><string>com.openuikit.bundleprobe</string>
	<key>CFBundleName</key><string>Probe</string>
	<key>CFBundlePackageType</key><string>APPL</string>
</dict>
</plist>
PLIST
cat >"$OUT/NoKeys.app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>SomethingElse</key><string>present, but not a key UIKit asks for</string>
</dict>
</plist>
PLIST

UIHELPERS_SUBJECT_AFTER=$(bash "$W/full/scripts/uihelpers_subject.sh" "$W" "$UIKIT")
if [ "$UIHELPERS_SUBJECT_BEFORE" != "$UIHELPERS_SUBJECT_AFTER" ]; then
    echo "build_full: REFUSING -- UIHelpers probe inputs changed during the build" >&2
    echo "  before: $UIHELPERS_SUBJECT_BEFORE" >&2
    echo "  after:  $UIHELPERS_SUBJECT_AFTER" >&2
    exit 2
fi
PINNED_SOURCE_STATE_AFTER=$(perl "$PINNED_INPUTS_TOOL" verify \
    --swift-foundation "$SF" --swift-collections "$SC" --digest-only)
if [ "$PINNED_SOURCE_STATE_BEFORE" != "$PINNED_SOURCE_STATE_AFTER" ]; then
    echo "build_full: REFUSING -- pinned upstream compile inputs changed during build" >&2
    exit 2
fi
{
    printf 'render_full\t%s\n' "$(sha256sum "$OUT/render_full" | awk '{print $1}')"
    printf 'indexpath_identity_probe\t%s\n' \
        "$(sha256sum "$OUT/indexpath_identity_probe" | awk '{print $1}')"
    printf 'FoundationEssentials.o\t%s\n' \
        "$(sha256sum "$FE_OUT/FoundationEssentials.o" | awk '{print $1}')"
    printf 'libquartz.dylib\t%s\n' \
        "$(sha256sum "$ROOTDIR/darwin/usr/lib/libquartz.dylib" | awk '{print $1}')"
    printf 'libSystem.B.dylib\t%s\n' \
        "$(sha256sum "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib" | awk '{print $1}')"
    printf 'libc++.1.dylib\t%s\n' \
        "$(sha256sum "$ROOTDIR/darwin/usr/lib/libc++.1.dylib" | awk '{print $1}')"
} > "$OUT/uihelpers-artifacts.sha256.tmp"
printf '%s\n' "$UIHELPERS_SUBJECT_AFTER" > "$OUT/uihelpers-subject.sha256.tmp"
# Publish the subject last: its presence is the commit marker that both the
# build and artifact manifests reached the successful end of the bracket.
mv "$OUT/uihelpers-artifacts.sha256.tmp" "$OUT/uihelpers-artifacts.sha256"
mv "$OUT/uihelpers-subject.sha256.tmp" "$OUT/uihelpers-subject.sha256"

echo "== done"; ls -l "$OUT/render_full" "$OUT/indexpath_identity_probe"
