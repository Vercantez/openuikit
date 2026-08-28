#!/bin/bash
# Stage a Darwin sysroot for building Foundation as Mach-O on Linux.
#
# Adapted from ~/swiftcore-macho/scripts/stage_sdk.sh. Same sysroot the Swift
# stdlib cross-build used, because Foundation must compile against exactly the
# headers libswiftCore was built against or the ObjC metadata will not line up.
#
# Inputs, all under /stage (see scripts/container.sh for how they get there):
#   machorun-sdk/   machorun's self-hosted header-only + .tbd SDK
#   objc4-runtime/  Apple objc4 runtime/ headers (NSObject.h, objc-internal.h, ...)
#   objc4-priv/     machorun's clean-room private-SPI headers
#   scf/            swift-corelibs-foundation (Apple's open-source CoreFoundation headers)
#   foundation/     swiftcore-macho's clean-room Foundation.h
#   libc/           clean-room setjmp.h / MacTypes.h
#
# Output: $W/sdk/MacOSX.sdk
set -euo pipefail
W=${W:-/work}
S=${S:-/stage}
SDK=$W/sdk/MacOSX.sdk

# ---------------------------------------------------------------------------
# PRECONDITIONS, BEFORE THE rm -rf. A GUARD THAT REFUSES AFTER DESTROYING IS
# NOT A GUARD.
#
# This script deletes $W/sdk and rebuilds it. The clean-room-header collision
# check below used to run AFTER that deletion, comparing files it had just
# copied in -- so when it fired, it exited 2 having already destroyed the SDK,
# leaving a half-built tree. Measured 2026-08-28: that is what broke the nscf
# compile, and the symptom (CF headers unable to find MacTypes types) looked
# nothing like a staging abort.
#
# Both checks now run over the INPUTS, which are readable without touching $W.
# The identical check remains in the copy loop below as a backstop; it should
# now be unreachable.

# (1) Would a clean-room libc header shadow one machorun's SDK now carries?
#     machorun's SDK grows over time -- MacTypes.h appeared in it recently --
#     so this collision is expected to APPEAR, not to be a permanent state.
: "${PREFER_MACHORUN_HEADERS:=0}"
_hdr_conflicts=""
for _h in "$S/libc/"*.h; do
    [ -e "$_h" ] || continue
    _b=${_h##*/}
    [ -e "$S/machorun-sdk/usr/include/$_b" ] && _hdr_conflicts="$_hdr_conflicts $_b"
done
if [ -n "$_hdr_conflicts" ] && [ "$PREFER_MACHORUN_HEADERS" != 1 ]; then
    echo "stage_sdk: machorun's SDK now carries headers our clean-room set also has:" >&2
    echo "          $_hdr_conflicts" >&2
    echo "  A shadowing copy cannot fail, so this refuses rather than overwrites." >&2
    echo "  NOTHING HAS BEEN DELETED -- \$W/sdk is untouched." >&2
    echo >&2
    echo "  Resolve one of two ways:" >&2
    echo "    - delete the clean-room copy from \$SWIFTCORE/sdk/libc (the real" >&2
    echo "      one is machorun's, and two definitions is the whole hazard), or" >&2
    echo "    - PREFER_MACHORUN_HEADERS=1 $0   to keep machorun's and skip ours." >&2
    exit 2
fi

# (2) Would restoring the snapshot's dylibs replace something different in $W?
#     /stage is a SNAPSHOT from container-creation time; the sibling repos move
#     on. Copying it over $W unconditionally is how a freshly built libSystem
#     got silently reverted together with its .tbd -- mutually consistent,
#     jointly stale, and with fresh mtimes, which defeats both a consistency
#     check and a timestamp check. From inside the container ~/machorun is not
#     mounted, so this cannot ask which is newer; it asks the answerable
#     question: am I about to replace something DIFFERENT from what I hold?
#     First-time staging (nothing in $W yet) is not a downgrade and never trips.
: "${FORCE_STAGE:=0}"
_lib_conflicts=""
for _f in "$S/darwinlib/"*.dylib; do
    [ -e "$_f" ] || continue
    _w="$W/lib/$(basename "$_f")"
    [ -f "$_w" ] || continue
    cmp -s "$_f" "$_w" || _lib_conflicts="$_lib_conflicts $(basename "$_f")"
done
if [ -n "$_lib_conflicts" ] && [ "$FORCE_STAGE" != 1 ]; then
    echo "stage_sdk: REFUSING to overwrite artefacts in \$W that differ from the" >&2
    echo "          /stage snapshot:$_lib_conflicts" >&2
    echo "  NOTHING HAS BEEN DELETED -- \$W/sdk is untouched." >&2
    echo "  Refresh the snapshot:  scripts/container.sh restage" >&2
    echo "  See what differs:      scripts/container.sh check" >&2
    echo "  Force the snapshot in: FORCE_STAGE=1 $0" >&2
    exit 4
fi

rm -rf "$W/sdk"
mkdir -p "$SDK"

cp -a "$S/machorun-sdk/usr" "$SDK/usr"

for h in NSObject.h NSObjCRuntime.h objc-internal.h objc-abi.h objc-exception.h \
         objc-sync.h objc-auto.h objc-class.h objc-load.h objc-runtime.h \
         objc.h runtime.h message.h objc-api.h hashtable.h hashtable2.h maptable.h \
         List.h Object.h Protocol.h objc-visibility.h; do
  [ -f "$S/objc4-runtime/$h" ] && cp -f "$S/objc4-runtime/$h" "$SDK/usr/include/objc/$h" || true
done

if [ -d "$S/objc4-priv" ]; then
  (cd "$S/objc4-priv" && find . -name '*.h' -exec install -D {} "$SDK/usr/include/{}" \; ) || true
fi
[ -f "$S/machorun-sdk/local/TargetConditionals.h" ] && \
  cp -f "$S/machorun-sdk/local/TargetConditionals.h" "$SDK/usr/include/TargetConditionals.h"

# Clean-room libc headers machorun's SDK does not carry. This REFUSES rather
# than overwrites -- see the long note at swiftcore-macho/scripts/stage_sdk.sh.
# Short version: this was a bare `cp -f`, machorun's SDK grew a real signal.h,
# ours silently replaced it with a subset that omitted sigaction(), and that
# single hidden declaration was the whole of what blocked libdispatch's
# event_epoll.c. A shadowing copy cannot fail, so it has to be made able to.
for h in "$S/libc/"*.h; do
  b=${h##*/}
  if [ -e "$SDK/usr/include/$b" ]; then
    # The precondition above already refused this case, so reaching here means
    # the caller opted in with PREFER_MACHORUN_HEADERS=1 -- keep machorun's and
    # say which one won. Left as a backstop rather than deleted: if the
    # precondition ever stops catching a collision, this still will, and it is
    # cheaper to print a line than to discover a shadowed header later.
    if [ "${PREFER_MACHORUN_HEADERS:-0}" = 1 ]; then
      echo "stage_sdk: keeping machorun's $b ($(wc -l < "$SDK/usr/include/$b") lines)," \
           "skipping our clean-room copy ($(wc -l < "$h") lines)"
      continue
    fi
    echo "stage_sdk: REFUSING to overwrite $SDK/usr/include/$b" >&2
    echo "  with the clean-room libc/$b -- machorun's SDK carries a real one" >&2
    echo "  ($(wc -l < "$SDK/usr/include/$b") lines against our $(wc -l < "$h")). Compare, then delete ours." >&2
    exit 2
  fi
  cp "$h" "$SDK/usr/include/$b"
done

mkdir -p "$SDK/usr/include/c++"
cp -a /usr/lib/llvm-18/include/c++/v1 "$SDK/usr/include/c++/v1"

# CoreFoundation.framework — Apple's own open-source CF headers, verbatim.
CFH="$SDK/System/Library/Frameworks/CoreFoundation.framework/Headers"
mkdir -p "$CFH"
cp "$S/scf/Sources/CoreFoundation/include/"*.h "$CFH/"
# corelibs' umbrella appends two corelibs-internal headers that are not in the
# real CoreFoundation.framework umbrella and drag in fts/dirent/sys-mount.
sed -i -E '/#include "(ForSwiftFoundationOnly|CFURLPriv)\.h"/d' "$CFH/CoreFoundation.h"

# Foundation.framework — clean-room umbrella from swiftcore-macho, plus our
# minimal-slice headers (installed later by scripts/build_slice.sh).
FH="$SDK/System/Library/Frameworks/Foundation.framework/Headers"
mkdir -p "$FH"
cp "$S/foundation/"*.h "$FH/"

for fw in CoreFoundation Foundation; do
  D="$SDK/System/Library/Frameworks/$fw.framework"
  mkdir -p "$D/Modules"
  cat > "$D/Modules/module.modulemap" <<EOF
framework module $fw [extern_c] [system] {
  umbrella header "$fw.h"
  export *
  module * { export * }
}
EOF
done

cat > "$SDK/SDKSettings.json" <<'EOF'
{ "DefaultProperties": { "PLATFORM_NAME": "macosx" },
  "DisplayName": "macOS 15.0", "Version": "15.0",
  "MaximumDeploymentTarget": "15.0.99",
  "CanonicalName": "macosx15.0" }
EOF

# The Darwin-target libswiftCore and its .swiftmodule, plus the Mach-O dylibs
# machorun loads at run time. machorun resolves LC_LOAD_DYLIB paths under
# $MACHORUN_ROOT/darwin, so lay the dylibs out at their real Darwin paths.
mkdir -p "$W/lib" "$W/swiftmodule" "$W/root/darwin/usr/lib"

cp -a "$S/darwinlib/"*.dylib "$W/lib/"
cp -a "$S/swiftcore/swift-macosx/arm64/libswiftCore.dylib" "$W/lib/"
cp -a "$S/swiftcore/swift-macosx/Swift.swiftmodule" "$W/swiftmodule/"
cp -f "$W/lib/"*.dylib "$W/root/darwin/usr/lib/"
# libswiftCore's install name is /usr/lib/swift/libswiftCore.dylib, not /usr/lib.
mkdir -p "$W/root/darwin/usr/lib/swift"
cp -f "$W/lib/libswiftCore.dylib" "$W/root/darwin/usr/lib/swift/"
cp -f "$S/machorun-bin" "$W/mrun"; chmod +x "$W/mrun"

echo "staged: $SDK"
find "$SDK" -name '*.h' | wc -l | sed 's/^/headers: /'
find "$SDK" -name '*.tbd' | wc -l | sed 's/^/tbds:    /'
ls "$W/lib" | sed 's/^/lib:     /'

# ---------------------------------------------------------------------------
# THE .tbd MUST NOT LAG THE DYLIB IT DESCRIBES.
#
# The link resolves against the .tbd; the loader resolves against the dylib. So
# a .tbd that is older than its dylib does not fail — it manufactures PHANTOM
# MISSING SYMBOLS: every name the dylib exports and the .tbd omits shows up as
# undefined, gets a loud "STUB CALLED" stub, and looks exactly like a real gap.
#
# That is not hypothetical. On 2026-08-28 it cost four functions written twice
# (gethostuuid, writev, snprintf_l, pthread_threadid_np — two of which had been
# in libSystem for weeks), and the shims then SHADOWED the real ones, because
# build_cftest_harness.sh links the probe object before -lSystem. One of the
# shadowed symbols was a documented FICTION, so the lie won by link order.
# Refreshing the .tbd dropped the stub count from 245 to 208 in one step.
#
# Reported, not fixed here: regenerating a .tbd is machorun's `build.sh tbd`,
# and this script only stages what it is given. But it must never stage the
# mismatch SILENTLY.
NM=${NM:-llvm-nm-18}
tbd_lag=0
for d in "$SDK/usr/lib/libSystem.B.tbd"; do
    dylib="$W/root/darwin/usr/lib/libSystem.B.dylib"
    [ -f "$d" ] && [ -f "$dylib" ] || continue
    missing=$("$NM" -g "$dylib" 2>/dev/null \
        | awk '$2=="T"{print substr($3,2)}' | sort -u \
        | while read -r s; do grep -q "_${s}\b" "$d" || echo "$s"; done | wc -l)
    total=$("$NM" -g "$dylib" 2>/dev/null | awk '$2=="T"' | wc -l)
    if [ "${missing:-0}" -gt 0 ]; then
        echo "tbd:     *** $(basename "$d") omits $missing of $total symbols the"
        echo "tbd:         dylib exports. Those will present as MISSING and get"
        echo "tbd:         loud stubs that shadow the real implementations."
        echo "tbd:         Regenerate with machorun's scripts/build.sh tbd."
        tbd_lag=1
    else
        echo "tbd:     libSystem.B.tbd advertises all $total exported symbols"
    fi
done
[ "$tbd_lag" -eq 0 ] || echo "tbd:     (staged anyway — this is a WARNING, and it is the reason"
[ "$tbd_lag" -eq 0 ] || echo "tbd:          a 'missing symbol' must be confirmed against the DYLIB)"
