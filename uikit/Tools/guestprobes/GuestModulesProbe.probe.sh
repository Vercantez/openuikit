# Guest modules apps import by Apple's names: CoreGraphics next to UIKit
# (one declaration per name) and Security (keychain fail-closed as an
# unentitled iOS 26.1 process) (docs/agent_reports/guest-swift-modules.md).
# Sourced by full/scripts/build_full.sh (build) and
# uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

build_extra_probe_GuestModulesProbe() {
    compile_app_module GuestModulesProbe "$OUT/GuestModulesProbe.o" \
        "$UIKIT/Tools/oracle2/guestmodulesprobe/main.swift"
    link_app_executable "$OUT/GuestModulesProbe" "$OUT/GuestModulesProbe.o" \
        "$OUT/guest-apple-coregraphics.o" "$OUT/guest-apple-security.o"
}

# Must equal the same main.swift run on the iOS 26.1 simulator (run.sh).
run_extra_probe_GuestModulesProbe() {
    local expected="$UIKIT/Tools/oracle2/guestmodulesprobe/transcript-ios26.1.txt" out
    out=$("$ROOT/machorun" "$BUILD/GuestModulesProbe" 2>/dev/null) \
        || { echo "GUEST_MODULES_EXIT_NONZERO"; printf '%s\n' "$out" | tail -5; return 1; }
    if [ "$out" = "$(cat "$expected")" ]; then
        echo "GUEST_MODULES_OK $(printf '%s\n' "$out" | wc -l | tr -d ' ') lines identical to the iOS 26.1 run (import CoreGraphics + UIKit, Security keychain -34018, SecCopyErrorMessageString, SecRandomCopyBytes)"
    else
        echo "GUEST_MODULES_MISMATCH"
        diff <(printf '%s\n' "$out") "$expected" | head -20
        return 1
    fi
}
