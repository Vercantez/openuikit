#!/usr/bin/env bash
# Quarantined Swift 6.2.4 compile probe for untouched Hackers UI targets.
# DesignSystem is always compiled first; HACKERS_PROBE_SCOPE optionally adds
# Comments, WhatsNew, or Feed. The caller mounts every input read-only and provides
# a new, empty /out directory.  This intentionally rebuilds the changed
# OpenUIKit/UIKit/SwiftUI modules before application type checking, so an old
# package binary cannot hide a source or ABI failure.

set -euo pipefail

TARGET=arm64-apple-macos15.0

for required in /pkg/sdk /pkg/modules /pkg/include /uikit/Sources/OpenUIKit \
    /uikit/Sources/SwiftUI /support/full/shims/FoundationNames.swift \
    /foundation/modules/Foundation.swiftmodule /dispatch/modules/Dispatch.swiftmodule \
    /graph-modules/Domain.swiftmodule \
    /graph-modules/Shared.swiftmodule /app/DesignSystem/Sources/DesignSystem; do
    [ -e "$required" ] || {
        echo "hackers DesignSystem probe: missing input: $required" >&2
        exit 2
    }
done

[ -z "$(find /out -mindepth 1 -maxdepth 1 -print -quit)" ] || {
    echo 'hackers DesignSystem probe refuses a nonempty output directory' >&2
    exit 2
}

mkdir -p "$HOME" "$XDG_CACHE_HOME" /out/modules /out/base-modules \
    /out/hidden-modules \
    /out/objects /out/module-cache /out/logs

copy_module_family() {
    local source=$1 name=$2 suffix
    [ -f "$source/$name.swiftmodule" ] || {
        echo "missing module family: $source/$name.swiftmodule" >&2
        exit 2
    }
    for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json \
        swiftinterface private.swiftinterface; do
        [ ! -f "$source/$name.$suffix" ] \
            || cp "$source/$name.$suffix" /out/base-modules/
    done
}

# OpenUIKit and SwiftUI must not see the Foundation umbrella.  Stage only the
# explicit low-level dependencies into their search roots.
for module in FoundationEssentials InternalCollectionsUtilities \
    OrderedCollections _RopeModule os OpenCombine Combine Observation; do
    copy_module_family /pkg/modules "$module"
done

cat >/out/foundation-hidden-guard.swift <<'EOF'
#if canImport(Foundation)
#error("Foundation umbrella leaked into the framework compile")
#endif
import FoundationEssentials
EOF

SWIFTC=(
    swiftc -target "$TARGET" -sdk /pkg/sdk
    -module-cache-path /out/module-cache
    -runtime-compatibility-version none -wmo
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xfrontend -disable-objc-attr-requires-foundation-module
)
C_FLAGS=(
    -Xcc -I/pkg/include/CPortableIO
    -Xcc -I/pkg/include/CSTBTrueType
    -Xcc -I/pkg/include/CHostClock
    -Xcc -I/pkg/include/COpenCombineHelpers
    -Xcc -I/pkg/include/CQuartz
    -Xcc -fmodule-map-file=/pkg/include/CoreImage/module.modulemap
    -Xcc -I/pkg/include/CoreImage
    -Xcc -fmodule-map-file=/pkg/include/COpenURLTransport/module.modulemap
    -Xcc -I/pkg/include/COpenURLTransport
    -Xcc -fmodule-map-file=/pkg/include/COpenRelativeTime/module.modulemap
    -Xcc -I/pkg/include/COpenRelativeTime
    -Xcc -fmodule-map-file=/dispatch/include/COpenDispatch/module.modulemap
    -Xcc -I/dispatch/include/COpenDispatch
    -Xcc -fmodule-map-file=/pkg/include/_FoundationCShims/module.modulemap
    -Xcc -I/pkg/include/_FoundationCShims
)

"${SWIFTC[@]}" "${C_FLAGS[@]}" -I /out/base-modules \
    -typecheck -module-name FoundationHiddenGuard \
    /out/foundation-hidden-guard.swift

mapfile -d '' -t OPENUIKIT_SOURCES < <(
    find /uikit/Sources/OpenUIKit -type f -name '*.swift' -print0 \
        | LC_ALL=C sort -z
)
mapfile -d '' -t OPENCOREGRAPHICS_SOURCES < <(
    find /uikit/Sources/OpenCoreGraphics -type f -name '*.swift' -print0 \
        | LC_ALL=C sort -z
)
mapfile -d '' -t SWIFTUI_SOURCES < <(
    find /uikit/Sources/SwiftUI -maxdepth 1 -type f -name '*.swift' -print0 \
        | LC_ALL=C sort -z
)
mapfile -d '' -t DESIGNSYSTEM_SOURCES < <(
    find /app/DesignSystem/Sources/DesignSystem -type f -name '*.swift' -print0 \
        | LC_ALL=C sort -z
)
mapfile -d '' -t COMMENTS_SOURCES < <(
    find /app/Features/Comments/Sources/Comments -type f -name '*.swift' -print0 \
        | LC_ALL=C sort -z
)
mapfile -d '' -t WHATSNEW_SOURCES < <(
    find /app/Features/WhatsNew/Sources/WhatsNew -type f -name '*.swift' -print0 \
        | LC_ALL=C sort -z
)
mapfile -d '' -t FEED_SOURCES < <(
    find /app/Features/Feed/Sources/Feed -type f -name '*.swift' -print0 \
        | LC_ALL=C sort -z
)

[ "${#OPENUIKIT_SOURCES[@]}" -eq 105 ]
[ "${#OPENCOREGRAPHICS_SOURCES[@]}" -eq 12 ]
[ "${#SWIFTUI_SOURCES[@]}" -eq 8 ]
[ "${#DESIGNSYSTEM_SOURCES[@]}" -eq 13 ]
[ "${#COMMENTS_SOURCES[@]}" -eq 7 ]
[ "${#WHATSNEW_SOURCES[@]}" -eq 6 ]
[ "${#FEED_SOURCES[@]}" -eq 4 ]

echo '== Foundation-hidden OpenCoreGraphics WMO compile'
"${SWIFTC[@]}" "${C_FLAGS[@]}" -I /out/base-modules \
    -parse-as-library -module-name OpenCoreGraphics \
    -emit-module -emit-module-path /out/modules/OpenCoreGraphics.swiftmodule \
    -emit-object -o /out/objects/OpenCoreGraphics.o \
    "${OPENCOREGRAPHICS_SOURCES[@]}" \
    2>&1 | tee /out/logs/opencoregraphics.log

echo '== Foundation-hidden OpenUIKit WMO compile'
"${SWIFTC[@]}" "${C_FLAGS[@]}" -I /out/base-modules -I /out/modules \
    -parse-as-library -module-name OpenUIKit \
    -emit-module -emit-module-path /out/modules/OpenUIKit.swiftmodule \
    -emit-object -o /out/objects/OpenUIKit.o \
    "${OPENUIKIT_SOURCES[@]}" /support/full/shims/FoundationNames.swift \
    2>&1 | tee /out/logs/openuikit.log

echo '== FoundationEssentials-branch UIKit shim WMO compile'
"${SWIFTC[@]}" "${C_FLAGS[@]}" -I /out/base-modules -I /out/modules \
    -parse-as-library -module-name UIKit \
    -emit-module -emit-module-path /out/modules/UIKit.swiftmodule \
    -emit-object -o /out/objects/UIKit.o \
    /uikit/Sources/UIKitShim/UIKit.swift \
    2>&1 | tee /out/logs/uikit.log

echo '== Foundation-hidden SwiftUI WMO compile'
"${SWIFTC[@]}" "${C_FLAGS[@]}" -I /out/base-modules -I /out/modules \
    -parse-as-library -module-name SwiftUI \
    -emit-module -emit-module-path /out/modules/SwiftUI.swiftmodule \
    -emit-object -o /out/objects/SwiftUI.o \
    "${SWIFTUI_SOURCES[@]}" \
    2>&1 | tee /out/logs/swiftui.log

# Preserve proof that the literal shim also compiled through its
# FoundationEssentials branch, then rebuild its final app-facing module after
# the Foundation umbrella is visible. This is what carries Apple's real
# UIKit -> Foundation -> Dispatch reexport chain into unchanged source.
cp /out/modules/UIKit.* /out/hidden-modules/

echo '== Foundation-visible final UIKit shim WMO compile'
"${SWIFTC[@]}" "${C_FLAGS[@]}" \
    -I /out/modules -I /foundation/modules -I /out/base-modules \
    -I /dispatch/modules -I /pkg/modules \
    -parse-as-library -module-name UIKit \
    -emit-module -emit-module-path /out/modules/UIKit.swiftmodule \
    -emit-object -o /out/objects/UIKit.o \
    /uikit/Sources/UIKitShim/UIKit.swift \
    2>&1 | tee /out/logs/uikit-final.log

echo '== final MessageUI module against rebuilt UIKit reexport chain'
"${SWIFTC[@]}" "${C_FLAGS[@]}" \
    -I /out/modules -I /foundation/modules -I /out/base-modules \
    -I /dispatch/modules -I /pkg/modules \
    -parse-as-library -module-name MessageUI \
    -emit-module -emit-module-path /out/modules/MessageUI.swiftmodule \
    -emit-object -o /out/objects/MessageUI.o \
    /support/full/messageui/MessageUI.swift \
    2>&1 | tee /out/logs/messageui.log

PLUGIN=/pkg/host-tools/swift/host/plugins/libObservationMacros.so
[ -f "$PLUGIN" ] || {
    echo "missing Observation macro plugin: $PLUGIN" >&2
    exit 2
}

echo '== exact untouched 13-source Hackers DesignSystem WMO compile'
"${SWIFTC[@]}" "${C_FLAGS[@]}" \
    -default-isolation MainActor \
    -I /out/modules -I /foundation/modules -I /graph-modules \
    -I /out/base-modules -I /dispatch/modules -I /pkg/modules \
    -load-plugin-library "$PLUGIN" \
    -parse-as-library -module-name DesignSystem \
    -emit-module -emit-module-path /out/modules/DesignSystem.swiftmodule \
    -emit-object -o /out/objects/DesignSystem.o \
    "${DESIGNSYSTEM_SOURCES[@]}" \
    2>&1 | tee /out/logs/designsystem.log

if [ "${HACKERS_PROBE_SCOPE:-designsystem}" = comments ]; then
    echo '== exact untouched 7-source Hackers Comments WMO compile'
    "${SWIFTC[@]}" "${C_FLAGS[@]}" \
        -default-isolation MainActor \
        -I /out/modules -I /foundation/modules -I /graph-modules \
        -I /out/base-modules -I /dispatch/modules -I /pkg/modules \
        -load-plugin-library "$PLUGIN" \
        -parse-as-library -module-name Comments \
        -emit-module -emit-module-path /out/modules/Comments.swiftmodule \
        -emit-object -o /out/objects/Comments.o \
        "${COMMENTS_SOURCES[@]}" \
        2>&1 | tee /out/logs/comments.log
fi

if [ "${HACKERS_PROBE_SCOPE:-designsystem}" = whatsnew ]; then
    echo '== exact untouched 6-source Hackers WhatsNew WMO compile'
    "${SWIFTC[@]}" "${C_FLAGS[@]}" \
        -default-isolation MainActor \
        -I /out/modules -I /foundation/modules -I /graph-modules \
        -I /out/base-modules -I /dispatch/modules -I /pkg/modules \
        -load-plugin-library "$PLUGIN" \
        -parse-as-library -module-name WhatsNew \
        -emit-module -emit-module-path /out/modules/WhatsNew.swiftmodule \
        -emit-object -o /out/objects/WhatsNew.o \
        "${WHATSNEW_SOURCES[@]}" \
        2>&1 | tee /out/logs/whatsnew.log
fi

if [ "${HACKERS_PROBE_SCOPE:-designsystem}" = feed ]; then
    echo '== exact untouched 4-source Hackers Feed WMO compile'
    "${SWIFTC[@]}" "${C_FLAGS[@]}" \
        -default-isolation MainActor \
        -I /out/modules -I /foundation/modules -I /graph-modules \
        -I /out/base-modules -I /dispatch/modules -I /pkg/modules \
        -load-plugin-library "$PLUGIN" \
        -parse-as-library -module-name Feed \
        -emit-module -emit-module-path /out/modules/Feed.swiftmodule \
        -emit-object -o /out/objects/Feed.o \
        "${FEED_SOURCES[@]}" \
        2>&1 | tee /out/logs/feed.log
fi

sha256sum /out/modules/OpenUIKit.swiftmodule /out/modules/UIKit.swiftmodule \
    /out/modules/OpenCoreGraphics.swiftmodule /out/modules/SwiftUI.swiftmodule \
    /out/modules/DesignSystem.swiftmodule /out/objects/OpenCoreGraphics.o \
    /out/objects/OpenUIKit.o /out/objects/SwiftUI.o \
    > /out/artifact-sha256.txt

if [ "${HACKERS_PROBE_SCOPE:-designsystem}" = whatsnew ]; then
    sha256sum /out/modules/WhatsNew.swiftmodule /out/objects/WhatsNew.o \
        >> /out/artifact-sha256.txt
fi


if [ "${HACKERS_PROBE_SCOPE:-designsystem}" = feed ]; then
    sha256sum /out/modules/Feed.swiftmodule /out/objects/Feed.o \
        >> /out/artifact-sha256.txt
fi

printf '%s\n' \
    'HACKERS_DESIGNSYSTEM_EXACT_COMPILE_OK sources=13 framework_wmo=foundation-hidden app=untouched' \
    | tee /out/result.txt

if [ "${HACKERS_PROBE_SCOPE:-designsystem}" = comments ]; then
    printf '%s\n' \
        'HACKERS_COMMENTS_EXACT_COMPILE_OK sources=7 dependencies=untouched framework_wmo=foundation-hidden app=untouched' \
        | tee -a /out/result.txt
fi


if [ "${HACKERS_PROBE_SCOPE:-designsystem}" = whatsnew ]; then
    printf '%s\n' \
        'HACKERS_WHATSNEW_EXACT_COMPILE_OK sources=6 dependencies=untouched framework_wmo=foundation-hidden app=untouched' \
        | tee -a /out/result.txt
fi

if [ "${HACKERS_PROBE_SCOPE:-designsystem}" = feed ]; then
    printf '%s\n' \
        'HACKERS_FEED_EXACT_COMPILE_OK sources=4 dependencies=untouched framework_wmo=foundation-hidden app=untouched' \
        | tee -a /out/result.txt
fi
