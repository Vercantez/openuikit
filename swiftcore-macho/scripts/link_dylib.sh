#!/bin/bash
# Link libswiftCore.dylib from the objects the ninja build produced.
# Thin wrapper around link_macho_dylib.sh kept so BUILD_LOG.md §7 still works.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"
W=${W:-$HOME/work}
B=${B:-$W/build}
LOG=${LOG:-$W/build.log}
if [ ! -f "$LOG" ]; then
  # ninja -d keeprsp leaves the link line in the most recent log ninja wrote
  # to the TTY; configure.sh tees cmake to configure.log. Prefer an explicit
  # ninja log, else scan the ninja build dir's .ninja_log is useless (no argv).
  echo "link_dylib.sh: set LOG= to the ninja stdout that contains the ELF link line" >&2
  echo "  (the one with -o lib/swift/macosx/${SWIFTCORE_DARWIN_ARCH}/libswiftCore.so)" >&2
  exit 2
fi
exec "$SCRIPT_DIR/link_macho_dylib.sh" "$LOG" libswiftCore "$@"
