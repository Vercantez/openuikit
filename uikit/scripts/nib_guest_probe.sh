#!/usr/bin/env bash
# Mach-O guest check of the storyboard / NIB runtime: machorun + objc4 on
# Linux (arm64 container), the route real apps take.
#
#   bash uikit/scripts/nib_guest_probe.sh [TREE]
#   NIB_GUEST_BUILD_FULL=/path/build_full.sh bash uikit/scripts/nib_guest_probe.sh
#
# Stages a DIAGNOSTIC copy of build_full.sh (default: the tree's own
# full/scripts/build_full.sh; NIB_GUEST_BUILD_FULL picks another, beside its
# guest_arch.inc) under TREE/build/nibguest (gitignored), extended to compile
# uikit/Tools/nibguest/NibGuestProbe.swift as one more guest app module and
# to run it under machorun against fixtures/nibruntime/NibGuest.storyboardc
# (ibtool output of Tools/nibguest/NibGuest.storyboard). It then runs
# scripts/ops/local_guest_verify.sh with that copy (build only) and prints the
# probe's line: NIB_GUEST_RUNTIME_OK when the archived custom classes were
# found by name in objc4, built through init(coder:), their outlets
# connected, the embed segue performed (with the app's prepare(for:sender:)
# override) and an archived button action delivered.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
TREE=${1:-$(cd "$HERE/../.." && pwd -P)}
SRC=${NIB_GUEST_BUILD_FULL:-$TREE/full/scripts/build_full.sh}
STAGE=$TREE/build/nibguest
mkdir -p "$STAGE"
cp "$SRC" "$STAGE/build_full.sh"
cp "$(dirname "$SRC")/guest_arch.inc" "$STAGE/guest_arch.inc"
python3 - "$STAGE/build_full.sh" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
# Anchor: the staging step after every guest executable is linked (stable
# across build_full's serial and parallel probe-link layouts).
anchor = "# Match SwiftPM's executable bundle metadata and stage Focus startup assets.\n"
assert anchor in s, "build_full.sh staging anchor not found"
s = s.replace(anchor, '''# DIAGNOSTIC (uikit/scripts/nib_guest_probe.sh): storyboard runtime probe.
compile_app_module NibGuestProbe "$OUT/NibGuestProbe.o" "$UIKIT/Tools/nibguest/NibGuestProbe.swift"
link_app_executable "$OUT/NibGuestProbe" "$OUT/NibGuestProbe.o"

''' + anchor, 1)
s += '''
# DIAGNOSTIC (uikit/scripts/nib_guest_probe.sh): run it under machorun.
(
  export MACHORUN_ROOT="$ROOTDIR" LD_LIBRARY_PATH="$OUT/host"
  export LD_PRELOAD="$OUT/host/libOpenDispatchHost.so:$OUT/host/libOpenFoundationInternationalizationHost.so:$OUT/host/libOpenURLTransportHost.so:$OUT/host/libOpenRelativeTimeHost.so"
  export OPENUIKIT_RESOURCE_ROOT="$UIKIT/Sources/OpenUIKit/Resources"
  "$ROOTDIR/machorun" "$OUT/NibGuestProbe" "$UIKIT/fixtures/nibruntime" 2>&1 | grep -v '^objc\\[' | tail -20
) || echo "NIB_GUEST_PROBE_EXIT_NONZERO"
'''
open(p, 'w').write(s)
PY
MAIN=$(dirname "$(cd "$TREE" && cd "$(git rev-parse --git-common-dir)" && pwd -P)")
LOCAL_GUEST_BUILD_FULL="$STAGE/build_full.sh" LOCAL_GUEST_SKIP_VERIFY=1 \
    bash "$MAIN/scripts/ops/local_guest_verify.sh" "$TREE"
grep -E 'NIB_GUEST_' "$TREE/build/local-guest/build_full.log"
