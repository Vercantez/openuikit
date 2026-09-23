# Guest Foundation facade gaps: Thread, NSRecursiveLock/NSCondition(Lock),
# URLSession task census, UserDefaults.setValue, NSString numeric values,
# String(format:locale:) (docs/agent_reports/guest-swift-modules.md).
# Sourced by full/scripts/build_full.sh (build) and
# uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

build_extra_probe_GuestFoundationProbe() {
    compile_app_module GuestFoundationProbe "$OUT/GuestFoundationProbe.o" \
        "$UIKIT/Tools/oracle2/guestfoundationprobe/main.swift"
    link_app_executable "$OUT/GuestFoundationProbe" "$OUT/GuestFoundationProbe.o"
}

# The same main.swift run on the iOS 26.1 simulator (run.sh) wrote the
# expected transcript; the guest must print it line for line.
run_extra_probe_GuestFoundationProbe() {
    local expected="$UIKIT/Tools/oracle2/guestfoundationprobe/transcript-ios26.1.txt" out
    out=$("$ROOT/machorun" "$BUILD/GuestFoundationProbe" 2>/dev/null) \
        || { echo "GUEST_FOUNDATION_PROBE_EXIT_NONZERO"; printf '%s\n' "$out" | tail -5; return 1; }
    if [ "$out" = "$(cat "$expected")" ]; then
        echo "GUEST_FOUNDATION_OK $(printf '%s\n' "$out" | wc -l | tr -d ' ') lines identical to the iOS 26.1 run (Thread, locks, URLSession tasks, UserDefaults.setValue, NSString numbers, String(format:locale:))"
    else
        echo "GUEST_FOUNDATION_MISMATCH"
        diff <(printf '%s\n' "$out") "$expected" | head -40
        return 1
    fi
}
