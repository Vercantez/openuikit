#!/bin/bash
# Darwin-target -shared from a Linux CMake rule must be rewritten to
# -dynamiclib -fuse-ld=lld -nostdlib -lSystem; gold / host ELF libc++ dropped.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
py=$SCRIPT_DIR/clangxx_darwin_link.py
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

rewrite() {
  SWIFTCORE_CLANGXX_PRINT_REWRITTEN=1 python3 "$py" "$@"
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
printf '%s\n' "$got" | grep -F -- '-fuse-ld=lld' >/dev/null \
  && echo "  OK  -fuse-ld=lld" || { echo "  FAIL missing lld"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-fuse-ld=gold' >/dev/null \
  && { echo "  FAIL gold survived"; fail=1; } \
  || echo "  OK  gold dropped"
printf '%s\n' "$got" | grep -F -- '-Wl,-soname' >/dev/null \
  && { echo "  FAIL -soname survived"; fail=1; } \
  || echo "  OK  no -soname"
printf '%s\n' "$got" | grep -F -- '-Wl,-install_name,libswiftCore.so' >/dev/null \
  && echo "  OK  soname -> install_name" || { echo "  FAIL missing install_name"; fail=1; }
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
echo "=== host ELF -shared is not rewritten ==="
got=$(rewrite -target x86_64-unknown-linux-gnu -shared -o libfoo.so foo.o)
printf '%s\n' "$got" | grep -F -- '-shared' >/dev/null \
  && echo "  OK  host -shared kept" || { echo "  FAIL host -shared dropped"; fail=1; }
printf '%s\n' "$got" | grep -F -- '-dynamiclib' >/dev/null \
  && { echo "  FAIL host link grew -dynamiclib"; fail=1; } \
  || echo "  OK  host not Darwin-rewritten"

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
if [ "$fail" -eq 0 ]; then
  echo "PASS -- Darwin shared link rewrite (lld, not gold; no host ELF libc++)"
  exit 0
fi
echo "FAIL"
exit 1
