#!/bin/bash
# Rebuild probe + stubs, link libCFTest, run the CF_IS_OBJC test.
#
# THE STUB SET IS DERIVED EVERY RUN, NOT CACHED. It used to read
# /work/stub-{data,func}.txt written by an earlier session. The moment CF began
# defining the 99 CFLocaleKeys aliases for real, those files still listed six of
# them and the link failed with "duplicate symbol: kCFGregorianCalendar" -- a
# stub for something that now exists. A cached list of what is missing is a
# claim with no version in it, which is the same defect as a transcribed alias
# list or a stale backup. So: link once to find out what is undefined, then
# stub exactly that.
set -uo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "$0")" && pwd)/guest_arch.inc"
SDK=/work/sdk/MacOSX.sdk

clang -target "$TRIPLE" -isysroot $SDK -Os -c /repo/tests/probe_sysctl.c \
  -o /work/probe_sysctl.o 2>/tmp/probe.err || { echo "PROBE BUILD FAILED"; grep -m3 error: /tmp/probe.err; exit 2; }

# Pass 1: what is actually undefined, with the probe and real objects in place.
clang -target "$TRIPLE" -isysroot $SDK -fuse-ld=lld -B /usr/lib/llvm-18/bin \
  -nostdlib -dynamiclib -Wl,--error-limit=0 \
  -L$SDK/usr/lib -L/work/lib \
  /work/probe_sysctl.o /work/cfobjc/obj/*.o /work/nscfobj/*.o \
  -lSystem -lobjc /work/lib/libdispatch.dylib /work/lib/libswiftcompat.dylib \
  -o /tmp/probe-pass1.dylib 2>/tmp/pass1.err
grep -oE "undefined symbol: [^ ]*" /tmp/pass1.err | sed "s/undefined symbol: //" | grep -v "^glibc_" | sort -u > /work/undef-now.txt   # _glibc_* are LOADER-resolved by design; stubbing them replaces a working dlsym bind with an abort
: > /work/stub-data.txt; : > /work/stub-func.txt   # awk only truncates when it WRITES; with no matching lines the old file survives and stubs something that now exists
awk "/^k[A-Z]/ || /^OBJC_CLASS/ {print > \"/work/stub-data.txt\"; next} {print > \"/work/stub-func.txt\"}" /work/undef-now.txt
[ -s /work/stub-func.txt ] || : > /work/stub-func.txt
[ -s /work/stub-data.txt ] || : > /work/stub-data.txt

llvm-nm-18 --defined-only /work/probe_sysctl.o | awk '$2=="T"{print substr($3,2)}' | sort -u > /work/probe-defines.txt
comm -23 /work/stub-func.txt /work/probe-defines.txt > /work/stub-func-active.txt
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
grep -v OBJC_CLASS /work/stub-data.txt | while read s; do i=$((i+1)); echo "void *sd_$i __asm__(\"_$s\") = 0;"; done
i=0
while read -r s; do i=$((i+1)); echo "void sf_$i(void) __asm__(\"_$s\");"; echo "void sf_$i(void){say(\"STUB CALLED: $s\n\");abort();}"; done < /work/stub-func-active.txt
} > /work/cfstubs.m
clang -target "$TRIPLE" -isysroot $SDK -fobjc-runtime=macosx-13.0 -fno-objc-arc \
  -Wno-objc-root-class -Os -c /work/cfstubs.m -o /work/cfstubs.o 2>/tmp/st.err || { echo "STUB BUILD FAILED"; grep -m3 error: /tmp/st.err; exit 2; }

clang -target "$TRIPLE" -isysroot $SDK -fuse-ld=lld -B /usr/lib/llvm-18/bin \
  -nostdlib -dynamiclib -install_name /usr/lib/libCFTest.dylib -Wl,--error-limit=0 \
  -Wl,-undefined,dynamic_lookup -L$SDK/usr/lib -L/work/lib \
  /work/probe_sysctl.o /work/cfobjc/obj/*.o /work/nscfobj/*.o /work/cfstubs.o \
  -lSystem -lobjc /work/lib/libdispatch.dylib /work/lib/libswiftcompat.dylib \
  -o /work/lib/libCFTest.dylib 2>/tmp/lk.err || { echo "LINK FAILED"; grep -m5 -E "undefined|duplicate" /tmp/lk.err; exit 2; }
cp -f /work/lib/libCFTest.dylib /work/root/darwin/usr/lib/libCFTest.dylib
echo "libCFTest relinked ($(wc -l < /work/undef-now.txt) stubbed)"
