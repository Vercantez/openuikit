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

# Idempotency for scratch/sysroot_fe4-x86_64 keys on INPUT content, not on the
# output directory existing. A sysroot staged before x86 libswiftCore landed
# would otherwise be reused while OpenCombine looks in usr/lib/swift and finds
# nothing. Recipe bump forces a restage when the stager itself gains steps.
PHASE2_SYSROOT_RECIPE=stage_fe_sysroot_x86.1
PHASE2_SYSROOT_STAMP=.phase2-stage-inputs

phase2_sha_or_absent() {
    local f=$1
    if [ -f "$f" ]; then
        sha256sum "$f" | awk '{print $1}'
    else
        printf 'ABSENT\n'
    fi
}

# Prefer the x86_64 Darwin.swiftinterface the overlays already ship; fall back
# to the arm64 slice (same text family) or a loose Darwin.swiftinterface.
phase2_arm_overlay_interface() {
    local arm=$1 f
    for f in \
        "$arm/usr/lib/swift/Darwin.swiftmodule/x86_64-apple-macos.swiftinterface" \
        "$arm/usr/lib/swift/Darwin.swiftmodule/arm64-apple-macos.swiftinterface" \
        "$arm/usr/lib/swift/Darwin.swiftinterface"
    do
        if [ -f "$f" ]; then
            printf '%s\n' "$f"
            return 0
        fi
    done
    return 1
}

# phase2_sysroot_input_lines <libswiftCore> <Swift.swiftmodule> <_Builtin_float.swiftmodule>
#                          <gen_darwin_modulemap.py> <Darwin.swiftinterface> <Darwin.modulemap>
phase2_sysroot_input_lines() {
    printf 'recipe=%s\n' "$PHASE2_SYSROOT_RECIPE"
    printf 'libswiftCore=%s\n' "$(phase2_sha_or_absent "$1")"
    printf 'Swift.swiftmodule=%s\n' "$(phase2_sha_or_absent "$2")"
    printf '_Builtin_float.swiftmodule=%s\n' "$(phase2_sha_or_absent "$3")"
    printf 'gen_darwin_modulemap.py=%s\n' "$(phase2_sha_or_absent "$4")"
    printf 'Darwin.swiftinterface=%s\n' "$(phase2_sha_or_absent "$5")"
    printf 'Darwin.modulemap=%s\n' "$(phase2_sha_or_absent "$6")"
}

phase2_write_sysroot_stamp() {
    local dest=$1
    shift
    phase2_sysroot_input_lines "$@" > "$dest"
}

# Print "key old->new" (and stamp=ABSENT). Return 0 iff stamp matches expected.
phase2_sysroot_stamp_diff() {
    local stamp=$1
    shift
    local expected key val old changed=0
    expected=$(phase2_sysroot_input_lines "$@")
    if [ ! -f "$stamp" ]; then
        printf 'stamp=ABSENT\n'
        return 1
    fi
    while IFS='=' read -r key val; do
        [ -n "$key" ] || continue
        old=$(awk -F= -v k="$key" '$1==k { print substr($0, index($0,"=")+1); exit }' "$stamp")
        [ -n "$old" ] || old=ABSENT
        if [ "$old" != "$val" ]; then
            printf '%s %s->%s\n' "$key" "$old" "$val"
            changed=1
        fi
    done <<EOF
$expected
EOF
    [ "$changed" -eq 0 ]
}

# phase2_sysroot_complete <sys> <need_core 0|1> <need_builtin 0|1>
# Overlays + Darwin.modulemap + x86 libSystem, plus staged Swift pieces when
# those artifacts exist. A tree that is only "headers and Darwin.swiftmodule"
# is not complete once x86 libswiftCore is in-tree.
phase2_sysroot_complete() {
    local sys=$1 need_core=$2 need_bf=$3
    [ -d "$sys/usr/include" ] || return 1
    [ -f "$sys/usr/lib/libSystem.B.dylib" ] || return 1
    phase2_is_x86_macho "$sys/usr/lib/libSystem.B.dylib" || return 1
    { [ -d "$sys/usr/lib/swift/Darwin.swiftmodule" ] \
        || [ -f "$sys/usr/lib/swift/Darwin.swiftinterface" ]; } || return 1
    [ -f "$sys/usr/include/Darwin.modulemap" ] || return 1
    if [ "$need_core" = 1 ]; then
        [ -f "$sys/usr/lib/swift/libswiftCore.dylib" ] || return 1
        phase2_is_x86_macho "$sys/usr/lib/swift/libswiftCore.dylib" || return 1
    fi
    if [ "$need_bf" = 1 ]; then
        { [ -f "$sys/usr/lib/swift/_Builtin_float.swiftmodule/x86_64-apple-macos.swiftmodule" ] \
            || [ -f "$sys/usr/lib/swift/_Builtin_float.swiftmodule/x86_64-apple-macos.swiftinterface" ]; } \
            || return 1
    fi
    return 0
}

phase2_copy_darwin_modulemaps_from_arm() {
    local sys=$1 arm=$2
    local m base copied=0 line
    [ -d "$arm/usr/include" ] || return 1
    mkdir -p "$sys/usr/include"
    for m in "$arm"/usr/include/*.modulemap; do
        [ -f "$m" ] || continue
        base=$(basename "$m")
        [ "$base" = module.modulemap ] && continue
        cp "$m" "$sys/usr/include/$base"
        copied=$((copied + 1))
    done
    if [ -f "$arm/usr/include/module.modulemap" ] && [ -f "$sys/usr/include/module.modulemap" ]; then
        while IFS= read -r line; do
            grep -qxF "$line" "$sys/usr/include/module.modulemap" && continue
            printf '%s\n' "$line" >> "$sys/usr/include/module.modulemap"
        done < <(grep -E '^(extern module |// Appended by machorun)' \
            "$arm/usr/include/module.modulemap" || true)
    fi
    echo "  copied $copied Darwin-family modulemaps from $arm"
    [ "$copied" -gt 0 ]
}

# Mirror full/foundation/stage_fe_sysroot.sh: base module.modulemap is already
# written; run gen_darwin_modulemap.py against THIS sysroot. The generator
# reads Xcode, so on Linux it fails; then copy the pruned family from the arm64
# sysroot (same headers, already generated on macOS). Print git/python errors
# instead of folding them into "not at pin" / "overlays absent".
phase2_install_darwin_modulemaps() {
    local sys=$1 arm=$2 gen=$3
    local err rc
    mkdir -p "$sys/usr/include"
    if [ -f "$gen" ]; then
        err=$(mktemp)
        set +e
        python3 "$gen" "$sys" >"$err" 2>&1
        rc=$?
        set -e
        if [ "$rc" -eq 0 ] && [ -f "$sys/usr/include/Darwin.modulemap" ]; then
            echo "  Darwin family: generated by gen_darwin_modulemap.py against $sys"
            rm -f "$err"
            return 0
        fi
        echo "  gen_darwin_modulemap.py exit ${rc:-ABSENT} ($(phase2_flatten < "$err")); copying pruned maps from arm64 sysroot"
        rm -f "$err"
    else
        echo "  gen_darwin_modulemap.py ABSENT at $gen; copying pruned maps from arm64 sysroot"
    fi
    phase2_copy_darwin_modulemaps_from_arm "$sys" "$arm" || true
    if [ -f "$sys/usr/include/Darwin.modulemap" ]; then
        echo "  Darwin.modulemap present"
        return 0
    fi
    echo "  no Darwin.modulemap (generator needs Xcode; arm64 sysroot had none to copy)"
    return 1
}

# Swift overlay or local -I module for $name, requiring the guest module triple
# (x86_64-apple-macos), never an arm64 slice under an x86 name.
phase2_swift_module_present() {
    local name=$1
    local root=$2
    local triple=${3:-${SWIFT_MODULE_TRIPLE:-x86_64-apple-macos}}
    local dir
    [ -n "$root" ] || return 1
    if [ -d "$root/usr/lib/swift" ]; then
        dir=$root/usr/lib/swift
    else
        dir=$root
    fi
    [ -f "$dir/$name.swiftmodule" ] && return 0
    [ -f "$dir/$name.swiftinterface" ] && return 0
    [ -f "$dir/$name.swiftmodule/$triple.swiftmodule" ] && return 0
    [ -f "$dir/$name.swiftmodule/$triple.swiftinterface" ] && return 0
    return 1
}

# FE import census before the 202-file compile. One line, never silent:
#   MATCH present=... optional_absent=...
#   MISSING present=... absent=... optional_absent=...
# Required (compile fails if missing on the Darwin path): Darwin, os, Swift,
# _Builtin_float, _StringProcessing (Regex in URLTemplate/RegexPatternCache;
# build_fe.sh does not pass -disable-implicit-string-processing-module-import),
# _Concurrency (Swift.swiftmodule / stdlib).
# Optional (canImport-guarded in standalone FE): Synchronization.
# os is the local module at OSMOD, not Apple's overlay.
# phase2_probe_fe_imports <sysroot> [osmod]
phase2_probe_fe_imports() {
    local sys=$1 osmod=${2:-}
    local triple=${SWIFT_MODULE_TRIPLE:-x86_64-apple-macos}
    local present="" absent="" opt_absent=""
    local name ok

    _fe_add() {
        local bucket=$1 item=$2
        if [ -z "${!bucket}" ]; then
            eval "$bucket=\$item"
        else
            eval "$bucket=\${!bucket},\$item"
        fi
    }

    for name in Darwin os Swift _Builtin_float _StringProcessing _Concurrency; do
        ok=0
        case "$name" in
            Darwin)
                if phase2_swift_module_present Darwin "$sys" "$triple" \
                    && [ -f "$sys/usr/include/Darwin.modulemap" ]; then
                    ok=1
                fi
                ;;
            os)
                if phase2_swift_module_present os "$osmod" "$triple"; then
                    ok=1
                fi
                ;;
            *)
                if phase2_swift_module_present "$name" "$sys" "$triple"; then
                    ok=1
                fi
                ;;
        esac
        if [ "$ok" -eq 1 ]; then
            _fe_add present "$name"
        else
            _fe_add absent "$name"
        fi
    done
    name=Synchronization
    if phase2_swift_module_present Synchronization "$sys" "$triple"; then
        _fe_add present Synchronization
    else
        _fe_add opt_absent Synchronization
    fi
    unset -f _fe_add
    if [ -n "$absent" ]; then
        printf 'MISSING present=%s absent=%s optional_absent=%s\n' \
            "${present:--}" "$absent" "${opt_absent:--}"
        return 1
    fi
    printf 'MATCH present=%s optional_absent=%s\n' "$present" "${opt_absent:--}"
    return 0
}
