#!/bin/bash
# CHECK 5 must account compiler-rt builtins without host-bound-allowing them.
#
# Operator measurement (x86 overlays linked -undefined dynamic_lookup): those
# names reach glibc as plain C imports. PR #64's libclang_rt.osx.a answers
# them at link once the overlays rebuild NOUNDEFS. Putting them on
# darwin/host-bound-allowed.txt is the wrong fix -- a builtin reaching glibc
# means a dylib was linked without the archive. src/host_deny.c's compiler-rt
# family is the assertion; this script grades that CHECK 5 agrees.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MR=$(cd "$SCRIPT_DIR/.." && pwd)
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

check=$SCRIPT_DIR/check_undefined.sh
deny=$MR/src/host_deny.c
allow=$MR/darwin/host-bound-allowed.txt

RT_MACHO='
___divti3
___modti3
___udivti3
___umodti3
___truncsfhf2
___isPlatformVersionAtLeast
___isPlatformOrVariantPlatformVersionAtLeast
'

echo "=== parser: mixed-case compiler-rt cnames are deny rows ==="
parsed=$(grep -oE '^ *X\([A-Za-z_][A-Za-z_0-9]*, "[A-Za-z_][A-Za-z_0-9]*"' "$deny" \
    | sed 's/.*"\(.*\)"/_\1/' | LC_ALL=C sort -u)
printf '%s\n' "$RT_MACHO" | grep -v '^$' | while IFS= read -r s; do
    if printf '%s\n' "$parsed" | grep -qx "$s"; then
        echo "  OK  parser sees $s"
    else
        echo "  FAIL parser dropped $s"
        echo "$parsed" | sed 's/^/    /'
        exit 1
    fi
done || fail=1

old_parsed=$(grep -oE '^ *X\([a-z_0-9]+, "[a-z_0-9]+"' "$deny" \
    | sed 's/.*"\(.*\)"/_\1/' | LC_ALL=C sort -u)
if printf '%s\n' "$old_parsed" | grep -qx '___isPlatformVersionAtLeast'; then
    echo "  FAIL the old [a-z_0-9] parser would already see mixed-case (test stale)"
    fail=1
else
    echo "  OK  the old [a-z_0-9] parser still drops ___isPlatformVersionAtLeast"
fi

echo
echo "=== host-bound-allowed.txt must not list compiler-rt builtins ==="
while IFS= read -r s; do
    [ -n "$s" ] || continue
    if grep -qE "^${s}([[:space:]]|$)" "$allow"; then
        echo "  FAIL $s is on the allow list -- do not host-bind-allow compiler-rt"
        fail=1
    else
        echo "  OK  $s is not allowed"
    fi
done <<EOF
$RT_MACHO
EOF

[ -f "$MR/darwin/usr/lib/libSystem.B.dylib" ] || {
    echo "FAIL no libSystem.B.dylib -- cannot build the overlay fixture"
    exit 1
}
command -v clang >/dev/null && command -v ld64.lld >/dev/null || {
    echo "FAIL need clang + ld64.lld to build the overlay fixture"
    exit 1
}

case "$(uname -m)" in
    x86_64)  TARGET=x86_64-apple-macos11; ARCH=x86_64 ;;
    aarch64|arm64) TARGET=arm64-apple-macos11; ARCH=arm64 ;;
    *) echo "FAIL unhandled host arch $(uname -m)"; exit 1 ;;
esac

echo
echo "=== fixture: overlay-shaped dylib (dynamic_lookup) without libswiftcompat ==="
# Operator x86 root after parking arm64 compat: overlays still import the
# builtins, nothing in the remaining root defines them, group-2 names ARE
# defined by libSystem/libc++.
cat > "$tmp/overlay.c" <<'C'
extern void rt_divti3(void) __asm("___divti3");
extern void rt_modti3(void) __asm("___modti3");
extern void rt_udivti3(void) __asm("___udivti3");
extern void rt_umodti3(void) __asm("___umodti3");
extern void rt_truncsfhf2(void) __asm("___truncsfhf2");
extern void rt_plat(void) __asm("___isPlatformVersionAtLeast");
extern void rt_platv(void) __asm("___isPlatformOrVariantPlatformVersionAtLeast");
extern void g_fmal(void) __asm("_fmal");
extern void g_flockfile(void) __asm("_flockfile");
extern void g_funlockfile(void) __asm("_funlockfile");
extern void g_dispatch(void) __asm("_dispatch_once_f");
extern void g_objc(void) __asm("__dyld_is_objc_constant");
extern void g_mh(void) __asm("__NSGetMachExecuteHeader");
extern void g_abort(void) __asm("__ZNSt3__122__libcpp_verbose_abortEPKcz");
extern void g_hw(void) __asm("__ZNSt3__16thread20hardware_concurrencyEv");
extern void g_pl(void) __asm("__ZNSt3__1plIcNS_11char_traitsIcEENS_9allocatorIcEEEENS_12basic_stringIT_T0_T1_EEPKS6_RKS9_");
void *overlay_touch(void);
void *overlay_touch(void)
{
    rt_divti3(); rt_modti3(); rt_udivti3(); rt_umodti3(); rt_truncsfhf2();
    rt_plat(); rt_platv();
    g_fmal(); g_flockfile(); g_funlockfile(); g_dispatch(); g_objc(); g_mh();
    g_abort(); g_hw(); g_pl();
    return 0;
}
C

clang -target "$TARGET" -isysroot "$MR/sdk" -fPIC -fno-builtin -O0 \
      -c "$tmp/overlay.c" -o "$tmp/overlay.o" 2>"$tmp/cc.log" \
  || { echo "FAIL overlay compile"; sed 's/^/    /' "$tmp/cc.log"; exit 1; }
ld64.lld -dylib -arch "$ARCH" -platform_version macos 11.0 11.0 \
         -undefined dynamic_lookup \
         -install_name /usr/lib/swift/libfakeoverlay.dylib \
         -o "$tmp/libfakeoverlay.dylib" "$tmp/overlay.o" 2>"$tmp/ld.log" \
  || { echo "FAIL overlay link"; sed 's/^/    /' "$tmp/ld.log"; exit 1; }

fix=$tmp/darwin
mkdir -p "$fix/usr/lib/swift"
for d in libSystem.B.dylib libc++.1.dylib libc++abi.dylib libobjc.A.dylib; do
    [ -f "$MR/darwin/usr/lib/$d" ] || { echo "FAIL missing $d"; exit 1; }
    ln -s "$MR/darwin/usr/lib/$d" "$fix/usr/lib/$d"
done
cp -a "$tmp/libfakeoverlay.dylib" "$fix/usr/lib/swift/libfakeoverlay.dylib"

echo "  linked $ARCH overlay; libswiftcompat deliberately absent"
set +e
out=$("$check" --strict "$fix" 2>&1)
rc=$?
set -e
printf '%s\n' "$out" | head -40

if [ "$rc" -eq 0 ]; then
    echo "  OK  --strict exits 0 on the operator-shaped root"
else
    echo "  FAIL --strict exited $rc (build.sh tbd would fail)"
    printf '%s\n' "$out" | sed 's/^/    /'
    fail=1
fi

while IFS= read -r s; do
    [ -n "$s" ] || continue
    if printf '%s\n' "$out" | grep -q "$s"; then
        if printf '%s\n' "$out" | grep "$s" | grep -q 'libclang_rt.osx.a'; then
            echo "  OK  $s tagged with the archive"
        else
            echo "  FAIL $s listed without naming libclang_rt.osx.a"
            fail=1
        fi
    else
        echo "  FAIL $s not listed (fixture should still import it)"
        fail=1
    fi
done <<EOF
$RT_MACHO
EOF

# Group 2 is implemented in libSystem/libc++ -- must not be unaccounted, and
# should not appear as a plain missing name at all.
for s in _fmal _flockfile _funlockfile _dispatch_once_f __dyld_is_objc_constant \
         __NSGetMachExecuteHeader \
         __ZNSt3__122__libcpp_verbose_abortEPKcz \
         __ZNSt3__16thread20hardware_concurrencyEv \
         __ZNSt3__1plIcNS_11char_traitsIcEENS_9allocatorIcEEEENS_12basic_stringIT_T0_T1_EEPKS6_RKS9_; do
    if printf '%s\n' "$out" | grep -E "^ +${s}[[:space:]]" | grep -q 'DENIED'; then
        echo "  FAIL $s is denied; it should be defined by libSystem/libc++"
        fail=1
    elif printf '%s\n' "$out" | grep -qE "^ +${s}[[:space:]]"; then
        echo "  FAIL $s still a plain missing name (libSystem/libc++ should define it)"
        fail=1
    else
        echo "  OK  $s is defined in the fixture root (not a CHECK 5 finding)"
    fi
done

if printf '%s\n' "$out" | grep -q "nobody's assertion behind them"; then
    echo "  FAIL --strict printed the unaccounted-name error"
    fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
    echo "PASS -- compiler-rt builtins are denied-via-archive, not host-bound-allowed"
    exit 0
fi
echo "FAIL"
exit 1
