#!/bin/bash
# Classify by -target: apple → Darwin / ld64.lld (do not re-compose the
# driver link); unknown-linux-gnu → ELF / ld.lld. The .so suffix is CMake's
# Linux CMAKE_SHARED_LIBRARY_SUFFIX, not the object format.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
py=$SCRIPT_DIR/clangxx_darwin_link.py
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

export LLD_BIN=${LLD_BIN:-/usr/lib/llvm-18/bin}
export LD_LLD=${LD_LLD:-$LLD_BIN/ld.lld}
export LD64_LLD=${LD64_LLD:-$LLD_BIN/ld64.lld}

rewrite() {
  SWIFTCORE_CLANGXX_PRINT_REWRITTEN=1 python3 "$py" "$@" 2>"$tmp/link.err"
}

assert_decision() {
  local out=$1 kind=$2 linker=$3
  local line="clangxx_darwin_link: -o ${out} decision=${kind} linker=${linker}"
  if grep -Fqx "$line" "$tmp/link.err"; then
    echo "  OK  $line"
  else
    echo "  FAIL expected: $line"
    echo "  got:"
    grep '^clangxx_darwin_link:' "$tmp/link.err" || cat "$tmp/link.err"
    fail=1
  fi
}

echo "=== apple-target .so (operator core) routes to ld64 via the Darwin driver ==="
# Exact CXX_SHARED_LIBRARY flag head (Linux CMake .so suffix, Darwin -target).
got=$(rewrite \
  -fPIC -fPIC -fno-semantic-interposition -fvisibility-inlines-hidden \
  -Werror=date-time -Werror=unguarded-availability-new -Wall -Wextra \
  -Wno-unused-parameter -Wwrite-strings -Wcast-qual -Wmissing-field-initializers \
  -Wimplicit-fallthrough -Wcovered-switch-default -Wno-noexcept-type \
  -Wnon-virtual-dtor -Wdelete-non-virtual-dtor -Wsuggest-override \
  -Wstring-conversion -Wmisleading-indentation -Wctad-maybe-unsupported \
  -fdiagnostics-color -ffunction-sections -fdata-sections -O3 -DNDEBUG \
  -B/usr/lib/llvm-18/bin \
  -target x86_64-apple-macosx13.0 \
  -isysroot /root/work/sdk/MacOSX.sdk \
  -F/root/work/sdk/MacOSX.sdk/../../../Developer/Library/Frameworks \
  -fuse-ld=lld \
  -Wl,-sectcreate,__TEXT,__info_plist,/root/work/build/stdlib/public/core/Info.plist \
  -Wl,-application_extension -Xlinker -compatibility_version -Xlinker 1 \
  -shared -Wl,-soname,libswiftCore.so \
  -o lib/swift/macosx/x86_64/libswiftCore.so \
  foo.o)
printf '%s\n' "$got"
printf '%s\n' "$got" | grep -F -- '-shared' >/dev/null \
  && echo "  OK  kept -shared for the Darwin driver" \
  || { echo "  FAIL dropped -shared (driver needs it for -dynamic/-dylib/-arch)"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-dynamiclib' >/dev/null \
  && { echo "  FAIL shim injected -dynamiclib (drops driver -platform_version/-arch)"; fail=1; } \
  || echo "  OK  did not replace the driver with -dynamiclib"
printf '%s\n' "$got" | grep -E '(^|[[:space:]])-nostdlib([[:space:]]|$)' >/dev/null \
  && { echo "  FAIL shim injected -nostdlib (C runtime)"; fail=1; } \
  || echo "  OK  did not inject -nostdlib"
printf '%s\n' "$got" | grep -F -- '-nostdlib++' >/dev/null \
  && echo "  OK  -nostdlib++ (driver must not auto-link host libc++)" \
  || { echo "  FAIL missing -nostdlib++"; fail=1; }
printf '%s\n' "$got" | grep -F -- '/root/work/sdk/MacOSX.sdk/usr/lib/libc++.tbd' >/dev/null \
  && echo "  OK  sysroot libc++.tbd on the Darwin link" \
  || { echo "  FAIL missing sysroot libc++.tbd"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-Wl,-force_load,' >/dev/null \
  && printf '%s\n' "$got" | grep -F -- 'libclang_rt.osx.a' >/dev/null \
  && echo "  OK  force-load Darwin compiler-rt builtins archive" \
  || { echo "  FAIL missing -Wl,-force_load,libclang_rt.osx.a"; fail=1; }
grep -q 'clangxx_darwin_link: cxx_runtime=/root/work/sdk/MacOSX.sdk/usr/lib/libc++.tbd' "$tmp/link.err" \
  && echo "  OK  printed cxx_runtime= sysroot tbd" \
  || { echo "  FAIL missing cxx_runtime line"; fail=1; }
grep -q 'clangxx_darwin_link: compiler_rt=' "$tmp/link.err" \
  && grep -q 'libclang_rt.osx.a' "$tmp/link.err" \
  && echo "  OK  printed compiler_rt= builtins archive" \
  || { echo "  FAIL missing compiler_rt line"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-fuse-ld=lld' >/dev/null \
  && echo "  OK  kept -fuse-ld=lld (Darwin maps lld → ld64.lld + -platform_version)" \
  || { echo "  FAIL dropped -fuse-ld=lld"; fail=1; }
printf '%s\n' "$got" | grep -F -- "--ld-path=${LD64_LLD}" >/dev/null \
  && echo "  OK  --ld-path=ld64.lld" || { echo "  FAIL missing --ld-path=ld64.lld"; fail=1; }
printf '%s\n' "$got" | grep -F -- "--ld-path=${LD_LLD}" >/dev/null \
  && { echo "  FAIL apple-target .so selected ld.lld"; fail=1; } \
  || echo "  OK  did not select ld.lld"
printf '%s\n' "$got" | grep -F -- '-platform_version' >/dev/null \
  && { echo "  FAIL shim injected -platform_version (driver must compose it)"; fail=1; } \
  || echo "  OK  did not inject -platform_version into clang argv"
printf '%s\n' "$got" | grep -E '(^|[[:space:]])-arch[[:space:]]' >/dev/null \
  && { echo "  FAIL shim injected -arch (driver must compose it)"; fail=1; } \
  || echo "  OK  did not inject -arch into clang argv"
grep -q 'rewritten argv:' "$tmp/link.err" \
  && { echo "  FAIL Darwin logged rewritten argv (re-issued the link)"; fail=1; } \
  || echo "  OK  no rewritten argv log for Darwin"
grep -q 'clangxx_darwin_link: driver argv:' "$tmp/link.err" \
  && echo "  OK  logged driver argv" \
  || { echo "  FAIL missing driver argv log"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-isysroot /root/work/sdk/MacOSX.sdk' >/dev/null \
  && echo "  OK  kept -isysroot for the Darwin driver" \
  || { echo "  FAIL dropped -isysroot"; fail=1; }
printf '%s\n' "$got" | grep -Eq -- '(^|[[:space:]])(-Wl,)?-?-soname' \
  && { echo "  FAIL leftover -soname (ld64.lld rejects it)"; fail=1; } \
  || echo "  OK  translated -soname (ld64 never sees it)"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftCore.dylib' >/dev/null \
  && echo "  OK  soname → install_name" || { echo "  FAIL missing install_name"; fail=1; }
assert_decision lib/swift/macosx/x86_64/libswiftCore.so darwin ld64.lld

echo
echo "=== unknown-linux-gnu .so routes to ld.lld ==="
got=$(rewrite -target x86_64-unknown-linux-gnu -shared \
  -Wl,-soname,libswiftCore.so -o libswiftCore.so foo.o)
printf '%s\n' "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-soname,libswiftCore.so' >/dev/null \
  && echo "  OK  ELF -soname kept" || { echo "  FAIL ELF -soname rewritten"; fail=1; }
printf '%s\n' "$got" | grep -F -- "--ld-path=${LD_LLD}" >/dev/null \
  && echo "  OK  --ld-path=ld.lld" || { echo "  FAIL missing --ld-path=ld.lld"; fail=1; }
printf '%s\n' "$got" | grep -F -- 'ld64.lld' >/dev/null \
  && { echo "  FAIL linux-target .so selected ld64.lld"; fail=1; } \
  || echo "  OK  did not select ld64.lld"
printf '%s\n' "$got" | grep -F -- 'libclang_rt.osx.a' >/dev/null \
  && { echo "  FAIL ELF link force-loaded Darwin compiler-rt"; fail=1; } \
  || echo "  OK  ELF link has no Darwin compiler-rt archive"
assert_decision libswiftCore.so elf ld.lld

echo
echo "=== compile (-c) is not rewritten ==="
got=$(rewrite -target x86_64-apple-macosx13.0 -c -o foo.o foo.cpp)
printf '%s\n' "$got" | grep -F -- '-dynamiclib' >/dev/null \
  && { echo "  FAIL compile grew -dynamiclib"; fail=1; } \
  || echo "  OK  compile argv unchanged in kind"
printf '%s\n' "$got" | grep -F -- '-c' >/dev/null \
  && echo "  OK  still -c" || { echo "  FAIL lost -c"; fail=1; }

echo
echo "=== Darwin gold -fuse-ld becomes -fuse-ld=lld plus --ld-path; -shared kept ==="
got=$(rewrite -target x86_64-apple-macosx13.0 -isysroot /sdk \
  -fuse-ld=gold -B/usr/bin -shared -Wl,-soname,libswiftDarwin.dylib \
  -o libswiftDarwin.dylib foo.o)
printf '%s\n' "$got"
printf '%s\n' "$got" | grep -F -- '-shared' >/dev/null \
  && echo "  OK  kept -shared" || { echo "  FAIL dropped -shared"; fail=1; }
printf '%s\n' "$got" | grep -F -- "-fuse-ld=gold" >/dev/null \
  && { echo "  FAIL gold survived"; fail=1; } \
  || echo "  OK  gold dropped"
printf '%s\n' "$got" | grep -F -- '-fuse-ld=lld' >/dev/null \
  && echo "  OK  -fuse-ld=lld (required for -platform_version)" \
  || { echo "  FAIL missing -fuse-ld=lld after dropping gold"; fail=1; }
printf '%s\n' "$got" | grep -F -- "--ld-path=${LD64_LLD}" >/dev/null \
  && echo "  OK  --ld-path=ld64.lld" || { echo "  FAIL missing ld64 --ld-path"; fail=1; }
printf '%s\n' "$got" | grep -E -- '-fuse-ld=/' >/dev/null \
  && { echo "  FAIL deprecated -fuse-ld=<path>"; fail=1; } \
  || echo "  OK  no -fuse-ld=<path>"
assert_decision libswiftDarwin.dylib darwin ld64.lld
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  soname -> install_name" || { echo "  FAIL missing install_name"; fail=1; }

echo
echo "=== overlay Darwin .so input kept (apple-target .so is Darwin) ==="
got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  -o libswiftDarwin.so Darwin.o \
  /home/ubuntu/work/build/lib/swift/macosx/x86_64/libswiftCore.so)
printf '%s\n' "$got" | grep -F -- 'libswiftCore.so' >/dev/null \
  && echo "  OK  Darwin .so input kept" || { echo "  FAIL dropped overlay dep .so"; fail=1; }
assert_decision libswiftDarwin.so darwin ld64.lld

echo
echo "=== Darwin .so output is mirrored to .dylib (helper) ==="
mkdir -p "$tmp/lib/swift/macosx/x86_64"
echo so > "$tmp/lib/swift/macosx/x86_64/libswiftDarwin.so"
python3 -c "
import sys
sys.path.insert(0, '$SCRIPT_DIR')
import clangxx_darwin_link as m
m.mirror_so_to_dylib(['-o', '$tmp/lib/swift/macosx/x86_64/libswiftDarwin.so'])
"
if [ -f "$tmp/lib/swift/macosx/x86_64/libswiftDarwin.dylib" ]; then
  cmp -s "$tmp/lib/swift/macosx/x86_64/libswiftDarwin.so" \
         "$tmp/lib/swift/macosx/x86_64/libswiftDarwin.dylib" \
    && echo "  OK  .dylib mirrors .so" || { echo "  FAIL dylib mismatch"; fail=1; }
else
  echo "  FAIL no .dylib written"; fail=1
fi

echo
echo "=== overlay Darwin -soname spellings rewrite to -install_name ==="
assert_no_soname() {
  local got=$1
  if printf '%s\n' "$got" | grep -Eq -- '(^|[[:space:]])(-Wl,)?-?-soname'; then
    echo "  FAIL leftover -soname in: $got"
    fail=1
    return 1
  fi
  echo "  OK  no -soname"
}

got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  -Wl,-soname,libswiftDarwin.dylib -o libswiftDarwin.dylib Darwin.o)
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  -Wl,-soname, -> install_name" || { echo "  FAIL concatenated soname"; fail=1; }
assert_decision libswiftDarwin.dylib darwin ld64.lld

got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  -soname,libswiftDarwin.dylib -o libswiftDarwin.dylib Darwin.o)
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  -soname, -> install_name" || { echo "  FAIL bare soname"; fail=1; }

got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  -Xlinker -soname -Xlinker libswiftDarwin.dylib -o libswiftDarwin.dylib Darwin.o)
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  -Xlinker -soname -> install_name" || { echo "  FAIL -Xlinker soname"; fail=1; }

echo
echo "=== Darwin driver -###: ld64.lld receives -platform_version and -arch ==="
clang_real=$(command -v clang++-18 || command -v clang++)
sdk=""
for d in /home/ubuntu/work/sdk/MacOSX.sdk /root/work/sdk/MacOSX.sdk; do
  if [ -f "$d/usr/lib/libc++.tbd" ]; then sdk=$d; break; fi
done
if [ ! -x "$clang_real" ]; then
  echo "  FAIL no clang++ to run -###"; fail=1
elif [ -z "$sdk" ]; then
  echo "  FAIL no sysroot libc++.tbd for -###"; fail=1
else
  set +e
  SWIFTCORE_REAL_CLANGXX="$clang_real" python3 "$py" \
    -fPIC -B/usr/lib/llvm-18/bin -L/usr/lib/llvm-18/lib \
    -target x86_64-apple-macosx13.0 \
    -isysroot "$sdk" \
    -fuse-ld=lld \
    -shared -Wl,-soname,libswiftCore.so \
    -o lib/swift/macosx/x86_64/libswiftCore.so \
    foo.o \
    -### >"$tmp/hash.out" 2>"$tmp/hash.err"
  set -e
  grep '^clangxx_darwin_link:' "$tmp/hash.err" || true
  grep -q 'rewritten argv:' "$tmp/hash.err" \
    && { echo "  FAIL -### path logged rewritten argv"; fail=1; } \
    || echo "  OK  -### path has no rewritten argv"
  job=$(grep -E 'ld64\.lld' "$tmp/hash.err" | tail -1 || true)
  printf '%s\n' "$job"
  printf '%s\n' "$job" | grep -q 'ld64.lld' \
    && echo "  OK  -### invoked ld64.lld" || { echo "  FAIL no ld64.lld in -###"; fail=1; }
  printf '%s\n' "$job" | grep -q -- '-platform_version' \
    && echo "  OK  ld64.lld received -platform_version from the Darwin driver" \
    || { echo "  FAIL ld64.lld job missing -platform_version"; fail=1; }
  printf '%s\n' "$job" | grep -q -- '"-arch"' \
    && echo "  OK  ld64.lld received -arch from the Darwin driver" \
    || { echo "  FAIL ld64.lld job missing -arch"; fail=1; }
  printf '%s\n' "$job" | grep -q -- 'x86_64' \
    && echo "  OK  ld64.lld -arch x86_64" || { echo "  FAIL missing x86_64 on ld64 job"; fail=1; }
  printf '%s\n' "$job" | grep -q '/usr/lib/llvm-18/lib' \
    && { echo "  FAIL ld64.lld job still has host /usr/lib/llvm-18/lib"; fail=1; } \
    || echo "  OK  ld64.lld job has no host llvm-18/lib"
  printf '%s\n' "$job" | grep -q 'libc++.so' \
    && { echo "  FAIL ld64.lld job still names host libc++.so"; fail=1; } \
    || echo "  OK  ld64.lld job does not name ELF libc++.so"
  printf '%s\n' "$job" | grep -q 'libc++.tbd' \
    && echo "  OK  ld64.lld job has sysroot libc++.tbd" \
    || { echo "  FAIL ld64.lld job missing libc++.tbd"; fail=1; }
  # Contrast: --ld-path= alone (no -fuse-ld=lld) omits -platform_version.
  "$clang_real" -### -target x86_64-apple-macosx13.0 -shared \
    --ld-path="$LD64_LLD" -o /tmp/x.so /dev/null >"$tmp/bare.out" 2>"$tmp/bare.err"
  bare=$(grep -E 'ld64\.lld' "$tmp/bare.err" | tail -1 || true)
  printf '%s\n' "$bare" | grep -q -- '-platform_version' \
    && { echo "  FAIL expected --ld-path= alone to omit -platform_version"; fail=1; } \
    || echo "  OK  control: --ld-path= alone does not emit -platform_version"
fi

echo
echo "=== Darwin link drops -L/usr/lib/llvm-18/lib (CMake LINK_PATH) ==="
got=$(rewrite -target x86_64-apple-macosx13.0 \
  -isysroot /root/work/sdk/MacOSX.sdk \
  -B/usr/lib/llvm-18/bin -L/usr/lib/llvm-18/lib \
  -shared -Wl,-soname,libswiftDarwin.so \
  -o lib/swift/macosx/x86_64/libswiftDarwin.so Darwin.o)
printf '%s\n' "$got"
printf '%s\n' "$got" | grep -q '/usr/lib/llvm-18/lib' \
  && { echo "  FAIL Darwin argv still has /usr/lib/llvm-18/lib"; fail=1; } \
  || echo "  OK  no /usr/lib/llvm-18/lib on Darwin argv"
printf '%s\n' "$got" | grep -F -- '-B/usr/lib/llvm-18/bin' >/dev/null \
  && echo "  OK  kept -B llvm-18/bin (linker tools)" \
  || { echo "  FAIL dropped -B/usr/lib/llvm-18/bin"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-nostdlib++' >/dev/null \
  && echo "  OK  -nostdlib++" || { echo "  FAIL missing -nostdlib++"; fail=1; }
printf '%s\n' "$got" | grep -F -- '/root/work/sdk/MacOSX.sdk/usr/lib/libc++.tbd' >/dev/null \
  && echo "  OK  explicit sysroot libc++.tbd" || { echo "  FAIL missing libc++.tbd"; fail=1; }
printf '%s\n' "$got" | grep -F -- '/root/work/sdk/MacOSX.sdk/usr/lib/libc++abi.tbd' >/dev/null \
  && echo "  OK  explicit sysroot libc++abi.tbd" || { echo "  FAIL missing libc++abi.tbd"; fail=1; }
grep -q 'cxx_runtime=/root/work/sdk/MacOSX.sdk/usr/lib/libc++.tbd' "$tmp/link.err" \
  && echo "  OK  cxx_runtime printed" || { echo "  FAIL missing cxx_runtime"; fail=1; }

echo
echo "=== Darwin std::string::append resolves from sysroot libc++.tbd, not host .so ==="
sdk=""
for d in /home/ubuntu/work/sdk/MacOSX.sdk /root/work/sdk/MacOSX.sdk; do
  if [ -f "$d/usr/lib/libc++.tbd" ]; then sdk=$d; break; fi
done
if [ -z "$sdk" ]; then
  echo "  FAIL no sysroot libc++.tbd to resolve std::string"; fail=1
else
  /usr/lib/llvm-18/bin/llvm-nm "$sdk/usr/lib/libc++.tbd" 2>/dev/null \
    | grep -q '__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc' \
    && echo "  OK  sysroot libc++.tbd exports basic_string::append" \
    || { echo "  FAIL tbd missing append"; fail=1; }
  cat > "$tmp/s.cpp" <<'EOF'
#include <string>
std::string f() { std::string s; s.append("x"); return s; }
EOF
  clang_real=$(command -v clang++-18 || command -v clang++)
  set +e
  "$clang_real" -c -target x86_64-apple-macosx13.0 -isysroot "$sdk" \
    -o "$tmp/s.o" "$tmp/s.cpp" 2>"$tmp/s.err"
  c_st=$?
  set -e
  if [ "$c_st" -ne 0 ]; then
    echo "  FAIL compile std::string rc=$c_st"; cat "$tmp/s.err"; fail=1
  else
    set +e
    SWIFTCORE_REAL_CLANGXX="$clang_real" python3 "$py" \
      -target x86_64-apple-macosx13.0 -isysroot "$sdk" \
      -B/usr/lib/llvm-18/bin -L/usr/lib/llvm-18/lib \
      -fuse-ld=lld -shared \
      -o "$tmp/libappend.so" "$tmp/s.o" 2>"$tmp/link.err"
    l_st=$?
    set -e
    printf '%s\n' "$(grep '^clangxx_darwin_link:' "$tmp/link.err" || true)"
    [ "$l_st" -eq 0 ] && echo "  OK  Darwin link with host -L succeeded (rc=0)" \
      || { echo "  FAIL Darwin std::string link rc=$l_st"; cat "$tmp/link.err"; fail=1; }
    grep -q 'unhandled file type' "$tmp/link.err" \
      && { echo "  FAIL still passed ELF libc++.so to ld64"; fail=1; } \
      || echo "  OK  no ELF libc++.so unhandled file type"
    grep -q "cxx_runtime=$sdk/usr/lib/libc++.tbd" "$tmp/link.err" \
      && echo "  OK  link printed cxx_runtime=$sdk/usr/lib/libc++.tbd" \
      || { echo "  FAIL cxx_runtime not sysroot tbd"; fail=1; }
    if [ -f "$tmp/libappend.so" ]; then
      /usr/lib/llvm-18/bin/llvm-nm -m "$tmp/libappend.so" 2>/dev/null \
        | grep 'appendEPKc' | grep -q 'libc++' \
        && echo "  OK  append bind names libc++ (sysroot tbd)" \
        || echo "  OK  linked (nm bind line optional on tbd-only dylib)"
    fi
  fi
fi

echo
echo "=== Darwin availability check resolves from compiler-rt builtins archive ==="
sdk=""
for d in /home/ubuntu/work/sdk/MacOSX.sdk /root/work/sdk/MacOSX.sdk; do
  if [ -f "$d/usr/lib/libc++.tbd" ]; then sdk=$d; break; fi
done
rt_a=""
work=${SWIFTCORE_WORK:-$HOME/work}
if [ -n "$sdk" ]; then
  rt_a=$work/build/libclang_rt.osx.a
  SWIFTCORE_SDKROOT="$sdk" SWIFTCORE_WORK="$work" \
    SWIFTCORE_COMPILER_RT_OSX="$rt_a" \
    bash "$SCRIPT_DIR/build_compiler_rt_osx.sh" "$rt_a"
fi
if [ -z "$sdk" ]; then
  echo "  FAIL no sysroot for availability Darwin link"; fail=1
elif [ ! -f "$rt_a" ]; then
  echo "  FAIL compiler-rt archive missing at $rt_a"; fail=1
else
  /usr/lib/llvm-18/bin/llvm-nm "$rt_a" 2>/dev/null \
    | grep -q 'isPlatformVersionAtLeast' \
    && echo "  OK  archive defines isPlatformVersionAtLeast" \
    || { echo "  FAIL archive missing isPlatformVersionAtLeast"; fail=1; }
  /usr/lib/llvm-18/bin/llvm-nm "$rt_a" 2>/dev/null \
    | grep -q 'isPlatformOrVariantPlatformVersionAtLeast' \
    && echo "  OK  archive defines isPlatformOrVariantPlatformVersionAtLeast" \
    || { echo "  FAIL archive missing variant hook"; fail=1; }
  cat > "$tmp/avail.c" <<'EOF'
int probe(void) {
  if (__builtin_available(macOS 11.0, *))
    return 1;
  return 0;
}
EOF
  clang_c=$(command -v clang-18 || command -v clang)
  clang_real=$(command -v clang++-18 || command -v clang++)
  set +e
  "$clang_c" -c -target x86_64-apple-macosx13.0 -isysroot "$sdk" \
    -o "$tmp/avail.o" "$tmp/avail.c" 2>"$tmp/avail.err"
  c_st=$?
  set -e
  if [ "$c_st" -ne 0 ]; then
    echo "  FAIL compile __builtin_available rc=$c_st"; cat "$tmp/avail.err"; fail=1
  else
    /usr/lib/llvm-18/bin/llvm-nm "$tmp/avail.o" 2>/dev/null \
      | grep -E 'isPlatformVersionAtLeast' \
      && echo "  OK  availability object refs isPlatformVersionAtLeast" \
      || echo "  OK  compile (nm ref optional)"
    set +e
    SWIFTCORE_REAL_CLANGXX="$clang_real" \
      SWIFTCORE_WORK="$work" \
      SWIFTCORE_COMPILER_RT_OSX="$rt_a" \
      python3 "$py" \
      -target x86_64-apple-macosx13.0 -isysroot "$sdk" \
      -B/usr/lib/llvm-18/bin -L/usr/lib/llvm-18/lib \
      -fuse-ld=lld -shared \
      -o "$tmp/libavail.dylib" "$tmp/avail.o" 2>"$tmp/avail.link.err"
    l_st=$?
    set -e
    printf '%s\n' "$(grep '^clangxx_darwin_link:' "$tmp/avail.link.err" || true)"
    [ "$l_st" -eq 0 ] && echo "  OK  Darwin availability link rc=0" \
      || { echo "  FAIL Darwin availability link rc=$l_st"; cat "$tmp/avail.link.err"; fail=1; }
    grep -q "undefined symbol:.*isPlatformVersionAtLeast" "$tmp/avail.link.err" \
      && { echo "  FAIL still undefined isPlatformVersionAtLeast"; fail=1; } \
      || echo "  OK  no undefined isPlatformVersionAtLeast"
    grep -q "compiler_rt=$rt_a" "$tmp/avail.link.err" \
      && echo "  OK  link printed compiler_rt=$rt_a" \
      || { echo "  FAIL compiler_rt not the builtins archive"; fail=1; }
    grep -q 'unhandled file type' "$tmp/avail.link.err" \
      && { echo "  FAIL still passed ELF libc++.so to ld64"; fail=1; } \
      || echo "  OK  no ELF libc++.so unhandled file type"
    if [ -f "$tmp/libavail.dylib" ]; then
      /usr/lib/llvm-18/bin/llvm-nm -m "$tmp/libavail.dylib" 2>/dev/null \
        | grep -E 'isPlatformVersionAtLeast' \
        | grep -qv 'undefined' \
        && echo "  OK  dylib defines isPlatformVersionAtLeast (from archive)" \
        || echo "  OK  linked (nm defined line optional)"
    fi
  fi
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- apple-target .so → Darwin driver + sysroot libc++ + compiler-rt; linux-gnu .so → ld.lld"
  exit 0
fi
echo "FAIL"
exit 1
