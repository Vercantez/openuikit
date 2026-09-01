#!/usr/bin/env bash
set -euo pipefail

W=${W:-/w}
PLATFORM=${PLATFORM:-/platform}
ICECUBES=${ICECUBES:-/icecubes}
OUTPUT=${OUTPUT:-/out}
SOURCE_COMMIT=${SOURCE_COMMIT:?SOURCE_COMMIT is required}
SOURCE_TREE=${SOURCE_TREE:?SOURCE_TREE is required}

die() {
    echo "foundationmodels_guest: $*" >&2
    exit 2
}

sha() { sha256sum "$1" | awk '{print $1}'; }

for tool in bash git swiftc ld64.lld-18 llvm-nm-18 llvm-otool-18 \
    readelf file ldd sha256sum cmp awk grep; do
    command -v "$tool" >/dev/null || die "missing tool: $tool"
done

[ -d "$W/full/foundationmodels" ] || die 'project source is missing'
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

AIPROMPT=$ICECUBES/Packages/StatusKit/Sources/StatusKit/Editor/Components/AIPrompt.swift
EDITORSTORE=$ICECUBES/Packages/StatusKit/Sources/StatusKit/Editor/EditorStore.swift
[ "$(sha "$AIPROMPT")" = \
    f21a16b2e7422e89410b2b6852e6b6b250c4599c2f4906796748486bdf2cd3fe ] \
    || die 'untouched AIPrompt.swift hash drifted'
[ "$(sha "$EDITORSTORE")" = \
    ddbebf90c661b1a2e143f7585e578deb2633ab7bdfe28fa74bd8866875151232 ] \
    || die 'untouched EditorStore.swift hash drifted'

case "$OUTPUT" in
    /out|/out/[A-Za-z0-9._-]*) ;;
    *) die "OUTPUT is not a narrow /out path: $OUTPUT" ;;
esac
[ ! -e "$OUTPUT" ] || [ -z "$(find "$OUTPUT" -mindepth 1 -print -quit)" ] \
    || die 'OUTPUT must not contain stale artifacts'

BUILD=$OUTPUT/build
MODULES=$OUTPUT/modules
LIB=$OUTPUT/lib
HOST_ROOT=$OUTPUT/host-tools/swift/host
HOST_LINUX=$OUTPUT/host-tools/swift/linux
HOST_TOOLS=$HOST_ROOT/plugins
PROBE=$OUTPUT/probe
AUDIT=$OUTPUT/attestation
RUNTIME=$OUTPUT/runtime-root
mkdir -p "$BUILD/module-cache" "$MODULES" "$LIB" "$HOST_TOOLS" \
    "$HOST_LINUX" "$PROBE" "$AUDIT" "$RUNTIME"

RUNTIME_SOURCE=$W/full/foundationmodels/FoundationModels.swift
MACRO_SOURCE=$W/full/foundationmodels/FoundationModelsMacros.swift
CONSUMER=$W/full/foundationmodels/tests/IceCubesFoundationModelsConsumer.swift
APPLE_ORACLE=$W/full/foundationmodels/tests/FoundationModelsNativeOracle.swift
APPLE_GOLDEN=$W/full/foundationmodels/tests/foundationmodels-apple-26.1.txt
FRONTIER=$W/full/foundationmodels/tests/icecubes_foundationmodels_frontier.tsv
for source in "$RUNTIME_SOURCE" "$MACRO_SOURCE" "$CONSUMER" \
    "$APPLE_ORACLE" "$APPLE_GOLDEN" "$FRONTIER"; do
    [ -f "$source" ] && [ ! -L "$source" ] \
        || die "source input is not a regular file: $source"
done

{
    printf 'format\tfoundationmodels-source-subject-v1\n'
    printf 'project-commit\t%s\n' "$SOURCE_COMMIT"
    printf 'project-tree\t%s\n' "$SOURCE_TREE"
    printf 'icecubes-commit\t%s\n' \
        "$(git -C "$ICECUBES" rev-parse HEAD^{commit})"
    printf 'icecubes-tree\t%s\n' \
        "$(git -C "$ICECUBES" rev-parse HEAD^{tree})"
    for source in "$RUNTIME_SOURCE" "$MACRO_SOURCE" "$CONSUMER" \
        "$APPLE_ORACLE" "$APPLE_GOLDEN" "$FRONTIER"; do
        printf 'source\t%s\t%s\n' "${source#"$W/"}" "$(sha "$source")"
    done
    printf 'upstream-source\t%s\t%s\n' \
        'Packages/StatusKit/Sources/StatusKit/Editor/Components/AIPrompt.swift' \
        "$(sha "$AIPROMPT")"
    printf 'upstream-source\t%s\t%s\n' \
        'Packages/StatusKit/Sources/StatusKit/Editor/EditorStore.swift' \
        "$(sha "$EDITORSTORE")"
} > "$AUDIT/source-subject.tsv"

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
PLUGIN=$HOST_TOOLS/libFoundationModelsMacros.so

echo '== build relocatable native FoundationModels macro plugin'
for library in \
    libSwiftSyntaxMacros.so libSwiftSyntaxBuilder.so libSwiftParserDiagnostics.so \
    libSwiftBasicFormat.so libSwiftParser.so libSwiftDiagnostics.so \
    libSwiftSyntax.so; do
    cp "$PLATFORM/host-tools/swift/host/$library" "$HOST_ROOT/$library"
done
for library in \
    libswiftCore.so libswift_Concurrency.so libswiftGlibc.so libdispatch.so \
    libswift_Builtin_float.so libBlocksRuntime.so libswiftSwiftOnoneSupport.so \
    libswift_StringProcessing.so libswift_RegexParser.so; do
    cp "$PLATFORM/host-tools/swift/linux/$library" "$HOST_LINUX/$library"
done
swiftc -parse-as-library -emit-library -module-name FoundationModelsMacros \
    -no-toolchain-stdlib-rpath -I /usr/lib/swift/host -L /usr/lib/swift/host \
    -Xlinker -rpath -Xlinker '$ORIGIN/..' \
    -Xlinker -rpath -Xlinker '$ORIGIN/../../../swift/linux' \
    "$MACRO_SOURCE" -o "$PLUGIN"
file "$PLUGIN" | grep -Eq 'ELF 64-bit.*(ARM aarch64|aarch64)' \
    || die 'FoundationModels macro plugin is not native ELF64/aarch64'
readelf -h "$PLUGIN" | grep -Eq 'Machine:[[:space:]]+AArch64' \
    || die 'FoundationModels macro plugin machine is not AArch64'
LD_LIBRARY_PATH="$HOST_ROOT:$HOST_LINUX" \
    ldd "$PLUGIN" | grep -Fq 'not found' \
    && die 'FoundationModels macro plugin closure is incomplete'

echo '== compile portable FoundationModels ARM64 Mach-O module'
"${SWIFTC[@]}" "${CFLAGS[@]}" -parse-as-library \
    -load-plugin-library "$PLUGIN" -module-name FoundationModels \
    -emit-module -emit-module-path "$MODULES/FoundationModels.swiftmodule" \
    -emit-object -o "$BUILD/FoundationModels.o" "$RUNTIME_SOURCE"
for suffix in swiftmodule swiftdoc swiftsourceinfo abi.json; do
    [ -f "$MODULES/FoundationModels.$suffix" ] \
        || die "FoundationModels.$suffix was not emitted"
done
llvm-otool-18 -hv "$BUILD/FoundationModels.o" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]OBJECT' \
    || die 'FoundationModels target object is not ARM64 Mach-O'

LD=(ld64.lld-18 -arch arm64 -platform_version ios-simulator 18.0 26.1 \
    -syslibroot "$PLATFORM/sdk")
COMMON_RUNTIME=(
    -L"$PLATFORM/runtime-root/darwin/usr/lib/swift"
    -L"$PLATFORM/runtime-root/darwin/usr/lib"
    -L"$PLATFORM/products"
    -L/usr/lib/swift -lswiftCore -lswift_Concurrency
    -L/usr/lib -lSystem
)

echo '== link libFoundationModels.dylib'
"${LD[@]}" -dylib -install_name /usr/lib/libFoundationModels.dylib \
    -current_version 1.0 -compatibility_version 1.0 \
    "${COMMON_RUNTIME[@]}" -lFoundation -lFoundationEssentials \
    -o "$LIB/libFoundationModels.dylib" "$BUILD/FoundationModels.o" \
    "$PLATFORM/runtime-root/darwin/usr/lib/libSystem.B.dylib"
llvm-otool-18 -hv "$LIB/libFoundationModels.dylib" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'libFoundationModels is not an ARM64 Mach-O dylib'
[ "$(llvm-nm-18 --defined-only --extern-only "$LIB/libFoundationModels.dylib" \
    | grep -c 'SystemLanguageModel')" -gt 0 ] \
    || die 'libFoundationModels has no SystemLanguageModel exports'
if llvm-otool-18 -L "$LIB/libFoundationModels.dylib" \
    | grep -Fq '/System/Library/Frameworks/FoundationModels.framework/'; then
    die 'portable dylib loads Apple FoundationModels.framework'
fi

echo '== expand macros and compile exact IceCubes API consumer'
"${SWIFTC[@]}" "${CFLAGS[@]}" -parse-as-library -I "$MODULES" \
    -load-plugin-library "$PLUGIN" -typecheck -dump-macro-expansions \
    "$CONSUMER" > "$AUDIT/macro-expansions.log" 2>&1
for expansion in \
    'static var generationSchema' \
    'var generatedContent' \
    'struct PartiallyGenerated' \
    'extension Tags: FoundationModels.Generable' \
    'guides: [.count(5)]'; do
    grep -Fq "$expansion" "$AUDIT/macro-expansions.log" \
        || die "macro expansion is missing: $expansion"
done
"${SWIFTC[@]}" "${CFLAGS[@]}" -parse-as-library -I "$MODULES" \
    -load-plugin-library "$PLUGIN" -module-name IceCubesFoundationModelsConsumer \
    -emit-object -o "$BUILD/IceCubesFoundationModelsConsumer.o" "$CONSUMER"
"${LD[@]}" -exported_symbol __mh_execute_header \
    -o "$PROBE/IceCubesFoundationModelsConsumer" \
    "$BUILD/IceCubesFoundationModelsConsumer.o" \
    -L"$LIB" -lFoundationModels "${COMMON_RUNTIME[@]}" \
    -lFoundation -lFoundationInternationalization -lFoundationEssentials \
    "$PLATFORM/runtime-root/darwin/usr/lib/libSystem.B.dylib"
llvm-otool-18 -hv "$PROBE/IceCubesFoundationModelsConsumer" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'FoundationModels consumer is not an ARM64 Mach-O executable'
[ "$(llvm-otool-18 -L "$PROBE/IceCubesFoundationModelsConsumer" \
    | awk '$1 == "/usr/lib/libFoundationModels.dylib" { count++ } END { print count + 0 }')" -eq 1 ] \
    || die 'FoundationModels consumer dylib load count is not one'

echo '== cold-run against a fresh runtime closure'
cp -a "$PLATFORM/runtime-root/." "$RUNTIME/"
cp "$LIB/libFoundationModels.dylib" \
    "$RUNTIME/darwin/usr/lib/libFoundationModels.dylib"
(
    cd "$OUTPUT"
    LD_LIBRARY_PATH="$RUNTIME/host" \
    LD_PRELOAD="$RUNTIME/host/libOpenDispatchHost.so:$RUNTIME/host/libOpenFoundationInternationalizationHost.so:$RUNTIME/host/libOpenURLTransportHost.so:$RUNTIME/host/libOpenRelativeTimeHost.so" \
    MACHORUN_ROOT="$RUNTIME" \
        "$RUNTIME/machorun" ./probe/IceCubesFoundationModelsConsumer
) | tee "$AUDIT/runtime.log"
grep -Fxq \
    'FOUNDATIONMODELS_GUEST_MACHO_OK macro=generable guide=count generated=roundtrip direct=fail-closed stream=fail-closed available=false' \
    "$AUDIT/runtime.log" \
    || die 'FoundationModels cold runtime marker is missing'
head -n 4 "$AUDIT/runtime.log" > "$AUDIT/apple-comparable.txt"
cmp "$AUDIT/apple-comparable.txt" "$APPLE_GOLDEN" \
    || die 'portable generated-content transcript differs from Apple 26.1'

{
    printf 'format\tfoundationmodels-artifacts-v1\n'
    for artifact in \
        modules/FoundationModels.swiftmodule \
        modules/FoundationModels.swiftdoc \
        modules/FoundationModels.swiftsourceinfo \
        modules/FoundationModels.abi.json \
        lib/libFoundationModels.dylib \
        host-tools/swift/host/plugins/libFoundationModelsMacros.so \
        probe/IceCubesFoundationModelsConsumer \
        attestation/macro-expansions.log \
        attestation/runtime.log \
        attestation/source-subject.tsv; do
        printf '%s\t%s\n' "$artifact" "$(sha "$OUTPUT/$artifact")"
    done
} > "$AUDIT/artifacts.sha256.tsv"

printf 'FOUNDATIONMODELS_ARM64_PLATFORM_OK module=FoundationModels dylib=1 plugin=ELF-aarch64 macro=Generable,Guide consumer=IceCubes target=%s apple-differential=exact service=fail-closed\n' \
    "$TARGET" | tee "$OUTPUT/FOUNDATIONMODELS_COMPLETE"
