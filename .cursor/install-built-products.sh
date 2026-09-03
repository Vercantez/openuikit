#!/usr/bin/env bash
# Cold-build in-repo products the pinned x86_64 toolchain can emit.
# Pieces that require aarch64 host execution or an Xcode SDK are logged
# precisely and omitted -- never approximated under the production names.

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
case "$repo_root" in ''|/) printf 'cursor-products: unsafe repository root\n' >&2; exit 1 ;; esac

host=$(uname -m)
machorun=$repo_root/machorun
scratch=$repo_root/scratch
manifest=$scratch/.cursor-built-products.json
unavailable=$scratch/.cursor-unavailable.txt
mkdir -p "$scratch"
: > "$unavailable"

note_unavailable() {
    printf '%s\n' "$1" | tee -a "$unavailable" >&2
}

tree_digest() {
    python3 "$repo_root/.cursor/tree-digest.py" "$1"
}

export DARWIN_CLANG=clang-18
# `clang` on PATH is Swift's bundled clang 17. Darwin/objc4/quartz must use
# the pinned Ubuntu LLVM 18 that ld64.lld-18 belongs with.
export CC=clang-18

# ---- x86_64: run the committed cycle (substrate only). ----
# Overlays come from swiftcore-macho/artifacts (SKIP_OVERLAYS). Phase2 rungs
# run in verify-cloud-environment.sh (SKIP_PHASE2) so install stays bounded.
if [ "$host" = x86_64 ]; then
    export W=$repo_root
    # shellcheck disable=SC1091
    . "$repo_root/full/scripts/guest_arch.inc"
    export OPENUIKIT_CYCLE_SKIP_OVERLAYS=1
    export OPENUIKIT_CYCLE_SKIP_PHASE2=1
    echo "== x86 cycle substrate (SKIP_OVERLAYS=1 SKIP_PHASE2=1 tree=$repo_root)"
    bash "$repo_root/scripts/ops/x86_cycle.sh" "$repo_root"

    loader=$machorun/build/machorun
    [ -x "$loader" ] || { printf 'cursor-products: missing x86 loader\n' >&2; exit 1; }
    file -b "$loader" | grep -q 'ELF 64-bit LSB pie executable, x86-64' \
        || { printf 'cursor-products: loader is not x86-64 ELF PIE: %s\n' "$(file -b "$loader")" >&2; exit 1; }
    loader_ok=1
    tbd=$machorun/sdk/usr/lib/libSystem.tbd
    [ -s "$tbd" ] && grep -q 'x86_64-macos' "$tbd" \
        || { printf 'cursor-products: missing x86 libSystem.tbd\n' >&2; exit 1; }
    tbd_ok=1

    for dylib in \
        "$machorun/darwin/usr/lib/libSystem.B.dylib" \
        "$machorun/darwin/usr/lib/libc++.1.dylib" \
        "$machorun/darwin/usr/lib/libc++abi.dylib" \
        "$machorun/darwin/usr/lib/libobjc.A.dylib" \
        "$machorun/darwin/usr/lib/libquartz.dylib" \
        "$machorun/darwin/usr/lib/libswiftcompat.dylib"
    do
        [ -f "$dylib" ] || { printf 'cursor-products: missing %s\n' "$dylib" >&2; exit 1; }
        llvm-otool-18 -hv "$dylib" | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64' \
            || { printf 'cursor-products: not X86_64 Mach-O: %s\n' "$dylib" >&2; exit 1; }
    done
    core=$repo_root/swiftcore-macho/artifacts/swift-macosx/x86_64/libswiftCore.dylib
    [ -f "$core" ] || { printf 'cursor-products: missing x86 libswiftCore.dylib\n' >&2; exit 1; }

    sys=$scratch/sysroot_fe4-x86_64
    mrroot=$scratch/mrroot_full-x86_64
    [ -d "$sys/usr/include" ] || { printf 'cursor-products: missing %s\n' "$sys" >&2; exit 1; }
    [ -f "$sys/usr/include/Darwin.modulemap" ] \
        || { printf 'cursor-products: sysroot missing Darwin.modulemap\n' >&2; exit 1; }
    { [ -d "$sys/usr/lib/swift/Darwin.swiftmodule" ] \
        || [ -f "$sys/usr/lib/swift/Darwin.swiftinterface" ]; } \
        || { printf 'cursor-products: sysroot missing Darwin overlay\n' >&2; exit 1; }
    [ -x "$mrroot/machorun" ] || { printf 'cursor-products: missing %s/machorun\n' "$mrroot" >&2; exit 1; }
    fw=$mrroot/darwin/System/Library/Frameworks
    [ -f "$fw/Foundation.framework/Foundation" ] \
        || { printf 'cursor-products: missing Foundation placeholder in mrroot_full-x86_64\n' >&2; exit 1; }
    [ -f "$fw/CoreFoundation.framework/CoreFoundation" ] \
        || { printf 'cursor-products: missing CoreFoundation placeholder in mrroot_full-x86_64\n' >&2; exit 1; }
    llvm-nm-18 -g "$fw/Foundation.framework/Foundation" | grep -q _machorun_foundation_placeholder \
        || { printf 'cursor-products: Foundation slot is not the empty placeholder\n' >&2; exit 1; }
    llvm-nm-18 -g "$fw/CoreFoundation.framework/CoreFoundation" | grep -q _machorun_foundation_placeholder \
        || { printf 'cursor-products: CoreFoundation slot is not the empty placeholder\n' >&2; exit 1; }

    empty_tbd=$(find "$sys" -name '*.tbd' -size 0 -print -quit)
    [ -z "$empty_tbd" ] \
        || { printf 'cursor-products: empty .tbd is a linker lie: %s\n' "$empty_tbd" >&2; exit 1; }

    note_unavailable "CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS host=$host reason=full/foundation/stage_swift_overlays.sh copies overlay dylibs from an iOS CoreSimulator runtime on macOS. This VM stages the committed x86_64 artifacts (swiftcore-macho/artifacts/swift-macosx/x86_64) instead; it does not materialize Apple's simulator copies."
    if [ ! -d "$scratch/opencombine-core-durable-20260828-r2/export" ]; then
        note_unavailable "CURSOR_ENV_CANNOT_BUILD_OPENCOMBINE_EXPORT host=$host reason=full/oracle-opencombine/build_and_run.sh compiles and RUNS the core under machorun inside a pinned fm-build container. x86 OpenCombine lands in export-x86_64/ from scripts/x86/build_opencombine.sh when phase2 runs it; the arm64 durable export/ is not rewritten."
    fi
    if [ ! -d "$scratch/modcache_swiftui_guest" ]; then
        note_unavailable "CURSOR_ENV_CANNOT_BUILD_MODCACHE_SWIFTUI_GUEST host=$host reason=scratch/modcache_swiftui_guest is the arm64 SwiftUI guest module cache. x86 uses scratch/modcache_fe4-x86_64 (created by phase2). Leaving the unsuffixed path absent is the honest state."
    fi
    if ! ls -d /tmp/focus-resources-x86-staged.*/bundles/Focus_Widget.bundle >/dev/null 2>&1; then
        note_unavailable "CURSOR_ENV_CANNOT_STAGE_FOCUS_BUNDLES host=$host reason=normalized Focus_Widget.bundle lives at /tmp/focus-resources-x86-staged.*/bundles on the operator box (S3-staged; needs pdftocairo + onboarding_resources_proof.py). Rung b is not this install's job."
    fi

    expected_markers=(
        CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS
    )
    [ -d "$scratch/opencombine-core-durable-20260828-r2/export" ] \
        || expected_markers+=(CURSOR_ENV_CANNOT_BUILD_OPENCOMBINE_EXPORT)
    [ -d "$scratch/modcache_swiftui_guest" ] \
        || expected_markers+=(CURSOR_ENV_CANNOT_BUILD_MODCACHE_SWIFTUI_GUEST)
    ls -d /tmp/focus-resources-x86-staged.*/bundles/Focus_Widget.bundle >/dev/null 2>&1 \
        || expected_markers+=(CURSOR_ENV_CANNOT_STAGE_FOCUS_BUNDLES)

    expected_count=${#expected_markers[@]}
    logged_count=0
    missing_expected=0
    for marker in "${expected_markers[@]}"; do
        if grep -q "^$marker " "$unavailable"; then
            logged_count=$((logged_count + 1))
        else
            printf 'cursor-products: missing expected unavailable marker: %s\n' "$marker" >&2
            missing_expected=$((missing_expected + 1))
        fi
    done
    [ "$missing_expected" -eq 0 ] \
        || { printf 'cursor-products: expected unavailable markers %s/%s\n' \
            "$logged_count" "$expected_count" >&2; exit 1; }
    total_logged=$(grep -c '^CURSOR_ENV_CANNOT_' "$unavailable" || true)

    sys_hash=$(tree_digest "$sys")
    mrroot_hash=$(tree_digest "$mrroot")
    darwin_hash=$(tree_digest "$machorun/darwin/usr/lib")

    python3 - "$manifest" "$host" "$loader_ok" "$tbd_ok" "$sys_hash" "$mrroot_hash" "$darwin_hash" \
        "$sys" "$mrroot" "$machorun" "$core" "$loader" <<'PY'
import hashlib, json, sys
from pathlib import Path

manifest, host, loader_ok, tbd_ok, sys_hash, mrroot_hash, darwin_hash, sysroot, mrroot, machorun, core, loader = sys.argv[1:]

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

files = {}
for label, path in [
    ("libSystem.B.dylib", Path(machorun) / "darwin/usr/lib/libSystem.B.dylib"),
    ("libc++.1.dylib", Path(machorun) / "darwin/usr/lib/libc++.1.dylib"),
    ("libobjc.A.dylib", Path(machorun) / "darwin/usr/lib/libobjc.A.dylib"),
    ("libquartz.dylib", Path(machorun) / "darwin/usr/lib/libquartz.dylib"),
    ("libswiftCore.dylib", Path(core)),
    ("libswiftcompat.dylib", Path(machorun) / "darwin/usr/lib/libswiftcompat.dylib"),
    ("machorun", Path(loader)),
]:
    files[label] = {"path": str(path), "sha256": sha256(path), "bytes": path.stat().st_size}

payload = {
    "host": host,
    "arch": "x86_64",
    "loaderBuilt": loader_ok == "1",
    "tbdGenerated": tbd_ok == "1",
    "sysrootFe4TreeSha256": sys_hash,
    "mrrootFullTreeSha256": mrroot_hash,
    "darwinUserlandTreeSha256": darwin_hash,
    "sysrootFe4": sysroot,
    "mrrootFull": mrroot,
    "files": files,
}
Path(manifest).write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

    printf 'CURSOR_BUILT_PRODUCTS_OK host=%s loader=%s tbd=%s arch=x86_64 sysroot_fe4-x86_64=%s mrroot_full-x86_64=%s darwin_dylibs=6/6\n' \
        "$host" "$loader_ok" "$tbd_ok" "$sys_hash" "$mrroot_hash"
    printf 'CURSOR_UNAVAILABLE_COUNT expected=%s/%s logged=%s (see %s)\n' \
        "$logged_count" "$expected_count" "$total_logged" "$unavailable"
    exit 0
fi

# ---- aarch64: cold-build in-repo arm64 Mach-O products (historical path). ----

# ---- machorun host loader (aarch64 assembly; cannot assemble on x86_64) ----
loader_ok=0
if [ "$host" = aarch64 ] || [ "$host" = arm64 ]; then
    sh "$machorun/scripts/build.sh" loader
    loader_ok=1
else
    set +e
    loader_log=$(mktemp)
    sh "$machorun/scripts/build.sh" loader >"$loader_log" 2>&1
    loader_status=$?
    set -e
    if [ "$loader_status" -eq 0 ] && [ -x "$machorun/build/machorun" ]; then
        loader_ok=1
    else
        note_unavailable "CURSOR_ENV_CANNOT_BUILD_LOADER host=$host reason=machorun/src/tlv_asm.S is aarch64 assembly (stp/ldp of x/q registers); this VM is $host and cannot assemble the host loader. The loader is a native Linux/aarch64 ELF, not a cross-built Mach-O."
        tail -n 5 "$loader_log" >&2 || true
    fi
    rm -f "$loader_log"
    rm -f "$machorun/build/tlv_asm.o" "$machorun/build/machorun"
fi

# ---- Darwin userland as arm64 Mach-O (Linux x86_64 CAN emit this) ----
echo "== darwin userland (arm64 Mach-O via clang-18 -target arm64-apple-macos11)"
sh "$machorun/scripts/build.sh" darwin
bash "$machorun/scripts/build_objc4.sh"
bash "$machorun/scripts/build_quartz.sh"

# ---- stage in-repo swiftcore-macho artifacts (already arm64 Mach-O) ----
artifacts=$repo_root/swiftcore-macho/artifacts
[ -f "$artifacts/swift-macosx/arm64/libswiftCore.dylib" ] \
    || { printf 'cursor-products: missing in-repo libswiftCore.dylib\n' >&2; exit 1; }
bash "$machorun/scripts/stage_swiftcore.sh" "$artifacts"
if [ -f "$artifacts/concurrency/swift-macosx/arm64/libswift_Concurrency.dylib" ]; then
    cp -f "$artifacts/concurrency/swift-macosx/arm64/libswift_Concurrency.dylib" \
        "$machorun/darwin/usr/lib/swift/libswift_Concurrency.dylib"
    file -b "$machorun/darwin/usr/lib/swift/libswift_Concurrency.dylib" | \
        grep -q 'Mach-O 64-bit.*arm64' \
        || { printf 'cursor-products: libswift_Concurrency.dylib is not arm64 Mach-O\n' >&2; exit 1; }
fi

# .tbd projection needs the host ELF loader: gen_tbd.sh CHECK 1 requires
# every name in darwin/loader-exports.txt to be defined by build/machorun
# (libSystem.tbd = nm(libSystem.B.dylib) UNION loader-exports). Do not emit
# empty or unchecked .tbd files -- those are a lie ld64 will believe.
tbd_ok=0
if [ "$loader_ok" -eq 1 ] && [ -x "$machorun/build/machorun" ]; then
    sh "$machorun/scripts/build.sh" tbd
    tbd_ok=1
else
    note_unavailable "CURSOR_ENV_CANNOT_GENERATE_TBD host=$host reason=machorun/scripts/gen_tbd.sh CHECK 1 requires the host ELF loader at build/machorun so every name in darwin/loader-exports.txt is really defined by that binary (libSystem.tbd is nm(libSystem.B.dylib) UNION loader-exports). Emitting .tbd files without that check, or empty .tbd files, would lie to ld64. This VM stages the real arm64 Mach-O dylibs instead; ld64 can link against dylibs. Generate .tbd on the ARM64 EC2 authority where the loader compiles."
    rm -f "$machorun/sdk/usr/lib"/*.tbd
fi

for dylib in \
    "$machorun/darwin/usr/lib/libSystem.B.dylib" \
    "$machorun/darwin/usr/lib/libc++.1.dylib" \
    "$machorun/darwin/usr/lib/libc++abi.dylib" \
    "$machorun/darwin/usr/lib/libobjc.A.dylib" \
    "$machorun/darwin/usr/lib/libquartz.dylib" \
    "$machorun/darwin/usr/lib/libswiftcompat.dylib" \
    "$machorun/darwin/usr/lib/swift/libswiftCore.dylib"
do
    [ -f "$dylib" ] || { printf 'cursor-products: missing %s\n' "$dylib" >&2; exit 1; }
    file -b "$dylib" | grep -q 'Mach-O 64-bit.*arm64' \
        || { printf 'cursor-products: not arm64 Mach-O: %s\n' "$dylib" >&2; exit 1; }
done

# ---- sysroot_fe4: in-repo headers + real dylibs + Swift.swiftmodule. ----
# Xcode Darwin overlays (usr/lib/swift/*.swiftinterface for Darwin/Foundation
# etc.) and Apple apinotes cannot be produced on Linux. Stage what we can
# under the production name, and record the missing Xcode-derived pieces so
# verify does not treat the tree as a full FE sysroot. ld64 links against the
# arm64 Mach-O dylibs we just built; do not invent empty .tbd files.
echo "== sysroot_fe4 from in-repo machorun/sdk headers + darwin dylibs + swiftcore-macho modules"
sys=$scratch/sysroot_fe4
rm -rf "$sys"
mkdir -p "$sys/usr"
cp -R "$machorun/sdk/usr/include" "$sys/usr/include"
mkdir -p "$sys/usr/lib"
cp -a "$machorun/darwin/usr/lib/." "$sys/usr/lib/"
if [ "$tbd_ok" -eq 1 ] && [ -d "$machorun/sdk/usr/lib" ]; then
    find "$machorun/sdk/usr/lib" -maxdepth 1 -type f -name '*.tbd' -print0 \
        | while IFS= read -r -d '' tbd; do
            cp -f "$tbd" "$sys/usr/lib/$(basename "$tbd")"
        done
fi
mkdir -p "$sys/usr/lib/swift"
cp -R "$artifacts/swift-macosx/Swift.swiftmodule" "$sys/usr/lib/swift/"
if [ -d "$artifacts/concurrency/swift-macosx/_Concurrency.swiftmodule" ]; then
    cp -R "$artifacts/concurrency/swift-macosx/_Concurrency.swiftmodule" \
        "$sys/usr/lib/swift/"
fi

objc4=$machorun/vendor/objc4/runtime
for h in NSObject.h NSObjCRuntime.h Protocol.h; do
    cp "$objc4/$h" "$sys/usr/include/objc/$h"
done
cat > "$sys/usr/include/module.modulemap" <<'EOF'
module ObjectiveC [system] {
  header "objc/objc.h"
  header "objc/objc-api.h"
  header "objc/runtime.h"
  header "objc/message.h"
  export *
  module NSObject  { header "objc/NSObject.h"      export * }
  module Protocol  { header "objc/Protocol.h"      export * }
  module Runtime   { header "objc/NSObjCRuntime.h" export * }
}
EOF

if [ -f "$objc4/Module/ObjectiveC.apinotes" ]; then
    cp "$objc4/Module/ObjectiveC.apinotes" "$sys/usr/include/ObjectiveC.apinotes"
fi

bash "$repo_root/full/foundation/stage_objc_platform_headers.sh" "$sys/usr/include"

# sdk-gaps: copy only files that would not shadow machorun/sdk (same refuse
# rule as stage_fe_sysroot.sh). This is in-repo content, not Xcode.
gaps=$repo_root/full/sdk-gaps/usr/include
if [ -d "$gaps" ]; then
    while IFS= read -r -d '' gap; do
        rel=${gap#"$gaps"/}
        if [ -e "$sys/usr/include/$rel" ]; then
            printf '  skip shadowing sdk-gap %s (already in machorun/sdk)\n' "$rel"
            continue
        fi
        mkdir -p "$(dirname "$sys/usr/include/$rel")"
        cp "$gap" "$sys/usr/include/$rel"
        printf '  + sdk-gap %s\n' "$rel"
    done < <(find "$gaps" -type f -print0)
fi

note_unavailable "CURSOR_ENV_CANNOT_STAGE_XCODE_DARWIN_OVERLAYS host=$host reason=full/foundation/stage_fe_sysroot.sh and scripts/stage_darwin_swift.sh copy usr/lib/swift from an Xcode macOS SDK (textual Darwin/Foundation/*.swiftinterface plus Apple apinotes such as _DarwinFoundation2.apinotes). Those files are not redistributable and are not in this repo. Linux x86_64 can emit arm64 Mach-O and can stage machorun/sdk headers, the real darwin dylibs, and in-repo Swift.swiftmodule; it cannot materialize Apple's Darwin overlay interfaces. gen_darwin_modulemap.py is also macOS-only because it prunes Xcode modulemaps."

# ---- mrroot_full: darwin userland + swiftcore, no aarch64 loader ----
echo "== mrroot_full from in-repo darwin userland (no host loader on $host)"
mrroot=$scratch/mrroot_full
rm -rf "$mrroot"
mkdir -p "$mrroot/darwin/usr/lib/swift"
cp -a "$machorun/darwin/usr/lib/." "$mrroot/darwin/usr/lib/"
if [ "$loader_ok" -eq 1 ] && [ -x "$machorun/build/machorun" ]; then
    cp -f "$machorun/build/machorun" "$mrroot/machorun"
    chmod a+x "$mrroot/machorun"
else
    note_unavailable "CURSOR_ENV_CANNOT_STAGE_MRROOT_LOADER host=$host reason=scratch/mrroot_full/machorun is the host ELF loader. It is not an arm64 Mach-O and cannot be compiled on $host (see CURSOR_ENV_CANNOT_BUILD_LOADER). Darwin dylibs and libswiftCore are staged; execution-shaped gates must refuse with CURSOR_ENV_CANNOT_EXECUTE_ARM64 rather than exec a stub."
fi

note_unavailable "CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS host=$host reason=full/foundation/stage_swift_overlays.sh copies libswiftDarwin/libswift_StringProcessing and the rest of the overlay closure from an iOS CoreSimulator runtime on macOS. Those dylibs are not in this repo and are not cross-built here."

# ---- OpenCombine export artifacts: need arm64 execution + isolated fm-build ----
if [ ! -d "$scratch/opencombine-core-durable-20260828-r2/export" ]; then
    note_unavailable "CURSOR_ENV_CANNOT_BUILD_OPENCOMBINE_EXPORT host=$host reason=full/oracle-opencombine/build_and_run.sh compiles and RUNS the core under machorun inside a pinned fm-build container. This VM can clone the source pin (scratch/opencombine-core-durable-20260828-r2/source) but cannot produce export/artifacts without arm64 execution and that container isolation."
fi

# ---- modcache_swiftui_guest: created only by a real SwiftUI guest compile ----
# An empty cache would let a gate look populated. Do not create the directory.
if [ ! -d "$scratch/modcache_swiftui_guest" ]; then
    note_unavailable "CURSOR_ENV_CANNOT_BUILD_MODCACHE_SWIFTUI_GUEST host=$host reason=scratch/modcache_swiftui_guest is a swiftc module cache produced while compiling the Focus SwiftUI guests against a full sysroot_fe4 (Xcode Darwin overlays + FE). This VM cannot complete that compile without those overlays; leaving the path absent is the honest state."
fi

empty_tbd=$(find "$sys" -name '*.tbd' -size 0 -print -quit)
[ -z "$empty_tbd" ] \
    || { printf 'cursor-products: empty .tbd is a linker lie: %s\n' "$empty_tbd" >&2; exit 1; }
if [ "$tbd_ok" -eq 0 ]; then
    leftover_tbd=$(find "$sys" -name '*.tbd' -print -quit)
    [ -z "$leftover_tbd" ] \
        || { printf 'cursor-products: .tbd present without loader CHECK 1: %s\n' "$leftover_tbd" >&2; exit 1; }
fi

expected_markers=()
if [ "$host" != aarch64 ] && [ "$host" != arm64 ]; then
    expected_markers+=(
        CURSOR_ENV_CANNOT_BUILD_LOADER
        CURSOR_ENV_CANNOT_GENERATE_TBD
        CURSOR_ENV_CANNOT_STAGE_MRROOT_LOADER
    )
fi
expected_markers+=(
    CURSOR_ENV_CANNOT_STAGE_XCODE_DARWIN_OVERLAYS
    CURSOR_ENV_CANNOT_STAGE_SIMRUNTIME_OVERLAY_DYLIBS
)
[ -d "$scratch/opencombine-core-durable-20260828-r2/export" ] \
    || expected_markers+=(CURSOR_ENV_CANNOT_BUILD_OPENCOMBINE_EXPORT)
[ -d "$scratch/modcache_swiftui_guest" ] \
    || expected_markers+=(CURSOR_ENV_CANNOT_BUILD_MODCACHE_SWIFTUI_GUEST)

expected_count=${#expected_markers[@]}
logged_count=0
missing_expected=0
for marker in "${expected_markers[@]}"; do
    if grep -q "^$marker " "$unavailable"; then
        logged_count=$((logged_count + 1))
    else
        printf 'cursor-products: missing expected unavailable marker: %s\n' "$marker" >&2
        missing_expected=$((missing_expected + 1))
    fi
done
[ "$missing_expected" -eq 0 ] \
    || { printf 'cursor-products: expected unavailable markers %s/%s\n' \
        "$logged_count" "$expected_count" >&2; exit 1; }
total_logged=$(grep -c '^CURSOR_ENV_CANNOT_' "$unavailable" || true)

sys_hash=$(tree_digest "$sys")
mrroot_hash=$(tree_digest "$mrroot")
darwin_hash=$(tree_digest "$machorun/darwin/usr/lib")

python3 - "$manifest" "$host" "$loader_ok" "$tbd_ok" "$sys_hash" "$mrroot_hash" "$darwin_hash" \
    "$sys" "$mrroot" "$machorun" <<'PY'
import hashlib, json, os, sys
from pathlib import Path

manifest, host, loader_ok, tbd_ok, sys_hash, mrroot_hash, darwin_hash, sysroot, mrroot, machorun = sys.argv[1:]

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

files = {}
for label, path in [
    ("libSystem.B.dylib", Path(machorun) / "darwin/usr/lib/libSystem.B.dylib"),
    ("libc++.1.dylib", Path(machorun) / "darwin/usr/lib/libc++.1.dylib"),
    ("libobjc.A.dylib", Path(machorun) / "darwin/usr/lib/libobjc.A.dylib"),
    ("libquartz.dylib", Path(machorun) / "darwin/usr/lib/libquartz.dylib"),
    ("libswiftCore.dylib", Path(machorun) / "darwin/usr/lib/swift/libswiftCore.dylib"),
    ("libswiftcompat.dylib", Path(machorun) / "darwin/usr/lib/libswiftcompat.dylib"),
]:
    files[label] = {"path": str(path), "sha256": sha256(path), "bytes": path.stat().st_size}

payload = {
    "host": host,
    "loaderBuilt": loader_ok == "1",
    "tbdGenerated": tbd_ok == "1",
    "sysrootFe4TreeSha256": sys_hash,
    "mrrootFullTreeSha256": mrroot_hash,
    "darwinUserlandTreeSha256": darwin_hash,
    "sysrootFe4": sysroot,
    "mrrootFull": mrroot,
    "files": files,
}
Path(manifest).write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

printf 'CURSOR_BUILT_PRODUCTS_OK host=%s loader=%s tbd=%s sysroot_fe4=%s mrroot_full=%s darwin_dylibs=6/6\n' \
    "$host" "$loader_ok" "$tbd_ok" "$sys_hash" "$mrroot_hash"
printf 'CURSOR_UNAVAILABLE_COUNT expected=%s/%s logged=%s (see %s)\n' \
    "$logged_count" "$expected_count" "$total_logged" "$unavailable"
