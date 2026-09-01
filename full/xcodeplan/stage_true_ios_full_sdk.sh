#!/usr/bin/env bash
# Build the narrow SDK used for the full iOS-simulator platform slice.
# Apple Darwin and Objective-C Swift overlays are deliberately staged as
# ordinary -I modules:
# the Linux Swift toolchain can consume their stable interfaces there, while
# treating the same files as SDK modules requires an exact Apple toolchain
# build identifier. The clean Clang SDK and all upstream inputs stay read-only.

set -euo pipefail

die() {
    echo "stage-true-ios-full-sdk: $*" >&2
    exit 2
}

[ "$#" -eq 3 ] || die \
    'usage: stage_true_ios_full_sdk.sh CORE_PACKAGE IPHONESIMULATOR_SDK OUTPUT_ROOT'

CORE_PACKAGE=$1
IOS_SDK=$2
OUTPUT_ROOT=$3

[ -d "$CORE_PACKAGE/sdk/usr/lib/swift" ] || die 'core package SDK is missing'
[ -d "$IOS_SDK/usr/lib/swift" ] || die 'iPhoneSimulator Swift overlays are missing'
[ ! -e "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ] \
    || die 'output root already exists; stale output is refused'

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

mkdir -p "$STAGE/sdk" "$STAGE/apple-overlays" "$STAGE/attestation"
cp -a "$CORE_PACKAGE/sdk/." "$STAGE/sdk/"

TARGET_VARIANT=arm64-apple-ios-simulator
SDK_MODULES=(
    Swift
    SwiftOnoneSupport
    Synchronization
    _Builtin_float
    _Concurrency
    _StringProcessing
)
APPLE_USER_MODULES=(
    Darwin
    _DarwinFoundation1
    _DarwinFoundation2
    _DarwinFoundation3
    ObjectiveC
)

for module_name in "${APPLE_USER_MODULES[@]}"; do
    accidental_sdk_interface="$STAGE/sdk/usr/lib/swift/$module_name.swiftmodule/$TARGET_VARIANT.swiftinterface"
    [ ! -e "$accidental_sdk_interface" ] && [ ! -L "$accidental_sdk_interface" ] \
        || die "core SDK unexpectedly contains an iOS Apple SDK interface: $module_name"
done

copy_module_variant() {
    local module_name=$1 destination_root=$2
    local source_directory="$IOS_SDK/usr/lib/swift/$module_name.swiftmodule"
    local destination_directory="$destination_root/$module_name.swiftmodule"
    mkdir -p "$destination_directory"
    for extension in swiftinterface swiftdoc; do
        local source_file="$source_directory/$TARGET_VARIANT.$extension"
        [ -f "$source_file" ] && [ ! -L "$source_file" ] \
            || die "required iOS module variant is missing: $source_file"
        cp "$source_file" "$destination_directory/"
    done
}

for module_name in "${SDK_MODULES[@]}"; do
    copy_module_variant "$module_name" "$STAGE/sdk/usr/lib/swift"
done
for module_name in "${APPLE_USER_MODULES[@]}"; do
    copy_module_variant "$module_name" "$STAGE/apple-overlays"
done

RUNTIME_TBDS=(
    libswiftCore.tbd
    libswiftSwiftOnoneSupport.tbd
    libswiftSynchronization.tbd
    libswiftDarwin.tbd
    libswiftObjectiveC.tbd
    libswift_DarwinFoundation1.tbd
    libswift_DarwinFoundation2.tbd
    libswift_DarwinFoundation3.tbd
    libswift_errno.tbd
    libswift_Builtin_float.tbd
    libswift_Concurrency.tbd
    libswift_RegexParser.tbd
    libswift_StringProcessing.tbd
)
for tbd_name in "${RUNTIME_TBDS[@]}"; do
    source_file="$IOS_SDK/usr/lib/swift/$tbd_name"
    [ -f "$source_file" ] && [ ! -L "$source_file" ] \
        || die "required iOS Swift runtime TBD is missing: $tbd_name"
    cp "$source_file" "$STAGE/sdk/usr/lib/swift/$tbd_name"
done
for tbd_name in libSystem.B.tbd libobjc.A.tbd; do
    source_file="$IOS_SDK/usr/lib/$tbd_name"
    [ -f "$source_file" ] && [ ! -L "$source_file" ] \
        || die "required iOS system TBD is missing: $tbd_name"
    cp "$source_file" "$STAGE/sdk/usr/lib/$tbd_name"
done
if [ -f "$IOS_SDK/SDKSettings.json" ] && [ ! -L "$IOS_SDK/SDKSettings.json" ]; then
    cp "$IOS_SDK/SDKSettings.json" "$STAGE/sdk/SDKSettings.json"
fi

(
    cd "$STAGE"
    find sdk/usr/lib/swift apple-overlays -type f \
        \( -name "$TARGET_VARIANT.swiftinterface" \
           -o -name "$TARGET_VARIANT.swiftdoc" \
           -o -name '*.tbd' \) -print0 \
        | sort -z | xargs -0 shasum -a 256
    shasum -a 256 sdk/usr/lib/libSystem.B.tbd sdk/usr/lib/libobjc.A.tbd
) > "$STAGE/attestation/target-sdk-inputs.sha256"
printf '%s\n' \
    'TRUE_IOS_FULL_SDK_COMPLETE target=arm64-apple-ios18.0-simulator apple-overlays=darwin,objectivec' \
    > "$STAGE/SDK_COMPLETE"

mv "$STAGE" "$OUTPUT_ROOT"
STAGE=''
trap - EXIT HUP INT TERM
echo "stage-true-ios-full-sdk: published $OUTPUT_ROOT"
