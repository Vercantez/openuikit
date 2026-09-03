#!/bin/bash
# Per-link linker: `-o …*.so` → ELF / ld.lld (keep -soname);
# `-o …*.dylib` (or -install_name / apple triple) → ld64.lld.
# Never by directory names (macosx in the path is not Darwin).
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

echo "=== Darwin -shared .dylib is rewritten for ld64.lld ==="
got=$(rewrite -target x86_64-apple-macosx13.0 -isysroot /sdk \
  -fuse-ld=gold -B/usr/bin -shared -Wl,-soname,libswiftDarwin.dylib \
  -o libswiftDarwin.dylib foo.o /usr/lib/llvm-18/lib/libc++.so \
  -L/usr/lib/llvm-18/lib -L/home/ubuntu/work/build/lib/swift/macosx/x86_64)
printf '%s\n' "$got"
printf '%s\n' "$got" | grep -F -- '-dynamiclib' >/dev/null \
  && echo "  OK  -dynamiclib" || { echo "  FAIL missing -dynamiclib"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-shared' >/dev/null \
  && { echo "  FAIL still has -shared"; fail=1; } \
  || echo "  OK  no -shared"
printf '%s\n' "$got" | grep -F -- "--ld-path=${LD64_LLD}" >/dev/null \
  && echo "  OK  --ld-path=ld64.lld" || { echo "  FAIL missing --ld-path=ld64.lld"; fail=1; }
printf '%s\n' "$got" | grep -E -- '-fuse-ld=/' >/dev/null \
  && { echo "  FAIL deprecated -fuse-ld=<path> survived"; fail=1; } \
  || echo "  OK  no -fuse-ld=<path>"
printf '%s\n' "$got" | grep -F -- '-fuse-ld=gold' >/dev/null \
  && { echo "  FAIL gold survived"; fail=1; } \
  || echo "  OK  gold dropped"
assert_decision libswiftDarwin.dylib darwin ld64.lld
printf '%s\n' "$got" | grep -F -- '-Wl,-soname' >/dev/null \
  && { echo "  FAIL -soname survived"; fail=1; } \
  || echo "  OK  no -soname"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  soname -> Darwin install_name" || { echo "  FAIL missing Darwin install_name"; fail=1; }
printf '%s\n' "$got" | grep -F -- '/usr/lib/llvm-18/lib/libc++.so' >/dev/null \
  && { echo "  FAIL host libc++.so survived"; fail=1; } \
  || echo "  OK  dropped host libc++.so"
printf '%s\n' "$got" | grep -F -- '-L/usr/lib/llvm-18/lib' >/dev/null \
  && { echo "  FAIL host llvm libdir survived"; fail=1; } \
  || echo "  OK  dropped host llvm -L"
printf '%s\n' "$got" | grep -F -- '-nostdlib' >/dev/null \
  && echo "  OK  -nostdlib" || { echo "  FAIL missing -nostdlib"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-lSystem' >/dev/null \
  && echo "  OK  -lSystem" || { echo "  FAIL missing -lSystem"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-lc++' >/dev/null \
  && echo "  OK  -lc++" || { echo "  FAIL missing -lc++"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-Wl,-undefined,dynamic_lookup' >/dev/null \
  && echo "  OK  dynamic_lookup" || { echo "  FAIL missing dynamic_lookup"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-L/home/ubuntu/work/build/lib/swift/macosx/x86_64' >/dev/null \
  && echo "  OK  kept Darwin -L" || { echo "  FAIL dropped Darwin -L"; fail=1; }

echo
echo "=== compile (-c) is not rewritten ==="
got=$(rewrite -target x86_64-apple-macosx13.0 -c -o foo.o foo.cpp)
printf '%s\n' "$got" | grep -F -- '-dynamiclib' >/dev/null \
  && { echo "  FAIL compile grew -dynamiclib"; fail=1; } \
  || echo "  OK  compile argv unchanged in kind"
printf '%s\n' "$got" | grep -F -- '-c' >/dev/null \
  && echo "  OK  still -c" || { echo "  FAIL lost -c"; fail=1; }

echo
echo "=== operator libswiftCore.so (macosx dir, ELF flags, no apple triple) is ELF ==="
# Exact flag head from the operator / CMake Linux CXX_SHARED_LIBRARY log
# (PR #40 classified this as darwin because of the macosx directory / apple
# heuristic). Output is .so → ld.lld, keep -soname.
got=$(rewrite \
  -fPIC -fPIC -fno-semantic-interposition -fvisibility-inlines-hidden \
  -Werror=date-time -Werror=unguarded-availability-new -Wall -Wextra \
  -Wno-unused-parameter -Wwrite-strings -Wcast-qual -Wmissing-field-initializers \
  -Wimplicit-fallthrough -Wcovered-switch-default -Wno-noexcept-type \
  -Wnon-virtual-dtor -Wdelete-non-virtual-dtor -Wsuggest-override \
  -Wstring-conversion -Wmisleading-indentation -Wctad-maybe-unsupported \
  -fdiagnostics-color -ffunction-sections -fdata-sections -O3 -DNDEBUG \
  -B/usr/lib/llvm-18/bin \
  -isysroot /root/work/sdk/MacOSX.sdk \
  -F/root/work/sdk/MacOSX.sdk/../../../Developer/Library/Frameworks \
  -fuse-ld=lld \
  -Wl,-sectcreate,__TEXT,__info_plist,/root/work/build/stdlib/public/core/Info.plist \
  -Wl,-application_extension -Xlinker -compatibility_version -Xlinker 1 \
  -shared -Wl,-soname,libswiftCore.so \
  -o lib/swift/macosx/x86_64/libswiftCore.so \
  foo.o)
printf '%s\n' "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-soname,libswiftCore.so' >/dev/null \
  && echo "  OK  ELF -soname kept" || { echo "  FAIL operator .so lost -soname"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-shared' >/dev/null \
  && echo "  OK  -shared kept" || { echo "  FAIL operator .so dropped -shared"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-dynamiclib' >/dev/null \
  && { echo "  FAIL operator .so grew -dynamiclib"; fail=1; } \
  || echo "  OK  not Darwin-rewritten"
printf '%s\n' "$got" | grep -F -- "--ld-path=${LD_LLD}" >/dev/null \
  && echo "  OK  --ld-path=ld.lld" || { echo "  FAIL missing --ld-path=ld.lld"; fail=1; }
printf '%s\n' "$got" | grep -F -- 'ld64.lld' >/dev/null \
  && { echo "  FAIL operator .so selected ld64.lld"; fail=1; } \
  || echo "  OK  did not select ld64.lld"
assert_decision lib/swift/macosx/x86_64/libswiftCore.so elf ld.lld

echo
echo "=== .so still ELF even with an apple triple (directory names do not win) ==="
got=$(rewrite -fPIC -fno-semantic-interposition \
  -target x86_64-apple-macosx13.0 -shared -Wl,-soname,libswiftCore.so \
  -o lib/swift/macosx/x86_64/libswiftCore.so foo.o)
printf '%s\n' "$got" | grep -F -- '-Wl,-soname,libswiftCore.so' >/dev/null \
  && echo "  OK  apple-triple .so keeps -soname" || { echo "  FAIL apple-triple .so rewritten"; fail=1; }
assert_decision lib/swift/macosx/x86_64/libswiftCore.so elf ld.lld

echo
echo "=== host ELF -shared with -soname is left for ld.lld ==="
got=$(rewrite -target x86_64-unknown-linux-gnu -shared \
  -Wl,-soname,libswiftCore.so -o libswiftCore.so foo.o)
printf '%s\n' "$got"
printf '%s\n' "$got" | grep -F -- '-shared' >/dev/null \
  && echo "  OK  host -shared kept" || { echo "  FAIL host -shared dropped"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-Wl,-soname,libswiftCore.so' >/dev/null \
  && echo "  OK  ELF -soname kept" || { echo "  FAIL ELF -soname rewritten"; fail=1; }
printf '%s\n' "$got" | grep -F -- "--ld-path=${LD_LLD}" >/dev/null \
  && echo "  OK  --ld-path=ld.lld" || { echo "  FAIL missing --ld-path=ld.lld"; fail=1; }
assert_decision libswiftCore.so elf ld.lld

echo
echo "=== linux triple + MacOSX.sdk + .so is still ELF ==="
got=$(rewrite -target x86_64-unknown-linux-gnu \
  -isysroot /root/work/sdk/MacOSX.sdk -shared \
  -Wl,-soname,libswiftCore.so -o libswiftCore.so foo.o)
printf '%s\n' "$got" | grep -F -- '-Wl,-soname,libswiftCore.so' >/dev/null \
  && echo "  OK  linux triple keeps -soname" || { echo "  FAIL SDK heuristic stole ELF link"; fail=1; }
assert_decision libswiftCore.so elf ld.lld

echo
echo "=== overlay link keeps Darwin-named .so input ==="
got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  -o libswiftDarwin.so Darwin.o \
  /home/ubuntu/work/build/lib/swift/macosx/x86_64/libswiftCore.so)
printf '%s\n' "$got" | grep -F -- 'libswiftCore.so' >/dev/null \
  && echo "  OK  Darwin .so input kept" || { echo "  FAIL dropped overlay dep .so"; fail=1; }
assert_decision libswiftDarwin.so elf ld.lld

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
echo "=== overlay Darwin .dylib -soname spellings rewrite to -install_name ==="
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
printf '%s\n' "$got"
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  -Wl,-soname,libswiftDarwin.dylib -> Darwin install_name" \
  || { echo "  FAIL concatenated -Wl,-soname,"; fail=1; }
assert_decision libswiftDarwin.dylib darwin ld64.lld

got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  -soname,libswiftDarwin.dylib -o libswiftDarwin.dylib Darwin.o)
printf '%s\n' "$got"
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  -soname,libswiftDarwin.dylib -> Darwin install_name" \
  || { echo "  FAIL bare -soname,"; fail=1; }

got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  -Xlinker -soname -Xlinker libswiftDarwin.dylib -o libswiftDarwin.dylib Darwin.o)
printf '%s\n' "$got"
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  -Xlinker -soname -> Darwin install_name" \
  || { echo "  FAIL -Xlinker -soname"; fail=1; }

got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  --as-needed -Wl,-rpath-link,/usr/lib -Wl,-soname,libswiftCore.dylib \
  -o libswiftCore.dylib foo.o)
printf '%s\n' "$got"
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '--as-needed' >/dev/null \
  && { echo "  FAIL --as-needed survived"; fail=1; } \
  || echo "  OK  --as-needed dropped"
printf '%s\n' "$got" | grep -F -- '-rpath-link' >/dev/null \
  && { echo "  FAIL -rpath-link survived"; fail=1; } \
  || echo "  OK  -rpath-link dropped"
assert_decision libswiftCore.dylib darwin ld64.lld

echo
echo "=== .dylib output without -target is Darwin/ld64 ==="
got=$(rewrite -shared -Wl,-soname,libswiftDarwin.dylib \
  -o libswiftDarwin.dylib Darwin.o)
printf '%s\n' "$got"
assert_no_soname "$got"
assert_decision libswiftDarwin.dylib darwin ld64.lld

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- -o *.so → ld.lld; -o *.dylib → ld64.lld; --ld-path=; decision printed"
  exit 0
fi
echo "FAIL"
exit 1
