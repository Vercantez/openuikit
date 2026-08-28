#!/bin/bash
# require_fresh_root.sh -- refuse to run against a guest root that has drifted
# from ~/machorun, WITHOUT breaking the roots that are supposed to differ.
#
#   scripts/require_fresh_root.sh scratch/mrroot_full     # assert, or refuse
#   MRROOT_REFRESH=1 scripts/require_fresh_root.sh …      # re-copy the COPIES only
#
# WHY IT EXISTS. scratch/mrroot* hold machorun's userland, and a copy read long
# after it was made is indistinguishable from a fresh one. An enumeration on
# 2026-08-27 found five such trees, all stale, FOUR still carrying the
# malloc_type defect that cost this project a week -- live on disk, in trees
# guests are actually executed against, months after it was fixed at the source.
# scratch/ is gitignored, so there is no commit, no diff and no review to notice
# it by; machorun's own check_stale.sh grades six hardcoded paths, all inside
# ~/machorun, and a copy tree it has never heard of is what it structurally
# cannot see.
#
# ================== WHY IT WAS REWRITTEN (2026-08-27 evening) ==================
#
# The first version was ANTI-CORRELATED WITH CORRECTNESS on the root that
# matters. Measured both ways: it said `root fresh` about an mrroot_full that
# could not load a single guest, and `STALE … 3 of 7` about a correctly built
# one. Two structural reasons, and neither is a tuning problem:
#
#  (1) IT COULD NOT TELL *DERIVED* FROM *COPIED*. In mrroot_full, libSystem.B
#      and libc++.1 are UMBRELLAS -- our shim objects plus LC_REEXPORT_DYLIB of
#      machorun's real library, which is renamed alongside as *.real.dylib. They
#      are BUILD OUTPUTS and are SUPPOSED to differ. The guard graded them
#      against machorun's plain libraries, reported DRIFT, and prescribed
#      `MRROOT_REFRESH=1`, which overwrote each umbrella with the upstream file
#      -- deleting the shim layer. Someone followed that advice and left
#      mrroot_full unable to load anything for the rest of the day: every scene
#      died with `__NSGetMachExecuteHeader` undefined, a symbol that exists ONLY
#      in full/shims/concpatch.c and in no machorun libSystem ever (nm, and
#      `git log -S`). AND, in the same breath, it SKIPPED libSystem.real.dylib
#      as "local-only, no upstream counterpart" -- the one file in the root that
#      actually carries machorun's bytes, i.e. the single place where staleness
#      is a real question is the one place it never looked.
#
#  (2) IT ENUMERATED THE TARGET, NOT THE UPSTREAM. A dylib present in machorun
#      and absent from the root is structurally invisible. machorun's post-#55
#      layout added libc++abi.dylib (libobjc hard-requires it); the root had
#      none, and the guard reported "6 dylib(s) match". Adding the file made the
#      line read 7 -- THE DENOMINATOR MOVING WAS THE ONLY THING THAT MADE THE
#      OMISSION VISIBLE, and only to someone watching for it.
#
# So the root is now described by a MANIFEST that the script BUILDING it writes
# (full/scripts/build_full.sh), and the expected set is enumerated from
# ~/machorun, not from the root. Kinds and what each is graded on:
#
#   copy      byte-identical to machorun's file
#   renamed   identical to machorun's file OUTSIDE LC_ID_DYLIB -- the .real
#             libraries, whose install name legitimately differs so an umbrella
#             can re-export them (scripts/macho_same_except_id.pl)
#   umbrella  newer than every input, DEFINES its discriminator symbol, and
#             re-exports its .real. Never compared against machorun: it is a
#             different library on purpose.
#   staged    byte-identical to a RECORDED sha256 of the external artefact it was
#             staged from -- usually Apple's iOS simruntime dylibs. An optional
#             fifth field identifies a same-path machorun artefact this staged
#             file intentionally overrides, accounting for it without falsely
#             grading the two different runtimes as copies.
#   local     not graded; may excuse an upstream file from MISSING
#
# `staged` EXISTS AS ITS OWN KIND ON PURPOSE, and the reason is the history
# above. "Matches machorun" is meaningless for a file machorun has never had, so
# the tempting move is to file those under `local` and skip them -- and SKIPPING
# IS EXACTLY WHAT DOOMED THE UMBRELLA: `libSystem.real.dylib` was skipped as
# "local-only, no upstream counterpart" and that was the one file where
# staleness was a live question. A staged dylib has an invariant, it is just not
# machorun: identity against the external source it was taken from. Recording
# the SOURCE's digest is what keeps that from being self-reference -- a manifest
# line written by hashing the file already in the root would be a check that can
# never fail.
#
# WHAT WAS KEPT, because it was right. It REFUSES rather than auto-refreshing
# (refreshing by default would swap the runtime out from under someone
# deliberately testing an older one). It prints its DENOMINATORS. It refuses to
# grade a root where it compared nothing -- a vacuous green is worse than no
# check. And callers pass an explicit MRROOT through unguarded, because
# comparing an alternative runtime is a first-class operation and half the
# reason to point at another root is that it is deliberately not current.
#
# MRROOT_REFRESH NOW ONLY TOUCHES `copy` ROWS, and refuses outright if anything
# derived is wrong. The remedy for a derived file is `build_full.sh`; it can
# never be a `cp`.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MACHORUN=${MACHORUN:-$HOME/machorun}
TARGET=${1:?usage: require_fresh_root.sh <path-to-guest-root>}
case "$TARGET" in /*) ;; *) TARGET="$ROOT/$TARGET" ;; esac
SHORT=${TARGET#$ROOT/}

[ -d "$MACHORUN" ] || { echo "require_fresh_root: no machorun checkout at $MACHORUN" >&2; exit 2; }
[ -d "$TARGET" ]   || { echo "require_fresh_root: no such root $TARGET" >&2; exit 2; }

# ---- tools ----------------------------------------------------------------
# Mach-O readers differ between the two hosts this runs on: Apple's nm/otool on
# macOS, llvm-nm-18/llvm-otool-18 in the container. GNU binutils `nm` is on PATH
# in the container and CANNOT read Mach-O -- it prints "file format not
# recognized" and an empty symbol list, which downstream reads as "defines
# nothing". So the llvm-prefixed tools are preferred and the result is checked
# for vacuity below, rather than trusted.
NM=""; OTOOL=""
for c in llvm-nm-18 llvm-nm nm;       do command -v "$c" >/dev/null 2>&1 && { NM=$c; break; }; done
for c in llvm-otool-18 llvm-otool otool; do command -v "$c" >/dev/null 2>&1 && { OTOOL=$c; break; }; done
nm_defined() {
    case "$NM" in
        llvm-nm*) "$NM" --extern-only --defined-only "$1" 2>/dev/null | awk '{print $NF}' ;;
        nm)       "$NM" -gU "$1" 2>/dev/null | awk '{print $NF}' ;;
        *)        return 1 ;;
    esac
}
reexports() { "$OTOOL" -l "$1" 2>/dev/null | grep -A2 LC_REEXPORT_DYLIB | awk '/^ *name /{print $2}'; }
# sha256sum on Linux, shasum on macOS -- picked once, the way sdk_stage.sh does.
if command -v sha256sum >/dev/null 2>&1; then _sha256() { sha256sum | cut -d' ' -f1; }
else                                         _sha256() { shasum -a 256 | cut -d' ' -f1; }; fi

# ---- the manifest ---------------------------------------------------------
MANIFEST="$TARGET/.manifest"
MANIFEST_SRC="manifest"
if [ ! -f "$MANIFEST" ]; then
    # A root built before manifests existed, or by a script that writes none.
    # Fall back to the old model -- everything with an upstream counterpart is a
    # copy -- but SAY SO on every line of output. The old model is exactly what
    # destroyed mrroot_full, so it must never be silently in force.
    MANIFEST_SRC="default (no .manifest in this root)"
    MANIFEST=$(mktemp); trap 'rm -f "$MANIFEST"' EXIT
    {
        [ -f "$TARGET/machorun" ] && printf 'copy\tmachorun\tbuild/machorun\n'
        while IFS= read -r f; do
            rel=${f#$TARGET/}; up=${rel#darwin/usr/lib/}
            if [ -f "$MACHORUN/darwin/usr/lib/$up" ]; then
                printf 'copy\t%s\tdarwin/usr/lib/%s\n' "$rel" "$up"
            else
                printf 'local\t%s\t-\tno upstream counterpart (assumed by DEFAULT, not declared)\n' "$rel"
            fi
        done < <(find "$TARGET/darwin/usr/lib" -name '*.dylib' -type f 2>/dev/null | LC_ALL=C sort)
    } > "$MANIFEST"
fi

# ---- grade ----------------------------------------------------------------
n_copy=0; n_renamed=0; n_umbrella=0; n_staged=0; n_local=0
bad_copy=""; bad_derived=""; absent=""
declare -a NOTES=()
note() { NOTES+=("$1"); }
accounted=""      # upstream paths this root is known to account for

while IFS=$'\t' read -r kind rel up rest; do
    case "$kind" in ''|'#'*) continue ;; esac
    f="$TARGET/$rel"
    # For a `staged` row the third column is a sha256, not an upstream path.
    # Its optional fifth column explicitly names a machorun artefact that the
    # staged file replaces; absent that field it accounts for no upstream file.
    case "$kind" in
        staged)
            staged_up=$(printf '%s\n' "$rest" | awk -F '\t' 'NF >= 2 { print $2 }')
            [ "${staged_up:--}" = "-" ] || accounted="$accounted $staged_up" ;;
        *) [ "${up:--}" = "-" ] || accounted="$accounted $up" ;;
    esac
    case "$kind" in
    copy)
        n_copy=$((n_copy+1))
        # A declared copy that is not on disk is a MISSING, not a stale one:
        # "STALE COPIES" would send the reader to compare bytes that are not
        # there, and the two have different remedies.
        if [ ! -f "$f" ]; then
            n_copy=$((n_copy-1))
            accounted=$(printf '%s' "$accounted" | sed "s| $up\$|| ; s| $up | |")
            continue
        fi
        if [ ! -f "$MACHORUN/$up" ]; then
            bad_copy="$bad_copy$rel\tupstream $up is gone -- the manifest describes a machorun that no longer exists\n"; continue; fi
        if cmp -s "$f" "$MACHORUN/$up"; then
            note "$(printf '  %-42s copy      identical to %s' "$rel" "$up")"
        else
            bad_copy="$bad_copy$rel\tdiffers from $MACHORUN/$up\n"
        fi ;;
    staged)
        # Manifest columns here are: staged <rel> <sha256-of-source>
        # <where-it-came-from> [<machorun-path-intentionally-overridden>]
        n_staged=$((n_staged+1))
        want=$up
        srcdesc=$(printf '%s' "$rest" | cut -f1)
        if [ ! -f "$f" ]; then
            bad_derived="$bad_derived$rel\tdeclared staged but absent from the root\n"; continue; fi
        # A staged row with no recorded source digest is refused rather than
        # graded: hashing the file and comparing it to itself is the vacuous
        # green this whole script exists to refuse.
        if [ "${#want}" -ne 64 ]; then
            bad_derived="$bad_derived$rel\tmanifest records no sha256 for the staged source -- refusing to grade it against itself\n"; continue; fi
        got=$(_sha256 <"$f")
        if [ "$got" = "$want" ]; then
            note "$(printf '  %-42s staged    %s == recorded source (%s)' "$rel" "${got:0:16}" "$srcdesc")"
        else
            bad_derived="$bad_derived$rel\tis not the artefact it was staged from: have ${got:0:16}, recorded ${want:0:16} ($srcdesc)\n"
        fi ;;
    renamed)
        n_renamed=$((n_renamed+1))
        if [ ! -f "$f" ]; then
            bad_derived="$bad_derived$rel\tabsent from the root\n"; continue; fi
        out=$(perl "$ROOT/scripts/macho_same_except_id.pl" "$f" "$MACHORUN/$up" 2>&1)
        case "$out" in
            SAME*) note "$(printf '  %-42s renamed   %s' "$rel" "${out#SAME }")" ;;
            *)     bad_derived="$bad_derived$rel\tnot machorun's $up any more: $out\n" ;;
        esac ;;
    umbrella)
        n_umbrella=$((n_umbrella+1))
        sym=$(printf '%s' "$rest" | cut -f1)
        deps=$(printf '%s' "$rest" | cut -f2-)
        if [ ! -f "$f" ]; then
            bad_derived="$bad_derived$rel\tabsent from the root\n"; continue; fi
        why=""
        # (a) newer than every input -- per SOURCE, because a derived artefact
        #     assembled from several sources needs a freshness check per source.
        for d in $deps; do
            p="$TARGET/$d"; [ -f "$p" ] || p="$ROOT/$d"
            [ -f "$p" ] || { why="input $d does not exist"; break; }
            [ "$p" -nt "$f" ] && { why="older than its input $d"; break; }
        done
        # (b) defines the symbol that is its whole reason to exist
        if [ -z "$why" ] && [ "${sym:--}" != "-" ]; then
            defs=$(nm_defined "$f")
            if [ -z "$defs" ]; then
                why="could not read defined symbols with ${NM:-no nm found} -- refusing to grade"
            elif ! printf '%s\n' "$defs" | grep -qx "$sym"; then
                why="does not define $sym -- it is not an umbrella, it is a plain copy"
            fi
        fi
        # (c) actually re-exports its .real
        real=$(printf '%s\n' $deps | grep '\.real\.dylib$' | head -1)
        if [ -z "$why" ] && [ -n "$real" ] && [ -n "$OTOOL" ]; then
            printf '%s\n' "$(reexports "$f")" | grep -qx "/usr/lib/$(basename "$real")" \
                || why="does not LC_REEXPORT_DYLIB /usr/lib/$(basename "$real")"
        fi
        if [ -n "$why" ]; then
            bad_derived="$bad_derived$rel\t$why\n"
        else
            incl=""; [ "${sym:--}" = "-" ] || incl=" incl. $sym"
            note "$(printf '  %-42s umbrella  %s own defs%s, reexports %s' "$rel" \
                     "$(nm_defined "$f" | grep -c .)" "$incl" "$(basename "${real:--}")")"
        fi ;;
    local)
        n_local=$((n_local+1))
        if [ ! -f "$f" ]; then
            bad_derived="$bad_derived$rel\tdeclared local but absent from the root\n"; continue; fi
        note "$(printf '  %-42s local     %s' "$rel" "$(printf '%s' "$rest" | cut -f1)")" ;;
    *)  echo "require_fresh_root: unknown manifest kind '$kind' for $rel" >&2; exit 2 ;;
    esac
done < "$MANIFEST"

# ---- what is UPSTREAM and unaccounted for ---------------------------------
# THE HOLE THIS CLOSES: the old guard walked the TARGET, so a dylib machorun has
# and this root lacks was invisible by construction. mrroot_full had no
# libc++abi.dylib at all and the guard said "6 dylib(s) match".
n_upstream=0
while IFS= read -r up; do
    rel=${up#$MACHORUN/}
    n_upstream=$((n_upstream+1))
    case " $accounted " in *" $rel "*) continue ;; esac
    absent="$absent $rel"
done < <({ find "$MACHORUN/darwin/usr/lib" -name '*.dylib' -type f 2>/dev/null
           [ -f "$MACHORUN/build/machorun" ] && echo "$MACHORUN/build/machorun"; } | LC_ALL=C sort)

graded=$((n_copy + n_renamed + n_umbrella + n_staged))
if [ "$graded" -eq 0 ]; then
    echo "require_fresh_root: REFUSING TO GRADE -- 0 gradable files in $SHORT" >&2
    echo "  ($n_local local, manifest source: $MANIFEST_SRC.) Is the root populated?" >&2
    exit 2
fi

# ---- report ---------------------------------------------------------------
# The two accumulators hold "<rel>\t<why>\n" per entry; `printf '%b'` is what
# turns those escapes into a real table.
show() { printf '%b' "$1" | while IFS=$'\t' read -r rel why; do
             [ -n "$rel" ] && printf '      %-40s %s\n' "$rel" "$why"; done; }
count() { printf '%b' "$1" | grep -c . ; }
nbad_copy=$(count "$bad_copy")
nbad_der=$(count "$bad_derived")
nabsent=$(printf '%s\n' $absent | grep -c .)

if [ "$nbad_copy" -eq 0 ] && [ "$nbad_der" -eq 0 ] && [ "$nabsent" -eq 0 ]; then
    printf 'root ok: %s -- %d copies identical, %d renamed identical outside LC_ID_DYLIB, %d umbrellas built, %d staged match their source, %d local\n' \
        "$SHORT" "$n_copy" "$n_renamed" "$n_umbrella" "$n_staged" "$n_local"
    printf '  %d upstream artefact(s) in %s, all accounted for; manifest: %s\n' \
        "$n_upstream" "${MACHORUN#$HOME/}" "$MANIFEST_SRC"
    # The per-file evidence -- digests, export counts, what re-exports what.
    # Printed on request rather than always, but printed BY DEFAULT when a
    # caller sets MRROOT_VERBOSE, because a verdict with no numbers under it is
    # the thing this guard was rewritten for.
    [ -n "${MRROOT_VERBOSE:-}" ] && [ ${#NOTES[@]} -gt 0 ] && printf '%s\n' "${NOTES[@]}"
    exit 0
fi

# MRROOT_REFRESH is deliberately powerless over anything derived.
if [ "${MRROOT_REFRESH:-0}" = 1 ] && [ "$nbad_der" -eq 0 ] && [ "$nabsent" -eq 0 ]; then
    printf '%b' "$bad_copy" | while IFS=$'\t' read -r rel _; do
        [ -n "$rel" ] || continue
        up=$(awk -F'\t' -v r="$rel" '$1=="copy" && $2==r {print $3}' "$MANIFEST")
        [ -n "$up" ] && cp -f "$MACHORUN/$up" "$TARGET/$rel" && echo "  refreshed $rel from $up"
    done
    echo "root refreshed: $SHORT -- $nbad_copy of $n_copy copy/copies updated"
    exit 0
fi

{
echo
echo "GUEST ROOT NOT USABLE: $SHORT"
printf '  graded %d file(s): %d copy, %d renamed, %d umbrella, %d staged (+%d local, not graded)\n' \
    "$graded" "$n_copy" "$n_renamed" "$n_umbrella" "$n_staged" "$n_local"
printf '  upstream set: %d artefact(s) in %s; manifest: %s\n' "$n_upstream" "${MACHORUN#$HOME/}" "$MANIFEST_SRC"
echo

if [ "$nbad_copy" -gt 0 ]; then
    echo "  STALE COPIES ($nbad_copy of $n_copy) -- these are meant to BE machorun's bytes:"
    show "$bad_copy"
    echo "      Fix: re-run full/scripts/build_full.sh (it stages from machorun), or for a"
    echo "           root that is nothing but copies:  MRROOT_REFRESH=1 $0 $SHORT"
    echo
fi
if [ "$nbad_der" -gt 0 ]; then
    echo "  DERIVED ARTEFACTS WRONG ($nbad_der of $((n_renamed + n_umbrella + n_staged + n_local))):"
    show "$bad_derived"
    echo "      Fix: RE-RUN full/scripts/build_full.sh. These files are BUILD OUTPUTS."
    echo "      DO NOT use MRROOT_REFRESH=1 on them: copying machorun's plain library over an"
    echo "      umbrella deletes the shim layer, and the root then loads nothing at all --"
    echo "      that is what happened on 2026-08-27 and it cost a day."
    echo
fi
if [ "$nabsent" -gt 0 ]; then
    echo "  MISSING FROM THIS ROOT ($nabsent) -- present in machorun, unaccounted for here:"
    for rel in $absent; do printf '      %s\n' "$rel"; done
    echo "      A dylib machorun grew and this root never got is invisible to any check that"
    echo "      walks the ROOT. libc++abi.dylib was exactly this: absent, and the old guard"
    echo "      reported '6 dylib(s) match'. Fix: re-run full/scripts/build_full.sh; if the"
    echo "      omission is deliberate, declare it as a 'local' row naming the upstream file."
    echo
fi
} >&2
exit 1
