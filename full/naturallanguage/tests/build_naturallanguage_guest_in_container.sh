#!/usr/bin/env bash
set -euo pipefail

W=${W:-/w}
PLATFORM=${PLATFORM:-/platform}
ICECUBES=${ICECUBES:-/icecubes}
OUTPUT=${OUTPUT:-/out}
SOURCE_COMMIT=${SOURCE_COMMIT:?SOURCE_COMMIT is required}
SOURCE_TREE=${SOURCE_TREE:?SOURCE_TREE is required}

die() {
    echo "naturallanguage_guest: $*" >&2
    exit 2
}

sha() { sha256sum "$1" | awk '{print $1}'; }

for tool in bash git swiftc ld64.lld-18 llvm-nm-18 llvm-otool-18 \
    file sha256sum cmp awk grep; do
    command -v "$tool" >/dev/null || die "missing tool: $tool"
done

[ -d "$W/full/naturallanguage" ] || die 'project source is missing'
[ -f "$PLATFORM/PLATFORM_COMPLETE" ] || die 'true-iOS platform is incomplete'
[ -d "$PLATFORM/sdk/usr/lib/swift" ] || die 'true-iOS SDK is missing'
[ -d "$PLATFORM/apple-overlays" ] || die 'Apple overlay directory is missing'
[ -d "$PLATFORM/package" ] || die 'platform modules are missing'
[ -x "$PLATFORM/runtime-root/machorun" ] || die 'machorun is missing'
[ -d "$ICECUBES/.git" ] || die 'IceCubes checkout is missing'
[ "$(git -C "$ICECUBES" rev-parse HEAD^{commit})" = \
    b2db3033fbf67a97b54d25d6dac2df8a029b26b1 ] \
    || die 'IceCubes commit drifted'
[ "$(git -C "$ICECUBES" rev-parse HEAD^{tree})" = \
    acecd527919ebd0c868f752b0ac73a2b45fdfcf5 ] \
    || die 'IceCubes tree drifted'
[ -z "$(git -C "$ICECUBES" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'IceCubes checkout is not untouched'

CONSUMER_RELATIVE=Packages/StatusKit/Sources/StatusKit/LanguageDetection/LanguageDetection.swift
EDITOR_RELATIVE=Packages/StatusKit/Sources/StatusKit/Editor/EditorStore.swift
ROW_RELATIVE=Packages/StatusKit/Sources/StatusKit/Row/StatusRowViewModel.swift
CONSUMER=$ICECUBES/$CONSUMER_RELATIVE
EDITOR=$ICECUBES/$EDITOR_RELATIVE
ROW=$ICECUBES/$ROW_RELATIVE
[ "$(sha "$CONSUMER")" = \
    f5d2ed281604303d5e3323b322c0490d1676134d50b2bb350141d9029f9f96f8 ] \
    || die 'untouched LanguageDetection.swift hash drifted'
[ "$(sha "$EDITOR")" = \
    ddbebf90c661b1a2e143f7585e578deb2633ab7bdfe28fa74bd8866875151232 ] \
    || die 'untouched EditorStore.swift hash drifted'
[ "$(sha "$ROW")" = \
    ca1cf5b24ba41ed2a18f62aca51afa40ebe1e4ce053e80c043b67fa4972bccb9 ] \
    || die 'untouched StatusRowViewModel.swift hash drifted'

case "$OUTPUT" in
    /out|/out/[A-Za-z0-9._-]*) ;;
    *) die "OUTPUT is not a narrow /out path: $OUTPUT" ;;
esac
[ ! -e "$OUTPUT" ] || [ -z "$(find "$OUTPUT" -mindepth 1 -print -quit)" ] \
    || die 'OUTPUT must not contain stale artifacts'

BUILD=$OUTPUT/build
MODULES=$OUTPUT/modules
LIB=$OUTPUT/lib
PROBE=$OUTPUT/probe
AUDIT=$OUTPUT/attestation
RUNTIME=$OUTPUT/runtime-root
mkdir -p "$BUILD/module-cache" "$MODULES" "$LIB" "$PROBE" "$AUDIT" "$RUNTIME"

RUNTIME_SOURCE=$W/full/naturallanguage/NaturalLanguage.swift
SOURCE_MANIFEST=$W/full/naturallanguage/naturallanguage_guest_sources.txt
ORACLE=$W/full/naturallanguage/tests/NaturalLanguageIceCubesOracle.swift
APPLE_GOLDEN=$W/full/naturallanguage/tests/naturallanguage-apple-26.1.txt
GENERALIZATION=$W/full/naturallanguage/tests/NaturalLanguageGeneralizationOracle.swift
GENERALIZATION_GOLDEN=$W/full/naturallanguage/tests/naturallanguage-generalization-apple-26.1.txt
FRONTIER=$W/full/naturallanguage/tests/icecubes_naturallanguage_frontier.tsv
for source in "$RUNTIME_SOURCE" "$SOURCE_MANIFEST" "$ORACLE" \
    "$APPLE_GOLDEN" "$GENERALIZATION" "$GENERALIZATION_GOLDEN" "$FRONTIER"; do
    [ -f "$source" ] && [ ! -L "$source" ] \
        || die "source input is not a regular file: $source"
done
[ "$(cat "$SOURCE_MANIFEST")" = full/naturallanguage/NaturalLanguage.swift ] \
    || die 'NaturalLanguage source manifest drifted'

write_source_subject() {
    local destination=$1 source
    {
        printf 'format\tnaturallanguage-source-subject-v1\n'
        printf 'project-commit\t%s\n' "$SOURCE_COMMIT"
        printf 'project-tree\t%s\n' "$SOURCE_TREE"
        printf 'icecubes-commit\t%s\n' \
            "$(git -C "$ICECUBES" rev-parse HEAD^{commit})"
        printf 'icecubes-tree\t%s\n' \
            "$(git -C "$ICECUBES" rev-parse HEAD^{tree})"
        for source in "$RUNTIME_SOURCE" "$SOURCE_MANIFEST" "$ORACLE" \
            "$APPLE_GOLDEN" "$GENERALIZATION" "$GENERALIZATION_GOLDEN" \
            "$FRONTIER"; do
            printf 'source\t%s\t%s\n' "${source#"$W/"}" "$(sha "$source")"
        done
        printf 'upstream-source\t%s\t%s\n' "$CONSUMER_RELATIVE" "$(sha "$CONSUMER")"
        printf 'upstream-source\t%s\t%s\n' "$EDITOR_RELATIVE" "$(sha "$EDITOR")"
        printf 'upstream-source\t%s\t%s\n' "$ROW_RELATIVE" "$(sha "$ROW")"
        printf 'platform-complete\t%s\n' "$(sha "$PLATFORM/PLATFORM_COMPLETE")"
    } > "$destination"
}
write_source_subject "$AUDIT/source-subject.before.tsv"

TARGET=arm64-apple-ios18.0-simulator
SWIFTC=(swiftc -target "$TARGET" -sdk "$PLATFORM/sdk"
    -I "$PLATFORM/apple-overlays" -I "$PLATFORM/package"
    -module-cache-path "$BUILD/module-cache"
    -runtime-compatibility-version none -wmo
    -Xfrontend -enable-cross-import-overlays
    -Xfrontend -disable-objc-attr-requires-foundation-module)
CFLAGS=(
    -Xcc -I"$PLATFORM/platform-include/CPortableIO"
    -Xcc -I"$PLATFORM/platform-include/CSTBTrueType"
    -Xcc -I"$PLATFORM/platform-include/CHostClock"
    -Xcc -I"$PLATFORM/platform-include/COpenCombineHelpers"
    -Xcc -I"$PLATFORM/platform-include/CQuartz"
    -Xcc -fmodule-map-file="$PLATFORM/platform-include/COpenURLTransport/module.modulemap"
    -Xcc -I"$PLATFORM/platform-include/COpenURLTransport"
    -Xcc -fmodule-map-file="$PLATFORM/platform-include/COpenRelativeTime/module.modulemap"
    -Xcc -I"$PLATFORM/platform-include/COpenRelativeTime"
    -Xcc -fmodule-map-file="$PLATFORM/platform-include/COpenDispatch/module.modulemap"
    -Xcc -I"$PLATFORM/platform-include/COpenDispatch"
    -Xcc -fmodule-map-file="$PLATFORM/platform-include/COpenFoundationCore/module.modulemap"
    -Xcc -I"$PLATFORM/platform-include/COpenFoundationCore"
    -Xcc -fmodule-map-file="$PLATFORM/platform-include/_FoundationCShims/module.modulemap"
    -Xcc -I"$PLATFORM/platform-include/_FoundationCShims"
)

echo '== compile portable NaturalLanguage ARM64 Mach-O module'
"${SWIFTC[@]}" "${CFLAGS[@]}" -parse-as-library \
    -module-name NaturalLanguage \
    -emit-module -emit-module-path "$MODULES/NaturalLanguage.swiftmodule" \
    -emit-object -o "$BUILD/NaturalLanguage.o" "$RUNTIME_SOURCE"
for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json; do
    [ -f "$MODULES/NaturalLanguage.$suffix" ] \
        || die "NaturalLanguage.$suffix was not emitted"
done
llvm-otool-18 -hv "$BUILD/NaturalLanguage.o" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]OBJECT' \
    || die 'NaturalLanguage target object is not ARM64 Mach-O'

LD=(ld64.lld-18 -arch arm64 -platform_version ios-simulator 18.0 26.1 \
    -syslibroot "$PLATFORM/sdk")
COMMON_RUNTIME=(
    -L"$PLATFORM/runtime-root/darwin/usr/lib/swift"
    -L"$PLATFORM/runtime-root/darwin/usr/lib"
    -L"$PLATFORM/products"
    -L/usr/lib/swift -lswiftCore -L/usr/lib -lSystem
)

echo '== link libNaturalLanguage.dylib'
"${LD[@]}" -dylib -install_name /usr/lib/libNaturalLanguage.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    "${COMMON_RUNTIME[@]}" -lFoundation -lFoundationEssentials \
    -o "$LIB/libNaturalLanguage.dylib" "$BUILD/NaturalLanguage.o" \
    "$PLATFORM/runtime-root/darwin/usr/lib/libSystem.B.dylib"
llvm-otool-18 -hv "$LIB/libNaturalLanguage.dylib" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'libNaturalLanguage is not an ARM64 Mach-O dylib'
[ "$(llvm-otool-18 -D "$LIB/libNaturalLanguage.dylib" | tail -n 1)" = \
    /usr/lib/libNaturalLanguage.dylib ] \
    || die 'libNaturalLanguage install name drifted'
[ "$(llvm-nm-18 --defined-only --extern-only "$LIB/libNaturalLanguage.dylib" \
    | grep -c 'NLLanguageRecognizer')" -gt 0 ] \
    || die 'libNaturalLanguage has no NLLanguageRecognizer exports'
if llvm-otool-18 -L "$LIB/libNaturalLanguage.dylib" \
    | grep -Fq '/System/Library/Frameworks/NaturalLanguage.framework/'; then
    die 'portable dylib loads Apple NaturalLanguage.framework'
fi

echo '== compile exact untouched IceCubes language consumer and oracle'
"${SWIFTC[@]}" "${CFLAGS[@]}" -parse-as-library -I "$MODULES" \
    -module-name NaturalLanguageIceCubesConsumer -emit-object \
    -o "$BUILD/NaturalLanguageIceCubesConsumer.o" "$CONSUMER" "$ORACLE"
"${LD[@]}" -exported_symbol __mh_execute_header \
    -o "$PROBE/NaturalLanguageIceCubesConsumer" \
    "$BUILD/NaturalLanguageIceCubesConsumer.o" \
    -L"$LIB" -lNaturalLanguage "${COMMON_RUNTIME[@]}" \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    -lswift_StringProcessing -lswift_RegexParser \
    "$PLATFORM/runtime-root/darwin/usr/lib/libSystem.B.dylib"
llvm-otool-18 -hv "$PROBE/NaturalLanguageIceCubesConsumer" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'NaturalLanguage consumer is not an ARM64 Mach-O executable'
[ "$(llvm-otool-18 -L "$PROBE/NaturalLanguageIceCubesConsumer" \
    | awk '$1 == "/usr/lib/libNaturalLanguage.dylib" { count++ } END { print count + 0 }')" -eq 1 ] \
    || die 'NaturalLanguage consumer dylib load count is not one'

echo '== compile independent 29-language generalization oracle'
"${SWIFTC[@]}" "${CFLAGS[@]}" -I "$MODULES" \
    -module-name NaturalLanguageGeneralizationOracle -emit-object \
    -o "$BUILD/NaturalLanguageGeneralizationOracle.o" "$GENERALIZATION"
"${LD[@]}" -exported_symbol __mh_execute_header \
    -o "$PROBE/NaturalLanguageGeneralizationOracle" \
    "$BUILD/NaturalLanguageGeneralizationOracle.o" \
    -L"$LIB" -lNaturalLanguage "${COMMON_RUNTIME[@]}" \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    "$PLATFORM/runtime-root/darwin/usr/lib/libSystem.B.dylib"
llvm-otool-18 -hv "$PROBE/NaturalLanguageGeneralizationOracle" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'NaturalLanguage generalization oracle is not ARM64 Mach-O'
[ "$(llvm-otool-18 -L "$PROBE/NaturalLanguageGeneralizationOracle" \
    | awk '$1 == "/usr/lib/libNaturalLanguage.dylib" { count++ } END { print count + 0 }')" -eq 1 ] \
    || die 'NaturalLanguage generalization dylib load count is not one'

echo '== cold-run exact Apple differential against fresh runtime closure'
cp -a "$PLATFORM/runtime-root/." "$RUNTIME/"
cp "$LIB/libNaturalLanguage.dylib" \
    "$RUNTIME/darwin/usr/lib/libNaturalLanguage.dylib"
(
    cd "$OUTPUT"
    LD_LIBRARY_PATH="$RUNTIME/host" \
    LD_PRELOAD="$RUNTIME/host/libOpenDispatchHost.so:$RUNTIME/host/libOpenFoundationInternationalizationHost.so:$RUNTIME/host/libOpenURLTransportHost.so:$RUNTIME/host/libOpenRelativeTimeHost.so" \
    MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/NaturalLanguageIceCubesConsumer
) | tee "$AUDIT/runtime.log"
cmp "$AUDIT/runtime.log" "$APPLE_GOLDEN" \
    || die 'portable NaturalLanguage transcript differs from Apple 26.1'
(
    cd "$OUTPUT"
    LD_LIBRARY_PATH="$RUNTIME/host" \
    LD_PRELOAD="$RUNTIME/host/libOpenDispatchHost.so:$RUNTIME/host/libOpenFoundationInternationalizationHost.so:$RUNTIME/host/libOpenURLTransportHost.so:$RUNTIME/host/libOpenRelativeTimeHost.so" \
    MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/NaturalLanguageGeneralizationOracle
) | tee "$AUDIT/generalization-runtime.log"
cmp "$AUDIT/generalization-runtime.log" "$GENERALIZATION_GOLDEN" \
    || die 'portable NaturalLanguage generalization differs from Apple 26.1'

write_source_subject "$AUDIT/source-subject.after.tsv"
cmp "$AUDIT/source-subject.before.tsv" "$AUDIT/source-subject.after.tsv" \
    || die 'NaturalLanguage or untouched IceCubes inputs changed during build'

{
    printf 'format\tnaturallanguage-artifacts-v1\n'
    for artifact in \
        modules/NaturalLanguage.swiftmodule \
        modules/NaturalLanguage.swiftdoc \
        modules/NaturalLanguage.swiftsourceinfo \
        modules/NaturalLanguage.abi.json \
        lib/libNaturalLanguage.dylib \
        probe/NaturalLanguageIceCubesConsumer \
        probe/NaturalLanguageGeneralizationOracle \
        attestation/runtime.log \
        attestation/generalization-runtime.log \
        attestation/source-subject.before.tsv \
        attestation/source-subject.after.tsv; do
        printf '%s\t%s\n' "$artifact" "$(sha "$OUTPUT/$artifact")"
    done
} > "$AUDIT/artifacts.sha256.tsv"

printf 'NATURALLANGUAGE_ARM64_PLATFORM_OK module=NaturalLanguage dylib=1 consumer=IceCubes-untouched target=%s apple-differential=exact classifier=script,trigram hints=real constraints=real generalization=29/29\n' \
    "$TARGET" | tee "$OUTPUT/NATURALLANGUAGE_COMPLETE"
