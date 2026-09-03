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
