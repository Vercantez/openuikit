#!/usr/bin/env bash
# Codex Cloud environment setup for the OpenUIKit Linux platform repository.
# Mirrors .cursor/Dockerfile (Swift 6.2 / Ubuntu 24.04 lab) on top of Codex's
# universal image, then runs the same static-evidence install and the same
# verification the Cursor environment ran. Paste ONE line into the Codex
# environment's "Setup script" field:
#
#     bash .codex/setup.sh
#
# The setup phase has network access; the agent phase does not need it.
set -euo pipefail

SWIFT_VERSION=${SWIFT_VERSION:-6.2.4}
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    binutils build-essential ca-certificates clang-18 cmake curl file \
    fonts-dejavu-core git git-lfs imagemagick jq libc++-18-dev \
    libcurl4-openssl-dev libdigest-sha-perl libedit-dev libfontconfig1-dev \
    libfreetype6-dev libicu-dev libncurses-dev libpng-dev libsdl2-dev \
    libsqlite3-dev libxml2-dev libz3-dev lld-18 llvm-18 ninja-build patchelf \
    patch perl pkg-config python3 python3-pip python3-venv ripgrep rsync \
    shellcheck sqlite3 sudo unzip xxd xvfb zip zlib1g-dev \
    libgcc-13-dev libstdc++-13-dev libpython3-dev tzdata gnupg2
sudo rm -rf /var/lib/apt/lists/*

# Swift 6.2.4 (the verify script refuses any other version) in the standard
# usr/ layout at /opt/swift624 — the pinned EC2 prefix that
# full/dispatch/swift_linux_lib.inc resolves before looking at swiftc's
# directory. The universal image's own Swift 6.2.4 is a swiftly proxy under
# /root/.swiftly/bin with no lib/swift/linux beside it, and the third Codex
# smoke task failed the built-products stage with
# "CANNOT_X86_HOST_RUNTIME MISSING=libdispatch.so,libBlocksRuntime.so,…".
SWIFT_PREFIX=/opt/swift624
if ! "$SWIFT_PREFIX/usr/bin/swiftc" --version 2>/dev/null | grep -q "Swift version ${SWIFT_VERSION}"; then
    arch=$(uname -m)
    case "$arch" in
        aarch64) suffix="-aarch64" ;;
        x86_64)  suffix="" ;;
        *) echo "unsupported arch $arch" >&2; exit 1 ;;
    esac
    url="https://download.swift.org/swift-${SWIFT_VERSION}-release/ubuntu2404${suffix}/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04${suffix}.tar.gz"
    echo "installing Swift ${SWIFT_VERSION} from ${url} into ${SWIFT_PREFIX}"
    curl -fsSL "$url" -o /tmp/swift.tar.gz
    sudo rm -rf "$SWIFT_PREFIX"
    sudo mkdir -p "$SWIFT_PREFIX"
    sudo tar -xzf /tmp/swift.tar.gz -C "$SWIFT_PREFIX" --strip-components=1
    rm -f /tmp/swift.tar.gz
fi
[ -f "$SWIFT_PREFIX/usr/lib/swift/linux/libdispatch.so" ] \
    || { echo "codex-setup: $SWIFT_PREFIX has no usr/lib/swift/linux/libdispatch.so" >&2; exit 1; }
export PATH=$SWIFT_PREFIX/usr/bin:$PATH SWIFT_TOOLCHAIN=$SWIFT_PREFIX

# The unversioned LLVM names must resolve to the pinned Ubuntu LLVM 18 binaries.
sudo ln -sfn /usr/bin/ld64.lld-18 /usr/bin/ld64.lld
for llvm_tool in llvm-nm llvm-otool llvm-objdump; do
    sudo ln -sfn "/usr/bin/${llvm_tool}-18" "/usr/bin/${llvm_tool}"
done
[ -x /usr/bin/llvm-readtapi-18 ] && sudo ln -sfn /usr/bin/llvm-readtapi-18 /usr/bin/llvm-readtapi || true
sudo git lfs install --system

# The universal image ships Swift 6.2.4 with its own ld64.lld (LLD 17) and
# llvm-* binaries in the toolchain's bin directory, which precedes /usr/bin on
# PATH. The lab pins Ubuntu's LLVM 18 (verify refuses anything else: the first
# Codex smoke task failed with "llvm-nm does not resolve to llvm-nm-18"), so a
# small bin directory of LLVM 18 links goes FIRST on PATH for setup and for
# every later shell.
sudo mkdir -p /opt/openuikit-llvm18/bin
for tool in ld64.lld llvm-nm llvm-otool llvm-objdump llvm-readtapi; do
    [ -x "/usr/bin/${tool}-18" ] && sudo ln -sfn "/usr/bin/${tool}-18" "/opt/openuikit-llvm18/bin/${tool}"
done
export PATH=/opt/openuikit-llvm18/bin:$PATH
export LANG=C.UTF-8 LC_ALL=C.UTF-8 OPENUIKIT_MACIOS_ROOT=/opt/openuikit-evidence/dotnet-macios
profile_line="export PATH=/opt/openuikit-llvm18/bin:$SWIFT_PREFIX/usr/bin:\$PATH SWIFT_TOOLCHAIN=$SWIFT_PREFIX LANG=C.UTF-8 LC_ALL=C.UTF-8 OPENUIKIT_MACIOS_ROOT=/opt/openuikit-evidence/dotnet-macios"
echo "$profile_line" | sudo tee /etc/profile.d/openuikit.sh >/dev/null
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
    grep -q openuikit-llvm18 "$rc" 2>/dev/null || echo "$profile_line" >> "$rc"
done

echo "swiftc: $(command -v swiftc)"
swiftc --version
echo "ld64.lld: $(command -v ld64.lld) -> $(readlink -f "$(command -v ld64.lld)")"
ld64.lld --version | head -1
# Exactly what the Cursor environment's "install" hook runs (.cursor/environment.json
# → .cursor/install.sh): static evidence, the pinned scratch corpus (the second
# Codex smoke task failed the verify gate with "missing corpus checkout:
# scratch/ladder-corpus/focus-ios"), the built products, then the verify gate.
bash .cursor/install.sh
echo "CODEX_SWIFT_ENVIRONMENT_OK swift=${SWIFT_VERSION} target=linux products=clean"
