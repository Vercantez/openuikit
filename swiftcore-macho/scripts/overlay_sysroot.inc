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

if [ -n "${SWIFTCORE_OVERLAY_SYSROOT_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
SWIFTCORE_OVERLAY_SYSROOT_INC=1

_overlay_sysroot_inc_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWIFTCORE_ROOT=${SWIFTCORE_ROOT:-$(cd "$_overlay_sysroot_inc_dir/.." && pwd)}
OPENUIKIT_ROOT=${OPENUIKIT_ROOT:-$(cd "$SWIFTCORE_ROOT/.." && pwd)}

# Bump when staging steps or the Darwin.modulemap header list change.
OVERLAY_SYSROOT_RECIPE=overlay-darwin.1
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

OVERLAY_SYSROOT_DEST=
OVERLAY_SYSROOT_REUSE=0
OVERLAY_SYSROOT_DISPLACED=

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
    if [ -f "$sdk/$OVERLAY_SYSROOT_STAMP" ]; then
        echo "overlay_sysroot: stamp=$sdk/$OVERLAY_SYSROOT_STAMP"
        overlay_sysroot_stamp_diff "$sdk/$OVERLAY_SYSROOT_STAMP" >/dev/null \
            && echo "overlay_sysroot: stamp=MATCH recipe=$OVERLAY_SYSROOT_RECIPE" \
            || echo "overlay_sysroot: stamp=MISMATCH recipe=$OVERLAY_SYSROOT_RECIPE"
    else
        echo "overlay_sysroot: stamp=ABSENT"
    fi
}

# Return 0 if the tree has the Darwin overlay surface we refuse-before-cmake on.
# overlay_sysroot_headers_ok <sdk>
overlay_sysroot_headers_ok() {
    local sdk=$1
    local arch=${SWIFTCORE_DARWIN_ARCH:-x86_64}
    if [ "$arch" = x86_64 ]; then
        overlay_sysroot_has_fmaxl "$sdk/usr/include/math.h" || return 1
    fi
    overlay_sysroot_has_extern_proc "$sdk/usr/include/sys/proc.h" || return 1
    [ -f "$sdk/usr/include/Darwin.modulemap" ] || return 1
}

# Named CANNOT, never a silent continue. Exit status 2 for the caller.
# overlay_sysroot_refuse_incomplete <sdk>
overlay_sysroot_refuse_incomplete() {
    local sdk=${1:?overlay_sysroot_refuse_incomplete: sdk}
    local arch=${SWIFTCORE_DARWIN_ARCH:-x86_64}
    local rc=0
    local math=$sdk/usr/include/math.h
    local proc=$sdk/usr/include/sys/proc.h
    if [ "$arch" = x86_64 ]; then
        if [ ! -f "$math" ]; then
            echo "CANNOT_OVERLAY_SYSROOT_MATH_H path=$math reason=math.h absent; Intel Libm pin was not staged into this sysroot" >&2
            rc=2
        elif ! overlay_sysroot_has_fmaxl "$math"; then
            echo "CANNOT_OVERLAY_SYSROOT_MATH_H path=$math reason=math.h lacks fmaxl (clean-room / stale SDK; refuse-overwrite over a pre-existing tree is a stale artefact every gate misses)" >&2
            rc=2
        fi
    fi
    if [ ! -f "$proc" ]; then
        echo "CANNOT_OVERLAY_SYSROOT_PROC_H path=$proc reason=sys/proc.h absent; machorun pin was not staged into this sysroot" >&2
        rc=2
    elif ! overlay_sysroot_has_extern_proc "$proc"; then
        echo "CANNOT_OVERLAY_SYSROOT_PROC_H path=$proc reason=sys/proc.h lacks extern_proc (stale SDK; Darwin.swift.gyb:74)" >&2
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
# Reuse the live tree when stamp matches AND headers pass the fmaxl/extern_proc
# gate. Otherwise create a fresh empty dest (caller stages into it).
overlay_sysroot_begin() {
    local parent=${1:?overlay_sysroot_begin: sdk parent}
    local live=$parent/MacOSX.sdk
    local id dest
    OVERLAY_SYSROOT_REUSE=0
    OVERLAY_SYSROOT_DEST=
    OVERLAY_SYSROOT_DISPLACED=
    mkdir -p "$parent"
    if [ -e "$live" ] || [ -L "$live" ]; then
        if overlay_sysroot_stamp_matches "$live" && overlay_sysroot_headers_ok "$live"; then
            echo "overlay_sysroot: reuse $live (stamp MATCH recipe=$OVERLAY_SYSROOT_RECIPE)"
            OVERLAY_SYSROOT_REUSE=1
            OVERLAY_SYSROOT_DEST=$live
            return 0
        fi
        echo "overlay_sysroot: live $live will not be reused:"
        overlay_sysroot_stamp_diff "$live/$OVERLAY_SYSROOT_STAMP" || true
        if ! overlay_sysroot_headers_ok "$live"; then
            echo "overlay_sysroot: live headers incomplete (fmaxl/extern_proc/Darwin.modulemap)"
        fi
    fi
    id=$(overlay_sysroot_inputs_id)
    dest=$parent/MacOSX.sdk.overlay-$id
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if overlay_sysroot_stamp_matches "$dest" && overlay_sysroot_headers_ok "$dest"; then
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
overlay_sysroot_finish() {
    local parent=${1:?overlay_sysroot_finish: sdk parent}
    local fresh=${2:?overlay_sysroot_finish: fresh}
    local live=$parent/MacOSX.sdk
    overlay_sysroot_write_stamp "$fresh"
    overlay_sysroot_commit_live "$live" "$fresh"
    overlay_sysroot_print_headers "$live"
    overlay_sysroot_refuse_incomplete "$live"
}
