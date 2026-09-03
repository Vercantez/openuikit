#!/bin/bash
# build_cfobjc.sh -- compile CoreFoundation objects into $W/cfobjc/obj.
#
#   TRIPLE=x86_64-apple-macos13.0 bash foundation-macho/scripts/build_cfobjc.sh
#   bash foundation-macho/scripts/build_cfobjc.sh --print-argv
#
# THIS IS THE RECIPE /work/cfobjc NEVER HAD. docs/CF_PREFERENCES_EXECUTION.md
# recorded that the objects build_cftest_harness.sh links were produced by
# hand; cf_census.sh's flags reproduce CFPreferences.o and diverge on 32
# files. This script is the census argv PLUS every flag and patch the tree
# already names as load-bearing for the objects that actually linked
# libCFTest. Every flag below cites its evidence. Do not add a flag that
# cannot.
#
# CANONICAL ARGV (the test greps this block and the printed CFOBJC_ARGV line):
#   -target $TRIPLE                         guest_arch.inc; cf_census.sh
#   -isysroot $SDK                          cf_census.sh
#   -x objective-c                          patch_cf_objc.py (76/82 vs 77/82 as C)
#   -fobjc-runtime=macosx-13.0              classify_ns_names.sh, build_cf_probes.sh
#   -fno-objc-arc                           every ObjC compile in this lane
#   -DINCLUDE_OBJC=1                        patch_cf_objc.py; CoreFoundation_Prefix.h:87
#   -DCF_BUILDING_CF                        cf_census.sh
#   -DDEPLOYMENT_RUNTIME_SWIFT=0            cf_census.sh; docs/DECISION.md
#   -DHAVE_STRUCT_TIMESPEC                  cf_census.sh
#   -DSWIFT_CORELIBS_FOUNDATION_HAS_THREADS=1  docs/cf-census/nine-own-exports.md
#   -fblocks -fconstant-cfstrings           cf_census.sh; NSCF_DESIGN.md
#   -fdollars-in-identifiers -fno-common    cf_census.sh
#   -fcf-runtime-abi=objc                   cf_census.sh; CF_TRIAGE.md §7 (NOT =swift)
#   -fexceptions -Os                        cf_census.sh
#   -include CoreFoundation_Prefix.h        cf_census.sh
#   -include CFShimCarbon.h                 cf_census.sh; cf_shims.sh
#   -include CFNSForwards.h                 gen_ns_forwards.py (ObjC class names)
#   -include CFFoundationInterfaces.h       its own comment: FORCE-included
#   -Dd_fileno=d_ino                        cf_census.sh
#   -DDISPATCH_APPLY_AUTO=((dispatch_queue_t)0)  cf_census.sh
#   -idirafter $X                           cf_census.sh (cfextra shims)
#   -I $CF/include -I $CF/internalInclude   cf_census.sh
#   -I $OURINC                              classify_ns_names.sh
#   -I $ICU_INC                             cf_census.sh (unblocks ICU TUs)
#
# Sources: $CF/*.c only (86 TUs). cf_census.sh's loop is `for f in "$CF"/*.c`.
# CF_PREFERENCES_EXECUTION.md's "86 objects compiled" is that glob, including
# the 4 EMPTY TUs the census then drops. BlockRuntime/*.c is not in the glob.
# uuid.c sits in that glob (pass-79.txt).
#
# Patches applied to a COPY under $OUT/src, never to the caller's tree:
#   patch_cf_objc.py          (dispatch macros + delete CF's const-string def)
#   patch_cf_runloop.py       (epoll on Darwin)
#   patch_cf_prefs_binary.py  (Darwin writes bplist00)
#   patch_cf_knownlocations.py
#   gen_alias_shims.py        (99 kCF* .set aliases; nine-own-exports.md)
#
# Why census flags alone diverge (the 32-file / 101-symbol wall):
#   census compiles as C, not -x objective-c / -DINCLUDE_OBJC=1
#   census does not delete ___CFConstantStringClassReference from CFRuntime.c
#   census does not append the CFLocaleKeys .set aliases
#   census may omit ICU_INC, so CFLocaleKeys.o loses kCFNumberFormatter*
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
FM=$(cd "$HERE/.." && pwd)
# shellcheck disable=SC1091
. "$HERE/guest_arch.inc"

PRINT_ARGV=0
if [ "${1:-}" = "--print-argv" ]; then
    PRINT_ARGV=1
    shift
fi

CC=${CC:-}
if [ -z "$CC" ]; then
    if command -v clang-18 >/dev/null 2>&1; then CC=clang-18
    elif command -v clang >/dev/null 2>&1; then CC=clang
    else
        echo "build_cfobjc: no clang-18/clang" >&2
        exit 2
    fi
fi

W=${W:-/work}
MONO=$(cd "$FM/.." && pwd)
OURINC=${OURINC:-$FM/include}

find_cf() {
    local c
    for c in \
        "${CF:-}" \
        "$W/cf/Sources/CoreFoundation" \
        "$W/cf" \
        "$W/cfobjc/src" \
        /work/cf \
        "$HOME/scf-full/Sources/CoreFoundation" \
        "$MONO/scratch/swift-corelibs-foundation/Sources/CoreFoundation" \
        "$MONO/scratch/scf/Sources/CoreFoundation"
    do
        [ -n "$c" ] || continue
        [ -f "$c/CFRuntime.c" ] && [ -f "$c/CFPreferences.c" ] || continue
        printf '%s\n' "$c"
        return 0
    done
    return 1
}

find_sdk() {
    local c
    for c in \
        "${SDK:-}" \
        "$W/sdk/MacOSX.sdk" \
        "$W/fe/sysroot" \
        "$MONO/scratch/sysroot_fe4-x86_64" \
        "$MONO/scratch/sysroot_fe4" \
        "$MONO/machorun/sdk"
    do
        [ -n "$c" ] || continue
        [ -d "$c/usr/include" ] || continue
        printf '%s\n' "$c"
        return 0
    done
    return 1
}

find_icu() {
    local c
    for c in \
        "${ICU_INC:-}" \
        "$W/icuSources/include" \
        "$MONO/scratch/swift-foundation-icu/icuSources/include" \
        "$HOME/swift-foundation-icu/icuSources/include"
    do
        [ -n "$c" ] || continue
        [ -d "$c" ] || continue
        printf '%s\n' "$c"
        return 0
    done
    return 1
}

SDK=$(find_sdk || true)
CF_IN=$(find_cf || true)
ICU_INC=$(find_icu || true)
OUT=${OUT:-$W/cfobjc}
X=${X:-$OUT/cfextra}

# The argv the compiler actually gets. Placeholders when --print-argv runs
# without a tree, so the test can still lock the flag set.
sdk_print=${SDK:-'$SDK'}
cf_print=${CF_IN:-'$CF'}
x_print=${X:-'$X'}
our_print=$OURINC
icu_flags=()
icu_print=()
if [ -n "$ICU_INC" ]; then
    icu_flags=(-I "$ICU_INC")
    icu_print=(-I "$ICU_INC")
else
    icu_print=(-I '$ICU_INC')
fi

# Quoted DISPATCH_APPLY_AUTO: cf_census.sh puts the same token in CFLAGS.
# Parentheses must not be globbed.
build_cfobjc_argv() {
    local sdk=$1 cf=$2 x=$3
    CFOBJC_ARGV=(
        "$CC"
        -target "$TRIPLE"
        -isysroot "$sdk"
        -x objective-c
        -fobjc-runtime=macosx-13.0
        -fno-objc-arc
        -I "$cf/include"
        -I "$cf/internalInclude"
        -I "$our_print"
        "${icu_flags[@]}"
        -DCF_BUILDING_CF
        -DDEPLOYMENT_RUNTIME_SWIFT=0
        -DHAVE_STRUCT_TIMESPEC
        -DINCLUDE_OBJC=1
        -DSWIFT_CORELIBS_FOUNDATION_HAS_THREADS=1
        -fblocks
        -fconstant-cfstrings
        -fdollars-in-identifiers
        -fno-common
        -fcf-runtime-abi=objc
        -fexceptions
        -Os
        -include "$cf/internalInclude/CoreFoundation_Prefix.h"
        -include "$x/CFShimCarbon.h"
        -include "$our_print/CFNSForwards.h"
        -include "$our_print/CFFoundationInterfaces.h"
        -Dd_fileno=d_ino
        -idirafter "$x"
        -DDISPATCH_APPLY_AUTO='((dispatch_queue_t)0)'
        -Wno-unused-parameter
        -Wno-unused-variable
        -Wno-unused-function
        -Wno-sign-compare
        -Wno-deprecated-declarations
        -Wno-nullability-completeness
        -Wno-objc-root-class
    )
}

build_cfobjc_argv "$sdk_print" "$cf_print" "$x_print"
# Re-print with placeholders for the stable test surface when paths vary.
CFOBJC_ARGV_DOC=(
    "$CC"
    -target "$TRIPLE"
    -isysroot '$SDK'
    -x objective-c
    -fobjc-runtime=macosx-13.0
    -fno-objc-arc
    -I '$CF/include'
    -I '$CF/internalInclude'
    -I '$OURINC'
    -I '$ICU_INC'
    -DCF_BUILDING_CF
    -DDEPLOYMENT_RUNTIME_SWIFT=0
    -DHAVE_STRUCT_TIMESPEC
    -DINCLUDE_OBJC=1
    -DSWIFT_CORELIBS_FOUNDATION_HAS_THREADS=1
    -fblocks
    -fconstant-cfstrings
    -fdollars-in-identifiers
    -fno-common
    -fcf-runtime-abi=objc
    -fexceptions
    -Os
    -include '$CF/internalInclude/CoreFoundation_Prefix.h'
    -include '$X/CFShimCarbon.h'
    -include '$OURINC/CFNSForwards.h'
    -include '$OURINC/CFFoundationInterfaces.h'
    -Dd_fileno=d_ino
    -idirafter '$X'
    -DDISPATCH_APPLY_AUTO='((dispatch_queue_t)0)'
)

echo "CFOBJC_ARGV: ${CFOBJC_ARGV_DOC[*]}"
echo "CFOBJC_TRIPLE=$TRIPLE"
echo "CFOBJC_ARCH=$ARCH"
echo "CFOBJC_RECIPE=cfobjc.1"

if [ "$PRINT_ARGV" -eq 1 ]; then
    exit 0
fi

if [ -z "$SDK" ]; then
    echo "build_cfobjc: no Darwin sysroot (set SDK=). Looked at W/sdk, W/fe/sysroot, scratch/sysroot_fe4{,-x86_64}, machorun/sdk." >&2
    exit 2
fi
if [ -z "$CF_IN" ]; then
    echo "build_cfobjc: no CoreFoundation sources (set CF= to Sources/CoreFoundation). Need CFRuntime.c + CFPreferences.c." >&2
    exit 2
fi
if [ ! -f "$OURINC/CFFoundationInterfaces.h" ] || [ ! -f "$OURINC/CFNSForwards.h" ]; then
    echo "build_cfobjc: missing $OURINC/CFFoundationInterfaces.h or CFNSForwards.h" >&2
    exit 2
fi

NM=${NM:-llvm-nm-18}
command -v "$NM" >/dev/null 2>&1 || NM=llvm-nm

set -e
mkdir -p "$OUT/obj" "$OUT/log" "$OUT/src"
X=$OUT/cfextra
bash "$HERE/cf_shims.sh" "$X"

# stage_sdk.sh copies swiftcore-macho/sdk/libc/setjmp.h into the CF MacOSX.sdk.
# The FE sysroot phase2 points at (scratch/sysroot_fe4*) never got that copy,
# and CoreFoundation.h includes <setjmp.h> at file scope. Without it, CFBundle
# and CFLocale fail on a missing libc header rather than on CF. Same file,
# same reason: only the type is used (the header says CF does not call setjmp).
if [ ! -f "$SDK/usr/include/setjmp.h" ]; then
    libc_setjmp=$MONO/swiftcore-macho/sdk/libc/setjmp.h
    if [ -f "$libc_setjmp" ]; then
        cp "$libc_setjmp" "$X/setjmp.h"
    fi
fi
# stage_sdk.sh copies objc4-priv (mach-o/dyld_priv.h) into the CF sysroot.
# CFBundle_Binary.c and CFBundle_Grok.c include it; the FE sysroot does not
# carry it. Same file, via -idirafter, so the census TUs that need it exist.
if [ ! -f "$SDK/usr/include/mach-o/dyld_priv.h" ]; then
    dyld_priv=$MONO/machorun/vendor/objc4-priv/mach-o/dyld_priv.h
    if [ -f "$dyld_priv" ]; then
        mkdir -p "$X/mach-o"
        cp "$dyld_priv" "$X/mach-o/dyld_priv.h"
    fi
fi
# scratch/sysroot_fe4 is an arm64 FE tree; machine/_types.h still branches to
# i386/_types.h for x86_64, and that file lives in machorun/sdk. Without it
# every TU dies on a missing machine header before CF is reached. Same fill
# as setjmp: a header the pointed-at sysroot's own include graph names.
case "$TRIPLE" in
    x86_64-*)
        if [ ! -f "$SDK/usr/include/i386/_types.h" ]; then
            mr_inc=$MONO/machorun/sdk/usr/include
            for sub in i386 mach/i386 libkern/i386; do
                if [ -d "$mr_inc/$sub" ]; then
                    mkdir -p "$X/$sub"
                    cp -a "$mr_inc/$sub/." "$X/$sub/"
                fi
            done
        fi
        ;;
esac

# Copy then patch. The caller's CF tree is not ours to mutate (operator pins,
# git checkouts). Patch scripts are idempotent on the copy.
if [ ! -f "$OUT/src/.cfobjc-copied" ] || [ "${CFOBJC_FORCE_COPY:-0}" = 1 ]; then
    rm -rf "$OUT/src"
    mkdir -p "$OUT/src"
    # Headers + top-level .c only (census glob). Skip BlockRuntime and Tools.
    cp -a "$CF_IN/." "$OUT/src/"
    rm -rf "$OUT/src/BlockRuntime" "$OUT/src/Tools"
    : > "$OUT/src/.cfobjc-copied"
fi
CF=$OUT/src

python3 "$HERE/patch_cf_objc.py" "$CF"
python3 "$HERE/patch_cf_runloop.py" "$CF"
python3 "$HERE/patch_cf_prefs_binary.py" "$CF"
python3 "$HERE/patch_cf_knownlocations.py" "$CF"
python3 "$HERE/gen_alias_shims.py" "$CF"
set +e

build_cfobjc_argv "$SDK" "$CF" "$X"
echo "CFOBJC_ARGV_RESOLVED: ${CFOBJC_ARGV[*]}"
printf '%s\n' "${CFOBJC_ARGV[@]}" > "$OUT/argv.txt"
{
    echo "recipe=cfobjc.1"
    echo "triple=$TRIPLE"
    echo "cf_in=$CF_IN"
    echo "sdk=$SDK"
    echo "icu=${ICU_INC:-ABSENT}"
} > "$OUT/stamp.txt"

shopt -s nullglob
pass=0; fail=0; empty=0
: > "$OUT/PASS.txt"; : > "$OUT/FAIL.txt"; : > "$OUT/EMPTY.txt"

for f in "$CF"/*.c; do
    b=$(basename "$f" .c)
    if "${CFOBJC_ARGV[@]}" -c "$f" -o "$OUT/obj/$b.o" 2>"$OUT/log/$b.err"; then
        n=$("$NM" --defined-only --extern-only "$OUT/obj/$b.o" 2>/dev/null | wc -l)
        n=${n:-0}
        if [ "$n" -eq 0 ]; then
            echo "$b" >> "$OUT/EMPTY.txt"
            empty=$((empty + 1))
            rm -f "$OUT/obj/$b.o"
        else
            echo "$b" >> "$OUT/PASS.txt"
            pass=$((pass + 1))
        fi
    else
        echo "$b" >> "$OUT/FAIL.txt"
        fail=$((fail + 1))
        rm -f "$OUT/obj/$b.o"
        echo "  FAIL $b: $(grep -m1 -E 'error:' "$OUT/log/$b.err" | sed 's/.*error: //' | cut -c1-80)"
    fi
done

echo "CFOBJC_RESULT PASS=$pass FAIL=$fail EMPTY=$empty OUT=$OUT/obj"
echo "CFOBJC_SOURCES=$CF/*.c (86-file census glob; empty TUs dropped like cf_census.sh)"
if [ "$pass" -eq 0 ]; then
    echo "build_cfobjc: zero passing objects; refusing to call this a CF build." >&2
    exit 2
fi
# The shipped libCFTest linked the non-empty set. A handful of remaining
# FAILs is a named wall (cf_census.sh FAIL.txt), not a reason to throw away
# the objects that did compile.
exit 0
