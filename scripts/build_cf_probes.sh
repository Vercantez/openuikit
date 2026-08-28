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
NSCF_INCLUDES="-I/work/nscf-include -I$CF/include -I$CF/internalInclude"

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

case "$WHICH" in all|t16|t19) rebuild_nscf ;; esac

if [ "$WHICH" = all ] || [ "$WHICH" = t17 ]; then
  note "T17 -- the mutex-signature wall, isolated from CoreFoundation"
  cp -f /repo/tests/t17_pthread_sig.c /work/obj/t17_src.c
  clang -target $TRIPLE -isysroot $SDK -Os -c /work/obj/t17_src.c -o /work/obj/t17.o \
    && link_bare t17 && run t17
  echo "  (the errorcheck mutex ABORTS until #80 lands; that is the expected result)"
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

  # WHERE the file landed is a finding, not a detail, so look in BOTH places.
  # Searching only under $HOME reported "nothing landed" while the write had
  # gone to /Library/Preferences -- gate-scope-excludes-the-answer, in this
  # script, about the very result it exists to report.
  echo "  --- preference files on disk:"
  f=$(find "$HOME/Library/Preferences" /Library/Preferences \
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
      "$HOME"/*) echo "    location: under \$HOME  (matches Darwin)" ;;
      *)         echo "    location: $(dirname "$f")  <-- the ANY-USER domain."
                 echo "                            Darwin's per-app default is"
                 echo "                            \$HOME/Library/Preferences." ;;
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
