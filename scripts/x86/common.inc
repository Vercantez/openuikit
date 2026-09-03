# scripts/x86/common.inc -- helpers for the PHASE 2 runner. Sourced, not executed.
#
# Marker grammar (one line, parseable, never a silent skip):
#   ENV_PREPARE <name> satisfied
#   ENV_PREPARE <name> cold-built
#   ENV_PREPARE <name> CANNOT_<MARKER> reason=<single-line>
# A CANNOT line is a refusal, not a skip. Callers must not treat it as success.

if [ -n "${PHASE2_COMMON_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
PHASE2_COMMON_INC=1

phase2_prepare() {
    printf 'ENV_PREPARE %s %s\n' "$1" "$2"
}

phase2_cannot() {
    # phase2_cannot <name> <MARKER> <reason>
    printf 'ENV_PREPARE %s CANNOT_%s reason=%s\n' "$1" "$2" "$3"
}

phase2_macho_cpu() {
    # Print ARM64 or X86_64 from llvm-otool -hv, or EMPTY.
    # Column 2 is cputype (X86_64 / ARM64); column 3 is cpusubtype (ALL).
    local f=$1
    [ -f "$f" ] || { printf 'EMPTY\n'; return 0; }
    llvm-otool-18 -hv "$f" 2>/dev/null \
        | awk '/MH_MAGIC_64/ { print $2; found=1 } END { if (!found) print "EMPTY" }' \
        | head -n 1
}

phase2_is_x86_macho() {
    llvm-otool-18 -hv "$1" 2>/dev/null | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64'
}

phase2_is_arm64_macho() {
    llvm-otool-18 -hv "$1" 2>/dev/null | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64'
}

phase2_is_elf_x86_loader() {
    local f=$1
    [ -x "$f" ] || return 1
    file -b "$f" | grep -q 'ELF 64-bit LSB pie executable, x86-64'
}

phase2_flatten() {
    tr '\n\t\r' '   ' | sed 's/  */ /g; s/^ //; s/ $//'
}

# git -C that names the start path and its parents as safe.directory.
# Host bootstrap may have skipped `git config --global safe.directory` when
# $HOME was unset (dubious-ownership). Do not require a .git directory on
# the start path: ladder-corpus/focus-ios is the git root, focus-ios/focus-ios
# is the app subtree.
phase2_git() {
    local dir=$1
    shift
    local abs parent grand
    abs=$(cd "$dir" && pwd) || return 1
    parent=$(dirname "$abs")
    grand=$(dirname "$parent")
    git -c "safe.directory=$abs" \
        -c "safe.directory=$parent" \
        -c "safe.directory=$grand" \
        -C "$abs" "$@"
}

# Probe Focus pin. One line, never silent:
#   MATCH toplevel=... observed=<sha>
#   MISMATCH start=... toplevel=... expected=<sha> observed=<sha>
#   ERROR start=... expected=<sha> observed=ABSENT|ERROR git_error=...
# Resolves the git root with rev-parse --show-toplevel before comparing HEAD.
phase2_probe_focus_pin() {
    local start=$1 expected=$2
    local err toplevel observed
    if [ ! -d "$start" ]; then
        printf 'ERROR start=%s expected=%s observed=ABSENT git_error=not a directory\n' \
            "$start" "$expected"
        return 1
    fi
    err=$(mktemp)
    if ! toplevel=$(phase2_git "$start" rev-parse --show-toplevel 2>"$err"); then
        printf 'ERROR start=%s expected=%s observed=ERROR git_error=%s\n' \
            "$start" "$expected" "$(phase2_flatten < "$err")"
        rm -f "$err"
        return 1
    fi
    if ! observed=$(phase2_git "$toplevel" rev-parse HEAD 2>"$err"); then
        printf 'ERROR start=%s toplevel=%s expected=%s observed=ERROR git_error=%s\n' \
            "$start" "$toplevel" "$expected" "$(phase2_flatten < "$err")"
        rm -f "$err"
        return 1
    fi
    rm -f "$err"
    if [ "$observed" = "$expected" ]; then
        printf 'MATCH toplevel=%s observed=%s\n' "$toplevel" "$observed"
        return 0
    fi
    printf 'MISMATCH start=%s toplevel=%s expected=%s observed=%s\n' \
        "$start" "$toplevel" "$expected" "$observed"
    return 1
}
