# Storyboard / NIB runtime under machorun + objc4 (docs/agent_reports/
# eidolon-nib-runtime.md). Sourced by full/scripts/build_full.sh (build) and
# uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

build_extra_probe_NibGuestProbe() {
    compile_app_module NibGuestProbe "$OUT/NibGuestProbe.o" "$UIKIT/Tools/nibguest/NibGuestProbe.swift"
    link_app_executable "$OUT/NibGuestProbe" "$OUT/NibGuestProbe.o"
}

# Archived custom classes found by name in objc4, init(coder:), outlets,
# embed segue with the app's prepare(for:sender:), an archived action.
run_extra_probe_NibGuestProbe() {
    local out
    out=$("$ROOT/machorun" "$BUILD/NibGuestProbe" "$UIKIT/fixtures/nibruntime" "${OPENUIKIT_RESOURCE_ROOT:-$UIKIT/Sources/OpenUIKit/Resources}" 2>&1 | grep -v '^objc\[' || true)
    printf '%s\n' "$out" | tail -5
    printf '%s\n' "$out" | grep -q '^NIB_GUEST_RUNTIME_OK '
}
