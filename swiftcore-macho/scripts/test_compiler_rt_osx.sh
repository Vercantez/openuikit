#!/bin/bash
# Tooth: Darwin compiler-rt builtins archive resolves __divti3 / __udivti3 /
# __floattidf / __isPlatformVersionAtLeast under ld64.lld NOUNDEFS.
# Overlay .o grep is printed when $W/build exists; otherwise the operator
# ninja overlay log is the proof.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
NM=${NM:-/usr/lib/llvm-18/bin/llvm-nm}
LD64=${LD64_LLD:-/usr/lib/llvm-18/bin/ld64.lld}
OTOOL=${OTOOL:-llvm-otool-18}
command -v "$OTOOL" >/dev/null 2>&1 || OTOOL=llvm-otool
clang_c=$(command -v clang-18 || command -v clang)

echo "=== bash -n build_compiler_rt_osx.sh ==="
bash -n "$SCRIPT_DIR/build_compiler_rt_osx.sh" \
  && echo "  OK  bash -n" || { echo "  FAIL bash -n"; fail=1; }

echo
echo "=== build libclang_rt.osx.a (generic C builtins + os_version_check override) ==="
sdk=""
for d in \
  "${SWIFTCORE_SDKROOT:-}" \
  "${SWIFTCORE_DARWIN_SDK:-}" \
  "${SWIFTCORE_WORK:-$HOME/work}/sdk/MacOSX.sdk" \
  /home/ubuntu/work/sdk/MacOSX.sdk \
  /root/work/sdk/MacOSX.sdk
do
  [ -n "$d" ] && [ -d "$d/usr/include" ] && { sdk=$d; break; }
done
if [ -z "$sdk" ]; then
  sdk=$tmp/sdk
  mkdir -p "$sdk/usr/include" "$sdk/usr/lib"
  root=$(cd "$SCRIPT_DIR/../.." && pwd)
  if [ -d "$root/machorun/sdk/usr/include" ]; then
    cp -a "$root/machorun/sdk/usr/include/." "$sdk/usr/include/"
  fi
  if [ -d "$root/machorun/sdk/local" ]; then
    cp -a "$root/machorun/sdk/local/." "$sdk/usr/include/" 2>/dev/null || true
  fi
  [ -f "$sdk/usr/include/TargetConditionals.h" ] \
    && echo "  OK  mini sysroot from machorun/sdk headers" \
    || { echo "  FAIL no TargetConditionals.h for compiler-rt"; fail=1; }
fi
rt_a=$tmp/libclang_rt.osx.a
set +e
out=$(SWIFTCORE_SDKROOT="$sdk" SWIFTCORE_DARWIN_ARCH=x86_64 \
  SWIFTCORE_LLVM_SRC="${SWIFTCORE_LLVM_SRC:-}" \
  SWIFTCORE_WORK="${SWIFTCORE_WORK:-$HOME/work}" \
  bash "$SCRIPT_DIR/build_compiler_rt_osx.sh" "$rt_a" 2>&1)
st=$?
set -e
printf '%s\n' "$out" | tail -20
[ "$st" -eq 0 ] && echo "  OK  build rc=0" || { echo "  FAIL build rc=$st"; fail=1; }
printf '%s\n' "$out" | grep -qE 'compiler-rt darwin builtins: members=[0-9]+ arch=x86_64 sha256=' \
  && echo "  OK  one-line members/arch/sha256 summary" \
  || { echo "  FAIL missing summary line"; fail=1; }
members=$(printf '%s\n' "$out" | sed -n 's/.*members=\([0-9][0-9]*\).*/\1/p' | tail -1)
[ "${members:-0}" -ge 50 ] && echo "  OK  member count $members (>=50, not a single TU)" \
  || { echo "  FAIL member count $members is still single-file vendoring"; fail=1; }
printf '%s\n' "$out" | grep -q 'os_version_check.c (in-tree override' \
  && echo "  OK  excluded upstream os_version_check.c (in-tree override)" \
  || { echo "  FAIL did not skip upstream os_version_check.c"; fail=1; }
if [ ! -f "$rt_a" ]; then
  echo "  FAIL archive missing"; fail=1
else
  for s in ___divti3 ___udivti3 ___floattidf ___isPlatformVersionAtLeast; do
    nmlst=$("$NM" "$rt_a" 2>/dev/null || true)
    printf '%s\n' "$nmlst" | grep -F -- "$s" >/dev/null \
      && echo "  OK  archive contains $s" \
      || { echo "  FAIL archive missing $s"; fail=1; }
  done
fi

echo
echo "=== ld64.lld NOUNDEFS probe: __divti3 __udivti3 __floattidf __isPlatformVersionAtLeast ==="
if [ ! -f "$rt_a" ]; then
  echo "  FAIL skip probe (no archive)"; fail=1
else
  cat > "$tmp/probe.c" <<'EOF'
__int128 call_div(__int128 a, __int128 b) { return a / b; }
unsigned __int128 call_udiv(unsigned __int128 a, unsigned __int128 b) { return a / b; }
double call_float(__int128 a) { return (double)a; }
int __isPlatformVersionAtLeast(unsigned, unsigned, unsigned, unsigned);
int call_plat(void) { return __isPlatformVersionAtLeast(1, 14, 0, 0); }
EOF
  # libc symbols pulled by os_version_check.c; stubs keep this probe NOUNDEFS
  # without -undefined dynamic_lookup and without exporting builtins from libSystem.
  cat > "$tmp/stubs.c" <<'EOF'
void *fopen(const char *a, const char *b) { (void)a; (void)b; return 0; }
int fclose(void *f) { (void)f; return 0; }
int fseek(void *f, long o, int w) { (void)f; (void)o; (void)w; return 0; }
long ftell(void *f) { (void)f; return 0; }
void rewind(void *f) { (void)f; }
unsigned long fread(void *p, unsigned long s, unsigned long n, void *f) {
  (void)p; (void)s; (void)n; (void)f; return 0;
}
int sscanf(const char *s, const char *fmt, ...) { (void)s; (void)fmt; return 0; }
char *getenv(const char *n) { (void)n; return 0; }
void *malloc(unsigned long n) { (void)n; return 0; }
void free(void *p) { (void)p; }
void *dlsym(void *h, const char *n) { (void)h; (void)n; return 0; }
unsigned long strlen(const char *s) { (void)s; return 0; }
char *strcpy(char *d, const char *s) { (void)s; return d; }
char *strcat(char *d, const char *s) { (void)s; return d; }
void __assert_rtn(const char *a, const char *b, int c, const char *d) {
  (void)a; (void)b; (void)c; (void)d;
}
EOF
  "$clang_c" -target x86_64-apple-macosx13.0 -fno-builtin -c -o "$tmp/probe.o" "$tmp/probe.c"
  "$clang_c" -target x86_64-apple-macosx13.0 -fno-builtin -c -o "$tmp/stubs.o" "$tmp/stubs.c"
  "$NM" -u "$tmp/probe.o" | grep -q '__divti3' \
    && echo "  OK  probe object refs __divti3" \
    || { echo "  FAIL probe missing __divti3 ref"; fail=1; }
  set +e
  "$LD64" -arch x86_64 -dylib -platform_version macos 13.0.0 13.0.0 \
    -o "$tmp/libprobe.dylib" "$tmp/probe.o" "$rt_a" "$tmp/stubs.o" 2>"$tmp/probe.link.err"
  lst=$?
  set -e
  [ "$lst" -eq 0 ] && echo "  OK  ld64.lld probe link rc=0 (NOUNDEFS)" \
    || { echo "  FAIL ld64.lld probe rc=$lst"; cat "$tmp/probe.link.err"; fail=1; }
  grep -q 'undefined dynamic_lookup' "$tmp/probe.link.err" \
    && { echo "  FAIL probe used -undefined dynamic_lookup"; fail=1; } \
    || echo "  OK  no -undefined dynamic_lookup"
  if [ -f "$tmp/libprobe.dylib" ]; then
    undef=$("$NM" -u "$tmp/libprobe.dylib" 2>/dev/null || true)
    miss=0
    for s in __divti3 __udivti3 __floattidf __isPlatformVersionAtLeast; do
      printf '%s\n' "$undef" | grep -q "$s" \
        && { echo "  FAIL llvm-nm -u still has $s"; miss=1; fail=1; } \
        || echo "  OK  llvm-nm -u has no $s"
    done
    [ "$miss" -eq 0 ] && echo "  OK  none of the four are undefined"
  fi
fi

echo
echo "=== overlay .o grep (U __divti3 / __float / __fix) ==="
build=${SWIFTCORE_WORK:-$HOME/work}/build
if [ -d "$build" ]; then
  hits=$(find "$build" -name '*.o' -print0 2>/dev/null \
    | xargs -0 "$NM" -u 2>/dev/null \
    | grep -E 'U __[a-z]*ti3|U __float|U __fix' | sort -u | head -40 || true)
  if [ -n "$hits" ]; then
    echo "$hits"
    echo "  note: overlay objects still reference compiler-rt helpers; the archive must supply them"
  else
    echo "  OK  no U __ti3/__float/__fix in $build overlay objects (or none found)"
  fi
else
  echo "  note: no $build; operator ninja overlay log is the proof (expected: all twelve OVERLAY … built)"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- compiler-rt darwin builtins archive resolves __divti3/__udivti3/__floattidf/__isPlatformVersionAtLeast"
  exit 0
fi
echo "FAIL"
exit 1
