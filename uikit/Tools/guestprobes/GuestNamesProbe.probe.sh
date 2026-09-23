# Guest Foundation NSUUID, NSDecimalNumber, NSCharacterSet, NSException
# (docs/agent_reports/guest-swift-modules.md).
# Sourced by full/scripts/build_full.sh (build) and
# uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

build_extra_probe_GuestNamesProbe() {
    compile_app_module GuestNamesProbe "$OUT/GuestNamesProbe.o" \
        "$UIKIT/Tools/oracle2/guestnamesprobe/main.swift"
    link_app_executable "$OUT/GuestNamesProbe" "$OUT/GuestNamesProbe.o"
}

# Must equal the same main.swift run on the iOS 26.1 simulator (run.sh).
run_extra_probe_GuestNamesProbe() {
    local expected="$UIKIT/Tools/oracle2/guestnamesprobe/transcript-ios26.1.txt" out
    out=$("$ROOT/machorun" "$BUILD/GuestNamesProbe" 2>/dev/null) \
        || { echo "GUEST_NAMES_EXIT_NONZERO"; printf '%s\n' "$out" | tail -5; return 1; }
    if [ "$out" = "$(cat "$expected")" ]; then
        echo "GUEST_NAMES_OK $(printf '%s\n' "$out" | wc -l | tr -d ' ') lines identical to the iOS 26.1 run (NSUUID, NSDecimalNumber, NSCharacterSet, NSException)"
    else
        echo "GUEST_NAMES_MISMATCH"
        diff <(printf '%s\n' "$out") "$expected" | head -20
        return 1
    fi
}
