# Guest Foundation Operation / BlockOperation / OperationQueue scheduling
# (docs/agent_reports/guest-swift-modules.md).
# Sourced by full/scripts/build_full.sh (build) and
# uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

build_extra_probe_GuestOperationProbe() {
    compile_app_module GuestOperationProbe "$OUT/GuestOperationProbe.o" \
        "$UIKIT/Tools/oracle2/guestoperationprobe/main.swift"
    link_app_executable "$OUT/GuestOperationProbe" "$OUT/GuestOperationProbe.o"
}

# Must equal the same main.swift run on the iOS 26.1 simulator (run.sh).
run_extra_probe_GuestOperationProbe() {
    local expected="$UIKIT/Tools/oracle2/guestoperationprobe/transcript-ios26.1.txt" out
    out=$("$ROOT/machorun" "$BUILD/GuestOperationProbe" 2>/dev/null) \
        || { echo "GUEST_OPERATION_EXIT_NONZERO"; printf '%s\n' "$out" | tail -5; return 1; }
    if [ "$out" = "$(cat "$expected")" ]; then
        echo "GUEST_OPERATION_OK $(printf '%s\n' "$out" | wc -l | tr -d ' ') lines identical to the iOS 26.1 run (Operation, BlockOperation, OperationQueue scheduling, async will/didChangeValue)"
    else
        echo "GUEST_OPERATION_MISMATCH"
        diff <(printf '%s\n' "$out") "$expected" | head -20
        return 1
    fi
}
