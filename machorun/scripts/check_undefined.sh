#!/bin/bash
# check_undefined.sh -- grade a darwin root's undefined symbols against what
# that root actually defines.
#
#   scripts/check_undefined.sh                 grade machorun's own darwin/
#   scripts/check_undefined.sh <root> [...]    grade a guest root (the directory
#                                              MACHORUN_ROOT points at)
#   scripts/check_undefined.sh --selftest      prove the instrument works
#
# WHY THIS EXISTS. src/resolve.c has a host fallback: a bind from an image the
# darwin-root prefix map served, which no loaded Mach-O satisfies, is answered
# out of glibc by name with no translation. Nothing grades what lands there.
# Staging a dylib into a guest root for one reason drags its whole undefined
# set along, and each name our userland does not define is answered silently --
# so the hazard set is "what failed to resolve", not "what we chose to bridge",
# and it grows every time somebody stages a library. Measured on
# scratch/mrroot_fe: 371 distinct symbols host-bound, eight of them plain C
# names that arrived by accident and four of those ABI-divergent (see
# docs/UNIMPLEMENTED.md#host-bind-denied, src/host_deny.c).
#
# It reports TWO kinds of finding, because the loader has two ways to miss.
#
#   MISSING    no image in the root defines it, under any name. This one is
#              certain: the loader will take glibc's, or fail.
#   MISPLACED  some image in the root defines it, but NOT the library the
#              symbol is two-level bound to, nor anything that library
#              re-exports. src/resolve.c does not fall back to a flat search
#              when a two-level lookup misses -- it goes straight to the host
#              -- so these host-bind too, while looking present to anyone
#              grepping the root. That is the shape of the libc++abi defect
#              (#61): __gxx_personality_v0 was in the process the whole time
#              and unreachable from the only library allowed to answer.
#
# THE RE-EXPORT WALK IS TRANSITIVE AND THAT IS NOT A DETAIL. A one-level walk
# invents findings: libc++.1 -> libc++.real -> libc++abi is two hops, so
# grading at depth 1 reports symbols as MISPLACED that resolve perfectly.
# --selftest measures the difference rather than asserting it.
#
# Depth 4 matches src/resolve.c's lookup_in(), deliberately: a checker that
# searches further than the loader would report clean about binds that fail.
#
# Directories named `*-park` (phase2 / build_stdlib `usr/lib-arm64-park`) are
# parking spots for a foreign-arch slice, not a library path. The loader does
# not search them; CHECK 5 must not grade them as if they were in the x86 root.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DEPTH=4
SELFTEST=0
STRICT=0
ROOTS=()
for a in "$@"; do
    case "$a" in
        --selftest) SELFTEST=1 ;;
        --strict)   STRICT=1 ;;
        --depth=*)  DEPTH="${a#--depth=}" ;;
        -h|--help)  sed -n '2,10p' "$0"; exit 0 ;;
        -*)         echo "check_undefined: unknown option $a" >&2; exit 64 ;;
        *)          ROOTS+=("$a") ;;
    esac
done
[ ${#ROOTS[@]} -gt 0 ] || ROOTS=("$ROOT/darwin")

die() { echo "check_undefined: $*" >&2; exit 1; }

ALLOW="$ROOT/darwin/host-bound-allowed.txt"
[ -f "$ALLOW" ] || die "no $ALLOW"

NM="${NM:-}"
if [ -z "$NM" ]; then
    for c in llvm-nm-18 llvm-nm nm; do
        command -v "$c" >/dev/null 2>&1 && { NM="$c"; break; }
    done
fi
# The refusal matters as much as the search (gen_tbd.sh learned this the hard
# way): a missing tool that yields nothing makes every root look clean.
[ -n "$NM" ] || die "no nm found (llvm-nm-18, llvm-nm or nm)"
OTOOL="${OTOOL:-}"
if [ -z "$OTOOL" ]; then
    for c in llvm-otool-18 llvm-otool otool; do
        command -v "$c" >/dev/null 2>&1 && { OTOOL="$c"; break; }
    done
fi
[ -n "$OTOOL" ] || die "no otool found (llvm-otool-18, llvm-otool or otool)"

strip_banners() { grep -vE '^$|\(for architecture .*\):$|^[^ ]*:$'; }
exports_of() { "$NM" --defined-only --extern-only --format=just-symbols "$1" 2>/dev/null \
                 | sed 's/[[:space:]]*$//' | strip_banners | LC_ALL=C sort -u; }
imports_of() { "$NM" -u "$1" 2>/dev/null | strip_banners | awk '{print $NF}' | LC_ALL=C sort -u; }

# `<symbol> <TAB> <library short name>` for every two-level undefined symbol.
# nm -m spells a flat bind "(dynamically looked up)", which gets no row here
# and is graded against the whole root instead -- which is what the loader does
# for BIND_SPECIAL_DYLIB_FLAT_LOOKUP.
twolevel_of() {
    "$NM" -m "$1" 2>/dev/null | strip_banners \
      | sed -n 's/.*(undefined)[^ ]* external \([^ ]*\) (from \([^)]*\)).*/\1\t\2/p'
}

# install names, in ordinal order, tagged with whether they are re-exported.
deps_of() {
    "$OTOOL" -l "$1" 2>/dev/null | awk '
        /LC_LOAD_DYLIB|LC_LOAD_WEAK_DYLIB|LC_LAZY_LOAD_DYLIB|LC_LOAD_UPWARD_DYLIB/ {c="load"}
        /LC_REEXPORT_DYLIB/ {c="reexport"}
        c && /^ *name / {print c "\t" $2; c=""}'
}

is_macho() {
    local m
    m=$(head -c 4 "$1" 2>/dev/null | LC_ALL=C od -An -tx1 | tr -d ' \n')
    case "$m" in cffaedfe|cefaedfe|feedfacf|feedface|cafebabe|bebafeca) return 0 ;; esac
    return 1
}

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

overall=0

grade_root() { # grade_root <root-dir> <depth>
    local root="$1" depth="$2"
    root="$(cd "$root" 2>/dev/null && pwd)" || { echo "!! no such root: $1" >&2; return 1; }

    local -a IMG=() CAND=()
    local f
    # -L, and it is load-bearing rather than tidy: a root assembled out of
    # SYMLINKS (which is how you stage one without copying through a bind
    # mount, see [[machorun-project]] on silent truncation) has no regular
    # files in it at all. Without -L this walk finds nothing, the union of
    # exports is empty, and every symbol in the root is reported MISSING --
    # a checker failing in the direction that looks like a finding.
    while IFS= read -r f; do
        CAND+=("$f")
        is_macho "$f" && IMG+=("$f")
    done < <(find -L "$root" \
                \( -type d -name '*-park' \) -prune \
                -o -type f \
                    ! -name '*.txt' ! -name '*.md' ! -name '*.tbd' ! -name '*.json' \
                    -print \
                2>/dev/null | LC_ALL=C sort)

    # AN EMPTY SCOPE IS NEVER A PASS. "0 unresolved out of 0 images" is what a
    # wrong path, a bad filter or a missing tool all look like.
    if [ ${#IMG[@]} -eq 0 ]; then
        echo "!! ${root}: no Mach-O images found (${#CAND[@]} candidate files)." >&2
        echo "   Refusing rather than reporting 0 unresolved symbols out of 0." >&2
        return 1
    fi

    # EVERY per-run file, including the closure cache and the install-name
    # index. Leaving `close.*` behind made the depth-0 run reuse the depth-4
    # answer, so the two depths agreed and the selftest concluded the walk was
    # not running -- a cache older than its question, one directory over from
    # the stale-artifact shape this project keeps meeting.
    rm -f "$TMP"/exp.* "$TMP"/imp.* "$TMP"/two.* "$TMP"/dep.* "$TMP"/close.* \
          "$TMP"/byname
    : > "$TMP/byname"
    : > "$TMP/all_exp"
    local i=0 rel
    for f in "${IMG[@]}"; do
        exports_of "$f" > "$TMP/exp.$i"
        imports_of "$f" > "$TMP/imp.$i"
        twolevel_of "$f" > "$TMP/two.$i"
        deps_of    "$f" > "$TMP/dep.$i"
        cat "$TMP/exp.$i" >> "$TMP/all_exp"
        # The loader maps a Darwin absolute path to <root><path>, so the path
        # under the root IS the install name. Index by that, not by basename:
        # tests/bin/loader_path exists precisely because two dylibs can share a
        # basename in different directories.
        rel="${f#$root}"
        printf '%s\t%s\n' "$rel" "$i" >> "$TMP/byname"
        i=$((i + 1))
    done
    LC_ALL=C sort -u "$TMP/all_exp" -o "$TMP/all_exp"

    # closure <index> <depth> -- exports of an image plus, transitively, the
    # exports of everything it RE-EXPORTS. Same shape and same limit as
    # src/resolve.c's lookup_in().
    closure() {
        local ix="$1" d="$2" kind name jx
        [ "$d" -ge 0 ] || return 0
        cat "$TMP/exp.$ix"
        while IFS=$'\t' read -r kind name; do
            [ "$kind" = reexport ] || continue
            jx=$(awk -F'\t' -v n="$name" '$1==n{print $2; exit}' "$TMP/byname")
            [ -n "$jx" ] || continue
            closure "$jx" $((d - 1))
        done < "$TMP/dep.$ix"
    }

    local n_missing=0 n_misplaced=0 n_imports=0
    : > "$TMP/missing"; : > "$TMP/misplaced"

    i=0
    for f in "${IMG[@]}"; do
        rel="${f#$root}"
        n_imports=$((n_imports + $(grep -c . "$TMP/imp.$i")))

        # MISSING: nothing in the root defines it at all.
        comm -23 "$TMP/imp.$i" "$TMP/all_exp" | while IFS= read -r s; do
            printf '%s\t%s\n' "$s" "$rel"
        done >> "$TMP/missing"

        # MISPLACED: defined somewhere, but not reachable from the library the
        # bind names. Resolving the short name nm prints back to a dependency
        # is done by MATCHING, and an ambiguous match is refused rather than
        # guessed -- nm strips an Apple version suffix ("libSystem.B.dylib" is
        # printed "libSystem") and two deps could collide under that rule.
        if [ -s "$TMP/two.$i" ]; then

            while IFS=$'\t' read -r sym short; do
                grep -qx "$sym" "$TMP/all_exp" || continue   # already MISSING
                local hits jx
                hits=$(awk -F'\t' '{print $2}' "$TMP/dep.$i" | while IFS= read -r n; do
                          b=$(basename "$n"); b="${b%.dylib}"
                          [ "$b" = "$short" ] && { echo "$n"; continue; }
                          case "$b" in "$short".*) echo "$n" ;; esac
                       done)
                [ "$(printf '%s\n' "$hits" | grep -c .)" = 1 ] || continue
                jx=$(awk -F'\t' -v n="$hits" '$1==n{print $2; exit}' "$TMP/byname")
                [ -n "$jx" ] || continue
                if [ ! -f "$TMP/close.$jx" ]; then
                    closure "$jx" "$depth" | LC_ALL=C sort -u > "$TMP/close.$jx"
                fi
                grep -qx "$sym" "$TMP/close.$jx" || \
                    printf '%s\t%s\t%s\n' "$sym" "$rel" "$hits" >> "$TMP/misplaced"
            done < "$TMP/two.$i"
        fi
        i=$((i + 1))
    done

    # Classify MISSING the way the boundary is actually built. Three very
    # different things end up on that list and only the third is a finding.
    LC_ALL=C sort -u "$TMP/missing" -o "$TMP/missing"
    LC_ALL=C sort -u "$TMP/misplaced" -o "$TMP/misplaced"
    awk -F'\t' '{print $1}' "$TMP/missing" | LC_ALL=C sort -u > "$TMP/missing_sym"
    grep    '^_glibc_' "$TMP/missing_sym" > "$TMP/m_glibc"  || true
    grep -v '^_glibc_' "$TMP/missing_sym" > "$TMP/m_rest"   || true
    grep -vE '^[[:space:]]*(#|$)' "$ROOT/darwin/loader-exports.txt" \
        | awk '{print $1}' | LC_ALL=C sort -u > "$TMP/ldx"
    comm -12 "$TMP/m_rest" "$TMP/ldx" > "$TMP/m_loader"
    comm -23 "$TMP/m_rest" "$TMP/ldx" > "$TMP/m_rest2"
    # The MAIN EXECUTABLE's header. A root is a set of libraries and has no
    # guest in it, so these can only ever be reported missing here and are
    # never host-bound at run time: the bind names the executable ordinal (or
    # is flat) and the guest supplies it. Bucketed and counted rather than
    # filtered away -- a name that vanishes from the output is a name nobody
    # can audit.
    grep -xE '__mh_execute_header|___mh_execute_header|__mh_dylib_header' \
        "$TMP/m_rest2" > "$TMP/m_exe" || true
    grep -vxE '__mh_execute_header|___mh_execute_header|__mh_dylib_header' \
        "$TMP/m_rest2" > "$TMP/m_plain" || true

    n_missing=$(grep -c . "$TMP/m_plain")
    n_misplaced=$(grep -c . "$TMP/misplaced")

    printf '%s\n' "$root"
    printf '   %d Mach-O images (%d files considered), %d undefined symbols\n' \
        "${#IMG[@]}" "${#CAND[@]}" "$n_imports"
    printf '   host-bound: %4d  _glibc_* (the labelled boundary, darwin/src/dsys.h)\n' \
        "$(grep -c . "$TMP/m_glibc")"
    printf '               %4d  loader exports (darwin/loader-exports.txt)\n' \
        "$(grep -c . "$TMP/m_loader")"
    printf '               %4d  main-executable header (supplied by the guest, not the root)\n' \
        "$(grep -c . "$TMP/m_exe")"
    printf '               %4d  PLAIN C NAMES -- nobody asserted these\n' "$n_missing"
    printf '   misplaced:  %4d  defined in the root, unreachable from the named library\n' \
        "$n_misplaced"

    # compiler-rt family rows: Mach-O name is "_" + the X() cname. awk field 4
    # is the family string. Mixed-case cnames (__isPlatform*) live here.
    awk -F'"' '/^ *X\(/ && $4=="compiler-rt" { print "_" $2 }' \
        "$ROOT/src/host_deny.c" | LC_ALL=C sort -u > "$TMP/denied_rt"

    if [ "$n_missing" != 0 ]; then
        while IFS= read -r s; do
            local who deny=""
            who=$(awk -F'\t' -v s="$s" '$1==s{printf "%s ", $2}' "$TMP/missing")
            if grep -qx "$s" "$TMP/denied_rt"; then
                deny="  [DENIED — compiler-rt builtin; reaching glibc means a dylib was linked without libclang_rt.osx.a]"
            elif grep -q "\"${s#_}\"" "$ROOT/src/host_deny.c"; then
                deny="  [DENIED by src/host_deny.c]"
            fi
            printf '     %-28s wanted by %s%s\n' "$s" "$who" "$deny"
        done < "$TMP/m_plain"
    fi
    if [ "$n_misplaced" != 0 ]; then
        while IFS=$'\t' read -r s who lib; do
            printf '     %-28s %s binds it two-level to %s, which does not\n' "$s" "$who" "$lib"
            printf '     %-28s export it or re-export anything that does\n' ""
        done < "$TMP/misplaced"
    fi

    # --------------------------------------------------------------- verdict
    # Reporting is the default; --strict is what makes it a gate. Every plain
    # name must be accounted for by a DECISION: denied (bound to a loud stub,
    # src/host_deny.c -- ABI-divergent Darwin C names OR compiler-rt builtins
    # whose reaching glibc means a dylib was linked without libclang_rt.osx.a)
    # or written down as measured-compatible (darwin/host-bound-allowed.txt).
    # Compiler-rt builtins must never go on the allow list. An unaccounted
    # one fails.
    [ "$STRICT" = 1 ] || return 0

    # Mixed-case compiler-rt hooks (__isPlatformVersionAtLeast) are deny rows.
    # [a-z_0-9]+ dropped them, so --strict listed a builtin as unaccounted
    # and invited a host-bound-allowed row -- the wrong fix.
    grep -oE '^ *X\([A-Za-z_][A-Za-z_0-9]*, "[A-Za-z_][A-Za-z_0-9]*"' "$ROOT/src/host_deny.c" \
        | sed 's/.*"\(.*\)"/_\1/' | LC_ALL=C sort -u > "$TMP/denied"
    grep -oE '^_[A-Za-z_][A-Za-z_0-9]*' "$ALLOW" | LC_ALL=C sort -u > "$TMP/allowed"
    [ -s "$TMP/denied" ] || { echo "!! parsed no rows out of src/host_deny.c" >&2; return 1; }

    comm -23 "$TMP/m_plain" <(LC_ALL=C sort -u "$TMP/denied" "$TMP/allowed") > "$TMP/unaccounted"
    comm -13 "$TMP/m_plain" "$TMP/allowed" > "$TMP/unused"

    if [ -s "$TMP/unused" ]; then
        printf '   note: %d allowed name(s) nothing in this root imports:%s\n' \
            "$(grep -c . "$TMP/unused")" "$(tr '\n' ' ' < "$TMP/unused" | sed 's/^/ /')"
    fi
    if [ -s "$TMP/unaccounted" ]; then
        echo "!! plain C name(s) reaching glibc with nobody's assertion behind them:" >&2
        sed 's/^/     /' "$TMP/unaccounted" >&2
        echo "   Each one is answered by glibc BY NAME, with no translation. Decide:" >&2
        echo "     * measured compatible -> add a row to darwin/host-bound-allowed.txt" >&2
        echo "       saying WHAT WAS CHECKED (six hazard families, not just structs);" >&2
        echo "     * divergent -> add a row to src/host_deny.c so it dies naming itself;" >&2
        echo "     * ours to implement -> implement it in darwin/src and it stops being" >&2
        echo "       undefined at all;" >&2
        echo "     * compiler-rt builtin (___divti3, ___isPlatform*, ___truncsfhf2, …) ->" >&2
        echo "       do NOT add it to host-bound-allowed.txt. A builtin reaching glibc" >&2
        echo "       means a dylib was linked without libclang_rt.osx.a (PR #64)." >&2
        echo "       Rebuild that dylib NOUNDEFS with the archive, or add a compiler-rt" >&2
        echo "       row to src/host_deny.c so the miss dies naming the archive." >&2
        if grep -qxE '___divti3|___modti3|___udivti3|___umodti3|___truncsfhf2|___isPlatformVersionAtLeast|___isPlatformOrVariantPlatformVersionAtLeast' "$TMP/unaccounted"; then
            echo "   (a compiler-rt name is on that list: the dylib was linked without the archive)" >&2
        fi
        return 1
    fi
    if [ "$n_misplaced" != 0 ]; then
        echo "!! $n_misplaced symbol(s) are in this root and unreachable from the library" >&2
        echo "   that binds them. src/resolve.c does NOT fall back to a flat search after" >&2
        echo "   a two-level miss, so these reach glibc exactly as a missing symbol would." >&2
        return 1
    fi
    return 0
}

# ------------------------------------------------------------------ selftest
#
# A checker nobody has watched fail is a comment. This proves three things,
# each in the direction that would otherwise be silent: a name nothing defines
# is REPORTED, a name something defines is NOT, and the transitive re-export
# walk is load-bearing rather than decorative.
if [ "$SELFTEST" = 1 ]; then
    fail=0
    root="$(cd "${ROOTS[0]}" && pwd)"
    echo "selftest, building its own probe against $root"

    command -v clang >/dev/null 2>&1 || die "selftest needs clang -- run it in the test-bed container"
    LD64=ld64.lld-18; command -v $LD64 >/dev/null 2>&1 || LD64=ld64.lld
    command -v $LD64 >/dev/null 2>&1 || die "selftest needs ld64.lld"

    W=$(mktemp -d)
    mkdir -p "$W/root/usr/lib"
    for f in "$root"/usr/lib/*.dylib; do ln -s "$f" "$W/root/usr/lib/"; done

    # ONE probe dylib carrying three imports with three different correct
    # verdicts. Same file, same run: a checker that reported all three the same
    # way -- however that way -- fails at least one of them.
    #
    #   machorun_selftest_no_such_symbol   nothing defines it     -> MISSING
    #   malloc                             libSystem defines it   -> silent
    #   __gxx_personality_v0               libc++abi defines it, and the bind
    #                                      names libc++.1, which REACHES it
    #                                      only through a re-export -> silent
    #                                      at depth 4, MISPLACED at depth 0
    #
    # The third is the one that matters. It is the chain that made a one-level
    # walk invent three findings when this check was first written by hand, and
    # it is also the shape of a real defect (#61): a symbol present in the
    # process and unreachable from the library allowed to answer.
    cat > "$W/p.c" <<'PROBE'
extern void *machorun_selftest_no_such_symbol(void);
extern void *malloc(unsigned long);
extern void  __gxx_personality_v0(void);
void *selftest_probe(void);
void *selftest_probe(void)
{
    __gxx_personality_v0();
    return machorun_selftest_no_such_symbol() ? malloc(1) : 0;
}
PROBE
    clang -target arm64-apple-macos11 -isysroot "$ROOT/sdk" -fPIC -O0 \
          -c "$W/p.c" -o "$W/p.o" 2>"$W/log" \
      && $LD64 -dylib -arch arm64 -platform_version macos 11.0 11.0 \
               -install_name /usr/lib/libselftest.dylib \
               -L"$ROOT/sdk/usr/lib" -lSystem -lc++ \
               -U _machorun_selftest_no_such_symbol \
               -o "$W/root/usr/lib/libselftest.dylib" "$W/p.o" 2>>"$W/log" \
      || { echo "selftest: could not build the probe dylib:" >&2
           sed 's/^/    /' "$W/log" >&2; rm -rf "$W"; exit 1; }

    out4=$(grade_root "$W/root" 4) || die "selftest: the probe root would not grade"
    out0=$(grade_root "$W/root" 0) || die "selftest: the probe root would not grade at depth 0"
    printf '%s\n' "$out4" | sed 's/^/   /'

    if printf '%s\n' "$out4" | grep -q '_machorun_selftest_no_such_symbol'; then
        echo "   ok   a fabricated import is reported MISSING"
    else
        echo "   FAIL a fabricated import was NOT reported"; fail=1
    fi
    if printf '%s\n' "$out4" | grep -qE '^ +_malloc '; then
        echo "   FAIL _malloc was reported; the root defines it"; fail=1
    else
        echo "   ok   _malloc, imported by the same probe, is NOT reported"
    fi

    mis4=$(printf '%s\n' "$out4" | awk '/misplaced:/{print $2}')
    mis0=$(printf '%s\n' "$out0" | awk '/misplaced:/{print $2}')
    if printf '%s\n' "$out4" | grep -q '__gxx_personality_v0'; then
        echo "   FAIL __gxx_personality_v0 reported at depth 4; the re-export chain reaches it"
        fail=1
    elif printf '%s\n' "$out0" | grep -q '__gxx_personality_v0' && \
         [ "${mis0:-0}" -gt "${mis4:-0}" ]; then
        echo "   ok   re-export walk is load-bearing: __gxx_personality_v0 is MISPLACED at"
        echo "        depth 0 ($mis0 total) and correctly silent at depth 4 ($mis4 total)"
    else
        echo "   FAIL the walk changes nothing ($mis0 misplaced at depth 0, $mis4 at depth 4)."
        echo "        A one-level walk invents findings on this exact chain, so a checker"
        echo "        that cannot tell the two depths apart is not doing the walk."
        fail=1
    fi

    # (4) --strict must REFUSE the probe root. Reporting a finding and exiting
    #     0 is the failure mode that made this whole area invisible: an
    #     unaccounted name is only a gate if something stops.
    STRICT=1
    if grade_root "$W/root" 4 >/dev/null 2>&1; then
        echo "   FAIL --strict exited 0 on a root with an unaccounted plain name"
        fail=1
    else
        echo "   ok   --strict refuses a root with an unaccounted plain name"
    fi
    STRICT=0

    # (5) `*-park` is a parking spot, not a library path. A copy of the probe
    #     under usr/lib-arm64-park must not change the image count or the
    #     findings -- CHECK 5 grades what the loader would search.
    mkdir -p "$W/root/usr/lib-arm64-park/swift"
    cp "$W/root/usr/lib/libselftest.dylib" \
       "$W/root/usr/lib-arm64-park/swift/libswiftCore.dylib"
    out_park=$(grade_root "$W/root" 4) || die "selftest: parked copy made the root ungradable"
    n4=$(printf '%s\n' "$out4" | awk '/Mach-O images/{print $1; exit}')
    np=$(printf '%s\n' "$out_park" | awk '/Mach-O images/{print $1; exit}')
    if [ "$n4" = "$np" ] && [ -n "$n4" ]; then
        echo "   ok   usr/lib-arm64-park does not add a Mach-O image ($n4 both times)"
    else
        echo "   FAIL parked dylib counted: $n4 images without park, $np with"; fail=1
    fi
    if printf '%s\n' "$out_park" | grep -q 'lib-arm64-park'; then
        echo "   FAIL findings name lib-arm64-park"; fail=1
    else
        echo "   ok   findings do not name the parking directory"
    fi

    rm -rf "$W"
    [ "$fail" = 0 ] && { echo "selftest: ok -- 5/5"; exit 0; }
    echo "selftest: FAILED" >&2; exit 1
fi

for r in "${ROOTS[@]}"; do
    grade_root "$r" "$DEPTH" || overall=1
done
exit "$overall"
