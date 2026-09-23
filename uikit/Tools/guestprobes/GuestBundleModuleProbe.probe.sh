# SwiftPM Bundle.module in the guest pipeline: the accessor
# full/xcodeplan/swiftpm_resource_accessor.py generates (Xcode 26.1's text)
# plus the package bundle staged beside the executable, as an app's package
# bundles sit in Bundle.main.resourceURL (docs/agent_reports/guest-swift-modules.md).
# Sourced by full/scripts/build_full.sh (build) and
# uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

build_extra_probe_GuestBundleModuleProbe() {
    local src="$UIKIT/Tools/oracle2/guestbundlemoduleprobe" gen="$OUT/swiftpm-accessor-GuestBundleModuleProbe.d"
    mkdir -p "$gen"
    python3 "$W/full/xcodeplan/swiftpm_resource_accessor.py" \
        GuestProbe_GuestBundleModuleProbe "$gen/resource_bundle_accessor.swift"
    compile_app_module GuestBundleModuleProbe "$OUT/GuestBundleModuleProbe.o" \
        "$src/main.swift" "$gen/resource_bundle_accessor.swift"
    link_app_executable "$OUT/GuestBundleModuleProbe" "$OUT/GuestBundleModuleProbe.o"
    rm -rf "$OUT/GuestProbe_GuestBundleModuleProbe.bundle"
    cp -R "$src/GuestProbe_GuestBundleModuleProbe.bundle" "$OUT/"
}

# Must equal the same program and layout on the iOS 26.1 simulator (run.sh).
run_extra_probe_GuestBundleModuleProbe() {
    local expected="$UIKIT/Tools/oracle2/guestbundlemoduleprobe/transcript-ios26.1.txt" out
    out=$("$ROOT/machorun" "$BUILD/GuestBundleModuleProbe" 2>/dev/null) \
        || { echo "GUEST_BUNDLE_MODULE_EXIT_NONZERO"; printf '%s\n' "$out" | tail -5; return 1; }
    if [ "$out" = "$(cat "$expected")" ]; then
        echo "GUEST_BUNDLE_MODULE_OK $(printf '%s\n' "$out" | wc -l | tr -d ' ') lines identical to the iOS 26.1 run (generated SwiftPM accessor, staged package bundle, NSLocalizedString(bundle: .module))"
    else
        echo "GUEST_BUNDLE_MODULE_MISMATCH"
        diff <(printf '%s\n' "$out") "$expected" | head -20
        return 1
    fi
}
