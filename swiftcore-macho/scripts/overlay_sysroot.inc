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
# (stage_overlay_darwin.sh + enumerated module headers) + machorun sys/proc.h
# + the SDK copy's link inputs: usr/lib/*.tbd, usr/lib/swift/*.tbd,
# usr/lib/swift/*.swiftmodule/*, HEAD:machorun (darwin tbds originate in
# machorun gen_tbd; phase2 copies them into scratch/sysroot_fe4[-x86_64]),
# and the crt_externs.h include_next chain (objc4-priv wrapper in front of
# the public machorun-sdk / FE header).
# Required *staged* headers (ConditionalMacros.h included) must be present in
# the dest tree: input-sha MATCH of the pin is not completeness. .tbd stubs
# are copied FROM that FE sysroot (fallback: machorun gen_tbd output / the
# displaced tree) into the fresh dest before the live MacOSX.sdk is moved aside.
#
# Staged Darwin*.modulemap files name headers (complex.h, …). Those files must
# resolve under usr/include before cmake. Closure is the Darwin Clang maps
# overlay compiles load via -sdk (usr/include/module.modulemap + Darwin*.modulemap),
# not libc++ usr/include/c++/v1/module.modulemap. Source Darwin headers from the
# FE sysroot / full/sdk-gaps / machorun / overlay-darwin pins.
#
# clang -target x86_64-apple-macos -isysroot $SDK searches usr/local/include
# then usr/include. objc4-priv/crt_externs.h is a wrapper (`#include_next
# <crt_externs.h>`). Flattening it onto usr/include (stage_sdk used to) leaves
# no later dir for the public header — Darwin.o dies at crt_externs.h:13.
# The working (stale) copy had the public machorun-sdk / FE file at
# usr/include/crt_externs.h. Restage puts the wrapper at usr/local/include
# and the public header at usr/include.

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
# header closure, the required staged-header / tbd completeness gate, the
# tbd / swiftmodule / HEAD:machorun stamp inputs, or the include_next
# wrapper layout change.
OVERLAY_SYSROOT_RECIPE=overlay-darwin.6
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
OVERLAY_SYSROOT_SOURCE=ABSENT
OVERLAY_SYSROOT_SOURCE_KIND=
OVERLAY_SYSROOT_TBD_SHA=ABSENT

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

# Darwin usr/lib/*.tbd in the FE sysroot are copied from machorun gen_tbd
# (phase2_stage_darwin_tbds_into_sysroot). Swift usr/lib/swift/*.tbd come from
# scripts/x86/gen_swift_tbd.sh, not gen_tbd. Stamp HEAD:machorun for the
# gen_tbd origin; stamp the tbd bytes themselves so a gen_tbd rerun without a
# new commit (e.g. PR #67 _fmal) restages the overlay SDK copy.
overlay_sysroot_machorun_head() {
    local live
    live=$(phase2_git "$OPENUIKIT_ROOT" rev-parse HEAD:machorun 2>/dev/null | tr -d '[:space:]') || live=
    if [ -n "$live" ]; then
        printf '%s\n' "$live"
    else
        printf 'ABSENT\n'
    fi
}

# scratch/sysroot_fe4[-x86_64]: the tree phase2 stages from machorun gen_tbd.
# Never the unsuffixed arm64 sysroot_fe4 on an x86_64 overlay.
overlay_sysroot_source_candidates() {
    local arch=${SWIFTCORE_DARWIN_ARCH:-x86_64}
    [ -n "${SWIFTCORE_FE_SYSROOT:-}" ] && printf '%s\n' "$SWIFTCORE_FE_SYSROOT"
    if [ -n "${W:-}" ]; then
        printf '%s\n' "$W/scratch/sysroot_fe4-${arch}"
        if [ "$arch" = x86_64 ]; then
            printf '%s\n' "$W/scratch/sysroot_fe4-x86_64"
        else
            printf '%s\n' "$W/scratch/sysroot_fe4"
        fi
    fi
    if [ "$arch" = x86_64 ]; then
        printf '%s\n' "$OPENUIKIT_ROOT/scratch/sysroot_fe4-x86_64"
    else
        printf '%s\n' "$OPENUIKIT_ROOT/scratch/sysroot_fe4"
    fi
}

overlay_sysroot_gen_tbd_candidates() {
    [ -n "${W:-}" ] && printf '%s\n' "$W/machorun-sdk"
    [ -n "${MACHORUN:-}" ] && printf '%s\n' "$MACHORUN/sdk"
    [ -n "${W:-}" ] && printf '%s\n' "$W/machorun/sdk"
    printf '%s\n' "$OPENUIKIT_ROOT/machorun/sdk"
}

overlay_sysroot_tree_has_tbds() {
    local root=$1
    local f
    [ -n "$root" ] || return 1
    [ -d "$root/usr/lib" ] || return 1
    for f in "$root/usr/lib"/*.tbd; do
        [ -e "$f" ] || [ -L "$f" ] || continue
        return 0
    done
    return 1
}

overlay_sysroot_resolve_source() {
    local cand root
    OVERLAY_SYSROOT_SOURCE=ABSENT
    OVERLAY_SYSROOT_SOURCE_KIND=
    while IFS= read -r cand; do
        [ -n "$cand" ] || continue
        [ -e "$cand" ] || [ -L "$cand" ] || continue
        overlay_sysroot_tree_has_tbds "$cand" || continue
        root=$(realpath "$cand" 2>/dev/null || printf '%s' "$cand")
        OVERLAY_SYSROOT_SOURCE=$root
        OVERLAY_SYSROOT_SOURCE_KIND=fe
        printf '%s\n' "$root"
        return 0
    done < <(overlay_sysroot_source_candidates)
    while IFS= read -r cand; do
        [ -n "$cand" ] || continue
        [ -e "$cand" ] || [ -L "$cand" ] || continue
        overlay_sysroot_tree_has_tbds "$cand" || continue
        root=$(realpath "$cand" 2>/dev/null || printf '%s' "$cand")
        OVERLAY_SYSROOT_SOURCE=$root
        OVERLAY_SYSROOT_SOURCE_KIND=gen_tbd
        printf '%s\n' "$root"
        return 0
    done < <(overlay_sysroot_gen_tbd_candidates)
    return 1
}

overlay_sysroot_tbd_relpaths() {
    local root=$1
    local dir f
    [ -n "$root" ] && [ "$root" != ABSENT ] || return 0
    for dir in usr/lib usr/lib/swift; do
        [ -d "$root/$dir" ] || continue
        for f in "$root/$dir"/*.tbd; do
            [ -e "$f" ] || [ -L "$f" ] || continue
            printf '%s\n' "$dir/$(basename "$f")"
        done
    done | LC_ALL=C sort -u
}

overlay_sysroot_hash_tbds() {
    local root=$1
    local rel list
    if [ -z "$root" ] || [ "$root" = ABSENT ]; then
        printf 'ABSENT\n'
        return 0
    fi
    list=$(overlay_sysroot_tbd_relpaths "$root")
    if [ -z "$list" ]; then
        printf 'ABSENT\n'
        return 0
    fi
    {
        while IFS= read -r rel; do
            [ -n "$rel" ] || continue
            printf '%s %s\n' "$rel" "$(overlay_sysroot_sha_or_absent "$root/$rel")"
        done <<EOF
$list
EOF
    } | sha256sum | awk '{print $1}'
}

overlay_sysroot_hash_swiftmodules() {
    local root=$1
    local f rel lines=""
    if [ -z "$root" ] || [ "$root" = ABSENT ] || [ ! -d "$root/usr/lib/swift" ]; then
        printf 'ABSENT\n'
        return 0
    fi
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        rel=${f#"$root/"}
        lines="${lines}${rel} $(overlay_sysroot_sha_or_absent "$f")"$'\n'
    done < <(find "$root/usr/lib/swift" -path '*.swiftmodule/*' \( -type f -o -type l \) | LC_ALL=C sort)
    if [ -z "$lines" ]; then
        printf 'ABSENT\n'
        return 0
    fi
    printf '%s' "$lines" | sha256sum | awk '{print $1}'
}

# overlay_sysroot: source=<path> tbd_sha=<…> on every run.
overlay_sysroot_print_source() {
    local src tbd_sha
    src=$(overlay_sysroot_resolve_source || true)
    [ -n "$src" ] || src=ABSENT
    tbd_sha=$(overlay_sysroot_hash_tbds "$src")
    OVERLAY_SYSROOT_SOURCE=$src
    OVERLAY_SYSROOT_TBD_SHA=$tbd_sha
    echo "overlay_sysroot: source=${src} tbd_sha=${tbd_sha}"
}

overlay_sysroot_print_stamp_diff() {
    local stamp=$1
    local line
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        echo "overlay_sysroot: $line"
    done < <(overlay_sysroot_stamp_diff "$stamp" || true)
}

# Names from `#include_next <foo.h>` / `"foo.h"` in a header. Empty if none.
overlay_sysroot_include_next_names() {
    local f=$1
    [ -f "$f" ] || return 0
    sed -n 's/^[[:space:]]*#[[:space:]]*include_next[[:space:]]*[<"]\([^>"]*\)[>"].*/\1/p' "$f"
}

overlay_sysroot_is_include_next_wrapper() {
    local f=$1
    [ -f "$f" ] || return 1
    overlay_sysroot_include_next_names "$f" | grep -q .
}

# clang -target *-apple-macos -isysroot $SDK (overlay -sdk): usr/local/include
# then usr/include. Resource dir is not an SDK dir we stage into.
overlay_sysroot_isysroot_include_dirs() {
    local sdk=${1:?overlay_sysroot_isysroot_include_dirs: sdk}
    printf '%s\n' "$sdk/usr/local/include"
    printf '%s\n' "$sdk/usr/include"
}

overlay_sysroot_objc4_priv_crt() {
    local cand
    for cand in \
        ${W:+$W/objc4-priv/crt_externs.h} \
        "$OPENUIKIT_ROOT/machorun/vendor/objc4-priv/crt_externs.h"
    do
        [ -n "$cand" ] || continue
        if [ -f "$cand" ]; then
            printf '%s\n' "$cand"
            return 0
        fi
    done
    return 1
}

# Public Apple crt_externs.h (no include_next). Working overlay copy / FE /
# machorun-sdk. Never the objc4-priv wrapper.
overlay_sysroot_public_crt_externs() {
    local root f
    while IFS= read -r root; do
        [ -n "$root" ] || continue
        f=$root/crt_externs.h
        [ -f "$f" ] || continue
        overlay_sysroot_is_include_next_wrapper "$f" && continue
        printf '%s\n' "$f"
        return 0
    done < <(overlay_sysroot_header_search_roots "")
    return 1
}

# One "name<TAB>wrapper_rel" per include_next whose target is not in a later
# -isysroot dir. Return 1 if any are missing.
# overlay_sysroot_include_next_missing_entries <sdk>
overlay_sysroot_include_next_missing_entries() {
    local sdk=${1:?overlay_sysroot_include_next_missing_entries: sdk}
    local dir f name later found any=0 wrapper_dir rest
    while IFS= read -r dir; do
        [ -n "$dir" ] || continue
        [ -d "$dir" ] || continue
        while IFS= read -r f; do
            [ -n "$f" ] || continue
            while IFS= read -r name; do
                [ -n "$name" ] || continue
                found=0
                rest=0
                while IFS= read -r later; do
                    [ -n "$later" ] || continue
                    if [ "$later" = "$dir" ]; then
                        rest=1
                        continue
                    fi
                    [ "$rest" -eq 1 ] || continue
                    if [ -f "$later/$name" ]; then
                        found=1
                        break
                    fi
                done < <(overlay_sysroot_isysroot_include_dirs "$sdk")
                if [ "$found" -eq 0 ]; then
                    wraprel=${f#"$sdk/"}
                    if [ "$wraprel" = "$f" ]; then
                        wraprel=${f#"$(realpath "$sdk" 2>/dev/null || printf '%s' "$sdk")/"}
                    fi
                    printf '%s\t%s\n' "$name" "$wraprel"
                    any=1
                fi
            done < <(overlay_sysroot_include_next_names "$f")
        done < <(find "$dir" -name '*.h' ! -path '*/c++/v1/*' -print | LC_ALL=C sort)
    done < <(overlay_sysroot_isysroot_include_dirs "$sdk")
    [ "$any" -eq 0 ]
}

overlay_sysroot_include_next_ok() {
    overlay_sysroot_include_next_missing_entries "$1" >/dev/null
}

# Restore the public header behind an include_next wrapper. clang -isysroot
# searches usr/local/include then usr/include: wrapper in front, public
# machorun-sdk / FE header behind. Overlay compiles pass -sdk only.
# overlay_sysroot_fill_include_next_wrappers <dest>
overlay_sysroot_fill_include_next_wrappers() {
    local dest=${1:?overlay_sysroot_fill_include_next_wrappers: dest}
    local name wraprel wrap public n=0
    mkdir -p "$dest/usr/include" "$dest/usr/local/include"
    while IFS=$'\t' read -r name wraprel; do
        [ -n "$name" ] || continue
        wrap=$dest/$wraprel
        public=
        if [ "$name" = crt_externs.h ]; then
            public=$(overlay_sysroot_public_crt_externs || true)
        else
            while IFS= read -r src_root; do
                [ -n "$src_root" ] || continue
                if [ -f "$src_root/$name" ] \
                    && ! overlay_sysroot_is_include_next_wrapper "$src_root/$name"; then
                    public=$src_root/$name
                    break
                fi
            done < <(overlay_sysroot_header_search_roots "$dest")
        fi
        if [ -z "$public" ] || [ ! -f "$public" ]; then
            echo "overlay_sysroot: include_next $name wrapper=$wraprel public=ABSENT"
            continue
        fi
        mkdir -p "$dest/usr/local/include/$(dirname "$name")" \
            "$dest/usr/include/$(dirname "$name")"
        # Wrapper in the front -isysroot dir; public header behind. Copy the
        # wrapper away from usr/include *before* overwriting that slot.
        if [ -f "$wrap" ] && overlay_sysroot_is_include_next_wrapper "$wrap" \
            && [ "$wraprel" != "usr/local/include/$name" ]; then
            cp -a "$wrap" "$dest/usr/local/include/$name"
            echo "overlay_sysroot: include_next wrapper $name → usr/local/include (front -isysroot dir)"
        fi
        cp -a "$public" "$dest/usr/include/$name"
        echo "overlay_sysroot: include_next target $name from $public → usr/include"
        n=$((n + 1))
    done < <(overlay_sysroot_include_next_missing_entries "$dest" || true)
    echo "overlay_sysroot: filled $n include_next targets into $dest"
}

# objc4-priv flatten: include_next wrappers go to usr/local/include (clang
# Darwin -isysroot front dir). Everything else stays on usr/include. Never
# overwrite the public machorun-sdk / FE header with a wrapper.
# overlay_sysroot_install_objc4_priv <priv_dir> <sdk>
overlay_sysroot_install_objc4_priv() {
    local priv=${1:?overlay_sysroot_install_objc4_priv: priv}
    local sdk=${2:?overlay_sysroot_install_objc4_priv: sdk}
    local rel src dest
    [ -d "$priv" ] || return 0
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        src=$priv/$rel
        [ -f "$src" ] || continue
        if overlay_sysroot_is_include_next_wrapper "$src"; then
            dest=$sdk/usr/local/include/$rel
            echo "overlay_sysroot: objc4-priv include_next $rel → usr/local/include (public header stays at usr/include)"
        else
            dest=$sdk/usr/include/$rel
        fi
        mkdir -p "$(dirname "$dest")"
        install -D "$src" "$dest"
    done < <(cd "$priv" && find . -name '*.h' | sed 's|^\./||' | LC_ALL=C sort)
}

overlay_sysroot_print_include_next() {
    local sdk=${1:?overlay_sysroot_print_include_next: sdk}
    local name wraprel any=0
    while IFS=$'\t' read -r name wraprel; do
        [ -n "$name" ] || continue
        echo "overlay_sysroot: include_next missing header=$name wrapper=$wraprel"
        any=1
    done < <(overlay_sysroot_include_next_missing_entries "$sdk" || true)
    if [ "$any" -eq 0 ]; then
        echo "overlay_sysroot: include_next complete"
    fi
}

# Named CANNOT. Exit 2. wrapper whose include_next target is absent.
# overlay_sysroot_refuse_include_next <sdk>
overlay_sysroot_refuse_include_next() {
    local sdk=${1:?overlay_sysroot_refuse_include_next: sdk}
    local name wraprel resolved entries=""
    while IFS=$'\t' read -r name wraprel; do
        [ -n "$name" ] || continue
        echo "overlay_sysroot: include_next missing header=$name wrapper=$wraprel" >&2
        entries="${entries:+$entries,}$name@$wraprel"
    done < <(overlay_sysroot_include_next_missing_entries "$sdk" || true)
    if [ -z "$entries" ]; then
        return 0
    fi
    resolved=$(realpath "$sdk" 2>/dev/null || printf '%s' "$sdk")
    echo "CANNOT_OVERLAY_SYSROOT_INCLUDE_NEXT tree=$sdk realpath=$resolved missing=$entries reason=wrapper #include_next has no later -isysroot target (clang Darwin -isysroot searches usr/local/include then usr/include; overlay compiles pass -sdk only). Working copy: public machorun-sdk/FE crt_externs.h at usr/include; objc4-priv wrapper at usr/local/include." >&2
    return 2
}

# overlay_sysroot_input_lines
# recipe + sha of the overlay-darwin header set + modulemap recipe + proc.h
# + source usr/lib/*.tbd + usr/lib/swift/*.tbd + swiftmodules + HEAD:machorun
# + public crt_externs.h / objc4-priv wrapper (include_next chain).
overlay_sysroot_input_lines() {
    local src=$SWIFTCORE_ROOT/sdk/overlay-darwin
    local proc tbd_src tbd_rel public_crt priv_crt
    proc=$(overlay_sysroot_proc_h || true)
    tbd_src=$(overlay_sysroot_resolve_source || true)
    [ -n "$tbd_src" ] || tbd_src=ABSENT
    public_crt=$(overlay_sysroot_public_crt_externs || true)
    priv_crt=$(overlay_sysroot_objc4_priv_crt || true)
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
    printf 'modulemap.closure=darwin_clang_overlay_maps\n'
    printf 'include_next.dirs=usr/local/include,usr/include\n'
    printf 'machorun.sys/proc.h=%s\n' "$(overlay_sysroot_sha_or_absent "${proc:-}")"
    printf 'machorun.crt_externs.h=%s\n' "$(overlay_sysroot_sha_or_absent "${public_crt:-}")"
    printf 'objc4-priv.crt_externs.h=%s\n' "$(overlay_sysroot_sha_or_absent "${priv_crt:-}")"
    # gen_tbd origin (darwin usr/lib/*.tbd). Not a substitute for hashing the
    # generated tbd bytes: PR #67 updated gen_tbd output without this tree
    # hash changing between overlay stamp writes.
    printf 'machorun.HEAD=%s\n' "$(overlay_sysroot_machorun_head)"
    printf 'tbd_sha=%s\n' "$(overlay_sysroot_hash_tbds "$tbd_src")"
    printf 'usr/lib/swift.modules=%s\n' "$(overlay_sysroot_hash_swiftmodules "$tbd_src")"
    if [ "$tbd_src" != ABSENT ]; then
        while IFS= read -r tbd_rel; do
            [ -n "$tbd_rel" ] || continue
            printf '%s=%s\n' "$tbd_rel" "$(overlay_sysroot_sha_or_absent "$tbd_src/$tbd_rel")"
        done < <(overlay_sysroot_tbd_relpaths "$tbd_src")
    fi
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
    overlay_sysroot_print_source
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
    overlay_sysroot_print_include_next "$sdk"
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
            overlay_sysroot_print_stamp_diff "$sdk/$OVERLAY_SYSROOT_STAMP"
        fi
    else
        echo "overlay_sysroot: stamp=ABSENT"
    fi
}

# Return 0 if the tree has the Darwin overlay surface we refuse-before-cmake on.
# include_next wrappers whose later -isysroot target is absent (objc4-priv
# crt_externs.h flattened onto usr/include) are incomplete.
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
    overlay_sysroot_modulemap_headers_ok "$sdk" || return 1
    overlay_sysroot_include_next_ok "$sdk" || return 1
}

# Clang module maps overlay Swift compiles load via -sdk (no -fmodule-map-file).
# Live ninja Darwin / Synchronization / _Concurrency / _StringProcessing /
# _Builtin_float / _RegexParser / Observation: -sdk=$W/sdk/MacOSX.sdk.
# swiftinterfaces import Darwin / Swift / SwiftShims / SwiftOverlayShims /
# _Concurrency / _Builtin_float — not std / Cxx. libc++ lives in
# usr/include/c++/v1/module.modulemap (stage_sdk.sh copies Ubuntu llvm-18);
# that map is outside this closure. full/foundation/stage_fe_sysroot.sh does
# not stage libc++ into the FE sysroot.
# overlay_sysroot_clang_overlay_modulemaps <sdk>
overlay_sysroot_clang_overlay_modulemaps() {
    local sdk=${1:?overlay_sysroot_clang_overlay_modulemaps: sdk}
    local inc=$sdk/usr/include
    local f
    [ -d "$inc" ] || return 0
    for f in "$inc"/module.modulemap "$inc"/Darwin*.modulemap; do
        [ -f "$f" ] || continue
        printf '%s\n' "$f"
    done | sort -u
}

# Relpaths of *.modulemap under usr/include that overlay compiles do not load.
# overlay_sysroot_skipped_modulemaps <sdk>
overlay_sysroot_skipped_modulemaps() {
    local sdk=${1:?overlay_sysroot_skipped_modulemaps: sdk}
    local inc=$sdk/usr/include
    local map ov kept
    [ -d "$inc" ] || return 0
    while IFS= read -r map; do
        [ -n "$map" ] || continue
        kept=0
        while IFS= read -r ov; do
            [ -n "$ov" ] || continue
            if [ "$map" = "$ov" ]; then
                kept=1
                break
            fi
        done < <(overlay_sysroot_clang_overlay_modulemaps "$sdk")
        if [ "$kept" -eq 0 ]; then
            printf '%s\n' "${map#"$sdk/"}"
        fi
    done < <(find "$inc" -name '*.modulemap' -print | sort)
}

# One "header<TAB>rel_map" per missing quoted header in overlay Clang maps.
# Return 1 if any are missing. Uses phase2_modulemap_quoted_headers.
# overlay_sysroot_modulemap_missing_entries <sdk>
overlay_sysroot_modulemap_missing_entries() {
    local sdk=${1:?overlay_sysroot_modulemap_missing_entries: sdk}
    local inc=$sdk/usr/include
    local map rel maprel any=0
    [ -d "$inc" ] || return 0
    while IFS= read -r map; do
        [ -n "$map" ] || continue
        maprel=${map#"$sdk/"}
        while IFS= read -r rel; do
            [ -n "$rel" ] || continue
            if [ -f "$inc/$rel" ] || [ -f "$(dirname "$map")/$rel" ]; then
                continue
            fi
            printf '%s\t%s\n' "$rel" "$maprel"
            any=1
        done < <(phase2_modulemap_quoted_headers "$map")
    done < <(overlay_sysroot_clang_overlay_modulemaps "$sdk")
    [ "$any" -eq 0 ]
}

# Comma-separated header paths (no map). Return 1 if any missing.
overlay_sysroot_modulemap_missing_headers() {
    local sdk=$1
    local rel map miss="" any=0
    while IFS=$'\t' read -r rel map; do
        [ -n "$rel" ] || continue
        any=1
        case ",$miss," in
            *",$rel,"*) ;;
            *) miss="${miss:+$miss,}$rel" ;;
        esac
    done < <(overlay_sysroot_modulemap_missing_entries "$sdk" || true)
    if [ "$any" -eq 1 ]; then
        printf '%s\n' "$miss"
        return 1
    fi
    return 0
}

overlay_sysroot_modulemap_headers_ok() {
    overlay_sysroot_modulemap_missing_entries "$1" >/dev/null
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
    miss_csv=$(overlay_sysroot_modulemap_missing_headers "$dest" || true)
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
    local map rel maprel skip any=0
    while IFS= read -r map; do
        [ -n "$map" ] || continue
        echo "overlay_sysroot: modulemap consider ${map#"$sdk/"}"
    done < <(overlay_sysroot_clang_overlay_modulemaps "$sdk")
    while IFS= read -r skip; do
        [ -n "$skip" ] || continue
        echo "overlay_sysroot: modulemap skip $skip reason=not a Darwin Clang overlay map (libc++ std / nested; ninja overlay compiles pass -sdk only, no -fmodule-map-file for c++/v1; swiftinterfaces import Darwin/Swift/SwiftShims not std)"
    done < <(overlay_sysroot_skipped_modulemaps "$sdk")
    while IFS=$'\t' read -r rel maprel; do
        [ -n "$rel" ] || continue
        echo "overlay_sysroot: modulemap missing header=$rel map=$maprel"
        any=1
    done < <(overlay_sysroot_modulemap_missing_entries "$sdk" || true)
    if [ "$any" -eq 0 ]; then
        echo "overlay_sysroot: modulemap headers complete"
    fi
}

# Named CANNOT. Exit 2. Each missing name is header@map.
# overlay_sysroot_refuse_modulemap_headers <sdk>
overlay_sysroot_refuse_modulemap_headers() {
    local sdk=${1:?overlay_sysroot_refuse_modulemap_headers: sdk}
    local rel maprel resolved entries="" 
    while IFS=$'\t' read -r rel maprel; do
        [ -n "$rel" ] || continue
        echo "overlay_sysroot: modulemap missing header=$rel map=$maprel" >&2
        entries="${entries:+$entries,}$rel@$maprel"
    done < <(overlay_sysroot_modulemap_missing_entries "$sdk" || true)
    if [ -z "$entries" ]; then
        return 0
    fi
    resolved=$(realpath "$sdk" 2>/dev/null || printf '%s' "$sdk")
    echo "CANNOT_OVERLAY_SYSROOT_MODULEMAP_HEADER tree=$sdk realpath=$resolved missing=$entries reason=Darwin Clang overlay maps (usr/include/module.modulemap + Darwin*.modulemap) name these headers; libc++ usr/include/c++/v1 is outside this closure (overlay compiles do not import std)" >&2
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

# Copy *.tbd (and swiftmodule files) into dest from src. overwrite=1 replaces
# dest files so scratch/sysroot_fe4[-x86_64] wins over a stale machorun-sdk
# copy stage_sdk.sh already laid down.
# overlay_sysroot_copy_tbds_from <src> <dest> <overwrite 0|1>
overlay_sysroot_copy_tbds_from() {
    local src=${1:?overlay_sysroot_copy_tbds_from: src}
    local dest=${2:?overlay_sysroot_copy_tbds_from: dest}
    local overwrite=${3:-0}
    local lib t bn n=0 swift_n=0 rel f
    lib=$src/usr/lib
    [ -d "$lib" ] || return 0
    mkdir -p "$dest/usr/lib"
    OVERLAY_SYSROOT_TBD_SEARCHED+=("$lib")
    for t in "$lib"/*.tbd; do
        [ -e "$t" ] || [ -L "$t" ] || continue
        bn=$(basename "$t")
        if [ "$overwrite" != 1 ] && [ -e "$dest/usr/lib/$bn" ]; then
            continue
        fi
        cp -a "$t" "$dest/usr/lib/$bn"
        n=$((n + 1))
    done
    if [ -d "$src/usr/lib/swift" ]; then
        mkdir -p "$dest/usr/lib/swift"
        for t in "$src/usr/lib/swift"/*.tbd; do
            [ -e "$t" ] || [ -L "$t" ] || continue
            bn=$(basename "$t")
            if [ "$overwrite" != 1 ] && [ -e "$dest/usr/lib/swift/$bn" ]; then
                continue
            fi
            cp -a "$t" "$dest/usr/lib/swift/$bn"
            swift_n=$((swift_n + 1))
        done
        while IFS= read -r f; do
            [ -n "$f" ] || continue
            rel=${f#"$src/usr/lib/swift/"}
            if [ "$overwrite" != 1 ] && [ -e "$dest/usr/lib/swift/$rel" ]; then
                continue
            fi
            mkdir -p "$(dirname "$dest/usr/lib/swift/$rel")"
            cp -a "$f" "$dest/usr/lib/swift/$rel"
            swift_n=$((swift_n + 1))
        done < <(find "$src/usr/lib/swift" -path '*.swiftmodule/*' \( -type f -o -type l \) | LC_ALL=C sort)
    fi
    if [ "$n" -gt 0 ] || [ "$swift_n" -gt 0 ]; then
        echo "overlay_sysroot: copied $n tbds + $swift_n swift inputs from $src → $dest"
    else
        echo "overlay_sysroot: tbd search $lib (none new)"
    fi
}

# Copy *.tbd into dest from each source tree's usr/lib. The FE sysroot
# (scratch/sysroot_fe4[-x86_64]) is the primary source and overwrites; other
# trees (live MacOSX.sdk, displaced, machorun gen_tbd) fill gaps only.
# overlay_sysroot_copy_tbds <dest> [src_sdk...]
overlay_sysroot_copy_tbds() {
    local dest=${1:?overlay_sysroot_copy_tbds: dest}
    shift
    local src root srcs primary seen=""
    OVERLAY_SYSROOT_TBD_SEARCHED=()
    mkdir -p "$dest/usr/lib"
    primary=$(overlay_sysroot_resolve_source || true)
    if [ -n "$primary" ]; then
        overlay_sysroot_copy_tbds_from "$primary" "$dest" 1
        seen=" $primary "
    fi
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
    for src in "${srcs[@]+"${srcs[@]}"}"; do
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
        overlay_sysroot_copy_tbds_from "$root" "$dest" 0
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
    echo "CANNOT_OVERLAY_SYSROOT_TBDS tree=$sdk realpath=$resolved count=0 searched=$searched reason=no .tbd stubs in this sysroot; ld64 would see a lie. scratch/sysroot_fe4[-x86_64] (phase2, from machorun gen_tbd) and the displaced MacOSX.sdk usr/lib must be copied into the fresh overlay dest." >&2
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
    if ! overlay_sysroot_refuse_include_next "$sdk"; then
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
    overlay_sysroot_print_source
    if [ -e "$live" ] || [ -L "$live" ]; then
        if overlay_sysroot_stamp_matches "$live" && overlay_sysroot_tree_complete "$live"; then
            echo "overlay_sysroot: reuse $live (stamp MATCH recipe=$OVERLAY_SYSROOT_RECIPE)"
            OVERLAY_SYSROOT_REUSE=1
            OVERLAY_SYSROOT_DEST=$live
            return 0
        fi
        echo "overlay_sysroot: live $live will not be reused:"
        if [ ! -f "$live/$OVERLAY_SYSROOT_STAMP" ]; then
            echo "overlay_sysroot: stamp=ABSENT"
        elif overlay_sysroot_stamp_matches "$live"; then
            echo "overlay_sysroot: stamp=MATCH recipe=$OVERLAY_SYSROOT_RECIPE"
        else
            echo "overlay_sysroot: stamp=MISMATCH recipe=$OVERLAY_SYSROOT_RECIPE"
            overlay_sysroot_print_stamp_diff "$live/$OVERLAY_SYSROOT_STAMP"
        fi
        if ! overlay_sysroot_tree_complete "$live"; then
            echo "overlay_sysroot: live tree incomplete (required headers, usr/lib/*.tbd, or include_next wrapper target)"
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
# Copy .tbd stubs from scratch/sysroot_fe4[-x86_64] (phase2 / machorun gen_tbd)
# into dest *before* displacing the live tree. Gap-fill from the still-live
# MacOSX.sdk and machorun/sdk.
overlay_sysroot_finish() {
    local parent=${1:?overlay_sysroot_finish: sdk parent}
    local fresh=${2:?overlay_sysroot_finish: fresh}
    local live=$parent/MacOSX.sdk
    overlay_sysroot_copy_tbds "$fresh" "$live"
    overlay_sysroot_fill_modulemap_headers "$fresh"
    overlay_sysroot_fill_include_next_wrappers "$fresh"
    overlay_sysroot_write_stamp "$fresh"
    overlay_sysroot_commit_live "$live" "$fresh"
    overlay_sysroot_print_headers "$live"
    overlay_sysroot_refuse_incomplete "$live" || return $?
    overlay_sysroot_refuse_empty_tbds "$live"
}
