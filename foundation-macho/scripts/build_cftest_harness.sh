#!/bin/bash
# Rebuild probe + stubs, link libCFTest.
#
# THE STUB SET IS DERIVED EVERY RUN, NOT CACHED. It used to read
# /work/stub-{data,func}.txt written by an earlier session. The moment CF began
# defining the 99 CFLocaleKeys aliases for real, those files still listed six of
# them and the link failed with "duplicate symbol: kCFGregorianCalendar" -- a
# stub for something that now exists. A cached list of what is missing is a
# claim with no version in it, which is the same defect as a transcribed alias
# list or a stale backup. So: link once to find out what is undefined, then
# stub exactly that.
#
# Reuse of lib/libCFTest.dylib is keyed on lib/libCFTest.dylib.inputs, written
# at link time: sha256 of every object linked (cfobjc + nscf + probe +
# cfstubs.o), the stub-set files, the libSystem/libobjc tbds, and the linker
# argv. A present dylib whose sibling stub text files match the pin is NOT
# enough — that is how a regenerated 214-name list sat next to a 143-stub
# dylib. Matching stamp → reused=1 stamp=<sha>. Mismatch →
# reason=inputs <key> old->new and relink. stub-func-active.txt newer than
# the dylib is a CANNOT naming both mtimes in verify-only (CFTEST_VERIFY_ONLY=1),
# and a forced relink otherwise.
#
# Objects come from scripts/build_cfobjc.sh ($W/cfobjc/obj/*.o) and from the
# NS* surface compiled here ($W/nscfobj/*.o) with the argv build_cf_probes.sh
# already committed for NSCFConstantString.m. This script is the LINKER
# (and the nscf compile). It does not compile CoreFoundation.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
FM=$(cd "$HERE/.." && pwd)
# shellcheck disable=SC1091
. "$HERE/guest_arch.inc"

W=${W:-/work}
R=${R:-$FM}
SDK=${SDK:-$W/sdk/MacOSX.sdk}
if [ ! -d "$SDK/usr/include" ]; then
    echo "build_cftest_harness: no sysroot at SDK=$SDK" >&2
    exit 2
fi
CC=${CC:-}
if [ -z "$CC" ]; then
    if command -v clang-18 >/dev/null 2>&1; then CC=clang-18
    elif command -v clang >/dev/null 2>&1; then CC=clang
    else
        echo "build_cftest_harness: no clang-18/clang" >&2
        exit 2
    fi
fi
LLD=${LLD_BIN:-/usr/lib/llvm-18/bin}
LIB=${LIB:-$W/lib}
CFOBJC_OBJ=${CFOBJC_OBJ:-$W/cfobjc/obj}
NSCF_OBJ=${NSCF_OBJ:-$W/nscfobj}
PROBE_SRC=${PROBE_SRC:-$R/tests/probe_sysctl.c}
CF=${CF:-$W/cfobjc/src}
[ -f "$CF/CFRuntime.c" ] || CF=${CF_FALLBACK:-$W/cf}
CFEXTRA=${CFEXTRA:-$W/cfobjc/cfextra}
if [ ! -d "$CFEXTRA" ]; then
    CFEXTRA=$(dirname "$CFOBJC_OBJ")/cfextra
fi
extra_inc=()
if [ -d "$CFEXTRA" ]; then
    extra_inc=(-idirafter "$CFEXTRA")
fi
CFTEST_EXPECT_FUNC=${CFTEST_EXPECT_FUNC:-$FM/docs/cf-census/cftest-stub-func-active.txt}
CFTEST_EXPECT_DATA=${CFTEST_EXPECT_DATA:-$FM/docs/cf-census/cftest-stub-data.txt}

mkdir -p "$LIB" "$NSCF_OBJ" "$W" /tmp
shopt -s nullglob

cftest_file_sha() {
    if [ -f "$1" ]; then
        sha256sum "$1" | awk '{print $1}'
    else
        printf 'ABSENT\n'
    fi
}

cftest_mtime_iso() {
    if [ -e "$1" ]; then
        date -u -r "$1" '+%Y-%m-%dT%H:%M:%SZ'
    else
        printf 'ABSENT\n'
    fi
}

cftest_tbd() {
    local base=$1 f
    for f in "$SDK/usr/lib/${base}.tbd" \
             "$SDK/usr/lib/${base}.B.tbd" \
             "$SDK/usr/lib/${base}.A.tbd"; do
        if [ -e "$f" ]; then
            printf '%s\n' "$f"
            return 0
        fi
    done
    printf '%s\n' "$SDK/usr/lib/${base}.tbd"
}

cftest_obj_key() {
    local o=$1
    case "$o" in
        "$CFOBJC_OBJ"/*) printf 'obj:cfobjc/%s\n' "$(basename "$o")" ;;
        "$NSCF_OBJ"/*) printf 'obj:nscfobj/%s\n' "$(basename "$o")" ;;
        *) printf 'obj:%s\n' "$(basename "$o")" ;;
    esac
}

cftest_linked_objects() {
    local o
    [ -f "$W/probe_sysctl.o" ] && printf '%s\n' "$W/probe_sysctl.o"
    for o in "$CFOBJC_OBJ"/*.o; do
        [ -f "$o" ] && printf '%s\n' "$o"
    done
    for o in "$NSCF_OBJ"/*.o; do
        [ -f "$o" ] && printf '%s\n' "$o"
    done
    [ -f "$W/cfstubs.o" ] && printf '%s\n' "$W/cfstubs.o"
}

cftest_final_link_words() {
    printf '%s\n' \
        "$CC" -target "$TRIPLE" -isysroot "$SDK" -fuse-ld=lld -B "$LLD" \
        -nostdlib -dynamiclib -install_name /usr/lib/libCFTest.dylib \
        -Wl,--error-limit=0 -Wl,-undefined,dynamic_lookup \
        -L"$SDK/usr/lib" -L"$LIB"
    cftest_linked_objects
    printf '%s\n' -lSystem -lobjc
    if [ "${#extra_libs[@]}" -gt 0 ]; then
        printf '%s\n' "${extra_libs[@]}"
    fi
    printf '%s\n' -o "$LIB/libCFTest.dylib"
}

cftest_inputs_text() {
    local o key sys_tbd objc_tbd
    sys_tbd=$(cftest_tbd libSystem)
    objc_tbd=$(cftest_tbd libobjc)
    printf 'argv=%s\n' "$(cftest_final_link_words | sha256sum | awk '{print $1}')"
    while IFS= read -r o; do
        [ -n "$o" ] || continue
        key=$(cftest_obj_key "$o")
        printf '%s=%s\n' "$key" "$(cftest_file_sha "$o")"
    done < <(cftest_linked_objects)
    printf 'stub-data=%s\n' "$(cftest_file_sha "$W/stub-data.txt")"
    printf 'stub-func-active=%s\n' "$(cftest_file_sha "$W/stub-func-active.txt")"
    printf 'tbd:libSystem=%s\n' "$(cftest_file_sha "$sys_tbd")"
    printf 'tbd:libobjc=%s\n' "$(cftest_file_sha "$objc_tbd")"
}

cftest_write_inputs() {
    cftest_inputs_text > "$LIB/libCFTest.dylib.inputs"
}

cftest_inputs_id() {
    cftest_file_sha "$LIB/libCFTest.dylib.inputs"
}

# Print "key old->new" lines. Return 0 iff the on-disk stamp matches.
cftest_inputs_diff() {
    local stamp=$LIB/libCFTest.dylib.inputs
    local expected key val old changed=0
    expected=$(cftest_inputs_text)
    if [ ! -f "$stamp" ]; then
        printf 'stamp ABSENT->present\n'
        return 1
    fi
    while IFS='=' read -r key val; do
        [ -n "$key" ] || continue
        old=$(awk -F= -v k="$key" '$1==k { print substr($0, index($0,"=")+1); exit }' "$stamp")
        [ -n "$old" ] || old=ABSENT
        if [ "$old" != "$val" ]; then
            printf '%s %s->%s\n' "$key" "$old" "$val"
            changed=1
        fi
    done <<EOF
$expected
EOF
    while IFS='=' read -r key val; do
        [ -n "$key" ] || continue
        if ! printf '%s\n' "$expected" | awk -F= -v k="$key" '$1==k { found=1 } END { exit !found }'
        then
            printf '%s %s->ABSENT\n' "$key" "$val"
            changed=1
        fi
    done < "$stamp"
    [ "$changed" -eq 0 ]
}

cftest_stub_stale_line() {
    printf 'CANNOT_CFTEST_STALE file=libCFTest.dylib stub-func-active.txt=%s libCFTest.dylib=%s\n' \
        "$(cftest_mtime_iso "$W/stub-func-active.txt")" \
        "$(cftest_mtime_iso "$LIB/libCFTest.dylib")"
}

# nscf argv: build_cf_probes.sh rebuild_nscf (NSCFConstantString.m), applied
# to every src/nscf/*.m. harvest_ns_classes.sh recorded 7 objects from
# /work/nscfobj; eight .m files exist now (NSCFConstantString is the eighth).
compile_nscf() {
    local f b
    local -a nscf_argv
    if [ ! -d "$R/src/nscf" ]; then
        echo "build_cftest_harness: no $R/src/nscf" >&2
        return 2
    fi
    nscf_argv=(
        "$CC" -target "$TRIPLE" -isysroot "$SDK"
        -fobjc-runtime=macosx-13.0 -fno-objc-arc
        -I"$R/include" -I"$CF/include" -I"$CF/internalInclude"
        "${extra_inc[@]}"
        -Wno-objc-root-class -Os
    )
    echo "NSCF_ARGV: ${nscf_argv[*]}"
    for f in "$R/src/nscf"/*.m; do
        b=$(basename "$f" .m)
        "$CC" -target "$TRIPLE" -isysroot "$SDK" \
            -fobjc-runtime=macosx-13.0 -fno-objc-arc \
            -I"$R/include" -I"$CF/include" -I"$CF/internalInclude" \
            "${extra_inc[@]}" \
            -Wno-objc-root-class -Os \
            -c "$f" -o "$NSCF_OBJ/$b.o" 2>"/tmp/nscf-$b.err" || {
            echo "NSCF BUILD FAILED: $b"
            grep -m3 error: "/tmp/nscf-$b.err" || true
            return 2
        }
    done
}

need_nscf=0
nscf_objs=("$NSCF_OBJ"/*.o)
if [ "${#nscf_objs[@]}" -eq 0 ]; then
    need_nscf=1
fi
if [ "$need_nscf" -eq 1 ] || [ "${CFOBJC_REBUILD_NSCF:-0}" = 1 ]; then
    compile_nscf || exit 2
fi

cf_objs=("$CFOBJC_OBJ"/*.o)
if [ "${#cf_objs[@]}" -eq 0 ]; then
    echo "build_cftest_harness: no objects in $CFOBJC_OBJ (run scripts/build_cfobjc.sh)" >&2
    exit 2
fi

DISPATCH=
if [ -f "${LIBDISPATCH_DYLIB:-}" ]; then
    DISPATCH=$LIBDISPATCH_DYLIB
elif [ -f "$LIB/libdispatch.dylib" ]; then
    DISPATCH=$LIB/libdispatch.dylib
elif [ -f "$SDK/usr/lib/libdispatch.dylib" ]; then
    DISPATCH=$SDK/usr/lib/libdispatch.dylib
fi
SWIFTCOMPAT=
if [ -f "$LIB/libswiftcompat.dylib" ]; then
    SWIFTCOMPAT=$LIB/libswiftcompat.dylib
fi

# Pass 1: what is actually undefined, with the probe and real objects in place.
extra_libs=()
[ -n "$DISPATCH" ] && extra_libs+=("$DISPATCH")
[ -n "$SWIFTCOMPAT" ] && extra_libs+=("$SWIFTCOMPAT")

relink_reason=
dylib=$LIB/libCFTest.dylib
if [ -f "$dylib" ]; then
    if [ -f "$W/stub-func-active.txt" ] && [ "$W/stub-func-active.txt" -nt "$dylib" ]; then
        relink_reason=$(cftest_stub_stale_line)
        if [ "${CFTEST_VERIFY_ONLY:-0}" = 1 ]; then
            echo "$relink_reason"
            echo "build_cftest_harness: stub-func-active.txt is newer than lib/libCFTest.dylib; refusing to call this satisfied (verify-only)." >&2
            exit 2
        fi
        echo "$relink_reason"
        echo "libCFTest relink reason=inputs stub-func-active.txt $(cftest_mtime_iso "$dylib")->$(cftest_mtime_iso "$W/stub-func-active.txt") (stub list newer than dylib)"
    else
        diff=$(cftest_inputs_diff || true)
        if [ -z "$diff" ]; then
            stamp_id=$(cftest_inputs_id)
            echo "libCFTest reused=1 stamp=$stamp_id dest=$dylib"
            if [ -d "$W/root/darwin/usr/lib" ]; then
                cp -f "$dylib" "$W/root/darwin/usr/lib/libCFTest.dylib"
            fi
            exit 0
        fi
        first=$(printf '%s\n' "$diff" | head -1)
        key=${first%% *}
        rest=${first#"$key "}
        relink_reason="reason=inputs $key $rest"
        if [ "${CFTEST_VERIFY_ONLY:-0}" = 1 ]; then
            echo "CANNOT_CFTEST_INPUTS file=libCFTest.dylib $relink_reason"
            echo "$diff"
            echo "build_cftest_harness: input stamp mismatch; refusing to call this satisfied (verify-only)." >&2
            exit 2
        fi
        echo "libCFTest relink $relink_reason"
        echo "$diff"
    fi
elif [ "${CFTEST_VERIFY_ONLY:-0}" = 1 ]; then
    echo "CANNOT_CFTEST_INPUTS file=libCFTest.dylib reason=inputs stamp ABSENT->present"
    echo "build_cftest_harness: no lib/libCFTest.dylib (verify-only)." >&2
    exit 2
fi

"$CC" -target "$TRIPLE" -isysroot "$SDK" -Os "${extra_inc[@]}" -c "$PROBE_SRC" \
  -o "$W/probe_sysctl.o" 2>/tmp/probe.err || { echo "PROBE BUILD FAILED"; grep -m3 error: /tmp/probe.err; exit 2; }

"$CC" -target "$TRIPLE" -isysroot "$SDK" -fuse-ld=lld -B "$LLD" \
  -nostdlib -dynamiclib -Wl,--error-limit=0 \
  -L"$SDK/usr/lib" -L"$LIB" \
  "$W/probe_sysctl.o" "$CFOBJC_OBJ"/*.o "$NSCF_OBJ"/*.o \
  -lSystem -lobjc "${extra_libs[@]}" \
  -o /tmp/probe-pass1.dylib 2>/tmp/pass1.err
grep -oE "undefined symbol: [^ ]*" /tmp/pass1.err | sed "s/undefined symbol: //" \
  | grep -v "^glibc_" \
  | if [ -n "$DISPATCH" ]; then cat; else grep -vE '^_?dispatch_' || true; fi \
  | sort -u > "$W/undef-now.txt"
# _glibc_* are LOADER-resolved by design; stubbing them replaces a working
# dlsym bind with an abort. dispatch_* are the same when libdispatch.dylib
# is not on the pass-1 line (x86 may not have built it yet): they must bind
# at load, not become loud stubs.
: > "$W/stub-data.txt"; : > "$W/stub-func.txt"
awk "/^k[A-Z]/ || /^OBJC_CLASS/ {print > \"$W/stub-data.txt\"; next} {print > \"$W/stub-func.txt\"}" "$W/undef-now.txt"
[ -s "$W/stub-func.txt" ] || : > "$W/stub-func.txt"
[ -s "$W/stub-data.txt" ] || : > "$W/stub-data.txt"

llvm-nm-18 --defined-only "$W/probe_sysctl.o" 2>/dev/null \
  | awk '$2=="T"{print substr($3,2)}' | sort -u > "$W/probe-defines.txt" || true
comm -23 "$W/stub-func.txt" "$W/probe-defines.txt" > "$W/stub-func-active.txt"

# The stub set is derived every run, then pinned against
# docs/cf-census/cftest-stub-func-active.txt and cftest-stub-data.txt.
# A 143-name set from a 64-object ICU-less compile looks exactly like a
# real gap (STUB CALLED: CFStringCreateWithBytes). check_cftest_stubs.sh
# prints CANNOT_CFTEST_STUBS extra=<names> missing=<names> and we stop
# before generating abort stubs.
stub_check=$(bash "$HERE/check_cftest_stubs.sh" \
    "$W/stub-func-active.txt" "$W/stub-data.txt" \
    "$CFTEST_EXPECT_FUNC" "$CFTEST_EXPECT_DATA") || {
    echo "$stub_check"
    echo "build_cftest_harness: refusing to link libCFTest with an unexpected stub set (docs/cf-census/cftest-stubs.md)." >&2
    exit 2
}
echo "$stub_check"
{
echo "#import <objc/NSObject.h>"
echo "extern void abort(void);"
echo "extern long write(int, const void *, unsigned long);"
echo "static void say(const char *s){unsigned long n=0;while(s[n])n++;(void)!write(2,s,n);}"
cat <<'CLS'
@interface NSMutableArray : NSObject
@end
@implementation NSMutableArray
/* NOT FOUNDATION. This is a TEST FIXTURE from foundation-macho's stub
 * library, created only because CoreFoundation references NSMutableArray as a
 * CLASS OBJECT (not through a cast) and the ObjC runtime fixes up class refs at
 * load, so a void* data stub would not survive.
 *
 * It is empty. If you are here, something looked NSMutableArray up by name and
 * found this instead of a real one -- most likely libswiftCore's
 * _swift_stdlib_connectNSBaseClasses, which re-parents six classes by name via
 * class_setSuperclass and has no way to tell a fixture from the real thing.
 * See docs/cf-census/nsmutablearray-stub.md. */
+ (void)initialize {
  say("\n*** foundation-macho TEST FIXTURE: NSMutableArray is a STUB ***\n"
      "*** Not Foundation. See docs/cf-census/nsmutablearray-stub.md ***\n");
}
- (void)doesNotRecognizeSelector:(SEL)s {
  say("\n*** foundation-macho TEST FIXTURE NSMutableArray received a real\n"
      "*** message. This class is EMPTY and is not Foundation's NSMutableArray.\n"
      "*** See docs/cf-census/nsmutablearray-stub.md\n");
  abort();
}
@end
CLS
i=0
grep -v OBJC_CLASS "$W/stub-data.txt" | while read s; do i=$((i+1)); echo "void *sd_$i __asm__(\"_$s\") = 0;"; done
i=0
while read -r s; do i=$((i+1)); echo "void sf_$i(void) __asm__(\"_$s\");"; echo "void sf_$i(void){say(\"STUB CALLED: $s\n\");abort();}"; done < "$W/stub-func-active.txt"
} > "$W/cfstubs.m"
"$CC" -target "$TRIPLE" -isysroot "$SDK" -fobjc-runtime=macosx-13.0 -fno-objc-arc \
  -Wno-objc-root-class -Os "${extra_inc[@]}" -c "$W/cfstubs.m" -o "$W/cfstubs.o" 2>/tmp/st.err || { echo "STUB BUILD FAILED"; grep -m3 error: /tmp/st.err; exit 2; }

"$CC" -target "$TRIPLE" -isysroot "$SDK" -fuse-ld=lld -B "$LLD" \
  -nostdlib -dynamiclib -install_name /usr/lib/libCFTest.dylib -Wl,--error-limit=0 \
  -Wl,-undefined,dynamic_lookup -L"$SDK/usr/lib" -L"$LIB" \
  "$W/probe_sysctl.o" "$CFOBJC_OBJ"/*.o "$NSCF_OBJ"/*.o "$W/cfstubs.o" \
  -lSystem -lobjc "${extra_libs[@]}" \
  -o "$LIB/libCFTest.dylib" 2>/tmp/lk.err || { echo "LINK FAILED"; grep -m5 -E "undefined|duplicate" /tmp/lk.err; exit 2; }
cftest_write_inputs
if [ -d "$W/root/darwin/usr/lib" ]; then
    cp -f "$LIB/libCFTest.dylib" "$W/root/darwin/usr/lib/libCFTest.dylib"
fi
echo "libCFTest relinked ($(wc -l < "$W/undef-now.txt") stubbed) dest=$LIB/libCFTest.dylib${relink_reason:+ $relink_reason}"
