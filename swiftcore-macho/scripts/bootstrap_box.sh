#!/bin/bash
# One-shot box setup for the Darwin-stdlib cross-build. Run ON the box.
# Host arch selects the swift.org tarball; the source pin is the commit, not
# the tag label.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"

export DEBIAN_FRONTEND=noninteractive
W=${W:-$HOME/work}
mkdir -p "$W"

echo "=== apt ==="
# --no-install-recommends: a stale index 404 on a *recommended* package
# (libheif-plugin-aomenc) failed the whole transaction last time.
sudo -E apt-get update -y >/dev/null
sudo -E apt-get install -y --no-install-recommends \
  build-essential cmake ninja-build git rsync python3 python3-dev \
  clang-18 lld-18 llvm-18 llvm-18-dev libclang-18-dev libc++-18-dev libc++abi-18-dev \
  libicu-dev libcurl4-openssl-dev libxml2-dev uuid-dev pkg-config zlib1g-dev \
  libedit-dev libncurses-dev binutils file >/dev/null
echo "apt ok"

echo "=== swift 6.2.4 toolchain ==="
if [ ! -x "${TC}/bin/swiftc" ]; then
  cd "$W"
  case "$(uname -m)" in
    x86_64)
      URL=https://download.swift.org/swift-6.2.4-release/ubuntu2404/swift-6.2.4-RELEASE/swift-6.2.4-RELEASE-ubuntu24.04.tar.gz
      ;;
    aarch64|arm64)
      URL=https://download.swift.org/swift-6.2.4-release/ubuntu2404-aarch64/swift-6.2.4-RELEASE/swift-6.2.4-RELEASE-ubuntu24.04-aarch64.tar.gz
      ;;
    *) echo "bootstrap: no swift.org tarball for $(uname -m)" >&2; exit 1 ;;
  esac
  curl -fsSL "$URL" -o swift.tar.gz
  sudo mkdir -p /opt/swift624
  sudo tar xzf swift.tar.gz -C /opt/swift624 --strip-components=1
  rm -f swift.tar.gz
  TC=/opt/swift624/usr
fi
"${TC}/bin/swiftc" --version

clone_tag() {
  local dest=$1 url=$2 pin_commit=${3:-}
  if [ -d "$dest/.git" ]; then
    echo "  reused $dest @$(git -C "$dest" rev-parse HEAD)"
    if [ -n "$pin_commit" ]; then
      local have
      have=$(git -C "$dest" rev-parse HEAD)
      if [ "$have" != "$pin_commit" ]; then
        echo "bootstrap: $dest is $have, want $pin_commit — refusing to reuse" >&2
        exit 2
      fi
    fi
    return 0
  fi
  git clone --depth 1 --branch "$SWIFT_PIN_TAG" "$url" "$dest"
  local got
  got=$(git -C "$dest" rev-parse HEAD)
  if [ -n "$pin_commit" ] && [ "$got" != "$pin_commit" ]; then
    echo "bootstrap: $dest HEAD $got != pin $pin_commit" >&2
    echo "  tag $SWIFT_PIN_TAG moved or the pin is wrong. Do not continue." >&2
    exit 2
  fi
  echo "  cloned $dest @$got"
}

echo "=== swift source (pin $SWIFT_PIN_COMMIT tag $SWIFT_PIN_TAG) ==="
clone_tag "$W/swift" https://github.com/swiftlang/swift.git "$SWIFT_PIN_COMMIT"

echo "=== corelibs-foundation (CoreFoundation headers for the sysroot) ==="
clone_tag "$W/scf" https://github.com/swiftlang/swift-corelibs-foundation.git

echo "=== swift-corelibs-libdispatch (pin $LIBDISPATCH_PIN_COMMIT tag $SWIFT_PIN_TAG) ==="
# apple-oss-distributions/libdispatch needs DISPATCH_USE_KEVENT_WORKQUEUE + HAVE_MACH.
# corelibs has the completed Linux port with event_epoll.c in the SAME tree,
# selected by configuration -- so this is a config choice, not a fork.
# Always pin-fetch: SWIFTCORE_OVERLAYS=1 / SWIFTCORE_BUILD_DISPATCH=1 pass this
# path into CMake. A missing tree must fail in configure.sh *before* cmake,
# not 40 lines into a CMake diagnostic.
clone_tag "$W/libdispatch" "$LIBDISPATCH_REPO" "$LIBDISPATCH_PIN_COMMIT"

if [ "${SWIFTCORE_OVERLAYS:-0}" = 1 ]; then
  echo "=== swift-experimental-string-processing (pin $STRING_PROCESSING_PIN_COMMIT tag $SWIFT_PIN_TAG) ==="
  clone_tag "$W/swift-experimental-string-processing" \
    "$STRING_PROCESSING_REPO" "$STRING_PROCESSING_PIN_COMMIT"
fi

mkdir -p "$W/shims"
echo "bootstrap complete host=$(uname -m) darwin_arch=$SWIFTCORE_DARWIN_ARCH tc=$TC"
