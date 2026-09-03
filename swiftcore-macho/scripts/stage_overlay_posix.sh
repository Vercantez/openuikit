#!/bin/bash
# Stage Apple's POSIX overlay headers into a Darwin sysroot.
#
# Usage: stage_overlay_posix.sh [SDK_ROOT]
#
# Copies verbatim apple-oss-distributions headers (sdk/overlay-posix/) that
# LibcOverlayShims.h / the Platform overlay need and that machorun's SDK
# does not carry: POSIX <semaphore.h> and the <sys/ioctl.h> closure.
# Refuse-overwrite: never bury a real header with this copy.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWIFTCORE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SDK=${1:-${SDK:-$HOME/work/sdk/MacOSX.sdk}}
SRC=$SWIFTCORE_ROOT/sdk/overlay-posix

LIBC_TAG=Libc-1752.120.2
LIBC_COMMIT=4e34d0559e3a1b081afeb8604d9e204a1f31321d
XNU_TAG=xnu-12377.121.6
XNU_COMMIT=ac9718fb1af618d5ce8678d0dc6e8a58f252216f

stage_one() {
  local rel=$1 src=$2 repo=$3 tag=$4 commit=$5 upath=$6
  local dest=$SDK/$rel
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ]; then
    echo "stage_overlay_posix: REFUSING to overwrite $dest" >&2
    echo "  with apple-oss-distributions/$repo $upath ($tag)." >&2
    echo "  If machorun's SDK now carries this header, delete the overlay-posix copy." >&2
    exit 2
  fi
  cp "$src" "$dest"
  echo "stage_overlay_posix: staged $rel"
  echo "  from apple-oss-distributions/$repo tag=$tag commit=$commit path=$upath"
}

[ -d "$SRC" ] || { echo "stage_overlay_posix: missing $SRC" >&2; exit 2; }

stage_one usr/include/semaphore.h "$SRC/semaphore.h" \
  Libc "$LIBC_TAG" "$LIBC_COMMIT" include/semaphore.h
stage_one usr/include/sys/ioctl.h "$SRC/sys/ioctl.h" \
  xnu "$XNU_TAG" "$XNU_COMMIT" bsd/sys/ioctl.h
stage_one usr/include/sys/ioccom.h "$SRC/sys/ioccom.h" \
  xnu "$XNU_TAG" "$XNU_COMMIT" bsd/sys/ioccom.h
stage_one usr/include/sys/ttycom.h "$SRC/sys/ttycom.h" \
  xnu "$XNU_TAG" "$XNU_COMMIT" bsd/sys/ttycom.h
stage_one usr/include/sys/filio.h "$SRC/sys/filio.h" \
  xnu "$XNU_TAG" "$XNU_COMMIT" bsd/sys/filio.h
stage_one usr/include/sys/sockio.h "$SRC/sys/sockio.h" \
  xnu "$XNU_TAG" "$XNU_COMMIT" bsd/sys/sockio.h

echo "stage_overlay_posix: done sysroot=$SDK"
echo "  staged: semaphore.h (Libc $LIBC_TAG) + sys/{ioctl,ioccom,ttycom,filio,sockio}.h (xnu $XNU_TAG)"
