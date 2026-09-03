#!/usr/bin/env bash
# Compile OpenCombine for x86_64-apple-macos BESIDE the arm64 durable tree.
# Never writes scratch/opencombine-core-durable-*/export/ (arm64 SHA pins).
# Output: $OPENCOMBINE_ROOT/export-x86_64/{artifacts,RESULT.txt}
#
# Source hashes from full/oracle-opencombine/policy.json still apply.
# Object SHAs do not: those pin the arm64 .o.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.inc
. "$HERE/common.inc"

W=${W:?set W to the openuikit tree}
# shellcheck disable=SC1091
. "$W/full/scripts/guest_arch.inc"
[ "$ARCH" = x86_64 ] || {
    echo "build_opencombine_x86: host/guest arch is $ARCH, not x86_64" >&2
    exit 2
}

OPENCOMBINE_ROOT=${OPENCOMBINE_ROOT:-$W/scratch/opencombine-core-durable-20260828-r2}
SRC=$OPENCOMBINE_ROOT/source
OUT=$OPENCOMBINE_ROOT/export-x86_64
SYS=${SYS:-$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}}
POLICY=$W/full/oracle-opencombine/policy.json
PATCH=$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch
HELPER_REL=Sources/COpenCombineHelpers/COpenCombineHelpers.cpp
HELPER_INCLUDE=$SRC/Sources/COpenCombineHelpers/include

[ -d "$SRC/Sources/OpenCombine" ] || {
    echo "CANNOT_X86_OPENCOMBINE reason=no OpenCombine source at $SRC" >&2
    exit 2
}
[ -d "$SYS/usr/include" ] || {
    echo "CANNOT_X86_OPENCOMBINE reason=no x86 sysroot at $SYS" >&2
    exit 2
}
[ -f "$SYS/usr/lib/swift/libswiftCore.dylib" ] && phase2_is_x86_macho "$SYS/usr/lib/swift/libswiftCore.dylib" || {
    echo "CANNOT_X86_OPENCOMBINE reason=no x86_64 libswiftCore in $SYS (arm64 dylib is not a substitute)" >&2
    exit 2
}
[ -f "$SYS/usr/lib/swift/Swift.swiftmodule/x86_64-apple-macos.swiftmodule" ] \
    || [ -f "$SYS/usr/lib/swift/Swift.swiftmodule/x86_64-apple-macos.swiftinterface" ] || {
    echo "CANNOT_X86_OPENCOMBINE reason=no x86_64-apple-macos Swift.swiftmodule slice in $SYS" >&2
    exit 2
}

sha() { sha256sum "$1" | awk '{print $1}'; }

# Source pins from policy.json (not object pins).
HELPER_SHA=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["compiler_inputs"]["files"]["Sources/COpenCombineHelpers/COpenCombineHelpers.cpp"])' "$POLICY")
PATCH_SHA=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["assets"]["patches/COpenCombineHelpers-pthread-recursive.patch"])' "$POLICY")
PATCHED_SHA=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["helper_patch"]["patched_sha256"])' "$POLICY")
CORE_COUNT=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["core_sources"]["swift_file_count"])' "$POLICY")

[ "$(sha "$SRC/$HELPER_REL")" = "$HELPER_SHA" ] || {
    echo "CANNOT_X86_OPENCOMBINE reason=COpenCombineHelpers.cpp drifted from policy pin" >&2
    exit 2
}
[ "$(sha "$PATCH")" = "$PATCH_SHA" ] || {
    echo "CANNOT_X86_OPENCOMBINE reason=helper patch drifted from policy pin" >&2
    exit 2
}

rm -rf "$OUT"
mkdir -p "$OUT/artifacts" "$OUT/work"
cp "$SRC/$HELPER_REL" "$OUT/work/COpenCombineHelpers.cpp"
patch --batch --forward --fuzz=0 "$OUT/work/COpenCombineHelpers.cpp" "$PATCH" >/dev/null
[ "$(sha "$OUT/work/COpenCombineHelpers.cpp")" = "$PATCHED_SHA" ] || {
    echo "CANNOT_X86_OPENCOMBINE reason=patched helper SHA drifted" >&2
    exit 2
}

clang++-18 -target "$TARGET" -isysroot "$SYS" -stdlib=libc++ -std=c++17 -O2 \
    -I "$HELPER_INCLUDE" \
    -c "$OUT/work/COpenCombineHelpers.cpp" \
    -o "$OUT/artifacts/COpenCombineHelpers.o"

mapfile -d '' CORE_SOURCES < <(find "$SRC/Sources/OpenCombine" -name '*.swift' -print0 | sort -z)
[ "${#CORE_SOURCES[@]}" -eq "$CORE_COUNT" ] || {
    echo "CANNOT_X86_OPENCOMBINE reason=OpenCombine source count ${#CORE_SOURCES[@]} != policy $CORE_COUNT" >&2
    exit 2
}

COMMON_SWIFT=(
    -parse-as-library -O -wmo
    -target "$TARGET" -sdk "$SYS"
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xcc -fmodule-map-file="$HELPER_INCLUDE/module.modulemap"
    -Xcc -I"$HELPER_INCLUDE"
    -module-name OpenCombine
    -module-cache-path "$OUT/work/modcache"
)
swiftc -emit-module -emit-module-path "$OUT/artifacts/OpenCombine.swiftmodule" \
    -emit-object -o "$OUT/artifacts/OpenCombine.o" \
    "${COMMON_SWIFT[@]}" "${CORE_SOURCES[@]}"

phase2_is_x86_macho "$OUT/artifacts/OpenCombine.o" || {
    echo "CANNOT_X86_OPENCOMBINE reason=OpenCombine.o is not X86_64 Mach-O" >&2
    file "$OUT/artifacts/OpenCombine.o" >&2
    exit 2
}

{
    echo "x86_64 OpenCombine cold-build"
    echo "target $TARGET"
    echo "object $(sha "$OUT/artifacts/OpenCombine.o")"
    echo "module $(sha "$OUT/artifacts/OpenCombine.swiftmodule")"
    echo "arm64 durable object SHA still stands in export/artifacts (untouched)"
} > "$OUT/RESULT.txt"

echo "PASS: x86 OpenCombine at $OUT/artifacts (arm64 export/ untouched)"
