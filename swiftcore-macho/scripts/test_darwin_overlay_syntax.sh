#!/bin/bash
# Darwin overlay syntax-only against the staged sysroot must not report the
# operator log names (sig_t, FILE, OSStatus, extern_proc, MAP_FAILED, libm
# f/l variants, ilogb/scalbn/remquo prototype mismatch).
#
# clang -fsyntax-only @import Darwin is the Clang module. swiftc -typecheck
# (Swift has no -fsyntax-only) is Darwin.o's importer against the same SDK.
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
CLANG=${CLANG:-${TC}/bin/clang}
if [ ! -x "$CLANG" ]; then
  CLANG=$(command -v clang)
fi

SDK=$tmp/sdk
mkdir -p "$SDK"
MACHORUN_SDK=${MACHORUN_SDK:-$OPENUIKIT_ROOT/machorun/sdk}
if [ ! -d "$MACHORUN_SDK/usr/include" ]; then
  echo "SKIP -- no machorun SDK at $MACHORUN_SDK"
  exit 0
fi
cp -a "$MACHORUN_SDK/usr" "$SDK/usr"
bash "$SCRIPT_DIR/stage_overlay_posix.sh" "$SDK"
SWIFTCORE_DARWIN_ARCH=x86_64 bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$SDK"
cat > "$SDK/SDKSettings.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CanonicalName</key><string>macosx15.0</string>
  <key>DisplayName</key><string>macOS 15.0</string>
  <key>Version</key><string>15.0</string>
  <key>MaximumDeploymentTarget</key><string>15.0.99</string>
</dict>
</plist>
EOF
cat > "$SDK/SDKSettings.json" <<'EOF'
{ "DefaultProperties": { "PLATFORM_NAME": "macosx" },
  "DisplayName": "macOS 15.0", "Version": "15.0",
  "MaximumDeploymentTarget": "15.0.99",
  "CanonicalName": "macosx15.0" }
EOF

check_log() {
  local log=$1
  if grep -Eq "no such module 'Darwin'|underlying Objective-C module 'Darwin' not found|cannot load underlying module for 'Darwin'|module 'Darwin' not found" "$log"; then
    echo "  FAIL Clang module Darwin not found"
    fail=1
  else
    echo "  OK  Clang module Darwin resolved"
  fi
  local name
  for name in sig_t FILE OSStatus extern_proc MAP_FAILED \
              os_unfair_lock os_unfair_lock_lock os_unfair_lock_trylock \
              os_unfair_lock_unlock dlopen dlsym RTLD_NOLOAD \
              acosf acosl asinhf asinhl atan2f atan2l cbrtf cbrtl \
              copysignf copysignl coshf coshl erff erfl erfcf erfcl \
              expm1f expm1l fdimf fdiml fmaxf fmaxl fminf fminl \
              hypotf hypotl log1pf log1pl logbf logbl nanf nanl \
              nextafterf nextafterl powf powl remquof remquol \
              sinhf sinhl tanf tanl tanhf tanhl tgammaf tgammal; do
    if grep -E "cannot find (type )?'$name'|cannot find '$name' in scope|unknown type name '$name'|use of undeclared identifier '$name'" "$log" >/dev/null; then
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
}

echo "=== clang -fsyntax-only @import Darwin ==="
cat > "$tmp/probe.m" <<'EOF'
@import Darwin;
void probe(sig_t h, FILE *f, OSStatus s, struct extern_proc *p) {
  (void)h; (void)f; (void)s; (void)p;
  (void)os_unfair_lock_lock; (void)os_unfair_lock_trylock; (void)os_unfair_lock_unlock;
  (void)dlopen; (void)dlsym; (void)RTLD_NOLOAD;
  (void)acosf; (void)acosl; (void)asinhf; (void)asinhl;
  (void)atan2f; (void)atan2l; (void)cbrtf; (void)cbrtl;
  (void)copysignf; (void)copysignl; (void)coshf; (void)coshl;
  (void)erff; (void)erfl; (void)erfcf; (void)erfcl;
  (void)expm1f; (void)expm1l; (void)fdimf; (void)fdiml;
  (void)fmaxf; (void)fmaxl; (void)fminf; (void)fminl;
  (void)hypotf; (void)hypotl; (void)log1pf; (void)log1pl;
  (void)logbf; (void)logbl; (void)nanf; (void)nanl;
  (void)nextafterf; (void)nextafterl; (void)powf; (void)powl;
  (void)remquof; (void)remquol; (void)sinhf; (void)sinhl;
  (void)tanf; (void)tanl; (void)tanhf; (void)tanhl;
  (void)tgammaf; (void)tgammal;
  (void)ilogb; (void)scalbn; (void)remquo;
}
EOF
clang_log=$tmp/clang.log
set +e
"$CLANG" -fsyntax-only -fmodules -fimplicit-module-maps \
  -target "$SWIFTCORE_CLANG_TARGET" -isysroot "$SDK" \
  "$tmp/probe.m" >"$clang_log" 2>&1
clang_rc=$?
set -e
echo "clang -fsyntax-only rc=$clang_rc"
sed -n '1,80p' "$clang_log"
for h in os/lock.h dlfcn.h; do
  grep -q "header \"$h\"" "$SDK/usr/include/Darwin.modulemap" \
    && echo "  OK  Darwin.modulemap names $h" \
    || { echo "  FAIL Darwin.modulemap missing $h"; fail=1; }
done
check_log "$clang_log"
[ "$clang_rc" -eq 0 ] && echo "  OK  clang rc=0" \
  || { echo "  FAIL clang rc=$clang_rc"; fail=1; }

echo
echo "=== swiftc -typecheck import Darwin ==="
cat > "$tmp/probe.swift" <<'EOF'
import Darwin

public func _probe_sig_t(_ h: sig_t?) {}
public func _probe_file(_ f: UnsafeMutablePointer<FILE>?) {}
public func _probe_osstatus(_ s: OSStatus) {}
public func _probe_extern_proc(_ p: extern_proc) {}
public let _probe_map_failed: UnsafeMutableRawPointer! = UnsafeMutableRawPointer(bitPattern: -1)
public func _probe_unfair_lock(_ l: os_unfair_lock) {}
public func _probe_sync_dl() {
  _ = os_unfair_lock_lock
  _ = os_unfair_lock_trylock
  _ = os_unfair_lock_unlock
  _ = dlopen
  _ = dlsym
  _ = RTLD_NOLOAD
}

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

if [ ! -x "$SWIFTC" ]; then
  echo "SKIP swiftc -- no $SWIFTC (clang -fsyntax-only already ran)"
else
  RES=
  for d in "${B:-$HOME/work/build}/lib/swift" \
           "$SWIFTCORE_ROOT/artifacts/swift-macosx" \
           /usr/lib/swift; do
    if [ -d "$d" ]; then RES=$d; break; fi
  done
  swift_log=$tmp/swift.log
  set +e
  extra=()
  [ -n "$RES" ] && extra+=(-resource-dir "$RES")
  "$SWIFTC" -target "$SWIFTCORE_SWIFTC_TARGET" -sdk "$SDK" \
    -parse-as-library -typecheck "${extra[@]}" \
    "$tmp/probe.swift" >"$swift_log" 2>&1
  swift_rc=$?
  set -e
  echo "swiftc -typecheck rc=$swift_rc resource-dir=${RES:-none}"
  sed -n '1,80p' "$swift_log"
  check_log "$swift_log"
  [ "$swift_rc" -eq 0 ] && echo "  OK  swiftc rc=0" \
    || { echo "  FAIL swiftc rc=$swift_rc"; fail=1; }
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- Darwin names typecheck against the staged sysroot"
  exit 0
fi
echo "FAIL -- operator names still reported"
exit 1
