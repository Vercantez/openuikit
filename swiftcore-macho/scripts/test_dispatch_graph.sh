#!/bin/bash
# Patch 8: a Darwin *target* on a Linux host must not CMake-link `dispatch`.
# That name becomes ninja input stdlib/public/Concurrency/dispatch with no rule
# (operator log line 905). Do not stub the target; skip the LINK_LIBRARIES
# append the way a Darwin host does (libSystem re-exports).
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fail=0
SWIFT=${SWIFT:-$HOME/work/swift}
CMAKE=$SWIFT/stdlib/public/Concurrency/CMakeLists.txt

echo "=== patch 8 is in apply_patches.py ==="
grep -q 'Darwin target does not CMake-link a missing dispatch target' \
  "$SCRIPT_DIR/apply_patches.py" \
  && echo "  OK  apply_patches.py has patch 8" \
  || { echo "  FAIL missing patch 8 tag"; fail=1; }

echo
echo "=== apply_patches.py against $SWIFT ==="
if [ -f "$CMAKE" ]; then
  python3 "$SCRIPT_DIR/apply_patches.py" "$SWIFT"
  grep -q 'NOT "${SWIFT_PRIMARY_VARIANT_SDK}" IN_LIST SWIFT_DARWIN_PLATFORMS' "$CMAKE" \
    && echo "  OK  Darwin-target skip is in Concurrency/CMakeLists.txt" \
    || { echo "  FAIL Darwin-target condition missing from $CMAKE"; fail=1; }
  set +e
  python3 - "$CMAKE" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
old = '''if("${SWIFT_CONCURRENCY_GLOBAL_EXECUTOR}" STREQUAL "dispatch")
  if(NOT CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    include_directories(AFTER
                          ${SWIFT_PATH_TO_LIBDISPATCH_SOURCE})'''
if old in s:
    print("  FAIL unpatched host-only CMAKE_SYSTEM_NAME guard still present")
    raise SystemExit(1)
print("  OK  host-only dispatch LINK_LIBRARIES guard is gone")
PY
  [ $? -eq 0 ] || fail=1
  set -e
else
  echo "  skip apply (no $CMAKE)"
fi

echo
echo "=== ninja graph must not depend on stdlib/public/Concurrency/dispatch ==="
NINJA_FILE=${SWIFTCORE_DISPATCH_GRAPH_NINJA:-}
if [ -z "$NINJA_FILE" ] && [ -f /tmp/dispatch-graph-proof/build.ninja ]; then
  NINJA_FILE=/tmp/dispatch-graph-proof/build.ninja
fi
if [ -n "$NINJA_FILE" ] && [ -f "$NINJA_FILE" ]; then
  set +e
  python3 - "$NINJA_FILE" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text()
needle = "stdlib/public/Concurrency/dispatch"
hits = []
for i, line in enumerate(text.splitlines(), 1):
    if needle in line and "_Concurrency.o" in line:
        hits.append(i)
if hits:
    print(f"  FAIL {p} still has {needle} on _Concurrency.o lines {hits[:5]}")
    raise SystemExit(1)
print(f"  OK  {p} has no {needle} input on _Concurrency.o")
PY
  [ $? -eq 0 ] || fail=1
  set -e
  cache=$(dirname "$NINJA_FILE")/CMakeCache.txt
  if [ -f "$cache" ]; then
    grep -q 'SWIFT_ENABLE_DISPATCH:BOOL=ON' "$cache" \
      && echo "  OK  SWIFT_ENABLE_DISPATCH=ON" \
      || { echo "  FAIL ENABLE_DISPATCH not ON in CMakeCache"; fail=1; }
    grep -q 'SWIFT_CONCURRENCY_GLOBAL_EXECUTOR:STRING=dispatch' "$cache" \
      && echo "  OK  GLOBAL_EXECUTOR=dispatch (executor sources stay compiled)" \
      || { echo "  FAIL GLOBAL_EXECUTOR is not dispatch"; fail=1; }
  fi
  if command -v ninja >/dev/null 2>&1; then
    graph_dir=$(dirname "$NINJA_FILE")
    set +e
    q=$(ninja -C "$graph_dir" -t query stdlib/public/Concurrency/OSX/x86_64/_Concurrency.o 2>&1)
    qs=$?
    set -e
    printf '%s\n' "$q" | head -40
    if [ "$qs" -eq 0 ]; then
      printf '%s\n' "$q" | grep -q 'stdlib/public/Concurrency/dispatch' \
        && { echo "  FAIL ninja -t query still lists Concurrency/dispatch"; fail=1; } \
        || echo "  OK  ninja -t query has no Concurrency/dispatch input"
    else
      echo "  skip ninja -t query rc=$qs"
    fi
  fi
else
  echo "  skip (set SWIFTCORE_DISPATCH_GRAPH_NINJA or configure /tmp/dispatch-graph-proof)"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- Darwin-target dispatch is libSystem, not a CMake/ninja dispatch node"
  exit 0
fi
echo "FAIL"
exit 1
