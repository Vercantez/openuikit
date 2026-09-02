#!/bin/bash
# Prove that the loader grows beyond the historical 64-image ceiling.  The
# runtime half deliberately creates a 130-dylib dependency chain: every image
# must be registered, fixed up and called for the guest to return success.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
BUILD=$(mktemp -d /tmp/machorun-image-capacity.XXXXXX)
trap 'rm -rf "$BUILD"' EXIT
IMAGE_COUNT=${IMAGE_COUNT:-130}

if [ "$IMAGE_COUNT" -le 128 ]; then
    echo "image_capacity_gate: IMAGE_COUNT must be greater than 128" >&2
    exit 64
fi

python3 "$ROOT/tests/src/test_dynamic_image_capacity.py"

HOST_CC=${HOST_CC:-cc}
command -v "$HOST_CC" >/dev/null 2>&1 || HOST_CC=clang-18
command -v "$HOST_CC" >/dev/null 2>&1 || HOST_CC=clang
command -v "$HOST_CC" >/dev/null 2>&1 || {
    echo "image_capacity_gate: no host C compiler" >&2; exit 1;
}
"$HOST_CC" -std=gnu11 -O2 -Wall -Wextra -Werror \
    -I"$ROOT/src" \
    "$ROOT/src/util.c" "$ROOT/src/image_table.c" \
    "$ROOT/tests/src/image_table_host.c" \
    -o "$BUILD/image-table-host"
"$BUILD/image-table-host" 2>"$BUILD/image-table-host.stderr" \
    | tee "$BUILD/image-table-host.stdout"
grep -Fq 'overflow=fail-closed' "$BUILD/image-table-host.stdout"
grep -Fq 'capacity overflow' "$BUILD/image-table-host.stderr"
grep -Fq "INT_MAX representation" "$BUILD/image-table-host.stderr"

if [ "$(uname -s)" != Linux ]; then
    echo "MACHORUN_IMAGE_CAPACITY_HOST_OK runtime=skipped,needs-linux-arm64"
    exit 0
fi

CLANG=${DARWIN_CLANG:-clang-18}
command -v "$CLANG" >/dev/null 2>&1 || CLANG=clang
LD64=${LD64:-ld64.lld-18}
command -v "$LD64" >/dev/null 2>&1 || LD64=ld64.lld
command -v "$CLANG" >/dev/null 2>&1 || {
    echo "image_capacity_gate: no clang" >&2; exit 1;
}
command -v "$LD64" >/dev/null 2>&1 || {
    echo "image_capacity_gate: no ld64.lld" >&2; exit 1;
}

CC=${CC:-$HOST_CC}
export CC
sh "$ROOT/scripts/build.sh" loader

last=$((IMAGE_COUNT - 1))
for ((index=last; index>=0; index--)); do
    name=$(printf 'image_%03d' "$index")
    next=$((index + 1))
    if [ "$index" -eq "$last" ]; then
        printf 'int %s(void) { return 1; }\n' "$name" >"$BUILD/$name.c"
    else
        next_name=$(printf 'image_%03d' "$next")
        printf 'extern int %s(void); int %s(void) { return %s() + 1; }\n' \
            "$next_name" "$name" "$next_name" >"$BUILD/$name.c"
    fi
    "$CLANG" -target arm64-apple-macos11 -ffreestanding \
        -fno-stack-protector -fno-builtin -fPIC -O1 \
        -c "$BUILD/$name.c" -o "$BUILD/$name.o"
    link_inputs=("$BUILD/$name.o")
    if [ "$index" -ne "$last" ]; then
        link_inputs+=("$BUILD/lib$next_name.dylib")
    fi
    "$LD64" -dylib -arch arm64 -platform_version macos 11.0 11.0 \
        -install_name "@loader_path/lib$name.dylib" \
        -undefined dynamic_lookup -o "$BUILD/lib$name.dylib" \
        "${link_inputs[@]}"
done

cat >"$BUILD/main.c" <<EOF
extern int image_000(void);
int main(void) { return image_000() == $IMAGE_COUNT ? 0 : 93; }
EOF
"$CLANG" -target arm64-apple-macos11 -ffreestanding \
    -fno-stack-protector -fno-builtin -O1 \
    -c "$BUILD/main.c" -o "$BUILD/main.o"
"$LD64" -arch arm64 -platform_version macos 11.0 11.0 \
    -e _main -undefined dynamic_lookup -o "$BUILD/image-capacity-guest" \
    "$BUILD/main.o" "$BUILD/libimage_000.dylib"

set +e
( cd "$BUILD" && timeout -k 2 30 "$ROOT/build/machorun" \
    ./image-capacity-guest ) >"$BUILD/runtime.stdout" 2>"$BUILD/runtime.stderr"
runtime_status=$?
set -e
if [ "$runtime_status" -ne 0 ]; then
    echo "image_capacity_gate: $IMAGE_COUNT-image guest exited $runtime_status" >&2
    sed -n '1,80p' "$BUILD/runtime.stderr" >&2
    exit 1
fi
if grep -Fq 'more than 64 images loaded' "$BUILD/runtime.stderr"; then
    echo "image_capacity_gate: fixed 64-image diagnostic returned" >&2
    exit 1
fi

printf 'MACHORUN_IMAGE_CAPACITY_RUNTIME_OK dylibs=%d total-images=%d ' \
    "$IMAGE_COUNT" "$((IMAGE_COUNT + 1))"
printf 'calls=complete handles=pointer-stable allocation=fail-closed\n'
