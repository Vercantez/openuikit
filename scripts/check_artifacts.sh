#!/bin/bash
# check_artifacts.sh -- grade the libswiftCore sitting in each staging directory.
#
# WHY, AND WHY IT IS SEPARATE FROM build_compat.sh.
#
# build_compat.sh asserts the SHIM: that libswiftcompat's exports are disjoint
# from machorun's userland. Nothing asserted anything about the libswiftCore
# sitting beside it -- and that is the artifact whose staleness produced this
# project's "newer, worse binary parked in a staging directory" class in the
# first place. Half-covered is the most misleading state a directory can be in,
# because the presence of A check reads as coverage.
#
# A staging directory is any directory shaped the way machorun's
# scripts/stage_swiftcore.sh reads: libswiftcompat.dylib beside
# swift-macosx/arm64/libswiftCore.dylib. They are DISCOVERED, not listed --
# a directory nobody wrote down is the one that rots.
#
# WHAT IT ASSERTS, and each line is a bug this project actually had:
#
#   1  libswiftCore is an arm64 Mach-O with install name
#      /usr/lib/swift/libswiftCore.dylib.
#   2  ___gxx_personality_v0 binds `from libc++`. A pre-relink build names
#      libSystem, and staging one silently reintroduces the deviation that
#      machorun carried for a week (BUILD_LOG §13, §16).
#   3  No __cxxabiv1 type_info vtable is a FLAT bind. Those are the symbols the
#      shim used to shadow with zerofill placeholders; flat means load order
#      decides, and a two-level bind is a fact where a flat bind is a race whose
#      outcome happens to be stable.
#   4  EVERY remaining flat bind has EXACTLY ONE provider across
#      (machorun userland + this directory's shim). Zero providers is an
#      unsatisfiable import; two is a coin toss. Today all 23 have exactly one.
#   5  All staging directories carry the SAME libswiftCore. Divergence between
#      them is precisely how a worse artifact sat one command from installation
#      while a better one was deployed.
#
# It prints its denominator and refuses to grade rather than passing vacuously.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MRLIB=${MRLIB:-$HOME/machorun/darwin/usr/lib}
NM=${NM:-nm}
command -v "$NM" >/dev/null 2>&1 || { echo "no symbol reader ($NM)" >&2; exit 2; }

CORE_REL=swift-macosx/arm64/libswiftCore.dylib
dirs=$(find "$REPO/artifacts" -name libswiftcompat.dylib -type f 2>/dev/null \
       | while read -r f; do d=$(dirname "$f"); [ -f "$d/$CORE_REL" ] && echo "$d"; done | sort)
ndirs=$(printf '%s\n' "$dirs" | grep -c .)

echo "staging directories discovered: $ndirs"
[ "$ndirs" -gt 0 ] || { echo "REFUSING TO GRADE: found none under $REPO/artifacts." >&2
                        echo "A pass over zero directories is not a pass." >&2; exit 2; }

# The userland every staged libswiftCore is resolved against. Read the built
# dylibs, not the .tbds: a .tbd is generated from a dylib and can lag it.
mrlibs=$(find "$MRLIB" -name '*.dylib' 2>/dev/null | grep -v libswiftcompat | grep -v libswiftCore | sort)
nmr=$(printf '%s\n' "$mrlibs" | grep -c .)
[ "$nmr" -gt 0 ] || { echo "REFUSING TO GRADE: no machorun dylibs under $MRLIB." >&2; exit 2; }
echo "machorun userland images: $nmr"
echo

fail=0
first_core_sha=""; first_core_dir=""
printf '%s\n' "$dirs" | while read -r d; do :; done   # (keep shell honest about the pipe)

for d in $dirs; do
  rel=${d#$REPO/}; [ "$rel" = "$d" ] && rel="artifacts"
  L="$d/$CORE_REL"; S="$d/libswiftcompat.dylib"
  echo "=== $rel"

  # 1. format + install name
  case "$(file -b "$L")" in *"Mach-O 64-bit"*arm64*) ;; *) echo "   FAIL not an arm64 Mach-O"; fail=1; continue ;; esac
  iname=$("$NM" -m "$L" >/dev/null 2>&1 && otool -D "$L" | tail -1)
  [ "$iname" = /usr/lib/swift/libswiftCore.dylib ] \
    && echo "   ok   install name $iname" \
    || { echo "   FAIL install name is '$iname'"; fail=1; }

  # 2. the personality bind
  p=$("$NM" -m "$L" | awk '/___gxx_personality_v0/ {print $NF}' | tr -d '()' | head -1)
  if [ "$p" = libc++ ]; then echo "   ok   ___gxx_personality_v0 from libc++"
  else echo "   FAIL ___gxx_personality_v0 binds '$p' -- expected libc++."
       echo "        A pre-relink libswiftCore. Staging it reintroduces the libSystem deviation."
       fail=1; fi

  # 3. no cxxabi vtable may be flat
  v=$("$NM" -m "$L" | grep 'dynamically looked up' | grep -c 'cxxabiv1.*type_infoE')
  [ "$v" -eq 0 ] && echo "   ok   no __cxxabiv1 vtable is a flat bind" \
                 || { echo "   FAIL $v __cxxabiv1 vtable(s) bind flat -- load order decides which wins"; fail=1; }

  # 4. every flat bind must have exactly one provider
  "$NM" -m "$L" | grep 'dynamically looked up' | awk '{print $(NF-3)}' | sort -u > /tmp/ca_flat.$$
  nflat=$(wc -l < /tmp/ca_flat.$$ | tr -d ' ')
  one=0; none=""; many=""
  while read -r s; do
    [ -n "$s" ] || continue
    provs=$(for f in $mrlibs "$S"; do "$NM" -jUg "$f" 2>/dev/null | grep -qx "$s" && basename "$f" .dylib; done | tr '\n' ' ')
    c=$(echo $provs | wc -w | tr -d ' ')
    case $c in 0) none="$none $s";; 1) one=$((one+1));; *) many="$many $s($provs)";; esac
  done < /tmp/ca_flat.$$
  rm -f /tmp/ca_flat.$$
  if [ -z "$none" ] && [ -z "$many" ]; then
    echo "   ok   all $nflat flat bind(s) have exactly one provider"
  else
    [ -n "$none" ] && { echo "   FAIL flat binds with NO provider:$none"; fail=1; }
    [ -n "$many" ] && { echo "   FAIL flat binds with MORE THAN ONE provider (a coin toss):$many"; fail=1; }
  fi

  # 4b. the same flat-bind rule for libswift_Concurrency, where present.
  # It is a staged artifact too, and it carried three flat __cxxabiv1 vtable
  # binds until 2026-08-27 purely because it predated the .tbd re-export fix.
  C="$d/swift-macosx/arm64/libswift_Concurrency.dylib"
  if [ -f "$C" ]; then
    cv=$("$NM" -m "$C" | grep 'dynamically looked up' | grep -c 'cxxabiv1.*type_infoE')
    [ "$cv" -eq 0 ] && echo "   ok   libswift_Concurrency: no __cxxabiv1 vtable binds flat" \
                    || { echo "   FAIL libswift_Concurrency: $cv __cxxabiv1 vtable(s) bind flat"; fail=1; }
    "$NM" -m "$C" | grep 'dynamically looked up' | awk '{print $(NF-3)}' | sort -u > /tmp/ca_cflat.$$
    cn=$(wc -l < /tmp/ca_cflat.$$ | tr -d ' '); cbad=""
    while read -r s; do
      [ -n "$s" ] || continue
      cp2=$(for f in $mrlibs "$S" "$L"; do "$NM" -jUg "$f" 2>/dev/null | grep -qx "$s" && echo x; done | wc -l | tr -d ' ')
      [ "$cp2" = 1 ] || cbad="$cbad $s($cp2)"
    done < /tmp/ca_cflat.$$
    rm -f /tmp/ca_cflat.$$
    [ -z "$cbad" ] && echo "   ok   libswift_Concurrency: all $cn flat bind(s) have exactly one provider" \
                   || { echo "   FAIL libswift_Concurrency flat binds not single-provider:$cbad"; fail=1; }
  fi

  # 5. cross-directory agreement
  sha=$(shasum -a256 "$L" | cut -d' ' -f1)
  if [ -z "$first_core_sha" ]; then first_core_sha=$sha; first_core_dir=$rel
  elif [ "$sha" != "$first_core_sha" ]; then
    echo "   FAIL libswiftCore differs from $first_core_dir's."
    echo "        Divergent staging sources are how a worse artifact sits one command from"
    echo "        installation while a better one is deployed. Make them the same file."
    fail=1
  else echo "   ok   libswiftCore identical to $first_core_dir's"; fi
done

echo
[ "$fail" = 0 ] && echo "PASS -- $ndirs staging directory/ies graded against $nmr userland images" \
                || echo "FAIL -- see above"
exit $fail
