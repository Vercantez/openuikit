#!/usr/bin/env bash
#
# objc4's sources say `#include <objc/runtime.h>` while the headers all live
# flat in runtime/. On Darwin the Xcode project supplies a VFS overlay
# (vendor/objc4/objc-vfs-overlay). We do the same with a generated symlink
# tree, so the vendored sources need no edits for this.
set -euo pipefail
WORK=${WORK:-/work}
SRC=$WORK/build/objc4-src
GEN=$WORK/build/gen

rm -rf "$GEN/include"
mkdir -p "$GEN/include/objc"
for h in "$SRC"/runtime/*.h; do
    ln -sf "$h" "$GEN/include/objc/$(basename "$h")"
done
# OldClasses.subproj/List.h is <objc/List.h> on Darwin.
[ -f "$SRC/runtime/OldClasses.subproj/List.h" ] && \
    ln -sf "$SRC/runtime/OldClasses.subproj/List.h" "$GEN/include/objc/List.h"
exit 0
