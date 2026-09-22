#!/usr/bin/env bash
# ios_guest.sh -- the Mach-O guest built for an iOS triple, run under machorun.
# docs/agent_reports/ios-target-route.md.
#
#   bash full/iostarget/ios_guest.sh [TREE]     # on the Mac host
#
# Host side: stages the iOS-simulator SDK variant the Linux toolchain needs
# (full/xcodeplan/stage_true_ios_full_sdk.sh over the local guest sysroot plus
# iPhoneSimulator26.1's stdlib interfaces and runtime .tbds), then re-enters
# itself in the openuikit-guest-env:arm64 container. Container side: runs
# full/scripts/build_full.sh with TARGET=arm64-apple-ios26.0-simulator
# (LC_BUILD_VERSION platform 7) into build/local-guest-ios, runs
# IOSTargetGuestProbe under machorun and diffs it against the iOS 26.1
# simulator transcript, then runs the same GuestBoundaryTests / LaunchProbe
# the macOS-triple guest verify runs.
#
# Needs a completed scripts/ops/local_guest_verify.sh for the same tree
# (machorun, base runtime root and sysroot under build/local-guest).
# Prints IOS_TARGET_GUEST_VERIFIED on success.
set -euo pipefail
IMAGE=${LOCAL_GUEST_IMAGE:-openuikit-guest-env:arm64}
IOS_TARGET=${IOS_TARGET:-arm64-apple-ios26.0-simulator}
IOS_MINOS=${IOS_MINOS:-26.0}
log() { printf '[ios-guest] %s\n' "$*" >&2; }
die() { printf '[ios-guest] FAIL: %s\n' "$*" >&2; exit 2; }

if [ "${1:-}" != --inside ]; then
    HERE=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
    TREE=${1:-$(CDPATH= cd -- "$HERE/../.." && pwd -P)}
    TREE=$(CDPATH= cd -- "$TREE" && pwd -P)
    COMMON=$(cd "$TREE" && cd "$(git rev-parse --git-common-dir)" && pwd -P)
    MAIN=$(dirname "$COMMON")
    SCRATCH=$(CDPATH= cd -- "$MAIN/scratch" && pwd -P)
    LG=$TREE/build/local-guest
    LGI=$TREE/build/local-guest-ios
    [ -f "$LG/sysroot_fe4/.local-guest.key" ] || die "run scripts/ops/local_guest_verify.sh $TREE first"
    SDK=${IOS_SDK:-$(xcrun --sdk iphonesimulator --show-sdk-path)}
    [ -d "$SDK/usr/lib/swift" ] || die "no iPhoneSimulator SDK at $SDK"
    mkdir -p "$LGI/core"
    ln -sfn ../../local-guest/sysroot_fe4 "$LGI/core/sdk"
    stage_key=$( { cat "$LG/sysroot_fe4/.local-guest.key"; echo "$SDK"; cat "$SDK/SDKSettings.json";
                   shasum -a 256 "$TREE/full/xcodeplan/stage_true_ios_full_sdk.sh"; } | shasum -a 256 | cut -d' ' -f1)
    if [ "$(cat "$LGI/true-ios-sdk/.stage-key" 2>/dev/null)" != "$stage_key" ]; then
        log "staging iOS-simulator SDK variant from $SDK"
        rm -rf "$LGI/true-ios-sdk"
        bash "$TREE/full/xcodeplan/stage_true_ios_full_sdk.sh" "$LGI/core" "$SDK" "$LGI/true-ios-sdk" >&2
        echo "$stage_key" > "$LGI/true-ios-sdk/.stage-key"
    fi
    mounts=(-v "$HOME:$HOME")
    for p in "$TREE" "$MAIN" "$SCRATCH"; do
        case "$p" in "$HOME"|"$HOME"/*) ;; *) mounts+=(-v "$p:$p") ;; esac
    done
    exec docker run --rm --platform linux/arm64 "${mounts[@]}" -w "$TREE" \
        -e TREE="$TREE" -e MAIN="$MAIN" -e SCRATCH="$SCRATCH" \
        -e IOS_TARGET="$IOS_TARGET" -e IOS_MINOS="$IOS_MINOS" \
        "$IMAGE" bash "$TREE/full/iostarget/ios_guest.sh" --inside
fi

# ----------------------------------------------------------- container side --
[ "$(uname -s)" = Linux ] || die 'inside mode must run on Linux'
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0='*'
export HOME=${HOME:-/root} CC=${CC:-cc} DARWIN_CLANG=clang-18
cd "$TREE"
LG=$TREE/build/local-guest
LGI=$TREE/build/local-guest-ios
export W=$TREE TARGET=$IOS_TARGET MINOS=$IOS_MINOS LINK_PLATFORM=ios-simulator LINK_SDK_VERSION=26.1
export SYS=$LGI/true-ios-sdk/sdk APPLE_SWIFT_USER_OVERLAYS=$LGI/true-ios-sdk/apple-overlays
export ROOTDIR=$LGI/mrroot_full MC=$LGI/modcache OUT=$LGI/full
export SF=$SCRATCH/swift-foundation SC=$SCRATCH/swift-collections
export SWIFT_FOUNDATION_ICU=$SCRATCH/swift-foundation-icu
export OPENCOMBINE_ROOT=$SCRATCH/opencombine-core-durable-20260828-r2
export BASE_RUNTIME_SOURCE=$LG/mrroot-base FE_RUNTIME_SOURCE=$SCRATCH/mrroot_fe
mkdir -p "$OUT" "$ROOTDIR" "$MC"
log "build_full for $TARGET (log $LGI/build_full.log)"
bash full/scripts/build_full.sh > "$LGI/build_full.log" 2>&1 \
    || { tail -40 "$LGI/build_full.log" >&2; die "build_full failed for $TARGET"; }

probe=$OUT/IOSTargetGuestProbe
llvm-otool-18 -l "$probe" | grep -A4 LC_BUILD_VERSION | tee "$LGI/probe-build-version.txt" >&2
grep -q 'platform 7' "$LGI/probe-build-version.txt" || die 'probe is not an iOS-simulator (platform 7) Mach-O'

export MACHORUN_ROOT=$ROOTDIR LD_LIBRARY_PATH=$OUT/host
export LD_PRELOAD="$OUT/host/libOpenDispatchHost.so:$OUT/host/libOpenFoundationInternationalizationHost.so:$OUT/host/libOpenURLTransportHost.so:$OUT/host/libOpenRelativeTimeHost.so"
export OPENUIKIT_RESOURCE_ROOT=$TREE/uikit/Sources/OpenUIKit/Resources
"$ROOTDIR/machorun" "$probe" > "$LGI/probe.txt" 2> "$LGI/probe.err" || { cat "$LGI/probe.err" >&2; die 'probe crashed under machorun'; }
cat "$LGI/probe.txt"
diff <(tail -n +2 "$TREE/full/iostarget/oracle-ios26.1.txt") <(tail -n +2 "$LGI/probe.txt") \
    || die 'probe transcript differs from the iOS 26.1 simulator'
echo "IOS_TARGET_PROBE_MATCHES_IOS_26_1 lines=$(wc -l < "$LGI/probe.txt")"
"$ROOTDIR/machorun" "$OUT/GuestBoundaryTests" > "$LGI/boundary.log" 2>&1 || true
grep -F 'FOCUS_GUEST_BOUNDARY_OK' "$LGI/boundary.log" || die 'GuestBoundaryTests failed on the iOS triple'
"$ROOTDIR/machorun" "$OUT/LaunchProbe" > "$LGI/launch.log" 2>&1 || true
grep -F 'FOCUS_REAL_APPDELEGATE_LAUNCHED' "$LGI/launch.log" || die 'LaunchProbe failed on the iOS triple'
echo "IOS_TARGET_GUEST_VERIFIED target=$TARGET"
