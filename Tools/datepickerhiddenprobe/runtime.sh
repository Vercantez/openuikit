#!/bin/zsh
# Fresh Foundation-hidden ARM64 Mach-O compile/link/Linux runtime proof for
# UIDatePicker. The historical system-image gate remains immutable; this gate
# recompiles that guest as a predecessor control beside the new literal-UIKit
# DatePicker guest, using exactly one Docker container.
set -euo pipefail

candidate_root="$(cd "$(dirname "$0")/../.." && pwd -P)"
support_root="${1:-$candidate_root/../swift-macho-linux}"
machorun_root="${2:-$candidate_root/../machorun}"

base_commit=8f98af2e53af566923de6616f3629bec0661aa8c
support_commit=3aea5dfa7858ec607183f4233fbb678babb9fb1e
support_tree=89b8640036f1982f47b07d5d8da9b9fb339ee244
support_parent=777e7c083a90452841009f56eec959c098761113
machorun_commit=e6b1745bef09ac8f1e2d6e6c83f7c70d6dbe49a5
machorun_tree=1b41ede32d9a3ba2a5ec2d37685dc64b4eee9b43
image="${SWIFT_MACHO_IMAGE:-swift-macho-spike:noble}"
image_id=sha256:85f9d4c5089ef811c53c55be5e8683f0f582cc9b158f9d9c5348331f3dec4044
container_name=openuikit-datepicker-hidden-runtime

die() {
    print -u2 -- "datepickerhiddenprobe: $*"
    exit 2
}

assert_clean_commit() {
    local repo="$1" expected_commit="$2" expected_tree="$3" label="$4"
    [[ -d "$repo/.git" ]] || die "$label is not a Git checkout: $repo"
    [[ "$(git -C "$repo" rev-parse HEAD)" == "$expected_commit" ]] \
        || die "$label commit drift"
    [[ "$(git -C "$repo" rev-parse HEAD^{tree})" == "$expected_tree" ]] \
        || die "$label tree drift"
    [[ -z "$(git -C "$repo" status --porcelain=v1 --untracked-files=all)" ]] \
        || die "$label checkout is not clean"
}

candidate_commit="$(git -C "$candidate_root" rev-parse HEAD)"
candidate_tree="$(git -C "$candidate_root" rev-parse HEAD^{tree})"
candidate_parents="$(git -C "$candidate_root" show -s --format=%P HEAD)"
[[ "$candidate_parents" == "$base_commit" ]] \
    || die "candidate must have sole parent $base_commit"
[[ "$(git -C "$candidate_root" rev-list --count "$base_commit..HEAD")" == 1 ]] \
    || die "candidate must be exactly one commit beyond the base"
[[ -z "$(git -C "$candidate_root" status --porcelain=v1 --untracked-files=all)" ]] \
    || die "candidate checkout is not clean"

expected_paths=$'Sources/OpenUIKit/UIDatePicker.swift\nTests/OpenUIKitTests/DatePickerSourceCompatibilityTests.swift\nTests/OpenUIKitTests/DatePickerTests.swift\nTests/OpenUIKitTests/FoundationCoexistenceTests.swift\nTools/datepickerhiddenprobe/expected.txt\nTools/datepickerhiddenprobe/main.swift\nTools/datepickerhiddenprobe/runtime.sh\nTools/datepickerprobe/Info.plist\nTools/datepickerprobe/expected.txt\nTools/datepickerprobe/main.swift\nTools/datepickerprobe/run.sh\nTools/reminderdatepickerprobe/EntryPointShim.swift\nTools/reminderdatepickerprobe/run.py\ndocs/APP_COMPAT.md\ndocs/KNOWN_GAPS.md\ndocs/ROADMAP.md'
actual_paths="$(git -C "$candidate_root" diff --name-only "$base_commit..HEAD" \
    | LC_ALL=C sort)"
[[ "$actual_paths" == "$expected_paths" ]] \
    || die "candidate changed-path boundary is not the exact 16-file slice"

assert_clean_commit "$support_root" "$support_commit" "$support_tree" support
[[ "$(git -C "$support_root" show -s --format=%P HEAD)" == "$support_parent" ]] \
    || die "support parent drift"
assert_clean_commit "$machorun_root" "$machorun_commit" "$machorun_tree" machorun
[[ -x "$machorun_root/build/machorun" ]] || die "current machorun loader is missing"
[[ -x "$support_root/scratch/mrroot_full/machorun" ]] \
    || die "support runtime-root loader is missing"
[[ -f "$support_root/scratch/mrroot_full/darwin/usr/lib/libquartz.dylib" ]] \
    || die "support Quartz runtime is missing"
[[ "$(shasum -a 256 "$machorun_root/build/machorun" | awk '{print $1}')" \
    == 1f3b2dd38cf2f6b4fb03db3ab6b3bc765ac16cc5d367141b92704a92e7699158 ]] \
    || die "machorun loader bytes drifted"
[[ "$(shasum -a 256 "$support_root/scratch/mrroot_full/machorun" | awk '{print $1}')" \
    == 1f3b2dd38cf2f6b4fb03db3ab6b3bc765ac16cc5d367141b92704a92e7699158 ]] \
    || die "runtime-root loader bytes drifted"

MACHORUN="$machorun_root" "$support_root/scripts/require_fresh_root.sh" \
    "$support_root/scratch/mrroot_full"
docker info >/dev/null
resolved_image="$(docker image inspect --format '{{.Id}}' "$image")"
[[ "$resolved_image" == "$image_id" ]] \
    || die "Docker image ID drifted"
[[ -z "$(docker ps -aq --filter name=^/${container_name}$)" ]] \
    || die "reserved container name already exists: $container_name"

probe_tmp="$(mktemp -d /private/tmp/datepicker-hidden-runtime.XXXXXX)"
[[ "$probe_tmp" == /private/tmp/datepicker-hidden-runtime.* ]] \
    || die "unexpected temporary output path"
keep_output="${DATEPICKER_HIDDEN_KEEP_OUTPUT:-0}"
[[ "$keep_output" == 0 || "$keep_output" == 1 ]] \
    || die "DATEPICKER_HIDDEN_KEEP_OUTPUT must be 0 or 1"
cleanup_probe() {
    if [[ "$keep_output" == 1 ]]; then
        print -u2 -- "DATEPICKER_HIDDEN_OUTPUT=$probe_tmp"
    else
        rm -rf -- "$probe_tmp"
    fi
}
trap cleanup_probe EXIT

container_id="$(docker create --rm --platform linux/arm64 --name "$container_name" \
    -v "$candidate_root:/uikit:ro" \
    -v "$support_root:/w:ro" \
    -v "$machorun_root:/machorun:ro" \
    -v "$probe_tmp:/out" \
    -w /tmp "$image" bash -lc '
set -euo pipefail

die() {
    echo "datepickerhiddenprobe-container: $*" >&2
    exit 2
}

hash_file() { sha256sum "$1" | awk "{print \$1}"; }

snapshot_tree() {
    local root="$1" output="$2"
    [[ -d "$root" && ! -L "$root" ]] || die "snapshot root is not a real directory: $root"
    find -P "$root" -mindepth 1 -print0 | LC_ALL=C sort -z \
      | while IFS= read -r -d "" node; do
          local kind payload relative mode
          relative="${node#$root/}"
          mode="$(stat -c "%a" -- "$node")"
          if [[ -L "$node" ]]; then
              kind=symlink
              payload="$(readlink -- "$node")"
          elif [[ -f "$node" ]]; then
              kind=file
              payload="$(hash_file "$node")"
          elif [[ -d "$node" ]]; then
              kind=directory
              payload=-
          else
              die "unsupported node in snapshot: $node"
          fi
          printf "%s\0%s\0%s\0%s\0" "$kind" "$mode" "$relative" "$payload"
        done > "$output"
}

TARGET=arm64-apple-macos15.0
MINOS=15.0
SYS=/w/scratch/sysroot_fe4
ROOT=/w/scratch/mrroot_full
FE=/w/scratch/fe4_out
COLLECTIONS=/w/scratch/fe4_collections
OSMODULE=/w/scratch/fe4_os
CSHIMS=/w/scratch/fe4_cshims
SWIFT_FOUNDATION=/w/scratch/swift-foundation
OUT=/out

for tool in swiftc clang-18 ld64.lld-18 llvm-otool-18 sha256sum diff; do
    command -v "$tool" >/dev/null || die "required tool missing: $tool"
done
swiftc --version > "$OUT/swift-version.txt"
[[ "$(sed -n "1p" "$OUT/swift-version.txt")" \
    == "Swift version 6.2.4 (swift-6.2.4-RELEASE)" ]] \
    || die "compiler is not exact Swift 6.2.4 release"
grep -F "Target: aarch64-unknown-linux-gnu" "$OUT/swift-version.txt" >/dev/null \
    || die "compiler host target drifted"
[[ "$(hash_file "$(command -v swiftc)")" \
    == 5a7209655c37a4f4937ea5219a4af59a7c9fc52dd13c615f26682642bc3a83ff ]] \
    || die "swiftc executable bytes drifted"

mkdir -p "$OUT/module-cache" "$OUT/no-fe-module-cache" "$OUT/uikitinc" \
    "$OUT/inc/CPortableIO" "$OUT/inc/CSTBTrueType" "$OUT/audit"
cp /uikit/Sources/CPortableIO/include/cportableio.h "$OUT/inc/CPortableIO/"
cp /uikit/Sources/CSTBTrueType/include/stb_truetype.h "$OUT/inc/CSTBTrueType/"
printf "%s\n" "module CPortableIO { header \"cportableio.h\" export * }" \
    > "$OUT/inc/CPortableIO/module.modulemap"
printf "%s\n" "module CSTBTrueType { header \"stb_truetype.h\" export * }" \
    > "$OUT/inc/CSTBTrueType/module.modulemap"

SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS"
  -module-cache-path "$OUT/module-cache"
  -runtime-compatibility-version none -wmo
  -Xfrontend -disable-implicit-string-processing-module-import
  -Xfrontend -disable-objc-attr-requires-foundation-module)
CINC=(-Xcc -fmodule-map-file=/uikit/Sources/CQuartz/include/module.modulemap
  -Xcc -I/uikit/Sources/CQuartz/include
  -Xcc -fmodule-map-file="$OUT/inc/CPortableIO/module.modulemap"
  -Xcc -I"$OUT/inc/CPortableIO"
  -Xcc -fmodule-map-file="$OUT/inc/CSTBTrueType/module.modulemap"
  -Xcc -I"$OUT/inc/CSTBTrueType")
FEMODULES=(-I "$FE" -I "$COLLECTIONS" -I "$OSMODULE"
  -Xcc -fmodule-map-file="$SWIFT_FOUNDATION/Sources/_FoundationCShims/include/module.modulemap"
  -Xcc -I"$SWIFT_FOUNDATION/Sources/_FoundationCShims/include")

upstream_digest="$(perl /w/full/foundation/pinned_inputs.pl verify \
  --swift-foundation /w/scratch/swift-foundation \
  --swift-collections /w/scratch/swift-collections --digest-only)"
[[ "$upstream_digest" \
    == 9eb1eec3fddb4bc6c6b99048b43a2af249952a79abc2796328c4e3ac0ccb4dc7 ]] \
    || die "pinned swift-foundation/swift-collections inputs drifted"
printf "%s\n" "$upstream_digest" > "$OUT/audit/upstream-inputs.sha256"

FE_INPUTS=(
  scratch/fe4_out/FoundationEssentials.swiftmodule
  scratch/fe4_out/FoundationEssentials.o
  scratch/fe4_collections/InternalCollectionsUtilities.swiftmodule
  scratch/fe4_collections/InternalCollectionsUtilities.o
  scratch/fe4_collections/OrderedCollections.swiftmodule
  scratch/fe4_collections/OrderedCollections.o
  scratch/fe4_collections/_RopeModule.swiftmodule
  scratch/fe4_collections/_RopeModule.o
  scratch/fe4_os/os.swiftmodule
  scratch/fe4_os/os.o
  scratch/fe4_cshims/platform_shims.o
  scratch/fe4_cshims/string_shims.o
  scratch/fe4_cshims/uuid.o
)
: > "$OUT/audit/fe-artifacts.tsv"
for relative in "${FE_INPUTS[@]}"; do
    [[ -f "/w/$relative" && ! -L "/w/$relative" ]] \
        || die "missing regular FE artifact: $relative"
    printf "%s\t%s\n" "$relative" "$(hash_file "/w/$relative")" \
        >> "$OUT/audit/fe-artifacts.tsv"
done
[[ "$(hash_file "$OUT/audit/fe-artifacts.tsv")" \
    == 3154369c8a4ea5bec0905c99ad7c71cf1f543d0d2f8d3fff6d28a7d1c8a0c467 ]] \
    || die "pinned FE artifact manifest drifted"

snapshot_tree /uikit/Sources/OpenCoreGraphics \
    "$OUT/audit/opencoregraphics.before.nul"
snapshot_tree /uikit/Sources/OpenUIKit "$OUT/audit/openuikit.before.nul"
snapshot_tree /uikit/Sources/UIKitShim "$OUT/audit/uikitshim.before.nul"
snapshot_tree /uikit/Sources/CQuartz/include "$OUT/audit/cquartz.before.nul"
snapshot_tree /uikit/Sources/CPortableIO "$OUT/audit/cportableio.before.nul"
snapshot_tree /uikit/Sources/CSTBTrueType "$OUT/audit/cstbtruetype.before.nul"
snapshot_tree /uikit/Tools/systemimagehiddenprobe \
    "$OUT/audit/systemimage-probe.before.nul"
snapshot_tree /uikit/Tools/datepickerhiddenprobe \
    "$OUT/audit/datepicker-probe.before.nul"
snapshot_tree /w/full/foundation "$OUT/audit/support-foundation.before.nul"
snapshot_tree /w/full/hostclock "$OUT/audit/support-hostclock.before.nul"
snapshot_tree /w/full/shims "$OUT/audit/support-shims.before.nul"
snapshot_tree "$SWIFT_FOUNDATION/Sources/_FoundationCShims/include" \
    "$OUT/audit/foundation-cshims.before.nul"
snapshot_tree "$SYS" "$OUT/audit/sysroot.before.nul"
snapshot_tree "$ROOT" "$OUT/audit/runtime-root.before.nul"

set +e
swiftc -target "$TARGET" -sdk "$SYS" \
  -module-cache-path "$OUT/no-fe-module-cache" \
  -runtime-compatibility-version none -wmo \
  -Xfrontend -disable-implicit-string-processing-module-import \
  -Xfrontend -disable-objc-attr-requires-foundation-module \
  "${CINC[@]}" -typecheck -module-name DatePickerNoFoundationEssentials \
  /w/full/foundation/foundationessentials_import_guard.swift \
  > "$OUT/fe-negative.stdout" 2> "$OUT/fe-negative.stderr"
negative_status=$?
set -e
[[ $negative_status -ne 0 ]] || die "missing-FE negative unexpectedly compiled"
grep -F "FoundationEssentials is not visible on the OpenUIKit production compile path" \
    "$OUT/fe-negative.stderr" >/dev/null \
    || die "missing-FE negative failed for the wrong reason"
echo FOUNDATION_ESSENTIALS_MISSING_PATH_REFUSED_OK

"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -typecheck \
  -module-name DatePickerWithFoundationEssentials \
  /w/full/foundation/foundationessentials_import_guard.swift

cat > "$OUT/fe-positive.swift" <<"EOF"
#if canImport(Foundation)
#error("Foundation umbrella must remain hidden")
#endif
#if !canImport(FoundationEssentials)
#error("FoundationEssentials must be visible")
#endif
import FoundationEssentials
let date = Date(timeIntervalSinceReferenceDate: 800000000)
var calendar = Calendar(identifier: .gregorian)
calendar.locale = Locale(identifier: "en_US_POSIX")
calendar.timeZone = TimeZone(secondsFromGMT: 0)!
precondition(calendar.component(.year, from: date) > 2001)
EOF
"${SWIFTC[@]}" "${FEMODULES[@]}" -typecheck \
    -module-name DatePickerFoundationEssentialsPositive "$OUT/fe-positive.swift"
echo FOUNDATION_ESSENTIALS_MATCHING_TOOLCHAIN_IMPORT_OK

mapfile -t OCG_SOURCES < <(find /uikit/Sources/OpenCoreGraphics \
  -type f -name "*.swift" | LC_ALL=C sort)
mapfile -t OUI_SOURCES < <(find /uikit/Sources/OpenUIKit \
  -type f -name "*.swift" | LC_ALL=C sort)
[[ ${#OCG_SOURCES[@]} -eq 12 ]] || die "OpenCoreGraphics source census drifted"
[[ ${#OUI_SOURCES[@]} -eq 102 ]] || die "OpenUIKit source census drifted"
for source in "${OCG_SOURCES[@]}"; do
    printf "%s\t%s\n" "${source#/uikit/}" "$(hash_file "$source")"
done > "$OUT/audit/opencoregraphics-sources.tsv"
for source in "${OUI_SOURCES[@]}"; do
    printf "%s\t%s\n" "${source#/uikit/}" "$(hash_file "$source")"
done > "$OUT/audit/openuikit-sources.tsv"
echo "== fresh candidate modules: OpenCoreGraphics=12 OpenUIKit=102"

"${SWIFTC[@]}" "${CINC[@]}" -module-name OpenCoreGraphics \
  -emit-object -emit-module \
  -emit-module-path "$OUT/OpenCoreGraphics.swiftmodule" \
  -o "$OUT/opencoregraphics.o" "${OCG_SOURCES[@]}"
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT" \
  -module-name OpenUIKit -emit-object -emit-module \
  -emit-module-path "$OUT/OpenUIKit.swiftmodule" \
  -o "$OUT/openuikit.o" "${OUI_SOURCES[@]}" \
  /w/full/shims/FoundationNames.swift
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
  -I "$OUT" -module-name UIKit -emit-object -emit-module \
  -emit-module-path "$OUT/uikitinc/UIKit.swiftmodule" \
  -o "$OUT/uikitshim.o" /uikit/Sources/UIKitShim/UIKit.swift

echo "== literal UIKit predecessor and DatePicker guest objects"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
  -I "$OUT" -I "$OUT/uikitinc" -module-name SystemImageHiddenProbe \
  -emit-object -o "$OUT/systemimage-probe.o" \
  /uikit/Tools/systemimagehiddenprobe/main.swift
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
  -I "$OUT" -I "$OUT/uikitinc" -module-name DatePickerHiddenProbe \
  -emit-object -o "$OUT/datepicker-probe.o" \
  /uikit/Tools/datepickerhiddenprobe/main.swift

echo "== fresh unchanged C dependency objects"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -I/uikit/Sources/CPortableIO/include \
  -c /uikit/Sources/CPortableIO/io.c -o "$OUT/cportableio.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -I/uikit/Sources/CSTBTrueType/include \
  -c /uikit/Sources/CSTBTrueType/stb_impl.c -o "$OUT/cstbtruetype.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -I/w/full/hostclock/include \
  -c /w/full/hostclock/hostclock.c -o "$OUT/hostclock.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -c /w/full/shims/swiftcorepatch.c -o "$OUT/swiftcorepatch.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O1 -nostdinc \
  -DOPEN_FOUNDATION_UUID_COMPAT=1 \
  -c /w/full/foundation/fm_unimplemented.c -o "$OUT/fm_unimplemented.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O1 \
  -c /w/full/foundation/uuid_compat.c -o "$OUT/uuid_compat.o"

FE_OBJECTS=(
  "$FE/FoundationEssentials.o"
  "$COLLECTIONS/InternalCollectionsUtilities.o"
  "$COLLECTIONS/OrderedCollections.o"
  "$COLLECTIONS/_RopeModule.o"
  "$OSMODULE/os.o"
  "$CSHIMS/platform_shims.o"
  "$CSHIMS/string_shims.o"
  "$CSHIMS/uuid.o"
  "$OUT/fm_unimplemented.o"
  "$OUT/uuid_compat.o"
)
COMMON_OBJECTS=(
  "$OUT/uikitshim.o" "$OUT/openuikit.o" "$OUT/opencoregraphics.o"
  "$OUT/cportableio.o" "$OUT/cstbtruetype.o" "$OUT/hostclock.o"
  "$OUT/swiftcorepatch.o" "${FE_OBJECTS[@]}"
)

link_guest() {
    local probe_object="$1" executable="$2"
    ld64.lld-18 -arch arm64 -platform_version macos "$MINOS" "$MINOS" \
      -syslibroot "$SYS" -dead_strip -exported_symbol __mh_execute_header \
      -rpath /usr/lib/swift -rpath @loader_path \
      -L"$ROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
      "$ROOT/darwin/usr/lib/libswiftcompat.dylib" \
      -L/usr/lib -lSystem -lobjc "$ROOT/darwin/usr/lib/libquartz.dylib" \
      "$ROOT/darwin/usr/lib/libSystem.B.dylib" \
      -o "$executable" "$probe_object" "${COMMON_OBJECTS[@]}"
}

echo "== link two ARM64 Mach-O guests"
link_guest "$OUT/systemimage-probe.o" "$OUT/systemimagehiddenprobe"
link_guest "$OUT/datepicker-probe.o" "$OUT/datepickerhiddenprobe"
mkdir "$OUT/empty-package"
for executable in "$OUT/systemimagehiddenprobe" "$OUT/datepickerhiddenprobe"; do
    llvm-otool-18 -L "$executable" > "$executable.loads.txt"
    tail -n +2 "$executable.loads.txt" \
      | sed -E "s/^[[:space:]]*//; s/[[:space:]]+\\(compatibility version.*$//" \
      > "$executable.direct-load-paths.txt"
    [[ -s "$executable.direct-load-paths.txt" ]] \
        || die "empty direct load set for $executable"
    if grep -E "Foundation\.framework|CoreFoundation\.framework|/usr/lib/swift/lib(Foundation|CoreFoundation)\.dylib" \
        "$executable.direct-load-paths.txt" >/dev/null; then
        die "Foundation umbrella load appeared in $executable"
    fi
    while IFS= read -r dependency; do
        case "$dependency" in
          /*) [[ -f "$ROOT/darwin$dependency" ]] \
                || die "direct dependency is absent from guest root: $dependency" ;;
          *) die "unexpected nonabsolute direct dependency: $dependency" ;;
        esac
    done < "$executable.direct-load-paths.txt"
    llvm-otool-18 -l "$executable" > "$executable.load-commands.txt"
    perl /w/full/swiftui/focus_widget_guest_attest.pl closure \
      --otool llvm-otool-18 --executable "$executable" \
      --package "$OUT/empty-package" --guest-root "$ROOT" \
      > "$executable.runtime-closure.before.tsv"
done
echo MACHO_LOADS_FOUNDATION_HIDDEN_OK

echo "== execute predecessor once and DatePicker twice through Linux machorun"
MACHORUN_ROOT="$ROOT" "$ROOT/machorun" "$OUT/systemimagehiddenprobe" \
  > "$OUT/systemimage.stdout" 2> "$OUT/systemimage.stderr"
printf "%s\n" "SYSTEM_IMAGE_FOUNDATION_HIDDEN_RUNTIME_OK symbols=6" \
  > "$OUT/systemimage.expected"
diff -u "$OUT/systemimage.expected" "$OUT/systemimage.stdout"
if [[ -s "$OUT/systemimage.stderr" ]]; then
    printf "%s\n" \
      "concpatch: dlopen(\"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation\") -- refused, as machorun does. mode=16" \
      > "$OUT/systemimage.allowed.stderr"
    diff -u "$OUT/systemimage.allowed.stderr" "$OUT/systemimage.stderr"
else
    : > "$OUT/systemimage.allowed.stderr"
fi
if grep -Eai "loader|fatal|fm_unimplemented|stub" \
    "$OUT/systemimage.stdout" "$OUT/systemimage.stderr" >/dev/null; then
    die "predecessor runtime reported loader/fatal/stub text"
fi

for run in 1 2; do
    MACHORUN_ROOT="$ROOT" "$ROOT/machorun" "$OUT/datepickerhiddenprobe" \
      > "$OUT/datepicker.$run.stdout" 2> "$OUT/datepicker.$run.stderr"
    [[ ! -s "$OUT/datepicker.$run.stderr" ]] \
        || die "DatePicker runtime stderr was not empty on run $run"
    diff -u /uikit/Tools/datepickerhiddenprobe/expected.txt \
        "$OUT/datepicker.$run.stdout"
    if grep -Eai "loader|fatal|fm_unimplemented|stub" \
        "$OUT/datepicker.$run.stdout" "$OUT/datepicker.$run.stderr" >/dev/null; then
        die "DatePicker runtime reported loader/fatal/stub text on run $run"
    fi
done
cmp "$OUT/datepicker.1.stdout" "$OUT/datepicker.2.stdout"

for executable in "$OUT/systemimagehiddenprobe" "$OUT/datepickerhiddenprobe"; do
    perl /w/full/swiftui/focus_widget_guest_attest.pl closure \
      --otool llvm-otool-18 --executable "$executable" \
      --package "$OUT/empty-package" --guest-root "$ROOT" \
      > "$executable.runtime-closure.after.tsv"
    cmp "$executable.runtime-closure.before.tsv" \
        "$executable.runtime-closure.after.tsv"
done

snapshot_tree /uikit/Sources/OpenCoreGraphics \
    "$OUT/audit/opencoregraphics.after.nul"
snapshot_tree /uikit/Sources/OpenUIKit "$OUT/audit/openuikit.after.nul"
snapshot_tree /uikit/Sources/UIKitShim "$OUT/audit/uikitshim.after.nul"
snapshot_tree /uikit/Sources/CQuartz/include "$OUT/audit/cquartz.after.nul"
snapshot_tree /uikit/Sources/CPortableIO "$OUT/audit/cportableio.after.nul"
snapshot_tree /uikit/Sources/CSTBTrueType "$OUT/audit/cstbtruetype.after.nul"
snapshot_tree /uikit/Tools/systemimagehiddenprobe \
    "$OUT/audit/systemimage-probe.after.nul"
snapshot_tree /uikit/Tools/datepickerhiddenprobe \
    "$OUT/audit/datepicker-probe.after.nul"
snapshot_tree /w/full/foundation "$OUT/audit/support-foundation.after.nul"
snapshot_tree /w/full/hostclock "$OUT/audit/support-hostclock.after.nul"
snapshot_tree /w/full/shims "$OUT/audit/support-shims.after.nul"
snapshot_tree "$SWIFT_FOUNDATION/Sources/_FoundationCShims/include" \
    "$OUT/audit/foundation-cshims.after.nul"
snapshot_tree "$SYS" "$OUT/audit/sysroot.after.nul"
snapshot_tree "$ROOT" "$OUT/audit/runtime-root.after.nul"
for before in "$OUT"/audit/*.before.nul; do
    after="${before%.before.nul}.after.nul"
    cmp "$before" "$after"
done

after_upstream_digest="$(perl /w/full/foundation/pinned_inputs.pl verify \
  --swift-foundation /w/scratch/swift-foundation \
  --swift-collections /w/scratch/swift-collections --digest-only)"
[[ "$after_upstream_digest" == "$upstream_digest" ]] \
    || die "pinned upstream inputs changed during gate"

sha256sum \
  "$OUT/audit/fe-artifacts.tsv" \
  "$OUT/audit/upstream-inputs.sha256" \
  "$OUT/audit/opencoregraphics-sources.tsv" \
  "$OUT/audit/openuikit-sources.tsv" \
  "$OUT/swift-version.txt" \
  "$OUT/OpenCoreGraphics.swiftmodule" "$OUT/OpenUIKit.swiftmodule" \
  "$OUT/uikitinc/UIKit.swiftmodule" \
  "$OUT/systemimagehiddenprobe" "$OUT/datepickerhiddenprobe" \
  "$OUT/systemimagehiddenprobe.loads.txt" \
  "$OUT/datepickerhiddenprobe.loads.txt" \
  "$OUT/systemimagehiddenprobe.direct-load-paths.txt" \
  "$OUT/datepickerhiddenprobe.direct-load-paths.txt" \
  "$OUT/systemimagehiddenprobe.load-commands.txt" \
  "$OUT/datepickerhiddenprobe.load-commands.txt" \
  "$OUT/systemimagehiddenprobe.runtime-closure.before.tsv" \
  "$OUT/systemimagehiddenprobe.runtime-closure.after.tsv" \
  "$OUT/datepickerhiddenprobe.runtime-closure.before.tsv" \
  "$OUT/datepickerhiddenprobe.runtime-closure.after.tsv" \
  /uikit/Tools/datepickerhiddenprobe/main.swift \
  /uikit/Tools/datepickerhiddenprobe/expected.txt \
  /uikit/Tools/datepickerhiddenprobe/runtime.sh \
  "$OUT/fe-negative.stdout" "$OUT/fe-negative.stderr" \
  "$OUT/systemimage.stdout" "$OUT/systemimage.stderr" \
  "$OUT/systemimage.allowed.stderr" \
  "$OUT/datepicker.1.stdout" "$OUT/datepicker.1.stderr" \
  "$OUT/datepicker.2.stdout" "$OUT/datepicker.2.stderr" \
  > "$OUT/audit/evidence.sha256"
for manifest in "$OUT"/audit/*.before.nul "$OUT"/audit/*.after.nul; do
    sha256sum "$manifest" >> "$OUT/audit/evidence.sha256"
done
cat "$OUT/audit/evidence.sha256"
echo DATEPICKER_FOUNDATION_HIDDEN_LINUX_RUNTIME_OK
')"
[[ "$(docker container inspect --format '{{.Image}}' "$container_id")" \
    == "$image_id" ]] || {
        docker container rm "$container_id" >/dev/null
        die "created container resolved a different image"
    }
docker start -a "$container_id"

[[ -z "$(git -C "$candidate_root" status --porcelain=v1 --untracked-files=all)" ]] \
    || die "candidate checkout changed during read-only gate"
assert_clean_commit "$support_root" "$support_commit" "$support_tree" support-after
assert_clean_commit "$machorun_root" "$machorun_commit" "$machorun_tree" machorun-after
[[ "$(docker image inspect --format '{{.Id}}' "$image")" == "$image_id" ]] \
    || die "Docker image ID changed during gate"

print -- "candidate_commit=$candidate_commit"
print -- "candidate_tree=$candidate_tree"
print -- "support_commit=$support_commit"
print -- "support_tree=$support_tree"
print -- "image_id=$image_id"
print -- "sources=OpenCoreGraphics:12,OpenUIKit:102 guests=systemimage:1,datepicker:2"
[[ "$keep_output" == 1 ]] && print -- "evidence_output=$probe_tmp"
print -- "DATEPICKER_HIDDEN_GATE_OK"
