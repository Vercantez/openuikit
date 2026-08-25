#!/usr/bin/env bash
#
# Assemble the header set a CLIENT compiles against: build/<arch>/include.
#
# Not the same thing as the build's own include tree (scripts/gen-include-tree.sh),
# which is a symlink farm full of objc4-private headers and only works with the
# force-included compat prefix. This one is self-contained: `clang -I<dir>` and
# nothing else, the way harness/run_linux.sh and any real program uses it.
#
# It is copies, not symlinks, so the directory can be bind-mounted into another
# container at a different path.
set -euo pipefail
WORK=${WORK:-/work}
SRC=$WORK/build/objc4-src
DEST=${1:?usage: gen-sdk.sh <install-include-dir>}

rm -rf "$DEST"
mkdir -p "$DEST/objc"

cp "$SRC"/runtime/*.h "$DEST/objc/"
[ -f "$SRC/runtime/OldClasses.subproj/List.h" ] && \
    cp "$SRC/runtime/OldClasses.subproj/List.h" "$DEST/objc/List.h"

# <objc/objc.h> opens with #include <Availability.h>, so these must resolve.
# Availability.h also carries the handful of Darwin <sys/cdefs.h> spellings
# (__unused, __deprecated, ...) that the public headers use -- see the note in
# compat/Availability.h. That is why a client needs no -include prefix.
for h in Availability.h AvailabilityMacros.h TargetConditionals.h; do
    cp "$WORK/compat/$h" "$DEST/$h"
done

exit 0
