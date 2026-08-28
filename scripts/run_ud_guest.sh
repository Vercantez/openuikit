#!/bin/bash
# run_ud_guest.sh -- run the #87 guest binary against a NAMED root, after
# checking that root by CONTENT.
#
#   scripts/run_ud_guest.sh [ROOT]        # default /work/root
#
# WHY THE ROOT IS A PARAMETER AND NOT AN ASSUMPTION (task #89). The #87 load
# failure was never about the Swift overlays. It was about WHICH ROOT the
# binary ran against: the composed root is built by this repo's stage_sdk.sh
# and never ran ~/swift-macho-linux/scripts/stage_swift_runtime.sh, which is
# what puts something at the two framework paths the simulator overlays name.
# ~/swift-macho-linux/scratch/mrroot_fe has them and does not exhibit the
# failure. Two roots, one binary, and nothing in the recipe said which.
#
# So this script REFUSES to run against a root it has not verified, and prints
# the root it used. An invocation that does not name its root is how a result
# gets attributed to the wrong tree.
#
# CHECKED BY CONTENT, NOT BY `ls`. A file being present at Foundation's path
# says nothing about what it is -- it could be the placeholder, machorun's
# 8-export abort stub, or a full copy of some real library. Each behaves
# differently and only one of them is what this root is supposed to have.
set -uo pipefail

W=${W:-/work}
ROOT=${1:-$W/root}
BIN=${BIN:-$W/bin/ud_guest}
MRUN=${MRUN:-/stage/machorun-bin}
NM=${NM:-llvm-nm-18}
OTOOL=${OTOOL:-llvm-otool-18}

FINGERPRINT=_machorun_foundation_placeholder
CF_SLOT=$ROOT/darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
FW_SLOT=$ROOT/darwin/System/Library/Frameworks/Foundation.framework/Foundation
REAL_CF=$ROOT/darwin/usr/lib/libCFTest.dylib

echo "== root   $ROOT"
echo "== binary $BIN"
fail=0

for slot in "$FW_SLOT" "$CF_SLOT"; do
    name=$(basename "$slot")
    if [ ! -f "$slot" ]; then
        echo "   REFUSING: nothing at $slot" >&2
        echo "     The simulator overlays carry a hard LC_LOAD_DYLIB on it and the" >&2
        echo "     load will stop before main. Run scripts/build_foundation_placeholder.sh" >&2
        fail=1; continue
    fi
    if "$NM" -g "$slot" 2>/dev/null | grep -q "$FINGERPRINT"; then
        echo "   $name: placeholder ($(wc -c < "$slot") bytes, empty by design)"
    else
        n=$("$NM" -g --defined-only "$slot" 2>/dev/null | grep -c . || true)
        echo "   $name: NOT the placeholder -- $(wc -c < "$slot") bytes, $n exports"
        echo "     install_name $("$OTOOL" -D "$slot" 2>/dev/null | tail -1)"
        echo "     This root was staged by something else. That is allowed, but the"
        echo "     result belongs to THAT root -- say so when reporting it."
    fi
done

# THE DUPLICATE-IMAGE CHECK. machorun keys loaded images by REQUESTED PATH, not
# by LC_ID_DYLIB, so the same dylib at two paths loads TWICE -- two copies of
# every ObjC class and of CF's global state, including the preferences cache,
# with nothing at load time reporting it. That is task #90. Until it is fixed,
# this is the check that catches it.
if [ -f "$CF_SLOT" ] && [ -f "$REAL_CF" ]; then
    a=$(md5sum "$CF_SLOT" 2>/dev/null | cut -d' ' -f1)
    b=$(md5sum "$REAL_CF" 2>/dev/null | cut -d' ' -f1)
    if [ "$a" = "$b" ]; then
        echo "   REFUSING: the CoreFoundation slot is a byte-identical copy of" >&2
        echo "     libCFTest.dylib (md5 $a). machorun will load CoreFoundation" >&2
        echo "     TWICE -- 22 duplicated ObjC classes and two preferences caches." >&2
        fail=1
    fi
fi

[ "$fail" -eq 0 ] || { echo "REFUSING to run; the root is not fit." >&2; exit 2; }

echo
MACHORUN_ROOT=$ROOT "$MRUN" "$BIN"
rc=$?
echo
echo "== exit $rc   (root $ROOT)"
exit $rc
