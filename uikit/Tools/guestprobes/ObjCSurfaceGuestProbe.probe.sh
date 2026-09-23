# Objective-C category on UIFont and Objective-C CALayer subclass under
# machorun + objc4 (docs/agent_reports/objc-surface.md). Sourced by
# full/scripts/build_full.sh (build) and
# uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

build_extra_probe_ObjCSurfaceGuestProbe() {
    local src="$UIKIT/Tools/oracle2/objcsurfaceprobe" obj="$OUT/objcsurfaceprobe"
    mkdir -p "$obj"
    # The guest header OpenUIKit emitted, the app defines, objc4 and a guest-only
    # <Foundation/Foundation.h> stand-in (the guest has no Foundation headers).
    "${CC[@]}" -fobjc-arc -DOUK_OPENUIKIT=1 -DOUK_NO_FOUNDATION=1 \
        -I "$OUT/objc-include" -I "$src/scenario/include" -I "$src/guestinc" \
        "-DSWIFT_CLASS(SWIFT_NAME)=SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA" \
        "-DSWIFT_CLASS_NAMED(SWIFT_NAME)=SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA" \
        -c "$src/scenario/OUKSurfaceScenario.m" -o "$obj/scenario.o"
    "${CC[@]}" -I "$src/scenario/include" -c "$src/guest_main.c" -o "$obj/guest_main.o"
    link_app_executable "$OUT/ObjCSurfaceGuestProbe" "$obj/scenario.o" "$obj/guest_main.o"
}

# Must equal the same scenario variant run on the iOS 26.1 simulator.
run_extra_probe_ObjCSurfaceGuestProbe() {
    local expected="$UIKIT/Tools/oracle2/objcsurfaceprobe/transcript-guest-ios26.1.txt" out
    out=$("$ROOT/machorun" "$BUILD/ObjCSurfaceGuestProbe" 2>/dev/null) || { echo "OBJC_SURFACE_GUEST_EXIT_NONZERO"; return 1; }
    if [ "$out" = "$(cat "$expected")" ]; then
        echo "OBJC_SURFACE_GUEST_OK $(printf '%s\n' "$out" | wc -l | tr -d ' ') lines identical to the iOS 26.1 run (UIFont category, CALayer subclass)"
    else
        echo "OBJC_SURFACE_GUEST_MISMATCH"
        diff <(printf '%s\n' "$out") "$expected" | head -20
        return 1
    fi
}
