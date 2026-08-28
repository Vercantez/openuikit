#!/bin/bash
# require_fresh_root_test.sh -- prove scripts/require_fresh_root.sh has teeth.
#
# A refusal that has never been observed to fire is a comment, and this guard's
# PREDECESSOR was not merely toothless: it was ANTI-CORRELATED with correctness
# on scratch/mrroot_full -- `root fresh` about a root that could not load a
# single guest, `STALE 3 of 7` about a correct one. So each case below is
# exercised against a real root, and the check must produce the RIGHT verdict in
# both directions, not just refuse a lot.
#
# Every mutation happens in a COPY under a temp dir. The live root is read once,
# never written.
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GUARD="$ROOT/scripts/require_fresh_root.sh"
SRCROOT=${1:-$ROOT/scratch/mrroot_full}
MACHORUN=${MACHORUN:-$HOME/machorun}

[ -d "$SRCROOT" ] || { echo "require_fresh_root_test: no root at $SRCROOT" >&2; exit 2; }
[ -f "$SRCROOT/.manifest" ] || { echo "require_fresh_root_test: $SRCROOT has no .manifest -- rebuild it with full/scripts/build_full.sh" >&2; exit 2; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0

# case <name> <expected-exit> <expected-substring> <mutation...>
# The mutation runs with $R bound to a private copy of the root.
case_() {
    local name=$1 want=$2 grepfor=$3; shift 3
    local R="$TMP/root"
    rm -rf "$R"; cp -a "$SRCROOT" "$R"
    ( R="$R"; eval "$@" ) || { echo "  $name: MUTATION FAILED" >&2; fail=$((fail+1)); return; }
    local out got
    out=$(bash "$GUARD" "$R" 2>&1); got=$?
    if [ "$got" != "$want" ]; then
        printf '  %-34s WRONG EXIT %s (wanted %s)\n' "$name" "$got" "$want" >&2
        printf '%s\n' "$out" | sed 's/^/      /' >&2; fail=$((fail+1)); return
    fi
    if ! printf '%s' "$out" | grep -q -- "$grepfor"; then
        printf '  %-34s exit %s but did not say %s\n' "$name" "$got" "$grepfor" >&2
        printf '%s\n' "$out" | sed 's/^/      /' >&2; fail=$((fail+1)); return
    fi
    printf '  %-34s exit %s  %s\n' "$name" "$got" \
        "$(printf '%s' "$out" | grep -m1 -- "$grepfor" | sed 's/^ *//')"
    pass=$((pass+1))
}

echo "require_fresh_root_test: subject $SRCROOT"
echo

# libswiftObjectiveC.dylib is the right stand-in for the simruntime dylibs in
# mrroot_fe: it has NO machorun counterpart, so promoting it from `local` to
# `staged` does not disturb the upstream accounting.
STAGED_REL=darwin/usr/lib/swift/libswiftObjectiveC.dylib
STAGED_SHA=$(shasum -a 256 <"$SRCROOT/$STAGED_REL" | cut -d' ' -f1)
stage_row() {   # rewrite that file's manifest row as `staged` with digest $1
    grep -v "libswiftObjectiveC" "$R/.manifest" > "$R/.m2" && mv "$R/.m2" "$R/.manifest"
    printf 'staged\t%s\t%s\tpretend iOS 26.1 simruntime\n' "$STAGED_REL" "$1" >> "$R/.manifest"
}

# (0) THE CASE THE OLD GUARD GOT BACKWARDS. A correctly built root -- umbrellas
#     that differ from machorun BY DESIGN -- must grade CLEAN.
case_ "correct root grades clean" 0 "root ok" "true"

# (1) TRUE STALENESS IN A DERIVED INPUT. libSystem.real.dylib is where machorun's
#     bytes actually live, and it is exactly the file the old guard SKIPPED as
#     "local-only, no upstream counterpart".
case_ "stale .real (content changed)" 1 "not machorun's" \
    'printf "\x00" >> "$R/darwin/usr/lib/libSystem.real.dylib"'

# (2) THE SAME FILE, BACKDATED RATHER THAN EDITED. Content is what is graded for
#     a renamed copy, so an mtime alone must NOT raise a false alarm -- the guard
#     must be right in this direction too, or it becomes noise people ignore.
case_ "backdated .real, content intact" 0 "root ok" \
    'touch -t 200001010000 "$R/darwin/usr/lib/libSystem.real.dylib"'

# (3) THE UMBRELLA OLDER THAN ITS INPUT. This is the staleness that matters for a
#     BUILT file: someone edits concpatch.c and the umbrella is not relinked.
case_ "umbrella older than its input" 1 "older than its input" \
    'touch "$R/darwin/usr/lib/libSystem.B.dylib"; touch "$R/darwin/usr/lib/libSystem.real.dylib"'

# (4) THE DISCRIMINATOR GONE. Overwriting the umbrella with machorun's plain
#     libSystem is precisely what `MRROOT_REFRESH=1` used to do, and it is the
#     state that left every scene dying with __NSGetMachExecuteHeader undefined.
#     The old guard called that root FRESH.
case_ "umbrella replaced by plain copy" 1 "does not define __NSGetMachExecuteHeader" \
    'cp -f "'"$MACHORUN"'/darwin/usr/lib/libSystem.B.dylib" "$R/darwin/usr/lib/libSystem.B.dylib"'

# (5) A DYLIB MACHORUN HAS AND THE ROOT LACKS. Invisible by construction to any
#     check that walks the ROOT; libc++abi.dylib was exactly this case.
case_ "upstream dylib missing from root" 1 "MISSING FROM THIS ROOT" \
    'rm -f "$R/darwin/usr/lib/libc++abi.dylib"'

# (5b) MACHORUN GREW A DYLIB AND THE MANIFEST NEVER HEARD OF IT -- the exact
#      shape of the libc++abi omission: not merely absent from disk, absent from
#      the description of the root as well, so nothing walking either the root or
#      the manifest can see it. Only enumerating UPSTREAM finds it.
case_ "upstream dylib undeclared" 1 "MISSING FROM THIS ROOT" \
    'rm -f "$R/darwin/usr/lib/libc++abi.dylib"; grep -v "libc++abi" "$R/.manifest" > "$R/.m2" && mv "$R/.m2" "$R/.manifest"'

# (5c/d/e) THE `staged` KIND -- files with NO machorun counterpart at all (the
#     Apple simruntime dylibs in mrroot_fe). "Matches machorun" is meaningless
#     for them, so the tempting move is to file them under `local` and skip them
#     -- and SKIPPING IS WHAT DOOMED THE UMBRELLA. Their invariant is identity
#     against the RECORDED digest of the external source. Graded in all three
#     states: matching, mutated, and declared without a source digest.
case_ "staged matches its source" 0 "staged match their source" \
    'stage_row "$STAGED_SHA"'
case_ "staged file mutated" 1 "is not the artefact it was staged from" \
    'stage_row "$STAGED_SHA"; printf "\x00" >> "$R/$STAGED_REL"'
# No recorded digest must REFUSE, not hash the file and compare it to itself:
# that would be a check that can never fail, which is the vacuous green this
# whole guard exists to reject.
case_ "staged with no source digest" 1 "refusing to grade it against itself" \
    'stage_row -'

# (5f) A staged file may intentionally replace a same-path machorun artefact.
#     Its optional fifth manifest field must account for that upstream file
#     without pretending the two different runtime builds are byte-identical.
#     Removing only that accounting field must expose the upstream omission.
case_ "staged override loses accounting" 1 "MISSING FROM THIS ROOT" \
    'grep -v "libswiftCore" "$R/.manifest" > "$R/.m2" && mv "$R/.m2" "$R/.manifest"; printf "staged\tdarwin/usr/lib/swift/libswiftCore.dylib\t%s\tpretend external runtime\n" "$(shasum -a 256 <"$R/darwin/usr/lib/swift/libswiftCore.dylib" | cut -d" " -f1)" >> "$R/.manifest"'

# (6) A STALE PLAIN COPY -- the case the old guard did handle, kept so the
#     rewrite is not a regression.
case_ "stale copy (libobjc)" 1 "STALE COPIES" \
    'printf "\x00" >> "$R/darwin/usr/lib/libobjc.A.dylib"'

# (7) THE LOADER. The old guard graded only darwin/usr/lib/*.dylib, so the single
#     most important artefact in the root was outside its scope entirely.
case_ "stale loader" 1 "^      machorun " \
    'printf "\x00" >> "$R/machorun"'

# (8) VACUOUS GRADING. A comparison of nothing is not a pass.
case_ "empty root refuses to grade" 2 "REFUSING TO GRADE" \
    'rm -f "$R/.manifest" "$R/machorun"; rm -rf "$R/darwin/usr/lib"; mkdir -p "$R/darwin/usr/lib"'

# (9) MRROOT_REFRESH MUST NOT TOUCH A DERIVED FILE. This is the destructive path
#     the rewrite exists to close, so it is asserted rather than assumed.
R="$TMP/refresh"; rm -rf "$R"; cp -a "$SRCROOT" "$R"
cp -f "$MACHORUN/darwin/usr/lib/libSystem.B.dylib" "$R/darwin/usr/lib/libSystem.B.dylib"
before=$(shasum -a 256 <"$R/darwin/usr/lib/libSystem.B.dylib" | cut -c1-16)
out=$(MRROOT_REFRESH=1 bash "$GUARD" "$R" 2>&1); got=$?
after=$(shasum -a 256 <"$R/darwin/usr/lib/libSystem.B.dylib" | cut -c1-16)
if [ "$got" = 1 ] && printf '%s' "$out" | grep -q "DO NOT use MRROOT_REFRESH=1"; then
    printf '  %-34s exit 1  refused, and said so; file unchanged (%s)\n' "MRROOT_REFRESH on a derived file" "$after"
    pass=$((pass+1))
else
    printf '  %-34s DID NOT REFUSE (exit %s, %s -> %s)\n' "MRROOT_REFRESH on a derived file" "$got" "$before" "$after" >&2
    fail=$((fail+1))
fi

# (10) ...BUT IT STILL WORKS FOR A PLAIN COPY, which is the capability worth
#      keeping. Two numbers that must agree: the file becomes machorun's again.
R="$TMP/refresh2"; rm -rf "$R"; cp -a "$SRCROOT" "$R"
printf '\x00' >> "$R/darwin/usr/lib/libobjc.A.dylib"
out=$(MRROOT_REFRESH=1 bash "$GUARD" "$R" 2>&1); got=$?
if [ "$got" = 0 ] && cmp -s "$R/darwin/usr/lib/libobjc.A.dylib" "$MACHORUN/darwin/usr/lib/libobjc.A.dylib"; then
    printf '  %-34s exit 0  restored to machorun'"'"'s bytes\n' "MRROOT_REFRESH on a plain copy"
    pass=$((pass+1))
else
    printf '  %-34s exit %s, not restored\n' "MRROOT_REFRESH on a plain copy" "$got" >&2
    printf '%s\n' "$out" | sed 's/^/      /' >&2; fail=$((fail+1))
fi

echo
if [ "$fail" -eq 0 ]; then
    echo "require_fresh_root_test: ok -- $pass case(s), every refusal observed to fire and the correct root graded clean"
    exit 0
fi
echo "require_fresh_root_test: FAILED -- $fail of $((pass+fail))" >&2
exit 1
