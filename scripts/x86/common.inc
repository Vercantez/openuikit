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

_phase2_tree=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=../../full/foundation/fe_sysroot_measurement.inc
. "$_phase2_tree/full/foundation/fe_sysroot_measurement.inc"
# shellcheck source=../../full/dispatch/swift_linux_lib.inc
. "$_phase2_tree/full/dispatch/swift_linux_lib.inc"
PHASE2_REPO=$_phase2_tree
unset _phase2_tree

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
PHASE2_SYSROOT_RECIPE=stage_fe_sysroot_x86.6
PHASE2_SYSROOT_STAMP=.phase2-stage-inputs

phase2_sha_or_absent() {
    local f=$1
    if [ -f "$f" ]; then
        sha256sum "$f" | awk '{print $1}'
    else
        printf 'ABSENT\n'
    fi
}

# Apple unsuffixed aliases gen_tbd emits as symlinks. -lobjc looks for
# libobjc.tbd, not libobjc.A.tbd. The x86.4 stager used find -type f and
# dropped them; render_full.o then died on _objc_sync_exit and friends.
phase2_required_darwin_tbd_relpaths() {
    printf '%s\n' \
        usr/lib/libSystem.B.tbd \
        usr/lib/libSystem.tbd \
        usr/lib/libc++.1.tbd \
        usr/lib/libc++.tbd \
        usr/lib/libc++abi.tbd \
        usr/lib/libobjc.A.tbd \
        usr/lib/libobjc.tbd \
        usr/lib/libquartz.tbd
}

# render_full.o undefineds that -lobjc must resolve (operator link at
# a447787a). Each must appear in the staged x86 libobjc.tbd.
phase2_render_full_objc_undefs() {
    printf '%s\n' \
        _objc_sync_exit \
        _objc_sync_enter \
        _objc_setAssociatedObject \
        _objc_getAssociatedObject \
        _objc_opt_self \
        _objc_getClassList \
        _objc_getClass \
        __objc_empty_cache
}

# Named $SYS/usr/lib/swift/*.tbd the widget gate lstat()s. Dylib stand-ins
# do not satisfy focus_widget_guest_attest. libswiftCore plus the twelve
# overlays (nine FE + _Concurrency + ObjectiveC + Observation).
phase2_required_swift_tbd_relpaths() {
    local name
    printf 'usr/lib/swift/libswiftCore.tbd\n'
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        printf 'usr/lib/swift/%s\n' "${name%.dylib}.tbd"
    done < <(phase2_twelve_overlay_names)
}

phase2_sysroot_tbd_relpaths() {
    local root=$1 t
    {
        if [ -d "$root/usr/lib" ]; then
            for t in "$root/usr/lib"/*.tbd; do
                [ -e "$t" ] || [ -L "$t" ] || continue
                printf 'usr/lib/%s\n' "$(basename "$t")"
            done
        fi
        if [ -d "$root/usr/lib/swift" ]; then
            for t in "$root/usr/lib/swift"/*.tbd; do
                [ -e "$t" ] || [ -L "$t" ] || continue
                printf 'usr/lib/swift/%s\n' "$(basename "$t")"
            done
        fi
    } | sort -u
}

phase2_arm_tbd_set_id() {
    local arm=$1 list
    if [ -z "$arm" ] || [ ! -d "$arm" ]; then
        printf 'EMPTY\n'
        return 0
    fi
    list=$(phase2_sysroot_tbd_relpaths "$arm")
    if [ -z "$list" ]; then
        printf 'EMPTY\n'
        return 0
    fi
    printf '%s\n' "$list" | sha256sum | awk '{print $1}'
}

phase2_darwin_tbd_source_id() {
    local root=${MACHORUN:-${W:+$W/machorun}} d lib
    if [ -z "$root" ]; then
        printf 'ABSENT\n'
        return 0
    fi
    {
        for lib in libSystem.B.dylib libc++.1.dylib libc++abi.dylib \
            libobjc.A.dylib libquartz.dylib; do
            phase2_sha_or_absent "$root/darwin/usr/lib/$lib"
        done
    } | sha256sum | awk '{print $1}'
}

phase2_tbd_is_x86_target() {
    local tbd=$1
    [ -e "$tbd" ] || [ -L "$tbd" ] || return 1
    grep -q 'x86_64-macos' "$tbd"
}

# TAPI v4 from an x86 Swift dylib via the committed writer. Never copy
# an arm64 .tbd and rewrite the target; symbols come from this x86 dylib.
# $install is unused (otool -D); kept so existing call sites stay valid.
phase2_emit_tbd_from_dylib() {
    local dylib=$1 dest=$3
    [ -f "$dylib" ] || return 1
    phase2_is_x86_macho "$dylib" || return 1
    bash "$PHASE2_REPO/scripts/x86/gen_swift_tbd.sh" "$dylib" "$dest" >/dev/null
}

# Copy machorun gen_tbd output into the x86 sysroot, including the unsuffixed
# aliases. Never copy arm64 sysroot .tbd files (they name arm64-macos).
phase2_stage_darwin_tbds_into_sysroot() {
    local sys=$1 machorun=$2
    local src=$machorun/sdk/usr/lib t bn
    mkdir -p "$sys/usr/lib"
    if [ -d "$src" ]; then
        for t in "$src"/*.tbd; do
            [ -e "$t" ] || [ -L "$t" ] || continue
            bn=$(basename "$t")
            [ -s "$t" ] || {
                echo "phase2: empty .tbd is a linker lie: $t" >&2
                return 1
            }
            if ! phase2_tbd_is_x86_target "$t"; then
                echo "phase2: refusing non-x86 .tbd $t (never copy arm64 tbds)" >&2
                return 1
            fi
            cp -a "$t" "$sys/usr/lib/$bn"
        done
    fi
    [ -s "$sys/usr/lib/libobjc.A.tbd" ] || {
        echo "phase2: no libobjc.A.tbd from gen_tbd at $src" >&2
        return 1
    }
    ln -sfn libSystem.B.tbd "$sys/usr/lib/libSystem.tbd"
    ln -sfn libobjc.A.tbd "$sys/usr/lib/libobjc.tbd"
    ln -sfn libc++.1.tbd "$sys/usr/lib/libc++.tbd"
    return 0
}

# Emit usr/lib/swift/*.tbd from x86 overlay dylibs (sysroot copy, FE search,
# ObjectiveC/Concurrency). Never copy arm64 overlay tbds.
phase2_stage_overlay_tbds_into_sysroot() {
    local sys=$1
    local dylib base dest install src name extra emitted
    mkdir -p "$sys/usr/lib/swift"
    emitted=" "
    _phase2_emit_overlay_tbd() {
        local dylib=$1
        local base dest install
        [ -f "$dylib" ] || return 0
        phase2_is_x86_macho "$dylib" || return 0
        base=$(basename "$dylib" .dylib)
        case " $emitted " in *" $base "*) return 0 ;; esac
        dest="$sys/usr/lib/swift/$base.tbd"
        install="/usr/lib/swift/$base.dylib"
        if phase2_emit_tbd_from_dylib "$dylib" "$install" "$dest"; then
            emitted="$emitted $base "
        fi
    }
    if [ -d "$sys/usr/lib/swift" ]; then
        for dylib in "$sys/usr/lib/swift"/*.dylib; do
            [ -e "$dylib" ] || continue
            _phase2_emit_overlay_tbd "$dylib"
        done
    fi
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        src=$(phase2_find_x86_overlay "$name" || true)
        [ -n "$src" ] || continue
        _phase2_emit_overlay_tbd "$src"
    done < <(phase2_twelve_overlay_names)
    src=$(phase2_find_x86_overlay libswiftCore.dylib || true)
    [ -n "$src" ] && _phase2_emit_overlay_tbd "$src"
    return 0
}

# Consumer-derived inventory: what build_full.sh, the widget/onboarding
# expected_*_inputs / expected_*_loads, focus_widget_guest_attest.pl, and
# foundation-macho/scripts/link_ud_guest.sh actually -l / name as .tbd.
# Never the Apple SDK's whole usr/lib/swift overlay list (ARKit, AppKit, …).
phase2_consumer_tbd_relpaths() {
    {
        phase2_required_darwin_tbd_relpaths
        phase2_required_swift_tbd_relpaths
    } | sort -u
}

# Apple-SDK .tbd names in the arm64 sysroot that no consumer links.
# Printed as NOTE, never a CANNOT.
phase2_sysroot_tbd_extras() {
    local arm=$1 rel want
    want=$(phase2_consumer_tbd_relpaths)
    [ -n "$arm" ] && [ -d "$arm" ] || return 0
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        printf '%s\n' "$want" | grep -qx "$rel" && continue
        printf '%s\n' "$rel"
    done < <(phase2_sysroot_tbd_relpaths "$arm")
}

# Consumer .tbd set must exist for x86 and name x86_64-macos. Extra Apple-SDK
# names from the arm64 sysroot are not required. Prints OK or MISSING=…
# WRONG_TARGET=…. An arm64-macos .tbd staged into the x86 sysroot is always
# WRONG_TARGET (never copy arm64 tbds).
phase2_sysroot_tbd_resolve() {
    local sys=$1 arm=$2
    local rel path missing=() wrong=() want seen=' '
    want=$(phase2_consumer_tbd_relpaths)
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        path=$sys/$rel
        if [ ! -e "$path" ] && [ ! -L "$path" ]; then
            missing+=("$rel")
            continue
        fi
        if ! phase2_tbd_is_x86_target "$path"; then
            wrong+=("$rel")
        fi
        seen="$seen $rel "
    done <<EOF
$want
EOF
    # Negative: a copied arm64-macos tbd anywhere in the x86 usr/lib set.
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        case " $seen " in *" $rel "*) continue ;; esac
        if ! phase2_tbd_is_x86_target "$sys/$rel"; then
            wrong+=("$rel")
        fi
    done < <(phase2_sysroot_tbd_relpaths "$sys")
    if [ "${#missing[@]}" -eq 0 ] && [ "${#wrong[@]}" -eq 0 ]; then
        printf 'OK\n'
        return 0
    fi
    local IFS=,
    [ "${#missing[@]}" -eq 0 ] || printf 'MISSING=%s' "${missing[*]}"
    if [ "${#wrong[@]}" -ne 0 ]; then
        [ "${#missing[@]}" -eq 0 ] || printf ' '
        printf 'WRONG_TARGET=%s' "${wrong[*]}"
    fi
    printf '\n'
    return 1
}

# Linux swiftc warns (and some compiles then fail) when -sdk has no
# SDKSettings.json. Same text as swiftcore-macho/scripts/stage_sdk.sh.
# Idempotent: do not overwrite an existing file.
phase2_ensure_sdk_settings() {
    local sdk=$1
    [ -d "$sdk" ] || return 0
    if [ ! -f "$sdk/SDKSettings.json" ]; then
        cat > "$sdk/SDKSettings.json" <<'EOF'
{ "DefaultProperties": { "PLATFORM_NAME": "macosx" },
  "DisplayName": "macOS 15.0", "Version": "15.0",
  "MaximumDeploymentTarget": "15.0.99",
  "CanonicalName": "macosx15.0" }
EOF
    fi
    if [ ! -f "$sdk/SDKSettings.plist" ]; then
        cat > "$sdk/SDKSettings.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CanonicalName</key><string>macosx15.0</string>
  <key>DisplayName</key><string>macOS 15.0</string>
  <key>Version</key><string>15.0</string>
  <key>MaximumDeploymentTarget</key><string>15.0.99</string>
  <key>SupportedTargets</key>
  <dict><key>macosx</key><dict>
    <key>Archs</key><array><string>x86_64</string></array>
    <key>LLVMTargetTripleSys</key><string>macos</string>
    <key>LLVMTargetTripleVendor</key><string>apple</string>
  </dict></dict>
</dict>
</plist>
EOF
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
#                          [fe_sysroot_measurement_headers.txt]
phase2_sysroot_input_lines() {
    printf 'recipe=%s\n' "$PHASE2_SYSROOT_RECIPE"
    printf 'libswiftCore=%s\n' "$(phase2_sha_or_absent "$1")"
    printf 'Swift.swiftmodule=%s\n' "$(phase2_sha_or_absent "$2")"
    printf '_Builtin_float.swiftmodule=%s\n' "$(phase2_sha_or_absent "$3")"
    printf 'gen_darwin_modulemap.py=%s\n' "$(phase2_sha_or_absent "$4")"
    printf 'Darwin.swiftinterface=%s\n' "$(phase2_sha_or_absent "$5")"
    printf 'Darwin.modulemap=%s\n' "$(phase2_sha_or_absent "$6")"
    printf 'fe_sysroot_measurement_headers=%s\n' \
        "$(phase2_sha_or_absent "${7:-$FE_SYSROOT_MEASUREMENT_HEADERS_FILE}")"
    printf 'tbd-set=%s\n' "$(phase2_arm_tbd_set_id "${ARM_SYS:-${W:+$W/scratch/sysroot_fe4}}")"
    printf 'tbd-darwin-dylibs=%s\n' "$(phase2_darwin_tbd_source_id)"
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
    # -lobjc looks for libobjc.tbd (Apple unsuffixed alias). libobjc.A.tbd
    # alone is not enough; x86.4 find -type f dropped the symlink.
    [ -e "$sys/usr/lib/libobjc.tbd" ] || return 1
    phase2_tbd_is_x86_target "$sys/usr/lib/libobjc.tbd" || return 1
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
    # Maps that name a header which is not on disk are not a working Clang Darwin.
    phase2_darwin_modulemap_headers_ok "$sys" || return 1
    # FileManager/sdk-gap measurement set (shared list). Missing removefile.h
    # is the class that failed FE with 14 errors after recipe x86.2.
    phase2_measurement_headers_ok "$sys"
}

# Print one `header "…"` path per line. Skip `exclude header`.
phase2_modulemap_quoted_headers() {
    local map=$1
    [ -f "$map" ] || return 0
    grep -E 'header[[:space:]]+"' "$map" | grep -v 'exclude[[:space:]]\+header' \
        | sed 's/.*header[[:space:]]*"\([^"]*\)".*/\1/'
}

# Comma-separated header paths named by staged modulemaps that do not resolve
# under usr/include. Return 1 if any are missing (so a restage that wrote maps
# without `_modules/*.h` cannot look satisfied).
phase2_darwin_modulemap_missing_headers() {
    local sys=$1 inc=$1/usr/include
    local map rel miss=""
    [ -d "$inc" ] || return 0
    while IFS= read -r map; do
        [ -n "$map" ] || continue
        while IFS= read -r rel; do
            [ -n "$rel" ] || continue
            [ -f "$inc/$rel" ] && continue
            case ",$miss," in
                *",$rel,"*) ;;
                *) miss="${miss:+$miss,}$rel" ;;
            esac
        done < <(phase2_modulemap_quoted_headers "$map")
    done < <(find "$inc" -name '*.modulemap' -print | sort)
    if [ -n "$miss" ]; then
        printf '%s\n' "$miss"
        return 1
    fi
    return 0
}

phase2_darwin_modulemap_headers_ok() {
    phase2_darwin_modulemap_missing_headers "$1" >/dev/null
}

# Comma-separated paths from the shared measurement-header list that are not
# under $sys/usr/include. Return 1 if any are missing (so a restage that
# skipped the FileManager set cannot look satisfied).
phase2_measurement_headers_missing() {
    local sys=$1 inc=$1/usr/include
    local h miss=""
    while IFS= read -r h; do
        [ -n "$h" ] || continue
        [ -f "$inc/$h" ] && continue
        case ",$miss," in
            *",$h,"*) ;;
            *) miss="${miss:+$miss,}$h" ;;
        esac
    done < <(fe_sysroot_measurement_headers)
    if [ -n "$miss" ]; then
        printf '%s\n' "$miss"
        return 1
    fi
    return 0
}

phase2_measurement_headers_ok() {
    phase2_measurement_headers_missing "$1" >/dev/null
}

# stage_absent semantics from arm64 sysroot_fe4: skip if already present
# (would shadow machorun/sdk or sdk-gaps); copy if the arm64 tree has it.
phase2_stage_measurement_headers_from_arm() {
    local sys=$1 arm=$2
    local h dest
    while IFS= read -r h; do
        [ -n "$h" ] || continue
        dest="$sys/usr/include/$h"
        if [ -e "$dest" ]; then
            echo "  REFUSED (already present, would shadow): $h" >&2
            continue
        fi
        [ -f "$arm/usr/include/$h" ] || continue
        mkdir -p "$(dirname "$dest")"
        cp "$arm/usr/include/$h" "$dest"
        echo "  + $h   [measurement set from arm64 sysroot_fe4]"
    done < <(fe_sysroot_measurement_headers)
}

# Same clang argv as full/scripts/build_full.sh. build_fe.sh is Swift-only
# on both arches; arm64 compiles this .c in the full link step, not there.
phase2_compile_removefile_compat() {
    local sys=$1 dest=$2 target=$3 src_tree=$4
    mkdir -p "$(dirname "$dest")"
    clang-18 -target "$target" -isysroot "$sys" -std=c11 -O2 \
        -Wall -Wextra -Werror -I "$src_tree/full/foundation" \
        -c "$src_tree/full/foundation/removefile_compat.c" \
        -o "$dest"
}

# Enumerate files the arm64 generator run wrote: Darwin-family maps,
# everything under usr/include/_modules/ (shim names come from Apple's maps,
# not a hardcoded list), and any other usr/include file that names
# gen_darwin_modulemap.py. Never copies module.modulemap (ObjectiveC; merge).
phase2_arm_generator_include_files() {
    local arm=$1 inc=$1/usr/include
    local f
    [ -d "$inc" ] || return 0
    while IFS= read -r -d '' f; do
        printf '%s\0' "$f"
    done < <(find "$inc" -maxdepth 1 -type f -name '*.modulemap' -print0 2>/dev/null || true)
    if [ -d "$inc/_modules" ]; then
        while IFS= read -r -d '' f; do
            printf '%s\0' "$f"
        done < <(find "$inc/_modules" -type f -print0)
    fi
    if grep -rl --include='*' 'gen_darwin_modulemap.py' "$inc" >/dev/null 2>&1; then
        while IFS= read -r -d '' f; do
            printf '%s\0' "$f"
        done < <(grep -rlZ 'gen_darwin_modulemap.py' "$inc")
    fi
}

phase2_copy_darwin_modulemaps_from_arm() {
    local sys=$1 arm=$2
    local f rel dest base copied_maps=0 copied_extra=0 line
    local -A seen=()
    [ -d "$arm/usr/include" ] || return 1
    mkdir -p "$sys/usr/include"
    while IFS= read -r -d '' f; do
        [ -f "$f" ] || continue
        rel=${f#"$arm/usr/include/"}
        [ -n "$rel" ] || continue
        [ "${seen[$rel]+x}" ] && continue
        seen[$rel]=1
        base=$(basename "$rel")
        if [ "$rel" = module.modulemap ] || [ "$base" = module.modulemap ]; then
            continue
        fi
        dest="$sys/usr/include/$rel"
        mkdir -p "$(dirname "$dest")"
        cp -a "$f" "$dest"
        case "$rel" in
            *.modulemap) copied_maps=$((copied_maps + 1)) ;;
            *) copied_extra=$((copied_extra + 1)) ;;
        esac
    done < <(phase2_arm_generator_include_files "$arm")
    if [ -f "$arm/usr/include/module.modulemap" ] && [ -f "$sys/usr/include/module.modulemap" ]; then
        while IFS= read -r line; do
            grep -qxF "$line" "$sys/usr/include/module.modulemap" && continue
            printf '%s\n' "$line" >> "$sys/usr/include/module.modulemap"
        done < <(grep -E '^(extern module |// Appended by machorun)' \
            "$arm/usr/include/module.modulemap" || true)
    fi
    # Any header a staged map names that still is not in the x86 include tree
    # but is on the arm64 sysroot (generator output we did not classify above).
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        [ -f "$sys/usr/include/$rel" ] && continue
        [ -f "$arm/usr/include/$rel" ] || continue
        mkdir -p "$(dirname "$sys/usr/include/$rel")"
        cp -a "$arm/usr/include/$rel" "$sys/usr/include/$rel"
        copied_extra=$((copied_extra + 1))
    done < <(find "$sys/usr/include" -name '*.modulemap' -print | sort | while IFS= read -r map; do
        phase2_modulemap_quoted_headers "$map"
    done)
    echo "  copied $copied_maps Darwin-family modulemaps and $copied_extra generator files from $arm"
    [ "$copied_maps" -gt 0 ]
}

# Mirror full/foundation/stage_fe_sysroot.sh: base module.modulemap is already
# written; run gen_darwin_modulemap.py against THIS sysroot. The generator
# reads Xcode, so on Linux it fails; then copy the pruned family from the arm64
# sysroot (same headers, already generated on macOS). Print git/python errors
# instead of folding them into "not at pin" / "overlays absent".
phase2_install_darwin_modulemaps() {
    local sys=$1 arm=$2 gen=$3
    local err rc miss
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
            miss=$(phase2_darwin_modulemap_missing_headers "$sys" || true)
            if [ -n "$miss" ]; then
                echo "  Darwin.modulemap present but header paths do not resolve: $miss"
                return 1
            fi
            echo "  Darwin.modulemap present; all header paths resolve"
            return 0
        fi
        echo "  gen_darwin_modulemap.py exit ${rc:-ABSENT} ($(phase2_flatten < "$err")); copying pruned maps from arm64 sysroot"
        rm -f "$err"
    else
        echo "  gen_darwin_modulemap.py ABSENT at $gen; copying pruned maps from arm64 sysroot"
    fi
    phase2_copy_darwin_modulemaps_from_arm "$sys" "$arm" || true
    if [ -f "$sys/usr/include/Darwin.modulemap" ]; then
        miss=$(phase2_darwin_modulemap_missing_headers "$sys" || true)
        if [ -n "$miss" ]; then
            echo "  Darwin.modulemap present but header paths do not resolve: $miss"
            return 1
        fi
        echo "  Darwin.modulemap present; all header paths resolve"
        return 0
    fi
    echo "  no Darwin.modulemap (generator needs Xcode; arm64 sysroot had none to copy)"
    return 1
}

# One line: swiftmodule=PRESENT|ABSENT swiftinterface=PRESENT|ABSENT
# Arm64 FE compiles Darwin.swiftinterface with 6.2.4; Apple's overlay is
# textual (SPIKE.md: 0 binary modules under usr/lib/swift). A prebuilt
# .swiftmodule would skip compiling the interface; x86 copies the x86_64
# sibling when that file exists, and otherwise takes the same compile-the-
# interface path. The 6.2.1-vs-6.2.4 "SDK is not supported" line is the
# fallback when Clang Darwin fails (missing maps or missing _modules headers),
# not a flag arm64 passes.
phase2_darwin_overlay_slice() {
    local root=$1 triple=$2
    local dir=$root/usr/lib/swift/Darwin.swiftmodule
    local sm=ABSENT si=ABSENT
    [ -f "$dir/${triple}.swiftmodule" ] && sm=PRESENT
    [ -f "$dir/${triple}.swiftinterface" ] && si=PRESENT
    [ -f "$root/usr/lib/swift/Darwin.swiftinterface" ] && si=PRESENT
    printf 'swiftmodule=%s swiftinterface=%s' "$sm" "$si"
}

phase2_report_darwin_overlay_path() {
    local sys=$1 arm=$2
    local arm_s x86_s
    arm_s=$(phase2_darwin_overlay_slice "$arm" arm64-apple-macos)
    x86_s=$(phase2_darwin_overlay_slice "$sys" x86_64-apple-macos)
    echo "  Darwin overlay arm64-apple-macos ($arm): $arm_s"
    echo "  Darwin overlay x86_64-apple-macos ($sys): $x86_s"
    case "$arm_s" in
        swiftmodule=PRESENT*)
            echo "  arm64 has a prebuilt Darwin.swiftmodule beside the interface (interface is not compiled). x86 uses the x86_64 sibling if PRESENT; no version-check disable."
            ;;
        *)
            echo "  arm64 compiles Darwin.swiftinterface (no prebuilt .swiftmodule). 6.2.1-vs-6.2.4 is a fallback when Clang Darwin fails; x86 takes the same path. No version-check disable."
            ;;
    esac
}

# One directory spelling per inode. phase2's /w -> $W symlink makes
# $W/scratch/modcache_fe4 and /w/scratch/modcache_fe4 the same files; clang
# then reports '_DarwinFoundation2' defined in both .pcm paths.
phase2_canonical_dir() {
    local d=$1 p
    mkdir -p "$d"
    p=$(realpath -P "$d" 2>/dev/null || readlink -f "$d")
    [ -n "$p" ] || { echo "phase2_canonical_dir: empty realpath for $d" >&2; return 1; }
    printf '%s\n' "$p"
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

# Nine FE overlay dylibs. Keep in lockstep with full/scripts/build_full.sh FE_OVERLAYS
# and scripts/env/prepare.py FE_OVERLAY_DYLIBS. x86 copies come from the
# swiftcore-macho stdlib cross-build (artifacts/swift-macosx/x86_64/), never
# from CoreSimulator (those overlay files are arm64-only non-fat).
phase2_fe_overlay_names() {
    printf '%s\n' \
        libswiftDarwin.dylib \
        libswiftSynchronization.dylib \
        libswift_Builtin_float.dylib \
        libswift_DarwinFoundation1.dylib \
        libswift_DarwinFoundation2.dylib \
        libswift_DarwinFoundation3.dylib \
        libswift_RegexParser.dylib \
        libswift_StringProcessing.dylib \
        libswift_errno.dylib
}

# Durable x86 overlay set: nine FE + the three build_full / widget-gate loads
# (expected_swiftui_loads: _Concurrency, ObjectiveC, Observation). Each needs
# an x86 .tbd under sysroot usr/lib/swift and the dylib in both mrroot-x86_64
# and mrroot_fe-x86_64. Sources: cross-built artifacts first, then
# scratch/apple-x86-overlays (ObjectiveC / _DarwinFoundation* / _errno).
phase2_twelve_overlay_names() {
    phase2_fe_overlay_names
    printf '%s\n' \
        libswift_Concurrency.dylib \
        libswiftObjectiveC.dylib \
        libswiftObservation.dylib
}

# scratch/apple-x86-overlays is operator-staged (never committed): Apple's
# x86_64 overlays extracted from the operator Mac's dyld shared cache with a
# PROVENANCE.txt (macOS build, tool, sha256s). It is the only source for the
# four Apple-SDK overlays the open-source stdlib cannot build on Linux
# (_DarwinFoundation1/2/3, _errno; PR #24). The cross-build stays first.
phase2_x86_overlay_search_dirs() {
    printf '%s\n' \
        "${W:?}/swiftcore-macho/artifacts/swift-macosx/x86_64" \
        "${W:?}/scratch/apple-x86-overlays" \
        "${HOME}/work/build/lib/swift/macosx/x86_64" \
        "${HOME}/work/build/lib/swift/macosx"
}

# Print the first x86 Mach-O overlay path for $1, or return 1.
phase2_find_x86_overlay() {
    local name=$1 dir
    while IFS= read -r dir; do
        [ -n "$dir" ] || continue
        if [ -f "$dir/$name" ] && phase2_is_x86_macho "$dir/$name"; then
            printf '%s\n' "$dir/$name"
            return 0
        fi
    done < <(phase2_x86_overlay_search_dirs)
    return 1
}

# Stage FE overlays into $1/darwin/usr/lib/swift/. Prints OK or MISSING=a,b,c.
# Missing overlays are a named CANNOT_X86_OVERLAYS_NOT_BUILT, not the macOS
# CoreSimulator marker.
phase2_stage_x86_fe_overlays() {
    local dest=$1
    local swift=$dest/darwin/usr/lib/swift
    mkdir -p "$swift"
    local missing=() name src
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        if src=$(phase2_find_x86_overlay "$name"); then
            cp -f "$src" "$swift/$name"
        else
            missing+=("$name")
        fi
    done < <(phase2_twelve_overlay_names)
    if [ "${#missing[@]}" -eq 0 ]; then
        printf 'OK\n'
        return 0
    fi
    local IFS=,
    printf 'MISSING=%s\n' "${missing[*]}"
    return 1
}

# Assemble scratch/mrroot${FULL_OUT_SUFFIX}: x86 ELF loader + x86 darwin
# userland + x86 libswiftCore. Analog of macOS-only scripts/stage_swift_runtime.sh,
# whose Swift OVERLAYS are arm64-only; those belong in mrroot_fe-x86_64 from
# the stdlib cross-build instead.
#   phase2_stage_x86_base_mrroot <dest> <loader> <darwin-root> <x86-libswiftCore>
phase2_stage_x86_base_mrroot() {
    local dest=$1 loader=$2 darwin_root=$3 x86_core=$4
    local rel d
    mkdir -p "$dest/darwin/usr/lib/swift" "$dest/host"
    if [ -x "$loader" ]; then
        cp -f "$loader" "$dest/machorun"
        chmod a+x "$dest/machorun"
    fi
    if [ -d "$darwin_root/usr/lib" ]; then
        while IFS= read -r -d '' d; do
            rel=${d#"$darwin_root/usr/lib/"}
            case "$rel" in
                swift/libswiftCore.dylib) continue ;;
            esac
            if phase2_is_x86_macho "$d"; then
                mkdir -p "$dest/darwin/usr/lib/$(dirname "$rel")"
                cp -a "$d" "$dest/darwin/usr/lib/$rel"
            fi
        done < <(find "$darwin_root/usr/lib" -type f -name '*.dylib' -print0 2>/dev/null)
    fi
    if [ -d "$darwin_root/System" ]; then
        mkdir -p "$dest/darwin/System"
        cp -a "$darwin_root/System/." "$dest/darwin/System/"
    fi
    if [ -f "$x86_core" ] && phase2_is_x86_macho "$x86_core"; then
        cp -f "$x86_core" "$dest/darwin/usr/lib/swift/libswiftCore.dylib"
    fi
    # Host Linux boundary: copy libdispatch.so / libBlocksRuntime.so from the
    # resolved Swift runtime dir, then build the four Open* helpers as ELF
    # x86_64. Incomplete host/ is CANNOT_X86_HOST_RUNTIME in phase2.sh.
    phase2_stage_x86_host_runtime "$dest" "$PHASE2_REPO" >/dev/null || true
}

# ELF 64-bit x86-64 shared object, regular file. Rejects arm64 ELF, Mach-O,
# text fixtures, and symlinks (build_full.sh requires regular files).
phase2_is_elf_x86_so() {
    local f=$1
    [ -f "$f" ] && [ ! -L "$f" ] || return 1
    file -b "$f" | grep -q 'ELF 64-bit LSB shared object, x86-64'
}

phase2_drop_unless_elf_x86_so() {
    local f=$1
    if phase2_is_elf_x86_so "$f"; then
        return 0
    fi
    rm -f "$f"
    return 1
}

# Record sha256 of every staged ELF x86-64 host runtime file.
phase2_record_host_runtime_sha256() {
    local dest=$1
    local host=$dest/host
    local name
    mkdir -p "$host"
    {
        echo "# sha256 of staged host runtime files"
        while IFS= read -r name; do
            [ -n "$name" ] || continue
            if phase2_is_elf_x86_so "$host/$name"; then
                sha256sum "$host/$name"
            fi
        done < <(openuikit_host_runtime_files)
    } > "$host/SHA256SUMS"
}

# Copy toolchain HOST_RUNTIME_FILES (libdispatch.so, libBlocksRuntime.so) from
# the resolved Swift linux lib dir, then BUILD the four Open* helpers as ELF
# x86_64 through the committed recipes. Never copies Open* (including arm64
# ELF leftover in the linux dir). Optional $2 is the repo root. Prints OK or
# MISSING=a,b,c naming each file that is not ELF x86-64.
phase2_stage_x86_host_runtime() {
    local dest=$1 repo=${2:-}
    local host=$dest/host
    local linux_lib src name missing
    mkdir -p "$host"
    linux_lib=$(openuikit_resolve_swift_linux_lib)
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        src=$linux_lib/$name
        if [ -e "$src" ]; then
            cp -fL "$src" "$host/$name"
        fi
        phase2_drop_unless_elf_x86_so "$host/$name" || true
    done < <(openuikit_host_runtime_toolchain_files)
    if [ -n "$repo" ]; then
        phase2_build_x86_host_helpers "$dest" "$repo" || true
    fi
    phase2_record_host_runtime_sha256 "$dest"
    missing=$(phase2_host_runtime_missing "$dest")
    if [ -z "$missing" ]; then
        printf 'OK\n'
        return 0
    fi
    printf 'MISSING=%s\n' "$missing"
    return 1
}

# Comma-separated HOST_RUNTIME_FILES that are not ELF x86-64 regular files.
phase2_host_runtime_missing() {
    local dest=$1
    local host=$dest/host
    local name missing=()
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        if ! phase2_is_elf_x86_so "$host/$name"; then
            missing+=("$name")
        fi
    done < <(openuikit_host_runtime_files)
    if [ "${#missing[@]}" -eq 0 ]; then
        return 0
    fi
    local IFS=,
    printf '%s\n' "${missing[*]}"
}

# Build the four Open* helpers through committed scripts. Skip a helper that
# is already ELF x86-64. Rebuild (do not keep) arm64 ELF / text / Mach-O.
# libOpenDispatchHost.so uses full/dispatch/build_host_bridge.sh; the other
# three use sibling build_host_helper.sh recipes. Does not stub missing libs.
phase2_build_x86_host_helpers() {
    local dest=$1 repo=$2
    local host=$dest/host
    local work=$dest/host-work
    mkdir -p "$host" "$work"

    if ! phase2_is_elf_x86_so "$host/libOpenDispatchHost.so"; then
        rm -f "$host/libOpenDispatchHost.so"
        if phase2_is_elf_x86_so "$host/libdispatch.so" \
            && phase2_is_elf_x86_so "$host/libBlocksRuntime.so" \
            && [ -f "$repo/full/dispatch/build_host_bridge.sh" ]; then
            set +e
            bash "$repo/full/dispatch/build_host_bridge.sh" \
                --repo "$repo" \
                --host-dir "$host" \
                --work-dir "$work" \
                --skip-runtime-pin \
                --host-abi "ELF64-$(uname -m)" \
                --refuse-prefix 'phase2_host_runtime: ' \
                >"$work/build_host_bridge.log" 2>&1
            set -e
        fi
        phase2_drop_unless_elf_x86_so "$host/libOpenDispatchHost.so" || true
    fi

    if ! phase2_is_elf_x86_so "$host/libOpenFoundationInternationalizationHost.so"; then
        rm -f "$host/libOpenFoundationInternationalizationHost.so"
        if [ -f "$repo/full/foundationinternationalization/build_host_helper.sh" ]; then
            set +e
            bash "$repo/full/foundationinternationalization/build_host_helper.sh" \
                --repo "$repo" \
                --host-dir "$host" \
                >"$work/OpenFoundationInternationalizationHost.log" 2>&1
            set -e
        fi
        phase2_drop_unless_elf_x86_so \
            "$host/libOpenFoundationInternationalizationHost.so" || true
    fi

    if ! phase2_is_elf_x86_so "$host/libOpenURLTransportHost.so"; then
        rm -f "$host/libOpenURLTransportHost.so"
        if [ -f "$repo/full/urltransport/build_host_helper.sh" ]; then
            set +e
            bash "$repo/full/urltransport/build_host_helper.sh" \
                --repo "$repo" \
                --host-dir "$host" \
                >"$work/OpenURLTransportHost.log" 2>&1
            set -e
        fi
        phase2_drop_unless_elf_x86_so "$host/libOpenURLTransportHost.so" || true
    fi

    if ! phase2_is_elf_x86_so "$host/libOpenRelativeTimeHost.so"; then
        rm -f "$host/libOpenRelativeTimeHost.so"
        if [ -f "$repo/full/relativetime/build_host_helper.sh" ]; then
            set +e
            bash "$repo/full/relativetime/build_host_helper.sh" \
                --repo "$repo" \
                --host-dir "$host" \
                >"$work/OpenRelativeTimeHost.log" 2>&1
            set -e
        fi
        phase2_drop_unless_elf_x86_so "$host/libOpenRelativeTimeHost.so" || true
    fi
}

# Closed BASE_RUNTIME_SOURCE Darwin/System/usr paths build_full.sh reads
# (plus host/, checked as ELF). FE overlays are listed separately against
# FE_RUNTIME_SOURCE. Leaf names are unique across this set.
phase2_base_layout_macho_names() {
    printf '%s\n' \
        darwin/System/Library/Frameworks/Foundation.framework/Foundation \
        darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation \
        darwin/usr/lib/libswiftcompat.dylib \
        darwin/usr/lib/swift/libswiftCore.dylib \
        darwin/usr/lib/swift/libswiftObjectiveC.dylib \
        darwin/usr/lib/swift/libswift_Concurrency.dylib \
        darwin/usr/lib/swift/libswiftObservation.dylib
}

phase2_layout_leaf() {
    local p=$1
    printf '%s\n' "${p##*/}"
}

# Build the extensionless Foundation/CoreFoundation loud-abort stubs with
# scripts/build_runtime_shims.sh (STUBS_ONLY, x86_64-apple-macos). Do not copy
# arm64 stubs from scratch/mrroot.
phase2_fill_x86_loud_abort_stubs() {
    local dest=$1 repo=$2 sys=$3
    local fw=$dest/darwin/System/Library/Frameworks
    local work=$dest/shim-work
    local log=$work/build_runtime_shims.log
    mkdir -p "$fw/Foundation.framework" "$fw/CoreFoundation.framework" "$work"
    if phase2_is_x86_macho "$fw/Foundation.framework/Foundation" \
        && phase2_is_x86_macho "$fw/CoreFoundation.framework/CoreFoundation"; then
        return 0
    fi
    rm -f "$fw/Foundation.framework/Foundation" \
        "$fw/CoreFoundation.framework/CoreFoundation"
    set +e
    ROOT="$repo" W="$repo" SYS="$sys" OUT="$work" \
        TARGET="${TARGET:-x86_64-apple-macos15.0}" MINOS=15.0 \
        STUBS_ONLY=1 \
        bash "$repo/scripts/build_runtime_shims.sh" >"$log" 2>&1
    set -e
    if [ -f "$work/Foundation.stub.dylib" ]; then
        cp -f "$work/Foundation.stub.dylib" "$fw/Foundation.framework/Foundation"
    fi
    if [ -f "$work/CoreFoundation.stub.dylib" ]; then
        cp -f "$work/CoreFoundation.stub.dylib" \
            "$fw/CoreFoundation.framework/CoreFoundation"
    fi
    if ! phase2_is_x86_macho "$fw/Foundation.framework/Foundation"; then
        rm -f "$fw/Foundation.framework/Foundation"
    fi
    if ! phase2_is_x86_macho "$fw/CoreFoundation.framework/CoreFoundation"; then
        rm -f "$fw/CoreFoundation.framework/CoreFoundation"
    fi
}

# libswiftcompat.dylib via swiftcore-macho/scripts/build_compat.sh. Never copy
# artifacts/libswiftcompat.dylib is arm64; always rebuild through the committed
# recipe. The x86 FE sysroot vends libSystem.B.tbd / libc++.1.tbd; the
# committed link line is -lSystem -lc++, so a private alias SDK provides those
# leaf names without mutating sysroot.
phase2_prepare_compat_alias_sdk() {
    local sys=$1 alias=$2 f
    rm -rf "$alias"
    mkdir -p "$alias/usr/lib"
    if [ -d "$sys/usr/include" ]; then
        ln -sfn "$sys/usr/include" "$alias/usr/include"
    fi
    if [ -d "$sys/usr/lib" ]; then
        for f in "$sys/usr/lib/"*; do
            [ -e "$f" ] || continue
            ln -sfn "$f" "$alias/usr/lib/$(basename "$f")"
        done
    fi
    if [ -e "$alias/usr/lib/libSystem.B.tbd" ] && [ ! -e "$alias/usr/lib/libSystem.tbd" ]; then
        ln -sfn libSystem.B.tbd "$alias/usr/lib/libSystem.tbd"
    fi
    if [ -e "$alias/usr/lib/libc++.1.tbd" ] && [ ! -e "$alias/usr/lib/libc++.tbd" ]; then
        ln -sfn libc++.1.tbd "$alias/usr/lib/libc++.tbd"
    fi
}

phase2_fill_x86_libswiftcompat() {
    local dest=$1 repo=$2 sys=$3 loader=${4:-}
    local out=$dest/darwin/usr/lib/libswiftcompat.dylib
    local mrlib=$repo/machorun/darwin/usr/lib
    local src_dir=$repo/swiftcore-macho/sdk/compat
    local work=$dest/shim-work
    local log=$work/build_compat.log
    local alias=$work/compat-sdk
    mkdir -p "$(dirname "$out")" "$work"
    if phase2_is_x86_macho "$out"; then
        return 0
    fi
    rm -f "$out"
    if [ ! -f "$src_dir/swiftcompat.c" ] || [ ! -f "$src_dir/shim.cpp" ]; then
        return 1
    fi
    phase2_prepare_compat_alias_sdk "$sys" "$alias"
    set +e
    W="$dest" SDK="$alias" SRC="$src_dir" MRLIB="$mrlib" LOADER="$loader" \
        OUT="$out" NM=llvm-nm-18 \
        bash "$repo/swiftcore-macho/scripts/build_compat.sh" >"$log" 2>&1
    set -e
    if ! phase2_is_x86_macho "$out"; then
        rm -f "$out"
        return 1
    fi
}

# Stage BASE swift runtime dylibs that exist as x86 Mach-O in the overlay
# search dirs (stdlib cross-build / operator Apple overlays). Never copy arm64.
phase2_fill_x86_base_swift_dylibs() {
    local dest=$1
    local swift=$dest/darwin/usr/lib/swift
    local name src
    mkdir -p "$swift"
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        if phase2_is_x86_macho "$swift/$name"; then
            continue
        fi
        rm -f "$swift/$name"
        if src=$(phase2_find_x86_overlay "$name"); then
            cp -f "$src" "$swift/$name"
        fi
    done < <(phase2_twelve_overlay_names)
}

# Fill what the committed recipes can produce, then print OK or MISSING=…
# naming every BASE/FE/host path build_full.sh still lacks as x86 Mach-O
# (host files: ELF x86-64).
phase2_stage_x86_mrroot_layout() {
    local dest=$1 fe=$2 repo=$3 sys=$4 loader=$5
    local missing=() rel leaf host name
    mkdir -p "$dest"
    phase2_fill_x86_loud_abort_stubs "$dest" "$repo" "$sys" || true
    phase2_fill_x86_libswiftcompat "$dest" "$repo" "$sys" "$loader" || true
    phase2_fill_x86_base_swift_dylibs "$dest" || true

    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        leaf=$(phase2_layout_leaf "$rel")
        if ! phase2_is_x86_macho "$dest/$rel"; then
            missing+=("$leaf")
        fi
    done < <(phase2_base_layout_macho_names)

    while IFS= read -r name; do
        [ -n "$name" ] || continue
        if ! phase2_is_elf_x86_so "$dest/host/$name"; then
            missing+=("$name")
        fi
    done < <(openuikit_host_runtime_files)

    while IFS= read -r name; do
        [ -n "$name" ] || continue
        if ! phase2_is_x86_macho "$dest/darwin/usr/lib/swift/$name"; then
            missing+=("$name")
        fi
        if ! phase2_is_x86_macho "$fe/darwin/usr/lib/swift/$name"; then
            missing+=("$name")
        fi
    done < <(phase2_twelve_overlay_names)

    if [ "${#missing[@]}" -eq 0 ]; then
        printf 'OK\n'
        return 0
    fi
    local uniq
    uniq=$(printf '%s\n' "${missing[@]}" | sort -u)
    printf 'MISSING=%s\n' "$(printf '%s\n' "$uniq" | paste -sd, -)"
    return 1
}

# shellcheck source=ud_guest.inc
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ud_guest.inc"

