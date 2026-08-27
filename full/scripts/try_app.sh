set -uo pipefail
W=/w; UIKIT=/uikit; SYS=$W/scratch/sysroot_full; OUT=$W/build/app; MC=$W/scratch/modcache_app
mkdir -p "$OUT" "$MC"
SWIFTC=(swiftc -target arm64-apple-macos13.0 -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -wmo
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module
        -Xcc -I"$W/build/full/inc/CPortableIO" -Xcc -I"$W/build/full/inc/CSTBTrueType"
        -Xcc -I"$UIKIT/Sources/CQuartz/include" -I "$W/build/full")
echo "=== STEP 1: the UIKit shim (@_exported import Foundation + OpenUIKit) ==="
"${SWIFTC[@]}" -module-name UIKit -emit-object -emit-module \
    -emit-module-path "$OUT/UIKit.swiftmodule" -o "$OUT/uikitshim.o" \
    "$UIKIT"/Sources/UIKitShim/*.swift 2>&1 | head -12
