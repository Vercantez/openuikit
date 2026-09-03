# guest_arch.inc -- Swift/UI guest triple for this host. Sourced, not executed.
#
# Distinct from machorun/scripts/guest_arch.inc (macos11): FoundationEssentials
# modules declare a macOS 15 minimum, and the full/swiftui gates compile at
# macos15.0. Do not unify the two numbers.
#
# Arm64 keeps the historical output paths (build/full, scratch/mrroot_full,
# build/swiftui-guest) so existing trees are not renamed. x86_64 writes
# BESIDE them: build/full-x86_64, scratch/mrroot_full-x86_64,
# build/swiftui-guest-x86_64. Never overwrite an arm64 package with an x86
# one, and never weaken an arm64 hash gate to make an x86 run pass.
if [ -z "${TARGET:-}" ]; then
    case "$(uname -m)" in
        x86_64)        TARGET=x86_64-apple-macos15.0 ;;
        aarch64|arm64) TARGET=arm64-apple-macos15.0 ;;
        *) echo "guest_arch: unsupported host $(uname -m)" >&2; exit 1 ;;
    esac
fi
case "$TARGET" in
    x86_64-*)          ARCH=x86_64; FULL_OUT_SUFFIX=-x86_64 ;;
    arm64-*|aarch64-*) ARCH=arm64;  FULL_OUT_SUFFIX= ;;
    *) echo "guest_arch: cannot derive arch from TARGET=$TARGET" >&2; exit 1 ;;
esac
# ld64 -arch flag matches ARCH. clang -target is TARGET.
LD64_ARCH="$ARCH"
# Swift emits module files as ${ARCH}-apple-macos.swiftmodule (no OS version).
SWIFT_MODULE_TRIPLE="${ARCH}-apple-macos"
# llvm-otool-18 -hv CPU column: ARM64 or X86_64.
case "$ARCH" in
    x86_64) OTOOL_CPU=X86_64 ;;
    arm64)  OTOOL_CPU=ARM64 ;;
esac
# Compile sysroot lives beside the arm64 tree on x86 (scratch/sysroot_fe4-x86_64).
# Arm64 keeps the historical unsuffixed path. Never overwrite one with the other.
SYSROOT_SUFFIX=$FULL_OUT_SUFFIX
# Durable OpenCombine export/ is arm64. x86 cold-builds land in export-x86_64/.
OPENCOMBINE_EXPORT_SUFFIX=$FULL_OUT_SUFFIX
# Child processes (widget env-prepare / scripts/env/prepare.py) must inherit
# the suffix; otherwise they resolve unsuffixed arm64 trees on an x86 host.
export FULL_OUT_SUFFIX
export TARGET ARCH SYSROOT_SUFFIX OPENCOMBINE_EXPORT_SUFFIX
export LD64_ARCH SWIFT_MODULE_TRIPLE OTOOL_CPU

require_macho_cpu() {
    local f=$1 label=${2:-$1}
    llvm-otool-18 -hv "$f" 2>/dev/null \
        | grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}" \
        || { echo "guest_arch: $label is not ${OTOOL_CPU} Mach-O: $f" >&2; return 1; }
}
