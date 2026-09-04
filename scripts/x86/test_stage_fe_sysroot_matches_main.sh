#!/usr/bin/env bash
# Dual-run SYS vs origin/main. Overlay-copied SYS must be byte-identical
# (diff -r). Arm64-copied Darwin family is FE_SYSROOT_SELECT=main-copy:
# no *-fe-clang sibling, compiles against SYS like main.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
MAIN_REF=${STAGE_FE_SYSROOT_MAIN_REF:-origin/main}

pass=0
fail=0
ok() { echo "PASS: $*"; pass=$((pass + 1)); }
die_test() { echo "FAIL: $*" >&2; fail=$((fail + 1)); }

header_sha() {
    local f=$1
    if [ -f "$f" ]; then
        sha256sum "$f" | awk '{print $1}'
    else
        printf 'ABSENT\n'
    fi
}

print_sys_shas() {
    local label=$1 sys=$2
    echo "=== $label SYS header sha256 ==="
    for rel in usr/include/math.h usr/include/tgmath.h usr/include/sys/proc.h \
        usr/include/MacTypes.h usr/include/Darwin.modulemap \
        usr/include/Darwin_C.modulemap; do
        printf '%s  %s\n' "$(header_sha "$sys/$rel")" "$rel"
    done
}

if ! git -C "$ROOT" cat-file -e "${MAIN_REF}:scripts/x86/stage_fe_sysroot.sh" 2>/dev/null; then
    echo "fetching $MAIN_REF for main's stage_fe_sysroot.sh"
    git -C "$ROOT" fetch origin main
    MAIN_REF=origin/main
fi
git -C "$ROOT" cat-file -e "${MAIN_REF}:scripts/x86/stage_fe_sysroot.sh"
git -C "$ROOT" cat-file -e "${MAIN_REF}:scripts/x86/common.inc"

WORK=$(mktemp -d /tmp/stage-fe-sysroot-matches-main.XXXXXX)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

MAIN_TREE=$WORK/main-tree
mkdir -p "$MAIN_TREE/scripts/x86"
git -C "$ROOT" show "${MAIN_REF}:scripts/x86/stage_fe_sysroot.sh" \
    > "$MAIN_TREE/scripts/x86/stage_fe_sysroot.sh"
git -C "$ROOT" show "${MAIN_REF}:scripts/x86/common.inc" \
    > "$MAIN_TREE/scripts/x86/common.inc"
git -C "$ROOT" show "${MAIN_REF}:scripts/x86/stamp.inc" \
    > "$MAIN_TREE/scripts/x86/stamp.inc"
git -C "$ROOT" show "${MAIN_REF}:scripts/x86/ud_guest.inc" \
    > "$MAIN_TREE/scripts/x86/ud_guest.inc"
chmod +x "$MAIN_TREE/scripts/x86/stage_fe_sysroot.sh"
ln -s "$ROOT/full" "$MAIN_TREE/full"
# Main's common.inc invokes PHASE2_REPO/scripts/x86/gen_swift_tbd.sh while
# staging overlay .tbd files into SYS. Keep main's stager/common.inc, but
# share the rest of scripts/x86 with this checkout.
while IFS= read -r -d '' f; do
    bn=$(basename "$f")
    case "$bn" in
        stage_fe_sysroot.sh|common.inc|stamp.inc|ud_guest.inc) continue ;;
    esac
    ln -sfn "$f" "$MAIN_TREE/scripts/x86/$bn"
done < <(find "$ROOT/scripts/x86" -maxdepth 1 -mindepth 1 -print0)

ARM=$WORK/arm
mkdir -p "$ARM/usr/include/sys" "$ARM/usr/lib/swift"
# Box-like arm64 sysroot: pruned Darwin family like main's gen_darwin_modulemap
# output. Darwin.modulemap does NOT name math.h; Darwin.C does. FE expand of
# `header "math.h"` onto Darwin is what made overlay tgmath miss acosf.
if [ -d "$ROOT/machorun/sdk/usr/include" ]; then
    cp -R "$ROOT/machorun/sdk/usr/include/." "$ARM/usr/include/"
fi
cat > "$ARM/usr/include/Darwin.modulemap" <<'EOF'
// pruned Darwin.modulemap from arm64 sysroot_fe4 (main cycle)
module Darwin [system] [extern_c] {
  module MacTypes {
    header "MacTypes.h"
    export *
  }
  export *
  extern module C "Darwin_C.modulemap"
}
EOF
cat > "$ARM/usr/include/Darwin_C.modulemap" <<'EOF'
// pruned Darwin_C.modulemap: Darwin.C owns math.h (not Darwin.modulemap)
module Darwin.C [system] [extern_c] {
  module math {
    header "math.h"
    export *
  }
  export *
}
EOF
printf 'module ObjectiveC [system] { header "objc/objc.h" export * }\nextern module Darwin "Darwin.modulemap"\n' \
    > "$ARM/usr/include/module.modulemap"
ART_IF=$ROOT/swiftcore-macho/artifacts/swift-macosx/Darwin.swiftmodule/x86_64-apple-macos.swiftinterface
if [ -f "$ART_IF" ]; then
    cp "$ART_IF" "$ARM/usr/lib/swift/Darwin.swiftinterface"
else
    printf '// Darwin.swiftinterface fixture\n' > "$ARM/usr/lib/swift/Darwin.swiftinterface"
fi

MACHORUN_MATH=$(header_sha "$ROOT/machorun/sdk/usr/include/math.h")
MACHORUN_MAC=$(header_sha "$ROOT/machorun/sdk/usr/include/MacTypes.h")
MACHORUN_PROC=$(header_sha "$ROOT/machorun/sdk/usr/include/sys/proc.h")
MACHORUN_TG=$(header_sha "$ROOT/machorun/sdk/usr/include/tgmath.h")

run_stager() {
    local script=$1 sys=$2 log=$3
    # Live SWIFTCORE_FE_SYSROOT must not leak into either stager.
    env -u SWIFTCORE_FE_SYSROOT \
        -u SWIFTCORE_FE_SYSROOT_EXTRA_INSERTS \
        -u SWIFTCORE_FE_SYSROOT_SKIP_DARWIN_MODULEMAP_EXTRA_INSERTS \
        -u PHASE2_COMMON_INC \
        W="$ROOT" SYS="$sys" ARM_SYS="$ARM" MACHORUN="$ROOT/machorun" \
        bash "$script" >"$log" 2>&1
}

SYS_MAIN=$WORK/sys-main-x86_64
SYS_OURS=$WORK/sys-ours-x86_64
LOG_MAIN=$WORK/main.log
LOG_OURS=$WORK/ours.log

set +e
run_stager "$MAIN_TREE/scripts/x86/stage_fe_sysroot.sh" "$SYS_MAIN" "$LOG_MAIN"
rc_main=$?
run_stager "$ROOT/scripts/x86/stage_fe_sysroot.sh" "$SYS_OURS" "$LOG_OURS"
rc_ours=$?
set -e

echo "=== main stager rc=$rc_main (origin/main may exit 3 without Darwin overlays) ==="
tail -n 30 "$LOG_MAIN" || true
echo "=== ours stager rc=$rc_ours ==="
tail -n 40 "$LOG_OURS" || true

if [ ! -d "$SYS_MAIN/usr/include" ]; then
    die_test "main stager wrote no SYS (rc=$rc_main); log=$LOG_MAIN"
    echo "pass=$pass fail=$fail"
    exit 1
fi
if [ ! -d "$SYS_OURS/usr/include" ]; then
    die_test "ours stager wrote no SYS (rc=$rc_ours); log=$LOG_OURS"
    echo "pass=$pass fail=$fail"
    exit 1
fi

print_sys_shas "MAIN ($MAIN_REF)" "$SYS_MAIN"
print_sys_shas "OURS" "$SYS_OURS"

main_math=$(header_sha "$SYS_MAIN/usr/include/math.h")
main_tg=$(header_sha "$SYS_MAIN/usr/include/tgmath.h")
main_proc=$(header_sha "$SYS_MAIN/usr/include/sys/proc.h")
main_mac=$(header_sha "$SYS_MAIN/usr/include/MacTypes.h")
main_map=$(header_sha "$SYS_MAIN/usr/include/Darwin.modulemap")
main_cmap=$(header_sha "$SYS_MAIN/usr/include/Darwin_C.modulemap")
ours_math=$(header_sha "$SYS_OURS/usr/include/math.h")
ours_tg=$(header_sha "$SYS_OURS/usr/include/tgmath.h")
ours_proc=$(header_sha "$SYS_OURS/usr/include/sys/proc.h")
ours_mac=$(header_sha "$SYS_OURS/usr/include/MacTypes.h")
ours_map=$(header_sha "$SYS_OURS/usr/include/Darwin.modulemap")
ours_cmap=$(header_sha "$SYS_OURS/usr/include/Darwin_C.modulemap")

# Box-path authority: these four files are copied from machorun/sdk; overlay-
# darwin Intel math.h / CarbonHeaders MacTypes must not land on SYS.
[ "$main_math" = "$MACHORUN_MATH" ] && ok "main SYS math.h sha=$main_math (machorun)" \
    || die_test "main SYS math.h $main_math != machorun $MACHORUN_MATH"
[ "$main_mac" = "$MACHORUN_MAC" ] && ok "main SYS MacTypes.h sha=$main_mac (machorun)" \
    || die_test "main SYS MacTypes.h $main_mac != machorun $MACHORUN_MAC"
[ "$main_proc" = "$MACHORUN_PROC" ] && ok "main SYS sys/proc.h sha=$main_proc (machorun)" \
    || die_test "main SYS sys/proc.h $main_proc != machorun $MACHORUN_PROC"
[ "$main_tg" = "$MACHORUN_TG" ] && ok "main SYS tgmath.h sha=$main_tg (machorun=$MACHORUN_TG)" \
    || die_test "main SYS tgmath.h $main_tg != machorun $MACHORUN_TG"

[ "$ours_math" = "$main_math" ] && ok "ours SYS math.h reproduces main" \
    || die_test "ours SYS math.h $ours_math != main $main_math"
[ "$ours_tg" = "$main_tg" ] && ok "ours SYS tgmath.h reproduces main" \
    || die_test "ours SYS tgmath.h $ours_tg != main $main_tg"
[ "$ours_proc" = "$main_proc" ] && ok "ours SYS sys/proc.h reproduces main" \
    || die_test "ours SYS sys/proc.h $ours_proc != main $main_proc"
[ "$ours_mac" = "$main_mac" ] && ok "ours SYS MacTypes.h reproduces main" \
    || die_test "ours SYS MacTypes.h $ours_mac != main $main_mac"
[ "$ours_map" = "$main_map" ] && ok "ours SYS Darwin.modulemap reproduces main sha=$main_map" \
    || die_test "ours SYS Darwin.modulemap $ours_map != main $main_map"
[ "$ours_cmap" = "$main_cmap" ] && ok "ours SYS Darwin_C.modulemap reproduces main sha=$main_cmap" \
    || die_test "ours SYS Darwin_C.modulemap $ours_cmap != main $main_cmap"

if grep -q 'header "math.h"' "$SYS_OURS/usr/include/Darwin.modulemap"; then
    die_test "SYS Darwin.modulemap names math.h (main uses Darwin.C; overlay tgmath misses acosf)"
else
    ok "SYS Darwin.modulemap does not name math.h"
fi
if grep -q 'header "math.h"' "$SYS_OURS/usr/include/Darwin_C.modulemap"; then
    ok "SYS Darwin_C.modulemap names math.h (Darwin.C submodule)"
else
    die_test "SYS Darwin_C.modulemap missing header math.h"
fi
if cmp -s "$ARM/usr/include/Darwin.modulemap" "$SYS_OURS/usr/include/Darwin.modulemap"; then
    ok "SYS Darwin.modulemap is the ARM pruned map (not FE expand / overlay-darwin generate)"
else
    die_test "SYS Darwin.modulemap differs from ARM pruned map"
fi

DIFF_OUT=$WORK/diff.txt
set +e
diff -rq -x .phase2-stage-inputs "$SYS_MAIN" "$SYS_OURS" >"$DIFF_OUT" 2>&1
diff_rc=$?
set -e
if [ "$diff_rc" -eq 0 ]; then
    ok "diff -r SYS trees (excluding .phase2-stage-inputs) are identical"
else
    echo "=== diff -rq SYS (first 80 lines) ==="
    head -n 80 "$DIFF_OUT"
    die_test "SYS trees differ from main (diff rc=$diff_rc)"
fi

# Include-tree digest: sha256 of `find . -type f | sort | xargs sha256sum`
# inside usr/include. Operator-box MAIN cycle at 27c6b679 measured
# 1a8d31fa51df8db9 over 506 files. CI's ARM fixture is smaller, so this
# asserts branch == origin/main on the same inputs rather than pinning
# that 506-file digest. The six-row box pins live in test_overlay_darwin.sh.
include_tree_digest() {
    local root=$1/usr/include
    (
        cd "$root"
        find . -type f | LC_ALL=C sort | xargs sha256sum | sha256sum | awk '{print $1}'
    )
}
DIGEST_MAIN=$(include_tree_digest "$SYS_MAIN")
DIGEST_OURS=$(include_tree_digest "$SYS_OURS")
if [ "$DIGEST_MAIN" = "$DIGEST_OURS" ]; then
    ok "SYS usr/include tree digest matches main (${DIGEST_OURS:0:16})"
else
    die_test "SYS usr/include tree digest disagrees: main=$DIGEST_MAIN ours=$DIGEST_OURS"
fi
n_include=$(find "$SYS_OURS/usr/include" -type f | wc -l | tr -d ' ')
ok "SYS usr/include file count = $n_include (box MAIN cycle is 506; CI fixture is smaller)"

FE_OURS=$(printf '%s-fe-clang\n' "${SYS_OURS%/}")
if [ -d "$FE_OURS" ]; then
    die_test "stager wrote *-fe-clang sibling for arm64-copied Darwin family (box is main-copy)"
else
    ok "arm64-copied Darwin family does not stage *-fe-clang sibling"
fi
if [ -f "$SYS_OURS/usr/include/sys/ioctl.h" ]; then
    die_test "overlay-copied SYS has sys/ioctl.h (ioctl stub is VM-only)"
else
    ok "overlay-copied SYS has no sys/ioctl.h"
fi
if [ -f "$SYS_OURS/usr/include/semaphore.h" ]; then
    die_test "overlay-copied SYS has semaphore.h (overlay-posix is VM-only)"
else
    ok "overlay-copied SYS has no semaphore.h"
fi
if [ -d "${SYS_MAIN}-fe-clang" ]; then
    die_test "main stager wrote a *-fe-clang sibling (main does not)"
else
    ok "main stager did not write a *-fe-clang sibling"
fi

# Intel overlay-darwin math.h must not be the overlay-copied SYS copy.
INTEL_MATH=$ROOT/swiftcore-macho/sdk/overlay-darwin/math.h
if [ -f "$INTEL_MATH" ] && [ -f "$SYS_OURS/usr/include/math.h" ]; then
    if cmp -s "$INTEL_MATH" "$SYS_OURS/usr/include/math.h"; then
        die_test "SYS math.h is overlay-darwin Intel (must stay machorun)"
    else
        ok "SYS math.h is not overlay-darwin Intel"
    fi
fi

# shellcheck disable=SC1091
. "$ROOT/scripts/x86/common.inc"
sel=$(phase2_select_fe_compile_sysroot "$SYS_OURS" "$ARM")
echo "$sel"
case "$sel" in
    FE_SYSROOT_SELECT=main-copy\ sys="$SYS_OURS")
        ok "FE_SYSROOT_SELECT=main-copy for arm64-copied Darwin family"
        ;;
    *)
        die_test "expected FE_SYSROOT_SELECT=main-copy sys=$SYS_OURS got: $sel"
        ;;
esac
[ "$PHASE2_FE_COMPILE_SYSROOT" = "$SYS_OURS" ] \
    && ok "compile sysroot is overlay-copied SYS (same as main)" \
    || die_test "compile sysroot $PHASE2_FE_COMPILE_SYSROOT != $SYS_OURS"
argv=$(phase2_os_module_compile_argv_summary "$ROOT")
echo "$argv"
case "$argv" in
    sys="$SYS_OURS"\ posix_xcc=none)
        ok "os-module argv equals main (SYS=overlay-copied SYS, no overlay-posix -I)"
        ;;
    *)
        die_test "os-module argv != main's: $argv"
        ;;
esac

echo "pass=$pass fail=$fail"
if [ "$fail" -ne 0 ]; then
    exit 1
fi
exit 0
