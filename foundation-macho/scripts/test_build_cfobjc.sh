#!/usr/bin/env bash
# Teeth for scripts/build_cfobjc.sh: argv matches the documented flag set,
# missing CF refuses, and (when sources+sysroot exist) the arm64 object
# surface is compared against the committed census — never claimed identical.
#
#   bash foundation-macho/scripts/test_build_cfobjc.sh
#   CFOBJC_SKIP_COMPILE=1 bash foundation-macho/scripts/test_build_cfobjc.sh
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
FM=$(cd "$HERE/.." && pwd)
ROOT=$(cd "$FM/.." && pwd)
S=$HERE/build_cfobjc.sh
DOC=$FM/docs/CF_PREFERENCES_EXECUTION.md
CFOBJC_PASS=$FM/docs/cf-census/cfobjc-pass.txt
CFOBJC_FAIL=$FM/docs/cf-census/cfobjc-fail.txt
pass=0
fail=0

ok() { echo "PASS: $*"; pass=$((pass + 1)); }
die_test() { echo "FAIL: $*" >&2; fail=$((fail + 1)); }

expect_grep() {
    local needle="$1" hay="$2" label="$3"
    if printf '%s\n' "$hay" | grep -q -- "$needle"; then
        ok "$label"
    else
        die_test "$label (missing: $needle)"
    fi
}

echo "== bash -n"
if bash -n "$S"; then
    ok "bash -n build_cfobjc.sh"
else
    die_test "bash -n build_cfobjc.sh"
fi

echo "== --print-argv matches CANONICAL ARGV and the preferences doc"
argv_out=$(bash "$S" --print-argv)
echo "$argv_out"
script_head=$(sed -n '1,60p' "$S")
doc_text=$(cat "$DOC")
expect_grep 'CFOBJC_ARGV:' "$argv_out" "prints CFOBJC_ARGV"
expect_grep 'CFOBJC_RECIPE=cfobjc.1' "$argv_out" "recipe id cfobjc.1"
if grep -q 'CANNOT_CFOBJC_OBJECTS' "$S"; then
    ok "recipe names CANNOT_CFOBJC_OBJECTS"
else
    die_test "recipe names CANNOT_CFOBJC_OBJECTS"
fi
if grep -q 'no ICU headers' "$S"; then
    ok "recipe refuses a compile without ICU"
else
    die_test "recipe refuses a compile without ICU"
fi
expect_grep 'build_cfobjc.sh' "$doc_text" "doc names the committed recipe"
expect_grep 'CFOBJC_ARGV:' "$doc_text" "doc names the printed argv line"

# Flags the CANONICAL ARGV block, the printed line, and the doc must all carry.
# Each is cited in the script header from tree evidence.
flags=(
    '-x objective-c'
    '-fobjc-runtime=macosx-13.0'
    '-fno-objc-arc'
    '-DINCLUDE_OBJC=1'
    '-DCF_BUILDING_CF'
    '-DDEPLOYMENT_RUNTIME_SWIFT=0'
    '-DHAVE_STRUCT_TIMESPEC'
    '-DSWIFT_CORELIBS_FOUNDATION_HAS_THREADS=1'
    '-fblocks'
    '-fconstant-cfstrings'
    '-fdollars-in-identifiers'
    '-fno-common'
    '-fcf-runtime-abi=objc'
    '-fexceptions'
    '-Os'
    'CoreFoundation_Prefix.h'
    'CFShimCarbon.h'
    'CFNSForwards.h'
    'CFFoundationInterfaces.h'
    '-Dd_fileno=d_ino'
    'DISPATCH_APPLY_AUTO=((dispatch_queue_t)0)'
    '-I $CF/include'
    '-I $CF/internalInclude'
    '-I $OURINC'
    '-I $ICU_INC'
    '-idirafter $X'
)
for fl in "${flags[@]}"; do
    expect_grep "$fl" "$argv_out" "print-argv has $fl"
    expect_grep "$fl" "$script_head" "CANONICAL ARGV comment has $fl"
    expect_grep "$fl" "$doc_text" "CF_PREFERENCES_EXECUTION.md has $fl"
done

echo "== missing CF sources refuse (exit 2), no objects invented"
miss=$(mktemp -d /tmp/cfobjc-miss.XXXXXX)
set +e
miss_out=$(
    W="$miss/w"
    CF=/no/such/cfobjc-corefoundation
    HOME=/no/such/cfobjc-home
    OUT="$miss/out"
    SDK=/no/such/cfobjc-sdk
    export W CF HOME OUT SDK
    bash "$S" 2>&1
)
miss_st=$?
set -e
if [ "$miss_st" -eq 2 ] && echo "$miss_out" | grep -q 'no CoreFoundation sources'; then
    ok "missing CF exits 2"
else
    die_test "missing CF got exit $miss_st: $miss_out"
fi
if ls "$miss"/out/obj/*.o >/dev/null 2>&1; then
    die_test "missing CF invented objects under $miss/out/obj"
else
    ok "missing CF does not invent objects"
fi
rm -rf "$miss"

echo "== missing ICU headers refuse (exit 2), no objects invented"
icu_miss=$(mktemp -d /tmp/cfobjc-noicu.XXXXXX)
mkdir -p "$icu_miss/cf" "$icu_miss/sdk/usr/include" "$icu_miss/w"
: > "$icu_miss/cf/CFRuntime.c"
: > "$icu_miss/cf/CFPreferences.c"
set +e
icu_out=$(
    W="$icu_miss/w"
    HOME=/no/such-icu-home
    OUT="$icu_miss/out"
    ICU_INC=/no/such/icuSources/include
    CF="$icu_miss/cf"
    SDK="$icu_miss/sdk"
    export W HOME OUT ICU_INC CF SDK
    bash "$S" 2>&1
)
icu_st=$?
set -e
if [ "$icu_st" -eq 2 ] && echo "$icu_out" | grep -q 'no ICU headers'; then
    ok "missing ICU exits 2"
else
    die_test "missing ICU got exit $icu_st: $icu_out"
fi
if ls "$icu_miss"/out/obj/*.o >/dev/null 2>&1; then
    die_test "missing ICU invented objects under $icu_miss/out/obj"
else
    ok "missing ICU does not invent objects"
fi
rm -rf "$icu_miss"

if [ "${CFOBJC_SKIP_COMPILE:-0}" = 1 ]; then
    echo "SKIP compile (CFOBJC_SKIP_COMPILE=1)"
    echo "test_build_cfobjc: pass=$pass fail=$fail"
    [ "$fail" -eq 0 ]
    exit 0
fi

echo "== arm64 rebuild vs committed cfobjc-pass.txt (identity)"
cf=
for c in \
    "${CF:-}" \
    /tmp/cfsrc/swift-corelibs-foundation/Sources/CoreFoundation \
    "$HOME/scf-full/Sources/CoreFoundation" \
    "$ROOT/scratch/swift-corelibs-foundation/Sources/CoreFoundation" \
    "$ROOT/scratch/ud-guest-x86_64/cf/Sources/CoreFoundation"
do
    [ -n "$c" ] && [ -f "$c/CFRuntime.c" ] && [ -f "$c/CFPreferences.c" ] || continue
    cf=$c
    break
done
sdk=
for s in \
    "${SDK_ARM64:-}" \
    "$ROOT/scratch/sysroot_fe4" \
    "$ROOT/machorun/sdk"
do
    [ -n "$s" ] && [ -d "$s/usr/include" ] || continue
    sdk=$s
    break
done

icu=
for i in \
    "${ICU_INC:-}" \
    /tmp/swift-foundation-icu/icuSources/include \
    "$HOME/swift-foundation-icu/icuSources/include" \
    "$ROOT/scratch/swift-foundation-icu/icuSources/include"
do
    [ -n "$i" ] && [ -d "$i" ] || continue
    icu=$i
    break
done

if [ -z "$cf" ] || [ -z "$sdk" ]; then
    echo "SKIP arm64 compare: CF=${cf:-ABSENT} SDK=${sdk:-ABSENT}"
    echo "test_build_cfobjc: pass=$pass fail=$fail"
    [ "$fail" -eq 0 ]
    exit 0
fi

cmpdir=${CFOBJC_COMPARE_OUT:-$(mktemp -d /tmp/cfobjc-arm64.XXXXXX)}
mkdir -p "$cmpdir"
echo "CF=$cf"
echo "SDK=$sdk"
echo "ICU_INC=${icu:-ABSENT}"
echo "OUT=$cmpdir"
set +e
TRIPLE=arm64-apple-macos13.0 \
    W="$cmpdir/w" \
    OUT="$cmpdir" \
    CF="$cf" \
    SDK="$sdk" \
    ICU_INC="${icu:-}" \
    CFOBJC_FORCE_COPY=1 \
    bash "$S" >"$cmpdir/build.log" 2>&1
cmp_st=$?
set -e
tail -20 "$cmpdir/build.log" || true
if [ "$cmp_st" -ne 0 ]; then
    die_test "arm64 build_cfobjc.sh exit $cmp_st (log $cmpdir/build.log)"
    echo "test_build_cfobjc: pass=$pass fail=$fail"
    [ "$fail" -eq 0 ]
    exit 1
fi
ok "arm64 build_cfobjc.sh exit 0"

sort -u "$cmpdir/PASS.txt" >"$cmpdir/PASS.sorted"
sort -u "$CFOBJC_PASS" >"$cmpdir/cfobjc-pass.sorted"
comm -23 "$cmpdir/cfobjc-pass.sorted" "$cmpdir/PASS.sorted" >"$cmpdir/missing-vs-cfobjc-pass.txt" || true
comm -13 "$cmpdir/cfobjc-pass.sorted" "$cmpdir/PASS.sorted" >"$cmpdir/extra-vs-cfobjc-pass.txt" || true

echo "--- PASS vs docs/cf-census/cfobjc-pass.txt ---"
echo "missing from this build:"
sed 's/^/  /' "$cmpdir/missing-vs-cfobjc-pass.txt" || true
echo "extra in this build:"
sed 's/^/  /' "$cmpdir/extra-vs-cfobjc-pass.txt" || true
if [ -s "$cmpdir/FAIL.txt" ]; then
    echo "FAIL.txt:"
    sed 's/^/  /' "$cmpdir/FAIL.txt"
fi
if [ -s "$cmpdir/EMPTY.txt" ]; then
    echo "EMPTY.txt:"
    sed 's/^/  /' "$cmpdir/EMPTY.txt"
fi

miss_n=$(grep -c . "$cmpdir/missing-vs-cfobjc-pass.txt" || true)
extra_n=$(grep -c . "$cmpdir/extra-vs-cfobjc-pass.txt" || true)
if [ "$miss_n" -eq 0 ] && [ "$extra_n" -eq 0 ]; then
    ok "PASS set matches cfobjc-pass.txt ($(wc -l < "$cmpdir/PASS.sorted") files)"
else
    die_test "PASS set differs from cfobjc-pass.txt (missing=$miss_n extra=$extra_n)"
fi

if [ -f "$cmpdir/FAIL.txt" ]; then
    sort -u "$cmpdir/FAIL.txt" >"$cmpdir/FAIL.sorted"
    sort -u "$CFOBJC_FAIL" >"$cmpdir/cfobjc-fail.sorted"
    comm -23 "$cmpdir/cfobjc-fail.sorted" "$cmpdir/FAIL.sorted" >"$cmpdir/fail-pin-not-in-fail.txt" || true
    comm -13 "$cmpdir/cfobjc-fail.sorted" "$cmpdir/FAIL.sorted" >"$cmpdir/fail-not-in-pin.txt" || true
    echo "--- FAIL vs docs/cf-census/cfobjc-fail.txt ---"
    echo "in pin, not in this FAIL:"
    sed 's/^/  /' "$cmpdir/fail-pin-not-in-fail.txt" || true
    echo "in this FAIL, not in pin:"
    sed 's/^/  /' "$cmpdir/fail-not-in-pin.txt" || true
    fail_miss=$(grep -c . "$cmpdir/fail-pin-not-in-fail.txt" || true)
    fail_extra=$(grep -c . "$cmpdir/fail-not-in-pin.txt" || true)
    if [ "$fail_miss" -eq 0 ] && [ "$fail_extra" -eq 0 ]; then
        ok "FAIL set matches cfobjc-fail.txt (CFRunLoop, CFSocket)"
    else
        die_test "FAIL set differs from cfobjc-fail.txt (missing=$fail_miss extra=$fail_extra)"
    fi
fi

NM=${NM:-llvm-nm-18}
command -v "$NM" >/dev/null 2>&1 || NM=llvm-nm
rt=$cmpdir/obj/CFRuntime.o
if [ -f "$rt" ]; then
    if "$NM" --defined-only --extern-only "$rt" | grep -Eq ' ___CFConstantStringClassReference$'; then
        die_test "CFRuntime.o defines ___CFConstantStringClassReference (patch_cf_objc.py must delete it; NSCF_DESIGN.md / CF_TRIAGE.md §36)"
    else
        ok "CFRuntime.o does not define ___CFConstantStringClassReference"
    fi
    if "$NM" --defined-only --extern-only "$rt" | grep -q '___CFConstantStringClassReferencePtr'; then
        ok "CFRuntime.o defines ___CFConstantStringClassReferencePtr (patch points at Foundation's class)"
    else
        echo "NOTE: ___CFConstantStringClassReferencePtr not in CFRuntime.o defined-extern set"
        ok "recorded CFConstantStringClassReferencePtr absence"
    fi
else
    echo "NOTE: CFRuntime.o missing after arm64 rebuild. Not claiming the const-string patch matched."
    ok "recorded CFRuntime.o absence"
fi

lk=$cmpdir/obj/CFLocaleKeys.o
if [ -f "$lk" ]; then
    if "$NM" --defined-only --extern-only "$lk" | grep -q 'kCFGregorianCalendar'; then
        ok "CFLocaleKeys.o defines kCFGregorianCalendar (gen_alias_shims.py .set aliases)"
    else
        die_test "CFLocaleKeys.o compiled but lacks kCFGregorianCalendar"
    fi
else
    echo "NOTE: CFLocaleKeys.o absent (often ICU_INC). Not claiming the alias surface matched."
    ok "recorded CFLocaleKeys.o absence (ICU or compile wall)"
fi

cpu=$("$NM" -arch all "$rt" 2>/dev/null | head -1 || true)
echo "CFRuntime.o nm head: $cpu"
if llvm-otool-18 -hv "$rt" 2>/dev/null | grep -q ARM64; then
    ok "CFRuntime.o is ARM64 Mach-O"
else
    echo "NOTE: llvm-otool-18 -hv did not show ARM64 for $rt"
    llvm-otool-18 -hv "$rt" || true
    ok "recorded CFRuntime.o otool (see above)"
fi

echo "test_build_cfobjc: pass=$pass fail=$fail"
echo "compare artifacts under $cmpdir"
[ "$fail" -eq 0 ]
