#!/bin/bash
# require_fresh_root.sh -- refuse to use a guest root whose copy of machorun's
# userland has drifted from ~/machorun.
#
#   scripts/require_fresh_root.sh scratch/mrroot          # assert, or refuse
#   MRROOT_REFRESH=1 scripts/require_fresh_root.sh …      # copy the current ones instead
#
# WHY. scratch/mrroot* are COPIES of ~/machorun/darwin/usr/lib. Three scripts
# build them; about seven others just read one, and a copy read long after it
# was made is indistinguishable from a fresh one. On 2026-08-27 an enumeration
# found five such trees, all stale, and FOUR of them still carried the pre-fix
# malloc_type_malloc -- branching to _malloc where machorun now branches to
# _glibc_malloc. That is a defect that cost this project a week, sitting live on
# disk in trees that guests are actually executed against, months after it was
# fixed at the source.
#
# Nothing detected it because scratch/ is gitignored, so there is no commit, no
# diff and no review to notice it by; and machorun's own check_stale.sh grades
# six hardcoded paths, all inside ~/machorun. A copy tree it has never heard of
# is the case it structurally cannot see.
#
# WHY IT REFUSES RATHER THAN SILENTLY REFRESHING. Refreshing by default would
# make `git stash`-style surprises: someone deliberately testing an older
# runtime would have it swapped out underneath them. A refusal that names the
# drifted files and the command that fixes them is louder and never wrong.
# Pass MRROOT_REFRESH=1 when you do want it updated.
#
# IT ONLY GRADES FILES MACHORUN ACTUALLY HAS. mrroot_full and friends also hold
# locally-built artefacts (libSystem.real.dylib, libswiftObjectiveC.dylib) that
# have no upstream to compare against; those are skipped, and the count of
# skipped files is reported so the denominator is never silently smaller than it
# looks.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MACHORUN=${MACHORUN:-$HOME/machorun}
SRC="$MACHORUN/darwin/usr/lib"
TARGET=${1:?usage: require_fresh_root.sh <path-to-guest-root>}
case "$TARGET" in /*) ;; *) TARGET="$ROOT/$TARGET" ;; esac

[ -d "$SRC" ]    || { echo "require_fresh_root: no $SRC" >&2; exit 2; }
[ -d "$TARGET" ] || { echo "require_fresh_root: no such root $TARGET" >&2; exit 2; }

compared=0; skipped=0; drift=""
while IFS= read -r f; do
  rel=${f#$TARGET/}
  up="$SRC/${rel#darwin/usr/lib/}"
  if [ ! -f "$up" ]; then skipped=$((skipped+1)); continue; fi
  compared=$((compared+1))
  cmp -s "$f" "$up" || drift="$drift $rel"
done < <(find "$TARGET/darwin/usr/lib" -name '*.dylib' -type f 2>/dev/null | sort)

# A comparison of nothing is not a pass. This is the same refusal build_compat.sh
# makes, and for the same reason: a vacuous green is worse than no check.
if [ "$compared" -eq 0 ]; then
  echo "require_fresh_root: REFUSING TO GRADE -- compared 0 dylibs in $TARGET" >&2
  echo "  ($skipped file(s) had no counterpart in $SRC.) Is the root populated?" >&2
  exit 2
fi

if [ -z "$drift" ]; then
  echo "root fresh: ${TARGET#$ROOT/} -- $compared dylib(s) match $SRC ($skipped local-only skipped)"
  exit 0
fi

n=$(printf '%s\n' $drift | grep -c .)
if [ "${MRROOT_REFRESH:-0}" = 1 ]; then
  for rel in $drift; do
    cp -f "$SRC/${rel#darwin/usr/lib/}" "$TARGET/$rel" && echo "  refreshed $rel"
  done
  echo "root refreshed: ${TARGET#$ROOT/} -- $n of $compared dylib(s) updated"
  exit 0
fi

echo >&2
echo "STALE GUEST ROOT: ${TARGET#$ROOT/}" >&2
echo "  $n of $compared dylib(s) differ from $SRC:" >&2
for rel in $drift; do echo "      $rel" >&2; done
echo >&2
echo "  This root is a COPY. Running against it tests whatever machorun looked" >&2
echo "  like when the copy was made -- four such trees were found still carrying" >&2
echo "  a malloc_type bug that had been fixed upstream weeks earlier." >&2
echo >&2
echo "  Refresh it:   MRROOT_REFRESH=1 scripts/require_fresh_root.sh ${TARGET#$ROOT/}" >&2
echo "  Or rebuild:   scripts/run_machorun.sh …   (it rm -rf's and re-copies)" >&2
exit 1
