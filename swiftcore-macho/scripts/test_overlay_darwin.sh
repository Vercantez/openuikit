#!/bin/bash
# Darwin overlay headers are Apple's (Libm / CarbonHeaders), staged with
# provenance. Darwin.modulemap names only headers that exist.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "=== stage into empty sysroot (x86_64) replaces nothing, writes Darwin.modulemap ==="
mkdir -p "$tmp/sdk"
set +e
out=$(SWIFTCORE_DARWIN_ARCH=x86_64 bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdk" 2>&1)
rc=$?
set -e
printf '%s\n' "$out"
[ "$rc" -eq 0 ] && echo "  OK  rc=0" || { echo "  FAIL rc=$rc"; fail=1; }
for h in usr/include/math.h usr/include/architecture/i386/math.h \
         usr/include/MacTypes.h usr/include/ConditionalMacros.h \
         usr/include/Darwin.modulemap usr/include/module.modulemap; do
  [ -f "$tmp/sdk/$h" ] && echo "  OK  $h" || { echo "  FAIL missing $h"; fail=1; }
done
printf '%s\n' "$out" | grep -q 'tag=Libm-2026' \
  && echo "  OK  Libm tag" || { echo "  FAIL missing Libm tag"; fail=1; }
printf '%s\n' "$out" | grep -q 'commit=17a5f9daa3f5679f7536b26f133b40cc078753c3' \
  && echo "  OK  Libm commit" || { echo "  FAIL missing Libm commit"; fail=1; }
printf '%s\n' "$out" | grep -q 'tag=CarbonHeaders-18.1' \
  && echo "  OK  CarbonHeaders tag" || { echo "  FAIL missing CarbonHeaders tag"; fail=1; }
printf '%s\n' "$out" | grep -q 'commit=214a9ae7ab3c0c78ddb50328ca226e6313c4c782' \
  && echo "  OK  CarbonHeaders commit" || { echo "  FAIL missing CarbonHeaders commit"; fail=1; }
cmp -s "$ROOT/sdk/overlay-darwin/math.h" "$tmp/sdk/usr/include/math.h" \
  && echo "  OK  math.h is the vendored Libm Intel file" \
  || { echo "  FAIL math.h mismatch"; fail=1; }
grep -q 'extern float  acosf' "$tmp/sdk/usr/include/math.h" \
  && echo "  OK  acosf is a real prototype (not a macro)" \
  || { echo "  FAIL acosf missing"; fail=1; }
grep -q 'typedef SInt32                          OSStatus' "$tmp/sdk/usr/include/MacTypes.h" \
  && echo "  OK  OSStatus in Apple MacTypes.h" \
  || { echo "  FAIL no OSStatus"; fail=1; }
grep -q 'module Darwin' "$tmp/sdk/usr/include/Darwin.modulemap" \
  && echo "  OK  Darwin.modulemap declares module Darwin" \
  || { echo "  FAIL no module Darwin"; fail=1; }
grep -q 'header "math.h"' "$tmp/sdk/usr/include/Darwin.modulemap" \
  && echo "  OK  Darwin.modulemap names math.h" \
  || { echo "  FAIL math.h not in modulemap"; fail=1; }
grep -q 'extern module Darwin' "$tmp/sdk/usr/include/module.modulemap" \
  && echo "  OK  module.modulemap references Darwin" \
  || { echo "  FAIL no extern module Darwin"; fail=1; }
# Generated map must not name a header that is not there.
while IFS= read -r h; do
  [ -f "$tmp/sdk/usr/include/$h" ] && echo "  OK  map header exists: $h" \
    || { echo "  FAIL map names absent $h"; fail=1; }
done < <(sed -n 's/.*header "\([^"]*\)".*/\1/p' "$tmp/sdk/usr/include/Darwin.modulemap")

echo
echo "=== replace clean-room math.h / MacTypes.h in a pre-populated sysroot ==="
mkdir -p "$tmp/sdk2/usr/include"
echo '/* clean-room stand-in */' > "$tmp/sdk2/usr/include/math.h"
echo '/* clean-room stand-in */' > "$tmp/sdk2/usr/include/MacTypes.h"
set +e
out=$(SWIFTCORE_DARWIN_ARCH=x86_64 bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdk2" 2>&1)
rc=$?
set -e
printf '%s\n' "$out" | tail -20
[ "$rc" -eq 0 ] && echo "  OK  replace rc=0" || { echo "  FAIL replace rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'replacing usr/include/math.h' \
  && echo "  OK  replaced math.h" || { echo "  FAIL did not replace math.h"; fail=1; }
cmp -s "$ROOT/sdk/overlay-darwin/math.h" "$tmp/sdk2/usr/include/math.h" \
  && echo "  OK  math.h now Apple Intel" || { echo "  FAIL math.h still stand-in"; fail=1; }

echo
echo "=== arm64 path does not overwrite math.h with Intel Libm ==="
mkdir -p "$tmp/sdk3/usr/include"
echo '/* arm64 clean-room math.h */' > "$tmp/sdk3/usr/include/math.h"
set +e
out=$(SWIFTCORE_DARWIN_ARCH=arm64 bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdk3" 2>&1)
rc=$?
set -e
[ "$rc" -eq 0 ] && echo "  OK  arm64 rc=0" || { echo "  FAIL arm64 rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'skipping Libm Intel math.h' \
  && echo "  OK  skipped Intel math.h on arm64" \
  || { echo "  FAIL arm64 still staged Intel math.h"; fail=1; }
grep -q 'arm64 clean-room math.h' "$tmp/sdk3/usr/include/math.h" \
  && echo "  OK  arm64 math.h untouched" || { echo "  FAIL arm64 math.h replaced"; fail=1; }

echo
echo "=== FE sysroot Darwin.modulemap is copied when present ==="
mkdir -p "$tmp/fe/usr/include" "$tmp/sdk4/usr/include" "$tmp/work/scratch"
echo 'module Darwin [system] { header "math.h" export * }' \
  > "$tmp/fe/usr/include/Darwin.modulemap"
echo 'extern module Darwin "Darwin.modulemap"' > "$tmp/fe/usr/include/module.modulemap"
echo 'extern float acosf(float);' > "$tmp/fe/usr/include/math.h"
ln -sfn "$tmp/fe" "$tmp/work/scratch/sysroot_fe4-x86_64"
set +e
out=$(W="$tmp/work" SWIFTCORE_DARWIN_ARCH=x86_64 \
  bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdk4" 2>&1)
rc=$?
set -e
printf '%s\n' "$out"
[ "$rc" -eq 0 ] && echo "  OK  FE rc=0" || { echo "  FAIL FE rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'FE sysroot' \
  && echo "  OK  used FE sysroot" || { echo "  FAIL did not use FE"; fail=1; }
grep -q 'header "math.h"' "$tmp/sdk4/usr/include/Darwin.modulemap" \
  && echo "  OK  FE Darwin.modulemap copied" \
  || { echo "  FAIL FE map missing"; fail=1; }
grep -q 'extern float acosf' "$tmp/sdk4/usr/include/math.h" \
  && echo "  OK  FE math.h copied" || { echo "  FAIL FE math.h missing"; fail=1; }

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- overlay Darwin headers staged from Apple OSS / FE sysroot"
  exit 0
fi
echo "FAIL"
exit 1
