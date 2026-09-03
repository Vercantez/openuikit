# overlay_targets.inc -- sourced. Derive overlay ninja names from the
# configured graph (`ninja -t targets`), never from a hardcoded list that
# can name a target CMake did not create.
#
# Phase-2 FE mrroot overlays (scripts/x86/common.inc phase2_fe_overlay_names)
# plus _Concurrency / Observation that the SwiftUI guest also loads.
# In-tree on a Linux-host OSX configure: _Concurrency, Synchronization,
# _StringProcessing, _Builtin_float, _RegexParser (with STRING_PROCESSING),
# Observation (with OBSERVATION), Darwin (Platform/). Not CMake targets on
# Linux: ObjectiveC, _DarwinFoundation1/2/3, _errno — those are Apple SDK
# overlays (stdlib/public/CMakeLists.txt:359: "On Apple platforms, we aren't
# building any overlays. Instead, we're picking them up from the SDK.").
# Named CANNOT, never ninja'd.

if [ -n "${SWIFTCORE_OVERLAY_TARGETS_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
SWIFTCORE_OVERLAY_TARGETS_INC=1

overlay_candidate_targets() {
    local arch=${1:?overlay_candidate_targets: arch}
    printf '%s\n' \
        "swift_Concurrency-macosx-${arch}" \
        "swiftSynchronization-macosx-${arch}" \
        "swift_StringProcessing-macosx-${arch}" \
        "swift_Builtin_float-macosx-${arch}" \
        "swift_RegexParser-macosx-${arch}" \
        "swiftObservation-macosx-${arch}" \
        "swiftDarwin-macosx-${arch}" \
        "swift_DarwinFoundation1-macosx-${arch}" \
        "swift_DarwinFoundation2-macosx-${arch}" \
        "swift_DarwinFoundation3-macosx-${arch}" \
        "swift_errno-macosx-${arch}" \
        "swiftObjectiveC-macosx-${arch}"
}

overlay_required_target() {
    case "$1" in
        swift_Concurrency-macosx-*|swiftSynchronization-macosx-*|swift_StringProcessing-macosx-*|swift_Builtin_float-macosx-*|swift_RegexParser-macosx-*)
            return 0 ;;
        *) return 1 ;;
    esac
}

overlay_xcode_only_target() {
    case "$1" in
        swiftObjectiveC-macosx-*|swift_DarwinFoundation[123]-macosx-*|swift_errno-macosx-*)
            return 0 ;;
        *) return 1 ;;
    esac
}

# Fill OVERLAY_NINJA_TARGETS. Print CANNOT_* for missing names. Exit 2 if a
# required overlay is absent. Never emit a name that is not in `ninja -t targets`.
# OVERLAY_STATUS[target] is built|FAILED|CANNOT_<reason> (CANNOT filled here;
# built/FAILED filled by the caller after each independent ninja).
#
# overlay_select_targets <build_dir> <arch>
overlay_select_targets() {
    local build_dir=${1:?overlay_select_targets: build dir}
    local arch=${2:?overlay_select_targets: arch}
    local dump n have
    OVERLAY_NINJA_TARGETS=()
    declare -gA OVERLAY_STATUS
    OVERLAY_STATUS=()

    if [ -n "${NINJA_TARGETS_DUMP:-}" ]; then
        dump=$(cat "$NINJA_TARGETS_DUMP")
    else
        local ninja_bin=${NINJA:-ninja}
        dump=$("$ninja_bin" -C "$build_dir" -t targets)
    fi
    echo "overlay_select: ninja -t targets from ${NINJA_TARGETS_DUMP:-$build_dir}"

    local missing_required=0
    while IFS= read -r n; do
        [ -n "$n" ] || continue
        have=0
        printf '%s\n' "$dump" | grep -E "^${n}:" >/dev/null && have=1
        if [ "$have" = 1 ]; then
            echo "overlay_select: have $n"
            OVERLAY_NINJA_TARGETS+=("$n")
            continue
        fi
        if overlay_xcode_only_target "$n"; then
            echo "CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=$n reason=not in ninja -t targets; Swift 6.2.4 Linux-host OSX stdlib does not add_subdirectory Apple SDK overlays (_DarwinFoundation1/2/3, _errno, ObjectiveC — stdlib/public/CMakeLists.txt:359 'picking them up from the SDK')"
            OVERLAY_STATUS[$n]=CANNOT_STAGE_XCODE_DARWIN_OVERLAYS
            continue
        fi
        if overlay_required_target "$n"; then
            echo "CANNOT_OVERLAY_TARGET_ABSENT target=$n reason=not in ninja -t targets; required overlay was not created by this CMake configuration" >&2
            OVERLAY_STATUS[$n]=CANNOT_OVERLAY_TARGET_ABSENT
            missing_required=1
            continue
        fi
        # Observation is in-tree when SWIFT_ENABLE_EXPERIMENTAL_OBSERVATION=ON
        # (overlays=1). An older graph without that flag still lists it on the
        # scoreboard as CANNOT rather than failing the whole select.
        if [[ "$n" == swiftObservation-macosx-* ]]; then
            echo "CANNOT_OVERLAY_TARGET_ABSENT target=$n reason=not in ninja -t targets; enable -DSWIFT_ENABLE_EXPERIMENTAL_OBSERVATION=ON (SWIFTCORE_OVERLAYS=1)"
            OVERLAY_STATUS[$n]=CANNOT_OVERLAY_TARGET_ABSENT
            continue
        fi
        # Darwin (and any other optional Platform overlay): named refusal, skip.
        echo "CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=$n reason=not in ninja -t targets"
        OVERLAY_STATUS[$n]=CANNOT_STAGE_XCODE_DARWIN_OVERLAYS
    done < <(overlay_candidate_targets "$arch")

    if [ "$missing_required" = 1 ]; then
        if [ ${#OVERLAY_NINJA_TARGETS[@]} -gt 0 ]; then
            echo "overlay_select: will ninja ${OVERLAY_NINJA_TARGETS[*]}"
        else
            echo "overlay_select: will ninja"
        fi
        return 2
    fi
    if [ ${#OVERLAY_NINJA_TARGETS[@]} -eq 0 ]; then
        echo "overlay_select: no overlay ninja targets in this configuration" >&2
        return 2
    fi
    echo "overlay_select: will ninja ${OVERLAY_NINJA_TARGETS[*]}"
    return 0
}

# OVERLAY <ninja-target> built|FAILED|CANNOT_<reason>
overlay_print_scoreboard() {
    local arch=${1:?overlay_print_scoreboard: arch}
    local n st
    echo "==== overlay scoreboard ===="
    while IFS= read -r n; do
        [ -n "$n" ] || continue
        st=${OVERLAY_STATUS[$n]:-UNKNOWN}
        echo "OVERLAY $n $st"
    done < <(overlay_candidate_targets "$arch")
}

# ls of produced overlay dylibs / ELF .so under lib/swift/macosx.
overlay_list_products() {
    local root=${1:?overlay_list_products: macosx dir}
    echo "==== overlay products $root ===="
    if [ ! -d "$root" ]; then
        echo "(absent)"
        return 0
    fi
    ls -la "$root"
    local d
    for d in "$root"/*/; do
        [ -d "$d" ] || continue
        echo "-- $d --"
        ls -la "$d"
    done
    echo "-- libswift*.dylib / libswift*.so --"
    find "$root" \( -name 'libswift*.dylib' -o -name 'libswift*.so' \) -print | sort
}

# Flatten lib/swift/macosx/<arch>/libswiftX.{so,dylib,a} to
# lib/swift/macosx/libswiftX.* (the unarch path overlay ninja depends on).
# overlay_flatten_unarch <build_dir> <arch>
overlay_flatten_unarch() {
    local build_dir=${1:?overlay_flatten_unarch: build dir}
    local arch=${2:?overlay_flatten_unarch: arch}
    local arch_dir=$build_dir/lib/swift/macosx/$arch
    local unarch=$build_dir/lib/swift/macosx
    local f bn
    [ -d "$arch_dir" ] || return 0
    mkdir -p "$unarch"
    for f in "$arch_dir"/libswift*.so "$arch_dir"/libswift*.dylib "$arch_dir"/libswift*.a; do
        [ -e "$f" ] || continue
        bn=$(basename "$f")
        ln -sfn "$arch/$bn" "$unarch/$bn"
    done
}

# Ninja's Linux rule writes .so; phase2 / stage_artifacts look for .dylib.
# overlay_copy_so_as_dylib <build_dir> <arch>
overlay_copy_so_as_dylib() {
    local build_dir=${1:?overlay_copy_so_as_dylib: build dir}
    local arch=${2:?overlay_copy_so_as_dylib: arch}
    local arch_dir=$build_dir/lib/swift/macosx/$arch
    local so dylib
    [ -d "$arch_dir" ] || return 0
    for so in "$arch_dir"/libswift*.so; do
        [ -e "$so" ] || continue
        dylib=${so%.so}.dylib
        if [ ! -e "$dylib" ] || [ "$so" -nt "$dylib" ]; then
            cp -f "$so" "$dylib"
        fi
    done
}
