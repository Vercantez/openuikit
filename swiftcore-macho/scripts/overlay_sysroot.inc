# overlay_sysroot.inc -- sourced. Input-keyed Darwin overlay sysroot staging.
#
# A refuse-overwrite over a pre-existing $W/sdk/MacOSX.sdk is a stale artefact
# every gate misses: stage_overlay_darwin.sh would skip Intel math.h / MacTypes
# / Darwin.modulemap, cmake would still point -sdk at the old tree, and Darwin.o
# would reprint fmaxl / extern_proc. Key reuse on INPUT content (like phase-2's
# .phase2-stage-inputs), not on the output directory existing.
#
# Mismatch → stage into a fresh directory we create. Never rm a tree we did
# not create this run; displace the live MacOSX.sdk aside (.stale-<utc>).
#
# Stamp covers the overlay-darwin header set + Darwin.modulemap recipe
# (stage_overlay_darwin.sh + enumerated module headers) + machorun sys/proc.h.
# Required *staged* headers (ConditionalMacros.h included) must be present in
# the dest tree: input-sha MATCH of the pin is not completeness. .tbd stubs
# from machorun gen_tbd / the displaced tree are copied into the fresh dest
# before the live MacOSX.sdk is moved aside.
#
# Staged Darwin*.modulemap files name headers (complex.h, …). Those files must
# resolve under usr/include before cmake — the same closure phase2 already
# checks (phase2_darwin_modulemap_missing_headers). Source them from the FE
# sysroot / full/sdk-gaps / machorun / overlay-darwin pins.

if [ -n "${SWIFTCORE_OVERLAY_SYSROOT_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
SWIFTCORE_OVERLAY_SYSROOT_INC=1

_overlay_sysroot_inc_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWIFTCORE_ROOT=${SWIFTCORE_ROOT:-$(cd "$_overlay_sysroot_inc_dir/.." && pwd)}
OPENUIKIT_ROOT=${OPENUIKIT_ROOT:-$(cd "$SWIFTCORE_ROOT/.." && pwd)}

# Reuse phase2's modulemap quoted-header enumeration (scripts/x86/test_phase2.sh
# maps-only restage). Do not reimplement the grep/sed.
# shellcheck disable=SC1091
. "$OPENUIKIT_ROOT/scripts/x86/common.inc"

# Bump when staging steps, the Darwin.modulemap header list, modulemap
# header closure, or the required staged-header / tbd completeness gate change.
OVERLAY_SYSROOT_RECIPE=overlay-darwin.3
OVERLAY_SYSROOT_STAMP=.overlay-sysroot-inputs

# Same enumeration as stage_overlay_darwin.sh DARWIN_MODULE_HEADERS.
OVERLAY_DARWIN_MODULE_HEADERS=(
  signal.h
  sys/signal.h
  stdio.h
  _stdio.h
  sys/proc.h
  sys/mman.h
  math.h
  os/base.h
  os/lock.h
  dlfcn.h
)

# Staged-tree surface that must exist after restage. Printed before ninja;
# absence is CANNOT_OVERLAY_SYSROOT_HEADER, not stamp=MATCH.
OVERLAY_SYSROOT_REQUIRED_HEADERS=(
  usr/include/math.h
  usr/include/sys/proc.h
  usr/include/MacTypes.h
  usr/include/ConditionalMacros.h
  usr/include/Darwin.modulemap
)

OVERLAY_SYSROOT_DEST=
OVERLAY_SYSROOT_REUSE=0
OVERLAY_SYSROOT_DISPLACED=
OVERLAY_SYSROOT_TBD_SEARCHED=()

overlay_sysroot_sha_or_absent() {
    local f=$1
    if [ -f "$f" ]; then
        sha256sum "$f" | awk '{print $1}'
    else
        printf 'ABSENT\n'
    fi
}

overlay_sysroot_proc_h() {
    local cand
    for cand in \
        ${W:+$W/machorun-sdk/usr/include/sys/proc.h} \
        "$OPENUIKIT_ROOT/machorun/sdk/usr/include/sys/proc.h"
    do
        [ -n "$cand" ] || continue
        if [ -f "$cand" ]; then
            printf '%s\n' "$cand"
            return 0
        fi
    done
    return 1
}

# overlay_sysroot_input_lines
# recipe + sha of the overlay-darwin header set + modulemap recipe + proc.h.
overlay_sysroot_input_lines() {
    local src=$SWIFTCORE_ROOT/sdk/overlay-darwin
    local proc
    proc=$(overlay_sysroot_proc_h || true)
    printf 'recipe=%s\n' "$OVERLAY_SYSROOT_RECIPE"
    printf 'overlay-darwin.math.h=%s\n' "$(overlay_sysroot_sha_or_absent "$src/math.h")"
    printf 'overlay-darwin.MacTypes.h=%s\n' "$(overlay_sysroot_sha_or_absent "$src/MacTypes.h")"
    printf 'overlay-darwin.ConditionalMacros.h=%s\n' \
        "$(overlay_sysroot_sha_or_absent "$src/ConditionalMacros.h")"
    printf 'overlay-darwin.i386.math.h=%s\n' \
        "$(overlay_sysroot_sha_or_absent "$src/architecture/i386/math.h")"
    printf 'stage_overlay_darwin.sh=%s\n' \
        "$(overlay_sysroot_sha_or_absent "$_overlay_sysroot_inc_dir/stage_overlay_darwin.sh")"
    printf 'Darwin.modulemap.headers=%s\n' \
        "$(printf '%s\n' "${OVERLAY_DARWIN_MODULE_HEADERS[@]}" | sha256sum | awk '{print $1}')"
    printf 'required.headers=%s\n' \
        "$(printf '%s\n' "${OVERLAY_SYSROOT_REQUIRED_HEADERS[@]}" | sha256sum | awk '{print $1}')"
    printf 'modulemap.closure=phase2_darwin_modulemap_missing_headers\n'
    printf 'machorun.sys/proc.h=%s\n' "$(overlay_sysroot_sha_or_absent "${proc:-}")"
}

overlay_sysroot_write_stamp() {
    local dest=${1:?overlay_sysroot_write_stamp: dest tree}
    overlay_sysroot_input_lines > "$dest/$OVERLAY_SYSROOT_STAMP"
}

# Print "key old->new" (and stamp=ABSENT). Return 0 iff stamp matches expected.
overlay_sysroot_stamp_diff() {
    local stamp=$1
    local expected key val old changed=0
    expected=$(overlay_sysroot_input_lines)
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

overlay_sysroot_inputs_id() {
    overlay_sysroot_input_lines | sha256sum | awk '{print substr($1,1,16)}'
}

overlay_sysroot_has_fmaxl() {
    local h=$1
    [ -f "$h" ] && grep -Eq '(^|[[:space:]*])fmaxl[[:space:]]*\(' "$h"
}

overlay_sysroot_has_extern_proc() {
    local h=$1
    [ -f "$h" ] && grep -Eq 'extern_proc' "$h"
}

# Print each required header's path, sha, and the fmaxl / extern_proc bits.
# overlay_sysroot_print_headers <sdk>
overlay_sysroot_print_headers() {
    local sdk=${1:?overlay_sysroot_print_headers: sdk}
    local rel h
    echo "overlay_sysroot: tree=$sdk"
    if [ -L "$sdk" ]; then
        echo "overlay_sysroot: symlink -> $(readlink "$sdk")"
    fi
    if [ -d "$sdk" ] || [ -L "$sdk" ]; then
        echo "overlay_sysroot: realpath=$(realpath "$sdk" 2>/dev/null || echo UNRESOLVED)"
    else
        echo "overlay_sysroot: realpath=ABSENT"
    fi
    for rel in usr/include/math.h usr/include/sys/proc.h usr/include/MacTypes.h \
               usr/include/ConditionalMacros.h usr/include/Darwin.modulemap \
               usr/include/os/lock.h usr/include/dlfcn.h; do
        h=$sdk/$rel
        if [ -f "$h" ]; then
            printf 'overlay_sysroot: header %s present sha256=%s' \
                "$rel" "$(overlay_sysroot_sha_or_absent "$h")"
            case "$rel" in
                usr/include/math.h)
                    if overlay_sysroot_has_fmaxl "$h"; then
                        printf ' fmaxl=yes'
                    else
                        printf ' fmaxl=NO'
                    fi
                    ;;
                usr/include/sys/proc.h)
                    if overlay_sysroot_has_extern_proc "$h"; then
                        printf ' extern_proc=yes'
                    else
                        printf ' extern_proc=NO'
                    fi
                    ;;
            esac
            printf '\n'
        else
            echo "overlay_sysroot: header $rel ABSENT"
        fi
    done
    overlay_sysroot_print_modulemap_closure "$sdk"
    overlay_sysroot_print_tbds "$sdk"
    if [ -f "$sdk/$OVERLAY_SYSROOT_STAMP" ]; then
        echo "overlay_sysroot: stamp=$sdk/$OVERLAY_SYSROOT_STAMP"
        if overlay_sysroot_stamp_diff "$sdk/$OVERLAY_SYSROOT_STAMP" >/dev/null; then
            if overlay_sysroot_tree_complete "$sdk"; then
                echo "overlay_sysroot: stamp=MATCH recipe=$OVERLAY_SYSROOT_RECIPE"
            else
                echo "overlay_sysroot: stamp=MATCH-inputs tree=INCOMPLETE recipe=$OVERLAY_SYSROOT_RECIPE"
            fi
        else
            echo "overlay_sysroot: stamp=MISMATCH recipe=$OVERLAY_SYSROOT_RECIPE"
        fi
    else
        echo "overlay_sysroot: stamp=ABSENT"
    fi
}

# Return 0 if the tree has the Darwin overlay surface we refuse-before-cmake on.
# overlay_sysroot_headers_ok <sdk>
overlay_sysroot_headers_ok() {
    local sdk=$1
    local arch=${SWIFTCORE_DARWIN_ARCH:-x86_64}
    local rel
    for rel in "${OVERLAY_SYSROOT_REQUIRED_HEADERS[@]}"; do
        [ -f "$sdk/$rel" ] || return 1
    done
    if [ "$arch" = x86_64 ]; then
        overlay_sysroot_has_fmaxl "$sdk/usr/include/math.h" || return 1
    fi
    overlay_sysroot_has_extern_proc "$sdk/usr/include/sys/proc.h" || return 1
    phase2_darwin_modulemap_headers_ok "$sdk" || return 1
}

# usr/include search roots for headers named by staged modulemaps. Same
# places the FE sysroot stages from (full/sdk-gaps for complex.h, then
# FE / machorun / overlay-darwin pins).
overlay_sysroot_header_search_roots() {
    local dest=${1:-}
    local dest_inc="" cand root seen=""
    if [ -n "$dest" ]; then
        dest_inc=$(realpath "$dest/usr/include" 2>/dev/null || true)
    fi
    for cand in \
        ${SWIFTCORE_FE_SYSROOT:+$SWIFTCORE_FE_SYSROOT/usr/include} \
        ${W:+$W/scratch/sysroot_fe4-${SWIFTCORE_DARWIN_ARCH:-x86_64}/usr/include} \
        ${W:+$W/scratch/sysroot_fe4-x86_64/usr/include} \
        "$OPENUIKIT_ROOT/scratch/sysroot_fe4-x86_64/usr/include" \
        "$OPENUIKIT_ROOT/full/sdk-gaps/usr/include" \
        ${W:+$W/machorun-sdk/usr/include} \
        ${MACHORUN:+$MACHORUN/sdk/usr/include} \
        ${W:+$W/machorun/sdk/usr/include} \
        "$OPENUIKIT_ROOT/machorun/sdk/usr/include" \
        "$SWIFTCORE_ROOT/sdk/overlay-darwin"
    do
        [ -n "$cand" ] || continue
        [ -d "$cand" ] || continue
        root=$(realpath "$cand" 2>/dev/null || printf '%s' "$cand")
        [ -n "$dest_inc" ] && [ "$root" = "$dest_inc" ] && continue
        case " $seen " in *" $root "*) continue ;; esac
        seen="$seen $root"
        printf '%s\n' "$root"
    done
}

# Copy every `header "…"` named by staged *.modulemap that is not yet
# under dest/usr/include. overlay_sysroot_fill_modulemap_headers <dest>
overlay_sysroot_fill_modulemap_headers() {
    local dest=${1:?overlay_sysroot_fill_modulemap_headers: dest}
    local inc=$dest/usr/include
    local miss_csv rel src_root src n=0
    mkdir -p "$inc"
    miss_csv=$(phase2_darwin_modulemap_missing_headers "$dest" || true)
    if [ -z "$miss_csv" ]; then
        echo "overlay_sysroot: modulemap headers complete tree=$dest"
        return 0
    fi
    echo "overlay_sysroot: modulemap missing=$miss_csv tree=$dest"
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        [ -f "$inc/$rel" ] && continue
        src=
        while IFS= read -r src_root; do
            [ -n "$src_root" ] || continue
            if [ -f "$src_root/$rel" ]; then
                src=$src_root/$rel
                break
            fi
        done < <(overlay_sysroot_header_search_roots "$dest")
        if [ -n "$src" ]; then
            mkdir -p "$(dirname "$inc/$rel")"
            cp -a "$src" "$inc/$rel"
            echo "overlay_sysroot: staged modulemap header $rel from $src"
            n=$((n + 1))
        fi
    done < <(printf '%s\n' "$miss_csv" | tr ',' '\n')
    echo "overlay_sysroot: filled $n modulemap headers into $inc"
}

overlay_sysroot_print_modulemap_closure() {
    local sdk=${1:?overlay_sysroot_print_modulemap_closure: sdk}
    local miss
    miss=$(phase2_darwin_modulemap_missing_headers "$sdk" || true)
    if [ -n "$miss" ]; then
        echo "overlay_sysroot: modulemap missing=$miss"
    else
        echo "overlay_sysroot: modulemap headers complete"
    fi
}

# Named CANNOT. Exit 2. overlay_sysroot_refuse_modulemap_headers <sdk>
overlay_sysroot_refuse_modulemap_headers() {
    local sdk=${1:?overlay_sysroot_refuse_modulemap_headers: sdk}
    local miss resolved
    miss=$(phase2_darwin_modulemap_missing_headers "$sdk" || true)
    if [ -z "$miss" ]; then
        return 0
    fi
    resolved=$(realpath "$sdk" 2>/dev/null || printf '%s' "$sdk")
    echo "CANNOT_OVERLAY_SYSROOT_MODULEMAP_HEADER tree=$sdk realpath=$resolved missing=$miss reason=staged modulemaps name these headers; overlay sysroot must stage the same header set the modulemaps reference (phase2_darwin_modulemap_missing_headers; complex.h comes from full/sdk-gaps)" >&2
    return 2
}

overlay_sysroot_tbd_count() {
    local sdk=$1
    local n=0
    local f
    [ -d "$sdk/usr/lib" ] || { printf '0\n'; return 0; }
    for f in "$sdk/usr/lib"/*.tbd; do
        [ -f "$f" ] || continue
        n=$((n + 1))
    done
    printf '%s\n' "$n"
}

overlay_sysroot_tree_complete() {
    local sdk=$1
    overlay_sysroot_headers_ok "$sdk" || return 1
    [ "$(overlay_sysroot_tbd_count "$sdk")" -gt 0 ]
}

overlay_sysroot_print_tbds() {
    local sdk=${1:?overlay_sysroot_print_tbds: sdk}
    local n resolved
    n=$(overlay_sysroot_tbd_count "$sdk")
    resolved=$(realpath "$sdk" 2>/dev/null || printf '%s' "$sdk")
    echo "overlay_sysroot: tbds tree=$sdk realpath=$resolved count=$n"
}

# Copy *.tbd into dest/usr/lib from each source tree's usr/lib. Never
# overwrite a tbd already in dest. Search: extra args, live MacOSX.sdk,
# displaced tree, machorun gen_tbd output.
# overlay_sysroot_copy_tbds <dest> [src_sdk...]
overlay_sysroot_copy_tbds() {
    local dest=${1:?overlay_sysroot_copy_tbds: dest}
    shift
    local src root lib t bn n srcs
    OVERLAY_SYSROOT_TBD_SEARCHED=()
    mkdir -p "$dest/usr/lib"
    srcs=("$@")
    for src in \
        ${W:+$W/sdk/MacOSX.sdk} \
        ${OVERLAY_SYSROOT_DISPLACED:+$OVERLAY_SYSROOT_DISPLACED} \
        ${W:+$W/machorun-sdk} \
        ${MACHORUN:+$MACHORUN/sdk} \
        ${W:+$W/machorun/sdk} \
        "$OPENUIKIT_ROOT/machorun/sdk"
    do
        [ -n "$src" ] || continue
        srcs+=("$src")
    done
    local seen="" s
    for src in "${srcs[@]}"; do
        [ -n "$src" ] || continue
        [ -e "$src" ] || [ -L "$src" ] || continue
        root=$(realpath "$src" 2>/dev/null || printf '%s' "$src")
        case " $seen " in *" $root "*) continue ;; esac
        seen="$seen $root"
        # Do not copy a tree onto itself.
        if [ "$root" = "$(realpath "$dest" 2>/dev/null || true)" ]; then
            OVERLAY_SYSROOT_TBD_SEARCHED+=("$root (dest)")
            continue
        fi
        lib=$root/usr/lib
        OVERLAY_SYSROOT_TBD_SEARCHED+=("$lib")
        [ -d "$lib" ] || continue
        n=0
        for t in "$lib"/*.tbd; do
            [ -f "$t" ] || continue
            bn=$(basename "$t")
            if [ -e "$dest/usr/lib/$bn" ]; then
                continue
            fi
            cp -a "$t" "$dest/usr/lib/$bn"
            n=$((n + 1))
        done
        if [ "$n" -gt 0 ]; then
            echo "overlay_sysroot: copied $n tbds from $lib → $dest/usr/lib"
        else
            echo "overlay_sysroot: tbd search $lib (none new)"
        fi
    done
    echo "overlay_sysroot: tbd dest=$dest/usr/lib count=$(overlay_sysroot_tbd_count "$dest")"
}

# Named CANNOT. Prints the tree that was searched. Exit 2.
# overlay_sysroot_refuse_empty_tbds <sdk>
overlay_sysroot_refuse_empty_tbds() {
    local sdk=${1:?overlay_sysroot_refuse_empty_tbds: sdk}
    local n resolved searched
    n=$(overlay_sysroot_tbd_count "$sdk")
    if [ "$n" -gt 0 ]; then
        return 0
    fi
    resolved=$(realpath "$sdk" 2>/dev/null || printf '%s' "$sdk")
    searched=$(printf '%s,' "${OVERLAY_SYSROOT_TBD_SEARCHED[@]:-}" | sed 's/,$//')
    [ -n "$searched" ] || searched=none
    echo "CANNOT_OVERLAY_SYSROOT_TBDS tree=$sdk realpath=$resolved count=0 searched=$searched reason=no .tbd stubs in this sysroot; ld64 would see a lie. machorun gen_tbd output and the displaced MacOSX.sdk usr/lib must be copied into the fresh overlay dest." >&2
    return 2
}

# Named CANNOT, never a silent continue. Exit status 2 for the caller.
# overlay_sysroot_refuse_incomplete <sdk>
overlay_sysroot_refuse_incomplete() {
    local sdk=${1:?overlay_sysroot_refuse_incomplete: sdk}
    local arch=${SWIFTCORE_DARWIN_ARCH:-x86_64}
    local rc=0
    local math=$sdk/usr/include/math.h
    local proc=$sdk/usr/include/sys/proc.h
    local rel h resolved
    resolved=$(realpath "$sdk" 2>/dev/null || printf '%s' "$sdk")
    for rel in "${OVERLAY_SYSROOT_REQUIRED_HEADERS[@]}"; do
        h=$sdk/$rel
        if [ ! -f "$h" ]; then
            echo "CANNOT_OVERLAY_SYSROOT_HEADER tree=$sdk realpath=$resolved path=$h reason=$rel absent from the staged sysroot (listed required header; stamp input MATCH is not presence)" >&2
            rc=2
        fi
    done
    if [ "$arch" = x86_64 ]; then
        if [ -f "$math" ] && ! overlay_sysroot_has_fmaxl "$math"; then
            echo "CANNOT_OVERLAY_SYSROOT_MATH_H path=$math tree=$sdk realpath=$resolved reason=math.h lacks fmaxl (clean-room / stale SDK; refuse-overwrite over a pre-existing tree is a stale artefact every gate misses)" >&2
            rc=2
        fi
    fi
    if [ -f "$proc" ] && ! overlay_sysroot_has_extern_proc "$proc"; then
        echo "CANNOT_OVERLAY_SYSROOT_PROC_H path=$proc tree=$sdk realpath=$resolved reason=sys/proc.h lacks extern_proc (stale SDK; Darwin.swift.gyb:74)" >&2
        rc=2
    fi
    if ! overlay_sysroot_refuse_modulemap_headers "$sdk"; then
        rc=2
    fi
    return "$rc"
}

# mv aside. Never rm. Prints the stale path.
# overlay_sysroot_displace <path>
overlay_sysroot_displace() {
    local path=${1:?overlay_sysroot_displace: path}
    local stale ts
    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        return 0
    fi
    ts=$(date -u +%Y%m%dT%H%M%SZ)
    stale=${path}.stale-${ts}
    if [ -e "$stale" ] || [ -L "$stale" ]; then
        stale=${stale}-$$
    fi
    echo "overlay_sysroot: displacing $path → $stale (never rm a tree we did not create)"
    mv "$path" "$stale"
    OVERLAY_SYSROOT_DISPLACED=$stale
}

# Point live MacOSX.sdk at a fresh staged tree (relative symlink).
# overlay_sysroot_commit_live <live_path> <fresh_dir>
overlay_sysroot_commit_live() {
    local live=${1:?overlay_sysroot_commit_live: live}
    local fresh=${2:?overlay_sysroot_commit_live: fresh}
    local parent bn
    parent=$(dirname "$live")
    bn=$(basename "$fresh")
    mkdir -p "$parent"
    if [ -L "$live" ]; then
        local cur
        cur=$(readlink "$live")
        if [ "$cur" = "$bn" ] || [ "$cur" = "$fresh" ]; then
            echo "overlay_sysroot: live already → $bn"
            return 0
        fi
    fi
    if [ -e "$live" ] || [ -L "$live" ]; then
        # Same directory already is the dest (staged in place): keep it.
        if [ "$(realpath "$live" 2>/dev/null || true)" = "$(realpath "$fresh" 2>/dev/null || true)" ]; then
            echo "overlay_sysroot: live is the fresh tree $fresh"
            return 0
        fi
        overlay_sysroot_displace "$live"
    fi
    ln -sfn "$bn" "$live"
    echo "overlay_sysroot: live $live → $bn"
}

overlay_sysroot_stamp_matches() {
    local sdk=$1
    local stamp=$sdk/$OVERLAY_SYSROOT_STAMP
    overlay_sysroot_stamp_diff "$stamp" >/dev/null
}

# overlay_sysroot_begin <sdk_parent>
# Sets OVERLAY_SYSROOT_DEST and OVERLAY_SYSROOT_REUSE.
# Reuse the live tree when stamp matches AND the dest is complete
# (required headers + usr/lib/*.tbd). Otherwise create a fresh empty dest.
overlay_sysroot_begin() {
    local parent=${1:?overlay_sysroot_begin: sdk parent}
    local live=$parent/MacOSX.sdk
    local id dest
    OVERLAY_SYSROOT_REUSE=0
    OVERLAY_SYSROOT_DEST=
    OVERLAY_SYSROOT_DISPLACED=
    mkdir -p "$parent"
    if [ -e "$live" ] || [ -L "$live" ]; then
        if overlay_sysroot_stamp_matches "$live" && overlay_sysroot_tree_complete "$live"; then
            echo "overlay_sysroot: reuse $live (stamp MATCH recipe=$OVERLAY_SYSROOT_RECIPE)"
            OVERLAY_SYSROOT_REUSE=1
            OVERLAY_SYSROOT_DEST=$live
            return 0
        fi
        echo "overlay_sysroot: live $live will not be reused:"
        overlay_sysroot_stamp_diff "$live/$OVERLAY_SYSROOT_STAMP" || true
        if ! overlay_sysroot_tree_complete "$live"; then
            echo "overlay_sysroot: live tree incomplete (required headers or usr/lib/*.tbd)"
        fi
    fi
    id=$(overlay_sysroot_inputs_id)
    dest=$parent/MacOSX.sdk.overlay-$id
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if overlay_sysroot_stamp_matches "$dest" && overlay_sysroot_tree_complete "$dest"; then
            echo "overlay_sysroot: reusing previously staged $dest"
            OVERLAY_SYSROOT_DEST=$dest
            OVERLAY_SYSROOT_REUSE=1
            overlay_sysroot_commit_live "$live" "$dest"
            OVERLAY_SYSROOT_DEST=$live
            return 0
        fi
        overlay_sysroot_displace "$dest"
    fi
    mkdir -p "$dest"
    echo "overlay_sysroot: fresh dest $dest (id=$id recipe=$OVERLAY_SYSROOT_RECIPE)"
    OVERLAY_SYSROOT_DEST=$dest
}

# overlay_sysroot_finish <sdk_parent> <fresh_dir>
# Copy .tbd stubs from the still-live MacOSX.sdk (and machorun gen_tbd)
# into dest *before* displacing the live tree.
overlay_sysroot_finish() {
    local parent=${1:?overlay_sysroot_finish: sdk parent}
    local fresh=${2:?overlay_sysroot_finish: fresh}
    local live=$parent/MacOSX.sdk
    overlay_sysroot_copy_tbds "$fresh" "$live"
    overlay_sysroot_fill_modulemap_headers "$fresh"
    overlay_sysroot_write_stamp "$fresh"
    overlay_sysroot_commit_live "$live" "$fresh"
    overlay_sysroot_print_headers "$live"
    overlay_sysroot_refuse_incomplete "$live" || return $?
    overlay_sysroot_refuse_empty_tbds "$live"
}
