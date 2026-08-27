#!/bin/bash
# One-shot box setup for the _Concurrency build. Run ON the box.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
W=$HOME/work
mkdir -p "$W"

echo "=== apt ==="
# --no-install-recommends: a stale index 404 on a *recommended* package
# (libheif-plugin-aomenc) failed the whole transaction last time.
sudo -E apt-get update -y >/dev/null
sudo -E apt-get install -y --no-install-recommends \
  build-essential cmake ninja-build git rsync python3 python3-dev \
  clang-18 lld-18 llvm-18 llvm-18-dev libclang-18-dev libc++-18-dev libc++abi-18-dev \
  libicu-dev libcurl4-openssl-dev libxml2-dev uuid-dev pkg-config zlib1g-dev \
  libedit-dev libncurses-dev binutils >/dev/null
echo "apt ok"

echo "=== swift 6.2.4 toolchain ==="
if [ ! -x /opt/swift624/usr/bin/swiftc ]; then
  cd "$W"
  URL=https://download.swift.org/swift-6.2.4-release/ubuntu2404-aarch64/swift-6.2.4-RELEASE/swift-6.2.4-RELEASE-ubuntu24.04-aarch64.tar.gz
  curl -fsSL "$URL" -o swift.tar.gz
  sudo mkdir -p /opt/swift624
  sudo tar xzf swift.tar.gz -C /opt/swift624 --strip-components=1
  rm -f swift.tar.gz
fi
/opt/swift624/usr/bin/swiftc --version

echo "=== swift source (6.2.4) ==="
[ -d "$W/swift" ] || git clone --depth 1 --branch swift-6.2.4-RELEASE \
  https://github.com/swiftlang/swift.git "$W/swift" 2>&1 | tail -1

echo "=== corelibs-foundation (CoreFoundation headers for the sysroot) ==="
[ -d "$W/scf" ] || git clone --depth 1 --branch swift-6.2.4-RELEASE \
  https://github.com/swiftlang/swift-corelibs-foundation.git "$W/scf" 2>&1 | tail -1

echo "bootstrap complete"

echo "=== swift-corelibs-libdispatch (the Linux-ported tree, NOT apple-oss-distributions) ==="
# apple-oss-distributions/libdispatch needs DISPATCH_USE_KEVENT_WORKQUEUE + HAVE_MACH.
# corelibs has the completed Linux port with event_epoll.c in the SAME tree,
# selected by configuration -- so this is a config choice, not a fork.
[ -d "$W/libdispatch" ] || git clone --depth 1 --branch swift-6.2.4-RELEASE \
  https://github.com/swiftlang/swift-corelibs-libdispatch.git "$W/libdispatch" 2>&1 | tail -1
echo "libdispatch: $(cd $W/libdispatch && git log --oneline -1)"
