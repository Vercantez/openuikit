#!/bin/bash
# Per-link linker: ELF -soname stays for ld.lld; Darwin -shared is rewritten
# for ld64.lld. Decision is the target triple / output .so vs .dylib, not a
# global PATH or -B that contains both linkers.
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

assert_linker() {
  local want=$1
  if grep -q "^clangxx_darwin_link: linker=${want} " "$tmp/link.err" \
     || grep -q "^clangxx_darwin_link: linker=${want}$" "$tmp/link.err"; then
    echo "  OK  printed linker=${want}"
    grep '^clangxx_darwin_link: linker=' "$tmp/link.err"
  else
    echo "  FAIL expected linker=${want} in:"
    cat "$tmp/link.err"
    fail=1
  fi
}

echo "=== Darwin -shared is rewritten ==="
got=$(rewrite -target x86_64-apple-macosx13.0 -isysroot /sdk \
  -fuse-ld=gold -B/usr/bin -shared -Wl,-soname,libswiftCore.so \
  -o libswiftCore.so foo.o /usr/lib/llvm-18/lib/libc++.so \
  -L/usr/lib/llvm-18/lib -L/home/ubuntu/work/build/lib/swift/macosx/x86_64)
printf '%s\n' "$got"
printf '%s\n' "$got" | grep -F -- '-dynamiclib' >/dev/null \
  && echo "  OK  -dynamiclib" || { echo "  FAIL missing -dynamiclib"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-shared' >/dev/null \
  && { echo "  FAIL still has -shared"; fail=1; } \
  || echo "  OK  no -shared"
printf '%s\n' "$got" | grep -F -- "-fuse-ld=${LD64_LLD}" >/dev/null \
  && echo "  OK  -fuse-ld=ld64.lld" || { echo "  FAIL missing ld64.lld fuse-ld"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-fuse-ld=gold' >/dev/null \
  && { echo "  FAIL gold survived"; fail=1; } \
  || echo "  OK  gold dropped"
assert_linker ld64.lld
printf '%s\n' "$got" | grep -F -- '-Wl,-soname' >/dev/null \
  && { echo "  FAIL -soname survived"; fail=1; } \
  || echo "  OK  no -soname"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftCore.dylib' >/dev/null \
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
echo "=== host ELF -shared with -soname is left for ld.lld ==="
got=$(rewrite -target x86_64-unknown-linux-gnu -shared \
  -Wl,-soname,libswiftCore.so -o libswiftCore.so foo.o)
printf '%s\n' "$got"
printf '%s\n' "$got" | grep -F -- '-shared' >/dev/null \
  && echo "  OK  host -shared kept" || { echo "  FAIL host -shared dropped"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-Wl,-soname,libswiftCore.so' >/dev/null \
  && echo "  OK  ELF -soname kept" || { echo "  FAIL ELF -soname rewritten"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-dynamiclib' >/dev/null \
  && { echo "  FAIL host link grew -dynamiclib"; fail=1; } \
  || echo "  OK  host not Darwin-rewritten"
printf '%s\n' "$got" | grep -F -- "-fuse-ld=${LD_LLD}" >/dev/null \
  && echo "  OK  -fuse-ld=ld.lld" || { echo "  FAIL missing ld.lld fuse-ld"; fail=1; }
printf '%s\n' "$got" | grep -F -- 'ld64.lld' >/dev/null \
  && { echo "  FAIL ELF link selected ld64.lld"; fail=1; } \
  || echo "  OK  ELF link did not select ld64.lld"
assert_linker ld.lld

echo
echo "=== linux triple wins over MacOSX.sdk on an ELF .so ==="
got=$(rewrite -target x86_64-unknown-linux-gnu \
  -isysroot /root/work/sdk/MacOSX.sdk -shared \
  -Wl,-soname,libswiftCore.so -o libswiftCore.so foo.o)
printf '%s\n' "$got" | grep -F -- '-Wl,-soname,libswiftCore.so' >/dev/null \
  && echo "  OK  linux triple keeps -soname" || { echo "  FAIL SDK heuristic stole ELF link"; fail=1; }
assert_linker ld.lld

echo
echo "=== overlay link keeps Darwin-named .so input ==="
got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  -o libswiftDarwin.so Darwin.o \
  /home/ubuntu/work/build/lib/swift/macosx/x86_64/libswiftCore.so)
printf '%s\n' "$got" | grep -F -- 'libswiftCore.so' >/dev/null \
  && echo "  OK  Darwin .so input kept" || { echo "  FAIL dropped overlay dep .so"; fail=1; }

echo
echo "=== Darwin .so output is mirrored to .dylib ==="
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
  -Wl,-soname,libswiftDarwin.so -o libswiftDarwin.so Darwin.o)
printf '%s\n' "$got"
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  -Wl,-soname,libswiftDarwin.so -> Darwin install_name" \
  || { echo "  FAIL concatenated -Wl,-soname,"; fail=1; }

got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  -soname,libswiftDarwin.so -o libswiftDarwin.so Darwin.o)
printf '%s\n' "$got"
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  -soname,libswiftDarwin.so -> Darwin install_name" \
  || { echo "  FAIL bare -soname,"; fail=1; }

got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  -Xlinker -soname -Xlinker libswiftDarwin.so -o libswiftDarwin.so Darwin.o)
printf '%s\n' "$got"
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' >/dev/null \
  && echo "  OK  -Xlinker -soname -> Darwin install_name" \
  || { echo "  FAIL -Xlinker -soname"; fail=1; }

got=$(rewrite -target x86_64-apple-macosx13.0 -shared \
  --as-needed -Wl,-rpath-link,/usr/lib -Wl,-soname,libswiftCore.so \
  -o libswiftCore.so foo.o)
printf '%s\n' "$got"
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- '--as-needed' >/dev/null \
  && { echo "  FAIL --as-needed survived"; fail=1; } \
  || echo "  OK  --as-needed dropped"
printf '%s\n' "$got" | grep -F -- '-rpath-link' >/dev/null \
  && { echo "  FAIL -rpath-link survived"; fail=1; } \
  || echo "  OK  -rpath-link dropped"
assert_linker ld64.lld

echo
echo "=== apple-triple core .so (Linux CMake ELF flags) is still Darwin/ld64 ==="
got=$(rewrite -fPIC -fno-semantic-interposition \
  -target x86_64-apple-macosx13.0 -shared -Wl,-soname,libswiftCore.so \
  -o lib/swift/macosx/x86_64/libswiftCore.so foo.o)
printf '%s\n' "$got"
assert_no_soname "$got"
printf '%s\n' "$got" | grep -F -- "-fuse-ld=${LD64_LLD}" >/dev/null \
  && echo "  OK  apple-triple core uses ld64.lld" \
  || { echo "  FAIL apple-triple core not ld64.lld"; fail=1; }
assert_linker ld64.lld

echo
echo "=== .dylib output without -target is Darwin/ld64 ==="
got=$(rewrite -shared -Wl,-soname,libswiftDarwin.dylib \
  -o libswiftDarwin.dylib Darwin.o)
printf '%s\n' "$got"
assert_no_soname "$got"
assert_linker ld64.lld

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- ELF -soname → ld.lld; Darwin -shared → ld64.lld; linker printed"
  exit 0
fi
echo "FAIL"
exit 1
