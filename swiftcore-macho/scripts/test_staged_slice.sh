#!/bin/bash
# Grade the committed Darwin slices. Arm64 must still be the recorded dylib;
# x86_64 must be MH_MAGIC_64 X86_64, not a rename of that file.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
ART=$ROOT/artifacts/swift-macosx
OTOOL=${OTOOL:-llvm-otool-18}
command -v "$OTOOL" >/dev/null || OTOOL=llvm-otool

ARM_PIN=dd01686e06c81a21755bb864b43dad446c011e6c60c6b387b3b332c0a12708cb
fail=0
ok() { echo "  OK  $*"; }
bad() { echo "  FAIL $*"; fail=1; }

sha() { sha256sum "$1" | awk '{print $1}'; }

echo "=== arm64 slice (must be unchanged) ==="
ARM=$ART/arm64/libswiftCore.dylib
[ -f "$ARM" ] || { echo "REFUSING: no arm64 libswiftCore"; exit 2; }
got=$(sha "$ARM")
[ "$got" = "$ARM_PIN" ] && ok "arm64 sha256 $ARM_PIN" || bad "arm64 sha $got != pin $ARM_PIN"
hdr=$("$OTOOL" -hv "$ARM")
echo "$hdr" | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64' && ok "MH_MAGIC_64 ARM64" || bad "arm64 header"
iname=$("$OTOOL" -D "$ARM" | tail -1)
[ "$iname" = /usr/lib/swift/libswiftCore.dylib ] && ok "arm64 LC_ID_DYLIB" || bad "arm64 id $iname"
[ -f "$ART/Swift.swiftmodule/arm64-apple-macos.swiftmodule" ] && ok "arm64 Swift.swiftmodule" \
  || bad "missing arm64 Swift.swiftmodule"

echo
echo "=== x86_64 slice (beside, never a rename) ==="
X86=$ART/x86_64/libswiftCore.dylib
[ -f "$X86" ] || { echo "REFUSING: no x86_64 libswiftCore — build_stdlib.sh has not staged"; exit 2; }
hdr=$("$OTOOL" -hv "$X86")
echo "$hdr" | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64' && ok "MH_MAGIC_64 X86_64 DYLIB" || bad "x86 header"
if echo "$hdr" | grep -q ARM64; then bad "ARM64 token in x86_64 dylib"; else ok "no ARM64 slice"; fi
iname=$("$OTOOL" -D "$X86" | tail -1)
[ "$iname" = /usr/lib/swift/libswiftCore.dylib ] && ok "x86 LC_ID_DYLIB" || bad "x86 id $iname"
[ "$(sha "$X86")" != "$ARM_PIN" ] && ok "x86 sha differs from arm64 (not a rename)" \
  || bad "x86 dylib is byte-identical to arm64"
[ -f "$ART/Swift.swiftmodule/x86_64-apple-macos.swiftmodule" ] && ok "x86 Swift.swiftmodule" \
  || bad "missing x86 Swift.swiftmodule"
[ -f "$ART/_Builtin_float.swiftmodule/x86_64-apple-macos.swiftmodule" ] && ok "x86 _Builtin_float.swiftmodule" \
  || bad "missing x86 _Builtin_float.swiftmodule"

echo
echo "=== in-tree FE overlays (phase2_fe_overlay_names minus Apple SDK splits) ==="
for n in libswiftDarwin.dylib libswiftSynchronization.dylib \
         libswift_Builtin_float.dylib libswift_RegexParser.dylib \
         libswift_StringProcessing.dylib; do
  f=$ART/x86_64/$n
  [ -f "$f" ] || { bad "missing $n"; continue; }
  hdr=$("$OTOOL" -hv "$f")
  echo "$hdr" | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64' && ok "$n MH_MAGIC_64 X86_64" \
    || bad "$n header"
  if echo "$hdr" | grep -q ARM64; then bad "$n has ARM64 token"; fi
  id=$("$OTOOL" -D "$f" | tail -1)
  [ "$id" = "/usr/lib/swift/$n" ] && ok "$n LC_ID_DYLIB" || bad "$n id $id"
done
for n in libswift_Concurrency.dylib libswiftObservation.dylib; do
  f=$ART/x86_64/$n
  [ -f "$f" ] || { bad "missing SwiftUI-load $n"; continue; }
  hdr=$("$OTOOL" -hv "$f")
  echo "$hdr" | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64' && ok "$n MH_MAGIC_64 X86_64" \
    || bad "$n header"
  id=$("$OTOOL" -D "$f" | tail -1)
  [ "$id" = "/usr/lib/swift/$n" ] && ok "$n LC_ID_DYLIB" || bad "$n id $id"
done
for n in libswift_DarwinFoundation1.dylib libswift_DarwinFoundation2.dylib \
         libswift_DarwinFoundation3.dylib libswift_errno.dylib; do
  [ ! -e "$ART/x86_64/$n" ] && ok "$n absent (CANNOT_STAGE_XCODE_DARWIN_OVERLAYS)" \
    || bad "must not stage fake $n"
done

echo
echo "=== manifests agree with files ==="
python3 - "$ROOT/artifacts/x86_64.manifest.json" "$ROOT/artifacts" <<'PY' || fail=1
import hashlib, json, sys
from pathlib import Path
man = json.loads(Path(sys.argv[1]).read_text())
root = Path(sys.argv[2])
n = 0
bad = 0
for rel, meta in man["files"].items():
    p = root / rel
    n += 1
    if not p.is_file():
        print(f"  FAIL missing {rel}"); bad += 1; continue
    h = hashlib.sha256(p.read_bytes()).hexdigest()
    if h != meta["sha256"] or p.stat().st_size != meta["bytes"]:
        print(f"  FAIL {rel} sha/size mismatch"); bad += 1
if man["source"]["commit"] != "ee343b46aef81c3ac7c5d7960cb35a41a88c5a9b":
    print("  FAIL source commit is not the 6.2.4 pin"); bad += 1
sib = man.get("siblings") or {}
want = {
    "swift-experimental-string-processing": "91177e6225c63e885872b83d48e254b1270fa15a",
    "swift-corelibs-libdispatch": "2df91f94651f2d924d7506c9d14685929386d779",
}
for name, commit in want.items():
    got = (sib.get(name) or {}).get("commit")
    if got != commit:
        print(f"  FAIL sibling {name} commit {got} != {commit}"); bad += 1
    else:
        print(f"  OK  sibling {name} @{commit}")
print(f"  {'OK' if bad==0 else 'FAIL'}  {n} files in x86_64.manifest.json, mismatches={bad}")
sys.exit(1 if bad else 0)
PY

echo
echo "=== libswiftcompat source pin matches the staged arm64 artifact ==="
if bash "$ROOT/scripts/test_compat_source.sh"; then
  echo "  OK  swiftcompat.c sha matches artifacts/libswiftcompat.source.json"
else
  echo "  FAIL swiftcompat.c / staged artifact pin"
  fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- arm64 pin intact, x86_64 is MH_MAGIC_64 X86_64 beside it"
  exit 0
fi
echo "FAIL"
exit 1
