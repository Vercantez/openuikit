# probe_machorun.inc -- sourced. Positive probe for a machorun loader that
# can run an x86_64 Mach-O on THIS host. Never assume the host is a cloud
# agent VM; never print CURSOR_ENV_CANNOT_EXECUTE_X86_SWIFT_GUEST without
# having looked for a loader.

if [ -n "${SWIFTCORE_PROBE_MACHORUN_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
SWIFTCORE_PROBE_MACHORUN_INC=1

# Append unique non-empty paths to the nameref array.
_sc_probe_add() {
    local -n _arr=$1
    local p=$2
    [ -n "$p" ] || return 0
    local e
    for e in "${_arr[@]+"${_arr[@]}"}"; do
        [ "$e" = "$p" ] && return 0
    done
    _arr+=("$p")
}

# Try one candidate path. On success print:  <loader>\t<root>
# A directory is treated as a machorun tree (build/machorun inside).
# A file is treated as the loader binary.
_sc_try_machorun_loader() {
    local cand=$1
    local bin="" root=""
    [ -n "$cand" ] || return 1
    if [ -d "$cand" ]; then
        if [ -x "$cand/build/machorun" ] && [ -f "$cand/build/machorun" ]; then
            bin=$cand/build/machorun
            root=$cand
        elif [ -x "$cand/machorun" ] && [ -f "$cand/machorun" ]; then
            bin=$cand/machorun
            root=$cand
        else
            return 1
        fi
    elif [ -x "$cand" ] && [ -f "$cand" ]; then
        bin=$cand
        local d
        d=$(cd "$(dirname "$cand")" && pwd)
        if [ "$(basename "$d")" = build ]; then
            root=$(cd "$d/.." && pwd)
        else
            root=$d
        fi
    else
        return 1
    fi

    local host desc
    host=$(uname -m)
    desc=$(file -b "$bin" 2>/dev/null || true)
    case "$host" in
        x86_64)
            printf '%s' "$desc" | grep -q 'ELF 64-bit' || return 1
            printf '%s' "$desc" | grep -Eq 'x86-64|x86_64' || return 1
            ;;
        aarch64|arm64)
            printf '%s' "$desc" | grep -q 'ELF 64-bit' || return 1
            printf '%s' "$desc" | grep -Eq 'aarch64|ARM aarch64' || return 1
            ;;
        *)
            return 1
            ;;
    esac

    # An aarch64 ELF loader cannot run an x86_64 Mach-O guest.
    if [ "${SWIFTCORE_DARWIN_ARCH:-x86_64}" = x86_64 ] && [ "$host" != x86_64 ]; then
        return 1
    fi

    local usage
    usage=$("$bin" 2>&1 || true)
    printf '%s' "$usage" | grep -qi 'mach-o' || return 1

    printf '%s\t%s\n' "$bin" "$root"
    return 0
}

# Print probed candidate paths (one per line) — for the CANNOT reason.
probe_machorun_candidates() {
    local cands=()
    _sc_probe_add cands "${MACHORUN_LOADER:-}"
    _sc_probe_add cands /opt/openuikit/x86-verify/openuikit/machorun
    _sc_probe_add cands /opt/openuikit/x86-verify/openuikit/machorun/build/machorun
    _sc_probe_add cands "${MACHORUN:-}/build/machorun"
    _sc_probe_add cands "${MACHORUN:-}"
    if [ -n "${OPENUIKIT_ROOT:-}" ]; then
        _sc_probe_add cands "$OPENUIKIT_ROOT/machorun/build/machorun"
        _sc_probe_add cands "$OPENUIKIT_ROOT/machorun"
    fi
    _sc_probe_add cands "${W:-$HOME/work}/machorun/build/machorun"
    _sc_probe_add cands "${W:-$HOME/work}/machorun"
    local c
    for c in "${cands[@]+"${cands[@]}"}"; do
        printf '%s\n' "$c"
    done
}

# First matching loader. Prints "<loader>\t<root>". Returns 1 if none.
probe_x86_macho_loader() {
    local cand got
    while IFS= read -r cand; do
        [ -n "$cand" ] || continue
        got=$(_sc_try_machorun_loader "$cand") || continue
        printf '%s\n' "$got"
        return 0
    done < <(probe_machorun_candidates)
    return 1
}
