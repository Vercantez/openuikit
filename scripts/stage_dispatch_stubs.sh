#!/bin/bash
# The six headers libdispatch's internal.h reaches that our sysroot lacks.
#
# FIVE OF THE SIX HAVE ZERO USES IN src/ — measured, not assumed. They are
# included and never referenced, so an empty stub is CORRECT rather than
# expedient: there is no sockaddr_in, no struct statfs and no layout to get
# wrong. Writing them "properly" would mean inventing ABI we cannot verify,
# which is strictly worse.
#
# sys/sysctl.h is the exception: hw_config.h:206 really calls sysctlbyname.
# See dispatch_patches.py #2 — upstream already has the correct
# sysconf(_SC_NPROCESSORS_ONLN) fallback, so we take that rather than fake a
# Darwin API over Linux.
set -euo pipefail
SDK=${SDK:-$HOME/work/sdk/MacOSX.sdk}
INC=$SDK/usr/include
mkdir -p "$INC/sys" "$INC/netinet"

stub() { # $1 = path, $2 = guard, $3 = why
  cat > "$INC/$1" <<EOF
#ifndef $2
#define $2
/* swiftcore-macho: $3
 *
 * libdispatch includes this header and never uses anything from it (verified by
 * grep over src/ for its API surface). An empty stub is therefore the honest
 * answer -- no invented struct layouts, nothing to get silently wrong. If a
 * future consumer actually needs this header, DELETE THIS FILE and stage a real
 * one; do not grow it field by field. */
#endif
EOF
}

stub sys/socket.h  _SWIFTCORE_MACHO_SYS_SOCKET_H  "no socket API is referenced by libdispatch"
stub netinet/in.h  _SWIFTCORE_MACHO_NETINET_IN_H  "no sockaddr_in or IP constant is referenced"
stub sys/queue.h   _SWIFTCORE_MACHO_SYS_QUEUE_H   "no LIST_/TAILQ_/STAILQ_/SLIST_ macro is referenced"
stub search.h      _SWIFTCORE_MACHO_SEARCH_H      "no hsearch/tsearch/lfind/lsearch is referenced"

# ---------------------------------------------------------------------------
# sys/mount.h is DIFFERENT and must not stay a stub.
# CFLocale on the Foundation track has a genuine consumer, and machorun-isamask
# owns staging a real one with provenance. This placeholder exists only so the
# libdispatch build can proceed in the interim; it is deliberately loud about
# that so it cannot quietly become the permanent answer.
# ---------------------------------------------------------------------------
cat > "$INC/sys/mount.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_SYS_MOUNT_H
#define _SWIFTCORE_MACHO_SYS_MOUNT_H
/* ***  INTERIM PLACEHOLDER -- DO NOT SHIP, DO NOT EXTEND  ***
 *
 * libdispatch includes <sys/mount.h> and uses nothing from it, so an empty
 * header unblocks that build. But CFLocale (Foundation track) DOES use this
 * header for real, and a real sys/mount.h with struct statfs is owned by
 * machorun-isamask with provenance discipline.
 *
 * When that lands, this file must be DELETED, not merged with. A struct statfs
 * invented here would be exactly the opaque-pointer/inline-struct ABI hazard
 * that class of bug is named for: it would compile, link, return success, and
 * corrupt memory. */
#if defined(__cplusplus)
#endif
#endif
EOF

echo "staged 6 dispatch stub headers into $INC"
echo "  NOTE: sys/mount.h is an INTERIM placeholder; the real one is owned elsewhere."
