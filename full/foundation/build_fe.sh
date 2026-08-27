#!/bin/bash
# build_fe.sh -- port swift-foundation's FoundationEssentials as
# arm64-apple-macos Mach-O, with canImport(Darwin) TRUE (route (A), the ioctl
# contract: everything above libSystem speaks Darwin).
#
# Supersedes build_foundationessentials.sh, whose sysroot recipe has two defects
# that were correct when written and are wrong now:
#
#   1. It REMOVED Darwin.swiftmodule so canImport(Darwin) was false. That was
#      the pre-ruling workaround. machorun 8380ae9/34e824b make the Clang
#      module Darwin real, and full/sdk-gaps/README.md's RULING is route (A).
#   2. `cp -r full/sdk-gaps/usr/include/. $SYS/usr/include/` copied a
#      SEVENTEEN-line stand-in over machorun's real 680-line <sys/attr.h>,
#      which machorun has shipped since 8380ae9. A shadowing copy cannot fail:
#      it subtracts silently. Only complex.h is still a gap, so only complex.h
#      is copied, and the copy REFUSES if the file is already there.
#
# THE SYSROOT MUST BE RESTAGED, NOT REUSED. scratch/sysroot was staged at
# 12:22:24 and machorun's sdk/ was last touched at 12:26:30 -- four minutes
# of skew, and every git-level check says both trees are current. Restaging is
# cheap; measuring a photograph is not.
#
# PORT FROM release/6.2.2, NOT main. main is 6.4-era and wants @export,
# @_lifetime/Lifetimes, UInt128 (macOS 15) and `bytes` (macOS 26) against our
# 6.2.4 compiler. Switching branches took the URL subset from 532 errors to 192.
#
# THE MODULE IS THE BUILD UNIT, NOT THE FILE. Cherry-picking "just URL" was
# measured and abandoned: pulling JSON5Scanner.swift for one UInt8 byte
# constant dragged in the entire JSON subsystem (102 errors).
set -euo pipefail
W=${W:-/w}
SF=${SF:-$W/scratch/swift-foundation}
SYS=${SYS:-$W/scratch/sysroot_fe4}
[ -d "$SF/Sources/FoundationEssentials" ] || { echo "no $SF" >&2; exit 1; }
[ -d "$SYS/usr/include" ] || { echo "no sysroot $SYS -- run stage_fe_sysroot.sh on macOS" >&2; exit 1; }

# ALL 202 FILES.  The old recipe filtered out five by name --
# URL_Bridge / URL_ObjC / URL_Swift / URLComponents_ObjC / String+Bridging --
# on the reading that they are the ObjC-bridging half.  FOUR of the five are;
# `URL_Swift.swift` IS THE OPPOSITE, and dropping it deleted the port's entire
# deliverable.  Its own header says so: "Outside of FOUNDATION_FRAMEWORK,
# `_SwiftURL` provides the sole implementation for `URL`."  The symptom was six
# "cannot find type '_SwiftURL' in scope" errors inside URL.swift's own
# `#else` branch (URL.swift:648, 657, 658, 778, 1358).
#
# Upstream's own non-framework build settles it: Sources/FoundationEssentials/
# URL/CMakeLists.txt lists all fourteen URL files including URL_Swift.swift,
# URL_Bridge.swift, URL_ObjC.swift and URLComponents_ObjC.swift, and
# String/CMakeLists.txt lists String+Bridging.swift.  They are guarded INSIDE
# by `#if FOUNDATION_FRAMEWORK` and compile to nothing here.  Excluding by
# filename second-guesses a conditional the file already contains.
#
# NB the memory note "URL is unconditionally `_URL`, a native Swift final class
# (URL_Impl.swift:42)" describes MAIN, not release/6.2.2.  On the branch we
# port, the class is `_SwiftURL` in URL/URL_Swift.swift.  Same architecture,
# different names -- and the wrong name is what made the filter look right.
#
# Space-safe: several upstream files have spaces in their names
# ("AttributedString/Collection Extensions.swift"), and an unquoted $(find)
# splits them into two nonexistent paths -- exactly 2 errors that read as a
# port problem.
SRCS=()
while IFS= read -r f; do SRCS+=("$f"); done < <(
    find "$SF/Sources/FoundationEssentials" -name '*.swift' | sort)
echo "== FoundationEssentials: ${#SRCS[@]} files"

# UPSTREAM'S OWN BUILD CONFIGURATION, COPIED RATHER THAN CHOSEN.
# Sources/FoundationEssentials/CMakeLists.txt:81-91 and Package.swift:116-156.
# Every flag below is upstream's; none is invented here. The first measurement
# of this module was taken WITHOUT them and reported 1,581 error lines, of
# which the great majority were configuration, not port:
#
#   -package-name SwiftFoundation   absent -> "the package access level used on
#                                   X requires a package name" x50, and every
#                                   `package` member then reads as inaccessible
#   Regex                           the old recipe passed
#                                   -disable-implicit-string-processing-module-import,
#                                   which upstream does NOT; "cannot find type
#                                   'Regex' in scope" x9 followed.
#   the feature flags               VariadicGenerics, LifetimeDependence,
#                                   AddressableTypes, AccessLevelOnImport,
#                                   StrictConcurrency, InferSendableFromCaptures,
#                                   MemberImportVisibility -- only BuiltinModule
#                                   was being passed.
#   AvailabilityMacro=...           `@available(FoundationPreview 6.2, *)` is a
#                                   MACRO upstream defines on the command line.
#
# A count taken in a configuration upstream never builds measures the
# configuration, not the port.
AVAIL="macOS 15, iOS 18, tvOS 18, watchOS 11"   # Package.swift _OSAvailability.alwaysAvailable
FEATURES=()
for f in VariadicGenerics LifetimeDependence AddressableTypes AllowUnsafeAttribute \
         BuiltinModule AccessLevelOnImport StrictConcurrency; do
    FEATURES+=(-enable-experimental-feature "$f")
done
for v in 6.0.2 6.1 6.2; do
    FEATURES+=(-enable-experimental-feature "AvailabilityMacro=FoundationPreview $v:$AVAIL")
done
for f in InferSendableFromCaptures MemberImportVisibility; do
    FEATURES+=(-enable-upcoming-feature "$f")
done

swiftc -target "${TARGET:-arm64-apple-macos15.0}" -sdk "$SYS" \
    -module-cache-path "$W/scratch/modcache_fe4" \
    -module-name FoundationEssentials -wmo \
    -runtime-compatibility-version none \
    -package-name SwiftFoundation \
    -I "${OSMOD:-$W/scratch/fe4_os}" \
    ${COLLECTIONS:+-I "$COLLECTIONS"} \
    "${FEATURES[@]}" \
    "$@" \
    "${SRCS[@]}"
