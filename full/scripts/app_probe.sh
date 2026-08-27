set -uo pipefail
W=/w; UIKIT=/uikit; SYS=$W/scratch/sysroot_full; OUT=$W/build/app; MC=$W/scratch/modcache_app
mkdir -p "$OUT" "$MC"
SWIFTC=(swiftc -target arm64-apple-macos13.0 -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -wmo
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module
        -Xcc -I"$W/build/full/inc/CPortableIO" -Xcc -I"$W/build/full/inc/CSTBTrueType"
        -Xcc -I"$UIKIT/Sources/CQuartz/include" -I "$W/build/full")

echo "=== the UIKit shim, WITHOUT the Foundation re-export ==="
"${SWIFTC[@]}" -module-name UIKit -emit-module -emit-module-path "$OUT/UIKit.swiftmodule" \
    -emit-object -o "$OUT/uikitshim.o" "$W/full/appshim/UIKit.swift" 2>&1 | grep -E "error" | head -5
echo "   (silence above = the shim itself builds)"

echo
echo "=== RealAppProbe: vendored UNMODIFIED app source + harness ==="
"${SWIFTC[@]}" -I "$OUT" -default-isolation MainActor -module-name RealAppProbe \
    -emit-module -emit-module-path "$OUT/RealAppProbe.swiftmodule" \
    -emit-object -o "$OUT/realappprobe.o" \
    "$UIKIT"/Sources/RealAppProbe/*.swift "$UIKIT"/Sources/RealAppProbe/Vendored/*.swift 2>&1 \
  | grep -E "^/.*error:" | sed 's|/uikit/Sources/RealAppProbe/||' > "$OUT/errs.txt"
echo "   total errors: $(wc -l < "$OUT/errs.txt")"
echo
echo "=== distinct missing names ==="
grep -oE "cannot find '[^']*'|cannot find type '[^']*'|no such module '[^']*'|has no member '[^']*'" "$OUT/errs.txt" \
  | sed "s/.*'\(.*\)'/\1/" | sort | uniq -c | sort -rn | head -40
echo
echo "=== first 12 errors verbatim, in file order ==="
head -12 "$OUT/errs.txt"
