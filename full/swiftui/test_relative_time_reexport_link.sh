#!/usr/bin/env bash
# Reproduce the d53a3510 libFoundation argv against ld64.lld-18.
#
# The package @rpath facade re-exports /usr/lib/libOpenRelativeTime.dylib
# (machorun is_runtime). ld64.lld searches that absolute install name
# through -syslibroot, then each -L. The umbrella already has -L$PACKAGE
# for -lFoundationEssentials etc., so the first hit is the facade itself
# (no symbols). -L$RUNROOT after that never runs. The undefined is
# _openui_relative_time_v1_format, not "unable to locate re-export".
#
# Passing the Darwin-root runtime dylib as an explicit input binds the
# symbol and keeps LC_ID /usr/lib/libOpenRelativeTime.dylib.
set -euo pipefail

W=${W:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)}
# shellcheck source=../../full/scripts/guest_arch.inc
. "$W/full/scripts/guest_arch.inc"
MRROOT_CANDIDATE=$W/scratch/mrroot_full${FULL_OUT_SUFFIX}
SYS_CANDIDATE=$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}
if [ -f "$MRROOT_CANDIDATE/darwin/usr/lib/libSystem.B.dylib" ] \
    && [ -d "$SYS_CANDIDATE/usr/lib" ]; then
    MRROOT=$MRROOT_CANDIDATE
    SYS=$SYS_CANDIDATE
else
    MRROOT=$W/scratch/mrroot_full
    SYS=$W/scratch/sysroot_fe4
    TARGET=arm64-apple-macos15.0
    ARCH=arm64
fi
[ -d "$SYS/usr/lib" ] || {
    echo "relative_time_reexport_link: Darwin sysroot is missing: $SYS" >&2
    exit 2
}
[ -f "$MRROOT/darwin/usr/lib/libSystem.B.dylib" ] || {
    echo "relative_time_reexport_link: libSystem.B.dylib is missing: $MRROOT" >&2
    exit 2
}

WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/relative-time-reexport-link.XXXXXX")
trap 'rm -rf "$WORKDIR"' EXIT
mkdir -p "$WORKDIR/runroot/darwin/usr/lib" "$WORKDIR/package"

clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$W/full/relativetime/include" \
    -c "$W/full/relativetime/OpenRelativeTimeBridge.c" \
    -o "$WORKDIR/bridge.o"
RUNTIME=$WORKDIR/runroot/darwin/usr/lib/libOpenRelativeTime.dylib
ld64.lld-18 -arch "$ARCH" -platform_version macos 15.0 15.0 -syslibroot "$SYS" \
    -dylib -dead_strip -undefined dynamic_lookup \
    -install_name /usr/lib/libOpenRelativeTime.dylib \
    -o "$RUNTIME" "$WORKDIR/bridge.o"
[ "$(llvm-otool-18 -D "$RUNTIME" | tail -n 1)" = "/usr/lib/libOpenRelativeTime.dylib" ] \
    || { echo "relative_time_reexport_link: runtime LC_ID drifted" >&2; exit 2; }
llvm-nm-18 --defined-only --extern-only --just-symbol-name "$RUNTIME" \
    | grep -Fxq _openui_relative_time_v1_format \
    || { echo "relative_time_reexport_link: runtime does not define _openui_relative_time_v1_format" >&2; exit 2; }

FACADE=$WORKDIR/package/libOpenRelativeTime.dylib
ld64.lld-18 -arch "$ARCH" -platform_version macos 15.0 15.0 -syslibroot "$SYS" \
    -L"$MRROOT/darwin/usr/lib" -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libOpenRelativeTime.dylib -rpath @loader_path \
    -o "$FACADE" \
    -reexport_library "$RUNTIME" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib"
if llvm-nm-18 --defined-only --extern-only --just-symbol-name "$FACADE" 2>/dev/null \
    | grep -Fq _openui_relative_time_v1_format; then
    echo "relative_time_reexport_link: facade unexpectedly defines _openui_relative_time_v1_format" >&2
    exit 2
fi
llvm-otool-18 -l "$FACADE" | awk '
    $1 == "cmd" && $2 == "LC_REEXPORT_DYLIB" { reexport = 1 }
    reexport && $1 == "name" && $2 == "/usr/lib/libOpenRelativeTime.dylib" { found = 1 }
    END { exit found ? 0 : 1 }
' || {
    echo "relative_time_reexport_link: facade does not re-export /usr/lib/libOpenRelativeTime.dylib" >&2
    exit 2
}

cat > "$WORKDIR/consumer.c" <<'EOF'
extern int openui_relative_time_v1_format(void);
int consumer(void) { return openui_relative_time_v1_format(); }
EOF
clang-18 -target "$TARGET" -isysroot "$SYS" -std=c11 -O2 \
    -c "$WORKDIR/consumer.c" -o "$WORKDIR/consumer.o"

# d53a3510 argv: -L$PACKAGE already on the umbrella, then -L$RUNROOT + facade.
set +e
ld64.lld-18 -arch "$ARCH" -platform_version macos 15.0 15.0 -syslibroot "$SYS" \
    -dylib -dead_strip -ignore_auto_link \
    -install_name @rpath/libConsumer.dylib \
    -o "$WORKDIR/consumer.fail.dylib" \
    "$WORKDIR/consumer.o" \
    -L"$WORKDIR/package" \
    -L"$WORKDIR/runroot/darwin/usr/lib" \
    "$FACADE" \
    --print-dylib-search \
    >"$WORKDIR/fail.trace" 2>"$WORKDIR/fail.err"
fail_rc=$?
set -e
[ "$fail_rc" -ne 0 ] \
    || { echo "relative_time_reexport_link: shadowed facade consumer unexpectedly linked" >&2; exit 2; }
grep -Fq '_openui_relative_time_v1_format' "$WORKDIR/fail.err" \
    || { echo "relative_time_reexport_link: shadowed facade miss did not name the relative-time symbol" >&2; cat "$WORKDIR/fail.err" >&2; exit 2; }
grep -Fq 'unable to locate re-export' "$WORKDIR/fail.err" \
    && { echo "relative_time_reexport_link: shadowed facade miss was a missing re-export, not a package -L hit" >&2; cat "$WORKDIR/fail.err" >&2; exit 2; }
grep -Fq "package/libOpenRelativeTime.dylib, found" "$WORKDIR/fail.trace" \
    || { echo "relative_time_reexport_link: re-export search did not hit the package facade" >&2; cat "$WORKDIR/fail.trace" >&2; exit 2; }
grep -Fq "runroot/darwin/usr/lib/libOpenRelativeTime.dylib, found" "$WORKDIR/fail.trace" \
    && { echo "relative_time_reexport_link: re-export search reached the runtime after the package facade" >&2; cat "$WORKDIR/fail.trace" >&2; exit 2; }

ld64.lld-18 -arch "$ARCH" -platform_version macos 15.0 15.0 -syslibroot "$SYS" \
    -dylib -dead_strip -ignore_auto_link -undefined dynamic_lookup \
    -install_name @rpath/libConsumer.dylib \
    -o "$WORKDIR/consumer.ok.dylib" \
    "$WORKDIR/consumer.o" \
    "$RUNTIME"
[ "$(llvm-otool-18 -D "$RUNTIME" | tail -n 1)" = "/usr/lib/libOpenRelativeTime.dylib" ] \
    || { echo "relative_time_reexport_link: runtime LC_ID changed after consumer link" >&2; exit 2; }
llvm-otool-18 -L "$WORKDIR/consumer.ok.dylib" \
    | awk '$1 == "/usr/lib/libOpenRelativeTime.dylib" { count++ } END { exit count == 1 ? 0 : 1 }' \
    || { echo "relative_time_reexport_link: consumer did not LC_LOAD the /usr/lib runtime image" >&2; exit 2; }
llvm-otool-18 -L "$WORKDIR/consumer.ok.dylib" \
    | awk '$1 == "@rpath/libOpenRelativeTime.dylib" { count++ } END { exit count == 0 ? 0 : 1 }' \
    || { echo "relative_time_reexport_link: consumer LC_LOADed the @rpath facade" >&2; exit 2; }
llvm-objdump-18 --macho --lazy-bind "$WORKDIR/consumer.ok.dylib" \
    | grep -Eq 'libOpenRelativeTime[[:space:]]+_openui_relative_time_v1_format' \
    || { echo "relative_time_reexport_link: consumer did not bind _openui_relative_time_v1_format through the runtime" >&2; exit 2; }

echo "RELATIVE_TIME_REEXPORT_LINK_OK facade=package-L-shadows-runtime runtime=explicit-input id=/usr/lib/libOpenRelativeTime.dylib"
