# overlay_targets.inc -- sourced. Derive overlay ninja names from the
# configured graph (`ninja -t targets`), never from a hardcoded list that
# can name a target CMake did not create.
#
# Phase-2 required overlays (FE arm64 load list): _Concurrency,
# _StringProcessing, Synchronization, _Builtin_float. Darwin is in this
# Linux graph (Platform/) even with -DSWIFT_BUILD_SDK_OVERLAY=OFF, because
# Swift 6.2.4 overwrites that option from SWIFT_BUILD_DYNAMIC_SDK_OVERLAY
# (default TRUE on a non-Apple host). ObjectiveC is not a CMake target here;
# Apple picks it up from the Xcode SDK.

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
        "swiftDarwin-macosx-${arch}" \
        "swiftObjectiveC-macosx-${arch}"
}

overlay_required_target() {
    case "$1" in
        swift_Concurrency-macosx-*|swiftSynchronization-macosx-*|swift_StringProcessing-macosx-*|swift_Builtin_float-macosx-*)
            return 0 ;;
        *) return 1 ;;
    esac
}

overlay_xcode_only_target() {
    case "$1" in
        swiftObjectiveC-macosx-*) return 0 ;;
        *) return 1 ;;
    esac
}

# Fill OVERLAY_NINJA_TARGETS. Print CANNOT_* for missing names. Exit 2 if a
# required overlay is absent. Never emit a name that is not in `ninja -t targets`.
#
# overlay_select_targets <build_dir> <arch>
overlay_select_targets() {
    local build_dir=${1:?overlay_select_targets: build dir}
    local arch=${2:?overlay_select_targets: arch}
    local dump n have
    OVERLAY_NINJA_TARGETS=()

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
            echo "CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=$n reason=not in ninja -t targets; Swift 6.2.4 does not create an ObjectiveC overlay CMake target on Linux (Apple picks it up from the Xcode SDK)"
            continue
        fi
        if overlay_required_target "$n"; then
            echo "CANNOT_OVERLAY_TARGET_ABSENT target=$n reason=not in ninja -t targets; required overlay was not created by this CMake configuration" >&2
            missing_required=1
            continue
        fi
        # Darwin (and any other optional Platform overlay): named refusal, skip.
        echo "CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=$n reason=not in ninja -t targets"
    done < <(overlay_candidate_targets "$arch")

    if [ "$missing_required" = 1 ]; then
        return 2
    fi
    if [ ${#OVERLAY_NINJA_TARGETS[@]} -eq 0 ]; then
        echo "overlay_select: no overlay ninja targets in this configuration" >&2
        return 2
    fi
    echo "overlay_select: will ninja ${OVERLAY_NINJA_TARGETS[*]}"
    return 0
}
