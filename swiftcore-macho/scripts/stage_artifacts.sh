#!/bin/bash
# Copy a just-built Darwin slice into artifacts/swift-macosx/<arch>/ beside
# the other slice. Never overwrites arm64 files. Writes a sha256 manifest.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWIFTCORE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"

W=${W:-$HOME/work}
B=${B:-$W/build}
SRC_DIR=$B/lib/swift
DEST_ROOT=$SWIFTCORE_ROOT/artifacts/swift-macosx
DEST_LIB=$DEST_ROOT/$SWIFTCORE_DARWIN_ARCH
MANIFEST=$SWIFTCORE_ROOT/artifacts/${SWIFTCORE_DARWIN_ARCH}.manifest.json

mkdir -p "$DEST_LIB"

# Hostile: never copy an arm64 Mach-O into the x86_64 directory (or vice versa).
check_cpu() {
  local f=$1
  local hdr
  hdr=$(llvm-otool-18 -hv "$f" 2>/dev/null || true)
  case "$SWIFTCORE_DARWIN_ARCH" in
    x86_64)
      echo "$hdr" | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64' || {
        echo "stage_artifacts: REFUSING $f — not MH_MAGIC_64 X86_64" >&2
        echo "  $(file -b "$f")" >&2
        exit 2
      }
      if echo "$hdr" | grep -q ARM64; then
        echo "stage_artifacts: REFUSING $f — ARM64 token in an x86_64 dest" >&2
        exit 2
      fi
      ;;
    arm64)
      echo "$hdr" | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64' || {
        echo "stage_artifacts: REFUSING $f — not MH_MAGIC_64 ARM64" >&2
        exit 2
      }
      ;;
  esac
}

copied=0
while IFS= read -r -d '' f; do
  bn=$(basename "$f")
  dest=$DEST_LIB/$bn
  case "$f" in
    *.dylib)
      check_cpu "$f"
      if [ -f "$dest" ]; then
        check_cpu "$dest"
      fi
      ;;
    *.a) ;;
    *) continue ;;
  esac
  cp -f "$f" "$dest"
  echo "  $bn  $(wc -c < "$dest") bytes"
  copied=$((copied + 1))
done < <(find "$SRC_DIR/${SWIFTCORE_STDLIB_DIR}" -maxdepth 1 -type f \( -name '*.dylib' -o -name '*.a' \) -print0 2>/dev/null)

# Modules: per-triple files go in the shared *.swiftmodule directories so
# arm64-apple-macos.* and x86_64-apple-macos.* sit beside each other.
mod_copied=0
while IFS= read -r -d '' d; do
  name=$(basename "$d")
  dest_mod=$DEST_ROOT/$name
  mkdir -p "$dest_mod"
  for f in "$d"/${SWIFTCORE_MODULE_TRIPLE}.*; do
    [ -f "$f" ] || continue
    bn=$(basename "$f")
    case "$bn" in
      arm64-apple-macos.*)
        [ "$SWIFTCORE_DARWIN_ARCH" = arm64 ] || {
          echo "stage_artifacts: REFUSING to copy $bn into an x86 staging pass" >&2
          exit 2
        }
        ;;
      x86_64-apple-macos.*)
        [ "$SWIFTCORE_DARWIN_ARCH" = x86_64 ] || {
          echo "stage_artifacts: REFUSING to copy $bn into an arm64 staging pass" >&2
          exit 2
        }
        ;;
    esac
    cp -f "$f" "$dest_mod/$bn"
    echo "  module $name/$bn  $(wc -c < "$dest_mod/$bn") bytes"
    mod_copied=$((mod_copied + 1))
  done
done < <(find "$SRC_DIR/macosx" -maxdepth 1 -type d -name '*.swiftmodule' -print0 2>/dev/null)

[ "$copied" -gt 0 ] || {
  echo "stage_artifacts: REFUSING — copied 0 dylibs from $SRC_DIR/${SWIFTCORE_STDLIB_DIR}" >&2
  exit 2
}

python3 - "$MANIFEST" "$SWIFTCORE_DARWIN_ARCH" "$SWIFTCORE_MODULE_TRIPLE" \
  "$SWIFT_PIN_COMMIT" "$SWIFT_PIN_TAG" "$DEST_ROOT" "$DEST_LIB" \
  "$STRING_PROCESSING_PIN_COMMIT" "$LIBDISPATCH_PIN_COMMIT" <<'PY'
import hashlib, json, os, sys, time
from pathlib import Path

(manifest, arch, module_triple, commit, tag, dest_root, dest_lib,
 sp_commit, dispatch_commit) = sys.argv[1:]

def sha256(p: Path):
    h = hashlib.sha256()
    with p.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

files = {}
for p in sorted(Path(dest_lib).glob("*")):
    if p.is_file():
        rel = str(p.relative_to(Path(dest_root).parent))
        files[rel] = {"sha256": sha256(p), "bytes": p.stat().st_size}
root = Path(dest_root)
for p in sorted(root.rglob(f"{module_triple}.*")):
    rel = str(p.relative_to(root.parent))
    files[rel] = {"sha256": sha256(p), "bytes": p.stat().st_size}

payload = {
    "schema": "swiftcore-macho/artifacts/manifest.schema.json",
    "arch": arch,
    "moduleTriple": module_triple,
    "source": {
        "repository": "https://github.com/swiftlang/swift.git",
        "tag": tag,
        "commit": commit,
    },
    "siblings": {
        "swift-experimental-string-processing": {
            "repository": "https://github.com/swiftlang/swift-experimental-string-processing.git",
            "tag": tag,
            "commit": sp_commit,
        },
        "swift-corelibs-libdispatch": {
            "repository": "https://github.com/swiftlang/swift-corelibs-libdispatch.git",
            "tag": tag,
            "commit": dispatch_commit,
        },
    },
    "patches": "scripts/apply_patches.py 1-5+7+8; patch 5 via SWIFTCORE_MACHO_LEGACY_IMAGE_REG=1; patch 6 (isa widen) off; patch 8 Darwin-target skips CMake dispatch link lib",
    "flags": {
        "SWIFTCORE_DARWIN_ARCH": arch,
        "SWIFT_SDK_OSX_ARCHITECTURES": arch,
        "SWIFT_INCLUDE_TOOLS": "OFF",
        "SWIFT_BUILD_STDLIB": "ON",
        "SWIFT_STDLIB_ENABLE_OBJC_INTEROP": "ON",
        "SWIFT_ENABLE_EXPERIMENTAL_CONCURRENCY": "ON",
        "SWIFT_BUILD_SDK_OVERLAY": "OFF",
        "SWIFTCORE_MACHO_LEGACY_IMAGE_REG": "1",
        "SWIFT_PATH_TO_STRING_PROCESSING_SOURCE": "pinned sibling",
        "SWIFT_PATH_TO_LIBDISPATCH_SOURCE": "pinned sibling",
        "SWIFT_ENABLE_DISPATCH": "ON",
    },
    "toolchain": "Swift version 6.2.4 (swift-6.2.4-RELEASE)",
    "host": os.uname().machine + "-unknown-linux-gnu",
    "generatedAtUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "fileCount": len(files),
    "files": files,
}
Path(manifest).write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
print(f"manifest {manifest} files={len(files)}")
PY

echo "staged $copied dylibs + $mod_copied module files -> $DEST_LIB (arm64 tree untouched)"
