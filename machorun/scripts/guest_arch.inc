# guest_arch.inc -- Darwin guest triple for this host. Sourced, not executed.
#
# DARWIN_TARGET may be set by the caller. Otherwise it follows uname -m so an
# x86_64 Linux host builds x86_64-apple-macos guests and an aarch64 host keeps
# building arm64-apple-macos. LD64_ARCH is the ld64 -arch flag; TBD_TARGET is
# the tapi "arm64-macos" / "x86_64-macos" token gen_tbd.sh emits.
if [ -z "${DARWIN_TARGET:-}" ]; then
    case "$(uname -m)" in
        x86_64)        DARWIN_TARGET=x86_64-apple-macos11 ;;
        aarch64|arm64) DARWIN_TARGET=arm64-apple-macos11 ;;
        *) echo "guest_arch: unsupported host $(uname -m)" >&2; exit 1 ;;
    esac
fi
case "$DARWIN_TARGET" in
    x86_64-*)          LD64_ARCH=x86_64; TBD_TARGET=x86_64-macos ;;
    arm64-*|aarch64-*) LD64_ARCH=arm64;  TBD_TARGET=arm64-macos  ;;
    *) echo "guest_arch: cannot derive -arch from DARWIN_TARGET=$DARWIN_TARGET" >&2; exit 1 ;;
esac
# Prefer the pinned LLVM 18 Darwin-capable clang. Swift's bundled clang 17
# refuses macOS linking via its lld; distro clang-18 + ld64.lld-18 is the
# combination every Darwin Mach-O build in this tree is measured against.
if [ -z "${DARWIN_CLANG:-}" ]; then
    if command -v clang-18 >/dev/null 2>&1; then DARWIN_CLANG=clang-18
    else DARWIN_CLANG=clang
    fi
fi
if [ -z "${LD64:-}" ]; then
    if command -v ld64.lld-18 >/dev/null 2>&1; then LD64=ld64.lld-18
    elif command -v ld64.lld >/dev/null 2>&1; then LD64=ld64.lld
    fi
fi
