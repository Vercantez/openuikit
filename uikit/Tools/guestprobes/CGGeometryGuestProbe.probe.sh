# CoreGraphics' Int / Double geometry initializers on the guest's portable
# CGPoint / CGSize / CGVector / CGRect (OpenCoreGraphics Geometry.swift),
# against the iOS 26.1 simulator running the same source
# (Tools/oracle2/cggeometryprobe). Sourced by full/scripts/build_full.sh (build)
# and uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

build_extra_probe_CGGeometryGuestProbe() {
    compile_app_module CGGeometryGuestProbe "$OUT/CGGeometryGuestProbe.o" \
        "$UIKIT/Tools/oracle2/cggeometryprobe/main.swift"
    link_app_executable "$OUT/CGGeometryGuestProbe" "$OUT/CGGeometryGuestProbe.o"
}

# Every line must equal the iOS 26.1 run.
run_extra_probe_CGGeometryGuestProbe() {
    local expected="$UIKIT/Tools/oracle2/cggeometryprobe/transcript-ios26.1.txt" out
    out=$("$ROOT/machorun" "$BUILD/CGGeometryGuestProbe" 2>/dev/null) || {
        echo "CG_GEOMETRY_GUEST_EXIT_NONZERO"
        printf '%s\n' "$out" | tail -3
        return 1
    }
    if [ "$out" = "$(cat "$expected")" ]; then
        echo "CG_GEOMETRY_GUEST_OK $(printf '%s\n' "$out" | grep -c '^CG ') lines identical to the iOS 26.1 run (CoreGraphics Int/Double initializers)"
    else
        echo "CG_GEOMETRY_GUEST_MISMATCH"
        diff <(printf '%s\n' "$out") "$expected" | head -20
        return 1
    fi
}
