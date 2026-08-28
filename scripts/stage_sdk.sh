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
