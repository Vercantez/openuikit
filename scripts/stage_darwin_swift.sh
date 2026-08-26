#!/bin/bash
# stage_darwin_swift.sh -- MACOS ONLY. Build scratch/sysroot: the one Apple
# dependency this spike has, isolated in a gitignored directory so it is
# obvious and reproducible.
#
#   usr/include, usr/lib/*.tbd   <- ~/machorun/sdk  (no Apple headers at all)
#   usr/lib/swift/               <- $(xcrun --show-sdk-path --sdk macosx)
#                                   159 entries, 12 MB: *.swiftinterface
#                                   (textual, library-evolution) + *.tbd
#
# Nothing from Xcode's *toolchain* is staged: the Linux compiler's own
# resource dir supplies SwiftShims, and it RECOMPILES the textual interfaces,
# which is what makes the 6.2.1 -> 6.2.4 version skew a non-issue.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only" >&2; exit 1; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MACHORUN=${MACHORUN:-$HOME/machorun}
SDK=$(xcrun --show-sdk-path --sdk macosx)
SYS="$ROOT/scratch/sysroot"
rm -rf "$SYS"; mkdir -p "$SYS/usr"
cp -R "$MACHORUN/sdk/usr/include" "$SYS/usr/include"
cp -R "$MACHORUN/sdk/usr/lib"     "$SYS/usr/lib"
cp -R "$SDK/usr/lib/swift"        "$SYS/usr/lib/swift"
echo "staged from $SDK"
echo "  usr/lib/swift : $(ls "$SYS/usr/lib/swift" | wc -l | tr -d ' ') entries, $(du -sh "$SYS/usr/lib/swift" | cut -f1)"
echo "  usr/include   : $(find "$SYS/usr/include" -type f | wc -l | tr -d ' ') headers (from machorun/sdk)"
echo "  total         : $(du -sh "$SYS" | cut -f1)"
