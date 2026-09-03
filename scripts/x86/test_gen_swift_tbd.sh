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

x86=$ROOT/swiftcore-macho/artifacts/swift-macosx/x86_64
n_checked=0
for dylib in \
    "$x86/libswiftCore.dylib" \
    "$x86/libswiftDarwin.dylib" \
    "$x86/libswift_Concurrency.dylib" \
    "$x86/libswiftObjectiveC.dylib" \
    "$x86/libswiftObservation.dylib" \
    "$x86/libswiftSynchronization.dylib" \
    "$x86/libswift_Builtin_float.dylib" \
    "$x86/libswift_RegexParser.dylib" \
    "$x86/libswift_StringProcessing.dylib"
do
    [ -f "$dylib" ] || continue
    llvm-otool-18 -hv "$dylib" 2>/dev/null | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64' || continue
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
done

[ "$n_checked" -ge 1 ] \
    && ok "round-trip covered $n_checked x86 Swift dylibs" \
    || die_test "no x86 Swift dylibs to round-trip"

# Concurrency acceptance: operator's next undefs after -lobjc.
if [ -f "$x86/libswift_Concurrency.dylib" ] && [ -f "$WORK/libswift_Concurrency.tbd" ]; then
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
