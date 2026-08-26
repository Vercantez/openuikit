#!/bin/bash
set -uo pipefail
ROOT=/w; SYS=$ROOT/scratch/sysroot; OUT=$ROOT/build/slice; MC=$ROOT/scratch/modcache
mkdir -p "$OUT"
swiftc -target arm64-apple-macos11 -sdk "$SYS" -module-cache-path "$MC" \
  -runtime-compatibility-version none -parse-as-library -wmo \
  \
  -Xfrontend -disable-objc-attr-requires-foundation-module \
  -module-name UIKitSlice -emit-module -emit-module-path "$OUT/UIKitSlice.swiftmodule" \
  -o "$OUT/uikitslice.o" $ROOT/slice/src/*.swift
