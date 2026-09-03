#!/bin/bash
# Empty SWIFT_LIPO turns ninja's flatten into `cmake -E env -create`, which
# Ubuntu cmake 3.28 rejects. The single-arch lipo shim copies; --rewrite-ninja
# patches an already-generated graph.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
py=$SCRIPT_DIR/lipo_single_arch.py
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "=== single-arch -create copies ==="
echo hello > "$tmp/in.so"
python3 "$py" -create -output "$tmp/out.so" "$tmp/in.so"
cmp -s "$tmp/in.so" "$tmp/out.so" \
  && echo "  OK  copy" || { echo "  FAIL copy mismatch"; fail=1; }

echo
echo "=== two inputs is CANNOT_LIPO_FAT_ON_LINUX ==="
echo a > "$tmp/a.so"
echo b > "$tmp/b.so"
set +e
out=$(python3 "$py" -create -output "$tmp/fat.so" "$tmp/a.so" "$tmp/b.so" 2>&1)
rc=$?
set -e
[ "$rc" -eq 2 ] && echo "  OK  rc=2" || { echo "  FAIL rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q CANNOT_LIPO_FAT_ON_LINUX \
  && echo "  OK  named CANNOT" || { echo "  FAIL missing marker"; fail=1; }
[ ! -e "$tmp/fat.so" ] && echo "  OK  no fat output" \
  || { echo "  FAIL wrote fat.so"; fail=1; }

echo
echo "=== --rewrite-ninja turns env -create into cmake -E copy ==="
mkdir -p "$tmp/build"
cat > "$tmp/build/build.ninja" <<'EOF'
  COMMAND = cd /tmp && /usr/bin/cmake -E env -create -output /tmp/lib/swift/macosx/libswiftCore.so /tmp/lib/swift/macosx/x86_64/libswiftCore.so
  COMMAND = cd /tmp && /usr/bin/cmake -E env PYTHONIOENCODING=UTF8 /usr/bin/python3 /tmp/line-directive
  COMMAND = cd /tmp && /usr/bin/cmake -E env /tmp/shims/lipo -create -output /tmp/keep.so /tmp/src.so
EOF
python3 "$py" --rewrite-ninja "$tmp/build"
got=$(cat "$tmp/build/build.ninja")
printf '%s\n' "$got" | grep -F -- '/usr/bin/cmake -E copy /tmp/lib/swift/macosx/x86_64/libswiftCore.so /tmp/lib/swift/macosx/libswiftCore.so' >/dev/null \
  && echo "  OK  empty-lipo became copy" || { echo "  FAIL rewrite missed empty lipo"; echo "$got"; fail=1; }
printf '%s\n' "$got" | grep -F -- 'cmake -E env PYTHONIOENCODING=UTF8' >/dev/null \
  && echo "  OK  env PYTHONIOENCODING left alone" || { echo "  FAIL rewrote gyb env"; fail=1; }
printf '%s\n' "$got" | grep -F -- '/tmp/shims/lipo -create' >/dev/null \
  && echo "  OK  real SWIFT_LIPO line left alone" || { echo "  FAIL rewrote real lipo"; fail=1; }
printf '%s\n' "$got" | grep -F -- 'cmake -E env -create' >/dev/null \
  && { echo "  FAIL empty-lipo line survived"; fail=1; } \
  || echo "  OK  no leftover env -create"

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- single-arch lipo copies; empty-lipo ninja is rewritten"
  exit 0
fi
echo "FAIL"
exit 1
