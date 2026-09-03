# ninja_checked.inc -- sourced. Run ninja and propagate its exit status.
#
# The Darwin stdlib ninja graph links ELF .so with -fuse-ld=gold (BUILD_LOG
# wall 7). That invocation is allowed to fail *only* when the log is that
# gold wall. Every other ninja invocation — overlays included — must fail
# the caller. PIPESTATUS[0] is ninja, not tee.

if [ -n "${SWIFTCORE_NINJA_CHECKED_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
SWIFTCORE_NINJA_CHECKED_INC=1

# ninja_checked [--allow-gold-wall] <logfile> [ninja-args...]
# Honors NINJA (default: ninja). Returns ninja's status; 0 on the expected
# gold wall when --allow-gold-wall is set.
ninja_checked() {
    local allow_gold=0
    if [ "${1:-}" = --allow-gold-wall ]; then
        allow_gold=1
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
    if [ "$st" -eq 0 ]; then
        rm -f "$chunk"
        return 0
    fi
    if [ "$allow_gold" = 1 ] && _sc_gold_wall_only "$chunk"; then
        echo "ninja: expected ELF gold wall (BUILD_LOG wall 7: -fuse-ld=gold); continuing"
        rm -f "$chunk"
        return 0
    fi
    echo "ninja: FAILED rc=$st" >&2
    rm -f "$chunk"
    return "$st"
}

_sc_gold_wall_only() {
    local chunk=$1
    grep -q "invalid linker name in argument '-fuse-ld=gold'" "$chunk" || return 1
    # A real compile/unknown-target failure alongside gold is not the wall.
    grep -q 'ninja: error:' "$chunk" && return 1
    grep -Eq "error: '.+' file not found" "$chunk" && return 1
    return 0
}
