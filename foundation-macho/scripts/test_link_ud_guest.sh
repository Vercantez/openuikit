#!/usr/bin/env bash
# Teeth for scripts/link_ud_guest.sh: clang-18, -nostdlib, one _RopeModule.o,
# and a dummy x86 link that would duplicate-symbol if both rope copies were
# on the line.
#
#   bash foundation-macho/scripts/test_link_ud_guest.sh
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
FM=$(cd "$HERE/.." && pwd)
ROOT=$(cd "$FM/.." && pwd)
S=$HERE/link_ud_guest.sh
pass=0
fail=0

ok() { echo "PASS: $*"; pass=$((pass + 1)); }
die_test() { echo "FAIL: $*" >&2; fail=$((fail + 1)); }

expect_grep() {
    local needle=$1 hay=$2 label=$3
    if printf '%s\n' "$hay" | grep -q -- "$needle"; then
        ok "$label"
    else
        die_test "$label (missing: $needle)"
    fi
}

echo "== bash -n"
if bash -n "$S"; then
    ok "bash -n link_ud_guest.sh"
else
    die_test "bash -n link_ud_guest.sh"
fi

script=$(cat "$S")
expect_grep 'clang-18' "$script" "prefers clang-18 over Swift clang-17"
expect_grep '-nostdlib' "$script" "Linux-hosted Darwin link is -nostdlib"
expect_grep 'collections/_RopeModule.o' "$script" "prefers staged collections/_RopeModule.o"
expect_grep 'Never both' "$script" "refuses to link both rope copies"

echo "== dummy x86 link: both rope copies present, only one on the line"
W=$(mktemp -d /tmp/link-ud-guest.XXXXXX)
cleanup() { rm -rf "$W"; }
trap cleanup EXIT

mkdir -p "$W/fe/module" "$W/fe/collections" "$W/fe/os" "$W/fe/cshims" \
    "$W/fe/sysroot/usr/lib/swift" "$W/lib" "$W/bin"
SDK=$W/fe/sysroot
TRIPLE=x86_64-apple-macos13.0

cc_obj() {
    local dest=$1 src=$2
    echo "$src" | clang-18 -target "$TRIPLE" -c -o "$dest" -x c -
}

cc_obj "$W/fe/runner.o" 'int main(void){return 0;}'
cc_obj "$W/fe/UserDefaultsGuest.o" 'int ud_guest_port=1;'
cc_obj "$W/fe/module/FoundationEssentials.o" 'int fe_essentials=1;'
cc_obj "$W/fe/collections/OrderedCollections.o" 'int fe_ordered=1;'
cc_obj "$W/fe/collections/InternalCollectionsUtilities.o" 'int fe_icu=1;'
# Same defined symbol in both copies — linking both is duplicate _rope_dup.
cc_obj "$W/fe/collections/_RopeModule.o" 'int rope_dup=1;'
cp -a "$W/fe/collections/_RopeModule.o" "$W/fe/_RopeModule.o"
cc_obj "$W/fe/os/os.o" 'int fe_os=1;'
cc_obj "$W/fe/cshims/platform_shims.o" 'int fe_plat=1;'
cc_obj "$W/fe/cshims/string_shims.o" 'int fe_str=1;'
cc_obj "$W/fe/cshims/uuid.o" 'int fe_uuid=1;'
cc_obj "$W/fe/fm_unimplemented.o" 'int fe_fm=1;'

emit_tbd() {
    local dest=$1 install=$2
    mkdir -p "$(dirname "$dest")"
    cat >"$dest" <<EOF
--- !tapi-tbd
tbd-version:     4
targets:         [ x86_64-macos ]
install-name:    '$install'
current-version: 1
compatibility-version: 1
exports:
  - targets:   [ x86_64-macos ]
    symbols:   [
                  '_dummy_tbd',
               ]
...
EOF
}

emit_tbd "$SDK/usr/lib/libSystem.B.tbd" "/usr/lib/libSystem.B.dylib"
ln -sfn libSystem.B.tbd "$SDK/usr/lib/libSystem.tbd"
emit_tbd "$SDK/usr/lib/libobjc.A.tbd" "/usr/lib/libobjc.A.dylib"
ln -sfn libobjc.A.tbd "$SDK/usr/lib/libobjc.tbd"
for n in libswiftCore libswiftDarwin libswift_StringProcessing \
    libswiftSynchronization libswift_errno; do
    emit_tbd "$SDK/usr/lib/swift/$n.tbd" "/usr/lib/swift/$n.dylib"
done

echo 'int cftest=1;' | clang-18 -target "$TRIPLE" -c -o "$W/cftest.o" -x c -
clang-18 -target "$TRIPLE" -isysroot "$SDK" -fuse-ld=lld -B /usr/lib/llvm-18/bin \
    -nostdlib -dynamiclib -install_name /usr/lib/libCFTest.dylib \
    "$W/cftest.o" -o "$W/lib/libCFTest.dylib"
cp -a "$W/lib/libCFTest.dylib" "$W/lib/libswiftcompat.dylib"

log=$W/link_ud_guest.log
set +e
W="$W" SDK="$SDK" OUT="$W/bin/ud_guest" LLD_BIN=/usr/lib/llvm-18/bin \
    bash "$S" >"$log" 2>&1
st=$?
set -e
echo "$log:"
cat "$log"

rope_n=$(grep -c '_RopeModule.o' "$log" || true)
if [ "$rope_n" -eq 1 ] && grep -q 'collections/_RopeModule.o' "$log" \
    && ! grep -qE '[[:space:]]fe/_RopeModule\.o' "$log"; then
    ok "inputs list collections/_RopeModule.o once (not the flat duplicate)"
else
    die_test "rope inputs: count=$rope_n (want 1 collections/). log=$(tr '\n' ' ' < "$log")"
fi
if grep -q 'duplicate symbol' "$log"; then
    die_test "ld64 still reports duplicate symbol (both rope copies on the line)"
else
    ok "no duplicate-symbol diagnostic"
fi
if grep -q 'CC=clang-18' "$log"; then
    ok "link log names CC=clang-18"
else
    die_test "link log missing CC=clang-18"
fi
if [ "$st" -eq 0 ] && [ -f "$W/bin/ud_guest" ] \
    && llvm-otool-18 -hv "$W/bin/ud_guest" | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64'; then
    ok "dummy ud_guest is MH_MAGIC_64 X86_64"
else
    die_test "dummy link exit $st (want 0 + X86_64 Mach-O). log=$(tr '\n' ' ' < "$log")"
fi

echo "test_link_ud_guest: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
