#!/bin/bash
# Build a flat iOS-style .app, then exercise Foundation.Bundle in a real
# Darwin-Mach-O Swift process under machorun on Linux.
#
# The positive output is diffed against Apple's Foundation (captured by
# oracle_macos.sh).  Two controls prevent a decorative green result:
#   * changing the resource bytes must make the guest reject the fixture;
#   * removing libFoundation from an isolated root must stop at the loader.
#
# The exact direct and recursive Mach-O closure and every executable input are
# content-pinned in tests/baselines.  Updating the substrate therefore requires
# a deliberate remeasurement rather than silently changing what this proves.
set -euo pipefail
cd "$(dirname "$0")/.."

NAME=${NAME:-fm-build}
if ! docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
  echo "FATAL: container '$NAME' is not running. Start it with scripts/container.sh up" >&2
  exit 2
fi

# The read-only /stage snapshot and the working root must describe the same
# machorun build before the hashes below mean anything.
scripts/container.sh check

docker exec -i "$NAME" bash -s <<'INNER'
set -euo pipefail
W=/work
R=/repo
SDK=$W/sdk/MacOSX.sdk
LLD=/usr/lib/llvm-18/bin
TRIPLE=arm64-apple-macos13.0
RUN=$(mktemp -d /work/t22-run.XXXXXX)
MISSROOT=$(mktemp -d /work/t22-missing-root.XXXXXX)
trap 'rm -rf "$RUN" "$MISSROOT"' EXIT
APP=$RUN/FocusBundleProbe.app
EXE=$APP/FocusBundleProbe

bash "$R/scripts/build_slice.sh" >/tmp/t22-slice.log
bash "$R/scripts/build_overlay.sh" >/tmp/t22-overlay.log

mkdir -p "$APP"
cp "$R/tests/fixtures/t22/Info.plist" "$APP/Info.plist"
cp "$R/tests/fixtures/t22/launch_probe.txt" "$APP/launch_probe.txt"

swiftc -c -target "$TRIPLE" -sdk "$SDK" -O \
  -I "$W/swiftmodule" -module-cache-path "$W/swiftmodcache" \
  "$R/tests/t22_bundle_resource.swift" -o "$RUN/t22.o" \
  >/tmp/t22-compile.log 2>&1
clang -target "$TRIPLE" -isysroot "$SDK" -fuse-ld=lld -B "$LLD" \
  -nostdlib -L"$SDK/usr/lib" -L"$W/lib" "$RUN/t22.o" \
  -lswiftCore -lFoundation -lFoundationSlice "$W/lib/libswiftcompat.dylib" \
  -lSystem -lobjc -o "$EXE"

echo "== image identity"
file "$EXE" "$W/lib/libFoundation.dylib"
[ -x "$EXE" ] || {
  echo "FATAL: Mach-O probe is not executable" >&2
  exit 3
}
[ "$(od -An -tx1 -N4 "$EXE" | tr -d ' \n')" = cffaedfe ] || {
  echo "FATAL: probe does not have the arm64 Mach-O magic" >&2
  exit 3
}
if "$EXE" >/dev/null 2>&1; then
  echo "FATAL: the probe ran directly on Linux; it is not the guest claimed" >&2
  exit 3
else
  direct_rc=$?
fi
[ "$direct_rc" -eq 126 ] || {
  echo "FATAL: direct Linux execution failed with unexpected exit $direct_rc" >&2
  exit 3
}
echo "direct Linux execution exit=$direct_rc (Mach-O requires machorun)"

emit_loads() {
  local label=$1 file=$2
  llvm-otool-18 -l "$file" | awk -v p="$label" '
    $1 == "cmd" && ($2 == "LC_LOAD_DYLIB" ||
                    $2 == "LC_LOAD_WEAK_DYLIB" ||
                    $2 == "LC_REEXPORT_DYLIB") {
      kind=$2; want=1; next
    }
    want && $1 == "name" { print p "\t" kind "\t" $2; want=0 }
  '
}

ACTUAL_CLOSURE=$RUN/closure.tsv
: > "$ACTUAL_CLOSURE"
declare -a closure_labels=(FocusBundleProbe)
declare -a closure_files=("$EXE")
declare -A closure_seen=([FocusBundleProbe]=1)
for ((image_index=0; image_index < ${#closure_files[@]}; image_index++)); do
  image_loads=$RUN/loads.$image_index.tsv
  emit_loads "${closure_labels[$image_index]}" \
    "${closure_files[$image_index]}" > "$image_loads"
  cat "$image_loads" >> "$ACTUAL_CLOSURE"
  while IFS=$'\t' read -r _image _kind install_name; do
    [ -f "$W/root/darwin$install_name" ] || {
      echo "FATAL: closure member absent: $install_name" >&2
      exit 4
    }
    if [ -z "${closure_seen[$install_name]+present}" ]; then
      closure_seen[$install_name]=1
      closure_labels+=("$(basename "$install_name")")
      closure_files+=("$W/root/darwin$install_name")
    fi
  done < "$image_loads"
done
diff -u "$R/tests/baselines/t22_bundle_closure.tsv" "$ACTUAL_CLOSURE"
echo "closure=$(awk -F '\t' '{print $3}' "$ACTUAL_CLOSURE" | sort -u | wc -l | tr -d ' ') dylibs, all present"

# The app must import Bundle from the dylib, and the dylib must define it.  This
# catches accidentally compiling the implementation into the probe itself or
# linking Apple's/placeholder Foundation surface.
llvm-nm-18 -u "$EXE" | swift-demangle | \
  grep -q 'Foundation.Bundle.main.unsafeMutableAddressor'
llvm-nm-18 -u "$EXE" | swift-demangle | \
  grep -q 'Foundation.Bundle.path(forResource:'
cmp "$W/lib/libFoundation.dylib" \
    "$W/root/darwin/usr/lib/libFoundation.dylib"
cmp "$W/lib/libFoundationSlice.dylib" \
    "$W/root/darwin/usr/lib/libFoundationSlice.dylib"
llvm-nm-18 -gU "$W/root/darwin/usr/lib/libFoundation.dylib" | swift-demangle | \
  grep -q 'static Foundation.Bundle.main.getter'
llvm-nm-18 -gU "$W/root/darwin/usr/lib/libFoundation.dylib" | swift-demangle | \
  grep -q 'Foundation.Bundle.path(forResource:'
if llvm-nm-18 -gU "$W/root/darwin/usr/lib/libFoundation.dylib" | grep -q machorun_foundation_placeholder; then
  echo "FATAL: Bundle linked the declarations-only Foundation placeholder" >&2
  exit 5
fi
echo "undefined: app=$(llvm-nm-18 -u "$EXE" | wc -l | tr -d ' ') Foundation=$(llvm-nm-18 -u "$W/root/darwin/usr/lib/libFoundation.dylib" | wc -l | tr -d ' ') (resolved by the pinned closure at load)"

hash_line() {
  local path=$1 label=$2
  shasum -a 256 "$path" | awk -v label="$label" '{print $1 "  " label}'
}
ACTUAL_INPUTS=$RUN/inputs.sha256
{
  hash_line "$W/mrun" mrun
  hash_line "$W/root/darwin/usr/lib/swift/libswiftCore.dylib" root/darwin/usr/lib/swift/libswiftCore.dylib
  hash_line "$W/root/darwin/usr/lib/libSystem.B.dylib" root/darwin/usr/lib/libSystem.B.dylib
  hash_line "$W/root/darwin/usr/lib/libobjc.A.dylib" root/darwin/usr/lib/libobjc.A.dylib
  hash_line "$W/root/darwin/usr/lib/libc++.1.dylib" root/darwin/usr/lib/libc++.1.dylib
  hash_line "$W/root/darwin/usr/lib/libc++abi.dylib" root/darwin/usr/lib/libc++abi.dylib
  hash_line "$W/root/darwin/usr/lib/libswiftcompat.dylib" root/darwin/usr/lib/libswiftcompat.dylib
  hash_line "$W/root/darwin/usr/lib/libFoundationSlice.dylib" root/darwin/usr/lib/libFoundationSlice.dylib
  hash_line "$W/root/darwin/usr/lib/libFoundation.dylib" root/darwin/usr/lib/libFoundation.dylib
  hash_line "$EXE" app/FocusBundleProbe
  hash_line "$R/src/slice/NSSlice.m" repo/src/slice/NSSlice.m
  hash_line "$R/include/FoundationSlice.h" repo/include/FoundationSlice.h
  hash_line "$R/src/overlay/Foundation.swift" repo/src/overlay/Foundation.swift
  hash_line "$R/src/overlay/Bundle.swift" repo/src/overlay/Bundle.swift
  hash_line "$R/scripts/build_slice.sh" repo/scripts/build_slice.sh
  hash_line "$R/scripts/build_overlay.sh" repo/scripts/build_overlay.sh
  hash_line "$R/scripts/oracle_macos.sh" repo/scripts/oracle_macos.sh
  hash_line "$R/scripts/run_bundle_guest.sh" repo/scripts/run_bundle_guest.sh
  hash_line "$R/tests/t22_bundle_resource.swift" repo/tests/t22_bundle_resource.swift
  hash_line "$R/tests/fixtures/t22/Info.plist" repo/tests/fixtures/t22/Info.plist
  hash_line "$R/tests/fixtures/t22/launch_probe.txt" repo/tests/fixtures/t22/launch_probe.txt
} > "$ACTUAL_INPUTS"
diff -u "$R/tests/baselines/t22_bundle_inputs.sha256" "$ACTUAL_INPUTS"
echo "inputs=$(wc -l < "$ACTUAL_INPUTS" | tr -d ' ') content-pinned"

echo "== positive: Apple-Foundation differential"
set +e
positive=$(MACHORUN_ROOT="$W/root" "$W/mrun" "$EXE" 2>&1)
positive_rc=$?
set -e
printf '%s\n' "$positive"
[ "$positive_rc" -eq 0 ]
diff -u "$R/tests/baselines/t22_bundle_resource.txt" <(printf '%s\n' "$positive")

echo "== negative: changed resource bytes"
cp "$R/tests/fixtures/t22/launch_probe_mutated.txt" "$APP/launch_probe.txt"
set +e
mutated=$(MACHORUN_ROOT="$W/root" "$W/mrun" "$EXE" 2>&1)
mutated_rc=$?
set -e
printf 'exit=%s %s\n' "$mutated_rc" "$mutated"
[ "$mutated_rc" -eq 73 ]
[ "$mutated" = 'ORACLE_FAIL content=focus-bundle-oracle-MUTATED' ]

echo "== negative: Foundation runtime absent"
cp -a "$W/root/darwin" "$MISSROOT/darwin"
missing_target="$MISSROOT/darwin/usr/lib/libFoundation.dylib"
[ -f "$missing_target" ]
rm "$missing_target"
set +e
missing=$(MACHORUN_ROOT="$MISSROOT" "$W/mrun" "$EXE" 2>&1)
missing_rc=$?
set -e
printf 'exit=%s\n' "$missing_rc"
printf '%s\n' "$missing" | sed -n '1,2p'
[ "$missing_rc" -eq 72 ]
printf '%s\n' "$missing" | grep -Fq "cannot find dylib '/usr/lib/libFoundation.dylib'"
printf '%s\n' "$missing" | grep -Fq "required by: $EXE"

echo "bundle guest: PASS (positive + mutation control + missing-runtime control)"
INNER
