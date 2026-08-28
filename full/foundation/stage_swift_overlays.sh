#!/bin/bash
# stage_swift_overlays.sh -- MACOS ONLY.  Put the Swift runtime dylibs the
# ported FoundationEssentials needs into a guest root of our own.
#
# TASK #72 WAS FILED AS A CROSS-BUILD AND IT IS NOT ONE.  The four dylibs the
# linked oracle runner could not load --
#
#     libswift_StringProcessing   12 non-lazy binds
#     libswift_errno               4
#     libswiftSynchronization      1
#     libswiftDarwin               0
#
# -- are ON DISK, in the same iOS 26.1 simulator runtime that
# scripts/stage_swift_runtime.sh already reads.  BUILD_LOG.md §10's own closing
# habit is what found them: "before provisioning, check whether the question is
# about a binary we already have."  ~/swiftcore-macho's artifacts/ holds none of
# them and its build tree died with the AWS box, so the cross-build read as the
# only route; one `ls` of the simruntime says otherwise.
#
# THE PRECEDENT IS ALREADY IN THE ROOT, AND MEASURED RATHER THAN ASSUMED.
# The staged guest root is ALREADY a mixture:
#   libswiftCore.dylib       9,908,448 bytes, platform 1 (macOS), minos 13.0
#                            -- sha256 matches ~/swiftcore-macho/artifacts/
#                            swift-macosx/arm64/libswiftCore.dylib, the
#                            CROSS-BUILT one, not the simulator's 8,778,560.
#   libswift_Concurrency     byte-identical to the SIMULATOR's, platform 7,
#                            minos 26.1.
# So a simulator-platform overlay running against a cross-built macOS
# libswiftCore is the configuration that already works, not a new risk.
# (Worth stating because it is easy to get backwards: the staged libswiftCore
# is NOT the sim's.)
#
# THE CLOSURE IS NINE, NOT FOUR.  The four pull in libswift_RegexParser,
# libswift_Builtin_float and libswift_DarwinFoundation1/2/3.  This script walks
# LC_LOAD_DYLIB transitively rather than copying a hand-written list, prints
# what it staged and what it skipped, and refuses if anything in the closure is
# absent from the simruntime -- an incomplete root is the failure mode that
# reads as a loader bug.
#
# It writes a root of its OWN (scratch/mrroot_fe) rather than into
# scratch/mrroot_full, which build_full.sh owns and rebuilds.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only (reads the CoreSimulator runtime)" >&2; exit 1; }
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SIM=${SIM:-"/Library/Developer/CoreSimulator/Volumes/iOS_23B80/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.1.simruntime/Contents/Resources/RuntimeRoot/usr/lib/swift"}
BASE=${BASE:-$ROOT/scratch/mrroot_full}
DEST=${DEST:-$ROOT/scratch/mrroot_fe}
[ -d "$SIM" ] || { echo "no simruntime at $SIM" >&2; exit 1; }
[ -d "$BASE" ] || { echo "no base root $BASE -- run full/scripts/build_full.sh first" >&2; exit 1; }

# The base root is a DERIVED ARTIFACT and this copies it, so record when both
# were made.  A root copied from a stale root is the photograph-of-a-photograph
# problem, and nothing downstream can see it.
echo "== base  $BASE (machorun staged $(date -r "$BASE/machorun" '+%Y-%m-%d %H:%M:%S'))"
echo "== loader $HOME/machorun/build/machorun (built $(date -r "$HOME/machorun/build/machorun" '+%Y-%m-%d %H:%M:%S'))"
if [ "$HOME/machorun/build/machorun" -nt "$BASE/machorun" ]; then
    echo "REFUSING: the loader is newer than the root it was staged into." >&2
    echo "Re-stage $BASE first; half a root from one version and half from another reads as a real result." >&2
    exit 1
fi

rm -rf "$DEST"; cp -a "$BASE" "$DEST"
LIB="$DEST/darwin/usr/lib/swift"
mkdir -p "$LIB"

# NB: GNU coreutils are the default on this host (see ~/CLAUDE.md), so stat is
# `-c%s` not BSD `-f%z` -- the BSD spelling fails and prints an empty size,
# which reads as a zero-byte dylib rather than as a broken command.
# transitive LC_LOAD_DYLIB closure, restricted to /usr/lib/swift/
want=(libswift_StringProcessing libswiftSynchronization libswift_errno libswiftDarwin)
declare -A seen=()
declare -a manifest_rows=()
queue=("${want[@]}")
staged=0 already=0
while [ ${#queue[@]} -gt 0 ]; do
    name=${queue[0]}; queue=("${queue[@]:1}")
    [ -n "${seen[$name]:-}" ] && continue
    seen[$name]=1
    if [ -f "$LIB/$name.dylib" ]; then
        # NO MANIFEST ROW HERE, and the reason is the header's own warning: the
        # base root is a MIXTURE, so "already present" does NOT mean "came from
        # the simruntime". libswiftCore is the case that proves it -- the root
        # carries the CROSS-BUILT macOS one, and an earlier version of this code
        # recorded the sim's digest for it. That row was FALSE: it would have
        # made require_fresh_root.sh report a mismatch on a correct file, and
        # invited someone to "fix" it by copying the sim's 8,778,560-byte
        # libswiftCore over the cross-built 9,908,448-byte one. Whoever put a
        # file here owns its row.
        echo "   have    $name.dylib   (base root's file; its row is build_full.sh's)"
        already=$((already + 1))
    elif [ -f "$SIM/$name.dylib" ]; then
        cp "$SIM/$name.dylib" "$LIB/$name.dylib"
        echo "   staged  $name.dylib   ($(lipo -archs "$SIM/$name.dylib"), $(stat -c%s "$SIM/$name.dylib") bytes)"
        staged=$((staged + 1))
        # THE MANIFEST ROW, and ONLY on this branch. The digest is of the
        # SIMRUNTIME SOURCE, never of the file now in the root -- hashing an
        # artefact and comparing it to itself is the vacuous green
        # require_fresh_root.sh exists to refuse.
        manifest_rows+=("$(printf 'staged\tdarwin/usr/lib/swift/%s.dylib\t%s\t%s' \
            "$name" "$(shasum -a 256 "$SIM/$name.dylib" | cut -d" " -f1)" "$SIM/$name.dylib")")
    else
        echo "   MISSING $name.dylib -- not in the simruntime either" >&2
        exit 2
    fi
    src="$LIB/$name.dylib"
    while read -r dep; do
        case "$dep" in
            /usr/lib/swift/*) queue+=("$(basename "$dep" .dylib)") ;;
        esac
    done < <(otool -L "$src" | tail -n +2 | awk '{print $1}')
done
echo "== $staged staged, $already already present, closure of ${#seen[@]} dylibs"

# ---- THE MANIFEST. BUILDER-OWNS-THE-MANIFEST, the same rule build_full.sh
# follows for mrroot_full: the script that puts a file in a root is the only one
# that knows where it came from, so it is the only one that can describe it.
# Without these rows require_fresh_root.sh sees nine dylibs it has never heard
# of and can say nothing about them -- and "nothing" reads as "fine".
#
# $DEST inherited mrroot_full's .manifest through the `cp -a` above, and those
# rows stay: they are true of the copied files and they are build_full.sh's to
# maintain. What is appended here is only what THIS script staged. Any inherited
# row for the same path is dropped first, so a file is described once.
echo "== manifest ($DEST/.manifest)"
if [ ${#manifest_rows[@]} -gt 0 ]; then
    tmp=$(mktemp)
    if [ -f "$DEST/.manifest" ]; then
        pat=$(printf '%s\n' "${manifest_rows[@]}" | cut -f2 | sed 's|[.]|[.]|g' | paste -sd'|' -)
        grep -vE "^[a-z]+	($pat)	" "$DEST/.manifest" > "$tmp" || true
    else
        echo "# generated by full/foundation/stage_swift_overlays.sh -- do not hand-edit" > "$tmp"
    fi
    printf '# --- staged by full/foundation/stage_swift_overlays.sh from the iOS simruntime\n' >> "$tmp"
    printf '%s\n' "${manifest_rows[@]}" >> "$tmp"
    mv "$tmp" "$DEST/.manifest"
    echo "   ${#manifest_rows[@]} staged row(s) recorded, each with its SOURCE digest"
else
    echo "   REFUSING to leave an unmanifested root: nothing was recorded" >&2
    exit 3
fi

echo "== $DEST"
