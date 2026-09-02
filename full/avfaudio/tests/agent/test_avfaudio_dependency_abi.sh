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
command -v python3 >/dev/null 2>&1 || die 'python3 is unavailable'

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

classify_repository_diagnostics() {
    python3 -B - "$1" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
wrapper = re.compile(r"^error: emit-module command failed with exit code ")
source_error = re.compile(r"^.*:\d+:\d+: error: (.*)$")
allowed = [
    re.compile(
        r"'(?:AudioStreamBasicDescription|AudioBuffer)' is ambiguous "
        r"for type lookup in this context$"
    ),
    re.compile(
        r"cannot find type '(?:CMAudioFormatDescription|MusicSequence|"
        r"AudioComponentDescription|AudioComponentInstantiationOptions|"
        r"AudioComponent|AudioUnit|AUAudioUnit)' in scope$"
    ),
    re.compile(
        r"cannot find '(?:AudioComponentDescription|AudioUnit)' in scope$"
    ),
]
boundary = []
unexpected = []
for line in lines:
    if wrapper.match(line):
        continue
    match = source_error.match(line)
    if match:
        if any(pattern.fullmatch(match.group(1)) for pattern in allowed):
            boundary.append(line)
        else:
            unexpected.append(line)
    elif line.startswith("error:") or line.startswith("clang: error:"):
        unexpected.append(line)
    elif line and not line[0].isspace() and ": error:" in line:
        unexpected.append(line)

if not boundary or unexpected:
    for line in unexpected:
        print(f"UNCLASSIFIED_REPOSITORY_DIAGNOSTIC: {line}", file=sys.stderr)
    raise SystemExit(1)
PY
}

repo_libraries=()
build_repository_dependency() {
    local module=$1
    local slug=$2
    local dependency_manifest=$REPO_ROOT/full/$slug/${slug}_guest_sources.txt
    local dependency_log=$TMP/$module-build.log
    local dependency_sources=()
    local relative source

    while IFS= read -r relative; do
        [ -n "$relative" ] || die "$module source manifest contains a blank row"
        case "$relative" in
            full/"$slug"/*.swift) ;;
            *) die "$module source is outside full/$slug: $relative" ;;
        esac
        source=$REPO_ROOT/$relative
        [ -f "$source" ] && [ ! -L "$source" ] \
            || die "$module source is missing or unsafe: $relative"
        dependency_sources+=("$source")
    done < "$dependency_manifest"
    [ "${#dependency_sources[@]}" -gt 0 ] || die "$module source manifest is empty"

    if ! swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
        -I "$TMP" -L "$TMP" \
        -module-name "$module" \
        -emit-module-path "$TMP/$module.swiftmodule" \
        -o "$TMP/lib$module.dylib" \
        "${dependency_sources[@]}" "${repo_libraries[@]}" \
        >"$dependency_log" 2>&1; then
        sed -n '1,240p' "$dependency_log" >&2
        printf 'AVFAUDIO_REPOSITORY_DEPENDENCY_BUILD_UNRESOLVED module=%s\n' \
            "$module" >&2
        die "repository dependency module failed to build: $module"
    fi
    repo_libraries+=("$TMP/lib$module.dylib")
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
    grep -Eq \
        "'AVAudioBuffer' initializer is inaccessible due to 'internal' protection level" \
        "$TMP/absent-initializer.log" \
        || die 'absent-initializer probe failed for an unexpected reason'

    printf '%s\n' \
        'import AVFAudio' \
        'let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!' \
        'let buffer = AVAudioCompressedBuffer(format: format, packetCapacity: 1)' \
        'buffer.packetDescriptions = nil' \
        > "$TMP/AVAudioCompressedBufferGetOnly.swift"
    if swiftc -warnings-as-errors -typecheck -I "$TMP" \
        "$TMP/AVAudioCompressedBufferGetOnly.swift" >"$TMP/get-only.log" 2>&1; then
        die 'graph-get-only AVAudioCompressedBuffer.packetDescriptions remains settable'
    fi
    grep -Eq "setter is inaccessible|cannot assign to property" "$TMP/get-only.log" \
        || die 'get-only property probe failed for an unexpected reason'

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
        'AVFAUDIO_CANONICAL_DEPENDENCY_ABI_GATE_OK checks=all-dependencies,copying-surface,copying-semantics,absent-extra-init,get-only-surface,c-layout,flexible-abl,identity,exact-load,fail-closed'
}

run_repository_boundary() {
    [ "${#swift_args[@]}" -eq 0 ] \
        || die 'repository mode does not accept custom Swift arguments'
    [ "${#clang_args[@]}" -eq 0 ] \
        || die 'repository mode does not accept custom Clang arguments'
    printf '%s\n' \
        'error: emit-module command failed with exit code 1' \
        '/tmp/fixture.swift:1:1: error: cannot find type '\''MusicSequence'\'' in scope' \
        > "$TMP/classifier-known.log"
    classify_repository_diagnostics "$TMP/classifier-known.log" \
        || die 'repository diagnostic classifier rejected a known dependency failure'
    printf '%s\n' \
        'error: emit-module command failed with exit code 1' \
        '/tmp/fixture.swift:1:1: error: cannot find type '\''MusicSequence'\'' in scope' \
        '/tmp/fixture.swift:2:1: error: AVFAudio-local sentinel failure' \
        > "$TMP/classifier-mixed.log"
    if classify_repository_diagnostics "$TMP/classifier-mixed.log" >/dev/null 2>&1; then
        die 'repository diagnostic classifier accepted an AVFAudio-local failure'
    fi
    printf '%s\n' \
        'AVFAUDIO_REPOSITORY_DIAGNOSTIC_CLASSIFIER_OK checks=known-accepted,mixed-local-rejected'
    missing_modules=()
    repo_libraries=()
    while IFS=: read -r dependency slug; do
        dependency_manifest=$REPO_ROOT/full/$slug/${slug}_guest_sources.txt
        if [ -f "$dependency_manifest" ] && [ ! -L "$dependency_manifest" ]; then
            build_repository_dependency "$dependency" "$slug"
        else
            missing_modules+=("$dependency")
        fi
    done <<'DEPENDENCIES'
CoreAudioTypes:coreaudiotypes
AudioToolbox:audiotoolbox
CoreMIDI:coremidi
CoreMedia:coremedia
DEPENDENCIES

    if swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
        -I "$TMP" -L "$TMP" \
        -module-name AVFAudio \
        -emit-module-path "$TMP/AVFAudio.swiftmodule" \
        -o "$TMP/libAVFAudio.dylib" \
        "${SOURCE_PATHS[@]}" "${repo_libraries[@]}" \
        >"$TMP/repository-boundary.log" 2>&1; then
        [ "${#missing_modules[@]}" -eq 0 ] \
            || die "repository dependency modules are missing: ${missing_modules[*]}"
        printf '%s\n' \
            'AVFAUDIO_REPOSITORY_DEPENDENCY_INTEGRATION_OK modules=CoreAudioTypes,AudioToolbox,CoreMIDI,CoreMedia'
        return
    fi

    if ! classify_repository_diagnostics "$TMP/repository-boundary.log"; then
        sed -n '1,240p' "$TMP/repository-boundary.log" >&2
        die 'repository dependency build failed outside the classified dependency boundary'
    fi
    sed -n '1,240p' "$TMP/repository-boundary.log" >&2
    printf '%s\n' \
        'AVFAUDIO_REPOSITORY_DEPENDENCY_BOUNDARY_UNRESOLVED modules=CoreAudioTypes,AudioToolbox,CoreMIDI,CoreMedia policy=no-lookalikes' >&2
    die 'repository dependency modules do not yet provide the canonical dependency ABI'
}

case "$mode" in
    canonical) run_canonical_probe ;;
    repository) run_repository_boundary ;;
    *) die "mode must be canonical or repository: $mode" ;;
esac
