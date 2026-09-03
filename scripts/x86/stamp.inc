# scripts/x86/stamp.inc -- one reuse library for every built product.
# POSIX sh (sourced). No site may reuse an artefact because the path exists.
#
#   stamp_key <out> <input>...   sha256 of file CONTENTS and any argv string
#   stamp_reuse <out> <key>      0 iff out exists, is the expected kind, and
#                                <out>.inputs-sha256 equals key. Prints
#                                `reused=1 stamp=<12>` to stderr on success.
#   stamp_write <out> <key>      write <out>.inputs-sha256
#   stamp_rebuild_reason <out> <key>
#                                prints `rebuilt reason=no-stamp` or
#                                `rebuilt reason=inputs <old12>-><new12>` to stderr
#
# Expected kind: x86_64 Mach-O (llvm-otool-18 MH_MAGIC_64 X86_64), x86-64 ELF
# PIE/shared object, a non-empty .tbd, or a directory (git checkout). A Mach-O
# of the wrong arch never reuses.

if [ -n "${STAMP_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
STAMP_INC=1

stamp_short() {
    printf '%s' "$1" | cut -c1-12
}

stamp_file() {
    printf '%s.inputs-sha256\n' "$1"
}

# Hash inputs. Regular files contribute CONTENT (not the path). Anything else
# (missing path, directory, flag, git tree, argv) contributes the string.
stamp_key() {
    if [ "$#" -lt 1 ]; then
        printf 'stamp_key: usage: stamp_key <out> <input>...\n' >&2
        return 2
    fi
    shift
    if [ "$#" -lt 1 ]; then
        printf 'stamp_key: need at least one input\n' >&2
        return 2
    fi
    {
        for _stamp_arg in "$@"; do
            if [ -f "$_stamp_arg" ] && [ ! -L "$_stamp_arg" ]; then
                printf 'F '
                sha256sum < "$_stamp_arg"
            elif [ -f "$_stamp_arg" ]; then
                printf 'F '
                sha256sum < "$_stamp_arg"
            else
                printf 'S %s\n' "$_stamp_arg"
            fi
        done
    } | sha256sum | awk '{ print $1 }'
}

stamp_expected_kind() {
    _stamp_f=$1
    if [ -d "$_stamp_f" ]; then
        return 0
    fi
    if [ ! -f "$_stamp_f" ]; then
        return 1
    fi
    case "$_stamp_f" in
        *.tbd)
            [ -s "$_stamp_f" ]
            return $?
            ;;
    esac
    if command -v llvm-otool-18 >/dev/null 2>&1; then
        if llvm-otool-18 -hv "$_stamp_f" 2>/dev/null | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64'; then
            return 0
        fi
        if llvm-otool-18 -hv "$_stamp_f" 2>/dev/null | grep -q 'MH_MAGIC_64'; then
            return 1
        fi
    fi
    _stamp_file=$(file -b "$_stamp_f" 2>/dev/null || true)
    case "$_stamp_file" in
        *"Mach-O 64-bit x86_64"*) return 0 ;;
        *"Mach-O 64-bit arm64"*|*"Mach-O 64-bit ARM64"*) return 1 ;;
        *"ELF 64-bit LSB pie executable, x86-64"*) return 0 ;;
        *"ELF 64-bit LSB executable, x86-64"*) return 0 ;;
        *"ELF 64-bit LSB shared object, x86-64"*) return 0 ;;
    esac
    return 1
}

# 0 = reuse. Prints the reuse line to stderr. Does not print on miss so the
# caller can emit rebuilt reason= after deciding to rebuild.
stamp_reuse() {
    _stamp_out=$1
    _stamp_key=$2
    _stamp_sf=$(stamp_file "$_stamp_out")
    if [ ! -e "$_stamp_out" ]; then
        return 1
    fi
    if ! stamp_expected_kind "$_stamp_out"; then
        return 1
    fi
    if [ ! -f "$_stamp_sf" ]; then
        return 1
    fi
    _stamp_have=$(tr -d '[:space:]' < "$_stamp_sf")
    if [ -z "$_stamp_have" ] || [ "$_stamp_have" != "$_stamp_key" ]; then
        return 1
    fi
    printf 'reused=1 stamp=%s\n' "$(stamp_short "$_stamp_key")" >&2
    return 0
}

stamp_rebuild_reason() {
    _stamp_out=$1
    _stamp_key=$2
    _stamp_sf=$(stamp_file "$_stamp_out")
    if [ ! -f "$_stamp_sf" ]; then
        printf 'rebuilt reason=no-stamp\n' >&2
        return 0
    fi
    _stamp_old=$(tr -d '[:space:]' < "$_stamp_sf")
    if [ -z "$_stamp_old" ]; then
        printf 'rebuilt reason=no-stamp\n' >&2
        return 0
    fi
    printf 'rebuilt reason=inputs %s->%s\n' \
        "$(stamp_short "$_stamp_old")" "$(stamp_short "$_stamp_key")" >&2
}

stamp_write() {
    _stamp_out=$1
    _stamp_key=$2
    _stamp_sf=$(stamp_file "$_stamp_out")
    mkdir -p "$(dirname "$_stamp_sf")"
    printf '%s\n' "$_stamp_key" > "$_stamp_sf"
}

# One line the cycle runner greps. status=reused|rebuilt|cannot
stamp_stage_line() {
    _stamp_name=$1
    _stamp_status=$2
    _stamp_key=$3
    _stamp_product=$4
    _stamp_sha=absent
    if [ -f "$_stamp_product" ]; then
        _stamp_sha=$(sha256sum "$_stamp_product" | awk '{ print substr($1,1,12) }')
    elif [ -d "$_stamp_product" ]; then
        _stamp_sha=$(printf '%s\n' "$_stamp_product" | sha256sum | awk '{ print substr($1,1,12) }')
    fi
    printf 'STAGE %s status=%s key=%s product=%s sha256=%s\n' \
        "$_stamp_name" "$_stamp_status" "$(stamp_short "$_stamp_key")" \
        "$_stamp_product" "$_stamp_sha"
}
