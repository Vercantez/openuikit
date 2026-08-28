#!/bin/bash
# Stage the build inputs out of the sibling repos and start the build container.
#
#   scripts/container.sh up      # stage + create the container
#   scripts/container.sh sh      # shell into it
#   scripts/container.sh down    # remove it
#
# Run on the macOS host. The sibling repos are read-only inputs and are copied,
# never mounted: Docker cannot mount from some of these paths, and this scope is
# explicitly forbidden from writing to them.
#
# Only ever touches the container named below, by exact name — the user runs
# unrelated containers.
set -euo pipefail
cd "$(dirname "$0")/.."
REPO=$PWD
NAME=fm-build
IMAGE=${IMAGE:-swift-macho-spike:noble}   # swift 6.2.4 + llvm-18/ld64.lld, arm64
SCRATCH=${SCRATCH:-${TMPDIR:-/tmp}/foundation-macho}
STAGE=$SCRATCH/stage
WORK=$SCRATCH/work

MACHORUN=${MACHORUN:-$HOME/machorun}
SWIFTCORE=${SWIFTCORE:-$HOME/swiftcore-macho}
SCF=${SCF:-$SCRATCH/src/scf}

stage() {
  rm -rf "$STAGE"; mkdir -p "$STAGE" "$WORK"

  # swift-corelibs-foundation, for Apple's open-source CoreFoundation headers.
  if [ ! -d "$SCF" ]; then
    mkdir -p "$(dirname "$SCF")"
    git clone --depth 1 --branch release/6.2 \
      https://github.com/swiftlang/swift-corelibs-foundation.git "$SCF"
  fi

  cp -a "$MACHORUN/sdk"                     "$STAGE/machorun-sdk"
  cp -a "$MACHORUN/vendor/objc4-priv"       "$STAGE/objc4-priv"
  mkdir -p "$STAGE/objc4-runtime"
  cp -a "$MACHORUN/vendor/objc4/runtime/"*.h "$STAGE/objc4-runtime/"
  mkdir -p "$STAGE/darwinlib"
  cp -a "$MACHORUN/darwin/usr/lib/"*.dylib  "$STAGE/darwinlib/"
  cp -a "$MACHORUN/build/machorun"          "$STAGE/machorun-bin"

  mkdir -p "$STAGE/swiftcore"
  cp -a "$SWIFTCORE/artifacts/swift-macosx" "$STAGE/swiftcore/"
  cp -a "$SWIFTCORE/artifacts/libswiftcompat.dylib" "$STAGE/darwinlib/"
  cp -a "$SWIFTCORE/sdk/libc"               "$STAGE/libc"
  cp -a "$SWIFTCORE/sdk/foundation"         "$STAGE/foundation"

  mkdir -p "$STAGE/scf/Sources/CoreFoundation"
  cp -a "$SCF/Sources/CoreFoundation/include" "$STAGE/scf/Sources/CoreFoundation/"

  echo "staged into $STAGE ($(du -sh "$STAGE" | cut -f1))"
}

case "${1:-up}" in
  up)
    stage
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    docker run -d --name "$NAME" \
      -v "$STAGE:/stage:ro" -v "$WORK:/work" -v "$REPO:/repo" \
      -w /work "$IMAGE" sleep infinity >/dev/null
    docker exec "$NAME" bash -lc 'bash /repo/scripts/stage_sdk.sh'
    echo
    echo "next:  docker exec $NAME bash -lc 'bash /repo/scripts/build_slice.sh &&"
    echo "                                    bash /repo/scripts/build_overlay.sh &&"
    echo "                                    bash /repo/scripts/run_tests.sh'"
    ;;
  sh)   exec docker exec -it "$NAME" bash ;;
  down) docker rm -f "$NAME" >/dev/null 2>&1 && echo "removed $NAME" ;;

  # ---------------------------------------------------------------------
  # restage / check -- /stage IS A SNAPSHOT, AND A SNAPSHOT IS A STALENESS
  # INJECTOR UNLESS SOMETHING STANDS AFTER IT.
  #
  # $STAGE is a read-only copy of the sibling repos, taken once at `up`. It
  # exists for a real reason (Docker cannot mount some of those paths, and this
  # scope must not write to them), so it is not going away. But `stage_sdk.sh`
  # copies $STAGE -> $WORK on EVERY run, and nothing checked whether that was a
  # downgrade.
  #
  # MEASURED 2026-08-28, mid-investigation: machorun was rebuilt with #80's
  # mutex fix, the new libSystem was staged into $WORK by hand, and a later
  # stage_sdk.sh silently restored the PRE-#80 dylib AND its matching .tbd.
  # They were then consistent with each other and stale against the tree --
  # which passes any check comparing the two artefacts to each other -- and the
  # restore gave the old file a FRESH mtime, so timestamps agreed with the lie
  # too. A test that had passed started failing again with no source change.
  #
  # `restage` refreshes the snapshot from the siblings as they are NOW.
  # `check` answers the question that matters before any measurement:
  #     "will the next stage_sdk.sh run change what I am testing?"
  # Neither guesses which copy is newer -- mtimes are unreliable across a
  # restore. They compare CONTENT and name every file that differs.
  restage|check)
    [ -d "$STAGE" ] || { echo "no snapshot at $STAGE; run '$0 up' first" >&2; exit 2; }
    if [ "$1" = restage ]; then
      # IN PLACE, AND NEVER `stage`. `stage()` begins with `rm -rf "$STAGE"`,
      # and $STAGE is a LIVE BIND-MOUNT SOURCE. Deleting it does not fail and
      # does not warn -- it DETACHES the mount: the container goes on seeing
      # the deleted inode, so /stage reads as an EMPTY DIRECTORY and every copy
      # out of it silently copies nothing. Measured 2026-08-28 by doing exactly
      # that: `stage_sdk.sh` then died on "/stage/machorun-sdk/usr: No such
      # file or directory" while the host directory was complete, and only
      # recreating the container restored it.
      #
      # So this refreshes the artefacts over the existing tree. `cp -a src/. dst/`
      # rather than `cp -a src dst`, because the latter NESTS when dst exists.
      echo "== refreshing the snapshot in place (never rm -rf: it is a live mount)"
      mkdir -p "$STAGE/machorun-sdk" "$STAGE/darwinlib"
      cp -a "$MACHORUN/sdk/." "$STAGE/machorun-sdk/"
      cp -a "$MACHORUN/darwin/usr/lib/"*.dylib "$STAGE/darwinlib/"
      cp -a "$MACHORUN/build/machorun" "$STAGE/machorun-bin"
      echo "   refreshed: machorun-sdk, darwinlib, machorun-bin"
      # A refresh that SUBTRACTS is the hazard on the other side, so say what
      # the snapshot now holds rather than assuming the copy added only.
      for d in machorun-sdk/usr/lib darwinlib; do
        printf '   %-24s %s files\n' "$d" \
          "$(find "$STAGE/$d" -type f 2>/dev/null | wc -l | tr -d ' ')"
      done
    fi
    echo "== files $WORK holds that differ from the snapshot"
    echo "   (stage_sdk.sh will REPLACE each of these on its next run)"
    differ=0
    for rel in darwinlib/libSystem.B.dylib darwinlib/libobjc.A.dylib \
               darwinlib/libdispatch.dylib darwinlib/libquartz.dylib \
               machorun-bin; do
      s="$STAGE/$rel"
      case "$rel" in
        machorun-bin) w="$WORK/mrun" ;;
        *)            w="$WORK/root/darwin/usr/lib/$(basename "$rel")" ;;
      esac
      [ -f "$s" ] && [ -f "$w" ] || continue
      if ! cmp -s "$s" "$w"; then
        printf '   DIFFERS  %-28s snapshot %8s B   work %8s B\n' \
          "$(basename "$rel")" "$(wc -c < "$s")" "$(wc -c < "$w")"
        differ=$((differ + 1))
      fi
    done
    if [ "$differ" -eq 0 ]; then
      echo "   none -- the snapshot and the work tree agree"
    else
      echo
      echo "   $differ file(s) differ. If the WORK copy is the one you built,"
      echo "   run '$0 restage' so the snapshot stops reverting it; if the"
      echo "   SNAPSHOT is right, re-run stage_sdk.sh in the container."
      echo "   Either way, do not measure until they agree -- a run against a"
      echo "   mixture is not a measurement of either."
    fi
    [ "$differ" -eq 0 ] || exit 1
    ;;

  *)    echo "usage: container.sh up|sh|down|restage|check" >&2; exit 2 ;;
esac
