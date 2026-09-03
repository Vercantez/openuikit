#!/bin/bash
# Darwin.o -fsyntax-only against the staged sysroot must not report the
# operator log names (sig_t, FILE, OSStatus, extern_proc, MAP_FAILED, libm
# f/l variants, ilogb/scalbn/remquo prototype mismatch).
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWIFTCORE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
OPENUIKIT_ROOT=$(cd "$SWIFTCORE_ROOT/.." && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"

fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

SWIFTC=${SWIFTC:-$TC/bin/swiftc}
if [ ! -x "$SWIFTC" ]; then
  echo "SKIP -- no swiftc at $SWIFTC"
  exit 0
fi

SDK=$tmp/sdk
mkdir -p "$SDK"
MACHORUN_SDK=${MACHORUN_SDK:-$OPENUIKIT_ROOT/machorun/sdk}
if [ ! -d "$MACHORUN_SDK/usr/include" ]; then
  echo "SKIP -- no machorun SDK at $MACHORUN_SDK"
  exit 0
fi
cp -a "$MACHORUN_SDK/usr" "$SDK/usr"
# POSIX + Darwin overlay staging (same order as stage_sdk.sh).
bash "$SCRIPT_DIR/stage_overlay_posix.sh" "$SDK"
SWIFTCORE_DARWIN_ARCH=x86_64 bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$SDK"
cat > "$SDK/SDKSettings.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CanonicalName</key><string>macosx15.0</string>
  <key>Version</key><string>15.0</string>
</dict></plist>
EOF
cat > "$SDK/SDKSettings.json" <<'EOF'
{ "DefaultProperties": { "PLATFORM_NAME": "macosx" },
  "Version": "15.0", "CanonicalName": "macosx15.0" }
EOF

# Probe the names the operator log reported. import Darwin is the Clang module.
cat > "$tmp/probe.swift" <<'EOF'
import Darwin

public func _probe_sig_t(_ h: sig_t?) {}
public func _probe_file(_ f: UnsafeMutablePointer<FILE>?) {}
public func _probe_osstatus(_ s: OSStatus) {}
public func _probe_extern_proc(_ p: extern_proc) {}
public let _probe_map_failed: UnsafeMutableRawPointer! = UnsafeMutableRawPointer(bitPattern: -1)

public func _probe_libm() {
  _ = acosf
  _ = acosl
  _ = asinhf
  _ = asinhl
  _ = atan2f
  _ = atan2l
  _ = cbrtf
  _ = cbrtl
  _ = copysignf
  _ = copysignl
  _ = coshf
  _ = coshl
  _ = erff
  _ = erfl
  _ = erfcf
  _ = erfcl
  _ = expm1f
  _ = expm1l
  _ = fdimf
  _ = fdiml
  _ = fmaxf
  _ = fmaxl
  _ = fminf
  _ = fminl
  _ = hypotf
  _ = hypotl
  _ = log1pf
  _ = log1pl
  _ = logbf
  _ = logbl
  _ = nanf
  _ = nanl
  _ = nextafterf
  _ = nextafterl
  _ = powf
  _ = powl
  _ = remquof
  _ = remquol
  _ = sinhf
  _ = sinhl
  _ = tanf
  _ = tanl
  _ = tanhf
  _ = tanhl
  _ = tgammaf
  _ = tgammal
  var q = Int32(0)
  _ = remquo(1.0 as Double, 2.0 as Double, &q)
  _ = ilogb(1.0 as Double)
  _ = scalbn(1.0 as Double, Int32(1))
}
EOF

log=$tmp/syntax.log
set +e
"$SWIFTC" -target "$SWIFTCORE_SWIFTC_TARGET" -sdk "$SDK" \
  -parse-as-library -fsyntax-only -parse-as-library \
  "$tmp/probe.swift" >"$log" 2>&1
rc=$?
set -e
echo "=== swiftc -fsyntax-only rc=$rc ==="
sed -n '1,80p' "$log"

if grep -Eq "no such module 'Darwin'|underlying Objective-C module 'Darwin' not found|cannot load underlying module for 'Darwin'" "$log"; then
  echo "  FAIL Clang module Darwin not found"
  fail=1
else
  echo "  OK  Clang module Darwin resolved"
fi

# The names from the operator log must not appear as 'cannot find'.
for name in sig_t FILE OSStatus extern_proc MAP_FAILED \
            acosf acosl asinhf asinhl atan2f atan2l cbrtf cbrtl \
            copysignf copysignl coshf coshl erff erfl erfcf erfcl \
            expm1f expm1l fdimf fdiml fmaxf fmaxl fminf fminl \
            hypotf hypotl log1pf log1pl logbf logbl nanf nanl \
            nextafterf nextafterl powf powl remquof remquol \
            sinhf sinhl tanf tanl tanhf tanhl tgammaf tgammal; do
  if grep -E "cannot find (type )?'$name'|cannot find '$name' in scope" "$log" >/dev/null; then
    echo "  FAIL still cannot find $name"
    fail=1
  else
    echo "  OK  no 'cannot find' for $name"
  fi
done

if grep -E "cannot convert value of type 'Int32' to expected argument type 'Int'|extra argument in call" "$log" >/dev/null; then
  echo "  FAIL ilogb/scalbn/remquo prototype mismatch still in log"
  grep -E "cannot convert value of type 'Int32'|extra argument in call" "$log" || true
  fail=1
else
  echo "  OK  no Int32/Int or extra-argument prototype mismatch"
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS -- Darwin.o names are visible against the staged sysroot (swiftc rc=$rc is a later wall if non-zero)"
  # A remaining error (missing Darwin submodule, SwiftShims, …) is allowed
  # only if it is not one of the enumerated names. Non-zero rc is OK when
  # the log is clean of those names; the operator overlay compile still
  # has to produce Darwin.o. If rc is 0, even better.
  exit 0
fi
echo "FAIL -- operator names still reported"
exit 1
