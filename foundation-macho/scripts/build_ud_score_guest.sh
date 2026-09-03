#!/bin/bash
# build_ud_score_guest.sh -- build the #87 step 4 GUEST scoreboard binary.
#
#   scripts/build_ud_score_guest.sh
#   scripts/build_ud_score_guest.sh --print-argv
#
# Compiles tests/ud_score_guest.swift together with a GENERATED Swift file that
# embeds the Darwin golden byte-for-byte, then links it exactly the way
# link_ud_guest.sh links the smoke runner -- same objects, same .tbd-first
# library order, same freshness refusal.
#
# W/R/ARCH (TRIPLE) are parameters the way link_ud_guest.sh is: defaults are
# the arm64 container (W=/work R=/repo, guest_arch.inc from uname). No-arg
# invocation keeps that compile argv: macos15 COMPILE_TRIPLE, the four -I
# paths, -module-cache-path $W/fe/modcache, then link via
# $R/scripts/link_ud_guest.sh. x86 passes W/R/TRIPLE/SDK/OUT/MODULE_CACHE.
#
# After a successful link, $OUT.inputs records object shas + libCFTest sha +
# the reconstructed clang-18 -nostdlib link argv. A later run whose stamp
# matches reuses the binary (no compile, no link).
#
# THE GOLDEN IS REGENERATED FROM THE COMMITTED FILE ON EVERY BUILD, never
# hand-carried. If the oracle re-emits it, the next build picks it up and its
# sha256 changes on the scoreboard's own header, so a board and the golden it
# was scored against can always be tied together after the fact.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
PRINT_ARGV=0
if [ "${1:-}" = "--print-argv" ]; then
    PRINT_ARGV=1
    shift
fi

W=${W:-/work}
R=${R:-/repo}
# shellcheck disable=SC1091
. "$HERE/guest_arch.inc"
SDK=${SDK:-$W/fe/sysroot}
LLD=${LLD_BIN:-/usr/lib/llvm-18/bin}
OUT=${OUT:-$W/bin/ud_score_guest}
GEN=${GEN:-$W/oracle/GuestGolden.swift}
MCACHE=${MODULE_CACHE:-$W/fe/modcache}
STAMP=${STAMP:-$OUT.inputs}
RUNNER=${RUNNER:-$W/fe/score_runner.o}
LINK=${LINK:-$R/scripts/link_ud_guest.sh}

CC=${CC:-}
if [ -z "$CC" ]; then
    if command -v clang-18 >/dev/null 2>&1; then CC=clang-18
    elif command -v clang >/dev/null 2>&1; then CC=clang
    else
        echo "build_ud_score_guest: no clang-18/clang" >&2
        exit 2
    fi
fi

# Same object set as link_ud_guest.sh with RUNNER=$W/fe/score_runner.o.
# collections/_RopeModule.o XOR fe/_RopeModule.o, never both.
ud_score_guest_objs() {
    local o
    local -a objs=(
        "$RUNNER"
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
    if [ -f "$W/fe/collections/_RopeModule.o" ]; then
        objs+=("$W/fe/collections/_RopeModule.o")
    elif [ -f "$W/fe/_RopeModule.o" ]; then
        objs+=("$W/fe/_RopeModule.o")
    fi
    for o in "${objs[@]}"; do
        [ -f "$o" ] && printf '%s\n' "$o"
    done
}

ud_score_guest_rope() {
    if [ -f "$W/fe/collections/_RopeModule.o" ]; then
        printf 'collections/_RopeModule.o\n'
    elif [ -f "$W/fe/_RopeModule.o" ]; then
        printf 'fe/_RopeModule.o\n'
    else
        printf 'none\n'
    fi
}

# clang-18 -nostdlib argv matching link_ud_guest.sh (tbd-first -L, -l set,
# libCFTest + libswiftcompat by path). Used for the inputs stamp, not to
# replace the linker.
ud_score_guest_link_argv() {
    local o
    local -a inputs=() libdirs dylibs
    while IFS= read -r o; do
        [ -n "$o" ] || continue
        inputs+=("$o")
    done < <(ud_score_guest_objs)
    libdirs=(-L"$SDK/usr/lib/swift" -L"$SDK/usr/lib" -L"$W/lib")
    dylibs=(-lswiftCore -lswiftDarwin -lswift_StringProcessing
            -lswiftSynchronization -lswift_errno -lobjc -lSystem
            "$W/lib/libCFTest.dylib" "$W/lib/libswiftcompat.dylib")
    printf '%s' "$CC -target $TRIPLE -isysroot $SDK -fuse-ld=lld -B $LLD -nostdlib"
    printf ' %s' "${libdirs[@]}"
    printf ' -Wl,-rpath,/usr/lib/swift -Wl,-rpath,@loader_path'
    printf ' %s' "${inputs[@]}" "${dylibs[@]}"
    printf ' -o %s\n' "$OUT"
}

ud_score_guest_stamp_text() {
    local o rel sha cftest
    printf 'recipe=ud_score_guest.1\n'
    while IFS= read -r o; do
        [ -n "$o" ] || continue
        rel=${o#"$W/"}
        if [ -f "$o" ]; then
            sha=$(sha256sum "$o" | awk '{print $1}')
        else
            sha=ABSENT
        fi
        printf 'obj:%s=%s\n' "$rel" "$sha"
    done < <(ud_score_guest_objs)
    if [ -f "$W/lib/libCFTest.dylib" ]; then
        cftest=$(sha256sum "$W/lib/libCFTest.dylib" | awk '{print $1}')
    else
        cftest=ABSENT
    fi
    printf 'libCFTest=%s\n' "$cftest"
    printf 'link_argv=%s\n' "$(ud_score_guest_link_argv | tr '\n' ' ' | sed 's/ *$//')"
}

ud_score_guest_stamp_matches() {
    local tmp st
    [ -f "$OUT" ] || return 1
    [ -f "$STAMP" ] || return 1
    [ -f "$RUNNER" ] || return 1
    tmp=$(mktemp)
    ud_score_guest_stamp_text > "$tmp"
    set +e
    cmp -s "$tmp" "$STAMP"
    st=$?
    set -e
    rm -f "$tmp"
    [ "$st" -eq 0 ]
}

# Canonical compile argv (no-arg / arm64). SWIFTC_EXTRA is empty here; x86
# appends CShims / collections / -runtime-compatibility-version none.
ud_score_guest_print_compile_argv() {
    printf 'swiftc -c -O -wmo -module-name ud_score_guest'
    printf ' -target %s -sdk %s' "$COMPILE_TRIPLE" "$SDK"
    printf ' -I %s/fe/module -I %s/fe -I %s/fe/collections -I %s/fe/os' "$W" "$W" "$W" "$W"
    printf ' -I %s/include/CFPreferencesMinimal' "$R"
    printf ' -module-cache-path %s' "$MCACHE"
    if [ -n "${SWIFTC_EXTRA:-}" ]; then
        printf ' %s' $SWIFTC_EXTRA
    fi
    printf ' %s/fe/score-src/main.swift %s/fe/score-src/GuestGolden.swift %s/fe/score-src/Provenance.swift' \
        "$W" "$W" "$W"
    printf ' -o %s\n' "$RUNNER"
}

if [ "$PRINT_ARGV" -eq 1 ]; then
    echo "UD_SCORE_W=$W"
    echo "UD_SCORE_R=$R"
    echo "UD_SCORE_ARCH=$ARCH"
    echo "UD_SCORE_TRIPLE=$TRIPLE"
    echo "UD_SCORE_COMPILE_TRIPLE=$COMPILE_TRIPLE"
    echo "UD_SCORE_SDK=$SDK"
    echo "UD_SCORE_OUT=$OUT"
    echo "UD_SCORE_GEN=$GEN"
    echo "UD_SCORE_MODULE_CACHE=$MCACHE"
    echo "UD_SCORE_CC=$CC"
    echo "UD_SCORE_NOSTDLIB=-nostdlib"
    echo "UD_SCORE_LINK_LIBS=-lswiftCore -lswiftDarwin -lswift_StringProcessing -lswiftSynchronization -lswift_errno -lobjc -lSystem libCFTest.dylib libswiftcompat.dylib"
    echo "UD_SCORE_ROPE=$(ud_score_guest_rope)"
    echo "UD_SCORE_LINK=OUT=$OUT RUNNER=$RUNNER bash $LINK"
    echo "UD_SCORE_COMPILE: $(ud_score_guest_print_compile_argv)"
    exit 0
fi

if [ "${SKIP_SWIFTC:-0}" != 1 ]; then
    # The generated file is produced on the HOST by scripts/stage_ud_oracle.sh --
    # this container has no python. Refuse rather than compile without it: an
    # absent golden would give an empty scoreboard, and an empty scoreboard scores
    # 100%.
    if [ ! -f "$GEN" ]; then
        echo "FATAL: the embedded golden is not staged at $GEN" >&2
        echo "  Run on the macOS host:  scripts/stage_ud_oracle.sh" >&2
        exit 2
    fi
fi

if ud_score_guest_stamp_matches; then
    echo "==> reuse $OUT (inputs match $STAMP)"
    echo "UD_SCORE_STATUS=satisfied"
    exit 0
fi

if [ "${SKIP_SWIFTC:-0}" = 1 ]; then
    if [ ! -f "$RUNNER" ]; then
        echo "FATAL: SKIP_SWIFTC=1 but score runner is missing at $RUNNER" >&2
        exit 2
    fi
else
    echo "==> golden: $(grep -m1 '// sha256:' "$GEN" || echo '(no sha line)')"
    echo "            $(grep -m1 '// Rows:' "$GEN" || true)"

    # The runner is TOP-LEVEL CODE, and in a whole-module build Swift allows that
    # in exactly one file, named main.swift. Copying it under that name is the
    # whole reason for this step -- compiled under its own name the error is
    # "statements are not allowed at the top level", which reads like a problem
    # with the code rather than with its filename.
    BUILDDIR=$W/fe/score-src
    rm -rf "$BUILDDIR"; mkdir -p "$BUILDDIR"
    cp "$R/tests/ud_score_guest.swift" "$BUILDDIR/main.swift"
    cp "$GEN" "$BUILDDIR/GuestGolden.swift"

    # THE ROUTE LINE. A scoreboard has to name what it measured, or a number from
    # it cannot be attributed to anything later. "The guest route" is not an
    # artifact -- these five files are, and any of them can move independently:
    # the port source, the CF seam it talks through, our CoreFoundation, the
    # FoundationEssentials module, and the golden. Hashing them AT BUILD TIME and
    # baking them into the binary means the board carries its own provenance,
    # rather than a report writer recalling it afterwards.
    sha() { [ -f "$1" ] && sha256sum "$1" | cut -c1-16 || echo "MISSING"; }
    {
      echo "// GENERATED by scripts/build_ud_score_guest.sh -- DO NOT EDIT."
      echo "let ROUTE: [(String, String)] = ["
      echo "  (\"port\",       \"UserDefaults.swift            $(sha "$R/src/overlay/UserDefaults.swift")\"),"
      echo "  (\"seam\",       \"UserDefaultsBridge_Guest.swift $(sha "$R/src/overlay/UserDefaultsBridge_Guest.swift")\"),"
      echo "  (\"CoreFoundation\", \"libCFTest.dylib          $(sha "$W/lib/libCFTest.dylib")\"),"
      echo "  (\"FoundationEssentials\", \"FoundationEssentials.o $(sha "$W/fe/module/FoundationEssentials.o")\"),"
      echo "  (\"port object\", \"UserDefaultsGuest.o           $(sha "$W/fe/UserDefaultsGuest.o")\"),"
      echo "]"
    } > "$BUILDDIR/Provenance.swift"
    cat "$BUILDDIR/Provenance.swift" | sed 's/^/    /'

    # COMPILE at macOS 15, LINK at 13. Not a mismatch to paper over: the
    # FoundationEssentials module this runner imports declares a minimum deployment
    # target of macOS 15.0, so compiling below it is a hard error; the guest root's
    # other objects were built the same way and link at 13.0 with a warning. Using
    # one number for both would either fail to compile or change the binary's
    # LC_BUILD_VERSION away from the configuration already proven to load.
    echo "==> compiling the scoreboard runner (target $COMPILE_TRIPLE)"
    mkdir -p "$(dirname "$RUNNER")" "$MCACHE"
    # No-arg argv is the original recipe (SWIFTC_EXTRA unset). x86 appends.
    if [ -n "${SWIFTC_EXTRA:-}" ]; then
        # shellcheck disable=SC2086
        swiftc -c -O -wmo -module-name ud_score_guest \
          -target "$COMPILE_TRIPLE" -sdk "$SDK" \
          -I "$W/fe/module" -I "$W/fe" -I "$W/fe/collections" -I "$W/fe/os" \
          -I "$R/include/CFPreferencesMinimal" \
          -module-cache-path "$MCACHE" \
          $SWIFTC_EXTRA \
          "$BUILDDIR/main.swift" "$BUILDDIR/GuestGolden.swift" "$BUILDDIR/Provenance.swift" \
          -o "$RUNNER"
    else
        swiftc -c -O -wmo -module-name ud_score_guest \
          -target "$COMPILE_TRIPLE" -sdk "$SDK" \
          -I "$W/fe/module" -I "$W/fe" -I "$W/fe/collections" -I "$W/fe/os" \
          -I "$R/include/CFPreferencesMinimal" \
          -module-cache-path "$MCACHE" \
          "$BUILDDIR/main.swift" "$BUILDDIR/GuestGolden.swift" "$BUILDDIR/Provenance.swift" \
          -o "$RUNNER"
    fi
fi

echo "==> linking"
mkdir -p "$(dirname "$OUT")"
OUT="$OUT" RUNNER="$RUNNER" W="$W" SDK="$SDK" LLD_BIN="$LLD" \
    bash "$LINK"
ud_score_guest_stamp_text > "$STAMP"
echo "==> wrote $STAMP"
echo "UD_SCORE_STATUS=cold-built"
