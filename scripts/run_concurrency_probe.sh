#!/bin/bash
# Build the concurrency probe against our cross-built stdlib + _Concurrency and
# run it under machorun. Differential target: tests/expected/concurrency_probe.macos.txt
#
# Link order is load-bearing: -lswiftCore BEFORE -lSystem. machorun binds by flat
# lookup in load order and its libSystem carries swift_release stubs; wrong order
# aborts on the first Swift release. See scripts/run_under_machorun.sh.
set -euo pipefail
W=${W:-$HOME/work}
SDK=$W/sdk/MacOSX.sdk
TC=${TC:-/opt/swift624/usr}
MR=${MR:-$W/machorun}
SRC=${1:-$W/tests/concurrency_probe.swift}
EXTRA_SWIFT=${EXTRA_SWIFT:-}
NAME=$(basename "$SRC" .swift)

RES=$W/build/lib/swift
GUEST=$MR/darwin/usr/lib

# Stage the runtime into the guest root.
mkdir -p "$GUEST/swift"
cp "$W/build/lib/swift/macosx/arm64/libswiftCore.dylib"        "$GUEST/swift/"
cp "$W/build/lib/swift/macosx/arm64/libswift_Concurrency.dylib" "$GUEST/swift/"
[ -f "$GUEST/libswiftcompat.dylib" ] || bash "$W/scripts/build_compat.sh" >/dev/null

# NOTE: no -disable-implicit-concurrency-module-import here. Importing
# _Concurrency is the entire point; a build that could not import it would be
# the thing under test failing.
"$TC/bin/swiftc" -c -target arm64-apple-macos13.0 -sdk "$SDK" \
  -resource-dir "$RES" -O -swift-version 5 -parse-as-library \
  $EXTRA_SWIFT "$SRC" -o "/tmp/$NAME.o"

"$TC/bin/clang" -target arm64-apple-macos13.0 -isysroot "$SDK" \
  -fuse-ld=lld -B "${LLD_BIN:-/usr/lib/llvm-18/bin}" -nostdlib \
  -L"$SDK/usr/lib" -L"$W/build/lib/swift/macosx/arm64" \
  "/tmp/$NAME.o" \
  -lswiftCore -lswift_Concurrency "$GUEST/libswiftcompat.dylib" -lSystem -lobjc \
  -o "/tmp/$NAME"

echo "built /tmp/$NAME:"; /usr/lib/llvm-18/bin/llvm-otool -L "/tmp/$NAME" 2>/dev/null | tail -n +2 | sed 's/^/    /'
echo "--- running under machorun ---"
cd "$MR"
./build/machorun "/tmp/$NAME"
