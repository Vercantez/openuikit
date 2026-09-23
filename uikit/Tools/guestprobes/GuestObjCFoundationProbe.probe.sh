# Objective-C and Swift sharing the guest's one Foundation, and NetNewsWire's
# unmodified RSDatabaseObjC (FMDB) on the guest's libsqlite3, against the iOS
# 26.1 simulator running the same sources (Tools/oracle2/guestobjcfoundation).
# Sourced by full/scripts/build_full.sh (build) and
# uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

# The pinned ladder corpus: LADDER_CORPUS, this checkout's scratch/, or the main
# checkout's (a worktree has none; scripts/ops/local_guest_verify.sh passes MAIN).
guest_objc_probe_corpus() {
    local candidate
    for candidate in "${LADDER_CORPUS:-}" "$W/scratch/ladder-corpus" "${MAIN:+$MAIN/scratch/ladder-corpus}"; do
        [ -n "$candidate" ] && [ -d "$candidate/NetNewsWire" ] && { printf '%s\n' "$candidate"; return 0; }
    done
    echo "GuestObjCFoundationProbe: no ladder corpus with NetNewsWire (set LADDER_CORPUS)" >&2
    return 1
}

build_extra_probe_GuestObjCFoundationProbe() {
    local src="$UIKIT/Tools/oracle2/guestobjcfoundation" obj="$OUT/guest-objc-foundation-obj" corpus rsdb f
    corpus=$(guest_objc_probe_corpus)
    # NetNewsWire @ PINS.txt, byte for byte (never a patched copy).
    (cd "$corpus/NetNewsWire" && sha256sum -c --quiet "$W/full/objcfoundation/rsdatabaseobjc.sha256")
    rsdb=$corpus/NetNewsWire/Modules/RSDatabase/Sources/RSDatabaseObjC
    rm -rf "$obj"
    mkdir -p "$obj/maps/OFScenario" "$obj/maps/RSDatabaseObjC"
    printf 'module OFScenario { header "%s" export * }\n' "$src/scenario/include/OFScenario.h" \
        > "$obj/maps/OFScenario/module.modulemap"
    printf 'module RSDatabaseObjC { umbrella header "%s" export * }\n' "$rsdb/include/RSDatabaseObjC.h" \
        > "$obj/maps/RSDatabaseObjC/module.modulemap"
    local objects=()
    for f in "$src"/scenario/*.m "$rsdb"/*.m; do
        compile_app_objc "$obj/$(basename "$f" .m).o" "$f" \
            -I "$src/scenario/include" -I "$rsdb/include" -I "$rsdb"
        objects+=("$obj/$(basename "$f" .m).o")
    done
    "${SWIFTC[@]}" -D OPENUIKIT_GUEST "${FEMODULES[@]}" "${APPMODS_CINC[@]}" "${OBJC_SWIFT_FLAGS[@]}" \
        -I "$OUT" -I "$APPINC" -I "$APPMODS" "${APP_AVAILABILITY_FLAGS[@]}" \
        -Xcc -fmodule-map-file="$obj/maps/OFScenario/module.modulemap" -Xcc -I"$src/scenario/include" \
        -Xcc -fmodule-map-file="$obj/maps/RSDatabaseObjC/module.modulemap" -Xcc -I"$rsdb/include" -Xcc -I"$rsdb" \
        -module-name GuestObjCFoundationProbe -emit-object -o "$obj/main.o" "$src/main.swift"
    link_app_executable "$OUT/GuestObjCFoundationProbe" "$obj/main.o" "${objects[@]}" \
        "${OBJC_FOUNDATION_LINK_OBJECTS[@]}" "$ROOTDIR/darwin/usr/lib/libsqlite3.dylib"
}

# Every line must equal the iOS 26.1 run; the FMDB lines are counted apart.
run_extra_probe_GuestObjCFoundationProbe() {
    local expected="$UIKIT/Tools/oracle2/guestobjcfoundation/transcript-ios26.1.txt" out
    out=$("$ROOT/machorun" "$BUILD/GuestObjCFoundationProbe" 2>/dev/null) || {
        echo "GUEST_OBJC_FOUNDATION_EXIT_NONZERO"
        printf '%s\n' "$out" | tail -3
        return 1
    }
    if [ "$out" = "$(cat "$expected")" ]; then
        echo "GUEST_OBJC_FOUNDATION_OK $(printf '%s\n' "$out" | grep -vc 'fmdb') lines identical to the iOS 26.1 run (ObjC strings, numbers, collections, errors, data, dates; Swift<->ObjC bridging)"
        echo "GUEST_FMDB_OK $(printf '%s\n' "$out" | grep -c 'fmdb') lines identical: NetNewsWire's unmodified RSDatabaseObjC on an in-memory SQLite database, from Objective-C and from Swift"
    else
        echo "GUEST_OBJC_FOUNDATION_MISMATCH"
        diff <(printf '%s\n' "$out") "$expected" | head -30
        return 1
    fi
}
