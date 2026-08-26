#!/bin/bash
# difftest.sh -- macOS only. The differential this spike is judged by.
#
#   build/macos/*        Apple swiftc + Apple ld + Apple SDK, run natively
#   build/linux/*        Linux swiftc 6.2.4 + ld64.lld-18 + scratch/sysroot,
#                        run natively on the SAME Mac (unmodified bytes;
#                        ld64.lld already emits a linker-signed adhoc sig)
#
# Same source, same machine, two toolchains. Output must match byte for byte.
# The Linux side never writes build/macos.
set -uo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only" >&2; exit 1; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
rm -rf "$ROOT/build/linux-on-macos"
cp -R "$ROOT/build/linux" "$ROOT/build/linux-on-macos"
fail=0
for t in spike_main objc_main breadth_main; do
    a=$(cd "$ROOT/build/macos"          && ./$t 2>&1); ra=$?
    b=$(cd "$ROOT/build/linux-on-macos" && ./$t 2>&1); rb=$?
    if [ "$a" = "$b" ] && [ $ra -eq $rb ]; then
        printf '%-14s PASS  (exit %d)\n' "$t" "$ra"
        printf '%s\n' "$a" | sed 's/^/               /'
    else
        fail=1
        printf '%-14s FAIL  (exit %d vs %d)\n' "$t" "$ra" "$rb"
        diff <(printf '%s\n' "$a") <(printf '%s\n' "$b") | sed 's/^/               /'
    fi
done
exit $fail
