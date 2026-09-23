# Guest Foundation no iCloud account: noAccount, CKError.notAuthenticated 9
# (docs/agent_reports/guest-swift-modules.md).
# Sourced by full/scripts/build_full.sh (build) and
# uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

build_extra_probe_GuestCloudKitProbe() {
    compile_app_module GuestCloudKitProbe "$OUT/GuestCloudKitProbe.o" \
        "$UIKIT/Tools/oracle2/guestcloudkitprobe/main.swift"
    link_app_executable "$OUT/GuestCloudKitProbe" "$OUT/GuestCloudKitProbe.o" \
        "$OUT/guest-apple-cloudkit.o"
}

# Must equal the same main.swift run on the iOS 26.1 simulator (run.sh).
run_extra_probe_GuestCloudKitProbe() {
    local expected="$UIKIT/Tools/oracle2/guestcloudkitprobe/transcript-ios26.1.txt" out
    out=$("$ROOT/machorun" "$BUILD/GuestCloudKitProbe" 2>/dev/null) \
        || { echo "GUEST_CLOUDKIT_EXIT_NONZERO"; printf '%s\n' "$out" | tail -5; return 1; }
    if [ "$out" = "$(cat "$expected")" ]; then
        echo "GUEST_CLOUDKIT_OK $(printf '%s\n' "$out" | wc -l | tr -d ' ') lines identical to the iOS 26.1 run (no iCloud account: noAccount, CKError.notAuthenticated 9)"
    else
        echo "GUEST_CLOUDKIT_MISMATCH"
        diff <(printf '%s\n' "$out") "$expected" | head -20
        return 1
    fi
}
