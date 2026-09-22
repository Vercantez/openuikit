#!/usr/bin/env bash
# Local full Mach-O guest verify on an Apple Silicon Mac, via an arm64 Linux
# container. Rebuilds whatever is stale for one tree (the main checkout or any
# git worktree of it) and runs uikit/scripts/linux_guest_realapp_verify.sh.
#
#   bash scripts/ops/local_guest_verify.sh [TREE]        # default: this checkout
#   LOCAL_GUEST_FORCE=1 ...                              # rebuild everything
#   LOCAL_GUEST_SKIP_VERIFY=1 ...                        # build only
#   LOCAL_GUEST_BUILD_FULL=/path/build_full.sh ...       # diagnostic: run another
#       copy of build_full (it must sit beside a guest_arch.inc); the guest
#       subject is still hashed from the tree's own full/scripts/build_full.sh
#
# Route (same producers as scripts/ops/arm64_verify.sh on the EC2 authority):
#   image     .cursor/Dockerfile (pinned swift:6.2-noble digest = Swift 6.2.4,
#             clang/lld/llvm-18) built for linux/arm64, tagged
#             openuikit-guest-env:arm64 and labelled with the Dockerfile sha
#   machorun  machorun/scripts/build.sh everything + stage_swiftcore.sh
#             (libswiftCore stashed / libswiftcompat removed first, as on the box)
#   base root copy of the shared scratch/mrroot (spike runtime) plus host/ built
#             from THIS tree: toolchain libdispatch/libBlocksRuntime (sha-pinned
#             by build_host_bridge.sh) and the four Open*Host.so helpers
#   sysroot   copy of the shared scratch/sysroot_fe4 with libSystem.tbd refreshed
#             from this tree's machorun/sdk (arm64_verify does the same cp)
#   build     full/scripts/build_full.sh
#   verify    uikit/scripts/linux_guest_realapp_verify.sh
#
# Read-only shared inputs come from the MAIN checkout's scratch/ (a worktree
# has none): swift-foundation, swift-collections, swift-foundation-icu,
# OpenCombine export, mrroot (spike runtime), mrroot_fe (FE overlays),
# sysroot_fe4. Per-tree outputs: machorun/build, machorun/darwin/usr,
# machorun/sdk/usr/lib/*.tbd, build/full, build/local-guest/. The main
# checkout keeps its conventional run root and module cache
# (scratch/mrroot_full, scratch/modcache_full) so the documented manual
# commands keep working; a worktree gets build/local-guest/{mrroot_full,modcache}.
set -euo pipefail

IMAGE=${LOCAL_GUEST_IMAGE:-openuikit-guest-env:arm64}

log() { printf '[local-guest] %s\n' "$*" >&2; }
die() { printf '[local-guest] FAIL: %s\n' "$*" >&2; exit 2; }
now() { date +%s; }

# ---------------------------------------------------------------- host side --
if [ "${1:-}" != --inside ]; then
    HERE=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
    TREE=${1:-$(CDPATH= cd -- "$HERE/../.." && pwd -P)}
    TREE=$(CDPATH= cd -- "$TREE" && pwd -P)
    TREE=$(git -C "$TREE" rev-parse --show-toplevel)
    COMMON=$(cd "$TREE" && cd "$(git rev-parse --git-common-dir)" && pwd -P)
    MAIN=$(dirname "$COMMON")
    [ -f "$TREE/full/scripts/build_full.sh" ] || die "$TREE is not an openuikit tree"
    [ -e "$MAIN/scratch" ] || die "no shared scratch/ in main checkout $MAIN"
    SCRATCH=$(CDPATH= cd -- "$MAIN/scratch" && pwd -P)
    command -v docker >/dev/null || die 'docker not on PATH'
    [ "$(uname -m)" = arm64 ] || log "warning: host is $(uname -m); the container is linux/arm64"

    dockerfile=$MAIN/.cursor/Dockerfile
    want_label=$(shasum -a 256 "$dockerfile" | cut -d' ' -f1)
    have_label=$(docker image inspect -f '{{index .Config.Labels "openuikit.dockerfile-sha256"}}' "$IMAGE" 2>/dev/null || true)
    if [ "$want_label" != "$have_label" ]; then
        log "building $IMAGE from $dockerfile (label ${have_label:-none} -> $want_label)"
        ctx=$(mktemp -d)
        docker build --platform linux/arm64 --label "openuikit.dockerfile-sha256=$want_label" \
            -t "$IMAGE" -f "$dockerfile" "$ctx"
        rmdir "$ctx"
    fi

    # Bind-mount at identical absolute paths so the scratch symlink, git
    # worktree gitdir pointers and every recorded path resolve unchanged.
    mounts=()
    for p in "$TREE" "$MAIN" "$SCRATCH" "$HERE"; do
        case "$p" in
            "$HOME"|"$HOME"/*) ;;
            *) mounts+=(-v "$p:$p") ;;
        esac
    done
    mounts+=(-v "$HOME:$HOME")
    tty=()
    [ -t 1 ] && tty=(-t)
    exec docker run --rm "${tty[@]}" --platform linux/arm64 "${mounts[@]}" \
        -w "$TREE" \
        -e GIT_CONFIG_COUNT=1 -e GIT_CONFIG_KEY_0=safe.directory -e GIT_CONFIG_VALUE_0='*' \
        -e LOCAL_GUEST_FORCE="${LOCAL_GUEST_FORCE:-0}" \
        -e LOCAL_GUEST_SKIP_VERIFY="${LOCAL_GUEST_SKIP_VERIFY:-0}" \
        -e LOCAL_GUEST_BUILD_FULL="${LOCAL_GUEST_BUILD_FULL:-}" \
        -e TREE="$TREE" -e MAIN="$MAIN" -e SCRATCH="$SCRATCH" \
        "$IMAGE" bash "$HERE/$(basename "${BASH_SOURCE[0]}")" --inside
fi

# ----------------------------------------------------------- container side --
[ "$(uname -s)" = Linux ] || die 'inside mode must run on Linux'
case "$(uname -m)" in aarch64|arm64) ;; *) die "container is $(uname -m), need aarch64" ;; esac
export HOME=${HOME:-/root}
export CC=${CC:-cc} DARWIN_CLANG=clang-18
cd "$TREE"
LG=$TREE/build/local-guest
mkdir -p "$LG" "$TREE/build/full"
LOCK=$LG/.lock
mkdir "$LOCK" 2>/dev/null || die "another local_guest_verify holds $LOCK (remove it if stale)"
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT
T0=$(now)
swiftc --version 2>&1 | head -1 | grep -q 'Swift version 6.2.4' || die 'toolchain is not Swift 6.2.4'

# Content key of paths in this tree: committed tree ids + working-tree edits +
# untracked non-ignored files. Clean trees hash to their git trees alone.
# Campaign state under full/framework-fanout, bytecode caches and this ops
# directory are not build inputs and churn independently.
TREE_KEY_EXCLUDES=(':(exclude)full/framework-fanout' ':(exclude,glob)**/__pycache__/**' ':(exclude)scripts/ops')
tree_key() {
    {
        for p in "$@"; do git rev-parse "HEAD:$p" 2>/dev/null || echo "none $p"; done
        git diff HEAD --binary -- "$@" "${TREE_KEY_EXCLUDES[@]}"
        git ls-files -o --exclude-standard -z -- "$@" "${TREE_KEY_EXCLUDES[@]}" | sort -z | xargs -0r sha256sum
    } | sha256sum | cut -d' ' -f1
}
key_ok() { [ "${LOCAL_GUEST_FORCE}" != 1 ] && [ -f "$1" ] && [ "$(cat "$1")" = "$2" ]; }

if [ "$TREE" = "$MAIN" ]; then
    ROOTDIR=$SCRATCH/mrroot_full
    MC=$SCRATCH/modcache_full
else
    ROOTDIR=$LG/mrroot_full
    MC=$LG/modcache
fi
BASE=$LG/mrroot-base
SYS=$LG/sysroot_fe4

# 1. machorun loader + darwin userland + tbd + libswiftCore/compat staging
t=$(now)
machorun_key=$( { tree_key machorun swiftcore-macho/artifacts; echo "$CC $DARWIN_CLANG"; } | sha256sum | cut -d' ' -f1)
if key_ok "$TREE/machorun/build/.local-guest.key" "$machorun_key" \
    && [ -x machorun/build/machorun ] && [ -f machorun/darwin/usr/lib/swift/libswiftCore.dylib ]; then
    log "machorun: reused key=${machorun_key:0:12}"
else
    log "machorun: build.sh everything + stage_swiftcore"
    rm -f machorun/build/.local-guest.key
    (
        cd machorun
        sc=darwin/usr/lib/swift/libswiftCore.dylib
        stash=$LG/libswiftCore.stash
        rm -f "$stash"
        [ -f "$sc" ] && mv "$sc" "$stash"
        rm -f darwin/usr/lib/libswiftcompat.dylib
        bash scripts/build.sh everything
        [ -f "$stash" ] && mkdir -p "$(dirname "$sc")" && mv "$stash" "$sc"
        bash scripts/stage_swiftcore.sh "$TREE/swiftcore-macho/artifacts"
    ) > "$LG/machorun.log" 2>&1 || { tail -40 "$LG/machorun.log" >&2; die "machorun build failed (log $LG/machorun.log)"; }
    echo "$machorun_key" > "$TREE/machorun/build/.local-guest.key"
fi
log "machorun: $(( $(now) - t ))s"

# 2. base runtime root: shared spike runtime + host/ built from this tree
t=$(now)
[ -d "$SCRATCH/mrroot/darwin/usr/lib/swift" ] || die "no shared spike runtime at $SCRATCH/mrroot"
base_key=$( {
    tree_key full/dispatch full/foundationinternationalization full/urltransport full/relativetime scripts/env
    find "$SCRATCH/mrroot/darwin" -type f -print0 | sort -z | xargs -0 sha256sum
    sha256sum /usr/lib/swift/linux/libdispatch.so /usr/lib/swift/linux/libBlocksRuntime.so
} | sha256sum | cut -d' ' -f1)
if key_ok "$BASE/.local-guest.key" "$base_key"; then
    log "base root: reused key=${base_key:0:12}"
else
    log "base root: staging $BASE"
    rm -rf "$BASE"
    mkdir -p "$BASE/host"
    cp -a "$SCRATCH/mrroot/darwin" "$BASE/darwin"
    cp -a "$SCRATCH/mrroot/machorun" "$BASE/machorun"
    {
        bash full/dispatch/build_host_bridge.sh --repo "$TREE" --host-dir "$BASE/host" \
            --work-dir "$LG/base-host-work" --host-abi ELF64-AArch64 --refuse-prefix 'local-guest: '
        for helper in foundationinternationalization urltransport relativetime; do
            bash "full/$helper/build_host_helper.sh" --repo "$TREE" --host-dir "$BASE/host"
        done
    } > "$LG/base-host.log" 2>&1 || { tail -30 "$LG/base-host.log" >&2; die "host runtime build failed"; }
    for f in libdispatch.so libBlocksRuntime.so libOpenDispatchHost.so \
        libOpenFoundationInternationalizationHost.so libOpenURLTransportHost.so libOpenRelativeTimeHost.so; do
        file -b "$BASE/host/$f" | grep -q 'ELF 64-bit LSB shared object, ARM aarch64' \
            || die "host runtime $f is not an aarch64 ELF shared object"
    done
    echo "$base_key" > "$BASE/.local-guest.key"
fi
log "base root: $(( $(now) - t ))s"

# 3. compile sysroot: shared sysroot_fe4 + this tree's libSystem.tbd
t=$(now)
[ -d "$SCRATCH/sysroot_fe4/usr/include" ] || die "no shared sysroot at $SCRATCH/sysroot_fe4"
sys_key=$( { find "$SCRATCH/sysroot_fe4" -type f -print0 | sort -z | xargs -0 sha256sum; sha256sum machorun/sdk/usr/lib/libSystem.tbd; } | sha256sum | cut -d' ' -f1)
if key_ok "$SYS/.local-guest.key" "$sys_key"; then
    log "sysroot: reused key=${sys_key:0:12}"
else
    log "sysroot: staging $SYS"
    rm -rf "$SYS"
    cp -a "$SCRATCH/sysroot_fe4" "$SYS"
    cp machorun/sdk/usr/lib/libSystem.tbd "$SYS/usr/lib/libSystem.tbd"
    echo "$sys_key" > "$SYS/.local-guest.key"
fi
log "sysroot: $(( $(now) - t ))s"

# 4. build_full
t=$(now)
export W=$TREE SYS ROOTDIR MC OUT=$TREE/build/full
export SF=$SCRATCH/swift-foundation SC=$SCRATCH/swift-collections
export SWIFT_FOUNDATION_ICU=$SCRATCH/swift-foundation-icu
export OPENCOMBINE_ROOT=$SCRATCH/opencombine-core-durable-20260828-r2
export BASE_RUNTIME_SOURCE=$BASE FE_RUNTIME_SOURCE=$SCRATCH/mrroot_fe
BUILD_FULL=${LOCAL_GUEST_BUILD_FULL:-$TREE/full/scripts/build_full.sh}
[ "$BUILD_FULL" = "$TREE/full/scripts/build_full.sh" ] || log "build_full: DIAGNOSTIC override $BUILD_FULL"
full_key=$( {
    echo "$machorun_key $base_key $sys_key $ROOTDIR $MC"
    sha256sum "$BUILD_FULL"
    tree_key full uikit scripts
} | sha256sum | cut -d' ' -f1)
if key_ok "$OUT/.local-guest.key" "$full_key" && [ -f "$OUT/render_full" ] \
    && [ -f "$OUT/focus-guest-executable.sha256" ]; then
    log "build_full: reused key=${full_key:0:12}"
else
    log "build_full: building (log $LG/build_full.log)"
    rm -f "$OUT/.local-guest.key"
    bash "$BUILD_FULL" > "$LG/build_full.log" 2>&1 \
        || { tail -60 "$LG/build_full.log" >&2; die "build_full failed (log $LG/build_full.log)"; }
    echo "$full_key" > "$OUT/.local-guest.key"
fi
log "build_full: $(( $(now) - t ))s"

# 5. guest real-app verification
if [ "$LOCAL_GUEST_SKIP_VERIFY" = 1 ]; then
    log "verify skipped; total $(( $(now) - T0 ))s"
    exit 0
fi
t=$(now)
export OPENUIKIT_REALAPP_GUEST_SUPPORT=$TREE OPENUIKIT_REALAPP_GUEST_BUILD=$OUT OPENUIKIT_REALAPP_GUEST_ROOT=$ROOTDIR
rc=0
bash uikit/scripts/linux_guest_realapp_verify.sh "$LG/verify" 2>&1 | tee "$LG/verify.log" || rc=$?
log "verify: $(( $(now) - t ))s rc=$rc; total $(( $(now) - T0 ))s; outputs $LG/verify"
exit "$rc"
