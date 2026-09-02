#!/bin/zsh
set -euo pipefail

candidate_root=${0:A:h:h:h}
if (( $# != 2 )); then
  print -u2 -- "usage: $0 <pinned-swift-macho-linux> <pinned-machorun>"
  exit 2
fi
support_root=$1
machorun_root=$2
base_commit=b8531df000f35a4580a9f239bb0348d04552053f
support_commit=3aea5dfa7858ec607183f4233fbb678babb9fb1e
support_tree=89b8640036f1982f47b07d5d8da9b9fb339ee244
machorun_commit=e6b1745bef09ac8f1e2d6e6c83f7c70d6dbe49a5
machorun_tree=1b41ede32d9a3ba2a5ec2d37685dc64b4eee9b43
image=${SWIFT_MACHO_IMAGE:-swift-macho-spike:noble}
image_id=sha256:85f9d4c5089ef811c53c55be5e8683f0f582cc9b158f9d9c5348331f3dec4044
container_name=openuikit-notification-bridge-guest

die() { print -u2 -- "notificationbridgeprobe: $*"; exit 2; }

assert_clean_commit() {
  local repo=$1 expected_commit=$2 expected_tree=$3 label=$4
  [[ -d $repo/.git ]] || die "$label is not a Git checkout"
  [[ $(git -C $repo rev-parse HEAD) == $expected_commit ]] \
    || die "$label commit drift"
  [[ $(git -C $repo rev-parse HEAD^{tree}) == $expected_tree ]] \
    || die "$label tree drift"
  [[ -z $(git -C $repo status --porcelain=v1 --untracked-files=all) ]] \
    || die "$label checkout is not clean"
}

expected_paths=$'Sources/OpenUIKit/FoundationTypes.swift\nSources/OpenUIKit/NotificationCenter.swift\nSources/OpenUIKit/Timer.swift\nSources/OpenUIKit/UIApplication.swift\nSources/OpenUIKit/UITextField.swift\nSources/UIKitShim/UIKit.swift\nTests/OpenUIKitTests/ActorIsolationTests.swift\nTests/OpenUIKitTests/NotificationFoundationExtensionProbe.swift\nTests/OpenUIKitTests/NotificationSourceCompatibilityTests.swift\nTests/OpenUIKitTests/NotificationTimerTests.swift\nTests/OpenUIKitTests/NotificationUIKitOnlyConsumerProbe.swift\nTools/notificationbridgeprobe/Info.plist\nTools/notificationbridgeprobe/expected.txt\nTools/notificationbridgeprobe/focus-client.swift\nTools/notificationbridgeprobe/foundation-extension.swift\nTools/notificationbridgeprobe/foundation-shim.swift\nTools/notificationbridgeprobe/guest.expected.txt\nTools/notificationbridgeprobe/guest.sh\nTools/notificationbridgeprobe/guest.swift\nTools/notificationbridgeprobe/main.swift\nTools/notificationbridgeprobe/native-elf.expected.txt\nTools/notificationbridgeprobe/native-elf.swift\nTools/notificationbridgeprobe/run.sh\nTools/remindernotificationprobe/EntryPointShim.swift\nTools/remindernotificationprobe/run.py\ndocs/APP_COMPAT.md\ndocs/ARCHITECTURE.md\ndocs/KNOWN_GAPS.md\ndocs/OBJC_RUNTIME.md\ndocs/PORTABILITY.md\ndocs/REAL_APP_TEST.md\ndocs/ROADMAP.md'
head=$(git -C $candidate_root rev-parse HEAD)
if [[ $head == $base_commit ]]; then
  tracked=$(git -C $candidate_root diff --name-only $base_commit)
  untracked=$(git -C $candidate_root ls-files --others --exclude-standard)
  actual_paths=$(printf '%s\n%s\n' "$tracked" "$untracked" \
    | sed '/^$/d' | LC_ALL=C sort -u)
else
  [[ $(git -C $candidate_root show -s --format=%P HEAD) == $base_commit ]] \
    || die "candidate commit does not have the exact base parent"
  [[ $(git -C $candidate_root rev-list --count $base_commit..HEAD) == 1 ]] \
    || die "candidate is not exactly one commit beyond base"
  [[ -z $(git -C $candidate_root status --porcelain=v1 --untracked-files=all) ]] \
    || die "committed candidate is not clean"
  actual_paths=$(git -C $candidate_root diff --name-only $base_commit..HEAD \
    | LC_ALL=C sort)
fi
[[ $actual_paths == $expected_paths ]] \
  || die "candidate changed-path boundary drifted"

assert_clean_commit $support_root $support_commit $support_tree support
assert_clean_commit $machorun_root $machorun_commit $machorun_tree machorun
[[ -x $support_root/scratch/mrroot_full/machorun ]] \
  || die "guest loader missing"
MACHORUN=$machorun_root $support_root/scripts/require_fresh_root.sh \
  $support_root/scratch/mrroot_full
docker info >/dev/null
[[ $(docker image inspect --format '{{.Id}}' $image) == $image_id ]] \
  || die "Docker image drifted"
[[ -z $(docker ps -aq --filter name=^/$container_name$) ]] \
  || die "reserved container name is already in use"

output_root=$(mktemp -d /private/tmp/notification-bridge-guest.XXXXXX)
[[ $output_root == /private/tmp/notification-bridge-guest.* ]] \
  || die "unexpected temporary path"
keep=${NOTIFICATION_BRIDGE_GUEST_KEEP_OUTPUT:-0}
cleanup() {
  docker rm -f $container_name >/dev/null 2>&1 || true
  if [[ $keep == 1 ]]; then
    print -u2 -- "NOTIFICATION_BRIDGE_GUEST_OUTPUT=$output_root"
  else
    rm -rf -- $output_root
  fi
}
trap cleanup EXIT

docker run --rm --platform linux/arm64 --name $container_name \
  -v $candidate_root:/uikit:ro -v $support_root:/w:ro \
  -v $machorun_root:/machorun:ro -v $output_root:/out \
  -w /tmp $image bash -lc '
set -euo pipefail
die() { echo "notification-bridge-guest: $*" >&2; exit 2; }
hash_file() { sha256sum "$1" | awk "{print \$1}"; }

TARGET=arm64-apple-macos15.0
SYS=/w/scratch/sysroot_fe4
ROOT=/w/scratch/mrroot_full
FE=/w/scratch/fe4_out
COLLECTIONS=/w/scratch/fe4_collections
OSMODULE=/w/scratch/fe4_os
CSHIMS=/w/scratch/fe4_cshims
SWIFT_FOUNDATION=/w/scratch/swift-foundation
OUT=/out
for tool in swift swiftc clang-18 ld64.lld-18 llvm-otool-18 sha256sum diff file cmp; do
  command -v "$tool" >/dev/null || die "missing tool $tool"
done
swiftc --version > "$OUT/swift-version.txt"
grep -Fx "Swift version 6.2.4 (swift-6.2.4-RELEASE)" \
  "$OUT/swift-version.txt" >/dev/null
grep -F "Target: aarch64-unknown-linux-gnu" "$OUT/swift-version.txt" >/dev/null
[[ "$(hash_file "$(command -v swiftc)")" \
    == 5a7209655c37a4f4937ea5219a4af59a7c9fc52dd13c615f26682642bc3a83ff ]]

# Native ELF: build the candidate as an external package dependency, then run
# the literal Foundation+UIKit client twice. All scratch state stays outside
# the read-only candidate mount.
mkdir -p "$OUT/native-client/Sources/NativeELFNotificationProbe"
cat > "$OUT/native-client/Package.swift" <<"EOF"
// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "NativeELFNotificationClient",
    dependencies: [.package(path: "/uikit")],
    targets: [
        .executableTarget(
            name: "NativeELFNotificationProbe",
            dependencies: [.product(name: "UIKit", package: "uikit")],
            swiftSettings: [.unsafeFlags(["-default-isolation", "MainActor"])]
        )
    ]
)
EOF
cp /uikit/Tools/notificationbridgeprobe/native-elf.swift \
  "$OUT/native-client/Sources/NativeELFNotificationProbe/main.swift"
swift build -c release --package-path "$OUT/native-client" \
  --scratch-path "$OUT/native-build" --product NativeELFNotificationProbe \
  > "$OUT/native-build.stdout" 2> "$OUT/native-build.stderr"
native_bin="$OUT/native-build/release/NativeELFNotificationProbe"
[[ -x $native_bin ]] || die "native ELF client binary missing"
for run in 1 2; do
  "$native_bin" > "$OUT/native-elf.$run.stdout" \
    2> "$OUT/native-elf.$run.stderr"
  [[ ! -s "$OUT/native-elf.$run.stderr" ]] \
    || die "native ELF runtime stderr was not empty"
  diff -u /uikit/Tools/notificationbridgeprobe/native-elf.expected.txt \
    "$OUT/native-elf.$run.stdout"
done
cmp "$OUT/native-elf.1.stdout" "$OUT/native-elf.2.stdout"

mkdir -p "$OUT/module-cache" "$OUT/inc/CPortableIO" "$OUT/inc/CSTBTrueType"
cp /uikit/Sources/CPortableIO/include/cportableio.h "$OUT/inc/CPortableIO/"
cp /uikit/Sources/CSTBTrueType/include/stb_truetype.h "$OUT/inc/CSTBTrueType/"
printf "%s\n" "module CPortableIO { header \"cportableio.h\" export * }" \
  > "$OUT/inc/CPortableIO/module.modulemap"
printf "%s\n" "module CSTBTrueType { header \"stb_truetype.h\" export * }" \
  > "$OUT/inc/CSTBTrueType/module.modulemap"
SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS"
  -module-cache-path "$OUT/module-cache" -runtime-compatibility-version none
  -wmo -Xfrontend -disable-implicit-string-processing-module-import
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

mapfile -t OCG < <(find /uikit/Sources/OpenCoreGraphics -type f -name "*.swift" \
  | LC_ALL=C sort)
mapfile -t OUI < <(find /uikit/Sources/OpenUIKit -type f -name "*.swift" \
  | LC_ALL=C sort)
[[ ${#OCG[@]} -eq 12 ]] || die "OpenCoreGraphics source census drifted"
[[ ${#OUI[@]} -eq 102 ]] || die "OpenUIKit source census drifted"
"${SWIFTC[@]}" "${CINC[@]}" -module-name OpenCoreGraphics \
  -emit-object -emit-module -emit-module-path "$OUT/OpenCoreGraphics.swiftmodule" \
  -o "$OUT/opencoregraphics.o" "${OCG[@]}"

# OpenUIKit and UIKit are intentionally compiled before any Foundation
# umbrella exists, matching production full/scripts/build_full.sh.
"${SWIFTC[@]}" "${CINC[@]}" "${FEMODULES[@]}" -I "$OUT" \
  -module-name OpenUIKit -emit-object -emit-module \
  -emit-module-path "$OUT/OpenUIKit.swiftmodule" -o "$OUT/openuikit.o" \
  "${OUI[@]}" /w/full/shims/FoundationNames.swift
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
  -I "$OUT" -module-name UIKit -emit-object -emit-module \
  -emit-module-path "$OUT/UIKit.swiftmodule" -o "$OUT/uikit.o" \
  /uikit/Sources/UIKitShim/UIKit.swift

# Only the app-facing layer sees this deliberately tiny Foundation module.
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
  -I "$OUT" -module-name Foundation -emit-object -emit-module \
  -emit-module-path "$OUT/Foundation.swiftmodule" -o "$OUT/foundation.o" \
  /uikit/Tools/notificationbridgeprobe/foundation-shim.swift
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" "${FEMODULES[@]}" \
  -I "$OUT" -module-name NotificationBridgeGuest -emit-object \
  -o "$OUT/guest.o" \
  /uikit/Tools/notificationbridgeprobe/foundation-extension.swift \
  /uikit/Tools/notificationbridgeprobe/focus-client.swift \
  /uikit/Tools/notificationbridgeprobe/guest.swift

clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -c /uikit/Sources/CPortableIO/io.c -o "$OUT/cportableio.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -I/uikit/Sources/CSTBTrueType/include \
  -c /uikit/Sources/CSTBTrueType/stb_impl.c -o "$OUT/cstbtruetype.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -I/w/full/hostclock/include -c /w/full/hostclock/hostclock.c \
  -o "$OUT/hostclock.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
  -c /w/full/shims/swiftcorepatch.c -o "$OUT/swiftcorepatch.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O1 -nostdinc \
  -DOPEN_FOUNDATION_UUID_COMPAT=1 -c /w/full/foundation/fm_unimplemented.c \
  -o "$OUT/fm_unimplemented.o"
clang-18 -target "$TARGET" -isysroot "$SYS" -O1 \
  -c /w/full/foundation/uuid_compat.c -o "$OUT/uuid_compat.o"

ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
  -syslibroot "$SYS" -dead_strip -exported_symbol __mh_execute_header \
  -rpath /usr/lib/swift -rpath @loader_path \
  -L"$ROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore -lswiftObjectiveC \
  "$ROOT/darwin/usr/lib/libswiftcompat.dylib" \
  -L/usr/lib -lSystem -lobjc "$ROOT/darwin/usr/lib/libquartz.dylib" \
  "$ROOT/darwin/usr/lib/libSystem.B.dylib" \
  -o "$OUT/notification-bridge-guest" "$OUT/guest.o" \
  "$OUT/foundation.o" "$OUT/uikit.o" "$OUT/openuikit.o" \
  "$OUT/opencoregraphics.o" "$OUT/cportableio.o" "$OUT/cstbtruetype.o" \
  "$OUT/hostclock.o" "$OUT/swiftcorepatch.o" \
  "$FE/FoundationEssentials.o" \
  "$COLLECTIONS/InternalCollectionsUtilities.o" \
  "$COLLECTIONS/OrderedCollections.o" "$COLLECTIONS/_RopeModule.o" \
  "$OSMODULE/os.o" "$CSHIMS/platform_shims.o" "$CSHIMS/string_shims.o" \
  "$CSHIMS/uuid.o" "$OUT/fm_unimplemented.o" "$OUT/uuid_compat.o"

llvm-otool-18 -L "$OUT/notification-bridge-guest" > "$OUT/guest.loads.txt"
if grep -E "Foundation\.framework|CoreFoundation\.framework|/usr/lib/swift/lib(Foundation|CoreFoundation)\.dylib" \
    "$OUT/guest.loads.txt"; then
  die "Foundation/CoreFoundation umbrella appeared in guest load commands"
fi
printf "%s\n" \
  "concpatch: dlopen(\"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation\") -- refused, as machorun does. mode=16" \
  > "$OUT/guest.allowed.stderr"
for run in 1 2; do
  MACHORUN_ROOT="$ROOT" "$ROOT/machorun" "$OUT/notification-bridge-guest" \
    > "$OUT/guest.$run.stdout" 2> "$OUT/guest.$run.stderr"
  # The Swift bridge/runtime probes for the native CoreFoundation umbrella.
  # The pinned loader must refuse it; accept that exact diagnostic and no
  # other stderr, so a real loader/runtime warning still fails closed.
  diff -u "$OUT/guest.allowed.stderr" "$OUT/guest.$run.stderr"
  diff -u /uikit/Tools/notificationbridgeprobe/guest.expected.txt \
    "$OUT/guest.$run.stdout"
  if grep -Eai "loader|fatal|fm_unimplemented|stub" \
      "$OUT/guest.$run.stdout" "$OUT/guest.$run.stderr" >/dev/null; then
    die "guest runtime reported loader/fatal/stub text"
  fi
done
cmp "$OUT/guest.1.stdout" "$OUT/guest.2.stdout"
file "$OUT/openuikit.o" "$OUT/notification-bridge-guest" "$native_bin" \
  > "$OUT/file.txt"
grep -F "Mach-O 64-bit arm64 object" "$OUT/file.txt" >/dev/null
grep -F "Mach-O 64-bit arm64 executable" "$OUT/file.txt" >/dev/null
grep -F "ELF 64-bit LSB pie executable, ARM aarch64" "$OUT/file.txt" >/dev/null
echo NOTIFICATION_BRIDGE_GUEST_OK sources=102 guest_runs=2 native_runs=2 foundation=app-only
' | tee $output_root/gate.log

cat $output_root/native-elf.1.stdout
cat $output_root/guest.1.stdout
print "NOTIFICATION_BRIDGE_GUEST_GATE_OK"
