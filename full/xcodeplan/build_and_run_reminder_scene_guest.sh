#!/usr/bin/env bash
# Build and run the unchanged Reminder AppDelegate + SceneDelegate as a real
# Mach-O guest for the host triple (full/scripts/guest_arch.inc). The outer
# half generates an attested build input and mounts every subject read-only.
# The inner half reuses the modules and guest root from full/scripts/build_full.sh.
# x86_64 writes beside the arm64 tree (build/full-x86_64/scene-guest).
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
W=$(cd -- "$SCRIPT_DIR/../.." && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/../scripts/guest_arch.inc"
SCENE_OUT="$W/build/full${FULL_OUT_SUFFIX}/scene-guest"

die() {
    echo "reminder-scene-guest: $*" >&2
    exit 2
}

prepare() {
    [ "$#" -eq 2 ] || die "usage: $0 INVENTORY_JSON REMINDER_SOURCE_ROOT"
    command -v python3 >/dev/null || die "python3 is required on the host"
    # Arm64 guests cannot execute on this x86 VM (CURSOR_ENV_CANNOT_EXECUTE_ARM64).
    # x86_64 guests on an x86_64 host are the phase-2 path: do not refuse them.
    if [ "$ARCH" = arm64 ] && [ "$(uname -m)" != aarch64 ] && [ "$(uname -m)" != arm64 ]; then
        bash "$W/.cursor/refuse-arm64-execution.sh" || exit $?
    fi

    local inventory source_root uikit_checkout machorun_checkout turns
    inventory=$(realpath "$1")
    source_root=$(realpath "$2")
    [ -f "$inventory" ] || die "inventory is not a regular file: $inventory"
    [ -d "$source_root" ] || die "source root is not a directory: $source_root"
    uikit_checkout=${UIKIT_CHECKOUT:-}
    machorun_checkout=${MACHORUN_CHECKOUT:-/Users/miguelsalinas/machorun}
    [ -n "$uikit_checkout" ] || die "set UIKIT_CHECKOUT to the OpenUIKit checkout"
    uikit_checkout=$(realpath "$uikit_checkout")
    machorun_checkout=$(realpath "$machorun_checkout")
    [ -f "$uikit_checkout/Package.swift" ] || die "not an OpenUIKit checkout: $uikit_checkout"
    [ -f "$machorun_checkout/build/machorun" ] || die "machorun is not built: $machorun_checkout"
    turns=${OPENUIKIT_HOST_TURNS:-3}
    [[ "$turns" =~ ^[1-9][0-9]*$ ]] || die "OPENUIKIT_HOST_TURNS must be a positive integer"

    # SCENE_OUT is a fixed derived-output child, never an application or
    # checkout root. Recreate it so the generator's exclusive-write contract
    # also catches accidental duplicate emission within this invocation.
    rm -rf -- "$SCENE_OUT"
    mkdir -p -- "$SCENE_OUT"
    python3 "$SCRIPT_DIR/scene_bootstrap.py" "$inventory" \
        --source-root "$source_root" \
        --output "$SCENE_OUT/GeneratedSceneBootstrap.swift" \
        >"$SCENE_OUT/bootstrap-record.json"

    python3 - "$SCENE_OUT/bootstrap-record.json" "$SCENE_OUT" <<'PY'
import json
from pathlib import Path
import re
import sys

record_path = Path(sys.argv[1])
output = Path(sys.argv[2])
record = json.loads(record_path.read_text(encoding="utf-8"))
module = record["module"]
if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", module):
    raise SystemExit("generator returned an unsafe module name")
if module != "Reminder":
    raise SystemExit(f"this proof requires the Reminder module, got {module!r}")
if record["inventory_swift_source_count"] != 22:
    raise SystemExit("this proof requires Reminder's exact 22-source inventory")
if record["app_delegate"]["type"] != "AppDelegate":
    raise SystemExit("this proof requires Reminder.AppDelegate")
if record["scene_delegate"]["type"] != "SceneDelegate":
    raise SystemExit("this proof requires Reminder.SceneDelegate")
paths = [record["app_delegate"]["path"], record["scene_delegate"]["path"]]
if any("\n" in path or "\r" in path for path in paths):
    raise SystemExit("delegate paths may not contain newlines")
(output / "module-name.txt").write_text(module + "\n", encoding="utf-8")
(output / "app-sources.nul").write_bytes(
    b"".join(path.encode("utf-8") + b"\0" for path in paths)
)
inventory_count = record["inventory_swift_source_count"]
(output / "source-boundary.txt").write_text(
    "unchanged_app_sources_compiled=2\n"
    f"inventory_swift_sources={inventory_count}\n",
    encoding="utf-8",
)
(output / "app-source-hashes.sha256").write_text(
    "".join(
        f"{entry['sha256']}  {entry['path']}\n"
        for entry in (record["app_delegate"], record["scene_delegate"])
    ),
    encoding="utf-8",
)
PY

    cp -- "$inventory" "$SCENE_OUT/project-inventory.json"
    (
        cd "$SCENE_OUT"
        sha256sum GeneratedSceneBootstrap.swift bootstrap-record.json \
            project-inventory.json module-name.txt app-sources.nul \
            source-boundary.txt app-source-hashes.sha256 \
            >prepared-inputs.sha256
    )

    case "$ARCH" in
        x86_64) DOCKER_PLATFORM=linux/amd64 ;;
        *)      DOCKER_PLATFORM=linux/arm64 ;;
    esac
    # Native host with the pinned toolchain: skip docker. The inner half
    # already follows $TARGET / suffixed build/full. This holds for the arm64
    # EC2 authority (no swift-macho-spike:noble image there) exactly as for the
    # x86_64 box; docker remains the fallback when the toolchain is absent.
    case "$(uname -m)" in
        x86_64)        host_arch=x86_64 ;;
        aarch64|arm64) host_arch=arm64 ;;
        *)             host_arch=$(uname -m) ;;
    esac
    if [ "$ARCH" = "$host_arch" ] \
        && command -v swiftc >/dev/null && command -v ld64.lld-18 >/dev/null; then
        UIKIT="$uikit_checkout" MACHORUN="$machorun_checkout" \
            OPENUIKIT_HOST_TURNS="$turns" \
            bash "$SCRIPT_DIR/build_and_run_reminder_scene_guest.sh" --inside "$source_root"
        return
    fi
    command -v docker >/dev/null || die "docker is required on the host"
    docker run --rm --platform "$DOCKER_PLATFORM" \
        -e OPENUIKIT_HOST_TURNS="$turns" \
        -v "$W:/w" \
        -v "$uikit_checkout:/uikit:ro" \
        -v "$machorun_checkout:/machorun:ro" \
        -v "$source_root:/app:ro" \
        -w /w swift-macho-spike:noble \
        bash full/xcodeplan/build_and_run_reminder_scene_guest.sh --inside /app
}

build_inside() {
    [ "$#" -eq 1 ] || die "internal invocation requires the mounted source root"
    local app_root=$1
    [ -d "$app_root" ] || die "mounted source root is missing: $app_root"
    command -v swiftc >/dev/null || die "swiftc is missing from the build container"
    command -v ld64.lld-18 >/dev/null || die "ld64.lld-18 is missing from the build container"

    (cd "$SCENE_OUT" && sha256sum -c prepared-inputs.sha256)
    (cd "$app_root" && sha256sum -c "$SCENE_OUT/app-source-hashes.sha256")

    bash "$W/full/scripts/build_full.sh"

    local full="$W/build/full${FULL_OUT_SUFFIX}"
    local sys="$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}"
    local rootdir="$W/scratch/mrroot_full${FULL_OUT_SUFFIX}"
    local module turns expected_subject actual_subject
    local uikit=${UIKIT:-/uikit}
    [ -s "$full/uihelpers-subject.sha256" ] || die "build_full success marker is missing"
    expected_subject=$(bash "$W/full/scripts/uihelpers_subject.sh" "$W" "$uikit")
    actual_subject=$(tr -d '\n' <"$full/uihelpers-subject.sha256")
    [ "$expected_subject" = "$actual_subject" ] || die "build_full subject marker does not match mounted sources"
    module=$(tr -d '\n' <"$SCENE_OUT/module-name.txt")
    [[ "$module" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "unsafe generated module name"
    turns=${OPENUIKIT_HOST_TURNS:-3}
    [[ "$turns" =~ ^[1-9][0-9]*$ ]] || die "OPENUIKIT_HOST_TURNS must be a positive integer"

    local -a relative_sources app_sources
    mapfile -d '' -t relative_sources <"$SCENE_OUT/app-sources.nul"
    [ "${#relative_sources[@]}" -eq 2 ] || die "generator did not select exactly two delegate sources"
    local relative candidate
    for relative in "${relative_sources[@]}"; do
        [[ "$relative" != /* && "$relative" != *".."* ]] || die "unsafe app source path: $relative"
        candidate="$app_root/$relative"
        [ -f "$candidate" ] || die "selected app source is missing: $candidate"
        app_sources+=("$candidate")
    done

    local mc="$SCENE_OUT/module-cache"
    mkdir -p "$mc"
    local -a swiftc_flags c_flags fe_flags link_flags
    swiftc_flags=(swiftc -target "$TARGET" -sdk "$sys"
        -module-cache-path "$mc" -runtime-compatibility-version none -wmo
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module)
    c_flags=(-Xcc -I"$full/inc/CPortableIO" -Xcc -I"$full/inc/CSTBTrueType"
        -Xcc -I"$W/full/hostclock/include" -Xcc -I"$uikit/Sources/CQuartz/include")
    fe_flags=(-I "$full/foundation/essentials"
        -I "$full/foundation/collections" -I "$full/foundation/os"
        -Xcc -fmodule-map-file="$W/scratch/swift-foundation/Sources/_FoundationCShims/include/module.modulemap"
        -Xcc -I"$W/scratch/swift-foundation/Sources/_FoundationCShims/include")
    link_flags=(ld64.lld-18 -arch "$ARCH" -platform_version macos 15.0 15.0
        -syslibroot "$sys" -rpath /usr/lib/swift)

    # PortableUIKitApplicationHost now enforces the same relocatable resource
    # contract as complete application bundles. Keep this older 2/22 proof
    # honest by staging its semantic data and fonts beside the standalone
    # executable; Bundle.main resolves to SCENE_OUT for a non-bundled image.
    if find "$uikit/Sources/OpenUIKit/Resources" -type l -print -quit | grep -q .; then
        die "OpenUIKit runtime resources contain a symlink"
    fi
    mkdir -p "$SCENE_OUT/OpenUIKit/fonts"
    cp -R "$uikit/Sources/OpenUIKit/Resources/." "$SCENE_OUT/OpenUIKit/"
    install -m 0644 /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
        "$SCENE_OUT/OpenUIKit/fonts/DejaVuSans.ttf"
    install -m 0644 /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf \
        "$SCENE_OUT/OpenUIKit/fonts/DejaVuSans-Bold.ttf"
    (
        cd "$SCENE_OUT"
        find OpenUIKit -type f -print0 | sort -z | xargs -0 sha256sum \
            >open-uikit-runtime-resources.sha256
    )

    echo "== unchanged Reminder scene slice (2 app sources; generated entry point; FE-backed production host loop)"
    "${swiftc_flags[@]}" "${c_flags[@]}" "${fe_flags[@]}" \
        -I "$full" -I "$full/uikitinc" -I "$full/appinc" \
        -default-isolation MainActor -module-name "$module" \
        -emit-object -o "$SCENE_OUT/reminder-scene-guest.o" \
        "${app_sources[@]}" \
        "$SCENE_OUT/GeneratedSceneBootstrap.swift" \
        "$W/full/xcodeplan/ReminderSceneRuntimeSupport.swift" \
        "$W/full/xcodeplan/PortableUIKitApplicationHost.swift" \
        "$W/full/xcodeplan/PortableUIKitLiveTransport.swift" \
        "$W/full/driver/RunLoop.swift"

    "${link_flags[@]}" -dead_strip -exported_symbol __mh_execute_header -rpath @loader_path \
        -L"$rootdir/darwin/usr/lib" \
        -L/usr/lib/swift -lswiftCore "$rootdir/darwin/usr/lib/libswiftcompat.dylib" \
        -L/usr/lib -lSystem -lobjc "$rootdir/darwin/usr/lib/libquartz.dylib" \
        "$rootdir/darwin/usr/lib/libSystem.B.dylib" \
        -o "$SCENE_OUT/reminder-scene-guest" \
        "$SCENE_OUT/reminder-scene-guest.o" \
        "$full/uikitshim.o" "$full/foundation.o" "$full/openuikit.o" \
        "$full/opencoregraphics.o" "$full/cportableio.o" "$full/cstbtruetype.o" \
        "$full/hostclock.o" "$full/swiftcorepatch.o" \
        "$full/foundation/essentials/FoundationEssentials.o" \
        "$full/foundation/collections/InternalCollectionsUtilities.o" \
        "$full/foundation/collections/OrderedCollections.o" \
        "$full/foundation/collections/_RopeModule.o" \
        "$full/foundation/os/os.o" \
        "$full/foundation/cshims/platform_shims.o" \
        "$full/foundation/cshims/string_shims.o" \
        "$full/foundation/cshims/uuid.o" \
        "$full/foundation/essentials/uuid_compat.o" \
        "$full/foundation/essentials/fm_unimplemented.o"

    (
        cd "$SCENE_OUT"
        MACHORUN_ROOT="$rootdir" OPENUIKIT_HOST_TURNS="$turns" \
            "$rootdir/machorun" ./reminder-scene-guest
    ) | tee "$SCENE_OUT/runtime.log"

    grep -Fx "REMINDER_UNCHANGED_WILL_CONNECT_OK" "$SCENE_OUT/runtime.log" >/dev/null \
        || die "unchanged SceneDelegate willConnect marker is missing"
    grep -Fx "PORTABLE_UIKIT_HOST_ACTIVE windows=1" "$SCENE_OUT/runtime.log" >/dev/null \
        || die "active scene/window marker is missing"
    grep -Fx "PORTABLE_UIKIT_HOST_LOOP_OK turns=$turns paced=true" "$SCENE_OUT/runtime.log" >/dev/null \
        || die "bounded production host-loop marker is missing"

    file "$SCENE_OUT/reminder-scene-guest" | tee "$SCENE_OUT/file.txt"
    sha256sum "$SCENE_OUT/reminder-scene-guest" "$SCENE_OUT/runtime.log" \
        >"$SCENE_OUT/runtime-artifacts.sha256"
    echo "== reminder scene guest proof passed"
}

if [ "${1:-}" = "--inside" ]; then
    shift
    build_inside "$@"
else
    prepare "$@"
fi
