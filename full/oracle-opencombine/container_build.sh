#!/bin/bash
# Run inside the pinned fm-build container. The host wrapper copies this
# directory, a detached OpenCombine checkout, and an attested runtime root into
# a brand-new /tmp subject before invoking us.
set -euo pipefail
export LC_ALL=C

OUT=${1:?usage: container_build.sh /tmp/opencombine-core.SUBJECT}
[[ "$OUT" =~ ^/tmp/opencombine-core\.[A-Za-z0-9._-]+$ ]] || {
    echo "REFUSED: container output must be one safe path segment matching /tmp/opencombine-core.*: $OUT" >&2
    exit 2
}

TOOL=$OUT/tooling
POLICY=$TOOL/policy.json
POLICY_TOOL=$TOOL/policy_tool.pl
SRC=$OUT/source
BASE_ROOT=$OUT/base-root
WORK=$OUT/work
AUDIT=$WORK/audit
LOGS=$WORK/logs
CORE=$WORK/core
HELPER=$WORK/helper
ORACLE=$WORK/oracle
PRODUCT=$WORK/product
RESULTS=$WORK/results
INPUTS=$WORK/inputs
EXPORT=$OUT/export

MACHORUN_BIN=${MACHORUN_BIN:?set MACHORUN_BIN to the pinned loader inside the container}
CONCURRENCY_MODULE_ROOT=${CONCURRENCY_MODULE_ROOT:?set CONCURRENCY_MODULE_ROOT to the source-built module root}
SWIFT_MODULE_ROOT=${SWIFT_MODULE_ROOT:-/work/swiftmodule}

for path in "$TOOL" "$POLICY" "$POLICY_TOOL" "$SRC/.git" "$BASE_ROOT"; do
    [ -e "$path" ] || { echo "REFUSED: required input is absent: $path" >&2; exit 2; }
done
if [ -e "$WORK" ] || [ -e "$EXPORT" ]; then
    echo "REFUSED: container subject already has work or export output: $OUT" >&2
    exit 2
fi
mkdir -p "$AUDIT" "$LOGS" "$CORE" "$HELPER" "$ORACLE" "$PRODUCT" "$RESULTS" "$INPUTS"

eval "$(perl "$POLICY_TOOL" env "$POLICY")"

say() { printf '%s\n' "$*"; }
section() { say ""; say "========== $*"; }
sha() { sha256sum "$1" | cut -d' ' -f1; }
require_hash() {
    local path=$1 want=$2 label=$3 got
    [ -f "$path" ] || { say "REFUSED: $label is absent: $path" >&2; exit 3; }
    got=$(sha "$path")
    [ "$got" = "$want" ] || {
        say "REFUSED: $label hash changed: expected $want, got $got ($path)" >&2
        exit 3
    }
    printf '  %-30s %s\n' "$label" "$got"
}
assert_contains() {
    local file=$1 needle=$2 label=$3
    grep -Fq -- "$needle" "$file" || {
        say "REFUSED: $label did not contain: $needle" >&2
        sed -n '1,160p' "$file" >&2
        exit 5
    }
}
assert_macho_noundefs() {
    local file=$1 kind=$2
    file "$file" | grep -Fq "Mach-O 64-bit arm64 $kind" || {
        say "REFUSED: not the expected arm64 Mach-O $kind: $file" >&2; file "$file" >&2; exit 5; }
    llvm-objdump-18 --macho --private-header "$file" | grep -Fq NOUNDEFS || {
        say "REFUSED: Mach-O lacks MH_NOUNDEFS: $file" >&2; exit 5; }
}
audit_dylibs() {
    local file=$1 audit_file=$2 label=$3
    shift 3
    local expected_file=$audit_file.expected
    llvm-objdump-18 --macho --all-headers "$file" > "$audit_file"
    printf '%s\n' "$@" > "$expected_file"
    perl "$POLICY_TOOL" verify-loads "$POLICY" "$audit_file" \
        "$expected_file" "$audit_file.records" > "$audit_file.verify.log" 2>&1 || {
            say "REFUSED: $label dependency/load-command audit failed" >&2
            if [ -f "$audit_file.verify.log" ]; then cat "$audit_file.verify.log" >&2; fi
            exit 5
        }
}
assert_same_file() {
    local left=$1 right=$2 label=$3
    cmp -s "$left" "$right" || {
        say "REFUSED: $label bytes disagree: $left vs $right" >&2
        exit 5
    }
    printf '  %-30s %s\n' "$label" "$(sha "$left")"
}
tree_manifest() {
    local root=$1 output=$2
    local unsorted=$output.paths.unsorted.nul
    local sorted=$output.paths.nul
    local symlinks=$output.symlinks.nul
    local nonregular=$output.nonregular.nul
    [ -d "$root" ] || { say "REFUSED: manifest root is absent: $root" >&2; exit 5; }
    (cd "$root" && find . -type l -print0) > "$symlinks"
    [ ! -s "$symlinks" ] || {
        say "REFUSED: manifest root contains a symlink: $root" >&2; exit 5; }
    (cd "$root" && find . ! -type d ! -type f ! -type l -print0) > "$nonregular"
    [ ! -s "$nonregular" ] || {
        say "REFUSED: manifest root contains a non-regular entry: $root" >&2; exit 5; }
    (cd "$root" && find . -type f -print0) > "$unsorted"
    sort -z "$unsorted" > "$sorted"
    : > "$output"
    while IFS= read -r -d '' rel; do
        printf '%s\0%s\0' "$(sha "$root/${rel#./}")" "${rel#./}" >> "$output"
    done < "$sorted"
    rm -- "$unsorted" "$sorted" "$symlinks" "$nonregular"
}

section "policy, source, runtime, and toolchain inputs"
perl "$POLICY_TOOL" assets "$POLICY" "$TOOL"
perl "$POLICY_TOOL" runtime "$POLICY" "$BASE_ROOT"
perl "$POLICY_TOOL" attest "$POLICY" "$SRC" \
    "$AUDIT/core-sources.before.nul" "$AUDIT/core-sources.before.json" \
    | tee "$LOGS/source-before.log"

[ "$(swiftc --version | sed -n '1p')" = "$OC_SWIFT_VERSION" ] || {
    say "REFUSED: swiftc version changed" >&2; swiftc --version >&2; exit 3; }
[ "$(clang++-18 --version | sed -n '1p')" = "$OC_CLANG_VERSION" ] || {
    say "REFUSED: clang version changed" >&2; clang++-18 --version >&2; exit 3; }
[ "$(ld64.lld-18 --version | sed -n '1p')" = "$OC_LLD_VERSION" ] || {
    say "REFUSED: ld64.lld version changed" >&2; ld64.lld-18 --version >&2; exit 3; }
[ -d "$OC_SDK" ] || { say "REFUSED: SDK is absent: $OC_SDK" >&2; exit 3; }

require_hash "$(command -v swiftc)" "$OC_SWIFTC_SHA" "swiftc executable"
require_hash "$(command -v clang++-18)" "$OC_CLANGXX_SHA" "clang++ executable"
require_hash "$(command -v ld64.lld-18)" "$OC_LLD_SHA" "ld64.lld executable"
require_hash "$(command -v llvm-objdump-18)" "$OC_OBJDUMP_SHA" "llvm-objdump executable"
require_hash "$(command -v llvm-nm-18)" "$OC_NM_SHA" "llvm-nm executable"

require_hash "$SWIFT_MODULE_ROOT/$OC_SWIFT_MODULE_REL" "$OC_SWIFT_MODULE_SHA" "source-built Swift module"
require_hash "$CONCURRENCY_MODULE_ROOT/$OC_CONCURRENCY_MODULE_REL" "$OC_CONCURRENCY_MODULE_SHA" "source-built Concurrency module"
require_hash "$MACHORUN_BIN" "$OC_MACHORUN_SHA" "machorun loader"
require_hash /work/fe/sysroot/usr/lib/libSystem.B.tbd \
    "$OC_LINK_SHA_work_fe_sysroot_usr_lib_libSystem_B_tbd" "libSystem link tbd"
require_hash /work/fe/sysroot/usr/lib/swift/libswift_Concurrency.tbd \
    "$OC_LINK_SHA_work_fe_sysroot_usr_lib_swift_libswift_Concurrency_tbd" "Concurrency link tbd"
require_hash /work/lib/libc++abi.dylib \
    "$OC_LINK_SHA_work_lib_libc__abi_dylib" "libc++abi link/runtime"
require_hash /work/lib/libobjc.A.dylib \
    "$OC_LINK_SHA_work_lib_libobjc_A_dylib" "libobjc link/runtime"
require_hash /work/lib/libswiftCore.dylib \
    "$OC_LINK_SHA_work_lib_libswiftCore_dylib" "swiftCore link/runtime"
require_hash /work/lib/libswiftcompat.dylib \
    "$OC_LINK_SHA_work_lib_libswiftcompat_dylib" "swiftcompat link/runtime"
require_hash "$OC_DISPATCH_DYLIB" "$OC_DISPATCH_SHA" "preserved libdispatch"
require_hash "$OC_DISPATCH_TBD" "$OC_DISPATCH_TBD_SHA" "libswiftDispatch tbd"
DISPATCH_BEFORE=$(sha "$OC_DISPATCH_DYLIB")

assert_same_file /work/lib/libc++abi.dylib \
    "$BASE_ROOT/darwin/usr/lib/libc++abi.dylib" "libc++abi link/runtime agreement"
assert_same_file /work/lib/libobjc.A.dylib \
    "$BASE_ROOT/darwin/usr/lib/libobjc.A.dylib" "libobjc link/runtime agreement"
assert_same_file /work/lib/libswiftCore.dylib \
    "$BASE_ROOT/darwin/usr/lib/swift/libswiftCore.dylib" "swiftCore link/runtime agreement"
assert_same_file /work/lib/libswiftcompat.dylib \
    "$BASE_ROOT/darwin/usr/lib/libswiftcompat.dylib" "swiftcompat link/runtime agreement"

section "attest and isolate every SDK/module compiler search root"
PINNED_SDK=$OC_SDK
perl "$POLICY_TOOL" tree "$POLICY" sdk "$PINNED_SDK" \
    "$AUDIT/sdk.original.before.nul" "$AUDIT/sdk.original.before.json"
perl "$POLICY_TOOL" tree "$POLICY" swift_module \
    "$SWIFT_MODULE_ROOT/$OC_SWIFT_MODULE_BUNDLE_REL" \
    "$AUDIT/swift-module.original.before.nul" "$AUDIT/swift-module.original.before.json"
perl "$POLICY_TOOL" tree "$POLICY" concurrency_module \
    "$CONCURRENCY_MODULE_ROOT/$OC_CONCURRENCY_MODULE_BUNDLE_REL" \
    "$AUDIT/concurrency-module.original.before.nul" "$AUDIT/concurrency-module.original.before.json"
perl "$POLICY_TOOL" dispatch "$POLICY" /work "$AUDIT/dispatch-original.before.json" \
    | tee "$LOGS/dispatch-original-before.log"

SDK=$INPUTS/MacOSX.sdk
SWIFT_INPUT_ROOT=$INPUTS/swift
CONCURRENCY_INPUT_ROOT=$INPUTS/concurrency
DISPATCH_WORK=$INPUTS/dispatch-work
DISPATCH_MODULE_PARENT=$DISPATCH_WORK/fe/sysroot/usr/lib/swift
mkdir -p "$SWIFT_INPUT_ROOT" "$CONCURRENCY_INPUT_ROOT" "$DISPATCH_MODULE_PARENT"
cp -a -- "$PINNED_SDK" "$SDK"
cp -a -- "$SWIFT_MODULE_ROOT/$OC_SWIFT_MODULE_BUNDLE_REL" "$SWIFT_INPUT_ROOT/"
cp -a -- "$CONCURRENCY_MODULE_ROOT/$OC_CONCURRENCY_MODULE_BUNDLE_REL" \
    "$CONCURRENCY_INPUT_ROOT/"
cp -a -- /work/fe/sysroot/usr/lib/swift/Dispatch.swiftmodule \
    "$DISPATCH_MODULE_PARENT/"

perl "$POLICY_TOOL" tree "$POLICY" sdk "$SDK" \
    "$AUDIT/sdk.isolated.before.nul" "$AUDIT/sdk.isolated.before.json"
perl "$POLICY_TOOL" tree "$POLICY" swift_module \
    "$SWIFT_INPUT_ROOT/$OC_SWIFT_MODULE_BUNDLE_REL" \
    "$AUDIT/swift-module.isolated.before.nul" "$AUDIT/swift-module.isolated.before.json"
perl "$POLICY_TOOL" tree "$POLICY" concurrency_module \
    "$CONCURRENCY_INPUT_ROOT/$OC_CONCURRENCY_MODULE_BUNDLE_REL" \
    "$AUDIT/concurrency-module.isolated.before.nul" "$AUDIT/concurrency-module.isolated.before.json"
perl "$POLICY_TOOL" dispatch "$POLICY" "$DISPATCH_WORK" \
    "$AUDIT/dispatch-isolated.before.json" | tee "$LOGS/dispatch-isolated-before.log"
for subject in sdk swift-module concurrency-module; do
    cmp -s "$AUDIT/$subject.original.before.nul" \
           "$AUDIT/$subject.isolated.before.nul" || {
        say "REFUSED: isolated $subject bytes/inventory disagree with source" >&2
        exit 4
    }
done
cmp -s "$AUDIT/dispatch-original.before.json" \
       "$AUDIT/dispatch-isolated.before.json" || {
    say "REFUSED: isolated Dispatch bundle disagrees with inventoried source" >&2
    exit 4
}
say "  compiler roots: isolated exact SDK plus Swift/_Concurrency bundles only"

swiftc -typecheck -target "$OC_TARGET" -sdk "$SDK" \
    -I "$SWIFT_INPUT_ROOT" -I "$CONCURRENCY_INPUT_ROOT" \
    -module-cache-path "$WORK/modcache-shadow-probe" \
    "$TOOL/oracles/module-shadow-probe.swift" \
    > "$LOGS/module-shadow-probe.stdout" 2> "$LOGS/module-shadow-probe.stderr"
[ "$(awk '/error:/ { count++ } END { print count + 0 }' \
    "$LOGS/module-shadow-probe.stderr")" -eq 0 ] || {
    say "REFUSED: isolated roots expose a Combine/OpenCombine shadow" >&2
    exit 4
}

mapfile -d '' CORE_SOURCES < "$AUDIT/core-sources.before.nul"
[ "${#CORE_SOURCES[@]}" -eq "$OC_CORE_COUNT" ] || {
    say "REFUSED: NUL source-list denominator is ${#CORE_SOURCES[@]}, expected $OC_CORE_COUNT" >&2
    exit 4
}
say "  compiler source array: ${#CORE_SOURCES[@]} NUL-delimited paths"

section "exact helper patch and C++ objects"
cp "$SRC/$OC_HELPER_REL" "$HELPER/COpenCombineHelpers.original.cpp"
cp "$SRC/$OC_HELPER_REL" "$HELPER/COpenCombineHelpers.cpp"
require_hash "$HELPER/COpenCombineHelpers.original.cpp" "$OC_HELPER_UPSTREAM_SHA" "upstream helper copy"
patch --batch --forward --fuzz=0 "$HELPER/COpenCombineHelpers.cpp" \
    "$TOOL/$OC_HELPER_PATCH_REL" > "$LOGS/helper-patch.log"
require_hash "$HELPER/COpenCombineHelpers.cpp" "$OC_HELPER_PATCHED_SHA" "patched helper copy"

HELPER_INCLUDE=$SRC/Sources/COpenCombineHelpers/include
for variant in original patched; do
    if [ "$variant" = original ]; then input=$HELPER/COpenCombineHelpers.original.cpp; else input=$HELPER/COpenCombineHelpers.cpp; fi
    clang++-18 -target "$OC_TARGET" -isysroot "$SDK" \
        -stdlib=libc++ -std=c++17 -O2 -I "$HELPER_INCLUDE" \
        -c "$input" -o "$HELPER/COpenCombineHelpers.$variant.o" \
        > "$LOGS/helper-$variant.stdout" 2> "$LOGS/helper-$variant.stderr"
done
require_hash "$HELPER/COpenCombineHelpers.patched.o" \
    "$OC_HELPER_OBJECT_SHA" \
    "patched helper object"
llvm-nm-18 -u "$HELPER/COpenCombineHelpers.original.o" > "$AUDIT/helper-original.undefined"
llvm-nm-18 -u "$HELPER/COpenCombineHelpers.patched.o" > "$AUDIT/helper-patched.undefined"
[ "$(awk '/recursive_mutex/ { count++ } END { print count + 0 }' \
    "$AUDIT/helper-original.undefined")" -eq 4 ] || {
    say "REFUSED: upstream helper no longer has exactly four recursive_mutex imports" >&2; exit 4; }
[ "$(awk '/recursive_mutex|system_error|system_category/ { count++ } END { print count + 0 }' \
    "$AUDIT/helper-patched.undefined")" -eq 0 ] || {
    say "REFUSED: patched helper retained forbidden libc++ lock/error imports" >&2; exit 4; }

section "103-source core typecheck and module/object emission"
COMMON_SWIFT=(
    -parse-as-library -O -wmo
    -target "$OC_TARGET" -sdk "$SDK"
    -I "$SWIFT_INPUT_ROOT" -I "$CONCURRENCY_INPUT_ROOT"
    -Xfrontend -disable-implicit-string-processing-module-import
    -Xcc -fmodule-map-file="$HELPER_INCLUDE/module.modulemap"
    -Xcc -I"$HELPER_INCLUDE"
    -module-name OpenCombine
)
swiftc -typecheck "${COMMON_SWIFT[@]}" \
    -module-cache-path "$CORE/modcache-typecheck" "${CORE_SOURCES[@]}" \
    > "$LOGS/core-typecheck.stdout" 2> "$LOGS/core-typecheck.stderr"
swiftc -emit-module -emit-module-path "$CORE/OpenCombine.swiftmodule" \
    -emit-object -o "$CORE/OpenCombine.o" "${COMMON_SWIFT[@]}" \
    -module-cache-path "$CORE/modcache-emit" "${CORE_SOURCES[@]}" \
    > "$LOGS/core-emit.stdout" 2> "$LOGS/core-emit.stderr"
[ "$(awk '/error:/ { count++ } END { print count + 0 }' \
    "$LOGS/core-typecheck.stderr")" -eq 0 ] || {
    say "REFUSED: core typecheck emitted an error diagnostic" >&2; exit 5; }
[ "$(awk '/error:/ { count++ } END { print count + 0 }' \
    "$LOGS/core-emit.stderr")" -eq 0 ] || {
    say "REFUSED: core emit emitted an error diagnostic" >&2; exit 5; }
file "$CORE/OpenCombine.o" | grep -Fq 'Mach-O 64-bit arm64 object' || {
    say "REFUSED: core object is not arm64 Mach-O" >&2; exit 5; }

section "negative original-helper link, then strict patched link"
set +e
ld64.lld-18 -dylib -arch arm64 -platform_version macos 13.0 13.0 \
    -install_name /usr/lib/swift/libOpenCombine-original-helper.dylib \
    -rpath /usr/lib/swift -ignore_auto_link -dead_strip \
    -o "$PRODUCT/libOpenCombine-original-helper.dylib" \
    "$CORE/OpenCombine.o" "$HELPER/COpenCombineHelpers.original.o" \
    /work/fe/sysroot/usr/lib/swift/libswift_Concurrency.tbd \
    /work/lib/libswiftCore.dylib /work/lib/libc++abi.dylib \
    /work/fe/sysroot/usr/lib/libSystem.B.tbd /work/lib/libobjc.A.dylib \
    > "$LOGS/original-helper-link.stdout" 2> "$LOGS/original-helper-link.stderr"
ORIGINAL_LINK_RC=$?
set -e
[ "$ORIGINAL_LINK_RC" -ne 0 ] && [ ! -e "$PRODUCT/libOpenCombine-original-helper.dylib" ] || {
    say "REFUSED: unpatched helper unexpectedly linked" >&2; exit 5; }
for symbol in recursive_mutexC1Ev recursive_mutex4lockEv recursive_mutex6unlockEv recursive_mutexD1Ev; do
    assert_contains "$LOGS/original-helper-link.stderr" "$symbol" "unpatched helper negative link"
done
say "  original helper refused by strict link (rc=$ORIGINAL_LINK_RC; all four imports observed)"

ld64.lld-18 -dylib -arch arm64 -platform_version macos 13.0 13.0 \
    -install_name /usr/lib/swift/libOpenCombine.dylib \
    -rpath /usr/lib/swift -ignore_auto_link -dead_strip \
    -o "$PRODUCT/libOpenCombine.dylib" \
    "$CORE/OpenCombine.o" "$HELPER/COpenCombineHelpers.patched.o" \
    /work/fe/sysroot/usr/lib/swift/libswift_Concurrency.tbd \
    /work/lib/libswiftCore.dylib /work/lib/libc++abi.dylib \
    /work/fe/sysroot/usr/lib/libSystem.B.tbd /work/lib/libobjc.A.dylib \
    > "$LOGS/opencombine-link.stdout" 2> "$LOGS/opencombine-link.stderr"
assert_macho_noundefs "$PRODUCT/libOpenCombine.dylib" 'dynamically linked shared library'
llvm-objdump-18 --macho --all-headers "$PRODUCT/libOpenCombine.dylib" \
    > "$AUDIT/libOpenCombine.headers"
assert_contains "$AUDIT/libOpenCombine.headers" 'name /usr/lib/swift/libOpenCombine.dylib' 'OpenCombine LC_ID_DYLIB'
audit_dylibs "$PRODUCT/libOpenCombine.dylib" "$AUDIT/libOpenCombine.dylibs" \
    'OpenCombine' \
    $'LC_ID_DYLIB\t/usr/lib/swift/libOpenCombine.dylib\t0.0.0\t0.0.0' \
    $'LC_LOAD_DYLIB\t/usr/lib/swift/libswift_Concurrency.dylib\t1.0.0\t0.0.0' \
    $'LC_LOAD_DYLIB\t/usr/lib/swift/libswiftCore.dylib\t1.0.0\t1.0.0' \
    $'LC_LOAD_DYLIB\t/usr/lib/libc++abi.dylib\t0.0.0\t0.0.0' \
    $'LC_LOAD_DYLIB\t/usr/lib/libSystem.B.dylib\t1.0.0\t1.0.0' \
    $'LC_LOAD_DYLIB\t/usr/lib/libobjc.A.dylib\t0.0.0\t0.0.0'
llvm-nm-18 -u "$PRODUCT/libOpenCombine.dylib" > "$AUDIT/libOpenCombine.undefined"

llvm-objdump-18 --macho --bind "$PRODUCT/libOpenCombine.dylib" \
    > "$AUDIT/libOpenCombine.bind.raw"
llvm-objdump-18 --macho --lazy-bind "$PRODUCT/libOpenCombine.dylib" \
    > "$AUDIT/libOpenCombine.lazy-bind.raw"
llvm-objdump-18 --macho --weak-bind "$PRODUCT/libOpenCombine.dylib" \
    > "$AUDIT/libOpenCombine.weak-bind.raw"
awk '$6 == "libswift_Concurrency" { print $7 }' \
    "$AUDIT/libOpenCombine.bind.raw" | sort -u \
    > "$AUDIT/concurrency-regular-binds.txt"
awk '$4 == "libswift_Concurrency" { print $5 }' \
    "$AUDIT/libOpenCombine.lazy-bind.raw" | sort -u \
    > "$AUDIT/concurrency-lazy-binds.txt"
awk '$1 ~ /^__/ && $2 ~ /^__/ { print $NF }' \
    "$AUDIT/libOpenCombine.weak-bind.raw" | sort -u \
    > "$AUDIT/weak-binds.txt"
sort -u "$AUDIT/concurrency-regular-binds.txt" \
    "$AUDIT/concurrency-lazy-binds.txt" > "$AUDIT/concurrency-binds.txt"
comm -12 "$AUDIT/concurrency-regular-binds.txt" \
    "$AUDIT/concurrency-lazy-binds.txt" > "$AUDIT/concurrency-bind-overlap.txt"
[ "$(wc -l < "$AUDIT/concurrency-regular-binds.txt")" -eq 14 ] || {
    say "REFUSED: Concurrency regular-bind denominator changed" >&2; exit 5; }
[ "$(wc -l < "$AUDIT/concurrency-lazy-binds.txt")" -eq 14 ] || {
    say "REFUSED: Concurrency lazy-bind denominator changed" >&2; exit 5; }
[ "$(wc -l < "$AUDIT/concurrency-binds.txt")" -eq 28 ] || {
    say "REFUSED: Concurrency unique regular+lazy bind denominator changed" >&2; exit 5; }
[ ! -s "$AUDIT/concurrency-bind-overlap.txt" ] || {
    say "REFUSED: Concurrency regular/lazy bind sets unexpectedly overlap" >&2; exit 5; }
[ "$(wc -l < "$AUDIT/weak-binds.txt")" -eq 2 ] || {
    say "REFUSED: weak-bind denominator changed" >&2; exit 5; }

CONCURRENCY_RUNTIME=$BASE_ROOT/darwin/usr/lib/swift/libswift_Concurrency.dylib
llvm-nm-18 -gj --defined-only "$CONCURRENCY_RUNTIME" \
    > "$AUDIT/concurrency-defined-exports.txt" \
    2> "$LOGS/concurrency-provider-nm.stderr"
[ ! -s "$LOGS/concurrency-provider-nm.stderr" ] || {
    say "REFUSED: llvm-nm emitted Concurrency provider diagnostics" >&2
    cat "$LOGS/concurrency-provider-nm.stderr" >&2
    exit 5
}
sort -u "$AUDIT/concurrency-defined-exports.txt" \
    -o "$AUDIT/concurrency-defined-exports.txt"
comm -23 "$AUDIT/concurrency-binds.txt" \
    "$AUDIT/concurrency-defined-exports.txt" > "$AUDIT/concurrency-missing.txt"
[ ! -s "$AUDIT/concurrency-missing.txt" ] || {
    say "REFUSED: actual Concurrency runtime misses linked symbols" >&2; exit 5; }
awk '{ print $0 "\tdarwin/usr/lib/swift/libswift_Concurrency.dylib" }' \
    "$AUDIT/concurrency-binds.txt" > "$AUDIT/concurrency-defined-providers.tsv"

find "$BASE_ROOT" -type f -name '*.dylib' -print0 | sort -z \
    > "$AUDIT/runtime-dylibs.nul"
mapfile -d '' RUNTIME_DYLIBS < "$AUDIT/runtime-dylibs.nul"
[ "${#RUNTIME_DYLIBS[@]}" -gt 0 ] || {
    say "REFUSED: runtime provider census found no dylibs" >&2; exit 5; }
: > "$AUDIT/runtime-defined-exports.unsorted.txt"
: > "$AUDIT/runtime-defined-providers.unsorted.tsv"
: > "$LOGS/runtime-provider-nm.stderr"
for dylib in "${RUNTIME_DYLIBS[@]}"; do
    provider=${dylib#"$BASE_ROOT"/}
    nm_output=$AUDIT/runtime-provider.nm.tmp
    if ! llvm-nm-18 -gj --defined-only "$dylib" > "$nm_output" \
        2>> "$LOGS/runtime-provider-nm.stderr"; then
        say "REFUSED: llvm-nm failed for runtime provider: $dylib" >&2
        tail -80 "$LOGS/runtime-provider-nm.stderr" >&2
        exit 5
    fi
    awk 'length($0) == 0 || index($0, "\t") { exit 1 }' "$nm_output" || {
        say "REFUSED: malformed defined-symbol output for runtime provider: $dylib" >&2
        exit 5
    }
    cat "$nm_output" >> "$AUDIT/runtime-defined-exports.unsorted.txt"
    awk -v provider="$provider" '{ print $0 "\t" provider }' "$nm_output" \
        >> "$AUDIT/runtime-defined-providers.unsorted.tsv"
done
rm -- "$AUDIT/runtime-provider.nm.tmp"
sort -u "$AUDIT/runtime-defined-exports.unsorted.txt" \
    > "$AUDIT/runtime-defined-exports.txt"
sort -u "$AUDIT/runtime-defined-providers.unsorted.tsv" \
    > "$AUDIT/runtime-defined-providers.tsv"
[ ! -s "$LOGS/runtime-provider-nm.stderr" ] || {
    say "REFUSED: llvm-nm emitted runtime-provider diagnostics" >&2
    cat "$LOGS/runtime-provider-nm.stderr" >&2
    exit 5
}
sort -u "$AUDIT/helper-patched.undefined" > "$AUDIT/helper-patched.undefined.sorted"
comm -23 "$AUDIT/helper-patched.undefined.sorted" \
    "$AUDIT/runtime-defined-exports.txt" > "$AUDIT/helper-provider-missing.txt"
comm -23 "$AUDIT/weak-binds.txt" "$AUDIT/runtime-defined-exports.txt" \
    > "$AUDIT/weak-bind-provider-missing.txt"
awk -F '\t' 'NR == FNR { wanted[$1] = 1; next }
    ($1 in wanted) { print }' "$AUDIT/helper-patched.undefined.sorted" \
    "$AUDIT/runtime-defined-providers.tsv" > "$AUDIT/helper-defined-providers.tsv"
awk -F '\t' 'NR == FNR { wanted[$1] = 1; next }
    ($1 in wanted) { print }' "$AUDIT/weak-binds.txt" \
    "$AUDIT/runtime-defined-providers.tsv" > "$AUDIT/weak-bind-defined-providers.tsv"
[ "$(wc -l < "$AUDIT/helper-patched.undefined.sorted")" -eq 21 ] || {
    say "REFUSED: patched helper undefined denominator changed" >&2; exit 5; }
[ ! -s "$AUDIT/helper-provider-missing.txt" ] || {
    say "REFUSED: runtime root cannot define every helper import" >&2; exit 5; }
[ ! -s "$AUDIT/weak-bind-provider-missing.txt" ] || {
    say "REFUSED: runtime root cannot define every weak-bind symbol" >&2; exit 5; }

section "Combine compatibility re-export shim"
swiftc -emit-module -emit-module-path "$PRODUCT/Combine.swiftmodule" \
    -emit-object -o "$ORACLE/Combine.o" -parse-as-library -O -wmo \
    -target "$OC_TARGET" -sdk "$SDK" \
    -I "$SWIFT_INPUT_ROOT" -I "$CONCURRENCY_INPUT_ROOT" -I "$CORE" \
    -module-cache-path "$ORACLE/modcache-combine" \
    -Xfrontend -disable-implicit-string-processing-module-import \
    -Xcc -fmodule-map-file="$HELPER_INCLUDE/module.modulemap" -Xcc -I"$HELPER_INCLUDE" \
    -module-name Combine "$TOOL/Combine.swift" \
    > "$LOGS/combine-compile.stdout" 2> "$LOGS/combine-compile.stderr"
ld64.lld-18 -dylib -arch arm64 -platform_version macos 13.0 13.0 \
    -install_name /usr/lib/swift/libCombine.dylib \
    -ignore_auto_link -dead_strip \
    -reexport_library "$PRODUCT/libOpenCombine.dylib" \
    -o "$PRODUCT/libCombine.dylib" "$ORACLE/Combine.o" \
    /work/lib/libswiftCore.dylib /work/fe/sysroot/usr/lib/libSystem.B.tbd \
    > "$LOGS/combine-link.stdout" 2> "$LOGS/combine-link.stderr"
assert_macho_noundefs "$PRODUCT/libCombine.dylib" 'dynamically linked shared library'
llvm-objdump-18 --macho --all-headers "$PRODUCT/libCombine.dylib" \
    > "$AUDIT/libCombine.headers"
assert_contains "$AUDIT/libCombine.headers" 'name /usr/lib/swift/libCombine.dylib' 'Combine LC_ID_DYLIB'
grep -A5 'cmd LC_REEXPORT_DYLIB' "$AUDIT/libCombine.headers" \
    > "$AUDIT/libCombine.reexports"
assert_contains "$AUDIT/libCombine.reexports" 'name /usr/lib/swift/libOpenCombine.dylib' 'Combine re-export'
audit_dylibs "$PRODUCT/libCombine.dylib" "$AUDIT/libCombine.dylibs" \
    'Combine' \
    $'LC_ID_DYLIB\t/usr/lib/swift/libCombine.dylib\t0.0.0\t0.0.0' \
    $'LC_LOAD_DYLIB\t/usr/lib/swift/libOpenCombine.dylib\t0.0.0\t0.0.0' \
    $'LC_REEXPORT_DYLIB\t/usr/lib/swift/libOpenCombine.dylib\t0.0.0\t0.0.0' \
    $'LC_LOAD_DYLIB\t/usr/lib/swift/libswiftCore.dylib\t1.0.0\t1.0.0' \
    $'LC_LOAD_DYLIB\t/usr/lib/libSystem.B.dylib\t1.0.0\t1.0.0'
llvm-nm-18 -u "$PRODUCT/libCombine.dylib" > "$AUDIT/libCombine.undefined"

section "derive, compile, and strict-link all oracle controls"
cp "$TOOL/oracles/published_oracle.swift" "$ORACLE/published_oracle.generated.swift"
patch --batch --forward --fuzz=0 "$ORACLE/published_oracle.generated.swift" \
    "$TOOL/oracles/oracle-mutation.patch" > "$LOGS/oracle-mutation-patch.log"
cmp -s "$ORACLE/published_oracle.generated.swift" "$TOOL/oracles/published_oracle_mutated.swift" || {
    say "REFUSED: mutation patch no longer derives the recorded mutant" >&2; exit 4; }

compile_oracle() {
    local name=$1 source=$2
    local object=$ORACLE/$name.o
    swiftc -emit-object -o "$object" -O -wmo \
        -target "$OC_TARGET" -sdk "$SDK" \
        -I "$SWIFT_INPUT_ROOT" -I "$CONCURRENCY_INPUT_ROOT" -I "$CORE" -I "$PRODUCT" \
        -module-cache-path "$ORACLE/modcache-$name" \
        -Xfrontend -disable-implicit-string-processing-module-import \
        -Xcc -fmodule-map-file="$HELPER_INCLUDE/module.modulemap" -Xcc -I"$HELPER_INCLUDE" \
        -module-name "$name" "$source" \
        > "$LOGS/$name-compile.stdout" 2> "$LOGS/$name-compile.stderr"
    ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0 \
        -e _main -rpath /usr/lib/swift -ignore_auto_link -dead_strip -dead_strip_dylibs \
        -L "$PRODUCT" -o "$PRODUCT/$name" "$object" \
        -lCombine /work/lib/libswiftCore.dylib \
        -needed_library /work/lib/libswiftcompat.dylib \
        /work/lib/libobjc.A.dylib /work/fe/sysroot/usr/lib/libSystem.B.tbd \
        > "$LOGS/$name-link.stdout" 2> "$LOGS/$name-link.stderr"
    assert_macho_noundefs "$PRODUCT/$name" executable
    audit_dylibs "$PRODUCT/$name" "$AUDIT/$name.dylibs" "$name" \
        $'LC_LOAD_DYLIB\t/usr/lib/swift/libCombine.dylib\t0.0.0\t0.0.0' \
        $'LC_LOAD_DYLIB\t/usr/lib/swift/libswiftCore.dylib\t1.0.0\t1.0.0' \
        $'LC_LOAD_DYLIB\t/usr/lib/libswiftcompat.dylib\t1.0.0\t1.0.0' \
        $'LC_LOAD_DYLIB\t/usr/lib/libobjc.A.dylib\t0.0.0\t0.0.0' \
        $'LC_LOAD_DYLIB\t/usr/lib/libSystem.B.dylib\t1.0.0\t1.0.0'
    llvm-nm-18 -u "$PRODUCT/$name" > "$AUDIT/$name.undefined"
}
compile_oracle PublishedOracle_positive "$TOOL/oracles/published_oracle.swift"
compile_oracle PublishedOracle_mutated "$ORACLE/published_oracle.generated.swift"
compile_oracle PublishedOracle_reentrant "$TOOL/oracles/published_oracle_reentrant.swift"

section "measured OpenCombineDispatch boundary"
set +e
swiftc -typecheck -target "$OC_TARGET" -sdk "$SDK" \
    -I "$SWIFT_INPUT_ROOT" -I "$CONCURRENCY_INPUT_ROOT" -I "$CORE" \
    -I "$PRODUCT" -I "$HELPER_INCLUDE" -I "$DISPATCH_MODULE_PARENT" \
    -module-cache-path "$WORK/modcache-dispatch-boundary" \
    -Xfrontend -disable-implicit-string-processing-module-import \
    -Xcc -fmodule-map-file="$HELPER_INCLUDE/module.modulemap" -Xcc -I"$HELPER_INCLUDE" \
    -module-name OpenCombineDispatch \
    "$SRC/Sources/OpenCombineDispatch/DispatchQueue+Scheduler.swift" \
    > "$LOGS/opencombine-dispatch.stdout" 2> "$LOGS/opencombine-dispatch.stderr"
DISPATCH_RC=$?
set -e
[ "$DISPATCH_RC" -eq "$OC_DISPATCH_FAILURE_EXIT" ] || {
    say "REFUSED: OpenCombineDispatch exited $DISPATCH_RC, expected $OC_DISPATCH_FAILURE_EXIT" >&2
    exit 6
}
perl "$POLICY_TOOL" normalize-dispatch-errors "$POLICY" \
    "$LOGS/opencombine-dispatch.stderr" "$OUT" \
    "$AUDIT/dispatch-error-headlines.actual" \
    > "$LOGS/dispatch-error-normalization.log"
{
    for ((i = 0; i < OC_DISPATCH_INTERFACE_ERROR_COUNT; i++)); do
        printf '%s\n' "$OC_DISPATCH_INTERFACE_ERROR_LINE"
        if [ "$i" -eq 0 ]; then printf '%s\n' "$OC_DISPATCH_SOURCE_ERROR_LINE"; fi
    done
} > "$AUDIT/dispatch-error-headlines.expected"
cmp -s "$AUDIT/dispatch-error-headlines.expected" \
       "$AUDIT/dispatch-error-headlines.actual" || {
    say "REFUSED: OpenCombineDispatch exact normalized error headlines changed" >&2
    diff -u "$AUDIT/dispatch-error-headlines.expected" \
        "$AUDIT/dispatch-error-headlines.actual" >&2 || exit 6
    exit 6
}
perl "$POLICY_TOOL" dispatch "$POLICY" /work "$AUDIT/dispatch-original.after.json" \
    | tee "$LOGS/dispatch-original-after.log"
perl "$POLICY_TOOL" dispatch "$POLICY" "$DISPATCH_WORK" \
    "$AUDIT/dispatch-isolated.after.json" | tee "$LOGS/dispatch-isolated-after.log"
cmp -s "$AUDIT/dispatch-original.before.json" \
       "$AUDIT/dispatch-original.after.json" || {
    say "REFUSED: original Dispatch inventory changed across the boundary probe" >&2
    exit 4
}
cmp -s "$AUDIT/dispatch-isolated.before.json" \
       "$AUDIT/dispatch-isolated.after.json" || {
    say "REFUSED: isolated Dispatch inventory changed across the boundary probe" >&2
    exit 4
}
require_hash "$OC_DISPATCH_DYLIB" "$DISPATCH_BEFORE" "preserved libdispatch after build"

perl "$POLICY_TOOL" attest "$POLICY" "$SRC" \
    "$AUDIT/core-sources.after.nul" "$AUDIT/core-sources.after.json" \
    | tee "$LOGS/source-after.log"
cmp -s "$AUDIT/core-sources.before.nul" "$AUDIT/core-sources.after.nul" || {
    say "REFUSED: compiler source list changed during the build" >&2; exit 4; }
cmp -s "$AUDIT/core-sources.before.json" "$AUDIT/core-sources.after.json" || {
    say "REFUSED: compiler input attestation changed during the build" >&2; exit 4; }
perl "$POLICY_TOOL" tree "$POLICY" sdk "$PINNED_SDK" \
    "$AUDIT/sdk.original.after.nul" "$AUDIT/sdk.original.after.json"
perl "$POLICY_TOOL" tree "$POLICY" sdk "$SDK" \
    "$AUDIT/sdk.isolated.after.nul" "$AUDIT/sdk.isolated.after.json"
perl "$POLICY_TOOL" tree "$POLICY" swift_module \
    "$SWIFT_MODULE_ROOT/$OC_SWIFT_MODULE_BUNDLE_REL" \
    "$AUDIT/swift-module.original.after.nul" "$AUDIT/swift-module.original.after.json"
perl "$POLICY_TOOL" tree "$POLICY" swift_module \
    "$SWIFT_INPUT_ROOT/$OC_SWIFT_MODULE_BUNDLE_REL" \
    "$AUDIT/swift-module.isolated.after.nul" "$AUDIT/swift-module.isolated.after.json"
perl "$POLICY_TOOL" tree "$POLICY" concurrency_module \
    "$CONCURRENCY_MODULE_ROOT/$OC_CONCURRENCY_MODULE_BUNDLE_REL" \
    "$AUDIT/concurrency-module.original.after.nul" "$AUDIT/concurrency-module.original.after.json"
perl "$POLICY_TOOL" tree "$POLICY" concurrency_module \
    "$CONCURRENCY_INPUT_ROOT/$OC_CONCURRENCY_MODULE_BUNDLE_REL" \
    "$AUDIT/concurrency-module.isolated.after.nul" "$AUDIT/concurrency-module.isolated.after.json"
for subject in sdk swift-module concurrency-module; do
    cmp -s "$AUDIT/$subject.original.before.nul" \
           "$AUDIT/$subject.original.after.nul" || {
        say "REFUSED: original $subject changed across compiler invocations" >&2
        exit 4
    }
    cmp -s "$AUDIT/$subject.isolated.before.nul" \
           "$AUDIT/$subject.isolated.after.nul" || {
        say "REFUSED: isolated $subject changed across compiler invocations" >&2
        exit 4
    }
done
say "  compiler-input bracket: source, SDK, module bundles, and Dispatch unchanged"

section "stage an exact disposable guest root"
GUEST=$WORK/guestroot-full
MISSING=$WORK/guestroot-missing
[ ! -e "$GUEST" ] && [ ! -e "$MISSING" ] || {
    say "REFUSED: guest-root output already exists" >&2; exit 2; }
cp -a "$BASE_ROOT" "$GUEST"
perl "$POLICY_TOOL" runtime "$POLICY" "$GUEST" > "$LOGS/staged-base-before-products.log"
install -m 0755 "$PRODUCT/libOpenCombine.dylib" "$GUEST/darwin/usr/lib/swift/libOpenCombine.dylib"
install -m 0755 "$PRODUCT/libCombine.dylib" "$GUEST/darwin/usr/lib/swift/libCombine.dylib"
cmp -s "$PRODUCT/libOpenCombine.dylib" "$GUEST/darwin/usr/lib/swift/libOpenCombine.dylib"
cmp -s "$PRODUCT/libCombine.dylib" "$GUEST/darwin/usr/lib/swift/libCombine.dylib"
{
    printf 'sha256\tguest-relative-path\tprovenance\n'
    printf '%s\t%s\t%s\n' "$(sha "$PRODUCT/libOpenCombine.dylib")" \
        'darwin/usr/lib/swift/libOpenCombine.dylib' 'strict linked product'
    printf '%s\t%s\t%s\n' "$(sha "$PRODUCT/libCombine.dylib")" \
        'darwin/usr/lib/swift/libCombine.dylib' 'strict linked re-export shim'
} > "$AUDIT/stage.tsv"

while IFS= read -r -d '' base_file; do
    rel=${base_file#"$BASE_ROOT"/}
    cmp -s "$base_file" "$GUEST/$rel" || {
        say "REFUSED: staging changed base runtime file: $rel" >&2; exit 5; }
done < <(find "$BASE_ROOT" -type f -print0)
llvm-nm-18 -gj --defined-only "$GUEST/darwin/usr/lib/libSystem.real.dylib" \
    | grep -Fxq '__NSGetMachExecuteHeader' || {
        say "REFUSED: staged root lost __NSGetMachExecuteHeader from libSystem.real" >&2; exit 5; }
if llvm-nm-18 -gj --defined-only "$GUEST/darwin/usr/lib/libSystem.B.dylib" \
        | grep -Fxq '__NSGetMachExecuteHeader'; then
    say "REFUSED: umbrella still defines __NSGetMachExecuteHeader (would beat .real)" >&2; exit 5
fi

cp -a "$GUEST" "$MISSING"
MISSING_TARGET=$MISSING/darwin/usr/lib/swift/libOpenCombine.dylib
[ -f "$MISSING_TARGET" ] || { say "REFUSED: missing-control target was absent before mutation" >&2; exit 5; }
rm -- "$MISSING_TARGET"
[ ! -e "$MISSING_TARGET" ] || { say "REFUSED: failed to remove exact missing-control target" >&2; exit 5; }
tree_manifest "$GUEST" "$AUDIT/guestroot-full.before.nul"
tree_manifest "$MISSING" "$AUDIT/guestroot-missing.before.nul"

section "positive, mutation, missing-dylib, and recursive guest controls"
SUBJECTS=(
    "$MACHORUN_BIN"
    "$HELPER/COpenCombineHelpers.cpp"
    "$HELPER/COpenCombineHelpers.patched.o"
    "$CORE/OpenCombine.swiftmodule"
    "$CORE/OpenCombine.o"
    "$PRODUCT/libOpenCombine.dylib"
    "$PRODUCT/Combine.swiftmodule"
    "$PRODUCT/libCombine.dylib"
    "$PRODUCT/PublishedOracle_positive"
    "$PRODUCT/PublishedOracle_mutated"
    "$PRODUCT/PublishedOracle_reentrant"
    "$OC_DISPATCH_DYLIB"
)
sha256sum "${SUBJECTS[@]}" > "$AUDIT/subjects.before.sha256"

run_guest() {
    local name=$1 root=$2 exe=$3 want_rc=$4 want_stream=$5 want_line=$6
    set +e
    MACHORUN_ROOT="$root" timeout -k 2 60 "$MACHORUN_BIN" "$exe" \
        > "$RESULTS/$name.stdout" 2> "$RESULTS/$name.stderr"
    local rc=$?
    set -e
    printf '%s\n' "$rc" > "$RESULTS/$name.exit"
    [ "$rc" -eq "$want_rc" ] || {
        say "REFUSED: $name exited $rc, expected $want_rc" >&2
        sed -n '1,120p' "$RESULTS/$name.stdout" >&2
        sed -n '1,160p' "$RESULTS/$name.stderr" >&2
        exit 7
    }
    case "$want_stream" in
        stdout) discriminator_file=$RESULTS/$name.stdout; other_file=$RESULTS/$name.stderr ;;
        stderr) discriminator_file=$RESULTS/$name.stderr; other_file=$RESULTS/$name.stdout ;;
        *) say "REFUSED: invalid discriminator stream: $want_stream" >&2; exit 7 ;;
    esac
    discriminator_count=$(awk -v want="$want_line" \
        '$0 == want { count++ } END { print count + 0 }' "$discriminator_file")
    other_count=$(awk -v want="$want_line" \
        '$0 == want { count++ } END { print count + 0 }' "$other_file")
    if [ "$discriminator_count" -ne 1 ] || [ "$other_count" -ne 0 ]; then
        say "REFUSED: $name needs exactly one full discriminator line on $want_stream: $want_line" >&2
        exit 7
    fi
    printf '  %-18s exit %-3s %s exact-line: %s\n' \
        "$name" "$rc" "$want_stream" "$want_line"
}
run_guest positive "$GUEST" "$PRODUCT/PublishedOracle_positive" \
    "$OC_EXPECT_POSITIVE_EXIT" "$OC_EXPECT_POSITIVE_STREAM" "$OC_EXPECT_POSITIVE_LINE"
run_guest mutated "$GUEST" "$PRODUCT/PublishedOracle_mutated" \
    "$OC_EXPECT_MUTATED_EXIT" "$OC_EXPECT_MUTATED_STREAM" "$OC_EXPECT_MUTATED_LINE"
run_guest missing-dylib "$MISSING" "$PRODUCT/PublishedOracle_positive" \
    "$OC_EXPECT_MISSING_EXIT" "$OC_EXPECT_MISSING_STREAM" "$OC_EXPECT_MISSING_LINE"
run_guest reentrant "$GUEST" "$PRODUCT/PublishedOracle_reentrant" \
    "$OC_EXPECT_REENTRANT_EXIT" "$OC_EXPECT_REENTRANT_STREAM" "$OC_EXPECT_REENTRANT_LINE"

tree_manifest "$GUEST" "$AUDIT/guestroot-full.after.nul"
tree_manifest "$MISSING" "$AUDIT/guestroot-missing.after.nul"
cmp -s "$AUDIT/guestroot-full.before.nul" "$AUDIT/guestroot-full.after.nul" || {
    say "REFUSED: full staged guest root changed while controls ran" >&2; exit 7; }
cmp -s "$AUDIT/guestroot-missing.before.nul" "$AUDIT/guestroot-missing.after.nul" || {
    say "REFUSED: missing-control guest root changed while controls ran" >&2; exit 7; }

sha256sum "${SUBJECTS[@]}" > "$AUDIT/subjects.after.sha256"
cmp -s "$AUDIT/subjects.before.sha256" "$AUDIT/subjects.after.sha256" || {
    say "REFUSED: build/oracle subjects changed while guests ran" >&2
    if ! diff -u "$AUDIT/subjects.before.sha256" \
        "$AUDIT/subjects.after.sha256" >&2; then :; fi
    exit 7
}
perl "$POLICY_TOOL" runtime "$POLICY" "$BASE_ROOT" > "$LOGS/runtime-after.log"
require_hash "$OC_DISPATCH_DYLIB" "$OC_DISPATCH_SHA" "preserved libdispatch after guests"
require_hash "$OC_DISPATCH_TBD" "$OC_DISPATCH_TBD_SHA" "libswiftDispatch tbd after guests"
require_hash /work/lib/libc++abi.dylib \
    "$OC_LINK_SHA_work_lib_libc__abi_dylib" "libc++abi link input after guests"
require_hash /work/lib/libobjc.A.dylib \
    "$OC_LINK_SHA_work_lib_libobjc_A_dylib" "libobjc link input after guests"
require_hash /work/lib/libswiftCore.dylib \
    "$OC_LINK_SHA_work_lib_libswiftCore_dylib" "swiftCore link input after guests"
require_hash /work/lib/libswiftcompat.dylib \
    "$OC_LINK_SHA_work_lib_libswiftcompat_dylib" "swiftcompat link input after guests"
assert_same_file /work/lib/libc++abi.dylib \
    "$BASE_ROOT/darwin/usr/lib/libc++abi.dylib" "libc++abi final hash agreement"
assert_same_file /work/lib/libobjc.A.dylib \
    "$BASE_ROOT/darwin/usr/lib/libobjc.A.dylib" "libobjc final hash agreement"
assert_same_file /work/lib/libswiftCore.dylib \
    "$BASE_ROOT/darwin/usr/lib/swift/libswiftCore.dylib" "swiftCore final hash agreement"
assert_same_file /work/lib/libswiftcompat.dylib \
    "$BASE_ROOT/darwin/usr/lib/libswiftcompat.dylib" "swiftcompat final hash agreement"

section "export durable evidence"
mkdir -p "$EXPORT/artifacts" "$EXPORT/audit" "$EXPORT/logs" "$EXPORT/results"
cp "$CORE/OpenCombine.swiftmodule" "$CORE/OpenCombine.swiftdoc" "$CORE/OpenCombine.o" \
    "$PRODUCT/Combine.swiftmodule" "$PRODUCT/Combine.swiftdoc" \
    "$PRODUCT/libOpenCombine.dylib" "$PRODUCT/libCombine.dylib" \
    "$PRODUCT/PublishedOracle_positive" "$PRODUCT/PublishedOracle_mutated" \
    "$PRODUCT/PublishedOracle_reentrant" "$EXPORT/artifacts/"
cp -a "$AUDIT/." "$EXPORT/audit/"
cp -a "$LOGS/." "$EXPORT/logs/"
cp -a "$RESULTS/." "$EXPORT/results/"
{
    printf 'OpenCombine commit\t%s\n' "$OC_COMMIT"
    printf 'core source count\t%s\n' "$OC_CORE_COUNT"
    printf 'core source digest\t%s\n' "$OC_CORE_DIGEST"
    printf 'OpenCombine dylib sha256\t%s\n' "$(sha "$PRODUCT/libOpenCombine.dylib")"
    printf 'Combine dylib sha256\t%s\n' "$(sha "$PRODUCT/libCombine.dylib")"
    printf 'libdispatch preserved sha256\t%s\n' "$(sha "$OC_DISPATCH_DYLIB")"
    printf 'positive exit\t%s\n' "$OC_EXPECT_POSITIVE_EXIT"
    printf 'mutated exit\t%s\n' "$OC_EXPECT_MUTATED_EXIT"
    printf 'missing-dylib exit\t%s\n' "$OC_EXPECT_MISSING_EXIT"
    printf 'reentrant exit\t%s\n' "$OC_EXPECT_REENTRANT_EXIT"
    printf 'OpenCombineDispatch\tblocked: pinned arm64e interface is selected but needs absent _StringProcessing and mismatches Swift 6.2.4; no arm64 target module or libswiftDispatch.dylib\n'
} > "$EXPORT/RESULT.txt"
tree_manifest "$EXPORT" "$OUT/export.manifest.nul"
say "  export: $EXPORT"
say "  PASS: core built, strictly linked, staged, audited, and all four controls discriminated"
