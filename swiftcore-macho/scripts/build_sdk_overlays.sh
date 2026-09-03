#!/bin/bash
# Build the five Apple-SDK overlays Linux CMake does not create:
#   _DarwinFoundation1/2/3, _errno (re-export shells)
#   ObjectiveC (real overlay from overlays/ObjectiveC.swift)
#
# Not ninja targets (stdlib/public/CMakeLists.txt:359). Compile with the
# Darwin overlay argv shape (no -parse-stdlib; -autolink-force-load) and
# link with the Darwin clang++ shim so ld64.lld gets sysroot libc++.tbd,
# never /usr/lib/llvm-18/lib, plus os_version_check.<arch>.o for availability.
#
# Prefer a sysroot .swiftinterface when present (scratch/sysroot_fe4[-x86_64]
# usr/lib/swift/<module>.swiftmodule/<triple>.swiftinterface). Otherwise
# compile the in-tree re-export shells (same @_exported import Apple ships).
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWIFTCORE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"

W=${W:-$HOME/work}
B=${B:-$W/build}
SDK=${SDK:-$W/sdk/MacOSX.sdk}
OVERLAY_SRC=$SWIFTCORE_ROOT/overlays
ARCH=${1:-$SWIFTCORE_DARWIN_ARCH}
BUILD_DIR=${2:-$B}
triple=$SWIFTCORE_MODULE_TRIPLE
target=$SWIFTCORE_CLANG_TARGET
out_lib=$BUILD_DIR/lib/swift/macosx/$ARCH
out_mod=$BUILD_DIR/lib/swift/macosx
work=$BUILD_DIR/sdk-overlays
clang_maps=$OVERLAY_SRC/clang
SWIFTC=${SWIFTC:-$TC/bin/swiftc}
CLANGXX=${CLANGXX:-$W/shims/clang++}
if [ ! -x "$CLANGXX" ]; then
  CLANGXX=(python3 "$SCRIPT_DIR/clangxx_darwin_link.py")
else
  CLANGXX=("$CLANGXX")
fi

mkdir -p "$work" "$out_lib" "$out_mod" "$work/modcache"

# Overlay links are NOUNDEFS; clang's __isPlatformVersionAtLeast lives in
# compiler-rt builtins, not gen_tbd libSystem. Link the static object
# (Apple's libclang_rt.osx.a member) into every overlay, including the
# five @_exported-import shells that do not reference the symbol.
if [ -d "$SDK" ] && [ "${SWIFTCORE_NINJA_HARNESS:-0}" != 1 ]; then
  export SWIFTCORE_SDKROOT="$SDK"
  export SWIFTCORE_WORK="$W"
  export SWIFTCORE_COMPILER_RT_OSX="${SWIFTCORE_COMPILER_RT_OSX:-$B/compiler-rt/os_version_check.${ARCH}.o}"
  bash "$SCRIPT_DIR/build_compiler_rt_osx.sh" "$SWIFTCORE_COMPILER_RT_OSX"
fi

# Sidecar Clang maps live outside the SDK; -I is required so header "errno.h"
# resolves to $SDK/usr/include, not overlays/clang/.
ensure_objc_nsobject_in_sdk_map() {
  local map=$SDK/usr/include/module.modulemap
  [ -f "$map" ] || return 0
  grep -q 'objc/NSObject.h' "$map" && return 0
  [ -f "$SDK/usr/include/objc/NSObject.h" ] || return 0
  python3 - "$map" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text()
needle = 'header "objc/message.h"'
insert = needle + '\n  header "objc/NSObject.h"'
if needle in text and 'objc/NSObject.h' not in text:
    p.write_text(text.replace(needle, insert, 1))
PY
  echo "sdk_overlay: added objc/NSObject.h to $map"
}

# Module maps must live in the SDK include dir so header "errno.h" resolves
# (Clang looks next to the map file). extern them from module.modulemap.
install_clang_overlay_maps() {
  local map=$SDK/usr/include/module.modulemap name
  cp -f "$clang_maps"/_DarwinFoundation1.modulemap \
        "$clang_maps"/_DarwinFoundation2.modulemap \
        "$clang_maps"/_DarwinFoundation3.modulemap \
        "$SDK/usr/include/"
  for name in _DarwinFoundation1 _DarwinFoundation2 _DarwinFoundation3; do
    grep -q "extern module $name " "$map" 2>/dev/null && continue
    printf '\nextern module %s "%s.modulemap"\n' "$name" "$name" >>"$map"
    echo "sdk_overlay: extern module $name -> $map"
  done
}

ensure_objc_nsobject_in_sdk_map
install_clang_overlay_maps

find_interface() {
  local name=$1 p root
  for root in \
    "${SYS:-}" \
    "$W/scratch/sysroot_fe4-${ARCH}" \
    "$W/scratch/sysroot_fe4-x86_64" \
    "$W/scratch/sysroot_fe4" \
    "$SDK" \
    "$W/sdk/MacOSX.sdk"
  do
    [ -n "$root" ] && [ -d "$root" ] || continue
    for p in \
      "$root/usr/lib/swift/${name}.swiftmodule/${triple}.swiftinterface" \
      "$root/usr/lib/swift/${name}.swiftinterface"
    do
      if [ -f "$p" ]; then
        printf '%s\n' "$p"
        return 0
      fi
    done
  done
  return 1
}

find_objc_source() {
  local p
  for p in \
    "$W/swift/stdlib/public/Darwin/ObjectiveC/ObjectiveC.swift" \
    "$OVERLAY_SRC/ObjectiveC.swift"
  do
    [ -f "$p" ] && { printf '%s\n' "$p"; return 0; }
  done
  return 1
}

swiftc_overlay() {
  local module=$1 link=$2 src=$3 obj=$4 moddir=$5
  shift 5 || true
  local extra=("$@")
  mkdir -p "$moddir"
  echo "sdk_overlay: swiftc module=$module src=$src"
  "$SWIFTC" \
    -c \
    -sdk "$SDK" \
    -target "$target" \
    -resource-dir "$BUILD_DIR/lib/swift" \
    -tools-directory "$(dirname "$SWIFTC")" \
    -module-cache-path "$work/modcache" \
    -parse-as-library \
    -O \
    -enable-library-evolution \
    -autolink-force-load \
    -module-name "$module" \
    -module-link-name "$link" \
    -I "$out_mod" \
    -swift-version 5 \
    -no-link-objc-runtime \
    -runtime-compatibility-version none \
    -Xcc -I"$SDK/usr/include" \
    -Xfrontend -disable-objc-attr-requires-foundation-module \
    -Xfrontend -disable-implicit-concurrency-module-import \
    -Xfrontend -disable-implicit-string-processing-module-import \
    -Xfrontend -disable-autolinking-runtime-compatibility-concurrency \
    "${extra[@]}" \
    -emit-module \
    -emit-module-path "$moddir/${triple}.swiftmodule" \
    -emit-module-interface-path "$moddir/${triple}.swiftinterface" \
    -o "$obj" \
    "$src"
  rm -f "$moddir/${triple}.swiftsourceinfo"
}

link_overlay() {
  local lib=$1 obj=$2
  local dylib=$out_lib/${lib}.dylib
  local so=$out_lib/${lib}.so
  local err=$work/${lib}.link.err
  local builtin="${SWIFTCORE_COMPILER_RT_OSX:-$BUILD_DIR/compiler-rt/os_version_check.${ARCH}.o}"
  echo "sdk_overlay: link $lib install_name=/usr/lib/swift/${lib}.dylib builtin=$builtin"
  set +e
  "${CLANGXX[@]}" \
    -target "$target" \
    -isysroot "$SDK" \
    -fuse-ld=lld \
    -B /usr/lib/llvm-18/bin \
    -shared \
    -Wl,-install_name,/usr/lib/swift/${lib}.dylib \
    -o "$dylib" \
    "$obj" \
    "$builtin" \
    -L "$out_lib" \
    -lswiftCore \
    -lSystem \
    -lobjc \
    2>"$err"
  local rc=$?
  set -e
  cat "$err" >&2 || true
  if [ "$rc" -ne 0 ]; then
    echo "sdk_overlay: link FAILED $lib rc=$rc" >&2
    return "$rc"
  fi
  if grep -q '/usr/lib/llvm-18/lib' "$err"; then
    echo "sdk_overlay: REFUSING Darwin link still mentions /usr/lib/llvm-18/lib" >&2
    return 2
  fi
  grep -E 'cxx_runtime=|compiler_rt=' "$err" || true
  cp -f "$dylib" "$so"
  echo "sdk_overlay: linked $dylib"
}

print_exports() {
  local dylib=$1
  echo "sdk_overlay: nm $(basename "$dylib")"
  llvm-nm-18 --defined-only --extern-only "$dylib" 2>/dev/null \
    | awk '{print $NF}' | sed 's/^_//' | sort -u
}

stage_module() {
  local name=$1
  mkdir -p "$out_mod/${name}.swiftmodule"
}

# Compare against Apple arm64 counterparts when present; always print ours.
compare_exports() {
  local lib=$1
  local ours=$out_lib/${lib}.dylib
  local apple="" cand
  for cand in \
    "$W/scratch/sysroot_fe4/usr/lib/swift/${lib}.dylib" \
    "$W/scratch/mrroot_full/darwin/usr/lib/swift/${lib}.dylib" \
    "$W/scratch/mrroot_fe/darwin/usr/lib/swift/${lib}.dylib" \
    "/Library/Developer/CoreSimulator/Volumes/iOS_23B80/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.1.simruntime/Contents/Resources/RuntimeRoot/usr/lib/swift/${lib}.dylib"
  do
    if [ -f "$cand" ]; then
      apple=$cand
      break
    fi
  done
  echo "==== export compare $lib ===="
  echo "-- ours (x86_64) --"
  print_exports "$ours" | tee "$work/${lib}.nm.ours"
  if [ -n "$apple" ]; then
    echo "-- apple ($apple) --"
    print_exports "$apple" | tee "$work/${lib}.nm.apple"
    echo "-- only in ours --"
    comm -23 "$work/${lib}.nm.ours" "$work/${lib}.nm.apple" || true
    echo "-- only in apple --"
    comm -13 "$work/${lib}.nm.ours" "$work/${lib}.nm.apple" || true
  else
    echo "-- apple arm64 counterpart ABSENT on this host (operator can provide nm lists) --"
    echo "-- documented Apple surface vs ours --"
    case "$lib" in
      libswift_DarwinFoundation1|libswift_DarwinFoundation2|libswift_DarwinFoundation3)
        echo "  expected Apple: __swift_FORCE_LOAD_\$_${lib#lib}. plus optional \$ld\$previous back-deploy"
        echo "  ours: FORCE_LOAD only (no magic-symbols-for-install-name.c on Linux)"
        ;;
      libswift_errno)
        echo "  expected Apple: Darwin.errno getter/setter + FORCE_LOAD"
        echo "  ours: \$s6Darwin5errnos5Int32Vvg / Vvs / VvM + FORCE_LOAD"
        ;;
      libswiftObjectiveC)
        echo "  expected Apple: NSObject ==, hash, FORCE_LOAD, Selector, ObjCBool, class/selector helpers, objc_enumerateClasses"
        echo "  ours: NSObject ==/hash/hashValue, FORCE_LOAD, Selector, ObjCBool, autoreleasepool"
        echo "  missing vs Apple: objc_enumerateClasses (needs ObjectiveC_Private / dyld; not in this sysroot)"
        ;;
    esac
  fi
}

build_one_shell() {
  local module=$1 link=$2 lib=$3 ninja_name=$4
  local iface src obj moddir kind
  moddir=$out_mod/${module}.swiftmodule
  mkdir -p "$moddir"
  obj=$work/${module}.o
  kind=synthesized
  src=$OVERLAY_SRC/${module}.swift
  if iface=$(find_interface "$module"); then
    kind=interface
    src=$iface
    echo "sdk_overlay: $module source=interface path=$iface"
  else
    echo "sdk_overlay: $module source=synthesized path=$src (sysroot interface absent)"
  fi
  [ -f "$src" ] || { echo "sdk_overlay: missing source $src" >&2; return 2; }
  local extra=()
  if [ "$module" = "_errno" ]; then
    extra+=(-Xfrontend -module-abi-name -Xfrontend Darwin)
  fi
  swiftc_overlay "$module" "$link" "$src" "$obj" "$moddir" "${extra[@]}" || return $?
  link_overlay "$lib" "$obj" || return $?
  echo "sdk_overlay: cxx_runtime printed above; dylib=$out_lib/${lib}.dylib kind=$kind"
  compare_exports "$lib"
  echo "sdk_overlay: STATUS $ninja_name built"
}

build_objc() {
  local src module=ObjectiveC link=swiftObjectiveC lib=libswiftObjectiveC
  local ninja_name=swiftObjectiveC-macosx-${ARCH}
  src=$(find_objc_source) || {
    echo "sdk_overlay: missing ObjectiveC.swift" >&2
    return 2
  }
  echo "sdk_overlay: ObjectiveC source=$src"
  local moddir=$out_mod/ObjectiveC.swiftmodule
  local obj=$work/ObjectiveC.o
  swiftc_overlay "$module" "$link" "$src" "$obj" "$moddir" || return $?
  link_overlay "$lib" "$obj" || return $?
  compare_exports "$lib"
  echo "sdk_overlay: STATUS $ninja_name built"
}

echo "==== sdk overlays (not CMake; Darwin driver) arch=$ARCH ===="
echo "sdk_overlay: sdk=$SDK resource-dir=$BUILD_DIR/lib/swift swiftc=$SWIFTC"

fail=0
build_one_shell _DarwinFoundation1 swift_DarwinFoundation1 libswift_DarwinFoundation1 \
  "swift_DarwinFoundation1-macosx-${ARCH}" || fail=1
build_one_shell _DarwinFoundation2 swift_DarwinFoundation2 libswift_DarwinFoundation2 \
  "swift_DarwinFoundation2-macosx-${ARCH}" || fail=1
build_one_shell _DarwinFoundation3 swift_DarwinFoundation3 libswift_DarwinFoundation3 \
  "swift_DarwinFoundation3-macosx-${ARCH}" || fail=1
build_one_shell _errno swift_errno libswift_errno \
  "swift_errno-macosx-${ARCH}" || fail=1
build_objc || fail=1

if [ "$fail" -ne 0 ]; then
  echo "sdk_overlay: FAILED" >&2
  exit 1
fi
echo "sdk_overlay: all five built"
exit 0
