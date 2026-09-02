#!/bin/bash
# Compile a Swift source file on Linux, link it against our cross-built Darwin
# libswiftCore.dylib, and run it under machorun's Mach-O loader.
#
#   scripts/run_under_machorun.sh /tmp/hello.swift
#
# TWO THINGS ARE LOAD-BEARING AND NEITHER IS OBVIOUS:
#
# 1. LINK ORDER: -lswiftCore MUST come before -lSystem. machorun resolves binds
#    with a flat lookup in load order, and its libSystem.B.dylib exports its own
#    `swift_release` *diagnostic stub* (it predates there being a real
#    libswiftCore to load — see machorun docs/UNIMPLEMENTED.md#swift-interop).
#    With libSystem first, objc4's fast-path refcounting binds to that stub and
#    the program aborts the moment any Swift object is released. With
#    libswiftCore first, it binds to the real implementation and the program
#    runs. Same binary, same libraries, different LC_LOAD_DYLIB order.
#
# 2. The optional stdlib modules must be disabled: we build core only, so there
#    is no _Concurrency, _StringProcessing or SwiftOnoneSupport to import. -O
#    avoids the last of those.
set -euo pipefail
W=${W:-$HOME/work}
SDK=$W/sdk/MacOSX.sdk
TC=${TC:-/opt/swift624/usr}
MR=${MR:-$W/machorun}
SRC=${1:?usage: run_under_machorun.sh <file.swift>}
BASE=$(basename "$SRC" .swift)

"$TC/bin/swiftc" -c -target arm64-apple-macos13.0 -sdk "$SDK" \
  -resource-dir "$W/build/lib/swift" -O \
  "$SRC" -o "/tmp/$BASE.o"

"$TC/bin/clang" -target arm64-apple-macos13.0 -isysroot "$SDK" \
  -fuse-ld=lld -B "${LLD_BIN:-/usr/lib/llvm-18/bin}" -nostdlib \
  -L"$SDK/usr/lib" -L"$W/build/lib/swift/macosx/arm64" \
  "/tmp/$BASE.o" \
  -lswiftCore "$MR/darwin/usr/lib/libswiftcompat.dylib" -lSystem -lobjc \
  -o "/tmp/$BASE"

cd "$MR"
exec ./build/machorun "/tmp/$BASE"
