#!/bin/bash
# Build and run the CF-execution probes (T16-T19) inside the fm-build container.
#
#   scripts/build_cf_probes.sh [t16|t17|t18|t19|all]     default: all
#
# WHY THIS SCRIPT EXISTS, AND IT IS NOT A CONVENIENCE.
#
# These four probes produced the two walls in docs/CF_PREFERENCES_EXECUTION.md,
# and they were originally built by hand. That is precisely the defect that
# document reports about /work/cfobjc -- an artifact whose recipe lives only in
# a shell history -- so leaving these unbuildable would have reproduced the
# finding while filing it.
#
# IT ALSO CARRIES A FLAG CHANGE THAT EXISTS NOWHERE ELSE. src/nscf/
# NSCFConstantString.m now `#include "ForFoundationOnly.h"` to use CF's OWN
# __CFStringEncodingIsSupersetOfASCII rather than copying it. That needs CF's
# include directories on the nscf compile line. Rebuild that file with the old
# flags and it does not compile -- so the include paths are HERE, in a file the
# repo owns, not in whatever command someone last typed.
#
# Per-probe requirements, each learned the hard way:
#
#   t17  links libSystem ONLY. It must not see CoreFoundation, because its
#        whole job is to show the mutex-signature wall is not CF's doing.
#   t19  needs -fconstant-cfstrings AND -fcf-runtime-abi=objc. The first makes
#        CFSTR() a real __NSCFConstantString; the second is the ABI the rest of
#        the build uses, and mixing them yields a misaligned __cfstring section
#        that fails at link with a message about nothing recognisable.
#
# Run on the macOS host; drives the container by name, and only that container.
set -uo pipefail

NAME=${NAME:-fm-build}
WHICH=${1:-all}

if ! docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
  echo "FATAL: container '$NAME' is not running. Start it with scripts/container.sh up" >&2
  exit 2
fi

# `docker exec -i`, and the -i is load-bearing: without it stdin is not
# forwarded, the heredoc below reaches nothing, and the whole thing exits 0
# having run no probes at all. That is exactly the shape docs/ calls
# "succeeds and does nothing" -- caught here on the first run of this script,
# which had printed nothing and returned success.
docker exec -i "$NAME" bash -s "$WHICH" <<'INNER'
set -uo pipefail
WHICH=$1
SDK=/work/sdk/MacOSX.sdk
LLD=/usr/lib/llvm-18/bin
TRIPLE=arm64-apple-macos13.0
CF=${CF:-/work/cf}
export MACHORUN_ROOT=/work/root
mkdir -p /work/obj

# The include set the nscf surface now requires. CF's own headers are on it
# because NSCFConstantString.m calls CF's inline ASCII-superset predicate
# instead of duplicating it.
# CF's PUBLIC headers declare CFStringGetPascalString and friends, so any TU
# including them needs the Pascal-string types machorun's MacTypes.h omits ON
# PURPOSE. CF's own build gets them from force-including CoreFoundation_Prefix.h;
# a non-CF file should not take CF's whole build prefix to borrow one inline
# predicate, so the repo carries the four typedefs. See include/CFCarbonTypesShim.h.
NSCF_INCLUDES="-I/work/nscf-include -I$CF/include -I$CF/internalInclude \
               -include /repo/include/CFCarbonTypesShim.h"

case "$WHICH" in
  all|t16|t17|t18|t19) ;;
  *) echo "FATAL: unknown probe '$WHICH'. Use: t16 | t17 | t18 | t19 | all" >&2
     # Without this, a typo selected NO probe, ran nothing, and printed
     # "probe teeth held" -- a green result for having done nothing, which is
     # the same failure as the missing `docker exec -i` above. A runner that
     # can report success without running anything is not a runner.
     exit 2 ;;
esac

fail=0
ran=0
note() { printf '\n=== %s\n' "$*"; ran=$((ran+1)); }

# ---------------------------------------------------------------------------
# THE .tbd MUST NOT LAG THE DYLIB, CHECKED BEFORE ANY PROBE RUNS.
#
# The link resolves against the .tbd; the loader resolves against the dylib. A
# .tbd that omits what the dylib exports does not fail -- it manufactures
# PHANTOM MISSING SYMBOLS: each shows up undefined, gets a loud "STUB CALLED"
# stub, and is indistinguishable from a real gap.
#
# It cost four functions written twice on 2026-08-28, two of which had been in
# libSystem for weeks. The shims then SHADOWED the real ones, because
# build_cftest_harness.sh links the probe object before -lSystem -- and one of
# them was a documented FICTION, so the lie won on link order alone.
# Refreshing the .tbd dropped the stub count 245 -> 208 in one step.
#
# It lives HERE rather than only in stage_sdk.sh because stage_sdk.sh restores
# both files from a READ-ONLY /stage that can be older than ~/machorun. It can
# revert a fresh libSystem and its .tbd TOGETHER, leaving them consistent with
# each other and stale against the tree -- and consistent-and-stale passes any
# check that only compares the two to each other. That is exactly what happened
# while this check was being written, which is why it reports the DYLIB's date
# too rather than only the symbol comparison.
tbd_vs_dylib() {
  T=/work/sdk/MacOSX.sdk/usr/lib/libSystem.B.tbd
  D=/work/root/darwin/usr/lib/libSystem.B.dylib
  [ -f "$T" ] && [ -f "$D" ] || { echo "tbd-check: missing $T or $D"; return 0; }
  total=$(llvm-nm-18 -g "$D" 2>/dev/null | awk '$2=="T"' | wc -l)
  missing=$(llvm-nm-18 -g "$D" 2>/dev/null | awk '$2=="T"{print substr($3,2)}' \
            | sort -u | while read -r s; do grep -q "_${s}\b" "$T" || echo "$s"; done)
  n=$(printf '%s' "$missing" | grep -c . || true)
  echo "tbd-check: dylib $(date -r "$D" +%H:%M) · tbd $(date -r "$T" +%H:%M) · $total exported"

  # AND COMPARE AGAINST THE BUILT ARTEFACT, not just the two staged files to
  # each other. stage_sdk.sh restores the dylib AND the .tbd from a read-only
  # /stage, so it reverts them together -- consistent with each other, stale
  # against the tree, and invisible to the symbol comparison above. It also
  # gives the restored file a FRESH mtime, so the timestamps lie as well.
  # Content is the only thing that does not.
  #
  # /stage IS THE ONE AUTHORITY, deliberately. An earlier version of this check
  # compared against a container-local rebuild in /work/mrsrc, which created
  # TWO authorities -- and two honest builds of the same source differ in bytes,
  # so it would fire on a difference that meant nothing. Refresh the snapshot
  # with `scripts/container.sh restage` and let it decide.
  B=/stage/darwinlib/libSystem.B.dylib
  if [ -f "$B" ] && ! cmp -s "$B" "$D"; then
    echo "  *** the libSystem in /work differs from the /stage snapshot."
    echo "      work $(wc -c < "$D") bytes, snapshot $(wc -c < "$B") bytes."
    echo "      stage_sdk.sh will replace the work copy on its next run."
    echo "      Reconcile first (scripts/container.sh check) -- a run against a"
    echo "      mixture is not a measurement of either."
    fail=1
  fi
  if [ "${n:-0}" -gt 0 ]; then
    echo "  *** the .tbd omits $n of $total symbols the dylib exports."
    echo "      They will present as MISSING and get stubs that shadow real code."
    printf '%s\n' "$missing" | head -6 | sed 's/^/        /'
    echo "      Fix: rebuild machorun's libSystem, run its scripts/build.sh tbd,"
    echo "      and stage BOTH into /work -- stage_sdk.sh restores the old pair."
    fail=1
  fi
}
tbd_vs_dylib

rebuild_nscf() {
  note "rebuilding the NS* surface (NSCFConstantString needs CF's headers)"
  clang -target $TRIPLE -isysroot $SDK -fobjc-runtime=macosx-13.0 -fno-objc-arc \
    $NSCF_INCLUDES -Wno-objc-root-class -Os \
    -c /repo/src/nscf/NSCFConstantString.m -o /work/nscfobj/NSCFConstantString.o || {
      echo "  FATAL: NSCFConstantString.m did not compile."
      echo "  If the error is 'ForFoundationOnly.h file not found', the CF source"
      echo "  tree is not at \$CF ($CF) -- that header is where CF's own"
      echo "  __CFStringEncodingIsSupersetOfASCII lives and it is included, not copied."
      exit 3; }
  # TOOTH: the object must actually define the selectors this file exists for.
  # A silently-stale object would relink fine and behave like the old code.
  n=$(llvm-nm-18 --defined-only /work/nscfobj/NSCFConstantString.o | grep -c 'fastCStringContents\|getCString' || true)
  echo "  selector implementations in the object: $n (expected >= 2)"
  [ "${n:-0}" -ge 2 ] || { echo "  FATAL: the rebuilt object is missing the selectors."; exit 3; }
  bash /repo/scripts/build_cftest_harness.sh | tail -1
}

build_objc() {   # name, extra flags
  clang -target $TRIPLE -isysroot $SDK -fobjc-runtime=macosx-13.0 -fno-objc-arc \
    ${2:-} -Wno-objc-root-class -Os -c "/repo/tests/$1".* -o "/work/obj/$1.o" || return 1
}

# Binaries go in /work/bin, NOT /work. Earlier sessions left DIRECTORIES named
# /work/t17 and /work/t18, so linking to those paths failed with "failed to
# open: Is a directory" -- a scratch layout from another day quietly deciding
# where this script may write.
mkdir -p /work/bin

link_with_cf() { # name
  clang -target $TRIPLE -isysroot $SDK -fuse-ld=lld -B $LLD -nostdlib \
    -L$SDK/usr/lib -L/work/lib "/work/obj/$1.o" \
    -lSystem -lobjc /work/lib/libCFTest.dylib -o "/work/bin/$1"
}

link_bare() {    # name -- libSystem ONLY, deliberately
  clang -target $TRIPLE -isysroot $SDK -fuse-ld=lld -B $LLD -nostdlib \
    -L$SDK/usr/lib "/work/obj/$1.o" -lSystem -o "/work/bin/$1"
}

run() {          # name, args...
  local n=$1; shift
  # TOOTH: the guest must not be runnable without the loader. If this ever
  # succeeds, the binary is not the Mach-O we think it is.
  if "/work/bin/$n" "$@" >/dev/null 2>&1; then
    echo "  *** '/work/bin/$n' RAN WITHOUT machorun -- it is not a Darwin guest ***"
    fail=1
  fi
  /work/mrun "/work/bin/$n" "$@" 2>&1
  return $?
}

# EVERY CF-linked probe relinks, because the relink is what regenerates the
# stub set from probe_sysctl.c. This once read `all|t16|t19`, so editing
# probe_sysctl.c and running `t18` silently exercised the PREVIOUS library and
# reported a stub that had just been implemented. A selector that decides
# whether to rebuild is a staleness hole; t17 is excluded because it links
# libSystem only and touches neither CF nor the stubs.
case "$WHICH" in all|t16|t18|t19) rebuild_nscf ;; esac

if [ "$WHICH" = all ] || [ "$WHICH" = t17 ]; then
  note "T17 -- the mutex-signature wall, isolated from CoreFoundation"
  cp -f /repo/tests/t17_pthread_sig.c /work/obj/t17_src.c
  clang -target $TRIPLE -isysroot $SDK -Os -c /work/obj/t17_src.c -o /work/obj/t17.o \
    && link_bare t17 && run t17
  echo "  (all three must lock: machorun #80 taught adopt() the ERRORCHECK,"
  echo "   RECURSIVE and FIRSTFIT signatures. An abort here is a REGRESSION,"
  echo "   or a stale libSystem -- check the tbd-check line above first.)"
fi

if [ "$WHICH" = all ] || [ "$WHICH" = t19 ]; then
  note "T19 -- __NSCFConstantString dispatch surface"
  build_objc t19_conststring_dispatch "-fconstant-cfstrings -fcf-runtime-abi=objc" \
    && mv /work/obj/t19_conststring_dispatch.o /work/obj/t19.o \
    && link_with_cf t19 && { run t19 | tail -4; }
  note "T19 refuse -- the negative control; it MUST abort"
  # CAPTURED, NOT PIPED, and the reason is worth the line. `set -o pipefail`
  # makes a pipeline report the rightmost NON-ZERO status, and this command is
  # SUPPOSED to die (SIGABRT, 134). Piping it into grep therefore reported the
  # check as FAILED precisely when the refusal WORKED -- a control inverted by
  # the shell option meant to make failures visible. Measured: the first run of
  # this script printed "the refusal did NOT fire" while the abort message was
  # on screen.
  refuse_out=$(/work/mrun /work/bin/t19 refuse 2>&1)
  if printf '%s' "$refuse_out" | grep -q "UNIMPLEMENTED"; then
    echo "  the loud refusal FIRED -- the refusal is evidence, not intention"
  else
    echo "  *** the refusal did NOT fire; every 'it refuses' claim is unproven ***"
    printf '%s\n' "$refuse_out" | sed 's/^/      /'
    fail=1
  fi
fi

if [ "$WHICH" = all ] || [ "$WHICH" = t18 ]; then
  note "T18 -- CFBundle identity (what decides the plist filename)"
  cp -f /repo/tests/t18_bundle_identity.c /work/obj/t18_src.c
  clang -target $TRIPLE -isysroot $SDK -Os -c /work/obj/t18_src.c -o /work/obj/t18.o \
    && link_with_cf t18 && run t18 | head -8
fi

if [ "$WHICH" = all ] || [ "$WHICH" = t16 ]; then
  note "T16 -- CF's preferences path"
  export HOME=/work/t16home; rm -rf "$HOME"; mkdir -p "$HOME"
  rm -f /Library/Preferences/com.example.t16prefs.plist
  build_objc t16_cfprefs && mv /work/obj/t16_cfprefs.o /work/obj/t16.o \
    && link_with_cf t16 && run t16 | tail -24

  # SEARCH WHERE CF SAYS IT WRITES, NOT WHERE WE ASSUME.
  #
  # This has now been wrong TWICE in this one script, the same way both times.
  # First it searched only $HOME while the file was in /Library/Preferences.
  # Then it searched $HOME and /Library while CF was writing to the PASSWD
  # entry's home -- because CF's order is CFFIXED_USER_HOME, then the passwd
  # entry, and only THEN $HOME (CFPlatform.c:370). $HOME is the last thing CF
  # consults and the first thing a harness assumes.
  #
  # T20 prints the directory CF resolves; this searches the union of every
  # candidate rather than picking one. A reporter that looks in one place
  # reports "nothing happened" for a write that happened somewhere else.
  echo "  --- preference files on disk:"
  PWHOME=$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6)
  f=$(find "$HOME/Library/Preferences" \
           "${PWHOME:-/nonexistent}/Library/Preferences" \
           "${CFFIXED_USER_HOME:-/nonexistent}/Library/Preferences" \
           /Library/Preferences \
        -name '*t16prefs*' 2>/dev/null | head -1)
  if [ -z "$f" ]; then
    echo "    (none. If T16 reported 'synchronize returned TRUE' above, that is"
    echo "     a FINDING -- a write that reports success and leaves no file.)"
  else
    echo "    $f"
    if head -c 6 "$f" | grep -q bplist
      then echo "    format:   bplist00  (matches Darwin)"
      else echo "    format:   XML       <-- DIVERGES. Darwin writes binary;"
           echo "                            CFPreferences.c:202 defaults"
           echo "                            __CFPreferencesWritesXML = true."; fi
    case "$f" in
      /Library/Preferences/*)
        echo "    location: /Library/Preferences  <-- the ANY-USER domain."
        echo "                            Darwin's per-app default is the"
        echo "                            CURRENT user's home." ;;
      *)
        echo "    location: $(dirname "$f")"
        echo "                            (a per-user home -- matches Darwin's"
        echo "                            shape; which home is CF's choice, not"
        echo "                            \$HOME's: CFPlatform.c:370)" ;;
    esac
  fi
fi

echo
# Print the denominator, not just the verdict. "teeth held" over zero probes is
# the report a broken selector produces.
echo "probes run: $ran"
if [ "$ran" -eq 0 ]; then
  echo "*** NOTHING RAN. A pass over an empty set is not a pass. ***"
  exit 2
fi
[ "$fail" -eq 0 ] && echo "probe teeth held." || echo "A TOOTH FAILED -- see above."
exit $fail
INNER
