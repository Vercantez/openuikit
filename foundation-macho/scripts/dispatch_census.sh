#!/bin/bash
# Census which libdispatch translation units build for our target.
#
#   scripts/dispatch_census.sh <libdispatch-src> [outdir]
#
# THE SOURCE LIST COMES FROM CMakeLists.txt, NOT FROM `find`.
#
# That is the whole reason this script exists rather than a one-line find. My
# first census enumerated `find src -name "*.c"` and reported 26 translation
# units. There are 27: block.cpp is a C++ source, listed at src/CMakeLists.txt
# line 75, and it defines _dispatch_block_create. The denominator was wrong for
# the life of that census, and nothing about the numbers looked wrong -- 23 of
# 26 and 23 of 27 read identically.
#
# It only surfaced at the LINK, as an undefined _dispatch_block_create, which is
# the same lesson twice in one night: enumerating by file extension is the same
# class of error as enumerating by guard spelling. The fix is not to remember
# ".cpp too" -- it is to stop enumerating from the filesystem when a build
# system is sitting right there with the answer.
#
# CMakeLists also settles which files are EXCLUDED for us rather than failing:
# generic_win_stubs.c and getprogname.c sit inside
# `if(CMAKE_SYSTEM_NAME STREQUAL Windows)`, and the two firehose .c files are
# not listed at all. A census that counts those as failures reports a worse
# number than the truth.
set -uo pipefail

SRC=${1:?usage: dispatch_census.sh <libdispatch-src> [outdir]}
OUT=${2:-/work/ld/census}
CML=$SRC/src/CMakeLists.txt
[ -f "$CML" ] || { echo "dispatch_census: no $CML" >&2; exit 2; }

# Sources CMake compiles unconditionally: every .c/.cpp inside a
# target_sources(dispatch PRIVATE ...) block that is NOT inside an if().
# Tracked by depth so a Windows-only or DTrace-only block is skipped.
mapfile -t SOURCES < <(
  awk '
    { sub(/#.*/, "") }                       # strip comments FIRST -- a comment
                                             # mentioning queue.c produced a
                                             # bogus entry on the first attempt
    # Conditions WE SATISFY are entered rather than skipped. Skipping every
    # if() is right for platform blocks and WRONG for DISPATCH_USE_INTERNAL_
    # WORKQUEUE, which sdk/dispatch-config/config_ac.h sets to 1 -- that block
    # holds event/workqueue.c, which we do build. Listing the conditions we
    # enable is honest and mechanical; inferring them from CMake semantics
    # would mean implementing CMake.
    /^[[:space:]]*if[[:space:]]*\(DISPATCH_USE_INTERNAL_WORKQUEUE\)/ { next }
    /^[[:space:]]*if[[:space:]]*\(/    { depth++; next }
    /^[[:space:]]*endif[[:space:]]*\(/ { if (depth > 0) depth--; next }
    # NOTE: an entered if() contributes no depth, so its endif decrements
    # nothing -- which is why the guard above is `if (depth > 0)`. Without it a
    # single entered block would drive depth negative and silently include the
    # REST of the file, platform blocks and all.
    depth > 0 { next }                       # inside if() -- platform-specific
    {
      # A source line is a bare path ending .c or .cpp, optionally followed by
      # the closing paren of the target_sources() call. Anything else -- a
      # command, a variable, a header -- is not a source.
      line = $0
      gsub(/[[:space:]]/, "", line)
      sub(/\)+$/, "", line)
      if (line ~ /^[A-Za-z0-9_\/.-]+\.(c|cpp)$/) print line
    }
  ' "$CML" | sort -u
)


if [ ${#SOURCES[@]} -eq 0 ]; then
  echo "dispatch_census: parsed ZERO sources from CMakeLists -- refusing to" >&2
  echo "  report a census over an empty set, which would show 0 of 0 passing." >&2
  exit 2
fi

mkdir -p "$OUT/obj" "$OUT/log"
: > "$OUT/PASS.txt"; : > "$OUT/FAIL.txt"
pass=0; fail=0

CFLAGS="-target arm64-apple-macos13.0 -isysroot ${SDK:-/work/sdk/MacOSX.sdk}
 -I$SRC/config-inc -I$SRC -I$SRC/src -I$SRC/private
 -DDISPATCH_EVENT_BACKEND_EPOLL=1 -DOS_VOUCHER_ACTIVITY_SPI=0
 -DOS_FIREHOSE_SPI=0 -fblocks -O1"

for rel in "${SOURCES[@]}"; do
  f=$SRC/src/$rel
  [ -f "$f" ] || { echo "dispatch_census: CMakeLists names $rel but it does not exist" >&2; continue; }
  b=$(echo "$rel" | tr / _)
  # block.cpp states its own requirement: `#error Must build without C++
  # exceptions`. Honouring that is the file's instruction, not our preference.
  if [ "${rel##*.}" = "cpp" ]; then
    cc=clang++; extra="-std=c++11 -fno-exceptions"
  else
    cc=clang;   extra=""
  fi
  if $cc $CFLAGS $extra -c "$f" -o "$OUT/obj/$b.o" 2>"$OUT/log/$b.err"; then
    echo "$rel" >> "$OUT/PASS.txt"; pass=$((pass+1))
  else
    echo "$rel" >> "$OUT/FAIL.txt"; fail=$((fail+1))
  fi
done

total=$((pass+fail))
echo "libdispatch census: PASS=$pass FAIL=$fail of $total"
echo "  (source list from CMakeLists.txt, so platform-excluded files are not"
echo "   counted as failures and .cpp sources are not silently missed)"
if [ "$fail" -gt 0 ]; then
  echo
  echo "=== failures, first error each ==="
  while read -r rel; do
    b=$(echo "$rel" | tr / _)
    printf '  %-28s %s\n' "$rel" \
      "$(grep -m1 'error:' "$OUT/log/$b.err" | sed 's/.*error: //' | cut -c1-52)"
  done < "$OUT/FAIL.txt"
fi
[ "$fail" -eq 0 ]
