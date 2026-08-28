#!/bin/bash
# swift_gate.sh -- the differential for rung (q): Swift classes and generics.
#
#   scripts/swift_gate.sh              run BOTH sides and compare (macOS host)
#   scripts/swift_gate.sh --record     re-record the macOS baseline, nothing else
#   scripts/swift_gate.sh --linux      Linux side only, compare against the baseline
#   scripts/swift_gate.sh --build-image  force a rebuild of the Swift test bed
#
# WHAT THIS GATE IS FOR, because "run a Swift program" undersells it.
#
# Two loader bugs used to make every Swift CLASS and every Swift GENERIC abort
# before main, and this fixture is the shape of program that finds them again:
#
#   (1) SwiftTLSContext::get() adopts pthread key 100 -- Apple's reserved
#       __PTK_FRAMEWORK_SWIFT_KEY0 -- with pthread_key_init_np, and reads it
#       back with plain pthread_getspecific. libSystem bound-checked that key
#       against 64 and forwarded the accessors to glibc's unrelated key
#       namespace, so tls_init_once() aborted with "failed to set destructor".
#       Instantiating class metadata or a generic witness table is the first
#       thing that reaches it, so nothing object-oriented could run at all.
#
#   (2) libSystem exported diagnostic swift_retain/swift_release stubs, and
#       machorun's flat lookup returns the first definition in load order.
#       libSystem loads before libswiftCore, so objc4's fast-path refcounting
#       bound to the abort with the real implementation one image away.
#
# SO THE GATE LINKS THE FIXTURE TWICE, in both dylib orders, and requires both
# to pass. That is the whole point of doing it twice: bug (2) was invisible in
# the -lswiftCore-first order, which is exactly why it survived long enough to
# become a documented "load-bearing" workaround. If someone reintroduces a
# swift_* definition into libSystem, the libSystem-first run fails here.
#
# METHOD, the same discipline as scripts/difftest.sh and scripts/quartz_pixel.sh:
#
#   * The macOS side BUILDS AND EXECUTES the oracle every run, with Apple's own
#     swiftc, and reports BASELINE-DRIFT rather than PASS if macOS itself no
#     longer produces the recorded output.
#   * The Linux side builds the same source with the swift.org Linux toolchain
#     cross-targeting arm64-apple-macos, links it against the libswiftCore that
#     ~/swiftcore-macho cross-built, and runs it under build/machorun.
#   * A mismatch is reported, never recorded. tests/expected/ is written only
#     by --record, and only on macOS.
#
# ONE HONEST DEVIATION FROM THE REST OF THE CORPUS. Every other fixture in
# tests/bin is a committed Mach-O built by APPLE'S toolchain, and both sides run
# those same bytes. This one cannot be, yet: our libswiftCore imports 29 symbols
# that machorun's userland does not carry, they live in libswiftcompat.dylib,
# and a guest has to link that explicitly -- so an Apple-built Swift binary
# fails to load here with an undefined __ZTVN10__cxxabiv117__class_type_infoE.
# Measured, not assumed; docs/UNIMPLEMENTED.md#swift-compat has it. Until that
# closes, the two sides run two binaries built from one source, and the thing
# being compared is the program's behaviour rather than the loader's handling
# of one specific set of bytes. Saying so is better than quietly grading a
# weaker comparison as if it were the strong one.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/harness/common.sh"

# Like objc44 and unlike difftest, this gate links against and RUNS the shipped
# dylibs without rebuilding them, so a dylib older than its own source makes
# both link orders pass or fail about the previous build. Warn rather than
# refuse: this gate skips cleanly when the Swift runtime is not staged, and a
# hard stop would block a run that is still worth something.
bash "$ROOT/scripts/check_stale.sh" --warn >&2

ID=swift_class
SRC="$ROOT/tests/src/$ID.swift"
EXP="$ROOT/tests/expected"
ACT="$ROOT/tests/actual/swift"
IMAGE="${MACHORUN_SWIFT_IMAGE:-machorun-swift:6.2.4}"
LOADER_REL="${MACHORUN_LOADER:-build/machorun}"

# The two link orders. The name is the variant id; the value is the tail of the
# link line, and the ONLY difference between them is where -lSystem sits.
ORDER_IDS=(system-first swiftcore-first)
ORDER_SYSTEM_FIRST='-lSystem -lobjc -lswiftCore /work/darwin/usr/lib/libswiftcompat.dylib'
ORDER_SWIFTCORE_FIRST='-lswiftCore /work/darwin/usr/lib/libswiftcompat.dylib -lSystem -lobjc'

DO_ORACLE=1
DO_LINUX=1
RECORD=0
FORCE_BUILD=0
for a in "$@"; do
    case "$a" in
        --record) RECORD=1; DO_LINUX=0 ;;
        --linux)  DO_ORACLE=0 ;;
        --build-image) FORCE_BUILD=1 ;;
        -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
        *) die "unknown option $a" ;;
    esac
done

[ -f "$SRC" ] || die "missing fixture source $SRC"
mkdir -p "$ACT"

fail=0
note() { printf '%s\n' "$*"; }

# =========================================================== the macOS oracle
# Apple's swiftc, Apple's libswiftCore, macOS's own dyld. Nothing about this
# half involves machorun, and that is the point of having it.
if [ "$DO_ORACLE" = 1 ] || [ "$RECORD" = 1 ]; then
    if [ "$(uname -s)" != "Darwin" ]; then
        if [ "$RECORD" = 1 ]; then
            die "--record needs macOS: the baseline is Apple's toolchain and Apple's runtime."
        fi
        note "${C_YEL}oracle skipped${C_RESET} -- not on macOS; grading against the committed baseline"
        DO_ORACLE=0
    else
        command -v xcrun >/dev/null 2>&1 || die "xcrun not found; the oracle needs Xcode's Swift"
        printf '%soracle: building %s with Apple swiftc%s\n' "$C_DIM" "$ID" "$C_RESET"
        # The two -disable-implicit-*-module-import flags are not tuning. Swift
        # implicitly imports _Concurrency and _StringProcessing into every file;
        # the libswiftCore we cross-build is core-only, so the Linux side has
        # neither. Suppressing them on BOTH sides keeps the two programs the
        # same program instead of letting the oracle quietly use more stdlib
        # than the thing it is grading.
        if ! xcrun swiftc -target arm64-apple-macos13.0 -O \
                -Xfrontend -disable-implicit-string-processing-module-import \
                -Xfrontend -disable-implicit-concurrency-module-import \
                -o "$ACT/$ID.macos" "$SRC" > "$ACT/$ID.build.log" 2>&1; then
            cat "$ACT/$ID.build.log" >&2
            die "oracle build failed"
        fi
        rc=0
        ( export LC_ALL=C LANG=C TZ=UTC; run_limited "$ACT/$ID.macos" ) \
            > "$ACT/$ID.macos.stdout" 2> "$ACT/$ID.macos.stderr" || rc=$?
        printf '%d\n' "$rc" > "$ACT/$ID.macos.exit"

        if [ "$RECORD" = 1 ]; then
            cp "$ACT/$ID.macos.stdout" "$EXP/$ID.stdout"
            cp "$ACT/$ID.macos.stderr" "$EXP/$ID.stderr"
            cp "$ACT/$ID.macos.exit"   "$EXP/$ID.exit"
            note "${C_GRN}recorded${C_RESET} $EXP/$ID.{stdout,stderr,exit}  (exit $rc)"
            exit 0
        fi

        # Drift: macOS no longer agrees with what was recorded from macOS. The
        # Linux comparison is void until that is understood, so it is never
        # reported as a pass.
        if [ -f "$EXP/$ID.exit" ]; then
            if ! cmp -s "$ACT/$ID.macos.stdout" "$EXP/$ID.stdout" ||
               [ "$(cat "$ACT/$ID.macos.exit")" != "$(cat "$EXP/$ID.exit")" ]; then
                printf '%sBASELINE-DRIFT%s  macOS itself no longer produces the recorded output.\n' \
                    "$C_RED" "$C_RESET"
                diff "$EXP/$ID.stdout" "$ACT/$ID.macos.stdout" | head -10
                exit 1
            fi
            note "oracle: matches the recorded baseline (exit $(cat "$EXP/$ID.exit"))"
        else
            note "${C_YEL}no baseline recorded${C_RESET} -- run scripts/swift_gate.sh --record"
            exit 1
        fi
    fi
fi

[ "$DO_LINUX" = 1 ] || exit $fail
[ -f "$EXP/$ID.exit" ] || die "no baseline at $EXP/$ID.exit; record it on macOS first"

# ============================================================ the Linux side
skip() { printf '%sSKIPPED%s  %s\n' "$C_YEL" "$C_RESET" "$1"; exit 0; }

command -v docker >/dev/null 2>&1 || skip "docker not installed on this host"
docker info >/dev/null 2>&1        || skip "docker daemon not reachable"

if ! bash "$ROOT/scripts/stage_swiftcore.sh" --check >/dev/null 2>&1; then
    printf '%sSKIPPED%s  the cross-built Swift runtime is not staged:\n' "$C_YEL" "$C_RESET"
    bash "$ROOT/scripts/stage_swiftcore.sh" --check
    printf '        stage it with  scripts/stage_swiftcore.sh\n'
    exit 0
fi

if [ "$FORCE_BUILD" = 1 ] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    printf '%sbuilding %s (first run only)%s\n' "$C_DIM" "$IMAGE" "$C_RESET"
    docker build --platform linux/arm64 -t "$IMAGE" -f "$ROOT/harness/Dockerfile.swift" "$ROOT/harness" \
        || skip "could not build the Swift test-bed image $IMAGE"
fi

# ------------------------------------------- will the subject hold still?
#
# THIS WAS THE ONE GATE OF FIVE WITH NO BRACKET, and it is the gate most exposed
# to the thing a bracket detects: it RUNS the shipped dylibs without rebuilding
# them, and darwin/usr/lib/swift/libswiftCore.dylib is re-staged by a different
# repo (~/swiftcore-macho, scripts/stage_swiftcore.sh) while this runs. A restage
# landing between the link and the run gives two PASSes about two runtimes.
# check_stale.sh above answers a different question -- is the artefact older than
# its source -- and cannot see a change that happens DURING the run.
GATE_FP_BEFORE="$(gate_fingerprint)"
GATE_HEAD_BEFORE=""
git -C "$ROOT" rev-parse --short HEAD >/dev/null 2>&1 && \
    GATE_HEAD_BEFORE="$(git -C "$ROOT" rev-parse --short HEAD)"

printf '%sbuilding and running %s under machorun (linux/arm64, %s)%s\n' \
    "$C_BLD" "$ID" "$IMAGE" "$C_RESET"
printf '%s\n' "----------------------------------------------------------------------"

CONTAINER_SCRIPT="$(cat <<'INNER'
set -u
cd /work
OUT=/work/tests/actual/swift
mkdir -p "$OUT"

# The resource dir's `shims` half must come from the compiler doing the
# compiling, not from the stdlib build -- they are the C headers the frontend
# itself includes. scripts/stage_swiftcore.sh deliberately does not stage them.
RES=/tmp/swift-res
rm -rf "$RES"; cp -a /work/build/swift-res "$RES"
cp -a /usr/lib/swift/shims "$RES/shims"

# Cross-compile for Darwin on Linux. -sdk is machorun's own header-only,
# .tbd-only SDK; -O avoids needing SwiftOnoneSupport, which our core-only
# stdlib build does not produce.
if ! swiftc -c -target arm64-apple-macos13.0 -sdk /work/sdk -resource-dir "$RES" -O \
        /work/tests/src/swift_class.swift -o /tmp/swift_class.o \
        > "$OUT/swift_class.compile.log" 2>&1; then
    echo "COMPILE-FAILED"
    exit 0
fi

link_and_run() { # link_and_run <variant> <link tail...>
    variant="$1"; shift
    # -B picks Ubuntu's ld64.lld-18 over the Swift toolchain's, which refuses
    # Mach-O output. -nostdlib because the Darwin libraries are named below.
    if ! clang -target arm64-apple-macos13.0 -isysroot /work/sdk \
            -fuse-ld=lld -B /usr/lib/llvm-18/bin -nostdlib \
            -L/work/sdk/usr/lib -L"$RES/macosx/arm64" \
            /tmp/swift_class.o "$@" \
            -o "/tmp/swift_class.$variant" \
            > "$OUT/swift_class.$variant.link.log" 2>&1; then
        echo "LINK-FAILED $variant"
        return
    fi
    rc=0
    LC_ALL=C LANG=C TZ=UTC timeout -k 2 60 "$LOADER" "/tmp/swift_class.$variant" \
        > "$OUT/swift_class.$variant.stdout" 2> "$OUT/swift_class.$variant.stderr" || rc=$?
    echo "$rc" > "$OUT/swift_class.$variant.exit"
}

LOADER="${MACHORUN_LOADER:-build/machorun}"
if [ ! -x "$LOADER" ]; then echo "NO-LOADER"; exit 0; fi
LOADER="$(cd "$(dirname "$LOADER")" && pwd)/$(basename "$LOADER")"

link_and_run system-first    $ORDER_SYSTEM_FIRST
link_and_run swiftcore-first $ORDER_SWIFTCORE_FIRST
echo "RAN"
INNER
)"

set +e
result="$(docker run --rm -i --platform linux/arm64 \
    -v "$ROOT:/work" \
    -v "$ROOT/tests/expected:/work/tests/expected:ro" \
    -e "MACHORUN_LOADER=$LOADER_REL" \
    -e "ORDER_SYSTEM_FIRST=$ORDER_SYSTEM_FIRST" \
    -e "ORDER_SWIFTCORE_FIRST=$ORDER_SWIFTCORE_FIRST" \
    -w /work "$IMAGE" bash -s <<<"$CONTAINER_SCRIPT" 2>&1)"
set -e

case "$(printf '%s\n' "$result" | tail -1)" in
    RAN) ;;
    NO-LOADER)      skip "loader binary $LOADER_REL was not produced by the build" ;;
    COMPILE-FAILED) printf '%sCOMPILE FAILED%s -- see tests/actual/swift/%s.compile.log\n' \
                        "$C_RED" "$C_RESET" "$ID"
                    tail -20 "$ACT/$ID.compile.log" 2>/dev/null; exit 1 ;;
    LINK-FAILED*)   printf '%sLINK FAILED%s -- see tests/actual/swift/*.link.log\n' \
                        "$C_RED" "$C_RESET"; exit 1 ;;
    *) skip "container run failed: $(printf '%s' "$result" | tail -3 | tr '\n' ' ')" ;;
esac

# ------------------------------------------- did the subject hold still?
# Checked BEFORE any verdict is printed, as difftest does: a scoreboard
# assembled from two runtimes looks exactly like one assembled from one, so
# there is nothing worth showing and nothing worth salvaging.
GATE_FP_AFTER="$(gate_fingerprint)"
gate_check_stable "$GATE_FP_BEFORE" "$GATE_FP_AFTER" "loader and darwin/ dylibs" || exit 2
if [ -n "$GATE_HEAD_BEFORE" ]; then
    gate_check_stable "$GATE_HEAD_BEFORE" "$(git -C "$ROOT" rev-parse --short HEAD)" "git HEAD" || exit 2
fi

# The subject, named on the scoreboard. A verdict is about a specific tree, and
# a result that does not say which one cannot be quoted later without guessing.
printf '%ssubject: %sbuild %s%s\n' "$C_DIM" \
    "${GATE_HEAD_BEFORE:+HEAD $GATE_HEAD_BEFORE }" "$GATE_FP_BEFORE" "$C_RESET"

# ================================================================== grading
for v in "${ORDER_IDS[@]}"; do
    d=""
    if [ ! -f "$ACT/$ID.$v.exit" ]; then
        d="no result produced"
    else
        ae="$(cat "$ACT/$ID.$v.exit")"; ee="$(cat "$EXP/$ID.exit")"
        if [ "$ae" != "$ee" ]; then
            d="exit $ae, expected $ee"
        elif ! cmp -s "$ACT/$ID.$v.stdout" "$EXP/$ID.stdout"; then
            d="stdout differs: $(diff "$EXP/$ID.stdout" "$ACT/$ID.$v.stdout" | head -1)"
        elif ! cmp -s "$ACT/$ID.$v.stderr" "$EXP/$ID.stderr"; then
            d="stderr differs: $(head -c 200 "$ACT/$ID.$v.stderr")"
        fi
    fi
    if [ -z "$d" ]; then
        printf '  %-20s %sPASS%s\n' "$v" "$C_GRN" "$C_RESET"
    else
        printf '  %-20s %sFAIL%s  %s\n' "$v" "$C_RED" "$C_RESET" "$d"
        # awk, not sed: these aborts are written with write(2) and carry no
        # trailing newline, so sed would run the next line onto the same one.
        [ -s "$ACT/$ID.$v.stderr" ] && \
            awk 'NR<=5 { print "      " $0 }' "$ACT/$ID.$v.stderr"
        fail=1
    fi
done

printf '%s\n' "----------------------------------------------------------------------"
if [ "$fail" = 0 ]; then
    printf '%sSwift classes, generics and dynamic dispatch run under machorun%s\n' "$C_GRN" "$C_RESET"
    printf 'in both dylib orders, byte-identical to macOS.\n'
else
    printf '%srung (q) is not green%s -- results in tests/actual/swift/\n' "$C_RED" "$C_RESET"
fi
exit $fail
