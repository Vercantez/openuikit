#!/usr/bin/env bash
# Construct and exercise a true iOS-simulator target SDK without modifying the
# source core package or any application/vendor checkout.

set -euo pipefail

die() {
    echo "true-ios-target: $*" >&2
    exit 1
}

[ "$#" -eq 4 ] || die \
    'usage: build_and_run_true_ios_target_guest.sh CORE_PACKAGE IPHONESIMULATOR_SDK CONTAINER_SHA256 OUTPUT_ROOT'

CORE_PACKAGE=$1
IOS_SDK=$2
CONTAINER_IMAGE=$3
OUTPUT_ROOT=$4
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

[ -d "$CORE_PACKAGE/sdk" ] || die 'core package SDK is missing'
[ -x "$CORE_PACKAGE/guest-root/machorun" ] || die 'core package machorun is missing'
[ -d "$IOS_SDK/usr/lib/swift" ] || die 'iPhoneSimulator Swift overlays are missing'
[ ! -e "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ] \
    || die 'output root already exists; stale output is refused'
[[ "$CONTAINER_IMAGE" =~ ^sha256:[0-9a-f]{64}$ ]] \
    || die 'container image must be an exact sha256 image ID'

ACTUAL_IMAGE=$(docker image inspect --format '{{.Id}}' "$CONTAINER_IMAGE")
[ "$ACTUAL_IMAGE" = "$CONTAINER_IMAGE" ] || die 'container image ID drifted'
IMAGE_PLATFORM=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' \
    "$CONTAINER_IMAGE")
[ "$IMAGE_PLATFORM" = linux/arm64 ] \
    || die "container platform is $IMAGE_PLATFORM, expected linux/arm64"

OUTPUT_PARENT=$(dirname -- "$OUTPUT_ROOT")
OUTPUT_BASENAME=$(basename -- "$OUTPUT_ROOT")
mkdir -p "$OUTPUT_PARENT"
STAGE=$(mktemp -d "$OUTPUT_PARENT/.${OUTPUT_BASENAME}.building.XXXXXX")
cleanup() {
    if [ -n "${STAGE:-}" ] && [ -d "$STAGE" ]; then
        rm -rf -- "$STAGE"
    fi
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$STAGE/sdk" "$STAGE/attestation"
cp -a "$CORE_PACKAGE/sdk/." "$STAGE/sdk/"

IOS_MODULES=(
    Swift
    SwiftOnoneSupport
    Synchronization
    _Builtin_float
    _Concurrency
    _StringProcessing
)
for module in "${IOS_MODULES[@]}"; do
    SOURCE_DIR="$IOS_SDK/usr/lib/swift/$module.swiftmodule"
    DESTINATION_DIR="$STAGE/sdk/usr/lib/swift/$module.swiftmodule"
    for extension in swiftinterface swiftdoc; do
        SOURCE_FILE="$SOURCE_DIR/arm64-apple-ios-simulator.$extension"
        [ -f "$SOURCE_FILE" ] && [ ! -L "$SOURCE_FILE" ] \
            || die "required iOS standard-library overlay is missing: $SOURCE_FILE"
        mkdir -p "$DESTINATION_DIR"
        cp "$SOURCE_FILE" "$DESTINATION_DIR/"
    done
done

IOS_RUNTIME_TBDS=(
    libswiftCore.tbd
    libswiftSwiftOnoneSupport.tbd
    libswiftSynchronization.tbd
    libswift_Builtin_float.tbd
    libswift_Concurrency.tbd
    libswift_RegexParser.tbd
    libswift_StringProcessing.tbd
)
for tbd in "${IOS_RUNTIME_TBDS[@]}"; do
    SOURCE_TBD="$IOS_SDK/usr/lib/swift/$tbd"
    [ -f "$SOURCE_TBD" ] && [ ! -L "$SOURCE_TBD" ] \
        || die "required iOS Swift runtime TBD is missing: $tbd"
    cp "$SOURCE_TBD" "$STAGE/sdk/usr/lib/swift/$tbd"
done
for tbd in libSystem.B.tbd libobjc.A.tbd; do
    [ -f "$IOS_SDK/usr/lib/$tbd" ] && [ ! -L "$IOS_SDK/usr/lib/$tbd" ] \
        || die "required iOS system TBD is missing: $tbd"
    cp "$IOS_SDK/usr/lib/$tbd" "$STAGE/sdk/usr/lib/$tbd"
done
if [ -f "$IOS_SDK/SDKSettings.json" ] && [ ! -L "$IOS_SDK/SDKSettings.json" ]; then
    cp "$IOS_SDK/SDKSettings.json" "$STAGE/sdk/SDKSettings.json"
fi

cp "$SCRIPT_DIR/TrueIOSTargetProbe.swift" "$STAGE/"
cp "$SCRIPT_DIR/true_ios_target_guest_inner.sh" "$STAGE/"
chmod 0755 "$STAGE/true_ios_target_guest_inner.sh"

{
    printf 'container-image\t%s\n' "$CONTAINER_IMAGE"
    printf 'core-package-complete\t%s\n' \
        "$(sha256sum "$CORE_PACKAGE/PACKAGE_COMPLETE" | awk '{print $1}')"
    (
        cd "$STAGE"
        find sdk/usr/lib/swift -type f \
            \( -name 'arm64-apple-ios-simulator.swiftinterface' \
               -o -name 'arm64-apple-ios-simulator.swiftdoc' \
               -o -name '*.tbd' \) -print0 \
            | sort -z | xargs -0 sha256sum
        sha256sum sdk/usr/lib/libSystem.B.tbd sdk/usr/lib/libobjc.A.tbd
    )
} > "$STAGE/attestation/target-sdk-inputs.tsv"

docker run --rm --network none --read-only --platform linux/arm64 \
    --tmpfs /tmp:rw,exec,mode=1777 \
    -v "$STAGE:/output:rw" \
    -v "$CORE_PACKAGE:/package:ro" \
    "$CONTAINER_IMAGE" \
    /output/true_ios_target_guest_inner.sh /output /package

[ -f "$STAGE/TrueIOSTargetProbe" ] \
    || die 'Linux guest did not produce the iOS Mach-O executable'
grep -Fxq \
    'TRUE_IOS_TRIPLE_GUEST_OK os=iOS target=arm64-apple-ios-simulator' \
    "$STAGE/attestation/runtime.log" \
    || die 'true-iOS runtime marker is missing'
rm -rf -- "$STAGE/module-cache"
printf '%s\n' \
    'TRUE_IOS_TARGET_COMPLETE target=arm64-apple-ios17.0-simulator platform=7' \
    > "$STAGE/TARGET_COMPLETE"

mv "$STAGE" "$OUTPUT_ROOT"
STAGE=''
trap - EXIT HUP INT TERM
echo "true-ios-target: published $OUTPUT_ROOT"
