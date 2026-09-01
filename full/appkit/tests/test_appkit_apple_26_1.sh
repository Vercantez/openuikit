#!/usr/bin/env bash
set -euo pipefail

W=${W:-$(cd "$(dirname "$0")/../../.." && pwd)}
SDK=$(xcrun --sdk macosx --show-sdk-path)
OUT=$(mktemp -d /private/tmp/appkit-apple-oracle-20260901.XXXXXX)
cleanup() {
    case "$OUT" in
        /private/tmp/appkit-apple-oracle-20260901.*) rm -rf "$OUT" ;;
        *) printf 'refusing unexpected cleanup path: %s\n' "$OUT" >&2; exit 3 ;;
    esac
}
trap cleanup EXIT

test "$(basename "$SDK")" = MacOSX26.1.sdk
framework=$SDK/System/Library/Frameworks/AppKit.framework/Versions/C
printf '%s  %s\n' \
    85c3ad5bfb717f0aeff9d99c52512bb020a8176a66b629c318320b26cdd6683e \
    "$framework/AppKit.tbd" \
    5c2dc8fef80f61f45ef54e8ae8a62a7fc31481d890919c87bae4045cd3effb85 \
    "$framework/Headers/NSApplication.h" \
    d36a32ad8f863776e6b68ef103f1c433ef7eb57311dcd17b1871f1befdae4031 \
    "$framework/Headers/NSAlert.h" \
    be46224f91d11b7d0e25a0ed80dda5c1a9e52c404038a5a7ebfc25794befff30 \
    "$framework/Headers/NSWorkspace.h" \
    b9168401a1e5c1ba85043bdd58b3b3baf6fee1f4b9fad2900edf4c61bdafdb29 \
    "$framework/Headers/NSFont.h" \
    4d065ead315e0c1bb1036e7f86d9c526c0fdd287834364afca6ee7e9e59f2cf5 \
    "$framework/Headers/NSFontManager.h" \
    50c5682f672e4056ab154c22e67ff87a88d5d75dbb821fad0cff39b1f000677f \
    "$framework/Headers/NSWindow.h" \
    aa251b227dddb07036380fea06c70da233ca09c44a256c2d01db80fdbd7ccca1 \
    "$framework/Headers/NSColor.h" \
    | shasum -a 256 -c -

xcrun swiftc -target arm64-apple-macos15.0 \
    "$W/full/appkit/tests/AppKitInterfaceOracle.swift" \
    -o "$OUT/AppKitInterfaceOracle"
"$OUT/AppKitInterfaceOracle" > "$OUT/apple.txt"
cmp "$W/full/appkit/tests/appkit-interface-apple-xcode-26.1.txt" \
    "$OUT/apple.txt"
printf 'APPKIT_APPLE_ORACLE_OK rows=10 sdk=macosx26.1 identity=Versions/C\n'
