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
printf '%s\n' "$got" | grep -F -- '-nostdlib' >/dev/null \
  && { echo "  FAIL shim injected -nostdlib"; fail=1; } \
  || echo "  OK  did not inject -nostdlib"
printf '%s\n' "$got" | grep -F -- "--ld-path=${LD64_LLD}" >/dev/null \
  && echo "  OK  --ld-path=ld64.lld" || { echo "  FAIL missing --ld-path=ld64.lld"; fail=1; }
printf '%s\n' "$got" | grep -F -- "--ld-path=${LD_LLD}" >/dev/null \
  && { echo "  FAIL apple-target .so selected ld.lld"; fail=1; } \
  || echo "  OK  did not select ld.lld"
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
echo "=== Darwin gold -fuse-ld becomes --ld-path=ld64; -shared kept ==="
got=$(rewrite -target x86_64-apple-macosx13.0 -isysroot /sdk \
  -fuse-ld=gold -B/usr/bin -shared -Wl,-soname,libswiftDarwin.dylib \
  -o libswiftDarwin.dylib foo.o)
printf '%s\n' "$got"
printf '%s\n' "$got" | grep -F -- '-shared' >/dev/null \
  && echo "  OK  kept -shared" || { echo "  FAIL dropped -shared"; fail=1; }
printf '%s\n' "$got" | grep -F -- "-fuse-ld=gold" >/dev/null \
  && { echo "  FAIL gold survived"; fail=1; } \
  || echo "  OK  gold dropped"
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
if [ "$fail" -eq 0 ]; then
  echo "PASS -- apple-target .so → ld64 (driver flags kept); linux-gnu .so → ld.lld"
  exit 0
fi
echo "FAIL"
exit 1
