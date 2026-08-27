#!/bin/bash
# check_stale.sh -- refuse when a built dylib is older than the source it is
# built from.
#
#   scripts/check_stale.sh          report and exit non-zero if anything is stale
#   scripts/check_stale.sh --warn   report, but always exit 0
#   scripts/check_stale.sh --stamp <artefact>...
#                                   record what those artefacts were JUST built
#                                   from. Called by scripts/build.sh after a
#                                   successful build, never on its own.
#
# IT COMPARES CONTENT, AND FALLS BACK TO mtime. A recorded stamp is the hash of
# the source set an artefact was built from; a mismatch means the sources are
# not what produced it. mtime can only say "the artefact is not older", which
# agrees with reality whenever the tree moved SIDEWAYS rather than forwards --
# a branch switch, a revert, a rebase, or a build run while the working tree
# still held conflict markers. That last one happened on 2026-08-27 and this
# script reported "ok 6" about it: correct, and useless.
#
# It also removes FALSE stales, which matter because a gate that cries wolf is
# a gate people stop reading. Restoring a file from a backup gives it a new
# mtime and identical content: mtime says stale, the hash says ok, and the hash
# is right.
#
# A stamp lives in build/, which is gitignored, so a fresh clone has none and
# gets the mtime check -- the behaviour that existed before. That is the
# correct degradation: a clone has no dylibs either, which is MISSING rather
# than stale.
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
    # --stamp records, for each named artefact, the hash of the sources it was
    # JUST built from. It is called by scripts/build.sh immediately after a
    # successful build, and never on its own -- a stamp written without a build
    # is a lie that reads exactly like the truth. build.sh runs `set -eu`, so a
    # failed sub-build aborts before reaching its stamp.
    --stamp) MODE=stamp ;;
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

# sha256, picked once, the same way mtime/fmt are above and for the same
# reason: the two systems this runs on spell it differently.
if command -v sha256sum >/dev/null 2>&1; then
    sha() { sha256sum "$@"; }                          # GNU coreutils
else
    sha() { shasum -a 256 "$@"; }                      # stock macOS
fi

# THE INPUT SET, HASHED. One definition, used for BOTH stamping and checking --
# which is the point. A stamp written from one file list and checked against
# another is a gate that agrees with itself and with nothing else.
#
# It hashes CONTENT and PATH, not mtimes: `git checkout` of an older branch,
# a revert, a rebase, and a build run while the tree held conflict markers all
# leave mtimes that look newer than the artefact while the CONTENT is not what
# the artefact was built from. mtime cannot see any of those.
inputs_hash() {
    local p f
    for p in "$@"; do
        [ -e "$ROOT/$p" ] || continue
        find "$ROOT/$p" -type f \
            \( -name '*.c' -o -name '*.h' -o -name '*.cpp' \
               -o -name '*.mm' -o -name '*.m' -o -name '*.sh' \) 2>/dev/null
    done | LC_ALL=C sort | while IFS= read -r f; do
        printf '%s  %s\n' "$(sha "$f" | cut -d' ' -f1)" "${f#$ROOT/}"
    done | sha | cut -d' ' -f1
}

STAMPS="$ROOT/build/.input-hashes"

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
# The Swift dylibs are absent from THIS list on purpose. They are STAGED from
# ~/swiftcore-macho by scripts/stage_swiftcore.sh rather than built here, so
# their sources are not in this tree and their mtimes say nothing about
# whether they are current. Naming them here with the wrong source set would be
# worse than leaving them out, because it would read as covered. They get a
# different check instead -- see PAIRS below, which asks the question that IS
# answerable about a staged copy.
TARGETS=(
    "darwin/usr/lib/libSystem.B.dylib|darwin/src scripts/build_darwin.sh"
    "darwin/usr/lib/libc++.1.dylib|darwin/src scripts/build_darwin.sh"
    # Added when libc++abi arrived with the exception work. A gate that does
    # not know about a new artefact reports "ok" about the four it does know,
    # which is the most reassuring possible way to be silent about the fifth.
    "darwin/usr/lib/libc++abi.dylib|vendor/libcxxabi darwin/src scripts/build_darwin.sh"
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
    now_hash=$(inputs_hash $srcs)

    if [ "$MODE" = stamp ]; then
        [ $# -gt 1 ] && ! printf '%s\n' "$@" | grep -qx -- "$art" && continue
        mkdir -p "$(dirname "$STAMPS")"
        [ -f "$STAMPS" ] && grep -v "^$art " "$STAMPS" > "$STAMPS.tmp" 2>/dev/null || : > "$STAMPS.tmp"
        printf '%s %s\n' "$art" "$now_hash" >> "$STAMPS.tmp"
        mv "$STAMPS.tmp" "$STAMPS"
        printf '   %-38s stamped\n' "$art"
        ok=$((ok + 1))
        continue
    fi

    # THE HASH IS THE ANSWER WHEN THERE IS ONE; mtime is the fallback.
    #
    # A matching hash says the sources are byte-for-byte what this artefact was
    # built from. mtime can only say "the artefact is not older", which agrees
    # with reality in every case where the tree moved sideways rather than
    # forwards -- a branch switch, a revert, or a build run while the working
    # tree still held conflict markers. That last one happened on 2026-08-27
    # and check_stale reported ok 6 about it, correctly and uselessly.
    was_hash=""
    [ -f "$STAMPS" ] && was_hash=$(grep "^$art " "$STAMPS" 2>/dev/null | cut -d' ' -f2)

    if [ -n "$was_hash" ] && [ "$was_hash" != "$now_hash" ]; then
        printf '   %-38s STALE     sources changed since it was built\n' "$art"
        printf '       built from %s\n' "$was_hash"
        printf '       sources now %s   (under: %s)\n' "$now_hash" "$srcs"
        stale=$((stale + 1))
        continue
    fi
    if [ -n "$was_hash" ]; then
        printf '   %-38s ok        sources unchanged since it was built\n' "$art"
        ok=$((ok + 1))
        continue
    fi

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

# ------------------------------------------------- staged copies: IDENTITY
#
# For an artefact STAGED from another repo, "is it older than its source" is
# unanswerable here -- the source is not in this tree. But a different question
# is both answerable and the one that actually bites: **is the file a guest
# LINKS against the same bytes as the file it LOADS?**
#
# Those are two different paths for the Swift runtime. scripts/swift_gate.sh
# links with `-lswiftCore` resolved from build/swift-res/macosx/arm64, and the
# loader resolves the install name to darwin/usr/lib/swift at run time. Nothing
# has ever checked that they are the same file.
#
# When they diverge, the failure has a very specific and misleading shape: the
# LINK SUCCEEDS -- ld64 is satisfied by the copy it was shown -- and the
# program dies at load, which reads as a loader bug, in the loader, to whoever
# is least equipped to suspect a staging script. That is the unbacked-promise
# bug inverted, and a neighbouring project lost time to exactly it.
#
# Measured 2026-08-27: both copies are md5 ff9ff833474c7973b180f29ec0c58ea8, so
# machorun's Swift path is currently clean. This check is what keeps it that
# way, and it is deliberately about IDENTITY rather than freshness: two copies
# staged from the same place at different times are wrong even if both are new.
PAIRS=(
    "build/swift-res/macosx/arm64/libswiftCore.dylib|darwin/usr/lib/swift/libswiftCore.dylib"
)

if command -v md5sum >/dev/null 2>&1; then digest() { md5sum "$1" | cut -d' ' -f1; }
else                                      digest() { md5 -q "$1"; }; fi

mismatch=0
for row in "${PAIRS[@]}"; do
    a="${row%%|*}"; b="${row#*|}"
    # Only meaningful when BOTH exist. One missing is the staging script's
    # business, and is already reported by --check there.
    [ -f "$ROOT/$a" ] && [ -f "$ROOT/$b" ] || continue
    da=$(digest "$ROOT/$a"); db=$(digest "$ROOT/$b")
    if [ "$da" != "$db" ]; then
        printf '   %-38s LINK/LOAD MISMATCH\n' "$(basename "$a")"
        printf '       linked  %s  %s\n' "$da" "$a"
        printf '       loaded  %s  %s\n' "$db" "$b"
        mismatch=$((mismatch + 1))
    else
        printf '   %-38s ok        link == load (%s)\n' "$(basename "$a")" "${da:0:12}"
    fi
done

printf '%s\n' "   ---------------------------------------------------------------"
printf '   ok %d  stale %d  missing %d  link/load mismatch %d\n' \
       "$ok" "$stale" "$missing" "$mismatch"

if [ "$mismatch" -gt 0 ]; then
    cat >&2 <<MSG

check_stale: $mismatch staged artefact(s) differ between the LINK copy and the
LOAD copy.

  A guest will link cleanly against one file and load the other. The failure
  surfaces at dlopen, looks like a loader bug, and is not one. Re-stage:

      scripts/stage_swiftcore.sh

MSG
    [ "$MODE" = warn ] || exit 1
fi

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
