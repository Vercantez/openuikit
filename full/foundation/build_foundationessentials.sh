#!/bin/bash
# Port swift-foundation's FoundationEssentials as arm64-apple-macos Mach-O.
#
# #58. DECISION.md §12 ruled Swift `URL` is a PORT of upstream, permanent.
#
# PORT FROM release/6.2.2, NOT main. main is 6.4-era and wants @export,
# @_lifetime/Lifetimes, UInt128 (macOS 15) and `bytes` (macOS 26) against our
# 6.2.4 compiler and macos13.0 target. Switching branches took the URL subset
# from 532 errors to 192, and the whole module now sits at 6. A wrong-branch
# port is indistinguishable from a hard port until you check.
#
# THE MODULE IS THE BUILD UNIT, NOT THE FILE. Cherry-picking "just URL" was
# measured and abandoned: pulling JSON5Scanner.swift for one UInt8 byte
# constant dragged in the entire JSON subsystem (JSONError, JSONMap,
# JSONScanner, 102 errors). Upstream builds all of FoundationEssentials as one
# module and every subset reconstructs a configuration upstream never builds.
# 197 files compile more cleanly than 30 do.
set -euo pipefail
W=${W:-/w}
SF=${SF:?set SF to a swift-foundation checkout on release/6.2.2}
SYS=$W/scratch/sysroot_fe3

# Private sysroot. os/Darwin .swiftmodules REMOVED so canImport() is false and
# upstream's own platform #if chain selects another branch -- the SDK-level
# lever rather than patching upstream's conditionals. Honest, too: we have no
# os_log at runtime either, so canImport(os)==false is TRUE, not a workaround.
# Plus the two headers machorun's SDK does not ship (see full/sdk-gaps/).
if [ ! -d "$SYS" ]; then
    cp -a "$W/scratch/sysroot_full" "$SYS"
    rm -rf "$SYS/usr/lib/swift/os.swiftmodule" "$SYS/usr/lib/swift/Darwin.swiftmodule"
    cp -r "$W/full/sdk-gaps/usr/include/." "$SYS/usr/include/"
fi

# Space-safe: several upstream files have spaces in their names
# ("AttributedString/Collection Extensions.swift"), and an unquoted $(find)
# splits them into two nonexistent paths. That produced exactly 2 errors and
# read as a port problem for one confusing minute.
SRCS=()
while IFS= read -r f; do SRCS+=("$f"); done < <(
    find "$SF/Sources/FoundationEssentials" -name '*.swift' \
    | grep -viE 'URL_Bridge|URLComponents_ObjC|URL_Swift|String\+Bridging|_ObjC')
echo "== FoundationEssentials: ${#SRCS[@]} files"

swiftc -target arm64-apple-macos13.0 -sdk "$SYS" \
    -module-cache-path "$W/scratch/modcache_fe" \
    -module-name FoundationEssentials -wmo "$@" \
    -Xfrontend -enable-builtin-module \
    -Xfrontend -disable-implicit-string-processing-module-import \
    "${SRCS[@]}"
