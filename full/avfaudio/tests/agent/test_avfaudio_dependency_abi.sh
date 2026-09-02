#!/usr/bin/env bash
set -euo pipefail

die() {
    printf 'AVFAUDIO_DEPENDENCY_ABI_GATE_REFUSING: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR=$(unset CDPATH; cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
FRAMEWORK_ROOT=$(unset CDPATH; cd -- "$SCRIPT_DIR/../.." && pwd -P)
REPO_ROOT=$(git -C "$FRAMEWORK_ROOT" rev-parse --show-toplevel 2>/dev/null) \
    || die 'framework is not inside a Git worktree'
MANIFEST=$FRAMEWORK_ROOT/avfaudio_guest_sources.txt

[ -f "$MANIFEST" ] && [ ! -L "$MANIFEST" ] || die 'guest source manifest is missing or unsafe'
command -v swiftc >/dev/null 2>&1 || die 'swiftc is unavailable'
command -v clang >/dev/null 2>&1 || die 'clang is unavailable'

mode=${1:-canonical}
if [ "$#" -gt 0 ]; then
    shift
fi
swift_args=()
clang_args=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        --swift-arg)
            [ "$#" -ge 2 ] || die '--swift-arg requires one argument'
            swift_args+=("$2")
            shift 2
            ;;
        --clang-arg)
            [ "$#" -ge 2 ] || die '--clang-arg requires one argument'
            clang_args+=("$2")
            shift 2
            ;;
        *) die "unknown argument: $1" ;;
    esac
done

if [ -d /private/tmp ] && [ -w /private/tmp ]; then
    BUILD_PARENT=/private/tmp
else
    BUILD_PARENT=/tmp
fi
TMP=$(mktemp -d "$BUILD_PARENT/avfaudio-dependency-abi.XXXXXX") \
    || die 'cannot create temporary build directory'
cleanup() {
    case "$TMP" in
        /tmp/avfaudio-dependency-abi.*|/private/tmp/avfaudio-dependency-abi.*)
            find "$TMP" -depth -delete
            ;;
        *) printf 'AVFAUDIO_DEPENDENCY_ABI_GATE_REFUSING: unsafe cleanup path\n' >&2 ;;
    esac
}
trap cleanup EXIT HUP INT TERM

SOURCE_PATHS=()
while IFS= read -r relative; do
    [ -n "$relative" ] || die 'guest source manifest contains a blank row'
    case "$relative" in
        full/avfaudio/*.swift) ;;
        *) die "guest source is outside AVFAudio: $relative" ;;
    esac
    source=$REPO_ROOT/$relative
    [ -f "$source" ] && [ ! -L "$source" ] || die "guest source is missing or unsafe: $relative"
    SOURCE_PATHS+=("$source")
done < "$MANIFEST"
[ "${#SOURCE_PATHS[@]}" -gt 0 ] || die 'guest source manifest is empty'

build_avfaudio() {
    swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
        "${swift_args[@]}" \
        -module-name AVFAudio \
        -emit-module-path "$TMP/AVFAudio.swiftmodule" \
        -o "$TMP/libAVFAudio.dylib" \
        "${SOURCE_PATHS[@]}"
}

run_canonical_probe() {
    build_avfaudio
    printf '%s\n' \
        'import AVFAudio' \
        'import Foundation' \
        'func requireCopying(_ value: any NSCopying) {}' \
        'func requireMutableCopying(_ value: any NSMutableCopying) {}' \
        'func verifyBufferSurface(_ buffer: AVAudioBuffer) {' \
        '    requireCopying(buffer)' \
        '    requireMutableCopying(buffer)' \
        '}' > "$TMP/AVAudioBufferCopyingSurface.swift"
    swiftc -warnings-as-errors -typecheck -I "$TMP" \
        "$TMP/AVAudioBufferCopyingSurface.swift"

    printf '%s\n' \
        'import AVFAudio' \
        'let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!' \
        'let _ = AVAudioBuffer(format: format)' \
        > "$TMP/AVAudioBufferAbsentInitializer.swift"
    if swiftc -warnings-as-errors -typecheck -I "$TMP" \
        "$TMP/AVAudioBufferAbsentInitializer.swift" >"$TMP/absent-initializer.log" 2>&1; then
        die 'graph-absent AVAudioBuffer.init(format:) remains public'
    fi

    clang -Werror "${clang_args[@]}" -c \
        "$SCRIPT_DIR/AVFAudioDependencyABI.c" \
        -o "$TMP/AVFAudioDependencyABI.o"
    swiftc -warnings-as-errors "${swift_args[@]}" -I "$TMP" \
        "$SCRIPT_DIR/AVFAudioDependencyABI.swift" \
        "$TMP/AVFAudioDependencyABI.o" \
        "$TMP/libAVFAudio.dylib" \
        -o "$TMP/avfaudio-dependency-abi"

    case "$(uname -s)" in
        Darwin)
            output=$(DYLD_LIBRARY_PATH="$TMP${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
                "$TMP/avfaudio-dependency-abi")
            ;;
        *)
            output=$(LD_LIBRARY_PATH="$TMP${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
                "$TMP/avfaudio-dependency-abi")
            ;;
    esac
    printf '%s\n' "$output"
    printf '%s\n' "$output" | grep -Fqx 'AVFAUDIO_DEPENDENCY_ABI_OK' \
        || die 'mixed C/Swift dependency ABI probe did not emit its success marker'
    printf '%s\n' \
        'AVFAUDIO_CANONICAL_DEPENDENCY_ABI_GATE_OK checks=copying-surface,absent-extra-init,c-layout,flexible-abl,identity,load,fail-closed'
}

run_repository_boundary() {
    [ "${#swift_args[@]}" -eq 0 ] \
        || die 'repository mode does not accept custom Swift arguments'
    [ "${#clang_args[@]}" -eq 0 ] \
        || die 'repository mode does not accept custom Clang arguments'
    swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
        -module-name AudioToolbox \
        -emit-module-path "$TMP/AudioToolbox.swiftmodule" \
        -o "$TMP/libAudioToolbox.dylib" \
        "$REPO_ROOT/full/audiotoolbox/AudioToolbox.swift"
    swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
        -module-name CoreMedia \
        -emit-module-path "$TMP/CoreMedia.swiftmodule" \
        -o "$TMP/libCoreMedia.dylib" \
        "$REPO_ROOT/full/coremedia/CoreMedia.swift"

    if swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
        -I "$TMP" -L "$TMP" -lAudioToolbox -lCoreMedia \
        -module-name AVFAudio \
        -emit-module-path "$TMP/AVFAudio.swiftmodule" \
        -o "$TMP/libAVFAudio.dylib" \
        "${SOURCE_PATHS[@]}" >"$TMP/repository-boundary.log" 2>&1; then
        printf '%s\n' \
            'AVFAUDIO_REPOSITORY_DEPENDENCY_INTEGRATION_OK modules=AudioToolbox,CoreMedia'
        return
    fi

    if ! grep -Eq \
        "ambiguous for type lookup|cannot find type 'CMAudioFormatDescription'|cannot find type 'MusicSequence'|cannot find (type )?'AudioComponent|cannot find type 'AUAudioUnit'" \
        "$TMP/repository-boundary.log"; then
        sed -n '1,240p' "$TMP/repository-boundary.log" >&2
        die 'repository dependency build failed outside the classified dependency boundary'
    fi
    sed -n '1,240p' "$TMP/repository-boundary.log" >&2
    printf '%s\n' \
        'AVFAUDIO_REPOSITORY_DEPENDENCY_BOUNDARY_UNRESOLVED modules=CoreAudioTypes,AudioToolbox,CoreMedia policy=no-lookalikes' >&2
    die 'repository AudioToolbox/CoreMedia modules do not yet provide the canonical dependency ABI'
}

case "$mode" in
    canonical) run_canonical_probe ;;
    repository) run_repository_boundary ;;
    *) die "mode must be canonical or repository: $mode" ;;
esac
