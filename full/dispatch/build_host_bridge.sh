#!/usr/bin/env bash
# Build and verify the Linux libOpenDispatchHost.so ELF helper.
# Both the frameworks lane and the Focus widget guest gate call this script.
# Clang flags, expected export names, glibc/readelf checks, and the
# open-dispatch-host-v1 attestation rows must stay byte-identical to the
# inlined host-libdispatch block that used to live in
# full/frameworks/build_core_guest_package.sh.

set -euo pipefail

W=''
HOST_DIR=''
WORK_DIR=''
ATTESTATION_DIR=''
LEDGER_STYLE=core
REFUSE_PREFIX='core_guest_package: REFUSING -- '
HOST_ABI='ELF64-AArch64'
SKIP_RUNTIME_PIN=0
HOST_DISPATCH_SOURCE=/usr/lib/swift/linux/libdispatch.so
HOST_BLOCKS_RUNTIME_SOURCE=/usr/lib/swift/linux/libBlocksRuntime.so
EXPECTED_HOST_DISPATCH_SHA256=39e502b3a8b016073947574a932172c1dafff8c41abd15b9b9f11bef7aaf1b6b
EXPECTED_HOST_BLOCKS_RUNTIME_SHA256=47a4f774ed1f4c094f8510c50d0006fde89a837ae785236e2ed669b8db9d002d

usage() {
    echo "usage: build_host_bridge.sh --repo ROOT --host-dir DIR --work-dir DIR [options]" >&2
    exit 2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo)
            [ "$#" -ge 2 ] || usage
            W=$2; shift 2 ;;
        --host-dir)
            [ "$#" -ge 2 ] || usage
            HOST_DIR=$2; shift 2 ;;
        --work-dir)
            [ "$#" -ge 2 ] || usage
            WORK_DIR=$2; shift 2 ;;
        --attestation-dir)
            [ "$#" -ge 2 ] || usage
            ATTESTATION_DIR=$2; shift 2 ;;
        --ledger-style)
            [ "$#" -ge 2 ] || usage
            LEDGER_STYLE=$2; shift 2 ;;
        --refuse-prefix)
            [ "$#" -ge 2 ] || usage
            REFUSE_PREFIX=$2; shift 2 ;;
        --host-abi)
            [ "$#" -ge 2 ] || usage
            HOST_ABI=$2; shift 2 ;;
        --host-dispatch-source)
            [ "$#" -ge 2 ] || usage
            HOST_DISPATCH_SOURCE=$2; shift 2 ;;
        --host-blocks-runtime-source)
            [ "$#" -ge 2 ] || usage
            HOST_BLOCKS_RUNTIME_SOURCE=$2; shift 2 ;;
        --expected-libdispatch-sha256)
            [ "$#" -ge 2 ] || usage
            EXPECTED_HOST_DISPATCH_SHA256=$2; shift 2 ;;
        --expected-blocks-sha256)
            [ "$#" -ge 2 ] || usage
            EXPECTED_HOST_BLOCKS_RUNTIME_SHA256=$2; shift 2 ;;
        --skip-runtime-pin)
            SKIP_RUNTIME_PIN=1; shift ;;
        -h|--help)
            usage ;;
        *)
            echo "build_host_bridge.sh: unknown option $1" >&2
            usage ;;
    esac
done

[ -n "$W" ] && [ -n "$HOST_DIR" ] && [ -n "$WORK_DIR" ] || usage

die() {
    echo "${REFUSE_PREFIX}$*" >&2
    exit 2
}

LEDGER_TOOL=$W/scripts/env/ledger.py
[ -f "$LEDGER_TOOL" ] && [ ! -L "$LEDGER_TOOL" ] \
    || die "env ledger tool is missing or linked: $LEDGER_TOOL"

hash_file() { python3 "$LEDGER_TOOL" --style "$LEDGER_STYLE" hash-file "$1"; }
require_hash() {
    python3 "$LEDGER_TOOL" --style "$LEDGER_STYLE" require-hash "$1" "$2" "$3" || exit $?
}

mkdir -p "$HOST_DIR" "$WORK_DIR"
for host_runtime_input in "$HOST_DISPATCH_SOURCE" "$HOST_BLOCKS_RUNTIME_SOURCE"; do
    [ -f "$host_runtime_input" ] && [ ! -L "$host_runtime_input" ] \
        || die "host Dispatch runtime input is not a regular file: $host_runtime_input"
done
if [ "$SKIP_RUNTIME_PIN" -ne 1 ]; then
    require_hash "$HOST_DISPATCH_SOURCE" "$EXPECTED_HOST_DISPATCH_SHA256" \
        host-libdispatch
    require_hash "$HOST_BLOCKS_RUNTIME_SOURCE" \
        "$EXPECTED_HOST_BLOCKS_RUNTIME_SHA256" host-BlocksRuntime
fi
cp "$HOST_DISPATCH_SOURCE" "$HOST_DIR/libdispatch.so"
cp "$HOST_BLOCKS_RUNTIME_SOURCE" "$HOST_DIR/libBlocksRuntime.so"

DISPATCH_HOST=$HOST_DIR/libOpenDispatchHost.so
clang-18 -std=c11 -O2 -fPIC -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$W/full/dispatch/include" -I /usr/lib/swift -shared \
    "$W/full/dispatch/OpenDispatchHost.c" \
    -L "$HOST_DIR" -Wl,-rpath,'$ORIGIN' \
    -ldispatch -Wl,--no-as-needed -lBlocksRuntime -Wl,--as-needed -pthread \
    -o "$DISPATCH_HOST"
clang-18 -std=c11 -O2 -Wall -Wextra -Werror \
    -I "$W/full/dispatch/include" -I /usr/lib/swift \
    "$W/full/dispatch/OpenDispatchHost.c" \
    "$W/full/dispatch/OpenDispatchHostTests.c" \
    -L "$HOST_DIR" -Wl,-rpath,"$HOST_DIR" \
    -ldispatch -Wl,--no-as-needed -lBlocksRuntime -Wl,--as-needed -pthread \
    -o "$WORK_DIR/open-dispatch-host-tests"
LD_LIBRARY_PATH="$HOST_DIR" "$WORK_DIR/open-dispatch-host-tests" \
    > "$WORK_DIR/open-dispatch-host-test.log" 2>&1
grep -Fx \
    'OPEN_DISPATCH_HOST_OK global=minted private=serial specific=typed semaphore=signal,timeout async=worker after=timer tokens=contained glibc>=2.38' \
    "$WORK_DIR/open-dispatch-host-test.log" >/dev/null \
    || die 'native Dispatch host semantic marker is missing'

DISPATCH_HOST_EXPECTED_EXPORTS=$WORK_DIR/open-dispatch-host-expected-exports.txt
{
    printf '%s\n' \
        openui_dispatch_host_v1_after \
        openui_dispatch_host_v1_async \
        openui_dispatch_host_v1_create_queue \
        openui_dispatch_host_v1_get_global_queue \
        openui_dispatch_host_v1_get_specific \
        openui_dispatch_host_v1_main \
        openui_dispatch_host_v1_monotonic_nanoseconds \
        openui_dispatch_host_v1_queue_set_specific \
        openui_dispatch_host_v1_release_queue \
        openui_dispatch_host_v1_runtime_check \
        openui_dispatch_host_v1_semaphore_create \
        openui_dispatch_host_v1_semaphore_release \
        openui_dispatch_host_v1_semaphore_signal \
        openui_dispatch_host_v1_semaphore_wait
} > "$DISPATCH_HOST_EXPECTED_EXPORTS"
readelf --wide --syms "$DISPATCH_HOST" \
    | awk '$5 == "GLOBAL" && $7 != "UND" && $8 ~ /^openui_dispatch_host_v1_/ { print $8 }' \
    | LC_ALL=C sort -u > "$WORK_DIR/open-dispatch-host-exports.txt"
cmp "$DISPATCH_HOST_EXPECTED_EXPORTS" "$WORK_DIR/open-dispatch-host-exports.txt" \
    || die 'Linux Dispatch helper exports drifted'

dispatch_glibc_max=$(readelf --version-info "$HOST_DIR/libdispatch.so" \
    | grep -o 'GLIBC_[0-9][0-9.]*' | sort -Vu | tail -n 1)
blocks_glibc_max=$(readelf --version-info "$HOST_DIR/libBlocksRuntime.so" \
    | grep -o 'GLIBC_[0-9][0-9.]*' | sort -Vu | tail -n 1)
if [ "$SKIP_RUNTIME_PIN" -ne 1 ]; then
    [ "$dispatch_glibc_max" = GLIBC_2.38 ] \
        || die "staged libdispatch maximum glibc requirement is $dispatch_glibc_max, expected GLIBC_2.38"
    [ "$blocks_glibc_max" = GLIBC_2.17 ] \
        || die "staged BlocksRuntime maximum glibc requirement is $blocks_glibc_max, expected GLIBC_2.17"
fi
readelf --wide --dynamic "$DISPATCH_HOST" \
    | awk '$2 == "(NEEDED)" { value=$5; gsub(/^\[|\]$/, "", value); print value }' \
    | LC_ALL=C sort -u > "$WORK_DIR/open-dispatch-host-sonames.txt"
for required_soname in libdispatch.so libBlocksRuntime.so; do
    grep -Fx "$required_soname" "$WORK_DIR/open-dispatch-host-sonames.txt" >/dev/null \
        || die "Linux Dispatch helper does not pin $required_soname"
done

if [ -n "$ATTESTATION_DIR" ]; then
    mkdir -p "$ATTESTATION_DIR"
    {
        printf 'format\topen-dispatch-host-v1\n'
        printf 'host-abi\t%s\n' "$HOST_ABI"
        printf 'glibc-minimum\t2.38\tsource=staged-libdispatch-version-needs\n'
        printf 'runtime\tlibdispatch.so\t%s\tmax-version=%s\n' \
            "$(hash_file "$HOST_DIR/libdispatch.so")" "$dispatch_glibc_max"
        printf 'runtime\tlibBlocksRuntime.so\t%s\tmax-version=%s\n' \
            "$(hash_file "$HOST_DIR/libBlocksRuntime.so")" "$blocks_glibc_max"
        printf 'helper\tlibOpenDispatchHost.so\t%s\trpath=$ORIGIN\n' \
            "$(hash_file "$DISPATCH_HOST")"
        while IFS= read -r soname; do
            printf 'direct-soname\t%s\n' "$soname"
        done < "$WORK_DIR/open-dispatch-host-sonames.txt"
        printf 'queue-policy\tmain=kind-only\tglobal=helper-minted-only\tprivate=helper-minted,serial-or-concurrent\n'
        printf 'specific-policy\tkey=opaque\tvalue=retained\tdestructor=guest-callback\n'
        printf 'semaphore-policy\thandle=helper-minted\twait=bounded-or-forever\n'
        printf 'job-policy\tguest-callback=opaque\thost-dispatch=dispatch_async_f\n'
    } > "$ATTESTATION_DIR/open-dispatch-host.tsv"
    cp "$WORK_DIR/open-dispatch-host-test.log" \
        "$ATTESTATION_DIR/open-dispatch-host-test.log"
fi
