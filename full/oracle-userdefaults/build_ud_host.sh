#!/bin/bash
# Build the UserDefaults host-route oracle: the PORT as its own Swift module,
# plus a runner that links it beside real Foundation and diffs the two.
#
#   full/oracle-userdefaults/build_ud_host.sh [outdir]
#
# The port is ONE source file used in TWO configurations. Here it is built with
# -DUD_HOST_ORACLE into a module named `PortedUserDefaults`, so its type is
# `PortedUserDefaults.UserDefaults` and coexists in one process with the real
# `Foundation.UserDefaults` it is graded against. The target build compiles the
# SAME file, undefined, into the Foundation overlay over our own CF.
#
# Pinned so a number here is a measurement: host toolchain and SDK are printed
# and recorded with every scoreboard.
set -euo pipefail

PORT_SRC=${PORT_SRC:-$HOME/foundation-macho/src/overlay/UserDefaults.swift}
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${1:-${TMPDIR:-/tmp}/ud-host}

if [ ! -f "$PORT_SRC" ]; then
  echo "FATAL: port source not found: $PORT_SRC" >&2
  exit 2
fi

mkdir -p "$OUT"

echo "==> toolchain"
swiftc --version | sed 's/^/    /'
SDKP=$(xcrun --sdk macosx --show-sdk-path)
echo "    sdk        $SDKP"
echo "    sdk version $(xcrun --sdk macosx --show-sdk-version)"
echo "    os         $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
echo "    port src   $PORT_SRC"
echo "    port sha   $(shasum -a 256 "$PORT_SRC" | cut -d' ' -f1)"

echo "==> building the port as module PortedUserDefaults (-DUD_HOST_ORACLE)"
swiftc -c -O -parse-as-library \
  -module-name PortedUserDefaults -DUD_HOST_ORACLE \
  -emit-module -emit-module-path "$OUT/PortedUserDefaults.swiftmodule" \
  "$PORT_SRC" -o "$OUT/PortedUserDefaults.o"

echo "==> building the runner"
swiftc -O -I "$OUT" \
  "$HERE/ud_runner.swift" "$OUT/PortedUserDefaults.o" \
  -o "$OUT/ud_runner"

# TOOTH: the runner must actually contain BOTH implementations. If the port's
# symbols were dropped -- dead-stripped, or the module built empty -- the
# runner would still link (it would just be measuring real Foundation against
# itself) and would print a perfect scoreboard that means nothing. This is the
# "succeeds and does nothing" shape, so check for the symbols by name.
echo "==> TOOTH: the port's symbols must be present in the runner"
N=$(nm -a "$OUT/ud_runner" 2>/dev/null \
    | grep -c '18PortedUserDefaults' || true)
echo "    PortedUserDefaults symbols in the binary: $N"
if [ "${N:-0}" -lt 10 ]; then
  echo "    *** FAIL: the port is not really in this binary. A scoreboard from" >&2
  echo "        it would be real-vs-real and would pass for the wrong reason. ***" >&2
  exit 3
fi

echo
echo "built: $OUT/ud_runner"
echo "run:   $OUT/ud_runner score | persist-write | persist-read | clean"
