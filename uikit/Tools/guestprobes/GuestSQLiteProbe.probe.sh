# The guest's /usr/lib/libsqlite3.dylib (full/sqlite) against the iOS 26.1
# simulator's: the same C program (Tools/oracle2/guestsqliteoptions/main.c)
# prints version, threading mode, compile options, pragma defaults and a
# prepare/bind/step/FTS4/WAL session on :memory: and on a file. Sourced by
# full/scripts/build_full.sh (build) and
# uikit/scripts/linux_guest_realapp_verify.sh (run); see README.md.

build_extra_probe_GuestSQLiteProbe() {
    local obj="$OUT/guest-sqlite-probe-obj"
    mkdir -p "$obj"
    "${CC[@]}" -I "$SQLITE_INCLUDE" -c "$UIKIT/Tools/oracle2/guestsqliteoptions/main.c" -o "$obj/main.o"
    "${LD[@]}" -o "$OUT/GuestSQLiteProbe" "$obj/main.o" \
        "$ROOTDIR/darwin/usr/lib/libsqlite3.dylib" -lSystem
}

# Everything but the compile-option rows must equal the iOS run line for line;
# the option rows must be exactly those full/sqlite/apple_compile_options.tsv
# reproduces (sqlite_options.py check).
run_extra_probe_GuestSQLiteProbe() {
    local expected="$UIKIT/Tools/oracle2/guestsqliteoptions/transcript-ios26.1.txt"
    local out="${TMPDIR:-/tmp}/guestsqliteprobe.$$.txt" rc=0
    "$ROOT/machorun" "$BUILD/GuestSQLiteProbe" > "$out" 2>/dev/null || { echo "GUEST_SQLITE_EXIT_NONZERO"; rm -f "$out"; return 1; }
    if python3 -B "$UIKIT/../full/sqlite/sqlite_options.py" check "$out" "$expected"; then
        echo "GUEST_SQLITE_OK $(grep -c '^crud ' "$out") statement lines and $(grep -c '^pragma ' "$out") pragma defaults identical to the iOS 26.1 run, $(grep -c '^opt ' "$out") compile options as measured ($(head -1 "$out"))"
    else
        echo "GUEST_SQLITE_MISMATCH"
        rc=1
    fi
    rm -f "$out"
    return "$rc"
}
