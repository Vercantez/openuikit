#!/bin/bash
# check_stale.sh -- refuse when a built dylib is older than the source it is
# built from.
#
#   scripts/check_stale.sh          report and exit non-zero if anything is stale
#   scripts/check_stale.sh --warn   report, but always exit 0
#
# WHY THIS EXISTS, and it is worth reading before deciding it is redundant.
#
# On 2026-08-27 the sigset_t wrapper was committed at 05:55 and the shipped
# darwin/usr/lib/libSystem.B.dylib was still the one built at 05:24. Someone
# checking the fix the obvious way -- `nm` the dylib we ship, look for
# _sigprocmask -- found zero defined symbols and correctly concluded the
# wrapper did not work. It did work. The artefact was half an hour behind its
# own source.
#
# What makes that worth a mechanism rather than a habit is that EVERY OTHER
# CHECK WE HAVE AGREES WITH THE STALE STATE and none of them is looking at it:
# difftest passes (it rebuilds inside the container before it runs), the three
# compile probes pass (they compile source), sdk_abi_probe passes (it builds
# its own guest), and `git log` says the fix landed (it did). The thing that is
# stale has no version in it, so nothing that compares versions can see it.
#
# ONE CORRECTION TO THE ORIGINAL PROPOSAL, which was framed as "if the build
# products are committed, refuse when they are older than their sources".
# darwin/usr/lib is NOT tracked by git -- `git ls-files darwin/usr/lib` returns
# nothing, and .gitignore excludes it. Every dylib there is a local build
# product. That makes the problem SMALLER in one way (no stale binary can be
# pushed to anyone else) and LARGER in another: there is no commit, no hash and
# no diff to notice it by, so a stale artefact is invisible to review as well
# as to the gates. Hence mtime, which is the only evidence a local build
# product carries. A recorded build stamp would survive a fresh clone better,
# but a fresh clone has no dylibs at all, which this script reports as MISSING
# rather than as stale -- a different thing, with a different fix.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MODE=fail
case "${1:---}" in
    --warn) MODE=warn ;;
    --) ;;
    -h|--help) sed -n '2,35p' "$0"; exit 0 ;;
    *) echo "check_stale: unknown option $1" >&2; exit 64 ;;
esac

# `date -r` MEANS OPPOSITE THINGS on the two systems this runs on, which is
# exactly the kind of thing this script exists to be annoyed by: GNU reads it
# as "the mtime of this FILE", BSD as "format this EPOCH". Both spellings are
# below, chosen once, the same way sdk_stage.sh picks sha256sum or shasum.
if stat -c %Y . >/dev/null 2>&1; then
    mtime()  { stat -c %Y "$1"; }                       # GNU coreutils
    fmt()    { date -d "@$1" '+%Y-%m-%d %H:%M:%S'; }
else
    mtime()  { stat -f %m "$1"; }                       # BSD / stock macOS
    fmt()    { date -r "$1" '+%Y-%m-%d %H:%M:%S'; }
fi

# Newest mtime under a set of paths, as an integer. Missing paths contribute
# nothing rather than failing: build_quartz.sh's vendor tree is optional.
newest() {
    local p n=0 t f
    for p in "$@"; do
        [ -e "$ROOT/$p" ] || continue
        while IFS= read -r f; do
            t=$(mtime "$f" 2>/dev/null) || continue
            [ "$t" -gt "$n" ] && n=$t
        done < <(find "$ROOT/$p" -type f \
                    \( -name '*.c' -o -name '*.h' -o -name '*.cpp' \
                       -o -name '*.mm' -o -name '*.m' -o -name '*.sh' \) 2>/dev/null)
    done
    echo "$n"
}

when() { if [ "$1" = 0 ]; then echo "(none)"; else fmt "$1"; fi; }

# artefact <TAB> the paths it is built from. Deliberately over-approximate:
# a false "stale" costs one rebuild, a false "fresh" costs an afternoon.
#
# The Swift dylibs are absent on purpose. They are STAGED from
# ~/swiftcore-macho by scripts/stage_swiftcore.sh rather than built here, so
# their sources are not in this tree and their mtimes say nothing about
# whether they are current. That is a real gap and belongs to whoever owns the
# staging, not to this check -- naming it here with the wrong source set would
# be worse than leaving it out, because it would read as covered.
TARGETS=(
    "darwin/usr/lib/libSystem.B.dylib|darwin/src scripts/build_darwin.sh"
    "darwin/usr/lib/libc++.1.dylib|darwin/src scripts/build_darwin.sh"
    "darwin/usr/lib/libobjc.A.dylib|vendor/objc4 vendor/objc4-priv scripts/build_objc4.sh"
    "darwin/usr/lib/libquartz.dylib|vendor/quartz scripts/build_quartz.sh"
    "build/machorun|src scripts/build.sh"
)

stale=0 missing=0 ok=0
printf '%s\n' "== built artefacts against the sources they are built from"

for row in "${TARGETS[@]}"; do
    art="${row%%|*}"
    srcs="${row#*|}"

    if [ ! -e "$ROOT/$art" ]; then
        printf '   %-38s MISSING   never built here; run scripts/build.sh\n' "$art"
        missing=$((missing + 1))
        continue
    fi

    # shellcheck disable=SC2086
    src_t=$(newest $srcs)
    art_t=$(mtime "$ROOT/$art")

    if [ "$src_t" -gt "$art_t" ]; then
        printf '   %-38s STALE\n' "$art"
        printf '       built  %s\n' "$(when "$art_t")"
        printf '       source %s   (newest under: %s)\n' "$(when "$src_t")" "$srcs"
        stale=$((stale + 1))
    else
        printf '   %-38s ok        built %s\n' "$art" "$(when "$art_t")"
        ok=$((ok + 1))
    fi
done

printf '%s\n' "   ---------------------------------------------------------------"
printf '   ok %d  stale %d  missing %d\n' "$ok" "$stale" "$missing"

if [ "$stale" -gt 0 ]; then
    # Name what was found rather than just declining: a refusal that reports
    # its evidence has twice handed someone the next finding instead of a
    # second question.
    cat >&2 <<MSG

check_stale: $stale artefact(s) are older than their own source.

  Anything that inspects those files -- nm, otool, a symbol count, "does the
  fix work" -- is reading a build that predates the fix. Rebuild first:

      scripts/build.sh everything

  This is not a correctness failure in the code. It is the case where every
  other check passes and is looking somewhere else.
MSG
    [ "$MODE" = warn ] && exit 0
    exit 1
fi
exit 0
