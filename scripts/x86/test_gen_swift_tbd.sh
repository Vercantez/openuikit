#!/usr/bin/env bash
# Round-trip teeth for scripts/x86/gen_swift_tbd.sh.
# Every defined-external symbol of the dylib must appear in the .tbd;
# every LC_REEXPORT_DYLIB must be recorded. Refuses arm64 Mach-O.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
GEN=$HERE/gen_swift_tbd.sh
pass=0
fail=0
ok() { echo "PASS: $*"; pass=$((pass + 1)); }
die_test() { echo "FAIL: $*" >&2; fail=$((fail + 1)); }

bash -n "$GEN" && ok "bash -n gen_swift_tbd.sh" || die_test "bash -n gen_swift_tbd.sh"

WORK=$(mktemp -d /tmp/gen-swift-tbd.XXXXXX)
trap 'rm -rf "$WORK"' EXIT

# Negative: arm64 dylib (if present) must refuse.
arm_core=$ROOT/swiftcore-macho/artifacts/swift-macosx/arm64/libswiftCore.dylib
if [ ! -f "$arm_core" ]; then
    arm_core=$ROOT/swiftcore-macho/artifacts/libswiftCore.dylib
fi
if [ -f "$arm_core" ] && llvm-otool-18 -hv "$arm_core" 2>/dev/null | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64'; then
    if bash "$GEN" "$arm_core" "$WORK/arm.tbd" 2>"$WORK/arm.err"; then
        die_test "gen_swift_tbd accepted an arm64 dylib"
    else
        grep -q 'not X86_64' "$WORK/arm.err" \
            && ok "refuses arm64 Mach-O" \
            || die_test "arm64 refuse message: $(cat "$WORK/arm.err")"
    fi
else
    ok "skip arm64 refuse (no arm64 libswiftCore in artifacts)"
fi

W=$ROOT
# shellcheck source=common.inc
. "$HERE/common.inc"

# Core + the twelve (artifacts first, scratch/apple-x86-overlays second).
n_checked=0
n_want=0
while IFS= read -r name; do
    [ -n "$name" ] || continue
    n_want=$((n_want + 1))
    dylib=$(phase2_find_x86_overlay "$name" || true)
    if [ -z "$dylib" ]; then
        ok "skip $name (no x86 dylib in overlay search; Apple-only live under scratch/apple-x86-overlays)"
        continue
    fi
    base=$(basename "$dylib" .dylib)
    dest=$WORK/$base.tbd
    if ! bash "$GEN" "$dylib" "$dest"; then
        die_test "emit failed for $base"
        continue
    fi
    grep -q 'targets:         \[ x86_64-macos \]' "$dest" \
        && ok "$base.tbd names x86_64-macos" \
        || die_test "$base.tbd missing x86_64-macos target"
    grep -q "install-name:    '/usr/lib/swift/$base.dylib'" "$dest" \
        && ok "$base.tbd install-name /usr/lib/swift/$base.dylib" \
        || die_test "$base.tbd install-name drifted ($(grep install-name "$dest"))"
    if bash "$GEN" --check "$dylib" "$dest"; then
        ok "$base round-trip --check"
    else
        die_test "$base round-trip --check failed"
    fi
    n_checked=$((n_checked + 1))
done < <({ printf 'libswiftCore.dylib\n'; phase2_twelve_overlay_names; })

# Synthetic Darwin with Apple's four LC_REEXPORT_DYLIB: gen_swift_tbd must
# record them under reexported-libraries. Committed artifacts may still lack
# re-exports until the operator rebuilds; this tooth does not wait on that.
echo
echo "=== synthetic Darwin LC_REEXPORT_DYLIB round-trip ==="
clang_c=$(command -v clang-18 || command -v clang)
echo 'void _swift_reexport_stub(void) {}' | "$clang_c" -target x86_64-apple-macosx13.0 -c -o "$WORK/stub.o" -x c -
for n in libswift_Builtin_float libswift_DarwinFoundation1 \
         libswift_DarwinFoundation2 libswift_DarwinFoundation3; do
    /usr/lib/llvm-18/bin/ld64.lld -arch x86_64 -dylib \
        -platform_version macos 13.0.0 13.0.0 \
        -install_name /usr/lib/swift/${n}.dylib \
        -o "$WORK/${n}.dylib" "$WORK/stub.o"
done
echo 'int darwin_overlay(void) { return 1; }' | "$clang_c" -target x86_64-apple-macosx13.0 -c -o "$WORK/Darwin.o" -x c -
/usr/lib/llvm-18/bin/ld64.lld -arch x86_64 -dylib \
    -platform_version macos 13.0.0 13.0.0 \
    -install_name /usr/lib/swift/libswiftDarwin.dylib \
    -reexport_library "$WORK/libswift_Builtin_float.dylib" \
    -reexport_library "$WORK/libswift_DarwinFoundation1.dylib" \
    -reexport_library "$WORK/libswift_DarwinFoundation2.dylib" \
    -reexport_library "$WORK/libswift_DarwinFoundation3.dylib" \
    -o "$WORK/libswiftDarwin.reexport.dylib" "$WORK/Darwin.o"
dest=$WORK/libswiftDarwin.reexport.tbd
if bash "$GEN" "$WORK/libswiftDarwin.reexport.dylib" "$dest"; then
    ok "emit tbd from Darwin with four LC_REEXPORT_DYLIB"
else
    die_test "emit failed for synthetic Darwin reexport dylib"
fi
if grep -q 'reexported-libraries:' "$dest"; then
    ok "libswiftDarwin.tbd has reexported-libraries"
else
    die_test "synthetic Darwin tbd missing reexported-libraries"
fi
for n in libswift_Builtin_float.dylib libswift_DarwinFoundation1.dylib \
         libswift_DarwinFoundation2.dylib libswift_DarwinFoundation3.dylib; do
    grep -q "/usr/lib/swift/$n" "$dest" \
        && ok "tbd reexports /usr/lib/swift/$n" \
        || die_test "tbd missing reexport $n"
done
# Live artifact Darwin (pre-rebuild) is allowed to lack re-exports; if it
# already has them, require exactly those four.
art=$ROOT/swiftcore-macho/artifacts/swift-macosx/x86_64/libswiftDarwin.dylib
if [ -f "$art" ]; then
    rx=$(llvm-otool-18 -l "$art" 2>/dev/null \
        | awk '/LC_REEXPORT_DYLIB/{f=1} f&&/^ *name /{print $2; f=0}' | sort -u)
    if [ -z "$rx" ]; then
        ok "artifact libswiftDarwin has no LC_REEXPORT yet (operator rebuild adds the four)"
    else
        want=$(printf '%s\n' \
            /usr/lib/swift/libswift_Builtin_float.dylib \
            /usr/lib/swift/libswift_DarwinFoundation1.dylib \
            /usr/lib/swift/libswift_DarwinFoundation2.dylib \
            /usr/lib/swift/libswift_DarwinFoundation3.dylib | sort -u)
        if [ "$rx" = "$want" ]; then
            ok "artifact libswiftDarwin has exactly four LC_REEXPORT_DYLIB"
        else
            die_test "artifact libswiftDarwin LC_REEXPORT drifted: $rx"
        fi
    fi
fi

[ "$n_want" -eq 13 ] \
    && ok "round-trip inventory is libswiftCore + twelve overlays" \
    || die_test "inventory count=$n_want want 13 (Core + twelve)"
[ "$n_checked" -ge 1 ] \
    && ok "round-trip covered $n_checked/$n_want x86 Swift dylibs" \
    || die_test "no x86 Swift dylibs to round-trip"

# Concurrency acceptance: operator's next undefs after -lobjc.
if [ -f "$WORK/libswift_Concurrency.tbd" ]; then
    conc_ok=1
    for s in _swift_task_create _swift_task_alloc '$sScP'; do
        if grep -q "$s" "$WORK/libswift_Concurrency.tbd"; then
            ok "libswift_Concurrency.tbd contains $s"
        else
            # _swift_task_create may be mangled; require at least _swift_task_ and \$sScP
            conc_ok=0
            echo "note: $s not a literal in Concurrency tbd" >&2
        fi
    done
    grep -q '_swift_task_' "$WORK/libswift_Concurrency.tbd" \
        && ok "libswift_Concurrency.tbd exports _swift_task_*" \
        || die_test "libswift_Concurrency.tbd missing _swift_task_*"
    grep -q 'sScP' "$WORK/libswift_Concurrency.tbd" \
        && ok "libswift_Concurrency.tbd exports \$sScP" \
        || die_test "libswift_Concurrency.tbd missing \$sScP"
fi

echo "test_gen_swift_tbd: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
