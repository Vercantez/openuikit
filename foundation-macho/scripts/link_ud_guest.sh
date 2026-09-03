#!/bin/bash
# link_ud_guest.sh -- relink the #87 guest binary from the objects already in
# /work/fe, and REFUSE if any input is newer than the output it produced.
#
#   scripts/link_ud_guest.sh
#
# WHY THIS EXISTS (task #89, 2026-08-28). The ud_guest binary was linked by
# hand and no committed script could rebuild it. That is not a style
# complaint -- it hid a stale artifact:
#
#     /work/bin/ud_guest              05:10:00 UTC   11,587,904 bytes
#     /work/fe/UserDefaultsGuest.o    05:17:13 UTC   (the PORT)
#     /work/fe/runner.o               05:17:56 UTC   (the RUNNER)
#     /work/lib/libCFTest.dylib       05:14:14 UTC   (CoreFoundation)
#
# The port object and the runner object are both SEVEN MINUTES NEWER than the
# binary said to contain them. Commit aa63668's message quotes "Port compiles
# (90,640 bytes)" and "binary links (11,587,904 bytes)" in one breath; both
# numbers are real, and they are numbers about two different builds. Anyone
# running that binary is testing a port that has since been recompiled.
#
# So this script does two things a hand-typed link line cannot: it is
# REPEATABLE, and it CHECKS. The freshness check is the point, not a courtesy
# -- a binary older than its own inputs passes every git-level check there is.
#
# Reuse of bin/ud_guest is keyed on bin/ud_guest.inputs, written at link time:
# sha256 of every object on the line, libCFTest.dylib, and the linker argv.
# Existence of the binary is not enough (same class as the loader existence
# reuse in PR #65). Matching stamp → reused=1 stamp=<sha>. Mismatch →
# reason=inputs <key> old->new and relink. UD_GUEST_VERIFY_ONLY=1 reports
# CANNOT_UD_GUEST_INPUTS instead of linking.
#
# NOT a compile step. The objects are built elsewhere (the port and runner by
# the #87 recipe, FoundationEssentials by ~/swift-macho-linux's build_fe.sh).
# This script only links, and it refuses rather than silently linking stale
# objects into a fresh-looking executable.
set -euo pipefail

W=${W:-/work}
# shellcheck disable=SC1091
. "$(cd "$(dirname "$0")" && pwd)/guest_arch.inc"
# The FE sysroot, NOT $W/sdk/MacOSX.sdk. This is the one carrying .tbd stubs
# for the Swift overlays (libswiftDarwin, libswift_StringProcessing,
# libswiftSynchronization, libswift_errno); linking against the CF sysroot
# instead produces a wall of undefined Swift symbols that reads like a port
# problem and is only a missing -L.
SDK=${SDK:-$W/fe/sysroot}
LLD=${LLD_BIN:-/usr/lib/llvm-18/bin}
OUT=${OUT:-$W/bin/ud_guest}
# Swift's /usr/bin/clang is clang-17; its bundled lld refuses macOS. Distro
# clang-18 + ld64.lld-18 is the Darwin driver this tree measures (same as
# build_cftest_harness.sh / machorun guest_arch.inc DARWIN_CLANG).
CC=${CC:-}
if [ -z "$CC" ]; then
    if command -v clang-18 >/dev/null 2>&1; then CC=clang-18
    elif command -v clang >/dev/null 2>&1; then CC=clang
    else
        echo "link_ud_guest: no clang-18/clang" >&2
        exit 2
    fi
fi

OBJS=(
  "${RUNNER:-$W/fe/runner.o}"
  "$W/fe/UserDefaultsGuest.o"
  "$W/fe/module/FoundationEssentials.o"
  "$W/fe/collections/OrderedCollections.o"
  "$W/fe/collections/InternalCollectionsUtilities.o"
  "$W/fe/os/os.o"
  "$W/fe/cshims/platform_shims.o"
  "$W/fe/cshims/string_shims.o"
  "$W/fe/cshims/uuid.o"
  "$W/fe/fm_unimplemented.o"
)
# collections/_RopeModule.o is the #87 staged path. fe/_RopeModule.o is a
# fallback when collections/ was not staged. Never both: they are the same
# object and ld64 reports duplicate symbols for every Rope export.
if [ -f "$W/fe/collections/_RopeModule.o" ]; then
    OBJS+=("$W/fe/collections/_RopeModule.o")
elif [ -f "$W/fe/_RopeModule.o" ]; then
    OBJS+=("$W/fe/_RopeModule.o")
fi
# Drop anything that is not there rather than failing on a path that moved.
INPUTS=()
for o in "${OBJS[@]}"; do [ -f "$o" ] && INPUTS+=("$o"); done

# THE SWIFT OVERLAYS MUST BE LINKED AGAINST THE .tbd STUBS, NOT THE DYLIBS,
# AND THE -L ORDER IS WHAT DECIDES IT.
#
# The staged overlay dylibs in $W/lib are iOS-SIMULATOR builds. ld64.lld
# REFUSES them outright for a macOS target --
#
#     ld64.lld: error: /work/lib/libswift_StringProcessing.dylib has platform
#     iOS Simulator, which is different from target platform macOS
#
# -- and every symbol that dylib would have provided then reports as
# "undefined". That is a spectacularly misleading failure: 61 undefined Swift
# symbols that look like a missing module and are really one rejected file.
# (All 61 are defined in $W/lib, and all 61 are advertised by the sysroot's
# .tbd stubs -- measured both ways before changing anything.)
#
# The .tbd stubs in $SDK/usr/lib/swift carry the macOS platform, so lld accepts
# them. Hence: SYSROOT -L DIRECTORIES FIRST, $W/lib last. If $W/lib comes first
# the search finds the sim .dylib and the link dies with that wall of
# undefineds. This ordering is load-bearing, not cosmetic.
LIBDIRS=(-L"$SDK/usr/lib/swift" -L"$SDK/usr/lib" -L"$W/lib")

# Linked by -l so the .tbd wins. libSystem is spelled without the .B here
# because the STUB is libSystem.tbd even though the dylib is libSystem.B.dylib.
DYLIBS=(-lswiftCore -lswiftDarwin -lswift_StringProcessing
        -lswiftSynchronization -lswift_errno -lobjc -lSystem)

# Ours, and macOS-platform, so the dylib itself is fine -- and naming it by
# path keeps it out of the search-order question entirely.
DYLIBS+=("$W/lib/libCFTest.dylib" "$W/lib/libswiftcompat.dylib")

ud_file_sha() {
    if [ -f "$1" ]; then
        sha256sum "$1" | awk '{print $1}'
    else
        printf 'ABSENT\n'
    fi
}

ud_obj_key() {
    printf 'obj:%s\n' "${1#$W/}"
}

ud_link_words() {
    printf '%s\n' \
        "$CC" -target "$TRIPLE" -isysroot "$SDK" \
        -fuse-ld=lld -B "$LLD" -nostdlib \
        "${LIBDIRS[@]}" \
        -Wl,-rpath,/usr/lib/swift -Wl,-rpath,@loader_path \
        "${INPUTS[@]}" "${DYLIBS[@]}" \
        -o "$OUT"
}

ud_inputs_text() {
    local o
    printf 'argv=%s\n' "$(ud_link_words | sha256sum | awk '{print $1}')"
    printf 'cftest=%s\n' "$(ud_file_sha "$W/lib/libCFTest.dylib")"
    for o in "${INPUTS[@]}"; do
        printf '%s=%s\n' "$(ud_obj_key "$o")" "$(ud_file_sha "$o")"
    done
}

ud_write_inputs() {
    mkdir -p "$(dirname "$OUT")"
    ud_inputs_text > "$OUT.inputs"
}

ud_inputs_diff() {
    local stamp=$OUT.inputs
    local expected key val old changed=0
    expected=$(ud_inputs_text)
    if [ ! -f "$stamp" ]; then
        printf 'stamp ABSENT->present\n'
        return 1
    fi
    while IFS='=' read -r key val; do
        [ -n "$key" ] || continue
        old=$(awk -F= -v k="$key" '$1==k { print substr($0, index($0,"=")+1); exit }' "$stamp")
        [ -n "$old" ] || old=ABSENT
        if [ "$old" != "$val" ]; then
            printf '%s %s->%s\n' "$key" "$old" "$val"
            changed=1
        fi
    done <<EOF
$expected
EOF
    while IFS='=' read -r key val; do
        [ -n "$key" ] || continue
        if ! printf '%s\n' "$expected" | awk -F= -v k="$key" '$1==k { found=1 } END { exit !found }'
        then
            printf '%s %s->ABSENT\n' "$key" "$val"
            changed=1
        fi
    done < "$stamp"
    [ "$changed" -eq 0 ]
}

echo "== inputs"
for o in "${INPUTS[@]}"; do
    printf '   %-46s %10s bytes  %s\n' "${o#$W/}" "$(wc -c < "$o")" \
        "$(date -r "$o" -u '+%H:%M:%S')"
done

relink_reason=
mkdir -p "$(dirname "$OUT")"
if [ -f "$OUT" ]; then
    diff=$(ud_inputs_diff || true)
    if [ -z "$diff" ]; then
        stamp_id=$(ud_file_sha "$OUT.inputs")
        echo "ud_guest reused=1 stamp=$stamp_id dest=$OUT"
        echo "== $OUT"
        echo "   $(wc -c < "$OUT") bytes"
        llvm-otool-18 -L "$OUT" | tail -n +2 | sed 's/^/   /'
        exit 0
    fi
    first=$(printf '%s\n' "$diff" | head -1)
    key=${first%% *}
    rest=${first#"$key "}
    relink_reason="reason=inputs $key $rest"
    if [ "${UD_GUEST_VERIFY_ONLY:-0}" = 1 ]; then
        echo "CANNOT_UD_GUEST_INPUTS file=ud_guest $relink_reason"
        echo "$diff"
        echo "link_ud_guest: input stamp mismatch; refusing to call this satisfied (verify-only)." >&2
        exit 2
    fi
    echo "ud_guest relink $relink_reason"
    echo "$diff"
elif [ "${UD_GUEST_VERIFY_ONLY:-0}" = 1 ]; then
    echo "CANNOT_UD_GUEST_INPUTS file=ud_guest reason=inputs stamp ABSENT->present"
    echo "link_ud_guest: no $OUT (verify-only)." >&2
    exit 2
fi

echo "==> linking $OUT CC=$CC${relink_reason:+ $relink_reason}"
# -nostdlib: Linux-hosted Darwin links must not pull host crt. Same as
# run_bundle_guest.sh / run_tests.sh. clang-18 still passes -syslibroot.
"$CC" -target "$TRIPLE" -isysroot "$SDK" \
  -fuse-ld=lld -B "$LLD" -nostdlib \
  "${LIBDIRS[@]}" \
  -Wl,-rpath,/usr/lib/swift -Wl,-rpath,@loader_path \
  "${INPUTS[@]}" "${DYLIBS[@]}" \
  -o "$OUT"
ud_write_inputs

# ---------------------------------------------------------------------------
# THE CHECK THIS SCRIPT EXISTS FOR. Every input must be OLDER than the output.
# Run AFTER the link so it grades the artifact that now exists on disk.
echo "== freshness: every input must predate the binary"
stale=0
for o in "${INPUTS[@]}" "$W/lib/libCFTest.dylib"; do
    [ -f "$o" ] || continue
    if [ "$o" -nt "$OUT" ]; then
        echo "   *** NEWER THAN THE BINARY: ${o#$W/}  ($(date -r "$o" -u '+%H:%M:%S'))" >&2
        stale=1
    fi
done
if [ "$stale" -ne 0 ]; then
    echo "REFUSING to call this build good: an input postdates the output." >&2
    echo "  Rebuild that input's producer, then run this script again." >&2
    exit 2
fi
echo "   all ${#INPUTS[@]} objects + libCFTest.dylib predate $(basename "$OUT")"

echo "== $OUT"
echo "   $(wc -c < "$OUT") bytes"
llvm-otool-18 -L "$OUT" | tail -n +2 | sed 's/^/   /'
