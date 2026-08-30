set -uo pipefail
W=/w; UIKIT=/uikit; SYS=$W/scratch/sysroot_full; OUT=$W/build/app; MC=$W/scratch/modcache_app
mkdir -p "$OUT" "$MC"
SWIFTC=(swiftc -target arm64-apple-macos13.0 -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -wmo
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module
        -Xcc -I"$W/build/full/inc/CPortableIO" -Xcc -I"$W/build/full/inc/CSTBTrueType"
        -Xcc -I"$UIKIT/Sources/CQuartz/include" -I "$W/build/full")
echo "== UIKit shim before the app-facing Foundation module"
"${SWIFTC[@]}" -I "$OUT" -module-name UIKit -emit-module -emit-module-path "$OUT/UIKit.swiftmodule" \
    -emit-object -o "$OUT/uikitshim.o" "$W/full/appshim/UIKit.swift" 2>&1 | grep error | head -3
echo "== narrow app-facing Foundation identities"
"${SWIFTC[@]}" -I "$OUT" -module-name Foundation \
    -emit-module -emit-module-path "$OUT/Foundation.swiftmodule" \
    -emit-object -o "$OUT/foundation.o" \
    "$W/full/appshim/Foundation.swift" \
    "$W/full/appshim/FoundationOpenUIKitAliases.swift" 2>&1 | grep error | head -3
echo "== RealAppProbe (vendored app source, UNMODIFIED)"
"${SWIFTC[@]}" -I "$OUT" -default-isolation MainActor -module-name RealAppProbe \
    -emit-module -emit-module-path "$OUT/RealAppProbe.swiftmodule" \
    -emit-object -o "$OUT/realappprobe.o" \
    "$UIKIT"/Sources/RealAppProbe/*.swift "$UIKIT"/Sources/RealAppProbe/Vendored/*.swift 2>&1 \
  | grep -E "error:" | sed 's|/uikit/Sources/RealAppProbe/||' > "$OUT/errs2.txt"
n=$(wc -l < "$OUT/errs2.txt")
echo "   errors: $n"
if [ "$n" != "0" ]; then
  echo "   distinct missing names:"
  grep -oE "cannot find '[^']*'|cannot find type '[^']*'|has no member '[^']*'|no such module '[^']*'" "$OUT/errs2.txt" \
    | sed "s/.*'\(.*\)'/\1/" | sort | uniq -c | sort -rn | head -30
  echo "   first 10 verbatim:"; head -10 "$OUT/errs2.txt"
fi
