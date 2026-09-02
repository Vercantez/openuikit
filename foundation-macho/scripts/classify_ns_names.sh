#!/bin/bash
# Ask the COMPILER which NS names already denote a type.
#
#   scripts/classify_ns_names.sh <candidates.txt>   > types.txt
#
# Reads one candidate name per line, prints the subset that already names a type
# in CF's real compilation context. Feed the output to gen_ns_forwards.py
# --types-file so those names get no @class (which would be "redefinition as a
# different kind of symbol", a hard error in every CF TU at once).
#
# THIS EXISTS BECAUSE THE QUESTION IS NOT ANSWERABLE FROM OUR OWN TREE. The
# first attempt grepped include/*.h for typedefs and got two different wrong
# answers: NSRange is a brace-enclosed struct typedef whose trailing name a
# naive ';' split never reaches, and NSUInteger is not in our headers at all --
# it comes from the SDK's objc/NSObjCRuntime.h. The compilation context is
# strictly larger than the files we wrote, so only the compiler knows.
#
# The probe is `typedef NAME __probe_NAME;`. It compiles exactly when NAME
# already denotes a type, and fails with "unknown type name" when it does not.
# It is deliberately NOT `NAME *x;` -- in ObjC that would also succeed for a
# name declared by an earlier @class, which is the case we are trying to detect.
set -uo pipefail
CAND=${1:?usage: classify_ns_names.sh <candidates.txt>}
SDK=${SDK:-/work/sdk/MacOSX.sdk}
CF=${CF:-/work/cs}
X=${X:-/work/cfextra}
OURINC=${OURINC:-/repo/include}
TRIPLE=${TRIPLE:-arm64-apple-macos13.0}

[ -s "$CAND" ] || { echo "classify_ns_names: $CAND is empty or missing" >&2; exit 2; }

probe() {  # $1 = body; returns 0 if it compiles
  printf '%s\n' "$1" > /tmp/nsprobe.m
  # THE PROBE MUST USE CF'S REAL COMPILATION CONTEXT, INCLUDING OUR HEADERS.
  # An earlier version omitted -I $OURINC and reported 0 of 27 names as types --
  # true of that context and useless, because it was not the context CF is built
  # in. NSRange and NSUInteger come from include/CFFoundationTypes.h, which is
  # force-included into CF exactly so the NS* method-argument types in CF's
  # dispatch macros resolve. Probing without it measures a build nobody runs.
  clang -target "$TRIPLE" -isysroot "$SDK" -x objective-c -fsyntax-only \
    -fobjc-runtime=macosx-13.0 -DINCLUDE_OBJC=1 \
    -I "$CF/include" -I "$CF/internalInclude" -I "$OURINC" \
    -DCF_BUILDING_CF -DDEPLOYMENT_RUNTIME_SWIFT=0 \
    -include "$CF/internalInclude/CoreFoundation_Prefix.h" \
    -include "$OURINC/CFFoundationTypes.h" \
    -idirafter "$X" /tmp/nsprobe.m 2>/dev/null
}

# POSITIVE AND NEGATIVE CONTROLS FIRST. If the probe harness is broken -- a bad
# include path, a missing prefix header -- every candidate would fail to compile
# and be reported as "not a type", which is silently the answer that emits a
# @class for everything. That is the false green this check must not produce, so
# it is proven in both directions before any real name is tested.
if ! probe 'typedef int __probe_control;'; then
  echo "classify_ns_names: the harness cannot compile a trivial typedef --" >&2
  echo "  every result would be a false 'not a type'. Check SDK/CF/X paths." >&2
  exit 2
fi
if probe 'typedef __definitely_not_a_type_xyzzy __probe_neg;'; then
  echo "classify_ns_names: the harness accepts an UNDEFINED type, so it cannot" >&2
  echo "  distinguish the two cases at all." >&2
  exit 2
fi

n=0
while read -r name; do
  [ -n "$name" ] || continue
  if probe "typedef $name __probe_${name};"; then
    echo "$name"
    n=$((n+1))
  fi
done < "$CAND"
echo "classify_ns_names: $n of $(grep -c . "$CAND") candidates already name a type" >&2
