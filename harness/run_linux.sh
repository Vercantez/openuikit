#!/bin/sh
# run_linux.sh -- compile and run one corpus test against OUR libobjc, in Docker.
#
# The port does not exist yet. Until it does, this script reports SKIPPED (exit
# 3) rather than failing, so scripts/difftest.sh stays runnable from day one and
# the skip count is itself a progress metric.
#
# Usage: harness/run_linux.sh tests/010-category-basic.m
# Exit: 0 ran, 1 compile failed, 2 ran but crashed/non-zero, 3 skipped.
#
# Contract with whoever owns the build system -- run_linux.sh needs exactly two
# things and does not care how they are produced:
#
#   OBJC4_LINUX_LIBDIR   directory containing libobjc.so   (default: see below)
#   OBJC4_LINUX_INCLUDE  directory containing objc/*.h     (default: see below)
#
# Both are paths on the HOST; the repo is bind-mounted at /src in the container
# and the paths are rewritten. Other knobs:
#
#   OBJC4_DOCKER_IMAGE   default objc4-linux-build:24.04 (docker/Dockerfile).
#                        It is the build container, reused: our libobjc.so needs
#                        libBlocksRuntime.so.0 at run time and that image is the
#                        one that has it. swift:6.2-noble does not.
#   OBJC4_LINUX_TARGET   default aarch64-unknown-linux-gnu
#   OBJC4_SKIP_LINUX=1   force SKIPPED without touching Docker

set -u

REPO=$(cd "$(dirname "$0")/.." && pwd)
TEST=${1:?usage: run_linux.sh <test.m>}
case "$TEST" in /*) ;; *) TEST="$REPO/$TEST" ;; esac
NAME=$(basename "$TEST" .m)

skip() { echo "run_linux.sh: SKIPPED $NAME: $1" >&2; exit 3; }

[ "${OBJC4_SKIP_LINUX:-0}" = "1" ] && skip "OBJC4_SKIP_LINUX=1"

# --- locate our runtime ------------------------------------------------------
LIBDIR=${OBJC4_LINUX_LIBDIR:-}
if [ -z "$LIBDIR" ]; then
    for cand in "$REPO/build/linux" "$REPO/build/linux-aarch64" "$REPO/build" "$REPO/out"; do
        if [ -f "$cand/libobjc.so" ] || [ -f "$cand/libobjc.A.so" ]; then LIBDIR=$cand; break; fi
    done
fi
[ -n "$LIBDIR" ] || skip "no libobjc.so found (set OBJC4_LINUX_LIBDIR)"
[ -f "$LIBDIR/libobjc.so" ] || [ -f "$LIBDIR/libobjc.A.so" ] || \
    skip "no libobjc.so in $LIBDIR"

INCLUDE=${OBJC4_LINUX_INCLUDE:-}
if [ -z "$INCLUDE" ]; then
    for cand in "$LIBDIR/include" "$REPO/build/include" "$REPO/include"; do
        if [ -d "$cand/objc" ]; then INCLUDE=$cand; break; fi
    done
fi
[ -n "$INCLUDE" ] || skip "no objc/ headers found (set OBJC4_LINUX_INCLUDE)"

command -v docker >/dev/null 2>&1 || skip "docker not installed"
docker info >/dev/null 2>&1 || skip "docker daemon not reachable"

IMAGE=${OBJC4_DOCKER_IMAGE:-objc4-linux-build:24.04}
TARGET=${OBJC4_LINUX_TARGET:-aarch64-unknown-linux-gnu}

# Rewrite host paths into container paths. Anything outside the repo is mounted
# separately, read-only.
in_repo() { case "$1" in "$REPO"/*|"$REPO") return 0 ;; *) return 1 ;; esac; }
MOUNTS="-v $REPO:/src"
if in_repo "$LIBDIR"; then C_LIBDIR="/src${LIBDIR#$REPO}";
else C_LIBDIR="/mnt/lib"; MOUNTS="$MOUNTS -v $LIBDIR:/mnt/lib:ro"; fi
if in_repo "$INCLUDE"; then C_INCLUDE="/src${INCLUDE#$REPO}";
else C_INCLUDE="/mnt/include"; MOUNTS="$MOUNTS -v $INCLUDE:/mnt/include:ro"; fi

OUT=$REPO/build/linux-tests
mkdir -p "$OUT"

# -fobjc-runtime=macosx-10.15 is the flag that makes clang emit APPLE-ABI class
# metadata and objc_classlist sections on ELF. Without it clang emits the
# GNUstep ABI and none of this corpus means anything.
#
# -fsigned-char pins plain `char` to Darwin's signedness. AArch64 Linux has
# unsigned char (clang predefines __CHAR_UNSIGNED__=1), which flips
# @encode(char) from "c" to "C" in every type string. That is a compiler ABI
# difference, not a runtime one; pinning it on BOTH sides keeps the diff
# measuring the runtime. docs/ABI_DIVERGENCE.md records the unpinned values.
#
# The rest mirrors run_macos.sh exactly, including -O0, so the only difference
# between the two sides of the diff is the runtime.
# A marker file, not an exit code, distinguishes "compile failed" from "the test
# program itself exited non-zero" -- the test's own exit status must pass
# through untouched.
rm -f "$OUT/$NAME.ccfail"

docker run --rm $MOUNTS -w /src \
    -e "C_LIBDIR=$C_LIBDIR" -e "C_INCLUDE=$C_INCLUDE" \
    -e "NAME=$NAME" -e "TARGET=$TARGET" \
    -e "RELTEST=${TEST#$REPO/}" \
    "$IMAGE" /bin/sh -c '
        set -u
        O=/src/build/linux-tests
        mkdir -p "$O"
        CF="-target $TARGET -O0 -g0 -fsigned-char
            -fobjc-runtime=macosx-10.15 -fno-objc-arc -fobjc-exceptions
            -Wno-objc-root-class -Wno-unused-function -Wno-deprecated-declarations
            -I/src/tests -I$C_INCLUDE"

        # Companion image: tests/<name>.lib.m becomes a shared library the test
        # links against. See the same block in run_macos.sh.
        EXTRA=""
        if [ -f "/src/tests/$NAME.lib.m" ]; then
            if ! clang $CF -fPIC -shared "/src/tests/$NAME.lib.m" \
                    -o "$O/lib$NAME.so" \
                    -L"$C_LIBDIR" -lobjc -Wl,-rpath,"$C_LIBDIR" \
                    2> "$O/$NAME.cc.log"
            then
                : > "$O/$NAME.ccfail"
                exit 1
            fi
            EXTRA="-L$O -l$NAME -Wl,-rpath,$O"
        fi

        if ! clang $CF "/src/$RELTEST" -o "$O/$NAME" \
            $EXTRA -L"$C_LIBDIR" -lobjc -ldl -lpthread \
            -Wl,-rpath,"$C_LIBDIR" \
            2> "$O/$NAME.cc.log"
        then
            : > "$O/$NAME.ccfail"
            exit 1
        fi
        exec "$O/$NAME"
    '
rc=$?

if [ -f "$OUT/$NAME.ccfail" ]; then
    echo "run_linux.sh: compile failed for $NAME" >&2
    [ -f "$OUT/$NAME.cc.log" ] && cat "$OUT/$NAME.cc.log" >&2
    exit 1
fi

case $rc in
    0)   exit 0 ;;
    125|126|127) skip "docker could not run the container (image $IMAGE missing?)" ;;
    *)   echo "run_linux.sh: $NAME exited $rc" >&2
         exit 2 ;;
esac
