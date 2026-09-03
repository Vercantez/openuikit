# ud_dispatch_run.inc -- optional Linux Dispatch host bridge + Darwin runtime
# image for run_ud_guest.sh / run_ud_persist.sh. Sourced, not executed.
#
# Same mechanism as full/xcodeplan/build_and_run_reminder_scene_guest.sh
# (`== build Linux Dispatch host bridge`, LD_PRELOAD of libOpenDispatchHost.so)
# and the Focus onboarding run-local overlay (PR #42/#47): do not mutate the
# named mrroot; clone it to $W/runroot; stage the Darwin facade at
# darwin/usr/lib/libOpenDispatch.dylib (LC_ID /usr/lib/libOpenDispatch.dylib).
#
# WHY THAT PATH, NOT /usr/lib/system/libdispatch.dylib AND NOT a libSystem.B
# re-export. libCFTest is linked -lSystem -undefined dynamic_lookup
# (build_cftest_harness.sh); libSystem.B does not re-export libdispatch
# (machorun/darwin/src/libsystem.c looks libdispatch_init up by name). The
# undefined _dispatch_* names therefore become BIND_SPECIAL_DYLIB_FLAT_LOOKUP
# binds. machorun/src/resolve.c searches every loaded image, then — because
# libCFTest's install name /usr/lib/libCFTest.dylib is an absolute Darwin path
# served from the prefix map — from->is_runtime is set (image.c) and
# host_lookup strips the underscore and dlsym(RTLD_DEFAULT)s the Linux
# libdispatch pulled in by LD_PRELOAD of the host bridge. The Darwin image
# itself is is_runtime so its _glibc_openui_dispatch_host_v1_* binds (the
# OpenDispatchBridge.c facade) resolve the same way. libSystem.B's concpatch
# already imports that _glibc_* ABI; it does not need a re-export.
#
# Variable names match the Reminder/Focus scripts:
#   DISPATCH_HOST     path to libOpenDispatchHost.so
#                     (OPENUI_DISPATCH_HOST is accepted as an alias)
#   DISPATCH_DARWIN   path to the Darwin libOpenDispatch.dylib to stage
#   DISPATCH_RUNROOT  optional overlay path (default $W/runroot)
#
# When DISPATCH_HOST is unset, this file is a no-op: MACHORUN_ROOT stays the
# named ROOT and there is no LD_PRELOAD. That is the #87 container path.

if [ -n "${UD_DISPATCH_RUN_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
UD_DISPATCH_RUN_INC=1

ud_dispatch_host_path() {
    if [ -n "${DISPATCH_HOST:-}" ]; then
        printf '%s\n' "$DISPATCH_HOST"
    elif [ -n "${OPENUI_DISPATCH_HOST:-}" ]; then
        printf '%s\n' "$OPENUI_DISPATCH_HOST"
    fi
}

# Print the == binary line with the loader path and sha256 of the file
# that is about to be exec'd. Callers must set MRUN.
ud_dispatch_loader_line() {
    local bin=$1
    local sha
    sha=$(sha256sum "$MRUN" 2>/dev/null | awk '{print $1}')
    echo "== binary $bin  loader=$MRUN sha256=${sha:-unreadable}"
}

# Sets UD_MACHORUN_ROOT, UD_DISPATCH_PRELOAD, UD_DISPATCH_LIBPATH.
# Prints == runroot when an overlay is staged.
ud_dispatch_prepare_root() {
    local host darwin runroot hostdir dest already=0
    UD_MACHORUN_ROOT=$ROOT
    UD_DISPATCH_PRELOAD=
    UD_DISPATCH_LIBPATH=

    host=$(ud_dispatch_host_path)
    [ -n "$host" ] || return 0

    darwin=${DISPATCH_DARWIN:-}
    if [ ! -f "$host" ] || [ -L "$host" ]; then
        echo "REFUSING: DISPATCH_HOST is not a regular file: ${host:-empty}" >&2
        return 2
    fi
    if [ -z "$darwin" ] || [ ! -f "$darwin" ] || [ -L "$darwin" ]; then
        echo "REFUSING: DISPATCH_DARWIN is not a regular file: ${darwin:-empty}" >&2
        return 2
    fi

    runroot=${DISPATCH_RUNROOT:-$W/runroot}
    if [ "$runroot" = "$ROOT" ]; then
        echo "REFUSING: run-local overlay path collided with the named root $ROOT" >&2
        return 2
    fi

    echo "== clone named root into a writable run-local overlay"
    # machorun's host_lookup/_glibc_ path only runs for images served from
    # the darwin-root prefix map (is_runtime). Do not write the shared
    # mrroot; stage the facade in a per-run copy (Focus onboarding / PR #42).
    if [ -f "$runroot/darwin/usr/lib/libSystem.B.dylib" ] \
        || [ -f "$runroot/darwin/System/Library/Frameworks/Foundation.framework/Foundation" ]
    then
        already=1
    fi
    if [ "$already" -eq 0 ]; then
        rm -rf "$runroot"
        mkdir -p "$runroot"
        cp -a "$ROOT/." "$runroot/"
        chmod -R u+w "$runroot" 2>/dev/null || true
    fi

    dest=$runroot/darwin/usr/lib/libOpenDispatch.dylib
    mkdir -p "$(dirname "$dest")"
    if [ ! -f "$dest" ] || ! cmp -s "$darwin" "$dest"; then
        cp -f "$darwin" "$dest"
    fi
    echo "== runroot $runroot"
    echo "== dispatch-host $host"
    echo "== dispatch-runtime $dest"

    UD_MACHORUN_ROOT=$runroot
    hostdir=$(cd "$(dirname "$host")" && pwd)
    UD_DISPATCH_PRELOAD="$host${LD_PRELOAD:+:$LD_PRELOAD}"
    UD_DISPATCH_LIBPATH="$hostdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
}

# Run $MRUN against UD_MACHORUN_ROOT, with LD_PRELOAD when a host bridge
# was prepared. Extra environment (UD_MODE=…) is inherited.
ud_dispatch_run() {
    if [ -n "${UD_DISPATCH_PRELOAD:-}" ]; then
        LD_PRELOAD="$UD_DISPATCH_PRELOAD" \
        LD_LIBRARY_PATH="$UD_DISPATCH_LIBPATH" \
        MACHORUN_ROOT="$UD_MACHORUN_ROOT" \
            "$MRUN" "$@"
    else
        MACHORUN_ROOT="$UD_MACHORUN_ROOT" \
            "$MRUN" "$@"
    fi
}
