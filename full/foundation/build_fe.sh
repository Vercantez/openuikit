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
PINNED_INPUTS_TOOL=${PINNED_INPUTS_TOOL:-$W/full/foundation/pinned_inputs.pl}
URL_RESOURCE_KEY_PATCH=${URL_RESOURCE_KEY_PATCH:-$W/full/foundation/patches/FoundationEssentials-URLResourceKey.patch}
PREDICATE_KEYPATH_PATCH=${PREDICATE_KEYPATH_PATCH:-$W/full/foundation/patches/FoundationEssentials-PredicateFinalClassKeyPath.patch}
IOS_HOME_DIRECTORY_PATCH=${IOS_HOME_DIRECTORY_PATCH:-$W/full/foundation/patches/FoundationEssentials-URLIOSHomeDirectory.patch}
EXPECTED_PREDICATE_KEYPATH_SOURCE_SHA=835ca09d5d0bf757abc02af0ca4294cc58bcad3d455ef71c1026746ad7ba08f7
EXPECTED_PREDICATE_KEYPATH_PATCH_SHA=ecf4e8045d42fb196705f37fbf723f75e11c20d9d6b2adc251210ed87e1464de
EXPECTED_IOS_HOME_DIRECTORY_PATCH_SHA=37ec5f335225bb8ae6860d50305975827f9b4228abe8c4ec0303b97fb8e45848
[ -d "$SF/Sources/FoundationEssentials" ] || { echo "no $SF" >&2; exit 1; }
[ -d "$SYS/usr/include" ] || { echo "no sysroot $SYS -- run stage_fe_sysroot.sh on macOS" >&2; exit 1; }
[ -f "$PINNED_INPUTS_TOOL" ] || { echo "no pinned-input tool $PINNED_INPUTS_TOOL" >&2; exit 1; }
[ -f "$URL_RESOURCE_KEY_PATCH" ] || { echo "no URLResourceKey patch $URL_RESOURCE_KEY_PATCH" >&2; exit 1; }
[ -f "$PREDICATE_KEYPATH_PATCH" ] || { echo "no Predicate key-path patch $PREDICATE_KEYPATH_PATCH" >&2; exit 1; }
[ -f "$IOS_HOME_DIRECTORY_PATCH" ] || { echo "no iOS home-directory patch $IOS_HOME_DIRECTORY_PATCH" >&2; exit 1; }

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
# ("AttributedString/Collection Extensions.swift"). The input list comes from
# the exact pinned Git tree, never an unrestricted filesystem walk; the tool
# also rejects ignored/untracked sources before returning any paths.
SRCS=()
SOURCE_LIST=$(perl "$PINNED_INPUTS_TOOL" list \
    --repository swift-foundation --repo "$SF" --group foundation-swift)
while IFS= read -r f; do
    [ -n "$f" ] && SRCS+=("$f")
done <<<"$SOURCE_LIST"
[ "${#SRCS[@]}" -eq 202 ] || {
    echo "build_fe: pinned FoundationEssentials manifest is not exactly 202 files" >&2
    exit 2
}

# Foundation.framework and standalone FoundationEssentials intentionally use
# different halves of upstream URL.swift.  We need the framework's real
# URLResourceKey value identity while retaining the standalone URL engine.
# Patch a derived copy only: the pinned upstream checkout remains byte-for-byte
# unchanged and is still bracketed by the package builder's input attestation.
FOUNDATION_URL_SOURCE=$SF/Sources/FoundationEssentials/URL/URL.swift
PATCHED_SOURCE_DIR=$W/build/foundationessentials-port-sources
PATCHED_URL_RESOURCE_SOURCE=$PATCHED_SOURCE_DIR/URL-resource-key.swift
PATCHED_URL_SOURCE=$PATCHED_SOURCE_DIR/URL.swift
FOUNDATION_PREDICATE_KEYPATH_SOURCE=$SF/Sources/FoundationEssentials/Predicate/KeyPath+Inspection.swift
PATCHED_PREDICATE_KEYPATH_SOURCE=$PATCHED_SOURCE_DIR/KeyPath+Inspection.swift
[ "$(sha256sum "$FOUNDATION_PREDICATE_KEYPATH_SOURCE" | awk '{print $1}')" = \
    "$EXPECTED_PREDICATE_KEYPATH_SOURCE_SHA" ] || {
        echo "build_fe: pinned Predicate key-path source hash drifted" >&2
        exit 2
    }
[ "$(sha256sum "$PREDICATE_KEYPATH_PATCH" | awk '{print $1}')" = \
    "$EXPECTED_PREDICATE_KEYPATH_PATCH_SHA" ] || {
        echo "build_fe: Predicate key-path patch hash drifted" >&2
        exit 2
    }
[ "$(sha256sum "$IOS_HOME_DIRECTORY_PATCH" | awk '{print $1}')" = \
    "$EXPECTED_IOS_HOME_DIRECTORY_PATCH_SHA" ] || {
        echo "build_fe: iOS home-directory patch hash drifted" >&2
        exit 2
    }
rm -rf -- "$PATCHED_SOURCE_DIR"
mkdir -p "$PATCHED_SOURCE_DIR"
patch --batch --forward --fuzz=0 -s -o "$PATCHED_URL_RESOURCE_SOURCE" \
    "$FOUNDATION_URL_SOURCE" "$URL_RESOURCE_KEY_PATCH"
case "${TARGET:-arm64-apple-macos15.0}" in
    *-apple-ios*-simulator)
        patch --batch --forward --fuzz=0 -s -o "$PATCHED_URL_SOURCE" \
            "$PATCHED_URL_RESOURCE_SOURCE" "$IOS_HOME_DIRECTORY_PATCH"
        ;;
    *)
        cp "$PATCHED_URL_RESOURCE_SOURCE" "$PATCHED_URL_SOURCE"
        ;;
esac
patch --batch --forward --fuzz=0 -s -o "$PATCHED_PREDICATE_KEYPATH_SOURCE" \
    "$FOUNDATION_PREDICATE_KEYPATH_SOURCE" "$PREDICATE_KEYPATH_PATCH"
patched_url_count=0
patched_predicate_keypath_count=0
for source_index in "${!SRCS[@]}"; do
    if [ "${SRCS[$source_index]}" = "$FOUNDATION_URL_SOURCE" ]; then
        SRCS[$source_index]=$PATCHED_URL_SOURCE
        patched_url_count=$((patched_url_count + 1))
    fi
    if [ "${SRCS[$source_index]}" = "$FOUNDATION_PREDICATE_KEYPATH_SOURCE" ]; then
        SRCS[$source_index]=$PATCHED_PREDICATE_KEYPATH_SOURCE
        patched_predicate_keypath_count=$((patched_predicate_keypath_count + 1))
    fi
done
[ "$patched_url_count" -eq 1 ] || {
    echo "build_fe: URL.swift replacement count $patched_url_count, expected 1" >&2
    exit 2
}
[ "$patched_predicate_keypath_count" -eq 1 ] || {
    echo "build_fe: predicate key-path replacement count $patched_predicate_keypath_count, expected 1" >&2
    exit 2
}
grep -F 'public struct URLResourceKey: RawRepresentable, Hashable, Sendable' \
    "$PATCHED_URL_SOURCE" >/dev/null || {
        echo "build_fe: derived URLResourceKey source is incomplete" >&2
        exit 2
    }
case "${TARGET:-arm64-apple-macos15.0}" in
    *-apple-ios*-simulator)
        grep -F 'URL(filePath: String.homeDirectoryPath(), directoryHint: .isDirectory)' \
            "$PATCHED_URL_SOURCE" >/dev/null || {
                echo "build_fe: derived iOS home-directory source is incomplete" >&2
                exit 2
            }
        ;;
esac
grep -F 'STORED_COMPONENT_PAYLOAD_MAXIMUM_INLINE_OFFSET' \
    "$PATCHED_PREDICATE_KEYPATH_SOURCE" >/dev/null || {
        echo "build_fe: derived Predicate key-path source is incomplete" >&2
        exit 2
    }
# THE TARGET TRAVELS WITH THE ARTIFACT, not just with a commit message.  This
# module raises the deployment floor of everything that links it: macos15.0,
# because Package.swift:92 declares `.macOS("15")` and `Mutex` is
# @available(macOS 15).  Anyone later diffing this against a macos13 binary
# would be reading ABI noise as a port bug.
echo "== FoundationEssentials: ${#SRCS[@]} files, target ${TARGET:-arm64-apple-macos15.0}"
# ALL tags at HEAD, not `git describe --exact-match`, which picks one
# arbitrarily.  swift-foundation's release/6.2.2 HEAD carries BOTH
# swift-6.2.1-RELEASE and swift-6.2.2-RELEASE -- the module did not change
# between those releases -- and describe printed the 6.2.1 one, a report line
# that reads as the wrong branch.
echo "   swift-foundation  $(cd "$SF" && git rev-parse --short HEAD)  tags: $(cd "$SF" && git tag --points-at HEAD | tr '\n' ' ')"

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
    -Xcc -fmodule-map-file="$SF/Sources/_FoundationCShims/include/module.modulemap" \
    -Xcc -I"$SF/Sources/_FoundationCShims/include" \
    "${FEATURES[@]}" \
    "$@" \
    "${SRCS[@]}"
