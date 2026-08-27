#!/bin/bash
# Configure swift-corelibs-libdispatch for a Darwin (Mach-O, arm64) target on a
# Linux host, forcing the epoll backend and no Mach.
#
# THE TRAP: -target arm64-apple-macos defines __APPLE__, and our sysroot carries
# mach/mach.h (machorun staged it for objc4). CMake's
#   check_include_files("mach/mach.h" HAVE_MACH)
# would therefore turn Mach ON and drag in exactly the machinery we are avoiding.
# Every HAVE_* below is pre-seeded so the check is SKIPPED rather than run — a
# configure-time override, not a patch.
set -euo pipefail
W=${W:-$HOME/work}
SDK=$W/sdk/MacOSX.sdk
TC=${TC:-/opt/swift624/usr}
SRC=$W/libdispatch
B=${B:-$W/build-dispatch}

TARGET_FLAGS="-target arm64-apple-macos13.0 -isysroot $SDK -fblocks"
# -fcf-runtime-abi=objc: the CF census hit ld64.lld rejecting __DATA,__cfstring
# with "symbol l__unnamed_cfstring_.N at misaligned offset" under the default
# swift ABI. Not an undefined symbol -- a record-layout error, invisible until
# link. objc is the correct ABI for our mode.
TARGET_FLAGS="$TARGET_FLAGS -fcf-runtime-abi=objc"
# The backend is a PREPROCESSOR define consumed by src/event/event_config.h
# (see scripts/dispatch_patches.py #1), not a CMake variable — passing it with
# -D on the cmake line silently does nothing but warn.
TARGET_FLAGS="$TARGET_FLAGS -DDISPATCH_EVENT_BACKEND_EPOLL=1"
# HAVE_OBJC arrives DEFINED-BUT-EMPTY, so `#if !defined(USE_OBJC) && HAVE_OBJC`
# (src/internal.h:76) becomes `#if ... &&` -> "expected value in expression",
# which cascaded into 89 errors across 33 TUs. Give it a value.
# (HAVE_OBJC and friends now come from config_ac.h -- see below. Passing them as
# -D collides with the generated config under -Werror.)
# os/voucher_activity_private.h includes <firehose/tracepoint_private.h> --
# Apple's firehose tracing, which has no open-source counterpart -- guarded by
# OS_VOUCHER_ACTIVITY_SPI and __has_include(<mach/mach_time.h>). Our sysroot
# HAS mach/mach_time.h (machorun staged it for objc4), so the guard passes and
# the include fails. Turning the SPI off is what the Linux build does.
TARGET_FLAGS="$TARGET_FLAGS -DOS_VOUCHER_ACTIVITY_SPI=0 -DOS_FIREHOSE_SPI=0"
# src/internal.h prefers <config/config_ac.h> when it exists, over the CHECKED-IN
# config/config.h -- which is a DARWIN config (HAVE_MACH 1, HAVE_OBJC 1,
# HAVE_PTHREAD_WORKQUEUES 1). Without this, Mach arrives from the source tree
# with no configure step involved. Upstream's own escape hatch; zero patches.
TARGET_FLAGS="$TARGET_FLAGS -I$W/dispatch-config-inc"

rm -rf "$B"; mkdir -p "$B"; cd "$B"

cmake -G Ninja "$SRC" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="$TC/bin/clang" \
  -DCMAKE_CXX_COMPILER="$TC/bin/clang++" \
  -DCMAKE_C_FLAGS="$TARGET_FLAGS" \
  -DCMAKE_CXX_FLAGS="$TARGET_FLAGS" \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  `# Ninja refuses to relink for install RPATH on a non-ELF platform` \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
  -DCMAKE_SKIP_RPATH=ON \
  \
  `# ---- force epoll, forbid Mach ----` \
  -DHAVE_MACH=0 \
  -DHAVE_MACH_ABSOLUTE_TIME=0 \
  -DHAVE_MACH_APPROXIMATE_TIME=0 \
  -DHAVE_MACH_PORT_CONSTRUCT=0 \
  -DDISPATCH_USE_KEVENT_WORKQUEUE=0 \
  -DHAVE_PTHREAD_WORKQUEUES=0 \
  -DHAVE_PTHREAD_WORKQUEUE_QOS=0 \
  -DHAVE_PTHREAD_WORKQUEUE_SETDISPATCH_NP=0 \
  \
  `# ---- no swift overlay, no tests: the C library is what CF and _Concurrency need ----` \
  -DENABLE_SWIFT=OFF \
  `# BUILD_TESTING is CTest's variable and the one libdispatch honours.` \
  `# ENABLE_TESTING is silently IGNORED -- it only appears in CMake's` \
  `# "manually-specified variables were not used" warning, and the test suite` \
  `# gets configured anyway. tests/dispatch_io_muxed.c then wants socket(),` \
  `# bind(), listen() and drags in a BSD sockets ABI the LIBRARY never needs.` \
  -DBUILD_TESTING=OFF \
  -DENABLE_TESTING=OFF \
  -DBUILD_SHARED_LIBS=YES \
  "$@" 2>&1 | tee "$W/configure-dispatch.log"

# CORRECTION to an earlier assumption: internal.h prefers <config/config_ac.h>,
# but CMake GENERATES a file of exactly that name into the build directory, and
# -I<build-dir> precedes any -I we add. So supplying our own alongside does not
# override it -- it is shadowed, and CMake's `#cmakedefine HAVE_OBJC` (valueless)
# still wins, which is the 89-errors-across-33-TUs bug.
#
# It must REPLACE the generated one. Doing it post-configure, where it cannot be
# silently reordered away.
if [ -f "$W/dispatch-config/config_ac.h" ]; then
  cp "$W/dispatch-config/config_ac.h" "$B/config/config_ac.h"
  echo "installed our config_ac.h over CMake's generated one"
fi

echo "configure exit: ${PIPESTATUS[0]}"
