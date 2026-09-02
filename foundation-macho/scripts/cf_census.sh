#!/bin/bash
# Census which CoreFoundation translation units build for our target.
#
#   scripts/cf_census.sh [outdir]
#
# THIS SCRIPT REFUSES TO COUNT AN EMPTY TRANSLATION UNIT AS A PASS.
#
# That is the whole point of the rewrite. The original census reported 4 files
# as passing -- CFWindowsUtilities, CFTimeZone_WindowsMapping,
# CFBundle_ResourceFork, CFPlugIn -- whose entire contents sit behind
# TARGET_OS_WIN32 (or equivalent) guards that are false for us. clang exits 0
# and emits an object file with no symbols in it. A metric that scores those as
# progress inflates every number downstream of it, and will keep doing so as the
# build grows. So a compile that produces zero defined symbols is reported as
# EMPTY, in its own column, and is excluded from the denominator.
#
# Configuration notes, both deliberate:
#
#  * DEPLOYMENT_RUNTIME_SWIFT=0 -- the mode docs/DECISION.md actually chose.
#    The earlier census used Swift mode, which hard-wires CF's constant objects
#    to corelibs' Swift Foundation classes and produces a link surface we will
#    never ship. Measured: ObjC mode reaches the same pass count and drops the
#    Swift coupling from 58 references to zero.
#
#  * -fcf-runtime-abi=objc -- NOT =swift. The Swift ABI changes the constant
#    CFString record layout; ld64.lld then rejects __DATA,__cfstring with
#    "symbol l__unnamed_cfstring_.N at misaligned offset", which looks nothing
#    like a configuration error. It also redirects constant strings to
#    ___CFConstantStringClassReference, which our Foundation supplies.
#
#  * NO -Wno-everything. The original census suppressed all diagnostics, so
#    "pass" meant "codegens", not "is plausibly correct". Warnings are counted
#    per file and reported; a few categories that are pure noise for a
#    cross-build of someone else's code are still silenced by name, so the
#    count means something.
#
#  * The five -DTARGET_OS_* predefines this script used to carry are GONE.
#    CF compiles with -Wundef-prefix=TARGET_OS promoted to an error, and our
#    sysroot was missing WASI, ANDROID, BSD, CYGWIN and NANO -- with
#    -Wno-everything all 86 files silently "passed" that check, without it all
#    86 failed. Fixed properly in machorun 5d64c3b, so the sysroot now defines
#    all 18 macros CF references and the workaround is removed rather than
#    left in place to rot.
set -uo pipefail
SDK=${SDK:-$HOME/work/sdk/MacOSX.sdk}
CF=${CF:-$HOME/scf-full/Sources/CoreFoundation}
X=${X:-$HOME/work/cfextra}
OUT=${1:-$HOME/fnd-link/census}
NM=${NM:-llvm-nm-18}
TRIPLE=arm64-apple-macos13.0

rm -rf "$OUT"; mkdir -p "$OUT/obj" "$OUT/log"

# ICU_INC: point at swift-foundation-icu's icuSources/include to unblock the 15
# ICU-dependent files. Without it they fail on _foundation_unicode/*.h and their
# 152 CF* symbols show up as undefined, which distorts the link gap.
ICU_INC=${ICU_INC:-}
CFLAGS="-target $TRIPLE -isysroot $SDK -I $CF/include -I $CF/internalInclude
 ${ICU_INC:+-I $ICU_INC}
 -DCF_BUILDING_CF -DDEPLOYMENT_RUNTIME_SWIFT=0 -DHAVE_STRUCT_TIMESPEC
 -fblocks -fconstant-cfstrings -fdollars-in-identifiers -fno-common
 -fcf-runtime-abi=objc -fexceptions -Os
 -include $CF/internalInclude/CoreFoundation_Prefix.h
 -include $X/CFShimCarbon.h -Dd_fileno=d_ino -idirafter $X

 -DDISPATCH_APPLY_AUTO=((dispatch_queue_t)0)
 -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function
 -Wno-sign-compare -Wno-deprecated-declarations -Wno-nullability-completeness"

: > "$OUT/PASS.txt"; : > "$OUT/FAIL.txt"; : > "$OUT/EMPTY.txt"
pass=0; fail=0; empty=0; warns=0

for f in "$CF"/*.c; do
  b=$(basename "$f" .c)
  if clang $CFLAGS -c "$f" -o "$OUT/obj/$b.o" 2>"$OUT/log/$b.err"; then
    # --extern-only matters: a TU whose entire contents are #if'd out still
    # emits the local assembler temp `ltmp0`, so a plain --defined-only count is
    # 1, not 0, and an empty TU sails through. Count only symbols the linker can
    # actually see. Measured: without --extern-only this check reported EMPTY=0
    # while three files really were empty.
    n=$($NM --defined-only --extern-only "$OUT/obj/$b.o" 2>/dev/null | wc -l)
    if [ "$n" -eq 0 ]; then
      # Compiles, defines nothing. Not a pass -- see the header comment.
      echo "$b" >> "$OUT/EMPTY.txt"; empty=$((empty+1))
      rm -f "$OUT/obj/$b.o"
    else
      echo "$b" >> "$OUT/PASS.txt"; pass=$((pass+1))
      # grep -c prints 0 AND exits 1 when there are no matches, so `|| echo 0`
      # would emit "0\n0" and poison the arithmetic. Take the first line only.
      w=$(grep -c "warning:" "$OUT/log/$b.err" 2>/dev/null | head -1)
      w=${w:-0}
      warns=$((warns + w))
      if [ "$w" -gt 0 ]; then
        printf '%-32s %s\n' "$b" "$w" >> "$OUT/WARNINGS.txt"
      fi
    fi
  else
    echo "$b" >> "$OUT/FAIL.txt"; fail=$((fail+1))
  fi
done

total=$((pass+fail))
echo "PASS=$pass FAIL=$fail EMPTY=$empty   (denominator $total, empty TUs excluded)"
echo "warnings across passing files: $warns"
echo
echo "=== EMPTY (compiles, defines nothing -- should not be in the build list) ==="
sed 's/^/  /' "$OUT/EMPTY.txt"
echo
echo "=== FAILURES (first error each) ==="
while read -r b; do
  printf '  %-30s %s\n' "$b" \
    "$(grep -m1 -E 'error:' "$OUT/log/$b.err" | sed 's/.*error: //' | cut -c1-70)"
done < "$OUT/FAIL.txt"
