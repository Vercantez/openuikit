# ninja_checked.inc -- sourced. Run ninja and propagate its exit status.
#
# Every ninja invocation — core and overlays — must fail the caller on a
# non-zero status. The previous gold-wall allow (`-fuse-ld=gold` is an
# invalid linker name for Swift's clang) hid overlay compiles: every
# overlay target depends on libswiftCore.so. configure.sh now passes
# -DSWIFT_USE_LINKER=lld. PIPESTATUS[0] is ninja, not tee.

if [ -n "${SWIFTCORE_NINJA_CHECKED_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
SWIFTCORE_NINJA_CHECKED_INC=1

# ninja_checked <logfile> [ninja-args...]
# Honors NINJA (default: ninja). Returns ninja's status. Never swallows
# -fuse-ld=gold: that is a misconfigure, not an allowed wall.
ninja_checked() {
    if [ "${1:-}" = --allow-gold-wall ]; then
        echo "ninja_checked: --allow-gold-wall is retired; configure with -DSWIFT_USE_LINKER=lld" >&2
        shift
    fi
    local log=${1:?ninja_checked: logfile}
    shift
    local ninja_bin=${NINJA:-ninja}
    if [ ! -x "$ninja_bin" ] && ! command -v "$ninja_bin" >/dev/null 2>&1; then
        echo "ninja_checked: no ninja binary (NINJA=$ninja_bin)" >&2
        return 127
    fi
    mkdir -p "$(dirname "$log")"
    local chunk
    chunk=$(mktemp)
    # Save/restore errexit: this function must not `set -e` on the caller,
    # or an overlay loop that wants to continue after a failure cannot.
    local errexit_was_on=0
    case $- in *e*) errexit_was_on=1 ;; esac
    set +e
    "$ninja_bin" "$@" 2>&1 | tee -a "$log" | tee "$chunk"
    local st=${PIPESTATUS[0]}
    if [ "$errexit_was_on" = 1 ]; then set -e; fi
    echo "ninja $* exit=$st"
    if [ "$st" -eq 126 ]; then
        echo "ninja_checked: rc=126 means ninja could not execute a command (not a compile/link diagnostic). Check that CMAKE_CXX_COMPILER / the clang++ shim / python3 / ld.lld are +x ELF binaries." >&2
    fi
    if [ "$st" -eq 0 ]; then
        rm -f "$chunk"
        return 0
    fi
    if grep -q "invalid linker name in argument '-fuse-ld=gold'" "$chunk"; then
        echo "CANNOT_LINKER_GOLD_REJECTED: ninja still passed -fuse-ld=gold; Swift's clang rejects that name. cmake must be -DSWIFT_USE_LINKER=lld." >&2
    fi
    echo "ninja: FAILED rc=$st" >&2
    rm -f "$chunk"
    return "$st"
}
