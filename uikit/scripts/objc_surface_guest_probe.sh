#!/usr/bin/env bash
# Mach-O guest check of the Objective-C surface (docs/agent_reports/
# objc-surface.md): an Objective-C category on UIFont and an Objective-C
# CALayer subclass, compiled by clang against OpenUIKit's generated header
# and run under machorun + objc4 on Linux (arm64 container).
#
#   bash uikit/scripts/objc_surface_guest_probe.sh [TREE]
#   OBJC_SURFACE_BUILD_FULL=/path/build_full.sh bash uikit/scripts/objc_surface_guest_probe.sh
#
# Stages a DIAGNOSTIC copy of build_full.sh (default: the tree's own
# full/scripts/build_full.sh; OBJC_SURFACE_BUILD_FULL picks another, beside its
# guest_arch.inc) under TREE/build/objcsurfaceguest (gitignored), extended to
#   1. also emit OpenUIKit's Objective-C header while compiling the guest
#      OpenUIKit (the Foundation-hidden build, unchanged otherwise);
#   2. compile Tools/oracle2/objcsurfaceprobe/scenario/OUKSurfaceScenario.m
#      (-DOUK_NO_FOUNDATION: the guest has objc4 but no NSString) and
#      guest_main.c with clang-18 -fobjc-arc against that header, under the
#      same SWIFT_CLASS / SWIFT_CLASS_NAMED defines apps get, and link them
#      like the other guest probes;
#   3. run the probe under machorun.
# It then runs scripts/ops/local_guest_verify.sh with that copy (build only)
# and compares the probe's output with transcript-guest-ios26.1.txt — the
# SAME scenario variant run on the iOS 26.1 simulator (run.sh). Prints
# OBJC_SURFACE_GUEST_OK on an exact match.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
TREE=${1:-$(cd "$HERE/../.." && pwd -P)}
SRC=${OBJC_SURFACE_BUILD_FULL:-$TREE/full/scripts/build_full.sh}
STAGE=$TREE/build/objcsurfaceguest
mkdir -p "$STAGE"
cp "$SRC" "$STAGE/build_full.sh"
cp "$(dirname "$SRC")/guest_arch.inc" "$STAGE/guest_arch.inc"
python3 - "$STAGE/build_full.sh" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
emit = '''    -emit-object -emit-module -emit-module-path "$OUT/OpenUIKit.swiftmodule" \\
    -o "$OUT/openuikit.o" \\'''
assert s.count(emit) == 1, "build_full.sh OpenUIKit compile line not found"
s = s.replace(emit, '''    -emit-object -emit-module -emit-module-path "$OUT/OpenUIKit.swiftmodule" \\
    -emit-objc-header-path "$OUT/objcsurface/OpenUIKit-Swift.h" \\
    -o "$OUT/openuikit.o" \\''')
anchor = '''run_jobs build_final_executable render_full GuestBoundaryTests LaunchProbe \\
    FuziProbe BrowserInkProbe indexpath_identity_probe
'''
assert anchor in s, "build_full.sh final-executable line not found"
s = s.replace('echo "== OpenUIKit (', 'mkdir -p "$OUT/objcsurface"\necho "== OpenUIKit (', 1)
s = s.replace(anchor, anchor + '''
# DIAGNOSTIC (uikit/scripts/objc_surface_guest_probe.sh): Objective-C surface.
OSP="$OUT/objcsurface"
OSP_SRC="$UIKIT/Tools/oracle2/objcsurfaceprobe"
OSP_FLAGS=(-fobjc-arc -DOUK_OPENUIKIT=1 -DOUK_NO_FOUNDATION=1 -I "$OSP" -I "$OSP_SRC/scenario/include" -I "$OSP_SRC/guestinc"
  "-DSWIFT_CLASS(SWIFT_NAME)=SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA"
  "-DSWIFT_CLASS_NAMED(SWIFT_NAME)=SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA")
echo "== objc surface probe: header $(grep -c '^@interface' "$OSP/OpenUIKit-Swift.h") interfaces"
grep -E '^SWIFT_CLASS_NAMED\\("(UIFont|CALayer)"\\)' "$OSP/OpenUIKit-Swift.h" || echo "OBJC_SURFACE_GUEST_HEADER_UNNAMED"
"${CC[@]}" "${OSP_FLAGS[@]}" -c "$OSP_SRC/scenario/OUKSurfaceScenario.m" -o "$OSP/scenario.o"
"${CC[@]}" -I "$OSP_SRC/scenario/include" -c "$OSP_SRC/guest_main.c" -o "$OSP/guest_main.o"
link_app_executable "$OUT/ObjCSurfaceGuestProbe" "$OSP/scenario.o" "$OSP/guest_main.o"
''')
s += '''
# DIAGNOSTIC (uikit/scripts/objc_surface_guest_probe.sh): run it under machorun.
(
  export MACHORUN_ROOT="$ROOTDIR" LD_LIBRARY_PATH="$OUT/host"
  export LD_PRELOAD="$OUT/host/libOpenDispatchHost.so:$OUT/host/libOpenFoundationInternationalizationHost.so:$OUT/host/libOpenURLTransportHost.so:$OUT/host/libOpenRelativeTimeHost.so"
  export OPENUIKIT_RESOURCE_ROOT="$UIKIT/Sources/OpenUIKit/Resources"
  "$ROOTDIR/machorun" "$OUT/ObjCSurfaceGuestProbe" > "$OUT/objcsurface/guest.txt" 2> "$OUT/objcsurface/guest.err"
  echo "OBJC_SURFACE_GUEST_EXIT=$?"
  sed 's/^/OUKSURF|/' "$OUT/objcsurface/guest.txt"
  grep -v '^objc\\[' "$OUT/objcsurface/guest.err" | tail -20 | sed 's/^/OUKSURF-ERR|/'
) || echo "OBJC_SURFACE_GUEST_EXIT_NONZERO"
'''
open(p, 'w').write(s)
PY
MAIN=$(dirname "$(cd "$TREE" && cd "$(git rev-parse --git-common-dir)" && pwd -P)")
LOCAL_GUEST_BUILD_FULL="$STAGE/build_full.sh" LOCAL_GUEST_SKIP_VERIFY=1 \
    bash "$MAIN/scripts/ops/local_guest_verify.sh" "$TREE"
LOG=$TREE/build/local-guest/build_full.log
grep -E 'objc surface probe|SWIFT_CLASS_NAMED|OBJC_SURFACE_GUEST|OUKSURF-ERR' "$LOG" | sed -E 's/^[0-9.]+ //' || true
python3 - "$LOG" "$TREE/uikit/Tools/oracle2/objcsurfaceprobe/transcript-guest-ios26.1.txt" <<'PY'
import re, sys
log, oracle = sys.argv[1:]
ours = [re.sub(r'^[0-9.]+ ', '', l).rstrip('\n')[len('OUKSURF|'):]
        for l in open(log) if re.sub(r'^[0-9.]+ ', '', l).startswith('OUKSURF|')]
ios = [l.rstrip('\n') for l in open(oracle)]
diff = [(i + 1, a, b) for i, (a, b) in enumerate(zip(ours, ios)) if a != b]
if ours == ios:
    print(f"OBJC_SURFACE_GUEST_OK {len(ours)} lines identical to the iOS 26.1 run of the same scenario "
          f"(UIFont category, CALayer subclass)")
else:
    print(f"OBJC_SURFACE_GUEST_MISMATCH ours={len(ours)} ios={len(ios)}")
    for i, a, b in diff[:20]:
        print(f"  line {i}: ours {a!r} ios {b!r}")
    sys.exit(1)
PY
