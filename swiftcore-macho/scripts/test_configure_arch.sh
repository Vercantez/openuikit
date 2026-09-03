#!/bin/bash
# DRY retarget: the arm64 configure path is the x86_64 path with a variable.
# A rewrite would drop the aarch64/arm64 flags; this test requires both.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cfg=$SCRIPT_DIR/configure.sh
fail=0

dump() {
  local arch=$1 host=$2 triple=$3
  SWIFTCORE_DARWIN_ARCH=$arch SWIFT_HOST_VARIANT_ARCH=$host SWIFT_HOST_TRIPLE=$triple \
    W=/tmp/swiftcore-print SRC=/tmp/swiftcore-print/swift B=/tmp/swiftcore-print/build \
    bash "$cfg" --print-flags
}

arm=$(dump arm64 aarch64 aarch64-unknown-linux-gnu)
x86=$(dump x86_64 x86_64 x86_64-unknown-linux-gnu)

echo "=== arm64 dump (recorded Graviton path) ==="
echo "$arm"
echo "=== x86_64 dump (this VM) ==="
echo "$x86"

need() {
  local hay=$1 needle=$2 label=$3
  printf '%s\n' "$hay" | grep -F -- "$needle" >/dev/null && echo "  OK  $label" \
    || { echo "  FAIL $label  missing $needle"; fail=1; }
}

need "$arm" "SWIFTCORE_DARWIN_ARCH=arm64" "arm64 darwin arch"
need "$arm" "SWIFT_HOST_VARIANT_ARCH=aarch64" "arm64 host arch"
need "$arm" "SWIFT_HOST_TRIPLE=aarch64-unknown-linux-gnu" "arm64 host triple"
need "$arm" "-DSWIFT_SDK_OSX_ARCHITECTURES=arm64" "arm64 SDK arch"
need "$arm" "-DSWIFT_PRIMARY_VARIANT_ARCH=arm64" "arm64 primary"
need "$arm" "SWIFTCORE_NINJA_CORE=swiftCore-macosx-arm64" "arm64 ninja target"

need "$x86" "SWIFTCORE_DARWIN_ARCH=x86_64" "x86 darwin arch"
need "$x86" "SWIFT_HOST_VARIANT_ARCH=x86_64" "x86 host arch"
need "$x86" "SWIFT_HOST_TRIPLE=x86_64-unknown-linux-gnu" "x86 host triple"
need "$x86" "-DSWIFT_SDK_OSX_ARCHITECTURES=x86_64" "x86 SDK arch"
need "$x86" "-DSWIFT_PRIMARY_VARIANT_ARCH=x86_64" "x86 primary"
need "$x86" "SWIFTCORE_NINJA_CORE=swiftCore-macosx-x86_64" "x86 ninja target"

# Shared flags must appear in BOTH dumps (the retarget is a diff, not a rewrite).
for flag in \
  "-DSWIFT_INCLUDE_TOOLS=OFF" \
  "-DSWIFT_BUILD_STDLIB=ON" \
  "-DSWIFT_STDLIB_ENABLE_OBJC_INTEROP=ON" \
  "-DSWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY=ON" \
  "-DSWIFT_INCLUDE_APINOTES=ON" \
  "-DSWIFT_SDKS=OSX"
do
  need "$arm" "$flag" "arm64 has $flag"
  need "$x86" "$flag" "x86 has $flag"
done

# Cross-contamination: arm64 dump must not set x86_64 SDK arch, and vice versa.
printf '%s\n' "$arm" | grep -F -- "-DSWIFT_SDK_OSX_ARCHITECTURES=x86_64" >/dev/null \
  && { echo "  FAIL arm64 dump carries x86_64 SDK arch"; fail=1; } \
  || echo "  OK  arm64 dump has no x86_64 SDK arch"
printf '%s\n' "$x86" | grep -F -- "-DSWIFT_SDK_OSX_ARCHITECTURES=arm64" >/dev/null \
  && { echo "  FAIL x86 dump carries arm64 SDK arch"; fail=1; } \
  || echo "  OK  x86 dump has no arm64 SDK arch"

# SWIFT_TOOLCHAIN / PATH, not only /opt/swift624 and /usr/bin.
tcroot=$(mktemp -d)
mkdir -p "$tcroot/usr/bin"
printf '#!/bin/sh\nexit 0\n' > "$tcroot/usr/bin/swiftc"
chmod +x "$tcroot/usr/bin/swiftc"
toolchain_dump=$(
  SWIFTCORE_DARWIN_ARCH=x86_64 SWIFT_HOST_VARIANT_ARCH=x86_64 \
    SWIFT_HOST_TRIPLE=x86_64-unknown-linux-gnu \
    SWIFT_TOOLCHAIN="$tcroot" \
    W=/tmp/swiftcore-print SRC=/tmp/swiftcore-print/swift B=/tmp/swiftcore-print/build \
    bash "$cfg" --print-flags
)
need "$toolchain_dump" "TC=$tcroot/usr" "SWIFT_TOOLCHAIN selects TC"
rm -rf "$tcroot"

pathroot=$(mktemp -d)
mkdir -p "$pathroot/bin"
printf '#!/bin/sh\nexit 0\n' > "$pathroot/bin/swiftc"
chmod +x "$pathroot/bin/swiftc"
path_dump=$(
  PATH="$pathroot/bin:/bin:/usr/bin" \
    SWIFTCORE_DARWIN_ARCH=x86_64 SWIFT_HOST_VARIANT_ARCH=x86_64 \
    SWIFT_HOST_TRIPLE=x86_64-unknown-linux-gnu \
    SWIFT_TOOLCHAIN= TC= \
    W=/tmp/swiftcore-print SRC=/tmp/swiftcore-print/swift B=/tmp/swiftcore-print/build \
    bash "$cfg" --print-flags
)
need "$path_dump" "TC=$pathroot" "command -v swiftc selects TC"
rm -rf "$pathroot"

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- 2 dumps, arm64 path intact, x86_64 is the same argv with arch swapped"
  exit 0
fi
echo "FAIL"
exit 1
