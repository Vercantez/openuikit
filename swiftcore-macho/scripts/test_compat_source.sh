#!/bin/bash
# Grade the committed arm64 libswiftcompat.dylib against the source that is
# supposed to have built it. A swiftcompat.c edit that does not rebuild the
# staged artifact is the stale-artefact class (084a028c).
#
# Also records the arch split that forbids deleting the nine x86-overlap
# symbols from the shared source: x86 libSystem exports them, the staged
# arm64 libSystem does not.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
fail=0
ok() { echo "  OK  $*"; }
bad() { echo "  FAIL $*"; fail=1; }

SRC=$ROOT/sdk/compat/swiftcompat.c
ART=$ROOT/artifacts/libswiftcompat.dylib
PIN=${COMPAT_SOURCE_PIN:-$ROOT/artifacts/libswiftcompat.source.json}
UNEXPORT=$ROOT/sdk/compat/x86_unexported_symbols.txt
MAN=$ROOT/artifacts/arm64.manifest.json
NM=${NM:-llvm-nm-18}
command -v "$NM" >/dev/null 2>&1 || NM=llvm-nm

[ -f "$SRC" ] || { echo "REFUSING: no $SRC" >&2; exit 2; }
[ -f "$ART" ] || { echo "REFUSING: no $ART" >&2; exit 2; }
[ -f "$PIN" ] || { echo "REFUSING: no $PIN (source sha must sit beside the artifact)" >&2; exit 2; }

src_sha=$(sha256sum "$SRC" | awk '{print $1}')
art_sha=$(sha256sum "$ART" | awk '{print $1}')
art_bytes=$(wc -c < "$ART" | tr -d ' ')

python3 - "$PIN" "$src_sha" "$art_sha" "$art_bytes" "$MAN" <<'PY' || fail=1
import json, sys
from pathlib import Path
pin_path, src_sha, art_sha, art_bytes, man_path = sys.argv[1:]
pin = json.loads(Path(pin_path).read_text())
bad = 0
want_src = pin["swiftcompat.c"]["sha256"]
if src_sha != want_src:
    print(f"  FAIL swiftcompat.c sha {src_sha} != recorded {want_src}")
    print("       rebuild artifacts/libswiftcompat.dylib from this source")
    print("       (or restore the source that built the staged artifact)")
    bad = 1
else:
    print(f"  OK  swiftcompat.c sha matches {want_src}")
want_art = pin["artifactSha256"]
if art_sha != want_art:
    print(f"  FAIL {pin['artifact']} sha {art_sha} != recorded {want_art}")
    bad = 1
else:
    print(f"  OK  {pin['artifact']} sha matches {want_art}")
if int(art_bytes) != int(pin["artifactBytes"]):
    print(f"  FAIL {pin['artifact']} bytes {art_bytes} != recorded {pin['artifactBytes']}")
    bad = 1
man = json.loads(Path(man_path).read_text())
man_ent = man["files"].get("libswiftcompat.dylib")
if not man_ent:
    print("  FAIL arm64.manifest.json has no libswiftcompat.dylib")
    bad = 1
elif man_ent["sha256"] != art_sha or int(man_ent["bytes"]) != int(art_bytes):
    print("  FAIL arm64.manifest.json disagrees with the staged artifact")
    bad = 1
else:
    print("  OK  arm64.manifest.json matches the staged artifact")
sys.exit(1 if bad else 0)
PY

echo
echo "=== arm64 artifact still exports the nine x86-overlap names ==="
[ -f "$UNEXPORT" ] || { bad "missing $UNEXPORT"; UNEXPORT=/dev/null; }
art_syms=$("$NM" --defined-only --extern-only "$ART" 2>/dev/null | awk '{print $NF}' | sort -u)
nine=0
while IFS= read -r s; do
  [ -n "$s" ] || continue
  case "$s" in \#*) continue ;; esac
  nine=$((nine + 1))
  echo "$art_syms" | grep -qx "$s" && ok "artifact exports $s" || bad "artifact missing $s"
done < "$UNEXPORT"
[ "$nine" -eq 9 ] && ok "unexport list has 9 names" || bad "unexport list has $nine names, expected 9"

echo
echo "=== nm both libSystem builds (skip a side that is absent) ==="
X86_SYS=${X86_LIBSYSTEM:-$ROOT/../machorun/darwin/usr/lib/libSystem.B.dylib}
ARM_SYS=${ARM_LIBSYSTEM:-}
for cand in \
    "$ROOT/../scratch/mrroot_full/darwin/usr/lib/libSystem.B.dylib" \
    "$ROOT/../scratch/sysroot_fe4/usr/lib/libSystem.B.dylib"; do
  [ -f "$cand" ] || continue
  if llvm-otool-18 -hv "$cand" 2>/dev/null | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64'; then
    ARM_SYS=$cand
    break
  fi
done
nm_has() {
  local f=$1 s=$2
  "$NM" --defined-only --extern-only "$f" 2>/dev/null | awk '{print $NF}' | grep -qx "$s"
}

if [ -f "$X86_SYS" ] && llvm-otool-18 -hv "$X86_SYS" 2>/dev/null | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64'; then
  x_hit=0
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    case "$s" in \#*) continue ;; esac
    if nm_has "$X86_SYS" "$s"; then x_hit=$((x_hit + 1)); else bad "x86 libSystem missing $s"; fi
  done < "$UNEXPORT"
  [ "$x_hit" -eq 9 ] && ok "x86 libSystem exports all 9 ($X86_SYS)" \
    || bad "x86 libSystem hit $x_hit/9"
else
  echo "  skip x86 libSystem (not an X86_64 Mach-O at $X86_SYS)"
fi

if [ -n "${ARM_SYS:-}" ] && [ -f "$ARM_SYS" ] \
    && llvm-otool-18 -hv "$ARM_SYS" 2>/dev/null | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64'; then
  a_hit=0
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    case "$s" in \#*) continue ;; esac
    nm_has "$ARM_SYS" "$s" && a_hit=$((a_hit + 1)) && bad "arm64 libSystem unexpectedly exports $s"
  done < "$UNEXPORT"
  [ "$a_hit" -eq 0 ] && ok "arm64 libSystem exports none of the 9 ($ARM_SYS)" \
    || bad "arm64 libSystem hit $a_hit/9 (drop would be right only if this is 9)"
else
  echo "  skip arm64 libSystem (no ARM64 Mach-O libSystem.B.dylib in scratch/)"
fi

hdr=$(llvm-otool-18 -hv "$ART" 2>/dev/null || true)
echo "$hdr" | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64' && ok "staged artifact is MH_MAGIC_64 ARM64" \
  || bad "staged artifact is not ARM64"

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- swiftcompat.c sha matches the pin beside artifacts/libswiftcompat.dylib"
  exit 0
fi
echo "FAIL"
exit 1
