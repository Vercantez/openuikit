# guest_arch.inc -- Darwin guest triple for foundation-macho on this host.
# Sourced, not executed.
#
# Distinct from machorun/scripts/guest_arch.inc (macos11) and
# full/scripts/guest_arch.inc (macos15 for everything). This tree LINKS at
# macos13.0 and COMPILES FoundationEssentials consumers at macos15.0. Do not
# unify those numbers. Callers may export TRIPLE / COMPILE_TRIPLE to override.
if [ -z "${TRIPLE:-}" ]; then
    case "$(uname -m)" in
        x86_64)        TRIPLE=x86_64-apple-macos13.0 ;;
        aarch64|arm64) TRIPLE=arm64-apple-macos13.0 ;;
        *) echo "foundation-macho guest_arch: unsupported host $(uname -m)" >&2; exit 1 ;;
    esac
fi
if [ -z "${COMPILE_TRIPLE:-}" ]; then
    case "$(uname -m)" in
        x86_64)        COMPILE_TRIPLE=x86_64-apple-macos15.0 ;;
        aarch64|arm64) COMPILE_TRIPLE=arm64-apple-macos15.0 ;;
        *) echo "foundation-macho guest_arch: unsupported host $(uname -m)" >&2; exit 1 ;;
    esac
fi
case "$TRIPLE" in
    x86_64-*)          ARCH=x86_64; LD64_ARCH=x86_64 ;;
    arm64-*|aarch64-*) ARCH=arm64;  LD64_ARCH=arm64 ;;
    *) echo "foundation-macho guest_arch: cannot derive arch from TRIPLE=$TRIPLE" >&2; exit 1 ;;
esac
