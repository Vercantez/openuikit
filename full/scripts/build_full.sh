#!/bin/bash
# build_full.sh -- build the FULL OpenUIKit module (not the vendored slice) as
# Darwin Mach-O on Linux (arm64-apple-macos or x86_64-apple-macos), plus a
# Foundation-umbrella-free scene renderer. FoundationEssentials is a real
# production dependency: it owns the app-facing IndexPath identity exported
# by literal UIKit.
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
W=${W:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)}
# shellcheck source=../../scripts/vendor_tree.sh
. "$W/scripts/vendor_tree.sh"
# shellcheck source=../../scripts/x86/stamp.inc
. "$W/scripts/x86/stamp.inc"
die() {
    echo "build_full: $*" >&2
    exit 2
}
# shellcheck disable=SC1091
. "$(cd "$(dirname "$0")" && pwd)/guest_arch.inc"
UIKIT=${UIKIT:-$W/uikit}
MINOS=${MINOS:-15.0}
LINK_PLATFORM=${LINK_PLATFORM:-macos}
LINK_SDK_VERSION=${LINK_SDK_VERSION:-$MINOS}
SYS=${SYS:-$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}}     # Darwin + FE compile sysroot; x86_64 writes beside
APPLE_SWIFT_USER_OVERLAYS=${APPLE_SWIFT_USER_OVERLAYS:-}
OUT=${OUT:-$W/build/full${FULL_OUT_SUFFIX}}
ROOTDIR=${ROOTDIR:-$W/scratch/mrroot_full${FULL_OUT_SUFFIX}}
MC=${MC:-$W/scratch/modcache_full${FULL_OUT_SUFFIX}}
SF=${SF:-$W/scratch/swift-foundation}
SC=${SC:-$W/scratch/swift-collections}
BASE_RUNTIME_SOURCE=${BASE_RUNTIME_SOURCE:-$W/scratch/mrroot${FULL_OUT_SUFFIX}}
FE_RUNTIME_SOURCE=${FE_RUNTIME_SOURCE:-$W/scratch/mrroot_fe${FULL_OUT_SUFFIX}}
SWIFT_CORE_RUNTIME_STAGER=$W/full/scripts/stage_swift_core_runtime.py
FE_BUILD=$OUT/foundation
FE_OUT=$FE_BUILD/essentials
FE_COLLECTIONS=$FE_BUILD/collections
FE_OS=$FE_BUILD/os
FE_CSHIMS=$FE_BUILD/cshims
PINNED_INPUTS_TOOL=$W/full/foundation/pinned_inputs.pl
FE_OBJECT_PROVENANCE_TOOL=$W/full/foundation/fe_object_provenance.py
BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE=${BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE:-}
BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT=${BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT:-}
BUILD_FULL_PREVIEW_MACRO_PLUGIN=${BUILD_FULL_PREVIEW_MACRO_PLUGIN:-}
BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE=${BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE:-standalone}
BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_DISABLED_OWNER=${BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_DISABLED_OWNER:-}

# ---- pinned upstream compile inputs ---------------------------------------
# This preflight happens before outputs or success markers are touched. The
# exact Git trees own the compiler manifests; ordinary `git status` is not
# enough because ignored .build* directories can contain Swift files that an
# unrestricted recursive walk would consume.
[ -d "$SYS/usr/include" ] || {
    echo "build_full: no FE sysroot at $SYS; run full/foundation/stage_fe_sysroot.sh (Darwin) or scripts/x86/stage_fe_sysroot.sh (Linux x86_64 sibling)" >&2
    exit 2
}
[ -f "$PINNED_INPUTS_TOOL" ] || {
    echo "build_full: no pinned-input tool at $PINNED_INPUTS_TOOL" >&2
    exit 2
}
[ -f "$FE_OBJECT_PROVENANCE_TOOL" ] && [ ! -L "$FE_OBJECT_PROVENANCE_TOOL" ] || {
    echo "build_full: no regular FE object provenance tool at $FE_OBJECT_PROVENANCE_TOOL" >&2
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
UIHELPERS_SUBJECT_BEFORE=$(bash "$W/full/scripts/uihelpers_subject.sh" \
    "$W" "$UIKIT" "$SF" "$SC")
mkdir -p "$OUT" "$MC" "$FE_OUT" "$FE_COLLECTIONS" "$FE_OS" "$FE_CSHIMS"
# These files are commit markers for a completely successful build. Remove
# them before mutating any output, so a failed or interrupted rebuild can never
# leave yesterday's attestation blessing today's partial binary.
rm -f "$OUT/uihelpers-subject.sha256" "$OUT/uihelpers-artifacts.sha256" \
    "$OUT/swift-core-runtime-stage.json" \
    "$OUT/foundation-fe-object-provenance.tsv" \
    "$OUT/uihelpers-subject.sha256.tmp" \
    "$OUT/uihelpers-artifacts.sha256.tmp" \
    "$OUT/foundation-fe-object-provenance.tsv.tmp"

APPLE_SWIFT_OVERLAY_FLAGS=()
if [ -n "$APPLE_SWIFT_USER_OVERLAYS" ]; then
    for module_name in Darwin _DarwinFoundation1 _DarwinFoundation2 _DarwinFoundation3 ObjectiveC; do
        module_file="$APPLE_SWIFT_USER_OVERLAYS/$module_name.swiftmodule/arm64-apple-ios-simulator.swiftinterface"
        [ -f "$module_file" ] && [ ! -L "$module_file" ] || {
            echo "build_full: missing regular Apple user-overlay interface: $module_file" >&2
            exit 2
        }
    done
    APPLE_SWIFT_OVERLAY_FLAGS=(-I "$APPLE_SWIFT_USER_OVERLAYS")
fi

SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS" "${APPLE_SWIFT_OVERLAY_FLAGS[@]}" -module-cache-path "$MC"
        -runtime-compatibility-version none -wmo
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch "$ARCH" -platform_version "$LINK_PLATFORM" "$MINOS" "$LINK_SDK_VERSION" -syslibroot "$SYS" -rpath /usr/lib/swift)
CC=(clang-18 -target "$TARGET" -isysroot "$SYS" -O2)

# The DTS route is explicit and fail-closed. Standalone mode builds the
# canonical target source, external mode consumes an all-or-none attested trio,
# and disabled mode is reserved for the core package's Foundation-hidden stage,
# whose post-Foundation phase owns DTS and both compiler-library plugins.
PREVIEW_INPUT_COUNT=0
[ -n "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE" ] \
    && PREVIEW_INPUT_COUNT=$((PREVIEW_INPUT_COUNT + 1))
[ -n "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT" ] \
    && PREVIEW_INPUT_COUNT=$((PREVIEW_INPUT_COUNT + 1))
[ -n "$BUILD_FULL_PREVIEW_MACRO_PLUGIN" ] \
    && PREVIEW_INPUT_COUNT=$((PREVIEW_INPUT_COUNT + 1))
case "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE" in
    standalone)
        [ "$PREVIEW_INPUT_COUNT" -eq 0 ] || {
            echo 'build_full: standalone DTS mode refuses external Preview inputs' >&2
            exit 2
        }
        [ -z "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_DISABLED_OWNER" ] || {
            echo 'build_full: standalone DTS mode refuses a disabled-owner token' >&2
            exit 2
        } ;;
    external)
        [ "$PREVIEW_INPUT_COUNT" -eq 3 ] || {
            echo 'build_full: external DTS mode requires all three Preview inputs' >&2
            exit 2
        }
        [ -z "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_DISABLED_OWNER" ] || {
            echo 'build_full: external DTS mode refuses a disabled-owner token' >&2
            exit 2
        } ;;
    disabled)
        [ "$PREVIEW_INPUT_COUNT" -eq 0 ] || {
            echo 'build_full: disabled DTS mode refuses external Preview inputs' >&2
            exit 2
        }
        [ "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_DISABLED_OWNER" = \
            core-package-post-foundation ] || {
            echo 'build_full: disabled DTS mode lacks the core-package ownership token' >&2
            exit 2
        } ;;
    *)
        echo "build_full: invalid DTS mode: $BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE" >&2
        exit 2 ;;
esac
PREVIEW_SWIFT_FLAGS=()
PREVIEW_LINK_OBJECTS=()
PREVIEW_INPUT_STATE_BEFORE='disabled'
if [ "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE" = external ]; then
    [ "$(basename "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE")" = \
        DeveloperToolsSupport.swiftmodule ] || {
        echo 'build_full: Preview target module basename drifted' >&2; exit 2; }
    [ "$(basename "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT")" = \
        developertoolsupport.o ] || {
        echo 'build_full: Preview target object basename drifted' >&2; exit 2; }
    [ "$(basename "$BUILD_FULL_PREVIEW_MACRO_PLUGIN")" = \
        OpenUIKitPreviewMacros-tool ] || {
        echo 'build_full: Preview host plugin basename drifted' >&2; exit 2; }
    for input in "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE" \
        "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT" \
        "$BUILD_FULL_PREVIEW_MACRO_PLUGIN"; do
        [ -f "$input" ] && [ ! -L "$input" ] || {
            echo "build_full: Preview input is not a regular non-symlink file: $input" >&2
            exit 2
        }
    done
    [ -x "$BUILD_FULL_PREVIEW_MACRO_PLUGIN" ] || {
        echo 'build_full: Preview host plugin is not executable' >&2; exit 2; }
    PREVIEW_SWIFT_FLAGS=(
        -I "$(dirname "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE")"
        -load-plugin-executable \
        "$BUILD_FULL_PREVIEW_MACRO_PLUGIN#OpenUIKitPreviewMacros"
        -j1
    )
    PREVIEW_LINK_OBJECTS=("$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT")
    PREVIEW_INPUT_STATE_BEFORE=$(
        sha256sum "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE" \
            "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT" \
            "$BUILD_FULL_PREVIEW_MACRO_PLUGIN"
    )
fi

# ---- guest root ------------------------------------------------------------
# MACHORUN defaults to the in-repo machorun/ subtree. External MACHORUN=/path
# checkouts remain overrides. The guest root is always staged from the CURRENT
# loader and userland rather than from a copy that silently goes stale. That
# mattered once already: a guest root staged before machorun's heap-below-2^47
# fix (9659e73) reproduced a bug that had been fixed upstream hours earlier.
MACHORUN=${MACHORUN:-$W/machorun}
# Agent branches that edit uikit/ (this task: RealAppProbe Focus/Hackers) have
# a different HEAD:uikit than scripts/vendor_pins.sh. The operator advances
# the pin after merge. Attest the in-repo tree we actually compile; a dirty
# uikit/ is still refused. External UIKIT checkouts keep the pin.
EXPECTED_UIKIT_TREE=$EXPECTED_INREPO_UIKIT_TREE
if vendor_is_inrepo "$W" uikit "$UIKIT"; then
    EXPECTED_UIKIT_TREE=$(git -C "$W" rev-parse --verify HEAD:uikit)
fi
assert_vendor_tree "$W" uikit "$UIKIT" "$EXPECTED_UIKIT_TREE" OpenUIKit
assert_vendor_tree "$W" machorun "$MACHORUN" "$EXPECTED_INREPO_MACHORUN_TREE" machorun
SWIFT_CORE_RUNTIME_SOURCE=${SWIFT_CORE_RUNTIME_SOURCE:-$MACHORUN/darwin/usr/lib/swift/libswiftCore.dylib}
SWIFT_CORE_RUNTIME_EXPECTED_SHA256=${SWIFT_CORE_RUNTIME_EXPECTED_SHA256:-}
# REFUSE WITHOUT THE MOUNT, rather than silently building half a root.
# Measured 2026-08-27: invoked without `-v ~/machorun:/machorun:ro`, every `-nt`
# test below compares against a path that does not exist and is therefore FALSE,
# so the loader copy AND the umbrella rebuild are both skipped -- with no error,
# exit 0, and a `render_full` that links fine against whatever the root happened
# to contain. That is the same class as the half-and-half root the comment above
# describes, except it leaves no trace at all. The docs' own §5 reproduce command
# omitted the mount, so this was reachable by following the instructions.
for req in "$MACHORUN/build/machorun" \
    "$MACHORUN/darwin/usr/lib/libSystem.B.dylib" \
    "$SWIFT_CORE_RUNTIME_SOURCE"; do
    [ -e "$req" ] && continue
    cat >&2 <<EOF

build_full: REFUSING TO BUILD -- $req is missing.

  MACHORUN=$MACHORUN does not look like a built machorun tree. Without it every
  freshness test below is silently FALSE and the loader + umbrella steps are
  skipped, producing a guest root assembled from whatever was already on disk.

  In-repo default is $W/machorun (build products live at machorun/build and
  machorun/darwin/usr). Build that tree, or set MACHORUN to a built checkout.
EOF
    exit 2
done
[ -f "$SWIFT_CORE_RUNTIME_STAGER" ] && [ ! -L "$SWIFT_CORE_RUNTIME_STAGER" ] \
    || { echo "build_full: Swift core runtime stager is missing: $SWIFT_CORE_RUNTIME_STAGER" >&2; exit 2; }
if [ -z "$SWIFT_CORE_RUNTIME_EXPECTED_SHA256" ]; then
    SWIFT_CORE_RUNTIME_EXPECTED_SHA256=$(sha256sum \
        "$SWIFT_CORE_RUNTIME_SOURCE" | awk '{print $1}')
fi
[ "${#SWIFT_CORE_RUNTIME_EXPECTED_SHA256}" -eq 64 ] \
    || { echo 'build_full: Swift core expected SHA-256 must be lowercase 64-hex' >&2; exit 2; }
case "$SWIFT_CORE_RUNTIME_EXPECTED_SHA256" in
    *[!0-9a-f]*)
        echo 'build_full: Swift core expected SHA-256 must be lowercase 64-hex' >&2
        exit 2 ;;
esac
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
# Restage when the loader OR any base runtime input's CONTENT changes.
# Measured 2026-09-03 (x86_64, main 3ed87cab): the BASE root's libswiftcompat
# was rebuilt at 11:47 from the current source, but mrroot_full kept the 08:33
# copy because only the loader's mtime was consulted; FoundationEssentials
# then linked against a shim that no longer matched arm64's.
# Existence and -nt are not a key: stamp_key hashes the loader + compat +
# overlay dylibs (except libswiftCore, which is staged separately).
base_runtime_key() {
    local f
    set -- "$MACHORUN/build/machorun" \
        "$BASE_RUNTIME_SOURCE/darwin/usr/lib/libswiftcompat.dylib"
    for f in "$BASE_RUNTIME_SOURCE/darwin/usr/lib/swift/"*.dylib; do
        [ -e "$f" ] || continue
        [ "$(basename "$f")" = libswiftCore.dylib ] && continue
        set -- "$@" "$f"
    done
    stamp_key "$ROOTDIR/machorun" "$@"
}
_base_runtime_stamp_key=$(base_runtime_key)
if stamp_reuse "$ROOTDIR/machorun" "$_base_runtime_stamp_key"; then
    echo "build_full: guest root reused stamp=$(stamp_short "$_base_runtime_stamp_key")" >&2
else
    stamp_rebuild_reason "$ROOTDIR/machorun" "$_base_runtime_stamp_key"
    echo "== staging guest root from $MACHORUN"
    mkdir -p "$ROOTDIR/darwin/usr/lib/swift"
    cp "$MACHORUN/build/machorun" "$ROOTDIR/machorun"
    # ObjectiveC/Concurrency and the Foundation/CoreFoundation loud-abort stubs
    # come from the explicit spike runtime. libswiftCore comes from the current
    # machorun runtime below: the SDK TBD and compiler can promise availability
    # entry points that an older spike copy does not implement, and Mach-O
    # two-level binding makes a same-named export in another image irrelevant.
    [ -d "$BASE_RUNTIME_SOURCE/darwin/System" ] && cp -R "$BASE_RUNTIME_SOURCE/darwin/System" "$ROOTDIR/darwin/"
    for runtime in "$BASE_RUNTIME_SOURCE/darwin/usr/lib/swift/"*.dylib; do
        [ "$(basename "$runtime")" = libswiftCore.dylib ] && continue
        cp "$runtime" "$ROOTDIR/darwin/usr/lib/swift/"
    done
    cp "$BASE_RUNTIME_SOURCE/darwin/usr/lib/libswiftcompat.dylib" "$ROOTDIR/darwin/usr/lib/"
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
    chmod a+x "$ROOTDIR/machorun" || true
    stamp_write "$ROOTDIR/machorun" "$_base_runtime_stamp_key"
fi

# Synchronise every runtime independently of the root-staging condition above.
# ObjectiveC/Concurrency remain recorded spike inputs. libswiftCore is the
# current canonical machorun input and is synchronised separately so an old
# spike copy can never silently overwrite its SDK-facing ABI.
for d in "$BASE_RUNTIME_SOURCE/darwin/usr/lib/swift/"*.dylib; do
    [ -f "$d" ] || { echo "build_full: no staged Swift runtime dylibs in $BASE_RUNTIME_SOURCE" >&2; exit 2; }
    [ "$(basename "$d")" = libswiftCore.dylib ] && continue
    target="$ROOTDIR/darwin/usr/lib/swift/$(basename "$d")"
    if ! cmp -s "$d" "$target"; then
        echo "== restaging $(basename "$d") from scratch/mrroot"
        cp "$d" "$target"
    fi
done
swift_core_target=$ROOTDIR/darwin/usr/lib/swift/libswiftCore.dylib
echo '== staging libswiftCore.dylib from current machorun runtime'
python3 -B "$SWIFT_CORE_RUNTIME_STAGER" \
    --canonical "$SWIFT_CORE_RUNTIME_SOURCE" \
    --base "$BASE_RUNTIME_SOURCE/darwin/usr/lib/swift/libswiftCore.dylib" \
    --destination "$swift_core_target" \
    --expected-sha256 "$SWIFT_CORE_RUNTIME_EXPECTED_SHA256" \
    --report "$OUT/swift-core-runtime-stage.json"
require_macho_cpu "$swift_core_target" "staged libswiftCore.dylib" \
    || die "refusing to keep a libswiftCore.dylib whose Mach-O CPU is not $OTOOL_CPU (would mix $ARCH guests with a foreign slice)"
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
    require_macho_cpu "$target" "FE overlay $name" \
        || die "FE overlay $name is not $OTOOL_CPU Mach-O (arm64 simruntime dylibs cannot be copied into an x86 mrroot)"
done

# The Darwin dispatch bridge deliberately crosses into a small, versioned
# Linux host boundary. Stage that boundary into the same private guest root so
# a cold runtime never depends on an unrelated package path or image-global
# preload. Keep the list closed: adding a host library is an ABI decision.
HOST_RUNTIME_FILES=(
    libdispatch.so
    libBlocksRuntime.so
    libOpenDispatchHost.so
    libOpenFoundationInternationalizationHost.so
    libOpenURLTransportHost.so
    libOpenRelativeTimeHost.so
)
echo "== staging Linux host runtime boundary"
rm -rf -- "$ROOTDIR/host"
mkdir -p "$ROOTDIR/host"
for name in "${HOST_RUNTIME_FILES[@]}"; do
    source="$BASE_RUNTIME_SOURCE/host/$name"
    [ -f "$source" ] && [ ! -L "$source" ] || {
        echo "build_full: missing regular host runtime input: $source" >&2
        exit 2
    }
    cp "$source" "$ROOTDIR/host/$name"
done

# A true iOS-simulator build uses the same ARM64 runtime implementation through
# machorun, but every staged copy must advertise the target platform to LLD.
# Retarget only the fresh private guest root; immutable runtime inputs remain
# byte-for-byte untouched.
retarget_runtime_macho() {
    [ "$LINK_PLATFORM" = ios-simulator ] || return 0
    python3 -B "$W/full/scripts/retarget_macho_build_version.py" \
        --platform 7 --minimum-os "$MINOS" --sdk "$LINK_SDK_VERSION" "$@"
}
if [ "$LINK_PLATFORM" = ios-simulator ]; then
    echo '== retargeting private runtime copies to iOS Simulator'
    while IFS= read -r -d '' candidate; do
        case "$(file -b "$candidate")" in
            Mach-O*) retarget_runtime_macho "$candidate" ;;
        esac
    done < <(find "$ROOTDIR/darwin" -type f -print0)
fi

# Keep the extensionless Foundation/CoreFoundation loud-abort stubs in step
# independently of loader freshness too.  They are real transitive load
# inputs of the staged Swift runtime, but the old root manifest only enumerated
# *.dylib and therefore could neither notice their absence nor their drift.
for framework in Foundation CoreFoundation; do
    source="$BASE_RUNTIME_SOURCE/darwin/System/Library/Frameworks/$framework.framework/$framework"
    target="$ROOTDIR/darwin/System/Library/Frameworks/$framework.framework/$framework"
    [ -f "$source" ] && [ ! -L "$source" ] || {
        echo "build_full: no regular staged $framework loud-abort stub in $BASE_RUNTIME_SOURCE" >&2
        exit 2
    }
    mkdir -p "$(dirname "$target")"
    if ! cmp -s "$source" "$target"; then
        echo "== restaging $framework loud-abort stub from scratch/mrroot"
        cp "$source" "$target"
    fi
    # The source snapshot is a macOS Mach-O.  Retarget after the freshness
    # copy (rather than only in the earlier whole-root pass), otherwise every
    # clean build silently puts platform 1 back into these two transitive
    # runtime images immediately after it converted the root to platform 7.
    retarget_runtime_macho "$target"
done

# ---- libSystem / libc++ umbrellas -----------------------------------------
# ONE umbrella per library, over machorun's CURRENT dylib, carrying BOTH sets
# of additions:
#   spike/syspatch.c + full/shims/libsystem_math_compat.c + spike/cxxpatch.cpp
#                                             the staged Apple Swift runtime and
#                                             CGFloat tgmath symbols
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
    retarget_runtime_macho "$LIB/libSystem.real.dylib"
    retarget_runtime_macho "$LIB/libc++.real.dylib"

    "${CC[@]}" -O1 -c -o "$OUT/syspatch.o"  "$W/spike/syspatch.c"
    "${CC[@]}" -O1 -c -o "$OUT/mathpatch.o" \
        "$W/full/shims/libsystem_math_compat.c"
    "${CC[@]}" -O1 -c -o "$OUT/concpatch.o" "$W/full/shims/concpatch.c"
    clang-18 -target "$TARGET" -isysroot "$SYS" -O1 -std=c++17 \
        -fno-exceptions -nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1 \
        -c -o "$OUT/cxxpatch.o" "$W/spike/cxxpatch.cpp"
    clang-18 -target "$TARGET" -isysroot "$SYS" -O1 -std=c++17 \
        -fno-exceptions -fno-rtti -nostdinc++ -isystem /usr/lib/llvm-18/include/c++/v1 \
        -c -o "$OUT/conccxx.o" "$W/full/shims/conccxx.cpp"

    ld64.lld-18 -arch "$ARCH" -platform_version "$LINK_PLATFORM" "$MINOS" "$LINK_SDK_VERSION" -syslibroot "$ROOTDIR/darwin" \
        -dylib -install_name /usr/lib/libSystem.B.dylib -undefined dynamic_lookup \
        -o "$LIB/libSystem.B.dylib" "$OUT/syspatch.o" "$OUT/mathpatch.o" "$OUT/concpatch.o" \
        -reexport_library "$LIB/libSystem.real.dylib"
    ld64.lld-18 -arch "$ARCH" -platform_version "$LINK_PLATFORM" "$MINOS" "$LINK_SDK_VERSION" -syslibroot "$ROOTDIR/darwin" \
        -dylib -install_name /usr/lib/libc++.1.dylib -undefined dynamic_lookup \
        -o "$LIB/libc++.1.dylib" "$OUT/cxxpatch.o" "$OUT/conccxx.o" \
        "$LIB/libSystem.B.dylib" -reexport_library "$LIB/libc++.real.dylib"

    # A second libSystem, identical plus full/shims/lowheap.c, kept alongside
    # rather than installed. See that file's header: it is a FAILED experiment,
    # retained so the next person does not repeat it.
    "${CC[@]}" -O1 -c -o "$OUT/lowheap.o" "$W/full/shims/lowheap.c"
    ld64.lld-18 -arch "$ARCH" -platform_version "$LINK_PLATFORM" "$MINOS" "$LINK_SDK_VERSION" -syslibroot "$ROOTDIR/darwin" \
        -dylib -install_name /usr/lib/libSystem.B.dylib -undefined dynamic_lookup \
        -o "$LIB/libSystem.B.lowheap.dylib" "$OUT/syspatch.o" "$OUT/mathpatch.o" "$OUT/concpatch.o" "$OUT/lowheap.o" \
        -reexport_library "$LIB/libSystem.real.dylib"

    # The umbrella must DEFINE the symbols that are its whole reason to exist.
    # _nan / _remquo come from full/shims/libsystem_math_compat.c. Discriminator
    # used to be __NSGetMachExecuteHeader; that moved into machorun's libSystem
    # (darwin/src/objcsupport.c). A definition here would beat libSystem.real,
    # so the umbrella must NOT define it.
    for sym in _nan _remquo; do
        llvm-nm-18 --extern-only --defined-only "$LIB/libSystem.B.dylib" 2>/dev/null \
            | awk -v s="$sym" '$NF==s{f=1} END{exit !f}' || {
            echo "build_full: the libSystem umbrella does not define $sym -- it is not an umbrella, it is a copy" >&2
            exit 1; }
    done
    # awk consumes the whole listing: `grep -q` exits at the first match and the
    # still-writing nm takes SIGPIPE, which pipefail reports as failure (measured
    # 2026-09-03 on both boxes: the symbol was present and the check still failed).
    llvm-nm-18 --extern-only --defined-only "$LIB/libSystem.real.dylib" 2>/dev/null \
        | awk '$NF=="__NSGetMachExecuteHeader"{f=1} END{exit !f}' || {
        echo "build_full: libSystem.real does not define __NSGetMachExecuteHeader -- it belongs in machorun, not the umbrella" >&2
        exit 1; }
    if llvm-nm-18 --extern-only --defined-only "$LIB/libSystem.B.dylib" 2>/dev/null \
            | awk '$NF=="__NSGetMachExecuteHeader"{f=1} END{exit !f}'; then
        echo "build_full: the libSystem umbrella still defines __NSGetMachExecuteHeader -- delete it from syspatch; a definition here beats .real" >&2
        exit 1
    fi
    # Overlay-surface names that moved into machorun. A copy here beats .real.
    for moved in _memset_s _qos_class_self _os_release _voucher_copy _voucher_adopt \
                 _clock_getres _vdprintf _openat _sem_open _nanf _remquof _remquol _nanl; do
        if llvm-nm-18 --extern-only --defined-only "$LIB/libSystem.B.dylib" 2>/dev/null \
                | awk -v s="$moved" '$NF==s{f=1} END{exit !f}'; then
            echo "build_full: the libSystem umbrella still defines $moved -- delete it from concpatch; a definition here beats .real" >&2
            exit 1
        fi
        llvm-nm-18 --extern-only --defined-only "$LIB/libSystem.real.dylib" 2>/dev/null \
            | awk -v s="$moved" '$NF==s{f=1} END{exit !f}' || {
            echo "build_full: libSystem.real does not define $moved -- it belongs in machorun, not the umbrella" >&2
            exit 1; }
    done
    # Mach-O names: the C objects _dispatch_main_q / _dispatch_source_type_timer
    # carry the leading underscore twice (measured on the arm64 umbrella:
    # __dispatch_main_q, __dispatch_source_type_timer).
    for dsym in _dispatch_async_f _dispatch_get_global_queue _dispatch_main \
                __dispatch_main_q __dispatch_source_type_timer; do
        llvm-nm-18 --extern-only --defined-only "$LIB/libSystem.B.dylib" 2>/dev/null \
            | awk -v s="$dsym" '$NF==s{f=1} END{exit !f}' || {
            echo "build_full: the libSystem umbrella does not define $dsym -- overlay LINK advertises umbrella own-defs" >&2
            exit 1; }
        if llvm-nm-18 --extern-only --defined-only "$LIB/libSystem.real.dylib" 2>/dev/null \
                | awk -v s="$dsym" '$NF==s{f=1} END{exit !f}'; then
            echo "build_full: libSystem.real defines $dsym -- that is a second definition; keep it in concpatch only" >&2
            exit 1
        fi
    done
    echo "   umbrella libSystem.B: $(llvm-nm-18 --extern-only --defined-only "$LIB/libSystem.B.dylib" | wc -l) own defs (incl. _nan,_remquo, dispatch_*; overlay libSystem names live in .real), reexporting libSystem.real"

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
    printf 'copy\tdarwin/usr/lib/swift/libswiftCore.dylib\tdarwin/usr/lib/swift/libswiftCore.dylib\n'
    for n in libswiftObjectiveC.dylib libswift_Concurrency.dylib; do
        source="$BASE_RUNTIME_SOURCE/darwin/usr/lib/swift/$n"
        source_sha=$(shasum -a 256 "$source" | cut -d' ' -f1)
        printf 'staged\tdarwin/usr/lib/swift/%s\t%s\t%s\n' "$n" "$source_sha" "$source"
    done
    for n in "${FE_OVERLAYS[@]}"; do
        source="$FE_RUNTIME_SOURCE/darwin/usr/lib/swift/$n"
        source_sha=$(shasum -a 256 "$source" | cut -d' ' -f1)
        printf 'staged\tdarwin/usr/lib/swift/%s\t%s\t%s\n' "$n" "$source_sha" "$source"
    done
    for framework in Foundation CoreFoundation; do
        source="$BASE_RUNTIME_SOURCE/darwin/System/Library/Frameworks/$framework.framework/$framework"
        source_sha=$(shasum -a 256 "$source" | cut -d' ' -f1)
        printf 'staged\tdarwin/System/Library/Frameworks/%s.framework/%s\t%s\t%s\n' \
            "$framework" "$framework" "$source_sha" "$source"
    done
    for n in "${HOST_RUNTIME_FILES[@]}"; do
        source="$BASE_RUNTIME_SOURCE/host/$n"
        source_sha=$(shasum -a 256 "$source" | cut -d' ' -f1)
        printf 'staged\thost/%s\t%s\t%s\n' "$n" "$source_sha" "$source"
    done
    printf 'renamed\tdarwin/usr/lib/libSystem.real.dylib\tdarwin/usr/lib/libSystem.B.dylib\n'
    printf 'renamed\tdarwin/usr/lib/libc++.real.dylib\tdarwin/usr/lib/libc++.1.dylib\n'
    printf 'umbrella\tdarwin/usr/lib/libSystem.B.dylib\t-\t_nan,_remquo\tdarwin/usr/lib/libSystem.real.dylib\tspike/syspatch.c\tfull/shims/libsystem_math_compat.c\tfull/shims/concpatch.c\n'
    printf 'umbrella\tdarwin/usr/lib/libc++.1.dylib\t-\t-\tdarwin/usr/lib/libc++.real.dylib\tspike/cxxpatch.cpp\tfull/shims/conccxx.cpp\n'
    printf 'local\tdarwin/usr/lib/libquartz.dylib\tdarwin/usr/lib/libquartz.dylib\tbuilt from /uikit Sources/CQuartz; machorun'"'"'s copy is an older sync without the codec entry points\n'
    printf 'local\tdarwin/usr/lib/libSystem.B.lowheap.dylib\t-\ta FAILED experiment kept deliberately; see full/shims/lowheap.c\n'
} > "$ROOTDIR/.manifest"

# Reduced form for hosts that cannot finish quartz / OpenUIKit / UIHelpers
# (Cursor x86 install is PHASE2_RUNGS=a). Same guest-root copy, loud-abort
# Foundation slots from BASE, and umbrella split as a full run; stop before
# libquartz from /uikit. BUILD_FULL_THROUGH=all (default) continues.
case "${BUILD_FULL_THROUGH:-all}" in
    umbrellas)
        echo "build_full: stopping after umbrellas (BUILD_FULL_THROUGH=umbrellas) root=$ROOTDIR"
        exit 0
        ;;
    all) ;;
    *)
        echo "build_full: invalid BUILD_FULL_THROUGH=${BUILD_FULL_THROUGH} (want all|umbrellas)" >&2
        exit 2
        ;;
esac

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
ld64.lld-18 -dylib -arch "$ARCH" -platform_version "$LINK_PLATFORM" "$MINOS" "$LINK_SDK_VERSION" \
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

# DeveloperToolsSupport is a real target-side framework dependency of the
# canonical UIKit shim. External mode injects an already-attested module/object
# plus its matching host macro plugin. Standalone mode compiles the exact
# canonical target source here and links it into both proof binaries. Disabled
# mode intentionally does neither; its ownership token is accepted only for the
# core-package route that builds DTS after the Foundation visibility boundary.
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
    "${APPLE_SWIFT_OVERLAY_FLAGS[@]}" \
    -parse-as-library \
    -emit-module -emit-module-path "$FE_OUT/FoundationEssentials.swiftmodule" \
    -c -o "$FE_OUT/FoundationEssentials.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O1 -nostdinc \
    -DOPEN_FOUNDATION_UUID_COMPAT=1 \
    -c "$W/full/foundation/fm_unimplemented.c" -o "$FE_OUT/fm_unimplemented.o"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$W/full/foundation" \
    "$W/full/foundation/removefile_compat.c" \
    "$W/full/foundation/removefile_compat_tests.c" \
    -o "$FE_OUT/removefile_compat_tests"
"$FE_OUT/removefile_compat_tests" \
    | tee "$FE_OUT/removefile-compat-tests.log"
grep -Fxq 'OPEN_FOUNDATION_REMOVEFILE_OK recursive=depth-first symlink=no-follow keep-parent=yes callbacks=confirm,error,status cancellation=honored secure=refused' \
    "$FE_OUT/removefile-compat-tests.log" || {
        echo 'build_full: removefile semantic proof marker is missing' >&2
        exit 2
    }
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -Wall -Wextra -Werror -I "$W/full/foundation" \
    -c "$W/full/foundation/removefile_compat.c" \
    -o "$FE_OUT/removefile_compat.o"
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
    "$FE_OUT/removefile_compat.o"
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

# The narrow Foundation identity module is physically built now so canonical
# DeveloperToolsSupport can use OpenUIKit's exact Bundle. It remains invisible
# to the UIKit invocation below because APPINC is deliberately absent from
# that command's search path; the Foundation-hidden UIKit branch is therefore
# still a compile-time property rather than an ordering accident.
echo "== app-only Foundation identity shim"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT" \
    -module-name Foundation -emit-module -emit-module-path "$APPINC/Foundation.swiftmodule" \
    -emit-object -o "$OUT/foundation.o" \
    "$W/full/appshim/Foundation.swift" \
    "$W/full/appshim/FoundationOpenUIKitAliases.swift"

if [ "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE" = standalone ]; then
    DTS_OUT=$OUT/developertoolsupport
    mkdir -p "$DTS_OUT"
    echo "== DeveloperToolsSupport (canonical target module)"
    "${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
        -I "$OUT" -I "$APPINC" \
        -module-name DeveloperToolsSupport \
        -emit-module -emit-module-path "$DTS_OUT/DeveloperToolsSupport.swiftmodule" \
        -emit-object -o "$DTS_OUT/developertoolsupport.o" \
        "$UIKIT/Sources/DeveloperToolsSupport/Preview.swift"
    PREVIEW_SWIFT_FLAGS=(-I "$DTS_OUT")
    PREVIEW_LINK_OBJECTS=("$DTS_OUT/developertoolsupport.o")
fi

echo "== literal UIKit shim (FoundationEssentials branch, actual /uikit source)"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
    "${PREVIEW_SWIFT_FLAGS[@]}" -I "$OUT" \
    -module-name UIKit -emit-module -emit-module-path "$UIKITINC/UIKit.swiftmodule" \
    -emit-object -o "$OUT/uikitshim.o" "$UIKIT/Sources/UIKitShim/UIKit.swift"

# Compile the app-shaped proof while no Foundation module is visible. Its only
# import is UIKit; qualified FE/OpenUIKit conversions prove re-export and exact
# identity rather than merely checking that an unqualified spelling exists.
echo "== literal UIKit IndexPath compile proof"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
    "${PREVIEW_SWIFT_FLAGS[@]}" \
    -I "$OUT" -I "$UIKITINC" -module-name LiteralUIKitIndexPathProbe \
    -emit-object -o "$OUT/literal_uikit_indexpath_probe.o" \
    "$W/full/foundation/literal_uikit_indexpath_probe.swift"

# The original vendored probe consumes the already-built narrow Foundation
# identity module. UIKit above could not see it, preserving the deliberate
# Foundation-hidden identity/legacy-renderer boundary.
echo "== RealAppProbe (UNMODIFIED app source)"

# Three files preserve the source-level split found in real apps: a
# Foundation-only extension, a UIKit-only consumer, and a direct dual import.
# Metatype assignments make every identity mismatch fail at its own named
# source line; the extension lookup separately proves Notification.Name is
# shared rather than merely source-compatible.
echo "== Foundation/UIKit notification identity compile proof"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
    "${PREVIEW_SWIFT_FLAGS[@]}" \
    -I "$OUT" -I "$UIKITINC" -I "$APPINC" \
    -module-name NotificationGuestIdentityProbe -typecheck \
    "$W/full/foundation/notification_foundation_extension_probe.swift" \
    "$W/full/foundation/notification_uikit_consumer_probe.swift" \
    "$W/full/foundation/notification_direct_import_probe.swift"

# ---- app-facing Combine / SwiftUI / Foundation (APPINC only) --------------
# MEASURED: a module named Foundation on the LIBRARY search path flips
# OpenUIKit's 33 canImport(Foundation) guards (full/appshim/Foundation.swift).
# UIKit and OpenUIKit invocations above keep their include roots. Everything
# below is emitted into APPINC / APPMODS, which those invocations never saw.
#
# Combine + SwiftUI match the widget-gate sources (full/oracle-opencombine,
# Sources/SwiftUI). Foundation is the core-guest 38-file facade
# (full/foundation/foundation_guest_sources.txt), compiled after Combine,
# Dispatch and FoundationInternationalization exist — the same order as
# full/frameworks/build_core_guest_package.sh after it calls this script.
APPMODS=$OUT/appmods
OPENCOMBINE_ROOT=${OPENCOMBINE_ROOT:-$W/scratch/opencombine-core-durable-20260828-r2}
OPENCOMBINE_ARTIFACTS=${OPENCOMBINE_ARTIFACTS:-$OPENCOMBINE_ROOT/export${FULL_OUT_SUFFIX}/artifacts}
OPENCOMBINE_SOURCE=$OPENCOMBINE_ROOT/source
OPENCOMBINE_HELPERS=$OPENCOMBINE_SOURCE/Sources/COpenCombineHelpers
SWIFT_FOUNDATION_ICU=${SWIFT_FOUNDATION_ICU:-$W/scratch/swift-foundation-icu}
FOUNDATION_INTERNATIONALIZATION_BUILDER=$W/full/foundationinternationalization/build_foundation_internationalization.sh
FOUNDATION_GUEST_MANIFEST=$W/full/foundation/foundation_guest_sources.txt
COREFOUNDATION_GUEST_MANIFEST=$W/full/foundation/corefoundation_guest_sources.txt
EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS=19
EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS=2
EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS=0
mkdir -p "$APPMODS/include/CPortableIO" "$APPMODS/include/CSTBTrueType" \
    "$APPMODS/include/CHostClock" "$APPMODS/include/COpenCombineHelpers" \
    "$APPMODS/include/COpenDispatch" "$APPMODS/include/COpenRelativeTime" \
    "$APPMODS/include/COpenURLTransport" "$APPMODS/include/CQuartz" \
    "$APPMODS/include/CoreFoundation" "$APPMODS/include/COpenFoundationCore"
cp -a "$OUT/inc/CPortableIO/." "$APPMODS/include/CPortableIO/"
cp -a "$OUT/inc/CSTBTrueType/." "$APPMODS/include/CSTBTrueType/"
cp -a "$W/full/hostclock/include/." "$APPMODS/include/CHostClock/"
cp -a "$UIKIT/Sources/CQuartz/include/." "$APPMODS/include/CQuartz/"
cp -a "$W/full/foundation/include/COpenFoundationCore/." \
    "$APPMODS/include/COpenFoundationCore/"
cp "$OPENCOMBINE_HELPERS/include/COpenCombineHelpers.h" \
    "$OPENCOMBINE_HELPERS/include/module.modulemap" \
    "$APPMODS/include/COpenCombineHelpers/"
cp -a "$W/full/dispatch/include/." "$APPMODS/include/COpenDispatch/"
cp -a "$W/full/relativetime/include/." "$APPMODS/include/COpenRelativeTime/"
cp -a "$W/full/urltransport/include/." "$APPMODS/include/COpenURLTransport/"
cp "$W/full/foundation/include/CoreFoundation/CoreFoundation.h" \
    "$APPMODS/include/CoreFoundation/CoreFoundation.h"
cp "$W/full/foundation/include/CoreFoundation/module.modulemap" \
    "$APPMODS/include/CoreFoundation/module.modulemap"
[ -f "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" ] && \
    [ -f "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" ] \
    || die "OpenCombine artifacts missing under $OPENCOMBINE_ARTIFACTS"
cp "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" "$APPMODS/"
[ -f "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" ] && \
    cp "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" "$APPMODS/"
for module in OpenUIKit OpenCoreGraphics; do
    for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json; do
        [ -e "$OUT/$module.$suffix" ] && cp "$OUT/$module.$suffix" "$APPMODS/"
    done
done
APPMODS_CINC=(
    -Xcc -I"$APPMODS/include/CPortableIO"
    -Xcc -I"$APPMODS/include/CSTBTrueType"
    -Xcc -I"$APPMODS/include/CHostClock"
    -Xcc -fmodule-map-file="$APPMODS/include/COpenCombineHelpers/module.modulemap"
    -Xcc -I"$APPMODS/include/COpenCombineHelpers"
    -Xcc -fmodule-map-file="$APPMODS/include/COpenDispatch/module.modulemap"
    -Xcc -I"$APPMODS/include/COpenDispatch"
    -Xcc -I"$APPMODS/include/CQuartz"
    -Xcc -fmodule-map-file="$APPMODS/include/COpenFoundationCore/module.modulemap"
    -Xcc -I"$APPMODS/include/COpenFoundationCore"
    -Xcc -fmodule-map-file="$APPMODS/include/CoreFoundation/module.modulemap"
    -Xcc -I"$APPMODS/include/CoreFoundation"
    -Xcc -fmodule-map-file="$APPMODS/include/COpenURLTransport/module.modulemap"
    -Xcc -I"$APPMODS/include/COpenURLTransport"
    -Xcc -fmodule-map-file="$APPMODS/include/COpenRelativeTime/module.modulemap"
    -Xcc -I"$APPMODS/include/COpenRelativeTime"
)

echo "== package source-built OpenCombine and literal Combine (app include path)"
cp "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" "$OUT/COpenCombineHelpers.cpp"
patch --batch --forward --fuzz=0 "$OUT/COpenCombineHelpers.cpp" \
    "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch"
clang++-18 -target "$TARGET" -isysroot "$SYS" -stdlib=libc++ -std=c++17 -O2 \
    -I "$APPMODS/include/COpenCombineHelpers" \
    -c "$OUT/COpenCombineHelpers.cpp" -o "$OUT/copencombinehelpers.o"
"${LD[@]}" -dylib -install_name @rpath/libOpenCombine.dylib \
    -rpath @loader_path -ignore_auto_link -dead_strip \
    -o "$APPMODS/libOpenCombine.dylib" \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" "$OUT/copencombinehelpers.o" \
    "$SYS/usr/lib/swift/libswift_Concurrency.tbd" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$ROOTDIR/darwin/usr/lib/libc++abi.dylib" \
    "$SYS/usr/lib/libSystem.tbd" "$ROOTDIR/darwin/usr/lib/libSystem.real.dylib" \
    "$SYS/usr/lib/libobjc.tbd"
"${SWIFTC[@]}" -parse-as-library "${APPMODS_CINC[@]}" "${FEMODULES[@]}" \
    -I "$APPMODS" \
    -module-name Combine -emit-module -emit-module-path "$APPMODS/Combine.swiftmodule" \
    -emit-object -o "$OUT/combine.o" \
    "$W/full/oracle-opencombine/Combine.swift"
"${LD[@]}" -dylib -install_name @rpath/libCombine.dylib \
    -rpath @loader_path -ignore_auto_link -dead_strip \
    -reexport_library "$APPMODS/libOpenCombine.dylib" \
    -o "$APPMODS/libCombine.dylib" "$OUT/combine.o" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" "$SYS/usr/lib/libSystem.tbd"
cp "$APPMODS/Combine.swiftmodule" "$APPINC/"
cp "$APPMODS/OpenCombine.swiftmodule" "$APPINC/"
cp "$APPMODS/libCombine.dylib" "$APPMODS/libOpenCombine.dylib" "$OUT/"

echo "== compile the first-party Symbols value model while Foundation is the DTS shim"
mapfile -d '' -t SYMBOLS_SOURCES < <(
    find "$UIKIT/Sources/Symbols" -maxdepth 1 -type f -name '*.swift' \
        -print0 | LC_ALL=C sort -z
)
"${SWIFTC[@]}" -parse-as-library -I "$APPMODS" \
    -module-name Symbols \
    -emit-module -emit-module-path "$APPMODS/Symbols.swiftmodule" \
    -emit-object -o "$OUT/symbols.o" \
    "${SYMBOLS_SOURCES[@]}"
cp "$APPMODS/Symbols.swiftmodule" "$APPINC/"

echo "== compile SwiftUI without APPINC (Foundation still the DTS identity shim)"
# Widget-gate order: SwiftUI is compiled while the app-facing Foundation
# facade does not sit on this invocation's search path. Hosting.swift's
# UIHostingController is not behind canImport(Foundation); the later
# overwrite of APPINC must not flip this compile.
mapfile -d '' -t SWIFTUI_SOURCES < <(
    find "$UIKIT/Sources/SwiftUI" -maxdepth 1 -type f -name '*.swift' \
        -print0 | LC_ALL=C sort -z
)
[ "${#SWIFTUI_SOURCES[@]}" -gt 0 ] \
    || die "SwiftUI source inventory is empty"
"${SWIFTC[@]}" -parse-as-library "${APPMODS_CINC[@]}" "${FEMODULES[@]}" \
    -I "$OUT" -I "$APPMODS" \
    -module-name SwiftUI -emit-module -emit-module-path "$APPMODS/SwiftUI.swiftmodule" \
    -emit-object -o "$OUT/swiftui.o" \
    "${SWIFTUI_SOURCES[@]}"
cp "$APPMODS/SwiftUI.swiftmodule" "$APPINC/"

echo "== Mach-O bridges for Dispatch, URL transport, relative time"
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$APPMODS/include/COpenDispatch" \
    -c "$W/full/dispatch/OpenDispatchBridge.c" \
    -o "$OUT/open-dispatch-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenDispatch.dylib \
    -o "$ROOTDIR/darwin/usr/lib/libOpenDispatch.dylib" \
    "$OUT/open-dispatch-bridge.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$APPMODS/include/COpenURLTransport" \
    -c "$W/full/urltransport/OpenURLTransportBridge.c" \
    -o "$OUT/open-url-transport-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenURLTransport.dylib \
    -o "$ROOTDIR/darwin/usr/lib/libOpenURLTransport.dylib" \
    "$OUT/open-url-transport-bridge.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$APPMODS/include/COpenRelativeTime" \
    -c "$W/full/relativetime/OpenRelativeTimeBridge.c" \
    -o "$OUT/open-relative-time-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenRelativeTime.dylib \
    -o "$ROOTDIR/darwin/usr/lib/libOpenRelativeTime.dylib" \
    "$OUT/open-relative-time-bridge.o"

echo "== compile the project Dispatch module before the Foundation umbrella"
"${SWIFTC[@]}" -parse-as-library "${APPMODS_CINC[@]}" \
    -I "$APPMODS" \
    -module-name Dispatch -emit-module \
    -emit-module-path "$APPMODS/Dispatch.swiftmodule" \
    -emit-object -o "$OUT/dispatch.o" "$W/full/dispatch/Dispatch.swift"
"${LD[@]}" -dylib -dead_strip -ignore_auto_link -undefined dynamic_lookup \
    -install_name @rpath/libDispatch.dylib -rpath @loader_path \
    -o "$APPMODS/libDispatch.dylib" \
    "$OUT/dispatch.o" "$ROOTDIR/darwin/usr/lib/libOpenDispatch.dylib" \
    -L"$APPMODS" -lOpenCombine \
    -L"$ROOTDIR/darwin/usr/lib" -L/usr/lib/swift \
    -lswiftCore \
    "$SYS/usr/lib/swift/libswiftSynchronization.tbd" \
    "$SYS/usr/lib/swift/libswift_Concurrency.tbd" \
    "$ROOTDIR/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib"
cp "$APPMODS/Dispatch.swiftmodule" "$APPINC/"
cp "$APPMODS/libDispatch.dylib" "$OUT/"

echo "== compile first-party CoreFoundation before the Foundation umbrella"
mapfile -t COREFOUNDATION_GUEST_RELATIVE_SOURCES < "$COREFOUNDATION_GUEST_MANIFEST"
COREFOUNDATION_GUEST_SOURCES=()
for relative in "${COREFOUNDATION_GUEST_RELATIVE_SOURCES[@]}"; do
    COREFOUNDATION_GUEST_SOURCES+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${APPMODS_CINC[@]}" "${FEMODULES[@]}" \
    -I "$APPMODS" -module-name CoreFoundation \
    -emit-module -emit-module-path "$APPMODS/CoreFoundation.swiftmodule" \
    -emit-object -o "$OUT/corefoundation.o" \
    "${COREFOUNDATION_GUEST_SOURCES[@]}"
cp "$APPMODS/CoreFoundation.swiftmodule" "$APPINC/"

echo "== build pinned FoundationInternationalization (core-guest ICU closure)"
[ -f "$FOUNDATION_INTERNATIONALIZATION_BUILDER" ] \
    || die "FoundationInternationalization builder missing"
"${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libFoundationEssentials.dylib -rpath @loader_path \
    -L"$ROOTDIR/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$ROOTDIR/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib" \
    -o "$APPMODS/libFoundationEssentials.dylib" \
    "${FE_OBJECTS[@]}" "$OUT/swiftcorepatch.o"
for fe_artifact in FoundationEssentials.swiftmodule FoundationEssentials.swiftdoc; do
    [ -f "$FE_OUT/$fe_artifact" ] || die "missing $FE_OUT/$fe_artifact"
    cp "$FE_OUT/$fe_artifact" "$APPMODS/$fe_artifact"
done
FINTL_STAGE=$OUT/fi-stage
FINTL_WORK=$OUT/fi-work
rm -rf -- "$FINTL_STAGE" "$FINTL_WORK"
mkdir -p "$FINTL_STAGE/guest-root/host" \
    "$FINTL_STAGE/guest-root/darwin/usr/lib" \
    "$FINTL_STAGE/include" \
    "$FINTL_STAGE/attestation" \
    "$FINTL_WORK"
ln -sfn "$SYS" "$FINTL_STAGE/sdk"
ln -sfn "$APPMODS" "$FINTL_STAGE/lib"
ln -sfn "$APPMODS" "$FINTL_STAGE/modules"
mkdir -p "$FINTL_STAGE/include/_FoundationCShims"
cp -a "$SF/Sources/_FoundationCShims/include/." \
    "$FINTL_STAGE/include/_FoundationCShims/"
for fi_runtime in libc++.1.dylib libc++.real.dylib libc++abi.dylib \
    libSystem.B.dylib libSystem.real.dylib libswiftcompat.dylib; do
    [ -e "$ROOTDIR/darwin/usr/lib/$fi_runtime" ] \
        || die "FI runtime dylib missing: $ROOTDIR/darwin/usr/lib/$fi_runtime"
    ln -s "$ROOTDIR/darwin/usr/lib/$fi_runtime" \
        "$FINTL_STAGE/guest-root/darwin/usr/lib/$fi_runtime"
done
: > "$FINTL_STAGE/guest-root/.manifest"
env SUPPORT_ROOT="$W" SWIFT_FOUNDATION="$SF" \
    SWIFT_FOUNDATION_ICU="$SWIFT_FOUNDATION_ICU" STAGE="$FINTL_STAGE" \
    WORK="$FINTL_WORK" TARGET="$TARGET" MIN_OS="$MINOS" \
    COLLECTIONS="$FE_COLLECTIONS" OSMOD="$FE_OS" CSHIMS="$FE_CSHIMS" \
    FOUNDATION_ICU_JOBS="${FOUNDATION_ICU_JOBS:-8}" \
    bash "$FOUNDATION_INTERNATIONALIZATION_BUILDER"
[ -f "$APPMODS/FoundationInternationalization.swiftmodule" ] \
    || die "FoundationInternationalization.swiftmodule missing after FI build"
cp "$APPMODS/FoundationInternationalization.swiftmodule" "$APPINC/"
cp "$APPMODS/libFoundationInternationalization.dylib" \
    "$APPMODS/lib_FoundationICU.dylib" "$OUT/"
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$W/full/foundationinternationalization/include" \
    -c "$W/full/foundationinternationalization/OpenFoundationInternationalizationBridge.c" \
    -o "$OUT/open-foundation-internationalization-bridge.o"
"${LD[@]}" -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenFoundationInternationalization.dylib \
    -o "$ROOTDIR/darwin/usr/lib/libOpenFoundationInternationalization.dylib" \
    "$OUT/open-foundation-internationalization-bridge.o"
APPMODS_CINC+=(
    -Xcc -fmodule-map-file="$FINTL_STAGE/include/FoundationICU/_foundation_unicode/module.modulemap"
    -Xcc -I"$FINTL_STAGE/include/FoundationICU"
)

echo "== compile the ordered app-facing Foundation facade into APPINC"
# Overwrites the DTS identity shim's swiftmodule. DTS.o is already compiled.
# Library/UIKit invocations above never had APPINC, so they stay Foundation-hidden.
mapfile -t FOUNDATION_GUEST_RELATIVE_SOURCES < "$FOUNDATION_GUEST_MANIFEST"
[ "${#FOUNDATION_GUEST_RELATIVE_SOURCES[@]}" -eq 38 ] \
    || die "Foundation guest source manifest must contain exactly 38 lines"
FOUNDATION_GUEST_SOURCES=()
for relative in "${FOUNDATION_GUEST_RELATIVE_SOURCES[@]}"; do
    FOUNDATION_GUEST_SOURCES+=("$W/$relative")
done
"${SWIFTC[@]}" -parse-as-library "${APPMODS_CINC[@]}" "${FEMODULES[@]}" \
    -I "$OUT" -I "$APPMODS" \
    -module-name Foundation -emit-module \
    -emit-module-path "$APPINC/Foundation.swiftmodule" \
    -emit-object -o "$OUT/foundation.o" \
    "${FOUNDATION_GUEST_SOURCES[@]}"
llvm-nm-18 -u -j "$OUT/foundation.o" | LC_ALL=C sort -u \
    > "$OUT/foundation-undefined-symbols.txt"
foundation_string_processing_undefineds=$(awk \
    'index($0, "17_StringProcessing") { count++ } END { print count + 0 }' \
    "$OUT/foundation-undefined-symbols.txt")
foundation_synchronization_undefineds=$(awk \
    'index($0, "15Synchronization") { count++ } END { print count + 0 }' \
    "$OUT/foundation-undefined-symbols.txt")
foundation_regex_parser_undefineds=$(awk \
    'index($0, "12_RegexParser") { count++ } END { print count + 0 }' \
    "$OUT/foundation-undefined-symbols.txt")
[ "$foundation_string_processing_undefineds" -eq \
    "$EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS" ] \
    || die "Foundation StringProcessing undefined count $foundation_string_processing_undefineds, expected $EXPECTED_FOUNDATION_STRING_PROCESSING_UNDEFINEDS"
[ "$foundation_synchronization_undefineds" -eq \
    "$EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS" ] \
    || die "Foundation Synchronization undefined count $foundation_synchronization_undefineds, expected $EXPECTED_FOUNDATION_SYNCHRONIZATION_UNDEFINEDS"
[ "$foundation_regex_parser_undefineds" -eq \
    "$EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS" ] \
    || die "Foundation RegexParser undefined count $foundation_regex_parser_undefineds, expected $EXPECTED_FOUNDATION_REGEX_PARSER_UNDEFINEDS"

echo "== RealAppProbe stub modules (FocusModules / HackersModules, dependency order)"
# Package.swift target graph: Glean, Intents, Onboarding have no deps;
# IntentsUI → Intents+OpenUIKit; Licenses → SwiftUI; Domain → Foundation;
# Shared → Domain+UIKit+SwiftUI+Combine; DesignSystem → Domain+Shared+SwiftUI.
# Shared and FeedViewModel use @Observable; the Darwin SDK's Observation
# module names ObservationMacros, which live in the host toolchain plugin
# (full/frameworks/build_core_guest_package.sh OBSERVATION_MACRO_PLUGIN).
swiftc_bin=$(command -v swiftc || true)
swift_usr=
if [ -n "$swiftc_bin" ]; then
    swift_usr=$(CDPATH= cd -- "$(dirname -- "$swiftc_bin")/.." && pwd -P)
fi
if [ -z "${OBSERVATION_MACRO_PLUGIN:-}" ]; then
    for cand in \
        ${swift_usr:+"$swift_usr/lib/swift/host/plugins/libObservationMacros.so"} \
        ${swift_usr:+"$swift_usr/lib/swift/host/compilerPlugins/libObservationMacros.so"} \
        /opt/swift624/usr/lib/swift/host/plugins/libObservationMacros.so \
        /opt/swift624/usr/lib/swift/host/compilerPlugins/libObservationMacros.so \
        /opt/swift/usr/lib/swift/host/plugins/libObservationMacros.so \
        /usr/lib/swift/host/plugins/libObservationMacros.so \
        /usr/lib/swift/host/compilerPlugins/libObservationMacros.so; do
        if [ -f "$cand" ]; then
            OBSERVATION_MACRO_PLUGIN=$cand
            break
        fi
    done
    if [ -z "${OBSERVATION_MACRO_PLUGIN:-}" ] && [ -n "$swift_usr" ]; then
        OBSERVATION_MACRO_PLUGIN=$(find "$swift_usr/lib" \
            \( -name 'libObservationMacros.so' -o -name 'libObservationMacros.dylib' \) \
            -print -quit 2>/dev/null || true)
    fi
fi
if [ ! -f "${OBSERVATION_MACRO_PLUGIN:-}" ]; then
    echo "build_full: ObservationMacros not at the known host-plugin paths" >&2
    echo "   swiftc=$(command -v swiftc || echo missing) swift_usr=$swift_usr" >&2
    for dir in \
        ${swift_usr:+"$swift_usr/lib/swift/host/plugins"} \
        ${swift_usr:+"$swift_usr/lib/swift/host/compilerPlugins"} \
        /opt/swift624/usr/lib/swift/host/plugins \
        /usr/lib/swift/host/plugins; do
        echo "   ls $dir:" >&2
        ls -la "$dir" 2>&1 | head -20 >&2 || true
    done
    die "ObservationMacros plugin missing (Shared @Observable)"
fi
# Stage the plugin next to its SwiftSyntax host libs, matching
# build_core_guest_package.sh. -load-plugin-library of a toolchain plugin can
# fail when the syntax .so files are not on the loader path (attempt 3 rc=1).
PLUGIN_STAGE=$OUT/host-tools/swift/host
mkdir -p "$PLUGIN_STAGE/plugins"
cp "$OBSERVATION_MACRO_PLUGIN" "$PLUGIN_STAGE/plugins/libObservationMacros.so"
plugin_host=$(CDPATH= cd -- "$(dirname -- "$OBSERVATION_MACRO_PLUGIN")/.." && pwd -P)
for lib in libSwiftSyntaxMacros.so libSwiftSyntaxBuilder.so \
    libSwiftParserDiagnostics.so libSwiftBasicFormat.so libSwiftParser.so \
    libSwiftDiagnostics.so libSwiftSyntax.so; do
    if [ -f "$plugin_host/$lib" ]; then
        cp "$plugin_host/$lib" "$PLUGIN_STAGE/$lib"
    elif [ -n "$swift_usr" ] && [ -f "$swift_usr/lib/swift/host/$lib" ]; then
        cp "$swift_usr/lib/swift/host/$lib" "$PLUGIN_STAGE/$lib"
    fi
done
OBSERVATION_MACRO_PLUGIN=$PLUGIN_STAGE/plugins/libObservationMacros.so
echo "== ObservationMacros $OBSERVATION_MACRO_PLUGIN"
OBSERVATION_PLUGIN_FLAGS=(
    -plugin-path "$PLUGIN_STAGE/plugins"
    -load-plugin-library "$OBSERVATION_MACRO_PLUGIN"
)
compile_app_module() {
    local name=$1 outfile=$2; shift 2
    echo "   module $name"
    "${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
        "${PREVIEW_SWIFT_FLAGS[@]}" "${APPMODS_CINC[@]}" \
        -I "$OUT" -I "$UIKITINC" -I "$APPINC" -I "$APPMODS" \
        -disable-availability-checking \
        "${OBSERVATION_PLUGIN_FLAGS[@]}" \
        -module-name "$name" \
        -emit-module -emit-module-path "$APPINC/$name.swiftmodule" \
        -emit-object -o "$outfile" \
        "$@"
}
compile_app_module Glean "$OUT/glean.o" \
    "$UIKIT"/Sources/RealAppProbe/FocusModules/Glean/*.swift
compile_app_module Intents "$OUT/intents_stub.o" \
    "$UIKIT"/Sources/RealAppProbe/FocusModules/Intents/*.swift
compile_app_module Onboarding "$OUT/onboarding_stub.o" \
    "$UIKIT"/Sources/RealAppProbe/FocusModules/Onboarding/*.swift
compile_app_module Domain "$OUT/domain.o" \
    "$UIKIT"/Sources/RealAppProbe/HackersModules/Domain/*.swift
compile_app_module IntentsUI "$OUT/intentsui_stub.o" \
    "$UIKIT"/Sources/RealAppProbe/FocusModules/IntentsUI/*.swift
compile_app_module Licenses "$OUT/licenses.o" \
    "$UIKIT"/Sources/RealAppProbe/FocusModules/Licenses/*.swift
compile_app_module Shared "$OUT/shared.o" \
    "$UIKIT"/Sources/RealAppProbe/HackersModules/Shared/*.swift
compile_app_module DesignSystem "$OUT/designsystem.o" \
    "$UIKIT"/Sources/RealAppProbe/HackersModules/DesignSystem/*.swift

echo "== RealAppProbe (top-level + Vendored + Vendored/* + Focus/ + Hackers/)"
# Measured glob that SwiftPM already compiles. The previous guest path
# only globbed RealAppProbe/*.swift + Vendored/*.swift, so canImport(Onboarding)
# / canImport(Domain) were false and the table stopped at 10 Pocket Casts
# screens. APPINC now has Onboarding, Domain, SwiftUI, Combine, Foundation.
APP_PROBE_SOURCES=(
    "$UIKIT"/Sources/RealAppProbe/*.swift
    "$UIKIT"/Sources/RealAppProbe/Vendored/*.swift
    "$UIKIT"/Sources/RealAppProbe/Vendored/*/*.swift
    "$UIKIT"/Sources/RealAppProbe/Focus/*.swift
    "$UIKIT"/Sources/RealAppProbe/Hackers/*.swift
)
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
    "${PREVIEW_SWIFT_FLAGS[@]}" "${APPMODS_CINC[@]}" \
    -I "$OUT" -I "$UIKITINC" -I "$APPINC" -I "$APPMODS" \
    -default-isolation MainActor -disable-availability-checking \
    -enable-upcoming-feature IsolatedDefaultValues \
    "${OBSERVATION_PLUGIN_FLAGS[@]}" \
    -module-name RealAppProbe -emit-module -emit-module-path "$OUT/RealAppProbe.swiftmodule" \
    -emit-object -o "$OUT/realappprobe.o" \
    "${APP_PROBE_SOURCES[@]}"

# The renderer sees both app include roots: RealApp.swift imports RealAppProbe,
# whose interface transitively names UIKit, Foundation, and FoundationEssentials.
echo "== renderer (SceneBuilder.swift + RealApp.swift verbatim + full/driver/main.swift)"
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" \
    "${PREVIEW_SWIFT_FLAGS[@]}" \
    -I "$OUT" -I "$UIKITINC" -I "$APPINC" -I "$APPMODS" -module-name render_full \
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
    "${PREVIEW_LINK_OBJECTS[@]}"
)
# Combine/OpenCombine/Dispatch are dylibs (widget/onboarding measured path).
# Their .o files are inside those dylibs — do not object-link them as well.
APP_LINK_OBJECTS=(
    "$OUT/symbols.o" "$OUT/swiftui.o" "$OUT/corefoundation.o"
    "$OUT/glean.o" "$OUT/intents_stub.o" "$OUT/onboarding_stub.o"
    "$OUT/domain.o" "$OUT/intentsui_stub.o" "$OUT/licenses.o"
    "$OUT/shared.o" "$OUT/designsystem.o"
)
"${LD[@]}" -dead_strip -exported_symbol __mh_execute_header -rpath @loader_path \
    -L"$ROOTDIR/darwin/usr/lib" -L"$OUT" -L"$APPMODS" \
    -L/usr/lib/swift -lswiftCore -lswift_StringProcessing -lswiftSynchronization \
    "$SWIFTCOMPAT" \
    -L/usr/lib -lSystem -lobjc "$QUARTZLIB" \
    "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib" \
    "$ROOTDIR/darwin/usr/lib/libc++.1.dylib" \
    "$ROOTDIR/darwin/usr/lib/libOpenDispatch.dylib" \
    "$ROOTDIR/darwin/usr/lib/libOpenURLTransport.dylib" \
    "$ROOTDIR/darwin/usr/lib/libOpenRelativeTime.dylib" \
    "$OUT/libCombine.dylib" "$OUT/libOpenCombine.dylib" \
    "$OUT/libDispatch.dylib" \
    "$OUT/libFoundationInternationalization.dylib" \
    "$OUT/lib_FoundationICU.dylib" \
    -o "$OUT/render_full" \
    "$OUT/render_full.o" "$OUT/realappprobe.o" "$OUT/foundation.o" \
    "${APP_LINK_OBJECTS[@]}" \
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
# @rpath dylibs the full app-facing Foundation pulls in. Probe.app runs the
# same binary from a sibling directory, so @loader_path must find them here.
for app_rpath in libCombine.dylib libOpenCombine.dylib libDispatch.dylib \
    libFoundationInternationalization.dylib lib_FoundationICU.dylib; do
    [ -f "$OUT/$app_rpath" ] && cp "$OUT/$app_rpath" "$OUT/Probe.app/"
done
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

UIHELPERS_SUBJECT_AFTER=$(bash "$W/full/scripts/uihelpers_subject.sh" \
    "$W" "$UIKIT" "$SF" "$SC")
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
PREVIEW_INPUT_STATE_AFTER='disabled'
if [ "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE" = external ]; then
    PREVIEW_INPUT_STATE_AFTER=$(
        sha256sum "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE" \
            "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT" \
            "$BUILD_FULL_PREVIEW_MACRO_PLUGIN"
    )
fi
if [ "$PREVIEW_INPUT_STATE_BEFORE" != "$PREVIEW_INPUT_STATE_AFTER" ]; then
    echo 'build_full: REFUSING -- Preview inputs changed during the build' >&2
    exit 2
fi
python3 "$FE_OBJECT_PROVENANCE_TOOL" attest \
    --project "$W" --full "$OUT" --subject "$UIHELPERS_SUBJECT_AFTER" \
    > "$OUT/foundation-fe-object-provenance.tsv.tmp"
python3 "$FE_OBJECT_PROVENANCE_TOOL" verify \
    --project "$W" --full "$OUT" --subject "$UIHELPERS_SUBJECT_AFTER" \
    --attestation "$OUT/foundation-fe-object-provenance.tsv.tmp"
{
    printf 'render_full\t%s\n' "$(sha256sum "$OUT/render_full" | awk '{print $1}')"
    printf 'indexpath_identity_probe\t%s\n' \
        "$(sha256sum "$OUT/indexpath_identity_probe" | awk '{print $1}')"
    printf 'FoundationEssentials.o\t%s\n' \
        "$(sha256sum "$FE_OUT/FoundationEssentials.o" | awk '{print $1}')"
    printf 'removefile_compat.o\t%s\n' \
        "$(sha256sum "$FE_OUT/removefile_compat.o" | awk '{print $1}')"
    printf 'removefile-compat-tests.log\t%s\n' \
        "$(sha256sum "$FE_OUT/removefile-compat-tests.log" | awk '{print $1}')"
    printf 'libquartz.dylib\t%s\n' \
        "$(sha256sum "$ROOTDIR/darwin/usr/lib/libquartz.dylib" | awk '{print $1}')"
    printf 'libSystem.B.dylib\t%s\n' \
        "$(sha256sum "$ROOTDIR/darwin/usr/lib/libSystem.B.dylib" | awk '{print $1}')"
    printf 'libc++.1.dylib\t%s\n' \
        "$(sha256sum "$ROOTDIR/darwin/usr/lib/libc++.1.dylib" | awk '{print $1}')"
    if [ "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODE" = external ]; then
        printf 'DeveloperToolsSupport.swiftmodule\t%s\n' \
            "$(sha256sum "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_MODULE" | awk '{print $1}')"
        printf 'developertoolsupport.o\t%s\n' \
            "$(sha256sum "$BUILD_FULL_DEVELOPER_TOOLS_SUPPORT_OBJECT" | awk '{print $1}')"
        printf 'OpenUIKitPreviewMacros-tool\t%s\n' \
            "$(sha256sum "$BUILD_FULL_PREVIEW_MACRO_PLUGIN" | awk '{print $1}')"
    fi
} > "$OUT/uihelpers-artifacts.sha256.tmp"
printf '%s\n' "$UIHELPERS_SUBJECT_AFTER" > "$OUT/uihelpers-subject.sha256.tmp"
# Publish the subject last: its presence is the commit marker that both the
# build and artifact/provenance manifests reached the successful end of the
# bracket.
mv "$OUT/foundation-fe-object-provenance.tsv.tmp" \
    "$OUT/foundation-fe-object-provenance.tsv"
mv "$OUT/uihelpers-artifacts.sha256.tmp" "$OUT/uihelpers-artifacts.sha256"
mv "$OUT/uihelpers-subject.sha256.tmp" "$OUT/uihelpers-subject.sha256"

echo "== done"; ls -l "$OUT/render_full" "$OUT/indexpath_identity_probe"
