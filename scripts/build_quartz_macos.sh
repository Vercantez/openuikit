#!/bin/bash
# build_quartz_macos.sh -- THE ORACLE. macOS only: Apple swiftc/clang, the real
# macOS SDK, macOS-built libquartz, run natively. Produces the baseline PNG the
# machorun run must match byte-for-byte.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only" >&2; exit 1; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/build/macos"
QZLIB=${QZLIB:-$HOME/machorun/build/quartz-macos/libquartz.dylib}
[ -f "$QZLIB" ] || { echo "no macOS libquartz at $QZLIB -- build it in ~/machorun first" >&2; exit 1; }
mkdir -p "$OUT/qzinc/quartz"

# quartz headers in an isolated include dir so <stddef.h> still comes from the
# macOS SDK, not the staged machorun SDK.
cp "$HOME/machorun/vendor/quartz/include/quartz/"*.h "$OUT/qzinc/quartz/"
printf 'module Quartz { header "quartz.h" export * }\n' > "$OUT/qzinc/quartz/module.modulemap"

xcrun swiftc -target arm64-apple-macos11 -parse-as-library -emit-object \
  -module-name QuartzDraw -Xfrontend -disable-objc-attr-requires-foundation-module \
  -I "$OUT/qzinc" -o "$OUT/quartz_draw.o" "$ROOT/spike/quartz_draw.swift"
xcrun clang -target arm64-apple-macos11 -O1 -c -o "$OUT/quartz_main.o" "$ROOT/spike/quartz_main.c"
xcrun swiftc -target arm64-apple-macos11 -emit-executable \
  -o "$OUT/quartz_main" "$OUT/quartz_draw.o" "$OUT/quartz_main.o" "$QZLIB"
install_name_tool -change /usr/lib/libquartz.dylib "$QZLIB" "$OUT/quartz_main"

"$OUT/quartz_main" "$OUT/quartz_swift_macos.png"
echo "oracle PNG: $OUT/quartz_swift_macos.png"
